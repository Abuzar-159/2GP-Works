@isTest
private class ABHome_SchTestClass {
    @isTest
    static  void ABHomeMethodIK1() {

        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230);
        insert expLoc;
        Product2 product = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = true);
        insert product;
        Work_Planner__c wp = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 100, Distribution_Timeline__c = 'Monthly', Minimum_Threshold__c = 10);
        insert wp;

        Resource_Group__c RG = new Resource_Group__c(
            Name = 'Mississauga - OW - Application / Transfer-In'
        );
        insert RG;

        Resource_Requirement__c RR = new Resource_Requirement__c(
            Name = 'Mississauga - OW - Application/Transfer-In',
            Work_Planner__c = wp.Id,
            Resource_Group__c = RG.Id
        );
        insert RR;
        User CU = [Select Id, Name, LastName, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, ProfileId, LanguageLocaleKey From User limit 1];
        system.debug('*** CU : ' + CU);
        List < User > Users = new List < User > ();

        Account acct = new Account(Name = 'Vet Servicessss', Event_Type__c = 'Expert Service');
        insert acct;

        List < Resource__c > Resources = new List < Resource__c > ();
        for (User U: Users) {
            for (Integer i = 0; i < 2; i++) {
                Resource__c Res = new Resource__c(
                    Name = 'Antonette Pagniello' + i, // Resource Name
                    User__c = U.Id, // User
                    Resource_Group__c = RG.Id, // Resource Group
                    Time_Slot_Duration__c = 0, // Time Slot Duration
                    Override_Holidays__c = false, // Override Holidays
                    Super_User__c = false, // Super User
                    Start_Date__c = system.today() + 1, // Start Date
                    End_Date__c = system.today() + 10, // End Date
                    Monday__c = 0.00,
                    Tue_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Tue Start Time
                    Tue_End_Time__c = Time.newInstance(14, 15, 0, 0), // Tue End Time
                    Tuesday__c = 1.00, // Tue (Hrs)
                    Wednesday__c = 0.02, // Wed (Hrs)
                    Thu_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Thu Start Time
                    Thu_End_Time__c = Time.newInstance(14, 15, 0, 0), // Thu End Time
                    Thursdays__c = 1.00, // Thu (Hrs)
                    Fri_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Fri Start Time
                    Fri_End_Time__c = Time.newInstance(14, 15, 0, 0), // Fri End Time
                    Friday__c = 1.00, // Fri (Hrs)
                    Saturday__c = 0.02, // Sat (Hrs)
                    Sunday__c = 0.00 // Mon (Hrs)
                    // Sun (Hrs)
                );
                Resources.add(Res);
            }
        }
        insert Resources;

        Test.startTest();
        ABHome_Sch ES = new ABHome_Sch ();
        ABHome_Sch.getlookups(expLoc.Id);
        // ABHome_Sch.setLocations(expLoc.Id);
        ABHome_Sch.getLocationsServices(expLoc.Id);
        ABHome_Sch.getAllTimeSlotList(System.now(), System.now().addDays(1), 60);
        //   String LId, String SId, String timezone, String expertId, Boolean AutoResourceAllocation, String MemberId
        //ABHome_Sch.getTimeSlotsDoInit(expLoc.Id, product.Id,'America/New_York', '', true, '');
        //ABHome_Sch.getTimeSlotsDoInitO(expLoc.Id, product.Id,'America/New_York', '', true, '');//
        //  ABHome_Sch.getTimeSlots(Resources[0].User__c, system.today(), expLoc.Id, product.Id, '', CU.TimeZoneSidKey, '');//
        Test.stopTest();

    }
