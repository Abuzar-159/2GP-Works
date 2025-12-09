public with sharing class shipmentRP {
    private static final Set<String> FV_DOC_TYPES = new Set<String>{ 'bol', 'label', 'label-pdf' };
     @AuraEnabled(cacheable=true)
    public static List<Logistic_Line_Item__c> getLogisticLineItems(Id logisticId) {
        return [
            SELECT Id,
                   Logistic__r.Name,
                   Logistic__r.Order_S__r.Name,
                   Logistic__r.Distribution_Channel__r.Name,
                   Logistic__r.Total_Quantity__c,
                   Logistic__r.Type__c,
                   Product__c,
                   Product__r.Name,
                   Quantity__c
                   // add more fields if needed from Logistic__r or line item
            FROM Logistic_Line_Item__c
            WHERE Logistic__c = :logisticId
        ];
    }

     @AuraEnabled(cacheable=true)
    public static Package_Details__c getPackageDetails(String packageType) {
        return [
            SELECT Id,
                   Name,
                   Package_Type__c,
                   Width__c,
                   Height__c,
                   
                   Weight__c,
                   Weight_Unit__c,
                   Length__c
            FROM Package_Details__c
            WHERE Package_Type__c = :packageType
            LIMIT 1
        ];

       }

    // @AuraEnabled(cacheable=true)
    // public static Order getOrderAddressInfo(Id orderId) {
    //     return [
    //         SELECT Id, Name, Bill_To_Address__c,
    //                Bill_To_Address__r.Id,
    //                Bill_To_Address__r.Name,
    //                Ship_To_Address__c,
    //                Ship_To_Address__r.Id,
    //                Ship_To_Address__r.Name
    //         FROM Order
    //         WHERE Id = :orderId
    //         LIMIT 1
    //     ];
    // }

      // Wrapper returned to LWC
    public class LogisticDetailsWrapper {
        @AuraEnabled public Logistic__c logistic      { get; set; }
        @AuraEnabled public Address__c fromAddress   { get; set; }
        @AuraEnabled public Address__c toAddress     { get; set; }
        @AuraEnabled public Account    account       { get; set; }
        @AuraEnabled public Contact    contact       { get; set; }     // TO contact (priority)
        @AuraEnabled public Contact    fromContact   { get; set; }     // FROM contact (priority)
    }
    @AuraEnabled(cacheable=true)
public static LogisticDetailsWrapper getLogisticDetails(Id logisticId) {
    LogisticDetailsWrapper wrap = new LogisticDetailsWrapper();
    if (logisticId == null) return wrap;

    // Fetch Logistic minimal
    String logiFields = UtilClass.selectStarFromSObject('Logistic__c');
        Logistic__c logi = (Logistic__c) Database.query(
        'SELECT ' + logiFields + ', Account__r.Name ' +
        'FROM Logistic__c WHERE Id = :logisticId LIMIT 1'
    );

    // Logistic__c logi = (Logistic__c) Database.query(
    //     'SELECT Id, Name, From_Address__c, To_Address__c, Contact__c, From_Contact__c, Account__c, Account__r.Name, Order_S__c FROM Logistic__c WHERE Id=\'' + logisticId + '\' LIMIT 1'
    // );

    wrap.logistic = logi;
    wrap.account  = logi.Account__r;

    String addressFields = UtilClass.selectStarFromSObject('Address__c');

    // 2️⃣ Fetch FROM Address if present
    if (logi.From_Address__c != null) {
        wrap.fromAddress = (Address__c) Database.query(
            'SELECT ' + addressFields + ', Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c, Customer__r.Company_txt__c FROM Address__c WHERE Id=\'' + logi.From_Address__c + '\' LIMIT 1'
        );
        wrap.fromContact = wrap.fromAddress?.Contact__r; // priority link
    }

    // 3️⃣ Fetch TO Address if present
    if (logi.To_Address__c != null) {
        wrap.toAddress = (Address__c) Database.query(
            'SELECT ' + addressFields + ', Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c, Customer__r.Company_txt__c FROM Address__c WHERE Id=\'' + logi.To_Address__c + '\' LIMIT 1'
        );
        wrap.Contact = wrap.toAddress?.Contact__r;
    }

    // 4️⃣ Fetch FROM Contact if explicitly present on Logistic
    if (logi.From_Contact__c != null) {
        wrap.fromContact = (Contact) Database.query(
            'SELECT Id, Name, AccountId, Account.Name, Account.Phone, Account.Email__c, Email, Phone, Company__c,Company__r.Name FROM Contact WHERE Id=\'' + logi.From_Contact__c + '\' LIMIT 1'
        );
    }

    // 5️⃣ Fetch TO Contact if explicitly present on Logistic
    if (logi.Contact__c != null) {
        wrap.Contact = (Contact) Database.query(
            'SELECT Id, Name, AccountId, Account.Name, Account.Phone, Account.Email__c, Email, Phone, Company__c,Company__r.Name FROM Contact WHERE Id=\'' + logi.Contact__c + '\' LIMIT 1'
        );
    }

    return wrap;
}

    // @AuraEnabled(cacheable=true)
    // public static LogisticDetailsWrapper getLogisticDetails(Id logisticId) {
    //     LogisticDetailsWrapper wrap = new LogisticDetailsWrapper();

    //     if (logisticId == null) {
    //         return wrap;
    //     }

    //     Logistic__c logi = [
    //         SELECT
    //             Id,
    //             Name,

    //             /* Logistic__c fields (add more as needed) */
    //             /*Status__c,
    //             Shipment_Mode__c,*/
    //             From_Address__c,
    //             To_Address__c,
    //             Contact__c,
    //             From_Contact__c,
    //             Account__c,

    //             /* Account fields */
    //             Account__r.Id,
    //             Account__r.Name,
    //             Account__r.Phone,
    //             Account__r.Email__c,
    //             Account__r.Company__c,

    //             /* =======================
    //                TO Address + relations
    //                ======================= */
    //             To_Address__r.Id,
    //             To_Address__r.Name,
    //             To_Address__r.Customer__c,
    //             To_Address__r.Contact__c,
    //             To_Address__r.Is_Billing_Address__c,
    //             To_Address__r.Active__c,
    //             To_Address__r.Is_Shipping_Address__c,
    //             To_Address__r.Primary__c,
    //             To_Address__r.opens_at__c,
    //             To_Address__r.closes_at__c,
    //             To_Address__r.Country__c,
    //             To_Address__r.Address_Line1__c,
    //             To_Address__r.Address_Line2__c,
    //             To_Address__r.Address_Line3__c,
    //             To_Address__r.City__c,
    //             To_Address__r.State__c,
    //             To_Address__r.Postal_Code__c,
    //             To_Address__r.Company__c,

    //                 /* To Address → Contact__c */
    //                 To_Address__r.Contact__r.Id,
    //                 To_Address__r.Contact__r.Name,
    //                 To_Address__r.Contact__r.Phone,
    //                 To_Address__r.Contact__r.Email,

    //                 /* To Address → Customer__c */
    //                 To_Address__r.Customer__r.Id,
    //                 To_Address__r.Customer__r.Name,
    //                 To_Address__r.Customer__r.Phone,
    //                 To_Address__r.Customer__r.Email__c,
    //                 To_Address__r.Customer__r.Company__c,

    //             /* =========================
    //                FROM Address + relations
    //                ========================= */
    //             From_Address__r.Id,
    //             From_Address__r.Name,
    //             From_Address__r.Customer__c,
    //             From_Address__r.Contact__c,
    //             From_Address__r.Is_Billing_Address__c,
    //             From_Address__r.Active__c,
    //             From_Address__r.Is_Shipping_Address__c,
    //             From_Address__r.Primary__c,
    //             From_Address__r.opens_at__c,
    //             From_Address__r.closes_at__c,
    //             From_Address__r.Country__c,
    //             From_Address__r.Address_Line1__c,
    //             From_Address__r.Address_Line2__c,
    //             From_Address__r.Address_Line3__c,
    //             From_Address__r.City__c,
    //             From_Address__r.State__c,
    //             From_Address__r.Postal_Code__c,
    //             From_Address__r.Company__c,
    //             From_Address__r.Company__r.Name,
    //             From_Address__r.Contact__r.Company__r.Name,
    //             From_Address__r.Contact__r.Company__r.Name,

    //                 /* From Address → Contact__c */
    //                 From_Address__r.Contact__r.Id,
    //                 From_Address__r.Contact__r.Name,
    //                 From_Address__r.Contact__r.Phone,
    //                 From_Address__r.Contact__r.Email,

    //                 /* From Address → Customer__c */
    //                 From_Address__r.Customer__r.Id,
    //                 From_Address__r.Customer__r.Name,
    //                 From_Address__r.Customer__r.Phone,
    //                 From_Address__r.Customer__r.Email__c,
    //                 From_Address__r.Customer__r.Company__c,

    //             /* Logistic__c main Contact__c (TO) */
    //             Contact__r.Id,
    //             Contact__r.Name,
    //             Contact__r.Phone,
    //             Contact__r.Email,
    //             Contact__r.Company__c,  
    //             Contact__r.Company__r.Name,
    //             Contact__r.Account.Name, 

    //             /* Logistic__c From_Contact__c (FROM) */
    //             From_Contact__r.Id,
    //             From_Contact__r.Name,
    //             From_Contact__r.Phone,
    //             From_Contact__r.Email
    //             From_Contact__r.Company__c,   
    //             From_Contact__r.Company__r.Name,   
    //             From_Contact__r.Account.Name 
    //         FROM Logistic__c
    //         WHERE Id = :logisticId
    //         LIMIT 1
    //     ];

    //     // Basic assignments
    //     wrap.logistic    = logi;
    //     wrap.fromAddress = logi.From_Address__r;
    //     wrap.toAddress   = logi.To_Address__r;
    //     wrap.account     = logi.Account__r;

    //     /* ==========================
    //        PRIORITY: FROM CONTACT
    //        1. Logistic__c.From_Contact__r
    //        2. From_Address__r.Contact__r
    //        ========================== */
    //     if (logi.From_Contact__r != null) {
    //         wrap.fromContact = logi.From_Contact__r;
    //     } else if (logi.From_Address__r != null &&
    //                logi.From_Address__r.Contact__r != null) {
    //         wrap.fromContact = logi.From_Address__r.Contact__r;
    //     } else {
    //         wrap.fromContact = null;
    //     }

    //     /* ==========================
    //        PRIORITY: TO CONTACT
    //        1. Logistic__c.Contact__r
    //        2. To_Address__r.Contact__r
    //        ========================== */
    //     if (logi.Contact__r != null) {
    //         wrap.contact = logi.Contact__r;
    //     } else if (logi.To_Address__r != null &&
    //                logi.To_Address__r.Contact__r != null) {
    //         wrap.contact = logi.To_Address__r.Contact__r;
    //     } else {
    //         wrap.contact = null;
    //     }

    //     return wrap;
    // }
    
@AuraEnabled(cacheable=true)
public static FetchInitWrapper fetchInitialData() {
    FetchInitWrapper data = new FetchInitWrapper();

    // ----- Picklists from Package__c -----
    data.dimensionOptions = getPicklistOptions(Package__c.Dimension__c);
    data.weightUnitOptions = getPicklistOptions(Package__c.Weight_Unit__c);
    data.freightClassOptions = getPicklistOptions(Package__c.freight_class__c);
    data.hazardClassOptions = getPicklistOptions(Package__c.Primary_Hazard_Class__c);
    data.packagingGroupOptions = getPicklistOptions(Package__c.Packaging_Group__c);

    // ----- Dynamic Credential Query -----
    Set<String> credNames = new Set<String>{
       System.Label.FedexRestAPI,
        System.Label.UPSRESTAPI,
        System.Label.AxoltFreightView
 
    };

    String fields = UtilClass.selectStarFromSObject('Credentials__c');

    String soql = 'SELECT ' + fields + ' FROM Credentials__c WHERE Name IN :credNames';
    List<Credentials__c> creds = (List<Credentials__c>) Database.query(soql);

    for (Credentials__c c : creds) {
        data.credentialsMap.put(c.Name, c);
    }

    return data;
}

// ✅ Generic picklist fetch helper (no extra SOQL)
public static List<SelectOptionWrapper> getPicklistOptions(Schema.SObjectField fieldRef){
    List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
    for (Schema.PicklistEntry p : fieldRef.getDescribe().getPicklistValues()) {
        options.add(new SelectOptionWrapper(p.getValue(), p.getLabel()));
    }
    return options;
}

 @AuraEnabled
    public static String getProvinceCode(String provinceName) {
        List<Province_Codes__c> provinceList = new List<Province_Codes__c>();
        if(String.isNotEmpty(provinceName)) {
            provinceList = [Select Id, Name, Code__c, Province__c From Province_Codes__c Where Province__c =: provinceName Limit 1];
        }
        if(provinceList.size() > 0) return provinceList[0].Code__c; else return '';
 
    }

     @AuraEnabled
    public static String getCountryCode(String countryName) {
        List<Country_Codes__c> countryList = new  List<Country_Codes__c>();
        if(String.isNotEmpty(countryName)) {
            countryList = [Select Id, Name, Code__c, Country__c From Country_Codes__c Where Country__c =: countryName  Limit 1];
        }
        if(countryList.size() > 0) return countryList[0].Code__c; else return '';
    }
private static Map<String,Object> buildLocationMap(Address__c addr, Contact con,Boolean isParcel,Boolean isOrigin) {
    Map<String,Object> m = new Map<String,Object>();
    if (addr == null) addr = new Address__c();

    // company fallback
    String company =
        (con != null && con.Company__r != null && !String.isBlank(con.Company__r.Name)) ? con.Company__r.Name :
        (addr.Customer__r != null && !String.isBlank(addr.Customer__r.Company_txt__c)) ? addr.Customer__r.Company_txt__c :
        (con != null && con.Account != null) ? con.Account.Name : null;
    System.debug('isOrigin '+isOrigin);
    System.debug('company: ' + company);
    System.debug('addr: ' + addr);
    System.debug('con: ' + con);
    m.put('company', company);
    m.put('address', addr.Name);
    m.put('city', addr.City__c);

    String st = getProvinceCode(addr.State__c);
    m.put('state', st);
    String cn = getCountryCode(addr.Country__c);
    m.put('country', String.isBlank(cn) ? 'us' : cn.toLowerCase());

    m.put('postalCode', addr.Postal_Code__c);
    m.put('contactName',  con != null ? con.Name  : null);
    m.put('contactPhone', con != null ? con.Phone : null);
    m.put('contactEmail', con != null ? con.Email : null);
    if (!(isParcel && !isOrigin)) {
    m.put('opensAt',  addr.opens_at__c != null ? ((addr.opens_at__c.hour()<10?'0':'')+addr.opens_at__c.hour()) + ':' + ((addr.opens_at__c.minute()<10?'0':'')+addr.opens_at__c.minute()) : null);
    m.put('closesAt', addr.closes_at__c != null ? ((addr.closes_at__c.hour()<10?'0':'')+addr.closes_at__c.hour()) + ':' + ((addr.closes_at__c.minute()<10?'0':'')+addr.closes_at__c.minute()) : null);
    //new extra things 
     if (!isOrigin && !isParcel) { // destination side
        String acc = addr.Accessorials__c;
       if (!String.isBlank(acc) && acc != '--None--') {
            Map<String, Boolean> accMap = new Map<String, Boolean>();

            // Only map supported Freightview accessorial fields
            if (acc == 'inside') {
                accMap.put('inside', true);
            } else if (acc == 'liftgate') {
                accMap.put('liftgate', true);
            } else if (acc == 'schedule') {
                accMap.put('schedule', true);
            } else if (acc == 'sortAndSegregate') {
                accMap.put('sortAndSegregate', true);
            } else if (acc == 'notify') {
                accMap.put('notify', true);
            }
            // add accessorial object only if valid key was mapped
            if (!accMap.isEmpty()) {
                m.put('accessorials', accMap);
            }
        }

        // Notes/Instructions only if available
        if (!String.isBlank(addr.Notes__c)) {
            m.put('instructions', addr.Notes__c);
        }
        if (!String.isBlank(addr.Delivery_Location_Type__c)  && addr.Delivery_Location_Type__c != '--None--') {
            m.put('shipType', addr.Delivery_Location_Type__c);
        }

    }
    }
    return m;
}
    // public static List<quoteWrapper> getRatesFEDEX(
    //     List<Package__c> pkgList,
    //     Shipment__c ship,
    //     Address__c fromA,
    //     Address__c toA,
    //     Boolean schedulePickup,
    //     DateTime pickupDT,
    //     Credentials__c cred
    // ){
    //     List<quoteWrapper> out = new List<quoteWrapper>();
    //     String jsonPayload = FedExPayloadBuilder.buildLTLRatePayload(
    //         pkgList, cred, fromA, toA, schedulePickup, pickupDT
    //     );

    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(cred.Endpoint_URL__c);
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setHeader('Authorization', 'Bearer ' + FedExToken.getAccessToken(cred));
    //     req.setBody(jsonPayload);

    //     HttpResponse r = new Http().send(req);
    //     if(r.getStatusCode() == 200){
    //         Map<String,Object> m = (Map<String,Object>)JSON.deserializeUntyped(r.getBody());
    //         for(Object o : (List<Object>)m.get('rateReplyDetails')){
    //             Map<String,Object> q = (Map<String,Object>)o;
    //             quoteWrapper w = new quoteWrapper();
    //             w.provider = 'FedEx';
    //             w.carrier = (String)q.get('serviceName');
    //             w.service = (String)q.get('serviceType');
    //             w.amount  = Decimal.valueOf((String)q.get('ratedShipmentDetails[0].totalNetCharge'));
    //             w.currencyQ = (String)q.get('currency');
    //             w.quoteId = (String)q.get('serviceType');
    //             w.shipmentCreated = false;
    //             out.add(w);
    //         }
    //     }
    //     return out;
    // }
    // public static List<quoteWrapper> getRatesUPS(
    //     List<Package__c> pkgList,
    //     Shipment__c ship,
    //     Address__c fromA,
    //     Address__c toA,
    //     Boolean schedulePickup,
    //     DateTime pickupDT,
    //     Credentials__c cred
    // ){
    //     List<quoteWrapper> out = new List<quoteWrapper>();
    //     String token = UPSRestAPI.getAccessToken(cred);
    //     String jsonPayload = UPSPayloadBuilder.buildLTLRatePayload(
    //         pkgList, cred, fromA, toA, schedulePickup, pickupDT
    //     );

    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(cred.Endpoint_URL__c);
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setHeader('TransactionSrc', fromA.Account_Number__c);
    //     req.setHeader('TransID', fromA.Account_Number__c);
    //     req.setHeader('Authorization', 'Bearer ' + token);
    //     req.setBody(jsonPayload);

    //     HttpResponse r = new Http().send(req);
    //     if(r.getStatusCode() == 200){
    //         Map<String,Object> m = (Map<String,Object>)JSON.deserializeUntyped(r.getBody());
    //         for(Object o : (List<Object>)m.get('ShipmentResponse.ShipmentResults.rateWrap')){
    //             Map<String,Object> q = (Map<String,Object>)o;
    //             quoteWrapper w = new quoteWrapper();
    //             w.provider = 'UPS';
    //             w.carrier = (String)q.get('Description');
    //             w.service = (String)q.get('Code');
    //             w.amount  = q.containsKey('TotalCharges.MonetaryValue')
    //                            ? Decimal.valueOf((String)q.get('TotalCharges.MonetaryValue')) : 0;
    //             w.currencyQ = (String)q.get('CurrencyCode');
    //             w.quoteId = (String)q.get('Code');
    //             w.shipmentCreated = false;
    //             out.add(w);
    //         }
    //     }
    //     return out;
    // }

//working this below
    // public static List<quoteWrapper> getRatesFV(
    //     List<Package__c> pkgList,
    //     Address__c fromA,
    //     Address__c toA,
    //     Boolean schedulePickup,
    //     String pickupDT,
    //     Credentials__c cred,
    //     String fromContact,
    //     String toContact
    // ){
    //     List<quoteWrapper> out = new List<quoteWrapper>();
    //     if (cred == null) return out; // safe exit, no crash

    //     // ---- Token ----
    //     String token = freightView.getAccessToken(cred.Username_Login__c,cred.Password_Transkey__c,cred.URL__c);
    //      Contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);
    //     Contact shipToContact   = (Contact) JSON.deserialize(toContact,   Contact.class);
    //     // ---- Build ONLY LTL payload (reuse your working mapping logic) ----
    //     Map<String,Object> payload = new Map<String,Object>();
    //     payload.put('pickupDate', pickupDT);

    //     List<Map<String,Object>> itemsList = new List<Map<String,Object>>();
    //     Boolean hasHazmat = false;

    //     for(Package__c p : pkgList){
    //         Map<String,Object> item = new Map<String,Object>{
    //             'description' => 'test',
    //             'quantity'    => 1,
    //             'type'        => p.Package_Type__c != null ? p.Package_Type__c.toLowerCase() : '',
    //             'weight'      => p.Weight__c,
    //             'weightUOM'   => 'lbs',
    //             'length'      => p.Length__c,
    //             'width'       => p.Width__c,
    //             'height'      => p.Height__c,
    //             'dimensionsUOM' => 'in'
    //         };

    //         if(p.is_hazmat__c == true){
    //             hasHazmat = true;

    //             if (String.isNotBlank(p.Hazmat_ID__c) &&
    //                 String.isNotBlank(p.Primary_Hazard_Class__c) &&
    //                 String.isNotBlank(p.Packaging_Group__c)) {

    //                 item.put('hazardous', new Map<String,Object>{
    //                     'hazmatId'     => p.Hazmat_ID__c,
    //                     'primaryClass' => p.Primary_Hazard_Class__c,
    //                     'packingGroup' => p.Packaging_Group__c
    //                 });
    //             }
    //         }

    //         itemsList.add(item);
    //     }

    //     payload.put('items', itemsList);
    //     payload.put('origin', buildLocationMap(fromA, shipFromContact,false,true));
    //     payload.put('destination', buildLocationMap(toA, shipToContact,false,false));
    //     // payload.put('pickupDate', pickupDT);
    //     // payload.put('returnQuotes', true);
    //    // payload.put('isHazardous', hasHazmat);
    //     String path = '/v2.0/shipments/ltl?returnQuotes=true';
    //     // ---- Callout ----
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(cred.URL__c + path);
    //     req.setMethod('POST');
    //     req.setHeader('Content-Type', 'application/json');
    //     req.setHeader('Authorization', 'Bearer ' + token);
    //     req.setTimeout(30000); // 30 sec
    //     req.setBody(JSON.serialize(payload));
    //      Http http = new Http();
    //      HttpResponse r = http.send(req);
    //     System.debug('FV LTL API Response => ' + r.getBody());

    //     // ---- Parse quotes ----
    //     if(r.getStatusCode() == 200 || r.getStatusCode() == 201){
    //         Map<String,Object> m = (Map<String,Object>)JSON.deserializeUntyped(r.getBody());
    //         if(m.containsKey('quotes')){
    //             for(Object qObj : (List<Object>)m.get('quotes')){
    //                 Map<String,Object> q = (Map<String,Object>)qObj;
    //                 quoteWrapper w = new quoteWrapper();
    //                 w.provider = 'FreightView';
    //                 w.carrier = (String)q.get('assetCarrierName');
    //                 w.service = (String)q.get('serviceDescription');
    //                 w.amount  = q.containsKey('amount') ? (Decimal)q.get('amount') : 0;
    //                 w.currencyQ = (String)q.get('currency');
    //                 w.quoteId = (String)q.get('quoteId');
    //                 w.shipmentCreated = true;
    //                 out.add(w);
    //             }
    //         }
    //     }
    //     return out;
    // }
    public static List<quoteWrapper> getRatesFV(
    List<PackageInputWrapper> pkgList,
    Address__c fromA,
    Address__c toA,
    Boolean schedulePickup,
    String pickupDT,
    Credentials__c cred,
    String fromContactJson,
    String toContactJson
){
    List<quoteWrapper> out = new List<quoteWrapper>();
    if (cred == null) return out;

    // Token call stays same
    String token = freightView.getAccessToken(cred.Username_Login__c, cred.Password_Transkey__c, cred.URL__c);

    // Payload building
          Contact shipFromContact = (Contact) JSON.deserialize(fromContactJson, Contact.class);
        Contact shipToContact   = (Contact) JSON.deserialize(toContactJson,   Contact.class);
   
    Map<String,Object> payload = new Map<String,Object>();
    payload.put('pickupDate', pickupDT);
    // payload.put('returnQuotes', true);

    List<Map<String,Object>> items = new List<Map<String,Object>>();
    Boolean hasHazmat = false;

    for(PackageInputWrapper p : pkgList){
        System.debug('package -->'+p);
        System.debug('package type -->'+p.FVPackageType);
        System.debug('package weight -->'+p.Weight);
        Map<String,Object> item = new Map<String,Object>{
            'description' => p.FVPackageType,
            'quantity'    => p.Quantity == null ? 1 : p.Quantity,
            'type'        => p.FVPackageType != null ? p.FVPackageType.toLowerCase() : '',
            'weight'      => p.Weight,
            'weightUOM'   => p.WeightUnit != null ? p.WeightUnit.toLowerCase() : 'lbs',
            'length'      => p.Length,
            'width'       => p.Width,
            'height'      => p.Height,
            'dimensionsUOM' => 'in',
            'freightClass'=> p.FreightClass != null ? Decimal.valueOf(p.FreightClass) : 50
        };

        if(p.isHazmat == true){
            hasHazmat = true;
        }

        items.add(item);
    }

    payload.put('items', items);
       payload.put('origin', buildLocationMap(fromA, shipFromContact,false,true));
        payload.put('destination', buildLocationMap(toA, shipToContact,false,false));
         payload.put('pickupDate', pickupDT);
    // Send request
    HttpRequest req = new HttpRequest();
    req.setEndpoint(cred.URL__c + '/v2.0/shipments/ltl?returnQuotes=true');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + token);
    req.setTimeout(30000);
    req.setBody(JSON.serialize(payload));

    HttpResponse res = new Http().send(req);
    System.debug('FV API Response => ' + res.getBody());
    if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
    Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        String shipmentId = (String) resMap.get('shipmentId');
        if (resMap.containsKey('quotes')) {
            List<Object> quotes = (List<Object>) resMap.get('quotes');

            for (Object qObj : quotes) {
                Map<String, Object> q = (Map<String, Object>) qObj;
                String status = (String) q.get('status');
                String mode = (String) q.get('mode');

                if (status == 'active' && mode == 'ltl') {  // focusing only on LTL active quotes
                    quoteWrapper qw = new quoteWrapper();

                    qw.provider = 'Freight View';
                    qw.carrier = (String) q.get('assetCarrierName');
                    qw.service = (String) q.get('serviceDescription');
                    qw.amount = (Decimal) q.get('amount');
                    qw.currencyQ = (String) q.get('currency');
                    qw.quoteId = (String) q.get('quoteId');

                    if (q.containsKey('shipmentId')) { qw.shipmentId = (String) q.get('shipmentId'); }
                     qw.shipmentId = shipmentId;
                    out.add(qw);
                }
            }
        }
    }
    return out;
}

