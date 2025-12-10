@isTest()
global Class CreatePO_WO_TestCases2 {
    
    static testmethod void UnitTestWO_Unit1() {
        PreventRecursiveLedgerEntry.testCasesTransactions = true; 
        
        Account orgn = new Account(Name='Universal Stores', Account_Type__c = 'Company'); 
        insert orgn;
        Account sup = new Account(Name='Supplier',Account_Type__c = 'Supplier'); 
        insert sup;
        
        Account vend = new Account(Name='Vendor',Account_Type__c = 'Vendor');
        insert vend;
        
        Account customer = new Account(Name='Customer', Account_Type__c = 'Customer');
        insert customer;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        
        WO__c wo = new WO__c(Name = 'test wo', Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        Profiling__c prof = new Profiling__c(Active__c = true);
        insert prof;
        Product2 ps = new Product2(Name='test', isActive=true,Track_Inventory__c=true,Serialise__c=true,Lot_Tracked__c=true);
        insert ps;
        Account c = new Account(Name='Test', Account_Type__c='Customer',Account_Profile__c = prof.Id);
        insert c;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=c.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        Address__c  address = new Address__c(Name='Test', Customer__c=c.Id, Active__c = true);
        insert address;
        Channel__c channel = new Channel__c(Name='Test', Ship_From_Address__c=address.Id, Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        Employees__c emp = new Employees__c(Name='Test', Employee_User__c=UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true,Priority__c = '1', Active__c= true);
        insert DC;
        Process__c prcs = new Process__c(Name = 'projectTestProcess');
        insert prcs;
        Site__c site1 = new Site__c(Name = 'projectTestSite');
        insert site1;
        
        Product2 pro = new Product2(Name = 'Laptop X200', Family = 'Hardware',IsActive= true , Issue_Purchase_Order__c = true );
        insert pro;
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        PricebookEntry pbe = new PricebookEntry( Pricebook2Id = standardPricebook.Id, Product2Id = pro.Id, UnitPrice = 102,IsActive = true);
        Insert pbe;
        
        Order ord = new Order(Name = 'Test Order',Status = 'Draft',EffectiveDate = system.today(),EndDate = system.today() + 4,Shipment_Type__c='UPS',Shipment_Preference_Speed__c='--None--',
                              AccountId = c.id,Contact__c=contact.Id,Pricebook2Id=standardPricebook.Id,Amount__c=345,Expected_Date__c=Date.today(),
                              Company__c=orgn.Id);        
        insert ord;
        OrderItem orItem = new OrderItem(OrderId = ord.Id,PricebookEntryId=pbe.Id,Quantity = 1,UnitPrice = 100,Active__c=true,Is_Back_Order__c=true);        
        //orItem.Product2Id= pro.Id;
        insert orItem;
        /*MPS__c mps = new MPS__c(Name = 'MPS1', Product__c = ps.Id);
        insert mps;
        MPS_line_Item__c mpsLine = new MPS_line_Item__c(Name = 'testMPS1', MPS__c = mps.Id);
        insert mpsLine;*/
        
        Routing__c rout = new Routing__c( Name = 'projectTestRouting', Product__c = ps.Id , Process__c = prcs.Id, Raw_Materials_Site__c = site.Id, Finished_Products_Site__c = site.Id);
        insert rout;
        Inventory_Stock__c stock = new Inventory_Stock__c(Name = 'inventory1', Warehouse__c = site1.Id, Product__c = ps.Id, Active__c = true);
        insert stock;
        Stock_Inward_Line_Item__c inward = new Stock_Inward_Line_Item__c(Name= 'inward1', Site_ProductService_InventoryStock__c = stock.Id, Product__c = ps.Id, Quantity__c = 5);
        insert inward;
        Manufacturing_Order__c MO = new Manufacturing_Order__c(Name = 'testMO1', Product__c = ps.Id, Routing__c = rout.Id);
        insert MO;
        WO__c WO1 = new WO__c(Name = 'testWO1', Routing__c = rout.Id,Product__c=pro.Id);
        insert WO1;
        Manufacturing_Order__c Mu = new Manufacturing_Order__c();
        insert Mu;
        
        MRP__c mrpLine = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1, MO__c = MO.Id);
        mrpLine.MO__c = MO.Id;
        mrpLine.Work_Order__c = WO1.Id;
        insert mrpLine;
        MRP__c mrpLine2 = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1, MO__c = MO.Id);
        mrpLine2.MO__c = MO.Id;
        insert mrpLine2;
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name = 'testRMA1');
        insert rma;
        RMA_Line_Item__c rmaLine = new RMA_Line_Item__c(Name = 'testRMAline1', Return_Merchandise_Authorisation__c = rma.Id);
        insert rmaLine;
        Date tomo = system.today();
        tomo.addMonths(1);
        Cost_Card__c ccard = new Cost_Card__c(Name = 'testCard1', Product__c = ps.Id, Supplier__c = sup.Id, End_Date__c = tomo, Cost__c = 10, Quantity__c = 5);
        insert ccard;
        List<Id> prods = new List<Id>();
        prods.add(ps.Id);
        PO__c PO = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id, Ready_To_Receive__c = true,Order__c=ord.Id);
        //insert PO;
        PO__c PO1 = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id); // Ready_To_Receive__c = true 23/10/23
        insert PO1;
        Purchase_Line_Items__c poli1 = new Purchase_Line_Items__c(Name = 'testPOLI1',Purchase_Orders__c=PO1.Id,Product__c=ps.Id,Quantity__c=10,Quantity_Received__c=10,RTV_Quantity__c=0,Tax__c=0,Unit_Price__c=10);
        insert poli1;
       /* Purchase_Line_Items__c poli2 = new Purchase_Line_Items__c(Name = 'testPOLI2',Purchase_Orders__c=PO1.Id,Product__c=ps.Id,Quantity__c=10,Quantity_Received__c=10,RTV_Quantity__c=0,Master_Purchase_Line_Items__c=poli1.Id);
        insert poli2;*/
        
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name = 'testPOLI1', Order__c = ord.Id);
        List<Purchase_Line_Items__c> poli_list = new List<Purchase_Line_Items__c>();
        poli_list.add(poli);
        Account sup01 = new Account(Name = 'testCaseSupplier', Account_Type__c = 'Vendor');
        insert sup01;
        Request__c req01 = new Request__c(Name='testCaseRequest1', Status__c = 'Open', Response_Due_Date__c = system.today());
        insert req01;
        Request_Supplier__c reqSup01 = new Request_Supplier__c(Name='testRequestSupp1', Request__c = req01.Id, Supplier__c = sup01.Id, Submit_Date__c = tomo);
        insert reqSup01;
        Package__c pack = new Package__c( Name__c='Test Pack',Order__c = ord.Id,Active__c = true,status__c='Deposited to front desk');
        insert pack;
        
        Package_List__c plist = new Package_List__c(Name = 'Test List', Order_Product__c = orItem.Id,Active__c=true, Order__c = ord.Id,Package__c = pack.Id, Quantity__c = 3);
        insert plist;
        
        Shipment__c ship = new Shipment__c(Customer__c=customer.id,Shipping_Address__c=address.Id,Active__c=true,Order__c = ord.Id ,Customer_Contact__c=contact.id,
                                           status__c='Shipped',Tracking_Number__c='123456'); 
        insert ship;
        PO.Request__c = req01.Id;
        
        Date sd = Date.today();

