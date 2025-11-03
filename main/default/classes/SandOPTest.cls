@isTest
private class SandOPTest {
    @testSetup
    static void testDataSetup() {
        // Create Organisation Account
        Account orgn = new Account(Name='Organisation', Account_Type__c = 'Organisation');
        insert orgn; 

        // Create Customer Account before Address__c
        Account acc = new Account(Name='Naseeruddin', Account_Type__c = 'Customer', Company__c=orgn.Id);
        insert acc;

        // Create Address__c with Customer__c
        Address__c add = new Address__c(
            Customer__c=acc.Id,
            Address_Line1__c='test', 
            Address_Line2__c='test', 
            Address_Line3__c='test', 
            City__c='test', 
            Country__c='United Kingdom', 
            Is_Billing_Address__c=true, 
            Is_Shipping_Address__c=true, 
            Primary__c=true, 
            Active__c=true, 
            Postal_Code__c='123', 
            State__c='Ajman'
        );
        insert add;

        // Create Site
        Site__c site = new Site__c(
            Name='TestSite', 
            Company__c=orgn.Id, 
            Address__c=add.Id, 
            Active__c=true
        );
        insert site;

        // Create Location with required Site__c field
        Location__c location = new Location__c(Name = 'TestLocation', Site__c = site.Id);
        insert location;

        // Continue with the rest of the setup
        Contact contact = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.id, Phone='1234567890', Email='test@test.com');
        insert contact;
        Product2 pro = new Product2(Name = 'Laptop X200', Family = 'Hardware', IsActive=TRUE, Length__c=2, Width__c=2, Height__c=2, Weight__c=2);
        insert pro;
        BOM__c ver = new BOM__c(Name='Test', Product__c=pro.Id);
        insert ver;
        pro.BOM__c = ver.Id;
        update pro;
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = pro.Id, UnitPrice = 1020, IsActive = true);
        insert pbe;
        Channel__c channel = new Channel__c(Name='Channel', Active__c=true, Ship_From_Address__c=add.Id);
        insert channel;
        RecordType custProfile_RTypes = [SELECT Id, Name FROM RecordType WHERE Name = 'Customer' AND SobjectType = 'Profiling__c' LIMIT 1]; 
        Profiling__c custProfile = new Profiling__c(Name='test', RecordTypeId=custProfile_RTypes.Id, Tax_Sourcing_Rules__c ='Origin');
        insert custProfile;
        RecordType orderProfile_RTypes = [SELECT Id, Name FROM RecordType WHERE Name = 'Order Profile' AND SobjectType = 'Profiling__c' LIMIT 1];
        Profiling__c profile = new Profiling__c(Name='AK Test', Active__c=true, Company__c=acc.Id, Channel__c=channel.Id, Price_Book__c=standardPricebook.Id, Tax_Sourcing_Rules__c ='Origin', RecordTypeId=orderProfile_RTypes.Id, Account_Profile__c=custProfile.Id);
        insert profile;
        acc.Order_Profile__c = profile.Id;
        update acc;
        RecordType rTypeProfile = [SELECT Id, Name FROM RecordType WHERE SobjectType='Profiling__c' AND Name='Employee' LIMIT 1];
        Profiling__c empProfile = new Profiling__c(Name='test', Active__c=true, RecordTypeId=rTypeProfile.Id);
        insert empProfile; 
        Employees__c emp = new Employees__c(First_Name__c='Naseer', Last_Name__c='Akhtar', Email__c='test@test.com', Company__c=orgn.Id, Employee_User__c=UserInfo.getUserId(), Employment_Status__c = 'Active', Non_Employee__c = false, Employee_Profiling__c=empProfile.Id);
        insert emp;
        Distribution_Channel__c dCh = new Distribution_Channel__c(Name='Test', Channel__c=channel.Id, Site__c=site.Id, Active__c=true);
        insert dCh;
        Order ord = new Order(Name = 'Test Order', Status = 'Draft', EffectiveDate = System.today(), Shipment_Type__c='UPS', Shipment_Preference_Speed__c='--None--',
                             AccountId = acc.id, Pricebook2Id=standardPricebook.Id, Amount__c=345, Expected_Date__c=Date.today(), Ship_To_Address__c=add.Id, Bill_To_Address__c=add.id,
                             Order_Profile__c=profile.Id, Stage__c='Entered', Channel__c=channel.Id, Contact__c=contact.Id); 
        insert ord;
        // Set CreatedDate for the Order
        Test.setCreatedDate(ord.Id, DateTime.newInstance(2025, 1, 1));
        OrderItem orditem = new OrderItem(OrderId = ord.Id, Quantity = 1, UnitPrice = 100, Product2Id = pro.Id, PricebookEntryId=pbe.Id, Active__c=true);        
        insert orditem;
        
         Order ord2 = new Order(Name = 'TEST_ORDER_001', Status = 'Draft', EffectiveDate = System.today(), Shipment_Type__c='UPS', Shipment_Preference_Speed__c='--None--',
                             AccountId = acc.id, Pricebook2Id=standardPricebook.Id, Amount__c=345, Expected_Date__c=Date.today(), Ship_To_Address__c=add.Id, Bill_To_Address__c=add.id,
                             Order_Profile__c=profile.Id, Stage__c='Entered', Channel__c=channel.Id, Contact__c=contact.Id , Company__c = orgn.Id); 
        insert ord2;
        System.debug('ord2 ->'+ord2.Name);
        // Set CreatedDate for the Order
        //Test.setCreatedDate(ord2.Id, DateTime.newInstance(2025, 1, 1));
        OrderItem orditem2 = new OrderItem(OrderId = ord2.Id, Quantity = 1, UnitPrice = 100, Product2Id = pro.Id, PricebookEntryId=pbe.Id, Active__c=true);        
        insert orditem2;
        Inventory_Stock__c warehouseItemInventoryStock = new Inventory_Stock__c(Company__c = orgn.Id, Name='test', Active__c=true, Warehouse__c=site.Id, Product__c=pro.Id, Location__c=location.Id, Checked_In_Date__c=Date.today().addDays(-30));
        insert warehouseItemInventoryStock;  
        Inventory_Stock__c warehouseItemInventoryStock2 = new Inventory_Stock__c(Company__c = orgn.Id, Name='test', Status__c='Checked In',Active__c=true, Warehouse__c=site.Id, Product__c=pro.Id, Checked_In_Date__c=Date.today().addDays(-40),Expiry_Date__c=Date.today().addDays(-10));
        insert warehouseItemInventoryStock2;    
        Stock_Inward_Line_Item__c spli = new Stock_Inward_Line_Item__c(Name='test', Active__c=true, Site_ProductService_InventoryStock__c=warehouseItemInventoryStock.Id, Product__c=pro.Id, Quantity__c=10);
        insert spli;
        Stock_Inward_Line_Item__c spli2 = new Stock_Inward_Line_Item__c(Name='test', Active__c=true, Site_ProductService_InventoryStock__c=warehouseItemInventoryStock2.Id, Product__c=pro.Id, Quantity__c=10,Status__c = 'In Stock',Unit_Price__c=10,Amount__c=100);
        insert spli2;
         Stock_Inward_Line_Item__c spli3 = new Stock_Inward_Line_Item__c(Name='test', Active__c=true, Site_ProductService_InventoryStock__c=warehouseItemInventoryStock2.Id, Product__c=pro.Id, Quantity__c=10,Status__c = 'In Stock');
        insert spli3;
        Tier__c tier1 = new Tier__c(Active__c=true, Floor_Unit__c=1, Ceiling_Unit__c=5);
        insert tier1;
        Discount_Plan__c dp = new Discount_Plan__c(Name='test', Active__c=true, Ceiling_Discount_Percentage__c=20, Default_Discount_Percentage__c=10, Floor_Discount_Percentage__c=0, Status__c='Manager Approved');
        insert dp;
        Tier_Discount_Allocation__c tda = new Tier_Discount_Allocation__c(Default__c=true, Active__c=true, Product__c=pro.Id, Tier__c=tier1.Id, Discount_Plan__c=dp.id, Order_Profile__c=profile.Id, Price_Book__c =profile.Price_Book__c);
        insert tda;
        Tax__c tax = new Tax__c(Active__c=true, Effective_Date__c=System.today(), Expiry_Date__c=System.today()+10, Tax_Rate__c=10, Type__c='Sales tax', Account_Profile__c=profile.Id, Province__c='Ajman', Country__c='United Kingdom', Product__c=pro.Id, Postal_Code__c='123');
        insert tax;
        Invoice__c invoice = new Invoice__c(Active__c = true, Order_S__c=ord.id, Account__c=acc.id, Invoice_Amount__c=100);
        insert invoice;
        Coupon__c coupon = new Coupon__c(Name='test', Start_Date__c=System.today(), End_Date__c=System.today(), Value__c=10.02,
                                                     Minimum_Order_Amount__c=10.00, Pre_Tax_Discount__c=true);
        insert coupon;
        Coupon_Issued__c ci = new Coupon_Issued__c(Name='test', Coupon__c=coupon.Id, Issued_Date__c=System.today(), Product__c=pro.Id);
        insert ci;
        Coupon_Redemption__c cr = new Coupon_Redemption__c(Name='Test', Coupon_Issued__c=ci.Id, Redemption_Date__c=System.today(),
                                                                       Coupon__c=coupon.Id);
        insert cr;
        Credit_Note__c credit = new Credit_Note__c(Name='Test', Coupon_Redemption__c=cr.Id, Account__c=acc.Id, Credit__c=100, Debit__c=10);
        insert credit;
        Loyalty_Setup__c loyalty = new Loyalty_Setup__c(Points_Per_Unit_Amount__c = 10);
        insert loyalty;
        Loyalty_Program__c loyaltyProg = new Loyalty_Program__c(Active__c=true, Loyalty_Setup__c=loyalty.Id);
        insert loyaltyProg;
        Loyalty_Card__c clubCard = new Loyalty_Card__c(Customer__c=acc.id, Contact__c=contact.id, Status__c='Active', Start_date__c=System.today(), Expiration_Date__c=System.today()+10, Loyalty_Program__c=loyaltyProg.Id, Company__c=orgn.Id);
        insert clubCard;
        Country_Codes__c countryCode = new Country_Codes__c(Name='test', Code__c='test', Country__c='test');
        insert countryCode;
        Package_Details__c pkgDetailList = new Package_Details__c(Name='Package', Length__c=1, Width__c=1, Height__c=1, Weight__c=1, Weight_Unit__c='KG', Package_Type__c='Package');
        insert pkgDetailList;
        Package_Details__c pkgDetailList2 = new Package_Details__c(Name='Your_Packaging', Length__c=1, Width__c=1, Height__c=1, Weight__c=1, Weight_Unit__c='KG', Package_Type__c='Your_Packaging');
        insert pkgDetailList2;
        UPS_Package_Type__c upsPackageType = new UPS_Package_Type__c(Name='test', Package_Code__c='12', Package_Description__c='Package');
        insert upsPackageType;

        // Create Reordering Rule for stock alert tests
        Reordering_Rule__c rule = new Reordering_Rule__c(
            Product__c = pro.Id,
            Warehouse__c = site.Id,
            Safety_Stock__c = 5,
            Reorder_Level__c = 15,
            Active__c = true
        );
        insert rule;
         Order ord3 = new Order(Name = 'TEST_ORDER_003', Status = 'Draft', EffectiveDate = System.today(), Shipment_Type__c='UPS', Shipment_Preference_Speed__c='--None--',
                             AccountId = acc.id, Pricebook2Id=standardPricebook.Id, Amount__c=345, Expected_Date__c=Date.today(), Ship_To_Address__c=add.Id, Bill_To_Address__c=add.id,
                             Order_Profile__c=profile.Id, Stage__c='Entered', Channel__c=channel.Id, Contact__c=contact.Id , Company__c = orgn.Id); 
        insert ord3;
        System.debug('ord3 ->'+ord3.Name);
        // Set CreatedDate for the Order
        //Test.setCreatedDate(ord2.Id, DateTime.newInstance(2025, 1, 1));
        OrderItem orditem3 = new OrderItem(OrderId = ord3.Id, Quantity = 1, UnitPrice = 100, Product2Id = pro.Id, PricebookEntryId=pbe.Id, Active__c=true);        
        insert orditem3;
        ord3.Is_Closed__c=true;
        update ord3;
 		 Warranty__c wrr1 = new Warranty__c(Product__c =pro.id,Valid_From__c=System.Today(),Valid_Till__c=System.Today()+30,Order_Product__c=orditem3.id);
        insert wrr1;
        Return_Merchandise_Authorisation__c rmarecord1 = new Return_Merchandise_Authorisation__c(Order__c=ord3.Id,Name='Test',  Expected_Date__c=system.today(), Account__c=acc.Id,Return_Contact__c=contact.Id, Active__c=true, Ready_To_Receive__c=true,Company__c=orgn.Id);
        insert rmarecord1;
        
        RMA_Line_Item__c rmalineitem = new RMA_Line_Item__c(Name='Test', Ord_Item__c=orditem3.Id, Active__c=true, Return_Merchandise_Authorisation__c=rmarecord1.Id, Return_Status__c='Quality Check',Company__c=orgn.Id);
        insert rmalineitem;
    }
    
    @isTest
    static void testGetTopProductsByDemand() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = sandOP.getTopProductsByDemand(org.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('topProductLabels'), 'Result should contain topProductLabels');
        System.assert(result.containsKey('topProductData'), 'Result should contain topProductData');
        List<String> labels = (List<String>)result.get('topProductLabels');
    }
    @isTest
    static void testGetWarehouseInventory() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

        // Update Stock_Inward_Line_Item__c to ensure stock quantity
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c WHERE Product__c = :prod.Id LIMIT 1];
        spli.Quantity__c = 10;
        update spli;
        Test.startTest();
        Map<String, Object> result = sandOP.getWarehouseInventory(org.Id, prod.Id,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('warehouseLabels'), 'Result should contain warehouseLabels');
        System.assert(result.containsKey('warehouseInventory'), 'Result should contain warehouseInventory');
        List<Decimal> inventory = (List<Decimal>)result.get('warehouseInventory');
        System.assert(inventory.size() > 0, 'Expected non-empty warehouse inventory');
    }

    @isTest
    static void testGetWarehouseInventoryNoProduct() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];

        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        Map<String, Object> result = sandOP.getWarehouseInventory(org.Id, null,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('warehouseLabels'), 'Result should contain warehouseLabels');
        System.assert(result.containsKey('warehouseInventory'), 'Result should contain warehouseInventory');
    }
    @isTest
    static void testGetLocationInventory() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c WHERE Product__c = :prod.Id LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        Map<String, Object> result = sandOP.getLocationInventory(site.Id, org.Id, prod.Id,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('locationLabels'), 'Result should contain locationLabels');
        System.assert(result.containsKey('locationInventory'), 'Result should contain locationInventory');
    }

    @isTest
    static void testGetLocationInventoryNoProduct() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];

        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        Map<String, Object> result = sandOP.getLocationInventory(site.Id, org.Id, null,null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('locationLabels'), 'Result should contain locationLabels');
        System.assert(result.containsKey('locationInventory'), 'Result should contain locationInventory');
    }
   /* @isTest
    static void testGetStockAlertData() {
        Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
        Location__c location = [SELECT Id FROM Location__c WHERE Name = 'TestLocation' LIMIT 1];
		Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c WHERE Product__c = :prod.Id LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        List<Map<String, Object>> result = sandOP.getStockAlertData(site.Id, location.Id, prod.Id,org.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected stock alert data');
        System.assertEquals('Laptop X200', result[0].get('productName'), 'Expected product name to be Laptop X200');
    }
*/ 
    @isTest
    static void testGetDynamicStockAgingData() {
        Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c WHERE Product__c = :prod.Id LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        List<Map<String, Object>> result = sandOP.getDynamicStockAgingData(site.Id, org.Id, prod.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected stock aging data');
        System.assertEquals('Laptop X200', result[0].get('productName'), 'Expected product name to be Laptop X200');
    }
    @isTest
    static void testGetAgingTrendData() {
        Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

        // Update Stock_Inward_Line_Item__c
        Stock_Inward_Line_Item__c spli = [SELECT Id FROM Stock_Inward_Line_Item__c WHERE Product__c = :prod.Id LIMIT 1];
        spli.Quantity__c = 10;
        update spli;

        Test.startTest();
        List<Map<String, Object>> result = sandOP.getAgingTrendData(site.Id, org.Id, prod.Id, '2024');
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected aging trend data');
        System.assert(result[0].containsKey('month'), 'Result should contain month key');
    }

    @isTest
    static void testGetCustomerOrderTrend() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Naseeruddin' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
		Id prd = null;
        Test.startTest();
        Map<String, Object> result = sandOP.getCustomerOrderTrend(acc.Id, prod.Id, org.Id, '2024');
        Map<String, Object> result2 = sandOP.getCustomerOrderTrend(acc.Id,prd,org.Id, '2024');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('months'), 'Result should contain months');
        System.assert(result.containsKey('quantities'), 'Result should contain quantities');
        List<Decimal> quantities = (List<Decimal>)result.get('quantities');
    }

    @isTest
    static void testGetCustomerSummary() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Naseeruddin' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
		Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
       List<Order> ordList = [SELECT Id, Status FROM Order];
        System.debug('ordList ->'+ordList);
        //System.assertEquals(1, ordList.size(), 'Order should exist from testSetup');
        Order ord = ordList[1];
        ord.status='Activated';
        update ord;
        Id prd=null;
        Test.startTest();
        Map<String, Object> result = sandOP.getCustomerSummary(acc.Id, prod.Id, '2024',org.Id);
        Map<String, Object> result2 = sandOP.getCustomerSummary(acc.Id, prd, '2024',org.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('frequency'), 'Result should contain frequency');
        System.assert(result.containsKey('monetary'), 'Result should contain monetary');
        System.assert(result.containsKey('recencyDays'), 'Result should contain recencyDays');
   
    }
	 @isTest
    static void testgetTopCustomersForProduct() {
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        List<Order> ordList = [SELECT Id, Status FROM Order];
        System.debug('ordList ->'+ordList);
        //System.assertEquals(1, ordList.size(), 'Order should exist from testSetup');
        Order ord = ordList[1];
        ord.status='Activated';
        update ord;
        Test.startTest();
        List<Map<String, Object>> result = sandOP.getTopCustomersForProduct(prod.Id,5,org.Id);
        Test.stopTest();
   
    }
    @isTest
     static void testgetDemandForecastWithHistory() {
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
        Test.startTest();
        Map<String, Object> result = sandOP.getDemandForecastWithHistory(prod.Id,'');
        Map<String, Object> result2 = sandOP.getDemandForecastWithHistory(prod.Id,'MOVING_AVERAGE');
        Test.stopTest();
   
    }
     @isTest
     static void testgetCurrencysymbol() {
        Test.startTest();
        String result = sandOP.getCurrencySymbol();
        Test.stopTest();
   
    }
  @isTest
     static void testgetTopReturningCustomers() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Test.startTest();
       
        List<sandOP.CustomerReturnSummary> results = sandOP.getTopReturningCustomers(org.Id,1);
        Test.stopTest();
   
    }
      @isTest
     static void testgetReturnRateTrend() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Test.startTest();
        List<sandOP.MonthlyReturnStat> results = sandOP.getReturnRateTrend(org.Id);
        Test.stopTest();
   
    }
     @isTest
     static void testgetTopReturnedProducts() {
        Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Test.startTest();
       
        List<sandOP.ReturnProductSummary> results = sandOP.getTopReturnedProducts(org.Id,1);
        Test.stopTest();
   
    }
     @isTest
     static void testgetDefaultProductFromOrderItem() {
       // Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
        Test.startTest();
       
        Product2 results = sandOP.getDefaultProductFromOrderItem();
        Test.stopTest();
   
    }
     @isTest
     static void testgetDefaultCustomerFromOrders() {
        Test.startTest();
       
        Account results = sandOP.getDefaultCustomerFromOrders();
        Test.stopTest();
   
    }
     @isTest
     static void testcheckversionAvailability() {
          Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
        Test.startTest();
       
        Boolean results = sandOP.checkversionAvailability(prod.Id);
        Test.stopTest();
   
    }
    
  }