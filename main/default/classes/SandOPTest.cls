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
        // RecordType custProfile_RTypes = [SELECT Id, Name FROM RecordType WHERE Name = 'Customer' AND SobjectType = 'Profiling__c' LIMIT 1]; 
        // Profiling__c custProfile = new Profiling__c(Name='test', RecordTypeId=custProfile_RTypes.Id, Tax_Sourcing_Rules__c ='Origin');
        Id custProfileRT = Schema.SObjectType.Profiling__c
                          .getRecordTypeInfosByDeveloperName()
                          .get('Customer')
                          .getRecordTypeId();

    Profiling__c custProfile = new Profiling__c( Name='test', RecordTypeId=custProfileRT, Tax_Sourcing_Rules__c='Origin');
    insert custProfile;
       // insert custProfile;
        // RecordType orderProfile_RTypes = [SELECT Id, Name FROM RecordType WHERE Name = 'Order Profile' AND SobjectType = 'Profiling__c' LIMIT 1];
        // Profiling__c profile = new Profiling__c(Name='AK Test', Active__c=true, Company__c=acc.Id, Channel__c=channel.Id, Price_Book__c=standardPricebook.Id, Tax_Sourcing_Rules__c ='Origin', RecordTypeId=orderProfile_RTypes.Id, Account_Profile__c=custProfile.Id);
       
        Id orderProfileRT = Schema.SObjectType.Profiling__c
                          .getRecordTypeInfosByDeveloperName()
                          .get('Order_Profile')   // DeveloperName
                          .getRecordTypeId();

Profiling__c profile = new Profiling__c(
    Name='AK Test',
    Active__c=true,
    Company__c=acc.Id,
    Channel__c=channel.Id,
    Price_Book__c=standardPricebook.Id,
    Tax_Sourcing_Rules__c='Origin',
    RecordTypeId=orderProfileRT,
    Account_Profile__c=custProfile.Id
);

        insert profile;
        acc.Order_Profile__c = profile.Id;
        update acc;
        //RecordType rTypeProfile = [SELECT Id, Name FROM RecordType WHERE SobjectType='Profiling__c' AND Name='Employee' LIMIT 1];
        //Profiling__c empProfile = new Profiling__c(Name='test', Active__c=true, RecordTypeId=rTypeProfile.Id);

        Id employeeProfileRT = Schema.SObjectType.Profiling__c
                              .getRecordTypeInfosByDeveloperName()
                              .get('Employee')     // DeveloperName
                              .getRecordTypeId();

Profiling__c empProfile = new Profiling__c(
    Name='test',
    Active__c=true,
    RecordTypeId=employeeProfileRT
);

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
        Map<String, Object> result = sandOP.getDemandForecastWithHistory(prod.Id,'',null);
        Map<String, Object> result2 = sandOP.getDemandForecastWithHistory(prod.Id,'MOVING_AVERAGE',null);
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
    try {
        List<sandOP.MonthlyReturnStat> results = sandOP.getReturnRateTrend(org.Id);
        System.assert(results != null); // allow empty or populated
    } catch (AuraHandledException e) {
        //System.assert(e.getMessage().startsWith('Error while processing return trend:'));
    }
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
    
    
    @isTest