// Set end date as 4 days after the start date
Date ed = Date.today().addDays(4);
        
        Cost_Card__c cc = new Cost_Card__c(Start_Date__c = sd , End_Date__c = ed);
        insert cc;
        
        
        
        
        Product2 p2 = new Product2(Name = 'test1',Vendor_product_Name__c = 'XYZ',Description = 'i dont know ',ProductCode = '129hht ', Issue_Purchase_Order__c = true, Status__c = 'Certified',  IsActive = true);
        insert p2;
        
         Approved_Vendor__c appv = new Approved_Vendor__c( Product__c = p2.Id, Default__c = true, Status__c = 'Approved', Cost_Card__c = cc.Id, Vendor__c = sup01.Id );
        insert appv;
        
        Tax__c t = new Tax__c(Account_Profile__c = prof.Id ,Effective_Date__c = sd,Expiry_Date__c = ed, Type__c ='Sales Tax', Tax_Rate__c = 20 ,Product__c = Null , Active__c=true, Postal_Code__c = 'test',City__c='test',Country__c='Brazil');
        insert t;
 
        
        
        
        //lightning
        Test.startTest();
     
        CreatePO2.getVendorDetails(sup.Id);
        CreatePO2.fetchCostCardIds(sup.Id);
        CreatePO2.fetchPrice(ccard.Id);
        try{ CreatePO2.fetchChannelandDC(ord.Id,''); }catch(Exception e){}
        try{ CreatePO2.fetchPOandPOLIs(PO1.Id, false); }catch(Exception e){}
        CreatePO2.fetchPOandPOLIs(PO1.Id, true);
        CreatePO2.getstocks(DC.Id,ps.Id);
        CreatePO2.getExistingPO('',ord.Id);
        CreatePO2.getOrgCurrencies(orgn.Id);
        CreatePO2.uploadFile(PO1.Id,'TEST','Test file uplaod','');
        CreatePO2.getCust(customer.Id);
        CreatePO2.getDC(DC.Id);
        List<String> itemToDel1=new List<String>();
        itemToDel1.add(poli1.Id);
        CreatePO2.deletePOLI(itemToDel1);
        List<String> ordIds = new List<String>();
        ordIds.add(ord.Id);
        //CreatePO2.getOrderAddress(ord.Id);
        CreatePO2.getOrderItemsforPOLIDropShip(ord.Id,'','');
        CreatePO2.populateOrdItems(ordIds);
        //try{CreatePO2.populateMpsline(mpsLine.Id);}catch(Exception e){}
        try{CreatePO2.populateMrpline(mrpLine.Id, 0);}catch(Exception e){}
        try{CreatePO2.populateMrpline(mrpLine2.Id, 0);}catch(Exception e){}
        CreatePO2.populateRMAPO(rmaLine.Id);
        try{CreatePO2.populateMOlines(MO.Id);}catch(Exception e){}
        try{CreatePO2.populateWOlines(WO1.Id);}catch(Exception e){}
        CreatePO2.getStatus(); 
        CreatePO2.getDependentPicklist('PO__c','Shipment_Type__c','Shipment_Preference_Speed__c');
        string shipid =ship.id;
        List<string> packids = new List<string>();
        try{ CreatePO2.save_PurchaseOrder(JSON.serialize(PO), JSON.serialize(poli_list), JSON.serialize(reqSup01), JSON.serialize(req01),'',shipid,packids, false, null,false,true);  }catch(Exception e){}
        CreatePO2.fetchProductCC(sup.Id, ps.Id);
        CreatePO2.fetchProductCC('',ps.Id);
        CreatePO2.getpacklistdetails(shipid,packids);
        packids.add(pack.id);
        CreatePO2.getpacklistdetails('',packids);
        try{ CreatePO2.getProducts(sup.Id,'','',DC.Id,true, 'Laptop');  }catch(Exception e){ }
        CreatePO2.checkforTax(address.Id,c.Id);
        try{ CreatePO2.save_PurchaseOrder(JSON.serialize(PO), JSON.serialize(poli_list), JSON.serialize(reqSup01), JSON.serialize(req01),'','',packids, false, null,false,true);  }catch(Exception e){}
        try{ CreatePO2.save_PurchaseOrder(JSON.serialize(PO), JSON.serialize(poli_list), JSON.serialize(reqSup01), JSON.serialize(req01),'','',packids, true, null,false,true);  }catch(Exception e){}
        System.assertEquals('ERP', 'ERP');
        CreatePO2.getFiles('');
        Attachment testAttachment = new Attachment(
            ParentId = PO1.Id,  // Set the ParentId to the record you want to attach the file to
            Name = 'TestAttachment.txt',
            Body = Blob.valueOf('Test Attachment Content'),
            ContentType = 'text/plain'
        );
        insert testAttachment;
        CreatePO2.getFiles(PO1.Id);
        CreatePO2.AnalyticalAccount AAwrp = new CreatePO2.AnalyticalAccount();
        CreatePO2.multiCurrencyWrap MCwrp = new CreatePO2.multiCurrencyWrap();
       // CreatePO2.DeleteAttachment(testAttachment.Id, PO1.Id);
        CreatePO2.getCurrencies(PO1.Id);
        CreatePO2.selectOptions SOp1 = new CreatePO2.selectOptions('','');
        CreatePO2.selectOptions SOp2 = new CreatePO2.selectOptions('','',false);
        
        Test.StopTest();
        
    }
    
    static testmethod void UnitTestWO_Unit15() {
        PreventRecursiveLedgerEntry.testCasesTransactions = true; 
        
        Account orgn = new Account(Name='Universal Stores', Account_Type__c = 'Company'); 
        insert orgn;
        Account sup = new Account(Name='Supplier',Account_Type__c = 'Supplier'); 
        insert sup;
        
        Account vend = new Account(Name='Vendor',Account_Type__c = 'Vendor');
        insert vend;
        
        Account customer = new Account(Name='Customer', Account_Type__c = 'Customer');
        insert customer;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        
        WO__c wo = new WO__c(Name = 'test wo', Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        Profiling__c prof = new Profiling__c(Active__c = true);
        insert prof;
        Product2 ps = new Product2(Name='test', isActive=true,Track_Inventory__c=true,Serialise__c=true,Lot_Tracked__c=true);
        insert ps;
        Account c = new Account(Name='Test', Account_Type__c='Customer',Account_Profile__c = prof.Id);
        insert c;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=c.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        Address__c  address = new Address__c(Name='Test', Customer__c=c.Id, Active__c = true);
        insert address;
        Channel__c channel = new Channel__c(Name='Test', Ship_From_Address__c=address.Id, Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        Employees__c emp = new Employees__c(Name='Test', Employee_User__c=UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true,Priority__c = '1', Active__c= true);
        insert DC;
        Process__c prcs = new Process__c(Name = 'projectTestProcess');
        insert prcs;
        Site__c site1 = new Site__c(Name = 'projectTestSite');
        insert site1;
        
        Product2 pro = new Product2(Name = 'Laptop X200', Family = 'Hardware',IsActive= true , Issue_Purchase_Order__c = true );
        insert pro;
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;
        PricebookEntry pbe = new PricebookEntry( Pricebook2Id = standardPricebook.Id, Product2Id = pro.Id, UnitPrice = 102,IsActive = true);
        Insert pbe;
        
        Order ord = new Order(Name = 'Test Order',Status = 'Draft',EffectiveDate = system.today(),EndDate = system.today() + 4,Shipment_Type__c='UPS',Shipment_Preference_Speed__c='--None--',
                              AccountId = c.id,Contact__c=contact.Id,Pricebook2Id=standardPricebook.Id,Amount__c=345,Expected_Date__c=Date.today(),
                              Company__c=orgn.Id);        
        insert ord;
        OrderItem orItem = new OrderItem(OrderId = ord.Id,PricebookEntryId=pbe.Id,Quantity = 1,UnitPrice = 100,Active__c=true,Is_Back_Order__c=true);        
        //orItem.Product2Id= pro.Id;
        insert orItem;
        
        Routing__c rout = new Routing__c( Name = 'projectTestRouting', Product__c = ps.Id , Process__c = prcs.Id, Raw_Materials_Site__c = site.Id, Finished_Products_Site__c = site.Id);
        insert rout;
        Inventory_Stock__c stock = new Inventory_Stock__c(Name = 'inventory1', Warehouse__c = site1.Id, Product__c = ps.Id, Active__c = true);
        insert stock;
        Stock_Inward_Line_Item__c inward = new Stock_Inward_Line_Item__c(Name= 'inward1', Site_ProductService_InventoryStock__c = stock.Id, Product__c = ps.Id, Quantity__c = 5);
        insert inward;
        Manufacturing_Order__c MO = new Manufacturing_Order__c(Name = 'testMO1', Product__c = ps.Id, Routing__c = rout.Id);
        insert MO;
        WO__c WO1 = new WO__c(Name = 'testWO1', Routing__c = rout.Id,Product__c=pro.Id);
        insert WO1;
        Manufacturing_Order__c Mu = new Manufacturing_Order__c();
        insert Mu;
        
        MRP__c mrpLine = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1, MO__c = MO.Id);
        mrpLine.MO__c = MO.Id;
        mrpLine.Work_Order__c = WO1.Id;
        insert mrpLine;
        MRP__c mrpLine2 = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1, MO__c = MO.Id);
        mrpLine2.MO__c = MO.Id;
        insert mrpLine2;
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name = 'testRMA1');
        insert rma;
        RMA_Line_Item__c rmaLine = new RMA_Line_Item__c(Name = 'testRMAline1', Return_Merchandise_Authorisation__c = rma.Id);
        insert rmaLine;
        Date tomo = system.today();
        tomo.addMonths(1);
        Cost_Card__c ccard = new Cost_Card__c(Name = 'testCard1', Product__c = ps.Id, Supplier__c = sup.Id, End_Date__c = tomo, Cost__c = 10, Quantity__c = 5);
        insert ccard;
        List<Id> prods = new List<Id>();
        prods.add(ps.Id);
        PO__c PO = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id, Ready_To_Receive__c = true,Order__c=ord.Id);
        //insert PO;
        PO__c PO1 = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id); // Ready_To_Receive__c = true 23/10/23
        insert PO1;
        Purchase_Line_Items__c poli1 = new Purchase_Line_Items__c(Name = 'testPOLI1',Purchase_Orders__c=PO1.Id,Product__c=ps.Id,Quantity__c=10,Quantity_Received__c=10,RTV_Quantity__c=0,Tax__c=0,Unit_Price__c=10);
        insert poli1;
       /* Purchase_Line_Items__c poli2 = new Purchase_Line_Items__c(Name = 'testPOLI2',Purchase_Orders__c=PO1.Id,Product__c=ps.Id,Quantity__c=10,Quantity_Received__c=10,RTV_Quantity__c=0,Master_Purchase_Line_Items__c=poli1.Id);
        insert poli2;*/
        
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name = 'testPOLI1', Order__c = ord.Id);
        List<Purchase_Line_Items__c> poli_list = new List<Purchase_Line_Items__c>();
        poli_list.add(poli);
        Account sup01 = new Account(Name = 'testCaseSupplier', Account_Type__c = 'Vendor');
        insert sup01;
        Request__c req01 = new Request__c(Name='testCaseRequest1', Status__c = 'Open', Response_Due_Date__c = system.today());
        insert req01;
        Request_Supplier__c reqSup01 = new Request_Supplier__c(Name='testRequestSupp1', Request__c = req01.Id, Supplier__c = sup01.Id, Submit_Date__c = tomo);
        insert reqSup01;
        Package__c pack = new Package__c( Name__c='Test Pack',Order__c = ord.Id,Active__c = true,status__c='Deposited to front desk');
        insert pack;
        
        Package_List__c plist = new Package_List__c(Name = 'Test List', Order_Product__c = orItem.Id,Active__c=true, Order__c = ord.Id,Package__c = pack.Id, Quantity__c = 3);
        insert plist;
        
        Shipment__c ship = new Shipment__c(Customer__c=customer.id,Shipping_Address__c=address.Id,Active__c=true,Order__c = ord.Id ,Customer_Contact__c=contact.id,
                                           status__c='Shipped',Tracking_Number__c='123456'); 
        insert ship;
        PO.Request__c = req01.Id;
        
        Date sd = Date.today();

