public with sharing class financialplanning {



    //Saqlain part Code 

     @AuraEnabled(cacheable=true)
    public static String getCurrencySymbol() {
    Boolean multiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');
    String currencyISO;
    Decimal currencyRate;
    String userIsoCode;

    String selectedIso = null; // ← no input, uses user's default

    if (selectedIso != null) {
        currencyISO = selectedIso;
    } else {
        currencyISO = UserInfo.getDefaultCurrency();
    }

    if (multiCurrencyEnabled) {
        userIsoCode = currencyISO;			String iso = userIsoCode;		String q = 'SELECT IsoCode, conversionRate FROM CurrencyType WHERE IsoCode = :iso';			currencyRate = (Decimal) Database.query(q)[0].get('conversionRate');
    } else {
        userIsoCode = currencyISO;
        currencyRate = 1;
    }

    // ✅ Symbol mapping
    Map<String, String> symbolMap = new Map<String, String>{
        'USD' => '$',
        'GBP' => '£',
        'EUR' => '€',
        'JPY' => '¥'
    };

    return symbolMap.containsKey(currencyISO) ? symbolMap.get(currencyISO) : currencyISO;
}


    @AuraEnabled(cacheable=true)
    public static Account getDefaultOrg() {
      
      return UtilClass.getOrganisationByLogin_Employee();
}

   @AuraEnabled(cacheable=true)
public static Map<String, List<Decimal>> getMonthlyCreditDebitSummary(Integer year) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    System.debug('🔍 Organisation ID: ' + org.Id);
    System.debug('📅 Filtering by Year: ' + year);

    // Get credit notes with valid date
    List<AggregateResult> creditResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Balance__c) total
        FROM Credit_Note__c
        WHERE Company__c = :org.Id
            AND Date__c != null
            AND CALENDAR_YEAR(Date__c) = :year
        GROUP BY CALENDAR_MONTH(Date__c)
        ORDER BY CALENDAR_MONTH(Date__c)
    ];

    // Get debit notes with valid date
    List<AggregateResult> debitResults = [
        SELECT CALENDAR_MONTH(Credit_Note_Date__c) month, SUM(Debit__c) total
        FROM Debit_Note__c
        WHERE Company__c = :org.Id
            AND Credit_Note_Date__c != null
            AND CALENDAR_YEAR(Credit_Note_Date__c) = :year
        GROUP BY CALENDAR_MONTH(Credit_Note_Date__c)
        ORDER BY CALENDAR_MONTH(Credit_Note_Date__c)
    ];

    List<Decimal> credits = new List<Decimal>(new Decimal[12]);
    List<Decimal> debits = new List<Decimal>(new Decimal[12]);

    for (AggregateResult ar : creditResults) {
        Integer month = (Integer) ar.get('month');        Decimal total = (Decimal) ar.get('total');        credits[month - 1] = total;
        System.debug('✅ Credit - Month: ' + month + ', Amount: ' + total);
    }

    for (AggregateResult ar : debitResults) {
        Integer month = (Integer) ar.get('month');        Decimal total = (Decimal) ar.get('total');        debits[month - 1] = total;
        System.debug('✅ Debit - Month: ' + month + ', Amount: ' + total);
    }

    for (Integer i = 0; i < 12; i++) {
        if (credits[i] == null) credits[i] = 0;
        if (debits[i] == null) debits[i] = 0;
    }

    System.debug('📈 Final Monthly Credits: ' + credits);
    System.debug('📉 Final Monthly Debits: ' + debits);

    return new Map<String, List<Decimal>>{
        'credits' => credits,
        'debits' => debits
    };
}


@AuraEnabled(cacheable=true)
public static Map<String, List<Decimal>> getMonthlyCreditDebitSummaryForFiscalYear(Date fiscalStartDate) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    System.debug('🔎 Organisation: ' + org);
    System.debug('🗓️ Fiscal Start Date: ' + fiscalStartDate);

    Date fiscalEndDate = fiscalStartDate.addMonths(12).addDays(-1);
    System.debug('🗓️ Fiscal End Date: ' + fiscalEndDate);

    // ---------------- Credit Notes ----------------
    List<AggregateResult> creditResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Balance__c) total
        FROM Credit_Note__c
        WHERE Company__c = :org.Id
            AND Date__c != null
            AND Date__c >= :fiscalStartDate
            AND Date__c <= :fiscalEndDate
        GROUP BY CALENDAR_MONTH(Date__c)
        ORDER BY CALENDAR_MONTH(Date__c)
    ];

    // ---------------- Debit Notes ----------------
    List<AggregateResult> debitResults = [
        SELECT CALENDAR_MONTH(Credit_Note_Date__c) month, SUM(Debit__c) total
        FROM Debit_Note__c
        WHERE Company__c = :org.Id
            AND Credit_Note_Date__c != null
            AND Credit_Note_Date__c >= :fiscalStartDate
            AND Credit_Note_Date__c <= :fiscalEndDate
        GROUP BY CALENDAR_MONTH(Credit_Note_Date__c)
        ORDER BY CALENDAR_MONTH(Credit_Note_Date__c)
    ];

    // ---------------- Final Arrays ----------------
    List<Decimal> credits = new List<Decimal>(new Decimal[12]);
    List<Decimal> debits = new List<Decimal>(new Decimal[12]);

    Integer fiscalStartMonth = fiscalStartDate.month(); // 1–12

    // Map credits into fiscal year index
    for (AggregateResult ar : creditResults) {
        Integer m = (Integer) ar.get('month');  // Calendar month 1–12
        Decimal total = (Decimal) ar.get('total');
        Integer idx = Math.mod((m - fiscalStartMonth + 12), 12); // 0–11, fiscal-shifted
        credits[idx] = total;
        System.debug('✅ Credit → Month ' + m + ' (Index ' + idx + '): ' + total);
    }

    // Map debits into fiscal year index
    for (AggregateResult ar : debitResults) {
        Integer m = (Integer) ar.get('month');  
        Decimal total = (Decimal) ar.get('total');
        Integer idx = Math.mod((m - fiscalStartMonth + 12), 12);
        debits[idx] = total;
        System.debug('✅ Debit → Month ' + m + ' (Index ' + idx + '): ' + total);
    }

    // Fill nulls
    for (Integer i = 0; i < 12; i++) {
        if (credits[i] == null) credits[i] = 0;
        if (debits[i] == null) debits[i] = 0;
    }

    System.debug('🧬 Final Fiscal Credits: ' + JSON.serialize(credits));
    System.debug('🧬 Final Fiscal Debits: ' + JSON.serialize(debits));

    return new Map<String, List<Decimal>>{
        'credits' => credits,
        'debits' => debits
    };
}



@AuraEnabled(cacheable=true)
public static Map<String, List<Decimal>> getMonthlyIncomeExpense(Integer year) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    System.debug('🔍 Organisation: ' + org);
    System.debug('📅 Year filter: ' + year);

    List<AggregateResult> invoiceResults = [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true
            AND Company__c = :org.Id
            AND Invoice_Date__c != null
            AND CALENDAR_YEAR(Invoice_Date__c) = :year
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
        ORDER BY CALENDAR_MONTH(Invoice_Date__c)
    ];

    List<AggregateResult> billResults = [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid'
            AND Company__c = :org.Id
            AND Bill_Date__c != null
            AND CALENDAR_YEAR(Bill_Date__c) = :year
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
        ORDER BY CALENDAR_MONTH(Bill_Date__c)
    ];

    List<AggregateResult> expenseResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
        WHERE Paid__c = true
            AND Date__c != null
            AND CALENDAR_YEAR(Date__c) = :year
        GROUP BY CALENDAR_MONTH(Date__c)
        ORDER BY CALENDAR_MONTH(Date__c)
    ];

    List<Decimal> income = new List<Decimal>(new Decimal[12]);
    List<Decimal> expense = new List<Decimal>(new Decimal[12]);
    List<Decimal> additionalExpense = new List<Decimal>(new Decimal[12]);

    for (AggregateResult ar : invoiceResults) {
        Integer m = (Integer) ar.get('month');		Decimal total = (Decimal) ar.get('total');		income[m - 1] = total;
        System.debug('✅ Income → Month ' + m + ': $' + total);
    }

    for (AggregateResult ar : billResults) {
        Integer m = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			expense[m - 1] = total;
        System.debug('✅ Bill Expense → Month ' + m + ': $' + total);
    }

    for (AggregateResult ar : expenseResults) {
        Integer m = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			additionalExpense[m - 1] = total;
        System.debug('🆕 Extra Expense → Month ' + m + ': $' + total);
    }

    // Combine both expenses, replace nulls with 0
    for (Integer i = 0; i < 12; i++) {
        if (income[i] == null) income[i] = 0;
        if (expense[i] == null) expense[i] = 0;
        if (additionalExpense[i] == null) additionalExpense[i] = 0;
        expense[i] += additionalExpense[i];
    }

    System.debug('📈 Final Income Array: ' + income);
    System.debug('📉 Final Expense Array (combined): ' + expense);

    return new Map<String, List<Decimal>>{
        'income' => income,
        'expense' => expense
    };
}