@AuraEnabled
public static RateResponseLTL getQuoteRatesLTL(
    List<String> providerList,
    String fromAddressJson,
    String toAddressJson,
    String logisticJson,
    String pkgListJson,
    Boolean schedulePickup,
    String pickupDT,
    String fromContact,
    String toContact
){

    RateResponseLTL resp = new RateResponseLTL();
    resp.quotesFedex = new List<quoteWrapper>();
    resp.quotesUPS = new List<quoteWrapper>();
    resp.quotesFreightView = new List<quoteWrapper>();
    resp.missingCredentials = new List<String>();

    FetchInitWrapper init = shipmentRP.fetchInitialData();
    Map<String,Credentials__c> cm = init.credentialsMap;
    System.debug('deserialiing');
    List<PackageInputWrapper> pkgList = new List<PackageInputWrapper>();

        if (String.isNotBlank(pkgListJson)) {
            pkgList = (List<PackageInputWrapper>) JSON.deserialize(
                pkgListJson,
                List<PackageInputWrapper>.class
            );
        }

        System.debug('📦 Parsed Package List => ' + pkgList);

    System.debug('bfA');
    Address__c fromA2;
    Address__c toA2;
    try {
        fromA2 = (Address__c) JSON.deserialize(fromAddressJson, Address__c.class);
    } catch (Exception e) {
        resp.missingCredentials.add('From Address invalid JSON: ' + e.getMessage());
    }

    try {
        toA2 = (Address__c) JSON.deserialize(toAddressJson, Address__c.class);
    } catch (Exception e) {
        resp.missingCredentials.add('To Address invalid JSON: ' + e.getMessage());
    }
    System.debug('package list '+pkgList);
    if(fromA2 == null) fromA2 = new Address__c();
    if(toA2 == null) toA2 = new Address__c();
    System.debug('AF A');
    Contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);
    Contact shipToContact   = (Contact) JSON.deserialize(toContact,   Contact.class);
    System.debug('AFR C');
    Boolean hasFD = cm.containsKey('FedEx');
    Boolean hasUPS = cm.containsKey('UPS');
    
     String fvKey = System.Label.AxoltFreightViewERP;
     Boolean hasFV  = cm.containsKey(fvKey); System.debug('hasFV '+hasFV);
    if(providerList.contains('fedex') && !hasFD)  resp.missingCredentials.add('FedEx');
    if(providerList.contains('ups') && !hasUPS) resp.missingCredentials.add('UPS');
    if(providerList.contains('freightview') && !hasFV) resp.missingCredentials.add('FreightView');

    if(providerList.contains('fedex') && hasFD){
       // resp.quotesFedex =getRatesFEDEX(pkgList, null, fromA, toA, schedulePickup, pickupDT,  cm.get(System.Label.FedexRestAPIName));
    }
        

    if(providerList.contains('ups') && hasUPS){
        //resp.quotesUPS = getRatesUPS(pkgList, null, fromA, toA, schedulePickup, pickupDT,  cm.get(System.Label.UPSRESTAPIName));
    }
        

    if(providerList.contains('freightview') && hasFV){
         Credentials__c fvCred = cm.get(fvKey);
        resp.quotesFreightView =  resp.quotesFreightView = getRatesFV(pkgList,fromA2,toA2,true,pickupDT,fvCred,fromContact,toContact);
        }
    return resp;
}
@AuraEnabled
public static BookingResult bookSelectedQuote(
    String provider,
    String quoteId,
    String fvShipmentId,
    Boolean schedulePickup,
    String mode,
    String fromAddressJson,
    String toAddressJson,
    String logisticJson,
    String fromContactJson,
    String toContactJson
) {
    BookingResult br = new BookingResult();

    System.debug('in booking method');
    if (String.isBlank(provider) || String.isBlank(quoteId)) {
        br.success = false;
        br.message = 'Missing provider or quoteId.';
        return br;
    }

    // Use same init as rating to avoid passing credentials from JS
    FetchInitWrapper init = fetchInitialData();
    Map<String, Credentials__c> cm = init.credentialsMap;

    String p = provider.toLowerCase();

    try {
        // 🔹 FreightView
        if (p.contains('freight')) {
            String fvKey = System.Label.AxoltFreightViewERP;
            Credentials__c fvCred = cm.get(fvKey);
            if (fvCred == null) {
                br.success = false;
                br.message = 'FreightView credentials are not configured.';
                return br;
            }

            br = bookFreightviewLtl(
                fvShipmentId,
                quoteId,
                schedulePickup,
                fvCred,
                mode,
                logisticJson,
                fromContactJson,
                toContactJson,
                fromAddressJson,
                toAddressJson
            );
            return br;
        }

        // 🔹 FedEx (stub for now)
        if (p.contains('fedex')) {
            br.success = false;
            br.message = 'FedEx booking not implemented yet.';
            return br;
        }

        // 🔹 UPS (stub for now)
        if (p.contains('ups')) {
            br.success = false;
            br.message = 'UPS booking not implemented yet.';
            return br;
        }

        br.success = false;
        br.message = 'Unsupported provider: ' + provider;
        return br;

    } catch (Exception e) {
        br.success = false;
        br.message = 'Error in bookSelectedQuote: ' + e.getMessage();
        return br;
    }
}
// private static BookingResult bookFreightviewLtl(
//     String fvShipmentId,
//     String quoteId,
//     Boolean schedulePickup,
//     Credentials__c cred,
//     String mode
// ) {
//     System.debug('in booking FV');
//     BookingResult br = new BookingResult();
//     br.success = false;

