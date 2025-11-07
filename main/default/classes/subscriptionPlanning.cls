public with sharing class subscriptionPlanning {

    @AuraEnabled(cacheable=true)
     public static Account getDefaultOrg() {
        return UtilClass.getOrganisationByLogin_Employee();
    }

   @AuraEnabled(cacheable=true)
    public static List<Product2> getSubscribedProducts() {
        return [
            SELECT Id, Name, Picture__c
            FROM Product2
            WHERE Is_Subscribe__c = true
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getSubscribedOrderItems(Id organisationId) {
        return [
            SELECT Id, Product2.Name, Order.Name, UnitPrice, Quantity, Net_Price__c, Total_Tax__c, All_Total_Price__c, ServiceDate, EndDate, Month_Duration__c
            FROM OrderItem
            WHERE Is_Subscribe__c = true AND Company__c = : organisationId
        ];
    }

    public class StatusCount {
        @AuraEnabled public String status;
        @AuraEnabled public Integer count;
        
        public StatusCount(String status, Integer count) {
            this.status = status;
            this.count = count;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<StatusCount> getSubscriptionStatusCounts(Id organisationId) {
        List<AggregateResult> groupedResults = [
            SELECT Status__c status, COUNT(Id) recordCount
            FROM Subscription__c  WHERE Company__c = : organisationId
            GROUP BY Status__c
        ];
        
        List<StatusCount> results = new List<StatusCount>();
        for (AggregateResult ar : groupedResults) {
            results.add(new StatusCount(
                (String)ar.get('status'),
                (Integer)ar.get('recordCount')
            ));
        }
        return results;
    }


     public class ProductCount {
        @AuraEnabled public String productName;
        @AuraEnabled public Integer count;
        
        public ProductCount(String name, Integer count) {
            this.productName = name;
            this.count = count;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductCount> getTopSubscribedProducts(Id organisationId) {
        List<AggregateResult> groupedResults = [
            SELECT Name productName, COUNT(Id) recordCount
            FROM Subscription__c  WHERE Company__c = : organisationId
            GROUP BY Name
            ORDER BY COUNT(Id) DESC
            LIMIT 5
        ];
        
        List<ProductCount> results = new List<ProductCount>();
        for (AggregateResult ar : groupedResults) {
            results.add(new ProductCount(
                (String)ar.get('productName'),
                (Integer)ar.get('recordCount')
            ));
        }
        return results;
    }
}