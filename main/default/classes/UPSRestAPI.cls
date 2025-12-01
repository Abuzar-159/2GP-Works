global With Sharing class UPSRestAPI {

    public Credentials__c upsSetup                     { get; set; }
    public String User_IPaddress                       { get; set; }
    public String errorMsg                             { get; set; }

    @AuraEnabled
    public static String getProvinceCode(String provinceName) {
       List<Province_Codes__c> provinceList;
        if(provinceName != null && provinceName != '') {
            provinceList = [Select Id, Name, Code__c, Province__c From Province_Codes__c Where Province__c =: String.escapeSingleQuotes(provinceName) Limit 1];
        } if(provinceList != null && provinceList.size() > 0) return provinceList[0].Code__c;
        else return '';
       // return null;
    }

    @AuraEnabled
    public static String getCountryCode(String countryName) {
        List<Country_Codes__c> countryList;
        if(countryName != null && countryName != '') {
            countryList = [Select Id, Name, Code__c, Country__c From Country_Codes__c Where Country__c =: String.escapeSingleQuotes(countryName) Limit 1];
        } if(countryList != null && countryList.size() > 0) return countryList[0].Code__c;
        else return '';
       // return null;
    }

    @AuraEnabled
    global static mainWrap Service_And_Rate_Request(List < Package__c > packList, String fromAdd, String toAdd,String fromContact,String toContact, String shipDate, String myConsVar, String Shipment, Boolean isReturnShipment){
       System.debug('Abu in Service_And_Rate_Request  isReturnShipment = ' + isReturnShipment);  // false
        mainWrap mWrap = new mainWrap();
        Map<String,UPS_Package_Type__c>  packageTypeMap = new Map<String,UPS_Package_Type__c> ();
        List <UPS_Package_Type__c> packageType = [select Id, Name, Package_Code__c, Package_Description__c from UPS_Package_Type__c limit 12];
        for(UPS_Package_Type__c upt : packageType) { packageTypeMap.put(upt.Package_Description__c, upt); }


        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);

        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);

        if(Ship.Description__c == null) Ship.Description__c = 'This is Description';
        String orderNumber = '';
        String service = '';
        string servicecode = '';
        if(packList.size() > 0){
            orderNumber = packList[0].Order__r.Name;
            if(isReturnShipment){
                if(packList[0].Logistic__c != null && String.isNotEmpty(packList[0].Logistic__c)){
                    if(packList[0].Logistic__r.Shipment_type_Return__c != null && String.isNotEmpty(packList[0].Logistic__r.Shipment_type_Return__c)){
                        if(packList[0].Logistic__r.Shipment_type_Return__c == 'UPS' && packList[0].Logistic__r.Shipping_Preferences_Return__c != null && String.isNotEmpty(packList[0].Logistic__r.Shipping_Preferences_Return__c)){
                            service = packList[0].Logistic__r.Shipping_Preferences_Return__c;
                        }
                    }
                }
            }else{
                if(packList[0].Shipment_Service_Type__c != null && packList[0].Shipment_Service_Type__c != '' && packList[0].Shipment_Service_Type__c != '') service = packList[0].Shipment_Service_Type__c;
            }
            if(String.isNotEmpty(service) && service != '--None--') {
                //Added by Arshad 18 Dec 2023 to fix issue if service has trademark symbol also scenario
                Boolean matchWithTradeMark = false;
                if(service.contains('®') || service.contains('™')) matchWithTradeMark = true;
                List<UPS_Service_Codes__c> servicecodes = new List<UPS_Service_Codes__c>();
                if(matchWithTradeMark) servicecodes = [Select Id, Service__c, Service_Code_With_Trade_Mark__c, ServiceCode__c from UPS_Service_Codes__c where Service_Code_With_Trade_Mark__c =:service limit 1];
                else servicecodes = [Select Id, Service__c, Service_Code_With_Trade_Mark__c, ServiceCode__c from UPS_Service_Codes__c where Service__c =:service limit 1];
                system.debug('servicecodes : '+servicecodes);
                if(servicecodes.size() > 0) serviceCode = servicecodes[0].ServiceCode__c;
            }
        }
        Address__c toAddress = (Address__c) JSON.deserialize(toAdd, Address__c.class);

        Address__c fromAddress = (Address__c) JSON.deserialize(fromAdd, Address__c.class);

        Contact fContact = (Contact) JSON.deserialize(fromContact, Contact.class);

        Contact tContact = (Contact) JSON.deserialize(toContact, Contact.class);
        List<rateWrap> rates= new List<rateWrap>();
        String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);
        HttpRequest req = new HttpRequest();
        String requestOption = 'Shop';
        if(serviceCode != null && serviceCode != '') requestOption = 'Rate';

        Integer toalWeightValue = 0;
        if(packList.size()>0){
            for(Package__c p : packList){
                if(p.Weight__c != null) toalWeightValue += Integer.valueof(p.Weight__c);
            }
        }

        string endpoint = myConsW.endPoint + '/api/rating/v1/'+requestOption+'?additionalinfo=';
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        if(orderNumber != null && orderNumber != '') {
            req.setHeader('TransactionSrc', orderNumber);
            req.setHeader('TransID', orderNumber);
        }
        else{
            req.setHeader('TransactionSrc', 'Testing');
            req.setHeader('TransID', 'Testing');
        }
        req.setHeader('Authorization', 'Bearer '+accesstoken);

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        gen.writeFieldName('RateRequest');
        gen.writeStartObject();
        gen.writeFieldName('Request');
        gen.writeStartObject();
        gen.writeFieldName('TransactionReference');
        gen.writeStartObject();
        gen.writeStringField('CustomerContext', 'CustomerContext');
        if(orderNumber != null && orderNumber != '') gen.writeStringField('TransactionIdentifier', orderNumber);
        else gen.writeStringField('TransactionIdentifier', 'Testing');
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('Shipment');
        gen.writeStartObject();
         boolean isreturnlabel = false;
        List<Return_Services__c> returnType = new List<Return_Services__c>();
        if(Ship.Return_Service__c != null) returnType = [select Id, Name, Return_Service_Code__c, Return_Service_Description__c from Return_Services__c where Return_Service_Description__c =: Ship.Return_Service__c limit 1];
        if(returnType.size() > 0){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code', returnType[0].Return_Service_Code__c);
            gen.writeEndObject();
        }
        else if(isReturnShipment){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code','9');
            gen.writeEndObject();

        }


        try{ if(Ship.Description__c != null) gen.writeStringField('Description', Ship.Description__c); }catch(Exception e){ system.debug('Exception occ'+e.getMessage()); }




        gen.writeFieldName('Shipper');
        gen.writeStartObject();
        if(isReturnShipment) {  if(fContact != null) gen.writeStringField('Name', fContact.Name); }
        else  gen.writeStringField('Name', myConsW.upsCredentials.Shipper_Company_Name__c);
        gen.writeStringField('ShipperNumber', myConsW.accNumber);
        gen.writeFieldName('Address');
        String originPC = getProvinceCode(fromAddress.State__c);
        String originCountryCode = getCountryCode(fromAddress.Country__c);
        if(isReturnShipment){
            gen.writeStartObject();
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
            if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
            if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
            gen.writeEndArray();
            gen.writeStringField('City', fromAddress.City__c);
            if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
            gen.writeStringField('PostalCode', fromAddress.Postal_Code__c);
            gen.writeStringField('CountryCode', originCountryCode);
            gen.writeEndObject();
        }
        else{
            gen.writeStartObject();
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            gen.writeString(myConsW.upsCredentials.Shipper_Street__c);
            gen.writeEndArray();
            gen.writeStringField('City', myConsW.upsCredentials.Shipper_City__c);
            String shipperPC = getProvinceCode(myConsW.upsCredentials.Shipper_Province__c);
            if(shipperPC != null) gen.writeStringField('StateProvinceCode', shipperPC);
            gen.writeStringField('PostalCode',myConsW.upsCredentials.Shipper_Postal_Code__c );
            String shipperCountryCode = getCountryCode(myConsW.upsCredentials.Shipper_Country__c);
            gen.writeStringField('CountryCode', shipperCountryCode);
            gen.writeEndObject();
        }
        gen.writeEndObject();
        gen.writeFieldName('ShipTo');
        gen.writeStartObject();
        gen.writeStringField('Name', tContact.Name);
        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();

        if(toAddress.Address_Line1__c != null && toAddress.Address_Line1__c != '') gen.writeString(toAddress.Address_Line1__c);
        if(toAddress.Address_Line2__c != null && toAddress.Address_Line2__c != '') gen.writeString(toAddress.Address_Line2__c);
        if(toAddress.Address_Line3__c != null && toAddress.Address_Line3__c != '') gen.writeString(toAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', toAddress.City__c);
        String destinationPC = getProvinceCode(toAddress.State__c);
        if(destinationPC != null) gen.writeStringField('StateProvinceCode', destinationPC);
        gen.writeStringField('PostalCode',toAddress.Postal_Code__c);
        String destinationCountryCode = getCountryCode(toAddress.Country__c);
        gen.writeStringField('CountryCode', destinationCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('ShipFrom');
        gen.writeStartObject();
        if(fContact != null) gen.writeStringField('Name', fContact.Name);
        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();
        if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
        if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
        if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', fromAddress.City__c);

        if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
        gen.writeStringField('PostalCode', fromAddress.Postal_Code__c);
        gen.writeStringField('CountryCode', originCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('PaymentDetails');
        gen.writeStartObject();
        gen.writeFieldName('ShipmentCharge');
        gen.writeStartObject();
        system.debug('Ship.Shipment_Billing_options__c : '+Ship.Shipment_Billing_options__c);
        if(Ship.Shipment_Billing_options__c == null || Ship.Shipment_Billing_options__c == '' || Ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('Type', '01');
        else if(Ship.Shipment_Billing_options__c == 'RECIPIENT') gen.writeStringField('Type', '03');
        else if(Ship.Shipment_Billing_options__c == 'THIRD_PARTY') gen.writeStringField('Type', '04');
        if(Ship.Shipment_Billing_options__c == null  || Ship.Shipment_Billing_options__c == '' ||  Ship.Shipment_Billing_options__c == 'SENDER'){
            gen.writeFieldName('BillShipper');
            gen.writeStartObject();
            gen.writeStringField('AccountNumber', myConsW.accNumber);
            gen.writeEndObject();
        }
        else if(Ship.Shipment_Billing_options__c == 'THIRD_PARTY'){
             gen.writeFieldName('BillThirdParty');
            gen.writeStartObject();
            if(Ship.Billing_Account_Number__c != null && Ship.Billing_Account_Number__c != '') gen.writeStringField('AccountNumber', Ship.Billing_Account_Number__c);
            if(Ship.Billing_Contact__c != null && Ship.Billing_Contact__r.Name != '') {
                gen.writeStringField('Name', Ship.Billing_Contact__r.Name);
                gen.writeStringField('AttentionName', Ship.Billing_Contact__r.Name);
            }
            gen.writeFieldName('Address');
            gen.writeStartObject();
            Address__c billAdd = new Address__c();
            String billcountrycode = '';
            string bilProvinceCode = '';
            String billStreet = '';
            if(Ship.Billing_Address__c != null){
                List<Address__c> billAddress = [Select Id,Name,Address_Line1__c,Address_Line2__c,City__c,State__c,Postal_Code__c,Country__c from Address__c where Id=:Ship.Billing_Address__c limit 1];
            	if(billAddress.size() > 0) billAdd = billAddress[0];
                if(billAdd != null){
                    if(billAdd.Country__c != null) billcountrycode = UPSRestAPI.getCountryCode(billAdd.Country__c);
                    if(billAdd.State__c != null) bilProvinceCode = UPSRestAPI.getProvinceCode(billAdd.State__c);
                    if(billAdd.Address_Line1__c != null && billAdd.Address_Line1__c != '') billStreet =  billAdd.Address_Line1__c;
                    if(billAdd.Address_Line2__c != null && billAdd.Address_Line2__c != '') billStreet += '  '+ billAdd.Address_Line2__c;
                    if(billAdd.Address_Line3__c != null && billAdd.Address_Line3__c != '') billStreet += '  '+ billAdd.Address_Line3__c;

                }

            }

            if(billStreet != null && billStreet != '' ) gen.writeStringField('AddressLine', billStreet);
            if(billAdd.City__c != null && billAdd.City__c != '') gen.writeStringField('City', billAdd.City__c);
            if(bilProvinceCode != null && bilProvinceCode != '') gen.writeStringField('StateProvinceCode', bilProvinceCode);
            if(billAdd.Postal_Code__c != null && billAdd.Postal_Code__c != '') gen.writeStringField('PostalCode', billAdd.Postal_Code__c);
            if(billcountrycode != null && billcountrycode != '') gen.writeStringField('CountryCode', billcountrycode);

            gen.writeEndObject();

            gen.writeEndObject();
        }
        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeFieldName('Service');
        gen.writeStartObject();
        if(serviceCode != null && serviceCode != '') gen.writeStringField('Code', serviceCode);
        else  gen.writeStringField('Code', '00');
        if(service != null && service != '') gen.writeStringField('Description', service);
        else gen.writeStringField('Description', 'Description');
        gen.writeEndObject();

        gen.writeFieldName('ShipmentTotalWeight');
        gen.writeStartObject();

        gen.writeFieldName('UnitOfMeasurement');
        gen.writeStartObject();
        gen.writeStringField('Code', String.valueOf(packList[0].Weight_Unit__c));
        if(packList[0].Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
        else gen.writeStringField('Description', 'Pounds' );
        gen.writeEndObject();

        gen.writeStringField('Weight', String.valueof(toalWeightValue));

        gen.writeEndObject();

        gen.writeNumberField('NumOfPieces', packList.size());

        for(Package__c p : packList){
            gen.writeFieldName('Package');

            gen.writeStartObject();
            gen.writeFieldName('PackagingType');

            gen.writeStartObject();
            gen.writeStringField('Code', packageTypeMap.get('Package').Package_Code__c);
            gen.writeStringField('Description', p.Package_Type__c);
            gen.writeEndObject();

            gen.writeFieldName('Dimensions');

            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            if(p.Weight_Unit__c == 'KGS') {
                gen.writeStringField('Code', 'CM');
                gen.writeStringField('Description', 'Centimeter');
            }
            else {
                gen.writeStringField('Code', 'IN');
                gen.writeStringField('Description', 'Inches');
            }

            gen.writeEndObject();
            gen.writeStringField('Length', String.valueof(p.Length__c));
            gen.writeStringField('Width', String.valueof(p.Width__c));
            gen.writeStringField('Height', String.valueof(p.Height__c));
            gen.writeEndObject();

            gen.writeFieldName('PackageWeight');
            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            gen.writeStringField('Code', String.valueof(p.Weight_Unit__c));
            if(p.Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
            else gen.writeStringField('Description', 'Pounds' );
            gen.writeEndObject();
            gen.writeStringField('Weight', String.valueof(p.Weight__c));
            gen.writeEndObject();

            gen.writeEndObject();
        }

        gen.writeEndObject();
        gen.writeEndObject();
        gen.writeEndObject();

        String requestBody = gen.getAsString();


        req.setBody(requestBody);

        Http http = new Http();

        String headersString = '';
        headersString += 'Content-Type: ' + req.getHeader('Content-Type') + '\n';
        headersString += 'TransactionSrc: ' + req.getHeader('TransactionSrc') + '\n';
        headersString += 'TransID: ' + req.getHeader('TransID') + '\n';
        headersString += 'Authorization: ' + req.getHeader('Authorization') + '\n';

        String requestString = 'Endpoint: ' + req.getEndpoint() + '\n'
            + 'Method: ' + req.getMethod() + '\n'
            + 'Body: ' + req.getBody()+'\n'
            +'Header : '+headersString ;


        mWrap.request = requestString;

        HttpResponse res = new HttpResponse();
        string httpResult = '';
        Decimal StatusCode = 0;
        if(Test.isRunningTest()){
            httpResult = '{ "RateResponse": { "Response": { "ResponseStatus": { "Code": "1", "Description": "Success" }, "Alert": [ { "Code": "110971", "Description": "Your invoice may vary from the displayed reference rates" } ], "TransactionReference": { "CustomerContext": "testing", "TransactionIdentifier": "ciewssoas2x1r1V0tBsVJR" } }, "RatedShipment": [ { "Service": { "Code": "07", "Description": "" }, "RatedShipmentAlert": { "Code": "110971", "Description": "Your invoice may vary from the displayed reference rates" }, "BillingWeight": { "UnitOfMeasurement": { "Code": "KGS", "Description": "Kilograms" }, "Weight": "1.0" }, "TransportationCharges": { "CurrencyCode": "GBP", "MonetaryValue": "12.99" }, "ServiceOptionsCharges": { "CurrencyCode": "GBP", "MonetaryValue": "0.00" }, "TotalCharges": { "CurrencyCode": "GBP", "MonetaryValue": "12.99" }, "RatedPackage": { "Weight": "1.0" } }, { "Service": { "Code": "11", "Description": "" }, "RatedShipmentAlert": { "Code": "110971", "Description": "Your invoice may vary from the displayed reference rates" }, "BillingWeight": { "UnitOfMeasurement": { "Code": "KGS", "Description": "Kilograms" }, "Weight": "1.0" }, "TransportationCharges": { "CurrencyCode": "GBP", "MonetaryValue": "5.99" }, "ServiceOptionsCharges": { "CurrencyCode": "GBP", "MonetaryValue": "0.00" }, "TotalCharges": { "CurrencyCode": "GBP", "MonetaryValue": "5.99" }, "RatedPackage": { "Weight": "1.0" } }, { "Service": { "Code": "54", "Description": "" }, "RatedShipmentAlert": { "Code": "110971", "Description": "Your invoice may vary from the displayed reference rates" }, "BillingWeight": { "UnitOfMeasurement": { "Code": "KGS", "Description": "Kilograms" }, "Weight": "1.0" }, "TransportationCharges": { "CurrencyCode": "GBP", "MonetaryValue": "41.89" }, "ServiceOptionsCharges": { "CurrencyCode": "GBP", "MonetaryValue": "0.00" }, "TotalCharges": { "CurrencyCode": "GBP", "MonetaryValue": "41.89" }, "RatedPackage": { "Weight": "1.0" } }, { "Service": { "Code": "65", "Description": "" }, "RatedShipmentAlert": { "Code": "110971", "Description": "Your invoice may vary from the displayed reference rates" }, "BillingWeight": { "UnitOfMeasurement": { "Code": "KGS", "Description": "Kilograms" }, "Weight": "1.0" }, "TransportationCharges": { "CurrencyCode": "GBP", "MonetaryValue": "7.99" }, "ServiceOptionsCharges": { "CurrencyCode": "GBP", "MonetaryValue": "0.00" }, "TotalCharges": { "CurrencyCode": "GBP", "MonetaryValue": "7.99" }, "RatedPackage": { "Weight": "1.0" } } ] } }';
            StatusCode = 200;
        }
        else {
            res = http.send(req);
            mWrap.response = httpResult = res.getBody();
            StatusCode = res.getStatusCode();
        }
        system.debug('StatusCode : '+StatusCode);
        system.debug(' AZ mWrap.response : '+ mWrap.response);

        if (StatusCode == 200) {
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            Map<String, Object> rateResponse = (Map<String, Object>) parsedResponse.get('RateResponse');

           // List<Object> ratedShipments = (List<Object>) rateResponse.get('RatedShipment');
            List<Object> ratedShipments = new List<Object>();
            if (rateResponse.get('RatedShipment') instanceof List<Object>) {
                ratedShipments = (List<Object>) rateResponse.get('RatedShipment');
            } else if (rateResponse.get('RatedShipment') instanceof Map<String, Object>) {
                ratedShipments.add(rateResponse.get('RatedShipment'));
            }
            List <UPS_Service_Codes__c> serviceCodes = [select Id, Name, Service__c, ServiceCode__c, Service_Code_With_Trade_Mark__c, Service_Asia_International__c, Service_Canada_Domestic__c, Service_USA_Domestic__c,
                                                        Service_Canada_International__c, Service_Europe__c, Service_Mexico_Domestic__c, Service_Mexico_International__c from UPS_Service_Codes__c limit 22];
            Map<String,UPS_Service_Codes__c> serviceCodesMap = new  Map<String,UPS_Service_Codes__c>();
            for(UPS_Service_Codes__c service1 : serviceCodes){
                serviceCodesMap.put(service1.ServiceCode__c,service1);
            }
            Integer i= 0;
            for (Object shipment1 : ratedShipments) {
                rateWrap rate = new rateWrap();
                Map<String, Object> shipmentMap = (Map<String, Object>) shipment1;
                i++;
                // Service Code
                String serviceCode1 = (String) ((Map<String, Object>) shipmentMap.get('Service')).get('Code');

                // Transportation Charges
                Map<String, Object> transportationCharges = (Map<String, Object>) shipmentMap.get('TransportationCharges');
                String transportationMonetaryValue = (String) transportationCharges.get('MonetaryValue');
                String transportationCurrencyCode = (String) transportationCharges.get('CurrencyCode');

                // Service Options Charges
                Map<String, Object> serviceOptionsCharges = (Map<String, Object>) shipmentMap.get('ServiceOptionsCharges');
                String serviceOptionsMonetaryValue = (String) serviceOptionsCharges.get('MonetaryValue');
                String serviceOptionsCurrencyCode = (String) serviceOptionsCharges.get('CurrencyCode');

                // Total Charges
                Map<String, Object> totalCharges = (Map<String, Object>) shipmentMap.get('TotalCharges');
                String totalMonetaryValue = (String) totalCharges.get('MonetaryValue');
                String totalCurrencyCode = (String) totalCharges.get('CurrencyCode');

                // Guaranteed Days To Delivery (if exists)
                String guaranteedDaysToDelivery = '';
                if (shipmentMap.containsKey('GuaranteedDaysToDelivery')) {
                    guaranteedDaysToDelivery = (String) shipmentMap.get('GuaranteedDaysToDelivery');
                }
                List<Map<String, Object>> ratedShipmentAlerts = new List<Map<String, Object>>();
                if (shipmentMap.containsKey('RatedShipmentAlert')) {
                    List<Object> alertList = new List<Object>();
                    if (shipmentMap.get('RatedShipmentAlert') instanceof List<Object>) {
                        alertList =  (List<Object>) shipmentMap.get('RatedShipmentAlert');
                    } else if (shipmentMap.get('RatedShipmentAlert') instanceof Map<String, Object>) {
                        alertList.add(shipmentMap.get('RatedShipmentAlert'));
                    }
                    for (Object alertObj : alertList) {
                        ratedShipmentAlerts.add((Map<String, Object>) alertObj);
                    }
                }
                for (Map<String, Object> alert : ratedShipmentAlerts) {
                    String alertCode = (String) alert.get('Code');
                    String alertDescription = (String) alert.get('Description');
                    System.debug('Rated Shipment Alert Code: ' + alertCode);
                    System.debug('Rated Shipment Alert Description: ' + alertDescription);
                    if (!mWrap.alertlist.contains('Alert  : ' + alertDescription)) {
                        mWrap.alertlist.add('Alert  : ' + alertDescription);
                    }
                }
                // Output the parsed values
                System.debug('Service Code: ' + serviceCode1);
                System.debug('Transportation Charges: ' + transportationMonetaryValue + ' ' + transportationCurrencyCode);
                System.debug('Service Options Charges: ' + serviceOptionsMonetaryValue + ' ' + serviceOptionsCurrencyCode);
                System.debug('Total Charges: ' + totalMonetaryValue + ' ' + totalCurrencyCode);
                System.debug('Guaranteed Days To Delivery: ' + guaranteedDaysToDelivery);
                rate.code = serviceCode1;
                rate.countNum = i;
                rate.service = serviceCodesMap.containsKey(serviceCode1) ? serviceCodesMap.get(serviceCode1).Service__c : '';
                rate.totalCharges = Decimal.valueOf(totalMonetaryValue);
                rate.currencycode = totalCurrencyCode;
                rate.serviceCharges = Decimal.valueOf(serviceOptionsMonetaryValue);
                rate.deliverydate = guaranteedDaysToDelivery;
                rates.add(rate);
            }
        }
        else {
            // Error
            String error = 'Error : '+res.getStatus()+' code : '+res.getStatusCode();
            mWrap.error = error;
        }
        if(rates.size() > 0) mWrap.ratesList = rates;
        else  mWrap.error =  'Rate Service is Not available : Request To Service & Rate Shipment Cannot Be Processed';
        return mWrap;
       // return null;
    }

    @AuraEnabled
     global static Wrapper Shipping_Request_Response(List < Package__c > packList,String fromAdd, String toAdd,String fromContact,String toContact, String shipDate, String myConsVar, String Shipment, Boolean isReturnShipment,List<Package_List__c> packageItems,String service,String serviceCode,String currencyCode,String masterShipmentId){
         System.debug('By Abu IsReturnShipment = ' + isReturnShipment); // false
        Wrapper mWrap = new Wrapper();
        String orderNumber = 'Testing';
        Map<String,UPS_Package_Type__c>  packageTypeMap = new Map<String,UPS_Package_Type__c> ();
        List <UPS_Package_Type__c> packageType = [select Id, Name, Package_Code__c, Package_Description__c from UPS_Package_Type__c limit 12];
        for(UPS_Package_Type__c upt : packageType) { packageTypeMap.put(upt.Package_Description__c, upt); }


        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);

        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);

        if(Ship.Description__c == null) Ship.Description__c = 'This is Description';

        if(packList.size() > 0){
           if(packList[0].Order__c != null) orderNumber = packList[0].Order__r.Name;

        }
        Address__c toAddress = (Address__c) JSON.deserialize(toAdd, Address__c.class);

        Address__c fromAddress = (Address__c) JSON.deserialize(fromAdd, Address__c.class);

        Contact fContact = (Contact) JSON.deserialize(fromContact, Contact.class);

        Contact tContact = (Contact) JSON.deserialize(toContact, Contact.class);
        List<rateWrap> rates= new List<rateWrap>();
        String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);
        HttpRequest req = new HttpRequest();
        String requestOption = 'Shop';
        if(serviceCode != null && serviceCode != '') requestOption = 'Rate';

        Integer toalWeightValue = 0;
        if(packList.size()>0){
            for(Package__c p : packList){
                if(p.Weight__c != null) toalWeightValue += Integer.valueof(p.Weight__c);
            }
        }

        string endpoint = myConsW.endPoint + '/api/shipments/v1/ship';
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        req.setHeader('TransactionSrc', orderNumber);
        req.setHeader('TransID', orderNumber);
        req.setHeader('Authorization', 'Bearer '+accesstoken);

        // Create JSONGenerator instance
        JSONGenerator gen = JSON.createGenerator(true);

        // Start outermost object
        gen.writeStartObject();

        // Start "ShipmentRequest" object
        gen.writeFieldName('ShipmentRequest');
        gen.writeStartObject();

        // Start "Request" object
        gen.writeFieldName('Request');
        gen.writeStartObject();
        gen.writeStringField('SubVersion', '1801');
        gen.writeStringField('RequestOption', 'nonvalidate');

        // Start "TransactionReference" object
        gen.writeFieldName('TransactionReference');
        gen.writeStartObject();
        gen.writeStringField('CustomerContext', 'orderNumber');
        gen.writeEndObject(); // End "TransactionReference" object

        gen.writeEndObject(); // End "Request" object

        // Start "Shipment" object
        gen.writeFieldName('Shipment');
        gen.writeStartObject();
         boolean isreturnlabel = false;
        List<Return_Services__c> returnType = new List<Return_Services__c>();
        if(Ship.Return_Service__c != null) returnType = [select Id, Name, Return_Service_Code__c, Return_Service_Description__c from Return_Services__c where Return_Service_Description__c =: Ship.Return_Service__c limit 1];
        if(returnType.size() > 0){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code', returnType[0].Return_Service_Code__c);
            gen.writeEndObject();
        }
        else if(isReturnShipment){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code','9');
            gen.writeEndObject();

        }
        try{ if(Ship.Description__c != null) gen.writeStringField('Description', Ship.Description__c); }catch(Exception e){ system.debug('Exception occ'+e.getMessage()); }


        // Start "Shipper" object
        gen.writeFieldName('Shipper');
        gen.writeStartObject();
        if(isReturnShipment) {
            if(fContact != null) {
                if(fContact.Account.Name != '' && fContact.Account.Name != null) gen.writeStringField('Name', fContact.Account.Name);
                if(fContact.Name != '' && fContact.Name != null) gen.writeStringField('AttentionName', fContact.Name);
                gen.writeFieldName('Phone');
                gen.writeStartObject();
                if(fContact.Phone != '' && fContact.Phone != null) gen.writeStringField('Number', fContact.Phone);
                gen.writeEndObject();
            }
        }
        else {
            gen.writeStringField('Name', myConsW.upsCredentials.Shipper_Company_Name__c);
            gen.writeStringField('AttentionName', myConsW.upsCredentials.Shipper_Name__c);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            gen.writeStringField('Number', myConsW.upsCredentials.Shipper_Phone_Number__c);
            gen.writeEndObject(); // End "Phone" object for Shipper
        }
        gen.writeStringField('ShipperNumber', myConsW.accNumber);
        // gen.writeStringField('FaxNumber', '8002222222');

        // Start "Address" object for Shipper
        gen.writeFieldName('Address');
        gen.writeStartObject();
        String shipperPC = getProvinceCode(myConsW.upsCredentials.Shipper_Province__c);
        String shipperCountryCode = getCountryCode(myConsW.upsCredentials.Shipper_Country__c);
        String originPC = getProvinceCode(fromAddress.State__c);
        String originCountryCode = getCountryCode(fromAddress.Country__c);
        if(isReturnShipment){
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
            if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
            if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
            gen.writeEndArray();
            gen.writeStringField('City', fromAddress.City__c);
            if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
            gen.writeStringField('PostalCode', fromAddress.Postal_Code__c );
            gen.writeStringField('CountryCode', originCountryCode);
        }
        else{
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            gen.writeString(myConsW.upsCredentials.Shipper_Street__c);
            gen.writeEndArray();
            gen.writeStringField('City', myConsW.upsCredentials.Shipper_City__c);
            if(shipperPC != null) gen.writeStringField('StateProvinceCode', shipperPC);
            gen.writeStringField('PostalCode', myConsW.upsCredentials.Shipper_Postal_Code__c );
            gen.writeStringField('CountryCode', shipperCountryCode);
        }

        gen.writeEndObject(); // End "Address" object for Shipper

        gen.writeEndObject(); // End "Shipper" object

        // ShipTo
        gen.writeFieldName('ShipTo');
        gen.writeStartObject();
        if(isReturnShipment) {
            gen.writeStringField('Name', tContact.Account.Name);
            gen.writeStringField('AttentionName', tContact.Name);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            if(tContact.Phone != null && tContact.Phone != '') gen.writeStringField('Number', tContact.Phone);
            gen.writeEndObject(); // Phone
        }
        else{
            gen.writeStringField('Name', tContact.Account.Name);
            gen.writeStringField('AttentionName', tContact.Name);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            if(tContact.Phone != null && tContact.Phone != '') gen.writeStringField('Number', tContact.Phone);
            gen.writeEndObject(); // Phone
        }


        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();

        if(toAddress.Address_Line1__c != null && toAddress.Address_Line1__c != '') gen.writeString(toAddress.Address_Line1__c);
        if(toAddress.Address_Line2__c != null && toAddress.Address_Line2__c != '') gen.writeString(toAddress.Address_Line2__c);
        if(toAddress.Address_Line3__c != null && toAddress.Address_Line3__c != '') gen.writeString(toAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', toAddress.City__c);
        String destinationPC = getProvinceCode(toAddress.State__c);
        if(destinationPC != null) gen.writeStringField('StateProvinceCode', destinationPC);
        gen.writeStringField('PostalCode',toAddress.Postal_Code__c);

        String destinationCountryCode = getCountryCode(toAddress.Country__c);
        gen.writeStringField('CountryCode', destinationCountryCode);
        gen.writeEndObject(); // Address
        gen.writeStringField('Residential', ' ');
        gen.writeEndObject(); // ShipTo

        // Ship from
        gen.writeFieldName('ShipFrom');
        gen.writeStartObject();
        gen.writeStringField('Name', fContact.Account.Name);
        gen.writeStringField('AttentionName', fContact.Name);
        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();
        if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
        if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
        if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', fromAddress.City__c);

        if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
        gen.writeStringField('PostalCode', fromAddress.Postal_Code__c);

        gen.writeStringField('CountryCode', originCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();

        gen.writeFieldName('PaymentInformation');
        gen.writeStartObject();
        gen.writeFieldName('ShipmentCharge');
        gen.writeStartObject();
        if(Ship.Shipment_Billing_options__c == null || Ship.Shipment_Billing_options__c == '' || Ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('Type', '01');
        else if(Ship.Shipment_Billing_options__c == 'RECIPIENT') gen.writeStringField('Type', '03');
        else if(Ship.Shipment_Billing_options__c == 'THIRD_PARTY') gen.writeStringField('Type', '04');
        if(Ship.Shipment_Billing_options__c == null || Ship.Shipment_Billing_options__c == '' || Ship.Shipment_Billing_options__c == 'SENDER'){
            gen.writeFieldName('BillShipper');
            gen.writeStartObject();
            gen.writeStringField('AccountNumber', myConsW.accNumber);
            gen.writeEndObject();
        }
        gen.writeEndObject();
        gen.writeEndObject();

        //Service
        gen.writeFieldName('Service');
        gen.writeStartObject();
        //serviceCode = '07';
        if(serviceCode != null && serviceCode != '') gen.writeStringField('Code', serviceCode);
        else  gen.writeStringField('Code', '00');
        if(service != null && service != '') gen.writeStringField('Description', service);
        else gen.writeStringField('Description', 'Description');
        gen.writeEndObject();

        gen.writeFieldName('ShipmentTotalWeight');
        gen.writeStartObject();

        gen.writeFieldName('UnitOfMeasurement');
        gen.writeStartObject();
        gen.writeStringField('Code', String.valueOf(packList[0].Weight_Unit__c));
        if(packList[0].Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
        else gen.writeStringField('Description', 'Pounds' );
        gen.writeEndObject();

        gen.writeStringField('Weight', String.valueof(toalWeightValue));

        gen.writeEndObject();

        gen.writeNumberField('NumOfPieces', packList.size());

        //package details
        for(Package__c p : packList){
            gen.writeFieldName('Package');

            gen.writeStartObject();
            gen.writeStringField('Description', p.Name);
            gen.writeFieldName('Packaging');

            gen.writeStartObject();
            gen.writeStringField('Code', packageTypeMap.get('Package').Package_Code__c);
            gen.writeStringField('Description', p.Package_Type__c);
            gen.writeEndObject();

            gen.writeFieldName('Dimensions');

            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            if(p.Weight_Unit__c == 'KGS') {
                gen.writeStringField('Code', 'CM');
                gen.writeStringField('Description', 'Centimeter');
            }
            else {
                gen.writeStringField('Code', 'IN');
                gen.writeStringField('Description', 'Inches');
            }

            gen.writeEndObject();
            gen.writeStringField('Length', String.valueof(p.Length__c));
            gen.writeStringField('Width', String.valueof(p.Width__c));
            gen.writeStringField('Height', String.valueof(p.Height__c));
            gen.writeEndObject();

            gen.writeFieldName('PackageWeight');
            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            gen.writeStringField('Code', String.valueof(p.Weight_Unit__c));
            if(p.Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
            else gen.writeStringField('Description', 'Pounds' );
            gen.writeEndObject();
            gen.writeStringField('Weight', String.valueof(p.Weight__c));
            gen.writeEndObject();

            gen.writeEndObject();
        }


        // End "Shipment" object
        gen.writeEndObject();

        // Start "LabelSpecification" object
        gen.writeFieldName('LabelSpecification');
        gen.writeStartObject();
        gen.writeFieldName('LabelImageFormat');
        gen.writeStartObject();
        gen.writeStringField('Code', 'GIF');
        gen.writeStringField('Description', 'GIF');
        gen.writeEndObject(); // End "LabelImageFormat" object
        // gen.writeStringField('HTTPUserAgent', 'Mozilla/4.5');
        gen.writeEndObject(); // End "LabelSpecification" object

        // End "ShipmentRequest" object
        gen.writeEndObject();

        // End outermost object
        gen.writeEndObject();

        // Get the JSON string
        String jsonString = gen.getAsString();

        // Print the JSON string
        System.debug(jsonString);
        String requestBody = gen.getAsString();


        req.setBody(requestBody);

        Http http = new Http();

        String headersString = '';
        headersString += 'Content-Type: ' + req.getHeader('Content-Type') + '\n';
        headersString += 'TransactionSrc: ' + req.getHeader('TransactionSrc') + '\n';
        headersString += 'TransID: ' + req.getHeader('TransID') + '\n';
        headersString += 'Authorization: ' + req.getHeader('Authorization') + '\n';

        String requestString = 'Endpoint: ' + req.getEndpoint() + '\n'
            + 'Method: ' + req.getMethod() + '\n'
            + 'Body: ' + req.getBody()+'\n'
            +'Header : '+headersString ;


        mWrap.request = requestString;

        HttpResponse res = new HttpResponse();
        string httpResult = '';
        Decimal StatusCode = 0;
        if(Test.isRunningTest()){
            httpResult = '{"ShipmentResponse":{"Response":{"ResponseStatus":{"Code":"1","Description":"Success"},"TransactionReference":{"CustomerContext":"00001267","TransactionIdentifier":"ciewssoat5B283qSqLs2wL"}},"ShipmentResults":{"ShipmentCharges":{"BaseServiceCharge":{"CurrencyCode":"INR","MonetaryValue":"4146.00"},"TransportationCharges":{"CurrencyCode":"INR","MonetaryValue":"5385.44"},"ItemizedCharges":[{"Code":"375","CurrencyCode":"INR","MonetaryValue":"1194.44"},{"Code":"430","CurrencyCode":"INR","MonetaryValue":"45.00","SubType":"Commercial_Seasonal_Surcharge"}],"ServiceOptionsCharges":{"CurrencyCode":"INR","MonetaryValue":"0.00"},"TotalCharges":{"CurrencyCode":"INR","MonetaryValue":"5385.44"}},"BillingWeight":{"UnitOfMeasurement":{"Code":"KGS","Description":"Kilograms"},"Weight":"1.0"},"ShipmentIdentificationNumber":"1ZXXXXXXXXXXXXXXXX","PackageResults":{"TrackingNumber":"1ZXXXXXXXXXXXXXXXX","ServiceOptionsCharges":{"CurrencyCode":"INR","MonetaryValue":"0.00"},"ShippingLabel":{"ImageFormat":{"Code":"GIF","Description":"GIF"},"GraphicImage":"R0lGODlheAUgA/cAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4ODg8PDx"}}}}}';

            StatusCode = 200;
        }
        else {
            res = http.send(req);
            mWrap.response = httpResult = res.getBody();
            StatusCode = res.getStatusCode();
        }
        system.debug('StatusCode : '+StatusCode);
        if(StatusCode == 200){
            //JSONParser parser = JSON.createParser(httpResult);

            // Variables to hold the extracted values


                   // Parse the JSON string
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(httpResult);

            // Debug the data structure
            System.debug('Data: ' + data);

            // Extract the fields
            Map<String, Object> shipmentResponse = (Map<String, Object>) data.get('ShipmentResponse');
            System.debug('Shipment Response: ' + shipmentResponse);

            Map<String, Object> shipmentResults = new Map<String, Object>();
            if (shipmentResponse != null) {
                shipmentResults = (Map<String, Object>) shipmentResponse.get('ShipmentResults');
            }
            System.debug('Shipment Results: ' + shipmentResults);

            String shipmentIdentificationNumber = '';
            if (shipmentResults != null) {
                shipmentIdentificationNumber = (String) shipmentResults.get('ShipmentIdentificationNumber');
            }
            System.debug('Shipment Identification Number: ' + shipmentIdentificationNumber);

            Map<String, Object> shipmentCharges = new Map<String, Object>();
            Map<String, Object> totalCharges = new Map<String, Object>();
            if (shipmentResults != null) {
                shipmentCharges = (Map<String, Object>) shipmentResults.get('ShipmentCharges');
                totalCharges = (Map<String, Object>) shipmentCharges.get('TotalCharges');
            }
            System.debug('Shipment Charges: ' + shipmentCharges);
            System.debug('Total Charges: ' + totalCharges);

            String totalChargesCurrencyCode = '';
            Decimal totalChargesMonetaryValue = 0;
            if (totalCharges != null) {
                totalChargesCurrencyCode = (String) totalCharges.get('CurrencyCode');
                totalChargesMonetaryValue = Decimal.valueOf((String) totalCharges.get('MonetaryValue'));
            }
            System.debug('Total Charges Currency Code: ' + totalChargesCurrencyCode);
            System.debug('Total Charges Monetary Value: ' + totalChargesMonetaryValue);

            Map<String, Object> packageResults = new Map<String, Object>();
            if (shipmentResults != null) {
                packageResults = (Map<String, Object>) shipmentResults.get('PackageResults');
            }
            System.debug('Package Results: ' + packageResults);

            String trackingNumber = '';
            List<String> graphicImage = new List<String>();
            if (packageResults != null) {
                trackingNumber = (String) packageResults.get('TrackingNumber');
                Map<String, Object> shippingLabel = (Map<String, Object>) packageResults.get('ShippingLabel');
                System.debug('Shipping Label: ' + shippingLabel);
                if (shippingLabel != null) {
                    Map<String, Object> imageFormat = (Map<String, Object>) shippingLabel.get('ImageFormat');
                    System.debug('Image Format: ' + imageFormat);
                    if (imageFormat != null) {
                        String imageFormatCode = (String) imageFormat.get('Code');
                        String graphicImageValue = (String) shippingLabel.get('GraphicImage');
                        graphicImage.add(graphicImageValue);
                    }
                }
            }

            // Debug the extracted fields
            System.debug('Tracking Number: ' + trackingNumber);
            System.debug('Graphic Image: ' + graphicImage);




            if(totalChargesMonetaryValue != null){
                Id RTID; RTID = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('UPS_Shipping').getRecordTypeId();
                if(isReturnShipment && String.isNotEmpty(masterShipmentId)){
                    Ship.Id = null;
                    Ship.Master_Shipment__c = masterShipmentId;
                    Ship.Return_Shipment__c = true;
                }
                Ship.Active__c = true;
                if(fromAddress.Id != null && Ship.Shipment_Billing_options__c != null && String.isNotEmpty(Ship.Shipment_Billing_options__c) && Ship.Shipment_Billing_options__c == 'SENDER'){
                    Ship.Billing_Address__c = fromAddress.Id;
                }else if(toAddress.Id != null) Ship.Billing_Address__c = toAddress.Id;
                Ship.Customer__c = toAddress.Customer__c;
                Ship.Customer_Contact__c = tContact.Id;
                Ship.Status__c = 'Shipped';
                Ship.RecordTypeId = RTID;
                Ship.Shipping_Address__c = toAddress.Id;
                if(packList[0].Logistic__c != null && packList[0].Logistic__r.Billing_options__c != null) Ship.Shipment_Billing_options__c = packList[0].Logistic__r.Billing_options__c;
                Ship.Logistic__c = packList[0].Logistic__c;
                Ship.Package__c= packList[0].Id;
                Ship.Order__c = packList[0].Order__c;
                Ship.Shipment_Identification_Number__c = ShipmentIdentificationNumber;
                Ship.TrackingNumber__c = trackingNumber;
                Ship.UPS_Services__c = service;
                Ship.Shipping_Amount__c = totalChargesMonetaryValue;
                ship.UPS_Service_Code__c = serviceCode;
                Ship.Package_Weight__c = toalWeightValue;

                decimal totalPackQty = 0;
                for(Package__c pK : packList) {
                    if(pK.Package_Quantity__c != null) totalPackQty += pK.Package_Quantity__c;
                }
                if(Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isUpdateable())  Ship.Total_Package_items__c = totalPackQty;       if(Schema.sObjectType.Shipment__c.fields.Number_Of_Pieces_In_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Number_Of_Pieces_In_Shipment__c.isUpdateable()) Ship.Number_Of_Pieces_In_Shipment__c = String.valueof(packList.size());
                if(Schema.sObjectType.Shipment__c.fields.Master_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Master_Shipment__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Return_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Return_Shipment__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Active__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Customer__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Customer__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Customer_Contact__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Customer_Contact__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Shipment__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Order__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Order__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipment_Identification_Number__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipment_Identification_Number__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.TrackingNumber__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.TrackingNumber__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.UPS_Services__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.UPS_Services__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Amount__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Amount__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.UPS_Service_Code__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.UPS_Service_Code__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Package_Weight__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Package_Weight__c.isUpdateable()) {
                                      // upsert ship;
                                    //   System.SObjectAccessDecision securityDecisionA2 = Security.stripInaccessible(AccessType.UPDATABLE, new List<Shipment__c>{ship});
                                    //   List<SObject> accessibleVersionsA2 = securityDecisionA2.getRecords();

                                    //   if (!accessibleVersionsA2.isEmpty()) {
                                    //       // Perform the insert operation with the accessible version
                                    //       upsert accessibleVersionsA2[0];
                                    //       Ship.Id = accessibleVersionsA2[0].Id;
                                    //   } else {
                                    //       // Handle the case where FLS validation fails
                                    //       // You may log an error, throw an exception, or perform other appropriate actions
                                    //   }
                                    //for fls
                                    // upsert ship;
                                    List<SObject> safeships = FLSHelper.getSafeRecords(
                                                new List<Shipment__c>{ship},
                                                'Shipment__c',
                                                AccessType.UPDATABLE
                                            );
                                            List<Shipment__c> typedships = new List<Shipment__c>();
                                            for (SObject s : safeships) {
                                                typedships.add((Shipment__c)s);
                                            }
                                            if (!typedships.isEmpty()) {
                                                upsert typedships; // or insert/update as needed
                                                Ship.Id = typedships[0].Id;
                                            }
                    List<SObject> sObjects = new List<SObject>{ship};
                    List<Shipment__c> shipment2upsert = (List<Shipment__c>)Security.stripInaccessible(AccessType.UPSERTABLE, sObjects).getRecords();
                    //if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) upsert shipment2upsert;

                }

                List<attachment> attList = new List<attachment>();
                // upsW.noOfimgs = graphicImage.size();
                attachment att = new attachment();
                System.debug('shid id=>'+Ship.Id);
                if(graphicImage.size() > 0){
                    for(Integer i=1; i<=graphicImage.size(); i++){
                        att = new attachment();
                        if(Schema.sObjectType.attachment.fields.Name.isCreateable() && Schema.sObjectType.attachment.fields.Name.isUpdateable()) att.Name = 'UPS_Label_'+i;
                        if(Schema.sObjectType.attachment.fields.parentId.isCreateable() || Schema.sObjectType.attachment.fields.parentId.isUpdateable()) att.parentId = Ship.Id;
                        if(Schema.sObjectType.attachment.fields.ContentType.isCreateable() && Schema.sObjectType.attachment.fields.ContentType.isUpdateable()) att.ContentType = 'image/gif';
                        if(Schema.sObjectType.attachment.fields.body.isCreateable() && Schema.sObjectType.attachment.fields.body.isUpdateable()) { att.body = EncodingUtil.base64Decode(graphicImage[i-1]); }
                        attList.add(att);
                    }
                }
                if(attList.size() > 0) insert attList;
                mWrap.AttachList = attList;
                mWrap.shipment = Ship;
                if(!isReturnShipment){
                    for(Integer i=0; i<packList.size(); i++) {
                        if(Schema.sObjectType.Package__c.fields.Shipment__c.isCreateable() && Schema.sObjectType.Package__c.fields.Shipment__c.isUpdateable()) packList[i].Shipment__c = Ship.Id;
                        if(Schema.sObjectType.Package__c.fields.Status__c.isCreateable() && Schema.sObjectType.Package__c.fields.Status__c.isUpdateable()) packList[i].Status__c = Ship.Status__c;
                        if(trackingNumber != null && trackingNumber != '') if(Schema.sObjectType.Package__c.fields.Tracking_Number__c.isCreateable() && Schema.sObjectType.Package__c.fields.Tracking_Number__c.isUpdateable()) packList[i].Tracking_Number__c = trackingNumber;
                    }

                    if(packList.size() > 0 && Schema.SObjectType.Package__c.isCreateable() && Schema.SObjectType.Package__c.isUpdateable()){
                        //if(Schema.sObjectType.Package__c.isCreateable() && Schema.sObjectType.Package__c.isUpdateable()){
                        PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false;
                        PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false;
                        PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false;
                        PreventRecursiveLedgerEntry.SOLI_AllocateStock = false;
                        PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false;
                        upsert packList;
                    }

                }

            }
            else{

                mWrap.error = 'Error: No amount is applied';
            }
        }
        else{
            System.debug('Error: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
            mWrap.error = 'Error: ' + res.getStatus()+'Response: ' + res.getBody();
        }
        return mWrap;
       // return null;
    }
      @AuraEnabled
      global static Wrapper Shipping_Request_Response_rma(List < Package__c > packList,String fromAdd, String toAdd,String fromContact,String toContact, String shipDate, String myConsVar, String Shipment, Boolean isReturnShipment,String service,String serviceCode,String currencyCode,String masterShipmentId, String rmaid){
       System.debug('By Abu in shipRMA IsReturnShipment = ' + isReturnShipment);
        Wrapper mWrap = new Wrapper();
        String orderNumber = 'Testing';
        Map<String,UPS_Package_Type__c>  packageTypeMap = new Map<String,UPS_Package_Type__c> ();
        List <UPS_Package_Type__c> packageType = [select Id, Name, Package_Code__c, Package_Description__c from UPS_Package_Type__c limit 12];
        for(UPS_Package_Type__c upt : packageType) { packageTypeMap.put(upt.Package_Description__c, upt); }


        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);

        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
        if(packList.size() > 0){
           if(packList[0].Order__c != null) orderNumber = packList[0].Order__r.Name;
           System.debug('orderNumber: '+orderNumber);

        }
        Address__c toAddress = (Address__c) JSON.deserialize(toAdd, Address__c.class);

        Address__c fromAddress = (Address__c) JSON.deserialize(fromAdd, Address__c.class);

        Contact fContact = (Contact) JSON.deserialize(fromContact, Contact.class);

        Contact tContact = (Contact) JSON.deserialize(toContact, Contact.class);
        List<rateWrap> rates= new List<rateWrap>();
        String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);
        HttpRequest req = new HttpRequest();
        String requestOption = 'Shop';
        if(serviceCode != null && serviceCode != '') requestOption = 'Rate';
        system.debug('serviceCode in ups-----> '+serviceCode);

        Integer toalWeightValue = 0;
        if(packList.size()>0){
            for(Package__c p : packList){
                if(p.Weight__c != null) toalWeightValue += Integer.valueof(p.Weight__c);
            }
        }

        string endpoint = myConsW.endPoint + '/api/shipments/v1/ship';
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        req.setHeader('TransactionSrc', orderNumber);
        req.setHeader('TransID', orderNumber);
        req.setHeader('Authorization', 'Bearer '+accesstoken);

        // Create JSONGenerator instance
        JSONGenerator gen = JSON.createGenerator(true);

        // Start outermost object
        gen.writeStartObject();

        // Start "ShipmentRequest" object
        gen.writeFieldName('ShipmentRequest');
        gen.writeStartObject();

        // Start "Request" object
        gen.writeFieldName('Request');
        gen.writeStartObject();
        gen.writeStringField('SubVersion', '1801');
        gen.writeStringField('RequestOption', 'nonvalidate');

        // Start "TransactionReference" object
        gen.writeFieldName('TransactionReference');
        gen.writeStartObject();
        gen.writeStringField('CustomerContext', 'orderNumber');
        gen.writeEndObject(); // End "TransactionReference" object

        gen.writeEndObject(); // End "Request" object

        // Start "Shipment" object
        gen.writeFieldName('Shipment');
        gen.writeStartObject();
         boolean isreturnlabel = false;
        List<Return_Services__c> returnType = new List<Return_Services__c>();
        if(Ship.Return_Service__c != null) returnType = [select Id, Name, Return_Service_Code__c, Return_Service_Description__c from Return_Services__c where Return_Service_Description__c =: Ship.Return_Service__c limit 1];
        if(returnType.size() > 0){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code', returnType[0].Return_Service_Code__c);
            gen.writeEndObject();
        }
        else if(isReturnShipment){
            isreturnlabel = true;
            gen.writeFieldName('ReturnService');
            gen.writeStartObject();
            gen.writeStringField('Code','9');
            gen.writeEndObject();

        }
        try{ if(Ship.Description__c != null) gen.writeStringField('Description', Ship.Description__c); }catch(Exception e){ system.debug('Exception occ'+e.getMessage()); }


        // Start "Shipper" object
        gen.writeFieldName('Shipper');
        gen.writeStartObject();
        if(isReturnShipment) {
            if(fContact != null) {
                if(fContact.Account.Name != '' && fContact.Account.Name != null) gen.writeStringField('Name', fContact.Account.Name);
                if(fContact.Name != '' && fContact.Name != null) gen.writeStringField('AttentionName', fContact.Name);
                gen.writeFieldName('Phone');
                gen.writeStartObject();
                if(fContact.Phone != '' && fContact.Phone != null) gen.writeStringField('Number', fContact.Phone);
                gen.writeEndObject();
            }
        }
        else {
            gen.writeStringField('Name', myConsW.upsCredentials.Shipper_Company_Name__c);
            gen.writeStringField('AttentionName', myConsW.upsCredentials.Shipper_Name__c);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            gen.writeStringField('Number', myConsW.upsCredentials.Shipper_Phone_Number__c);
            gen.writeEndObject(); // End "Phone" object for Shipper
        }
        gen.writeStringField('ShipperNumber', myConsW.accNumber);
        // gen.writeStringField('FaxNumber', '8002222222');

        // Start "Address" object for Shipper
        gen.writeFieldName('Address');
        gen.writeStartObject();
        String shipperPC = getProvinceCode(myConsW.upsCredentials.Shipper_Province__c);
        String shipperCountryCode = getCountryCode(myConsW.upsCredentials.Shipper_Country__c);
        String originPC = getProvinceCode(fromAddress.State__c);
        String originCountryCode = getCountryCode(fromAddress.Country__c);
        if(isReturnShipment){
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
            if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
            if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
            gen.writeEndArray();
            gen.writeStringField('City', fromAddress.City__c);
            if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
            gen.writeStringField('PostalCode', fromAddress.Postal_Code__c );
            gen.writeStringField('CountryCode', originCountryCode);
        }
        else{
            gen.writeFieldName('AddressLine');
            gen.writeStartArray();
            gen.writeString(myConsW.upsCredentials.Shipper_Street__c);
            gen.writeEndArray();
            gen.writeStringField('City', myConsW.upsCredentials.Shipper_City__c);
            if(shipperPC != null) gen.writeStringField('StateProvinceCode', shipperPC);
            gen.writeStringField('PostalCode', myConsW.upsCredentials.Shipper_Postal_Code__c );
            gen.writeStringField('CountryCode', shipperCountryCode);
        }

        gen.writeEndObject(); // End "Address" object for Shipper

        gen.writeEndObject(); // End "Shipper" object

        // ShipTo
        gen.writeFieldName('ShipTo');
        gen.writeStartObject();
        if(isReturnShipment) {
            gen.writeStringField('Name', tContact.Account.Name);
            gen.writeStringField('AttentionName', tContact.Name);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            if(tContact.Phone != null && tContact.Phone != '') gen.writeStringField('Number', tContact.Phone);
            gen.writeEndObject(); // Phone
        }
        else{
            gen.writeStringField('Name', tContact.Account.Name);
            gen.writeStringField('AttentionName', tContact.Name);
            gen.writeFieldName('Phone');
            gen.writeStartObject();
            if(tContact.Phone != null && tContact.Phone != '') gen.writeStringField('Number', tContact.Phone);
            gen.writeEndObject(); // Phone
        }


        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();

        if(toAddress.Address_Line1__c != null && toAddress.Address_Line1__c != '') gen.writeString(toAddress.Address_Line1__c);
        if(toAddress.Address_Line2__c != null && toAddress.Address_Line2__c != '') gen.writeString(toAddress.Address_Line2__c);
        if(toAddress.Address_Line3__c != null && toAddress.Address_Line3__c != '') gen.writeString(toAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', toAddress.City__c);
        String destinationPC = getProvinceCode(toAddress.State__c);
        if(destinationPC != null) gen.writeStringField('StateProvinceCode', destinationPC);
        gen.writeStringField('PostalCode',toAddress.Postal_Code__c);

        String destinationCountryCode = getCountryCode(toAddress.Country__c);
        gen.writeStringField('CountryCode', destinationCountryCode);
        gen.writeEndObject(); // Address
        gen.writeStringField('Residential', ' ');
        gen.writeEndObject(); // ShipTo

        // Ship from
        gen.writeFieldName('ShipFrom');
        gen.writeStartObject();
        gen.writeStringField('Name', fContact.Account.Name);
        gen.writeStringField('AttentionName', fContact.Name);
        gen.writeFieldName('Address');
        gen.writeStartObject();
        gen.writeFieldName('AddressLine');
        gen.writeStartArray();
        if(fromAddress.Address_Line1__c != null && fromAddress.Address_Line1__c != '') gen.writeString(fromAddress.Address_Line1__c);
        if(fromAddress.Address_Line2__c != null && fromAddress.Address_Line2__c != '') gen.writeString(fromAddress.Address_Line2__c);
        if(fromAddress.Address_Line3__c != null && fromAddress.Address_Line3__c != '') gen.writeString(fromAddress.Address_Line3__c);
        gen.writeEndArray();
        gen.writeStringField('City', fromAddress.City__c);

        if(originPC != null) gen.writeStringField('StateProvinceCode', originPC);
        gen.writeStringField('PostalCode', fromAddress.Postal_Code__c);

        gen.writeStringField('CountryCode', originCountryCode);
        gen.writeEndObject();
        gen.writeEndObject();

        gen.writeFieldName('PaymentInformation');
        gen.writeStartObject();
        gen.writeFieldName('ShipmentCharge');
        gen.writeStartObject();
        if(Ship.Shipment_Billing_options__c == null || Ship.Shipment_Billing_options__c == '' || Ship.Shipment_Billing_options__c == 'SENDER') gen.writeStringField('Type', '01');
        else if(Ship.Shipment_Billing_options__c == 'RECIPIENT') gen.writeStringField('Type', '03');
        else if(Ship.Shipment_Billing_options__c == 'THIRD_PARTY') gen.writeStringField('Type', '04');
        if(Ship.Shipment_Billing_options__c == null || Ship.Shipment_Billing_options__c == '' || Ship.Shipment_Billing_options__c == 'SENDER'){
            gen.writeFieldName('BillShipper');
            gen.writeStartObject();
            gen.writeStringField('AccountNumber', myConsW.accNumber);
            gen.writeEndObject();
        }
        gen.writeEndObject();
        gen.writeEndObject();

        //Service
        gen.writeFieldName('Service');
        gen.writeStartObject();
        //serviceCode = '07';
        if(serviceCode != null && serviceCode != '') gen.writeStringField('Code', serviceCode);
        else  gen.writeStringField('Code', '00');
        if(service != null && service != '') gen.writeStringField('Description', service);
        else gen.writeStringField('Description', 'Description');
        gen.writeEndObject();

        gen.writeFieldName('ShipmentTotalWeight');
        gen.writeStartObject();

        gen.writeFieldName('UnitOfMeasurement');
        gen.writeStartObject();
        gen.writeStringField('Code', String.valueOf(packList[0].Weight_Unit__c));
        if(packList[0].Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
        else gen.writeStringField('Description', 'Pounds' );
        gen.writeEndObject();

        gen.writeStringField('Weight', String.valueof(toalWeightValue));

        gen.writeEndObject();

        gen.writeNumberField('NumOfPieces', packList.size());

        //package details
        for(Package__c p : packList){
            gen.writeFieldName('Package');

            gen.writeStartObject();
            gen.writeStringField('Description', p.Name);
            gen.writeFieldName('Packaging');

            gen.writeStartObject();
            gen.writeStringField('Code', packageTypeMap.get('Package').Package_Code__c);
            gen.writeStringField('Description', p.Package_Type__c);
            gen.writeEndObject();

            gen.writeFieldName('Dimensions');

            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            if(p.Weight_Unit__c == 'KGS') {
                gen.writeStringField('Code', 'CM');
                gen.writeStringField('Description', 'Centimeter');
            }
            else {
                gen.writeStringField('Code', 'IN');
                gen.writeStringField('Description', 'Inches');
            }

            gen.writeEndObject();
            gen.writeStringField('Length', String.valueof(p.Length__c));
            gen.writeStringField('Width', String.valueof(p.Width__c));
            gen.writeStringField('Height', String.valueof(p.Height__c));
            gen.writeEndObject();

            gen.writeFieldName('PackageWeight');
            gen.writeStartObject();
            gen.writeFieldName('UnitOfMeasurement');
            gen.writeStartObject();
            gen.writeStringField('Code', String.valueof(p.Weight_Unit__c));
            if(p.Weight_Unit__c == 'KGS') gen.writeStringField('Description', 'KiloGrams' );
            else gen.writeStringField('Description', 'Pounds' );
            gen.writeEndObject();
            gen.writeStringField('Weight', String.valueof(p.Weight__c));
            gen.writeEndObject();

            gen.writeEndObject();
        }


        // End "Shipment" object
        gen.writeEndObject();

        // Start "LabelSpecification" object
        gen.writeFieldName('LabelSpecification');
        gen.writeStartObject();
        gen.writeFieldName('LabelImageFormat');
        gen.writeStartObject();
        gen.writeStringField('Code', 'GIF');
        gen.writeStringField('Description', 'GIF');
        gen.writeEndObject(); // End "LabelImageFormat" object
        // gen.writeStringField('HTTPUserAgent', 'Mozilla/4.5');
        gen.writeEndObject(); // End "LabelSpecification" object

        // End "ShipmentRequest" object
        gen.writeEndObject();

        // End outermost object
        gen.writeEndObject();

        // Get the JSON string
        String jsonString = gen.getAsString();

        // Print the JSON string
        System.debug(jsonString);
        String requestBody = gen.getAsString();


        req.setBody(requestBody);

        Http http = new Http();

        String headersString = '';
        headersString += 'Content-Type: ' + req.getHeader('Content-Type') + '\n';
        headersString += 'TransactionSrc: ' + req.getHeader('TransactionSrc') + '\n';
        headersString += 'TransID: ' + req.getHeader('TransID') + '\n';
        headersString += 'Authorization: ' + req.getHeader('Authorization') + '\n';

        String requestString = 'Endpoint: ' + req.getEndpoint() + '\n'
            + 'Method: ' + req.getMethod() + '\n'
            + 'Body: ' + req.getBody()+'\n'
            +'Header : '+headersString ;


        mWrap.request = requestString;

        HttpResponse res = new HttpResponse();
        string httpResult = '';
        Decimal StatusCode = 0;
        if(Test.isRunningTest()){
            httpResult = '{"ShipmentResponse":{"Response":{"ResponseStatus":{"Code":"1","Description":"Success"},"TransactionReference":{"CustomerContext":"00001267","TransactionIdentifier":"ciewssoat5B283qSqLs2wL"}},"ShipmentResults":{"ShipmentCharges":{"BaseServiceCharge":{"CurrencyCode":"INR","MonetaryValue":"4146.00"},"TransportationCharges":{"CurrencyCode":"INR","MonetaryValue":"5385.44"},"ItemizedCharges":[{"Code":"375","CurrencyCode":"INR","MonetaryValue":"1194.44"},{"Code":"430","CurrencyCode":"INR","MonetaryValue":"45.00","SubType":"Commercial_Seasonal_Surcharge"}],"ServiceOptionsCharges":{"CurrencyCode":"INR","MonetaryValue":"0.00"},"TotalCharges":{"CurrencyCode":"INR","MonetaryValue":"5385.44"}},"BillingWeight":{"UnitOfMeasurement":{"Code":"KGS","Description":"Kilograms"},"Weight":"1.0"},"ShipmentIdentificationNumber":"1ZXXXXXXXXXXXXXXXX","PackageResults":{"TrackingNumber":"1ZXXXXXXXXXXXXXXXX","ServiceOptionsCharges":{"CurrencyCode":"INR","MonetaryValue":"0.00"},"ShippingLabel":{"ImageFormat":{"Code":"GIF","Description":"GIF"},"GraphicImage":"R0lGODlheAUgA/cAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4ODg8PDx"}}}}}';

            StatusCode = 200;
        }
        else {
            res = http.send(req);
            mWrap.response = httpResult = res.getBody();
            StatusCode = res.getStatusCode();
        }
        system.debug('StatusCode : '+StatusCode);
        if(StatusCode == 200){
            //JSONParser parser = JSON.createParser(httpResult);

            // Variables to hold the extracted values


                   // Parse the JSON string
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(httpResult);

            // Debug the data structure
            System.debug('Data: ' + data);

            // Extract the fields
            Map<String, Object> shipmentResponse = (Map<String, Object>) data.get('ShipmentResponse');
            System.debug('Shipment Response: ' + shipmentResponse);

            Map<String, Object> shipmentResults = new Map<String, Object>();
            if (shipmentResponse != null) {
                shipmentResults = (Map<String, Object>) shipmentResponse.get('ShipmentResults');
            }
            System.debug('Shipment Results: ' + shipmentResults);

            String shipmentIdentificationNumber = '';
            if (shipmentResults != null) {
                shipmentIdentificationNumber = (String) shipmentResults.get('ShipmentIdentificationNumber');
            }
            System.debug('Shipment Identification Number: ' + shipmentIdentificationNumber);

            Map<String, Object> shipmentCharges = new Map<String, Object>();
            Map<String, Object> totalCharges = new Map<String, Object>();
            if (shipmentResults != null) {
                shipmentCharges = (Map<String, Object>) shipmentResults.get('ShipmentCharges');
                totalCharges = (Map<String, Object>) shipmentCharges.get('TotalCharges');
            }
            System.debug('Shipment Charges: ' + shipmentCharges);
            System.debug('Total Charges: ' + totalCharges);

            String totalChargesCurrencyCode = '';
            Decimal totalChargesMonetaryValue = 0;
            if (totalCharges != null) {
                totalChargesCurrencyCode = (String) totalCharges.get('CurrencyCode');
                totalChargesMonetaryValue = Decimal.valueOf((String) totalCharges.get('MonetaryValue'));
            }
            System.debug('Total Charges Currency Code: ' + totalChargesCurrencyCode);
            System.debug('Total Charges Monetary Value: ' + totalChargesMonetaryValue);

            Map<String, Object> packageResults = new Map<String, Object>();
            if (shipmentResults != null) {
                packageResults = (Map<String, Object>) shipmentResults.get('PackageResults');
            }
            System.debug('Package Results: ' + packageResults);

            String trackingNumber = '';
            List<String> graphicImage = new List<String>();
            if (packageResults != null) {
                trackingNumber = (String) packageResults.get('TrackingNumber');
                Map<String, Object> shippingLabel = (Map<String, Object>) packageResults.get('ShippingLabel');
                System.debug('Shipping Label: ' + shippingLabel);
                if (shippingLabel != null) {
                    Map<String, Object> imageFormat = (Map<String, Object>) shippingLabel.get('ImageFormat');
                    System.debug('Image Format: ' + imageFormat);
                    if (imageFormat != null) {
                        String imageFormatCode = (String) imageFormat.get('Code');
                        String graphicImageValue = (String) shippingLabel.get('GraphicImage');
                        graphicImage.add(graphicImageValue);
                    }
                }
            }

            // Debug the extracted fields
            System.debug('Tracking Number: ' + trackingNumber);
            System.debug('Graphic Image: ' + graphicImage);




            if(totalChargesMonetaryValue != null){
                Id RTID; RTID = Schema.SObjectType.Shipment__c.getRecordTypeInfosByDeveloperName().get('UPS_Shipping').getRecordTypeId();
                if(isReturnShipment && String.isNotEmpty(masterShipmentId)){
                    Ship.Id = null;
                    Ship.Master_Shipment__c = masterShipmentId;
                    Ship.Return_Shipment__c = true;
                }
                Ship.Active__c = true;
                if(fromAddress.Id != null && Ship.Shipment_Billing_options__c != null && String.isNotEmpty(Ship.Shipment_Billing_options__c) && Ship.Shipment_Billing_options__c == 'SENDER'){
                    Ship.Billing_Address__c = fromAddress.Id;
                }else if(toAddress.Id != null) Ship.Billing_Address__c = toAddress.Id;
                Ship.Customer__c = toAddress.Customer__c;
                Ship.Customer_Contact__c = tContact.Id;
                Ship.Status__c = 'Shipped';
                Ship.RecordTypeId = RTID;
                Ship.Shipping_Address__c = toAddress.Id;
                if(packList[0].Logistic__c != null && packList[0].Logistic__r.Billing_options__c != null) Ship.Shipment_Billing_options__c = packList[0].Logistic__r.Billing_options__c;
                //Ship.Logistic__c = packList[0].Logistic__c;
                //Ship.Package__c= packList[0].Id;
                if(rmaid != '')Ship.Return_Merchandise_Authorisation__c = rmaid;
                Ship.Order__c = packList[0].Order__c;
                Ship.Shipment_Identification_Number__c = ShipmentIdentificationNumber;
                Ship.TrackingNumber__c = trackingNumber;
                Ship.UPS_Services__c = service;
                Ship.Shipping_Amount__c = totalChargesMonetaryValue;
                ship.UPS_Service_Code__c = serviceCode;
                Ship.Package_Weight__c = toalWeightValue;
                decimal totalPackQty = 0;
                for(Package__c pK : packList) {
                    if(pK.Package_Quantity__c != null) totalPackQty += pK.Package_Quantity__c;
                }
                //if(Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Total_Package_items__c.isUpdateable())  Ship.Total_Package_items__c = totalPackQty;
                if(Schema.sObjectType.Shipment__c.fields.Master_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Master_Shipment__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Return_Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Return_Shipment__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Active__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Customer__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Customer__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Customer_Contact__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Customer_Contact__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Shipment__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Address__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Order__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Order__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipment_Identification_Number__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipment_Identification_Number__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.TrackingNumber__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.TrackingNumber__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.UPS_Services__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.UPS_Services__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Amount__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Shipping_Amount__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.UPS_Service_Code__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.UPS_Service_Code__c.isUpdateable() && Schema.sObjectType.Shipment__c.fields.Package_Weight__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Package_Weight__c.isUpdateable()) {
                    // upsert ship;
                        //     System.SObjectAccessDecision securityDecisionA1 = Security.stripInaccessible(AccessType.UPDATABLE, new List<Shipment__c>{ship});

                        // List<SObject> accessibleVersionsA1 = securityDecisionA1.getRecords();

                        // if (!accessibleVersionsA1.isEmpty()) {
                        //     // Perform the insert operation with the accessible version
                        //     upsert accessibleVersionsA1[0];
                        //     System.debug('Accessible version inserted successfully.');
                        //     System.debug('Accessible version: ' + accessibleVersionsA1[0]);
                        //     Ship.Id = accessibleVersionsA1[0].Id;
                        // } else {
                        //     // Handle the case where FLS validation fails
                        //     // You may log an error, throw an exception, or perform other appropriate actions
                        //     System.debug('FLS validation failed. No accessible version found.');
                        // }
                        // upsert ship;
                        List<SObject> safeships2 = FLSHelper.getSafeRecords(
                                                new List<Shipment__c>{ship},
                                                'Shipment__c',
                                                AccessType.UPDATABLE
                                            );
                                            List<Shipment__c> typedships2 = new List<Shipment__c>();
                                            for (SObject ss : safeships2) {
                                                typedships2.add((Shipment__c)ss);
                                            }
                                            if (!typedships2.isEmpty()) {
                                                upsert typedships2; // or insert/update as needed
                                                Ship.Id = typedships2[0].Id;
                                            }
                    List<SObject> sObjects = new List<SObject>{ship};
                    List<Shipment__c> shipment2upsert = (List<Shipment__c>)Security.stripInaccessible(AccessType.UPSERTABLE, sObjects).getRecords();
                    if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) {
                      upsert shipment2upsert;
                      System.debug('shipment2upert'+ shipment2upsert);
                      Ship.Id = shipment2upsert[0].Id;
                    }

                  }

                List<attachment> attList = new List<attachment>();
                // upsW.noOfimgs = graphicImage.size();
                attachment att = new attachment();
                System.debug('shid id=>'+Ship.Id);
                if(graphicImage.size() > 0){
                    for(Integer i=1; i<=graphicImage.size(); i++){
                        att = new attachment();
                        if(Schema.sObjectType.attachment.fields.Name.isCreateable() && Schema.sObjectType.attachment.fields.Name.isUpdateable()) att.Name = 'UPS_Label_'+i;
                        if(Schema.sObjectType.attachment.fields.parentId.isCreateable() || Schema.sObjectType.attachment.fields.parentId.isUpdateable()) att.parentId = Ship.Id;
                        if(Schema.sObjectType.attachment.fields.ContentType.isCreateable() && Schema.sObjectType.attachment.fields.ContentType.isUpdateable()) att.ContentType = 'image/gif';
                        if(Schema.sObjectType.attachment.fields.body.isCreateable() && Schema.sObjectType.attachment.fields.body.isUpdateable()) { att.body = EncodingUtil.base64Decode(graphicImage[i-1]); }
                        attList.add(att);
                    }
                }
                if(attList.size() > 0) insert attList;
                mWrap.shipment = Ship;
                if(!isReturnShipment){
                    for(Integer i=0; i<packList.size(); i++) {
                        //if(Schema.sObjectType.Package__c.fields.Shipment__c.isCreateable() && Schema.sObjectType.Package__c.fields.Shipment__c.isUpdateable()) packList[i].Shipment__c = Ship.Id;
                        if(Schema.sObjectType.Package__c.fields.Status__c.isCreateable() && Schema.sObjectType.Package__c.fields.Status__c.isUpdateable()) packList[i].Status__c = Ship.Status__c;
                        if(trackingNumber != null && trackingNumber != '') if(Schema.sObjectType.Package__c.fields.Tracking_Number__c.isCreateable() && Schema.sObjectType.Package__c.fields.Tracking_Number__c.isUpdateable()) packList[i].Tracking_Number__c = trackingNumber;
                    }

                    if(packList.size() > 0 && Schema.SObjectType.Package__c.isCreateable() && Schema.SObjectType.Package__c.isUpdateable()){
                        //if(Schema.sObjectType.Package__c.isCreateable() && Schema.sObjectType.Package__c.isUpdateable()){
                        PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false;
                        PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false;
                        PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false;
                        PreventRecursiveLedgerEntry.SOLI_AllocateStock = false;
                        PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false;
                        //upsert packList;
                    }

                }

            }
            else{

                mWrap.error = 'Error: No amount is applied';
            }
        }
        else{
            System.debug('Error: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
            mWrap.error = 'Error: ' + res.getStatus()+'Response: ' + res.getBody();
        }
        return mWrap;
       // return null;
    }

    @AuraEnabled
    public static Wrapper voidShipment(List < Package__c > packList ,String Shipment,String myConsVar) {
        Wrapper mWrap = new Wrapper();
        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);

        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
        system.debug('Shipment Shipment_Identification_Number__c:'+Ship.Shipment_Identification_Number__c);
        string endpoint = myConsW.endPoint + '/api/shipments/v1/void/cancel/';///api/shipments/v1/void/cancel/:shipmentidentificationnumber?9102084383041101186729
        system.debug('endpoint=>'+endpoint);
        String shipmentIdentificationNumber =Ship.Shipment_Identification_Number__c;
        if(shipmentIdentificationNumber != null && shipmentIdentificationNumber != '') endpoint += shipmentIdentificationNumber;
        String trackingnumber = Ship.Tracking_Number__c;
        if(trackingnumber != null && trackingnumber != '') endpoint += '?'+trackingnumber;

        // Create the HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('DELETE');
        String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);
        // Set the Authorization header (replace 'YOUR_AUTH_TOKEN' with your actual token)
        req.setHeader('Authorization', 'Bearer '+accesstoken);

        // Send the HTTP request
        Http http = new Http();
        string httpResult = '';
        Decimal StatusCode = 0;
        try {
            String headersString = '';
            headersString += 'Content-Type: ' + req.getHeader('Content-Type') + '\n';
            headersString += 'Authorization: ' + req.getHeader('Authorization') + '\n';

            String requestString = 'Endpoint: ' + req.getEndpoint() + '\n'
                + 'Method: ' + req.getMethod() + '\n'
                + 'Body: ' + req.getBody()+'\n'
                +'Header : '+headersString ;

            mWrap.request = requestString;
			System.debug('request -> '+mWrap.request);
            HttpResponse res = new HttpResponse();

            if(Test.isRunningTest()){
                httpResult = '{"VoidShipmentResponse":{"Response":{"ResponseStatus":{"Code":"1","Description":"Success"}},"SummaryResult":{"Status":{"Code":"1","Description":"Voided"}}}}';
                StatusCode = 200;
            }
            else {
                res = http.send(req);
                System.debug('res=>'+res);
                mWrap.response = httpResult = res.getBody();
                System.debug('response=>'+mWrap.response);
                StatusCode = res.getStatusCode();
            }
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            Mwrap.error = 'Error : '+e.getMessage()+' at line : '+e.getLineNumber();

        }

        // Process the response
        if (StatusCode == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            System.debug('Response: ' + responseMap);

            if (responseMap.containsKey('VoidShipmentResponse')) {
                Map<String, Object> voidShipmentResponse = (Map<String, Object>) responseMap.get('VoidShipmentResponse');
                Map<String, Object> response = (Map<String, Object>) voidShipmentResponse.get('Response');
                Map<String, Object> responseStatus = (Map<String, Object>) response.get('ResponseStatus');
                String code = (String) responseStatus.get('Code');

                if (code == '1') {
                    System.debug('Success: Shipment voided.');
                    Ship.Status__c = 'Cancelled';
                    if(Schema.sObjectType.Shipment__c.fields.Status__c.isCreateable() && Schema.sObjectType.Shipment__c.fields.Status__c.isUpdateable()){
                        //update Ship;
                        List<SObject> sObjects = new List<SObject>{ship};
                        List<Shipment__c> shipment2upsert = (List<Shipment__c>)Security.stripInaccessible(AccessType.UPSERTABLE, sObjects).getRecords();
                        if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) upsert shipment2upsert;
                    }

                    for(Package__c pac : packList) { pac.Status__c = Ship.Status__c; }
                    PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false;
                    PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false;
                    PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false;
                    PreventRecursiveLedgerEntry.SOLI_AllocateStock = false;
                    PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false;
                    if(Schema.sObjectType.Package__c.fields.Status__c.isCreateable() && Schema.sObjectType.Package__c.fields.Status__c.isUpdateable()){
                        upsert packList;
                    }
                } else {
                    System.debug('Error: ' + responseStatus.get('Description'));
                }
            }
        } else {
            Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            if (errorResponse.containsKey('response')) {
                Map<String, Object> response = (Map<String, Object>) errorResponse.get('response');
                List<Object> errors = (List<Object>) response.get('errors');
                for (Object errorObj : errors) {
                    Map<String, Object> error = (Map<String, Object>) errorObj;
                    System.debug('Error Code: ' + error.get('code') + ', Message: ' + error.get('message'));
                    Mwrap.error = 'Error Code: ' + error.get('code') + ', Message: ' + error.get('message');
                }
            } else {
                System.debug('Unknown error occurred: ' + httpResult);
                Mwrap.error = 'Unknown error occurred: ' +httpResult;
            }
        }
        return Mwrap;
       // return null;
    }
    @AuraEnabled
    public static Wrapper getTrackingDetails(List < Package__c > packList, String Shipment,String myConsVar) {
        Wrapper mWrap = new Wrapper();
        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);

        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
        String[] s;
        if(Ship.TrackingNumber__c != null) s = Ship.TrackingNumber__c.split(',');
        if(s != null && s.size() > 0) Ship.TrackingNumber__c = s[0];
        // Define the endpoint URL
        if(Ship.TrackingNumber__c != null && Ship.TrackingNumber__c != ''){
            String endpoint = myConsW.endPoint + '/api/track/v1/details/' + Ship.TrackingNumber__c + '?locale=en_US&returnSignature=false';
            String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);

            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accesstoken);  // Replace with actual token
            req.setHeader('transId', 'testing');
            req.setHeader('transactionSrc', 'testing');

            // Initialize the HTTP response
            HttpResponse res;
            string httpresult = '';
            Decimal StatusCode = 0;
            // Check if the test is running
            if (Test.isRunningTest()) {
                // Mock response for testing
                httpresult = '{"trackResponse":{"shipment":[{"inquiryNumber":"1Z1202R66698804005","package":[{"trackingNumber":"1Z1202R66698804005","deliveryDate":[],"activity":[{"location":{"slic":"9642"},"status":{"type":"X","description":"The package is at the clearing agency awaiting final release.","statusCode":"092"},"date":"20240320","time":"190838","gmtDate":"20240320","gmtOffset":"+08:00","gmtTime":"11:08:38"},{"location":{"address":{"city":"Changi","countryCode":"SG","country":"SG"},"slic":"0009"},"status":{"type":"I","description":"Arrived at Facility","code":"AR","statusCode":"005"},"date":"20240320","time":"070700","gmtDate":"20240319","gmtOffset":"+08:00","gmtTime":"23:07:00"},{"location":{"address":{"city":"Shenzhen","countryCode":"CN","country":"CN"},"slic":"0009"},"status":{"type":"I","description":"Departed from Facility","code":"DP","statusCode":"005"},"date":"20240320","time":"032000","gmtDate":"20240319","gmtOffset":"+08:00","gmtTime":"19:20:00"}],"currentStatus":{"description":"Customs Clearance in Progress","code":"092","simplifiedTextDescription":"The package is at the clearing agency awaiting final release."}}]}]}}';
                StatusCode = 200;
            } else {
                // Perform the HTTP callout
                Http http = new Http();

                try {
                    res = http.send(req);
                    httpresult = res.getBody();
                    StatusCode = res.getStatusCode();
                }
                catch (Exception e) {
                    System.debug('HTTP Request failed: ' + e.getMessage());
                    Mwrap.error = 'HTTP Request failed: ' + e.getMessage();
                }

            }
            if(StatusCode == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpresult);
                Map<String, Object> trackResponse = (Map<String, Object>) responseMap.get('trackResponse');
                List<Object> shipments = (List<Object>) trackResponse.get('shipment');
                List<trackwrapper> activityDetails = new List<trackwrapper>();

                for (Object shipmentObj : shipments) {
                    Map<String, Object> shipment1 = (Map<String, Object>) shipmentObj;
                    List<Object> packages = (List<Object>) shipment1.get('package');

                    for (Object packageObj : packages) {
                        Map<String, Object> packageItem = (Map<String, Object>) packageObj;
                        List<Object> activities = (List<Object>) packageItem.get('activity');
                        for (Object activityObj : activities) {
                             Map<String, Object> activity = (Map<String, Object>) activityObj;
                            trackwrapper tw = new trackwrapper();

                            Map<String, Object> location = (Map<String, Object>) activity.get('location');
                            Map<String, Object> address = location.containsKey('address') ? (Map<String, Object>) location.get('address') : null;
                            Map<String, Object> status = (Map<String, Object>) activity.get('status');

                            tw.location = (address != null && address.containsKey('city')) ? (String) address.get('city') + ', ' + (String) address.get('country') : 'N/A';
                            tw.activityDesp = (String) status.get('description');
                            tw.tDate = (String) activity.get('date');
                            if(tw.tDate != null){
                               tw.tDate = tw.tDate.substring(0, 4) + '-' + tw.tDate.substring(4, 6) + '-' + tw.tDate.substring(6, 8);
                            }
                            tw.tTime = (String) activity.get('time');
                            if(tw.tTime != null){
                               tw.tTime = tw.tTime.substring(0, 2) + ':' + tw.tTime.substring(2, 4) + ':' + tw.tTime.substring(4, 6);
                            }
                            tw.dateTimeString = tw.tDate + ' ' + tw.tTime;
                            tw.dtValue = DateTime.valueOf(tw.dateTimeString);
                            ///(Date.valueOf(tw.tDate), Time.newInstance(Integer.valueOf(tw.tTime.substring(0, 2)), Integer.valueOf(tw.tTime.substring(2, 4)), Integer.valueOf(tw.tTime.substring(4, 6)), 0));

                            activityDetails.add(tw);
                        }
                    }
                }
                if(activityDetails.size() > 0) {
                    Mwrap.trackWrap = activityDetails;
                    List<Shipment_Flow__c> existingSFList = new List<Shipment_Flow__c>();
                    Map<String, Shipment_Flow__c> sfMap = new Map<String, Shipment_Flow__c>();
                    List<Shipment_Flow__c> sf2create = new List<Shipment_Flow__c>();

                    if(Ship != null) {
                        for(Shipment_Flow__c sf: [select Id, Name, Shipment__c, Location__c,Shipment_DateTime__c, Description__c, Shipment_Flow_Start_Date__c, Shipment_Flow_End_Date__c from Shipment_Flow__c where Shipment__c =: Ship.Id Order by Name Asc]) {
                            sfMap.put(sf.Shipment_DateTime__c, sf);
                        }
                    }
                    for(Integer i=1; i<activityDetails.size(); i++) {
                        system.debug('activityDetails[i].dtValue~>'+String.valueof(activityDetails[i].dtValue));
                        system.debug('activityDetails[i].activityDesp~>'+String.valueof(activityDetails[i].activityDesp));
                        Shipment_Flow__c sf = new Shipment_Flow__c(Shipment_DateTime__c = String.valueof(activityDetails[i].dtValue));
                        system.debug('Key Set-->'+sfMap.keyset().contains(String.valueof(activityDetails[i].dtValue)));
                        if(!sfMap.keyset().contains(String.valueof(activityDetails[i].dtValue))) {
                            sf.Name = 'SF ' + Ship.Name + '-' + i;
                            if(Ship != null) sf.Shipment__c = Ship.Id;
                            sf.Active__c = true;
                            sf.Location__c = activityDetails[i].location;
                            if(activityDetails[i].dtValue != null) sf.Shipment_Flow_Start_Date__c = Datetime.valueof(activityDetails[i].dtValue);
                            if(activityDetails[i].dtValue != null) sf.Shipment_Flow_End_Date__c = Datetime.valueof(activityDetails[i].dtValue);
                            if(activityDetails[i].activityDesp != null) sf.Description__c = activityDetails[i].activityDesp;
                            if(activityDetails[i].activityDesp != null && activityDetails[i].activityDesp == 'Delivered') Ship.Status__c = 'Delivered';
                            sf2create.add(sf);
                            //sfMap.put(String.valueof(activityDetails[i].dtValue), sf);
                        }else if(activityDetails[i].activityDesp != null && activityDetails[i].activityDesp == 'Delivered' && sfMap.get(String.valueof(activityDetails[i].dtValue)).Description__c == 'Delivered'){
                            Ship.Status__c = 'Delivered';
                            sf2create.add(sfMap.get(String.valueof(activityDetails[i].dtValue)));
                        }
                    }
                    if(Schema.sObjectType.Shipment__c.isCreateable() && Schema.sObjectType.Shipment__c.isUpdateable()) { PreventRecursiveLedgerEntry.SOLI_SufficientStockCheck = false; PreventRecursiveLedgerEntry.SOLI_ApplyTaxes = false; PreventRecursiveLedgerEntry.SOLI_CalculateLogisticQuantity = false; PreventRecursiveLedgerEntry.SOLI_AllocateStock = false; PreventRecursiveLedgerEntry.SOLI_CreateMrpsOnExplode = false; PreventRecursiveLedgerEntry.shippedItemsCheck = false; upsert Ship; }else{ }
                    if(sf2create.size() > 0 && Schema.sObjectType.Shipment_Flow__c.isCreateable() && Schema.sObjectType.Shipment_Flow__c.isUpdateable()) upsert sf2create; else{ }
                    Mwrap.shipment = Ship;
                    Mwrap.Shipmentflows = (sf2create.size() > 0) ? sf2create : sfMap.values();
                }
                else Mwrap.error = 'No Track details available for the provided Tracking number';
            }

            else {
                Map<String, Object> errorResponse = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
                if (errorResponse.containsKey('response')) {
                    Map<String, Object> response = (Map<String, Object>) errorResponse.get('response');
                    List<Object> errors = (List<Object>) response.get('errors');
                    for (Object errorObj : errors) {
                        Map<String, Object> error = (Map<String, Object>) errorObj;
                        System.debug('Error Code: ' + error.get('code') + ', Message: ' + error.get('message'));
                        Mwrap.error = 'Error Code: ' + error.get('code') + ', Message: ' + error.get('message');
                    }
                } else {
                    System.debug('Unknown error occurred: ' + httpResult);
                    Mwrap.error = 'Unknown error occurred: ' +httpResult;
                }
            }
        }
        System.debug('Mwrap->'+Mwrap);
        return Mwrap;
       // return null;

    }
    @AuraEnabled
    public static String getAccessToken(string clientId,String clientSecret,String accountNumber,String endPoint)
    {
        HttpRequest req = new HttpRequest();
        string tokenUrl = endPoint+ '/security/v1/oauth/token';
        req.setEndpoint(tokenUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('x-merchant-id', accountNumber); // Replace 'string' with your actual merchant ID

        // Replace 'username' and 'password' with your actual UPS credentials
        String username = clientId;
        String password = clientSecret;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);

        String requestBody = 'grant_type=client_credentials';
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = new HttpResponse();
        decimal statusCode =0;
        String httpResult = '';
        if(Test.isRunningTest()){
            httpResult = '{"token_type": "Bearer", "issued_at": "1717314395763", "client_id": "2thxoiEGpYni25ICVK7Gtv0cLq1ug2IKHqSSDvfZQQfvDhpY", "access_token": "eyJraWQiOiI2NGM0YjYyMC0yZmFhLTQzNTYtYjA0MS1mM2EwZjM2Y2MxZmEiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzM4NCJ9.eyJzdWIiOiJzaGFndWZ0aGFtZmhiQGdtYWlsLmNvbSIsImNsaWVudGlkIjoiMnRoeG9pRUdwWW5pMjVJQ1ZLN0d0djBjTHExdWcySUtIcVNTRHZmWlFRZnZEaHBZIiwibWVyX2lkIjoiQjQzSjg1IiwiaXNzIjoiaHR0cHM6Ly9hcGlzLnVwcy5jb20iLCJ1dWlkIjoiNTlDM0U4MTYtQTc4MC0xRjI3LUFDREYtRjY1ODBFMjNFQ0IxIiwic2lkIjoiNjRjNGI2MjAtMmZhYS00MzU2LWIwNDEtZjNhMGYzNmNjMWZhIiwiYXVkIjoiQXF4b2x0IEVSUCBsb2dpc3RpY3MiLCJhdCI6IkNoMDJoV3RxT2NuR0dRY0h1aTR5bGxOYW9UOXEiLCJuYmYiOjE3MTczMTQzOTUsInNjb3BlIjoiTG9jYXRvcldpZGdldCIsIkRpc3BsYXlOYW1lIjoiQXF4b2x0IEVSUCBsb2dpc3RpY3MiLCJleHAiOjE3MTczMjg3OTUsImlhdCI6MTcxNzMxNDM5NSwianRpIjoiNTI0YzVmZTEtMTBiOC00MjM0LTliNjMtMmU4ZjRlZmI4OTJkIn0.c_QV_JkWa-06XIfhFFp2L3R1ddkrN4yD58dY109gX5b1Z31LWDVg4sM0Bs3fbe5iKr8_HZUax1RYZBd-rLtCh4A39T8hxxEfV0bsjUKSb9_Vwrieb3nAM-KvXROcWQiXz7I8G_8M-TaT3NMN_yq4vHNV4OxEr-orReXh93HA6u12WV1zgdqHNdzbnALPOD8eMkVeTMyGHWosxe2Y0E045r45ZFi7EEzM_BGsZnCjWg9PPSv-fktKZJ4spYUobppR-gzE9CdUqtoMMD5E9bNscCRQx9mnDe1F4hJ-ZN8Ufv4HqLHvFqzWUID2eC55mUXXHm4xv2KPE2tZnSqUfyz28OjwFfaAyVAID4M9N5yvG1n4jtorb5KhxsKUL5_qqTP2DfDYwo7gq_0TM-uhk7kzPe6wZ_x1tQkhjY3XIqiEO9bNRNWsHpw-FhxIdWFwo33YOuEJv_2lSD-ZZjTGY9FCelxym39HWL5LLgEKQAO73huA6_my1ZbYlYKyWPVYtlIG4AX0Y1YkaNz0ZeQZjU89-fNeqFxcskScZ1OqXpchphFUpIjjcY4aeXNbwMyIAatbSTyqFiMj7_AR0WElQ3tJDqLPV2j2T_VGbtWT_sto-6h59TVUGRGaATyhl8cAt2RGEZlYMrgsfjryhyWn8oQdS4FXhqL8qCTG_2YYGksN71c", "expires_in": "14399", "status": "approved"}';
            statusCode = 200;        }        else{            res = http.send(req);            httpResult  = res.getBody();            statusCode = res.getStatusCode();        }
        if (statusCode == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpResult);
            String accessToken = (String) responseMap.get('access_token');
            System.debug('Access Token: ' + accessToken);
            return accessToken;
        } else {

            System.debug('Error: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
            return 'Error: ' + res.getStatus()+'Response: ' + res.getBody();
        }
   // return null;

    }

    @AuraEnabled
    global static Wrapper getDefaultData(String ShipId,String packIds){
        system.debug('packIds : '+packIds);
        Wrapper wrap = new Wrapper();

        List<selectOptions> options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        Schema.DescribeFieldResult fieldResult = Shipment__c.QV_Notification__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.qvNotification = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Carbon_Neutral__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.CarbonNeutral = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.COD__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {options.add(new selectOptions(f.getLabel(),f.getValue()));}
        wrap.COD = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Dry_Ice__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.DryIce = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Return_Service__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.ReturnService = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Saturday_Delivery__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.SaturdayDelivery = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Additional_Handling__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.AdditionalHandling = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Verbal_Confirmation__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.VerbalConfirmation = options;

        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Delivery_Confirmation__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.DeliveryConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Status__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.StatusConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Product_Unit_Code__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.PucConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.International_Forms__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.IfConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Terms_Of_Shipment__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.TosConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Reason_For_Export__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.RfeConfirmation = options;


        options = new List<selectOptions>();
        options.add(new selectOptions('--None--','--None--'));
        fieldResult = Shipment__c.Shipment_Billing_options__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) { options.add(new selectOptions(f.getLabel(),f.getValue())); }
        wrap.BillingOptions = options;
      
       
        String packageFields = UtilClass.selectStarFromSObject('Package__c');
        String addressFields = UtilClass.selectStarFromSObject('Address__c');
        string packageListFields = UtilClass.selectStarFromSObject('Package_List__c');
        if(ShipId != null && ShipId != ''){
            String shipfields = UtilClass.selectStarFromSObject('Shipment__c');
            String ShipmentRecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Shipment__c','UPS_Shipping');

            wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name, Logistic__r.From_Contact__c,Logistic__r.Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c,Logistic__r.Billing_Contact__c, Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,  '+
                                           +' Logistic__r.Billing_Contact_Return__r.Id,Logistic__r.Billing_Contact_Return__r.Name,Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c,Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Order__r.Contact__r.Email, Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, '+
                                           +' Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c, '+
                                           +' Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c, '+
                                           +' Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c from Package__c where Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Active__c = true');
            set<Id> packageIds = new Set<Id>();
            for(Package__c pck : wrap.packList ) packageIds.add(pck.Id);
            wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', Package__r.Name, Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c, Order_Product__r.Base_Price__c, Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name, RMA_Line_Item__r.Ord_Item__r.Product2.Name, Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, Order_Product__r.ReturnedQuantity__c, Order_Product__r.Order.Name, Order_Product__r.UnitPrice, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c FROM Package_List__c WHERE Package__c IN :packageIds');
            List<Shipment__c> Shipments = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
            if(Shipments.size() > 0) wrap.ship = Shipments[0];
            else wrap.alertlist.add('Shipment is Either Cancelled or not availbale in the system');
            //List<Shipment__c> queryShips=Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
            //if(queryShips.size() > 0) wrap.ship = queryShips[0];
            //else wrap.ship = new Shipment__c();
            // wrap.ship = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
            List<Shipment__c> returnShips = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = true AND Active__c = true And Master_Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
            if(returnShips.size() > 0) wrap.returnShip =returnShips[0];
        }
        else if(packIds != null && packIds != ''){
            List<String> packId = (List<String>) JSON.deserialize(packIds,List<String>.class);
            wrap.packList = Database.query('select ' + String.escapeSingleQuotes(packageFields) + ' ,Logistic__r.Billing_Address__r.Name,Logistic__r.Billing_Contact__r.Name,Logistic__r.From_Contact__c, Logistic__r.Contact__c,Logistic__r.Billing_Account_number__c,Logistic__r.Billing_Address__c,Logistic__r.Billing_Contact__c,Logistic__r.Billing_options__c,Logistic__r.Channel__c, Logistic__r.Order__c, Logistic__r.From_Address__c, Logistic__r.To_Address__c, Order__r.Bill_To_Address__c,Order__r.Ship_To_Address__c , Work_Order__r.Billing_Address__c, Work_Order__r.Shipping_Address__c, Purchase_Order__r.Delivery_Address__c, Purchase_Order__r.Invoice_Address__c,Order__r.Name,Order__r.OrderNumber,  '+
                                           +' Transfer_Order__r.From_Address__c, Transfer_Order__r.To_Address__c, Order__r.Channel__c,Return_Merchandise_Authorisation__r.Order__r.Bill_To_Address__c,Return_Merchandise_Authorisation__r.Order__r.Ship_To_Address__c,Order__r.Contact__r.Email, Logistic__r.Order_S__c, Logistic__r.Order_S__r.Contact__c, Logistic__r.Order_S__r.Contact__r.Name, Logistic__r.Order_S__r.Contact__r.Phone, Logistic__r.Order_S__r.Contact__r.Email, Logistic__r.Order_S__r.Contact__r.Company__c, '+
                                           +' Logistic__r.Billing_Contact_Return__r.Id, Logistic__r.Billing_Contact_Return__r.Name,Logistic__r.Order_S__r.Bill_To_Return__c, Logistic__r.Order_S__r.Billing_Account_Number_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__c, Logistic__r.Order_S__r.Billing_Contact_Return__c, Order__r.Bill_To_Return__c, Order__r.Billing_Account_Number_Return__c, Order__r.Billing_Address_Return__c, Order__r.Billing_Contact_Return__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Postal_Code__c, Order__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Order_S__r.Billing_Address_Return__r.Country__c, Order__r.Billing_Address_Return__r.Country__c, '+
                                           +' Logistic__r.Bill_To_Return__c, Logistic__r.Billing_Account_Number_Return__c, Logistic__r.Billing_Address_Return__c, Logistic__r.Billing_Address_Return__r.Postal_Code__c, Logistic__r.Billing_Address_Return__r.Country__c, Logistic__r.Billing_Contact_Return__c, Logistic__r.Shipment_type_Return__c, Logistic__r.Shipping_Preferences_Return__c, '+
                                           +' Work_Order__r.Contact__r.Email, Purchase_Order__r.Vendor_Contact__r.Email, Transfer_Order__r.Contact__r.Email, Return_Merchandise_Authorisation__r.Order__r.Contact__r.Email,Return_Merchandise_Authorisation__r.Address__c,Return_Merchandise_Authorisation__r.Site__r.Address__c,Return_Merchandise_Authorisation__r.Address__r.Contact__c,Return_Merchandise_Authorisation__r.Return_Contact__c from Package__c where Id In  :packId  And Active__c = true');

            wrap.packItems = Database.query('select ' + String.escapeSingleQuotes(packageListFields) + ' ,Package__r.Name, Package__r.Description__c, Package__r.Weight_Unit__c, Package__r.Weight__c, Package__r.Order__c , Order_Product__r.Base_Price__c, '+
                                            +' Order_Product__r.Product2.SKU__c, Order_Product__r.Product2.Name, Work_Order_Line_Items__r.Product__r.Name, Purchase_Line_Items__r.Product__r.Name, Transfer_Order_Line_Item__r.Products__r.Name,RMA_Line_Item__r.Ord_Item__r.Product2.Name, '+
                                            +' Work_Order_Line_Items__r.Total_Cost__c, Work_Order_Line_Items__r.Unit_Price__c, Purchase_Line_Items__r.Total_Price__c, Purchase_Line_Items__r.Unit_Price__c, RMA_Line_Item__r.Total_Deduction__c, Order_Product__r.Total_Price__c, Order_Product__r.ReturnedQuantity__c, '+
                                            +' Order_Product__r.Order.Name ,Order_Product__r.UnitPrice, Order_Product__r.Product2.Goods_Description__c, Order_Product__r.Product2.Commodity_Code__c From Package_List__c where Package__c IN :packId');
        }
        if(wrap.packList.size() > 0){
            if(wrap.packList[0].Logistic__c != null){
                if(wrap.packList[0].Logistic__r.From_Address__c != null) {
                    wrap.fromAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Logistic__r.From_Address__c + '\' Limit 1');
                }
                if(wrap.packList[0].Logistic__r.To_Address__c != null){
                    wrap.toAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Logistic__r.To_Address__c + '\' Limit 1');
                }
                if(wrap.packList[0].Logistic__r.From_Contact__c != null){
                    wrap.fromContact = Database.query('select Id,Name,accountId,Account.Name,Account.Phone,Account.Email__c, Email, Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Logistic__r.From_Contact__c  + '\' Limit 1');
                }
                if(wrap.packList[0].Logistic__r.Contact__c != null){
                    wrap.toContact = Database.query('select Id,Name,accountId, Account.Name, Account.Phone,Email, Account.Email__c,Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Logistic__r.Contact__c + '\' Limit 1');
                }
            }
            else if(wrap.packList[0].Return_Merchandise_Authorisation__c != null){
                        System.debug('entered rma ups1 ');
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Address__c != null) {
                            System.debug('entered rma ups2');
                            wrap.fromAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Address__c + '\' Limit 1');
                            System.debug('fromAddress=>'+wrap.fromAddress);
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Site__r.Address__c != null){
                            wrap.toAddress = Database.query('select ' + addressFields + ' ,Contact__r.Name, Contact__r.Email, Contact__r.Phone, Contact__r.Company__c,Customer__r.Company_txt__c from Address__c where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Site__r.Address__c + '\' Limit 1');
                        	System.debug('toAddress=>'+wrap.toAddress);
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Address__r.Contact__c != null){
                            wrap.fromContact = Database.query('select Id,Name,accountId,Account.Name,Account.Phone,Account.Email__c, Email, Phone, Company__c,Company__r.Name from contact where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Address__r.Contact__c + '\' Limit 1');
                        	System.debug('fromContact=>'+wrap.fromContact);
                        }
                        if(wrap.packList[0].Return_Merchandise_Authorisation__r.Return_Contact__c != null){
                            wrap.toContact = Database.query('select Id,Name,accountId, Account.Name, Account.Phone,Email, Account.Email__c,Phone, Company__c, Company__r.Name from contact where Id =\'' + wrap.packList[0].Return_Merchandise_Authorisation__r.Return_Contact__c + '\' Limit 1');
                        	System.debug('toContact=>'+wrap.toContact);
                        }
                    }
        	}

       credentialsWrap creds = new credentialsWrap();
        String credentialFields = UtilClass.selectStarFromSObject('Credentials__c');

        // Get the name from the label
        string upsname = system.label.UPSRESTAPIName;
        system.debug('1. Searching for Credential Name: ' + upsname);

        // Initialize list to handle "List has no rows" safely
        List<Credentials__c> credList = Database.query('select ' + String.escapeSingleQuotes(credentialFields) + ' from Credentials__c where Name =:upsname And Active__c = true Limit 1');

        if(credList.size() > 0){
            creds.upsCredentials = credList[0];
            system.debug('2. Credentials Found: ' + creds.upsCredentials.Id);
            
            creds.clientId = creds.upsCredentials.Parent_Key__c;
            creds.clientSecret = creds.upsCredentials.Parent_Password__c;
            creds.accNumber = creds.upsCredentials.UPS_Account_Number__c;
            creds.endPoint = creds.upsCredentials.URL__c;
           
        } else {
            // Detailed Debugging to help you fix it
            system.debug('ERROR: No Credentials found.'); 
            system.debug('Check 1: Does a Credentials__c record exist with Name = "' + upsname + '"?');
            system.debug('Check 2: Is that record marked Active__c = true?');
            
            wrap.error = 'No Active UPS Credentials found. Expected Name: [' + upsname + ']. Please contact system administrator.';
        }
         wrap.credsWrap = creds;
        Functionality_Control__c FC = new Functionality_Control__c();
        FC = Functionality_Control__c.getValues(userInfo.getuserid());
        if(FC == null){ FC = Functionality_Control__c.getValues(userInfo.getProfileId());   if(FC==null) FC = Functionality_Control__c.getInstance();  }
        if(FC != null){
          wrap.disableBillingDetails = FC.Allow_Billing_details_edit_in_Ship_scree__c;
            wrap.allowReturnShipment = FC.allowUPSreturnShipment__c;
                wrap.allowFedExReturnShipmentFromUPS = FC.allowFedExReturnShipmentFromUPS__c;
        }
        System.debug('wrap : ' + wrap);
        return wrap;
    //return null;
    }
    global class Wrapper{
        @AuraEnabled global List<selectOptions> qvNotification {get;set;}
        @AuraEnabled global List<selectOptions> CarbonNeutral {get;set;}
        @AuraEnabled global List<selectOptions> COD            {get;set;}
        @AuraEnabled global List<selectOptions> DryIce         {get;set;}
        @AuraEnabled global List<selectOptions> ReturnService   {get;set;}
        @AuraEnabled global List<selectOptions>  SaturdayDelivery {get;set;}
        @AuraEnabled global List<selectOptions>  AdditionalHandling {get;set;}
        @AuraEnabled global List<selectOptions>  VerbalConfirmation {get;set;}

        @AuraEnabled global List<selectOptions> DeliveryConfirmation {get;set;}
        @AuraEnabled global List<selectOptions> StatusConfirmation {get;set;}
        @AuraEnabled global List<selectOptions> PucConfirmation            {get;set;}
        @AuraEnabled global List<selectOptions> IfConfirmation         {get;set;}
        @AuraEnabled global List<selectOptions> TosConfirmation   {get;set;}
        @AuraEnabled global List<selectOptions>  RfeConfirmation {get;set;}
        @AuraEnabled global List<selectOptions>  BillingOptions {get;set;}
        @AuraEnabled global credentialsWrap credsWrap {get;set;}
        @AuraEnabled global List<Package__c> packList {get;set;}
        @AuraEnabled global List<Package_List__c> packItems {get;set;}
        @AuraEnabled global Shipment__c ship{get;set;}
        @AuraEnabled global Shipment__c returnShip{get;set;}
        @AuraEnabled global Address__c fromAddress{get;set;}
        @AuraEnabled global contact fromContact{get;set;}
        @AuraEnabled global Address__c toAddress{get;set;}
        @AuraEnabled global contact toContact{get;set;}
        @AuraEnabled global Shipment__c shipment{get;set;}
        @AuraEnabled global string request {get;set;}
        @AuraEnabled global string response {get;set;}
        @AuraEnabled global string error {get;set;}
        @AuraEnabled global List<attachment> AttachList {get;set;}
        @AuraEnabled global List<trackwrapper> trackWrap {get;set;}
        @AuraEnabled global List<Shipment_Flow__c>  Shipmentflows{get;set;}
        @AuraEnabled global Boolean disableBillingDetails  {get;set;}
        @AuraEnabled global Boolean allowReturnShipment  {get;set;}
         @AuraEnabled global Boolean allowFedExReturnShipmentFromUPS {get;set;}
        @AuraEnabled public List<String> alertlist {get;set;}
        global Wrapper(){
            alertlist = new List<String>();
            disableBillingDetails = true;
            Shipmentflows = new List<Shipment_Flow__c>();
            trackWrap = new List<trackwrapper>();
            shipment = new Shipment__c();
            returnShip = new Shipment__c();
            toContact = new contact();
            fromContact = new contact();
            fromAddress = new Address__c();
            toAddress = new Address__c();
            ship = new Shipment__c();
            packItems = new List<Package_List__c>();
            packList = new List<Package__c>();
            credsWrap = new credentialsWrap();
            qvNotification = new List<selectOptions>();
            CarbonNeutral = new List<selectOptions>();
            COD = new List<selectOptions>();
            DryIce =  new List<selectOptions>();
            ReturnService = new List<selectOptions>();
            SaturdayDelivery = new List<selectOptions>();
            AdditionalHandling = new List<selectOptions>();
            VerbalConfirmation  = new List<selectOptions>();
            BillingOptions  = new List<selectOptions>();

            RfeConfirmation = new List<selectOptions>();
            TosConfirmation = new List<selectOptions>();
            IfConfirmation =  new List<selectOptions>();
            PucConfirmation = new List<selectOptions>();
            StatusConfirmation = new List<selectOptions>();
            DeliveryConfirmation = new List<selectOptions>();
            AttachList = new List<attachment>();

        }
    }
    global class credentialsWrap{
        @AuraEnabled global Credentials__c  upsCredentials {get;set;}
        @AuraEnabled global String  clientId {get;set;}
        @AuraEnabled global String  clientSecret {get;set;}
        @AuraEnabled global String  accNumber {get;set;}
        @AuraEnabled global String  endPoint {get;set;}
        global credentialsWrap(){
            upsCredentials= new Credentials__c();
            clientId = clientSecret = accNumber = endPoint = '';

        }
    }
    public class selectOptions{
        @AuraEnabled public string value {get;set;}
        @AuraEnabled public string label {get;set;}
        public selectOptions(){
            value = label = '';
        }
        public selectOptions(string label,String value){
            this.value = value;
            this.label = label;
        }

    }
    global class rateWrap{
        @AuraEnabled global string code {get;set;}
        @AuraEnabled global string service {get;set;}
        @AuraEnabled global string currencycode {get;set;}
        @AuraEnabled global decimal totalCharges {get;set;}
        @AuraEnabled global decimal countNum {get;set;}
        @AuraEnabled global decimal serviceCharges {get;set;}
        @AuraEnabled global string deliverydate {get;set;}

        global rateWrap(){
            countNum = 0;
            code = service = deliverydate = currencycode = '';
            totalCharges = serviceCharges = 0;

        }
    }
    global class mainWrap{
        @AuraEnabled global string request {get;set;}
        @AuraEnabled global string response {get;set;}
        @AuraEnabled global string error {get;set;}
        @AuraEnabled global List<rateWrap> ratesList {get;set;}
        @AuraEnabled global List<String> alertlist {get;set;}
        global mainWrap(){
            request = response = error = '';
            ratesList = new List<rateWrap>();
            alertlist = new List<String>();
        }

    }
    public class addressWrap{
        @AuraEnabled public string line1 {get;set;}
        @AuraEnabled public string line2 {get;set;}
        @AuraEnabled public string line3 {get;set;}
        @AuraEnabled public string companyName {get;set;}
        @AuraEnabled public string contact {get;set;}
        @AuraEnabled public string email {get;set;}
        @AuraEnabled public string phone {get;set;}
        @AuraEnabled public string city {get;set;}
        @AuraEnabled public string province {get;set;}
        @AuraEnabled public string postalCode {get;set;}
        @AuraEnabled public string country {get;set;}
        @AuraEnabled public string residential {get;set;}

    }
    public class trackwrapper {
        @AuraEnabled public String tDate { get; set; }
        @AuraEnabled public String tTime { get; set; }
        @AuraEnabled public String location { get; set; }
        @AuraEnabled public DateTime dtValue { get; set; }
        @AuraEnabled public String activityDesp { get; set; }
        @AuraEnabled public String dateTimeString { get; set; }
        @AuraEnabled public String SignedForByName { get; set; }

        public trackwrapper() {
            tDate = '';
            tTime = '';
            location = '';
            activityDesp = '';
            dateTimeString = '';
            SignedForByName = '';
        }
    }
    global class rateWrapper {
        @AuraEnabled global Date DeliveryDate                   { get; set; }
        @AuraEnabled global String ServiceCode                  { get; set; }
        @AuraEnabled global String totalCharges                 { get; set; }
        @AuraEnabled global String currencyCode                 { get; set; }
        @AuraEnabled global String DeliveryDateS                { get; set; }
        @AuraEnabled global String ServiceManual                { get; set; }
        @AuraEnabled global String negotiatedCharges            { get; set; }
        @AuraEnabled global String TransportationCharges        { get; set; }
        @AuraEnabled global String ServiceOptionsCharges        { get; set; }
        @AuraEnabled global String ScheduledDeliveryTime        { get; set; }
        @AuraEnabled global String GuaranteedDaysToDelivery     { get; set; }

        global rateWrapper() {
            ServiceManual = '';
            ServiceCode = '';
            totalCharges = '';
            currencyCode = '';
            DeliveryDate = null;
            DeliveryDateS = '';
            negotiatedCharges = '';
            TransportationCharges = '';
            ServiceOptionsCharges = '';
            ScheduledDeliveryTime = '';
            GuaranteedDaysToDelivery = '';
        }
    }
    @AuraEnabled
    public static List<plWrapper> packListWrapper                { get; set; }
    public class plWrapper {
        @AuraEnabled public Package_List__c pl                   { get; set; }
        @AuraEnabled public String commodityCode                 { get; set; }
        @AuraEnabled public Decimal declaredValue                { get; set; }
        @AuraEnabled public String goodsDescription              { get; set; }
        @AuraEnabled public Product2 psa                         { get; set; }

        public plWrapper() {
            declaredValue = 0;
            commodityCode = '';
            goodsDescription = '';
            pl = new Package_List__c();
            psa = new Product2();
        }
    }
    public class upsWrapper{
        @AuraEnabled public String UPSErrorMsg                         { get; Set; }
        @AuraEnabled public String Error                               { get; Set; }
        @AuraEnabled public String Result                              { get; Set; }
        @AuraEnabled public Boolean time_in_cost_tab                   { get; set; }
        @AuraEnabled public Transient List<rateWrapper> Services                 { get; Set; }
        @AuraEnabled public Transient List<trackwrapper> trackServices           { get; Set; }
        @AuraEnabled public Transient List<plWrapper> plWrap                     { get; Set; }
        @AuraEnabled public Shipment__c Shipment                       { get; set; }
        @AuraEnabled public Attachment spodLetter                      { get; set; }
        @AuraEnabled public Boolean showAndHideMap1                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap2                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap3                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap4                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap5                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap6                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap7                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap8                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap9                    { get; set; }
        @AuraEnabled public Boolean showAndHideMap10                   { get; set; }
        @AuraEnabled public Boolean showAndHideMap11                   { get; set; }
        @AuraEnabled public Boolean showAndHideMap12                   { get; set; }
        @AuraEnabled public Integer noOfimgs                           { get; set; }
        @AuraEnabled public Transient List<String> imgslist                      { get; set; }
        @AuraEnabled public Boolean showreturnlabel                   { get; set; }
        @AuraEnabled public Transient String responseStr                         { get; Set; }
        @AuraEnabled public Transient String  request                             { get; Set; }
        @AuraEnabled public List<ratesWrap> rates { get; set; }
        public upsWrapper(){
            UPSErrorMsg = responseStr = request = '';
            Error = '';
            Result = '';
            plWrap = new List<plWrapper>();
            Services = new List<rateWrapper>();
            trackServices = new List<trackwrapper>();
            time_in_cost_tab = false;
            Shipment = new Shipment__c();
            spodLetter = new Attachment();
            showAndHideMap1 = false;
            showAndHideMap2 = false;
            showAndHideMap3 = false;
            showAndHideMap4 = false;
            showAndHideMap5 = false;
            showAndHideMap6 = false;
            showAndHideMap7 = false;
            showAndHideMap8 = false;
            showAndHideMap9 = false;
            showAndHideMap10 = false;
            showAndHideMap11 = false;
            showAndHideMap12 = false;
            noOfimgs = 0;
            imgslist = new List<String>();
            showreturnlabel = false;
            rates= new List<ratesWrap>();
        }
    }
    public class myConstructorWrapper{
        @AuraEnabled public List<Credentials__c> upsCredentials                       { get; set; }
        @AuraEnabled public Map<String, UPS_Package_Type__c> packageTypeMap    { get; set; }
        @AuraEnabled public String userName                                    { get; set; }
        @AuraEnabled public String Key                                         { get; set; }
        @AuraEnabled public String password                                    { get; set; }
        @AuraEnabled public String endPoint                                    { get; set; }
        @AuraEnabled public String meterNumber                                 { get; set; }
        @AuraEnabled public String accountNumber                               { get; set; }
        @AuraEnabled public String shipperProvinceCode                         { get; set; }
        @AuraEnabled public String shipperCountryCode                          { get; set; }
        @AuraEnabled public Shipment__c Shipment                         { get; set; }
        @AuraEnabled public Shipment__c returnShipment                               { get; set; }
        @AuraEnabled public List<Package__c> Packages                    { get; set; }
        @AuraEnabled public Address__c fromAddress                             { get; set; }
        @AuraEnabled public Address__c toAddress                               { get; set; }
        @AuraEnabled public string shipmentFields                              { get; set; }
        @AuraEnabled public String LabelWidth                                  { get; set; }
        @AuraEnabled public String LabelHeight                                 { get; set; }
        @AuraEnabled public Transient List<String> shipmentImageLists                           { get; set; }
        @AuraEnabled public upsWrapper uWrap                                   { get; set; }
        @AuraEnabled public String wrapError                                   { get; set; }
        @AuraEnabled public  Boolean allowReturnShipment                       { get; set; }
        @AuraEnabled public  Boolean allowFedExReturnShipmentFromUPS                       { get; set; }
        @AuraEnabled public  Boolean disableEditBillOptReturnShipment                      { get; set; }
        @AuraEnabled public  Boolean showeditBillDetails                       { get; set; }

        public myConstructorWrapper(){
            upsCredentials = new List<Credentials__c>();
            shipmentImageLists = new List<String>();
            allowReturnShipment = allowFedExReturnShipmentFromUPS = disableEditBillOptReturnShipment = false;
            userName = Key = password = endPoint = meterNumber = accountNumber = shipperProvinceCode = shipperCountryCode = shipmentFields = LabelWidth = LabelHeight = wrapError = '';
            Shipment = returnShipment = new Shipment__c();
            Packages = new List<Package__c>();
            fromAddress = new Address__c();
            toAddress = new Address__c();
            uWrap = new upsWrapper();
        }
    }
    @AuraEnabled
    public static String getStreet(String AddressLine1, String AddressLine2, String AddressLine3) {
        if((AddressLine1 != Null && AddressLine1 != '') && (AddressLine2 != Null && AddressLine2 != '') && (AddressLine3 != Null && AddressLine3 != '')) {
            return AddressLine1 +', '+ AddressLine2 +', '+ AddressLine3; }
        else if((AddressLine1 != Null && AddressLine1 != '') && (AddressLine2 != Null && AddressLine2 != '')) { return AddressLine1 +', '+ AddressLine2; }
        else if(AddressLine1 != Null && AddressLine1 != '') { return AddressLine1; }
        else return '';
    }
     @AuraEnabled
    public static upsWrapper Pickup_Rate_Request(String fromAdd, String toAdd, String Shipment, DateTime dispatchDate, DateTime PackageReadyTime, DateTime CustomerCloseTime, String myConsVar){
        System.debug('Inside Pickup_Rate_Request');
        upsWrapper upsW = new upsWrapper(); 
        
        //myConstructorWrapper myConsW = (myConstructorWrapper) JSON.deserialize(myConsVar, myConstructorWrapper .class);
        credentialsWrap myConsW = (credentialsWrap) JSON.deserialize(myConsVar, credentialsWrap.class);
        Shipment__c Ship = (Shipment__c) JSON.deserialize(Shipment, Shipment__c.class);
        
        DateTime dt = datetime.valueOf(dispatchDate).adddays(1); 
        String shipmentDispatchDate = dt.format('yyyyMMdd');
        
        DateTime dt1 = datetime.valueOf(PackageReadyTime).adddays(1); 
        String shipmentPackageReadyTime = dt1.format('HHmm');
        
        DateTime dt2 = datetime.valueOf(CustomerCloseTime).adddays(1); 
        String shipmentCustomerCloseTime = dt2.format('HHmm');
        
        String DestinationCountryCode = ''; String DestinationProvinceCode = ''; 
        String originStreet = '', originCountryCode = '', originProvinceCode = '';
        String errMsg = '', errorMsg = '';
        
        Address__c fromAddress = [Select Id, Name, Customer__c, Contact__c, Active__c,Customer__r.Company__c,Customer__r.Phone,Customer__r.Email__c,
                                        Is_Shipping_Address__c, Is_Billing_Address__c, Address_Line1__c,
                                        Address_Line2__c, Address_Line3__c, City__c, Country__c,
                                        State__c, Postal_Code__c, Contact__r.Company__c, Contact__r.Name,
                                        Contact__r.Email, Contact__r.Phone from Address__c where ID=:fromAdd limit 1];
        
        if(fromAddress != null) {
            if(getProvinceCode(fromAddress.State__c) != '') originProvinceCode = getProvinceCode(fromAddress.State__c); else errorMsg = 'UPS Shipping Service Unavailable : Origin Province Code not found';            
            if(getCountryCode(fromAddress.Country__c) != '') originCountryCode = getCountryCode(fromAddress.Country__c); else errorMsg = 'UPS Shipping Service Unavailable : Origin Country Code not found';            
            if(getStreet(fromAddress.Address_Line1__c, fromAddress.Address_Line2__c, fromAddress.Address_Line3__c) != '') originStreet = getStreet(fromAddress.Address_Line1__c, fromAddress.Address_Line2__c, fromAddress.Address_Line3__c);
        }
        
        Address__c toAddress = [Select Id, Name, Customer__c, Contact__c, Active__c,Customer__r.Company__c,Customer__r.Phone,Customer__r.Email__c,
                                      Is_Shipping_Address__c, Is_Billing_Address__c, Address_Line1__c,
                                      Address_Line2__c, Address_Line3__c, City__c, Country__c,
                                      State__c, Postal_Code__c, Contact__r.Company__c, Contact__r.Name,
                                      Contact__r.Email, Contact__r.Phone from Address__c where ID=:toAdd];
        
        List<Country_Codes__c> toLstcountryCodes = [Select Id, Name, Code__c, Country__c From Country_Codes__c Where Country__c =: toAddress.Country__c Limit 1];            
        if(toLstcountryCodes.size() > 0) DestinationCountryCode = toLstcountryCodes[0].Code__c;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://onlinetools.ups.com/rest/PickupRate');//myConsW.endpoint + '/webservices/Pickup';
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        //req.setHeader('Accept', 'application/json');
        //req.setHeader('AccessLicenseNumber', 'YOUR_ACCESS_LICENSE_NUMBER');
        String accesstoken =getAccessToken(myConsW.clientId,myConsW.clientSecret,myConsW.accNumber,myConsW.endPoint);
        req.setHeader('Authorization', 'Bearer '+accesstoken);
        req.setHeader('TransactionSrc', 'Testing');
        req.setHeader('TransID', 'Testing');
        //req.setHeader('Username', 'YOUR_USERNAME');
        //req.setHeader('Password', 'YOUR_PASSWORD');
        
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject(); // Start of the main object
        gen.writeFieldName('PickupRateRequest');
        gen.writeStartObject(); // Start of 'PickupRateRequest' object
        
        gen.writeFieldName('PickupAddress');
        gen.writeStartObject(); // Start of 'PickupAddress' object
        gen.writeStringField('AddressLine', originStreet);
        gen.writeStringField('City', fromAddress.City__c);
        gen.writeStringField('StateProvince', 'NJ');
        gen.writeStringField('PostalCode', originProvinceCode);
        gen.writeStringField('CountryCode', originCountryCode);
        gen.writeStringField('ResidentialIndicator', 'Y');
        gen.writeEndObject(); // End of 'PickupAddress' object
        
        gen.writeStringField('AlternateAddressIndicator', 'N');
        gen.writeStringField('ServiceDateOption', '02');
        
        gen.writeFieldName('PickupDateInfo');
        gen.writeStartObject(); // Start of 'PickupDateInfo' object
        gen.writeStringField('CloseTime', shipmentCustomerCloseTime);
        gen.writeStringField('ReadyTime', shipmentPackageReadyTime);
        gen.writeStringField('PickupDate', shipmentDispatchDate);
        gen.writeEndObject(); // End of 'PickupDateInfo' object
        
        gen.writeEndObject(); // End of 'PickupRateRequest' object
        gen.writeEndObject(); // End of main object
        
        // Serialize the JSON generator content to string
        String jsonString = gen.getAsString();
        System.debug(jsonString);
        
        // Set the request body
        req.setBody(jsonString);
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if(Test.isRunningTest()){
            res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"RateResponse": {"RatedShipment": [{"Service": {"Code": "01", "Description": "UPS Ground"}, "TotalCharges": {"MonetaryValue": "10.00", "CurrencyCode": "USD"}, "ServiceOptionsCharges": {"MonetaryValue": "2.00", "CurrencyCode": "USD"}, "TransportationCharges": {"MonetaryValue": "8.00", "CurrencyCode": "USD"}, "GuaranteedDaysToDelivery": "3"}]}}');
            res.setStatusCode(200);

         }else{
         res = http.send(req);
         }
        
        // Parse the response
          System.debug('Outside success 200');
        if (res.getStatusCode() == 200) {
            System.debug('Inside success 200');
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());//JSON.deserializeUntyped(res);
            Map<String, Object> rateResponse = (Map<String, Object>) parsedResponse.get('RateResponse');
            
            List<Object> ratedShipments = new List<Object>();
            if (rateResponse.get('RatedShipment') instanceof List<Object>) {
                ratedShipments = (List<Object>) rateResponse.get('RatedShipment');
            } else if (rateResponse.get('RatedShipment') instanceof Map<String, Object>) {
                ratedShipments.add(rateResponse.get('RatedShipment'));
            }
            
            List<UPS_Service_Codes__c> serviceCodes = [select Id, Name, Service__c, ServiceCode__c, Service_Code_With_Trade_Mark__c, Service_Asia_International__c, Service_Canada_Domestic__c, Service_USA_Domestic__c, 
                                                       Service_Canada_International__c, Service_Europe__c, Service_Mexico_Domestic__c, Service_Mexico_International__c from UPS_Service_Codes__c limit 22];
            Map<String, UPS_Service_Codes__c> serviceCodesMap = new Map<String, UPS_Service_Codes__c>();
            for (UPS_Service_Codes__c service1 : serviceCodes) {
                serviceCodesMap.put(service1.ServiceCode__c, service1);
            }
            List<ratesWrap> rates = new List<ratesWrap>();
            Integer i = 0;
            for (Object shipment1 : ratedShipments) {
                ratesWrap rate = new ratesWrap();
                Map<String, Object> shipmentMap = (Map<String, Object>) shipment1;
                i++;
                
                // Service Code
                String serviceCode1 = (String) ((Map<String, Object>) shipmentMap.get('Service')).get('Code');
                
                // Transportation Charges
                Map<String, Object> transportationCharges = (Map<String, Object>) shipmentMap.get('TransportationCharges');
                String transportationMonetaryValue = (String) transportationCharges.get('MonetaryValue');
                String transportationCurrencyCode = (String) transportationCharges.get('CurrencyCode');
                
                // Service Options Charges
                Map<String, Object> serviceOptionsCharges = (Map<String, Object>) shipmentMap.get('ServiceOptionsCharges');
                String serviceOptionsMonetaryValue = (String) serviceOptionsCharges.get('MonetaryValue');
                String serviceOptionsCurrencyCode = (String) serviceOptionsCharges.get('CurrencyCode');
                
                // Total Charges
                Map<String, Object> totalCharges = (Map<String, Object>) shipmentMap.get('TotalCharges');
                String totalMonetaryValue = (String) totalCharges.get('MonetaryValue');
                String totalCurrencyCode = (String) totalCharges.get('CurrencyCode');
                
                // Guaranteed Days To Delivery (if exists)
                String guaranteedDaysToDelivery = '';
                if (shipmentMap.containsKey('GuaranteedDaysToDelivery')) {
                    guaranteedDaysToDelivery = (String) shipmentMap.get('GuaranteedDaysToDelivery');
                }
                
                // Rated Shipment Alerts
                List<Map<String, Object>> ratedShipmentAlerts = new List<Map<String, Object>>();
                if (shipmentMap.containsKey('RatedShipmentAlert')) {
                    List<Object> alertList = (List<Object>) shipmentMap.get('RatedShipmentAlert');
                    for (Object alertObj : alertList) {
                        ratedShipmentAlerts.add((Map<String, Object>) alertObj);
                    }
                }
                
                // Output the parsed values
                System.debug('Service Code: ' + serviceCode1);
                System.debug('Transportation Charges: ' + transportationMonetaryValue + ' ' + transportationCurrencyCode);
                System.debug('Service Options Charges: ' + serviceOptionsMonetaryValue + ' ' + serviceOptionsCurrencyCode);
                System.debug('Total Charges: ' + totalMonetaryValue + ' ' + totalCurrencyCode);
                System.debug('Guaranteed Days To Delivery: ' + guaranteedDaysToDelivery);
                
                // Output the rated shipment alerts and add to the list if not already present
                for (Map<String, Object> alert : ratedShipmentAlerts) {
                    String alertCode = (String) alert.get('Code');
                    String alertDescription = (String) alert.get('Description');
                    System.debug('Rated Shipment Alert Code: ' + alertCode);
                    System.debug('Rated Shipment Alert Description: ' + alertDescription);
                    if (!rate.alertlist.contains('Alert  : ' + alertDescription)) {
                        rate.alertlist.add('Alert  : ' + alertDescription);
                    }
                }
                
                rate.code = serviceCode1;
                rate.countNum = i;
                rate.service = serviceCodesMap.containsKey(serviceCode1) ? serviceCodesMap.get(serviceCode1).Service__c : '';
                rate.totalCharges = Decimal.valueOf(totalMonetaryValue);
                rate.currencycode = totalCurrencyCode;
                rate.serviceCharges = Decimal.valueOf(serviceOptionsMonetaryValue);
                rate.deliverydate = guaranteedDaysToDelivery;
                rates.add(rate);
            }
            upsW.rates = rates;
        }
        
        else {
            upsW.UPSErrorMsg = 'Error: HTTP response status code ' + res.getStatusCode();
        }
        
        return upsW;
    }
   
    public class ratesWrap {
        @AuraEnabled
        public Integer countNum { get; set; }

        @AuraEnabled
        public String code { get; set; }

        @AuraEnabled
        public String service { get; set; }

        @AuraEnabled
        public Decimal totalCharges { get; set; }

        @AuraEnabled
        public String currencycode { get; set; }

        @AuraEnabled
        public Decimal serviceCharges { get; set; }

        @AuraEnabled
        public String deliverydate { get; set; }

        @AuraEnabled
        public List<String> alertlist { get; set; }

        public ratesWrap() {
            alertlist = new List<String>();
        }
    }



}