//     if (String.isBlank(fvShipmentId)) {
//         br.message = 'Missing FreightView shipmentId from quote.';
//         return br;
//     }
//     if (String.isBlank(quoteId)) {
//         br.message = 'Missing FreightView quoteId.';
//         return br;
//     }
//     if (cred == null) {
//         br.message = 'FreightView credentials not provided.';
//         return br;
//     }

//     try {
//         // ---------- Auth ----------
//         String token = freightView.getAccessToken(
//             cred.Username_Login__c,
//             cred.Password_Transkey__c,
//             cred.URL__c
//         );

//         // ---------- Mode ----------
//         String m = (mode == null ? '' : mode.trim().toLowerCase());
//         if (m != 'truckload' && m != 'parcel' && m != 'ltl') m = 'ltl';
//         Boolean isParcel    = (m == 'parcel');
//         Boolean isTruckload = (m == 'truckload');
//         Boolean isLTL       = (m == 'ltl');

//         String encId = EncodingUtil.urlEncode(fvShipmentId, 'UTF-8');

//         // ---------- Build endpoint ----------
//         String endpoint;
//         if (isTruckload) {
//             endpoint = cred.URL__c + '/v2.0/shipments/truckload/' + encId + '/award';
//         } else if (isParcel) {
//             endpoint = cred.URL__c + '/v2.0/shipments/parcel/' + encId + '/book';
//         } else {
//             // default LTL
//             endpoint = cred.URL__c + '/v2.0/shipments/ltl/' + encId + '/book';
//         }

//         Map<String,Object> body = new Map<String,Object>();
//         body.put('quoteId', quoteId);

//         if (isLTL) {
//             body.put('schedulePickup', (schedulePickup == null ? true : schedulePickup));
//         }

//         HttpRequest req = new HttpRequest();
//         req.setEndpoint(endpoint);
//         req.setMethod('POST');
//         req.setHeader('Content-Type', 'application/json');
//         req.setHeader('Authorization', 'Bearer ' + token);
//         req.setTimeout(30000);
//         req.setBody(JSON.serialize(body));

//         Http http = new Http();
//         HttpResponse res = http.send(req);
//         Integer sc = res.getStatusCode();
//         String resBody = res.getBody();
//         br.responseRaw = resBody;

