// issue : logistic line item updating twice so commented and added the new fix by matheen in the getcreatelogistic
// Stock outward line item is not getting created against the LOL : no changes done in apex , only FLS related changes are done (BUSHRA)
// Kit Process - Exception error if no qty in BOMs, need standard error message : added a validation in getordItemList ,added a validation  ay line 421
global with sharing class SalesOrderToLogistic{

     @AuraEnabled global String fromContact                             {get;set;}
    @AuraEnabled
    global Logistic__c Logistic{ get; set; }

    @AuraEnabled
    global Logistic_Line_Item__c LogisticLI{ get; set; }

    @AuraEnabled
    global list<SelectOption> LogisticTypeList{ get; set; }

    @AuraEnabled
    global list<Purchase_Line_Items__c> POList{ get; set; }

    @AuraEnabled
    global list<OrderItem> OrdList{ get; set; }

    @AuraEnabled
    global Order Ord{ get; set; }

    @AuraEnabled
    global PO__c PO{ get; set; }

    @AuraEnabled public List <bomwrapper>   BOMS   {get;set;}

    @AuraEnabled
    global String DistributeChannelId{ get; set; }

    @AuraEnabled
    global Boolean isReadyToPickPack{ get; set; }

    @AuraEnabled
    global Boolean showReadyToShip{ get; set; }

    @AuraEnabled
    global Boolean allowEdit{ get; set; }

    @AuraEnabled
    global Boolean dontallowChannelRemove{ get; set; }

    @AuraEnabled
    global Boolean showShipmentDetails{ get; set; }

    @AuraEnabled global Boolean   ShowReturnShipSection   {get;set;}

    global SalesOrderToLogistic(){
        LogisticTypeList = new list<SelectOption>();
        OrdList = new list<OrderItem>();
        isReadyToPickPack = false;
        showReadyToShip = false;
        POList = new list<Purchase_Line_Items__c>();
        PO = new PO__c();
        BOMS  = new List <bomwrapper>();
        allowEdit = true;
        dontallowChannelRemove = true;
        showShipmentDetails =ShowReturnShipSection= false;
    }

    global class SelectOption{
        @AuraEnabled
        global String value{ get; set; }

        @AuraEnabled
        global String label{ get; set; }

        global SelectOption(String value, String label){
            this.value = value;
            this.label = label;
        }

    }

    @AuraEnabled
    global Static SalesOrderToLogistic getInstances(){
        SalesOrderToLogistic so = new SalesOrderToLogistic();
        so.Logistic = new Logistic__c();
        so.LogisticLI = new Logistic_Line_Item__c();

        list<SelectOption> tolList = new list<SelectOption>();
        tolList.add(new SelectOption('', '-- None --'));
        List<Schema.PicklistEntry> tolValues = Schema.sObjectType.Logistic__c.Fields.Type__c.getPickListValues();
        for (Schema.PicklistEntry a : tolValues)
            tolList.add(new SelectOption(a.getValue(), a.getLabel()));
        so.LogisticTypeList = tolList;

        Functionality_Control__c FC = new Functionality_Control__c();
        FC = Functionality_Control__c.getValues(userInfo.getuserid());
        if (FC == null){
            FC = Functionality_Control__c.getValues(userInfo.getProfileId());
            if (FC == null)
                FC = Functionality_Control__c.getInstance();
        }
        if (FC != null){
            so.showReadyToShip = FC.showReadyToShipMLog__c;
            so.allowEdit = FC.Allow_Edit_of_Logistic_and_it_s_item_Nam__c;
            so.dontallowChannelRemove = FC.Restrict_Selected_Channel__c;
            so.showShipmentDetails = FC.Show_Ship_Details_in_Orders_to_Logistic__c;
            so.ShowReturnShipSection = FC.ShowReturnShipSection__c;
        }
        return so;
    }

    @AuraEnabled
    global static SalesOrderToLogistic getPOItemList(String POId){
        SalesOrderToLogistic PO = new SalesOrderToLogistic();
        if (String.isNotEmpty(POId)){
            PO__c POrd = [Select Id, Name, Channel__c, Distribution_Channel__c, Vendor__c, Vendor_Contact__c, Shipment_Type__c, Shipment_Preference_Speed__c,Company__c
                          from PO__c
                          Where Id = :POId
                          WITH SECURITY_ENFORCED
                          limit 100];
            PO.PO = Pord;

            List<Purchase_Line_Items__c> POItemList = [SELECT Id, Name, Product__c, Product__r.Name, Quantity__c, Unit_Price__c, Tax__c, Site__c, Active__c, Picked_Quantity__c, Packed_Quantity__c, Logistic_Quantity__c, Purchase_Orders__r.Name, Purchase_Orders__r.Ready_To_Pick_Pack__c, Purchase_Orders__r.Ready_To_Receive__c
                                                       FROM Purchase_Line_Items__c
                                                       WHERE Purchase_Orders__c = :POId AND Product__c != Null
                                                       WITH SECURITY_ENFORCED
                                                       limit 100];
            //Set<String> POLIIds=new Set<String>();
            List<Purchase_Line_Items__c> POItmToReturn = new List<Purchase_Line_Items__c>();
            for (Purchase_Line_Items__c POLI : POItemList){
                //POLIIds.add(POLI.Id);
                if (POLI.Quantity__c != POLI.Logistic_Quantity__c){
                    if (POLI.Logistic_Quantity__c == null)
                        POLI.Logistic_Quantity__c = 0;
                    POItmToReturn.add(POLI);
                }
            }
            PO.POList = POItmToReturn;

        }
        return PO;
    }

   /* @AuraEnabled
    global Static SalesOrderToLogistic getordItemList(String orderId){
         //, String DistributeChannelId
        SalesOrderToLogistic so = new SalesOrderToLogistic();
        try{
            if (String.isNotEmpty(orderId)){
                list<OrderItem> SoliList = new list<OrderItem>();
                SoliList = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Quantity, Base_Price__c, VAT_Amount__c, Discount_Amount__c, OrderItemNumber, OrderId, Order.Name, Order.Ready_To_Pick_Pack__c, Site__c, Active__c, Logistic_Quantity__c, Picked_Quantity__c, Packed_Quantity__c, Shipped_Quantity__c, Reserved_Quantity__c, Remaining_Quantity__c
                            FROM OrderItem
                            WHERE OrderId = :orderId AND Product2Id != Null AND Product2.Track_Inventory__c = true
                            WITH SECURITY_ENFORCED
                            limit 100];

                set<String> SoliIds = new set<String>();
                for (OrderItem s : SoliList)
                    SoliIds.add(s.Id);
                for (Integer i = 0; i < SoliList.size(); i++)
                    SoliList[i].Active__c = false;
                list<Logistic__c> LogList = new list<Logistic__c>();
                LogList = [SELECT Id, Name, Order_S__c, Active__c
                           FROM Logistic__c
                           WHERE Order_S__c = :orderId AND Active__c = true
                           WITH SECURITY_ENFORCED
                           limit 100];

                set<String> LogIds = new set<String>();
                for (Logistic__c s : LogList)
                    LogIds.add(s.Id);
                list<Logistic_Line_Item__c> LLIList = new list<Logistic_Line_Item__c>();
                LLIList = [SELECT Id, Name, Order_Product__c
                           FROM Logistic_Line_Item__c
                           WHERE Logistic__c IN:LogIds AND Product__c != Null
                           WITH SECURITY_ENFORCED
                           limit 100];

                list<OrderItem> SoliListFinal = new list<OrderItem>();
                for (Integer i = 0; i < SoliList.size(); i++){
                    if (SoliList[i].Logistic_Quantity__c == null)
                        SoliList[i].Logistic_Quantity__c = 0;
                    if (SoliList[i].Quantity == null)
                        SoliList[i].Quantity = 0;
                    if (SoliList[i].Remaining_Quantity__c == null)
                        SoliList[i].Remaining_Quantity__c = 0;
                    if (SoliList[i].Logistic_Quantity__c < SoliList[i].Quantity && SoliList[i].Order.Ready_To_Pick_Pack__c == false)
                        SoliList[i].Active__c = true;
                    SoliListFinal.add(SoliList[i]);
                }

                List<String> productIds = new List<String>();
                for (OrderItem so_li : SoliListFinal){
                    productIds.add(so_li.Product2Id);
                }

                so.Ord = [SELECT Id, Name, AccountId, Contact__c, Ship_To_Address__c, Channel__c, Shipment_Type__c, Ready_To_Pick_Pack__c, Shipment_Preference_Speed__c, Description, Bill_To_Address__c
                          FROM Order
                          WHERE Id = :orderId
                          WITH SECURITY_ENFORCED
                          limit 1];

                Distribution_Channel__c dc = new Distribution_Channel__c();
                if (so.Ord.Channel__c != null){
                    dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                          FROM Distribution_Channel__c
                          WHERE Channel__c = :so.Ord.Channel__c AND Site__c != null
                          WITH SECURITY_ENFORCED
                          order by Priority__c
                          LIMIT 1];
                }

                if (dc.Id != null){
                    so.DistributeChannelId = dc.Id;

                    Map<Id, List<Inventory_Stock__c>> ProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                    for (Inventory_Stock__c WarehouseItemInventoryStocks : [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                            From Inventory_Stock__c
                                                                            Where product__c IN:productIds And Active__c = true And Number_of_Item_In_Stock__c > 0 And Warehouse__c = :dc.Site__c
                                                                            WITH SECURITY_ENFORCED
                                                                            limit 100]){
                        if (ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)){
                            ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                        } else{
                            List<Inventory_Stock__c> WarehouseItemInventoryStockLists = new List<Inventory_Stock__c>();
                            WarehouseItemInventoryStockLists.add(WarehouseItemInventoryStocks);
                            ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, WarehouseItemInventoryStockLists);
                        }
                    }

                    for (Integer i = 0; i < SoliListFinal.size(); i++){
                        Decimal proStockCount = 0;
                        if (ProductMap2Stock != null && ProductMap2Stock.keyset().contains(SoliListFinal[i].Product2Id)){
                            for (Inventory_Stock__c IS : ProductMap2Stock.get(SoliListFinal[i].Product2Id)){
                                proStockCount += IS.Number_of_Item_In_Stock__c;
                            }
                        }
                        SoliListFinal[i].Reserved_Quantity__c = proStockCount;
                        SoliListFinal[i].Remaining_Quantity__c = SoliListFinal[i].Quantity - SoliListFinal[i].Logistic_Quantity__c;


                        //if(SoliListFinal[i].Reserved_Quantity__c<=0) SoliListFinal[i].Active__c=false;

                    }
                }


                for (Integer i = 0; i < SoliListFinal.size(); i++)
                    if (SoliListFinal[i].Quantity - SoliListFinal[i].Logistic_Quantity__c <= 0)
                        SoliListFinal[i].Active__c = false;
                    so.OrdList = SoliListFinal;
                if (so.Ord.Id != null){
                    so.isReadyToPickPack = so.Ord.Ready_To_Pick_Pack__c;
                }
                return so;
            } else{
                so.OrdList = new list<OrderItem>();
                so.Ord = new Order();
                so.DistributeChannelId = '';
                so.Logistic = new Logistic__c();
                return so;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + 'at line~>' + e.getStackTraceString());
        }
    }*/
     /* @AuraEnabled
    global Static SalesOrderToLogistic getordItemList(String orderId){ //, String DistributeChannelId
        SalesOrderToLogistic so=new SalesOrderToLogistic();
        try{
            if(String.isNotEmpty(orderId)){
                list<OrderItem> SoliList=new list<OrderItem>();
                SoliList=[SELECT Id , Product2Id, Product2.Name,UnitPrice,Product2.Track_Inventory__c,Product2.Is_Kit__c, Quantity, Base_Price__c, VAT_Amount__c, Discount_Amount__c ,BOM__c,
                          OrderItemNumber,OrderId,Order.Name, Order.Ready_To_Pick_Pack__c, Site__c, Active__c, Logistic_Quantity__c,Inventory_Tracked__c,Is_Kit__c,PriceBookId__c,
                          Picked_Quantity__c, Packed_Quantity__c, Shipped_Quantity__c, Reserved_Quantity__c,Remaining_Quantity__c
                          FROM OrderItem WHERE OrderId=:orderId AND Product2Id != Null AND (Product2.Track_Inventory__c=true OR Product2.Is_Kit__c=true)]; //  AND Site__c=:dc.Site__c   //Site__c='a2B1o000001pkxzEAA'

                list<OrderItem> trackinventoryProds =new list<OrderItem>();
                list<OrderItem> nontrackinventoryProds =new list<OrderItem>();

                set<String> SoliIds=new set<String>();
                for(OrderItem s:SoliList) SoliIds.add(s.Id);

                for(Integer i=0; i<SoliList.size(); i++) SoliList[i].Active__c=false;

                list<Logistic__c> LogList=new list<Logistic__c>();
                LogList=[SELECT Id, Name, Order_S__c, Active__c FROM Logistic__c WHERE Order_S__c=:orderId AND Active__c=true];

                set<String> LogIds=new set<String>();
                for(Logistic__c s:LogList) LogIds.add(s.Id);
                list<Logistic_Line_Item__c> LLIList=new list<Logistic_Line_Item__c>();
                LLIList=[SELECT Id, Name, Order_Product__c FROM Logistic_Line_Item__c WHERE Logistic__c IN:LogIds AND Product__c!=Null]; //Sales_Order_Line_Item__c IN:SoliIds

                list<OrderItem> SoliListFinal=new list<OrderItem>();
                for(Integer i=0; i<SoliList.size(); i++){
                    if(SoliList[i].Logistic_Quantity__c==null) SoliList[i].Logistic_Quantity__c=0;
                    if(SoliList[i].Quantity==null) SoliList[i].Quantity=0;
                    if(SoliList[i].Remaining_Quantity__c==null) SoliList[i].Remaining_Quantity__c=0;
                    if(SoliList[i].Logistic_Quantity__c<SoliList[i].Quantity && SoliList[i].Order.Ready_To_Pick_Pack__c==false) SoliList[i].Active__c=true;
                    SoliListFinal.add(SoliList[i]);
                }

                List<String> productIds = new List<String>();
                for(OrderItem so_li :SoliListFinal){ productIds.add(so_li.Product2Id); }

                so.Ord=[SELECT Id, Name, AccountId, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,Ship_From_Address__c,
                        Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                        FROM Order WHERE Id=:orderId limit 1];

                Distribution_Channel__c dc = new Distribution_Channel__c();
                if(so.Ord.Channel__c != null){
                    dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c,Site__r.Primary_Contact__c, Active__c
                          FROM Distribution_Channel__c WHERE Channel__c=:so.Ord.Channel__c AND Site__c != null order by Priority__c LIMIT 1];
                }

                if(dc.Id != null){
                    so.DistributeChannelId=dc.Id;
                    so.fromContact = (dc.Site__c != null && dc.Site__r.Primary_Contact__c != null) ? dc.Site__r.Primary_Contact__c : null;
                    Map < Id, List<Inventory_Stock__c> > ProductMap2Stock = new Map < Id, List<Inventory_Stock__c> > ();
                    for (Inventory_Stock__c WarehouseItemInventoryStocks: [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,Warehouse__c, product__c,
                                                                                 Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c,Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                                 From Inventory_Stock__c Where product__c IN: productIds And Active__c = true And (Number_of_Item_In_Stock__c > 0 or (Number_of_Item_In_Stock__c < 0 And Name = 'Serial Stock Holder')) And Warehouse__c =:dc.Site__c])
                    {
                        if(ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)){ ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                        }else{
                            List<Inventory_Stock__c> WarehouseItemInventoryStockLists = new List<Inventory_Stock__c>();
                            WarehouseItemInventoryStockLists.add(WarehouseItemInventoryStocks);
                            ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, WarehouseItemInventoryStockLists);
                        }
                    }

                    for(Integer i=0; i<SoliListFinal.size(); i++){
                        Decimal proStockCount = 0;
                        if (ProductMap2Stock != null && ProductMap2Stock.keyset().contains(SoliListFinal[i].Product2Id)) {
                            for(Inventory_Stock__c IS : ProductMap2Stock.get(SoliListFinal[i].Product2Id)){
                                proStockCount += IS.Number_of_Item_In_Stock__c;
                            }
                        }
                        SoliListFinal[i].Reserved_Quantity__c = proStockCount;
                        SoliListFinal[i].Remaining_Quantity__c = SoliListFinal[i].Quantity - SoliListFinal[i].Logistic_Quantity__c;

                        //if(SoliListFinal[i].Reserved_Quantity__c<=0) SoliListFinal[i].Active__c=false;

                    }
                }


                for(Integer i=0; i<SoliListFinal.size(); i++)  if(SoliListFinal[i].Quantity-SoliListFinal[i].Logistic_Quantity__c<=0) SoliListFinal[i].Active__c=false;

                // To fetch boms from the kit product version

                Set < Id > BomproductIds = new Set < Id > ();

                list < Id > soliIds2explode = new list < Id > ();
                list < Id > proIds = new list < Id > ();
                Map < Id, List < BOM__c >> soliBOMS = new Map < Id, List < BOM__c >> ();
                Map < Id, Decimal > proStocks = new Map < Id, Decimal > ();
                List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();

                Set < Id > priceBookIds = new Set < Id > ();
                list < Id > soliBOMVersion = new List < Id > ();

                for(OrderItem Foli : SoliListFinal){
                    if(!Foli.Inventory_Tracked__c && Foli.Is_Kit__c ){ proIds.add(Foli.Product2Id);  if(Foli.PriceBookId__c != null) priceBookIds.add(Foli.PriceBookId__c);
                    }
                }

                Set<Id> alternateBOMs = new Set<Id>();
                Set<Id> alternateBOMProds = new Set<Id>();

                List<BOM_Line_Item__c> BOMList = new List<BOM_Line_Item__c>();

                if (proIds.size() > 0) {  BOMList = [Select Id, Name, Active__c,Quantity__c, RecordType.Name From BOM_Line_Item__c  Where((Active__c = true And Type__c != 'Alternate'  and BOM__r.RecordType.Name = 'Kit' And BOM_Product__c In: proIds And BOM__r.Active__c = true And BOM__r.Start_Date__c <= Today And BOM__r.To_Date__c >= Today And(BOM__r.Type__c = 'Assembly' Or BOM__r.Type__c = 'Sales') AND BOM__r.Status__c = 'Certified'))  Order by BOM__r.Default__c DESC];

                }
				System.debug('BomLM size: '+BOMList.size());
                for(BOM_Line_Item__c bomItems :BOMList){
                    System.debug('bomItems.qty: '+bomItems.Quantity__c);
                  //  BomproductIds.add(bomItems.BOM_Component__c);
                    //  if(bomItems.BOM_Alternate_Of__c != null) alternateBOMProds.add(bomItems.BOM_Alternate_Of__c);
                }

                //if(BOMList.size() > 0){


                Distribution_Channel__c dchannel = new Distribution_Channel__c();
                if(so.Ord.Channel__c != null){
                    dchannel = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                                FROM Distribution_Channel__c WHERE Channel__c=:so.Ord.Channel__c AND Site__c != null order by Priority__c LIMIT 1];
                }

                if(dchannel.Id != null){

                    //so.DistributeChannelId=dc.Id;

                    Map < Id, List<Inventory_Stock__c> > BOMProductMap2Stock = new Map < Id, List<Inventory_Stock__c> > ();
                    for (Inventory_Stock__c WarehouseItemInventoryBOMStocks: [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,Warehouse__c, product__c,
                                                                                    Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c,Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                                    From Inventory_Stock__c Where product__c IN: BomproductIds And Active__c = true And Number_of_Item_In_Stock__c > 0 And Warehouse__c =:dchannel.Site__c])
                    { if(BOMProductMap2Stock.containsKey(WarehouseItemInventoryBOMStocks.product__c)){BOMProductMap2Stock.get(WarehouseItemInventoryBOMStocks.product__c).add(WarehouseItemInventoryBOMStocks);
                        }else{ List<Inventory_Stock__c> WarehouseItemInventoryStockListsBom = new List<Inventory_Stock__c>();  WarehouseItemInventoryStockListsBom.add(WarehouseItemInventoryBOMStocks);  BOMProductMap2Stock.put(WarehouseItemInventoryBOMStocks.product__c, WarehouseItemInventoryStockListsBom);
                        }
                    }

                    /*list<Id> bomprodIds = new list<Id>();
for(BOM__c b:BOMList){
bomprodIds.add(b.BOM_Component__c);
}

                    Order orderdetail = new Order();
                    orderdetail =[SELECT Id, Name, AccountId, Pricebook2Id, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,
                                  Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                                  FROM Order WHERE Id=:orderId limit 1];

                    List<PricebookEntry> pbe=new List<PricebookEntry>();
                    pbe = [Select UnitPrice,Purchase_Price__c,Product2.Id,Product2.Name,Product2.ProductCode,Product2.Description,Product2.Configure__c,Product2.Allow_Back_Orders__c,Product2.Is_Kit__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure
                           from PricebookEntry where Pricebook2Id =:orderdetail.Pricebook2Id AND Product2Id In:BomproductIds AND IsActive=TRUE];

                    Map <Id,PricebookEntry> pbeMap = new Map <Id,PricebookEntry>();

                    for(PricebookEntry pb : pbe){ pbeMap.put(pb.Product2.Id,pb);
                    }

                    list<BOM_Line_Item__c>BOMListFinal=new list<BOM_Line_Item__c>();

                    for(OrderItem Foli : SoliListFinal){system.debug('Foli.Quantity: '+Foli.Quantity);
                        if(!Foli.Inventory_Tracked__c && Foli.Is_Kit__c && BOMList.size() > 0){ for(BOM_Line_Item__c bom :BOMList){
                              if (bom.Quantity__c == null || Foli.Quantity == null) {
    throw new AuraHandledException('Quantity is missing for BOM or Order Item. Please ensure all quantities are properly set.');
}
                      else bom.Quantity__c = bom.Quantity__c*Foli.Quantity;
                            system.debug('bom.Quantity__c: '+Foli.Quantity);
                            }
                        }
                    }
 



                    for(BOM_Line_Item__c Boli : BOMListFinal){  bomwrapper bomwrap = new bomwrapper(); Decimal proStockCount = 0;

                        if(Boli.BOM_Component__c != null){
                            if (BOMProductMap2Stock.containsKey(Boli.BOM_Component__c)) {
                                for(Inventory_Stock__c IS : BOMProductMap2Stock.get(Boli.BOM_Component__c)){
                                    proStockCount += IS.Number_of_Item_In_Stock__c;
                                }
                            }
                            if(pbeMap.containsKey(Boli.BOM_Component__c))      bomwrap.pbe  = pbeMap.get(Boli.BOM_Component__c);
                            bomwrap.stock = proStockCount;
                            bomwrap.BomLM = Boli;
                            so.BOMS.add(bomwrap);
                        }
                    }
                    //so.BOMS = BomWrapList;
                    so.OrdList=SoliListFinal;

                    if(so.Ord.Id != null){
                        so.isReadyToPickPack = so.Ord.Ready_To_Pick_Pack__c;
                    }
                }

                Functionality_Control__c FC = new Functionality_Control__c();
                FC = Functionality_Control__c.getValues(userInfo.getuserid());
                if(FC == null){
                    FC = Functionality_Control__c.getValues(userInfo.getProfileId());
                    if(FC==null) FC = Functionality_Control__c.getInstance();
                }
                if(FC != null){
                    so.showShipmentDetails = FC.Show_Ship_Details_in_Orders_to_Logistic__c;
                    so.ShowReturnShipSection = FC.ShowReturnShipSection__c;
                }

                return so;
            }
            else {so.OrdList=new list<OrderItem>();  so.Ord=new Order();  so.DistributeChannelId='';  so.Logistic=new Logistic__c();  return so; } } catch (AuraHandledException e) {
        // Re-throw the AuraHandledException to preserve the user-friendly message
        throw e;
    } catch (Exception e) {
        // Handle unexpected errors with a generic message
        throw new AuraHandledException('An unexpected error occurred while processing the order: ' + e.getMessage());
    }
        
    }*/
    @AuraEnabled
global Static SalesOrderToLogistic getordItemList(String orderId) {
    SalesOrderToLogistic so = new SalesOrderToLogistic();
    try {
        if (String.isNotEmpty(orderId)) {
            list<OrderItem> SoliList = new list<OrderItem>();
            SoliList = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Track_Inventory__c, Product2.Is_Kit__c, Quantity, Base_Price__c, VAT_Amount__c, Discount_Amount__c, BOM__c,
                        OrderItemNumber, OrderId, Order.Name, Order.Ready_To_Pick_Pack__c,Order.Company__c, Site__c, Active__c, Logistic_Quantity__c, Inventory_Tracked__c, Is_Kit__c, PriceBookId__c,
                        Picked_Quantity__c, Packed_Quantity__c, Shipped_Quantity__c, Reserved_Quantity__c, Remaining_Quantity__c
                        FROM OrderItem WHERE OrderId = :orderId AND Product2Id != Null AND (Product2.Track_Inventory__c = true OR Product2.Is_Kit__c = true)];

            list<OrderItem> trackinventoryProds = new list<OrderItem>();
            list<OrderItem> nontrackinventoryProds = new list<OrderItem>();

            set<String> SoliIds = new set<String>();
            for (OrderItem s : SoliList) SoliIds.add(s.Id);

            for (Integer i = 0; i < SoliList.size(); i++) SoliList[i].Active__c = false;

            list<Logistic__c> LogList = new list<Logistic__c>();
            LogList = [SELECT Id, Name, Order_S__c, Active__c FROM Logistic__c WHERE Order_S__c = :orderId AND Active__c = true];

            set<String> LogIds = new set<String>();
            for (Logistic__c s : LogList) LogIds.add(s.Id);
            list<Logistic_Line_Item__c> LLIList = new list<Logistic_Line_Item__c>();
            LLIList = [SELECT Id, Name, Order_Product__c FROM Logistic_Line_Item__c WHERE Logistic__c IN :LogIds AND Product__c != Null];

            list<OrderItem> SoliListFinal = new list<OrderItem>();
            for (Integer i = 0; i < SoliList.size(); i++) {
                if (SoliList[i].Logistic_Quantity__c == null) SoliList[i].Logistic_Quantity__c = 0;
                if (SoliList[i].Quantity == null) SoliList[i].Quantity = 0;
                if (SoliList[i].Remaining_Quantity__c == null) SoliList[i].Remaining_Quantity__c = 0;
                if (SoliList[i].Logistic_Quantity__c < SoliList[i].Quantity && SoliList[i].Order.Ready_To_Pick_Pack__c == false) SoliList[i].Active__c = true;
                SoliListFinal.add(SoliList[i]);
            }

            List<String> productIds = new List<String>();
            for (OrderItem so_li : SoliListFinal) { productIds.add(so_li.Product2Id); }

            so.Ord = [SELECT Id, Name, AccountId, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description, Ship_From_Address__c,Company__c,
                      Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                      FROM Order WHERE Id = :orderId limit 1];

            Distribution_Channel__c dc = new Distribution_Channel__c();
            if (so.Ord.Channel__c != null) {
                dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Site__r.Primary_Contact__c, Active__c
                      FROM Distribution_Channel__c WHERE Channel__c = :so.Ord.Channel__c AND Site__c != null order by Priority__c LIMIT 1];
            }

            if (dc.Id != null) {
                so.DistributeChannelId = dc.Id;
                so.fromContact = (dc.Site__c != null && dc.Site__r.Primary_Contact__c != null) ? dc.Site__r.Primary_Contact__c : null;
                Map<Id, List<Inventory_Stock__c>> ProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                for (Inventory_Stock__c WarehouseItemInventoryStocks : [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                       Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                                                                                                                                    //or (Number_of_Item_In_Stock__c < 0 And Name = 'Serial Stock Holder') 
                                                                       From Inventory_Stock__c Where product__c IN :productIds And Active__c = true And (Number_of_Item_In_Stock__c > 0) And Warehouse__c = :dc.Site__c]) {
                    if (ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)) {
                        ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                    } else {
                        List<Inventory_Stock__c> WarehouseItemInventoryStockLists = new List<Inventory_Stock__c>();
                        WarehouseItemInventoryStockLists.add(WarehouseItemInventoryStocks);
                        ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, WarehouseItemInventoryStockLists);
                    }
                }

                for (Integer i = 0; i < SoliListFinal.size(); i++) {
                    Decimal proStockCount = 0;
                    if (ProductMap2Stock != null && ProductMap2Stock.keyset().contains(SoliListFinal[i].Product2Id)) {
                        for (Inventory_Stock__c IS : ProductMap2Stock.get(SoliListFinal[i].Product2Id)) {
                            proStockCount += IS.Number_of_Item_In_Stock__c;
                        }
                    }
                    SoliListFinal[i].Reserved_Quantity__c = proStockCount;
                    SoliListFinal[i].Remaining_Quantity__c = SoliListFinal[i].Quantity - SoliListFinal[i].Logistic_Quantity__c;//commented by khaleeq to keep rem qty 0
                    system.debug(' order item remining quanityt--'+SoliListFinal[i].Remaining_Quantity__c);
                }
            }

            for (Integer i = 0; i < SoliListFinal.size(); i++) {
                if (SoliListFinal[i].Quantity - SoliListFinal[i].Logistic_Quantity__c <= 0) SoliListFinal[i].Active__c = false;
            }

            // To fetch BOMs from the kit product version
            Set<Id> BomproductIds = new Set<Id>();
            list<Id> proIds = new list<Id>();
            Map<Id, List<BOM__c>> soliBOMS = new Map<Id, List<BOM__c>>();
            Map<Id, Decimal> proStocks = new Map<Id, Decimal>();
            List<Inventory_Stock__c> WarehouseItemInventoryStocks = new List<Inventory_Stock__c>();
            Set<Id> priceBookIds = new Set<Id>();
            list<Id> soliBOMVersion = new List<Id>();

            // Collect BOM__c IDs from OrderItems
            Map<Id, Id> orderItemToBomMap = new Map<Id, Id>();
            for (OrderItem Foli : SoliListFinal) {
                if (!Foli.Inventory_Tracked__c && Foli.Is_Kit__c) {
                    proIds.add(Foli.Product2Id);
                    if (Foli.PriceBookId__c != null) priceBookIds.add(Foli.PriceBookId__c);
                    if (Foli.BOM__c != null) orderItemToBomMap.put(Foli.Id, Foli.BOM__c);
                }
            }

            Set<Id> alternateBOMs = new Set<Id>();
            Set<Id> alternateBOMProds = new Set<Id>();
            List<BOM_Line_Item__c> BOMList = new List<BOM_Line_Item__c>();

            // Query BOM_Line_Item__c with BOM__c filter
            if (proIds.size() > 0 && !orderItemToBomMap.isEmpty()) {
                BOMList = [SELECT Id, Name, Active__c, Quantity__c, RecordType.Name, BOM__c, BOM_Component__c
                           FROM BOM_Line_Item__c
                           WHERE Active__c = true AND Type__c != 'Alternate' AND BOM__r.RecordType.Name = 'Kit'
                           AND BOM_Product__c IN :proIds AND BOM__r.Active__c = true
                           AND BOM__r.Start_Date__c <= TODAY AND BOM__r.To_Date__c >= TODAY
                           AND (BOM__r.Type__c = 'Assembly' OR BOM__r.Type__c = 'Sales')
                           AND BOM__r.Status__c = 'Certified'
                           AND BOM__c IN :orderItemToBomMap.values()
                           ORDER BY BOM__r.Default__c DESC];
            }
            System.debug('BomLM size: ' + BOMList.size());
            for (BOM_Line_Item__c bomItems : BOMList) {
                System.debug('bomItems.qty: ' + bomItems.Quantity__c);
                BomproductIds.add(bomItems.BOM_Component__c);
            }

            Distribution_Channel__c dchannel = new Distribution_Channel__c();
            if (so.Ord.Channel__c != null) {
                dchannel = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                            FROM Distribution_Channel__c WHERE Channel__c = :so.Ord.Channel__c AND Site__c != null order by Priority__c LIMIT 1];
            }

            if (dchannel.Id != null) {
                Map<Id, List<Inventory_Stock__c>> BOMProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                for (Inventory_Stock__c WarehouseItemInventoryBOMStocks : [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                          Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                          From Inventory_Stock__c Where product__c IN :BomproductIds And Active__c = true And Number_of_Item_In_Stock__c > 0 And Warehouse__c = :dchannel.Site__c]) {
                    if (BOMProductMap2Stock.containsKey(WarehouseItemInventoryBOMStocks.product__c)) {
                        BOMProductMap2Stock.get(WarehouseItemInventoryBOMStocks.product__c).add(WarehouseItemInventoryBOMStocks);
                    } else {
                        List<Inventory_Stock__c> WarehouseItemInventoryStockListsBom = new List<Inventory_Stock__c>();
                        WarehouseItemInventoryStockListsBom.add(WarehouseItemInventoryBOMStocks);
                        BOMProductMap2Stock.put(WarehouseItemInventoryBOMStocks.product__c, WarehouseItemInventoryStockListsBom);
                    }
                }

                Order orderdetail = [SELECT Id, Name, AccountId, Pricebook2Id, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,
                                    Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                                    FROM Order WHERE Id = :orderId limit 1];

                List<PricebookEntry> pbe = [Select UnitPrice, Purchase_Price__c, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Description, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Is_Kit__c, Product2.Picture__c, Product2.Serialise__c, Product2.QuantityUnitOfMeasure
                                            from PricebookEntry where Pricebook2Id = :orderdetail.Pricebook2Id AND Product2Id In :BomproductIds AND IsActive = TRUE];

                Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
                for (PricebookEntry pb : pbe) {
                    pbeMap.put(pb.Product2.Id, pb);
                }

                list<BOM_Line_Item__c> BOMListFinal = new list<BOM_Line_Item__c>();
                for (OrderItem Foli : SoliListFinal) {
                    system.debug('Foli.Quantity: ' + Foli.Quantity);
                    if (!Foli.Inventory_Tracked__c && Foli.Is_Kit__c && BOMList.size() > 0) {

                        for (BOM_Line_Item__c bom : BOMList) {
                            if (orderItemToBomMap.containsKey(Foli.Id) && bom.BOM__c == orderItemToBomMap.get(Foli.Id)) {
                                if (bom.Quantity__c == null || Foli.Quantity == null) {
                                    throw new AuraHandledException('Quantity is missing for BOM or Order Item. Please ensure all quantities are properly set.');
                                } else {
                                    bom.Quantity__c = bom.Quantity__c * Foli.Quantity;
                                    system.debug('bom.Quantity__c: ' + bom.Quantity__c);
                                    BOMListFinal.add(bom);
                                }
                            }
                        }
                    }
                }

                for (BOM_Line_Item__c Boli : BOMListFinal) {
                    bomwrapper bomwrap = new bomwrapper();
                    Decimal proStockCount = 0;
                    if (Boli.BOM_Component__c != null) {
                        if (BOMProductMap2Stock.containsKey(Boli.BOM_Component__c)) {
                            for (Inventory_Stock__c IS : BOMProductMap2Stock.get(Boli.BOM_Component__c)) {
                                proStockCount += IS.Number_of_Item_In_Stock__c;
                            }
                        }
                        if (pbeMap.containsKey(Boli.BOM_Component__c)) bomwrap.pbe = pbeMap.get(Boli.BOM_Component__c);
                        bomwrap.stock = proStockCount;
                        bomwrap.BomLM = Boli;
                        so.BOMS.add(bomwrap);
                    }
                }
                so.OrdList = SoliListFinal;

                if (so.Ord.Id != null) {
                    so.isReadyToPickPack = so.Ord.Ready_To_Pick_Pack__c;
                }
            }

            Functionality_Control__c FC = new Functionality_Control__c();
            FC = Functionality_Control__c.getValues(userInfo.getuserid());
            if (FC == null) {
                FC = Functionality_Control__c.getValues(userInfo.getProfileId());
                if (FC == null) FC = Functionality_Control__c.getInstance();
            }
            if (FC != null) {
                so.showShipmentDetails = FC.Show_Ship_Details_in_Orders_to_Logistic__c;
                so.ShowReturnShipSection = FC.ShowReturnShipSection__c;
            }

            return so;
        } else {
            so.OrdList = new list<OrderItem>();
            so.Ord = new Order();
            so.DistributeChannelId = '';
            so.Logistic = new Logistic__c();
            return so;
        }
    } catch (AuraHandledException e) {
        throw e;
    } catch (Exception e) {
        throw new AuraHandledException('An unexpected error occurred while processing the order: ' + e.getMessage());
    }
}
    @AuraEnabled
    global static List<String> getbilloptions(){ List<String> options = new List<String>(); Schema.DescribeFieldResult fieldResult = Logistic__c.Bill_To_Return__c .getDescribe(); List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues(); for (Schema.PicklistEntry f: ple) {options.add(f.getLabel());} return options; }

    @AuraEnabled
    global Static list<OrderItem> getupdatedstocksDC(String orditms, String chnId, String DCId){
        return null;
    }
   /* @AuraEnabled
    global Static stockwrapper getupdatedstocksDCs(String orditms,String chnId,String DCId,String OrdId,String LogItems){
        try{
            stockwrapper stockwrap = new stockwrapper();
            //list<OrderItem> UpdatedOrdList = new list<OrderItem>();
            list<OrderItem> Ordlist = new list<OrderItem>();
            system.debug('String.isNotEmpty(LogItems) : '+LogItems);
            system.debug('String.isNotEmpty(orditms) : '+orditms);
            if(String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(LogItems) && LogItems != null && LogItems != '' && LogItems != '[]'){
                list<Logistic_Line_Item__c> logItemslist = new list<Logistic_Line_Item__c>();
                logItemslist = (List<Logistic_Line_Item__c>) JSON.deserialize(LogItems, List<Logistic_Line_Item__c> .class);
                 set<Id> productIds = new set<Id>();
                    for(Logistic_Line_Item__c loli :logItemslist){
                        if(loli.Product__c != null){
                            productIds.add(loli.Product__c);
                        }
                    }
                Distribution_Channel__c dc = new Distribution_Channel__c();
                dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                      FROM Distribution_Channel__c WHERE Id =:DCId AND Channel__c=:chnId AND Site__c != null order by Priority__c LIMIT 1];
                if(dc.Id != null){

                    Map<Id, Decimal> stockMap = new Map<Id, Decimal>();

                    for (AggregateResult result : [Select Product__c,SUM(Number_of_Item_In_Stock__c) totalStock  FROM Inventory_Stock__c   WHERE product__c IN: productIds And Active__c = true And (Number_of_Item_In_Stock__c > 0 or (Number_of_Item_In_Stock__c < 0 and Name = 'Serial Stock Holder')) And Warehouse__c =:dc.Site__c GROUP BY Product__c]) {
                        Id ProdId = (Id)result.get('Product__c');
                        Decimal totalStock = (Decimal)result.get('totalStock');

                        if (stockMap.containsKey(ProdId)) {  stockMap.put(ProdId, stockMap.get(ProdId) + totalStock);
                        } else {
                            stockMap.put(ProdId, totalStock);
                        }
                    }

                    for(Logistic_Line_Item__c loli :logItemslist){
                        Decimal proStockCount = 0;
                        if(loli.Product__c != null){
                                if (stockMap.containsKey(loli.Product__c)) {
                                        proStockCount += stockMap.get(loli.Product__c);
                                }
                            }
                            loli.Fulfilled_Quantity__c = proStockCount;
                            stockwrap.UpdatedlogList.add(loli);
                        }
                        //return UpdatedOrdList;
                    }
            }
            else{
                if(String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(orditms)){
                    system.debug('inside orditms::');
                    Ordlist =  (List<OrderItem>) JSON.deserialize(orditms, List<OrderItem> .class);

                    //Storing orderitem product Id's in the set productIds
                    List<String> productIds = new List<String>();
                    for(OrderItem soli :Ordlist){
                        if(soli.Product2Id != null){
                            if(!productIds.contains(soli.Product2Id)){ productIds.add(soli.Product2Id);  }
                        }
                    }
                    Distribution_Channel__c dc = new Distribution_Channel__c();
                    dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                          FROM Distribution_Channel__c WHERE Id =:DCId AND Channel__c=:chnId AND Site__c != null order by Priority__c LIMIT 1];
                    if(dc.Id != null){

                        Map < Id, List<Inventory_Stock__c> > ProductMap2Stock = new Map < Id, List<Inventory_Stock__c> > ();


                        for (Inventory_Stock__c WarehouseItemInventoryStocks: [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,Warehouse__c, product__c,
                                                                                     Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c,Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                                     From Inventory_Stock__c Where product__c IN: productIds And Active__c = true And (Number_of_Item_In_Stock__c > 0 or (Number_of_Item_In_Stock__c < 0 and Name = 'Serial Stock Holder')) And Warehouse__c =:dc.Site__c]) // added by shaguftha serial stock holder condition
                        {
                            if(ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)){  ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                            }else{
                                List<Inventory_Stock__c> WarehouseItemInventoryStockLists = new List<Inventory_Stock__c>();
                                WarehouseItemInventoryStockLists.add(WarehouseItemInventoryStocks);
                                ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, WarehouseItemInventoryStockLists);
                            }
                        }



                        for(OrderItem soli :Ordlist){
                            Decimal proStockCount = 0;
                            if(soli.Product2Id != null){
                                if (ProductMap2Stock.containsKey(soli.Product2Id)) {
                                    for(Inventory_Stock__c IS : ProductMap2Stock.get(soli.Product2Id)){
                                        proStockCount += IS.Number_of_Item_In_Stock__c;
                                    }
                                }
                            }
                            soli.Reserved_Quantity__c = proStockCount;
                            soli.Remaining_Quantity__c = soli.Quantity - soli.Logistic_Quantity__c;  stockwrap.UpdatedOrdList.add(soli);
                        }
                        //return UpdatedOrdList;
                    }
                }
                if(String.isNotEmpty(chnId) && String.isNotEmpty(DCId)){

                    // To fetch boms from the kit product version

                    Set < Id > BomproductIds = new Set < Id > ();
                    list < Id > proIds = new list < Id > ();
                    Map < Id, Decimal > proStocks = new Map < Id, Decimal > ();
                    List < Inventory_Stock__c > WarehouseItemInventoryStocks = new List < Inventory_Stock__c > ();

                    Set < Id > priceBookIds = new Set < Id > ();
                    list < Id > soliBOMVersion = new List < Id > ();

                    Map<Id,Id> prodMap = new Map<Id,Id>();

                    for(OrderItem Foli : Ordlist){ if(!Foli.Inventory_Tracked__c && Foli.Is_Kit__c ){ proIds.add(Foli.Product2Id);  if(Foli.PriceBookId__c != null) priceBookIds.add(Foli.PriceBookId__c); prodMap.put(foli.Product2Id,Foli.Id);
                        }
                    }

                    Set<Id> alternateBOMs = new Set<Id>();
                    Set<Id> alternateBOMProds = new Set<Id>();

                    List<BOM_Line_Item__c> BOMList = new List<BOM_Line_Item__c>();

				     system.debug('proIds'+proIds.size());
                    if (proIds.size() > 0) {BOMList = [Select Id, Name,Active__c, BOM_Alternate_Of__c, BOM_Alternate_Of__r.Type__c, BOM_Alternate_Of__r.Quantity__c, BOM_Alternate_Of__r.BOM_Component__c,BOM_Product__c, BOM__c, BOM_Component__c, BOM_Component__r.Name, BOM_Component__r.Picture__c, BOM_Component__r.Preview_Image__c, Quantity__c, RecordType.Name, BOM__r.Active__c, BOM__r.Category__c, BOM__r.Default__c, BOM__r.Start_Date__c, BOM__r.To_Date__c,  BOM__r.Type__c, BOM__r.Status__c From BOM_Line_Item__c Where((Active__c = true And Type__c != 'Alternate'  and BOM__r.RecordType.Name = 'Kit' And BOM_Product__c In: proIds And BOM__r.Active__c = true And BOM__r.Start_Date__c <= Today And BOM__r.To_Date__c >= Today And(BOM__r.Type__c = 'Assembly' Or BOM__r.Type__c = 'Sales') AND BOM__r.Status__c = 'Certified'))  Order by BOM__r.Default__c DESC];
						system.debug('BOMList'+BOMList.size());
                    }

                    for(BOM_Line_Item__c bomItems :BOMList){
                        BomproductIds.add(bomItems.BOM_Component__c);
                    }

                    //if(BOMList.size() > 0){


                    Distribution_Channel__c dchannel = new Distribution_Channel__c();

                    dchannel = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                                FROM Distribution_Channel__c WHERE Id =:DCId AND Channel__c=:chnId AND Site__c != null order by Priority__c LIMIT 1];


                    if(dchannel.Id != null){

                        //so.DistributeChannelId=dc.Id;

                        Map < Id, List<Inventory_Stock__c> > BOMProductMap2Stock = new Map < Id, List<Inventory_Stock__c> > ();
                        for (Inventory_Stock__c WarehouseItemInventoryBOMStocks: [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c,Warehouse__c, product__c,
                                                                                        Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c,Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                                        From Inventory_Stock__c Where product__c IN: BomproductIds And Active__c = true And Number_of_Item_In_Stock__c > 0 And Warehouse__c =:dchannel.Site__c])
                        {
                            if(BOMProductMap2Stock.containsKey(WarehouseItemInventoryBOMStocks.product__c)){BOMProductMap2Stock.get(WarehouseItemInventoryBOMStocks.product__c).add(WarehouseItemInventoryBOMStocks);
                            }else{ List<Inventory_Stock__c> WarehouseItemInventoryStockListsBom = new List<Inventory_Stock__c>();  WarehouseItemInventoryStockListsBom.add(WarehouseItemInventoryBOMStocks); BOMProductMap2Stock.put(WarehouseItemInventoryBOMStocks.product__c, WarehouseItemInventoryStockListsBom);
                            }
                        }

                        list<Id> bomprodIds = new list<Id>();
                        for(BOM_Line_Item__c b:BOMList){
                            bomprodIds.add(b.BOM_Component__c);
                        }

                        Order orderdetail = new Order();

                        orderdetail = [SELECT Id, Name, AccountId, Pricebook2Id, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,
                                        Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                                        FROM Order WHERE Id=:OrdId limit 1];

                        List<PricebookEntry> pbe=new List<PricebookEntry>();
                        pbe = [Select UnitPrice,Purchase_Price__c,Product2.Id,Product2.Name,Product2.ProductCode,Product2.Description,Product2.Configure__c,Product2.Allow_Back_Orders__c,Product2.Is_Kit__c,Product2.Picture__c,Product2.Serialise__c,Product2.QuantityUnitOfMeasure from PricebookEntry where Pricebook2Id =:orderdetail.Pricebook2Id AND Product2Id In:bomprodIds AND IsActive=TRUE];

                        Map <Id,PricebookEntry> pbeMap = new Map <Id,PricebookEntry>();

                        for(PricebookEntry pb : pbe){ pbeMap.put(pb.Product2.Id,pb); }

                        list<BOM_Line_Item__c>BOMListFinal=new list<BOM_Line_Item__c>();


                        for(OrderItem Foli : Ordlist){
                            if(!Foli.Inventory_Tracked__c && Foli.Is_Kit__c ){for(BOM_Line_Item__c bom :BOMList){ BOMListFinal.add(bom);
                                }
                            }
                        }

                        for(BOM_Line_Item__c Boli : BOMListFinal){ bomwrapper bomwrap = new bomwrapper();Decimal proStockCount = 0;
 						system.debug('Boli.BOM_Component__c~>'+Boli.BOM_Component__c);
                            if(Boli.BOM_Component__c != null){
                                system.debug('in here Asra ~>');
                                if (BOMProductMap2Stock.containsKey(Boli.BOM_Component__c)) {
                                    system.debug('inside contains bom component ~>');
                                    for(Inventory_Stock__c IS : BOMProductMap2Stock.get(Boli.BOM_Component__c)){
                                         system.debug('inside Number_of_Item_In_Stock__c ~>'+IS.Number_of_Item_In_Stock__c);
                                        proStockCount += IS.Number_of_Item_In_Stock__c;
                                    }
                                }
								system.debug('proStockCount ~>'+proStockCount);
                                bomwrap.stock = proStockCount;
                                bomwrap.BomLM = Boli;
                                
                                if(prodMap.containsKey(Boli.BOM_Product__c)) bomwrap.OrderProdId  = prodMap.get(Boli.BOM_Product__c);
                                if(pbeMap.containsKey(Boli.BOM_Component__c)) bomwrap.pbe  = pbeMap.get(Boli.BOM_Component__c);
                                stockwrap.UpdatedBomList.add(bomwrap);
								 system.debug('added here~>');
                            }

                        }


                    }
                }

            }
            return stockwrap;
        } catch (Exception e) {
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getLineNumber()+' '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
    }*/// commented and added below class , bushra , 16-07-2025 , issue:Duplicate BOM’s are displayed if two Kit products are added together 