@AuraEnabled(cacheable=true)
public static Map<String, List<Decimal>> getMonthlyIncomeExpenseForFiscalYear(Date fiscalStartDate) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    System.debug('🔍 Organisation: ' + org);
    System.debug('📅 Fiscal Start Date: ' + fiscalStartDate);

    Date fiscalEndDate = fiscalStartDate.addMonths(12).addDays(-1);
    System.debug('📅 Fiscal End Date: ' + fiscalEndDate);

    // ---------------- Income (Invoices) ----------------
    List<AggregateResult> invoiceResults = [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true
            AND Company__c = :org.Id
            AND Invoice_Date__c >= :fiscalStartDate
            AND Invoice_Date__c <= :fiscalEndDate
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
    ];

    // ---------------- Bills (Expenses) ----------------
    List<AggregateResult> billResults = [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid'
            AND Company__c = :org.Id
            AND Bill_Date__c >= :fiscalStartDate
            AND Bill_Date__c <= :fiscalEndDate
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ];

    // ---------------- Additional Expenses ----------------
    List<AggregateResult> expenseResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
        WHERE Paid__c = true
            AND Date__c >= :fiscalStartDate
            AND Date__c <= :fiscalEndDate
        GROUP BY CALENDAR_MONTH(Date__c)
    ];

    // ---------------- Final Lists ----------------
    List<Decimal> income = new List<Decimal>(new Decimal[12]);
    List<Decimal> expense = new List<Decimal>(new Decimal[12]);
    List<Decimal> additionalExpense = new List<Decimal>(new Decimal[12]);

    Integer fiscalStartMonthIndex = fiscalStartDate.month() - 1; // 0–11

    for (AggregateResult ar : invoiceResults) {
        Integer m = (Integer) ar.get('month');  // 1–12
        Decimal total = (Decimal) ar.get('total');
    Integer idx = Math.mod((m - 1 - fiscalStartMonthIndex + 12), 12); // fixed
        income[idx] = total;
        System.debug('✅ Income → Month ' + m + ' (Index ' + idx + '): ' + total);
    }

    for (AggregateResult ar : billResults) {			        Integer m = (Integer) ar.get('month');		Decimal total = (Decimal) ar.get('total');			Integer idx = Math.mod((m - 1 - fiscalStartMonthIndex + 12), 12);				expense[idx] = total;
        System.debug('✅ Bill Expense → Month ' + m + ' (Index ' + idx + '): ' + total);
    }

    for (AggregateResult ar : expenseResults) {			Integer m = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			Integer idx = Math.mod((m - 1 - fiscalStartMonthIndex + 12), 12);			additionalExpense[idx] = total;
        System.debug('🆕 Extra Expense → Month ' + m + ' (Index ' + idx + '): ' + total);
    }

    // Fill nulls and combine expenses
    for (Integer i = 0; i < 12; i++) {				if (income[i] == null) income[i] = 0;			if (expense[i] == null) expense[i] = 0;				if (additionalExpense[i] == null) additionalExpense[i] = 0;				expense[i] += additionalExpense[i];
    }

    System.debug('📈 Final Income (Fiscal Year): ' + JSON.serialize(income));
    System.debug('📉 Final Expense (Fiscal Year, combined): ' + JSON.serialize(expense));
    System.debug('----------------------------------------');

    return new Map<String, List<Decimal>>{			'income' => income,			'expense' => expense
    };
}



@AuraEnabled(cacheable=true)
public static Map<String, List<Object>> getChartOfAccountsByType(String recordType) {
    Account org = UtilClass.getOrganisationByLogin_Employee();

    List<Chart_of_Accounts__c> coaList = [
        SELECT Name, Total_Debit__c, Total_Credit__c
        FROM Chart_of_Accounts__c
        WHERE RecordType.Name = :recordType
            AND Company__c = :org.Id
            AND (Total_Debit__c > 5000 OR Total_Credit__c > 5000)
    ];

    List<String> labels = new List<String>();
    List<Decimal> debits = new List<Decimal>();
    List<Decimal> credits = new List<Decimal>();

    for (Chart_of_Accounts__c coa : coaList) {
        labels.add(coa.Name);        debits.add(coa.Total_Debit__c != null ? coa.Total_Debit__c : 0);        credits.add(coa.Total_Credit__c != null ? coa.Total_Credit__c : 0);
    }

    return new Map<String, List<Object>>{
        'labels' => labels,
        'debits' => debits,
        'credits' => credits
    };
}


@AuraEnabled(cacheable=true)
public static Map<String, Object> getCustomerInvoiceSummary(String type) {
    System.debug('--- Method Entry: getCustomerInvoiceSummary ---');
    System.debug('Type: ' + type);

    Map<String, Decimal> summaryMap = new Map<String, Decimal>();
    Map<String, Integer> countMap = new Map<String, Integer>();

    if (type == 'Overdue') {
        List<Invoice__c> overdueInvoices = [
            SELECT Id, Name, Account__r.Name, Account__c, Sub_Total_Amount__c, Status__c
            FROM Invoice__c
            WHERE Status__c = 'Overdue'
        ];

        System.debug('Overdue Invoices Count: ' + overdueInvoices.size());
        System.debug('Overdue Invoices: ' + JSON.serialize(overdueInvoices));   

        for (Invoice__c inv : overdueInvoices) {
            String customer = inv.Account__r != null ? inv.Account__r.Name : 'Unknown';           Decimal amount = inv.Sub_Total_Amount__c != null ? inv.Sub_Total_Amount__c : 0;

            if (!summaryMap.containsKey(customer)) {               summaryMap.put(customer, amount);                countMap.put(customer, 1);
            } else {
                summaryMap.put(customer, summaryMap.get(customer) + amount);                countMap.put(customer, countMap.get(customer) + 1);
            }

            System.debug('Customer: ' + customer + ', Amount: ' + amount);
        }
    } else if (type == 'Unpaid') {        Date today = Date.today();

        List<Bill__c> unpaidBills = [
            SELECT Id, Name, Vendor__r.Name, Total_Amount__c, Due_Date__c, Status__c
            FROM Bill__c
            WHERE Status__c != 'Paid' AND Due_Date__c < :today 
        ];

        System.debug('Unpaid Bills Count: ' + unpaidBills.size());
        System.debug('Unpaid Bills: ' + JSON.serialize(unpaidBills));

        for (Bill__c bill : unpaidBills) {            String vendor = bill.Vendor__r != null ? bill.Vendor__r.Name : 'Unknown';            Decimal amount = bill.Total_Amount__c != null ? bill.Total_Amount__c : 0;

            if (!summaryMap.containsKey(vendor)) {               summaryMap.put(vendor, amount);                countMap.put(vendor, 1);
            } else {
                summaryMap.put(vendor, summaryMap.get(vendor) + amount);                countMap.put(vendor, countMap.get(vendor) + 1);
            }

            System.debug('Vendor: ' + vendor + ', Amount: ' + amount);
        }
    }

    List<String> labels = new List<String>();
    List<Decimal> amounts = new List<Decimal>();
    List<Integer> counts = new List<Integer>();

    for (String key : summaryMap.keySet()) {
        labels.add(key);        amounts.add(summaryMap.get(key));        counts.add(countMap.get(key));
        System.debug('Summary Entry - Name: ' + key + ', Amount: ' + summaryMap.get(key) + ', Count: ' + countMap.get(key));
    }

    Map<String, Object> result = new Map<String, Object>();
    result.put('labels', labels);
    result.put('amounts', amounts);
    result.put('counts', counts);

    System.debug('--- Method Exit: getCustomerInvoiceSummary ---');
    return result;
}
public class InvoiceBillDetail {
    @AuraEnabled public String recordName { get; set; }				@AuraEnabled public String accountId { get; set; }			@AuraEnabled public String recordId { get; set; }			@AuraEnabled public Decimal amount { get; set; }

    public InvoiceBillDetail(String recordName, String accountId, Decimal amount, String recordId) {			this.recordName = recordName;				this.accountId = accountId;			this.amount = amount;			this.recordId = recordId;
    }
}