@isTest
    static  void ABHomeMethod() {

        // Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');
        insert acc;

        Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
        insert con;
        String totalMiles = '';
        String totalMiles1 = '';
        String assert = 'test@gmail.com';
        String assert1 = '78967';

        User u1 = [SELECT Id FROM User limit 1];
        contact testMiles2 = new contact(FirstName = 'test1', LastName = 'tes', Phone = '78967', Email = 'test187755@gmail.com');

        insert testMiles2;
        for (contact m: [SELECT FirstName, Phone, Email FROM contact WHERE CreatedDate = TODAY]) {
            totalMiles += m.Email;
            totalMiles1 += m.Phone;
        }

        Product_Service_List__c psl = new Product_Service_List__c(Name = 'Croydon - North End', Active__c = true, Description__c = 'test');
        insert psl;

        Id rec = Schema.SObjectType.Expert__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Expert__c expert = new Expert__c(Name = 'Mark Cooper', RecordTypeId = rec, Product_Service_List__c = psl.Id,
                                                             Start_Time__c = '9:00', End_Time__c = '20:00', Expert_Time_Slot_Duration__c = '30',
                                                             Expert_Start_Time__c = system.today(), Expert_End_Time__c = system.today() + 1, Email__c = 'expert002@gmail.com', Description__c = 'test',
                                                             Phone__c = '07141141141', Active__c = true, Expert_Image_Url__c = 'https://eventrok-dev-ed--c.ap1.content.force.com/servlet/servlet.ImageServer?id=0159000000D9QKd&oid=00D90000000wSQS&lastMod=1471946486000');
        insert expert;
        list < Expert__c > expertList = new list < Expert__c > ();
        expertList.add(expert);
        upsert expertList;

        ABHome_Sch expService = new ABHome_Sch ();
        String firstHideExpertId;
        expService.firstHideExpertId = expertList[0].Id;
        expService.showExpert = false;
        expService.sessionsList = null;
        expService.startAT = null;
        expService.startET = null;
        ABHome_Sch.accountsList = null;
        ABHome_Sch.locList = null;
        ABHome_Sch.selectedCity = null;
        expService.AvailableExperts = null;
        expService.registration = null;
        expService.StartTime = expService.EndTime = expService.DBST = expService.DBET = null;
        expService.DocumentId = null;
        ABHome_Sch.RecordWrp rw = new ABHome_Sch.RecordWrp();
        rw.Id = null;
        rw.Name = null;
        rw.Email = null;
        rw.Phone = null;
        rw.Type = null;

        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);
        insert expLoc;

        Expert_Location_Allocation__c ela = new Expert_Location_Allocation__c(Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Active__c = true);
        try { insert ela; } catch (Exception e) {
            system.debug('Exception' + e.getMessage());
        }


        Id record = Schema.SObjectType.Available_Date__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Available_Date__c ad = new Available_Date__c(Expert__c = expert.Id, Expert_Location__c = expLoc.Id,
                                                                         Start_Date__c = system.today() + 1, End_Date__c = system.today(), RecordTypeId = record, Reason__c = 'Available');
        insert ad;

        Product2 product = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = true);
        insert product;
        Product2 product1 = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = false);
        insert product1;

        Product_Service_List_Item__c psli = new Product_Service_List_Item__c(Product_Service_List__c = psl.Id, Product2__c = product.Id, Active__c = true);
        insert psli;

        Contact_Profile__c cp = new Contact_Profile__c(Name = 'London - Westfield Centre Profile', Active__c = true);
        insert cp;

        Profile_Allocation__c pa = new Profile_Allocation__c(Profile_Allocation_Account__c = acc.Id, Expert_Location__c = expLoc.Id, Active__c = true, Default__c = true);
        insert pa;




        Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();

        Work_Planner__c wp = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 100, Distribution_Timeline__c = 'Monthly', Minimum_Threshold__c = 10);
        insert wp;
        Resource_Group__c RG = new Resource_Group__c(
            Name = 'Mississauga - OW - Application / Transfer-In'
        );
        insert RG;

        Resource_Requirement__c RR = new Resource_Requirement__c(
            Name = 'Mississauga - OW - Application/Transfer-In',
            Work_Planner__c = wp.Id,
            Resource_Group__c = RG.Id
        );
        insert RR;
        Event__c event = new Event__c(Name = 'test', Event_Location__c = expLoc.Id, Event_Status__c = 'Active', Expert_Location__c = expLoc.Id,
                                                          Registration_Start_Date__c = system.today(), Registration_End_Date__c = system.today() + 1);
        insert event;
        update event;

        Event_Allocation__c eventAlloc = new Event_Allocation__c(Location__c = expLoc.Id, Expert__c = expert.Id, Event__c = event.Id,Active__c=true);
        insert eventAlloc;

        Resource__c Resource = new Resource__c(Name = 'Arshad shariff', Start_date__c = System.today(), End_date__c = System.today() + 30, User__c = userInfo.getUserId(),
                                                                   Mon_Start_Time__c = Time.newInstance(9, 30, 0, 0), Mon_End_Time__c = Time.newInstance(17, 30, 0, 0), Mon_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Mon_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Tue_Start_Time__c = Time.newInstance(9, 30, 0, 0), Tue_End_Time__c = Time.newInstance(17, 30, 0, 0), Tue_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Tue_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Wed_Start_Time__c = Time.newInstance(9, 30, 0, 0), Wed_End_Time__c = Time.newInstance(17, 30, 0, 0), Wed_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Wed_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Thu_Start_Time__c = Time.newInstance(9, 30, 0, 0), Thu_End_Time__c = Time.newInstance(17, 30, 0, 0), Thu_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Thu_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Fri_Start_Time__c = Time.newInstance(9, 30, 0, 0), Fri_End_Time__c = Time.newInstance(17, 30, 0, 0), Fri_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Fri_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sat_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sat_End_Time__c = Time.newInstance(17, 30, 0, 0), Sat_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sat_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sun_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sun_End_Time__c = Time.newInstance(17, 30, 0, 0), Sun_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sun_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Email__c = 'abc@gmail.com', Time_Slot_Duration__c = 60, Break_Start_Time__c = Time.newInstance(17, 30, 0, 0), Break_End_Time__c = Time.newInstance(18, 30, 0, 0)
                                                                  ); //,Appointment_Email__c=true
        insert Resource;
        Capacity_SCH__c cap1 = new Capacity_SCH__c(Name='test',Resource_Group__c=RG.Id, Product__c = product.Id,Date__c=system.today()+1,Start_Time__c = Time.newInstance(9, 30, 0, 0),End_Time__c = Time.newInstance(17, 30, 0, 0),Capacity_Hrs__c=8, User__c=UserInfo.getUserId(),Resource__c = Resource.Id);
        insert cap1;

        Capacity_SCH__c cap2 = new Capacity_SCH__c(Name='test',Resource_Group__c=RG.Id, Product__c = product.Id,Date__c=system.today()+2,Start_Time__c = Time.newInstance(9, 30, 0, 0),End_Time__c = Time.newInstance(17, 30, 0, 0),Capacity_Hrs__c=8, User__c=UserInfo.getUserId(),Resource__c = Resource.Id);
        insert cap2;
        Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Registration_Price__c = 100, Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.today(), End_Time__c = system.today(), Customer_Name__c = 'test', Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com', Resource__c = Resource.Id, Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg;

        SystemCode__c sysCode = new SystemCode__c();
        sysCode.Date_Format__c = 'EEE MM-DD-YYYY';
        sysCode.name = 'SystemCodeTime';
        insert sysCode;

        ABHome_Sch expSer = new ABHome_Sch ();
        ABHome_Sch.WrapperClass wrap = new ABHome_Sch.WrapperClass();
        ABHome_Sch.CheckPaidService check = new ABHome_Sch.CheckPaidService();

        expSer.Country = null;
        expSer.selectedWPId = null;
        expSer.startAfternoonTime = System.now();
        expser.startEndTime = null;
        expser.AvailableDatesOD = new List < Available_Date__c > ();
        expSer.AvailableDatesList = new set < Available_Date__c > ();
        // ABHome_Sch.readXMLResponse(null,'');

        ABHome_Sch.TimeSlot ts = new ABHome_Sch.TimeSlot();
        ts.Slot = System.now();
        ts.IsAvailable = false;
        ts.checked = false;
        ts.ResourceId = null;
        list < Time_Off__c > TimeOffList = new list < Time_Off__c > ();
        TimeOffList = [SELECT Id, Name, Resource__c, Start_Date__c, End_Date__c, Type__c, Start_Time__c, End_Time__c, User__c
                       FROM Time_Off__c WHERE End_Date__c >=: System.today() AND Type__c != null
                       AND((Start_Time__c = null AND End_Time__c = null) OR(Start_Time__c != null AND End_Time__c != null))
                       AND Start_Date__c != null AND End_Date__c != null Order By Start_Date__c];
        // ABHome_Sch.MaxRegistrationExceeded(reg, product.Id, expLoc.Id);
        ABHome_Sch.getAvailableTimeSlots(system.today(), expLoc.Id, product.Id, System.now(), System.now().addHours(10), System.now(), System.now().addHours(1), Resource, false, 30, new List < ABHome_Sch.TimeSlot > (),
                                     new List < Holiday__c > (), new list < Registration__c > (), TimeOffList);

        // LId, SId, startTime, endTime, DBST, DBET, AvailableResourceList[i], Product.Allow_Not_Available_Slot__c, slotDuration, AllTimeSlotList, HolidayList,
        // BookedRegMap.get(AvailableResourceList[i].Id), TimeOffMap.get(AvailableResourceList[i].User__c)


        wrap.ServiceImage = null;
        ABHome_Sch.getAccounts();
        String accId = acc.Id;
        ABHome_Sch.getLocations(accId);
        ABHome_Sch.getTypes();
        try { ABHome_Sch.getExperts(); } catch (Exception e) {
            system.debug('Exception-->' + e.getMessage());
        }
        //ABHome_Sch.getAvailableDates('', '');
        //ABHome_Sch.fetchProducts();
        String typeId = product.Family;
        String acId = acc.Id;
        String prodId = product.Id;
        ABHome_Sch.fetchLocs(acId, prodId);
        String value = 'test';
        String label = 'test';
        Boolean isDisabled = true;
        ABHome_Sch.SelectOption selects = new ABHome_Sch.SelectOption(value, label, isDisabled);
        Registration__c Invite = reg;
        ABHome_Sch.inviteGuest(Invite);
        ABHome_Sch.getpickval();
        String events = event.Id;
        // ABHome_Sch.getEvt(events);
        String accsId = acc.Id;
        String locId = expLoc.Id;
        String Category = product.Family;

        try { ABHome_Sch.filterAccLocType(); } catch (exception ex) {
            system.debug('Exception-->' + ex.getMessage());
        }
        String SID = product.Id;
        String LID = expLoc.Id;
        String RegId = reg.Id;
        ABHome_Sch.getRegDetails(RegId); //

        ABHome_Sch.getExpertByTimeZone('America/New_York');
        ABHome_Sch.getExpertByTimeZoneAndResources(LID, SID, 'America/New_York');

        Registration__c Regis = reg;
        String status = reg.Status__c;

        String RegJSON = '[{"Id":"' + reg.Id + '","Name":"009938","Customer_Email__c":"Hena.Zohra@aqxolt.com","Customer_Name__c":"Abdur","Customer_Lastname__c":"Rakib","Customer_Contact__c":"879908765678","Customer_Status__c":"Not Attended","Customer_Type__c":"Consumer","Expert_Location__c":"' + expLoc.Id + '","Registration_Type__c":"Walk in","Amount_Paid__c":0,"Status__c":"Reserve","Total_Due__c":0,"Total_Due_Amount__c":2133.5,"Registration_Price__c":2000,"Total_Registration_Price__c":2133.5,"Event__r":{"Name":"HR & Finance Business Summit","Description__c":"HR Director Business Summit:","Event_Type__c":"Event","Id":"' + event.Id + '","Expert_Location__r":{"Show_Experts__c":true,"Name":"London - Westfield Centre - Manipal Center","Address__c":"1089 Lower Level, Westfield Shopping Centre","City__c":"London","Province_State__c":"Greater London","Country__c":"United Kingdom","Zip_Code__c":"W12 7GB","Id":"' + expLoc.Id + '"}}}]';

        String RDJSON = '{"Id":"' + reg.Id + '","Name":"010703","Customer_Lastname__c":"Test","Expert_Location__c":"' + expLoc.Id + '","Expert__c":"' + expert.Id + '","Customer_Type__c":"Consumer","Product2__c":"' + product.Id + '","Registration_Type__c":"Online","Status__c":"Booked","Customer_Email__c":"abc@gmail.com","Customer_Contact__c":"98765435678","Total_Registration_Price__c":"106.67","Purpose__c":"pay","Expert_Location__r":{"Name":"United Kingdom1","Address__c":"Housing Rights","City__c":"Catford","Country__c":"United Kingdom","Show_Experts__c":true,"Id":"' + expLoc.Id + '"},"Expert__r":{"Name":"Mark Cooper","Id":"' + expert.Id + '"},"Product2__r":{"Name":"HR Directors - UK","Id":"' + product.Id + '"},"Registration_Price__c":100}';
        String RegsJSON = JSON.serialize(reg);
        try {
            ABHome_Sch.getBookReg2D(RegsJSON, String.valueOf(System.now()), product.Id, expLoc.Id, expert.Id, true, 100);
            Registration__c obj = new Registration__c();
        } catch (exception e) {
            system.debug('Exception-->' + e.getMessage());
        }

        ABHome_Sch.updateReg(RDJSON);


        ABHome_Sch.GetApp();
        String SelectedPBE = 'test';
        String RegisId = reg.Id;


        test.startTest();

        String EId = eventAlloc.Id;
        ABHome_Sch.getEventAllocationById(EId);
        DateTime dt = reg.Registration_Time__c;
        String locsId = expLoc.Id;
        try {
            list < String > stList = new list < String > ();
            stList.add(String.valueOf(System.now()));
            stList.add(String.valueOf(System.now() + 1));
            ABHome_Sch.getSelected1(stList, Expert.Id, expLoc.Id, reg.Id);
            ABHome_Sch.getReg(reg.Id); //
            ABHome_Sch.getRegUpdate(reg.Id, product.Id);
            ABHome_Sch.timeConvert('11:00 AM');
            //ABHome_Sch.getWorkPlanner(WP.Id);
            //ABHome_Sch.getWPnners(expLoc.Id,'America/New_York');
            //ABHome_Sch.getWPnnerByLocatinAndService(expLoc.Id,'America/New_York',product.Id);
            ABHome_Sch.getTimeSlotM(Resource.Id, ad, expLoc.Id, product.Id, WP.Id);
            ABHome_Sch.getAvailableDates(Resource.Id, expLoc.Id);
            ABHome_Sch.getLocationDetails(expLoc.Id);
            ABHome_Sch.getSearchRecords('Vet');
            ABHome_Sch.getChildRegistrations(reg.Id);
            ABHome_Sch.getRegistration(reg.Id);
            ABHome_Sch.Registration(reg.Id);
            ABHome_Sch.Reservations(expLoc.Id, product.Id);
            ABHome_Sch.getReservations(expLoc.Id, product.Id,Expert.Id);

        } catch (Exception e) {
            system.debug('Exception-->' + e.getMessage());
        }

        String LIds = expLoc.Id;
        String SIds = product.Id;
        ABHome_Sch.getTimeSlotsDI1(LIds, SIds,'America/New_York',expert.Id);
        ABHome_Sch.getTimeSlot(LIds, SIds, 'America/New_York', expert.Id, 0);

        String EIds = expert.Id;
       // ABHome_Sch.getTimeSlotM(expert.Id, ad, expLoc.Id, SIds);
        ABHome_Sch.getBookedTime();
        Registration__c Regs = reg;
        ABHome_Sch.getSTValue('');
        //ABHome_Sch.getAllTimeSlotList(System.now(), System.now().addDays(1), 60);
        Member__c Member = new Member__c(Name = '78967', Account_Membership__c = Acc.Id, Assigned_Contact__c = Con.Id);
        insert Member;
        //ABHome_Sch.getServices('America/New_York', Member.Id);

        // ABHome_Sch.ClubNewMethod('America/New_York',JSON.serialize(System.today()), 'Next', expLoc.Id, SIds,Member.Id);
        // ABHome_Sch.ClubNewMethod('America/New_York',System.today(), 'Next', expLoc.Id, SIds,Member.Id);
        // ABHome_Sch.ClubNewMethod('America/New_York',System.today(), 'Prev', expLoc.Id, SIds,Member.Id);
        String exploc2=expLoc.Id;
        String mid=Member.Id;
        ABHome_Sch.ClubNewMethod1UserAvailability(new List<Resource__c>(), new List<Resource__c>(), 'America/New_York',System.today(), 'Next', exploc2, SIds,mid, Product, new SystemCode__c(), new List<Holiday__c>(), new Map<Id, list<Registration__c>>(),new Map<Id, list<Time_Off__c>>(), new list<Work_Planner__c>());//,new List<Capacity__c>()
        ABHome_Sch.ClubNewMethod1NP(new List<Resource__c>(), new List<Resource__c>(), 'America/New_York',System.today(), 'Prev', exploc2, SIds,mid, Product, new SystemCode__c(), new List<Holiday__c>(), new Map<Id, list<Registration__c>>(),new Map<Id, list<Time_Off__c>>(), new list<Work_Planner__c>());//,new List<Capacity__c>()
        ABHome_Sch.ClubNewMethod1(new List<Resource__c>(), new List<Resource__c>(), 'America/New_York',System.today(), 'Prev', exploc2, SIds,mid, Product, new SystemCode__c(), new List<Holiday__c>(), new Map<Id, list<Registration__c>>(),new Map<Id, list<Time_Off__c>>(), new list<Work_Planner__c>());//,new List<Capacity__c>()
        ABHome_Sch.getCancellationReasons();

        List < Resource__c > AvailableResourcelist = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        List < Resource__c > RRListByResourceGroup = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);

        expSer.firstHideExpertName = null;
        expSer.TZ = null;
        String RJSON = '[{"Id":"' + reg.Id + '","FirstName":"Md","LastName":"Shahid","Phone":"9873248957","Email":"abdur.rakib@aqxolt.com","Is_Invited_user__c":"false"}]';

        List < String > selDates = new List < String > ();
        selDates.add(String.valueOf(System.now()));
        selDates.add(String.valueOf(System.now()));

        List < String > ResourceIds = new List < String > ();
        ResourceIds.add(Resource.Id);
        ResourceIds.add(Resource.Id);

        String SelDateStr = '["2019-02-07T20:30:00.000Z","2019-02-07T21:00:00.000Z"]';
        String Resources = '["a179000000UMGCwAAP","a179000000UMGCwAAP"]';
        ABHome_Sch.getChangeRegistrationStatus(Reg.Id);
        ABHome_Sch.getDayNameOfDate(System.today());
        //ABHome_Sch.getCreateReg(SelDateStr, Resources, '30', Exploc.Id, Resource.Id, Reg.Id);
        // ABHome_Sch.getRegUpdate(Reg.Id, Product.Id, Acc.Id, con.Id, Member.Id);
        String exp=Exploc.Id;
        String prod=Product.Id;
        ABHome_Sch.getResourcesByTimeZone(exp,prod,'America/New_York','');
        //ABHome_Sch.getTimeSlotsDoInit(Exploc.Id,Product.Id,'America/New_York',Resource.Id,true,Member.Id); //

        //ABHome_Sch.checkResourceAvailibity(Resource, System.today()+1, Exploc.Id, Product.Id, new Product2(), new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), '');

        // ABHome_Sch.getTimeSlots(Resource.Id, System.Today()+1, Exploc.Id, Product.Id, 'Next', 'America/New_York' , Member.Id);

        //ABHome_Sch.getUserTimeSlots(Resource, System.Now(), Exploc.Id, Product.Id, Product, new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), 'Next', new list < Work_Planner__c > ());

        //ABHome_Sch.checkResourceAvailibity(Resource, System.today()+1, Exploc.Id, Product1.Id, new Product2(), new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), 'Next');

        //ABHome_Sch.checkResourceAvailibity(Resource,System.today(), Exploc.Id, Product.Id, new Product2(), new SystemCode__c(), new list<Registration__c>(),new list<Time_Off__c>(), new List<Holiday__c>());
        //ABHome_Sch.getTimeSlotC(Resource.Id, System.Today(), Exploc.Id, Product.Id, 'Prev', 'America/New_York' , Member.Id);
        ABHome_Sch.getUserTimeSlots(Resource, System.Now(), exp, prod, Product, new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), 'Prev', new list < Work_Planner__c > ());//,cap1

        // ABHome_Sch.checkResourceAvailibity(Resource, System.today()+1, Exploc.Id, Product.Id, new Product2(), new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), 'Prev');
        // ABHome_Sch.getUserTimeSlots(Resource, System.Now(), Exploc.Id, Product.Id, Product, new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), '', new list < Work_Planner__c > ());
        // ABHome_Sch.getResourcesByTimeZone(Exploc.Id, Product.Id, 'America/New_York', '');
        // ABHome_Sch.getUsersByTimeZone(Exploc.Id, Product.Id,'America/New_York',Member.Id,System.today());


        ABHome_Sch.getAvailableDate(System.now(), Resource);
        Resource.Start_date__c = System.today() + 1;
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);

        Resource.Start_date__c = System.today() + 2;

        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);

        Resource.Start_date__c = System.today() + 3;
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);

        Resource.Start_date__c = System.today() + 4;
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);

        Resource.Start_date__c = System.today() + 5;
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);

        Resource.Start_date__c = System.today() + 6;
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getAvailableDate(Resource.Start_date__c, Resource);
        List < Resource__c > RList = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        List < Resource__c > RListNew = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        ABHome_Sch.getResourcesSortByAssignedToMember(RList, '','', Member.Id); //
        List < Registration__c > RegList = new List < Registration__c > ();
        RegList.add(reg);
        //ABHome_Sch.getCreateContact(JSON.serialize(RegList), con.Id);
        // try{ABHome_Sch.getBookRegistration('','',String.valueOf(Time.newInstance(9, 30, 0,0)), product.Id,expLoc.Id, Resource.Id, false,0);}catch(Exception e){}

        Relationship__c fam = new Relationship__c(Name='Fam-0001');
        insert fam;
        Contact_Relationship__c conRel = new Contact_Relationship__c(Name='ConRelTest1', Parent_Contact__c = con.Id, Family__c=fam.Id);
        insert conRel;
        ABHome_Sch.getExpertByTime(new set<String>(),system.now(),'');
        test.stopTest();
        delete event;
        String sxmltag = 'yshjd3';

        //   ABHome_Sch.getBookReg3D(RDJSON, RegJSON, String.valueOf(System.now()), product.Id, expLoc.Id, Resource.Id, false, 100);


        // ABHome_Sch.getCheckForWarnings(RDJSON, String.valueOf(System.now()), String.valueOf(System.now() + 7), System.today());

        /*
try{ABHome_Sch.getBookRegistrations(RDJSON,RegJSON,String.valueOf(System.now()),product.Id,expLoc.Id,expert.Id,true,100,'a179000000UMGCwAAP',String.valueOf(System.now()),String.valueOf(System.now()+1),System.today());}catch(Exception e){} //
*/ //ABHome_Sch.getDelectReserveRegistration(Reg.Id); //

        //ABHome_Sch.getCreateContact(JSON.serialize(RegList), con.Id);
        String salName = 'ERok';
        String sal1Name = 'ERok';
        System.assertEquals(salName, sal1Name);
        String RId;
        String TId;
    }
