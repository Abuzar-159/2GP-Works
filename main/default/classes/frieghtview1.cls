public with sharing class frieghtview1 {
   
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
                wrap.packItems = Database.query('SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packageIds' );


                List<Shipment__c> Shipslist = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = false AND Active__c = true And Id=\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\' And RecordTypeId =\'' + String.escapeSingleQuotes(ShipmentRecTypeId) + '\') Limit 1');
                if(Shipslist.size() > 0) wrap.ship  = Shipslist[0];
                else wrap.alertlist.add('Shipment is Either Cancelled or not availbale in the system');
                List<Shipment__c> returnShips = Database.query('select ' + String.escapeSingleQuotes(shipfields) + ' ,Return_Merchandise_Authorisation__r.Address__c,Billing_Address__r.Id,Billing_Address__r.Name from Shipment__c where (Return_Shipment__c = true AND Active__c = true And Master_Shipment__c =\'' + String.escapeSingleQuotes(shipId) + '\' And Status__c != \'Cancelled\') Limit 1');
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
                    'SELECT ' + String.escapeSingleQuotes(packageListFields) + ', ' +'Package__r.Name, ' +'Logistic_Line_Item__r.Product__c, ' +'Logistic_Line_Item__r.Product__r.Weight__c, ' +'Package__r.Description__c, ' +'Package__r.Weight_Unit__c, ' +'Package__r.Weight__c, ' +'Package__r.Order__c, ' +'Order_Product__r.Base_Price__c, ' +'Order_Product__r.Product2.SKU__c, ' +'Order_Product__r.Product2.Name, ' +'Order_Product__r.Product2.Declared_Shipment_Value__c, ' +'Work_Order_Line_Items__r.Product__r.Name, ' +'Purchase_Line_Items__r.Product__r.Name, ' +'Transfer_Order_Line_Item__r.Products__r.Name, ' +'RMA_Line_Item__r.Ord_Item__r.Product2.Name, ' +'Work_Order_Line_Items__r.Total_Cost__c, ' +'Work_Order_Line_Items__r.Unit_Price__c, ' +'Purchase_Line_Items__r.Total_Price__c, ' +'Purchase_Line_Items__r.Unit_Price__c, ' +'RMA_Line_Item__r.Total_Deduction__c, ' +'Order_Product__r.Total_Price__c, ' +'Order_Product__r.ReturnedQuantity__c, ' +'Order_Product__r.Order.Name, ' +'Order_Product__r.UnitPrice, ' +'Order_Product__r.Product2.Goods_Description__c, ' +'Order_Product__r.Product2.Commodity_Code__c ' +'FROM Package_List__c ' +'WHERE Package__c IN :packId');
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


}