public class BillDetail {
    @AuraEnabled public String recordName { get; set; }			@AuraEnabled public String recordId { get; set; }			@AuraEnabled public Decimal amount { get; set; }

    public BillDetail(String recordName, Decimal amount, String recordId) {			this.recordName = recordName;			this.amount = amount;			this.recordId = recordId;
    }
}

    @AuraEnabled(cacheable=true)
    public static Object getGroupedInvoiceBillDetails(String type) {
        if (type == 'Overdue') {
            Map<String, List<InvoiceBillDetail>> groupedInvoices = new Map<String, List<InvoiceBillDetail>>();
            List<Invoice__c> invoices = [
                SELECT Id, Name, Account__r.Name, Account__c, Sub_Total_Amount__c
                FROM Invoice__c
                WHERE Status__c = 'Overdue'
            ];

            for (Invoice__c inv : invoices) {
                String customer = inv.Account__r?.Name != null ? inv.Account__r.Name : 'Unknown';				String accountId = inv.Account__c != null ? inv.Account__c : 'Unknown';			Decimal amount = inv.Sub_Total_Amount__c != null ? inv.Sub_Total_Amount__c : 0;

                if (!groupedInvoices.containsKey(customer)) {			groupedInvoices.put(customer, new List<InvoiceBillDetail>());
                }
                groupedInvoices.get(customer).add(new InvoiceBillDetail(inv.Name, accountId, amount, inv.Id));
            }
            return groupedInvoices;
        }

        else if (type == 'Unpaid') {			Map<String, List<BillDetail>> groupedBills = new Map<String, List<BillDetail>>();				Date today = Date.today();

            List<Bill__c> bills = [
                SELECT Id, Name, Vendor__r.Name, Vendor__c, Total_Amount__c
                FROM Bill__c
                WHERE Status__c != 'Paid' AND Due_Date__c < :today
            ];

            for (Bill__c bill : bills) {			String vendor = bill.Vendor__r?.Name != null ? bill.Vendor__r.Name : 'Unknown';			Decimal amount = bill.Total_Amount__c != null ? bill.Total_Amount__c : 0;     String billName = bill.Name != null ? bill.Name : 'Unknown Bill';

                if (!groupedBills.containsKey(vendor)) {			groupedBills.put(vendor, new List<BillDetail>());
                }
                groupedBills.get(vendor).add(new BillDetail(billName, amount, bill.Id));
            }
            return groupedBills;
        }

        return null;
    }








    @AuraEnabled(cacheable=true)
public static Map<String, Map<String, List<Decimal>>> getMonthlyIncomeExpensenew(Date fromDate, Date toDate) {
    Account org = UtilClass.getOrganisationByLogin_Employee();

    List<Decimal> paidIncome = new List<Decimal>(new Decimal[12]);
    List<Decimal> unpaidIncome = new List<Decimal>(new Decimal[12]);
    List<Decimal> paidExpense = new List<Decimal>(new Decimal[12]);
    List<Decimal> unpaidExpense = new List<Decimal>(new Decimal[12]);

    // ✅ Paid Invoices (Income)
    List<AggregateResult> paidInvoiceResults = [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Company__c = :org.Id
            AND Paid__c = true
            AND Invoice_Date__c != null
            AND Invoice_Date__c >= :fromDate
            AND Invoice_Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
    ];

    // ✅ Unpaid Invoices (Income)
    List<AggregateResult> unpaidInvoiceResults = [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Company__c = :org.Id
            AND Paid__c = false
            AND Invoice_Date__c != null
            AND Invoice_Date__c >= :fromDate
            AND Invoice_Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
    ];

    // ✅ Paid Bills (Expenses)
    List<AggregateResult> paidBillResults = [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Company__c = :org.Id
            AND Status__c = 'Paid'
            AND Bill_Date__c != null
            AND Bill_Date__c >= :fromDate
            AND Bill_Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ];

    // ✅ Unpaid Bills (Expenses)
    List<AggregateResult> unpaidBillResults = [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Company__c = :org.Id
            AND Status__c != 'Paid'
            AND Bill_Date__c != null
            AND Bill_Date__c >= :fromDate
            AND Bill_Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ];

    // ✅ Paid My Expenses
    List<AggregateResult> paidMyExpenseResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
       // WHERE Company__c = :org.Id
            WHERE Paid__c = true
            AND Date__c >= :fromDate
            AND Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Date__c)
    ];

    // ✅ Unpaid My Expenses
    List<AggregateResult> unpaidMyExpenseResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
       // WHERE Company__c = :org.Id
            WHERE Paid__c = false
            AND Date__c >= :fromDate
            AND Date__c <= :toDate
        GROUP BY CALENDAR_MONTH(Date__c)
    ];

    // 🔄 Process Results
    for (AggregateResult ar : paidInvoiceResults) {
        Integer month = (Integer) ar.get('month');			paidIncome[month - 1] = (Decimal) ar.get('total');
    }

    for (AggregateResult ar : unpaidInvoiceResults) {
        Integer month = (Integer) ar.get('month');			unpaidIncome[month - 1] = (Decimal) ar.get('total');
    }

    for (AggregateResult ar : paidBillResults) {
        Integer month = (Integer) ar.get('month');			paidExpense[month - 1] = (Decimal) ar.get('total');
    }

    for (AggregateResult ar : unpaidBillResults) {
        Integer month = (Integer) ar.get('month');			unpaidExpense[month - 1] = (Decimal) ar.get('total');
    }

    // 🔄 Add My Expenses to Expense Totals
    for (AggregateResult ar : paidMyExpenseResults) {
        Integer month = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			if (paidExpense[month - 1] == null) paidExpense[month - 1] = 0;			paidExpense[month - 1] += total;
    }

    for (AggregateResult ar : unpaidMyExpenseResults) {
        Integer month = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			if (unpaidExpense[month - 1] == null) unpaidExpense[month - 1] = 0;			unpaidExpense[month - 1] += total;
    }

    // 💡 Null safety
    for (Integer i = 0; i < 12; i++) {
        if (paidIncome[i] == null) paidIncome[i] = 0;
        if (unpaidIncome[i] == null) unpaidIncome[i] = 0;
        if (paidExpense[i] == null) paidExpense[i] = 0;
        if (unpaidExpense[i] == null) unpaidExpense[i] = 0;
    }

    return new Map<String, Map<String, List<Decimal>>>{
        'paid' => new Map<String, List<Decimal>>{
            'income' => paidIncome,
            'expense' => paidExpense
        },
        'unpaid' => new Map<String, List<Decimal>>{
            'income' => unpaidIncome,
            'expense' => unpaidExpense
        }
    };
}


@AuraEnabled(cacheable=true)
public static Map<String, Decimal> getOverallIncomeAndExpenseTotals() {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    System.debug('🏢 Organisation: ' + org.Name);

    // ✅ Get Total Income (all Invoices with valid dates)
    AggregateResult incomeResult = [
        SELECT SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Company__c = :org.Id
            AND Invoice_Date__c != null
    ];

    // ✅ Get Total Expense (Bills with valid dates)
    AggregateResult billExpenseResult = [
        SELECT SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Company__c = :org.Id
            AND Bill_Date__c != null
    ];

    // ✅ Get My Expenses
    AggregateResult myExpenseResult = [
        SELECT SUM(Amount__c) total
        FROM Expense__c
       // WHERE Company__c = :org.Id
            WHERE Date__c != null
    ];

    Decimal totalIncome = (Decimal)(incomeResult.get('total') ?? 0);
    Decimal totalBillExpense = (Decimal)(billExpenseResult.get('total') ?? 0);
    Decimal totalMyExpense = (Decimal)(myExpenseResult.get('total') ?? 0);

    Decimal totalExpense = totalBillExpense + totalMyExpense;

    System.debug('💰 Total Income (All Time): ' + totalIncome);
    System.debug('💸 Total Bill Expense: ' + totalBillExpense);
    System.debug('💸 Total My Expense: ' + totalMyExpense);
    System.debug('📊 Final Total Expense (Bill + My): ' + totalExpense);

    return new Map<String, Decimal>{
        'totalIncome' => totalIncome,
        'totalExpense' => totalExpense
    };
}



public class ExpenseBreakdown {
    @AuraEnabled public Decimal totalExpenseBill { get; set; }
    @AuraEnabled public Decimal totalPOBill { get; set; }
    @AuraEnabled public Decimal totalAdvance { get; set; }
    @AuraEnabled public Decimal totalMyExpense { get; set; } // ✅ New field

