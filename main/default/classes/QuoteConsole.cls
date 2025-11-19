global with sharing class QuoteConsole {
    /*
 * Changes made by : Parveez Pasha
 * Date   		   : 12th Jan 2023
 * Reason          : To manage the governor limit on More than 50,000 Records and Fetching Products from the Assinged pricebook instead of All products.
 * Code Change     : commented Code from line (354-381) and added the line item(382-412) to fetch products separately when filters are added in search.
*/


    
    @AuraEnabled(cacheable=true)
    global static ProWrapper getStatus(){
        ProWrapper initial=new ProWrapper();
        try{     
			     
            	
            initial.quoteStatus=QuoteConsole.getPicklists('Quotes__c','Status__c',false);
            initial.prodFam=QuoteConsole.getPicklists('Product2','Family',true);
            initial.isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            initial.allCurrencies.add(new SelectOptions(initial.userCurrency, initial.userCurrency));
            if(initial.isMultiCurrency) initial.allCurrencies=QuoteConsole.getPicklists('PricebookEntry','CurrencyIsoCode',false);
            //Currency Fetching
            
            Employees__c emp;
            for(Employees__c employee:[Select Id, Name, First_Name__c, Channel__c, Last_Name__c, Employee_User__c, Email__c, Employee_Profiling__c, Company__c
                                             From Employees__c
                                             Where Employee_User__c = : UserInfo.getUserId() AND Active__c=true 
                                              order by CreatedDate Asc Limit 1])  
                emp=employee;
            if(emp==null) initial.errorMsg='Employee not found for current user.';
            else initial.emp=emp;
            //Id RT = Schema.SObjectType.Profiling__c.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            Id RT = Schema.SObjectType.Profiling__c.getRecordTypeInfosByDeveloperName().get('Order_Profile').getRecordTypeId();
            initial.recType=RT;
            Profiling__c profile;
            for(Profiling__c pr:[Select Id, Name,Channel__c from Profiling__c where RecordTypeId =:RT AND Active__c=true    Limit 1 ])  
                profile=pr;
            if(profile == null) initial.errorMsg='Customer Profile not found.';
            else initial.profile=profile;
        }catch(Exception e){initial.errorMsg=e.getMessage()+'Line Number :'+e.getLineNumber();}        
        return initial;
    }
    
    @AuraEnabled
    global static ProWrapper cusmChange(String accId){
        System.debug('accid cusschange--'+accId);
        ProWrapper pw=new ProWrapper();
        try{
            
            Account acc=[Select Id,Name,Company__c,Order_Profile__c,Order_Profile__r.Channel__c,Order_Profile__r.Price_Book__c from Account where Id =:accId    Limit 1];
            System.debug('Account details-'+acc);
            pw.acc=acc;
            List<Contact> con = [Select Id,Name,AccountId From Contact Where AccountId =: accId AND Primary__c = true    Limit 1];
            System.debug('con details-'+con);
            if(con.size() > 0) pw.conId=con[0].Id;
            else {
                List<Contact> con1 = [Select Id,Name,AccountId From Contact Where AccountId =: accId AND Primary__c = false   limit 50];
                System.debug('con1 details'+con1);
                if(con1.size() == 1)pw.conId=con1[0].Id;
                else pw.conId=con1[0].Id;
            }


            List<Address__c> Baddress = [Select Id,Name,Customer__c
                                               from Address__c 
                                               where Customer__c =:accId AND Is_Billing_Address__c = true    Limit 1];
            List<Address__c> Saddress = [Select Id,Name,Customer__c
                                               from Address__c 
                                               where Customer__c =:accId AND Is_Shipping_Address__c = true    Limit 1];
            if(Baddress.size()>0) pw.billAdd=Baddress[0].Id;
            if(Saddress.size()>0) pw.shipAdd=Saddress[0].Id;
        }catch(Exception e){ pw.errorMsg='Please check Primary Contact, Shipping Address Or Billing Address of Customer';}        
        return pw;
    }
    
    global static List<SelectOptions> getPicklists(String Object_Name1,String Field_name, Boolean isAddNone){
        
        Functionality_Control__c FC = new Functionality_Control__c();
        FC = Functionality_Control__c.getOrgDefaults();
        if(Object_Name1.containsIgnoreCase('__c')){
            if(FC.Consider_Namespace__c){
                Object_Name1 = (Object_Name1.containsIgnoreCase('Axolt__'))? Object_Name1 : 'Axolt__'+Object_Name1;Field_name = (Field_name.containsIgnoreCase('Axolt__'))? Field_name : 'Axolt__'+Field_name;
            }      
        }
        
        List<SelectOptions> allPicklist=new List<SelectOptions>();        
        //String Field_name='CurrencyIsoCode';
        Schema.SObjectType targetObject = Schema.getGlobalDescribe().get(Object_Name1);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetObject.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        if(isAddNone) allPicklist.add(new SelectOptions('--None--',''));
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            allPicklist.add(new SelectOptions(a.getLabel(),a.getValue()));
        }
        return allPicklist;
    }
    
    
    global class ProWrapper {
        @AuraEnabled global String errorMsg 					{ get; set; }
        @AuraEnabled global List<SelectOptions> prodFam 		{ get; Set; } 
        @AuraEnabled global List<SelectOptions> prodCat 		{ get; Set; }
        @AuraEnabled global List<SelectOptions> quoteStatus		{ get; Set; }
        @AuraEnabled global Employees__c emp		 		{ get; Set; }
        @AuraEnabled global Id recType					{ get; Set; }
        @AuraEnabled global Profiling__c profile			{ get; Set; }
        @AuraEnabled global Date todayDate						{ get; Set; }
        @AuraEnabled global Account acc							{ get; Set; }
        //@AuraEnabled global String accOrderProfile				{ get; Set; }
        //@AuraEnabled global String accOrderProfileChannel		{ get; Set; }
        @AuraEnabled global String conId						{ get; Set; }
        @AuraEnabled global String billAdd						{ get; Set; }
        @AuraEnabled global String shipAdd						{ get; Set; }
        //@AuraEnabled global String organisation					{ get; Set; }
        @AuraEnabled global Boolean isMultiCurrency 			{ get;set;}
        @AuraEnabled global List<SelectOptions> allCurrencies   { get; set; }
        @AuraEnabled global String userCurrency                 { get; set; }
        
        global ProWrapper() {
            errorMsg='';
            prodFam = new List<SelectOptions>();
            prodCat = new List<SelectOptions>();
            quoteStatus=new List<SelectOptions>();
            emp=new Employees__c();
            profile=new Profiling__c();
            todayDate=System.today();
            acc=new Account();
            //accOrderProfile='';
            conId='';
            billAdd='';
            shipAdd='';
            //organisation='';
            isMultiCurrency=false;
            allCurrencies=new List<SelectOptions>();
            userCurrency=UserInfo.getDefaultCurrency();
        }
    }
    global class SelectOptions {
        @AuraEnabled global String label     { get; set; }
        @AuraEnabled global String value     { get; set; }        
        global SelectOptions(String lab, string val) {
            label = lab;
            value = val;
        }
    }
    
    @AuraEnabled
    global static List<ProductWrapper> changeProfilehandler(String currProfile, String billToAddId, String shipToAddId,List<String> ProdId,String currencycode){
        if(ProdId.size() > 0){
            Profiling__c profile = [Select Id,Name,Channel__c,Price_Book__c,Tax_Sourcing_Rules__c from Profiling__c where Id =:currProfile    Limit 1];
            string priceBookId = profile.Price_Book__c;
            if(profile.Tax_Sourcing_Rules__c == null) profile.Tax_Sourcing_Rules__c='Destination';
            Set<Id> siteIds=new Set<Id>();
            
            List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c from Distribution_Channel__c
                                                                  where Channel__c=:profile.Channel__c and Active__c=true   limit 50];                
            if(DistributionChannels.size() > 0) {
                for(Distribution_Channel__c DC: DistributionChannels) {
                    siteIds.add(DC.Site__c);
                }
            }
            List<PricebookEntry> pbe=new List<PricebookEntry>();
            Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            
            String query='Select Pricebook2Id,UnitPrice,Product2.Id,Product2.Name,Product2.ProductCode,Product2.Description,Product2.BOM__c,Product2.Configure__c,Product2.Allow_Back_orders__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure,Product2.Is_Kit__c from PricebookEntry where Pricebook2Id =:priceBookId AND Product2Id IN (Select Id From Product2 where IsActive=TRUE AND Id In: ProdId ) AND IsActive=TRUE ';
            
            if(isMultiCurrency)  { query= query+ ' AND CurrencyIsoCode=:currencycode limit 200';  pbe = Database.query(query); }
            else  {
                //query= query+ ' Limit 12'; 
                pbe = Database.query(query);
            }
            Set<Id> productIds=new Set<Id>();            
            for(PricebookEntry pb1 : pbe) productIds.add(pb1.Product2.Id);
            List <Inventory_Stock__c> WarehouseItemInventoryStocks = new List <Inventory_Stock__c>();
            if(productIds.size() > 0) {
                WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                Number_of_Item_In_Stock__c, BOM__c From Inventory_Stock__c
                                                Where product__c In: productIds And
                                                Active__c = true And
                                                Warehouse__c In: siteIds And                                                 
                                                Number_of_Item_In_Stock__c > 0   limit 50];
            }	        
            Map<String, Decimal> stockView = new Map<String, Decimal>();
            for(Id prId:productIds){
                Decimal stock=0;
                for(Inventory_Stock__c inven : WarehouseItemInventoryStocks){
                    if(prId == inven.product__c){
                        stock += inven.Number_of_Item_In_Stock__c;
                    }
                }
                stockView.put(prId,stock);                
            }
            //*************Stock Calculation ends**************
            
            //=========Discount Plan==============
            Integer currentQuantity=1;
            List <Tier_Discount_Allocation__c> TDAS= new List <Tier_Discount_Allocation__c>();
            TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, 
                    product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                    Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                    Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                    From Tier_Discount_Allocation__c
                    Where order_Profile__c = : profile.Id And
                    Price_Book__c =:profile.Price_Book__c AND
                    product__c In: productIds And
                    Tier__r.Floor_Unit__c <= : currentQuantity And
                    Tier__r.Ceiling_Unit__c >= : currentQuantity And
                    Tier__r.Active__c = true And
                    Discount_Plan__r.Active__c = true And
                    Active__c = true   limit 50];
            
            List <Id> discountPlanIds = new List <Id>();
            for(Tier_Discount_Allocation__c TDA: TDAS) { if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
                                                       }
            List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
            discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                         Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                         From Discount_Plan__c
                         Where Id In: discountPlanIds And
                         Active__c = True   limit 50];
            
            Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
            for(Discount_Plan__c dis: discounts)  discountMap.put(dis.id, dis);
            
            
            Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
            Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
            for(PricebookEntry pbPro: pbe) {           
                List <Discount_Plan__c> myDiscountPlans = new List <Discount_Plan__c>();
                List <Tier_Discount_Allocation__c> myTierDiscAlc = new List <Tier_Discount_Allocation__c>();
                for(Tier_Discount_Allocation__c TDA: TDAS) {
                    if(pbPro.Product2.Id == TDA.product__c && TDA.Discount_Plan__c != Null) { myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));myTierDiscAlc.add(TDA);
                    }
                }
                discountPlans.put(pbPro.Product2.Id, myDiscountPlans);  
                tierDiscAllocation.put(pbPro.Product2.Id, myTierDiscAlc);
            }
            Date todayDate = system.today();
            List<Tax__c> profileTax = new List<Tax__c>();
            profileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c = Null AND Active__c=true   order by Province__c DESC];
            
            List<Tax__c> productprofileTax = new List<Tax__c>();
            productprofileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c != Null AND Product__c In : productIds AND Active__c=true   order by Province__c DESC limit 50];
            
            Address__c quoteBillToAdd;
            Address__c quoteShipToAdd;
            if(billToAddId != '' && billToAddId != null) quoteBillToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:billToAddId AND Active__c=true    Limit 1];
            if(shipToAddId != '' && shipToAddId != null) quoteShipToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:shipToAddId AND Active__c=true    Limit 1];
            
            String TaxPostalCode = '';
            String TaxCity = '';
            String TaxProvince = '';
            String TaxCountry = '';
            if(quoteBillToAdd != Null){
                if(profile.Tax_Sourcing_Rules__c =='Origin'){
                    if(quoteBillToAdd.Zip_Postal_Code__c != Null && quoteBillToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteBillToAdd.Zip_Postal_Code__c;
                    if(quoteBillToAdd.City__c != Null && quoteBillToAdd.City__c != '') TaxCity = quoteBillToAdd.City__c;
                    if(quoteBillToAdd.State__c != Null && quoteBillToAdd.State__c != '') TaxProvince = quoteBillToAdd.State__c;
                    if(quoteBillToAdd.Country__c != Null && quoteBillToAdd.Country__c != '') TaxCountry = quoteBillToAdd.Country__c;
                }
            }        
            
            if(quoteShipToAdd != Null){
                if(profile.Tax_Sourcing_Rules__c =='Destination'){                if(quoteShipToAdd.Zip_Postal_Code__c != Null && quoteShipToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteShipToAdd.Zip_Postal_Code__c;                if(quoteShipToAdd.City__c != Null && quoteShipToAdd.City__c != '') TaxCity = quoteShipToAdd.City__c;                if(quoteShipToAdd.State__c != Null && quoteShipToAdd.State__c != '') TaxProvince = quoteShipToAdd.State__c;                if(quoteShipToAdd.Country__c != Null && quoteShipToAdd.Country__c != '') TaxCountry = quoteShipToAdd.Country__c;
                                                                       }
            }
            List<ProductWrapper> prodWrap=new List<ProductWrapper>();
            for(PricebookEntry pb : pbe){         
                
                List<SelectOptions> options = new List<SelectOptions>();
                options.add(new SelectOptions('--None--',''));
                if(discountPlans.get(pb.Product2.Id) != null) {
                    for(Discount_Plan__c dis: discountPlans.get(pb.Product2.Id))  options.add(new SelectOptions(dis.Name,dis.Id));
                    
                }            
                
                //=============taxes start==================
                Tax__c tax;//=new Tax__c();            
                Boolean taxFound = false;
                Decimal vatAmount=0;
                Decimal anotherTax=0;
                String taxId='';
                
                //Product Taxes
                if(productprofileTax.size() > 0){
                    for(Tax__c ProductTax : productprofileTax){                    
                        if(pb.Product2.Id == ProductTax.Product__c){
                            
                            if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == TaxPostalCode && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break;                                                         
                            }
                            if(!taxFound){
                                if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){  tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                            }
                            if(!taxFound){
                                if((TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == TaxCountry)){ tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                            }
                            if(!taxFound){
                                if(ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == Null){   tax=ProductTax; taxId=ProductTax.Id;  taxFound = true;  break;  }
                            }
                        }
                    }
                }
                //Profile Taxes
                if(!taxFound){										//When ProductTax will not available                
                    if(profileTax.size() > 0){
                        for(Tax__c profileTax1 : profileTax){
                            
                            if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == TaxPostalCode && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id; taxFound = true; break;  }
                            if(!taxFound){if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id;  taxFound = true; break; }
                            }
                            if(!taxFound){if((TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == TaxCountry)){  tax=profileTax1; taxId=profileTax1.Id; taxFound = true;  break; }
                            }
                            if(!taxFound){ if(profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == Null){  tax=profileTax1;  taxId=profileTax1.Id; taxFound = true; break; }
                            }
                        }
                    }                
                }
                //=============taxes end==================
                
                ProductWrapper pw=new ProductWrapper();
                pw.pbe=pb;
                //pw.PSSpbe=PSSpbeMap.get(pb.Product2.Id);
                if(pb.Product2.BOM__c != null) pw.version=pb.Product2.BOM__c;
                pw.CurrentDiscounts=options;
                pw.stock= stockView.get(pb.Product2.Id) != null ? stockView.get(pb.Product2.Id) : 0.00;
                pw.disPlans= discountPlans.get(pb.Product2.Id) != null ? discountPlans.get(pb.Product2.Id) : new List<Discount_Plan__c>();
                pw.tierDists= tierDiscAllocation.get(pb.Product2.Id)!= null ? tierDiscAllocation.get(pb.Product2.Id) : new List<Tier_Discount_Allocation__c>();
                //pw.PSSList=PSSMap.get(pb.Product2.Id);
                pw.tax= tax != null ? tax : new Tax__c();
                pw.vatAmount=vatAmount;
                pw.otherTax=anotherTax;
                pw.totalTaxAmount=vatAmount+anotherTax;
                prodWrap.add(pw);            
            }
            return prodwrap;
        }
        return null;   
    }
    
    @AuraEnabled(cacheable = true)
    global static List < ProductWrapper > fetchProducts(String currProfile, String billToAddId, String shipToAddId, String searchItem, String prodFamily, boolean isSubscriptionProd, String currencycode){
        Profiling__c profile = [Select Id, Name, Channel__c, Price_Book__c,Dynamic_Discount__c, Tax_Sourcing_Rules__c from Profiling__c where Id =: currProfile    Limit 1];
        if (profile.Tax_Sourcing_Rules__c == null) profile.Tax_Sourcing_Rules__c = 'Destination';
        Set < Id > siteIds=new Set < Id > ();
        List<Discount_Plan__c>  dynamicDiscount = new  List<Discount_Plan__c>();
        
        if(profile.Dynamic_Discount__c != null) {
            
            dynamicDiscount = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                               Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                               From Discount_Plan__c
                               Where Id =:profile.Dynamic_Discount__c  And Active__c = True And Start_Date__c <= TODAY And End_Date__c >= TODAY  limit 1];
        }
        
        List < Distribution_Channel__c > DistributionChannels =[Select Id, Name, Channel__c, Site__c, Priority__c from Distribution_Channel__c
                                                                where Channel__c =: profile.Channel__c and Active__c = true   limit 50];
        if (DistributionChannels.size() > 0) {
            for (Distribution_Channel__c DC: DistributionChannels) {
                siteIds.add(DC.Site__c);
            }
        }
        
        String searchProductBy = '%' + searchItem + '%';
        
        
        List < PricebookEntry > searchProdList=new List < PricebookEntry > ();
        
        List < PricebookEntry > pbe=new List < PricebookEntry > ();
        
        if (searchItem != '' || prodFamily != '') {
            
            if (!String.isEmpty(searchItem) && !String.isEmpty(prodFamily))
                searchProdList = [Select Id, UnitPrice, Product2.Id, Product2.Name,Product2.Is_Subscribe__c, Product2.Apply_Dynamic_Discount__c,Product2.ProductCode,Product2.Track_Inventory__c from PricebookEntry where(Product2.Name like: searchProductBy OR Product2.ProductCode like: searchProductBy OR Product2.StockKeepingUnit like: searchProductBy) AND Product2.Family =: prodFamily  AND Product2.IsActive = true    Limit 5000];
            else if (!String.isEmpty(prodFamily))
                searchProdList = [Select Id, UnitPrice, Product2.Id, Product2.Name,Product2.Is_Subscribe__c, Product2.Apply_Dynamic_Discount__c,Product2.ProductCode,Product2.Track_Inventory__c from PricebookEntry where(Product2.Name like: searchProductBy OR Product2.ProductCode like: searchProductBy OR Product2.StockKeepingUnit like: searchProductBy) AND Product2.Family =: prodFamily  AND Product2.IsActive = true    Limit 5000];
            else
                searchProdList = [Select Id, UnitPrice, Product2.Id, Product2.Name,Product2.Is_Subscribe__c, Product2.Apply_Dynamic_Discount__c,Product2.ProductCode,Product2.Track_Inventory__c from PricebookEntry where(Product2.Name like: searchProductBy OR Product2.ProductCode like: searchProductBy OR Product2.StockKeepingUnit like: searchProductBy) AND Product2.IsActive = true    Limit 5000];
            
            Set < Id > searchProdIds=new Set < Id > ();
            for (PricebookEntry pr:searchProdList) searchProdIds.add(pr.Product2.Id);
            
            Id profileId = profile.Price_Book__c;
            if (searchProdIds.size() > 0) {
                Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
                
                String query = 'Select Id,UnitPrice,Product2.Id,Product2.Name,Product2.Apply_Dynamic_Discount__c,Product2.ProductCode,Product2.Description,Product2.Goods_Description__c,Product2.BOM__c,Product2.Configure__c,Product2.Allow_Back_orders__c,Product2.Track_Inventory__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure,Product2.Is_Subscribe__c,Product2.Subscription_Plan__c,Product2.Subscription_Plan__r.Number_of_Days__c,Product2.Family from PricebookEntry where Pricebook2Id =:profileId AND Product2Id In:searchProdIds AND IsActive=TRUE';
                
                if (isMultiCurrency) {
                    query +=  ' AND CurrencyIsoCode =:currencycode limit 1000'; 
                    pbe = Database.query(query); 
                }else {
                    query += ' limit 1000';
                    pbe = Database.query(query);
                }
            }
            
        }
        if (searchItem == '' && prodFamily == '') {
            System.debug('2');
            Id profileId = profile.Price_Book__c;
            Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            
            String query = 'Select Id,UnitPrice,Product2.Id,Product2.Apply_Dynamic_Discount__c,Product2.Name,Product2.ProductCode,Product2.Description,Product2.Goods_Description__c,Product2.BOM__c,Product2.Configure__c,Product2.Allow_Back_orders__c,Product2.Track_Inventory__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure,Product2.Is_Subscribe__c,Product2.Subscription_Plan__c,Product2.Subscription_Plan__r.Number_of_Days__c,Product2.Family from PricebookEntry where Pricebook2Id =:profileId AND IsActive=TRUE ';
            
            if (isMultiCurrency) { query = query + ' AND CurrencyIsoCode=:currencycode ORDER BY CreatedDate DESC Limit 500'; pbe = Database.query(query); }
            else {
                query = query + ' ORDER BY CreatedDate DESC Limit 1000'; pbe = Database.query(query);
            }
            
        }
        
        Set < Id > productIds=new Set < Id > ();
        for (PricebookEntry pb1 : pbe) productIds.add(pb1.Product2.Id);
        
        List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();
        if (productIds.size() > 0) {
            WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                            Number_of_Item_In_Stock__c, BOM__c From Inventory_Stock__c
                                            Where product__c In: productIds And
                                            Active__c = true And
                                            Warehouse__c In: siteIds And
                                            Product__r.Family != 'Software' And
                                            Number_of_Item_In_Stock__c > 0   limit 1000];
        }
        
        Map < String, Decimal > stockView = new Map < String, Decimal > ();
        for (Id prId:productIds) {
            Decimal stock = 0;
            for (Inventory_Stock__c inven : WarehouseItemInventoryStocks) {
                if (prId == inven.product__c) {
                    stock += inven.Number_of_Item_In_Stock__c;
                }
            }
            stockView.put(prId, stock);
        }
        List < License__c > SoftwareProdLicenses = new List < License__c > ();
        if (productIds.size() > 0) {
            SoftwareProdLicenses = [Select Id, Name, Active__c, product__c, Number_Of_Licenses__c From License__c
                                    Where product__c In: productIds And
                                    Active__c = true And
                                    Product__r.Family = 'Software' And
                                    Number_Of_Licenses__c > 0   limit 50];
        }
        
        Map < String, Decimal > LicenseView = new Map < String, Decimal > ();
        for (Id prId:productIds) {
            Decimal Licensecount = 0;
            for (License__c License : SoftwareProdLicenses) {
                if (prId == License.product__c) { Licensecount += License.Number_Of_Licenses__c;
                }
            }
            LicenseView.put(prId, Licensecount);
        }
        //*************License Calculation ends**************
        
        
        //=========Discount Plan==============
        Integer currentQuantity = 1;
        List < Tier_Discount_Allocation__c > TDAS= new List < Tier_Discount_Allocation__c > ();
        TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,
                product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                From Tier_Discount_Allocation__c
                Where order_Profile__c = : profile.Id And
                Price_Book__c =: profile.Price_Book__c AND
                product__c In: productIds And
                Tier__r.Floor_Unit__c <= : currentQuantity And
                Tier__r.Ceiling_Unit__c >= : currentQuantity And
                Tier__r.Active__c = true And
                Discount_Plan__r.Active__c = true And
                Active__c = true   limit 50];
        
        List < Id > discountPlanIds = new List < Id > ();
        for (Tier_Discount_Allocation__c TDA: TDAS) {
            if (TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
        }
        List < Discount_Plan__c > discounts = new List < Discount_Plan__c > ();
        discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                     Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                     From Discount_Plan__c
                     Where Id In: discountPlanIds And
                     Active__c = True   limit 50];
        
        Map < Id, Discount_Plan__c > discountMap = new Map < Id, Discount_Plan__c > ();
        for (Discount_Plan__c dis: discounts) discountMap.put(dis.id, dis);
        
        
        Map < Id, List < Discount_Plan__c >> discountPlans = new Map < Id, List < Discount_Plan__c >> ();
        Map < Id, List < Tier_Discount_Allocation__c >> tierDiscAllocation = new Map < Id, List < Tier_Discount_Allocation__c >> ();
        for (PricebookEntry pbPro: pbe) {
            List < Discount_Plan__c > myDiscountPlans = new List < Discount_Plan__c > ();
            List < Tier_Discount_Allocation__c > myTierDiscAlc = new List < Tier_Discount_Allocation__c > ();
            for (Tier_Discount_Allocation__c TDA: TDAS) {
                if (pbPro.Product2.Id == TDA.product__c && TDA.Discount_Plan__c != Null) { myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));myTierDiscAlc.add(TDA);
                }
            }
            if(dynamicDiscount.Size()>0 && pbPro.Product2.Apply_Dynamic_Discount__c)myDiscountPlans.add(dynamicDiscount[0]);
            discountPlans.put(pbPro.Product2.Id, myDiscountPlans);
            tierDiscAllocation.put(pbPro.Product2.Id, myTierDiscAlc);
                        
        }
        
        //==============/Discount Plan===========================
        
        //=============Taxex Calculation start=====================
        Date todayDate = system.today();
        List < Tax__c > profileTax = new List < Tax__c > ();
        profileTax = [Select Id, Name, Active__c, Apply_Tax_On__c, City__c, Country__c, Effective_Date__c, Expiry_Date__c, Other_Tax_Rate__c, Other_Tax_Type__c, Postal_Code__c, Product__c, Province__c, Tax_Rate__c, Type__c from Tax__c where Account_Profile__c =: profile.Id AND Effective_Date__c <= : todayDate AND Expiry_Date__c >= : todayDate AND Type__c = : 'Sales Tax' AND Tax_Rate__c != Null AND Product__c = Null AND Active__c = true   order by Province__c DESC limit 50];
        
        List < Tax__c > productprofileTax = new List < Tax__c > ();
        productprofileTax = [Select Id, Name, Active__c, Apply_Tax_On__c, City__c, Country__c, Effective_Date__c, Expiry_Date__c, Other_Tax_Rate__c, Other_Tax_Type__c, Postal_Code__c, Product__c, Province__c, Tax_Rate__c, Type__c from Tax__c where Account_Profile__c =: profile.Id AND Effective_Date__c <= : todayDate AND Expiry_Date__c >= : todayDate AND Type__c = : 'Sales Tax' AND Tax_Rate__c != Null AND Product__c != Null AND Product__c In : productIds AND Active__c = true   order by Province__c DESC limit 50];
        
        Address__c quoteBillToAdd;
        Address__c quoteShipToAdd;
        if (billToAddId != '' && billToAddId != null) quoteBillToAdd = [Select Id, Name, Active__c, Address__c, City__c, Country__c, State__c, Zip_Postal_Code__c from Address__c where Id =: billToAddId AND Active__c = true    Limit 1];
        if (shipToAddId != '' && shipToAddId != null) quoteShipToAdd = [Select Id, Name, Active__c, Address__c, City__c, Country__c, State__c, Zip_Postal_Code__c from Address__c where Id =: shipToAddId AND Active__c = true    Limit 1];
        
        String TaxPostalCode = '';
        String TaxCity = '';
        String TaxProvince = '';
        String TaxCountry = '';
        if (quoteBillToAdd != Null) {
            if (profile.Tax_Sourcing_Rules__c == 'Origin') {
                if (quoteBillToAdd.Zip_Postal_Code__c != Null && quoteBillToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteBillToAdd.Zip_Postal_Code__c;
                if (quoteBillToAdd.City__c != Null && quoteBillToAdd.City__c != '') TaxCity = quoteBillToAdd.City__c;
                if (quoteBillToAdd.State__c != Null && quoteBillToAdd.State__c != '') TaxProvince = quoteBillToAdd.State__c;
                if (quoteBillToAdd.Country__c != Null && quoteBillToAdd.Country__c != '') TaxCountry = quoteBillToAdd.Country__c;
            }
        }
        
        if (quoteShipToAdd != Null) {
            if (profile.Tax_Sourcing_Rules__c == 'Destination') { if (quoteShipToAdd.Zip_Postal_Code__c != Null && quoteShipToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteShipToAdd.Zip_Postal_Code__c; if (quoteShipToAdd.City__c != Null && quoteShipToAdd.City__c != '') TaxCity = quoteShipToAdd.City__c; if (quoteShipToAdd.State__c != Null && quoteShipToAdd.State__c != '') TaxProvince = quoteShipToAdd.State__c; if (quoteShipToAdd.Country__c != Null && quoteShipToAdd.Country__c != '') TaxCountry = quoteShipToAdd.Country__c;
            }
        }
        
        //=============Taxex Calculation end=====================
        
        List < ProductWrapper > prodWrap=new List < ProductWrapper > ();
        for (PricebookEntry pb : pbe) {
            
            List < SelectOptions > options = new List < SelectOptions > ();
            options.add(new SelectOptions('--None--', ''));
            if (discountPlans.get(pb.Product2.Id) != null) {
                for (Discount_Plan__c dis: discountPlans.get(pb.Product2.Id)) options.add(new SelectOptions(dis.Name, dis.Id));
                
            }
            
            //=============taxes start==================
            Tax__c tax;//=new Tax__c();            
            Boolean taxFound = false;
            Decimal vatAmount = 0;
            Decimal anotherTax = 0;
            String taxId = '';
            
            //Product Taxes
            if (productprofileTax.size() > 0) {
                for (Tax__c ProductTax : productprofileTax) {
                    if (pb.Product2.Id == ProductTax.Product__c) {
                        
                        if ((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == TaxPostalCode && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)) { tax = ProductTax; taxId = ProductTax.Id; taxFound = true; break;
                        }
                        if (!taxFound) {
                            if ((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)) { tax = ProductTax; taxId = ProductTax.Id; taxFound = true; break; }
                        }
                        if (!taxFound) {
                            if ((TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == TaxCountry)) { tax = ProductTax; taxId = ProductTax.Id; taxFound = true; break; }
                        }
                        if (!taxFound) {
                            if (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == Null) { tax = ProductTax; taxId = ProductTax.Id; taxFound = true; break; }
                        }
                    }
                }
            }
            //Profile Taxes
            if (!taxFound) {										//When ProductTax will not available                
                if (profileTax.size() > 0) {
                    for (Tax__c profileTax1 : profileTax) {
                        
                        if ((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == TaxPostalCode && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)) { tax = profileTax1; taxId = profileTax1.Id; taxFound = true; break; }
                        if (!taxFound) { if ((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)) { tax = profileTax1; taxId = profileTax1.Id; taxFound = true; break; }
                        }
                        if (!taxFound) { if ((TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == TaxCountry)) { tax = profileTax1; taxId = profileTax1.Id; taxFound = true; break; }
                        }
                        if (!taxFound) { if (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == Null) { tax = profileTax1; taxId = profileTax1.Id; taxFound = true; break; }
                        }
                    }
                }
            }
            //=============taxes end==================
            
            ProductWrapper pw = new ProductWrapper();
            
            /* Visibility Control */
            Functionality_Control__c FC = new Functionality_Control__c();
            FC = Functionality_Control__c.getValues(userInfo.getuserid());
            if (FC == null) { FC = Functionality_Control__c.getValues(userInfo.getProfileId()); if (FC == null) FC = Functionality_Control__c.getInstance(); }
            if (FC != null) { pw.isgoodsDescription = FC.Show_GoodsDescription__c; pw.ShowUOMData = FC.Show_UOM__c; pw.ShowStockData = FC.Show_Stock__c; pw.ShowOption = FC.Show_Optional_Selected_Items__c; }
            pw.pbe = pb;
            //pw.PSSpbe=PSSpbeMap.get(pb.Product2.Id);
            if (pb.Product2.BOM__c != null) pw.version = pb.Product2.BOM__c;
            pw.CurrentDiscounts = options;
            pw.stock = stockView.get(pb.Product2.Id) != null ? stockView.get(pb.Product2.Id) : 0.00;
            pw.License = LicenseView.get(pb.Product2.Id) != null ? LicenseView.get(pb.Product2.Id) : 0.00;
            pw.disPlans = discountPlans.get(pb.Product2.Id) != null ? discountPlans.get(pb.Product2.Id) : new List < Discount_Plan__c > ();
            pw.tierDists = tierDiscAllocation.get(pb.Product2.Id) != null ? tierDiscAllocation.get(pb.Product2.Id) : new List < Tier_Discount_Allocation__c > ();
            //pw.PSSList=PSSMap.get(pb.Product2.Id);
            pw.tax = tax != null ? tax : new Tax__c();
            pw.vatAmount = vatAmount;
            pw.otherTax = anotherTax;
            pw.totalTaxAmount = vatAmount + anotherTax;
            if (pb.Product2.Subscription_Plan__c != null) pw.endDate = System.today() + Integer.valueOf(pb.Product2.Subscription_Plan__r.Number_of_Days__c);
            if (pb.Product2.Subscription_Plan__c != null) pw.isSubProd = true;
            prodWrap.add(pw);
        }
        return prodWrap;
    }
    
    @AuraEnabled(cacheable=true)
    global static List<ProductWrapper> fetchOptionalProducts(String currProfile, String billToAddId, String shipToAddId,String prodId){
        Profiling__c profile = [Select Id,Name,Channel__c,Price_Book__c,Tax_Sourcing_Rules__c from Profiling__c where Id =:currProfile    Limit 1];
        if(profile.Tax_Sourcing_Rules__c == null) profile.Tax_Sourcing_Rules__c='Destination';
        Set<Id> siteIds=new Set<Id>();
        
        List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c from Distribution_Channel__c
                                                              where Channel__c=:profile.Channel__c and Active__c=true   limit 50];                
        if(DistributionChannels.size() > 0) {
            for(Distribution_Channel__c DC: DistributionChannels) {
                siteIds.add(DC.Site__c);
            }
        }
        
        List<Product_Service_Sell__c> PSS=new List<Product_Service_Sell__c>();        
        PSS=[Select Id,Name,Parent_Product__c,Related_Product__c from Product_Service_Sell__c where Parent_Product__c =:prodId AND Active__c=true   limit 50];
        Set<Id> PSSRelatedProdIds=new Set<Id>();
        for(Product_Service_Sell__c ps: PSS){
            PSSRelatedProdIds.add(ps.Related_Product__c);
        }
        List<PricebookEntry> pbe= [Select UnitPrice,Product2.Id,Product2.Name,Product2.Track_Inventory__c, Product2.ProductCode,Product2.Description,Product2.BOM__c,Product2.Configure__c,Product2.Allow_Back_orders__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure,Product2.Subscription_Plan__c,Product2.Subscription_Plan__r.Number_of_Days__c from PricebookEntry where Pricebook2Id =:profile.Price_Book__c AND Product2Id IN (Select Id From Product2 where IsActive=TRUE AND Id In: PSSRelatedProdIds ) AND IsActive=TRUE   limit 50];
        Set<Id> productIds=new Set<Id>();            
        for(PricebookEntry pb1 : pbe) productIds.add(pb1.Product2.Id);
                
        List <Inventory_Stock__c> WarehouseItemInventoryStocks = new List <Inventory_Stock__c>();
        if(productIds.size() > 0) {
            WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                            Number_of_Item_In_Stock__c, BOM__c From Inventory_Stock__c
                                            Where product__c In: productIds And
                                            Active__c = true And
                                            Warehouse__c In: siteIds And                                                 
                                            Number_of_Item_In_Stock__c > 0   limit 50];
        }	        
        Map<String, Decimal> stockView = new Map<String, Decimal>();
        for(Id prId:productIds){
            Decimal stock=0;
            for(Inventory_Stock__c inven : WarehouseItemInventoryStocks){ if(prId == inven.product__c){ stock += inven.Number_of_Item_In_Stock__c; }
            }
            stockView.put(prId,stock);                
        }
        //*************Stock Calculation ends**************
        
        //=========Discount Plan==============
        Integer currentQuantity=1;
        List <Tier_Discount_Allocation__c> TDAS= new List <Tier_Discount_Allocation__c>();
        TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, 
                product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                From Tier_Discount_Allocation__c
                Where order_Profile__c = : profile.Id And
                Price_Book__c =:profile.Price_Book__c AND
                product__c In: productIds And
                Tier__r.Floor_Unit__c <= : currentQuantity And
                Tier__r.Ceiling_Unit__c >= : currentQuantity And
                Tier__r.Active__c = true And
                Discount_Plan__r.Active__c = true And
                Active__c = true   limit 50];
        
        List <Id> discountPlanIds = new List <Id>();
        for(Tier_Discount_Allocation__c TDA: TDAS) { if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
        }
        List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
        discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                     Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                     From Discount_Plan__c
                     Where Id In: discountPlanIds And
                     Active__c = True   limit 50];
        
        Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
        for(Discount_Plan__c dis: discounts)  discountMap.put(dis.id, dis);
        
        
        Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
        Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
        for(PricebookEntry pbPro: pbe) {           
            List <Discount_Plan__c> myDiscountPlans = new List <Discount_Plan__c>();
            List <Tier_Discount_Allocation__c> myTierDiscAlc = new List <Tier_Discount_Allocation__c>();
            for(Tier_Discount_Allocation__c TDA: TDAS) {
                if(pbPro.Product2.Id == TDA.product__c && TDA.Discount_Plan__c != Null) { myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));myTierDiscAlc.add(TDA);
                }
            }
            discountPlans.put(pbPro.Product2.Id, myDiscountPlans);  
            tierDiscAllocation.put(pbPro.Product2.Id, myTierDiscAlc);
            
            
        }
        
        //==============/Discount Plan===========================
        
        //=============Taxex Calculation start=====================
        Date todayDate = system.today();
        List<Tax__c> profileTax = new List<Tax__c>();
        profileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c = Null AND Active__c=true   order by Province__c DESC limit 50];
        
        List<Tax__c> productprofileTax = new List<Tax__c>();
        productprofileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c != Null AND Product__c In : productIds AND Active__c=true   order by Province__c DESC limit 50];
        
        Address__c quoteBillToAdd;
        Address__c quoteShipToAdd;
        if(billToAddId != '' && billToAddId != null) quoteBillToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:billToAddId AND Active__c=true    Limit 1];
        if(shipToAddId != '' && shipToAddId != null) quoteShipToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:shipToAddId AND Active__c=true    Limit 1];
        
        String TaxPostalCode = '';
        String TaxCity = '';
        String TaxProvince = '';
        String TaxCountry = '';
        if(quoteBillToAdd != Null){
            if(profile.Tax_Sourcing_Rules__c =='Origin'){
                if(quoteBillToAdd.Zip_Postal_Code__c != Null && quoteBillToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteBillToAdd.Zip_Postal_Code__c;
                if(quoteBillToAdd.City__c != Null && quoteBillToAdd.City__c != '') TaxCity = quoteBillToAdd.City__c;
                if(quoteBillToAdd.State__c != Null && quoteBillToAdd.State__c != '') TaxProvince = quoteBillToAdd.State__c;
                if(quoteBillToAdd.Country__c != Null && quoteBillToAdd.Country__c != '') TaxCountry = quoteBillToAdd.Country__c;
            }
        }        
        
        if(quoteShipToAdd != Null){
            if(profile.Tax_Sourcing_Rules__c =='Destination'){                if(quoteShipToAdd.Zip_Postal_Code__c != Null && quoteShipToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteShipToAdd.Zip_Postal_Code__c;                if(quoteShipToAdd.City__c != Null && quoteShipToAdd.City__c != '') TaxCity = quoteShipToAdd.City__c;                if(quoteShipToAdd.State__c != Null && quoteShipToAdd.State__c != '') TaxProvince = quoteShipToAdd.State__c;                if(quoteShipToAdd.Country__c != Null && quoteShipToAdd.Country__c != '') TaxCountry = quoteShipToAdd.Country__c;
            }
        }        
        
        //=============Taxex Calculation end=====================
        
        List<ProductWrapper> prodWrap=new List<ProductWrapper>();
        for(PricebookEntry pb : pbe){         
            
            List<SelectOptions> options = new List<SelectOptions>();
            options.add(new SelectOptions('--None--',''));
            if(discountPlans.get(pb.Product2.Id) != null) {
                for(Discount_Plan__c dis: discountPlans.get(pb.Product2.Id))  options.add(new SelectOptions(dis.Name,dis.Id));
                
            }            
            
            //=============taxes start==================
            Tax__c tax;//=new Tax__c();            
            Boolean taxFound = false;
            Decimal vatAmount=0;
            Decimal anotherTax=0;
            String taxId='';
            
            //Product Taxes
            if(productprofileTax.size() > 0){
                for(Tax__c ProductTax : productprofileTax){                    
                    if(pb.Product2.Id == ProductTax.Product__c){
                        
                        if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == TaxPostalCode && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){ tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break;                                                         
                        }
                        if(!taxFound){
                            if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){  tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                        }
                        if(!taxFound){
                            if((TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == TaxCountry)){ tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                        }
                        if(!taxFound){
                            if(ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == Null){   tax=ProductTax; taxId=ProductTax.Id;  taxFound = true;  break;  }
                        }
                    }
                }
            }
            //Profile Taxes
            if(!taxFound){										//When ProductTax will not available                
                if(profileTax.size() > 0){
                    for(Tax__c profileTax1 : profileTax){
                        
                        if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == TaxPostalCode && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id; taxFound = true; break;  }
                        if(!taxFound){ if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id;  taxFound = true; break; }
                        }
                        if(!taxFound){ if((TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == TaxCountry)){  tax=profileTax1; taxId=profileTax1.Id; taxFound = true;  break; }
                        }
                        if(!taxFound){ if(profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == Null){  tax=profileTax1;  taxId=profileTax1.Id; taxFound = true; break; }
                        }
                    }
                }                
            }
            //=============taxes end==================
            
            ProductWrapper pw=new ProductWrapper();
            pw.pbe=pb;
            if(pb.Product2.BOM__c != null) pw.version=pb.Product2.BOM__c;
            pw.CurrentDiscounts=options;
            pw.stock= stockView.get(pb.Product2.Id) != null ? stockView.get(pb.Product2.Id) : 0.00;
            pw.disPlans= discountPlans.get(pb.Product2.Id) != null ? discountPlans.get(pb.Product2.Id) : new List<Discount_Plan__c>();
            pw.tierDists= tierDiscAllocation.get(pb.Product2.Id)!= null ? tierDiscAllocation.get(pb.Product2.Id) : new List<Tier_Discount_Allocation__c>();
            pw.tax= tax != null ? tax : new Tax__c();
            pw.vatAmount=vatAmount;
            pw.otherTax=anotherTax;
            pw.totalTaxAmount=vatAmount+anotherTax;
            if(pb.Product2.Subscription_Plan__c != null) pw.endDate= System.today()+Integer.valueOf(pb.Product2.Subscription_Plan__r.Number_of_Days__c);
            if(pb.Product2.Subscription_Plan__c != null) pw.isSubProd=true;
            prodWrap.add(pw);            
        }
        return prodWrap;
    }
    
    @AuraEnabled(cacheable=true)
    global static List<ProductWrapper> getSubscriptions(String currCustomer,String currProfile, String billToAddId, String shipToAddId,String searchItem, String prodFamily){
        Profiling__c profile = [Select Id,Name,Channel__c,Price_Book__c,Tax_Sourcing_Rules__c from Profiling__c where Id =:currProfile    Limit 1];
        if(profile.Tax_Sourcing_Rules__c == null) profile.Tax_Sourcing_Rules__c='Destination';
                
        String searchProductBy='%'+searchItem+'%';
        
        List<Subscription__c> subscriptionsList=new List<Subscription__c>();
        if(!String.isEmpty(searchItem) && !String.isEmpty(prodFamily))
        	subscriptionsList=[Select Id,Name,BOM__c,Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Description,Product__r.BOM__c,Product__r.Configure__c,Product__r.Allow_Back_orders__c,Product__r.Picture__c,Product__r.Serialise__c,Product__r.QuantityUnitOfMeasure,Product__r.Subscription_Plan__c,Product__r.Subscription_Plan__r.Number_of_Days__c,Description__c,Discount__c,End_Date__c,Price__c,Quantity__c,Start_Date__c from Subscription__c Where (Product__r.Name like: searchProductBy OR Product__r.ProductCode like: searchProductBy OR Product__r.StockKeepingUnit like:searchProductBy)  AND Product__r.Family=:prodFamily AND Account__c=:currCustomer AND Active__c=true    Limit 50];
        else if(!String.isEmpty(prodFamily))
        	subscriptionsList=[Select Id,Name,BOM__c,Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Description,Product__r.BOM__c,Product__r.Configure__c,Product__r.Allow_Back_orders__c,Product__r.Picture__c,Product__r.Serialise__c,Product__r.QuantityUnitOfMeasure,Product__r.Subscription_Plan__c,Product__r.Subscription_Plan__r.Number_of_Days__c,Description__c,Discount__c,End_Date__c,Price__c,Quantity__c,Start_Date__c from Subscription__c Where (Product__r.Name like: searchProductBy OR Product__r.ProductCode like: searchProductBy OR Product__r.StockKeepingUnit like:searchProductBy) AND Product__r.Family=:prodFamily AND Account__c=:currCustomer AND Active__c=true    Limit 50];
        else
            subscriptionsList=[Select Id,Name,BOM__c,Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Description,Product__r.BOM__c,Product__r.Configure__c,Product__r.Allow_Back_orders__c,Product__r.Picture__c,Product__r.Serialise__c,Product__r.QuantityUnitOfMeasure,Product__r.Subscription_Plan__c,Product__r.Subscription_Plan__r.Number_of_Days__c,Description__c,Discount__c,End_Date__c,Price__c,Quantity__c,Start_Date__c from Subscription__c Where (Product__r.Name like: searchProductBy OR Product__r.ProductCode like: searchProductBy OR Product__r.StockKeepingUnit like:searchProductBy) AND Account__c=:currCustomer AND Active__c=true    Limit 50];
           
        Set<Id> searchProdIds=new Set<Id>();
        for(Subscription__c sb:subscriptionsList)
            searchProdIds.add(sb.Product__c);
                   
        Set<Id> siteIds=new Set<Id>();        
        List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c from Distribution_Channel__c
                                                              where Channel__c=:profile.Channel__c and Active__c=true   limit 50];                
        if(DistributionChannels.size() > 0) {
            for(Distribution_Channel__c DC: DistributionChannels) {
                siteIds.add(DC.Site__c);
            }
        }
        List <Inventory_Stock__c> WarehouseItemInventoryStocks = new List <Inventory_Stock__c>();
        if(searchProdIds.size() > 0) {
            WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                            Number_of_Item_In_Stock__c, BOM__c From Inventory_Stock__c
                                            Where product__c In: searchProdIds And
                                            Active__c = true And
                                            Warehouse__c In: siteIds And                                                 
                                            Number_of_Item_In_Stock__c > 0   limit 50];
        }	        
        Map<String, Decimal> stockView = new Map<String, Decimal>();
        for(Id prId:searchProdIds){
            Decimal stock=0;
            for(Inventory_Stock__c inven : WarehouseItemInventoryStocks){
                if(prId == inven.product__c){stock += inven.Number_of_Item_In_Stock__c;
                }
            }
            stockView.put(prId,stock);                
        }
        //*************Stock Calculation ends**************
        
        //=========Discount Plan==============
        Integer currentQuantity=1;
        List <Tier_Discount_Allocation__c> TDAS= new List <Tier_Discount_Allocation__c>();
        TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, 
                product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                From Tier_Discount_Allocation__c
                Where order_Profile__c = : profile.Id And
                Price_Book__c =:profile.Price_Book__c AND
                product__c In: searchProdIds And
                Tier__r.Floor_Unit__c <= : currentQuantity And
                Tier__r.Ceiling_Unit__c >= : currentQuantity And
                Tier__r.Active__c = true And
                Discount_Plan__r.Active__c = true And
                Active__c = true   limit 50];
        
        List <Id> discountPlanIds = new List <Id>();
        for(Tier_Discount_Allocation__c TDA: TDAS) { if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
        }
        List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
        discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                     Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                     From Discount_Plan__c
                     Where Id In: discountPlanIds And
                     Active__c = True   limit 50];
        
        Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
        for(Discount_Plan__c dis: discounts)  discountMap.put(dis.id, dis);
        
        
        Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
        Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
        for(Subscription__c sb:subscriptionsList) {           
            List <Discount_Plan__c> myDiscountPlans = new List <Discount_Plan__c>();List <Tier_Discount_Allocation__c> myTierDiscAlc = new List <Tier_Discount_Allocation__c>();
            for(Tier_Discount_Allocation__c TDA: TDAS) {
                if(sb.Product__c == TDA.product__c && TDA.Discount_Plan__c != Null) {
                    myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));myTierDiscAlc.add(TDA);
                }
            }
            discountPlans.put(sb.Product__c, myDiscountPlans);  tierDiscAllocation.put(sb.Product__c, myTierDiscAlc);            
        }
        
        //==============/Discount Plan===========================
        
        //=============Taxex Calculation start=====================
        Date todayDate = system.today();
        List<Tax__c> profileTax = new List<Tax__c>();
        profileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c = Null AND Active__c=true   order by Province__c DESC limit 50];
        
        List<Tax__c> productprofileTax = new List<Tax__c>();
        productprofileTax=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Rate__c,Type__c from Tax__c where Account_Profile__c =:profile.Id AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Tax_Rate__c != Null AND Product__c != Null AND Product__c In : searchProdIds AND Active__c=true   order by Province__c DESC limit 50];
        
        Address__c quoteBillToAdd;
        Address__c quoteShipToAdd;
        if(billToAddId != '' && billToAddId != null) quoteBillToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:billToAddId AND Active__c=true    Limit 1];
        if(shipToAddId != '' && shipToAddId != null) quoteShipToAdd=[Select Id,Name,Active__c,Address__c,City__c,Country__c,State__c,Zip_Postal_Code__c from Address__c where Id =:shipToAddId AND Active__c=true    Limit 1];
        
        String TaxPostalCode = '';
        String TaxCity = '';
        String TaxProvince = '';
        String TaxCountry = '';
        if(quoteBillToAdd != Null){
            if(profile.Tax_Sourcing_Rules__c =='Origin'){
                if(quoteBillToAdd.Zip_Postal_Code__c != Null && quoteBillToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteBillToAdd.Zip_Postal_Code__c;
                if(quoteBillToAdd.City__c != Null && quoteBillToAdd.City__c != '') TaxCity = quoteBillToAdd.City__c;
                if(quoteBillToAdd.State__c != Null && quoteBillToAdd.State__c != '') TaxProvince = quoteBillToAdd.State__c;
                if(quoteBillToAdd.Country__c != Null && quoteBillToAdd.Country__c != '') TaxCountry = quoteBillToAdd.Country__c;
            }
        }        
        
        if(quoteShipToAdd != Null){
            if(profile.Tax_Sourcing_Rules__c =='Destination'){                if(quoteShipToAdd.Zip_Postal_Code__c != Null && quoteShipToAdd.Zip_Postal_Code__c != '') TaxPostalCode = quoteShipToAdd.Zip_Postal_Code__c;                if(quoteShipToAdd.City__c != Null && quoteShipToAdd.City__c != '') TaxCity = quoteShipToAdd.City__c;                if(quoteShipToAdd.State__c != Null && quoteShipToAdd.State__c != '') TaxProvince = quoteShipToAdd.State__c;                if(quoteShipToAdd.Country__c != Null && quoteShipToAdd.Country__c != '') TaxCountry = quoteShipToAdd.Country__c;
            }
        }        
        
        //=============Taxex Calculation end=====================
        
        List<ProductWrapper> prodWrap=new List<ProductWrapper>();
        for(Subscription__c sb:subscriptionsList){         
            
            List<SelectOptions> options = new List<SelectOptions>();
            options.add(new SelectOptions('--None--',''));
            if(discountPlans.get(sb.Product__c) != null) {
                for(Discount_Plan__c dis: discountPlans.get(sb.Product__c))  options.add(new SelectOptions(dis.Name,dis.Id));
                
            }            
            
            //=============taxes start==================
            Tax__c tax;//=new Tax__c();            
            Boolean taxFound = false;
            Decimal vatAmount=0;
            Decimal anotherTax=0;
            String taxId='';
            
            //Product Taxes
            if(productprofileTax.size() > 0){
                for(Tax__c ProductTax : productprofileTax){                    
                    if(sb.Product__c == ProductTax.Product__c){
                        
                        if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == TaxPostalCode && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){
                            tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break;                                                         
                        }
                        if(!taxFound){
                            if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.Province__c == TaxProvince && ProductTax.Country__c == TaxCountry)){  tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                        }
                        if(!taxFound){
                            if((TaxCountry != Null && TaxCountry != '') && (ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == TaxCountry)){ tax=ProductTax; taxId=ProductTax.Id; taxFound = true; break; }
                        }
                        if(!taxFound){
                            if(ProductTax.Postal_Code__c == Null && ProductTax.City__c == Null && ProductTax.Province__c == Null && ProductTax.Country__c == Null){   tax=ProductTax; taxId=ProductTax.Id;  taxFound = true;  break;  }
                        }
                    }
                }
            }
            //Profile Taxes
            if(!taxFound){										//When ProductTax will not available                
                if(profileTax.size() > 0){
                    for(Tax__c profileTax1 : profileTax){
                        
                        if((TaxPostalCode != Null && TaxPostalCode != '' && TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == TaxPostalCode && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id; taxFound = true; break;  }
                        if(!taxFound){
                            if((TaxProvince != Null && TaxProvince != '' && TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.Province__c == TaxProvince && profileTax1.Country__c == TaxCountry)){ tax=profileTax1; taxId=profileTax1.Id;  taxFound = true; break; }
                        }
                        if(!taxFound){
                            if((TaxCountry != Null && TaxCountry != '') && (profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == TaxCountry)){  tax=profileTax1; taxId=profileTax1.Id; taxFound = true;  break; }
                        }
                        if(!taxFound){
                            if(profileTax1.Postal_Code__c == Null && profileTax1.City__c == Null && profileTax1.Province__c == Null && profileTax1.Country__c == Null){  tax=profileTax1;  taxId=profileTax1.Id; taxFound = true; break; }
                        }
                    }
                }                
            }
            //=============taxes end==================
            
            ProductWrapper pw=new ProductWrapper();pw.subs=sb;pw.quantity=sb.Quantity__c;
            if(sb.BOM__c != null) pw.version=sb.BOM__c;            
            pw.CurrentDiscounts=options;pw.stock= stockView.get(sb.Product__c) != null ? stockView.get(sb.Product__c) : 0.00;pw.tierDists= tierDiscAllocation.get(sb.Product__c)!= null ? tierDiscAllocation.get(sb.Product__c) : new List<Tier_Discount_Allocation__c>();pw.tax= tax != null ? tax : new Tax__c();pw.vatAmount=vatAmount;pw.otherTax=anotherTax;pw.totalTaxAmount=vatAmount+anotherTax;pw.startDate=sb.Start_Date__c;pw.endDate= sb.End_Date__c;pw.isSubProd=true;
            prodWrap.add(pw);            
        }
        return prodWrap;
    }    
    
    @AuraEnabled
    global static List<ProductWrapper> getDiscountPlan(String profileId,String prodId, Decimal quantity){
        Set<Id> productIds=new Set<Id>();            
        productIds.add(prodId);
        
        List <Tier_Discount_Allocation__c> TDAS= new List <Tier_Discount_Allocation__c>();
        TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, 
                product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                From Tier_Discount_Allocation__c
                Where Order_Profile__c = : profileId And
                product__c In: productIds And
                Tier__r.Floor_Unit__c <= : quantity And
                Tier__r.Ceiling_Unit__c >= : quantity And
                Tier__r.Active__c = true And
                Discount_Plan__r.Active__c = true And
                Active__c = true   limit 50];
        
        List <Id> discountPlanIds = new List <Id>();
        for(Tier_Discount_Allocation__c TDA: TDAS) {
            if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
        }
        List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
        discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                     Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                     From Discount_Plan__c
                     Where Id In: discountPlanIds And
                     Active__c = True   limit 50];
        
        Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
        for(Discount_Plan__c dis: discounts) {
            discountMap.put(dis.id, dis);
        }
        
        Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
        Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
        //for(PricebookEntry pbPro: pbe) {
        List <Discount_Plan__c> myDiscountPlans = new List <Discount_Plan__c>();
        List <Tier_Discount_Allocation__c> myTierDiscAlc = new List <Tier_Discount_Allocation__c>();
        for(Tier_Discount_Allocation__c TDA: TDAS) {
            if(prodId == TDA.product__c && TDA.Discount_Plan__c != Null) {
                myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));
                myTierDiscAlc.add(TDA);
            }
        }
        discountPlans.put(prodId, myDiscountPlans);  
        tierDiscAllocation.put(prodId, myTierDiscAlc);
        //}
        List<ProductWrapper> prWrapperList=new List<ProductWrapper>();
        //for(PricebookEntry pb : pbe){
        List<SelectOptions> options = new List<SelectOptions>();
        options.add(new SelectOptions('--None--',''));
        if(discountPlans.get(prodId) != null) {
            for(Discount_Plan__c dis: discountPlans.get(prodId)) {
                options.add(new SelectOptions(dis.Name,dis.Id));
            }
        }
        
        ProductWrapper prWrapper=new ProductWrapper();
        prWrapper.CurrentDiscounts=options;
        prWrapper.disPlans=(discountPlans.get(prodId)!= null)? discountPlans.get(prodId):new List<Discount_Plan__c>();
        prWrapper.tierDists=(tierDiscAllocation.get(prodId)!= null)? tierDiscAllocation.get(prodId):new List<Tier_Discount_Allocation__c>();
        
        prWrapperList.add(prWrapper);
        //pbe1.add(new pbeWrapper(new PricebookEntry(),'',new ERP7__Site__c(),'',options,0.00,(discountPlans.get(prodId)!= null)? discountPlans.get(prodId):new List<ERP7__Discount_Plan__c>(),(tierDiscAllocation.get(prodId)!= null)? tierDiscAllocation.get(prodId):new List<ERP7__Tier_Discount_Allocation__c>(),new ERP7__Tax__c(),'',0,0));    //      ,(discountPlans.get(pb.Product2.Id)!= null)? discountPlans.get(pb.Product2.Id):discountPlans.get(pb.Product2.Id),(tierDiscAllocation.get(pb.Product2.Id)!= null)? tierDiscAllocation.get(pb.Product2.Id):tierDiscAllocation.get(pb.Product2.Id)         
        
        //}
        return prWrapperList;
    }
    
    @AuraEnabled
    global static String draftQuoteSave(String quote, String quoteLines, String quoteLinesIdToDel){
        String message='';
        try{
            List<String> itemsToDel = (List<String>) JSON.deserialize(quoteLinesIdToDel, List<String>.class);            
            if(itemsToDel.size() > 0 && Quote_Line_Items__c.sObjectType.getDescribe().isDeletable()) Database.delete(itemsToDel);
            
            
            Quotes__c quoteToUpsert = new Quotes__c();
            quoteToUpsert =  (Quotes__c) JSON.deserialize(quote, Quotes__c.class);
            if(string.isEmpty(quoteToUpsert.Id))quoteToUpsert.Id = null;
            if(Schema.sObjectType.Quotes__c.isCreateable() && Schema.sObjectType.Quotes__c.isUpdateable()) upsert quoteToUpsert;
            message=JSON.serialize([Select Id,Name from Quotes__c where Id =:quoteToUpsert.Id Limit 1]) ;
            List<Quote_Line_Items__c> quoteLinesToUpsert = (List<Quote_Line_Items__c>) JSON.deserialize(quoteLines, List<Quote_Line_Items__c>.class);
            System.debug('quoteLinesToUpsert::'+quoteLinesToUpsert);
            for(Quote_Line_Items__c qtLine:quoteLinesToUpsert){
                if(qtLine.Id == null) qtLine.Quotes__c=quoteToUpsert.Id;                
            }
            
            
            if(quoteLinesToUpsert.size() > 0 && Schema.sObjectType.Quote_Line_Items__c.isCreateable() && Schema.sObjectType.Quote_Line_Items__c.isUpdateable()) upsert quoteLinesToUpsert;
            
            
        }catch(Exception e){message=e.getMessage()+'Line:'+e.getLineNumber();
                            System.debug(message=e.getMessage()+'Line:'+e.getLineNumber());}
        
        return message;
    }
    
    global class ProductWrapper{
        @AuraEnabled global PricebookEntry pbe							{ get; set; }
        @AuraEnabled global Subscription__c subs					{ get; set; }
        @AuraEnabled global String version								{ get; set; }
        @AuraEnabled global List<SelectOptions> CurrentDiscounts       { get; set; }
        @AuraEnabled global Decimal stock								{ get; set; }
        @AuraEnabled global Decimal License								{ get; set; }
        @AuraEnabled global List<Discount_Plan__c> disPlans				{ get; set; }
        @AuraEnabled global List<Tier_Discount_Allocation__c> tierDists	{ get; set; }
        @AuraEnabled global Tax__c tax							{ get; set; }
        //@AuraEnabled global String taxId								{ get; set; }
        @AuraEnabled global Decimal vatAmount							{ get; set; }
        @AuraEnabled global Decimal otherTax							{ get; set; }
        @AuraEnabled global Decimal totalTaxAmount							{ get; set; }
        @AuraEnabled global Boolean isSubscribe							{ get; set; }
        @AuraEnabled global Decimal quantity							{ get; set; }
        @AuraEnabled global Decimal minDiscount							{ get; set; }
        @AuraEnabled global Decimal maxDiscount							{ get; set; }
        @AuraEnabled global Decimal discountPercent                    	{ get; set; }
        @AuraEnabled global Decimal totalDiscount                    	{ get; set; }
        @AuraEnabled global Boolean isPercent							{ get; set; }
        @AuraEnabled global String discountPlan							{ get; set; }
        @AuraEnabled global Date startDate							    { get; set; }
        @AuraEnabled global Date endDate							    { get; set; }
        @AuraEnabled global Boolean isSubProd							{ get; set; }
        @AuraEnabled global Boolean isgoodsDescription				    { get; set; }
        @AuraEnabled global Boolean ShowUOMData				            { get; set; }
        @AuraEnabled global Boolean ShowStockData				        { get; set; }
        @AuraEnabled global Boolean ShowOption 							{ get; set; }
        
        global ProductWrapper(){	
            pbe=new PricebookEntry();
            subs=new Subscription__c();
            version='';
            quantity=1;
            minDiscount=0;
            maxDiscount=0;           
            stock=0;
            License=0;
            CurrentDiscounts=new List<SelectOptions>();
            discountPercent=0;
            totalDiscount=0;
            disPlans=new List<Discount_Plan__c>();
            tierDists= new List<Tier_Discount_Allocation__c>();
            tax=new Tax__c();
            vatAmount=0;
            otherTax=0;
            totalTaxAmount=0;
            isPercent=true;
            isSubscribe = false;
            discountPlan='';
            startDate=System.today();
            endDate=System.today() + 29;
            isSubProd=false;
            isgoodsDescription=false;
            ShowUOMData=false;
            ShowStockData=false;
            
        }
    }
    
    @AuraEnabled
    global static QtWrapper fetchQuoteLine(String quoteId){
        system.debug('qo-');
        QtWrapper qtAndLine=new QtWrapper();
        try{
            Boolean isMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
            if(isMultiCurrency) qtAndLine.quote=Database.Query('Select Id,CurrencyIsoCode,Name,Employee__c,Bill_To_Address__c,Company__c,Price_Book__c,Channel__c,Contact__c,Customer__c,Customer__r.Order_Profile__c,Order_Profile__c,Ship_To_Address__c,Status__c,Request_Date__c,Description__c,opportunities__c  from Quotes__c where Id =:quoteId    Limit 1');
            if(!isMultiCurrency) qtAndLine.quote=[Select Id,Name,Employee__c,Bill_To_Address__c,Channel__c,Contact__c,Company__c,Price_Book__c,Customer__c,Customer__r.Order_Profile__c,Order_Profile__c,Ship_To_Address__c,Status__c,Request_Date__c,Description__c,Opportunity__c,Opportunity_Id__c,Opportunity_Name__c,opportunities__c from Quotes__c where Id =:quoteId    Limit 1];
            
            qtAndLine.qtLine=[Select Id,Name,Site__c,Site__r.Name,List_Price__c,Commission__c,Optional_Item__c,
                              Discount_Amount__c,Discount_Percent__c,Discount_Plan__c,Discount_Plan__r.Name,Month_Duration__c,Duration_in_Days__c,
                              Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                        	  Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c,
                              Other_Tax__c,Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Picture__c,Product__r.Description,Product__r.Serialise__c,
                              Product__r.Track_Inventory__c, Product__r.Allow_Back_Orders__c,Product__r.Configure__c,Product__r.QuantityUnitOfMeasure,Product__r.Is_Subscribe__c,Net_Price__c,
                              Product__r.BOM__c,Product__r.Subscription_Plan__c,Product_Version__c,Quantity__c,sortOrder__c,Pricebook_Entry_Id__c,PriceBookId__c,
                              VAT_Amount__c,Tax__c,Description__c,TotalPrice__c,Status__c,Start_Date__c,End_Date__c,Product_Subscription_Plan_Allocation__c,Purchase_Type__c,FreeOfCharge__c
                              from Quote_Line_Items__c where Quotes__c =:quoteId   order by sortOrder__c limit 200];
            
            String profileId=qtAndLine.quote.Order_Profile__c != null ?qtAndLine.quote.Order_Profile__c : qtAndLine.quote.Customer__r.Order_Profile__c;
            
            Set<Id> productIds=new Set<Id>();
            Set<Id> qtLinetaxIds=new Set<Id>();
            for(Quote_Line_Items__c qtLine1:qtAndLine.qtLine){
                productIds.add(qtLine1.Product__c);
                qtLinetaxIds.add(qtLine1.Tax__c);
            }
            
            
           
            Date todayDate = system.today();
            qtAndLine.taxMap=[Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Code__c,Tax_Rate__c,Type__c from Tax__c where Id In:qtLinetaxIds AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Active__c=true   limit 1];
            qtAndLine.TDA = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, 
                        Product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
                        Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
                        Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
                        From Tier_Discount_Allocation__c
                        Where Order_Profile__c = : profileId And
                        product__c In: productIds And
                        Tier__r.Active__c = true And
                        Discount_Plan__r.Active__c = true And Discount_Plan__r.Status__c='Manager Approved' AND
                        Active__c = true   limit 50];
            
            List <Id> discPlanIds = new List <Id>();
            for(Tier_Discount_Allocation__c TDA: qtAndLine.TDA) {
                if(TDA.Discount_Plan__c != Null) discPlanIds.add(TDA.Discount_Plan__c);
            }
            qtAndLine.discountPlans = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                         Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                         From Discount_Plan__c
                         Where Id In: discPlanIds And
                         Active__c = True   limit 50];
              
        }catch(Exception e){ qtAndLine.errorMsg=e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }        
        return qtAndLine;
        
    }
    
    global class QtWrapper{
        @AuraEnabled global String errorMsg									{ get; set; }
        @AuraEnabled global Quotes__c quote							{ get; set; }
        @AuraEnabled global List<Quote_Line_Items__c> qtLine			{ get; set; }
        @AuraEnabled global List<Tax__c> taxMap						{ get; set; }
        @AuraEnabled global List<Tier_Discount_Allocation__c> TDA		{ get; set; }
        @AuraEnabled global List<Discount_Plan__c> discountPlans		{ get; set; }
        
        global QtWrapper(){
            errorMsg = '';
            quote=new Quotes__c();
            qtLine=new List<Quote_Line_Items__c>();
            taxMap=new List<Tax__c>();
            TDA=new List<Tier_Discount_Allocation__c>();
            discountPlans=new List<Discount_Plan__c>();
        }
    }

    @AuraEnabled
    global static Quotes__c getQuoteId(String Qid){
        Quotes__c  quote = new Quotes__c();
        if(String.isNotEmpty(Qid)) quote = [select Id, Name from Quotes__c where Id =:QId   limit 1];
        
        return quote;
    }

    @AuraEnabled
    global static List<Subscription_Plan__c> getSubscriptionPlans(){

        List<Subscription_Plan__c>  plans = new List<Subscription_Plan__c>();
        plans = [select Id,Name,Number_of_Days__c,Duration_Unit__c,Duration__c,Description__c,Active__c from Subscription_Plan__c Where Active__c = true   limit 50];
       	
        return plans;
    }
    @AuraEnabled
    global static SubPlanWrapper getselectedplanDetails (string selectedPlan_Id){
        SubPlanWrapper selectedplanwrap = new SubPlanWrapper();
        try{            
            if(String.isNotEmpty(SelectedPlan_Id)) selectedplanwrap.SelectedsubPlan  = [select Id,Name,Subscription_Plan__r.Duration__c,Subscription_Plan__r.Order_Delivery_Frequency__c from Product_Subscription_Plan_Allocation__c where Id =: selectedPlan_Id and Active__c =:true   limit 1];
       	    
        }
        catch(Exception e){selectedplanwrap.errorMsg=e.getMessage() +' Line Number @ : '+ e.getLineNumber();}        
        return selectedplanwrap;
    }
    global class SubPlanWrapper{
        @AuraEnabled global String errorMsg									                { get; set; }@AuraEnabled global Product_Subscription_Plan_Allocation__c  SelectedsubPlan	{ get; set; }
        global SubPlanWrapper(){
            errorMsg = '';SelectedsubPlan =new Product_Subscription_Plan_Allocation__c ();
        }
    }
    
    @AuraEnabled
    global static functionalityWrap getFnctionalityControls(){
        functionalityWrap Fwrap =new functionalityWrap();

             /* Visibility Control */
             Functionality_Control__c FC = new Functionality_Control__c();
             FC = Functionality_Control__c.getValues(userInfo.getuserid());
             if(FC == null){ FC = Functionality_Control__c.getValues(userInfo.getProfileId());  if(FC==null) FC = Functionality_Control__c.getInstance(); }
             if(FC != null){ 
                             Fwrap.ShowUOM =FC.Show_UOM__c;
                             Fwrap.ShowStock = FC.Show_Stock__c;
                             Fwrap.ShowFamily = FC.Show_Family_product_Filter__c;
                             Fwrap.handleDiscountField = FC.Control_Discount_field_on_Quote_Console__c;
                             Fwrap.allowZeroUnitprice = FC.Allow_Adding_Zero_Unit_Products_on_Quot__c;
                             Fwrap.showconfigBtn = FC.Config_Button_on_QuoteConsole__c;
                             Fwrap.HidePnLBtn = FC.P_L_Button__c;
                 			 Fwrap.ShowOption = FC.Show_Optional_Selected_Items__c;
                             Fwrap.ApplyDiscountTaxOnWholeQuote = FC.Apply_Discount_Tax_on_Whole_Quote__c;
                             Fwrap.MarkFOCQuote = FC.MarkFOC__c;
                             //Fwrap.assignAccountCurrency = FC.get_Default_Currency_From_Account__c;
                             Fwrap.applywholeQuoteDiscount=FC.Apply_Discount_on_Whole_Quote__c;
                           }

        return Fwrap;
    }

    global class functionalityWrap{
        @AuraEnabled global boolean ShowFamily									                { get; set; }
        @AuraEnabled global boolean ShowUOM									                    { get; set; }
        @AuraEnabled global boolean ShowStock									                { get; set; }
        @AuraEnabled global boolean handleDiscountField									        { get; set; }
        @AuraEnabled global boolean allowZeroUnitprice									        { get; set; }
        @AuraEnabled global boolean showconfigBtn									            { get; set; }
        @AuraEnabled global boolean HidePnLBtn									                { get; set; }
        @AuraEnabled global boolean ShowOption													{ get; set; }
        @AuraEnabled global boolean ApplyDiscountTaxOnWholeQuote								{ get; set; }
        @AuraEnabled global boolean MarkFOCQuote								                { get; set; }
         @AuraEnabled public boolean applywholeQuoteDiscount								        { get; set; }
        global functionalityWrap(){
            ShowFamily = false;
            ShowUOM = false;
            ShowStock = false;
            handleDiscountField = false;
            allowZeroUnitprice = false;
            showconfigBtn = false;
            HidePnLBtn = false;
            ShowOption = false;
            ApplyDiscountTaxOnWholeQuote = false;
            MarkFOCQuote = false;
            applywholeQuoteDiscount = false;
        }
    }
    
    @AuraEnabled
    global static ConfigBOMs FetchBOMs (string QuoteLineId,string QuotelineVersion){
        ConfigBOMs Config = new ConfigBOMs();
        try{            
            Config.QuoteLineItem = [Select Id,Name,Quantity__c,Product_Version__c,TotalPrice__c,Product__r.Picture__c from Quote_Line_Items__c where Id=:QuoteLineId    Limit 1];
            Config.QuoteLineBOM =  [Select Id,Name,Quantity__c,Unit_Price__c,Component_BOM__c,BOM_Component__r.Picture__c from BOM_Line_Item__c Where BOM__c=:QuotelineVersion   limit 1];
            
            Set<Id> nestedBOM = new Set<Id>();
            
        if(Config.QuoteLineBOM.size() > 0) { for(BOM_Line_Item__c Bom :Config.QuoteLineBOM){ if(Bom.Component_BOM__c != null) nestedBOM.add(Bom.Component_BOM__c); } }
			Config.Level2BOM = [select Id,Name,Quantity__c,Unit_Price__c,BOM_Component__r.Picture__c,BOM__c from BOM_Line_Item__c where BOM__c IN : nestedBOM   limit 1];          
            
        	}
        catch(Exception e){Config.errorMsg=e.getMessage() +' Line Number @ : '+ e.getLineNumber();}        
        return Config;
    }

    global class ConfigBOMs{
       
        @AuraEnabled global List<Quote_Line_Items__c>  QuoteLineItem			{ get; set; }@AuraEnabled global List<BOM_Line_Item__c>  QuoteLineBOM		    { get; set; } @AuraEnabled global List<BOM_Line_Item__c>  Level2BOM		    	{ get; set; }@AuraEnabled global String errorMsg									        { get; set; }
       

        global ConfigBOMs(){

            QuoteLineItem = new List<Quote_Line_Items__c>();QuoteLineBOM  = new List<BOM_Line_Item__c>();Level2BOM	  = new List<BOM_Line_Item__c>();errorMsg      = '';
            
        }
    }
    @AuraEnabled
    global static String CheckOrg (){

        boolean OrgtypeStatus = false;
        String OrgType ='';

        try{            
            OrgtypeStatus =  [select IsSandbox from Organization   limit 1].IsSandbox;
            
            if(OrgtypeStatus)OrgType = 'SandBox'; else OrgType = 'Production-Org/Dev-Org';
           
        	}
        catch(Exception e){}  

        return OrgType;
    }

    @AuraEnabled
    global static String  getBaseURL(){

         string sfdcBaseURL = '';								

        try{            
           
            String initurl = '.vf.force.com';
            String DestinationURL = '.file.force.com';
            sfdcBaseURL = URL.getSalesforceBaseUrl().getHost();
            
            sfdcBaseURL = sfdcBaseURL.replace(initurl,DestinationURL);
     		sfdcBaseURL = sfdcBaseURL.replace('--c',''); //working in sandbox
            
           
        	}
        catch(Exception e){}  

        return sfdcBaseURL;
    }
    
    @AuraEnabled
    global static Discount_Plan__c discountPlanInfo(string planId){
        Discount_Plan__c discplanInfo = new Discount_Plan__c();discplanInfo = [Select Id,Name,Ceiling_Discount_Percentage__c,Discount_Percent__c,RecordType.Name,Default_Discount_Percentage__c from Discount_Plan__c where Id=:planId  limit 1];return discplanInfo;
    }

}