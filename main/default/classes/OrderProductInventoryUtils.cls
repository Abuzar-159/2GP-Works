global with sharing class OrderProductInventoryUtils{
    global static void createProductPurchaseLineItems(set<Id> lineItemIds){
        system.debug('OrderProductInventoryUtils createProductPurchaseLineItems is called');
        System.debug('lineItemIds:'+lineItemIds);
        System.debug('PreventRecursiveLedgerEntry.SOLI_AllocateStock:'+PreventRecursiveLedgerEntry.SOLI_AllocateStock);
        if(PreventRecursiveLedgerEntry.SOLI_AllocateStock){
            PreventRecursiveLedgerEntry.SOLI_AllocateStock = false;
            //Set<Id> lineItemIds = new Set<Id>();
            List<Manufacturing_Order__c> SOMOs = new List<Manufacturing_Order__c>();
            List<PO__c> SOPOs = new List<PO__c>();
            Set<Id> salepointIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> assetIds = new Set<Id>();
            Set<Id> orderIds= new Set<Id>();
            Set<Id> allSalepointSiteIds = new Set<Id>();
            Map<Id, Set<Id>> salepointSites = new Map<Id, Set<Id>>();
            Map<Id, Set<Inventory_Stock__c>> productSites = new Map<Id, Set<Inventory_Stock__c>>();
            Map<Id, List<Stock_Outward_Line_Item__c>> existingSoliAndSOWMap = new Map<Id, List<Stock_Outward_Line_Item__c>>();
            List<Stock_Outward_Line_Item__c> existingSOWList = new List<Stock_Outward_Line_Item__c>();
            
            List<OrderItem> currentLineItems;
            
            if(Schema.sObjectType.OrderItem.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Base_Price__c','Discount_Amount__c','Invoice__c','UnitPrice','Total_Price__c','VAT_Amount__c', 'Inventory_Tracked__c','Product2Id','Quantity','OrderId','Loyalty_Points__c','Loyalty_Program__c','Checked_Out_Process__c','Commission__c','Commission_Rate_Card__c','Status__c'},'OrderItem');
                UtilClass.FlsCheck(new String[]{'Sub_Total__c','Total_Discount__c','Total_Due__c','Total_Tax_Amount__c','Channel__c','Stage__c','Is_Back_Order__c'},'Order');
                UtilClass.FlsCheck(new String[]{'SKU__c','Track_Inventory__c'},'Product__c');
                if(!Schema.sObjectType.Commission_Rate_Card__c.fields.Commission_Plan__c.isAccessible()) return ;
                
                currentLineItems = [Select Id, Base_Price__c, Discount_Amount__c, Invoice__c, UnitPrice, Total_Price__c, VAT_Amount__c,  Inventory_Tracked__c, Company__c,Organisation_Business_Unit__c,
                                    Product2Id, Product2.Name, Product2.SKU__c, Quantity, OrderId, Loyalty_Points__c, Loyalty_Program__c, Checked_Out_Process__c, Is_Back_Order__c, Is_Pre_Order__c,
                                    Order.Name, Order.Sub_Total__c, Order.Total_Discount__c, Order.Total_Due__c, Order.Total_Tax_Amount__c, Commission__c, Commission_Rate_Card__c,
                                    Commission_Rate_Card__r.Commission_Plan__c, Status__c, Product2.Track_Inventory__c, Order.Channel__c, Order.Stage__c, Order.Is_Back_Order__c, Order.Is_Pre_Order__c,
                                    Asset__c, Asset__r.Serial__c, Serial__c, BOM__c, Product2.Serialise__c, Product2.Lot_Tracked__c
                                    From OrderItem 
                                    Where Id In: lineItemIds];
                /*'--- currentLineItems :'+currentLineItems*/
            }   
            
            list<String> SolidIds=new list<String>();  Set<Id> backOrderProdIds=new Set<Id>();
            for(OrderItem lineItem : currentLineItems){ SolidIds.add(lineItem.Id); if(lineItem.Is_Back_Order__c) backOrderProdIds.add(lineItem.Product2Id); }
            
            existingSOWList=[SELECT Id, Name, Order__c, Order_Product__c,Quantity__c
                             FROM Stock_Outward_Line_Item__c WHERE Order_Product__c IN:SolidIds AND Logistic_Line_Item__c!=NULL AND Quantity__c>0];
            
            for(OrderItem lineItem : currentLineItems ){  
                orderIds.add(lineItem.OrderId);
                if(lineItem.Product2Id != Null){
                    if(Schema.sObjectType.OrderItem.fields.Product2Id.isAccessible()) productIds.add(lineItem.Product2Id);
                } 
                if(lineItem.asset__c != Null){ if(Schema.sObjectType.OrderItem.fields.asset__c.isAccessible()) assetIds.add(lineItem.asset__c);
                }
                if(lineItem.Order.Channel__c != Null){
                    if(Schema.sObjectType.Order.isAccessible() && Schema.sObjectType.Order.fields.Channel__c.isAccessible() && Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.OrderItem.fields.OrderId.isAccessible()) salepointIds.add(lineItem.Order.Channel__c);
                }
                if(lineItem.Id != Null){
                    if(Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()){
                        list<Stock_Outward_Line_Item__c> swList=new list<Stock_Outward_Line_Item__c>();   
                        for(Stock_Outward_Line_Item__c sw : existingSOWList ){ if(lineItem.Id==sw.Order_Product__c) swList.add(sw); } 
                        existingSoliAndSOWMap.put(lineItem.Id, swList);   
                    }                        
                } 
            } 
            
            // if(AllocateCustomerSpecific){
            SOMOs = [Select Id,Name from Manufacturing_Order__c where (Order_Product__c IN:lineItemIds and Order__c IN:orderIds) and Product__c IN:productIds];
            System.debug('SOMOs : '+SOMOs.size());    
            SOPOs = [Select Id,Name from PO__c where Order__c IN:orderIds and Ready_To_Receive__c =:true];
            System.debug('SOPOs : '+SOPOs.size());    
            // }
            
            List<Distribution_Channel__c> DistributionChannels;
            if(Schema.sObjectType.Distribution_Channel__c.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Active__c','Channel__c','Site__c','Channel__c','Site__c','Priority__c'},'Distribution_Channel__c');
                DistributionChannels = [Select Id, Name, Active__c,  Channel__c, Site__c, Priority__c
                                        From Distribution_Channel__c
                                        Where Channel__c In : salepointIds And
                                        Active__c = true
                                        Order By Priority__c ASC];
            }
            
            for(Id sId : salepointIds){ 
                Set<Id> siteIds = new Set<Id>();
                for(Distribution_Channel__c DC : DistributionChannels){
                    if(sId == DC.Channel__c) { 
                        if(Schema.sObjectType.Distribution_Channel__c.fields.Site__c.isAccessible()) siteIds.add(DC.Site__c);
                        if(Schema.sObjectType.Distribution_Channel__c.fields.Site__c.isAccessible()) allSalepointSiteIds.add(DC.Site__c);
                    }
                }
                salepointSites.put(sId,siteIds);
            }
            
            //Creating Inventory for product which don't have any inventory.
            List<Id> allSalepointSiteIdsList=new List<Id>();  allSalepointSiteIdsList.addAll(allSalepointSiteIds);
            if(backOrderProdIds.size() > 0){ 
                List<Inventory_Stock__c> invforBackOrders=[Select Id,Name,Product__c from Inventory_Stock__c where Product__c In:backOrderProdIds];        
                Map<Id,Id> prodIdWithInv = new Map<Id,Id>(); 
                for(Inventory_Stock__c inv:invforBackOrders) prodIdWithInv.put(inv.Product__c,inv.Id); 
                List<Inventory_Stock__c> inventoryList=new List<Inventory_Stock__c>();
                if(prodIdWithInv.size()>0){
                    for(OrderItem ordItm:currentLineItems){
                        if(prodIdWithInv.get(ordItm.Product2Id) == null){
                            Inventory_Stock__c inv=new Inventory_Stock__c(); inv.Name=ordItm.Product2.Name; inv.Product__c=ordItm.Product2Id; inv.Warehouse__c=allSalepointSiteIdsList[0]; inv.Active__c=true;  inv.Checked_In_Date__c=System.today(); inventoryList.add(inv);  
                        }  
                    } if(inventoryList.size() > 0) insert inventoryList;
                }
            }
            
            List<Inventory_Stock__c> WarehouseItemInventoryStocks = new List<Inventory_Stock__c>(); 
            
            List<Inventory_Stock__c> invtoryList = new List<Inventory_Stock__c>();
            List<Inventory_Stock__c> MOPOinvtoryList = new List<Inventory_Stock__c>();
            
            // Changed below code by Arshad 10 Aug 2023
            if(Schema.sObjectType.Inventory_Stock__c.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Active__c','Company__c','Warehouse__c','Number_of_Item_In_Stock__c','Number_of_Item_Purchased_In__c','Number_of_Items_Dispatched__c','No_of_Items_Sold__c','Checked_In_Date__c'},'Inventory_Stock__c');
                
                system.debug('SOMOs : '+SOMOs.size());
                system.debug('SOPOs : '+SOPOs.size());
                
                //if(AllocateCustomerSpecific){
                if(SOMOs.size() > 0 || SOPOs.size() > 0){
                    set<Id> MoIds = new set<Id>();set<Id> PoIds = new set<Id>();set<Id> InvIds = new set<Id>();
                    for(Manufacturing_Order__c MO : SOMOs) MoIds.add(MO.Id);
                    for(PO__c PO : SOPOs) PoIds.add(PO.Id);
                    system.debug('MoIds : '+MoIds);
                    List<Stock_Inward_Line_Item__c> stinlist = [Select Id,Name,Product__c,Site_ProductService_InventoryStock__c from Stock_Inward_Line_Item__c where Active__c = true and Product__c IN :productIds and Scrap__c = false and (Purchase_Orders__c IN:PoIds or Manufacturing_Order__c IN: MoIds) and Quantity__c > 0 and Status__c != 'Awaiting Stock'];
                    for(Stock_Inward_Line_Item__c sin : stinlist) InvIds.add(sin.Site_ProductService_InventoryStock__c);
                    system.debug('InvIds : '+InvIds);
                    system.debug('productIds : '+productIds);
                    
                    WarehouseItemInventoryStocks = MOPOinvtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, BOM__c,Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where (Product__c In: productIds Or Fixed_Asset__c In: assetIds) And Active__c = true And Warehouse__c In: allSalepointSiteIds and Id IN:InvIds and Name != 'Awaiting Stock' Order By Checked_In_Date__c ASC]; //And Number_of_Item_In_Stock__c > 0
                    
                    system.debug('WarehouseItemInventoryStocks MOPOinvtoryList size~>'+WarehouseItemInventoryStocks.size());
                    
                }
                
                system.debug('WarehouseItemInventoryStocks inhere1~>'+WarehouseItemInventoryStocks.size());
                
                system.debug('No MOs or POs associated with the order ');
                if(MOPOinvtoryList.size() > 0){
                    invtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, BOM__c, Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where (Product__c In: productIds Or Fixed_Asset__c In: assetIds) And Active__c = true And Warehouse__c In: allSalepointSiteIds and Name != 'Awaiting Stock' AND Id NOT IN:MOPOinvtoryList Order By BOM__c,Checked_In_Date__c ASC NULLS LAST]; //And Number_of_Item_In_Stock__c > 0
                }else{
                    invtoryList = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, BOM__c,
                                   Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, 
                                   Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c 
                                   From Inventory_Stock__c Where (Product__c In: productIds Or Fixed_Asset__c In: assetIds) And
                                   Active__c = true And Warehouse__c In: allSalepointSiteIds and Name != 'Awaiting Stock' 
                                   Order By BOM__c,Checked_In_Date__c ASC NULLS LAST]; //And Number_of_Item_In_Stock__c > 0
                }
                
                system.debug('invtoryList size~>'+invtoryList.size());
                
                if(invtoryList.size() > 0){
                    WarehouseItemInventoryStocks.addAll(invtoryList);
                }
                
                system.debug('WarehouseItemInventoryStocks inhere2~>'+WarehouseItemInventoryStocks.size());
            }
            
            Map<String,Decimal> WIISListsprodmyStockMap = new Map<String,Decimal>();
            Map<String,List<Inventory_Stock__c>> WIISListsprodMap = new Map<String,List<Inventory_Stock__c>>();
            Map<String,List<Inventory_Stock__c>> WIISListsAssetMap = new Map<String,List<Inventory_Stock__c>>();
            
            List<Stock_Outward_Line_Item__c> pplis2Insert = new List<Stock_Outward_Line_Item__c>(); 
            List<Id> SerialStockIds = new List<Id>();
            
            if(WarehouseItemInventoryStocks.size() > 0){
                
                for(Inventory_Stock__c WIIS : WarehouseItemInventoryStocks){
                    if(WIIS.Product__c != null){
                        List<Inventory_Stock__c> newlst = new List<Inventory_Stock__c>();
                        if(WIISListsprodMap.containsKey(WIIS.Product__c)) newlst = WIISListsprodMap.get(WIIS.Product__c);
                        newlst.add(WIIS);
                        if(newlst.size() > 0) WIISListsprodMap.put(WIIS.Product__c,newlst);
                        
                        Decimal mynewStock = 0;
                        if(WIISListsprodmyStockMap.containsKey(WIIS.Product__c)) mynewStock = WIISListsprodmyStockMap.get(WIIS.Product__c); // 0 //1
                        if(WIIS.Number_of_Item_In_Stock__c > 0 || (WIIS.Number_of_Item_In_Stock__c < 0 && WIIS.Name == 'Serial Stock Holder')) mynewStock += WIIS.Number_of_Item_In_Stock__c; /// 1 //2
                        
                        //if(mynewStock > 0) 
                        WIISListsprodmyStockMap.put(WIIS.Product__c,mynewStock); //1
                    }else if(WIIS.Fixed_Asset__c != null){
                        List<Inventory_Stock__c> newlst = new List<Inventory_Stock__c>();
                        if(WIISListsAssetMap.containsKey(WIIS.Fixed_Asset__c)) newlst = WIISListsAssetMap.get(WIIS.Fixed_Asset__c);
                        newlst.add(WIIS);
                        if(newlst.size() > 0) WIISListsAssetMap.put(WIIS.Fixed_Asset__c,newlst);
                        
                        //Assetprodstock need todo
                    }
                }
                Map<Id, Inventory_Stock__c> pliStock = new Map<Id, Inventory_Stock__c>();
                Map<Id, Stock_Outward_Line_Item__c> pliStockInward = new Map<Id, Stock_Outward_Line_Item__c>();
                List<Inventory_Stock__c> Inventory2Upsert = new List<Inventory_Stock__c>();
                system.debug('productSites : '+productSites.size());
                for(OrderItem lineItem : currentLineItems ){  
                    boolean succeed = false;
                    List<Inventory_Stock__c> prodInventoryList = new List<Inventory_Stock__c>();
                    List<Inventory_Stock__c> finalprodInventoryList = new List<Inventory_Stock__c>();
                    
                    if(lineItem.Product2Id != null && WIISListsprodMap.containsKey(lineItem.Product2Id)) prodInventoryList = WIISListsprodMap.get(lineItem.Product2Id);
                    else if(lineItem.Asset__c != null && WIISListsAssetMap.containsKey(lineItem.Asset__c)) prodInventoryList = WIISListsAssetMap.get(lineItem.Asset__c);
                    
                    if(lineItem.Checked_Out_Process__c == 'LIFO'){
                        List<Inventory_Stock__c> LIFOprodInventoryList = new List<Inventory_Stock__c>();
                        for(Integer i=prodInventoryList.size(); i>0; i--){
                            if(Schema.sObjectType.Inventory_Stock__c.isAccessible()) LIFOprodInventoryList.add(prodInventoryList[i-1]);
                        }
                        if(Schema.sObjectType.Inventory_Stock__c.isAccessible()) finalprodInventoryList.addAll(LIFOprodInventoryList);
                    } 
                    else { finalprodInventoryList = prodInventoryList; system.debug('else finalprodInventoryList assignment'); }
                    
                    system.debug('finalprodInventoryList size~>'+finalprodInventoryList.size());
                    Decimal lineOrderedQuantity = (lineItem.Quantity != Null)? lineItem.Quantity : 0;
                    Decimal existingStoliQuantity = 0; 
                    
                    for(String soliId : existingSoliAndSOWMap.keySet()){  
                        if(lineItem.Id==soliId){
                            for(Stock_Outward_Line_Item__c sto : existingSoliAndSOWMap.get(soliId)){ if(sto.Quantity__c!=null) existingStoliQuantity += sto.Quantity__c; 
                            } 
                        }
                    }            
                    
                    if(existingStoliQuantity > 0) lineOrderedQuantity = lineOrderedQuantity - existingStoliQuantity;
                    
                    system.debug('lineOrderedQuantity~>'+lineOrderedQuantity);
                    
                    if(lineOrderedQuantity > 0){
                        if(lineItem.Inventory_Tracked__c == true && !lineItem.Is_Back_Order__c && !lineItem.Is_Pre_Order__c){
                            Decimal prodStock = 0;
                            if(WIISListsprodmyStockMap.containsKey(lineItem.Product2Id)) prodStock = WIISListsprodmyStockMap.get(lineItem.Product2Id); 
                            system.debug('prodStock : '+prodStock);
                            if(lineItem.Product2.Serialise__c){
                                if(prodStock >= lineOrderedQuantity && prodInventoryList.size() >= lineOrderedQuantity){
                                    Inventory_Stock__c inv = new Inventory_Stock__c(Active__c = true, Product__c = lineItem.Product2Id, Company__c = lineItem.Company__c, Organisation_Business_Unit__c = lineItem.Organisation_Business_Unit__c, Name = 'Serial Stock Holder', Warehouse__c = allSalepointSiteIdsList[0]);
                                    Inventory2Upsert.add(inv);
                                    //  for(Integer i=0; i < lineOrderedQuantity; i++){
                                    Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                                    PPLI.Name = 'Serial Stock Holder';
                                    PPLI.Active__c = true;
                                    PPLI.Order__c = lineItem.OrderId;
                                    if(lineItem.Product2Id != null) PPLI.Product__c = lineItem.Product2Id;
                                    if(lineItem.Asset__c != null){
                                        PPLI.Fixed_Asset__c = lineItem.Asset__c;
                                        if(lineItem.Asset__r.Serial__c != null) PPLI.Serial__c = lineItem.Asset__r.Serial__c;
                                    }
                                    //SerialStockIds.add(prodInventoryList[i].Id);
                                    PPLI.Quantity__c = lineOrderedQuantity;
                                    PPLI.Order_Product__c = lineItem.Id;
                                    /*PPLI.Site_Product_Service_Inventory_Stock__c = prodInventoryList[i].Id;
if(prodInventoryList[i].Serial__c != null){
PPLI.Serial__c = prodInventoryList[i].Serial__c ;
}
if(prodInventoryList[i].Batch_Lot__c != null) PPLI.Material_Batch_Lot__c = prodInventoryList[i].Batch_Lot__c;
if(prodInventoryList[i].BOM__c != null) PPLI.BOM__c = prodInventoryList[i].BOM__c;*/
                                    if(lineItem.Order.Stage__c == 'Entered') PPLI.Status__c = 'Reserved';
                                    else if(lineItem.Order.Stage__c == 'Closed') PPLI.Status__c = 'Committed';
                                    pplis2Insert.add(PPLI);
                                    pliStock.put(lineItem.Id,inv);
                                    pliStockInward.put(lineItem.Id,PPLI);
                                    // }
                                }else system.debug('no serial stocks for ordered qty~>'+lineOrderedQuantity);
                            }
                            else if(prodStock >= lineOrderedQuantity){
                                for(Inventory_Stock__c currProductSite : prodInventoryList){
                                    if(lineOrderedQuantity > 0  && (lineItem.BOM__c == null || (lineItem.BOM__c != null && lineItem.BOM__c == currProductSite.BOM__c))){
                                        system.debug('First condition');
                                        if(currProductSite.Number_of_Item_In_Stock__c > 0 && currProductSite.Number_of_Item_In_Stock__c >= lineOrderedQuantity){
                                            system.debug('2nd condition');
                                            Integer loopquantity = 1;
                                            if(lineItem.Product2.Serialise__c){ SerialStockIds.add(currProductSite.Id);loopquantity = Integer.valueof(lineOrderedQuantity);
                                            }
                                            
                                            system.debug('loopquantity : '+loopquantity);
                                            for(Integer i=0; i<loopquantity; i++){
                                                Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                                                PPLI.Active__c = true;
                                                PPLI.Order__c = lineItem.OrderId;
                                                PPLI.Product__c = lineItem.Product2Id;
                                                if(lineItem.Asset__c != Null && lineItem.Asset__r.Serial__c != Null ){ PPLI.Fixed_Asset__c = lineItem.Asset__c;PPLI.Serial__c = lineItem.Asset__r.Serial__c;
                                                }
                                                if(currProductSite.Serial__c != Null) PPLI.Serial__c = currProductSite.Serial__c;
                                                
                                                if(lineItem.Product2.Serialise__c) PPLI.Quantity__c = 1;
                                                else PPLI.Quantity__c = lineOrderedQuantity;
                                                
                                                PPLI.Order__c = lineItem.OrderId;
                                                PPLI.Order_Product__c = lineItem.Id;
                                                PPLI.Site_Product_Service_Inventory_Stock__c = currProductSite.Id;
                                                if(currProductSite.Serial__c != null) PPLI.Serial__c = currProductSite.Serial__c;
                                                if(currProductSite.Batch_Lot__c != null) PPLI.Material_Batch_Lot__c = currProductSite.Batch_Lot__c;
                                                if(currProductSite.BOM__c != null) PPLI.BOM__c = currProductSite.BOM__c;
                                                if(lineItem.Order.Stage__c == 'Entered') PPLI.Status__c = 'Reserved';
                                                else if(lineItem.Order.Stage__c == 'Closed') PPLI.Status__c = 'Committed';
                                                pplis2Insert.add(PPLI);
                                            }
                                            succeed = true;
                                            break;
                                        }
                                        else if(currProductSite.Number_of_Item_In_Stock__c > 0) {
                                            system.debug('First else condition');
                                            Integer loopquantity = 1;
                                            if(lineItem.Product2.Serialise__c){ SerialStockIds.add(currProductSite.Id);loopquantity = Integer.valueof(currProductSite.Number_of_Item_In_Stock__c);
                                            }
                                            system.debug('loopquantity : '+loopquantity);
                                            for(Integer i=0; i<loopquantity; i++){
                                                Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();PPLI.Active__c = true;PPLI.Order__c = lineItem.OrderId;PPLI.Product__c = lineItem.Product2Id;
                                                
                                                if(lineItem.Asset__c != Null && lineItem.Asset__r.Serial__c != Null){ PPLI.Fixed_Asset__c = lineItem.Asset__c;PPLI.Serial__c = lineItem.Asset__r.Serial__c;
                                                }
                                                if(lineItem.Product2.Serialise__c) PPLI.Quantity__c = 1;
                                                else PPLI.Quantity__c = currProductSite.Number_of_Item_In_Stock__c;
                                                
                                                PPLI.Order_Product__c = lineItem.Id;PPLI.Site_Product_Service_Inventory_Stock__c = currProductSite.Id;
                                                if(currProductSite.Serial__c != null) PPLI.Serial__c = currProductSite.Serial__c;
                                                if(currProductSite.Batch_Lot__c != null) PPLI.Material_Batch_Lot__c = currProductSite.Batch_Lot__c;
                                                if(currProductSite.BOM__c != null) PPLI.BOM__c = currProductSite.BOM__c;
                                                PPLI.Order__c = lineItem.OrderId;
                                                if(lineItem.Order.Stage__c == 'Entered') PPLI.Status__c = 'Reserved';
                                                else if(lineItem.Order.Stage__c == 'Closed') PPLI.Status__c = 'Committed';
                                                
                                                system.debug('PPLI.Status__c 11: '+PPLI.Status__c );
                                                pplis2Insert.add(PPLI);lineOrderedQuantity -= currProductSite.Number_of_Item_In_Stock__c;
                                            }
                                        }
                                    }
                                    if(succeed){ break; } 
                                }  
                                
                            }
                        } 
                        else if(lineItem.Inventory_Tracked__c == true && (lineItem.Is_Back_Order__c || lineItem.Is_Pre_Order__c) && lineItem.Order.Stage__c == 'Entered'){
                            if((lineItem.Product2Id != null && WIISListsprodMap.containsKey(lineItem.Product2Id)) || (lineItem.Asset__c != null && WIISListsAssetMap.containsKey(lineItem.Asset__c))){
                                Inventory_Stock__c stock = new  Inventory_Stock__c();
                                if(lineItem.Product2Id != null && WIISListsprodMap.containsKey(lineItem.Product2Id)) stock = WIISListsprodMap.get(lineItem.Product2Id)[0];
                                else if(lineItem.Asset__c != null && WIISListsAssetMap.containsKey(lineItem.Asset__c)) stock = WIISListsAssetMap.get(lineItem.Asset__c)[0];
                                
                                Integer loopquantity = 1;
                                if(lineItem.Product2.Serialise__c){
                                    SerialStockIds.add(Stock.Id);
                                    loopquantity = Integer.valueof(lineOrderedQuantity);
                                }
                                for(Integer i=0; i<loopquantity; i++){
                                    Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                                    PPLI.Order__c = lineItem.OrderId;
                                    PPLI.Site_Product_Service_Inventory_Stock__c = stock.Id;
                                    //if(Stock.Serial__c != null) PPLI.Serial__c = Stock.Serial__c; 
                                    //PPLI.Material_Batch_Lot__c = Stock.Batch_Lot__c;
                                    if(stock.BOM__c != null) PPLI.BOM__c = stock.BOM__c;
                                    PPLI.Active__c = true;
                                    PPLI.Order__c = lineItem.OrderId;
                                    PPLI.Product__c = lineItem.Product2Id;
                                    if(lineItem.Asset__c != Null && lineItem.Asset__r.Serial__c != Null){
                                        PPLI.Fixed_Asset__c = lineItem.Asset__c;
                                        PPLI.Serial__c = lineItem.Asset__r.Serial__c;
                                    }
                                    if(lineItem.Product2.Serialise__c) PPLI.Quantity__c = 1;
                                    else PPLI.Quantity__c = lineOrderedQuantity;
                                    PPLI.Order_Product__c = lineItem.Id;
                                    PPLI.Status__c = 'Requested';
                                    pplis2Insert.add(PPLI);
                                }
                            }
                        }
                    } 
                }
                
                system.debug('pplis2Insert : '+pplis2Insert.size());
                
                if(pplis2Insert.size() > 0){
                    List<Serial_Number__c> serials2Update = new List<Serial_Number__c>();
                    
                    if(SerialStockIds.size() > 0){
                        /*
List< Stock_Inward_Line_Item__c > SILIS =  [Select Id, Name, Active__c, Fixed_Asset__c, Fixed_Asset__r.Available__c, Fixed_Asset__r.Product__c, Quantity__c, Order__c, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, Batch_Lot_Code__c,
Product__c, Site_ProductService_InventoryStock__c, Site_ProductService_InventoryStock__r.Warehouse__c, Site_ProductService_InventoryStock__r.Number_of_Item_In_Stock__c, Order_Product__c
From Stock_Inward_Line_Item__c Where Serial__c != Null And Serial__r.Available__c = true And Serial__r.Expired__c = false And
Active__c = true And Site_ProductService_InventoryStock__c In :SerialStockIds Limit 1000];

List<Id> SerialIds = new List<Id>();
for(Stock_Outward_Line_Item__c pplil : pplis2Insert){
if(SerialStockIds.contains(pplil.Site_Product_Service_Inventory_Stock__c)){
for(Stock_Inward_Line_Item__c silil : SILIS){
if(pplil.Site_Product_Service_Inventory_Stock__c == silil.Site_ProductService_InventoryStock__c){
if(!SerialIds.contains(silil.Serial__c)){
pplil.Serial__c = silil.Serial__c;
SerialIds.add(silil.Serial__c);
break;
}
}
}
}
}
*/
                        
                        /* commented by shaguftha as the serial number which are reserved are not avialble in the outbound PIck
*  for(Id SerialId : SerialIds) {
Serial_Number__c SN = new Serial_Number__c(Id = SerialId);
if(Schema.sObjectType.Serial_Number__c.fields.Available__c.isUpdateable()) SN.Available__c = false;
serials2Update.add(SN);
}*/
                    }
                    if(Inventory2Upsert.size() > 0) insert Inventory2Upsert;
                    for(Id pliId : pliStockInward.KeySet()){
                        pliStockInward.get(pliId).Site_Product_Service_Inventory_Stock__c= pliStock.get(pliId).Id;
                    }
                    if(pplis2Insert.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()) { upsert pplis2Insert; } else{ /* not allowed to upsert */}
                    /// if(serials2Update.size() > 0 && Schema.sObjectType.Serial_Number__c.isUpdateable()) {update serials2Update; } else{ /* not allowed*/ }
                }
            }
        } 
    }
    
    /* Method to update Product Purchase Line Items for update of Line Items. */
    global static void updateProductPurchaseLineItems(set<Id> lineItemIds){
        System.debug('inside updateProductPurchaseLineItems');
        System.debug('PreventRecursiveLedgerEntry.SOLI_AllocateStock:'+PreventRecursiveLedgerEntry.SOLI_AllocateStock);
        if(PreventRecursiveLedgerEntry.SOLI_AllocateStock){
            PreventRecursiveLedgerEntry.SOLI_AllocateStock = false;
            List<Manufacturing_Order__c> SOMOs = new List<Manufacturing_Order__c>();
            List<PO__c> SOPOs = new List<PO__c>();
        
            
            Set<Id> salepointIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            Set<Id> allSalepointSiteIds = new Set<Id>();
            Map<Id, Set<Id>> salepointSites = new Map<Id, Set<Id>>();
            Map<Id, Set<Inventory_Stock__c>> productSites = new Map<Id, Set<Inventory_Stock__c>>();       
            List<OrderItem> currentLineItems;
            Set<Id> orderIds= new Set<Id>();
            Map<Id, List<Stock_Outward_Line_Item__c>> existingSoliAndSOWMap = new Map<Id, List<Stock_Outward_Line_Item__c>>();
            list<Stock_Outward_Line_Item__c> existingSOWList = new List<Stock_Outward_Line_Item__c>(); 
            
            if(Schema.sObjectType.OrderItem.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Base_Price__c','Discount_Amount__c','Invoice__c','UnitPrice','Total_Price__c','VAT_Amount__c','Company__c','Organisation_Business_Unit__c','Inventory_Tracked__c','Product2Id','Quantity','OrderId','Loyalty_Points__c','Loyalty_Program__c','Checked_Out_Process__c','Commission__c','Commission_Rate_Card__c','Status__c'},'OrderItem');
                UtilClass.FlsCheck(new String[]{'Sub_Total__c','Total_Discount__c','Total_Due__c','Total_Tax_Amount__c','Channel__c','Stage__c','Is_Back_Order__c'},'Order');
                UtilClass.FlsCheck(new String[]{'SKU__c','Track_Inventory__c'},'Product__c');
                if(!Schema.sObjectType.Commission_Rate_Card__c.fields.Commission_Plan__c.isAccessible()) return ;
                
                currentLineItems = [Select Id, Base_Price__c, Discount_Amount__c, Invoice__c, UnitPrice, Total_Price__c, VAT_Amount__c,Company__c, Organisation_Business_Unit__c, Inventory_Tracked__c,
                                    Product2Id, Product2.Name, Product2.SKU__c, Quantity, OrderId, Loyalty_Points__c, Loyalty_Program__c, Checked_Out_Process__c, Is_Pre_Order__c, Is_Back_Order__c,
                                    Order.Name, Order.Sub_Total__c, Order.Total_Discount__c, Order.Total_Due__c, Order.Total_Tax_Amount__c, Commission__c, Commission_Rate_Card__c,
                                    Commission_Rate_Card__r.Commission_Plan__c, Status__c, Product2.Track_Inventory__c, Order.Channel__c, Order.Stage__c, Order.Is_Back_Order__c, BOM__c
                                    From OrderItem 
                                    Where Id In: lineItemIds];
            }
            
            list<String> SolidIds=new list<String>();
            for(OrderItem lineItem : currentLineItems) SolidIds.add(lineItem.Id);
            
            existingSOWList=[SELECT Id, Name, Order__c, Order_Product__c, Logistic_Line_Item__c, Quantity__c
                             FROM Stock_Outward_Line_Item__c WHERE Order_Product__c IN:SolidIds AND ((Logistic_Line_Item__c!=NULL AND Status__c='Reserved') OR Status__c='Requested') AND Quantity__c>0]; //AND Status__c='Committed'
            
            System.debug('existingSOWList:'+existingSOWList.size());
            
            /* List<Stock_Outward_Line_Item__c> pplis2delete;
Map<Id, Id> lineStock = new Map<Id, Id>();
if(Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()){
UtilClass.FlsCheck(new String[]{'Active__c','Product__c','Quantity__c','Sales_Order_Line_Item__c','Site_Product_Service_Inventory_Stock__c'},'Stock_Outward_Line_Item__c');

pplis2delete = [Select Id, Name, Active__c, Product__c, Quantity__c, Sales_Order_Line_Item__c, Site_Product_Service_Inventory_Stock__c, Picked_Date__c
From Stock_Outward_Line_Item__c
Where Sales_Order_Line_Item__c In : lineItemIds And
Picked_Date__c = Null And
Active__c = true];
}*/
            
            // if(pplis2delete.size() > 0) if (Schema.sObjectType.Stock_Outward_Line_Item__c.isDeletable()) DMLManager.deleteAsUser(pplis2delete);
            
            for(OrderItem lineItem : currentLineItems ){  
                orderIds.add(lineItem.OrderId);
                if(lineItem.Product2Id != Null){
                    if(Schema.sObjectType.OrderItem.fields.Product2Id.isAccessible()) productIds.add(lineItem.Product2Id);
                } 
                if(lineItem.Order.Channel__c != Null){
                    if(Schema.sObjectType.Order.isAccessible() && Schema.sObjectType.Order.fields.Channel__c.isAccessible() && Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.OrderItem.fields.OrderId.isAccessible()) salepointIds.add(lineItem.Order.Channel__c);
                } 
                if(lineItem.Id != Null){
                    if(Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()){
                        list<Stock_Outward_Line_Item__c> swList=new list<Stock_Outward_Line_Item__c>();   
                        for(Stock_Outward_Line_Item__c sw : existingSOWList){    
                            if(lineItem.Id==sw.Order_Product__c) swList.add(sw);
                        } 
                        existingSoliAndSOWMap.put(lineItem.Id, swList);   
                    }
                }
                
            } 
            System.debug('existingSoliAndSOWMap:'+existingSoliAndSOWMap.size());
            
            //if(AllocateCustomerSpecific){
            SOMOs = [Select Id,Name from Manufacturing_Order__c where Order_Product__c IN:lineItemIds and Order__c IN:orderIds and Product__c IN:productIds];
            SOPOs = [Select Id,Name from PO__c where Order__c IN:orderIds and Ready_To_Receive__c =:true];
            //}
            
            List<Distribution_Channel__c> DistributionChannels;
            if(Schema.sObjectType.Distribution_Channel__c.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Active__c','Channel__c','Site__c','Priority__cActive__c','Company__c','Organisation_Business_Unit__c','Channel__c','Site__c','Priority__c'},'Distribution_Channel__c');
                DistributionChannels = [Select Id, Name, Active__c, Channel__c, Site__c, Priority__c
                                        From Distribution_Channel__c
                                        Where Channel__c In : salepointIds And
                                        Active__c = true
                                        Order By Priority__c ASC];
            }
            for(Id sId : salepointIds){
                Set<Id> siteIds = new Set<Id>();
                for(Distribution_Channel__c DC : DistributionChannels){
                    if(sId == DC.Channel__c) { 
                        if(Schema.sObjectType.Distribution_Channel__c.fields.Site__c.isAccessible()) siteIds.add(DC.Site__c);
                        if(Schema.sObjectType.Distribution_Channel__c.fields.Site__c.isAccessible()) allSalepointSiteIds.add(DC.Site__c);
                    }
                }
                salepointSites.put(sId,siteIds);
            }
            
            List<Inventory_Stock__c> WarehouseItemInventoryStocks;
            if(Schema.sObjectType.Inventory_Stock__c.isAccessible()){
                UtilClass.FlsCheck(new String[]{'Active__c','Company__c','Organisation_Business_Unit__c','Warehouse__c','Item__c','Number_of_Item_In_Stock__c','Number_of_Item_Purchased_In__c','Number_of_Items_Dispatched__c','No_of_Items_Sold__c','Checked_In_Date__c'},'Inventory_Stock__c');
                
                // if(AllocateCustomerSpecific){
                if(SOMOs.size() > 0 || SOPOs.size() > 0){
                    set<Id> MoIds = new set<Id>();set<Id> PoIds = new set<Id>();set<Id> InvIds = new set<Id>();
                    for(Manufacturing_Order__c MO : SOMOs) MoIds.add(MO.Id);
                    for(PO__c PO : SOPOs) PoIds.add(PO.Id);
                    system.debug('MoIds : '+MoIds);
                    List<Stock_Inward_Line_Item__c> stinlist = [Select Id,Name,Site_ProductService_InventoryStock__c from Stock_Inward_Line_Item__c where Active__c = true and Product__c IN :productIds and Scrap__c = false and (Purchase_Orders__c IN:PoIds or Manufacturing_Order__c IN: MoIds) and Quantity__c > 0 and Status__c != 'Awaiting Stock'];
                    for(Stock_Inward_Line_Item__c sin : stinlist) InvIds.add(sin.Site_ProductService_InventoryStock__c);
                    system.debug('InvIds : '+InvIds);
                    
                    WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c,  Warehouse__c, Fixed_Asset__c, Batch_Lot__c, Serial__c, BOM__c, Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c Where (Product__c In: productIds) And Active__c = true And Warehouse__c In: allSalepointSiteIds and Id IN:InvIds and Name != 'Awaiting Stock' Order By Checked_In_Date__c ASC];
                    system.debug('WarehouseItemInventoryStocks : '+WarehouseItemInventoryStocks.size());
                }
                else{
                    system.debug('No MOs or POs associated with the order ');
                    WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, Serial__c, Batch_Lot__c, BOM__c,
                                                    Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, 
                                                    Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c 
                                                    From Inventory_Stock__c
                                                    Where Product__c In: productIds And
                                                    Active__c = true And
                                                    Warehouse__c In: allSalepointSiteIds                                              
                                                    //And Number_of_Item_In_Stock__c > 0
                                                    Order By Checked_In_Date__c ASC];
                }
                // }
                /*  else{
WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Organisation_Business_Unit__c, Warehouse__c, Serial__c, Batch_Lot__c, BOM__c,
Product__c,  Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c, 
Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c 
From Inventory_Stock__c
Where Product__c In: productIds And
Active__c = true And
Warehouse__c In: allSalepointSiteIds                                              
//And Number_of_Item_In_Stock__c > 0
Order By Checked_In_Date__c ASC];  
}*/
            }
            
            for(Id pId : productIds){
                Set<Inventory_Stock__c> sites = new Set<Inventory_Stock__c>();
                for(Inventory_Stock__c WIIS : WarehouseItemInventoryStocks){
                    if(pId == WIIS.Product__c) if(Schema.sObjectType.Inventory_Stock__c.isAccessible()) sites.add(WIIS);
                }
                productSites.put(pId,sites);
            }
            
            List<Stock_Outward_Line_Item__c> pplis2Insert = new List<Stock_Outward_Line_Item__c>();                                                                     
            for(OrderItem lineItem : currentLineItems ){ 
                System.debug('lineItem:'+lineItem);
                boolean succeed = false;
                Set<Id> currSalepointSites;
                if(Schema.sObjectType.Order.isAccessible() && Schema.sObjectType.Order.fields.Channel__c.isAccessible() && Schema.sObjectType.OrderItem.isAccessible() && Schema.sObjectType.OrderItem.fields.OrderId.isAccessible()) currSalepointSites = salepointSites.get(lineItem.Order.Channel__c);
                System.debug('currSalepointSites:'+currSalepointSites);
                Set<Inventory_Stock__c> currTempProductSites;
                if(Schema.sObjectType.OrderItem.fields.Product2Id.isAccessible()) currTempProductSites = productSites.get(lineItem.Product2Id);
                System.debug('currTempProductSites:'+currTempProductSites);
                Set<Inventory_Stock__c> currProductSites = new Set<Inventory_Stock__c>();
                
                List<Inventory_Stock__c> currTempProductSitess = new List<Inventory_Stock__c>();
                currTempProductSitess.addAll(currTempProductSites);
                System.debug('currTempProductSitess:'+currTempProductSitess);
                List<Inventory_Stock__c> currProductSitess = new List<Inventory_Stock__c>();
                
                if(lineItem.Checked_Out_Process__c == 'LIFO'){ 
                    for(Integer i=currTempProductSitess.size(); i>0; i--){
                        if(Schema.sObjectType.Inventory_Stock__c.isAccessible()) currProductSitess.add(currTempProductSitess[i-1]);
                    }
                    currProductSites.addAll(currProductSitess);
                } else currProductSites = currTempProductSites;
                
                System.debug('currProductSites:'+currProductSites);
                Decimal quantity;
                if(Schema.sObjectType.OrderItem.fields.Quantity.isAccessible()) quantity = lineItem.Quantity;
                System.debug('quantity:'+quantity);
                Decimal SWQuantity=0; 
                
                for(String soliId : existingSoliAndSOWMap.keySet()){
                    System.debug('soliId:'+soliId);
                    System.debug('lineItem.Id:'+lineItem.Id);
                    if(lineItem.Id==soliId){                         
                        for(Stock_Outward_Line_Item__c sto : existingSoliAndSOWMap.get(soliId)){
                            if(sto.Quantity__c!=null){
                                SWQuantity+=sto.Quantity__c; 
                            }   
                        } 
                    }
                }    
                
                System.debug('SWQuantity:'+SWQuantity);
                if(SWQuantity!=null && SWQuantity!=0) quantity=quantity-SWQuantity;
                
                System.debug('lineItem.Inventory_Tracked__c:'+lineItem.Inventory_Tracked__c);
                System.debug('lineItem.Is_Back_Order__c:'+lineItem.Is_Back_Order__c);
                System.debug('lineItem.Is_Pre_Order__c:'+lineItem.Is_Pre_Order__c);
                System.debug('quantity:'+quantity);
                if(lineItem.Inventory_Tracked__c == true && !lineItem.Is_Back_Order__c && !lineItem.Is_Pre_Order__c && quantity>0){
                    System.debug('inside if 465');
                    for(Id currSalepointSite : currSalepointSites){
                        System.debug('currSalepointSite:'+currSalepointSite);
                        for(Inventory_Stock__c currProductSite : currProductSites){
                            System.debug('currProductSite:'+currProductSite);
                            if(currSalepointSite == currProductSite.Warehouse__c && quantity > 0 && (lineItem.BOM__c == null || (lineItem.BOM__c != null && lineItem.BOM__c == currProductSite.BOM__c))){
                                if(currProductSite.Number_of_Item_In_Stock__c > 0 && currProductSite.Number_of_Item_In_Stock__c >= quantity){
                                    Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) PPLI.Active__c = true;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isUpdateable()) PPLI.Order__c = lineItem.OrderId;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) PPLI.Product__c = lineItem.Product2Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) PPLI.Quantity__c = quantity;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isUpdateable()) PPLI.Order_Product__c = lineItem.Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) PPLI.Site_Product_Service_Inventory_Stock__c = currProductSite.Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isUpdateable()) PPLI.Material_Batch_Lot__c = currProductSite.Batch_Lot__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()) PPLI.BOM__c = currProductSite.BOM__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){
                                        if(lineItem.Order.Stage__c == 'Entered') PPLI.Status__c = 'Reserved';
                                        else if(lineItem.Order.Stage__c == 'Closed') PPLI.Status__c = 'Committed';
                                    }
                                    pplis2Insert.add(PPLI);
                                    succeed = true;
                                    break;
                                }
                                else if(currProductSite.Number_of_Item_In_Stock__c > 0) {
                                    Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) PPLI.Active__c = true;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isUpdateable()) PPLI.Order__c = lineItem.OrderId;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) PPLI.Product__c = lineItem.Product2Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) PPLI.Quantity__c = currProductSite.Number_of_Item_In_Stock__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isUpdateable()) PPLI.Order_Product__c = lineItem.Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) PPLI.Site_Product_Service_Inventory_Stock__c = currProductSite.Id;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isUpdateable()) PPLI.Material_Batch_Lot__c = currProductSite.Batch_Lot__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()) PPLI.BOM__c = currProductSite.BOM__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){
                                        if(lineItem.Order.Stage__c == 'Entered') PPLI.Status__c = 'Reserved';
                                        else if(lineItem.Order.Stage__c == 'Closed') PPLI.Status__c = 'Committed';
                                    }
                                    pplis2Insert.add(PPLI);
                                    quantity -= currProductSite.Number_of_Item_In_Stock__c;
                                }
                            }
                        }  
                        if(succeed){ break; } 
                    }
                } 
                else if(lineItem.Inventory_Tracked__c == true && quantity>0 && (lineItem.Is_Back_Order__c || lineItem.Is_Pre_Order__c) && lineItem.Order.Stage__c == 'Entered'){
                    /*'--- Is Back order or Is Pre order'*/
                    for(Id currSalepointSite : currSalepointSites){
                        List<Inventory_Stock__c> Stocks;
                        if(currProductSites.size() > 0) {
                            Stocks = new list<Inventory_Stock__c>();Stocks.addAll(currProductSites); Inventory_Stock__c Stock = Stocks[0];
                            if(lineItem.BOM__c != null) for(Inventory_Stock__c IS : currProductSites){ if(lineItem.BOM__c == IS.BOM__c){ Stock = IS; break; } }
                            // Stock = (currProductSites.size() > 0)? (new list<Inventory_Stock__c>(currProductSites)[0]) : new Inventory_Stock__c(Active__c = true, Product__c = lineItem.Product__c, Company__c = lineItem.Company__c, Organisation_Business_Unit__c = lineItem.Organisation_Business_Unit__c, Name = 'Stock Requested ' + String.valueof(System.today()), Warehouse__c = currSalepointSite);
                            Stock_Outward_Line_Item__c PPLI = new Stock_Outward_Line_Item__c();
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) PPLI.Active__c = true;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order__c.isUpdateable()) PPLI.Order__c = lineItem.OrderId;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) PPLI.Product__c = lineItem.Product2Id;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) PPLI.Quantity__c = quantity;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Order_Product__c.isUpdateable()) PPLI.Order_Product__c = lineItem.Id;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) PPLI.Site_Product_Service_Inventory_Stock__c = Stock.Id;
                            //PPLI.Material_Batch_Lot__c = Stock.Batch_Lot__c;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()) PPLI.BOM__c = Stock.BOM__c;
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()) PPLI.Status__c = 'Requested';
                            pplis2Insert.add(PPLI);
                            succeed = true;
                            break;
                        }
                    }     
                    if(succeed){ break; } 
                }
            } 
            if(pplis2Insert.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){ DMLManager.UpsertAsUser(pplis2Insert);} else{/*not allowed*/} 
        }
    }
    
    /* Method to delete Product Purchase Line Items for delete of Line Items. */
    global static void deleteProductPurchaseLineItems(List<OrderItem> lineItems){
        Set<Id> lineItemIds = new Set<Id>();
        for(OrderItem lineItem : lineItems){            
            lineItemIds.add(lineItem.Id);
        }  
        
        List<OrderItem> currentLineItems;
        if(Schema.sObjectType.OrderItem.isAccessible()){
            UtilClass.FlsCheck(new String[]{'Base_Price__c','Discount_Amount__c','Invoice__c','UnitPrice','Total_Price__c','VAT_Amount__c','Inventory_Tracked__c','Product2Id','Quantity','OrderId','Loyalty_Points__c','Loyalty_Program__c','Checked_Out_Process__c','Commission__c','Commission_Rate_Card__c','Status__c'},'OrderItem');
            UtilClass.FlsCheck(new String[]{'Sub_Total__c','Total_Discount__c','Total_Due__c','Total_Tax_Amount__c','Channel__c','Stage__c','Is_Back_Order__c'},'Order');
            UtilClass.FlsCheck(new String[]{'SKU__c','Track_Inventory__c'},'Product__c');
            if(!Schema.sObjectType.Commission_Rate_Card__c.fields.Commission_Plan__c.isAccessible()) return ;
            
            currentLineItems = [Select Id, Base_Price__c, Discount_Amount__c, Invoice__c, UnitPrice, Total_Price__c, VAT_Amount__c, Inventory_Tracked__c,
                                Product2Id, Product2.Name, Product2.SKU__c, Quantity, OrderId, Loyalty_Points__c, Loyalty_Program__c,
                                Order.Name, Order.Sub_Total__c, Order.Total_Discount__c, Order.Total_Due__c, Order.Total_Tax_Amount__c, Commission__c, Commission_Rate_Card__c,
                                Commission_Rate_Card__r.Commission_Plan__c, Status__c, Product2.Track_Inventory__c, Order.Channel__c
                                From OrderItem 
                                Where Id In: lineItemIds];
        }
        
        UtilClass.FlsCheck(new String[]{'Active__c','Product__c','Quantity__c','Order_Product__c','Site_Product_Service_Inventory_Stock__c','Status__c'},'Stock_Outward_Line_Item__c');
        List<Stock_Outward_Line_Item__c> pplis2delete = [Select Id, Name, Active__c,  Product__c, Quantity__c, Order_Product__c, Site_Product_Service_Inventory_Stock__c, Status__c, Fixed_Asset__c
                                                         From Stock_Outward_Line_Item__c
                                                         Where Order_Product__c In : lineItemIds And
                                                         Active__c = true ];//and Status__c='Requested'
        List <Id> AssetsIds = new List<Id>();                                                   
        for(Stock_Outward_Line_Item__c soli : pplis2delete) if(soli.Fixed_Asset__c != Null) AssetsIds.add(soli.Fixed_Asset__c);                                                   
        List<Asset__c> assets2Update = [Select Id, Name, Available__c, Status__c From Asset__c  Where Id In :AssetsIds];
        for(Asset__c Asset : assets2Update){
            if(Schema.sObjectType.Asset__c.fields.Available__c.isCreateable() && Schema.sObjectType.Asset__c.fields.Available__c.isUpdateable()) Asset.Available__c = true;
            if(Schema.sObjectType.Asset__c.fields.Status__c.isCreateable() && Schema.sObjectType.Asset__c.fields.Status__c.isUpdateable()) Asset.Status__c = 'Available';
        }                                                    
        
        if(pplis2delete.size() > 0 && Stock_Outward_Line_Item__c.sObjectType.getDescribe().isDeletable()) { delete pplis2delete; } else{ /*not allwed*/}
        if(assets2Update.size() > 0 && Schema.sObjectType.Asset__c.isCreateable() && Schema.sObjectType.Asset__c.isUpdateable()){ DMLManager.upsertAsUser(assets2Update);}else{/*not allowed*/} 
    }
    
}