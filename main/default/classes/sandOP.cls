public with sharing class sandOP {
    @AuraEnabled(cacheable=true)
    public static Account getDefaultOrganisation() {        return UtilClass.getOrganisationByLogin_Employee();    }

     //=================================================  Abuzar added inventory levels  ==============================================================
    
    // Wrapper class defined outside any method in a graph
    public class InventorySummaryWrapper {
        @AuraEnabled public Decimal totalExpectedRaw = 0;
        @AuraEnabled public Decimal totalConsumedRaw = 0;
        @AuraEnabled public Decimal totalScrappedRaw = 0;
    
        @AuraEnabled public Decimal totalWipQuantity = 0;
        @AuraEnabled public Decimal totalWipScrapped = 0;
    
        @AuraEnabled public Decimal totalFinishedRequested = 0;
        @AuraEnabled public Decimal totalFinishedInStock = 0;
        @AuraEnabled public Decimal totalFinishedScrapped = 0;
        @AuraEnabled public Decimal totalFinishedScrap = 0;
    }
    
    // based on the product name filter date from to date

        @AuraEnabled
        public static InventorySummaryWrapper getSummedInventory(Id productId, Date fromDate, Date toDate, Id organizationId) {
            // Fallback to current fiscal year (assume FY starts in April)
                System.debug('📨 Apex called with Product: ' + productId + ', From: ' + fromDate + ', To: ' + toDate);

            if (fromDate == null || toDate == null) {
                Date today = Date.today();
                Integer fiscalYearStartMonth = 4; // April
                Integer year = today.month() >= fiscalYearStartMonth ? today.year() : today.year() - 1;
                fromDate = Date.newInstance(year, fiscalYearStartMonth, 1);
                toDate = fromDate.addMonths(12).addDays(-1);
            }
    
            // Get Manufacturing Orders by product and date range
            List<Manufacturing_Order__c> moList;
            if (productId != null) {
            moList = [
                SELECT Id FROM Manufacturing_Order__c
                WHERE Product__c = :productId
                AND CreatedDate >= :fromDate AND CreatedDate <= :toDate
            ];
        } else {
            moList = [
                SELECT Id FROM Manufacturing_Order__c
                WHERE CreatedDate >= :fromDate AND CreatedDate <= :toDate
            ];
        }
    
            Set<Id> moIds = new Set<Id>();
            for (Manufacturing_Order__c mo : moList) {
                moIds.add(mo.Id);
            }
    
            InventorySummaryWrapper summary = new InventorySummaryWrapper();
    
            // RAW
            for (MRP__c rec : [
                SELECT Expected_Quantity__c, Consumed_Quantity__c, Scrapped_Quantity__c
                FROM MRP__c WHERE MO__c IN :moIds
            ]) {
                summary.totalExpectedRaw += rec.Expected_Quantity__c != null ? rec.Expected_Quantity__c : 0;
                summary.totalConsumedRaw += rec.Consumed_Quantity__c != null ? rec.Consumed_Quantity__c : 0;
                summary.totalScrappedRaw += rec.Scrapped_Quantity__c != null ? rec.Scrapped_Quantity__c : 0;
            }
    
            // WIP
            for (WIP__c rec : [
                SELECT Quantity__c, Scrapped__c
                FROM WIP__c WHERE MO__c IN :moIds
            ]) {
                summary.totalWipQuantity += rec.Quantity__c != null ? rec.Quantity__c : 0;
                summary.totalWipScrapped += rec.Scrapped__c != null ? rec.Scrapped__c : 0;
            }
    
            // Finished
            for (Inventory_Stock__c rec : [
                SELECT No_of_Items_Requested__c, Number_of_Item_In_Stock__c,
                       Number_of_Items_Scrapped__c, Scrap__c
                FROM Inventory_Stock__c WHERE Manufacturing_Order__c IN :moIds
            ]) {
                summary.totalFinishedRequested += rec.No_of_Items_Requested__c != null ? rec.No_of_Items_Requested__c : 0;
                summary.totalFinishedInStock += rec.Number_of_Item_In_Stock__c != null ? rec.Number_of_Item_In_Stock__c : 0;
                summary.totalFinishedScrapped += rec.Number_of_Items_Scrapped__c != null ? rec.Number_of_Items_Scrapped__c : 0;
                // summary.totalFinishedScrap += rec.Scrap__c != null ? rec.Scrap__c : 0;
            }
    
            return summary;
        }
        
        
    // based on the top 5 product name filter date from to date
public class Top5InventorySummaryWrapper implements Comparable {
    @AuraEnabled public Id productId;
    @AuraEnabled public String productName;

    @AuraEnabled public Decimal totalExpectedRaw = 0;    @AuraEnabled public Decimal totalConsumedRaw = 0;    @AuraEnabled public Decimal totalScrappedRaw = 0;

    @AuraEnabled public Decimal totalWipQuantity = 0;    @AuraEnabled public Decimal totalWipScrapped = 0;

    @AuraEnabled public Decimal totalFinishedRequested = 0;    @AuraEnabled public Decimal totalFinishedInStock = 0;
    @AuraEnabled public Decimal totalFinishedScrapped = 0;    @AuraEnabled public Decimal totalFinishedScrap = 0;

    @AuraEnabled public Decimal totalAll = 0;
    public Integer compareTo(Object other) {
    Top5InventorySummaryWrapper o = (Top5InventorySummaryWrapper) other;
    Decimal diff = o.totalAll - this.totalAll;
    if (diff > 0) return 1;
    if (diff < 0) return -1;
    return 0;
}
}


   @AuraEnabled
public static List<Top5InventorySummaryWrapper> getTop5Inventory() {
    // Get fiscal year start and end from org settings
    Organization orgInfo = [SELECT FiscalYearStartMonth FROM Organization LIMIT 1];
    Integer startMonth = orgInfo.FiscalYearStartMonth;   Date today = Date.today();    Integer year = today.month() >= startMonth ? today.year() : today.year() - 1;
    Date fromDate = Date.newInstance(year, startMonth, 1);   Date toDate = fromDate.addMonths(12).addDays(-1);

    // Get MOs within fiscal year
    List<Manufacturing_Order__c> mos = [
        SELECT Id, Product__c, Product__r.Name
        FROM Manufacturing_Order__c
        WHERE CreatedDate >= :fromDate AND CreatedDate <= :toDate
              AND Product__c != null
    ];

    Map<Id, Top5InventorySummaryWrapper> productSummaryMap = new Map<Id, Top5InventorySummaryWrapper>();
    Set<Id> moIds = new Set<Id>();    Map<Id, Id> moToProductMap = new Map<Id, Id>();

    for (Manufacturing_Order__c mo : mos) {
        moIds.add(mo.Id);
        moToProductMap.put(mo.Id, mo.Product__c);
        if (!productSummaryMap.containsKey(mo.Product__c)) {
            Top5InventorySummaryWrapper wrap = new Top5InventorySummaryWrapper();
            wrap.productId = mo.Product__c;            wrap.productName = mo.Product__r.Name;
            productSummaryMap.put(mo.Product__c, wrap);
        }
    }

    // RAW
    for (MRP__c rec : [
        SELECT MO__c, Expected_Quantity__c, Consumed_Quantity__c, Scrapped_Quantity__c
        FROM MRP__c WHERE MO__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.MO__c);
        if (productSummaryMap.containsKey(productId)) {    Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalExpectedRaw += rec.Expected_Quantity__c != null ? rec.Expected_Quantity__c : 0;
            wrap.totalConsumedRaw += rec.Consumed_Quantity__c != null ? rec.Consumed_Quantity__c : 0;
            wrap.totalScrappedRaw += rec.Scrapped_Quantity__c != null ? rec.Scrapped_Quantity__c : 0;
        }
    }

    // WIP
    for (WIP__c rec : [
        SELECT MO__c, Quantity__c, Scrapped__c
        FROM WIP__c WHERE MO__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.MO__c);
        if (productSummaryMap.containsKey(productId)) {       Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalWipQuantity += rec.Quantity__c != null ? rec.Quantity__c : 0;
            wrap.totalWipScrapped += rec.Scrapped__c != null ? rec.Scrapped__c : 0;
        }
    }

    // Finished
    for (Inventory_Stock__c rec : [
        SELECT Manufacturing_Order__c, No_of_Items_Requested__c,
               Number_of_Item_In_Stock__c, Number_of_Items_Scrapped__c, Scrap__c
        FROM Inventory_Stock__c
        WHERE Manufacturing_Order__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.Manufacturing_Order__c);
        if (productSummaryMap.containsKey(productId)) {  Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalFinishedRequested += rec.No_of_Items_Requested__c != null ? rec.No_of_Items_Requested__c : 0;
            wrap.totalFinishedInStock += rec.Number_of_Item_In_Stock__c != null ? rec.Number_of_Item_In_Stock__c : 0;
            wrap.totalFinishedScrapped += rec.Number_of_Items_Scrapped__c != null ? rec.Number_of_Items_Scrapped__c : 0;
            // wrap.totalFinishedScrap += rec.Scrap__c != null ? rec.Scrap__c : 0;
        }
    }

    // Compute total and sort
    List<Top5InventorySummaryWrapper> sortedList = new List<Top5InventorySummaryWrapper>();
    for (Top5InventorySummaryWrapper wrap : productSummaryMap.values()) {       wrap.totalAll = wrap.totalExpectedRaw + wrap.totalWipQuantity + wrap.totalFinishedInStock;
        sortedList.add(wrap);
    }

    sortedList.sort(); // Uses compareTo() defined above
List<Top5InventorySummaryWrapper> top5List = new List<Top5InventorySummaryWrapper>();

for (Integer i = 0; i < Math.min(5, sortedList.size()); i++) {    top5List.add(sortedList[i]);
}
return top5List;
}

@AuraEnabled(cacheable=true)
public static Integer getOrgFiscalStartMonth() {    return [SELECT FiscalYearStartMonth FROM Organization LIMIT 1].FiscalYearStartMonth;
}

// ========================================================= Abuzar's code ends here ===========================================================

// Matheen's Code 

@AuraEnabled(cacheable=true)
public static Product2 getDefaultProductFromOrderItem() {
        // Get the first day of the current year
    Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
    Date endOfYear = Date.newInstance(Date.today().year(), 12, 31);

    List<AggregateResult> topProductResult = [
        SELECT Product2Id, SUM(Quantity) totalQuantity
        FROM OrderItem
        WHERE Product2Id != null
            AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
            AND Order.EffectiveDate >= :startOfYear
            AND Order.EffectiveDate <= :endOfYear

        GROUP BY Product2Id
        ORDER BY SUM(Quantity) DESC
        LIMIT 1
    ];


    if (!topProductResult.isEmpty()) {
        Id topProductId = (Id)topProductResult[0].get('Product2Id');
        List<Product2> products = [
            SELECT Id, Name
            FROM Product2        WHERE Id = :topProductId
        ];
        return products.isEmpty() ? null : products[0];
    }
    return null;
}
@AuraEnabled(cacheable=true)
public static Account getDefaultCustomerFromOrders() {
    Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);    Date endOfYear = Date.newInstance(Date.today().year(), 12, 31);

    List<AggregateResult> topCustomerResult = [
        SELECT AccountId, COUNT(Id) orderCount
        FROM Order
        WHERE 
            Active__c = true 
            AND AccountId != null
            AND EffectiveDate >= :startOfYear
            AND EffectiveDate <= :endOfYear
        GROUP BY AccountId
        ORDER BY COUNT(Id) DESC
        LIMIT 1
    ];

    if (!topCustomerResult.isEmpty()) {
        Id topCustomerId = (Id) topCustomerResult[0].get('AccountId');
        List<Account> customers = [SELECT Id, Name FROM Account WHERE Id = :topCustomerId];       return customers.isEmpty() ? null : customers[0];
    }

    return null;
}

@AuraEnabled(cacheable=true)
public static Site__c getDefaultWarehouseByStock(Id organisationId) {
    List<Site__c> topSite = [
        SELECT Id, Name
        FROM Site__c
        WHERE Active__c = TRUE
        AND Company__c = :organisationId
        AND Stock__c != null
        ORDER BY Stock__c DESC
        LIMIT 1
    ];

    return topSite.isEmpty() ? null : topSite[0];
}


