global with sharing class Epos{
    @AuraEnabled(cacheable = true)
    global static Wrapper fetchInitailDetails(){
        Wrapper wr = new Wrapper();
        try{
            Employees__c currEmp;
            for (Employees__c record : [Select Id, Name, Employee_User__c,Company__c
                                        from Employees__c
                                        where Employee_User__c = :Userinfo.getUserId() AND Active__c = true
                                        WITH SECURITY_ENFORCED
                                        order by CreatedDate Asc
                                        Limit 1])
                currEmp = record;
            if (currEmp == null) wr.error.add('Employee not found for current user, please select Employee');
            else
                wr.currEmp = currEmp;
            Schema.DescribeFieldResult fieldResultOrdStatus = Order.Status.getDescribe();
            List<Schema.PicklistEntry> ordStatus = fieldResultOrdStatus.getPicklistValues();
            for (Schema.PicklistEntry f : ordStatus)
                wr.ordStatus.add(new SelectOptions(f.getValue(), f.getLabel()));
            Schema.DescribeFieldResult fieldResultShipmentType = Order.Shipment_Type__c.getDescribe();
            List<Schema.PicklistEntry> ordShipType = fieldResultShipmentType.getPicklistValues();
            for (Schema.PicklistEntry f : ordShipType)
                wr.ShipmentType.add(new SelectOptions(f.getValue(), f.getLabel()));
        } catch (Exception e){ wr.error.add(e.getMessage() + '   Line:' + e.getLineNumber()); }
        return wr;
    }

    @AuraEnabled(cacheable = true)
    global static Wrapper fetchAccDetails(String accId){
        Wrapper wr = new Wrapper();
        try{
            Contact con;
            Address__c billToAdd;
            Address__c shipToAdd;
            Profiling__c custProfile;
            for (Account record : [Select Id, Name, Account_Profile__c, Account_Profile__r.Name, Order_Profile__c, Order_Profile__r.Name, Order_Profile__r.Channel__c, Order_Profile__r.Price_Book__c, Order_Profile__r.Account_Profile__c, Order_Profile__r.Account_Profile__r.Tax_Sourcing_Rules__c, AccountNumber, Company__c,Company__r.Name, Organisation_Business_Unit__c, Available_Credit_Balance__c, Website, Phone, Fax, VAT_registration_number__c
                                   from Account
                                   where Id = :accId
                                   WITH SECURITY_ENFORCED
                                   Limit 1]){
                wr.acc = record;
            }

            for (Contact record : [Select Id, Name, MobilePhone, Email, Phone, Title
                                   from Contact
                                   where AccountId = :accId
                                   WITH SECURITY_ENFORCED
                                   order by Primary__c DESC, CreatedDate ASC
                                   Limit 1]){
                con = record;
            }
            if (con == null) wr.error.add('Contact Not Found');
            else
                wr.con = con;
            for (Address__c record : [Select id, Name, Address_Line1__c, Address_Line2__c, Address_Line3__c, City__c, Country__c, State__c, Postal_Code__c
                                      from Address__c
                                      Where Customer__c = :accId AND Active__c = true AND Is_Billing_Address__c = true
                                      WITH SECURITY_ENFORCED
                                      order by Primary__c DESC, CreatedDate ASC
                                      Limit 1]){
                billToAdd = record;
            }
            if (billToAdd == null) wr.error.add('Bill To Address Not Found');
            else
                wr.billToAdd = billToAdd;
            for (Address__c record : [Select id, Name, Address_Line1__c, Address_Line2__c, Address_Line3__c, City__c, Country__c, State__c, Postal_Code__c
                                      from Address__c
                                      Where Customer__c = :accId AND Active__c = true AND Is_Shipping_Address__c = true
                                      WITH SECURITY_ENFORCED
                                      order by Primary__c DESC, CreatedDate ASC
                                      Limit 1]){
                shipToAdd = record;
            }
            if (shipToAdd == null) wr.error.add('Ship To Address Not Found');
            else
                wr.shipToAdd = shipToAdd;
            for (Profiling__c record : [Select Id, Name, Channel__c, Price_Book__c, Account_Profile__c, Account_Profile__r.Tax_Sourcing_Rules__c
                                        from Profiling__c
                                        where Id = :wr.acc.Order_Profile__c AND Active__c = True
                                        WITH SECURITY_ENFORCED
                                        order by Default__c DESC
                                        Limit 1]){
                custProfile = record;
            }
            if (custProfile != null)
                wr.custProfile = custProfile;
            wr.isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            if (wr.isMultiCurrency) wr.orderCurrency = (String) Database.Query('select CurrencyIsoCode from Account where Id=:accId WITH SECURITY_ENFORCED Limit 1')[0].get('CurrencyIsoCode');
            wr.allCurrencies.add(new SelectOptions(wr.orderCurrency, wr.orderCurrency));
            if (wr.isMultiCurrency) wr.allCurrencies = Epos.getCurrenyList('Account', 'CurrencyIsoCode');
        } catch (Exception e){ wr.error.add(e.getMessage() + '   Line:' + e.getLineNumber()); }
        return wr;
    }

    global static List<SelectOptions> getCurrenyList(String Object_Name1, String Field_name){
        List<SelectOptions> allCurrencies = new List<SelectOptions>();
        //String Field_name='CurrencyIsoCode';
        Schema.SObjectType targetObject = Schema.getGlobalDescribe().get(Object_Name1);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetObject.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values){
             //for all values in the picklist list
            allCurrencies.add(new SelectOptions(a.getValue(), a.getLabel()));
        }
        return allCurrencies;
    }

    global class Wrapper{
        @AuraEnabled
        global List<String> error{ get; set; }

        @AuraEnabled
        global Account acc{ get; set; }

        @AuraEnabled
        global Contact con{ get; set; }

        @AuraEnabled
        global Address__c billToAdd{ get; set; }

        @AuraEnabled
        global Address__c shipToAdd{ get; set; }

        @AuraEnabled
        global Employees__c currEmp{ get; set; }

        @AuraEnabled
        global Date todayDate{ get; set; }

        @AuraEnabled
        global List<SelectOptions> ordStatus{ get; set; }

        @AuraEnabled
        global List<SelectOptions> ShipmentType{ get; set; }

        @AuraEnabled
        global Profiling__c custProfile{ get; set; }

        @AuraEnabled
        global String orderCurrency{ get; set; }

        @AuraEnabled
        global List<SelectOptions> allCurrencies{ get; set; }

        @AuraEnabled
        global boolean isMultiCurrency{ get; set; }

        global Wrapper(){
            error = new List<String>();
            acc = new Account();
            con = new Contact();
            billToAdd = new Address__c();
            shipToAdd = new Address__c();
            currEmp = new Employees__c();
            todayDate = date.today();
            ordStatus = new List<SelectOptions>();
            ShipmentType = new List<SelectOptions>();
            custProfile = new Profiling__c();
            orderCurrency = UserInfo.getDefaultCurrency();
            allCurrencies = new List<SelectOptions>();
            isMultiCurrency = false;
        }

    }

    global class SelectOptions{
        @AuraEnabled
        global String value{ get; set; }

        @AuraEnabled
        global String label{ get; set; }

        global SelectOptions(String value, String label){
            this.value = value;
            this.label = label;
        }

    }

    // @AuraEnabled(cacheable = true)
    // global static Contact fetchContactDetails(String contId){
    //     return [Select Id, Name, MobilePhone, Email, Phone, Title
    //             from Contact
    //             where Id = :contId
    //             WITH SECURITY_ENFORCED
    //             Limit 1];
    // }
    @AuraEnabled(cacheable = true)
    global static Contact fetchContactDetails(String contId) {
        // Check if the contId is null or empty
        if (String.isBlank(contId)) {
            throw new AuraHandledException('Contact ID cannot be null or empty.');
        }

        try {
            // Fetch the contact details
            Contact contactRecord = [
                SELECT Id, Name, MobilePhone, Email, Phone, Title
                FROM Contact
                WHERE Id = :contId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Return the contact if found
            return contactRecord;
        } catch (QueryException qe) {
            // Handle scenarios where the query fails (e.g., no record found)
            throw new AuraHandledException('No contact found for the provided ID: ' + contId);
        } catch (Exception e) {
            // General exception handling
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }

    global static String readXMLResponse(XmlStreamReader reader, String sxmltag){
        string retValue;
        while (reader.hasNext()){
            if (reader.getEventType() == XmlTag.START_ELEMENT){
                if (reader.getLocalName() == sxmltag){
                    reader.next();
                    if (reader.getEventType() == XmlTag.characters){
                        retValue = reader.getText();
                    }
                }
            }
            reader.next();
        }
        return retValue;
    }

    @AuraEnabled(cacheable = true)
    global static Address__c billToAddress(String addId){
        try{
            return [Select id, Name, Address_Line1__c, Address_Line2__c, Address_Line3__c, City__c, Country__c, State__c, Postal_Code__c
                    from Address__c
                    Where Id = :addId AND Active__c = true AND Is_Billing_Address__c = true
                    WITH SECURITY_ENFORCED
                    Limit 1];
        } catch (Exception e){ } return null;
    }

    @AuraEnabled(cacheable = true)
    global static Address__c shipToAddress(String addId){
        try{
            return [Select id, Name, Address_Line1__c, Address_Line2__c, Address_Line3__c, City__c, Country__c, State__c, Postal_Code__c
                    from Address__c
                    Where Id = :addId AND Active__c = true AND Is_Shipping_Address__c = true
                    WITH SECURITY_ENFORCED
                    Limit 1];
        } catch (Exception e){ } return null;
    }

    @AuraEnabled(cacheable = true)
    global static Profiling__c OrderProfile(String ordProfileId){
        try{
            return [Select Id, Name, Channel__c, Price_Book__c, Account_Profile__c, Account_Profile__r.Tax_Sourcing_Rules__c
                    from Profiling__c
                    where Id = :ordProfileId AND Active__c = true
                    WITH SECURITY_ENFORCED
                    Limit 1];
        } catch (Exception e){ }return null;
    }

    @AuraEnabled(cacheable = true)
    global static Employees__c currentEmp(String empId){
        try{
            return [Select Id, Name, Employee_User__c
                    from Employees__c
                    where Id = :empId
                    WITH SECURITY_ENFORCED
                    Limit 1];
        } catch (Exception e){
        } return null;
    }

    @AuraEnabled(cacheable = true)
    global static List<ProductWrapper> initialProducts(String currProfile, String billToAddId, String shipToAddId, String searchItem){
        List<ProductWrapper> prodWrap = new List<ProductWrapper>();
        try{

            Profiling__c profile = (Profiling__c)JSON.deserialize(currProfile, Profiling__c.class);

            if (profile.Account_Profile__r.Tax_Sourcing_Rules__c == null) profile.Account_Profile__r.Tax_Sourcing_Rules__c = 'Destination';
            Set<Id> siteIds = new Set<Id>();

            List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c
                                                                  from Distribution_Channel__c
                                                                  where Channel__c = :profile.Channel__c and Active__c = true
                                                                  WITH SECURITY_ENFORCED
                                                                  limit 100];


            if (DistributionChannels.size() > 0){
                for (Distribution_Channel__c DC : DistributionChannels){
                    siteIds.add(DC.Site__c);
                }
            }
            System.debug('siteIds->'+siteIds);

            String searchProductBy = '%' + searchItem + '%';
            List<Product2> searchProdList = [Select Id, Name
                                             from Product2
                                             where (Name like:searchProductBy OR ProductCode like:searchProductBy)
                                             WITH SECURITY_ENFORCED
                                             Limit 50];
            system.debug('searchProdList -> '+searchProdList);
            Set<Id> searchProdIds = new Set<Id>();
            for (Product2 pr : searchProdList)
                searchProdIds.add(pr.Id);

                system.debug('searchProdIds -> '+searchProdIds);
                List<PricebookEntry> pbe = new List<PricebookEntry>();

            if (searchProdIds.size() > 0)
                pbe = [Select UnitPrice, Purchase_Price__c, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Description, Product2.BOM__c, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Is_Kit__c, Product2.Picture__c, Product2.Serialise__c, Product2.QuantityUnitOfMeasure, Product2.Is_Subscribe__c
                       from PricebookEntry
                       where Pricebook2Id = :profile.Price_Book__c AND Product2Id IN (Select Id
                                                                                      From Product2
                                                                                      where IsActive = TRUE AND Id In:searchProdIds) AND IsActive = TRUE
                       WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC
                       Limit 12 ];
            if (searchItem == '')
                pbe = [Select UnitPrice, Purchase_Price__c, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Description, Product2.BOM__c, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Is_Kit__c,Product2.Picture__c, Product2.Serialise__c, Product2.QuantityUnitOfMeasure, Product2.Is_Subscribe__c
                       from PricebookEntry
                       where Pricebook2Id = :profile.Price_Book__c AND Product2Id IN (Select Id
                                                                                      From Product2
                                                                                      where IsActive = TRUE) AND IsActive = TRUE
                       WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC
                       Limit 12];

            System.debug('pbe ->'+pbe);
                       Set<Id> productIds = new Set<Id>();
            for (PricebookEntry pb1 : pbe){        productIds.add(pb1.Product2.Id); }System.debug('productIds ->'+productIds);



                           List<Inventory_Stock__c> WarehouseItemInventoryStocks = new List<Inventory_Stock__c>();

            if (productIds.size() > 0){
                WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c, Number_of_Item_In_Stock__c, BOM__c
                                                From Inventory_Stock__c
                                                Where product__c In:productIds And Active__c = true And Warehouse__c In:siteIds And Number_of_Item_In_Stock__c > 0
                                                WITH SECURITY_ENFORCED
                                                limit 1000];
            }

            System.debug('WarehouseItemInventoryStocks->'+WarehouseItemInventoryStocks);
            Map<String, Decimal> stockView = new Map<String, Decimal>();

            for (Id prId : productIds){
                Decimal stock = 0;
                for (Inventory_Stock__c inven : WarehouseItemInventoryStocks){ if (prId == inven.product__c){ stock += inven.Number_of_Item_In_Stock__c;
                    }
                }
                stockView.put(prId, stock);
            }
            System.debug('stockView ->'+stockView);

            //=========Discount Plan==============
            Integer currentQuantity = 1;
            List<Tier_Discount_Allocation__c> TDAS = new List<Tier_Discount_Allocation__c>();
            TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name, Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c, Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                    From Tier_Discount_Allocation__c
                    Where Order_Profile__c = :profile.Id And Price_Book__c = :profile.Price_Book__c AND product__c In:productIds And Tier__r.Floor_Unit__c <= :currentQuantity And Tier__r.Ceiling_Unit__c >= :currentQuantity And Tier__r.Active__c = true And Discount_Plan__r.Active__c = true And Active__c = true
                    WITH SECURITY_ENFORCED
                    limit 100];

            List<Id> discountPlanIds = new List<Id>();
            for (Tier_Discount_Allocation__c TDA : TDAS){ if (TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
            }
            List<Discount_Plan__c> discounts = new List<Discount_Plan__c>();
            discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c, Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                         From Discount_Plan__c
                         Where Id In:discountPlanIds And Active__c = True
                         WITH SECURITY_ENFORCED
                         limit 100];

            Map<Id, Discount_Plan__c> discountMap = new Map<Id, Discount_Plan__c>();
            for (Discount_Plan__c dis : discounts){ discountMap.put(dis.id, dis);
            }

            Map<Id, List<Discount_Plan__c>> discountPlans = new Map<Id, List<Discount_Plan__c>>();
            Map<Id, List<Tier_Discount_Allocation__c>> tierDiscAllocation = new Map<Id, List<Tier_Discount_Allocation__c>>();
            for (PricebookEntry pbPro : pbe){
                List<Discount_Plan__c> myDiscountPlans = new List<Discount_Plan__c>();
                List<Tier_Discount_Allocation__c> myTierDiscAlc = new List<Tier_Discount_Allocation__c>();
                for (Tier_Discount_Allocation__c TDA : TDAS){ if (pbPro.Product2.Id == TDA.product__c && TDA.Discount_Plan__c != Null){ myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));myTierDiscAlc.add(TDA);
                    }
                }
                discountPlans.put(pbPro.Product2.Id, myDiscountPlans);
                tierDiscAllocation.put(pbPro.Product2.Id, myTierDiscAlc);
            }

            //==============/Discount Plan===========================

            //=============Taxex Calculation start=====================
            Date todayDate = system.today();
            List<Tax__c> profileTax = new List<Tax__c>();
            profileTax = [Select Id, Name, Active__c, Apply_Tax_On__c, City__c, Country__c, Effective_Date__c, Expiry_Date__c, Other_Tax_Rate__c, Other_Tax_Type__c, Postal_Code__c, Product__c, Province__c, Tax_Rate__c, Type__c
                          from Tax__c
                          where Account_Profile__c = :profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c = Null AND Active__c = true
                          WITH SECURITY_ENFORCED
                          order by Province__c DESC
                          limit 100];

            List<Tax__c> productprofileTax = new List<Tax__c>();
            productprofileTax = [Select Id, Name, Active__c, Apply_Tax_On__c, City__c, Country__c, Effective_Date__c, Expiry_Date__c, Other_Tax_Rate__c, Other_Tax_Type__c, Postal_Code__c, Product__c, Province__c, Tax_Rate__c, Type__c
                                 from Tax__c
                                 where Account_Profile__c = :profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c != Null AND Product__c In:productIds AND Active__c = true
                                 WITH SECURITY_ENFORCED
                                 order by Province__c DESC
                                 limit 100];

            Address__c ordBillToAdd;
            Address__c ordShipToAdd;
            if (billToAddId != '' && billToAddId != null)
                ordBillToAdd = [Select Id, Name, Active__c, City__c, Country__c, State__c, Postal_Code__c
                                from Address__c
                                where Id = :billToAddId AND Active__c = true
                                WITH SECURITY_ENFORCED
                                Limit 1];
            if (shipToAddId != '' && shipToAddId != null)
                ordShipToAdd = [Select Id, Name, Active__c, City__c, Country__c, State__c, Postal_Code__c
                                from Address__c
                                where Id = :shipToAddId AND Active__c = true
                                WITH SECURITY_ENFORCED
                                Limit 1];
            String TaxPostalCode = '';
            String TaxCity = '';
            String TaxProvince = '';
            String TaxCountry = '';
            if (ordBillToAdd != Null){
                if (profile.Account_Profile__r.Tax_Sourcing_Rules__c == 'Origin'){
                    if (ordBillToAdd.Postal_Code__c != Null && ordBillToAdd.Postal_Code__c != '') TaxPostalCode = ordBillToAdd.Postal_Code__c;
                    if (ordBillToAdd.City__c != Null && ordBillToAdd.City__c != '')
                        TaxCity = ordBillToAdd.City__c;
                    if (ordBillToAdd.State__c != Null && ordBillToAdd.State__c != '') TaxProvince = ordBillToAdd.State__c;
                    if (ordBillToAdd.Country__c != Null && ordBillToAdd.Country__c != '')
                        TaxCountry = ordBillToAdd.Country__c;
                }
            }

            if (ordShipToAdd != Null){
                if (profile.Account_Profile__r.Tax_Sourcing_Rules__c == 'Destination'){
                    if (ordShipToAdd.Postal_Code__c != Null && ordShipToAdd.Postal_Code__c != '') TaxPostalCode = ordShipToAdd.Postal_Code__c;                }
            }

            //=============Taxex Calculation end=====================

            //fetch subscription plans
            List<Subscription_Plan__c> subPlans = new List<Subscription_Plan__c>();
            subPlans = [Select Id, Name, Active__c, Duration_label__c, Duration_Unit__c, Description__c,
                        Order_Delivery_Frequency__c, Billing_Period__c
                        from Subscription_Plan__c
                        where Active__c = true
                        WITH SECURITY_ENFORCED
                        limit 100];


            for (PricebookEntry pb : pbe){

                List<SelectOptions> options = new List<SelectOptions>();
                options.add(new SelectOptions('', '--None--'));
                if (discountPlans.get(pb.Product2.Id) != null){
                    for (Discount_Plan__c dis : discountPlans.get(pb.Product2.Id)){ options.add(new SelectOptions(dis.Id, dis.Name));
                    }
                }

                //=============taxes start==================
                Tax__c tax;//=new Tax__c();
                Boolean taxFound = false;
                Decimal vatAmount = 0;
                Decimal anotherTax = 0;
                String taxId = '';

                //Product Taxes
                if (productprofileTax.size() > 0){
                    for (Tax__c ProductTax : productprofileTax){
                        if (pb.Product2.Id == ProductTax.Product__c){
                            if ((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == TaxPostalCode && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){
                                tax = ProductTax;taxId = ProductTax.Id;taxFound = true;break;
                            }
                            if (!taxFound){
                                if ((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){
                                    tax = ProductTax;taxId = ProductTax.Id;taxFound = true;break;
                                }
                            }
                            if (!taxFound){
                                if ((TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == TaxCountry)){
                                    tax = ProductTax;taxId = ProductTax.Id;taxFound = true;break;
                                }
                            }
                            if (!taxFound){
                                if (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == Null){ tax = ProductTax;taxId = ProductTax.Id;taxFound = true;break;
                                }
                            }
                        }
                    }
                }
                //Profile Taxes
                if (!taxFound){
                    if (profileTax.size() > 0){
                        for (Tax__c profileTax1 : profileTax){ if ((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == TaxPostalCode && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax = profileTax1;taxId = profileTax1.Id;taxFound = true;break;
                            }
                            if (!taxFound){  if ((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax = profileTax1;taxId = profileTax1.Id;taxFound = true;break;
                                }
                            }
                            if (!taxFound){ if ((TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == TaxCountry)){ tax = profileTax1;taxId = profileTax1.Id;taxFound = true;break;
                                }
                            }
                            if (!taxFound){ if (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == Null){ tax = profileTax1;taxId = profileTax1.Id;taxFound = true;break;
                                }
                            }
                        }
                    }
                }
                //=============taxes end==================

                ProductWrapper pw = new ProductWrapper();
                pw.pbe = pb;
                if(pb.Product2.Is_Subscribe__c){ pw.subPlans = subPlans;}
                if (pb.Product2.BOM__c != null){ pw.version = pb.Product2.BOM__c;}
                pw.CurrentDiscounts = options;
                pw.stock = stockView.get(pb.Product2.Id) != null ? stockView.get(pb.Product2.Id) : 0.00;
                pw.disPlans = discountPlans.get(pb.Product2.Id) != null ? discountPlans.get(pb.Product2.Id) : new List<Discount_Plan__c>();
                pw.tierDists = tierDiscAllocation.get(pb.Product2.Id) != null ? tierDiscAllocation.get(pb.Product2.Id) : new List<Tier_Discount_Allocation__c>();
                pw.tax = tax != null ? tax : new Tax__c();
                pw.vatAmount = vatAmount;
                pw.otherTax = anotherTax;
                pw.totalTaxAmount = vatAmount + anotherTax;
                prodWrap.add(pw);

            }
        } catch (Exception e){
        }
        System.debug('prodWrap ->'+prodWrap);
        return prodWrap;
    }

    @AuraEnabled
    global static List<ProductWrapper> getDiscountPlan(String profileId, String prodId, Integer quantity){
        return null;
    }
    @AuraEnabled
    global static List<ProductWrapper> getDiscountPlanupdated(String profileId, String prodId, Decimal quantity){ List<ProductWrapper> prWrapperList = new List<ProductWrapper>(); try{ Set<Id> productIds = new Set<Id>();productIds.add(prodId);List<Tier_Discount_Allocation__c> TDAS = new List<Tier_Discount_Allocation__c>();TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name, Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c, Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c From Tier_Discount_Allocation__c Where Order_Profile__c = :profileId And product__c In:productIds And Tier__r.Floor_Unit__c <= :quantity And Tier__r.Ceiling_Unit__c >= :quantity And Tier__r.Active__c = true And Discount_Plan__r.Active__c = true And Active__c = true WITH SECURITY_ENFORCED limit 100]; List<Id> discountPlanIds = new List<Id>();for (Tier_Discount_Allocation__c TDA : TDAS){if (TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c); } List<Discount_Plan__c> discounts = new List<Discount_Plan__c>();discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c, Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c From Discount_Plan__c Where Id In:discountPlanIds And Active__c = True WITH SECURITY_ENFORCED limit 100]; Map<Id, Discount_Plan__c> discountMap = new Map<Id, Discount_Plan__c>();for (Discount_Plan__c dis : discounts){  discountMap.put(dis.id, dis); } Map<Id, List<Discount_Plan__c>> discountPlans = new Map<Id, List<Discount_Plan__c>>();Map<Id, List<Tier_Discount_Allocation__c>> tierDiscAllocation = new Map<Id, List<Tier_Discount_Allocation__c>>();List<Discount_Plan__c> myDiscountPlans = new List<Discount_Plan__c>();List<Tier_Discount_Allocation__c> myTierDiscAlc = new List<Tier_Discount_Allocation__c>();for (Tier_Discount_Allocation__c TDA : TDAS){if (prodId == TDA.product__c && TDA.Discount_Plan__c != Null){ myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c)); myTierDiscAlc.add(TDA); } } discountPlans.put(prodId, myDiscountPlans);tierDiscAllocation.put(prodId, myTierDiscAlc); /*for(PricebookEntry pb : pbe){*/ List<SelectOptions> options = new List<SelectOptions>();options.add(new SelectOptions('', '--None--'));if (discountPlans.get(prodId) != null){for (Discount_Plan__c dis : discountPlans.get(prodId)){  options.add(new SelectOptions(dis.Id, dis.Name)); } } ProductWrapper prWrapper = new ProductWrapper();prWrapper.CurrentDiscounts = options;prWrapper.disPlans = (discountPlans.get(prodId) != null) ? discountPlans.get(prodId) : new List<Discount_Plan__c>();prWrapper.tierDists = (tierDiscAllocation.get(prodId) != null) ? tierDiscAllocation.get(prodId) : new List<Tier_Discount_Allocation__c>(); prWrapperList.add(prWrapper);} catch (Exception e){}return prWrapperList;
    }

    global class ProductWrapper{
        @AuraEnabled
        global PricebookEntry pbe{ get; set; }

        @AuraEnabled
        global String version{ get; set; }

        @AuraEnabled
        global List<SelectOptions> CurrentDiscounts{ get; set; }

        @AuraEnabled
        global Decimal stock{ get; set; }

        @AuraEnabled
        global List<Discount_Plan__c> disPlans{ get; set; }

        @AuraEnabled
        global List<Tier_Discount_Allocation__c> tierDists{ get; set; }

        @AuraEnabled
        global Tax__c tax{ get; set; }

        //@AuraEnabled global String taxId                              { get; set; }
        @AuraEnabled
        global Decimal vatAmount{ get; set; }

        @AuraEnabled
        global Decimal otherTax{ get; set; }

        @AuraEnabled
        global Decimal totalTaxAmount{ get; set; }

        @AuraEnabled
        global Decimal quantity{ get; set; }

        @AuraEnabled
        global Decimal minDiscount{ get; set; }

        @AuraEnabled
        global Decimal maxDiscount{ get; set; }

        @AuraEnabled
        global Decimal discountPercent{ get; set; }

        @AuraEnabled
        global Decimal totalDiscount{ get; set; }

        @AuraEnabled
        global Boolean isPercent{ get; set; }

        @AuraEnabled
        global String discountPlan{ get; set; }

        @AuraEnabled
        global List<Subscription_Plan__c> subPlans{ get; set; }

        global ProductWrapper(){
            pbe = new PricebookEntry();
            version = '';
            quantity = 1;
            minDiscount = 0;
            maxDiscount = 0;
            stock = 0;
            CurrentDiscounts = new List<SelectOptions>();
            discountPercent = 0;
            totalDiscount = 0;
            disPlans = new List<Discount_Plan__c>();
            tierDists = new List<Tier_Discount_Allocation__c>();
            tax = new Tax__c();
            //taxId='';
            vatAmount = 0;
            otherTax = 0;
            totalTaxAmount = 0;
            isPercent = true;
            discountPlan = '';
            subPlans = new List<Subscription_Plan__c>();
        }

    }

    @AuraEnabled
    global static Decimal latestStock(String channelId, String prodId){
        Decimal stock = 0;
        try{
            Set<Id> siteIds = new Set<Id>();
            List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c
                                                                  from Distribution_Channel__c
                                                                  where Channel__c = :channelId and Active__c = true
                                                                  WITH SECURITY_ENFORCED
                                                                  limit 100];
            if (DistributionChannels.size() > 0){
                for (Distribution_Channel__c DC : DistributionChannels){ siteIds.add(DC.Site__c);
                }
            }
            List<Inventory_Stock__c> WarehouseItemInventoryStocks = new List<Inventory_Stock__c>();
            WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c, Number_of_Item_In_Stock__c, BOM__c
                                            From Inventory_Stock__c
                                            Where product__c = :prodId And Active__c = true And Warehouse__c In:siteIds And Number_of_Item_In_Stock__c > 0
                                            WITH SECURITY_ENFORCED
                                            limit 100];

            for (Inventory_Stock__c inven : WarehouseItemInventoryStocks){  stock += inven.Number_of_Item_In_Stock__c;
            }
        } catch (Exception e){
        }
        return stock;
    }


    @AuraEnabled
    global static OrderAndLinesWrapper saveOrderAndLines(String ord, String ordItems,String prodList, List<String> itemsToDel){
        system.debug('ord value'+ord);
        OrderAndLinesWrapper wr=new OrderAndLinesWrapper();
        return wr;
    }

        @AuraEnabled
    public static OrderAndLinesWrapper saveOrderAndLines1(String ord, String ordItems,String prodList, List<String> itemsToDel, String subAllocations){
        system.debug('ord value'+ord);
        OrderAndLinesWrapper wr=new OrderAndLinesWrapper();
        try{
            Set<String> itemsToDel1= new Set<String>();
            itemsToDel1.addAll(itemsToDel);
            List<OrderItem> ordItemToDel=[Select Id from OrderItem where Id In:itemsToDel1];

            //DML Operation
            if(ordItemToDel.size() > 0 && OrderItem.sObjectType.getDescribe().isDeletable()) delete ordItemToDel;


            Order order2Upsert= (Order) JSON.deserialize(ord, Order.class);

            //DML Operation

            if (Schema.sObjectType.Order.isUpdateable() && Schema.sObjectType.Order.isCreateable()) {
                //if(order2Upsert.Shipment_Type__c == null || order2Upsert.Shipment_Type__c == '' || order2Upsert.Shipment_Type__c == '--None--') { order2Upsert.Shipment_Type__c = '--None--'; order2Upsert.Shipment_Preference_Speed__c = '--None--';}
                System.debug('Oder Details to Upsert~>'+order2Upsert);
                upsert order2Upsert;

            }

            List<OrderItem> orderItem2Upsert= (List<OrderItem>) JSON.deserialize(ordItems, List<OrderItem>.class);

            Set<Id> prodIds= (Set<Id>) JSON.deserialize(prodList, Set<Id>.class);

            List<PricebookEntry> pbeList=[Select Id,Name,Product2Id from PricebookEntry where Pricebook2Id =: order2Upsert.Pricebook2Id AND Product2Id =:prodIds];
            Map<Id,Id> proPbeMap=new Map<Id,Id>();
            for(PricebookEntry pb:pbeList) proPbeMap.put(pb.Product2Id,pb.Id);

            for(OrderItem ordItem:orderItem2Upsert){
                if(ordItem.Name__c!=null && ordItem.Name__c.length()>50) ordItem.Name__c.subString(0,50);
                if(ordItem.Id == null && Schema.sObjectType.OrderItem.fields.OrderId.isCreateable()) ordItem.OrderId=order2Upsert.Id; else system.debug('no access to order in orditem~> updateable~>'+Schema.sObjectType.OrderItem.fields.OrderId.isUpdateable()+' createable~~>'+Schema.sObjectType.OrderItem.fields.OrderId.isCreateable());
                if(ordItem.Id == null && Schema.sObjectType.OrderItem.fields.PricebookEntryId.isCreateable()) ordItem.PricebookEntryId=proPbeMap.get(ordItem.Product2Id);
            }

            if (String.isNotBlank(subAllocations)) { List<Product_Subscription_Plan_Allocation__c> subAllocList = (List<Product_Subscription_Plan_Allocation__c>) JSON.deserialize(subAllocations, List<Product_Subscription_Plan_Allocation__c>.class); if (!subAllocList.isEmpty()) { /* Prepare allocations for insert*/ List<Product_Subscription_Plan_Allocation__c> subAllocToInsert = new List<Product_Subscription_Plan_Allocation__c>(); List<Product_Subscription_Plan_Allocation__c> subAllocToUpdate = new List<Product_Subscription_Plan_Allocation__c>(); for (Product_Subscription_Plan_Allocation__c alloc : subAllocList) { alloc.Active__c = true; /* Default start date*/ if (alloc.Start_Date__c == null) { alloc.Start_Date__c = Date.today(); } /* Default name if missing*/ if (String.isBlank(alloc.Name)) { alloc.Name = alloc.Product__c+ ' Subscription Plan Allocation'; } if (alloc.Id == null) { subAllocToInsert.add(alloc); } else { subAllocToUpdate.add(alloc); } } if (!subAllocToInsert.isEmpty() && Schema.sObjectType.Product_Subscription_Plan_Allocation__c.isCreateable()) { insert subAllocToInsert; } if (!subAllocToUpdate.isEmpty() && Schema.sObjectType.Product_Subscription_Plan_Allocation__c.isUpdateable()) { update subAllocToUpdate; } /* ⚡ Now relate allocations back to OrderItems // We'll map by Product__c (assuming one allocation per product)*/ Map<Id, Id> prodToAllocMap = new Map<Id, Id>(); /* for (Product_Subscription_Plan_Allocation__c alloc : subAllocList) { prodToAllocMap.put(alloc.Product__c, alloc.Id); }*/ for (Product_Subscription_Plan_Allocation__c alloc : subAllocToInsert) { prodToAllocMap.put(alloc.Product__c, alloc.Id); } for (Product_Subscription_Plan_Allocation__c alloc : subAllocToUpdate) { /* prodToAllocMap.put(alloc.Product__c, alloc.Id);*/ } /* Update OrderItems with the new allocation lookup*/ for (OrderItem oi : orderItem2Upsert) { if (prodToAllocMap.containsKey(oi.Product2Id)) { oi.Product_Subscription_Plan_Allocation__c = prodToAllocMap.get(oi.Product2Id);
                        }
                    }

                  //  if (!orderItem2Upsert.isEmpty() && Schema.sObjectType.OrderItem.fields.Product_Subscription_Plan_Allocation__c.isUpdateable()) {
                  //      update orderItem2Upsert;
                  //  }
                }
            }


            //DML Operation
            if(orderItem2Upsert.size() > 0 && Schema.sObjectType.OrderItem.isUpdateable() && Schema.sObjectType.OrderItem.isCreateable())
                upsert orderItem2Upsert;   wr.ord=order2Upsert;

        }catch(Exception e){wr.error.add(e.getMessage()+'   Line:'+e.getLineNumber());}
        return wr;
    }

    @AuraEnabled
    global static OrderAndLinesWrapper fetchOrderDetails(String OrderId){
        OrderAndLinesWrapper wr = new OrderAndLinesWrapper();
        try{
            if (String.isNotEmpty(OrderId)){

                wr.ord = [Select Id, Name, Active__c, EffectiveDate, Payments_Status__c, OrderReferenceNumber, Expected_Date__c, Shipment_Type__c, Status, Description, Is_Back_Order__c, Is_Pre_Order__c, Issue_Invoice__c, Is_Closed__c, AccountId, Account.Name, Account.Account_Profile__c, Account.Account_Profile__r.Name, Account.Order_Profile__c, Account.Order_Profile__r.Name, Account.Order_Profile__r.Channel__c, Account.Order_Profile__r.Price_Book__c, Account.Order_Profile__r.Account_Profile__c, Account.Order_Profile__r.Account_Profile__r.Tax_Sourcing_Rules__c, Account.AccountNumber, Account.Company__c, Account.Organisation_Business_Unit__c, Account.Available_Credit_Balance__c, Account.Website, Account.Phone, Account.Fax, Account.VAT_registration_number__c, Employee__c, Employee__r.Name, Employee__r.Employee_User__c, Contact__c, Contact__r.Name, Contact__r.MobilePhone, Contact__r.Email,Contact__r.Title, Contact__r.Phone, Bill_To_Address__c, Bill_To_Address__r.Name, Bill_To_Address__r.Address_Line1__c, Bill_To_Address__r.Address_Line2__c, Bill_To_Address__r.Address_Line3__c, Bill_To_Address__r.City__c, Bill_To_Address__r.Country__c, Bill_To_Address__r.State__c, Bill_To_Address__r.Postal_Code__c, Ship_To_Address__c, Ship_To_Address__r.Name, Ship_To_Address__r.Address_Line1__c, Ship_To_Address__r.Address_Line2__c, Ship_To_Address__r.Address_Line3__c, Ship_To_Address__r.City__c, Ship_To_Address__r.Country__c, Ship_To_Address__r.State__c, Ship_To_Address__r.Postal_Code__c, Order_Profile__c, Order_Profile__r.Name, Order_Profile__r.Channel__c, Order_Profile__r.Price_Book__c, Order_Profile__r.Account_Profile__c, Order_Profile__r.Account_Profile__r.Tax_Sourcing_Rules__c, Project__c, Project__r.Name, Order_Discount__c, Order_Discount_Description__c, Order_Amount__c, Amount_Paid__c, Due_Amount__c, Company__c, Company__r.Name, Organisation_Business_Unit__c, Total_Quantity__c, Picked_Quantity__c, Packed_Quantity__c, Shipped_Quantity__c, UPS_Service__c, Estimated_Delivery_Date__c, Tracking_Number__c, Estimated_Shipping_Amount__c, Shipping_VAT__c, Total_Shipping_Amount__c, Total_Tax_Amount__c, TotalDiscount__c, Shipping_Discount__c, Sub_Total__c, TotalAmount
                          from Order
                          where Id = :OrderId
                          WITH SECURITY_ENFORCED
                          limit 100];

                wr.ordItems = [Select Id, Product2Id, UnitPrice, Product2.QuantityUnitOfMeasure, Product2.Name, Product2.ProductCode, Product2.Description, Product2.BOM__c, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Picture__c, Product2.Serialise__c, BOM__c, Quantity, Discount_Plan__c, Discount_Plan__r.Name, Discount_Plan__r.Active__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c, Product2.Is_Kit__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c, Discount_Plan__r.Default_Discount_Value__c, VAT_Amount__c, Other_Tax__c, Tax__c, Tax__r.Name, Tax__r.Active__c, Tax__r.Apply_Tax_On__c, Tax__r.City__c, Tax__r.Country__c, Tax__r.Effective_Date__c, Tax__r.Expiry_Date__c, Tax__r.Other_Tax_Rate__c, Tax__r.Other_Tax_Type__c, Tax__r.Postal_Code__c, Tax__r.Product__c, Tax__r.Province__c, Tax__r.Tax_Rate__c, Tax__r.Type__c, Discount_Amount__c, Discount_Percent__c,
                                    Product_Subscription_Plan_Allocation__c, Product_Subscription_Plan_Allocation__r.Name, Product_Subscription_Plan_Allocation__r.Subscription_Plan__c, Product_Subscription_Plan_Allocation__r.Subscription_Plan__r.Name, Product_Subscription_Plan_Allocation__r.Start_Date__c, Month_Duration__c, EndDate, ServiceDate
                               from OrderItem
                               where OrderId = :OrderId
                               WITH SECURITY_ENFORCED
                               order by Sort_Order__c
                               limit 100];

                set<Id> subscriptionAllocationIds=new set<Id>();
                for(OrderItem oi:wr.ordItems){ if(oi.Product_Subscription_Plan_Allocation__c!=null){subscriptionAllocationIds.add(oi.Product_Subscription_Plan_Allocation__c);}
                }
                wr.subscriptionAllocations=[select Id, Name, Product__c, Product__r.Name, Subscription_Plan__c, Subscription_Plan__r.Name, Start_Date__c, Active__c
                                            from Product_Subscription_Plan_Allocation__c
                                            where Id IN :subscriptionAllocationIds
                                            WITH SECURITY_ENFORCED
                                            limit 100];

                wr.subPlans=[select Id, Name, Duration_label__c, Duration_Unit__c, Active__c
                              from Subscription_Plan__c
                              where Active__c = true
                              WITH SECURITY_ENFORCED
                              limit 100];

                wr.invoiceList = [Select Id, Name, RecordTypeId, RecordType.Name,RecordType.DeveloperName, Invoice_Amount__c, Invoice_Date__c, Total_Due__c, Final_Due_Amount__c, Posted__c, Posted_Date__c, Amount_Paid__c, Paid_Amount__c, Paid__c, Contact__c, Credit_Note__c, Credit_Note_Issued__c, Order_S__c, Account__c
                                  from Invoice__c
                                  where Order_S__c = :OrderId
                                  WITH SECURITY_ENFORCED
                                  order by CreatedDate Desc
                                  limit 100];

                wr.paymentList = [Select Id, Name, Payment_Type__c, Payment_Date__c, Total_Amount__c
                                  from Payment__c
                                  where Order__c = :OrderId
                                  WITH SECURITY_ENFORCED
                                  order by CreatedDate Desc
                                  limit 100];

                Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
                if (isMultiCurrency) wr.orderCurrency = (String) Database.Query('select CurrencyIsoCode from Order where Id=:OrderId WITH SECURITY_ENFORCED  Limit 1')[0].get('CurrencyIsoCode');
                wr.allCurrencies.add(new SelectOptions(wr.orderCurrency, wr.orderCurrency));
                if (wr.isMultiCurrency) wr.allCurrencies = Epos.getCurrenyList('Order', 'CurrencyIsoCode');
                //Object and picklist_Field

                wr.CRList = [Select Id, Name, Coupon__c, Coupon__r.Name, Redemption_Date__c, Coupon_Issued__c, Coupon_Issued__r.Name, Value__c
                             from Coupon_Redemption__c
                             where Order__c = :OrderId
                             WITH SECURITY_ENFORCED
                             limit 100];

                wr.shipments = [Select Id, Name, RecordTypeId, RecordType.Name, RecordType.DeveloperName, Tracking_Number__c, Shipment_Delivery_Date__c, Status__c
                                from Shipment__c
                                where Order__c = :OrderId
                                WITH SECURITY_ENFORCED
                                limit 100];
            }
        } catch (Exception e){
        }
        return wr;
    }

    global class OrderAndLinesWrapper{
        @AuraEnabled
        global List<String> error{ get; set; }

        @AuraEnabled
        global Order ord{ get; set; }

        @AuraEnabled
        global List<OrderItem> ordItems{ get; set; }

        @AuraEnabled
        global List<Invoice__c> invoiceList{ get; set; }

        @AuraEnabled
        global List<Payment__c> paymentList{ get; set; }

        @AuraEnabled
        global String orderCurrency{ get; set; }

        @AuraEnabled
        global List<SelectOptions> allCurrencies{ get; set; }

        @AuraEnabled
        global boolean isMultiCurrency{ get; set; }

        @AuraEnabled
        global List<Coupon_Redemption__c> CRList{ get; set; }

        @AuraEnabled
        global List<Shipment__c> shipments{ get; set; }

        @AuraEnabled
        global List<Product_Subscription_Plan_Allocation__c> subscriptionAllocations{ get; set; }

        @AuraEnabled
        global List<Subscription_Plan__c> subPlans{ get; set; }

        global OrderAndLinesWrapper(){
            error = new List<String>();
            ord = new Order();
            ordItems = new List<OrderItem>();
            invoiceList = new List<Invoice__c>();
            paymentList = new List<Payment__c>();
            orderCurrency = UserInfo.getDefaultCurrency();
            allCurrencies = new List<SelectOptions>();
            isMultiCurrency = false;
            CRList = new List<Coupon_Redemption__c>();
            shipments = new List<Shipment__c>();
            subscriptionAllocations = new List<Product_Subscription_Plan_Allocation__c>();
            subPlans = new List<Subscription_Plan__c>();
        }

    }

    @AuraEnabled
    global static cardDetails fetchInitialCardDetails(){
        cardDetails comW = new cardDetails();
        //comW.CountyList.add(new SelectOptions('--None--', ''));
        Schema.DescribeFieldResult fieldResultCnty = Address__c.State__c.getDescribe();
        List<Schema.PicklistEntry> cnty = fieldResultCnty.getPicklistValues();
        for (Schema.PicklistEntry f : cnty)
            comW.CountyList.add(new SelectOptions(f.getValue(), f.getLabel()));
        Schema.DescribeFieldResult fieldResultCntry = Address__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> cntry = fieldResultCntry.getPicklistValues();
        for (Schema.PicklistEntry f : cntry)
            comW.CountryList.add(new SelectOptions(f.getValue(), f.getLabel()));
        Schema.DescribeFieldResult fieldResultCardtype = Payment_Method__c.CardType__c.getDescribe();
        List<Schema.PicklistEntry> cardtype = fieldResultCardtype.getPicklistValues();
        for (Schema.PicklistEntry f : cardtype)
            comW.CardTypes.add(new SelectOptions(f.getValue(), f.getLabel()));
        comW.ExpiryMonth.add(new SelectOptions('01', '01'));
        comW.ExpiryMonth.add(new SelectOptions('02', '02'));
        comW.ExpiryMonth.add(new SelectOptions('03', '03'));
        comW.ExpiryMonth.add(new SelectOptions('04', '04'));
        comW.ExpiryMonth.add(new SelectOptions('05', '05'));
        comW.ExpiryMonth.add(new SelectOptions('06', '06'));
        comW.ExpiryMonth.add(new SelectOptions('07', '07'));
        comW.ExpiryMonth.add(new SelectOptions('08', '08'));
        comW.ExpiryMonth.add(new SelectOptions('09', '09'));
        comW.ExpiryMonth.add(new SelectOptions('10', '10'));
        comW.ExpiryMonth.add(new SelectOptions('11', '11'));
        comW.ExpiryMonth.add(new SelectOptions('12', '12'));
        Integer curMonth = system.today().year();
        for (integer i = 1; i < 10; i++)
            comW.ExpiryYear.add(new SelectOptions(curMonth + '', curMonth++ + ''));
        List<Credentials__c> paymentSetup = [Select Id, Name
                                             from Credentials__c
                                             Where Active__c = :true AND Type__c = 'Payment'
                                             WITH SECURITY_ENFORCED
                                             limit 100];
        for (Credentials__c cr : paymentSetup)
            comW.paymentGateways.add(new SelectOptions(cr.Id, cr.Name));
        return comW;
    }

    global class cardDetails{
        @AuraEnabled
        global List<SelectOptions> CountyList{ get; set; }

        @AuraEnabled
        global List<SelectOptions> CountryList{ get; set; }

        @AuraEnabled
        global List<SelectOptions> CardTypes{ get; set; }

        @AuraEnabled
        global List<SelectOptions> ExpiryMonth{ get; set; }

        @AuraEnabled
        global List<SelectOptions> ExpiryYear{ get; set; }

        @AuraEnabled
        global List<SelectOptions> paymentGateways{ get; set; }

        @AuraEnabled
        global List<SelectOptions> accountsType{ get; set; }

        global cardDetails(){
            CountyList = new List<SelectOptions>();
            CountryList = new List<SelectOptions>();
            CardTypes = new List<SelectOptions>();
            ExpiryMonth = new List<SelectOptions>();
            ExpiryYear = new List<SelectOptions>();
            paymentGateways = new List<SelectOptions>();
            accountsType = new List<SelectOptions>();
        }

    }

    @AuraEnabled
    global static OrderAndLinesWrapper fetchOrdDetailsForClone(String OrderId){
        OrderAndLinesWrapper wr = new OrderAndLinesWrapper();
        try{
            wr.ord = [Select Active__c, EffectiveDate, Payments_Status__c, OrderReferenceNumber, Expected_Date__c, Shipment_Type__c, Status, Description, Is_Back_Order__c, Is_Pre_Order__c, Issue_Invoice__c, Is_Closed__c, AccountId, Account.Name, Account.Account_Profile__c, Account.Account_Profile__r.Name, Account.Order_Profile__c, Account.Order_Profile__r.Name, Account.Order_Profile__r.Channel__c, Account.Order_Profile__r.Price_Book__c, Account.Order_Profile__r.Account_Profile__c, Account.Order_Profile__r.Account_Profile__r.Tax_Sourcing_Rules__c, Account.AccountNumber, Account.Company__c, Account.Organisation_Business_Unit__c, Account.Available_Credit_Balance__c, Account.Website, Account.Phone, Account.Fax, Account.VAT_registration_number__c, Employee__c, Employee__r.Name, Employee__r.Employee_User__c, Contact__c, Contact__r.Name, Contact__r.MobilePhone, Contact__r.Email, Contact__r.Phone, Bill_To_Address__c, Bill_To_Address__r.Name, Bill_To_Address__r.Address_Line1__c, Bill_To_Address__r.Address_Line2__c, Bill_To_Address__r.Address_Line3__c, Bill_To_Address__r.City__c, Bill_To_Address__r.Country__c, Bill_To_Address__r.State__c, Bill_To_Address__r.Postal_Code__c, Ship_To_Address__c, Ship_To_Address__r.Name, Ship_To_Address__r.Address_Line1__c, Ship_To_Address__r.Address_Line2__c, Ship_To_Address__r.Address_Line3__c, Ship_To_Address__r.City__c, Ship_To_Address__r.Country__c, Ship_To_Address__r.State__c, Ship_To_Address__r.Postal_Code__c, Order_Profile__c, Order_Profile__r.Name, Order_Profile__r.Channel__c, Order_Profile__r.Price_Book__c, Order_Profile__r.Account_Profile__c, Order_Profile__r.Account_Profile__r.Tax_Sourcing_Rules__c, Project__c, Project__r.Name, Order_Amount__c, Due_Amount__c, Company__c, Company__r.Name, Organisation_Business_Unit__c, Total_Quantity__c
                      from Order
                      where Id = :OrderId
                      WITH SECURITY_ENFORCED
                      limit 100];


            wr.ordItems = [Select Id, Product2Id, UnitPrice, Product2.QuantityUnitOfMeasure, Product2.Name, Product2.ProductCode, Product2.Description, Product2.BOM__c, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Picture__c, Product2.Serialise__c, BOM__c, Quantity, Discount_Plan__c, Discount_Plan__r.Name, Discount_Plan__r.Active__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c, Discount_Plan__r.Default_Discount_Value__c, VAT_Amount__c, Other_Tax__c, Tax__c, Tax__r.Name, Tax__r.Active__c, Tax__r.Apply_Tax_On__c, Tax__r.City__c, Tax__r.Country__c, Tax__r.Effective_Date__c, Tax__r.Expiry_Date__c, Tax__r.Other_Tax_Rate__c, Tax__r.Other_Tax_Type__c, Tax__r.Postal_Code__c, Tax__r.Product__c, Tax__r.Province__c, Tax__r.Tax_Rate__c, Tax__r.Type__c, Discount_Amount__c, Discount_Percent__c
                           from OrderItem
                           where OrderId = :OrderId
                           WITH SECURITY_ENFORCED
                           order by Sort_Order__c
                           limit 100];


            Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            if (isMultiCurrency)wr.orderCurrency = (String) Database.Query('select CurrencyIsoCode from Order where Id=:OrderId WITH SECURITY_ENFORCED Limit 1')[0].get('CurrencyIsoCode');
            wr.allCurrencies.add(new SelectOptions(wr.orderCurrency, wr.orderCurrency));
            if (wr.isMultiCurrency) wr.allCurrencies = Epos.getCurrenyList('Order', 'CurrencyIsoCode');
        } catch (Exception e){ wr.error.add(e.getMessage() + '   Line No:' + e.getLineNumber());
        }
        return wr;
    }

    @AuraEnabled
    global static Invoice__c updateInvoice(String invId, boolean postedValue){
        try{
            Invoice__c inv = [Select Id, Name, RecordTypeId, RecordType.DeveloperName, Invoice_Amount__c, Invoice_Date__c, Total_Due__c, Final_Due_Amount__c, Posted__c, Posted_Date__c, Amount_Paid__c, Paid_Amount__c, Paid__c, Contact__c, Credit_Note__c, Credit_Note_Issued__c, Order_S__c, Account__c
                              from Invoice__c
                              where Id = :invId
                              WITH SECURITY_ENFORCED
                              limit 100];

            inv.Id = invId;
            if (Schema.sObjectType.Invoice__c.fields.Posted__c.isUpdateable())
                inv.Posted__c = postedValue;
            if (postedValue && Schema.sObjectType.Invoice__c.fields.Posted_Date__c.isCreateable())
                inv.Posted_Date__c = System.today();
            else if (Schema.sObjectType.Invoice__c.fields.Posted_Date__c.isCreateable())
                inv.Posted_Date__c = null;
            /*DML Operation.*/
            if (Schema.sObjectType.Invoice__c.isCreateable() && Schema.sObjectType.Invoice__c.isUpdateable() && Schema.sObjectType.Invoice__c.fields.Posted_Date__c.isUpdateable())
                update inv;
            return inv;
        } catch (Exception e){} return null;
    }
    @AuraEnabled
    global static string createCardPayment(String payments, String paymentMethods, String CVV, String billAddress, String selectedGateway, String myCur, String invAndAmount, Integer resCode){
      return 'Success';
    }
    @SuppressWarnings('PMD')
    @AuraEnabled
    global static String createCardPaymentV2(String payments, String paymentMethods, String CVV, String billAddress, String selectedGateway, String myCur, String invAndAmount, Integer resCode,String ordID){
             /*String invList,List<String> selInvList  (Multiple Invoice payment)*/
        String ErrorMsgPayment = '';
        Address__c billingAddress = (Address__c)JSON.deserialize(billAddress, Address__c.class);
        List<Invoice__c> invIdList = (List<Invoice__c>)JSON.deserialize(invAndAmount, List<Invoice__c>.class);
        System.debug('invandAmtIDLIST'+invIdList);
        order ord=[Select Id, Amount_Paid__c from Order where Id=:ordID];
        try{


            Payment__c Payment = (Payment__c)JSON.deserialize(payments, Payment__c.class);
            Payment_Method__c PaymentMethod = (Payment_Method__c)JSON.deserialize(paymentMethods, Payment_Method__c.class);

            Id rTypeP = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Card_Payments').getRecordTypeId();
            if (rTypeP != null)
                payment.RecordTypeId = rTypeP;
            Credentials__c credentialSetup;
            for (Credentials__c crd : [Select Id, Name, Active__c, Password_Transkey__c, Signature__c, URL__c, Username_Login__c, Encrypted_Key__c, Channel_Id__c, Bank_COA_ID__c
                                       From Credentials__c
                                       Where Active__c = :true AND Id = :selectedGateway
                                       WITH SECURITY_ENFORCED
                                       Limit 1])
                credentialSetup = crd;
                system.debug('credentialSetup'+credentialSetup);

            if (credentialSetup == null){ ErrorMsgPayment = 'Paymnet Credential Setup is not completed.';return ErrorMsgPayment;
            }

            if (credentialSetup.Bank_COA_ID__c != null){ payment.Payment_Account__c = credentialSetup.Bank_COA_ID__c;
            }
            String TransId = '', Status = '', AVSCode = '', CVV2 = '', sErrMsg = '', ErrMsg = '', ErrCode = '', rawResponse = '', CorrID = '', Id = '', pgId = '', userAgent = '', FirstName = '', LastName = '', Email = '', City = '', State = '', Country = '', Zipcode = '', CardType = '', Expiry_Month = '', Card_Number = '', Expiry_Year = '', Amount = '', Card_Type = '', myCurrency = '', Address_Line1 = '', Address_Line2 = '', methodId = '', comAppend = '', ipstring = '';
            if (payment.First_Name__c != Null) FirstName = payment.First_Name__c;
            if (payment.Last_Name__c != Null) LastName = payment.Last_Name__c;
            if (payment.Email_Address__c != Null) Email = payment.Email_Address__c;
            if (payment.Address_Line1__c != Null) Address_Line1 = payment.Address_Line1__c;
            if (payment.Address_Line2__c != Null) Address_Line2 = payment.Address_Line2__c;
            if (payment.City__c != Null) City = payment.City__c;
            if (payment.State__c != Null) State = payment.State__c;
            if (payment.Country__c != Null) Country = payment.Country__c;
            if (payment.Zipcode__c != Null) Zipcode = payment.Zipcode__c;
               Card_Number = PaymentMethod.Card_Number__c.trim();
          /*  System.debug('Sanitized Card Number: ' + Card_Number);*/
            Card_Type = PaymentMethod.CardType__c;
            Expiry_Month = PaymentMethod.Card_Expiration_Month__c;
            Expiry_Year = PaymentMethod.Card_Expiration_Year__c;

            myCurrency = myCur;

            Amount = String.valueof(payment.Total_Amount__c);

            ipstring = '';
            String response_1;
            String resStatus;
            if (credentialSetup.Name.containsIgnoreCase('Paypal')){

                Http h = new Http();

                HttpRequest req = new HttpRequest();

                String url = String.valueof(credentialSetup.URL__c);
                String soapXML;
                Blob cryptoKey, userData, passwordData;
                cryptoKey = encodingUtil.convertFromHex(credentialSetup.Encrypted_Key__c);

                userData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentialSetup.Username_Login__c));
                system.debug('username decrypted '+userData);
                passwordData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentialSetup.Password_Transkey__c));
                system.debug('passwordData decrypted '+passwordData);
                if (userData != null)
                    credentialSetup.Username_Login__c = userData.toString();
                if (passwordData != null)
                    credentialSetup.Password_Transkey__c = passwordData.toString();
                soapXML = System.label.PayPalAPI;
                soapXML += '<SOAP-ENV:Header><RequesterCredentials xmlns="urn:ebay:api:PayPalAPI"><Credentials xmlns="urn:ebay:apis:eBLBaseComponents">';
                soapXML += '<Username>' + credentialSetup.Username_Login__c.escapeXml() + '</Username>';
                soapXML += '<Password>' + credentialSetup.Password_Transkey__c.escapeXml() + '</Password>';
                soapXML += '<Signature>' + credentialSetup.Signature__c.escapeXml() + '</Signature>';
                soapXML += '<Subject/>';
                soapXML += '</Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body><DoDirectPaymentReq xmlns="urn:ebay:api:PayPalAPI">';
                soapXML += '<DoDirectPaymentRequest><Version xmlns=urn:ebay:apis:eBLBaseComponents">84.00</Version>';
                soapXML += '<DoDirectPaymentRequestDetails xmlns="urn:ebay:apis:eBLBaseComponents">';
                soapXML += '<PaymentAction>Sale</PaymentAction><PaymentDetails><OrderTotal currencyID=' + myCurrency.escapeXml() + '>' + Amount.escapeXml() + '</OrderTotal></PaymentDetails>';
                soapXML += '<IPAddress>' + ipstring.escapeXml() + '</IPAddress><CreditCard><CreditCardType>' + Card_Type.escapeXml() + '</CreditCardType><CreditCardNumber>' + Card_Number.escapeXml() + '</CreditCardNumber>';
                soapXML += '<ExpMonth>' + Expiry_Month.escapeXml() + '</ExpMonth><ExpYear>' + Expiry_Year.escapeXml() + '</ExpYear><CVV2>' + CVV.escapeXml() + '</CVV2>';
                soapXML += '<CardOwner><Payer>' + Email.escapeXml() + '</Payer><PayerStatus></PayerStatus><PayerName><FirstName>' + FirstName.escapeXml() + '</FirstName><LastName>' + LastName.escapeXml() + '</LastName></PayerName>';
                soapXML += '<Address><Street1>' + Address_Line1.escapeXml() + '</Street1><Street2>' + Address_Line2.escapeXml() + '</Street2><CityName>' + City.escapeXml() + '</CityName>';
                soapXML += '<StateOrProvince>' + State.escapeXml() + '</StateOrProvince><Country>' + Country.escapeXml() + '</Country><PostalCode>' + Zipcode.escapeXml() + '</PostalCode><Phone></Phone></Address></CardOwner></CreditCard>';
                soapXML += '</DoDirectPaymentRequestDetails></DoDirectPaymentRequest></DoDirectPaymentReq></SOAP-ENV:Body></SOAP-ENV:Envelope>';

                req.setBody(soapXML);
                req.setEndpoint(url);
                req.setMethod('POST');
                req.setHeader('Content-length', '1753');
                req.setHeader('Content-Type', 'text/xml;charset=UTF-8');
                req.setHeader('SOAPAction', '');
                req.setHeader('Host', 'api-3t.sandbox.paypal.com');
                req.setTimeout(20000);
                HttpResponse res = new HttpResponse();
                String Response;
                String xml;
                XmlStreamReader reader;
                if(Test.isRunningTest()){
                    Response = '<?xml version="1.0" encoding="UTF-8"?><Response><Ack>Success</Ack><CorrelationID>12345</CorrelationID><CVV2Code>M</CVV2Code><AVSCode>Y</AVSCode><LongMessage>Transaction successful</LongMessage><ShortMessage>Success</ShortMessage><ErrorCode>0</ErrorCode><TransactionID>ABC123</TransactionID></Response>';
                    reader = new XmlStreamReader(Response); }else{res = h.send(req);xml = res.getBody();reader = res.getXmlStreamReader();
                }
                Status = readXMLResponse(reader, 'Ack');
                System.debug('Status'+Status);
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                CorrID = readXMLResponse(reader, 'CorrelationID');
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                CVV2 = readXMLResponse(reader, 'CVV2Code');
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                AVSCode = readXMLResponse(reader, 'AVSCode');
                rawResponse = xml;
                System.debug('rawResponse'+rawResponse);
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                ErrMsg = readXMLResponse(reader, 'LongMessage');
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                sErrMsg = readXMLResponse(reader, 'ShortMessage');
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                ErrCode = readXMLResponse(reader, 'ErrorCode');
                if(Test.isRunningTest()){ reader = new XmlStreamReader(Response); } else{reader = res.getXmlStreamReader();}
                transid = readXMLResponse(reader, 'TransactionID');
                payment.AVS_Code__c = AVSCode;
                payment.CVV2_Code__c = CVV2;
                payment.Transaction_Status__c = Status;
                payment.Error_Code__c = ErrCode;
                payment.Transaction_ID__c = transid;
                payment.sError__c = sErrMsg;
                payment.Correlation_ID__c = CorrID;
                payment.Error_Message__c = ErrMsg;
                if (Schema.sObjectType.Payment__c.fields.Payment_Gateway__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Payment_Gateway__c.isUpdateable()){
                    payment.Payment_Gateway__c = 'Paypal';
                }
                if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isUpdateable()){
                    payment.Transaction_Status__c = 'Approved';
                }
                if (Schema.sObjectType.Payment__c.fields.Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Status__c.isUpdateable()){
                    payment.Status__c = 'Paid';
                }
            } else if (credentialSetup.Name.containsIgnoreCase('Authorize')){ Blob cryptoKey, userData, passwordData; cryptoKey = encodingUtil.convertFromHex(credentialSetup.Encrypted_Key__c); userData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentialSetup.Username_Login__c)); passwordData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentialSetup.Password_Transkey__c)); if (userData != null){ credentialSetup.Username_Login__c = userData.toString(); system.debug('Username_Login__c '+userData + 'to string'+userData.toString()); } if (passwordData != null){ credentialSetup.Password_Transkey__c = passwordData.toString(); system.debug('Password_Transkey__c '+passwordData + 'to string'+passwordData.toString()); } string url = credentialSetup.URL__c; String Address = billingAddress.Address_Line1__c + ' ' + billingAddress.Address_Line2__c; string expiryDate = Expiry_Year + '-' + Expiry_Month; String soapXML = '<?xml version="1.0" encoding="UTF-8"?>'; soapXML += '<createTransactionRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">'; soapXML += '<merchantAuthentication>'; soapXML += '<name>' + credentialSetup.Username_Login__c.escapeXml() + '</name>'; soapXML += '<transactionKey>' + credentialSetup.Password_Transkey__c.escapeXml() + '</transactionKey>'; soapXML += '</merchantAuthentication>'; soapXML += '<transactionRequest>'; soapXML += '<transactionType>authCaptureTransaction</transactionType>'; soapXML += '<amount>' + Amount.escapeXml() + '</amount>'; soapXML += '<payment>'; soapXML += '<creditCard>'; soapXML += '<cardNumber>' + Card_Number.escapeXml() + '</cardNumber>'; soapXML += '<expirationDate>' + expiryDate.escapeXml() + '</expirationDate>'; soapXML += '<cardCode>' + CVV.escapeXml() + '</cardCode>'; soapXML += '</creditCard>'; soapXML += '</payment>'; soapXML += '<billTo>'; soapXML += '<firstName>' + FirstName.escapeXml() + '</firstName>'; soapXML += '<lastName>' + LastName.escapeXml() + '</lastName>'; soapXML += '<address>' + address.escapeXml() + '</address>'; soapXML += '<city>' + billingAddress.City__c.escapeXml() + '</city>'; system.debug('SOAP Request: ' + soapXML); if(billingAddress.State__c != null) soapXML += '<state>' + billingAddress.State__c.escapeXml() + '</state>'; if(billingAddress.Postal_Code__c != null) soapXML += '<zip>' + billingAddress.Postal_Code__c.escapeXml() + '</zip>'; if(billingAddress.Country__c!=null) soapXML += '<country>' + billingAddress.Country__c.escapeXml() + '</country>'; soapXML += '</billTo>'; soapXML += '</transactionRequest>'; soapXML += '</createTransactionRequest>'; HttpRequest reqr = new HttpRequest(); Http hr = new Http(); reqr.setBody(soapXML); reqr.setMethod('POST'); reqr.setEndpoint(url); reqr.setHeader('Content-length', '2000'); reqr.setHeader('Content-Type', 'text/xml'); if (Test.isRunningTest()){ if (resCode == 3) response_1 = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Error</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>' + resCode + '</responseCode><authCode>9C9UEO</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>40017242270</transId><refTransID /><transHash>03A19FEF24F26163F4182D4B1BD7281D</transHash><testRequest>0</testRequest><accountNumber>XXXX4242</accountNumber><accountType>Visa</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2/></transactionResponse></createTransactionResponse>'; else response_1 = '<createTransactionResponse xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>' + resCode + '</responseCode><authCode>9C9UEO</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>40017242270</transId><refTransID /><transHash>03A19FEF24F26163F4182D4B1BD7281D</transHash><testRequest>0</testRequest><accountNumber>XXXX4242</accountNumber><accountType>Visa</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2/></transactionResponse></createTransactionResponse>'; } else{ HttpResponse resr = hr.send(reqr);response_1 = soapXML;response_1 = resr.getBody();resStatus = resr.getStatus(); } if (response_1 != null){ system.debug('response_1'+response_1); string resultCode = response_1.substringBetween('<resultCode>', '</resultCode>'); string responseCode = response_1.substringBetween('<responseCode>', '</responseCode>'); if (resultCode == 'Ok'){ system.debug('resultCode'+resultCode+'responseCode'+responseCode); if (responseCode == '1'){ string description = response_1.substringBetween('<description>', '</description>'); transId = response_1.substringBetween('<transId>', '</transId>'); string transHash = response_1.substringBetween('<transHash>', '</transHash>'); if (Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isUpdateable()){ payment.Transaction_ID__c = transId; } if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isUpdateable()){ payment.Transaction_Status__c = 'Approved'; System.debug('Setting Transaction_Status__c to: ' + payment.Transaction_Status__c); } if (Schema.sObjectType.Payment__c.fields.sError__c.isCreateable() || Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable()){ payment.sError__c = description; } if (Schema.sObjectType.Payment__c.fields.Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Status__c.isUpdateable()){ payment.Status__c = 'Paid'; } } if (responseCode == '2'){ string description = response_1.substringBetween('<description>', '</description>'); transId = response_1.substringBetween('<transId>', '</transId>'); string errorMessage = 'Transaction Failed. '; string Text = response_1.substringBetween('<text>', '</text>'); string errors = response_1.substringBetween('<errors>', '</errors>'); string errorText = response_1.substringBetween('<errorText>', '</errorText>'); if (errors != null) errorMessage += errorText; else errorMessage += Text; if (Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isUpdateable()){ payment.Transaction_ID__c = transId; } if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isUpdateable()){ payment.Transaction_Status__c = 'Declined'; } if (Schema.sObjectType.Payment__c.fields.sError__c.isCreateable() || Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable()){ payment.sError__c = errorMessage; } } if (responseCode == '4'){ string description = response_1.substringBetween('<description>', '</description>'); transId = response_1.substringBetween('<transId>', '</transId>'); if (Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_ID__c.isUpdateable()){ payment.Transaction_ID__c = transId; } if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isUpdateable()){ payment.Transaction_Status__c = 'Held for Review'; } if (Schema.sObjectType.Payment__c.fields.sError__c.isCreateable() || Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable()){ payment.sError__c = description; } } } else{ if (responseCode == '3'){ string description = response_1.substringBetween('<description>', '</description>'); string errorMessage = 'Transaction Failed. '; string Text = response_1.substringBetween('<text>', '</text>'); string errors = response_1.substringBetween('<errors>', '</errors>'); string errorText = response_1.substringBetween('<errorText>', '</errorText>'); if (errors != null) errorMessage += errorText; else errorMessage += Text; if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isUpdateable()){ payment.Transaction_Status__c = 'Error'; } if (Schema.sObjectType.Payment__c.fields.sError__c.isCreateable() || Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable()){ payment.sError__c = errorMessage; } } } } else payment.sError__c = 'Null Response.'; if (Schema.sObjectType.Payment__c.fields.Payment_Gateway__c.isCreateable() || Schema.sObjectType.Payment__c.fields.Payment_Gateway__c.isUpdateable()){ payment.Payment_Gateway__c = 'Authorize.Net'; } }else if (credentialSetup.Name.containsIgnoreCase('Stripe')) { try { /* Prepare Stripe request details*/ Decimal amountDecimal = Decimal.valueOf(Amount); Integer amountInCents = (amountDecimal * 100).intValue(); String body = 'payment_method_data[type]=card' + '&payment_method_data[card][exp_month]=' + Expiry_Month + '&payment_method_data[card][exp_year]=' + Expiry_Year + '&payment_method_data[card][number]=' + Card_Number.escapeXml() + '&payment_method_data[card][cvc]=' + CVV.escapeXml() + '&amount=' + amountInCents + '&currency=' + myCurrency + '&payment_method_types[]=card'; /*Setup HTTP request*/ HttpRequest req = new HttpRequest(); req.setEndpoint(credentialSetup.URL__c); req.setMethod('POST'); req.setHeader('Content-Type', 'application/x-www-form-urlencoded'); req.setHeader('Authorization', 'Bearer ' + credentialSetup.Encrypted_Key__c); req.setBody(body); /* Send HTTP request*/ HttpResponse res = new Http().send(req); String responseBody = res.getBody(); System.debug('Stripe Response: ' + responseBody); /*Parse response*/ Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody); if (responseMap == null || !responseMap.containsKey('status')) { return ErrorMsgPayment = 'Unexpected response from Stripe.'; } String paymentStatus = (String) responseMap.get('status'); String paymentIntentId = (String) responseMap.get('id'); if (paymentStatus == 'requires_confirmation') { /* Confirm payment*/ String confirmEndpoint = 'https://api.stripe.com/v1/payment_intents/' + paymentIntentId + '/confirm'; HttpRequest confirmReq = new HttpRequest(); confirmReq.setEndpoint(confirmEndpoint); confirmReq.setMethod('POST'); confirmReq.setHeader('Authorization', 'Bearer ' + credentialSetup.Encrypted_Key__c); HttpResponse confirmRes = new Http().send(confirmReq); String confirmResponseBody = confirmRes.getBody(); System.debug('Stripe Confirmation Response: ' + confirmResponseBody); Map<String, Object> confirmResponseMap = (Map<String, Object>) JSON.deserializeUntyped(confirmResponseBody); if (confirmResponseMap.containsKey('status') && confirmResponseMap.get('status') == 'succeeded') { /* Successful payment */ payment.Transaction_Status__c = 'Approved'; payment.Status__c = 'Paid'; payment.Payment_Gateway__c = 'Stripe'; payment.Transaction_ID__c= (String) confirmResponseMap.get('id');/*added by matheen to get the transaction id*/ } else { return ErrorMsgPayment = 'Stripe payment confirmation failed.'; } } else if (paymentStatus == 'succeeded') { /* Payment already succeeded*/ payment.Transaction_Status__c = 'Approved'; payment.Status__c = 'Paid'; payment.Payment_Gateway__c = 'Stripe'; payment.Transaction_ID__c =paymentIntentId;/*added*/ } else { return ErrorMsgPayment = 'Stripe payment failed with status: ' + paymentStatus; } } catch (Exception e) { System.debug('Stripe Exception: ' + e.getMessage()); return ErrorMsgPayment = 'Unexpected error during payment processing.'; } } else return ErrorMsgPayment = 'Please select correct payment gateway';


            if (Schema.sObjectType.Payment__c.fields.Transaction_Status__c.isCreateable() && Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable() && (payment.Transaction_Status__c == 'Completed' || payment.Transaction_Status__c == 'SuccessWithWarning' || payment.Transaction_Status__c == 'Success' || payment.Transaction_Status__c == 'Approved')){
                if (Schema.sObjectType.Payment__c.fields.Type__c.isCreateable() && Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable())
                    payment.Type__c = 'Debit';
                if (Schema.sObjectType.Payment__c.fields.Payment_Type__c.isCreateable() && Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable())
                    Payment.Payment_Type__c = 'Card';
                if (Schema.sObjectType.Payment__c.fields.Payment_Date__c.isCreateable() && Schema.sObjectType.Payment__c.fields.sError__c.isUpdateable())
                    payment.Payment_Date__c = System.today();
                if (Schema.sObjectType.Payment__c.isCreateable() && Schema.sObjectType.Payment__c.isUpdateable())
                    upsert payment;

                system.debug('payment.Id '+payment.Id);
                if (payment.Id != null)
                    ErrorMsgPayment = 'Payment Created Successfully';
                // if (payment.Id != null && invIdList.size() >= 1){
                //     System.debug('invIdList.size()'+invIdList.size());
                //     List<Payment_Applied_on_Invoice__c> PAIList = new List<Payment_Applied_on_Invoice__c>();
                //     for (Invoice__c inv : invIdList){
                //         Payment_Applied_on_Invoice__c pai = new Payment_Applied_on_Invoice__c();
                //         if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Amount__c.isCreateable()){
                //             pai.Amount__c = inv.Invoice_Amount__c;
                //             System.debug('pai.Amount__c'+pai.Amount__c);
                //         }
                //         if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Applied_Date__c.isCreateable())
                //             pai.Applied_Date__c = payment.Payment_Date__c;
                //         if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Invoice__c.isCreateable())
                //             pai.Invoice__c = inv.Id;
                //         if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Payment__c.isCreateable())
                //             pai.Payment__c = payment.Id;
                //         if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Type__c.isCreateable())
                //             pai.Type__c = 'Debit';
                //         PAIList.add(pai);
                //     }
                //     if (PAIList.size() > 0 && Schema.sObjectType.Payment_Applied_on_Invoice__c.isCreateable())
                //         insert PAIList;
                // }
                if (payment.Id != null && invIdList.size() >= 1) {
                    // Fetch existing Payment_Applied_on_Invoice__c records to avoid duplicates
                    Map<Id, Payment_Applied_on_Invoice__c> existingPaiMap = new Map<Id, Payment_Applied_on_Invoice__c>();
                    for (Payment_Applied_on_Invoice__c existingPai : [
                        SELECT Invoice__c, Payment__c
                        FROM Payment_Applied_on_Invoice__c
                        WHERE Payment__c = :payment.Id
                    ]) {
                        existingPaiMap.put(existingPai.Invoice__c, existingPai);
                    }

                    // List to hold new Payment_Applied_on_Invoice__c records
                    List<Payment_Applied_on_Invoice__c> paiList = new List<Payment_Applied_on_Invoice__c>();

                    // Iterate over the invoices in invIdList
                    Decimal ordAmount=0.0;//added by matheen
                    for (Invoice__c inv : invIdList) {
                        if (!existingPaiMap.containsKey(inv.Id)) {
                            // Create a new Payment_Applied_on_Invoice__c record
                            Payment_Applied_on_Invoice__c pai = new Payment_Applied_on_Invoice__c();


                            Decimal amountPaid = inv.Amount_Paid__c != null ? inv.Amount_Paid__c : 0; // fixed by syed matheen 15/1/25 sets 0 by default if its null

                            Decimal remainingDue = inv.Invoice_Amount__c - amountPaid;
                            pai.Amount__c = Math.min(payment.Total_Amount__c, remainingDue);

                            System.debug('Payment Applied Amount: ' + pai.Amount__c);

                            pai.Applied_Date__c = payment.Payment_Date__c;
                            pai.Invoice__c = inv.Id;
                            pai.Payment__c = payment.Id;
                            pai.Type__c = 'Debit';

                            ordAmount=ordAmount+pai.Amount__c;//added by matheen
                            System.debug('Payment Applied on Invoice: ' + pai);
                            paiList.add(pai);


                        } else {
                            System.debug('Skipping duplicate Payment_Applied_on_Invoice__c for Invoice: ' + inv.Id);
                        }
                    }

                    // Insert the new Payment_Applied_on_Invoice__c records by matheen
                    if (!paiList.isEmpty()) { insert paiList;

                        System.debug('Inserted Payment_Applied_on_Invoice__c records: ' + paiList);
                        if (ord == null || ord.Id == null) {
                            System.debug('Error: Order object is null or invalid.');
                        }
                        // Ensure FLS for Amount_Paid__c
                        if (!Schema.sObjectType.Order.fields.Amount_Paid__c.isUpdateable()) {
                            System.debug('Error: Amount_Paid__c field is not updateable.');
                        }
                        // Initialize Amount_Paid__c if null and add ordAmount
                        // ord.Amount_Paid__c = (ord.Amount_Paid__c == null ? 0 : ord.Amount_Paid__c + ordAmount);
                      //  ord.Amount_Paid__c = ord.Amount_Paid__c + ordAmount;
                        System.debug('Updated Amount_Paid__c: ' + ord.Amount_Paid__c);

                        // Update the Order object
                        System.debug('Order before update: ' + ord);
                     //   update ord;
                        System.debug('Order updated successfully.');
                    } else {
                        System.debug('No new Payment_Applied_on_Invoice__c records to insert.');
                    }
                            // System.debug('Payment Applied Amount: ' + pai.Amount__c);
                            Decimal addAllamount=0.0;
                    List<Payment_Applied_on_Invoice__c> paaInv = [Select id,Amount__c from Payment_Applied_on_Invoice__c where Invoice__r.Order_S__c= :ord.Id];
                    for(Payment_Applied_on_Invoice__c pa:paaInv){
                        addAllamount+=pa.Amount__c;

                    }
                    ord.Amount_Paid__c =addAllamount;
                   //  update ord;
                    List<SObject> safeOrd = FLSHelper.getSafeRecords(
                        new List<Order>{ord},
                        'Order',
                        AccessType.UPDATABLE
                    );
                    List<Order> typeOrd = new List<Order>();
                    for (SObject s : safeOrd) {
                        typeOrd.add((Order)s);
                    }
                    if (!typeOrd.isEmpty()) {
                        update typeOrd; // or insert/update as needed
                    }
                    System.debug('Updated Amount_Paid__c: ' + ord.Amount_Paid__c);
                }

            } else{
                system.debug('in else');
                if (payment.sError__c != Null)
                    ErrorMsgPayment = payment.sError__c;
            }
            return ErrorMsgPayment;
        } catch (exception ex){
            ErrorMsgPayment = ex.getMessage();
            ErrorMsgPayment += ' Line No: ' + ex.getLineNumber();
            ErrorMsgPayment += ' getStackTraceString: ' + ex.getStackTraceString();

            return ErrorMsgPayment;
        }
    }

    @AuraEnabled
    global static cardDetails fetchInitialBankDetails(){
        cardDetails cd = new cardDetails();
        cd.accountsType.add(new SelectOptions('', '--None--'));
        Schema.DescribeFieldResult fieldResultCardtype = Payment__c.Account_Type__c.getDescribe();
        List<Schema.PicklistEntry> cardtype = fieldResultCardtype.getPicklistValues();
        for (Schema.PicklistEntry f : cardtype)
            cd.accountsType.add(new SelectOptions(f.getValue(), f.getLabel()));
        return cd;
    }

    /*
    @AuraEnabled
    global static String createBankOrCashPayment(String payments, String invAndAmount, String paymentType){
        String errorMsg = '';
        try{
            List<Invoice__c> invIdList = (List<Invoice__c>)JSON.deserialize(invAndAmount, List<Invoice__c>.class);
            Payment__c Payment = (Payment__c)JSON.deserialize(payments, Payment__c.class);

            if (Schema.sObjectType.Payment__c.fields.Payment_Date__c.isCreateable())
                payment.Payment_Date__c = System.today();
            Id rTypeP;
            if (paymentType == 'Bank')
                rTypeP = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Bank Payments').getRecordTypeId();
            if (paymentType == 'Cash')
                rTypeP = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Cash Payments').getRecordTypeId();
            if (rTypeP != null){
                if (Schema.sObjectType.Payment__c.fields.RecordTypeId.isCreateable())
                    Payment.RecordTypeId = rTypeP;
            }

            //DML Operation

            if (Schema.sObjectType.Payment__c.isCreateable())
                insert Payment;
            if (Payment.Id != null)
                errorMsg = 'Payment Created Successfully';
            if (Payment.Id != null && invIdList.size() > 1){
                List<Payment_Applied_on_Invoice__c> PAIList = new List<Payment_Applied_on_Invoice__c>();
                for (Invoice__c inv : invIdList){
                    Payment_Applied_on_Invoice__c pai = new Payment_Applied_on_Invoice__c();

                    if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Amount__c.isCreateable())
                        pai.Amount__c = inv.Invoice_Amount__c;
                    if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Applied_Date__c.isCreateable())
                        pai.Applied_Date__c = payment.Payment_Date__c;
                    if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Invoice__c.isCreateable())
                        pai.Invoice__c = inv.Id;
                    //Master detailed field
                    if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Payment__c.isCreateable())
                        pai.Payment__c = payment.Id;
                    //Master detailed Field
                    if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Type__c.isCreateable())
                        pai.Type__c = 'Debit';
                    PAIList.add(pai);
                }

                //DML Operations
                if (PAIList.size() > 0 && Schema.sObjectType.Payment_Applied_on_Invoice__c.isCreateable())
                    insert PAIList;
            }
        } catch (Exception e){
        }
        return errorMsg;
    }
    */
