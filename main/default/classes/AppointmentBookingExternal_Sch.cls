public without sharing class AppointmentBookingExternal_Sch {
   public class customException extends Exception {} 
    
    @AuraEnabled 
    public static prodregwrap getAllServicesandReg(String RegId,String ProgId) {
        try{
            String MemProgId = '';
            if(String.isNotEmpty(ProgId)) MemProgId = ProgId;
            prodregwrap prwrap = new prodregwrap();
            
            Registration__c reg = new Registration__c();
            if(Schema.sObjectType.Registration__c.isAccessible() && String.isNotEmpty(RegId)){
                List<Registration__c> tempReglist = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,Membership_Program__c,
                                                               Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Is_Rescheduled__c,
                                                               Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Payment_Status__c,Amount_Paid__c,Cancellation_Reasons__c,
                                                               Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                                               Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                                               Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                                               Account__c, Contact__c, Member__c,Member__r.Assigned_Resource__c,Member__r.Assigned_Resource__r.User__c From Registration__c where ID =:RegId];
                
                if(tempReglist != null && tempReglist.size() > 0){
                    reg = tempReglist[0]; 
                    //if(String.isNotEmpty(serviceId)) reg.Product2__c=serviceId;
                    if(reg.Membership_Program__c != null) MemProgId = reg.Membership_Program__c;
                    prwrap.reg = reg; 
                }
            }
            
            List<prodlistWrapper> prodlistWrapper = new List<prodlistWrapper>();
            date dt = system.today();
            list<Resource_Requirement__c> RRList=new list<Resource_Requirement__c>();
            /* RRList=[SELECT Id, Name, Work_Planner__c,Location__c,Work_Planner__r.Location__c, Resource_Group__c, Work_Planner__r.Location__r.Name,Work_Planner__r.Product__r.Membership_Program__r.Name,
Work_Planner__r.Product__c,Work_Planner__r.Product__r.Membership_Program__c, Work_Planner__r.Product__r.Name,Work_Planner__r.Product__r.Duration__c 
FROM Resource_Requirement__c 
WHERE Work_Planner__r.Location__c!=null AND Work_Planner__c!=null AND Resource_Group__c!=null AND Work_Planner__r.Product__c != null AND Work_Planner__r.Product__r.Membership_Program__c != null 
AND Work_Planner__r.Product__r.Membership_Program__c =: ProgId AND Work_Planner__r.Status__c='Approved' AND Work_Planner__r.Location__r.Active__c=true AND Work_Planner__r.Product__r.IsActive=true 
AND Work_Planner__r.Product__r.Membership_Program__r.Active__c=true 
AND Work_Planner__r.Product__r.Membership_Program__r.End_Date__c >=: dt 
Order By LastModifiedDate]; */
            String Approved = 'Approved';
            //Commented by Abuzar to optimize query Avoid untrusted/unescaped variables in DML query

            // String rrqry = 'SELECT Id, Name, Work_Planner__c,Location__c,Work_Planner__r.Location__c, Resource_Group__c, Work_Planner__r.Location__r.Name,Work_Planner__r.Product__r.Membership_Program__r.Name, '+
            //     'Work_Planner__r.Product__c,Work_Planner__r.Product__r.Membership_Program__c, Work_Planner__r.Product__r.Name,Work_Planner__r.Product__r.Duration__c '+
            //     'FROM Resource_Requirement__c '+
            //     'WHERE Work_Planner__r.Location__c!=null AND Work_Planner__c!=null AND Resource_Group__c!=null AND Work_Planner__r.Product__c != null AND Work_Planner__r.Product__r.Membership_Program__c != null '+
            //     'AND Work_Planner__r.Status__c =: Approved AND Work_Planner__r.Location__r.Active__c=true AND Work_Planner__r.Product__r.IsActive=true '+
            //     'AND Work_Planner__r.Product__r.Membership_Program__r.Active__c=true '+
            //     'AND Work_Planner__r.Product__r.Membership_Program__r.End_Date__c >=: dt ';
            
            // if(String.isNotEmpty(MemProgId)) rrqry += ' AND Work_Planner__r.Product__r.Membership_Program__c =: MemProgId ';
            // rrqry += ' Order By LastModifiedDate ';    
            // RRList = Database.query(rrqry);

            String fieldList = UtilClass_Sch.selectStarFromSObject('Resource_Requirement__c');

String rrqry =
    'SELECT ' + fieldList +
    ', Work_Planner__r.Location__c' +
    ', Work_Planner__r.Location__r.Name' +
    ', Work_Planner__r.Product__r.Membership_Program__r.Name' +
    ', Work_Planner__r.Product__r.Membership_Program__c' +
    ', Work_Planner__r.Product__r.Name' +
    ', Work_Planner__r.Product__r.Duration__c ' +
    'FROM Resource_Requirement__c ' +
    'WHERE Work_Planner__r.Location__c != null ' +
    'AND Work_Planner__c != null ' +
    'AND Resource_Group__c != null ' +
    'AND Work_Planner__r.Product__c != null ' +
    'AND Work_Planner__r.Product__r.Membership_Program__c != null ' +
    'AND Work_Planner__r.Status__c = :approvedStatus ' +
    'AND Work_Planner__r.Location__r.Active__c = true ' +
    'AND Work_Planner__r.Product__r.IsActive = true ' +
    'AND Work_Planner__r.Product__r.Membership_Program__r.Active__c = true ' +
    'AND Work_Planner__r.Product__r.Membership_Program__r.End_Date__c >= :dt';

Map<String, Object> bindVars = new Map<String, Object>{
    'approvedStatus' => Approved, // assuming this is a variable (e.g. picklist value)
    'dt'             => dt       // assuming Date/Datetime variable dt
};

if (String.isNotEmpty(MemProgId)) {
    rrqry += ' AND Work_Planner__r.Product__r.Membership_Program__c = :memProgId';
    bindVars.put('memProgId', MemProgId);
}

rrqry += ' ORDER BY LastModifiedDate';

 RRList =
    (List<Resource_Requirement__c>)Database.queryWithBinds(
        rrqry,
        bindVars,
        AccessLevel.USER_MODE
    );


            system.debug('RRList ~>'+RRList.size());
            
            set<String> RGIdsUser=new set<String>();
            for(Resource_Requirement__c rr:RRList) RGIdsUser.add(rr.Resource_Group__c);
            
            list<Resource__c> ResourceList=new  list<Resource__c>();
            ResourceList= [SELECT Id, Name, Resource_Group__c, Team__c, User__c, Supervisor_User__c, Super_User__c FROM Resource__c
                           WHERE Resource_Group__c IN:RGIdsUser WITH SECURITY_ENFORCED]; 
            system.debug('ResourceList ~>'+ResourceList.size());
            
            RGIdsUser=new set<String>();
            for(Resource__c res:ResourceList) RGIdsUser.add(res.Resource_Group__c);  
            
            list<Resource_Requirement__c> RReqList=new list<Resource_Requirement__c>(); 
            for(Resource_Requirement__c rr:RRList){
                if(RGIdsUser.contains(rr.Resource_Group__c)) 
                    RReqList.add(rr);
            } 
            
            system.debug('RReqList ~>'+RReqList.size());
            
            set<String> LocIds=new set<String>(); 
            set<String> ProdIds=new set<String>();  
            Map<String,Boolean> prodlocmap = new Map<String,Boolean>();
            TimeZone tz = UserInfo.getTimeZone();
            
            String timezonename = ''; 
            
            if(tz != null) timezonename = tz.getDisplayName();
            for(Resource_Requirement__c rr:RReqList){  
                if(rr.Work_Planner__c != null){
                    if(rr.Work_Planner__r.Product__c != null && rr.Work_Planner__r.Product__r.Membership_Program__c != null && rr.Work_Planner__r.Location__c != null ){ //&& rr.Work_Planner__r.Product__c == '01tf4000003PeunAAC'
                        system.debug('prod~>'+rr.Work_Planner__r.Product__c);
                        system.debug('loc~>'+rr.Work_Planner__r.Location__c);
                        String key = ''+rr.Work_Planner__r.Product__c+rr.Work_Planner__r.Location__c+'';
                        system.debug('prodlocmap containsKey~>'+prodlocmap.containsKey(key)); 
                        if(!prodlocmap.containsKey(key)){
                            system.debug('added in');
                            prodlocmap.put(key,true);
                            ProdIds.add(rr.Work_Planner__r.Product__c); 
                            LocIds.add(rr.Work_Planner__r.Location__c); 
                            prodlistWrapper prodWR = new prodlistWrapper();
                            prodWR.ProdId = rr.Work_Planner__r.Product__c;
                            prodWR.ProdName = rr.Work_Planner__r.Product__r.Name;
                            prodWR.MemProgId = rr.Work_Planner__r.Product__r.Membership_Program__c;
                            prodWR.MemProgName = rr.Work_Planner__r.Product__r.Membership_Program__r.Name;
                            prodWR.ProdDuration = rr.Work_Planner__r.Product__r.Duration__c;
                            prodWR.LocId = rr.Work_Planner__r.Location__c;
                            prodWR.LocName = rr.Work_Planner__r.Location__r.Name;
                            prodWR.timezone = timezonename;
                            prodlistWrapper.add(prodWR);
                        }
                    }
                }
            }
            
            Map<id,List<PriceBookEntry>> pbemap = new Map<id,List<PriceBookEntry>>();
            
            for (Product2 p: [SELECT Id, Name, Duration__c,Membership_Program__c, Allow_Multi_Booking__c, Allow_Not_Available_Slot__c, Allow_Not_Available_Day__c, (SELECT Id,UnitPrice,Pricebook2.Name, Pricebook2Id,Product2Id FROM PriceBookEntries WHERE IsActive=true  AND Pricebook2.IsActive =true AND (Pricebook2.IsStandard = false OR Pricebook2.IsStandard = true)) FROM Product2 WHERE ID IN : ProdIds WITH SECURITY_ENFORCED]) {
                if(p.PriceBookEntries.size() > 0) pbemap.put(p.Id, p.PriceBookEntries); 
                for(Integer j=0; j<prodlistWrapper.size(); j++){
                    if(prodlistWrapper[j].ProdId == p.Id){
                        prodlistWrapper[j].Prod = p;
                        if(p.PriceBookEntries.size() > 0){ if(prodlistWrapper[j].ProdId == p.PriceBookEntries[0].Product2Id){ prodlistWrapper[j].FeeAmount = p.PriceBookEntries[0].UnitPrice; 
                            }
                        } 
                    }
                }
            }
            
            for (Expert_Location__c loc: [SELECT Id, Name FROM Expert_Location__c WHERE ID IN : LocIds WITH SECURITY_ENFORCED]) {
                for(Integer j=0; j<prodlistWrapper.size(); j++){
                    if(prodlistWrapper[j].LocId == loc.Id){
                        prodlistWrapper[j].Location = loc;
                    }
                }
            }
            
            prwrap.prodlistwrp = prodlistWrapper;
            return prwrap;} catch (Exception e) { System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    public class prodlistWrapper {
        @AuraEnabled public String ProdName     { get; set; }
        @AuraEnabled public String ProdId     { get; set; }
        @AuraEnabled public String MemProgId     { get; set; }
        @AuraEnabled public String MemProgName     { get; set; }
        @AuraEnabled public Decimal ProdDuration     { get; set; }
        @AuraEnabled public String LocId     { get; set; }
        @AuraEnabled public String LocName     { get; set; }
        @AuraEnabled public String timezone     { get; set; }
        @AuraEnabled public Datetime LocStartTime     { get; set; }
        @AuraEnabled public Date Todaydt     { get; set; }
        //@AuraEnabled public List<PriceBookEntry> pbelist     { get; set; }
        @AuraEnabled public Expert_Location__c Location     { get; set; }
        @AuraEnabled public Product2 prod     { get; set; }
        @AuraEnabled public Decimal FeeAmount     { get; set; }
        
        public prodlistWrapper() {
            ProdName = ProdId = MemProgId = MemProgName = LocId = LocName = '' ;
            ProdDuration = FeeAmount = 0;
            LocStartTime = system.now();
            Todaydt = system.today();
            //pbelist = new List<PriceBookEntry>();
            Location = new Expert_Location__c();
            prod = new Product2();
        }
    } 
    
    public class prodregwrap{
        @AuraEnabled Public Registration__c reg   { get; set;}
        @AuraEnabled Public List<prodlistWrapper> prodlistwrp  { get; set;}
        
        public prodregwrap(){
            reg = new Registration__c();
            prodlistwrp = new List<prodlistWrapper>();
        }
    }
    
    @AuraEnabled
    public static List<OptionWrap> getCancellationReasons(){
        List<OptionWrap> options = new List<OptionWrap>();
        Schema.DescribeFieldResult fieldResult = Registration__c.Cancellation_Reasons__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new OptionWrap('', '--none--'));
        for (Schema.PicklistEntry f: ple) {
            options.add(new OptionWrap(f.getValue(), f.getLabel()));
        }
        return options;
    }
    
    public class OptionWrap{
        @AuraEnabled Public String value   { get; set;}
        @AuraEnabled Public String label   { get; set;}
        
        public OptionWrap(String Id, String lab){
            value = Id;
            label = lab;
        }
    }
    
    /*
@AuraEnabled 
public static ABHome_Sch ClubNewMethodfromAB(String MyTimezone, Date SelectDate, String MyAct, String LId, String SId, String MemberId, String Execute) {
ABHome_Sch es = new ABHome_Sch();
try{
es = ABHome_Sch.ClubNewMethod(MyTimezone,SelectDate,MyAct,LId,SId,MemberId,Execute);
return es;
}catch (Exception e) {  throw new AuraHandledException(e.getMessage());
} 
}

@AuraEnabled 
public static ABHome_Sch getTimeSlotsDoInitfromAB(String LId, String SId, String timezone, String expertId, Boolean AutoResourceAllocation, String MemberId) {

ABHome_Sch es = new ABHome_Sch();
try{
es = ABHome_Sch.getTimeSlotsDoInit(LId,SId,timezone,expertId,AutoResourceAllocation,MemberId);
return es;
}catch (Exception e) {  throw new AuraHandledException(e.getMessage());
} 
}
*/
    
    @AuraEnabled 
    public static List < ABHome_Sch.ResourceWrp >  getUsersByTimeZonefromAB(String LocationId, String ServiceId, String TimeZoneName, String MemberId, Date sDate) {
        List < ABHome_Sch.ResourceWrp > es = new List < ABHome_Sch.ResourceWrp >();
        try{
            es = ABHome_Sch.getUsersByTimeZone(LocationId,ServiceId,TimeZoneName,MemberId,sDate);
            return es; }catch (Exception e) { System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());  throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    @AuraEnabled 
    public static ABHome_Sch getTimeSlotsfromAB(String EId, DateTime selDate, String LId, String sId, String Action, String TimeZoneName, String MemberId) {
        ABHome_Sch es = new ABHome_Sch();
        try{
            es = ABHome_Sch.getTimeSlots(EId,selDate,LId,sId,Action,TimeZoneName,MemberId);
            return es;}catch (Exception e) { System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    
    @AuraEnabled 
    public static ABHome_Sch reservebooking(String selDates, String Resources, String Duration,String locId,String serviceId,String ResourceId,String RId,Boolean isReschedule){
        ABHome_Sch es = new ABHome_Sch();
        try{
            
            List<String> ResourceList = ( List<String>) JSON.deserialize(Resources,   List<String> .class); 
            
            List<DateTime> selTimeList = ( List<DateTime>) JSON.deserialize(selDates,   List<DateTime> .class);
            
            Map<DateTime, String> selTimes =new Map<DateTime, String>();
            for(Integer i = 0; i < selTimeList.size(); i++) selTimes.put(selTimeList[i],ResourceList[i]);
            
            try{ 
                List<Registration__c> Regs2upsert = new List<Registration__c>();
                for(Integer i = 0; i < selTimes.size(); i++){
                    Registration__c tempReg;
                    if(Schema.sObjectType.Registration__c.isCreateable()){
                        if(String.isEmpty(RId)){tempReg = new Registration__c(Registration_Type__c='Online',Is_From_Portal__c=true, Status__c='Reserve', Resource__c=selTimes.get(new List<DateTime>(selTimes.keySet())[i]), Registration_Time__c=new List<DateTime>(selTimes.keySet())[i] ,End_Time__c=new List<DateTime>(selTimes.keySet())[i].addMinutes(Integer.valueOf(Duration))); //,RecordTypeId=rt.Id
                        }else{
                            List<Registration__c> tempReglist = [Select Id, Name, Purpose__c, Information__c,Account__c, Category_of_registration__c, Customer_Email__c,
                                                                           Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Is_Rescheduled__c,
                                                                           Customer_Status__c, Customer_Type__c, Expert__c, Expert_Location__c,Is_Invited_user__c,Cancellation_Reasons__c,
                                                                           Membership_Points__c, Product2__c, Registration_DateD__c,Registration_End_Time__c,Resource__c,Payment_Status__c,Amount_Paid__c,
                                                                           Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c, Registration_DateT__c, Registration_Type__c, 
                                                                           Registration_Time__c, Status__c, Expert_Location__r.Show_Experts__c, Expert_Location__r.Name,  Expert_Location__r.Address__c,
                                                                           Expert_Location__r.City__c, Expert_Location__r.Province_State__c,  Expert_Location__r.Country__c,
                                                                           Expert_Location__r.Zip_Code__c,Meeting_Type__c, Product2__r.Name,Registration__c, End_Time__c 
                                                                           From Registration__c where ID =:RId];
                            if(tempReglist != null && tempReglist.size()>0){
                                tempReg = tempReglist[0]; }else{  tempReg = new Registration__c(Registration_Type__c='Online', Status__c='Reserve', Resource__c=selTimes.get(new List<DateTime>(selTimes.keySet())[i]), Registration_Time__c=new List<DateTime>(selTimes.keySet())[i] ,End_Time__c=new List<DateTime>(selTimes.keySet())[i].addMinutes(Integer.valueOf(Duration))); //,RecordTypeId=rt.Id
                            }
                        }              
                    }
                    
                    if(String.isNotEmpty(locId)) tempReg.Expert_Location__c=locId;
                    if(String.isNotEmpty(serviceId)) tempReg.Product2__c=serviceId;
                    //if(String.isNotEmpty(tempReg.Status__c) && tempReg.Status__c == 'Booked') { tempReg.Is_Rescheduled__c = true; tempReg.Status__c='Reserve'; }
                    if(String.isEmpty(tempReg.Status__c) || tempReg.Status__c == 'Invited') tempReg.Status__c='Reserve';
                    if(isReschedule) tempReg.Is_Rescheduled__c = true;
                    Regs2upsert.add(tempReg); 
                    tempReg.Registration_Time__c=new List<DateTime>(selTimes.keySet())[i]; 
                    tempReg.Resource__c =selTimes.get(new List<DateTime>(selTimes.keySet())[i]); 
                    tempReg.End_Time__c=new List<DateTime>(selTimes.keySet())[i].addMinutes(Integer.valueOf(Duration));
                    es.BSTime = Time.newInstance(tempReg.Registration_Time__c.hour(),tempReg.Registration_Time__c.minute(),0,0);
                    es.BETime = Time.newInstance(tempReg.End_Time__c.hour(),tempReg.End_Time__c.minute(),0,0);
                    
                }
                if(Regs2upsert.size() > 0){  
                    if(Schema.sObjectType.Registration__c.isCreateable()){   
                        if(isReschedule == false) upsert Regs2upsert[0];
                        es.registration=Regs2upsert[0];  
                    }else { throw new customException('No Access to Create Registrations'); }
                } 
            }catch(Exception ex){
                System.debug('Exception ex~> '+ ex.getMessage()+'; at line ~> '+ex.getStackTraceString());
                es.ExpMsg=ex.getMessage()+'  @'+ex.getLineNumber(); es.Registration=null;
                if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') && ex.getMessage().contains('book')) es.ExpMsg=ex.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ',': []');
            }
            return es;
        }catch (Exception e){ 
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    @AuraEnabled
    public static Registration__c cancelreserve(String RegId){ 
        try{
            List<Registration__c> reg=[Select Id, Name, Purpose__c, Information__c,Account__c, Category_of_registration__c, Customer_Email__c,
                                                 Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Is_Rescheduled__c,
                                                 Customer_Status__c, Customer_Type__c, Expert__c, Expert_Location__c,Is_Invited_user__c,Cancellation_Reasons__c,
                                                 Membership_Points__c, Product2__c, Registration_DateD__c,Registration_End_Time__c,Resource__c,Payment_Status__c,Amount_Paid__c,
                                                 Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c, Registration_DateT__c, Registration_Type__c, 
                                                 Registration_Time__c, Status__c, Expert_Location__r.Show_Experts__c, Expert_Location__r.Name,  Expert_Location__r.Address__c,
                                                 Expert_Location__r.City__c, Expert_Location__r.Province_State__c,  Expert_Location__r.Country__c,
                                                 Expert_Location__r.Zip_Code__c,Meeting_Type__c, Product2__r.Name,Registration__c, End_Time__c 
                                                 From Registration__c where id=:RegId AND Status__c = 'Reserve'];
            if(reg.size()>0){
                
                if(reg[0].Is_Invited_user__c){
                    
                    reg[0].Registration_DateD__c = null;
                    reg[0].Registration_Time__c = null;
                    reg[0].End_Time__c = null;
                    reg[0].Registration_DateT__c = null;
                    reg[0].Registration_End_Time__c = null;
                    reg[0].Is_Rescheduled__c = false;
                    reg[0].Resource__c = null;
                    update reg[0];
                    return reg[0];
                }else{  /*delete reg;*/ Database.delete( reg,  false,AccessLevel.USER_MODE);

   return new Registration__c(); } }else return null; }catch (Exception e) {   System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    @AuraEnabled
    Public static Registration__c fetchregdetails(String RegId,String serviceId){ 
        try{
            Registration__c reg = new Registration__c();
            if(Schema.sObjectType.Registration__c.isAccessible() && String.isNotEmpty(RegId)){
                List<Registration__c> tempReglist = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,Membership_Program__c,
                                                               Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Is_Rescheduled__c,
                                                               Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Payment_Status__c,Amount_Paid__c,Cancellation_Reasons__c,
                                                               Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                                               Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                                               Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                                               Account__c, Contact__c, Member__c,Member__r.Assigned_Resource__c,Member__r.Assigned_Resource__r.User__c 
                                                               From Registration__c where ID =:RegId];
                if(tempReglist != null && tempReglist.size()>0){ reg = tempReglist[0]; if(String.isNotEmpty(serviceId)) reg.Product2__c=serviceId; return reg; }else return null; }else return null;
        }catch (Exception e) {System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }   
    }
    
    
   /* @AuraEnabled
    public static Registration__c getConfirmBooking(String RegJSON){  
        try{ 
            if(String.isNotEmpty(RegJSON)){
                Registration__c Reg1 = (Registration__c) JSON.deserialize(RegJSON, Registration__c.class);
                upsert Reg1;
                Registration__c Reg = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                                                 Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Payment_Status__c,
                                                 Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Is_Rescheduled__c,Amount_Paid__c,Cancellation_Reasons__c,
                                                 Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                                 Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                                 Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                                 Account__c, Contact__c, Member__c 
                                                 From Registration__c  WHERE ID = : Reg1.Id Limit 1];
                Reg.Is_Invited_user__c = true; update Reg;
                list<Registration__c> BookedRegList=new  list<Registration__c>();
                BookedRegList=[SELECT Id, name, Registration_Time__c, Resource__c, Resource__r.User__c, Status__c
                               FROM Registration__c Where Resource__c = :Reg.Resource__c And Registration_Time__c=:Reg.Registration_Time__c 
                               And (Status__c = 'Booked' Or Status__c = 'Waiting' Or Status__c ='Invited') ORDER BY Registration_Time__c];                                        
                String OldId = ''; if(BookedRegList.size()>0) OldId=BookedRegList[0].Id;
                
                if(BookedRegList.size()>0 && OldId!=Reg.Id){ throw new customException('Sorry, this slot has just been booked.  Please choose another time slot.'); }
                
                return Reg; }else{ throw new customException('Attempt to deference null object'); }
        } catch(Exception e){
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }     
    }*/
    
    @AuraEnabled
    public static Registration__c getConfirmBooking(String RegJSON){  
        try{ 
            if (String.isNotEmpty(RegJSON)) {
                Registration__c Reg1 = (Registration__c) JSON.deserialize(RegJSON, Registration__c.class);
                
                List<Contact> conList = new List<Contact>();
                
                if (Reg1.Contact__c == null) {
                    if (Reg1.Customer_Contact__c != null) {
                        conList = [
                            SELECT Id, Name, Phone, MobilePhone, Email 
                            FROM Contact  
                            WHERE MobilePhone = :Reg1.Customer_Contact__c 
                            OR Email = :Reg1.Customer_Email__c
                            WITH SECURITY_ENFORCED
                            LIMIT 1
                        ];
                    } else {
                        conList = [
                            SELECT Id, Name, Phone, MobilePhone, Email 
                            FROM Contact  
                            WHERE Email = :Reg1.Customer_Email__c
                            WITH SECURITY_ENFORCED LIMIT 1
                        ];
                    }
                    
                    if (!conList.isEmpty()) {
                        Reg1.Contact__c = conList[0].Id;
                    } else {
                         Account acc = new Account();
            if (Schema.sObjectType.Account.fields.Name.isCreateable()) {
                acc.Name = (Reg1.Customer_Name__c != null ? Reg1.Customer_Name__c : 'New Customer') 
                          + ' ' + (Reg1.Customer_Lastname__c != null ? Reg1.Customer_Lastname__c : '');
            }
            if (Schema.sObjectType.Account.fields.Phone.isCreateable()) {
                acc.Phone = Reg1.Customer_Contact__c;
            }
            if (Schema.sObjectType.Account.fields.SCH_Email__c != null && Schema.sObjectType.Account.fields.SCH_Email__c.isCreateable()) {
                // if it's a Person Account org
                acc.SCH_Email__c = Reg1.Customer_Email__c;
            }

            if (Schema.sObjectType.Account.isCreateable()) {
                insert acc;
            }

                        Contact c = new Contact();
                        
                        if (Schema.sObjectType.Contact.fields.FirstName.isCreateable()) {
                            c.FirstName = Reg1.Customer_Name__c;
                        }
                        if (Schema.sObjectType.Contact.fields.LastName.isCreateable()) {
                            c.LastName = Reg1.Customer_Lastname__c;
                        }
                        if (Schema.sObjectType.Contact.fields.MobilePhone.isCreateable()) {
                            c.MobilePhone = Reg1.Customer_Contact__c;
                        }
                        if (Schema.sObjectType.Contact.fields.Email.isCreateable()) {
                            c.Email = Reg1.Customer_Email__c;
                        }
                        if (Schema.sObjectType.Contact.fields.IsRegistrationContact__c.isCreateable()) {
                            c.IsRegistrationContact__c = true;
                        }
                        if (Schema.sObjectType.Contact.fields.AccountId.isCreateable()) {
                c.AccountId = acc.Id;
            }
                        
                        if (Schema.sObjectType.Contact.isCreateable()) {
                            insert c;
                            Reg1.Contact__c = c.Id; // only assign here if inserted
                        }
                    }
                }
                
                // upsert Reg1;
                Database.upsert(
    Reg1,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                
            
            Registration__c Reg = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                                   Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Payment_Status__c,
                                   Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Is_Rescheduled__c,Amount_Paid__c,Cancellation_Reasons__c,
                                   Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                   Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                   Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                   Account__c, Contact__c, Member__c 
                                   From Registration__c  WHERE ID = : Reg1.Id Limit 1];
            Reg.Is_Invited_user__c = true;
            //  update Reg;
            Database.update(
    Reg,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
            list<Registration__c> BookedRegList=new  list<Registration__c>();
            BookedRegList=[SELECT Id, name, Registration_Time__c, Resource__c, Resource__r.User__c, Status__c
                           FROM Registration__c Where Resource__c = :Reg.Resource__c And Registration_Time__c=:Reg.Registration_Time__c 
                           And (Status__c = 'Booked' Or Status__c = 'Waiting' Or Status__c ='Invited') ORDER BY Registration_Time__c];                                        
            String OldId = ''; if(BookedRegList.size()>0) OldId=BookedRegList[0].Id;
            
            if(BookedRegList.size()>0 && OldId!=Reg.Id){ throw new customException('Sorry, this slot has just been booked.  Please choose another time slot.'); }
            
            return Reg; }else{ throw new customException('Attempt to deference null object'); }  } catch(Exception e){System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
    }     
}
    
    
    @AuraEnabled
    public static Registration__c  CreateRegInvite(String ClientId,String MemberId,String RegJSON){
        try{
            if(String.isNotEmpty(RegJSON)){
                Registration__c  Reg = (Registration__c) JSON.deserialize(RegJSON, Registration__c.class);
                Registration__c  RegNew = new Registration__c();
                RegNew.Status__c = 'Invited';
                RegNew.Is_Invited_user__c = true;
                if(Reg.Product2__c != null){ RegNew.Product2__c = Reg.Product2__c; }
                if(Reg.Expert_Location__c != null){ RegNew.Expert_Location__c = Reg.Expert_Location__c; }
                if(Reg.Membership_Program__c != null){ RegNew.Membership_Program__c = Reg.Membership_Program__c; }
                
                if(String.isNotEmpty(ClientId)){ RegNew.Contact__c = ClientId; }
                if(String.isNotEmpty(MemberId)){ RegNew.Member__c = MemberId; }
                Contact con = new Contact();
                if(RegNew.Member__c != null){
                    Member__c mem = [Select Id,Name,Assigned_Contact__c,Assigned_Resource__c from Member__c where Id =:RegNew.Member__c AND Assigned_Contact__c != null WITH SECURITY_ENFORCED LIMIT 1];
                    if(mem != null){
                        if(mem.Assigned_Contact__c != null){
                            RegNew.Contact__c = mem.Assigned_Contact__c;
                            con = [Select Id,FirstName,LastName,Email,Phone,MobilePhone from Contact where Id =:mem.Assigned_Contact__c LIMIT 1];
                        }
                    }
                }else if(RegNew.Contact__c != null){
                    con = [Select Id,FirstName,LastName,Email,Phone,MobilePhone from Contact where Id =:RegNew.Contact__c LIMIT 1];
                }
                if(con.Id != null){
                    if(String.isNotEmpty(con.FirstName)) RegNew.Customer_Name__c = con.FirstName;
                    if(String.isNotEmpty(con.LastName)) RegNew.Customer_Lastname__c = con.LastName;
                    if(String.isNotEmpty(con.Email)) RegNew.Customer_Email__c = con.Email;
                    if(String.isNotEmpty(con.Phone)) RegNew.Customer_Contact__c = con.Phone; else if(String.isNotEmpty(con.MobilePhone)) RegNew.Customer_Contact__c = con.MobilePhone;
                }
                // upsert RegNew;
                Database.upsert(
    RegNew,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                return RegNew; }else return null; } catch (Exception e) {  System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }   
    }
    
    @AuraEnabled
    public static Registration__c  gocancelreg(String RId,String reason) {
        try{
            if(String.isNotEmpty(RId)){
                Registration__c Reg = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                                                 Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Payment_Status__c,
                                                 Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Is_Rescheduled__c,Amount_Paid__c,Cancellation_Reasons__c,
                                                 Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                                 Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                                 Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                                 Account__c, Contact__c, Member__c From Registration__c  WHERE ID = : RId Limit 1];
                Reg.Status__c = 'Cancelled';
                if(String.isNotEmpty(reason)) Reg.Cancellation_Reasons__c = reason;
                // update Reg;
                Database.update(
    Reg,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                return  Reg; }else return null; } catch (Exception e) {  System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }   
    }
    
    @AuraEnabled
    public static Registration__c justupdatedetails(String RegJSON,String RId){
        try{ 
            if(String.isNotEmpty(RegJSON)){
                Registration__c Reg1 = (Registration__c) JSON.deserialize(RegJSON, Registration__c.class);
                if(String.isNotEmpty(RId)){
                   /* Registration__c Reg = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                                                     Information__c From Registration__c  WHERE ID = : RId Limit 1];
                    Reg.Customer_Name__c = Reg1.Customer_Name__c;
                    Reg.Customer_Lastname__c = Reg1.Customer_Lastname__c;
                    Reg.Customer_Email__c = Reg1.Customer_Email__c;
                    Reg.Customer_Contact__c = Reg1.Customer_Contact__c;
                    Reg.Information__c = Reg1.Information__c;
                    
                    update Reg;
					*/
                    // upsert Reg1;
                    Database.upsert(
    Reg1,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                    Registration__c updatedReg = [Select Id, Name,Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                                                            Category_of_registration__c,Customer_Status__c, Customer_Type__c,Registration_Type__c,Information__c,Is_Invited_user__c,Payment_Status__c,
                                                            Registration_Price__c,Total_Registration_Price__c, Discount__c, Total_Due__c, Total_Due_Amount__c,Total_Tax_Amount__c,Is_Rescheduled__c,Amount_Paid__c,Cancellation_Reasons__c,
                                                            Expert_Location__c,Expert_Location__r.Name,  Expert_Location__r.Address__c,Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Zip_Code__c,  Expert_Location__r.Country__c,
                                                            Product2__c,Product2__r.Name, Product2__r.Session_Duration__c,Product2__r.Duration__c,Product2__r.Membership_Program__c,
                                                            Resource__c,Resource__r.Name,Resource__r.User__c,Resource__r.User__r.Name,
                                                            Account__c, Contact__c, Member__c 
                                                            From Registration__c  WHERE ID = : Reg1.Id Limit 1];
                    return updatedReg;  }else{ throw new customException('Attempt to deference null object'); }
            }else{ throw new customException('Attempt to deference null object'); }
        } catch(Exception e){ 
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }     
    }
    
    @AuraEnabled
    public static String getCheckInByRegNo(String RegNo){
        try{
            String response = 'Failed';
            List<Registration__c> regs = new List<Registration__c>();
            Date todaydt = system.today();
            
            regs = [Select Id, Name, Status__c,Registration_Time__c,End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,Customer_Email__c,
                    Customer_Status__c, Check_In__c, Appointment_DateDt__c,
                    Expert_Location__c, Expert_Location__r.Name,
                    Product2__c, Product2__r.Name, Queue__c, Booked_Current_Status__c, Checked_in_Date_Time__c, Token_Number__c, 
                    Resource__c, Resource__r.Name, Resource__r.User__c,Resource__r.User__r.Name,
                    Account__c, Contact__c, Member__c 
                    From Registration__c WHERE Name =: RegNo AND Status__c = 'Booked' AND Expert_Location__c != null AND Product2__c != null AND Resource__c != null AND 
                    Registration_Time__c >=: system.now() AND Appointment_DateDt__c =:todaydt Limit 1]; 
            
            if(regs.size() > 0){
                Registration__c reg2Update = regs[0];
                List<Queue__c> queuforEvent=[Select id from Queue__c where Location__c =: reg2Update.Expert_Location__c AND Status__c='Active'  WITH SECURITY_ENFORCED]; 
                
                if(queuforEvent.size() > 0){
                    List<Registration__c> records = [Select Id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,
                                                               Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Booked_Current_Status__c,
                                                               Product2__r.Name, Company__c,Product2__r.Wait_Threshold__c,
                                                               Resource__r.Time_Slot_Duration__c,waiting_Time__c,Booked_Date__c, Checked_in_Date_Time__c
                                                               From Registration__c where Status__c='Booked' 
                                                               AND Expert_Location__c=:reg2Update.Expert_Location__c AND  Appointment_DateDt__c = Today //And  Product2__c =:service AND Resource__c=:resource
                                                               AND Check_In__c=True Order by Booked_Date__c ASC ];
                    
                    integer recSize = records.size()+1;
                    if(recSize<=9){ 
                        reg2Update.Token_Number__c='0'+String.valueof(recSize); 
                    }else{
                        reg2Update.Token_Number__c=String.valueof(recSize);  
                    }
                    
                    reg2Update.Queue__c=queuforEvent[0].Id;
                    reg2Update.Status__c='Booked';
                    reg2Update.Booked_Current_Status__c='NotInProgress';
                    //reg2Update.Booked_Date__c=System.now();
                    reg2Update.Checked_in_Date_Time__c=System.now();
                    reg2Update.Check_In__c=True;
                    reg2Update.Customer_Status__c='Attended';
                }
                
                // update reg2Update;
                Database.update(
    reg2Update,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                response = 'Success';
            }
            return response; }catch(Exception e){System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString()); throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static String getCheckInByRegDetails(String FirstName, String LastName, String Email, String Phone){
        try{
            String response = 'Failed';
            List<Registration__c> regs = new List<Registration__c>();
            Datetime now = system.now();
            String Booked = 'Booked';
            Date todaydt = system.today();
            
            String qry = ' Select Id, Name, Status__c, Registration_Time__c, End_Time__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c, Customer_Email__c, ';
            qry += ' Customer_Status__c,Appointment_DateDt__c, ';
            qry += ' Expert_Location__c, Expert_Location__r.Name, ';
            qry += ' Product2__c, Product2__r.Name, Queue__c, Booked_Current_Status__c, Checked_in_Date_Time__c, Check_In__c, Token_Number__c, ';
            qry += ' Resource__c, Resource__r.Name, Resource__r.User__c,Resource__r.User__r.Name, ';
            qry += ' Account__c, Contact__c, Member__c ';
            qry += ' From Registration__c WHERE Status__c =:Booked AND Expert_Location__c != null AND Product2__c != null AND Resource__c != null AND ';
            if(String.isNotEmpty(FirstName)) qry += ' Customer_Name__c =: FirstName AND ';
            if(String.isNotEmpty(LastName)) qry += ' Customer_Lastname__c =: LastName AND ';
            if(String.isNotEmpty(Email)) qry += ' Customer_Email__c =: Email AND ';
            if(String.isNotEmpty(Phone)) qry += ' Customer_Contact__c =: Phone AND ';
            qry += ' Registration_Time__c >=: now AND Appointment_DateDt__c =:todaydt Limit 1 ';
            
            system.debug('qry~>'+qry);
            
            regs = database.query(qry);
            
            if(regs.size() > 0){
                Registration__c reg2Update = regs[0];
                List<Queue__c> queuforEvent=[Select id from Queue__c where Location__c =: reg2Update.Expert_Location__c AND Status__c='Active' WITH SECURITY_ENFORCED]; 
                
                if(queuforEvent.size() > 0){
                    List<Registration__c> records = [Select Id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,
                                                               Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Booked_Current_Status__c,
                                                               Product2__r.Name, Company__c,Product2__r.Wait_Threshold__c,
                                                               Resource__r.Time_Slot_Duration__c,waiting_Time__c,Booked_Date__c, Checked_in_Date_Time__c
                                                               From Registration__c where Status__c='Booked' 
                                                               AND Expert_Location__c=:reg2Update.Expert_Location__c AND  Appointment_DateDt__c = Today //And  Product2__c =:service AND Resource__c=:resource
                                                               AND Check_In__c=True Order by Booked_Date__c ASC ];
                    
                    integer recSize = records.size()+1;
                    if(recSize<=9){ 
                        reg2Update.Token_Number__c='0'+String.valueof(recSize); 
                    }else{
                        reg2Update.Token_Number__c=String.valueof(recSize);  
                    }
                    
                    reg2Update.Queue__c=queuforEvent[0].Id;
                    reg2Update.Status__c='Booked';
                    reg2Update.Booked_Current_Status__c='NotInProgress';
                    //reg2Update.Booked_Date__c=System.now();
                    reg2Update.Checked_in_Date_Time__c=System.now();
                    reg2Update.Check_In__c=True;
                    reg2Update.Customer_Status__c='Attended';
                }
                
                // update reg2Update;
                Database.update(
    reg2Update,
    false,                  // allOrNone
    AccessLevel.USER_MODE   // 🔥 new security standard
);
 
                response = 'Success';
            }
            return response; }catch(Exception e){System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
    }
    

}