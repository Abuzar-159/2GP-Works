public with sharing class freightView {
    private static final Set<String> FV_DOC_TYPES = new Set<String>{ 'bol', 'label', 'label-pdf' };
  @AuraEnabled(cacheable=true)
    public static String getContactPhone(Id contactId) {
        if(contactId == null) return null;
        Contact c = [SELECT Phone FROM Contact WHERE Id = :contactId LIMIT 1];
        return c.Phone;
    }	
       @AuraEnabled
public static shipmentResponse shippingRequestResponse(
    List<Package__c> packList,
    String fromAddress,
    String toAddress,
    String fromContact,
    String toContact,
    String ShipDateStamp,
    String myConsVar,
    String Shipment,
    List<Package_List__c> packageItems,
    String masterShipmentId
){
    shipmentResponse res = new shipmentResponse();

    // Deserialize shipment & contacts
    Shipment__c ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
    System.debug('ship=>'+ship);
    contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);
    contact shipToContact  = (Contact) JSON.deserialize(toContact, Contact.class);
    String toCountryCode = '';String toProvinceCode = '';String FromCountryCode = '';String FromProvinceCode = '';
    Address__c tAddress = new  Address__c();
    if(String.isNotEmpty(toAddress)) {
            tAddress = (Address__c) JSON.deserialize(toAddress,Address__c.class);
            toCountryCode = getCountryCode(tAddress.Country__c);
            toProvinceCode =getProvinceCode(tAddress.State__c);
        }
        Address__c fAddress = new  Address__c();
        if(String.isNotEmpty(fromAddress)) {
            fAddress = (Address__c) JSON.deserialize(fromAddress,Address__c.class);
            FromCountryCode = getCountryCode(fAddress.Country__c);
            FromProvinceCode =getProvinceCode(fAddress.State__c);
        }
    // Prepare authentication
    myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
    System.debug('MCW.childkey'+ MCW.childpassword);
    String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);
    

    // Prepare shipment payload
    Map<String, Object> payload = new Map<String, Object>();
    payload.put('pickupDate', ShipDateStamp);

    // Origin
    Map<String, Object> origin = new Map<String, Object>();
   		String originCompany;
        if (shipFromContact != null && shipFromContact.Company__r != null && !String.isBlank(shipFromContact.Company__r.Name)) {
            originCompany = shipFromContact.Company__r.Name;
        } else if (fAddress != null && fAddress.Customer__r != null && !String.isBlank(fAddress.Customer__r.Company_txt__c)) {
            originCompany = fAddress.Customer__r.Company_txt__c;
        } else if (shipFromContact != null && shipFromContact.Account != null && !String.isBlank(shipFromContact.Account.Name)) {
            originCompany = shipFromContact.Account.Name;
        }
    origin.put('company', originCompany);
    //origin.put('company', fAddress.Company__c != null ? fAddress.Company__r.Name : shipFromContact.Account.Name);
    origin.put('address', fAddress.Name);
    origin.put('city', fAddress.City__c);
    origin.put('state', FromProvinceCode);
    origin.put('postalCode', fAddress.Postal_Code__c);
    origin.put('country', fromCountryCode != null ? fromCountryCode.toLowerCase() : 'us');
    origin.put('contactName', shipFromContact.Name);
    origin.put('contactPhone', shipFromContact.Phone);
    origin.put('opensAt',
        fAddress.opens_at__c != null ?
            ((fAddress.opens_at__c.hour() < 10 ? '0' : '') + fAddress.opens_at__c.hour() + ':' +
            (fAddress.opens_at__c.minute() < 10 ? '0' : '') + fAddress.opens_at__c.minute())
        : null
    );

    origin.put('closesAt',
        fAddress.closes_at__c != null ?
            ((fAddress.closes_at__c.hour() < 10 ? '0' : '') + fAddress.closes_at__c.hour() + ':' +
            (fAddress.closes_at__c.minute() < 10 ? '0' : '') + fAddress.closes_at__c.minute())
        : null
    );

    payload.put('origin', origin);

    // Destination
    Map<String, Object> destination = new Map<String, Object>();
    String destinationCompany;
    if (shipToContact != null && shipToContact.Company__r != null && !String.isBlank(shipToContact.Company__r.Name)) {
        destinationCompany = shipToContact.Company__r.Name;
    } else if (tAddress != null && tAddress.Customer__r != null && !String.isBlank(tAddress.Customer__r.Company_txt__c)) {
        destinationCompany = tAddress.Customer__r.Company_txt__c;
    } else if (shipToContact != null && shipToContact.Account != null && !String.isBlank(shipToContact.Account.Name)) {
        destinationCompany = shipToContact.Account.Name;
    }
    destination.put('company', destinationCompany);
    //destination.put('company', tAddress.Company__r.Name != null ? tAddress.Company__r.Name : shipToContact.Account.Name);
    destination.put('address', tAddress.Name);
    destination.put('city', tAddress.City__c);
    destination.put('state', toProvinceCode);
    destination.put('postalCode', tAddress.Postal_Code__c);
    destination.put('country', toCountryCode != null ? toCountryCode.toLowerCase() : 'us');
    destination.put('contactName', shipToContact.Name);
    destination.put('contactPhone', shipToContact.Phone);
    destination.put('opensAt',
        tAddress.opens_at__c != null ?
            ((tAddress.opens_at__c.hour() < 10 ? '0' : '') + tAddress.opens_at__c.hour() + ':' +
            (tAddress.opens_at__c.minute() < 10 ? '0' : '') + tAddress.opens_at__c.minute())
        : null
    );

    destination.put('closesAt',
        tAddress.closes_at__c != null ?
            ((tAddress.closes_at__c.hour() < 10 ? '0' : '') + tAddress.closes_at__c.hour() + ':' +
            (tAddress.closes_at__c.minute() < 10 ? '0' : '') + tAddress.closes_at__c.minute())
        : null
    );

    payload.put('destination', destination);

    // Items
   List<Map<String, Object>> itemsList = new List<Map<String, Object>>();
Boolean hasHazmat = false; // Track if any item is hazardous
List<String> missingFields = new List<String>(); // Collect missing field errors

