global with sharing class ConvertQuoteToOrder {
    
    @AuraEnabled
    global static OrderWrapper getQuoteAndLine(String quoteId){
        OrderWrapper qtAndLine=new OrderWrapper();
        try{
            qtAndLine.quote=[Select Id,Name,Bill_To_Address__c,Channel__c,Contact__c,Customer__c,Order_Profile__c,Order_Profile__r.Price_Book__c,Ship_To_Address__c,Status__c,Contract__c from Quotes__c where Id =:quoteId WITH SECURITY_ENFORCED Limit 1];
            qtAndLine.emp=[Select Id, Name, First_Name__c, Channel__c, Last_Name__c, Employee_User__c, Email__c, Employee_Profiling__c, Company__c
                           From Employees__c
                           Where Employee_User__c = : UserInfo.getUserId()
                           WITH SECURITY_ENFORCED order by CreatedDate Asc Limit 1];
            qtAndLine.qtLine=[Select Id,Name,List_Price__c,Commission__c,Discount_Amount__c,Discount_Percent__c,Discount_Plan__c,Other_Tax__c,Product__c,Product__r.Name,Product__r.ProductCode,Product__r.Picture__c,Product__r.Allow_Back_Orders__c,Product_Version__c,Quantity__c,sortOrder__c,VAT_Amount__c,Tax__c,Description__c,Site__c,Start_Date__c,End_Date__c,Order_Delivery_Frequency__c,Is_Subscribe__c,Product__r.Is_Subscribe__c,Product_Subscription_Plan_Allocation__c,Month_Duration__c,Duration_in_Days__c,Product__r.Track_Inventory__c, Pricebook_Entry_Id__c  from Quote_Line_Items__c where Quotes__c =:quoteId WITH SECURITY_ENFORCED order by sortOrder__c limit 500];
            
            //Id RT = Schema.SObjectType.Profiling__c.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            Id RT = Schema.SObjectType.Profiling__c.getRecordTypeInfosByDeveloperName().get('Order_Profile').getRecordTypeId(); 
            qtAndLine.recType=RT;
            List<String> options = new List<String>();
            Schema.DescribeFieldResult fieldResult = Order.Status.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry f: ple) options.add(f.getLabel()); qtAndLine.status=options;
            
            List<String> type1 = new List<String>();
            Schema.DescribeFieldResult fieldResult1 = Order.Type.getDescribe();
            List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();
            for (Schema.PicklistEntry f: ple1) type1.add(f.getLabel()); qtAndLine.type1=type1;
            
            Set<Id> productIds=new Set<Id>();
            for(Quote_Line_Items__c qtLine1:qtAndLine.qtLine){
                productIds.add(qtLine1.Product__c);
            }
            
            //=============Stock start===========================
            String profileId='';
            if(qtAndLine.quote.Customer__c != null){
                Account acc=[Select Id,Name,Order_Profile__c from Account where Id =:qtAndLine.quote.Customer__c WITH SECURITY_ENFORCED limit 1];
                profileId=acc.Order_Profile__c;
            }
            else{
                profileId=qtAndLine.quote.Order_Profile__c;
            }
            Profiling__c profile=[Select Id,Name,Channel__c,Price_Book__c,Company__c,Tax_Sourcing_Rules__c from Profiling__c where Id =:profileId WITH SECURITY_ENFORCED Limit 1];
            Set<Id> siteIds=new Set<Id>();
            Channel__c channel = [Select Id, Name from Channel__c where Id=:profile.Channel__c and Active__c=true WITH SECURITY_ENFORCED Limit 1];
            List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Channel__c, Site__c, Priority__c from Distribution_Channel__c
                                                                  where Channel__c=:channel.Id and Active__c=true WITH SECURITY_ENFORCED limit 50];
            if(DistributionChannels.size() > 0) {
                for(Distribution_Channel__c DC: DistributionChannels) {
                    siteIds.add(DC.Site__c);
                }
            }
            List <Inventory_Stock__c> WarehouseItemInventoryStocks = new List <Inventory_Stock__c>();
            if(productIds.size() > 0) {
                WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                Number_of_Item_In_Stock__c, BOM__c From Inventory_Stock__c
                                                Where product__c In: productIds And
                                                Active__c = true And
                                                Warehouse__c In: siteIds And
                                                Number_of_Item_In_Stock__c > 0 WITH SECURITY_ENFORCED limit 50
                                               ];
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
            //=============Stock end===========================
            
            List<qtLineWrapper> qtlWprList=new List<qtLineWrapper>();
            
            /*for(Quote_Line_Items__c qtLine:qtAndLine.qtLine){
qtLineWrapper qtlWpr=new qtLineWrapper();
qtlWpr.qtLine=qtLine;
if(qtLine.Tax__c != null){
Date todayDate = system.today();
qtlWpr.tax = [Select Id,Name,Active__c,Apply_Tax_On__c,City__c,Country__c,Effective_Date__c,Expiry_Date__c,Other_Tax_Rate__c,Other_Tax_Type__c,Postal_Code__c,Product__c,Province__c,Tax_Code__c,Tax_Rate__c,Type__c from Tax__c where Id =:qtLine.Tax__c AND Effective_Date__c <= :todayDate AND Expiry_Date__c >= :todayDate AND Type__c = :'Sales Tax' AND Active__c=true WITH SECURITY_ENFORCED Limit 1];
qtlWpr.taxId = qtLine.Tax__c;
}
if(qtLine.VAT_Amount__c != null) qtlWpr.vatAmount=qtLine.VAT_Amount__c.setScale(2);
if(qtLine.Other_Tax__c != null) qtlWpr.otherTax=qtLine.Other_Tax__c.setScale(2);

//================Discount Plan start===============
Decimal currentQuantity=qtLine.Quantity__c;
List <Tier_Discount_Allocation__c> TDAS= new List <Tier_Discount_Allocation__c>();
TDAS = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,
product__c, Tier__c, Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, Discount_Plan__r.Name,
Discount_Plan__r.Active__c, Default__c, Discount_Plan__r.Default_Discount_Percentage__c, Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c,
Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, Discount_Plan__r.Ceiling_Discount_Value__c
From Tier_Discount_Allocation__c
Where Order_Profile__c = : profileId And
product__c =: qtLine.Product__c And
Tier__r.Floor_Unit__c <= : currentQuantity And
Tier__r.Ceiling_Unit__c >= : currentQuantity And
Tier__r.Active__c = true And
Discount_Plan__r.Active__c = true And Discount_Plan__r.Status__c='Manager Approved' AND
Active__c = true WITH SECURITY_ENFORCED limit 50
];

List <Id> discountPlanIds = new List <Id>();
for(Tier_Discount_Allocation__c TDA: TDAS) {
if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
}
List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
From Discount_Plan__c
Where Id In: discountPlanIds And
Active__c = True WITH SECURITY_ENFORCED limit 50
];

Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
for(Discount_Plan__c dis: discounts) {
discountMap.put(dis.id, dis);
}

Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
for(Id pbPro: productIds) {
List <Discount_Plan__c> myDiscountPlans = new List <Discount_Plan__c>();
List <Tier_Discount_Allocation__c> myTierDiscAlc = new List <Tier_Discount_Allocation__c>();
for(Tier_Discount_Allocation__c TDA: TDAS) {
if(pbPro == TDA.product__c && TDA.Discount_Plan__c != Null) {
myDiscountPlans.add(discountMap.get(TDA.Discount_Plan__c));
myTierDiscAlc.add(TDA);
}
}
discountPlans.put(pbPro, myDiscountPlans);
tierDiscAllocation.put(pbPro, myTierDiscAlc);
}

List<selectOptions1> disPlans = new List<selectOptions1>();
disPlans.add(new selectOptions1('--None--',''));
if(discountPlans.get(qtLine.Product__c) != null) {
for(Discount_Plan__c dis: discountPlans.get(qtLine.Product__c)) {
disPlans.add(new selectOptions1(dis.Name,dis.Id));
}
}
qtlWpr.CurrentDiscounts=disPlans;
qtlWpr.stock=(stockView.get(qtLine.Product__c)!= null)? stockView.get(qtLine.Product__c):0.00;
qtlWpr.tierDists=(tierDiscAllocation.get(qtLine.Product__c)!= null)?tierDiscAllocation.get(qtLine.Product__c):new List<Tier_Discount_Allocation__c>();
qtlWpr.disPlans=(discountPlans.get(qtLine.Product__c)!= null)?discountPlans.get(qtLine.Product__c):new List<Discount_Plan__c>();

String discountPlan=qtLine.Discount_Plan__c;
if(discountPlan != null){
for(Discount_Plan__c disPlan:qtlWpr.disPlans){
if(qtLine.Discount_Plan__c != null){
if(qtLine.Discount_Plan__c == disPlan.Id){
if(disPlan.Default_Discount_Percentage__c != null){
qtlWpr.isPercent=true;
qtlWpr.minDiscount=disPlan.Floor_Discount_Percentage__c;
qtlWpr.maxDiscount=disPlan.Ceiling_Discount_Percentage__c;
qtlWpr.discountPercent=qtLine.Discount_Percent__c;
qtlWpr.discountPlan=qtLine.Discount_Plan__c;
}else if(disPlan.Default_Discount_Value__c != null){
qtlWpr.isPercent=false;
qtlWpr.minDiscount=disPlan.Floor_Discount_Value__c;
qtlWpr.maxDiscount=disPlan.Ceiling_Discount_Value__c;
qtlWpr.discountPercent=qtLine.Discount_Amount__c;
qtlWpr.discountPlan=qtLine.Discount_Plan__c;
}else{
qtlWpr.isPercent=true;
qtlWpr.minDiscount=0;
qtlWpr.maxDiscount=0;
qtlWpr.discountPercent=0;
qtlWpr.discountPlan='';
}
}
}
}
}else{
if(qtLine.Discount_Percent__c != null){
qtlWpr.isPercent=true;
qtlWpr.minDiscount=0;
qtlWpr.maxDiscount=0;
qtlWpr.discountPercent=qtLine.Discount_Percent__c;
qtlWpr.discountPlan='';
}else if(qtLine.Discount_Amount__c != null){
qtlWpr.isPercent=false;
qtlWpr.minDiscount=0;
qtlWpr.maxDiscount=0;
qtlWpr.discountPercent=qtLine.Discount_Amount__c;
qtlWpr.discountPlan='';
}else{
qtlWpr.isPercent=true;
qtlWpr.minDiscount=0;
qtlWpr.maxDiscount=0;
qtlWpr.discountPercent=0;
qtlWpr.discountPlan='';
}
}
qtlWprList.add(qtlWpr);
//================Discount Plan end===============
}*/
            
            // Collect all tax Ids & product Ids first
            Set<Id> taxIds = new Set<Id>();
            //Set<Id> productIds = new Set<Id>();
            for (Quote_Line_Items__c qtLine : qtAndLine.qtLine) {
                if (qtLine.Tax__c != null) {
                    taxIds.add(qtLine.Tax__c);
                }
                if (qtLine.Product__c != null) {
                    productIds.add(qtLine.Product__c);
                }
            }
            
            Date todayDate = System.today();
            
            // Query all relevant taxes at once
            Map<Id, Tax__c> taxMap = new Map<Id, Tax__c>(
                [SELECT Id, Name, Active__c, Apply_Tax_On__c, City__c, Country__c, Effective_Date__c, Expiry_Date__c, 
                 Other_Tax_Rate__c, Other_Tax_Type__c, Postal_Code__c, Product__c, Province__c, Tax_Code__c, Tax_Rate__c, Type__c
                 FROM Tax__c
                 WHERE Id IN :taxIds
                 AND Effective_Date__c <= :todayDate
                 AND Expiry_Date__c >= :todayDate
                 AND Type__c = 'Sales Tax'
                 AND Active__c = true
                 WITH SECURITY_ENFORCED
                ]
            );
            
            // Query all Tier Discount Allocations once (bulk)
            List<Tier_Discount_Allocation__c> allTDAs = [
                SELECT Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, product__c, Tier__c, 
                Tier__r.Ceiling_Unit__c, Tier__r.Floor_Unit__c, Tier__r.Active__c, Discount_Plan__c, 
                Discount_Plan__r.Name, Discount_Plan__r.Active__c, Discount_Plan__r.Status__c, 
                Default__c, Discount_Plan__r.Default_Discount_Percentage__c, 
                Discount_Plan__r.Floor_Discount_Percentage__c, Discount_Plan__r.Ceiling_Discount_Percentage__c, 
                Discount_Plan__r.Default_Discount_Value__c, Discount_Plan__r.Floor_Discount_Value__c, 
                Discount_Plan__r.Ceiling_Discount_Value__c
                FROM Tier_Discount_Allocation__c
                WHERE Order_Profile__c = :profileId
                AND product__c IN :productIds
                AND Tier__r.Active__c = true
                AND Discount_Plan__r.Active__c = true
                AND Discount_Plan__r.Status__c = 'Manager Approved'
                AND Active__c = true
                WITH SECURITY_ENFORCED
                LIMIT 5000
            ];
            
            // Collect Discount Plan Ids from TDAs
            Set<Id> discountPlanIds = new Set<Id>();
            for (Tier_Discount_Allocation__c tda : allTDAs) {
                if (tda.Discount_Plan__c != null) {
                    discountPlanIds.add(tda.Discount_Plan__c);
                }
            }
            
            // Query all discount plans once
            Map<Id, Discount_Plan__c> discountMap = new Map<Id, Discount_Plan__c>(
                [SELECT Id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, 
                 Description__c, Floor_Discount_Percentage__c, Status__c, Default_Discount_Value__c, 
                 Ceiling_Discount_Value__c, Floor_Discount_Value__c
                 FROM Discount_Plan__c
                 WHERE Id IN :discountPlanIds
                 AND Active__c = true
                 WITH SECURITY_ENFORCED
                 LIMIT 5000
                ]
            );
            
            // Organize TDAs by Product for quick lookup
            Map<Id, List<Tier_Discount_Allocation__c>> productToTDAs = new Map<Id, List<Tier_Discount_Allocation__c>>();
            for (Tier_Discount_Allocation__c tda : allTDAs) {
                if (!productToTDAs.containsKey(tda.Product__c)) {
                    productToTDAs.put(tda.Product__c, new List<Tier_Discount_Allocation__c>());
                }
                productToTDAs.get(tda.Product__c).add(tda);
            }
            
            // Final loop (no SOQL inside)
            //List<qtLineWrapper> qtlWprList = new List<qtLineWrapper>();
            
            for (Quote_Line_Items__c qtLine : qtAndLine.qtLine) {
                qtLineWrapper qtlWpr = new qtLineWrapper();
                qtlWpr.qtLine = qtLine;
                
                // Tax mapping
                if (qtLine.Tax__c != null && taxMap.containsKey(qtLine.Tax__c)) {
                    qtlWpr.tax = taxMap.get(qtLine.Tax__c);
                    qtlWpr.taxId = qtLine.Tax__c;
                }
                
                if (qtLine.VAT_Amount__c != null) qtlWpr.vatAmount = qtLine.VAT_Amount__c.setScale(2);
                if (qtLine.Other_Tax__c != null) qtlWpr.otherTax = qtLine.Other_Tax__c.setScale(2);
                
                // ================= Discount Plan =================
                Decimal currentQuantity = qtLine.Quantity__c;
                
                // Filter TDAs for this product & quantity
                List<Tier_Discount_Allocation__c> filteredTDAs = new List<Tier_Discount_Allocation__c>();
                if (productToTDAs.containsKey(qtLine.Product__c)) {
                    for (Tier_Discount_Allocation__c tda : productToTDAs.get(qtLine.Product__c)) {
                        if (tda.Tier__r.Floor_Unit__c <= currentQuantity &&
                            tda.Tier__r.Ceiling_Unit__c >= currentQuantity) {
                                filteredTDAs.add(tda);
                            }
                    }
                }
                
                // Build discount plans list
                List<Discount_Plan__c> disPlansList = new List<Discount_Plan__c>();
                List<selectOptions1> disPlans = new List<selectOptions1>();
                disPlans.add(new selectOptions1('--None--', ''));
                
                for (Tier_Discount_Allocation__c tda : filteredTDAs) {
                    if (discountMap.containsKey(tda.Discount_Plan__c)) {
                        disPlansList.add(discountMap.get(tda.Discount_Plan__c));
                        disPlans.add(new selectOptions1(discountMap.get(tda.Discount_Plan__c).Name, tda.Discount_Plan__c));
                    }
                }
                
                qtlWpr.CurrentDiscounts = disPlans;
                qtlWpr.stock = (stockView.get(qtLine.Product__c) != null) ? stockView.get(qtLine.Product__c) : 0.00;
                qtlWpr.tierDists = filteredTDAs;
                qtlWpr.disPlans = disPlansList;
                
                // Handle discount values
                String discountPlan = qtLine.Discount_Plan__c;
                if (discountPlan != null) {
                    for (Discount_Plan__c disPlan : disPlansList) {
                        if (qtLine.Discount_Plan__c == disPlan.Id) {
                            if (disPlan.Default_Discount_Percentage__c != null) {
                                qtlWpr.isPercent = true;
                                qtlWpr.minDiscount = disPlan.Floor_Discount_Percentage__c;
                                qtlWpr.maxDiscount = disPlan.Ceiling_Discount_Percentage__c;
                                qtlWpr.discountPercent = qtLine.Discount_Percent__c;
                                qtlWpr.discountPlan = qtLine.Discount_Plan__c;
                            } else if (disPlan.Default_Discount_Value__c != null) {
                                qtlWpr.isPercent = false;
                                qtlWpr.minDiscount = disPlan.Floor_Discount_Value__c;
                                qtlWpr.maxDiscount = disPlan.Ceiling_Discount_Value__c;
                                qtlWpr.discountPercent = qtLine.Discount_Amount__c;
                                qtlWpr.discountPlan = qtLine.Discount_Plan__c;
                            }
                        }
                    }
                } else {
                    if (qtLine.Discount_Percent__c != null) {
                        qtlWpr.isPercent = true;
                        qtlWpr.discountPercent = qtLine.Discount_Percent__c;
                    } else if (qtLine.Discount_Amount__c != null) {
                        qtlWpr.isPercent = false;
                        qtlWpr.discountPercent = qtLine.Discount_Amount__c;
                    } else {
                        qtlWpr.isPercent = true;
                        qtlWpr.discountPercent = 0;
                    }
                    qtlWpr.minDiscount = 0;
                    qtlWpr.maxDiscount = 0;
                    qtlWpr.discountPlan = '';
                }

                    // Calculate Net and Gross amounts (handle subscription and non-subscription)
                    Decimal unitPrice = (qtlWpr.qtLine.List_Price__c != null) ? qtlWpr.qtLine.List_Price__c : 0;
                    Decimal qty = (qtlWpr.qtLine.Quantity__c != null) ? qtlWpr.qtLine.Quantity__c : 0;
                    Decimal monthDur = (qtlWpr.qtLine.Month_Duration__c != null) ? qtlWpr.qtLine.Month_Duration__c : 0;
                    Decimal durDays = (qtlWpr.qtLine.Duration_in_Days__c != null) ? qtlWpr.qtLine.Duration_in_Days__c : 0;

                    Decimal normalBaseAmount = unitPrice * qty;
                    Decimal subMonthAmount = unitPrice * qty * monthDur;
                    Decimal subDayAmount = unitPrice * qty * (durDays / 30);
                    Decimal subBaseAmount = subMonthAmount + subDayAmount;

                    Decimal discountAmt = 0;
                    if (qtlWpr.isPercent) {
                        if (qtlWpr.qtLine.Product__r != null && qtlWpr.qtLine.Product__r.Is_Subscribe__c == true) {
                            discountAmt = (subBaseAmount * qtlWpr.discountPercent) / 100;
                        } else {
                            discountAmt = (normalBaseAmount * qtlWpr.discountPercent) / 100;
                        }
                    } else {
                        discountAmt = qtlWpr.discountPercent * qty;
                    }

                    Boolean isSub = (qtlWpr.qtLine.Product__r != null && qtlWpr.qtLine.Product__r.Is_Subscribe__c == true);
                    Decimal netAmount = (isSub) ? (subBaseAmount - discountAmt) : (normalBaseAmount - discountAmt);
                    Decimal taxAmount = 0;
                    if (qtlWpr.vatAmount != null) taxAmount += qtlWpr.vatAmount;
                    if (qtlWpr.otherTax != null) taxAmount += qtlWpr.otherTax;
                    Decimal grossAmount = netAmount + taxAmount;

                    qtlWpr.subNetAmount = netAmount.setScale(2);
                    qtlWpr.subGrossAmount = grossAmount.setScale(2);

                    qtlWprList.add(qtlWpr);
            }
            // ================= End =================
            
            
            qtAndLine.qtLineWapper=qtlWprList;
            
        }catch(Exception e){ qtAndLine.errorMsg=e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return qtAndLine;
    }
    
    @AuraEnabled
    global static OrderWrapper getDiscountPlan(String customer,String qtProfile,String prodId, Integer quantity){
        OrderWrapper getDiscPlan=new OrderWrapper();
        try{
            Set<Id> productIds=new Set<Id>();
            productIds.add(prodId);
            String profileId='';
            Account acc=[Select Id,Name,Order_Profile__c from Account where Id =:customer WITH SECURITY_ENFORCED limit 1];
            if(acc.Order_Profile__c != null){
                Profiling__c profile=[Select Id,Name,Channel__c,Price_Book__c from Profiling__c where Id =:acc.Order_Profile__c WITH SECURITY_ENFORCED Limit 1];
                profileId=profile.Id;
            }else if(acc.Order_Profile__c == null){
                Profiling__c profile=[Select Id,Name,Channel__c,Price_Book__c,Company__c from Profiling__c where Id =:qtProfile WITH SECURITY_ENFORCED Limit 1];
                profileId=profile.Id;
            }
            
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
                    Discount_Plan__r.Active__c = true And Discount_Plan__r.Status__c='Manager Approved' AND
                    Active__c = true WITH SECURITY_ENFORCED limit 50
                   ];
            
            List <Id> discountPlanIds = new List <Id>();
            for(Tier_Discount_Allocation__c TDA: TDAS) {
                if(TDA.Discount_Plan__c != Null) discountPlanIds.add(TDA.Discount_Plan__c);
            }
            List <Discount_Plan__c> discounts = new List <Discount_Plan__c>();
            discounts = [Select id, Name, Active__c, Ceiling_Discount_Percentage__c, Default_Discount_Percentage__c, Description__c, Floor_Discount_Percentage__c,
                         Status__c, Default_Discount_Value__c, Ceiling_Discount_Value__c, Floor_Discount_Value__c
                         From Discount_Plan__c
                         Where Id In: discountPlanIds And
                         Active__c = True WITH SECURITY_ENFORCED limit 50
                        ];
            
            Map <Id,Discount_Plan__c> discountMap = new Map <Id,Discount_Plan__c>();
            for(Discount_Plan__c dis: discounts) {
                discountMap.put(dis.id, dis);
            }
            
            Map <Id,List <Discount_Plan__c>> discountPlans = new Map <Id,List <Discount_Plan__c>>();
            Map <Id,List <Tier_Discount_Allocation__c>> tierDiscAllocation = new Map <Id,List <Tier_Discount_Allocation__c>>();
            
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
            
            List<selectOptions1> options = new List<selectOptions1>();
            options.add(new selectOptions1('--None--',''));
            if(discountPlans.get(prodId) != null) {
                for(Discount_Plan__c dis: discountPlans.get(prodId)) {
                    options.add(new selectOptions1(dis.Name,dis.Id));
                }
            }
            qtLineWrapper qtlWpr=new qtLineWrapper();
            qtlWpr.CurrentDiscounts=options;
            qtlWpr.tierDists=(tierDiscAllocation.get(prodId)!= null)?tierDiscAllocation.get(prodId):new List<Tier_Discount_Allocation__c>();
            qtlWpr.disPlans=(discountPlans.get(prodId)!= null)?discountPlans.get(prodId):new List<Discount_Plan__c>();
            qtlWpr.discountPlan='';
            getDiscPlan.qtLineWapper.add(qtlWpr);
        }catch(Exception e){ getDiscPlan.errorMsg=e.getMessage() +' Line Number @ : '+ e.getLineNumber();}
        return getDiscPlan;
    }
    
    @AuraEnabled
    global static String checkOrdStatus(String quoteId){
        Quotes__c qt = [Select Id,Name,Customer__c,Order_Profile__c,Order_Created__c,Order__c,Contract__c from Quotes__c where Id =:quoteId WITH SECURITY_ENFORCED limit 1];
        system.debug('checkOrdStatus qt =='+qt);        
        if(qt.Order_Created__c && qt.Order__c != null){ 
            return 'Order Already created for Quote :'+qt.Name; 
        }else{ 
            return 'Order not created'; 
        }
    }
    
    @AuraEnabled
    global static String saveOrderAndLine(String listOfQuoteLine, String quoteId, String orderName, String customer, String contact, String orderProfile, String employee, String status, String orderType, String billToAdd, String shipToAdd, String description, String org) {
        system.debug('orgg-----'+org);    
        String orderId = '';
        try {
            // Step 1: Retrieve necessary information such as contact, profile, and quote.
            Contact con = [SELECT Id, Name, Email FROM Contact WHERE Id = :contact WITH SECURITY_ENFORCED LIMIT 1];
            Quotes__c qt = [SELECT Id, Name, Customer__c, Order_Profile__c, Order_Created__c, Contract__c,Total_Discount__c,Quote_Discount_Amount__c FROM Quotes__c WHERE Id = :quoteId WITH SECURITY_ENFORCED LIMIT 1];
            Profiling__c profile;
            
            if (qt.Order_Created__c) {
                return 'Order already created for Quote: ' + qt.Name;
            }
            
            if (qt.Customer__c != null) {
                Account acc = [SELECT Id, Name, Order_Profile__c FROM Account WHERE Id = :qt.Customer__c WITH SECURITY_ENFORCED LIMIT 1];
                profile = [SELECT Id, Name, Price_Book__c, Channel__c FROM Profiling__c WHERE Id = :acc.Order_Profile__c WITH SECURITY_ENFORCED LIMIT 1];
            } else {
                profile = [SELECT Id, Name, Price_Book__c, Channel__c FROM Profiling__c WHERE Id = :qt.Order_Profile__c WITH SECURITY_ENFORCED LIMIT 1];
            }
            
            // Step 2: Deserialize the list of Quote Line Items.
            List<qtLineWrapper> listOfQuoteLine1 = (List<qtLineWrapper>) JSON.deserialize(listOfQuoteLine, List<qtLineWrapper>.class);
            
            // Step 3: Create the Order.
            Order ord = new Order();
            ord.Name = orderName;
            ord.Active__c = true;
            ord.EffectiveDate = System.today();
            ord.Customer_Email__c = con.Email;
            ord.AccountId = customer;
            ord.Quote__c = qt.Id;
            ord.ContractId = qt.Contract__c;
            ord.Pricebook2Id = profile.Price_Book__c;
            ord.Channel__c = profile.Channel__c;
            ord.Contact__c = contact;
            ord.Order_Profile__c = orderProfile;
            ord.Employee__c = employee;
            ord.Status = status;
            ord.Type = orderType;
            ord.Bill_To_Address__c = billToAdd;
            ord.Ship_To_Address__c = shipToAdd;
            ord.Description = description;
            ord.Company__c = org;
            ord.Stage__c = 'Entered';
            
            //Added by Abuzar for the discount eligibility usecase on 7/07/2025
            // Set Order_Discount__c as the difference between Final_Discount_Amount__c and Total_Discount__c [agentforce discounts]
            if (qt.Quote_Discount_Amount__c != null && qt.Quote_Discount_Amount__c != 0 ) {
                ord.Order_Discount__c = qt.Quote_Discount_Amount__c - qt.Total_Discount__c;
            } 
            //else {
            //  ord.Order_Discount__c = 0; // Default to 0 if either field is null
            //}
            
            
            // Insert the new Order record.
            insert ord;
            orderId = ord.Id;
            
            
            //PricebookEntry pbe = [SELECT Id,Product2.Allow_Back_Orders__c,Product2.Available_Stock__c FROM PricebookEntry WHERE Pricebook2Id = :profile.Price_Book__c AND Product2Id IN : productIds WITH SECURITY_ENFORCED LIMIT 1];
            // Step 4: Create the list of OrderItems from the quote lines.
            List<OrderItem> orderItemList = new List<OrderItem>();
            for (qtLineWrapper qtLine : listOfQuoteLine1) {
                // Remove the checkSelected condition. We want to add all products.
                // Retrieve the PricebookEntryId based on the Product2Id and Pricebook2Id.
                //PricebookEntry pbe = [SELECT Id,Product2.Allow_Back_Orders__c,Product2.Available_Stock__c FROM PricebookEntry WHERE Pricebook2Id = :profile.Price_Book__c AND Product2Id = :qtLine.qtLine.Product__c WITH SECURITY_ENFORCED LIMIT 1];
                 
                // Create a new OrderItem and populate the required fields.
                OrderItem ordItem = new OrderItem();
                ordItem.OrderId = ord.Id;
                ordItem.PricebookEntryId = qtLine.qtLine.Pricebook_Entry_Id__c ;
                ordItem.Product2Id = qtLine.qtLine.Product__c;
                ordItem.UnitPrice = qtLine.qtLine.List_Price__c;
                ordItem.Quantity = qtLine.qtLine.Quantity__c;
                ordItem.ServiceDate = qtLine.qtLine.Start_Date__c != null ? qtLine.qtLine.Start_Date__c : System.today();
                ordItem.EndDate = qtLine.qtLine.End_Date__c;
                if(qtLine.qtLine.Product__r.Is_Subscribe__c == true){
                    ordItem.Is_Subscribe__c = qtLine.qtLine.Is_Subscribe__c;
                    ordItem.Month_Duration__c = qtLine.qtLine.Month_Duration__c;
                    ordItem.Duration_in_Days__c = qtLine.qtLine.Duration_in_Days__c; 
                }
                //ordItem.Is_Subscribe__c = qtLine.qtLine.Is_Subscribe__c;
                ordItem.Quote_Line_Items__c = qtLine.qtLine.Id;
                system.debug('qtLine.qtLine.Product__r.Track_Inventory__c--'+qtLine.qtLine.Product__r.Track_Inventory__c);
                ordItem.Inventory_Tracked__c = true;
                ordItem.Active__c = true;
                ordItem.Allocate_Stock__c = true;
                //ordItem.Is_Back_Order__c =  pbe.Product2.Allow_Back_Orders__c && (pbe.Product2.Available_Stock__c == null || pbe.Product2.Available_Stock__c <= 0) ? true : false;
                ordItem.Description = qtLine.qtLine.Description__c;
                
                // Added by Abuzar on 18-11-2025 for Calculate Sub_Total__c: default = ListPrice * Quantity
                Decimal listPrice = (qtLine.qtLine.List_Price__c != null) ? qtLine.qtLine.List_Price__c : 0;
                Decimal qty = (qtLine.qtLine.Quantity__c != null) ? qtLine.qtLine.Quantity__c : 0;
                Decimal monthDur = (qtLine.qtLine.Month_Duration__c != null) ? qtLine.qtLine.Month_Duration__c : 0;
                Decimal durDays = (qtLine.qtLine.Duration_in_Days__c != null) ? qtLine.qtLine.Duration_in_Days__c : 0;

                if (qtLine.qtLine.Product__r != null && qtLine.qtLine.Product__r.Is_Subscribe__c == true) {
                    ordItem.Sub_Total__c = (listPrice * qty * monthDur) + ((listPrice * qty * durDays) / 30);
                } else {
                    ordItem.Sub_Total__c = (listPrice * qty);
                }
                
                // Add additional fields as necessary (e.g., discount, tax).
                // Handle discount for subscription and non-subscription products
                if (qtLine.isPercent) {
                    ordItem.Discount_Percent__c = qtLine.discountPercent;
                    Decimal discount = 0;
                    
                    // For subscription products: calculate discount on months/days base
                    if (qtLine.qtLine.Product__r != null && qtLine.qtLine.Product__r.Is_Subscribe__c == true) {
                        Decimal monthlyBase = listPrice * qty * monthDur;
                        Decimal dailyBase = listPrice * qty * (durDays / 30);
                        Decimal subscriptionBase = monthlyBase + dailyBase;
                        discount = (subscriptionBase * qtLine.discountPercent) / 100;
                    } else {
                        // For non-subscription products: calculate discount on normal base
                        discount = ((listPrice * qty) * qtLine.discountPercent) / 100;
                    }
                    
                    ordItem.Discount_Amount__c = discount;
                } else {
                    // Flat discount amount
                    ordItem.Discount_Amount__c = qtLine.discountPercent;
                }
                if (qtLine.vatAmount > 0 || qtLine.otherTax > 0) {
                    ordItem.Tax__c = qtLine.taxId;
                    ordItem.VAT_Amount__c = qtLine.vatAmount;
                    ordItem.Other_Tax__c = qtLine.otherTax;
                }
                
                // Add to list of OrderItems to insert.
                orderItemList.add(ordItem);
            }
            
            // Insert all OrderItems at once.
            insert orderItemList;
            
            // Step 5: Update the quote to indicate an order has been created.
            qt.Order_Created__c = true;
            qt.Order__c = ord.Id;
            update qt;
            
        } catch (Exception e) {
            return e.getMessage() + ' Line Number @ : ' + e.getLineNumber();
        }
        
        return orderId;
    }
    
    global class qtLineWrapper{
        @AuraEnabled global Boolean checkSelected						{ get; set; }
        @AuraEnabled global Quote_Line_Items__c qtLine			{ get; set; }
        @AuraEnabled global List<Discount_Plan__c> disPlans				{ get; set; }
        @AuraEnabled global List<Tier_Discount_Allocation__c> tierDists	{ get; set; }
        @AuraEnabled global List<selectOptions1> CurrentDiscounts       { get; set; }
        @AuraEnabled global Decimal stock								{ get; set; }
        @AuraEnabled global Boolean isPercent							{ get; set; }
        @AuraEnabled global Decimal minDiscount							{ get; set; }
        @AuraEnabled global Decimal maxDiscount							{ get; set; }
        @AuraEnabled global Decimal discountPercent                    	{ get; set; }
        @AuraEnabled global String discountPlan							{ get; set; }
        @AuraEnabled global Tax__c tax							{ get; set; }
        @AuraEnabled global String taxId								{ get; set; }
        @AuraEnabled global Decimal vatAmount							{ get; set; }
        @AuraEnabled global Decimal otherTax							{ get; set; }
        @AuraEnabled global Decimal subNetAmount { get; set; }
        @AuraEnabled global Decimal subGrossAmount { get; set; }
        
        global qtLineWrapper(){
            checkSelected=false;
            qtLine=new Quote_Line_Items__c();
            disPlans=new List<Discount_Plan__c>();
            tierDists=new List<Tier_Discount_Allocation__c>();
            CurrentDiscounts=new List<selectOptions1>();
            stock=0;
            isPercent=true;
            minDiscount=0;
            maxDiscount=0;
            discountPercent=0;
            discountPlan='';
            tax=new Tax__c();
            taxId='';
            vatAmount=0;
            otherTax=0;
        }
    }
    
    global class OrderWrapper{
        @AuraEnabled global String errorMsg									{ get; set; }
        @AuraEnabled global Quotes__c quote							{ get; set; }
        @AuraEnabled global Employees__c emp							{ get; set; }
        @AuraEnabled global List<Quote_Line_Items__c> qtLine			{ get; set; }
        @AuraEnabled global List<String> status								{ get; set; }
        @AuraEnabled global List<String> type1								{ get; set; }
        @AuraEnabled global List<qtLineWrapper> qtLineWapper				{ get; set; }
        @AuraEnabled global Id recType								{ get; Set; }
        
        global OrderWrapper(){
            errorMsg = '';
            quote=new Quotes__c();
            emp=new Employees__c();
            qtLine=new List<Quote_Line_Items__c>();
            status=new List<String>();
            type1=new List<String>();
            qtLineWapper=new List<qtLineWrapper>();
        }
    }
    
    global class selectOptions1 {
        @AuraEnabled global String label     { get; set; }
        @AuraEnabled global String value     { get; set; }
        
        global selectOptions1(String lab, string val) {
            label = lab;
            value = val;
        }
    }
}