@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getTopCustomersForProduct(Id productId, Integer topN,Id OrgId) {
    Integer currentYear = Date.today().year();
    Date startDate = Date.newInstance(currentYear, 1, 1);
    Date endDate = Date.newInstance(currentYear, 12, 31);

    List<AggregateResult> results = [
        SELECT Order.AccountId accId, SUM(Quantity) totalQty
        FROM OrderItem
        WHERE Product2Id = :productId
        AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND Order.EffectiveDate >= :startDate AND Order.EffectiveDate <= :endDate
        AND Company__c = :OrgId
        GROUP BY Order.AccountId
        ORDER BY SUM(Quantity) DESC
        LIMIT :topN
    ];

    List<Map<String, Object>> response = new List<Map<String, Object>>();
    for (AggregateResult ar : results) {
        Id accId = (Id)ar.get('accId');     Decimal qty = (Decimal)ar.get('totalQty');
        Account acc = [SELECT Name FROM Account WHERE Id = :accId LIMIT 1];

        Map<String, Object> entry = new Map<String, Object>();
        entry.put('accountId', accId);       entry.put('accountName', acc.Name);       entry.put('quantity', qty.setScale(2));       response.add(entry);
    }

    return response;
}


  /*  @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDemandData(String productId, String organisationId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            System.debug('getDemandData called with productId: ' + productId + ', organisationId: ' + organisationId);
            if (String.isBlank(productId) || String.isBlank(organisationId)) {
                throw new AuraHandledException('Product ID and Organisation ID cannot be blank.');
            }
            // Demand by Month: Aggregate quantity by month
            List<AggregateResult> monthlyDemand = [
                SELECT CALENDAR_MONTH(Order.EffectiveDate) month, CALENDAR_YEAR(Order.EffectiveDate) year, SUM(Quantity) totalQuantity
                FROM OrderItem
                WHERE Product2Id = :productId
                AND Order.Company__c = :organisationId
                AND Order.EffectiveDate = LAST_N_MONTHS:6
                GROUP BY CALENDAR_MONTH(Order.EffectiveDate), CALENDAR_YEAR(Order.EffectiveDate)
                ORDER BY CALENDAR_YEAR(Order.EffectiveDate), CALENDAR_MONTH(Order.EffectiveDate)
                LIMIT 2000
            ];
            System.debug('Monthly demand data: ' + monthlyDemand);
            List<String> monthLabels = new List<String>();
            List<Decimal> monthData = new List<Decimal>();
            for (AggregateResult ar : monthlyDemand) {
                Integer month = (Integer)ar.get('month');
                Integer year = (Integer)ar.get('year');
                monthLabels.add(String.valueOf(month) + '/' + String.valueOf(year));
                monthData.add((Decimal)ar.get('totalQuantity'));
            }
            result.put('monthLabels', monthLabels);
            result.put('monthData', monthData);
            
            // Demand by Customer: Aggregate quantity by customer
            List<AggregateResult> customerDemand = [
                SELECT Order.Account.Name customerName, SUM(Quantity) totalQuantity
                FROM OrderItem
                WHERE Product2Id = :productId
                AND Order.Company__c = :organisationId
                GROUP BY Order.Account.Name
                ORDER BY Order.Account.Name
                LIMIT 2000
            ];
            System.debug('Customer demand data: ' + customerDemand);
            List<String> customerLabels = new List<String>();
            List<Decimal> customerData = new List<Decimal>();
            for (AggregateResult ar : customerDemand) {
                customerLabels.add((String)ar.get('customerName'));
                customerData.add((Decimal)ar.get('totalQuantity'));
            }
            result.put('customerLabels', customerLabels);
            result.put('customerData', customerData);
            
            AggregateResult productDemand = [
                SELECT SUM(Quantity) totalQuantity
                FROM OrderItem
                WHERE Product2Id = :productId
                AND Order.Company__c = :organisationId
            ];
            System.debug('Product demand data: ' + productDemand);
            List<String> productLabels = new List<String>{[SELECT Name FROM Product2 WHERE Id = :productId].Name};
            List<Decimal> productData = new List<Decimal>{(Decimal)productDemand.get('totalQuantity')};
            result.put('productLabels', productLabels);
            result.put('productData', productData);
            System.debug('Demand data result: ' + result); 
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching demand data: ' + e.getMessage());
        }
    }
*/
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getTopProductsByDemand(String organisationId) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            System.debug('getTopProductsByDemand called with organisationId: ' + organisationId);
            if (String.isBlank(organisationId)) {
                throw new AuraHandledException('Organisation ID cannot be blank.');
            }
            Date startOfYear = Date.newInstance(Date.today().year(), 1, 1);
            Date endOfYear = Date.newInstance(Date.today().year(), 12, 31);

            List<AggregateResult> topProducts = [
                SELECT Product2.Name productName, SUM(Quantity) totalQuantity
                FROM OrderItem
                WHERE Order.Company__c = :organisationId
                AND Order.Status NOT IN ('Cancelled','Draft','Entered') 
                AND Order.EffectiveDate >= :startOfYear
                AND Order.EffectiveDate <= :endOfYear
                GROUP BY Product2.Name
                ORDER BY SUM(Quantity) DESC
                LIMIT 5
            ];

            System.debug('Top products data: ' + topProducts);
            List<String> topProductLabels = new List<String>();
            List<Decimal> topProductData = new List<Decimal>();
            for (AggregateResult ar : topProducts) {
                topProductLabels.add((String)ar.get('productName'));               topProductData.add((Decimal)ar.get('totalQuantity'));
            }
            result.put('topProductLabels', topProductLabels);
            result.put('topProductData', topProductData);
            System.debug('Top products result: ' + result);
            return result;
        } catch (Exception e) {           throw new AuraHandledException('Error fetching top products: ' + e.getMessage());
        }
    }