for (Package_List__c pl : packageItems) {
    Map<String, Object> item = new Map<String, Object>();

    Product2 prod = pl.Order_Product__r.Product2;

    // --- General item fields ---
    item.put('quantity', Integer.valueOf(pl.Quantity__c));
    Decimal weight = prod.Weight__c != null ? prod.Weight__c : pl.Package__r.Weight__c;
    item.put('weight', (weight != null && weight > 0) ? weight : 1);
    item.put('weightUOM', pl.Package__r.Weight_Unit__c == 'KGS' ? 'kg' : 'lbs');
    item.put('freightClass', prod.freight_class__c != null ? (Object)prod.freight_class__c : (Object)65);
    item.put('description', prod.Name);
    item.put('type', pl.Package__r.Package_Type__c != null ? pl.Package__r.Package_Type__c.toLowerCase() : 'pallet');
    Decimal length = prod.Length__c != null ? prod.Length__c : pl.Package__r.Length__c;
    Decimal width  = prod.Width__c  != null ? prod.Width__c  : pl.Package__r.Width__c;
    Decimal height = prod.Height__c != null ? prod.Height__c : pl.Package__r.Height__c;
    item.put('length', (length != null && length >= 1) ? length : 1);
    item.put('width',  (width != null && width >= 1) ? width : 1);
    item.put('height', (height != null && height >= 1) ? height : 1);
    item.put('dimensionsUOM', 'in');

    // --- Optional NMFC ---
   if (prod.NMFC_code__c != null) {
        item.put('nmfcNumber', prod.NMFC_code__c);
    }


    // --- HAZMAT CHECKS ---
    if (prod.is_hazmat__c == true) {
        hasHazmat = true;
		System.debug('Hazmat_ID__c =>'+prod.Hazmat_ID__c +'Primary_hazard_class__c =>'+prod.Primary_Hazard_Class__c +'Packaging_Group__c =>'+prod.Packaging_Group__c);
        // Validate required hazmat fields
        if (String.isBlank(prod.Hazmat_ID__c)) missingFields.add(prod.Name + ': Hazmat ID missing');
        if (String.isBlank(prod.Primary_Hazard_Class__c)) missingFields.add(prod.Name + ': Primary Hazard Class missing');
        if (String.isBlank(prod.Packaging_Group__c)) missingFields.add(prod.Name + ': Packaging Group missing');

        // Add hazmat info if all present
        if (String.isNotBlank(prod.Hazmat_ID__c) && 
            String.isNotBlank(prod.Primary_Hazard_Class__c) &&
            String.isNotBlank(prod.Packaging_Group__c)) {

            Map<String, Object> hazmat = new Map<String, Object>();
           	hazmat.put('hazmatId', prod.Hazmat_ID__c);
            hazmat.put('primaryClass', prod.Primary_Hazard_Class__c);
            hazmat.put('packingGroup', prod.Packaging_Group__c);

            item.put('hazardous', hazmat);
        }
    }

    itemsList.add(item);
}

// --- Handle missing hazmat fields ---
if (!missingFields.isEmpty()) {
    res.errMsgs = missingFields;
    return res;
}

// --- Add items to payload ---
payload.put('items', itemsList);

