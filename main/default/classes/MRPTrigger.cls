public with sharing class MRPTrigger{
    public Static void MRPsRollupSummary(Boolean trigger_isExecuting,Boolean trigger_isBefore,Boolean trigger_isAfter,Boolean trigger_isInsert,Boolean trigger_isUpdate,Boolean trigger_isUnDelete,Boolean  trigger_isDelete,String trigger_new1,String trigger_old1){
        List<MRP__c> trigger_new = (List<MRP__c>)JSON.deserialize(trigger_new1, List<MRP__c>.class);
        List<MRP__c> trigger_old = (List<MRP__c>)JSON.deserialize(trigger_old1, List<MRP__c>.class);
        if(trigger_isAfter && !PreventRecursiveLedgerEntry.testCasesTransactions && Trigger.isExecuting)   if(trigger_isInsert || trigger_isUpdate || trigger_isUnDelete) {  list<RollUpSummaryUtility.fieldDefinition> MPSfieldDefinitions = new list<RollUpSummaryUtility.fieldDefinition> {  new RollUpSummaryUtility.fieldDefinition('SUM', 'BOM_Actual_Cost__c', 'Direct_Materials__c')     };        RollUpSummaryUtility.rollUpTrigger(MPSfieldDefinitions, trigger_new, 'MRP__c','Schedule__c', 'Schedule__c', '');  PreventRecursiveLedgerEntry.testCasesTransactions = true;   }
        if(trigger_isAfter && !PreventRecursiveLedgerEntry.testCasesTransactions && Trigger.isExecuting)    if(trigger_isDelete) {     list<RollUpSummaryUtility.fieldDefinition> MPSfieldDefinitions = new list<RollUpSummaryUtility.fieldDefinition> {    new RollUpSummaryUtility.fieldDefinition('SUM', 'BOM_Actual_Cost__c', 'Direct_Materials__c') };  RollUpSummaryUtility.rollUpTrigger(MPSfieldDefinitions, trigger_old, 'MRP__c','Schedule__c', 'Schedule__c', '');    PreventRecursiveLedgerEntry.testCasesTransactions = true;     }

    }

    public Static void ManageSiteDispatchLineItems(Boolean trigger_isExecuting, Boolean trigger_isBefore, Boolean trigger_isAfter, Boolean trigger_isInsert, Boolean trigger_isUpdate, Boolean trigger_isUnDelete, Boolean trigger_isDelete, String trigger_new1, String trigger_old1) {
        List < MRP__c > trigger_new = (List < MRP__c > ) JSON.deserialize(trigger_new1, List < MRP__c > .class);
        List < MRP__c > trigger_old = (List < MRP__c > ) JSON.deserialize(trigger_old1, List < MRP__c > .class);
        List < Id > mrpIds = new List < Id > ();
        List < Id > productIds = new List < Id > ();
        Map < Id, Stock_Outward_Line_Item__c > mySDLI = new Map < Id, Stock_Outward_Line_Item__c > ();
        List < Stock_Outward_Line_Item__c > SDLIs2Upsert = new List < Stock_Outward_Line_Item__c > ();
        Map < Id, List < Inventory_Stock__c >> productSites = new Map < Id, List < Inventory_Stock__c >> ();
        
        
        if (!PreventRecursiveLedgerEntry.testCasesTransactions && trigger_isExecuting && trigger_isAfter) {
            system.debug('ManageSiteDispatchLineItems called');
            PreventRecursiveLedgerEntry.testCasesTransactions = true;
            Set<Id> ordIds=new Set<Id>();
            if (trigger_IsInsert || trigger_IsUndelete || trigger_IsUpdate) {
                for (MRP__c MRP: trigger_New) {
                    mrpIds.add(MRP.Id);
                    productIds.add(MRP.MRP_Product__c);
                    if(MRP.Order_Product__c!=null){
                        ordIds.add(MRP.Order_Product__c);
                    }
                }
                system.debug('mrpIds : ' + mrpIds.size());
                List < Stock_Outward_Line_Item__c > SDLIs;
                if (Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()) {
                    Utilclass.FlsCheck(new String[] {
                        'Active__c',
                            'Batch_Lot_Code__c',
                            'BoM__c',
                            'Process__c',
                            'Schedule__c',
                            'MRP_Material_Requirements_Planning__c',
                            'Product__c',
                            'Purchase_Orders__c',
                            'Quantity__c',
                            'Site_Product_Service_Inventory_Stock__c',
                            'Status__c',
                            'Tax__c',
                            'Total_Amount__c',
                            'Unit_Price__c'
                            }, 'Stock_Outward_Line_Item__c');
                    SDLIs = [Select Id, Name, Active__c, Batch_Lot_Code__c, BoM__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c,
                             Product__c, Purchase_Orders__c, Quantity__c, Manufacturing_Order__c, Scrap__c, Product__r.Serialise__c,
                             Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c, Site_Product_Service_Inventory_Stock__r.Number_of_Item_In_Stock__c
                             From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c In: mrpIds
                            ];
                    system.debug('SDLIs : ' + SDLIs.size());
                }
                List < Inventory_Stock__c > WarehouseItemInventoryStocks;
                if (Schema.sObjectType.Inventory_Stock__c.isAccessible()) {
                    UtilClass.FlsCheck(new String[] {
                        'Active__c',
                            'Company__c',
                            'Warehouse__c',
                            'Product__c',
                            'Number_of_Item_In_Stock__c',
                            'Number_of_Item_Purchased_In__c',
                            'Number_of_Items_Dispatched__c',
                            'No_of_Items_Sold__c',
                            'Checked_In_Date__c'
                            }, 'Inventory_Stock__c');
                    
                    WarehouseItemInventoryStocks = [Select Id, Name, Active__c, Company__c, Warehouse__c,
                                                    Product__c, Number_of_Item_In_Stock__c, Number_of_Item_Purchased_In__c,
                                                    Number_of_Items_Dispatched__c, No_of_Items_Sold__c, Checked_In_Date__c From Inventory_Stock__c
                                                    Where Product__c In: productIds And Active__c = true And Scrap__c = false and Name != 'Awaiting Stock'
                                                    and Number_of_Items_Awaiting_in_Stock__c = 0
                                                    And Number_of_Item_In_Stock__c > 0
                                                    Order By Checked_In_Date__c ASC
                                                   ];
                }
                //to fetch the site
                String siteId='';
                Map<Stock_Outward_Line_Item__c, Inventory_Stock__c> sdliInvMap=new Map<Stock_Outward_Line_Item__c, Inventory_Stock__c>();//for serial products
                List<Inventory_Stock__c> invsToInsert=new List<Inventory_Stock__c>();//for serial stock holder
                if(ordIds.size()>0){
                    List<OrderItem> oItems=[Select Id, OrderId, Order.Channel__c from OrderItem where Id IN :ordIds];
                    if(oItems!=null && oItems.size()>0 && oItems[0].OrderId!=null && oItems[0].Order.Channel__c!=null){
                        List<Distribution_Channel__c> dc=[Select Id, Name, Site__c from Distribution_Channel__c where Channel__c= :oItems[0].Order.Channel__c];
                        if(dc!=null && dc.size()>0 && dc[0].Site__c!=null){
                            siteId=dc[0].Site__c;
                        }
                    }
                }
                //end
                for (Id pId: productIds) {
                    List < Inventory_Stock__c > sites = new List < Inventory_Stock__c > ();
                    for (Inventory_Stock__c WIIS: WarehouseItemInventoryStocks) {
                        if (pId == WIIS.Product__c) sites.add(WIIS);
                    }
                    productSites.put(pId, sites);
                }
                for (MRP__c MRP: trigger_New) {
                    for (Stock_Outward_Line_Item__c SDLI: SDLIs) {
                        if (MRP.Id == SDLI.MRP_Material_Requirements_Planning__c) {
                            mySDLI.put(MRP.Id, SDLI);
                            break;
                        }
                    }
                }
                system.debug('mySDLI : ' + mySDLI.size());
                String MRPFields = UtilClass.selectStarFromSObject('MRP__c');
                String mrpKitRT = 'MRP Kit';
                
                List < MRP__c > AllMRPs = Database.query('select ' + String.escapeSingleQuotes(MRPFields) + ' ,Order_Product__r.OrderId, Purchase_Line_Items__r.Purchase_Orders__c, RecordType.Name, MRP_Product__r.Serialise__c from MRP__c where Id In: mrpIds and RecordType.Name =: mrpKitRT');
                system.debug('AllMRPs : ' + AllMRPs.size());
                for (MRP__c MRP: AllMRPs) {
                    
                    Stock_Outward_Line_Item__c SDLI;
                    system.debug('mySDLI.containsKey(MRP.Id) : ' + mySDLI.containsKey(MRP.Id));
                    system.debug('productSites.containsKey(MRP.MRP_Product__c) : ' + productSites.containsKey(MRP.MRP_Product__c));
                    if (!mySDLI.containsKey(MRP.Id) && productSites.containsKey(MRP.MRP_Product__c) && productSites.get(MRP.MRP_Product__c).size() > 0 && !MRP.MRP_Product__r.Serialise__c) {
                        Decimal MRPallocatedQuantity = 0.0;
                        List < Inventory_Stock__c > WIISs = productSites.get(MRP.MRP_Product__c);
                        //Inventory_Stock__c WIIS = (MRP.Check_Out_Process__c == 'LIFO')? WIISs[WIISs.size()-1] : WIISs[0];
                        for (Inventory_Stock__c WIIS: WIISs) {
                            if (WIIS.Number_of_Item_In_Stock__c > 0 && WIIS.Number_of_Item_In_Stock__c >= MRP.Total_Amount_Required__c && MRPallocatedQuantity == 0.0) {
                                SDLI = new Stock_Outward_Line_Item__c();
                                if (Schema.sObjectType.MRP__c.fields.Name.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()) {
                                    SDLI.Name = MRP.Name;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                                    SDLI.Active__c = true;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.Process__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isUpdateable()) {
                                    SDLI.Process__c = MRP.Process__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.Schedule__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isUpdateable()) {
                                    SDLI.Schedule__c = MRP.Schedule__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                                    SDLI.MRP_Material_Requirements_Planning__c = MRP.Id;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()) {
                                    SDLI.BoM__c = MRP.BOM__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                                    SDLI.Quantity__c = MRP.Total_Amount_Required__c;
                                    MRPallocatedQuantity += SDLI.Quantity__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()) {
                                    SDLI.Status__c = 'Reserved';
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                                    SDLI.Product__c = MRP.MRP_Product__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.Inventory_Stock__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) {
                                    SDLI.Site_Product_Service_Inventory_Stock__c = WIIS.Id;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.MO__c.isAccessible() && MRP.MO__c != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                    SDLI.Manufacturing_Order__c = MRP.MO__c;
                                } else {
                                    /*No access*/ }
                                if (MRP.BOM_Requirement_Cost__c != Null) {
                                    if (Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isUpdateable()) {
                                        SDLI.Total_Amount__c = MRP.BOM_Requirement_Cost__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isUpdateable()) {
                                        SDLI.Unit_Price__c = (MRP.Total_Amount_Required__c != Null && MRP.Total_Amount_Required__c > 0) ? MRP.BOM_Requirement_Cost__c / MRP.Total_Amount_Required__c : 0;
                                    } else {
                                        /*No access*/ }
                                }
                                
                                if (MRP.Order_Product__c != null) {
                                    SDLI.Order_Product__c = MRP.Order_Product__c;
                                    SDLI.Order__c = MRP.Order_Product__r.OrderId;
                                    SDLI.Status__c = MRP.Status__c;
                                    system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                }
                                if (MRP.Purchase_Line_Items__c != Null) {
                                    if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable()) {
                                        SDLI.Purchase_Line_Items__c = MRP.Purchase_Line_Items__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isUpdateable()) {
                                        SDLI.Purchase_Orders__c = MRP.Purchase_Line_Items__r.Purchase_Orders__c;
                                    } else {
                                        /*No access*/ }
                                }
                                if (MRP.Work_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()) {
                                    SDLI.Work_Orders__c = MRP.Work_Order__c;
                                } else {
                                    /*No access*/ }
                                if (MRP.Work_Order_Line_Items__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable()) {
                                    SDLI.Work_Order_Line_Items__c = MRP.Work_Order_Line_Items__c;
                                } else {
                                    /*No access*/ }
                                
                                if (MRP.Transfer_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isUpdateable()) {
                                    SDLI.Transfer_Order__c = MRP.Transfer_Order__c;
                                } else {
                                    /*No access*/ }
                                if (MRP.Transfer_Order_Line_Item__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable()) {
                                    SDLI.Transfer_Order_Line_Item__c = MRP.Transfer_Order_Line_Item__c;
                                } else {
                                    /*No access*/ }
                                if (MRP.MO__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                    SDLI.Manufacturing_Order__c = MRP.MO__c;
                                } else {
                                    /*No access*/ }
                                //if(MRP.MO__c != Null)
                                SDLIs2Upsert.add(SDLI);
                            } else if (WIIS.Number_of_Item_In_Stock__c > 0) {
                                system.debug('MRPallocatedQuantity : ' + MRPallocatedQuantity);
                                system.debug('MRP.Total_Amount_Required__c bfr: ' + MRP.Total_Amount_Required__c);
                                if (MRPallocatedQuantity < MRP.Total_Amount_Required__c) {
                                    SDLI = new Stock_Outward_Line_Item__c();
                                    if (Schema.sObjectType.MRP__c.fields.Name.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()) {
                                        SDLI.Name = MRP.Name;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                                        SDLI.Active__c = true;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.Process__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isUpdateable()) {
                                        SDLI.Process__c = MRP.Process__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.Schedule__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isUpdateable()) {
                                        SDLI.Schedule__c = MRP.Schedule__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                                        SDLI.MRP_Material_Requirements_Planning__c = MRP.Id;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()) {
                                        SDLI.BoM__c = MRP.BOM__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                                        if (WIIS.Number_of_Item_In_Stock__c > (MRP.Total_Amount_Required__c - MRPallocatedQuantity)) {
                                            SDLI.Quantity__c = (MRP.Total_Amount_Required__c - MRPallocatedQuantity);
                                        } else SDLI.Quantity__c = WIIS.Number_of_Item_In_Stock__c;
                                        MRPallocatedQuantity += SDLI.Quantity__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()) {
                                        SDLI.Status__c = 'Reserved';
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                                        SDLI.Product__c = MRP.MRP_Product__c;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.Inventory_Stock__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) {
                                        SDLI.Site_Product_Service_Inventory_Stock__c = WIIS.Id;
                                    } else {
                                        /*No access*/ }
                                    if (Schema.sObjectType.MRP__c.fields.MO__c.isAccessible() && MRP.MO__c != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                        SDLI.Manufacturing_Order__c = MRP.MO__c;
                                    } else {
                                        /*No access*/ }
                                    if (MRP.BOM_Requirement_Cost__c != Null) {
                                        if (Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isUpdateable()) {
                                            SDLI.Total_Amount__c = MRP.BOM_Requirement_Cost__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isUpdateable()) {
                                            SDLI.Unit_Price__c = (MRP.Total_Amount_Required__c != Null && MRP.Total_Amount_Required__c > 0) ? MRP.BOM_Requirement_Cost__c / MRP.Total_Amount_Required__c : 0;
                                        } else {
                                            /*No access*/ }
                                    }
                                    if (MRP.Order_Product__c != null) {
                                        SDLI.Order_Product__c = MRP.Order_Product__c;
                                        SDLI.Order__c = MRP.Order_Product__r.OrderId;
                                        SDLI.Status__c = MRP.Status__c;
                                        system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                    }
                                    if (MRP.Purchase_Line_Items__c != Null) {
                                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable()) {
                                            SDLI.Purchase_Line_Items__c = MRP.Purchase_Line_Items__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isUpdateable()) {
                                            SDLI.Purchase_Orders__c = MRP.Purchase_Line_Items__r.Purchase_Orders__c;
                                        } else {
                                            /*No access*/ }
                                    }
                                    if (MRP.Work_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()) {
                                        SDLI.Work_Orders__c = MRP.Work_Order__c;
                                    } else {
                                        /*No access*/ }
                                    if (MRP.Work_Order_Line_Items__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable()) {
                                        SDLI.Work_Order_Line_Items__c = MRP.Work_Order_Line_Items__c;
                                    } else {
                                        /*No access*/ }
                                    if (MRP.Transfer_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isUpdateable()) {
                                        SDLI.Transfer_Order__c = MRP.Transfer_Order__c;
                                    } else {
                                        /*No access*/ }
                                    if (MRP.Transfer_Order_Line_Item__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable()) {
                                        SDLI.Transfer_Order_Line_Item__c = MRP.Transfer_Order_Line_Item__c;
                                    } else {
                                        /*No access*/ }
                                    if (MRP.MO__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                        SDLI.Manufacturing_Order__c = MRP.MO__c;
                                    } else {
                                        /*No access*/ }
                                    SDLIs2Upsert.add(SDLI);
                                }
                            }
                        }
                        
                    } else if (mySDLI.containsKey(MRP.Id)) {
                        Decimal MRPallocatedQuantity = 0.0;
                        SDLI = mySDLI.get(MRP.Id);
                        system.debug('SDLI.Site_Product_Service_Inventory_Stock__r.Number_of_Item_In_Stock__c : ' + SDLI.Site_Product_Service_Inventory_Stock__r.Number_of_Item_In_Stock__c);
                        system.debug('SDLI.Quantity__c : ' + SDLI.Quantity__c);
                        if ((SDLI.Site_Product_Service_Inventory_Stock__r.Number_of_Item_In_Stock__c + SDLI.Quantity__c) >= SDLI.Quantity__c && SDLI.Status__c == 'Reserved') {
                            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                                SDLI.Active__c = true;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.fields.Process__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isUpdateable()) {
                                SDLI.Process__c = MRP.Process__c;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.fields.Schedule__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isUpdateable()) {
                                SDLI.Schedule__c = MRP.Schedule__c;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                                SDLI.MRP_Material_Requirements_Planning__c = MRP.Id;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()) {
                                SDLI.BoM__c = MRP.BOM__c;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.fields.MO__c.isAccessible() && MRP.MO__c != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                SDLI.Manufacturing_Order__c = MRP.MO__c;
                            } else {
                                /*No access*/ }
                            if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                                MRPallocatedQuantity = SDLI.Quantity__c;
                            } else {
                                /*No access*/ } /*SDLI.Quantity__c = MRP.Total_Amount_Required__c;*/
                            if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                                SDLI.Product__c = MRP.MRP_Product__c;
                            } else {
                                /*No access*/ }
                            if (MRP.BOM_Requirement_Cost__c != Null) {
                                if (Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isUpdateable()) {
                                    SDLI.Total_Amount__c = MRP.BOM_Requirement_Cost__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isUpdateable()) {
                                    SDLI.Unit_Price__c = (MRP.Total_Amount_Required__c != Null && MRP.Total_Amount_Required__c > 0) ? MRP.BOM_Requirement_Cost__c / MRP.Total_Amount_Required__c : 0;
                                } else {
                                    /*No access*/ }
                            }
                            if (MRP.Order_Product__c != Null) {
                                SDLI.Order_Product__c = MRP.Order_Product__c;
                                SDLI.Order__c = MRP.Order_Product__r.OrderId;
                                SDLI.Status__c = MRP.Status__c;
                            }
                            if (MRP.Purchase_Line_Items__c != Null) {
                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable()) {
                                    SDLI.Purchase_Line_Items__c = MRP.Purchase_Line_Items__c;
                                } else {
                                    /*No access*/ }
                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isUpdateable()) {
                                    SDLI.Purchase_Orders__c = MRP.Purchase_Line_Items__r.Purchase_Orders__c;
                                } else {
                                    /*No access*/ }
                            }
                            if (MRP.Work_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()) {
                                SDLI.Work_Orders__c = MRP.Work_Order__c;
                            } else {
                                /*No access*/ }
                            if (MRP.Work_Order_Line_Items__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable()) {
                                SDLI.Work_Order_Line_Items__c = MRP.Work_Order_Line_Items__c;
                            } else {
                                /*No access*/ }
                            if (MRP.Transfer_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isUpdateable()) {
                                SDLI.Transfer_Order__c = MRP.Transfer_Order__c;
                            } else {
                                /*No access*/ }
                            if (MRP.Transfer_Order_Line_Item__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable()) {
                                SDLI.Transfer_Order_Line_Item__c = MRP.Transfer_Order_Line_Item__c;
                            } else {
                                /*No access*/ }
                            if (MRP.MO__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                SDLI.Manufacturing_Order__c = MRP.MO__c;
                            } else {
                                /*No access*/ } /*if(MRP.MO__c != Null)*/
                            SDLIs2Upsert.add(SDLI);
                        } else {
                            system.debug('MRPallocatedQuantity else : ' + MRPallocatedQuantity);
                            if (productSites.containsKey(MRP.MRP_Product__c) && !MRP.MRP_Product__r.Serialise__c) {
                                system.debug('MRP.Total_Amount_Required__c if : ' + MRP.Total_Amount_Required__c);
                                List < Inventory_Stock__c > WIISs = productSites.get(MRP.MRP_Product__c);
                                for (Inventory_Stock__c WIIS: WIISs) {
                                    if (WIIS.Number_of_Item_In_Stock__c > 0 && WIIS.Number_of_Item_In_Stock__c >= MRP.Total_Amount_Required__c && MRPallocatedQuantity == 0.0) {
                                        system.debug(' if 1 ');
                                        if (Schema.sObjectType.MRP__c.fields.Name.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()) {
                                            SDLI.Name = MRP.Name;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                                            SDLI.Active__c = true;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.Process__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isUpdateable()) {
                                            SDLI.Process__c = MRP.Process__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.Schedule__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isUpdateable()) {
                                            SDLI.Schedule__c = MRP.Schedule__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                                            SDLI.MRP_Material_Requirements_Planning__c = MRP.Id;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()) {
                                            SDLI.BoM__c = MRP.BOM__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                                            SDLI.Quantity__c = MRP.Total_Amount_Required__c;
                                            MRPallocatedQuantity += SDLI.Quantity__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()) {
                                            SDLI.Status__c = 'Reserved';
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                                            SDLI.Product__c = MRP.MRP_Product__c;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.Inventory_Stock__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) {
                                            SDLI.Site_Product_Service_Inventory_Stock__c = WIIS.Id;
                                        } else {
                                            /*No access*/ }
                                        if (Schema.sObjectType.MRP__c.fields.MO__c.isAccessible() && MRP.MO__c != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                            SDLI.Manufacturing_Order__c = MRP.MO__c;
                                        } else {
                                            /*No access*/ }
                                        if (MRP.BOM_Requirement_Cost__c != Null) {
                                            if (Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isUpdateable()) {
                                                SDLI.Total_Amount__c = MRP.BOM_Requirement_Cost__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isUpdateable()) {
                                                SDLI.Unit_Price__c = (MRP.Total_Amount_Required__c != Null && MRP.Total_Amount_Required__c > 0) ? MRP.BOM_Requirement_Cost__c / MRP.Total_Amount_Required__c : 0;
                                            } else {
                                                /*No access*/ }
                                        }
                                        system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                        if (MRP.Order_Product__c != null) {
                                            SDLI.Order_Product__c = MRP.Order_Product__c;
                                            SDLI.Order__c = MRP.Order_Product__r.OrderId;
                                            SDLI.Status__c = MRP.Status__c;
                                            system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                        }
                                        if (MRP.Purchase_Line_Items__c != Null) {
                                            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable()) {
                                                SDLI.Purchase_Line_Items__c = MRP.Purchase_Line_Items__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isUpdateable()) {
                                                SDLI.Purchase_Orders__c = MRP.Purchase_Line_Items__r.Purchase_Orders__c;
                                            } else {
                                                /*No access*/ }
                                        }
                                        if (MRP.Work_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()) {
                                            SDLI.Work_Orders__c = MRP.Work_Order__c;
                                        } else {
                                            /*No access*/ }
                                        if (MRP.Work_Order_Line_Items__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable()) {
                                            SDLI.Work_Order_Line_Items__c = MRP.Work_Order_Line_Items__c;
                                        } else {
                                            /*No access*/ }
                                        if (MRP.Transfer_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isUpdateable()) {
                                            SDLI.Transfer_Order__c = MRP.Transfer_Order__c;
                                        } else {
                                            /*No access*/ }
                                        if (MRP.Transfer_Order_Line_Item__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable()) {
                                            SDLI.Transfer_Order_Line_Item__c = MRP.Transfer_Order_Line_Item__c;
                                        } else {
                                            /*No access*/ }
                                        if (MRP.MO__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                            SDLI.Manufacturing_Order__c = MRP.MO__c;
                                        } else {
                                            /*No access*/ }
                                        SDLIs2Upsert.add(SDLI);
                                    } else if (WIIS.Number_of_Item_In_Stock__c > 0) {
                                        system.debug('MRPallocatedQuantity else 2: ' + MRPallocatedQuantity);
                                        system.debug('MRP.Total_Amount_Required__c bfr: ' + MRP.Total_Amount_Required__c);
                                        if (MRPallocatedQuantity < MRP.Total_Amount_Required__c) {
                                            if (Schema.sObjectType.MRP__c.fields.Name.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()) {
                                                SDLI.Name = MRP.Name;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                                                SDLI.Active__c = true;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.Process__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Process__c.isUpdateable()) {
                                                SDLI.Process__c = MRP.Process__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.Schedule__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Schedule__c.isUpdateable()) {
                                                SDLI.Schedule__c = MRP.Schedule__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                                                SDLI.MRP_Material_Requirements_Planning__c = MRP.Id;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()) {
                                                SDLI.BoM__c = MRP.BOM__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                                                if (WIIS.Number_of_Item_In_Stock__c > (MRP.Total_Amount_Required__c - MRPallocatedQuantity)) {
                                                    SDLI.Quantity__c = (MRP.Total_Amount_Required__c - MRPallocatedQuantity);
                                                } else SDLI.Quantity__c = WIIS.Number_of_Item_In_Stock__c;
                                                MRPallocatedQuantity += SDLI.Quantity__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()) {
                                                SDLI.Status__c = 'Reserved';
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                                                SDLI.Product__c = MRP.MRP_Product__c;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.Inventory_Stock__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()) {
                                                SDLI.Site_Product_Service_Inventory_Stock__c = WIIS.Id;
                                            } else {
                                                /*No access*/ }
                                            if (Schema.sObjectType.MRP__c.fields.MO__c.isAccessible() && MRP.MO__c != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                                SDLI.Manufacturing_Order__c = MRP.MO__c;
                                            } else {
                                                /*No access*/ }
                                            if (MRP.BOM_Requirement_Cost__c != Null) {
                                                if (Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Total_Amount__c.isUpdateable()) {
                                                    SDLI.Total_Amount__c = MRP.BOM_Requirement_Cost__c;
                                                } else {
                                                    /*No access*/ }
                                                if (Schema.sObjectType.MRP__c.fields.Required_Amount__c.isAccessible() && Schema.sObjectType.MRP__c.fields.BOM_Requirement_Cost__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Unit_Price__c.isUpdateable()) {
                                                    SDLI.Unit_Price__c = (MRP.Total_Amount_Required__c != Null && MRP.Total_Amount_Required__c > 0) ? MRP.BOM_Requirement_Cost__c / MRP.Total_Amount_Required__c : 0;
                                                } else {
                                                    /*No access*/ }
                                            }
                                            system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                            system.debug('SDLI.Quantity__c : ' + SDLI.Quantity__c);
                                            system.debug('MRP.Total_Amount_Required__c after: ' + MRP.Total_Amount_Required__c);
                                            if (MRP.Order_Product__c != null) {
                                                SDLI.Order_Product__c = MRP.Order_Product__c;
                                                SDLI.Order__c = MRP.Order_Product__r.OrderId;
                                                SDLI.Status__c = MRP.Status__c;
                                                system.debug('SDLI.Status__c : ' + SDLI.Status__c);
                                            }
                                            if (MRP.Purchase_Line_Items__c != Null) {
                                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable()) {
                                                    SDLI.Purchase_Line_Items__c = MRP.Purchase_Line_Items__c;
                                                } else {
                                                    /*No access*/ }
                                                if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Purchase_Orders__c.isUpdateable()) {
                                                    SDLI.Purchase_Orders__c = MRP.Purchase_Line_Items__r.Purchase_Orders__c;
                                                } else {
                                                    /*No access*/ }
                                            }
                                            if (MRP.Work_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()) {
                                                SDLI.Work_Orders__c = MRP.Work_Order__c;
                                            } else {
                                                /*No access*/ }
                                            if (MRP.Work_Order_Line_Items__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable()) {
                                                SDLI.Work_Order_Line_Items__c = MRP.Work_Order_Line_Items__c;
                                            } else {
                                                /*No access*/ }
                                            if (MRP.Transfer_Order__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order__c.isUpdateable()) {
                                                SDLI.Transfer_Order__c = MRP.Transfer_Order__c;
                                            } else {
                                                /*No access*/ }
                                            if (MRP.Transfer_Order_Line_Item__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable()) {
                                                SDLI.Transfer_Order_Line_Item__c = MRP.Transfer_Order_Line_Item__c;
                                            } else {
                                                /*No access*/ }
                                            if (MRP.MO__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()) {
                                                SDLI.Manufacturing_Order__c = MRP.MO__c;
                                            } else {
                                                /*No access*/ }
                                            SDLIs2Upsert.add(SDLI);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if(MRP.MRP_Product__r.Serialise__c && mySDLI.containsKey(MRP.Id)){
                        Stock_Outward_Line_Item__c sdliNew = mySDLI.get(MRP.Id);
                        if(sdliNew!=null && sdliNew.Name == 'Serial Stock Holder'){
                            if(sdliNew.Quantity__c != MRP.Total_Amount_Required__c - MRP.Consumed_Quantity__c){
                                sdliNew.Quantity__c = (MRP.Total_Amount_Required__c - MRP.Consumed_Quantity__c) * 1;//remove negative sign by zain
                                SDLIs2Upsert.add(sdliNew);
                            }
                        }
                    }else if(MRP.MRP_Product__r.Serialise__c && !mySDLI.containsKey(MRP.Id)){
                        Inventory_Stock__c inv = new Inventory_Stock__c(Name = 'Serial Stock Holder', Active__c = true, Product__c = MRP.MRP_Product__c);
                        Stock_Outward_Line_Item__c sdliNew = new Stock_Outward_Line_Item__c();
                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()) {
                            sdliNew.Name = 'Serial Stock Holder';
                        }
                        if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()) {
                            sdliNew.Active__c = true;
                        }
                        if (Schema.sObjectType.MRP__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()) {
                            sdliNew.MRP_Material_Requirements_Planning__c = MRP.Id;
                        }
                        if (Schema.sObjectType.MRP__c.fields.MRP_Product__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()) {
                            sdliNew.Product__c = MRP.MRP_Product__c;
                        }
                        if(Schema.sObjectType.MRP__c.fields.BOM__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isUpdateable()){
                            sdliNew.BoM__c = MRP.BOM__c;
                        }
                        if(Schema.sObjectType.MRP__c.fields.Total_Amount_Required__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){
                            sdliNew.Quantity__c = MRP.Total_Amount_Required__c!=null?MRP.Total_Amount_Required__c * (1):0;//remove negative sign by zain
                        }
                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isAccessible() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable()){
                            sdliNew.Status__c = 'Reserved';
                        }
                        if(Schema.sObjectType.MRP__c.fields.Order_Product__c.isAccessible() && MRP.Order_Product__c != null){
                            sdliNew.Order_Product__c = MRP.Order_Product__c;
                            sdliNew.Order__c = MRP.Order_Product__r.OrderId;
                        }
                        
                        
                        if(siteId!=null && siteId!=''){
                            System.debug('siteId : ' + siteId);
                            inv.Warehouse__c = siteId;
                            invsToInsert.add(inv);
                            sdliInvMap.put(sdliNew, inv);
                        }
                      //  SDLIs2Upsert.add(sdliNew);
                    }
                    
                    
                }
                
                //only for serial products
                if(invsToInsert.size()>0 && Schema.sObjectType.Inventory_Stock__c.isCreateable() && Schema.sObjectType.Inventory_Stock__c.isUpdateable()){
                    try{
                        System.debug('invsToInsert before insert: ' + invsToInsert.size());
                        insert invsToInsert;
                    }catch(exception e){
                        system.debug('Error in insert Inventory_Stock__c : ' + e.getMessage());
                    }
                    for(Stock_Outward_Line_Item__c sdliKey : sdliInvMap.keySet()){
                        Inventory_Stock__c invVal = sdliInvMap.get(sdliKey);
                        System.debug('invVal.Id : ' + invVal.Id);
                        system.debug('sdliKey.Name : ' + sdliKey.Name);
                        if(invVal!=null && invVal.Id!=null){
                            sdliKey.Site_Product_Service_Inventory_Stock__c = invVal.Id;
                            System.debug('adding sdli to SDLIs2Upsert');
                            SDLIs2Upsert.add(sdliKey);
                        }
                        
                    }
                }
                //
                
                if (SDLIs2Upsert.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()) {
                    set < Stock_Outward_Line_Item__c > outwardset = new set < Stock_Outward_Line_Item__c > ();
                    outwardset.addAll(SDLIs2Upsert);
                    system.debug('outwardset MRPTrigger : ' + outwardset.size());
                    SDLIs2Upsert = new List < Stock_Outward_Line_Item__c > ();
                    SDLIs2Upsert.addAll(outwardset);
                    system.debug('SDLIs2Upsert MRPTrigger : ' + SDLIs2Upsert.size());
                    try {
                        upsert SDLIs2Upsert;
                    } catch (exception e) {
                        system.debug('Error in upsert : ' + e.getMessage());
                    }
                } else {}
                
            }
            
            if (trigger_isBefore && trigger_IsDelete) {
                for (MRP__c MRP: trigger_Old) {
                    mrpIds.add(MRP.Id);
                }
                List < Stock_Outward_Line_Item__c > SDLIs;
                if (Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()) {
                    SDLIs = [Select Id, Name, Active__c, Batch_Lot_Code__c, BoM__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c, Product__c, Purchase_Orders__c, Quantity__c, Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c In: mrpIds];
                }
                if (SDLIs.size() > 0)
                    if (Stock_Outward_Line_Item__c.sObjectType.getDescribe().isDeletable()) delete SDLIs;
            }
            
        }
    }

    // added by Abuzar for handling the Scheadule MO scenario for huge quantity of MRP records on 03-12-2025 converted the flow "Set Cost of BOM to Work orders" to the trigger 
     // -------------------------------------------------
    // BEFORE INSERT/UPDATE: Set BOM_Actual_Cost__c & BOM_Requirement_Cost__c
    // (replaces Flow formulas BOMActualCost & BOMRequirementCost)
    // -------------------------------------------------
    public static void handleBeforeBOMCost(List<MRP__c> newList) {
        system.debug('AZ MRPTrigger.handleBeforeBOMCost - Start');
        if (newList == null || newList.isEmpty()) return;

        // Collect BOM Line Item ids
        Set<Id> bomLineItemIds = new Set<Id>();
        for (MRP__c mrp : newList) {
            if (mrp.BOM_Line_Item__c != null) {
                bomLineItemIds.add(mrp.BOM_Line_Item__c);
            }
        }
        if (bomLineItemIds.isEmpty()) return;

        // Query BOM Line Items with Cost Card & Cost
        Map<Id, BOM_Line_Item__c> bomLineItemById = new Map<Id, BOM_Line_Item__c>([
            SELECT Id,
                   Cost_Price__c,
                   Cost_Card__c,
                   Cost_Card__r.Cost__c
            FROM BOM_Line_Item__c
            WHERE Id IN :bomLineItemIds
        ]);

        // Compute BOM_Actual_Cost__c and BOM_Requirement_Cost__c
        for (MRP__c mrp : newList) {
            if (mrp.Work_Order__c == null || mrp.BOM_Line_Item__c == null) continue;

            BOM_Line_Item__c bli = bomLineItemById.get(mrp.BOM_Line_Item__c);
            if (bli == null) continue;

            // Same logic as Flow formulas:
            // if(Cost_Card__c != null, Cost_Card__r.Cost__c, Cost_Price__c)
            Decimal unitCost = 0;
            if (bli.Cost_Card__c != null && bli.Cost_Card__r != null && bli.Cost_Card__r.Cost__c != null) {
                unitCost = bli.Cost_Card__r.Cost__c;
            } else if (bli.Cost_Price__c != null) {
                unitCost = bli.Cost_Price__c;
            }

            Decimal fulfilledAmt = (mrp.Fulfilled_Amount__c == null) ? 0 : mrp.Fulfilled_Amount__c;
            Decimal requiredAmt  = (mrp.Required_Amount__c  == null) ? 0 : mrp.Required_Amount__c;

            mrp.BOM_Actual_Cost__c      = unitCost * fulfilledAmt;
            mrp.BOM_Requirement_Cost__c = unitCost * requiredAmt;
        }
    }

    // -------------------------------------------------
    // AFTER INSERT/UPDATE: Sum BOM_Actual_Cost__c into WO__c.Material_Cost__c
    // (replaces Flow: Get_all_MRPS_associated_with_Work_Order + loop + Get_total_BOM_Cost + Update_Work_orders)
    // -------------------------------------------------
    public static void handleAfterBOMCost(List<MRP__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        // Only records matching Flow start condition: Work_Order__c != null AND BOM_Line_Item__c != null
        Set<Id> workOrderIds = new Set<Id>();
        Map<Id, String> workOrderToKey = new Map<Id, String>(); // WO -> (WO|BOM|MO) key

        for (MRP__c mrp : newList) {
            if (mrp.Work_Order__c != null && mrp.BOM_Line_Item__c != null) {
                workOrderIds.add(mrp.Work_Order__c);
                String key = buildGroupingKey(mrp.Work_Order__c, mrp.BOM__c, mrp.MO__c);
                // Last record per WO in this tx wins, same idea as Flow executing per-record
                workOrderToKey.put(mrp.Work_Order__c, key);
            }
        }

        if (workOrderIds.isEmpty()) return;

        Set<String> keysToCalculate = new Set<String>(workOrderToKey.values());

        // Get all MRP__c for these Work Orders (like the Flow lookup),
        // only ones with BOM_Line_Item__c != null.
        List<MRP__c> relatedMrps = [
            SELECT Id,
                   Work_Order__c,
                   BOM__c,
                   MO__c,
                   BOM_Line_Item__c,
                   BOM_Actual_Cost__c
            FROM MRP__c
            WHERE Work_Order__c IN :workOrderIds
              AND BOM_Line_Item__c != null
        ];

        // Sum BOM_Actual_Cost__c per (Work_Order__c, BOM__c, MO__c)
        Map<String, Decimal> totalCostByKey = new Map<String, Decimal>();
        for (MRP__c mrp : relatedMrps) {
            String key = buildGroupingKey(mrp.Work_Order__c, mrp.BOM__c, mrp.MO__c);

            // Only calculate for combos touched in this transaction
            if (!keysToCalculate.contains(key)) continue;

            Decimal existing = totalCostByKey.containsKey(key) ? totalCostByKey.get(key) : 0;
            Decimal cost     = (mrp.BOM_Actual_Cost__c == null) ? 0 : mrp.BOM_Actual_Cost__c;
            totalCostByKey.put(key, existing + cost);
        }

        // Prepare Work Orders to update Material_Cost__c
        List<WO__c> workOrdersToUpdate = new List<WO__c>();
        for (Id woId : workOrderToKey.keySet()) {
            String key = workOrderToKey.get(woId);
            Decimal totalCost = totalCostByKey.containsKey(key) ? totalCostByKey.get(key) : 0;

            workOrdersToUpdate.add(new WO__c(
                Id               = woId,
                Material_Cost__c = totalCost
            ));
        }

        if (!workOrdersToUpdate.isEmpty()) {
            update workOrdersToUpdate;
        }
    }

    // Helper: same grouping as Flow filters (Work_Order__c, BOM__c, MO__c)
    private static String buildGroupingKey(Id workOrderId, Id bomId, Id moId) {
        return String.valueOf(workOrderId) + '|' +
               String.valueOf(bomId)       + '|' +
               String.valueOf(moId);
    }
    
}