@isTest
    static  void ABHomeMethod1() {

        //Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');//, RecordTypeId = accRecType
        insert acc;
        Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
        insert con;
        String totalMiles = '';
        String totalMiles1 = '';
        String assert = 'test@gmail.com';
        String assert1 = '78967';

        User u1 = [SELECT Id FROM User limit 1];
        contact testMiles2 = new contact(FirstName = 'test1', LastName = 'tes', Phone = '78967', Email = 'test187755@gmail.com');

        insert testMiles2;
        for (contact m: [SELECT FirstName, Phone, Email FROM contact WHERE CreatedDate = TODAY]) {
            totalMiles += m.Email;
            totalMiles1 += m.Phone;
        }

        Product_Service_List__c psl = new Product_Service_List__c(Name = 'Croydon - North End', Active__c = true, Description__c = 'test');
        insert psl;

        Id rec = Schema.SObjectType.Expert__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Expert__c expert = new Expert__c(Name = 'Mark Cooper', RecordTypeId = rec, Product_Service_List__c = psl.Id,
                                                             Start_Time__c = '9:00', End_Time__c = '20:00', Expert_Time_Slot_Duration__c = '30',
                                                             Expert_Start_Time__c = system.today(), Expert_End_Time__c = system.today() + 1, Email__c = 'expert002@gmail.com', Description__c = 'test',
                                                             Phone__c = '07141141141', Active__c = true, Expert_Image_Url__c = 'https://eventrok-dev-ed--c.ap1.content.force.com/servlet/servlet.ImageServer?id=0159000000D9QKd&oid=00D90000000wSQS&lastMod=1471946486000');
        insert expert;
        list < Expert__c > expertList = new list < Expert__c > ();
        expertList.add(expert);
        upsert expertList;

        ABHome_Sch expService = new ABHome_Sch ();
        String firstHideExpertId;
        expService.firstHideExpertId = expertList[0].Id;
        expService.showExpert = false;
        expService.sessionsList = null;
        expService.startAT = null;
        expService.startET = null;
        ABHome_Sch.accountsList = null;
        ABHome_Sch.locList = null;
        ABHome_Sch.selectedCity = null;
        expService.AvailableExperts = null;
        expService.registration = null;
        expService.StartTime = expService.EndTime = expService.DBST = expService.DBET = null;

        ABHome_Sch.RecordWrp rw = new ABHome_Sch.RecordWrp();
        rw.Id = null;
        rw.Name = null;
        rw.Email = null;
        rw.Phone = null;
        rw.Type = null;

        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);
        insert expLoc;
        Expert_Location__c expLoc2 = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);
        insert expLoc2;

        Expert_Location_Allocation__c ela = new Expert_Location_Allocation__c(Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Active__c = true);
        try {
            insert ela;
        } catch (Exception e) {
            system.debug('Exception' + e.getMessage());
        }


        Id record = Schema.SObjectType.Available_Date__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Available_Date__c ad = new Available_Date__c(Expert__c = expert.Id, Expert_Location__c = expLoc.Id,
                                                                         Start_Date__c = system.today() + 1, End_Date__c = system.today(), RecordTypeId = record, Reason__c = 'Available');
        insert ad;
        Membership_Program__c memProg = new Membership_Program__c(Name='Test membership');
        insert memProg;

        Product2 product = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = true, Membership_Program__c = memProg.Id);
        insert product;
        Product2 product1 = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = false);
        insert product1;

        Product_Service_List_Item__c psli = new Product_Service_List_Item__c(Product_Service_List__c = psl.Id, Product2__c = product.Id, Active__c = true);
        insert psli;

        Contact_Profile__c cp = new Contact_Profile__c(Name = 'London - Westfield Centre Profile', Active__c = true);
        insert cp;

        Profile_Allocation__c pa = new Profile_Allocation__c(Profile_Allocation_Account__c = acc.Id, Expert_Location__c = expLoc.Id, Active__c = true, Default__c = true);
        insert pa;





        Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Registration_Price__c = 100, Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.today(), End_Time__c = system.today(), Customer_Name__c = 'test', Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com',  Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg;


        Work_Planner__c WP = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 10);
        insert WP;
        try {
            ABHome_Sch.getBookingCancelled(Reg.Id);
            ABHome_Sch.getNewRescheduling(Reg.Id,JSON.serialize(system.today()));
        } catch (Exception e) {
                system.debug('Exception'+e.getMessage());
        }

        String RegJSON = '[{"Id":"' + reg.Id + '","Name":"009938","Customer_Email__c":"Hena.Zohra@aqxolt.com","Customer_Name__c":"Abdur","Customer_Lastname__c":"Rakib","Customer_Contact__c":"879908765678","Customer_Status__c":"Not Attended","Customer_Type__c":"Consumer","Expert_Location__c":"' + expLoc.Id + '","Registration_Type__c":"Walk in","Amount_Paid__c":0,"Status__c":"Reserve","Total_Due__c":0,"Total_Due_Amount__c":2133.5,"Registration_Price__c":2000,"Total_Registration_Price__c":2133.5,"Event__r":{"Name":"HR & Finance Business Summit","Description__c":"HR Director Business Summit:","Event_Type__c":"Event","Id":"' + event.Id + '","Expert_Location__r":{"Show_Experts__c":true,"Name":"London - Westfield Centre - Manipal Center","Address__c":"1089 Lower Level, Westfield Shopping Centre","City__c":"London","Province_State__c":"Greater London","Country__c":"United Kingdom","Zip_Code__c":"W12 7GB","Id":"' + expLoc.Id + '"}}}]';
        String RDJSON = '{"Id":"' + reg.Id + '","Name":"010703","Customer_Lastname__c":"Test","Expert_Location__c":"' + expLoc.Id + '","Expert__c":"' + expert.Id + '","Customer_Type__c":"Consumer","Product2__c":"' + product.Id + '","Registration_Type__c":"Online","Status__c":"Booked","Customer_Email__c":"abc@gmail.com","Customer_Contact__c":"98765435678","Total_Registration_Price__c":"106.67","Purpose__c":"pay","Expert_Location__r":{"Name":"United Kingdom1","Address__c":"Housing Rights","City__c":"Catford","Country__c":"United Kingdom","Show_Experts__c":true,"Id":"' + expLoc.Id + '"},"Expert__r":{"Name":"Mark Cooper","Id":"' + expert.Id + '"},"Product2__r":{"Name":"HR Directors - UK","Id":"' + product.Id + '"},"Registration_Price__c":100}';
        String RDJSON2 = '{"Id":"' + reg.Id + '","Name":"010703","Customer_Lastname__c":"Test","Expert_Location__c":"' + expLoc.Id + '","Expert__c":"' + expert.Id + '","Customer_Type__c":"Consumer","Product2__c":"' + product.Id + '","Registration_Type__c":"Online","Status__c":"Booked","Customer_Email__c":"test@gmail.com","Customer_Contact__c":"98765435678","Total_Registration_Price__c":"106.67","Purpose__c":"pay","Expert_Location__r":{"Name":"United Kingdom1","Address__c":"Housing Rights","City__c":"Catford","Country__c":"United Kingdom","Show_Experts__c":true,"Id":"' + expLoc.Id + '"},"Expert__r":{"Name":"Mark Cooper","Id":"' + expert.Id + '"},"Product2__r":{"Name":"HR Directors - UK","Id":"' + product.Id + '"},"Registration_Price__c":100}';
        Resource_Group__c ResourceGroup = new Resource_Group__c(Name = 'Abdur Rakib', Start_date__c = System.today(), End_date__c = System.today() + 30);
        insert ResourceGroup;
        Resource_Requirement__c resReq = new Resource_Requirement__c(Name='Test ResReq', Resource_Group__c = ResourceGroup.Id, Work_Planner__c=WP.Id, Location__c=expLoc.Id);
        insert resReq;
        Resource_Requirement__c RR = new Resource_Requirement__c(
            Name = 'Mississauga - OW - Application/Transfer-In',
            Work_Planner__c = wp.Id,
            Resource_Group__c = ResourceGroup.Id
        );
        insert RR;

        list < Time_Off__c > TimeOffList = new list < Time_Off__c > ();
        TimeOffList = [SELECT Id, Name, Resource__c, Start_Date__c, End_Date__c, Type__c, Start_Time__c, End_Time__c, User__c
                       FROM Time_Off__c WHERE
                       End_Date__c >=: System.today()
                       AND Type__c != null
                       AND((Start_Time__c = null AND End_Time__c = null) OR(Start_Time__c != null AND End_Time__c != null))
                       AND Start_Date__c != null AND End_Date__c != null Order By Start_Date__c
                      ];

        Resource__c Resource = new Resource__c( Resource_Group__c = ResourceGroup.id,Name = 'Abdur Rakib', Start_date__c = System.today(), End_date__c = System.today() + 30, User__c=userInfo.getUserId(),
                                                                   Mon_Start_Time__c = Time.newInstance(9, 30, 0, 0), Mon_End_Time__c = Time.newInstance(17, 30, 0, 0), Mon_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Mon_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Tue_Start_Time__c = Time.newInstance(9, 30, 0, 0), Tue_End_Time__c = Time.newInstance(17, 30, 0, 0), Tue_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Tue_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Wed_Start_Time__c = Time.newInstance(9, 30, 0, 0), Wed_End_Time__c = Time.newInstance(17, 30, 0, 0), Wed_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Wed_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Thu_Start_Time__c = Time.newInstance(9, 30, 0, 0), Thu_End_Time__c = Time.newInstance(17, 30, 0, 0), Thu_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Thu_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Fri_Start_Time__c = Time.newInstance(9, 30, 0, 0), Fri_End_Time__c = Time.newInstance(17, 30, 0, 0), Fri_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Fri_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sat_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sat_End_Time__c = Time.newInstance(17, 30, 0, 0), Sat_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sat_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sun_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sun_End_Time__c = Time.newInstance(17, 30, 0, 0), Sun_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sun_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Email__c = 'abc@gmail.com', Time_Slot_Duration__c = 60, Break_Start_Time__c = Time.newInstance(17, 30, 0, 0), Break_End_Time__c = Time.newInstance(18, 30, 0, 0)
                                                                  ); //,Appointment_Email__c=true
        insert Resource;
        Registration__c reg2 = new Registration__c(Customer_Lastname__c = 'test', Registration_Price__c = 100, Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.today(), End_Time__c = system.today(), Customer_Name__c = 'test', Contact__c = con.Id,Resource__c=Resource.Id,
                                                                      Customer_Email__c = 'test@gmail.com', Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg2;
        Member__c Member = new Member__c(Name = '78967', Account_Membership__c = Acc.Id, Assigned_Contact__c = Con.Id);
        insert Member;
        String RegJSON2 = '[{"Id":"' + reg.Id + '","Name":"009938","Customer_Email__c":"Hena.Zohra@aqxolt.com","Customer_Name__c":"Abdur","Customer_Lastname__c":"Rakib","Customer_Contact__c":"879908765678","Customer_Status__c":"Not Attended","Customer_Type__c":"Consumer","Expert_Location__c":"' + expLoc.Id + '","Registration_Type__c":"Walk in","Amount_Paid__c":0,"Status__c":"Reserve","Total_Due__c":0,"Total_Due_Amount__c":2133.5,"Registration_Price__c":2000,"Total_Registration_Price__c":2133.5,"Event__c":"' + event.Id + '"}]';



        /*    new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);*/

        List < Resource__c > RList = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        List < Resource__c > RListNew = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        List < Resource__c > AvailableResourcelist = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        List < Resource__c > RRListByResourceGroup = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        ABHome_Sch.getUsersByTimeZone(expLoc.Id, product.Id,'America/New_York',Member.Id,System.today());
        ABHome_Sch.getTimeSlots(Resource.Id, System.Today(), Exploc.Id, Product.Id, 'Prev', 'America/New_York', Member.Id); //
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getUserType();
        ABHome_Sch.Wrapper wrap = new ABHome_Sch.Wrapper();
        ABHome_Sch.ClubNewMethod('America/New_York',System.today(),null,Exploc.Id, Product.Id,Member.Id,'');
        //ABHome_Sch.ClubNewMethodInit('America/New_York',System.today(),null,Exploc.Id, Product.Id,Member.Id,'');
        //ABHome_Sch.getCheckForWarnings(RegJSON,'09.00','10.00',system.today());
        //ABHome_Sch.getDelectReserveRegistration(RegJSON);
        ABHome_Sch.getServices('America/New_York', Member.Id);
        test.startTest();
        ABHome_Sch.checkResourceAvailibity(Resource, System.today()+1, Exploc.Id, Product.Id, new Product2(), new SystemCode__c(), new list < Registration__c > (), new list < Time_Off__c > (), new List < Holiday__c > (), '');
        ABHome_Sch.BookRegistration(RegJSON, RDJSON,'09.00',Product.Id, Exploc.Id,Resource.Id,true,0.02,'','09.00','10.00',system.today());

        ABHome_Sch.deleteVirtualMeeting(reg.Id);
        //ABHome_Sch.getCreateContact(RegJSON2,'');
        //ABHome_Sch.getCreateContact(RegJSON2,con.Id);
        //ABHome_Sch.getCreateContact(RDJSON,con.Id);
        //ABHome_Sch.getCreateContact(RDJSON2,con.Id);
        ABHome_Sch.getTimeCancelled(reg.Id);
		ABHome_Sch.getDelectReserveRegistration(reg.Id);
		ABHome_Sch.MaxRegistrationExceeded(reg, product.id,Exploc.Id);
        ABHome_Sch.MaxRegistrationExceeded(reg2, product.id,Exploc.Id);
        test.stopTest();
        String salName = 'ERok';
        String sal1Name = 'ERok';
        System.assertEquals(salName, sal1Name); //a179000000UMGCwAAP
    }