// --- Emergency Contact ---
if (hasHazmat) {
    if (ship.Emergency_Contact__c == null || String.isBlank(ship.Emergency_Contact__r.Name) || String.isBlank(ship.Emergency_Contact__r.Phone)) {
        res.errMsgs = new List<String>{'Emergency contact details are missing and its required for hazardous shipments.'};
        return res;
    } else {
        Map<String, Object> emergencyContact = new Map<String, Object>();
        emergencyContact.put('name', ship.Emergency_Contact__r.Name);
        emergencyContact.put('phone', ship.Emergency_Contact__r.Phone);
        payload.put('emergencyContact', emergencyContact);
    }
} else if (String.isNotBlank(ship.Emergency_Contact__c)) {
    // Optional: include emergency contact if present for non-hazmat
    Map<String, Object> emergencyContact = new Map<String, Object>();
    emergencyContact.put('name', ship.Emergency_Contact__r.Name);
    emergencyContact.put('phone', ship.Emergency_Contact__r.Phone);
    payload.put('emergencyContact', emergencyContact);
}


    // Serialize payload
    String jsonBody = JSON.serialize(payload);
    System.debug('Freightview Shipment Payload: ' + jsonBody);

    // Make HTTP callout
    HttpRequest request = new HttpRequest();
    request.setEndpoint(MCW.endPoint + '/v2.0/shipments/ltl');
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Authorization', 'Bearer ' + token);
    request.setBody(jsonBody);

    Http http = new Http();
    HttpResponse response = http.send(request);
    System.debug('Freightview Response: ' + response.getBody());
    Integer statusCode = response.getStatusCode();
    String responseBody = response.getBody();
    res.response = responseBody;

    if (statusCode == 200 || statusCode == 201) {
        // Parse JSON response
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        // Extract basic fields
        String shipmentId = (String) responseMap.get('shipmentId');
        String shipmentStatus = (String) responseMap.get('status');
        String pickupDate = (String) responseMap.get('pickupDate');

        // Extract locations (origin and destination)
        List<Object> locations = (List<Object>) responseMap.get('locations');
        Map<String, Object> originLoc;
        Map<String, Object> destLoc;

        if (locations != null && locations.size() > 0) {
            for (Object locObj : locations) {
                Map<String, Object> loc = (Map<String, Object>) locObj;
                String type = (String) loc.get('type');
                if (type == 'origin') originLoc = loc;
                if (type == 'destination') destLoc = loc;
            }
        }

        // Build or update Shipment__c record
        Id recordTypeId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName()
                                .get('freightview')
                                .getRecordTypeId();

        ship.RecordTypeId = recordTypeId;
        ship.Active__c = true;
        ship.Name = 'Shipment';
        ship.Status__c = 'Pending'; // always pending on creation
        ship.shipmentID__c = shipmentId; // freightview shipmentId used as reference
        ship.Carrier_Code__c = 'FV';
        // ship.Pickup_Date__c = Date.valueOf(pickupDate);

        // Link addresses, customer, and contacts
        if (fAddress.Id != null && ship.Shipment_Billing_options__c == 'SENDER') {
            ship.Billing_Address__c = fAddress.Id;
        } else if (tAddress.Id != null) {
            ship.Billing_Address__c = tAddress.Id;
        }
        if (fAddress.Id != null && ship.Shipment_Billing_options__c == 'SENDER') {
            ship.Billing_Contact__c = shipFromContact.Id;
        } else if (tAddress.Id != null) {
            ship.Billing_Contact__c = shipToContact.Id;
        }
        if (tAddress.Customer__c != null)
            ship.Customer__c = tAddress.Customer__c;

        ship.Customer_Contact__c = shipToContact.Id;
        ship.Shipping_Address__c = tAddress.Id;

        // Assign logistics and package info
        if (packList.size() > 0) {
            ship.Package__c = packList[0].Id;
            if (packList[0].Logistic__c != null)
                ship.Logistic__c = packList[0].Logistic__c;
            if (packList[0].Order__c != null)
                ship.Order__c = packList[0].Order__c;
            if (packList[0].Return_Merchandise_Authorisation__c != null)
                ship.Return_Merchandise_Authorisation__c = packList[0].Return_Merchandise_Authorisation__c;
        }
        // Integer totalPackages = packList.size();
        decimal totalPackQty = 0;
        // for (Package__c pkg : packList) {
        //     totalPackageItems += (pkg.Total_Package_Items__c != null ? Integer.valueOf(pkg.Total_Package_Items__c) : 0);
        // }
        for(Package__c pK : packList) totalPackQty += pK.Package_Quantity__c;
        ship.Number_Of_Pieces_In_Shipment__c = String.valueof(packList.size());
        ship.Total_Package_Items__c = totalPackQty;

        // Save shipment record
        upsert ship;

        // Update packages
        for (Package__c pk : packList) {
            pk.Shipment__c = ship.Id;
            // pk.Status__c = ship.Status__c;
            pk.Tracking_Number__c = shipmentId;
        }
        if (!packList.isEmpty()) update packList;

        // Attach documents if any
        if (responseMap.containsKey('documents')) {
            List<Object> docs = (List<Object>) responseMap.get('documents');
            List<Attachment> attList = new List<Attachment>();
            for (Object docObj : docs) {
                Map<String, Object> doc = (Map<String, Object>) docObj;
                String fileUrl = (String) doc.get('url');
                if (fileUrl != null) {
                    Attachment att = new Attachment(
                        Name = 'Freightview_Document_Link.txt',
                        ParentId = ship.Id,
                        ContentType = 'text/plain',
                        Body = Blob.valueOf('Document: ' + fileUrl)
                    );
                    attList.add(att);
                }
            }
            if (!attList.isEmpty()) insert attList;
        }

        // Return result
        res.ShipDetails = ship;
        // res.success = true;

    } else {
        // Handle validation or API error
        Map<String, Object> errMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> errors = (List<Object>) errMap.get('errors');
        List<String> errList = new List<String>();
        if (errors != null && !errors.isEmpty()) {
            for (Object errObj : errors) {
                Map<String, Object> e = (Map<String, Object>) errObj;
                String msg = e.get('message') != null ? (String)e.get('message') : 'Unknown error';
                String prop = e.get('propertyName') != null ? (String)e.get('propertyName') : '';
                errList.add('Property: ' + prop + ' | Message: ' + msg);
            }
        }
        res.errMsgs = errList;
        // res.success = false;
    }
    return res;

}


    @AuraEnabled
    public static String getAccessToken(String client_id, String client_secret, String endPoint) {
        System.debug('🔑 Freightview v2 Auth - client_id: ' + client_id);
        System.debug('🔑 Freightview v2 Auth - endPoint: ' + endPoint);
        System.debug('client secret: '+client_secret);
        // Correct v2 token endpoint
        String tokenUrl = endPoint + '/v2.0/auth/token';
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(tokenUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        // ✅ Body should include client_id, client_secret, and grant_type
        Map<String, Object> bodyMap = new Map<String, Object>{
            'grant_type' => 'client_credentials',
            'client_id' => client_id,
            'client_secret' => client_secret
        };
        request.setBody(JSON.serialize(bodyMap));

        Http http = new Http();
        HttpResponse response;
        String httpResult = '';
        Integer statusCode = 0;

        if (Test.isRunningTest()) {
            httpResult = '{"access_token":"mock_token_v2_12345","token_type":"bearer","expires_in":3600}';
            statusCode = 200;
        } else {
            response = http.send(request);
            httpResult = response.getBody();
            statusCode = response.getStatusCode();
            System.debug('📦 Freightview v2 Response: ' + httpResult);
        }

        if (statusCode == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(httpResult);
            String accessToken = (String)jsonResponse.get('access_token');
            System.debug('✅ Freightview v2 Access Token: ' + accessToken);
            return accessToken;
        } else {
            System.debug('❌ Freightview v2 Token Failed - Status: ' + statusCode + ', Body: ' + httpResult);
            return null;
        }
    }
    
   
 @AuraEnabled
    public static Wrapper getDefaultData(String ShipId,String packIds,Boolean ReturnShip){
        Wrapper wrap = new Wrapper();
        try{
            if(ReturnShip == null) ReturnShip = false;
        system.debug('ShipId : '+ShipId);
        system.debug('packIds : '+packIds);


        //Address__c address = new Address__c();

        List<selectOptions> options = new List<selectOptions>();
        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        Schema.DescribeFieldResult fieldResult = Shipment__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.StatusConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Signature_Services__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.SignatureServices = options;

       

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Label_options__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.LabelOptions = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Shipment_Billing_options__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.BillingOptions = options;

        myConstructorWrapper MCW = new myConstructorWrapper();
        string credName = system.Label.AxoltFreightViewERP;
        System.debug('credName = ' + credName);
        String credentialFields = UtilClass.selectStarFromSObject('Credentials__c');
        MCW.FreightViewCredentials = Database.query('select ' + credentialFields + ' from Credentials__c where (Name = :credName And Active__c = true) Limit 1');
        System.debug('MCW.FreightViewCredentials = ' + MCW.FreightViewCredentials);
        System.debug('MCW.FreightViewCredentials[0].Shipper_Country__c = ' + MCW.FreightViewCredentials[0].Shipper_Country__c);
        if(MCW.FreightViewCredentials.size() > 0){
            MCW.parentKey =MCW.FreightViewCredentials[0].Parent_Key__c;
            MCW.parentPassword = MCW.FreightViewCredentials[0].Parent_Password__c;
            MCW.endPoint = MCW.FreightViewCredentials[0].URL__c;
            MCW.accountNumber = MCW.FreightViewCredentials[0].UPS_Account_Number__c;
            MCW.childKey = MCW.FreightViewCredentials[0].key__c;
            MCW.childpassword = MCW.FreightViewCredentials[0].Password_Transkey__c;
            MCW.Username = MCW.FreightViewCredentials[0].Username_Login__c;

            if(getProvinceCode(MCW.FreightViewCredentials[0].Shipper_Province__c) != '')
                MCW.shipperProvinceCode = getProvinceCode(MCW.FreightViewCredentials[0].Shipper_Province__c);
            else if(MCW.FreightViewCredentials[0].Shipper_Province__c != null && MCW.FreightViewCredentials[0].Shipper_Province__c != '') MCW.wrapError = ' Shipping Service Unavailable : Shipper Province Code not found';
            if(getCountryCode(MCW.FreightViewCredentials[0].Shipper_Country__c) != '')
                MCW.shipperCountryCode = getCountryCode(MCW.FreightViewCredentials[0].Shipper_Country__c); else MCW.wrapError = ' Shipping Service Unavailable : Shipper Country Code not found';
        }
        else MCW.wrapError = ' Shipping Service Unavailable : Please setup  credentials';

        wrap.credsWrap = MCW;
        String packageFields = UtilClass.selectStarFromSObject('Package__c');
        String addressFields = UtilClass.selectStarFromSObject('Address__c');
        string packageListFields = UtilClass.selectStarFromSObject('Package_List__c');
        if(!ReturnShip){
            if(ShipId != null && ShipId != ''){
                system.debug('enterd ship id');
                String shipfields = UtilClass.selectStarFromSObject('Shipment__c');
                String ShipmentRecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Shipment__c','freightview');

                //wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name, Logistic__r.From_Contact__c,Logistic__r.Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c,Logistic__r.Billing_Contact__c, Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,Logistic__r.Billing_Contact_Return__r.Id,Logistic__r.Billing_Contact_Return__r.Name,Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c, Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c, Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email,  Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c,  Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c,  Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email from Package__c where Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Active__c = true');
                wrap.packList = Database.query( 'SELECT ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name, Logistic__r.From_Contact__c,Logistic__r.Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c,Logistic__r.Billing_Contact__c, Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,Logistic__r.Billing_Contact_Return__r.Id,Logistic__r.Billing_Contact_Return__r.Name,Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c, Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c, Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email,  Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c,  Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c,  Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email FROM Package__c WHERE Shipment__c = \'' + String.escapeSingleQuotes(shipId) + '\' AND Active__c = true');
                set<Id> packageIds = new Set<Id>();
                system.debug('wrp.packlist----'+wrap.packList);
                for(Package__c pck : wrap.packList ) packageIds.add(pck.Id);
                //wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', Package__r.Name, Logistic_Line_Item__r.Product__c,Logistic_Line_Item__r.Product__r.Weight__c,Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c, Package__r.Sales_Order__c, Order_Product__r.Base_Price__c, Sales_Order_Line_Item__r.Base_Price__c, Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Sales_Order_Line_Item__r.Product__r.SKU__c, Sales_Order_Line_Item__r.Product__r.Name,Sales_Order_Line_Item__r.Product__r.Declared_Shipment_Value__c,Order_Product__r.Product2.Declared_Shipment_Value__ Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name, RMA_Line_Item__r.Ord_Item__r.Product2.Name, RMA_Line_Item__r.SOLI__r.Product__r.Name, Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, Sales_Order_Line_Item__r.Total_Price__c, Order_Product__r.ReturnedQuantity__c, Sales_Order_Line_Item__r.ReturnedQuantity__c, Order_Product__r.Order.Name, Sales_Order_Line_Item__r.Sales_Order__r.Name, Order_Product__r.UnitPrice, Sales_Order_Line_Item__r.Price_Product__c, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c, Sales_Order_Line_Item__r.Product__r.Goods_Description__c, Sales_Order_Line_Item__r.Product__r.Commodity_Code__c FROM Package_List__c WHERE Package__c IN :packageIds');
                wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, '+'Order_Product__r.Product2.is_hazmat__c,' +'Order_Product__r.Product2.freight_class__c,'+'Order_Product__r.Product2.NMFC_code__c,'+'Order_Product__r.Product2.Primary_Hazard_Class__c,'+'Order_Product__r.Product2.Packaging_Group__c,'+'Order_Product__r.Product2.Hazmat_ID__c,' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packageIds' );


                List<Shipment__c> Shipslist = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,emergency_contact__r.Id,emergency_contact__r.Name,emergency_contact__r.phone,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name,Billing_Contact__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
                if(Shipslist.size() > 0) wrap.ship  = Shipslist[0];
                else wrap.alertlist.add('Shipment is Either Cancelled or not availbale in the system');
                List<Shipment__c> returnShips = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,emergency_contact__r.Id,emergency_contact__r.Name,emergency_contact__r.phone,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name,Billing_Contact__r.Name from Shipment__c where (Return_Shipment__c = true AND Active__c = true And Master_Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\') Limit 1');
                if(returnShips.size() > 0) wrap.returnShip =returnShips[0];
            }
            else if(packIds != null && packIds != ''){
                system.debug('entered else if of packsIds');
                List<String> packId = (List<String>) JSON.deserialize(packIds,List<String>.class);
                wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name,Logistic__r.From_Contact__c, Logistic__r.Contact__c,Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Billing_Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c, Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c ,Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,  '+
                                               +' Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c,Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_From_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email, Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c,  '+
                                               +' Logistic__r.Billing_Contact_Return__r.Id, Logistic__r.Billing_Contact_Return__r.Name,Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Estimated_Shipping_Amount__c, Order__r.Insurance_Charges__c, Order__r.Shipping_VAT__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c, '+
                                               +' Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c, '+
                                               +' Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email ,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__r.Contact__c from Package__c where Id In  :packId  And Active__c = true');
                wrap.packItems = Database.query(
                    'SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Order_Product__r.Product2.is_hazmat__c,'+'Order_Product__r.Product2.freight_class__c,'+'Order_Product__r.Product2.NMFC_code__c,'+'Order_Product__r.Product2.Primary_Hazard_Class__c,'+'Order_Product__r.Product2.Packaging_Group__c,'+'Order_Product__r.Product2.Hazmat_ID__c,' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packId');
               /* wrap.packItems = Database.query('select ' + String.escapeSingleQuotes(packageListFields) + ' ,Logistic_Line_Item__r.Product__c,Logistic_Line_Item__r.Product__r.Weight__c,Package__r.Name, Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c ,Order_Product__r.Base_Price__c, '+
                                                +' Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name,RMA_Line_Item__r.Ord_Item__r.Product2.Name, '+
                                                +' Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, '+
                                                +' Order_Product__r.Order.Name , Order_Product__r.UnitPrice, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c From Package_List__c where Package__c IN :packId');*/
            }
            System.debug('wrap.packList.size()==>'+wrap.packList.size());
            if(wrap.packList.size() > 0){

                if(wrap.packList[0].Logistic__c != null){
                    if(wrap.packList[0].Logistic__r.From_Address__c != null) { wrap.fromAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Logistic__r.From_Address__c + '\' Limit 1');
                    }
                    if(wrap.packList[0].Logistic__r.To_Address__c != null){ wrap.toAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Logistic__r.To_Address__c + '\' Limit 1');
                    }
                    if(wrap.packList[0].Logistic__r.From_Contact__c != null){ wrap.fromContact = Database.query('select Id,Name,accountId,Account.Name,Account.Phone,Account.Email__c, Email, Phone, Company__c ,Company__r.Name from contact where Id =\'' + wrap.packList[0].Logistic__r.From_Contact__c  + '\' Limit 1');
                    }
                    if(wrap.packList[0].Logistic__r.Contact__c != null){  wrap.toContact = Database.query('select Id,Name,accountId, Account.Name, Account.Phone,Email, Account.Email__c,Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Logistic__r.Contact__c + '\' Limit 1');
                    }
                }
                

                
            }else {
                System.debug('entered if else');
            }

        }
        Functionality_Control__c FC = new Functionality_Control__c();
        FC = Functionality_Control__c.getValues(userInfo.getuserid());
        if(FC == null){ FC = Functionality_Control__c.getValues(userInfo.getProfileId());   if(FC==null) FC = Functionality_Control__c.getInstance();  }
        if(FC != null){
            wrap.disableBillingDetails = FC.Allow_Billing_details_edit_in_Ship_scree__c;
           
        }
        return wrap;
        }catch(Exception e){
            System.debug('error->'+e.getLineNumber()+' and '+e.getMessage());
        }
        System.debug('wrap==>'+wrap);
        return wrap;
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
 @AuraEnabled
    public static List<quoteWrapper> getQuoteRates(String Shipment, String myConsVar) {
        List<quoteWrapper> quotesList = new List<quoteWrapper>();

        try {
            // Deserialize inputs
            Shipment__c ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
            System.debug('ship =>'+ship);
            myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);

            // Get token
            String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);
            System.debug('ship.shipmentID__c '+ship.shipmentID__c);
			System.debug('afr token');
            if (String.isBlank(ship.shipmentID__c)) {
                throw new AuraHandledException('Shipment does not have a Tracking Number.');
            }
			System.debug('h1');
            // Prepare endpoint
            String endpoint = MCW.endPoint + '/v2.0/shipments/' + ship.shipmentID__c + '/quotes';
			System.debug('endpoint now '+endpoint);
            // HTTP Request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('req'+req);
            System.debug('FreightView Quotes Response: ' + res.getBody());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    Map<String, Object> resMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    List<Object> quotes = (List<Object>) resMap.get('quotes');

                    for (Object qObj : quotes) {
                        Map<String, Object> q = (Map<String, Object>) qObj;
                        String status = (String) q.get('status');
                        String mode = (String) q.get('mode');

                        if (status == 'active' && mode == 'ltl') {
                            quoteWrapper qw = new quoteWrapper();
                            qw.quoteId = (String) q.get('quoteId');
                            qw.assetCarrierName = (String) q.get('assetCarrierName');
                            qw.assetCarrierCode = (String) q.get('assetCarrierCode');
                            qw.providerName = (String) q.get('providerName');
                            qw.providerCode = (String) q.get('providerCode');
                            qw.serviceDescription = (String) q.get('serviceDescription');
                            qw.amount = (Decimal) q.get('amount');
                            qw.currencyCode = (String) q.get('currency');
                            qw.transitDaysMin = q.containsKey('transitDaysMin') ? (Integer) q.get('transitDaysMin') : null;
                            qw.transitDaysMax = q.containsKey('transitDaysMax') ? (Integer) q.get('transitDaysMax') : null;
                            qw.shipmentBookPageUrl = (String) q.get('shipmentBookPageUrl');
                            qw.status = status;
                            qw.mode = mode;
							// NEW fields for richer meaning
                            qw.pricingMethod = (String) q.get('pricingMethod'); // e.g., "contracted", "dynamic", "spot"
                            qw.pricingType   = (String) q.get('pricingType');   // e.g., "tariff"
                            qw.quoteNum      = (String) q.get('quoteNum');      // e.g., "LZC5C12825"
                            qw.interline     = q.containsKey('interline') ? (Boolean) q.get('interline') : null;
                            qw.timeT          = q.containsKey('time') ? (Integer) q.get('time') : null;

                            quotesList.add(qw);
                        }
                    }
                }
                else {
                System.debug('Error fetching quotes: ' + res.getStatusCode() + ' - ' + res.getBody());
                throw new AuraHandledException('Failed to fetch quotes: ' + res.getStatusCode()); 
            }

        } catch (Exception e) {
            System.debug('Error in getQuotes: ' + e.getMessage());
            throw new AuraHandledException('Error fetching FreightView quotes: ' + e.getMessage());
        }
