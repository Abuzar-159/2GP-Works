@isTest
public with sharing class financialPlanningtestclass {
    @isTest
    private static void unit1() {

         Accounting_Period__c ap = new Accounting_Period__c(Name='Test', Start_Date__c=system.today(),
                                                                       End_Date__c=system.today(), Status__c='Closed', Date_Locked__c=system.today());
        insert ap;
        Product2 prod = New Product2(Name='test Prod',IsActive=true);
        insert prod;
        Account acc = new Account(Name='Test',Account_type__c = 'Organisation',Default__c = true); 
        insert acc;
        AccountsPayable.DefaultOrganisation();
         Account vendor = new Account(Name='Test Supplier',Account_type__c = 'Vendor');
        insert vendor;
        Account customer = new Account(Name='Customer',Account_type__c = 'Customer');
        insert customer;
        Contact contact = new Contact(FirstName='Test',LastName='Contact',AccountId=customer.id,Phone='1234567890',Email='test@test.com');
        insert contact;
        Address__c sAddress = new Address__c(Customer__c=customer.id,Contact__c=contact.id,Active__c=true,Address_Line1__c='Test Recipient Line 1', Address_Line2__c='Line 2', Address_Line3__c='test', City__c='Long Beach',State__c='California', Postal_Code__c='90805', Country__c = 'United States', Is_Shipping_Address__c=true);
        insert sAddress;
        Channel__c salepoint = new Channel__c(Name = 'Sale Point',  Active__c=true, Street__c = 'Test Sndr Address Line 1',City__c = 'COLORADO SPRINGS',State_Province__c = 'Colorado',Country__c = 'United States',Zip_Postal_Code__c = '80915', Shipper_Name__c = 'Apex', Company__c = 'ApexCloud', Phone__c = '1234567890',
                                              Ship_From_Address__c=sAddress.Id);
        insert salepoint;
        PO__c po = new PO__c(Vendor__c = vendor.Id);
        insert po;
        RecordType rTypeProfile = [Select Id, Name From RecordType Where SobjectType='BILL__c' And Name='Advance to vendor' Limit 1];
        BILL__c bill = new BILL__c(Vendor__c = vendor.Id,recordTypeId=rTypeProfile.Id, Amount_Paid__c=10);
        try{ insert bill; } catch(exception e){ }
        
         
        Invoice__c Invoice=new Invoice__c(Name='INV-0001', Posted_Date__c=System.today(),Active__c=true, Posted__c=true, Discount_Amount__c=10);
        insert Invoice; 
       
        Payment__c pay = new Payment__c(Payment_Type__c = 'Voucher',Accounts__c = vendor.Id,Amount__c=0);
        insert pay;
        Voucher__c voucher = new Voucher__c(name='test',Amount__c=180,Vendor__c=vendor.Id,Vendor_invoice_Bill__c =bill.Id );
        insert voucher;
        pay.Voucher__c=voucher.Id;
        update pay;
        PO__c PO1 = new PO__c(Name = 'testPO1', Vendor__c = vendor.Id, Company__c = acc.Id, Ready_To_Receive__c = true);
        insert PO1;
        Purchase_Line_Items__c poli = new Purchase_Line_Items__c(Name= 'test PO',Purchase_Orders__c = PO1.Id,Product__c=prod.Id,Quantity__c=5,Unit_Price__c=12);
        insert poli;
        RecordType billitemRecId = [Select Id, Name From RecordType Where SobjectType='Bill_Line_Item__c' And Name='Advance to vendor' Limit 1];
        Bill_Line_Item__c billItem1 = new Bill_Line_Item__c(Name= 'Test bill01',Purchase_Order_Line_Items__c=poli.Id,BILL__c = bill.Id, Sort_Order__c=10);
        insert billItem1;
        Invoice__c inv = new Invoice__c(Name='tst',account__c=customer.Id);
        insert inv;
        Discount_Plan__c displan = new Discount_Plan__c(Name='testdisplan',Vendor__c=vendor.Id,Due_Date_Days__c=20,Discount_Percent__c=10);
        insert displan; 
        
        Debit_Note__c debitNote = new Debit_Note__c(Account__c=vendor.id,Name='Test',Amount__c=120, Vendor_Invoice_Bill__c=bill.Id);
        insert debitNote;
        
        Debit_Note_Item__c debititem = new Debit_Note_Item__c(Name='test',Debit_Note__c=debitNote.Id);
        insert debititem;
        
        Debit_Note_Item__c debititem2 = new Debit_Note_Item__c(Name='test2',Debit_Note__c=debitNote.Id, Bill_Line_Item__c=billItem1.Id);
        insert debititem2;
        
        Return_Merchandise_Authorisation__c rma = new Return_Merchandise_Authorisation__c(Name='test', Channel__c=salepoint.Id, Address__c=sAddress.Id);
        insert rma;
        
        Credit_Note__c creditNote = new Credit_Note__c(Name='Test',Amount__c=200,Active__c=true,    Credit__c=200,Account__c=customer.id, Company__c = acc.Id);
        insert creditNote;
        
        Chart_of_Accounts__c coa = new Chart_of_Accounts__c(Name='Inventory', Company__c = acc.Id);
        insert coa;
        
        Id recordType = Schema.Sobjecttype.Chart_of_Accounts__c.getRecordTypeInfosByName().get('Income/Revenue').getRecordTypeId();
        
        Chart_of_Accounts__c coa1 = new Chart_of_Accounts__c(Name='Inventory', Company__c = acc.Id, RecordTypeId=recordType);
        insert coa1;
        
        Product2 ps = new Product2(Name='test',isActive=true, Expense_Account__c = coa.Id, Revenue_Account__c = coa1.Id, Inventory_Account__c = coa.Id);
        insert ps;

          Chart_of_Accounts__c coa3 = new Chart_of_Accounts__c(Name='Inventory', Company__c = acc.Id);
        insert coa3;

         Project__c proj = new Project__c(Name = 'Test project',Active__c = true);
        insert proj;

        Budget_Plan__c bp1 = new Budget_Plan__c(UnPosted_Actual_Expenditures__c=false, Name = 'test BP',Organisation__c = acc.Id);
        insert bp1;
        Budget_Account__c bc1 = new Budget_Account__c(Name = 'test BC',Budget_Plan__c = bp1.Id,Project__c = proj.Id,Organisation__c = acc.Id,Amount__c =100,Committed_Amount__c = 50,Consumed_Amount__c=20,First_Quarter_Amount__c = 25);
        insert bc1;
        
        
        
         Date fromDate = Date.today().addDays(-10); // 10 days ago
        Date toDate = Date.today();                // today
 test.startTest();
       
         financialplanning.getMonthlyCreditDebitSummary(2024);
         financialplanning.getMonthlyIncomeExpense(2024);
            financialplanning.getChartOfAccountsByType('Expense');
            financialplanning.getCustomerInvoiceSummary('Overdue');
            financialplanning.getMonthlyIncomeExpensenew(fromDate, toDate);
            financialplanning.getOverallIncomeAndExpenseTotals();
            financialplanning.getOverallExpenseBreakdown();
            financialplanning.getFilteredExpenseBreakdown(fromDate, toDate);
            financialplanning.getChartOfAccountTotals();
            financialplanning.getProjectBudgetsByChartOfAccount(coa.Id);
            financialplanning.getProjectsByChartOfAccount(coa.Id);
            financialplanning.getSingleProjectBudget(coa.Id, proj.Id);
            financialplanning.getChartOfAccountsWithBudgetAccounts();
        financialplanning.getCurrencySymbol();
        financialplanning.getGroupedInvoiceBillDetails('Overdue');
        financialplanning.getMonthlyIncomeExpenseWithPrediction();
        financialplanning.getDefaultOrg();
        financialplanning.getSingleProjectBudgetSimulated(proj.Id);
        financialplanning.getMonthlyExpensesOnly(2021);
        financialplanning.getProjectIDs();
          Map<String, Object> result = financialplanning.getYearlyIncomeAndExpenseWithPrediction();

  test.stopTest();



        

    }
    
    
       @isTest
    private static void unit2() {
        // 🏗️ Create test Organisation
        Account org = new Account(Name = 'Test Org');
        insert org;

        // 🧾 Insert invoices (last 3 years)
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < 24; i++) {
            invoices.add(new Invoice__c(
                Paid__c = true,
                Invoice_Date__c = Date.today().addMonths(-i),
                Company__c = org.Id
            ));
        }
        insert invoices;

        // 📑 Insert current year bills
        Integer year = Date.today().year();
        List<Bill__c> bills = new List<Bill__c>();
        for (Integer i = 1; i <= 6; i++) {
            bills.add(new Bill__c(
                Status__c = 'Paid',
                Bill_Date__c = Date.newInstance(year, i, 10),
                Total_Amount__c = 500 + i,
                Company__c = org.Id
            ));
        }
        insert bills;

        // 💳 Insert current year expenses
        List<Expense__c> expenses = new List<Expense__c>();
        for (Integer i = 1; i <= 6; i++) {
            expenses.add(new Expense__c(
                Paid__c = true,
                Date__c = Date.newInstance(year, i, 15)
            ));
        }
        insert expenses;

        // 📥 Prepare simulation input map
        Map<String, Object> monthlySim = new Map<String, Object>{
            'income' => 12000,
            'expense' => 8000
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'Jan' => monthlySim,
            'Feb' => monthlySim,
            'Mar' => monthlySim
        };
            
            
            
        String inputText = 'for purchase order,amount 2000, month july 2025';

        Test.startTest();
        try {
            String result = financialplanning.refineResponse(inputText); 
        } catch (Exception e) {
            System.debug('Expected callout exception: ' + e.getMessage());
        }
                Map<String, Object> result = financialplanning.simulateForecastWithInputs(inputMap);

        Test.stopTest();

    }
  
}