    public ExpenseBreakdown() {
        totalExpenseBill = 0.0;
        totalPOBill = 0.0;
        totalAdvance = 0.0;
        totalMyExpense = 0.0; // ✅ Init My Expense
    }
}

@AuraEnabled(cacheable=true)
public static ExpenseBreakdown getOverallExpenseBreakdown() {
    ExpenseBreakdown amt = new ExpenseBreakdown();
    Account org = UtilClass.getOrganisationByLogin_Employee();

    // ✅ Existing: Grouped expense types from Bill object
    for (AggregateResult ar : [
        SELECT RecordType.Name name, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Company__c = :org.Id 
              AND Bill_Date__c != null
              AND RecordType.Name IN ('Expense Bill', 'PO Bill', 'Advance to Vendor')
        GROUP BY RecordType.Name
    ]) {			String name = String.valueOf(ar.get('name'));			Decimal total = (Decimal) ar.get('total');

        if (name == 'Expense Bill') {			amt.totalExpenseBill = total;			} else if (name == 'PO Bill') {			amt.totalPOBill = total;			} else if (name == 'Advance to Vendor') {			amt.totalAdvance = total;
        }
    }

    // ✅ NEW: Add "My Expenses" from Expense__c
    AggregateResult myExpenseResult = [
        SELECT SUM(Amount__c) total
        FROM Expense__c
       // WHERE Company__c = :org.Id 
              WHERE Date__c != null
    ];
    amt.totalMyExpense = (Decimal)(myExpenseResult.get('total') ?? 0);

    // 🔍 Debug logs
    System.debug('🔹 Expense Bill Total: ' + amt.totalExpenseBill);
    System.debug('🔹 PO Bill Total: ' + amt.totalPOBill);
    System.debug('🔹 Advance to Vendor Total: ' + amt.totalAdvance);
    System.debug('🔹 My Expense Total: ' + amt.totalMyExpense);

    // 🧮 Grand Total Log
    Decimal grandTotal = amt.totalExpenseBill + amt.totalPOBill + amt.totalAdvance + amt.totalMyExpense;
    System.debug('🧾 Grand Total of All Expenses: ' + grandTotal);

    return amt;
}


// @AuraEnabled(cacheable=true)
// public static ExpenseBreakdown getFilteredExpenseBreakdown(Date fromDate, Date toDate) {
//     ExpenseBreakdown breakdown = new ExpenseBreakdown();

//     Account org = UtilClass.getOrganisationByLogin_Employee();

//     for (AggregateResult ar : [
//         SELECT RecordType.Name name, SUM(Total_Amount__c) total
//         FROM Bill__c
//         WHERE Company__c = :org.Id
//             AND Bill_Date__c >= :fromDate
//             AND Bill_Date__c <= :toDate
//             AND RecordType.Name IN ('Expense Bill', 'PO Bill', 'Advance to Vendor')
//         GROUP BY RecordType.Name
//     ]) {        String name = String.valueOf(ar.get('name'));        Decimal total = (Decimal)ar.get('total');

//         if (name == 'Expense Bill') {            breakdown.totalExpenseBill = total;       } else if (name == 'PO Bill') {           breakdown.totalPOBill = total;       } else if (name == 'Advance to Vendor') {           breakdown.totalAdvance = total;
//         }
//     }

//     system.debug('📊 Filtered Expense Breakdown: ' + JSON.serialize(breakdown));
//     system.debug('📅 From Date: ' + fromDate + ', To Date: ' + toDate);
//     return breakdown;
// }



@AuraEnabled(cacheable=true)
public static ExpenseBreakdown getFilteredExpenseBreakdown(Date fromDate, Date toDate) {
    ExpenseBreakdown breakdown = new ExpenseBreakdown();
    Account org = UtilClass.getOrganisationByLogin_Employee();

    // 🔹 Bills Breakdown
    for (AggregateResult ar : [
        SELECT RecordType.Name name, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Company__c = :org.Id
            AND Bill_Date__c >= :fromDate
            AND Bill_Date__c <= :toDate
            AND RecordType.Name IN ('Expense Bill', 'PO Bill', 'Advance to Vendor')
        GROUP BY RecordType.Name
    ]) {			String name = String.valueOf(ar.get('name'));			Decimal total = (Decimal) ar.get('total');

        if (name == 'Expense Bill') {			breakdown.totalExpenseBill = total;			} else if (name == 'PO Bill') {			breakdown.totalPOBill = total;			} else if (name == 'Advance to Vendor') {			breakdown.totalAdvance = total;
        }
    }

    // 🔹 My Expenses Breakdown (NEW)
    AggregateResult myExpenseResult = [
        SELECT SUM(Amount__c) total
        FROM Expense__c
        WHERE Date__c >= :fromDate
            AND Date__c <= :toDate
    ];
    breakdown.totalMyExpense = (Decimal)(myExpenseResult.get('total') ?? 0);

    // 📋 Logs
    System.debug('📊 Filtered Expense Breakdown: ' + JSON.serialize(breakdown));
    System.debug('📅 From Date: ' + fromDate + ', To Date: ' + toDate);

    return breakdown;
}




@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getChartOfAccountTotals() {
    Account org = UtilClass.getOrganisationByLogin_Employee(); // Get current org
    System.debug('🏢 Organisation: ' + org.Name);

    // Grouping by Chart of Account
    Map<String, Map<String, Object>> coaMap = new Map<String, Map<String, Object>>();

    List<Budget_Plan__c> plans = [
        SELECT Id, Name, Total_Budget_Amount__c, Consumed_Amount__c,
               Remaining_Amount__c, Committed__c,
               (SELECT Id, Name, Chart_of_Account__r.Name 
                FROM Budget_Account__r)
        FROM Budget_Plan__c
        WHERE Organisation__c = :org.Id
    ];

    for (Budget_Plan__c plan : plans) {
        for (Budget_Account__c acc : plan.Budget_Account__r) {            String chartOfAccount = acc.Chart_of_Account__r != null ? acc.Chart_of_Account__r.Name : 'N/A';

            if (!coaMap.containsKey(chartOfAccount)) {               coaMap.put(chartOfAccount, new Map<String, Object>{                    'chartOfAccount' => chartOfAccount,                    'approved' => 0,                    'consumed' => 0,                    'remaining' => 0,                    'committed' => 0
                });
            }

            Map<String, Object> data = coaMap.get(chartOfAccount);              data.put('approved', (Decimal)data.get('approved') + (plan.Total_Budget_Amount__c != null ? plan.Total_Budget_Amount__c : 0));               data.put('consumed', (Decimal)data.get('consumed') + (plan.Consumed_Amount__c != null ? plan.Consumed_Amount__c : 0));              data.put('remaining', (Decimal)data.get('remaining') + (plan.Remaining_Amount__c != null ? plan.Remaining_Amount__c : 0));              data.put('committed', (Decimal)data.get('committed') + (plan.Committed__c != null ? plan.Committed__c : 0));
        }
    }

    List<Map<String, Object>> resultList = new List<Map<String, Object>>();
    resultList.addAll(coaMap.values());

    System.debug('📊 Org-Filtered Chart of Account Totals: ' + JSON.serialize(resultList));
    return resultList;
}



@AuraEnabled(cacheable=true)
public static Map<String, Object> getChartOfAccountGrandTotal() {				List<Map<String, Object>> chartData = getChartOfAccountTotals(); // call the original function

    Decimal totalApproved = 0;			Decimal totalConsumed = 0;			Decimal totalRemaining = 0;			Decimal totalCommitted = 0;

    for (Map<String, Object> row : chartData) {					totalApproved += (Decimal)(row.get('approved') != null ? row.get('approved') : 0);					totalConsumed += (Decimal)(row.get('consumed') != null ? row.get('consumed') : 0);					totalRemaining += (Decimal)(row.get('remaining') != null ? row.get('remaining') : 0);				totalCommitted += (Decimal)(row.get('committed') != null ? row.get('committed') : 0);
    }


    System.debug('📊 Grand Total - Approved: ' + totalApproved);
    System.debug('📊 Grand Total - Consumed: ' + totalConsumed);

    System.debug('📊 Grand Total - Remaining: ' + totalRemaining);
    System.debug('📊 Grand Total - Committed: ' + totalCommitted);

    return new Map<String, Object>{			'chartOfAccount' => 'Total',				'approved' => totalApproved,				'consumed' => totalConsumed,				'remaining' => totalRemaining,					'committed' => totalCommitted
    };
}



