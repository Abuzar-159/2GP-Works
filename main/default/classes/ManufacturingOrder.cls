global with sharing class ManufacturingOrder {

    @AuraEnabled
    public static comWrap getAll(String vmoy,Boolean applyLimit,Boolean ShowAllWO) {
        comWrap comW = new comWrap();
        try{
            system.debug('getAll called');

            String AllTaskFields ='Id,Name, Type__c,Work_Center__r.Name, Work_Center__r.Supervisor__c, Work_Center__r.Supervisor__r.Name, Work_Order__r.Process_Cycle__c, Operation__r.Is_Signature_Required__c, Operation__r.Timer__c, Operation__r.Label_Generator__c, Operation__r.Sort__c, Reviewed_By__r.Name,Status__c,Finished_Quantity__c,Auto_Clock_In__c,Start_Date__c,End_Date__c ';
            String TSFields = UtilClass.selectStarFromSObject('Timesheet__c');
            String AllTSFields = TSFields + '';
            String TSEFields = UtilClass.selectStarFromSObject('Time_Card_Entry__c');
            String AllTSEFields = TSEFields + ', Timesheet__r.Work_Order__c, Timesheet__r.Employees__r.Name, Timesheet__r.Employees__r.Employee_User__c, Action_Task__r.Auto_Clock_In__c ';
            String ProductFields = UtilClass.selectStarFromSObject('Product2');
            String AllProductFields = ProductFields + '';
            String RoutingFields = UtilClass.selectStarFromSObject('Routing__c');
            String AllRoutingFields = RoutingFields + '';
            String VersionFields = UtilClass.selectStarFromSObject('BOM__c');
            String AllVersionFields = VersionFields + '';

            Schema.DescribeFieldResult fieldResult = Manufacturing_Order__c.Status__c.getDescribe();
            List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
            for(Schema.PicklistEntry f: ple) {
                comW.moStatus.add(new SelectOptions(f.getLabel(), f.getValue()));
            }

            if(vmoy != '' && vmoy != Null){
                system.debug('inhere vmoy~>'+vmoy);

                comW.manuOrders = Database.query('SELECT Id,Name,End_Date__c,Quantity_Scrapped__c,Manufacturing_Order__c,Quantity_Produced__c, Product__r.Quality_Check_QA__c,Product__r.QA_Handling_Inbound_Post_MO_Completion__c,Product__r.UoM__c,Routing__c,Routing__r.Max_Allowed_Cuts__c,Routing__r.Name,Routing__r.Raw_Materials_Site__c,Routing__r.Auto_Stock_Allocation__c,Manufacturing_Order__r.Name,Quantity__c,BOM__c,BOM__r.Name,Status__c,StartDate__c,ExpectedDate__c,Order__c,Order__r.Name,Order_Product__c,Order_Product__r.OrderItemNumber,Labour_Cost__c,Material_Cost__c,Overhead_Cost__c,Cost__c,Scrap_Cost__c,Product__c,Product__r.Name,Product__r.QuantityUnitOfMeasure,Product__r.Serialise__c,Product__r.Lot_Tracked__c,Rejected_Cost__c FROM Manufacturing_Order__c WHERE Id = :vmoy Limit 1');

                Map<String,Manufacturing_Order__c> prodMRPsMoMap = new Map<String,Manufacturing_Order__c>();

                for(Manufacturing_Order__c cMO : Database.query('SELECT Id,Name,Routing__c,Routing__r.Name,Routing__r.Raw_Materials_Site__c,Manufacturing_Order__c,Routing__r.Auto_Stock_Allocation__c,Manufacturing_Order__r.Name,Quantity__c,BOM__c,BOM__r.Name,Status__c,StartDate__c,ExpectedDate__c,Order__c,Order__r.Name,Order_Product__c,Labour_Cost__c,Material_Cost__c,Overhead_Cost__c,Cost__c,Product__c,Product__r.Name,Product__r.QuantityUnitOfMeasure,Product__r.Serialise__c,Product__r.Lot_Tracked__c FROM Manufacturing_Order__c WHERE Manufacturing_Order__c = :vmoy ')){      if(cMO.Product__c != null && cMO.MRP_Material_Requirement_Planning__c != null){    String key = ''+cMO.Product__c+cMO.MRP_Material_Requirement_Planning__c+'';  prodMRPsMoMap.put(key, cMO); }    }

                List<MRP__c> MRPs = [Select Id, Name,BOM_unit_Price__c, BOM_Line_Item__r.Cost_Price__c, Total_Amount_Required__c, BOM_Line_Item__c,toLabel( BOM_Line_Item__r.Unit_of_Measure__c), BOM_Line_Item__r.Name, BOM_Line_Item__r.BOM__c, MRP_Product__c, MRP_Product__r.Name, MRP_Product__r.ProductCode,MRP_Product__r.Vendor_product_Name__c,MRP_Product__r.Picture__c, MRP_Product__r.Preview_Image__c,Order_Product__c , RecordType.Name, Expected_Quantity__c, Minimum_Variance__c, Maximum_Variance__c, BOM_Line_Item__r.Exact_Quantity__c,
                                           Work_Order__c, Work_Order__r.Name, Work_Order_Line_Items__c, MO__c, MO__r.BOM__c,MO__r.Quantity__c, Fulfilled_Amount__c, BOM_Line_Item__r.Is_Protected__c, MO__r.Routing__r.Raw_Materials_Site__c, Consumed_Quantity__c, Scrapped_Quantity__c, MRP_Product__r.Issue_Purchase_Order__c, MRP_Product__r.Issue_Manufacturing_Order__c, Status__c, MRP_Product__r.Serialise__c, MRP_Product__r.Lot_Tracked__c,
                                           BOM_Line_Item__r.Quantity__c, BOM_Line_Item__r.Minimum_Variance__c, BOM_Line_Item__r.Maximum_Variance__c, BOM_Line_Item__r.Product_Feature__c, BOM_Line_Item__r.Product_Feature__r.Name,
                                           toLabel(MRP_Product__r.QuantityUnitOfMeasure), MRP_Product__r.Alternate_Quantity_Unit_Of_Measure__c
                                           From MRP__c Where MO__c = :vmoy Order By Work_Order__c ASC]; //BOM__r.Product_Feature__c, BOM__r.Sort__c,

                system.debug('MRPs~>'+MRPs.size());
                Map<Id,Integer> WOMRPCount = new Map<Id,Integer>();
                List<MRP__c> feature_MRPs = new List<MRP__c>();
                for(MRP__c MRP : MRPs) if(MRP.BOM_Line_Item__r.Product_Feature__c != Null || MRP.BOM_Line_Item__r.Product_Feature__c == Null) feature_MRPs.add(MRP);
                MRPs = feature_MRPs;
                feature_MRPs = new List<MRP__c>();
                //Added code by shguftha to get batch No only when product is not serialized
                List<Stock_Outward_Line_Item__c> SOLIs = new List<Stock_Outward_Line_Item__c>();
                if(!comW.manuOrders.Product__r.Serialise__c){   SOLIs = [Select Id, Name, Active__c, Batch_Lot_Code__c, BOM_Line_Item__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c, BOM__c, Serial__c, Serial__r.Name,Serial__r.Date_of_Manufacture__c,  MO_WO_Serial__c, MO_WO_Serial__r.Name, MO_WO_Material_Batch_Lot__c, MO_WO_Material_Batch_Lot__r.Name,     Product__c, Purchase_Orders__c, Quantity__c, Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name   From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c In: MRPs AND MRP_Material_Requirements_Planning__c != null]; }
                Set<Id> proIds = new Set<Id>();
                Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
                for(MRP__c mrp : MRPS){
                    if(mrp.MRP_Product__c != Null) proIds.add(mrp.MRP_Product__c);
                    if(mrp.Work_Order__c != null) {
                        WOMRPCount.put(mrp.Work_Order__c,0);
                        if(WOMRPCount.containsKey(mrp.Work_Order__c)) {
                            WOMRPCount.put(mrp.Work_Order__c,WOMRPCount.get(mrp.Work_Order__c) + 1);
                        }
                    }
                }
                String selectedSite = comW.manuOrders.Routing__r.Raw_Materials_Site__c;
                String finishedProduct = comW.manuOrders.Product__c;

                if(selectedSite != Null && selectedSite != ''){
                    for(AggregateResult result: [Select Product__c,SUM(Number_of_Item_In_Stock__c) totalStock  FROM Inventory_Stock__c   WHERE Active__c = true   And Warehouse__c = :selectedSite And Number_of_Item_In_Stock__c > 0 and Product__c IN:proIds GROUP BY Product__c]){
                        Decimal myStock = 0;
                        Id ProdId = (Id)result.get('Product__c');
                        if(stockMap.containsKey(ProdId)) myStock = stockMap.get(ProdId);
                        myStock +=(Decimal)result.get('totalStock');
                        stockMap.put(ProdId,myStock);
                    }
                }

                comW.UOMCs = [Select MasterLabel, QualifiedApiName, DeveloperName,From_UOM__c, From_Value__c,To_UOM__c, To_Value__c FROM UOM_Conversion__mdt limit 1000];
                List<mrpWrap> mrpWrapList = new List<mrpWrap>();

                system.debug('1 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                for(Integer i=0; i<MRPs.size(); i++){
                    MRP__c MRP = MRPs[i];
                    mrpWrap mrpWraper = new mrpWrap();

                    mrpWraper.MRP = MRP;

                    if((i == 0 && MRP.BOM_Line_Item__r.Product_Feature__c != Null) || (i > 0 && MRP.BOM_Line_Item__r.Product_Feature__c != MRPs[i-1].BOM_Line_Item__r.Product_Feature__c)){
                        if(MRP.BOM_Line_Item__r.Product_Feature__c != Null){
                            mrpWraper.Feature.Id = MRP.BOM_Line_Item__r.Product_Feature__c;
                            mrpWraper.Feature.Name = MRP.BOM_Line_Item__r.Product_Feature__r.Name;  } else mrpWraper.Feature.Name = '';
                    }

                    if(stockMap.containsKey(MRP.MRP_Product__c)) mrpWraper.Stock = stockMap.get(MRP.MRP_Product__c).setscale(4);

                    if(mrpWraper.Stock == 0) mrpWraper.bgColor = 'red-s';
                    else if(mrpWraper.Stock > 0 && mrpWraper.Stock < mrpWraper.MRP.Total_Amount_Required__c) mrpWraper.bgColor = 'orange';
                    else if(mrpWraper.Stock > 0 && mrpWraper.Stock >= mrpWraper.MRP.Total_Amount_Required__c) {
                        mrpWraper.bgColor = 'green';
                        if(mrpWraper.MRP.Fulfilled_Amount__c < mrpWraper.MRP.Total_Amount_Required__c && mrpWraper.MRP.Status__c == 'Requested') {  comW.ReserveStock = true;}
                        system.debug('mrpWraper.MRP.Status__c : '+mrpWraper.MRP.Status__c);
                    }

                    if(MRP.MRP_Product__c != null && MRP.Id != null){
                        String Key = ''+MRP.MRP_Product__c+MRP.Id+'';
                        if(prodMRPsMoMap.containsKey(Key)){  mrpWraper.MO = prodMRPsMoMap.get(Key);                        }
                    }
                    set<Id> batchIds = new set<Id>();
                    System.debug('SOLIs : '+SOLIs.size());
                    if(SOLIs.size() > 0){     for(Stock_Outward_Line_Item__c soli : SOLIs){     if(MRP.Id == soli.MRP_Material_Requirements_Planning__c){      if(soli.Material_Batch_Lot__c != Null && !batchIds.contains(soli.Material_Batch_Lot__c)) {  mrpWraper.Batches.add(new Batch__c(Id=soli.Material_Batch_Lot__c,Name=soli.Material_Batch_Lot__r.Name)); batchIds.add(soli.Material_Batch_Lot__c); }        }     }      }
                    if(MRP.BOM_Line_Item__r.Unit_of_Measure__c != Null) {
                        mrpWraper.SelectedUOM = MRP.BOM_Line_Item__r.Unit_of_Measure__c;
                        mrpWraper.UOMS.add(new SelectOptions(mrpWraper.SelectedUOM, mrpWraper.SelectedUOM, true));
                        if(MRP.MRP_Product__r.QuantityUnitOfMeasure != mrpWraper.SelectedUOM) mrpWraper.UOMS.add(new SelectOptions(MRP.MRP_Product__r.QuantityUnitOfMeasure, MRP.MRP_Product__r.QuantityUnitOfMeasure));
                    }

                    if(MRP.MRP_Product__r.Alternate_Quantity_Unit_Of_Measure__c != null){
                        String UOMS = MRP.MRP_Product__r.Alternate_Quantity_Unit_Of_Measure__c;
                        List<String> arr = UOMS.split(';');
                        for(String str : arr){
                            if(str != mrpWraper.SelectedUOM && str != MRP.MRP_Product__r.QuantityUnitOfMeasure) mrpWraper.UOMS.add(new SelectOptions(str, str));
                        }
                    }
                    mrpWrapList.add(mrpWraper);
                }

                system.debug('2 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                comW.MRPs = mrpWrapList;

                mrpWrapList = new List<mrpWrap>();
                stockMap = new Map<ID,Decimal>();
                system.debug('3 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                if(comW.manuOrders.Routing__r.Auto_Stock_Allocation__c == false) comW.ReserveStock = false;
                comW.WOs = Database.query('SELECT Id,Name,End_Date__c,Product__c,Product__r.Name,Product__r.UoM__c,Product__r.QuantityUnitOfMeasure,Quantity_Built__c,Quantity_Ordered__c,Code__c,Work_Center__c,Work_Center__r.Id,Work_Center__r.Name,Start_Date__c,ExpectedDate__c,Lead_Time__c,toLabel(Status__c) FROM WO__c WHERE MO__c = :vmoy');
                system.debug('4 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                String wpallFields = UtilClass.selectStarFromSObject('WIP_Flow__c');
                wpallFields += ' , Product__r.Name, Product__r.Serialise__c, Product__r.Lot_Tracked__c,Work_Orders__r.Name, Work_Orders__r.Quantity_Ordered__c ,Work_Orders__r.Quantity_Scrapped__c,Product__r.UoM__c,Product__r.QuantityUnitOfMeasure,BOM__r.Name,WIP__r.Name,WIP__r.Material_Batch_Lot__c,WIP__r.Material_Batch_Lot__r.Name,WIP__r.Serial_Number__c,WIP__r.Serial_Number__r.Name';
                string wpquery = 'select ' + String.escapeSingleQuotes(wpallFields) + ' from WIP_Flow__c where WIP__r.MO__c   = :vmoy limit 100';
                List<WIP_Flow__c> wipflows =  Database.query(wpquery);
                comW.wipflowsLength = (Integer)[SELECT COUNT(Id) total FROM WIP_Flow__c WHERE WIP__r.MO__c = :vmoy][0].get('total');


                wpallFields = '';
                wpquery  = '';

                comW.wipflows = wipflows;

                wipflows = new List<WIP_Flow__c>();

                system.debug('5 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                List<Serial_Number__c> MOserialNos = Database.query('select Id ,Name, Serial_Number__c,Date_of_Manufacture__c,Availability_date__c,Shelf_Life_Expiration_Date__c,Cost_Price__c,Product__r.Name, Product__r.Picture__c, Warehouse__r.Name, Asset__r.Product__c, Asset__r.Product__r.Name,Product__r.Barcode__c, Asset__r.Available__c, Asset__r.Is_Reserved__c, Asset__r.Name, Asset__r.Picture__c, Asset__r.Status__c ,Barcode__c ,Scrap__c,Available__c from Serial_Number__c where Manufacturing_Order__c = :vmoy limit 100');
                comW.moSerialNos = MOserialNos;
                comW.serialsLength= (Integer)[SELECT COUNT(Id) total FROM Serial_Number__c WHERE Manufacturing_Order__c  = :vmoy][0].get('total');

                MOserialNos = new List<Serial_Number__c>();

                system.debug('6 Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

                List< Purchase_Requisition_Line_Items__c > PRQLIS = [Select Id, Name, Purchase_Requisition__c from Purchase_Requisition_Line_Items__c Where MRP__c In :MRPs Or MRP__r.Work_Order__r.MO__c =: vmoy];
                Set<Id> PRIds = new Set<Id>();
                for(Purchase_Requisition_Line_Items__c PRq : PRQLIS){ if(PRq.Purchase_Requisition__c != Null) PRIds.add(PRq.Purchase_Requisition__c); }

                comW.PRS = [Select Id, Name, Purchase_Orders__c, Manufacturing_Order__c, Work_Order__c, Work_Order__r.MO__c From Requisition__c Where Manufacturing_Order__c =: vmoy Or Work_Order__r.MO__c =: vmoy OR Id In :PRIds ];
                List< Purchase_Line_Items__c > PRLIS = [Select Id, Name, Purchase_Orders__c from Purchase_Line_Items__c Where MRP_Material_Requirements_Planning__c In :MRPs Or MRP_Material_Requirements_Planning__r.Work_Order__r.MO__c =: vmoy];
                Set<Id> POIds = new Set<Id>();

                for(Purchase_Line_Items__c PR : PRLIS){ if(PR.Purchase_Orders__c != Null) POIds.add(PR.Purchase_Orders__c); }

                comW.POS = [Select Id, Name, Total_Quantity__c, Reconciled_Quantity__c, Inbound_Total_Quantity__c, Inbound_Received_Quantity__c From PO__c Where Id In : POIds];
                comW.moBatchNos = Database.query('select Id,Name, Product__r.Name, Product__r.Picture__c, Product__r.Barcode__c ,Barcode__c,Date_of_Manufacture__c from Batch__c where Manufacturing_Order__c = :vmoy');

                Set<Id> woIds = new Set<Id>();
                for(WO__c WO : comW.WOs){ woIds.add(WO.Id); WOWrap WOW = new WOWrap(); WOW.WorkOrder = WO;
                                         if(ShowAllWO == false)  {
                                             if(WOMRPCount.containsKey(WO.Id)) comW.WOWS.add(WOW);          }       else  comW.WOWS.add(WOW);  }

                Map<Id, List<Actions_Tasks__c>> WOTasks = new Map<Id, List<Actions_Tasks__c>>();
                Map<Id, List<Time_Card_Entry__c>> WOTCEs = new Map<Id, List<Time_Card_Entry__c>>();
                Map<Id, List<Resource_Allocation__c>> WORAs = new Map<Id, List<Resource_Allocation__c>>();

                List<Actions_Tasks__c> Tasks = Database.query('SELECT '+String.escapeSingleQuotes(AllTaskFields)+' FROM Actions_Tasks__c WHERE Work_Order__c = :woIds Order By Operation__r.Sort__c ASC limit 1000');
                List<Time_Card_Entry__c> TimeCardEntries = Database.query('SELECT '+String.escapeSingleQuotes(AllTSEFields)+' FROM Time_Card_Entry__c WHERE Timesheet__r.Work_Order__c = :woIds Order BY CreatedDate Desc limit 1000');
                String wcFields = 'Id,Name,Type__c,Start_Date__c,End_Date__c,Hours__c, Resource_Group__r.Name, Employees__r.Name, Machine__r.Name ';
                utilClass.FLSCheck(wcFields.split(','),'Resource_Allocation__c');
                String query = 'select ' + String.escapeSingleQuotes(wcFields) + ' from Resource_Allocation__c Where Work_Order__c = :woIds Order by CreatedDate Asc limit 1000';
                List< Resource_Allocation__c > RAS = Database.query(query);

                for(Actions_Tasks__c Task : Tasks){   if(WOTasks.containsKey(Task.Work_Order__c)) WOTasks.get(Task.Work_Order__c).add(Task);  else WOTasks.put(Task.Work_Order__c, new List<Actions_Tasks__c>{Task});     }
                for(Time_Card_Entry__c TCE : TimeCardEntries ){   if(WOTCEs.containsKey(TCE.Timesheet__r.Work_Order__c)) WOTCEs.get(TCE.Timesheet__r.Work_Order__c).add(TCE);    else WOTCEs.put(TCE.Timesheet__r.Work_Order__c, new List<Time_Card_Entry__c>{TCE});  }
                for(Resource_Allocation__c RA : RAS){     if(WORAs.containsKey(RA.Work_Order__c)) WORAs.get(RA.Work_Order__c).add(RA);      else WORAs.put(RA.Work_Order__c, new List<Resource_Allocation__c>{RA});  }
                for(WOWrap WOW : comW.WOWS){
                    WOW.Tasks = WOTasks.get(WOW.WorkOrder.Id);
                    WOW.TimeCardEntries = WOTCEs.get(WOW.WorkOrder.Id);
                    WOW.RAS = WORAs.get(WOW.WorkOrder.Id);
                }

                List<Attachment> Attachments = [Select Id, Name, ParentId, Owner.Name, CreatedDate From Attachment Where ParentId =: vmoy And Name = 'Signature' Order By CreatedDate Asc];
                if(Attachments.size() > 0) comW.Attachment = Attachments[0];

                comW.SelectedAttachments = [Select Id, Name, ParentId, Owner.Name, CreatedDate From Attachment Where ParentId =: vmoy And Name = 'Signature' Order By CreatedDate Asc];
                comW.Product = new Product2(Id=comW.manuOrders.Product__c, Name=comW.manuOrders.Product__r.Name);
                comW.Routing = new Routing__c(Id=comW.manuOrders.Routing__c, Name=comW.manuOrders.Routing__r.Name,Max_Allowed_Cuts__c = comW.manuOrders.Routing__r.Max_Allowed_Cuts__c);
                comW.Version = new BOM__c(Id=comW.manuOrders.BOM__c, Name=comW.manuOrders.BOM__r.Name);
                if (Schema.SObjectType.PO__c.getRecordTypeInfosByDeveloperName().containsKey('Standard_Purchase_Order')) {
    			comW.standardPOId = Schema.SObjectType.PO__c
        			.getRecordTypeInfosByDeveloperName()
        			.get('Standard_Purchase_Order')
        			.getRecordTypeId();
				}

                Functionality_Control__c FC = new Functionality_Control__c();
                FC = Functionality_Control__c.getValues(userInfo.getuserid());

                if(FC == null){
                    FC = Functionality_Control__c.getValues(userInfo.getProfileId());
                    if(FC==null) FC = Functionality_Control__c.getInstance();
                }
                if(FC != null){
                    if(!FC.Manufacturing_Is_Console_Editable__c) comW.isEditable = false;    else if(comW.manuOrders.Status__c == 'Complete') comW.isEditable = false;
                    comW.showCosts = FC.Manufacturing_Console_Show_Costs__c;
                    comW.linksNewOptions = FC.Manufacturing_Links_New_Options__c;
                    comW.showAutoStockAllocation = FC.MO_AutoStockAllocation__c;
                    comW.showManualStockAllocation = FC.MO_ManualStockAllocation__c;
                    comW.allowMultiPos = FC.Allow_Multi_POs_from_Manufacturing_order__c;
                    comW.isStandardOrder = FC.Is_Standard_Order__c;
                    comW.ShowCustomSerailNumberGeneration = true;//FC.Show_Custom_generation_of_serial_numbers__c;
                    comW.ShowLangOptionForTraveller= FC.ShowLangOptionForTraveller__c;
                    comW.ReplaceTravellerOrgURL= FC.Replace_Traveller_OrgURL__c;
                    comW.ShowProdStatus = FC.Show_Production_Status_Traveller__c;
                    comW.showVendorCode = FC.Show_Vendor_Product_Code__c;
                    comW.showScrapDetails = FC.Hide_Scrap_and_Waste_in_MO_and_WO__c;
                    comW.showMOLabels = FC.show_Manufacturing_label__c;
                    comW.AllowMRPDelete = FC.AllowMRPDeleteinMO__c;
                    comW.enableQA = FC.Enable_QA_in_Manufacturing_process__c;
                    comW.PreventStatusEdit = FC.Prevent_Status_edit_after_Receiving__c;
                    comW.showUplaodforItems = FC.Show_upload_for_each_item_in_Receive__c;
                    if(FC.hide_purchase_requisition_in_MO__c) comW.showRequisition = false; else comW.showRequisition = true;
                }

            }

        } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); }
        return comW;
    }
    @AuraEnabled
    public static List<SelectOptions> getInwardStatus(){
        List<SelectOptions> options = new List<SelectOptions>();
        Schema.DescribeFieldResult fieldResult = Stock_Inward_Line_Item__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(new SelectOptions(f.getValue(), f.getLabel()));

        }
        if(options.size() > 0) return options;   else return null;
    }
    @AuraEnabled
    public static comWrap SaveM(String MO){
        Manufacturing_Order__c MOs = (Manufacturing_Order__c) JSON.deserialize(MO, Manufacturing_Order__c .class);
        comWrap comW = new comWrap();
        try{
            if(MOs.End_Date__c == Null && Schema.sObjectType.Manufacturing_Order__c.fields.End_Date__c.isCreateable() && Schema.sObjectType.Manufacturing_Order__c.fields.End_Date__c.isUpdateable()){ MOs.End_Date__c = MOs.ExpectedDate__c;}else{/*No access*/}
            if(Schema.sObjectType.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Manufacturing_Order__c.isUpdateable()){upsert MOs;}else{comW.errorMsg ='Not allowed to upsert Manufacturing Order';}
            comW.manuOrders = MOs;    } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }

    @AuraEnabled
    public static comWrap SaveAllMRPs(String MRPs){
        List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
        comWrap comW = new comWrap();
        try{
            comW.errorMsg = '';
            List<MRP__c> MRPs2Upsert = new List<MRP__c>();
            for(mrpWrap mrpWrapper : mrpWrappers){
                MRPs2Upsert.add(mrpWrapper.MRP);
            }
            if(MRPs2Upsert.size() > 0 && Schema.SObjectType.MRP__c.isCreateable() && Schema.SObjectType.MRP__c.isUpdateable()){ upsert MRPs2Upsert;}else{/*No access*/}   } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }

    @AuraEnabled
    public static void deleteSerial(String RecId){
        Serial_Number__c ser = [Select Id,Name from Serial_Number__c where Id=:RecId limit 1];
        if(Serial_Number__c.sObjectType.getDescribe().isDeletable()) {delete ser;} else{}
    }

    @AuraEnabled
    public static comWrap SaveSerial(String SerialNumber, String MO){
        Manufacturing_Order__c MOs = (Manufacturing_Order__c) JSON.deserialize(MO, Manufacturing_Order__c .class);
        Serial_Number__c SlNumber = (Serial_Number__c) JSON.deserialize(SerialNumber, Serial_Number__c .class);
        comWrap comW = new comWrap();
        try{
            if(Schema.sObjectType.Serial_Number__c.fields.Warehouse__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.Warehouse__c.isUpdateable()) SlNumber.Warehouse__c = MOs.Routing__r.Finished_Products_Site__c;
            if(Schema.sObjectType.Serial_Number__c.fields.Product__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.Product__c.isUpdateable())   SlNumber.Product__c = MOs.Product__c;
            if(Schema.sObjectType.Serial_Number__c.fields.BOM__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.BOM__c.isUpdateable())   SlNumber.BOM__c = MOs.BOM__c;
            if(Schema.sObjectType.Serial_Number__c.fields.Manufacturing_Order__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.Manufacturing_Order__c.isUpdateable()) SlNumber.Manufacturing_Order__c = MOs.Id;
            // upsert SlNumber;
            System.SObjectAccessDecision securityDecision2 = Security.stripInaccessible(
                AccessType.UPDATABLE,
                  new List<Serial_Number__c>{SlNumber}
            );
            
            List<Serial_Number__c> accessibleRecords2 = (List<Serial_Number__c>) securityDecision2.getRecords();
            
            if (!accessibleRecords2.isEmpty()) {
                upsert accessibleRecords2;
            }
            comW.manuOrders = MOs;
            comW.errorMsg = '';     } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }

    @AuraEnabled
    public static comWrap SaveBatch(String Batch, String MO){
        Manufacturing_Order__c MOs = (Manufacturing_Order__c) JSON.deserialize(MO, Manufacturing_Order__c .class);
        Batch__c SlNumber = (Batch__c) JSON.deserialize(Batch, Batch__c .class);
        comWrap comW = new comWrap();
        try{
            if(Schema.sObjectType.Batch__c.fields.Product__c.isCreateable() && Schema.sObjectType.Batch__c.fields.Product__c.isUpdateable()){SlNumber.Product__c = MOs.Product__c;}else{/*No access*/}
            if(Schema.sObjectType.Batch__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Batch__c.fields.BOM__c.isUpdateable()){SlNumber.BOM__c = MOs.BOM__c;}else{/*No access*/}
            if(Schema.sObjectType.Batch__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Batch__c.fields.Manufacturing_Order__c.isUpdateable()){SlNumber.Manufacturing_Order__c = MOs.Id;}else{/*No access*/}
            if(Schema.sObjectType.Batch__c.isCreateable() && Schema.sObjectType.Batch__c.isUpdateable()){upsert SlNumber;}else{comW.errorMsg='Not allowed to upsert batch';}
            comW.manuOrders = MOs;
            comW.errorMsg = '';
        } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }

    @AuraEnabled
    public static comWrap MRPEdit(String MRP, String MRPs){
        comWrap comWrapper = new comWrap();
        try{
            List<Id> bomIds = new List<Id>();
            mrpWrap mrpWrapper = (mrpWrap) JSON.deserialize(MRP, mrpWrap .class);
            List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
            for(mrpWrap mrrp : mrpWrappers){
                if(mrrp.MRP.BOM_Line_Item__c != Null) bomIds.add(mrrp.MRP.BOM_Line_Item__c);
            }

            comWrapper.AlternativeBOMs = [Select Id, Name, Bill_Of_Material__c, BOM_Variance__c, Product__c, Product_Feature__c, Type__c, BOM_Variance__r.BOM_Component__r.Name,
                                          BOM_Variance__r.BOM_Component__c, BOM_Variance__r.RecordType.Name, BOM_Variance__r.RecordTypeId, BOM_Variance__r.BOM__c,
                                          BOM_Variance__r.Unit_of_Measure__c
                                          From Variance__c
                                          Where Type__c = 'Alternative' And
                                          BOM_Variance__r.BOM__c =: mrpWrapper.MRP.BOM_Line_Item__r.BOM__c And
                                          Bill_Of_Material__c Not In: bomIds And
                                          Bill_Of_Material__c = :mrpWrapper.MRP.BOM_Line_Item__c
                                         ];

            String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
            String AllWarehouseFields = WarehouseFields + '';
            Set<Id> proIds = new Set<Id>();
            Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
            for(Variance__c bom : comWrapper.AlternativeBOMs){ if(bom.BOM_Variance__r.BOM_Component__c != Null) proIds.add(bom.BOM_Variance__r.BOM_Component__c);
                                                                   }
            String selectedSite = mrpWrapper.MRP.MO__r.Routing__r.Raw_Materials_Site__c;
            if(selectedSite != Null && selectedSite != ''){
                List<Inventory_Stock__c> WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, '+
                                                                    +' StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c In: proIds And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Expiry_Date__c ASC');
                for(Id proId : proIds){    Decimal myStock = 0;      for(Inventory_Stock__c stock : WIISLists){      if(proId == stock.Product__c){  myStock += stock.Number_of_Item_In_Stock__c;  }    }                       stockMap.put(proId,myStock);   }
            }
            comWrapper.MRPs = new List<mrpWrap>();
            Id rTpe_MRPMAN; rTpe_MRPMAN = Schema.SObjectType.MRP__c.getRecordTypeInfosByDeveloperName().get('MRP_Manufacturing').getRecordTypeId();
            for(Variance__c bom : comWrapper.AlternativeBOMs){        mrpWrap mrpW = new mrpWrap();   MRP__c MRPn = new MRP__c(Name = BOM.BOM_Variance__r.BOM_Component__r.Name,Total_Amount_Required__c = mrpWrapper.MRP.Total_Amount_Required__c,BOM_Line_Item__c = BOM.BOM_Variance__c,MRP_Product__c = BOM.BOM_Variance__r.BOM_Component__c,BOM__c = BOM.BOM_Variance__r.BOM__c, MO__c = mrpWrapper.MRP.MO__c);   mrpW.Qnty = mrpWrapper.MRP.Total_Amount_Required__c;       if(bom.BOM_Variance__r.RecordType.Name == 'Manufacturing BOM' && rTpe_MRPMAN != null) MRPn.RecordTypeId = rTpe_MRPMAN;  mrpW.MRP = MRPn;     if(stockMap.containsKey(BOM.BOM_Variance__r.BOM_Component__c)) mrpW.Stock = stockMap.get(BOM.BOM_Variance__r.BOM_Component__c);   comWrapper.MRPs.add(mrpW);   }    } catch(Exception e) { comWrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comWrapper;
    }

   /* @AuraEnabled
    public static comWrap MRPUpdate(string mrpMain1, String alternateMrps){
        List<mrpWrap> mrpWrapper = (List<mrpWrap>) JSON.deserialize(alternateMrps, List<mrpWrap> .class);
        MRP__c mrpMain = (MRP__c) JSON.deserialize(mrpMain1, MRP__c .class);
        comWrap comWrapper = new comWrap();
        try{
            List<MRP__c> alternateMrps2upsert = new List<MRP__c>();
            List<MRP__c> alternateMrps2delete = new List<MRP__c>();

            for(mrpWrap mrp : mrpWrapper){
                if(mrp.isSelect && mrp.Qnty > 0) { mrp.MRP.Total_Amount_Required__c = mrp.Qnty; alternateMrps2upsert.add(mrp.MRP); }
            }
            if((mrpMain.BOM_Line_Item__r.Is_Protected__c == true && alternateMrps2upsert.size() > 0) || !(mrpMain.Total_Amount_Required__c > 0)) alternateMrps2delete.add(mrpMain);
            else alternateMrps2upsert.add(mrpMain);

            if(alternateMrps2upsert.size() > 0){ if(Schema.SObjectType.MRP__c.isCreateable() && Schema.SObjectType.MRP__c.isUpdateable()){upsert alternateMrps2upsert;}else{comWrapper.errorMsg='Not allowed to upsert MRPs';} }
            if(alternateMrps2delete.size() > 0 && MRP__c.sObjectType.getDescribe().isDeletable()) delete alternateMrps2delete;
        } catch(Exception e) { comWrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comWrapper;
    }*/
     @AuraEnabled
public static comWrap MRPUpdate(string mrpMain1, String alternateMrps) {
    List<mrpWrap> mrpWrapper = (List<mrpWrap>) JSON.deserialize(alternateMrps, List<mrpWrap>.class);
    MRP__c mrpMain = (MRP__c) JSON.deserialize(mrpMain1, MRP__c.class);
    comWrap comWrapper = new comWrap();
    
    try {
        List<MRP__c> alternateMrps2upsert = new List<MRP__c>();
        
        // Process alternate MRPs
        for(mrpWrap mrp : mrpWrapper) {
            if(mrp.isSelect && mrp.Qnty > 0) {   mrp.MRP.Total_Amount_Required__c = mrp.Qnty;  alternateMrps2upsert.add(mrp.MRP);
            }
            // Add validation for negative quantities if needed
            else if(mrp.Qnty < 0) { comWrapper.errorMsg = 'Quantity cannot be negative';  return comWrapper;
            }
        }
        
        // Handle main MRP
        if(mrpMain.Total_Amount_Required__c < 0) { comWrapper.errorMsg = 'Main MRP quantity cannot be negative'; return comWrapper; }
        
        // Add main MRP to upsert list if not protected or has positive quantity
        if(!(mrpMain.BOM_Line_Item__r.Is_Protected__c == true && alternateMrps2upsert.size() > 0)) {
            alternateMrps2upsert.add(mrpMain);
        }
        
        // Perform upsert if we have records and permissions
        if(alternateMrps2upsert.size() > 0) {
            if(Schema.SObjectType.MRP__c.isCreateable() && Schema.SObjectType.MRP__c.isUpdateable()) {
                upsert alternateMrps2upsert;  } else {   comWrapper.errorMsg = 'Not allowed to upsert MRPs';
            }
        }
        
    } catch(Exception e) {
        comWrapper.errorMsg = e.getMessage() + ' Line Number @ : ' + e.getLineNumber();
    }
    
    return comWrapper;
}

    @AuraEnabled
    public static comWrap getAllSOLI(string MOrdItm) {
        comWrap comW = new comWrap();
        if(MOrdItm!= null && MOrdItm != ''){
            OrderItem oItm = [Select Id, OrderItemNumber, OrderId, Active__c, Product2Id, Product2.Name,
                              Status__c, Quantity, BOM__c, BOM__r.Name, Routing__c, Routing__r.Name,
                              Product2.Routing__c, Product2.BOM__c,Product2.Routing__r.Name,Product2.BOM__r.Name,
                              Start_Time__c, End_Time__c from OrderItem where Id=:MOrdItm];
            comW.manuOrders.Order_Product__c = oItm.Id;
            //   comW.manuOrders.Order_Product__r.OrderItemNumber = oItm.OrderItemNumber;
            comW.manuOrders.Product__c = oItm.Product2Id;
            if(oItm.BOM__c != null)  {   comW.manuOrders.BOM__c = oItm.BOM__c;        comW.Version = new BOM__c(Id=oItm.BOM__c, Name=oItm.BOM__r.Name);  }
            else{
                comW.manuOrders.BOM__c = oItm.Product2.BOM__c;
                comW.Version = new BOM__c(Id=oItm.Product2.BOM__c, Name=oItm.Product2.BOM__r.Name);
            }
            if(oItm.Routing__c != null){    comW.manuOrders.Routing__c = oItm.Routing__c;  comW.Routing = new Routing__c(Id=oItm.Routing__c, Name=oItm.Routing__r.Name); }
            else{
                comW.manuOrders.Routing__c = oItm.Product2.Routing__c;
                comW.Routing = new Routing__c(Id=oItm.Product2.Routing__c, Name=oItm.Product2.Routing__r.Name);
            }
            comW.manuOrders.Order__c = oItm.OrderId;
            comW.manuOrders.Quantity__c = oItm.Quantity;
            comW.manuOrders.StartDate__c = oItm.Start_Time__c;
            comW.manuOrders.End_Date__c = oItm.End_Time__c;
            //Routing__r.Name, Product__r.Name, BOM__r.Name
            comW.Product = new Product2(Id=oItm.Product2Id, Name=oItm.Product2.Name);


        }
        return comW;
    }

    @AuraEnabled
    public static mrpWrap getAllMO(string mrpId) {
        Manufacturing_Order__c MOmrp = new Manufacturing_Order__c();
        mrpWrap mrpWraper = new mrpWrap();
        MRP__c MRP = [Select Id, Name, Total_Amount_Required__c, BOM_Line_Item__c, BOM_Line_Item__r.Unit_of_Measure__c, BOM_Line_Item__r.Name, BOM_Line_Item__r.BOM__c, MRP_Product__c, MRP_Product__r.Name, MRP_Product__r.Picture__c, MRP_Product__r.Preview_Image__c, RecordType.Name, MRP_Product__r.BOM__c, MRP_Product__r.Routing__c, MRP_Product__r.BOM__r.Name, MRP_Product__r.Routing__r.Name, BOM_Line_Item__r.Exact_Quantity__c,
                            Work_Order_Line_Items__c, MO__c, MO__r.BOM__c, Fulfilled_Amount__c, BOM_Line_Item__r.Is_Protected__c, MO__r.Routing__r.Raw_Materials_Site__c, Consumed_Quantity__c, Scrapped_Quantity__c, MRP_Product__r.Issue_Purchase_Order__c, MRP_Product__r.Issue_Manufacturing_Order__c, MO__r.Name, Expected_Quantity__c, Minimum_Variance__c, Maximum_Variance__c, MRP_Product__r.Serialise__c, MRP_Product__r.Lot_Tracked__c,
                            BOM_Line_Item__r.Quantity__c, BOM_Line_Item__r.Minimum_Variance__c, BOM_Line_Item__r.Maximum_Variance__c, BOM_Line_Item__r.Sort__c, BOM_Line_Item__r.Product_Feature__c, BOM_Line_Item__r.Product_Feature__r.Name
                            From MRP__c
                            Where Id = :mrpId Order By BOM_Line_Item__r.Sort__c ASC];

        MOmrp.Name = MRP.MRP_Product__r.Name;
        MOmrp.Quantity__c = MRP.Total_Amount_Required__c;
        MOmrp.Product__c = MRP.MRP_Product__c;
        MOmrp.Manufacturing_Order__c = MRP.MO__c;
        MOmrp.MRP_Material_Requirement_Planning__c = MRP.Id;
        MOmrp.Routing__c = MRP.MRP_Product__r.Routing__c;
        MOmrp.BOM__c = MRP.MRP_Product__r.BOM__c;
        mrpWraper.MRP = MRP;
        mrpWraper.MO = MOmrp;
        mrpWraper.Product = new Product2(Id=MRP.MRP_Product__c, Name=MRP.MRP_Product__r.Name);
        mrpWraper.Routing = new Routing__c(Id=MRP.MRP_Product__r.Routing__c, Name=MRP.MRP_Product__r.Routing__r.Name);
        mrpWraper.Version = new BOM__c(Id=MRP.MRP_Product__r.BOM__c, Name=MRP.MRP_Product__r.BOM__r.Name);
        return mrpWraper;
    }

    @AuraEnabled
    public static mrpWrap getAllMPS(string mpslineId) {
        Manufacturing_Order__c MOmrp = new Manufacturing_Order__c();
        mrpWrap mrpWraper = new mrpWrap();
        String mpsLineFields = UtilClass.selectStarFromSObject('MPS_line_Item__c');
        utilClass.FLSCheck(mpsLineFields.split(','),'MPS_line_Item__c');
        String query = 'select ' + String.escapeSingleQuotes(mpsLineFields) + ', MPS__r.Master_Production_Schedule__c, MPS__r.BOM__c, MPS__r.BOM__r.Name, MPS__r.Product__r.BOM__c, MPS__r.Product__r.Routing__c, MPS__r.Product__r.Routing__r.Name, MPS__r.Product__r.Name, MPS__r.Lot_Size__c, MPS__r.Product__c from MPS_line_Item__c where Id =: mpslineId ';
        List<MPS_line_Item__c> MPSSLines = Database.query(query);
        if(MPSSLines.size() > 0){    MOmrp.Name = MPSSLines[0].MPS__r.Product__r.Name;     MOmrp.Quantity__c = MPSSLines[0].MPS__r.Lot_Size__c;     MOmrp.Product__c = MPSSLines[0].MPS__r.Product__c;    MOmrp.Routing__c = MPSSLines[0].MPS__r.Product__r.Routing__c;     MOmrp.BOM__c = (MPSSLines[0].MPS__r.BOM__c != Null)? MPSSLines[0].MPS__r.BOM__c : MPSSLines[0].MPS__r.Product__r.BOM__c;  mrpWraper.Product = new Product2(Id=MPSSLines[0].MPS__r.Product__c, Name=MPSSLines[0].MPS__r.Product__r.Name);     mrpWraper.Routing = new Routing__c(Id=MPSSLines[0].MPS__r.Product__r.Routing__c, Name=MPSSLines[0].MPS__r.Product__r.Routing__r.Name);   if(MPSSLines[0].MPS__r.BOM__c != Null) mrpWraper.Version = new BOM__c(Id=MPSSLines[0].MPS__r.BOM__c, Name=MPSSLines[0].MPS__r.BOM__r.Name); }
        mrpWraper.MO = MOmrp;
        return mrpWraper;
    }

	@AuraEnabled
    public static comWrap ReserveMRPSStocks(String MRPs,Integer AutostkLimit){
        List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
        comWrap comW = new comWrap();
        system.debug('AutostkLimit : '+AutostkLimit);
        try{
            comW.errorMsg = '';
            Set<Id> bomStockAllocProdIds = new Set<Id>();
            List<mrpWrap> mrpWrapret = new List<mrpWrap>();
            String selectedSite = comW.manuOrders.Routing__r.Raw_Materials_Site__c;
            String finishedProduct = comW.manuOrders.Product__c;
            List<Id> proIds = new List<Id>();
            //Map<Id, Decimal> stockMap = new Map<Id, Decimal>();
            set<Id> MRPIds = new set<Id>();
            Map<Id,List<Inventory_Stock__c>> productSites = new Map<Id,List<Inventory_Stock__c>>();
            Map<Id,Decimal> Mapexistingstock = new Map<Id,Decimal>();
            Map<Id,Set<Id>> MapexistingstockSerials = new Map<Id,Set<Id>>();
            String MOId = '';
            Map<Id,decimal> bomDupProductStockAllocated = new Map<Id,decimal>();
            Map<Id,decimal> inventoryStockAllocated = new Map<Id,decimal>();




            for(mrpWrap mrpWrapper : mrpWrappers){
                if(MOId == '') MOId = mrpWrapper.mrp.MO__c;
                if(mrpWrapper.mrp.MO__r.Routing__r.Raw_Materials_Site__c != Null) selectedSite = mrpWrapper.mrp.MO__r.Routing__r.Raw_Materials_Site__c;
                if(mrpWrapper.mrp.MRP_Product__c != Null) proIds.add(mrpWrapper.mrp.MRP_Product__c);
                MRPIds.add(mrpWrapper.mrp.Id);
                
                if(mrpWrapper.mrp.MRP_Product__c != Null) bomDupProductStockAllocated.put(mrpWrapper.mrp.MRP_Product__c, 0);

            }
            List<Stock_Outward_Line_Item__c> fulfilledStock = [Select Id,Name,Quantity__c,MRP_Material_Requirements_Planning__c,MO_WO_Serial__c from Stock_Outward_Line_Item__c where MRP_Material_Requirements_Planning__c In:MRPIds and Active__c =true];
           	Set<Id> bomserials=new Set<Id>();//new line 
            
            List<Serial_Number__c> SNS = new List<Serial_Number__c> ();
            Map<Id,Serial_Number__c> SNSMap = new Map<Id,Serial_Number__c> ();
            Manufacturing_Order__c MO = new Manufacturing_Order__c();
            
            Set<Id> SerialNos = new Set<Id>();
            for(mrpWrap mrpWrapper : mrpWrappers){
                Decimal allocatedqty = 0;
                
                for(Stock_Outward_Line_Item__c stk : fulfilledStock){
                    if(stk.MRP_Material_Requirements_Planning__c == mrpWrapper.MRP.Id) { 
                        allocatedqty += stk.Quantity__c;
                        if(stk.MO_WO_Serial__c != Null) SerialNos.add(stk.MO_WO_Serial__c);
                        // system.debug('allocatedqty : '+allocatedqty);
                    }
                }
                MapexistingstockSerials.put(mrpWrapper.MRP.Id, SerialNos);  
                if(allocatedqty > 0) Mapexistingstock.put(mrpWrapper.MRP.Id,allocatedqty);
            }
            fulfilledStock = new List<Stock_Outward_Line_Item__c>();
            
            if(MOId != '') {
                MO = [Select Id, Name, Product__r.Serialise__c From Manufacturing_Order__c Where Id =: MOId];
                if(MO.Product__r.Serialise__c == true) {
                    SNSMap = new Map<Id,Serial_Number__c> ([Select Id, Name, Material_Batch_Lot__c, Manufacturing_Order__c, Product__c  From Serial_Number__c Where Manufacturing_Order__c =: MO.Id and Id Not IN :SerialNos limit :AutostkLimit]);
                    SNS = SNSMap.Values();
                }
            }
            //system.debug('*** SNS : '+SNS.size());
            if(selectedSite != Null && selectedSite != ''){
                String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
                String AllWarehouseFields = WarehouseFields + '';
                List<Inventory_Stock__c> WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, '+
                                                                          +' StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c In: proIds And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Checked_In_Date__c ASC, Expiration_Date__c ASC NULLS LAST Limit 1000');//added Expiration_Date__c ASC filter on 22_07_24 //changed to check in date on 30_05_24// Number_of_Item_In_Stock__c DESC removed on 29_02_24// changed DESC limit 1000 19_08_23 and order by Number_of_Item_In_Stock__c from Expiry date
                
                System.debug('WIISLists->'+WIISLists);
                List<Inventory_Stock__c> withExpirationDate = new List<Inventory_Stock__c>();
                List<Inventory_Stock__c> withoutExpirationDate = new List<Inventory_Stock__c>();
                
                for (Inventory_Stock__c record : WIISLists) {
                    inventoryStockAllocated.put(record.Id, 0);
                    if (record.Expiration_Date__c != null) {     withExpirationDate.add(record);
                    } else {
                        withoutExpirationDate.add(record);
                    }
                }
                
                // Manual sort of the list with Expiration_Date__c
                for (Integer i = 0; i < withExpirationDate.size() - 1; i++) { for (Integer j = i + 1; j < withExpirationDate.size(); j++) { if (withExpirationDate[i].Expiration_Date__c > withExpirationDate[j].Expiration_Date__c) { Inventory_Stock__c temp = withExpirationDate[i]; withExpirationDate[i] = withExpirationDate[j]; withExpirationDate[j] = temp; } } }
                
                // Merge the sorted lists while maintaining the original order for records without expiration dates
                List<Inventory_Stock__c> sortedInventoryStocks = new List<Inventory_Stock__c>();
                Integer expIndex = 0;
                Integer noExpIndex = 0;
                
                for (Inventory_Stock__c record : WIISLists) {
                     if (record.Expiration_Date__c != null) { sortedInventoryStocks.add(withExpirationDate[expIndex]); expIndex++; }  else {
                        sortedInventoryStocks.add(withoutExpirationDate[noExpIndex]);
                        noExpIndex++;
                    }
                }
               //System.debug('sortedInventoryStocks->'+sortedInventoryStocks);
                // Output the sorted results
               /*  for (Inventory_Stock__c inv : sortedInventoryStocks) {
                    System.debug('inv: ' + inv);
                }*/
                
                for(Id proId : proIds){
                    Decimal myStock = 0;
                    if(!productSites.containsKey(proId)) productSites.put(proId, new List<Inventory_Stock__c>());
                    for(Inventory_Stock__c stock : sortedInventoryStocks){
                        if(proId == stock.Product__c){
                            
                            // myStock += stock.Number_of_Item_In_Stock__c;
                            List<Inventory_Stock__c> myStocks = productSites.get(proId);
                            myStocks.add(stock);
                            productSites.put(proId,myStocks);
                        }
                    }
                    
                    // stockMap.put(proId,myStock);
                    
                }
                WIISLists = new List<Inventory_Stock__c>();
                
            }
            // system.debug('stockMap ; '+stockMap);
            List<Stock_Outward_Line_Item__c> SDLIs2Upsert = new List<Stock_Outward_Line_Item__c>();
            List<MRP__c> MRPs2Upsert = new List<MRP__c>();
            
            System.debug('Limits.getCpuTime 1- '+ Limits.getCpuTime());
            System.debug('Limits.getLimitCpuTime 1- '+ Limits.getLimitCpuTime());
            System.debug('Limits.getHeapSize 1- '+ Limits.getHeapSize());
            System.debug('Limits.getLimitHeapSize 1- '+ Limits.getLimitHeapSize());
            Map<Id,decimal> SerialsStockAllocated = new Map<Id,decimal>();
            
            
            for(mrpWrap mrpWrapper : mrpWrappers){
                Decimal SA = bomDupProductStockAllocated.get(mrpWrapper.mrp.MRP_Product__c);
                mrpWrapper.Stock = mrpWrapper.Stock - SA;
                
                System.debug('in for main logic');
                /*
                if(bomStockAllocProdIds.contains(mrpWrapper.MRP.MRP_Product__c)){
					continue;                    
                }  
                */
                //System.debug('Processing Product ID: ' + mrpWrapper.MRP.MRP_Product__c);
                
               //System.debug('Updated bomStockAllocProdIds Set: ' + bomStockAllocProdIds);
                
                Decimal WM = mrpWrapper.WeightMultiplier;
                system.debug('Product : '+mrpWrapper.MRP.MRP_Product__c+'   mrpWrapper.Stock : '+mrpWrapper.Stock+ ' 2.mrpWrapper.MRP.Status__c : '+mrpWrapper.MRP.Status__c+ ' 3.mrpWrapper.MRP.Total_Amount_Required__c : '+mrpWrapper.MRP.Total_Amount_Required__c);
                decimal stockAllocated = 0;
                
                if(mrpWrapper.Stock > 0 && mrpWrapper.MRP.Status__c == 'Requested'){ 
                    Decimal requiredQty = mrpWrapper.MRP.Total_Amount_Required__c - mrpWrapper.MRP.Fulfilled_Amount__c;
                    //system.debug('')
                    if (mrpWrapper.Stock <= 0) { //mrpWrapper.Stock < requiredQty
                        //comW.errorMsg = 'Insufficient stock for auto allocation. Available: ' + mrpWrapper.Stock + ', Required: ' + requiredQty;
                        //return comW;
                        continue;
                    }
                    //&& ((mrpWrapper.Stock >= mrpWrapper.mrp.Total_Amount_Required__c) || ((mrpWrapper.Stock + mrpWrapper.mrp.Fulfilled_Amount__c) >= mrpWrapper.mrp.Total_Amount_Required__c))                   
                    // system.debug('if');
                    List<Inventory_Stock__c> WIISs = productSites.get(mrpWrapper.MRP.MRP_Product__c);
                    system.debug('stockAllocated 1: '+stockAllocated);
                    if(WIISs != Null && WIISs.size() > 0){
                        //bomStockAllocProdIds.add(mrpWrapper.MRP.MRP_Product__c);
                        system.debug('WIISs : Not null ');
                        Inventory_Stock__c WIIS = (mrpWrapper.MRP.Check_Out_Process__c == 'LIFO')? WIISs[WIISs.size()-1] : WIISs[0];
                        system.debug('WIIS : '+WIIS.Number_of_Item_In_Stock__c);
                        
                        
                        // Single WIIS straight forward reduction and reserving
                        if((WIIS.Number_of_Item_In_Stock__c + (mrpWrapper.mrp.Fulfilled_Amount__c/WM) - SA) >= (mrpWrapper.MRP.Total_Amount_Required__c/WM)){
                            system.debug('In if 1');
                            if(SNS.size() > 0){
                                for(Serial_Number__c SN : SNS){
                                    if(!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id)){
                                        system.debug('*** SNS In One: '+SN.Name);
                                        Stock_Outward_Line_Item__c SDLI = new Stock_Outward_Line_Item__c(Name = String.isNotBlank(mrpWrapper.MRP.MRP_Product__r.Name)? mrpWrapper.MRP.MRP_Product__r.Name:'', Active__c = true, Process__c = mrpWrapper.MRP.Process__c, Schedule__c = mrpWrapper.MRP.Schedule__c, MRP_Material_Requirements_Planning__c = mrpWrapper.MRP.Id, BOM_Line_Item__c = mrpWrapper.MRP.BOM_Line_Item__c, Status__c = 'Reserved', Product__c = mrpWrapper.MRP.MRP_Product__c, Site_Product_Service_Inventory_Stock__c = WIIS.Id, BOM__c = WIIS.BOM__c);
                                        //if(Mapexistingstock.containsKey(mrpWrapper.MRP.Id)) SDLI.Quantity__c = mrpWrapper.MRP.Total_Amount_Required__c - Mapexistingstock.get(mrpWrapper.MRP.Id) ;
                                        //else SDLI.Quantity__c = mrpWrapper.MRP.Total_Amount_Required__c;
                                        stockAllocated += (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM);
                                        SDLI.Quantity__c = (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM).setScale(4);
                                       
                                        SA = SA + SDLI.Quantity__c;
                            			bomDupProductStockAllocated.put(mrpWrapper.mrp.MRP_Product__c, SA);

                                        Decimal WIIS_Allocated = inventoryStockAllocated.get(WIIS.Id);
                                        inventoryStockAllocated.put(WIIS.Id, (WIIS_Allocated+SDLI.Quantity__c)); 

                                        
                                        SDLI.MO_WO_Serial__c = SN.Id; if(SN.Material_Batch_Lot__c != Null) SDLI.MO_WO_Material_Batch_Lot__c = SN.Material_Batch_Lot__c; if(WIIS.Batch_Lot__c != null) SDLI.Material_Batch_Lot__c = WIIS.Batch_Lot__c; if(WIIS.Serial__c != null) { SDLI.Serial__c = WIIS.Serial__c;bomserials.add(WIIS.Serial__c); } if(mrpWrapper.MRP.BOM_Requirement_Cost__c != Null){ SDLI.Unit_Price__c = (mrpWrapper.MRP.Total_Amount_Required__c != Null && mrpWrapper.MRP.Total_Amount_Required__c > 0)? mrpWrapper.MRP.BOM_Requirement_Cost__c/mrpWrapper.MRP.Total_Amount_Required__c : 0; SDLI.Total_Amount__c = SDLI.Quantity__c*SDLI.Unit_Price__c; } if(mrpWrapper.MRP.Work_Order__c != Null) SDLI.Work_Orders__c = mrpWrapper.MRP.Work_Order__c; if(mrpWrapper.MRP.Work_Order_Line_Items__c != Null) SDLI.Work_Order_Line_Items__c = mrpWrapper.MRP.Work_Order_Line_Items__c; if(mrpWrapper.MRP.MO__c != Null) SDLI.Manufacturing_Order__c = mrpWrapper.MRP.MO__c; SDLIs2Upsert.add(SDLI); MapexistingstockSerials.get(mrpWrapper.MRP.Id).add(SN.Id); }
                                    
                                }
                            }
                            else{ system.debug('*** SNS out One: '); Stock_Outward_Line_Item__c SDLI = new Stock_Outward_Line_Item__c(Name = String.isNotBlank(mrpWrapper.MRP.MRP_Product__r.Name)? mrpWrapper.MRP.MRP_Product__r.Name:'', Active__c = true, Process__c = mrpWrapper.MRP.Process__c, Schedule__c = mrpWrapper.MRP.Schedule__c, MRP_Material_Requirements_Planning__c = mrpWrapper.MRP.Id, BOM_Line_Item__c = mrpWrapper.MRP.BOM_Line_Item__c, Status__c = 'Reserved', Product__c = mrpWrapper.MRP.MRP_Product__c, Site_Product_Service_Inventory_Stock__c = WIIS.Id, BOM__c = WIIS.BOM__c); if(Mapexistingstock.containsKey(mrpWrapper.MRP.Id)) { system.debug('out 1'); stockAllocated +=  (mrpWrapper.MRP.Total_Amount_Required__c/WM) - Mapexistingstock.get(mrpWrapper.MRP.Id); SDLI.Quantity__c = mrpWrapper.MRP.Total_Amount_Required__c/WM - Mapexistingstock.get(mrpWrapper.MRP.Id); } else { system.debug('out 2'); SDLI.Quantity__c = (mrpWrapper.MRP.Total_Amount_Required__c/WM).setScale(4); stockAllocated += (mrpWrapper.MRP.Total_Amount_Required__c/WM);} if(WIIS.Batch_Lot__c != null) SDLI.Material_Batch_Lot__c = WIIS.Batch_Lot__c; if(WIIS.Serial__c != null) { SDLI.Serial__c = WIIS.Serial__c; bomserials.add(WIIS.Serial__c); } if(mrpWrapper.MRP.BOM_Requirement_Cost__c != Null){ SDLI.Total_Amount__c = mrpWrapper.MRP.BOM_Requirement_Cost__c; SDLI.Unit_Price__c = (mrpWrapper.MRP.Total_Amount_Required__c != Null && mrpWrapper.MRP.Total_Amount_Required__c > 0)? mrpWrapper.MRP.BOM_Requirement_Cost__c/mrpWrapper.MRP.Total_Amount_Required__c : 0; } if(mrpWrapper.MRP.Work_Order__c != Null) SDLI.Work_Orders__c = mrpWrapper.MRP.Work_Order__c; if(mrpWrapper.MRP.Work_Order_Line_Items__c != Null) SDLI.Work_Order_Line_Items__c = mrpWrapper.MRP.Work_Order_Line_Items__c; if(mrpWrapper.MRP.MO__c != Null) SDLI.Manufacturing_Order__c = mrpWrapper.MRP.MO__c; if(mrpWrapper.Stock < SDLI.Quantity__c) SDLI.Quantity__c = mrpWrapper.Stock; SA = SA + SDLI.Quantity__c; bomDupProductStockAllocated.put(mrpWrapper.mrp.MRP_Product__c, SA); Decimal WIIS_Allocated = inventoryStockAllocated.get(WIIS.Id); inventoryStockAllocated.put(WIIS.Id, (WIIS_Allocated+SDLI.Quantity__c)); SDLIs2Upsert.add(SDLI); }
                            system.debug('mrpWrapper.MRP.Fulfilled_Amount__c bfr : '+mrpWrapper.MRP.Fulfilled_Amount__c);
                            system.debug('stockAllocated : '+stockAllocated);
                            system.debug('WM : '+WM);
                            
                            mrpWrapper.MRP.Fulfilled_Amount__c = (mrpWrapper.MRP.Fulfilled_Amount__c + (stockAllocated * WM)).setScale(4); //added setscale on 20_10_2023  //mrpWrapper.MRP.Total_Amount_Required__c; change added by shaguftha 11/09/23
                            system.debug('mrpWrapper.MRP.Fulfilled_Amount__c 1 : '+mrpWrapper.MRP.Fulfilled_Amount__c);
                            mrpWrapper.Stock = (mrpWrapper.Stock - stockAllocated).setScale(4); // added setScale on 20_10_23
                            system.debug('1 : mrpWrapper.Stock : '+mrpWrapper.Stock);
                            mrpWrapper.MRPQuantity = mrpWrapper.MRP.Total_Amount_Required__c - mrpWrapper.MRP.Fulfilled_Amount__c;
                            if(mrpWrapper.MRP.Fulfilled_Amount__c == mrpWrapper.MRP.Total_Amount_Required__c) mrpWrapper.MRP.Status__c = 'Reserved';
                            MRPs2Upsert.add(mrpWrapper.MRP);
                            comW.errorMsg = '';
                            mrpWrapret.add(mrpWrapper); 
                            
                        }
                        
                        
                        //Multiple WIIS calculative Reserving and other calculations
                        else if(WIIS.Number_of_Item_In_Stock__c - SA < mrpWrapper.MRP.Total_Amount_Required__c/WM){
                            system.debug('else if 1');
                            
                            //Need Change Imran
                            Decimal remainingqty = 0;
                            for(Inventory_Stock__c stk : WIISs){
                                Decimal WIISStock = stk.Number_of_Item_In_Stock__c - inventoryStockAllocated.get(stk.Id);
                                 if(mrpWrapper.MRP.Fulfilled_Amount__c != mrpWrapper.MRP.Total_Amount_Required__c && mrpWrapper.MRP.Fulfilled_Amount__c < mrpWrapper.MRP.Total_Amount_Required__c){
                                    if(SNS.size() > 0){
                                       system.debug('WIISStock : '+WIISStock);
                                        if(WIISStock > 0 && WIISStock >= (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM)){ 
                                            while(SNSMap.values().size() > 0){
                                                Serial_Number__c SN = SNSMap.values()[0];
                                                system.debug('SN : '+SN);
                                                system.debug('!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id) : '+!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id));
                                                //for(Serial_Number__c SN : SNS){
                                                if(!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id)){ // && WIISStock > 0 && WIISStock >= (mrpWrapper.MRP.BOM__r.Quantity__c/WM)
                                                    system.debug('*** SNS In two : '+SN.Name);
                                                    Stock_Outward_Line_Item__c SDLI = new Stock_Outward_Line_Item__c(Name = String.isNotBlank(mrpWrapper.MRP.MRP_Product__r.Name)? mrpWrapper.MRP.MRP_Product__r.Name:'', Active__c = true, Process__c = mrpWrapper.MRP.Process__c, Schedule__c = mrpWrapper.MRP.Schedule__c, MRP_Material_Requirements_Planning__c = mrpWrapper.MRP.Id, BOM_Line_Item__c = mrpWrapper.MRP.BOM_Line_Item__c, Status__c = 'Reserved', Product__c = mrpWrapper.MRP.MRP_Product__c, Site_Product_Service_Inventory_Stock__c = stk.Id, BOM__c = stk.BOM__c);
                                                    //totalAllocatedQty += stk.Number_of_Item_In_Stock__c;
                                                    //if(((mrpWrapper.MRP.Total_Amount_Required__c == stk.Number_of_Item_In_Stock__c) || (mrpWrapper.MRP.Total_Amount_Required__c > (stk.Number_of_Item_In_Stock__c + mrpWrapper.MRP.Fulfilled_Amount__c))) || remainingqty >= stk.Number_of_Item_In_Stock__c || remainingqty == 0) { SDLI.Quantity__c = stk.Number_of_Item_In_Stock__c; system.debug('stk.Number_of_Item_In_Stock__c 1 ***: '+stk.Number_of_Item_In_Stock__c); }
                                                    //else if(Mapexistingstock.containsKey(mrpWrapper.MRP.Id) && remainingqty > Mapexistingstock.get(mrpWrapper.MRP.Id)) { SDLI.Quantity__c = remainingqty - Mapexistingstock.get(mrpWrapper.MRP.Id); system.debug('SDLI.Quantity__c  1 ***: '+SDLI.Quantity__c ); }
                                                    //else { SDLI.Quantity__c = remainingqty;  system.debug('remainingqty  1 ***: '+remainingqty );}//stk.Number_of_Item_In_Stock__c -  mrpWrapper.MRP.Fulfilled_Amount__c;
                                                    stockAllocated += (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM);
                                                    system.debug('stockAllocated 2: '+stockAllocated);
                                                    SDLI.Quantity__c = (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM).setScale(4); SDLI.MO_WO_Serial__c = SN.Id; if(SN.Material_Batch_Lot__c != Null) SDLI.MO_WO_Material_Batch_Lot__c = SN.Material_Batch_Lot__c; if(stk.Batch_Lot__c != null) SDLI.Material_Batch_Lot__c = stk.Batch_Lot__c; if(stk.Serial__c != null) { SDLI.Serial__c = stk.Serial__c; bomserials.add(stk.Serial__c); } if(mrpWrapper.MRP.BOM_Requirement_Cost__c != Null){ SDLI.Total_Amount__c = mrpWrapper.MRP.BOM_Requirement_Cost__c; SDLI.Unit_Price__c = (mrpWrapper.MRP.Total_Amount_Required__c != Null && mrpWrapper.MRP.Total_Amount_Required__c > 0)? mrpWrapper.MRP.BOM_Requirement_Cost__c/mrpWrapper.MRP.Total_Amount_Required__c : 0; } if(mrpWrapper.MRP.Work_Order__c != Null) SDLI.Work_Orders__c = mrpWrapper.MRP.Work_Order__c; if(mrpWrapper.MRP.Work_Order_Line_Items__c != Null) SDLI.Work_Order_Line_Items__c = mrpWrapper.MRP.Work_Order_Line_Items__c; if(mrpWrapper.MRP.MO__c != Null) SDLI.Manufacturing_Order__c = mrpWrapper.MRP.MO__c; SDLIs2Upsert.add(SDLI); SA = SA + SDLI.Quantity__c; bomDupProductStockAllocated.put(mrpWrapper.mrp.MRP_Product__c, SA); Decimal WIIS_Allocated = inventoryStockAllocated.get(stk.Id); inventoryStockAllocated.put(stk.Id, (WIIS_Allocated+SDLI.Quantity__c)); 


                                                    
                                                    mrpWrapper.MRP.Fulfilled_Amount__c = mrpWrapper.MRP.Fulfilled_Amount__c + (SDLI.Quantity__c * WM);//(mrpWrapper.MRP.Fulfilled_Amount__c + stk.Number_of_Item_In_Stock__c).setscale(4);
                                                    WIISStock = WIISStock - SDLI.Quantity__c;
                                                    system.debug('SDLI else if 2: '+SDLI.Quantity__c+' MRP Fulfilled QTy : '+mrpWrapper.MRP.Fulfilled_Amount__c );
                                                    MapexistingstockSerials.get(mrpWrapper.MRP.Id).add(SN.Id);
                                                    if(WIISStock <= 0 || WIISStock < SDLI.Quantity__c) break;
                                                }
                                                SNSMap.remove(SN.Id);
                                                system.debug('SNSMap : '+SNSMap.size());
                                            }
                                        }
                                        // Start Shaguftha change 23_11_23
                                        else if(WIISStock > 0 && WIISStock < (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM)){
                                            while(SNSMap.values().size() > 0){
                                                Serial_Number__c SN = SNSMap.values()[0];
                                                system.debug('SN : '+SN);
                                                system.debug('!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id) : '+!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id));
                                                if(!MapexistingstockSerials.get(mrpWrapper.MRP.Id).contains(SN.Id)){ // && WIISStock > 0 && WIISStock >= (mrpWrapper.MRP.BOM__r.Quantity__c/WM)
                                                    system.debug('*** SNS In two : '+SN.Name);
                                                    Stock_Outward_Line_Item__c SDLI = new Stock_Outward_Line_Item__c(Name = String.isNotBlank(mrpWrapper.MRP.MRP_Product__r.Name)? mrpWrapper.MRP.MRP_Product__r.Name:'', Active__c = true, Process__c = mrpWrapper.MRP.Process__c, Schedule__c = mrpWrapper.MRP.Schedule__c, MRP_Material_Requirements_Planning__c = mrpWrapper.MRP.Id, BOM_Line_Item__c = mrpWrapper.MRP.BOM_Line_Item__c, Status__c = 'Reserved', Product__c = mrpWrapper.MRP.MRP_Product__c, Site_Product_Service_Inventory_Stock__c = stk.Id, BOM__c = stk.BOM__c);
                                                    //stockAllocated += (mrpWrapper.MRP.BOM__r.Quantity__c/WM);
                                                    system.debug('stockAllocated 2: '+stockAllocated);
                                                    SDLI.Quantity__c = WIISStock; //(mrpWrapper.MRP.BOM__r.Quantity__c/WM).setScale(4);
                                                    stockAllocated += SDLI.Quantity__c;
                                                    SDLI.MO_WO_Serial__c = SN.Id;
                                                    if(SN.Material_Batch_Lot__c != Null) SDLI.MO_WO_Material_Batch_Lot__c = SN.Material_Batch_Lot__c;
                                                    
                                                    if(stk.Batch_Lot__c != null) SDLI.Material_Batch_Lot__c = stk.Batch_Lot__c;
                                                    if(stk.Serial__c != null) {  SDLI.Serial__c = stk.Serial__c; bomserials.add(stk.Serial__c); }
                                                    if(mrpWrapper.MRP.BOM_Requirement_Cost__c != Null){
                                                        SDLI.Total_Amount__c = mrpWrapper.MRP.BOM_Requirement_Cost__c;
                                                        SDLI.Unit_Price__c = (mrpWrapper.MRP.Total_Amount_Required__c != Null && mrpWrapper.MRP.Total_Amount_Required__c > 0)? mrpWrapper.MRP.BOM_Requirement_Cost__c/mrpWrapper.MRP.Total_Amount_Required__c : 0;
                                                    }
                                                    if(mrpWrapper.MRP.Work_Order__c != Null) SDLI.Work_Orders__c = mrpWrapper.MRP.Work_Order__c;
                                                    if(mrpWrapper.MRP.Work_Order_Line_Items__c != Null) SDLI.Work_Order_Line_Items__c = mrpWrapper.MRP.Work_Order_Line_Items__c;
                                                    if(mrpWrapper.MRP.MO__c != Null) SDLI.Manufacturing_Order__c = mrpWrapper.MRP.MO__c;
                                                    SDLIs2Upsert.add(SDLI);
                                                    mrpWrapper.MRP.Fulfilled_Amount__c = mrpWrapper.MRP.Fulfilled_Amount__c + (SDLI.Quantity__c * WM);//(mrpWrapper.MRP.Fulfilled_Amount__c + stk.Number_of_Item_In_Stock__c).setscale(4);
                                                    WIISStock = WIISStock - SDLI.Quantity__c;
                                                    system.debug('SDLI else if 2: '+SDLI.Quantity__c+' MRP Fulfilled QTy : '+mrpWrapper.MRP.Fulfilled_Amount__c );
                                                    if(SerialsStockAllocated.containsKey(SN.Id)) SerialsStockAllocated.put(SN.Id,(SerialsStockAllocated.get(SN.Id) + SDLI.Quantity__c));
                                                    else SerialsStockAllocated.put(SN.Id,SDLI.Quantity__c);
                                                    if(SerialsStockAllocated.containsKey(SN.Id) && SerialsStockAllocated.get(SN.Id) == (mrpWrapper.MRP.BOM_Line_Item__r.Quantity__c/WM)) MapexistingstockSerials.get(mrpWrapper.MRP.Id).add(SN.Id);
                                                    if(WIISStock <= 0 || WIISStock < SDLI.Quantity__c) break;                                                    
                                                }
                                                system.debug('remove');
                                                SNSMap.remove(SN.Id);
                                                system.debug('SNSMap : '+SNSMap.size());
                                            }
                                        }
                                        // end Shaguftha change 23_11_23
                                    }
                                    else{

                                        system.debug('*** SNS out two: ');
                                        Stock_Outward_Line_Item__c SDLI = new Stock_Outward_Line_Item__c(Name = String.isNotBlank(mrpWrapper.MRP.MRP_Product__r.Name)? mrpWrapper.MRP.MRP_Product__r.Name:'', Active__c = true, Process__c = mrpWrapper.MRP.Process__c, Schedule__c = mrpWrapper.MRP.Schedule__c, MRP_Material_Requirements_Planning__c = mrpWrapper.MRP.Id, BOM_Line_Item__c = mrpWrapper.MRP.BOM_Line_Item__c, Status__c = 'Reserved', Product__c = mrpWrapper.MRP.MRP_Product__c, Site_Product_Service_Inventory_Stock__c = stk.Id, BOM__c = stk.BOM__c);
                                       // totalAllocatedQty += stk.Number_of_Item_In_Stock__c;
                                                //    System.debug('== Debugging MRP Allocation Condition ==');
                                                //    System.debug('Total_Amount_Required: ' + mrpWrapper.MRP.Total_Amount_Required__c);
                                                //    System.debug('Fulfilled_Amount: ' + mrpWrapper.MRP.Fulfilled_Amount__c);
                                                //    System.debug('WM (Working Multiplier): ' + WM);
                                                //    System.debug('WIISStock: ' + WIISStock);
                                                //    System.debug('remainingqty: ' + remainingqty);
                                                    
                                                //     Individual condition components for clarity
                                                //     Decimal requiredDivWM = mrpWrapper.MRP.Total_Amount_Required__c / WM;
                                                //    Decimal fulfilledDivWM = mrpWrapper.MRP.Fulfilled_Amount__c / WM;
                                                //     Decimal stockPlusFulfilled = WIISStock + fulfilledDivWM;
                                                    
                                                //    System.debug('Required / WM: ' + requiredDivWM);
                                                //    System.debug('Fulfilled / WM: ' + fulfilledDivWM);
                                                //    System.debug('Stock + Fulfilled: ' + stockPlusFulfilled);
                                                //    System.debug('Condition1 (Required / WM == WIISStock): ' + (requiredDivWM == WIISStock));
                                                //    System.debug('Condition2 (Required / WM > Stock + Fulfilled): ' + (requiredDivWM > stockPlusFulfilled));
                                                //    System.debug('Condition3 (remainingqty >= WIISStock): ' + (remainingqty >= WIISStock));
                                                //    System.debug('Condition4 (remainingqty == 0): ' + (remainingqty == 0));

                                        if (((mrpWrapper.MRP.Total_Amount_Required__c / WM == WIISStock) || (mrpWrapper.MRP.Total_Amount_Required__c / WM > (WIISStock + mrpWrapper.MRP.Fulfilled_Amount__c / WM))) || remainingqty >= WIISStock || remainingqty == 0) {
                                            /*stockAllocated += stk.Number_of_Item_In_Stock__c;*/
                                            //added this condition by matheen 24/2/25
                                            if(remainingqty!=0 && remainingqty < WIISStock){ 
                                                SDLI.Quantity__c =remainingqty ;
                                            }else {
                                                SDLI.Quantity__c = WIISStock;
                                            }
                                            // matheen changes ends here
                                            system.debug('in awkward condition  ***: ' + SDLI.Quantity__c);
                                            System.debug('remainingqty ***: ' + remainingqty);
                                            system.debug('WIISStock ***: ' + WIISStock);
                                        } else if (Mapexistingstock.containsKey(mrpWrapper.MRP.Id) && remainingqty > Mapexistingstock.get(mrpWrapper.MRP.Id)) {
                                            SDLI.Quantity__c = (remainingqty - Mapexistingstock.get(mrpWrapper.MRP.Id)).setScale(4); /*stockAllocated += (remainingqty - Mapexistingstock.get(mrpWrapper.MRP.Id));*/
                                            system.debug('SDLI.Quantity__c  1 ***: ' + SDLI.Quantity__c);
                                        } else {
                                            SDLI.Quantity__c = (remainingqty).setScale(4); /*stockAllocated += remainingqty; */
                                            system.debug('remainingqty  1 ***: ' + remainingqty);
                                        } //stk.Number_of_Item_In_Stock__c -  mrpWrapper.MRP.Fulfilled_Amount__c;
                                        
                                        
                                        //partial allocation bushra
                                        System.debug('mrpWrapper.Stock before partial allocation: ' + mrpWrapper.Stock);
                                        if(mrpWrapper.Stock < SDLI.Quantity__c) SDLI.Quantity__c = mrpWrapper.Stock;
                                        System.debug('SDLI.Quantity__c for partial allocation: ' + SDLI.Quantity__c);
                                        SA = SA + SDLI.Quantity__c;
                            			bomDupProductStockAllocated.put(mrpWrapper.mrp.MRP_Product__c, SA);

                                        Decimal WIIS_Allocated = inventoryStockAllocated.get(stk.Id);
                                        inventoryStockAllocated.put(stk.Id, (WIIS_Allocated+SDLI.Quantity__c)); 
                                        
                                        stockAllocated += SDLI.Quantity__c; // uncommented on 18_10_23
                                        
                                        if(stk.Batch_Lot__c != null) SDLI.Material_Batch_Lot__c = stk.Batch_Lot__c;
                                        if(stk.Serial__c != null) { SDLI.Serial__c = stk.Serial__c; bomserials.add(stk.Serial__c);}
                                        if(mrpWrapper.MRP.BOM_Requirement_Cost__c != Null){
                                            SDLI.Total_Amount__c = mrpWrapper.MRP.BOM_Requirement_Cost__c;
                                            SDLI.Unit_Price__c = (mrpWrapper.MRP.Total_Amount_Required__c != Null && mrpWrapper.MRP.Total_Amount_Required__c > 0)? mrpWrapper.MRP.BOM_Requirement_Cost__c/mrpWrapper.MRP.Total_Amount_Required__c : 0;
                                        }
                                        if(mrpWrapper.MRP.Work_Order__c != Null) SDLI.Work_Orders__c = mrpWrapper.MRP.Work_Order__c;
                                        if(mrpWrapper.MRP.Work_Order_Line_Items__c != Null) SDLI.Work_Order_Line_Items__c = mrpWrapper.MRP.Work_Order_Line_Items__c;
                                        if(mrpWrapper.MRP.MO__c != Null) SDLI.Manufacturing_Order__c = mrpWrapper.MRP.MO__c;
                                        
                                        
                                        SDLIs2Upsert.add(SDLI);
                                        mrpWrapper.MRP.Fulfilled_Amount__c = mrpWrapper.MRP.Fulfilled_Amount__c + (SDLI.Quantity__c * WM);//(mrpWrapper.MRP.Fulfilled_Amount__c + stk.Number_of_Item_In_Stock__c).setscale(4); // 18_10_23 SDLI.Quantity__c from StockAllocated
                                        system.debug('SDLI else if 2: '+SDLI.Quantity__c+' MRP QTy : '+mrpWrapper.MRP.Fulfilled_Amount__c );
                                    }
                                    //mrpWrapper.Stock = mrpWrapper.Stock - mrpWrapper.MRP.Fulfilled_Amount__c;       
                                    //mrpWrapper.MRP.Fulfilled_Amount__c = mrpWrapper.MRP.Fulfilled_Amount__c + Decimal.valueOf(stockAllocated * WM);
                                    remainingqty = (mrpWrapper.MRP.Total_Amount_Required__c - mrpWrapper.MRP.Fulfilled_Amount__c)/WM;
                                    if(remainingqty < 0) remainingqty = 0;
                                    system.debug('mrpWrapper.MRP.Fulfilled_Amount__c 1 : '+mrpWrapper.MRP.Fulfilled_Amount__c);
                                    if(mrpWrapper.MRP.Fulfilled_Amount__c >= mrpWrapper.MRP.Total_Amount_Required__c){
                                        Decimal totalFulfilled =  (Mapexistingstock.containsKey(mrpWrapper.MRP.Id)) ?  (Mapexistingstock.get(mrpWrapper.MRP.Id)) : 0;
                                        /*for(Stock_Outward_Line_Item__c ss : SDLIs2Upsert){
                                                    if(ss.MRP_Material_Requirements_Planning__c == mrpWrapper.MRP.Id) totalFulfilled += ss.Quantity__c;
                                                    }*/ 
                                        System.debug('totalFulfilled : '+totalFulfilled);
                                        mrpWrapper.MRP.Fulfilled_Amount__c = (totalFulfilled * WM) + (stockAllocated * WM); // added * WM for totalfulfilled Shaguftha 02_01_2024
                                        system.debug('totalFulfilled else if 2 after: '+totalFulfilled+' MRP QTy : '+mrpWrapper.MRP.Fulfilled_Amount__c );
                                        if(mrpWrapper.MRP.Fulfilled_Amount__c >= mrpWrapper.MRP.Total_Amount_Required__c) mrpWrapper.MRP.Status__c = 'Reserved';
                                        // mrpWrapper.MRPQuantity = mrpWrapper.MRP.Total_Amount_Required__c - mrpWrapper.MRP.Fulfilled_Amount__c;
                                        system.debug('mrpWrapper.Stock  : '+mrpWrapper.Stock);
                                        //  MRPs2Upsert.add(mrpWrapper.MRP);
                                        comW.errorMsg = '';
                                        mrpWrapret.add(mrpWrapper);
                                        break;
                                    } 
                                }
                            } // for WIIS
                            system.debug('stockAllocated : '+stockAllocated);
                            system.debug('mrpWrapper.Stock : '+mrpWrapper.Stock);
                            mrpWrapper.MRPQuantity = mrpWrapper.MRP.Total_Amount_Required__c - mrpWrapper.MRP.Fulfilled_Amount__c;
                            mrpWrapper.Stock = mrpWrapper.Stock - stockAllocated;
                            MRPs2Upsert.add(mrpWrapper.MRP);
                            mrpWrapret.add(mrpWrapper); 
                            system.debug('MRPs2Upsert : '+MRPs2Upsert);
                        } // Multiple WIIS
                        
                        
                    } // WIIS size > 0
                } // MRP Stock > 0
                
               
            }
            mrpWrappers = new List<mrpWrap>();
            System.debug('Limits.getCpuTime 2- '+ Limits.getCpuTime());
            System.debug('Limits.getLimitCpuTime 2- '+ Limits.getLimitCpuTime());
            System.debug('Limits.getHeapSize 2- '+ Limits.getHeapSize());
            System.debug('Limits.getLimitHeapSize 2- '+ Limits.getLimitHeapSize());
            
            if(SDLIs2Upsert.size() > 0){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){ PreventRecursiveLedgerEntry.proceedStockOutwardUpdateHandler=false; upsert SDLIs2Upsert;}else{comW.errorMsg ='Not allowed to upsert SDLI';} }
            //new code start
                List<Serial_Number__c> bomserialstoupdate=new List<Serial_Number__c>();
                            if(bomserials.size()>0){ bomserialstoupdate=[select id, name, available__c, product__c, bom__c, scrap__c from Serial_Number__c where id in: bomserials]; if(bomserialstoupdate != null && bomserialstoupdate.size()>0){ for(Serial_Number__c ser:bomserialstoupdate ){if(ser.available__c != null && ser.available__c){if(Schema.sObjectType.Serial_Number__c.fields.Available__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.Available__c.isUpdateable())ser.Available__c=false;}} System.SObjectAccessDecision securityDecision = Security.stripInaccessible( AccessType.UPDATABLE, bomserialstoupdate ); List<Serial_Number__c> accessibleRecords = (List<Serial_Number__c>) securityDecision.getRecords(); if (!accessibleRecords.isEmpty()) { update accessibleRecords; } }
                            }//end
            SDLIs2Upsert = new List<Stock_Outward_Line_Item__c>();
            if(MRPs2Upsert.size() > 0){ if(Schema.sObjectType.MRP__c.isCreateable() && Schema.sObjectType.MRP__c.isUpdateable()){PreventRecursiveLedgerEntry.MRPFlowTrigger = false; upsert MRPs2Upsert;}else{comW.errorMsg ='Not allowed to upsert MRPs';} }
            List<mrpWrap> retunrMRP = new List<mrpWrap>();
            for(mrpWrap mrpWrapper : mrpWrapret){ for(MRP__c mrp : MRPs2Upsert){    if(mrpWrapper.MRP.MRP_Product__c == mrp.MRP_Product__c){     mrpWrapper.MRP = mrp;
                        // mrpWrapper.Stock = mrpWrapper.Stock - mrp.Fulfilled_Amount__c;
                        system.debug('mrpWrapper.Stock : '+mrpWrapper.Stock);
                    }                    
                }
                retunrMRP.add(mrpWrapper);
            }
            MRPs2Upsert = new List<MRP__c>();
            mrpWrapret = new List<mrpWrap>();
            comW.MRPs=retunrMRP;
            retunrMRP = new List<mrpWrap>();
        } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber();  }
        return comW;
    } 

    @AuraEnabled
    public static comWrap SaveNewSOLI(String NewSOLI, String MRPs, String SerialNos){
        Savepoint sp = Database.setSavepoint();
        List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
        Stock_Outward_Line_Item__c mySOLI = (Stock_Outward_Line_Item__c) JSON.deserialize(NewSOLI, Stock_Outward_Line_Item__c .class);
        List<Id> moSerialNos = (List<Id>) JSON.deserialize(SerialNos, List<Id> .class);
		//new code here to uncheck the available checkbox on Serial_Number__c
		Set<Id> bomserials=new Set<Id>();//new line
        mrpWrap mrp = new mrpWrap();
        for(mrpWrap mrpW : mrpWrappers){
            if(mrpW.isSelect) mrp = mrpW;
        }
        comWrap comW = new comWrap();
        comW.errorMsg = '';
        try{
            if(mrp.isSelect){
                Decimal WM = mrp.WeightMultiplier;
                String selectedSite = mrp.MRP.MO__r.Routing__r.Raw_Materials_Site__c;
                String MOId = mrp.MRP.MO__c;
                String Prod = mrp.MRP.MRP_Product__c;
                if(selectedSite != Null && selectedSite != ''){
                    String WarehouseFields = UtilClass.selectStarFromSObject('Inventory_Stock__c');
                    String AllWarehouseFields = WarehouseFields + '';
                    List<Inventory_Stock__c> WIISLists = new List<Inventory_Stock__c> ();
                    if(!mrp.MRP.MRP_Product__r.Serialise__c && !mrp.MRP.MRP_Product__r.Lot_Tracked__c)
                        WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c =: Prod And Number_of_Item_In_Stock__c > 0) And Active__c = true) Order By Expiry_Date__c ASC');
                    else if(mrp.MRP.MRP_Product__r.Serialise__c){
                        List<Stock_Inward_Line_Item__c>  SDLIs = [Select Id, Name, Active__c, Fixed_Asset__c, Quantity__c,  Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, Batch_Lot_Code__c,  Product__c, Site_ProductService_InventoryStock__c, Site_ProductService_InventoryStock__r.Warehouse__c, Site_ProductService_InventoryStock__r.Number_of_Item_In_Stock__c,  Site_ProductService_InventoryStock__r.BOM__c     From Stock_Inward_Line_Item__c        Where Product__c = :Prod And           Serial__c != Null And        Serial__r.Available__c = true And        Site_ProductService_InventoryStock__r.Number_of_Item_In_Stock__c > 0 And         Site_ProductService_InventoryStock__r.Warehouse__c = : selectedSite And         Serial__c = :mySOLI.Serial__c Limit 1];
                        if(SDLIs.size() > 0){     String stkId = SDLIs[0].Site_ProductService_InventoryStock__c;      WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, StorageContainer__r.Barcode__c from Inventory_Stock__c where Id =: stkId');                        } }
                    else if(mrp.MRP.MRP_Product__r.Lot_Tracked__c){  String batch = mySOLI.Material_Batch_Lot__c;  WIISLists = Database.query('select ' + String.escapeSingleQuotes(AllWarehouseFields) + ', Warehouse__r.Name, Location__r.Name, StorageContainer__r.Name, Warehouse__r.Barcode__c, Location__r.Barcode__c, StorageContainer__r.Barcode__c from Inventory_Stock__c where (Warehouse__c =: selectedSite And (Product__c =: Prod And Number_of_Item_In_Stock__c > 0) And Active__c = true And Batch_Lot__c =: batch) Order By Expiry_Date__c ASC');     }

                    Decimal myStock = 0;
                    for(Inventory_Stock__c stock : WIISLists){
                        myStock += stock.Number_of_Item_In_Stock__c;
                    }

                    mySOLI.Quantity__c = mySOLI.Quantity__c.setScale(4);
                    system.debug('moSerialNos.size() : '+moSerialNos.size());
                    Decimal totalQuantity = (moSerialNos.size() > 0)? mySOLI.Quantity__c * moSerialNos.size() : mySOLI.Quantity__c;
                    if(myStock >= totalQuantity){
                        system.debug('mrp.MRP.Total_Amount_Required__c : '+ mrp.MRP.Total_Amount_Required__c);
                        system.debug('mrp.MRP.Fulfilled_Amount__c : '+ mrp.MRP.Fulfilled_Amount__c);

                        if(Schema.sObjectType.MRP__c.fields.Fulfilled_Amount__c.isCreateable() && Schema.sObjectType.MRP__c.fields.Fulfilled_Amount__c.isUpdateable()){
                            mrp.MRP.Fulfilled_Amount__c = (mrp.MRP.Fulfilled_Amount__c != null)? mrp.MRP.Fulfilled_Amount__c.setScale(4) : 0 ;
                            mrp.ActualWeight = mrp.MRP.Fulfilled_Amount__c;
                        }else{ /*No access*/ } //.setScale(2)
                        if(Schema.sObjectType.MRP__c.fields.Status__c.isCreateable() && Schema.sObjectType.MRP__c.fields.Status__c.isUpdateable()){
                            if(mrp.MRP.Status__c == 'Requested' && mrp.MRP.Fulfilled_Amount__c == mrp.MRP.Total_Amount_Required__c) mrp.MRP.Status__c = 'Reserved';
                        }else{/*No access*/}
                        system.debug('mrp.MRP.Status__c : '+ mrp.MRP.Status__c);
                        Decimal AllocatedStock = 0;
                        List<Stock_Outward_Line_Item__c> SOLIs2Upsert = new List<Stock_Outward_Line_Item__c>();
                        system.debug('AllocatedStock  : '+AllocatedStock );
                        system.debug('totalQuantity: '+totalQuantity);
                        if(moSerialNos.size() == 0){
                            for(Inventory_Stock__c stock : WIISLists){
                                if(AllocatedStock < totalQuantity){
                                    Stock_Outward_Line_Item__c myNewSOLI = new Stock_Outward_Line_Item__c();
                                    if(mySOLI.Quantity__c <= stock.Number_of_Item_In_Stock__c ){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = mySOLI.Quantity__c;}else{/*No access*/} }      else{ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = stock.Number_of_Item_In_Stock__c;}else{/*No access*/} }
                                    AllocatedStock += myNewSOLI.Quantity__c;
                                    mySOLI.Quantity__c = mySOLI.Quantity__c - myNewSOLI.Quantity__c; // added by shaguftha on 08_04_24 to fix the issue of allocating more quantity when the stock on fisrt inventory record is less than total required
                                    system.debug('myNewSOLI.Quantity__c : '+myNewSOLI.Quantity__c);
                                    system.debug('mySOLI.Quantity__c : '+mySOLI.Quantity__c);
                                    //mrp.ActualWeight += myNewSOLI.Quantity__c;
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()){myNewSOLI.Name = String.isNotBlank(mrp.MRP.MRP_Product__r.Name)? mrp.MRP.MRP_Product__r.Name:'';}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()){myNewSOLI.Product__c = mrp.MRP.MRP_Product__c;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()){myNewSOLI.Site_Product_Service_Inventory_Stock__c = stock.Id;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){myNewSOLI.Status__c = 'Reserved';}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()){myNewSOLI.BOM__c = mrp.MRP.BOM__c;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()){myNewSOLI.Active__c = true;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()){myNewSOLI.MRP_Material_Requirements_Planning__c = mrp.MRP.Id;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM_Line_Item__c.isUpdateable()){myNewSOLI.BOM_Line_Item__c = mrp.MRP.BOM_Line_Item__c;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()){myNewSOLI.Work_Orders__c = mrp.MRP.Work_Order__c;}else{/*No access*/}
                                    if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()){myNewSOLI.Manufacturing_Order__c = mrp.MRP.MO__c;}else{/*No access*/}
                                    if(mySOLI.Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.Material_Batch_Lot__c = mySOLI.Material_Batch_Lot__c; }else{/*No access*/}
                                    if(mySOLI.Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isUpdateable()){ 
                                        myNewSOLI.Serial__c = mySOLI.Serial__c; bomserials.add(mySOLI.Serial__c);
                                    }else{/*No access*/}
                                    if(mySOLI.MO_WO_Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.MO_WO_Material_Batch_Lot__c = mySOLI.MO_WO_Material_Batch_Lot__c; }else{/*No access*/}
                                    if(mySOLI.MO_WO_Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isUpdateable()){ myNewSOLI.MO_WO_Serial__c = mySOLI.MO_WO_Serial__c; }else{/*No access*/}

                                    if(mrp.MRP.BOM_Requirement_Cost__c != Null){    mySOLI.Total_Amount__c = mrp.MRP.BOM_Requirement_Cost__c/WM;       mySOLI.Unit_Price__c = (mrp.MRP.Total_Amount_Required__c != Null && mrp.MRP.Total_Amount_Required__c > 0)? (mrp.MRP.BOM_Requirement_Cost__c/mrp.MRP.Total_Amount_Required__c)/WM : 0;   }

                                    SOLIs2Upsert.add(myNewSOLI);
                                }
                            }
                        } else{
                            Map<Id, Decimal> serialAllocationMap = new Map<Id, Decimal>(); for (Id moSNId : moSerialNos) { serialAllocationMap.put(moSNId, 0); } for(Inventory_Stock__c stock : WIISLists){ Decimal currentStock = stock.Number_of_Item_In_Stock__c; for(Id moSNId:  moSerialNos){ Decimal allocatedQty = serialAllocationMap.get(moSNId); system.debug('allocatedQty : '+allocatedQty); if (allocatedQty >= mySOLI.Quantity__c) { continue; } system.debug('currentStock bfr: '+currentStock); if(AllocatedStock < totalQuantity && currentStock > 0){ Stock_Outward_Line_Item__c myNewSOLI = new Stock_Outward_Line_Item__c(); Decimal remainingQtyForSerial = mySOLI.Quantity__c - allocatedQty; system.debug('remainingQtyForSerial : '+remainingQtyForSerial); if(remainingQtyForSerial <= currentStock){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = remainingQtyForSerial;}else{/*No access*/} } else{ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = currentStock;}else{/*No access*/} } AllocatedStock += myNewSOLI.Quantity__c;
                                        currentStock -= myNewSOLI.Quantity__c;
                                        serialAllocationMap.put(moSNId, allocatedQty + myNewSOLI.Quantity__c);
                                        //system.debug('myNewSOLI.Quantity__c : '+myNewSOLI.Quantity__c);
                                        system.debug('mySOLI.Quantity__c : '+mySOLI.Quantity__c);
                                        // mrp.ActualWeight += myNewSOLI.Quantity__c;
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Name.isUpdateable()){myNewSOLI.Name = String.isNotBlank(mrp.MRP.MRP_Product__r.Name)? mrp.MRP.MRP_Product__r.Name:'';}else{/*No access*/}
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()){myNewSOLI.Product__c = mrp.MRP.MRP_Product__c;}else{/*No access*/}
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()){myNewSOLI.Site_Product_Service_Inventory_Stock__c = stock.Id;}else{/*No access*/}
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){myNewSOLI.Status__c = 'Reserved';}else{/*No access*/}
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()){myNewSOLI.BOM__c = mrp.MRP.BOM__c;}else{/*No access*/}
                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()){myNewSOLI.Active__c = true;}else{/*No access*/} if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()){myNewSOLI.MRP_Material_Requirements_Planning__c = mrp.MRP.Id;}else{/*No access*/} if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BoM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM_Line_Item__c.isUpdateable()){myNewSOLI.BOM_Line_Item__c = mrp.MRP.BOM_Line_Item__c;}else{/*No access*/} if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()){myNewSOLI.Work_Orders__c = mrp.MRP.Work_Order__c;}else{/*No access*/} if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()){myNewSOLI.Manufacturing_Order__c = mrp.MRP.MO__c;}else{/*No access*/} if(mySOLI.Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.Material_Batch_Lot__c = mySOLI.Material_Batch_Lot__c; }else{/*No access*/} if(mySOLI.Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isUpdateable()){ myNewSOLI.Serial__c = mySOLI.Serial__c; bomserials.add(mySOLI.Serial__c);}else{/*No access*/} if(mySOLI.MO_WO_Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.MO_WO_Material_Batch_Lot__c = mySOLI.MO_WO_Material_Batch_Lot__c; }else{/*No access*/} if(mySOLI.MO_WO_Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isUpdateable()){ myNewSOLI.MO_WO_Serial__c = moSNId; }else{/*No access*/} if(mrp.MRP.BOM_Requirement_Cost__c != Null){ mySOLI.Total_Amount__c = mrp.MRP.BOM_Requirement_Cost__c/WM; mySOLI.Unit_Price__c = (mrp.MRP.Total_Amount_Required__c != Null && mrp.MRP.Total_Amount_Required__c > 0)? (mrp.MRP.BOM_Requirement_Cost__c/mrp.MRP.Total_Amount_Required__c)/WM : 0; } SOLIs2Upsert.add(myNewSOLI); } else if(currentStock == 0){
                                        continue;
                                    }
                                    system.debug('currentStock afte: '+currentStock);
                                }
                            }
                        }
                       /* {
                            for(Inventory_Stock__c stock : WIISLists){
                                for(Id moSNId:  moSerialNos){
                                    if(AllocatedStock < totalQuantity){
                                        Stock_Outward_Line_Item__c myNewSOLI = new Stock_Outward_Line_Item__c();        
										if(mySOLI.Quantity__c <= stock.Number_of_Item_In_Stock__c ){ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = mySOLI.Quantity__c;}else{} }                                        else{ if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Quantity__c.isUpdateable()){myNewSOLI.Quantity__c = stock.Number_of_Item_In_Stock__c;}else{} }                                        AllocatedStock += myNewSOLI.Quantity__c;                                        system.debug('mySOLI.Quantity__c : '+mySOLI.Quantity__c);                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Product__c.isUpdateable()){myNewSOLI.Product__c = mrp.MRP.MRP_Product__c;}else{}                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Site_Product_Service_Inventory_Stock__c.isCreateable()){myNewSOLI.Site_Product_Service_Inventory_Stock__c = stock.Id;}else{}                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){myNewSOLI.Status__c = 'Reserved';}else{}                                       if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM__c.isUpdateable()){myNewSOLI.BOM__c = mrp.MRP.BOM__c;}else{}                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Active__c.isUpdateable()){myNewSOLI.Active__c = true;}else{}                                       if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MRP_Material_Requirements_Planning__c.isUpdateable()){myNewSOLI.MRP_Material_Requirements_Planning__c = mrp.MRP.Id;}else{}                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.BOM_Line_Item__c.isUpdateable()){myNewSOLI.BOM_Line_Item__c = mrp.MRP.BOM_Line_Item__c;}else{}                                        if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Work_Orders__c.isUpdateable()){myNewSOLI.Work_Orders__c = mrp.MRP.Work_Order__c;}else{}                                      if(Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Manufacturing_Order__c.isUpdateable()){myNewSOLI.Manufacturing_Order__c = mrp.MRP.MO__c;}else{}                                       if(mySOLI.Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.Material_Batch_Lot__c = mySOLI.Material_Batch_Lot__c; }else{}   if(mySOLI.Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Serial__c.isUpdateable()){ myNewSOLI.Serial__c = mySOLI.Serial__c; }else{}    if(mySOLI.MO_WO_Material_Batch_Lot__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Material_Batch_Lot__c.isUpdateable()){ myNewSOLI.MO_WO_Material_Batch_Lot__c = mySOLI.MO_WO_Material_Batch_Lot__c; }else{}  if(mySOLI.MO_WO_Serial__c != Null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.MO_WO_Serial__c.isUpdateable()){ myNewSOLI.MO_WO_Serial__c = moSNId; }else{}
										if(mrp.MRP.BOM_Requirement_Cost__c != Null){  mySOLI.Total_Amount__c = mrp.MRP.BOM_Requirement_Cost__c/WM;     mySOLI.Unit_Price__c = (mrp.MRP.Total_Amount_Required__c != Null && mrp.MRP.Total_Amount_Required__c > 0)? (mrp.MRP.BOM_Requirement_Cost__c/mrp.MRP.Total_Amount_Required__c)/WM : 0;   }  SOLIs2Upsert.add(myNewSOLI);
                                    }
                                }
                            }
                        }*/
                        if(Schema.sObjectType.MRP__c.isCreateable() && Schema.sObjectType.MRP__c.isUpdateable()){upsert mrp.MRP;system.debug('mrp.MRP.Status__c after update MRP: '+ mrp.MRP.Status__c);}else{comW.errorMsg = 'Not allowed to upsert MRPs';}
                        if(SOLIs2Upsert.size()>0){
                            if(Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){upsert SOLIs2Upsert; system.debug('mrp.MRP.Status__c after update sOLI: '+ mrp.MRP.Status__c);}else{comW.errorMsg = 'Not allowed to upsert Stock Outward';}

                        }//new code below
                        List<Serial_Number__c> bomserialstoupdate=new List<Serial_Number__c>();
                        if(bomserials.size()>0){
                            bomserialstoupdate=[select id, name, available__c, product__c, bom__c, scrap__c from Serial_Number__c where id in: bomserials];
                            if(bomserialstoupdate != null && bomserialstoupdate.size()>0){
                                for(Serial_Number__c ser:bomserialstoupdate ){if(ser.available__c != null && ser.available__c){if(Schema.sObjectType.Serial_Number__c.fields.Available__c.isCreateable() || Schema.sObjectType.Serial_Number__c.fields.Available__c.isUpdateable())ser.Available__c=false;}}
                              //  upsert bomserialstoupdate;
                                System.SObjectAccessDecision securityDecision1 = Security.stripInaccessible(
                                    AccessType.UPDATABLE,
                                    bomserialstoupdate
                                );
                                
                                List<Serial_Number__c> accessibleRecords1 = (List<Serial_Number__c>) securityDecision1.getRecords();
                                
                                if (!accessibleRecords1.isEmpty()) {
                                    upsert accessibleRecords1;
                                }
                            }
                        }
                        //end
                        mrp.SOLIs = [Select Id, Name, Active__c, Batch_Lot_Code__c, BOM_Line_Item__c, BOM_Line_Item__r.Quantity__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c, BOM__c, Serial__c, Serial__r.Name, MO_WO_Serial__c, MO_WO_Serial__r.Name, MO_WO_Material_Batch_Lot__c, MO_WO_Material_Batch_Lot__r.Name,
                                     Product__c, Purchase_Orders__c, Quantity__c, Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name
                                     From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c =: mrp.MRP.Id];
                        set<String> serialsIds = new set<String> ();
                        Map<String, Decimal> serialQuantityMap = new Map<String, Decimal>();
                        
                        // Step 3: Iterate over the SOLIs and sum up the quantity for each MO_WO_Serial__c
                        for (Stock_Outward_Line_Item__c soli : mrp.SOLIs) {
                            if (soli.MO_WO_Serial__c != null) {
                                if (serialQuantityMap.containsKey(soli.MO_WO_Serial__c)) {
                                    // Add the Quantity to the existing value in the map
                                    serialQuantityMap.put(soli.MO_WO_Serial__c, serialQuantityMap.get(soli.MO_WO_Serial__c) + soli.Quantity__c);
                                } else {
                                    // Initialize with the current Quantity
                                    serialQuantityMap.put(soli.MO_WO_Serial__c, soli.Quantity__c);
                                }
                            }
                        }
                        for (Stock_Outward_Line_Item__c soli : mrp.SOLIs) {
                            if (soli.MO_WO_Serial__c != null && serialQuantityMap.containsKey(soli.MO_WO_Serial__c)) {
                                // Get the total quantity for the current MO_WO_Serial__c
                                Decimal totQuantity = serialQuantityMap.get(soli.MO_WO_Serial__c);
                                
                                // Compare total quantity with BOM_Line_Item__r.Quantity__c
                                if (totQuantity == soli.BOM_Line_Item__r.Quantity__c) {
                                    // If they are equal, add the MO_WO_Serial__c to the set
                                    serialsIds.add(soli.MO_WO_Serial__c);
                                }
                            }
                        }
                        //for(Stock_Outward_Line_Item__c stk : mrp.SOLIs) { if(stk.MO_WO_Serial__c != null && stk.BOM_Line_Item__c!=null && stk.BOM_Line_Item__r.Quantity__c!=null && stk.Quantity__c==stk.BOM_Line_Item__r.Quantity__c){system.debug('stk.Quantity__c : '+stk.Quantity__c+'stk.BOM_Line_Item__r.Quantity__c '+stk.BOM_Line_Item__r.Quantity__c); serialsIds.add(stk.MO_WO_Serial__c);} }
                        mrp.Stock = mrp.Stock - totalQuantity;
                        mrp.MRPQuantity = (mrp.Stock > 0 && mrp.Stock > mrp.MRP.Total_Amount_Required__c) ? (mrp.MRP.Total_Amount_Required__c - mrp.MRP.Fulfilled_Amount__c) : mrp.Stock;
                        system.debug('totalQuantity : '+totalQuantity);
                        comW.MRPs = mrpWrappers;
                        List<String> serialsList = new List<String>(serialsIds);
                        comW.moSerialNos = getSerialNumbers(0,MOId,500,serialsList); // changed on 26_09_24 to fix the serial display issue
                            //[Select Id,Name,Availability_date__c,Available__c,Barcode__c,Date_of_Manufacture__c,Serial_Number__c,Manufacturing_Order__c,Manufacturing_Order__r.Id,Manufacturing_Order__r.Name from  Serial_Number__c where Manufacturing_Order__c   = :MOId and Id Not IN : serialsIds LIMIT 1000];
                    }
                    else{     Database.rollback(sp);    comW.errorMsg = System.Label.Invalid_stock;   } } else{   Database.rollback(sp);       comW.errorMsg = 'Raw Material Missing/Invalid on Routing';    } } } catch(DMLException e){    Database.rollback(sp);     comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }
    @AuraEnabled
    public static List<Stock_Outward_Line_Item__c> getMRPDetails(String MRP,String Mo){
        List<Stock_Outward_Line_Item__c> stk = new List<Stock_Outward_Line_Item__c>();
        stk = [Select Id, Name, Active__c, Batch_Lot_Code__c, BOM_Line_Item__c, BOM_Line_Item__r.Quantity__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c, BOM__c, Serial__c, Serial__r.Name,Serial__r.Date_of_Manufacture__c,  MO_WO_Serial__c, MO_WO_Serial__r.Name, MO_WO_Material_Batch_Lot__c, MO_WO_Material_Batch_Lot__r.Name,
               Product__c, Purchase_Orders__c, Quantity__c, Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name, Scrap__c
               From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c =: MRP AND MRP_Material_Requirements_Planning__c != null];//new condition Scrap__c=false
        return stk;

    }
    @AuraEnabled
    public static Double getSerialStock(String serialId){

        Double serialStock = 0.0;
        try{
            Set<Id> stockIds = new Set<Id>();
            List<AggregateResult> serialInv = new List<AggregateResult>();
            List<AggregateResult> serialInvOut = new List<AggregateResult>();
            serialInv = [Select SUM(Number_of_Item_In_Stock__c)avaialbleStock from Inventory_Stock__c WHERE Serial__c =: serialId AND Serial__c != null GROUP BY Serial__c];

            if(serialInv.size() > 0) serialStock = (Double)serialInv[0].get('avaialbleStock');

        }catch(Exception e){
            /*'exception occured : '+ e.getMessage() + '; At line : ' + e.getLineNumber()*/
            //throw new AuraHandledException(e.getMessage());
        }
        return serialStock;
    }

    @AuraEnabled
    public static Double getBatchStock(String batchId,string site){
        try{
            Double batchStock = 0.0;
            List<AggregateResult> batchInv = new List<AggregateResult>();
            batchInv = [SELECT SUM(Number_of_Item_In_Stock__c) avaialbleStock FROM Inventory_Stock__c WHERE Batch_Lot__c =: batchId AND Batch_Lot__c != null AND Number_of_Item_In_Stock__c > 0 and Warehouse__c =: site GROUP BY Batch_Lot__c];
            if(batchInv.size() > 0) batchStock = (Double)batchInv[0].get('avaialbleStock');
            return batchStock;    }catch(Exception e){ throw new AuraHandledException(e.getMessage()); }
    }


   @AuraEnabled
    public static String setSerials(String MOId,String serialsList){
        try{
            List<String> ser=new List<String>();
            List<Serial_Number__c> serials2=new List<Serial_Number__c>();
            List<Serial_Number__c> serials = (List<Serial_Number__c>) JSON.deserialize(serialsList,List<Serial_Number__c>.class);
            for(Serial_Number__c x:serials){ ser.add(x.Serial_No__c);}
            serials2=[select id, name from Serial_Number__c where Manufacturing_Order__c!=:MOId and Serial_No__c IN:ser ];
            system.debug('existing serials are present: '+serials2);
            if(serials2.size()>0) {return System.Label.Duplicate_Serial_Numbers_Found;}
            if (serials.size() > 0) {
                List<Serial_Number__c> failedRecords = new List<Serial_Number__c>();
                List<Database.SaveResult> updateResults = Database.update(serials, false);
                Integer counter = 0;
                for (Integer i = 0; i < updateResults.size(); i++) {
                    if (!updateResults.get(i).isSuccess()) {
                        // DML operation failed
                        Database.Error error = updateResults.get(i).getErrors().get(0); failedRecords.add(serials.get(i)); // failed record from the list
                        System.debug('Failed ID' + updateResults.get(i).Id);
                    }
                }
                if (failedRecords.isEmpty()) {
                    return 'Success';
                }
                else{     String failedRecordsMessage = 'Failed to generate the following serial numbers: ';  for (Serial_Number__c failedRecord : failedRecords) {        failedRecordsMessage +=  failedRecord.Name + ', ';     }     failedRecordsMessage += 'as the serial number already exists ';    return failedRecordsMessage;   }
            }
            return null;
        } catch (Exception e) {
            if (e.getMessage().contains('Duplicate') || e.getMessage().contains('duplicate')) {
                return 'Duplicate serial numbers found. Please change the serial start number.';
            } else {
                return 'Error: ' + e.getMessage();
            }
        }
    }
    @AuraEnabled
    public static comWrap DeleteSOLI(String SOLI, String MRPs){
        List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
        Stock_Outward_Line_Item__c mySOLI = [Select Id, Name, Quantity__c,Serial__c from Stock_Outward_Line_Item__c where Id =:SOLI];
        Set<Id> bomserials=new Set<Id>();
		if(mySOLI!=null && mySOLI.Serial__c!=null){  bomserials.add(mySOLI.Serial__c);  }
        List<Serial_Number__c> bomserialstoupdate=new List<Serial_Number__c>();
                        
        mrpWrap mrp = new mrpWrap();
        for(mrpWrap mrpW : mrpWrappers){
            if(mrpW.isSelect) mrp = mrpW;
        }
        comWrap comW = new comWrap();
        comW.errorMsg = '';
        try{
            if(mrp.isSelect){
                if(Stock_Outward_Line_Item__c.sObjectType.getDescribe().isDeletable()) delete mySOLI;
                if(bomserials.size()>0){
                            bomserialstoupdate=[select id, name, available__c, product__c, bom__c, scrap__c from Serial_Number__c where id in: bomserials];
                            if(bomserialstoupdate != null && bomserialstoupdate.size()>0){
                                for(Serial_Number__c ser:bomserialstoupdate ){if(ser.available__c != null && ser.available__c==false){ser.Available__c=true;}}PreventRecursiveLedgerEntry.ProceedSerialsTrigger=false;PreventRecursiveLedgerEntry.ProceedSerialsTriggerValidation=false;
                                List<SObject> safebomserialstoupdate = FLSHelper.getSafeRecords(bomserialstoupdate , 'Serial_Number__c', AccessType.UPDATABLE);
                                List<Serial_Number__c> Typedbomserialstoupdate = new List<Serial_Number__c>();
                                for (SObject SObj : safebomserialstoupdate) {
                                    Typedbomserialstoupdate.add((Serial_Number__c)SObj);
                                }
                                if(!Typedbomserialstoupdate.isEmpty()){
                                    upsert Typedbomserialstoupdate;
                                }
                            }
                        }
                mrp.ActualWeight -= (mySOLI.Quantity__c);
                if(mrp.MRP.Fulfilled_Amount__c >= mySOLI.Quantity__c){ if(Schema.sObjectType.MRP__c.fields.Fulfilled_Amount__c.isUpdateable()){mrp.MRP.Fulfilled_Amount__c -= (mySOLI.Quantity__c*mrp.WeightMultiplier);}else{/*No access*/} }
                else{ if(Schema.sObjectType.MRP__c.fields.Fulfilled_Amount__c.isUpdateable()){mrp.MRP.Fulfilled_Amount__c = 0;}else{/*No access*/} }
                if(mrp.MRP.Fulfilled_Amount__c != mrp.MRP.Total_Amount_Required__c) mrp.MRP.Status__c = 'Requested';
                mrp.Stock += mySOLI.Quantity__c; // Change SM 4
                mrp.MRPQuantity = (mrp.MRP.Total_Amount_Required__c - mrp.MRP.Fulfilled_Amount__c); // change SM 5
                if(Schema.sObjectType.MRP__c.isUpdateable()){update mrp.MRP;}else{/*not allowed to update*/}
                mrp.SOLIs = [Select Id, Name, Active__c, Batch_Lot_Code__c, BOM_Line_Item__c,BOM_Line_Item__r.Quantity__c, Process__c, Schedule__c, MRP_Material_Requirements_Planning__c, BOM__c, Serial__c, Serial__r.Name, MO_WO_Serial__c, MO_WO_Serial__r.Name, MO_WO_Material_Batch_Lot__c, MO_WO_Material_Batch_Lot__r.Name,
                             Product__c, Purchase_Orders__c, Quantity__c, Site_Product_Service_Inventory_Stock__c, Status__c, Tax__c, Total_Amount__c, Unit_Price__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name
                             From Stock_Outward_Line_Item__c Where MRP_Material_Requirements_Planning__c =: mrp.MRP.Id];
                comW.MRPs = mrpWrappers;
                //new code to get updated mo serials after deleting SOLI
                Map<String, Decimal> serialQuantityMap = new Map<String, Decimal>();
                set<String> serialsIds = new set<String> ();
                for(Stock_Outward_Line_Item__c stk : mrp.SOLIs){
                    if (stk.MO_WO_Serial__c != null) {
                        if(!serialQuantityMap.containskey(stk.MO_WO_Serial__c)){
        					serialQuantityMap.put(stk.MO_WO_Serial__c, stk.Quantity__c);
                        }else{
                            serialQuantityMap.put(stk.MO_WO_Serial__c,serialQuantityMap.get(stk.MO_WO_Serial__c)+stk.Quantity__c);
                        }
    				}
                }
                for (Stock_Outward_Line_Item__c stk : mrp.SOLIs) {
    				if (
        					stk.MO_WO_Serial__c != null &&
        					stk.BOM_Line_Item__c != null &&
        					stk.BOM_Line_Item__r.Quantity__c != null
    					) {
        				Decimal actualQty = serialQuantityMap.get(stk.MO_WO_Serial__c);
        				Decimal bomQty = stk.BOM_Line_Item__r.Quantity__c;

        				if (actualQty == bomQty) {
            				serialsIds.add(stk.MO_WO_Serial__c);
        				}
    				}
				}
                //for(Stock_Outward_Line_Item__c stk : mrp.SOLIs) { if(stk.MO_WO_Serial__c != null&& stk.BOM_Line_Item__c!=null && stk.BOM_Line_Item__r.Quantity__c!=null && stk.Quantity__c==stk.BOM_Line_Item__r.Quantity__c) serialsIds.add(stk.MO_WO_Serial__c); }
                List<String> serialsList = new List<String>(serialsIds);
                MRP__c temp=[select Id, name, MO__c  from MRP__c where Id=: mrp.MRP.Id limit 1];
                if(temp!=null && temp.MO__c!=null){comW.moSerialNos = getSerialNumbers(0,temp.MO__c,500,serialsList);}
                //new code end
            }
        } catch(Exception e) { comW.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comW;
    }

    @AuraEnabled
    public static comWrap MRPNewUpdate(string MRP1){
        MRP__c MRP = (MRP__c) JSON.deserialize(MRP1, MRP__c .class);
        comWrap comWrapper = new comWrap();
        try{
            WO__c WO = [Select Id, Name, Process_Cycle__c, BOM__c, Product__c, Work_Center__c From WO__c Where Id =: MRP.Work_Order__c];
            BOM_Line_Item__c BOM = [Select Id, Name, BOM_Component__c From BOM_Line_Item__c Where Id =: MRP.BOM_Line_Item__c];
            if(Schema.sObjectType.MRP__c.fields.Process_Cycle__c.isCreateable() && Schema.sObjectType.MRP__c.fields.Process_Cycle__c.isUpdateable()){MRP.Process_Cycle__c = WO.Process_Cycle__c;}else{/*No access*/}
            if(Schema.sObjectType.MRP__c.fields.Work_Order__c.isCreateable() && Schema.sObjectType.MRP__c.fields.Work_Order__c.isUpdateable()){MRP.Work_Order__c = WO.Id;}else{/*No access*/}
            if(Schema.sObjectType.MRP__c.fields.BOM__c.isCreateable() && Schema.sObjectType.MRP__c.fields.BOM__c.isUpdateable()){MRP.BOM__c = WO.BOM__c;}else{/*No access*/}
            if(Schema.sObjectType.MRP__c.fields.MRP_Product__c.isCreateable() && Schema.sObjectType.MRP__c.fields.MRP_Product__c.isUpdateable()){MRP.MRP_Product__c = BOM.BOM_Component__c;}else{/*No access*/}
            if(Schema.sObjectType.MRP__c.fields.Work_Center__c.isCreateable() && Schema.sObjectType.MRP__c.fields.Work_Center__c.isUpdateable()){MRP.Work_Center__c  = WO.Work_Center__c;}else{/*No access*/}
            if(Schema.sObjectType.MRP__c.isCreateable() && Schema.sObjectType.MRP__c.isUpdateable()){upsert MRP;}else{comWrapper.errorMsg ='not allowed to upsert';}
        } catch(Exception e) { comWrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return comWrapper;
    }

    @AuraEnabled
    public static comWrap GetDefaults(String  proId){
        comWrap comWrapper = new comWrap();
        comWrapper.Product = [Select Id, Name, BOM__c, Routing__c, BOM__r.Name, Routing__r.Name From Product2 Where Id =: proId];
        comWrapper.Routing = new Routing__c(Id=comWrapper.Product.Routing__c, Name=comWrapper.Product.Routing__r.Name);
        comWrapper.Version = new BOM__c(Id=comWrapper.Product.BOM__c, Name=comWrapper.Product.BOM__r.Name);
        return comWrapper;
    }

    @AuraEnabled
    public static comWrap GetRouting(String  routingId){
        comWrap comWrapper = new comWrap();
        comWrapper.Routing = [Select Id, Name, Lead_Time_days__c From Routing__c Where Id =: routingId];
        comWrapper.StartDate = system.today();
        comWrapper.ExpectedDate = system.today()+1;
        if(comWrapper.Routing.Lead_Time_days__c != Null) comWrapper.ExpectedDate = system.today()+Integer.valueof(comWrapper.Routing.Lead_Time_days__c);
        return comWrapper;
    }

    @AuraEnabled
    public static ScanWrap SearchScanCode(String scanCode, String MRPs){
        ScanWrap scanWrapper = new ScanWrap();
        try{
            List<mrpWrap> mrpWrappers = (List<mrpWrap>) JSON.deserialize(MRPs, List<mrpWrap> .class);
            List<Serial_Number__c> SNS = [Select Id, Name, Manufacturing_Order__c, Product__c  From Serial_Number__c Where Barcode__c =: scanCode Limit 1];
            if(SNS.size() > 0) {
                scanWrapper.Serial = SNS[0];
                scanWrapper.substep = 'Serial';
                for(mrpWrap mrrp : mrpWrappers){
                    if(mrrp.isSelect){
                        if(scanWrapper.Serial.Manufacturing_Order__c != Null && scanWrapper.Serial.Manufacturing_Order__c == mrrp.MRP.MO__c) {
                            scanWrapper.step = 'MO';
                        }
                        else if(scanWrapper.Serial.Product__c == mrrp.MRP.MRP_Product__c){
                            scanWrapper.step = 'MRP';
                        }
                    }
                    if(scanWrapper.step != '') break;
                }
            }
            else{
                List<Batch__c> BTS = [Select Id, Name, Manufacturing_Order__c, Product__c  From Batch__c Where Barcode__c =: scanCode Limit 1];
                if(BTS.size() > 0) {
                    scanWrapper.Batch = BTS[0];
                    scanWrapper.substep = 'Batch';
                    for(mrpWrap mrrp : mrpWrappers){
                        if(mrrp.isSelect && scanWrapper.Batch.Manufacturing_Order__c != Null && scanWrapper.Batch.Manufacturing_Order__c == mrrp.MRP.MO__c) {
                            scanWrapper.step = 'MO';
                        }
                        else if(mrrp.isSelect && scanWrapper.Batch.Product__c == mrrp.MRP.MRP_Product__c){
                            scanWrapper.step = 'MRP';
                        }
                        if(scanWrapper.step != '') break;
                    }
                }
            }
        } catch(Exception e) { scanWrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return scanWrapper;
    }

    @AuraEnabled
    public static List<Attachment> GetAttachments(String MOId) {
        comWrap comW = new comWrap();
        List<Attachment> MYATS = [Select Id, Name, ParentId, ContentType, Owner.Name, CreatedDate From Attachment Where ParentId = :MOId And Name = 'Signature' Order By CreatedDate Asc];
        return MYATS;
    }

    @AuraEnabled
    public static comWrap DeleteAT(String RAId, String ObjName){
        comWrap comW = new comWrap();
        String query = 'select Id from ' +String.escapeSingleQuotes(ObjName)+ ' Where Id =:RAId';
        SObject AT = Database.query(query);
        SObjectType sObjType = ((SObject) Type.forName(ObjName).newInstance()).getSObjectType();
        if(Attachment.sObjectType.getDescribe().isDeletable()) { delete AT;}else{/*No access*/}
        return comW;
    }
    @AuraEnabled
    public static List<WIP_Flow__c> getWIPFlows(Integer offsetVal,string Mo){
        List<WIP_Flow__c> wipflows = [Select Id,Name,Product__c,Product__r.Name,BOM__c,BOM__r.Name,Product__r.QuantityUnitOfMeasure,Work_Orders__c,Work_Orders__r.Id,Work_Orders__r.Name,Quantity_Ordered__c,Quantity__c,Quantity_Scrapped__c,WIP__c,WIP__r.Serial_Number__c,WIP__r.Serial_Number__r.Name,WIP__r.Material_Batch_Lot__c,WIP__r.Material_Batch_Lot__r.Name from  WIP_Flow__c where WIP__r.MO__c   = :Mo LIMIT 100 OFFSET :offsetVal];
        return wipflows;
    }
    @AuraEnabled
    public static List<Serial_Number__c> getSerialNumbers(Integer offsetVal,string Mo,Integer limitSer,List<String> SerialIds){
        if(limitSer == null || limitSer == 0) limitSer = 4000;
        if(SerialIds == null) SerialIds = new List<String>();
        List<Serial_Number__c> serialNums= [Select Id,Name,Availability_date__c,Available__c,Barcode__c,Date_of_Manufacture__c,Serial_Number__c,Manufacturing_Order__c,Manufacturing_Order__r.Id,Manufacturing_Order__r.Name from  Serial_Number__c where Manufacturing_Order__c   = :Mo and Id Not In : SerialIds  LIMIT :limitSer OFFSET :offsetVal];
        return serialNums;
    }
    @AuraEnabled
    public static String deleteSelectedMRP(List<String> MRPIds){
        if(MRPIds.size() > 0){
            List<MRP__c> Mrps2Delete = new List<MRP__c>();
            for(String mrpId : MRPIds){
                MRP__c mrp = new MRP__c(Id = mrpId);
                Mrps2Delete.add(mrp);
            }
            if(Mrps2Delete.size() > 0 && MRP__c.sObjectType.getDescribe().isDeletable()) delete Mrps2Delete;//if(Mrps2Delete.size() > 0) delete Mrps2Delete;
            return 'Success';
        }else return null;
    }
    @AuraEnabled
    public static List<ReceivedSILIWrap> getStockinwards(Integer offsetVal,string MoId){
        List<ReceivedSILIWrap> sinwards = new List<ReceivedSILIWrap>();
        String status = 'Quality Check(QA)';
        if(MoId != null && MoId != ''){
            set<Id> prodIds = new set<Id>();
            set<Id> receivedSili = new set<Id>();
            List<Stock_Inward_Line_Item__c> sinwardslist = [Select Id,Name,Product__r.Lot_Tracked__c,Product__r.Serialise__c,Product__r.Quality_Check_QA__c,Serial__c,Serial__r.Name,Material_Batch_Lot__c,Material_Batch_Lot__r.Name,Scrap__c,Status__c,Product__c,Product__r.Name,Quantity__c from Stock_Inward_Line_Item__c where Manufacturing_Order__c = : MoId and Status__c = :status limit 100 OFFSET :offsetVal];
            for(Stock_Inward_Line_Item__c sin : sinwardslist){
                if(sin.Product__c != null) prodIds.add(sin.Product__c);
                receivedSili.add(sin.Id);
            }
            if(prodIds.size() > 0){
                List<Checklist__c> checklists = new List<Checklist__c>();
                checklists = [Select Id,Name,Is_Mandatory__c,Action_Detail__c ,Has_Checklist__c, toLabel(Comply__c), toLabel(Result__c), Notes__c, Product__c
                              from Checklist__c where Product__c != null AND Product__c IN: prodIds AND Product__r.Quality_Check_QA__c = true Order by createdDate asc];
                Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
                if(checklists.size() > 0){
                    Set<Id> checklistIds = new Set<Id>();
                    for(Checklist__c chk: checklists){ checklistIds.add(chk.Id); }
                    userAccessMap = new Map<Id, UserRecordAccess>([SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =:UserInfo.getUserId() AND RecordId IN :checklistIds]);
                }

                List<Guideline_Checklists__c> enteredChecklists = new List<Guideline_Checklists__c>();
                enteredChecklists = [Select Id, Name, Checklist__c,Is_Mandatory__c, Status__c,Instructions__c, Stock_Inward_Line_Item__c, Checklist__r.Is_Mandatory__c, Checklist__r.Action_Detail__c, Checklist__r.Has_Checklist__c,Checklist__r.Name, toLabel(Checklist__r.Comply__c), toLabel(Checklist__r.Result__c), Checklist__r.Product__c,
                                     (Select Id, Name, ParentId from Attachments)
                                     from Guideline_Checklists__c where Stock_Inward_Line_Item__c IN: receivedSili AND Checklist__c != null AND Stock_Inward_Line_Item__c != null];
                Map<String,List<Guideline_Checklists__c>> guideMAp = new Map<String,List<Guideline_Checklists__c>>();
                for(Guideline_Checklists__c guide: enteredChecklists){
                    String key = ''+guide.Stock_Inward_Line_Item__c+guide.Checklist__c;
                    system.debug('key setting~>'+key);
                    if(guideMAp.containsKey(key)) guideMAp.get(key).add(guide);
                    else guideMAp.put(key, new List<Guideline_Checklists__c>{guide});
                }
                for(Stock_Inward_Line_Item__c stinReceived : sinwardslist){
                    ReceivedSILIWrap wrapReceive = new ReceivedSILIWrap();
                    wrapReceive.sili = stinReceived;

                    for(Checklist__c check : checklists){
                        String key = ''+stinReceived.Id+check.Id;
                        system.debug('key checkinghere~>'+key);
                        system.debug('guideMAp.containsKey(key)~>'+guideMAp.containsKey(key));
                        if(guideMAp.containsKey(key)){
                            system.debug('inhere1');
                            wrapReceive.guideline.addAll(guideMAp.get(key));
                            system.debug('wrapReceive.guideline~>'+wrapReceive.guideline.size());
                            for(Guideline_Checklists__c gu : wrapReceive.guideline){
                                if(gu.Checklist__c != null){
                                    UserRecordAccess userAccess = (userAccessMap.containsKey(gu.Checklist__c)) ? userAccessMap.get(gu.Checklist__c) : null;
                                    gu.Name = gu.Checklist__r.Name;
                                    if(gu.Checklist__r.Comply__c != '') gu.Name = gu.Checklist__r.Comply__c;
                                    gu.Is_Mandatory__c = false;
                                    if (userAccess != null){
                                        if(userAccess.HasEditAccess) gu.Is_Mandatory__c = true; //set to true if it has edit access - used to disable picklist/input on UI
                                    }
                                }
                            }
                        }
                        else{
                            if(check.Product__c == stinReceived.Product__c){
                                system.debug('inhere2');
                                UserRecordAccess userAccess = (userAccessMap.containsKey(check.Id)) ? userAccessMap.get(check.Id) : null;                                Guideline_Checklists__c guideChecks = new Guideline_Checklists__c();                                guideChecks.Name = check.Name;                               if(check.Comply__c != '') guideChecks.Name = check.Comply__c;         guideChecks.Checklist__c = check.Id;          guideChecks.Checklist__r = new  Checklist__c(Is_Mandatory__c = check.Is_Mandatory__c,Comply__c = check.Comply__c,Result__c = check.Result__c,Notes__c = check.Notes__c);         guideChecks.Instructions__c = guideChecks.Status__c = check.Has_Checklist__c ? check.Result__c : check.Action_Detail__c;      guideChecks.Stock_Inward_Line_Item__c = stinReceived.Id;   guideChecks.Is_Mandatory__c = false;     if (userAccess != null){         if(userAccess.HasEditAccess) guideChecks.Is_Mandatory__c = true;        }     wrapReceive.guideline.add(guideChecks);
                            }
                        }
                    }
                    sinwards.add(wrapReceive);
                }

            }
        }
        if(sinwards.size() > 0){
            return sinwards;
        }
        else return null;
    }
    @AuraEnabled
    public static string saveAlldetail(String createdsili){
        if(createdsili != null && createdsili != ''){
            List<ReceivedSILIWrap> sili2updateWrap = new List<ReceivedSILIWrap>();
            sili2updateWrap = (List<ReceivedSILIWrap>) JSON.deserialize(createdsili,List<ReceivedSILIWrap>.class);
            List<Stock_Inward_Line_Item__c> sili2update = new List<Stock_Inward_Line_Item__c>();
            List<Guideline_Checklists__c>  guidelines2update = new List<Guideline_Checklists__c>();
            set<Id> QAProdIds = new set<Id>();
            if(sili2updateWrap.size() > 0) {
                for(ReceivedSILIWrap wrap : sili2updateWrap){
                    sili2update.add(wrap.sili);
                    QAProdIds.add(wrap.sili.Product__c);
                    system.debug('sili wrap status : '+wrap.sili.Status__c);
                    if(wrap.guideline != null) guidelines2update.addAll(wrap.guideline);
                }
                 update sili2update;
             }

             if(guidelines2update.size() > 0){
                 List<Checklist__c> checklists = new List<Checklist__c>();
                 checklists = [Select Id,Name,Is_Mandatory__c,Action_Detail__c ,Has_Checklist__c, toLabel(Comply__c), toLabel(Result__c), Notes__c, Product__c
                               from Checklist__c where Product__c != null AND Product__c IN: QAProdIds AND Product__r.Quality_Check_QA__c = true Order by createdDate asc];

                 Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
                 if(checklists.size() > 0){
                     Set<Id> checklistIds = new Set<Id>();
                     for(Checklist__c chk: checklists){ checklistIds.add(chk.Id); }
                     userAccessMap = new Map<Id, UserRecordAccess>([SELECT RecordId, HasEditAccess  FROM UserRecordAccess WHERE UserId =:UserInfo.getUserId() AND RecordId IN :checklistIds]);
                 }
                List<Guideline_Checklists__c> updatedGuidelines = new List<Guideline_Checklists__c>();

                for(Guideline_Checklists__c guide : guidelines2update){
                    if(guide.Checklist__c != null){
                        UserRecordAccess userAccess = (userAccessMap.containsKey(guide.Checklist__c)) ? userAccessMap.get(guide.Checklist__c) : null;
                        if (userAccess != null){
                            if(userAccess.HasEditAccess){
                                if(Schema.sObjectType.Guideline_Checklists__c.fields.Checklist__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Checklist__c.isUpdateable()) guide.Checklist__r = null;
                                if(Schema.sObjectType.Guideline_Checklists__c.fields.Status__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Status__c.isUpdateable())  guide.Status__c = guide.Instructions__c;
                                if(Schema.sObjectType.Guideline_Checklists__c.fields.Is_Mandatory__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Is_Mandatory__c.isUpdateable()) guide.Is_Mandatory__c = false;

                                //guide.Checklist__r = null;
                               // guide.Status__c = guide.Instructions__c;
                               // guide.Is_Mandatory__c = false;
                                //guide.Attachments = null;
                                updatedGuidelines.add(guide);
                            }
                        }
                    }
                }
                                // upsert updatedGuidelines;
                
                 List<SObject> safeupdatedGuidelines = FLSHelper.getSafeRecords(updatedGuidelines, 'Guideline_Checklists__c', AccessType.UPDATABLE);
                 // Now cast back to your object
                 List<Guideline_Checklists__c> TypedupdatedGuidelines = new List<Guideline_Checklists__c>();
                 for (SObject SObj : safeupdatedGuidelines) {
                     TypedupdatedGuidelines.add((Guideline_Checklists__c)SObj);
                 }
                 if(!TypedupdatedGuidelines.isEmpty()){
                     upsert TypedupdatedGuidelines;
                 }
             }
            return 'Success';
        }
        return null;
    }
      @AuraEnabled
    public static List<Attachment> uploadMultipleFilesforQAguideline(String parent, List<String> fileName, List<String> base64Data, List<String> contentType) {
        try{
            List<Attachment> attachments2Insert = new List<Attachment>();
            List<Attachment> Attachments = new List<Attachment>();
            if(String.isNotEmpty(parent)){

                Guideline_Checklists__c guidelines2update = (Guideline_Checklists__c) JSON.deserialize(parent,Guideline_Checklists__c.class);

              if(Schema.sObjectType.Guideline_Checklists__c.fields.Checklist__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Checklist__c.isUpdateable()) guidelines2update.Checklist__r = null;
              if(Schema.sObjectType.Guideline_Checklists__c.fields.Status__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Status__c.isUpdateable())  guidelines2update.Status__c = guidelines2update.Instructions__c;
               if(Schema.sObjectType.Guideline_Checklists__c.fields.Is_Mandatory__c.isCreateable() || Schema.sObjectType.Guideline_Checklists__c.fields.Is_Mandatory__c.isUpdateable()) guidelines2update.Is_Mandatory__c = false;
                //guidelines2update.Attachments = null;

                // upsert guidelines2update;
                List<SObject> safeguidelines2update = FLSHelper.getSafeRecords(new List<Guideline_Checklists__c>{guidelines2update}, 'Guideline_Checklists__c', AccessType.UPDATABLE);
                // Now cast back to your object
                List<Guideline_Checklists__c> Typedguidelines2update = new List<Guideline_Checklists__c>();
                for (SObject SObj : safeguidelines2update) {
                    Typedguidelines2update.add((Guideline_Checklists__c)SObj);
                }
                if(!Typedguidelines2update.isEmpty()){
                    upsert Typedguidelines2update;
                }

                for (Integer i = 0; i < fileName.size(); i++) {
                    base64Data[i] = EncodingUtil.urlDecode(base64Data[i], 'UTF-8');
                    Attachment a = new Attachment(); a.parentId = guidelines2update.Id;  a.Body = EncodingUtil.base64Decode(base64Data[i]); a.Name = fileName[i];  a.ContentType = contentType[i];
                    attachments2Insert.add(a);
                }
                insert attachments2Insert;
                Attachments = [Select Id, Name, ParentId from Attachment where ParentId =:guidelines2update.Id Order By CreatedDate ASC];
            }
            return Attachments;
        }
        catch(Exception e) {
            system.debug('uploadMultipleFilesforQAguideline error : '+e.getMessage()+' Line Number :'+e.getLineNumber());
            /* throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString() ); */
            return null;
        }
    }


    public class ReceivedSILIWrap{
        @AuraEnabled public  Stock_Inward_Line_Item__c sili                                           { get; set; }
        @AuraEnabled public List<Guideline_Checklists__c>  guideline                            { get; set; }
        public ReceivedSILIWrap(){
            sili = new Stock_Inward_Line_Item__c();
            guideline = new List<Guideline_Checklists__c>();
        }
    }
    public class comWrap {
        @AuraEnabled public Boolean ShowCustomSerailNumberGeneration                { get ; set; }
        @AuraEnabled public Manufacturing_Order__c manuOrders                 { get ; set; }
        @AuraEnabled public List<WIP_Flow__c> wipflows                        { get ; set; }
        @AuraEnabled public List<WIP_Flow__c> wipflowsList                        { get ; set; }
        @AuraEnabled public List<mrpWrap> MRPs                                      { get ; set; }
        @AuraEnabled public List<WO__c> WOs                                   { get ; set; }
        @AuraEnabled public List<Stock_Outward_Line_Item__c> SOLIs            { get ; set; }
        @AuraEnabled public List<Stock_Inward_Line_Item__c> SILIs             { get ; set; }
        @AuraEnabled public List< Variance__c > AlternativeBOMs               { get ; set; }
        @AuraEnabled public String errorMsg                                         { get ; set; }
        @AuraEnabled public Boolean isSelect                                        { get ; set; }
        @AuraEnabled public Boolean ReserveStock                                    { get ; set; }
        @AuraEnabled public List<Serial_Number__c> moSerialNos                { get ; set; }
        @AuraEnabled public List<Serial_Number__c> moSerialNosList           { get ; set; }
        @AuraEnabled public List<Batch__c> moBatchNos                         { get ; set; }
        @AuraEnabled public Serial_Number__c SerialNumber2Upsert              { get ; set; }
        @AuraEnabled public Batch__c Batch2Upsert                             { get ; set; }
        @AuraEnabled public Stock_Outward_Line_Item__c NewSOLI                { get ; set; }
        @AuraEnabled public MRP__c NewMRP                                     { get ; set; }
        @AuraEnabled public List<PO__c> POS                                   { get ; set; }
        @AuraEnabled public List<Requisition__c> PRS                          { get ; set; }
        @AuraEnabled public Product2 Product                                        { get ; set; }
        @AuraEnabled public Routing__c Routing                                { get ; set; }
        @AuraEnabled public BOM__c Version                                { get ; set; }
        @AuraEnabled public List<selectOptions> moStatus                            { get ; set; }
        @AuraEnabled public List<UOM_Conversion__mdt> UOMCs                   { get ; set; }
        @AuraEnabled public Date StartDate                                          { get ; set; }
        @AuraEnabled public Date ExpectedDate                                       { get ; set; }
        @AuraEnabled public List<WOWrap> WOWS                                       { get ; set; }
        @AuraEnabled public Attachment Attachment                                   { get ; set; }
        @AuraEnabled public List<Attachment> SelectedAttachments                    { get ; set; }
        @AuraEnabled public Boolean  allowMultiPos                                  { get ; set; }
        @AuraEnabled public Boolean isEditable                                      { get ; set; }
        @AuraEnabled public Boolean showCosts                                       { get ; set; }
        @AuraEnabled public Boolean linksNewOptions                                 { get ; set; }
        @AuraEnabled public Boolean showAutoStockAllocation                         { get ; set; }
        @AuraEnabled public Boolean showManualStockAllocation                       { get ; set; }
        @AuraEnabled public Boolean  isStandardOrder                                { get ; set; }
        @AuraEnabled public Integer totalWips                                       { get ; set; }
        @AuraEnabled public Integer totalSerials                                       { get ; set; }
        @AuraEnabled public Boolean  ShowLangOptionForTraveller                                { get; set; }
        @AuraEnabled public Boolean  ReplaceTravellerOrgURL                                { get; set; }
        @AuraEnabled public Boolean showRequisition                                   { get; set; }
        @AuraEnabled public Integer wipflowsLength                                     { get; set; }
        @AuraEnabled public Integer serialsLength                                     { get; set; }
        @AuraEnabled public Boolean ShowProdStatus                                   { get; set; }
        @AuraEnabled public Boolean showVendorCode                                   { get; set; }
        @AuraEnabled public Boolean showScrapDetails                                     { get; set; }
        @AuraEnabled public Boolean showMOLabels                                         { get; set; }
        @AuraEnabled public Boolean  AllowMRPDelete                                       { get; set; }
        @AuraEnabled public Boolean enableQA										     { get; set; }
        @AuraEnabled public Boolean PreventStatusEdit                                    { get; set; }
        @AuraEnabled public Boolean showUplaodforItems                                              { get; set; }
        @AuraEnabled public Id standardPOId {get;set;}
        public comWrap() {
            serialsLength= 0;
            wipflowsLength= 0;
            showRequisition = true;
            ShowCustomSerailNumberGeneration = showVendorCode = showScrapDetails = showMOLabels = AllowMRPDelete = PreventStatusEdit = enableQA = showUplaodforItems = false;
            isStandardOrder = false;
            totalWips = 0;
            totalSerials = 0;
            manuOrders = new Manufacturing_Order__c(StartDate__c = system.today(), Expected_Date__c = system.today()+1, ExpectedDate__c= system.today()+1);
            wipflows = new List<WIP_Flow__c>();
            wipflowsList = new List<WIP_Flow__c>();
            MRPs = new List<mrpWrap>();
            WOs = new List<WO__c>();
            SOLIs = new List<Stock_Outward_Line_Item__c>();
            SILIs = new List<Stock_Inward_Line_Item__c>();
            AlternativeBOMs = new List<Variance__c>();
            errorMsg = '';
            isSelect = false;
            ReserveStock = false;
            moSerialNos = new List<Serial_Number__c>();
            moSerialNosList = new List<Serial_Number__c>();
            moBatchNos = new List<Batch__c>();
            SerialNumber2Upsert = new Serial_Number__c();
            Batch2Upsert = new Batch__c();
            NewSOLI = new Stock_Outward_Line_Item__c();
            NewMRP = new MRP__c();
            POS = new List<PO__c>();
            PRS = new List<Requisition__c>();
            Product = new Product2();
            moStatus = new List < selectOptions > ();
            UOMCs = new List<UOM_Conversion__mdt>();
            ExpectedDate = system.today()+1;
            StartDate = system.today();
            Routing = new Routing__c();
            Version = new BOM__c();
            WOWS = new List<WOWrap>();
            Attachment = new Attachment();
            SelectedAttachments = new List<Attachment>();
            isEditable = true;
            showCosts = true;
            linksNewOptions = true;
            showAutoStockAllocation = true;
            showManualStockAllocation = true;
            ShowLangOptionForTraveller= false;
            ReplaceTravellerOrgURL= false;
            ShowProdStatus = false;
        }
    }

    public class mrpWrap {
        @AuraEnabled public MRP__c MRP                                        { get ; set; }
        @AuraEnabled public List<MRP__c> MRPs                                 { get ; set; }
        @AuraEnabled public List<Stock_Outward_Line_Item__c> SOLIs            { get ; set; }
        @AuraEnabled public Decimal Stock                                           { get ; set; }
        @AuraEnabled public Decimal Qnty                                            { get ; set; }
        @AuraEnabled public String errorMsg                                         { get ; set; }
        @AuraEnabled public Boolean isSelect                                        { get ; set; }
        @AuraEnabled public String bgColor                                          { get ; set; }
        @AuraEnabled public Manufacturing_Order__c MO                         { get ; set; }
        @AuraEnabled public List<Serial_Number__c> SerialNos                  { get ; set; }
        @AuraEnabled public List<Batch__c> Batches                            { get ; set; }
        @AuraEnabled public Decimal ActualWeight                                    { get ; set; }
        @AuraEnabled public List<selectOptions> UOMS                                { get ; set; }
        @AuraEnabled public String SelectedUOM                                      { get ; set; }
        @AuraEnabled public Decimal WeightMultiplier                                { get ; set; }
        @AuraEnabled public Decimal BOMWeightMultiplier                             { get ; set; }
        @AuraEnabled public Product_Feature__c Feature                        { get ; set; }
        @AuraEnabled public Product2 Product                                        { get ; set; }
        @AuraEnabled public Routing__c Routing                                { get ; set; }
        @AuraEnabled public BOM__c Version                                { get ; set; }
        @AuraEnabled public Decimal oldMRPQty                                       { get ; set; }
        @AuraEnabled public Decimal MRPQuantity                                     { get ; set; }

        public mrpWrap() {
            MRPQuantity = 0;
            MRP = new MRP__c();
            MRPs = new List<MRP__c>();
            Stock = 0;
            Qnty = 0;
            oldMRPQty = 0;
            ActualWeight = 0;
            WeightMultiplier = 1;
            BOMWeightMultiplier = 1;
            errorMsg = '';
            isSelect = false;
            bgColor = '#fff';
            MO = new Manufacturing_Order__c();
            SOLIs = new List<Stock_Outward_Line_Item__c>();
            SerialNos = new List<Serial_Number__c>();
            Batches = new List<Batch__c>();
            UOMS = new List < selectOptions > ();
            SelectedUOM = '';
            Feature = new Product_Feature__c();
            Product = new Product2();
            Routing = new Routing__c();
            Version = new BOM__c();
        }
    }

    public class ScanWrap {
        @AuraEnabled public String step                                             { get ; set; }
        @AuraEnabled public String substep                                          { get ; set; }
        @AuraEnabled public String errorMsg                                         { get ; set; }
        @AuraEnabled public Serial_Number__c Serial                           { get ; set; }
        @AuraEnabled public Batch__c Batch                                    { get ; set; }

        public ScanWrap() {
            step = '';
            substep = '';
            errorMsg = '';
            Serial = new Serial_Number__c();
            Batch = new Batch__c();
        }
    }

    public class selectOptions {
        @AuraEnabled public String label     { get; set; }
        @AuraEnabled public String value     { get; set; }
        @AuraEnabled public Boolean selected { get; set; }

        public selectOptions(String lab, string val) {
            label = lab;
            value = val;
            //selected = false;
        }
        public selectOptions(String lab, string val, Boolean sel) {
            label = lab;
            value = val;
            selected = sel;
        }
    }

    public class WOWrap {
        @AuraEnabled public WO__c WorkOrder                                   { get ; set; }
        @AuraEnabled public List< Time_Card_Entry__c > TimeCardEntries        { get ; set; }
        @AuraEnabled public List<Actions_Tasks__c> Tasks                      { get ; set; }
        @AuraEnabled public List< MRP__c > MRPS                               { get ; set; }
        @AuraEnabled public List<Serial_Number__c> SerialNos                  { get ; set; }
        @AuraEnabled public List<Batch__c> BatchNos                           { get ; set; }
        @AuraEnabled public List< Resource_Allocation__c > RAS                { get ; set; }
        @AuraEnabled public Boolean isSelect                                        { get ; set; }

        public WOWrap() {
            WorkOrder = new WO__c();
            TimeCardEntries= new List< Time_Card_Entry__c >();
            Tasks = new List<Actions_Tasks__c>();
            MRPS = new List< MRP__c >();
            SerialNos = new List<Serial_Number__c>();
            BatchNos = new List<Batch__c>();
            RAS = new List< Resource_Allocation__c >();
            isSelect = false;
        }
    }
     public static final String base64Chars = '' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            'abcdefghijklmnopqrstuvwxyz' +
            '0123456789+/';
        public static String base64ToBits(String validFor) {
            if (String.isEmpty(validFor)) return '';
            String validForBits = '';

            for (Integer i = 0; i < validFor.length(); i++) {
                String thisChar = validFor.mid(i, 1);
                Integer val = base64Chars.indexOf(thisChar);
                String bits = decimalToBinary(val).leftPad(6, '0');
                validForBits += bits;
            }

            return validForBits;
        }
        public static String decimalToBinary(Integer val) {
            String bits = '';
            while (val > 0) {
                Integer remainder = Math.mod(val, 2);
                val = Integer.valueOf(Math.floor(val / 2));
                bits = String.valueOf(remainder) + bits;
            }
            return bits;
        }
    @AuraEnabled
    public static Map<String, List<SelectOptions>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        Map<String,List<SelectOptions>> objResults = new Map<String,List<SelectOptions>>();
        //Map<String,List<String>> objResults = new Map<String,List<String>>();

        Schema.sObjectType objType = objDetail.getSObjectType();
        if (objType==null){  return objResults; }

        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){ return objResults;
                                                                                                   }

        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : contrEntries) {
            String label = ple.getLabel();
            String value = ple.getValue();
            //objResults.put(label, new List<String>());
            //controllingValues.add(label);
            objResults.put(label, new List<SelectOptions>());
            controllingValues.add(label);
        }
        for (PicklistEntryWrapper plew : depEntries) {

            String label = plew.label;
            String value = plew.value;
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    //objResults.get(controllingValues.get(i)).add(label);
                    objResults.get(controllingValues.get(i)).add(new SelectOptions(value,label));
                }
            }
        }
        return objResults;
    }

    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper{

        public String label {get;set;} public String active {get;set;} public String value {get;set;}
        public String validFor {get;set;} public String defaultValue {get;set;}public PicklistEntryWrapper(){
        }


    }
      @AuraEnabled
