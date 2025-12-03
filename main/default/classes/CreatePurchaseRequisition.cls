global with sharing class CreatePurchaseRequisition {
    
    
    @AuraEnabled
    global String channel {get; set;}
    @AuraEnabled
    global Distribution_Channel__c distributionChannel {get; set;}
    @AuraEnabled
    global Account OrgAcc {get; set;}
    @AuraEnabled
    global Employees__c emplRequester {get; set;}
    @AuraEnabled
    global Business_Unit__c BusinessUnit {get; set;}
    @AuraEnabled
    global Contact DeliveryCon {get; set;}
    @AuraEnabled
    global Address__c DeliveryAdd {get; set;}
     @AuraEnabled
    global Date startDate {get; set;}
    @AuraEnabled
    global Boolean salesAccess {get; set;}
    @AuraEnabled
    global String SOID1 {get; set;} 
    
    /* @AuraEnabled
global static Order fetchdetails(String OrderId){
Order ord = [Select Id , Name,BillToContactId ,Bill_To_Address__c ,AccountId, Company__c ,Contact__c From Order where Id=:OrderId];
return ord;
}*/
    
  
 /*   
    @AuraEnabled
	global static CreatePurchaseRequisition fetchChannelandDC(String OId,String SOLIId){
        
        CreatePurchaseRequisition CPR = new CreatePurchaseRequisition();
        try{
            List<Employees__c> empList = [Select Id, Name, Employee_User__c, Channel__c ,Channel__r.Company__c from Employees__c
                                                where Employee_User__c=:UserInfo.getUserId()];
            if(empList.size()>0 && empList != null){
                CPR.emplRequester = empList[0];
                system.debug('Emp name '+ empList[0]);
                CPR.channel = empList[0].Channel__c;
                List<Distribution_Channel__c> dcList = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c from Distribution_Channel__c
                                                              where Channel__c=:empList[0].Channel__c and Active__c=true and Site__c != null order by Priority__c limit 1];
                if(dcList.size()>0 && dcList != null) CPR.distributionChannel = dcList[0];
                
            }
            
            if(OId != ''){
                Order ord = [Select Id , Name , Company__c , Bill_To_Address__c ,Contact__c,Organisation_Business_Unit__c from Order where Id=:OId Limit 1];
                Account acc = [Select Id , Name   from Account Where Id = :ord.Company__c limit 1];
                CPR.OrgAcc=acc;
                List<Contact> con = [Select Id , Name ,  AccountId ,Primary__c from Contact Where Id=:ord.Contact__c limit 1];
                CPR.DeliveryCon=con[0];
                List<Address__c> add = [Select Name ,  Contact__c ,Is_Billing_Address__c from Address__c Where Id=:ord.Bill_To_Address__c limit 1];
                CPR.DeliveryAdd=add[0];
            }
            else{
                Account acc = [Select Id , Name,Organisation_Business_Unit__c   from Account Where Id=:empList[0].Channel__r.Company__c  limit 1];
                CPR.OrgAcc = acc;
                Business_Unit__c bus = new Business_Unit__c();
                if(acc!= null) if(acc.Organisation_Business_Unit__c != null) bus =    [Select Id , Name   from Business_Unit__c Where id=:acc.Organisation_Business_Unit__c   limit 1];
                else bus =    [Select Id , Name   from Business_Unit__c Where Company__c=:empList[0].Channel__r.Company__c  limit 1];
                if(bus != null) CPR.BusinessUnit = bus;
                List<Contact> con = [Select Id , Name ,  AccountId ,Primary__c from Contact Where AccountId=:acc.Id limit 1];
                CPR.DeliveryCon=con[0];
                List<Address__c> add = [Select Name ,  Customer__c,Contact__c ,Is_Billing_Address__c from Address__c Where (Customer__c=:acc.Id AND Is_Billing_Address__c = TRUE) limit 1];
                CPR.DeliveryAdd=add[0];
            }
         
        }catch(Exception e){ /'Error : '+e.getLineNumber()+' Message : '+e.getMessage() / }
       System.debug('CPR ->'+CPR);
        return CPR;
    }*/
    
    
    @AuraEnabled
	global static CreatePurchaseRequisition fetchChannelandDC(String OId,String SOLIId){
    
            CreatePurchaseRequisition CPR = new CreatePurchaseRequisition();
            try{
                List<Employees__c> empList = [Select Id, Name, Employee_User__c, Channel__c ,Channel__r.Company__c from Employees__c
                                                    where Employee_User__c=:UserInfo.getUserId()];
                System.debug('Fetched Employees: ' + empList);
                
                
                if(empList.size()>0 && empList != null){
                    CPR.emplRequester = empList[0];
                    System.debug('CPR.emplRequester: ' + CPR.emplRequester);
        
                    CPR.channel = empList[0].Channel__c;
                    System.debug('CPR.channel: ' + CPR.channel);
        
                    List<Distribution_Channel__c> dcList = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c from Distribution_Channel__c
                                                                  where Channel__c=:empList[0].Channel__c and Active__c=true and Site__c != null order by Priority__c limit 1];
                    System.debug('Fetched Distribution Channels: ' + dcList);
                    
                    if(dcList.size()>0 && dcList != null) {
                        CPR.distributionChannel = dcList[0];
                        System.debug('CPR.distributionChannel: ' + CPR.distributionChannel);
                    }
                }
                
                if(OId != ''){
                    Order ord = [Select Id , Name , Company__c , Bill_To_Address__c ,Contact__c,Organisation_Business_Unit__c from Order where Id=:OId Limit 1];
                    System.debug('Fetched Order: ' + ord);
        
                    Account acc = [Select Id , Name   from Account Where Id = :ord.Company__c limit 1];
                    System.debug('Fetched Org Account: ' + acc);
                    CPR.OrgAcc=acc;
        
                    List<Contact> con = [Select Id , Name ,  AccountId ,Primary__c from Contact Where Id=:ord.Contact__c limit 1];
                    System.debug('Fetched Contact: ' + con);
                    CPR.DeliveryCon=con[0];
        
                    List<Address__c> add = [Select Name ,  Contact__c ,Is_Billing_Address__c from Address__c Where Id=:ord.Bill_To_Address__c limit 1];
                    System.debug('Fetched Address: ' + add);
                    CPR.DeliveryAdd=add[0];
                }
                else{
                    Account acc = [Select Id , Name,Organisation_Business_Unit__c   from Account Where Id=:empList[0].Channel__r.Company__c  limit 1];
                    System.debug('Fetched Fallback Account: ' + acc);
                    CPR.OrgAcc = acc;
        
                    Business_Unit__c bus = new Business_Unit__c();
                    if(acc!= null) 
                        if(acc.Organisation_Business_Unit__c != null) 
                            bus = [Select Id , Name from Business_Unit__c Where id=:acc.Organisation_Business_Unit__c limit 1];
                        else 
                            bus = [Select Id , Name from Business_Unit__c Where Company__c=:empList[0].Channel__r.Company__c limit 1];
                    System.debug('Fetched Business Unit: ' + bus);
        
                    if(bus != null) CPR.BusinessUnit = bus;
        
                    List<Contact> con = [Select Id , Name ,  AccountId ,Primary__c from Contact Where AccountId=:acc.Id limit 1];
                    System.debug('Fetched Contact (fallback): ' + con);
                    CPR.DeliveryCon=con[0];
        
                    List<Address__c> add = [Select Name ,  Customer__c,Contact__c ,Is_Billing_Address__c from Address__c Where (Customer__c=:acc.Id AND Is_Billing_Address__c = TRUE) limit 1];
                    System.debug('Fetched Address (fallback): ' + add);
                    CPR.DeliveryAdd=add[0];
                }
             
            } catch(Exception e){ 
                System.debug(' Error at line ' + e.getLineNumber() + ': ' + e.getMessage());
            }
        
            System.debug(' Final CPR Object: ' + CPR);
        	CPR.startDate = System.today();
            return CPR;
        }	

    
    
    
    
    @AuraEnabled
    global static WrapperClass getStatus(){
        WrapperClass wrap = new WrapperClass();
        List<String> options = new List<String>(); 
        Schema.DescribeFieldResult fieldResult = Requisition__c.Status__c.getDescribe(); 
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues(); 
        for (Schema.PicklistEntry f: ple) options.add(f.getLabel());  wrap.StatusList =options;
        if(Schema.sObjectType.Requisition__c.fields.Originating_Business_Unit__c.isAccessible()) wrap.isAccessible =true;
        return wrap;
    }
    
    @AuraEnabled
    global static Requisition__c save_PurchaseRequisition(String purchaseRequisition,String PRLI_List,String orderId){
        System.debug('purchaseRequisition '+purchaseRequisition);
        Requisition__c prequisitions = (Requisition__c) JSON.deserialize(purchaseRequisition, Requisition__c.class);
        if(Schema.sObjectType.Requisition__c.fields.Active__c.isCreateable() && Schema.sObjectType.Requisition__c.fields.Active__c.isUpdateable()) prequisitions.Active__c = true;
        if(Schema.sObjectType.Requisition__c.fields.Status__c.isCreateable() && Schema.sObjectType.Requisition__c.fields.Status__c.isUpdateable() && (prequisitions.Status__c == null || prequisitions.Status__c == '')) prequisitions.Status__c = 'In Process';
        if(orderId !=null && orderId !=''){ if(Schema.sObjectType.Requisition__c.fields.Order_S__c.isCreateable() && Schema.sObjectType.Requisition__c.fields.Order_S__c.isUpdateable()) prequisitions.Order_S__c = orderId;}
        if(prequisitions != null && Schema.sObjectType.Requisition__c.isCreateable() && Schema.sObjectType.Requisition__c.isUpdateable()){ upsert prequisitions;} else{ }
        
        List<Purchase_Requisition_Line_Items__c> pr_List = (List<Purchase_Requisition_Line_Items__c>) JSON.deserialize(PRLI_List, List<Purchase_Requisition_Line_Items__c>.class);
        for(Integer i = 0;  i<pr_List.size();i++){

            if(pr_List[i].Name != null && pr_List[i].Name.length() > 70){
                    pr_List[i].Name = pr_List[i].Name.substring(0, 70);
            }
            if(Schema.sObjectType.Purchase_Requisition_Line_Items__c.fields.Purchase_Requisition__c.isCreateable() || Schema.sObjectType.Purchase_Requisition_Line_Items__c.fields.Purchase_Requisition__c.isUpdateable()) pr_List[i].Purchase_Requisition__c = prequisitions.id;
        }
        if(pr_List.size()>0 && (Schema.sObjectType.Purchase_Requisition_Line_Items__c.isCreateable() || Schema.sObjectType.Purchase_Requisition_Line_Items__c.isUpdateable())){ upsert pr_List;} else{ }
        return prequisitions; 
    }
 
    
    
    @AuraEnabled
    global static POWrapper populateOrdItems(String orderId1, String SalesId)
    {
        POWrapper poWrap = new POWrapper();
        List<OrderItem> ordItemList=new List<OrderItem>();
       // List<Sales_Order_Line_Item__c> SOLIList = new  List<Sales_Order_Line_Item__c>();
        Decimal OrdQty = 0;
        List<Purchase_Requisition_Line_Items__c> prliList=new List<Purchase_Requisition_Line_Items__c>();
        try{
            if(orderId1 != null && orderId1 != ''){
                ordItemList = [Select Id, Product2Id, Product2.Name, Quantity, OrderId,UnitPrice,
                               Total_Price__c, PriceBook_Base_Price__c, Description, Base_Price__c from OrderItem where OrderId=:orderId1 and Is_Back_Order__c = true];
                for(OrderItem ordItem:ordItemList){
                    Purchase_Requisition_Line_Items__c prli=new Purchase_Requisition_Line_Items__c();
                    prli.Name=ordItem.Id;
                    prli.Product__c=ordItem.Product2Id;
                    prli.Product__r=new Product2(Id=ordItem.Product2Id,Name=ordItem.Product2.Name);
                    prli.Quantity__c = ordItem.Quantity;
                    // OrdQty = ordItem.Quantity;
                    prliList.add(prli);
                }
                list<Requisition__c> reqList=new list<Requisition__c>();  
                reqList=[SELECT Id, Name, Order_S__c, Active__c FROM Requisition__c
                         WHERE Order_S__c=:orderId1 AND Active__c=true];
                set<String> reqIds=new set<String>();
                
                for(Requisition__c s:reqList) reqIds.add(s.Id);
                
                list<Purchase_Requisition_Line_Items__c> ReqLIList=new list<Purchase_Requisition_Line_Items__c>();  
                ReqLIList=[SELECT Id, Name, Order_Product__c,Quantity__c,Product__c FROM Purchase_Requisition_Line_Items__c
                           WHERE Purchase_Requisition__c IN:reqIds AND Product__c!=Null]; //Sales_Order_Line_Item__c IN:SoliIds  
                // Map < Id, decimal > Prod_Quantity = new Map < Id, decimal > ();
                //for(Purchase_Requisition_Line_Items__c pr :ReqLIList ) Prod_Quantity.put(pr.Product__c,pr.Quantity__c);
                Set<Id> proIds=new Set<Id>();
                for(Purchase_Requisition_Line_Items__c pr :ReqLIList ){
                    proIds.add(pr.Product__c);
                }
                
                Map<String,Decimal> proQuanMap=new Map<String,Decimal>();
                for(Id pro:proIds){
                    Decimal quantity=0;
                    for(Purchase_Requisition_Line_Items__c pr :ReqLIList ){
                        if(pro == pr.Product__c){
                            quantity+=pr.Quantity__c;
                            
                        }
                    }
                    proQuanMap.put(pro,quantity);
                }
                Map<String,Decimal> OrdproQuanMap=new Map<String,Decimal>();
                for(Id prod:proIds){
                    Decimal quantityOrd=0;
                    for(OrderItem orp :ordItemList ){
                        if(prod == orp.Product2Id){
                            quantityOrd+=orp.Quantity;
                            
                        }
                    }
                    OrdproQuanMap.put(prod,quantityOrd);
                }
                Map<String,Decimal> ReqproQuanMap=new Map<String,Decimal>();
                for(String OrdMap : OrdproQuanMap.keySet()){
                    Decimal finalQty = 0 ;
                    for(String Req :  proQuanMap.keySet()){
                        if(OrdMap == Req) {
                            finalQty= OrdproQuanMap.get(OrdMap) - proQuanMap.get(Req);
                        }
                    } ReqproQuanMap.put(OrdMap,finalQty);  
                }
                for(Integer i=0; i<prliList.size(); i++){
                    for(String finalQ : ReqproQuanMap.keySet()){
                        if((finalQ == prliList[i].Product__c) && (ReqproQuanMap.get(finalQ) != prliList[i].Quantity__c) && (prliList[i].Quantity__c != 0)){
                            prliList[i].Quantity__c = ReqproQuanMap.get(finalQ);
                        }
                        if((finalQ == prliList[i].Product__c) && (prliList[i].Quantity__c == 0)) prliList.remove(i); 
                    }
                }
            }    
            
            if(prliList.size() > 0){
                poWrap.wPOLIs =  prliList;
                set <Id> siteIds = new set <Id>(); 
                set <Id> prodIds = new set <Id>(); 
                List<ProductStock> prodlst = new List<ProductStock>();
                for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
                List<Employees__c> empList = [Select Id, Name, Employee_User__c, Channel__c , Channel__r.Company__c from Employees__c
                                                    where Employee_User__c=:UserInfo.getUserId()];
                String DCId = '';
                if(empList.size()>0 && empList != null){
                    List<Distribution_Channel__c> dcList = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c from Distribution_Channel__c
                                                                  where Channel__c=:empList[0].Channel__c and Active__c=true and Site__c != null and Priority__c != null order by Priority__c ASC limit 1];
                    if(dcList.size() > 0) DCId = dcList[0].Id;
                }
                if(String.isNotEmpty(DCId)) {
                    for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
                    List<Distribution_Channel__c> DistributionChannels=[Select Id, Name, Active__c,  Channel__c, Site__c
                                                                        From Distribution_Channel__c
                                                                        Where 
                                                                        Id=:DCId And Active__c = true order by Priority__c ASC];
                    
                    for(Distribution_Channel__c DC: DistributionChannels) {
                        siteIds.add(DC.Site__c);
                    }
                    List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();
                    WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                    Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, BOM__c,No_of_Items_Requested__c,
                                                    Number_of_Items_Dispatched__c, No_of_Items_Sold__c,Number_of_Items_Awaiting_in_Stock__c
                                                    From Inventory_Stock__c
                                                    Where product__c In: prodIds And
                                                    Active__c = true And
                                                    Warehouse__c In: siteIds 
                                                   ];
                    for(Id ProductId : prodIds){
                        Decimal demand = 0.0;  Decimal myStock = 0.0;  Decimal Awaitingstock = 0.0;
                        ProductStock pr = new ProductStock();
                        
                        for(Inventory_Stock__c WIIS: WarehouseItemInventoryStocks) {
                            if(ProductId == WIIS.product__c){
                                myStock += WIIS.Number_of_Item_In_Stock__c;  
                                demand+=WIIS.No_of_Items_Requested__c;
                                Awaitingstock += WIIS.Number_of_Items_Awaiting_in_Stock__c;
                            }
                                
                        }
                        
                        pr.Product = ProductId;
                        pr.Demand = demand;
                        pr.Stock = myStock;
                        pr.AwaitingStocks=Awaitingstock;
                        prodlst.add(pr);
                    }
                }
                poWrap.productStocks = prodlst;   
            }
            else{ return null;}
        }catch(Exception e){ /*'Error at : '+e.getLineNumber()+'Message : '+e.getMessage() */}
        return poWrap; 
    }
      global class poliVenWrap{
        @AuraEnabled global Purchase_Requisition_Line_Items__c  poli {get;set;}
        @AuraEnabled global String  MOId {get;set;}
    }
 @AuraEnabled
