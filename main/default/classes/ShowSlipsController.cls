public with sharing class ShowSlipsController {

    public List<LogisticsWrapper> data { get; set; }

    public ShowSlipsController() {

        String idsParam = ApexPages.currentPage().getParameters().get('logIds');
        data = new List<LogisticsWrapper>();

        if (String.isBlank(idsParam)) {
            return; // No IDs passed
        }

        // Convert comma separated IDs → List<Id>
        List<Id> logisticsIds = new List<Id>();
        for (String s : idsParam.split(',')) {
            logisticsIds.add((Id)s);
        }

        // Query Packages related to these Logistics
        List<Package__c> pkgs = [
            SELECT Id, Name, Logistic__c
            FROM Package__c
            WHERE Logistic__c IN :logisticsIds
        ];

        // Group packages by Logistics
        Map<Id, List<Package__c>> pkgMap = new Map<Id, List<Package__c>>();
        for (Id logId : logisticsIds) {
            pkgMap.put(logId, new List<Package__c>());
        }

        for (Package__c p : pkgs) {
            pkgMap.get(p.Logistic__c).add(p);
        }

        // Build wrapper data
        for (Id logId : logisticsIds) {
            LogisticsWrapper lw = new LogisticsWrapper();
            lw.logId = logId;
            lw.packages = pkgMap.get(logId);
            data.add(lw);
        }
    }

    public class LogisticsWrapper {
        public Id logId { get; set; }
        public List<Package__c> packages { get; set; }
    }
}