// Group for verification: providerName -> list of serviceDescription
// Group for verification: assetCarrierName -> list of serviceDescription
Map<String, List<String>> carrierServicesMap = new Map<String, List<String>>();
for (quoteWrapper qw : quotesList) {
    String carrier = qw.assetCarrierName != null ? qw.assetCarrierName : 'Unknown Carrier';
    if (!carrierServicesMap.containsKey(carrier)) carrierServicesMap.put(carrier, new List<String>());
    carrierServicesMap.get(carrier).add(qw.serviceDescription);
}

// Debug log for verification
System.debug('📝 Quotes Grouped by Carrier (serviceDescription only):');
for (String carrier : carrierServicesMap.keySet()) {
    System.debug('🚚 ' + carrier + ' => ' + carrierServicesMap.get(carrier));
}


        return quotesList;
    }
    @AuraEnabled
public static BookingResult bookFreightview(
    String shipmentJson,       
    String quoteId,
    Boolean schedulePickup,
    String myConsVar
) {
    System.debug('1');
    System.debug('schedule pickup is '+schedulePickup);
    BookingResult br = new BookingResult();
   // br.documentTitles = new List<String>();

    try {
        System.debug('2');
        // Auth
        myConstructorWrapper mcw = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
         Shipment__c shipmentRec = (Shipment__c) JSON.deserialize(shipmentJson, Shipment__c.class);
        System.debug('3');
        String token = getAccessToken(mcw.Username, mcw.childpassword, mcw.endPoint);
		System.debug('4');
        //  Prepare endpoint using Freightview Shipment Id
        if (String.isBlank(shipmentRec.shipmentID__c)) {
            throw new AuraHandledException('Shipment record is missing Freightview Shipment ID.');
        }
		System.debug('5');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(mcw.endPoint + '/v2.0/shipments/ltl/' +
            EncodingUtil.urlEncode(shipmentRec.shipmentID__c, 'UTF-8') + '/book');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setTimeout(30000);
        req.setBody(JSON.serialize(new Map<String,Object>{
            'quoteId' => quoteId,
            'schedulePickup' => schedulePickup
        }));
        System.debug('quoteId'+quoteId);
		System.debug('req'+req);
        Http http = new Http();
        HttpResponse res = http.send(req);
        br.responseRaw = res.getBody();
		System.debug('br.responseRaw =>'+br.responseRaw);
        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            br.success = false;
            // Parse responseRaw to extract errors
            try {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String mainMsg = (String) respMap.get('message');
                List<Object> errorsList = (List<Object>) respMap.get('errors');
                List<String> detailedErrors = new List<String>();
                if (errorsList != null) {
                    for (Object eObj : errorsList) {
                        Map<String, Object> eMap = (Map<String, Object>) eObj;
                        if (eMap.containsKey('message')) detailedErrors.add((String) eMap.get('message'));
                    }
                }
                br.message = mainMsg + (detailedErrors.size() > 0 ? ': ' + String.join(detailedErrors, ', ') : '');
            } catch (Exception ex) {
                // fallback
                br.message = 'Booking failed: ' + res.getStatusCode() + ' - ' + res.getBody();
            }
            br.responseRaw = res.getBody();
            return br;
        }


        //️⃣ Parse response
        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        String status = (String) resp.get('status');
       // String detailsUrl = (String) resp.get('shipmentDetailsUrl');
        String fvId = (String) resp.get('shipmentId');

        String trackingNumber;
        if (resp.containsKey('tracking')) {
            Map<String, Object> tr = (Map<String, Object>) resp.get('tracking');
            trackingNumber = (String) tr.get('trackingNumber');
            System.debug('trackingNumber'+trackingNumber);
        }

        Map<String, Object> sel = (Map<String, Object>) resp.get('selectedQuote');
        String carrier = sel != null ? (String) sel.get('assetCarrierName') : null;
        String service = sel != null ? (String) sel.get('serviceDescription') : null;
        Decimal amount = null;
        if (sel != null && sel.containsKey('amount')) {
            amount = Decimal.valueOf(String.valueOf(sel.get('amount')));
        }
        String currencyFV = sel != null ? (String) sel.get('currency') : null;
List<String> titles = new List<String>();
List<Id> docIds = new List<Id>();

try {
    docIds = saveFreightviewDocs(resp, shipmentRec.Id, token, titles);
} catch (Exception exDocs) {
    System.debug('Doc save error (download): ' + exDocs.getMessage());
}
        //  Update shipment record (no query!)
        Shipment__c ship = new Shipment__c(
            Id = shipmentRec.Id,
            Status__c = 'confirmed',
            Carrier__c = carrier,
            Service_Description__c = service,
            Shipping_Amount__c = amount,
            shipmentID__c = fvId,
            TrackingNumber__c = trackingNumber
        );
		System.debug('updating shipment');
        update ship;
		System.debug('afr update ship');
        // Right after "update ship;"

        // Populate result so UI can show what we saved
        br.contentDocumentIds = docIds;
        br.contentTitles = titles;
		Map<String, Id> byType = new Map<String, Id>();
System.debug('>>> TITLES: ' + JSON.serialize(titles));

for (Integer i = 0; i < titles.size(); i++) {
    String t = (titles[i] ?? '').toLowerCase();
    Id docId = docIds.size() > i ? docIds[i] : null;

    if (t.endsWith('-bol') || t.endsWith('-bol.pdf') || t.contains('-bol'))
        byType.put('bol', docId);
    else if (t.endsWith('-label') || t.endsWith('-label.pdf') || t.contains('-label'))
        byType.put('label', docId);
    else if (t.endsWith('-customer-quote') || t.endsWith('-customer-quote.pdf') || t.contains('-customer-quote'))
        byType.put('customer-quote', docId);
    else if (t.endsWith('-rate-detail') || t.endsWith('-rate-detail.pdf') || t.contains('-rate-detail'))
        byType.put('rate-detail', docId);
}

br.docByType = byType;
System.debug('>>> FIXED DOC BY TYPE: ' + JSON.serialize(br.docByType));

        
		System.debug('everything looks fine');
        //️⃣ Return response
        br.success = true;
        br.message = 'Shipment booked successfully and documents saved.';
        br.shipmentSalesforceId = shipmentRec.Id;
        br.shipmentId = fvId;
        br.status = status;
        br.trackingNumber = trackingNumber;
       // br.shipmentDetailsUrl = detailsUrl;
        br.amount = amount;
        br.currencyCode = currencyFV;
        br.carrier = carrier;
        br.service = service;
        br.ShipDetails = ship;
        return br;

    } catch (Exception e) {
        System.debug('in error in booking');
        br.success = false;
        br.message = 'Error: ' + e.getMessage();
        return br;
    }
}
private class FvDocDownload {
    String title;
    String ext;
    Blob data;
    FvDocDownload(String t, String e, Blob b) { title = t; ext = e; data = b; }
}
private static Blob fvGetBlob(String downloadUrl, String bearerToken) {
    if (!String.isBlank(downloadUrl) && downloadUrl.endsWith('?')) {
        downloadUrl = downloadUrl.substring(0, downloadUrl.length()-1);
    }
    HttpRequest r = new HttpRequest();
    r.setMethod('GET');
    r.setEndpoint(downloadUrl);
    r.setHeader('Authorization', 'Bearer ' + bearerToken);
    r.setHeader('Accept', 'application/pdf');
    r.setTimeout(30000);

    Http h = new Http();
    HttpResponse resp = h.send(r);
    Integer sc = resp.getStatusCode();
    if (sc == 200 || sc == 201) return resp.getBodyAsBlob();

    // Optional tiny retry for 429
    if (sc == 429) {
        resp = h.send(r);
        if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) return resp.getBodyAsBlob();
    }
    System.debug('Freightview doc GET failed: ' + sc + ' - ' + resp.getBody());
    return null;
}

