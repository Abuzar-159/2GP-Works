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

}