@AuraEnabled(cacheable=true)
public static List<ProjectBudgetWrapper> getProjectBudgetsByChartOfAccount(Id chartOfAccountId) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    Map<Id, ProjectBudgetWrapper> projectData = new Map<Id, ProjectBudgetWrapper>();

    List<Budget_Account__c> accounts = [
        SELECT Id, Project__c, Project__r.Name, Budget_Plan__c,
               Chart_of_Account__c,
               Budget_Plan__r.Total_Budget_Amount__c,
               Budget_Plan__r.Consumed_Amount__c,
               Budget_Plan__r.Remaining_Amount__c,
               Budget_Plan__r.Committed__c
        FROM Budget_Account__c
        WHERE Chart_of_Account__c = :chartOfAccountId
        //AND Budget_Plan__r.Company__c= :org.Id
     
    ];
    System.debug('📊 Total Budget Accounts for Chart of Account ' + chartOfAccountId + ': ' + accounts.size());

    for (Budget_Account__c acc : accounts) {
        Id projectId = acc.Project__c;          if (!projectData.containsKey(projectId)) {              projectData.put(projectId, new ProjectBudgetWrapper(             acc.Project__r.Name, 0, 0, 0, 0
            ));
        }

         System.debug('📊 Processing Budget Account: ' + acc.Id + ', Project: ' + acc.Project__r.Name);
        ProjectBudgetWrapper pbw = projectData.get(projectId);          pbw.total     += acc.Budget_Plan__r.Total_Budget_Amount__c   != null ? acc.Budget_Plan__r.Total_Budget_Amount__c   : 0;     pbw.consumed  += acc.Budget_Plan__r.Consumed_Amount__c       != null ? acc.Budget_Plan__r.Consumed_Amount__c       : 0;     pbw.remaining += acc.Budget_Plan__r.Remaining_Amount__c      != null ? acc.Budget_Plan__r.Remaining_Amount__c      : 0;     pbw.committed += acc.Budget_Plan__r.Committed__c             != null ? acc.Budget_Plan__r.Committed__c             : 0;

    }

    System.debug('📊 Final Project Budget Data: ' + JSON.serialize(projectData.values()));
    return projectData.values();
}

public class ProjectBudgetWrapper {
    @AuraEnabled public String projectName;
    @AuraEnabled public Decimal total;
    @AuraEnabled public Decimal consumed;
    @AuraEnabled public Decimal remaining;
    @AuraEnabled public Decimal committed;

    public ProjectBudgetWrapper(String name, Decimal total, Decimal consumed, Decimal remaining, Decimal committed) {
        this.projectName = name;
        this.total = total;
        this.consumed = consumed;
        this.remaining = remaining;
        this.committed = committed;
    }
}

  @AuraEnabled(cacheable=true)
    public static List<IdNameWrapper> getProjectsByChartOfAccount(Id chartOfAccountId) {
        Set<Id> projectIds = new Set<Id>();
        List<IdNameWrapper> projects = new List<IdNameWrapper>();

        for (Budget_Account__c acc : [
            SELECT Project__c, Project__r.Name
            FROM Budget_Account__c
            WHERE Chart_of_Account__c = :chartOfAccountId
            AND Project__c != null
        ]) {            if (!projectIds.contains(acc.Project__c)) {       projectIds.add(acc.Project__c);          projects.add(new IdNameWrapper(acc.Project__c, acc.Project__r.Name));
            }
        }
        return projects;
    }

    @AuraEnabled(cacheable=true)
    public static ProjectBudgetWrapper getSingleProjectBudget(Id chartOfAccountId, Id projectId) {
        Decimal total = 0, consumed = 0, remaining = 0, committed = 0;

        for (Budget_Account__c acc : [
            SELECT Budget_Plan__r.Total_Budget_Amount__c,
                   Budget_Plan__r.Consumed_Amount__c,
                   Budget_Plan__r.Remaining_Amount__c,
                   Budget_Plan__r.Committed__c
            FROM Budget_Account__c
            WHERE Chart_of_Account__c = :chartOfAccountId
            AND Project__c = :projectId
            AND Budget_Plan__c != null
        ]) {           total     += acc.Budget_Plan__r.Total_Budget_Amount__c   != null ? acc.Budget_Plan__r.Total_Budget_Amount__c   : 0;       consumed  += acc.Budget_Plan__r.Consumed_Amount__c       != null ? acc.Budget_Plan__r.Consumed_Amount__c       : 0;       remaining += acc.Budget_Plan__r.Remaining_Amount__c      != null ? acc.Budget_Plan__r.Remaining_Amount__c      : 0;    committed += acc.Budget_Plan__r.Committed__c             != null ? acc.Budget_Plan__r.Committed__c             : 0;
        }

        return new ProjectBudgetWrapper(null, total, consumed, remaining, committed);
    }

    // public class ProjectBudgetWrapper {
    //     @AuraEnabled public String projectName;
    //     @AuraEnabled public Decimal total;
    //     @AuraEnabled public Decimal consumed;
    //     @AuraEnabled public Decimal remaining;
    //     @AuraEnabled public Decimal committed;

    //     public ProjectBudgetWrapper(String name, Decimal total, Decimal consumed, Decimal remaining, Decimal committed) {
    //         this.projectName = name;
    //         this.total = total;
    //         this.consumed = consumed;
    //         this.remaining = remaining;
    //         this.committed = committed;
    //     }
    // }

    public class IdNameWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;

        public IdNameWrapper(Id id, String name) {  this.id = id;  this.name = name;
        }
    }



@AuraEnabled(cacheable=true)
public static List<Id> getChartOfAccountsWithBudgetAccounts() {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    
    Set<Id> chartOfAccountIds = new Set<Id>();

    List<Budget_Account__c> budgetAccounts = [
        SELECT Chart_of_Account__c
        FROM Budget_Account__c
        WHERE Budget_Plan__r.Organisation__c = :org.Id
        AND Chart_of_Account__c != null
        AND Project__c != null
        AND Budget_Plan__c != null
    ];

    for (Budget_Account__c acc : budgetAccounts) {
        chartOfAccountIds.add(acc.Chart_of_Account__c);
    }
    System.debug('📊 Chart of Accounts with Budget Accounts: ' + chartOfAccountIds);
    
    return new List<Id>(chartOfAccountIds);
}

private static List<Decimal> predictFuture(List<Decimal> values, Integer steps) {
    List<Decimal> forecast = new List<Decimal>();
    if (values == null || values.size() < 2) return forecast;

    Decimal alpha = 0.8;
    Decimal beta = 0.2;
    Decimal level = values[0];
    Decimal trend = values[1] - values[0];

    for (Integer i = 1; i < values.size(); i++) {
        Decimal prevLevel = level;
        level = alpha * values[i] + (1 - alpha) * (level + trend);
        trend = beta * (level - prevLevel) + (1 - beta) * trend;
    }

    for (Integer s = 1; s <= steps; s++) {
        forecast.add((level + s * trend).setScale(2));
    }

    return forecast;
}

@AuraEnabled(cacheable=true)
public static Map<String, Object> getYearlyIncomeAndExpenseWithPrediction() {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    Integer currentYear = Date.today().year();
    Integer startYear = currentYear - 5;
    Integer endYear = currentYear;

    Map<Integer, Decimal> incomeByYear = new Map<Integer, Decimal>();
    Map<Integer, Decimal> expenseByYear = new Map<Integer, Decimal>();

    for (Integer y = startYear; y <= endYear; y++) {
        incomeByYear.put(y, 0);
        expenseByYear.put(y, 0);
    }

    List<AggregateResult> incomeResults = [
        SELECT CALENDAR_YEAR(Invoice_Date__c) yr, SUM(Sub_Total_Amount__c) amt
        FROM Invoice__c
        WHERE Company__c = :org.Id
        AND Invoice_Date__c != null
        GROUP BY CALENDAR_YEAR(Invoice_Date__c)
    ];

    for (AggregateResult res : incomeResults) {
        Integer yr = (Integer)res.get('yr');       if (incomeByYear.containsKey(yr)) {          incomeByYear.put(yr, (Decimal)res.get('amt'));
        }
    }

    List<AggregateResult> expenseResults = [
        SELECT CALENDAR_YEAR(Bill_Date__c) yr, SUM(Total_Amount__c) amt
        FROM Bill__c
        WHERE Company__c = :org.Id
        AND Bill_Date__c != null
        GROUP BY CALENDAR_YEAR(Bill_Date__c)
    ];

    for (AggregateResult res : expenseResults) {
        Integer yr = (Integer)res.get('yr');        if (expenseByYear.containsKey(yr)) {           expenseByYear.put(yr, (Decimal)res.get('amt'));
        }
    }

    List<Integer> years = new List<Integer>();
    List<Decimal> incomeList = new List<Decimal>();
    List<Decimal> expenseList = new List<Decimal>();

    for (Integer y = startYear; y <= endYear; y++) {
        years.add(y);
        incomeList.add(incomeByYear.get(y));
        expenseList.add(expenseByYear.get(y));
    }

    // Predict next 5 years
    List<Decimal> predictedIncomeList = predictFuture(incomeList, 5);
    List<Decimal> predictedExpenseList = predictFuture(expenseList, 5);

    // Append future years
    for (Integer i = 1; i <= 5; i++) {
        years.add(currentYear + i);
    }

    return new Map<String, Object>{
        'years' => years,
        'income' => incomeList,
        'expense' => expenseList,
        'predictedIncome' => predictedIncomeList,
        'predictedExpense' => predictedExpenseList
    };
}