/**
 * Two-phase saver:
 *  Phase 1: CALL OUTS ONLY → collect blobs in memory
 *  Phase 2: DML ONLY       → insert ContentVersion (Files) with FirstPublishLocationId
 */
private static List<Id> saveFreightviewDocs(
    Map<String,Object> resp,
    Id shipmentId,
    String bearerToken,
    List<String> outTitles
) {
    List<Id> contentDocIds = new List<Id>();
    if (resp == null || !resp.containsKey('documents')) return contentDocIds;

    List<Object> docs = (List<Object>) resp.get('documents');
    if (docs == null || docs.isEmpty()) return contentDocIds;

    // ---- Phase 1: CALL OUTS ONLY ----
    List<FvDocDownload> downloads = new List<FvDocDownload>();
    for (Object o : docs) {
        Map<String,Object> d = (Map<String,Object>) o;
        String type     = (String) d.get('type');
        String fileName = (String) d.get('fileName');
        String mime     = (String) d.get('mimeType');
        String url      = (String) d.get('downloadUrl');

        Boolean wanted =
            (type != null && FV_DOC_TYPES.contains(type.toLowerCase())) ||
            (fileName != null && FV_DOC_TYPES.contains(fileName.toLowerCase()));
        if (!wanted || String.isBlank(url)) continue;

        Blob body = fvGetBlob(url, bearerToken);  // **callout**
        if (body == null) continue;

        String st = !String.isBlank(type) ? type.toLowerCase()
                 : (!String.isBlank(fileName) ? fileName.toLowerCase() : 'document');
        String title = 'FV-' + (String)resp.get('shipmentId') + '-' + st;
        String ext = (mime != null && mime.toLowerCase().contains('pdf')) ? '.pdf' : '.bin';
        downloads.add(new FvDocDownload(title, ext, body));
    }

    // ---- Phase 2: DML ONLY ----
    if (!downloads.isEmpty()) {
        List<ContentVersion> cvs = new List<ContentVersion>();
        for (FvDocDownload d : downloads) {
            cvs.add(new ContentVersion(
                Title = d.title,
                PathOnClient = d.title + d.ext,
                VersionData = d.data,
                IsMajorVersion = true,
                FirstPublishLocationId = shipmentId // link to Shipment__c
            ));
        }
        insert cvs;

        // Collect ids & titles (handy for UI)
        Set<Id> cdIds = new Set<Id>();
        for (ContentVersion cv : cvs) if (cv.ContentDocumentId != null) cdIds.add(cv.ContentDocumentId);
        System.debug('');
        if (!cdIds.isEmpty()) {
            for (ContentDocument cd : [SELECT Id, Title FROM ContentDocument WHERE Id IN :cdIds]) {
                contentDocIds.add(cd.Id);
                if (outTitles != null) outTitles.add(cd.Title);
            }
        }
    }
    return contentDocIds;
}
    @AuraEnabled(cacheable=true)