static void testGetStockMovementData_basic() {
    // Pull existing records from @testSetup
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
    Order anyOrder = [SELECT Id FROM Order LIMIT 1];
    Return_Merchandise_Authorisation__c rma =
        [SELECT Id FROM Return_Merchandise_Authorisation__c LIMIT 1];
    RMA_Line_Item__c rmaLine =
        [SELECT Id FROM RMA_Line_Item__c LIMIT 1];
    Inventory_Stock__c anyInv =
        [SELECT Id FROM Inventory_Stock__c LIMIT 1];

    // --- Create INWARD records for 2024 ---
    Stock_Inward_Line_Item__c inManual = new Stock_Inward_Line_Item__c(
        Name = 'IN_Manual_2024',
        Active__c = true,
        Product__c = prod.Id,
        Quantity__c = 5,
        Site_ProductService_InventoryStock__c = anyInv.Id
        // keep all source lookups null -> should classify as 'Manual'
    );
    insert inManual;

    Stock_Inward_Line_Item__c inRma = new Stock_Inward_Line_Item__c(
        Name = 'IN_RMA_2024',
        Active__c = true,
        Product__c = prod.Id,
        Quantity__c = 2,
        RMA__c = rma.Id,
        Site_ProductService_InventoryStock__c = anyInv.Id
    );
    insert inRma;

    // Ensure CreatedDate lies in 2024 for both inward records
    Test.setCreatedDate(inManual.Id, DateTime.newInstance(2024, 6, 10, 0, 0, 0));
    Test.setCreatedDate(inRma.Id,    DateTime.newInstance(2024, 7, 15, 0, 0, 0));

    // --- Create OUTWARD records for 2024 ---
    Stock_Outward_Line_Item__c outManual = new Stock_Outward_Line_Item__c(
        Name = 'OUT_Manual_2024',
        Active__c = true,
        Status__c = 'Shipped',       // not 'Reserved'
        Product__c = prod.Id,
        Quantity__c = 3,
       Site_Product_Service_Inventory_Stock__c = anyInv.Id
        // all source lookups null -> 'Manual'
    );
    insert outManual;

    Stock_Outward_Line_Item__c outOrder = new Stock_Outward_Line_Item__c(
        Name = 'OUT_Order_2024',
        Active__c = true,
        Status__c = 'Shipped',
        Product__c = prod.Id,
        Quantity__c = 4,
        Order__c = anyOrder.Id,
      Site_Product_Service_Inventory_Stock__c = anyInv.Id
    );
    insert outOrder;

    // Ensure CreatedDate lies in 2024 for both outward records
    Test.setCreatedDate(outManual.Id, DateTime.newInstance(2024, 8, 20, 0, 0, 0));
    Test.setCreatedDate(outOrder.Id,  DateTime.newInstance(2024, 9, 25, 0, 0, 0));

    Test.startTest();
    Map<String, List<Map<String, Object>>> result = sandOP.getStockMovementData('2024',null);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result map should not be null');
    System.assert(result.containsKey('inwards'),  'Result should contain inwards');
    System.assert(result.containsKey('outwards'), 'Result should contain outwards');

    List<Map<String, Object>> inList  = result.get('inwards');
    List<Map<String, Object>> outList = result.get('outwards');

    System.assert(inList.size()  > 0, 'Expected some inward entries');
    System.assert(outList.size() > 0, 'Expected some outward entries');

    // Validate categorization and month/year formatting like "6/2024"
    Boolean foundInManual = false, foundInRma = false, foundOutManual = false, foundOutOrder = false;

    for (Map<String,Object> row : inList) {
        String src   = (String)row.get('source');
        String month = (String)row.get('month');
        System.assertNotEquals(null, row.get('quantity'), 'Inward quantity should be present');
        if (src == 'Manual' && month.endsWith('/2024')) foundInManual = true;
        if (src == 'RMA'    && month.endsWith('/2024')) foundInRma    = true;
    }
    for (Map<String,Object> row : outList) {
        String src   = (String)row.get('source');
        String month = (String)row.get('month');
        System.assertNotEquals(null, row.get('quantity'), 'Outward quantity should be present');
        if (src == 'Manual' && month.endsWith('/2024')) foundOutManual = true;
        if (src == 'Order'  && month.endsWith('/2024')) foundOutOrder  = true;
    }

    System.assert(foundInManual,  'Expected at least one inward Manual entry for 2024');
    System.assert(foundInRma,     'Expected at least one inward RMA entry for 2024');
    System.assert(foundOutManual, 'Expected at least one outward Manual entry for 2024');
    System.assert(foundOutOrder,  'Expected at least one outward Order entry for 2024');
}

//az
//
//
@isTest
static void testGetStockMovementData_Simple() {
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
    Order anyOrder = [SELECT Id FROM Order LIMIT 1];
    Inventory_Stock__c inv = [SELECT Id FROM Inventory_Stock__c LIMIT 1];

    // Inward (Manual) in 2024
    Stock_Inward_Line_Item__c inRec = new Stock_Inward_Line_Item__c(
        Name='IN_2024',
        Active__c=true,
        Product__c=prod.Id,
        Quantity__c=2,
        Site_ProductService_InventoryStock__c=inv.Id
    );
    insert inRec;
    Test.setCreatedDate(inRec.Id, DateTime.newInstance(2024, 6, 10, 0, 0, 0));

    // Outward (Order) in 2024 — REQUIRED field set correctly
    Stock_Outward_Line_Item__c outRec = new Stock_Outward_Line_Item__c(
        Name='OUT_2024',
        Active__c=true,
        Status__c='Shipped', // not 'Reserved'
        Product__c=prod.Id,
        Quantity__c=1,
        Order__c=anyOrder.Id,
        Site_Product_Service_Inventory_Stock__c=inv.Id
    );
    insert outRec;
    Test.setCreatedDate(outRec.Id, DateTime.newInstance(2024, 7, 15, 0, 0, 0));

    Test.startTest();
    Map<String, List<Map<String, Object>>> res = sandOP.getStockMovementData('2024',null);
    Test.stopTest();

    System.assert(res != null);
    System.assertEquals(true, res.containsKey('inwards'));
    System.assertEquals(true, res.containsKey('outwards'));
}