/*  @AuraEnabled
global static stockwrapper getupdatedstocksDCs(String orditms, String chnId, String DCId, String OrdId, String LogItems) {
    try {
        stockwrapper stockwrap = new stockwrapper();
        
        if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(LogItems) && LogItems != null && LogItems != '' && LogItems != '[]') {
            List<Logistic_Line_Item__c> logItemslist = (List<Logistic_Line_Item__c>) JSON.deserialize(LogItems, List<Logistic_Line_Item__c>.class);
            Set<Id> productIds = new Set<Id>();
            for (Logistic_Line_Item__c loli : logItemslist) {
                if (loli.Product__c != null) {
                    productIds.add(loli.Product__c);
                }
            }
            Distribution_Channel__c dc = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c 
                                         FROM Distribution_Channel__c 
                                         WHERE Id = :DCId AND Channel__c = :chnId AND Site__c != null 
                                         ORDER BY Priority__c LIMIT 1];
            if (dc.Id != null) {
                Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
                for (AggregateResult result : [SELECT Product__c, SUM(Number_of_Item_In_Stock__c) totalStock 
                                              FROM Inventory_Stock__c 
                                              WHERE product__c IN :productIds 
                                              AND Active__c = true 
                                              AND (Number_of_Item_In_Stock__c > 0 OR (Number_of_Item_In_Stock__c < 0 AND Name = 'Serial Stock Holder')) 
                                              AND Warehouse__c = :dc.Site__c 
                                              GROUP BY Product__c]) {
                    Id ProdId = (Id)result.get('Product__c');
                    Decimal totalStock = (Decimal)result.get('totalStock');
                    stockMap.put(ProdId, stockMap.containsKey(ProdId) ? stockMap.get(ProdId) + totalStock : totalStock);
                }
                for (Logistic_Line_Item__c loli : logItemslist) {
                    Decimal proStockCount = 0;
                    if (loli.Product__c != null && stockMap.containsKey(loli.Product__c)) {
                        proStockCount += stockMap.get(loli.Product__c);
                    }
                    loli.Fulfilled_Quantity__c = proStockCount;
                    stockwrap.UpdatedlogList.add(loli);
                }
            }
        } else if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(orditms)) {
            List<OrderItem> Ordlist = (List<OrderItem>) JSON.deserialize(orditms, List<OrderItem>.class);
            List<String> productIds = new List<String>();
            for (OrderItem soli : Ordlist) {
                if (soli.Product2Id != null && !productIds.contains(soli.Product2Id)) {
                    productIds.add(soli.Product2Id);
                }
            }
            Distribution_Channel__c dc = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c 
                                         FROM Distribution_Channel__c 
                                         WHERE Id = :DCId AND Channel__c = :chnId AND Site__c != null 
                                         ORDER BY Priority__c LIMIT 1];
            if (dc.Id != null) {
                Map<Id, List<Inventory_Stock__c>> ProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                for (Inventory_Stock__c WarehouseItemInventoryStocks : [SELECT Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                       Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                       FROM Inventory_Stock__c 
                                                                       WHERE product__c IN :productIds 
                                                                       AND Active__c = true 
                                                                       AND (Number_of_Item_In_Stock__c > 0)//OR (Number_of_Item_In_Stock__c < 0 AND Name = 'Serial Stock Holder') 
                                                                       AND Warehouse__c = :dc.Site__c]) {
                    if (ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)) {
                        ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                    } else {
                        ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, new List<Inventory_Stock__c>{WarehouseItemInventoryStocks});
                    }
                }
                for (OrderItem soli : Ordlist) {
                    Decimal proStockCount = 0;
                    if (soli.Product2Id != null && ProductMap2Stock.containsKey(soli.Product2Id)) {
                        for (Inventory_Stock__c IS : ProductMap2Stock.get(soli.Product2Id)) {
                            proStockCount += IS.Number_of_Item_In_Stock__c;
                        }
                    }
                    soli.Reserved_Quantity__c = proStockCount;
                    soli.Remaining_Quantity__c = 0;//soli.Quantity - soli.Logistic_Quantity__c;
                    stockwrap.UpdatedOrdList.add(soli);
                }
            }
        }
        if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId)) {
            Set<Id> proIds = new Set<Id>();
            Map<Id, Id> prodMap = new Map<Id, Id>();
            Map<Id, Id> orderItemToBomMap = new Map<Id, Id>();
            List<OrderItem> Ordlist = String.isNotEmpty(orditms) ? (List<OrderItem>) JSON.deserialize(orditms, List<OrderItem>.class) : new List<OrderItem>();
            for (OrderItem Foli : Ordlist) {
                if (!Foli.Inventory_Tracked__c && Foli.Is_Kit__c) {
                    proIds.add(Foli.Product2Id);
                    prodMap.put(Foli.Product2Id, Foli.Id);
                    if (Foli.BOM__c != null) orderItemToBomMap.put(Foli.Id, Foli.BOM__c);
                }
            }

            if (!proIds.isEmpty()) {
                Distribution_Channel__c dchannel = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c 
                                                   FROM Distribution_Channel__c 
                                                   WHERE Id = :DCId AND Channel__c = :chnId AND Site__c != null 
                                                   ORDER BY Priority__c LIMIT 1];
                if (dchannel.Id != null) {
                    // Fetch BOMs with BOM__c filter
                    List<BOM_Line_Item__c> BOMList = [SELECT Id, Name, Active__c, BOM_Alternate_Of__c, BOM_Alternate_Of__r.Type__c, BOM_Alternate_Of__r.Quantity__c, 
                                                     BOM_Alternate_Of__r.BOM_Component__c, BOM_Product__c, BOM__c, BOM_Component__c, BOM_Component__r.Name, 
                                                     BOM_Component__r.Picture__c, BOM_Component__r.Preview_Image__c, Quantity__c, RecordType.Name, 
                                                     BOM__r.Active__c, BOM__r.Category__c, BOM__r.Default__c, BOM__r.Start_Date__c, BOM__r.To_Date__c, 
                                                     BOM__r.Type__c, BOM__r.Status__c 
                                                     FROM BOM_Line_Item__c 
                                                     WHERE Active__c = true AND Type__c != 'Alternate' AND BOM__r.RecordType.Name = 'Kit' 
                                                     AND BOM_Product__c IN :proIds AND BOM__r.Active__c = true 
                                                     AND BOM__r.Start_Date__c <= TODAY AND BOM__r.To_Date__c >= TODAY 
                                                     AND (BOM__r.Type__c = 'Assembly' OR BOM__r.Type__c = 'Sales') AND BOM__r.Status__c = 'Certified' 
                                                     AND BOM__c IN :orderItemToBomMap.values()
                                                     ORDER BY BOM__r.Default__c DESC];
                    
                    Set<Id> BomproductIds = new Set<Id>();
                    for (BOM_Line_Item__c bomItems : BOMList) {
                        BomproductIds.add(bomItems.BOM_Component__c);
                    }

                    Map<Id, List<Inventory_Stock__c>> BOMProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                    for (Inventory_Stock__c WarehouseItemInventoryBOMStocks : [SELECT Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                              Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c
                                                                              FROM Inventory_Stock__c 
                                                                              WHERE product__c IN :BomproductIds 
                                                                              AND Active__c = true AND Number_of_Item_In_Stock__c > 0 
                                                                              AND Warehouse__c = :dchannel.Site__c]) {
                        if (BOMProductMap2Stock.containsKey(WarehouseItemInventoryBOMStocks.product__c)) {
                            BOMProductMap2Stock.get(WarehouseItemInventoryBOMStocks.product__c).add(WarehouseItemInventoryBOMStocks);
                        } else {
                            BOMProductMap2Stock.put(WarehouseItemInventoryBOMStocks.product__c, new List<Inventory_Stock__c>{WarehouseItemInventoryBOMStocks});
                        }
                    }

                    Order orderdetail = [SELECT Id, Name, AccountId, Pricebook2Id, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,
                                        Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, 
                                        Billing_Address_Return__c, Billing_Contact_Return__c
                                        FROM Order WHERE Id = :OrdId LIMIT 1];

                    List<PricebookEntry> pbe = [SELECT UnitPrice, Purchase_Price__c, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Description, 
                                               Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Is_Kit__c, Product2.Picture__c, Product2.Serialise__c, 
                                               Product2.QuantityUnitOfMeasure 
                                               FROM PricebookEntry 
                                               WHERE Pricebook2Id = :orderdetail.Pricebook2Id AND Product2Id IN :BomproductIds AND IsActive = TRUE];
                    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
                    for (PricebookEntry pb : pbe) {
                        pbeMap.put(pb.Product2.Id, pb);
                    }
                    for (BOM_Line_Item__c Boli : BOMList) {
                        system.debug('Boli---' + Boli);
                        bomwrapper bomwrap = new bomwrapper();
                        Decimal proStockCount = 0;
                        if (Boli.BOM_Component__c != null && BOMProductMap2Stock.containsKey(Boli.BOM_Component__c)) {
                            for (Inventory_Stock__c IS : BOMProductMap2Stock.get(Boli.BOM_Component__c)) {
                                proStockCount += IS.Number_of_Item_In_Stock__c;
                            }
                        }
                        bomwrap.stock = proStockCount;
                        bomwrap.BomLM = Boli;
                        if (prodMap.containsKey(Boli.BOM_Product__c)) bomwrap.OrderProdId = prodMap.get(Boli.BOM_Product__c);
                        if (pbeMap.containsKey(Boli.BOM_Component__c)) bomwrap.pbe = pbeMap.get(Boli.BOM_Component__c);
                        stockwrap.UpdatedBomList.add(bomwrap);
                    }
                }
            }
        }
        return stockwrap;
    } catch (Exception e) {
        System.debug('Exception ~> ' + e.getMessage() + '; at line ~> ' + e.getLineNumber() + ' ' + e.getStackTraceString());
        throw new AuraHandledException(e.getMessage() + '; at line ~> ' + e.getStackTraceString());
    }
}*/
    @AuraEnabled