public static Map<String, Id> getShipmentDocs(Id shipmentId) {
    Map<String, Id> docByType = new Map<String, Id>();

    List<ContentDocumentLink> links = [
        SELECT ContentDocumentId, ContentDocument.Title
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :shipmentId
    ];

    for (ContentDocumentLink link : links) {
        String t = (link.ContentDocument.Title ?? '').toLowerCase();
        if (t.contains('-bol')) docByType.put('bol', link.ContentDocumentId);
        else if (t.contains('-label')) docByType.put('label', link.ContentDocumentId);
        else if (t.contains('-customer-quote')) docByType.put('customer-quote', link.ContentDocumentId);
        else if (t.contains('-rate-detail')) docByType.put('rate-detail', link.ContentDocumentId);
    }

    return docByType;
}
@AuraEnabled
public static List<TrackingEventWrapper> getTrackingHistory(String shipmentId, String myConsVar) {
    List<TrackingEventWrapper> trackingList = new List<TrackingEventWrapper>();
	System.debug('shipmentId=>'+shipmentId);
    try {
        if (String.isBlank(shipmentId)) {
            throw new AuraHandledException('Shipment ID is required for tracking.');
        }

        // Deserialize credentials
        myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);

        // Get token
        String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);

        // Prepare endpoint
        String endpoint = MCW.endPoint + '/v2.0/shipments/' + shipmentId + '/tracking';

        // HTTP Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        System.debug('request =>'+req);
        HttpResponse res = http.send(req);
		System.debug('response =>'+res);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            List<Object> events = (List<Object>) JSON.deserializeUntyped(res.getBody());
            for (Object eObj : events) {
                Map<String, Object> e = (Map<String, Object>) eObj;
                TrackingEventWrapper evt = new TrackingEventWrapper();
                evt.createdDate = (String) e.get('createdDate');
                evt.eventDate   = (String) e.get('eventDate');
                evt.eventTime   = (String) e.get('eventTime');
                evt.eventType   = (String) e.get('eventType');
                evt.summary     = (String) e.get('summary');
                trackingList.add(evt);
            }
        } else {
            throw new AuraHandledException('Failed to fetch tracking: ' + res.getStatusCode());
        }

    } catch (Exception ex) {
        throw new AuraHandledException('Error fetching FreightView tracking: ' + ex.getMessage());
    }

    return trackingList;
}

    public class myConstructorWrapper{
        @AuraEnabled public List<Credentials__c> FreightViewCredentials                { get; set; }
        @AuraEnabled public String parentKey                                   { get; set; }
        @AuraEnabled public String parentPassword                              { get; set; }
        @AuraEnabled public String childKey                                    { get; set; }
        @AuraEnabled public String childpassword                               { get; set; }
        @AuraEnabled public String endPoint                                    { get; set; }@AuraEnabled public String meterNumber                                 { get; set; }
        @AuraEnabled public String accountNumber                               { get; set; }
        @AuraEnabled public String shipperProvinceCode                         { get; set; }
        @AuraEnabled public String Username                                    { get; set; }

        @AuraEnabled public String shipperCountryCode                          { get; set; }@AuraEnabled public String wrapError                                   { get; set; }
    }

    public class Wrapper {
    @AuraEnabled public List<selectOptions> StatusConfirmation { get; set; }
    @AuraEnabled public List<selectOptions> SignatureServices { get; set; }
    @AuraEnabled public List<selectOptions> LabelOptions { get; set; }
    @AuraEnabled public List<selectOptions> BillingOptions { get; set; }
    @AuraEnabled public myConstructorWrapper credsWrap { get; set; }
    @AuraEnabled public List<Package__c> packList { get; set; }
    @AuraEnabled public List<Package_List__c> packItems { get; set; }
    @AuraEnabled public Shipment__c ship { get; set; }
    @AuraEnabled public Shipment__c returnShip { get; set; }
    @AuraEnabled public List<String> alertlist { get; set; }
    @AuraEnabled public Address__c fromAddress { get; set; }
    @AuraEnabled public Address__c toAddress { get; set; }
    @AuraEnabled public Contact fromContact { get; set; }
    @AuraEnabled public Contact toContact { get; set; }
    @AuraEnabled public Boolean disableBillingDetails { get; set; }

    public Wrapper(){
        StatusConfirmation = new List<selectOptions>();
        SignatureServices = new List<selectOptions>();
        LabelOptions = new List<selectOptions>();
        BillingOptions = new List<selectOptions>();
        credsWrap = new myConstructorWrapper();
        packList = new List<Package__c>();
        packItems = new List<Package_List__c>();
        alertlist = new List<String>();
        ship = new Shipment__c();
        returnShip = new Shipment__c();
        fromAddress = new Address__c();
        toAddress = new Address__c();
        fromContact = new Contact();
        toContact = new Contact();
        disableBillingDetails = false;
    }
}
    public class selectOptions{
        @AuraEnabled public string value {get;set;}
        @AuraEnabled public string label {get;set;}
        public selectOptions(){ value = label = '';
        }
        public selectOptions(string label,String value){
            this.value = value;
            this.label = label;
        }

    }

    public class shipmentResponse {
      @AuraEnabled public List<String> errMsgs { get; set; }
      @AuraEnabled public String successMsg { get; set; }
      @AuraEnabled public String request { get; set; }
      @AuraEnabled public String response { get; set; }@AuraEnabled public List<Shipment_Flow__c> ShipFlows { get; set; }
      @AuraEnabled public Shipment__c ShipDetails { get; set; }
      @AuraEnabled public List<Attachment> attList { get; set; }

      public shipmentResponse() {
          errMsgs = new List<String>();
      }
  }