@AuraEnabled(cacheable=true)
public static Map<String, Object> getMonthlyIncomeExpenseWithPrediction() {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    Integer currentYear = Date.today().year();
    Integer currentMonth = Date.today().month();

    Date endDate = Date.today();
    Date startDate = endDate.addYears(-3); // Last 3 years

    // ===== Current Year Actuals =====
    List<Decimal> income = new List<Decimal>(new Decimal[12]);
    List<Decimal> expense = new List<Decimal>(new Decimal[12]);
    List<Decimal> additionalExpense = new List<Decimal>(new Decimal[12]);

    for (Integer i = 0; i < 12; i++) {
        income[i] = 0;
        expense[i] = 0;
        additionalExpense[i] = 0;
    }

    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true AND Company__c = :org.Id AND
              Invoice_Date__c != null AND CALENDAR_YEAR(Invoice_Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
    ]) {			Integer m = (Integer) ar.get('month');			income[m - 1] = (Decimal) ar.get('total');
    }

    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid' AND Company__c = :org.Id AND
              Bill_Date__c != null AND CALENDAR_YEAR(Bill_Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ]) {			Integer m = (Integer) ar.get('month');				expense[m - 1] = (Decimal) ar.get('total');
    }

    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
        WHERE Paid__c = true AND Date__c != null AND
              CALENDAR_YEAR(Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Date__c)
    ]) {			Integer m = (Integer) ar.get('month');			additionalExpense[m - 1] = (Decimal) ar.get('total');
    }

    for (Integer i = 0; i < 12; i++) {
        expense[i] += additionalExpense[i];
    }

    // Historical Data
    Map<Integer, List<Decimal>> incomeHistory = new Map<Integer, List<Decimal>>();
    Map<Integer, List<Decimal>> expenseHistory = new Map<Integer, List<Decimal>>();

    for (Integer i = 1; i <= 12; i++) {
        incomeHistory.put(i, new List<Decimal>());
        expenseHistory.put(i, new List<Decimal>());
    }

    for (AggregateResult ar : [
        SELECT CALENDAR_YEAR(Invoice_Date__c) yr, CALENDAR_MONTH(Invoice_Date__c) mon, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true AND Company__c = :org.Id AND
              Invoice_Date__c >= :startDate AND Invoice_Date__c <= :endDate
        GROUP BY CALENDAR_YEAR(Invoice_Date__c), CALENDAR_MONTH(Invoice_Date__c)
    ]) {			incomeHistory.get((Integer) ar.get('mon')).add((Decimal) ar.get('total'));
    }
    System.debug('📊 Income History: ' + JSON.serialize(incomeHistory));

    for (AggregateResult ar : [
        SELECT CALENDAR_YEAR(Bill_Date__c) yr, CALENDAR_MONTH(Bill_Date__c) mon, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid' AND Company__c = :org.Id AND
              Bill_Date__c >= :startDate AND Bill_Date__c <= :endDate
        GROUP BY CALENDAR_YEAR(Bill_Date__c), CALENDAR_MONTH(Bill_Date__c)
    ]) {			expenseHistory.get((Integer) ar.get('mon')).add((Decimal) ar.get('total'));
    }
    System.debug('📊 Expense History: ' + JSON.serialize(expenseHistory));

    // Holt-Winters Prediction (simplified)
    List<Decimal> predictedIncome = applyHoltWinters(incomeHistory, currentMonth);
    List<Decimal> predictedExpense = applyHoltWinters(expenseHistory, currentMonth);

    List<String> monthLabels = new List<String>();
    for (Integer m = 1; m <= 12; m++) {
        monthLabels.add(getMonthLabel(m));
    }

    return new Map<String, Object>{
        'income' => income,
        'expense' => expense,
        'predictedIncome' => predictedIncome,
        'predictedExpense' => predictedExpense,
        'monthLabels' => monthLabels,
        'incomeHistory' => incomeHistory,
        'expenseHistory' => expenseHistory
    };
}

private static List<Decimal> applyHoltWinters(Map<Integer, List<Decimal>> history, Integer currentMonth) {
    Decimal alpha = 0.6;
    Decimal beta = 0.2;
    Decimal gamma = 0.1;

    List<Decimal> result = new List<Decimal>();

    Decimal level = 0;
    Decimal trend = 0;
    List<Decimal> seasonality = new List<Decimal>(new Decimal[12]);

    // Initialize level and seasonality
    for (Integer i = 0; i < 12; i++) {
        List<Decimal> monthData = history.get(i + 1);
        Decimal avg = 0;
        if (!monthData.isEmpty()) {
            for (Decimal val : monthData) avg += val;			avg /= monthData.size();
        }
        seasonality[i] = avg;
        level += avg;
    }
    level /= 12;

    trend = (seasonality[11] - seasonality[0]) / 11;
for (Integer i = 0; i < 12; i++) {
    if (i < currentMonth) {
        result.add(0); // Actuals already exist
    } else {
        Integer idx = Math.mod(i, 12); // wrap index between 0-11

        Decimal seasonal = gamma * seasonality[idx] + (1 - gamma) * seasonality[idx];
        level = alpha * (seasonality[idx] != null ? seasonality[idx] : 0) + (1 - alpha) * (level + trend);
        trend = beta * (level - (result.size() > 0 ? result[result.size() - 1] : level)) + (1 - beta) * trend;

        Decimal forecast = level + trend + seasonal;

        // ✅ Stop prediction if forecast goes negative or zero
        if (forecast <= 0) {
            // Fill remaining months with 0
            while (result.size() < 12) {
                result.add(0);
            }
            break;
        }

        result.add(forecast.setScale(2));
    }
}


    return result;
}




    @AuraEnabled