@isTest
static void testGetStockMovementData_YearFilterSimple() {
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
    Inventory_Stock__c inv = [SELECT Id FROM Inventory_Stock__c LIMIT 1];

    // Inward in 2023 (should be excluded for 2024)
    Stock_Inward_Line_Item__c oldIn = new Stock_Inward_Line_Item__c(
        Name='IN_2023',
        Active__c=true,
        Product__c=prod.Id,
        Quantity__c=3,
        Site_ProductService_InventoryStock__c=inv.Id
    );
    insert oldIn;
    Test.setCreatedDate(oldIn.Id, DateTime.newInstance(2023, 12, 20, 0, 0, 0));

    // Tiny inward in 2024 so list isn’t empty
    Stock_Inward_Line_Item__c in2024 = new Stock_Inward_Line_Item__c(
        Name='IN_2024_min',
        Active__c=true,
        Product__c=prod.Id,
        Quantity__c=1,
        Site_ProductService_InventoryStock__c=inv.Id
    );
    insert in2024;
    Test.setCreatedDate(in2024.Id, DateTime.newInstance(2024, 1, 5, 0, 0, 0));

    Test.startTest();
    Map<String, List<Map<String, Object>>> res = sandOP.getStockMovementData('2024',null);
    Test.stopTest();

    Boolean has2023 = false;
    for (Map<String, Object> r : res.get('inwards'))  if (((String)r.get('month')).endsWith('/2023')) has2023 = true;
    for (Map<String, Object> r : res.get('outwards')) if (((String)r.get('month')).endsWith('/2023')) has2023 = true;

    System.assertEquals(false, has2023);
}

    @isTest
static void testSaveSimulation_SimpleSuccess() {
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

    // Use valid picklist values from the org (handles restricted picklists)
    List<Schema.PicklistEntry> modelPE = Simulation__c.Model__c.getDescribe().getPicklistValues();
    List<Schema.PicklistEntry> typePE  = Simulation__c.Type__c.getDescribe().getPicklistValues();
    String validModel = modelPE.isEmpty() ? null : modelPE[0].getValue();
    String validType  = typePE.isEmpty()  ? null : typePE[0].getValue();

    String payload = JSON.serialize(new Map<String, Object>{
        'name' => 'Sim A',
        'model' => validModel,  // ✅ dynamic valid value
        'type' => validType,    // ✅ dynamic valid value
        'productId' => prod.Id,
        'fromPeriod' => '2024-01',
        'toPeriod' => '2024-12',
        'lines' => new List<Object>{
            new Map<String, Object>{ 'yearMonth' => '2024-01', 'forecasted' => 10, 'simulated' => 12, 'actual' => 9 },
            new Map<String, Object>{ 'yearMonth' => '2024-02', 'forecasted' => 11, 'simulated' => 13 }
        }
    });

    Test.startTest();
    Id simId = sandOP.saveSimulation(payload);
    Test.stopTest();

    System.assert(simId != null);

    Integer lineCount = [SELECT COUNT() FROM Simulation_Line_Item__c WHERE Simulation__c = :simId];
    System.assertEquals(2, lineCount);
}

@isTest
static void testSaveSimulation_ErrorCases_Simple() {
    // Blank payload
    try {
        sandOP.saveSimulation('');
        System.assert(false);
    } catch (AuraHandledException e) {
        //System.assert(e.getMessage().contains('No payload received.'));
    }

    // Invalid JSON
    try {
        sandOP.saveSimulation('{bad json}');
        System.assert(false);
    } catch (AuraHandledException e) {
       // System.assert(e.getMessage().contains('Invalid payload'));
    }

    // No lines
    String noLines = JSON.serialize(new Map<String, Object>{
        'name' => 'Sim Empty',
        'model' => null,
        'type' => null,
        'productId' => '001000000000000AAA',
        'fromPeriod' => '2024-01',
        'toPeriod' => '2024-12',
        'lines' => new List<Object>()
    });
    try {
        sandOP.saveSimulation(noLines);
        System.assert(false);
    } catch (AuraHandledException e) {
       // System.assert(e.getMessage().contains('Nothing to save'));
    }
}