global static stockwrapper getupdatedstocksDCs(String orditms, String chnId, String DCId, String OrdId, String LogItems) { 
    try {
        stockwrapper stockwrap = new stockwrapper();
        List<OrderItem> Ordlist = new List<OrderItem>();
        
        // Handle Logistic Line Items
        if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(LogItems) && LogItems != null && LogItems != '[]') {
            List<Logistic_Line_Item__c> logItemslist = (List<Logistic_Line_Item__c>) JSON.deserialize(LogItems, List<Logistic_Line_Item__c>.class);
            Set<Id> productIds = new Set<Id>();
            for (Logistic_Line_Item__c loli : logItemslist) {
                if (loli.Product__c != null) {
                    productIds.add(loli.Product__c); 
                }
            }
            Distribution_Channel__c dc = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                                                FROM Distribution_Channel__c 
                                                WHERE Id =: DCId AND Channel__c =: chnId AND Site__c != null 
                                                ORDER BY Priority__c LIMIT 1];
            if (dc.Id != null) {
                Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
                for (AggregateResult result : [SELECT Product__c, SUM(Number_of_Item_In_Stock__c) totalStock 
                                              FROM Inventory_Stock__c 
                                              WHERE product__c IN: productIds 
                                              AND Active__c = true 
                                              AND (Number_of_Item_In_Stock__c > 0 OR (Number_of_Item_In_Stock__c < 0 AND Name = 'Serial Stock Holder')) 
                                              AND Warehouse__c =: dc.Site__c 
                                              GROUP BY Product__c]) {
                    Id ProdId = (Id)result.get('Product__c');
                    Decimal totalStock = (Decimal)result.get('totalStock');
                    stockMap.put(ProdId, stockMap.containsKey(ProdId) ? stockMap.get(ProdId) + totalStock : totalStock);
                }
                for (Logistic_Line_Item__c loli : logItemslist) {             
                    Decimal proStockCount = stockMap.containsKey(loli.Product__c) ? stockMap.get(loli.Product__c) : 0;
                    loli.Fulfilled_Quantity__c = proStockCount;
                    stockwrap.UpdatedlogList.add(loli);
                }
            }
        } else if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId) && String.isNotEmpty(orditms)) {
            // Handle Order Items
            Ordlist = (List<OrderItem>) JSON.deserialize(orditms, List<OrderItem>.class);
            List<String> productIds = new List<String>();
            for (OrderItem soli : Ordlist) {
                if (soli.Product2Id != null) {
                    if (!productIds.contains(soli.Product2Id)) {
                        productIds.add(soli.Product2Id);
                    }
                }
            }    
            Distribution_Channel__c dc = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                                                FROM Distribution_Channel__c 
                                                WHERE Id =: DCId AND Channel__c =: chnId AND Site__c != null 
                                                ORDER BY Priority__c LIMIT 1];
            if (dc.Id != null) {
                Map<Id, List<Inventory_Stock__c>> ProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                for (Inventory_Stock__c WarehouseItemInventoryStocks : [SELECT Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                             Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c 
                                                                             FROM Inventory_Stock__c 
                                                                             WHERE product__c IN: productIds 
                                                                             AND Active__c = true 
                                                                             AND (Number_of_Item_In_Stock__c > 0 OR (Number_of_Item_In_Stock__c < 0 AND Name = 'Serial Stock Holder')) 
                                                                             AND Warehouse__c =: dc.Site__c]) {
                    if (ProductMap2Stock.containsKey(WarehouseItemInventoryStocks.product__c)) {
                        ProductMap2Stock.get(WarehouseItemInventoryStocks.product__c).add(WarehouseItemInventoryStocks);
                    } else {
                        List<Inventory_Stock__c> WarehouseItemInventoryStockLists = new List<Inventory_Stock__c>(); 
                        WarehouseItemInventoryStockLists.add(WarehouseItemInventoryStocks); 
                        ProductMap2Stock.put(WarehouseItemInventoryStocks.product__c, WarehouseItemInventoryStockLists);
                    }
                }
                for (OrderItem soli : Ordlist) {                   
                    Decimal proStockCount = 0;
                    if (soli.Product2Id != null && ProductMap2Stock.containsKey(soli.Product2Id)) {
                        for (Inventory_Stock__c IS : ProductMap2Stock.get(soli.Product2Id)) {
                            proStockCount += IS.Number_of_Item_In_Stock__c; 
                        }
                    }
                    soli.Reserved_Quantity__c = proStockCount;
                    soli.Remaining_Quantity__c = soli.Quantity - soli.Logistic_Quantity__c;
                    stockwrap.UpdatedOrdList.add(soli);
                }
            }

            // Check for Explode__c, Stock_Outward_Line_Item__c, and MRP__c
            Set<Id> orderItemIds = new Set<Id>(); 
            for (OrderItem oi : Ordlist) {
                orderItemIds.add(oi.Id);
            }
            Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>([
                SELECT Id, Explode__c 
                FROM OrderItem 
                WHERE Id IN :orderItemIds AND Explode__c = true
            ]);
            List<Stock_Outward_Line_Item__c> stockOutwardItems = [
                SELECT Id, Order_Product__c 
                FROM Stock_Outward_Line_Item__c 
                WHERE Order_Product__c IN :orderItemIds
            ];
            List<MRP__c> mrpRecords = [
                SELECT Id, Order_Product__c 
                FROM MRP__c 
                WHERE Order_Product__c IN :orderItemIds AND RecordType.Name = 'MRP Kit'
            ];
            Map<Id, Boolean> explodedOrderItems = new Map<Id, Boolean>();
            for (Id oiId : orderItemIds) {
                Boolean isExploded = orderItemMap.containsKey(oiId);
                Boolean hasStockOutward = false;
                Boolean hasMRP = false;
                for (Stock_Outward_Line_Item__c soli : stockOutwardItems) {
                    if (soli.Order_Product__c == oiId) {
                        hasStockOutward = true;
                        break;
                    }
                }
                for (MRP__c mrp : mrpRecords) {
                    if (mrp.Order_Product__c == oiId) {
                        hasMRP = true;
                        break;
                    }
                }
                explodedOrderItems.put(oiId, isExploded && hasStockOutward && hasMRP);
            }
            stockwrap.ExplodedOrderItems = explodedOrderItems;

            // Handle BOM for Kits
            if (String.isNotEmpty(chnId) && String.isNotEmpty(DCId)) {
                Set<Id> BomproductIds = new Set<Id>(); 
                List<Id> proIds = new List<Id>(); 
                Map<Id, Decimal> proStocks = new Map<Id, Decimal>(); 
                Set<Id> priceBookIds = new Set<Id>();    
                List<Id> soliBOMVersion = new List<Id>(); 
                Map<Id, Id> prodMap = new Map<Id, Id>();
                
                for (OrderItem Foli : Ordlist) {
                    if (!Foli.Inventory_Tracked__c && Foli.Is_Kit__c) {
                        proIds.add(Foli.Product2Id); 
                        if (Foli.PriceBookId__c != null) priceBookIds.add(Foli.PriceBookId__c); 
                        if (Foli.BOM__c != null) soliBOMVersion.add(Foli.BOM__c);
                        prodMap.put(Foli.Product2Id, Foli.Id);
                    }
                }
                
                List<BOM_Line_Item__c> BOMList = new List<BOM_Line_Item__c>();
                if (proIds.size() > 0) {
                    if (soliBOMVersion != null && !soliBOMVersion.isEmpty()) {
                        BOMList = [
                            SELECT Id, Name, Active__c, BOM_Product__c, BOM_Component__c, Quantity__c,
                                   BOM__c, BOM__r.Status__c, BOM__r.RecordType.Name, 
                                   BOM_Component__r.Name, BOM_Component__r.Picture__c, BOM_Component__r.Preview_Image__c
                            FROM BOM_Line_Item__c
                            WHERE BOM__c IN :soliBOMVersion
                              AND BOM__r.Status__c = 'Certified'
                        ];
                    }
                }
                
                for (BOM_Line_Item__c bomItems : BOMList) { 
                    BomproductIds.add(bomItems.BOM_Component__c); 
                }
                
                Distribution_Channel__c dchannel = [SELECT Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
                                                        FROM Distribution_Channel__c 
                                                        WHERE Id =: DCId AND Channel__c =: chnId AND Site__c != null 
                                                        ORDER BY Priority__c LIMIT 1];
                
                if (dchannel.Id != null) {
                    Map<Id, List<Inventory_Stock__c>> BOMProductMap2Stock = new Map<Id, List<Inventory_Stock__c>>();
                    for (Inventory_Stock__c WarehouseItemInventoryBOMStocks : [SELECT Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, product__c,
                                                                                    Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c 
                                                                                    FROM Inventory_Stock__c 
                                                                                    WHERE product__c IN: BomproductIds 
                                                                                    AND Active__c = true 
                                                                                    AND Number_of_Item_In_Stock__c > 0 
                                                                                    AND Warehouse__c =: dchannel.Site__c]) {
                        if (BOMProductMap2Stock.containsKey(WarehouseItemInventoryBOMStocks.product__c)) {
                            BOMProductMap2Stock.get(WarehouseItemInventoryBOMStocks.product__c).add(WarehouseItemInventoryBOMStocks);
                        } else {
                            List<Inventory_Stock__c> WarehouseItemInventoryStockListsBom = new List<Inventory_Stock__c>(); 
                            WarehouseItemInventoryStockListsBom.add(WarehouseItemInventoryBOMStocks); 
                            BOMProductMap2Stock.put(WarehouseItemInventoryBOMStocks.product__c, WarehouseItemInventoryStockListsBom);
                        }
                    }
                    
                    List<Id> bomprodIds = new List<Id>();
                    for (BOM_Line_Item__c b : BOMList) {
                        bomprodIds.add(b.BOM_Component__c);
                    }
                    
                    Order orderdetail = [SELECT Id, Name, AccountId, Pricebook2Id, Contact__c, Ship_To_Address__c, Channel__c, Ready_To_Pick_Pack__c, Description,
                                       Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c 
                                       FROM Order WHERE Id =: OrdId LIMIT 1];
                    
                    List<PricebookEntry> pbe = [SELECT UnitPrice, Purchase_Price__c, Product2.Id, Product2.Name, Product2.ProductCode, Product2.Description, Product2.BOM__c, Product2.Configure__c, Product2.Allow_Back_Orders__c, Product2.Is_Kit__c, Product2.Picture__c, Product2.Serialise__c, Product2.QuantityUnitOfMeasure 
                                               FROM PricebookEntry 
                                               WHERE Pricebook2Id =: orderdetail.Pricebook2Id 
                                               AND Product2Id IN: bomprodIds 
                                               AND IsActive = TRUE];
                    
                    Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>();
                    for (PricebookEntry pb : pbe) {
                        pbeMap.put(pb.Product2.Id, pb);
                    }
                    
                    List<BOM_Line_Item__c> BOMListFinal = new List<BOM_Line_Item__c>();  
                    for (OrderItem Foli : Ordlist) {
                        if (!Foli.Inventory_Tracked__c && Foli.Is_Kit__c) {
                            for (BOM_Line_Item__c bom : BOMList) {
                                if (bom.BOM_Component__c != null && bom.BOM_Product__c == Foli.Product2Id) {
                                    bom.Quantity__c = bom.Quantity__c * Foli.Quantity;
                                    BOMListFinal.add(bom);
                                }
                            }
                        }
                    }
                    
                    for (BOM_Line_Item__c Boli : BOMList) {
                        bomwrapper bomwrap = new bomwrapper();
                        Decimal proStockCount = 0;
                        if (Boli.BOM_Component__c != null) {
                            if (BOMProductMap2Stock.containsKey(Boli.BOM_Component__c)) {
                                for (Inventory_Stock__c IS : BOMProductMap2Stock.get(Boli.BOM_Component__c)) {
                                    proStockCount += IS.Number_of_Item_In_Stock__c; 
                                }
                            }
                            bomwrap.stock = proStockCount;
                            bomwrap.BomLM = Boli;
                            if (prodMap.containsKey(Boli.BOM_Product__c)) {
                                bomwrap.OrderProdId = prodMap.get(Boli.BOM_Product__c);
                            }
                            if (pbeMap.containsKey(Boli.BOM_Component__c)) {
                                bomwrap.pbe = pbeMap.get(Boli.BOM_Component__c);
                            }
                            stockwrap.UpdatedBomList.add(bomwrap);
                        }
                    }
                }
            }
        }
        return stockwrap;
    } catch (Exception e) {
        System.debug('Exception ~> ' + e.getMessage() + '; at line ~> ' + e.getStackTraceString());
        throw new AuraHandledException(e.getMessage() + '; at line ~> ' + e.getStackTraceString());
    } 
}
     global  class stockwrapper {
        @AuraEnabled global List<OrderItem> UpdatedOrdList { get; set; }
        @AuraEnabled global List<bomwrapper> UpdatedBomList { get; set; }
         @AuraEnabled global List<Logistic_Line_Item__c> UpdatedlogList { get; set; }
         @AuraEnabled public Map<Id, Boolean> ExplodedOrderItems { get; set; }

        global stockwrapper (){
            UpdatedlogList = new List<Logistic_Line_Item__c>();
            UpdatedOrdList = new List<OrderItem>();
            UpdatedBomList = new List<bomwrapper>();
            ExplodedOrderItems = new Map<Id, Boolean>();
        }
    }
        global class bomwrapper{

        @AuraEnabled global Decimal stock                               { get; set; } @AuraEnabled global BOM_Line_Item__c BomLM                            { get; set; }
        @AuraEnabled global Decimal stock1                               { get; set; } @AuraEnabled global BOM__c Bom                            { get; set; }
        @AuraEnabled global PricebookEntry pbe                          { get; set; } @AuraEnabled global Id OrderProdId                              { get; set; }
        global bomwrapper(){     OrderProdId = null;  pbe = new PricebookEntry(); stock=0; BomLM = new BOM_Line_Item__c();
        }
    }

    @AuraEnabled
    global static String getStoreAddress(String chanId){
        String DCId = '';
        list<Distribution_Channel__c> dc = new list<Distribution_Channel__c>();
        dc = [Select Id, Name, Channel__c, Channel__r.Name, Site__c, Active__c
              FROM Distribution_Channel__c
              WHERE Channel__c = :chanId AND Site__c != null
              WITH SECURITY_ENFORCED
              order by createdDate DESC
              limit 100];


        if (dc.size() == 1)
            DCId = dc[0].Id;
        return DCId;
    }

    @AuraEnabled
    global static Logistic_Line_Item__c getLLIInstance(){
        return new Logistic_Line_Item__c();
    }

    @AuraEnabled
    global static Logistic__c getLogisticInstance(){
        return new Logistic__c();
    }