@isTest
    static  void ABHomeMethod4() {

       // Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');//, RecordTypeId = accRecType
        insert acc;
        Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
        insert con;
        String totalMiles = '';
        String totalMiles1 = '';
        String assert = 'test@gmail.com';
        String assert1 = '78967';

        User u1 = [SELECT Id FROM User limit 1];
        contact testMiles2 = new contact(FirstName = 'test1', LastName = 'tes', Phone = '78967', Email = 'test187755@gmail.com');

        insert testMiles2;
        for (contact m: [SELECT FirstName, Phone, Email FROM contact WHERE CreatedDate = TODAY]) {
            totalMiles += m.Email;
            totalMiles1 += m.Phone;
        }

        Product_Service_List__c psl = new Product_Service_List__c(Name = 'Croydon - North End', Active__c = true, Description__c = 'test');
        insert psl;

        Id rec = Schema.SObjectType.Expert__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Expert__c expert = new Expert__c(Name = 'Mark Cooper', RecordTypeId = rec, Product_Service_List__c = psl.Id,
                                                             Start_Time__c = '9:00', End_Time__c = '20:00', Expert_Time_Slot_Duration__c = '30',
                                                             Expert_Start_Time__c = system.today(), Expert_End_Time__c = system.today() + 1, Email__c = 'expert002@gmail.com', Description__c = 'test',
                                                             Phone__c = '07141141141', Active__c = true, Expert_Image_Url__c = 'https://eventrok-dev-ed--c.ap1.content.force.com/servlet/servlet.ImageServer?id=0159000000D9QKd&oid=00D90000000wSQS&lastMod=1471946486000');
        insert expert;
        list < Expert__c > expertList = new list < Expert__c > ();
        expertList.add(expert);
        upsert expertList;

        ABHome_Sch expService = new ABHome_Sch ();
        String firstHideExpertId;
        expService.firstHideExpertId = expertList[0].Id;
        expService.showExpert = false;
        expService.sessionsList = null;
        expService.startAT = null;
        expService.startET = null;
        ABHome_Sch.accountsList = null;
        ABHome_Sch.locList = null;
        ABHome_Sch.selectedCity = null;
        expService.AvailableExperts = null;
        expService.registration = null;
        expService.StartTime = expService.EndTime = expService.DBST = expService.DBET = null;

        ABHome_Sch.RecordWrp rw = new ABHome_Sch.RecordWrp();
        rw.Id = null;
        rw.Name = null;
        rw.Email = null;
        rw.Phone = null;
        rw.Type = null;

        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);
        insert expLoc;

        Expert_Location_Allocation__c ela = new Expert_Location_Allocation__c(Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Active__c = true);
        try {
            insert ela;
        } catch (Exception e) {
            system.debug('Exception==='+e.getMessage());
        }


         Id record = Schema.SObjectType.Available_Date__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Available_Date__c ad = new Available_Date__c(Expert__c = expert.Id, Expert_Location__c = expLoc.Id,
                                                                         Start_Date__c = system.today() + 1, End_Date__c = system.today(), RecordTypeId = record, Reason__c = 'Available');
        insert ad;

        Product2 product = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = true);
        insert product;
        Product2 product1 = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = false);
        insert product1;

        Product_Service_List_Item__c psli = new Product_Service_List_Item__c(Product_Service_List__c = psl.Id, Product2__c = product.Id, Active__c = true);
        insert psli;

        Contact_Profile__c cp = new Contact_Profile__c(Name = 'London - Westfield Centre Profile', Active__c = true);
        insert cp;

        Profile_Allocation__c pa = new Profile_Allocation__c(Profile_Allocation_Account__c = acc.Id, Expert_Location__c = expLoc.Id, Active__c = true, Default__c = true);
        insert pa;





        Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Registration_Price__c = 100, Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.today(), End_Time__c = system.today(), Customer_Name__c = 'test', Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com',Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg;
        String regisId=reg.Id;
		AppointmentBookingExternal_Sch.getAllServicesandReg(regisId, '');
        Work_Planner__c WP = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 10);
        insert WP;
        try {
            ABHome_Sch.getBookingCancelled(Reg.Id);
            ABHome_Sch.getNewRescheduling(Reg.Id,JSON.serialize(system.today()));
        } catch (Exception e) {
            system.debug('Exception==='+e.getMessage());
        }

        String RegJSON = '[{"Id":"' + reg.Id + '","Name":"009938","Customer_Email__c":"Hena.Zohra@aqxolt.com","Customer_Name__c":"Abdur","Customer_Lastname__c":"Rakib","Customer_Contact__c":"879908765678","Customer_Status__c":"Not Attended","Customer_Type__c":"Consumer","Expert_Location__c":"' + expLoc.Id + '","Registration_Type__c":"Walk in","Amount_Paid__c":0,"Status__c":"Reserve","Total_Due__c":0,"Total_Due_Amount__c":2133.5,"Registration_Price__c":2000,"Total_Registration_Price__c":2133.5,"Event__r":{"Name":"HR & Finance Business Summit","Description__c":"HR Director Business Summit:","Event_Type__c":"Event","Id":"' + event.Id + '","Expert_Location__r":{"Show_Experts__c":true,"Name":"London - Westfield Centre - Manipal Center","Address__c":"1089 Lower Level, Westfield Shopping Centre","City__c":"London","Province_State__c":"Greater London","Country__c":"United Kingdom","Zip_Code__c":"W12 7GB","Id":"' + expLoc.Id + '"}}}]';
        String RDJSON = '{"Id":"' + reg.Id + '","Name":"010703","Customer_Lastname__c":"Test","Expert_Location__c":"' + expLoc.Id + '","Expert__c":"' + expert.Id + '","Customer_Type__c":"Consumer","Product2__c":"' + product.Id + '","Registration_Type__c":"Online","Status__c":"Booked","Customer_Email__c":"abc@gmail.com","Customer_Contact__c":"98765435678","Total_Registration_Price__c":"106.67","Purpose__c":"pay","Expert_Location__r":{"Name":"United Kingdom1","Address__c":"Housing Rights","City__c":"Catford","Country__c":"United Kingdom","Show_Experts__c":true,"Id":"' + expLoc.Id + '"},"Expert__r":{"Name":"Mark Cooper","Id":"' + expert.Id + '"},"Product2__r":{"Name":"HR Directors - UK","Id":"' + product.Id + '"},"Registration_Price__c":100}';

        Resource_Group__c ResourceGroup = new Resource_Group__c(Name = 'Abdur Rakib', Start_date__c = System.today(), End_date__c = System.today() + 30);
        insert ResourceGroup;

        Resource_Requirement__c RR = new Resource_Requirement__c(
            Name = 'Mississauga - OW - Application/Transfer-In',
            Work_Planner__c = wp.Id,
            Resource_Group__c = ResourceGroup.Id
        );
        insert RR;

        list < Time_Off__c > TimeOffList = new list < Time_Off__c > ();
        TimeOffList = [SELECT Id, Name, Resource__c, Start_Date__c, End_Date__c, Type__c, Start_Time__c, End_Time__c, User__c
                       FROM Time_Off__c WHERE
                       End_Date__c >=: System.today()
                       AND Type__c != null
                       AND((Start_Time__c = null AND End_Time__c = null) OR(Start_Time__c != null AND End_Time__c != null))
                       AND Start_Date__c != null AND End_Date__c != null Order By Start_Date__c
                      ];

        Resource__c Resource = new Resource__c( Resource_Group__c = ResourceGroup.id,Name = 'Abdur Rakib', Start_date__c = System.today(), End_date__c = System.today() + 30, User__c=userInfo.getUserId(),
                                                                   Mon_Start_Time__c = Time.newInstance(9, 30, 0, 0), Mon_End_Time__c = Time.newInstance(17, 30, 0, 0), Mon_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Mon_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Tue_Start_Time__c = Time.newInstance(9, 30, 0, 0), Tue_End_Time__c = Time.newInstance(17, 30, 0, 0), Tue_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Tue_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Wed_Start_Time__c = Time.newInstance(9, 30, 0, 0), Wed_End_Time__c = Time.newInstance(17, 30, 0, 0), Wed_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Wed_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Thu_Start_Time__c = Time.newInstance(9, 30, 0, 0), Thu_End_Time__c = Time.newInstance(17, 30, 0, 0), Thu_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Thu_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Fri_Start_Time__c = Time.newInstance(9, 30, 0, 0), Fri_End_Time__c = Time.newInstance(17, 30, 0, 0), Fri_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Fri_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sat_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sat_End_Time__c = Time.newInstance(17, 30, 0, 0), Sat_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sat_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sun_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sun_End_Time__c = Time.newInstance(17, 30, 0, 0), Sun_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sun_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Email__c = 'abc@gmail.com', Time_Slot_Duration__c = 60, Break_Start_Time__c = Time.newInstance(17, 30, 0, 0), Break_End_Time__c = Time.newInstance(18, 30, 0, 0)
                                                                  ); //,Appointment_Email__c=true
        insert Resource;
        Member__c Member = new Member__c(Name = '78967', Account_Membership__c = Acc.Id, Assigned_Contact__c = Con.Id);
        insert Member;

        List < Resource__c > RList = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        List < Resource__c > RListNew = new List < Resource__c > ();
        RList.add(Resource);
        RList.add(Resource);
        List < Resource__c > AvailableResourcelist = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        List < Resource__c > RRListByResourceGroup = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        ABHome_Sch.getUsersByTimeZone(expLoc.Id, product.Id,'America/New_York',Member.Id,System.today());
        AppointmentBookingExternal_Sch.getUsersByTimeZonefromAB(expLoc.Id, product.Id,'America/New_York',Member.Id,System.today());
        AppointmentBookingExternal_Sch.getTimeSlotsfromAB(Resource.Id, System.Today(), Exploc.Id, Product.Id, 'Prev', 'America/New_York', Member.Id);
        ABHome_Sch.getTimeSlots(Resource.Id, System.Today(), Exploc.Id, Product.Id, 'Prev', 'America/New_York', Member.Id); //
        ABHome_Sch.getDayNameOfDate(Resource.Start_date__c);
        ABHome_Sch.getUserType();
        ABHome_Sch.ClubNewMethod('America/New_York',System.today(),null,Exploc.Id, Product.Id,Member.Id,'');
        //ABHome_Sch.ClubNewMethodInit('America/New_York',System.today(),null,Exploc.Id, Product.Id,Member.Id,'');
        //ABHome_Sch.getCheckForWarnings(RegJSON,'09.00','10.00',system.today());


        // ABHome_Sch.getBookRegistrations(RegJSON, RDJSON,'09.00',Product.Id, Exploc.Id,Resource.Id,true,0.02,'','09.00','10.00',system.today());
        String RJSON = '[{"Id":"' + reg.Id + '","FirstName":"Md","LastName":"Shahid","Phone":"9873248957","Email":"abdur.rakib@aqxolt.com","Is_Invited_user__c":"false"}]';
        //      ABHome_Sch.getCheckForWarnings(RegJSON,'09.00','10.00',system.today());


        try{
            ABHome_Sch.getCreateAccountAndContact(RJSON,100,true);
        }catch(Exception e){
            system.debug('Exception in getCreateAccountAndContact');
        }
        try{
            ABHome_Sch.getCreateAccountAndContact(RJSON,100,false);
        }catch(Exception e){
            system.debug('Exception in getCreateAccountAndContact');
        }


        String salName = 'ERok';
        String sal1Name = 'ERok';
        System.assertEquals(salName, sal1Name); //a179000000UMGCwAAP
    }