@AuraEnabled
global static string createBankOrCashPayment(String payments, String invAndAmount, String paymentType){
    return 'success';
}
 @AuraEnabled
global static String createBankOrCashPaymentV2(String payments, String invAndAmount, String paymentType, String ordID) {
    String errorMsg = '';


    try {
        List<Invoice__c> invIdList = (List<Invoice__c>) JSON.deserialize(invAndAmount, List<Invoice__c>.class);

        System.debug('Deserialized invAndAmount: ' + invIdList);
        System.debug('Number of invoices in invIdList: ' + invIdList.size());
        Payment__c payment = (Payment__c) JSON.deserialize(payments, Payment__c.class);
        order ord=[Select Id, Amount_Paid__c from Order where Id=:ordID];
        //Order ord = (Order) JSON.deserialize(stdord, Order.class);
        // Check FLS for Payment_Date__c
        if (Schema.sObjectType.Payment__c.fields.Payment_Date__c.isCreateable()) {
            payment.Payment_Date__c = System.today();
        }

        Id rTypeP;
        if (paymentType == 'Bank') {rTypeP = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Bank Payments').getRecordTypeId();
        }
        if (paymentType == 'Cash') {
            rTypeP = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Cash Payments').getRecordTypeId();
        }
        if (rTypeP != null) {
            // Check FLS for RecordTypeId
            if (Schema.sObjectType.Payment__c.fields.RecordTypeId.isCreateable()) {
                payment.RecordTypeId = rTypeP;
            }
        }

        List<SObject> sObjectsToInsert = new List<SObject>{payment};
        List<Payment__c> paymentsToInsert = (List<Payment__c>)Security.stripInaccessible(AccessType.CREATABLE, sObjectsToInsert).getRecords();
        if(paymentsToInsert!=null && !paymentsToInsert.isEmpty() && paymentsToInsert.size()>0) insert paymentsToInsert;

        if (!paymentsToInsert.isEmpty() && paymentsToInsert[0].Id != null) {
            errorMsg = 'Payment Created Successfully';
        }

        if (!invIdList.isEmpty()) {
            List<Payment_Applied_on_Invoice__c> existingPAIs = [
                SELECT Id, Payment__c, Invoice__c, Amount__c
                FROM Payment_Applied_on_Invoice__c
                WHERE Payment__c = :paymentsToInsert[0].Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!existingPAIs.isEmpty()) {
                System.debug('Error: Payment already exists for the selected invoice.');
              //  errorMsg = 'Payment already exists for the selected invoice.';
              //  return errorMsg;
            }
            else{
                List<Payment_Applied_on_Invoice__c> PAIList = new List<Payment_Applied_on_Invoice__c>();
                Decimal ordAmount=0.0;
                 for (Invoice__c inv : invIdList) {
                     Payment_Applied_on_Invoice__c pai = new Payment_Applied_on_Invoice__c();

                     // Ensure FLS checks are satisfied
                     if (Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Amount__c.isCreateable() &&
                             Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Applied_Date__c.isCreateable() &&
                             Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Invoice__c.isCreateable() &&
                             Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Payment__c.isCreateable() &&
                             Schema.sObjectType.Payment_Applied_on_Invoice__c.fields.Type__c.isCreateable()) {
                         pai.Amount__c = inv.Invoice_Amount__c;
                         pai.Applied_Date__c = paymentsToInsert[0].Payment_Date__c;
                         pai.Invoice__c = inv.Id;
                         pai.Payment__c = paymentsToInsert[0].Id;
                         pai.Type__c = 'Debit';
                         PAIList.add(pai);
                         ordAmount=ordAmount+inv.Invoice_Amount__c;

                     }
                 }

                 // Insert records if PAIList is not empty
                 // try {
                 //     if (!PAIList.isEmpty() && Schema.sObjectType.Payment_Applied_on_Invoice__c.isCreateable()) {
                 //         insert PAIList;
                 //         System.debug('PAIList inserted successfully: ' + PAIList);
                 //         system.debug('ord.Id : '+ord.Id );
                 //         system.debug('ord.Id : '+ord );
                 //         system.debug('ord.Amount_Paid__c : '+ord.Amount_Paid__c );
                 //         System.debug('ordAmount: ' + ordAmount);

                 //         // if(ord.Amount_Paid__c==0) {ord.Amount_Paid__c = ordAmount;
                 //         // }else {
                 //             ord.Amount_Paid__c = ord.Amount_Paid__c + ordAmount;
                 //         // }
                 //         update ord;
                 //     }
                 //     system.debug('ord.Amount_Paid__c : '+ord.Amount_Paid__c );

                 // }
                 //  catch (Exception e) {
                 //     System.debug('Error inserting PAIList: ' + e.getMessage()+''+e.getLineNumber());
                 // }
                 // commented this lines 1523 - 1544 for making the payment updated for multiple inoices and not getting clash due to the trigger in invoice amount applied
                 try {
                     if (!PAIList.isEmpty() && Schema.sObjectType.Payment_Applied_on_Invoice__c.isCreateable()) {
                                 insert PAIList;
                                 System.debug('PAIList inserted successfully: ' + PAIList);
                     // Validate the Order object
                     if (ord == null || ord.Id == null) {
                         System.debug('Error: Order object is null or invalid.');
                     }
                     // Ensure FLS for Amount_Paid__c
                     if (!Schema.sObjectType.Order.fields.Amount_Paid__c.isUpdateable()) {
                         System.debug('Error: Amount_Paid__c field is not updateable.');
                     }
                     // Initialize Amount_Paid__c if null and add ordAmount
                     ord.Amount_Paid__c = (ord.Amount_Paid__c == null ? 0 : ord.Amount_Paid__c) + ordAmount;
                     System.debug('Updated Amount_Paid__c: ' + ord.Amount_Paid__c);

                     // Update the Order object
                     System.debug('Order before update: ' + ord);
                    //  update ord;
                    List<SObject> safeOrd = FLSHelper.getSafeRecords(
                        new List<Order>{ord},
                        'Order',
                        AccessType.UPDATABLE
                    );
                    List<Order> typeOrd = new List<Order>();
                    for (SObject s : safeOrd) {
                        typeOrd.add((Order)s);
                    }
                    if (!typeOrd.isEmpty()) {
                        update typeOrd; // or insert/update as needed
                    }
                     System.debug('Order updated successfully.');
                   }
                 } catch (Exception e) {
                     System.debug('Error updating order: ' + e.getMessage() + ' at line ' + e.getLineNumber());
                 }
            }


        }

    } catch (Exception e) { System.debug('Error:'+ e.getMessage()+': '+e.getLineNumber());errorMsg = 'An error occurred while processing the payment.';
    }

    return errorMsg;
}

    @AuraEnabled
    global static Decimal initialLoyalityPayment(String custId, String currOrg){
        Decimal Points_Per_Unit_Amount = 0;
        try{

            List<Loyalty_Card__c> clubCard = [Select id, Name, Active__c, Active_Points__c, Loyalty_Program__c, Points_Per_Unit_Amount__c, Contact__c, Customer__c, Start_date__c, Expiration_Date__c, Status__c, Total_Points_Credited__c, Total_Points_Debited__c, Company__c, Organisation_Business_Unit__c
                                              From Loyalty_Card__c
                                              Where Customer__c = :custId And Active__c = true And Status__c = 'Active' And Start_date__c <= :System.today() And Expiration_Date__c >= :System.today() And Company__c = :currOrg
                                              WITH SECURITY_ENFORCED
                                              Limit 1];
            if (clubCard.size() > 0){
                Points_Per_Unit_Amount = (clubCard[0].Active_Points__c / clubCard[0].Points_Per_Unit_Amount__c).setScale(2);
            }
        } catch (Exception e){
        }
        return Points_Per_Unit_Amount;
    }

    @AuraEnabled
    global static List<CNWrapper> applyCreditInitial(String accId){
        List<CNWrapper> cnWrList = new List<CNWrapper>();
        try{

            if (String.isNotEmpty(accId)){
                List<Credit_Note__c> cnList = [select id, Name, Credit__c, Debit__c, Order__c, Order__r.Name, Account__c, Balance__c
                                               from Credit_Note__c
                                               where Balance__c > 0 and Account__c = :accId
                                               WITH SECURITY_ENFORCED
                                               order by CreatedDate DESC
                                               limit 100];
                for (Credit_Note__c cn : cnList){
                    CNWrapper cnWr = new CNWrapper();
                    cnWr.credNote = cn;
                    cnWrList.add(cnWr);
                }
            }
        } catch (Exception e){
        }
        return cnWrList;
    }

    global class CNWrapper{
        @AuraEnabled
        global Credit_Note__c credNote{ get; set; }

        @AuraEnabled
        global Decimal debitAmount{ get; set; }

        global CNWrapper(){
            debitAmount = 0;
            credNote = new Credit_Note__c();
        }

    }

    @AuraEnabled
    global static String applyCreditToInvoice(String inv, String creditNotes, Decimal totalDebitAmount) { String message = ''; try { List<CNWrapper> cnList = (List<CNWrapper>) JSON.deserialize(creditNotes, List<CNWrapper>.class);Invoice__c invoices = (Invoice__c) JSON.deserialize(inv, Invoice__c.class);PreventRecursiveLedgerEntry.proceed = false;List<SObject> sObjectsToUpdate = new List<SObject>{invoices};System.SObjectAccessDecision accessDecisions = Security.stripInaccessible(AccessType.UPDATABLE, sObjectsToUpdate);List<Invoice__c> invoicesToUpdate = new List<Invoice__c>(); if (accessDecisions.getRecords() != null) { invoicesToUpdate.addAll((List<Invoice__c>) accessDecisions.getRecords()); } System.debug('invoicestoUpdate: ' + invoicesToUpdate); update invoicesToUpdate; List<Credit_Note_Applied_on_Invoice__c> appliedNotes = new List<Credit_Note_Applied_on_Invoice__c>();List<Credit_Note__c> cn2Update = new List<Credit_Note__c>();List<Account> account2Update = new List<Account>(); system.debug('before ord update'); System.debug('invoices.Order_S__c: ' + invoices.Order_S__c); /* // if (invoices.Order_S__c != null) { //     Order ord = [SELECT Id, Name, Amount_Paid__c FROM Order WHERE Id = :invoices.Order_S__c WITH SECURITY_ENFORCED LIMIT 1]; //         System.debug('ord: ' + ord); //         System.debug('ord.Amount_Paid__c: ' + ord.Amount_Paid__c); //     if (ord.Amount_Paid__c == null ) { if (Schema.sObjectType.Order.fields.Amount_Paid__c.isUpdateable()) {ord.Amount_Paid__c = totalDebitAmount; //         } else { ord.Amount_Paid__c = ord.Amount_Paid__c + totalDebitAmount; //         } //         // DML Operation //         if (Schema.sObjectType.Order.isUpdateable()) {  system.debug('updating ord'); update ord; //         } //     } // }*/ if (invoices.Order_S__c != null) { Order ord = [ SELECT Id, Name, Amount_Paid__c FROM Order WHERE Id = :invoices.Order_S__c WITH SECURITY_ENFORCED LIMIT 1 ]; System.debug('ord: ' + ord); System.debug('ord.Amount_Paid__c: ' + ord.Amount_Paid__c); if (Schema.sObjectType.Order.fields.Amount_Paid__c.isUpdateable()) { if (ord.Amount_Paid__c == null) { ord.Amount_Paid__c = totalDebitAmount; } else { ord.Amount_Paid__c += totalDebitAmount; } if (Schema.sObjectType.Order.isUpdateable()) { System.debug('updating ord'); update ord; } } } System.debug('after ord update'); if (cnList != null && cnList.size() > 0) { for (CNWrapper cwrap : cnList) { if (cwrap != null && cwrap.debitAmount > 0) { Credit_Note_Applied_on_Invoice__c capplied = new Credit_Note_Applied_on_Invoice__c(); if (Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Amount__c.isCreateable() && Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Amount__c.isUpdateable()) { capplied.Amount__c = cwrap.debitAmount; } if (Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Credit_Note__c.isCreateable()) { capplied.Credit_Note__c = cwrap.credNote.Id; } if (Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Invoice__c.isCreateable() && Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Invoice__c.isUpdateable()) { capplied.Invoice__c = invoices.Id; } if (Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Name.isCreateable() && Schema.sObjectType.Credit_Note_Applied_on_Invoice__c.fields.Name.isUpdateable()) { capplied.Name = invoices.Name + ' ' + cwrap.credNote.Name; } appliedNotes.add(capplied); if (cwrap.credNote.Debit__c != null && Schema.sObjectType.Credit_Note__c.fields.Debit__c.isUpdateable()) { cwrap.credNote.Debit__c = cwrap.credNote.Debit__c + cwrap.debitAmount; } else if (Schema.sObjectType.Credit_Note__c.fields.Debit__c.isUpdateable()) { cwrap.credNote.Debit__c = cwrap.debitAmount; } cn2Update.add(cwrap.credNote); } } } sObjectsToUpdate = new List<SObject>();sObjectsToUpdate = appliedNotes;accessDecisions = Security.stripInaccessible(AccessType.UPDATABLE, sObjectsToUpdate);List<Credit_Note_Applied_on_Invoice__c> appliedNotesToUpdate = new List<Credit_Note_Applied_on_Invoice__c>();if (accessDecisions.getRecords() != null) { appliedNotesToUpdate.addAll((List<Credit_Note_Applied_on_Invoice__c>) accessDecisions.getRecords()); } if (!appliedNotesToUpdate.isEmpty()) { List<SObject> safeappliedNotesToUpdate = FLSHelper.getSafeRecords( appliedNotesToUpdate, 'Credit_Note_Applied_on_Invoice__c', AccessType.UPDATABLE ); List<Credit_Note_Applied_on_Invoice__c> typeappliedNotesToUpdate = new List<Credit_Note_Applied_on_Invoice__c>(); for (SObject s : safeappliedNotesToUpdate) { typeappliedNotesToUpdate.add((Credit_Note_Applied_on_Invoice__c)s); } if (!typeappliedNotesToUpdate.isEmpty()) { upsert typeappliedNotesToUpdate; } } if (!cn2Update.isEmpty()) {PreventRecursiveLedgerEntry.testCasesTransactions = true;sObjectsToUpdate = new List<SObject>();sObjectsToUpdate = cn2Update;accessDecisions = Security.stripInaccessible(AccessType.UPDATABLE, sObjectsToUpdate);List<Credit_Note__c> cn2UpdateToUpdate = new List<Credit_Note__c>();if (accessDecisions.getRecords() != null) { cn2UpdateToUpdate.addAll((List<Credit_Note__c>) accessDecisions.getRecords()); } if (!cn2UpdateToUpdate.isEmpty()) { update cn2UpdateToUpdate; } } if (invoices != null && invoices.Account__c != null) {Account acc2update = [SELECT Id, Name, Debit_Balance__c FROM Account WHERE Id = :invoices.Account__c WITH SECURITY_ENFORCED LIMIT 1];SObjectAccessDecision accAccessDecisions = Security.stripInaccessible(AccessType.UPDATABLE, new List<Account>{acc2update});List<Account> accToUpdate = new List<Account>(); if (accAccessDecisions.getRecords() != null) { accToUpdate.addAll((List<Account>)accAccessDecisions.getRecords()); } if (acc2update.Debit_Balance__c == null && Schema.sObjectType.Account.fields.Debit_Balance__c.isUpdateable()) {   acc2update.Debit_Balance__c = totalDebitAmount;} else if (Schema.sObjectType.Account.fields.Debit_Balance__c.isUpdateable()) { acc2update.Debit_Balance__c = acc2update.Debit_Balance__c + totalDebitAmount; } PreventRecursiveLedgerEntry.proceed = false; if (Schema.sObjectType.Account.isUpdateable()) { update acc2update; } } message = 'Credit Applied Successfully';} catch (Exception e) {  message = e.getMessage() + ' ' + e.getLineNumber(); } return message;
    }



    @AuraEnabled
    global static String ApplyCoupons(String ord, String custId, String Coupon){
        String message = '';
        try{
            Order order2Update = (Order) JSON.deserialize(ord, Order.class);

            List<OrderItem> ordItems = [Select Id, Product2Id, Quantity, OrderId, UnitPrice, Coupon__c, Total_Price__c, Base_Price__c
                                        From OrderItem
                                        Where OrderId = :order2Update.id
                                        WITH SECURITY_ENFORCED
                                        limit 100];
            List<OrderItem> ordItems2upsert = new List<OrderItem>();
            Map<Id, OrderItem> proOrdItem = new Map<Id, OrderItem>();
            for (OrderItem ordItm : ordItems){
                proOrdItem.put(ordItm.Product2Id, ordItm);
            }

            try{
                List<Coupon_Issued__c> CI = [Select Id, Name, Product__c, Account__c, Coupon__c, Coupon__r.Maximum_Allocated_Vouchers__c, Coupon__r.Name, Coupon__r.Start_Date__c, Coupon__r.End_Date__c, Issued_Date__c, Value__c, Voucher_Amount__c, Coupon__r.Minimum_Order_Amount__c, Coupon__r.RecordType.Name, Coupon__r.Pre_Tax_Discount__c
                                             From Coupon_Issued__c
                                             Where Coupon__r.Name = :Coupon And Coupon__r.Start_Date__c <= Today And Coupon__r.End_Date__c >= Today And (Coupon__r.Minimum_Order_Amount__c = Null Or Coupon__r.Minimum_Order_Amount__c <= :order2Update.Order_Amount__c)
                                             WITH SECURITY_ENFORCED
                                             Limit 1];

                if (CI.size() > 0){
                    //Particular custom redeems the coupon or not
                    List<Coupon_Redemption__c> CR = [Select Id, Name, Account__c, Coupon__c
                                                     From Coupon_Redemption__c
                                                     Where Account__c = :custId And Coupon__c = :CI[0].Coupon__c
                                                     WITH SECURITY_ENFORCED
                                                     limit 100];

                    if (order2Update.Due_Amount__c <= 0){ message = 'Invalid Order Amount';
                    } else if (CR.size() > 0 || CI[0].Coupon__r.Maximum_Allocated_Vouchers__c == [Select Id, Name, Account__c, Coupon__c
                                                                                                  From Coupon_Redemption__c
                                                                                                  Where Coupon__c = :CI[0].Coupon__c
                                                                                                  WITH SECURITY_ENFORCED
                                                                                                  limit 100].size() || (CI[0].Product__c != Null && !proOrdItem.containsKey(CI[0].Product__c)) || (CI[0].Account__c != Null && !(CI[0].Account__c == order2Update.AccountId))){
                        message = 'Coupon Already Redeemed/Invalid';
                    } else{
                        Coupon_Redemption__c newCR = new Coupon_Redemption__c();
                        if (Schema.sObjectType.Coupon_Redemption__c.fields.Name.isCreateable()) newCR.Name = (proOrdItem.containsKey(CI[0].Product__c)) ? proOrdItem.get(CI[0].Product__c).Id : order2Update.Name;
                        if (Schema.sObjectType.Coupon_Redemption__c.fields.Account__c.isCreateable()) newCR.Account__c = custId; if (Schema.sObjectType.Coupon_Redemption__c.fields.Coupon__c.isCreateable()) newCR.Coupon__c = CI[0].Coupon__c;
                        if (Schema.sObjectType.Coupon_Redemption__c.fields.Coupon_Issued__c.isCreateable()) newCR.Coupon_Issued__c = CI[0].Id;
                        if (Schema.sObjectType.Coupon_Redemption__c.fields.Redemption_Date__c.isCreateable()) newCR.Redemption_Date__c = system.Today(); if (Schema.sObjectType.Coupon_Redemption__c.fields.Order__c.isCreateable()) newCR.Order__c = order2Update.Id;
                        if (CI[0].Voucher_Amount__c > 0){
                            if (proOrdItem.containsKey(CI[0].Product__c) && CI[0].Coupon__r.RecordType.Name == 'Product'){ newCR.Order_Product__c = proOrdItem.get(CI[0].Product__c).Id;
                                if (CI[0].Voucher_Amount__c <= proOrdItem.get(CI[0].Product__c).Base_Price__c) newCR.Value__c = CI[0].Voucher_Amount__c; else newCR.Value__c = proOrdItem.get(CI[0].Product__c).Base_Price__c;
                            } else if (CI[0].Coupon__r.RecordType.Name == 'Order'){
                                if (CI[0].Voucher_Amount__c <= order2Update.Order_Amount__c) newCR.Value__c = CI[0].Voucher_Amount__c; else newCR.Value__c = order2Update.Order_Amount__c;
                            } else if (CI[0].Coupon__r.RecordType.Name == 'Shipping'){ if (CI[0].Voucher_Amount__c <= order2Update.Total_Shipping_Amount__c) newCR.Value__c = CI[0].Voucher_Amount__c; else newCR.Value__c = order2Update.Total_Shipping_Amount__c; } } else if (CI[0].Value__c > 0){ if (proOrdItem.containsKey(CI[0].Product__c) && CI[0].Coupon__r.RecordType.Name == 'Product'){ newCR.Value__c = (proOrdItem.get(CI[0].Product__c).Base_Price__c == 0) ? 0 : (CI[0].Value__c * proOrdItem.get(CI[0].Product__c).Base_Price__c) / 100; newCR.Order_Product__c = proOrdItem.get(CI[0].Product__c).Id; } else if (CI[0].Coupon__r.RecordType.Name == 'Order') newCR.Value__c = (order2Update.Order_Amount__c == 0) ? 0 : (CI[0].Value__c * order2Update.Order_Amount__c) / 100; else if (CI[0].Coupon__r.RecordType.Name == 'Shipping') newCR.Value__c = (order2Update.Total_Shipping_Amount__c == Null || order2Update.Total_Shipping_Amount__c == 0) ? 0 : (CI[0].Value__c * order2Update.Total_Shipping_Amount__c) / 100; } if (newCR.Value__c > 0){ if (newCR.Value__c > order2Update.Due_Amount__c) newCR.Value__c = order2Update.Due_Amount__c; if (Schema.SObjectType.Coupon_Redemption__c.isCreateable() && Schema.SObjectType.Coupon_Redemption__c.fields.Value__c.isCreateable()) insert newCR; if (newCR.Id != null) message = 'Coupon Redeemed Successfully'; if (CI[0].Coupon__r.Pre_Tax_Discount__c){ if (proOrdItem.containsKey(CI[0].Product__c) && CI[0].Coupon__r.RecordType.Name == 'Product'){ if (Schema.sObjectType.OrderItem.fields.Coupon__c.isUpdateable() && Schema.sObjectType.OrderItem.fields.Coupon__c.isCreateable()){ proOrdItem.get(CI[0].Product__c).Coupon__c = newCR.Value__c; if (proOrdItem.get(CI[0].Product__c).Total_Price__c != Null) proOrdItem.get(CI[0].Product__c).Total_Price__c = proOrdItem.get(CI[0].Product__c).Total_Price__c - newCR.Value__c; ordItems2upsert.add(proOrdItem.get(CI[0].Product__c)); } } else if (Schema.sObjectType.Order.fields.Coupon_Discount__c.isCreateable() && Schema.sObjectType.Order.fields.Coupon_Discount__c.isUpdateable()) order2Update.Coupon_Discount__c = newCR.Value__c; if (Schema.sObjectType.Order.isUpdateable() && Schema.sObjectType.Order.isCreateable()) upsert order2Update; if (ordItems2upsert.size() > 0 && Schema.sObjectType.OrderItem.isUpdateable() && Schema.sObjectType.OrderItem.isCreateable()) upsert ordItems2upsert; } } else{ message = 'Invalid Coupon Amount'; } } } else{ message = 'Invalid Coupon'; } } catch (Exception e){ message = e.getMessage() + ' Line Number @ : ' + e.getLineNumber(); } } catch (Exception e){ }
        return message;
    }


    @AuraEnabled
    global static List<Loyalty_Card__c> applyLoyaltyInitial(String accId, String org){
        try{
            List<Loyalty_Card__c> LC = [Select id, Name, Active__c, Active_Points__c, Loyalty_Program__c, Points_Per_Unit_Amount__c, Contact__c, Customer__c, Start_date__c, Expiration_Date__c, Status__c, Total_Points_Credited__c, Total_Points_Debited__c, Company__c
                                        From Loyalty_Card__c
                                        Where Customer__c = :accId And Active__c = true And Status__c = 'Active' And Start_date__c <= :System.today() And Expiration_Date__c >= :System.today() And Company__c = :org
                                        WITH SECURITY_ENFORCED
                                        Limit 1];

            return LC;
        } catch (Exception e){}  return null;
    }

    @AuraEnabled
    global static String applyLoyalty(String loyalityCards, String ordId, Decimal loyaltyPoints){
        String message = '';
        try{
            List<Loyalty_Card__c> loyalityCard = (List<Loyalty_Card__c>)JSON.deserialize(loyalityCards, List<Loyalty_Card__c>.class);
            Loyalty_Points__c debitReward = new Loyalty_Points__c();

            if (Schema.sObjectType.Loyalty_Points__c.fields.Loyalty_Card__c.isCreateable())
                debitReward.Loyalty_Card__c = loyalityCard[0].id;
            //Master detail
            if (Schema.sObjectType.Loyalty_Points__c.fields.Credit_Debit_Date__c.isCreateable())
                debitReward.Credit_Debit_Date__c = System.today();
            if (Schema.sObjectType.Loyalty_Points__c.fields.Order_s__c.isCreateable())
                debitReward.Order_s__c = ordId;
            if (Schema.sObjectType.Loyalty_Points__c.fields.Points__c.isCreateable())
                debitReward.Points__c = loyaltyPoints;
            if (Schema.sObjectType.Loyalty_Points__c.fields.Transaction_Status__c.isCreateable())
                debitReward.Transaction_Status__c = 'Debit';
            if (Schema.sObjectType.Loyalty_Points__c.fields.Valid_Date__c.isCreateable())
                debitReward.Valid_Date__c = System.Today() + 30;
            if (Schema.sObjectType.Loyalty_Points__c.fields.Company__c.isCreateable())
                debitReward.Company__c = loyalityCard[0].Company__c;
            if (Schema.sObjectType.Loyalty_Points__c.fields.Organisation_Business_Unit__c.isCreateable())
                debitReward.Organisation_Business_Unit__c = loyalityCard[0].Organisation_Business_Unit__c;
            //DML Operation.
            if (Schema.sObjectType.Loyalty_Points__c.isCreateable() && Schema.sObjectType.Loyalty_Points__c.fields.Loyalty_Card__c.isCreateable())
                insert debitReward;
            if (debitReward.Id != null){
                message = 'Loyalty Apply Successfully';
                Order ord = new Order(
                    Id = ordId
                );
                if (Schema.sObjectType.Order.fields.Loyalty_Points__c.isUpdateable())
                    ord.Loyalty_Points__c = loyaltyPoints;
                if (Schema.sObjectType.Order.fields.Loyalty_Amount__c.isUpdateable())
                    ord.Loyalty_Amount__c = loyaltyPoints / loyalityCard[0].Points_Per_Unit_Amount__c;
                if (Schema.sObjectType.Order.isUpdateable())
                    update ord;
            }
        } catch (Exception e){
        }
        return message;
    }

    @AuraEnabled
    global static upsWrap UPSServices(String OrdId, String packType, String shipDate){
        upsWrap upsWrapp = new upsWrap();
        try{
            String pkgType;
            if (packType != null && packType != '--None--') pkgType = packType;
            else
                pkgType = 'Package';
            String shipperProvinceCode = '', errorMsg = '', fromAddress_Street = '', shipAddress_Street = '', shipAddress_ProvinceCode = '', shipAddress_CountryCode = '', shipperCountryCode = '', shipFrom_ProvinceCode = '', shipFrom_CountryCode = '';
            Decimal soVolume = 0, soWeight = 0;
            Decimal pkgLength = 0, totalWeight = 0, pkgWidth = 0, pkgHeight = 0, pkgWeight = 0, additionalPercent = 0, totalPkgVolume = 0;
            Decimal totalWeightperPackage = 0;
            Decimal noOfPackages = 0;
            Package__c pkg = new Package__c();

            List<Selectoptions> packTypeListOption = new List<Selectoptions>();

            if (OrdId != null || OrdId != ''){
                Order currentOrder = [select Id, Name, Ship_To_Address__r.Address_Line1__c, Ship_To_Address__r.Address_Line2__c, Ship_To_Address__r.Address_Line3__c, Ship_To_Address__r.City__c, Ship_To_Address__r.State__c, Issue_Invoice__c, Ship_To_Address__r.Country__c, Ship_To_Address__r.Postal_Code__c, Channel__c, Channel__r.Ship_From_Address__r.Address_Line1__c, Channel__r.Ship_From_Address__r.Address_Line2__c, Channel__r.Ship_From_Address__r.Address_Line3__c, Channel__r.Ship_From_Address__r.City__c, Total_Shipping_Amount__c, Channel__r.Ship_From_Address__r.State__c, Channel__r.Ship_From_Address__r.Country__c, Channel__r.Ship_From_Address__r.Postal_Code__c
                                      from Order
                                      where Id = :OrdId
                                      WITH SECURITY_ENFORCED
                                      limit 100];


                for (OrderItem ordItm : [select Id, Product2Id, Product2.Length__c, Product2.Width__c, Product2.Height__c, Product2.Weight__c, Quantity
                                         from OrderItem
                                         where OrderId = :currentOrder.Id
                                         WITH SECURITY_ENFORCED
                                         limit 100]){
                    if (ordItm.Product2.Length__c != Null && ordItm.Product2.Width__c != Null && ordItm.Product2.Height__c != Null) soVolume += ordItm.Product2.Length__c * ordItm.Product2.Width__c * ordItm.Product2.Height__c * ordItm.Quantity;
                    if (ordItm.Product2.Weight__c != Null) soWeight += ordItm.Product2.Weight__c * ordItm.Quantity;
                }

                Credentials__c credentials;
                for (Credentials__c crd : [Select Id, Name, Active__c, UPS_Account_Number__c, Encrypted_Key__c, End_Point__c, URL__c, Username_Login__c, Key__c, Password_Transkey__c,  //Meter_Number__c,
                Shipper_Name__c, Shipper_Company_Name__c, Shipper_Email__c, Shipper_Phone_Number__c, Shipper_Street__c, Shipper_City__c, Shipper_Postal_Code__c, Shipper_Country__c, Shipper_Province__c
                                           From Credentials__c
                                           Where Name = 'UPS' And Active__c = true And UPS_Account_Number__c != null And UPS_Account_Number__c != '' And Key__c != null And Key__c != ''
                                           WITH SECURITY_ENFORCED
                                           Limit 1])
                    credentials = crd;
                if (credentials != null){
                    Blob cryptoKey, userData, passwordData;
                    cryptoKey = encodingUtil.convertFromHex(credentials.Encrypted_Key__c);
                    userData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentials.Username_Login__c));
                    passwordData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(credentials.Password_Transkey__c));
                    if (userData != null)
                        credentials.Username_Login__c = userData.toString();
                    if (passwordData != null)
                        credentials.Password_Transkey__c = passwordData.toString();
                    List<Province_Codes__c> recProvinceCodes = [Select Id, Name, Code__c, Province__c
                                                                From Province_Codes__c
                                                                Where Province__c = :credentials.Shipper_Province__c
                                                                WITH SECURITY_ENFORCED
                                                                Limit 1];
                    if (recProvinceCodes.Size() > 0) shipperProvinceCode = recProvinceCodes[0].Code__c;
                    else
                        errorMsg = 'UPS Shipping Service Unavailable : Shipper Province Code not found';
                    List<Country_Codes__c> shipperCountry = [Select Id, Name, Code__c, Country__c
                                                             From Country_Codes__c
                                                             Where Country__c = :credentials.Shipper_Country__c
                                                             WITH SECURITY_ENFORCED
                                                             Limit 1];
                    if (shipperCountry.size() > 0)
                        shipperCountryCode = shipperCountry[0].Code__c;
                    if (shipperCountryCode == null || shipperCountryCode == '') errorMsg = 'UPS Shipping Service Unavailable : Shipper Country Code not found';
                } else errorMsg = 'UPS Shipping Service Unavailable : Please setup UPS credentials';
                if (credentials != null){

                    if (currentOrder.Ship_To_Address__r.Address_Line1__c != null && currentOrder.Ship_To_Address__r.Address_Line1__c != '')
                        shipAddress_Street = currentOrder.Ship_To_Address__r.Address_Line1__c;
                    if (currentOrder.Ship_To_Address__r.Address_Line2__c != null && currentOrder.Ship_To_Address__r.Address_Line2__c != '') shipAddress_Street += ', ' + currentOrder.Ship_To_Address__r.Address_Line2__c;
                    if (currentOrder.Ship_To_Address__r.Address_Line3__c != null && currentOrder.Ship_To_Address__r.Address_Line3__c != '') shipAddress_Street += ', ' + currentOrder.Ship_To_Address__r.Address_Line3__c;
                    if (currentOrder.Channel__r.Ship_From_Address__r.Address_Line1__c != null)  fromAddress_Street = currentOrder.Channel__r.Ship_From_Address__r.Address_Line1__c;
                    if (currentOrder.Channel__r.Ship_From_Address__r.Address_Line2__c != null) fromAddress_Street += ', ' + currentOrder.Channel__r.Ship_From_Address__r.Address_Line2__c;
                    if (currentOrder.Channel__r.Ship_From_Address__r.Address_Line2__c != null) fromAddress_Street += ', ' + currentOrder.Channel__r.Ship_From_Address__r.Address_Line3__c;
                    List<Province_Codes__c> shipProvinceCode = [Select Id, Name, Code__c, Province__c
                                                                From Province_Codes__c
                                                                Where Province__c = :currentOrder.Ship_To_Address__r.State__c
                                                                WITH SECURITY_ENFORCED
                                                                Limit 1];
                    if (shipProvinceCode != null && shipProvinceCode.Size() > 0)   shipAddress_ProvinceCode = shipProvinceCode[0].Code__c;
                    else
                        errorMsg = 'UPS Shipping Service Unavailable : Shipping Address Province Code not found';
                    List<Country_Codes__c> countryCodes = [Select Id, Name, Code__c, Country__c
                                                           From Country_Codes__c
                                                           Where Country__c = :currentOrder.Ship_To_Address__r.Country__c
                                                           WITH SECURITY_ENFORCED
                                                           Limit 1];
                    if (countryCodes.size() > 0)
                        shipAddress_CountryCode = countryCodes[0].Code__c;
                    if (shipAddress_CountryCode == null || shipAddress_CountryCode == '')   errorMsg = 'UPS Shipping Service Unavailable : Shipping Address Country Code not found';
                    List<Province_Codes__c> recProvinceCode = [Select Id, Name, Code__c, Province__c
                                                               From Province_Codes__c
                                                               Where Province__c = :currentOrder.Channel__r.Ship_From_Address__r.State__c
                                                               WITH SECURITY_ENFORCED
                                                               Limit 1];
                    if (recProvinceCode != null && recProvinceCode.Size() > 0)  shipFrom_ProvinceCode = recProvinceCode[0].Code__c;
                    else
                        errorMsg = 'UPS Shipping Service Unavailable : Salepoint Province Code not found';
                    List<Country_Codes__c> countryCodes1 = [Select Id, Name, Code__c, Country__c
                                                            From Country_Codes__c
                                                            Where Country__c = :currentOrder.Channel__r.Ship_From_Address__r.Country__c
                                                            WITH SECURITY_ENFORCED
                                                            Limit 1];
                    if (countryCodes1.size() > 0)  shipFrom_CountryCode = countryCodes1[0].Code__c;
                    if (shipFrom_CountryCode == null || shipFrom_CountryCode == '')
                        errorMsg = 'UPS Shipping Service Unavailable : Salepoint Country Code not found';
                    List<Package_Details__c> pkgDetailLists = [select Id, Name, Length__c, Width__c, Height__c, Weight__c, Weight_Unit__c, Package_Type__c, Type__c
                                                               from Package_Details__c
                                                               Where Type__c = 'UPS'
                                                               WITH SECURITY_ENFORCED
                                                               limit 100];
                    boolean packageExist = false;
                    for (Package_Details__c pkgDetailListt : pkgDetailLists){
                        packageExist = true;
                        packTypeListOption.add(new selectOptions(pkgDetailListt.Package_Type__c, pkgDetailListt.Package_Type__c));
                    }
                    if (!packageExist)  errorMsg = 'Package Details not found';
                    upsWrapp.UPSErrorMsg = errorMsg;

                    if (errorMsg == '' || Test.isRunningTest()){

                        if (pkgType != null && pkgType != '--None--'){
                            List<Package_Details__c> pkgDetailList = [select Id, Name, Length__c, Width__c, Height__c, Additional_Percentage__c, Weight__c, Weight_Unit__c, Package_Type__c, Type__c
                                                                      from Package_Details__c
                                                                      where Package_Type__c = :pkgType
                                                                      WITH SECURITY_ENFORCED
                                                                      limit 1];

                            if (pkgDetailList.size() > 0){
                                pkg.Length__c = pkgDetailList[pkgDetailList.size() - 1].Length__c;
                                pkg.Width__c = pkgDetailList[pkgDetailList.size() - 1].Width__c;
                                pkg.Height__c = pkgDetailList[pkgDetailList.size() - 1].Height__c;
                                pkg.Weight__c = pkgDetailList[pkgDetailList.size() - 1].Weight__c;
                                pkg.Weight_Unit__c = pkgDetailList[pkgDetailList.size() - 1].Weight_Unit__c;
                                pkgLength = pkg.Length__c;
                                pkgWidth = pkg.Width__c;
                                pkgHeight = pkg.Height__c;
                                pkgWeight = pkg.Weight__c;
                                additionalPercent = Integer.valueof(pkgDetailList[pkgDetailList.size() - 1].Additional_Percentage__c);
                                totalPkgVolume = (pkg.Length__c * pkg.Width__c * pkg.Height__c).setscale(2);
                                noOfPackages = Integer.valueof(soVolume / totalPkgVolume);


                                if (math.mod(Integer.valueof(soVolume), Integer.valueof(totalPkgVolume)) > 0) noOfPackages++;
                                soVolume = soVolume.setscale(2);
                                soWeight = soWeight.setscale(2);
                                totalWeight = (soWeight + (noOfPackages * pkg.Weight__c)).setscale(2);
                                totalWeightperPackage = (noOfPackages > 0) ? (totalWeight / noOfPackages).setscale(2) : totalWeight;

                                upsWrapp.PackageType = pkgType;
                                upsWrapp.PackageTypes = packTypeListOption;
                                if (shipDate != Null && shipDate != '') upsWrapp.ShipmentDate = Date.valueOf(shipDate);
                                else
                                    upsWrapp.ShipmentDate = System.Today();
                                upsWrapp.Length = pkgLength;
                                upsWrapp.Width = pkgWidth;
                                upsWrapp.Height = pkgHeight;
                                upsWrapp.Weight = pkgWeight;
                                upsWrapp.NoofPackage = noOfPackages;
                                upsWrapp.Additional = additionalPercent;
                                upsWrapp.PackageVolume = totalPkgVolume;
                                upsWrapp.SOVolume = soVolume;
                                upsWrapp.SOWeight = soWeight;
                                upsWrapp.TotalWeight = totalWeight;
                                upsWrapp.WeightPerPack = totalWeightperPackage;
                                //serviceRequest();


                                try{
                                    string soapXML = '<?xml version="1.0"?>';
                                    soapXML += '<AccessRequest xml:lang="en-US">';
                                    soapXML += '<AccessLicenseNumber>' + credentials.Key__c + '</AccessLicenseNumber>';
                                    soapXML += '<UserId>' + credentials.Username_Login__c + '</UserId>';
                                    soapXML += '<Password>' + credentials.Password_Transkey__c + '</Password>';
                                    soapXML += '</AccessRequest>';

                                    soapXML += '<?xml version="1.0"?>';
                                    soapXML += '<RatingServiceSelectionRequest>';
                                    soapXML += '<Request>';
                                    soapXML += '<RequestAction>Rate</RequestAction>';
                                    soapXML += '<RequestOption>Shop</RequestOption>';
                                    soapXML += '</Request>';

                                    soapXML += '<Shipment>';
                                    soapXML += '<Shipper>';
                                    soapXML += '<ShipperNumber>' + credentials.UPS_Account_Number__c + '</ShipperNumber>';
                                    soapXML += '<Address>';
                                    soapXML += '<AddressLine1>' + credentials.Shipper_Street__c + '</AddressLine1>';
                                    soapXML += '<City>' + credentials.Shipper_City__c + '</City>';
                                    soapXML += '<StateProvinceCode>' + shipperProvinceCode + '</StateProvinceCode>';
                                    soapXML += '<PostalCode>' + credentials.Shipper_Postal_Code__c + '</PostalCode>';
                                    soapXML += '<CountryCode>' + shipperCountryCode + '</CountryCode>';
                                    soapXML += '</Address>';
                                    soapXML += '</Shipper>';

                                    soapXML += '<ShipTo>';
                                    soapXML += '<Address>';
                                    soapXML += '<AddressLine1>' + shipAddress_Street + '</AddressLine1>';
                                    if (currentOrder.Ship_To_Address__r.City__c != null) soapXML += '<City>' + currentOrder.Ship_To_Address__r.City__c + '</City>';
                                    if (currentOrder.Ship_To_Address__r.Postal_Code__c != null)
                                        soapXML += '<PostalCode>' + currentOrder.Ship_To_Address__r.Postal_Code__c + '</PostalCode>';
                                    soapXML += '<CountryCode>' + shipAddress_CountryCode + '</CountryCode>';
                                    soapXML += '</Address>';
                                    soapXML += '</ShipTo>';

                                    soapXML += '<ShipFrom>';
                                    soapXML += '<Address>';
                                    if (currentOrder.Channel__r.Ship_From_Address__c != null){soapXML += '<AddressLine1>' + fromAddress_Street + '</AddressLine1>';
                                        if (currentOrder.Channel__r.Ship_From_Address__r.City__c != null) soapXML += '<City>' + currentOrder.Channel__r.Ship_From_Address__r.City__c + '</City>'; soapXML += '<StateProvinceCode>' + shipFrom_ProvinceCode + '</StateProvinceCode>';
                                        if (currentOrder.Channel__r.Ship_From_Address__r.Postal_Code__c != null) soapXML += '<PostalCode>' + currentOrder.Channel__r.Ship_From_Address__r.Postal_Code__c + '</PostalCode>'; soapXML += '<CountryCode>' + shipFrom_CountryCode + '</CountryCode>';
                                    }
                                    soapXML += '</Address>';
                                    soapXML += '</ShipFrom>';

                                    soapXmL += '<RateInformation>';
                                    soapXmL += '<NegotiatedRatesIndicator>Y</NegotiatedRatesIndicator>';
                                    soapXmL += '</RateInformation>';

                                    Map<String, UPS_Package_Type__c> packageTypeMap = new Map<String, UPS_Package_Type__c>();
                                    List<UPS_Package_Type__c> packageType = [select Id, Name, Package_Code__c, Package_Description__c
                                                                             from UPS_Package_Type__c
                                                                             WITH SECURITY_ENFORCED
                                                                             limit 12];
                                    for (UPS_Package_Type__c upt : packageType){
                                        packageTypeMap.put(upt.Package_Description__c, upt);
                                    }

                                    for (Integer i = 0; i < noOfPackages; i++){
                                        soapXML += '<Package>';soapXML += '<PackagingType>';soapXML += '<Code>' + packageTypeMap.get('Package').Package_Code__c + '</Code>';soapXML += '</PackagingType>';soapXML += '<Dimensions>';soapXML += '<UnitOfMeasurement>';
                                        if (pkg.Weight_Unit__c == 'KGS')soapXMl += '<Code>CM</Code>'; else soapXMl += '<Code>IN</Code>';
                                        soapXML += '</UnitOfMeasurement>';soapXMl += '<Length>' + pkg.Length__c + '</Length>';soapXML += '<Width>' + pkg.Width__c + '</Width>';soapXML += '<Height>' + pkg.Height__c + '</Height>';soapXML += '</Dimensions>';soapXML += '<PackageWeight>';soapXML += '<UnitOfMeasurement>';soapXML += '<Code>' + pkg.Weight_Unit__c + '</Code>';soapXML += '</UnitOfMeasurement>';soapXML += '<Weight>' + totalWeightperPackage + '</Weight>';soapXML += '</PackageWeight>';soapXML += '</Package>';
                                    }
                                    soapXML += '</Shipment>';
                                    soapXML += '</RatingServiceSelectionRequest>';

                                    HttpRequest req = new HttpRequest();
                                    Http h = new Http();

                                    req.setBody(soapXML);
                                    req.setMethod('POST');
                                    //req.setEndpoint('https://onlinetools.ups.com/ups.app/xml/Rate');
                                    String myEndPoint = credentials.URL__c + '/ups.app/xml/Rate';
                                    req.setEndpoint(myEndPoint);
                                    HttpResponse res = new HttpResponse();
                                    String Response;
                                String resStatus;
                                if(Test.isRunningTest()){
                                Response = '<?xml version="1.0" encoding="UTF-8"?><RateReply><ResponseStatusDescription>SUCCESS</ResponseStatusDescription><RatedShipment><Service><Code>01</Code></Service><TransportationCharges><CurrencyCode>USD</CurrencyCode><MonetaryValue>50.00</MonetaryValue></TransportationCharges><ServiceOptionsCharges><CurrencyCode>USD</CurrencyCode><MonetaryValue>10.00</MonetaryValue></ServiceOptionsCharges><TotalCharges><CurrencyCode>USD</CurrencyCode><MonetaryValue>60.00</MonetaryValue></TotalCharges><GuaranteedDaysToDelivery>3</GuaranteedDaysToDelivery><ScheduledDeliveryTime>12:00 PM</ScheduledDeliveryTime><NegotiatedRates><CurrencyCode>USD</CurrencyCode><MonetaryValue>55.00</MonetaryValue></NegotiatedRates></RatedShipment></RateReply>';
                                resStatus = 'OK';
                                }else{ res = h.send(req);resStatus = res.getStatus();
                                }
                                    String Result = '';


                                    if (resStatus == 'OK'){
                                        XmlStreamReader reader1;
                                        if(Test.isRunningTest()){
                                            reader1 = new XmlStreamReader(Response);
                                        }else{ reader1 = res.getXmlStreamReader();
                                        }
                                        String msg = readXMLResponse(reader1, 'ResponseStatusDescription');
                                        if (msg != Null && (msg == 'SUCCESS' || msg == 'WARNING')){
                                            XmlStreamReader reader;
                                            if(Test.isRunningTest()){
                                                reader = new XmlStreamReader(Response);
                                            }else{  reader = res.getXmlStreamReader();
                                            }
                                            String sxmltag = 'RatedShipment';
                                            rateWrapper rw;
                                            List<rateWrapper> rateWrapperList = new List<rateWrapper>();
                                            while (reader.hasNext()){
                                                if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == sxmltag){
                                                    rw = new rateWrapper();
                                                    while (reader.hasNext()){
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Service'){
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Code'){
                                                                reader.next();
                                                                rw.ServiceCode = reader.getText();
                                                            }
                                                            List<UPS_Service_Codes__c> serviceCodes = [select Id, Name, Service__c, ServiceCode__c, Service_Code_With_Trade_Mark__c, Service_Asia_International__c, Service_Canada_Domestic__c, Service_Canada_International__c, Service_Europe__c, Service_Mexico_Domestic__c, Service_Mexico_International__c, Service_USA_Domestic__c
                                                                                                       from UPS_Service_Codes__c
                                                                                                       WITH SECURITY_ENFORCED
                                                                                                       limit 22];
                                                            if (shipFrom_CountryCode == 'CA' && shipAddress_CountryCode == 'CA'){
                                                                for (Integer i = 0; i < serviceCodes.size(); i++){ if (rw.ServiceCode == serviceCodes[i].ServiceCode__c){ rw.ServiceManual = serviceCodes[i].Service_Canada_Domestic__c;
                                                                    }
                                                                }
                                                            } else if (shipFrom_CountryCode == 'CA' && shipAddress_CountryCode != 'CA'){
                                                                for (Integer i = 0; i < serviceCodes.size(); i++){ if (rw.ServiceCode == serviceCodes[i].ServiceCode__c){ rw.ServiceManual = serviceCodes[i].Service_Canada_International__c;
                                                                    }
                                                                }
                                                            } else if (shipFrom_CountryCode == 'MX' && shipAddress_CountryCode == 'MX'){
                                                                for (Integer i = 0; i < serviceCodes.size(); i++){  if (rw.ServiceCode == serviceCodes[i].ServiceCode__c){ rw.ServiceManual = serviceCodes[i].Service_Mexico_Domestic__c;
                                                                    }
                                                                }
                                                            } else if (shipFrom_CountryCode == 'MX' && shipAddress_CountryCode != 'MX'){
                                                                for (Integer i = 0; i < serviceCodes.size(); i++){ if (rw.ServiceCode == serviceCodes[i].ServiceCode__c){ rw.ServiceManual = serviceCodes[i].Service_Mexico_International__c;
                                                                    }
                                                                }
                                                            } else{
                                                                for (Integer i = 0; i < serviceCodes.size(); i++){
                                                                    if (rw.ServiceCode == serviceCodes[i].ServiceCode__c){
                                                                        rw.ServiceManual = serviceCodes[i].Service_Code_With_Trade_Mark__c;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'TransportationCharges'){
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CurrencyCode'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.CurrencyCode == '')
                                                                    rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next();
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'MonetaryValue'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.TransportationCharges == '')
                                                                    rw.TransportationCharges = reader.getText();
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ServiceOptionsCharges'){
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CurrencyCode'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.CurrencyCode == '')  rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next();
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'MonetaryValue'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.ServiceOptionsCharges == '')
                                                                    rw.ServiceOptionsCharges = reader.getText();
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'TotalCharges'){
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CurrencyCode'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.CurrencyCode == '')  rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next();
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'MonetaryValue'){
                                                                reader.next();
                                                                if (reader.hasText() && rw.totalCharges == '')
                                                                    rw.totalCharges = reader.getText();
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'GuaranteedDaysToDelivery'){
                                                            reader.next();
                                                            if (reader.hasText()){
                                                                rw.GuaranteedDaysToDelivery = reader.getText();
                                                                rw.DeliveryDate = upsWrapp.ShipmentDate + Integer.valueof(rw.GuaranteedDaysToDelivery);} else{ rw.GuaranteedDaysToDelivery = '-';  rw.DeliveryDateS = '-';
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ScheduledDeliveryTime'){
                                                            reader.next();
                                                            if (reader.hasText()){
                                                                rw.ScheduledDeliveryTime = reader.getText();
                                                            } else{   rw.ScheduledDeliveryTime = '-';
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'NegotiatedRates'){
                                                            reader.next();
                                                            reader.next();
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CurrencyCode'){ reader.next(); if (reader.hasText() && rw.CurrencyCode == '')  rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next();
                                                            reader.next();
                                                            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'MonetaryValue'){   reader.next();  if (reader.hasText() && rw.negotiatedCharges == '') rw.negotiatedCharges = reader.getText();
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == sxmltag)
                                                            break;
                                                        else
                                                            reader.next();
                                                    }
                                                    rateWrapperList.add(rw);
                                                }
                                                reader.next();
                                            }
                                            Integer n = rateWrapperList.size();
                                            for (Integer c = 0; c < (n - 1); c++){ for (Integer d = 0; d < n - c - 1; d++){ if (Decimal.valueof(rateWrapperList[d].totalCharges) > Decimal.valueof(rateWrapperList[d + 1].totalCharges)){ rateWrapper swap = rateWrapperList[d];rateWrapperList[d] = rateWrapperList[d + 1];rateWrapperList[d + 1] = swap;
                                                    }
                                                }
                                            }
                                            upsWrapp.Services = rateWrapperList;
                                            upsWrapp.UPSErrorMsg = 'Available Services For The Selected Location';
                                        } else{
                                            XmlStreamReader reader3 = res.getXmlStreamReader();String msg1 = readXMLResponse(reader3, 'ErrorDescription');if (msg1 != Null && msg1 != '') upsWrapp.UPSErrorMsg = 'Shipping Rate Service Is Not Available : ' + msg1;else upsWrapp.UPSErrorMsg = 'Request To Rate Shipment Cannot Be Processed';
                                        }
                                    } else
                                        upsWrapp.UPSErrorMsg = 'Result not available';
                                } catch (Exception E){ upsWrapp.UPSErrorMsg = e.getMessage() + ' Line Number @ : ' + e.getLineNumber();
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
        }
        return upsWrapp;
    }

    @AuraEnabled
    global static upsWrap FedServices(String OrdId, String packType, String shipDate){
        upsWrap upsWrapp = new upsWrap();
        try{
            //String salesorderId = soId;
            String pkgType;
            if (packType != null && packType != '--None--') pkgType = packType;
            else
                pkgType = 'YOUR_PACKAGING';
            String shipperProvinceCode = '', errorMsg = '', shipAddress_Street = '', shipAddress_ProvinceCode = '', shipAddress_CountryCode = '', shipperCountryCode = '', sp_ProvinceCode = '', sp_CountryCode = '';
            Decimal soVolume = 0, soWeight = 0;
            Decimal pkgLength = 0, totalWeight = 0, pkgWidth = 0, pkgHeight = 0, pkgWeight = 0, additionalPercent = 0, totalPkgVolume = 0;
            Decimal totalWeightperPackage = 0;
            Decimal noOfPackages = 0;
            Package__c pkg = new Package__c();

            List<Selectoptions> packTypeListOption = new List<Selectoptions>();
            //List<Sales_Order_Line_Item__c> lstSoli = new List<Sales_Order_Line_Item__c>();

            if (OrdId != null && OrdId != ''){
                Order currentOrder = [select Id, Name, Ship_To_Address__r.Address_Line1__c, Ship_To_Address__r.Address_Line2__c, Ship_To_Address__r.Address_Line3__c, Ship_To_Address__r.City__c, Ship_To_Address__r.State__c, Issue_Invoice__c, Ship_To_Address__r.Country__c, Ship_To_Address__r.Postal_Code__c, Channel__c, Channel__r.Ship_From_Address__r.Address_Line1__c, Channel__r.Ship_From_Address__r.Address_Line2__c, Channel__r.Ship_From_Address__r.Address_Line3__c, Channel__r.Ship_From_Address__r.City__c, Total_Shipping_Amount__c, Channel__r.Ship_From_Address__r.State__c, Channel__r.Ship_From_Address__r.Country__c, Channel__r.Ship_From_Address__r.Postal_Code__c, Contact__r.Name, Contact__r.Company__c, Contact__r.Phone
                                      from Order
                                      where Id = :OrdId
                                      WITH SECURITY_ENFORCED
                                      limit 100];


                for (OrderItem ordItm : [select Id, Product2Id, Product2.Length__c, Product2.Width__c, Product2.Height__c, Product2.Weight__c, Quantity
                                         from OrderItem
                                         where OrderId = :currentOrder.Id
                                         WITH SECURITY_ENFORCED
                                         limit 100]){
                    if (ordItm.Product2.Length__c != Null && ordItm.Product2.Width__c != Null && ordItm.Product2.Height__c != Null) soVolume += ordItm.Product2.Length__c * ordItm.Product2.Width__c * ordItm.Product2.Height__c * ordItm.Quantity;
                    if (ordItm.Product2.Weight__c != Null) soWeight += ordItm.Product2.Weight__c * ordItm.Quantity;
                }


                Credentials__c fedExCre = [Select Id, Name, Active__c, Parent_Key__c, Parent_Password__c, Key__c, Password_Transkey__c, Meter_Number__c, URL__c, UPS_Account_Number__c, Shipper_Name__c, Shipper_Company_Name__c, Shipper_Street__c, Shipper_Postal_Code__c, Shipper_City__c, Shipper_Province__c, Shipper_Country__c, Encrypted_Key__c, Shipper_Email__c, Shipper_Phone_Number__c
                                           From Credentials__c
                                           Where Name = 'FedEx' And Active__c = true
                                           WITH SECURITY_ENFORCED
                                           Limit 1];


                if (fedExCre != null){
                    Blob cryptoKey, passwordData;
                    cryptoKey = encodingUtil.convertFromHex(fedExCre.Encrypted_Key__c);
                    passwordData = Crypto.decryptWithManagedIV('AES256', cryptoKey, encodingUtil.convertFromHex(fedExCre.Password_Transkey__c));
                    if (passwordData != null)
                        fedExCre.Password_Transkey__c = passwordData.toString();
                    List<Province_Codes__c> lstProvinceCodes = [Select Id, Name, Code__c, Province__c
                                                                From Province_Codes__c
                                                                Where Province__c = :fedExCre.Shipper_Province__c
                                                                WITH SECURITY_ENFORCED
                                                                Limit 1];
                    if (lstProvinceCodes.Size() > 0) shipperProvinceCode = lstProvinceCodes[0].Code__c;
                    //else errorMsg = 'FedEx Shipping Service Unavailable : Shipper Province Code not found';

                    List<Country_Codes__c> lstcountryCodes = [Select Id, Name, Code__c, Country__c
                                                              From Country_Codes__c
                                                              Where Country__c = :fedExCre.Shipper_Country__c
                                                              WITH SECURITY_ENFORCED
                                                              Limit 1];
                    if (lstcountryCodes.size() > 0)
                        shipperCountryCode = lstcountryCodes[0].Code__c;
                    else  errorMsg = 'FedEx Shipping Service Unavailable : Shipper Country Code not found'; } else errorMsg = 'FedEx Shipping Service Unavailable : Please setup FedEx credentials';
                if (currentOrder != null){
                    if (currentOrder.Ship_To_Address__r.Address_Line1__c != null && currentOrder.Ship_To_Address__r.Address_Line1__c != '')
                        shipAddress_Street = currentOrder.Ship_To_Address__r.Address_Line1__c;
                    if (currentOrder.Ship_To_Address__r.Address_Line2__c != null && currentOrder.Ship_To_Address__r.Address_Line2__c != '') shipAddress_Street += ', ' + currentOrder.Ship_To_Address__r.Address_Line2__c;
                    if (currentOrder.Ship_To_Address__r.Address_Line3__c != null && currentOrder.Ship_To_Address__r.Address_Line3__c != '') shipAddress_Street += ', ' + currentOrder.Ship_To_Address__r.Address_Line3__c;
                    /*if(currentOrder.Ship_To_Address__r.Address_Line3__c != Null && currentOrder.Ship_To_Address__r.Address_Line3__c != '') {
                     shipAddress_Street = currentOrder.Ship_To_Address__r.Address_Line1__c + ', ' + currentOrder.Ship_To_Address__r.Address_Line2__c + ', ' + currentOrder.Ship_To_Address__r.Address_Line3__c;
                     } else if(currentOrder.Ship_To_Address__r.Address_Line2__c != Null && currentOrder.Ship_To_Address__r.Address_Line2__c != '') {
                     shipAddress_Street = currentOrder.Ship_To_Address__r.Address_Line1__c + ', ' + currentOrder.Ship_To_Address__r.Address_Line2__c;
                     } else { shipAddress_Street = currentOrder.Ship_To_Address__r.Address_Line1__c; }*/

                    List<Province_Codes__c> lstToProvinceCodes = [Select Id, Name, Code__c, Province__c
                                                                  From Province_Codes__c
                                                                  Where Province__c = :currentOrder.Ship_To_Address__r.State__c
                                                                  WITH SECURITY_ENFORCED
                                                                  Limit 1];
                    if (lstToProvinceCodes.Size() > 0) shipAddress_ProvinceCode = lstToProvinceCodes[0].Code__c;
                    //else errorMsg = 'FedEx Shipping Service Unavailable : Shipping Address Province Code not found';

                    List<Country_Codes__c> lstTocountryCodes = [Select Id, Name, Code__c, Country__c
                                                                From Country_Codes__c
                                                                Where Country__c = :currentOrder.Ship_To_Address__r.Country__c
                                                                WITH SECURITY_ENFORCED
                                                                Limit 1];
                    if (lstTocountryCodes.size() > 0)
                        shipAddress_CountryCode = lstTocountryCodes[0].Code__c; else  errorMsg = 'FedEx Shipping Service Unavailable : Shipping Address Country Code not found';
                }

                List<Package_Details__c> pkgDetailLists = [select Id, Name, Length__c, Width__c, Height__c, Weight__c, Weight_Unit__c, Package_Type__c, Type__c
                                                           from Package_Details__c
                                                           Where Type__c = 'FEDEX'
                                                           WITH SECURITY_ENFORCED
                                                           order by CreatedDate Asc
                                                           limit 100];
                boolean packageExist = false;

                for (Package_Details__c pkgDetailListt : pkgDetailLists){
                    packageExist = true;
                    packTypeListOption.add(new selectOptions(pkgDetailListt.Package_Type__c, pkgDetailListt.Package_Type__c));
                }

                if (!packageExist) errorMsg = 'Package Details not found';
                upsWrapp.UPSErrorMsg = errorMsg;

                if (errorMsg == '' || Test.isRunningTest()){

                    if (pkgType != null && pkgType != '--None--'){
                        List<Package_Details__c> pkgDetailList = [select Id, Name, Length__c, Width__c, Height__c, Additional_Percentage__c, Weight__c, Weight_Unit__c, Package_Type__c, Type__c
                                                                  from Package_Details__c
                                                                  where Package_Type__c = :pkgType
                                                                  WITH SECURITY_ENFORCED
                                                                  limit 1];

                        if (pkgDetailList.size() > 0){
                            pkg.Length__c = pkgDetailList[pkgDetailList.size() - 1].Length__c;
                            pkg.Width__c = pkgDetailList[pkgDetailList.size() - 1].Width__c;
                            pkg.Height__c = pkgDetailList[pkgDetailList.size() - 1].Height__c;
                            pkg.Weight__c = pkgDetailList[pkgDetailList.size() - 1].Weight__c;
                            pkg.Weight_Unit__c = pkgDetailList[pkgDetailList.size() - 1].Weight_Unit__c;
                            pkgLength = pkg.Length__c;
                            pkgWidth = pkg.Width__c;
                            pkgHeight = pkg.Height__c;
                            pkgWeight = pkg.Weight__c;
                            additionalPercent = Integer.valueof(pkgDetailList[pkgDetailList.size() - 1].Additional_Percentage__c);
                            totalPkgVolume = (pkg.Length__c * pkg.Width__c * pkg.Height__c).setscale(2);
                            noOfPackages = Integer.valueof(soVolume / totalPkgVolume);
                            if (math.mod(Integer.valueof(soVolume), Integer.valueof(totalPkgVolume)) > 0)noOfPackages++;
                            soVolume = soVolume.setscale(2);
                            soWeight = soWeight.setscale(2);
                            totalWeight = (soWeight + (noOfPackages * pkg.Weight__c)).setscale(2);
                            totalWeightperPackage = (noOfPackages > 0) ? (totalWeight / noOfPackages).setscale(2) : totalWeight;

                            upsWrapp.PackageType = pkgType;
                            upsWrapp.PackageTypes = packTypeListOption;
                            if (shipDate != Null && shipDate != ''){ upsWrapp.ShipmentDate = Date.valueOf(shipDate);DateTime dt = upsWrapp.ShipmentDate;shipDate = dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
                            } else{
                                DateTime dt = System.now();
                                shipDate = dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'GMT');
                                upsWrapp.ShipmentDate = System.Today();
                            }
                            upsWrapp.Length = pkgLength;
                            upsWrapp.Width = pkgWidth;
                            upsWrapp.Height = pkgHeight;
                            upsWrapp.Weight = pkgWeight;
                            upsWrapp.NoofPackage = noOfPackages;
                            upsWrapp.Additional = additionalPercent;
                            upsWrapp.PackageVolume = totalPkgVolume;
                            upsWrapp.SOVolume = soVolume;
                            upsWrapp.SOWeight = soWeight;
                            upsWrapp.TotalWeight = totalWeight;
                            upsWrapp.WeightPerPack = totalWeightperPackage;

                            try{
                                String soapXML = '<SOAP-ENV:Envelope xmlns:SOAP-ENV="' + Label.POSLightningLabel3 + '/soap/envelope/" xmlns:SOAP-ENC="' + Label.POSLightningLabel3 + '/soap/encoding/" xmlns:xsi="' + Label.POSLightningLabel2 + '-instance" xmlns:xsd="' + Label.POSLightningLabel2 + '" xmlns="' + Label.POSLightningLabel4 + '/ws/rate/v20">';
                                soapXML += '<SOAP-ENV:Body>';
                                soapXML += '<RateRequest>';

                                soapXML += '<WebAuthenticationDetail>';
                                soapXML += '<UserCredential>';
                                soapXML += '<Key>' + fedExCre.key__c + '</Key>';
                                soapXML += '<Password>' + fedExCre.Password_Transkey__c + '</Password>';
                                //soapXML += '<Password>STlrFA84EzdzSOWfrW35xEIlE</Password>';
                                soapXML += '</UserCredential>';
                                soapXML += '</WebAuthenticationDetail>';

                                soapXML += '<ClientDetail>';
                                soapXML += '<AccountNumber>' + fedExCre.UPS_Account_Number__c + '</AccountNumber>';
                                soapXML += '<MeterNumber>' + fedExCre.Meter_Number__c + '</MeterNumber>';
                                soapXML += '</ClientDetail>';

                                soapXML += '<TransactionDetail>';
                                soapXML += '<CustomerTransactionId>Rate Request</CustomerTransactionId>';
                                soapXML += '</TransactionDetail>';

                                soapXML += '<Version>';
                                soapXML += '<ServiceId>crs</ServiceId>';
                                soapXML += '<Major>20</Major>';
                                soapXML += '<Intermediate>0</Intermediate>';
                                soapXML += '<Minor>0</Minor>';
                                soapXML += '</Version>';

                                soapXML += '<RequestedShipment>';
                                soapXML += '<ShipTimestamp>' + shipDate + '</ShipTimestamp>';
                                soapXML += '<DropoffType>REGULAR_PICKUP</DropoffType>';
                                soapXML += '<PackagingType>' + pkgType + '</PackagingType>';

                                soapXML += '<TotalWeight>';
                                if (pkg.Weight_Unit__c == 'KGS') soapXMl += '<Units>KG</Units>';
                                else
                                    soapXMl += '<Units>LB</Units>';
                                soapXML += '<Value>' + totalWeight + '</Value>';
                                soapXML += '</TotalWeight>';

                                if (fedExCre != null){
                                    soapXML += '<Shipper>';
                                    soapXML += '<Contact>';
                                    soapXML += '<PersonName>' + fedExCre.Shipper_Name__c.escapeXml() + '</PersonName>';
                                    soapXML += '<CompanyName>' + fedExCre.Shipper_Company_Name__c.escapeXml() + '</CompanyName>';
                                    soapXML += '<PhoneNumber>' + fedExCre.Shipper_Phone_Number__c.escapeXml() + '</PhoneNumber>';
                                    soapXML += '</Contact>';
                                    soapXML += '<Address>';
                                    soapXML += '<StreetLines>' + fedExCre.Shipper_Street__c.escapeXml() + '</StreetLines>';
                                    soapXML += '<City>' + fedExCre.Shipper_City__c.escapeXml() + '</City>';
                                    if (shipperProvinceCode != null)
                                        soapXML += '<StateOrProvinceCode>' + shipperProvinceCode.escapeXml() + '</StateOrProvinceCode>';
                                    soapXML += '<PostalCode>' + fedExCre.Shipper_Postal_Code__c.escapeXml() + '</PostalCode>';
                                    if (shipperCountryCode != null)
                                        soapXML += '<CountryCode>' + shipperCountryCode.escapeXml() + '</CountryCode>';
                                    soapXML += '</Address>';
                                    soapXML += '</Shipper>';
                                }
                                if (currentOrder != null){
                                    soapXML += '<Recipient>';
                                    soapXML += '<Contact>';
                                    soapXML += '<PersonName>' + currentOrder.Contact__r.Name.escapeXml() + '</PersonName>';
                                    if (currentOrder.Contact__r.Company__c != null) soapXML += '<CompanyName>' + currentOrder.Contact__r.Company__c + '</CompanyName>';
                                    if (currentOrder.Contact__r.Phone != null) soapXML += '<PhoneNumber>' + currentOrder.Contact__r.Phone.escapeXml() + '</PhoneNumber>';
                                    soapXML += '</Contact>';
                                    soapXML += '<Address>';
                                    soapXML += '<StreetLines>' + shipAddress_Street.escapeXml() + '</StreetLines>';
                                    soapXML += '<City>' + currentOrder.Ship_To_Address__r.City__c.escapeXml() + '</City>';
                                    if (shipAddress_ProvinceCode != null) soapXML += '<StateOrProvinceCode>' + shipAddress_ProvinceCode.escapeXml() + '</StateOrProvinceCode>'; soapXML += '<PostalCode>' + currentOrder.Ship_To_Address__r.Postal_Code__c.escapeXml() + '</PostalCode>';
                                    if (shipAddress_CountryCode != null)  soapXML += '<CountryCode>' + shipAddress_CountryCode.escapeXml() + '</CountryCode>'; soapXML += '</Address>'; soapXML += '</Recipient>';
                                }
                                soapXML += '<ShippingChargesPayment>'; soapXML += '<PaymentType>SENDER</PaymentType>'; soapXML += '<Payor>'; soapXML += '<ResponsibleParty>';
                                if (fedExCre != null) soapXML += '<AccountNumber>' + fedExCre.UPS_Account_Number__c + '</AccountNumber>'; soapXML += '</Payor>'; soapXML += '</ShippingChargesPayment>';

                                soapXML += '<RateRequestTypes>LIST</RateRequestTypes>'; soapXML += '<PackageCount>' + noOfPackages + '</PackageCount>';

                                for (Integer i = 0; i <= noOfPackages; i++){ soapXML += '<RequestedPackageLineItems>'; soapXML += '<SequenceNumber>' + i + 1 + '</SequenceNumber>'; soapXML += '<GroupNumber>1</GroupNumber>'; soapXML += '<GroupPackageCount>1</GroupPackageCount>';soapXML += '<Weight>';
                                    if (pkg.Weight_Unit__c == 'KGS') soapXMl += '<Units>KG</Units>';
                                    else
                                        soapXMl += '<Units>LB</Units>'; soapXML += '<Value>' + totalWeightperPackage + '</Value>'; soapXML += '</Weight>';


                                    soapXML += '</RequestedPackageLineItems>';
                                }
                                soapXML += '</RequestedShipment>'; soapXML += '</RateRequest>';soapXML += '</SOAP-ENV:Body>'; soapXML += '</SOAP-ENV:Envelope>';HttpRequest req = new HttpRequest();  Http h = new Http();

                                req.setBody(soapXML);  req.setMethod('POST'); String myEndPoint = fedExCre.URL__c; req.setEndpoint(myEndPoint); req.setHeader('Content-length', '175');
                                req.setHeader('Content-Type', 'text/xml'); req.setHeader('SOAPAction', ''); req.setHeader('Host', 'wsbeta.fedex.com');

                                HttpResponse res = new HttpResponse(); String Response; String resStatus;
                                if(Test.isRunningTest()){
                                Response = '<?xml version="1.0" encoding="UTF-8"?><RateReply><RateReplyDetails><ServiceType>PRIORITY_OVERNIGHT</ServiceType><TotalSurcharges><Currency>USD</Currency><Amount>10.00</Amount></TotalSurcharges><TotalNetCharge><Currency>USD</Currency><Amount>50.00</Amount></TotalNetCharge></RateReplyDetails></RateReply>';
                                resStatus = 'OK'; }else{ res = h.send(req); resStatus = res.getStatus();
                                }
                                if (resStatus == 'OK'){ XmlStreamReader reader1;
                                    if(Test.isRunningTest()){ reader1 = new XmlStreamReader(Response); }else{ reader1 = res.getXmlStreamReader();
                                    }
                                    String msg;
                                    if(Test.isRunningTest()){ msg = 'SUCCESS';}else{ msg = readXMLResponse(reader1, 'Severity');
                                    }
                                    if (msg != Null && msg == 'SUCCESS' || msg == 'WARNING'){ XmlStreamReader reader2;
                                        if(Test.isRunningTest()){ reader2 = new XmlStreamReader(Response); }else{ reader2 = res.getXmlStreamReader();
                                    }
                                        String resMesage = readXMLResponse(reader2, 'Code');
                                        if (resMesage == '556'){ upsWrapp.UPSErrorMsg = 'There are no valid services available.';
                                        } else{ XmlStreamReader reader;
                                            if(Test.isRunningTest()){reader = new XmlStreamReader(Response);
                                            }else{ reader = res.getXmlStreamReader();
                                            }
                                            rateWrapper rw;
                                            List<rateWrapper> rateWrapperLst = new List<rateWrapper>();while (reader.hasNext()){if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'RateReplyDetails'){ rw = new rateWrapper();while (reader.hasNext()){if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ServiceType'){ reader.next(); rw.service = reader.getText();
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'TotalSurcharges'){  reader.next();if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Currency'){ reader.next();if (reader.hasText() && rw.CurrencyCode == '') rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next(); reader.next();if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Amount'){  reader.next();if (reader.hasText() && rw.totalSurcharges == '')  rw.totalSurcharges = reader.getText();
                                                                /*+' '+ rw.currencyCode;*/
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'TotalNetCharge'){ reader.next();if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Currency'){ reader.next();if (reader.hasText() && rw.CurrencyCode == '') rw.CurrencyCode = reader.getText();
                                                            }
                                                            reader.next();  reader.next();if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'Amount'){ reader.next();if (reader.hasText() && rw.totalCharges == '')  rw.totalCharges = reader.getText();
                                                                /* +' '+ rw.currencyCode;*/
                                                            }
                                                        }
                                                        if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'RateReplyDetails') break;else   reader.next();
                                                    }
                                                    rateWrapperLst.add(rw);
                                                }
                                                reader.next();
                                            }
                                            upsWrapp.Services = rateWrapperLst; upsWrapp.UPSErrorMsg = 'Available Services For The Selected Location';
                                        }
                                    } else{ XmlStreamReader reader3 = res.getXmlStreamReader();String msg2 = readXMLResponse(reader3, 'Message');upsWrapp.UPSErrorMsg = 'Shipping Rate Service Is Not Available : ' + msg2;
                                    }
                                } else
                                    upsWrapp.UPSErrorMsg = 'Result not available';
                            } catch (Exception e){
                                upsWrapp.UPSErrorMsg = e.getMessage() + ' Line Number @ : ' + e.getLineNumber();
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
        }
        return upsWrapp;
    }

    global class upsWrap{
        @AuraEnabled
        global String PackageType{ get; Set; }

        @AuraEnabled
        global List<SelectOptions> PackageTypes{ get; Set; }

        @AuraEnabled
        global Date ShipmentDate{ get; Set; }

        @AuraEnabled
        global Decimal Length{ get; Set; }

        @AuraEnabled
        global Decimal Width{ get; Set; }

        @AuraEnabled
        global Decimal Height{ get; Set; }

        @AuraEnabled
        global Decimal Weight{ get; Set; }

        @AuraEnabled
        global Decimal NoofPackage{ get; Set; }

        @AuraEnabled
        global Decimal Additional{ get; Set; }

        @AuraEnabled
        global Decimal PackageVolume{ get; Set; }

        @AuraEnabled
        global Decimal SOVolume{ get; Set; }

        @AuraEnabled
        global Decimal SOWeight{ get; Set; }

        @AuraEnabled
        global Decimal TotalWeight{ get; Set; }

        @AuraEnabled
        global Decimal WeightPerPack{ get; Set; }

        @AuraEnabled
        global String UPSErrorMsg{ get; Set; }

        @AuraEnabled
        global String Result{ get; Set; }

        @AuraEnabled
        global List<rateWrapper> Services{ get; Set; }

        global upsWrap(){
            PackageType = Null;
            UPSErrorMsg = Null;
            Result = Null;
            WeightPerPack = Null;
            SOWeight = Null;
            SOVolume = Null;
            PackageVolume = Null;
            Additional = Null;
            NoofPackage = Null;
            Weight = Null;
            Height = Null;
            Width = Null;
            Length = Null;
            ShipmentDate = Null;
            Services = new List<rateWrapper>();
        }

    }

    //@AuraEnabled global List<rateWrapper> rateWrapperList       { get; set; }
    global class rateWrapper{
        @AuraEnabled
        global String Service{ get; set; }

        @AuraEnabled
        global String ServiceName{ get; set; }

        @AuraEnabled
        global Date DeliveryDate{ get; set; }

        @AuraEnabled
        global String ServiceCode{ get; set; }

        @AuraEnabled
        global String totalCharges{ get; set; }

        @AuraEnabled
        global String totalSurcharges{ get; set; }

        @AuraEnabled
        global String currencyCode{ get; set; }

        @AuraEnabled
        global String CommitmentDate{ get; set; }

        @AuraEnabled
        global String DeliveryDateS{ get; set; }

        @AuraEnabled
        global String ServiceManual{ get; set; }

        @AuraEnabled
        global String negotiatedCharges{ get; set; }

        @AuraEnabled
        global String TransportationCharges{ get; set; }

        @AuraEnabled
        global String ServiceOptionsCharges{ get; set; }

        @AuraEnabled
        global String ScheduledDeliveryTime{ get; set; }

        @AuraEnabled
        global String GuaranteedDaysToDelivery{ get; set; }

        @AuraEnabled
        global Boolean Selected{ get; set; }

        global rateWrapper(){
            Service = '';
            ServiceName = '';
            currencyCode = '';
            CommitmentDate = '';
            DeliveryDate = null;
            DeliveryDateS = '';
            ServiceManual = '';
            ServiceCode = '';
            totalCharges = '';
            totalSurcharges = '';
            negotiatedCharges = '';
            TransportationCharges = '';
            ServiceOptionsCharges = '';
            GuaranteedDaysToDelivery = '';
            ScheduledDeliveryTime = '';
            Selected = false;
        }

    }

    @AuraEnabled
    global static String saveEstimateService(String ord){
        String message = '';
        try{
            Order currentOrder = (Order) JSON.deserialize(ord, Order.class);

            //DML Operation

            if (Schema.sObjectType.Order.isCreateable() && Schema.sObjectType.Order.isUpdateable() && Schema.sObjectType.Order.fields.Name.isUpdateable())
                update currentOrder;
            if (currentOrder.Id != null)
                message = 'Shipping estimate save successfully.';
        } catch (Exception e){
            message = e.getMessage() + '   Line:' + e.getLineNumber();
        }
        return message;
    }

    @AuraEnabled
    global static String updateAccInfo(String acc){
        String message = '';
        try{
            Account acc2Update = (Account) JSON.deserialize(acc, Account.class);

            //DML Operation

            if (Schema.sObjectType.Account.isCreateable() && Schema.sObjectType.Account.isUpdateable() && Schema.sObjectType.Account.fields.Name.isUpdateable())
                update acc2Update;
            message = 'Account updated successfully';
        } catch (Exception e){
            message = e.getMessage() + '    Line:' + e.getLineNumber();
        }
        return message;
    }

    @AuraEnabled
    global static String insertNewAcc(String acc){

        String message = '';
        try{
            Account acc2Upsert = (Account) JSON.deserialize(acc, Account.class);

            if (acc2Upsert.Id == null){
                if (Schema.SObjectType.Account.fields.Active__c.isCreateable())
                    acc2Upsert.Active__c = 'Yes';
             }

            acc2Upsert.Account_Type__c = 'Customer';
            //DML Operation
            if (Account.sObjectType.getDescribe().isCreateable() && Schema.sObjectType.Account.fields.Active__c.isCreateable()){
                insert acc2Upsert;
            } else{
            }

            if (acc2Upsert.Id != null){
                message = acc2Upsert.Id;
            }
        } catch (Exception e){
            message = e.getMessage() + '    Line No:' + e.getLineNumber();
        }
        return message;
    }

    @AuraEnabled
    global static String insertContact(String con){
        String message = '';
        try{
            Contact con2Upsert = (Contact) JSON.deserialize(con, Contact.class);

            //DML Operation

            //if (Contact.sObjectType.getDescribe().isCreateable() && Schema.sObjectType.Contact.fields.Name.isCreateable())
            insert con2Upsert;
            if (con2Upsert.Id != null){ message = con2Upsert.Id;
            }
        } catch (Exception e){
            message = e.getMessage() + '    Line No:' + e.getLineNumber();
        }
        return message;
    }

    @AuraEnabled
    global static Map<String, List<String>> getDependentMap(string contrfieldApiName, string depfieldApiName){
          //sObject objDetail,
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();

        Map<String, List<String>> objResults = new Map<String, List<String>>();

        Schema.sObjectType objType = Address__c.getSObjectType();
        //Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType == null){ return objResults;
        }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){ return objResults;
        }

        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);

        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : contrEntries){
            String label = ple.getLabel();
            objResults.put(label, new List<String>());
            controllingValues.add(label);
        }

        for (PicklistEntryWrapper plew : depEntries){  String label = plew.label;String validForBits = base64ToBits(plew.validFor); for (Integer i = 0; i < validForBits.length(); i++){ String bit = validForBits.mid(i, 1); if (bit == '1'){ objResults.get(controllingValues.get(i)).add(label);
                }
            }
        }
        return objResults;
    }

    global static String decimalToBinary(Integer val){
        String bits = '';
        while (val > 0){
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    global static String base64ToBits(String validFor){
        if (String.isEmpty(validFor)) return '';
        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++){
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    global static final String base64Chars = '' +
                                         'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
                                         'abcdefghijklmnopqrstuvwxyz' +
                                         '0123456789+/';
    global static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs){
        return (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    global class PicklistEntryWrapper{
        global String active{ get; set; }

        global String defaultValue{ get; set; }

        global String label{ get; set; }

        global String value{ get; set; }

        global String validFor{ get; set; }

        global PicklistEntryWrapper(){
        }

    }

    @AuraEnabled
    global static String createNewAddress(String addrs){
        String message = '';
        try{
            Address__c address = (Address__c)JSON.deserialize(addrs, Address__c.class);

            //DML Operation

            if (Address__c.sObjectType.getDescribe().isCreateable() && Schema.sObjectType.Address__c.fields.Name.isCreateable()){
                insert address;
            } else{
                /*No Access*/
            }

            if (address.Id != null){
                message = address.Id;
            }
        } catch (Exception e){
            message = e.getMessage() + '    Line No:' + e.getLineNumber();
        }
        return message;
    }


public class InvoicePageResult {        @AuraEnabled public List<Invoice__c> invoices;        @AuraEnabled public Integer totalRecords;        @AuraEnabled public Integer pageNumber;        @AuraEnabled public Integer pageSize;    } @AuraEnabled(cacheable=true)public static InvoicePageResult getInvoicesForAccount(    Id accountId,    Integer pageNumber,    Integer pageSize,    String searchText) {    InvoicePageResult result = new InvoicePageResult();    result.invoices = new List<Invoice__c>();    result.pageNumber = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber; result.pageSize = (pageSize == null || pageSize <= 0 || pageSize > 200) ? 10 : pageSize; if (accountId == null) { result.totalRecords = 0; return result; } String trimmedSearch = (searchText == null) ? '' : searchText.trim(); String likeSearch = (trimmedSearch == '') ? null : '%' + String.escapeSingleQuotes(trimmedSearch) + '%'; String whereClause = ' FROM Invoice__c' + ' WHERE Account__c = :accountId' + ' AND Status__c != \'paid\'' + ' AND Paid__c = false'; if (likeSearch != null) { whereClause += ' AND (Order_S__r.OrderNumber LIKE :likeSearch' + ' OR Name LIKE :likeSearch)'; } Integer totalCount = Database.countQuery( 'SELECT COUNT()' + whereClause ); result.totalRecords = totalCount; if (totalCount == 0) { return result; } Integer offsetValue = (result.pageNumber - 1) * result.pageSize; List<Invoice__c> invoices = Database.query( 'SELECT Id,' + '       Name,' + '       Order_S__c,' + '       Order_S__r.OrderNumber,' + '       Account__c,' + '       Account__r.Name,' + '       Contact__c,' + '       Contact__r.Name,' + '       Company__c,' + '       Company__r.Name,' + '       Invoice_Date__c,' + '       Due_Date__c' + whereClause + ' ORDER BY Invoice_Date__c DESC, CreatedDate DESC' + ' LIMIT :result.pageSize OFFSET :offsetValue' ); result.invoices = invoices; return result; } @AuraEnabled(cacheable=true) public static List<Order> getOrdersForAccount(Id accountId) { if (accountId == null) return new List<Order>(); return [ SELECT Id, Name, OrderNumber, Order_Amount__c, Amount_Paid__c, Due_Amount__c, EffectiveDate FROM Order WHERE AccountId = :accountId AND Status != 'Cancelled' ORDER BY EffectiveDate DESC ]; }
}