public class quoteWrapper {
    @AuraEnabled public String quoteId;
    @AuraEnabled public String assetCarrierName;
    @AuraEnabled public String assetCarrierCode;
    @AuraEnabled public String providerName;
    @AuraEnabled public String providerCode;
    @AuraEnabled public String serviceDescription;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String currencyCode;
    @AuraEnabled public Integer transitDaysMin;
    @AuraEnabled public Integer transitDaysMax;
    @AuraEnabled public String shipmentBookPageUrl;
    @AuraEnabled public String status;
    @AuraEnabled public String mode;
    @AuraEnabled public String pricingMethod;    
     @AuraEnabled public String pricingType;     
    @AuraEnabled public String quoteNum;         
     @AuraEnabled public Boolean interline;       
    @AuraEnabled public Integer timeT;            
}

  public class BookingResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String responseRaw;
        @AuraEnabled public Id shipmentSalesforceId;
        @AuraEnabled public String shipmentId;
        @AuraEnabled public String status;              
        @AuraEnabled public String trackingNumber;
        //@AuraEnabled public String shipmentDetailsUrl;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String carrier;
        @AuraEnabled public String service;
      @AuraEnabled public Shipment__c ShipDetails { get; set; }
    
    // New (optional, helps the UI)
    @AuraEnabled public List<Id> contentDocumentIds;
    @AuraEnabled public List<String> contentTitles;
      @AuraEnabled public Map<String, Id> docByType; 
      
    }
public class TrackingEventWrapper {
    @AuraEnabled public String createdDate;
    @AuraEnabled public String eventDate;
    @AuraEnabled public String eventTime;
    @AuraEnabled public String eventType;
    @AuraEnabled public String summary;
}
}