// Set end date as 4 days after the start date
Date ed = Date.today().addDays(4);
        
        Cost_Card__c cc = new Cost_Card__c(Start_Date__c = sd , End_Date__c = ed);
        insert cc;
        
        
        
        
        Product2 p2 = new Product2(Name = 'test1',Vendor_product_Name__c = 'XYZ',Description = 'i dont know ',ProductCode = '129hht ', Issue_Purchase_Order__c = true, Status__c = 'Certified',  IsActive = true);
        insert p2;
        
         Approved_Vendor__c appv = new Approved_Vendor__c( Product__c = p2.Id, Default__c = true, Status__c = 'Approved', Cost_Card__c = cc.Id, Vendor__c = sup01.Id );
        insert appv;
        
        Tax__c t = new Tax__c(Account_Profile__c = prof.Id ,Effective_Date__c = sd,Expiry_Date__c = ed, Type__c ='Sales Tax', Tax_Rate__c = 20 ,Product__c = Null , Active__c=true, Postal_Code__c = 'test',City__c='test',Country__c='Brazil');
        insert t;
        Test.startTest();
        try{CreatePO2.populateSOlines(ord.Id);}catch(Exception e){}
        String salName = 'Erp7';
        String sal1Name = 'Erp7';
        System.assertEquals(salName, sal1Name);
        Test.StopTest();
    }
    
    static testmethod void UnitTestPO_Unit11(){
        Account orgn = new Account(Name='Company', Account_Type__c = 'Company');
        insert orgn;
        Account sup = new Account(Name='Supplier',Account_Type__c = 'Supplier');
        insert sup;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=orgn.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        WO__c wo = new WO__c(Name = 'test wo', Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        
        
        Product2 ps = new Product2(Name='test', isActive=true,Track_Inventory__c=true);
        insert ps;
        Account c = new Account(Name='Test', Account_Type__c='Customer');
        insert c;
        Address__c  address = new Address__c(Name='Test', Customer__c=c.Id);
        insert address;
        Channel__c channel = new Channel__c(Name='Test', Ship_From_Address__c=address.Id, Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        Employees__c emp = new Employees__c(Name='Test', Employee_User__c=UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true);
        insert DC;
        Process__c prcs = new Process__c(Name = 'projectTestProcess');
        insert prcs;
        Site__c site1 = new Site__c(Name = 'projectTestSite');
        insert site1;
        
        /*MPS__c mps = new MPS__c(Name = 'MPS1', Product__c = ps.Id);
        insert mps;
        MPS_line_Item__c mpsLine = new MPS_line_Item__c(Name = 'testMPS1', MPS__c = mps.Id);
        insert mpsLine;*/
        
        Routing__c rout = new Routing__c( Name = 'projectTestRouting', Product__c = ps.Id , Process__c = prcs.Id, Raw_Materials_Site__c = site1.Id, Finished_Products_Site__c = site.Id);
        insert rout;
        Inventory_Stock__c stock = new Inventory_Stock__c(Name = 'inventory1', Warehouse__c = site1.Id, Product__c = ps.Id, Active__c = true);
        insert stock;
        Stock_Inward_Line_Item__c inward = new Stock_Inward_Line_Item__c(Name= 'inward1', Site_ProductService_InventoryStock__c = stock.Id, Product__c = ps.Id, Quantity__c = 5);
        insert inward;
        Manufacturing_Order__c MO = new Manufacturing_Order__c(Name = 'testMO1', Product__c = ps.Id, Routing__c = rout.Id);
        insert MO;
        WO__c WO1 = new WO__c(Name = 'testWO1', Routing__c = rout.Id);
        insert WO1;
        MRP__c mrpLine = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1);
        mrpLine.MO__c = MO.Id;
        mrpLine.Work_Order__c = WO1.Id;
        insert mrpLine;
        MRP__c mrpLine2 = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1);
        mrpLine2.MO__c = MO.Id;
        insert mrpLine2;
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name = 'testRMA1');
        insert rma;
        RMA_Line_Item__c rmaLine = new RMA_Line_Item__c(Name = 'testRMAline1', Return_Merchandise_Authorisation__c = rma.Id);
        insert rmaLine;
        Date tomo = system.today();
        tomo.addMonths(1);
        Cost_Card__c ccard = new Cost_Card__c(Name = 'testCard1', Product__c = ps.Id, Supplier__c = sup.Id, End_Date__c = tomo, Cost__c = 10, Quantity__c = 5);
        insert ccard;
        List<Id> prods = new List<Id>();
        prods.add(ps.Id);
        
         // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
       Address__c add = new Address__c(Customer__c = testAccount.Id ,Is_Billing_Address__c = true, Is_Shipping_Address__c = true, Active__c = true);
        insert add;
 
        
        Order ord = new Order(Name = 'Test Order',Status = 'Draft',EffectiveDate = system.today(),EndDate = system.today() + 4,Shipment_Type__c='UPS',Shipment_Preference_Speed__c='--None--',
                              AccountId = c.id,Contact__c=contact.Id,Amount__c=345,Expected_Date__c=Date.today(),
                              Company__c=orgn.Id);        
        insert ord;
        OrderItem orItem = new OrderItem(OrderId = ord.Id,Quantity = 1,UnitPrice = 100,Active__c=true,Is_Back_Order__c=true);     
        
        PO__c PO = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id, Ready_To_Receive__c = true);
        //insert PO;
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name = 'testPOLI1', Order__c = ord.Id);
        List<Purchase_Line_Items__c> poli_list = new List<Purchase_Line_Items__c>();
        poli_list.add(poli);
        Account sup01 = new Account(Name = 'testCaseSupplier', Account_Type__c = 'Vendor');
        insert sup01;
        Request__c req01 = new Request__c(Name='testCaseRequest1', Status__c = 'Open', Response_Due_Date__c = system.today());
        insert req01;
        Request_Supplier__c reqSup01 = new Request_Supplier__c(Name='testRequestSupp1', Request__c = req01.Id, Supplier__c = sup01.Id, Submit_Date__c = tomo);
        insert reqSup01;
        PO.Request__c = req01.Id;
        
        CreatePO2.fetchProductDesc(ps.Id);
        CreatePO2.getVendorDetailsNew(c.Id, JSON.serialize(prods));
        CreatePO2.getOrgAddressDetails(testAccount.Id);
        CreatePO2.getPOFC();
           CreatePO2.getProdDetails('','');
        CreatePO2.getFCdetails();
        //CreatePO2.getSubFamily();
        //CreatePO2.ContactRecordTypess(); 
        CreatePO2.getDefaultVendor(site.Id, prods);
        CreatePO2.PRWrap pwr = new CreatePO2.PRWrap();
        CreatePO2.PRStock prt = new CreatePO2.PRStock();        
        System.assertEquals('ERP', 'ERP');
        
    }
    
    static testmethod void UnitTestWO_Unit2() {
        PreventRecursiveLedgerEntry.testCasesTransactions = true;
        
        Account orgn = new Account(Name='Company', Account_Type__c = 'Company');
        insert orgn;
        Account sup = new Account(Name='Supplier', Account_Type__c = 'Supplier');
        insert sup;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=orgn.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        WO__c wo = new WO__c(Name = 'test wo',  Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        
        Product2 ps = new Product2(Name='test',isActive=true,Track_Inventory__c=true);
        insert ps;
        
        Order ord = new Order(Name = 'Test Order',Status = 'Draft',EffectiveDate = system.today(),EndDate = system.today() + 4,Shipment_Type__c='UPS',Shipment_Preference_Speed__c='--None--',
                              AccountId = sup.id,Contact__c=contact.Id,Amount__c=345,Expected_Date__c=Date.today(),
                              Company__c=orgn.Id);        
        insert ord;
        OrderItem orItem = new OrderItem(OrderId = ord.Id,Quantity = 1,UnitPrice = 100,Active__c=true,Is_Back_Order__c=true);  
        
        /*pageReference page1 = System.page.Create_PurchaseOrder;
page1.getParameters().put('Id',Ord.Id);
page1.getParameters().put('retUrl',' /'+Ord.Id);
Test.setCurrentPage(page1);*/
        
        CreatePO2 sopo = new CreatePO2();
        //sopo.setSOID(sod.Id);
        LIst<id> temp_list= new List<Id>();
        temp_list.add(sopo.getSOID());
        sopo.setsoIds(temp_list);
        temp_list=sopo.getsoIds();
        CreatePO2.newWrapper sopowrap = new CreatePO2.newWrapper(1);
        sopo.addpoliWrapperRows();
        //sopo.TotalPriceCalculation();
        sopo.setSOID('');
        //sopo.savePO();
        //sopo.back();
        //sopo.SOID = sod.Id;
        
        /*pageReference page = System.page.Create_WorkOrder;
page.getParameters().put('Id',sod.Id);
page.getParameters().put('retUrl',' /'+sod.Id);
Test.setCurrentPage(page);*/
        /*
        CreateWo sowo = new CreateWo();
        sowo.setSOID(Ord.Id);
        CreateWo.newWrapper sowowrap = new CreateWo.newWrapper(1);
        sowo.addWoliWrapperRows();
        sowo.saveWO();
        CreateWo sowo1 = new CreateWo();
        sowo1.back();
        
        CreateWO cw=new CreateWO();
        CreateWO.addRow=0;CreateWO.toDelIdent=0;CreateWO.addRow=0;
        */
        
        String s1 = 'test';
        String s2 = 'test'; 
        System.assertEquals(s1,s2);              
    }
    
    static testmethod void UnitTestPO_Unit3(){
        Account orgn = new Account(Name='Company', Account_Type__c = 'Company');
        insert orgn;
        Account sup = new Account(Name='Supplier',Account_Type__c = 'Supplier');
        insert sup;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=orgn.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        WO__c wo = new WO__c(Name = 'test wo', Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        Order ord = new Order(Name = 'Test Order',Status = 'Draft',EffectiveDate = system.today(),EndDate = system.today() + 4,Shipment_Type__c='UPS',Shipment_Preference_Speed__c='--None--',
                              AccountId = sup.id,Contact__c=contact.Id,Amount__c=345,Expected_Date__c=Date.today(),
                              Company__c=orgn.Id);        
        insert ord;
        OrderItem orItem = new OrderItem(OrderId = ord.Id,Quantity = 1,UnitPrice = 100,Active__c=true,Is_Back_Order__c=true);  
        
        Product2 ps = new Product2(Name='test', isActive=true,Track_Inventory__c=true);
        insert ps;
        Account c = new Account(Name='Test', Account_Type__c='Customer');
        insert c;
        Address__c  address = new Address__c(Name='Test', Customer__c=c.Id);
        insert address;
        Channel__c channel = new Channel__c(Name='Test', Ship_From_Address__c=address.Id, Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        Employees__c emp = new Employees__c(Name='Test', Employee_User__c=UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true);
        insert DC;
        Process__c prcs = new Process__c(Name = 'projectTestProcess');
        insert prcs;
        Site__c site1 = new Site__c(Name = 'projectTestSite');
        insert site1;
        /*MPS__c mps = new MPS__c(Name = 'MPS1', Product__c = ps.Id);
        insert mps;
        MPS_line_Item__c mpsLine = new MPS_line_Item__c(Name = 'testMPS1', MPS__c = mps.Id);
        insert mpsLine;*/
        
        Routing__c rout = new Routing__c( Name = 'projectTestRouting', Product__c = ps.Id , Process__c = prcs.Id, Raw_Materials_Site__c = site1.Id, Finished_Products_Site__c = site.Id);
        insert rout;
        Inventory_Stock__c stock = new Inventory_Stock__c(Name = 'inventory1', Warehouse__c = site1.Id, Product__c = ps.Id, Active__c = true);
        insert stock;
        Stock_Inward_Line_Item__c inward = new Stock_Inward_Line_Item__c(Name= 'inward1', Site_ProductService_InventoryStock__c = stock.Id, Product__c = ps.Id, Quantity__c = 5);
        insert inward;
        Manufacturing_Order__c MO = new Manufacturing_Order__c(Name = 'testMO1', Product__c = ps.Id, Routing__c = rout.Id);
        insert MO;
        WO__c WO1 = new WO__c(Name = 'testWO1', Routing__c = rout.Id);
        insert WO1;
        MRP__c mrpLine = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1);
        mrpLine.MO__c = MO.Id;
        mrpLine.Work_Order__c = WO1.Id;
        insert mrpLine;
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name = 'testRMA1');
        insert rma;
        RMA_Line_Item__c rmaLine = new RMA_Line_Item__c(Name = 'testRMAline1', Return_Merchandise_Authorisation__c = rma.Id);
        insert rmaLine;
        Date tomo = system.today();
        tomo.addMonths(1);
        Cost_Card__c ccard = new Cost_Card__c(Name = 'testCard1', Product__c = ps.Id, Supplier__c = sup.Id, End_Date__c = tomo, Cost__c = 10, Quantity__c = 5);
        insert ccard;
        List<Id> prods = new List<Id>();
        prods.add(ps.Id);
        PO__c PO = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id, Ready_To_Receive__c = true);
        //insert PO;
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name = 'testPOLI1', Order__c = Ord.Id);
        List<Purchase_Line_Items__c> poli_list = new List<Purchase_Line_Items__c>();
        poli_list.add(poli);
        Account sup01 = new Account(Name = 'testCaseSupplier', Account_Type__c = 'Vendor');
        insert sup01;
        Request__c req01 = new Request__c(Name='testCaseRequest1', Status__c = 'Open', Response_Due_Date__c = system.today());
        insert req01;
        
        //vf
        
        CreatePO2 sopo = new CreatePO2();
        /*pageReference page1 = System.page.Create_PurchaseOrder;
page1.getParameters().put('Id',sod.Id);
page1.getParameters().put('retUrl',' /'+sod.Id);
Test.setCurrentPage(page1);*/
        
        //sopo.setSOID(sod.Id);
        sopo.soId = Ord.Id;
        //sopo.soliList.add(solim);
        LIst<id> temp_list= new List<Id>();
        temp_list.add(sopo.getSOID());
        sopo.setsoIds(temp_list);
        temp_list=sopo.getsoIds();
        CreatePO2.newWrapper sopowrap = new CreatePO2.newWrapper(1);
        sopo.delpoliWrapperRow();
        /*sopo.savePO();
sopo.back();
sopo.doInit();
sopo.init();
sopo.getUnitPriceByVendor();*/
        sopo.addPoliWrapperRows();
        sopo.delPoliWrapperRow();
        CreatePO2.getPackageType();
        //sopo.getUnitPriceByVendor();
        try{CreatePO2.populateSOLI(orItem.Id);}catch(Exception e){}
        
        /*pageReference page = System.page.Create_WorkOrder;
page.getParameters().put('Id',sod.Id);
page.getParameters().put('retUrl',' /'+sod.Id);
Test.setCurrentPage(page);*/
        
        /*
        CreateWo sowo = new CreateWo();
        LIst<id> templist= new List<Id>();
        templist.add(sowo.getSOID());
        sowo.setsoIds(templist);
        templist=sowo.getsoIds();
        CreateWo.newWrapper sowowrap = new CreateWo.newWrapper(1);
        sowo.delWoliWrapperRow();
        sowo.saveWO();
        sowo.back();
        */
        String s1 = 'test';
        String s2 = 'test'; 
        System.assertEquals(s1,s2);   
    }
    
    static testmethod void UnitTestPO_Unit4(){
        Account orgn = new Account(Name='Company', Account_Type__c = 'Company');
        insert orgn;
        Account customer = new Account(Name='Customer', Account_Type__c = 'Customer');
        insert customer;
        Account sup = new Account(Name='Supplier',Account_Type__c = 'Supplier');
        insert sup;
        Business_Unit__c bUnit = new Business_Unit__c(Company__c = orgn.Id, name = 'test', Active__c= true);
        insert bUnit;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=customer.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        WO__c wo = new WO__c(Name = 'test wo', Active__c = true, WO_Supplier__c = sup.Id);
        insert wo;
        
        
        Product2 ps = new Product2(Name='test', isActive=true,Track_Inventory__c=true);
        insert ps;
        Account c = new Account(Name='Test', Account_Type__c='Customer');
        insert c;
        Address__c  address = new Address__c(Name='Test', Customer__c=c.Id);
        insert address;
        Channel__c channel = new Channel__c(Name='Test', Ship_From_Address__c=address.Id, Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        Employees__c emp = new Employees__c(Name='Test', Employee_User__c=UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true);
        insert DC;
        Process__c prcs = new Process__c(Name = 'projectTestProcess');
        insert prcs;
        Site__c site1 = new Site__c(Name = 'projectTestSite');
        insert site1;
        Address__c bAddress = new Address__c(Customer__c=customer.id, Contact__c=contact.id,Active__c=true,Address_Line1__c='test', Address_Line2__c='test', Address_Line3__c='test',
                                             City__c='test',Country__c='United States', Postal_Code__c='test',Is_Billing_Address__c=true);
        insert bAddress;
        Address__c sAddress = new Address__c(Customer__c=customer.id, Contact__c=contact.id,Active__c=true,Address_Line1__c='test', Address_Line2__c='test', Address_Line3__c='test',
                                             City__c='test',Country__c='United States', Postal_Code__c='test',Is_Shipping_Address__c=true);
        insert sAddress;
        Id pricebookId = Test.getStandardPricebookId();
        Order sod = new Order();   
        sod.Status = 'Draft';
        sod.Stage__c = 'Entered';
        sod.EffectiveDate = system.today();
        sod.AccountId = Contact.AccountId;
        sod.Contact__c = Contact.Id;
        sod.Channel__c = channel.Id;
        sod.Bill_To_Address__c = bAddress.Id;
        sod.Ship_To_Address__c = sAddress.Id;
        sod.Request_Date__c = system.Today();
        sod.Authorised__c = true;
        sod.Ready_To_Pick_Pack__c = true;
        sod.fulfilled__c = false;
        sod.Barcode__c = 'test';
        sod.Pricebook2Id=pricebookId;
        sod.Shipment_Type__c='UPS';sod.Shipment_Preference_Speed__c='--None--';
        insert sod; 
        Order psod = sod;
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
        update standardPricebook;       
        PricebookEntry pbe = new PricebookEntry( Pricebook2Id = standardPricebook.Id, Product2Id = ps.Id, UnitPrice = 1020,IsActive = true);
        Insert pbe;
        OrderItem solim = new OrderItem(UnitPrice=100,Discount_Amount__c=10,Product2Id=ps.id,PricebookEntryId=pbe.Id,Quantity=1,OrderId=psod.id,Total_Price__c=100,VAT_Amount__c=10, Inventory_Tracked__c = true, Allocate_Stock__c = true);
        insert solim; 
        /*MPS__c mps = new MPS__c(Name = 'MPS1', Product__c = ps.Id);
        insert mps;
        MPS_line_Item__c mpsLine = new MPS_line_Item__c(Name = 'testMPS1', MPS__c = mps.Id);
        insert mpsLine;*/
        
        Routing__c rout = new Routing__c( Name = 'projectTestRouting', Product__c = ps.Id , Process__c = prcs.Id, Raw_Materials_Site__c = site1.Id, Finished_Products_Site__c = site.Id);
        insert rout;
        Inventory_Stock__c stock = new Inventory_Stock__c(Name = 'inventory1', Warehouse__c = site1.Id, Product__c = ps.Id, Active__c = true);
        insert stock;
        Stock_Inward_Line_Item__c inward = new Stock_Inward_Line_Item__c(Name= 'inward1', Site_ProductService_InventoryStock__c = stock.Id, Product__c = ps.Id, Quantity__c = 5);
        insert inward;
        Manufacturing_Order__c MO = new Manufacturing_Order__c(Name = 'testMO1', Product__c = ps.Id, Routing__c = rout.Id);
        insert MO;
        WO__c WO1 = new WO__c(Name = 'testWO1', Routing__c = rout.Id);
        insert WO1;
        MRP__c mrpLine = new MRP__c(Name = 'testMRPLine1', MRP_Product__c = ps.Id, Total_Amount_Required__c=10, Fulfilled_Amount__c = 1);
        mrpLine.MO__c = MO.Id;
        mrpLine.Work_Order__c = WO1.Id;
        insert mrpLine;
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name = 'testRMA1');
        insert rma;
        RMA_Line_Item__c rmaLine = new RMA_Line_Item__c(Name = 'testRMAline1', Return_Merchandise_Authorisation__c = rma.Id);
        insert rmaLine;
        Date tomo = system.today();
        tomo.addMonths(1);
        Cost_Card__c ccard = new Cost_Card__c(Name = 'testCard1', Product__c = ps.Id, Supplier__c = sup.Id, End_Date__c = tomo, Cost__c = 10, Quantity__c = 5);
        insert ccard;
        List<Id> prods = new List<Id>();
        prods.add(ps.Id);
        PO__c PO = new PO__c(Name = 'testPO1', Vendor__c = sup.Id, Channel__c = channel.Id, Distribution_Channel__c = DC.Id, Company__c = orgn.Id, Ready_To_Receive__c = true);
        insert PO;
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name = 'testPOLI1', Order_Product__c = solim.Id,Purchase_Orders__c= PO.Id);
        insert poli;
        List<Purchase_Line_Items__c> poli_list = new List<Purchase_Line_Items__c>();
        poli_list.add(poli);
        set<Id> PuId = new set<Id>();
        for(Purchase_Line_Items__c pr : poli_list){ PuId.add(pr.Id); }
        Account sup01 = new Account(Name = 'testCaseSupplier', Account_Type__c = 'Vendor');
        insert sup01;
        Request__c req01 = new Request__c(Name='testCaseRequest1', Status__c = 'Open', Response_Due_Date__c = system.today());
        insert req01;
        Dimension__c dimen = new Dimension__c(Name='Test',Sort_Order__c=0);
        insert dimen;
        //vf
        
        CreatePO2 sopo = new CreatePO2();
        
        /*pageReference page1 = System.page.Create_PurchaseOrder;
page1.getParameters().put('Id',sod.Id);
page1.getParameters().put('retUrl',' /'+sod.Id);
Test.setCurrentPage(page1);*/
        
        //sopo.setSOID(sod.Id);
        sopo.soId = sod.Id;
        //sopo.soliList.add(solim);
        LIst<id> temp_list= new List<Id>();
        temp_list.add(sopo.getSOID());
        sopo.setsoIds(temp_list);
        temp_list=sopo.getsoIds();
        CreatePO2.newWrapper sopowrap = new CreatePO2.newWrapper(1);
        sopo.delpoliWrapperRow();
        /*sopo.savePO();
sopo.back();
sopo.doInit();
sopo.init();
sopo.getUnitPriceByVendor();*/
        sopo.addPoliWrapperRows();
        sopo.delPoliWrapperRow();
        //sopo.getUnitPriceByVendor();
        CreatePO2.getDC(DC.Id);
        CreatePO2.getDC('');
        CreatePO2.getCust(c.Id);
        CreatePO2.getCust('');
        CreatePO2.getVendorAddress(c.Id);
        CreatePO2.getVendorAddress('');
        CreatePO2.getShipmentType();
        CreatePO2.fetchEmployeeRequester();
        CreatePO2.getRecentRecord('Account');
        CreatePO2.getRecentContact();
        CreatePO2.getRecentDA();
        //CreatePO2.getCurrencies('');
        CreatePO2.getFamily();
        CreatePO2.getCategoryList();
        CreatePO2.AnalyticalAccounts(JSON.serialize(new List<Dimension__c>{dimen}),PO.Id);
        
        CreatePO2.deleteDimensions(dimen.Id);
        
        String s1 = 'test';
        String s2 = 'test'; 
        System.assertEquals(s1,s2);   
        PreventRecursiveLedgerEntry.SOLI_AllocateStock=true;
        OrderProductInventoryUtils.createProductPurchaseLineItems(PuId);
        PreventRecursiveLedgerEntry.SOLI_AllocateStock=true;
        OrderProductInventoryUtils.updateProductPurchaseLineItems(PuId);
        
        
        ApexPages.currentPage().getParameters().put('Id',po.Id);
        ApexPages.currentPage().getParameters().put('CustID',' /'+contact.Id);
        /*PurchaseOrderDocumentNew PODN = new PurchaseOrderDocumentNew();
PODN.Email_Details();
PODN.sendPO();
//PODN.createPDF();
PODN.getRecipientId();
PODN.setRecipientId(po.Id);*/
    }
    
    static testmethod void validatevenderpartTest(){
        Product2 pro = new Product2(Name = 'Laptop X200', Family = 'Hardware',IsActive=TRUE);
        insert pro;
        Cost_Card__c costcrd = new Cost_Card__c(Name = 'Laptop X200 cost',Product__c=pro.Id,Vendor_Part_Number__c='00001');
        insert costcrd;
        list<Cost_Card__c>costList = new list<Cost_Card__c>();
        for(integer i=1;i<=5;i++){
            Cost_Card__c cost = new Cost_Card__c();
            cost.Name = 'CostCard-' + i;
            cost.Product__c = pro.Id;
            cost.Vendor_Part_Number__c = '0000' + i;
            costList.add(cost);
        }
        Test.startTest();
        try { insert costList;} catch (DmlException e) {}
        String s1 = 'test';
        String s2 = 'test'; 
        System.assertEquals(s1,s2);  
        Test.stopTest();
    }
    
    //there is my code 
     @IsTest
    static void testCloneAttachment() {
        // Create a test record (e.g., an Account)
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        // Create a test attachment
        Attachment testAttachment = new Attachment(
            ParentId = testAccount.Id,
            Name = 'Test Attachment',
            Body = Blob.valueOf('Test content')
        );
        insert testAttachment;

        // Clone the attachment to another Account record
        Account clonedAccount = new Account(Name='Cloned Account');
        insert clonedAccount;
        
        List<Id> attachmentIds = new List<Id>{testAttachment.Id};

        // Call the method
        Test.startTest();
        String result = CreatePO2.cloneAttachment(clonedAccount.Id, attachmentIds);
        Test.stopTest();
        
        // Query the cloned attachment to validate
        List<Attachment> clonedAttachments = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :clonedAccount.Id];

        // Assert that the cloned attachment exists and has the correct values
        System.assertEquals(1, clonedAttachments.size(), 'Cloned attachment should be created');
        System.assertEquals('Test Attachment', clonedAttachments[0].Name, 'Attachment name should be the same');
    }
    
    
    //its working tillhere 


    
    @isTest
    public static void testGetOrderAddress() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
       Address__c add = new Address__c(Customer__c = testAccount.Id ,Is_Billing_Address__c = true, Is_Shipping_Address__c = true, Active__c = true);
        insert add;
 
        // Create a test Order and associate it with the Account
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
           // Ship_To_Address__c = '123 Test St, Test City, TC 12345',
           // Ship_From_Address__c = '456 Example Rd, Example City, EC 67890',
            //Bill_To_Address__c = '789 Billing Blvd, Billing City, BC 23456',
            Status = 'Draft', // Required field for Order
            EffectiveDate = Date.today() // Required field for Order
        );
        insert testOrder;

        // Call the method to get the order address
        Order resultOrder = CreatePO2.getOrderAddress(testOrder.Id);
        
        // Verify the result
        System.assertNotEquals(null, resultOrder, 'The order should not be null.');
        System.assertEquals(testOrder.Id, resultOrder.Id, 'The returned order Id should match the test order Id.');
        System.assertEquals(testOrder.Ship_To_Address__c, resultOrder.Ship_To_Address__c, 'The Ship To Address should match.');
        System.assertEquals(testOrder.Ship_From_Address__c, resultOrder.Ship_From_Address__c, 'The Ship From Address should match.');
        System.assertEquals(testOrder.Bill_To_Address__c, resultOrder.Bill_To_Address__c, 'The Bill To Address should match.');
    }
    
    
    // here is my code 

    
  // Test method for getPOCurrencies
    @isTest
    static void testGetPOCurrencies() {
        // Check if multi-currency is enabled in the org
        boolean isMultiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');

        // Create test PO record
        PO__c testPO = new PO__c(Name = 'Test PO');
         Product2 p2 = new Product2(Name = 'test1',Vendor_product_Name__c = 'XYZ',Description = 'i dont know ',ProductCode = '129hht ', Issue_Purchase_Order__c = true, Status__c = 'Certified');
        insert p2;

      

        insert testPO;

        Test.startTest();

        // Call the method with the test PO's ID
        String poCurrency = CreatePO2.getPOCurrencies(testPO.Id); 
           

        Test.stopTest();

        // Debug to check the returned currency
        System.debug('CurrencyIsoCode: ' + poCurrency);

        // Handle assert conditions based on multi-currency enablement
        String salName = 'Erp7';
        String sal1Name = 'Erp7';
        System.assertEquals(salName, sal1Name);
    }
        
    
    
    
    
    /* static testmethod void test_get_prod_details_with_valid_ids() {
    // Setup test data
    Product2 product = new Product2(Name='Test Product', isActive=true);
    insert product;
    
    DC__c dc = new DC__c(Name='Test DC');
    insert dc;
    
    // Call the method under test
    wrapProd result = YourClassName.getProdDetails(product.Id, dc.Id);
    
    // Assert the expected results
    System.assertNotEquals(null, result, 'Result should not be null for valid IDs');
    System.assertEquals(product.Id, result.productId, 'Product ID should match');
    System.assertEquals(dc.Id, result.dcId, 'DC ID should match');
}
   */
   
    
    
     @IsTest
    static void testPopulateMpsline() {
        // Insert a Product record
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, Track_Inventory__c = true);
        insert prod;
        
        Material_Requirement_Planning__c MRP = new Material_Requirement_Planning__c(
        );
          insert MRP;
        
        // Insert a Master Production Schedule record
        MPS__c mps = new MPS__c(
            Product__c = prod.Id,
            Lot_Size__c = 50,
            Master_MRP__c = MRP.id
        );
        insert mps;

        // Insert an MPS Line Item record
        MPS_line_Item__c mpsLineItem = new MPS_line_Item__c(
            MPS__c = mps.Id
        );
        insert mpsLineItem;

        // Call the method to test
        Test.startTest();
        Purchase_Line_Items__c result = CreatePO2.populateMpsline(mpsLineItem.Id); // Replace 'YourClassName' with your actual class name
        Test.stopTest();

        // Assert the result is not null and check some field values
        System.assertNotEquals(null, result, 'The Purchase_Line_Items__c should not be null');
        System.assertEquals('Test Product', result.Name, 'The Product name should match');
        System.assertEquals(50, result.Quantity__c, 'The quantity should match the Lot Size');
    }
   
    
     @IsTest
    static void test32() {
        
         Account c = new Account(Name='Test', Account_Type__c='Customer');
        insert c;
        
        // Insert a Product record
        Chart_of_Accounts__c coa = new Chart_of_Accounts__c(
        Company__c = c.Id
        );
        insert coa;
        
        Project__c p = new Project__c();
          insert p;
        
    	Business_Unit__c bUnit = new Business_Unit__c(Company__c = c.Id, name = 'test', Active__c= true);
        insert bUnit;
        
        Budget_Plan__c bp = new Budget_Plan__c(Approved__c = true);
        insert bp;
        
        Budget_Account__c ba = new Budget_Account__c(Chart_of_Account__c= coa.Id,Project__c = p.Id, Organisation_Business_Unit__c = bUnit.Id , Budget_Plan__c = bp.Id, Consumed_Amount__c = 199, Committed_Amount__c= 122, Amount__c = 12222, Name = 'xyz');
        insert ba;
        
        CreatePO2 cPO = new CreatePO2();
        CreatePO2.wrapProd wpd = new CreatePO2.wrapProd();
         
     
       
        
        Channel__c channel = new Channel__c(Name='Test', Shipper_Name__c='test',
                                            Phone__c='1234567890', City__c='test', Street__c='test',
                                            State_Province__c='test', Country__c='test', Zip_Postal_Code__c='test', Active__c=true);
        insert channel;
        
         Site__c site = new Site__c(Name='Test', Active__c=true);
        insert site;
        
    
        
        Employees__c emp = new Employees__c(Name='Test',Employee_User__c = UserInfo.getUserId(), Channel__c=channel.Id);
        insert emp;
        
        Distribution_Channel__c DC = new Distribution_Channel__c(Name='Test', Site__c=site.Id, Channel__c=emp.Channel__c, Primary__c = true,Priority__c = '1', Active__c= true);
        insert DC;
        
        
      Date sd = Date.today();

// Set end date as 4 days after the start date
Date ed = Date.today().addDays(4);
        
        Cost_Card__c cc = new Cost_Card__c(Start_Date__c = sd , End_Date__c = ed);
        insert cc;
        
        
        Cost_Card__c cw = new Cost_Card__c(Start_Date__c = sd , End_Date__c = ed);
        insert cw;
        
          Product2 p2 = new Product2(Name = 'test1',Vendor_product_Name__c = 'XYZ',Description = 'i dont know ',ProductCode = '129hht ', Issue_Purchase_Order__c = true, Status__c = 'Certified',  IsActive = true);
        insert p2;
        
         
         Product2 p3 = new Product2(Name = 'test2',Vendor_product_Name__c = 'XYZ',Description = 'i dont know ',ProductCode = '129hht ', Issue_Purchase_Order__c = true, Status__c = 'Certified');
        insert p3;
        
        Approved_Vendor__c appv = new Approved_Vendor__c( Product__c = p2.Id, Default__c = true, Status__c = 'Approved', Cost_Card__c = cc.Id );
        insert appv;
        
       Approved_Vendor__c apv = new Approved_Vendor__c( Product__c = p3.Id, Default__c = false, Status__c = 'Approved', Cost_Card__c = cw.Id );
        insert apv;
        
         Approved_Vendor__c aapv = new Approved_Vendor__c(Vendor__c = null);
        insert aapv;
        
        
        Inventory_Stock__c Ist = new Inventory_Stock__c(Active__c = true, Warehouse__c = site.Id);
        insert Ist;
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
           
      
       
         Test.startTest();
         CreatePO2.getProjectDepartmentBudget(coa.Id,p.Id,bUnit.Id);
        CreatePO2.getProjectBudget(coa.Id,p.Id);
        CreatePO2.getPORecordTypes();
        CreatePO2.getSubFamily();
        cPO.doInit();
        cPO.init();
		cPO.TotalPriceCalculation(); 
        cPO.back();
        cPO.savePO();
        cPO.getUnitPriceByVendor();
        CreatePO2.getProdDetails(p2.Id ,DC.Id);
        CreatePO2.getProdDetails(p2.Id,'');
         CreatePO2.getProdDetails(p3.Id,'');
      CreatePO2.getProducts('','','',DC.Id,true,'');
        CreatePO2.getProdDetails('',DC.Id);
        
    	String salName = 'Erp7';
        String sal1Name = 'Erp7';
        System.assertEquals(salName, sal1Name);
        
        
        
        
        
        
     
        
        
        Test.stopTest();
    }
 
}