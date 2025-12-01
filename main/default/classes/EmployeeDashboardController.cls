public with sharing class EmployeeDashboardController {

    @AuraEnabled
    public static void processApprovalAction(Id recordId, String action, String objectType, String comment) {
        // IMPORTANT: Implement your actual approval/rejection logic here.
        // This is a placeholder. You'll need to query the record, update its status,
        // and potentially use Apex Approval Processes if your system relies on them.

        System.debug('Processing approval action: ' + action + ' for ' + objectType + ' with ID: ' + recordId);

        try {
            if (objectType == 'LeaveRequest') {
                Leave_Request__c lr = [SELECT Id, Status__c FROM Leave_Request__c WHERE Id = :recordId LIMIT 1];
                if (lr != null) {
                    lr.Status__c = (action == 'Approve') ? 'Approved' : 'Rejected'; // Adjust field and values as per your Leave Request object
                    // update lr;
                    List<SObject> safelr = FLSHelper.getSafeRecords(
    new List<SObject>{lr}, // record if the items are just list
    'Leave_Request__c',
    AccessType.UPDATABLE
);
List<Leave_Request__c> typedlr = new List<Leave_Request__c>();
for (SObject s : safelr) {
    typedlr.add((Leave_Request__c)s);
}
if (!typedlr.isEmpty()) {
    update typedlr;
}

                }
            } else if (objectType == 'TimesheetRequest') {
                Timesheet__c ts = [SELECT Id, Status__c FROM Timesheet__c WHERE Id = :recordId LIMIT 1];
                if (ts != null) {
                    ts.Status__c = (action == 'Approve') ? 'Approved' : 'Rejected'; // Adjust field and values as per your Timesheet object
                    // update ts;
                    List<SObject> safets = FLSHelper.getSafeRecords(
    new List<SObject>{ts}, // record if the items are just list
    'Timesheet__c',
    AccessType.UPDATABLE
);
List<Timesheet__c> typedts = new List<Timesheet__c>();
for (SObject s : safets) {
    typedts.add((Timesheet__c)s);
}
if (!typedts.isEmpty()) {
    update typedts;
}

                }
            }
            // Add more else if blocks for other object types that support approve/reject
            // else if (objectType == 'Expense') { ... }

        } catch (Exception e) {
            // It's crucial to handle exceptions and throw them back to LWC
            throw new AuraHandledException('Error processing ' + objectType + ' ' + action + ': ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<AbsenceWrapper> getCurrentAbsences(String filterByLeaveType) {
        List<AbsenceWrapper> absences = new List<AbsenceWrapper>();
        Date today = Date.today();
        Date prevdate= today.addDays(30); // 30 days ago

        String query = 'SELECT Id, Name, Employee__c, Employee__r.Name,Employee__r.Employee_User__r.SmallPhotoUrl ,';
        query += 'Leave_Start_Date__c, Leave_End_Date__c, Number_of_Days__c, Leave_Type__c ';
        query += 'FROM Leave_Request__c ';
        query += 'WHERE Status__c = \'Approved\' ';
        query += 'AND Leave_End_Date__c >= :today ';
        query += 'AND Leave_Start_Date__c <= :today ';

        if (String.isNotBlank(filterByLeaveType) && filterByLeaveType != 'All') {
            query += 'AND Leave_Type__c = :filterByLeaveType ';
        }

        query += 'ORDER BY Leave_End_Date__c ASC, Leave_Start_Date__c ASC ';
        query += 'LIMIT 10';

        List<Leave_Request__c> leaveRequests = Database.query(query);

        for (Leave_Request__c lr : leaveRequests) {
            String employeeName = lr.Employee__r.Name;
            Id employeeId = lr.Employee__c;
            Date startDate = lr.Leave_Start_Date__c;
            Date endDate = lr.Leave_End_Date__c;
            Integer totalDays = 0;
            if (lr.Number_of_Days__c != null) {
                totalDays = Integer.valueOf(lr.Number_of_Days__c);
            } else {
                 totalDays = calculateTotalAbsenceDays(startDate, endDate);
            }

            absences.add(new AbsenceWrapper(
                lr.Id,
                employeeId,
                employeeName,
                totalDays,
                getReturnDateLabel(today, endDate),
                lr.Employee__r.Employee_User__r.SmallPhotoUrl != null ? lr.Employee__r.Employee_User__r.SmallPhotoUrl : 'https://www.lightningdesignsystem.com/assets/images/avatar1.jpg' // Default avatar
            ));
        }

        return absences;
    }

    // REMOVED: getLeaveTypes() method is no longer here.

    private static Integer calculateTotalAbsenceDays(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            return 0;
        }
        Integer totalDays = startDate.daysBetween(endDate) + 1;
        return totalDays > 0 ? Integer.valueOf(Math.round(totalDays)) : 0;
    }

    private static String getReturnDateLabel(Date today, Date endDate) {
        if (endDate == null) {
            return 'Date N/A';
        }

        Integer daysUntilReturn = today.daysBetween(endDate);

        if (daysUntilReturn == 0) {
            return 'Back today';
        } else if (daysUntilReturn == 1) {
            return 'Back tomorrow';
        } else if (daysUntilReturn > 1) {
            return 'Back in ' + daysUntilReturn + ' days';
        } else {
            return 'Already back';
        }
    }

    public class AbsenceWrapper {
        @AuraEnabled public Id leaveRequestId;
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public Integer totalAbsenceDays;
        @AuraEnabled public String returnDateLabel;
        @AuraEnabled public String employeePhotoUrl;

        public AbsenceWrapper(Id lrId, Id empId, String empName, Integer days, String returnLabel, String empPhotoUrl) {
            this.leaveRequestId = lrId;
            this.employeeId = empId;
            this.employeeName = empName;
            this.totalAbsenceDays = days;
            this.returnDateLabel = returnLabel;
            this.employeePhotoUrl = empPhotoUrl; // Default avatar
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<NotificationWrapper>> getNotificationsData() {
        Map<String, List<NotificationWrapper>> notificationMap = new Map<String, List<NotificationWrapper>>();
        notificationMap.put('Inbox', new List<NotificationWrapper>());
        notificationMap.put('Request', new List<NotificationWrapper>());
        notificationMap.put('Completed', new List<NotificationWrapper>());

        String currentUserId = UserInfo.getUserId();

        // --- Fetch Pending Requests (for 'Request' tab) ---

        // 1. Pending Leave Requests (User is the Approver)
        for (Leave_Request__c lr : [
            SELECT Id, Name, Employee__c, Employee__r.Name, Leave_Start_Date__c, Leave_End_Date__c,
                   Number_of_Days__c, Status__c, Leave_Type__c, Approver__c, LastModifiedDate
            FROM Leave_Request__c
            WHERE Status__c = 'Submitted' AND Approver__r.Employee_User__c = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 20 // Limit per request type for dashboard display
        ]) {
            notificationMap.get('Request').add(new NotificationWrapper(
                lr.Id,
                lr.Employee__r.Name,
                'Absence Request',
                lr.Leave_Type__c + ' (' + (lr.Number_of_Days__c != null ? lr.Number_of_Days__c + ' days' : '') + ')',
                lr.Leave_Start_Date__c + ' - ' + lr.Leave_End_Date__c,
                'Pending',
                'LeaveRequest',
                0, // Placeholder for comment count
                lr.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }

        // 2. Pending Timesheet Requests (User is the Approver)
        for (Timesheet__c ts : [
            SELECT Id, Name, Employees__c, Employees__r.Name, Status__c, From_Date__c, To_Date__c, Approver__c,LastModifiedDate
            FROM Timesheet__c
            WHERE Status__c = 'Submitted' AND Approver__c = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ]) {
            notificationMap.get('Request').add(new NotificationWrapper(
                ts.Id,
                ts.Employees__r.Name,
                'Timesheet Request',
                'Period: ' + ts.From_Date__c + ' to ' + ts.To_Date__c,
                '', // No sub-detail for timesheet for now
                'Pending',
                'TimesheetRequest',
                0,
                ts.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }

        // 3. Pending Review Requests (User is the reviewer)
        for (Review__c er : [
            SELECT Id, Name, Employees__c, Employees__r.Name, Review_Type__c,Start_Date__c, Target_Completion_Date__c, Status__c, ReviewManager__c, ReviewManager__r.Employee_User__c, LastModifiedDate
            FROM Review__c
            WHERE Status__c IN ('Pending', 'Submitted To Manager') AND ReviewManager__r.Employee_User__c = :currentUserId
            ORDER BY Target_Completion_Date__c ASC
            LIMIT 20
        ]) {
            notificationMap.get('Request').add(new NotificationWrapper(
                er.Id,
                er.Employees__r.Name,
                'Review Request',
                er.Review_Type__c + ' Due: ' + er.Target_Completion_Date__c.format(),
                '',
                'Pending',//er.Status__c, // Use actual status for badge
                'ReviewRequest',
                0,
                er.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }

        // 4. Pending Expense Requests (User is the Approver)
      /*  for (Expense__c exp : [
            SELECT Id, Name, Submitted_By__r.Name, Amount__c, CurrencyIsoCode,
                   Description__c, Status__c, Approver__c
            FROM Expense__c
            WHERE Status__c = 'Pending Approval' AND Approver__c = :currentUserId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ]) {
            notificationMap.get('Request').add(new NotificationWrapper(
                exp.Id,
                exp.Submitted_By__r.Name,
                'Expense',
                exp.Amount__c != null ? exp.Amount__c.setScale(2) + ' ' + (exp.CurrencyIsoCode != null ? String.valueOf(exp.CurrencyIsoCode) : '') : '',
                exp.Description__c,
                'Pending',
                'Expense',
                1 // Placeholder for comment count
            ));
        }*/

        // Sort 'Request' notifications by created date or urgency if desired
        notificationMap.get('Request').sort(new NotificationDateComparator());


        // --- Fetch Inbox Notifications (Reward Redemptions) ---

        // Fetch recent Reward Redemptions (e.g., last 30 days) for all employees for general knowledge
        // (This would appear in everyone's inbox, or filtered by department/manager if you add more logic)
        for (Reward_Redemption_Item__c rr : [
            SELECT Id, Name, Employee__r.Name, Total_Points_for_Item__c, Date_Redeemed__c
            FROM Reward_Redemption_Item__c
            WHERE Date_Redeemed__c = LAST_N_DAYS:30
            ORDER BY Date_Redeemed__c DESC
            LIMIT 20 // Limit for inbox display
        ]) {
            // Decision: To show this to ALL employees or only relevant parties?
            // For general transparency/engagement, showing to all in "Inbox" is acceptable.
            // For specific manager/HR oversight, add WHERE clauses (e.g., Employee__r.ManagerId = :currentUserId)
            notificationMap.get('Inbox').add(new NotificationWrapper(
                rr.Id,
                rr.Employee__r.Name,
                'Reward Redeemed',
                rr.Name + ' (' + rr.Total_Points_for_Item__c + ' Points)',
                'Redeemed on ' + rr.Date_Redeemed__c.format(),
                'Redeemed', // Status for badge
                'RewardRedemption',
                0,
                rr.Date_Redeemed__c
            ));
        }
        
        // --- Fetch Completed Notifications ---
        // (Add SOQL queries for approved/rejected leave/timesheet/expense/review requests or acknowledged announcements)
        // Example: Fetch approved/rejected leave requests for the current user
        for (Leave_Request__c lr : [
            SELECT Id, Name, Employee__c, Employee__r.Employee_User__c, Employee__r.Name, Leave_Start_Date__c, Leave_End_Date__c,
                   Number_of_Days__c, Status__c, Leave_Type__c, Approver__c, LastModifiedDate
            FROM Leave_Request__c
            WHERE Status__c IN ('Approved', 'Rejected', 'Cancelled') AND Approver__r.Employee_User__c = :currentUserId And Approved_Date__c != NULL And Approved_Date__c > LAST_N_DAYS:15
            ORDER BY LastModifiedDate DESC
            LIMIT 10
        ]) {
            notificationMap.get('Completed').add(new NotificationWrapper(
                lr.Id,
                lr.Leave_Type__c + ' Request',
                'Absence Request',
                'For ' + lr.Leave_Start_Date__c + ' to ' + lr.Leave_End_Date__c,
                '',
                lr.Status__c,
                'LeaveRequestArchived',
                0,
                lr.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }
        for (Timesheet__c ts : [
            SELECT Id, Name, Employees__c, Employees__r.Name, Status__c, From_Date__c, To_Date__c, Approver__c,LastModifiedDate
            FROM Timesheet__c
            WHERE Status__c IN ('Approved', 'Rejected', 'Cancelled') AND Approver__c = :currentUserId And Approve_Rejected_Date__c != NULL And Approve_Rejected_Date__c > LAST_N_DAYS:15
            ORDER BY CreatedDate DESC
            LIMIT 20
        ]) {
            notificationMap.get('Completed').add(new NotificationWrapper(
                ts.Id,
                ts.Employees__r.Name,
                'Timesheet Request',
                'Period: ' + ts.From_Date__c + ' to ' + ts.To_Date__c,
                '', // No sub-detail for timesheet for now
                ts.Status__c,
                'TimesheetRequestArchieved',
                0,
                ts.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }

        // 3. Pending Review Requests (User is the reviewer)
        for (Review__c er : [
            SELECT Id, Name, Employees__c, Employees__r.Name, Review_Type__c,Start_Date__c, Target_Completion_Date__c, Status__c, ReviewManager__c, ReviewManager__r.Employee_User__c, LastModifiedDate
            FROM Review__c
        WHERE Status__c = 'Signed Off' AND ReviewManager__r.Employee_User__c = :currentUserId And Date_Signed_Off__c != NULL And Date_Signed_Off__c > LAST_N_DAYS:15
            ORDER BY Target_Completion_Date__c ASC
            LIMIT 20
        ]) {
            notificationMap.get('Completed').add(new NotificationWrapper(
                er.Id,
                er.Employees__r.Name,
                'Review Request',
                er.Review_Type__c + ' Due: ' + er.Target_Completion_Date__c.format(),
                '',
                er.Status__c, // Use actual status for badge
                'ReviewRequestArchieved',
                0,
                er.LastModifiedDate // Use LastModifiedDate for sorting
            ));
        }
        notificationMap.get('Completed').sort(new NotificationDateComparator());


        return notificationMap;
    }

    // Wrapper class to return structured notification data
    public class NotificationWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String primaryPersonName; // Guy Hawkins, Wade Warren, Employee who redeemed
        @AuraEnabled public String notificationType; // Absence Request, Expense, Timesheet, Review, Reward Redeemed
        @AuraEnabled public String mainDetail;       // Vacation (2 days), 6.500 Euros, Reward name (Points)
        @AuraEnabled public String subDetail;        // Dates, Description, Redemption date
        @AuraEnabled public String statusBadge;      // Pending, Redeemed, Approved, Rejected
        @AuraEnabled public String actionType;       // 'LeaveRequest', 'Expense', 'TimesheetRequest', 'ReviewRequest', 'RewardRedemption'
        @AuraEnabled public Integer commentCount;     // (0), (1)
        @AuraEnabled public DateTime createdDate; // Optional: If you want to show when the notification was created

        public NotificationWrapper(Id rId, String pName, String nType, String mDetail, String sDetail, String sBadge, String aType, Integer cCount, DateTime createdDate) {
            this.recordId = rId;
            this.primaryPersonName = pName;
            this.notificationType = nType;
            this.mainDetail = mDetail;
            this.subDetail = sDetail;
            this.statusBadge = sBadge;
            this.actionType = aType;
            this.commentCount = cCount;
            this.createdDate = createdDate; // Default to today if not provided
        }
    }

    // Comparator class to sort notifications by date (e.g., CreatedDate)
    public class NotificationDateComparator implements Comparator<NotificationWrapper> {
        public Integer compare(NotificationWrapper n1, NotificationWrapper n2) {
            // This requires the wrapper to store a date for sorting,
            // or you sort the SOQL results directly.
            // For simplicity, if sorting by CreatedDate, it's better done in SOQL.
            // If you need complex custom sorting logic in Apex, you'd add date fields to wrapper.
            if (n1.createdDate == null && n2.createdDate == null) {
                return 0; // Both are null, consider them equal
            } else if(n1.createdDate > n2.createdDate) {
                return 1; // n1 is after n2
            } else if(n1.createdDate < n2.createdDate) {
                return -1; // n1 is before n2

            }
            return 0; // Return 0 if equal, -1 if n1 < n2, 1 if n1 > n2
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<NewJoinerWrapper> getNewJoiners(String periodType) {
        Date today = Date.today();
        Date startDateFilter;
        if (periodType == 'ThisMonth') {
            startDateFilter = today.toStartOfMonth();
        } else if (periodType == 'ThisQuarter') {
            Integer currentMonth = today.month();
            Integer currentYear = today.year();
            
            // Determine the start month of the current quarter
            Integer quarterStartMonth;
            if (currentMonth >= 1 && currentMonth <= 3) { // Q1 (Jan-Mar)
                quarterStartMonth = 1;
            } else if (currentMonth >= 4 && currentMonth <= 6) { // Q2 (Apr-Jun)
                quarterStartMonth = 4;
            } else if (currentMonth >= 7 && currentMonth <= 9) { // Q3 (Jul-Sep)
                quarterStartMonth = 7;
            } else { // Q4 (Oct-Dec)
                quarterStartMonth = 10;
            }
            startDateFilter = Date.newInstance(currentYear, quarterStartMonth, 1);
        } else if (periodType == 'ThisYear') {
            startDateFilter = Date.newInstance(today.year(), 1, 1); // January 1st of current year
        } else {
            // Default to 'ThisMonth' or a reasonable default if no valid periodType is given
            // Or, consider 'All' to show all new joiners (could be performance intensive)
            // For dashboard card, a recent period is usually best.
            startDateFilter = today.toStartOfMonth(); // Defaulting to this month
            System.debug('Invalid periodType provided, defaulting to ThisMonth: ' + periodType);
        }

      /*  if (periodInDays == null || periodInDays <= 0) {
            periodInDays = 90; // Default to last 90 days if not specified
        }
        Date joinDateThreshold = Date.today().addDays(-periodInDays);*/

        String query = 'SELECT Id, Name, Employment_Start_Date__c, Employee_User__r.SmallPhotoUrl ';
        query += 'FROM Employees__c ';
        query += 'WHERE Employment_Start_Date__c >= :startDateFilter And Employee_User__c != null And Progress__c= \'Completed\'  And Employee_Status__c= \'On boarding\''; // Ensure we only fetch employees with a user linked
        // Add department filter if provided
       /* if (String.isNotBlank(filterByDepartment) && filterByDepartment != 'All') {
           // query += 'AND Department__c = :filterByDepartment ';
        }*/

        query += 'ORDER BY Employment_Start_Date__c DESC '; // Most recent joiners first
        query += 'LIMIT 10'; // Limit to display top N joiners in the card

        List<Employees__c> newJoinerRecords = Database.query(query);

        List<NewJoinerWrapper> newJoinerData = new List<NewJoinerWrapper>();
        for (Employees__c emp : newJoinerRecords) {
            newJoinerData.add(new NewJoinerWrapper(
                emp.Id,
                emp.Name,
                emp.Employment_Start_Date__c,
                //emp.Department__c,
                emp.Employee_User__r.SmallPhotoUrl != null ? emp.Employee_User__r.SmallPhotoUrl : 'https://www.lightningdesignsystem.com/assets/images/avatar1.jpg' // Default avatar
            ));
        }

        return newJoinerData;
    }


    // Wrapper class to return structured data to LWC
    public class NewJoinerWrapper {
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public Date joinDate;
       // @AuraEnabled public String department;
        @AuraEnabled public String employeePhotoUrl;

        public NewJoinerWrapper(Id empId, String empName, Date jDate, String photoUrl) {//String dept,
            this.employeeId = empId;
            this.employeeName = empName;
            this.joinDate = jDate;
           // this.department = dept;
            this.employeePhotoUrl = photoUrl;
        }
    }

   /* @AuraEnabled(cacheable=true)
    public static List<RetentionDataPoint> getEmployeeRetentionTrend(Integer months) {
        List<RetentionDataPoint> dataPoints = new List<RetentionDataPoint>();
        Date today = Date.today();

        // --- DUMMY DATA FOR DEMONSTRATION ---
        // In a real scenario, you would query historical data
        // from custom objects that track employee counts, hires, and terminations.
        // For example, a custom object like Monthly_HR_Metrics__c with fields:
        // Month_Year__c (Date), Start_Count__c (Number), End_Count__c (Number), Hires__c (Number), Terminations__c (Number)
        // And then calculate: (End_Count__c - Hires__c) / Start_Count__c * 100 or similar
        // Or simply net change: End_Count__c - Start_Count__c

        // Generate dummy data for the last 'months' period
        for (Integer i = months - 1; i >= 0; i--) {
            Date monthDate = today.addMonths(-i);
            DateTime monthDateTime = DateTime.newInstance(monthDate.year(), monthDate.month(), 1, 0, 0, 0);
            String monthLabel = monthDateTime.format('MMM'); // e.g., 'Jan', 'Feb'

            // Generating fluctuating dummy values
            Integer value;
            if (i == months - 1) value = -65; // Start value
            else if (i == months - 2) value = -25;
            else if (i == months - 3) value = -65;
            else if (i == months - 4) value = 55;
            else if (i == months - 5) value = -5;
            else if (i == months - 6) value = 20;
            else value = Math.round(Math.random() * 120) - 60; // Random values between -60 and 60

            dataPoints.add(new RetentionDataPoint(monthLabel, value));
        }
        // --- END DUMMY DATA ---

        return dataPoints;
    }*/
   
    @AuraEnabled(cacheable=true)
    public static List<RetentionDataPoint> getEmployeeRetentionTrend(Integer months) {
        List<RetentionDataPoint> dataPoints = new List<RetentionDataPoint>();

        // Input validation for 'months'
        if (months == null || months <= 0) {
            months = 6; // Default to 6 months if invalid
        }
        if (months > 24) { // Cap at 24 months for reasonable performance/data volume
            months = 24;
        }

        Date today = Date.today();
        // Calculate the start of the *first month* we want to display data for.
        // This will be the (months - 1)th month ago.
        Date firstChartMonthStart = today.addMonths(-(months - 1)).toStartOfMonth();
        
        // Oldest date needed for querying employees who started before the chart period
        Date queryOldestDate = today.addMonths(-months).toStartOfMonth(); 
        
        // --- Step 1: Fetch all relevant employee start and end dates in one query ---
        List<Employees__c> relevantEmployees = [
            SELECT Id, Name, Employment_Start_Date__c, Employment_End_Date__c
            FROM Employees__c
            WHERE (Employment_Start_Date__c >= :queryOldestDate AND Employment_Start_Date__c <= :today And Employee_User__c!=null)
            OR (Employment_End_Date__c >= :queryOldestDate AND Employment_End_Date__c <= :today And Employee_User__c!=null)
            OR (Employee_User__c!=null And Employment_Start_Date__c < :queryOldestDate AND (Employment_End_Date__c = NULL OR Employment_End_Date__c > :queryOldestDate))
            ALL ROWS // Include deleted/archived records if needed, otherwise omit
        ];

        // --- Step 2: Initialize monthly counts for starts and ends within the period ---
        Map<Date, Integer> monthlyStarts = new Map<Date, Integer>();
        Map<Date, Integer> monthlyEnds = new Map<Date, Integer>();
        
        // Initialize maps for all months within the requested period (from oldest to today's month)
        for (Integer i = 0; i < months; i++) {
            Date monthStart = today.addMonths(-i).toStartOfMonth();
            monthlyStarts.put(monthStart, 0);
            monthlyEnds.put(monthStart, 0);
        }

        // --- Step 3: Populate monthly starts and ends from queried employees ---
        for (Employees__c emp : relevantEmployees) {
            if (emp.Employment_Start_Date__c != null) {
                Date startMonth = emp.Employment_Start_Date__c.toStartOfMonth();
                if (monthlyStarts.containsKey(startMonth)) {
                    monthlyStarts.put(startMonth, monthlyStarts.get(startMonth) + 1);
                }
            }
            if (emp.Employment_End_Date__c != null) {
                Date endMonth = emp.Employment_End_Date__c.toStartOfMonth();
                if (monthlyEnds.containsKey(endMonth)) {
                    monthlyEnds.put(endMonth, monthlyEnds.get(endMonth) + 1);
                }
            }
        }

        // --- Step 4: Calculate active employee count at the *start of the first chart month* ---
        // This is the base count from which we will cumulatively add/subtract
        Integer activeCountAtStartOfPeriod = [
            SELECT COUNT()
            FROM Employees__c
            WHERE Employment_Start_Date__c < :firstChartMonthStart
            AND (Employment_End_Date__c = NULL OR Employment_End_Date__c >= :firstChartMonthStart) // >= :firstChartMonthStart to include those who leave on the exact start date
            ALL ROWS
        ];
        
        // Initialize the running count for the chart
        Integer currentCumulativeCount = activeCountAtStartOfPeriod;


        // --- Step 5: Iterate through months (from oldest to current) to build the cumulative trend ---
        for (Integer i = months - 1; i >= 0; i--) {
            Date monthDate = today.addMonths(-i).toStartOfMonth();
            DateTime dt= DateTime.newInstance(monthDate.year(), monthDate.month(), 1, 0, 0, 0);
            String monthLabel = dt.format('MMM yy');

            Integer startsInMonth = monthlyStarts.get(monthDate);
            Integer endsInMonth = monthlyEnds.get(monthDate);

            // Calculate active count at the end of this specific month
            // This is the (previous month's end count) + starts in this month - ends in this month
            currentCumulativeCount += (startsInMonth - endsInMonth);

            // Add the cumulative active count for this month as a data point
            dataPoints.add(new RetentionDataPoint(monthLabel, currentCumulativeCount));
        }

        return dataPoints;
    }


    public class RetentionDataPoint {
        @AuraEnabled public String label; // e.g., Month name like 'Jan', 'Feb'
        @AuraEnabled public Integer value; // The retention percentage or change
        
        public RetentionDataPoint(String label, Integer value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<OnboardingProgressWrapper> getOnboardingProgress() {
        List<OnboardingProgressWrapper> onboardingData = new List<OnboardingProgressWrapper>();
        Map<Id,List<Actions_Tasks__c>> taskMap = new Map<Id,List<Actions_Tasks__c>>();
        Set<Id> employeeIds = new Set<Id>();

        List<Employees__c> onboardingEmployees = [
            SELECT
                Id,
                Name,
                Employee_User__r.SmallPhotoUrl,Progress__c // Get the small photo URL from the related User record
               // (SELECT Id, Status__c, Process_Type__c FROM Actions_Tasks__r WHERE Process_Type__c = 'On boarding') // Subquery for related onboarding tasks
            FROM
                Employees__c
            WHERE
                Employee_Status__c = 'On boarding' AND Progress__c != 'Completed' AND Employee_User__c!=null// Assuming Progress__c field exists on Employees__c
        ];
        for(Employees__c emp : onboardingEmployees) {
            employeeIds.add(emp.Id);
        }
        List<Actions_Tasks__c> relatedTasks = [
            SELECT
                Id,
                Status__c,
                Process_Type__c,
                Employee__c
            FROM
                Actions_Tasks__c
            WHERE
                Employee__c IN :employeeIds AND Process_Type__c = 'On boarding'
        ];
        for(Actions_Tasks__c task : relatedTasks) {
            if(!taskMap.containsKey(task.Employee__c)) {
                taskMap.put(task.Employee__c, new List<Actions_Tasks__c>());
            } 
            taskMap.get(task.Employee__c).add(task);
        }

        for (Employees__c emp : onboardingEmployees) {
            Integer totalOnboardingTasks = 0;
            Integer completedOnboardingTasks = 0;

            // Iterate through related Actions_Tasks__c
            if (taskMap.get(emp.Id) != null) {
                for (Actions_Tasks__c task : taskMap.get(emp.Id)) {
                    totalOnboardingTasks++; // Count all onboarding tasks
                    if (task.Status__c == 'Completed') { // Check if task is completed
                        completedOnboardingTasks++;
                    }
                }
            }

            Integer progressPercentage = 0;
            if (totalOnboardingTasks > 0) {
                progressPercentage = (completedOnboardingTasks * 100) / totalOnboardingTasks;
            }

            String status = 'Active';
            if (progressPercentage < 50 && totalOnboardingTasks > 0 && completedOnboardingTasks < (totalOnboardingTasks / 2) && completedOnboardingTasks > 0) { 
                 status = 'Warning';
            } else if (totalOnboardingTasks > 0 && completedOnboardingTasks == 0 && progressPercentage == 0) {
                status = 'Warning';
            } else if (totalOnboardingTasks == 0 && emp.Progress__c != 'Completed') {
                status = 'Warning';
            }


            onboardingData.add(new OnboardingProgressWrapper(
                emp.Id,
                emp.Name,
                emp.Employee_User__r.SmallPhotoUrl != null ? emp.Employee_User__r.SmallPhotoUrl : 'https://www.lightningdesignsystem.com/assets/images/avatar1.jpg', // Fallback avatar
                progressPercentage,
                status
            ));
        }

        return onboardingData;
    }

    // Wrapper class to return structured data to LWC
    public class OnboardingProgressWrapper {
        @AuraEnabled public Id employeeId;
        @AuraEnabled public String employeeName;
        @AuraEnabled public String employeePhotoUrl;
        @AuraEnabled public Integer progressPercentage;
        @AuraEnabled public String status; // 'Active', 'Warning'

        public OnboardingProgressWrapper(Id empId, String empName, String photoUrl, Integer progress, String stat) {
            this.employeeId = empId;
            this.employeeName = empName;
            this.employeePhotoUrl = photoUrl;
            this.progressPercentage = progress;
            this.status = stat;
        }
    }

    @AuraEnabled(cacheable=true)
    public static EmployeeInfo getCurrentEmployeeDetails() {
        EmployeeInfo result = new EmployeeInfo();
        String currentUserId = UserInfo.getUserId();

        try {
            Employees__c employeeRecord = [
                SELECT
                    Id,
                    Name, // Name of the Employee record (e.g., John Doe)
                    Employee_User__r.FullPhotoUrl // Photo URL from the related User record
                FROM
                    Employees__c
                WHERE
                    Employee_User__c = :currentUserId
                LIMIT 1
            ];

            result.employeeName = employeeRecord.Name;
            // Use the FullPhotoUrl from the related User record
            result.employeePhotoUrl = employeeRecord.Employee_User__r.FullPhotoUrl;

        } catch (QueryException e) {
            System.debug('No Employees__c record found for current user or other query error: ' + e.getMessage());
            // Fallback to current User's name and photo if Employees__c record not found or error
            // This ensures a greeting even if the custom employee record isn't linked
            User currentUser = [SELECT Name, FullPhotoUrl FROM User WHERE Id = :currentUserId LIMIT 1];
            result.employeeName = currentUser.Name;
            result.employeePhotoUrl = currentUser.FullPhotoUrl;
        } catch (Exception e) {
            System.debug('Unexpected error fetching current employee details: ' + e.getMessage());
            // Generic fallback
            User currentUser = [SELECT Name, FullPhotoUrl FROM User WHERE Id = :currentUserId LIMIT 1];
            result.employeeName = currentUser.Name;
            result.employeePhotoUrl = currentUser.FullPhotoUrl;
        }

        // Provide a default image if FullPhotoUrl is null (e.g., no photo set for the user)
        if (result.employeePhotoUrl == null) {
            result.employeePhotoUrl = 'https://www.lightningdesignsystem.com/assets/images/avatar1.jpg'; // SLDS default avatar
        }

        // Provide a default name if still null (shouldn't happen for active users)
        if (result.employeeName == null) {
            result.employeeName = 'Employee';
        }

        return result;
    }

    // Wrapper class to return multiple values from Apex to LWC
    public class EmployeeInfo {
        @AuraEnabled public String employeeName;
        @AuraEnabled public String employeePhotoUrl;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getQuickAccessBadgeCounts() {
        Map<String, Integer> badgeCounts = new Map<String, Integer>();

        try {
            Integer pendingOnboarding = [SELECT COUNT() FROM Employees__c WHERE Employee_Status__c='On boarding' And Progress__c != 'Completed'];
            badgeCounts.put('Onboarding', pendingOnboarding);
        } catch (QueryException e) {
            System.debug('Error querying Onboarding_Task__c: ' + e.getMessage());
            badgeCounts.put('Onboarding', 0); 
        }

        try {
            Integer pendingTimesheets = [SELECT COUNT() FROM Timesheet__c WHERE Approver__c=:UserInfo.getUserId() And Status__c = 'Pending Approval' And Project__c!=null];
            badgeCounts.put('Timesheets', pendingTimesheets);
        } catch (QueryException e) {
            System.debug('Error querying Timesheet__c: ' + e.getMessage());
            badgeCounts.put('Timesheets', 0); 
        }


        try {
            Integer pendingLeaves = [SELECT COUNT() FROM Leave_Request__c WHERE Approver__r.Employee_User__c=:UserInfo.getUserId() And  Status__c = 'Submitted'];
            badgeCounts.put('LeaveManagement', pendingLeaves);
        } catch (QueryException e) {
            System.debug('Error querying Leave_Request__c: ' + e.getMessage());
            badgeCounts.put('LeaveManagement', 0); 
        }

        try {
            Integer pendingApplications = [SELECT COUNT() FROM Job_Applicant__c WHERE Status__c != 'Offer Accepted' OR Status__c = 'Pending Approval'];
            badgeCounts.put('Recruiting', pendingApplications);
        } catch (QueryException e) {
            System.debug('Error querying Job_Application__c: ' + e.getMessage());
            badgeCounts.put('Recruiting', 0); 
        }

        try {
            Integer pendingReviews = [SELECT COUNT() FROM Review__c WHERE Employees__r.Employee_User__c=:UserInfo.getUserId() And (Status__c = 'Pending Completion' OR Status__c = 'Pending Approval')];
            badgeCounts.put('EmployeeReview', pendingReviews);
        } catch (QueryException e) {
            System.debug('Error querying Employee_Review__c: ' + e.getMessage());
            badgeCounts.put('EmployeeReview', 0); 
        }

        // For 'Employees', a direct 'pending approval' count isn't common.
        // If you need a badge here, consider what it represents (e.g., new hires awaiting welcome kit).
        // For example, if you have a field Is_New_Hire_Pending__c on Employee__c:
        /*
        try {
            Integer pendingNewHires = [SELECT COUNT() FROM Employee__c WHERE Is_New_Hire_Pending__c = TRUE];
            badgeCounts.put('Employees', pendingNewHires);
        } catch (QueryException e) {
            System.debug('Error querying Employee__c for pending new hires: ' + e.getMessage());
            badgeCounts.put('Employees', 0);
        }
        */

        return badgeCounts;
    }
}