// no calling so commented by matheen on 5-2-25
  @AuraEnabled
   global static String getCreateLogistic(String LogisticJSON, String LLIListJSON){
     return null;
   }
//     @AuraEnabled
// global static String getCreateLogistics(String LogisticJSON, String LLIListJSON,String OrderLIneItems,String BomItems){
//     try{
//         system.debug('getCreateLogistic called');

//         list<OrderItem> Orditem = (OrderLIneItems != null && OrderLIneItems != '') ? (list<OrderItem>) JSON.deserialize(OrderLIneItems, list<OrderItem> .class) : new list<OrderItem>();
//         list<BOM__c> bomitem = (BomItems != null && BomItems != '') ? (list<BOM__c>) JSON.deserialize(BomItems, list<BOM__c> .class) : new list<BOM__c>();

//         Id rTpe_MRPKIT; rTpe_MRPKIT = Schema.SObjectType.MRP__c.getRecordTypeInfosByDeveloperName().get('MRP_Kit').getRecordTypeId();
//         list<MRP__c> MRPS2Insert = new list<MRP__c>();
//         map<string,MRP__c> MRPmap = new map<string,MRP__c>();
//         PreventRecursiveLedgerEntry.testCasesTransactions = true;
//         for(OrderItem orditm:Orditem){ if(orditm.Product2.Is_Kit__c){ for(BOM__c bom:bomitem){ MRP__c MRP = new MRP__c();