public static Map<String, Object> simulateForecastWithInputs(Map<String, Object> simulatedValues) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    Integer currentYear = Date.today().year();
    Integer currentMonth = Date.today().month();

    Date endDate = Date.today();
    Date startDate = endDate.addYears(-3); // Last 3 years

    // Initialize data structures
    List<Decimal> income = new List<Decimal>(new Decimal[12]);
    List<Decimal> expense = new List<Decimal>(new Decimal[12]);
    List<Decimal> additionalExpense = new List<Decimal>(new Decimal[12]);

    for (Integer i = 0; i < 12; i++) {
        income[i] = 0;
        expense[i] = 0;
        additionalExpense[i] = 0;
    }

    // Fetch current year actuals
    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Invoice_Date__c) month, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true AND Company__c = :org.Id AND
              Invoice_Date__c != null AND CALENDAR_YEAR(Invoice_Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Invoice_Date__c)
    ]) {		Integer m = (Integer) ar.get('month');		income[m - 1] = (Decimal) ar.get('total');
    }

 


    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid' AND Company__c = :org.Id AND
              Bill_Date__c != null AND CALENDAR_YEAR(Bill_Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ]) {		Integer m = (Integer) ar.get('month');			expense[m - 1] = (Decimal) ar.get('total');
    }



    for (AggregateResult ar : [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
        WHERE Paid__c = true AND Date__c != null AND
              CALENDAR_YEAR(Date__c) = :currentYear
        GROUP BY CALENDAR_MONTH(Date__c)
    ]) {
        Integer m = (Integer) ar.get('month');
        additionalExpense[m - 1] = (Decimal) ar.get('total');
    }

    for (Integer i = 0; i < 12; i++) {
        expense[i] += additionalExpense[i];
    }


    
   System.debug('📊 Current Year Income: ' + JSON.serialize(income));
    System.debug('📊 Current Year Expense: ' + JSON.serialize(expense));
    System.debug('📊 Current Year Additional Expense: ' + JSON.serialize(additionalExpense));

    // Historical Data
    Map<Integer, List<Decimal>> incomeHistory = new Map<Integer, List<Decimal>>();
    Map<Integer, List<Decimal>> expenseHistory = new Map<Integer, List<Decimal>>();

    for (Integer i = 1; i <= 12; i++) {
        incomeHistory.put(i, new List<Decimal>());
        expenseHistory.put(i, new List<Decimal>());
    }

    // Fetch historical data for the last 3 years
    System.debug('📊 Fetching historical data for the last 3 years...');
    System.debug('📊 Organisation ID: ' + org.Id);
    System.debug('📊 Start Date: ' + startDate);
    System.debug('📊 End Date: ' + endDate);


    for (AggregateResult ar : [
        SELECT CALENDAR_YEAR(Invoice_Date__c) yr, CALENDAR_MONTH(Invoice_Date__c) mon, SUM(Sub_Total_Amount__c) total
        FROM Invoice__c
        WHERE Paid__c = true AND Company__c = :org.Id AND
              Invoice_Date__c >= :startDate AND Invoice_Date__c <= :endDate
        GROUP BY CALENDAR_YEAR(Invoice_Date__c), CALENDAR_MONTH(Invoice_Date__c)
    ]) {		Integer month = (Integer) ar.get('mon');			if (!incomeHistory.containsKey(month)) {			incomeHistory.put(month, new List<Decimal>());
        }
        incomeHistory.get(month).add((Decimal) ar.get('total'));
    }

    for (AggregateResult ar : [
        SELECT CALENDAR_YEAR(Bill_Date__c) yr, CALENDAR_MONTH(Bill_Date__c) mon, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid' AND Company__c = :org.Id AND
              Bill_Date__c >= :startDate AND Bill_Date__c <= :endDate
        GROUP BY CALENDAR_YEAR(Bill_Date__c), CALENDAR_MONTH(Bill_Date__c)
    ]) {			Integer month = (Integer) ar.get('mon');			if (!expenseHistory.containsKey(month)) {			expenseHistory.put(month, new List<Decimal>());
        }
        expenseHistory.get(month).add((Decimal) ar.get('total'));
    }

    System.debug('📊 Income History: ' + JSON.serialize(incomeHistory));
    System.debug('📊 Expense History: ' + JSON.serialize(expenseHistory));
    System.debug('📊 Current Year Additional Expense: ' + JSON.serialize(additionalExpense));


    // Merge simulated values into historical data for the current year
    Map<String, Integer> monthToIndex = new Map<String, Integer>{
        'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6,
        'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12
    };

    for (String month : simulatedValues.keySet()) {
    // Safely convert the raw object to Map<String, Object>
    Map<String, Object> values = new Map<String, Object>();
    Object raw = simulatedValues.get(month);

    if (raw instanceof Map<Object, Object>) {
        Map<Object, Object> rawMap = (Map<Object, Object>) raw;			for (Object key : rawMap.keySet()) {			values.put(String.valueOf(key), rawMap.get(key));
        }
    }

    Integer monthIndex = monthToIndex.get(month);

    if (monthIndex != null) {
        if (values.containsKey('income') && values.get('income') != null) {
            Decimal simIncome = (Decimal) values.get('income');			income[monthIndex - 1] = simIncome;

            if (!incomeHistory.containsKey(monthIndex)) {			incomeHistory.put(monthIndex, new List<Decimal>());
            }
            incomeHistory.get(monthIndex).add(simIncome);
        }

        if (values.containsKey('expense') && values.get('expense') != null) {
            Decimal simExpense = (Decimal) values.get('expense');			expense[monthIndex - 1] = simExpense;

            if (!expenseHistory.containsKey(monthIndex)) {			expenseHistory.put(monthIndex, new List<Decimal>());
            }
            expenseHistory.get(monthIndex).add(simExpense);
        }
    }
}
   System.debug('📊 Updated Income History with Simulated Values: ' + JSON.serialize(incomeHistory));
System.debug('📊 Updated Expense History with Simulated Values: ' + JSON.serialize(expenseHistory));
System.debug('📊 Current Month: ' + currentMonth);

// ✅ Clean incomeHistory
Map<Integer, List<Decimal>> cleanedIncomeHistory = new Map<Integer, List<Decimal>>();
for (Integer month : incomeHistory.keySet()) {
    List<Decimal> values = incomeHistory.get(month);
    if (values != null && !values.isEmpty()) {
        cleanedIncomeHistory.put(month, values);
    }
}

// ✅ Clean expenseHistory
Map<Integer, List<Decimal>> cleanedExpenseHistory = new Map<Integer, List<Decimal>>();
for (Integer month : expenseHistory.keySet()) {
    List<Decimal> values = expenseHistory.get(month);
    if (values != null && !values.isEmpty()) {
        cleanedExpenseHistory.put(month, values);
    }
}

    System.debug('📊 Cleaned Income History: ' + JSON.serialize(cleanedIncomeHistory));
    System.debug('📊 Cleaned Expense History: ' + JSON.serialize(cleanedExpenseHistory));

// 🔮 Run Holt-Winters prediction with cleaned data
List<Decimal> predictedIncome = applyHoltWintersnew(cleanedIncomeHistory, currentMonth);
List<Decimal> predictedExpense = applyHoltWintersnew(cleanedExpenseHistory, currentMonth);

    // Prepare simulated data arrays
    List<Decimal> simulatedIncome = new List<Decimal>(new Decimal[12]);
    List<Decimal> simulatedExpense = new List<Decimal>(new Decimal[12]);
    for (Integer i = 0; i < 12; i++) {
        simulatedIncome[i] = 0;
        simulatedExpense[i] = 0;
    }

for (String month : simulatedValues.keySet()) {
    Map<String, Object> values = new Map<String, Object>();
    Object raw = simulatedValues.get(month);
    if (raw instanceof Map<Object, Object>) {
        Map<Object, Object> rawMap = (Map<Object, Object>) raw;			for (Object key : rawMap.keySet()) {				values.put(String.valueOf(key), rawMap.get(key));
        }
    }

    Integer monthIndex = monthToIndex.get(month);
    if (monthIndex != null) {
        if (values.containsKey('income') && values.get('income') != null) {
            simulatedIncome[monthIndex - 1] = (Decimal) values.get('income');
        }
        if (values.containsKey('expense') && values.get('expense') != null) {
            simulatedExpense[monthIndex - 1] = (Decimal) values.get('expense');
        }
    }
}

    List<String> monthLabels = new List<String>();
    for (Integer m = 1; m <= 12; m++) {
        monthLabels.add(getMonthLabel(m));
    }


    System.debug('📊 Simulated Income: ' + JSON.serialize(simulatedIncome));
    System.debug('📊 Simulated Expense: ' + JSON.serialize(simulatedExpense));
    System.debug('📊 Predicted Income: ' + JSON.serialize(predictedIncome));
    System.debug('📊 Predicted Expense: ' + JSON.serialize(predictedExpense));
    System.debug('📊 Month Labels: ' + JSON.serialize(monthLabels));


    return new Map<String, Object>{
        'actualIncome' => income,
        'actualExpense' => expense,
        'predictedIncome' => predictedIncome,
        'predictedExpense' => predictedExpense,
        'simulatedIncome' => simulatedIncome,
        'simulatedExpense' => simulatedExpense,
        'monthLabels' => monthLabels
    };
}
private static List<Decimal> applyHoltWintersnew(Map<Integer, List<Decimal>> history, Integer currentMonth) {
    Decimal alpha = 0.6; // Level smoothing
    Decimal beta = 0.2;  // Trend smoothing
    Decimal gamma = 0.1; // Seasonality smoothing

    List<Decimal> result = new List<Decimal>();
    Decimal level = 0;
    Decimal trend = 0;
    
    // Initialize seasonality with zeros to avoid null issues
    List<Decimal> seasonality = new List<Decimal>();
    for (Integer i = 0; i < 12; i++) {
        seasonality.add(0);
    }

    System.debug('📊 Applying Holt-Winters with current month: ' + currentMonth);  
    System.debug('📊 History: ' + JSON.serialize(history));

    // Step 1: Calculate average for each month (1 to 12)
    Integer nonZeroMonths = 0;
    Decimal totalLevel = 0;
    for (Integer i = 0; i < 12; i++) {
        List<Decimal> monthData = history.get(i + 1);
        if (monthData != null && !monthData.isEmpty()) {
            Decimal avg = 0;			Integer count = 0;			for (Decimal val : monthData) {			if (val != null) {			avg += val;				count++;
                }
            }
            if (count > 0) {			avg /= count;			if (avg > 0) {			seasonality[i] = avg;			totalLevel += avg;				nonZeroMonths++;
                }
            }
        }
    }

    // Step 2: Set initial level
    level = nonZeroMonths > 0 ? totalLevel / nonZeroMonths : 100;

    // Step 3: Fill in any zero or null seasonality entries
    for (Integer i = 0; i < 12; i++) {
        if (seasonality[i] == null || seasonality[i] == 0) {
            seasonality[i] = level / (nonZeroMonths > 0 ? nonZeroMonths : 1);
        }
    }

    // Step 4: Set initial trend
    trend = nonZeroMonths > 1 ? (seasonality[11] - seasonality[0]) / 11 : 0.01;

    System.debug('📊 Initial Level: ' + level);
    System.debug('📊 Initial Trend: ' + trend);
    System.debug('📊 Initial Seasonality: ' + JSON.serialize(seasonality));

    // Step 5: Generate forecasts
    for (Integer i = 0; i < 12; i++) {
        if (i < currentMonth - 1) {
            result.add(0); // Already actuals
        } else {
            Integer idx = Math.mod(i, 12);
            Decimal lastValue = result.isEmpty() ? level : result[result.size() - 1];
            Decimal seasonal = seasonality[idx] != null ? seasonality[idx] : 0;

            level = alpha * seasonal + (1 - alpha) * (lastValue + trend);
            trend = beta * (level - lastValue) + (1 - beta) * trend;

            // Safely update seasonality
            Decimal newSeasonal = gamma * (lastValue + trend - level) + (1 - gamma) * seasonal;
            seasonality[idx] = newSeasonal != null ? newSeasonal : 0;

            Decimal forecast = level + trend + seasonality[idx];
            result.add(forecast > 0 ? forecast.setScale(2) : 0.01); // Minimum 0.01
        }
    }

    System.debug('📊 Holt-Winters Forecast: ' + JSON.serialize(result));
    System.debug('📊 Updated Seasonality: ' + JSON.serialize(seasonality));

    return result;
}



