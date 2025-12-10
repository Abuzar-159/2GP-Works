global with sharing class OrderTrigger{
  // global static void ManagePurchaseOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1){  //     List<PO__c> Trigger_New = (List<PO__c>)JSON.deserialize(Trigger_New1, List<PO__c>.class);//     List<PO__c> Trigger_Old = (List<PO__c>)JSON.deserialize(Trigger_Old1, List<PO__c>.class);//     List<Id> POIds = new List<Id>();//     List<Id> poliIds = new List<Id>();//     List<Logistic__c> logistics2upsert = new List<Logistic__c>();//     List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();//     List<Purchase_Line_Items__c> POLI2upsert = new List<Purchase_Line_Items__c>();//     List<Purchase_Line_Items__c> poliS = new List<Purchase_Line_Items__c>();//     List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();//     List<List<Stock_Outward_Line_Item__c>> loliOutwards = new List<List<Stock_Outward_Line_Item__c>>();//     List<Logistic_Line_Item__c> AllTheLolis = new List<Logistic_Line_Item__c>();//     List<Logistic__c> existingLogistics = new List<Logistic__c>();
  //     Map<Id, PO__c> POMapOutbound = new Map<Id, PO__c>();
  //     Map<Id, PO__c> POMapInbound = new Map<Id, PO__c>();
  //     Map<Id, Logistic__c> existingLogisticMapOutbound = new Map<Id, Logistic__c>();
  //     Map<Id, Logistic__c> existingLogisticMapInbound = new Map<Id, Logistic__c>();
  //     Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
  //     Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();
  //     String PORecTypeId = Schema.SObjectType.Logistic__c.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
  //     String Reserved = 'Reserved';
  //     String ReturnStat = 'Returned to Supplier';
  //     String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
  //     UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
  //     String poliFields = UtilClass.selectStarFromSObject('Purchase_Line_Items__c');
  //     UtilClass.FLSCheck(poliFields.split(','), 'Purchase_Line_Items__c');
  //     if (Trigger.IsAfter && Trigger_IsUpdate && Schema.sObjectType.Logistic__c.isAccessible()){
  //         List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Active__c, Primary__c, Channel__c, Site__c, Site__r.Name
  //                                                               From Distribution_Channel__c
  //                                                               Where Active__c = true
  //                                                               WITH SECURITY_ENFORCED
  //                                                               Order By Priority__c Desc
  //                                                               limit 100];
  //         for (Distribution_Channel__c DC : DistributionChannels){
  //             String DCId = DC.Site__c + '' + DC.Channel__c;
  //             siteDistribution.put(DCId, DC);
  //         }
  //         for (Integer i = 0; i < trigger_New.size(); i++){
  //             if (trigger_New[i].Ready_To_Pick_Pack__c || (trigger_New[i].Ready_To_Receive__c && trigger_New[i].Logistic_Created__c == false)){
  //                 POIds.add(trigger_New[i].Id);
  //             }
  //         }
  //         if (POIds.size() > 0)
  //             existingLogistics = [Select Id, Name, Type__c, Purchase_Order__c
  //                                  From Logistic__c
  //                                  Where Purchase_Order__c In:POIds
  //                                  WITH SECURITY_ENFORCED
  //                                  limit 100];
  //         for (Logistic__c Log : existingLogistics){
  //             if (Log.Type__c == 'Outbound') existingLogisticMapOutbound.put(Log.Purchase_Order__c, Log);
  //             else if (Log.Type__c == 'Inbound')
  //                 existingLogisticMapInbound.put(Log.Purchase_Order__c, Log);
  //         }
  //         for (Integer i = 0; i < trigger_New.size(); i++){
  //             if (trigger_New[i].Ready_To_Pick_Pack__c && !existingLogisticMapOutbound.containsKey(trigger_New[i].Id)){
  //                 POMapOutbound.put(trigger_New[i].Id, trigger_New[i]);
  //             }
  //             if (trigger_New[i].Ready_To_Receive__c && trigger_New[i].Logistic_Created__c == false && !existingLogisticMapInbound.containsKey(trigger_New[i].Id)){
  //                 POMapInbound.put(trigger_New[i].Id, trigger_New[i]);
  //             }
  //         }
  //         // Outbound Logistics and Lines Creation
  //         if (POMapOutbound.Values().size() > 0){
  //             Set<Id> orderIds = POMapOutbound.keySet();Map<Id, List<Purchase_Line_Items__c>> PO_Polis_Map = new Map<Id, List<Purchase_Line_Items__c>>();Map<Id, List<Stock_Outward_Line_Item__c>> polis_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
  //             polis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Purchase_Line_Items__c where (Purchase_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true)) WITH SECURITY_ENFORCED limit 100');
  //             pplis = Database.query('select ' + String.escapeSingleQuotes(PPLIFields) + ', Fixed_Asset__r.Product__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Purchase_Line_Items__r.Purchase_Orders__c from Stock_Outward_Line_Item__c where Purchase_Orders__c In: orderIds and (Status__c  = :Reserved Or Status__c = :ReturnStat) and Quantity__c > 0 WITH SECURITY_ENFORCED Order By Purchase_Orders__c Asc limit 100');
  //             for (Purchase_Line_Items__c POLI : POLIS){
  //                 if (PO_Polis_Map == Null)
  //                     PO_Polis_Map.put(POLI.Purchase_Orders__c, new List<Purchase_Line_Items__c>());
  //                 if (PO_Polis_Map.containsKey(POLI.Purchase_Orders__c)){
  //                     PO_Polis_Map.get(POLI.Purchase_Orders__c).add(POLI);
  //                 } else{
  //                     List<Purchase_Line_Items__c> myPOLI = new List<Purchase_Line_Items__c>();
  //                     myPOLI.add(POLI);
  //                     PO_Polis_Map.put(POLI.Purchase_Orders__c, myPOLI);
  //                 }
  //                 polis_PPLI_Map.put(POLI.Id, new List<Stock_Outward_Line_Item__c>());
  //             }
  //             for (Stock_Outward_Line_Item__c ppli : pplis){
  //                 if (polis_PPLI_Map.containsKey(ppli.Purchase_Line_Items__c))
  //                     polis_PPLI_Map.get(ppli.Purchase_Line_Items__c).add(ppli);
  //                 else{
  //                     List<Stock_Outward_Line_Item__c> myPPLI = new List<Stock_Outward_Line_Item__c>();                        myPPLI.add(ppli);                        polis_PPLI_Map.put(ppli.Purchase_Line_Items__c, myPPLI);
  //                 }
  //             }
  //             for (PO__c SO : POMapOutbound.Values()){
  //                 Set<Id> mySites = new Set<Id>();
  //                 if (PO_Polis_Map.containsKey(SO.Id)){
  //                     for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
  //                         for (Stock_Outward_Line_Item__c ppli : polis_PPLI_Map.get(poli.Id))
  //                             mySites.add(ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c);
  //                     }
  //                     Integer i = 1;
  //                     for (Id siteId : mySites){
  //                         String DCId = siteId + '' + SO.Channel__c;
  //                         Logistic__c Logistic = new Logistic__c(Name = SO.Name + '-Logistic-' + String.valueof(i), Type__c = 'Outbound', Account__c = SO.Vendor__c, Contact__c = SO.Vendor_Contact__c, Company__c= SO.Company__c, Purchase_Order__c = SO.Id, Active__c = true, Channel__c = SO.Channel__c, To_Address__c = SO.Vendor_Address__c, From_Address__c = SO.Delivery_Address__c, RecordTypeId = PORecTypeId, Distribution_Channel__c = siteDistribution.get(DCId).Id);
  //                         Logistic.Shipment_type__c = SO.Shipment_type__c;Logistic.Shipping_Preferences__c = SO.Shipment_Preference_Speed__c;
  //                         List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();i++;
  //                         Integer j = 1;
  //                         for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
  //                             string name = poli.Name + '-LogisticLine-' + String.valueof(j);
  //                             if (name.Length() >= 80){ name = name.substring(0, 60) + '-LogisticLine-' + String.valueof(j);
  //                             }
  //                             Logistic_Line_Item__c loli = new Logistic_Line_Item__c( Name = name, Product__c = POLI.Product__c, Purchase_Line_Items__c = POLI.Id, Quantity__c = 0,  Explode__c = POLI.Explode__c, Price_Product__c = POLI.Unit_Price__c, Status__c = 'Reserved');  // Price_Product__c = POLI.Total_Price__c We should be considering Unit Price
  //                             List<Stock_Outward_Line_Item__c> myOutwards = new List<Stock_Outward_Line_Item__c>();
  //                             for (Stock_Outward_Line_Item__c ppli : polis_PPLI_Map.get(poli.Id)){
  //                                 if (siteId == ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c){
  //                                     loli.Quantity__c += ppli.Quantity__c;myOutwards.add(ppli);
  //                                 }
  //                             }
  //                             if (loli.Quantity__c > 0){
  //                                 myLines.add(loli);AllTheLolis.add(loli);loliOutwards.add(myOutwards);j++;
  //                             }
  //                         }
  //                         if (myLines.size() > 0)
  //                             logAndLine.put(Logistic, myLines);
  //                     }
  //                 }
  //             }
  //         }
  //         // Inbound Logistics and Lines Creation
  //         if (POMapInbound.Values().size() > 0){
  //             Map<Id, List<Purchase_Line_Items__c>> PO_Polis_Map = new Map<Id, List<Purchase_Line_Items__c>>();
  //             Set<Id> orderIds = POMapInbound.keySet();
  //             polis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + '  from Purchase_Line_Items__c where (Purchase_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true)) WITH SECURITY_ENFORCED limit 100');
  //             for (Purchase_Line_Items__c POLI : POLIS){
  //                 if (PO_Polis_Map == Null)
  //                     PO_Polis_Map.put(POLI.Purchase_Orders__c, new List<Purchase_Line_Items__c>());
  //                 if (PO_Polis_Map.containsKey(POLI.Purchase_Orders__c))
  //                     PO_Polis_Map.get(POLI.Purchase_Orders__c).add(POLI);
  //                 else{
  //                     List<Purchase_Line_Items__c> myPOLI = new List<Purchase_Line_Items__c>();
  //                     myPOLI.add(POLI);
  //                     PO_Polis_Map.put(POLI.Purchase_Orders__c, myPOLI);
  //                 }
  //             }
  //             for (PO__c SO : POMapInbound.Values()){
  //                 if (PO_Polis_Map.containsKey(SO.Id)){
  //                     Logistic__c Logistic = new Logistic__c(
  //                         Name = SO.Name + '-Logistic',
  //                         Type__c = 'Inbound',
  //                         Account__c = SO.Vendor__c,
  //                         Contact__c = SO.Vendor_Contact__c,
  //                          Company__c= SO.Company__c,
  //                         Purchase_Order__c = SO.Id,
  //                         Active__c = true,
  //                         Channel__c = SO.Channel__c,
  //                         To_Address__c = SO.Delivery_Address__c,
  //                         From_Address__c = SO.Vendor_Address__c,
  //                         RecordTypeId = PORecTypeId,
  //                         Distribution_Channel__c = SO.Distribution_Channel__c
  //                     );
  //                     if (Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isUpdateable())
  //                         Logistic.Shipment_type__c = SO.Shipment_type__c;
  //                     if (Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isUpdateable())
  //                         Logistic.Shipping_Preferences__c = SO.Shipment_Preference_Speed__c;
  //                     List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();
  //                     Integer j = 1;
  //                     for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
  //                         poli.Logistic_Quantity__c = poli.Quantity__c;
  //                          POLI2upsert.add(poli);
  //                         string name = poli.Name + '-LogisticLine-' + String.valueof(j);
  //                         if (name.Length() >= 80){
  //                             name = name.substring(0, 60) + '-LogisticLine-' + String.valueof(j);
  //                         }
  //                         Logistic_Line_Item__c loli = new Logistic_Line_Item__c(
  //                             Name = name,
  //                             Product__c = POLI.Product__c,
  //                             Purchase_Line_Items__c = POLI.Id,
  //                             Explode__c = POLI.Explode__c,
  //                             Price_Product__c = POLI.Unit_Price__c,
  //                             Status__c = 'Reserved',
  //                             Quantity__c = poli.Quantity__c
  //                         );  //// Price_Product__c = POLI.Total_Price__c We should be considering Unit Price
  //                         myLines.add(loli);
  //                         j++;
  //                     }
  //                     if (myLines.size() > 0)
  //                         logAndLine.put(Logistic, myLines);
  //                 }
  //             }
  //         }
  //         if (logAndLine.keySet().size() > 0){
  //             logistics2upsert.addAll(logAndLine.keySet());
  //             if (Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Purchase_Order__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Purchase_Order__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipping_Preferences__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isUpdateable()){
  //                 upsert logistics2upsert;
  //             } else{
  //                 /*not allowed*/
  //             }
  //             Integer j = 0;
  //             for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){
  //                 for (Logistic_Line_Item__c loli : allLolis)
  //                     loli.Logistic__c = logistics2upsert[j].Id;
  //                 logisticsLines2upsert.addAll(allLolis);
  //                 j++;
  //             }
  //             if (logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){
  //                 //upsert logisticsLines2upsert;
  //                 List<Logistic_Line_Item__c> loglineToUpsert = (List<Logistic_Line_Item__c>)Security.stripInaccessible(AccessType.UPSERTABLE, logisticsLines2upsert).getRecords();
  //                 if (!loglineToUpsert.isEmpty()) {
  //                     if(Schema.sObjectType.Logistic_Line_Item__c.IsCreateable() && Schema.sObjectType.Logistic_Line_Item__c.IsUpdateable()){
  //                         upsert loglineToUpsert;
  //                     }
  //                 }
  //             } else{
  //                 /*no allwed*/
  //             }
  //             List<Stock_Outward_Line_Item__c> allOutwards = new List<Stock_Outward_Line_Item__c>();
  //             for (Integer x = 0; x < AllTheLolis.size(); x++){
  //                 for (Stock_Outward_Line_Item__c mySOLI : loliOutwards[x]){
  //                     if (AllTheLolis[x].Id != null){ mySOLI.Logistic_Line_Item__c = AllTheLolis[x].Id;
  //                     }
  //                     if (mySOLI.Status__c == 'Returned to Supplier'){ mySOLI.Status__c = '    Reserved';
  //                     }
  //                     allOutwards.add(mySOLI);
  //                 }
  //             }
  //             if (POLI2upsert.size() > 0 && Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isCreateable() && Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isUpdateable()){
  //                 upsert POLI2upsert;
  //             } else{
  //                  /*not allowed*/
  //             }
  //             if (allOutwards.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Logistic_Line_Item__c.isUpdateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){
  //                 update allOutwards;
  //             } else{
  //                 /*not allwed*/
  //             }
  //         }
  //     }
  // }
  // changed by matheen bcz for GIIH 625
  global static void ManagePurchaseOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1){
    system.debug('ManagePurchaseOrderLogistics called');
    List<PO__c> Trigger_New = (List<PO__c>)JSON.deserialize(Trigger_New1, List<PO__c>.class);
    List<PO__c> Trigger_Old = (List<PO__c>)JSON.deserialize(Trigger_Old1, List<PO__c>.class);
    List<Id> POIds = new List<Id>();
    List<Id> poliIds = new List<Id>();
    List<Logistic__c> logistics2upsert = new List<Logistic__c>();
    List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();
    List<Purchase_Line_Items__c> POLI2upsert = new List<Purchase_Line_Items__c>();
    List<Purchase_Line_Items__c> poliS = new List<Purchase_Line_Items__c>();
      List<Id> polisToUpdate = new List<Id>();List<Purchase_Line_Items__c> polisToUpdateList = new List<Purchase_Line_Items__c>();List<Id> poIdList2 = new List<Id>();
    List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
    List<List<Stock_Outward_Line_Item__c>> loliOutwards = new List<List<Stock_Outward_Line_Item__c>>();
    List<Logistic_Line_Item__c> AllTheLolis = new List<Logistic_Line_Item__c>();
    List<Logistic__c> existingLogistics = new List<Logistic__c>();

    Map<Id, PO__c> POMapOutbound = new Map<Id, PO__c>();
    Map<Id, PO__c> POMapInbound = new Map<Id, PO__c>();
    Map<Id, Logistic__c> existingLogisticMapOutbound = new Map<Id, Logistic__c>();
    Map<Id, Logistic__c> existingLogisticMapInbound = new Map<Id, Logistic__c>();
    Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
    Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();

    String PORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c', 'Purchase_Order');
    String Reserved = 'Reserved';
    String ReturnStat = 'Returned to Supplier';
    String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
    UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
    String poliFields = UtilClass.selectStarFromSObject('Purchase_Line_Items__c');
    UtilClass.FLSCheck(poliFields.split(','), 'Purchase_Line_Items__c');

    if (Trigger.IsAfter && Trigger_IsUpdate && Schema.sObjectType.Logistic__c.isAccessible()){
      List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Active__c, Primary__c, Channel__c, Site__c, Site__r.Name,Site__r.Primary_Contact__c
                                                            From Distribution_Channel__c
                                                            Where Active__c = true
                                                            Order By Priority__c Desc];
      for (Distribution_Channel__c DC : DistributionChannels){
        String DCId = DC.Site__c + '' + DC.Channel__c;
        siteDistribution.put(DCId, DC);
      }
      for (Integer i = 0; i < trigger_New.size(); i++){
        system.debug('trigger_New[i].Ready_To_Pick_Pack__c : ' + trigger_New[i].Ready_To_Pick_Pack__c);
        system.debug('trigger_New[i].Ready_To_Receive__c : ' + trigger_New[i].Ready_To_Receive__c);
        system.debug('trigger_New[i].Logistic_Created__ : ' + trigger_New[i].Logistic_Created__c);
        System.debug('trigger_New[i].Ready_To_Receive__c : ' + trigger_New[i].Ready_To_Receive__c);
        System.debug('trigger_New[i].logistic_created__c :'+trigger_New[i].Logistic_Created__c);
        if (trigger_New[i].Ready_To_Pick_Pack__c || (trigger_New[i].Ready_To_Receive__c && trigger_New[i].Logistic_Created__c == false)){
          System.debug('Adding POId : ' + trigger_New[i].Id);
          POIds.add(trigger_New[i].Id);
        }
          if(trigger_New[i].Ready_To_Pick_Pack__c && Trigger_Old[i].Ready_To_Pick_Pack__c==false){
              poIdList2.add(trigger_New[i].Id);
          }
      }
        system.debug('poIdList2 : ' + poIdList2);
        if(poIdList2.size()>0){
            polisToUpdateList=[Select id from Purchase_Line_Items__c where Purchase_Orders__c in:poIdList2];
            if(polisToUpdateList.size()>0){
                upsert polisToUpdateList;
            }
        }
      system.debug('POIds : ' + POIds);
      if (POIds.size() > 0)
        existingLogistics = [Select Id, Name, Type__c, Purchase_Order__c
                             From Logistic__c
                             Where Purchase_Order__c In:POIds];
      for (Logistic__c Log : existingLogistics){
        if (Log.Type__c == 'Outbound')
          existingLogisticMapOutbound.put(Log.Purchase_Order__c, Log);
        else if (Log.Type__c == 'Inbound')
          existingLogisticMapInbound.put(Log.Purchase_Order__c, Log);
          system.debug('existingLogisticMapOutbound : ' + existingLogisticMapOutbound);
      }

      for (Integer i = 0; i < trigger_New.size(); i++){
        if (trigger_New[i].Ready_To_Pick_Pack__c && !existingLogisticMapOutbound.containsKey(trigger_New[i].Id)){
          POMapOutbound.put(trigger_New[i].Id, trigger_New[i]);
        }
        System.debug('existingLogisticMapInbound.containsKey(trigger_New[i].Id) : ' + existingLogisticMapInbound.containsKey(trigger_New[i].Id));
        if (trigger_New[i].Ready_To_Receive__c && trigger_New[i].Logistic_Created__c == false && !existingLogisticMapInbound.containsKey(trigger_New[i].Id)){
          System.debug('Adding POMapInbound : ' + trigger_New[i].Id);
          POMapInbound.put(trigger_New[i].Id, trigger_New[i]);
        }
      }
      system.debug('POMapInbound : ' + POMapInbound.Values().size());
      // Outbound Logistics and Lines Creation
      if (POMapOutbound.Values().size() > 0){
        Set<Id> orderIds = POMapOutbound.keySet();
        Map<Id, List<Purchase_Line_Items__c>> PO_Polis_Map = new Map<Id, List<Purchase_Line_Items__c>>();
        Map<Id, List<Stock_Outward_Line_Item__c>> polis_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();

        polis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Purchase_Line_Items__c where (Purchase_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');
        pplis = Database.query('select ' + String.escapeSingleQuotes(PPLIFields) + ', Fixed_Asset__r.Product__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Purchase_Line_Items__r.Purchase_Orders__c from Stock_Outward_Line_Item__c where Purchase_Orders__c In: orderIds and (Status__c  = :Reserved Or Status__c = :ReturnStat) and Quantity__c > 0 Order By Purchase_Orders__c Asc');

        for (Purchase_Line_Items__c POLI : POLIS){
          if (PO_Polis_Map == Null)
            PO_Polis_Map.put(POLI.Purchase_Orders__c, new List<Purchase_Line_Items__c>());
          if (PO_Polis_Map.containsKey(POLI.Purchase_Orders__c)){
            PO_Polis_Map.get(POLI.Purchase_Orders__c).add(POLI);
          } else{
            List<Purchase_Line_Items__c> myPOLI = new List<Purchase_Line_Items__c>();
            myPOLI.add(POLI);
            PO_Polis_Map.put(POLI.Purchase_Orders__c, myPOLI);
          }
          polis_PPLI_Map.put(POLI.Id, new List<Stock_Outward_Line_Item__c>());
        }

        for (Stock_Outward_Line_Item__c ppli : pplis){
          if (polis_PPLI_Map.containsKey(ppli.Purchase_Line_Items__c))
            polis_PPLI_Map.get(ppli.Purchase_Line_Items__c).add(ppli);
          else{
            List<Stock_Outward_Line_Item__c> myPPLI = new List<Stock_Outward_Line_Item__c>();	 myPPLI.add(ppli);	polis_PPLI_Map.put(ppli.Purchase_Line_Items__c, myPPLI);
          }
        }

        for (PO__c SO : POMapOutbound.Values()){
          Set<Id> mySites = new Set<Id>();
          if (PO_Polis_Map.containsKey(SO.Id)){
            for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
              for (Stock_Outward_Line_Item__c ppli : polis_PPLI_Map.get(poli.Id))
                mySites.add(ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c);
            }
            Integer i = 1;
            for (Id siteId : mySites){
              String DCId = siteId + '' + SO.Channel__c;
              System.debug('setting from contact');
              System.debug('SO.Delivery_Address_r.Contact__c : ' + SO.Delivery_Address__r.Contact__c);
              Logistic__c Logistic = new Logistic__c( Name = SO.Name + '-Logistic-' + String.valueof(i),	Type__c = 'Outbound',	Account__c = SO.Vendor__c,	 Contact__c = SO.Vendor_Contact__c,	Purchase_Order__c = SO.Id,	Active__c = true,	 Channel__c = SO.Channel__c,	To_Address__c = SO.Vendor_Address__c,	 From_Address__c = SO.Delivery_Address__c, From_Contact__c = ((siteDistribution.get(DCId) != null) ? siteDistribution.get(DCId).Site__r.Primary_Contact__c : null),	RecordTypeId = PORecTypeId,	Distribution_Channel__c = siteDistribution.get(DCId).Id
              );
              Logistic.Shipment_type__c = SO.Shipment_type__c;	Logistic.Shipping_Preferences__c = SO.Shipment_Preference_Speed__c;
              List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();
              i++;
              Integer j = 1;
              for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
                string name = poli.Name + '-LogisticLine-' + String.valueof(j);
                system.debug('name length : ' + name.length() + 'name : ' + name);
                if (name.Length() >= 80){ name = name.substring(0, 60) + '-LogisticLine-' + String.valueof(j);
                }
                Logistic_Line_Item__c loli = new Logistic_Line_Item__c( Name = name, Product__c = POLI.Product__c,Purchase_Line_Items__c = POLI.Id, Quantity__c = 0, Explode__c = POLI.Explode__c, Price_Product__c = POLI.Unit_Price__c,Status__c = 'Reserved'
                );  // Price_Product__c = POLI.Total_Price__c We should be considering Unit Price
                List<Stock_Outward_Line_Item__c> myOutwards = new List<Stock_Outward_Line_Item__c>();
                for (Stock_Outward_Line_Item__c ppli : polis_PPLI_Map.get(poli.Id)){
                  if (siteId == ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c){	loli.Quantity__c += ppli.Quantity__c;myOutwards.add(ppli);
                  }
                }
                if (loli.Quantity__c > 0){	myLines.add(loli);	AllTheLolis.add(loli);	 loliOutwards.add(myOutwards);	j++;
                }
              }
              if (myLines.size() > 0)
                logAndLine.put(Logistic, myLines);
            }
          }
        }
      }
      // Inbound Logistics and Lines Creation
      if (POMapInbound.Values().size() > 0){
        Map<Id, List<Purchase_Line_Items__c>> PO_Polis_Map = new Map<Id, List<Purchase_Line_Items__c>>();
        Set<Id> orderIds = POMapInbound.keySet();
        polis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Purchase_Line_Items__c where (Purchase_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');

        for (Purchase_Line_Items__c POLI : POLIS){
          if (PO_Polis_Map == Null)
            PO_Polis_Map.put(POLI.Purchase_Orders__c, new List<Purchase_Line_Items__c>());
          if (PO_Polis_Map.containsKey(POLI.Purchase_Orders__c))
            PO_Polis_Map.get(POLI.Purchase_Orders__c).add(POLI);
          else{
            List<Purchase_Line_Items__c> myPOLI = new List<Purchase_Line_Items__c>();
            myPOLI.add(POLI);
            PO_Polis_Map.put(POLI.Purchase_Orders__c, myPOLI);
          }
        }

        for (PO__c SO : POMapInbound.Values()){
          if (PO_Polis_Map.containsKey(SO.Id)){
            Logistic__c Logistic = new Logistic__c(
              Name = SO.Code__c!=null?'PO-'+SO.Code__c + '-Logistic':SO.Name + '-Logistic',
              Type__c = 'Inbound',
              Account__c = SO.Vendor__c,
              Contact__c = SO.Vendor_Contact__c,
              Purchase_Order__c = SO.Id,
              Active__c = true,
              Channel__c = SO.Channel__c,
              To_Address__c = SO.Delivery_Address__c,
              From_Address__c = SO.Vendor_Address__c,
              RecordTypeId = PORecTypeId,
              Distribution_Channel__c = SO.Distribution_Channel__c
            );

            Logistic.Shipment_type__c = SO.Shipment_type__c;
            Logistic.Shipping_Preferences__c = SO.Shipment_Preference_Speed__c;

            List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();
            Integer j = 1;

            for (Purchase_Line_Items__c poli : PO_Polis_Map.get(SO.Id)){
              poli.Logistic_Quantity__c = poli.Quantity__c;
              POLI2upsert.add(poli);
              string name = poli.Name + '-LogisticLine-' + String.valueof(j);
              system.debug('name length : ' + name.length() + 'name : ' + name);
              if (name.Length() >= 80){	name = name.substring(0, 60) + '-LogisticLine-' + String.valueof(j);
                system.debug('name : ' + name);
                system.debug('name length : ' + name.length());
              }
              Logistic_Line_Item__c loli = new Logistic_Line_Item__c(
                Name = name,
                Product__c = POLI.Product__c,
                Purchase_Line_Items__c = POLI.Id,
                Explode__c = POLI.Explode__c,
                Price_Product__c = POLI.Unit_Price__c,
                Status__c = 'Reserved',
                Quantity__c = poli.Quantity__c
              );  //// Price_Product__c = POLI.Total_Price__c We should be considering Unit Price
              myLines.add(loli);
              j++;

            }
            if (myLines.size() > 0)
              logAndLine.put(Logistic, myLines);
          }
        }
      }
      List<Logistic__c> typelogistics2upsert = new List<Logistic__c>();
      if (logAndLine.keySet().size() > 0){
        logistics2upsert.addAll(logAndLine.keySet());
        if (Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Purchase_Order__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Purchase_Order__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable()){
          // upsert logistics2upsert;
          List<SObject> safelogistics2upsert = FLSHelper.getSafeRecords(
              logistics2upsert,
              'Logistic__c',
              AccessType.UPDATABLE
          );
          for (SObject s : safelogistics2upsert) {
              typelogistics2upsert.add((Logistic__c)s);
          }
          if (!typelogistics2upsert.isEmpty()) {
              upsert typelogistics2upsert; // or insert/update as needed
          }
        } else{
          /*not allowed*/
        }
        Integer j = 0;
        for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){
          for (Logistic_Line_Item__c loli : allLolis)
            loli.Logistic__c = typelogistics2upsert[j].Id;
          logisticsLines2upsert.addAll(allLolis);
          j++;
        }
        if (logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Purchase_Line_Items__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Purchase_Line_Items__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){
          upsert logisticsLines2upsert;
        } else{
          /*no allwed*/
        }

        system.debug('after LOLI upsert');
        List<Stock_Outward_Line_Item__c> allOutwards = new List<Stock_Outward_Line_Item__c>();
        for (Integer x = 0; x < AllTheLolis.size(); x++){
          for (Stock_Outward_Line_Item__c mySOLI : loliOutwards[x]){
            if (AllTheLolis[x].Id != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Logistic_Line_Item__c.isUpdateable())
              mySOLI.Logistic_Line_Item__c = AllTheLolis[x].Id;
            if (mySOLI.Status__c == 'Returned to Supplier')
              mySOLI.Status__c = '  Reserved';
            allOutwards.add(mySOLI);
          }
        }
        system.debug('allOutwards length~>' + allOutwards.size());
        if (POLI2upsert.size() > 0 && Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isCreateable() && Schema.sObjectType.Purchase_Line_Items__c.fields.Logistic_Quantity__c.isUpdateable()){
          upsert POLI2upsert;
        } else{
           /*not allowed*/
        }

        if (allOutwards.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){	 update allOutwards;
        } else{
          /*not allwed*/
        }


      }
    }
  }

  global static void ManageSalesOrderWarranties(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, List<Order> Trigger_New, List<Order> Trigger_Old){

    List<Id> warSoIds = new List<Id>();
    List<Id> productIds = new List<Id>();
    List<Id> soliIds = new List<Id>();
    List<Id> stoliIds = new List<Id>();
    Map<Id, Warranty__c> lineWarranty = new Map<Id, Warranty__c>();
    Map<Id, Warranty_Return_Policy__c> itemPolicy = new Map<Id, Warranty_Return_Policy__c>();
    List<Warranty__c> Warranties2Insert = new List<Warranty__c>();
    List<Id> cancelledPOIds = new List<Id>();
    for (Order SO : trigger_New){
      if (SO.Status == 'Cancelled')
        cancelledPOIds.add(SO.Id);
      if (SO.Issue_Warranty__c == True){
        warSoIds.add(SO.Id);
      } else if (Trigger_IsUpdate){
        String test2 = '';
        for (Order SOD : Trigger_Old){
          if (SO.Id == SOD.Id && SOD.Issue_Warranty__c != True && SO.Issue_Warranty__c == True){
            warSoIds.add(SO.Id);
            break;
          }
        }
      }
    }
    if (!PreventRecursiveLedgerEntry.testCasesTransactions){

      List<Stock_Outward_Line_Item__c> STOLIS;
      if (Schema.sObjectType.Stock_Outward_Line_Item__c.isAccessible()){
        if (warSoIds.size() > 0){
          STOLIS = [Select Id, Name, Active__c, Fixed_Asset__c, Product__c, Product__r.Name, Quantity__c, Order__c, Order_Product__c, Serial__c, Material_Batch_Lot__c, Order_Product__r.Company__c, Order_Product__r.Organisation_Business_Unit__c
                    From Stock_Outward_Line_Item__c
                    Where Order__c In:warSoIds
                    WITH SECURITY_ENFORCED
                    limit 100];
          if (STOLIS.size() > 0){
            for (Stock_Outward_Line_Item__c STOLI : STOLIS){
              stoliIds.add(STOLI.Id);
              productIds.add(STOLI.Product__c);
            }
            List<Warranty_Return_Policy__c> WRPS;
            if (Schema.sObjectType.Warranty_Return_Policy__c.isAccessible()){
              UtilClass.FlsCheck(new String[]{ 'Active__c', 'Days_of_Warranty__c', 'Exchange__c', 'Number_Days_From_Trans_Return_Accepted__c', 'Company__c', 'Organisation_Business_Unit__c', 'Product__c', 'Standard_Manufacturing_Warranty__c' }, 'Warranty_Return_Policy__c');
              if (productIds.size() > 0){
                WRPS = [Select Id, Name, Active__c, Days_of_Warranty__c, Exchange__c, Number_Days_From_Trans_Return_Accepted__c, Company__c, Organisation_Business_Unit__c, Product__c, Standard_Manufacturing_Warranty__c
                        From Warranty_Return_Policy__c
                        Where Product__c In:productIds And Active__c = true
                        WITH SECURITY_ENFORCED
                        limit 100];
              }
              if (WRPS != null)
                for (Warranty_Return_Policy__c WRP : WRPS){
                  itemPolicy.put(WRP.Product__c, WRP);
              }
            }
            List<Warranty__c> WS;
            if (Schema.sObjectType.Warranty__c.isAccessible()){
              UtilClass.FlsCheck(new String[]{ 'Company__c', 'Organisation_Business_Unit__c', 'Product__c', 'Quantity__c', 'Order_Product__c', 'Type__c', 'Valid_From__c', 'Valid_Till__c', 'Warranty_Return_Policy__c' }, 'Warranty__c');
              if (stoliIds.size() > 0)
                WS = [Select Id, Name, Company__c, Organisation_Business_Unit__c, Product__c, Quantity__c, Stock_Outward_Line_Item__c
                      From Warranty__c
                      Where Stock_Outward_Line_Item__c In:stoliIds
                      WITH SECURITY_ENFORCED
                      limit 100];
              if (WS != null)
                for (Warranty__c W : WS)
                  lineWarranty.put(W.Stock_Outward_Line_Item__c, W);
            }
            for (Stock_Outward_Line_Item__c STOLI : STOLIS){
              if (!lineWarranty.containsKey(STOLI.Id) && itemPolicy.containsKey(STOLI.Product__c)){
                Warranty_Return_Policy__c itmPolicy = itemPolicy.get(STOLI.Product__c);
                Warranty__c W = new Warranty__c();
                if (Schema.sObjectType.Warranty__c.fields.Company__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Company__c.isUpdateable()){
                  W.Company__c = STOLI.Order_Product__r.Company__c;
                }
                if (Schema.sObjectType.Warranty__c.fields.Organisation_Business_Unit__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Organisation_Business_Unit__c.isUpdateable()){
                  W.Organisation_Business_Unit__c = STOLI.Order_Product__r.Organisation_Business_Unit__c;
                }
                if (Schema.sObjectType.Warranty__c.fields.Product__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Product__c.isUpdateable()){
                  W.Product__c = STOLI.Product__c;
                }
                if (Schema.sObjectType.Warranty__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Quantity__c.isUpdateable()){
                  W.Quantity__c = STOLI.Quantity__c;
                }
                if (Schema.sObjectType.Warranty__c.fields.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Stock_Outward_Line_Item__c.isUpdateable()){
                  W.Stock_Outward_Line_Item__c = STOLI.Id;
                }
                if (Schema.sObjectType.Warranty__c.fields.Order_Product__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Order_Product__c.isUpdateable()){
                  W.Order_Product__c = STOLI.Order_Product__c;
                }
                if (Schema.sObjectType.Warranty__c.fields.Type__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Type__c.isUpdateable()){
                  W.Type__c = 'Standard';
                }
                if (Schema.sObjectType.Warranty__c.fields.Valid_From__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Valid_From__c.isUpdateable()){
                  W.Valid_From__c = System.Today();
                }
                if (Schema.sObjectType.Warranty__c.fields.Valid_Till__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Valid_Till__c.isUpdateable()){
                  W.Valid_Till__c = System.Today() + integer.Valueof(itmPolicy.Days_of_Warranty__c);
                }
                if (Schema.sObjectType.Warranty__c.fields.Warranty_Return_Policy__c.isCreateable() && Schema.sObjectType.Warranty__c.fields.Warranty_Return_Policy__c.isUpdateable()){
                  W.Warranty_Return_Policy__c = itmPolicy.Id;
                }
                Warranties2Insert.add(W);
              }
            }
          } else
            Trigger_New[0].addError('No stock outwards created for this sales order to issue warranty');
        }

        if (Warranties2Insert.size() > 0 && Schema.sObjectType.Warranty__c.isCreateable() && Schema.sObjectType.Warranty__c.isUpdateable()){
          List<Warranty__c> warrantyToUpsert = (List<Warranty__c>)Security.stripInaccessible(AccessType.UPSERTABLE, Warranties2Insert).getRecords();
          if (warrantyToUpsert != null && !warrantyToUpsert.isEmpty())
            upsert warrantyToUpsert;
        } else{
          /*not alloed to insert warranty*/
        }

        if (cancelledPOIds.size() > 0){
          List<Stock_Outward_Line_Item__c> cancelStock = [Select Id, Name, Order__c, Status__c, Fixed_Asset__c
                                                          From Stock_Outward_Line_Item__c
                                                          Where Order__c In:cancelledPOIds And Status__c != 'Rejected'
                                                          WITH SECURITY_ENFORCED
                                                          limit 100];
          List<Id> AssetsIds = new List<Id>();
          for (Stock_Outward_Line_Item__c soli : cancelStock){
            if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Status__c.isUpdateable()){
              soli.Status__c = 'Rejected';
            }
            if (soli.Fixed_Asset__c != Null){
              AssetsIds.add(soli.Fixed_Asset__c);
            }
          }
          List<Asset__c> assets2Update = [Select Id, Name, Available__c, Status__c
                                          From Asset__c
                                          Where Id In:AssetsIds
                                          WITH SECURITY_ENFORCED
                                          limit 100];
          for (Asset__c Asset : assets2Update){
            if (Schema.sObjectType.Asset__c.fields.Available__c.isCreateable() && Schema.sObjectType.Asset__c.fields.Available__c.isUpdateable()){
              Asset.Available__c = true;
            }
            if (Schema.sObjectType.Asset__c.fields.Status__c.isCreateable() && Schema.sObjectType.Asset__c.fields.Status__c.isUpdateable()){
              Asset.Status__c = 'Available';
            }
          }
          List<Logistic__c> cancelLogistics = [Select Id, Name, Order_S__c, Closed__c
                                               From Logistic__c
                                               Where Order_S__c In:cancelledPOIds And Closed__c = false
                                               WITH SECURITY_ENFORCED
                                               limit 100];
          for (Logistic__c logis : cancelLogistics){
            if (Schema.sObjectType.Logistic__c.fields.Closed__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Closed__c.isUpdateable()){
              logis.Closed__c = true;
            }
          }
          if (cancelStock.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){
            {
              upsert cancelStock;
            }
          } else{
            /*not allowed*/
          }
          if (assets2Update.size() > 0 && Schema.sObjectType.Asset__c.isCreateable() && Schema.sObjectType.Asset__c.isUpdateable()){
            {
              upsert assets2Update;
            }
          } else{
            /*not allowed*/
          }
          if (cancelLogistics.size() > 0 && Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){
            {
              upsert cancelLogistics;
            }
          } else{
            /*not allowed*/
          }
        }
      }
    }
  }

  global static void ManageSalesOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, Boolean Trigger_IsAfter, List<Order> Trigger_New, List<Order> Trigger_Old){

    Map<Id, list<Stock_Outward_Line_Item__c>> MRPoutward = new Map<Id, list<Stock_Outward_Line_Item__c>>();
    List<Id> POIds = new List<Id>();
    List<Id> soliIds = new List<Id>();
    List<Logistic__c> logistics2upsert = new List<Logistic__c>();
    List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();
    List<OrderItem> SOLIS = new List<OrderItem>();
    List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
    List<Logistic__c> existingLogistics = new List<Logistic__c>();
    Map<Id, Order> SOMap = new Map<Id, Order>();
    Map<Id, List<OrderItem>> SO_Solis_Map = new Map<Id, List<OrderItem>>();
    Map<Id, List<Stock_Outward_Line_Item__c>> solis_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
    Map<Id, Logistic__c> existingLogisticMap = new Map<Id, Logistic__c>();
    Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
    Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();
    String Reserved = 'Reserved';
    String SORecTypeId = Schema.SObjectType.Logistic__c.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId();
    String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
    UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
    String SOLIFields = 'Id,Active__c,Admin_Shipping_Amount__c,Allocate_Stock__c,Asset__c,AvailableQuantity,Base_Price__c,Batch_Lot__c,Checked_Out_Process__c,Commission__c,Commission_Rate_Card__c,Cost__c,Coupon__c,Coupon_Redemption__c,Detailed_Description__c,Discount_Amount__c,Discount_Percent__c,Discount_Plan__c,EndDate,End_Time__c,Explode__c,Gross_Amount__c,Insufficient_BOM__c,Inventory_Tracked__c,Invoice__c,Invoiced_Quantity__c,Is_Back_Order__c,Is_Kit__c,Is_Pre_Order__c,Issue_Manufacturing_Order__c,Issue_Purchase_Order__c,Issue_Work_Order__c,Description,ListPrice,Logistic_Cost__c,Logistic_Quantity__c,Manufacturing_Order__c,Name__c,Net_Price__c,OrderItemNumber,OrderId,Status__c,Company__c,Other_Tax__c,Overhead_Cost__c,Packed_Quantity__c,Picked_Quantity__c,Price_Book_Unit_Cost__c,PriceBook_Base_Price__c,PriceBook_Total_Price__c,PriceBookId__c,Product2Id,BOM__c,Quantity,Quantity_Needed__c,Ready_To_Pick_Pack__c,Reserved_Date__c,Reserved_Quantity__c,ReturnAmount__c,ReturnedQuantity__c,RMALines_to_Process__c,Routing__c,Serial_Number__c,Serial__c,Serialise__c,Shipped_Quantity__c,Site__c,Sort_Order__c,Order_Line_Status__c,Sub_Total__c,Tax__c,VAT_Amount__c,Total_Price__c,All_Total_Price__c,TotalPrice,Total_Tax__c,Track_Inventory__c,UnitPrice';//UtilClass.selectStarFromSObject('OrderItem');UtilClass.FLSCheck(SOLIFields.split(','),'OrderItem');
    List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Active__c, Primary__c, Channel__c, Site__c, Site__r.Name, Site__r.Primary_Contact__c
                                                          From Distribution_Channel__c
                                                          Where Active__c = true
                                                          WITH SECURITY_ENFORCED
                                                          order by Priority__c Desc
                                                          NULLS LAST
                                                          limit 100];
    for (Distribution_Channel__c DC : DistributionChannels){
      String DCId = DC.Site__c + '' + DC.Channel__c;
      siteDistribution.put(DCId, DC);
    }

    if (Trigger_IsAfter && Schema.sObjectType.Logistic__c.isAccessible()){

      set<Id> allTrgSOIds = new set<Id>();
      for (Integer i = 0; i < trigger_New.size(); i++){
        if (trigger_New[i].Ready_To_Pick_Pack__c && !PreventRecursiveLedgerEntry.Loged && trigger_New[i].Total_Quantity__c > trigger_New[i].Total_Logistic_Quantity_U__c){
          POIds.add(trigger_New[i].Id);
          SO_Solis_Map.put(trigger_New[i].Id, new List<OrderItem>());
          SOMap.put(trigger_New[i].Id, trigger_New[i]);
        }
        allTrgSOIds.add(trigger_New[i].Id);
      }
      List<OrderItem> kitSOLIS = new List<OrderItem>();
      kitSOLIS = Database.query('select Id, OrderId, Order.Ready_To_Pick_Pack__c from OrderItem where (OrderId In : allTrgSOIds And Product2.Is_Kit__c=true) WITH SECURITY_ENFORCED limit 100');
      for (Integer i = 0; i < kitSOLIS.size(); i++){
        if (kitSOLIS[i].Order.Ready_To_Pick_Pack__c && !PreventRecursiveLedgerEntry.Loged){
          POIds.add(kitSOLIS[i].OrderId);
          SO_Solis_Map.put(kitSOLIS[i].OrderId, new List<OrderItem>());
          for (Integer j = 0; j < trigger_New.size(); j++){
            if (trigger_New[j].Id == kitSOLIS[i].OrderId){
              SOMap.put(kitSOLIS[i].OrderId, trigger_New[j]);
              break;
            }
          }
        }
      }

      if (SOMap.Values().size() > 0){
        Set<Id> orderIds = SOMap.keySet();
        SOLIS = Database.query('select ' + String.escapeSingleQuotes(SOLIFields) + ', Product2.Name from OrderItem where (OrderId In : orderIds And (Product2.Track_Inventory__c=true Or Product2.Is_Kit__c=true Or Product2.Is_Asset__c=true)) WITH SECURITY_ENFORCED limit 100 ');
        pplis = Database.query('select ' + String.escapeSingleQuotes(PPLIFields) + ', Fixed_Asset__r.Product__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Order_Product__r.OrderId from Stock_Outward_Line_Item__c where Order__c In: orderIds and Status__c  = :Reserved and Quantity__c > 0 WITH SECURITY_ENFORCED order by Order__c Asc limit 100');

        for (OrderItem SOLI : SOLIS){
          if (SO_Solis_Map.containsKey(SOLI.OrderId))
            SO_Solis_Map.get(SOLI.OrderId).add(SOLI);
          else{
            List<OrderItem> mySOLI = new List<OrderItem>();
            mySOLI.add(SOLI);
            SO_Solis_Map.put(SOLI.OrderId, mySOLI);
          }
          solis_PPLI_Map.put(SOLI.Id, new List<Stock_Outward_Line_Item__c>());
        }

        for (Stock_Outward_Line_Item__c ppli : pplis){
          if (solis_PPLI_Map.containsKey(ppli.Order_Product__c))
            solis_PPLI_Map.get(ppli.Order_Product__c).add(ppli);
          else{
            List<Stock_Outward_Line_Item__c> myPPLI = new List<Stock_Outward_Line_Item__c>();
            myPPLI.add(ppli);
            solis_PPLI_Map.put(ppli.Order_Product__c, myPPLI);
          }
        }

        list<Stock_Outward_Line_Item__c> stoListFinal = new list<Stock_Outward_Line_Item__c>();

        try{
          stoListFinal = [SELECT Id, Name, Quantity__c, Order_Product__c, MRP_Material_Requirements_Planning__c, MRP_Material_Requirements_Planning__r.MRP_Product__c, Product__c, Logistic_Line_Item__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Status__c
                          FROM Stock_Outward_Line_Item__c
                          WHERE Order__c IN:SOMap.keySet() AND Status__c = 'Reserved' AND Logistic_Line_Item__c = NULL AND Quantity__c > 0
                          WITH SECURITY_ENFORCED
                          limit 100];
          for (Stock_Outward_Line_Item__c stockout : stoListFinal){
            if (stockout.MRP_Material_Requirements_Planning__c != null && stockout.MRP_Material_Requirements_Planning__r.MRP_Product__c != null){
              if (MRPoutward.containsKey(stockout.MRP_Material_Requirements_Planning__c)){
                {
                  MRPoutward.get(stockout.MRP_Material_Requirements_Planning__c).add(stockout);
                }
              } else
                MRPoutward.put(stockout.MRP_Material_Requirements_Planning__c, new List<Stock_Outward_Line_Item__c>{ stockout });
            }
          }

          existingLogistics = [Select Id, Name, Type__c, Account__c, Contact__c, Order_S__c, Active__c, Channel__c, To_Address__c, From_Address__c, RecordTypeId, Distribution_Channel__c, Closed__c
                               From Logistic__c
                               Where Order_S__c In:SOMap.keySet()
                               WITH SECURITY_ENFORCED
                               limit 100];
        } catch (Exception ex){
          /* ManageSalesOrderLogistics catch enter'*/
        }

        Map<Id, Order> soList = new Map<Id, Order>();
        List<List<Stock_Outward_Line_Item__c>> loliOutwards = new List<List<Stock_Outward_Line_Item__c>>();
        List<Logistic_Line_Item__c> AllTheLolis = new List<Logistic_Line_Item__c>();

        if (stoListFinal.size() > 0){
          for (Order SO : SOMap.Values()){
            Set<Id> mySites = new Set<Id>();
            if (SO_Solis_Map.containsKey(SO.Id)){
              for (OrderItem SOLI : SO_Solis_Map.get(SO.Id)){
                for (Stock_Outward_Line_Item__c ppli : stoListFinal)
                  mySites.add(ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c);
              }
              Integer i = 1+existingLogistics.size();
              for (Id siteId : mySites){
                String DCId = siteId + '' + SO.Channel__c;
                Logistic__c Logistic = new Logistic__c(
                  Name = SO.OrderNumber + '-Logistic-' + String.valueof(i),
                  Type__c = 'Outbound',
                  Account__c = SO.AccountId,
                  Contact__c = SO.Contact__c,
                  Company__c = SO.Company__c,
                  Order_S__c = SO.Id,
                  Active__c = true,
                  Channel__c = SO.Channel__c,
                  To_Address__c = SO.Ship_To_Address__c,
                  From_Address__c = SO.Ship_From_Address__c,
                  From_Contact__c = ((siteDistribution.get(DCId) != null) ? siteDistribution.get(DCId).Site__r.Primary_Contact__c : null),
                  RecordTypeId = SORecTypeId,
                  Distribution_Channel__c = (siteDistribution.get(DCId) != null) ? siteDistribution.get(DCId).Id : null
                );
                if (Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Shipment_type__c.isUpdateable()){
                  Logistic.Shipment_type__c = SO.Shipment_Type__c;
                }

                for (Logistic__c Log : existingLogistics){
                  if (Log.Type__c == 'Outbound' && Log.Order_S__c == SO.Id && Log.Active__c == true && Log.Channel__c == SO.Channel__c && Log.RecordTypeId == SORecTypeId && Log.Closed__c == false && siteDistribution.containsKey(DCId) && Log.Distribution_Channel__c == siteDistribution.get(DCId).Id){
                    Logistic = Log;
                    break;
                  }
                }
                Order sorder = new Order(
                  Id = SO.Id
                );
                if (Schema.sObjectType.Order.fields.Logistic__c.isUpdateable())
                  sorder.Logistic__c = True;
                soList.put(SO.Id, sorder);
                List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();
                i++;
                Integer j = 1;
                for (OrderItem SOLI : SO_Solis_Map.get(SO.Id)){
                  // changed the name of the loli to include SOLI.Product2.Name by Abubakar on 24 June 2024
                  if (!SOLI.Is_Kit__c){
                    Logistic_Line_Item__c loli = new Logistic_Line_Item__c(  Name = SOLI.Product2.Name + '-LogisticLine-' + String.valueof(j), Product__c = SOLI.Product2Id,Logistic__c = null, Order_Product__c = SOLI.Id, Status__c = 'Reserved', BOM__c = SOLI.BOM__c, Explode__c = SOLI.Explode__c, Price_Product__c = SOLI.UnitPrice, Quantity__c = 0, Detail_Description__c = SOLI.Detailed_Description__c
                    );
                    Decimal myQuantity = 0;
                    List<Stock_Outward_Line_Item__c> myOutwards = new List<Stock_Outward_Line_Item__c>();
                    for (Integer k = 0; k < stoListFinal.size(); k++){
                      if (stoListFinal[k].Order_Product__c == SOLI.Id && stoListFinal[k].Quantity__c != null && stoListFinal[k].Quantity__c > 0){
                        if (siteId == stoListFinal[k].Site_Product_Service_Inventory_Stock__r.Warehouse__c){
                          myQuantity += stoListFinal[k].Quantity__c; myOutwards.add(stoListFinal[k]);
                        }
                      }
                    }
                    if (Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){
                      loli.Quantity__c = myQuantity;
                    }
                    if (loli.Quantity__c > 0){
                      myLines.add(loli); AllTheLolis.add(loli); loliOutwards.add(myOutwards); j++;
                    }
                  } else if (SOLI.Is_Kit__c){
                    List<Stock_Outward_Line_Item__c> myOutwards = new List<Stock_Outward_Line_Item__c>();
                    for (Id MRPID : MRPoutward.keyset()){
                      Logistic_Line_Item__c loli = new Logistic_Line_Item__c();
                      Decimal myQuantity = 0;
                      for (Integer k = 0; k < stoListFinal.size(); k++){
                        if (stoListFinal[k].Order_Product__c == SOLI.Id && stoListFinal[k].Quantity__c != null && stoListFinal[k].Quantity__c > 0 && MRPID == stoListFinal[k].MRP_Material_Requirements_Planning__c){
                          loli = new Logistic_Line_Item__c( Name = SOLI.Product2.Name + '-LogisticLine-' + String.valueof(j), Product__c = stoListFinal[k].Product__c,
                            Logistic__c = null,
                            Order_Product__c = stoListFinal[k].Order_Product__c, Status__c = 'Reserved', BOM__c = SOLI.BOM__c, Explode__c = SOLI.Explode__c, Price_Product__c = SOLI.UnitPrice, Quantity__c = 0
                          );
                          if (siteId == stoListFinal[k].Site_Product_Service_Inventory_Stock__r.Warehouse__c){
                            myQuantity += stoListFinal[k].Quantity__c; myOutwards.add(stoListFinal[k]);
                          }
                          if (Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){  loli.Quantity__c = myQuantity;
                          }
                        }
                      }
                      if (loli.Quantity__c > 0){
                        myLines.add(loli); AllTheLolis.add(loli); loliOutwards.add(myOutwards); j++;
                      }
                    }
                  }
                }
                if (myLines.size() > 0)
                  logAndLine.put(Logistic, myLines);
              }
            }
          }
        }

        if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){
          if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable()){
            if (logAndLine.keySet().size() > 0){
              logistics2upsert.addAll(logAndLine.keySet());
              if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable()){
                upsert logistics2upsert;
              } else{
                /*not allowed */
              }
              Integer j = 0;
              for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){
                for (Logistic_Line_Item__c loli : allLolis){
                  if (Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable())
                    loli.Logistic__c = logistics2upsert[j].Id;
                }
                logisticsLines2upsert.addAll(allLolis);
                j++;
              }
              if (logisticsLines2upsert.size() > 0){
                PreventRecursiveLedgerEntry.Loged = true;
                if (Schema.sObjectType.Logistic_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.isUpdateable()){
                  insert logisticsLines2upsert;
                } else{
                  /*not allowed*/
                }
                List<Stock_Outward_Line_Item__c> allOutwards = new List<Stock_Outward_Line_Item__c>();
                for (Integer x = 0; x < logisticsLines2upsert.size(); x++){
                  for (Stock_Outward_Line_Item__c mySOLI : loliOutwards[x]){
                    if (logisticsLines2upsert[x].Product__c == mySOLI.Product__c){
                      if (Schema.sObjectType.Stock_Outward_Line_Item__c.fields.logistic_line_item__c.isCreateable() && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.logistic_line_item__c.isUpdateable()){
                        mySOLI.Logistic_Line_Item__c = AllTheLolis[x].Id;
                        allOutwards.add(mySOLI);
                      }
                    }
                  }
                }
                if (soList.size() > 0 && Schema.sObjectType.Order.isUpdateable()){
                  update soList.values();
                } else{
                  /*not allowed*/
                }
                if (allOutwards.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){  update allOutwards;
                } else{
                  /*not allwed*/
                }
              }
            }
          }
        }
      }
    }
  }

  /* global static void ManageRMALogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1) {
   system.debug('entered ManageRMALogistics for rma screen authiorse');
   List<Return_Merchandise_Authorisation__c> Trigger_New = (List<Return_Merchandise_Authorisation__c>)JSON.deserialize(Trigger_New1, List<Return_Merchandise_Authorisation__c>.class);
   List<Return_Merchandise_Authorisation__c> Trigger_Old = (List<Return_Merchandise_Authorisation__c>)JSON.deserialize(Trigger_Old1, List<Return_Merchandise_Authorisation__c>.class);
   List < Id > POIds = new List < Id > ();
   List < Id > soliIds = new List < Id > ();
   List < Logistic__c > logistics2upsert = new List < Logistic__c >();
   List < Logistic_Line_Item__c > logisticsLines2upsert = new List < Logistic_Line_Item__c >();
   List< RMA_Line_Item__c > SOLIS = new List< RMA_Line_Item__c >();
   List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
   List<Logistic__c> existingLogistics = new List<Logistic__c>();

   Map < Id, Return_Merchandise_Authorisation__c> SOMap = new Map < Id, Return_Merchandise_Authorisation__c> ();
   Map < Id, List< RMA_Line_Item__c >> SO_Solis_Map = new Map < Id, List< RMA_Line_Item__c >> ();
   Map < Id, List<Stock_Outward_Line_Item__c>> solis_PPLI_Map = new Map < Id, List<Stock_Outward_Line_Item__c>> ();
   Map < Id, Logistic__c> existingLogisticMap = new Map < Id, Logistic__c> ();
   Map < Logistic__c, List < Logistic_Line_Item__c >> logAndLine = new Map < Logistic__c, List < Logistic_Line_Item__c >> ();
   Map < String, Distribution_Channel__c> siteDistribution = new Map < String, Distribution_Channel__c> ();

   String RMARecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c','RMA');
   String Reserved = 'Reserved';
   String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
   UtilClass.FLSCheck(PPLIFields.split(','),'Stock_Outward_Line_Item__c');
   String SOLIFields = UtilClass.selectStarFromSObject('RMA_Line_Item__c');
   UtilClass.FLSCheck(SOLIFields.split(','),'RMA_Line_Item__c');

   if(Trigger_IsUpdate  && Schema.sObjectType.Logistic__c.isAccessible()){//Trigger.IsAfter && commented by asra
   System.debug('Inside ManageRMALogistics');//1
   for (Integer i=0; i<trigger_New.size(); i++) { if (trigger_New[i].Ready_To_Receive__c) { POIds.add(trigger_New[i].Id); SO_Solis_Map.put(trigger_New[i].Id, new List<RMA_Line_Item__c>());
   }
   }
   if(POIds.size() > 0) existingLogistics = [Select Id, Name, RMA__c From Logistic__c Where RMA__c In :POIds];
   for(Logistic__c Log : existingLogistics) existingLogisticMap.put(Log.RMA__c, Log);

   for (Integer i=0; i<trigger_New.size(); i++) {
   if (trigger_New[i].Ready_To_Receive__c && !existingLogisticMap.containsKey(trigger_New[i].Id)) { SOMap.put(trigger_New[i].Id, trigger_New[i]);
   }
   }
   if(SOMap.Values().size() > 0){
   System.debug('SOMap--> '+ SOMap);//2
   Set<Id> orderIds = SOMap.keySet();
   SOLIS = Database.query('select ' + String.escapeSingleQuotes(SOLIFields) + ' from RMA_Line_Item__c where (Return_Merchandise_Authorisation__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');
   System.debug('SOLIS--> '+ SOLIS);
   for(RMA_Line_Item__c SOLI :SOLIS){
   if(SO_Solis_Map.containsKey(SOLI.Return_Merchandise_Authorisation__c)){ SO_Solis_Map.get(SOLI.Return_Merchandise_Authorisation__c).add(SOLI);
   } else {
   List<RMA_Line_Item__c> mySOLI = new List<RMA_Line_Item__c>(); mySOLI.add(SOLI); SO_Solis_Map.put(SOLI.Return_Merchandise_Authorisation__c, mySOLI);
   }
   }
   System.debug('SOLIS--> '+ SO_Solis_Map);//3
   for(Return_Merchandise_Authorisation__c SO : SOMap.Values()){
   if(SO_Solis_Map.containsKey(SO.Id)){
   Logistic__c Logistic = new Logistic__c(Name=SO.Name+'-Logistic', Type__c='Inbound', Account__c=SO.Account__c, Contact__c=SO.Return_Contact__c, RMA__c=SO.Id, Active__c=true,Channel__c=SO.Channel__c, To_Address__c = SO.Address__c,RecordTypeId=RMARecTypeId,Distribution_Channel__c=SO.Distribution_Channel__c,Site__c=SO.Site__c,Logistic_Expected_Date__c = SO.Expected_Date__c);
   Logistic.Shipment_type__c = '--None--'; Logistic.Shipping_Preferences__c = '--None--';

   List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>(); Integer j = 1;

   for(RMA_Line_Item__c SOLI : SO_Solis_Map.get(SO.Id)){
   Logistic_Line_Item__c loli = new Logistic_Line_Item__c(Name=SOLI.Name+'-LogisticLine-'+String.valueof(j), Product__c=SOLI.Product__c, RMA_Line_Item__c=SOLI.Id, Status__c=SOLI.Return_Status__c, Explode__c = SOLI.Explode__c,Quantity__c=SOLI.Quantity_Return__c,Price_Product__c=SOLI.Sale_Price__c);
   if(loli.Quantity__c > 0) { myLines.add(loli);  j++;

   }
   }
   if(myLines.size() > 0) logAndLine.put(Logistic, myLines);
   }
   }
   System.debug('logAndLine--> '+ logAndLine);//4
   if(logAndLine.keySet().size() > 0){ logistics2upsert.addAll(logAndLine.keySet());
   if(Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() &&  Schema.sObjectType.Logistic__c.fields.RMA__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.RMA__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Site__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Site__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable()){
   // upsert logistics2upsert;

   System.SObjectAccessDecision securityDecihsgsionv99 = Security.stripInaccessible(AccessType.UPDATABLE, logistics2upsert); List<SObject> accessiblnjsheVersions  = securityDecihsgsionv99.getRecords();

   if (Schema.sObjectType.Logistic__c.isCreateable() && Schema.sObjectType.Logistic__c.isUpdateable() &&!accessiblnjsheVersions.isEmpty()) {upsert accessiblnjsheVersions[0]; } else {}}else{ }
   Integer j=0; for(List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){  for(Logistic_Line_Item__c loli : allLolis) loli.Logistic__c = logistics2upsert[j].Id; logisticsLines2upsert.addAll(allLolis); j++;

   }
   if(logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.RMA_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.RMA_Line_Item__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable())
   { upsert logisticsLines2upsert;}else{/*No acces */
  /*                                      }
   }
   System.debug('logistics2upsert--> '+ logistics2upsert);//5
   System.debug('logisticsLines2upsert--> '+ logisticsLines2upsert);//6
   }
   }
   } */
  // fixed by matheen for RMA
  global static void ManageRMALogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1){
    List<Return_Merchandise_Authorisation__c> Trigger_New = (List<Return_Merchandise_Authorisation__c>)JSON.deserialize(Trigger_New1, List<Return_Merchandise_Authorisation__c>.class);
    List<Return_Merchandise_Authorisation__c> Trigger_Old = (List<Return_Merchandise_Authorisation__c>)JSON.deserialize(Trigger_Old1, List<Return_Merchandise_Authorisation__c>.class);
    List<Id> POIds = new List<Id>();
    List<Id> soliIds = new List<Id>();
    List<Logistic__c> logistics2upsert = new List<Logistic__c>();
    List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();
    List<RMA_Line_Item__c> SOLIS = new List<RMA_Line_Item__c>();
    List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
    List<Logistic__c> existingLogistics = new List<Logistic__c>();

    Map<Id, Return_Merchandise_Authorisation__c> SOMap = new Map<Id, Return_Merchandise_Authorisation__c>();
    Map<Id, List<RMA_Line_Item__c>> SO_Solis_Map = new Map<Id, List<RMA_Line_Item__c>>();
    Map<Id, List<Stock_Outward_Line_Item__c>> solis_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
    Map<Id, Logistic__c> existingLogisticMap = new Map<Id, Logistic__c>();
    Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
    Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();

    String RMARecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c', 'RMA');
    String Reserved = 'Reserved';
    String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
    UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
    String SOLIFields = UtilClass.selectStarFromSObject('RMA_Line_Item__c');
    UtilClass.FLSCheck(SOLIFields.split(','), 'RMA_Line_Item__c');

    if (Trigger.IsAfter && Trigger_IsUpdate && Schema.sObjectType.Logistic__c.isAccessible()){
      System.debug('Inside ManageRMALogistics');//1
      for (Integer i = 0; i < trigger_New.size(); i++){   if (trigger_New[i].Ready_To_Receive__c){	POIds.add(trigger_New[i].Id);	SO_Solis_Map.put(trigger_New[i].Id, new List<RMA_Line_Item__c>());   }   }   if (POIds.size() > 0)    existingLogistics = [Select Id, Name, RMA__c                    From Logistic__c                 Where RMA__c In:POIds];   for (Logistic__c Log : existingLogistics)     existingLogisticMap.put(Log.RMA__c, Log);   for (Integer i = 0; i < trigger_New.size(); i++){    if (trigger_New[i].Ready_To_Receive__c && !existingLogisticMap.containsKey(trigger_New[i].Id)){      SOMap.put(trigger_New[i].Id, trigger_New[i]);     }   } if (SOMap.Values().size() > 0){   Set<Id> orderIds = SOMap.keySet();     SOLIS = Database.query('select ' + String.escapeSingleQuotes(SOLIFields) + ' from RMA_Line_Item__c where (Return_Merchandise_Authorisation__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');    System.debug('SOLIS--> ' + SOLIS);   for (RMA_Line_Item__c SOLI : SOLIS){     if (SO_Solis_Map.containsKey(SOLI.Return_Merchandise_Authorisation__c)){      SO_Solis_Map.get(SOLI.Return_Merchandise_Authorisation__c).add(SOLI);     } else{      List<RMA_Line_Item__c> mySOLI = new List<RMA_Line_Item__c>();      mySOLI.add(SOLI);     SO_Solis_Map.put(SOLI.Return_Merchandise_Authorisation__c, mySOLI);    }  }  System.debug('SOLIS--> ' + SO_Solis_Map);  for (Return_Merchandise_Authorisation__c SO : SOMap.Values()){    if (SO_Solis_Map.containsKey(SO.Id)){        Logistic__c Logistic = new Logistic__c(       Name = SO.Name + '-Logistic',     Type__c = 'Inbound',      Account__c = SO.Account__c,      Contact__c = SO.Return_Contact__c,    RMA__c = SO.Id,    Active__c = true,    Channel__c = SO.Channel__c,    To_Address__c = SO.Address__c,    RecordTypeId = RMARecTypeId,    Distribution_Channel__c = SO.Distribution_Channel__c,    Site__c = SO.Site__c,     Logistic_Expected_Date__c = SO.Expected_Date__c    );    Logistic.Shipment_type__c = '--None--';  
        //  Logistic.Shipping_Preferences__c = '--None--'; commented by matheen bcz of the exception and its out of the value
     List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();     Integer j = 1;     for (RMA_Line_Item__c SOLI : SO_Solis_Map.get(SO.Id)){      Logistic_Line_Item__c loli = new Logistic_Line_Item__c(        Name = SOLI.Name + '-LogisticLine-' + String.valueof(j),       Product__c = SOLI.Product__c,      RMA_Line_Item__c = SOLI.Id,      Status__c = SOLI.Return_Status__c,      Explode__c = SOLI.Explode__c,     Quantity__c = SOLI.Quantity_Return__c,     Price_Product__c = SOLI.Sale_Price__c  );   if (loli.Quantity__c > 0){    myLines.add(loli);    j++;       }      }      system.debug('myLines.size()==' + myLines.size());     if (myLines.size() > 0)        logAndLine.put(Logistic, myLines);      }    }     List<Logistic__c> typelogistics2upsert = new List<Logistic__c>();  System.debug('logAndLine--> ' + logAndLine);  if (logAndLine.keySet().size() > 0){     logistics2upsert.addAll(logAndLine.keySet());     if (Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RMA__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.RMA__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Site__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Site__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable()){    /* upsert logistics2upsert;*/    List<SObject> safelogistics2upsert = FLSHelper.getSafeRecords(       logistics2upsert,      'Logistic__c',     AccessType.UPDATABLE   );    for (SObject s : safelogistics2upsert) {       typelogistics2upsert.add((Logistic__c)s);   }   if (!typelogistics2upsert.isEmpty()) {    upsert typelogistics2upsert;    }  } else{      /*No access*/     }     Integer j = 0;    for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){     for (Logistic_Line_Item__c loli : allLolis)       loli.Logistic__c = typelogistics2upsert[j].Id;    logisticsLines2upsert.addAll(allLolis);    j++;      }        if (logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.RMA_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.RMA_Line_Item__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){      upsert logisticsLines2upsert;     } else{      /*No access*/     }
        }
        System.debug('logistics2upsert--> ' + logistics2upsert);//5
        System.debug('logisticsLines2upsert--> ' + logisticsLines2upsert);//6
      }
    }
  }

  //public static void ManageTransferOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, List < Transfer_Order__c > Trigger_New, List < Transfer_Order__c > Trigger_Old) {
  public static void ManageTransferOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1){
    try{
      system.debug('ManageTransferOrderLogistics called');
      List<Transfer_Order__c> Trigger_New = (List<Transfer_Order__c>)JSON.deserialize(Trigger_New1, List<Transfer_Order__c>.class);
      List<Transfer_Order__c> Trigger_Old = (List<Transfer_Order__c>)JSON.deserialize(Trigger_Old1, List<Transfer_Order__c>.class);
      List<Id> ToIds = new List<Id>();
      List<Id> TOLIIds = new List<Id>();
      List<Logistic__c> logistics2upsert = new List<Logistic__c>();
      List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();
      List<Transfer_Order_Line_Items__c> TOLIs = new List<Transfer_Order_Line_Items__c>();
      List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
      List<Logistic__c> existingLogistics = new List<Logistic__c>();

      Map<Id, Transfer_Order__c> TOMapOutbound = new Map<Id, Transfer_Order__c>();
      Map<Id, Transfer_Order__c> TOMapInbound = new Map<Id, Transfer_Order__c>();
      Map<Id, Logistic__c> existingLogisticMapOutbound = new Map<Id, Logistic__c>();
      Map<Id, Logistic__c> existingLogisticMapInbound = new Map<Id, Logistic__c>();
      Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
      Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();

      List<List<Stock_Outward_Line_Item__c>> loliOutwards = new List<List<Stock_Outward_Line_Item__c>>();
      List<Logistic_Line_Item__c> AllTheLolis = new List<Logistic_Line_Item__c>();

      String TORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c', 'Transfer_Order');
      String Reserved = 'Reserved';
      String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
      UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
      String poliFields = UtilClass.selectStarFromSObject('Transfer_Order_Line_Items__c');
      UtilClass.FLSCheck(poliFields.split(','), 'Transfer_Order_Line_Items__c');

      List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Active__c, Primary__c, Channel__c, Site__c, Site__r.Primary_Contact__c, Site__r.Name
                                                            From Distribution_Channel__c
                                                            Where Active__c = true
                                                            Order By Priority__c Desc];
      for (Distribution_Channel__c DC : DistributionChannels){
        String DCId = DC.Site__c + '' + DC.Channel__c;
        siteDistribution.put(DCId, DC);
      }
      if (Trigger.IsAfter && Trigger_IsUpdate && Schema.sObjectType.Logistic__c.isAccessible()){
        for (Integer i = 0; i < trigger_New.size(); i++){
          if (trigger_New[i].Ready_To_Pick_Pack__c || trigger_New[i].Ready_To_Receive__c){
            ToIds.add(trigger_New[i].Id);
          }
        }
        if (ToIds.size() > 0)
          existingLogistics = [Select Id, Name, Type__c, Transfer_Order__c
                               From Logistic__c
                               Where Transfer_Order__c In:ToIds];
        for (Logistic__c Log : existingLogistics){
          if (Log.Type__c == 'Outbound')   existingLogisticMapOutbound.put(Log.Transfer_Order__c, Log);  else if (Log.Type__c == 'Inbound')   existingLogisticMapInbound.put(Log.Transfer_Order__c, Log);
        }

        for (Integer i = 0; i < trigger_New.size(); i++){
          if (trigger_New[i].Ready_To_Pick_Pack__c && !existingLogisticMapOutbound.containsKey(trigger_New[i].Id)){
            TOMapOutbound.put(trigger_New[i].Id, trigger_New[i]);
          }
          if (trigger_New[i].Ready_To_Receive__c && !existingLogisticMapInbound.containsKey(trigger_New[i].Id)){
            TOMapInbound.put(trigger_New[i].Id, trigger_New[i]);
          }
        }

        // Outbound Logistics and Lines Creation
        if (TOMapOutbound.Values().size() > 0){
          system.debug('here 1');
          Map<Id, List<Transfer_Order_Line_Items__c>> TO_TOLIs_Map = new Map<Id, List<Transfer_Order_Line_Items__c>>();
          Map<Id, List<Stock_Outward_Line_Item__c>> TOLIs_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();

          Set<Id> orderIds = TOMapOutbound.keySet();
          TOLIs = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Transfer_Order_Line_Items__c where (Transfer_Order__c In : orderIds And (Products__r.Track_Inventory__c=true Or Products__r.Is_Kit__c=true Or Products__r.Is_Asset__c=true))');
          pplis = Database.query('select ' + String.escapeSingleQuotes(PPLIFields) + ', Fixed_Asset__r.Product__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Transfer_Order_Line_Item__r.Transfer_Order__c from Stock_Outward_Line_Item__c where Transfer_Order__c In: orderIds and Status__c  = :Reserved and Quantity__c > 0 Order By Transfer_Order__c Asc');
          system.debug('TOLIs=>' + TOLIs);
          system.debug('pplis=>' + pplis);

          for (Transfer_Order_Line_Items__c TOLI : TOLIs){
            if (TO_TOLIs_Map == Null)
              TO_TOLIs_Map.put(TOLI.Transfer_Order__c, new List<Transfer_Order_Line_Items__c>());
            if (TO_TOLIs_Map.containsKey(TOLI.Transfer_Order__c)){
              TO_TOLIs_Map.get(TOLI.Transfer_Order__c).add(TOLI);
            } else{
              List<Transfer_Order_Line_Items__c> myPOLI = new List<Transfer_Order_Line_Items__c>();
              myPOLI.add(TOLI);
              TO_TOLIs_Map.put(TOLI.Transfer_Order__c, myPOLI);
            }
            TOLIs_PPLI_Map.put(TOLI.Id, new List<Stock_Outward_Line_Item__c>());
          }

          for (Stock_Outward_Line_Item__c ppli : pplis){
            if (TOLIs_PPLI_Map.containsKey(ppli.Transfer_Order_Line_Item__c)){
              TOLIs_PPLI_Map.get(ppli.Transfer_Order_Line_Item__c).add(ppli);
            } else{
              List<Stock_Outward_Line_Item__c> myPPLI = new List<Stock_Outward_Line_Item__c>();
              myPPLI.add(ppli);
              TOLIs_PPLI_Map.put(ppli.Transfer_Order_Line_Item__c, myPPLI);
            }
          }

          for (Transfer_Order__c TO : TOMapOutbound.Values()){
            system.debug('here 2');
            Set<Id> mySites = new Set<Id>();
            if (TO_TOLIs_Map.containsKey(TO.Id)){
              for (Transfer_Order_Line_Items__c TOLI : TO_TOLIs_Map.get(TO.Id)){
                for (Stock_Outward_Line_Item__c ppli : TOLIs_PPLI_Map.get(TOLI.Id)){
                  mySites.add(ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c);
                }
              }
              Integer i = 1+existingLogistics.size() + logAndLine.keySet().size();
              for (Id siteId : mySites){
                system.debug('here 3');                String DCId = siteId + '' + TO.Channel__c;  Logistic__c Logistic = new Logistic__c( Name = TO.Name + '-Logistic-' + String.valueof(i), Type__c = 'Outbound', Account__c = TO.Customer__c, Contact__c = TO.Contact__c, Transfer_Order__c = TO.Id, Active__c = true, Channel__c = TO.Channel__c, To_Address__c = TO.To_Address__c, From_Address__c = TO.From_Address__c, RecordTypeId = TORecTypeId, Distribution_Channel__c = TO.Distribution_Channel__c   );    Logistic.From_Contact__c = (siteDistribution.containskey(DCId) ? siteDistribution.get(DCId).Site__r.Primary_Contact__c : null); /*added by shaguftha 02_07_24*/  if (TO.Shipment_type__c != null && TO.Shipment_type__c != '')   Logistic.Shipment_type__c = TO.Shipment_type__c;   else  Logistic.Shipment_type__c = '--None--';   if (TO.Shipment_Preference_Speed__c != null && TO.Shipment_Preference_Speed__c != '')   Logistic.Shipping_Preferences__c = TO.Shipment_Preference_Speed__c;   else  Logistic.Shipping_Preferences__c = '--None--';  i++;   List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();  Integer j = 1; for (Transfer_Order_Line_Items__c TOLI : TO_TOLIs_Map.get(TO.Id)){     Logistic_Line_Item__c loli = new Logistic_Line_Item__c( Name = '', Product__c = TOLI.Products__c, Transfer_Order_Line_Item__c = TOLI.Id, Quantity__c = 0, Explode__c = TOLI.Explode__c, Status__c = 'Reserved', Batch_Lot__c = string.valueOf(TOLI.Batch_Lot__c), Serial_Number__c = string.valueOf(TOLI.SerialNumber__c)       ); /*Name=TOLI.Name+'-LogisticLine-'+String.valueof(j),*/string     name = TOLI.Name + '-LogisticLine-' + String.valueof(j);      if (name.length() > 80)      loli.Name = name.substring(0, 79);    else     loli.Name = name;   List<Stock_Outward_Line_Item__c> myOutwards = new List<Stock_Outward_Line_Item__c>();   for (Stock_Outward_Line_Item__c ppli : TOLIs_PPLI_Map.get(TOLI.Id)){    if (siteId == ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c){    loli.Quantity__c += ppli.Quantity__c;     myOutwards.add(ppli);   }  }   if (loli.Quantity__c > 0){      myLines.add(loli);  AllTheLolis.add(loli);      loliOutwards.add(myOutwards);        j++;     }    }    if (myLines.size() > 0)      logAndLine.put(Logistic, myLines);     }       }       }     }

        // Inbound Logistics and Lines Creation
        if (TOMapInbound.Values().size() > 0){
          Map<Id, List<Transfer_Order_Line_Items__c>> TO_TOLIs_Map = new Map<Id, List<Transfer_Order_Line_Items__c>>();   Set<Id> orderIds = TOMapInbound.keySet();    TOLIs = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Transfer_Order_Line_Items__c where (Transfer_Order__c In : orderIds And (Products__r.Track_Inventory__c=true Or Products__r.Is_Kit__c=true Or Products__r.Is_Asset__c=true))');   for (Transfer_Order_Line_Items__c TOLI : TOLIs){   if (TO_TOLIs_Map == Null)    TO_TOLIs_Map.put(TOLI.Transfer_Order__c, new List<Transfer_Order_Line_Items__c>());   if (TO_TOLIs_Map.containsKey(TOLI.Transfer_Order__c)){  TO_TOLIs_Map.get(TOLI.Transfer_Order__c).add(TOLI);   } else{    List<Transfer_Order_Line_Items__c> myTOLI = new List<Transfer_Order_Line_Items__c>();  myTOLI.add(TOLI);     TO_TOLIs_Map.put(TOLI.Transfer_Order__c, myTOLI);     }   }     for (Transfer_Order__c TO : TOMapInbound.Values()){     if (TO_TOLIs_Map.containsKey(TO.Id)){    Integer p = 1+existingLogistics.size() + logAndLine.keySet().size();    Logistic__c Logistic = new Logistic__c( Name = TO.Name + '-Logistic-' + String.valueof(p), Type__c = 'Inbound', Account__c = TO.Customer__c, Contact__c = TO.Contact__c, Transfer_Order__c = TO.Id, Active__c = true, Channel__c = TO.To_Channel__c, To_Address__c = TO.To_Address__c, From_Address__c = TO.From_Address__c, RecordTypeId = TORecTypeId, Distribution_Channel__c = TO.To_Distribution_Channel__c    );    p++;   List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();  Integer j = 1;    if (TO.Shipment_type__c != null && TO.Shipment_type__c != '')      Logistic.Shipment_type__c = TO.Shipment_type__c;    else    Logistic.Shipment_type__c = '--None--';  if (TO.Shipment_Preference_Speed__c != null && TO.Shipment_Preference_Speed__c != '')    Logistic.Shipping_Preferences__c = TO.Shipment_Preference_Speed__c;    else     Logistic.Shipping_Preferences__c = '--None--';   for (Transfer_Order_Line_Items__c TOLI : TO_TOLIs_Map.get(TO.Id)){     Logistic_Line_Item__c loli = new Logistic_Line_Item__c(	Name = '',	Product__c = TOLI.Products__c,	Transfer_Order_Line_Item__c = TOLI.Id,	Quantity__c = TOLI.Quantity_requested__c,	Explode__c = TOLI.Explode__c,	Status__c = 'Reserved',	Batch_Lot__c = string.valueOf(TOLI.Batch_Lot__c), Serial_Number__c = string.valueOf(TOLI.SerialNumber__c)      ); /*Name=TOLI.Name+'-LogisticLine-'+String.valueof(j), */string     name = TOLI.Name + '-LogisticLine-' + String.valueof(j);   if (name.length() > 80)    loli.Name = name.substring(0, 79);    else        loli.Name = name;     myLines.add(loli);      j++;      }   if (myLines.size() > 0)      logAndLine.put(Logistic, myLines);     }    }    }

        if (logAndLine.keySet().size() > 0){
          logistics2upsert.addAll(logAndLine.keySet());
          system.debug('logistics2upsert size ~>' + logistics2upsert.size()); List<Logistic__c> typelogistics2upsert = new List<Logistic__c>(); 
          if (Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Transfer_Order__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Transfer_Order__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable()){/* upsert logistics2upsert;*/List<SObject> safelogistics2upsert = FLSHelper.getSafeRecords(logistics2upsert,'Logistic__c',      AccessType.UPDATABLE     );             for (SObject s : safelogistics2upsert) {       typelogistics2upsert.add((Logistic__c)s);     }    if (!typelogistics2upsert.isEmpty()) { System.debug('typelogistics2upsert[0].Shipping_Preferences__c = '+ typelogistics2upsert[0].Shipping_Preferences__c);  upsert typelogistics2upsert; /* or insert/update as needed*/     }     } else{       /*No access */     }   Integer j = 0;   for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){      for (Logistic_Line_Item__c loli : allLolis)      loli.Logistic__c = typelogistics2upsert[j].Id;     logisticsLines2upsert.addAll(allLolis);       j++;     }       if (logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Transfer_Order_Line_Item__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Transfer_Order_Line_Item__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){   upsert logisticsLines2upsert;    } else{       /*cannot upsert*/    }   List<Stock_Outward_Line_Item__c> allOutwards = new List<Stock_Outward_Line_Item__c>();   for (Integer x = 0; x < AllTheLolis.size(); x++){    for (Stock_Outward_Line_Item__c mySOLI : loliOutwards[x]){       if (AllTheLolis[x].Id != null && Schema.sObjectType.Stock_Outward_Line_Item__c.fields.Logistic_Line_Item__c.isUpdateable())       mySOLI.Logistic_Line_Item__c = AllTheLolis[x].Id;     allOutwards.add(mySOLI);    }    }   system.debug('allOutwards length~>' + allOutwards.size());     if (allOutwards.size() > 0 && Schema.sObjectType.Stock_Outward_Line_Item__c.isUpdateable()){     update allOutwards;  } else{   /*not allwed*/  }
        }
      }
    } catch (Exception e){
      System.debug('Exception ManageTransferOrderLogistics~> ' + e.getMessage() + '; at line ~> ' + e.getLineNumber());
    }
  }

  global static void ManageWorkOrderLogistics(Boolean Trigger_IsInsert, Boolean Trigger_IsUpdate, String Trigger_New1, String Trigger_Old1){
    List<WO__c> Trigger_New = (List<WO__c>)JSON.deserialize(Trigger_New1, List<WO__c>.class);
    List<WO__c> Trigger_Old = (List<WO__c>)JSON.deserialize(Trigger_Old1, List<WO__c>.class);
    List<Id> WOIds = new List<Id>();
    List<Id> woliIds = new List<Id>();
    List<Logistic__c> logistics2upsert = new List<Logistic__c>();
    List<Logistic_Line_Item__c> logisticsLines2upsert = new List<Logistic_Line_Item__c>();
    List<Work_Order_Line_Items__c> wolis = new List<Work_Order_Line_Items__c>();
    List<Stock_Outward_Line_Item__c> pplis = new List<Stock_Outward_Line_Item__c>();
    List<Logistic__c> existingLogistics = new List<Logistic__c>();

    Map<Id, WO__c> WOMapOutbound = new Map<Id, WO__c>();
    Map<Id, WO__c> WOMapInbound = new Map<Id, WO__c>();
    Map<Id, Logistic__c> existingLogisticMapOutbound = new Map<Id, Logistic__c>();
    Map<Id, Logistic__c> existingLogisticMapInbound = new Map<Id, Logistic__c>();
    Map<Logistic__c, List<Logistic_Line_Item__c>> logAndLine = new Map<Logistic__c, List<Logistic_Line_Item__c>>();
    Map<String, Distribution_Channel__c> siteDistribution = new Map<String, Distribution_Channel__c>();

    String WORecTypeId = RecordTypeUtil.getObjectRecordTypeIds('Logistic__c', 'Work_Order');
    String Reserved = 'Reserved';
    String PPLIFields = UtilClass.selectStarFromSObject('Stock_Outward_Line_Item__c');
    UtilClass.FLSCheck(PPLIFields.split(','), 'Stock_Outward_Line_Item__c');
    String poliFields = UtilClass.selectStarFromSObject('Work_Order_Line_Items__c');
    UtilClass.FLSCheck(poliFields.split(','), 'Work_Order_Line_Items__c');

    List<Distribution_Channel__c> DistributionChannels = [Select Id, Name, Active__c, Primary__c, Channel__c, Site__c, Site__r.Name
                                                          From Distribution_Channel__c
                                                          Where Active__c = true
                                                          Order By Priority__c Desc];
    for (Distribution_Channel__c DC : DistributionChannels){
      String DCId = DC.Site__c + '' + DC.Channel__c;
      siteDistribution.put(DCId, DC);
    }
    if (Trigger_IsUpdate && Schema.sObjectType.Logistic__c.isAccessible()){
      //Trigger.IsAfter && is removed by asra after confirming with shaguftha
      for (Integer i = 0; i < trigger_New.size(); i++){
        if (trigger_New[i].Ready_To_Pick_Pack__c || trigger_New[i].Ready_To_Receive__c){
          WOIds.add(trigger_New[i].Id);
        }
      }
      if (WOIds.size() > 0)
        existingLogistics = [Select Id, Name, Type__c, Work_Order__c
                             From Logistic__c
                             Where Work_Order__c In:WOIds];
      for (Logistic__c Log : existingLogistics){
        if (Log.Type__c == 'Outbound') existingLogisticMapOutbound.put(Log.Work_Order__c, Log);
        else if (Log.Type__c == 'Inbound')existingLogisticMapInbound.put(Log.Work_Order__c, Log);
      }

      for (Integer i = 0; i < trigger_New.size(); i++){
        if (trigger_New[i].Ready_To_Pick_Pack__c && !existingLogisticMapOutbound.containsKey(trigger_New[i].Id)){
          WOMapOutbound.put(trigger_New[i].Id, trigger_New[i]);
        }
        if (trigger_New[i].Ready_To_Receive__c && !existingLogisticMapInbound.containsKey(trigger_New[i].Id)){
          WOMapInbound.put(trigger_New[i].Id, trigger_New[i]);
        }
      }

      // Outbound Logistics and Lines Creation
      if (WOMapOutbound.Values().size() > 0){
        Map<Id, List<Work_Order_Line_Items__c>> WO_wolis_Map = new Map<Id, List<Work_Order_Line_Items__c>>();  Map<Id, List<Stock_Outward_Line_Item__c>> wolis_PPLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();   Set<Id> orderIds = WOMapOutbound.keySet();  wolis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Work_Order_Line_Items__c where (Work_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');   pplis = Database.query('select ' + String.escapeSingleQuotes(PPLIFields) + ', Fixed_Asset__r.Product__c, Site_Product_Service_Inventory_Stock__r.Warehouse__c, Work_Order_Line_Items__r.Work_Orders__c from Stock_Outward_Line_Item__c where Work_Orders__c In: orderIds and Status__c  = :Reserved and Quantity__c > 0 Order By Work_Orders__c Asc');   for (Work_Order_Line_Items__c WOLI : wolis){     if (WO_wolis_Map == Null)      WO_wolis_Map.put(WOLI.Work_Orders__c, new List<Work_Order_Line_Items__c>());      if (WO_wolis_Map.containsKey(WOLI.Work_Orders__c)){       WO_wolis_Map.get(WOLI.Work_Orders__c).add(WOLI);    } else{     List<Work_Order_Line_Items__c> myPOLI = new List<Work_Order_Line_Items__c>();    myPOLI.add(WOLI);     WO_wolis_Map.put(WOLI.Work_Orders__c, myPOLI);   }     wolis_PPLI_Map.put(WOLI.Id, new List<Stock_Outward_Line_Item__c>());   }    for (Stock_Outward_Line_Item__c ppli : pplis){     if (wolis_PPLI_Map.containsKey(ppli.Work_Order_Line_Items__c)){     wolis_PPLI_Map.get(ppli.Work_Order_Line_Items__c).add(ppli);   } else{   List<Stock_Outward_Line_Item__c> myPPLI = new List<Stock_Outward_Line_Item__c>();   myPPLI.add(ppli);   wolis_PPLI_Map.put(ppli.Work_Order_Line_Items__c, myPPLI);    }   }  for (WO__c WO : WOMapOutbound.Values()){      Set<Id> mySites = new Set<Id>();   if (WO_wolis_Map.containsKey(WO.Id)){   for (Work_Order_Line_Items__c woli : WO_wolis_Map.get(WO.Id)){      for (Stock_Outward_Line_Item__c ppli : wolis_PPLI_Map.get(WOLI.Id)){       mySites.add(ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c);     }  }   Integer i = 1;    for (Id siteId : mySites){      String DCId = siteId + '' + WO.Channel__c;     Logistic__c Logistic = new Logistic__c(      Name = WO.Name + '-Logistic-' + String.valueof(i),      Type__c = 'Outbound',     Account__c = WO.WO_Supplier__c,    Contact__c = WO.Contact__c,     Work_Order__c = WO.Id,   Active__c = true,  Channel__c = WO.Channel__c,  To_Address__c = WO.Shipping_Address__c,   From_Address__c = WO.Billing_Address__c,   RecordTypeId = WORecTypeId,   Distribution_Channel__c = WO.Distribution_Channel__c,    Shipment_type__c = '',   Shipping_Preferences__c = ''  );     i++;     List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();     Integer j = 1;     for (Work_Order_Line_Items__c woli : WO_wolis_Map.get(WO.Id)){     Logistic_Line_Item__c loli = new Logistic_Line_Item__c(     Name = woli.Name + '-LogisticLine-' + String.valueof(j),     Product__c = woli.Product__c,     Work_Order_Line_Items__c = woli.Id,   Quantity__c = 0,    BOM__c = woli.BOM__c,   Explode__c = woli.Explode__c,  Price_Product__c = woli.Unit_Price__c,  Status__c = 'Reserved'   );  for (Stock_Outward_Line_Item__c ppli : wolis_PPLI_Map.get(WOLI.Id)){     if (siteId == ppli.Site_Product_Service_Inventory_Stock__r.Warehouse__c)       loli.Quantity__c += ppli.Quantity__c;    }    if (loli.Quantity__c > 0){      myLines.add(loli);     j++;     }   }    if (myLines.size() > 0)     logAndLine.put(Logistic, myLines);    }     }    }   }

      // Inbound Logistics and Lines Creation
      if (WOMapInbound.Values().size() > 0){
        Map<Id, List<Work_Order_Line_Items__c>> WO_wolis_Map = new Map<Id, List<Work_Order_Line_Items__c>>();       Set<Id> orderIds = WOMapInbound.keySet();    wolis = Database.query('select ' + String.escapeSingleQuotes(poliFields) + ' from Work_Order_Line_Items__c where (Work_Orders__c In : orderIds And (Product__r.Track_Inventory__c=true Or Product__r.Is_Kit__c=true Or Product__r.Is_Asset__c=true))');     for (Work_Order_Line_Items__c WOLI : wolis){      if (WO_wolis_Map == Null)        WO_wolis_Map.put(WOLI.Work_Orders__c, new List<Work_Order_Line_Items__c>());     if (WO_wolis_Map.containsKey(WOLI.Work_Orders__c)){      WO_wolis_Map.get(WOLI.Work_Orders__c).add(WOLI);      } else{       List<Work_Order_Line_Items__c> myWOLI = new List<Work_Order_Line_Items__c>();        myWOLI.add(WOLI);      WO_wolis_Map.put(WOLI.Work_Orders__c, myWOLI);    }     }    for (WO__c WO : WOMapInbound.Values()){     if (WO_wolis_Map.containsKey(WO.Id)){      Logistic__c Logistic = new Logistic__c(       Name = WO.Name + '-Logistic',      Type__c = 'Inbound',      Account__c = WO.WO_Supplier__c,     Contact__c = WO.Contact__c,          Work_Order__c = WO.Id,       Active__c = true,      Channel__c = WO.Channel__c,       To_Address__c = WO.Shipping_Address__c,       From_Address__c = WO.Billing_Address__c,       RecordTypeId = WORecTypeId,       Distribution_Channel__c = WO.Distribution_Channel__c,        Shipment_type__c = '',        Shipping_Preferences__c = ''      );   List<Logistic_Line_Item__c> myLines = new List<Logistic_Line_Item__c>();       Integer j = 1;     for (Work_Order_Line_Items__c woli : WO_wolis_Map.get(WO.Id)){       Logistic_Line_Item__c loli = new Logistic_Line_Item__c(        Name = woli.Name + '-LogisticLine-' + String.valueof(j),        Product__c = woli.Product__c,       Work_Order_Line_Items__c = woli.Id,       Quantity__c = woli.Quantity__c,    BOM__c = woli.BOM__c,      Explode__c = woli.Explode__c,       Price_Product__c = woli.Unit_Price__c,         Status__c = 'Reserved'     );    myLines.add(loli);      }    if (myLines.size() > 0)     logAndLine.put(Logistic, myLines);  }  } }

      if (logAndLine.keySet().size() > 0){
        logistics2upsert.addAll(logAndLine.keySet());        if (Schema.sObjectType.Logistic__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Type__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Account__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Contact__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Work_Order__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Work_Order__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Active__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Channel__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.To_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.From_Address__c.isUpdateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isCreateable() && Schema.sObjectType.Logistic__c.fields.RecordTypeId.isUpdateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isCreateable() && Schema.sObjectType.Logistic__c.fields.Distribution_Channel__c.isUpdateable()){          upsert logistics2upsert;        } else{           /* not alllowed */        }        Integer j = 0;  for (List<Logistic_Line_Item__c> allLolis : logAndLine.Values()){for (Logistic_Line_Item__c loli : allLolis)loli.Logistic__c = logistics2upsert[j].Id;logisticsLines2upsert.addAll(allLolis);  j++;}  if (logisticsLines2upsert.size() > 0 && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Name.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Logistic__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Work_Order_Line_Items__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Work_Order_Line_Items__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Status__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.BOM__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.BOM__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Explode__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Price_Product__c.isUpdateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isCreateable() && Schema.sObjectType.Logistic_Line_Item__c.fields.Quantity__c.isUpdateable()){upsert logisticsLines2upsert;
        } else{
          /*not allowed */
        }
      }
    }
  }

}