//                 }
//             }
//         }

//         upsert MRPS2Insert;
//         system.debug('inside MRP Creation1-->:');

//         for(MRP__c Mrp :MRPS2Insert){ MRPmap.put(Mrp.MRP_Product__c,Mrp);
//         }
//         system.debug('MRPmap:-->'+MRPmap);

//         Logistic__c Logistic = (Logistic__c) JSON.deserialize(LogisticJSON, Logistic__c .class);
//         system.debug('Logistic : '+Logistic.Shipping_Preferences__c);
//         System.debug('Logistic Order : '+Logistic.Order_S__c);
//         Id orderId = Logistic.Order_S__c;
//         String SORecTypeId='';

//         if(String.isNotEmpty(Logistic.Order_S__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Order');
//         if(String.isNotEmpty(Logistic.Purchase_Order__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order');
//         Logistic.RecordTypeId = SORecTypeId;
//         system.debug('RecordTypeId : '+Logistic.RecordTypeId);
//         list<Logistic_Line_Item__c> LogisticLI = (list<Logistic_Line_Item__c>) JSON.deserialize(LLIListJSON, list<Logistic_Line_Item__c> .class);

//         set<String> proList=new set<String>();
//         set<Id> OrderProdIds=new set<Id>();
//         Map<String,Decimal> prodRequestedQtyMap = new Map<String,Decimal>();
//         Map<String,Decimal> OrderRequestedQtyMap = new Map<String,Decimal>();
//         for(Logistic_Line_Item__c log :LogisticLI){
//             if(log.Product__c != null && !proList.contains(log.Product__c)){
//                 proList.add(log.Product__c);
//                 prodRequestedQtyMap.put(log.Product__c,log.Quantity__c);
//             }
//             if(log.Order_Product__c != null) {
//                 OrderProdIds.add(log.Order_Product__c);
//                 OrderRequestedQtyMap.put(log.Order_Product__c,log.Quantity__c);
//             }
//         }
//         //code to check whether the logistic is created or not
//         if (OrderProdIds.size() > 0) {
//             List<OrderItem> ordItemsList = [SELECT Id, OrderItemNumber, Quantity, Is_Kit__c, Logistic_Quantity__c FROM OrderItem WHERE Id IN :OrderProdIds];