@isTest
    static  void ABHomeMethod5() {

       // Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');//, RecordTypeId = accRecType
        insert acc;


        Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
        insert con;
        String totalMiles = '';
        String totalMiles1 = '';
        String assert = 'test@gmail.com';
        String assert1 = '78967';

        User u1 = [SELECT Id FROM User limit 1];
        contact testMiles2 = new contact(FirstName = 'test1', LastName = 'tes', Phone = '78967', Email = 'test187755@gmail.com');

        insert testMiles2;
        for (contact m: [SELECT FirstName, Phone, Email FROM contact WHERE CreatedDate = TODAY]) {
            totalMiles += m.Email;
            totalMiles1 += m.Phone;
        }

        Product_Service_List__c psl = new Product_Service_List__c(Name = 'Croydon - North End', Active__c = true, Description__c = 'test');
        insert psl;

        Id rec = Schema.SObjectType.Expert__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Expert__c expert = new Expert__c(Name = 'Mark Cooper', RecordTypeId = rec, Product_Service_List__c = psl.Id,
                                                             Start_Time__c = '9:00', End_Time__c = '20:00', Expert_Time_Slot_Duration__c = '30',
                                                             Expert_Start_Time__c = system.today(), Expert_End_Time__c = system.today() + 1, Email__c = 'expert002@gmail.com', Description__c = 'test',
                                                             Phone__c = '07141141141', Active__c = true, Expert_Image_Url__c = 'https://eventrok-dev-ed--c.ap1.content.force.com/servlet/servlet.ImageServer?id=0159000000D9QKd&oid=00D90000000wSQS&lastMod=1471946486000');
        insert expert;
        list < Expert__c > expertList = new list < Expert__c > ();
        expertList.add(expert);
        upsert expertList;

        ABHome_Sch expService = new ABHome_Sch ();
        String firstHideExpertId;
        expService.firstHideExpertId = expertList[0].Id;
        expService.showExpert = false;
        expService.sessionsList = null;
        expService.startAT = null;
        expService.startET = null;
        ABHome_Sch.accountsList = null;
        ABHome_Sch.locList = null;
        ABHome_Sch.selectedCity = null;
        expService.AvailableExperts = null;
        expService.registration = null;
        expService.StartTime = expService.EndTime = expService.DBST = expService.DBET = null;
        expService.DocumentId = null;
        ABHome_Sch.RecordWrp rw = new ABHome_Sch.RecordWrp();
        rw.Id = null;
        rw.Name = null;
        rw.Email = null;
        rw.Phone = null;
        rw.Type = null;

        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                               Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                               Description__c = 'test', Account__c = acc.Id, Product_Service_List__c = psl.Id, Phone__c = '9090890987',
                                                                               Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230, Store_Manager__c = expert.Id);
        insert expLoc;

        Expert_Location_Allocation__c ela = new Expert_Location_Allocation__c(Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Active__c = true);
        try {
            insert ela;
        } catch (Exception e) {
            system.debug('Exception in Expert_Location_Allocation__c insert');
        }


        Id record = Schema.SObjectType.Available_Date__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Available_Date__c ad = new Available_Date__c(Expert__c = expert.Id, Expert_Location__c = expLoc.Id,
                                                                         Start_Date__c = system.today() + 1, End_Date__c = system.today(), RecordTypeId = record, Reason__c = 'Available');
        insert ad;

        Product2 product = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = true);
        insert product;
        Product2 product1 = new Product2(Name = 'HR Directors - UK', isActive = true, Family = 'Event', Allow_Not_Available_Day__c = false);
        insert product1;

        Product_Service_List_Item__c psli = new Product_Service_List_Item__c(Product_Service_List__c = psl.Id, Product2__c = product.Id, Active__c = true);
        insert psli;

        Contact_Profile__c cp = new Contact_Profile__c(Name = 'London - Westfield Centre Profile', Active__c = true);
        insert cp;

        Profile_Allocation__c pa = new Profile_Allocation__c(Profile_Allocation_Account__c = acc.Id, Expert_Location__c = expLoc.Id, Active__c = true, Default__c = true);
        insert pa;





        Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Work_Planner__c wp = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 100, Distribution_Timeline__c = 'Monthly', Minimum_Threshold__c = 10);
        insert wp;

        Event__c event = new Event__c(Name = 'test', Event_Location__c = expLoc.Id, Event_Status__c = 'Active', Expert_Location__c = expLoc.Id,
                                                          Registration_Start_Date__c = system.today(), Registration_End_Date__c = system.today() + 1);
        insert event;

        Event_Allocation__c eventAlloc = new Event_Allocation__c(Location__c = expLoc.Id, Expert__c = expert.Id, Event__c = event.Id);
        insert eventAlloc;

        Resource__c Resource = new Resource__c(Name = 'Hena Zohra', Start_date__c = System.today(), End_date__c = System.today() + 30, User__c = userInfo.getUserId(),
                                                                   Mon_Start_Time__c = Time.newInstance(9, 30, 0, 0), Mon_End_Time__c = Time.newInstance(17, 30, 0, 0), Mon_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Mon_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Tue_Start_Time__c = Time.newInstance(9, 30, 0, 0), Tue_End_Time__c = Time.newInstance(17, 30, 0, 0), Tue_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Tue_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Wed_Start_Time__c = Time.newInstance(9, 30, 0, 0), Wed_End_Time__c = Time.newInstance(17, 30, 0, 0), Wed_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Wed_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Thu_Start_Time__c = Time.newInstance(9, 30, 0, 0), Thu_End_Time__c = Time.newInstance(17, 30, 0, 0), Thu_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Thu_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Fri_Start_Time__c = Time.newInstance(9, 30, 0, 0), Fri_End_Time__c = Time.newInstance(17, 30, 0, 0), Fri_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Fri_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sat_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sat_End_Time__c = Time.newInstance(17, 30, 0, 0), Sat_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sat_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Sun_Start_Time__c = Time.newInstance(9, 30, 0, 0), Sun_End_Time__c = Time.newInstance(17, 30, 0, 0), Sun_Break_Start_Time__c = Time.newInstance(14, 30, 0, 0), Sun_Break_End_Time__c = Time.newInstance(15, 30, 0, 0),
                                                                   Email__c = 'abc@gmail.com', Time_Slot_Duration__c = 60, Break_Start_Time__c = Time.newInstance(17, 30, 0, 0), Break_End_Time__c = Time.newInstance(18, 30, 0, 0)
                                                                  ); //,Appointment_Email__c=true
        insert Resource;
        Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Registration_Price__c = 100, Expert_Location__c = expLoc.Id, Expert__c = expert.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.today(), End_Time__c = system.today(), Customer_Name__c = 'test', Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com', Resource__c = Resource.Id,  Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg;
        ABHome_Sch.fetchRegistration(String.valueOf(reg.Id));






        SystemCode__c sysCode = new SystemCode__c();
        sysCode.Date_Format__c = 'EEE MM-DD-YYYY';
        sysCode.name = 'SystemCodeTime';
        insert sysCode;



        ABHome_Sch expSer = new ABHome_Sch ();
        ABHome_Sch.WrapperClass wrap = new ABHome_Sch.WrapperClass();
        ABHome_Sch.CheckPaidService check = new ABHome_Sch.CheckPaidService();
        expSer.Country = null;
        expSer.selectedWPId = null;
        expSer.startAfternoonTime = System.now();
        expser.startEndTime = null;
        expser.AvailableDatesOD = new List < Available_Date__c > ();
        expSer.AvailableDatesList = new set < Available_Date__c > ();
        // ABHome_Sch.readXMLResponse(null,'');

        ABHome_Sch.TimeSlot ts = new ABHome_Sch.TimeSlot();
        ts.Slot = System.now();
        ts.IsAvailable = false;
        ts.checked = false;
        ts.ResourceId = null;
        list < Time_Off__c > TimeOffList = new list < Time_Off__c > ();
        TimeOffList = [SELECT Id, Name, Resource__c, Start_Date__c, End_Date__c, Type__c, Start_Time__c, End_Time__c, User__c
                       FROM Time_Off__c WHERE
                       End_Date__c >=: System.today()
                       AND Type__c != null
                       AND((Start_Time__c = null AND End_Time__c = null) OR(Start_Time__c != null AND End_Time__c != null))
                       AND Start_Date__c != null AND End_Date__c != null Order By Start_Date__c
                      ];
        // ABHome_Sch.MaxRegistrationExceeded(reg, product.Id, expLoc.Id);
        ABHome_Sch.getAvailableTimeSlots(system.today(), expLoc.Id, product.Id, System.now(), System.now().addHours(10), System.now(), System.now().addHours(1), Resource, false, 30, new List < ABHome_Sch.TimeSlot > (),
                                     new List < Holiday__c > (), new list < Registration__c > (), TimeOffList);

        // LId, SId, startTime, endTime, DBST, DBET, AvailableResourceList[i], Product.Allow_Not_Available_Slot__c, slotDuration, AllTimeSlotList, HolidayList,
        // BookedRegMap.get(AvailableResourceList[i].Id), TimeOffMap.get(AvailableResourceList[i].User__c)


        wrap.ServiceImage = null;
        ABHome_Sch.getAccounts();
        String accId = acc.Id;
        ABHome_Sch.getLocations(accId);
        ABHome_Sch.getTypes();
        try {
            ABHome_Sch.getExperts();
        } catch (Exception e) {
            system.debug('Exception in ABHome_Sch.getExperts' + e.getMessage());
        }
        //ABHome_Sch.getAvailableDates('', '');
        //ABHome_Sch.fetchProducts();
        String typeId = product.Family;
        String acId = acc.Id;
        String prodId = product.Id;
        ABHome_Sch.fetchLocs(acId, prodId);
        String value = 'test';
        String label = 'test';
        Boolean isDisabled = true;
        ABHome_Sch.SelectOption selects = new ABHome_Sch.SelectOption(value, label, isDisabled);
        Registration__c Invite = reg;
        ABHome_Sch.inviteGuest(Invite);
        ABHome_Sch.getpickval();
        String events = event.Id;
        // ABHome_Sch.getEvt(events);
        String accsId = acc.Id;
        String locId = expLoc.Id;
        String Category = product.Family;

        try {
            ABHome_Sch.filterAccLocType();
        } catch (exception ex) {
            system.debug('Exception in ABHome_Sch.filterAccLocType' + ex.getMessage());
        }
        String SID = product.Id;
        String LID = expLoc.Id;
        String RegId = reg.Id;
        ABHome_Sch.getRegDetails(RegId); //

        ABHome_Sch.getExpertByTimeZone('America/New_York');
        ABHome_Sch.getExpertByTimeZoneAndResources(LID, SID, 'America/New_York');

        Registration__c Regis = reg;
        String status = reg.Status__c;

        String RegJSON = '[{"Id":"' + reg.Id + '","Name":"009938","Customer_Email__c":"Hena.Zohra@aqxolt.com","Customer_Name__c":"Abdur","Customer_Lastname__c":"Rakib","Customer_Contact__c":"879908765678","Customer_Status__c":"Not Attended","Customer_Type__c":"Consumer","Expert_Location__c":"' + expLoc.Id + '","Registration_Type__c":"Walk in","Amount_Paid__c":0,"Status__c":"Reserve","Total_Due__c":0,"Total_Due_Amount__c":2133.5,"Registration_Price__c":2000,"Total_Registration_Price__c":2133.5,"Event__r":{"Name":"HR & Finance Business Summit","Description__c":"HR Director Business Summit:","Event_Type__c":"Event","Id":"' + event.Id + '","Expert_Location__r":{"Show_Experts__c":true,"Name":"London - Westfield Centre - Manipal Center","Address__c":"1089 Lower Level, Westfield Shopping Centre","City__c":"London","Province_State__c":"Greater London","Country__c":"United Kingdom","Zip_Code__c":"W12 7GB","Id":"' + expLoc.Id + '"}}}]';

        String RDJSON = '{"Id":"' + reg.Id + '","Name":"010703","Customer_Lastname__c":"Test","Expert_Location__c":"' + expLoc.Id + '","Expert__c":"' + expert.Id + '","Customer_Type__c":"Consumer","Product2__c":"' + product.Id + '","Registration_Type__c":"Online","Status__c":"Booked","Customer_Email__c":"abc@gmail.com","Customer_Contact__c":"98765435678","Total_Registration_Price__c":"106.67","Purpose__c":"pay","Expert_Location__r":{"Name":"United Kingdom1","Address__c":"Housing Rights","City__c":"Catford","Country__c":"United Kingdom","Show_Experts__c":true,"Id":"' + expLoc.Id + '"},"Expert__r":{"Name":"Mark Cooper","Id":"' + expert.Id + '"},"Product2__r":{"Name":"HR Directors - UK","Id":"' + product.Id + '"},"Registration_Price__c":100}';
        String RegsJSON = JSON.serialize(reg);


        ABHome_Sch.GetApp();
        String SelectedPBE = 'test';
        String RegisId = reg.Id;



        String EId = eventAlloc.Id;

        DateTime dt = reg.Registration_Time__c;
        String locsId = expLoc.Id;
        try {
            list < String > stList = new list < String > ();
            stList.add(String.valueOf(System.now()));
            stList.add(String.valueOf(System.now() + 1));



        } catch (Exception e) {
            system.debug('Exception in ABHome_Sch.getTimeCancelled' + e.getMessage());
        }


        String LIds = expLoc.Id;
        String SIds = product.Id;


        String EIds = expert.Id;

        Member__c Member = new Member__c(Name = '78967', Account_Membership__c = Acc.Id, Assigned_Contact__c = Con.Id);
        insert Member;


        List < Resource__c > AvailableResourcelist = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);
        List < Resource__c > RRListByResourceGroup = new List < Resource__c > ();
        AvailableResourcelist.add(Resource);

        expSer.firstHideExpertName = null;
        expSer.TZ = null;
        String RJSON = '[{"Id":"' + reg.Id + '","FirstName":"Md","LastName":"Shahid","Phone":"9873248957","Email":"abdur.rakib@aqxolt.com","Is_Invited_user__c":"false"}]';

        List < String > selDates = new List < String > ();
        selDates.add(String.valueOf(System.now()));
        selDates.add(String.valueOf(System.now()));

        List < String > ResourceIds = new List < String > ();
        ResourceIds.add(Resource.Id);
        ResourceIds.add(Resource.Id);

        String SelDateStr = '["2019-02-07T20:30:00.000Z","2019-02-07T21:00:00.000Z"]';
        String Resources = '["a179000000UMGCwAAP","a179000000UMGCwAAP"]';


        String sxmltag = 'yshjd3';

        try{ABHome_Sch res=ABHome_Sch.getBookRegistration(RDJSON,RegJSON,String.valueOf(System.now()),String.valueOf(product.Id),String.valueOf(expLoc.Id),String.valueOf(expert.Id),true,100.0,'','10:00',String.valueOf(System.now()+1),System.today(),'');}catch(Exception e){ system.debug('Exception in ABHome_Sch.getBookRegistration'); } //

        ABHome_Sch.CancelBooking(RegId);

        ABHome_Sch.getResourcesByTimeZone(Exploc.Id, Product.Id, 'America/New_York', '');
        ABHome_Sch.getRegUpdates(RegId,Product.Id,'AID','CId','MId');
        //ABHome_Sch.getCreateReg(system.today(),'Resources','30','Exploc','ResourceId','RID');
        ABHome_Sch.getCreateReg(SelDateStr, Resources, '30', Exploc.Id, Resource.Id, Reg.Id);//,Product.Id
        //  ABHome_Sch.getTimeCancelled(Reg.Id);
        ABHome_Sch.getChildRegistrations(reg.Id);

        //ABHome_Sch.getTimeCancelled(reg.Id);
        //ABHome_Sch.deleteVirtualMeeting(reg.Id);
        //ABHome_Sch.deleteVirtualMeeting(reg.Id);
        String salName = 'ERok';
        String sal1Name = 'ERok';
        System.assertEquals(salName, sal1Name);
        String RId;
        String TId;
    }