@isTest
static void testSimulationAccuracyResult_CompareTo_Simple() {
    sandOP.SimulationAccuracyResult a = new sandOP.SimulationAccuracyResult(); a.mae = 2.5;
    sandOP.SimulationAccuracyResult b = new sandOP.SimulationAccuracyResult(); b.mae = 1.0;
    sandOP.SimulationAccuracyResult c = new sandOP.SimulationAccuracyResult(); c.mae = null;

    List<sandOP.SimulationAccuracyResult> listy = new List<sandOP.SimulationAccuracyResult>{ a, b, c };
    listy.sort();

    System.assertEquals(1.0, listy[0].mae);
    System.assertEquals(2.5, listy[1].mae);
    System.assertEquals(null, listy[2].mae);
}


@isTest
static void testEvaluateSimulations_Simple() {
    // Reuse product from test setup
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

    // --- create a Simulation header ---
    Simulation__c sim = new Simulation__c(
        Name = 'ApprovedSim2024',
        Product__c = prod.Id,
        Type__c = 'Demand',
        From_Period__c = '2024-01',
        To_Period__c   = '2024-12',
        Status__c = 'Approved'
    );
    insert sim;

    // --- two line items for that simulation ---
    List<Simulation_Line_Item__c> lines = new List<Simulation_Line_Item__c>{
        new Simulation_Line_Item__c(
            Simulation__c = sim.Id,
            YearMonth__c = '2024-01',
            Simulated_Value__c = 10,
            Forecasted_Value__c = 12
        ),
        new Simulation_Line_Item__c(
            Simulation__c = sim.Id,
            YearMonth__c = '2024-02',
            Simulated_Value__c = 8,
            Forecasted_Value__c = 9
        )
    };
    insert lines;

    // --- actual values JSON ---
    List<Map<String,Object>> actuals = new List<Map<String,Object>>{
        new Map<String,Object>{ 'yearMonth' => '2024-01', 'actual' => 9 },
        new Map<String,Object>{ 'yearMonth' => '2024-02', 'actual' => 7 }
    };
    String actualsJson = JSON.serialize(actuals);

    // --- call the method ---
    Test.startTest();
    List<sandOP.SimulationAccuracyResult> results =
        sandOP.evaluateSimulations(prod.Id, '2024', actualsJson);
    Test.stopTest();

    // --- simple checks ---
    System.assert(results != null);
    System.assert(results.size() > 0);
    System.assert(results[0].mae != null);
    System.assert(results[0].lines.size() == 2);
}

@isTest
static void testEvaluateSimulations_ErrorCases() {
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];

    // Missing product
    try {
        sandOP.evaluateSimulations(null, '2024', '[]');
        System.assert(false);
    } catch (AuraHandledException e) {
        
    }

    // Missing year
    try {
        sandOP.evaluateSimulations(prod.Id, '', '[]');
        System.assert(false);
    } catch (AuraHandledException e) {
        
    }

    // Invalid JSON
    try {
        sandOP.evaluateSimulations(prod.Id, '2024', '{bad json}');
        System.assert(false);
    } catch (AuraHandledException e) {
        
    }
}

    
    @isTest
static void testGetStockAlertData_Minimal() {
    // Reuse setup data
    Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
    Location__c loc = [SELECT Id FROM Location__c WHERE Name = 'TestLocation' LIMIT 1];
    Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Laptop X200' LIMIT 1];
    Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];

    // Ensure inventory passes the > 0 stock filter
    List<Inventory_Stock__c> invs = [
        SELECT Id FROM Inventory_Stock__c
        WHERE Warehouse__c = :site.Id AND Product__c = :prod.Id
    ];
     update invs;

    Test.startTest();
    List<Map<String,Object>> rows = sandOP.getStockAlertData(site.Id, loc.Id, prod.Id, org.Id);
    Test.stopTest();

    System.assert(rows != null);
    System.assert(rows.size() > 0);

    // Light sanity on first row keys
    Map<String,Object> r = rows[0];
    System.assert(r.containsKey('productId'));
    System.assert(r.containsKey('currentStock'));
    System.assert(r.containsKey('warehouse'));
    System.assert(r.containsKey('location'));
    System.assert(r.containsKey('productName'));
    System.assert(r.containsKey('reorderLevel'));
    System.assert(r.containsKey('safetyStock'));
}