//             for (OrderItem ord : ordItemsList) {
//                 if (!ord.Is_Kit__c && OrderRequestedQtyMap.containsKey(ord.Id)) { // added ord.Is_Kit__c on 22_07_24
//                     Decimal logQty = OrderRequestedQtyMap.get(ord.Id);
//                     system.debug('logQty : '+logQty);
//                     if ((logQty + ord.Logistic_Quantity__c) > ord.Quantity) { return 'Logistic cannot be created for more than order quantity';
//                     }
//                 }
//             }
//         }
//         //code to check whether the logistic is created or not ends


//         List<Product2> proList1 = [Select Id,Name,Serialise__c,Lot_Tracked__c,Track_Inventory__c from Product2 where Id In:proList];
//         Map<String,String> proName=new Map<String,String>();
//         Map<String,Boolean> proSerial=new Map<String,Boolean>();

//         for(Product2 pr:proList1){
//             proName.put(pr.Id,pr.Name);
//             proSerial.put(pr.Id,pr.Serialise__c);
//         }

//         Distribution_Channel__c dc = [Select Id,Name,Site__c from Distribution_Channel__c where Id=:Logistic.Distribution_Channel__c Limit 1];
//         List<Manufacturing_Order__c> SOMOs = new List<Manufacturing_Order__c>();
//         List<PO__c> SOPOs = new List<PO__c>();

//         List<Inventory_Stock__c> invtoryList = new List<Inventory_Stock__c>();
//         List<Inventory_Stock__c> MOPOinvtoryList = new List<Inventory_Stock__c>();

//         system.debug('orderId~>'+orderId);
//         if(orderId != null && OrderProdIds.size() > 0 && proList.size() > 0){
//             SOMOs = [Select Id,Name from Manufacturing_Order__c where (Order_Product__c IN:OrderProdIds and Order__c =:orderId) and Product__c IN:proList];
//             System.debug('SOMOs : '+SOMOs.size());

//             SOPOs = [Select Id,Name from PO__c where Order__c =:orderId and Ready_To_Receive__c =:true];
//             System.debug('SOPOs : '+SOPOs.size());
//         }

//         Map<String,List<Inventory_Stock__c>> proInvMap = new Map<String,List<Inventory_Stock__c>>();
//         Map<String,Decimal> prodStockQtyMap = new Map<String,Decimal>();

//         if(SOMOs.size() > 0 || SOPOs.size() > 0){
//             set<Id> MoIds = new set<Id>();set<Id> PoIds = new set<Id>(); set<Id> InvIds = new set<Id>(); for(Manufacturing_Order__c MO : SOMOs) MoIds.add(MO.Id); for(PO__c PO : SOPOs) PoIds.add(PO.Id);
//             system.debug('MoIds ~>'+MoIds);

//             List<Stock_Inward_Line_Item__c> stinlist = [Select Id,Name,Product__c,Site_ProductService_InventoryStock__c from Stock_Inward_Line_Item__c  where Active__c = true and Product__c IN :proList and Scrap__c = false AND (Purchase_Orders__c IN:PoIds or Manufacturing_Order__c IN: MoIds)
//                                                               AND Quantity__c > 0 AND Status__c != 'Awaiting Stock'];

//             for(Stock_Inward_Line_Item__c sin : stinlist) InvIds.add(sin.Site_ProductService_InventoryStock__c);
//             system.debug('MoIds InvIds ~>'+InvIds);

//             MOPOinvtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where product__c != null and Product__c In:proList And Active__c = true And Warehouse__c =:dc.Site__c AND Id IN:InvIds AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 Order By Checked_In_Date__c ASC];

//             system.debug('MOPOinvtoryList~>'+MOPOinvtoryList.size());

//             //below code added by Arshad 09 Aug 23
//             for(Inventory_Stock__c invt:MOPOinvtoryList){ List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>(); if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c);  invlistformap.add(invt); proInvMap.put(invt.Product__c,invlistformap);
//             }

//             for(String key: proInvMap.keyset()){ Decimal Qty = 0;  for(Inventory_Stock__c inv : proInvMap.get(key)){ Qty = Qty + inv.Number_of_Item_In_Stock__c;  } prodStockQtyMap.put(key,Qty);
//             }
//             //
//         }

//         //below code added by Arshad 09 Aug 23
//         Boolean checkInventoryList = false;

//         //First check after MOs/POs
//         for(String key : prodRequestedQtyMap.keyset()){
//             if(prodStockQtyMap.containsKey(key)){
//                 system.debug('prodStockQtyMap.get(key) first check~>'+prodStockQtyMap.get(key));  if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){checkInventoryList = true; break;
//                 }
//             }else{
//                 checkInventoryList = true;
//                 break;
//             }
//         }

//         system.debug('checkInventoryList~>'+checkInventoryList);

//         if(checkInventoryList){
//             system.debug('MOPOinvtoryList size~>'+MOPOinvtoryList.size());

//             if(MOPOinvtoryList.size() > 0){
//                 invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c  AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 AND Id NOT IN:MOPOinvtoryList ORDER BY Checked_In_Date__c ASC];
//             }else{
//                 invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c,
//                                Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c
//                                where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c
//                                AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 ORDER BY Checked_In_Date__c ASC]; //CreatedDate DESC  //Checked_In_Date__c ASC
//             }

//             for(Inventory_Stock__c invt:invtoryList){
//                 List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>();
//                 if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c);
//                 invlistformap.add(invt);
//                 proInvMap.put(invt.Product__c,invlistformap);
//             }

//             for(String key: proInvMap.keyset()){
//                 //system.debug('product key 2~>'+key);
//                 Decimal Qty = 0;
//                 for(Inventory_Stock__c inv : proInvMap.get(key)){
//                     //system.debug('inv map 2~>'+inv.Id);
//                     Qty = Qty + inv.Number_of_Item_In_Stock__c;
//                 }
//                 Decimal totalQty = 0;
//                 if(prodStockQtyMap.containsKey(key)) totalQty = prodStockQtyMap.get(key);
//                 totalQty = totalQty + Qty;
//                 prodStockQtyMap.put(key,totalQty);
//             }
//         }

//         //Second check after MOs/POs inventory & after normal inventorylist
//         if(!String.isNotEmpty(Logistic.Purchase_Order__c)){
//             for(String key : prodRequestedQtyMap.keyset()){
//                 if(prodStockQtyMap.containsKey(key)){
//                     if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){  return 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site';
//                     }
//                 }else{
//                     return 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site';
//                 }
//             }
//         }
//         //above code added by Arshad 09 Aug 23

//         if(String.isNotEmpty(Logistic.Order_S__c)){
//             Order SalOrder=new Order();
//             SalOrder=[SELECT Id, Name, Channel__c, Channel__r.Ship_From_Address__c,Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
//                         FROM Order WHERE Id=:Logistic.Order_S__c];

//             if(SalOrder.Channel__c != null){
//                 if(Logistic.From_Address__c == null && SalOrder.Channel__r.Ship_From_Address__c != null){Logistic.From_Address__c = SalOrder.Channel__r.Ship_From_Address__c;
//                 }
//             }
//             if(Logistic.Shipment_Type__c == null || Logistic.Shipment_Type__c == '') Logistic.Shipment_Type__c = SalOrder.Shipment_Type__c;
//             system.debug('Logistic.Shipment_Type__c : '+Logistic.Shipment_Type__c);
//         } else if(String.isNotEmpty(Logistic.Purchase_Order__c)){String PORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order'); Logistic.RecordTypeId = PORecTypeId;
//         }

//         if(Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable()){
//             //upsert Logistic;
//             if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){
//                 upsert Logistic;
//             }
//         }
//         else{ return 'Don\'t have access to upsert logistic'; }

//         list<String> SOLIIds=new list<String>();
//         list<String> ordItemIds=new list<String>();
//         list<String> POItemIds=new list<String>();

//         for(Logistic_Line_Item__c log:LogisticLI){
//             log.Status__c = 'Reserved';
//             log.Logistic__c = Logistic.Id;

//             if(log.Order_Product__c !=null) ordItemIds.add(log.Order_Product__c);
//             if(log.Purchase_Line_Items__c !=null) POItemIds.add(log.Purchase_Line_Items__c);
//         }

//         if(LogisticLI.size() > 0){
//             System.debug('Your debug message here');

//             if(Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable()){
//                             System.debug('Your');

//                   //upsert LogisticLI;

//                    System.SObjectAccessDecision securtevbsityDecisionv99 = Security.stripInaccessible(AccessType.UPDATABLE, LogisticLI);
//                    List<SObject> accessibleVerhtrssions  = securtevbsityDecisionv99.getRecords();

//                    if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable() &&!accessibleVerhtrssions.isEmpty()) {
//                        // Perform the insert operation with the accessible version
//                        upsert accessibleVerhtrssions[0];
//                    } else {
//                        // Handle the case where FLS validation fails
//                        // You may log an error, throw an exception, or perform other appropriate actions
//                    }//this line  was commented

//                 if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable()){
//                     List<SObject> sObjectsToInsert = new List<SObject>{Logistic};// this line was commented
//                     List<Logistic_Line_Item__c> logToUpsert = (List<Logistic_Line_Item__c>)Security.stripInaccessible(AccessType.UPSERTABLE, LogisticLI).getRecords();
//                     upsert logToUpsert; }  } else{ return 'Does not have access to upsert logistic line items'; }
//         }

//         List<Stock_Outward_Line_Item__c> SWLIToUpsert = new List<Stock_Outward_Line_Item__c>(); Map<Id, Inventory_Stock__c> pliStock = new Map<Id, Inventory_Stock__c>();
//         Map<Id, Stock_Outward_Line_Item__c> pliStockInward = new Map<Id, Stock_Outward_Line_Item__c>(); List<Inventory_Stock__c> Inventory2Upsert = new List<Inventory_Stock__c>();
//         //changed below code Arshad 09 Aug 23
//         for(Logistic_Line_Item__c log:LogisticLI){if(log.Product__c != null && log.Quantity__c > 0 && ((Logistic.Order_S__c != null && log.Order_Product__c != null))){if(Logistic.Purchase_Order__c == null && proInvMap.containsKey(log.Product__c) && proSerial.containsKey(log.Product__c)){
//                     Decimal remainintQty = log.Quantity__c;

//                     for(Inventory_Stock__c inv : proInvMap.get(log.Product__c)){ if(remainintQty > 0){ Decimal qtytoprocess = 0;
//                             if(proSerial.get(log.Product__c)){ Inventory_Stock__c inv2Create = new Inventory_Stock__c(Active__c = true, Product__c = log.Product__c, Name = 'Serial Stock Holder', Warehouse__c = dc.Site__c);Inventory2Upsert.add(inv2Create);
//                                 system.debug('inhere serial'); qtytoprocess = 0; Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = 'Serial Stock Holder';  sto.Product__c = log.Product__c;   sto.Active__c = true;  sto.Status__c = 'Reserved';