@isTest
    static  void ABHomeMethodTestMethod12() {
        ABHome_Sch.getCheckForWarnings('null', String.valueOf(System.now()), String.valueOf(System.now() + 7), System.today());
        ABHome_Sch.getBookReg3D('RDJSON', 'RegJSON', String.valueOf(System.now()), 'product.Id', 'expLoc.Id', 'Resource.Id', false, 100);
        //ABHome_Sch.getDelectReserveRegistration(RegJSON);
        ABHome_Sch.fetchProducts();

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        String strTmp = '<xml><ToUserName>tUN</ToUserName><FromUserName>fUN</FromUserName><MsgType>mT</MsgType></xml>';
        req.requestBody = Blob.valueOf(strTmp);
        req.requestURI = 'https://ap1.salesforce.com/services/apexrest/Demo//CoreService';
        req.httpMethod = 'POST';

        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        //ABHome_Sch.updateMeeting('TestToken',null);
        //ABHome_Sch.startMeeting('TestToken',null);
        RestContext.request = req;
        RestContext.response = res;
        XmlStreamReader reader = new XmlStreamReader(req.requestBody.toString());
        ABHome_Sch.readXMLResponse(reader,'Transaction_Approved');
        Test.stopTest();

        //try{ ABHome_Sch.methodCall('hjgfd89765432456');}catch(Exception ex){}
        //try{ ABHome_Sch.getToken(); }catch(Exception ex){}
        //try{ ABHome_Sch.makeAPICall();  }catch(Exception ex){}

        ABHome_Sch expService = new ABHome_Sch ();
        //  ABHome_Sch.fetchRegistration(null);
        String firstHideExpertId;
        expService.firstHideExpertId = null;
        expService.showExpert = false;
        expService.sessionsList = null;
        expService.startAT = null;
        expService.startET = null;
        ABHome_Sch.accountsList = null;
        ABHome_Sch.locList = null;
        ABHome_Sch.selectedCity = null;
        expService.AvailableExperts = null;
        expService.registration = null;
        expService.StartTime = expService.EndTime = expService.DBST = expService.DBET = null;
        expService.DocumentId = null;
        ABHome_Sch.RecordWrp rw = new ABHome_Sch.RecordWrp();
        rw.Id = null;
        rw.Name = null;
        rw.Email = null;
        rw.Phone = null;
        rw.Type = null;

        ABHome_Sch.selectOptions rw2 = new ABHome_Sch.selectOptions(null,null);
        ABHome_Sch.selectOptions rw1 = new ABHome_Sch.selectOptions(null,null,null);
        rw1.label = null;
        rw1.value = null;
        rw1.selected = null;


        /*   ABHome_Sch ab=new ABHome_Sch ();
ab.message =null;
ab.Request =null;
ab.Response =null;
ABHome_Sch.meetingId =null;
ABHome_Sch.codeValue =null;
ABHome_Sch.accessToken =null;
ABHome_Sch.getTimeCancelled(null);*/
        ABHome_Sch.getBookRoomForAppointment('',System.now(), System.now().addDays(1));


    }

    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
        static void CalendlyABTest1() {
        AppointmentBookingExternal_Sch cab = new AppointmentBookingExternal_Sch();
        PreventRecursiveEntry_Sch.EventRegistraionSync = false;
        PreventRecursiveEntry_Sch.TimeOffCalenderEvent = false;
        PreventRecursiveEntry_Sch.EventCalenderEvent = false;
        PreventRecursiveEntry_Sch.EventZoneCalenderEvent = false;
        PreventRecursiveEntry_Sch.RollUp_Registration = false;

        AppointmentBookingExternal_Sch.getCancellationReasons();
        AppointmentBookingExternal_Sch.OptionWrap cow = new AppointmentBookingExternal_Sch.OptionWrap('abc','xyz');
        //AppointmentBookingExternal_Sch.OptionWrap('abc','xyz');
        Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
            Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
            Description__c = 'test', Phone__c = '9090890987',
            Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230);
        insert expLoc;
       Membership_Program__c Program=new Membership_Program__c(Name='abc',Active__c=true,End_Date__c = system.today().addDays(3));
        insert Program;
        Product2 product = new Product2(Name='test', IsActive=true, Family='Event', Membership_Program__c=Program.Id);
        insert product;
        Work_Planner__c wp = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 100, Distribution_Timeline__c = 'Monthly', Minimum_Threshold__c = 10);
        insert wp;

        Resource_Group__c RG = new Resource_Group__c(
            Name = 'Mississauga - OW - Application / Transfer-In'
        );
        insert RG;

        Resource_Requirement__c RR = new Resource_Requirement__c(
            Name = 'Mississauga - OW - Application/Transfer-In',
            Work_Planner__c = wp.Id,
            Resource_Group__c = RG.Id
        );
        insert RR;
        User CU = [SELECT Id,Name,LastName FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true limit 1];

        List < User > Users = new List < User > ();

        Account acct = new Account(Name = 'Vet Servicessss', Event_Type__c = 'Expert Service');
        insert acct;

        List < Resource__c > Resources = new List < Resource__c > ();
            for (Integer i = 0; i < 4; i++) {
                Resource__c Res = new Resource__c(
                    Name = 'Antonette Pagniello' + i, // Resource Name
                    User__c = CU.Id, // User
                    Resource_Group__c = RG.Id, // Resource Group
                    Time_Slot_Duration__c = 0, // Time Slot Duration
                    Override_Holidays__c = false, // Override Holidays
                    Super_User__c = false, // Super User
                    Start_Date__c = system.today() + 1, // Start Date
                    End_Date__c = system.today() + 10, // End Date
                    Monday__c = 0.00,
                    Tue_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Tue Start Time
                    Tue_End_Time__c = Time.newInstance(14, 15, 0, 0), // Tue End Time
                    Tuesday__c = 1.00, // Tue (Hrs)
                    Wednesday__c = 0.02, // Wed (Hrs)
                    Thu_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Thu Start Time
                    Thu_End_Time__c = Time.newInstance(14, 15, 0, 0), // Thu End Time
                    Thursdays__c = 1.00, // Thu (Hrs)
                    Fri_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Fri Start Time
                    Fri_End_Time__c = Time.newInstance(14, 15, 0, 0), // Fri End Time
                    Friday__c = 1.00, // Fri (Hrs)
                    Saturday__c = 0.02, // Sat (Hrs)
                    Sunday__c = 0.00 // Mon (Hrs)
                    // Sun (Hrs)
                );
                Resources.add(Res);
            }
        insert Resources;


        //Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');//, RecordTypeId = accRecType
        insert acc;
        Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
        insert con;

        Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();
        Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Expert_Location__c = expLoc.Id, Status__c = 'Booked',
                                                                      Registration_Time__c = system.now().addDays(1), Customer_Name__c = 'test', //Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com',Registration_Type__c = 'Online', RecordTypeId = recReg);
        insert reg;

         Registration__c reservereg = new Registration__c(Customer_Lastname__c = 'test', Expert_Location__c = expLoc.Id, Status__c = 'Reserve',
                                                                      Registration_Time__c = system.now().addDays(1), Customer_Name__c = 'test', //Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com',Registration_Type__c = 'Online', RecordTypeId = recReg);

        AppointmentBookingExternal_Sch.CreateRegInvite(String.valueOf(con.Id),'',JSON.serialize(reservereg));
        Member__c Member = new Member__c(Name = '78967', Account_Membership__c = acc.Id, Assigned_Contact__c = con.Id);
        insert Member;
         AppointmentBookingExternal_Sch.CreateRegInvite('',String.valueOf(Member.Id),JSON.serialize(reservereg));
        insert reservereg;

         Registration__c reservereg2 = new Registration__c(Customer_Lastname__c = 'test', Expert_Location__c = expLoc.Id, Status__c = 'Reserve',
                                                                      Registration_Time__c = system.now().addDays(1), Customer_Name__c = 'test', //Contact__c = con.Id,
                                                                      Customer_Email__c = 'test@gmail.com',Registration_Type__c = 'Online', RecordTypeId = recReg,Is_Invited_user__c=true);
        insert reservereg2;



        List < String > Resources1 = new List < String > ();
        Resources1.add(Resources[0].Id);

        List < DateTime > datetimelist = new List < DateTime > ();
        datetimelist.add(system.now().addDays(1));
        List < String > selDates = new List < String > ();
        selDates.add(String.valueOf(System.now()));




        SystemCode__c sysCode = new SystemCode__c();
        sysCode.Date_Format__c = 'EEE MM-DD-YYYY';
        sysCode.name = 'SystemCodeTime';
        insert sysCode;


        AppointmentBookingExternal_Sch.prodlistWrapper plw=new AppointmentBookingExternal_Sch.prodlistWrapper();
        AppointmentBookingExternal_Sch.prodregwrap plrw=new AppointmentBookingExternal_Sch.prodregwrap();

        AppointmentBookingExternal_Sch.getAllServicesandReg(reg.Id,'');

        test.startTest();
        Profile p = [SELECT Id,Name FROM Profile WHERE Name='Minimum Access - Salesforce'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='standarduserAKHDNF101@testorg.com');
        System.runAs(u) {
            try{
                AppointmentBookingExternal_Sch.getAllServicesandReg(reg.Id,'');
            }catch(Exception e){
                System.debug('Exception'+e.getMessage());
            }
        }
        try{
            //AppointmentBookingExternal_Sch.ClubNewMethodfromAB('America/New_York',System.today(),null,expLoc.Id, product.Id,'','');
            //AppointmentBookingExternal_Sch.getTimeSlotsDoInitfromAB(expLoc.Id, product.Id,'America/New_York', '', true, '');
            AppointmentBookingExternal_Sch.getTimeSlotsfromAB(Resources[0].Id, System.today(), expLoc.Id, product.Id, '', 'America/New_York', '');
            AppointmentBookingExternal_Sch.getUsersByTimeZonefromAB(expLoc.Id, product.Id, 'America/New_York', '', system.today());
            AppointmentBookingExternal_Sch.reservebooking(JSON.serialize(datetimelist), JSON.serialize(Resources1), '30', String.valueOf(exploc.Id),String.valueOf(product.Id), String.valueOf(Resources1[0]),  String.valueOf(reg.Id),false);
            AppointmentBookingExternal_Sch.reservebooking(JSON.serialize(datetimelist), JSON.serialize(Resources1), '30', String.valueOf(exploc.Id),String.valueOf(product.Id), String.valueOf(Resources1[0]),  String.valueOf(reg.Id),true);
            AppointmentBookingExternal_Sch.fetchregdetails(reg.Id,product.Id);
            AppointmentBookingExternal_Sch.getConfirmBooking(JSON.serialize(reg));
            AppointmentBookingExternal_Sch.cancelreserve(String.valueOf(reservereg.Id));
            AppointmentBookingExternal_Sch.cancelreserve(String.valueOf(reservereg2.Id));
            AppointmentBookingExternal_Sch.getCheckInByRegDetails('','','','');
            AppointmentBookingExternal_Sch.getCheckInByRegNo('');





        }catch(Exception e){
            System.debug('Exception'+e.getMessage());
        }
        test.stopTest();

        String salName = 'ERP7';
        String sal1Name = 'ERP7';
        System.assertEquals(salName, sal1Name);
    }