@AuraEnabled
public static Boolean checkversionAvailability(String productId) {
    try {
        List<BOM__c> versions = [
            SELECT Id
            FROM BOM__c
            WHERE Product__c = :productId
            AND Active__c = true
            LIMIT 1
        ];
        
        return !versions.isEmpty();  
    } catch (Exception e) {     throw new AuraHandledException(e.getMessage());
    }
}
        @AuraEnabled(cacheable=true)
    public static Map<String, Object> getWarehouseInventory(String organisationId, String productId, String version) {
        try {
        if (String.isBlank(organisationId)) {
            throw new AuraHandledException('Organisation ID is required.');
        }

        List<AggregateResult> warehouseResults;

            // if (String.isNotBlank(productId)) {
            //     warehouseResults = [
            //         SELECT Warehouse__r.Name warehouseName, SUM(Number_of_Item_In_Stock__c) totalQuantity
            //         FROM Inventory_Stock__c
            //         WHERE Warehouse__r.Company__c = :organisationId
            //         AND Product__c = :productId
            //         AND Active__c = true
            //         AND Name != 'Awaiting Stock'
            //         AND Number_of_Item_In_Stock__c > 0
            //         GROUP BY Warehouse__r.Name
            //         ORDER BY SUM(Number_of_Item_In_Stock__c) DESC LIMIT 2000
            //     ];
            // } else {
            //     warehouseResults = [
            //         SELECT Warehouse__r.Name warehouseName, SUM(Number_of_Item_In_Stock__c) totalQuantity
            //         FROM Inventory_Stock__c
            //         WHERE Warehouse__r.Company__c = :organisationId
            //         AND Active__c = true
            //         AND Name != 'Awaiting Stock'
            //         AND Number_of_Item_In_Stock__c > 0
            //         GROUP BY Warehouse__r.Name
            //         ORDER BY SUM(Number_of_Item_In_Stock__c) DESC LIMIT 2000
            //     ];
            // }
            // Start building the base query
            String query = 'SELECT Warehouse__r.Name warehouseName, ' +
                        'SUM(Number_of_Item_In_Stock__c) totalQuantity ' +
                        'FROM Inventory_Stock__c ' +
                        'WHERE Warehouse__r.Company__c = \'' + String.escapeSingleQuotes(organisationId) + '\' ' +
                        'AND Active__c = true ' +
                        'AND Name != \'Awaiting Stock\' ' +
                        'AND Number_of_Item_In_Stock__c > 0 ';

            // Conditionally add product filter
            if (String.isNotBlank(productId) && productId != 'null') {
                query += 'AND Product__c = \'' + String.escapeSingleQuotes(productId) + '\' ';
            }
            if (String.isNotBlank(version) && version != 'null') {
                query += 'AND Version__c = \'' + String.escapeSingleQuotes(version) + '\' ';
            }

            // Add grouping and ordering
            query += 'GROUP BY Warehouse__r.Name ' +
                    'ORDER BY SUM(Number_of_Item_In_Stock__c) DESC ' +
                    'LIMIT 2000';

            // Execute the query
            warehouseResults = Database.query(query);

        // Process results
        List<String> warehouseLabels = new List<String>();
        List<Decimal> warehouseInventory = new List<Decimal>();

        for (AggregateResult ar : warehouseResults) {
            warehouseLabels.add((String)ar.get('warehouseName'));
            warehouseInventory.add((Decimal)ar.get('totalQuantity'));
        }

        return new Map<String, Object>{
            'warehouseLabels' => warehouseLabels,
            'warehouseInventory' => warehouseInventory
        };
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching warehouse inventory: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getLocationInventory(String siteId, String organisationId , String productId,String version) {
        try {
            if (String.isBlank(siteId)) {
                throw new AuraHandledException('Site ID is required.');
            }
            if (String.isBlank(organisationId)) {
                throw new AuraHandledException('Organisation ID is required.');
            }
            // List<AggregateResult> locationResults;
            // Query inventory aggregated by location for the specific site
        //    if(String.isNotBlank(productId)){
        //     locationResults = [
        //         SELECT Location__r.Name locationName, 
        //             SUM(Number_of_Item_In_Stock__c) totalQuantity
        //         FROM Inventory_Stock__c
        //         WHERE Warehouse__r.Company__c = :organisationId
        //         AND Warehouse__c = :siteId
        //         AND Number_of_Item_In_Stock__c > 0
        //         AND Active__c = true
        //         AND Name != 'Awaiting Stock'
        //         AND Product__c = :productId
        //         GROUP BY Location__r.Name
        //         ORDER BY SUM(Number_of_Item_In_Stock__c) DESC LIMIT 2000
        //     ];
        //    }
        //    else{
        //    locationResults = [
        //         SELECT Location__r.Name locationName, 
        //             SUM(Number_of_Item_In_Stock__c) totalQuantity
        //         FROM Inventory_Stock__c
        //         WHERE Warehouse__r.Company__c = :organisationId
        //         AND Warehouse__c = :siteId
        //         AND Number_of_Item_In_Stock__c > 0
        //         AND Active__c = true
        //         AND Name != 'Awaiting Stock'
        //         GROUP BY Location__r.Name
        //         ORDER BY SUM(Number_of_Item_In_Stock__c) DESC LIMIT 2000
        //     ];
        //    }
// Prepare dynamic SOQL query parts
        String query = 'SELECT Location__r.Name locationName, ' +
                       'SUM(Number_of_Item_In_Stock__c) totalQuantity ' +
                       'FROM Inventory_Stock__c ' +
                       'WHERE Warehouse__r.Company__c = \'' + String.escapeSingleQuotes(organisationId) + '\' ' +
                       'AND Warehouse__c = \'' + String.escapeSingleQuotes(siteId) + '\' ' +
                       'AND Number_of_Item_In_Stock__c > 0 ' +
                       'AND Active__c = true ' +
                       'AND Name != \'Awaiting Stock\' ';

        // Add product filter if present
        if (String.isNotBlank(productId) && productId != 'null') {
            query += 'AND Product__c = \'' + String.escapeSingleQuotes(productId) + '\' ';
        }

        // Add version-specific logic
        if (String.isNotBlank(version) && version != 'null') {
            query += 'AND Version__c = \'' + String.escapeSingleQuotes(version) + '\' ';
        }

        // Final query clauses
        query += 'GROUP BY Location__r.Name ' +
                 'ORDER BY SUM(Number_of_Item_In_Stock__c) DESC ' +
                 'LIMIT 2000';

        // Execute the query
        List<AggregateResult> locationResults = Database.query(query);

            List<String> locationLabels = new List<String>();
            List<Decimal> locationInventory = new List<Decimal>();

            for (AggregateResult ar : locationResults) {
                String locationName = (String)ar.get('locationName');
                Decimal totalQuantity = (Decimal)ar.get('totalQuantity');

                if (locationName == null) {
                    locationName = 'No Location';
                }

                locationLabels.add(locationName);
                locationInventory.add(totalQuantity);
            }

            // If no results, add a placeholder to indicate no inventory
            if (locationLabels.isEmpty()) {
                locationLabels.add('No Location');       locationInventory.add(0);
            }

            return new Map<String, Object>{
                'locationLabels' => locationLabels,
                'locationInventory' => locationInventory
            };
        } catch (Exception e) {    throw new AuraHandledException('Error fetching location inventory: ' + e.getMessage());
        }
    }

// @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getStockAlertData(Id siteId,Id location, Id product,Id OrgId) {
//     System.debug('product '+product);
//     List<Map<String, Object>> results = new List<Map<String, Object>>();

//      if (siteId == null || OrgId == null) {
//         throw new AuraHandledException('Site (Warehouse) is required');
//     }

//     List<Inventory_Stock__c> inventoryRecords;

//     if (location != null && product != null) {
//         inventoryRecords = [
//             SELECT Product__c, Number_of_Item_In_Stock__c,
//                    Warehouse__r.Name, Location__r.Name
//             FROM Inventory_Stock__c
//             WHERE Active__c = true
//             AND Warehouse__c = :siteId
//             AND Location__c = :location
//             AND Product__c = :product
//             AND Name != 'Awaiting Stock'
//             AND Company__c = :OrgId
//             AND Number_of_Item_In_Stock__c > 0 LIMIT 2000
//         ];
//     }
//     // Site + Location
//     else if (location != null) {
//         inventoryRecords = [
//             SELECT Product__c, Number_of_Item_In_Stock__c,
//                    Warehouse__r.Name, Location__r.Name
//             FROM Inventory_Stock__c
//             WHERE Active__c = true
//             AND Warehouse__c = :siteId
//             AND Location__c = :location
//             AND Name != 'Awaiting Stock'
//             AND Company__c = :OrgId
//             AND Number_of_Item_In_Stock__c > 0
//         ];
//     }
//     // Site + Product
//     else if (product != null) {
//         inventoryRecords = [
//             SELECT Product__c, Number_of_Item_In_Stock__c,
//                    Warehouse__r.Name, Location__r.Name
//             FROM Inventory_Stock__c
//             WHERE Active__c = true
//             AND Warehouse__c = :siteId
//             AND Product__c = :product
//             AND Name != 'Awaiting Stock'
//             AND Company__c = :OrgId
//             AND Number_of_Item_In_Stock__c > 0
//         ];
//     }
//     // Only Site
//     else {
//         inventoryRecords = [
//             SELECT Product__c, Number_of_Item_In_Stock__c,
//                    Warehouse__r.Name, Location__r.Name
//             FROM Inventory_Stock__c
//             WHERE Active__c = true
//             AND Warehouse__c = :siteId
//             AND Name != 'Awaiting Stock'
//             AND Company__c = :OrgId
//             AND Number_of_Item_In_Stock__c > 0
//         ];
//     }
//     // Step 2: Aggregate stock by product + location + warehouse
//     Map<String, Map<String, Object>> dataMap = new Map<String, Map<String, Object>>();
//     Set<Id> productIds = new Set<Id>();

//     for (Inventory_Stock__c record : inventoryRecords) {
//         Id productId = record.Product__c;
//         String warehouseName = record.Warehouse__r.Name;
//         String locationName = record.Location__r.Name;
//         String key = productId + '|' + warehouseName + '|' + locationName;

//         productIds.add(productId);

//         if (!dataMap.containsKey(key)) {
//             dataMap.put(key, new Map<String, Object>{
//                 'productId' => productId,
//                 'currentStock' => 0,
//                 'warehouse' => warehouseName,
//                 'location' => locationName
//             });
//         }

//         Decimal currentTotal = (Decimal) dataMap.get(key).get('currentStock');
//         dataMap.get(key).put('currentStock', currentTotal + record.Number_of_Item_In_Stock__c);
//     }

//     if (productIds.isEmpty()) return results;

//     // Step 3: Get product names
//     Map<Id, String> productNameMap = new Map<Id, String>();
//     for (Product2 prod : [
//         SELECT Id, Name FROM Product2 WHERE Id IN :productIds
//     ]) {
//         productNameMap.put(prod.Id, prod.Name);
//     }

//     // Step 4: Get reordering rules
//     Map<Id, Reordering_Rule__c> ruleMap = new Map<Id, Reordering_Rule__c>();
//     for (Reordering_Rule__c rule : [
//         SELECT Product__c, Safety_Stock__c, Reorder_Level__c
//         FROM Reordering_Rule__c
//         WHERE Warehouse__c = :siteId
//         AND Product__c IN :productIds
//         AND Active__c = true
//     ]) {
//         ruleMap.put(rule.Product__c, rule);
//     }

//     // Step 5: Assemble final results
//     for (Map<String, Object> entry : dataMap.values()) {
//         Id productId = (Id) entry.get('productId');
//         Decimal currentStock = (Decimal) entry.get('currentStock');
//         Decimal reorderLevel = 0;
//         Decimal safetyStock = 0;

//         if (ruleMap.containsKey(productId)) {
//             Reordering_Rule__c rule = ruleMap.get(productId);
//             reorderLevel = rule.Reorder_Level__c != null ? rule.Reorder_Level__c : 0;
//             safetyStock = rule.Safety_Stock__c != null ? rule.Safety_Stock__c : 0;
//         }

//         entry.put('productName', productNameMap.get(productId));
//         entry.put('reorderLevel', reorderLevel);
//         entry.put('safetyStock', safetyStock);

//         results.add(entry);
//     }
//     System.debug('result '+results);
//     return results;
// }
@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getStockAlertData(Id siteId, Id location, Id product, Id OrgId) {
    if (siteId == null || OrgId == null) {
        throw new AuraHandledException('Site (Warehouse) and Organisation are required');
    }

    // Base query
    String baseQuery = 'SELECT Product__c, Number_of_Item_In_Stock__c, ' +
                       'Warehouse__r.Name, Location__r.Name ' +
                       'FROM Inventory_Stock__c ' +
                       'WHERE Active__c = true ' +
                       'AND Warehouse__c = :siteId ' +
                       'AND Company__c = :OrgId ' +
                       'AND Name != \'Awaiting Stock\' ' +
                       'AND Number_of_Item_In_Stock__c > 0 ';

    if (location != null) {
        baseQuery += 'AND Location__c = :location ';
    }
    if (product != null) {
        baseQuery += 'AND Product__c = :product ';
    }

    // Optional: Add limit if product and location both given (small result set)
    if (location != null && product != null) {
        baseQuery += 'LIMIT 2000 ';
    }

    List<Inventory_Stock__c> inventoryRecords = Database.query(baseQuery);

    // Step 2: Group by Product + Warehouse + Location
    Map<String, Map<String, Object>> dataMap = new Map<String, Map<String, Object>>();
    Set<Id> productIds = new Set<Id>();

    for (Inventory_Stock__c stock : inventoryRecords) {
        Id productId = stock.Product__c;
        String warehouseName = stock.Warehouse__r.Name;
        String locationName = stock.Location__r.Name;
        String key = productId + '|' + warehouseName + '|' + locationName;

        productIds.add(productId);

        if (!dataMap.containsKey(key)) {
            dataMap.put(key, new Map<String, Object>{
                'productId' => productId,
                'currentStock' => 0,
                'warehouse' => warehouseName,
                'location' => locationName
            });
        }

        Decimal existing = (Decimal) dataMap.get(key).get('currentStock');
        dataMap.get(key).put('currentStock', existing + stock.Number_of_Item_In_Stock__c);
    }

    if (productIds.isEmpty()) return new List<Map<String, Object>>();

    // Step 3: Product names
    Map<Id, String> productNameMap = new Map<Id, String>();
    for (Product2 prod : [SELECT Id, Name FROM Product2 WHERE Id IN :productIds]) {
        productNameMap.put(prod.Id, prod.Name);
    }

    // Step 4: Reordering rules
    Map<Id, Reordering_Rule__c> ruleMap = new Map<Id, Reordering_Rule__c>();
    for (Reordering_Rule__c rule : [
        SELECT Product__c, Safety_Stock__c, Reorder_Level__c
        FROM Reordering_Rule__c
        WHERE Warehouse__c = :siteId
        AND Product__c IN :productIds
        AND Active__c = true
    ]) {
        ruleMap.put(rule.Product__c, rule);
    }

    // Step 5: Assemble result
    List<Map<String, Object>> results = new List<Map<String, Object>>();
    for (Map<String, Object> row : dataMap.values()) {
        Id productId = (Id) row.get('productId');
        Decimal stock = (Decimal) row.get('currentStock');
        Decimal reorder = 0;
        Decimal safety = 0;

        if (ruleMap.containsKey(productId)) {
            Reordering_Rule__c rule = ruleMap.get(productId);
            reorder = rule.Reorder_Level__c != null ? rule.Reorder_Level__c : 0;
            safety = rule.Safety_Stock__c != null ? rule.Safety_Stock__c : 0;
        }

        row.put('productName', productNameMap.get(productId));
        row.put('reorderLevel', reorder);
        row.put('safetyStock', safety);

        results.add(row);
    }
System.debug('FINAL RESULTS: ' + results);

    return results;
}

// @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getDynamicStockAgingData(Id siteId, Id orgId, Id prodId) {
//     if (siteId == null || orgId == null) {
//         throw new AuraHandledException('Site ID and Organisation ID are required.');
//     }

//     String baseQuery = 'SELECT Product__c, Product__r.Name, Number_of_Item_In_Stock__c, ' +
//                        'Checked_In_Date__c, Expiry_Date__c, Expiration_Date__c, Status__c ' +
//                        'FROM Inventory_Stock__c ' +
//                        'WHERE Checked_In_Date__c != NULL ' +
//                        'AND Number_of_Item_In_Stock__c > 0 ' +
//                        'AND Warehouse__c = :siteId ' +
//                        'AND Active__c = true ' +
//                        'AND Name != \'Awaiting Stock\' ' +
//                        'AND Company__c = :orgId';

//     if (prodId != null) {
//         baseQuery += ' AND Product__c = :prodId';
//     }

//     baseQuery += ' LIMIT 5000';

//     List<Inventory_Stock__c> stocks = Database.query(baseQuery);
//     List<Map<String, Object>> agingList = new List<Map<String, Object>>();

//     for (Inventory_Stock__c stock : stocks) {
//         Boolean isExpired = false;
//         if (stock.Status__c == 'Expired' || 
//             (stock.Expiry_Date__c != null && stock.Expiry_Date__c <= Date.today()) ||
//             (stock.Expiration_Date__c != null && stock.Expiration_Date__c <= Date.today())) {
//             isExpired = true;
//         }

//         Date received = stock.Checked_In_Date__c;
//         Integer ageInDays = Date.today().daysBetween(received);

//         String bucket;
//         if (isExpired) {
//             bucket = 'Expired';
//         } else if (ageInDays < 30) {
//             bucket = '<30d';
//         } else if (ageInDays < 90) {
//             bucket = '30–90d';
//         } else if (ageInDays < 180) {
//             bucket = '90–180d';
//         } else if (ageInDays < 365) {
//             bucket = '180–365d';
//         } else {
//             bucket = '>365d';
//         }

//         String status = 'Fresh';
//         if (isExpired) {
//             status = 'Expired';
//         } else if (ageInDays >= 365) {
//             status = 'Obsolete';
//         } else if (ageInDays >= 180) {
//             status = 'At Risk';
//         } else if (ageInDays >= 90) {
//             status = 'Aging';
//         } else if (ageInDays >= 30) {
//             status = 'Slow Moving';
//         }

//         agingList.add(new Map<String, Object>{
//             'productId' => stock.Product__c,
//             'productName' => stock.Product__r.Name,
//             'quantity' => stock.Number_of_Item_In_Stock__c,
//             'receivedDate' => received,
//             'ageInDays' => ageInDays,
//             'bucket' => bucket,
//             'status' => status,
//             'isExpired' => isExpired
//         });
//     }

//     return agingList;
// }
@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getDynamicStockAgingData(Id siteId, Id orgId, Id prodId) {
    if (siteId == null || orgId == null) {
        throw new AuraHandledException('Site ID and Organisation ID are required.');
    }

    Map<String, Map<String, Object>> groupedMap = new Map<String, Map<String, Object>>();

    String baseQuery = 'SELECT Product__c, Product__r.Name, Product__r.Serialise__c, ' +
                       'Number_of_Item_In_Stock__c, Checked_In_Date__c, Expiry_Date__c, ' +
                       'Expiration_Date__c, Status__c ' +
                       'FROM Inventory_Stock__c ' +
                       'WHERE Checked_In_Date__c != NULL ' +
                       'AND Number_of_Item_In_Stock__c > 0 ' +
                       'AND Warehouse__c = :siteId ' +
                       'AND Active__c = true ' +
                       'AND Name != \'Awaiting Stock\' ' +
                       'AND Company__c = :orgId';

    if (prodId != null) {
        baseQuery += ' AND Product__c = :prodId';
    }

    baseQuery += ' LIMIT 5000';

    List<Inventory_Stock__c> stocks = Database.query(baseQuery);

    for (Inventory_Stock__c stock : stocks) {
        Boolean isSerialised = stock.Product__r.Serialise__c;
        String key = isSerialised
            ? stock.Product__c + '-' + String.valueOf(stock.Checked_In_Date__c)
            : String.valueOf(stock.Product__c);

        Boolean isExpired = false;
        if (stock.Status__c == 'Expired') {
            isExpired = true;
        } else if (stock.Expiry_Date__c != null && stock.Expiry_Date__c <= Date.today()) {
            isExpired = true;
        } else if (stock.Expiration_Date__c != null && stock.Expiration_Date__c <= Date.today()) {
            isExpired = true;
        }

        if (!groupedMap.containsKey(key)) {
            groupedMap.put(key, new Map<String, Object>{
                'productId' => stock.Product__c,
                'productName' => stock.Product__r.Name,
                'quantity' => stock.Number_of_Item_In_Stock__c,
                'receivedDate' => stock.Checked_In_Date__c,
                'isExpired' => isExpired
            });
        } else {
            Map<String, Object> existing = groupedMap.get(key);
            Decimal qty = (Decimal)existing.get('quantity');
            existing.put('quantity', qty + stock.Number_of_Item_In_Stock__c);

            if ((Boolean)existing.get('isExpired') == false && isExpired) {
                existing.put('isExpired', true);
            }

            // For serialised, receivedDate should remain same; for non-serial, take earliest
            if (!isSerialised) {
                Date existingDate = (Date)existing.get('receivedDate');
                if (stock.Checked_In_Date__c < existingDate) {
                    existing.put('receivedDate', stock.Checked_In_Date__c);
                }
            }
        }
    }

    return groupedMap.values();
}

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getAgingTrendData(Id siteId, Id orgId, Id prodId, String yearStr) {
    Integer year = Integer.valueOf(yearStr);
    Date lastDayOfYear = Date.newInstance(year, 12, 31);
    
    List<Map<String, Object>> trendData = new List<Map<String, Object>>();
    List<String> allBuckets = new List<String>{ '<30d', '30–90d', '90–180d', '180–365d', '>365d', 'Expired' };

    // Step 1: Fetch all stock records received up to the selected year
    String baseQuery = 'SELECT Product__c, Checked_In_Date__c, Number_of_Item_In_Stock__c, ' +
                       'Expiry_Date__c, Expiration_Date__c, Status__c ' +
                       'FROM Inventory_Stock__c ' +
                       'WHERE Number_of_Item_In_Stock__c > 0 ' +
                       'AND Warehouse__c = :siteId ' +
                       'AND Company__c = :orgId ' +
                       'AND Active__c = true ' +
                       'AND Name != \'Awaiting Stock\' ' +
                       'AND Checked_In_Date__c <= :lastDayOfYear';
	
    if (prodId != null) {
        baseQuery += ' AND Product__c = :prodId';
    }
    baseQuery += ' LIMIT 5000'; 
    List<Inventory_Stock__c> allStocks = Database.query(baseQuery);
	System.debug('ALLSTOCKS->'+allStocks);
    // Step 2: Build monthly trend
    for (Integer m = 1; m <= 12; m++) {
        Date snapshotDate = Date.newInstance(year, m, 1).addMonths(1).addDays(-1); // last day of the month

        Integer monthInt = snapshotDate.month();
        String monthStr = (monthInt < 10 ? '0' : '') + String.valueOf(monthInt);
        String monthKey = String.valueOf(snapshotDate.year()) + '-' + monthStr;

        Map<String, Decimal> bucketMap = new Map<String, Decimal>();

        for (Inventory_Stock__c stock : allStocks) {
            if (stock.Checked_In_Date__c == null || stock.Checked_In_Date__c > snapshotDate) {     continue;
            }

            Integer age = stock.Checked_In_Date__c.daysBetween(snapshotDate);  String bucket;

            if (stock.Status__c == 'Expired' ||
                (stock.Expiry_Date__c != null && stock.Expiry_Date__c <= snapshotDate) ||
                (stock.Expiration_Date__c != null && stock.Expiration_Date__c <= snapshotDate)) {
                bucket = 'Expired';
            } else if (age < 30) {    bucket = '<30d';} else if (age < 90) {    bucket = '30–90d';} else if (age < 180) {    bucket = '90–180d';
            } else if (age < 365) {   bucket = '180–365d'; } else {   bucket = '>365d';
            }

            Decimal qty = stock.Number_of_Item_In_Stock__c;           bucketMap.put(bucket, bucketMap.containsKey(bucket) ? bucketMap.get(bucket) + qty : qty);
        }

        // Step 3: Add row to trend data
        Map<String, Object> row = new Map<String, Object>();
        row.put('month', monthKey);
        for (String bucket : allBuckets) {
            row.put(bucket, bucketMap.containsKey(bucket) ? bucketMap.get(bucket) : 0);
        }

        trendData.add(row);
    }
    return trendData;
}
@AuraEnabled(cacheable=true)
public static Map<String, Object> getCustomerOrderTrend(Id customerId, Id productId, Id orgId, String yearStr) {
    System.debug('in getCustomerOrderTrend');

    Map<String, Object> result = new Map<String, Object>();
    System.debug('customerId -> ' + customerId + ' | productId -> ' + productId + ' | orgId -> ' + orgId + ' | yearStr -> ' + yearStr);

    if (String.isBlank(customerId) || String.isBlank(orgId)) {
        System.debug('Missing customerId or orgId');
        result.put('months', new List<String>());       result.put('quantities', new List<Decimal>());       return result;
    }

    Integer selectedYear = String.isNotBlank(yearStr) ? Integer.valueOf(yearStr) : Date.today().year();
    Date startOfYear = Date.newInstance(selectedYear, 1, 1);
    Date endOfYear = Date.newInstance(selectedYear, 12, 31);

    List<OrderItem> orderItems;

    if (productId != null) {
        orderItems = [
            SELECT Quantity, Product2Id, Order.EffectiveDate, Order.AccountId
            FROM OrderItem
            WHERE Order.AccountId = :customerId
            AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
            AND Order.EffectiveDate  >= :startOfYear AND Order.EffectiveDate  <= :endOfYear
            AND Company__c = :orgId
            AND Product2Id = :productId
            LIMIT 2000
        ];
    } else {
        orderItems = [
            SELECT Quantity, Product2Id, Order.EffectiveDate, Order.AccountId
            FROM OrderItem
            WHERE Order.AccountId = :customerId
            AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
            AND Order.EffectiveDate  >= :startOfYear AND Order.EffectiveDate  <= :endOfYear
            AND Company__c = :orgId
            LIMIT 2000
        ];
    }

    Map<String, Decimal> monthlyData = new Map<String, Decimal>();

    for (OrderItem oi : orderItems) {
        if (oi.Order != null && oi.Order.EffectiveDate  != null) {
            Date orderDate = oi.Order.EffectiveDate;            String monthLabel = getMonthLabel(orderDate.month());

            if (!monthlyData.containsKey(monthLabel)) {               monthlyData.put(monthLabel, 0);
            }
            monthlyData.put(monthLabel, monthlyData.get(monthLabel) + oi.Quantity);
        }
    }

    List<String> months = new List<String>{ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
    List<Decimal> quantities = new List<Decimal>();
    for (String m : months) {
        quantities.add(monthlyData.containsKey(m) ? monthlyData.get(m) : 0);
    }

    result.put('months', months);
    result.put('quantities', quantities);
    System.debug('result -> ' + result);

    return result;
}

// Helper to convert numeric month to label
private static String getMonthLabel(Integer monthNumber) {
    List<String> monthLabels = new List<String>{
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    };
    return monthLabels[monthNumber - 1];
}
@AuraEnabled(cacheable=true)
public static Map<String, Object> getCustomerSummary(Id customerId, Id productId, String yearStr,Id orgId) {
    Integer year = String.isNotBlank(yearStr) ? Integer.valueOf(yearStr) : Date.today().year();
    Date startOfYear = Date.newInstance(year, 1, 1);
    Date endOfYear = Date.newInstance(year, 12, 31);
    List<OrderItem> items;

if (productId != null) {
    items = [
        SELECT Quantity, TotalPrice, Order.EffectiveDate
        FROM OrderItem
        WHERE Order.AccountId = :customerId
        AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND Order.EffectiveDate >= :startOfYear AND Order.EffectiveDate <= :endOfYear
        AND Company__c = :orgId
        AND Product2Id = :productId
        LIMIT 2000
    ];
} else {
    items = [
        SELECT Quantity, TotalPrice, Order.EffectiveDate
        FROM OrderItem
        WHERE Order.AccountId = :customerId
        AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND Order.EffectiveDate >= :startOfYear AND Order.EffectiveDate <= :endOfYear
        AND Company__c = :orgId
        LIMIT 2000
    ];
}
    Integer frequency = items.size();
    Decimal totalAmount = 0;
    Datetime  mostRecentDate = null;

    for (OrderItem oi : items) {
        totalAmount += oi.TotalPrice;
        if (mostRecentDate == null || oi.Order.EffectiveDate > mostRecentDate) {            mostRecentDate = oi.Order.EffectiveDate;
        }
    }

//    Integer daysSinceLastOrder = mostRecentDate != null
//     ? Date.today().daysBetween(Date.newInstance(mostRecentDate.year(), mostRecentDate.month(), mostRecentDate.day()))
//     : null;
    Integer daysSinceLastOrder = mostRecentDate != null
    ? Math.abs(Date.today().daysBetween(Date.newInstance(mostRecentDate.year(), mostRecentDate.month(), mostRecentDate.day())))
    : null;

    System.debug('Customer Summary: Frequency -> ' + frequency + ', Total Amount -> ' + totalAmount +
                 ', Days Since Last Order -> ' + daysSinceLastOrder + ', Last Order Date -> ' + mostRecentDate);
    return new Map<String, Object>{
        'frequency' => frequency,
        'monetary' => totalAmount,
        'recencyDays' => daysSinceLastOrder,
        'lastOrderDate' => mostRecentDate
    };
}

// @AuraEnabled(cacheable=true)
// public static Map<String, Object> getDemandForecastWithHistory(Id productId, String dummyYear) {
//     Date endDate = Date.today();
//     Date startDate = endDate.addYears(-3); // Last 3 years

//     // Step 1: Fetch grouped demand by Year + Month
//     List<AggregateResult> results = [
//         SELECT CALENDAR_YEAR(Order.CreatedDate) yr,
//                CALENDAR_MONTH(Order.CreatedDate) mon,
//                SUM(Quantity) qty
//         FROM OrderItem
//         WHERE Product2Id = :productId
//         AND Order.Status = 'Activated'
//         AND Order.CreatedDate >= :startDate AND Order.CreatedDate <= :endDate
//         GROUP BY CALENDAR_YEAR(Order.CreatedDate), CALENDAR_MONTH(Order.CreatedDate)
//         ORDER BY CALENDAR_YEAR(Order.CreatedDate), CALENDAR_MONTH(Order.CreatedDate)
//     ];

//     // Step 2: Build a complete time series (e.g., "Jan 2022", "Feb 2022", ..., "Jun 2025")
//     Map<String, Decimal> demandMap = new Map<String, Decimal>();
//     for (AggregateResult ar : results) {
//         Integer y = (Integer)ar.get('yr');
//         Integer m = (Integer)ar.get('mon');
//         String label = getMonthLabel(m) + ' ' + y;
//         Decimal qty = (Decimal)ar.get('qty');
//         demandMap.put(label, qty.setScale(2));
//     }

//     List<String> monthLabels = new List<String>();
//     List<Decimal> demandValues = new List<Decimal>();

//     Date d = startDate.toStartOfMonth();
//     while (d <= endDate) {
//         String label = getMonthLabel(d.month()) + ' ' + d.year();
//         monthLabels.add(label);
//         demandValues.add(demandMap.containsKey(label) ? demandMap.get(label) : 0);
//         d = d.addMonths(1);
//     }

//     // Step 3: Run forecast on full series
//     Integer forecastMonths = 6;
//     Integer seasonLength = 12;
//     ForecastResult forecastResult = runHoltWinters(demandValues, forecastMonths, seasonLength);

//     // Step 4: Return combined result
//     Map<String, Object> result = new Map<String, Object>();
//     result.put('historicalMonths', monthLabels);
//     result.put('historicalValues', demandValues);
//     result.put('forecastMonths', forecastResult.forecastMonths);
//     result.put('forecastValues', forecastResult.forecastValues);

//     return result;
// }


// private static ForecastResult runHoltWinters(List<Decimal> values, Integer m, Integer seasonLength) {
//     Decimal alpha = 0.5;
//     Decimal beta = 0.3;
//     Decimal gamma = 0.2;

//     Integer len = values.size();
//     if (len < seasonLength * 2) {
//         throw new AuraHandledException('Not enough data for Holt-Winters.');
//     }

//     List<Decimal> level = new List<Decimal>{ values[0] };
//     List<Decimal> trend = new List<Decimal>{ values[1] - values[0] };
//     List<Decimal> seasonals = initSeasonals(values, seasonLength);

//     for (Integer i = 1; i < len; i++) {
//         Decimal lastLevel = level[i - 1];
//         Decimal lastTrend = trend[i - 1];
//         Integer sIndex = Math.mod(i, seasonLength);
//         Decimal seasonal = seasonals[sIndex];
//         Decimal current = values[i];

//         Decimal newLevel = alpha * (current - seasonal) + (1 - alpha) * (lastLevel + lastTrend);
//         Decimal newTrend = beta * (newLevel - lastLevel) + (1 - beta) * lastTrend;
//         Decimal newSeasonal = gamma * (current - newLevel) + (1 - gamma) * seasonal;

//         level.add(newLevel);
//         trend.add(newTrend);
//         seasonals[sIndex] = newSeasonal;
//     }

//     ForecastResult result = new ForecastResult();
//     result.forecastMonths = new List<String>();
//     result.forecastValues = new List<Decimal>();

//     Date today = Date.today();
//     for (Integer i = 1; i <= m; i++) {
//         Decimal l = level[len - 1];
//         Decimal t = trend[len - 1];
//         Integer sIndex = Math.mod(len + i - 1, seasonLength);
//         Decimal s = seasonals[sIndex];
//         Decimal f = l + (i * t) + s;
//         //result.forecastValues.add(f.setScale(2));
//         result.forecastValues.add(Math.max(f, 0).setScale(2));

//         Date monthDate = today.addMonths(i);
//         result.forecastMonths.add(getMonthLabel(monthDate.month()));
//     }

//     return result;
// }

private static List<Decimal> initSeasonals(List<Decimal> values, Integer seasonLength) {
    List<Decimal> seasonals = new List<Decimal>();
    for (Integer i = 0; i < seasonLength; i++) {
        Decimal sum = 0;
        Integer count = 0;
        for (Integer j = i; j < values.size(); j += seasonLength) {
            sum += values[j];
            count++;
        }
        Decimal avg = (count > 0) ? sum / count : 0;
        seasonals.add(avg);
    }
    return seasonals;
}


// Forecast result structure
public class ForecastResult {
    @AuraEnabled public List<String> forecastMonths;
    @AuraEnabled public List<Decimal> forecastValues;
}

// new 
@AuraEnabled
public static Map<String, Object> getHistoricalDemandData(Id productId, String dummyYear) {
    //System.debug('OrgId -> ' + OrgId + ' | productId -> ' + productId);
    // If(OrgId == null || orgId == ''){
    //     throw new AuraHandledException('Organisation ID is required.');
    // }
    Date endDate = Date.today();
    Date startDate = endDate.addYears(-3); // Last 3 years

    List<AggregateResult> results = [
        SELECT CALENDAR_YEAR(Order.EffectiveDate) yr,
               CALENDAR_MONTH(Order.EffectiveDate) mon,
               SUM(Quantity) qty
        FROM OrderItem
        WHERE Product2Id = :productId
        AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND Order.EffectiveDate >= :startDate AND Order.EffectiveDate <= :endDate
        GROUP BY CALENDAR_YEAR(Order.EffectiveDate), CALENDAR_MONTH(Order.EffectiveDate)
        ORDER BY CALENDAR_YEAR(Order.EffectiveDate), CALENDAR_MONTH(Order.EffectiveDate)
    ];
System.debug('fetched');
    Map<String, Decimal> demandMap = new Map<String, Decimal>();
    for (AggregateResult ar : results) {
        Integer y = (Integer)ar.get('yr');        Integer m = (Integer)ar.get('mon');        String label = getMonthLabel(m) + ' ' + y;        Decimal qty = (Decimal)ar.get('qty');        demandMap.put(label, qty.setScale(2));
    }

    List<String> monthLabels = new List<String>();
    List<Decimal> demandValues = new List<Decimal>();

    Date d = startDate.toStartOfMonth();
    while (d <= endDate) {
        String label = getMonthLabel(d.month()) + ' ' + d.year();
        monthLabels.add(label);
        demandValues.add(demandMap.containsKey(label) ? demandMap.get(label) : 0);
        d = d.addMonths(1);
    }

    Map<String, Object> result = new Map<String, Object>();
    result.put('historicalMonths', monthLabels);
    result.put('historicalValues', demandValues);
    return result;
}
@AuraEnabled
public static ForecastResult generateForecastFromHistorical(List<Decimal> historicalValues, String modelName) {
    Integer forecastMonths = 6;
    Integer seasonLength = 12;

    if (modelName == 'Holt-Winters') {
        if (historicalValues.size() < seasonLength * 2) {         throw new AuraHandledException('Not enough data for Holt-Winters.');
        }
        return runHoltWintersForecast(historicalValues, forecastMonths, seasonLength);
    } else if (modelName == 'MOVING_AVERAGE') {      return runMovingAverageForecast(historicalValues, forecastMonths);
    }

    throw new AuraHandledException('Unsupported model: ' + modelName);
}

private static ForecastResult runHoltWintersForecast(List<Decimal> values, Integer m, Integer seasonLength) {
    Decimal alpha = 0.5;
    Decimal beta = 0.3;
    Decimal gamma = 0.2;

    Integer len = values.size();
    if (len < seasonLength * 2) {
        throw new AuraHandledException('Not enough data for Holt-Winters.');
    }

    List<Decimal> level = new List<Decimal>{ values[0] };
    List<Decimal> trend = new List<Decimal>{ values[1] - values[0] };
    List<Decimal> seasonals = initSeasonals(values, seasonLength);

    for (Integer i = 1; i < len; i++) {
        Decimal lastLevel = level[i - 1];
        Decimal lastTrend = trend[i - 1];
        Integer sIndex = Math.mod(i, seasonLength);
        Decimal seasonal = seasonals[sIndex];
        Decimal current = values[i];

        Decimal newLevel = alpha * (current - seasonal) + (1 - alpha) * (lastLevel + lastTrend);
        Decimal newTrend = beta * (newLevel - lastLevel) + (1 - beta) * lastTrend;
        Decimal newSeasonal = gamma * (current - newLevel) + (1 - gamma) * seasonal;

        level.add(newLevel);
        trend.add(newTrend);
        seasonals[sIndex] = newSeasonal;
    }

    ForecastResult result = new ForecastResult();
    result.forecastMonths = new List<String>();
    result.forecastValues = new List<Decimal>();

    Date today = Date.today();
    for (Integer i = 1; i <= m; i++) {
        Decimal l = level[len - 1];
        Decimal t = trend[len - 1];
        Integer sIndex = Math.mod(len + i - 1, seasonLength);
        Decimal s = seasonals[sIndex];
        Decimal f = l + (i * t) + s;
        result.forecastValues.add(Math.max(f, 0).setScale(2));

        Date monthDate = today.addMonths(i);
        result.forecastMonths.add(getMonthLabel(monthDate.month()) + ' ' + monthDate.year());
    }

    return result;
}
private static ForecastResult runMovingAverageForecast(List<Decimal> inputValues, Integer forecastMonths) {
    Integer window = 12;

    ForecastResult result = new ForecastResult();
    result.forecastValues = new List<Decimal>();
    result.forecastMonths = new List<String>();

    // Clone values to avoid mutating original list
    List<Decimal> values = new List<Decimal>(inputValues);

    Date baseMonth = Date.today();

    for (Integer i = 0; i < forecastMonths; i++) {
        Decimal sum = 0;
        Integer count = 0;

        for (Integer j = values.size() - window; j < values.size(); j++) {
            if (j >= 0) {
                sum += values[j];
                count++;
            }
        }

        Decimal avg = (count > 0) ? (sum / count).setScale(2) : 0;
        values.add(avg); // Extend forecast base

        Date forecastMonth = baseMonth.addMonths(i + 1);
        String label = getMonthLabel(forecastMonth.month()) + ' ' + forecastMonth.year();

        result.forecastMonths.add(label);
        result.forecastValues.add(avg);
    }

    return result;
}

@AuraEnabled(cacheable=true)
public static Map<String, Object> getDemandForecastWithHistory(Id productId, String modelName) {
    System.debug('getDemandForecastWithHistory called for productId: ' + productId + ', modelName: ' + modelName);
    Map<String, Object> history = getHistoricalDemandData(productId, ''); // will ignore this year filter for now
    List<Decimal> demandValues = (List<Decimal>) history.get('historicalValues');

    ForecastResult forecast;

    if (modelName == 'MOVING_AVERAGE') {
        forecast = runMovingAverageForecast(demandValues, 6);
    } else {
        // Default to Holt-Winters
        forecast = runHoltWintersForecast(demandValues, 6, 12);
    }

    history.put('forecastMonths', forecast.forecastMonths);
    history.put('forecastValues', forecast.forecastValues);

    return history;
}

@AuraEnabled(cacheable=true)
    public static String getCurrencySymbol() {
    Boolean multiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');
    String currencyISO;
    Decimal currencyRate;
    String userIsoCode;
 
    String selectedIso = null; // ← no input, uses user's default
 
    if (selectedIso != null) {
        currencyISO = selectedIso;
    } else {
        currencyISO = UserInfo.getDefaultCurrency();
    }
 
    if (multiCurrencyEnabled) {
        userIsoCode = currencyISO;       String iso = userIsoCode;
        String q = 'SELECT IsoCode, conversionRate FROM CurrencyType WHERE IsoCode = :iso';       currencyRate = (Decimal) Database.query(q)[0].get('conversionRate');
    } else {
        userIsoCode = currencyISO;
        currencyRate = 1;
    }
 
    // ✅ Symbol mapping
    Map<String, String> symbolMap = new Map<String, String>{
        'USD' => '$',
        'GBP' => '£',
        'EUR' => '€',
        'JPY' => '¥'
    };
 
    return symbolMap.containsKey(currencyISO) ? symbolMap.get(currencyISO) : currencyISO;
}
// risk and return methods

// public class ReturnProductSummary {
//     @AuraEnabled public String productId;
//     @AuraEnabled public String productName;
//     @AuraEnabled public Integer totalReturnedQty;
//     @AuraEnabled public Integer totalSoldQty;
//     @AuraEnabled public Decimal returnRate;
//     @AuraEnabled public String topReturnReason;
//     @AuraEnabled public Integer totalReturnCases;
//     @AuraEnabled public Date lastReturnDate;
// }

// public class ComparatorByReturnedQty implements Comparator<Object> {
//     public Integer compare(Object a, Object b) {
//         sandOP.ReturnProductSummary rp1 = (sandOP.ReturnProductSummary)a;
//         sandOP.ReturnProductSummary rp2 = (sandOP.ReturnProductSummary)b;
//         return rp2.totalReturnedQty - rp1.totalReturnedQty; // Descending
//     }
// }



// @AuraEnabled(cacheable=true)
// public static List<ReturnProductSummary> getTopReturnedProducts(String organisationId, Integer limitCount) {
//     Map<Id, ReturnProductSummary> returnMap = new Map<Id, ReturnProductSummary>();
//     Map<Id, Map<String, Integer>> reasonCountMap = new Map<Id, Map<String, Integer>>();
//     Map<Id, Integer> returnCaseCountMap = new Map<Id, Integer>();
//     Map<Id, Date> lastReturnDateMap = new Map<Id, Date>();

//     // 1. Aggregate returned quantities, reasons, and return dates per product
//     List<AggregateResult> returnAgg = [
//         SELECT Product__c productId,
//                Product__r.Name productName,
//                SUM(Quantity_Return__c) totalReturnedQty,
//                Acceptance_Type__c reason,
//                COUNT(Id) returnCases,
//                MAX(CreatedDate) lastReturnDate
//         FROM RMA_Line_Item__c
//         WHERE Company__c = :organisationId
//         GROUP BY Product__c, Product__r.Name, Acceptance_Type__c
//     ];

//     for (AggregateResult ar : returnAgg) {
//         Id productId = (Id)ar.get('productId');
//         String reason = (String)ar.get('reason');
//         Integer qty = ((Decimal)ar.get('totalReturnedQty')).intValue();
//         Integer caseCount = ((Decimal)ar.get('returnCases')).intValue();
//         DateTime dt = (DateTime)ar.get('lastReturnDate');
//         Date lastReturnDate = dt.date();


//         if (!returnMap.containsKey(productId)) {
//             ReturnProductSummary summary = new ReturnProductSummary();
//             summary.productId = productId;
//             summary.productName = (String)ar.get('productName');
//             summary.totalReturnedQty = 0;
//             returnMap.put(productId, summary);
//         }

//         returnMap.get(productId).totalReturnedQty += qty;

//         // Count reasons
//         if (!reasonCountMap.containsKey(productId)) {
//             reasonCountMap.put(productId, new Map<String, Integer>());
//         }
//         Map<String, Integer> reasonMap = reasonCountMap.get(productId);
//         reasonMap.put(reason, reasonMap.containsKey(reason) ? reasonMap.get(reason) + qty : qty);

//         // Track return cases
//         returnCaseCountMap.put(productId, returnCaseCountMap.containsKey(productId)
//             ? returnCaseCountMap.get(productId) + caseCount : caseCount);

//         // Track latest return date
//         if (!lastReturnDateMap.containsKey(productId) || lastReturnDateMap.get(productId) < lastReturnDate) {
//             lastReturnDateMap.put(productId, lastReturnDate);
//         }
//     }

//     // 2. Get sold quantities for these products
//     List<AggregateResult> soldAgg = [
//         SELECT Product2Id, SUM(Quantity) totalSold
//         FROM OrderItem
//         WHERE Product2Id IN :returnMap.keySet() AND Company__c = :organisationId
//         AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
//         GROUP BY Product2Id 
//     ];

//     for (AggregateResult ar : soldAgg) {
//         Id productId = (Id)ar.get('Product2Id');
//         if (returnMap.containsKey(productId)) {
//             Integer soldQty = ((Decimal)ar.get('totalSold')).intValue();
//             returnMap.get(productId).totalSoldQty = soldQty;
//            returnMap.get(productId).returnRate = soldQty > 0
//             ? (((Decimal)returnMap.get(productId).totalReturnedQty / soldQty) * 100).setScale(2)
//             : 0;
//         }
//     }

//     // 3. Set top reason, total return cases, and last return date
//     for (Id productId : returnMap.keySet()) {
//         ReturnProductSummary summary = returnMap.get(productId);
//         Map<String, Integer> reasons = reasonCountMap.get(productId);
//         if (reasons != null) {
//             String topReason = null;
//             Integer maxQty = 0;
//             for (String r : reasons.keySet()) {
//                 if (reasons.get(r) > maxQty) {
//                     maxQty = reasons.get(r);
//                     topReason = r;
//                 }
//             }
//             summary.topReturnReason = topReason;
//         }
//         summary.totalReturnCases = returnCaseCountMap.get(productId);
//         summary.lastReturnDate = lastReturnDateMap.get(productId);
//     }

//     // 4. Sort the results by returned quantity (descending)
//     List<ReturnProductSummary> sorted = new List<ReturnProductSummary>(returnMap.values());
//     sorted.sort(new ComparatorByReturnedQty());

//     // 5. Limit results to top N
//     List<ReturnProductSummary> topResults = new List<ReturnProductSummary>();
//     for (Integer i = 0; i < Math.min(limitCount, sorted.size()); i++) {
//         topResults.add(sorted[i]);
//     }
//     System.debug('Top Returned Products: ' + topResults);
//     return topResults;
// }
public class ReturnProductSummary {
    @AuraEnabled public String productId;
    @AuraEnabled public String productName;
    @AuraEnabled public Integer totalReturnedQty = 0;
    @AuraEnabled public Integer totalSoldQty = 0;
    @AuraEnabled public Decimal returnRate = 0;
    @AuraEnabled public String topReturnReason;
    @AuraEnabled public Integer totalReturnCases = 0;
    @AuraEnabled public Date lastReturnDate;
}

public class ComparatorByReturnedQty implements Comparator<Object> {
    public Integer compare(Object a, Object b) {
        sandOP.ReturnProductSummary rp1 = (sandOP.ReturnProductSummary)a;  sandOP.ReturnProductSummary rp2 = (sandOP.ReturnProductSummary)b;    return rp2.totalReturnedQty - rp1.totalReturnedQty;
    }
}

@AuraEnabled(cacheable=true)
public static List<ReturnProductSummary> getTopReturnedProducts(String organisationId, Integer limitCount) {
    Map<Id, ReturnProductSummary> returnMap = new Map<Id, ReturnProductSummary>();
    Map<Id, Map<String, Integer>> reasonCountMap = new Map<Id, Map<String, Integer>>();
    Map<Id, Integer> returnCaseCountMap = new Map<Id, Integer>();
    Map<Id, Date> lastReturnDateMap = new Map<Id, Date>();

    // 1. Aggregate returned quantities, reasons, and return dates per product
    List<AggregateResult> returnAgg = [
        SELECT Product__c productId,
               Product__r.Name productName,
               SUM(Quantity_Return__c) totalReturnedQty,
               Acceptance_Type__c reason,
               COUNT(Id) returnCases,
               MAX(CreatedDate) lastReturnDate
        FROM RMA_Line_Item__c
        WHERE Company__c = :organisationId
        GROUP BY Product__c, Product__r.Name, Acceptance_Type__c
    ];

 /*   for (AggregateResult ar : returnAgg) {
        Id productId = (Id)ar.get('productId');
        String reason = (String)ar.get('reason');
        Integer qty = ((Decimal)ar.get('totalReturnedQty')).intValue();
        Integer caseCount = ((Decimal)ar.get('returnCases')).intValue();
        Date lastReturnDate = ((DateTime)ar.get('lastReturnDate')).date();

        if (!returnMap.containsKey(productId)) {
            ReturnProductSummary summary = new ReturnProductSummary();
            summary.productId = productId;
            summary.productName = (String)ar.get('productName') != null ? (String)ar.get('productName') : 'Manual Product';
            returnMap.put(productId, summary);
        } else if (returnMap.get(productId).productName == null && ar.get('productName') != null) {
            returnMap.get(productId).productName = (String)ar.get('productName');
        }

        returnMap.get(productId).totalReturnedQty += qty;

        // Track reasons
        if (!reasonCountMap.containsKey(productId)) {
            reasonCountMap.put(productId, new Map<String, Integer>());
        }
        Map<String, Integer> reasonMap = reasonCountMap.get(productId);
        reasonMap.put(reason, reasonMap.containsKey(reason) ? reasonMap.get(reason) + qty : qty);

        // Track return cases
        returnCaseCountMap.put(productId,
            returnCaseCountMap.containsKey(productId) ? returnCaseCountMap.get(productId) + caseCount : caseCount);

        // Track latest return date
        if (!lastReturnDateMap.containsKey(productId) || lastReturnDateMap.get(productId) < lastReturnDate) {
            lastReturnDateMap.put(productId, lastReturnDate);
        }
    }*/
    
    for (AggregateResult ar : returnAgg) {
    Id productId = (Id)ar.get('productId');
    String reason = (String)ar.get('reason');
    Decimal qtyDec = (Decimal)ar.get('totalReturnedQty');
    Integer qty = (qtyDec == null) ? 0 : qtyDec.intValue();

    Decimal caseDec = (Decimal)ar.get('returnCases');
    Integer caseCount = (caseDec == null) ? 0 : caseDec.intValue();

    Date lastReturnDate;
    if (ar.get('lastReturnDate') != null) {
        lastReturnDate = ((DateTime)ar.get('lastReturnDate')).date();
    }

    if (!returnMap.containsKey(productId)) {
        ReturnProductSummary summary = new ReturnProductSummary();
        summary.productId = productId;
        summary.productName = (String)ar.get('productName') != null
            ? (String)ar.get('productName')
            : 'Manual Product';
        returnMap.put(productId, summary);
    } else if (returnMap.get(productId).productName == null           && ar.get('productName') != null) {
        returnMap.get(productId).productName = (String)ar.get('productName');
    }

    returnMap.get(productId).totalReturnedQty += qty;

    // Track reasons
    if (!reasonCountMap.containsKey(productId)) {
        reasonCountMap.put(productId, new Map<String, Integer>());
    }
    Map<String, Integer> reasonMap = reasonCountMap.get(productId);
    reasonMap.put(
        reason,
        reasonMap.containsKey(reason)
            ? reasonMap.get(reason) + qty
            : qty
    );

    // Track return cases
    returnCaseCountMap.put(
        productId,
        returnCaseCountMap.containsKey(productId)
            ? returnCaseCountMap.get(productId) + caseCount
            : caseCount
    );

    // Track latest return date
    if (lastReturnDate != null &&
        (!lastReturnDateMap.containsKey(productId)
            || lastReturnDateMap.get(productId) < lastReturnDate)) {
        lastReturnDateMap.put(productId, lastReturnDate);
    }
}


    // 2. Get sold quantities
    List<AggregateResult> soldAgg = [
        SELECT Product2Id, SUM(Quantity) totalSold
        FROM OrderItem
        WHERE Product2Id IN :returnMap.keySet()
          AND Company__c = :organisationId
          AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        GROUP BY Product2Id
    ];

    for (AggregateResult ar : soldAgg) {
        Id productId = (Id)ar.get('Product2Id');
        if (returnMap.containsKey(productId)) {            Integer soldQty = ((Decimal)ar.get('totalSold')).intValue();
            ReturnProductSummary summary = returnMap.get(productId);
            summary.totalSoldQty = soldQty; System.debug('Total sold qty for product ' + productId + ': ' + soldQty); System.debug('Total returned qty for product ' + productId + ': ' + summary.totalReturnedQty);
            summary.returnRate = soldQty > 0
                ? (((Decimal)summary.totalReturnedQty / soldQty) * 100).setScale(2)
                : 0;
            System.debug('Calculated return rate for product ' + productId + ': ' + summary.returnRate);
        }
    }

    // 3. Fill missing defaults and set top reason, case count, return date
    for (Id productId : returnMap.keySet()) {
        ReturnProductSummary summary = returnMap.get(productId);

        // Top reason
        if (reasonCountMap.containsKey(productId)) {
            String topReason;
            Integer maxQty = 0;
            for (String r : reasonCountMap.get(productId).keySet()) {
                if (reasonCountMap.get(productId).get(r) > maxQty) {
                    maxQty = reasonCountMap.get(productId).get(r);                    topReason = r;
                }
            }
            summary.topReturnReason = topReason;
        }

        // Total return cases
        summary.totalReturnCases = returnCaseCountMap.containsKey(productId)
            ? returnCaseCountMap.get(productId) : 0;

        // Last return date
        summary.lastReturnDate = lastReturnDateMap.containsKey(productId)
            ? lastReturnDateMap.get(productId) : null;

        // Defaults for missing sales
        if (summary.totalSoldQty == null) summary.totalSoldQty = 0;
        if (summary.returnRate == null) summary.returnRate = 0;
    }

    // 4. Sort and limit
    List<ReturnProductSummary> sorted = new List<ReturnProductSummary>(returnMap.values());
    sorted.sort(new ComparatorByReturnedQty());

    List<ReturnProductSummary> topResults = new List<ReturnProductSummary>();
    for (Integer i = 0; i < Math.min(limitCount, sorted.size()); i++) {
        topResults.add(sorted[i]);
    }

    System.debug('✅ Final Top Returned Products: ' + topResults);
    return topResults;
}

/*@AuraEnabled(cacheable=true)
public static List<ReasonDistribution> getReturnReasonDistribution(String organisationId) {
    List<AggregateResult> result = [
        SELECT Acceptance_Type__c reason,
               SUM(Quantity_Return__c) qty
        FROM RMA_Line_Item__c
        WHERE Company__c = :organisationId
        GROUP BY Acceptance_Type__c
    ];

    List<ReasonDistribution> reasons = new List<ReasonDistribution>();
    for (AggregateResult ar : result) {
        ReasonDistribution r = new ReasonDistribution();
        r.reason = (String)ar.get('reason');
        r.totalQty = ((Decimal)ar.get('qty')).intValue();
        reasons.add(r);
    }
    return reasons;
}

public class ReasonDistribution {
    @AuraEnabled public String reason;
    @AuraEnabled public Integer totalQty;
}*/
    
    @AuraEnabled(cacheable=true)
public static List<ReasonDistribution> getReturnReasonDistribution(String organisationId) {
    List<AggregateResult> result = [
        SELECT Acceptance_Type__c reason,
               SUM(Quantity_Return__c) qty
        FROM RMA_Line_Item__c
        WHERE Company__c = :organisationId
        GROUP BY Acceptance_Type__c
    ];

    List<ReasonDistribution> reasons = new List<ReasonDistribution>();
    for (AggregateResult ar : result) {
        String reason = (String)ar.get('reason');
        Decimal qtyDec = (Decimal)ar.get('qty');

        ReasonDistribution r = new ReasonDistribution();
        r.reason   = String.isBlank(reason) ? 'Unknown' : reason;
        r.totalQty = (qtyDec == null) ? 0 : qtyDec.intValue();

        reasons.add(r);
    }
    return reasons;
}

public class ReasonDistribution {
    @AuraEnabled public String reason;
    @AuraEnabled public Integer totalQty;
}

@AuraEnabled
public static Integer getCurrentFiscalYear() {
    Integer startMonth = [SELECT FiscalYearStartMonth FROM Organization LIMIT 1].FiscalYearStartMonth;
    Date today = Date.today();
    Integer fiscalYear = today.year();

    if (today.month() < startMonth) {     fiscalYear -= 1;
    }
    return fiscalYear;
}

public class MonthlyReturnStat {
    @AuraEnabled public String monthLabel;
    @AuraEnabled public Integer totalReturnedQty;
    @AuraEnabled public Integer totalSoldQty;
    @AuraEnabled public Decimal returnRate;
}

@AuraEnabled(cacheable=true)
public static List<MonthlyReturnStat> getReturnRateTrend(String organisationId) {
    List<MonthlyReturnStat> result = new List<MonthlyReturnStat>();
    try {
        Integer year = Date.today().year();
        Date startDate = Date.newInstance(year, 1, 1);
        Date endDate = Date.newInstance(year, 12, 31);

        Map<String, MonthlyReturnStat> dataMap = new Map<String, MonthlyReturnStat>();

        System.debug('📅 Start Date: ' + startDate + ', End Date: ' + endDate);

        List<AggregateResult> returned = [
            SELECT CALENDAR_MONTH(CreatedDate) month,
                   SUM(Quantity_Return__c) qty
            FROM RMA_Line_Item__c
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
                  AND Company__c = :organisationId
            GROUP BY CALENDAR_MONTH(CreatedDate)
        ];

        for (AggregateResult ar : returned) {
            Integer month = (Integer)ar.get('month');
            Integer qty = ((Decimal)ar.get('qty')).intValue();

            MonthlyReturnStat stat = new MonthlyReturnStat();
            stat.monthLabel = DateTime.newInstance(year, month, 1, 0, 0, 0).format('MMM yyyy');
            stat.totalReturnedQty = qty;            dataMap.put(String.valueOf(month), stat);
        }

        List<AggregateResult> sold = [
            SELECT CALENDAR_MONTH(CreatedDate) month,
                   SUM(Quantity) qty
            FROM OrderItem
            WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate
            GROUP BY CALENDAR_MONTH(CreatedDate)
        ];

        for (AggregateResult ar : sold) {
            Integer month = (Integer)ar.get('month');       Integer qty = ((Decimal)ar.get('qty')).intValue();

            String key = String.valueOf(month);
            if (!dataMap.containsKey(key)) {    MonthlyReturnStat stat = new MonthlyReturnStat();
                stat.monthLabel = DateTime.newInstance(year, month, 1, 0, 0, 0).format('MMM yyyy');            stat.totalReturnedQty = 0;
                dataMap.put(key, stat);
            }

            MonthlyReturnStat stat = dataMap.get(key);
            stat.totalSoldQty = qty;
            stat.returnRate = qty > 0 ? ((Decimal)stat.totalReturnedQty / qty) * 100 : 0;
        }

        List<Integer> monthKeys = new List<Integer>();
        for (String m : dataMap.keySet()) {    monthKeys.add(Integer.valueOf(m));
        }
        monthKeys.sort();

        for (Integer m : monthKeys) {    result.add(dataMap.get(String.valueOf(m)));
        }

        System.debug('✅ Final Return Rate Result: ' + result);

        return result;

    } catch (Exception e) {
        System.debug('❌ ERROR in getReturnRateTrend: ' + e.getMessage());
        throw new AuraHandledException('Error while processing return trend: ' + e.getMessage());
    }
}
//customer return insights
// public class CustomerReturnSummary {
//     @AuraEnabled public Id customerId;
//     @AuraEnabled public String customerName;
//     @AuraEnabled public Integer totalReturnedQty;
//     @AuraEnabled public Integer totalOrderedQty;
//     @AuraEnabled public Decimal returnRate;
//     @AuraEnabled public Integer totalOrders;
//     @AuraEnabled public String topReturnReason;
//     @AuraEnabled public Integer totalReturnCases;
//     @AuraEnabled public Date lastReturnDate;
// }

public class ComparatorByCustomerReturnQty implements Comparator<Object> {
    public Integer compare(Object a, Object b) {
 sandOP.CustomerReturnSummary c1 = (sandOP.CustomerReturnSummary)a;        sandOP.CustomerReturnSummary c2 = (sandOP.CustomerReturnSummary)b;        return c2.totalReturnedQty - c1.totalReturnedQty;
    }
}
public class CustomerReturnSummary {
    @AuraEnabled public String customerId;
    @AuraEnabled public String customerName;
    @AuraEnabled public Integer totalReturnedQty;
    @AuraEnabled public Integer totalOrderedQty=0;
    @AuraEnabled public Decimal returnRate=0.0;
    @AuraEnabled public String topReturnReason;
    @AuraEnabled public Integer totalReturnCases=0;
    @AuraEnabled public Date lastReturnDate;
    @AuraEnabled public Integer totalOrders=0;
}

@AuraEnabled(cacheable=true)
public static List<CustomerReturnSummary> getTopReturningCustomers(String organisationId, Integer limitCount) {
    Map<Id, CustomerReturnSummary> returnMap = new Map<Id, CustomerReturnSummary>();
    Map<Id, Map<String, Integer>> reasonCountMap = new Map<Id, Map<String, Integer>>();
    Map<Id, Date> lastReturnDateMap = new Map<Id, Date>();
    Map<Id, Integer> returnCaseCountMap = new Map<Id, Integer>();

    // 1. RMA Return Aggregates
    List<AggregateResult> returnAgg = [
        SELECT Return_Merchandise_Authorisation__r.Account__c customerId,
               Return_Merchandise_Authorisation__r.Account__r.Name customerName,
               SUM(Quantity_Return__c) totalReturnedQty,
               Acceptance_Type__c reason,
               COUNT(Id) returnCases,
               MAX(CreatedDate) lastReturnDate
        FROM RMA_Line_Item__c
        WHERE Company__c = :organisationId
        GROUP BY 
            Return_Merchandise_Authorisation__r.Account__c, 
            Return_Merchandise_Authorisation__r.Account__r.Name,
            Acceptance_Type__c
    ];
// System.debug('return AGG '+returnAgg);
   /* for (AggregateResult ar : returnAgg) {
        Id customerId = (Id)ar.get('customerId');
        if (customerId == null) continue;

        String customerName = (String)ar.get('customerName') != null ? (String)ar.get('customerName') : 'Manual';
        String reason = (String)ar.get('reason');
        Integer qty = ((Decimal)ar.get('totalReturnedQty')).intValue();
        Integer caseCount = ((Decimal)ar.get('returnCases')).intValue();
        Date lastReturnDate = ((Datetime)ar.get('lastReturnDate')).date();

        if (!returnMap.containsKey(customerId)) {
            CustomerReturnSummary summary = new CustomerReturnSummary();
            summary.customerId = customerId;
            summary.customerName = customerName;
            summary.totalReturnedQty = 0;
            returnMap.put(customerId, summary);
        }

        returnMap.get(customerId).totalReturnedQty += qty;

        // Track reason counts
        if (!reasonCountMap.containsKey(customerId)) {
            reasonCountMap.put(customerId, new Map<String, Integer>());
        }
        Map<String, Integer> reasonMap = reasonCountMap.get(customerId);
        reasonMap.put(reason, reasonMap.containsKey(reason) ? reasonMap.get(reason) + qty : qty);

        // Track return cases
        returnCaseCountMap.put(customerId, returnCaseCountMap.containsKey(customerId)
            ? returnCaseCountMap.get(customerId) + caseCount : caseCount);

        // Track latest return date
        if (!lastReturnDateMap.containsKey(customerId) || lastReturnDateMap.get(customerId) < lastReturnDate) {
            lastReturnDateMap.put(customerId, lastReturnDate);
        }
    } */
    for (AggregateResult ar : returnAgg) {
    Id customerId = (Id)ar.get('customerId');
    if (customerId == null) continue;

    String customerName = (String)ar.get('customerName');
    customerName = String.isNotBlank(customerName) ? customerName : 'Manual';

    String reason = (String)ar.get('reason');

    // ✅ Null-safe conversions
    Decimal qtyDec = (Decimal)ar.get('totalReturnedQty');
    Integer qty = (qtyDec == null) ? 0 : qtyDec.intValue();

    Decimal caseDec = (Decimal)ar.get('returnCases');
    Integer caseCount = (caseDec == null) ? 0 : caseDec.intValue();

    Date lastReturnDate = null;
    if (ar.get('lastReturnDate') != null) {
        lastReturnDate = ((Datetime)ar.get('lastReturnDate')).date();
    }

    if (!returnMap.containsKey(customerId)) {
        CustomerReturnSummary summary = new CustomerReturnSummary();
        summary.customerId = customerId;
        summary.customerName = customerName;
        summary.totalReturnedQty = 0;
        returnMap.put(customerId, summary);
    }

    returnMap.get(customerId).totalReturnedQty += qty;

    // Track reason counts
    if (!reasonCountMap.containsKey(customerId)) {
        reasonCountMap.put(customerId, new Map<String, Integer>());
    }
    Map<String, Integer> reasonMap = reasonCountMap.get(customerId);
    reasonMap.put(
        reason,
        reasonMap.containsKey(reason)
            ? reasonMap.get(reason) + qty
            : qty
    );

    // Track return cases
    returnCaseCountMap.put(
        customerId,
        returnCaseCountMap.containsKey(customerId)
            ? returnCaseCountMap.get(customerId) + caseCount
            : caseCount
    );

    // Track latest return date
    if (lastReturnDate != null &&
        (!lastReturnDateMap.containsKey(customerId)
            || lastReturnDateMap.get(customerId) < lastReturnDate)) {
        lastReturnDateMap.put(customerId, lastReturnDate);
    }
}


    // 2. Order Aggregates
    List<AggregateResult> orderAgg = [
        SELECT Order.AccountId customerId, SUM(Quantity) totalOrdered, COUNT_DISTINCT(OrderId) orderCount
        FROM OrderItem
        WHERE Order.AccountId IN :returnMap.keySet()
        GROUP BY Order.AccountId
    ];

    for (AggregateResult ar : orderAgg) {
        Id customerId = (Id)ar.get('customerId');
        if (returnMap.containsKey(customerId)) {
            Integer totalOrdered = ((Decimal)ar.get('totalOrdered')).intValue();
            Integer totalOrders = (Integer)ar.get('orderCount');
            CustomerReturnSummary summary = returnMap.get(customerId);
            summary.totalOrderedQty = totalOrdered;
            summary.totalOrders = totalOrders;
            System.debug('totalOrdered ->'+totalOrdered+'totalOrders ->'+totalOrders);
            System.debug(' summary.totalOrderedQty '+ summary.totalOrderedQty);
            System.debug(' summary.totalOrders'+  summary.totalOrders);
            summary.returnRate = totalOrdered > 0
                ? (((Decimal)summary.totalReturnedQty / totalOrdered) * 100).setScale(2) : 0;
            // System.debug('return rate '+ summary.returnRate);
        }
    }

    // 3. Assign top reason, return cases, and last return date
    for (Id customerId : returnMap.keySet()) {
        CustomerReturnSummary summary = returnMap.get(customerId);
        Map<String, Integer> reasons = reasonCountMap.get(customerId);

        if (reasons != null) {
            String topReason = null;
            Integer maxQty = 0;
            for (String r : reasons.keySet()) {
                if (reasons.get(r) > maxQty) {
                    topReason = r;                   maxQty = reasons.get(r);
                }
            }
            summary.topReturnReason = topReason;
        }

        summary.totalReturnCases = returnCaseCountMap.get(customerId);
        summary.lastReturnDate = lastReturnDateMap.get(customerId);
    }

    // 4. Sort
    List<CustomerReturnSummary> sorted = new List<CustomerReturnSummary>(returnMap.values());
    sorted.sort(new ComparatorByCustomerReturnQty());

    // 5. Limit
    List<CustomerReturnSummary> topResults = new List<CustomerReturnSummary>();
    for (Integer i = 0; i < Math.min(limitCount, sorted.size()); i++) {
        topResults.add(sorted[i]);
    }
    // System.debug('top result '+topResults);
    return topResults;
}


// new stok movement methods 
// @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getStockInwardData(Date startDate, Date endDate) {
//     List<Stock_Inward_Line_Item__c> records = [
//         SELECT Id, Quantity__c, Received_Month__c,
//                Purchase_Orders__c,
//                Work_Order__c,
//                RMA__c,
//                Cart__c,
//                Manufacturing_Order__c,
//                Transfer_Order__c,
//                Stock_Take_Line_Item__c
//         FROM Stock_Inward_Line_Item__c
//         WHERE CreatedDate >= :startDate
//           AND CreatedDate <= :endDate
//     ];

//     Map<String, Decimal> aggregateMap = new Map<String, Decimal>();

//     for (Stock_Inward_Line_Item__c rec : records) {
//         String sourceType;
//         if (rec.Purchase_Orders__c != null)         sourceType = 'Purchase Order';
//         else if (rec.Manufacturing_Order__c != null) sourceType = 'Manufacturing Order';
//         else if (rec.Stock_Take_Line_Item__c != null) sourceType = 'Stock Take';
//         else if (rec.Cart__c != null)               sourceType = 'Stock Transfer';
//         else if (rec.Transfer_Order__c != null)     sourceType = 'Transfer Order';
//         else if (rec.RMA__c != null)                sourceType = 'RMA';
//         else if (rec.Work_Order__c != null)         sourceType = 'Work Order';
//         else                                              sourceType = 'Manual';

//         String monthKey = rec.Received_Month__c != null ? rec.Received_Month__c : 'Manual Month';

//         Decimal qty = rec.Quantity__c != null ? rec.Quantity__c : 0;
//         String finalKey = monthKey + '|' + sourceType;

//         aggregateMap.put(finalKey, (aggregateMap.containsKey(finalKey) ? aggregateMap.get(finalKey) : 0) + qty);
//     }

//     List<Map<String, Object>> results = new List<Map<String, Object>>();
//     for (String key : aggregateMap.keySet()) {
//         List<String> parts = key.split('\\|');
//         results.add(new Map<String, Object>{
//             'month'    => parts[0],
//             'source'   => parts[1],
//             'quantity' => aggregateMap.get(key)
//         });
//     }

//     return results;
// }
// @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getStockOutwardData(Date startDate, Date endDate) {
//     List<Stock_Outward_Line_Item__c> records = [
//         SELECT Id, Quantity__c, Dispatched_Month__c, Status__c, Active__c,
//                Order__c,
//                Purchase_Orders__c,
//                Manufacturing_Order__c,
//                Cart__c,
//                Stock_Take_Line_Item__c,
//                RMA_Line_Item__c,
//                Transfer_Order__c,
//                Work_Orders__c
//         FROM Stock_Outward_Line_Item__c
//         WHERE CreatedDate >= :startDate
//           AND CreatedDate <= :endDate
//           AND Status__c != 'Reserved'
//           AND Active__c = true
//     ];

//     Map<String, Decimal> aggregateMap = new Map<String, Decimal>();

//     for (Stock_Outward_Line_Item__c rec : records) {
//         String sourceType;
//         if (rec.Order__c != null)                 sourceType = 'Order';
//         else if (rec.Purchase_Orders__c != null)  sourceType = 'Purchase Order';
//         else if (rec.Manufacturing_Order__c != null) sourceType = 'Manufacturing Order';
//         else if (rec.Cart__c != null)             sourceType = 'Stock Transfer';
//         else if (rec.Stock_Take_Line_Item__c != null) sourceType = 'Stock Take';
//         else if (rec.RMA_Line_Item__c != null)              sourceType = 'RMA';
//         else if (rec.Transfer_Order__c != null)   sourceType = 'Transfer Order';
//         else if (rec.Work_Orders__c != null)       sourceType = 'Work Orders';
//         else                                            sourceType = 'Manual';

//         String monthKey = rec.Dispatched_Month__c != null ? rec.Dispatched_Month__c : 'Manual Month';

//         Decimal qty = rec.Quantity__c != null ? rec.Quantity__c : 0;
//         String finalKey = monthKey + '|' + sourceType;

//         aggregateMap.put(finalKey, (aggregateMap.containsKey(finalKey) ? aggregateMap.get(finalKey) : 0) + qty);
//     }

//     List<Map<String, Object>> results = new List<Map<String, Object>>();
//     for (String key : aggregateMap.keySet()) {
//         List<String> parts = key.split('\\|');
//         results.add(new Map<String, Object>{
//             'month'    => parts[0],
//             'source'   => parts[1],
//             'quantity' => aggregateMap.get(key)
//         });
//     }

//     return results;
// }

// @AuraEnabled(cacheable=true)
// public static Map<String, List<Map<String, Object>>> getStockMovementData(Date startDate, Date endDate) {
//     Map<String, List<Map<String, Object>>> resultMap = new Map<String, List<Map<String, Object>>>();

//     // ===== STOCK INWARDS =====
//     List<Stock_Inward_Line_Item__c> inwardRecords = [
//         SELECT Id, Quantity__c, Received_Month__c,
//                Purchase_Orders__c,
//                Work_Order__c,
//                RMA__c,
//                Cart__c,
//                Manufacturing_Order__c,
//                Transfer_Order__c,
//                Stock_Take_Line_Item__c
//         FROM Stock_Inward_Line_Item__c
//         WHERE CreatedDate >= :startDate
//           AND CreatedDate <= :endDate
//     ];

//     List<Map<String, Object>> inwardList = aggregateStockData(
//         inwardRecords,
//         'inward'
//     );

//     // ===== STOCK OUTWARDS =====
//     List<Stock_Outward_Line_Item__c> outwardRecords = [
//         SELECT Id, Quantity__c, Dispatched_Month__c, Status__c, Active__c,
//                Order__c,
//                Purchase_Orders__c,
//                Manufacturing_Order__c,
//                Cart__c,
//                Stock_Take_Line_Item__c,
//                RMA_Line_Item__c,
//                Transfer_Order__c,
//                Work_Orders__c
//         FROM Stock_Outward_Line_Item__c
//         WHERE CreatedDate >= :startDate
//           AND CreatedDate <= :endDate
//           AND Status__c != 'Reserved'
//           AND Active__c = true
//     ];

//     List<Map<String, Object>> outwardList = aggregateStockData(
//         outwardRecords,
//         'outward'
//     );

//     // Add to result
//     resultMap.put('inwards', inwardList);
//     resultMap.put('outwards', outwardList);

//     return resultMap;
// }

// // ===== HELPER METHOD =====
// private static List<Map<String, Object>> aggregateStockData(List<SObject> records, String type) {
//     Map<String, Decimal> aggregateMap = new Map<String, Decimal>();

//     for (SObject s : records) {
//         String sourceType;
//         String monthKey;
//         Decimal qty;

//         if (type == 'inward') {
//             Stock_Inward_Line_Item__c rec = (Stock_Inward_Line_Item__c) s;
//             sourceType =
//                 rec.Purchase_Orders__c != null ? 'Purchase Order' :
//                 rec.Manufacturing_Order__c != null ? 'Manufacturing Order' :
//                 rec.Stock_Take_Line_Item__c != null ? 'Stock Take' :
//                 rec.Cart__c != null ? 'Stock Transfer' :
//                 rec.Transfer_Order__c != null ? 'Transfer Order' :
//                 rec.RMA__c != null ? 'RMA' :
//                 rec.Work_Order__c != null ? 'Work Order' : 'Manual';

//             monthKey = rec.Received_Month__c != null ? rec.Received_Month__c : 'Manual Month';
//             qty = rec.Quantity__c != null ? rec.Quantity__c : 0;

//         } else {
//             Stock_Outward_Line_Item__c rec = (Stock_Outward_Line_Item__c) s;
//             sourceType =
//                 rec.Order__c != null ? 'Order' :
//                 rec.Purchase_Orders__c != null ? 'Purchase Order' :
//                 rec.Manufacturing_Order__c != null ? 'Manufacturing Order' :
//                 rec.Cart__c != null ? 'Stock Transfer' :
//                 rec.Stock_Take_Line_Item__c != null ? 'Stock Take' :
//                 rec.RMA_Line_Item__c != null ? 'RMA' :
//                 rec.Transfer_Order__c != null ? 'Transfer Order' :
//                 rec.Work_Orders__c != null ? 'Work Orders' : 'Manual';

//             monthKey = rec.Dispatched_Month__c != null ? rec.Dispatched_Month__c : 'Manual Month';
//             qty = rec.Quantity__c != null ? rec.Quantity__c : 0;
//         }

//         String finalKey = monthKey + '|' + sourceType;
//         aggregateMap.put(finalKey, (aggregateMap.containsKey(finalKey) ? aggregateMap.get(finalKey) : 0) + qty);
//     }

//     // Convert to list for LWC
//     List<Map<String, Object>> results = new List<Map<String, Object>>();
//     for (String key : aggregateMap.keySet()) {
//         List<String> parts = key.split('\\|');
//         results.add(new Map<String, Object>{
//             'month'    => parts[0],
//             'source'   => parts[1],
//             'quantity' => aggregateMap.get(key)
//         });
//     }
//     return results;
// }
// 
@AuraEnabled(cacheable=true)
public static Map<String, List<Map<String, Object>>> getStockMovementData(String yearStr) {
    Integer year = Integer.valueOf(yearStr);
    Date startDate = Date.newInstance(year, 1, 1);
    Date endDate = Date.newInstance(year, 12, 31);

    Map<String, List<Map<String, Object>>> resultMap = new Map<String, List<Map<String, Object>>>();

    // ===== STOCK INWARDS =====
    Map<String, Decimal> inwardTotals = new Map<String, Decimal>();

    List<Stock_Inward_Line_Item__c> inwardRecords = [
        SELECT CreatedDate,
               Purchase_Orders__c,
               Manufacturing_Order__c,
               Stock_Take_Line_Item__c,
               Cart__c,
               Transfer_Order__c,
               RMA__c,
               Work_Order__c,
               Quantity__c
        FROM Stock_Inward_Line_Item__c
        WHERE CreatedDate >= :startDate
          AND CreatedDate <= :endDate
    ];

    for (Stock_Inward_Line_Item__c rec : inwardRecords) {
        String sourceType = 'Manual';
        if (rec.Purchase_Orders__c != null)         sourceType = 'Purchase Order';
        else if (rec.Manufacturing_Order__c != null) sourceType = 'Manufacturing Order';
        else if (rec.Stock_Take_Line_Item__c != null) sourceType = 'Stock Take';
        else if (rec.Cart__c != null)               sourceType = 'Stock Transfer';
        else if (rec.Transfer_Order__c != null)     sourceType = 'Transfer Order';
        else if (rec.RMA__c != null)                sourceType = 'RMA';
        else if (rec.Work_Order__c != null)         sourceType = 'Work Order';

        Date cd = rec.CreatedDate.date();
        String monthKey = cd.month() + '/' + cd.year();
        String finalKey = monthKey + '|' + sourceType;

        Decimal qty = rec.Quantity__c != null ? rec.Quantity__c : 0;
        inwardTotals.put(finalKey, (inwardTotals.containsKey(finalKey) ? inwardTotals.get(finalKey) : 0) + qty);
    }

    List<Map<String, Object>> inwardList = new List<Map<String, Object>>();
    for (String key : inwardTotals.keySet()) {
        List<String> parts = key.split('\\|');
        Decimal roundedQty = inwardTotals.get(key).setScale(2, RoundingMode.HALF_UP);
        inwardList.add(new Map<String, Object>{
            'month'    => parts[0],
            'source'   => parts[1],
            'quantity' => roundedQty
        });
    }

    resultMap.put('inwards', inwardList);

    // ===== STOCK OUTWARDS =====
    Map<String, Decimal> outwardTotals = new Map<String, Decimal>();

    List<Stock_Outward_Line_Item__c> outwardRecords = [
        SELECT CreatedDate,
               Order__c,
               Purchase_Orders__c,
               Manufacturing_Order__c,
               Cart__c,
               Stock_Take_Line_Item__c,
               RMA_Line_Item__c,
               Transfer_Order__c,
               Work_Orders__c,
               Quantity__c
        FROM Stock_Outward_Line_Item__c
        WHERE CreatedDate >= :startDate
          AND CreatedDate <= :endDate
          AND Status__c != 'Reserved'
          AND Active__c = true
    ];

    for (Stock_Outward_Line_Item__c rec : outwardRecords) {
        String sourceType = 'Manual';
        if (rec.Order__c != null)                  sourceType = 'Order';
        else if (rec.Purchase_Orders__c != null)   sourceType = 'Purchase Order';
        else if (rec.Manufacturing_Order__c != null) sourceType = 'Manufacturing Order';
        else if (rec.Cart__c != null)              sourceType = 'Stock Transfer';
        else if (rec.Stock_Take_Line_Item__c != null) sourceType = 'Stock Take';
        else if (rec.RMA_Line_Item__c != null)     sourceType = 'RMA';
        else if (rec.Transfer_Order__c != null)    sourceType = 'Transfer Order';
        else if (rec.Work_Orders__c != null)       sourceType = 'Work Orders';

        Date cd = rec.CreatedDate.date();
        String monthKey = cd.month() + '/' + cd.year();
        String finalKey = monthKey + '|' + sourceType;

        Decimal qty = rec.Quantity__c != null ? rec.Quantity__c : 0;
        outwardTotals.put(finalKey, (outwardTotals.containsKey(finalKey) ? outwardTotals.get(finalKey) : 0) + qty);
    }

    List<Map<String, Object>> outwardList = new List<Map<String, Object>>();
    for (String key : outwardTotals.keySet()) {
        List<String> parts = key.split('\\|');
        Decimal roundedQty = outwardTotals.get(key).setScale(2, RoundingMode.HALF_UP);
        outwardList.add(new Map<String, Object>{
            'month'    => parts[0],
            'source'   => parts[1],
            'quantity' => roundedQty
        });
    }

    resultMap.put('outwards', outwardList);

    return resultMap;
}
// ========= Simulation Save DTOs =========
public class SimulationLineDTO {
    @AuraEnabled public String yearMonth;         // 'YYYY-MM'
    @AuraEnabled public Decimal forecasted;       // Forecasted value
    @AuraEnabled public Decimal simulated;        // Simulated value
    @AuraEnabled public Decimal actual;           // Optional
}

public class SimulationSaveDTO {
    @AuraEnabled public String name;
    @AuraEnabled public String model;             // Must match picklist values on Model__c
    @AuraEnabled public String type;              // Must match picklist values on Type__c
    @AuraEnabled public Id productId;             // Lookup(Product2)
    @AuraEnabled public String fromPeriod;        // 'YYYY-MM'
    @AuraEnabled public String toPeriod;          // 'YYYY-MM'
    @AuraEnabled public List<SimulationLineDTO> lines;
}

// ========= Main entry point from LWC =========
// @AuraEnabled
// public static Id saveSimulation(String payloadJson) {
//     if (String.isBlank(payloadJson)) {
//         throw new AuraHandledException('No payload received.');
//     }

//     SimulationSaveDTO payload;
//     try {
//         payload = (SimulationSaveDTO) JSON.deserialize(payloadJson, SimulationSaveDTO.class);
//     } catch (Exception e) {
//         throw new AuraHandledException('Invalid payload: ' + e.getMessage());
//     }

//     if (payload == null || payload.lines == null || payload.lines.isEmpty()) {
//         throw new AuraHandledException('Nothing to save. Run a simulation first.');
//     }

//     // Build Simulation header
//     Simulation__c sim = new Simulation__c();
//     sim.Name                   = String.isBlank(payload.name) ? 'Simulation ' + Datetime.now().format('yyyy-MM-dd HH:mm') : payload.name;
//     sim.Model__c         = payload.model;
//     sim.Type__c          = payload.type;
    
//      // Optional: if you prefer to hard-fail with a friendly message instead of nulling, uncomment:
//     if (payload.model != null && sim.Model__c == null)
//     //     throw new AuraHandledException('Invalid Model. Provide one of the allowed values.');
//     if (payload.type != null && sim.Type__c == null)
//     //     throw new AuraHandledException('Invalid Type. Provide one of the allowed values.');

    
//     sim.Product__c       = payload.productId;
//     sim.From_Period__c   = payload.fromPeriod;
//     sim.To_Period__c     = payload.toPeriod;
// 	System.debug('inserting simulation');
//     System.debug('sim=>'+sim);
//     insert sim;
// 	System.debug('inserted ');
//     // Build line items
//     List<Simulation_Line_Item__c> toInsert = new List<Simulation_Line_Item__c>();
//     for (SimulationLineDTO row : payload.lines) {
//         Simulation_Line_Item__c li = new Simulation_Line_Item__c();
//         li.Simulation__c        = sim.Id;
//         li.YearMonth__c         = row.yearMonth;               // 'YYYY-MM' (your formula fields derive Month/Year)
//         li.Forecasted_Value__c  = (row.forecasted == null) ? 0 : row.forecasted.setScale(2);
//         li.Simulated_Value__c   = (row.simulated  == null) ? 0 : row.simulated.setScale(2);
//         if (row.actual != null) {
//             li.Actual_Value__c = row.actual.setScale(2);
//         }
//         toInsert.add(li);
//     }
//     if (!toInsert.isEmpty()) {System.debug('inserting toInsert simulation line items');	insert toInsert; System.debug('inserted');}

//     return sim.Id;
// }


//added by abuzar for null value exception error in test class

// Helper: map incoming text to a canonical restricted picklist value (case-insensitive). Null if invalid.
private static String picklistOrNull(String incoming, Schema.DescribeFieldResult dfr) {
    if (String.isBlank(incoming)) return null;
    String key = incoming.trim().toLowerCase();
    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
        if (pe.getValue() != null && pe.getValue().toLowerCase() == key) {
            return pe.getValue(); // canonical value
        }
    }
    return null;
}

@AuraEnabled
public static Id saveSimulation(String payloadJson) {
    if (String.isBlank(payloadJson)) {
        throw new AuraHandledException('No payload received.');
    }

    SimulationSaveDTO payload;
    try {
        payload = (SimulationSaveDTO) JSON.deserialize(payloadJson, SimulationSaveDTO.class);
    } catch (Exception e) {
        throw new AuraHandledException('Invalid payload: ' + e.getMessage());
    }

    if (payload == null || payload.lines == null || payload.lines.isEmpty()) {
        throw new AuraHandledException('Nothing to save. Run a simulation first.');
    }

    // Build Simulation header
    Simulation__c sim = new Simulation__c();
    sim.Name = String.isBlank(payload.name)
        ? 'Simulation ' + Datetime.now().format('yyyy-MM-dd HH:mm')
        : payload.name;

    // ✅ Restricted picklists: normalize or block with a friendly error
    sim.Model__c = picklistOrNull(payload.model, Simulation__c.Model__c.getDescribe());
    sim.Type__c  = picklistOrNull(payload.type,  Simulation__c.Type__c.getDescribe());

    if (String.isNotBlank(payload.model) && sim.Model__c == null) {
        throw new AuraHandledException('Invalid Model. Provide one of the allowed values.');
    }
    if (String.isNotBlank(payload.type) && sim.Type__c == null) {
        throw new AuraHandledException('Invalid Type. Provide one of the allowed values.');
    }

    // Other fields (left as-is)
    sim.Product__c     = payload.productId;
    sim.From_Period__c = payload.fromPeriod;
    sim.To_Period__c   = payload.toPeriod;

    System.debug('inserting simulation');
    System.debug('sim=>' + sim);
    insert sim;
    System.debug('inserted');

    // Build line items
    List<Simulation_Line_Item__c> toInsert = new List<Simulation_Line_Item__c>();
    for (SimulationLineDTO row : payload.lines) {
        Simulation_Line_Item__c li = new Simulation_Line_Item__c();
        li.Simulation__c       = sim.Id;
        li.YearMonth__c        = row.yearMonth;               // 'YYYY-MM'
        li.Forecasted_Value__c = (row.forecasted == null) ? 0 : row.forecasted.setScale(2);
        li.Simulated_Value__c  = (row.simulated  == null) ? 0 : row.simulated.setScale(2);
        if (row.actual != null) {
            li.Actual_Value__c = row.actual.setScale(2);
        }
        toInsert.add(li);
    }
    if (!toInsert.isEmpty()) {
        System.debug('inserting toInsert simulation line items');
        insert toInsert;
        System.debug('inserted');
    }

    return sim.Id;
}

// evaluate simulation accuracy
/*
public class ActualValueDTO {
    @AuraEnabled public String yearMonth;   // 'YYYY-MM'
    @AuraEnabled public Decimal actual;     // actual demand (from JS)
}

// ---------- Result DTO + Comparable to allow results.sort() ----------
public class SimulationAccuracyResult implements Comparable {
    @AuraEnabled public Id simulationId;
    @AuraEnabled public String simulationName;
    @AuraEnabled public Decimal mae;        // Mean Absolute Error

    // Compare for ascending order on mae (nulls go last)
    public Integer compareTo(Object o) {
        SimulationAccuracyResult other = (SimulationAccuracyResult) o;
        Decimal a = this.mae;
        Decimal b = other.mae;
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        if (a < b) return -1;
        if (a > b) return 1;
        return 0;
    }
}

@AuraEnabled
public static List<SimulationAccuracyResult> evaluateSimulations(Id productId, String year, String actualsJson) {
    // Basic validation
    if (productId == null) {
        throw new AuraHandledException('Product Id is required.');
    }
    if (String.isBlank(year)) {
        throw new AuraHandledException('Year is required (YYYY).');
    }

    // Deserialize actualsJson if provided; otherwise use empty map (missing months -> 0)
    List<ActualValueDTO> actualList = new List<ActualValueDTO>();
    if (!String.isBlank(actualsJson)) {
        try {
            actualList = (List<ActualValueDTO>) JSON.deserialize(actualsJson, List<ActualValueDTO>.class);
        } catch (Exception ex) {
            throw new AuraHandledException('Invalid actualsJson: ' + ex.getMessage());
        }
    }

    Map<String, Decimal> actualsByMonth = new Map<String, Decimal>();
    for (ActualValueDTO a : actualList) {
        if (a == null) continue;
        String ym = a.yearMonth;
        if (String.isBlank(ym)) continue;
        actualsByMonth.put(ym, (a.actual == null) ? 0 : a.actual);
    }

    // Build year pattern for LIKE (e.g., '2025%')
    String yearPattern = year + '%';

    // Fetch Approved Demand simulations for this product & year
    List<Simulation__c> sims = [
        SELECT Id, Name, From_Period__c, To_Period__c
        FROM Simulation__c
        WHERE Product__c = :productId
          AND Type__c = 'Demand'
          AND From_Period__c LIKE :yearPattern
          AND Status__c = 'Approved'
        ORDER BY CreatedDate DESC
    ];

    if (sims.isEmpty()) {
        return new List<SimulationAccuracyResult>();
    }

    // Collect simulation Ids
    List<Id> simIds = new List<Id>();
    for (Simulation__c s : sims) simIds.add(s.Id);

    // Fetch line items for those simulations (simulated values)
    Map<Id, List<Simulation_Line_Item__c>> simLineMap = new Map<Id, List<Simulation_Line_Item__c>>();
    for (Simulation_Line_Item__c li : [
        SELECT Id, Simulation__c, YearMonth__c, Simulated_Value__c
        FROM Simulation_Line_Item__c
        WHERE Simulation__c IN :simIds
        ORDER BY YearMonth__c
    ]) {
        if (!simLineMap.containsKey(li.Simulation__c)) {
            simLineMap.put(li.Simulation__c, new List<Simulation_Line_Item__c>());
        }
        simLineMap.get(li.Simulation__c).add(li);
    }

    // Calculate MAE for each simulation
    List<SimulationAccuracyResult> results = new List<SimulationAccuracyResult>();
    for (Simulation__c sim : sims) {
        List<Simulation_Line_Item__c> lines = simLineMap.containsKey(sim.Id) ? simLineMap.get(sim.Id) : null;
        if (lines == null || lines.isEmpty()) {
            // skip simulations without line items
            continue;
        }

        Decimal sumAbsDiff = 0;
        Integer count = 0;

        for (Simulation_Line_Item__c li : lines) {
            Decimal simVal = (li.Simulated_Value__c == null) ? 0 : li.Simulated_Value__c;
            String ym = li.YearMonth__c;
            Decimal actualVal = (ym != null && actualsByMonth.containsKey(ym)) ? actualsByMonth.get(ym) : 0;
            sumAbsDiff += (simVal - actualVal).abs();
            count++;
        }

        SimulationAccuracyResult r = new SimulationAccuracyResult();
        r.simulationId = sim.Id;
        r.simulationName = sim.Name;
        if (count > 0) {
            r.mae = (sumAbsDiff / count).setScale(2); // two decimals
        } else {
            r.mae = null;
        }
        results.add(r);
    }

    // Sort by lowest MAE first (Comparable implementation)
    results.sort();

    return results;
}*/

  // ---------- DTO for actuals passed from JS ----------
    public class ActualValueDTO {
        @AuraEnabled public String yearMonth;   // 'YYYY-MM'
        @AuraEnabled public Decimal actual;     // actual demand (from JS)
    }

    // ---------- DTO for line-level accuracy ----------
    public class SimulationLineAccuracy {
        @AuraEnabled public String yearMonth;
        @AuraEnabled public Decimal simulated;
        @AuraEnabled public Decimal forecasted;
        @AuraEnabled public Decimal actual;
        @AuraEnabled public Decimal absError;   // |simulated - actual|
    }

    // ---------- Simulation result DTO ----------
    public class SimulationAccuracyResult implements Comparable {
        @AuraEnabled public Id simulationId;
        @AuraEnabled public String simulationName;
        @AuraEnabled public Decimal mae;   
        @AuraEnabled public List<SimulationLineAccuracy> lines;

        // Comparable implementation (for results.sort())
        public Integer compareTo(Object o) {
            SimulationAccuracyResult other = (SimulationAccuracyResult) o;
            Decimal a = this.mae;
            Decimal b = other.mae;
            if (a == null && b == null) return 0;
            if (a == null) return 1;   // nulls go last
            if (b == null) return -1;
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        }
    }

    /**
     * Evaluate simulations for a product & year using MAE.
     *
     * @param productId   Product2 Id to filter simulations
     * @param year        Year as 'YYYY' (used to filter From_Period__c)
     * @param actualsJson JSON array of ActualValueDTO: 
     *        [{ yearMonth: "2025-01", actual: 123 }, ...]
     *
     * Returns a list of SimulationAccuracyResult sorted by lowest MAE (most accurate first).
     */
    @AuraEnabled
    public static List<SimulationAccuracyResult> evaluateSimulations(Id productId, String year, String actualsJson) {
        // Validate inputs
        if (productId == null) {
            throw new AuraHandledException('Product Id is required.');
        }
        if (String.isBlank(year)) {
            throw new AuraHandledException('Year is required (YYYY).');
        }

        // Parse actualsJson
        List<ActualValueDTO> actualList = new List<ActualValueDTO>();
        if (!String.isBlank(actualsJson)) {
            try {
                actualList = (List<ActualValueDTO>) JSON.deserialize(actualsJson, List<ActualValueDTO>.class);
            } catch (Exception ex) {
                throw new AuraHandledException('Invalid actualsJson: ' + ex.getMessage());
            }
        }

        // Build a map of actuals keyed by YearMonth
        Map<String, Decimal> actualsByMonth = new Map<String, Decimal>();
        for (ActualValueDTO a : actualList) {
            if (a == null || String.isBlank(a.yearMonth)) continue;
            actualsByMonth.put(a.yearMonth, (a.actual == null) ? 0 : a.actual);
        }

        // Pattern for year filter
        String yearPattern = year + '%';

        // Fetch Approved Demand simulations for this product & year
        List<Simulation__c> sims = [
            SELECT Id, Name, From_Period__c, To_Period__c
            FROM Simulation__c
            WHERE Product__c = :productId
              AND Type__c = 'Demand'
              AND From_Period__c LIKE :yearPattern
              AND Status__c = 'Approved'
            ORDER BY CreatedDate DESC
        ];
        if (sims.isEmpty()) return new List<SimulationAccuracyResult>();

        // Collect ids
        List<Id> simIds = new List<Id>();
        for (Simulation__c s : sims) simIds.add(s.Id);

        // Fetch line items
        Map<Id, List<Simulation_Line_Item__c>> simLineMap = new Map<Id, List<Simulation_Line_Item__c>>();
        for (Simulation_Line_Item__c li : [
            SELECT Id, Simulation__c, YearMonth__c,
                   Simulated_Value__c, Forecasted_Value__c
            FROM Simulation_Line_Item__c
            WHERE Simulation__c IN :simIds
            ORDER BY YearMonth__c
        ]) {
            if (!simLineMap.containsKey(li.Simulation__c)) {
                simLineMap.put(li.Simulation__c, new List<Simulation_Line_Item__c>());
            }
            simLineMap.get(li.Simulation__c).add(li);
        }

        // Build results
        List<SimulationAccuracyResult> results = new List<SimulationAccuracyResult>();
        for (Simulation__c sim : sims) {
            List<Simulation_Line_Item__c> lines = simLineMap.get(sim.Id);
            if (lines == null || lines.isEmpty()) continue;

            Decimal sumAbsDiff = 0;
            Integer count = 0;
            List<SimulationLineAccuracy> lineResults = new List<SimulationLineAccuracy>();

            for (Simulation_Line_Item__c li : lines) {
                Decimal simVal = (li.Simulated_Value__c == null) ? 0 : li.Simulated_Value__c;
                Decimal fctVal = (li.Forecasted_Value__c == null) ? 0 : li.Forecasted_Value__c;
                String ym = li.YearMonth__c;
                Decimal actualVal = (ym != null && actualsByMonth.containsKey(ym)) ? actualsByMonth.get(ym) : 0;

                Decimal absErr = (simVal - actualVal).abs();

                SimulationLineAccuracy l = new SimulationLineAccuracy();
                l.yearMonth = ym;
                l.simulated = simVal;
                l.forecasted = fctVal;
                l.actual = actualVal;
                l.absError = absErr;
                lineResults.add(l);

                sumAbsDiff += absErr;
                count++;
            }

            SimulationAccuracyResult r = new SimulationAccuracyResult();
            r.simulationId = sim.Id;
            r.simulationName = sim.Name;
            r.mae = (count > 0) ? (sumAbsDiff / count).setScale(2) : null;
            r.lines = lineResults;
            results.add(r);
        }

        // Sort by lowest MAE
        results.sort();
        return results;
    }

}