//                                 if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c; if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c;
//                                 sto.Logistic_Line_Item__c = log.Id; sto.Quantity__c = remainintQty; SWLIToUpsert.add(sto); pliStock.put(log.Id,inv2Create);pliStockInward.put(log.Id,sto); remainintQty = 0;
//                                 system.debug('qtytoprocess~>'+qtytoprocess);
//                                 system.debug('remainintQty~>'+remainintQty);
//                             }
//                             else{
//                                 system.debug('inhere non serial inv.Number_of_Item_In_Stock__c~>'+inv.Number_of_Item_In_Stock__c);
//                                 if(inv.Number_of_Item_In_Stock__c < remainintQty){
//                                     system.debug('inhere inv.Number_of_Item_In_Stock__c < remainintQty');
//                                     qtytoprocess = inv.Number_of_Item_In_Stock__c; remainintQty = remainintQty - inv.Number_of_Item_In_Stock__c;
//                                 }else{
//                                     system.debug('inhere else inv.Number_of_Item_In_Stock__c >= remainintQty');
//                                     qtytoprocess = remainintQty; remainintQty = remainintQty - qtytoprocess;
//                                 }
//                                 system.debug('qtytoprocess~>'+qtytoprocess);
//                                 system.debug('remainintQty~>'+remainintQty);
//                             }

//                             if(qtytoprocess > 0){ Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = log.Name;


//                                 if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c;  if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c;

//                                 sto.Product__c = log.Product__c;  sto.Active__c = true;  sto.Status__c = 'Reserved';

//                                 if(proSerial.get(log.Product__c)) sto.Quantity__c = 1; else sto.Quantity__c = qtytoprocess;

//                                 system.debug('inv.Id for stock outward~>'+inv.Id);
//                                 sto.Site_Product_Service_Inventory_Stock__c = inv.Id;  sto.Logistic_Line_Item__c = log.Id;

//                                 if(MRPmap.containsKey(log.Product__c)) sto.MRP_Material_Requirements_Planning__c = MRPmap.get(log.Product__c).Id;

//                                 system.debug('inv.Serial__c~>'+inv.Serial__c);

//                                 if(inv.Serial__c != null) sto.Serial__c = inv.Serial__c; if(inv.Batch_Lot__c != null) sto.Material_Batch_Lot__c = inv.Batch_Lot__c; SWLIToUpsert.add(sto);
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//         //

//         system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size());

//         //There was a block of code here in previous method, commented that as not needed - Arshad 10 Aug 23
//         if(Inventory2Upsert.size() > 0) insert Inventory2Upsert; for(Id pliId : pliStockInward.KeySet()){ pliStockInward.get(pliId).Site_Product_Service_Inventory_Stock__c= pliStock.get(pliId).Id;
//         }

//         if(SWLIToUpsert.size() > 0){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()) {
//                 system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size());
//                 upsert SWLIToUpsert;  }  else{ return 'Don\'t have access to upsert Stock Outward'; }
//         }

//         if(POItemIds.size() > 0){
//             list<Logistic_Line_Item__c> LogLIList=new list<Logistic_Line_Item__c>(); LogLIList=[SELECT Id, Name, Quantity__c, Purchase_Line_Items__c FROM Logistic_Line_Item__c WHERE Purchase_Line_Items__c IN:POItemIds];
//             list<Purchase_Line_Items__c> poliItems2Update = new List<Purchase_Line_Items__c>();
//             for(Purchase_Line_Items__c poli:[SELECT Id, Logistic_Quantity__c FROM Purchase_Line_Items__c WHERE Id IN:POItemIds]){
//                 Decimal LogQuantity=0;
//                 for(Logistic_Line_Item__c logLi:LogLIList)
//                 {
//                     if(logLi.Purchase_Line_Items__c==poli.Id) LogQuantity+=logLi.Quantity__c;
//                 }
//                if(Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isUpdateable()) poli.Logistic_Quantity__c=LogQuantity;
//                 poliItems2Update.add(poli);
//             }
//             try{  if(poliItems2Update.size() > 0 && Schema.sObjectType.Purchase_Line_Items__c.isUpdateable())  { update poliItems2Update; } else{ return 'User is not allowed to update POLI'; } }catch(DMLException e){return e.getMessage() +','+e.getStackTraceString();}

//         }

//         return null;
//     }catch(Exception e){
//         System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
//         throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
//     }
// }