global static poliVenWrap populateMrpline(String mrplineId) {
    return null ;
}
  @AuraEnabled
global static poliVenWrap populateMrplineNew(String mrplineId, Decimal quantityMultiplier) {
    poliVenWrap wrap = new poliVenWrap();
    Purchase_Requisition_Line_Items__c prli;
    if(mrplineId != null && mrplineId != '') {
        String mrpFields = UtilClass.selectStarFromSObject('MRP__c');
        utilClass.FLSCheck(mrpFields.split(','), 'MRP__c');
        String query = 'SELECT ' + String.escapeSingleQuotes(mrpFields) + ', MRP_Product__r.Name, MRP_Product__r.QuantityUnitOfMeasure, BOM_Line_Item__r.Unit_of_Measure__c, MO__r.Routing__r.Raw_Materials_Site__c FROM MRP__c WHERE Id = :mrplineId';
        List<MRP__c> MRPS = Database.query(query);
        if(MRPS.size() > 0) {
            wrap.MOId = MRPS[0].MO__c;
            // Get stock for the product
            Decimal stock = 0;
            String selectedSite = null;
            if(MRPS[0].MO__r != null && MRPS[0].MO__r.Routing__r != null && MRPS[0].MO__r.Routing__r.Raw_Materials_Site__c != null) {
                selectedSite = MRPS[0].MO__r.Routing__r.Raw_Materials_Site__c;
            }
            if(selectedSite != null && MRPS[0].MRP_Product__c != null) {
                List<AggregateResult> stockResults = [SELECT SUM(Number_of_Item_In_Stock__c) totalStock
                                                    FROM Inventory_Stock__c
                                                    WHERE Active__c = true
                                                    AND Warehouse__c = :selectedSite
                                                    AND Number_of_Item_In_Stock__c > 0
                                                    AND Product__c = :MRPS[0].MRP_Product__c];
                if(!stockResults.isEmpty() && stockResults[0].get('totalStock') != null) {
                    stock = (Decimal)stockResults[0].get('totalStock');
                }
            }
            // Apply UOM conversion (REVISED: Net shortage for partial; full required converted if sufficient stock)
            Decimal fulfilledAmount = MRPS[0].Fulfilled_Amount__c != null ? MRPS[0].Fulfilled_Amount__c : 0;
            Decimal multiplier = (quantityMultiplier != null ? quantityMultiplier : 1);  // base_to_req conversion factor
            Decimal requiredQty = MRPS[0].Total_Amount_Required__c != null ? MRPS[0].Total_Amount_Required__c : 0;
            Decimal stockInRequiredUOM = stock * multiplier;
            Decimal netShortageInReqUOM = requiredQty - fulfilledAmount - stockInRequiredUOM;
            Decimal finalQty = 0;
            if (netShortageInReqUOM > 0) {
                // Partial or no stock: Use net shortage converted
                finalQty = netShortageInReqUOM / multiplier;  // Convert shortage to base UOM for PR
                
                // Apply Minimum Ordering Quantity if applicable
                if(selectedSite != null) {
                    List<Reordering_Rule__c> ReorderingRules = [SELECT Id, MinimumOrderingQuantity__c
                                                               FROM Reordering_Rule__c
                                                               WHERE Product__c = :MRPS[0].MRP_Product__c
                                                               AND MinimumHoldingQuantity__c != null
                                                               AND MinimumOrderingQuantity__c != null
                                                               AND Warehouse__c = :selectedSite
                                                               ORDER BY CreatedDate DESC LIMIT 1];
                    if(!ReorderingRules.isEmpty() && ReorderingRules[0].MinimumOrderingQuantity__c != null && ReorderingRules[0].MinimumOrderingQuantity__c > finalQty) {
                        finalQty = ReorderingRules[0].MinimumOrderingQuantity__c;
                    }
                }
            } else {
                // Sufficient/more stock: Use full required qty converted (ignore stock for qty, but still populate line)
                finalQty = requiredQty / multiplier;
                System.debug('Sufficient stock for MRP Id: ' + mrplineId + '. Using full required qty with conversion: ' + finalQty);
            }
            
            // Always create Purchase_Requisition_Line_Items__c to populate MRP details
            prli = new Purchase_Requisition_Line_Items__c();
            prli.Name = MRPS[0].MRP_Product__r.Name;
            prli.Quantity__c = finalQty;
            prli.Product__c = MRPS[0].MRP_Product__c;
            prli.Product__r = new Product2(Id=MRPS[0].MRP_Product__c, Name=MRPS[0].MRP_Product__r.Name);
            prli.MRP__c = MRPS[0].Id;
            prli.Amount__c = MRPS[0].Total_Amount_Required__c;
            prli.Price__c = MRPS[0].Amount_Required__c;
            wrap.poli = prli;
            
            // Debug logging
            System.debug('MRP Id: ' + mrplineId);
            System.debug('Total Amount Required: ' + MRPS[0].Total_Amount_Required__c);
            System.debug('Fulfilled Amount: ' + fulfilledAmount);
            System.debug('Stock: ' + stock);
            System.debug('Quantity Multiplier: ' + quantityMultiplier);
            System.debug('Stock in Required UOM: ' + stockInRequiredUOM);
            System.debug('Net Shortage in Required UOM: ' + netShortageInReqUOM);
            System.debug('Calculated Quantity__c: ' + prli.Quantity__c);
        }
    }
    return wrap;
}
    
 /*   @AuraEnabled
    global static POWrapper populateMOlines(String MOId)
    {
        List<Purchase_Requisition_Line_Items__c> prlis = new List<Purchase_Requisition_Line_Items__c>();
        POWrapper poWrap = new POWrapper();
        if(MOId != null && MOId != ''){
            String MOFields = UtilClass.selectStarFromSObject('Manufacturing_Order__c');
            String AllMOFields = MOFields + ', Product__r.Serialise__c, Product__r.Lot_Tracked__c, Product__r.Name, Product__r.QuantityUnitOfMeasure, BOM__r.Name, Routing__r.Raw_Materials_Site__c, Manufacturing_Order__r.Name, Routing__r.Finished_Products_Site__c ';
            Manufacturing_Order__c MO = Database.query('SELECT '+String.escapeSingleQuotes(AllMOFields)+' FROM Manufacturing_Order__c WHERE Id = :MOId Limit 1');
            String selectedSite = MO.Routing__r.Raw_Materials_Site__c;
            
            String mrpFields = UtilClass.selectStarFromSObject('MRP__c');
            utilClass.FLSCheck(mrpFields.split(','),'MRP__c');
            String query = 'select ' + String.escapeSingleQuotes(mrpFields) + ', MRP_Product__r.Name from MRP__c where MO__c =: MOId ';
            List<MRP__c> MRPS = Database.query(query);
            
            Set<Id> proIds = new Set<Id>();
            Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
            for(MRP__c mrp : MRPS){
                if(mrp.MRP_Product__c != Null ) proIds.add(mrp.MRP_Product__c);
            }
            
            if(selectedSite != Null && selectedSite != ''){
                String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
                String AllWarehouseFields = WarehouseFields + ''; 
                List<Inventory_Stock__c> WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, '+
                                                                    +' StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c In: proIds And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Expiry_Date__c ASC'); 
                for(Id proId : proIds){
                    Decimal myStock = 0;
                    for(Inventory_Stock__c stock : WIISLists){
                        if(proId == stock.Product__c){
                            myStock += stock.Number_of_Item_In_Stock__c;
                        }
                    }
                    stockMap.put(proId,myStock);
                }
            }
            
            for(MRP__c mrp : MRPS){
                if(mrp.MRP_Product__c != Null && stockMap.containsKey(mrp.MRP_Product__c) && mrp.Fulfilled_Amount__c != mrp.Total_Amount_Required__c){
                    Decimal FA = (mrp.Fulfilled_Amount__c != Null)? mrp.Fulfilled_Amount__c : 0;
                    if(stockMap.get(mrp.MRP_Product__c) < (mrp.Total_Amount_Required__c - FA)){
                        Purchase_Requisition_Line_Items__c prli = new Purchase_Requisition_Line_Items__c();
                        prli.Name = mrp.MRP_Product__r.Name;
                        prli.Quantity__c = mrp.Total_Amount_Required__c - FA - stockMap.get(mrp.MRP_Product__c);
                        prli.Product__c = mrp.MRP_Product__c;
                        prli.Product__r = new Product2(Id=mrp.MRP_Product__c,Name=mrp.MRP_Product__r.Name);
                        prli.MRP__c = mrp.id;
                        prlis.add(prli);
                    }
                }
            }
        }  
        if(prlis.size() > 0){
            poWrap.wPOLIs =  prlis;
            set <Id> siteIds = new set <Id>(); 
            set <Id> prodIds = new set <Id>(); 
            List<ProductStock> prodlst = new List<ProductStock>();
            for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
            List<Employees__c> empList = [Select Id, Name, Employee_User__c, Channel__c , Channel__r.Company__c from Employees__c
                                                where Employee_User__c=:UserInfo.getUserId()];
            String DCId = '';
            if(empList.size()>0 && empList != null){
                List<Distribution_Channel__c> dcList = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c from Distribution_Channel__c
                                                              where Channel__c=:empList[0].Channel__c and Active__c=true and Site__c != null and Priority__c != null order by Priority__c ASC limit 1];
                if(dcList.size() > 0) DCId = dcList[0].Id;
            }
            if(String.isNotEmpty(DCId)) {
                for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
                List<Distribution_Channel__c> DistributionChannels=[Select Id, Name, Active__c,  Channel__c, Site__c
                                                                    From Distribution_Channel__c
                                                                    Where 
                                                                    Id=:DCId And Active__c = true order by Priority__c ASC];
                
                for(Distribution_Channel__c DC: DistributionChannels) {
                    siteIds.add(DC.Site__c);
                }
                List<Stock_Inward_Line_Item__c> SILIList=new List<Stock_Inward_Line_Item__c>();
                List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();
                WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, BOM__c,No_of_Items_Requested__c,
                                                Number_of_Items_Dispatched__c, No_of_Items_Sold__c,Number_of_Items_Awaiting_in_Stock__c
                                                From Inventory_Stock__c
                                                Where product__c In: prodIds And
                                                Active__c = true And
                                                Warehouse__c In: siteIds
                                               ];
                for(Id ProductId : prodIds){
                    Decimal demand = 0.0;  Decimal myStock = 0.0;  Decimal Awaitingstock = 0.0;
                    ProductStock pr = new ProductStock();
                    
                    for(Inventory_Stock__c WIIS: WarehouseItemInventoryStocks) {
                        if(ProductId == WIIS.product__c)
                            myStock += WIIS.Number_of_Item_In_Stock__c;  
                        demand+=WIIS.No_of_Items_Requested__c;
                        Awaitingstock += WIIS.Number_of_Items_Awaiting_in_Stock__c;
                    }
                    
                    pr.Product = ProductId;
                    pr.Demand = demand;
                    pr.Stock = myStock;
                    pr.AwaitingStocks=Awaitingstock;
                    prodlst.add(pr);
                }
            }
            poWrap.productStocks = prodlst;
        }
        return poWrap;
    }*/
  @AuraEnabled