//         System.debug('FreightView booking SC=' + sc + ' BODY=' + resBody);

//         // ---------- Error handling ----------
//         if (sc != 200 && sc != 201 && sc != 204) {
//             Map<String, Object> err = null;
//             try {
//                 err = (Map<String, Object>) JSON.deserializeUntyped(resBody);
//             } catch (Exception ignore) {}

//             String msg = 'Booking failed: ' + sc;
//             if (err != null && err.containsKey('message')) {
//                 msg = (String) err.get('message');
//             }
//             if (err != null && err.containsKey('errors')) {
//                 List<Object> errs = (List<Object>) err.get('errors');
//                 if (errs != null && !errs.isEmpty()) {
//                     List<String> parts = new List<String>();
//                     for (Object eObj : errs) {
//                         Map<String,Object> e = (Map<String,Object>) eObj;
//                         if (e != null && e.containsKey('message')) {
//                             parts.add((String)e.get('message'));
//                         }
//                     }
//                     if (!parts.isEmpty()) {
//                         msg += ': ' + String.join(parts, ' | ');
//                     }
//                 }
//             }
//             br.success = false;
//             br.message = msg;
//             return br;
//         }

//         // 204 (no content) – e.g. some award endpoints
//         if (sc == 204 || String.isBlank(resBody)) {
//             br.success    = true;
//             br.message    = 'Shipment booked successfully (no body returned).';
//             br.shipmentId = fvShipmentId;
//             br.status     = 'confirmed';
//             return br;
//         }

//         // ---------- Parse success body ----------
//         Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(resBody);

//         br.shipmentId = (String) resp.get('shipmentId');
//         br.status     = (String) resp.get('status');

//         if (resp.containsKey('tracking')) {
//             Map<String, Object> tr = (Map<String, Object>) resp.get('tracking');
//             br.trackingNumber = (String) tr.get('trackingNumber');
//         }

//         Map<String, Object> sel = (Map<String, Object>) resp.get('selectedQuote');
//         if (sel != null) {
//             br.carrier = (String) sel.get('assetCarrierName');
//             br.service = (String) sel.get('serviceDescription');

//             if (sel.containsKey('amount')) {
//                 br.amount = Decimal.valueOf(String.valueOf(sel.get('amount')));
//             }
//             br.currencyCode = (String) sel.get('currency');
//         }

//         br.success = true;
//         br.message = 'Shipment booked successfully.';
//         return br;

//     } catch (Exception e) {
//         br.success = false;
//         br.message = 'Error in bookFreightviewLtl: ' + e.getMessage();
//         return br;
//     }
// }
// version 2 
// private static BookingResult bookFreightviewLtl(
//     String fvShipmentId,
//     String quoteId,
//     Boolean schedulePickup,
//     Credentials__c cred,
//     String mode,
//     String logisticJson,
//     String fromContactJson,
//     String toContactJson,
//     String fromAddressJson,
//     String toAddressJson
// ) {
//     System.debug('in booking FV');
//     BookingResult br = new BookingResult();
//     br.success = false;

//     if (String.isBlank(fvShipmentId)) {
//         br.message = 'Missing FreightView shipmentId from quote.';
//         return br;
//     }
//     if (String.isBlank(quoteId)) {
//         br.message = 'Missing FreightView quoteId.';
//         return br;
//     }
//     if (cred == null) {
//         br.message = 'FreightView credentials not provided.';
//         return br;
//     }

//     try {
//         // ---------- Auth ----------
//         String token = freightView.getAccessToken(
//             cred.Username_Login__c,
//             cred.Password_Transkey__c,
//             cred.URL__c
//         );

//         // ---------- Mode ----------
//         String m = (mode == null ? '' : mode.trim().toLowerCase());
//         if (m != 'truckload' && m != 'parcel' && m != 'ltl') m = 'ltl';
//         Boolean isParcel    = (m == 'parcel');
//         Boolean isTruckload = (m == 'truckload');
//         Boolean isLTL       = (m == 'ltl');

//         String encId = EncodingUtil.urlEncode(fvShipmentId, 'UTF-8');

//         // ---------- Build endpoint ----------
//         String endpoint;
//         if (isTruckload) {
//             endpoint = cred.URL__c + '/v2.0/shipments/truckload/' + encId + '/award';
//         } else if (isParcel) {
//             endpoint = cred.URL__c + '/v2.0/shipments/parcel/' + encId + '/book';
//         } else {
//             // default LTL
//             endpoint = cred.URL__c + '/v2.0/shipments/ltl/' + encId + '/book';
//         }

//         Map<String,Object> body = new Map<String,Object>();
//         body.put('quoteId', quoteId);

//         if (isLTL) {
//             body.put('schedulePickup', (schedulePickup == null ? true : schedulePickup));
//         }

//         HttpRequest req = new HttpRequest();
//         req.setEndpoint(endpoint);
//         req.setMethod('POST');
//         req.setHeader('Content-Type', 'application/json');
//         req.setHeader('Authorization', 'Bearer ' + token);
//         req.setTimeout(30000);
//         req.setBody(JSON.serialize(body));

//         Http http = new Http();
//         HttpResponse res = http.send(req);
//         Integer sc = res.getStatusCode();
//         String resBody = res.getBody();
//         br.responseRaw = resBody;

//         System.debug('FreightView booking SC=' + sc + ' BODY=' + resBody);

//         // ---------- Error handling ----------
//         if (sc != 200 && sc != 201 && sc != 204) {
//             Map<String, Object> err = null;
//             try {
//                 err = (Map<String, Object>) JSON.deserializeUntyped(resBody);
//             } catch (Exception ignore) {}

//             String msg = 'Booking failed: ' + sc;
//             if (err != null && err.containsKey('message')) {
//                 msg = String.valueOf(err.get('message'));
//             }
//             if (err != null && err.containsKey('errors')) {
//                 List<Object> errs = (List<Object>) err.get('errors');
//                 if (errs != null && !errs.isEmpty()) {
//                     List<String> parts = new List<String>();
//                     for (Object eObj : errs) {
//                         Map<String,Object> e = (Map<String,Object>) eObj;
//                         if (e != null && e.containsKey('message')) {
//                             parts.add(String.valueOf(e.get('message')));
//                         }
//                     }
//                     if (!parts.isEmpty()) {
//                         msg += ': ' + String.join(parts, ' | ');
//                     }
//                 }
//             }
//             br.success = false;
//             br.message = msg;
//             return br;
//         }

//         // ---------- Success (200 / 201 / 204) ----------
//         if (sc == 200 || sc == 201 || sc == 204) {
//             Map<String,Object> resp = String.isBlank(resBody)
//                 ? new Map<String,Object>()
//                 : (Map<String,Object>) JSON.deserializeUntyped(resBody);

//             String shipmentId = (String) resp.get('shipmentId');
//             if (String.isBlank(shipmentId)) {
//                 // Fallback if not returned, at least store fvShipmentId
//                 shipmentId = fvShipmentId;
//             }

//             // --- Prepare Shipment Record ---
//             Shipment__c ship = new Shipment__c();
//             ship.RecordTypeId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName()
//                                     .get('freightview').getRecordTypeId();
//             ship.Active__c = true;
//             ship.Name = 'Shipment';
//             ship.shipmentID__c = shipmentId;
//             ship.Carrier_Code__c = 'FV';

//             // --- Parse logistics & address/contact JSON once ---
//             Logistic__c lg = (Logistic__c) JSON.deserialize(logisticJson, Logistic__c.class);

//             Map<String,Object> fromAddrMap = (Map<String,Object>) JSON.deserializeUntyped(fromAddressJson);
//             Map<String,Object> toAddrMap   = (Map<String,Object>) JSON.deserializeUntyped(toAddressJson);
//             Map<String,Object> fromConMap  = (Map<String,Object>) JSON.deserializeUntyped(fromContactJson);
//             Map<String,Object> toConMap    = (Map<String,Object>) JSON.deserializeUntyped(toContactJson);

//             Id fAId = (Id) fromAddrMap.get('Id');
//             Id tAId = (Id) toAddrMap.get('Id');
//             Id fCId = (Id) fromConMap.get('Id');
//             Id tCId = (Id) toConMap.get('Id');
//             Id custId = (Id) toAddrMap.get('Customer__c');
//             // --- Assign Logistics & Order & Customer ---
//             if (lg.Id != null)        ship.Logistic__c = lg.Id;
//             if (lg.Order_S__c != null) ship.Order__c   = lg.Order_S__c;

//             // Customer
//            // Id cust = (Id) JSON.deserializeUntyped(toContactJson).get('Id');
//             ship.Customer__c         = custId;
//             ship.Customer_Contact__c = tCId;
//             ship.Shipping_Address__c = tAId;

//             // --- Billing Options Logic (from Logistics) ---
//             String billingOpt = (lg.Billing_Options__c == null)
//                 ? 'SENDER'
//                 : lg.Billing_Options__c.toUpperCase();

//             if (billingOpt == 'SENDER' && fAId != null) {
//                 ship.Billing_Address__c = fAId;
//                 ship.Billing_Contact__c = fCId;
//             } else if (billingOpt == 'RECEIVER' && tAId != null) {
//                 ship.Billing_Address__c = tAId;
//                 ship.Billing_Contact__c = tCId;
//             }
//             // If you later want THIRD_PARTY, uncomment and adjust:
//             /*
//             else if (billingOpt == 'THIRD_PARTY') {
//                 ship.Billing_Address__c   = null;
//                 ship.Billing_Contact__c   = null;
//                 ship.Third_Party_Account__c = lg.Third_Party_Account__c;
//                 ship.Direction__c         = 'THIRD_PARTY';
//             }
//             */

//             // --- Read important metadata from API ---
//             if (resp.containsKey('pickupDate') && resp.get('pickupDate') != null) {
//                 // Example: "2027-07-02"
//                 ship.Shipment_Date__c = Date.valueOf(String.valueOf(resp.get('pickupDate')));
//             }
//             // if (resp.containsKey('bookedDate') && resp.get('bookedDate') != null) {
//             //     // Example: "2025-12-01T09:21:30.570Z" → use JSON engine to parse ISO
//             //     String bookedStr = String.valueOf(resp.get('bookedDate'));
//             //     ship.Booked_Date__c = (Datetime) JSON.deserialize(
//             //         '"' + bookedStr + '"',
//             //         Datetime.class
//             //     );
//             // }
//             if (resp.containsKey('status') && resp.get('status') != null) {
//                 ship.Status__c = String.valueOf(resp.get('status'));
//             }

//             // --- Read LTL weight and cost ---
//             // if (resp.containsKey('equipment') && resp.get('equipment') != null) {
//             //     Map<String,Object> eq = (Map<String,Object>) resp.get('equipment');
//             //     if (eq.containsKey('weight') && eq.get('weight') != null) {
//             //         ship.Shipment_Weight__c = Decimal.valueOf(String.valueOf(eq.get('weight')));
//             //     }
//             // }
//             Decimal amount = null;
//             String currencyFV;
//             String carrier;
//             String service;
//             if (resp.containsKey('selectedQuote') && resp.get('selectedQuote') != null) {
//                 Map<String,Object> q = (Map<String,Object>) resp.get('selectedQuote');

//                 if (q.containsKey('amount') && q.get('amount') != null){
//                     amount = Decimal.valueOf(String.valueOf(q.get('amount')));
//                 }
//                 ship.Shipping_Amount__c = amount;  
//                 currencyFV = q != null ? (String) q.get('currency') : null;
//                 carrier = q != null ? (String) q.get('assetCarrierName')   : null;
//                 service = q != null ? (String) q.get('serviceDescription') : null;
//                 ship.Carrier__c = carrier;
//                 ship.service_Description__c = service;
//                 // if (q.containsKey('assetCarrierName') && q.get('assetCarrierName') != null)
//                 //     ship.Carrier__c = String.valueOf(q.get('assetCarrierName'));
//                 // if (q.containsKey('serviceDescription') && q.get('serviceDescription') != null)
//                 //     ship.service_Description__c = String.valueOf(q.get('serviceDescription'));
//             }

