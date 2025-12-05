public with sharing class freightView {
    private static final Set<String> FV_DOC_TYPES = new Set<String>{ 'bol', 'label', 'label-pdf' };
  @AuraEnabled(cacheable=true)
    public static String getContactPhone(Id contactId) {
        if(contactId == null) return null;
        Contact c = [SELECT Phone FROM Contact WHERE Id = :contactId LIMIT 1];
        return c.Phone;
    }	

@AuraEnabled
public static shipmentResponse shippingRequestResponse(List<Package__c> packList,String fromAddress,String toAddress,
    String fromContact,
    String toContact,
    String ShipDateStamp,
    String myConsVar,
    String Shipment,
    List<Package_List__c> packageItems,
    String masterShipmentId,
    String shipmentMode,String tlStopsJson
){
    shipmentResponse res = new shipmentResponse();
    //System.debug('tlStopsJson=>'+tlStopsJson);
    //System.debug('deserialized tlStopsJson=>'+JSON.deserializeUntyped(tlStopsJson));
    
    // ---- Parse inputs ----
    Shipment__c ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
    Contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);
    Contact shipToContact   = (Contact) JSON.deserialize(toContact,   Contact.class);

    Address__c fAddress = String.isNotBlank(fromAddress) ? (Address__c) JSON.deserialize(fromAddress, Address__c.class) : new Address__c();
    Address__c tAddress = String.isNotBlank(toAddress)   ? (Address__c) JSON.deserialize(toAddress,   Address__c.class) : new Address__c();

    // ---- Auth ----
    myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
    String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);
    System.debug('AFR token');
    // ---- Mode flags ----
    String mode = (shipmentMode == null ? '' : shipmentMode).trim().toLowerCase();
    Boolean isTruckload = (mode == 'truckload' || mode == 'truck load' || mode == 'tl' || mode == 'ftl');
    Boolean isParcel    = (mode == 'parcel');

    // ---- Build LTL-style items list (we'll reuse parts for TL) ----
    List<Map<String, Object>> itemsList = new List<Map<String, Object>>();
    Boolean hasHazmat = false;
    List<String> missingHazmat = new List<String>();
    if (packList != null) {
        for (Package__c p : packList) {

            Map<String, Object> item = new Map<String, Object>();

         

          if (p.Weight__c == null || p.Weight__c <= 0) {
                res.errMsgs = new List<String>{
                    'Weight is required and must be > 0 for package: ' + p.Name
                };
                return res;
            }

            item.put('weight', p.Weight__c);
            item.put('weightUOM', p.Weight_Unit__c == 'KGS' ? 'kg' : 'lbs');


           if (p.Length__c == null || p.Width__c == null || p.Height__c == null ||
                p.Length__c <= 0 || p.Width__c <= 0 || p.Height__c <= 0) {

                res.errMsgs = new List<String>{
                    'Dimensions (LxWxH) are required and must be > 0 for package: ' + p.Name
                };
                return res;
            }

            item.put('length',  p.Length__c);
            item.put('width',   p.Width__c);
            item.put('height',  p.Height__c);
            item.put('dimensionsUOM', 'in');


            item.put('dimensionsUOM', 'in');

            String typeVal = (String.isNotBlank(p.Package_Type__c)) ? p.Package_Type__c.toLowerCase() : '';
            item.put('type', typeVal);

            item.put('description', p.Name);


            if (!isParcel) {

                item.put('quantity', 1);

                item.put('weightUOM', p.Weight_Unit__c == 'KGS' ? 'kg' : 'lbs');

                if (p.freight_class__c != null) {
                    try {
                        Decimal fc = Decimal.valueOf(p.freight_class__c);
                        item.put('freightClass', fc);
                    } catch (Exception ex) {
                        res.errMsgs = new List<String>{ 'Invalid freight class for package: ' + p.Name };
                        return res;
                    }
                } else {
                    res.errMsgs = new List<String>{ 'Freight Class is required for package: ' + p.Name };
                    return res;
                }

               
                if (p.NMFC_code__c != null) {
                    try {
                        item.put('nmfcNumber', Integer.valueOf(p.NMFC_code__c));
                    } catch (Exception ex) {
                        res.errMsgs = new List<String>{ 'Invalid NMFC for package: ' + p.Name };
                        return res;
                    }
                }


               
                if (p.is_hazmat__c == true) { hasHazmat = true; if (String.isBlank(p.Hazmat_ID__c)) missingHazmat.add(p.Name + ': Hazmat ID missing'); if (String.isBlank(p.Primary_Hazard_Class__c)) missingHazmat.add(p.Name + ': Hazard Class missing'); if (String.isBlank(p.Packaging_Group__c)) missingHazmat.add(p.Name + ': Packaging Group missing'); if (String.isNotBlank(p.Hazmat_ID__c) && String.isNotBlank(p.Primary_Hazard_Class__c) && String.isNotBlank(p.Packaging_Group__c)) { item.put('hazardous', new Map<String, Object>{ 'hazmatId'     => p.Hazmat_ID__c, 'primaryClass' => p.Primary_Hazard_Class__c, 'packingGroup' => p.Packaging_Group__c }); } } } itemsList.add(item); } } if (!missingHazmat.isEmpty()){ res.errMsgs = missingHazmat; return res; } Map<String,Object> emergencyContact = null; if(!isParcel){ if (hasHazmat) { if (ship.Emergency_Contact__c == null || ship.Emergency_Contact__r == null || String.isBlank(ship.Emergency_Contact__r.Name) || String.isBlank(ship.Emergency_Contact__r.Phone)) { res.errMsgs = new List<String>{ 'Emergency contact details are required for hazardous shipments.' }; return res; } emergencyContact = new Map<String,Object>{ 'name'  => ship.Emergency_Contact__r.Name, 'phone' => ship.Emergency_Contact__r.Phone }; } else if (String.isNotBlank(ship.Emergency_Contact__c) && ship.Emergency_Contact__r != null) { emergencyContact = new Map<String,Object>{ 'name'  => ship.Emergency_Contact__r.Name, 'phone' => ship.Emergency_Contact__r.Phone }; } } Map<String,Object> payload = new Map<String,Object>(); payload.put('pickupDate', ShipDateStamp); if (isTruckload) { List<Map<String,Object>> stopsUI = new List<Map<String,Object>>(); System.debug('tlStopsJson=>'+tlStopsJson); if (String.isNotBlank(tlStopsJson)) { Object parsed = JSON.deserializeUntyped(tlStopsJson); if (parsed instanceof List<Object>) { for (Object o : (List<Object>) parsed) { if (!(o instanceof Map<String,Object>)) continue; Map<String,Object> s = (Map<String,Object>) o; String addrId = (String)s.get('addressId'); if (String.isBlank(addrId)) addrId = (String)s.get('address'); if (String.isBlank(addrId)) addrId = (String)s.get('Address__c'); if (String.isBlank(addrId)) { System.debug('⚠️ Skipping stop — no addressId found: ' + s); continue; } s.put('addressId', addrId); stopsUI.add(s); } } } System.debug('stopsUI=>'+stopsUI); Set<Id> addrIds = new Set<Id>(); for (Map<String,Object> s : stopsUI) addrIds.add((Id)s.get('addressId')); Map<Id, Address__c> addrById = new Map<Id, Address__c>(); if (!addrIds.isEmpty()) { for (Address__c a : [ SELECT Id, Name, Address_Line1__c, City__c, State__c, Postal_Code__c, Country__c, opens_at__c, closes_at__c, Contact__r.Phone, Contact__r.Name, Customer__r.Company_txt__c FROM Address__c WHERE Id IN :addrIds ]) addrById.put(a.Id, a); } List<Map<String,Object>> locations = new List<Map<String,Object>>(); Integer seq = 0; Map<String,Object> loc0 = new Map<String,Object>(); loc0.put('stopType', 'pickup'); loc0.put('sequence', seq); loc0.put('stopDate', ShipDateStamp); loc0.put('state', getProvinceCode(fAddress != null ? fAddress.State__c : null)); loc0.put('postalCode', fAddress != null ? fAddress.Postal_Code__c : null); String fromCountry = fAddress != null ? getCountryCode(fAddress.Country__c) : null; loc0.put('country', String.isBlank(fromCountry) ? 'us' : fromCountry.toLowerCase()); String originCompany = (shipFromContact != null && shipFromContact.Company__r != null && !String.isBlank(shipFromContact.Company__r.Name)) ? shipFromContact.Company__r.Name : (fAddress != null && fAddress.Customer__r != null && !String.isBlank(fAddress.Customer__r.Company_txt__c)) ? fAddress.Customer__r.Company_txt__c : (shipFromContact != null && shipFromContact.Account != null) ? shipFromContact.Account.Name : null; loc0.put('company', originCompany); loc0.put('address', fAddress != null ? fAddress.Name : null); loc0.put('opensAt',  fAddress != null && fAddress.opens_at__c  != null ? ((fAddress.opens_at__c.hour()<10?'0':'')+fAddress.opens_at__c.hour()) + ':' + ((fAddress.opens_at__c.minute()<10?'0':'')+fAddress.opens_at__c.minute()) : null); loc0.put('closesAt', fAddress != null && fAddress.closes_at__c != null ? ((fAddress.closes_at__c.hour()<10?'0':'')+fAddress.closes_at__c.hour()) + ':' + ((fAddress.closes_at__c.minute()<10?'0':'')+fAddress.closes_at__c.minute()) : null); loc0.put('contactName',  shipFromContact != null ? shipFromContact.Name  : null); loc0.put('contactPhone', shipFromContact != null ? shipFromContact.Phone : null); locations.add(loc0); seq++; Integer lastDeliverySeq = null; for (Map<String,Object> s : stopsUI) { Address__c a = addrById.get((Id)s.get('addressId')); if (a == null) continue; String uiType = (String)s.get('type'); String apiType = uiType == 'pickup_deliver' ? 'pickup-and-delivery' : uiType == 'deliver' ? 'delivery' : 'pickup'; locations.add(new Map<String,Object>{ 'stopType'   => apiType, 'sequence'   => seq, 'company'    => a?.Customer__r?.Company_txt__c, 'address'    => a?.Name, 'address2'   => a?.Address_Line1__c, 'city'       => a?.City__c, 'state'      => getProvinceCode(a?.State__c), 'postalCode' => a?.Postal_Code__c, 'country'    => (String.isBlank(getCountryCode(a?.Country__c)) ? 'us' : getCountryCode(a?.Country__c).toLowerCase()), 'opensAt' => ( a?.opens_at__c != null ? ((a.opens_at__c.hour()<10?'0':'') + a.opens_at__c.hour()) + ':' + ((a.opens_at__c.minute()<10?'0':'') + a.opens_at__c.minute()) : null ), 'closesAt' => ( a?.closes_at__c != null ? ((a.closes_at__c.hour()<10?'0':'') + a.closes_at__c.hour()) + ':' + ((a.closes_at__c.minute()<10?'0':'') + a.closes_at__c.minute()) : null ), 'contactName'  => a?.Contact__r.Name, 'contactPhone' => a?.Contact__r.Phone, 'notes'        => (String)s.get('instructions') }); if (apiType == 'delivery' || apiType == 'pickup-and-delivery') lastDeliverySeq = seq; seq++; } Map<String,Object> locEnd = new Map<String,Object>(); locEnd.put('stopType', 'delivery'); locEnd.put('sequence', seq); locEnd.put('stopDate', ShipDateStamp); locEnd.put('state', getProvinceCode(tAddress != null ? tAddress.State__c : null)); locEnd.put('postalCode', tAddress != null ? tAddress.Postal_Code__c : null); String toCountry = tAddress != null ? getCountryCode(tAddress.Country__c) : null; locEnd.put('country', String.isBlank(toCountry) ? 'us' : toCountry.toLowerCase()); String destCompany = (shipToContact != null && shipToContact.Company__r != null && !String.isBlank(shipToContact.Company__r.Name)) ? shipToContact.Company__r.Name : (tAddress != null && tAddress.Customer__r != null && !String.isBlank(tAddress.Customer__r.Company_txt__c)) ? tAddress.Customer__r.Company_txt__c : (shipToContact != null && shipToContact.Account != null) ? shipToContact.Account.Name : null; locEnd.put('company', destCompany); locEnd.put('address', tAddress != null ? tAddress.Name : null); locEnd.put('opensAt',  tAddress != null && tAddress.opens_at__c  != null ? ((tAddress.opens_at__c.hour()<10?'0':'')+tAddress.opens_at__c.hour()) + ':' + ((tAddress.opens_at__c.minute()<10?'0':'')+tAddress.opens_at__c.minute()) : null); locEnd.put('closesAt', tAddress != null && tAddress.closes_at__c != null ? ((tAddress.closes_at__c.hour()<10?'0':'')+tAddress.closes_at__c.hour()) + ':' + ((tAddress.closes_at__c.minute()<10?'0':'')+tAddress.closes_at__c.minute()) : null); locEnd.put('contactName',  shipToContact != null ? shipToContact.Name  : null); locEnd.put('contactPhone', shipToContact != null ? shipToContact.Phone : null); locations.add(locEnd); if (lastDeliverySeq == null) lastDeliverySeq = seq; payload.put('locations', locations); String equipmentType; for (Package__c p : packList) if (String.isNotBlank(p.Equipment_Type__c)) { equipmentType = p.Equipment_Type__c; break; } if (String.isBlank(equipmentType)) { res.errMsgs = new List<String>{ 'Equipment Type is required for Truckload.' }; return res; } Decimal totalWeight = 0; String eqUOM = 'lbs'; for (Package__c p : packList) { if (p.Weight__c != null) { totalWeight += p.Weight__c; } if (p.Weight_Unit__c == 'KGS') { eqUOM = 'kg'; } } payload.put('equipment', new Map<String,Object>{ 'type' => equipmentType, 'description' => 'General goods', 'weight' => totalWeight, 'weightUOM' => eqUOM, 'isHazardous' => hasHazmat }); List<Map<String,Object>> tlItems = new List<Map<String,Object>>(); for (Package__c p : packList) { Map<String,Object> it = new Map<String,Object>{ 'description' => p.Name, 'quantity'    => 1, 'type'        => p.Package_Type__c != null ? p.Package_Type__c.toLowerCase() : 'package', 'weight'      => (p.Weight__c != null ? p.Weight__c : 1), 'weightUOM'   => (p.Weight_Unit__c == 'KGS' ? 'kg' : 'lbs'), 'stackable'   => false, 'pickupLocationSequence' => 0, 'dropLocationSequence'   => lastDeliverySeq }; if (p.is_hazmat__c == true && String.isNotBlank(p.Primary_Hazard_Class__c)) { it.put('hazmatClass', p.Primary_Hazard_Class__c); } tlItems.add(it); } payload.put('items', tlItems); payload.put('isLiveLoad', ship.isLiveLoad__c == true); if (emergencyContact != null) payload.put('emergencyContact', emergencyContact); } else { payload.put('origin',      buildLocationMap(fAddress, shipFromContact,isParcel,true)); payload.put('destination', buildLocationMap(tAddress, shipToContact,isParcel,false)); payload.put('items', itemsList); if (emergencyContact != null) payload.put('emergencyContact', emergencyContact); } String path = '/v2.0/shipments/ltl'; if (isTruckload) path = '/v2.0/shipments/truckload'; else if (isParcel) path = '/v2.0/shipments/parcel'; String jsonBody = JSON.serialize(payload); System.debug('Freightview Payload (' + (isTruckload ? 'TL' : isParcel ? 'Parcel' : 'LTL') + '): ' + jsonBody); HttpRequest request = new HttpRequest(); request.setEndpoint(MCW.endPoint + path); request.setMethod('POST'); request.setHeader('Content-Type', 'application/json'); request.setHeader('Authorization', 'Bearer ' + token); request.setBody(jsonBody); Http http = new Http(); HttpResponse response = http.send(request); System.debug('Freightview Response: ' + response.getBody()); Integer statusCode = response.getStatusCode(); String responseBody = response.getBody(); res.response = responseBody; if (statusCode == 200 || statusCode == 201) { Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody); String shipmentId = (String) responseMap.get('shipmentId'); Id recordTypeId = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName() .get('freightview').getRecordTypeId(); ship.RecordTypeId  = recordTypeId; ship.Active__c     = true; ship.Name          = 'Shipment'; ship.Status__c     = 'Pending'; ship.shipmentID__c = shipmentId; ship.Carrier_Code__c = 'FV'; if (fAddress.Id != null && ship.Shipment_Billing_options__c == 'SENDER') { ship.Billing_Address__c = fAddress.Id; ship.Billing_Contact__c = (shipFromContact != null ? shipFromContact.Id : null); } else if (tAddress.Id != null) { ship.Billing_Address__c = tAddress.Id; ship.Billing_Contact__c = (shipToContact != null ? shipToContact.Id : null); } if (tAddress.Customer__c != null) ship.Customer__c = tAddress.Customer__c; ship.Customer_Contact__c = (shipToContact != null ? shipToContact.Id : null); ship.Shipping_Address__c = tAddress.Id; if (packList != null && !packList.isEmpty()) { if(packList.size() == 1)ship.Package__c = packList[0].Id; if (packList[0].Logistic__c != null) ship.Logistic__c = packList[0].Logistic__c; if (packList[0].Order__c   != null) ship.Order__c    = packList[0].Order__c; if (packList[0].Return_Merchandise_Authorisation__c != null) ship.Return_Merchandise_Authorisation__c = packList[0].Return_Merchandise_Authorisation__c; } Decimal totalPackQty = 0; if (packList != null) for (Package__c pK : packList) totalPackQty += (pK.Package_Quantity__c == null ? 0 : pK.Package_Quantity__c); ship.Number_Of_Pieces_In_Shipment__c = String.valueOf(packList == null ? 0 : packList.size()); ship.Total_Package_Items__c          = totalPackQty; upsert ship; if (packList != null && !packList.isEmpty()) { for (Package__c pk : packList) { pk.Shipment__c = ship.Id; pk.Tracking_Number__c = shipmentId; } update packList; } if (responseMap != null && responseMap.containsKey('documents')) { List<Object> docs = (List<Object>) responseMap.get('documents'); List<Attachment> attList = new List<Attachment>(); if (docs != null) { for (Object docObj : docs) { Map<String, Object> doc = (Map<String, Object>) docObj; String fileUrl = (String) doc.get('url'); if (fileUrl != null) { attList.add(new Attachment( Name = 'Freightview_Document_Link.txt', ParentId = ship.Id, ContentType = 'text/plain', Body = Blob.valueOf('Document: ' + fileUrl) )); } } } if (!attList.isEmpty()) insert attList; } res.ShipDetails = ship; return res; } else { Map<String, Object> errMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody); List<Object> errors = errMap != null ? (List<Object>) errMap.get('errors') : null; List<String> errList = new List<String>(); if (errors != null && !errors.isEmpty()) { for (Object errObj : errors) { Map<String, Object> e = (Map<String, Object>) errObj; String msg  = e != null && e.get('message') != null ? (String) e.get('message')  : 'Unknown error'; String prop = e != null && e.get('propertyName') != null ? (String) e.get('propertyName') : ''; errList.add('Property: ' + prop + ' | Message: ' + msg); } } res.errMsgs = errList; return res;

        //end big
    }
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
                wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, Package__r.Package_Type__c,' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, '+'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packageIds' );


                List<Shipment__c> Shipslist = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,emergency_contact__r.Id,emergency_contact__r.Name,emergency_contact__r.phone,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name,Billing_Contact__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
                System.debug('Shipslist =>'+Shipslist);
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
                    'SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, Package__r.Package_Type__c, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packId');
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

     // Minimal shared helper (single place to build LTL/Parcel locations)