private static String getMonthLabel(Integer month) {
    List<String> months = new List<String>{
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    };
    return months[month - 1];
}


@AuraEnabled(cacheable=true)
public static Map<String, List<Decimal>> getMonthlyExpensesOnly(Integer year) {
    Account org = UtilClass.getOrganisationByLogin_Employee();
    if (year == null) {
        year = Date.today().year(); 
    }

    // Fetch bill-based expenses
    List<AggregateResult> billResults = [
        SELECT CALENDAR_MONTH(Bill_Date__c) month, SUM(Total_Amount__c) total
        FROM Bill__c
        WHERE Status__c = 'Paid'
            AND Company__c = :org.Id
            AND Bill_Date__c != null
            AND CALENDAR_YEAR(Bill_Date__c) = :year
        GROUP BY CALENDAR_MONTH(Bill_Date__c)
    ];

    // Fetch direct expenses
    List<AggregateResult> expenseResults = [
        SELECT CALENDAR_MONTH(Date__c) month, SUM(Amount__c) total
        FROM Expense__c
        WHERE Paid__c = true
            AND Date__c != null
            AND CALENDAR_YEAR(Date__c) = :year
        GROUP BY CALENDAR_MONTH(Date__c)
    ];

    // Prepare 12 months of data
    List<Decimal> totalExpense = new List<Decimal>();
    for (Integer i = 0; i < 12; i++) {
        totalExpense.add(0);
    }

    for (AggregateResult ar : billResults) {
        Integer month = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');				totalExpense[month - 1] += total;
    }

    for (AggregateResult ar : expenseResults) {
        Integer month = (Integer) ar.get('month');			Decimal total = (Decimal) ar.get('total');			totalExpense[month - 1] += total;
    }

    return new Map<String, List<Decimal>>{
        'expense' => totalExpense
    };
}



 public class ProjectBudgetWrapperSimulated {
        @AuraEnabled public Id projectId;
        @AuraEnabled public Decimal approved;
        @AuraEnabled public Decimal consumed;
        @AuraEnabled public Decimal remaining;
        @AuraEnabled public Decimal committed;

        public ProjectBudgetWrapperSimulated(Id pid, Decimal a, Decimal c, Decimal r, Decimal com) {
            this.projectId = pid;
            this.approved = a;
            this.consumed = c;
            this.remaining = r;
            this.committed = com;
        }
    }

    @AuraEnabled(cacheable=true)
    public static ProjectBudgetWrapperSimulated getSingleProjectBudgetSimulated(Id projectId) { 
        Decimal total = 0, consumed = 0, remaining = 0, committed = 0;

        for (Budget_Account__c acc : [
            SELECT Budget_Plan__r.Total_Budget_Amount__c,
                   Budget_Plan__r.Consumed_Amount__c,
                   Budget_Plan__r.Remaining_Amount__c,
                   Budget_Plan__r.Committed__c
            FROM Budget_Account__c
            WHERE Chart_of_Account__c != null 
            AND Project__c = :projectId
            AND Budget_Plan__c != null
        ]) {		total     += acc.Budget_Plan__r.Total_Budget_Amount__c != null ? acc.Budget_Plan__r.Total_Budget_Amount__c : 0;			consumed  += acc.Budget_Plan__r.Consumed_Amount__c     != null ? acc.Budget_Plan__r.Consumed_Amount__c     : 0;				remaining += acc.Budget_Plan__r.Remaining_Amount__c    != null ? acc.Budget_Plan__r.Remaining_Amount__c    : 0;				committed += acc.Budget_Plan__r.Committed__c           != null ? acc.Budget_Plan__r.Committed__c           : 0;
        }

        return new ProjectBudgetWrapperSimulated(projectId, total, consumed, remaining, committed);
    }

@AuraEnabled(cacheable=true)
public static String getProjectIDs() {
    List<Id> projectIds = new List<Id>();
    for (Budget_Account__c acc : [
        SELECT Id, Project__c,
               Chart_of_Account__c,
               Budget_Plan__c
        FROM Budget_Account__c
        WHERE Chart_of_Account__c != null 
        AND Project__c != null
        AND Budget_Plan__c != null
    ]) {			projectIds.add(acc.Project__c);
    }
    return JSON.serialize(projectIds);
}




 @AuraEnabled
    public static String refineResponse( String inputText) {
        System.debug('🔁 refineResponse called. InputText: ' + inputText);

        return processRefineResponse(inputText);
    }

    private static String processRefineResponse(String inputText) {
        String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyB9wA3lQNhEu0fb4rlnSz6-OJETAtBLrBs';
        String prompt = inputText.replaceAll('"', '\\"');
        String requestPayload = '{"contents": [{"parts": [{"text": "' + prompt + '"}]}]}';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestPayload);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {		Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());			List<Object> candidates = (List<Object>) jsonResponse.get('candidates');

                if (!candidates.isEmpty()) {			Map<String, Object> candidate = (Map<String, Object>) candidates[0];			Map<String, Object> content = (Map<String, Object>) candidate.get('content');				List<Object> parts = (List<Object>) content.get('parts');

                    if (!parts.isEmpty()) {					Map<String, Object> part = (Map<String, Object>) parts[0];				return (String) part.get('text');
                    }
                }
                throw new AuraHandledException('No valid text returned from Gemini API.');
            } else {
                throw new AuraHandledException('API request failed. Code: ' + res.getStatusCode() + ' — ' + res.getBody());
            }
        } catch (Exception e) {
            throw new AuraHandledException('AI Refinement Error: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
public static Integer getOrgFiscalStartMonth() {
    try {
        FiscalYearSettings fys = [
            SELECT StartDate, IsStandardYear 
            FROM FiscalYearSettings 
            LIMIT 1
        ];

        System.debug('📊 Today: ' + Date.today());
        System.debug('📊 Fiscal Year Settings: ' + JSON.serialize(fys));

        if (fys.IsStandardYear) {
            // Standard Fiscal Year → Organization setting
            Integer orgStartMonth = [
                SELECT FiscalYearStartMonth 
                FROM Organization 
                LIMIT 1
            ].FiscalYearStartMonth;

            System.debug('✅ Standard Fiscal Year detected. Start Month: ' + orgStartMonth);
            return orgStartMonth;
        } else {
            // Custom Fiscal Year → use StartDate.month()
            Integer customStartMonth = fys.StartDate.month();
            System.debug('✅ Custom Fiscal Year detected. Start Month: ' + customStartMonth);
            return customStartMonth;
        }

    } catch (Exception e) {
        System.debug('⚠️ Error in getOrgFiscalStartMonth: ' + e.getMessage());
        // Fallback → January as 1
        return 1;
    }
}

}