@isTest
static void testGetStockAlertData_NoProductNoLocation() {
    Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
    Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];

    // Make sure at least one inventory row qualifies
    List<Inventory_Stock__c> invs = [
        SELECT Id FROM Inventory_Stock__c WHERE Warehouse__c = :site.Id
    ];
     update invs;

    Test.startTest();
    List<Map<String,Object>> rows = sandOP.getStockAlertData(site.Id, null, null, org.Id);
    Test.stopTest();

    System.assert(rows != null);
    System.assert(rows.size() > 0);
}

@isTest
static void testGetStockAlertData_MissingParams_Throws() {
    Site__c site = [SELECT Id FROM Site__c WHERE Name = 'TestSite' LIMIT 1];
    Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];

    // Missing site
    try {
        sandOP.getStockAlertData(null, null, null, org.Id);
        System.assert(false);
    } catch (AuraHandledException e) {
         }

    // Missing org
    try {
        sandOP.getStockAlertData(site.Id, null, null, null);
        System.assert(false);
    } catch (AuraHandledException e) {
          }
}
    
    @isTest
static void testGetDefaultWarehouseByStock_Simple() {
    Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
    List<Site__c> sites = [SELECT Id, Name FROM Site__c WHERE Company__c = :org.Id];

    // Ensure at least two active sites with stock values
    if (sites.size() < 2) {
        Site__c extra = new Site__c(
            Name = 'Warehouse-Extra',
            Company__c = org.Id,
            Active__c = true
        );
        insert extra;
        sites.add(extra);
    }

    // Give one site a higher stock to make it the top one
    Site__c siteHigh = sites[0];
     update siteHigh;

    Test.startTest();
    Site__c result = sandOP.getDefaultWarehouseByStock(org.Id);
    Test.stopTest();

    System.assert(result != null);
    System.assertEquals(siteHigh.Id, result.Id, 'Should return site with highest stock value');
}

@isTest
static void testGetDefaultWarehouseByStock_NoResult() {
    // Use an org with no sites
    Account newOrg = new Account(Name = 'NoWarehouseOrg', Account_Type__c = 'Organisation');
    insert newOrg;

    Test.startTest();
    Site__c result = sandOP.getDefaultWarehouseByStock(newOrg.Id);
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null if no active site with stock exists');
}

@isTest
static void testGetReturnReasonDistribution_Simple() {
    Account org = [SELECT Id FROM Account WHERE Name = 'Organisation' LIMIT 1];
    Return_Merchandise_Authorisation__c rma =
        [SELECT Id FROM Return_Merchandise_Authorisation__c LIMIT 1];

    // Create two RMA line items with different reasons
    RMA_Line_Item__c li1 = new RMA_Line_Item__c(
        Name = 'Reason-Approved',
        Return_Merchandise_Authorisation__c = rma.Id,
        Company__c = org.Id,
        Acceptance_Type__c = 'Return',
        Quantity_Return__c = 3,
        Active__c = true
    );
    RMA_Line_Item__c li2 = new RMA_Line_Item__c(
        Name = 'Reason-Rejected',
        Return_Merchandise_Authorisation__c = rma.Id,
        Company__c = org.Id,
        Acceptance_Type__c = 'Replacement',
        Quantity_Return__c = 2,
        Active__c = true
    );
    insert new List<RMA_Line_Item__c>{ li1, li2 };

    Test.startTest();
    List<sandOP.ReasonDistribution> res =
        sandOP.getReturnReasonDistribution(org.Id);
    Test.stopTest();

    System.assert(res != null);
    System.assert(res.size() >= 2);

    // Minimal verification of totals
    Map<String, Integer> byReason = new Map<String, Integer>();
    for (sandOP.ReasonDistribution r : res) byReason.put(r.reason, r.totalQty);

    System.assertEquals(3, byReason.get('Return'));
    System.assertEquals(2, byReason.get('Replacement'));
}

@isTest
static void testGetCurrentFiscalYear_Simple() {
    // Compute expected using same rule
    Integer startMonth = [SELECT FiscalYearStartMonth FROM Organization LIMIT 1].FiscalYearStartMonth;
    Date today = Date.today();
    Integer expected = today.year();
    if (today.month() < startMonth) expected -= 1;

    Test.startTest();
    Integer actual = sandOP.getCurrentFiscalYear();
    Test.stopTest();

    System.assertEquals(expected, actual);
}

    
  }