public with sharing class supplyPlanningController {
   // supply demand based on months
   

@AuraEnabled(cacheable=true)
public static List<MonthlySupplyDemandWrapper> getMonthlySupplyDemand(
    String productId,
    Id organisationId,
    Date fromDate,
    Date toDate
) {
    System.debug('📦 Fetching monthly supply & demand for productId: ' + productId);
    System.debug('📅 From: ' + fromDate + ' To: ' + toDate);

    List<MonthlySupplyDemandWrapper> results = new List<MonthlySupplyDemandWrapper>();

    for (AggregateResult ar : [
        
    
    SELECT
            FISCAL_MONTH(OrderItem.CreatedDate) monthNum,
            SUM(Quantity) totalDemand,
            SUM(Shipped_Quantity__c) totalSupply
        FROM OrderItem
        WHERE Product2Id = :productId 
            AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
            AND Order.Company__c = :organisationId
            AND OrderItem.CreatedDate <= :toDate
            AND OrderItem.CreatedDate >= :fromDate
        GROUP BY FISCAL_MONTH(OrderItem.CreatedDate)
        ORDER BY FISCAL_MONTH(OrderItem.CreatedDate)
    ]) {
        Integer month = (Integer) ar.get('monthNum');  Decimal demand = (Decimal) ar.get('totalDemand');  Decimal supply = (Decimal) ar.get('totalSupply');

        System.debug('📊 Fiscal Month: ' + month + ', Demand: ' + demand + ', Supply: ' + supply);

        results.add(new MonthlySupplyDemandWrapper(month, demand, supply));
    }

    System.debug('✅ Total records returned: ' + results.size());
    return results;
}

    
    public class MonthlySupplyDemandWrapper {
        @AuraEnabled public Integer month;
        @AuraEnabled public Decimal totalDemand;
        @AuraEnabled public Decimal totalSupply;
    
        public MonthlySupplyDemandWrapper(Integer month, Decimal demand, Decimal supply) {
            this.month = month; this.totalDemand = demand; this.totalSupply = supply;
        }
    }


    
private static List<Decimal> initSeasonals(List<Decimal> values, Integer seasonLength) {
    List<Decimal> seasonals = new List<Decimal>();
    for (Integer i = 0; i < seasonLength; i++) {
        Decimal sum = 0;
        Integer count = 0;
        for (Integer j = i; j < values.size(); j += seasonLength) {
            sum += values[j];
            count++;
        }
        Decimal avg = (count > 0) ? sum / count : 0;
        seasonals.add(avg);
    }
    return seasonals;
}

private static String getMonthLabel(Integer monthNum) {
    if (monthNum == null || monthNum < 1 || monthNum > 12) return 'Unknown';
    List<String> monthLabels = new List<String>{
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    };
    return monthLabels[monthNum - 1];
}



// Forecast result structure
public class ForecastResult {
    @AuraEnabled public List<String> forecastMonths;
    @AuraEnabled public List<Decimal> forecastValues;
}

    @AuraEnabled
public static Map<String, Object> getHistoricalSupplyDemandData(Id productId) {
    Date endDate = Date.today();
    Date startDate = endDate.addYears(-3); // Last 3 years

    List<AggregateResult> results = [
        SELECT CALENDAR_YEAR(Order.EffectiveDate) yr,
               CALENDAR_MONTH(Order.EffectiveDate) mon,
               SUM(Quantity) qty,
               SUM(Shipped_Quantity__c) shipped
        FROM OrderItem
        WHERE Product2Id = :productId
        AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND Order.EffectiveDate >= :startDate AND Order.EffectiveDate <= :endDate
        GROUP BY CALENDAR_YEAR(Order.EffectiveDate), CALENDAR_MONTH(Order.EffectiveDate)
        ORDER BY CALENDAR_YEAR(Order.EffectiveDate), CALENDAR_MONTH(Order.EffectiveDate)
    ];

    Map<String, Decimal> demandMap = new Map<String, Decimal>();
    Map<String, Decimal> supplyMap = new Map<String, Decimal>();

    for (AggregateResult ar : results) {
        Integer y = (Integer)ar.get('yr');
        Integer m = (Integer)ar.get('mon');
        String label = getMonthLabel(m) + ' ' + y;   Decimal qty = (Decimal)ar.get('qty');   Decimal shipped = (Decimal)ar.get('shipped');
  demandMap.put(label, qty.setScale(2));  supplyMap.put(label, shipped.setScale(2));
    }

    List<String> monthLabels = new List<String>();
    List<Decimal> demandValues = new List<Decimal>();
    List<Decimal> supplyValues = new List<Decimal>();

    Date d = startDate.toStartOfMonth();
    while (d <= endDate) {
        String label = getMonthLabel(d.month()) + ' ' + d.year();
        monthLabels.add(label);
        demandValues.add(demandMap.containsKey(label) ? demandMap.get(label) : 0);
        supplyValues.add(supplyMap.containsKey(label) ? supplyMap.get(label) : 0);
        d = d.addMonths(1);
    }

    Map<String, Object> result = new Map<String, Object>();
    result.put('historicalMonths', monthLabels);
    result.put('historicalDemandValues', demandValues);
    result.put('historicalSupplyValues', supplyValues);
    return result;
}


private static ForecastResult runHoltWintersForecast(List<Decimal> values, Integer m, Integer seasonLength) {
    Decimal alpha = 0.5;
    Decimal beta = 0.3;
    Decimal gamma = 0.2;

    Integer len = values.size();
    if (len < seasonLength * 2) {
        throw new AuraHandledException('Not enough data for Holt-Winters.');
    }

    List<Decimal> level = new List<Decimal>{ values[0] };
    List<Decimal> trend = new List<Decimal>{ values[1] - values[0] };
    List<Decimal> seasonals = initSeasonals(values, seasonLength);

    for (Integer i = 1; i < len; i++) {
        Decimal lastLevel = level[i - 1];
        Decimal lastTrend = trend[i - 1];
        Integer sIndex = Math.mod(i, seasonLength);
        Decimal seasonal = seasonals[sIndex];
        Decimal current = values[i];

        Decimal newLevel = alpha * (current - seasonal) + (1 - alpha) * (lastLevel + lastTrend);
        Decimal newTrend = beta * (newLevel - lastLevel) + (1 - beta) * lastTrend;
        Decimal newSeasonal = gamma * (current - newLevel) + (1 - gamma) * seasonal;

        level.add(newLevel);
        trend.add(newTrend);
        seasonals[sIndex] = newSeasonal;
    }

    ForecastResult result = new ForecastResult();
    result.forecastMonths = new List<String>();
    result.forecastValues = new List<Decimal>();

    Date today = Date.today();
    for (Integer i = 1; i <= m; i++) {
        Decimal l = level[len - 1];
        Decimal t = trend[len - 1];
        Integer sIndex = Math.mod(len + i - 1, seasonLength);
        Decimal s = seasonals[sIndex];
        Decimal f = l + (i * t) + s;
        result.forecastValues.add(Math.max(f, 0).setScale(2));

        Date monthDate = today.addMonths(i);
        result.forecastMonths.add(getMonthLabel(monthDate.month()) + ' ' + monthDate.year());
    }

    return result;
}


@AuraEnabled(cacheable=true)
public static Map<String, Object> getSupplyDemandForecastWithHistory(Id productId, String modelName) {
    System.debug('🔮 Running forecast for productId: ' + productId + ' using model: ' + modelName);
    Map<String, Object> history = getHistoricalSupplyDemandData(productId);

    List<Decimal> demandValues = (List<Decimal>) history.get('historicalDemandValues');
    List<Decimal> supplyValues = (List<Decimal>) history.get('historicalSupplyValues');

    ForecastResult demandForecast;
    ForecastResult supplyForecast;

    if (modelName == 'MOVING_AVERAGE') {
       // demandForecast = runMovingAverageForecast(demandValues, 6);
        //supplyForecast = runMovingAverageForecast(supplyValues, 6);
    } else {
        demandForecast = runHoltWintersForecast(demandValues, 12, 12);
        supplyForecast = runHoltWintersForecast(supplyValues, 12, 12);
    }
    System.debug('🔮 demandForecast ' + demandForecast);
    System.debug('🔮 supplyForecast ' +supplyForecast);
    System.debug(' ⚙️ demandValues ' +demandValues);
    System.debug('⚙️ supplyValues ' +supplyValues);


    history.put('forecastMonths', demandForecast.forecastMonths); // Same for both
    history.put('forecastDemandValues', demandForecast.forecastValues);
    history.put('forecastSupplyValues', supplyForecast.forecastValues);

    return history;
}



    

    
    //for top 5 supply and demand
    
    @AuraEnabled(cacheable=true)
public static List<ProductSupplyDemandSummary> getTop5SupplyAndDemand(
    Id organisationId,
    Date fromDate,
    Date toDate
) {
    List<ProductSupplyDemandSummary> results = new List<ProductSupplyDemandSummary>();

    // -------- TOP 5 by DEMAND --------
    for (AggregateResult ar : [
        SELECT Product2Id                      pId,
               Product2.Name                   pName,
               SUM(Quantity)                  qDemand,
               SUM(Shipped_Quantity__c) qSupply
        FROM   OrderItem
        WHERE  Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND    CreatedDate >= :fromDate
        AND    CreatedDate <= :toDate
        AND    Order.Company__c = :organisationId
        GROUP  BY Product2Id, Product2.Name
        ORDER  BY SUM(Quantity) DESC
        LIMIT  5
    ]) {
        results.add(new ProductSupplyDemandSummary(
            (Id)      ar.get('pId'),    (String)  ar.get('pName'),    (Decimal) ar.get('qDemand'),    (Decimal) ar.get('qSupply'),    'Demand'
        ));
    }

    // -------- TOP 5 by SUPPLY --------
    for (AggregateResult ar : [
        SELECT Product2Id                      pId,
               Product2.Name                   pName,
               SUM(Quantity)                  qDemand,
               SUM(Shipped_Quantity__c) qSupply
        FROM   OrderItem
        WHERE  Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
        AND    CreatedDate >= :fromDate
        AND    CreatedDate <= :toDate
        AND    Order.Company__c = :organisationId
        GROUP  BY Product2Id, Product2.Name
        ORDER  BY SUM(Shipped_Quantity__c) DESC
        LIMIT  5
    ]) {
        results.add(new ProductSupplyDemandSummary(
            (Id)      ar.get('pId'),   (String)  ar.get('pName'),   (Decimal) ar.get('qDemand'),   (Decimal) ar.get('qSupply'),   'Supply'
        ));
    }

    return results;
}

    
    public class ProductSupplyDemandSummary {
        @AuraEnabled public Id      productId;
        @AuraEnabled public String  productName;
        @AuraEnabled public Decimal totalDemand;
        @AuraEnabled public Decimal totalSupply;
        @AuraEnabled public String  rankingType;   
    
        public ProductSupplyDemandSummary(
                Id productId, String productName,
                Decimal demand, Decimal supply,
                String rankingType) {
            this.productId   = productId;
            this.productName = productName;
            this.totalDemand = demand;
            this.totalSupply = supply;
            this.rankingType = rankingType;
        }
    }
    
    //Country supply demand for the top 5 countries
@AuraEnabled(cacheable=true)
public static List<Top5CountrySupplyDemandWrapper> getTop5CountrySupplyDemand(
    Id organisationId,
    Date fromDate,
    Date toDate
) {
    List<Top5CountrySupplyDemandWrapper> results = new List<Top5CountrySupplyDemandWrapper>();

    // 🔄 Fetch OrderItems within date range
    List<OrderItem> orderItems = [
        SELECT Quantity, Shipped_Quantity__c,
               Order.AccountId, Order.Contact__c
        FROM OrderItem
        WHERE Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
          AND Order.Company__c = :organisationId
          AND CreatedDate >= :fromDate
          AND CreatedDate <= :toDate
    ];

    Set<Id> accountIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();

    for (OrderItem oi : orderItems) {
        if (oi.Order.AccountId != null) accountIds.add(oi.Order.AccountId);
        if (oi.Order.Contact__c != null) contactIds.add(oi.Order.Contact__c);
    }

    // 📦 Get shipping address country mapping
    Map<String, String> accountContactToCountry = new Map<String, String>();
    for (Address__c addr : [
        SELECT Customer__c, Contact__c, Country__c, Is_Shipping_Address__c
        FROM Address__c
        WHERE Customer__c IN :accountIds
          AND Contact__c != NULL
          AND Country__c != NULL
          AND Is_Shipping_Address__c = true
    ]) {
        String key = String.valueOf(addr.Customer__c) + ':' + String.valueOf(addr.Contact__c);
        accountContactToCountry.put(key, addr.Country__c);
    }

    // 📊 Aggregate demand & supply per country
    Map<String, Decimal> demandMap = new Map<String, Decimal>();
    Map<String, Decimal> supplyMap = new Map<String, Decimal>();

    for (OrderItem oi : orderItems) {
        if (oi.Order.Contact__c == null) continue;

        String key = String.valueOf(oi.Order.AccountId) + ':' + String.valueOf(oi.Order.Contact__c);
        if (!accountContactToCountry.containsKey(key)) continue;

        String country = accountContactToCountry.get(key);
        Decimal currentDemand = demandMap.containsKey(country) ? demandMap.get(country) : 0;   Decimal currentSupply = supplyMap.containsKey(country) ? supplyMap.get(country) : 0;

        demandMap.put(country, currentDemand + oi.Quantity);
        supplyMap.put(country, currentSupply + (oi.Shipped_Quantity__c != null ? oi.Shipped_Quantity__c : 0));
    }

    for (String country : demandMap.keySet()) {
        results.add(new Top5CountrySupplyDemandWrapper(
            country,
            demandMap.get(country),
            supplyMap.get(country)
        ));
    }

    results.sort(new Top5CountryDemandComparator());
    
        List<Top5CountrySupplyDemandWrapper> topResults;

        if (results.size() > 5) {
            topResults = new List<Top5CountrySupplyDemandWrapper>();
            for (Integer i = 0; i < 5; i++) {
                topResults.add(results[i]);
            }
        } else {
            topResults = results;
        }
        
        return topResults;
    }
    
    public class Top5CountrySupplyDemandWrapper {
        @AuraEnabled public String country;
        @AuraEnabled public Decimal totalDemand;
        @AuraEnabled public Decimal totalSupply;
    
        public Top5CountrySupplyDemandWrapper(String country, Decimal demand, Decimal supply) {
            this.country = country;
            this.totalDemand = demand;
            this.totalSupply = supply;
        }
    }
    
    public class Top5CountryDemandComparator implements Comparator<Top5CountrySupplyDemandWrapper> {
        public Integer compare(Top5CountrySupplyDemandWrapper a, Top5CountrySupplyDemandWrapper b) {
            if (a.totalDemand > b.totalDemand) return -1;
            if (a.totalDemand < b.totalDemand) return 1;
            return 0;
        }
    }

    //Country Supply demand
    @AuraEnabled(cacheable=false)
public static List<CountrySupplyDemandWrapper> getSupplyDemandByCountry(
    Id productId,
    Id organisationId,
    Date fromDate,
    Date toDate
) {
    List<CountrySupplyDemandWrapper> results = new List<CountrySupplyDemandWrapper>();

    // Step 1: Get relevant OrderItems
    List<OrderItem> orderItems = [
        SELECT Quantity, Shipped_Quantity__c,
               Order.AccountId, Order.Contact__c
        FROM OrderItem
        WHERE Product2Id = :productId
          AND Order.Status NOT IN ('Cancelled', 'Draft', 'Entered')
          AND Order.Company__c = :organisationId
          AND CreatedDate >= :fromDate
          AND CreatedDate <= :toDate
    ];

    Set<Id> accountIds = new Set<Id>();
    Set<Id> contactIds = new Set<Id>();

    for (OrderItem oi : orderItems) {
        if (oi.Order.AccountId != null) accountIds.add(oi.Order.AccountId);
        if (oi.Order.Contact__c != null) contactIds.add(oi.Order.Contact__c);
    }

    // Step 3: Fetch matching shipping addresses with country info
    Map<String, String> accountContactKeyToCountry = new Map<String, String>();

    for (Address__c addr : [
        SELECT Customer__c, Contact__c, Country__c, Is_Shipping_Address__c
        FROM Address__c
        WHERE Customer__c IN :accountIds
          AND Contact__c != NULL
          AND Country__c != NULL
          AND Is_Shipping_Address__c = true
    ]) {
        String key = String.valueOf(addr.Customer__c) + ':' + String.valueOf(addr.Contact__c);
        accountContactKeyToCountry.put(key, addr.Country__c);
    }

    Map<String, Decimal> demandMap = new Map<String, Decimal>();
    Map<String, Decimal> supplyMap = new Map<String, Decimal>();

    for (OrderItem oi : orderItems) {
        if (oi.Order.Contact__c == null) continue;

        String key = String.valueOf(oi.Order.AccountId) + ':' + String.valueOf(oi.Order.Contact__c);
        if (!accountContactKeyToCountry.containsKey(key)) continue;

        String country = accountContactKeyToCountry.get(key);
        Decimal currentDemand = demandMap.containsKey(country) ? demandMap.get(country) : 0;
        Decimal currentSupply = supplyMap.containsKey(country) ? supplyMap.get(country) : 0;

        demandMap.put(country, currentDemand + oi.Quantity);
        supplyMap.put(country, currentSupply + (oi.Shipped_Quantity__c != null ? oi.Shipped_Quantity__c : 0));
    }

    for (String country : demandMap.keySet()) {
        results.add(new CountrySupplyDemandWrapper(
            country,
            demandMap.get(country),
            supplyMap.get(country)
        ));
    }

    return results;
}

    public class CountrySupplyDemandWrapper {
        @AuraEnabled public String country;
        @AuraEnabled public Decimal totalDemand;
        @AuraEnabled public Decimal totalSupply;
    
        public CountrySupplyDemandWrapper(String country, Decimal demand, Decimal supply) {
            this.country = country;
            this.totalDemand = demand;
            this.totalSupply = supply;
        }
    }


    // SupplierScorecardController 
                @AuraEnabled(cacheable=true)
public static Map<String, String> getDefaultTopVendor(Id organisationId, Integer year) {
    Map<String, String> result = new Map<String, String>();
    if (organisationId == null || year == null) return result;

    // Step 1: Find vendors with Paid Payments
    Set<Id> vendorsWithSpend = new Set<Id>();
    for (AggregateResult ar : [
        SELECT Accounts__c accId
        FROM Payment__c
        WHERE Status__c = 'Paid'
          AND Account__c = :organisationId
          AND Accounts__c != null
          AND FISCAL_YEAR(CreatedDate) = :year
        GROUP BY Accounts__c
    ]) {
        vendorsWithSpend.add((Id) ar.get('accId'));
    }

    // Step 2: Find vendors with POs in fiscal year
    Set<Id> vendorsWithPO = new Set<Id>();
    for (AggregateResult ar : [
        SELECT Vendor__c vendorId
        FROM PO__c
        WHERE Order_Date__c != null
          AND FISCAL_YEAR(Order_Date__c) = :year
        GROUP BY Vendor__c
    ]) {
        vendorsWithPO.add((Id) ar.get('vendorId'));
    }

    // Step 3: Find vendors with Stock Inward Line Items (quality)
    Set<Id> vendorsWithQuality = new Set<Id>();
    for (AggregateResult ar : [
        SELECT Purchase_Orders__r.Vendor__c vendorId
        FROM Stock_Inward_Line_Item__c
        WHERE Purchase_Orders__r.Vendor__c != null
          AND FISCAL_YEAR(CreatedDate) = :year
        GROUP BY Purchase_Orders__r.Vendor__c
    ]) {
        vendorsWithQuality.add((Id) ar.get('vendorId'));
    }

    // Step 4: Intersection of all 3
    Set<Id> eligibleVendors = new Set<Id>();
    for (Id vId : vendorsWithSpend) {
        if (vendorsWithPO.contains(vId) && vendorsWithQuality.contains(vId)) {
            eligibleVendors.add(vId);
        }
    }

    // Step 5: Pick the top vendor by spend
    if (!eligibleVendors.isEmpty()) {
        List<AggregateResult> topVendor = [
            SELECT Accounts__c accId, MAX(Accounts__r.Name) accName, SUM(Amount__c) total
            FROM Payment__c
            WHERE Status__c = 'Paid'
              AND Account__c = :organisationId
              AND Accounts__c IN :eligibleVendors
              AND FISCAL_YEAR(CreatedDate) = :year
            GROUP BY Accounts__c
            ORDER BY  SUM(Amount__c) DESC
            LIMIT 1
        ];

        if (!topVendor.isEmpty()) {
            result.put('Id', (String) topVendor[0].get('accId'));
            result.put('Name', (String) topVendor[0].get('accName'));
        }
    }

    return result;
}

    
    //spend over time real data

    @AuraEnabled(cacheable=true)
public static String getCurrencySymbol() {
    Boolean multiCurrencyEnabled = Schema.getGlobalDescribe().containsKey('CurrencyType');
    String currencyISO;
    Decimal currencyRate;
    String userIsoCode;

    if (UserInfo.getDefaultCurrency() != null) {
        currencyISO = UserInfo.getDefaultCurrency();
    } else {
        currencyISO = 'USD'; // Fallback
    }

    if (multiCurrencyEnabled) {
        String q = 'SELECT IsoCode, conversionRate FROM CurrencyType WHERE IsoCode = :currencyISO';
        currencyRate = (Decimal) Database.query(q)[0].get('conversionRate');
    } else {
        currencyRate = 1;
    }

    Map<String, String> symbolMap = new Map<String, String>{
        'USD' => '$',
        'GBP' => '£',
        'EUR' => '€',
        'JPY' => '¥',
        'INR' => '₹',
        'CNY' => '¥',
        'AUD' => 'A$',
        'CAD' => 'C$'
    };

    return symbolMap.containsKey(currencyISO) ? symbolMap.get(currencyISO) : currencyISO;
}



// //forcaste + 

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getSpendOverTimeWithForecast(Id vendorId, Id organisationId, Integer year) {
    List<Map<String, Object>> result = new List<Map<String, Object>>();

    if (vendorId == null || organisationId == null || year == null) {
        return result;
    }

    try {
        Integer currentMonth = Date.today().month();
        Integer pastYear1 = year - 1;
        Integer pastYear2 = year - 2;
        Integer pastYear3 = year - 3;

        // 1. Fetch current year's actuals
        List<AggregateResult> thisYearTotals = [
            SELECT CALENDAR_MONTH(CreatedDate) month,
                   SUM(Amount__c) total
            FROM Payment__c
            WHERE Accounts__c = :vendorId
            AND Status__c = 'Paid'
            AND Purchase_Orders__c != null
            AND Bill__c != null
            AND Account__c = :organisationId
            AND CALENDAR_YEAR(CreatedDate) = :year
            GROUP BY CALENDAR_MONTH(CreatedDate)
        ];

        // 2. Fetch historical totals (past 3 years)
        List<AggregateResult> past3YearsTotals = [
            SELECT CALENDAR_MONTH(CreatedDate) month,
                   CALENDAR_YEAR(CreatedDate) yr,
                   SUM(Amount__c) total
            FROM Payment__c
            WHERE Accounts__c = :vendorId
            AND Status__c = 'Paid'
            AND Purchase_Orders__c != null
            AND Bill__c != null
            AND Account__c = :organisationId
            AND CALENDAR_YEAR(CreatedDate) IN :new List<Integer>{pastYear1, pastYear2, pastYear3}
            GROUP BY CALENDAR_MONTH(CreatedDate), CALENDAR_YEAR(CreatedDate)
        ];

        Map<Integer, Decimal> currentYearData = new Map<Integer, Decimal>();
        for (AggregateResult ar : thisYearTotals) {
            Integer month = (Integer) ar.get('month');
            Decimal total = (Decimal) ar.get('total');
            currentYearData.put(month, total);
        }

        // 3. Prepare historical averages
        Map<Integer, List<Decimal>> monthToPastAmounts = new Map<Integer, List<Decimal>>();
        for (AggregateResult ar : past3YearsTotals) {
            Integer month = (Integer) ar.get('month');
            Decimal total = (Decimal) ar.get('total');

            if (!monthToPastAmounts.containsKey(month)) {
                monthToPastAmounts.put(month, new List<Decimal>());
            }
            monthToPastAmounts.get(month).add(total);
        }

        Map<Integer, Decimal> forecastMap = new Map<Integer, Decimal>();
        for (Integer m = 1; m <= 12; m++) {
            List<Decimal> values = monthToPastAmounts.containsKey(m) ? monthToPastAmounts.get(m) : new List<Decimal>();
            Decimal sum = 0;
            for (Decimal d : values) {
                sum += d;
            }
            forecastMap.put(m, values.isEmpty() ? 0 : Math.round(sum / values.size()));
        }

        List<String> monthNames = new List<String>{
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        };

        // 4. Build result for 12 months
        for (Integer i = 1; i <= 12; i++) {
            if (currentYearData.containsKey(i)) {
                result.add(new Map<String, Object>{
                    'month' => monthNames[i - 1],
                    'amount' => currentYearData.get(i),
                    'isForecast' => false
                });
            } else {
                result.add(new Map<String, Object>{
                    'month' => monthNames[i - 1],
                    'amount' => forecastMap.get(i),
                    'isForecast' => true
                });
            }
        }

    } catch (Exception e) {
        System.debug('❌ Error in getSpendOverTimeWithForecast: ' + e.getMessage());
        throw new AuraHandledException('Failed to generate forecast: ' + e.getMessage());
    }

    return result;
}



//here end

                @AuraEnabled(cacheable=true)
                public static List<Map<String, Object>> getSpendOverTime(Id vendorId, Id organisationId, Integer year) {
                List<Map<String, Object>> result = new List<Map<String, Object>>();
    
                    if (vendorId == null || organisationId == null || year == null) {
                return result;
            }
            try {
                // Query payments by vendor, org, year with filters
                List<AggregateResult> monthlyTotals = [
                    SELECT CALENDAR_MONTH(CreatedDate) month,
                        SUM(Amount__c) total
                    FROM Payment__c
                    WHERE Accounts__c = :vendorId
                    AND Status__c = 'Paid'
                    AND Purchase_Orders__c != null
                    AND Bill__c != null
                    AND Account__c = :organisationId
                    AND CALENDAR_YEAR(CreatedDate) = :year
                    GROUP BY CALENDAR_MONTH(CreatedDate)
                    ORDER BY CALENDAR_MONTH(CreatedDate)
                ];
    
                // Month names
                List<String> monthNames = new List<String>{
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                };
    
                // Build result list
                for (AggregateResult ar : monthlyTotals) {
                    Integer monthIndex = (Integer) ar.get('month') - 1;
                    result.add(new Map<String, Object>{
                        'month' => monthNames[monthIndex],
                        'amount' => (Decimal) ar.get('total')
                    });
                }
    
            } catch (Exception e) {
                System.debug('❌ Error in getSpendOverTime: ' + e.getMessage());
    
                // Still return dummy if exception occurs
                List<String> monthNames = new List<String>{        'January', 'February', 'March', 'April', 'May', 'June',        'July', 'August', 'September', 'October', 'November', 'December'
                };
                for (Integer i = 0; i < 12; i++) {
                    result.add(new Map<String, Object>{
                        'month' => monthNames[i],
                        'amount' => Math.mod((i + 1) * 2500 + 1000, 30000)
                    });
                }
            }
            return result;
        }

// ontime delivery
                @AuraEnabled(cacheable=true)
                public static List<Map<String, Object>> getOnTimeDeliveryMapped(Id vendorId, Id organisationId, Integer year) {
                    List<Map<String, Object>> results = new List<Map<String, Object>>();
                    System.debug('==== Method Invoked ====');
                    System.debug('Vendor Id: ' + vendorId);
                    System.debug('Year: ' + year);
    
                    if (vendorId == null || year == null) {
                        System.debug('Vendor ID or Year is null. Returning empty result.');
                        return results;
                    }
    
                    // Get relevant POs
                    Map<Id, PO__c> poMap = new Map<Id, PO__c>();
                    List<PO__c> pos = [
                        SELECT Id, Name,
                            Expected_Date__c,
                            Order_Date__c
                        FROM PO__c
                        WHERE Vendor__c = :vendorId
                        AND Order_Date__c != null
                        AND CALENDAR_YEAR(Order_Date__c) = :year
                    ];
    
                    for (PO__c po : pos) {
                        poMap.put(po.Id, po);
                    }
    
                    if (poMap.isEmpty()) {
                        return results;
                    }
    
                    // Fetch related Stock Inward Line Items
                    List<Stock_Inward_Line_Item__c> lineItems = [
                        SELECT Received_Month__c, Purchase_Orders__c
                        FROM Stock_Inward_Line_Item__c
                        WHERE Purchase_Orders__c IN :poMap.keySet()
                        AND Received_Month__c != null
                    ];
    
                    // Group delivery status by month
                    Map<String, Map<String, Integer>> monthSummary = new Map<String, Map<String, Integer>>();
    
                    for (Stock_Inward_Line_Item__c item : lineItems) {
                        PO__c po = poMap.get(item.Purchase_Orders__c);
                        if (po == null || po.Expected_Date__c == null) continue;
    
                        String expectedMonth = po.Expected_Date__c.format().substring(0, 7); // 'YYYY-MM'
                        String receivedMonth = item.Received_Month__c;
                        Boolean isOnTime = receivedMonth.compareTo(expectedMonth) <= 0;
    
                        // Group by receivedMonth (not expectedMonth), adjust if needed
                        String keyMonth = receivedMonth;
    
                        if (!monthSummary.containsKey(keyMonth)) {
                            monthSummary.put(keyMonth, new Map<String, Integer>{
                                'onTime' => 0,
                                'late' => 0
                            });
                        }
    
                        if (isOnTime) {
                            monthSummary.get(keyMonth).put('onTime', monthSummary.get(keyMonth).get('onTime') + 1);
                        } else {
                            monthSummary.get(keyMonth).put('late', monthSummary.get(keyMonth).get('late') + 1);
                        }
                    }
    
                    // Convert to List<Map<String, Object>> format
                    for (String month : monthSummary.keySet()) {
                        Map<String, Integer> counts = monthSummary.get(month);
                        results.add(new Map<String, Object>{
                            'month' => month,
                            'onTime' => counts.get('onTime'),
                            'late' => counts.get('late')
                        });
                    }
    
                    return results;
                }
    //Quality analysis
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Integer>> getMonthlyQualityData(Id vendorId, Id organisationId, Integer year) {
        Map<String, Map<String, Integer>> result = new Map<String, Map<String, Integer>>();
    
        // Initialize map with all 12 months
        for (Integer i = 1; i <= 12; i++) {
            result.put(String.valueOf(i), new Map<String, Integer>{
                'good' => 0,
                'bad' => 0
            });
        }
    
        // ✅ Dynamically use selected year to create range
        Date startDate = Date.newInstance(year, 1, 1);
        Date endDate = Date.newInstance(year, 12, 31);
    
        List<Stock_Inward_Line_Item__c> lineItems = [
            SELECT Name,
                   CreatedDate, 
                   Status__c,
                   Purchase_Orders__r.Vendor__c,
                   Purchase_Orders__r.Vendor_Contact__c,
                   Purchase_Orders__r.Active__c
            FROM Stock_Inward_Line_Item__c
            WHERE Name != 'Awaiting stock'
              AND Status__c IN ('In Stock', 'Committed', 'Rejected')
              AND Purchase_Orders__r.Active__c = true
              AND Purchase_Orders__r.Vendor__c = :vendorId
              AND CreatedDate >= :startDate
              AND CreatedDate <= :endDate
        ];
    
        for (Stock_Inward_Line_Item__c item : lineItems) {
            Integer month = item.CreatedDate.month();
            String status = item.Status__c;
    
            if (status == 'Rejected') {
                result.get(String.valueOf(month)).put('bad', result.get(String.valueOf(month)).get('bad') + 1);
            } else if (status == 'In Stock' || status == 'Committed') {
                result.get(String.valueOf(month)).put('good', result.get(String.valueOf(month)).get('good') + 1);
            }
        }
    
        return result;
    }
    
    

    // Wrapper class defined outside any method in a graph
    public class InventorySummaryWrapper {
        @AuraEnabled public Decimal totalExpectedRaw = 0;
        @AuraEnabled public Decimal totalConsumedRaw = 0;
        @AuraEnabled public Decimal totalScrappedRaw = 0;
    
        @AuraEnabled public Decimal totalWipQuantity = 0;
        @AuraEnabled public Decimal totalWipScrapped = 0;
    
        @AuraEnabled public Decimal totalFinishedRequested = 0;
        @AuraEnabled public Decimal totalFinishedInStock = 0;
        @AuraEnabled public Decimal totalFinishedScrapped = 0;
        @AuraEnabled public Decimal totalFinishedScrap = 0;
    }
    
    // based on the product name filter date from to date

        @AuraEnabled
        public static InventorySummaryWrapper getSummedInventory(Id productId, Date fromDate, Date toDate, Id organizationId) {
            // Fallback to current fiscal year (assume FY starts in April)
                System.debug('📨 Apex called with Product: ' + productId + ', From: ' + fromDate + ', To: ' + toDate);

            if (fromDate == null || toDate == null) {
                Date today = Date.today();
                Integer fiscalYearStartMonth = 4; // April
                Integer year = today.month() >= fiscalYearStartMonth ? today.year() : today.year() - 1;
                fromDate = Date.newInstance(year, fiscalYearStartMonth, 1);
                toDate = fromDate.addMonths(12).addDays(-1);
            }
    
            // Get Manufacturing Orders by product and date range
            List<Manufacturing_Order__c> moList;
            if (productId != null) {
            moList = [
                SELECT Id FROM Manufacturing_Order__c
                WHERE Product__c = :productId
                AND CreatedDate >= :fromDate AND CreatedDate <= :toDate
            ];
        } else {
            moList = [
                SELECT Id FROM Manufacturing_Order__c
                WHERE CreatedDate >= :fromDate AND CreatedDate <= :toDate
            ];
        }
    
            Set<Id> moIds = new Set<Id>();
            for (Manufacturing_Order__c mo : moList) {
                moIds.add(mo.Id);
            }
    
            InventorySummaryWrapper summary = new InventorySummaryWrapper();
    
            // RAW
            for (MRP__c rec : [
                SELECT Expected_Quantity__c, Consumed_Quantity__c, Scrapped_Quantity__c
                FROM MRP__c WHERE MO__c IN :moIds
            ]) {
                summary.totalExpectedRaw += rec.Expected_Quantity__c != null ? rec.Expected_Quantity__c : 0;
                summary.totalConsumedRaw += rec.Consumed_Quantity__c != null ? rec.Consumed_Quantity__c : 0;
                summary.totalScrappedRaw += rec.Scrapped_Quantity__c != null ? rec.Scrapped_Quantity__c : 0;
            }
    
            // WIP
            for (WIP__c rec : [
                SELECT Quantity__c, Scrapped__c
                FROM WIP__c WHERE MO__c IN :moIds
            ]) {
                summary.totalWipQuantity += rec.Quantity__c != null ? rec.Quantity__c : 0;
                summary.totalWipScrapped += rec.Scrapped__c != null ? rec.Scrapped__c : 0;
            }
    
            // Finished
            for (Inventory_Stock__c rec : [
                SELECT No_of_Items_Requested__c, Number_of_Item_In_Stock__c,
                       Number_of_Items_Scrapped__c, Scrap__c
                FROM Inventory_Stock__c WHERE Manufacturing_Order__c IN :moIds
            ]) {
                summary.totalFinishedRequested += rec.No_of_Items_Requested__c != null ? rec.No_of_Items_Requested__c : 0;
                summary.totalFinishedInStock += rec.Number_of_Item_In_Stock__c != null ? rec.Number_of_Item_In_Stock__c : 0;
                summary.totalFinishedScrapped += rec.Number_of_Items_Scrapped__c != null ? rec.Number_of_Items_Scrapped__c : 0;
                // summary.totalFinishedScrap += rec.Scrap__c != null ? rec.Scrap__c : 0;
            }
    
            return summary;
        }
        
        
    // based on the top 5 product name filter date from to date
public class Top5InventorySummaryWrapper implements Comparable {
    @AuraEnabled public Id productId;
    @AuraEnabled public String productName;

    @AuraEnabled public Decimal totalExpectedRaw = 0;
    @AuraEnabled public Decimal totalConsumedRaw = 0;
    @AuraEnabled public Decimal totalScrappedRaw = 0;

    @AuraEnabled public Decimal totalWipQuantity = 0;
    @AuraEnabled public Decimal totalWipScrapped = 0;

    @AuraEnabled public Decimal totalFinishedRequested = 0;
    @AuraEnabled public Decimal totalFinishedInStock = 0;
    @AuraEnabled public Decimal totalFinishedScrapped = 0;
    @AuraEnabled public Decimal totalFinishedScrap = 0;

    @AuraEnabled public Decimal totalAll = 0;
    public Integer compareTo(Object other) {
    Top5InventorySummaryWrapper o = (Top5InventorySummaryWrapper) other;
    Decimal diff = o.totalAll - this.totalAll;
    if (diff > 0) return 1;
    if (diff < 0) return -1;
    return 0;
}
}


   @AuraEnabled
public static List<Top5InventorySummaryWrapper> getTop5Inventory() {
    // Get fiscal year start and end from org settings
    Organization orgInfo = [SELECT FiscalYearStartMonth FROM Organization LIMIT 1];
    Integer startMonth = orgInfo.FiscalYearStartMonth;
    Date today = Date.today();
    Integer year = today.month() >= startMonth ? today.year() : today.year() - 1;
    Date fromDate = Date.newInstance(year, startMonth, 1);
    Date toDate = fromDate.addMonths(12).addDays(-1);

    // Get MOs within fiscal year
    List<Manufacturing_Order__c> mos = [
        SELECT Id, Product__c, Product__r.Name
        FROM Manufacturing_Order__c
        WHERE CreatedDate >= :fromDate AND CreatedDate <= :toDate
              AND Product__c != null
    ];

    Map<Id, Top5InventorySummaryWrapper> productSummaryMap = new Map<Id, Top5InventorySummaryWrapper>();
    Set<Id> moIds = new Set<Id>();
    Map<Id, Id> moToProductMap = new Map<Id, Id>();

    for (Manufacturing_Order__c mo : mos) {
        moIds.add(mo.Id);
        moToProductMap.put(mo.Id, mo.Product__c);
        if (!productSummaryMap.containsKey(mo.Product__c)) {
            Top5InventorySummaryWrapper wrap = new Top5InventorySummaryWrapper();
            wrap.productId = mo.Product__c;
            wrap.productName = mo.Product__r.Name;
            productSummaryMap.put(mo.Product__c, wrap);
        }
    }

    // RAW
    for (MRP__c rec : [
        SELECT MO__c, Expected_Quantity__c, Consumed_Quantity__c, Scrapped_Quantity__c
        FROM MRP__c WHERE MO__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.MO__c);
        if (productSummaryMap.containsKey(productId)) {
            Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalExpectedRaw += rec.Expected_Quantity__c != null ? rec.Expected_Quantity__c : 0;
            wrap.totalConsumedRaw += rec.Consumed_Quantity__c != null ? rec.Consumed_Quantity__c : 0;
            wrap.totalScrappedRaw += rec.Scrapped_Quantity__c != null ? rec.Scrapped_Quantity__c : 0;
        }
    }

    // WIP
    for (WIP__c rec : [
        SELECT MO__c, Quantity__c, Scrapped__c
        FROM WIP__c WHERE MO__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.MO__c);
        if (productSummaryMap.containsKey(productId)) {
            Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalWipQuantity += rec.Quantity__c != null ? rec.Quantity__c : 0;
            wrap.totalWipScrapped += rec.Scrapped__c != null ? rec.Scrapped__c : 0;
        }
    }

    // Finished
    for (Inventory_Stock__c rec : [
        SELECT Manufacturing_Order__c, No_of_Items_Requested__c,
               Number_of_Item_In_Stock__c, Number_of_Items_Scrapped__c, Scrap__c
        FROM Inventory_Stock__c
        WHERE Manufacturing_Order__c IN :moIds
    ]) {
        Id productId = moToProductMap.get(rec.Manufacturing_Order__c);
        if (productSummaryMap.containsKey(productId)) {
            Top5InventorySummaryWrapper wrap = productSummaryMap.get(productId);
            wrap.totalFinishedRequested += rec.No_of_Items_Requested__c != null ? rec.No_of_Items_Requested__c : 0;
            wrap.totalFinishedInStock += rec.Number_of_Item_In_Stock__c != null ? rec.Number_of_Item_In_Stock__c : 0;
            wrap.totalFinishedScrapped += rec.Number_of_Items_Scrapped__c != null ? rec.Number_of_Items_Scrapped__c : 0;
            // wrap.totalFinishedScrap += rec.Scrap__c != null ? rec.Scrap__c : 0;
        }
    }

    // Compute total and sort
    List<Top5InventorySummaryWrapper> sortedList = new List<Top5InventorySummaryWrapper>();
    for (Top5InventorySummaryWrapper wrap : productSummaryMap.values()) {
        wrap.totalAll = wrap.totalExpectedRaw + wrap.totalWipQuantity + wrap.totalFinishedInStock;
        sortedList.add(wrap);
    }

    sortedList.sort(); // Uses compareTo() defined above
List<Top5InventorySummaryWrapper> top5List = new List<Top5InventorySummaryWrapper>();

for (Integer i = 0; i < Math.min(5, sortedList.size()); i++) {
    top5List.add(sortedList[i]);
}
return top5List;
}

@AuraEnabled(cacheable=true)
public static Integer getOrgFiscalStartMonth() {
    // return [SELECT FiscalYearStartMonth FROM Organization LIMIT 1].FiscalYearStartMonth;

      try {
        System.debug('📘 Attempting to fetch FiscalYearSettings...');
        
        FiscalYearSettings fys = [
            SELECT StartDate, YearType, IsStandardYear
            FROM FiscalYearSettings
            LIMIT 1
        ];
        
        System.debug('✅ Retrieved FiscalYearSettings: StartDate = ' + fys.StartDate + ', YearType = ' + fys.YearType);

        // ✅ First, handle Standard Fiscal Year
        if (fys.IsStandardYear == true) {
            System.debug('📘 Detected Standard Fiscal Year. Fetching FiscalYearStartMonth from Organization...');
            
            Organization orgInfo = [
                SELECT FiscalYearStartMonth
                FROM Organization
                LIMIT 1
            ];

            Integer fiscalStartMonth = orgInfo.FiscalYearStartMonth;
            System.debug('✅ Standard Fiscal Year Start Month: ' + fiscalStartMonth);
            return fiscalStartMonth;
        }

        // ✅ Else, handle Custom Fiscal Year
        Integer customStartMonth = fys.StartDate.month();
        System.debug('✅ Custom Fiscal Year detected. Start Month: ' + customStartMonth);
        return customStartMonth;

    } catch (Exception e) {
        System.debug('⚠️ Exception caught: ' + e.getMessage());
        System.debug('🔁 Attempting fallback using Organization object...');

        try {
            Organization orgInfo = [
                SELECT FiscalYearStartMonth
                FROM Organization
                LIMIT 1
            ];

            Integer fiscalStartMonth = orgInfo.FiscalYearStartMonth;
            System.debug('✅ Fallback Fiscal Year Start Month: ' + fiscalStartMonth);
            return fiscalStartMonth;

        } catch (Exception inners) {
            System.debug('❌ Fallback failed: ' + inners.getMessage());
            Integer defaultMonth = Date.today().month();
            System.debug('🚨 Returning current month as last resort: ' + defaultMonth);
            return defaultMonth;
        }
    }
    }


@AuraEnabled(cacheable=true)
public static Site__c getDefaultWarehouseByStock(Id organisationId) {
    List<Site__c> topSite = [
        SELECT Id, Name
        FROM Site__c
        WHERE Active__c = TRUE
        AND Company__c = :organisationId
        AND Stock__c != null
        ORDER BY Stock__c DESC
        LIMIT 1
    ];

    return topSite.isEmpty() ? null : topSite[0];
}


@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getTopCustomersForProduct(Id productId, Integer topN,Id OrgId) {
    Integer currentYear = Date.today().year();
    Date startDate = Date.newInstance(currentYear, 1, 1);
    Date endDate = Date.newInstance(currentYear, 12, 31);

    List<AggregateResult> results = [
        SELECT Order.AccountId accId, SUM(Quantity) totalQty
        FROM OrderItem
        WHERE Product2Id = :productId
        AND Order.Status = 'Activated'
        AND Order.EffectiveDate >= :startDate AND Order.EffectiveDate <= :endDate
        AND Company__c = :OrgId
        GROUP BY Order.AccountId
        ORDER BY SUM(Quantity) DESC
        LIMIT :topN
    ];

    List<Map<String, Object>> response = new List<Map<String, Object>>();
    for (AggregateResult ar : results) {
        Id accId = (Id)ar.get('accId');
        Decimal qty = (Decimal)ar.get('totalQty');
        Account acc = [SELECT Name FROM Account WHERE Id = :accId LIMIT 1];

        Map<String, Object> entry = new Map<String, Object>();
        entry.put('accountId', accId);    entry.put('accountName', acc.Name);    entry.put('quantity', qty.setScale(2));    response.add(entry);
    }

    return response;
}

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getStockAlertData(Id siteId, Id location, Id product, Id OrgId) {
    if (siteId == null || OrgId == null) {
        throw new AuraHandledException('Site (Warehouse) and Organisation are required');
    }

    // Base query
    String baseQuery = 'SELECT Product__c, Number_of_Item_In_Stock__c, ' +
                       'Warehouse__r.Name, Location__r.Name ' +
                       'FROM Inventory_Stock__c ' +
                       'WHERE Active__c = true ' +
                       'AND Warehouse__c = :siteId ' +
                       'AND Company__c = :OrgId ' +
                       'AND Name != \'Awaiting Stock\' ' +
                       'AND Number_of_Item_In_Stock__c > 0 ';

    if (location != null) {
        baseQuery += 'AND Location__c = :location ';
    }
    if (product != null) {
        baseQuery += 'AND Product__c = :product ';
    }

    // Optional: Add limit if product and location both given (small result set)
    if (location != null && product != null) {
        baseQuery += 'LIMIT 2000 ';
    }

    List<Inventory_Stock__c> inventoryRecords = Database.query(baseQuery);

    // Step 2: Group by Product + Warehouse + Location
    Map<String, Map<String, Object>> dataMap = new Map<String, Map<String, Object>>();
    Set<Id> productIds = new Set<Id>();

    for (Inventory_Stock__c stock : inventoryRecords) {
        Id productId = stock.Product__c;
        String warehouseName = stock.Warehouse__r.Name;     String locationName = stock.Location__r.Name;     String key = productId + '|' + warehouseName + '|' + locationName;

        productIds.add(productId);

        if (!dataMap.containsKey(key)) {
            dataMap.put(key, new Map<String, Object>{
                'productId' => productId,    'currentStock' => 0,    'warehouse' => warehouseName,    'location' => locationName
            });
        }

        Decimal existing = (Decimal) dataMap.get(key).get('currentStock');
        dataMap.get(key).put('currentStock', existing + stock.Number_of_Item_In_Stock__c);
    }

    if (productIds.isEmpty()) return new List<Map<String, Object>>();

    // Step 3: Product names
    Map<Id, String> productNameMap = new Map<Id, String>();
    for (Product2 prod : [SELECT Id, Name FROM Product2 WHERE Id IN :productIds]) {
        productNameMap.put(prod.Id, prod.Name);
    }

    // Step 4: Reordering rules
    Map<Id, Reordering_Rule__c> ruleMap = new Map<Id, Reordering_Rule__c>();
    for (Reordering_Rule__c rule : [
        SELECT Product__c, Safety_Stock__c, Reorder_Level__c
        FROM Reordering_Rule__c
        WHERE Warehouse__c = :siteId
        AND Product__c IN :productIds
        AND Active__c = true
    ]) {
        ruleMap.put(rule.Product__c, rule);
    }

    // Step 5: Assemble result
    List<Map<String, Object>> results = new List<Map<String, Object>>();
    for (Map<String, Object> row : dataMap.values()) {
        Id productId = (Id) row.get('productId');
        Decimal stock = (Decimal) row.get('currentStock');    Decimal reorder = 0;    Decimal safety = 0;

        if (ruleMap.containsKey(productId)) {
            Reordering_Rule__c rule = ruleMap.get(productId);
            reorder = rule.Reorder_Level__c != null ? rule.Reorder_Level__c : 0;
            safety = rule.Safety_Stock__c != null ? rule.Safety_Stock__c : 0;
        }

        row.put('productName', productNameMap.get(productId));
        row.put('reorderLevel', reorder);
        row.put('safetyStock', safety);

        results.add(row);
    }
System.debug('FINAL RESULTS: ' + results);

    return results;
}



// ================== DROP-IN REPLACEMENT ==================
@AuraEnabled(cacheable=true)
public static List<MonthlyPriceDTO> getMonthlySalesPriceStats(
    Id productId,
    Id orgId,
    Date startDate,
    Date endDate
) {
    if (startDate == null) startDate = System.today().addMonths(-12);
    if (endDate == null) endDate = System.today();

    // --------------------------------------------
    // 1) Keep your existing AVG/MIN/MAX (by Invoice date)
    // --------------------------------------------
    String invAgg =
        'SELECT CALENDAR_YEAR(Invoice__r.Invoice_Date__c) yr, ' +
               'CALENDAR_MONTH(Invoice__r.Invoice_Date__c) mn, ' +
               'AVG(Unit_Price__c) avgP, MIN(Unit_Price__c) minP, MAX(Unit_Price__c) maxP ' +
        'FROM Invoice_Line_Item__c ' +
        'WHERE Product__c = :productId ' +
        'AND Invoice__r.Invoice_Date__c >= :startDate ' +
        'AND Invoice__r.Invoice_Date__c <= :endDate ';

    if (orgId != null) invAgg += 'AND Invoice__r.Company__c = :orgId ';

    invAgg += 'GROUP BY CALENDAR_YEAR(Invoice__r.Invoice_Date__c), ' +
              'CALENDAR_MONTH(Invoice__r.Invoice_Date__c) ' +
              'ORDER BY CALENDAR_YEAR(Invoice__r.Invoice_Date__c) ASC, ' +
                       'CALENDAR_MONTH(Invoice__r.Invoice_Date__c) ASC';

    List<AggregateResult> invResults = Database.query(invAgg);

    // Store price stats keyed by "YYYY-M" (e.g., 2025-7)
    Map<String, PriceStats> priceByMonth = new Map<String, PriceStats>();
    for (AggregateResult ar : invResults) {
        Integer yr = (Integer)ar.get('yr');
        Integer mn = (Integer)ar.get('mn');
        String key = String.valueOf(yr) + '-' + String.valueOf(mn);
        priceByMonth.put(key, new PriceStats(
            (Decimal)ar.get('avgP'),           (Decimal)ar.get('minP'),            (Decimal)ar.get('maxP')
        ));
    }

    // --------------------------------------------
    // 2) NEW: Pull Sales Orders for the product & window (by OrderItem)
    //    Group by EffectiveDate (month), then break down by Status
    // --------------------------------------------
    // Guard-rail for prod
   // ---- One dynamic SOQL, no if/else ----
Integer MAX_ROWS = 5000;

String baseSoql =
'SELECT Id,' +
'       Order.Id, Order.Name, Order.OrderNumber, Order.EffectiveDate, Order.Status,' +
'       Order.AccountId,' +
'       Order.Account.Name,' + 
'       Order.Stage__c, Order.Expected_Date__c,' +
'       Order.Company__c, Order.Sub_Total__c, Order.Order_Amount__c,' +
'       Order.Packed_Quantity__c, Order.Picked_Quantity__c,' +
'       Order.Shipped_Quantity__c, Order.Total_Quantity__c ' +
'FROM OrderItem ' +
'WHERE Product2Id = :productId ' +
'  AND Order.EffectiveDate >= :startDate ' +
'  AND Order.EffectiveDate <= :endDate';

String orgClause = (orgId == null) ? '' : ' AND Order.Company__c = :orgId';

String finalSoql = baseSoql +
                   orgClause +
                   ' ORDER BY Order.EffectiveDate DESC ' +
                   ' LIMIT ' + String.valueOf(MAX_ROWS);

List<OrderItem> ois = Database.query(finalSoql);

    // Per-month containers (key = "YYYY-M")
    Map<String, Integer> monthSOCount   = new Map<String, Integer>();                           // NEW
    // NEW: per-status counts
    Map<String, Integer> monthDraftCount        = new Map<String, Integer>();
    Map<String, Integer> monthEnteredCount      = new Map<String, Integer>();
    Map<String, Integer> monthActivatedCount    = new Map<String, Integer>();
    Map<String, Integer> monthPickedUpCount     = new Map<String, Integer>();
    Map<String, Integer> monthPartShippedCount  = new Map<String, Integer>();
    Map<String, Integer> monthShippedCount      = new Map<String, Integer>();
    Map<String, Integer> monthDeliveredCount    = new Map<String, Integer>();
    Map<String, Integer> monthCancelledCount    = new Map<String, Integer>();

    // NEW: per-status lists (detailed wrappers)
    Map<String, List<SOWrapper>> monthDraftList       = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthEnteredList     = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthActivatedList   = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthPickedUpList    = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthPartShippedList = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthShippedList     = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthDeliveredList   = new Map<String, List<SOWrapper>>();
    Map<String, List<SOWrapper>> monthCancelledList   = new Map<String, List<SOWrapper>>();

    for (OrderItem oi : ois) {
        if (oi.Order == null || oi.Order.EffectiveDate == null) continue;

        Date eff = oi.Order.EffectiveDate;
        String key = eff.year() + '-' + eff.month();

        // init maps
        if (!monthSOCount.containsKey(key)) monthSOCount.put(key, 0);

        // init lists
        if (!monthDraftList.containsKey(key))       monthDraftList.put(key, new List<SOWrapper>());
        if (!monthEnteredList.containsKey(key))     monthEnteredList.put(key, new List<SOWrapper>());
        if (!monthActivatedList.containsKey(key))   monthActivatedList.put(key, new List<SOWrapper>());
        if (!monthPickedUpList.containsKey(key))    monthPickedUpList.put(key, new List<SOWrapper>());
        if (!monthPartShippedList.containsKey(key)) monthPartShippedList.put(key, new List<SOWrapper>());
        if (!monthShippedList.containsKey(key))     monthShippedList.put(key, new List<SOWrapper>());
        if (!monthDeliveredList.containsKey(key))   monthDeliveredList.put(key, new List<SOWrapper>());
        if (!monthCancelledList.containsKey(key))   monthCancelledList.put(key, new List<SOWrapper>());

        if (!monthDraftCount.containsKey(key))       monthDraftCount.put(key, 0);
        if (!monthEnteredCount.containsKey(key))     monthEnteredCount.put(key, 0);
        if (!monthActivatedCount.containsKey(key))   monthActivatedCount.put(key, 0);
        if (!monthPickedUpCount.containsKey(key))    monthPickedUpCount.put(key, 0);
        if (!monthPartShippedCount.containsKey(key)) monthPartShippedCount.put(key, 0);
        if (!monthShippedCount.containsKey(key))     monthShippedCount.put(key, 0);
        if (!monthDeliveredCount.containsKey(key))   monthDeliveredCount.put(key, 0);
        if (!monthCancelledCount.containsKey(key))   monthCancelledCount.put(key, 0);

        // Build detail wrapper
        SOWrapper w = new SOWrapper( // NEW
            (String)oi.Order.Id,
            oi.Order.Name,
            oi.Order.OrderNumber,
            oi.Order.EffectiveDate,
            oi.Order.Expected_Date__c,
            oi.Order.Status,
            oi.Order.AccountId,
            (oi.Order.Account != null ? oi.Order.Account.Name : null),  // 🆕 pass Account Name
            (String)oi.Order.Company__c,
            oi.Order.Stage__c,
            oi.Order.Sub_Total__c,
            oi.Order.Order_Amount__c,
            oi.Order.Packed_Quantity__c,
            oi.Order.Picked_Quantity__c,
            oi.Order.Shipped_Quantity__c,
            oi.Order.Total_Quantity__c
        );

        // Tally
        monthSOCount.put(key, monthSOCount.get(key) + 1);

        // Normalize statuses into the 8 buckets you listed
        String st = (oi.Order.Status != null) ? oi.Order.Status.trim() : '';
        if (st == 'Draft') {
            monthDraftCount.put(key, monthDraftCount.get(key)+1);
            monthDraftList.get(key).add(w);
        } else if (st == 'Entered') {
            monthEnteredCount.put(key, monthEnteredCount.get(key)+1);
            monthEnteredList.get(key).add(w);
        } else if (st == 'Activated') {
            monthActivatedCount.put(key, monthActivatedCount.get(key)+1);
            monthActivatedList.get(key).add(w);
        } else if (st == 'Picked Up') {
            monthPickedUpCount.put(key, monthPickedUpCount.get(key)+1);
            monthPickedUpList.get(key).add(w);
        } else if (st == 'Partially Shipped') {
            monthPartShippedCount.put(key, monthPartShippedCount.get(key)+1);
            monthPartShippedList.get(key).add(w);
        } else if (st == 'Shipped') {
            monthShippedCount.put(key, monthShippedCount.get(key)+1);
            monthShippedList.get(key).add(w);
        } else if (st == 'Delivered') {
            monthDeliveredCount.put(key, monthDeliveredCount.get(key)+1);
            monthDeliveredList.get(key).add(w);
        } else if (st == 'Cancelled') {
            monthCancelledCount.put(key, monthCancelledCount.get(key)+1);
            monthCancelledList.get(key).add(w);
        } else {
            // Unknown statuses: optionally bucket to Entered or ignore
            monthEnteredCount.put(key, monthEnteredCount.get(key)+1);
            monthEnteredList.get(key).add(w);
        }
    }

    // --------------------------------------------
    // 3) Build DTOs by union of keys (invoice stats ⨁ order buckets)
    // --------------------------------------------
    Set<String> allKeys = new Set<String>();
    allKeys.addAll(priceByMonth.keySet());
    allKeys.addAll(monthSOCount.keySet());

    List<MonthlyPriceDTO> out = new List<MonthlyPriceDTO>();
    for (String key : allKeys) {
        Integer yr = Integer.valueOf(key.split('-')[0]);
        Integer mn = Integer.valueOf(key.split('-')[1]);

        // default zeros, then override from invoice map if present
        Decimal avgP = 0, minP = 0, maxP = 0;
        if (priceByMonth.containsKey(key)) {
            avgP = priceByMonth.get(key).avgP;
            minP = priceByMonth.get(key).minP;
            maxP = priceByMonth.get(key).maxP;
        }

        MonthlyPriceDTO dto = new MonthlyPriceDTO(yr, mn, avgP, minP, maxP);

        // ---- NEW: sales order counts & lists on DTO ----
        dto.totalSOCount          = monthSOCount.containsKey(key)         ? monthSOCount.get(key)         : 0;
        dto.soDraftCount          = monthDraftCount.containsKey(key)      ? monthDraftCount.get(key)      : 0;
        dto.soEnteredCount        = monthEnteredCount.containsKey(key)    ? monthEnteredCount.get(key)    : 0;
        dto.soActivatedCount      = monthActivatedCount.containsKey(key)  ? monthActivatedCount.get(key)  : 0;
        dto.soPickedUpCount       = monthPickedUpCount.containsKey(key)   ? monthPickedUpCount.get(key)   : 0;
        dto.soPartShippedCount    = monthPartShippedCount.containsKey(key)? monthPartShippedCount.get(key): 0;
        dto.soShippedCount        = monthShippedCount.containsKey(key)    ? monthShippedCount.get(key)    : 0;
        dto.soDeliveredCount      = monthDeliveredCount.containsKey(key)  ? monthDeliveredCount.get(key)  : 0;
        dto.soCancelledCount      = monthCancelledCount.containsKey(key)  ? monthCancelledCount.get(key)  : 0;

        dto.soDraftList           = monthDraftList.get(key);
        dto.soEnteredList         = monthEnteredList.get(key);
        dto.soActivatedList       = monthActivatedList.get(key);
        dto.soPickedUpList        = monthPickedUpList.get(key);
        dto.soPartiallyShippedList= monthPartShippedList.get(key);
        dto.soShippedList         = monthShippedList.get(key);
        dto.soDeliveredList       = monthDeliveredList.get(key);
        dto.soCancelledList       = monthCancelledList.get(key);

        out.add(dto);
    }

    out.sort(); // relies on your MonthlyPriceDTO.compareTo (year, month)
    return out;
}

// Helper holder for price stats (internal to this class)
private class PriceStats {
    Decimal avgP; Decimal minP; Decimal maxP;
    PriceStats(Decimal a, Decimal n, Decimal x) { avgP=a; minP=n; maxP=x; }
}

// ================== ADD THIS WRAPPER (sibling class) ==================
// NEW: Sales Order wrapper returned inside DTO lists
public class SOWrapper {
    @AuraEnabled public String   orderId              { get; set; }
    @AuraEnabled public String   Name            { get; set; }
    @AuraEnabled public String   OrderNumber     { get; set; }
    @AuraEnabled public Date     EffectiveDate   { get; set; }
    @AuraEnabled public Date     ExpectedDate    { get; set; }         // Expected_Date__c
    @AuraEnabled public String   Status          { get; set; }
    @AuraEnabled public String   AccountId       { get; set; }
        @AuraEnabled public String   AccountName     { get; set; }         // 🆕 Account Name
    @AuraEnabled public String   OrganisationId  { get; set; }         // Company__c
    @AuraEnabled public String   Stage           { get; set; }         // Stage__c
    @AuraEnabled public Decimal  SubTotal        { get; set; }         // Sub_Total__c
    @AuraEnabled public Decimal  OrderAmount     { get; set; }         // Order_Amount__c
    @AuraEnabled public Decimal  PackedQty       { get; set; }         // Packed_Quantity__c
    @AuraEnabled public Decimal  PickedQty       { get; set; }         // Picked_Quantity__c
    @AuraEnabled public Decimal  ShippedQty      { get; set; }         // Shipped_Quantity__c
    @AuraEnabled public Decimal  TotalQty        { get; set; }         // Total_Quantity__c

    public SOWrapper(String id, String name, String ordNo, Date eff, Date exp, String st,
                     String acctId,  String acctName,String orgId, String stage,
                     Decimal subTot, Decimal ordAmt,
                     Decimal packed, Decimal picked, Decimal shipped, Decimal totalQ) {
        orderId = id; Name = name; OrderNumber = ordNo;
        EffectiveDate = eff; ExpectedDate = exp; Status = st;
                AccountId = acctId; AccountName = acctName;              // 🆕 set AccountName
        AccountId = acctId; OrganisationId = orgId; Stage = stage;
        SubTotal = subTot; OrderAmount = ordAmt;
        PackedQty = packed; PickedQty = picked; ShippedQty = shipped; TotalQty = totalQ;
    }
}



// -------------------------
// PURCHASE PRICE
// -------------------------
@AuraEnabled(cacheable=true)
public static List<MonthlyPriceDTO> getMonthlyPurchasePriceStats(
    Id productId,
    Id orgId,
    Date startDate,
    Date endDate
) {
    if (startDate == null) startDate = System.today().addMonths(-12);
    if (endDate == null) endDate = System.today();

    Integer maxLineItemRows = 5000;
    Integer maxPoRows       = 5000;

    // --- 1) Aggregate avg/min/max by month
    String aggQuery =
        'SELECT CALENDAR_YEAR(Purchase_Orders__r.Order_Date__c) yr, ' +
        '       CALENDAR_MONTH(Purchase_Orders__r.Order_Date__c) mn, ' +
        '       AVG(Unit_Price__c) avgP, MIN(Unit_Price__c) minP, MAX(Unit_Price__c) maxP ' +
        'FROM Purchase_Line_Items__c ' +
        'WHERE Product__c = :productId ' +
        'AND   Purchase_Orders__r.Order_Date__c >= :startDate ' +
        'AND   Purchase_Orders__r.Order_Date__c <= :endDate ';

    if (orgId != null) {
        aggQuery += 'AND   Purchase_Orders__r.Company__c = :orgId ';
    }

    aggQuery += 'GROUP BY CALENDAR_YEAR(Purchase_Orders__r.Order_Date__c), ' +
                '         CALENDAR_MONTH(Purchase_Orders__r.Order_Date__c) ' +
                'ORDER BY CALENDAR_YEAR(Purchase_Orders__r.Order_Date__c), ' +
                '         CALENDAR_MONTH(Purchase_Orders__r.Order_Date__c) ' +
                'LIMIT :maxLineItemRows';

    List<AggregateResult> arList = Database.query(aggQuery);

    Map<String, MonthlyPriceDTO> dtoByKey = new Map<String, MonthlyPriceDTO>();
    for (AggregateResult ar : arList) {
        Integer yr = (Integer) ar.get('yr');
        Integer mn = (Integer) ar.get('mn');
        Decimal avgP = (Decimal) ar.get('avgP');
        Decimal minP = (Decimal) ar.get('minP');
        Decimal maxP = (Decimal) ar.get('maxP');
        String key = yr + '-' + mn;

        MonthlyPriceDTO dto = new MonthlyPriceDTO(yr, mn, avgP, minP, maxP);
        dto.totalPOCount = 0;
        dto.initPOStatusLists(); // ✅ helper method in DTO
        dtoByKey.put(key, dto);
    }

    // --- 2) Fetch detailed POs
    String poQuery =
        'SELECT Id, Name, Company__c, Total_Amount__c, Order_Date__c, ' +
        '       Status__c, Vendor__c, Vendor__r.Name ' +
        'FROM PO__c ' +
        'WHERE Id IN ( ' +
        '   SELECT Purchase_Orders__c FROM Purchase_Line_Items__c WHERE Product__c = :productId ' +
        ') ' +
        'AND   Order_Date__c >= :startDate ' +
        'AND   Order_Date__c <= :endDate ';

    if (orgId != null) {
        poQuery += 'AND   Company__c = :orgId ';
    }

    poQuery += 'ORDER BY Order_Date__c DESC, CreatedDate DESC ' +
               'LIMIT :maxPoRows';

    List<PO__c> pos = Database.query(poQuery);

    for (PO__c po : pos) {
        if (po.Order_Date__c == null) continue;
        Integer yr = po.Order_Date__c.year();
        Integer mn = po.Order_Date__c.month();
        String key = yr + '-' + mn;

        if (!dtoByKey.containsKey(key)) {
            MonthlyPriceDTO dto = new MonthlyPriceDTO(yr, mn, 0, 0, 0);
            dto.initPOStatusLists();
            dtoByKey.put(key, dto);
        }

        MonthlyPriceDTO dto = dtoByKey.get(key);
        POWrapper wrap = new POWrapper(
            (String)po.Id, po.Name, (String)po.Company__c,
            po.Total_Amount__c, po.Order_Date__c,
            po.Status__c, (String)po.Vendor__c,
            po.Vendor__r != null ? po.Vendor__r.Name : null
        );

        dto.totalPOCount++;

        // ✅ Handle all status types
        String status = po.Status__c;
        if (status == 'Draft') dto.poDraftList.add(wrap);
        else if (status == 'Logged') dto.poLoggedList.add(wrap);
        else if (status == 'Assigned') dto.poAssignedList.add(wrap);        else if (status == 'Approved') dto.poApprovedList.add(wrap); 
        else if (status == 'Rejected') dto.poRejectedList.add(wrap);    
        else if (status == 'In Progress') dto.poInProgressList.add(wrap);        else if (status == 'Booked') dto.poBookedList.add(wrap);
        else if (status == 'Closed') dto.poClosedList.add(wrap);        else if (status == 'Cancelled') dto.poCancelledList.add(wrap);
        else if (status == 'Supplier Accepted') dto.poSupplierAcceptedList.add(wrap);        else if (status == 'Reconciled') dto.poReconciledList.add(wrap);
        else if (status == 'Submitted for Approval') dto.poSubmittedForApprovalList.add(wrap);     else if (status == 'On Hold') dto.poOnHoldList.add(wrap);
    }

    List<MonthlyPriceDTO> out = new List<MonthlyPriceDTO>(dtoByKey.values());
    out.sort();
    return out;
}


// ---------------------- PO Wrapper (for LWC table rows) ----------------------
public class POWrapper {
    @AuraEnabled public String Id { get; set; }
    @AuraEnabled public String Name { get; set; }
    @AuraEnabled public String organisationId { get; set; }
    @AuraEnabled public Decimal totalAmount { get; set; }
    @AuraEnabled public Date orderDate { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public String vendorId { get; set; }
    @AuraEnabled public String vendorName { get; set; }

    public POWrapper(String id, String name, String orgId, Decimal totalAmt, Date ordDate,
                     String stat, String vendId, String vendName) {
        this.Id = id;
        this.Name = name;
        this.organisationId = orgId;
        this.totalAmount = totalAmt;
        this.orderDate = ordDate;
        this.status = stat;
        this.vendorId = vendId;
        this.vendorName = vendName;
    }
}


// ---------------------- Manufacturing Unit Price Stats ----------------------
@AuraEnabled(cacheable=true)
public static List<MonthlyPriceDTO> getMonthlyManufacturingUnitPriceStats(
    Id productId,
    Date startDate,
    Date endDate
) {
    if (startDate == null) startDate = System.today().addMonths(-12);
    if (endDate == null) endDate = System.today();
         Integer maxRows = 5000;

    String baseQuery =
        'SELECT Id, Name, StartDate__c, End_Date__c, ExpectedDate__c, ' +
        '       Quantity__c, Cost__c, Status__c, ' +
        '       Duration__c, Product__c, Product__r.Name ' +
        'FROM Manufacturing_Order__c ' +
        'WHERE Product__c = :productId ' +
        'AND   StartDate__c >= :startDate ' +
        'AND   StartDate__c <= :endDate ' +
        'ORDER BY StartDate__c DESC, CreatedDate DESC ' +
        'LIMIT :maxRows';

    List<Manufacturing_Order__c> orders = Database.query(baseQuery);

    // Maps per month
    Map<String, List<Decimal>> monthUnitCostMap = new Map<String, List<Decimal>>();
    Map<String, List<Decimal>> monthDurationMap = new Map<String, List<Decimal>>();
    Map<String, List<Decimal>> monthDelayMap    = new Map<String, List<Decimal>>();
    Map<String, Integer> monthTotalCount        = new Map<String, Integer>();
    Map<String, Integer> monthCompletedCount    = new Map<String, Integer>();
    Map<String, Integer> monthInProgressCount   = new Map<String, Integer>();
    Map<String, Integer> monthDraftCount        = new Map<String, Integer>();
    Map<String, Integer> monthCancelledCount    = new Map<String, Integer>();
    Map<String, Integer> monthReleaseCount      = new Map<String, Integer>();

    // MO lists per status (Id + Name — kept as-is)
    Map<String, List<IdNameWrapper>> monthCompletedMOs  = new Map<String, List<IdNameWrapper>>();
    Map<String, List<IdNameWrapper>> monthInProgressMOs = new Map<String, List<IdNameWrapper>>();
    Map<String, List<IdNameWrapper>> monthDraftMOs      = new Map<String, List<IdNameWrapper>>();
    Map<String, List<IdNameWrapper>> monthCancelledMOs  = new Map<String, List<IdNameWrapper>>();
    Map<String, List<IdNameWrapper>> monthReleaseMOs    = new Map<String, List<IdNameWrapper>>();

    // ✅ NEW: detailed MO lists per status (with extra fields)
    Map<String, List<MOWrapper>> monthCompletedMODetails  = new Map<String, List<MOWrapper>>();
    Map<String, List<MOWrapper>> monthInProgressMODetails = new Map<String, List<MOWrapper>>();
    Map<String, List<MOWrapper>> monthDraftMODetails      = new Map<String, List<MOWrapper>>();
    Map<String, List<MOWrapper>> monthCancelledMODetails  = new Map<String, List<MOWrapper>>();
    Map<String, List<MOWrapper>> monthReleaseMODetails    = new Map<String, List<MOWrapper>>();

    for (Manufacturing_Order__c mo : orders) {
        if (mo.StartDate__c == null) continue;
        String key = mo.StartDate__c.year() + '-' + mo.StartDate__c.month();

        if (!monthUnitCostMap.containsKey(key)) monthUnitCostMap.put(key, new List<Decimal>());
        if (!monthDurationMap.containsKey(key)) monthDurationMap.put(key, new List<Decimal>());
        if (!monthDelayMap.containsKey(key))    monthDelayMap.put(key, new List<Decimal>());
        if (!monthTotalCount.containsKey(key))      monthTotalCount.put(key, 0);
        if (!monthCompletedCount.containsKey(key))  monthCompletedCount.put(key, 0);
        if (!monthInProgressCount.containsKey(key)) monthInProgressCount.put(key, 0);
        if (!monthDraftCount.containsKey(key))      monthDraftCount.put(key, 0);
        if (!monthCancelledCount.containsKey(key))  monthCancelledCount.put(key, 0);
        if (!monthReleaseCount.containsKey(key))    monthReleaseCount.put(key, 0);

        if (!monthCompletedMOs.containsKey(key))  monthCompletedMOs.put(key, new List<IdNameWrapper>());
        if (!monthInProgressMOs.containsKey(key)) monthInProgressMOs.put(key, new List<IdNameWrapper>());
        if (!monthDraftMOs.containsKey(key))      monthDraftMOs.put(key, new List<IdNameWrapper>());
        if (!monthCancelledMOs.containsKey(key))  monthCancelledMOs.put(key, new List<IdNameWrapper>());
        if (!monthReleaseMOs.containsKey(key))    monthReleaseMOs.put(key, new List<IdNameWrapper>());

        // ✅ init detailed lists
        if (!monthCompletedMODetails.containsKey(key))  monthCompletedMODetails.put(key, new List<MOWrapper>());
        if (!monthInProgressMODetails.containsKey(key)) monthInProgressMODetails.put(key, new List<MOWrapper>());
        if (!monthDraftMODetails.containsKey(key))      monthDraftMODetails.put(key, new List<MOWrapper>());
        if (!monthCancelledMODetails.containsKey(key))  monthCancelledMODetails.put(key, new List<MOWrapper>());
        if (!monthReleaseMODetails.containsKey(key))    monthReleaseMODetails.put(key, new List<MOWrapper>());

        // Unit Cost series
        if (mo.Quantity__c != null && mo.Quantity__c != 0 && mo.Cost__c != null) {
            monthUnitCostMap.get(key).add(mo.Cost__c / mo.Quantity__c);
        }

        // Duration series for average
        if (mo.End_Date__c != null) {
            monthDurationMap.get(key).add(mo.StartDate__c.date().daysBetween(mo.End_Date__c.date()));
        }

        // Delay series
        if (mo.End_Date__c != null && mo.ExpectedDate__c != null) {
            monthDelayMap.get(key).add(mo.ExpectedDate__c.date().daysBetween(mo.End_Date__c.date()));
        }

        // ✅ Build detailed wrapper for this MO (extra fields included)
        MOWrapper moDetail = new MOWrapper(
            (String)mo.Id,
            mo.Name,
            mo.StartDate__c,
            mo.End_Date__c,
            mo.Cost__c,
            mo.Duration__c,
            (String)mo.Product__c,
            mo.Product__r != null ? mo.Product__r.Name : null   // ✅ Added

        );

        // Status counts + lists
        monthTotalCount.put(key, monthTotalCount.get(key)+1);

        if (mo.Status__c == 'Complete') {
            monthCompletedCount.put(key, monthCompletedCount.get(key)+1);
            monthCompletedMOs.get(key).add(new IdNameWrapper(mo.Id, mo.Name));
            monthCompletedMODetails.get(key).add(moDetail);   // ✅ add detailed
        }
        if (mo.Status__c == 'In Progress') {
            monthInProgressCount.put(key, monthInProgressCount.get(key)+1);
            monthInProgressMOs.get(key).add(new IdNameWrapper(mo.Id, mo.Name));
            monthInProgressMODetails.get(key).add(moDetail);  // ✅ add detailed
        }
        if (mo.Status__c == 'Draft') {
            monthDraftCount.put(key, monthDraftCount.get(key)+1);
            monthDraftMOs.get(key).add(new IdNameWrapper(mo.Id, mo.Name));
            monthDraftMODetails.get(key).add(moDetail);       // ✅ add detailed
        }
        if (mo.Status__c == 'Cancelled') {
            monthCancelledCount.put(key, monthCancelledCount.get(key)+1);
            monthCancelledMOs.get(key).add(new IdNameWrapper(mo.Id, mo.Name));
            monthCancelledMODetails.get(key).add(moDetail);   // ✅ add detailed
        }
        if (mo.Status__c == 'Release') {
            monthReleaseCount.put(key, monthReleaseCount.get(key)+1);
            monthReleaseMOs.get(key).add(new IdNameWrapper(mo.Id, mo.Name));
            monthReleaseMODetails.get(key).add(moDetail);     // ✅ add detailed
        }
    }

    List<MonthlyPriceDTO> dataList = new List<MonthlyPriceDTO>();

    for (String key : monthUnitCostMap.keySet()) {
        List<Decimal> unitCosts = monthUnitCostMap.get(key);
        List<Decimal> durations = monthDurationMap.get(key);
        List<Decimal> delays    = monthDelayMap.get(key);

        Decimal avgCost = 0, minCost = 0, maxCost = 0;
        if (!unitCosts.isEmpty()) {
            minCost = maxCost = unitCosts[0];
            Decimal totalCost = 0;
            for (Decimal c : unitCosts) {
                totalCost += c;
                if (c < minCost) minCost = c;
                if (c > maxCost) maxCost = c;
            }
            avgCost = totalCost / unitCosts.size();
        }

        Decimal totalDuration = 0;
        for (Decimal d : durations) totalDuration += d;
        Decimal avgDuration = !durations.isEmpty() ? totalDuration / durations.size() : 0;

        Decimal totalDelay = 0;
        for (Decimal d2 : delays) totalDelay += d2;
        Decimal avgDelay = !delays.isEmpty() ? totalDelay / delays.size() : 0;

        Integer yr = Integer.valueOf(key.split('-')[0]);
        Integer mn = Integer.valueOf(key.split('-')[1]);

        MonthlyPriceDTO dto = new MonthlyPriceDTO(yr, mn, avgCost, minCost, maxCost);
        dto.avgDuration    = avgDuration;
        dto.avgDelay       = avgDelay;
        dto.totalCount     = monthTotalCount.get(key);
        dto.completedCount = monthCompletedCount.get(key);
        dto.inProgressCount= monthInProgressCount.get(key);
        dto.draftCount     = monthDraftCount.get(key);
        dto.cancelledCount = monthCancelledCount.get(key);
        dto.releaseCount   = monthReleaseCount.get(key);

        // existing Id+Name lists
        dto.completeMOList    = monthCompletedMOs.get(key);
        dto.inProgressMOList  = monthInProgressMOs.get(key);
        dto.draftMOList       = monthDraftMOs.get(key);
        dto.cancelledMOList   = monthCancelledMOs.get(key);
        dto.releaseMOList     = monthReleaseMOs.get(key);

        // ✅ attach detailed lists
        dto.completeMODetails    = monthCompletedMODetails.get(key);
        dto.inProgressMODetails  = monthInProgressMODetails.get(key);
        dto.draftMODetails       = monthDraftMODetails.get(key);
        dto.cancelledMODetails   = monthCancelledMODetails.get(key);
        dto.releaseMODetails     = monthReleaseMODetails.get(key);

        dataList.add(dto);
    }

    dataList.sort();
    return dataList;
}

// ---------------------- DTOs (siblings) ----------------------
public class IdNameWrapper {
    @AuraEnabled public String Id   { get; set; }
    @AuraEnabled public String Name { get; set; }
    public IdNameWrapper(String id, String name) {
        this.Id = id; this.Name = name;
    }
}

// ✅ NEW: Detailed MO wrapper exposing requested fields
public class MOWrapper {
    @AuraEnabled public String    Id        { get; set; }
    @AuraEnabled public String    Name      { get; set; }
    @AuraEnabled public Datetime  startDate { get; set; }   
    @AuraEnabled public Datetime  endDate   { get; set; }   
    @AuraEnabled public Decimal   cost      { get; set; }   
    @AuraEnabled public Decimal   duration  { get; set; }   
    @AuraEnabled public String    productId { get; set; }   
    @AuraEnabled public String    productName { get; set; }   


    public MOWrapper(String id, String name, Datetime startDt, Datetime endDt,
                     Decimal costAmt, Decimal dur, String prodId, String prodName) {
        this.Id = id;
        this.Name = name;
        this.startDate = startDt;
        this.endDate = endDt;
        this.cost = costAmt;
        this.duration = dur;
        this.productId = prodId;
        this.productName = prodName;

    }
}

public class MonthlyPriceDTO implements Comparable {
    @AuraEnabled public Integer year  { get; set; }
    @AuraEnabled public Integer month { get; set; }
    @AuraEnabled public Decimal avgPrice { get; set; }
    @AuraEnabled public Decimal minPrice { get; set; }
    @AuraEnabled public Decimal maxPrice { get; set; }

    @AuraEnabled public Decimal avgDuration { get; set; }
    @AuraEnabled public Decimal avgDelay    { get; set; }
    @AuraEnabled public Integer totalCount { get; set; }
    @AuraEnabled public Integer completedCount { get; set; }
    @AuraEnabled public Integer inProgressCount { get; set; }
    @AuraEnabled public Integer draftCount { get; set; }
    @AuraEnabled public Integer cancelledCount { get; set; }
    @AuraEnabled public Integer releaseCount { get; set; }

 

    // MO lists per status (Id + Name)
    @AuraEnabled public List<IdNameWrapper> completeMOList   { get; set; }
    @AuraEnabled public List<IdNameWrapper> inProgressMOList { get; set; }
    @AuraEnabled public List<IdNameWrapper> draftMOList      { get; set; }
    @AuraEnabled public List<IdNameWrapper> cancelledMOList  { get; set; }
    @AuraEnabled public List<IdNameWrapper> releaseMOList    { get; set; }

    // ✅ NEW: Detailed MO lists per status
    @AuraEnabled public List<MOWrapper> completeMODetails   { get; set; }
    @AuraEnabled public List<MOWrapper> inProgressMODetails { get; set; }
    @AuraEnabled public List<MOWrapper> draftMODetails      { get; set; }
    @AuraEnabled public List<MOWrapper> cancelledMODetails  { get; set; }
    @AuraEnabled public List<MOWrapper> releaseMODetails    { get; set; }
    public List<String> moNames { get; set; } 

      // --- PO Status Lists ---
@AuraEnabled public List<POWrapper> poDraftList { get; set; }
@AuraEnabled public List<POWrapper> poLoggedList { get; set; }
@AuraEnabled public List<POWrapper> poAssignedList { get; set; }
@AuraEnabled public List<POWrapper> poApprovedList { get; set; }
@AuraEnabled public List<POWrapper> poRejectedList { get; set; }
@AuraEnabled public List<POWrapper> poInProgressList { get; set; }
@AuraEnabled public List<POWrapper> poBookedList { get; set; }
@AuraEnabled public List<POWrapper> poClosedList { get; set; }
@AuraEnabled public List<POWrapper> poCancelledList { get; set; }
@AuraEnabled public List<POWrapper> poSupplierAcceptedList { get; set; }
@AuraEnabled public List<POWrapper> poReconciledList { get; set; }
@AuraEnabled public List<POWrapper> poSubmittedForApprovalList { get; set; }
@AuraEnabled public List<POWrapper> poOnHoldList { get; set; }
    @AuraEnabled public Integer totalPOCount { get; set; }    


    // ---- SALES ORDER FIELDS (NEW) ----
@AuraEnabled public Integer totalSOCount        { get; set; }
@AuraEnabled public Integer soDraftCount        { get; set; }
@AuraEnabled public Integer soEnteredCount      { get; set; }
@AuraEnabled public Integer soActivatedCount    { get; set; }
@AuraEnabled public Integer soPickedUpCount     { get; set; }
@AuraEnabled public Integer soPartShippedCount  { get; set; }
@AuraEnabled public Integer soShippedCount      { get; set; }
@AuraEnabled public Integer soDeliveredCount    { get; set; }
@AuraEnabled public Integer soCancelledCount    { get; set; }

@AuraEnabled public List<SOWrapper> soDraftList            { get; set; }
@AuraEnabled public List<SOWrapper> soEnteredList          { get; set; }
@AuraEnabled public List<SOWrapper> soActivatedList        { get; set; }
@AuraEnabled public List<SOWrapper> soPickedUpList         { get; set; }
@AuraEnabled public List<SOWrapper> soPartiallyShippedList { get; set; }
@AuraEnabled public List<SOWrapper> soShippedList          { get; set; }
@AuraEnabled public List<SOWrapper> soDeliveredList        { get; set; }
@AuraEnabled public List<SOWrapper> soCancelledList        { get; set; }



    public MonthlyPriceDTO(Integer y, Integer m, Decimal avgP, Decimal minP, Decimal maxP) {
        year = y; month = m;
        avgPrice = avgP; minPrice = minP; maxPrice = maxP;
                totalPOCount = 0;


        completeMOList   = new List<IdNameWrapper>();
        inProgressMOList = new List<IdNameWrapper>();
        draftMOList      = new List<IdNameWrapper>();
        cancelledMOList  = new List<IdNameWrapper>();
        releaseMOList    = new List<IdNameWrapper>();

        // init detailed lists
        completeMODetails   = new List<MOWrapper>();
        inProgressMODetails = new List<MOWrapper>();
        draftMODetails      = new List<MOWrapper>();
        cancelledMODetails  = new List<MOWrapper>();
        releaseMODetails    = new List<MOWrapper>();

        moNames = new List<String>();
    }

    public Integer compareTo(Object otherObj) {
        MonthlyPriceDTO other = (MonthlyPriceDTO)otherObj;
        if (this.year != other.year) return this.year - other.year;
        return this.month - other.month;
    }

    public void initPOStatusLists() {
    poDraftList = new List<POWrapper>();
    poLoggedList = new List<POWrapper>();
    poAssignedList = new List<POWrapper>();
    poApprovedList = new List<POWrapper>();
    poRejectedList = new List<POWrapper>();
    poInProgressList = new List<POWrapper>();
    poBookedList = new List<POWrapper>();
    poClosedList = new List<POWrapper>();
    poCancelledList = new List<POWrapper>();
    poSupplierAcceptedList = new List<POWrapper>();
    poReconciledList = new List<POWrapper>();
    poSubmittedForApprovalList = new List<POWrapper>();
    poOnHoldList = new List<POWrapper>();
}
}
}