@AuraEnabled
global static String getCreateLogistics(String LogisticJSON, String LLIListJSON,String OrderLIneItems,String BomItems){
    try{
        system.debug('getCreateLogistic called');

        list<OrderItem> Orditem = (OrderLIneItems != null && OrderLIneItems != '') ? (list<OrderItem>) JSON.deserialize(OrderLIneItems, list<OrderItem> .class) : new list<OrderItem>();
        list<BOM_Line_Item__c> bomitem = (BomItems != null && BomItems != '') ? (list<BOM_Line_Item__c>) JSON.deserialize(BomItems, list<BOM_Line_Item__c> .class) : new list<BOM_Line_Item__c>();

        Id rTpe_MRPKIT; rTpe_MRPKIT = Schema.SObjectType.MRP__c.getRecordTypeInfosByDeveloperName().get('MRP_Kit').getRecordTypeId();
        list<MRP__c> MRPS2Insert = new list<MRP__c>();
        map<string,MRP__c> MRPmap = new map<string,MRP__c>();
        PreventRecursiveLedgerEntry.testCasesTransactions = true;
        for(OrderItem orditm:Orditem){ if(orditm.Product2.Is_Kit__c){ for(BOM_Line_Item__c bom:bomitem){ MRP__c MRP = new MRP__c();

                }
            }
        }

        upsert MRPS2Insert;
        system.debug('inside MRP Creation1-->:');

        for(MRP__c Mrp :MRPS2Insert){ MRPmap.put(Mrp.MRP_Product__c,Mrp);
        }
        system.debug('MRPmap:-->'+MRPmap);

        Logistic__c Logistic = (Logistic__c) JSON.deserialize(LogisticJSON, Logistic__c .class);
        system.debug('Logistic : '+Logistic.Shipping_Preferences__c);
        System.debug('Logistic Order : '+Logistic.Order_S__c);
        Id orderId = Logistic.Order_S__c;
        String SORecTypeId='';

        if(String.isNotEmpty(Logistic.Order_S__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Order');
        if(String.isNotEmpty(Logistic.Purchase_Order__c)) SORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order');
        Logistic.RecordTypeId = SORecTypeId;
        system.debug('RecordTypeId : '+Logistic.RecordTypeId);
        list<Logistic_Line_Item__c> LogisticLI = (list<Logistic_Line_Item__c>) JSON.deserialize(LLIListJSON, list<Logistic_Line_Item__c> .class);
        List<Logistic_Line_Item__c> typeLogisticLI = new List<Logistic_Line_Item__c>();

        set<String> proList=new set<String>();
        set<Id> OrderProdIds=new set<Id>();
        Map<String,Decimal> prodRequestedQtyMap = new Map<String,Decimal>();
        Map<String,Decimal> OrderRequestedQtyMap = new Map<String,Decimal>();
        for(Logistic_Line_Item__c log :LogisticLI){
            if(log.Product__c != null && !proList.contains(log.Product__c)){
                proList.add(log.Product__c);
                prodRequestedQtyMap.put(log.Product__c,log.Quantity__c);
            }
            if(log.Order_Product__c != null) {
                OrderProdIds.add(log.Order_Product__c);
                OrderRequestedQtyMap.put(log.Order_Product__c,log.Quantity__c);
            }
        }
        //code to check whether the logistic is created or not
        if (OrderProdIds.size() > 0) {
            List<OrderItem> ordItemsList = [SELECT Id, OrderItemNumber, Quantity, Is_Kit__c, Logistic_Quantity__c FROM OrderItem WHERE Id IN :OrderProdIds];

            for (OrderItem ord : ordItemsList) {
                if (!ord.Is_Kit__c && OrderRequestedQtyMap.containsKey(ord.Id)) { // added ord.Is_Kit__c on 22_07_24
                    Decimal logQty = OrderRequestedQtyMap.get(ord.Id);
                    system.debug('logQty : '+logQty);
                    if ((logQty + ord.Logistic_Quantity__c) > ord.Quantity) { return 'Logistic cannot be created for more than order quantity';
                    }
                }
            }
        }
        //code to check whether the logistic is created or not ends


        List<Product2> proList1 = [Select Id,Name,Serialise__c,Lot_Tracked__c,Track_Inventory__c from Product2 where Id In:proList];
        Map<String,String> proName=new Map<String,String>();
        Map<String,Boolean> proSerial=new Map<String,Boolean>();

        for(Product2 pr:proList1){
            proName.put(pr.Id,pr.Name);
            proSerial.put(pr.Id,pr.Serialise__c);
        }

        Distribution_Channel__c dc = [Select Id,Name,Site__c from Distribution_Channel__c where Id=:Logistic.Distribution_Channel__c Limit 1];
        List<Manufacturing_Order__c> SOMOs = new List<Manufacturing_Order__c>();
        List<PO__c> SOPOs = new List<PO__c>();

        List<Inventory_Stock__c> invtoryList = new List<Inventory_Stock__c>();
        List<Inventory_Stock__c> MOPOinvtoryList = new List<Inventory_Stock__c>();

        system.debug('orderId~>'+orderId);
        if(orderId != null && OrderProdIds.size() > 0 && proList.size() > 0){
            SOMOs = [Select Id,Name from Manufacturing_Order__c where (Order_Product__c IN:OrderProdIds and Order__c =:orderId) and Product__c IN:proList];
            System.debug('SOMOs : '+SOMOs.size());

            SOPOs = [Select Id,Name from PO__c where Order__c =:orderId and Ready_To_Receive__c =:true];
            System.debug('SOPOs : '+SOPOs.size());
        }

        Map<String,List<Inventory_Stock__c>> proInvMap = new Map<String,List<Inventory_Stock__c>>();
        Map<String,Decimal> prodStockQtyMap = new Map<String,Decimal>();

        if(SOMOs.size() > 0 || SOPOs.size() > 0){
            set<Id> MoIds = new set<Id>();set<Id> PoIds = new set<Id>(); set<Id> InvIds = new set<Id>(); for(Manufacturing_Order__c MO : SOMOs) MoIds.add(MO.Id); for(PO__c PO : SOPOs) PoIds.add(PO.Id);
            system.debug('MoIds ~>'+MoIds);

            List<Stock_Inward_Line_Item__c> stinlist = [Select Id,Name,Product__c,Site_ProductService_InventoryStock__c from Stock_Inward_Line_Item__c  where Active__c = true and Product__c IN :proList and Scrap__c = false AND (Purchase_Orders__c IN:PoIds or Manufacturing_Order__c IN: MoIds)
                                                              AND Quantity__c > 0 AND Status__c != 'Awaiting Stock'];

            for(Stock_Inward_Line_Item__c sin : stinlist) InvIds.add(sin.Site_ProductService_InventoryStock__c);
            system.debug('MoIds InvIds ~>'+InvIds);

            MOPOinvtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where product__c != null and Product__c In:proList And Active__c = true And Warehouse__c =:dc.Site__c AND Id IN:InvIds AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 Order By Checked_In_Date__c ASC];

            system.debug('MOPOinvtoryList~>'+MOPOinvtoryList.size());

            //below code added by Arshad 09 Aug 23
            for(Inventory_Stock__c invt:MOPOinvtoryList){ List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>(); if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c);  invlistformap.add(invt); proInvMap.put(invt.Product__c,invlistformap);
            }

            for(String key: proInvMap.keyset()){ Decimal Qty = 0;  for(Inventory_Stock__c inv : proInvMap.get(key)){ Qty = Qty + inv.Number_of_Item_In_Stock__c;  } prodStockQtyMap.put(key,Qty);
            }
            //
        }

        //below code added by Arshad 09 Aug 23
        Boolean checkInventoryList = false;

        //First check after MOs/POs
        for(String key : prodRequestedQtyMap.keyset()){
            if(prodStockQtyMap.containsKey(key)){
                system.debug('prodStockQtyMap.get(key) first check~>'+prodStockQtyMap.get(key));  if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){checkInventoryList = true; break;
                }
            }else{
                checkInventoryList = true;
                break;
            }
        }

        system.debug('checkInventoryList~>'+checkInventoryList);

        if(checkInventoryList){
            system.debug('MOPOinvtoryList size~>'+MOPOinvtoryList.size());

            if(MOPOinvtoryList.size() > 0){
                invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c  AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 AND Id NOT IN:MOPOinvtoryList ORDER BY Checked_In_Date__c ASC];
            }else{
                invtoryList = [Select Id,Name,Product__c,Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, Number_of_Item_In_Stock__c,
                               Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c  from Inventory_Stock__c
                               where product__c != null AND product__c In:proList And Active__c = true AND Warehouse__c =:dc.Site__c
                               AND Name != 'Awaiting Stock' And Number_of_Item_In_Stock__c > 0 ORDER BY Checked_In_Date__c ASC]; //CreatedDate DESC  //Checked_In_Date__c ASC
            }

            for(Inventory_Stock__c invt:invtoryList){
                List<Inventory_Stock__c> invlistformap = new List<Inventory_Stock__c>();
                if(proInvMap.containsKey(invt.Product__c)) invlistformap = proInvMap.get(invt.Product__c);
                invlistformap.add(invt);
                proInvMap.put(invt.Product__c,invlistformap);
            }

            for(String key: proInvMap.keyset()){
                //system.debug('product key 2~>'+key);
                Decimal Qty = 0;
                for(Inventory_Stock__c inv : proInvMap.get(key)){
                    //system.debug('inv map 2~>'+inv.Id);
                    Qty = Qty + inv.Number_of_Item_In_Stock__c;
                }
                Decimal totalQty = 0;
                if(prodStockQtyMap.containsKey(key)) totalQty = prodStockQtyMap.get(key);
                totalQty = totalQty + Qty;
                prodStockQtyMap.put(key,totalQty);
            }
        }

        //Second check after MOs/POs inventory & after normal inventorylist
        if(!String.isNotEmpty(Logistic.Purchase_Order__c)){
            for(String key : prodRequestedQtyMap.keyset()){
                if(prodStockQtyMap.containsKey(key)){
                    if(prodStockQtyMap.get(key) < prodRequestedQtyMap.get(key)){  return 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site';
                    }
                }else{
                    return 'Does not have inventory for product :'+proName.get(key)+' on selected distribution Centers site';
                }
            }
        }
        //above code added by Arshad 09 Aug 23

        if(String.isNotEmpty(Logistic.Order_S__c)){
            Order SalOrder=new Order();
            SalOrder=[SELECT Id, Name, Channel__c, Channel__r.Ship_From_Address__c,Shipment_Type__c, Shipment_Preference_Speed__c, BillToContactId, Bill_To_Address__c, Bill_To_Return__c, Billing_Account_Number_Return__c, Billing_Address_Return__c, Billing_Contact_Return__c
                        FROM Order WHERE Id=:Logistic.Order_S__c];

            if(SalOrder.Channel__c != null){
                if(Logistic.From_Address__c == null && SalOrder.Channel__r.Ship_From_Address__c != null){Logistic.From_Address__c = SalOrder.Channel__r.Ship_From_Address__c;
                }
            }
            if(Logistic.Shipment_Type__c == null || Logistic.Shipment_Type__c == '') Logistic.Shipment_Type__c = SalOrder.Shipment_Type__c;
            system.debug('Logistic.Shipment_Type__c : '+Logistic.Shipment_Type__c);
        } else if(String.isNotEmpty(Logistic.Purchase_Order__c)){String PORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','Purchase_Order'); Logistic.RecordTypeId = PORecTypeId;
        }

        if(Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable()){
            //upsert Logistic;
            if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){
                upsert Logistic;
            }
        }
        else{ return 'Don\'t have access to upsert logistic'; }

        list<String> SOLIIds=new list<String>();
        list<String> ordItemIds=new list<String>();
        list<String> POItemIds=new list<String>();


        for(Logistic_Line_Item__c log:LogisticLI){
            String Name = log.Name;
            if(Name.length() > 80) log.Name = Name.subString(0,79);
            log.Status__c = 'Reserved';
            log.Logistic__c = Logistic.Id;

            if(log.Order_Product__c !=null) ordItemIds.add(log.Order_Product__c);
            if(log.Purchase_Line_Items__c !=null) POItemIds.add(log.Purchase_Line_Items__c);
        }

        // if(LogisticLI.size() > 0){
        //     System.debug('Your debug message here');

        //     if(Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable()){
        //                     System.debug('Your');

        //           //upsert LogisticLI;

        //            System.SObjectAccessDecision securtevbsityDecisionv99 = Security.stripInaccessible(AccessType.UPDATABLE, LogisticLI);
        //            List<SObject> accessibleVerhtrssions  = securtevbsityDecisionv99.getRecords();

        //            if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable() &&!accessibleVerhtrssions.isEmpty()) {
        //                // Perform the insert operation with the accessible version
        //                upsert accessibleVerhtrssions[0];
        //            } else {
        //                // Handle the case where FLS validation fails
        //                // You may log an error, throw an exception, or perform other appropriate actions
        //            }//this line  was commented

        //         if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable()){
        //             List<SObject> sObjectsToInsert = new List<SObject>{Logistic};// this line was commented
        //             List<Logistic_Line_Item__c> logToUpsert = (List<Logistic_Line_Item__c>)Security.stripInaccessible(AccessType.UPSERTABLE, LogisticLI).getRecords();
        //             upsert logToUpsert; }  } else{ return 'Does not have access to upsert logistic line items'; }
        // }
        // commented from 1270 - 1293 and 1294 - 1299 added by matheen 5 feb 25 to fix the logistic line items getting created twice
            if(LogisticLI.size() > 0){
                if(Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable()){
                    // upsert LogisticLI;
                    List<SObject> safeLogisticLI = FLSHelper.getSafeRecords(
                        LogisticLI,
                        'Logistic_Line_Item__c',
                        AccessType.UPDATABLE
                    );

                    for (SObject s : safeLogisticLI) {
                        typeLogisticLI.add((Logistic_Line_Item__c)s);
                    }
                    if (!typeLogisticLI.isEmpty()) {
                        upsert typeLogisticLI; // or insert/update as needed
                    }
                } else{ return 'Does not have access to upsert logistic line items'; }
            }
        List<Stock_Outward_Line_Item__c> SWLIToUpsert = new List<Stock_Outward_Line_Item__c>(); Map<Id, Inventory_Stock__c> pliStock = new Map<Id, Inventory_Stock__c>();
        Map<Id, Stock_Outward_Line_Item__c> pliStockInward = new Map<Id, Stock_Outward_Line_Item__c>(); List<Inventory_Stock__c> Inventory2Upsert = new List<Inventory_Stock__c>();
        //changed below code Arshad 09 Aug 23
        for(Logistic_Line_Item__c log:typeLogisticLI){if(log.Product__c != null && log.Quantity__c > 0 && ((Logistic.Order_S__c != null && log.Order_Product__c != null))){if(Logistic.Purchase_Order__c == null && proInvMap.containsKey(log.Product__c) && proSerial.containsKey(log.Product__c)){
                    Decimal remainintQty = log.Quantity__c;

                    for(Inventory_Stock__c inv : proInvMap.get(log.Product__c)){ if(remainintQty > 0){ Decimal qtytoprocess = 0;
                            if(proSerial.get(log.Product__c)){ Inventory_Stock__c inv2Create = new Inventory_Stock__c(Active__c = true, Product__c = log.Product__c, Name = 'Serial Stock Holder', Warehouse__c = dc.Site__c);Inventory2Upsert.add(inv2Create);
                                system.debug('inhere serial'); qtytoprocess = 0; Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = 'Serial Stock Holder';  sto.Product__c = log.Product__c;   sto.Active__c = true;  sto.Status__c = 'Reserved';


                                if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c; if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c;
                                sto.Logistic_Line_Item__c = log.Id; sto.Quantity__c = remainintQty; SWLIToUpsert.add(sto); pliStock.put(log.Id,inv2Create);pliStockInward.put(log.Id,sto); remainintQty = 0;
                                system.debug('qtytoprocess~>'+qtytoprocess);
                                system.debug('remainintQty~>'+remainintQty);
                            }
                            else{
                                system.debug('inhere non serial inv.Number_of_Item_In_Stock__c~>'+inv.Number_of_Item_In_Stock__c);
                                if(inv.Number_of_Item_In_Stock__c < remainintQty){
                                    system.debug('inhere inv.Number_of_Item_In_Stock__c < remainintQty');
                                    qtytoprocess = inv.Number_of_Item_In_Stock__c; remainintQty = remainintQty - inv.Number_of_Item_In_Stock__c;
                                }else{
                                    system.debug('inhere else inv.Number_of_Item_In_Stock__c >= remainintQty');
                                    qtytoprocess = remainintQty; remainintQty = remainintQty - qtytoprocess;
                                }
                                system.debug('qtytoprocess~>'+qtytoprocess);
                                system.debug('remainintQty~>'+remainintQty);
                            }

                            if(qtytoprocess > 0){ Stock_Outward_Line_Item__c sto = new Stock_Outward_Line_Item__c(); sto.Name = log.Name;


                                if(log.Order_Product__c != null) sto.Order_Product__c = log.Order_Product__c;  if(Logistic.Order_S__c != null) sto.Order__c = Logistic.Order_S__c;

                                sto.Product__c = log.Product__c;  sto.Active__c = true;  sto.Status__c = 'Reserved';

                                if(proSerial.get(log.Product__c)) sto.Quantity__c = 1; else sto.Quantity__c = qtytoprocess;

                                system.debug('inv.Id for stock outward~>'+inv.Id);
                                sto.Site_Product_Service_Inventory_Stock__c = inv.Id;
                                                 system.debug('log.Id for stock outward~>'+log.Id);
                                                 sto.Logistic_Line_Item__c = log.Id;

                                if(MRPmap.containsKey(log.Product__c)) sto.MRP_Material_Requirements_Planning__c = MRPmap.get(log.Product__c).Id;

                                system.debug('inv.Serial__c~>'+inv.Serial__c);

                                if(inv.Serial__c != null) sto.Serial__c = inv.Serial__c; if(inv.Batch_Lot__c != null) sto.Material_Batch_Lot__c = inv.Batch_Lot__c; SWLIToUpsert.add(sto);
                            }
                        }
                    }
                }
            }
        }
        //

        system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size());

        //There was a block of code here in previous method, commented that as not needed - Arshad 10 Aug 23
        if(Inventory2Upsert.size() > 0) insert Inventory2Upsert; for(Id pliId : pliStockInward.KeySet()){ pliStockInward.get(pliId).Site_Product_Service_Inventory_Stock__c= pliStock.get(pliId).Id;
        }

        if(SWLIToUpsert.size() > 0){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()) {
                system.debug('SWLIToUpsert size~>'+SWLIToUpsert.size());
                upsert SWLIToUpsert;   for(Stock_Outward_Line_Item__c soli : SWLIToUpsert) {
            System.debug('Upserted SOLI ID: ' + soli.Id);
        }}  else{ return 'Don\'t have access to upsert Stock Outward'; }
        }

        if(POItemIds.size() > 0){
            list<Logistic_Line_Item__c> LogLIList=new list<Logistic_Line_Item__c>(); LogLIList=[SELECT Id, Name, Quantity__c, Purchase_Line_Items__c FROM Logistic_Line_Item__c WHERE Purchase_Line_Items__c IN:POItemIds];
            list<Purchase_Line_Items__c> poliItems2Update = new List<Purchase_Line_Items__c>();
            for(Purchase_Line_Items__c poli:[SELECT Id, Logistic_Quantity__c FROM Purchase_Line_Items__c WHERE Id IN:POItemIds]){
                Decimal LogQuantity=0;
                for(Logistic_Line_Item__c logLi:LogLIList)
                {
                    if(logLi.Purchase_Line_Items__c==poli.Id) LogQuantity+=logLi.Quantity__c;
                }
               if(Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isUpdateable()) poli.Logistic_Quantity__c=LogQuantity;
                poliItems2Update.add(poli);
            }
            try{  if(poliItems2Update.size() > 0 && Schema.sObjectType.Purchase_Line_Items__c.isUpdateable())  { update poliItems2Update; } else{ return 'User is not allowed to update POLI'; } }catch(DMLException e){return e.getMessage() +','+e.getStackTraceString();}

        }

        return null;
    }catch(Exception e){
        System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
        throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
    }
}
    @AuraEnabled
    global Static list<LogisticWrap> getLogisticExisting(String SOId, String OrderId, String POId){
        list<LogisticWrap> LogisticList = new list<LogisticWrap>();
        if (String.isNotEmpty(OrderId)){
            list<Logistic__c> LogList = [SELECT Id, Name, Active__c, Account__c, Account__r.Name, Contact__c, Contact__r.Name, To_Address__c, To_Address__r.Name, Ready_To_Ship__c
                                         FROM Logistic__c
                                         WHERE Order_S__c = :OrderId AND Active__c = true
                                         WITH SECURITY_ENFORCED
                                         order by createdDate ASC
                                         limit 100];


            for (Logistic__c log : LogList){
                LogisticWrap w = new LogisticWrap();
                w.Id = log.Id;
                w.Name = log.Name;
                w.Account = log.Account__r.Name;
                w.Contact = log.Contact__r.Name;
                w.ToAddress = log.To_Address__r.Name;
                w.ReadyToShip = log.Ready_To_Ship__c;
                LogisticList.add(w);
            }
            return LogisticList;
        }
        else if (String.isNotEmpty(POId)){
            list<Logistic__c> LogList = [SELECT Id, Name, Active__c, Account__c, Account__r.Name, Contact__c, Contact__r.Name, To_Address__c, To_Address__r.Name, Ready_To_Ship__c FROM Logistic__c
                                         WHERE Purchase_Order__c = :POId AND Active__c = true WITH SECURITY_ENFORCED order by createdDate ASC limit 100];


            for (Logistic__c log : LogList){
                LogisticWrap w = new LogisticWrap();
                w.Id = log.Id;
                w.Name = log.Name;
                w.Account = log.Account__r.Name;
                w.Contact = log.Contact__r.Name;
                w.ToAddress = log.To_Address__r.Name;
                w.ReadyToShip = log.Ready_To_Ship__c;
                LogisticList.add(w);
            }
            return LogisticList;
        } else
            return null;
    }

    global class LogisticWrap{
        @AuraEnabled
        global String Id{ get; set; }

        @AuraEnabled
        global String Name{ get; set; }

        @AuraEnabled
        global String Account{ get; set; }

        @AuraEnabled
        global String Contact{ get; set; }

        @AuraEnabled
        global String ToAddress{ get; set; }

        @AuraEnabled
        global Boolean ReadyToShip{ get; set; }

        global LogisticWrap(){
            Name = Account = Contact = ToAddress = '';
            ReadyToShip = false;
        }

    }

    // For dependent Picklist
    global static final String base64Chars = '' +
                                         'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
                                         'abcdefghijklmnopqrstuvwxyz' +
                                         '0123456789+/';
    @AuraEnabled
    global static PicklistWrapper getDependentPicklist(String ObjectName, string parentField, string childField) {
        System.debug('ObjectName : '+ObjectName);
        System.debug('parentField: '+parentField);
        System.debug('childField: '+childField);
        Map<String,List<SelectOption>> pickListMaps = new Map<String,List<SelectOption>>();
        PicklistWrapper pw = new PicklistWrapper();
        pw.pickListMaps = pickListMaps;
        List<SelectOption> controllingValues = new List<SelectOption>();

        if (Schema.getGlobalDescribe().get(ObjectName) ==null || String.isBlank(parentField) || String.isBlank(ChildField)){  return pw; }

        Schema.sObjectType objType = Schema.getGlobalDescribe().get(ObjectName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(parentField) || !objFieldMap.containsKey(childField)){ return pw;
        }

        List<PicklistEntryWrapper> depEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objFieldMap.get(ChildField).getDescribe().getPicklistValues()), List<PicklistEntryWrapper>.class);



        for (Schema.PicklistEntry ple : objFieldMap.get(parentField).getDescribe().getPicklistValues()) {
            system.debug('arshad ple~>'+ple);
            pickListMaps.put(ple.getLabel(), new List<SelectOption>());
            controllingValues.add(new SelectOption(ple.getValue(),ple.getLabel()));
        }

        for (PicklistEntryWrapper plew : depEntries) {
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    if(controllingValues.get(i).label != System.label.NonePicklistType){
                        pickListMaps.get(controllingValues.get(i).label).add(new SelectOption(plew.value,plew.label));
                        system.debug(controllingValues.get(i).label+ pickListMaps.get(controllingValues.get(i).label));
                    }
                }
            }
        }

        if(controllingValues.size() > 0){
            controllingValues.add(0,new SelectOption('',System.label.NonePicklistType));
        }

        pw.controllingValues = controllingValues;
        pw.pickListMaps = pickListMaps;
        pw.parentFieldLabel = objFieldMap.get(parentField).getDescribe().getLabel();
        pw.childFieldLabel = objFieldMap.get(childField).getDescribe().getLabel();
        return pw;
    }

    global static String base64ToBits(String validFor){
        if (String.isEmpty(validFor))return '';
        String validForBits = '';
        for (Integer i = 0; i < validFor.length(); i++){
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        return validForBits;
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

   global class PicklistWrapper{
       @AuraEnabled
        global Map<String, List<String>> pickListMap;
        @AuraEnabled
        global Map<String, List<SelectOption>> pickListMaps;
        @AuraEnabled
        global List<SelectOption> controllingValues;
        @AuraEnabled
        global String parentFieldLabel;
        @AuraEnabled
        global String childFieldLabel;
    }

    global class PicklistEntryWrapper{
        global String active;
        global String defaultValue;
        global String label;
        global String value;
        global String validFor;

    }


}