private static Map<String,Object> buildLocationMap(Address__c addr, Contact con,Boolean isParcel,Boolean isOrigin) {
    Map<String,Object> m = new Map<String,Object>();
    if (addr == null) addr = new Address__c();

    // company fallback
    String company = (con != null && con.Company__r != null && !String.isBlank(con.Company__r.Name)) ? con.Company__r.Name : (addr.Customer__r != null && !String.isBlank(addr.Customer__r.Company_txt__c)) ? addr.Customer__r.Company_txt__c : (con != null && con.Account != null) ? con.Account.Name : null; m.put('company', company); m.put('address', addr.Name); m.put('city', addr.City__c); String st = getProvinceCode(addr.State__c); m.put('state', st); String cn = getCountryCode(addr.Country__c); m.put('country', String.isBlank(cn) ? 'us' : cn.toLowerCase()); m.put('postalCode', addr.Postal_Code__c); m.put('contactName',  con != null ? con.Name  : null); m.put('contactPhone', con != null ? con.Phone : null); m.put('contactEmail', con != null ? con.Email : null); if (!(isParcel && !isOrigin)) { m.put('opensAt',  addr.opens_at__c != null ? ((addr.opens_at__c.hour()<10?'0':'')+addr.opens_at__c.hour()) + ':' + ((addr.opens_at__c.minute()<10?'0':'')+addr.opens_at__c.minute()) : null); m.put('closesAt', addr.closes_at__c != null ? ((addr.closes_at__c.hour()<10?'0':'')+addr.closes_at__c.hour()) + ':' + ((addr.closes_at__c.minute()<10?'0':'')+addr.closes_at__c.minute()) : null); } return m;
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
    public static QuoteRatesResponse getQuoteRates(String Shipment, String myConsVar,String modeFilter) {
        //List<quoteWrapper> quotesList = new List<quoteWrapper>();
        String mf = (modeFilter == null ? '' : modeFilter).trim().toLowerCase();
        System.debug('modeFilter =>'+mf);
         QuoteRatesResponse out = new QuoteRatesResponse();
          out.quotes = new List<quoteWrapper>();
           out.requestedFrom = new List<Object>();
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
                     if (resMap != null && resMap.containsKey('requestedFrom')) {
                        out.requestedFrom = (List<Object>) resMap.get('requestedFrom');
                    }
                    for (Object qObj : quotes) {
                        Map<String, Object> q = (Map<String, Object>) qObj;
                        String status = (String) q.get('status');
                        String mode = (String) q.get('mode');

                        if (status == 'active' && mode == mf) {
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

                            out.quotes.add(qw);
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
        for (quoteWrapper qw : out.quotes) {
            String carrier = qw.assetCarrierName != null ? qw.assetCarrierName : 'Unknown Carrier';
            if (!carrierServicesMap.containsKey(carrier)) carrierServicesMap.put(carrier, new List<String>());
            carrierServicesMap.get(carrier).add(qw.serviceDescription);
        }

        // Debug log for verification
        System.debug('📝 Quotes Grouped by Carrier (serviceDescription only):');
        for (String carrier : carrierServicesMap.keySet()) {
            System.debug('🚚 ' + carrier + ' => ' + carrierServicesMap.get(carrier));
        }


    return out;
}
private static Map<String,Object> fvGetShipment(String base, String token, String fvId) {
    HttpRequest r = new HttpRequest();
    r.setMethod('GET');
    r.setEndpoint(base + '/v2.0/shipments/' + EncodingUtil.urlEncode(fvId, 'UTF-8'));
    r.setHeader('Authorization', 'Bearer ' + token);
    r.setHeader('Content-Type', 'application/json');
    r.setTimeout(30000);

    Http h = new Http();
    HttpResponse resp = h.send(r);
    Integer sc = resp.getStatusCode();
    if (sc == 200 || sc == 201) {
        return (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
    }
    throw new AuraHandledException('Failed to fetch FV shipment (' + sc + '): ' + resp.getBody());
}

@AuraEnabled
public static BookingResult bookFreightview(String shipmentJson,String quoteId,Boolean schedulePickup,String myConsVar,String mode) {
    BookingResult br = new BookingResult();

    try {
        // ---------- Auth & inputs ----------
        myConstructorWrapper mcw = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
        Shipment__c shipmentRec  = (Shipment__c) JSON.deserialize(shipmentJson, Shipment__c.class);

        if (String.isBlank(shipmentRec.shipmentID__c)) {
            throw new AuraHandledException('Shipment record is missing Freightview Shipment ID.');
        }
        String token = getAccessToken(mcw.Username, mcw.childpassword, mcw.endPoint);

        // ---------- Mode routing ----------
        String m = (mode == null ? '' : mode.trim().toLowerCase());
        if (m != 'truckload' && m != 'parcel' && m != 'ltl') m = 'ltl';
        Boolean isParcel    = (m == 'parcel');
        Boolean isLTL       = (m == 'ltl');
        Boolean isTruckload = (m == 'truckload');
        String encId = EncodingUtil.urlEncode(shipmentRec.shipmentID__c, 'UTF-8');

        // ---------- Truckload → Hydrate → Award ----------
        if (isTruckload) {
            System.debug('Booking Truckload shipment via /award');
            Map<String,Object> fv = fvGetShipment(mcw.endPoint, token, shipmentRec.shipmentID__c);

            List<Object> locations = (List<Object>) fv.get('locations');
            Map<String,Object> equipment = (Map<String,Object>) fv.get('equipment');
            List<Object> items = (List<Object>) fv.get('items');

          
            Map<String,Object> emergencyContact = (Map<String,Object>) fv.get('emergencyContact');
            Object isLiveLoad = fv.containsKey('isLiveLoad') ? fv.get('isLiveLoad') : null;

            List<String> problems = new List<String>();
            if (locations == null || locations.size() < 2) problems.add('locations (>=2) not found on FV shipment');
            if (equipment == null || equipment.isEmpty())  problems.add('equipment not found on FV shipment');
            if (items == null || items.isEmpty())          problems.add('items not found on FV shipment');

            if (!problems.isEmpty()) {
                throw new AuraHandledException('Cannot award truckload: ' + String.join(problems, '; '));
            }

            
            Map<String,Object> awardBody = new Map<String,Object>{
                'quoteId'        => quoteId,
                'schedulePickup' => (schedulePickup == null ? true : schedulePickup),
                'createBOL'      => true,
                'locations'      => locations,
                'equipment'      => equipment,
                'items'          => items
            };
            if (emergencyContact != null) awardBody.put('emergencyContact', emergencyContact);
            if (isLiveLoad != null)       awardBody.put('isLiveLoad', isLiveLoad);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(mcw.endPoint + '/v2.0/shipments/truckload/' + encId + '/award');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setTimeout(30000);
            req.setBody(JSON.serialize(awardBody));

            Http http = new Http();
            HttpResponse res = http.send(req);
            Integer sc = res.getStatusCode();
            String resBody = res.getBody();
            br.responseRaw = resBody;

            if (sc == 204) {
                Shipment__c upd = new Shipment__c(Id = shipmentRec.Id, Status__c = 'awarded');
                update upd;

                br.success               = true;
                br.message               = 'Truckload shipment awarded.';
                br.shipmentSalesforceId  = shipmentRec.Id;
                br.shipmentId            = shipmentRec.shipmentID__c;
                br.status                = 'awarded';
                br.ShipDetails           = upd;
                return br;
            }

            Map<String, Object> err = null;
            try { err = (Map<String, Object>) JSON.deserializeUntyped(resBody); } catch (Exception ignore) {}
            String msg = 'Award failed: ' + sc;
            if (err != null && err.containsKey('message')) msg = (String) err.get('message');
            if (err != null && err.containsKey('errors')) {
                List<Object> errs = (List<Object>) err.get('errors');
                if (errs != null && !errs.isEmpty()) {
                    List<String> parts = new List<String>();
                    for (Object eObj : errs) {
                        Map<String,Object> e = (Map<String,Object>) eObj;
                        if (e != null && e.containsKey('message')) parts.add((String)e.get('message'));
                    }
                    if (!parts.isEmpty()) msg += ': ' + String.join(parts, ' | ');
                }
            }
            br.success = false;
            br.message = msg;
            return br;
        }

        String endpoint = (isParcel)
            ? mcw.endPoint + '/v2.0/shipments/parcel/' + encId + '/book'
            : mcw.endPoint + '/v2.0/shipments/ltl/'    + encId + '/book';

        Map<String, Object> body = new Map<String, Object>{
            'quoteId' => quoteId
        };
        if (!isParcel) {
            body.put('schedulePickup', (schedulePickup == null ? true : schedulePickup));
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setTimeout(30000);
        req.setBody(JSON.serialize(body));
        System.debug('Booking endpoint: ' + endpoint);
        System.debug('Booking body: ' + req.getBody());
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('FreightView Booking Response: ' + res.getBody());
        Integer sc = res.getStatusCode();
        String resBody = res.getBody();
        br.responseRaw = resBody;

        if (sc != 200 && sc != 201) {
            Map<String, Object> err = null; try { err = (Map<String, Object>) JSON.deserializeUntyped(resBody); } catch (Exception ignore) {} String msg = 'Booking failed: ' + sc; if (err != null && err.containsKey('message')) msg = (String) err.get('message'); if (err != null && err.containsKey('errors')) { List<Object> errs = (List<Object>) err.get('errors'); if (errs != null && !errs.isEmpty()) { List<String> parts = new List<String>(); for (Object eObj : errs) { Map<String,Object> e = (Map<String,Object>) eObj; if (e != null && e.containsKey('message')) parts.add((String)e.get('message')); } if (!parts.isEmpty()) msg += ': ' + String.join(parts, ' | '); } } br.success = false;            br.message = msg;            return br;
        }

        Map<String, Object> resp = (Map<String, Object>) JSON.deserializeUntyped(resBody); String status = (String) resp.get('status'); String fvId   = (String) resp.get('shipmentId'); String trackingNumber; if (resp.containsKey('tracking')) { Map<String, Object> tr = (Map<String, Object>) resp.get('tracking'); trackingNumber = (String) tr.get('trackingNumber'); } Map<String, Object> sel = (Map<String, Object>) resp.get('selectedQuote'); String carrier = sel != null ? (String) sel.get('assetCarrierName')   : null; String service = sel != null ? (String) sel.get('serviceDescription') : null; Decimal amount = null; if (sel != null && sel.containsKey('amount')) amount = Decimal.valueOf(String.valueOf(sel.get('amount'))); String currencyFV = sel != null ? (String) sel.get('currency') : null; List<String> titles = new List<String>(); List<Id> docIds = new List<Id>(); try { docIds = saveFreightviewDocs(resp, shipmentRec.Id, token, titles); } catch (Exception exDocs) { System.debug('Doc save error: ' + exDocs.getMessage()); } Shipment__c shipUpd = new Shipment__c( Id = shipmentRec.Id, Status__c = 'confirmed', Carrier__c = carrier, Service_Description__c = service, Shipping_Amount__c = amount, shipmentID__c = (String.isBlank(fvId) ? shipmentRec.shipmentID__c : fvId), TrackingNumber__c = trackingNumber ); update shipUpd; Map<String, Id> byType = new Map<String, Id>(); for (Integer i = 0; i < titles.size(); i++) { String t = (titles[i] == null ? '' : titles[i]).toLowerCase(); Id did = (docIds.size() > i ? docIds[i] : null); if (t.endsWith('-bol') || t.endsWith('-bol.pdf') || t.contains('-bol'))             byType.put('bol', did); else if (t.endsWith('-label') || t.endsWith('-label.pdf') || t.contains('-label')) byType.put('label', did); else if (t.endsWith('-customer-quote') || t.contains('-customer-quote'))           byType.put('customer-quote', did); else if (t.endsWith('-rate-detail')   || t.contains('-rate-detail'))               byType.put('rate-detail', did); } br.success               = true; br.message               = 'Shipment booked successfully.'; br.shipmentSalesforceId  = shipmentRec.Id; br.shipmentId            = (String.isBlank(fvId) ? shipmentRec.shipmentID__c : fvId); br.status                = status; br.trackingNumber        = trackingNumber; br.amount                = amount; br.currencyCode          = currencyFV; br.carrier               = carrier; br.service               = service; br.ShipDetails           = shipUpd; br.contentDocumentIds    = docIds; br.contentTitles         = titles; br.docByType             = byType; return br; } catch (Exception e) { br.success = false; br.message = 'Error: ' + e.getMessage(); return br;
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

        Blob body = fvGetBlob(url, bearerToken); 
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
            for (ContentDocument cd : [SELECT Id, Title FROM ContentDocument WHERE Id IN :cdIds]) { contentDocIds.add(cd.Id); if (outTitles != null) outTitles.add(cd.Title);
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
    System.debug('links for docs  --> '+links);
    for (ContentDocumentLink link : links) {
        String t = (link.ContentDocument.Title ?? '').toLowerCase();
        if (t.contains('-bol')) docByType.put('bol', link.ContentDocumentId);
        else if (t.contains('-label')) docByType.put('label', link.ContentDocumentId); else if (t.contains('-customer-quote')) docByType.put('customer-quote', link.ContentDocumentId); else if (t.contains('-rate-detail')) docByType.put('rate-detail', link.ContentDocumentId);
    }
    System.debug('docByType --> '+docByType);
    return docByType;
}
@AuraEnabled
public static List<TrackingEventWrapper> getTrackingHistory(String shipmentId, String myConsVar) {
    List<TrackingEventWrapper> trackingList = new List<TrackingEventWrapper>();
	System.debug('shipmentId=>'+shipmentId);
    try {
        if (String.isBlank(shipmentId)) {            throw new AuraHandledException('Shipment ID is required for tracking.');
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

    } catch (Exception ex) {        throw new AuraHandledException('Error fetching FreightView tracking: ' + ex.getMessage());
    }

    return trackingList;
}
@AuraEnabled
public static Map<String, Object> requestTruckloadRFQ(
    String myConsVar,
    String shipmentId,
    List<String> emails,
    String message
){
    if (String.isBlank(shipmentId)) {
        throw new AuraHandledException('Shipment ID is required.');
    }
    if (emails == null || emails.isEmpty()) {
        throw new AuraHandledException('At least one email is required.');
    }

    // Auth
    myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
    String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);

    // Build payload
    Map<String, Object> body = new Map<String, Object>{
        'emails'  => emails,
        'message' => (message == null ? '' : message)
    };

    String endpoint = MCW.endPoint + '/v2.0/shipments/truckload/quotes/' +
                      EncodingUtil.urlEncode(shipmentId, 'UTF-8') +
                      '/request';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + token);
    req.setBody(JSON.serialize(body));
    req.setTimeout(120000);

    Http http = new Http();
    HttpResponse resp = http.send(req);

    Integer code = resp.getStatusCode();
    String respBody = resp.getBody();
    System.debug('TL RFQ response (' + code + '): ' + respBody);

    // 204 → success (no content)
    if (code == 204) {
        return new Map<String, Object>{ 'status' => 'success', 'message' => 'RFQ request submitted successfully.' };
    }

    // Handle standard 2xx (with possible content)
    if (code >= 200 && code < 300) {
        if (String.isBlank(respBody)) {
            return new Map<String, Object>{ 'status' => 'success' };
        }
        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        return (out == null) ? new Map<String, Object>{ 'status' => 'success' } : out;
    }

    // Handle Freightview error object

    Map<String, Object> errMap = new Map<String, Object>(); try { errMap = (Map<String, Object>) JSON.deserializeUntyped(respBody); } catch (Exception e) { throw new AuraHandledException('Freightview RFQ error: ' + respBody); } String errMsg = 'RFQ request failed.'; if (errMap != null && errMap.containsKey('message')) { errMsg = (String) errMap.get('message'); } throw new AuraHandledException(errMsg);
}

@AuraEnabled(cacheable=true)
public static List<String> getPackageEquipmentTypes() {
    List<String> out = new List<String>();
    Schema.DescribeFieldResult dfr = Package__c.Equipment_Type__c.getDescribe();
    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
        if (pe != null && pe.getValue() != null) out.add(pe.getValue());
    }
    return out;
}
@AuraEnabled
public static Map<String, Object> addManualTruckloadQuote(
    String myConsVar,
    String shipmentId,
    Decimal amount,
    String currencyMQ,
    String carrierEmail,
    String carrierName,           
    String autoCreateCarrierName,  
    String quoteNum,               
    String notes,                  
    String expiresAtISO,           
    Integer transitDays,          
    String equipmentType,          
    String serviceId,
    String serviceDescription
){
    System.debug('serviceId=>'+serviceId);
    System.debug('serviceDescription=>'+serviceDescription);
    // Validate minimums
    if (String.isBlank(shipmentId))  throw new AuraHandledException('Shipment ID is required.');
    if (amount == null || amount < 1) throw new AuraHandledException('Amount must be >= 1.');
    if (String.isBlank(currencyMQ))    currencyMQ = 'USD';
    if (String.isBlank(carrierEmail)) throw new AuraHandledException('Carrier email is required.');

    // Auth
    myConstructorWrapper MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
    String token = getAccessToken(MCW.Username, MCW.childpassword, MCW.endPoint);

    // Build body with only provided, API-friendly fields
    Map<String, Object> body = new Map<String, Object>();
    body.put('amount', amount);
    body.put('currency', currencyMQ.trim().toUpperCase());
    body.put('carrierEmail', carrierEmail.trim());

    if (String.isNotBlank(quoteNum))             body.put('quoteNum', quoteNum.trim());
    if (String.isNotBlank(carrierName))          body.put('carrierName', carrierName.trim());
    if (String.isNotBlank(autoCreateCarrierName))body.put('autoCreateCarrierName', autoCreateCarrierName.trim());
    if (String.isNotBlank(notes))                body.put('notes', notes);
    if (String.isNotBlank(expiresAtISO))         body.put('expiresAt', expiresAtISO.trim());
    if (transitDays != null && transitDays > 0)  body.put('transitDays', transitDays);
    if (String.isNotBlank(equipmentType))        body.put('equipmentType', equipmentType.trim().toLowerCase());
    if (String.isNotBlank(serviceId))            body.put('serviceId', serviceId.trim().toLowerCase());
    if (String.isNotBlank(serviceDescription))   body.put('serviceDescription', serviceDescription.trim());

    // Endpoint
    String endpoint = MCW.endPoint + '/v2.0/shipments/truckload/' +
        EncodingUtil.urlEncode(shipmentId, 'UTF-8') + '/quote';

    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + token);
    req.setTimeout(120000);
    req.setBody(JSON.serialize(body));
    System.debug('Manual TL Quote Request: ' + req.getBody());
    Http http = new Http();
    HttpResponse resp = http.send(req);
    Integer code = resp.getStatusCode();
    String respBody = resp.getBody();
    System.debug('Manual TL Quote (' + code + '): ' + respBody);

    // 201 Created returns { "quoteId": "..." }
    if (code == 201 || code == 200) {
        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        if (out == null) out = new Map<String, Object>();
        return out;
    } else {
        Map<String, Object> err = (Map<String, Object>) JSON.deserializeUntyped(respBody);
        String errMsg = (err != null && err.containsKey('message')) ? (String) err.get('message') : 'Failed to create manual quote.';
        throw new AuraHandledException(errMsg);
    }
}
@AuraEnabled(cacheable=true)
public static List<ManualQuoteDTO> getManualQuotes(String myConsVar, String fvShipmentId) {
    if (String.isBlank(fvShipmentId)) {
        throw new AuraHandledException('Freightview Shipment ID is required.');
    }

    myConstructorWrapper mcw = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
    String token = getAccessToken(mcw.Username, mcw.childpassword, mcw.endPoint);

    HttpRequest req = new HttpRequest();
    req.setEndpoint(mcw.endPoint + '/v2.0/shipments/' + EncodingUtil.urlEncode(fvShipmentId, 'UTF-8'));
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + token);
    req.setTimeout(30000);

    Http http = new Http();
    HttpResponse res = http.send(req);
    Integer sc = res.getStatusCode();
    if (sc != 200 && sc != 201) {
        throw new AuraHandledException('Failed to load shipment manual quotes: ' + sc + ' - ' + res.getBody());
    }

    Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

    List<ManualQuoteDTO> result = new List<ManualQuoteDTO>();
    Object selObj = body.get('selectedQuote');

    if (selObj != null && selObj instanceof Map<String, Object>) {
        Map<String, Object> selectedQuote = (Map<String, Object>) selObj;

        String method = (String) selectedQuote.get('method');
        String status = (String) selectedQuote.get('status');
        String methodLc = method == null ? '' : method.toLowerCase();
        String statusLc = status == null ? '' : status.toLowerCase();

        // Only return manual + awarded
        if ('manual' == methodLc && 'awarded' == statusLc) {
            ManualQuoteDTO dto = new ManualQuoteDTO();
            dto.quoteId            = (String) selectedQuote.get('quoteId');
            dto.assetCarrierName   = (String) selectedQuote.get('assetCarrierName');
            dto.providerName       = (String) selectedQuote.get('providerName');
            dto.serviceDescription = (String) selectedQuote.get('serviceDescription');
            dto.serviceId          = (String) selectedQuote.get('serviceId');
            dto.equipmentType      = (String) selectedQuote.get('equipmentType');
            dto.pricingMethod      = (String) selectedQuote.get('pricingMethod');
            dto.pricingType        = (String) selectedQuote.get('pricingType');

            String cur = (String) selectedQuote.get('currency');
            if (!String.isBlank(cur)) cur = cur.toUpperCase();
            dto.currencyMQ = cur;

            Object amt = selectedQuote.get('amount');
            if (amt != null) {
                try { dto.amount = Decimal.valueOf(String.valueOf(amt)); } catch (Exception ignore) {}
            }

            dto.status      = status;
            dto.method      = method;
            dto.createdDate = (String) selectedQuote.get('createdDate');

            result.add(dto);
        }
    }

    System.debug('Found ' + result.size() + ' manual awarded quote.');
    return result;
}

    @AuraEnabled
    public static BookingResult confirmTruckloadManualSimplified(
        String myConsVar,
        String fvShipmentId,
        String shipmentSfId,
        String pickupConfirmationNumber,
        String manualQuoteJson
    ) {
        System.debug('manualQuoteJson=>'+manualQuoteJson);
        BookingResult br = new BookingResult();
        try {
            if (String.isBlank(fvShipmentId)) throw new AuraHandledException('Freightview Shipment ID required.');
            if (String.isBlank(shipmentSfId)) throw new AuraHandledException('Salesforce Shipment Id required.');
            if (String.isBlank(pickupConfirmationNumber)) throw new AuraHandledException('Pickup Confirmation # required.');

            myConstructorWrapper mcw = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
            String token = getAccessToken(mcw.Username, mcw.childpassword, mcw.endPoint);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(mcw.endPoint + '/v2.0/shipments/truckload/' +
                EncodingUtil.urlEncode(fvShipmentId, 'UTF-8') + '/confirm');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30000);
            req.setBody(JSON.serialize(new Map<String,Object>{
                'pickupConfirmationNumber' => pickupConfirmationNumber
            }));

            Http http = new Http();
            HttpResponse res = http.send(req);
            Integer sc = res.getStatusCode();
            br.responseRaw = res.getBody();

            if (!(sc == 204 || sc == 200 || sc == 201)) {
                String msg = 'Confirm failed: ' + sc;
                try {
                    Map<String,Object> err = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                    if (err != null && err.containsKey('message')) msg = (String) err.get('message');
                } catch (Exception ignore) {}
                br.success = false;
                br.message = msg;
                return br;
            }

            Map<String,Object> manualQuote = String.isNotBlank(manualQuoteJson)
                ? (Map<String,Object>) JSON.deserializeUntyped(manualQuoteJson)
                : new Map<String,Object>();
            System.debug(manualQuote);
            Shipment__c upd = new Shipment__c(
                Id = shipmentSfId,
                Status__c = 'confirmed'
            );
            if (manualQuote.containsKey('assetCarrierName'))
                upd.Carrier__c = (String) manualQuote.get('assetCarrierName');
            if (manualQuote.containsKey('serviceDescription'))
                upd.Service_Description__c = (String) manualQuote.get('serviceDescription');
           
               // upd.Shipping_Amount__c = Decimal.valueOf(String.valueOf(manualQuote.get('amount')));
            Object amt = manualQuote.containsKey('amount') ? manualQuote.get('amount') : manualQuote.get('amountFormatted');
            if (amt != null) upd.Shipping_Amount__c = Decimal.valueOf(String.valueOf(amt).replaceAll('[^0-9\\.]', ''));
               // if (manualQuote.containsKey('currency'))
            //     upd.CurrencyIsoCode = (String) manualQuote.get('currency');

            update upd;

            br.success               = true;
            br.message               = 'Truckload shipment manually confirmed successfully.';
            br.shipmentSalesforceId  = shipmentSfId;
            br.shipmentId            = fvShipmentId;
            br.status                = 'confirmed';
            br.carrier               = upd.Carrier__c;
            br.service               = upd.Service_Description__c;
            br.amount                = upd.Shipping_Amount__c;
           // br.currencyCode          = upd.CurrencyIsoCode;
            br.ShipDetails           = upd;
            return br;

        } catch (Exception e) {
            br.success = false;
            br.message = 'Error: ' + e.getMessage();
            return br;
        }
    }
@AuraEnabled
public static BookingResult cancelTruckloadShipment(String myConsVar, String shipmentJson) {
    BookingResult br = new BookingResult();
    try {
        if (String.isBlank(myConsVar)) 
            throw new AuraHandledException('Missing connection details.');

        if (String.isBlank(shipmentJson)) 
            throw new AuraHandledException('Shipment details missing.');

        // Deserialize the passed shipment
        Map<String, Object> shipmentMap = (Map<String, Object>) JSON.deserializeUntyped(shipmentJson);
        String fvShipmentId = (String) shipmentMap.get('shipmentID__c');
        String shipmentSfId = (String) shipmentMap.get('Id');

        if (String.isBlank(fvShipmentId)) 
            throw new AuraHandledException('Freightview Shipment ID is required.');
        if (String.isBlank(shipmentSfId)) 
            throw new AuraHandledException('Salesforce Shipment ID is required.');

        // Deserialize connection info
        myConstructorWrapper mcw = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
        String token = getAccessToken(mcw.Username, mcw.childpassword, mcw.endPoint);

        // Cancel from Freightview
        HttpRequest req = new HttpRequest();
        req.setEndpoint(mcw.endPoint + '/v2.0/shipments/truckload/' +
                        EncodingUtil.urlEncode(fvShipmentId, 'UTF-8'));
        req.setMethod('DELETE');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);
        Integer sc = res.getStatusCode();
        br.responseRaw = res.getBody();

        if (!(sc == 200 || sc == 204)) {
            String msg = 'Cancel failed: ' + sc;
            try {
                Map<String, Object> err = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (err != null && err.containsKey('message')) msg = (String) err.get('message');
            } catch (Exception ignore) {}
            br.success = false;
            br.message = msg;
            return br;
        }

        //  Update the shipment status to "Cancelled"
        Shipment__c s = new Shipment__c(
            Id = shipmentSfId,
            Status__c = 'Cancelled'
        );
        update s;

        // Response back to LWC
        br.success = true;
        br.message = 'Shipment successfully cancelled in Freightview and marked as Cancelled in Salesforce.';
        br.shipmentId = fvShipmentId;
        br.shipmentSalesforceId = shipmentSfId;
        br.status = 'Cancelled';
        return br;

    } catch (Exception e) { br.success = false; br.message = 'Error: ' + e.getMessage(); return br; }
}

 public class ManualQuoteDTO {
        @AuraEnabled public String quoteId;
        @AuraEnabled public String assetCarrierName;
        @AuraEnabled public String providerName;
        @AuraEnabled public String serviceDescription;
        @AuraEnabled public String serviceId;
        @AuraEnabled public String equipmentType;
        @AuraEnabled public String pricingMethod;
        @AuraEnabled public String pricingType;
        @AuraEnabled public String currencyMQ;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String status;
        @AuraEnabled public String method;
        @AuraEnabled public String createdDate;
    }


    //end manual quote and confirmation code
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
      @AuraEnabled public List<String> errMsgs { get; set; } @AuraEnabled public String successMsg { get; set; } @AuraEnabled public String request { get; set; } @AuraEnabled public String response { get; set; } @AuraEnabled public List<Shipment_Flow__c> ShipFlows { get; set; } @AuraEnabled public Shipment__c ShipDetails { get; set; } @AuraEnabled public List<Attachment> attList { get; set; }

      public shipmentResponse() {
          errMsgs = new List<String>();
      }
  }
  public class QuoteRatesResponse {
    @AuraEnabled public List<quoteWrapper> quotes;
    @AuraEnabled public List<Object> requestedFrom;
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