//             // --- Tracking ---
//             // if (resp.containsKey('tracking') && resp.get('tracking') != null) {
//             //     Map<String,Object> t = (Map<String,Object>) resp.get('tracking');
//             //     if (t.containsKey('status') && t.get('status') != null) {
//             //         ship.Tracking_Status__c = String.valueOf(t.get('status'));
//             //     }
//             // }
//             String trackingNumber;
//                 if (resp.containsKey('tracking')) {
//                     Map<String, Object> tr = (Map<String, Object>) resp.get('tracking');
//                     trackingNumber = (String) tr.get('trackingNumber');
//                 }
//             br.trackingNumber = trackingNumber;
//             // --- BOL number (if/when you want it) ---
//             /*
//             if (resp.containsKey('bol') && resp.get('bol') != null) {
//                 Map<String,Object> b = (Map<String,Object>) resp.get('bol');
//                 if (b.containsKey('bolNumber') && b.get('bolNumber') != null) {
//                     ship.BOL_Number__c = String.valueOf(b.get('bolNumber'));
//                 }
//             }
//             */

//             // --- Finally upsert Shipment ---
//             upsert ship;
//              // Save docs (if any)
//                 List<String> titles = new List<String>();
//                 List<Id> docIds = new List<Id>();
//                 try {
//                     docIds = saveFreightviewDocs(resp,ship.Id, token, titles);
//                 } catch (Exception exDocs) {
//                     System.debug('Doc save error: ' + exDocs.getMessage());
//                 }
//                 // Doc type map for UI
//         Map<String, Id> byType = new Map<String, Id>();
//         for (Integer i = 0; i < titles.size(); i++) {
//             String t = (titles[i] == null ? '' : titles[i]).toLowerCase();
//             Id did = (docIds.size() > i ? docIds[i] : null);
//             if (t.endsWith('-bol') || t.endsWith('-bol.pdf') || t.contains('-bol'))             byType.put('bol', did);
//             else if (t.endsWith('-label') || t.endsWith('-label.pdf') || t.contains('-label')) byType.put('label', did);
//             else if (t.endsWith('-customer-quote') || t.contains('-customer-quote'))           byType.put('customer-quote', did);
//             else if (t.endsWith('-rate-detail')   || t.contains('-rate-detail'))               byType.put('rate-detail', did);
//         }
//             br.success   = true;
//             br.message   = 'Shipment booked successfully.';
//             br.shipmentId = shipmentId;
//             br.status    = 'confirmed';
//             br.amount = amount;
//             br.currencyCode          = currencyFV;
//             br.carrier               = carrier;
//             br.service               = service;
//             br.contentDocumentIds    = docIds;
//             br.contentTitles         = titles;
//             br.docByType             = byType;
//             return br;
//         }

//         // Fallback (should not reach here)
//         // br.success = false;
//         // br.message = 'Shipment booked successfully.';
//         // br.shipmentId = fvShipmentId;
//         // br.status = 'confirmed';
//         return br;

//     } catch (Exception e) {
//         br.success = false;
//         br.message = 'Error in bookFreightviewLtl: ' + e.getMessage();
//         return br;
//     }
// }
// version 3 
private static BookingResult bookFreightviewLtl(
    String fvShipmentId,
    String quoteId,
    Boolean schedulePickup,
    Credentials__c cred,
    String mode,
    String logisticJson,
    String fromContactJson,
    String toContactJson,
    String fromAddressJson,
    String toAddressJson
) {
    System.debug('in booking FV');
    BookingResult br = new BookingResult();
    br.success = false;

    if (String.isBlank(fvShipmentId)) {
        br.message = 'Missing FreightView shipmentId from quote.';
        return br;
    }
    if (String.isBlank(quoteId)) {
        br.message = 'Missing FreightView quoteId.';
        return br;
    }
    if (cred == null) {
        br.message = 'FreightView credentials not provided.';
        return br;
    }

    try {
        // ---------- Auth ----------
        String token = freightView.getAccessToken(
            cred.Username_Login__c,
            cred.Password_Transkey__c,
            cred.URL__c
        );

        // ---------- Mode ----------
        String m = (mode == null ? '' : mode.trim().toLowerCase());
        if (m != 'truckload' && m != 'parcel' && m != 'ltl') m = 'ltl';
        Boolean isParcel    = (m == 'parcel');
        Boolean isTruckload = (m == 'truckload');
        Boolean isLTL       = (m == 'ltl');

        String encId = EncodingUtil.urlEncode(fvShipmentId, 'UTF-8');

        // ---------- Build endpoint ----------
        String endpoint;
        if (isTruckload) {
            endpoint = cred.URL__c + '/v2.0/shipments/truckload/' + encId + '/award';
        } else if (isParcel) {
            endpoint = cred.URL__c + '/v2.0/shipments/parcel/' + encId + '/book';
        } else {
            // default LTL
            endpoint = cred.URL__c + '/v2.0/shipments/ltl/' + encId + '/book';
        }

        Map<String,Object> body = new Map<String,Object>();
        body.put('quoteId', quoteId);

        if (isLTL) {
            body.put('schedulePickup', (schedulePickup == null ? true : schedulePickup));
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setTimeout(30000);
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);
        Integer sc = res.getStatusCode();
        String resBody = res.getBody();
        br.responseRaw = resBody;

        System.debug('FreightView booking SC=' + sc + ' BODY=' + resBody);

        // ---------- Error handling ----------
        if (sc != 200 && sc != 201 && sc != 204) {
            Map<String, Object> err = null;
            try {
                err = (Map<String, Object>) JSON.deserializeUntyped(resBody);
            } catch (Exception ignore) {}

            String msg = 'Booking failed: ' + sc;
            if (err != null && err.containsKey('message')) {
                msg = String.valueOf(err.get('message'));
            }
            if (err != null && err.containsKey('errors')) {
                List<Object> errs = (List<Object>) err.get('errors');
                if (errs != null && !errs.isEmpty()) {
                    List<String> parts = new List<String>();
                    for (Object eObj : errs) {
                        Map<String,Object> e = (Map<String,Object>) eObj;
                        if (e != null && e.containsKey('message')) {
                            parts.add(String.valueOf(e.get('message')));
                        }
                    }
                    if (!parts.isEmpty()) {
                        msg += ': ' + String.join(parts, ' | ');
                    }
                }
            }
            br.success = false;
            br.message = msg;
            return br;
        }

        // ---------- Success (200 / 201 / 204) ----------
        if (sc == 200 || sc == 201 || sc == 204) {
            Map<String,Object> resp = String.isBlank(resBody)
                ? new Map<String,Object>()
                : (Map<String,Object>) JSON.deserializeUntyped(resBody);

            String shipmentId = (String) resp.get('shipmentId');
            if (String.isBlank(shipmentId)) {
                // Fallback if not returned, at least store fvShipmentId
                shipmentId = fvShipmentId;
            }

            // --- Prepare Shipment Record ---
            Shipment__c ship = new Shipment__c();
            ship.RecordTypeId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName()
                                    .get('freightview').getRecordTypeId();
            ship.Active__c = true;
            ship.Name = 'Shipment';
            ship.shipmentID__c = shipmentId;
            ship.Carrier_Code__c = 'FV';

            // --- Parse logistics & address/contact JSON once ---
            Logistic__c lg = (Logistic__c) JSON.deserialize(logisticJson, Logistic__c.class);

            Map<String,Object> fromAddrMap = (Map<String,Object>) JSON.deserializeUntyped(fromAddressJson);
            Map<String,Object> toAddrMap   = (Map<String,Object>) JSON.deserializeUntyped(toAddressJson);
            Map<String,Object> fromConMap  = (Map<String,Object>) JSON.deserializeUntyped(fromContactJson);
            Map<String,Object> toConMap    = (Map<String,Object>) JSON.deserializeUntyped(toContactJson);

            Id fAId = (Id) fromAddrMap.get('Id');
            Id tAId = (Id) toAddrMap.get('Id');
            Id fCId = (Id) fromConMap.get('Id');
            Id tCId = (Id) toConMap.get('Id');
            Id custId = (Id) toAddrMap.get('Customer__c');
            // --- Assign Logistics & Order & Customer ---
            if (lg.Id != null)        ship.Logistic__c = lg.Id;
            if (lg.Order_S__c != null) ship.Order__c   = lg.Order_S__c;

            // Customer
            ship.Customer__c         = custId;
            ship.Customer_Contact__c = tCId;
            ship.Shipping_Address__c = tAId;

            // --- Billing Options Logic (from Logistics) ---
            String billingOpt = (lg.Billing_Options__c == null)
                ? 'SENDER'
                : lg.Billing_Options__c.toUpperCase();

            if (billingOpt == 'SENDER' && fAId != null) {
                ship.Billing_Address__c = fAId;
                ship.Billing_Contact__c = fCId;
            } else if (billingOpt == 'RECEIVER' && tAId != null) {
                ship.Billing_Address__c = tAId;
                ship.Billing_Contact__c = tCId;
            }

            // --- Read important metadata from API ---
            if (resp.containsKey('pickupDate') && resp.get('pickupDate') != null) {
                // Example: "2027-07-02"
                ship.Shipment_Date__c = Date.valueOf(String.valueOf(resp.get('pickupDate')));
            }
            // if (resp.containsKey('bookedDate') && resp.get('bookedDate') != null) {
            //     // Example: "2025-12-01T09:21:30.570Z" → use JSON engine to parse ISO
            //     String bookedStr = String.valueOf(resp.get('bookedDate'));
            //     ship.Booked_Date__c = (Datetime) JSON.deserialize(
            //         '"' + bookedStr + '"',
            //         Datetime.class
            //     );
            // }
            if (resp.containsKey('status') && resp.get('status') != null) {
                ship.Status__c = String.valueOf(resp.get('status'));
            }
            Decimal amount = null;
            String currencyFV;
            String carrier;
            String service;
            if (resp.containsKey('selectedQuote') && resp.get('selectedQuote') != null) {
                Map<String,Object> q = (Map<String,Object>) resp.get('selectedQuote');

                if (q.containsKey('amount') && q.get('amount') != null){
                    amount = Decimal.valueOf(String.valueOf(q.get('amount')));
                }
                ship.Shipping_Amount__c = amount;  
                currencyFV = q != null ? (String) q.get('currency') : null;
                carrier = q != null ? (String) q.get('assetCarrierName')   : null;
                service = q != null ? (String) q.get('serviceDescription') : null;
                ship.Carrier__c = carrier;
                ship.service_Description__c = service;
            }
            ship.is_prebooked__c=true;
            ship.Shipment_Provider__c='FreightView';
            String trackingNumber;
                if (resp.containsKey('tracking')) {
                    Map<String, Object> tr = (Map<String, Object>) resp.get('tracking');
                    trackingNumber = (String) tr.get('trackingNumber');
                }
            br.trackingNumber = trackingNumber;
            // --- Finally upsert Shipment ---
            upsert ship;

            br.success   = true; br.message   = 'Shipment booked successfully.'; br.shipmentId = shipmentId; br.shipmentSalesforceId  = ship.Id; br.status    = 'confirmed'; br.provider = 'freightView'; br.amount = amount; br.currencyCode          = currencyFV; br.carrier               = carrier; br.service               = service; return br; } return br;

    } catch (Exception e) {
        br.success = false;
        br.message = 'Error in bookFreightviewLtl: ' + e.getMessage();
        return br;
    }
}