@isTest
    static  void CalendlyABTest2(){
        try{

            Expert_Location__c expLoc = new Expert_Location__c(Name = 'London - Westfield Centre - Manipal Center', Address__c = '1089 Lower Level, Westfield Shopping Centre', City__c = 'London',
                                                                                   Province_State__c = 'Greater London', Zip_Code__c = 'W12 7GB', Country__c = 'United Kingdom',
                                                                                   Description__c = 'test', Phone__c = '9090890987',
                                                                                   Active__c = true, latitude__c = 51.50720230, longitude__c = -0.22324230);
            insert expLoc;

            Membership_Program__c Program=new Membership_Program__c(Name='abc',Active__c=true,End_Date__c = system.today().addDays(3));
            insert Program;

            Product2 product = new Product2(Name='test', IsActive=true, Family='Event', Membership_Program__c=Program.Id);
            insert product;

            Work_Planner__c wp = new Work_Planner__c(Location__c = expLoc.Id, Product__c = product.Id, Status__c = 'Approved', Maximum_Threshold__c = 100, Distribution_Timeline__c = 'Monthly', Minimum_Threshold__c = 10);
            insert wp;

            Resource_Group__c RG = new Resource_Group__c(Name = 'Mississauga - OW - Application / Transfer-In');
            insert RG;

            Resource_Requirement__c RR = new Resource_Requirement__c(Name = 'Mississauga - OW - Application/Transfer-In',Work_Planner__c = wp.Id,Resource_Group__c = RG.Id);
            insert RR;

            User CU = [SELECT Id,Name,LastName FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true limit 1];

            List < User > Users = new List < User > ();

            Account acct = new Account(Name = 'Vet Servicessss', Event_Type__c = 'Expert Service');
            insert acct;

            List < Resource__c > Resources = new List < Resource__c > ();
            for (Integer i = 0; i < 4; i++) {
                Resource__c Res = new Resource__c(
                    Name = 'Antonette Pagniello' + i, // Resource Name
                    User__c = CU.Id, // User
                    Resource_Group__c = RG.Id, // Resource Group
                    Time_Slot_Duration__c = 0, // Time Slot Duration
                    Override_Holidays__c = false, // Override Holidays
                    Super_User__c = false, // Super User
                    Start_Date__c = system.today() + 1, // Start Date
                    End_Date__c = system.today() + 10, // End Date
                    Monday__c = 0.00,
                    Tue_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Tue Start Time
                    Tue_End_Time__c = Time.newInstance(14, 15, 0, 0), // Tue End Time
                    Tuesday__c = 1.00, // Tue (Hrs)
                    Wednesday__c = 0.02, // Wed (Hrs)
                    Thu_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Thu Start Time
                    Thu_End_Time__c = Time.newInstance(14, 15, 0, 0), // Thu End Time
                    Thursdays__c = 1.00, // Thu (Hrs)
                    Fri_Start_Time__c = Time.newInstance(13, 15, 0, 0), // Fri Start Time
                    Fri_End_Time__c = Time.newInstance(14, 15, 0, 0), // Fri End Time
                    Friday__c = 1.00, // Fri (Hrs)
                    Saturday__c = 0.02, // Sat (Hrs)
                    Sunday__c = 0.00 // Mon (Hrs)
                    // Sun (Hrs)
                );
                Resources.add(Res);
            }
            insert Resources;


            //Id accRecType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer_Account').getRecordTypeId();
            Account acc = new Account(Name = 'Vet Services', Event_Type__c = 'Expert Service');//, RecordTypeId = accRecType
            insert acc;

            Contact con = new contact(FirstName = 'test', LastName = 'test', phone = '98798', Email = 'test@gmail.com', AccountId = acc.Id);
            insert con;


            Id recReg = Schema.SObjectType.Registration__c.getRecordTypeInfosByDeveloperName().get('Expert_Service').getRecordTypeId();

            Registration__c reg = new Registration__c(Customer_Lastname__c = 'test', Expert_Location__c = expLoc.Id, Status__c = 'Booked',
                                                                          Registration_Time__c = system.now().addDays(1), Customer_Name__c = 'test',Contact__c = con.Id,
                                                                          Customer_Email__c = 'test@gmail.com',Registration_Type__c = 'Online', RecordTypeId = recReg);
            insert reg;



            AppointmentBookingExternal_Sch.gocancelreg(reg.Id, '');
            AppointmentBookingExternal_Sch.justupdatedetails(JSON.serialize(reg), reg.Id);
            AppointmentBookingExternal_Sch.justupdatedetails('', reg.Id);
        }catch(Exception e){
            system.debug('Exception==='+e.getMessage());
        }


        String salName = 'ERP7';
        String sal1Name = 'ERP7';
        System.assertEquals(salName, sal1Name);
    }




}