public static comWrap MRPNewUpdate1(string MRP1){ 
    MRP__c MRP = (MRP__c) JSON.deserialize(MRP1, MRP__c.class);
    comWrap comWrapper = new comWrap();
    try {
        WO__c WO = [Select Id, Name, Process_Cycle__c, BOM__c, Product__c, Work_Center__c, MO__c 
                          From WO__c Where Id =: MRP.Work_Order__c];
        Product2 prod = [Select Id, Name, QuantityUnitOfMeasure From Product2 Where Id =: MRP.MRP_Product__c];
        
        Id bomRecordTypeId = Schema.SObjectType.BOM_Line_Item__c.getRecordTypeInfosByName().get('Manufacturing BOM').getRecordTypeId();

        // Query Routing_Link__c records related to the Process Cycle
        List<Routing_Link__c> routingLinks = [SELECT Id 
                                                   FROM Routing_Link__c 
                                                   WHERE Process_Cycle__c = :WO.Process_Cycle__c 
                                                   LIMIT 1];

        // Select the first Routing_Link__c record, if available
        Id routingLinkId = (routingLinks != null && !routingLinks.isEmpty()) ? routingLinks[0].Id : null;

        if (MRP.Id == null) {
            BOM_Line_Item__c newBOM = new BOM_Line_Item__c();
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Name.isCreateable()) {
                newBOM.Name = prod.Name;
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.BOM_Product__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.BOM_Product__c.isUpdateable()) {
                newBOM.BOM_Product__c = WO.Product__c;
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.BOM_Component__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.BOM_Component__c.isUpdateable()) {
                newBOM.BOM_Component__c = prod.Id;
            }
            
            // FIXED: Set the required parent BOM field
            if (Schema.sObjectType.BOM_Line_Item__c.fields.BOM__c.isCreateable()) {
                newBOM.BOM__c = WO.BOM__c;
            }
            
            newBOM.RecordTypeId = bomRecordTypeId;
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Active__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Active__c.isUpdateable()) {
                newBOM.Active__c = true;
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Type__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Type__c.isUpdateable()) {
                newBOM.Type__c = 'Primary';
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Unit_of_Measure__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Unit_of_Measure__c.isUpdateable()) {
                newBOM.Unit_of_Measure__c = prod.QuantityUnitOfMeasure;
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Process_Cycle__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Process_Cycle__c.isUpdateable()) {
                newBOM.Process_Cycle__c = WO.Process_Cycle__c;
            }
            
            // Set Quantity__c on BOM from user input
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Quantity__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                newBOM.Quantity__c = MRP.Total_Amount_Required__c;
            }
            
            // Set Status__c to 'Certified'
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Status__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Status__c.isUpdateable()) {
                newBOM.Status__c = 'Certified';
            }
            
            // Set Routing_Link__c from queried Routing Link
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Routing_Link__c.isCreateable() && 
                Schema.sObjectType.BOM_Line_Item__c.fields.Routing_Link__c.isUpdateable() && 
                routingLinkId != null) {
                newBOM.Routing_Link__c = routingLinkId;
            }
            
            if (Schema.sObjectType.BOM_Line_Item__c.isCreateable()) {
                insert newBOM;
            } else {
                comWrapper.errorMsg = 'not allowed to create BOM';
            }
            
            if (Schema.sObjectType.MRP__c.fields.BOM_Line_Item__c.isCreateable() && 
                Schema.sObjectType.MRP__c.fields.BOM_Line_Item__c.isUpdateable()) {
                MRP.BOM_Line_Item__c = newBOM.Id;
            }
        } else {
            // Update existing BOM if MRP already exists
            // FIXED: Query the correct parent field
            BOM_Line_Item__c existingBOM = [SELECT Id, Quantity__c, Status__c, Routing_Link__c, BOM__c 
                                            FROM BOM_Line_Item__c WHERE Id = :MRP.BOM_Line_Item__c];
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Quantity__c.isUpdateable()) {
                existingBOM.Quantity__c = MRP.Total_Amount_Required__c;
            }
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Status__c.isUpdateable()) {
                existingBOM.Status__c = 'Certified';
            }
            if (Schema.sObjectType.BOM_Line_Item__c.fields.Routing_Link__c.isUpdateable() && 
                routingLinkId != null) {
                existingBOM.Routing_Link__c = routingLinkId;
            }
            // FIXED: Optionally sync parent BOM if needed
            if (Schema.sObjectType.BOM_Line_Item__c.fields.BOM__c.isUpdateable() && WO.BOM__c != null) {
                existingBOM.BOM__c = WO.BOM__c;
            }
            update existingBOM;
        }

        // Fetch MO to get Quantity__c
        Manufacturing_Order__c mo = [SELECT Quantity__c FROM Manufacturing_Order__c WHERE Id = :WO.MO__c LIMIT 1];
        
        // Calculate Total_Amount_Required__c for MRP
        if (Schema.sObjectType.MRP__c.fields.Total_Amount_Required__c.isCreateable() && 
            Schema.sObjectType.MRP__c.fields.Total_Amount_Required__c.isUpdateable()) {
            Decimal bomQuantity = MRP.Total_Amount_Required__c; // This is the user input now stored in BOM
            Decimal moQuantity = mo.Quantity__c != null ? mo.Quantity__c : 0;
            MRP.Total_Amount_Required__c = bomQuantity * moQuantity;
        }

        if(Schema.sObjectType.MRP__c.fields.Process_Cycle__c.isCreateable() && 
           Schema.sObjectType.MRP__c.fields.Process_Cycle__c.isUpdateable()) {
            MRP.Process_Cycle__c = WO.Process_Cycle__c;
        }
        if(Schema.sObjectType.MRP__c.fields.Name.isCreateable() && 
           Schema.sObjectType.MRP__c.fields.Name.isUpdateable()) {
            MRP.Name = prod.Name;
        }
        if(Schema.sObjectType.MRP__c.fields.BOM__c.isCreateable() && 
           Schema.sObjectType.MRP__c.fields.BOM__c.isUpdateable()) {
            MRP.BOM__c = WO.BOM__c;
        }
        if(Schema.sObjectType.MRP__c.fields.MRP_Product__c.isCreateable() && 
           Schema.sObjectType.MRP__c.fields.MRP_Product__c.isUpdateable()) {
            MRP.MRP_Product__c = prod.Id;
        }
        if(Schema.sObjectType.MRP__c.fields.Work_Center__c.isCreateable() && 
           Schema.sObjectType.MRP__c.fields.Work_Center__c.isUpdateable()) {
            MRP.Work_Center__c = WO.Work_Center__c;
        }

        // Set MRP Status to 'Requested' when created
        if (MRP.Id == null) {
            if (Schema.sObjectType.MRP__c.fields.Status__c.isCreateable() && 
                Schema.sObjectType.MRP__c.fields.Status__c.isUpdateable()) {
                MRP.Status__c = 'Requested';
            }
        }

        // Set BOM unit price from BOM_Line_Item__c Cost_Price__c or Cost_Card__c.Cost_Price__c
        if (MRP.BOM_Line_Item__c != null) {
            BOM_Line_Item__c bomItem = [SELECT Cost_Price__c, Cost_Card__c FROM BOM_Line_Item__c WHERE Id = :MRP.BOM_Line_Item__c LIMIT 1];
            Decimal unitPrice = bomItem.Cost_Price__c;
           // if (unitPrice == null && bomItem.Cost_Card__c != null) {
           //     Cost_Card__c costCard = [SELECT Cost_Price__c FROM Cost_Card__c WHERE Id = :bomItem.Cost_Card__c LIMIT 1];
           //     unitPrice = costCard.Cost_Price__c;
           // }
            if (Schema.sObjectType.MRP__c.fields.BOM_unit_Price__c.isCreateable() && 
                Schema.sObjectType.MRP__c.fields.BOM_unit_Price__c.isUpdateable()) {
                MRP.BOM_unit_Price__c = 0.00;
            }
        }
        
        if(Schema.sObjectType.MRP__c.isCreateable() && Schema.sObjectType.MRP__c.isUpdateable()) {
            upsert MRP;
        } else {
            comWrapper.errorMsg = 'not allowed to upsert';
        }
    } catch(Exception e) { 
        comWrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); 
    }
    return comWrapper;
}
}