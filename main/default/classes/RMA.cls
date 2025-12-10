global with sharing class RMA{
    private final Order so;

    @AuraEnabled
    global list<String> FrieghtTypeList{ get; set; }

    @AuraEnabled
    global list<String> StatusList{ get; set; }

    @AuraEnabled
    global boolean isOrderAccess{ get; set; }

    @AuraEnabled
    global boolean isSOAccess{ get; set; }

    @AuraEnabled
    global String ChannelId{ get; set; }

    @AuraEnabled
    global String ObjectLabel{ get; set; }

    @AuraEnabled
    global Distribution_Channel__c distributionchannel{ get; set; }

    global RMA(){
        ChannelId = '';
        ObjectLabel = SObjectType.Return_Merchandise_Authorisation__c.getLabel();
        distributionchannel = new Distribution_Channel__c();
        isOrderAccess = isSOAccess = false;
        FrieghtTypeList = StatusList = new List<String>();
    }

    @AuraEnabled
    global static RMA doInit(){
        RMA rma = new RMA();
        try{
            List<Employees__c> emp = [Select Id, Channel__c
                                      FROM Employees__c
                                      Where Employee_User__c = :userinfo.getUserId() and Active__c = true
                                      WITH SECURITY_ENFORCED];
            if (emp != null && emp.size() > 0){
                rma.ChannelId = emp[0].Channel__c;
                List<Distribution_Channel__c> dc_list = [SELECT Id, Name, Channel__c, Site__c, Site__r.Name, Site__r.Address__c, Site__r.Address__r.Name, Site__r.Address__r.Address_Line1__c, Site__r.Address__r.Address_Line2__c, Site__r.Address__r.City__c, Site__r.Address__r.State__c, Site__r.Address__r.Postal_Code__c, Site__r.Address__r.Country__c
                                                         FROM Distribution_Channel__c
                                                         Where Channel__c = :emp[0].Channel__c AND Active__c = true AND Returns_Handling__c = true AND Site__c != null
                                                         WITH SECURITY_ENFORCED
                                                         order by Priority__c
                                                         limit 1];
                if (dc_list != null && dc_list.size() > 0)
                    rma.distributionchannel = dc_list[0];
            }

            /*if (Schema.sobjectType.Return_Merchandise_Authorisation__c.Fields.Order__c.isAccessible())
                rma.isSOAccess = true;
            else
                rma.isSOAccess = false;*/
            if (Schema.sobjectType.Return_Merchandise_Authorisation__c.Fields.Order__c.isAccessible())
                rma.isOrderAccess = true;
            else
                rma.isOrderAccess = false;
            List<String> options = new List<String>();
            options.add('--None--');
            Schema.DescribeFieldResult fieldResult = Return_Merchandise_Authorisation__c.Freight_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry f : ple)
                options.add(f.getLabel());
            rma.FrieghtTypeList = options;

            List<String> StatusList = new List<String>();
            Schema.DescribeFieldResult FR = Return_Merchandise_Authorisation__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> ple1 = FR.getPicklistValues();
            for (Schema.PicklistEntry f : ple1)
                StatusList.add(f.getLabel());
            rma.StatusList = StatusList;

            return rma;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
    }

    global RMA(ApexPages.StandardController controller){
        if (ApexPages.currentPage().getParameters().get('soId') != null)
            so = [SELECT Id, Name
                  FROM Order
                  WHERE Id = :ApexPages.currentPage().getParameters().get('soId')
                  WITH SECURITY_ENFORCED];
    }

    global Order getSO(){
        return so;
    }

    @AuraEnabled
    global static List<String> getFreightType(){
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Return_Merchandise_Authorisation__c.Freight_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple)
            options.add(f.getLabel());
        return options;
    }

    @AuraEnabled
    global static List<String> getRMAStatus(){
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Return_Merchandise_Authorisation__c.status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple)
            options.add(f.getLabel());
        return options;
    }

    @AuraEnabled(cacheable=true)
    global static Return_Merchandise_Authorisation__c getRMAInstance(){
        return new Return_Merchandise_Authorisation__c();
    }

    @AuraEnabled
    global static List<String> getStatus(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = RMA_Line_Item__c.Return_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple){
            options.add(f.getLabel());
        }
        return options;
    }

    @AuraEnabled
    global static String getSiteDetails(String recordId){
        try{
            List<Site__c> siteList = new List<Site__c>();
            if (String.isNotEmpty(recordId))
                siteList = [SELECT Id, Address__c
                            FROM Site__c
                            Where Id = :recordId
                            WITH SECURITY_ENFORCED];
            return (siteList.size() > 0) ? siteList[0].Address__c : '';
        } catch (Exception e){throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    global static Distribution_Channel__c getSiteDetailsbyDC(String recordId){
        try{
            List<Distribution_Channel__c> dcList = new List<Distribution_Channel__c>();
            if (String.isNotEmpty(recordId))
                dcList = [SELECT Id, Name, Channel__c, Site__c, Site__r.Name
                          FROM Distribution_Channel__c
                          Where Id = :recordId
                          WITH SECURITY_ENFORCED];
            return (dcList.size() > 0) ? dcList[0] : null;
        } catch (Exception e){throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
    }

    @AuraEnabled(cacheable=true)
    global static Address__c FetchAddressById(String custId, String recordId){
         System.debug('rec id--+'+recordId);
        try{
            List<Address__c> addressList = new List<Address__c>();
            String qryFilter = '';
            if (String.isNotEmpty(custId))
                qryFilter += ' AND Customer__c=:CustId';
            if (String.isNotEmpty(recordId))
                qryFilter += ' AND Id =:recordId';
                System.debug('qryFilter --+'+qryFilter);
            if (String.isNotEmpty(qryFilter))
                addressList = Database.query('SELECT Id,Name,Address_Line1__c , Address_Line2__c ,City__c ,State__c ,Postal_Code__c,Country__c FROM Address__c WHERE Name != null ' + String.escapeSingleQuotes(qryFilter) + ' WITH SECURITY_ENFORCED   LIMIT 1 ');
            system.debug('addressList--'+addressList);
                if (addressList.size() > 0){ System.debug('address :'+addressList[0]);
                return addressList[0];}
            else{ System.debug('address is null');
                 return null;}
        } catch (Exception e){throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    global static Contact FetchContactById(String custId, String recordId){
        try{
            List<Contact> contactList = new List<Contact>();
            if (String.isNotEmpty(custId)){
                if (String.isNotEmpty(recordId))
                    contactList = [SELECT Id, Name, Email, Phone, Account.Name
                                   FROM Contact
                                   Where AccountId = :custId AND Id = :recordId
                                   WITH SECURITY_ENFORCED];
            }
            if (contactList.size() > 0)
                return contactList[0];
            else
                return null;
        } catch (Exception e){ throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    global static List<RMAWrapperLI> getOrdItemByCustomer(String CustID, Integer OFF_SET, String SoId){
        String defaultAcceptanceType;
        String defaultReturnStatus;
        for (Schema.PicklistEntry av : RMA_Line_Item__c.Acceptance_Type__c.getDescribe().getPicklistValues())
            if (av.isDefaultValue()){
                defaultAcceptanceType = av.getValue();
            break;
        }
        for (Schema.PicklistEntry av : RMA_Line_Item__c.Return_Status__c.getDescribe().getPicklistValues())
            if (av.isDefaultValue()){
                defaultReturnStatus = av.getValue();
            break;
        }

        OFF_SET = Integer.valueof(OFF_SET);
        String qryFilter = '';
        if (String.isNotEmpty(CustID))
            qryFilter += ' AND Order.AccountId =:CustID';
        if (String.isNotEmpty(SoId))
            qryFilter += ' AND OrderId =:SoId';
        List<RMAWrapperLI> RMAWrapperLIlist = new List<RMAWrapperLI>();
        Map<Id, Boolean> soli_WarrantyMap = new Map<Id, Boolean>();
        if (String.isNotEmpty(CustID) || String.isNotEmpty(SoId)){
            Map<Id, OrderItem> soliitemsMap = new Map<Id, OrderItem>((List<OrderItem>)Database.query('SELECT Id,Total_Tax__c, Tax__r.Tax_Rate__c,All_Total_Price__c,Order.Amount_Paid__c,Order.Coupon_Discount_Quantity__c ,Coupon__c,Base_Price__c,UnitPrice,Batch_Lot__c,Batch_Lot__r.Name,Serial__c,Discount_Amount__c,Serial__r.Name,Serial__r.Serial_Number__c,Serial_Number__c ,OrderId,Order.Company__c,Order.Name , Order.Status ,Order.AccountId, ReturnedQuantity__c, Quantity, Product2Id ,Product2.Name, Product2.ProductCode,Product2.Serialise__c, Product2.Lot_Tracked__c FROM OrderItem WHERE Order.Status !=\'Cancelled\' AND Order.Is_Closed__c  =true ' + String.escapeSingleQuotes(qryFilter) + ' WITH SECURITY_ENFORCED order by CreatedDate desc Limit 200'));

            Map<Id, Id> soliMapSerial = new Map<Id, Id>();
            for (RMA_Line_Item__c tempRMALI : [Select Id, Ord_Item__c, Serial_Number__c
                                               FROM RMA_Line_Item__c
                                               WHERE Ord_Item__c IN:soliitemsMap.keySet() AND Serial_Number__c != null AND Product__r.Serialise__c = true
                                               WITH SECURITY_ENFORCED]){soliMapSerial.put(tempRMALI.Ord_Item__c, tempRMALI.Serial_Number__c);
            }

            if (soliitemsMap.keySet().size() > 0){
                for (Warranty__c warranty : [Select Id, Order_Product__c
                                             From Warranty__c
                                             Where Order_Product__c In:soliitemsMap.keySet() And Valid_From__c <= Today And Valid_Till__c >= Today
                                             WITH SECURITY_ENFORCED]){
                    soli_WarrantyMap.put(warranty.Order_Product__c, true);
                }

                Map<Id, List<Stock_Outward_Line_Item__c>> rentalSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
                Map<Id, List<Stock_Outward_Line_Item__c>> batchSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
                IF (soliitemsMap.keySet().SIZE() > 0){
                    for (Stock_Outward_Line_Item__c soli : [SELECT Id, Order_Product__r.Product2.Lot_Tracked__c, Order_Product__r.Product2.Serialise__c, Fixed_Asset__c, Product__c, Order_Product__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, Quantity__c
                                                            FROM Stock_Outward_Line_Item__c
                                                            WHERE Order_Product__c in:soliitemsMap.keySet() and (Order_Product__r.Product2.Serialise__c = true or Order_Product__r.Product2.Lot_Tracked__c = true) and Status__c = 'Committed'
                                                            WITH SECURITY_ENFORCED]){
                        if (soli.Order_Product__r.Product2.Serialise__c){
                            List<Stock_Outward_Line_Item__c> templist = (rentalSOLI_Map.get(soli.Order_Product__c) != null) ? rentalSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                            templist.add(soli);
                            rentalSOLI_Map.put(soli.Order_Product__c, templist);
                        }
                        if (soli.Order_Product__r.Product2.Lot_Tracked__c){
                            List<Stock_Outward_Line_Item__c> templist = (batchSOLI_Map.get(soli.Order_Product__c) != null) ? batchSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                            templist.add(soli);batchSOLI_Map.put(soli.Order_Product__c, templist);
                        }
                    }
                }


                for (OrderItem so_Li : soliitemsMap.values()){
                    if (so_li.ReturnedQuantity__c == null)
                        so_li.ReturnedQuantity__c = 0.00;
                    if (so_Li.Product2.Serialise__c && rentalSOLI_Map.get(so_Li.Id) != null){
                        for (Stock_Outward_Line_Item__c soli : rentalSOLI_Map.get(so_Li.Id)){
                            if (!(soliMapSerial.get(so_Li.Id) != null)){
                                RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                    Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                    Base_Price__c = so_li.Base_Price__c, 
                                    Sale_Price__c = so_li.UnitPrice, 
                                    Acceptance_Type__c = defaultAcceptanceType, 
                                    Return_Status__c = defaultReturnStatus, 
                                    Product__c = so_li.Product2Id, 
                                    Product__r = new Product2(
                                        Name = so_li.Product2.Name, 
                                        ProductCode = so_li.Product2.ProductCode
                                    ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = soli.Quantity__c, Return_Reason__c = ''
                                );
                                //RMALI.Total_Deduction__c= so_li.All_Total_Price__c;
                                if (so_li.Total_Tax__c != null)
                                    RMALI.Tax__c = so_li.Total_Tax__c / so_li.Quantity;
                                // RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);
                                
                                // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here

                                RMALI.Serial_Number__c = soli.Serial__c;
                                RMALI.Serial_Number__r = new Serial_Number__c(
                                    Id = soli.Serial__c, 
                                    Name = soli.Serial__r.Name, 
                                    Serial_Number__c = soli.Serial__r.Serial_Number__c
                                );
                                RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                RMAWrapperLIlist.add(temp_RMAWrapperLI);
                            }
                        }

                    } else if (!so_Li.Product2.Serialise__c){
                        decimal qty = double.valueof(so_li.Quantity - so_li.ReturnedQuantity__c);
                        if (qty > 0.00){
                            RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                Batch_Lot__c = so_li.Batch_Lot__c, 
                                Serial_Number__c = so_li.Serial__c, 
                                Acceptance_Type__c = defaultAcceptanceType, 
                                Return_Status__c = defaultReturnStatus, 
                                Product__c = so_li.Product2Id, 
                                Product__r = new Product2(
                                    Name = so_li.Product2.Name, 
                                    ProductCode = so_li.Product2.ProductCode
                                ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = qty, Base_Price__c = so_li.Base_Price__c, Sale_Price__c = so_li.UnitPrice, Return_Reason__c = ''
                            );
                            if (so_li.Total_Tax__c != null)
                                RMALI.Tax__c = so_li.Total_Tax__c / so_li.Quantity;
                            //RMALI.Total_Deduction__c= so_li.All_Total_Price__c;
                            // RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);
                             // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here

                            if (so_Li.Product2.Lot_Tracked__c && batchSOLI_Map.get(so_Li.Id) != null){ for (Stock_Outward_Line_Item__c soli : batchSOLI_Map.get(so_Li.Id)){ RMALI.Batch_Lot__c = soli.Material_Batch_Lot__c;  RMALI.Batch_Lot__r = new Batch__c( Name = soli.Material_Batch_Lot__r.Name );} }
                            RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                            RMAWrapperLIlist.add(temp_RMAWrapperLI);
                        }
                    }
                }
            }
        }
        return RMAWrapperLIlist;
    }

   /* @AuraEnabled
    global static customerInfo FetchcustomerInfo(String custId, String invId, String ordId, Boolean isSalesOrder, Boolean isOrder){
        customerInfo custinfo = new customerInfo();
        contact con = new contact();
        Address__c addr = new Address__c();
        try{
            if (String.isNotEmpty(custId)){
                con = [SELECT Id, Name, Email, Phone, Account.Name
                       FROM Contact
                       Where AccountId = :custId AND Primary__c = true
                       WITH SECURITY_ENFORCED
                       limit 1];
                addr = [SELECT Id, Name, Address_Line1__c, Address_Line2__c, City__c, State__c, Postal_Code__c, Country__c
                        FROM Address__c
                        WHERE Customer__c = :custId AND Primary__c = true AND Is_Shipping_Address__c = true
                        WITH SECURITY_ENFORCED
                        limit 1];
            }
            if (con.Id != null)
                custinfo.contact = con;
            if (addr.Id != null)
                custinfo.Address = addr;
        } catch (QueryException qe){
            if (con.Id != null)
                custinfo.contact = con;
            if (addr.Id != null)
                custinfo.Address = addr;
        }
        try{
            if ((String.isEmpty(invId) || String.isBlank(invId)) && String.isNotEmpty(custId)){
                String defaultAcceptanceType;
                String defaultReturnStatus;
                for (Schema.PicklistEntry av : RMA_Line_Item__c.Acceptance_Type__c.getDescribe().getPicklistValues())
                    if (av.isDefaultValue()){
                        defaultAcceptanceType = av.getValue();
                    break;
                }
                for (Schema.PicklistEntry av : RMA_Line_Item__c.Return_Status__c.getDescribe().getPicklistValues())
                    if (av.isDefaultValue()){
                        defaultReturnStatus = av.getValue();
                    break;
                }

                List<RMAWrapperLI> RMAWrapperLIlist = new List<RMAWrapperLI>();
                Map<Id, Boolean> soli_WarrantyMap = new Map<Id, Boolean>();


                Map<Id, List<Id>> AssetsProdIds = new Map<Id, List<Id>>();
                Map<Id, String> astProdSN = new Map<Id, String>();

                if ((String.isEmpty(ordId) || String.isBlank(ordId))){
                    for (Asset ast : [Select Id, AccountId, Product2Id, ProductCode, StockKeepingUnit, PurchaseDate, SerialNumber, Status
                                      FROM Asset
                                      WHERE AccountId = :custId AND Product2Id != null AND Status = 'Installed'
                                      WITH SECURITY_ENFORCED]){
                        if (String.isNotEmpty(ast.SerialNumber))
                            astProdSN.put(ast.Product2Id, ast.SerialNumber);
                        if (AssetsProdIds.containsKey(ast.AccountId)){
                            AssetsProdIds.get(ast.AccountId).add(ast.Product2Id);
                        } else{
                            AssetsProdIds.put(ast.AccountId, new List<Id>{ ast.Product2Id });
                        }
                    }
                }

                List<String> prodIds = new List<String>();
                if (AssetsProdIds.containsKey(custId)){
                    prodIds = AssetsProdIds.get(custId);
                }

                if (isOrder){
                    String qry = 'SELECT Id,Total_Tax__c,All_Total_Price__c,Order.Amount_Paid__c,Order.Coupon_Discount_Quantity__c ,Coupon__c,Base_Price__c,UnitPrice,Batch_Lot__c,Batch_Lot__r.Name,Serial__c,Discount_Amount__c,Serial__r.Name,Serial__r.Serial_Number__c,Serial_Number__c ,OrderId,Order.Company__c,Order.Name , Order.Status ,Order.AccountId, ReturnedQuantity__c, Quantity, Product2Id ,Product2.Name, Product2.ProductCode,Product2.Serialise__c, Product2.Lot_Tracked__c FROM OrderItem WHERE Order.Status !=\'Cancelled\' AND Order.Is_Closed__c  = true AND Order.AccountId =: custId ';
                    if (String.isNotEmpty(ordId))
                        qry += ' AND OrderId =: ordId ';
                    else if (prodIds.size() > 0)
                        qry += ' AND Product2Id IN : prodIds ';
                    qry += '  WITH SECURITY_ENFORCED order by CreatedDate desc Limit 200 ';

                    Map<Id, OrderItem> soliitemsMap = new Map<Id, OrderItem>((List<OrderItem>)Database.query(qry));
                    if (soliitemsMap.keySet().size() > 0){

                        Map<Id, Id> soliMapSerial = new Map<Id, Id>();
                        for (RMA_Line_Item__c tempRMALI : [Select Id, Ord_Item__c, Serial_Number__c
                                                           FROM RMA_Line_Item__c
                                                           WHERE Ord_Item__c IN:soliitemsMap.keySet() AND Serial_Number__c != null AND Product__r.Serialise__c = true
                                                           WITH SECURITY_ENFORCED]){
                            soliMapSerial.put(tempRMALI.Ord_Item__c, tempRMALI.Serial_Number__c);
                        }

                        for (Warranty__c warranty : [Select Id, Order_Product__c
                                                     From Warranty__c
                                                     Where Order_Product__c In:soliitemsMap.keySet() And Valid_From__c <= Today And Valid_Till__c >= Today
                                                     WITH SECURITY_ENFORCED]){
                            soli_WarrantyMap.put(warranty.Order_Product__c, true);
                        }

                        Map<Id, List<Stock_Outward_Line_Item__c>> rentalSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
                        Map<Id, List<Stock_Outward_Line_Item__c>> batchSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();

                        for (Stock_Outward_Line_Item__c soli : [SELECT Id, Order_Product__r.Product2.Lot_Tracked__c, Order_Product__r.Product2.Serialise__c, Fixed_Asset__c, Product__c ,Order_Product__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name, Serial__c ,Serial__r.Name, Serial__r.Serial_No__c ,Quantity__c FROM Stock_Outward_Line_Item__c  WHERE Order_Product__c in: soliitemsMap.keySet() and (Order_Product__r.Product2.Serialise__c = true or Order_Product__r.Product2.Lot_Tracked__c = true) and Status__c = 'Committed']){
                            if (soli.Order_Product__r.Product2.Serialise__c){
                                List<Stock_Outward_Line_Item__c> templist = (rentalSOLI_Map.get(soli.Order_Product__c) != null) ? rentalSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                                templist.add(soli);
                                rentalSOLI_Map.put(soli.Order_Product__c, templist);
                            }
                            if (soli.Order_Product__r.Product2.Lot_Tracked__c){
                                List<Stock_Outward_Line_Item__c> templist = (batchSOLI_Map.get(soli.Order_Product__c) != null) ? batchSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                                templist.add(soli);
                                batchSOLI_Map.put(soli.Order_Product__c, templist);
                            }
                        }

                        Boolean processit = false;
                        for (OrderItem so_Li : soliitemsMap.values()){
                            if (so_li.ReturnedQuantity__c == null)
                                so_li.ReturnedQuantity__c = 0.00;
                            if (so_Li.Product2.Serialise__c && rentalSOLI_Map.get(so_Li.Id) != null){
                                for (Stock_Outward_Line_Item__c soli : rentalSOLI_Map.get(so_Li.Id)){
                                    processit = false;
                                    if (soliMapSerial.containsKey(so_Li.Id)){
                                        if (soli.Serial__c != null){
                                            if (soliMapSerial.get(so_Li.Id) != soli.Serial__c)
                                                processit = true;
                                        } else
                                            processit = true;
                                    } else
                                        processit = true;
                                    if (processit){
                                        RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                            Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                            Base_Price__c = so_li.Base_Price__c, 
                                            Sale_Price__c = so_li.UnitPrice, 
                                            Acceptance_Type__c = defaultAcceptanceType, 
                                            Return_Status__c = defaultReturnStatus, 
                                            Product__c = so_li.Product2Id, 
                                            Product__r = new Product2(
                                                Name = so_li.Product2.Name, 
                                                ProductCode = so_li.Product2.ProductCode
                                            ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = soli.Quantity__c, Return_Reason__c = ''
                                        );
                                        if (so_li.Total_Tax__c != null)
                                            RMALI.Tax__c = so_li.Total_Tax__c / so_li.Quantity;
                                        RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);
                                        if (soli.Serial__c != null){
                                            RMALI.Serial_Number__c = soli.Serial__c;
                                             RMALI.Serial_Number__r = new Serial_Number__c(Id=soli.Serial__c,Name=soli.Serial__r.Name,Serial_No__c=soli.Serial__r.Serial_No__c);
                                        }
                                        RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                        RMAWrapperLIlist.add(temp_RMAWrapperLI);
                                    }
                                }
                            } else if (!so_Li.Product2.Serialise__c){
                                decimal qty = double.valueof(so_li.Quantity - so_li.ReturnedQuantity__c);
                                if (qty > 0.00){
                                    RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                        Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                        Batch_Lot__c = so_li.Batch_Lot__c, 
                                        Serial_Number__c = so_li.Serial__c, 
                                        Acceptance_Type__c = defaultAcceptanceType, 
                                        Return_Status__c = defaultReturnStatus, 
                                        Product__c = so_li.Product2Id, 
                                        Product__r = new Product2(
                                            Name = so_li.Product2.Name, 
                                            ProductCode = so_li.Product2.ProductCode
                                        ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = qty, Base_Price__c = so_li.Base_Price__c, Sale_Price__c = so_li.UnitPrice, Return_Reason__c = ''
                                    );
                                    if (so_li.Total_Tax__c != null)
                                        RMALI.Tax__c = so_li.Total_Tax__c / so_li.Quantity;
                                    RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);
                                    if (so_Li.Product2.Lot_Tracked__c && batchSOLI_Map.get(so_Li.Id) != null){
                                        for (Stock_Outward_Line_Item__c soli : batchSOLI_Map.get(so_Li.Id)){
                                            RMALI.Batch_Lot__c = soli.Material_Batch_Lot__c;
                                            RMALI.Batch_Lot__r = new Batch__c(
                                                Name = soli.Material_Batch_Lot__r.Name
                                            );
                                        }
                                    }
                                    RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                    RMAWrapperLIlist.add(temp_RMAWrapperLI);
                                }
                            }
                        }
                    } else{

                    }

                    custinfo.RAMLI_List = RMAWrapperLIlist;
                }
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        } 
        return custinfo;
    }*/
     @AuraEnabled(cacheable=true)
    global static customerInfo FetchcustomerInfo(String custId,String invId,String ordId,Boolean isSalesOrder,Boolean isOrder){
       
       System.debug('custId ->'+custId+'invId ->'+invId+'ordId->'+ordId+'isSalesOrder ->'+isSalesOrder+'isOrder->'+isOrder);
        customerInfo custinfo = new customerInfo(); 
        contact con = new contact();
        Address__c addr = new Address__c();
        Order order=new Order();
        try{
            //Order object used to fetch the to_address from Order.Ship_To_Address__c and is inturn used to generate the from_address for RMA.
            if(String.isNotEmpty(ordId)){
                order=[Select Id, Contact__c,Contact__r.Name, Ship_To_Address__c,Ship_To_Address__r.Name from Order where Id=:ordId limit 1];
            }
            
            if(String.isNotEmpty(custId)){
                con = [SELECT Id,Name,Email,Phone,Account.Name FROM Contact Where AccountId=:custId limit 1];
                addr = [SELECT Id,Name,Address_Line1__c , Address_Line2__c ,City__c ,State__c ,Postal_Code__c,Country__c FROM Address__c WHERE Customer__c=:custId AND Is_Shipping_Address__c =true limit 1]; // Uncommented by matheen 23-2-25
                if(order!=null && order.Ship_To_Address__c!=null){
                    addr = [SELECT Id,Name,Address_Line1__c , Address_Line2__c ,City__c ,State__c ,Postal_Code__c,Country__c FROM Address__c WHERE Customer__c=:custId AND Id=:order.Ship_To_Address__c AND Is_Shipping_Address__c =true limit 1];
                }
            }
            // if(con.Id != null) custinfo.contact = con;
            // if(addr.Id != null) custinfo.Address = addr;
            if(order.Contact__c != null) custinfo.contact = order.Contact__r;
            if(order.Ship_To_Address__c != null) custinfo.Address = order.Ship_To_Address__r;
           
            System.debug('order Ship_To_Address__c --'+custinfo.Address);
            System.debug('order Contact__c --'+custinfo.contact);

            

        }catch(QueryException qe){
            system.debug('qexcp~>'+qe.getMessage()+' at '+qe.getStackTraceString());
            if(con.Id != null) custinfo.contact = con;
            if(addr.Id != null) custinfo.Address = addr;
        }
        try{
            
            Map<Id,List<Id>> AssetsProdIds = new Map<Id,List<Id>>();
            Map<Id,String> astProdSN = new Map<Id,String>();
            
            if((String.isEmpty(ordId) || String.isBlank(ordId))){
                for(Asset ast:[Select Id,AccountId, Product2Id,ProductCode,StockKeepingUnit,PurchaseDate,SerialNumber,Status FROM Asset WHERE AccountId =: custId AND Product2Id != null AND Status = 'Installed' ]){if(String.isNotEmpty(ast.SerialNumber)){ astProdSN.put(ast.Product2Id, ast.SerialNumber);} if (AssetsProdIds.containsKey(ast.AccountId)){ AssetsProdIds.get(ast.AccountId).add(ast.Product2Id); }else{AssetsProdIds.put(ast.AccountId, new List <Id> { ast.Product2Id }); } }
            }
            
            List<String> prodIds = new List<String>();
            if(AssetsProdIds.containsKey(custId)){prodIds = AssetsProdIds.get(custId);
            }
            
            //if((String.isEmpty(invId) || String.isBlank(invId)) && String.isNotEmpty(custId)){
            if(String.isNotEmpty(invId) || String.isNotEmpty(ordId)){
                String defaultAcceptanceType;
                String defaultReturnStatus;
                for (Schema.PicklistEntry av: RMA_Line_Item__c.Acceptance_Type__c.getDescribe().getPicklistValues()) 
                    if (av.isDefaultValue()) { defaultAcceptanceType = av.getValue();break;}
                for (Schema.PicklistEntry av: RMA_Line_Item__c.Return_Status__c.getDescribe().getPicklistValues()) 
                    if (av.isDefaultValue()) { defaultReturnStatus = av.getValue();break;}
                
                List<RMAWrapperLI> RMAWrapperLIlist = new  List<RMAWrapperLI>();
                Map<Id,Boolean> soli_WarrantyMap = new Map<Id,Boolean>();
                
                
                if(isOrder){
                    String qry = 'SELECT Id,Total_Tax__c,Tax__r.Tax_Rate__c,All_Total_Price__c,Order.Amount_Paid__c,Order.Coupon_Discount_Quantity__c ,Coupon__c,Base_Price__c,UnitPrice,Batch_Lot__c,Batch_Lot__r.Name,Serial__c,Discount_Amount__c,Serial__r.Name,Serial__r.Serial_No__c,Serial_Number__c ,OrderId,Order.Company__c,Order.Name , Order.Status ,Order.AccountId, ReturnedQuantity__c, Quantity, Product2Id ,Product2.Name, Product2.ProductCode,Product2.Serialise__c, Product2.Lot_Tracked__c FROM OrderItem WHERE Order.Status !=\'Cancelled\' AND Order.Is_Closed__c  = true AND Order.AccountId =: custId ';
                    if(String.isNotEmpty(ordId)) qry += ' AND OrderId =: ordId '; 
                    else if(prodIds.size() > 0) qry += ' AND Product2Id IN : prodIds ';
                    qry += '  Order By CreatedDate desc Limit 200 ';
                    
                    Map<Id,OrderItem> soliitemsMap = new  Map<Id,OrderItem>((List<OrderItem>)Database.query(qry));
                    if(soliitemsMap.keySet().size()>0){
                        system.debug('inside soliitemsMap.keySet().size()>0');
                        Map<Id,Id> soliMapSerial = new Map<Id,Id>();
                        for(RMA_Line_Item__c tempRMALI:[Select Id,Ord_Item__c, Serial_Number__c  FROM RMA_Line_Item__c WHERE Ord_Item__c IN : soliitemsMap.keySet() AND Serial_Number__c != null AND Product__r.Serialise__c = true]){
                            soliMapSerial.put(tempRMALI.Ord_Item__c,tempRMALI.Serial_Number__c);
                        }
                        system.debug('soliMapSerial~>'+soliMapSerial);
                        
                        for(Warranty__c warranty: [Select Id,Order_Product__c From Warranty__c Where Order_Product__c In: soliitemsMap.keySet()
                                                   And Valid_From__c <= Today And Valid_Till__c >= Today]){
                                                       soli_WarrantyMap.put(warranty.Order_Product__c,true);                                                          
                                                   }
                        
                        Map<Id,List<Stock_Outward_Line_Item__c>> rentalSOLI_Map = new Map<Id,List<Stock_Outward_Line_Item__c>>();
                        Map<Id,List<Stock_Outward_Line_Item__c>> batchSOLI_Map = new Map<Id,List<Stock_Outward_Line_Item__c>>();
                        
                        for (Stock_Outward_Line_Item__c soli : [SELECT Id, Order_Product__r.Product2.Lot_Tracked__c, Order_Product__r.Product2.Serialise__c, Fixed_Asset__c, Product__c ,Order_Product__c, Material_Batch_Lot__c, Material_Batch_Lot__r.Name, Serial__c ,Serial__r.Name, Serial__r.Serial_No__c ,Quantity__c FROM Stock_Outward_Line_Item__c  WHERE Order_Product__c in: soliitemsMap.keySet() and (Order_Product__r.Product2.Serialise__c = true or Order_Product__r.Product2.Lot_Tracked__c = true) and Status__c = 'Committed']){if(soli.Order_Product__r.Product2.Serialise__c){ List<Stock_Outward_Line_Item__c> templist = (rentalSOLI_Map.get(soli.Order_Product__c) != null)?rentalSOLI_Map.get(soli.Order_Product__c): new List<Stock_Outward_Line_Item__c>(); templist.add(soli); rentalSOLI_Map.put(soli.Order_Product__c,templist); } if(soli.Order_Product__r.Product2.Lot_Tracked__c){  List<Stock_Outward_Line_Item__c> templist = (batchSOLI_Map.get(soli.Order_Product__c) != null)?batchSOLI_Map.get(soli.Order_Product__c): new List<Stock_Outward_Line_Item__c>(); templist.add(soli);batchSOLI_Map.put(soli.Order_Product__c,templist); } }
                        
                        system.debug('rentalSOLI_Map~>'+rentalSOLI_Map);
                        
                        Boolean processit = false;
                        for(OrderItem so_Li:soliitemsMap.values()){
                            if(so_li.ReturnedQuantity__c == null)so_li.ReturnedQuantity__c =0.00;
                            if(so_Li.Product2.Serialise__c  &&  rentalSOLI_Map.get(so_Li.Id) != null){
                                for (Stock_Outward_Line_Item__c soli : rentalSOLI_Map.get(so_Li.Id)){
                                    processit = false;
                                    if(soliMapSerial.containsKey(so_Li.Id)){
                                        if(soli.Serial__c != null){
                                            if(soliMapSerial.get(so_Li.Id) != soli.Serial__c) processit = true;
                                        }else processit = true;
                                    }else processit = true;
                                    
                                    system.debug('processit~>'+processit);
                                    
                                    if(processit){
                                        RMA_Line_Item__c RMALI = new RMA_Line_Item__c(Is_Warranty_Exists__c =soli_WarrantyMap.containsKey(so_Li.Id),Base_Price__c = so_li.Base_Price__c  ,Sale_Price__c  = so_li.UnitPrice ,Acceptance_Type__c =defaultAcceptanceType,Return_Status__c=defaultReturnStatus,Product__c =so_li.Product2Id,Product__r = new Product2(Name = so_li.Product2.Name, ProductCode = so_li.Product2.ProductCode) , Ord_Item__c=so_li.id,Company__c = so_li.Order.Company__c,Name=so_li.Product2.Name,Quantity_Return__c=soli.Quantity__c,Return_Reason__c='');
                                        //RMALI.Total_Deduction__c= so_li.All_Total_Price__c;
                                        if(so_li.Total_Tax__c !=null) RMALI.Tax__c=so_li.Total_Tax__c/so_li.Quantity;
                                        // RMALI.Total_Deduction__c= (RMALI.Sale_Price__c*RMALI.Quantity_Return__c)+(RMALI.Tax__c*RMALI.Quantity_Return__c);   

                                         // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here

                                        if(soli.Serial__c != null){
                                            RMALI.Serial_Number__c = soli.Serial__c;
                                            RMALI.Serial_Number__r = new Serial_Number__c(Id=soli.Serial__c,Name=soli.Serial__r.Name,Serial_No__c=soli.Serial__r.Serial_No__c);
                                        }
                                        RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li,RMALI,soli_WarrantyMap.containsKey(so_Li.Id));
                                        RMAWrapperLIlist.add(temp_RMAWrapperLI);
                                    }
                                }
                                
                            }else if(!so_Li.Product2.Serialise__c){  decimal qty = double.valueof(so_li.Quantity - so_li.ReturnedQuantity__c); if(qty>0.00){  RMA_Line_Item__c RMALI =  new RMA_Line_Item__c(Is_Warranty_Exists__c =soli_WarrantyMap.containsKey(so_Li.Id),Batch_Lot__c = so_li.Batch_Lot__c, Serial_Number__c =so_li.Serial__c,Acceptance_Type__c =defaultAcceptanceType,Return_Status__c=defaultReturnStatus,Product__c =so_li.Product2Id , Product__r = new Product2(Name = so_li.Product2.Name, ProductCode = so_li.Product2.ProductCode) ,Ord_Item__c=so_li.id,Company__c = so_li.Order.Company__c,Name=so_li.Product2.Name,Quantity_Return__c=qty,Base_Price__c = so_li.Base_Price__c  ,Sale_Price__c  = so_li.UnitPrice,Return_Reason__c='');if(so_li.Total_Tax__c !=null){ RMALI.Tax__c=so_li.Total_Tax__c/so_li.Quantity;} /*RMALI.Total_Deduction__c= so_li.All_Total_Price__c;*/
                            // RMALI.Total_Deduction__c= (RMALI.Sale_Price__c*RMALI.Quantity_Return__c)+(RMALI.Tax__c*RMALI.Quantity_Return__c); 

                             // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here
                            
                            if(so_Li.Product2.Lot_Tracked__c &&  batchSOLI_Map.get(so_Li.Id) != null){ for(Stock_Outward_Line_Item__c soli : batchSOLI_Map.get(so_Li.Id)){  RMALI.Batch_Lot__c = soli.Material_Batch_Lot__c; RMALI.Batch_Lot__r = new Batch__c(Name = soli.Material_Batch_Lot__r.Name); } } RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li,RMALI,soli_WarrantyMap.containsKey(so_Li.Id)); RMAWrapperLIlist.add(temp_RMAWrapperLI); } }
                        } 
                    }else{
                        system.debug('soliitemsMap keyset not > 0');
                    }
                    
                    custinfo.RAMLI_List = RMAWrapperLIlist;                    
                }
                
            }
        }catch (Exception e){
            system.debug('Exp~>'+e.getMessage()+' at '+e.getStackTraceString());  throw new AuraHandledException(e.getMessage()+' :- '+e.getStackTraceString());
        }
        System.debug('custinfo -> '+custinfo);
        return custinfo;
    }
    /*@AuraEnabled
    global static sObj_Wrapper createRMA(String RMAobj, String RMALIs, Boolean isSalesOrder, Boolean isOrder){
        try{
            Return_Merchandise_Authorisation__c RMA = (Return_Merchandise_Authorisation__c)JSON.deserialize(RMAobj, Return_Merchandise_Authorisation__c.class);
            if (Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Active__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Active__c.isUpdateable())
                RMA.Active__c = true;
            if (Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Status__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Status__c.isUpdateable())
                RMA.Status__c = 'Initiated';
            list<RMAWrapperLI> RMA2Create = (List<RMAWrapperLI>)JSON.deserialize(RMALIs, List<RMAWrapperLI>.class);
            List<RMA_Line_Item__c> RMA_LI_2_Insert = new List<RMA_Line_Item__c>();
            if (Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isUpdateable())
                if (String.isEmpty(RMA.Order__c))
                    RMA.Order__c = null;
                if (Schema.sObjectType.Return_Merchandise_Authorisation__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.isUpdateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isUpdateable()){
                    upsert RMA;
            } else{
              
            }

            for (RMAWrapperLI temp : RMA2Create){
                if (temp.isfinalSelect){
                    if (Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isCreateable() || Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isUpdateable())
                        if (!(temp.RMALI.Return_Merchandise_Authorisation__c != null))
                            temp.RMALI.Return_Merchandise_Authorisation__c = RMA.Id;
                        if (Schema.sObjectType.RMA_Line_Item__c.fields.Amount_Paid__c.isCreateable() && Schema.sObjectType.RMA_Line_Item__c.fields.Amount_Paid__c.isUpdateable())
                            if (temp.OrdItem.OrderId != null)
                                temp.RMALI.Amount_Paid__c = (temp.OrdItem.Order.Amount_Paid__c >= temp.RMALI.Total_Deduction__c) ? temp.RMALI.Total_Deduction__c : temp.OrdItem.Order.Amount_Paid__c;
                            RMA_LI_2_Insert.add(temp.RMALI);
                        temp.RMALI.Serial_Number__r = null;
                    temp.RMALI.Product__r = null;
                    temp.RMALI.Batch_Lot__r = null;
                }
            }

            if (RMA_LI_2_Insert.size() > 0){
                if (Schema.sObjectType.RMA_Line_Item__c.isCreateable() && Schema.sObjectType.RMA_Line_Item__c.isUpdateable() && Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isCreateable() && Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isUpdateable()){
                    upsert RMA_LI_2_Insert;
                } else{
                   
                } 
            }
            PreventRecursiveLedgerEntry.testCasesTransactions = false;
            if (RMA.Id != null)
                return fetch_RMALI(RMA.Id, isSalesOrder, isOrder);
            else
                return fetch_RMALI('', isSalesOrder, isOrder);
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
}*/
    @AuraEnabled 
    global static sObj_Wrapper createRMA(String RMAobj,String RMALIs,Boolean isSalesOrder,Boolean isOrder){   
        try{
            Return_Merchandise_Authorisation__c  RMA = (Return_Merchandise_Authorisation__c)JSON.deserialize(RMAobj,Return_Merchandise_Authorisation__c.class);
            Boolean UpdateRMA =false;
            if(RMA.Authorize__c && RMA.Id == null) UpdateRMA=true; 
            System.debug('UpdateRMA '+UpdateRMA);
            if(Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Active__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Active__c.isUpdateable()) RMA.Active__c =true; 
            if(Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Status__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Status__c.isUpdateable()) RMA.Status__c='Initiated';
            list<RMAWrapperLI> RMA2Create = (List<RMAWrapperLI>)JSON.deserialize(RMALIs, List<RMAWrapperLI>.class);        
            List<RMA_Line_Item__c> RMA_LI_2_Insert = new List<RMA_Line_Item__c>();
            if(Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Order__c.isUpdateable()) if(String.isEmpty(RMA.Order__c)) RMA.Order__c = null;
            if(Schema.sObjectType.Return_Merchandise_Authorisation__c.isCreateable() && Schema.sObjectType.Return_Merchandise_Authorisation__c.isUpdateable()){ upsert RMA;  } else{/*no access to upsert */}
            
            for(RMAWrapperLI temp :RMA2Create){   
                if(temp.isfinalSelect){
                    if(Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isCreateable() || Schema.sObjectType.RMA_Line_Item__c.fields.Return_Merchandise_Authorisation__c.isUpdateable()) if(!(temp.RMALI.Return_Merchandise_Authorisation__c != null)) temp.RMALI.Return_Merchandise_Authorisation__c = RMA.Id;
                    
                    if(Schema.sObjectType.RMA_Line_Item__c.fields.Amount_Paid__c.isCreateable() && Schema.sObjectType.RMA_Line_Item__c.fields.Amount_Paid__c.isUpdateable()) if(temp.OrdItem.OrderId != null) temp.RMALI.Amount_Paid__c = (temp.OrdItem.Order.Amount_Paid__c >= temp.RMALI.Total_Deduction__c)?temp.RMALI.Total_Deduction__c:temp.OrdItem.Order.Amount_Paid__c;
                    //if(temp.RMALI.Tax__c != null) temp.RMALI.Tax__c = temp.RMALI.Quantity_Return__c * temp.RMALI.Tax__c;
                    RMA_LI_2_Insert.add(temp.RMALI);
                    temp.RMALI.Serial_Number__r = null;
                    temp.RMALI.Product__r = null;
                    temp.RMALI.Batch_Lot__r = null;
                }
            }
            
            if(RMA_LI_2_Insert.size()>0){
                if(Schema.sObjectType.RMA_Line_Item__c.isCreateable() && Schema.sObjectType.RMA_Line_Item__c.isUpdateable()) { upsert RMA_LI_2_Insert; } else{ /* not allowed*/ }
            }
            
            if(UpdateRMA== true) {
                PreventRecursiveLedgerEntry.testCasesTransactions  =false; update RMA;
            }
            //PreventRecursiveLedgerEntry.testCasesTransactions  =false;       
            if(RMA.Id != null)  return  fetch_RMALI(RMA.Id,isSalesOrder,isOrder); else return fetch_RMALI('',isSalesOrder,isOrder);
        }catch(Exception e){
            system.debug('Exp~>'+e.getMessage()+' at '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+' :- '+e.getStackTraceString());
        } 
    }
    
    /*@AuraEnabled
    global static sObj_Wrapper fetch_RMALI(String RMA_Id, Boolean isSalesOrder, Boolean isOrder){
        sObj_Wrapper obj = new sObj_Wrapper();
        try{
            if (String.isNotEmpty(RMA_Id)){
                List<RMAWrapperLI> RMALI_List = new List<RMAWrapperLI>();
                Set<Id> soli_ids = new set<Id>();
                Return_Merchandise_Authorisation__c RMA = [Select Id, Authorize__c, Is_Closed__c, Channel__c, Expected_Date__c, Site__c, Refund_Amount__c, Shipping_Amount__c, Shipping_Tax__c, ReStock_Tax__c, Freight_Type__c, Distribution_Channel__c, Total_Quantity__c, Status__c, Order__c, Order__r.Name, Name, Address__c, Address__r.Name, Account__c, Account__r.Name, Shipped_Quantity__c, Received_Quantity__c, Packed_Quantity__c, Return_Contact__c, Return_Contact__r.Name, Invoice__c, Invoice__r.Name, Restock_percentage__c, Restock_Fee__c, Special_Instructions__c
                                                           FROM Return_Merchandise_Authorisation__c
                                                           Where Id = :RMA_Id
                                                           WITH SECURITY_ENFORCED];
                Map<Id, Boolean> soli_WarrantyMap = new Map<Id, Boolean>();

                if (isOrder){
                    for (Warranty__c warranty : [Select Id, Order_Product__c
                                                 From Warranty__c
                                                 Where Order_Product__r.OrderId = :RMA.Order__c AND Order_Product__r.Product2.Is_Asset__c = false And Valid_From__c <= Today And Valid_Till__c >= Today
                                                 WITH SECURITY_ENFORCED]){
                        soli_WarrantyMap.put(warranty.Order_Product__c, true);
                    }
                }

                List<RMA_Line_Item__c> RMA_LI_2_upsert = new List<RMA_Line_Item__c>();
                Map<Id, OrderItem> orditemsMap = new Map<Id, OrderItem>();
                RMA_LI_2_upsert = [SELECT Id, Batch_Lot__c, Batch_Lot__r.Name, Return_Merchandise_Authorisation__r.Name, Return_Merchandise_Authorisation__r.Address__c, Return_Merchandise_Authorisation__r.Account__c, Return_Merchandise_Authorisation__c, Return_Merchandise_Authorisation__r.Site__c, Return_Merchandise_Authorisation__r.Return_Contact__c, Serial_Number__c, Serial_Number__r.Name, Acceptance_Type__c, Return_Status__c, Product__c, Product__r.Name, Product__r.ProductCode, Ord_Item__c, Company__c, Name, Quantity_Return__c, Total_Deduction__c, Return_Reason__c, Sale_Price__c, Base_Price__c, Is_Warranty_Exists__c, Shipped_Quantity__c, Packed_Quantity__c, Received_Quantity__c, Return_Quantity__c, Serial_Number__r.Serial_Number__c, Tax__c
                                   FROM RMA_Line_Item__c
                                   Where Return_Merchandise_Authorisation__c = :RMA_Id
                                   WITH SECURITY_ENFORCED];
                if (isOrder){
                    for (RMA_Line_Item__c temp : RMA_LI_2_upsert){
                        soli_ids.add(temp.Ord_Item__c);
                    }
                    orditemsMap = new Map<Id, OrderItem>([SELECT Id, Order.Amount_Paid__c, Order.Coupon_Discount_Quantity__c, Coupon__c, Batch_Lot__c, Batch_Lot__r.Name, Serial_Number__c, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, OrderId, Order.Company__c, Order.Name, Reserved_Quantity__c, Order.EffectiveDate, Order.Status, Order.AccountId, ReturnedQuantity__c, Quantity, Product2Id, Product2.Name, Product2.ProductCode
                                                          FROM OrderItem
                                                          WHERE Id IN:soli_ids
                                                          WITH SECURITY_ENFORCED]);
                    for (RMA_Line_Item__c temp : RMA_LI_2_upsert){
                        if (orditemsMap.containsKey(temp.Ord_Item__c)){
                            RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(orditemsMap.get(temp.Ord_Item__c), temp, soli_WarrantyMap.containsKey(temp.Ord_Item__c));
                            RMALI_List.add(temp_RMAWrapperLI);
                        }
                    }
                }

                obj.sObj = (Return_Merchandise_Authorisation__c)RMA;
                obj.RAMLI_List = RMALI_List;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + ' :- ' + e.getStackTraceString());
        }
        return obj;
    }*/
     @AuraEnabled   
    global static sObj_Wrapper fetch_RMALI(String RMA_Id,Boolean isSalesOrder,Boolean isOrder){
        sObj_Wrapper obj = new sObj_Wrapper();
        try{
            if(String.isNotEmpty(RMA_Id)){
                List<RMAWrapperLI> RMALI_List = new List<RMAWrapperLI>();
                Set<Id> soli_ids = new set<Id>();
                Return_Merchandise_Authorisation__c RMA = [Select Id,Authorize__c,Is_Closed__c,Channel__c,Expected_Date__c,Site__c,Refund_Amount__c,Shipping_Amount__c,Shipping_Tax__c, ReStock_Tax__c, Distribution_Channel__c,Total_Quantity__c,
                                                                 Status__c,Order__c,Order__r.Name,Name,Address__c,Address__r.Name,Account__c,Account__r.Name,Shipped_Quantity__c,Received_Quantity__c,Packed_Quantity__c,
                                                                 Return_Contact__c,Return_Contact__r.Name,Invoice__c,Invoice__r.Name, Restock_percentage__c,Restock_Fee__c,Special_Instructions__c FROM Return_Merchandise_Authorisation__c Where Id=:RMA_Id];
                Map<Id,Boolean> soli_WarrantyMap = new Map<Id,Boolean>();
                
                if(isOrder){ //if(RMA.Order__c != null){
                    for(Warranty__c warranty: [Select Id,Order_Product__c From Warranty__c Where Order_Product__r.OrderId =:RMA.Order__c AND Order_Product__r.Product2.Is_Asset__c = false
                                               And Valid_From__c <= Today And Valid_Till__c >= Today]){
                                                   soli_WarrantyMap.put(warranty.Order_Product__c,true);                                                          
                                               }
                }
                
                List<RMA_Line_Item__c> RMA_LI_2_upsert = new List<RMA_Line_Item__c>();
              
                Map<Id,OrderItem> orditemsMap = new  Map<Id,OrderItem>();
                RMA_LI_2_upsert = [SELECT Id,Batch_Lot__c,Batch_Lot__r.Name,Discount_Amount__c,Return_Merchandise_Authorisation__r.Name,Return_Merchandise_Authorisation__r.Address__c ,Return_Merchandise_Authorisation__r.Account__c,Return_Merchandise_Authorisation__c,
                                   Return_Merchandise_Authorisation__r.Site__c ,Return_Merchandise_Authorisation__r.Return_Contact__c,Serial_Number__c,Serial_Number__r.Name ,Acceptance_Type__c ,Return_Status__c,Product__c ,Product__r.Name,
                                   Product__r.ProductCode,Ord_Item__c,Company__c ,Name,Quantity_Return__c,Total_Deduction__c,Return_Reason__c ,Sale_Price__c,Base_Price__c,Is_Warranty_Exists__c,Shipped_Quantity__c,
                                   Packed_Quantity__c,Received_Quantity__c,Return_Quantity__c,Serial_Number__r.Serial_No__c,Tax__c FROM RMA_Line_Item__c Where Return_Merchandise_Authorisation__c =:RMA_Id];
               if(isOrder){ //if(RMA.Order__c != null){
                    for(RMA_Line_Item__c temp:RMA_LI_2_upsert){soli_ids.add(temp.Ord_Item__c);
                    }
                    orditemsMap = new  Map<Id,OrderItem>([SELECT Id,Order.Amount_Paid__c,Tax__r.Tax_Rate__c,Order.Coupon_Discount_Quantity__c ,Coupon__c,Batch_Lot__c,Batch_Lot__r.Name,Serial_Number__c,Serial__c,Serial__r.Name,Serial__r.Serial_Number__c,OrderId,Order.Organisation__c, Order.Name,Reserved_Quantity__c ,Order.EffectiveDate ,Order.Status ,Order.AccountId, ReturnedQuantity__c, Quantity, Product2Id , Product2.Name,Product2.ProductCode FROM OrderItem WHERE  Id IN: soli_ids]);
                    for(RMA_Line_Item__c temp:RMA_LI_2_upsert){ if(orditemsMap.containsKey(temp.Ord_Item__c)){  RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(orditemsMap.get(temp.Ord_Item__c),temp,soli_WarrantyMap.containsKey(temp.Ord_Item__c)); RMALI_List.add(temp_RMAWrapperLI); } }
                }
                
                obj.sObj = (Return_Merchandise_Authorisation__c)RMA;
                obj.RAMLI_List = RMALI_List;
            }
        }catch(Exception e){
            system.debug('Exp~>'+e.getMessage()+' at '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+' :- '+e.getStackTraceString());
        } 
        /*'RAMLI_List=>'+obj.RAMLI_List.size()+'  ,RAMLI_List=>'+obj.RAMLI_List*/
        return obj;
    }

    @AuraEnabled
    global static sObj_Wrapper Fetch_RMALI1(String So_Id){
        sObj_Wrapper obj = new sObj_Wrapper();
        try{
            String defaultAcceptanceType;
            String defaultReturnStatus;
            for (Schema.PicklistEntry av : RMA_Line_Item__c.Acceptance_Type__c.getDescribe().getPicklistValues())
                if (av.isDefaultValue()){
                    defaultAcceptanceType = av.getValue();
                break;
            }
            for (Schema.PicklistEntry av : RMA_Line_Item__c.Return_Status__c.getDescribe().getPicklistValues())
                if (av.isDefaultValue()){
                    defaultReturnStatus = av.getValue();
                break;
            }


            if (!String.isBlank(So_Id)){
                Order so = [SELECT Id, Name, AccountId, Channel__c, Account.Name, Contact__c, Contact__r.Name, Ship_To_Address__c, Ship_To_Address__r.Name, Expected_Date__c
                            FROM Order
                            Where Id = :So_Id
                            WITH SECURITY_ENFORCED];
                List<RMAWrapperLI> RMAWrapperLIlist = new List<RMAWrapperLI>();
                Map<Id, Boolean> soli_WarrantyMap = new Map<Id, Boolean>();
                Map<Id, OrderItem> soliitemsMap = new Map<Id, OrderItem>();

                for (Warranty__c warranty : [Select Id, Order_Product__c
                                             From Warranty__c
                                             Where Order_Product__r.OrderId = :So_Id AND Order_Product__r.Product2.Is_Asset__c = false And Valid_From__c <= Today And Valid_Till__c >= Today
                                             WITH SECURITY_ENFORCED]){
                    soli_WarrantyMap.put(warranty.Order_Product__c, true);
                }
                soliitemsMap = new Map<Id, OrderItem>([SELECT Id, Order.Amount_Paid__c, Order.Coupon_Discount_Quantity__c, Coupon__c, Other_Tax__c, Tax__r.Tax_Rate__c,All_Total_Price__c, VAT_Amount__c, Discount_Amount__c, Base_Price__c, Batch_Lot__c, Batch_Lot__r.Name, Serial_Number__c, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, OrderId, Order.Company__c, Order.Name, Reserved_Quantity__c, Order.Account.Name, Order.EffectiveDate, Order.Status, Order.AccountId, Order.Contact__c, Order.Ship_To_Address__c, ReturnedQuantity__c, Quantity, Product2Id, Product2.Serialise__c, Product2.Name, Product2.ProductCode, UnitPrice, Total_Price__c
                                                       FROM OrderItem
                                                       WHERE OrderId = :So_Id
                                                       WITH SECURITY_ENFORCED]);
                set<Id> soliMapSerial = new Set<Id>();
                for (RMA_Line_Item__c tempRMALI : [Select Id, Ord_Item__c, Serial_Number__c
                                                   FROM RMA_Line_Item__c
                                                   WHERE Ord_Item__c IN:soliitemsMap.keySet() AND Serial_Number__c != null AND Product__r.Serialise__c = true
                                                   WITH SECURITY_ENFORCED]){
                    soliMapSerial.add(tempRMALI.Serial_Number__c);
                }

                Map<Id, List<Stock_Outward_Line_Item__c>> rentalSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
                IF (soliitemsMap.keySet().SIZE() > 0)
                    for (Stock_Outward_Line_Item__c soli : [SELECT Id, Fixed_Asset__c, Product__c, Order_Product__c, Order_Product__r.Product2.Name, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, Quantity__c
                                                            FROM Stock_Outward_Line_Item__c
                                                            WHERE Order_Product__c in:soliitemsMap.keySet() AND Order_Product__r.Product2.Serialise__c = true AND Status__c = 'Committed'
                                                            WITH SECURITY_ENFORCED]){
                        List<Stock_Outward_Line_Item__c> templist = (rentalSOLI_Map.get(soli.Order_Product__c) != null) ? rentalSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                    templist.add(soli);
                    rentalSOLI_Map.put(soli.Order_Product__c, templist);

                }
                for (OrderItem so_Li : soliitemsMap.values()){
                    decimal taxAmount_perQty = ((so_Li.Other_Tax__c + so_Li.VAT_Amount__c) > 0) ? (so_Li.Other_Tax__c + so_Li.VAT_Amount__c) / so_Li.Quantity : 0.00;

                    /*Unit Price is calculated with Discount */
                    //decimal unitAmount_perQty = (so_Li.Total_Price__c >0)?(so_Li.Total_Price__c)/so_Li.Quantity:0.00;
                    decimal unitAmount_perQty = (so_Li.Total_Price__c > 0) ? so_Li.UnitPrice : 0.00;
                    unitAmount_perQty -= so_Li.Order.Coupon_Discount_Quantity__c;
                    if (so_li.ReturnedQuantity__c == null)
                        so_li.ReturnedQuantity__c = 0.00;
                    if (so_Li.Product2.Serialise__c && rentalSOLI_Map.get(so_Li.Id) != null){
                        for (Stock_Outward_Line_Item__c soli : rentalSOLI_Map.get(so_Li.Id)){
                            if (!soliMapSerial.contains(soli.Serial__c)){
                                RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                    Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                    Base_Price__c = so_li.Base_Price__c, 
                                    Total_Deduction__c = so_li.All_Total_Price__c, 
                                    Acceptance_Type__c = defaultAcceptanceType, 
                                    Return_Status__c = defaultReturnStatus, 
                                    Ord_Item__c = so_li.id, 
                                    Company__c = so_li.Order.Company__c, 
                                    Name = so_li.Product2.Name, 
                                    Quantity_Return__c = soli.Quantity__c, 
                                    Tax__c = taxAmount_perQty, 
                                    Sale_Price__c = unitAmount_perQty, 
                                    Return_Reason__c = ''
                                );

                                RMALI.Serial_Number__c = soli.Serial__c;
                                RMALI.Serial_Number__r = new Serial_Number__c(
                                    Id = soli.Serial__c, 
                                    Name = soli.Serial__r.Name, 
                                    Serial_Number__c = soli.Serial__r.Serial_Number__c
                                );
                                if (so_li.Batch_Lot__c != null){ RMALI.Batch_Lot__c = so_li.Batch_Lot__c; RMALI.Batch_Lot__r = new Batch__c( Name = so_li.Batch_Lot__r.Name ); }
                                if (soli.Fixed_Asset__c != null)
                                    RMALI.Fixed_Asset__c = soli.Fixed_Asset__c;
                                else{
                                    RMALI.Product__c = soli.Product__c;
                                    RMALI.Product__r = new Product2(
                                        Name = so_li.Product2.Name, 
                                        ProductCode = so_li.Product2.ProductCode
                                    );
                                }
                                /*'so_Li.Serial__r '+so_Li.Serial__r.Name*/
                                RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                RMAWrapperLIlist.add(temp_RMAWrapperLI);
                            }
                        }

                    } else if (!so_Li.Product2.Serialise__c){
                        decimal qty = double.valueof(so_li.Quantity - so_li.ReturnedQuantity__c);
                        if (qty > 0.00){
                            RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                Batch_Lot__c = so_li.Batch_Lot__c, 
                                Serial_Number__c = so_li.Serial__c, 
                                Acceptance_Type__c = defaultAcceptanceType, 
                                Return_Status__c = defaultReturnStatus, 
                                Product__c = so_li.Product2Id, 
                                Product__r = new Product2(
                                    Name = so_li.Product2.Name, 
                                    ProductCode = so_li.Product2.ProductCode
                                ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = qty, Base_Price__c = so_li.Base_Price__c, Total_Deduction__c = so_li.All_Total_Price__c, Tax__c = taxAmount_perQty, Sale_Price__c = unitAmount_perQty, Return_Reason__c = ''
                            );
                            if (so_li.Serial__c != null){ RMALI.Serial_Number__c = so_li.Serial__c; RMALI.Serial_Number__r = new Serial_Number__c( Id = so_li.Serial__c,   Name = so_li.Serial__r.Name,  Serial_Number__c = so_li.Serial__r.Serial_Number__c ); }
                            if (so_li.Batch_Lot__c != null){
                                RMALI.Batch_Lot__c = so_li.Batch_Lot__c;
                                RMALI.Batch_Lot__r = new Batch__c(
                                    Name = so_li.Batch_Lot__r.Name
                                );
                            }
                            RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                            RMAWrapperLIlist.add(temp_RMAWrapperLI);
                        }
                    }
                }
                obj.sObj = (Order) so;
                obj.RAMLI_List = RMAWrapperLIlist;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage() + '; at line ~> ' + e.getLineNumber());
        }
        return obj;
    }

    @AuraEnabled
    global static sObj_Wrapper Fetch_RMALIByInvoice(String InvoiceId){
        sObj_Wrapper obj = new sObj_Wrapper();
        try{
            String defaultAcceptanceType;
            String defaultReturnStatus;
            for (Schema.PicklistEntry av1 : RMA_Line_Item__c.Acceptance_Type__c.getDescribe().getPicklistValues())
                if (av1.isDefaultValue()){
                    defaultAcceptanceType = av1.getValue();
                break;
            }
            for (Schema.PicklistEntry av : RMA_Line_Item__c.Return_Status__c.getDescribe().getPicklistValues())
                if (av.isDefaultValue()){
                    defaultReturnStatus = av.getValue();
                break;
            }


            if (!String.isBlank(InvoiceId)){
                Invoice__c Inv = [SELECT Id, Name, Account__c, Contact__c, Order_S__c, Order_S__r.Channel__c, Account__r.Name, Order_S__r.Contact__c, Order_S__r.Contact__r.Name, Order_S__r.Ship_To_Address__c, Order_S__r.Ship_To_Address__r.Name, Order_S__r.Name, Order_S__r.Expected_Date__c
                                  FROM Invoice__c
                                  Where Id = :InvoiceId
                                  WITH SECURITY_ENFORCED
                                  Limit 1];
                List<RMAWrapperLI> RMAWrapperLIlist = new List<RMAWrapperLI>();
                Map<Id, Boolean> soli_WarrantyMap = new Map<Id, Boolean>();
                Map<Id, OrderItem> soliitemsMap = new Map<Id, OrderItem>();
                List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
                set<Id> soliIds = new set<Id>();
                for (Warranty__c warranty : [Select Id, Order_Product__c
                                             From Warranty__c
                                             Where Order_Product__r.Invoice__c = :InvoiceId And Valid_From__c <= Today And Valid_Till__c >= Today
                                             WITH SECURITY_ENFORCED]){
                    soli_WarrantyMap.put(warranty.Order_Product__c, true);
                }
                invoiceLineItems = [SELECT Id, Invoice__c, Name, Discount_Amount__c, Other_Tax__c, Product__c, Product__r.Serialise__c, Quantity__c, Return_Quantity__c, Order_Product__c, Base_Price__c, Total_Price__c, VAT_Amount__c, Unit_Price__c
                                    FROM Invoice_Line_Item__c
                                    WHERE Invoice__c = :InvoiceId
                                    WITH SECURITY_ENFORCED];
                for (Invoice_Line_Item__c invli : invoiceLineItems){
                    if (invli.Return_Quantity__c == null){
                        invli.Return_Quantity__c = 0.00;
                    }
                    if ((invli.Quantity__c - invli.Return_Quantity__c) > 0.00){
                        soliIds.add(invli.Order_Product__c);
                    }
                }
                soliitemsMap = new Map<Id, OrderItem>([SELECT Id, Other_Tax__c, Tax__r.Tax_Rate__c,Order.Amount_Paid__c, Order.Coupon_Discount_Quantity__c, Coupon__c, VAT_Amount__c, Discount_Amount__c, Base_Price__c, Batch_Lot__c, Batch_Lot__r.Name, Serial_Number__c, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, OrderId, Order.Company__c, Order.Name, Reserved_Quantity__c, Order.Account.Name, Order.EffectiveDate, Order.Status, Order.AccountId, Order.Contact__c, Order.Ship_To_Address__c, ReturnedQuantity__c, Quantity, Product2Id, Product2.Serialise__c, Product2.Name, Product2.ProductCode, Total_Price__c
                                                       FROM OrderItem
                                                       WHERE Id IN:soliIds
                                                       WITH SECURITY_ENFORCED]);
                set<Id> soliMapSerial = new Set<Id>();
                for (RMA_Line_Item__c tempRMALI : [Select Id, Ord_Item__c, Serial_Number__c
                                                   FROM RMA_Line_Item__c
                                                   WHERE Ord_Item__c IN:soliitemsMap.keySet() AND Serial_Number__c != null AND Product__r.Serialise__c = true
                                                   WITH SECURITY_ENFORCED]){
                    soliMapSerial.add(tempRMALI.Serial_Number__c);
                }
                Map<Id, List<Stock_Outward_Line_Item__c>> rentalSOLI_Map = new Map<Id, List<Stock_Outward_Line_Item__c>>();
                if (soliitemsMap.keySet().SIZE() > 0)
                    for (Stock_Outward_Line_Item__c soli : [SELECT Id, Fixed_Asset__c, Product__c, Order_Product__c, Serial__c, Serial__r.Name, Serial__r.Serial_Number__c, Quantity__c
                                                            FROM Stock_Outward_Line_Item__c
                                                            WHERE Order_Product__c in:soliitemsMap.keySet() AND Order_Product__r.Product2.Serialise__c = true AND Status__c = 'Committed'
                                                            WITH SECURITY_ENFORCED]){
                        List<Stock_Outward_Line_Item__c> templist = (rentalSOLI_Map.get(soli.Order_Product__c) != null) ? rentalSOLI_Map.get(soli.Order_Product__c) : new List<Stock_Outward_Line_Item__c>();
                    templist.add(soli);
                    rentalSOLI_Map.put(soli.Order_Product__c, templist);
                }
                for (Invoice_Line_Item__c invli : invoiceLineItems){
                    OrderItem so_li = soliitemsMap.get(invli.Order_Product__c);
                    if (so_Li != null){
                        decimal taxAmount_perQty = ((invli.Other_Tax__c != null && invli.VAT_Amount__c != null) && (invli.Other_Tax__c + invli.VAT_Amount__c) > 0) ? (invli.Other_Tax__c + invli.VAT_Amount__c) / invli.Quantity__c : 0.00;
                        //Product Coupon Discount is calculated
                        decimal DiscountAmount_perQty = (so_li.Coupon__c != null && SO_li.Quantity != null && so_li.Coupon__c > 0) ? (so_li.Coupon__c) / SO_li.Quantity : 0.00;
                        //Unit Price is calculated with Discount
                        //decimal unitAmount_perQty = (invli.Total_Price__c >0)?(invli.Total_Price__c)/invli.Quantity__c:0.00;
                        decimal unitAmount_perQty = (invli.Total_Price__c > 0) ? invli.Unit_Price__c : 0.00;
                        unitAmount_perQty -= DiscountAmount_perQty;
                        unitAmount_perQty -= so_Li.Order.Coupon_Discount_Quantity__c;
                        if (invli.Return_Quantity__c == null)
                            invli.Return_Quantity__c = 0.00;
                        if (invli.Product__r.Serialise__c && rentalSOLI_Map.get(invli.Order_Product__c) != null){
                            for (Stock_Outward_Line_Item__c soli : rentalSOLI_Map.get(invli.Order_Product__c)){
                                if (!soliMapSerial.contains(soli.Serial__c)){
                                    RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                        Invoice_Line_Item__c = invli.Id, 
                                        Sale_Price__c = unitAmount_perQty, 
                                        Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                        Base_Price__c = invli.Base_Price__c, 
                                        Acceptance_Type__c = defaultAcceptanceType, 
                                        Return_Status__c = defaultReturnStatus, 
                                        Ord_Item__c = so_li.id, 
                                        Company__c = so_li.Order.Company__c, 
                                        Name = so_li.Product2.Name, 
                                        Quantity_Return__c = soli.Quantity__c, 
                                        Tax__c = taxAmount_perQty, 
                                        Return_Reason__c = ''
                                    );
                                    //RMALI.Total_Deduction__c= invli.Total_Price__c;
                                    // RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);
                                     // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here

                                    RMALI.Serial_Number__c = soli.Serial__c;
                                    RMALI.Serial_Number__r = new Serial_Number__c(
                                        Id = soli.Serial__c, 
                                        Name = soli.Serial__r.Name, 
                                        Serial_Number__c = soli.Serial__r.Serial_Number__c
                                    );
                                    if (so_li.Batch_Lot__c != null){ RMALI.Batch_Lot__c = so_li.Batch_Lot__c; RMALI.Batch_Lot__r = new Batch__c( Name = so_li.Batch_Lot__r.Name ); }
                                    if (soli.Fixed_Asset__c != null)
                                        RMALI.Fixed_Asset__c = soli.Fixed_Asset__c;
                                    else{
                                        RMALI.Product__c = soli.Product__c;
                                        RMALI.Product__r = new Product2(
                                            Name = so_li.Product2.Name, 
                                            ProductCode = so_li.Product2.ProductCode
                                        );
                                    }
                                    RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                    RMAWrapperLIlist.add(temp_RMAWrapperLI);
                                }
                            }

                        } else if (!so_Li.Product2.Serialise__c){
                            decimal qty = double.valueof(invli.Quantity__c - invli.Return_Quantity__c);
                            if (qty > 0.00){
                                RMA_Line_Item__c RMALI = new RMA_Line_Item__c(
                                    Invoice_Line_Item__c = invli.Id, 
                                    Sale_Price__c = unitAmount_perQty, 
                                    Is_Warranty_Exists__c = soli_WarrantyMap.containsKey(so_Li.Id), 
                                    Batch_Lot__c = so_li.Batch_Lot__c, 
                                    Serial_Number__c = so_li.Serial__c, 
                                    Acceptance_Type__c = defaultAcceptanceType, 
                                    Return_Status__c = defaultReturnStatus, 
                                    Product__c = invli.Product__c, 
                                    Product__r = new Product2(
                                        Name = so_li.Product2.Name, 
                                        ProductCode = so_li.Product2.ProductCode
                                    ), Ord_Item__c = so_li.id, Company__c = so_li.Order.Company__c, Name = so_li.Product2.Name, Quantity_Return__c = qty, Base_Price__c = invli.Base_Price__c, Tax__c = taxAmount_perQty, Return_Reason__c = ''
                                );
                                //RMALI.Total_Deduction__c=invli.Total_Price__c;
                                // RMALI.Total_Deduction__c = (RMALI.Sale_Price__c * RMALI.Quantity_Return__c) + (RMALI.Tax__c * RMALI.Quantity_Return__c);

                                 // added by abuzar for the GIIH 1020 to sub the discount from the Total_Deduction__c
                               
                                // Calculate total sale price and tax
Decimal totalSalePrice = RMALI.Sale_Price__c * RMALI.Quantity_Return__c;
Decimal totalTax = RMALI.Tax__c * RMALI.Quantity_Return__c;

// Avoid division by zero
// Decimal discountPerUnit = 0;
// if (RMALI.OrdItem != null && RMALI.OrdItem.Quantity != 0) {
//     discountPerUnit = RMALI.OrdItem.Discount_Amount__c != null && RMALI.OrdItem.Discount_Amount__c != 0  ? RMALI.OrdItem.Discount_Amount__c / RMALI.OrdItem.Quantity : 0;
// }

// // Calculate total discount for returned qty
// Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;

// // Final Total Deduction
// RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;

Decimal discountPerUnit = 0;
if (so_Li != null && so_Li.Quantity != 0) {
    discountPerUnit = (so_Li.Discount_Amount__c != null && so_Li.Discount_Amount__c != 0) 
        ? so_Li.Discount_Amount__c / so_Li.Quantity : 0;
}
Decimal totalDiscount = discountPerUnit * RMALI.Quantity_Return__c;
RMALI.Total_Deduction__c = (totalSalePrice + totalTax) - totalDiscount;


//Changes  by ABuzar Ends here
                                if (so_li.Serial__c != null){ RMALI.Serial_Number__c = so_li.Serial__c; RMALI.Serial_Number__r = new Serial_Number__c(Id = so_li.Serial__c, Name = so_li.Serial__r.Name,  Serial_Number__c = so_li.Serial__r.Serial_Number__c); }
                                if (so_li.Batch_Lot__c != null){  RMALI.Batch_Lot__c = so_li.Batch_Lot__c; RMALI.Batch_Lot__r = new Batch__c(Name = so_li.Batch_Lot__r.Name  ); }
                                RMAWrapperLI temp_RMAWrapperLI = new RMAWrapperLI(so_Li, RMALI, soli_WarrantyMap.containsKey(so_Li.Id));
                                RMAWrapperLIlist.add(temp_RMAWrapperLI);
                            }
                        }
                    }
                }
                obj.sObj = (Invoice__c)Inv;
                obj.RAMLI_List = RMAWrapperLIlist;
            }
        } catch (Exception e){throw new AuraHandledException(e.getMessage() + '; at line ~> ' + e.getLineNumber());
        }
        return obj;
    }

    @AuraEnabled
    global static void DeleteByRMALIId(String recordData){
        RMA_Line_Item__c rmali_2_Delete = (RMA_Line_Item__c)JSON.deserialize(recordData, RMA_Line_Item__c.class);
        if (RMA_Line_Item__c.sObjectType.getDescribe().isDeletable()){
            delete rmali_2_Delete;
        } else{
            /* no access to delete*/
        }
    }

    @AuraEnabled
    global static Map<String, Boolean> getCRUD(){
        Map<String, Boolean> crudValues = new Map<String, Boolean>();
        crudValues.put('PO__c', Schema.sObjectType.PO__c.isAccessible());
        crudValues.put('WO__c', Schema.sObjectType.WO__c.isAccessible());
        crudValues.put('Is_Closed__c', Schema.sObjectType.Return_Merchandise_Authorisation__c.fields.Is_Closed__c.isAccessible());
        return crudValues;
    }

    global class sObj_Wrapper{
        @AuraEnabled
        global sObject sObj{ get; set; }

        @AuraEnabled
        global List<RMAWrapperLI> RAMLI_List{ get; set; }

        global sObj_Wrapper(){
            RAMLI_List = new List<RMAWrapperLI>();
        }

    }

    global class customerInfo{
        @AuraEnabled
        global Contact contact{ get; set; }

        @AuraEnabled
        global Address__c Address{ get; set; }
        @AuraEnabled
        global List<RMAWrapperLI> RAMLI_List{ get; set; }

        global customerInfo(){
            contact = new Contact();
            Address = new Address__c();
            RAMLI_List = new List<RMAWrapperLI>();
        }

    }

    global class RMAWrapperLI{
        @AuraEnabled
        global Boolean isSelect{ get; set; }

        @AuraEnabled
        global Boolean isfinalSelect{ get; set; }

        @AuraEnabled
        global RMA_Line_Item__c RMALI{ get; set; }

        @AuraEnabled
        global OrderItem OrdItem{ get; set; }

        @AuraEnabled
        global Boolean isWarranty_Exists{ get; set; }

        @AuraEnabled
        global Decimal returnQty{ get; set; }

        @AuraEnabled
        global String reasonReason{ get; set; }

        @AuraEnabled
        global String accepType{ get; set; }

        global RMAWrapperLI(OrderItem SOLI, RMA_Line_Item__c RMALI, Boolean isWarranty_Exists){
            isSelect = isfinalSelect = false;
            this.OrdItem = SOLI;
            this.RMALI = RMALI;
            this.isWarranty_Exists = isWarranty_Exists;
            returnQty = 0.0;
            reasonReason = accepType = '';
        }

    }

}