private class FvDocDownload {
    String title;
    String ext;
    Blob data;
    FvDocDownload(String t, String e, Blob b) { title = t; ext = e; data = b; }
}
private static Blob fvGetBlob(String downloadUrl, String bearerToken) { if (!String.isBlank(downloadUrl) && downloadUrl.endsWith('?')) { downloadUrl = downloadUrl.substring(0, downloadUrl.length()-1); } HttpRequest r = new HttpRequest(); r.setMethod('GET'); r.setEndpoint(downloadUrl); r.setHeader('Authorization', 'Bearer ' + bearerToken); r.setHeader('Accept', 'application/pdf'); r.setTimeout(30000); Http h = new Http(); HttpResponse resp = h.send(r); Integer sc = resp.getStatusCode(); if (sc == 200 || sc == 201) return resp.getBodyAsBlob(); if (sc == 429) { resp = h.send(r); if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) return resp.getBodyAsBlob(); } System.debug('Freightview doc GET failed: ' + sc + ' - ' + resp.getBody()); return null;
}

@AuraEnabled
public static BookingResult saveFreightviewDocs(
    String respRawJson,
    Id shipmentId,
    String username,
    String password,
    String url
) {
    BookingResult br = new BookingResult();
    br.success = false;

    System.debug('🚀 [FV DOC SAVE START] shipmentId=' + shipmentId);
    System.debug('📦 Incoming FV Response Raw=' + respRawJson);
    System.debug('🔑 FV Creds username=' + username + ' url=' + url);

    if (String.isBlank(respRawJson) || shipmentId == null || 
        String.isBlank(username) || String.isBlank(password) || String.isBlank(url)) {
        System.debug('❌ [FV DOC SAVE] Missing input – exiting early');
        br.message = 'Missing input for FreightView doc save.';
        return br;
    }

    try {
        // Get token using ONLY FV creds
        System.debug('🔐 Requesting FreightView Access Token...');
        String token = freightView.getAccessToken(username, password, url);
        System.debug('✅ Token received (length=' + (token != null ? token.length() : 0) + ')');

        // Parse booking API response
        Map<String,Object> resp = (Map<String,Object>) JSON.deserializeUntyped(respRawJson);
        System.debug('📄 Parsed Response Map Keys=' + (resp != null ? resp.keySet() : null));
      

        if (resp == null || !resp.containsKey('documents')) {
            System.debug('⚠️ [FV DOC SAVE] No "documents" key found in API response');
            br.message = 'No documents found in FreightView response.';
            return br;
        }

        List<Object> docs = (List<Object>) resp.get('documents');
        System.debug('📎 [FV DOC SAVE] Documents array size=' + (docs != null ? docs.size() : 0));

        List<String> titles = new List<String>();
        List<ContentVersion> cvs = new List<ContentVersion>();

        // Download docs in memory (CALL-OUT PHASE only)
        for (Integer i = 0; i < docs.size(); i++) {
            Map<String,Object> d = (Map<String,Object>) docs[i];
            String dlUrl = (String) d.get('downloadUrl');
            String type = (String) d.get('type');
            String fileName = (String) d.get('fileName');

            System.debug('➡️ [DOC ' + i + '] fileName=' + fileName + ' type=' + type + ' downloadUrl=' + dlUrl);

            if (String.isBlank(dlUrl)) {
                System.debug('⏭️ skipping – blank URL');
                continue;
            }

            if (!FV_DOC_TYPES.contains(fileName?.toLowerCase())) {
                System.debug('⏭️ skipping – not a wanted doc type');
                continue;
            }

            System.debug('⬇️ Downloading doc blob from FreightView...');
            Blob blobData = fvGetBlob(dlUrl, token);
            System.debug('🔎 blob received? ' + (blobData != null));

            if (blobData == null) {
                System.debug('⏭️ skipping – blob is null');
                continue;
            }

          //  String title = 'FV-' + fileName;
          // ✅ Get FreightView shipment Id from the booking API response
            String fvShip = String.valueOf(resp.get('shipmentId')); 

            // ✅ Decide type (bol or label) safely
            String docKey = '';
            if (fileName != null && fileName.toLowerCase().contains('bol'))      docKey = 'bol';
            else if (fileName != null && fileName.toLowerCase().contains('label')) docKey = 'label';
            else if (type != null && type.toLowerCase().contains('bol'))         docKey = 'bol';
            else if (type != null && type.toLowerCase().contains('label'))       docKey = 'label';
            else docKey = 'document';

            // ✅ Build exactly the format you want
            String title = 'FV-' + fvShip + '-' + docKey; 

            cvs.add(new ContentVersion(
                Title = title,
                PathOnClient = title + '.pdf',
                VersionData = blobData,
                IsMajorVersion = true,
                FirstPublishLocationId = shipmentId
            ));
            titles.add(title);
            System.debug('✅ [FV DOC SAVE] Queued for insert: ' + title);
        }

        System.debug('🧾 Total docs ready to insert=' + cvs.size()); if (!cvs.isEmpty()) { System.debug('💾 Inserting ContentVersion records...'); insert cvs; System.debug('🎉 [FV DOC SAVE SUCCESS] Insert completed'); Set<Id> cdIds = new Set<Id>(); for (ContentVersion cv : cvs) { if (cv.ContentDocumentId != null) { cdIds.add(cv.ContentDocumentId); } } System.debug('📁 Collected ContentDocumentIds=' + cdIds); br.contentDocumentIds = new List<Id>(cdIds); br.contentTitles = titles; br.message = 'Documents saved successfully to Shipment.'; br.success = true; } else { System.debug('⚠️ [FV DOC SAVE] No docs were downloaded – nothing to save'); br.message = 'No docs downloaded from FreightView.'; return br; } System.debug('🏁 [FV DOC SAVE END] Final docIds returned=' + br.contentDocumentIds);
        return br;

    } catch (Exception e) {
        System.debug('🔥 [FV DOC SAVE ERROR]=' + e.getMessage());
        br.message = 'Doc save error: ' + e.getMessage();
        br.success = false;
        return br;
    }
}


  
    public class SelectOptionWrapper {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        public SelectOptionWrapper(String v, String l){
            value = v;
            label = l;
        }
    }

    public class FetchInitWrapper {
        @AuraEnabled public List<SelectOptionWrapper> dimensionOptions = new List<SelectOptionWrapper>();
        @AuraEnabled public List<SelectOptionWrapper> weightUnitOptions = new List<SelectOptionWrapper>();
        @AuraEnabled public List<SelectOptionWrapper> freightClassOptions = new List<SelectOptionWrapper>();
        @AuraEnabled public List<SelectOptionWrapper> hazardClassOptions = new List<SelectOptionWrapper>();
        @AuraEnabled public List<SelectOptionWrapper> packagingGroupOptions = new List<SelectOptionWrapper>();

        @AuraEnabled public Map<String, Credentials__c> credentialsMap = new Map<String, Credentials__c>();
    }
    public class quoteWrapper {
    @AuraEnabled public String provider;
    @AuraEnabled public String carrier;
    @AuraEnabled public String service;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currencyQ;
    @AuraEnabled public String quoteId;
    @AuraEnabled public Boolean shipmentCreated;
    @AuraEnabled public String shipmentId;

}

public class RateResponseLTL {
    @AuraEnabled public List<quoteWrapper> quotesFedex;
    @AuraEnabled public List<quoteWrapper> quotesUPS;
    @AuraEnabled public List<quoteWrapper> quotesFreightView;
    @AuraEnabled public List<String> missingCredentials;
}
public class PackageInputWrapper {
    @AuraEnabled public Integer id;
    @AuraEnabled public Integer Quantity;
    @AuraEnabled public String FVPackageType;
    @AuraEnabled public Decimal Weight;
    @AuraEnabled public Decimal Length;
    @AuraEnabled public Decimal Width;
    @AuraEnabled public Decimal Height;
    @AuraEnabled public String WeightUnit;
    @AuraEnabled public String DimensionUnit;
    @AuraEnabled public String FreightClass;
    @AuraEnabled public Boolean isHazmat;
    @AuraEnabled public String HazmatID;
    @AuraEnabled public String HazardClass;
    @AuraEnabled public String PackagingGroup;
    @AuraEnabled public String DeclaredValue;
    @AuraEnabled public String NMFCCode;
}
public class BookingResult {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String  message;
    @AuraEnabled public String  shipmentId;
    @AuraEnabled public String  shipmentSalesforceId ;
    @AuraEnabled public String  status;
    @AuraEnabled public String  trackingNumber;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String  currencyCode;
    @AuraEnabled public String  carrier;
    @AuraEnabled public String  provider;
    @AuraEnabled public String  service;
    @AuraEnabled public String  responseRaw;
      @AuraEnabled public List<Id> contentDocumentIds;
    @AuraEnabled public List<String> contentTitles;
      @AuraEnabled public Map<String, Id> docByType;
       
}

public class ProductStockSummary {
        @AuraEnabled public Id      productId;
        @AuraEnabled public Decimal totalQty;

        public ProductStockSummary(Id productId, Decimal totalQty) {
            this.productId = productId;
            this.totalQty  = totalQty;
        }
    }
// for order to logistic here 
// @AuraEnabled(cacheable=true)
// public static Map<String, Object> getOrderAndItemsAnalysis(Id orderId) {

//     Map<String, Object> out = new Map<String, Object>();

//     String orderQuery = 'SELECT ' + UtilClass.selectStarFromSObject('Order') + 
//                        ' FROM Order WHERE Id = :orderId';
//     SObject orderRec = Database.query(orderQuery);
//     out.put('order', orderRec);

//    String itemQuery = 'SELECT ' + UtilClass.selectStarFromSObject('OrderItem') +
//                    ', Product2.Name FROM OrderItem WHERE OrderId = :orderId';
//     List<SObject> itemRecs = Database.query(itemQuery);

//     List<Map<String, Object>> analysis = new List<Map<String, Object>>();
//     Set<Id> ProductIds = new Set<Id>();
//     for (SObject s : itemRecs) {
//         Decimal qty  = (Decimal) s.get('Quantity');
//         Decimal logQ = s.get('Logistic_Quantity__c') == null ? 0 : (Decimal)s.get('Logistic_Quantity__c');
//         Decimal rem  = qty - logQ;

//         Map<String, Object> row = new Map<String, Object>();
//         row.put('record', s);
//         productIds.add((Id)s.get('Product2Id'));
//         row.put('remainingQty', rem);
//         analysis.add(row);
//     }

//     out.put('items', analysis);

