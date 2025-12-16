public with sharing class ShowSlipsController {

    public List<LogisticsWrapper> data { get; set; }
 // Keywords to identify doc type from Title (adjust to your naming)
    private static final List<String> BOL_KEYS   = new List<String>{ '-bol', ' bol', 'bol' };
private static final List<String> LABEL_KEYS = new List<String>{ '-label', ' label', 'labels', 'lbl' };

    public ShowSlipsController() {

    //     String idsParam = ApexPages.currentPage().getParameters().get('logIds');
    //     data = new List<LogisticsWrapper>();

    //     if (String.isBlank(idsParam)) {
    //         return; // No IDs passed
    //     }

    //     // Convert comma separated IDs → List<Id>
    //     List<Id> logisticsIds = new List<Id>();
    //     for (String s : idsParam.split(',')) {
    //         logisticsIds.add((Id)s);
    //     }

    //     // Query Packages related to these Logistics
    //     List<Package__c> pkgs = [
    //         SELECT Id, Name, Logistic__c
    //         FROM Package__c
    //         WHERE Logistic__c IN :logisticsIds
    //     ];

    //     // Group packages by Logistics
    //     Map<Id, List<Package__c>> pkgMap = new Map<Id, List<Package__c>>();
    //     for (Id logId : logisticsIds) {
    //         pkgMap.put(logId, new List<Package__c>());
    //     }

    //     for (Package__c p : pkgs) {
    //         pkgMap.get(p.Logistic__c).add(p);
    //     }

    //     // Build wrapper data
    //     for (Id logId : logisticsIds) {
    //         LogisticsWrapper lw = new LogisticsWrapper();
    //         lw.logId = logId;
    //         lw.packages = pkgMap.get(logId);
    //         data.add(lw);
    //     }
    // }

    // public class LogisticsWrapper {
    //     public Id logId { get; set; }
    //     public List<Package__c> packages { get; set; }
    // }


   String idsParam = ApexPages.currentPage().getParameters().get('logIds');
        data = new List<LogisticsWrapper>();
        if (String.isBlank(idsParam)) return;

        List<Id> logisticsIds = new List<Id>();
        for (String s : idsParam.split(',')) logisticsIds.add((Id)s);

        // Packages per Logistic (your existing logic)
        List<Package__c> pkgs = [
            SELECT Id, Name, Logistic__c
            FROM Package__c
            WHERE Logistic__c IN :logisticsIds
        ];

        Map<Id, List<Package__c>> pkgMap = new Map<Id, List<Package__c>>();
        for (Id logId : logisticsIds) pkgMap.put(logId, new List<Package__c>());
        for (Package__c p : pkgs) pkgMap.get(p.Logistic__c).add(p);

        // Shipments related to Logistics
        List<Shipment__c> shps = [
            SELECT Id, Name, Logistic__c
            FROM Shipment__c
            WHERE Logistic__c IN :logisticsIds
        ];

        Set<Id> shipmentIds = new Set<Id>();
        Map<Id, List<Shipment__c>> shipmentByLog = new Map<Id, List<Shipment__c>>();
        for (Id logId : logisticsIds) shipmentByLog.put(logId, new List<Shipment__c>());

        for (Shipment__c s : shps) {
            shipmentIds.add(s.Id);
            shipmentByLog.get(s.Logistic__c).add(s);
        }

        // Build Shipment -> (BOL PDFs, Label PDFs)
        Map<Id, List<PdfFileWrap>> bolByShipment   = new Map<Id, List<PdfFileWrap>>();
        Map<Id, List<PdfFileWrap>> labelByShipment = new Map<Id, List<PdfFileWrap>>();

        if (!shipmentIds.isEmpty()) {
            // Shipment -> ContentDocument
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :shipmentIds
            ];

            Map<Id, Set<Id>> docIdsByShipment = new Map<Id, Set<Id>>();
            Set<Id> docIds = new Set<Id>();

            for (ContentDocumentLink l : links) {
                docIds.add(l.ContentDocumentId);
                if (!docIdsByShipment.containsKey(l.LinkedEntityId)) {
                    docIdsByShipment.put(l.LinkedEntityId, new Set<Id>());
                }
                docIdsByShipment.get(l.LinkedEntityId).add(l.ContentDocumentId);
            }

            // Latest PDF versions
            Map<Id, ContentVersion> latestPdfByDoc = new Map<Id, ContentVersion>();
            for (ContentVersion cv : [
                SELECT Id, Title, FileType, ContentDocumentId, IsLatest
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
                AND IsLatest = true
                AND FileType = 'PDF'
            ]) {
                latestPdfByDoc.put(cv.ContentDocumentId, cv);
            }

            // Categorize per Shipment using Title keywords
            for (Id shId : docIdsByShipment.keySet()) {
                for (Id dId : docIdsByShipment.get(shId)) {
                    ContentVersion cv = latestPdfByDoc.get(dId);
                    if (cv == null) continue;

                    String title = (cv.Title == null) ? '' : cv.Title.toLowerCase();
                    PdfFileWrap wrap = new PdfFileWrap(cv.Id, cv.Title);

                    if (containsAny(title, BOL_KEYS)) {
                        if (!bolByShipment.containsKey(shId)) bolByShipment.put(shId, new List<PdfFileWrap>());
                        bolByShipment.get(shId).add(wrap);
                    } else if (containsAny(title, LABEL_KEYS)) {
                        if (!labelByShipment.containsKey(shId)) labelByShipment.put(shId, new List<PdfFileWrap>());
                        labelByShipment.get(shId).add(wrap);
                    }
                }
            }
        }

        // Build wrapper data per Logistic
        for (Id logId : logisticsIds) {
            LogisticsWrapper lw = new LogisticsWrapper();
            lw.logId = logId;
            lw.packages = pkgMap.get(logId);
            lw.shipments = new List<ShipmentWrap>();

            for (Shipment__c s : shipmentByLog.get(logId)) {
                ShipmentWrap sw = new ShipmentWrap();
                sw.shipmentId = s.Id;
                sw.shipmentName = s.Name;
                sw.bolPdfs = bolByShipment.containsKey(s.Id) ? bolByShipment.get(s.Id) : new List<PdfFileWrap>();
                sw.labelPdfs = labelByShipment.containsKey(s.Id) ? labelByShipment.get(s.Id) : new List<PdfFileWrap>();
                lw.shipments.add(sw);
            }

            data.add(lw);
        }
    }

    private static Boolean containsAny(String haystack, List<String> needles) {
        for (String n : needles) {
            if (!String.isBlank(n) && haystack.contains(n.toLowerCase())) return true;
        }
        return false;
    }

    public class LogisticsWrapper {
        public Id logId { get; set; }
        public List<Package__c> packages { get; set; }
        public List<ShipmentWrap> shipments { get; set; }
    }

    public class ShipmentWrap {
        public Id shipmentId { get; set; }
        public String shipmentName { get; set; }
        public List<PdfFileWrap> bolPdfs { get; set; }
        public List<PdfFileWrap> labelPdfs { get; set; }
    }

//    public class PdfFileWrap {
//     public Id versionId { get; set; }
//     public String title { get; set; }

//     public PdfFileWrap(Id vId, String t) {
//         versionId = vId;
//         title = t;
//     }

// public String getInlineUrl() {
//         return '/sfc/servlet.shepherd/version/renditionDownload'
//             + '?rendition=ORIGINAL_Pdf'
//             + '&versionId=' + versionId
//             + '&operationContext=S1';
//     }
public class PdfFileWrap {
    public Id versionId { get; set; }
    public Id attachmentId { get; set; }
    public String title { get; set; }

    public String previewUrl { get; set; }
    public String openUrl { get; set; }

    // FILES (ContentVersion)
    public PdfFileWrap(Id vId, String t) {
        versionId = vId;
        title = t;

        // Salesforce native file preview
        previewUrl = '/lightning/r/ContentVersion/' + versionId + '/view';

        openUrl = '/sfc/servlet.shepherd/version/download/' + versionId;
    }

    // ATTACHMENTS
    public PdfFileWrap(Attachment a) {
        attachmentId = a.Id;
        title = a.Name;

        previewUrl = null;
        openUrl = '/servlet/servlet.FileDownload?file=' + attachmentId;
    }
}

}