global static POWrapper populateMOlines(String MOId) {
    List<Purchase_Requisition_Line_Items__c> prlis = new List<Purchase_Requisition_Line_Items__c>();
    POWrapper poWrap = new POWrapper();

    if(MOId != null && MOId != ''){
        String MOFields = UtilClass.selectStarFromSObject('Manufacturing_Order__c');
        String AllMOFields = MOFields + ', Product__r.Serialise__c, Product__r.Lot_Tracked__c, Product__r.Name, Product__r.QuantityUnitOfMeasure, BOM__r.Name, Routing__r.Raw_Materials_Site__c, Manufacturing_Order__r.Name, Routing__r.Finished_Products_Site__c ';
        Manufacturing_Order__c MO = Database.query('SELECT '+String.escapeSingleQuotes(AllMOFields)+' FROM Manufacturing_Order__c WHERE Id = :MOId Limit 1');
        String selectedSite = MO.Routing__r.Raw_Materials_Site__c;

        String mrpFields = UtilClass.selectStarFromSObject('MRP__c');
        utilClass.FLSCheck(mrpFields.split(','),'MRP__c');
        String query = 'select ' + String.escapeSingleQuotes(mrpFields) + ', MRP_Product__r.Name, MRP_Product__r.ProductCode, MRP_Product__r.Vendor_product_Name__c, BOM__r.Unit_of_Measure__c, MRP_Product__r.QuantityUnitOfMeasure, MRP_Product__r.Serialise__c, BOM_Line_Item__r.Unit_of_Measure__c from MRP__c where MO__c =: MOId ';
        List<MRP__c> MRPS = Database.query(query);

        // Get UOM conversion metadata
        List<UOM_Conversion__mdt> uom = [Select MasterLabel, QualifiedApiName, DeveloperName, From_UOM__c, From_Value__c, To_UOM__c, To_Value__c FROM UOM_Conversion__mdt limit 1000];

        Set<Id> proIds = new Set<Id>();
        Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
        for(MRP__c mrp : MRPS){
            if(mrp.MRP_Product__c != null) proIds.add(mrp.MRP_Product__c);
        }

        if(selectedSite != null && selectedSite != ''){
            String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
            String AllWarehouseFields = WarehouseFields + '';
            List<Inventory_Stock__c> WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, '+
                                                               ' StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c In: proIds And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Expiry_Date__c ASC');
            for(Id proId : proIds){
                Decimal myStock = 0;
                for(Inventory_Stock__c stock : WIISLists){
                    if(proId == stock.Product__c){
                        myStock += stock.Number_of_Item_In_Stock__c;
                    }
                }
                stockMap.put(proId, myStock);
            }
        }

        for(MRP__c mrp : MRPS){
            // UOM Conversion logic
            decimal weightMultiplier = 1;
            if(mrp.BOM__c != null && mrp.MRP_Product__c != null){
                String newUOM = mrp.MRP_Product__r.QuantityUnitOfMeasure;
                String oldUOM = mrp.BOM_Line_Item__r.Unit_of_Measure__c;
                System.debug('newUOM: ' + newUOM + ', oldUOM: ' + oldUOM);

                if(newUOM != '' && newUOM != null && oldUOM != '' && oldUOM != null && newUOM != oldUOM){
                    for(UOM_Conversion__mdt uomNew : uom){
                        if((uomNew.From_UOM__c == oldUOM && uomNew.To_UOM__c == newUOM) ||
                           (uomNew.From_UOM__c == newUOM && uomNew.To_UOM__c == oldUOM)){
                            if(uomNew.From_UOM__c == oldUOM && uomNew.To_UOM__c == newUOM){
                                weightMultiplier = uomNew.From_Value__c/uomNew.To_Value__c;
                                System.debug('Conversion applied: ' + oldUOM + ' to ' + newUOM + ', weightMultiplier: ' + weightMultiplier);
                            }
                            else if(uomNew.From_UOM__c == newUOM && uomNew.To_UOM__c == oldUOM){
                                weightMultiplier = uomNew.To_Value__c/uomNew.From_Value__c;
                                System.debug('Conversion applied: ' + newUOM + ' to ' + oldUOM + ', weightMultiplier: ' + weightMultiplier);
                            }
                        }
                    }
                }
            }
            system.debug('weightMultiplier: ' + weightMultiplier);

            if(mrp.MRP_Product__c != null && stockMap.containsKey(mrp.MRP_Product__c) && mrp.Fulfilled_Amount__c != (mrp.Total_Amount_Required__c/weightMultiplier)){
                Decimal FA = (mrp.Fulfilled_Amount__c != null) ? mrp.Fulfilled_Amount__c : 0;
                // Convert stock to the same UOM as Total_Amount_Required__c
                Decimal stockInRequiredUOM = stockMap.get(mrp.MRP_Product__c) * weightMultiplier; // e.g., 0.9 liters * 1000 = 900 milliliters
                if(stockInRequiredUOM < (mrp.Total_Amount_Required__c - FA)){
                    Purchase_Requisition_Line_Items__c prli = new Purchase_Requisition_Line_Items__c();
                    prli.Name = mrp.MRP_Product__r.Name;
                    System.debug('FA: ' + FA);
                    System.debug('stockMap.get(mrp.MRP_Product__c): ' + stockMap.get(mrp.MRP_Product__c));
                    System.debug('stockInRequiredUOM: ' + stockInRequiredUOM);
                    System.debug('mrp.Total_Amount_Required__c: ' + mrp.Total_Amount_Required__c);
                    Decimal curQuan = mrp.Total_Amount_Required__c - FA - stockInRequiredUOM; // e.g., 2100 - 0 - 900 = 1200
                    prli.Quantity__c = (mrp.MRP_Product__r.Serialise__c) ? 
                        Math.round(curQuan/weightMultiplier) : 
                        (curQuan/weightMultiplier).setScale(3);
                    prli.Product__c = mrp.MRP_Product__c;
                    prli.Product__r = new Product2(Id=mrp.MRP_Product__c, Name=mrp.MRP_Product__r.Name, ProductCode=mrp.MRP_Product__r.ProductCode);
                    prli.MRP__c = mrp.id;
                    prlis.add(prli);
                }
            }
        }
    }

    if(prlis.size() > 0){
        poWrap.wPOLIs = prlis;
        set<Id> siteIds = new set<Id>();
        set<Id> prodIds = new set<Id>();
        List<ProductStock> prodlst = new List<ProductStock>();
        for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
        List<Employees__c> empList = [Select Id, Name, Employee_User__c, Channel__c, Channel__r.Company__c from Employees__c
                                     where Employee_User__c=:UserInfo.getUserId()];
        String DCId = '';
        if(empList.size()>0 && empList != null){
            List<Distribution_Channel__c> dcList = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c from Distribution_Channel__c
                                                  where Channel__c=:empList[0].Channel__c and Active__c=true and Site__c != null and Priority__c != null order by Priority__c ASC limit 1];
            if(dcList.size() > 0) DCId = dcList[0].Id;
        }
        if(String.isNotEmpty(DCId)) {
            for(Purchase_Requisition_Line_Items__c pp : poWrap.wPOLIs) prodIds.add(pp.Product__c);
            List<Distribution_Channel__c> DistributionChannels=[Select Id, Name, Active__c, Channel__c, Site__c
                                                              From Distribution_Channel__c
                                                              Where Id=:DCId And Active__c = true order by Priority__c ASC];
            for(Distribution_Channel__c DC: DistributionChannels) {
                siteIds.add(DC.Site__c);
            }
            List<Stock_Inward_Line_Item__c> SILIList = new List<Stock_Inward_Line_Item__c>();
            List<Inventory_Stock__c> WarehouseItemInventoryStocks = new List<Inventory_Stock__c>();
            WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                           Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, BOM__c, No_of_Items_Requested__c,
                                           Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Number_of_Items_Awaiting_in_Stock__c
                                           From Inventory_Stock__c
                                           Where product__c In: prodIds And Active__c = true And Warehouse__c In: siteIds];
            for(Id ProductId : prodIds){
                Decimal demand = 0.0;
                Decimal myStock = 0.0;
                Decimal Awaitingstock = 0.0;
                ProductStock pr = new ProductStock();
                for(Inventory_Stock__c WIIS: WarehouseItemInventoryStocks) {
                    if(ProductId == WIIS.product__c) {
                        myStock += WIIS.Number_of_Item_In_Stock__c;
                        demand += WIIS.No_of_Items_Requested__c;
                        Awaitingstock += WIIS.Number_of_Items_Awaiting_in_Stock__c;
                    }
                }
                pr.Product = ProductId;
                pr.Demand = demand;
                pr.Stock = myStock;
                pr.AwaitingStocks = Awaitingstock;
                prodlst.add(pr);
            }
        }
        poWrap.productStocks = prodlst;
    }
    return poWrap;
}
    
    @AuraEnabled
    global static List<Purchase_Requisition_Line_Items__c> populateWOlines(String WOId)
    {
        List<Purchase_Requisition_Line_Items__c> prlis = new List<Purchase_Requisition_Line_Items__c>();
        if(WOId != null && WOId != ''){
            String WOFields = UtilClass.selectStarFromSObject('WO__c');
            String AllWOFields = WOFields + ', Product__r.Serialise__c, Product__r.Lot_Tracked__c, Product__r.Name, Product__r.QuantityUnitOfMeasure, BOM__r.Name, Routing__r.Raw_Materials_Site__c, Routing__r.Finished_Products_Site__c ';
            WO__c WO = Database.query('SELECT '+String.escapeSingleQuotes(AllWOFields)+' FROM WO__c WHERE Id = :WOId Limit 1');
            String selectedSite = WO.Routing__r.Raw_Materials_Site__c;
            
            
            String mrpFields = UtilClass.selectStarFromSObject('MRP__c');
            utilClass.FLSCheck(mrpFields.split(','),'MRP__c');
            String query = 'select ' + String.escapeSingleQuotes(mrpFields) + ', MRP_Product__r.Name from MRP__c where Work_Order__c =: WOId ';
            List<MRP__c> MRPS = Database.query(query);
            
            Set<Id> proIds = new Set<Id>();
            Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
            for(MRP__c mrp : MRPS){
                if(mrp.MRP_Product__c != Null ) proIds.add(mrp.MRP_Product__c);
            }
            
            if(selectedSite != Null && selectedSite != ''){
                String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
                String AllWarehouseFields = WarehouseFields + ''; 
                List<Inventory_Stock__c> WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, '+
                                                                    +' StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c In: proIds And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Expiry_Date__c ASC'); 
                for(Id proId : proIds){
                    Decimal myStock = 0;
                    for(Inventory_Stock__c stock : WIISLists){
                        if(proId == stock.Product__c){
                            myStock += stock.Number_of_Item_In_Stock__c;
                        }
                    }
                    stockMap.put(proId,myStock);
                }
            }
            
            for(MRP__c mrp : MRPS){
                if(mrp.MRP_Product__c != Null && stockMap.containsKey(mrp.MRP_Product__c) && mrp.Fulfilled_Amount__c != mrp.Total_Amount_Required__c){
                    Decimal FA = (mrp.Fulfilled_Amount__c != Null)? mrp.Fulfilled_Amount__c : 0;
                    if(stockMap.get(mrp.MRP_Product__c) < (mrp.Total_Amount_Required__c - FA)){
                        Purchase_Requisition_Line_Items__c prli = new Purchase_Requisition_Line_Items__c();
                        prli.Name = mrp.MRP_Product__r.Name;
                        prli.Quantity__c = mrp.Total_Amount_Required__c - FA - stockMap.get(mrp.MRP_Product__c);
                        prli.Product__c = mrp.MRP_Product__c;
                        prli.Product__r = new Product2(Id=mrp.MRP_Product__c,Name=mrp.MRP_Product__r.Name);
                        prli.MRP__c = mrp.id;
                        prlis.add(prli);
                    }
                }
            }
        }    
        return prlis;
    }
    @AuraEnabled
    global Static list<PRWrap> getExistingPReq(String SOId,String OrderId){ 
        list<PRWrap> ReqList=new list<PRWrap>(); 
        /*'getLOLIExisting SOId==>'+SOId+'      getLOLIExisting OrderId==>'+OrderId */
        if(String.isNotEmpty(SOId)){  
            list<Requisition__c>  RList=[SELECT Id, Name, Order_S__c ,Order_S__r.Name ,Active__c,Status__c, Delivery_Contact__c, Delivery_Contact__r.Name, Delivery_Address__c, Delivery_Address__r.Name
                                               FROM Requisition__c 
                                               WHERE Order_S__c=:OrderId AND Active__c=true Order By createdDate ASC];
            
            
            for(Requisition__c log:RList) {  PRWrap w=new PRWrap();  w.Id=log.Id; w.Name=log.Name;  w.Order=log.Order_S__r.Name;  w.Contact=log.Delivery_Contact__r.Name;  w.ToAddress=log.Delivery_Address__r.Name; w.Status=log.Status__c;  ReqList.add(w); 
                                                }
            return ReqList;   
        }
        else if(String.isNotEmpty(OrderId)){
            list<Requisition__c>  RList=[SELECT Id, Name, Active__c,Order_S__c,Order_S__r.OrderNumber, Delivery_Contact__c, Delivery_Contact__r.Name, Delivery_Address__c, Delivery_Address__r.Name, Status__c
                                               FROM Requisition__c 
                                               WHERE Order_S__c=:OrderId AND Active__c=true Order By createdDate ASC];
            
            
            for(Requisition__c log:RList) {  PRWrap w=new PRWrap();  w.Id=log.Id; w.Name=log.Name;  w.Order=log.Order_S__r.OrderNumber;  w.Contact=log.Delivery_Contact__r.Name;  w.ToAddress=log.Delivery_Address__r.Name; w.Status=log.Status__c;  ReqList.add(w); 
                                                 
                                                }
            return ReqList;  
            
        } else return null;                                                           
        
    } 
    @AuraEnabled
    global Static ProductStock getstocks(String DCId,String ProductId){
        ProductStock pr = new ProductStock();
        Decimal myStock = 0.0;
        Decimal demand=0.0;
        Decimal Awaitingstock = 0.0;
        List <Id> siteIds = new List <Id>(); 
        if(String.isNotEmpty(DCId) && String.isNotEmpty(ProductId)) {
            List<Distribution_Channel__c> DistributionChannels=[Select Id, Name, Active__c,  Channel__c, Site__c
                                                                From Distribution_Channel__c
                                                                Where 
                                                                Id=:DCId And Active__c = true order by Priority__c ASC];
            
            for(Distribution_Channel__c DC: DistributionChannels) {
                siteIds.add(DC.Site__c);
            }
        }
        
        
        List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();
        WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                        Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, BOM__c,No_of_Items_Requested__c,
                                        Number_of_Items_Dispatched__c, No_of_Items_Sold__c,Number_of_Items_Awaiting_in_Stock__c
                                        From Inventory_Stock__c
                                        Where product__c =: ProductId And
                                        Active__c = true And
                                        Warehouse__c In: siteIds 
                                       ];
        
        for(Inventory_Stock__c WIIS: WarehouseItemInventoryStocks) {
            if(ProductId == WIIS.product__c){
                myStock += WIIS.Number_of_Item_In_Stock__c; 
                demand+=WIIS.No_of_Items_Requested__c;
                Awaitingstock += WIIS.Number_of_Items_Awaiting_in_Stock__c;
            }
            
        }
        Product2 des=fetchProductDesc(ProductId);
        
        pr.Product = ProductId;
        pr.Demand = demand;
        pr.Stock = myStock;
        pr.AwaitingStocks=Awaitingstock;
        pr.description=des.Description;
        return pr;
        
    }
    global class ProductStock{
        @AuraEnabled global Decimal Demand                                  {get; set;}
        @AuraEnabled global Decimal Stock                                   {get; set;}
        @AuraEnabled global Decimal AwaitingStocks                          {get; set;}
        @AuraEnabled global String Product                                  {get; set;}
        @AuraEnabled global String description                                  {get; set;}
        global ProductStock(){
            Demand = 0.0;Stock = 0.0; AwaitingStocks = 0.0;
            Product = '';description='';
        }
        
    }
    global class WrapperClass{
        @AuraEnabled
        global List<String> StatusList {get;set;} 
        @AuraEnabled
        global Boolean isAccessible =false;
    }
    
    global class PRWrap{
        @AuraEnabled
        global String Id {get;set;} 
        @AuraEnabled
        global String Name {get;set;} 
        @AuraEnabled
        global String Order {get;set;} 
        @AuraEnabled
        global String Contact {get;set;} 
        @AuraEnabled
        global String ToAddress {get;set;} 
        @AuraEnabled
        global String  Status {get;set;} 
        
        
        global PRWrap(){
            Name=Order=Contact=ToAddress=Status='';    
        }    
        
    }
    
    @AuraEnabled
    global static Product2 fetchProductDesc(String productId){  
        if(String.isNotEmpty(productId)) return [Select Id, Name,Description, Vendor_Supplier_Description__c from Product2 where Id =: productId Limit 1];
        else return null;
    }
    global class POWrapper{
        @AuraEnabled global List<Purchase_Requisition_Line_Items__c> wPOLIs               { get; set; }
        @AuraEnabled global List<ProductStock> productStocks                        { get; set; }
        
    }
    
}