//     return out;
// }
@AuraEnabled(cacheable=true)
public static Map<String, Object> getOrderAndDcDetails(Id orderId,  Id dcId) {

    Map<String, Object> out = new Map<String, Object>(); String orderQuery = 'SELECT ' + UtilClass.selectStarFromSObject('Order') + ' , Channel__r.Id, Channel__r.Name,Contact__r.Id,Contact__r.Name,Ship_To_Address__r.Id,Ship_To_Address__r.Name,Account.Name FROM Order WHERE Id = :orderId'; SObject orderRec = Database.query(orderQuery); out.put('order', orderRec); String itemQuery = 'SELECT ' + UtilClass.selectStarFromSObject('OrderItem') + ', Product2.Id, Product2.Name FROM OrderItem WHERE OrderId = :orderId'; List<SObject> itemRecs = Database.query(itemQuery); List<Map<String, Object>> analysis = new List<Map<String, Object>>(); Set<Id> productIds = new Set<Id>(); for (SObject s : itemRecs) { Decimal qty  = (Decimal)s.get('Quantity'); Decimal logQ = s.get('Logistic_Quantity__c') == null ? 0 : (Decimal)s.get('Logistic_Quantity__c'); Decimal rem  = qty - logQ; Map<String, Object> row = new Map<String, Object>(); row.put('record', s); row.put('remainingQty', rem); row.put('totalQty', qty); row.put('logisticQty', logQ); analysis.add(row); productIds.add((Id)s.get('Product2Id')); } out.put('items', analysis); if (dcId != null) { Distribution_Channel__c topDC = [ SELECT Id, Name, Priority__c, Site__c, Site__r.Name,Active__c, Site__r.Address__c, Site__r.Address__r.Name, Site__r.Primary_Contact__c, Site__r.Primary_Contact__r.Name, Site__r.Address__r.City__c, Site__r.Address__r.State__c, Site__r.Address__r.Country__c FROM Distribution_Channel__c WHERE Id = :dcId ORDER BY Priority__c ASC LIMIT 1 ]; if (topDC != null) { Map<String, Object> dcMap = new Map<String, Object>{ 'Id' => topDC.Id, 'Name' => topDC.Name, 'Priority__c' => topDC.Priority__c, 'Active__c' => topDC.Active__c }; dcMap.put('Site', new Map<String, Object>{ 'siteId' => topDC.Site__c, 'siteName' => topDC.Site__r?.Name, 'siteAddressId' => topDC.Site__r?.Address__c, 'siteAddressName' => topDC.Site__r?.Address__r?.Name, 'sitePrimaryContactId' => topDC.Site__r?.Primary_Contact__c, 'sitePrimaryContactName' => topDC.Site__r?.Primary_Contact__r?.Name }); out.put('distributionChannel', dcMap); } } List<Logistic__c> logisticRecs = [ SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Contact__r.Name, From_Contact__c, From_Contact__r.Name, To_Address__c, To_Address__r.Name, From_Address__c, From_Address__r.Name FROM Logistic__c WHERE Order_S__c = :orderId ]; out.put('logistics', logisticRecs); return out;
}



@AuraEnabled(cacheable=true)
public static Map<String, Object> getOrderAndItemsAnalysis(Id orderId) {

    Map<String, Object> out = new Map<String, Object>(); String orderQuery = 'SELECT ' + UtilClass.selectStarFromSObject('Order') + ' , Channel__r.Id, Channel__r.Name,Contact__r.Id,Contact__r.Name,Ship_To_Address__r.Id,Ship_To_Address__r.Name,Account.Name FROM Order WHERE Id = :orderId'; SObject orderRec = Database.query(orderQuery); out.put('order', orderRec); String itemQuery = 'SELECT ' + UtilClass.selectStarFromSObject('OrderItem') + ', Product2.Id, Product2.Name FROM OrderItem WHERE OrderId = :orderId'; List<SObject> itemRecs = Database.query(itemQuery); List<Map<String, Object>> analysis = new List<Map<String, Object>>(); Set<Id> productIds = new Set<Id>(); for (SObject s : itemRecs) { Decimal qty  = (Decimal)s.get('Quantity'); Decimal logQ = s.get('Logistic_Quantity__c') == null ? 0 : (Decimal)s.get('Logistic_Quantity__c'); Decimal rem  = qty - logQ; Map<String, Object> row = new Map<String, Object>(); row.put('record', s); row.put('remainingQty', rem); row.put('totalQty', qty); row.put('logisticQty', logQ); analysis.add(row); productIds.add((Id)s.get('Product2Id')); } out.put('items', analysis); Id chId = (Id)orderRec.get('Channel__c'); if (chId != null) { Distribution_Channel__c topDC = [ SELECT Id, Name, Priority__c, Site__c, Site__r.Name,Active__c, Site__r.Address__c, Site__r.Address__r.Name, Site__r.Primary_Contact__c, Site__r.Primary_Contact__r.Name, Site__r.Address__r.City__c, Site__r.Address__r.State__c, Site__r.Address__r.Country__c FROM Distribution_Channel__c WHERE Channel__c = :chId ORDER BY Priority__c ASC LIMIT 1 ]; if (topDC != null) { Map<String, Object> dcMap = new Map<String, Object>{ 'Id' => topDC.Id, 'Name' => topDC.Name, 'Priority__c' => topDC.Priority__c, 'Active__c' => topDC.Active__c }; dcMap.put('Site', new Map<String, Object>{ 'siteId' => topDC.Site__c, 'siteName' => topDC.Site__r?.Name, 'siteAddressId' => topDC.Site__r?.Address__c, 'siteAddressName' => topDC.Site__r?.Address__r?.Name, 'sitePrimaryContactId' => topDC.Site__r?.Primary_Contact__c, 'sitePrimaryContactName' => topDC.Site__r?.Primary_Contact__r?.Name }); out.put('distributionChannel', dcMap); } } List<Logistic__c> logisticRecs = [ SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Contact__r.Name, From_Contact__c, From_Contact__r.Name, To_Address__c, To_Address__r.Name, From_Address__c, From_Address__r.Name FROM Logistic__c WHERE Order_S__c = :orderId ]; out.put('logistics', logisticRecs); Integer logisticCount = [SELECT COUNT() FROM Logistic__c WHERE Order_S__c = :orderId]; String orderNum = (String)orderRec.get('OrderNumber'); String newLogisticName = orderNum + '-Logistic-' + String.valueOf(logisticCount + 1); out.put('newLogisticName', newLogisticName); return out;
}
    
