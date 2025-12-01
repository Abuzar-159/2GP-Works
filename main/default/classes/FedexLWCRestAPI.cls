global with Sharing class FedexLWCRestAPI {
    @AuraEnabled  global String request_1 {get;set;}
    @AuraEnabled
    global static List<String> getSpecialServices(){ List<String> options = new List<String>(); Schema.DescribeFieldResult fieldResult = Shipment__c.Fedex_Special_Services__c.getDescribe(); List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues(); for (Schema.PicklistEntry f: ple) {options.add(f.getLabel());} return options; }

    @AuraEnabled
    global static List<String> getLabelOptions(){ List<String> options = new List<String>(); Schema.DescribeFieldResult fieldResult = Shipment__c.Label_options__c.getDescribe(); List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues(); for (Schema.PicklistEntry f: ple) {options.add(f.getLabel());} return options; }

    @AuraEnabled
    global static Contact getShiptoContact(String packId){
        system.debug('--> inside getShiptoContact packageId is :' +packId);
        //List<String> pakIds = new List<String>();
        //if(String.isNotEmpty(packId)) pakIds = (List<String>) JSON.deserialize(packId, List<String> .class);
        if(String.isNotEmpty(packId)){
            Package__c packages = new Package__c(); contact con = new contact();
            packages = [Select Id, Logistic__r.Contact__c,Name,Order__c,Order__r.Contact__c,Order__r.Contact__r.Name,Transfer_Order__c,Transfer_Order__r.Contact__c,
                        Transfer_Order__r.Contact__r.Name,Return_Merchandise_Authorisation__c ,Return_Merchandise_Authorisation__r.Name,Return_Merchandise_Authorisation__r.Return_Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__r.Name,
                        Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c,
                        Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c from Package__c where Id =:packId limit 1];

            if(packages != null){
                system.debug('packages.Order__c : '+packages.Order__c);
                if(packages.Logistic__c != null) {system.debug('packages.Logistic__r.Contact__c : '+packages.Logistic__r.Contact__c); if(packages.Logistic__r.Contact__c != null) { con = [Select Id,Name,AccountId,Account.Name,Company__c,Phone,Email from Contact where Id=:packages.Logistic__r.Contact__c]; system.debug('con : '+con); return con; } else return null; }
                else return null;
            } else return null;  } else return null;
    }

    @AuraEnabled
    global static Contact getShipFromContact(String packId){
        system.debug('--> inside getShiptoContact packageId is :' +packId);
        //List<String> pakIds = new List<String>();
        // if(String.isNotEmpty(packId)) pakIds = (List<String>) JSON.deserialize(packId, List<String> .class);
        if(String.isNotEmpty(packId)){
            Package__c packages = new Package__c(); contact con = new contact();
            packages = [Select Id, Name,Order__c,Order__r.Contact__c,Order__r.Contact__r.Name,Transfer_Order__c,Transfer_Order__r.Contact__c,
                        Transfer_Order__r.Contact__r.Name,Return_Merchandise_Authorisation__c ,Return_Merchandise_Authorisation__r.Name,Return_Merchandise_Authorisation__r.Return_Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__r.Name,
                        Logistic__r.From_Contact__c, Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c,
                        Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c from Package__c where Id =:packId limit 1];

            if(packages != null){
                system.debug('packages.Order__c : '+packages.Order__c);
                if(packages.Logistic__c != null) {system.debug('packages.Logistic__r.From_Contact__c : '+packages.Logistic__r.From_Contact__c); if(packages.Logistic__r.From_Contact__c != null) { con = [Select Id,Name,AccountId,Account.Name,Company__c,Phone,Email from Contact where Id=:packages.Logistic__r.From_Contact__c]; system.debug('con : '+con); return con; } else return null; }
                else return null;
            } else return null;
        } else return null;
    }

    @AuraEnabled
    global static myConstructorWrapper fetchInitailDetails(String ShipmentId){
        myConstructorWrapper MCW = new myConstructorWrapper();
        string credName = system.Label.FedexRestAPIName;
        String credentialFields = UtilClass.selectStarFromSObject('Credentials__c');
        MCW.fedCredentials = Database.query('select ' + credentialFields + ' from Credentials__c where (Name =: credName And Active__c = true) Limit 1');
        if(MCW.fedCredentials.size() > 0){
            MCW.parentKey =MCW.fedCredentials[0].Parent_Key__c;
            MCW.parentPassword = MCW.fedCredentials[0].Parent_Password__c;
            MCW.endPoint = MCW.fedCredentials[0].URL__c;
            MCW.accountNumber = MCW.fedCredentials[0].UPS_Account_Number__c;
            MCW.childKey = MCW.fedCredentials[0].key__c;
            MCW.childpassword = MCW.fedCredentials[0].Password_Transkey__c;
            if(Fedex.getProvinceCode(MCW.fedCredentials[0].Shipper_Province__c) != '')
                MCW.shipperProvinceCode = Fedex.getProvinceCode(MCW.fedCredentials[0].Shipper_Province__c);
            else if(MCW.fedCredentials[0].Shipper_Province__c != null && MCW.fedCredentials[0].Shipper_Province__c != '') MCW.wrapError = 'FedEx Shipping Service Unavailable : Shipper Province Code not found';
            if(Fedex.getCountryCode(MCW.fedCredentials[0].Shipper_Country__c) != '')
                MCW.shipperCountryCode = Fedex.getCountryCode(MCW.fedCredentials[0].Shipper_Country__c); else MCW.wrapError = 'FedEx Shipping Service Unavailable : Shipper Country Code not found';
        }
        else MCW.wrapError = 'FedEx Shipping Service Unavailable : Please setup FedEx credentials';

        if(ShipmentId != null && ShipmentId != ''){
            List<Shipment__c>  shipmnts = new List<Shipment__c>();
            String ShipmentRecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Shipment__c','Fedex_Shipping');
            shipmnts = Database.query('select Id, Name, Billing_Account_Number__c,Billing_Postal_Code__c,Billing_Country_Code__c,Shipment_Billing_options__c,Billing_Contact__c,Billing_Contact__r.Id,Billing_Contact__r.Name,Billing_Address__r.Id,Billing_Address__r.Name,Customer__c, Active__c, Check_In__c, Fedex_Service__c, Number_Of_Pieces_In_Shipment__c, Pickup_Requested__c, Shipment_Date__c, Shipment_Type__c, Shipping_Amount__c, Status__c, Tracking_Number__c,TrackingNumber__c, Tracking_Unique_Id__c, Unit__c, Code__c, Billing_Address__c, Customer_Contact__c, Signature_Services__c, Email_from_Third_Party__c, Shipping_Address__c, Status_Duration__c, Is_Free_Shipment__c, Reason_For_Export__c, Terms_Of_Shipment__c, Logistic__c, Carrier_Code__c, Transfer_Order__c, Purchase_Orders__c, Work_Order__c, Order__c, RecordTypeId, Product_Unit_Code__c, Pickup_Location__c, Pickup_Confirmation_Number__c, Package_Ready_Time__c,Return_Merchandise_Authorisation__c,Return_Merchandise_Authorisation__r.Name,Return_Merchandise_Authorisation__r.Address__c from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(ShipmentId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
            Shipment__c Shipment = new Shipment__c();
            if(shipmnts.size() > 0) Shipment = shipmnts[0];
            //MCW.Shipment = (Shipment.Id != null) ? Shipment : new Shipment__c();
        }
        return MCW;

    }
    @AuraEnabled
    global static addressWrap ValidateAddress(String address,String creds){
        addressWrap addWrap = new addressWrap();
        if(address != null && address != ''){
            Address__c address2validate = (Address__c) JSON.deserialize(address,Address__c.class);
            myConstructorWrapper MCW = new myConstructorWrapper();
            if(creds != null && creds != ''){
                MCW =  (myConstructorWrapper) JSON.deserialize(creds,myConstructorWrapper.class);
                String accessToken = getAccessToken(MCW.parentKey,MCW.parentPassword,MCW.childKey,MCW.childpassword,MCW.endPoint);
                if(accessToken != null){
                    String endPoint = MCW.endPoint +'/address/v1/addresses/resolve';
                    String stateProviceCode = Fedex.getProvinceCode(address2validate.State__c);
                    String countryCode = Fedex.getCountryCode(address2validate.Country__c);
                    String requestBody = '{' +
                        '"addressesToValidate": [' +
                        '{' +
                        '"address": {' +
                        '"streetLines": ["' + address2validate.Address_Line1__c + '", "' + address2validate.Address_Line2__c + '"],' +
                        '"city": "' + address2validate.City__c + '",' +
                        '"stateOrProvinceCode": "' + stateProviceCode + '",' +
                        '"postalCode": "' + address2validate.Postal_Code__c + '",' +
                        '"countryCode": "' + countryCode + '"' +
                        '}' +
                        '}' +
                        ']' +
                        '}';
                    system.debug('requestBody : '+requestBody);
                    HttpRequest request = new HttpRequest();
                    request.setEndpoint(endpoint);
                    request.setMethod('POST');
                    request.setHeader('Content-Type', 'application/json');
                    request.setHeader('Authorization', 'Bearer ' + accessToken);
                    request.setBody(requestBody);
                    Http http = new Http();
                    String httpResult = '';
                    Decimal StatusCode = 0;
                    HttpResponse response = new HttpResponse();
                    if(Test.isRunningTest()){
                        httpResult = '{"transactionId":"APIF_SV_ADVC_TxID459f2208-f24b-42cd-95c3-082b97c0b0c5","output":{"alerts":[{"code":"VIRTUAL.RESPONSE","message":"This is a Virtual Response.","alertType":"NOTE"}],"resolvedAddresses":[{"streetLinesToken":["CALLE RIOBAMBA 5680"],"city":"ROSARIO","stateOrProvinceCode":"SANTA FE","postalCode":"S2009ARN","parsedPostalCode":{"base":"S2009ARN"},"countryCode":"AR","classification":"UNKNOWN","ruralRouteHighwayContract":false,"generalDelivery":false,"customerMessages":[],"normalizedStatusNameDPV":false,"standardizedStatusNameMatchSource":"Postal","resolutionMethodName":"GENERIC_VALIDATE","attributes":{"POBox":"false","SuiteRequiredButMissing":"false","StreetPointNotApplicable":"false","InvalidSuiteNumber":"false","ResolutionInput":"RAW_ADDRESS","ResolutionMethod":"GENERIC_VALIDATE","DataVintage":"November 2022","MatchSource":"Postal","CountrySupported":"true","ValidlyFormed":"true","Matched":"true","StreetOrganizationAddress":"false","MissingOrAmbiguousDirectional":"false","StreetNameAddress":"true","StreetPointNotValidated":"false","Inserted":"false","RuralRoute":"false","PostalDataSource":"Informatica","InterpolatedStreetAddress":"false","MultiUnitBase":"false","StreetBuildingAddress":"false","StreetRange":"false","UniqueZIP":"false","StreetAddress":"false","RRConversion":"false","SuiteNotValidated":"false","ValidMultiUnit":"false","AddressType":"STANDARDIZED","AddressPrecision":"Street","MultipleMatches":"false"}}]}';
                        StatusCode = 200;
                    }
                    else {
                        response = http.send(request);
                        httpResult = response.getBody();
                        StatusCode = response.getStatusCode();
                    }
                    if (response.getStatusCode() == 200) {
                        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
                        Map<String, Object> output = (Map<String, Object>) jsonResponse.get('output');
                        List<Object> resolvedAddresses = (List<Object>) output.get('resolvedAddresses');
                        if (!resolvedAddresses.isEmpty()) {
                            Map<String, Object> addressDetails = (Map<String, Object>) resolvedAddresses[0];

                            List<Object> streetLinesTokenObjects = (List<Object>) addressDetails.get('streetLinesToken');
                            List<String> streetLinesToken = new List<String>();
                            Address__c addresstoreturn = new Address__c();
                            for (Object obj : streetLinesTokenObjects) {
                                streetLinesToken.add((String)obj);
                            }
                            String streetLines = String.join(streetLinesToken, ', '); // Join street lines if there are multiple lines
                            String city = (String) addressDetails.get('city');
                            String stateOrProvinceCode = (String) addressDetails.get('stateOrProvinceCode');
                            if(stateOrProvinceCode != null && stateOrProvinceCode  != ''){
                                List<Province_Codes__c> provinceList= [Select Id, Name, Code__c, Province__c From Province_Codes__c Where Code__c=: String.escapeSingleQuotes(stateOrProvinceCode) Limit 1]; if(provinceList != null && provinceList.size() > 0) addresstoreturn.State__c =provinceList[0].Province__c ;
                            }
                            String postalCode = (String) addressDetails.get('postalCode');String ReturnedcountryCode = (String) addressDetails.get('countryCode');

                            addresstoreturn.Address_Line1__c = (streetLinesToken.size() > 0) ? streetLinesToken[0] : '';addresstoreturn.Address_Line2__c = (streetLinesToken.size() > 1) ? streetLinesToken[1] : '';addresstoreturn.City__c = city;addresstoreturn.Postal_Code__c = postalCode;
                            if(ReturnedcountryCode != null && ReturnedcountryCode != ''){ List<Country_Codes__c> provinceList= [Select Id, Name, Code__c, Country__c From Country_Codes__c Where Code__c=: String.escapeSingleQuotes(CountryCode ) Limit 1]; if(provinceList != null && provinceList.size() > 0)  addresstoreturn.Country__c =provinceList[0].Country__c;
                            }
                            addWrap.address = addresstoreturn;
                        }

                    } else {
                        // Error handling
                        System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
                        addWrap.errMsg = 'Error: ' + response.getStatusCode() + ' ' + response.getStatus();
                    }

                }
                else  addWrap.errMsg = 'The access token not generated please retry!';

            }
            return addWrap;
        } else return null;
    }
    @AuraEnabled
    global static shipmentResponse getRates(List<Package__c> PackageItems,String consVar,String fromAddress,String ToAddress, String shipDate,String shipmentDetails,Boolean isReturnShipment){
                System.debug('By Abu FedEx getRates IsReturnShipment = ' + isReturnShipment);

        shipmentResponse res = new shipmentResponse();
        try{
        System.debug('PackageItems=>'+PackageItems);
        System.debug('consVar=>'+consVar);
        System.debug('fromAddress=>'+fromAddress);
        System.debug('ToAddress=>'+ToAddress);
        System.debug('shipDate=>'+shipDate);
        System.debug('shipmentDetails=>'+shipmentDetails);
        System.debug('isReturnShipment=>'+isReturnShipment);


        myConstructorWrapper MCW = new myConstructorWrapper();
        Address__c tAddress = new  Address__c();
        String toCountryCode = '';
        String FromCountryCode = '';
        String toProvinceCode = '';
        String FromProvinceCode = '';
        if(String.isNotEmpty(ToAddress)) {
            tAddress = (Address__c) JSON.deserialize(ToAddress,Address__c.class);
            toCountryCode = Fedex.getCountryCode(tAddress.Country__c);
            toProvinceCode = Fedex.getProvinceCode(tAddress.State__c);
        }
        Address__c fAddress = new  Address__c();
        if(String.isNotEmpty(fromAddress)) {
            fAddress = (Address__c) JSON.deserialize(fromAddress,Address__c.class);
            FromCountryCode = Fedex.getCountryCode(fAddress.Country__c);
            FromProvinceCode = Fedex.getProvinceCode(fAddress.State__c);
        }
        // if(PackageItems != null && PackageItems != '') packlist = (List<Package__c>) JSON.deserialize(PackageItems,List<Package__c>.class);

        if(consVar != null && consVar != '') MCW = (myConstructorWrapper) JSON.deserialize(consVar, myConstructorWrapper.class);
        if (MCW == null ||
            String.isBlank(MCW.parentKey) ||
            String.isBlank(MCW.parentPassword) ||
            String.isBlank(MCW.accountNumber) ||
            String.isBlank(MCW.endPoint)) {

            res.errMsgs.add('FedEx Credentials Missing: Please configure FedEx API credentials.');
            return res;
        }


        if(shipDate == null || shipDate == '') shipDate = String.valueOf(System.today());
        system.debug('shipDate : '+shipDate);
        String myDT = shipDate + ' ' + 0 + ':' + 0 +  ':' + 0;
        system.debug('myDT~>'+myDT);
        DateTime dt = datetime.valueOf(myDT);
        system.debug('dt~>'+dt);
        DateTime dtnew = datetime.newInstance(dt.year(), dt.month(), dt.day(), 0, 0, 0);
        system.debug('dtnew~>'+dtnew);
        String shipmentDate = dtnew.format('yyyy-MM-dd');
        shipDate = shipmentDate;
        String endpoint = MCW.endpoint + '/rate/v1/comprehensiverates/quotes';
            System.debug('PackageItems[0].Id -1=>'+PackageItems[0].Id);
            System.debug('parentKey=>'+MCW.parentKey);
        String token = getAccessToken(MCW.parentKey,MCW.parentPassword,MCW.childKey,MCW.childpassword,MCW.endPoint);
            System.debug('token=>'+token);
        contact shipToContact = getShiptoContact(PackageItems[0].Id);
            System.debug('PackageItems[0].Id=>-2'+PackageItems[0].Id);
        contact shipFromContact = getShipFromContact(PackageItems[0].Id);
            System.debug('PackageItems[0].Id=>-3'+PackageItems[0].Id);
        String shippingSpeed = '';
        if(isReturnShipment){
            if(PackageItems[0].Logistic__c != null && String.isNotEmpty(PackageItems[0].Logistic__c)){
                if(PackageItems[0].Logistic__r.Shipment_type_Return__c != null && String.isNotEmpty(PackageItems[0].Logistic__r.Shipment_type_Return__c)){
                    if(PackageItems[0].Logistic__r.Shipment_type_Return__c == 'FedEx' && PackageItems[0].Logistic__r.Shipping_Preferences_Return__c != null && String.isNotEmpty(PackageItems[0].Logistic__r.Shipping_Preferences_Return__c)){ ShippingSpeed = PackageItems[0].Logistic__r.Shipping_Preferences_Return__c;
                    }
                }
            }
        }else{
            if(PackageItems[0].Shipment_Service_Type__c != null && String.isNotEmpty(PackageItems[0].Shipment_Service_Type__c)) ShippingSpeed = PackageItems[0].Shipment_Service_Type__c;
        }

        JSONGenerator gen = JSON.createGenerator(true);

        // Start constructing the JSON body.
        gen.writeStartObject();

        // "accountNumber" field
        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        gen.writeStringField('value', MCW.accountNumber);
        gen.writeEndObject();

        // "requestedShipment" field
        gen.writeFieldName('requestedShipment');
        gen.writeStartObject();

        // "shipper" field
        gen.writeFieldName('shipper');
        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
         if(shipFromContact != null){
            if(shipFromContact.Name != null && shipFromContact.Name != '') gen.writeStringField('personName', shipFromContact.Name);
            if(shipFromContact.Phone != null && shipFromContact.Phone != '')gen.writeStringField('phoneNumber', shipFromContact.Phone);
            if(shipFromContact.Company__c != null &&  shipFromContact.Company__c != '') gen.writeStringField('companyName', shipFromContact.Company__c);
            else gen.writeStringField('companyName', shipFromContact.Account.Name);
        }

        gen.writeEndObject();gen.writeFieldName('address');gen.writeStartObject();gen.writeFieldName('streetLines');gen.writeStartArray();
        gen.writeString(fAddress.Address_Line1__c);
        if(fAddress.Address_Line2__c != null && fAddress.Address_Line2__c != '') gen.writeString(fAddress.Address_Line2__c);
        if(fAddress.Address_Line3__c != null && fAddress.Address_Line3__c != '') gen.writeString(fAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', fAddress.City__c);
        gen.writeStringField('stateOrProvinceCode', FromProvinceCode);
        gen.writeStringField('postalCode', fAddress.Postal_Code__c);
        gen.writeStringField('countryCode', FromCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();

        // "recipient" field
        gen.writeFieldName('recipient');
        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();

        if(shipToContact != null){
            gen.writeStringField('personName', shipToContact.Name);
            gen.writeStringField('phoneNumber', shipToContact.Phone);
            if( shipToContact.Company__c != null &&  shipToContact.Company__c != '') gen.writeStringField('companyName', shipToContact.Company__c);
            else gen.writeStringField('companyName', shipToContact.Account.Name);
        }
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();gen.writeFieldName('streetLines');gen.writeStartArray();gen.writeString(tAddress.Address_Line1__c);
        if(tAddress.Address_Line2__c != null && tAddress.Address_Line2__c != '') gen.writeString(tAddress.Address_Line2__c);
        if(tAddress.Address_Line3__c != null && tAddress.Address_Line3__c != '') gen.writeString(tAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', tAddress.City__c);
        gen.writeStringField('stateOrProvinceCode',toProvinceCode );gen.writeStringField('postalCode', tAddress.Postal_Code__c);gen.writeStringField('countryCode', toCountryCode);gen.writeEndObject();gen.writeEndObject();

        // "pickupType" field
        gen.writeStringField('pickupType', 'USE_SCHEDULED_PICKUP');
        gen.writeStringField('packagingType', 'YOUR_PACKAGING');
        gen.writeStringField('shipDatestamp', shipDate);


        // "rateRequestType" field
        gen.writeFieldName('rateRequestType');
        gen.writeStartArray();
        gen.writeString('LIST');
        gen.writeString('PREFERRED');
        gen.writeEndArray();

        // "shippingSpeed" field
        if(shippingSpeed != null && shippingSpeed != '' && shippingSpeed != '--None--') gen.writeStringField('serviceType', shippingSpeed);

        // "requestedPackageLineItems" field
        gen.writeFieldName('requestedPackageLineItems');
        gen.writeStartArray();
        for(Package__c pkg : PackageItems) {
            gen.writeStartObject();
            gen.writeFieldName('weight');
            gen.writeStartObject();
            if(pkg.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
            else gen.writeStringField('units', 'LB');
            gen.writeStringField('value', String.valueOf(pkg.Weight__c));
            gen.writeEndObject();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();

        // Get the JSON string.
        String requestBody = gen.getAsString();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setBody(requestBody);

        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n';
        headersString += 'Authorization: ' + request.getHeader('Authorization') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        res.request = requestString;

        Http http = new Http();
        HttpResponse response = new HttpResponse();
        Decimal StatusCode = 0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{"transactionId":"APIF_SV_RATC_TxID811a4069-c302-4e3d-a7c3-1709abde28da","output":{"alerts":[{"code":"VIRTUAL.RESPONSE","message":"This is a Virtual Response.","alertType":"NOTE"}],"rateReplyDetails":[{"serviceType":"FEDEX_INTERNATIONAL_PRIORITY_EXPRESS","serviceName":"FedEx International Priority® Express","packagingType":"YOUR_PACKAGING","customerMessages":[{"code":"SERVICE.TYPE.INTERNATIONAL.MESSAGE","message":"Rate does not include duties & taxes, clearance entry fees or other import fees.  The payor of duties/taxes/fees will be responsible for any applicable Clearance Entry Fees."}],"ratedShipmentDetails":[{"rateType":"ACCOUNT","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":1084.8,"totalNetCharge":1199.94,"totalVatCharge":0.0,"totalNetFedExCharge":1199.94,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":1199.94,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":115.14,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","level":"SHIPMENT","amount":57.14},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","level":"SHIPMENT","amount":36.0},{"type":"DEMAND","description":"Demand Surcharge","level":"SHIPMENT","amount":18.0},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","level":"SHIPMENT","amount":4.0}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"USD","rate":1.0},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"USD","rateScale":"US001OFA_2A_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"USD"},{"rateType":"PREFERRED_CURRENCY","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":1456.51,"totalNetCharge":1611.08,"totalVatCharge":0.0,"totalNetFedExCharge":1611.08,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":1611.08,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":154.57,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","amount":76.71},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","amount":48.33},{"type":"DEMAND","description":"Demand Surcharge","amount":24.16},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","amount":5.37}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"CAD","rate":1.34},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"CAD","rateScale":"US001OFA_2A_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"CAD"}],"operationalDetail":{"ineligibleForMoneyBackGuarantee":false,"astraDescription":"IPE","airportId":"YYZ","serviceCode":"2A"},"signatureOptionType":"SERVICE_DEFAULT","serviceDescription":{"serviceId":"EP1000000299","serviceType":"FEDEX_INTERNATIONAL_PRIORITY_EXPRESS","code":"2A","names":[{"type":"long","encoding":"utf-8","value":"FedEx International Priority® Express"},{"type":"long","encoding":"ascii","value":"FedEx International Priority Express"},{"type":"medium","encoding":"utf-8","value":"FedEx Intl Priority Express"},{"type":"medium","encoding":"ascii","value":"FedEx Intl Priority Express"},{"type":"short","encoding":"utf-8","value":"IPM"},{"type":"short","encoding":"ascii","value":"IPM"},{"type":"abbrv","encoding":"ascii","value":"LO"}],"serviceCategory":"parcel","description":"International Priority Express (IP EXP)","astraDescription":"IPE"}},{"serviceType":"FEDEX_INTERNATIONAL_PRIORITY","serviceName":"FedEx International Priority®","packagingType":"YOUR_PACKAGING","customerMessages":[{"code":"SERVICE.TYPE.INTERNATIONAL.MESSAGE","message":"Rate does not include duties & taxes, clearance entry fees or other import fees.  The payor of duties/taxes/fees will be responsible for any applicable Clearance Entry Fees."}],"ratedShipmentDetails":[{"rateType":"ACCOUNT","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":1035.6,"totalNetCharge":1148.28,"totalVatCharge":0.0,"totalNetFedExCharge":1148.28,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":1148.28,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":112.68,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","level":"SHIPMENT","amount":54.68},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","level":"SHIPMENT","amount":36.0},{"type":"DEMAND","description":"Demand Surcharge","level":"SHIPMENT","amount":18.0},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","level":"SHIPMENT","amount":4.0}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"USD","rate":1.0},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"USD","rateScale":"US001OFA_2P_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"USD"},{"rateType":"PREFERRED_CURRENCY","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":1390.45,"totalNetCharge":1541.72,"totalVatCharge":0.0,"totalNetFedExCharge":1541.72,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":1541.72,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":151.27,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","amount":73.41},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","amount":48.33},{"type":"DEMAND","description":"Demand Surcharge","amount":24.16},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","amount":5.37}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"CAD","rate":1.34},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"CAD","rateScale":"US001OFA_2P_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"CAD"}],"operationalDetail":{"ineligibleForMoneyBackGuarantee":false,"astraDescription":"IP EOD","airportId":"YYZ","serviceCode":"2P"},"signatureOptionType":"SERVICE_DEFAULT","serviceDescription":{"serviceId":"EP1000000300","serviceType":"FEDEX_INTERNATIONAL_PRIORITY","code":"2P","names":[{"type":"long","encoding":"utf-8","value":"FedEx International Priority®"},{"type":"long","encoding":"ascii","value":"FedEx International Priority"},{"type":"medium","encoding":"utf-8","value":"FedEx International Priority"},{"type":"medium","encoding":"ascii","value":"FedEx International Priority"},{"type":"short","encoding":"utf-8","value":"IPED"},{"type":"short","encoding":"ascii","value":"IPED"},{"type":"abbrv","encoding":"ascii","value":"OA"}],"serviceCategory":"parcel","description":"International Priority EOD (IP EOD)","astraDescription":"IP EOD"}},{"serviceType":"INTERNATIONAL_ECONOMY","serviceName":"FedEx International Economy®","packagingType":"YOUR_PACKAGING","customerMessages":[{"code":"SERVICE.TYPE.INTERNATIONAL.MESSAGE","message":"Rate does not include duties & taxes, clearance entry fees or other import fees.  The payor of duties/taxes/fees will be responsible for any applicable Clearance Entry Fees."}],"ratedShipmentDetails":[{"rateType":"ACCOUNT","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":899.16,"totalNetCharge":996.59,"totalVatCharge":0.0,"totalNetFedExCharge":996.59,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":996.59,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":97.43,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","level":"SHIPMENT","amount":47.88},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","level":"SHIPMENT","amount":36.0},{"type":"DEMAND","description":"Demand Surcharge","level":"SHIPMENT","amount":18.0},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","level":"SHIPMENT","amount":4.0}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"USD","rate":1.0},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"USD","rateScale":"US001OFA_5_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"USD"},{"rateType":"PREFERRED_CURRENCY","ratedWeightMethod":"ACTUAL","totalDiscounts":0.0,"totalBaseCharge":1204.89,"totalNetCharge":1335.05,"totalVatCharge":0.0,"totalNetFedExCharge":1335.05,"totalDutiesAndTaxes":0.0,"totalNetChargeWithDutiesAndTaxes":1335.05,"totalDutiesTaxesAndFees":0.0,"totalAncillaryFeesAndTaxes":0.0,"shipmentRateDetail":{"rateZone":"A","dimDivisor":139,"fuelSurchargePercent":5.0,"totalSurcharges":130.16,"totalFreightDiscount":0.0,"surCharges":[{"type":"FUEL","description":"Fuel Surcharge","amount":64.04},{"type":"ADDITIONAL_HANDLING","description":"Additional handling surcharge - weight","amount":48.33},{"type":"DEMAND","description":"Demand Surcharge","amount":24.16},{"type":"ON_CALL_PICKUP","description":"FedEx pickup","amount":5.37}],"pricingCode":"","currencyExchangeRate":{"fromCurrency":"USD","intoCurrency":"CAD","rate":1.34},"totalBillingWeight":{"units":"LB","value":120.0},"dimDivisorType":"COUNTRY","currency":"CAD","rateScale":"US001OFA_5_YOUR_PACKAGING","totalRateScaleWeight":{"units":"LB","value":120.0}},"currency":"CAD"}],"operationalDetail":{"ineligibleForMoneyBackGuarantee":false,"astraDescription":"IE EOD","airportId":"YYZ","serviceCode":"5"},"signatureOptionType":"SERVICE_DEFAULT","serviceDescription":{"serviceId":"EP1000000302","serviceType":"INTERNATIONAL_ECONOMY","code":"5","names":[{"type":"long","encoding":"utf-8","value":"FedEx International Economy®"},{"type":"long","encoding":"ascii","value":"FedEx International Economy"},{"type":"medium","encoding":"utf-8","value":"FedEx Intl Economy"},{"type":"medium","encoding":"ascii","value":"FedEx Intl Economy"},{"type":"short","encoding":"utf-8","value":"IE"},{"type":"short","encoding":"ascii","value":"IE"},{"type":"abbrv","encoding":"ascii","value":"EA"}],"serviceCategory":"parcel","description":"International Economy EOD (IE EOD)","astraDescription":"IE EOD"}}]}}';
                StatusCode = 200;
        }else {
            System.debug('else response');
            System.debug('endpoint=>'+endpoint);
            response = http.send(request);
            System.debug('response=>'+response);
            StatusCode = response.getStatusCode();
        }
        // Process the response as needed
        if (StatusCode == 200) {
            // Successful response
            String responseBody = response.getBody();
            res.response = responseBody;

            // Process responseBody
        }
        else {
            // Error handling
            System.debug('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
            System.debug('response body=>'+response.getBody());
            res.errMsgs.add('Error: ' + response.getStatusCode() + ' ' + response.getStatus());
        }
        return res;
        }catch(Exception e){
            System.debug('get rates error=>'+e.getMessage()+' and '+e.getLineNumber());
        }
        System.debug('res - Abu = ' + res);
        return res;
    }

    @AuraEnabled
    global static shipmentResponse shippingRequestResponse(List<Package__c> packList,String fromAddress,String ToAddress,string fromContact,string toContact,String ShipDateStamp, String myConsVar, String Shipment, String rateService,String rateCurrency,boolean isReturnShipment,List<Package_List__c> packageItems,String masterShipmentId){
        System.debug('By Abu FedEx shippingRequestResponse IsReturnShipment = ' + isReturnShipment);
        rateCurrency = 'USD';
        System.debug('packageItems length=>'+packageItems.size());
        System.debug('packageItems =>'+packageItems);
        Shipment__c ship = (Shipment__c) JSON.deserialize(Shipment,Shipment__c.class);shipmentResponse res = new shipmentResponse();

        if(ship.Description__c == null) ship.Description__c = 'This is Description';

        myConstructorWrapper MCW = new myConstructorWrapper();
        Address__c tAddress = new  Address__c();String toCountryCode = '';String toProvinceCode = '';String FromCountryCode = '';String FromProvinceCode = '';
        contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);//getShiptoContact(packList[0].Id);
        contact shipToContact  = (Contact) JSON.deserialize(toContact, Contact.class);//getShipFromContact(packList[0].Id);
        // List<Package_List__c> packageItems = [Select Id,Name,Package__c,Quantity__c,Package__r.Weight_Unit__c ,Package__r.Weight__c,Order_Product__c,Order_Product__r.OrderItemNumber,Purchase_Line_Items__c,Purchase_Line_Items__r.Name,Order_Product__r.Product2.Name,Purchase_Line_Items__r.Product__r.Name,Order_Product__r.Product2.Commodity_Code__c,Purchase_Line_Items__r.Product__r.Commodity_Code__c,Order_Product__r.Product2.Declared_Shipment_Value__c,Purchase_Line_Items__r.Product__r.Declared_Shipment_Value__c from Package_List__c where Package__c != null And Package__c IN:packList];

        if(String.isNotEmpty(ToAddress)) {
            tAddress = (Address__c) JSON.deserialize(ToAddress,Address__c.class);
            toCountryCode = Fedex.getCountryCode(tAddress.Country__c);
            toProvinceCode = Fedex.getProvinceCode(tAddress.State__c);
        }
        Address__c fAddress = new  Address__c();
        if(String.isNotEmpty(fromAddress)) {
            fAddress = (Address__c) JSON.deserialize(fromAddress,Address__c.class);
            FromCountryCode = Fedex.getCountryCode(fAddress.Country__c);
            FromProvinceCode = Fedex.getProvinceCode(fAddress.State__c);
        }
        // if(PackageItems != null && PackageItems != '') packlist = (List<Package__c>) JSON.deserialize(PackageItems,List<Package__c>.class);
        if(myConsVar != null && myConsVar != '') MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
        if(ShipDateStamp == null || ShipDateStamp == '') ShipDateStamp = String.valueOf(System.today());
        system.debug('ShipDateStamp : '+ShipDateStamp);
        String myDT = ShipDateStamp + ' ' + 0 + ':' + 0 +  ':' + 0;
        system.debug('myDT~>'+myDT);
        DateTime dt = datetime.valueOf(myDT);
        system.debug('dt~>'+dt);
        DateTime dtnew = datetime.newInstance(dt.year(), dt.month(), (dt.day()), 0, 0, 0);
        system.debug('dtnew~>'+dtnew);
        String shipmentDate = dtnew.format('yyyy-MM-dd');
        ShipDateStamp = shipmentDate;
        String endpoint = MCW.endpoint + '/ship/v1/shipments';
        system.debug('endpoint : '+endpoint);
        String token = getAccessToken(MCW.parentKey,MCW.parentPassword,MCW.childKey,MCW.childpassword,MCW.endPoint);
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeStringField('labelResponseOptions', 'LABEL');
        gen.writeStringField('CustomerTransactionId', tAddress.Contact__r.Name);
        gen.writeFieldName('requestedShipment');
        gen.writeStartObject();
        gen.writeFieldName('shipper');

        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(shipFromContact != null){
            gen.writeStringField('personName', shipFromContact.Name);
            gen.writeStringField('phoneNumber', shipFromContact.Phone);
            if(isReturnShipment && packList.size() > 0 && packList[0].Logistic__c != null && packList[0].Logistic__r.Account__c != null && packList[0].Logistic__r.Account__r.Name != null && packList[0].Logistic__r.Account__r.Name != ''){
                gen.writeStringField('companyName', packList[0].Logistic__r.Account__r.Name);
            }
            //else if( shipFromContact.Company__c != null &&  shipFromContact.Company__c != '') gen.writeStringField('companyName', shipFromContact.Company__c);
            else if( shipFromContact.Company_Name__c != null &&  shipFromContact.Company_Name__c != '') gen.writeStringField('companyName', shipFromContact.Company_Name__c);
            else gen.writeStringField('companyName', shipFromContact.Account.Name);
        }
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        gen.writeFieldName('streetLines');
        gen.writeStartArray();
        gen.writeString(fAddress.Address_Line1__c);
        if(fAddress.Address_Line2__c != null && fAddress.Address_Line2__c != '') gen.writeString(fAddress.Address_Line2__c);
        if(fAddress.Address_Line3__c != null && fAddress.Address_Line3__c != '') gen.writeString(fAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', fAddress.City__c);gen.writeStringField('stateOrProvinceCode', FromProvinceCode);
        gen.writeStringField('postalCode', fAddress.Postal_Code__c);
        gen.writeStringField('countryCode', FromCountryCode);
        gen.writeEndObject();
        gen.writeFieldName('tins');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('number', '123456789');
        gen.writeStringField('tinType', 'PERSONAL_STATE');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();

        gen.writeFieldName('recipients');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(shipToContact != null){
            gen.writeStringField('personName', shipToContact.Name);
            gen.writeStringField('phoneNumber', shipToContact.Phone);
            if(!isReturnShipment && packList.size() > 0 && packList[0].Logistic__c != null && packList[0].Logistic__r.Account__c != null && packList[0].Logistic__r.Account__r.Name != null && packList[0].Logistic__r.Account__r.Name != ''){
                gen.writeStringField('companyName', packList[0].Logistic__r.Account__r.Name);
            }
            //else if(shipToContact.Company__c != null &&  shipToContact.Company__c != '') gen.writeStringField('companyName', shipToContact.Company__c);
            else if( shipToContact.Company_Name__c != null &&  shipToContact.Company_Name__c != '') gen.writeStringField('companyName', shipToContact.Company_Name__c);
            else gen.writeStringField('companyName', shipToContact.Account.Name);
        }
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        gen.writeFieldName('streetLines');
        gen.writeStartArray();
        gen.writeString(tAddress.Address_Line1__c);
        if(tAddress.Address_Line2__c != null && tAddress.Address_Line2__c != '') gen.writeString(tAddress.Address_Line2__c);
        if(tAddress.Address_Line3__c != null && tAddress.Address_Line3__c != '') gen.writeString(tAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', tAddress.City__c);gen.writeStringField('stateOrProvinceCode',toProvinceCode );
        gen.writeStringField('postalCode', tAddress.Postal_Code__c);
        gen.writeStringField('countryCode', toCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeStringField('shipDatestamp', ShipDateStamp);
        gen.writeStringField('serviceType', rateService);
        gen.writeStringField('packagingType', 'YOUR_PACKAGING');
        gen.writeStringField('pickupType', 'USE_SCHEDULED_PICKUP');
        gen.writeBooleanField('blockInsightVisibility', false);
        gen.writeNumberField('totalPackageCount', packList.size());
        contact BillCon = new contact();
        String BillConID = ship.Billing_Contact__c;
        if(BillConID  != '' && BillConID != null){
            BillCon = [Select Id,Name,Company__c,Phone,AccountId,Account.Name,Account.Phone from contact where Id =:BillConID limit 1];
        }

        Decimal totalWeight = 0;
        Decimal totalDeclaredValue = 0;
        Decimal estimatesShipAmount = 0;
        Decimal InsuranceCharges = 0;
        Decimal ShipVATAmount = 0;
        for(Package__c p : packList){
            totalWeight += p.Weight__c;
            totalDeclaredValue += p.Declared_Value__c;
            if(p.Order__c != null){
                if(p.Order__r.Estimated_Shipping_Amount__c != null) {
                    estimatesShipAmount += p.Order__r.Estimated_Shipping_Amount__c;
                }
                if(p.Order__r.Shipping_VAT__c != null) { ShipVATAmount += p.Order__r.Shipping_VAT__c; }
                if(p.Order__r.Insurance_Charges__c != null) { InsuranceCharges += p.Order__r.Insurance_Charges__c; }
            }
        }

        gen.writeFieldName('TotalWeight');
        gen.writeStartObject();
        if(packList[0].Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
        else gen.writeStringField('units', 'LB');
        gen.writeNumberField('value', totalWeight);
        gen.writeEndObject();
        gen.writeFieldName('shippingChargesPayment');
        gen.writeStartObject();
        gen.writeStringField('paymentType', ship.Shipment_Billing_options__c);
        gen.writeFieldName('payor');
        gen.writeStartObject();
        gen.writeFieldName('responsibleParty');
        gen.writeStartObject();
        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('value', MCW.accountNumber);
        else gen.writeStringField('value', ship.Billing_Account_Number__c);
        gen.writeEndObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(ship.Shipment_Billing_options__c == 'SENDER' && shipFromContact != null) gen.writeStringField('personName', shipFromContact.Name);
        else if(BillCon != null && BillCon.Name != null) gen.writeStringField('personName', BillCon.Name);
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        Address__c biladd = new Address__c();
        String billcountrycode = '';
        string billAddId = ship.Billing_Address__c;
        if(ship.Billing_Country_Code__c != null) {  billcountrycode = ship.Billing_Country_Code__c; }
        else if(billAddId != null && billAddId != ''){
            biladd = [Select Id,Name,Address_Line1__c,Address_Line2__c,City__c,State__c,Postal_Code__c,Country__c from Address__c where Id = :ship.Billing_Address__c  limit 1];
            billcountrycode = Fedex.getCountryCode(biladd.Country__c);
        }
        if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('countryCode', FromCountryCode);
        else if(ship.Billing_Country_Code__c != null) {
            gen.writeStringField('countryCode', billcountrycode);
        }

        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('shipmentSpecialServices');
        gen.writeStartObject();
        gen.writeFieldName('specialServiceTypes');
        gen.writeStartArray();
        if(isReturnShipment){ gen.writeString('RETURN_SHIPMENT'); }
        else if(ship.Fedex_Special_Services__c != null && ship.Fedex_Special_Services__c != '') gen.writeString(ship.Fedex_Special_Services__c);
        gen.writeEndArray();
        if(isReturnShipment){
            gen.writeFieldName('returnShipmentDetail');
            gen.writeStartObject();
            gen.writeStringField('returnType', 'PRINT_RETURN_LABEL');
            gen.writeEndObject();
        }
        gen.writeEndObject();
        if(FromCountryCode != toCountryCode){
            gen.writeFieldName('customsClearanceDetail');gen.writeStartObject();gen.writeFieldName('commercialInvoice');gen.writeStartObject();gen.writeFieldName('comments');gen.writeStartArray();gen.writeString('FEDEX BUSINESS');gen.writeEndArray();gen.writeFieldName('customerReferences');gen.writeStartArray();gen.writeStartObject();gen.writeStringField('customerReferenceType', 'CUSTOMER_REFERENCE');gen.writeStringField('value', '123456789');gen.writeEndObject();gen.writeEndArray();
            gen.writeFieldName('taxesOrMiscellaneousCharge');gen.writeStartObject();gen.writeNumberField('amount', ShipVATAmount);gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeFieldName('freightCharge');gen.writeStartObject();gen.writeNumberField('amount', estimatesShipAmount);gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeEndObject();gen.writeFieldName('dutiesPayment');gen.writeStartObject();gen.writeFieldName('payor');gen.writeStartObject();gen.writeFieldName('responsibleParty');gen.writeStartObject();gen.writeFieldName('address');gen.writeStartObject();
            if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('countryCode', FromCountryCode);
            else if(ship.Billing_Country_Code__c != null) { gen.writeStringField('countryCode', billcountrycode);
            }
            gen.writeEndObject();gen.writeFieldName('contact');gen.writeStartObject();
            if(ship.Shipment_Billing_options__c == 'SENDER') { gen.writeStringField('personName', shipFromContact.Name);
            }
            else if(BillCon != null) gen.writeStringField('personName', BillCon.Name);
            gen.writeEndObject();gen.writeFieldName('accountNumber');gen.writeStartObject();
            if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('value', MCW.accountNumber);
            else gen.writeStringField('value', ship.Billing_Account_Number__c);
            gen.writeEndObject();gen.writeEndObject();gen.writeEndObject();gen.writeStringField('paymentType', ship.Shipment_Billing_options__c);gen.writeEndObject();gen.writeFieldName('documentContent');gen.writeString('NON_DOCUMENTS');gen.writeFieldName('commodities');gen.writeStartArray();
            for(Package_List__c pl :packageItems ){
                gen.writeStartObject();gen.writeFieldName('unitPrice');gen.writeStartObject();
                if(pl.Order_Product__c != null && pl.Order_Product__r.Product2.Declared_Shipment_Value__c != null) gen.writeNumberField('amount',  pl.Order_Product__r.Product2.Declared_Shipment_Value__c);
                else gen.writeNumberField('amount',  0);
                gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeNumberField('numberOfPieces', Integer.valueOf(pl.Quantity__c));
                System.debug('entered Order_Product__c==='+pl.Order_Product__c);
                if(pl.Order_Product__c != null) {
                    System.debug('entered Order_Product__c != null');
                    gen.writeStringField('description', pl.Order_Product__r.Product2.Name);
                }else if(pl.Return_Merchandise_Authorisation__c != null){
                    System.debug('entered Return_Merchandise_Authorisation__c != null');
                    gen.writeStringField('description', pl.RMA_Line_Item__r.Ord_Item__r.Product2.Name);
                }
                gen.writeNumberField('quantity', Integer.valueOf(pl.Quantity__c));gen.writeStringField('quantityUnits', 'EA');gen.writeFieldName('customsValue');gen.writeStartObject();
                if(pl.Order_Product__c != null && pl.Order_Product__r.Product2.Declared_Shipment_Value__c != null) gen.writeNumberField('amount',  pl.Order_Product__r.Product2.Declared_Shipment_Value__c);
                else gen.writeNumberField('amount',  0);
                gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeStringField('countryOfManufacture', FromCountryCode);gen.writeFieldName('weight');gen.writeStartObject();
                if(pl.Package__r.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
                else gen.writeStringField('units', 'LB');
                if(pl.Logistic_Line_Item__c != null && pl.Logistic_Line_Item__r.Product__r.Weight__c >= 0)  gen.writeNumberField('value', pl.Logistic_Line_Item__r.Product__r.Weight__c);
                else gen.writeNumberField('value', pl.Package__r.Weight__c);
                gen.writeEndObject();gen.writeEndObject();

            }
            gen.writeEndArray();
            if(isReturnShipment) gen.writeStringField('purpose', 'REPAIR_AND_RETURN');
            else gen.writeStringField('purpose', Ship.Reason_For_Export__c);
            gen.writeFieldName('recipientCustomsId');gen.writeStartObject();gen.writeStringField('type', 'PASSPORT');gen.writeStringField('value', '12345678');gen.writeEndObject();gen.writeFieldName('customsOption');gen.writeStartObject();gen.writeStringField('type', 'OTHER');
            if(isReturnShipment) gen.writeStringField('description', 'RETURN LABEL');
            else  gen.writeStringField('description', 'Sample');
            gen.writeEndObject();gen.writeFieldName('totalCustomsValue');gen.writeStartObject();gen.writeNumberField('amount', totalDeclaredValue);gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeFieldName('insuranceCharge'); gen.writeStartObject();gen.writeNumberField('amount', InsuranceCharges);gen.writeStringField('currency', rateCurrency);gen.writeEndObject();gen.writeEndObject();
        }


        gen.writeFieldName('labelSpecification');
        gen.writeStartObject();
        if(packList[0].Thermal_Labels__c){ gen.writeStringField('imageType', 'ZPLII');gen.writeStringField('labelStockType', 'STOCK_4X85_TRAILING_DOC_TAB');
        }
        else{
            gen.writeStringField('imageType', 'PDF');
            gen.writeStringField('labelStockType', 'PAPER_85X11_TOP_HALF_LABEL');
        }

        gen.writeEndObject();

        gen.writeFieldName('rateRequestType');
        gen.writeStartArray();
        gen.writeString('LIST');
        gen.writeEndArray();
        gen.writeFieldName('requestedPackageLineItems');
        gen.writeStartArray();
        for (Package__c pl :packList) {
            gen.writeStartObject();
            gen.writeFieldName('insuredValue');
            gen.writeStartObject();
            gen.writeStringField('Currency', rateCurrency);
            if(pl.Order__r.Insurance_Charges__c != null && pl.Order__r.Insurance_Charges__c > 0) gen.writeNumberField('Amount', pl.Order__r.Insurance_Charges__c);
            else gen.writeNumberField('Amount', 0);
            gen.writeEndObject();
            gen.writeFieldName('weight');
            gen.writeStartObject();
            if(pl.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
            else gen.writeStringField('units', 'LB');
            gen.writeNumberField('value', pl.Weight__c);
            gen.writeEndObject();
            gen.writeFieldName('dimensions');
            gen.writeStartObject();
            gen.writeNumberField('length', pl.Length__c);
            gen.writeNumberField('width', pl.Width__c);
            gen.writeNumberField('height', pl.Height__c);
            if(pl.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'CM');
            else gen.writeStringField('units', 'IN');
            gen.writeEndObject();
            gen.writeFieldName('packageSpecialServices');
            gen.writeStartObject();
            gen.writeFieldName('specialServiceTypes');
            gen.writeStartArray();
            gen.writeString('SIGNATURE_OPTION');
            gen.writeEndArray();
            gen.writeStringField('signatureOptionType', 'SERVICE_DEFAULT');
            gen.writeEndObject();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();

        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        gen.writeStringField('value', MCW.accountNumber);
        gen.writeEndObject();
        gen.writeEndObject();

        String jsonString = gen.getAsString();


        // Print the JSON string
        System.debug(jsonString);


        //return jsonString;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setBody(jsonString);

        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n';
        headersString += 'Authorization: ' + request.getHeader('Authorization') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        res.request = requestString;
        //return res;

        Http http = new Http();
        Decimal StatusCode = 0;
        HttpResponse response = new HttpResponse();
        string httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{\"transactionId\":\"APIF_SV_SHPC_TxID3078dc8d-3fb3-413e-9134-790bb97352f8\",\"output\":{\"alerts\":[{\"code\":\"VIRTUAL.RESPONSE\",\"message\":\"ThisisaVirtualResponse.\",\"alertType\":\"NOTE\"}],\"transactionShipments\":[{\"masterTrackingNumber\":\"794903800925\",\"serviceType\":\"FEDEX_PRIORITY_EXPRESS\",\"shipDatestamp\":\"2023-12-05\",\"serviceName\":\"FedEx®PriorityExpress\",\"pieceResponses\":[{\"masterTrackingNumber\":\"794903800925\",\"packageSequenceNumber\":1,\"trackingNumber\":\"794903800925\",\"additionalChargesDiscount\":0.0,\"netRateAmount\":2653.04,\"netChargeAmount\":0.0,\"netDiscountAmount\":0.0,\"packageDocuments\":[{\"contentType\":\"LABEL\",\"copiesToPrint\":1,\"encodedLabel\":\"JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMyAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL091dGxpbmVzCi9Db3VudCAwCj4+CmVuZG9iagozIDAgb2JqCjw8Ci9UeXBlIC9QYWdlcwovQ291bnQgMwovS2lkcyBbMTggMCBSIDE5IDAgUiAyMCAwIFJdCj4+CmVuZG9iago0IDAgb2JqClsvUERGIC9UZXh0IC9JbWFnZUIgL0ltYWdlQyAvSW1hZ2VJXQplbmRvYmoKNSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iago2IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0hlbHZldGljYS1Cb2xkCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKNyAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EtT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjggMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhLUJvbGRPYmxpcXVlCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKOSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9Db3VyaWVyCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTAgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1Cb2xkCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTEgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1PYmxpcXVlCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTIgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1Cb2xkT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEzIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLVJvbWFuCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTQgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvVGltZXMtQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE1IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUl0YWxpYwovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE2IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUJvbGRJdGFsaWMKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNyAwIG9iaiAKPDwKL0NyZWF0aW9uRGF0ZSAoRDoyMDAzKQovUHJvZHVjZXIgKEZlZEV4IFNlcnZpY2VzKQovVGl0bGUgKEZlZEV4IFNoaXBwaW5nIExhYmVsKQ0vQ3JlYXRvciAoRmVkRXggQ3VzdG9tZXIgQXV0b21hdGlvbikNL0F1dGhvciAoQ0xTIFZlcnNpb24gNTEyMDEzNSkKPj4KZW5kb2JqCjE4IDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMSAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjE5IDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMiAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjIwIDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMiAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjIxIDAgb2JqCjw8IC9MZW5ndGggMjU3NgovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdIAo+PgpzdHJlYW0KR2F0PS4+QWtJayduLXNccyQuXFtdMExTV2dIIj9iUnBvKSktJyU/NzY/YTZ1UWI/b09NP1tlJEJZM0szbW1nOT1BV11ZUyRcaU1XXkEvOGIKckdYYUE6WDNeJjlKRl0xNzI3WFQ+MW06MSpIPjU7P2loNEwxcDNrKSp1NkxHWS5CQ0phbk5qam46ZV02RlJZI1xERERoT207V2ZHJFBdLSgKTzsuNS1KcDlLPT9MQVJePzxKI25tZTktbVtKU2lKKSRMXydIXyRNIScrSzUiRUo2XVlGcnFPY1MpKmVvbzVBaSY/ZC0rYUwhYzYsQURyczoKcS9jNFhILCNpWCRORkJzKD8tVTBsbF9uNCYxXGlfPlhqLzw/LmktaGRvPUopPj84XGlMJDNxMSJga2JmbWJiLDdlN3VPYFlFWXA3SHU3XWcKKHFpLWYwIUJLVl5ZVzZGUkMkI2A/Q3Rycj4oIl5uMG8oQGM7LU8uS1ojXi9hVD4lay5KLDhtL1deOz9XcGZMU1k9WSwvXl8uJkpWZzxRbikKZUNSOilSbEdhKlhzPElzJlVBRVQ9RSIzNDwiPTk1XEBdRy1fU0BBN19UI2M6QFNTQFFvQS9pKVVgJUYjWjlDY2Y2cTAuNVNyVVhnQGwvTjoKUVEyOFNOV1JySCIrbStCWkteXWlYZVFVSEF0bWBfWGAjRT9rRipBZixfYSsmUi4/QnRmRzpQWXA7SWJvOFQ/T2AvZyFuTFlpQltAbkAuMEYKbGgqYEw9JypUNEFwJllCTlI4Q2U0LyshRyNLZnQnY1c5J0VMRjxydVVnRFk/ZzpZK0laVmU/ck8jT1EmLVNgL0FXNSJkJm8rK1hWWWZCU1QKVC9TOSJXVEBtJlNhWiQ0R29FN0BjczlKVSlLXl1ERj5yTzFdQSdzams0TilHX1VuWDlSYXA/PmMoUV1XSF5KV0VtY1VMdV4nRStvMDM7NVIKalAjTk1mIlpJO11OXFVAajRAdWM5ZlozTnJOSk5zPGo9Yy9UJWFYMS10OD5xNl9ycU0zXDY2T0NYRyNUJ20ySUwjJEA2NiRNKmxkREVWb10KbTMhQSssaS5YajpaUVVmYk1EVylZTVslKF1tNmZFQSdIPG5DXE40MC1qY1YmVjQ5QjpUby42VFtZSFxhXFw+VU8tKys1al1HZDxRbkNJbEIKSzVHRjshQnEjb09WIXMqKGRacyloWWZwMG1lbmMjMzktcFA4WzouOldbRWJhTyooSS1KKlVGWik3XnM3ZnB0LV0pQE9ERVFJZ2IsKytjPC4KY210LFYudTUiPD5tKytYbUZnaTpjSkFCVEIrKkUoJGNsPHVCazpzUGc+a0g5IyokXDg+PmNRNDVcSzB1cGxCJ0dxZSQ6WCVeZWtCbFJDbzwKMEtqZSoxaikyREo2YyNpaHFLaz8iamNDLCtjRSk6UFlQc2Y2dDQqK1VeQiZcUD4mXVQ7ZlFAJEYmLFZkbE8lRCguNnU6LlBzJmBIUFk1aloKMi9eY18ocSJMUCshIWopQmw3aHNXYzNUZk1lNyMqV2FNSjNaRnNxTUVFdGtDPVdhcTlPYyZwdW5qMCFsal0mYGVMI05nPC1ILmI+aSlgXU4KS2M+c1NFT2dsS3BJVTwkVGQtSWUlSSwwWFUyMUFmTWIiLjtfcHU3XzVtRzsuWkpWQyFLJUJCT09yRCxFOyxrRWBMX2U0b2Q8N3JZXmQwVWsKL1glSVc+Ol9rIU0qNCdcSj42OWNcMm1wNy1IVHNHbEFEVG1VS1NObFQhU1dGZzAjJ0MvJDA5PVckcSJaRVdCVU9wZDsyY01Bajk9OzZFI2gKODFCQzROVShgJyMmbVwvOUovLT5KRTk4Vi5oYEJNVyRvLUleZykwbUs1JTUyV1BYV3A9RytGUyNJJCNLSko3aXNwc20vV1EqPmJbPy0+NmgKWFpXSmNTdTxQZVJULG0lRS5FKEdpMiVzZyomZkRTTm06Oi8oPF51aGxVXCUrSz9ZRSdWcG9mQilnW0h0WHQtS2dOVlxNKm87TkJYYGNfSUQKKiZfT21bVWhHZi1ALSVfXT8rIlM3bDxuQ1tgOGQ+TTVsKkQ+L2A1c0hnYVtKWi82KC1pK1BBYD9IZzdPT2ouaTMyaztHUlliNGY+P2xwU2QKWixVXD1XLkNfPDBKUzwoNFp0NShmJVAiPGVBMEopXnNKR2pWaV06czhXcGZkJDkwUmRqcGUrNWxkQk9bSyRJYyFAYDRTci0tJDprVzRUPDkKIixCPGJrcD9OP05CTSZZZFEpMiFUNVxdVD9LMCRhRzM9WiIycUE0TjNtXklnS1BBSygoPiJnbU5aMiJpVk82R14qMSFcaiJbZTdnRjppQz4KQEVTalordF9XZVoya3JxYWo9UVMiLU9OSEdJSXI8SjplIixHPkZfSCNiKVRXZDwvQ3QqN1lEZkBjJEgrNCslLkpHIiNFSEA4V15kMCpnazwKXDZnRXVec1RCKnFcJzpVay9bX15tPWMjLVcpZXBOTj1PU1xxJ2IoUFoya3BcKCE+ciJUU09mKl0/YVJ0XnFpQHJEKDNvNEI2dSIzbzJXOnQKOCw2OGlfcGJcQVJzKCFxIyopbEpiVHRtQGE6aksjaCguWHRpMzRWdTlZKTosZVxaIUA+dTs+VVpyRjdeJWxeNUM2SmNtTldjNF5vWXFJZ0gKMSJgQ1pTbUBuJWkrUHIrUW5FWyQ9NXVibSQ+Kz4zLXRGTTBmJEtVWyIsQj1VTTNAbTg2VHMrTzdCXlpfUjJdVHFUU2MjOnF1MmVGIyZyJ2QKJktOJCMndVZAXT8vbnFwZDI3cEIuXThwSGZJcGM2S2M+Lkk3UmZ1JGQwYktWaC1GSEspYD0wX0gxYUZNOUlvPHJHX1BHamIlRUgxTikrKEAKa2FtaXJgXnJlIiZAVWZNVnU5ZF1eOjBmXTVLY1AlSGlvbFk6SDdnT2xlQ2ZRcFM0MSxcNF0+PihOSDtnOVQiLixOKEE5PTdCVWNqIlU4aiEKK01RIXUhZ0JyQydtVVQ7QmopTWVvKTslWjc/dGJGWWAlTjM2Tlo6RFxBITw7JUxvI1ZqOV4xMCxpSVIxIVF1SGFbK29PP1Q7QipMZ0k6PD0KLS5EREUuLjpdUkRjbTg8cW9gO2cxPDRIMkgpIl1bP1MyakI9U3VzLkAuQThNSDdzZF8xP2c/Pk0wWWlWSDFWXS4/Im0tTUlZQD4oXldoOFIKSixdJzJMSGtjN1gmIllnLTgjXWlLZSoxRVhPcitGPWFwMD5PYztBb25KO0JyL25WN0xjJFxUVylVam4/SHQkXjREZ2MnSlR1VzMhLjpsKE8KZXBFc14xUiVoL29CMElGclVyTW5kXzNKcUkySnVeYSUlYFJuQi9eU2xTNjQ5QGonKHBxYGZHPnI/JythWWZRfj4KZW5kc3RyZWFtCmVuZG9iagoyMiAwIG9iago8PCAvTGVuZ3RoIDIyNjIKL0ZpbHRlciBbL0FTQ0lJODVEZWNvZGUgL0ZsYXRlRGVjb2RlXSAKPj4Kc3RyZWFtCkdhdD0uRDAkQEwmSDspOHJlImhaVjlEY0BnPTw3PTNVbkRfIj1MU2RQU3ExaC0nV1FZVGgzdGRycWBlYyo4PVNuaVJWVGBrNDc9IUJOUCdUCmgyK0NMJD1OWzpOKTlcLE4zVXIjMS9bL2pXUz1LJGQ+Nz9wRHAzRTU4I3QlZCc7TToqSTJFLWM8clwvRDs4QFs/WkRgMmMlMzBtLyQmaHMlCkFcUV5mOEghZTxSJTtPYkMsUikuKEEiTSdlZyQ5ITUvZCk8b3VGIjY4WkFoP1RSTUBdblp1RTRxdEpSYW05cnMuKmlNaTpoSHRbb085P1VxClFIYWcyL0NcMms+cjlhJDE1R0JDPFZaJjs1MyFeWmM9Y2FUTXAnZk9vU0hIdSJKRVg8K2A3TVpcc1lKSi1ZaD1eVCpgPkxTIWE9Q0VvPCgnCnJJNnF0TmcwWExNJ0NaTy1eMl5rLC9oQjRbZl5HWW87QWM9WDBMQSk2PWtKMiUoK0NtbG5OVUIjSChodCVudTVVM2ROTktsaydbSE9VSVg9ClwzKWhuXlVcVSI7I0tEdHBILGpoRFJESiRpVk9WN1YyaUozUyJfZEk5NiJ1bkhiSlNdKGNXI1pWImolXGBgXiQlVVJHT0JGLzBqOENZUCNXCnI6cC4qMjE5W3UyLS9ZNGJxVFw2ZTM6bGhWLSlSL15dKlZMYl1EISxYTTQ/aVJ1RGJCNClKSVNvWXFjNCZtPT5QTDJhXTczJ01cNEVXMVBnCk04UnAmISUvXGsqWzRgMmA4SV87RyNMTV5dKG4kKmBWVSkiVllKUipyKjRBZWo0YjBCKlwqb1dYO1hfTypRQlAjMkdDMDArYFlvaVViLCQzCjUkLDdVIi8lTSZMKHE7XiUsQnNFWmpqal1VOSwyWCFSIUJiKFg7TDpFbjhIOXI8NlFEbCRdK0Q1SG5zcms6aiVoPShNPUoxOnJcRlFKOUw4CmBzN1hLUl4xRWI9OUBOW1hmXyRzKk8kUEE3Vy84XTNWQ15uJkxSX0sjQSU1WlssVjQuYGQoUDhdZj4zOCpxJUxQZElMLi9MYyI2SylXNkBmCll1VDclP3BZYTc5dGxTK0pLcT4xJ3EjLChQPGolSF0tRnAlSSNPVWllQ1tOJiI7ZFcyV1UtQmpbUSlYQm9nUTVNYGAqTyE6ZFBjQmA2am5hClVfclsjVS9KZDslV2dyTEItPmVGTWo8TltANyJhXXA7RWBlUmxPYCFeX043PS1GPixhRyRZVyhvJ0guP2RnREpkKUswYD9sOj0vRWFUZ00nCmR0ODtAPVdNUGwmSSNtNSMjaW51P3BZYTcwa0BiXzhFZGllN0FiU0FBXSI7TDgqY2A/USxHK1taNjhYIV02U10vUDRhQk5OUmZhXV5ndSIhCmVCZmRXOV1Gais3ISp0bU1ISEVpSDNZNj9WQUxobFBWQU5LIWNMP1hNdVxkWDMzJ288I25wTCtcZ0NsciRIPDNVJDBNcEpQRE04dGY5QHRfCiR1KSZWQmNbKi1FX11TRSRDRllFa0kxPWtUVG1LIk9YWFspKSphcHInZSNiSGtdNHU+ZV9pVT9DYWlidEUpKCJBO18pOUMpNjtFcT5SciYnCilaRXMnLjo9cC9WOWo+c2NhYVQhQzxgVy8kIlsjRDxlWjNgbGFzOWBSTSRzMmlFYkg5VCU4T1gkPVVFZEYtNkA0W0FkVjMlbypsRSMyR2wrCmR0PGlmJ1NqJmMmZ2lsOD8hXnEuJkQ/VD1vXWEwdUthZDEwWTwwdFtDMGRgajhTKWpaTyZYUldFKUlrRWVzMlZIbUpPXyYrSSJpb2AwbTl0Ci9iWGBeaSxXMD4uV0E6RGRcJVo1SytlUzglLWhqcjMybUghbCNTLkUzKClvQSo6dEM9WCRLZy4+YCJYT2BAYS8lRHBBKWplU2s9PVUiZi06CmNGLWR1M1FUTUguUVNrTi5SXHAjPm45W1tqT1RDRlM0ZVsnU1JSLzVNWU9XOkU9KFowTSFBay5FKU5BaEJGRUZFJysubWtgP0MjMGs4ZGErCiQnZEpZP3NEKC88ZGkiV1I/cVBEU1VIbClMLFpNIz9AZi5YalBqMSdmblcvVCg1TVJVJmduRGRfZzUuOScrLWJMNHUzPjlrXWhZWicuUyEiCitrdUQ1O1csPjpXNEsuTThWTEYoYDo9UDNiRFdSOFkvRW5jcjMwZDdpZTUvOFRtTytTTTBKOiVBJCtMTjMyJmJeRmlZITVwdUZjQz4jYUxXCihBVTdDWHJhK19VOFZBMzo6cFw6YGA8USZMSWwoKlldYSstS0wzS2BCbTlHJmlUdTZqNlxwUTw2blxBRSRuPzZwQ1ZtOy48OHNdP0VXKz48ClotUmheJFc3UWRFJ2c2KGgqUjMtKSI0OytbPU9aKFdETj89Sz5FQ29AcW5lSkhaNmkwTG5vSCplJChxVzAwIV5fOnVcOGRLZ0NiN0haMmxWCjMzOzUsMzInMCNANGVcJCQwTl8hJWRpUixiSCFwKVRiXCVfOjIzWWlRPiZPJS8tVytERzYrYmRYQTkmbSphLyFAPyltdVpoSURHJ2Y0bzNwCltbUFlsLkE0YydLXlEnQyxGYiU5JkVBO1k6JChtSEI+WEA6cFc5bkJFZVxZTm1RJEVxWDNeUCpwdV8wMnMxQ0ZQZDtEX3Q5VWssdU49UjRpCkVMNFRiOEAhNVRlJyY8Ly0+WDNsYllJPjIscyFAKF9ac24mODhHSnQ5aGxaI0MzJzxaKTY4UF9yQWRjOUZAVW5cSCc/TGBkXUtmUl0zPEVlCm1sP1QpSUZuaEgpalsuR14jaTBzXWwxVkM/YmJCJmg7LCdwYzA0PzdgRVVaS1g4UlhhYkVuZD9aZnArJkdGbCxFUCxGVVxjLWdcaiNjPmQ4CisqZzRLLkhGdUlIKCZnRFw/TElhZEk0UmhdQV1ZTSEmRSZpMUxpKl1dN1pGdWdUdTFPZEJYcTYpW0haR3AlUi9ScnJbQC0uRkp+PgplbmRzdHJlYW0KZW5kb2JqCjIzIDAgb2JqCjw8IC9UeXBlIC9YT2JqZWN0Ci9TdWJ0eXBlIC9JbWFnZQovV2lkdGggMTE4Ci9IZWlnaHQgNDkKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDQ2MQovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9lSkldUj8jWG5Ya1Q2QT5YS25EYldCIk1aRWFqUHBkNF0nKF5AUmx0ImtCIlMwJGYlPz1tPTRDOzsuJE4oalJjWVIlc2QmbDkkT3ReCikmNz1MKDctZXFxZUAuKC9TQzk4NC1mTFhlTFo1cWNaNWxBRUI1NT4zQDA9ayI7UmgyaEJjUUwzJko/NW9bY0gwYlNGTl48OztANDFTWTltCmMiWkk9WWwjYzQpYF8iWWxtTjMlLkEubE5TYFZlL1k8JT8uNygoKS8uZEJbO2shSlslJyVESlxJPythNzo1b05rWVxxRVM+MzxJNWJabShJCiVkPEBCKThEYnQzcEtHY2xiUWsxJ2laVnM3Tk0wXG8mUipxVT5nSHUtRnJDa2g8a0hGRypcJE09X3NWLy0kXEpGOmUvPz5mWEErQ0NtcERlCmRTUDZHY3UsXFgnQUw9YTVKQ1s0NkcuaHAyPVU0ZV4kZW9cUSNiKm03QzgkLUpBKGNaP1lgJ0M7NkpwSGVQbFwkSEVDIXVeKlFhKzZnRU1rCltmRVYqYi4jPnByPi1XU2YjPmgmVz91a2tUc2hZYD0vWC42NkEqO2Jpcy9kZ0BRWFhzcjhtO34+CmVuZHN0cmVhbQplbmRvYmoKMjQgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCA1NAovSGVpZ2h0IDU0Ci9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCA3NwovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIjBKZDBUZHEkajRvRl5VLCJIVHM5RUlFOzBBVCxfRSpMWiVvQDdKbDVWO0gnQ3M9VHJxRGFILjRCZiNjNE9WVDsoZCNmPEdFOX4+CmVuZHN0cmVhbQplbmRvYmoKMjUgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCAyOTQKL0hlaWdodCA2NwovQ29sb3JTcGFjZSAvRGV2aWNlR3JheQovQml0c1BlckNvbXBvbmVudCA4Ci9MZW5ndGggMTM2MgovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9jPWAsM0YkcSM9PzkvRWZNXD5bRzYmME5VZzZRSTs6WTE+cCdcTz5rbGNUWDkwUzs0OnQqc19WOCNfIWJASSpjZidzJCxPLTVOW0JBCl9sSmFWQiZdZmhDN2Q7XiwyZj1nSyYzOXBRLU1sc0kzc2EtR05qJCdONU5yLGRTZnBKOSQwOGRAKGc9JCdYR21gWC5FX1BaVj4tUnA/QGFaCithVzFbYFsjMEgyP3BgQFVbSWVlKCJHM1lRZFNkQzk/QHRiXjtdcWdSWSNcX1dDLT48al5GcSNDJyFxZWI4UE9UXFZjSGNVVFUwXEFGKFBIClRALE05Y1ooQmNWNW9pVnJaUC5XU0IkMl43JGgxTic4KDxiNkBHTmFrKSNjNmFMY1I3JmFacnAuVydbSDorSUZbTjBfbWlcanJhcS4pSTApClwpIipcP2YzPW1HRiZwM2ZFY1JoSGFNTVM3Rzg9bkxtT14lSDZmMzI0NVZBM08vOTRKWSMxKDNdJWUkOk1Db3BtRDUzbVw9dDNEblprN1hTCipLPFtJR3AsVGQ7ImFYUltQN2QsVWtDOnFWMCY+LS8kPnItJF0rNFIoSE8mSkllLW1PIyxlYlNINCRbZjMnOXA6PUFeW2g9SCIuLVw+NWpJCmEqbjZrPSpuWDEvWiFxYyQrI3E5L2dYVGhFTDdYc2FxRG1jK11WXFRaJTdaYVZQWGNxTCJYK1k6TFNeOzBQVGpgO3R1Wyw7WWdcbGUxVClRCk0wQjJpNnAoJCVLI01FKFFvJV91ZVskJENZOFQvcl9JKFNUVV9ocG4vI0MmKi5kYHFaX2NvYCtrcidodFU8O2IpYTBNa1YkVj1OdWtnMSMyCjNoJkV0YFQ7JjwhU0tyUzFeQzhGNE1eTWNmWURUbylFYjVVVjU4OXQnIyQlNTQtRmEvYzRqSFVQPHFqUS49YzI4PFFoYnBIc0RpT2EpVyJbCm9QQTAvTlpsOlBRQl5POlBhOWBUOGhsbkpmJ1xlR0U2KD4yTENvSW4zKihDRSxUWTpsLS4yTGhiQCRORCZRLCJTYGlYPSM2IUUlKjtIY1tPCi5CLE8vR1BTMVtEblFZRkhLLF50JiQ5cGYkKzw9UCo/Sz9OMzUtPikzJi1dIVsvVUpoW2prJGIuSydaJHBHaUtCJV1KZW4oKTxwQUE4SS4xCiYoTS9cPXEvXT1aJzgySmtnK0VMaT1iMS1RPTtTOTh0V0ZwOGtcRCwtJTNgbyhUMSg4ZFBhZmw/IyoyWnBZcTprckBIPk9pZW1tdEI4K2EzClRjc21MPEhhQHVbJDl1V1ApS1ZiQjRRbztNWUAuNWooOGJyVVpoXDEjO1VXNy9aIzw5Ii1kUUg6XUx0MzNXYSVhWlVyKGMmU1BUKj9DMnUlClMzJy01Q0ZnaSVtRiMkKWNoWk9OZXElIjluXXBqUCQ9Nj10a3BAXmInWkxRcEpOLzhSVD89QmNWaSZvK1FlISYxLSZiWDNnNWdDWjQkO1g8CmRJPzFYLkRZZV1AQ3E7Py8+XTFiUEw+PDlVPG5va2pnKCFQN1ZPTC89cCVxWyZUY0kmNkNdYCInOVZzND9AOSs9QzVvZkBVby81amBvLU5vClFkU2RDOUJmRkM5Ok5vWjE2PFo0SjFQWEhtV01QZyxib3JTS1tTVzJOSC9WSWwpcDEkJ1g2KykqOFF0MDtTI1lcLi8sMycpO1lHcjZYT3NoCiVJSyVKOlMqWFIuQzk5MzMjVi0yP1N0Lz0hJy9HRlwnPEVOayMyMTdURlgyTFY2bEskUS1xakdJWFY7cV5yS15+PgplbmRzdHJlYW0KZW5kb2JqCjI2IDAgb2JqCjw8IC9UeXBlIC9YT2JqZWN0Ci9TdWJ0eXBlIC9JbWFnZQovV2lkdGggMTE4Ci9IZWlnaHQgNDkKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDQ2MQovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9lSkldUj8jWG5Ya1Q2QT5YS25EYldCIk1aRWFqUHBkNF0nKF5AUmx0ImtCIlMwJGYlPz1tPTRDOzsuJE4oalJjWVIlc2QmbDkkT3ReCikmNz1MKDctZXFxZUAuKC9TQzk4NC1mTFhlTFo1cWNaNWxBRUI1NT4zQDA9ayI7UmgyaEJjUUwzJko/NW9bY0gwYlNGTl48OztANDFTWTltCmMiWkk9WWwjYzQpYF8iWWxtTjMlLkEubE5TYFZlL1k8JT8uNygoKS8uZEJbO2shSlslJyVESlxJPythNzo1b05rWVxxRVM+MzxJNWJabShJCiVkPEBCKThEYnQzcEtHY2xiUWsxJ2laVnM3Tk0wXG8mUipxVT5nSHUtRnJDa2g8a0hGRypcJE09X3NWLy0kXEpGOmUvPz5mWEErQ0NtcERlCmRTUDZHY3UsXFgnQUw9YTVKQ1s0NkcuaHAyPVU0ZV4kZW9cUSNiKm03QzgkLUpBKGNaP1lgJ0M7NkpwSGVQbFwkSEVDIXVeKlFhKzZnRU1rCltmRVYqYi4jPnByPi1XU2YjPmgmVz91a2tUc2hZYD0vWC42NkEqO2Jpcy9kZ0BRWFhzcjhtO34+CmVuZHN0cmVhbQplbmRvYmoKMjcgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCA1NAovSGVpZ2h0IDU0Ci9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCA3NwovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIjBKZDBUZHEkajRvRl5VLCJIVHM5RUlFOzBBVCxfRSpMWiVvQDdKbDVWO0gnQ3M9VHJxRGFILjRCZiNjNE9WVDsoZCNmPEdFOX4+CmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDI4CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAwOSAwMDAwMCBuIAowMDAwMDAwMDU4IDAwMDAwIG4gCjAwMDAwMDAxMDQgMDAwMDAgbiAKMDAwMDAwMDE3NiAwMDAwMCBuIAowMDAwMDAwMjI4IDAwMDAwIG4gCjAwMDAwMDAzMjYgMDAwMDAgbiAKMDAwMDAwMDQyOSAwMDAwMCBuIAowMDAwMDAwNTM1IDAwMDAwIG4gCjAwMDAwMDA2NDUgMDAwMDAgbiAKMDAwMDAwMDc0MSAwMDAwMCBuIAowMDAwMDAwODQzIDAwMDAwIG4gCjAwMDAwMDA5NDggMDAwMDAgbiAKMDAwMDAwMTA1NyAwMDAwMCBuIAowMDAwMDAxMTU4IDAwMDAwIG4gCjAwMDAwMDEyNTggMDAwMDAgbiAKMDAwMDAwMTM2MCAwMDAwMCBuIAowMDAwMDAxNDY2IDAwMDAwIG4gCjAwMDAwMDE2MzYgMDAwMDAgbiAKMDAwMDAwMjA1MyAwMDAwMCBuIAowMDAwMDAyNDcwIDAwMDAwIG4gCjAwMDAwMDI4ODcgMDAwMDAgbiAKMDAwMDAwNTU1NSAwMDAwMCBuIAowMDAwMDA3OTA5IDAwMDAwIG4gCjAwMDAwMDg1NTYgMDAwMDAgbiAKMDAwMDAwODgxNyAwMDAwMCBuIAowMDAwMDEwMzY2IDAwMDAwIG4gCjAwMDAwMTEwMTMgMDAwMDAgbiAKdHJhaWxlcgo8PAovSW5mbyAxNyAwIFIKL1NpemUgMjgKL1Jvb3QgMSAwIFIKPj4Kc3RhcnR4cmVmCjExMjc0CiUlRU9GCg==\",\"docType\":\"PDF\"}],\"currency\":\"SEK\",\"customerReferences\":[],\"codcollectionAmount\":0.0,\"baseRateAmount\":650.0},{\"masterTrackingNumber\":\"794903800925\",\"packageSequenceNumber\":2,\"trackingNumber\":\"794903800936\",\"additionalChargesDiscount\":0.0,\"netRateAmount\":2653.04,\"netChargeAmount\":0.0,\"netDiscountAmount\":0.0,\"packageDocuments\":[{\"contentType\":\"LABEL\",\"copiesToPrint\":1,\"encodedLabel\":\"JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMyAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL091dGxpbmVzCi9Db3VudCAwCj4+CmVuZG9iagozIDAgb2JqCjw8Ci9UeXBlIC9QYWdlcwovQ291bnQgMQovS2lkcyBbMTggMCBSXQo+PgplbmRvYmoKNCAwIG9iagpbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0KZW5kb2JqCjUgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKNiAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EtQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjcgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhLU9ibGlxdWUKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iago4IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0hlbHZldGljYS1Cb2xkT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjkgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllcgovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEwIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjExIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEyIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItQm9sZE9ibGlxdWUKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxMyAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1Sb21hbgovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE0IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUJvbGQKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1JdGFsaWMKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNiAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1Cb2xkSXRhbGljCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTcgMCBvYmogCjw8Ci9DcmVhdGlvbkRhdGUgKEQ6MjAwMykKL1Byb2R1Y2VyIChGZWRFeCBTZXJ2aWNlcykKL1RpdGxlIChGZWRFeCBTaGlwcGluZyBMYWJlbCkNL0NyZWF0b3IgKEZlZEV4IEN1c3RvbWVyIEF1dG9tYXRpb24pDS9BdXRob3IgKENMUyBWZXJzaW9uIDUxMjAxMzUpCj4+CmVuZG9iagoxOCAwIG9iago8PAovVHlwZSAvUGFnZQ0vUGFyZW50IDMgMCBSCi9SZXNvdXJjZXMgPDwgL1Byb2NTZXQgNCAwIFIgCiAvRm9udCA8PCAvRjEgNSAwIFIgCi9GMiA2IDAgUiAKL0YzIDcgMCBSIAovRjQgOCAwIFIgCi9GNSA5IDAgUiAKL0Y2IDEwIDAgUiAKL0Y3IDExIDAgUiAKL0Y4IDEyIDAgUiAKL0Y5IDEzIDAgUiAKL0YxMCAxNCAwIFIgCi9GMTEgMTUgMCBSIAovRjEyIDE2IDAgUiAKID4+Ci9YT2JqZWN0IDw8IC9GZWRFeEV4cHJlc3MgMjAgMCBSCi9FeHByZXNzRSAyMSAwIFIKL2JhcmNvZGUwIDIyIDAgUgo+Pgo+PgovTWVkaWFCb3ggWzAgMCA2MTIgNzkyXQovVHJpbUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDE5IDAgUgovUm90YXRlIDA+PgplbmRvYmoKMTkgMCBvYmoKPDwgL0xlbmd0aCAyNjUzCi9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0gCj4+CnN0cmVhbQpHYXQ9LjlvZzVQJyJuXEJJaXNoRyFjNlRnV1pvVkZILjk5Nk8jPTZeQD9VXSVsbUMiZFolYHA9RzgnJmhrRTF1YylOaERHQmMrOytITW5tZgpYPWxLZHE4bGQhYjY1XyE+Wj0jXFVtMkMkZExpczIjVVlaJzkmbSlOcGhvVkxpTXBQQ1IvRG46IUMlRStVazpVUm5yU3RmQm9lJTo/KGcsVwpMSmwoOiQwKGM6SGJOXUhJOjYsVF0zYz4pZUYoWToxKCNILW08J0o1OixNJSZgPm8vXmc6XmpsWU1cM25JSihrUWhodWMoVEo2M3ROXCJLcgo1NWs2OT0iOSJCVi1WIkFAZCpzPiYxP0ZJJWU4VjY9U1pwM1stR09eYis9Y2BrMW0mSEFSSEtgTHUoWCJZa2lxNG1hXy83WGQ2VHBSRjhJMgpZSDMnalVcPiM1amppZTJRYi1uUSEyUy83UVk0Y2gvXS1fTFFzSVNdVzMqbENaPyQ4ZisyPk9aSixKSGZZWDN1XXBmTjo0PVktKSRfLiZKZgpnPE1AQ1dAc0hbMmZXLm0vMFRqbyRrSlIpYSpSPzxhKV1mN2E2aCt0J0YjPSUtOHNGUSdRWm1PUlchRTUsWWJKTlBQKlRSLDlrJF5ub1N0ZwolRi4raF91MCllLidPLjhfImZEX1NeKi5mRmdUJCY5UVYyUG9nP1twUiQvYlBVZWhtQTtkOXFOW0tZdVpJPEdhY1JDRVEzaWssOFI4UEBENQo2QEQpa0dhUSZLODJwcDRbKSVkSGhFbWpiWGU1LWdSWlMxM1tWJygjTHReNDFbQ0k+P0RmNnVGa25ETU9sbF5UZWtyN0FpYk9uPyw9M20yZQpjMD5CKTBoK3MvaygmXV8qQE9fOjRCbWVsKjI2XXJNIlM6R28+VSRiPHVcUE9yYyE6bEkyJWwsTEE2W1AyMVBXUyVYU1dTXTZVYE9bcWBIVwpEPEpNbUFLRj9TNCoyOjdsTldvUiI1V1dyb0IsMVldbTlFNFY9OmgqK0JeWXVFY0VZSnFbT3QtVzRWa0Y4Y1JaPj0zRD02NSIqPVhsXnRtbgpoUUYhMm5dUzsiVk9YQkJvZUFdQTxqPFguZUYpSU5pVzVbcVoqIzw/TFhCTzwvNzd0TiFOckI1clxfTC5hIzJZdD02blc2XVwwXWBDazIrQApWOkQrME9kdGlRXFwkXEJlWEtXIWY1RlltPUVCPmJnLSRPbzk3Z2khQmRYKC8tdEJXc202MXJNWUhQLTAkKj9RKFd1PUpdcjIlRic/bFJpPApKQm5OYSZtUz88XXBDaDddM2lBJlplbSlCQkRgSCcuNkJtR0hicFghUWtzMCJmQyFAQyZNKC9XaDpaNzdAbUs2Sm82QVhES10lZUtlPmQkMAozYy1EZ24oSSY8Y0JuOyItT1xXZThWZ0BzQmsvWDZnPnIrUiJwTldqPj5qcFo1XEswdXBuJnBsXS1kdS0lXmVsY29iP3Q2UWxeJThiQV5DWwohVU5GaEk4PkpqMG1IMCkkPGA2NTtgWTIiO1UoN2NWJF0uQi1eZj9SVnJHZSdrRlBNKGxPKCZPLjpBbkcvcG01Li5AL1tTMi9eY19mT08tSAorISFqKUMjQD5TV2MzVGZNZTcjKlkrVkkjWjk8LSlFRiM5RVciNC8/T2MiTW5xJmlQRzNZY09TNj8ubS5HQG83X0MmSEtwV2MzU1dpWzBqWgpNQnVsQUE/SS5WaiRuYV43JSZTSV9IMChNRj5bc19dKyoyKERMPTBGbFopVDZmKVE8K2FfMy9hQ0JSaUJCOz1pZDxQVyVCME5qa19LRXIkOAo9NlVcYGsyRj5IWCE8ZDBqQ2tOLl1jJmxBOl4yJWkxVmZQNE09Im0qIyZtTktnUl9CRltBPl1tRWtQL3IhIk1aNG5tV242LF4pJko8czBKWApANDxXOE4yMkJqN2JxQE4pRTk1LnAnbUJeMDs2YlpvVFVpXFRfa0dPUVpVdU1vWS08NGtSKD4qZDQmTiRQKUdXSTR1YmhhZXMhK2JVVlo5LApvRUgvMSMlImw1a0k9cUQvOURwX1pXUE1UPlh0YXAlYj5mWjo5IUJLMj10KFJsUkdvRWQ8MjEzSGc0IlxGTGhzJSVOQDhHZ1g3JGMnPjtASQpdPjdHSzdxXCcwQ18kY3RQSCcvTlpca1VaNzxwXSo3RlBQPilFQCFuQkdcI0hIOjBQKVRjNmBBREhKPE8jMiJdJVcyZCssMmVxOUwnSDR1UQptXGAjKV8tNVQ5TUFlSj4nXi1HK2dDdUNdK1xDK0tXZHF1YjElLTJBPWRNVjQnZnB1LGIocVkrOTkudDFaLmlKQEpBWThpV1g0NUNBJzxTKwozbF9dTCc6cGYkOSx1WClEQkRhOWBwMDNraz81cCFkLV1JYmlqcTI2XERbYjknVShgKUBFRnQwMVhycU4tLExuR0Q6cjtlVWtPLE9dRSciQwpQRy1ELF90IWosRy4uZjpKOmUuMDpKW0p1I1dpaCJjczxSZzMnJlNeTWc7TUhtLWtBa2dRZWRoX2MhMVEwKmAsN0FOKiU3Sj43I0BwJzI0aApTV087az43MkNjZDkvSVozQkNSMmtHKi1HYjZEb2YuU1FRbTZdOzw+bU9PUy1FJWsuNj5FWCouZyJvPFBIa2dPQFRtU0VjWi1vYCRScydGYQojKilsSmJUdG1ATF9HXTpoK1FvP2kzM29ccERPJzAvUE9zbU0mSj8pLG5qanJVQFZlJCYrMyVpXnNUUFZNamRvdDY2OE1YLlRPIiszTWZMaApkSnRLIjdOLUtfbCl0O09jNywtZGlKWj4tQDBCbDQkOStGJSIuKWJCIyk/RGJwb1tLdSomU2hMYGdmNWZVbUpXcCsmYiU5ZTloaXMrbCpsLAooS1h1LiomaFdILW1hLUcmcVUhVDVaUDxrai5VN1FGPEIkVUJcaEpdZiFuVCskJ2dRKGA1YV1kRFUyRENcakgzTEw2XztuMV40P2JuOEtCOwo/VHAzWy9qOSc8QVcrU148bi1yUUh1UiJfXnJjLCJvNi5hW2ZyZk5gVzs2PkZGTkFZPEJEVCE0OVRQLEU4VDIyXVtFYyVtXmIjY2M8dUciRwpFbjcnTG4pQXRmPGxdaio1PnU+cEFUblJMVTpDLG1fIlxTR0RdYlE9Sy1yTCRfTD5BcW5EQWE7YjhhJFpnaG4xKVZSYjk1PEBBUVg5XU0yLwpdVUAwXUFKST5yMERqREYqKUFXV1EkV0ZRXE5HN0tuXzZDSGlvUztTQUg0L0lkVFFKXEYiU2okQDM5O1pLRE9ncWVETDNlcyJYUURsYzQ0QQo1LG0oZmBTVj1GcU9ZUWhzLSVKSD82LWtaLzpbWXJhTiFTbnBfTy0kLzd1JUpjJFxUVylAX3EkPlZXUj5GTkI7bkxFPS9RLFs5c3JqTHMwZQo0Iz8tOXJxWileJW1SaFhLbGg1ZUMqLzVybC8/JVloMSdQOmczUFNxYzU9V2pzOEBGY1wlX29ZcD5gXn4+CmVuZHN0cmVhbQplbmRvYmoKMjAgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCAxMTgKL0hlaWdodCA0OQovQ29sb3JTcGFjZSAvRGV2aWNlR3JheQovQml0c1BlckNvbXBvbmVudCA4Ci9MZW5ndGggNDYxCi9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiL2VKSV1SPyNYblhrVDZBPlhLbkRiV0IiTVpFYWpQcGQ0XScoXkBSbHQia0IiUzAkZiU/PW09NEM7Oy4kTihqUmNZUiVzZCZsOSRPdF4KKSY3PUwoNy1lcXFlQC4oL1NDOTg0LWZMWGVMWjVxY1o1bEFFQjU1PjNAMD1rIjtSaDJoQmNRTDMmSj81b1tjSDBiU0ZOXjw7O0A0MVNZOW0KYyJaST1ZbCNjNClgXyJZbG1OMyUuQS5sTlNgVmUvWTwlPy43KCgpLy5kQls7ayFKWyUnJURKXEk/K2E3OjVvTmtZXHFFUz4zPEk1YlptKEkKJWQ8QEIpOERidDNwS0djbGJRazEnaVpWczdOTTBcbyZSKnFVPmdIdS1GckNraDxrSEZHKlwkTT1fc1YvLSRcSkY6ZS8/PmZYQStDQ21wRGUKZFNQNkdjdSxcWCdBTD1hNUpDWzQ2Ry5ocDI9VTRlXiRlb1xRI2IqbTdDOCQtSkEoY1o/WWAnQzs2SnBIZVBsXCRIRUMhdV4qUWErNmdFTWsKW2ZFVipiLiM+cHI+LVdTZiM+aCZXP3Vra1RzaFlgPS9YLjY2QSo7YmlzL2RnQFFYWHNyOG07fj4KZW5kc3RyZWFtCmVuZG9iagoyMSAwIG9iago8PCAvVHlwZSAvWE9iamVjdAovU3VidHlwZSAvSW1hZ2UKL1dpZHRoIDU0Ci9IZWlnaHQgNTQKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDc3Ci9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiMEpkMFRkcSRqNG9GXlUsIkhUczlFSUU7MEFULF9FKkxaJW9AN0psNVY7SCdDcz1UcnFEYUguNEJmI2M0T1ZUOyhkI2Y8R0U5fj4KZW5kc3RyZWFtCmVuZG9iagoyMiAwIG9iago8PCAvVHlwZSAvWE9iamVjdAovU3VidHlwZSAvSW1hZ2UKL1dpZHRoIDI5NAovSGVpZ2h0IDcwCi9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCAxNDE5Ci9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiL2NsWWA3WSY7MHJcMEM6NXRIcyhLaVdfczRTTC5ER2prQC9wZihpbGducDNRO0g+ZUwnTShbQzhOKzI6aXFoNiRxPUVVRChIPklGM3IKPl1GRE5nMG5gPEpTdTkibFdOaGtNRE1QdVU9dUlPR1BSUihVUDxkQGZodSFHcy1YS0xmN2hfQm83a14/XWhTLyZiRldRQ2onZVFSPSonMSgKJ0dTMGZdIVNrclVGO2xpSFZvK2cvPSteXkhDQF8zcSgkP2YqK0A1Y2I8TUdtQixESSFjQlhHSmxyXDlDKyVlbm5TYjorV0xLT09GM2IqQF8KL1ojP289YWpzTzdSPjpdOy8rdSk/JDdNZyRrQSZRZV4uLV5BMDJEWWFJSCkzWFIlTFxEIkpoNDstaENpLjRxQzouN2p0QU11ZHNyTGpMaEoKXlxkYmBONi9AXURcNjksJlk1YD01SiJvRUNnIyxsVyszSzI0JGxOa1onOlImJF48MzFXYmIuVl9IJV9YYGJBKF82ZzMmLjIkZi9hJC04bzUKZExnWGNhMVJLWCRgTnEiZ20xdDBEcyNKRz4iXGdOT3Q/RUUvZHVDU1UzJ3BWLXRsIyEuRS0sQ1s8XjEuJzM9bFVDNzxlLFUwS09aKGM/QVoKL18wWGhAb3U+cmtsalpkLlthI1RFaSNtP2BGNFk4JFZOJXMlKjlKOUFIT2xmOU1JTyNfI0tjVSssJ0h0S1Y/XDIuNHFDOi47PCVraWkvPWkKal4+WCYjdUQsZilPYHBrOHQjQE8xdFkoOmAnPzFqV2U+a2xMMls/aCUpYk9VTlJuU14uNHFBJC5IdDI7a0Y6IjBiKE9hZDMjKCZIR2MsNiYKJ0xVVDRVPXJrLCxHU2Vsa1hFSEIoOU5fdCc9ZGBNbVFSbltQYTlhXVBZKnFebzwsXmw4Q21EZkBUXFU9V2hxLUtNRiQpTD9TLSpYMzFCJz4KO0wrQHEuSiJjWWJOS0xbPVw7P09CaEREWjE8MU1HQnI7NEQqM3FnQVRiLzhBS2pWX2MsXWIqaT0nIjZRJCs0Jk5lI0xjK0kkQj0rbTtGRioKVilLZ00hUjdONCNpJkhpX1RwIj1tPUNHajpyUW1IZHQrPj5QVUBaIT5BWXVPbFs+UyY5OmFYPmcvOypIJW9bTShiKi1fRFMldSV0S2FhJyMKRT1MI1Y8QUVhbFY9PV4+MWdtQ2RURmJOaTtzMHJVKkRKQGsyUy1cJT4iWys8bDdgJl5xM2pLSVVhLl1cTGcoMiFpN08qJSV1PT5fMT8ic18KNUw6ZzdgJl9YTC1uSUY3PF4raz9RZFNjWFM1Tk9rVHNzLUlnLypkTS9vLWFzNlBAOCFoWC87ZzNdRmpLPWprTCdZdCxBJDFhK0ltKSs4JDAKVGUzKztvSSkiZkwxL1N1aC45JzRWWnRDQzZcRlZpY141dU5vWTdeRGNWJXQkXWdLb2xyJENZZCsrTjk8O3RDJF4sWWFPTD4wL25WUFIodWYKOHJIJ0pQaTZ0NypYc3M7U0NTcGJOZCohKVYpS2YuImcoUEdBOUJELmRJIikrV3RbKFdvYjg4PThrIW9pZ11qdUw5NWkyNyYlZEtPcFFmWXEKOTUsaWc1cSwmdSk9Iiw/I0o+LCRBSSxbalJBZFBDNSw+aGYjPUtwVyIoUi1XI2dXKigucEdDbmRbbFo1UGE5YlhQYy4ya1YuWXVhKVg1WVgKQzdvKF1ZYmtCZlskUFNGRy9mUD9FKyNfVls7KVJIb0dcJWErcTtlLC40cUJPLj1uV2pOTDJKcytLKU0jUzYwaUArcmRfVkxrIyY0S04nV10KPTA8KUFUR2RTWy0rRmkxX0k9ImY4UiJlW2wkbFhjbGQrMDlEQDRJIn4+CmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDIzCjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAwOSAwMDAwMCBuIAowMDAwMDAwMDU4IDAwMDAwIG4gCjAwMDAwMDAxMDQgMDAwMDAgbiAKMDAwMDAwMDE2MiAwMDAwMCBuIAowMDAwMDAwMjE0IDAwMDAwIG4gCjAwMDAwMDAzMTIgMDAwMDAgbiAKMDAwMDAwMDQxNSAwMDAwMCBuIAowMDAwMDAwNTIxIDAwMDAwIG4gCjAwMDAwMDA2MzEgMDAwMDAgbiAKMDAwMDAwMDcyNyAwMDAwMCBuIAowMDAwMDAwODI5IDAwMDAwIG4gCjAwMDAwMDA5MzQgMDAwMDAgbiAKMDAwMDAwMTA0MyAwMDAwMCBuIAowMDAwMDAxMTQ0IDAwMDAwIG4gCjAwMDAwMDEyNDQgMDAwMDAgbiAKMDAwMDAwMTM0NiAwMDAwMCBuIAowMDAwMDAxNDUyIDAwMDAwIG4gCjAwMDAwMDE2MjIgMDAwMDAgbiAKMDAwMDAwMjAwMSAwMDAwMCBuIAowMDAwMDA0NzQ2IDAwMDAwIG4gCjAwMDAwMDUzOTMgMDAwMDAgbiAKMDAwMDAwNTY1NCAwMDAwMCBuIAp0cmFpbGVyCjw8Ci9JbmZvIDE3IDAgUgovU2l6ZSAyMwovUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNzI2MAolJUVPRgo=\",\"docType\":\"PDF\"}],\"currency\":\"SEK\",\"customerReferences\":[],\"codcollectionAmount\":0.0,\"baseRateAmount\":650.0}],\"shipmentAdvisoryDetails\":{},\"completedShipmentDetail\":{\"usDomestic\":false,\"carrierCode\":\"FDXE\",\"masterTrackingId\":{\"trackingIdType\":\"FEDEX\",\"formId\":\"0881\",\"trackingNumber\":\"794903800925\"},\"serviceDescription\":{\"serviceId\":\"EP1000000376\",\"serviceType\":\"FEDEX_PRIORITY_EXPRESS\",\"code\":\"D2\",\"names\":[{\"type\":\"long\",\"encoding\":\"utf-8\",\"value\":\"FedEx®PriorityExpress\"},{\"type\":\"long\",\"encoding\":\"ascii\",\"value\":\"FedExPriorityExpress\"},{\"type\":\"medium\",\"encoding\":\"utf-8\",\"value\":\"FedEx®PriorityExpress\"},{\"type\":\"medium\",\"encoding\":\"ascii\",\"value\":\"FedExPriorityExpress\"},{\"type\":\"short\",\"encoding\":\"utf-8\",\"value\":\"NPE\"},{\"type\":\"short\",\"encoding\":\"ascii\",\"value\":\"NPE\"},{\"type\":\"abbrv\",\"encoding\":\"ascii\",\"value\":\"RN\"}],\"operatingOrgCodes\":[\"FXE\"],\"serviceCategory\":\"parcel\",\"description\":\"PriorityExpress\",\"astraDescription\":\"PREX\"},\"packagingDescription\":\"CustomerPackaging\",\"operationalDetail\":{\"ursaPrefixCode\":\"9H\",\"ursaSuffixCode\":\"BMAA\",\"originLocationId\":\"ARND\",\"originLocationNumber\":0,\"originServiceArea\":\"PM\",\"destinationLocationId\":\"BMAA\",\"destinationLocationNumber\":0,\"destinationServiceArea\":\"A1\",\"destinationLocationStateOrProvinceCode\":\"\",\"deliveryDate\":\"\",\"deliveryDay\":\"\",\"commitDate\":\"\",\"commitDay\":\"\",\"ineligibleForMoneyBackGuarantee\":false,\"astraPlannedServiceLevel\":\"A1\",\"astraDescription\":\"PRIORITYEXPRESS\",\"postalCode\":\"10012\",\"stateOrProvinceCode\":\"\",\"countryCode\":\"SE\",\"airportId\":\"ARN\",\"serviceCode\":\"D2\",\"packagingCode\":\"01\",\"publishedDeliveryTime\":\"\",\"scac\":\"\"},\"shipmentRating\":{\"actualRateType\":\"PAYOR_ACCOUNT_SHIPMENT\",\"shipmentRateDetails\":[{\"rateType\":\"PAYOR_ACCOUNT_SHIPMENT\",\"rateScale\":\"SE1F1_D2_YOUR_PACKAGING\",\"rateZone\":\"1\",\"pricingCode\":\"\",\"ratedWeightMethod\":\"ACTUAL\",\"currencyExchangeRate\":{\"fromCurrency\":\"SEK\",\"intoCurrency\":\"SEK\",\"rate\":1.0},\"dimDivisor\":139,\"fuelSurchargePercent\":10.5,\"totalBillingWeight\":{\"units\":\"KG\",\"value\":21.0},\"totalBaseCharge\":650.0,\"totalFreightDiscounts\":0.0,\"totalNetFreight\":650.0,\"totalSurcharges\":1472.43,\"totalNetFedExCharge\":2122.43,\"totalTaxes\":530.61,\"totalNetCharge\":2653.04,\"totalRebates\":0.0,\"totalDutiesAndTaxes\":0.0,\"totalAncillaryFeesAndTaxes\":0.0,\"totalDutiesTaxesAndFees\":0.0,\"totalNetChargeWithDutiesAndTaxes\":0.0,\"surcharges\":[{\"surchargeType\":\"OUT_OF_PICKUP_AREA\",\"level\":\"SHIPMENT\",\"description\":\"OutofPickupAreaTierB\",\"amount\":1035.0},{\"surchargeType\":\"DEMAND\",\"level\":\"SHIPMENT\",\"description\":\"DemandSurcharge\",\"amount\":100.0},{\"surchargeType\":\"FEDEX_INTRACOUNTRY_FEES\",\"level\":\"SHIPMENT\",\"description\":\"Waybill\",\"amount\":50.0},{\"surchargeType\":\"FUEL\",\"level\":\"SHIPMENT\",\"description\":\"Fuel\",\"amount\":187.43},{\"surchargeType\":\"OTHER\",\"level\":\"SHIPMENT\",\"description\":\"Multi-PieceShipment\",\"amount\":100.0}],\"freightDiscounts\":[],\"taxes\":[{\"type\":\"VAT\",\"description\":\"Swedenvalue-added\",\"amount\":530.61}],\"currency\":\"SEK\"}]},\"completedPackageDetails\":[{\"sequenceNumber\":1,\"trackingIds\":[{\"trackingIdType\":\"FEDEX\",\"formId\":\"0881\",\"trackingNumber\":\"794903800925\"}],\"groupNumber\":0,\"signatureOption\":\"SERVICE_DEFAULT\",\"operationalDetail\":{\"barcodes\":{\"binaryBarcodes\":[{\"type\":\"COMMON_2D\",\"value\":\"Wyk+HjAxHTAyMTAwMTIdNzUyHUQyHTc5NDkwMzgwMDkyNTA4ODEdRkRFHTYwNjg5NDg5OR0zMzkdHTEvMh04Ljk5S0cdTh1SRUNJUElFTlQgQUREUkVTUyAxHVNUT0NLSE9MTR0gIB1Kb2huIFRheWxvch4wNh0xMFpYSTAwMh0xMVpGZWRleB0xMlo0NjIwMzQ1Njc4OR0xNFpSRUNJUElFTlQgQUREUkVTUyAyHTE1WjEwMDQ5MzgyNB0yMFocHTMxWjE0OTU0MTA4MzA4OTExNTgyMDQ4MDA3OTQ5MDM4MDA5MjUdMzJaMDIdMzlaQVJORB0eMDkdRkRYHXodOB04LgI0Ohp/QB4E\"}],\"stringBarcodes\":[{\"type\":\"FEDEX_1D\",\"value\":\"1495410830891158204800794903800925\"}]},\"astraHandlingText\":\"\",\"operationalInstructions\":[{\"number\":2,\"content\":\"TRK#\"},{\"number\":3,\"content\":\"0881\"},{\"number\":4,\"content\":\"##MASTER##\"},{\"number\":5,\"content\":\"9HBMAA\"},{\"number\":7,\"content\":\"1495410830891158204800794903800925\"},{\"number\":8,\"content\":\"583J3/8E24/9AE3\"},{\"number\":9,\"content\":\"1of2\"},{\"number\":10,\"content\":\"794903800925\"},{\"number\":12,\"content\":\"A1\"},{\"number\":13,\"content\":\"PRIORITYEXPRESS\"},{\"number\":15,\"content\":\"10012\"},{\"number\":16,\"content\":\"-SE\"},{\"number\":17,\"content\":\"ARN\"}]}},{\"sequenceNumber\":2,\"trackingIds\":[{\"trackingIdType\":\"FEDEX\",\"formId\":\"0891\",\"trackingNumber\":\"794903800936\"}],\"groupNumber\":0,\"signatureOption\":\"SERVICE_DEFAULT\",\"operationalDetail\":{\"barcodes\":{\"binaryBarcodes\":[{\"type\":\"COMMON_2D\",\"value\":\"Wyk+HjAxHTAyMTAwMTIdNzUyHUQyHTc5NDkwMzgwMDkzNjA4OTEdRkRFHTYwNjg5NDg5OR0zMzkdHTIvMh0xMi4wMEtHHU4dUkVDSVBJRU5UIEFERFJFU1MgMR1TVE9DS0hPTE0dICAdSm9obiBUYXlsb3IeMDYdMTBaWEkwMDIdMTFaRmVkZXgdMTJaNDYyMDM0NTY3ODkdMTRaUkVDSVBJRU5UIEFERFJFU1MgMh0xNVoxMDA0OTM4MjQdMjBaHB0yOFo3OTQ5MDM4MDA5MjUwODgxHTMxWjE0OTU2ODgwMzA4OTExNTgyMDQ4MDA3OTQ5MDM4MDA5MzYdMzJaMDIdMzlaQVJORB0eMDkdRkRYHXodOB04LgI0Ohp/QB4E\"}],\"stringBarcodes\":[{\"type\":\"FEDEX_1D\",\"value\":\"1495688030891158204800794903800936\"}]},\"astraHandlingText\":\"\",\"operationalInstructions\":[{\"number\":2,\"content\":\"MPS#\"},{\"number\":3,\"content\":\"0891\"},{\"number\":4,\"content\":\"Mstr#794903800925\"},{\"number\":5,\"content\":\"9HBMAA\"},{\"number\":7,\"content\":\"1495688030891158204800794903800936\"},{\"number\":8,\"content\":\"583J3/8E24/9AE3\"},{\"number\":9,\"content\":\"2of2\"},{\"number\":10,\"content\":\"794903800936\"},{\"number\":11,\"content\":\"0881\"},{\"number\":12,\"content\":\"A1\"},{\"number\":13,\"content\":\"PRIORITYEXPRESS\"},{\"number\":15,\"content\":\"10012\"},{\"number\":16,\"content\":\"-SE\"},{\"number\":17,\"content\":\"ARN\"}]}}],\"documentRequirements\":{\"generationDetails\":[{\"type\":\"AIR_WAYBILL\",\"minimumCopiesRequired\":2}],\"prohibitedDocuments\":[\"USMCA_COMMERCIAL_INVOICE_CERTIFICATION_OF_ORIGIN\",\"USMCA_CERTIFICATION_OF_ORIGIN\"]}},\"serviceCategory\":\"EXPRESS\"}]}}';
            // {"transactionId":"APIF_SV_SHPC_TxID979c74e0-3a03-4706-9fd6-862cbd4b6a23","output":{"transactionShipments":[{"alerts":[{"code":"VIRTUAL.RESPONSE","message":"This is a Virtual Response.","alertType":"NOTE"}],"masterTrackingNumber":"794900456722","serviceType":"PRIORITY_OVERNIGHT","shipDatestamp":"2023-09-07","serviceName":"FedEx Priority Overnight®","pieceResponses":[{"masterTrackingNumber":"794900456722","deliveryDatestamp":"2023-09-08","trackingNumber":"794900456722","additionalChargesDiscount":0.0,"netRateAmount":325.95,"netChargeAmount":0.0,"netDiscountAmount":0.0,"packageDocuments":[{"contentType":"LABEL","copiesToPrint":1,"encodedLabel":"Pgo+PgovTWVkaWFCb","docType":"PDF"}],"currency":"CAD","customerReferences":[],"codcollectionAmount":0.0,"baseRateAmount":228.5}],"shipmentAdvisoryDetails":{},"completedShipmentDetail":{"usDomestic":false,"carrierCode":"FDXE","masterTrackingId":{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"},"serviceDescription":{"serviceId":"EP1000000002","serviceType":"PRIORITY_OVERNIGHT","code":"01","names":[{"type":"long","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"long","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"medium","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"medium","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"short","encoding":"utf-8","value":"P-1"},{"type":"short","encoding":"ascii","value":"P-1"},{"type":"abbrv","encoding":"ascii","value":"PO"}],"operatingOrgCodes":["FXE"],"serviceCategory":"parcel","description":"Priority Overnight","astraDescription":"PO"},"packagingDescription":"Customer Packaging","operationalDetail":{"ursaPrefixCode":"6B","ursaSuffixCode":"YBZA ","originLocationId":"YVRA ","originLocationNumber":0,"originServiceArea":"AM","destinationLocationId":"YBZA ","destinationLocationNumber":0,"destinationServiceArea":"A2","destinationLocationStateOrProvinceCode":"ON","deliveryDate":"2023-09-08","deliveryDay":"FRI","commitDate":"2023-09-08","commitDay":"FRI","ineligibleForMoneyBackGuarantee":false,"astraPlannedServiceLevel":"FRI - 08 SEP A2","astraDescription":"PRIORITY OVERNIGHT","postalCode":"M5C2C5","stateOrProvinceCode":"ON","countryCode":"CA","airportId":"YYZ","serviceCode":"01","packagingCode":"01","publishedDeliveryTime":"A2","scac":""},"shipmentRating":{"actualRateType":"PAYOR_ACCOUNT_SHIPMENT","shipmentRateDetails":[{"rateType":"PAYOR_ACCOUNT_SHIPMENT","rateScale":"CA0001F12_01_YOUR_PACKAGING","rateZone":"12","pricingCode":"","ratedWeightMethod":"DIM","currencyExchangeRate":{"fromCurrency":"CAD","intoCurrency":"CAD","rate":1.0},"dimDivisor":139,"fuelSurchargePercent":14.75,"totalBillingWeight":{"units":"LB","value":29.0},"totalBaseCharge":228.5,"totalFreightDiscounts":0.0,"totalNetFreight":228.5,"totalSurcharges":59.95,"totalNetFedExCharge":288.45,"totalTaxes":37.5,"totalNetCharge":325.95,"totalRebates":0.0,"totalDutiesAndTaxes":0.0,"totalAncillaryFeesAndTaxes":0.0,"totalDutiesTaxesAndFees":0.0,"totalNetChargeWithDutiesAndTaxes":0.0,"surcharges":[{"surchargeType":"INSURED_VALUE","description":"Insured value","amount":11.25},{"surchargeType":"PRIORITY_ALERT","description":"Priority Alert","amount":15.0},{"surchargeType":"FUEL","description":"Fuel","amount":33.7}],"freightDiscounts":[],"taxes":[{"type":"HST","description":"Canada Ontario harmonized sales","amount":37.5}],"currency":"CAD"}]},"completedPackageDetails":[{"sequenceNumber":1,"trackingIds":[{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"}],"groupNumber":0,"signatureOption":"SERVICE_DEFAULT","operationalDetail":{"barcodes":{"binaryBarcodes":[{"type":"COMMON_2D","value":"Wyk+HjAxHTAyTTVDMkM1HTEyNB0wMR03OTQ5MDA0NTY3MjIwNzMwHUZERR02MDgyNzE0NTcdMjUwHR0xLzEdMjAuMDBMQh1OHVRDMDAzIEpVTDIzIFRpcmUgTG9zcyAmIFByZXZlbh1UT1JPTlRPHU9OHVNISVAgVE8gQ09OVEFDVCBOQU1FHjA2HTEwWlhJMDAyHTExWlNISVAgVE8gUkVDSVBJRU5UIENNUE5ZHTEyWjkwMTI2MzU1NTUdMTRaUE8gLUN1UGFjayAtIEludHJhIENBIC0gUEEgLx0xNVoxMDA3NTAxNTMdMjBaHDMyNh0zMVoxMTQ1MzI3ODgxMDYwNDA0NjcyMTAwNzk0OTAwNDU2NzIyHTMyWjAyMTU5Mx0zOVpZVlJBHR4wOR1GRFgdeh04HTAlCzo7H39AHgQ="}],"stringBarcodes":[{"type":"FEDEX_1D","value":"1145327881060404672100794900456722"}]},"astraHandlingText":"ELB *PA","operationalInstructions":[{"number":2,"content":"TRK#"},{"number":3,"content":"0730"},{"number":5,"content":"6B YBZA "},{"number":7,"content":"1145327881060404672100794900456722"},{"number":8,"content":"583J4/05BA/9AE3"},{"number":10,"content":"7949 0045 6722"},{"number":12,"content":"FRI - 08 SEP A2"},{"number":13,"content":"PRIORITY OVERNIGHT"},{"number":14,"content":"ELB *PA"},{"number":15,"content":"M5C 2C5"},{"number":16,"content":"ON-CA"},{"number":17,"content":"YYZ"}]}],"documentRequirements":{}},"serviceCategory":"EXPRESS"}]}}';
            StatusCode = 200;
        }else {
            response = http.send(request);
            res.response = httpResult = response.getBody();
            StatusCode = response.getStatusCode();
        }

        // Process the response as needed
        if (StatusCode == 200) {
            Id RTID; RTID = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('Fedex_Shipping').getRecordTypeId();
            //Shipment__c ship = new Shipment__c();
            ship.Active__c = true;

            ship.RecordTypeId = RTID;
            ship.Name = 'Shipment';
            if(fAddress.Id != null && Ship.Shipment_Billing_options__c != null && String.isNotEmpty(Ship.Shipment_Billing_options__c) && Ship.Shipment_Billing_options__c == 'SENDER'){
                Ship.Billing_Address__c = fAddress.Id;
            }else if(tAddress.Id != null) Ship.Billing_Address__c = tAddress.Id;
            if(Schema.sObjectType.Shipment__c.fields.Customer__c.isCreateable() && ship.Customer__c == Null) Ship.Customer__c = tAddress.Customer__c;
            Ship.Customer_Contact__c = shipToContact.Id;
            if(Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable()) { Ship.Status__c = 'Shipped'; }
            if(Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isUpdateable()) { Ship.Shipping_Address__c = tAddress.Id; }
            if(packList.size() > 0){
                ship.Package__c = packList[0].Id;
                if(packList[0].Logistic__c != null && Schema.sObjectType.Shipment__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isUpdateable()) Ship.Logistic__c = packList[0].Logistic__c ;
                if(packList[0].Logistic__c != null && packList[0].Logistic__r.Billing_options__c != null) Ship.Shipment_Billing_options__c = packList[0].Logistic__r.Billing_options__c;
                if(packList[0].Order__c != null) Ship.Order__c = packList[0].Order__c;
                if(packList[0].Return_Merchandise_Authorisation__c != null) Ship.Return_Merchandise_Authorisation__c = packList[0].Return_Merchandise_Authorisation__c;

            }
            System.debug('packList[0].Return_Merchandise_Authorisation__c=>'+Ship);
            if(Schema.sObjectType.Shipment__c.fields.Fedex_Service__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Fedex_Service__c.isUpdateable()) { Ship.Fedex_Service__c = rateService; }




            // Successful response
            res.response = httpResult;
            // Parse JSON response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            Map<String, Object> outputMap = (Map<String, Object>) responseMap.get('output');
            List<Object> transactionShipments = (List<Object>) outputMap.get('transactionShipments');
            List<attachment> attList = new List<attachment>();
            String masterTrackingNumber = '';
            // Iterate through transaction shipments
            for (Object shipmentObj : transactionShipments) {
                Map<String, Object> shipment1 = (Map<String, Object>) shipmentObj;

                // Extract masterTrackingNumber
                masterTrackingNumber = (String) shipment1.get('masterTrackingNumber');
                System.debug('Master Tracking Number: ' + masterTrackingNumber);

                // Extract packageDocuments

                Decimal totalNetChargeval = 0;
                // Extract currency
                List<Object> pieceResponses = (List<Object>) shipment1.get('pieceResponses');
                for (Object pieceResponse : pieceResponses) {
                    Map<String, Object> response2 = (Map<String, Object>) pieceResponse;
                    String currencyval = (String) response2.get('currency');
                    System.debug('Currency: ' + currencyval);

                }

                // Extract carrierCode
                Map<String, Object> completedShipmentDetail = (Map<String, Object>) shipment1.get('completedShipmentDetail');
                String carrierCode = (String) completedShipmentDetail.get('carrierCode');
                System.debug('Carrier Code: ' + carrierCode);
                // Extract totalNetCharge

                Map<String, Object> response3 = new Map<String, Object>();
                if(completedShipmentDetail.containskey('shipmentRating'))  response3= (Map<String, Object>) completedShipmentDetail.get('shipmentRating');
                if(response3.size() > 0){
                    List<Object> shipmentRates = (List<Object>) response3.get('shipmentRateDetails');
                    system.debug('response3 : '+response3);
                    system.debug('shipmentRates : '+shipmentRates);
                    if(shipmentRates.size() > 0){
                        for (Object pieceResponse : shipmentRates) {
                            Map<String, Object> response2 = (Map<String, Object>) pieceResponse;
                            totalNetChargeval = (Decimal) response2.get('totalNetCharge');
                            System.debug('Total Net Charge: ' + totalNetChargeval);

                        }

                    }
                }
                ship.Shipping_Amount__c = totalNetChargeval;
                // Extract masterTrackingId
                Map<String, Object> masterTrackingId = (Map<String, Object>) completedShipmentDetail.get('masterTrackingId');
                String trackingIdType = (String) masterTrackingId.get('trackingIdType');
                if(Schema.sObjectType.Shipment__c.fields.Tracking_Unique_Id__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Tracking_Unique_Id__c.isUpdateable()) { if(TrackingIdType != null && TrackingIdType != '') Ship.Tracking_Unique_Id__c = TrackingIdType; }
                if(Schema.sObjectType.Shipment__C.fields.Number_Of_Pieces_In_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Number_Of_Pieces_In_Shipment__c.isUpdateable()) Ship.Number_Of_Pieces_In_Shipment__c = String.valueof(packList.size());

                ship.Carrier_Code__c = carrierCode;



                String formId = (String) masterTrackingId.get('formId');
                String trackingNumber = (String) masterTrackingId.get('trackingNumber');
                ship.TrackingNumber__c = trackingNumber;


                List<Object> packageResponses = (List<Object>) shipment1.get('pieceResponses');
                for (Object packageResponse : packageResponses) {
                    Map<String, Object> packageMap = (Map<String, Object>) packageResponse;
                    List<Object> packageDocuments = (List<Object>) packageMap.get('packageDocuments');
                    for (Object packageDocument : packageDocuments) {
                        Map<String, Object> doc = (Map<String, Object>) packageDocument;
                        attachment att = new attachment();
                        String contentType = (String) doc.get('contentType');
                        Integer copiesToPrint = (Integer) doc.get('copiesToPrint');
                        String labelData = (String) doc.get('encodedLabel');
                        system.debug('labelData : '+labelData);

                        if(labelData != null){

                            att = new attachment(Name = 'Fedex_Label.pdf', parentId = 'a0L0600000SwaYZEAZ', ContentType = 'application/pdf',body = EncodingUtil.base64Decode(labelData) );
                            attList.add(att);
                        }

                        System.debug('Package Document: ContentType=' + contentType + ', CopiesToPrint=' + copiesToPrint);
                    }
                }
                System.debug('Tracking ID Type: ' + trackingIdType + ', Form ID: ' + formId + ', Tracking Number: ' + trackingNumber);
            }
            if(isReturnShipment && masterShipmentId != null && masterShipmentId != ''){
                Ship.Id = null;
                Ship.Master_Shipment__c = masterShipmentId;
                Ship.Return_Shipment__c = true;
            }
            decimal totalPackQty = 0;
            for(Package__c pK : packList) totalPackQty += pK.Package_Quantity__c;
            if(Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isUpdateable())  Ship.Total_Package_items__c = totalPackQty;
            //PreventRecursiveLedgerEntry.shippedItemsCheck = false;
            if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) upsert ship;
            res.ShipDetails = ship;
            if(attList.size() > 0) {
                for(attachment att : attList){
                    if(ship.Id != null) att.ParentID= ship.Id;
                    system.debug('Id change : '+ship.Id);
                }
                 // for fls upsert attList;
                 List<SObject> safeattList = FLSHelper.getSafeRecords(
                    attList,
                    'Attachment',
                    AccessType.UPDATABLE
                );
                List<Attachment> typedattList = new List<Attachment>();
                for (SObject s : safeattList) {
                  Attachment attListRecord = (Attachment)s;
                  if (!attListRecord.getPopulatedFieldsAsMap().containsKey('ParentID') && ship.Id != null) {
                    attListRecord.ParentID = ship.Id;
                  }
                    typedattList.add(attListRecord);
                }
                if (!typedattList.isEmpty()) {
                    System.debug('upserting attachments 861: ' + typedattList);
                    upsert typedattList; // or insert/update as needed
                }
            }
            if(isReturnShipment == false){
                for(Integer i=0; i<packList.size(); i++) {
                    packList[i].Shipment__c = Ship.Id; packList[i].Status__c = Ship.Status__c;
                    packList[i].Tracking_Number__c = ship.TrackingNumber__c ;
                }
                if(packList.size() > 0) if(Schema.sObjectType.Package__c.isCreateable() && Schema.sObjectType.Package__c.isUpdateable()) update packList; // uncommented by Abubakar, because when shipment for packages was being made the package status was not being changed
                system.debug('--- packList : '+packList);
            }
            System.debug('ship-->'+ship);
            if(packList.size() > 0){
                if(packList[0].Order__c != null){
                    System.debug('entered packList[0].Order__c');
                    Order SalesOrder1 = new Order(); SalesOrder1 = Database.query('select Id, Name, Tracking_Number__c,Return_Tracking_Number__c, UPS_Service__c, Shipment_Type__c from Order where (Id =\'' + String.escapeSingleQuotes(packList[0].Order__r.Id) + '\') Limit 1');
                    if(isReturnShipment == false){
                        if(Schema.sObjectType.Order.fields.UPS_Service__c.isCreateable() && Schema.sObjectType.Order.fields.UPS_Service__c.isUpdateable()) SalesOrder1.UPS_Service__c = rateService;
                        if(Schema.sObjectType.Order.fields.Shipment_Type__c.isCreateable() && Schema.sObjectType.Order.fields.Shipment_Type__c.isUpdateable()) SalesOrder1.Shipment_Type__c = 'FedEx';
                        if(Schema.sObjectType.Order.fields.Tracking_Number__c.isCreateable() && Schema.sObjectType.Order.fields.Tracking_Number__c.isUpdateable()) {
                            if(SalesOrder1.Tracking_Number__c == null) SalesOrder1.Tracking_Number__c = ship.TrackingNumber__c ; else SalesOrder1.Tracking_Number__c += ', ' + ship.TrackingNumber__c ; }
                    }
                    else{
                        if(Schema.sObjectType.Order.fields.Return_Tracking_Number__c.isCreateable() && Schema.sObjectType.Order.fields.Return_Tracking_Number__c.isUpdateable()) {
                            if(SalesOrder1.Return_Tracking_Number__c == null) SalesOrder1.Return_Tracking_Number__c = ship.TrackingNumber__c ; else SalesOrder1.Return_Tracking_Number__c += ', ' + ship.TrackingNumber__c ; }
                    }

                    if(Schema.sObjectType.Order.isCreateable() && Schema.sObjectType.Order.isUpdateable()) { PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false; PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false; PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false; PreventRecursiveLedgerEntry.SOLI_AllocateStock = false; PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false; update SalesOrder1; }
                }

            }

            //return responseBody;
            // Process responseBody
        }
        else {
            // res.response = httpResult;
            // Error handling
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> errors = (List<Object>) responseMap.get('errors');
            if (errors != null && !errors.isEmpty()) {
                List<String> errlst = new List<String>();

                for (Object error : errors) {
                    String errorMessage = 'Error occurred:';Map<String, Object> errorMap = (Map<String, Object>) error;String errorCode = (String) errorMap.get('code');String errorMsg = (String) errorMap.get('message');errorMessage += '\nCode: ' + errorCode + '\nMessage: ' + errorMsg;errlst.add(errorMessage);
                }
                res.errMsgs = errlst;
                //  System.debug(errorMessage); // You can replace System.debug with any other method to display the error message
            } else {
                System.debug('An unknown error occurred.'); // Handle the case when no errors are present
            }

        }
        return res;
    }

     @AuraEnabled
    global static shipmentResponse shippingRequestResponse_rma(List<Package__c> packList,String fromAddress,String ToAddress,string fromContact,string toContact,String ShipDateStamp, String myConsVar, String Shipment, String rateService,String rateCurrency,boolean isReturnShipment,List<Package_List__c> packageItems,String masterShipmentId, String rmaId){
        System.debug('By Abu FedEx shippingRequestResponse_rma IsReturnShipment = ' + isReturnShipment);
        rateCurrency = 'USD';
        System.debug('packageItems length=>'+packageItems.size());
        System.debug('packageItems =>'+packageItems);
        Shipment__c ship = (Shipment__c) JSON.deserialize(Shipment,Shipment__c.class);
        system.debug('ship : '+ship);
        shipmentResponse res = new shipmentResponse();
        myConstructorWrapper MCW = new myConstructorWrapper();
        Address__c tAddress = new  Address__c();
        String toCountryCode = '';
        String toProvinceCode = '';
        String FromCountryCode = '';
        String FromProvinceCode = '';
        contact shipFromContact = (Contact) JSON.deserialize(fromContact, Contact.class);//getShiptoContact(packList[0].Id);
        contact shipToContact  = (Contact) JSON.deserialize(toContact, Contact.class);//getShipFromContact(packList[0].Id);
        // List<Package_List__c> packageItems = [Select Id,Name,Package__c,Quantity__c,Package__r.Weight_Unit__c ,Package__r.Weight__c,Order_Product__c,Order_Product__r.OrderItemNumber,Purchase_Line_Items__c,Purchase_Line_Items__r.Name,Order_Product__r.Product2.Name,Purchase_Line_Items__r.Product__r.Name,Order_Product__r.Product2.Commodity_Code__c,Purchase_Line_Items__r.Product__r.Commodity_Code__c,Order_Product__r.Product2.Declared_Shipment_Value__c,Purchase_Line_Items__r.Product__r.Declared_Shipment_Value__c from Package_List__c where Package__c != null And Package__c IN:packList];

        if(String.isNotEmpty(ToAddress)) {
            tAddress = (Address__c) JSON.deserialize(ToAddress,Address__c.class);
            toCountryCode = Fedex.getCountryCode(tAddress.Country__c);
            toProvinceCode = Fedex.getProvinceCode(tAddress.State__c);
        }
        Address__c fAddress = new  Address__c();
        if(String.isNotEmpty(fromAddress)) {
            fAddress = (Address__c) JSON.deserialize(fromAddress,Address__c.class);
            FromCountryCode = Fedex.getCountryCode(fAddress.Country__c);
            FromProvinceCode = Fedex.getProvinceCode(fAddress.State__c);
        }
        // if(PackageItems != null && PackageItems != '') packlist = (List<Package__c>) JSON.deserialize(PackageItems,List<Package__c>.class);
        if(myConsVar != null && myConsVar != '') MCW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper.class);
        if(ShipDateStamp == null || ShipDateStamp == '') ShipDateStamp = String.valueOf(System.today());
        system.debug('ShipDateStamp : '+ShipDateStamp);
        String myDT = ShipDateStamp + ' ' + 0 + ':' + 0 +  ':' + 0;
        system.debug('myDT~>'+myDT);
        DateTime dt = datetime.valueOf(myDT);
        system.debug('dt~>'+dt);
        DateTime dtnew = datetime.newInstance(dt.year(), dt.month(), (dt.day()), 0, 0, 0);
        system.debug('dtnew~>'+dtnew);
        String shipmentDate = dtnew.format('yyyy-MM-dd');
        ShipDateStamp = shipmentDate;
        String endpoint = MCW.endpoint + '/ship/v1/shipments';
        system.debug('endpoint : '+endpoint);
        String token = getAccessToken(MCW.parentKey,MCW.parentPassword,MCW.childKey,MCW.childpassword,MCW.endPoint);
        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeStringField('labelResponseOptions', ship.Label_options__c);
        gen.writeStringField('CustomerTransactionId', tAddress.Contact__r.Name);
        gen.writeFieldName('requestedShipment');
        gen.writeStartObject();
        gen.writeFieldName('shipper');

        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(shipFromContact != null){
            gen.writeStringField('personName', shipFromContact.Name);
            gen.writeStringField('phoneNumber', shipFromContact.Phone);
            if(isReturnShipment && packList.size() > 0 && packList[0].Logistic__c != null && packList[0].Logistic__r.Account__c != null && packList[0].Logistic__r.Account__r.Name != null && packList[0].Logistic__r.Account__r.Name != ''){
                gen.writeStringField('companyName', packList[0].Logistic__r.Account__r.Name);
            }
            //else if( shipFromContact.Company__c != null &&  shipFromContact.Company__c != '') gen.writeStringField('companyName', shipFromContact.Company__c);
            else if( shipFromContact.Company_Name__c != null &&  shipFromContact.Company_Name__c != '') gen.writeStringField('companyName', shipFromContact.Company_Name__c);
            else gen.writeStringField('companyName', shipFromContact.Account.Name);
        }
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        gen.writeFieldName('streetLines');
        gen.writeStartArray();
        gen.writeString(fAddress.Address_Line1__c);
        if(fAddress.Address_Line2__c != null && fAddress.Address_Line2__c != '') gen.writeString(fAddress.Address_Line2__c);
        if(fAddress.Address_Line3__c != null && fAddress.Address_Line3__c != '') gen.writeString(fAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', fAddress.City__c);
        gen.writeStringField('stateOrProvinceCode', FromProvinceCode);
        gen.writeStringField('postalCode', fAddress.Postal_Code__c);
        gen.writeStringField('countryCode', FromCountryCode);
        gen.writeEndObject();
        gen.writeFieldName('tins');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('number', '123456789');
        gen.writeStringField('tinType', 'PERSONAL_STATE');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();

        gen.writeFieldName('recipients');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(shipToContact != null){
            gen.writeStringField('personName', shipToContact.Name);
            gen.writeStringField('phoneNumber', shipToContact.Phone);
            if(!isReturnShipment && packList.size() > 0 && packList[0].Logistic__c != null && packList[0].Logistic__r.Account__c != null && packList[0].Logistic__r.Account__r.Name != null && packList[0].Logistic__r.Account__r.Name != ''){
                gen.writeStringField('companyName', packList[0].Logistic__r.Account__r.Name);
            }
            //else if(shipToContact.Company__c != null &&  shipToContact.Company__c != '') gen.writeStringField('companyName', shipToContact.Company__c);
            else if( shipToContact.Company_Name__c != null &&  shipToContact.Company_Name__c != '') gen.writeStringField('companyName', shipToContact.Company_Name__c);
            else gen.writeStringField('companyName', shipToContact.Account.Name);
        }
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        gen.writeFieldName('streetLines');
        gen.writeStartArray();
        gen.writeString(tAddress.Address_Line1__c);
        if(tAddress.Address_Line2__c != null && tAddress.Address_Line2__c != '') gen.writeString(tAddress.Address_Line2__c);
        if(tAddress.Address_Line3__c != null && tAddress.Address_Line3__c != '') gen.writeString(tAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('city', tAddress.City__c);
        gen.writeStringField('stateOrProvinceCode',toProvinceCode );
        gen.writeStringField('postalCode', tAddress.Postal_Code__c);
        gen.writeStringField('countryCode', toCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeStringField('shipDatestamp', ShipDateStamp);
        gen.writeStringField('serviceType', rateService);
        gen.writeStringField('packagingType', 'YOUR_PACKAGING');
        gen.writeStringField('pickupType', 'USE_SCHEDULED_PICKUP');
        gen.writeBooleanField('blockInsightVisibility', false);
        gen.writeNumberField('totalPackageCount', packList.size());
        contact BillCon = new contact();
        String BillConID = ship.Billing_Contact__c;
        if(BillConID  != '' && BillConID != null){ BillCon = [Select Id,Name,Company__c,Phone,AccountId,Account.Name,Account.Phone from contact where Id =:BillConID limit 1];
        }

        Decimal totalWeight = 0;
        Decimal totalDeclaredValue = 0;
        Decimal estimatesShipAmount = 0;
        Decimal InsuranceCharges = 0;
        Decimal ShipVATAmount = 0;
        for(Package__c p : packList){
            totalWeight += p.Weight__c;
            totalDeclaredValue += p.Declared_Value__c;
            if(p.Order__c != null){
                if(p.Order__r.Estimated_Shipping_Amount__c != null) {
                    estimatesShipAmount += p.Order__r.Estimated_Shipping_Amount__c;
                }
                if(p.Order__r.Shipping_VAT__c != null) { ShipVATAmount += p.Order__r.Shipping_VAT__c; }
                if(p.Order__r.Insurance_Charges__c != null) { InsuranceCharges += p.Order__r.Insurance_Charges__c; }
            }
        }

        gen.writeFieldName('TotalWeight');
        gen.writeStartObject();
        if(packList[0].Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
        else gen.writeStringField('units', 'LB');
        gen.writeNumberField('value', totalWeight);
        gen.writeEndObject();
        gen.writeFieldName('shippingChargesPayment');
        gen.writeStartObject();
        gen.writeStringField('paymentType', ship.Shipment_Billing_options__c);
        gen.writeFieldName('payor');
        gen.writeStartObject();
        gen.writeFieldName('responsibleParty');
        gen.writeStartObject();
        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('value', MCW.accountNumber);
        else gen.writeStringField('value', ship.Billing_Account_Number__c);
        gen.writeEndObject();
        gen.writeFieldName('contact');
        gen.writeStartObject();
        if(ship.Shipment_Billing_options__c == 'SENDER' && shipFromContact != null) gen.writeStringField('personName', shipFromContact.Name);
        else if(BillCon != null && BillCon.Name != null) gen.writeStringField('personName', BillCon.Name);
        gen.writeEndObject();
        gen.writeFieldName('address');
        gen.writeStartObject();
        Address__c biladd = new Address__c();
        String billcountrycode = '';
        string billAddId = ship.Billing_Address__c;
        if(ship.Billing_Country_Code__c != null) {  billcountrycode = ship.Billing_Country_Code__c; }
        else if(billAddId != null && billAddId != ''){ biladd = [Select Id,Name,Address_Line1__c,Address_Line2__c,City__c,State__c,Postal_Code__c,Country__c from Address__c where Id = :ship.Billing_Address__c  limit 1];billcountrycode = Fedex.getCountryCode(biladd.Country__c);
        }
        if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('countryCode', FromCountryCode);
        else if(ship.Billing_Country_Code__c != null) { gen.writeStringField('countryCode', billcountrycode);
        }

        gen.writeEndObject();gen.writeEndObject();gen.writeEndObject();gen.writeEndObject();gen.writeFieldName('shipmentSpecialServices');gen.writeStartObject();gen.writeFieldName('specialServiceTypes');gen.writeStartArray();
        if(isReturnShipment){ gen.writeString('RETURN_SHIPMENT');}
        else if(ship.Fedex_Special_Services__c != null && ship.Fedex_Special_Services__c != '') gen.writeString(ship.Fedex_Special_Services__c);
        gen.writeEndArray();
        if(isReturnShipment){
            gen.writeFieldName('returnShipmentDetail');gen.writeStartObject();gen.writeStringField('returnType', 'PRINT_RETURN_LABEL');gen.writeEndObject();
        }
        gen.writeEndObject();
        if(FromCountryCode != toCountryCode) { gen.writeFieldName('customsClearanceDetail'); gen.writeStartObject(); gen.writeFieldName('commercialInvoice'); gen.writeStartObject(); gen.writeFieldName('comments'); gen.writeStartArray(); gen.writeString('FEDEX BUSINESS'); gen.writeEndArray(); gen.writeFieldName('customerReferences'); gen.writeStartArray(); gen.writeStartObject(); gen.writeStringField('customerReferenceType', 'CUSTOMER_REFERENCE'); gen.writeStringField('value', '123456789'); gen.writeEndObject(); gen.writeEndArray(); gen.writeFieldName('taxesOrMiscellaneousCharge'); gen.writeStartObject(); gen.writeNumberField('amount', ShipVATAmount); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeFieldName('freightCharge'); gen.writeStartObject(); gen.writeNumberField('amount', estimatesShipAmount); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeEndObject(); gen.writeFieldName('dutiesPayment'); gen.writeStartObject(); gen.writeFieldName('payor'); gen.writeStartObject(); gen.writeFieldName('responsibleParty'); gen.writeStartObject(); gen.writeFieldName('address'); gen.writeStartObject(); if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('countryCode', FromCountryCode); else if(ship.Billing_Country_Code__c != null) { gen.writeStringField('countryCode', billcountrycode); } gen.writeEndObject(); gen.writeFieldName('contact'); gen.writeStartObject(); if(ship.Shipment_Billing_options__c == 'SENDER') { gen.writeStringField('personName', shipFromContact.Name); } else if(BillCon != null) gen.writeStringField('personName', BillCon.Name); gen.writeEndObject(); gen.writeFieldName('accountNumber'); gen.writeStartObject(); if(ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('value', MCW.accountNumber); else gen.writeStringField('value', ship.Billing_Account_Number__c); gen.writeEndObject(); gen.writeEndObject(); gen.writeEndObject(); gen.writeStringField('paymentType', ship.Shipment_Billing_options__c); gen.writeEndObject(); gen.writeFieldName('documentContent'); gen.writeString('NON_DOCUMENTS'); gen.writeFieldName('commodities'); gen.writeStartArray(); for(Package_List__c pl :packageItems ) { gen.writeStartObject(); gen.writeFieldName('unitPrice'); gen.writeStartObject(); if(pl.Order_Product__c != null && pl.Order_Product__r.Product2.Declared_Shipment_Value__c != null) gen.writeNumberField('amount',  pl.Order_Product__r.Product2.Declared_Shipment_Value__c); else gen.writeNumberField('amount',  0); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeNumberField('numberOfPieces', Integer.valueOf(pl.Quantity__c)); System.debug('entered Order_Product__c==='+pl.Order_Product__c); if(pl.Order_Product__c != null) { System.debug('entered Order_Product__c != null'); gen.writeStringField('description', pl.Order_Product__r.Product2.Name); } else if(pl.Return_Merchandise_Authorisation__c != null) { System.debug('entered Return_Merchandise_Authorisation__c != null'); gen.writeStringField('description', pl.RMA_Line_Item__r.Ord_Item__r.Product2.Name); } gen.writeNumberField('quantity', Integer.valueOf(pl.Quantity__c)); gen.writeStringField('quantityUnits', 'EA'); gen.writeFieldName('customsValue'); gen.writeStartObject(); if(pl.Order_Product__c != null && pl.Order_Product__r.Product2.Declared_Shipment_Value__c != null) gen.writeNumberField('amount',  pl.Order_Product__r.Product2.Declared_Shipment_Value__c); else gen.writeNumberField('amount',  0); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeStringField('countryOfManufacture', FromCountryCode); gen.writeFieldName('weight'); gen.writeStartObject(); if(pl.Package__r.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG'); else gen.writeStringField('units', 'LB'); if(pl.Logistic_Line_Item__c != null && pl.Logistic_Line_Item__r.Product__r.Weight__c >= 0)  gen.writeNumberField('value', pl.Logistic_Line_Item__r.Product__r.Weight__c); else gen.writeNumberField('value', pl.Package__r.Weight__c); gen.writeEndObject(); gen.writeEndObject(); } gen.writeEndArray(); if(isReturnShipment) gen.writeStringField('purpose', 'REPAIR_AND_RETURN'); else gen.writeStringField('purpose', Ship.Reason_For_Export__c); gen.writeFieldName('recipientCustomsId'); gen.writeStartObject(); gen.writeStringField('type', 'PASSPORT'); gen.writeStringField('value', '12345678'); gen.writeEndObject(); gen.writeFieldName('customsOption'); gen.writeStartObject(); gen.writeStringField('type', 'OTHER'); if(isReturnShipment) gen.writeStringField('description', 'RETURN LABEL'); else  gen.writeStringField('description', 'Sample'); gen.writeEndObject(); gen.writeFieldName('totalCustomsValue'); gen.writeStartObject(); gen.writeNumberField('amount', totalDeclaredValue); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeFieldName('insuranceCharge'); gen.writeStartObject(); gen.writeNumberField('amount', InsuranceCharges); gen.writeStringField('currency', rateCurrency); gen.writeEndObject(); gen.writeEndObject(); }


        gen.writeFieldName('labelSpecification');gen.writeStartObject();
        if(packList[0].Thermal_Labels__c){ gen.writeStringField('imageType', 'ZPLII');gen.writeStringField('labelStockType', 'STOCK_4X85_TRAILING_DOC_TAB');
        }
        else{
            gen.writeStringField('imageType', 'PDF');gen.writeStringField('labelStockType', 'PAPER_85X11_TOP_HALF_LABEL');
        }

        gen.writeEndObject();

        gen.writeFieldName('rateRequestType');
        gen.writeStartArray();
        gen.writeString('LIST');
        gen.writeEndArray();
        gen.writeFieldName('requestedPackageLineItems');
        gen.writeStartArray();
        for (Package__c pl :packList) {
            gen.writeStartObject();
            gen.writeFieldName('insuredValue');
            gen.writeStartObject();
            gen.writeStringField('Currency', rateCurrency);
            if(pl.Order__r.Insurance_Charges__c != null && pl.Order__r.Insurance_Charges__c > 0) gen.writeNumberField('Amount', pl.Order__r.Insurance_Charges__c);
            else gen.writeNumberField('Amount', 0);
            gen.writeEndObject();
            gen.writeFieldName('weight');
            gen.writeStartObject();
            if(pl.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'KG');
            else gen.writeStringField('units', 'LB');
            gen.writeNumberField('value', pl.Weight__c);
            gen.writeEndObject();
            gen.writeFieldName('dimensions');
            gen.writeStartObject();
            gen.writeNumberField('length', pl.Length__c);
            gen.writeNumberField('width', pl.Width__c);
            gen.writeNumberField('height', pl.Height__c);
            if(pl.Weight_Unit__c == 'KGS') gen.writeStringField('units', 'CM');
            else gen.writeStringField('units', 'IN');
            gen.writeEndObject();
            gen.writeFieldName('packageSpecialServices');
            gen.writeStartObject();
            gen.writeFieldName('specialServiceTypes');
            gen.writeStartArray();
            gen.writeString('SIGNATURE_OPTION');
            gen.writeEndArray();
            gen.writeStringField('signatureOptionType', 'SERVICE_DEFAULT');
            gen.writeEndObject();
            gen.writeEndObject();
        }
        gen.writeEndArray();
        gen.writeEndObject();

        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        gen.writeStringField('value', MCW.accountNumber);
        gen.writeEndObject();
        gen.writeEndObject();

        String jsonString = gen.getAsString();


        // Print the JSON string
        System.debug(jsonString);


        //return jsonString;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + token);
        request.setBody(jsonString);

        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n';
        headersString += 'Authorization: ' + request.getHeader('Authorization') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        res.request = requestString;
        //return res;

        Http http = new Http();
        Decimal StatusCode = 0;
        HttpResponse response = new HttpResponse();
        string httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{\"transactionId\":\"APIF_SV_SHPC_TxID3078dc8d-3fb3-413e-9134-790bb97352f8\",\"output\":{\"alerts\":[{\"code\":\"VIRTUAL.RESPONSE\",\"message\":\"ThisisaVirtualResponse.\",\"alertType\":\"NOTE\"}],\"transactionShipments\":[{\"masterTrackingNumber\":\"794903800925\",\"serviceType\":\"FEDEX_PRIORITY_EXPRESS\",\"shipDatestamp\":\"2023-12-05\",\"serviceName\":\"FedEx®PriorityExpress\",\"pieceResponses\":[{\"masterTrackingNumber\":\"794903800925\",\"packageSequenceNumber\":1,\"trackingNumber\":\"794903800925\",\"additionalChargesDiscount\":0.0,\"netRateAmount\":2653.04,\"netChargeAmount\":0.0,\"netDiscountAmount\":0.0,\"packageDocuments\":[{\"contentType\":\"LABEL\",\"copiesToPrint\":1,\"encodedLabel\":\"JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMyAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL091dGxpbmVzCi9Db3VudCAwCj4+CmVuZG9iagozIDAgb2JqCjw8Ci9UeXBlIC9QYWdlcwovQ291bnQgMwovS2lkcyBbMTggMCBSIDE5IDAgUiAyMCAwIFJdCj4+CmVuZG9iago0IDAgb2JqClsvUERGIC9UZXh0IC9JbWFnZUIgL0ltYWdlQyAvSW1hZ2VJXQplbmRvYmoKNSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iago2IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0hlbHZldGljYS1Cb2xkCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKNyAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EtT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjggMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhLUJvbGRPYmxpcXVlCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKOSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9Db3VyaWVyCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTAgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1Cb2xkCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTEgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1PYmxpcXVlCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTIgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllci1Cb2xkT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEzIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLVJvbWFuCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTQgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvVGltZXMtQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE1IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUl0YWxpYwovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE2IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUJvbGRJdGFsaWMKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNyAwIG9iaiAKPDwKL0NyZWF0aW9uRGF0ZSAoRDoyMDAzKQovUHJvZHVjZXIgKEZlZEV4IFNlcnZpY2VzKQovVGl0bGUgKEZlZEV4IFNoaXBwaW5nIExhYmVsKQ0vQ3JlYXRvciAoRmVkRXggQ3VzdG9tZXIgQXV0b21hdGlvbikNL0F1dGhvciAoQ0xTIFZlcnNpb24gNTEyMDEzNSkKPj4KZW5kb2JqCjE4IDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMSAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjE5IDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMiAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjIwIDAgb2JqCjw8Ci9UeXBlIC9QYWdlDS9QYXJlbnQgMyAwIFIKL1Jlc291cmNlcyA8PCAvUHJvY1NldCA0IDAgUiAKIC9Gb250IDw8IC9GMSA1IDAgUiAKL0YyIDYgMCBSIAovRjMgNyAwIFIgCi9GNCA4IDAgUiAKL0Y1IDkgMCBSIAovRjYgMTAgMCBSIAovRjcgMTEgMCBSIAovRjggMTIgMCBSIAovRjkgMTMgMCBSIAovRjEwIDE0IDAgUiAKL0YxMSAxNSAwIFIgCi9GMTIgMTYgMCBSIAogPj4KL1hPYmplY3QgPDwgL0ZlZEV4RXhwcmVzcyAyMyAwIFIKL0V4cHJlc3NFIDI0IDAgUgovYmFyY29kZTAgMjUgMCBSCi9GZWRFeEV4cHJlc3MgMjYgMCBSCi9FeHByZXNzRSAyNyAwIFIKPj4KPj4KL01lZGlhQm94IFswIDAgNjEyIDc5Ml0KL1RyaW1Cb3hbMCAwIDYxMiA3OTJdCi9Db250ZW50cyAyMiAwIFIKL1JvdGF0ZSAwPj4KZW5kb2JqCjIxIDAgb2JqCjw8IC9MZW5ndGggMjU3NgovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdIAo+PgpzdHJlYW0KR2F0PS4+QWtJayduLXNccyQuXFtdMExTV2dIIj9iUnBvKSktJyU/NzY/YTZ1UWI/b09NP1tlJEJZM0szbW1nOT1BV11ZUyRcaU1XXkEvOGIKckdYYUE6WDNeJjlKRl0xNzI3WFQ+MW06MSpIPjU7P2loNEwxcDNrKSp1NkxHWS5CQ0phbk5qam46ZV02RlJZI1xERERoT207V2ZHJFBdLSgKTzsuNS1KcDlLPT9MQVJePzxKI25tZTktbVtKU2lKKSRMXydIXyRNIScrSzUiRUo2XVlGcnFPY1MpKmVvbzVBaSY/ZC0rYUwhYzYsQURyczoKcS9jNFhILCNpWCRORkJzKD8tVTBsbF9uNCYxXGlfPlhqLzw/LmktaGRvPUopPj84XGlMJDNxMSJga2JmbWJiLDdlN3VPYFlFWXA3SHU3XWcKKHFpLWYwIUJLVl5ZVzZGUkMkI2A/Q3Rycj4oIl5uMG8oQGM7LU8uS1ojXi9hVD4lay5KLDhtL1deOz9XcGZMU1k9WSwvXl8uJkpWZzxRbikKZUNSOilSbEdhKlhzPElzJlVBRVQ9RSIzNDwiPTk1XEBdRy1fU0BBN19UI2M6QFNTQFFvQS9pKVVgJUYjWjlDY2Y2cTAuNVNyVVhnQGwvTjoKUVEyOFNOV1JySCIrbStCWkteXWlYZVFVSEF0bWBfWGAjRT9rRipBZixfYSsmUi4/QnRmRzpQWXA7SWJvOFQ/T2AvZyFuTFlpQltAbkAuMEYKbGgqYEw9JypUNEFwJllCTlI4Q2U0LyshRyNLZnQnY1c5J0VMRjxydVVnRFk/ZzpZK0laVmU/ck8jT1EmLVNgL0FXNSJkJm8rK1hWWWZCU1QKVC9TOSJXVEBtJlNhWiQ0R29FN0BjczlKVSlLXl1ERj5yTzFdQSdzams0TilHX1VuWDlSYXA/PmMoUV1XSF5KV0VtY1VMdV4nRStvMDM7NVIKalAjTk1mIlpJO11OXFVAajRAdWM5ZlozTnJOSk5zPGo9Yy9UJWFYMS10OD5xNl9ycU0zXDY2T0NYRyNUJ20ySUwjJEA2NiRNKmxkREVWb10KbTMhQSssaS5YajpaUVVmYk1EVylZTVslKF1tNmZFQSdIPG5DXE40MC1qY1YmVjQ5QjpUby42VFtZSFxhXFw+VU8tKys1al1HZDxRbkNJbEIKSzVHRjshQnEjb09WIXMqKGRacyloWWZwMG1lbmMjMzktcFA4WzouOldbRWJhTyooSS1KKlVGWik3XnM3ZnB0LV0pQE9ERVFJZ2IsKytjPC4KY210LFYudTUiPD5tKytYbUZnaTpjSkFCVEIrKkUoJGNsPHVCazpzUGc+a0g5IyokXDg+PmNRNDVcSzB1cGxCJ0dxZSQ6WCVeZWtCbFJDbzwKMEtqZSoxaikyREo2YyNpaHFLaz8iamNDLCtjRSk6UFlQc2Y2dDQqK1VeQiZcUD4mXVQ7ZlFAJEYmLFZkbE8lRCguNnU6LlBzJmBIUFk1aloKMi9eY18ocSJMUCshIWopQmw3aHNXYzNUZk1lNyMqV2FNSjNaRnNxTUVFdGtDPVdhcTlPYyZwdW5qMCFsal0mYGVMI05nPC1ILmI+aSlgXU4KS2M+c1NFT2dsS3BJVTwkVGQtSWUlSSwwWFUyMUFmTWIiLjtfcHU3XzVtRzsuWkpWQyFLJUJCT09yRCxFOyxrRWBMX2U0b2Q8N3JZXmQwVWsKL1glSVc+Ol9rIU0qNCdcSj42OWNcMm1wNy1IVHNHbEFEVG1VS1NObFQhU1dGZzAjJ0MvJDA5PVckcSJaRVdCVU9wZDsyY01Bajk9OzZFI2gKODFCQzROVShgJyMmbVwvOUovLT5KRTk4Vi5oYEJNVyRvLUleZykwbUs1JTUyV1BYV3A9RytGUyNJJCNLSko3aXNwc20vV1EqPmJbPy0+NmgKWFpXSmNTdTxQZVJULG0lRS5FKEdpMiVzZyomZkRTTm06Oi8oPF51aGxVXCUrSz9ZRSdWcG9mQilnW0h0WHQtS2dOVlxNKm87TkJYYGNfSUQKKiZfT21bVWhHZi1ALSVfXT8rIlM3bDxuQ1tgOGQ+TTVsKkQ+L2A1c0hnYVtKWi82KC1pK1BBYD9IZzdPT2ouaTMyaztHUlliNGY+P2xwU2QKWixVXD1XLkNfPDBKUzwoNFp0NShmJVAiPGVBMEopXnNKR2pWaV06czhXcGZkJDkwUmRqcGUrNWxkQk9bSyRJYyFAYDRTci0tJDprVzRUPDkKIixCPGJrcD9OP05CTSZZZFEpMiFUNVxdVD9LMCRhRzM9WiIycUE0TjNtXklnS1BBSygoPiJnbU5aMiJpVk82R14qMSFcaiJbZTdnRjppQz4KQEVTalordF9XZVoya3JxYWo9UVMiLU9OSEdJSXI8SjplIixHPkZfSCNiKVRXZDwvQ3QqN1lEZkBjJEgrNCslLkpHIiNFSEA4V15kMCpnazwKXDZnRXVec1RCKnFcJzpVay9bX15tPWMjLVcpZXBOTj1PU1xxJ2IoUFoya3BcKCE+ciJUU09mKl0/YVJ0XnFpQHJEKDNvNEI2dSIzbzJXOnQKOCw2OGlfcGJcQVJzKCFxIyopbEpiVHRtQGE6aksjaCguWHRpMzRWdTlZKTosZVxaIUA+dTs+VVpyRjdeJWxeNUM2SmNtTldjNF5vWXFJZ0gKMSJgQ1pTbUBuJWkrUHIrUW5FWyQ9NXVibSQ+Kz4zLXRGTTBmJEtVWyIsQj1VTTNAbTg2VHMrTzdCXlpfUjJdVHFUU2MjOnF1MmVGIyZyJ2QKJktOJCMndVZAXT8vbnFwZDI3cEIuXThwSGZJcGM2S2M+Lkk3UmZ1JGQwYktWaC1GSEspYD0wX0gxYUZNOUlvPHJHX1BHamIlRUgxTikrKEAKa2FtaXJgXnJlIiZAVWZNVnU5ZF1eOjBmXTVLY1AlSGlvbFk6SDdnT2xlQ2ZRcFM0MSxcNF0+PihOSDtnOVQiLixOKEE5PTdCVWNqIlU4aiEKK01RIXUhZ0JyQydtVVQ7QmopTWVvKTslWjc/dGJGWWAlTjM2Tlo6RFxBITw7JUxvI1ZqOV4xMCxpSVIxIVF1SGFbK29PP1Q7QipMZ0k6PD0KLS5EREUuLjpdUkRjbTg8cW9gO2cxPDRIMkgpIl1bP1MyakI9U3VzLkAuQThNSDdzZF8xP2c/Pk0wWWlWSDFWXS4/Im0tTUlZQD4oXldoOFIKSixdJzJMSGtjN1gmIllnLTgjXWlLZSoxRVhPcitGPWFwMD5PYztBb25KO0JyL25WN0xjJFxUVylVam4/SHQkXjREZ2MnSlR1VzMhLjpsKE8KZXBFc14xUiVoL29CMElGclVyTW5kXzNKcUkySnVeYSUlYFJuQi9eU2xTNjQ5QGonKHBxYGZHPnI/JythWWZRfj4KZW5kc3RyZWFtCmVuZG9iagoyMiAwIG9iago8PCAvTGVuZ3RoIDIyNjIKL0ZpbHRlciBbL0FTQ0lJODVEZWNvZGUgL0ZsYXRlRGVjb2RlXSAKPj4Kc3RyZWFtCkdhdD0uRDAkQEwmSDspOHJlImhaVjlEY0BnPTw3PTNVbkRfIj1MU2RQU3ExaC0nV1FZVGgzdGRycWBlYyo4PVNuaVJWVGBrNDc9IUJOUCdUCmgyK0NMJD1OWzpOKTlcLE4zVXIjMS9bL2pXUz1LJGQ+Nz9wRHAzRTU4I3QlZCc7TToqSTJFLWM8clwvRDs4QFs/WkRgMmMlMzBtLyQmaHMlCkFcUV5mOEghZTxSJTtPYkMsUikuKEEiTSdlZyQ5ITUvZCk8b3VGIjY4WkFoP1RSTUBdblp1RTRxdEpSYW05cnMuKmlNaTpoSHRbb085P1VxClFIYWcyL0NcMms+cjlhJDE1R0JDPFZaJjs1MyFeWmM9Y2FUTXAnZk9vU0hIdSJKRVg8K2A3TVpcc1lKSi1ZaD1eVCpgPkxTIWE9Q0VvPCgnCnJJNnF0TmcwWExNJ0NaTy1eMl5rLC9oQjRbZl5HWW87QWM9WDBMQSk2PWtKMiUoK0NtbG5OVUIjSChodCVudTVVM2ROTktsaydbSE9VSVg9ClwzKWhuXlVcVSI7I0tEdHBILGpoRFJESiRpVk9WN1YyaUozUyJfZEk5NiJ1bkhiSlNdKGNXI1pWImolXGBgXiQlVVJHT0JGLzBqOENZUCNXCnI6cC4qMjE5W3UyLS9ZNGJxVFw2ZTM6bGhWLSlSL15dKlZMYl1EISxYTTQ/aVJ1RGJCNClKSVNvWXFjNCZtPT5QTDJhXTczJ01cNEVXMVBnCk04UnAmISUvXGsqWzRgMmA4SV87RyNMTV5dKG4kKmBWVSkiVllKUipyKjRBZWo0YjBCKlwqb1dYO1hfTypRQlAjMkdDMDArYFlvaVViLCQzCjUkLDdVIi8lTSZMKHE7XiUsQnNFWmpqal1VOSwyWCFSIUJiKFg7TDpFbjhIOXI8NlFEbCRdK0Q1SG5zcms6aiVoPShNPUoxOnJcRlFKOUw4CmBzN1hLUl4xRWI9OUBOW1hmXyRzKk8kUEE3Vy84XTNWQ15uJkxSX0sjQSU1WlssVjQuYGQoUDhdZj4zOCpxJUxQZElMLi9MYyI2SylXNkBmCll1VDclP3BZYTc5dGxTK0pLcT4xJ3EjLChQPGolSF0tRnAlSSNPVWllQ1tOJiI7ZFcyV1UtQmpbUSlYQm9nUTVNYGAqTyE6ZFBjQmA2am5hClVfclsjVS9KZDslV2dyTEItPmVGTWo8TltANyJhXXA7RWBlUmxPYCFeX043PS1GPixhRyRZVyhvJ0guP2RnREpkKUswYD9sOj0vRWFUZ00nCmR0ODtAPVdNUGwmSSNtNSMjaW51P3BZYTcwa0BiXzhFZGllN0FiU0FBXSI7TDgqY2A/USxHK1taNjhYIV02U10vUDRhQk5OUmZhXV5ndSIhCmVCZmRXOV1Gais3ISp0bU1ISEVpSDNZNj9WQUxobFBWQU5LIWNMP1hNdVxkWDMzJ288I25wTCtcZ0NsciRIPDNVJDBNcEpQRE04dGY5QHRfCiR1KSZWQmNbKi1FX11TRSRDRllFa0kxPWtUVG1LIk9YWFspKSphcHInZSNiSGtdNHU+ZV9pVT9DYWlidEUpKCJBO18pOUMpNjtFcT5SciYnCilaRXMnLjo9cC9WOWo+c2NhYVQhQzxgVy8kIlsjRDxlWjNgbGFzOWBSTSRzMmlFYkg5VCU4T1gkPVVFZEYtNkA0W0FkVjMlbypsRSMyR2wrCmR0PGlmJ1NqJmMmZ2lsOD8hXnEuJkQ/VD1vXWEwdUthZDEwWTwwdFtDMGRgajhTKWpaTyZYUldFKUlrRWVzMlZIbUpPXyYrSSJpb2AwbTl0Ci9iWGBeaSxXMD4uV0E6RGRcJVo1SytlUzglLWhqcjMybUghbCNTLkUzKClvQSo6dEM9WCRLZy4+YCJYT2BAYS8lRHBBKWplU2s9PVUiZi06CmNGLWR1M1FUTUguUVNrTi5SXHAjPm45W1tqT1RDRlM0ZVsnU1JSLzVNWU9XOkU9KFowTSFBay5FKU5BaEJGRUZFJysubWtgP0MjMGs4ZGErCiQnZEpZP3NEKC88ZGkiV1I/cVBEU1VIbClMLFpNIz9AZi5YalBqMSdmblcvVCg1TVJVJmduRGRfZzUuOScrLWJMNHUzPjlrXWhZWicuUyEiCitrdUQ1O1csPjpXNEsuTThWTEYoYDo9UDNiRFdSOFkvRW5jcjMwZDdpZTUvOFRtTytTTTBKOiVBJCtMTjMyJmJeRmlZITVwdUZjQz4jYUxXCihBVTdDWHJhK19VOFZBMzo6cFw6YGA8USZMSWwoKlldYSstS0wzS2BCbTlHJmlUdTZqNlxwUTw2blxBRSRuPzZwQ1ZtOy48OHNdP0VXKz48ClotUmheJFc3UWRFJ2c2KGgqUjMtKSI0OytbPU9aKFdETj89Sz5FQ29AcW5lSkhaNmkwTG5vSCplJChxVzAwIV5fOnVcOGRLZ0NiN0haMmxWCjMzOzUsMzInMCNANGVcJCQwTl8hJWRpUixiSCFwKVRiXCVfOjIzWWlRPiZPJS8tVytERzYrYmRYQTkmbSphLyFAPyltdVpoSURHJ2Y0bzNwCltbUFlsLkE0YydLXlEnQyxGYiU5JkVBO1k6JChtSEI+WEA6cFc5bkJFZVxZTm1RJEVxWDNeUCpwdV8wMnMxQ0ZQZDtEX3Q5VWssdU49UjRpCkVMNFRiOEAhNVRlJyY8Ly0+WDNsYllJPjIscyFAKF9ac24mODhHSnQ5aGxaI0MzJzxaKTY4UF9yQWRjOUZAVW5cSCc/TGBkXUtmUl0zPEVlCm1sP1QpSUZuaEgpalsuR14jaTBzXWwxVkM/YmJCJmg7LCdwYzA0PzdgRVVaS1g4UlhhYkVuZD9aZnArJkdGbCxFUCxGVVxjLWdcaiNjPmQ4CisqZzRLLkhGdUlIKCZnRFw/TElhZEk0UmhdQV1ZTSEmRSZpMUxpKl1dN1pGdWdUdTFPZEJYcTYpW0haR3AlUi9ScnJbQC0uRkp+PgplbmRzdHJlYW0KZW5kb2JqCjIzIDAgb2JqCjw8IC9UeXBlIC9YT2JqZWN0Ci9TdWJ0eXBlIC9JbWFnZQovV2lkdGggMTE4Ci9IZWlnaHQgNDkKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDQ2MQovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9lSkldUj8jWG5Ya1Q2QT5YS25EYldCIk1aRWFqUHBkNF0nKF5AUmx0ImtCIlMwJGYlPz1tPTRDOzsuJE4oalJjWVIlc2QmbDkkT3ReCikmNz1MKDctZXFxZUAuKC9TQzk4NC1mTFhlTFo1cWNaNWxBRUI1NT4zQDA9ayI7UmgyaEJjUUwzJko/NW9bY0gwYlNGTl48OztANDFTWTltCmMiWkk9WWwjYzQpYF8iWWxtTjMlLkEubE5TYFZlL1k8JT8uNygoKS8uZEJbO2shSlslJyVESlxJPythNzo1b05rWVxxRVM+MzxJNWJabShJCiVkPEBCKThEYnQzcEtHY2xiUWsxJ2laVnM3Tk0wXG8mUipxVT5nSHUtRnJDa2g8a0hGRypcJE09X3NWLy0kXEpGOmUvPz5mWEErQ0NtcERlCmRTUDZHY3UsXFgnQUw9YTVKQ1s0NkcuaHAyPVU0ZV4kZW9cUSNiKm03QzgkLUpBKGNaP1lgJ0M7NkpwSGVQbFwkSEVDIXVeKlFhKzZnRU1rCltmRVYqYi4jPnByPi1XU2YjPmgmVz91a2tUc2hZYD0vWC42NkEqO2Jpcy9kZ0BRWFhzcjhtO34+CmVuZHN0cmVhbQplbmRvYmoKMjQgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCA1NAovSGVpZ2h0IDU0Ci9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCA3NwovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIjBKZDBUZHEkajRvRl5VLCJIVHM5RUlFOzBBVCxfRSpMWiVvQDdKbDVWO0gnQ3M9VHJxRGFILjRCZiNjNE9WVDsoZCNmPEdFOX4+CmVuZHN0cmVhbQplbmRvYmoKMjUgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCAyOTQKL0hlaWdodCA2NwovQ29sb3JTcGFjZSAvRGV2aWNlR3JheQovQml0c1BlckNvbXBvbmVudCA4Ci9MZW5ndGggMTM2MgovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9jPWAsM0YkcSM9PzkvRWZNXD5bRzYmME5VZzZRSTs6WTE+cCdcTz5rbGNUWDkwUzs0OnQqc19WOCNfIWJASSpjZidzJCxPLTVOW0JBCl9sSmFWQiZdZmhDN2Q7XiwyZj1nSyYzOXBRLU1sc0kzc2EtR05qJCdONU5yLGRTZnBKOSQwOGRAKGc9JCdYR21gWC5FX1BaVj4tUnA/QGFaCithVzFbYFsjMEgyP3BgQFVbSWVlKCJHM1lRZFNkQzk/QHRiXjtdcWdSWSNcX1dDLT48al5GcSNDJyFxZWI4UE9UXFZjSGNVVFUwXEFGKFBIClRALE05Y1ooQmNWNW9pVnJaUC5XU0IkMl43JGgxTic4KDxiNkBHTmFrKSNjNmFMY1I3JmFacnAuVydbSDorSUZbTjBfbWlcanJhcS4pSTApClwpIipcP2YzPW1HRiZwM2ZFY1JoSGFNTVM3Rzg9bkxtT14lSDZmMzI0NVZBM08vOTRKWSMxKDNdJWUkOk1Db3BtRDUzbVw9dDNEblprN1hTCipLPFtJR3AsVGQ7ImFYUltQN2QsVWtDOnFWMCY+LS8kPnItJF0rNFIoSE8mSkllLW1PIyxlYlNINCRbZjMnOXA6PUFeW2g9SCIuLVw+NWpJCmEqbjZrPSpuWDEvWiFxYyQrI3E5L2dYVGhFTDdYc2FxRG1jK11WXFRaJTdaYVZQWGNxTCJYK1k6TFNeOzBQVGpgO3R1Wyw7WWdcbGUxVClRCk0wQjJpNnAoJCVLI01FKFFvJV91ZVskJENZOFQvcl9JKFNUVV9ocG4vI0MmKi5kYHFaX2NvYCtrcidodFU8O2IpYTBNa1YkVj1OdWtnMSMyCjNoJkV0YFQ7JjwhU0tyUzFeQzhGNE1eTWNmWURUbylFYjVVVjU4OXQnIyQlNTQtRmEvYzRqSFVQPHFqUS49YzI4PFFoYnBIc0RpT2EpVyJbCm9QQTAvTlpsOlBRQl5POlBhOWBUOGhsbkpmJ1xlR0U2KD4yTENvSW4zKihDRSxUWTpsLS4yTGhiQCRORCZRLCJTYGlYPSM2IUUlKjtIY1tPCi5CLE8vR1BTMVtEblFZRkhLLF50JiQ5cGYkKzw9UCo/Sz9OMzUtPikzJi1dIVsvVUpoW2prJGIuSydaJHBHaUtCJV1KZW4oKTxwQUE4SS4xCiYoTS9cPXEvXT1aJzgySmtnK0VMaT1iMS1RPTtTOTh0V0ZwOGtcRCwtJTNgbyhUMSg4ZFBhZmw/IyoyWnBZcTprckBIPk9pZW1tdEI4K2EzClRjc21MPEhhQHVbJDl1V1ApS1ZiQjRRbztNWUAuNWooOGJyVVpoXDEjO1VXNy9aIzw5Ii1kUUg6XUx0MzNXYSVhWlVyKGMmU1BUKj9DMnUlClMzJy01Q0ZnaSVtRiMkKWNoWk9OZXElIjluXXBqUCQ9Nj10a3BAXmInWkxRcEpOLzhSVD89QmNWaSZvK1FlISYxLSZiWDNnNWdDWjQkO1g8CmRJPzFYLkRZZV1AQ3E7Py8+XTFiUEw+PDlVPG5va2pnKCFQN1ZPTC89cCVxWyZUY0kmNkNdYCInOVZzND9AOSs9QzVvZkBVby81amBvLU5vClFkU2RDOUJmRkM5Ok5vWjE2PFo0SjFQWEhtV01QZyxib3JTS1tTVzJOSC9WSWwpcDEkJ1g2KykqOFF0MDtTI1lcLi8sMycpO1lHcjZYT3NoCiVJSyVKOlMqWFIuQzk5MzMjVi0yP1N0Lz0hJy9HRlwnPEVOayMyMTdURlgyTFY2bEskUS1xakdJWFY7cV5yS15+PgplbmRzdHJlYW0KZW5kb2JqCjI2IDAgb2JqCjw8IC9UeXBlIC9YT2JqZWN0Ci9TdWJ0eXBlIC9JbWFnZQovV2lkdGggMTE4Ci9IZWlnaHQgNDkKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDQ2MQovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIi9lSkldUj8jWG5Ya1Q2QT5YS25EYldCIk1aRWFqUHBkNF0nKF5AUmx0ImtCIlMwJGYlPz1tPTRDOzsuJE4oalJjWVIlc2QmbDkkT3ReCikmNz1MKDctZXFxZUAuKC9TQzk4NC1mTFhlTFo1cWNaNWxBRUI1NT4zQDA9ayI7UmgyaEJjUUwzJko/NW9bY0gwYlNGTl48OztANDFTWTltCmMiWkk9WWwjYzQpYF8iWWxtTjMlLkEubE5TYFZlL1k8JT8uNygoKS8uZEJbO2shSlslJyVESlxJPythNzo1b05rWVxxRVM+MzxJNWJabShJCiVkPEBCKThEYnQzcEtHY2xiUWsxJ2laVnM3Tk0wXG8mUipxVT5nSHUtRnJDa2g8a0hGRypcJE09X3NWLy0kXEpGOmUvPz5mWEErQ0NtcERlCmRTUDZHY3UsXFgnQUw9YTVKQ1s0NkcuaHAyPVU0ZV4kZW9cUSNiKm03QzgkLUpBKGNaP1lgJ0M7NkpwSGVQbFwkSEVDIXVeKlFhKzZnRU1rCltmRVYqYi4jPnByPi1XU2YjPmgmVz91a2tUc2hZYD0vWC42NkEqO2Jpcy9kZ0BRWFhzcjhtO34+CmVuZHN0cmVhbQplbmRvYmoKMjcgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCA1NAovSGVpZ2h0IDU0Ci9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCA3NwovRmlsdGVyIFsvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGVdCj4+c3RyZWFtCkdiIjBKZDBUZHEkajRvRl5VLCJIVHM5RUlFOzBBVCxfRSpMWiVvQDdKbDVWO0gnQ3M9VHJxRGFILjRCZiNjNE9WVDsoZCNmPEdFOX4+CmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDI4CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAwOSAwMDAwMCBuIAowMDAwMDAwMDU4IDAwMDAwIG4gCjAwMDAwMDAxMDQgMDAwMDAgbiAKMDAwMDAwMDE3NiAwMDAwMCBuIAowMDAwMDAwMjI4IDAwMDAwIG4gCjAwMDAwMDAzMjYgMDAwMDAgbiAKMDAwMDAwMDQyOSAwMDAwMCBuIAowMDAwMDAwNTM1IDAwMDAwIG4gCjAwMDAwMDA2NDUgMDAwMDAgbiAKMDAwMDAwMDc0MSAwMDAwMCBuIAowMDAwMDAwODQzIDAwMDAwIG4gCjAwMDAwMDA5NDggMDAwMDAgbiAKMDAwMDAwMTA1NyAwMDAwMCBuIAowMDAwMDAxMTU4IDAwMDAwIG4gCjAwMDAwMDEyNTggMDAwMDAgbiAKMDAwMDAwMTM2MCAwMDAwMCBuIAowMDAwMDAxNDY2IDAwMDAwIG4gCjAwMDAwMDE2MzYgMDAwMDAgbiAKMDAwMDAwMjA1MyAwMDAwMCBuIAowMDAwMDAyNDcwIDAwMDAwIG4gCjAwMDAwMDI4ODcgMDAwMDAgbiAKMDAwMDAwNTU1NSAwMDAwMCBuIAowMDAwMDA3OTA5IDAwMDAwIG4gCjAwMDAwMDg1NTYgMDAwMDAgbiAKMDAwMDAwODgxNyAwMDAwMCBuIAowMDAwMDEwMzY2IDAwMDAwIG4gCjAwMDAwMTEwMTMgMDAwMDAgbiAKdHJhaWxlcgo8PAovSW5mbyAxNyAwIFIKL1NpemUgMjgKL1Jvb3QgMSAwIFIKPj4Kc3RhcnR4cmVmCjExMjc0CiUlRU9GCg==\",\"docType\":\"PDF\"}],\"currency\":\"SEK\",\"customerReferences\":[],\"codcollectionAmount\":0.0,\"baseRateAmount\":650.0},{\"masterTrackingNumber\":\"794903800925\",\"packageSequenceNumber\":2,\"trackingNumber\":\"794903800936\",\"additionalChargesDiscount\":0.0,\"netRateAmount\":2653.04,\"netChargeAmount\":0.0,\"netDiscountAmount\":0.0,\"packageDocuments\":[{\"contentType\":\"LABEL\",\"copiesToPrint\":1,\"encodedLabel\":\"JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwovUGFnZXMgMyAwIFIKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL091dGxpbmVzCi9Db3VudCAwCj4+CmVuZG9iagozIDAgb2JqCjw8Ci9UeXBlIC9QYWdlcwovQ291bnQgMQovS2lkcyBbMTggMCBSXQo+PgplbmRvYmoKNCAwIG9iagpbL1BERiAvVGV4dCAvSW1hZ2VCIC9JbWFnZUMgL0ltYWdlSV0KZW5kb2JqCjUgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKNiAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9IZWx2ZXRpY2EtQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjcgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvSGVsdmV0aWNhLU9ibGlxdWUKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iago4IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0hlbHZldGljYS1Cb2xkT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjkgMCBvYmoKPDwKL1R5cGUgL0ZvbnQKL1N1YnR5cGUgL1R5cGUxCi9CYXNlRm9udCAvQ291cmllcgovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEwIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItQm9sZAovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjExIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItT2JsaXF1ZQovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjEyIDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL0NvdXJpZXItQm9sZE9ibGlxdWUKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxMyAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1Sb21hbgovRW5jb2RpbmcgL01hY1JvbWFuRW5jb2RpbmcKPj4KZW5kb2JqCjE0IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UeXBlMQovQmFzZUZvbnQgL1RpbWVzLUJvbGQKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNSAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1JdGFsaWMKL0VuY29kaW5nIC9NYWNSb21hbkVuY29kaW5nCj4+CmVuZG9iagoxNiAwIG9iago8PAovVHlwZSAvRm9udAovU3VidHlwZSAvVHlwZTEKL0Jhc2VGb250IC9UaW1lcy1Cb2xkSXRhbGljCi9FbmNvZGluZyAvTWFjUm9tYW5FbmNvZGluZwo+PgplbmRvYmoKMTcgMCBvYmogCjw8Ci9DcmVhdGlvbkRhdGUgKEQ6MjAwMykKL1Byb2R1Y2VyIChGZWRFeCBTZXJ2aWNlcykKL1RpdGxlIChGZWRFeCBTaGlwcGluZyBMYWJlbCkNL0NyZWF0b3IgKEZlZEV4IEN1c3RvbWVyIEF1dG9tYXRpb24pDS9BdXRob3IgKENMUyBWZXJzaW9uIDUxMjAxMzUpCj4+CmVuZG9iagoxOCAwIG9iago8PAovVHlwZSAvUGFnZQ0vUGFyZW50IDMgMCBSCi9SZXNvdXJjZXMgPDwgL1Byb2NTZXQgNCAwIFIgCiAvRm9udCA8PCAvRjEgNSAwIFIgCi9GMiA2IDAgUiAKL0YzIDcgMCBSIAovRjQgOCAwIFIgCi9GNSA5IDAgUiAKL0Y2IDEwIDAgUiAKL0Y3IDExIDAgUiAKL0Y4IDEyIDAgUiAKL0Y5IDEzIDAgUiAKL0YxMCAxNCAwIFIgCi9GMTEgMTUgMCBSIAovRjEyIDE2IDAgUiAKID4+Ci9YT2JqZWN0IDw8IC9GZWRFeEV4cHJlc3MgMjAgMCBSCi9FeHByZXNzRSAyMSAwIFIKL2JhcmNvZGUwIDIyIDAgUgo+Pgo+PgovTWVkaWFCb3ggWzAgMCA2MTIgNzkyXQovVHJpbUJveFswIDAgNjEyIDc5Ml0KL0NvbnRlbnRzIDE5IDAgUgovUm90YXRlIDA+PgplbmRvYmoKMTkgMCBvYmoKPDwgL0xlbmd0aCAyNjUzCi9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0gCj4+CnN0cmVhbQpHYXQ9LjlvZzVQJyJuXEJJaXNoRyFjNlRnV1pvVkZILjk5Nk8jPTZeQD9VXSVsbUMiZFolYHA9RzgnJmhrRTF1YylOaERHQmMrOytITW5tZgpYPWxLZHE4bGQhYjY1XyE+Wj0jXFVtMkMkZExpczIjVVlaJzkmbSlOcGhvVkxpTXBQQ1IvRG46IUMlRStVazpVUm5yU3RmQm9lJTo/KGcsVwpMSmwoOiQwKGM6SGJOXUhJOjYsVF0zYz4pZUYoWToxKCNILW08J0o1OixNJSZgPm8vXmc6XmpsWU1cM25JSihrUWhodWMoVEo2M3ROXCJLcgo1NWs2OT0iOSJCVi1WIkFAZCpzPiYxP0ZJJWU4VjY9U1pwM1stR09eYis9Y2BrMW0mSEFSSEtgTHUoWCJZa2lxNG1hXy83WGQ2VHBSRjhJMgpZSDMnalVcPiM1amppZTJRYi1uUSEyUy83UVk0Y2gvXS1fTFFzSVNdVzMqbENaPyQ4ZisyPk9aSixKSGZZWDN1XXBmTjo0PVktKSRfLiZKZgpnPE1AQ1dAc0hbMmZXLm0vMFRqbyRrSlIpYSpSPzxhKV1mN2E2aCt0J0YjPSUtOHNGUSdRWm1PUlchRTUsWWJKTlBQKlRSLDlrJF5ub1N0ZwolRi4raF91MCllLidPLjhfImZEX1NeKi5mRmdUJCY5UVYyUG9nP1twUiQvYlBVZWhtQTtkOXFOW0tZdVpJPEdhY1JDRVEzaWssOFI4UEBENQo2QEQpa0dhUSZLODJwcDRbKSVkSGhFbWpiWGU1LWdSWlMxM1tWJygjTHReNDFbQ0k+P0RmNnVGa25ETU9sbF5UZWtyN0FpYk9uPyw9M20yZQpjMD5CKTBoK3MvaygmXV8qQE9fOjRCbWVsKjI2XXJNIlM6R28+VSRiPHVcUE9yYyE6bEkyJWwsTEE2W1AyMVBXUyVYU1dTXTZVYE9bcWBIVwpEPEpNbUFLRj9TNCoyOjdsTldvUiI1V1dyb0IsMVldbTlFNFY9OmgqK0JeWXVFY0VZSnFbT3QtVzRWa0Y4Y1JaPj0zRD02NSIqPVhsXnRtbgpoUUYhMm5dUzsiVk9YQkJvZUFdQTxqPFguZUYpSU5pVzVbcVoqIzw/TFhCTzwvNzd0TiFOckI1clxfTC5hIzJZdD02blc2XVwwXWBDazIrQApWOkQrME9kdGlRXFwkXEJlWEtXIWY1RlltPUVCPmJnLSRPbzk3Z2khQmRYKC8tdEJXc202MXJNWUhQLTAkKj9RKFd1PUpdcjIlRic/bFJpPApKQm5OYSZtUz88XXBDaDddM2lBJlplbSlCQkRgSCcuNkJtR0hicFghUWtzMCJmQyFAQyZNKC9XaDpaNzdAbUs2Sm82QVhES10lZUtlPmQkMAozYy1EZ24oSSY8Y0JuOyItT1xXZThWZ0BzQmsvWDZnPnIrUiJwTldqPj5qcFo1XEswdXBuJnBsXS1kdS0lXmVsY29iP3Q2UWxeJThiQV5DWwohVU5GaEk4PkpqMG1IMCkkPGA2NTtgWTIiO1UoN2NWJF0uQi1eZj9SVnJHZSdrRlBNKGxPKCZPLjpBbkcvcG01Li5AL1tTMi9eY19mT08tSAorISFqKUMjQD5TV2MzVGZNZTcjKlkrVkkjWjk8LSlFRiM5RVciNC8/T2MiTW5xJmlQRzNZY09TNj8ubS5HQG83X0MmSEtwV2MzU1dpWzBqWgpNQnVsQUE/SS5WaiRuYV43JSZTSV9IMChNRj5bc19dKyoyKERMPTBGbFopVDZmKVE8K2FfMy9hQ0JSaUJCOz1pZDxQVyVCME5qa19LRXIkOAo9NlVcYGsyRj5IWCE8ZDBqQ2tOLl1jJmxBOl4yJWkxVmZQNE09Im0qIyZtTktnUl9CRltBPl1tRWtQL3IhIk1aNG5tV242LF4pJko8czBKWApANDxXOE4yMkJqN2JxQE4pRTk1LnAnbUJeMDs2YlpvVFVpXFRfa0dPUVpVdU1vWS08NGtSKD4qZDQmTiRQKUdXSTR1YmhhZXMhK2JVVlo5LApvRUgvMSMlImw1a0k9cUQvOURwX1pXUE1UPlh0YXAlYj5mWjo5IUJLMj10KFJsUkdvRWQ8MjEzSGc0IlxGTGhzJSVOQDhHZ1g3JGMnPjtASQpdPjdHSzdxXCcwQ18kY3RQSCcvTlpca1VaNzxwXSo3RlBQPilFQCFuQkdcI0hIOjBQKVRjNmBBREhKPE8jMiJdJVcyZCssMmVxOUwnSDR1UQptXGAjKV8tNVQ5TUFlSj4nXi1HK2dDdUNdK1xDK0tXZHF1YjElLTJBPWRNVjQnZnB1LGIocVkrOTkudDFaLmlKQEpBWThpV1g0NUNBJzxTKwozbF9dTCc6cGYkOSx1WClEQkRhOWBwMDNraz81cCFkLV1JYmlqcTI2XERbYjknVShgKUBFRnQwMVhycU4tLExuR0Q6cjtlVWtPLE9dRSciQwpQRy1ELF90IWosRy4uZjpKOmUuMDpKW0p1I1dpaCJjczxSZzMnJlNeTWc7TUhtLWtBa2dRZWRoX2MhMVEwKmAsN0FOKiU3Sj43I0BwJzI0aApTV087az43MkNjZDkvSVozQkNSMmtHKi1HYjZEb2YuU1FRbTZdOzw+bU9PUy1FJWsuNj5FWCouZyJvPFBIa2dPQFRtU0VjWi1vYCRScydGYQojKilsSmJUdG1ATF9HXTpoK1FvP2kzM29ccERPJzAvUE9zbU0mSj8pLG5qanJVQFZlJCYrMyVpXnNUUFZNamRvdDY2OE1YLlRPIiszTWZMaApkSnRLIjdOLUtfbCl0O09jNywtZGlKWj4tQDBCbDQkOStGJSIuKWJCIyk/RGJwb1tLdSomU2hMYGdmNWZVbUpXcCsmYiU5ZTloaXMrbCpsLAooS1h1LiomaFdILW1hLUcmcVUhVDVaUDxrai5VN1FGPEIkVUJcaEpdZiFuVCskJ2dRKGA1YV1kRFUyRENcakgzTEw2XztuMV40P2JuOEtCOwo/VHAzWy9qOSc8QVcrU148bi1yUUh1UiJfXnJjLCJvNi5hW2ZyZk5gVzs2PkZGTkFZPEJEVCE0OVRQLEU4VDIyXVtFYyVtXmIjY2M8dUciRwpFbjcnTG4pQXRmPGxdaio1PnU+cEFUblJMVTpDLG1fIlxTR0RdYlE9Sy1yTCRfTD5BcW5EQWE7YjhhJFpnaG4xKVZSYjk1PEBBUVg5XU0yLwpdVUAwXUFKST5yMERqREYqKUFXV1EkV0ZRXE5HN0tuXzZDSGlvUztTQUg0L0lkVFFKXEYiU2okQDM5O1pLRE9ncWVETDNlcyJYUURsYzQ0QQo1LG0oZmBTVj1GcU9ZUWhzLSVKSD82LWtaLzpbWXJhTiFTbnBfTy0kLzd1JUpjJFxUVylAX3EkPlZXUj5GTkI7bkxFPS9RLFs5c3JqTHMwZQo0Iz8tOXJxWileJW1SaFhLbGg1ZUMqLzVybC8/JVloMSdQOmczUFNxYzU9V2pzOEBGY1wlX29ZcD5gXn4+CmVuZHN0cmVhbQplbmRvYmoKMjAgMCBvYmoKPDwgL1R5cGUgL1hPYmplY3QKL1N1YnR5cGUgL0ltYWdlCi9XaWR0aCAxMTgKL0hlaWdodCA0OQovQ29sb3JTcGFjZSAvRGV2aWNlR3JheQovQml0c1BlckNvbXBvbmVudCA4Ci9MZW5ndGggNDYxCi9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiL2VKSV1SPyNYblhrVDZBPlhLbkRiV0IiTVpFYWpQcGQ0XScoXkBSbHQia0IiUzAkZiU/PW09NEM7Oy4kTihqUmNZUiVzZCZsOSRPdF4KKSY3PUwoNy1lcXFlQC4oL1NDOTg0LWZMWGVMWjVxY1o1bEFFQjU1PjNAMD1rIjtSaDJoQmNRTDMmSj81b1tjSDBiU0ZOXjw7O0A0MVNZOW0KYyJaST1ZbCNjNClgXyJZbG1OMyUuQS5sTlNgVmUvWTwlPy43KCgpLy5kQls7ayFKWyUnJURKXEk/K2E3OjVvTmtZXHFFUz4zPEk1YlptKEkKJWQ8QEIpOERidDNwS0djbGJRazEnaVpWczdOTTBcbyZSKnFVPmdIdS1GckNraDxrSEZHKlwkTT1fc1YvLSRcSkY6ZS8/PmZYQStDQ21wRGUKZFNQNkdjdSxcWCdBTD1hNUpDWzQ2Ry5ocDI9VTRlXiRlb1xRI2IqbTdDOCQtSkEoY1o/WWAnQzs2SnBIZVBsXCRIRUMhdV4qUWErNmdFTWsKW2ZFVipiLiM+cHI+LVdTZiM+aCZXP3Vra1RzaFlgPS9YLjY2QSo7YmlzL2RnQFFYWHNyOG07fj4KZW5kc3RyZWFtCmVuZG9iagoyMSAwIG9iago8PCAvVHlwZSAvWE9iamVjdAovU3VidHlwZSAvSW1hZ2UKL1dpZHRoIDU0Ci9IZWlnaHQgNTQKL0NvbG9yU3BhY2UgL0RldmljZUdyYXkKL0JpdHNQZXJDb21wb25lbnQgOAovTGVuZ3RoIDc3Ci9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiMEpkMFRkcSRqNG9GXlUsIkhUczlFSUU7MEFULF9FKkxaJW9AN0psNVY7SCdDcz1UcnFEYUguNEJmI2M0T1ZUOyhkI2Y8R0U5fj4KZW5kc3RyZWFtCmVuZG9iagoyMiAwIG9iago8PCAvVHlwZSAvWE9iamVjdAovU3VidHlwZSAvSW1hZ2UKL1dpZHRoIDI5NAovSGVpZ2h0IDcwCi9Db2xvclNwYWNlIC9EZXZpY2VHcmF5Ci9CaXRzUGVyQ29tcG9uZW50IDgKL0xlbmd0aCAxNDE5Ci9GaWx0ZXIgWy9BU0NJSTg1RGVjb2RlIC9GbGF0ZURlY29kZV0KPj5zdHJlYW0KR2IiL2NsWWA3WSY7MHJcMEM6NXRIcyhLaVdfczRTTC5ER2prQC9wZihpbGducDNRO0g+ZUwnTShbQzhOKzI6aXFoNiRxPUVVRChIPklGM3IKPl1GRE5nMG5gPEpTdTkibFdOaGtNRE1QdVU9dUlPR1BSUihVUDxkQGZodSFHcy1YS0xmN2hfQm83a14/XWhTLyZiRldRQ2onZVFSPSonMSgKJ0dTMGZdIVNrclVGO2xpSFZvK2cvPSteXkhDQF8zcSgkP2YqK0A1Y2I8TUdtQixESSFjQlhHSmxyXDlDKyVlbm5TYjorV0xLT09GM2IqQF8KL1ojP289YWpzTzdSPjpdOy8rdSk/JDdNZyRrQSZRZV4uLV5BMDJEWWFJSCkzWFIlTFxEIkpoNDstaENpLjRxQzouN2p0QU11ZHNyTGpMaEoKXlxkYmBONi9AXURcNjksJlk1YD01SiJvRUNnIyxsVyszSzI0JGxOa1onOlImJF48MzFXYmIuVl9IJV9YYGJBKF82ZzMmLjIkZi9hJC04bzUKZExnWGNhMVJLWCRgTnEiZ20xdDBEcyNKRz4iXGdOT3Q/RUUvZHVDU1UzJ3BWLXRsIyEuRS0sQ1s8XjEuJzM9bFVDNzxlLFUwS09aKGM/QVoKL18wWGhAb3U+cmtsalpkLlthI1RFaSNtP2BGNFk4JFZOJXMlKjlKOUFIT2xmOU1JTyNfI0tjVSssJ0h0S1Y/XDIuNHFDOi47PCVraWkvPWkKal4+WCYjdUQsZilPYHBrOHQjQE8xdFkoOmAnPzFqV2U+a2xMMls/aCUpYk9VTlJuU14uNHFBJC5IdDI7a0Y6IjBiKE9hZDMjKCZIR2MsNiYKJ0xVVDRVPXJrLCxHU2Vsa1hFSEIoOU5fdCc9ZGBNbVFSbltQYTlhXVBZKnFebzwsXmw4Q21EZkBUXFU9V2hxLUtNRiQpTD9TLSpYMzFCJz4KO0wrQHEuSiJjWWJOS0xbPVw7P09CaEREWjE8MU1HQnI7NEQqM3FnQVRiLzhBS2pWX2MsXWIqaT0nIjZRJCs0Jk5lI0xjK0kkQj0rbTtGRioKVilLZ00hUjdONCNpJkhpX1RwIj1tPUNHajpyUW1IZHQrPj5QVUBaIT5BWXVPbFs+UyY5OmFYPmcvOypIJW9bTShiKi1fRFMldSV0S2FhJyMKRT1MI1Y8QUVhbFY9PV4+MWdtQ2RURmJOaTtzMHJVKkRKQGsyUy1cJT4iWys8bDdgJl5xM2pLSVVhLl1cTGcoMiFpN08qJSV1PT5fMT8ic18KNUw6ZzdgJl9YTC1uSUY3PF4raz9RZFNjWFM1Tk9rVHNzLUlnLypkTS9vLWFzNlBAOCFoWC87ZzNdRmpLPWprTCdZdCxBJDFhK0ltKSs4JDAKVGUzKztvSSkiZkwxL1N1aC45JzRWWnRDQzZcRlZpY141dU5vWTdeRGNWJXQkXWdLb2xyJENZZCsrTjk8O3RDJF4sWWFPTD4wL25WUFIodWYKOHJIJ0pQaTZ0NypYc3M7U0NTcGJOZCohKVYpS2YuImcoUEdBOUJELmRJIikrV3RbKFdvYjg4PThrIW9pZ11qdUw5NWkyNyYlZEtPcFFmWXEKOTUsaWc1cSwmdSk9Iiw/I0o+LCRBSSxbalJBZFBDNSw+aGYjPUtwVyIoUi1XI2dXKigucEdDbmRbbFo1UGE5YlhQYy4ya1YuWXVhKVg1WVgKQzdvKF1ZYmtCZlskUFNGRy9mUD9FKyNfVls7KVJIb0dcJWErcTtlLC40cUJPLj1uV2pOTDJKcytLKU0jUzYwaUArcmRfVkxrIyY0S04nV10KPTA8KUFUR2RTWy0rRmkxX0k9ImY4UiJlW2wkbFhjbGQrMDlEQDRJIn4+CmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDIzCjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDAwOSAwMDAwMCBuIAowMDAwMDAwMDU4IDAwMDAwIG4gCjAwMDAwMDAxMDQgMDAwMDAgbiAKMDAwMDAwMDE2MiAwMDAwMCBuIAowMDAwMDAwMjE0IDAwMDAwIG4gCjAwMDAwMDAzMTIgMDAwMDAgbiAKMDAwMDAwMDQxNSAwMDAwMCBuIAowMDAwMDAwNTIxIDAwMDAwIG4gCjAwMDAwMDA2MzEgMDAwMDAgbiAKMDAwMDAwMDcyNyAwMDAwMCBuIAowMDAwMDAwODI5IDAwMDAwIG4gCjAwMDAwMDA5MzQgMDAwMDAgbiAKMDAwMDAwMTA0MyAwMDAwMCBuIAowMDAwMDAxMTQ0IDAwMDAwIG4gCjAwMDAwMDEyNDQgMDAwMDAgbiAKMDAwMDAwMTM0NiAwMDAwMCBuIAowMDAwMDAxNDUyIDAwMDAwIG4gCjAwMDAwMDE2MjIgMDAwMDAgbiAKMDAwMDAwMjAwMSAwMDAwMCBuIAowMDAwMDA0NzQ2IDAwMDAwIG4gCjAwMDAwMDUzOTMgMDAwMDAgbiAKMDAwMDAwNTY1NCAwMDAwMCBuIAp0cmFpbGVyCjw8Ci9JbmZvIDE3IDAgUgovU2l6ZSAyMwovUm9vdCAxIDAgUgo+PgpzdGFydHhyZWYKNzI2MAolJUVPRgo=\",\"docType\":\"PDF\"}],\"currency\":\"SEK\",\"customerReferences\":[],\"codcollectionAmount\":0.0,\"baseRateAmount\":650.0}],\"shipmentAdvisoryDetails\":{},\"completedShipmentDetail\":{\"usDomestic\":false,\"carrierCode\":\"FDXE\",\"masterTrackingId\":{\"trackingIdType\":\"FEDEX\",\"formId\":\"0881\",\"trackingNumber\":\"794903800925\"},\"serviceDescription\":{\"serviceId\":\"EP1000000376\",\"serviceType\":\"FEDEX_PRIORITY_EXPRESS\",\"code\":\"D2\",\"names\":[{\"type\":\"long\",\"encoding\":\"utf-8\",\"value\":\"FedEx®PriorityExpress\"},{\"type\":\"long\",\"encoding\":\"ascii\",\"value\":\"FedExPriorityExpress\"},{\"type\":\"medium\",\"encoding\":\"utf-8\",\"value\":\"FedEx®PriorityExpress\"},{\"type\":\"medium\",\"encoding\":\"ascii\",\"value\":\"FedExPriorityExpress\"},{\"type\":\"short\",\"encoding\":\"utf-8\",\"value\":\"NPE\"},{\"type\":\"short\",\"encoding\":\"ascii\",\"value\":\"NPE\"},{\"type\":\"abbrv\",\"encoding\":\"ascii\",\"value\":\"RN\"}],\"operatingOrgCodes\":[\"FXE\"],\"serviceCategory\":\"parcel\",\"description\":\"PriorityExpress\",\"astraDescription\":\"PREX\"},\"packagingDescription\":\"CustomerPackaging\",\"operationalDetail\":{\"ursaPrefixCode\":\"9H\",\"ursaSuffixCode\":\"BMAA\",\"originLocationId\":\"ARND\",\"originLocationNumber\":0,\"originServiceArea\":\"PM\",\"destinationLocationId\":\"BMAA\",\"destinationLocationNumber\":0,\"destinationServiceArea\":\"A1\",\"destinationLocationStateOrProvinceCode\":\"\",\"deliveryDate\":\"\",\"deliveryDay\":\"\",\"commitDate\":\"\",\"commitDay\":\"\",\"ineligibleForMoneyBackGuarantee\":false,\"astraPlannedServiceLevel\":\"A1\",\"astraDescription\":\"PRIORITYEXPRESS\",\"postalCode\":\"10012\",\"stateOrProvinceCode\":\"\",\"countryCode\":\"SE\",\"airportId\":\"ARN\",\"serviceCode\":\"D2\",\"packagingCode\":\"01\",\"publishedDeliveryTime\":\"\",\"scac\":\"\"},\"shipmentRating\":{\"actualRateType\":\"PAYOR_ACCOUNT_SHIPMENT\",\"shipmentRateDetails\":[{\"rateType\":\"PAYOR_ACCOUNT_SHIPMENT\",\"rateScale\":\"SE1F1_D2_YOUR_PACKAGING\",\"rateZone\":\"1\",\"pricingCode\":\"\",\"ratedWeightMethod\":\"ACTUAL\",\"currencyExchangeRate\":{\"fromCurrency\":\"SEK\",\"intoCurrency\":\"SEK\",\"rate\":1.0},\"dimDivisor\":139,\"fuelSurchargePercent\":10.5,\"totalBillingWeight\":{\"units\":\"KG\",\"value\":21.0},\"totalBaseCharge\":650.0,\"totalFreightDiscounts\":0.0,\"totalNetFreight\":650.0,\"totalSurcharges\":1472.43,\"totalNetFedExCharge\":2122.43,\"totalTaxes\":530.61,\"totalNetCharge\":2653.04,\"totalRebates\":0.0,\"totalDutiesAndTaxes\":0.0,\"totalAncillaryFeesAndTaxes\":0.0,\"totalDutiesTaxesAndFees\":0.0,\"totalNetChargeWithDutiesAndTaxes\":0.0,\"surcharges\":[{\"surchargeType\":\"OUT_OF_PICKUP_AREA\",\"level\":\"SHIPMENT\",\"description\":\"OutofPickupAreaTierB\",\"amount\":1035.0},{\"surchargeType\":\"DEMAND\",\"level\":\"SHIPMENT\",\"description\":\"DemandSurcharge\",\"amount\":100.0},{\"surchargeType\":\"FEDEX_INTRACOUNTRY_FEES\",\"level\":\"SHIPMENT\",\"description\":\"Waybill\",\"amount\":50.0},{\"surchargeType\":\"FUEL\",\"level\":\"SHIPMENT\",\"description\":\"Fuel\",\"amount\":187.43},{\"surchargeType\":\"OTHER\",\"level\":\"SHIPMENT\",\"description\":\"Multi-PieceShipment\",\"amount\":100.0}],\"freightDiscounts\":[],\"taxes\":[{\"type\":\"VAT\",\"description\":\"Swedenvalue-added\",\"amount\":530.61}],\"currency\":\"SEK\"}]},\"completedPackageDetails\":[{\"sequenceNumber\":1,\"trackingIds\":[{\"trackingIdType\":\"FEDEX\",\"formId\":\"0881\",\"trackingNumber\":\"794903800925\"}],\"groupNumber\":0,\"signatureOption\":\"SERVICE_DEFAULT\",\"operationalDetail\":{\"barcodes\":{\"binaryBarcodes\":[{\"type\":\"COMMON_2D\",\"value\":\"Wyk+HjAxHTAyMTAwMTIdNzUyHUQyHTc5NDkwMzgwMDkyNTA4ODEdRkRFHTYwNjg5NDg5OR0zMzkdHTEvMh04Ljk5S0cdTh1SRUNJUElFTlQgQUREUkVTUyAxHVNUT0NLSE9MTR0gIB1Kb2huIFRheWxvch4wNh0xMFpYSTAwMh0xMVpGZWRleB0xMlo0NjIwMzQ1Njc4OR0xNFpSRUNJUElFTlQgQUREUkVTUyAyHTE1WjEwMDQ5MzgyNB0yMFocHTMxWjE0OTU0MTA4MzA4OTExNTgyMDQ4MDA3OTQ5MDM4MDA5MjUdMzJaMDIdMzlaQVJORB0eMDkdRkRYHXodOB04LgI0Ohp/QB4E\"}],\"stringBarcodes\":[{\"type\":\"FEDEX_1D\",\"value\":\"1495410830891158204800794903800925\"}]},\"astraHandlingText\":\"\",\"operationalInstructions\":[{\"number\":2,\"content\":\"TRK#\"},{\"number\":3,\"content\":\"0881\"},{\"number\":4,\"content\":\"##MASTER##\"},{\"number\":5,\"content\":\"9HBMAA\"},{\"number\":7,\"content\":\"1495410830891158204800794903800925\"},{\"number\":8,\"content\":\"583J3/8E24/9AE3\"},{\"number\":9,\"content\":\"1of2\"},{\"number\":10,\"content\":\"794903800925\"},{\"number\":12,\"content\":\"A1\"},{\"number\":13,\"content\":\"PRIORITYEXPRESS\"},{\"number\":15,\"content\":\"10012\"},{\"number\":16,\"content\":\"-SE\"},{\"number\":17,\"content\":\"ARN\"}]}},{\"sequenceNumber\":2,\"trackingIds\":[{\"trackingIdType\":\"FEDEX\",\"formId\":\"0891\",\"trackingNumber\":\"794903800936\"}],\"groupNumber\":0,\"signatureOption\":\"SERVICE_DEFAULT\",\"operationalDetail\":{\"barcodes\":{\"binaryBarcodes\":[{\"type\":\"COMMON_2D\",\"value\":\"Wyk+HjAxHTAyMTAwMTIdNzUyHUQyHTc5NDkwMzgwMDkzNjA4OTEdRkRFHTYwNjg5NDg5OR0zMzkdHTIvMh0xMi4wMEtHHU4dUkVDSVBJRU5UIEFERFJFU1MgMR1TVE9DS0hPTE0dICAdSm9obiBUYXlsb3IeMDYdMTBaWEkwMDIdMTFaRmVkZXgdMTJaNDYyMDM0NTY3ODkdMTRaUkVDSVBJRU5UIEFERFJFU1MgMh0xNVoxMDA0OTM4MjQdMjBaHB0yOFo3OTQ5MDM4MDA5MjUwODgxHTMxWjE0OTU2ODgwMzA4OTExNTgyMDQ4MDA3OTQ5MDM4MDA5MzYdMzJaMDIdMzlaQVJORB0eMDkdRkRYHXodOB04LgI0Ohp/QB4E\"}],\"stringBarcodes\":[{\"type\":\"FEDEX_1D\",\"value\":\"1495688030891158204800794903800936\"}]},\"astraHandlingText\":\"\",\"operationalInstructions\":[{\"number\":2,\"content\":\"MPS#\"},{\"number\":3,\"content\":\"0891\"},{\"number\":4,\"content\":\"Mstr#794903800925\"},{\"number\":5,\"content\":\"9HBMAA\"},{\"number\":7,\"content\":\"1495688030891158204800794903800936\"},{\"number\":8,\"content\":\"583J3/8E24/9AE3\"},{\"number\":9,\"content\":\"2of2\"},{\"number\":10,\"content\":\"794903800936\"},{\"number\":11,\"content\":\"0881\"},{\"number\":12,\"content\":\"A1\"},{\"number\":13,\"content\":\"PRIORITYEXPRESS\"},{\"number\":15,\"content\":\"10012\"},{\"number\":16,\"content\":\"-SE\"},{\"number\":17,\"content\":\"ARN\"}]}}],\"documentRequirements\":{\"generationDetails\":[{\"type\":\"AIR_WAYBILL\",\"minimumCopiesRequired\":2}],\"prohibitedDocuments\":[\"USMCA_COMMERCIAL_INVOICE_CERTIFICATION_OF_ORIGIN\",\"USMCA_CERTIFICATION_OF_ORIGIN\"]}},\"serviceCategory\":\"EXPRESS\"}]}}';
                //'{"transactionId":"APIF_SV_SHPC_TxID979c74e0-3a03-4706-9fd6-862cbd4b6a23","output":{"transactionShipments":[{"alerts":[{"code":"VIRTUAL.RESPONSE","message":"This is a Virtual Response.","alertType":"NOTE"}],"masterTrackingNumber":"794900456722","serviceType":"PRIORITY_OVERNIGHT","shipDatestamp":"2023-09-07","serviceName":"FedEx Priority Overnight®","pieceResponses":[{"masterTrackingNumber":"794900456722","deliveryDatestamp":"2023-09-08","trackingNumber":"794900456722","additionalChargesDiscount":0.0,"netRateAmount":325.95,"netChargeAmount":0.0,"netDiscountAmount":0.0,"packageDocuments":[{"contentType":"LABEL","copiesToPrint":1,"encodedLabel":"Pgo+PgovTWVkaWFCb","docType":"PDF"}],"currency":"CAD","customerReferences":[],"codcollectionAmount":0.0,"baseRateAmount":228.5}],"shipmentAdvisoryDetails":{},"completedShipmentDetail":{"usDomestic":false,"carrierCode":"FDXE","masterTrackingId":{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"},"serviceDescription":{"serviceId":"EP1000000002","serviceType":"PRIORITY_OVERNIGHT","code":"01","names":[{"type":"long","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"long","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"medium","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"medium","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"short","encoding":"utf-8","value":"P-1"},{"type":"short","encoding":"ascii","value":"P-1"},{"type":"abbrv","encoding":"ascii","value":"PO"}],"operatingOrgCodes":["FXE"],"serviceCategory":"parcel","description":"Priority Overnight","astraDescription":"PO"},"packagingDescription":"Customer Packaging","operationalDetail":{"ursaPrefixCode":"6B","ursaSuffixCode":"YBZA ","originLocationId":"YVRA ","originLocationNumber":0,"originServiceArea":"AM","destinationLocationId":"YBZA ","destinationLocationNumber":0,"destinationServiceArea":"A2","destinationLocationStateOrProvinceCode":"ON","deliveryDate":"2023-09-08","deliveryDay":"FRI","commitDate":"2023-09-08","commitDay":"FRI","ineligibleForMoneyBackGuarantee":false,"astraPlannedServiceLevel":"FRI - 08 SEP A2","astraDescription":"PRIORITY OVERNIGHT","postalCode":"M5C2C5","stateOrProvinceCode":"ON","countryCode":"CA","airportId":"YYZ","serviceCode":"01","packagingCode":"01","publishedDeliveryTime":"A2","scac":""},"shipmentRating":{"actualRateType":"PAYOR_ACCOUNT_SHIPMENT","shipmentRateDetails":[{"rateType":"PAYOR_ACCOUNT_SHIPMENT","rateScale":"CA0001F12_01_YOUR_PACKAGING","rateZone":"12","pricingCode":"","ratedWeightMethod":"DIM","currencyExchangeRate":{"fromCurrency":"CAD","intoCurrency":"CAD","rate":1.0},"dimDivisor":139,"fuelSurchargePercent":14.75,"totalBillingWeight":{"units":"LB","value":29.0},"totalBaseCharge":228.5,"totalFreightDiscounts":0.0,"totalNetFreight":228.5,"totalSurcharges":59.95,"totalNetFedExCharge":288.45,"totalTaxes":37.5,"totalNetCharge":325.95,"totalRebates":0.0,"totalDutiesAndTaxes":0.0,"totalAncillaryFeesAndTaxes":0.0,"totalDutiesTaxesAndFees":0.0,"totalNetChargeWithDutiesAndTaxes":0.0,"surcharges":[{"surchargeType":"INSURED_VALUE","description":"Insured value","amount":11.25},{"surchargeType":"PRIORITY_ALERT","description":"Priority Alert","amount":15.0},{"surchargeType":"FUEL","description":"Fuel","amount":33.7}],"freightDiscounts":[],"taxes":[{"type":"HST","description":"Canada Ontario harmonized sales","amount":37.5}],"currency":"CAD"}]},"completedPackageDetails":[{"sequenceNumber":1,"trackingIds":[{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"}],"groupNumber":0,"signatureOption":"SERVICE_DEFAULT","operationalDetail":{"barcodes":{"binaryBarcodes":[{"type":"COMMON_2D","value":"Wyk+HjAxHTAyTTVDMkM1HTEyNB0wMR03OTQ5MDA0NTY3MjIwNzMwHUZERR02MDgyNzE0NTcdMjUwHR0xLzEdMjAuMDBMQh1OHVRDMDAzIEpVTDIzIFRpcmUgTG9zcyAmIFByZXZlbh1UT1JPTlRPHU9OHVNISVAgVE8gQ09OVEFDVCBOQU1FHjA2HTEwWlhJMDAyHTExWlNISVAgVE8gUkVDSVBJRU5UIENNUE5ZHTEyWjkwMTI2MzU1NTUdMTRaUE8gLUN1UGFjayAtIEludHJhIENBIC0gUEEgLx0xNVoxMDA3NTAxNTMdMjBaHDMyNh0zMVoxMTQ1MzI3ODgxMDYwNDA0NjcyMTAwNzk0OTAwNDU2NzIyHTMyWjAyMTU5Mx0zOVpZVlJBHR4wOR1GRFgdeh04HTAlCzo7H39AHgQ="}],"stringBarcodes":[{"type":"FEDEX_1D","value":"1145327881060404672100794900456722"}]},"astraHandlingText":"ELB *PA","operationalInstructions":[{"number":2,"content":"TRK#"},{"number":3,"content":"0730"},{"number":5,"content":"6B YBZA "},{"number":7,"content":"1145327881060404672100794900456722"},{"number":8,"content":"583J4/05BA/9AE3"},{"number":10,"content":"7949 0045 6722"},{"number":12,"content":"FRI - 08 SEP A2"},{"number":13, "content":"PRIORITY OVERNIGHT"},{"number":14,"content":"ELB *PA"},{"number":15,"content":"M5C 2C5"},{"number":16,"content":"ON-CA"},{"number":17,"content":"YYZ"}]}],"documentRequirements":{}},"serviceCategory":"EXPRESS"}]}}';
            // {"transactionId":"APIF_SV_SHPC_TxID979c74e0-3a03-4706-9fd6-862cbd4b6a23","output":{"transactionShipments":[{"alerts":[{"code":"VIRTUAL.RESPONSE","message":"This is a Virtual Response.","alertType":"NOTE"}],"masterTrackingNumber":"794900456722","serviceType":"PRIORITY_OVERNIGHT","shipDatestamp":"2023-09-07","serviceName":"FedEx Priority Overnight®","pieceResponses":[{"masterTrackingNumber":"794900456722","deliveryDatestamp":"2023-09-08","trackingNumber":"794900456722","additionalChargesDiscount":0.0,"netRateAmount":325.95,"netChargeAmount":0.0,"netDiscountAmount":0.0,"packageDocuments":[{"contentType":"LABEL","copiesToPrint":1,"encodedLabel":"Pgo+PgovTWVkaWFCb","docType":"PDF"}],"currency":"CAD","customerReferences":[],"codcollectionAmount":0.0,"baseRateAmount":228.5}],"shipmentAdvisoryDetails":{},"completedShipmentDetail":{"usDomestic":false,"carrierCode":"FDXE","masterTrackingId":{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"},"serviceDescription":{"serviceId":"EP1000000002","serviceType":"PRIORITY_OVERNIGHT","code":"01","names":[{"type":"long","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"long","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"medium","encoding":"utf-8","value":"FedEx Priority Overnight®"},{"type":"medium","encoding":"ascii","value":"FedEx Priority Overnight"},{"type":"short","encoding":"utf-8","value":"P-1"},{"type":"short","encoding":"ascii","value":"P-1"},{"type":"abbrv","encoding":"ascii","value":"PO"}],"operatingOrgCodes":["FXE"],"serviceCategory":"parcel","description":"Priority Overnight","astraDescription":"PO"},"packagingDescription":"Customer Packaging","operationalDetail":{"ursaPrefixCode":"6B","ursaSuffixCode":"YBZA ","originLocationId":"YVRA ","originLocationNumber":0,"originServiceArea":"AM","destinationLocationId":"YBZA ","destinationLocationNumber":0,"destinationServiceArea":"A2","destinationLocationStateOrProvinceCode":"ON","deliveryDate":"2023-09-08","deliveryDay":"FRI","commitDate":"2023-09-08","commitDay":"FRI","ineligibleForMoneyBackGuarantee":false,"astraPlannedServiceLevel":"FRI - 08 SEP A2","astraDescription":"PRIORITY OVERNIGHT","postalCode":"M5C2C5","stateOrProvinceCode":"ON","countryCode":"CA","airportId":"YYZ","serviceCode":"01","packagingCode":"01","publishedDeliveryTime":"A2","scac":""},"shipmentRating":{"actualRateType":"PAYOR_ACCOUNT_SHIPMENT","shipmentRateDetails":[{"rateType":"PAYOR_ACCOUNT_SHIPMENT","rateScale":"CA0001F12_01_YOUR_PACKAGING","rateZone":"12","pricingCode":"","ratedWeightMethod":"DIM","currencyExchangeRate":{"fromCurrency":"CAD","intoCurrency":"CAD","rate":1.0},"dimDivisor":139,"fuelSurchargePercent":14.75,"totalBillingWeight":{"units":"LB","value":29.0},"totalBaseCharge":228.5,"totalFreightDiscounts":0.0,"totalNetFreight":228.5,"totalSurcharges":59.95,"totalNetFedExCharge":288.45,"totalTaxes":37.5,"totalNetCharge":325.95,"totalRebates":0.0,"totalDutiesAndTaxes":0.0,"totalAncillaryFeesAndTaxes":0.0,"totalDutiesTaxesAndFees":0.0,"totalNetChargeWithDutiesAndTaxes":0.0,"surcharges":[{"surchargeType":"INSURED_VALUE","description":"Insured value","amount":11.25},{"surchargeType":"PRIORITY_ALERT","description":"Priority Alert","amount":15.0},{"surchargeType":"FUEL","description":"Fuel","amount":33.7}],"freightDiscounts":[],"taxes":[{"type":"HST","description":"Canada Ontario harmonized sales","amount":37.5}],"currency":"CAD"}]},"completedPackageDetails":[{"sequenceNumber":1,"trackingIds":[{"trackingIdType":"FEDEX","formId":"0730","trackingNumber":"794900456722"}],"groupNumber":0,"signatureOption":"SERVICE_DEFAULT","operationalDetail":{"barcodes":{"binaryBarcodes":[{"type":"COMMON_2D","value":"Wyk+HjAxHTAyTTVDMkM1HTEyNB0wMR03OTQ5MDA0NTY3MjIwNzMwHUZERR02MDgyNzE0NTcdMjUwHR0xLzEdMjAuMDBMQh1OHVRDMDAzIEpVTDIzIFRpcmUgTG9zcyAmIFByZXZlbh1UT1JPTlRPHU9OHVNISVAgVE8gQ09OVEFDVCBOQU1FHjA2HTEwWlhJMDAyHTExWlNISVAgVE8gUkVDSVBJRU5UIENNUE5ZHTEyWjkwMTI2MzU1NTUdMTRaUE8gLUN1UGFjayAtIEludHJhIENBIC0gUEEgLx0xNVoxMDA3NTAxNTMdMjBaHDMyNh0zMVoxMTQ1MzI3ODgxMDYwNDA0NjcyMTAwNzk0OTAwNDU2NzIyHTMyWjAyMTU5Mx0zOVpZVlJBHR4wOR1GRFgdeh04HTAlCzo7H39AHgQ="}],"stringBarcodes":[{"type":"FEDEX_1D","value":"1145327881060404672100794900456722"}]},"astraHandlingText":"ELB *PA","operationalInstructions":[{"number":2,"content":"TRK#"},{"number":3,"content":"0730"},{"number":5,"content":"6B YBZA "},{"number":7,"content":"1145327881060404672100794900456722"},{"number":8,"content":"583J4/05BA/9AE3"},{"number":10,"content":"7949 0045 6722"},{"number":12,"content":"FRI - 08 SEP A2"},{"number":13,"content":"PRIORITY OVERNIGHT"},{"number":14,"content":"ELB *PA"},{"number":15,"content":"M5C 2C5"},{"number":16,"content":"ON-CA"},{"number":17,"content":"YYZ"}]}],"documentRequirements":{}},"serviceCategory":"EXPRESS"}]}}';
            StatusCode = 200;
        }else { response = http.send(request);res.response = httpResult = response.getBody();StatusCode = response.getStatusCode();
        }

        // Process the response as needed
        if (StatusCode == 200) {
            Id RTID; RTID = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('Fedex_Shipping').getRecordTypeId();
            //Shipment__c ship = new Shipment__c();
            ship.Active__c = true;

            ship.RecordTypeId = RTID;
            ship.Name = 'Shipment';
            if(fAddress.Id != null && Ship.Shipment_Billing_options__c != null && String.isNotEmpty(Ship.Shipment_Billing_options__c) && Ship.Shipment_Billing_options__c == 'SENDER'){
                Ship.Billing_Address__c = fAddress.Id;
            }else if(tAddress.Id != null) Ship.Billing_Address__c = tAddress.Id;
            if(Schema.sObjectType.Shipment__c.fields.Customer__c.isCreateable() && ship.Customer__c == Null) Ship.Customer__c = tAddress.Customer__c;
            Ship.Customer_Contact__c = shipToContact.Id;
            if(Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable()) { Ship.Status__c = 'Shipped'; }
            if(Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isUpdateable()) { Ship.Shipping_Address__c = tAddress.Id; }
            if(packList.size() > 0){
                //ship.Package__c = packList[0].Id;
                //if(packList[0].Logistic__c != null && Schema.sObjectType.Shipment__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isUpdateable()) Ship.Logistic__c = packList[0].Logistic__c ;
                //if(packList[0].Logistic__c != null && packList[0].Logistic__r.Billing_options__c != null) Ship.Shipment_Billing_options__c = packList[0].Logistic__r.Billing_options__c;
                if(packList[0].Order__c != null) Ship.Order__c = packList[0].Order__c;
                if(packList[0].Return_Merchandise_Authorisation__c != null) Ship.Return_Merchandise_Authorisation__c = packList[0].Return_Merchandise_Authorisation__c;

            }
            if(rmaid != '')Ship.Return_Merchandise_Authorisation__c = rmaid;
            System.debug('packList[0].Return_Merchandise_Authorisation__c=>'+Ship);
            if(Schema.sObjectType.Shipment__c.fields.Fedex_Service__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Fedex_Service__c.isUpdateable()) { Ship.Fedex_Service__c = rateService; }




            // Successful response
            res.response = httpResult;
            // Parse JSON response
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            Map<String, Object> outputMap = (Map<String, Object>) responseMap.get('output');
            List<Object> transactionShipments = (List<Object>) outputMap.get('transactionShipments');
            List<attachment> attList = new List<attachment>();
            String masterTrackingNumber = '';
            // Iterate through transaction shipments
            for (Object shipmentObj : transactionShipments) {
                Map<String, Object> shipment1 = (Map<String, Object>) shipmentObj;

                // Extract masterTrackingNumber
                masterTrackingNumber = (String) shipment1.get('masterTrackingNumber');
                System.debug('Master Tracking Number: ' + masterTrackingNumber);

                // Extract packageDocuments

                Decimal totalNetChargeval = 0;
                // Extract currency
                List<Object> pieceResponses = (List<Object>) shipment1.get('pieceResponses');
                for (Object pieceResponse : pieceResponses) {
                    Map<String, Object> response2 = (Map<String, Object>) pieceResponse;
                    String currencyval = (String) response2.get('currency');
                    System.debug('Currency: ' + currencyval);

                }

                // Extract carrierCode
                Map<String, Object> completedShipmentDetail = (Map<String, Object>) shipment1.get('completedShipmentDetail');
                String carrierCode = (String) completedShipmentDetail.get('carrierCode');
                System.debug('Carrier Code: ' + carrierCode);
                // Extract totalNetCharge

                Map<String, Object> response3 = new Map<String, Object>();
                if(completedShipmentDetail.containskey('shipmentRating'))  response3= (Map<String, Object>) completedShipmentDetail.get('shipmentRating');
                if(response3.size() > 0){
                    List<Object> shipmentRates = (List<Object>) response3.get('shipmentRateDetails');
                    system.debug('response3 : '+response3);
                    system.debug('shipmentRates : '+shipmentRates);
                    if(shipmentRates.size() > 0){
                        for (Object pieceResponse : shipmentRates) {
                            Map<String, Object> response2 = (Map<String, Object>) pieceResponse;
                            totalNetChargeval = (Decimal) response2.get('totalNetCharge');
                            System.debug('Total Net Charge: ' + totalNetChargeval);

                        }

                    }
                }
                ship.Shipping_Amount__c = totalNetChargeval;
                // Extract masterTrackingId
                Map<String, Object> masterTrackingId = (Map<String, Object>) completedShipmentDetail.get('masterTrackingId');
                String trackingIdType = (String) masterTrackingId.get('trackingIdType');
                if(Schema.sObjectType.Shipment__c.fields.Tracking_Unique_Id__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Tracking_Unique_Id__c.isUpdateable()) { if(TrackingIdType != null && TrackingIdType != '') Ship.Tracking_Unique_Id__c = TrackingIdType; }
                if(Schema.sObjectType.Shipment__C.fields.Number_Of_Pieces_In_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Number_Of_Pieces_In_Shipment__c.isUpdateable()) Ship.Number_Of_Pieces_In_Shipment__c = String.valueof(packList.size());

                ship.Carrier_Code__c = carrierCode;



                String formId = (String) masterTrackingId.get('formId');
                String trackingNumber = (String) masterTrackingId.get('trackingNumber');
                ship.TrackingNumber__c = trackingNumber;


                List<Object> packageResponses = (List<Object>) shipment1.get('pieceResponses');
                for (Object packageResponse : packageResponses) {
                    Map<String, Object> packageMap = (Map<String, Object>) packageResponse;
                    List<Object> packageDocuments = (List<Object>) packageMap.get('packageDocuments');
                    for (Object packageDocument : packageDocuments) {
                        Map<String, Object> doc = (Map<String, Object>) packageDocument;
                        attachment att = new attachment();
                        String contentType = (String) doc.get('contentType');
                        Integer copiesToPrint = (Integer) doc.get('copiesToPrint');
                        String labelData = (String) doc.get('encodedLabel');
                        system.debug('labelData : '+labelData);

                        if(labelData != null){

                            att = new attachment(Name = 'Fedex_Label.pdf', ParentId = 'a0L0600000SwaYZEAZ', ContentType = 'application/pdf',body = EncodingUtil.base64Decode(labelData) );
                            attList.add(att);
                        }

                        System.debug('Package Document: ContentType=' + contentType + ', CopiesToPrint=' + copiesToPrint);
                    }
                }
                System.debug('Tracking ID Type: ' + trackingIdType + ', Form ID: ' + formId + ', Tracking Number: ' + trackingNumber);
            }
            if(isReturnShipment && masterShipmentId != null && masterShipmentId != ''){ Ship.Id = null;Ship.Master_Shipment__c = masterShipmentId;Ship.Return_Shipment__c = true;
            }
            decimal totalPackQty = 0;
            for(Package__c pK : packList) totalPackQty += pK.Package_Quantity__c;
            if(Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isUpdateable())  Ship.Total_Package_items__c = totalPackQty;
            //PreventRecursiveLedgerEntry.shippedItemsCheck = false;
            if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) {upsert ship;}
            res.ShipDetails = ship;
            if (attList.size() > 0) {
              for (Attachment att : attList) {
                  if (ship.Id != null) att.ParentId = ship.Id;
                  System.debug('Id change : ' + ship.Id);
                  System.debug('att : ' + att);
              }

                 //for FLS  upsert accessibleVersionsA2;
                 List<SObject> safeListaccv2 = FLSHelper.getSafeRecords(
                        attList,
                        'Attachment',
                        AccessType.UPDATABLE
                    );
                    List<Attachment> typedaccv2List = new List<Attachment>();
                    for (SObject s : safeListaccv2) {
                      Attachment accv2Record = (Attachment)s;
                      if (!accv2Record.getPopulatedFieldsAsMap().containsKey('ParentId') && ship.Id != null) {
                          accv2Record.ParentId = ship.Id;
                      }
                        typedaccv2List.add(accv2Record);
                    }
                    if (!typedaccv2List.isEmpty()) {
                        System.debug('Before upsert typedaccv2List: ' + typedaccv2List);
                        upsert typedaccv2List; // or insert/update as needed
                    }


                  System.debug('After accessibleVersionsA2: ' + typedaccv2List);

          }

            res.attList=attList;
            if(isReturnShipment == false){
                for(Integer i=0; i<packList.size(); i++) { packList[i].Shipment__c = Ship.Id; packList[i].Status__c = Ship.Status__c;packList[i].Tracking_Number__c = ship.TrackingNumber__c ;
                }
                //if(packList.size() > 0) if(Schema.sObjectType.Package__c.isCreateable() && Schema.sObjectType.Package__c.isUpdateable()) update packList;
                system.debug('--- packList : '+packList);
            }
            System.debug('ship-->'+ship);
            if(packList.size() > 0){
                if(packList[0].Order__c != null){
                    System.debug('entered packList[0].Order__c');
                    Order SalesOrder1 = new Order(); SalesOrder1 = Database.query('select Id, Name, Tracking_Number__c,Return_Tracking_Number__c, UPS_Service__c, Shipment_Type__c from Order where (Id =\'' + String.escapeSingleQuotes(packList[0].Order__r.Id) + '\') Limit 1');
                    if(isReturnShipment == false){
                        if(Schema.sObjectType.Order.fields.UPS_Service__c.isCreateable() && Schema.sObjectType.Order.fields.UPS_Service__c.isUpdateable()) SalesOrder1.UPS_Service__c = rateService;
                        if(Schema.sObjectType.Order.fields.Shipment_Type__c.isCreateable() && Schema.sObjectType.Order.fields.Shipment_Type__c.isUpdateable()) SalesOrder1.Shipment_Type__c = 'FedEx';
                        if(Schema.sObjectType.Order.fields.Tracking_Number__c.isCreateable() && Schema.sObjectType.Order.fields.Tracking_Number__c.isUpdateable()) {
                            if(SalesOrder1.Tracking_Number__c == null) SalesOrder1.Tracking_Number__c = ship.TrackingNumber__c ; else SalesOrder1.Tracking_Number__c += ', ' + ship.TrackingNumber__c ; }
                    }
                    else{
                        if(Schema.sObjectType.Order.fields.Return_Tracking_Number__c.isCreateable() && Schema.sObjectType.Order.fields.Return_Tracking_Number__c.isUpdateable()) {
                            if(SalesOrder1.Return_Tracking_Number__c == null) SalesOrder1.Return_Tracking_Number__c = ship.TrackingNumber__c ; else SalesOrder1.Return_Tracking_Number__c += ', ' + ship.TrackingNumber__c ; }
                    }

                    if(Schema.sObjectType.Order.isCreateable() && Schema.sObjectType.Order.isUpdateable()) { PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false; PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false; PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false; PreventRecursiveLedgerEntry.SOLI_AllocateStock = false; PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false; update SalesOrder1; }
                }

            }

            //return responseBody;
            // Process responseBody
        }
        else {
            // res.response = httpResult;
            // Error handling
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> errors = (List<Object>) responseMap.get('errors');
            if (errors != null && !errors.isEmpty()) {
                List<String> errlst = new List<String>();

                for (Object error : errors) { String errorMessage = 'Error occurred:';Map<String, Object> errorMap = (Map<String, Object>) error;String errorCode = (String) errorMap.get('code');String errorMsg = (String) errorMap.get('message');errorMessage += '\nCode: ' + errorCode + '\nMessage: ' + errorMsg;errlst.add(errorMessage);
                }
                res.errMsgs = errlst;
                //  System.debug(errorMessage); // You can replace System.debug with any other method to display the error message
            } else {
                System.debug('An unknown error occurred.'); // Handle the case when no errors are present
            }

        }
        return res;
    }


    @AuraEnabled
    global static shipmentResponse cancelShipment(String Shipment, List<Package__c> packList,String TimeStamp, String myConsVar){
        shipmentResponse res = new shipmentResponse();
        myConstructorWrapper myConsW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper .class);
        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
        String token = getAccessToken(myConsW.parentKey,myConsW.parentPassword,myConsW.childKey,myConsW.childpassword,myConsW.endPoint);

        String myDT = system.today() + ' ' + 0 + ':' + 0 +  ':' + 0;
        DateTime dt = datetime.valueOf(myDT).adddays(1);
        String shipmentDate = dt.format('yyyy-MM-dd');
        TimeStamp = shipmentDate;

        String[] s;  if(Ship.TrackingNumber__c != null) s = Ship.TrackingNumber__c.split(',');
        if(s != null && s.size() > 0) Ship.TrackingNumber__c = s[0];
        // Create a JSONGenerator object
        JSONGenerator gen = JSON.createGenerator(true);

        // Start the JSON object
        gen.writeStartObject();

        // Write "accountNumber" object
        gen.writeFieldName('accountNumber');
        gen.writeStartObject();
        gen.writeStringField('value', myConsW.accountNumber);
        gen.writeEndObject();

        // Write "trackingNumber"
        gen.writeStringField('trackingNumber', Ship.TrackingNumber__c);

        // Write "senderCountryCode"
        gen.writeStringField('senderCountryCode', myConsW.shipperCountryCode);

        // Write "emailShipment"
        gen.writeBooleanField('emailShipment', false);

        // End the JSON object
        gen.writeEndObject();

        // Get the generated JSON string
        String jsonString = gen.getAsString();

        // Print the generated JSON string
        System.debug(jsonString);
        HttpRequest request = new HttpRequest();
        String parentEndPoint = myConsW.endPoint +'/ship/v1/shipments/cancel';
        request.setEndpoint(parentEndPoint);
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer '+token);
        request.setBody(jsonString);
        String headers = request.getHeader('Content-Type');
        // Convert the HttpRequest object to a string for debugging or logging
        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n'
            +'Authorization : '+request.getHeader('Authorization') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        res.request= requestString;
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        Decimal StatusCode = 0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{"transactionId": "APIF_SV_SHPC_TxIDe80199c3-8b3c-447f-9db4-1592e3c845d9","customertransactionId": "APIF_SV_SHPC_TxIDcustomer test","output": {"alerts": [{"code": "VIRTUAL.RESPONSE","message": "This is a Virtual Response.","alertType": "NOTE"}],"cancelledShipment": true,"cancelledHistory": true}}';
            StatusCode = 200;
        }else { response = http.send(request);res.response = httpResult = response.getBody();StatusCode = response.getStatusCode();
        }
        if (StatusCode == 200) {
            // Parse the JSON response
            Map<String, Object> jsonData = (Map<String, Object>) JSON.deserializeUntyped(httpResult); // Assuming 'responseBody' contains your JSON string

            // Extract the 'output' object
            Map<String, Object> output = (Map<String, Object>) jsonData.get('output');

            // Extract 'cancelledShipment' from 'output'
            Boolean cancelledShipment = false;
            if(output != null && output.containsKey('cancelledShipment')) {
                cancelledShipment = (Boolean) output.get('cancelledShipment');
            }
            String message1 = '';
            if (output != null && output.containsKey('message')) { message1 = (String) output.get('message');res.errMsgs.add(message1);
            }
            // Extract 'alerts' from 'output' if needed
            List<Object> alerts = (output.containskey('alerts')) ? (List<Object>) output.get('alerts') : new List<Object>();


            for (Object alertObj : alerts) {
                Map<String, Object> alert = (Map<String, Object>) alertObj;
                String code = (String) alert.get('code');
                String message = (String) alert.get('message');
                String alertType = (String) alert.get('alertType');
                System.debug('Alert Code: ' + code);
                System.debug('Alert Message: ' + message);
                System.debug('Alert Type: ' + alertType);
                res.errMsgs.add(alertType+ ':' +message);
            }
            if(output.containskey('errors')){

                List<Object> errLst = (List<Object>) output.get('errors');
                for (Object alertObj : errLst) { Map<String, Object> alert = (Map<String, Object>) alertObj;String code = (String) alert.get('code');String message = (String) alert.get('message');res.errMsgs.add(Code+ ':' +message);
                }

            }
            if(cancelledShipment){
                if(Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable()) { Ship.Status__c = 'Cancelled'; }
                if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) update Ship;
                if(packList != null && packList.size() > 0) { for(Package__c pac : packList) { pac.Status__c = 'Cancelled'; }
                 update packList;
               /* System.SObjectAccessDecision securityDecisionA3 = Security.stripInaccessible(AccessType.UPDATABLE, packList);
                List<SObject> accessibleVersionsA3 = securityDecisionA3.getRecords();

                if (!accessibleVersionsA3.isEmpty()) {
                    // Perform the insert operation with the accessible version
                    update accessibleVersionsA3[0];
                } else {
                    // Handle the case where FLS validation fails
                    // You may log an error, throw an exception, or perform other appropriate actions
                } */
               }
                system.debug('-- packList : ' +packList);
                res.successMsg = 'Shipment deleted successfully';
            }
            else{
                res.errMsgs.add('Request to cancel shipment cannot be processed');
            }
        }
        return res;
    }
    @AuraEnabled
    global static shipmentResponse TrackShipment(String Shipment, List<Package__c> packList,String TimeStamp){
        shipmentResponse res = new shipmentResponse();
        //myConstructorWrapper myConsW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper .class);
        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);String myDT = system.today() + ' ' + 0 + ':' + 0 +  ':' + 0;DateTime dt = datetime.valueOf(myDT).adddays(1);String shipmentDate = dt.format('yyyy-MM-dd');TimeStamp = shipmentDate;
        system.debug('Ship.TrackingNumber__c=>'+Ship);
        String[] s;  if(Ship.TrackingNumber__c != null) s = Ship.TrackingNumber__c.split(',');
        if(s != null && s.size() > 0) Ship.TrackingNumber__c = s[0];
        // Create JSONGenerator instance
        JSONGenerator gen = JSON.createGenerator(true);gen.writeStartObject();gen.writeFieldName('trackingInfo');gen.writeStartArray();gen.writeStartObject();gen.writeFieldName('trackingNumberInfo');gen.writeStartObject();gen.writeStringField('trackingNumber', Ship.TrackingNumber__c);gen.writeEndObject();gen.writeEndObject();gen.writeEndArray();gen.writeBooleanField('includeDetailedScans', true);gen.writeEndObject();

        // Get JSON string
        String jsonString = gen.getAsString();String accessToken = getAccessToken(System.Label.ParenKey,system.label.ParentPassword,'','',System.label.trackingTokenEndpoint_New );        // Construct HTTP request
        HttpRequest req = new HttpRequest();string endpoint = System.label.trackingTokenEndpoint_New  + '/track/v1/trackingnumbers';
        req.setEndpoint(endpoint);req.setMethod('POST');req.setHeader('Content-Type', 'application/json');req.setHeader('Authorization', 'Bearer '+accessToken);req.setBody(jsonString);

        String headersString = '';headersString += 'Content-Type: ' + req.getHeader('Content-Type') + '\n';
        String requestString = 'Endpoint: ' + req.getEndpoint() + '\n'
            + 'Method: ' + req.getMethod() + '\n'
            + 'Body: ' + req.getBody()+'\n'
            +'Header : '+headersString ;
        res.request = requestString;
        // Send HTTP request
        Http http = new Http();
        HTTPResponse response = new HttpResponse();
        Decimal StatusCode = 0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{ "transactionId": "APIF_SV_TRKC_TxIDc6d55954-ea66-4b36-9641-bfc63b77cc78", "output": { "alerts": [ { "code": "VIRTUAL.RESPONSE", "message": "This is a Virtual Response.", "alertType": "NOTE" } ], "completeTrackResults": [ { "trackingNumber": "794843185271", "trackResults": [ { "trackingNumberInfo": { "trackingNumber": "794843185271", "trackingNumberUniqueId": "2460316000~794843185271~FX", "carrierCode": "FDXE" }, "additionalTrackingInfo": { "nickname": "", "packageIdentifiers": [ { "type": "RETURNED_TO_SHIPPER_TRACKING_NUMBER", "values": [ "721968507143" ], "trackingNumberUniqueId": "2460320000", "carrierCode": "" }, { "type": "SHIPPER_REFERENCE", "values": [ "BG-24010554AJQFVBHP" ], "trackingNumberUniqueId": "", "carrierCode": "" } ], "hasAssociatedShipments": false }, "shipperInformation": { "contact": {}, "address": { "city": "HONG KONG", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" } }, "recipientInformation": { "contact": {}, "address": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" } }, "latestStatusDetail": { "code": "DE", "derivedCode": "DE", "statusByLocale": "Delivery exception", "description": "Delivery exception", "scanLocation": { "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "countryCode": "US", "residential": false, "countryName": "United States" }, "ancillaryDetails": [ { "reason": "14", "reasonDescription": "Return tracking number 721968507143", "action": "No action is required. The package is being returned to the shipper.", "actionDescription": "Unable to deliver shipment, returned to shipper" } ] }, "dateAndTimes": [ { "type": "ACTUAL_PICKUP", "dateTime": "2024-01-08T13:46:00+08:00" }, { "type": "SHIP", "dateTime": "2024-01-08T00:00:00-06:00" }, { "type": "ACTUAL_TENDER", "dateTime": "2024-01-08T13:46:00+08:00" } ], "availableImages": [], "specialHandlings": [ { "type": "DELIVER_WEEKDAY", "description": "Deliver Weekday", "paymentType": "OTHER" }, { "type": "NO_SIGNATURE_REQUIRED", "description": "No Signature Required", "paymentType": "OTHER" } ], "packageDetails": { "packagingDescription": { "type": "YOUR_PACKAGING", "description": "Your Packaging" }, "sequenceNumber": "1", "count": "1", "weightAndDimensions": { "weight": [ { "value": "1.1", "unit": "KG" }, { "value": "2.43", "unit": "LB" } ], "dimensions": [ { "length": 19, "width": 18, "height": 8, "units": "CM" }, { "length": 7, "width": 7, "height": 3, "units": "IN" } ] }, "packageContent": [] }, "shipmentDetails": { "possessionStatus": true, "weight": [ { "value": "1.1", "unit": "KG" }, { "value": "2.43", "unit": "LB" } ] }, "scanEvents": [ { "date": "2024-01-10T14:53:00-09:00", "eventType": "RS", "eventDescription": "Returning package to shipper", "exceptionCode": "14", "exceptionDescription": "Return tracking number", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "DELIVERY_LOCATION", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-09T15:15:00-09:00", "eventType": "CD", "eventDescription": "Clearance delay - Import", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "CD", "derivedStatus": "Clearance Delay" }, { "date": "2024-01-09T14:09:00-09:00", "eventType": "CP", "eventDescription": "Clearance in progress", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANC", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T16:07:00-09:00", "eventType": "CP", "eventDescription": "Clearance in progress", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T13:29:00-09:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "71", "exceptionDescription": "Package available for clearance", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T12:05:00-09:00", "eventType": "AR", "eventDescription": "Arrived at FedEx hub", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCR", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T20:50:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "TA YUAN DISTRICT", "postalCode": "337", "countryCode": "TW", "residential": false, "countryName": "Taiwan, China" }, "locationId": "TPERT", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T20:20:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "TA YUAN DISTRICT", "postalCode": "337", "countryCode": "TW", "residential": false, "countryName": "Taiwan, China" }, "locationId": "TPER", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T16:02:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "LANTAU ISLAND", "postalCode": "99999", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "HKGIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T14:45:00+08:00", "eventType": "DP", "eventDescription": "Left FedEx origin facility", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "KWUN TONG", "postalCode": "180", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "KTZA", "locationType": "ORIGIN_FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T13:46:00+08:00", "eventType": "PU", "eventDescription": "Picked up", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "KWUN TONG", "postalCode": "180", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "KTZA", "locationType": "PICKUP_LOCATION", "derivedStatusCode": "PU", "derivedStatus": "Picked up" }, { "date": "2024-01-06T02:02:24-06:00", "eventType": "OC", "eventDescription": "Shipment information sent to FedEx", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "residential": false }, "locationType": "CUSTOMER", "derivedStatusCode": "IN", "derivedStatus": "Label created" } ], "availableNotifications": [ "ON_DELIVERY", "ON_ESTIMATED_DELIVERY" ], "deliveryDetails": { "deliveryAttempts": "0", "deliveryOptionEligibilityDetails": [ { "option": "INDIRECT_SIGNATURE_RELEASE", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "REDIRECT_TO_HOLD_AT_LOCATION", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "REROUTE", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "RESCHEDULE", "eligibility": "INELIGIBLE" }, { "option": "RETURN_TO_SHIPPER", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "DISPUTE_DELIVERY", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "SUPPLEMENT_ADDRESS", "eligibility": "POSSIBLY_ELIGIBLE" } ], "destinationServiceArea": "EDDUNAVAILABLE" }, "originLocation": { "locationContactAndAddress": { "address": { "city": "TSUEN WAN", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" } }, "locationId": "HKGA" }, "destinationLocation": { "locationContactAndAddress": { "address": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" } }, "locationType": "" }, "lastUpdatedDestinationAddress": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" }, "serviceCommitMessage": { "message": "No scheduled delivery date available at this time.", "type": "ESTIMATED_DELIVERY_DATE_UNAVAILABLE" }, "serviceDetail": { "type": "FEDEX_INTERNATIONAL_PRIORITY", "description": "FedEx International Priority", "shortDescription": "IPED" }, "standardTransitTimeWindow": { "window": { "ends": "2024-01-09T20:00:00-05:00" } }, "estimatedDeliveryTimeWindow": { "window": {} }, "goodsClassificationCode": "", "returnDetail": {} } ] }';
            //httpResult = '{ "transactionId": "APIF_SV_TRKC_TxIDc6d55954-ea66-4b36-9641-bfc63b77cc78", "output": { "alerts": [ { "code": "VIRTUAL.RESPONSE", "message": "This is a Virtual Response.", "alertType": "NOTE" } ], "completeTrackResults": [ { "trackingNumber": "794843185271", "trackResults": [ { "trackingNumberInfo": { "trackingNumber": "794843185271", "trackingNumberUniqueId": "2460316000~794843185271~FX", "carrierCode": "FDXE" }, "additionalTrackingInfo": { "nickname": "", "packageIdentifiers": [ { "type": "RETURNED_TO_SHIPPER_TRACKING_NUMBER", "values": [ "721968507143" ], "trackingNumberUniqueId": "2460320000", "carrierCode": "" }, { "type": "SHIPPER_REFERENCE", "values": [ "BG-24010554AJQFVBHP" ], "trackingNumberUniqueId": "", "carrierCode": "" } ], "hasAssociatedShipments": false }, "shipperInformation": { "contact": {}, "address": { "city": "HONG KONG", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" } }, "recipientInformation": { "contact": {}, "address": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" } }, "latestStatusDetail": { "code": "DE", "derivedCode": "DE", "statusByLocale": "Delivery exception", "description": "Delivery exception", "scanLocation": { "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "countryCode": "US", "residential": false, "countryName": "United States" }, "ancillaryDetails": [ { "reason": "14", "reasonDescription": "Return tracking number 721968507143", "action": "No action is required. The package is being returned to the shipper.", "actionDescription": "Unable to deliver shipment, returned to shipper" } ] }, "dateAndTimes": [ { "type": "ACTUAL_PICKUP", "dateTime": "2024-01-08T13:46:00+08:00" }, { "type": "SHIP", "dateTime": "2024-01-08T00:00:00-06:00" }, { "type": "ACTUAL_TENDER", "dateTime": "2024-01-08T13:46:00+08:00" } ], "availableImages": [], "specialHandlings": [ { "type": "DELIVER_WEEKDAY", "description": "Deliver Weekday", "paymentType": "OTHER" }, { "type": "NO_SIGNATURE_REQUIRED", "description": "No Signature Required", "paymentType": "OTHER" } ], "packageDetails": { "packagingDescription": { "type": "YOUR_PACKAGING", "description": "Your Packaging" }, "sequenceNumber": "1", "count": "1", "weightAndDimensions": { "weight": [ { "value": "1.1", "unit": "KG" }, { "value": "2.43", "unit": "LB" } ], "dimensions": [ { "length": 19, "width": 18, "height": 8, "units": "CM" }, { "length": 7, "width": 7, "height": 3, "units": "IN" } ] }, "packageContent": [] }, "shipmentDetails": { "possessionStatus": true, "weight": [ { "value": "1.1", "unit": "KG" }, { "value": "2.43", "unit": "LB" } ] }, "scanEvents": [ { "date": "2024-01-10T14:53:00-09:00", "eventType": "RS", "eventDescription": "Returning package to shipper", "exceptionCode": "14", "exceptionDescription": "Return tracking number", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "DELIVERY_LOCATION", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-09T15:15:00-09:00", "eventType": "CD", "eventDescription": "Clearance delay - Import", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "CD", "derivedStatus": "Clearance Delay" }, { "date": "2024-01-09T14:09:00-09:00", "eventType": "CP", "eventDescription": "Clearance in progress", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANC", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T16:07:00-09:00", "eventType": "CP", "eventDescription": "Clearance in progress", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T13:29:00-09:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "71", "exceptionDescription": "Package available for clearance", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T12:05:00-09:00", "eventType": "AR", "eventDescription": "Arrived at FedEx hub", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "ANCHORAGE", "stateOrProvinceCode": "AK", "postalCode": "99502", "countryCode": "US", "residential": false, "countryName": "United States" }, "locationId": "ANCR", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T20:50:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "TA YUAN DISTRICT", "postalCode": "337", "countryCode": "TW", "residential": false, "countryName": "Taiwan, China" }, "locationId": "TPERT", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T20:20:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "TA YUAN DISTRICT", "postalCode": "337", "countryCode": "TW", "residential": false, "countryName": "Taiwan, China" }, "locationId": "TPER", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T16:02:00+08:00", "eventType": "IT", "eventDescription": "On the way", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "LANTAU ISLAND", "postalCode": "99999", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "HKGIP", "locationType": "FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T14:45:00+08:00", "eventType": "DP", "eventDescription": "Left FedEx origin facility", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "KWUN TONG", "postalCode": "180", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "KTZA", "locationType": "ORIGIN_FEDEX_FACILITY", "derivedStatusCode": "IT", "derivedStatus": "In transit" }, { "date": "2024-01-08T13:46:00+08:00", "eventType": "PU", "eventDescription": "Picked up", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "city": "KWUN TONG", "postalCode": "180", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" }, "locationId": "KTZA", "locationType": "PICKUP_LOCATION", "derivedStatusCode": "PU", "derivedStatus": "Picked up" }, { "date": "2024-01-06T02:02:24-06:00", "eventType": "OC", "eventDescription": "Shipment information sent to FedEx", "exceptionCode": "", "exceptionDescription": "", "scanLocation": { "streetLines": [ "" ], "residential": false }, "locationType": "CUSTOMER", "derivedStatusCode": "IN", "derivedStatus": "Label created" } ], "availableNotifications": [ "ON_DELIVERY", "ON_ESTIMATED_DELIVERY" ], "deliveryDetails": { "deliveryAttempts": "0", "deliveryOptionEligibilityDetails": [ { "option": "INDIRECT_SIGNATURE_RELEASE", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "REDIRECT_TO_HOLD_AT_LOCATION", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "REROUTE", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "RESCHEDULE", "eligibility": "INELIGIBLE" }, { "option": "RETURN_TO_SHIPPER", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "DISPUTE_DELIVERY", "eligibility": "POSSIBLY_ELIGIBLE" }, { "option": "SUPPLEMENT_ADDRESS", "eligibility": "POSSIBLY_ELIGIBLE" } ], "destinationServiceArea": "EDDUNAVAILABLE" }, "originLocation": { "locationContactAndAddress": { "address": { "city": "TSUEN WAN", "countryCode": "HK", "residential": false, "countryName": "Hong Kong SAR, China" } }, "locationId": "HKGA" }, "destinationLocation": { "locationContactAndAddress": { "address": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" } }, "locationType": "" }, "lastUpdatedDestinationAddress": { "city": "FARMINGTON", "stateOrProvinceCode": "ME", "countryCode": "US", "residential": false, "countryName": "United States" }, "serviceCommitMessage": { "message": "No scheduled delivery date available at this time.", "type": "ESTIMATED_DELIVERY_DATE_UNAVAILABLE" }, "serviceDetail": { "type": "FEDEX_INTERNATIONAL_PRIORITY", "description": "FedEx International Priority", "shortDescription": "IPED" }, "standardTransitTimeWindow": { "window": { "ends": "2024-01-09T20:00:00-05:00" } }, "estimatedDeliveryTimeWindow": { "window": {} }, "goodsClassificationCode": "", "returnDetail": {} } ] }';
            StatusCode = 500;
        }else {
            response = http.send(req);httpResult = response.getBody();StatusCode = response.getStatusCode();
        }
        system.debug('StatusCode :' +StatusCode);
        if (StatusCode == 200) {
            res.response = httpResult;
            // Parse the JSON response into a Map
            system.debug('httpResult :' +httpResult);
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResult);Map<String, Shipment_Flow__c> sfMap = new Map<String, Shipment_Flow__c>();
            List<Shipment_Flow__c> sf2create = new List<Shipment_Flow__c>();
            if(Ship != null) {
                for(Shipment_Flow__c sf: [select Id, Name, Shipment__c, Location__c,Shipment_DateTime__c, Description__c, Shipment_Flow_Start_Date__c, Shipment_Flow_End_Date__c from Shipment_Flow__c where Shipment__c =: Ship.Id Order by Name Asc]) {
                    sfMap.put(sf.Shipment_DateTime__c, sf);
                }
            }
            system.debug('sfMap : '+sfMap.size());
            // Extract the necessary details
            Map<String, Object> output = (Map<String, Object>) jsonResponse.get('output');
            if (output.containsKey('completeTrackResults')){
                List<Object> completeTrackResults = (List<Object>) output.get('completeTrackResults');
                for (Object result : completeTrackResults) {
                    Map<String, Object> trackResult = (Map<String, Object>) result;
                    if (trackResult.containsKey('trackResults')) {
                        List<Object> trackEvents = (List<Object>) trackResult.get('trackResults');
                        for (Object trackEvent : trackEvents) { Map<String, Object> event = (Map<String, Object>) trackEvent;
                            List<Object> scanEvents = (List<Object>) event.get('scanEvents');
                            if (scanEvents != null && !scanEvents.isEmpty()) {
                                Integer i = 1;
                                for (Object scanEvent : scanEvents) {
                                    Map<String, Object> scanEventMap = (Map<String, Object>) scanEvent;string eventdate = (string) scanEventMap.get('date');String yys, mms, dds, hhs, mins, secs;
                                    yys = eventdate.substring(0,4);  mms = eventdate.substring(5,7);dds = eventdate.substring(8,10);  hhs = eventdate.substring(11,13);mins = eventdate.substring(14,16);  secs = eventdate.substring(17,19);String dateTimeString = yys +'-'+ mms +'-'+ dds + ' '+ hhs +':'+ mins +':'+ secs;
                                    system.debug('dateTimeString : '+dateTimeString);
                                    Datetime dtValue = Datetime.valueOf(dateTimeString);

                                    String eventType = (String) scanEventMap.get('eventType');
                                    system.debug('eventType : '+eventType);
                                    String eventDescription = (String) scanEventMap.get('eventDescription');
                                    system.debug('eventDescription : '+eventDescription);
                                    Map<String, Object> scanLocation = (Map<String, Object>) scanEventMap.get('scanLocation');
                                    String city = (String) scanLocation.get('city');String postalCode = (String) scanLocation.get('postalCode');String countryCode = (String) scanLocation.get('countryCode');String locationId = (String) scanEventMap.get('locationId');String locationType = (String) scanEventMap.get('locationType');String derivedStatus = (String) scanEventMap.get('derivedStatus');
                                     System.debug(' beforesfMap.containsKey(' + String.valueOf(dtValue) + ') => ' + sfMap.containsKey(String.valueOf(dtValue)));

                                    if(!sfMap.containsKey(String.valueof(dtValue))){
                                        System.debug('afer sfMap.containsKey(' + String.valueOf(dtValue) + ') => ' + sfMap.containsKey(String.valueOf(dtValue)));
                                        Shipment_Flow__c sf = new Shipment_Flow__c(Shipment_DateTime__c = String.valueof(dtValue));
                                        sf.Name = 'SF ' + Ship.Name + '-' + i;
                                        if(Ship != null) sf.Shipment__c = Ship.Id;
                                        sf.Active__c = true;sf.Location__c = '';
                                        if(city != null) sf.Location__c = city;
                                        if(postalCode != null) sf.Location__c+= ',' +postalCode;
                                        if(countryCode != null)    sf.Location__c+= ',' + countryCode;
                                        // Datetime eventDateTime = Datetime.valueOfGmt(eventdate);
                                        // String formattedDate = eventDateTime.format('yyyy-MM-dd HH:mm:ss');

                                        sf.Shipment_Flow_Start_Date__c = Datetime.valueOf(dtValue);sf.Shipment_Flow_End_Date__c =datetime.valueOf(dtValue);sf.Description__c = '';
                                        if(eventType != null) sf.Description__c = eventType;
                                        if(eventDescription != null) sf.Description__c += ':'+eventDescription;
                                        system.debug('sf.Description__c : '+sf.Description__c);
                                        if(derivedStatus == 'Delivered') Ship.Status__c = 'Delivered';
                                        sf2create.add(sf);
                                        i++;
                                    }
                                    else{
                                        Shipment_Flow__c sf = sfMap.get(String.valueof(dtValue));
                                        if(derivedStatus == 'Delivered') Ship.Status__c = 'Delivered';
                                        sf2create.add(sf);
                                        system.debug('sf2create added existing sf: ' + sf2create);  
                                    }

                                }
                            }
                        }
                    }
                }

            }
            if(sf2create.size() > 0) {
                System.debug('sf2create : ' + sf2create);
                // upsert sf2create;
                // System.debug('Upserted Shipment_Flow__c records: ' + sf2create);
                // res.ShipFlows = sf2create;
              // for fls  upsert sf2create;
              //commented for test ZAIN
              List<SObject> safeListsf2create = FLSHelper.getSafeRecords(
                    sf2create,
                    'Shipment_Flow__c',
                    AccessType.UPDATABLE
                );
                List<Shipment_Flow__c> typedListsF2create = new List<Shipment_Flow__c>();
                for (SObject sf : safeListsf2create) {
                  Shipment_Flow__c sfRecords = (Shipment_Flow__c)sf;
                  system.debug('sfRecords before setting ship.Id: ' + sfRecords);
                  system.debug('b ship.Id to be set in sfRecords: ' + Ship.Id);
                  system.debug('sfRecords populated fields: ' + sfRecords.getPopulatedFieldsAsMap().containsKey('Shipment___c'));
                  system.debug('Schema.sObjectType.Shipment_Flow__c.fields.Shipment__c.isUpdateable(): ' + Schema.sObjectType.Shipment_Flow__c.fields.Shipment__c.isUpdateable());
                   List<Shipment_Flow__c> existingRecords = [select Id from Shipment_Flow__c where Shipment__c =: Ship.Id Order by Name Asc];
                  if(!sfRecords.getPopulatedFieldsAsMap().containsKey('Shipment__c') && Ship.Id != null && existingRecords.size() == 0){
                    system.debug('ship.Id to be set in sfRecords: ' + Ship.Id);
                    sfRecords.Shipment__c = Ship.Id;
                    system.debug('a ship.Id set in sfRecords: ' + sfRecords);
                    
                  }
                
                    typedListsF2create.add(sfRecords);
                    system.debug('typedListsF2create record: ' + sfRecords);
                    system.debug('typedListsf2create record: ' + typedListsf2create);
                }
                if (!typedListsf2create.isEmpty()) {
                System.debug('Upserting Shipment_Flow__c records: ' + typedListsf2create);
                    upsert typedListsf2create; // or insert/update as needed
                }
              System.debug('Upserted Shipment_Flow__c records: ' + typedListsf2create[0]);
              res.ShipFlows = typedListsf2create;
            //till here ZAIN 
            }


            if(Ship.Status__c == 'Delivered') {
            //  commented for FLS check   update Ship;
            List<SObject> safeShip = FLSHelper.getSafeRecords(
                    new List<Shipment__c>{Ship},
                    'Shipment__c',
                    AccessType.UPDATABLE
                );
                List<Shipment__c> typedShip = new List<Shipment__c>();
                for (SObject sp : safeShip) {
                    typedShip.add((Shipment__c)sp);
                }
                if (!typedShip.isEmpty()) {
                    update typedShip; // or insert/update as needed
                }
            }
            res.ShipDetails = Ship;

        }
        System.debug('res : '+res);
        return res;
    }

   /* @AuraEnabled
    global static String getAccessToken(string parentKey,String parentPassword,String childKey,String childpassword,String endPoint){
        HttpRequest request = new HttpRequest();
        String parentEndPoint = endPoint +'/oauth/token';
        request.setEndpoint(parentEndPoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String requestBody = '';
        if(childKey != null && childKey != '' && childpassword != null && childpassword != ''){
            requestBody = 'grant_type=csp_credentials'
                + '&client_id=' + EncodingUtil.urlEncode(parentKey, 'UTF-8')
                + '&client_secret=' + EncodingUtil.urlEncode(parentPassword, 'UTF-8')
                + '&child_Key=' + EncodingUtil.urlEncode(childKey, 'UTF-8')
                + '&child_secret=' + EncodingUtil.urlEncode(childpassword, 'UTF-8');
        }
        else{
            requestBody = 'grant_type=client_credentials'
                + '&client_id=' + EncodingUtil.urlEncode(parentKey, 'UTF-8')
                + '&client_secret=' + EncodingUtil.urlEncode(parentPassword, 'UTF-8');
            //  + '&child_Key=' + EncodingUtil.urlEncode(childKey, 'UTF-8')
            //+ '&child_secret=' + EncodingUtil.urlEncode(childpassword, 'UTF-8');
        }

        request.setBody(requestBody);
        String headers = request.getHeader('Content-Type');
        // Convert the HttpRequest object to a string for debugging or logging
        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        // FedexLWCRestAPI.request_1 = requestString;
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        Decimal StatusCode = 0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{"access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZSI6WyJDWFMtVFAiXSwiUGF5bG9hZCI6eyJjbGllbnRJZGVudGl0eSI6eyJjbGllbnRLZXkiOiJsN2M1YzNjZmY0NmZkZDQ3ZDlhNDAzMTFiMjQyNWVkZTk4IiwiY2hpbGRLZXkiOiIwNDljNTRjZS0xNDkzLTQ5ZjctYjc1Yy1jYmE3ZmQ0MGE2YjEiLCJjbGllbnRQcm9kdWN0VmVyc2lvbiI6IjEzOTQiLCJjbGllbnRQcm9kdWN0SUQiOiJBUVhMIiwiY2hpbGRBcHBOYW1lIjoiZWE1NzA1MDItNmIxZS00OWE3LWFjYzgtMjM4MjEwNWU5N2UzXzI1NjUxMzUxNyJ9LCJhdXRoZW50aWNhdGlvblJlYWxtIjoiQ01BQyIsImFkZGl0aW9uYWxJZGVudGl0eSI6eyJ0aW1lU3RhbXAiOiIyMi1NYXItMjAyNCAwMjoyMTozMiBFU1QiLCJncmFudF90eXBlIjoiY3NwX2NyZWRlbnRpYWxzIiwiYXBpbW9kZSI6IlNhbmRib3giLCJjeHNJc3MiOiJodHRwczovL2N4c2F1dGhzZXJ2ZXItc3RhZ2luZy5hcHAucGFhcy5mZWRleC5jb20vdG9rZW4vb2F1dGgyIn0sInBlcnNvbmFUeXBlIjoiQ29tcGF0aWJsZVByb3ZpZGVyX0NTUCJ9LCJleHAiOjE3MTEwOTU2OTIsImp0aSI6IjdjNDQ4YjAyLTExNWItNDdjMy04OGFhLWNkNDExMmQ5M2NlMiJ9.lf-jgAJVFPnN_jZpdxgh55BwDuvKxRV6oeSXtQ2V2ilXL-9nNkFzxezIJjOhb8iYU-UkKkRwXbLzPcPBPSaY3HFqKVMGopF19v0jJpYWp_CQjg_EQfWM3EkfpZ37ZPTMeRD1VZgon33X_NnvYRdNGZruLPehJa7d9UWWTfc1N5ZNvAzcco9-K9f3oZx75CgKrkPg4ujn-aSWpt44wDaEmiE1zbPvZ0OB0ZK2cwKtCJjBGfd2vpIF6NYAsKPxZkcQ1crEAuLT2jwUs3lBo37WkJi0xo2aT68pDfVpdnbr_cwJeuCpDKLE1zjcHc9FShGukDYvKQO4VFo2WYFmHJGsPCztA74Xsu36whZuuHl89LVWyjYEvgn60GIqqkDW1HICONSkC7_RBu5GiYO5tg_eezfHAIkh9xZ4mn0Ex2hSu2bZgGUFuYUipxOGGKX6rXvMkQeheFjtfdMTSqcP2vFAJ7W0-VjscN39SdGefROkAlwEtK20olG6TLv8DCnvbADDV8GjBuYgSJPOAiNF9LnS4LrlO9JmRouMuTgbW_2uYzPOvWHvXCykD2zSNjeG0H1GUOwKioVchW-Xtgnryr8wCD63YJs2-rMjwSmz7hSsFIEwqqdnB_wm4l5qE_VQVvLo5TfrgOShYDkYOyGEJY8zMu4up0AeQsdUZVDYA1UqM6Y",  "token_type": "bearer","expires_in": 3599,  "scope": "CXS-TP"}';
            StatusCode = 200;
        }else {
            response = http.send(request);
            httpResult = response.getBody();
            StatusCode = response.getStatusCode();
        }
        if (StatusCode == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(httpResult);
            String accessToken = (String)jsonResponse.get('access_token');
            system.debug('accessToken : '+accessToken);
            return accessToken;
        }
        else return null;
    }
*/
    @AuraEnabled
    global static String getAccessToken(string parentKey,String parentPassword,String childKey,String childpassword,String endPoint){

		System.debug('parentKey->'+parentKey);
        System.debug('parentPassword->'+parentPassword);
        System.debug('childKey->'+childKey);
        System.debug('childpassword->'+childpassword);
        HttpRequest request = new HttpRequest();
        String parentEndPoint = endPoint +'/oauth/token';
        request.setEndpoint(parentEndPoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String requestBody = '';
        if(childKey != null && childKey != '' && childpassword != null && childpassword != ''){
            requestBody = 'grant_type=csp_credentials'
                + '&client_id=' + EncodingUtil.urlEncode(parentKey, 'UTF-8')
                + '&client_secret=' + EncodingUtil.urlEncode(parentPassword, 'UTF-8')
                + '&child_Key=' + EncodingUtil.urlEncode(childKey, 'UTF-8')
                + '&child_secret=' + EncodingUtil.urlEncode(childpassword, 'UTF-8');
        }
        else{
            requestBody = 'grant_type=client_credentials'
                + '&client_id=' + EncodingUtil.urlEncode(parentKey, 'UTF-8')
                + '&client_secret=' + EncodingUtil.urlEncode(parentPassword, 'UTF-8');
            //  + '&child_Key=' + EncodingUtil.urlEncode(childKey, 'UTF-8')
            //+ '&child_secret=' + EncodingUtil.urlEncode(childpassword, 'UTF-8');
        }

        request.setBody(requestBody);
        String headers = request.getHeader('Content-Type');
        // Convert the HttpRequest object to a string for debugging or logging
        String headersString = '';
        headersString += 'Content-Type: ' + request.getHeader('Content-Type') + '\n';
        String requestString = 'Endpoint: ' + request.getEndpoint() + '\n'
            + 'Method: ' + request.getMethod() + '\n'
            + 'Body: ' + request.getBody()+'\n'
            +'Header : '+headersString ;
        // FedexLWCRestAPI.request_1 = requestString;
        system.debug('reuest : '+requestString);
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        Decimal StatusCode = 0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{"access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzY29wZSI6WyJDWFMtVFAiXSwiUGF5bG9hZCI6eyJjbGllbnRJZGVudGl0eSI6eyJjbGllbnRLZXkiOiJsN2M1YzNjZmY0NmZkZDQ3ZDlhNDAzMTFiMjQyNWVkZTk4IiwiY2hpbGRLZXkiOiIwNDljNTRjZS0xNDkzLTQ5ZjctYjc1Yy1jYmE3ZmQ0MGE2YjEiLCJjbGllbnRQcm9kdWN0VmVyc2lvbiI6IjEzOTQiLCJjbGllbnRQcm9kdWN0SUQiOiJBUVhMIiwiY2hpbGRBcHBOYW1lIjoiZWE1NzA1MDItNmIxZS00OWE3LWFjYzgtMjM4MjEwNWU5N2UzXzI1NjUxMzUxNyJ9LCJhdXRoZW50aWNhdGlvblJlYWxtIjoiQ01BQyIsImFkZGl0aW9uYWxJZGVudGl0eSI6eyJ0aW1lU3RhbXAiOiIyMi1NYXItMjAyNCAwMjoyMTozMiBFU1QiLCJncmFudF90eXBlIjoiY3NwX2NyZWRlbnRpYWxzIiwiYXBpbW9kZSI6IlNhbmRib3giLCJjeHNJc3MiOiJodHRwczovL2N4c2F1dGhzZXJ2ZXItc3RhZ2luZy5hcHAucGFhcy5mZWRleC5jb20vdG9rZW4vb2F1dGgyIn0sInBlcnNvbmFUeXBlIjoiQ29tcGF0aWJsZVByb3ZpZGVyX0NTUCJ9LCJleHAiOjE3MTEwOTU2OTIsImp0aSI6IjdjNDQ4YjAyLTExNWItNDdjMy04OGFhLWNkNDExMmQ5M2NlMiJ9.lf-jgAJVFPnN_jZpdxgh55BwDuvKxRV6oeSXtQ2V2ilXL-9nNkFzxezIJjOhb8iYU-UkKkRwXbLzPcPBPSaY3HFqKVMGopF19v0jJpYWp_CQjg_EQfWM3EkfpZ37ZPTMeRD1VZgon33X_NnvYRdNGZruLPehJa7d9UWWTfc1N5ZNvAzcco9-K9f3oZx75CgKrkPg4ujn-aSWpt44wDaEmiE1zbPvZ0OB0ZK2cwKtCJjBGfd2vpIF6NYAsKPxZkcQ1crEAuLT2jwUs3lBo37WkJi0xo2aT68pDfVpdnbr_cwJeuCpDKLE1zjcHc9FShGukDYvKQO4VFo2WYFmHJGsPCztA74Xsu36whZuuHl89LVWyjYEvgn60GIqqkDW1HICONSkC7_RBu5GiYO5tg_eezfHAIkh9xZ4mn0Ex2hSu2bZgGUFuYUipxOGGKX6rXvMkQeheFjtfdMTSqcP2vFAJ7W0-VjscN39SdGefROkAlwEtK20olG6TLv8DCnvbADDV8GjBuYgSJPOAiNF9LnS4LrlO9JmRouMuTgbW_2uYzPOvWHvXCykD2zSNjeG0H1GUOwKioVchW-Xtgnryr8wCD63YJs2-rMjwSmz7hSsFIEwqqdnB_wm4l5qE_VQVvLo5TfrgOShYDkYOyGEJY8zMu4up0AeQsdUZVDYA1UqM6Y",  "token_type": "bearer","expires_in": 3599,  "scope": "CXS-TP"}';
            StatusCode = 200;
        }else {
            response = http.send(request);
            httpResult = response.getBody();
             system.debug('httpResult : '+httpResult);
            StatusCode = response.getStatusCode();
        }
        if (StatusCode == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(httpResult);
            String accessToken = (String)jsonResponse.get('access_token');
            system.debug('accessToken : '+accessToken);
            return accessToken;
        }
        else return null;
    }
    @AuraEnabled
    global static Wrapper getDefaultData(String ShipId,String packIds,Boolean ReturnShip){
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

        //1
        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Terms_Of_Shipment__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.TosConfirmation = options;

        //2
        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Reason_For_Export__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.RfeConfirmation = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Signature_Services__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.SignatureServices = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Fedex_Special_Services__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.specialServices = options;

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

        
        String packageFields = UtilClass.selectStarFromSObject('Package__c');
        String addressFields = UtilClass.selectStarFromSObject('Address__c');
        string packageListFields = UtilClass.selectStarFromSObject('Package_List__c');
        if(!ReturnShip){
            if(ShipId != null && ShipId != ''){
                system.debug('enterd ship id');
                String shipfields = UtilClass.selectStarFromSObject('Shipment__c');
                String ShipmentRecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Shipment__c','Fedex_Shipping');

                //wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name, Logistic__r.From_Contact__c,Logistic__r.Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c,Logistic__r.Billing_Contact__c, Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,Logistic__r.Billing_Contact_Return__r.Id,Logistic__r.Billing_Contact_Return__r.Name,Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c, Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c, Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email,  Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c,  Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c,  Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email from Package__c where Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Active__c = true');
                wrap.packList = Database.query( 'SELECT ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name, Logistic__r.From_Contact__c,Logistic__r.Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c,Logistic__r.Billing_Contact__c, Logistic__r.Billing_Account_Number__c,Logistic__r.Billing_Address__c,Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,Logistic__r.Billing_Contact_Return__r.Id,Logistic__r.Billing_Contact_Return__r.Name,Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c, Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c, Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email,  Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c,  Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c,  Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email FROM Package__c WHERE Shipment__c = \'' + String.escapeSingleQuotes(shipId) + '\' AND Active__c = true');
                set<Id> packageIds = new Set<Id>();
                system.debug('wrp.packlist----'+wrap.packList);
                for(Package__c pck : wrap.packList ) packageIds.add(pck.Id);
                //wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', Package__r.Name, Logistic_Line_Item__r.Product__c,Logistic_Line_Item__r.Product__r.Weight__c,Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c, Package__r.Sales_Order__c, Order_Product__r.Base_Price__c, Sales_Order_Line_Item__r.Base_Price__c, Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Sales_Order_Line_Item__r.Product__r.SKU__c, Sales_Order_Line_Item__r.Product__r.Name,Sales_Order_Line_Item__r.Product__r.Declared_Shipment_Value__c,Order_Product__r.Product2.Declared_Shipment_Value__ Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name, RMA_Line_Item__r.Ord_Item__r.Product2.Name, RMA_Line_Item__r.SOLI__r.Product__r.Name, Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, Sales_Order_Line_Item__r.Total_Price__c, Order_Product__r.ReturnedQuantity__c, Sales_Order_Line_Item__r.ReturnedQuantity__c, Order_Product__r.Order.Name, Sales_Order_Line_Item__r.Sales_Order__r.Name, Order_Product__r.UnitPrice, Sales_Order_Line_Item__r.Price_Product__c, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c, Sales_Order_Line_Item__r.Product__r.Goods_Description__c, Sales_Order_Line_Item__r.Product__r.Commodity_Code__c FROM Package_List__c WHERE Package__c IN :packageIds');
                wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packageIds' );


                List<Shipment__c> Shipslist = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
                if(Shipslist.size() > 0) wrap.ship  = Shipslist[0];
                else wrap.alertlist.add('Shipment is Either Cancelled or not availbale in the system');
                List<Shipment__c> returnShips = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = true AND Active__c = true And Master_Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\') Limit 1');
                if(returnShips.size() > 0) wrap.returnShip =returnShips[0];
            }
            else if(packIds != null && packIds != ''){
                system.debug('entered else if of packsIds'+packIds);
                List<String> packId = (List<String>) JSON.deserialize(packIds,List<String>.class);
                wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Account__c,Logistic__r.Account__r.Id,Logistic__r.Account__r.Name,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name,Logistic__r.From_Contact__c, Logistic__r.Contact__c,Logistic__r.Billing_Account_Number__c,Logistic__r.Billing_Address__c,Logistic__r.Billing_Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c, Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c ,Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,  '+
                                               +' Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c,Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_From_Address__c,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c,Order__r.Contact__r.Email, Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c,  '+
                                               +' Logistic__r.Billing_Contact_Return__r.Id, Logistic__r.Billing_Contact_Return__r.Name,Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Estimated_Shipping_Amount__c, Order__r.Insurance_Charges__c, Order__r.Shipping_VAT__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c, '+
                                               +' Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c, '+
                                               +' Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email ,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__r.Contact__c from Package__c where Id In  :packId  And Active__c = true');
                wrap.packItems = Database.query(
                    'SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packId');
               /* wrap.packItems = Database.query('select ' + String.escapeSingleQuotes(packageListFields) + ' ,Logistic_Line_Item__r.Product__c,Logistic_Line_Item__r.Product__r.Weight__c,Package__r.Name, Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c ,Order_Product__r.Base_Price__c, '+
                                                +' Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name,RMA_Line_Item__r.Ord_Item__r.Product2.Name, '+
                                                +' Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, '+
                                                +' Order_Product__r.Order.Name , Order_Product__r.UnitPrice, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c From Package_List__c where Package__c IN :packId');*/
            }
            System.debug('wrap.packList.size()==>'+wrap.packList.size());
            System.debug('wrap.packItems.size()==>' + JSON.serialize(wrap.packList));
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

                    if(wrap.packList[0].Return_Merchandise_Authorisation__c != null){
                        System.debug('entered rma 1');
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Address__c != null) {
                            System.debug('entered rma 2');
                            wrap.fromAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone,Company__r.Name, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Address__c + '\' Limit 1');
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Site__r.Address__c != null){
                            wrap.toAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Company__r.Name,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Site__r.Address__c + '\' Limit 1');
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Address__r.Contact__c != null){
                            wrap.fromContact = Database.query('select Id,Name,accountId,Account.Name,Account.Phone,Account.Email__c, Email, Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Address__r.Contact__c + '\' Limit 1');
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Return_Contact__c != null){
                            wrap.toContact = Database.query('select Id,Name,accountId, Account.Name, Account.Phone,Email, Account.Email__c,Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Return_Contact__c + '\' Limit 1');
                        }
                    }



                //khaleeq
              /*  else if(wrap.packList[0].Return_Merchandise_Authorisation__c != null){
                    System.debug('entered RMA');
                    Return_Merchandise_Authorisation__c RMA =[Select Id, Address__c,Site__c, Site__r.Address__c From Return_Merchandise_Authorisation__c where Id=:wrap.packList[0].Return_Merchandise_Authorisation__c ];
                	if(RMA.Id != null && RMA.Site__c != null){
                        if(RMA.Site__r.Address__c != null) {
                            wrap.address = [Select Id, Name, Customer__c, Contact__c, Active__c,Customer__r.Company__c,Customer__r.Phone,Customer__r.Email__c,
                                       Is_Shipping_Address__c, Is_Billing_Address__c, Address_Line1__c,
                                       Address_Line2__c, Address_Line3__c, City__c, Country__c,
                                       State__c, Postal_Code__c, Contact__r.Company__c, Contact__r.Name,
                                       Contact__r.Email, Contact__r.Phone from Address__c where Id=:RMA.Site__r.Address__c limit 1];
                        }
                    }
                }*/

            }else {
                System.debug('entered if else');
            }

        }
        myConstructorWrapper MCW = new myConstructorWrapper();
        string credName = system.Label.FedexRestAPIName;
        		System.debug('credName = ' + credName);
        String credentialFields = UtilClass.selectStarFromSObject('Credentials__c');
        MCW.fedCredentials = Database.query('select ' + credentialFields + ' from Credentials__c where (Name = :credName And Active__c = true) Limit 1');
        System.debug('MCW.fedCredentials = ' + MCW.fedCredentials);
        System.debug('MCW.fedCredentials[0].Shipper_Country__c = ' + MCW.fedCredentials[0].Shipper_Country__c);
        if(MCW.fedCredentials.size() > 0){
            MCW.parentKey =MCW.fedCredentials[0].Parent_Key__c;
            MCW.parentPassword = MCW.fedCredentials[0].Parent_Password__c;
            MCW.endPoint = MCW.fedCredentials[0].URL__c;
            MCW.accountNumber = MCW.fedCredentials[0].UPS_Account_Number__c;
            MCW.childKey = MCW.fedCredentials[0].key__c;
            MCW.childpassword = MCW.fedCredentials[0].Password_Transkey__c;
            if(Fedex.getProvinceCode(MCW.fedCredentials[0].Shipper_Province__c) != '')
                MCW.shipperProvinceCode = Fedex.getProvinceCode(MCW.fedCredentials[0].Shipper_Province__c);
            else if(MCW.fedCredentials[0].Shipper_Province__c != null && MCW.fedCredentials[0].Shipper_Province__c != '') MCW.wrapError = 'FedEx Shipping Service Unavailable : Shipper Province Code not found';
            if(Fedex.getCountryCode(MCW.fedCredentials[0].Shipper_Country__c) != '')
                MCW.shipperCountryCode = Fedex.getCountryCode(MCW.fedCredentials[0].Shipper_Country__c); else MCW.wrapError = 'FedEx Shipping Service Unavailable : Shipper Country Code not found';
        }
        else MCW.wrapError = 'FedEx Shipping Service Unavailable : Please setup FedEx credentials';

        wrap.credsWrap = MCW;
        Functionality_Control__c FC = new Functionality_Control__c();
        FC = Functionality_Control__c.getValues(userInfo.getuserid());
        if(FC == null){ FC = Functionality_Control__c.getValues(userInfo.getProfileId());   if(FC==null) FC = Functionality_Control__c.getInstance();  }
        if(FC != null){
            wrap.disableBillingDetails = FC.Allow_Billing_details_edit_in_Ship_scree__c;
            wrap.allowReturnShipment = FC.allowFedExReturnShipment__c;
            wrap.allowUPSReturnShipmentFromFedex = FC.allowUPSReturnShipmentFromFedEx__c;
             wrap.disableEditBillOptReturnShipment = FC.disableEditBillOptReturnShipment__c;
        }
        return wrap;
        }catch(Exception e){
            System.debug('error->'+e.getLineNumber()+' and '+e.getMessage());
        }
        return wrap;
    }

    global class selectOptions{
        @AuraEnabled global string value {get;set;}
        @AuraEnabled global string label {get;set;}
        global selectOptions(){ value = label = '';
        }
        global selectOptions(string label,String value){
            this.value = value;
            this.label = label;
        }

    }
    global class Wrapper{




        @AuraEnabled global List<selectOptions> ReturnService   {get;set;}@AuraEnabled global List<selectOptions>  SignatureServices   {get;set;}
        @AuraEnabled global List<selectOptions>  SaturdayDelivery {get;set;}@AuraEnabled global List<selectOptions>  AdditionalHandling {get;set;}@AuraEnabled global List<selectOptions>  VerbalConfirmation {get;set;}

        @AuraEnabled global List<selectOptions> DeliveryConfirmation {get;set;}@AuraEnabled global List<selectOptions> qvNotification {get;set;}
        @AuraEnabled global List<selectOptions> StatusConfirmation {get;set;}@AuraEnabled global List<selectOptions> CarbonNeutral {get;set;}
        @AuraEnabled global List<selectOptions> LabelOptions            {get;set;}

        @AuraEnabled global myConstructorWrapper credsWrap {get;set;}@AuraEnabled global List<selectOptions> COD            {get;set;}
        @AuraEnabled global List<Package__c> packList {get;set;}@AuraEnabled global List<selectOptions> DryIce         {get;set;}
        @AuraEnabled global Address__c address {get;set;}
        @AuraEnabled global List<Package_List__c> packItems {get;set;}
        @AuraEnabled global Shipment__c ship{get;set;}@AuraEnabled global List<selectOptions> specialServices         {get;set;}@AuraEnabled global List<selectOptions> TosConfirmation   {get;set;}@AuraEnabled global List<selectOptions>  RfeConfirmation {get;set;}@AuraEnabled global List<selectOptions>  BillingOptions {get;set;}
        @AuraEnabled global Shipment__c returnShip{get;set;}
        @AuraEnabled global Address__c fromAddress{get;set;}
        @AuraEnabled global contact fromContact{get;set;}
        @AuraEnabled global Address__c toAddress{get;set;}
        @AuraEnabled global contact toContact{get;set;}
        @AuraEnabled global Shipment__c shipment{get;set;} @AuraEnabled global string request {get;set;}@AuraEnabled global string response {get;set;}@AuraEnabled global string error {get;set;}
        // @AuraEnabled global List<trackwrapper> trackWrap {get;set;}
        @AuraEnabled global List<Shipment_Flow__c>  Shipmentflows{get;set;}
        @AuraEnabled global Boolean disableBillingDetails  {get;set;}
        @AuraEnabled global Boolean allowReturnShipment  {get;set;}
        @AuraEnabled global Boolean allowUPSReturnShipmentFromFedex {get;set;}
       @AuraEnabled global Boolean disableEditBillOptReturnShipment {get;set;}
        @AuraEnabled global List<String> alertlist {get;set;}
        global Wrapper(){
            alertlist = new List<String>();
            disableBillingDetails = true;
            Shipmentflows = new List<Shipment_Flow__c>();
            // trackWrap = new List<trackwrapper>();
            shipment = new Shipment__c();returnShip = new Shipment__c();toContact = new contact();fromContact = new contact();
            fromAddress = new Address__c();
            toAddress = new Address__c();
            ship = new Shipment__c();
            packItems = new List<Package_List__c>();
            packList = new List<Package__c>();
            address = new Address__c();
            credsWrap = new myConstructorWrapper();
            qvNotification = new List<selectOptions>();
            CarbonNeutral = new List<selectOptions>();
            COD = new List<selectOptions>();
            DryIce =  new List<selectOptions>();
            ReturnService = new List<selectOptions>();
            SaturdayDelivery = new List<selectOptions>();
            AdditionalHandling = new List<selectOptions>();
            VerbalConfirmation  = new List<selectOptions>();
            BillingOptions  = new List<selectOptions>();
            SignatureServices = new List<selectOptions>();
            RfeConfirmation = new List<selectOptions>();
            TosConfirmation = new List<selectOptions>();
            specialServices =  new List<selectOptions>();
            LabelOptions = new List<selectOptions>();
            StatusConfirmation = new List<selectOptions>();
            DeliveryConfirmation = new List<selectOptions>();

        }
    }
    global class myConstructorWrapper{
        @AuraEnabled global List<Credentials__c> fedCredentials                { get; set; }
        @AuraEnabled global String parentKey                                   { get; set; }
        @AuraEnabled global String parentPassword                              { get; set; }
        @AuraEnabled global String childKey                                    { get; set; }
        @AuraEnabled global String childpassword                               { get; set; }
        @AuraEnabled global String endPoint                                    { get; set; }@AuraEnabled global String meterNumber                                 { get; set; }
        @AuraEnabled global String accountNumber                               { get; set; }
        @AuraEnabled global String shipperProvinceCode                         { get; set; }
        @AuraEnabled global String shipperCountryCode                          { get; set; }@AuraEnabled global String wrapError                                   { get; set; }
    }
    global class addressWrap{
        @AuraEnabled global String errMsg                                   { get; set; }@AuraEnabled global Address__c address                           { get; set; }
    }

  global class shipmentResponse {
      @AuraEnabled global List<String> errMsgs { get; set; }
      @AuraEnabled global String successMsg { get; set; }
      @AuraEnabled global String request { get; set; }
      @AuraEnabled global String response { get; set; }@AuraEnabled global List<Shipment_Flow__c> ShipFlows { get; set; }
      @AuraEnabled global Shipment__c ShipDetails { get; set; }
      @AuraEnabled global List<Attachment> attList { get; set; }

      global shipmentResponse() {
          errMsgs = new List<String>();
      }
  }


}