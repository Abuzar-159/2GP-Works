public with sharing class testtemp {
    public class ProductStockSummary {
        @AuraEnabled public Id      productId;
        @AuraEnabled public Decimal totalQty;

        public ProductStockSummary(Id productId, Decimal totalQty) {
            this.productId = productId;
            this.totalQty  = totalQty;
        }
    }

    public static Map<Id, ProductStockSummary> getTotalStockPerProduct(
    List<Id> productIds,
    String channel,                 // kept for compatibility (not used in filter here)
    String distributionChannel      // Id of Distribution_Channel__c record
) {
    Map<Id, ProductStockSummary> result = new Map<Id, ProductStockSummary>();

    if (productIds == null || productIds.isEmpty() || String.isBlank(distributionChannel)) {
        return result;
    }

    // 1) Get the DC record to derive Site (Warehouse)
    Id dcId;
    try {
        dcId = (Id)distributionChannel;         // assuming caller passes DC Id as String
    } catch (Exception e) {
        // If it's not a valid Id, nothing to do
        return result;
    }

    // ⚠️ Adjust object/field API names if different in your org
    Distribution_Channel__c dc = [
        SELECT Id, Site__c
        FROM Distribution_Channel__c
        WHERE Id = :dcId
        LIMIT 1
    ];

    if (dc.Site__c == null) {
        // No site/warehouse on DC → no inventory to fetch
        return result;
    }

    Id siteId = dc.Site__c;   // this is what Inventory_Stock__c.Warehouse__c points to

    // 2) Query Inventory_Stock__c filtered by Warehouse__c (site)
    String soql =
        'SELECT Product__c productId,' +
        '       SUM(Number_of_Item_In_Stock__c) totalQty' +
        '  FROM Inventory_Stock__c' +
        ' WHERE Product__c IN :productIds' +
        '   AND Active__c = true' +
        '   AND Number_of_Item_In_Stock__c > 0' +
        '   AND Name NOT IN (\'Awaiting Stock\', \'Serial Stock Holder\')' +
        '   AND Warehouse__c = :siteId' +
        ' GROUP BY Product__c';

    List<AggregateResult> ars = Database.query(soql);

    for (AggregateResult ar : ars) {
        Id      productId = (Id)ar.get('productId');
        Decimal totalQty  = (Decimal)ar.get('totalQty');

        result.put(productId, new ProductStockSummary(productId, totalQty));
    }

    return result;
}


@AuraEnabled
public static String createLogisticsMinimal(String LogisticJSON, String LLIListJSON) {
    try {
        System.debug('createLogisticsMinimal called');

        // Deserialize inputs
        Logistic__c logistic = (Logistic__c) JSON.deserialize(LogisticJSON, Logistic__c.class);
        List<Logistic_Line_Item__c> logisticLIs = (LLIListJSON != null && LLIListJSON != '')
            ? (List<Logistic_Line_Item__c>) JSON.deserialize(LLIListJSON, List<Logistic_Line_Item__c>.class)
            : new List<Logistic_Line_Item__c>();

        // Distribution channel required for warehouse/site
        if (logistic.Distribution_Channel__c == null) {
            return 'Distribution Channel is required on Logistic';
        }
        List<Distribution_Channel__c> dcs = [
            SELECT Id, Name, Site__c FROM Distribution_Channel__c WHERE Id = :logistic.Distribution_Channel__c LIMIT 1
        ];
        if (dcs.isEmpty()) return 'Selected Distribution Channel not found';
        Distribution_Channel__c dc = dcs[0];

        // Collect product ids used in logistic line items
        Set<Id> productIds = new Set<Id>();
        for (Logistic_Line_Item__c lli : logisticLIs) {
            if (lli.Product__c != null) productIds.add(lli.Product__c);
        }

        // Load product metadata (serial flag and names)
        Map<Id, Product2> productsMap = new Map<Id, Product2>();
        if (!productIds.isEmpty()) {
            for (Product2 p : [SELECT Id, Name, Serialise__c FROM Product2 WHERE Id IN :productIds]) {
                productsMap.put(p.Id, p);
            }
        }

        // Insert or update logistic: user asked "insert" mainly — we'll insert if no Id, update if Id present
        if (logistic.Id == null) {
            if (!Schema.sObjectType.Logistic__c.isCreateable()) return 'No create access on Logistic';
            insert logistic;
        } else {
            if (!Schema.sObjectType.Logistic__c.isUpdateable()) return 'No update access on Logistic';
            update logistic;
        }

        // Prepare logistic line items: name truncation + status + link to logistic
        for (Logistic_Line_Item__c l : logisticLIs) {
            if (l.Name != null && l.Name.length() > 80) l.Name = l.Name.substring(0, 80);
            l.Status__c = 'Reserved';
            l.Logistic__c = logistic.Id;
        }

        // FLS-safe upsert of logistic line items
        if (!logisticLIs.isEmpty()) {
            if (!(Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable()))
                return 'Does not have access to upsert logistic line items';

            List<SObject> safeLogisticLI = FLSHelper.getSafeRecords(logisticLIs, 'Logistic_Line_Item__c', AccessType.UPDATABLE);
            List<Logistic_Line_Item__c> typeLogisticLI = new List<Logistic_Line_Item__c>();
            for (SObject s : safeLogisticLI) typeLogisticLI.add((Logistic_Line_Item__c)s);
            if (!typeLogisticLI.isEmpty()) upsert typeLogisticLI;
            // refresh to get Ids (useful for later mapping)
            Map<Id, Logistic_Line_Item__c> persistedLLIById = new Map<Id, Logistic_Line_Item__c>();
            for (Logistic_Line_Item__c l : typeLogisticLI) if (l.Id != null) persistedLLIById.put(l.Id, l);
        }

        // Build map of required quantities per product from persisted logistic LIs
        Map<Id, Decimal> productRequestedQty = new Map<Id, Decimal>();
        for (Logistic_Line_Item__c l : logisticLIs) {
            if (l.Product__c != null && l.Quantity__c != null && l.Quantity__c > 0) {
                Decimal existing = productRequestedQty.containsKey(l.Product__c) ? productRequestedQty.get(l.Product__c) : 0;
                productRequestedQty.put(l.Product__c, existing + l.Quantity__c);
            }
        }

        // Query existing inventory rows for relevant products at the distribution center site (FIFO order)
        Map<Id, List<Inventory_Stock__c>> inventoryByProduct = new Map<Id, List<Inventory_Stock__c>>();
        if (!productRequestedQty.isEmpty()) {
            List<Inventory_Stock__c> invRows = [
                SELECT Id, Product__c, Number_of_Item_In_Stock__c, Serial__c, Batch_Lot__c, Checked_In_Date__c
                FROM Inventory_Stock__c
                WHERE Product__c IN :productRequestedQty.keySet()
                  AND Warehouse__c = :dc.Site__c
                  AND Active__c = true
                  AND Name != 'Awaiting Stock'
                  AND Number_of_Item_In_Stock__c > 0
                ORDER BY Checked_In_Date__c ASC
            ];
            for (Inventory_Stock__c inv : invRows) {
                if (!inventoryByProduct.containsKey(inv.Product__c)) inventoryByProduct.put(inv.Product__c, new List<Inventory_Stock__c>());
                inventoryByProduct.get(inv.Product__c).add(inv);
            }
        }

        // Create Stock Outward Line Items (SWLI)
        List<Stock_Outward_Line_Item__c> swliToUpsert = new List<Stock_Outward_Line_Item__c>();
        List<Inventory_Stock__c> serialInventoryToInsert = new List<Inventory_Stock__c>();
        Map<Id, Inventory_Stock__c> tempInvMap = new Map<Id, Inventory_Stock__c>(); // key: logisticLineItem.Id -> created inventory (temp keyed by composite below)

        // We'll iterate each logistic LI and reserve from inventoryByProduct (FIFO)
        for (Logistic_Line_Item__c logLI : logisticLIs) {
            if (logLI.Product__c == null || logLI.Quantity__c == null || logLI.Quantity__c <= 0) continue;

            Boolean isSerial = productsMap.containsKey(logLI.Product__c) && (productsMap.get(logLI.Product__c).Serialise__c == true);
            Decimal remaining = logLI.Quantity__c;

            if (isSerial) {
                // For serial-tracked: create ONE serial stock holder inventory record and one SWLI that references it
                Inventory_Stock__c serialInv = new Inventory_Stock__c(
                    Active__c = true,
                    Product__c = logLI.Product__c,
                    Name = 'Serial Stock Holder',
                    Warehouse__c = dc.Site__c
                );
                serialInventoryToInsert.add(serialInv);

                // Create SWLI placeholder now; we will wire Site_Product_Service_Inventory_Stock__c after insert
                Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c();
                sto.Name = 'Serial Stock Holder';
                sto.Product__c = logLI.Product__c;
                sto.Active__c = true;
                sto.Status__c = 'Reserved';
                sto.Logistic_Line_Item__c = logLI.Id;
                // Assign order/product links if provided on logistic line item
                if (logLI.Order_Product__c != null) sto.Order_Product__c = logLI.Order_Product__c;
                //if (logLI.Logistic__c != null) sto.Logistic__c = logLI.Logistic__c;
                // For serial we assign full remaining quantity to the single SWLI
                sto.Quantity__c = remaining;
                // Keep mapping so we can assign the created inventory id after insert
                // Use map key as index of insertion list: use pseudo-key approach by storing index later
                swliToUpsert.add(sto);
                // We'll map the SWLI index to its created Inventory after insert by matching insertion order
                // Store association: add a specially constructed placeholder to tempInvMap using negative composite id (we'll use size of serialInventoryToInsert -1 as key)
                // But maps keyed by Id not allowed; instead use list alignment: we will insert serialInventoryToInsert and then assign IDs to corresponding SWLIs in same order
            } else {
                // Non-serial: consume from existing inventory FIFO list
                List<Inventory_Stock__c> invList = inventoryByProduct.containsKey(logLI.Product__c) ? inventoryByProduct.get(logLI.Product__c) : new List<Inventory_Stock__c>();
                Integer idx = 0;
                while (remaining > 0 && idx < invList.size()) {
                    Inventory_Stock__c inv = invList[idx];
                    Decimal invQty = inv.Number_of_Item_In_Stock__c == null ? 0 : inv.Number_of_Item_In_Stock__c;
                    if (invQty <= 0) { idx++; continue; }

                    Decimal qtyToTake = (invQty <= remaining) ? invQty : remaining;
                    Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c();
                    sto.Name = logLI.Name != null ? logLI.Name : 'Stock Outward';
                    sto.Product__c = logLI.Product__c;
                    sto.Active__c = true;
                    sto.Status__c = 'Reserved';
                    sto.Logistic_Line_Item__c = logli.Id;
                    if (logLI.Order_Product__c != null) sto.Order_Product__c = logLI.Order_Product__c;
                   // if (logLI.Logistic__c != null) sto.Logistic__c = logLI.Logistic__c;
                    sto.Quantity__c = qtyToTake;
                    sto.Site_Product_Service_Inventory_Stock__c = inv.Id;
                    // Optionally set batch/serial fields if desired
                    if (inv.Serial__c != null) sto.Serial__c = inv.Serial__c;
                    if (inv.Batch_Lot__c != null) sto.Material_Batch_Lot__c = inv.Batch_Lot__c;

                    swliToUpsert.add(sto);

                    // reduce remaining and move to next inventory row if needed
                    remaining = remaining - qtyToTake;
                    idx++;
                }

                if (remaining > 0) {
                    // Not enough inventory available
                    return 'Does not have inventory for product: ' + (productsMap.containsKey(logLI.Product__c) ? productsMap.get(logLI.Product__c).Name : String.valueOf(logLI.Product__c)) + ' on selected distribution center site';
                }
            }
        } // end loop logisticLIs

        // Insert created serial inventory entries (all serialInventoryToInsert correspond to serial SWLIs in same order they were added)
        if (!serialInventoryToInsert.isEmpty()) {
            insert serialInventoryToInsert;
            // Wire newly created inventory ids to the corresponding SWLIs (map by relative order)
            Integer serialIndex = 0;
            for (Integer i = 0; i < swliToUpsert.size(); i++) {
                Stock_Outward_Line_Item__c sto = swliToUpsert[i];
                // Only assign if this SWLI is the serial one (we detect by name 'Serial Stock Holder' and Product in serial list)
                if (sto != null && sto.Name == 'Serial Stock Holder') {
                    if (serialIndex < serialInventoryToInsert.size()) {
                        Inventory_Stock__c insertedInv = serialInventoryToInsert[serialIndex];
                        sto.Site_Product_Service_Inventory_Stock__c = insertedInv.Id;
                        serialIndex++;
                    }
                }
            }
        }

        // Upsert SWLIs (check create/update permission)
        if (!swliToUpsert.isEmpty()) {
            if (!(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()))
                return 'Don\'t have access to upsert Stock Outward Line Items';

            upsert swliToUpsert;
            for (Stock_Outward_Line_Item__c s : swliToUpsert) {
                System.debug('Upserted SWLI Id: ' + s.Id);
            }
        }

        // NOTE: Per your request we are skipping POLI updates and any MRP/BOM/kit handling.

        return null; // success
    } catch (Exception e) {
        System.debug('Exception in createLogisticsMinimal: ' + e.getMessage() + ' stack: ' + e.getStackTraceString());
        throw new AuraHandledException(e.getMessage());
    }
}

}