// abuzar
@AuraEnabled(cacheable=true)
 public static Map<Id, ProductStockSummary> getTotalStockPerProduct( List<Id> productIds, String channel, String distributionChannel ) { System.debug('productIds --> '+productIds); System.debug('channel --> '+channel); System.debug('distributionChannel --> '+distributionChannel); Map<Id, ProductStockSummary> result = new Map<Id, ProductStockSummary>(); if (productIds == null || productIds.isEmpty() || String.isBlank(distributionChannel)) { return result; } Id dcId; try { dcId = (Id)distributionChannel; } catch (Exception e) { return result; } Distribution_Channel__c dc = [ SELECT Id, Site__c FROM Distribution_Channel__c WHERE Id = :dcId LIMIT 1 ]; if (dc.Site__c == null) { return result; } Id siteId = dc.Site__c; System.debug('SiteId: ' + siteId); String soql = 'SELECT Product__c productId,' + '       SUM(Number_of_Item_In_Stock__c) totalQty' + '  FROM Inventory_Stock__c' + ' WHERE Product__c IN :productIds' + '   AND Active__c = true' + '   AND Number_of_Item_In_Stock__c >= 0' + '   AND Name NOT IN (\'Awaiting Stock\', \'Serial Stock Holder\')' + '   AND Warehouse__c = :siteId' + ' GROUP BY Product__c'; List<AggregateResult> ars = Database.query(soql); for (AggregateResult ar : ars) { Id      productId = (Id)ar.get('productId'); Decimal totalQty  = (Decimal)ar.get('totalQty'); result.put(productId, new ProductStockSummary(productId, totalQty)); } for (Id pId : productIds) { if (!result.containsKey(pId)) { result.put(pId, new ProductStockSummary(pId, 0)); } } return result; } public class Result { @AuraEnabled public Logistic__c logistic { get; set; } @AuraEnabled public String message   { get; set; } } @AuraEnabled public static Result getCreateLogistics(String LogisticJSON, String LLIListJSON,String OrderLIneItems,String BomItems){ Result res = new Result(); res.logistic = new Logistic__c(); res.message = ''; try{ system.debug('getCreateLogistic called'); list<OrderItem> Orditem = (OrderLIneItems != null && OrderLIneItems != '') ? (list<OrderItem>) JSON.deserialize(OrderLIneItems, list<OrderItem> .class) : new list<OrderItem>(); list<BOM_Line_Item__c> bomitem = (BomItems != null && BomItems != '') ? (list<BOM_Line_Item__c>) JSON.deserialize(BomItems, list<BOM_Line_Item__c> .class) : new list<BOM_Line_Item__c>(); Id rTpe_MRPKIT; rTpe_MRPKIT = Schema.SObjectType.MRP__c.getRecordTypeInfosByDeveloperName().get('MRP_Kit').getRecordTypeId(); list<MRP__c> MRPS2Insert = new list<MRP__c>(); map<string,MRP__c> MRPmap = new map<string,MRP__c>(); PreventRecursiveLedgerEntry.testCasesTransactions = true; for(OrderItem orditm:Orditem){ if(orditm.Product2.Is_Kit__c){ for(BOM_Line_Item__c bom:bomitem){ MRP__c MRP = new MRP__c(); } } } upsert MRPS2Insert; system.debug('inside MRP Creation1-->:'); for(MRP__c Mrp :MRPS2Insert){ MRPmap.put(Mrp.MRP_Product__c,Mrp); } system.debug('MRPmap:-->'+MRPmap); Logistic__c Logistic = (Logistic__c) JSON.deserialize(LogisticJSON, Logistic__c .class); system.debug('Logistic : '+Logistic.Shipping_Preferences__c); System.debug('Logistic Order : '+Logistic.Order_S__c); Id orderId = Logistic.Order_S__c; String SORecTypeId=''; if(String.isNotEmpty(Logistic.Order_S__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Order'); if(String.isNotEmpty(Logistic.Purchase_Order__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order'); Logistic.RecordTypeId = SORecTypeId; system.debug('RecordTypeId : '+Logistic.RecordTypeId); list<Logistic_Line_Item__c> LogisticLI = (list<Logistic_Line_Item__c>) JSON.deserialize(LLIListJSON, list<Logistic_Line_Item__c> .class); List<Logistic_Line_Item__c> typeLogisticLI = new List<Logistic_Line_Item__c>(); set<String> proList=new set<String>(); set<Id> OrderProdIds=new set<Id>(); Map<String,Decimal> prodRequestedQtyMap = new Map<String,Decimal>(); Map<String,Decimal> OrderRequestedQtyMap = new Map<String,Decimal>(); for(Logistic_Line_Item__c log :LogisticLI){ if(log.Product__c != null && !proList.contains(log.Product__c)){ proList.add(log.Product__c); prodRequestedQtyMap.put(log.Product__c,log.Quantity__c); } if(log.Order_Product__c != null) { OrderProdIds.add(log.Order_Product__c); OrderRequestedQtyMap.put(log.Order_Product__c,log.Quantity__c); } } if (OrderProdIds.size() > 0) { List<OrderItem> ordItemsList = [SELECT Id, OrderItemNumber, Quantity, Is_Kit__c, Logistic_Quantity__c FROM OrderItem WHERE Id IN :OrderProdIds]; for (OrderItem ord : ordItemsList) { if (!ord.Is_Kit__c && OrderRequestedQtyMap.containsKey(ord.Id)) { Decimal logQty = OrderRequestedQtyMap.get(ord.Id); system.debug('logQty : '+logQty); if ((logQty + ord.Logistic_Quantity__c) > ord.Quantity) { res.message = 'Logistic cannot be created for more than order quantity'; return res; } } } } List<Product2> proList1 = [Select Id,Name,Serialise__c,Lot_Tracked__c,Track_Inventory__c from Product2 where Id In:proList]; Map<String,String> proName=new Map<String,String>(); Map<String,Boolean> proSerial=new Map<String,Boolean>(); for(Product2 pr:proList1){ proName.put(pr.Id,pr.Name); proSerial.put(pr.Id,pr.Serialise__c); } Distribution_Channel__c dc = [Select Id,Name,Site__c from Distribution_Channel__c where Id=:Logistic.Distribution_Channel__c Limit 1]; List<Manufacturing_Order__c> SOMOs = new List<Manufacturing_Order__c>(); List<PO__c> SOPOs = new List<PO__c>(); List<Inventory_Stock__c> invtoryList = new List<Inventory_Stock__c>(); List<Inventory_Stock__c> MOPOinvtoryList = new List<Inventory_Stock__c>(); system.debug('orderId~>'+orderId); if(orderId != null && OrderProdIds.size() > 0 && proList.size() > 0){ SOMOs = [Select Id,Name from Manufacturing_Order__c where (Order_Product__c IN:OrderProdIds and Order__c =:orderId) and Product__c IN:proList]; System.debug('SOMOs : '+SOMOs.size()); SOPOs = [Select Id,Name from PO__c where Order__c =:orderId and Ready_To_Receive__c =:true]; System.debug('SOPOs : '+SOPOs.size()); } Map<String,List<Inventory_Stock__c>> proInvMap = new Map<String,List<Inventory_Stock__c>>(); Map<String,Decimal> prodStockQtyMap = new Map<String,Decimal>(); if(SOMOs.size() > 0 || SOPOs.size() > 0){ set<Id> MoIds = new set<Id>();set<Id> PoIds = new set<Id>(); set<Id> InvIds = new set<Id>(); for(Manufacturing_Order__c MO : SOMOs) MoIds.add(MO.Id); for(PO__c PO : SOPOs) PoIds.add(PO.Id); system.debug('MoIds ~>'+MoIds); List<Stock_Inward_Line_Item__c> stinlist = [Select Id,Name,Product__c,Site_ProductService_InventoryStock__c from Stock_Inward_Line_Item__c  where Active__c = true and Product__c IN :proList and Scrap__c = false AND (Purchase_Orders__c IN:PoIds or Manufacturing_Order__c IN: MoIds) AND Quantity__c > 0 AND Status__c != 'Awaiting Stock']; for(Stock_Inward_Line_Item__c sin : stinlist) InvIds.add(sin.Site_ProductService_InventoryStock__c); system.debug('MoIds InvIds ~>'+InvIds); MOPOinvtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where product__c != null and Product__c In:proList And Active__c = true And Warehouse__c =:dc.Site__c AND Id IN:InvIds AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 Order By Checked_In_Date__c ASC]; system.debug('MOPOinvtoryList~>'+MOPOinvtoryList.size()); for(Inventory_Stock__c invt:MOPOinvtoryList){ List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>(); if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c);  invlistformap.add(invt); proInvMap.put(invt.Product__c,invlistformap); } for(String key: proInvMap.keyset()){ Decimal Qty = 0;  for(Inventory_Stock__c inv : proInvMap.get(key)){ Qty = Qty + inv.Number_of_Item_In_Stock__c;  } prodStockQtyMap.put(key,Qty); } } Boolean checkInventoryList = false; for(String key : prodRequestedQtyMap.keyset()){ if(prodStockQtyMap.containsKey(key)){ system.debug('prodStockQtyMap.get(key) first check~>'+prodStockQtyMap.get(key));  if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){checkInventoryList = true; break; } }else{ checkInventoryList = true; break; } } system.debug('checkInventoryList~>'+checkInventoryList); if(checkInventoryList){ system.debug('MOPOinvtoryList size~>'+MOPOinvtoryList.size()); if(MOPOinvtoryList.size() > 0){ invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c  AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 AND Id NOT IN:MOPOinvtoryList ORDER BY Checked_In_Date__c ASC]; }else{ invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 ORDER BY Checked_In_Date__c ASC]; } for(Inventory_Stock__c invt:invtoryList){ List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>(); if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c); invlistformap.add(invt); proInvMap.put(invt.Product__c,invlistformap); } for(String key: proInvMap.keyset()){ Decimal Qty = 0; for(Inventory_Stock__c inv : proInvMap.get(key)){ Qty = Qty + inv.Number_of_Item_In_Stock__c; } Decimal totalQty = 0; if(prodStockQtyMap.containsKey(key)) totalQty = prodStockQtyMap.get(key); totalQty = totalQty + Qty; prodStockQtyMap.put(key,totalQty); } } if(!String.isNotEmpty(Logistic.Purchase_Order__c)){ for(String key : prodRequestedQtyMap.keyset()){ if(prodStockQtyMap.containsKey(key)){ if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){ res.message = 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site'; return res; } }else{ res.message = 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site'; return res; } } } if(String.isNotEmpty(Logistic.Order_S__c)){ Order SalOrder=new Order(); SalOrder=[SELECT Id, Name, Channel__c, Channel__r.Ship_From_Address__c,Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c FROM Order WHERE Id=:Logistic.Order_S__c]; if(SalOrder.Channel__c != null){ if(Logistic.From_Address__c == null && SalOrder.Channel__r.Ship_From_Address__c != null){Logistic.From_Address__c = SalOrder.Channel__r.Ship_From_Address__c; } } if(Logistic.Shipment_Type__c == null || Logistic.Shipment_Type__c == '') Logistic.Shipment_Type__c = SalOrder.Shipment_Type__c; system.debug('Logistic.Shipment_Type__c : '+Logistic.Shipment_Type__c); } else if(String.isNotEmpty(Logistic.Purchase_Order__c)){String PORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order'); Logistic.RecordTypeId = PORecTypeId; } if(Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable()){ if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){ upsert Logistic; } } else{ res.message = 'Don\'t have access to upsert logistic'; return res;  } list<String> SOLIIds=new list<String>(); list<String> ordItemIds=new list<String>(); list<String> POItemIds=new list<String>(); for(Logistic_Line_Item__c log:LogisticLI){ String Name = log.Name; if(Name.length() > 80) log.Name = Name.subString(0,79); log.Status__c = 'Reserved'; log.Logistic__c = Logistic.Id; if(log.Order_Product__c !=null) ordItemIds.add(log.Order_Product__c); if(log.Purchase_Line_Items__c !=null) POItemIds.add(log.Purchase_Line_Items__c); } if(LogisticLI.size() > 0){ if(Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable()){ List<SObject> safeLogisticLI = FLSHelper.getSafeRecords( LogisticLI, 'Logistic_Line_Item__c', AccessType.UPDATABLE ); for (SObject s : safeLogisticLI) { typeLogisticLI.add((Logistic_Line_Item__c)s); } if (!typeLogisticLI.isEmpty()) { upsert typeLogisticLI; } } else{ res.message = 'Don\'t have access to upsert logistic line items'; return res;} } List<Stock_Outward_Line_Item__c> SWLIToUpsert = new List<Stock_Outward_Line_Item__c>(); Map<Id, Inventory_Stock__c> pliStock = new Map<Id, Inventory_Stock__c>(); Map<Id, Stock_Outward_Line_Item__c> pliStockInward = new Map<Id, Stock_Outward_Line_Item__c>(); List<Inventory_Stock__c> Inventory2Upsert = new List<Inventory_Stock__c>(); for(Logistic_Line_Item__c log:typeLogisticLI){if(log.Product__c != null && log.Quantity__c > 0 && ((Logistic.Order_S__c != null && log.Order_Product__c != null))){if(Logistic.Purchase_Order__c == null && proInvMap.containsKey(log.Product__c) && proSerial.containsKey(log.Product__c)){ Decimal remainintQty = log.Quantity__c; for(Inventory_Stock__c inv : proInvMap.get(log.Product__c)){ if(remainintQty > 0){ Decimal qtytoprocess = 0; if(proSerial.get(log.Product__c)){ Inventory_Stock__c inv2Create = new Inventory_Stock__c(Active__c = true, Product__c = log.Product__c, Name = 'Serial Stock Holder', Warehouse__c = dc.Site__c);Inventory2Upsert.add(inv2Create); system.debug('inhere serial'); qtytoprocess = 0; Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = 'Serial Stock Holder';  sto.Product__c = log.Product__c;   sto.Active__c = true;  sto.Status__c = 'Reserved'; if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c; if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c; sto.Logistic_Line_Item__c = log.Id; sto.Quantity__c = remainintQty; SWLIToUpsert.add(sto); pliStock.put(log.Id,inv2Create);pliStockInward.put(log.Id,sto); remainintQty = 0; system.debug('qtytoprocess~>'+qtytoprocess); system.debug('remainintQty~>'+remainintQty); } else{ system.debug('inhere non serial inv.Number_of_Item_In_Stock__c~>'+inv.Number_of_Item_In_Stock__c); if(inv.Number_of_Item_In_Stock__c < remainintQty){ system.debug('inhere inv.Number_of_Item_In_Stock__c < remainintQty'); qtytoprocess = inv.Number_of_Item_In_Stock__c; remainintQty = remainintQty - inv.Number_of_Item_In_Stock__c; }else{ system.debug('inhere else inv.Number_of_Item_In_Stock__c >= remainintQty'); qtytoprocess = remainintQty; remainintQty = remainintQty - qtytoprocess; } system.debug('qtytoprocess~>'+qtytoprocess); system.debug('remainintQty~>'+remainintQty); } if(qtytoprocess > 0){ Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = log.Name; if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c;  if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c; sto.Product__c = log.Product__c;  sto.Active__c = true;  sto.Status__c = 'Reserved'; if(proSerial.get(log.Product__c)) sto.Quantity__c = 1; else sto.Quantity__c = qtytoprocess; system.debug('inv.Id for stock outward~>'+inv.Id); sto.Site_Product_Service_Inventory_Stock__c = inv.Id; system.debug('log.Id for stock outward~>'+log.Id); sto.Logistic_Line_Item__c = log.Id; if(MRPmap.containsKey(log.Product__c)) sto.MRP_Material_Requirements_Planning__c = MRPmap.get(log.Product__c).Id; system.debug('inv.Serial__c~>'+inv.Serial__c); if(inv.Serial__c != null) sto.Serial__c = inv.Serial__c; if(inv.Batch_Lot__c != null) sto.Material_Batch_Lot__c = inv.Batch_Lot__c; SWLIToUpsert.add(sto); } } } } } } system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size()); if(Inventory2Upsert.size() > 0) insert Inventory2Upsert; for(Id pliId : pliStockInward.KeySet()){ pliStockInward.get(pliId).Site_Product_Service_Inventory_Stock__c= pliStock.get(pliId).Id; } if(SWLIToUpsert.size() > 0){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()) { system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size()); upsert SWLIToUpsert;   for(Stock_Outward_Line_Item__c soli : SWLIToUpsert) { System.debug('Upserted SOLI ID: ' + soli.Id); }}  else{ res.message = 'Don\'t have access to upsert Stock Outward'; return res; } } if(POItemIds.size() > 0){ list<Logistic_Line_Item__c> LogLIList=new list<Logistic_Line_Item__c>(); LogLIList=[SELECT Id, Name, Quantity__c, Purchase_Line_Items__c FROM Logistic_Line_Item__c WHERE Purchase_Line_Items__c IN:POItemIds]; list<Purchase_Line_Items__c> poliItems2Update = new List<Purchase_Line_Items__c>(); for(Purchase_Line_Items__c poli:[SELECT Id, Logistic_Quantity__c FROM Purchase_Line_Items__c WHERE Id IN:POItemIds]){ Decimal LogQuantity=0; for(Logistic_Line_Item__c logLi:LogLIList) { if(logLi.Purchase_Line_Items__c==poli.Id) LogQuantity+=logLi.Quantity__c; } if(Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isUpdateable()) poli.Logistic_Quantity__c=LogQuantity; poliItems2Update.add(poli); } try{  if(poliItems2Update.size() > 0 && Schema.sObjectType.Purchase_Line_Items__c.isUpdateable())  { update poliItems2Update; } else{ res.message = 'User is not allowed to update POLI'; return res; } }catch(DMLException e){ res.message = 'DML Exception on PO Line Items update: '+ e.getMessage() +','+e.getStackTraceString(); return res;} } res.message = 'Logistic created successfully'; res.logistic = Logistic; return res; }catch(Exception e){ System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString()); } }

    @AuraEnabled(cacheable=true)
    public static Boolean getShipmentDetails(Id logisticId) {
        if (logisticId == null) { return false; } return [ SELECT COUNT() FROM Shipment__c WHERE Logistic__c = :logisticId ] > 0; }
}