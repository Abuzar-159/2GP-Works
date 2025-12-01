public with sharing class Queue_Expert_Sch   {
    public Queue_Expert_Sch(){
        
    }
    
    @AuraEnabled
    public static Wrapper updateRecordValues(String Id, String recValues,String userID, String recordType,String queueId,String accountId, String event, String location,DateTime sDate, DateTime eDate) {
        Wrapper wrapper=new Wrapper();
        List<String> recordValues=new List<String>();
        try{
            recordValues= (List<String>)JSON.deserialize(recValues, List<String> .class); integer recsize=recordValues.Size(); system.debug('Enter getValuesOfId');  Registration__c registrationToUpdate; registrationToUpdate = [SELECT id, Name, OwnerId,Product2__c,Wait_Time_Exceeded__c,Resource__c, RecordTypeId, Account__c,Account__r.Name, Event__c, Expert_Location__c, Company__c, Ticket__c, Customer_Status__c,Is_Amount_Refunded__c, Twilio_Message__c, Queue__c,Queue__r.Name, Customer_Type__c, Status__c, Registration_Type__c,Registration_Time__c, Registration_End_Time__c, End_Time__c,  Meeting_Status__c, Meeting_outcome__c,Purpose__c, Customer_Name__c, Customer_Lastname__c, Customer_Email__c, Customer_Contact__c, Registration_Price__c, Total_Tax_Amount__c, Discount__c, LastModifiedDate,waiting_Time__c,Booked_Current_Status__c FROM Registration__c WHERE id=: Id]; registrationToUpdate.Customer_Status__c=recordValues[0];System.debug('customer-status'+recordValues[0]); /*registrationToUpdate.Registration_Time__c= sDate;*/ DateTime newDateTime = (Datetime.now()).addMinutes(40);  /* registrationToUpdate.End_Time__c=eDate;*/  registrationToUpdate.Customer_Type__c=recordValues[1];   registrationToUpdate.Registration_Type__c=recordValues[2]; registrationToUpdate.Meeting_Status__c=recordValues[3]; registrationToUpdate.Meeting_outcome__c=recordValues[4];  registrationToUpdate.Purpose__c=recordValues[5]; registrationToUpdate.Customer_Name__c=recordValues[6];  registrationToUpdate.Customer_Lastname__c=recordValues[7]; registrationToUpdate.Customer_Email__c=recordValues[8];    registrationToUpdate.Customer_Contact__c=recordValues[9]; if(recordValues.size()>=15) registrationToUpdate.Status__c='Completed';/*recordValues[14];*/ if(recordValues.size()>=16) { if(recordValues[15]=='') recordValues[15]=null; registrationToUpdate.Contact__c=recordValues[15]; } update registrationToUpdate; System.debug('registrationToUpdate123->'+registrationToUpdate); return wrapper;    
        } catch(Exception e){ system.debug('Exception ==>'+e);wrapper.errmsg=String.valueof(e); return wrapper; }                                  
    }
    
   
    
    @AuraEnabled
    public static List<String> getFieldsSetApiName(String sObjectName,string fieldSetApiName){
        List<String> fields = new List<String>();
        for(Schema.FieldSetMember field:
            schema.getGlobalDescribe().get(sObjectName).getDescribe().fieldSets.getMap().get(fieldSetApiName).getFields())
            fields.add(field.getFieldPath());
        return fields;
    }
    
    @AuraEnabled 
    public static wrapper getFilterValues(String loc,String ser,String res,String event,String rtype){
        Wrapper wrapper=new Wrapper();
        if(loc!=null && ser!=null){
            wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c where Location__c=:loc AND   Product__c=:ser ]; }
        else if(loc!=null && event!=null){wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c where Location__c=:loc AND Event__c=:event]; }
        else if(loc!=null && ser==null && event==null){
            wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c where Location__c=:loc ]; } else{ wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c]; }        
        set<String> WPIds=new set<String>();
        for(integer i=0;i<=wrapper.WP.size()-1;i++) { WPIds.add(wrapper.WP[i].Id); }
        if(res!=null){
            wrapper.RR=[Select Id,Resource_Group__c, Name,Preferred_Resource__c,Work_Planner__c,Work_Planner__r.Location__c,
                        Work_Planner__r.Product__c, Work_Planner__r.Event__c From Resource_Requirement__c Where  Work_Planner__c IN:WPIds AND Preferred_Resource__c=:res]; }
        else {
            wrapper.RR=[Select Id, Name,Preferred_Resource__c,Resource_Group__c,Work_Planner__c,Work_Planner__r.Location__c,
                        Work_Planner__r.Product__c,Work_Planner__r.Event__c From Resource_Requirement__c Where  Work_Planner__c IN:WPIds ];}
        set<String> RRLoc=new set<String>();
        for(integer i=0;i<=wrapper.RR.size()-1;i++)  {
            RRLoc.add(wrapper.RR[i].Work_Planner__r.Location__c);
            wrapper.allServices.add(wrapper.RR[i].Work_Planner__r.Product__c) ;
            wrapper.allresources.add(wrapper.RR[i].Preferred_Resource__c) ; 
        }
        return wrapper;
        
    }
    
    @AuraEnabled
    public static Wrapper getExpertsByLoc(String locID){
        Wrapper wrapper=new Wrapper();  wrapper filtervalues=getFilterValues(locID,null,null,null,null); 
        for(integer i=0;i<=filtervalues.RR.size()-1;i++){ wrapper.allresources.add(filtervalues.RR[i].Preferred_Resource__c); } 
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getServices(String location,String Program,String resource){ 
        system.debug('Program==>'+Program+' '+location);
        Wrapper wrapper=new Wrapper();
        if(resource!=null && resource!=''){
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
            wrapper filterwrap=getFilterValues(location,null,Resource,null,null);
            wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            List<Queue_Allocation__c> serOFQLA=[Select Id,Service__c From Queue_Allocation__c where Resource__c=:Resource AND Queue__r.Location__c=:location AND Queue__r.Status__c='Active' AND Active__c=True  ];
            Set<String> QALSer=new Set<String>(); for(integer i=0;i<serOFQLA.size();i++){QALSer.add(serOFQLA[i].Service__c);} 
            Set<String> filSer=new set<String>(); filSer=filterwrap.allServices;   for(String ser:QALSer) { if(filSer.contains(ser)){wrapper.allServices.add(ser);} } 
            List<Product2> forPrograms=[Select id from Product2 where id IN : wrapper.allServices AND Membership_Program__c=:Program];
            wrapper.allServices.clear();
            for(Product2 forService : forPrograms){
                wrapper.allServices.add(forService.id);
            }
            
        }else{
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];   wrapper filterwrap=getFilterValues(location,null,null,null,null);  wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            List<Queue__c> queueOfloc=[Select Id From Queue__c where Location__c=:location AND Status__c='Active'];
            set<String> qIDS=new set<String>(); for(integer i=0;i<=queueOfloc.size()-1;i++) {  qIDS.add(queueOfloc[i].Id); }  List<Queue_Allocation__c> serOFQLA=[Select Service__c From Queue_Allocation__c where Queue__c IN : qIDS AND Active__c=true];
            Set<String> serFromQLA=new Set<String>();
            for(integer i=0;i<=serOFQLA.size()-1;i++) { serFromQLA.add(serOFQLA[i].Service__c); }  
            set<String> filSer=new set<String>(); filSer=filterwrap.allServices;  
            for(String ser:serFromQLA) { if(filSer.contains(ser)){wrapper.allServices.add(ser);} } 
            List<Product2> forPrograms=[Select id from Product2 where id IN : wrapper.allServices AND Membership_Program__c=:Program];
            wrapper.allServices.clear();
            for(Product2 forService : forPrograms){
                wrapper.allServices.add(forService.id);
            }
        }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getlookups(String location,String Resource){
        wrapper wrapper=new wrapper(); 
        if(Resource!=null && Resource!=''){
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
            wrapper filterwrap=getFilterValues(location,null,Resource,null,null);
            wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            List<Queue_Allocation__c> serOFQLA=[Select Id,Service__c From Queue_Allocation__c where Resource__c=:Resource AND Queue__r.Location__c=:location AND Queue__r.Status__c='Active' AND Active__c=True  ];
            Set<String> QALSer=new Set<String>(); for(integer i=0;i<serOFQLA.size();i++){QALSer.add(serOFQLA[i].Service__c);} 
            Set<String> filSer=new set<String>(); filSer=filterwrap.allServices;   for(String ser:QALSer) { if(filSer.contains(ser)){wrapper.allServices.add(ser);} } 
            List<Product2> forPrograms=[Select id,Membership_Program__c from Product2 where id IN : wrapper.allServices AND Membership_Program__c!=null];
            for(integer i=0;i<forPrograms.size();i++){   wrapper.programs.add(forPrograms[i].Membership_Program__c);  }  }else{  List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location]; wrapper filterwrap=getFilterValues(location,null,null,null,null);  wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ];  List<Queue__c> queueOfloc=[Select Id From Queue__c where Location__c=:location AND Status__c='Active']; set<String> qIDS=new set<String>(); for(integer i=0;i<=queueOfloc.size()-1;i++) {  qIDS.add(queueOfloc[i].Id); } List<Queue_Allocation__c> serOFQLA=[Select Service__c From Queue_Allocation__c where Queue__c IN : qIDS AND Active__c=true]; Set<String> serFromQLA=new Set<String>();for(integer i=0;i<=serOFQLA.size()-1;i++) { serFromQLA.add(serOFQLA[i].Service__c); }   set<String> filSer=new set<String>(); filSer=filterwrap.allServices;   for(String ser:serFromQLA) { if(filSer.contains(ser)){wrapper.allServices.add(ser);} } List<Product2> forPrograms=[Select id,Membership_Program__c from Product2 where id IN : wrapper.allServices AND Membership_Program__c!=null]; system.debug('forPrgrams==>'+forPrograms);  for(integer i=0;i<forPrograms.size();i++){ wrapper.programs.add(forPrograms[i].Membership_Program__c); }
        } 
        return wrapper;
    }
    
    @AuraEnabled 
    public static wrapper initSetUp(){
        Wrapper wrapper=new Wrapper();
        try{
        String userid=UserInfo.getUserId();
        System.debug('current user->'+userid);
        User usr=new User();
        if(String.isNotEmpty(userid)) usr=[SELECT Id, Name FROM User WHERE Id=:userid]; 
        if(usr.Name!=null) wrapper.SelectedUserName=usr.Name;
        System.debug('usr->'+usr);
        
        List<Registration__c> records=new List<Registration__c>();
        Wrapper forAllRegRecords=getRecordsOfLocationsonLoad(null, null,null,null,null,'Check In Appointments'); 
        
        records=forAllRegRecords.records;
        wrapper.appointmentFiler='Check In Appointments';
        System.debug('records size->'+records.size());
        if(records.size()<=0){
            forAllRegRecords=getRecordsOfLocationsonLoad(null, null,null,null,null,'Todays Appointments');
            System.debug('inside->'+records.size());
            wrapper.appointmentFiler='Todays Appointments';
        }
        system.debug('appointmentFiler : '+wrapper.appointmentFiler);
        records=forAllRegRecords.records;
        System.debug('forAllRegRecords->'+forAllRegRecords);
        System.debug('records size->'+records.size()); 
        for(Integer z=0;z<records.size();z++){
            System.debug('z->'+records[z]);
        }
        
        System.debug('records->'+records);
        integer rsize=records.Size();
        if(rsize<=0) {wrapper.existLocation=true;}
        for(integer i=0;i<=rsize-1;i++) {  if(records[i].Booked_Current_Status__c=='InProgress'){  wrapper.ObjectValues.add(records[i]); wrapper.inProgress=true;}
                                        }
        system.debug('wrapper.ObjectValues==>'+wrapper.ObjectValues);
        if(wrapper.ObjectValues.size()>=1){  wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc]; wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment  Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];  wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];  wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId]; }
        for(integer index=0;index<rsize;index++)  { wrapper.mapOfRecords.put(String.valueof(index), records[index]); }
        //Wrapper.QueueFields=getFieldsSetApiName('Registration__c','Work_Bench_Filed_Set'); 
        Wrapper.appointmentFields=getFieldsSetApiName('Registration__c','WB_Appointment_Details');
        Wrapper.customerFields=getFieldsSetApiName('Registration__c','WB_Customer_Details');
        Wrapper.meetingFields=getFieldsSetApiName('Registration__c','WB_Meeting_Details');
        
        wrapper.allCategory.add(new selectOptions('Todays Appointments', 'Todays Appointments'));
        wrapper.allCategory.add(new selectOptions('Check In Appointments', 'Check In Appointments'));
        wrapper.allCategory.add(new selectOptions('Future Appointments', 'Future Appointments'));
        wrapper.allCategory.add(new selectOptions('Past Appointments', 'Past Appointments'));
        wrapper.allCategory.add(new selectOptions('Completed Appointments', 'Completed Appointments'));system.debug('QueueFields==>'+wrapper.QueueFields); system.debug('wrapper.regRecords==>'+wrapper.regRecords); }catch(Exception e){
            system.debug('Exception~>'+e.getMessage()+'at ~>'+e.getStackTraceString());
        }
        return wrapper;
    }
    
    @AuraEnabled
    public static wrapper getRecordsOfLocationsonLoad(String location, String service, String resource,String program,String Team,String catValue) {   
        System.debug('getRecordsOfLocations is called'+program+' , '+catValue);
        system.debug('location=>'+location+', service==>'+service+' ,resource=>'+resource+' ,program=>'+program+' , team=>'+Team);
        String ser,res,checkLoc,prgrm,teamID;
        
        // Resource__c r=[SELECT Id,User__c, Name FROM Resource__c WHERE User__c=:userid limit 1];
        
        Wrapper wrapper=new Wrapper();
        // try{
        if(location=='' || location==null){checkLoc=null;} else{checkLoc=location;}
        if(service==''  || service==null){ ser=null;}else{ser=service;}  
        if(resource=='' || resource==null){res=null;}else{res=resource;}
        if(program==''  || program==null){prgrm=null;}else{prgrm=program;}
        if(Team=='' || Team==null){teamID=null;}else{teamID=Team;}
        system.debug('location=>'+checkLoc+', service==>'+ser+' ,resource=>'+res+' ,program=>'+prgrm+' , team=>'+teamID);
        DateTime nowTime=system.now() ; 
        String allFields = UtilClass_Sch.selectStarFromSObject('Registration__c');
        
        
        
        String Query=' Select '+ allFields +' ,Resource__r.User__c, Account__r.Flagged__c,Contact__r.Flagged__c, Product2__r.Wait_Threshold__c,Contact__r.Name  From  Registration__c where   Product2__c!=null   AND Resource__c!=null ';// AND Resource__c!=null, 
        if(catValue=='Check In Appointments'){
            Query +=' AND Appointment_DateDt__c = Today AND Status__c=\'Booked\' AND Check_In__c=True ';
        }else if(catValue=='Todays Appointments'){
            Query +=' AND Appointment_DateDt__c = Today AND Status__c=\'Booked\' AND  Registration_Time__c >=: nowTime ';}else if(catValue=='Past Appointments'){ Query +='  AND Check_In__c=False AND Registration_Time__c <=: nowTime '; }else if(catValue=='Completed Appointments'){ Query +=' AND Status__c=\'Completed\' '; }else if(catValue=='Future Appointments'){ Query +=' AND Appointment_DateDt__c >Today AND Status__c=\'Booked\' AND  Registration_Time__c >=: nowTime ';
        }  
        if(checkLoc!=null)Query +=' AND Expert_Location__c=:checkLoc ';
        if(ser!=null)Query +=' AND Product2__c=:ser ';
        if(prgrm!=null)Query +=' AND Membership_Program__c=:prgrm ';
        if(teamID!=null)Query +=' AND Resource__r.Team__c=:teamID ';
        
        // User__c
        Id userid=UserInfo.getUserId();
        System.debug('res123->'+userid);
        res=userid;
        if(res!=null){
            //Query +=' AND Resource__c=:res ';
            //Query +=' AND (Resource__c=:res OR Resource__c=null) ';
            Query +=' AND (Resource__r.User__c=:res OR Resource__r.User__c=null) ';  
            //Resource__c ResourceRecord=[Select Id, Name, User__c FROM Resource__c WHERE Id=:res];
            //if(ResourceRecord.Name!=null) wrapper.SelectedUserName=ResourceRecord.Name;  
            User usr=new User();  
            if(res!=null) 
                if(usr.Name!=null) wrapper.SelectedUserName=usr.Name; }else{User usr=[SELECT Id, Name FROM User WHERE Id=:userInfo.getUserId()]; if(usr.Name!=null) wrapper.SelectedUserName=usr.Name; 
        }
        
        /*
List<Resource__c> userRes=[Select id,Resource_Group__c from Resource__c where Supervisor__c=true and  User__c=:UserInfo.getUserId()]; 
system.debug('userRes==>'+userRes);
set<String> resids=new set<String>();

if(res==null && userRes.size()==0){
userRes=[Select id,Resource_Group__c from Resource__c where User__c=:UserInfo.getUserId()]; 
for(Resource__c ures: userRes)resids.add(ures.Id);
system.debug('resids==>'+resids);
Query +=' AND Resource__c IN:resids ';
}
else{
if(res!=null)Query +=' AND Resource__c=:res ';
}*/
        
        Query +=' Order by Booked_Date__c ASC ';    
        System.debug('Query==>'+Query);
        if(checkLoc!=null || ser!=null || prgrm!=null || teamID!=null || res!=null)wrapper.records = Database.query(Query);    
        wrapper.records = Database.query(Query);
        
        system.debug('wrapper.records==>'+wrapper.records);
        
        integer rsize=wrapper.records.Size();
        if(rsize>0) { wrapper.existLocation=true;} 
        for(integer i=0;i<=rsize-1;i++) {  if(wrapper.records[i].Booked_Current_Status__c=='InProgress'){ wrapper.ObjectValues.add(wrapper.records[i]); wrapper.inProgress=true; }
        }
        if(wrapper.ObjectValues.size()>0){    wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];   wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];    wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];   wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId];
        }
        for(integer index=0;index<rsize;index++)  { wrapper.mapOfRecords.put(String.valueof(index), wrapper.records[index]); }
        
        for(integer index=0;index<rsize;index++)  {  Records rec=new Records();  rec.regRecords=wrapper.records[index]; rec.waitingTime='12 hours'; wrapper.regRecords.add(rec);  
        }
        
        // }catch(Exception e ){System.debug(e);}
        
        System.debug('map==>'+wrapper.mapOfRecords);
        system.debug('wrapper.regRecords==>'+wrapper.regRecords);
        
        return wrapper;
    } 
    
    @AuraEnabled
    public static Wrapper serviceForExpert(String locationId ,String serviceID ){ 
        Wrapper wrapper=new Wrapper(); 
        List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:locationId]; 
        List<Queue__c> queue=[Select Id From Queue__c where Location__c=:locationId]; 
        Set<String> qids=new Set<String>(); 
        for(integer i=0;i<=queue.size()-1;i++){qids.add(queue[i].Id);} 
        List<Queue_Allocation__c> resQLA=[Select Resource__c 
                                                    From Queue_Allocation__c where Service__c=:serviceID AND Queue__c IN : qids];
        set<String> resIDS=new Set<String>(); 
        for(integer i=0;i<=resQLA.size()-1;i++){ resIDS.add(resQLA[i].Resource__c); }
        wrapper filterwrap=getFilterValues(locationId,serviceID,null,null,null);  for(integer i=0;i<=filterwrap.RR.size()-1;i++) { if(resIDS.contains(filterwrap.RR[i].Preferred_Resource__c))wrapper.allresources.add(filterwrap.RR[i].Preferred_Resource__c);}     
        String userid=UserInfo.getUserId();String resource;
        List<Resource__c> resForLoginUser=[Select Id from Resource__c Where User__c=:userid AND Id IN:wrapper.allresources ];
        List<Team_Member__c> TM=new List<Team_Member__c>();
        if(resForLoginUser.size()>0){wrapper.fres=resForLoginUser[0].Id;TM=[Select Id,Team__c from Team_Member__c where Resource__c=:resForLoginUser[0].Id];  if(TM.size()>0){ wrapper.selectedTeamID=TM[0].Team__c;}
        }else{
            for (string res : wrapper.allresources) {  resource = res; break; }
            wrapper.fres=resource;
            TM=[Select Id,Team__c from Team_Member__c where Resource__c=:resource]; 
            if(TM.size()>0){ wrapper.selectedTeamID=TM[0].Team__c;}
        }
        return wrapper;   
    }
    
    @AuraEnabled
    public static wrapper getRecordsOfLocations(String location, String service, String resource,String program,String Team,String catValue) {   
        System.debug('getRecordsOfLocations is called'+program+' , '+catValue);
        system.debug('location=>'+location+', service==>'+service+' ,resource=>'+resource+' ,program=>'+program+' , team=>'+Team);
        String ser,res,checkLoc,prgrm,teamID;
        Wrapper wrapper=new Wrapper();
        // try{
        if(location=='' || location==null){checkLoc=null;} else{checkLoc=location;}
        if(service==''  || service==null){ ser=null;}else{ser=service;}  
        if(resource=='' || resource==null){res=null;}else{res=resource;}
        if(program==''  || program==null){prgrm=null;}else{prgrm=program;}
        if(Team=='' || Team==null){teamID=null;}else{teamID=Team;}
        system.debug('location=>'+checkLoc+', service==>'+ser+' ,resource=>'+res+' ,program=>'+prgrm+' , team=>'+teamID);
        DateTime nowTime=system.now() ; 
        String allFields = UtilClass_Sch.selectStarFromSObject('Registration__c');
        String Query=' Select '+ allFields +' ,Resource__r.User__c, Account__r.Flagged__c,Contact__r.Flagged__c, Product2__r.Wait_Threshold__c,Contact__r.Name  From  Registration__c where   Product2__c!=null AND Resource__c!=null';// AND Resource__c!=null, 
        if(catValue=='Check In Appointments'){
            Query +=' AND Appointment_DateDt__c = Today AND Status__c=\'Booked\' AND Check_In__c=True ';
        }else if(catValue=='Todays Appointments'){ Query +=' AND Appointment_DateDt__c = Today AND Status__c=\'Booked\' AND  Registration_Time__c >=: nowTime ';
        }else if(catValue=='Past Appointments'){ Query +='  AND Check_In__c=False AND Registration_Time__c <=: nowTime ';
        }else if(catValue=='Completed Appointments'){ Query +=' AND Status__c=\'Completed\' ';
        }else if(catValue=='Future Appointments'){  Query +=' AND Appointment_DateDt__c > Today AND Status__c=\'Booked\' AND  Registration_Time__c >=: nowTime ';
        }     
        if(checkLoc!=null)Query +=' AND Expert_Location__c=:checkLoc ';
        if(ser!=null)Query +=' AND Product2__c=:ser ';
        if(prgrm!=null)Query +=' AND Membership_Program__c=:prgrm ';
        if(teamID!=null)Query +=' AND Resource__r.Team__c=:teamID ';
        
        if(res!=null){
            //Query +=' AND Resource__c=:res ';
            //Query +=' AND (Resource__c=:res OR Resource__c=null)  OR Resource__r.User__c=null';
            Query +=' AND (Resource__r.User__c=:res) ';  
            //Resource__c ResourceRecord=[Select Id, Name, User__c FROM Resource__c WHERE Id=:res];
            //if(ResourceRecord.Name!=null) wrapper.SelectedUserName=ResourceRecord.Name;  
            User usr=new User();  
            if(res!=null) usr=[SELECT Id, Name FROM User WHERE Id=:res];
            if(usr.Name!=null) wrapper.SelectedUserName=usr.Name;  System.debug('if res'); }else{ User usr=[SELECT Id, Name FROM User WHERE Id=:userInfo.getUserId()]; if(usr.Name!=null) wrapper.SelectedUserName=usr.Name; Id currUserId=UserInfo.getUserId();Query +=' AND (Resource__r.User__c=:currUserId) '; 
            System.debug('else res');
            
        }
        
        /*
List<Resource__c> userRes=[Select id,Resource_Group__c from Resource__c where Supervisor__c=true and  User__c=:UserInfo.getUserId()]; 
system.debug('userRes==>'+userRes);
set<String> resids=new set<String>();

if(res==null && userRes.size()==0){
userRes=[Select id,Resource_Group__c from Resource__c where User__c=:UserInfo.getUserId()]; 
for(Resource__c ures: userRes)resids.add(ures.Id);
system.debug('resids==>'+resids);
Query +=' AND Resource__c IN:resids ';
}
else{
if(res!=null)Query +=' AND Resource__c=:res ';
}*/
        
        Query +=' Order by Booked_Date__c ASC ';    
        System.debug('Query==>'+Query);
        if(checkLoc!=null || ser!=null || prgrm!=null || teamID!=null || res!=null)wrapper.records = Database.query(Query);    
        wrapper.records = Database.query(Query);
        
        system.debug('wrapper.records==>'+wrapper.records);
        
        integer rsize=wrapper.records.Size();
        if(rsize>0) { wrapper.existLocation=true;} 
        for(integer i=0;i<=rsize-1;i++) {if(wrapper.records[i].Booked_Current_Status__c=='InProgress'){ wrapper.ObjectValues.add(wrapper.records[i]); wrapper.inProgress=true;}}
        if(wrapper.ObjectValues.size()>0){  wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];  wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];    wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];   wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId];
                                         }
        for(integer index=0;index<rsize;index++)  { wrapper.mapOfRecords.put(String.valueof(index), wrapper.records[index]);}
        
        for(integer index=0;index<rsize;index++)  { 
            Records rec=new Records();  rec.regRecords=wrapper.records[index]; rec.waitingTime='12 hours'; wrapper.regRecords.add(rec);  
        }
        
        // }catch(Exception e ){System.debug(e);}
        
        System.debug('map==>'+wrapper.mapOfRecords);
        system.debug('wrapper.regRecords==>'+wrapper.regRecords);
        
        wrapper.appointmentFiler=catValue;
        
        
        return wrapper;
    }    
    
    @AuraEnabled
    public static Wrapper popUpRecordsOfId(string id, String location,String waitingTime){
        Wrapper wrapper=new Wrapper(); Registration__c registrationToUpdate;
        try {
            registrationToUpdate = [SELECT Booked_Current_Status__c,waiting_Time__c FROM Registration__c 
                                    WHERE id=: id LIMIT 1];
            registrationToUpdate.Booked_Current_Status__c = 'InProgress';
            registrationToUpdate.waiting_Time__c = waitingTime;
            registrationToUpdate.Serve_Start_Time__c = System.now(); 
            
            // update registrationToUpdate; 
            List<SObject> saferegistrationToUpdate = FLSHelper.getSafeRecords(
                new List<SObject>{registrationToUpdate}, // record if the items are just list
                'Registration__c',
                AccessType.UPDATABLE
            );
            List<Registration__c> typedregistrationToUpdate = new List<Registration__c>();
            for (SObject s : saferegistrationToUpdate) {
                typedregistrationToUpdate.add((Registration__c)s);
            }
            if (!typedregistrationToUpdate.isEmpty()) {
                update typedregistrationToUpdate;
            }

            registrationToUpdate = [SELECT Booked_Current_Status__c FROM Registration__c WHERE id=: id LIMIT 1]; 
            if(registrationToUpdate.Booked_Current_Status__c == 'InProgress'){wrapper.updateStatusForCancel=True;}    } catch(DmlException e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage());  
        }
        wrapper.ObjectValues=[SELECT id, Name, OwnerId, RecordTypeId, Account__c,Account__r.Flagged__c,Resource__c,Account__r.Name, Event__c, Expert_Location__c,
                              Company__c, Ticket__c, Customer_Status__c, Is_Amount_Refunded__c,Twilio_Message__c, Queue__c,Queue__r.Name,
                              Customer_Type__c, Status__c, Registration_Type__c, Registration_Time__c,Registration_End_Time__c,Wait_Time_Exceeded__c,Product2__r.Wait_Threshold__c,
                              End_Time__c,  Meeting_Status__c, Meeting_outcome__c,  Purpose__c,Customer_Name__c, Customer_Lastname__c, Customer_Email__c,
                              Customer_Contact__c,Contact__c, Resource__r.User__c, waiting_Time__c, Registration_Price__c, Total_Tax_Amount__c, Discount__c,Booked_Current_Status__c,LastModifiedDate 
                              FROM Registration__c WHERE id=:id ];
        wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];
        wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];
        wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];
        wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId];
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getRegDetails(string id){
        Wrapper wrapper=new Wrapper();
        wrapper.ObjectValues=[SELECT id, Name, OwnerId, RecordTypeId,Wait_Time_Exceeded__c,Contact__c, Account__c,Account__r.Flagged__c,Resource__c,Account__r.Name, Event__c, Expert_Location__c,
                              Company__c, Ticket__c, Customer_Status__c,    Is_Amount_Refunded__c,
                              Twilio_Message__c, Queue__c,Queue__r.Name, Resource__r.User__c,
                              Customer_Type__c, Status__c, Registration_Type__c,    Registration_Time__c,
                              Registration_End_Time__c,Product2__r.Wait_Threshold__c,
                              End_Time__c,  Meeting_Status__c, Meeting_outcome__c,  Purpose__c,
                              Customer_Name__c, Customer_Lastname__c, Customer_Email__c,
                              Customer_Contact__c,waiting_Time__c, Registration_Price__c, 
                              Total_Tax_Amount__c, Discount__c,Booked_Current_Status__c,
                              LastModifiedDate
                              FROM Registration__c WHERE id=:id ];
        System.debug('ObjectValues query result: ' + JSON.serialize(wrapper.ObjectValues));
        wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];
        System.debug('Notes query result: ' + JSON.serialize(wrapper.Notes));
        wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];
        System.debug('Attachments query result: ' + JSON.serialize(wrapper.Attachments));
        wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];
        System.debug('userName query result: ' + JSON.serialize(wrapper.userName));
        wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId];
        System.debug('recordTypeName query result: ' + JSON.serialize(wrapper.recordTypeName));
        return wrapper;
    }
    

    @AuraEnabled
    public static Wrapper setStatus(String passedId, String location,String status,String purpose){
        Wrapper wrapper = new Wrapper();system.debug('purpose==>'+purpose);
        Registration__c registrationToUpdate;
        try {
            registrationToUpdate = [SELECT Resource__c,Product2__c,Status__c,Booked_Current_Status__c FROM Registration__c WHERE id=: passedId LIMIT 1];
            
            registrationToUpdate.Status__c = status;
            registrationToUpdate.Booked_Current_Status__c='NotInProgress';
            registrationToUpdate.Cancellation_Reason__c= purpose; 
            registrationToUpdate.Booked_Current_Status__c='Completed';
            registrationToUpdate.Serve_Finished_Time__c=System.now();     
            // update registrationToUpdate; 

            List<SObject> saferegistrationToUpdate1 = FLSHelper.getSafeRecords(    new List<SObject>{registrationToUpdate},     'Registration__c',    AccessType.UPDATABLE);            List<Registration__c> typedregistrationToUpdate1 = new List<Registration__c>();            for (SObject s : saferegistrationToUpdate1) {                typedregistrationToUpdate1.add((Registration__c)s);            }            if (!typedregistrationToUpdate1.isEmpty()) {                update typedregistrationToUpdate1;            }                        registrationToUpdate = [SELECT Resource__c,Resource__r.User__c,Product2__c,Status__c FROM Registration__c WHERE id=: passedId LIMIT 1];
           
            if( registrationToUpdate.Status__c == status){wrapper.updateStatusForCancel=True;} } catch(DmlException e) {  System.debug('An unexpected error has occurred: ' + e.getMessage()); }
        Wrapper forAllRegRecords=getRecordsOfLocations(location, registrationToUpdate.Product2__c,registrationToUpdate.Resource__r.User__c,null,null,null);   
        List<Registration__c> records=forAllRegRecords.records;
        
        integer rsize=records.Size();
        for(integer i=0;i<=rsize-1;i++) {if(records[i].Booked_Current_Status__c=='InProgress'){ wrapper.ObjectValues.add(records[i]); wrapper.inProgress=true;}}
        if(wrapper.ObjectValues.size()>0){  wrapper.Notes = [Select Id, Title, ParentId From Note Where ParentId=:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];  wrapper.Attachments = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:wrapper.ObjectValues[0].Id Order By CreatedDate Asc];  wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId];  wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId];
                                         }
        for(integer index=0;index<rsize;index++) { wrapper.mapOfRecords.put(String.valueof(index), records[index]); }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getRescheduleDetail(String id){
        Wrapper wrapper=new Wrapper(); wrapper.todaysDate=System.now();
        try{
            wrapper.getReschudle = [SELECT Resource__c, Resource__r.Name,RecordTypeId,
                                    Product2__c,Product2__r.Name,
                                    Expert_Location__c, Expert_Location__r.Name,
                                    Registration_Time__c
                                    From Registration__c where id=:id];
            RecordType recLoc = [Select Id,DeveloperName, Name From RecordType where id=:wrapper.getReschudle[0].RecordTypeId]; String ser; if(recLoc.DeveloperName=='Expert_Event') { List<Queue_Allocation__c> serQLA=[Select Id, Service__c FROM Queue_Allocation__c Where Queue__r.Location__c=:wrapper.getReschudle[0].Expert_Location__c AND Resource__c=:wrapper.getReschudle[0].Resource__c];if(serQLA.size()>=1){ser=serQLA[0].Service__c;} }else{ ser=wrapper.getReschudle[0].Product2__c;} List<Work_Planner__c> WP=new List<Work_Planner__c>(); List<Resource_Requirement__c> RR=new List<Resource_Requirement__c>(); List<Resource__c> Res=new List<Resource__c>(); WP=[Select Id,Name,Location__c,Product__c FROM Work_Planner__c where Location__c=:wrapper.getReschudle[0].Expert_Location__c AND  Product__c=:ser]; set<String> wpids=new set<String>(); for(integer i=0;i<=WP.size()-1;i++) { wpids.add(WP[i].Id); } Res=[Select Id,Name  FROM Resource__c Where Id=:wrapper.getReschudle[0].Resource__c ]; Set<String> ResIds=new Set<String>(); for(integer i=0;i<=Res.size()-1;i++) { ResIds.add(Res[i].Id); } RR=[Select Id, Name,Preferred_Resource__c,Work_Planner__c From Resource_Requirement__c Where Preferred_Resource__c IN : ResIds AND Work_Planner__c IN : wpids ]; String finalResource; for(String s : ResIds){ if(RR[0].Preferred_Resource__c==s){ finalResource=s; } } List<Queue__c> Queue=[Select Id,Location__c From Queue__c Where Status__c='Active'  AND Location__c =:wrapper.getReschudle[0].Expert_Location__c]; Set<String> qidsr=new Set<String>(); for(integer i=0;i<=Queue.size()-1;i++) { qidsr.add(Queue[i].Id);} List<Queue_Allocation__c> QLA=new List<Queue_Allocation__c>(); if(Queue.size()>=1){ QLA=[Select Id From Queue_Allocation__c where Queue__c IN : qidsr AND Resource__c=:wrapper.getReschudle[0].Resource__c AND Service__c=:ser AND Active__c=true ]; } if(QLA.size()>=1){ wrapper sam=getResource(finalResource); List<Resource__c> resource=sam.getRes; wrapper.resource=resource; integer expertSlot=integer.valueOf(resource[0].Time_Slot_Duration__c); Date startDate=resource[0].Start_Date__c; DateTime endDate=resource[0].End_Date__c; DateTime todaysDate=System.now(); Date currentDate; if(startDate>=todaysDate.Date()){currentDate=startDate;}else{ currentDate=todaysDate.Date();} Time myTime = Time.newInstance(0, 0, 0, 0); DateTime DOW=DateTime.newInstance(currentDate,myTime); String dayOfWeek=DOW.format('EEE'); Date ddd=date.today(); map<DateTime, list<DateTime>> Slots=new map<DateTime, list<DateTime>>(); List<DateTime> monSlots=new List<DateTime>(); List<DateTime> tueSlots=new List<DateTime>(); List<DateTime> wedSlots=new List<DateTime>(); List<DateTime> thuSlots=new List<DateTime>(); List<DateTime> friSlots=new List<DateTime>(); List<DateTime> satSlots=new List<DateTime>(); List<DateTime> sunSlots=new List<DateTime>(); List<Registration__c> allReg=[Select Id, Name, Registration_Time__c,End_Time__c From Registration__c where   Registration_Time__c >=: System.now() AND Resource__c =:wrapper.getReschudle[0].Resource__c AND Expert_Location__c =:wrapper.getReschudle[0].Expert_Location__c AND Product2__c=:ser]; list<Time_Off__c> TimeOff=[Select Id,Name,Start_Time__c,Start_Date__c,End_Time__c,End_Date__c,Resource__c,Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=Null AND Type__c!=Null AND  Start_Time__c!=NULL AND End_Time__c!=NULL]; list<Time_Off__c> TimeOffDate=[Select Id,Name,Start_Time__c,Start_Date__c,End_Time__c ,End_Date__c, Resource__c, Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c=NULL AND End_Time__c=NULL AND Type__c!=Null]; Set<Date> ToffDates=new Set<Date>(); Date TOFFDate; for(integer i=0;i<=TimeOffDate.size()-1;i++){ TOFFDate=TimeOffDate[i].Start_Date__c; while(TOFFDate<=TimeOffDate[i].End_Date__c)  {ToffDates.add(TOFFDate);  TOFFDate=TOFFDate.addDays(1); } } for(integer i=1;i<=4;i++){   if(currentDate>endDate  ){system.debug('currentDate is greater than the endDate');i++;}else{  if(dayOfWeek=='Mon')  { if(resource[0].Mon_Start_Time__c==null || resource[0].Mon_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1;  currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); }else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Mon_Start_Time__c,  resource[0].Mon_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));  }currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Tue')  {if(resource[0].Tue_Start_Time__c==null || resource[0].Tue_End_Time__c==null || ToffDates.contains(currentDate))  {  i=i-1; currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); }else{  Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Tue_Start_Time__c,  resource[0].Tue_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c);     Map<Date, Map<String, String>> mb=m.mapOfslots2;    for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }  } else if(dayOfWeek=='Wed')  {if(resource[0].Wed_Start_Time__c==null || resource[0].Wed_End_Time__c==null || ToffDates.contains(currentDate))   { i=i-1;  dayOfWeek=''; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Wed_Start_Time__c,  resource[0].Wed_End_Time__c,expertSlot,  resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c);   Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset())  { wrapper.mapOfslots2.put(key, mb.get(key)); }  currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');  } }  else if(dayOfWeek=='Thu')  { if(resource[0].Thu_Start_Time__c==null || resource[0].Thu_End_Time__c==null || ToffDates.contains(currentDate))   {i=i-1; dayOfWeek='';  currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');   }else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Thu_Start_Time__c,   resource[0].Thu_End_Time__c,expertSlot , resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c); Map<Date, Map<String, String>> mb=m.mapOfslots2;    for(Date key : mb.keyset()) {  wrapper.mapOfslots2.put(key, mb.get(key));  }  currentDate=currentDate.addDays(1);    DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');  }  } else if(dayOfWeek=='Fri') {if(resource[0].Fri_Start_Time__c==null || resource[0].Fri_End_Time__c==null || ToffDates.contains(currentDate))    {i=i-1; dayOfWeek=''; currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); }else{   Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Fri_Start_Time__c,  resource[0].Fri_End_Time__c,expertSlot , resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c   );   Map<Date, Map<String, String>> mb=m.mapOfslots2;    for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));} currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Sat') {if(resource[0].Sat_Start_Time__c==null || resource[0].Sat_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1; dayOfWeek=''; currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');}else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Sat_Start_Time__c,   resource[0].Sat_End_Time__c,expertSlot , resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );   Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset())   {wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Sun'){ if(resource[0].Sun_Start_Time__c==null || resource[0].Sun_End_Time__c==null || ToffDates.contains(currentDate))  { i=i-1; dayOfWeek=''; currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');  }else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Sun_Start_Time__c,   resource[0].Sun_End_Time__c,expertSlot ,  resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );  Map<Date, Map<String, String>> mb=m.mapOfslots2;     for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;      dayOfWeek=forDOW.format('EEE'); }} } } Date lastDate; for(Date key : wrapper.mapOfslots2.keyset())  { lastDate=key; }
                if(lastDate==resource[0].End_Date__c){ wrapper.disl=true; }else{}   } }catch(Exception e){system.debug('Error in getRescheduleDetail method. '+e);}
        List<Queue__c> getQueueLocations=[SELECT Id,Location__c,Location__r.Name From Queue__c]; 
        Set<String> qloc=new Set<String>(); for(integer i=0;i<=getQueueLocations.size()-1;i++){qloc.add(getQueueLocations[i].Location__c);}  
        for(String loc : qloc){wrapper.LocationIds.add(loc);}
        wrapper filterwrap;
        filterwrap=getFilterValues(wrapper.getReschudle[0].Expert_Location__c,null,null,null,null); 
        Set<String> filser=new Set<String>();filser=filterwrap.allServices;
        List<Queue_Allocation__c> QLAForSer=[Select Resource__c,Service__c From Queue_Allocation__c 
                                                       where Queue__r.Location__c=:wrapper.getReschudle[0].Expert_Location__c AND Resource__c!=null AND  Service__c!=null]; 
        Set<String> QLAserv=new Set<String>();
        for(integer i=0;i<=QLAForSer.size()-1;i++){ QLAserv.add(QLAForSer[i].Service__c);}
        for(String serv:QLAserv)
        { if(filser.contains(serv)){ wrapper.ServiceIds.add(serv);}}
        wrapper filterRes; 
        filterRes=getFilterValues(wrapper.getReschudle[0].Expert_Location__c,wrapper.getReschudle[0].Product2__c,null,null,null);
        Set<String> filres=new Set<String>();filres=filterRes.allresources;
        system.debug('filterRes==>'+filterRes.allresources);
        List<Queue_Allocation__c> QLAForRes=[Select Resource__c,Service__c From Queue_Allocation__c 
                                                       where Queue__r.Location__c=:wrapper.getReschudle[0].Expert_Location__c AND  Service__c=:wrapper.getReschudle[0].Product2__c AND Resource__c!=null AND  Service__c!=null]; 
        Set<String> QLAres=new Set<String>();
        for(integer i=0;i<=QLAForRes.size()-1;i++){ QLAres.add(QLAForRes[i].Resource__c);}
        for(String resc:QLAres){ if(filres.contains(resc)){ wrapper.ExpertIds.add(resc);}}
        return wrapper;
    }
        @AuraEnabled
    public static Wrapper getRegRecordUpdate(String Id, String recValues,String userID, String recordType,String queueId, String accountId, String event, String location,DateTime sDate, DateTime eDate) { 
        Wrapper wrapper=new Wrapper();
        system.debug('recValues==>'+recValues);       
        List<String> recordValues=new List<String>();
        try{ recordValues= (List<String>)JSON.deserialize(recValues, List<String> .class); } catch(Exception e){ wrapper.errmsg=e.getMessage()+' 1@'+e.getLineNumber(); system.debug('getRecordUpdate Exception'+e.getMessage()+' @@'+e.getLineNumber()+' ST=>'+e.getStackTraceString()); return wrapper; }
        
        try{
            integer recsize = recordValues.Size(); system.debug('Enter getValuesOfId');
            Registration__c registrationToUpdate;
            
            registrationToUpdate = [SELECT id, Name, OwnerId,Product2__c,Wait_Time_Exceeded__c,Resource__c, RecordTypeId, Account__c,Account__r.Name, Event__c, Expert_Location__c,
                                    Company__c, Ticket__c, Customer_Status__c,Is_Amount_Refunded__c,Twilio_Message__c, Queue__c,Queue__r.Name,
                                    Customer_Type__c, Status__c, Registration_Type__c,Registration_Time__c,Registration_End_Time__c, Resource__r.User__c,
                                    End_Time__c,  Meeting_Status__c, Meeting_outcome__c,Purpose__c,Customer_Name__c, Customer_Lastname__c, Customer_Email__c,
                                    Customer_Contact__c, Registration_Price__c, Total_Tax_Amount__c, Discount__c,LastModifiedDate,waiting_Time__c,Booked_Current_Status__c 
                                    FROM Registration__c WHERE id=: Id];
            registrationToUpdate.Status__c = 'Completed';
            registrationToUpdate.Customer_Status__c = 'Attended'; //registrationToUpdate.Queue__c=queueId;
            registrationToUpdate.Registration_Time__c = sDate;
            DateTime newDateTime = (Datetime.now()).addMinutes(40);   registrationToUpdate.End_Time__c=eDate;  registrationToUpdate.Customer_Type__c=recordValues[1];   registrationToUpdate.Registration_Type__c=recordValues[2];   registrationToUpdate.Meeting_Status__c=recordValues[3]; registrationToUpdate.Meeting_outcome__c=recordValues[4];  registrationToUpdate.Purpose__c=recordValues[5]; registrationToUpdate.Customer_Name__c=recordValues[6];  registrationToUpdate.Customer_Lastname__c=recordValues[7];  registrationToUpdate.Customer_Email__c=recordValues[8];    registrationToUpdate.Customer_Contact__c=recordValues[9];
            registrationToUpdate.Booked_Current_Status__c = 'Completed';
            registrationToUpdate.Serve_Finished_Time__c = System.now();
            /*update registrationToUpdate;*/
            List<SObject> saferegistrationToUpdate2 = FLSHelper.getSafeRecords(
    new List<SObject>{registrationToUpdate},    'Registration__c',    AccessType.UPDATABLE );   List<Registration__c> typedregistrationToUpdate2 = new List<Registration__c>();    for (SObject s : saferegistrationToUpdate2) {    typedregistrationToUpdate2.add((Registration__c)s);}        if (!typedregistrationToUpdate2.isEmpty()) {    update typedregistrationToUpdate2;
}            system.debug('Enter getValuesOfId2'); 
 
registrationToUpdate = [SELECT Status__c,Product2__c,Resource__c FROM Registration__c WHERE id=: Id]; 
            if( registrationToUpdate.Status__c == 'Completed') { wrapper.updateStatus=True; }  
            wrapper.ObjectValues=[SELECT id, Name, OwnerId, RecordTypeId, Account__r.Flagged__c,Account__c,Account__r.Name, Event__c, Expert_Location__c,Company__c, Ticket__c, Customer_Status__c,Is_Amount_Refunded__c,Resource__r.User__c,
                                  Twilio_Message__c, Queue__c,Queue__r.Name, Resource__c,Customer_Type__c, Status__c, Registration_Type__c,Registration_Time__c,Registration_End_Time__c,Product2__r.Wait_Threshold__c,End_Time__c,Wait_Time_Exceeded__c,
                                  Meeting_Status__c, Meeting_outcome__c,  Purpose__c,Customer_Name__c, Customer_Lastname__c, Customer_Email__c,Customer_Contact__c, Registration_Price__c,waiting_Time__c, Total_Tax_Amount__c, Discount__c,Booked_Current_Status__c 
                                  FROM Registration__c WHERE id=:id ];
            
            wrapper.userName=[SELECT Name FROM User WHERE Id=:wrapper.ObjectValues[0].OwnerId]; wrapper.recordTypeName = [Select Id, Name From RecordType where id=:wrapper.ObjectValues[0].RecordTypeId]; 
            System.debug('registrationToUpdate==>'+registrationToUpdate.Resource__c); 
            Wrapper forAllRegRecords=getRecordsOfLocations(location, registrationToUpdate.Product2__c,registrationToUpdate.Resource__r.User__c,null,null,null);
            List<Registration__c> records=forAllRegRecords.records;  integer rsize=records.Size();
            for(integer index=0;index<rsize;index++) { wrapper.mapOfRecords.put(String.valueof(index), records[index]);  } 
            wrapper.errmsg=null;
            return wrapper;
        } catch(Exception e) {
            System.debug('An unexpected error has occurred: ' + e.getMessage()+' LN==>'+e.getLineNumber());
            wrapper.errmsg=e.getMessage()+' 2@'+e.getLineNumber()+' ST=>'+e.getStackTraceString();
            
            return wrapper;           
        }
        
    }
    
    @AuraEnabled public static  Wrapper generateSlots(List<Registration__c> allRegs, list<Time_Off__c> allTOFF, Date currentDate,Time DayST,Time DayET,integer expertSlot, Time BST, Time BET){ Wrapper wrapper=new Wrapper(); DateTime todayDate=System.now(); Map<DateTime,DateTime> bookedReg=new Map<DateTime,DateTime>(); Map<DateTime, String> bookedRegs=new Map<DateTime, String>(); List<Registration__c> allReg=allRegs; for(integer i=0;i<=allReg.size()-1;i++){ bookedReg.put(allReg[i].Registration_Time__c, allReg[i].End_Time__c);  bookedRegs.put(allReg[i].Registration_Time__c, allReg[i].Name); } Map<DateTime, String> TOFF=new Map<DateTime, String>(); list<Time_Off__c> TimeOff=allTOFF; Map<DateTime,DateTime> TODates=new Map<DateTime,DateTime>(); for(integer i=0;i<=TimeOff.size()-1;i++) { TODates.put(DateTime.newInstance(TimeOff[i].End_Date__c, TimeOff[i].Start_Time__c), DateTime.newInstance(TimeOff[i].End_Date__c, TimeOff[i].End_Time__c)); TOFF.put(DateTime.newInstance(TimeOff[i].End_Date__c, TimeOff[i].Start_Time__c),  TimeOff[i].Type__c); } Map<Date, Map<String, String>> mapOfslots2=new Map<Date, Map<String, String>>(); Map<String, String> sl=new Map<String, String>(); DateTime startOfDay=DateTime.newInstance(currentDate, DayST); DateTime strDate=startOfDay; DateTime endOfDay=DateTime.newInstance(currentDate, DayET); DateTime bstt; if(BST!=null){bstt=DateTime.newInstance(currentDate, BST);} DateTime bett; if(BET!=null){bett=DateTime.newInstance(currentDate, BET);} if(BST!=null && BET!=null){ if(startOfDay < bstt || startOfDay >= bett){ if(todayDate>startOfDay){ sl.put(String.valueOf(startOfDay), 'True'); }else{ sl.put(String.valueOf(startOfDay), 'false');} if(startOfDay.addMinutes(expertSlot)<bstt || startOfDay.addMinutes(expertSlot)>=bett){if(startOfDay.addMinutes(expertSlot)==bett){sl.put(String.valueOf(startOfDay), 'BreakTime');}}else{if(startOfDay.addMinutes(expertSlot)==bstt){} else{sl.put(String.valueOf(startOfDay), 'BreakTime');}}}else{ sl.put(String.valueOf(startOfDay), 'BreakTime');  }}else{if(todayDate>startOfDay){  sl.put(String.valueOf(startOfDay), 'True'); }else{  sl.put(String.valueOf(startOfDay), 'false'); }} for(DateTime key : bookedReg.keyset()){ if(startOfDay<key || startOfDay>=bookedReg.get(key)) { if(startOfDay.addMinutes(expertSlot)<key || startOfDay.addMinutes(expertSlot)>=bookedReg.get(key)){}    else{if(startOfDay.addMinutes(expertSlot)==key){}else{    if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), bookedRegs.get(key)); }}}  }else{   if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), bookedRegs.get(key));}  } } for(DateTime key:TODates.keyset()){ if(startOfDay<key || startOfDay>=TODates.get(key)){if(startOfDay.addMinutes(expertSlot)<key || startOfDay.addMinutes(expertSlot)>=TODates.get(key))    {if(startOfDay.addMinutes(expertSlot)==TODates.get(key)){sl.put(String.valueOf(startOfDay), TOFF.get(key));}}else{if(startOfDay.addMinutes(expertSlot)==key){}else{ if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), TOFF.get(key)); }}} }else {if(startOfDay.Date()==key.Date()){ sl.put(String.valueOf(startOfDay), TOFF.get(key));  } }} DateTime chechEnd; while(startOfDay<endOfDay) {startOfDay=startOfDay.addMinutes(expertSlot);chechEnd=startOfDay.addMinutes(expertSlot);if(chechEnd>endOfDay){}else{if(startOfDay<endOfDay){  if(BST!=null && BET!=null){if(startOfDay < bstt || startOfDay >= bett){ if(todayDate>startOfDay){  sl.put(String.valueOf(startOfDay), 'True'); }else{  sl.put(String.valueOf(startOfDay), 'false'); }  if(startOfDay.addMinutes(expertSlot)<bstt || startOfDay.addMinutes(expertSlot)>=bett){if(startOfDay.addMinutes(expertSlot)==bett){sl.put(String.valueOf(startOfDay), 'BreakTime');}} else{if(startOfDay.addMinutes(expertSlot)==bstt){}  else{sl.put(String.valueOf(startOfDay), 'BreakTime'); }} }else{sl.put(String.valueOf(startOfDay), 'BreakTime'); }}else{if(todayDate>startOfDay){  sl.put(String.valueOf(startOfDay), 'True'); }else{   sl.put(String.valueOf(startOfDay), 'false');}} for(DateTime key : bookedReg.keyset()){if(startOfDay<key || startOfDay>=bookedReg.get(key)) { if(startOfDay.addMinutes(expertSlot)<key || startOfDay.addMinutes(expertSlot)>=bookedReg.get(key)){}else{if(startOfDay.addMinutes(expertSlot)==key){}else{  if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), bookedRegs.get(key));  }}}      }else{ if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay),  bookedRegs.get(key));} } } for(DateTime key:TODates.keyset()){if(startOfDay<key || startOfDay>=TODates.get(key))  {  if(startOfDay.addMinutes(expertSlot)<key || startOfDay.addMinutes(expertSlot)>=TODates.get(key)){if(startOfDay.addMinutes(expertSlot)==TODates.get(key)){sl.put(String.valueOf(startOfDay), TOFF.get(key));}}else{if(startOfDay.addMinutes(expertSlot)==key){}else{ if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), TOFF.get(key));  }}} }else  {if(startOfDay.Date()==key.Date()){sl.put(String.valueOf(startOfDay), TOFF.get(key)); } } } } } } wrapper.mapOfslots2.put(currentDate, sl); return Wrapper; }
    
    @AuraEnabled
    public static Wrapper getNextSlots(String nextDate,String resID,String expertId,String serviceId,String locationId){
        Wrapper wrapper=new Wrapper();
        Datetime myDate =Datetime.valueOf(nextDate);
        wrapper sam=getResource(resID);
        List<Resource__c> resource=sam.getRes;
        
        integer expertSlot=integer.valueOf(resource[0].Time_Slot_Duration__c);
        
        Date actualSDate=resource[0].Start_Date__c;
        DateTime actualEDate=resource[0].End_Date__c;
       
        Date sDate = date.newinstance(myDate.year(), myDate.month(), myDate.day());
        sDate=sDate.addDays(1);
        Date startDate= myDate.Date(); 
        startDate=startDate.addDays(1);
        DateTime endDate=sDate;
        integer j=1;
        while(endDate<=actualEDate && j<=4){endDate=endDate.addDays(1); j++; }
       
        DateTime DOW=startDate;
        String dayOfWeek=DOW.format('EEE');
        Date currentDate=startDate;
        map<DateTime, list<DateTime>> Slots=new map<DateTime, list<DateTime>>(); 
        List<DateTime> monSlots=new List<DateTime>();
        List<DateTime> tueSlots=new List<DateTime>();
        List<DateTime> wedSlots=new List<DateTime>();
        List<DateTime> thuSlots=new List<DateTime>();
        List<DateTime> friSlots=new List<DateTime>();
        List<DateTime> satSlots=new List<DateTime>();
        List<DateTime> sunSlots=new List<DateTime>();
        List<Registration__c> allReg=[Select Id, Name, Registration_Time__c,End_Time__c From Registration__c where Registration_Time__c >=: System.now()
                                                AND Resource__c =:expertId AND Expert_Location__c =:locationId AND Product2__c=:serviceId];
        list<Time_Off__c> TimeOff=[Select Id,Name,Start_Time__c, End_Time__c,Start_Date__c ,End_Date__c, Resource__c, Type__c 
                                             From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c!=NULL AND End_Time__c!=NULL AND Type__c!=Null];
        list<Time_Off__c> TimeOffDate=[Select Id,Name,Start_Time__c,Start_Date__c,End_Time__c ,End_Date__c, Resource__c, Type__c 
                                                 From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c=NULL AND End_Time__c=NULL AND Type__c!=Null];
        Set<Date> ToffDates=new Set<Date>();
        Date TOFFDate;
        for(integer i=0;i<=TimeOffDate.size()-1;i++){ TOFFDate=TimeOffDate[i].Start_Date__c; while(TOFFDate<=TimeOffDate[i].End_Date__c) { ToffDates.add(TOFFDate); TOFFDate=TOFFDate.addDays(1);   }}  
        for(integer i=1;i<=4;i++){
            if(currentDate>actualEDate ){system.debug('currentDate is greater than the endDate');i++;}else{
                if(dayOfWeek=='Mon')
                {if(resource[0].Mon_Start_Time__c==null || resource[0].Mon_End_Time__c==null || ToffDates.contains(currentDate))  {
                    i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');
                }else{
                    wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Mon_Start_Time__c, 
                                            resource[0].Mon_End_Time__c,expertSlot ,
                                            resource[0].Break_Start_Time__c, 
                                            resource[0].Break_End_Time__c
                                           );
                    Map<Date, Map<String, String>> mb=m.mapOfslots2;
                    for(Date key : mb.keyset())
                    { wrapper.mapOfslots2.put(key, mb.get(key)); }
                    currentDate=currentDate.addDays(1);
                    DateTime forDOW=currentDate;
                    dayOfWeek=forDOW.format('EEE');
                }
                }
                else if(dayOfWeek=='Tue')
                {
                    if(resource[0].Tue_Start_Time__c==null || resource[0].Tue_End_Time__c==null || ToffDates.contains(currentDate))  {
                        i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');
                    }else{
                        wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Tue_Start_Time__c, 
                                                resource[0].Tue_End_Time__c,expertSlot, resource[0].Break_Start_Time__c, 
                                                resource[0].Break_End_Time__c
                                               );
                        Map<Date, Map<String, String>> mb=m.mapOfslots2;
                        for(Date key : mb.keyset())
                        { wrapper.mapOfslots2.put(key, mb.get(key));}
                        currentDate=currentDate.addDays(1);
                        DateTime forDOW=currentDate;
                        dayOfWeek=forDOW.format('EEE');
                    }
                } else if(dayOfWeek=='Wed')
                {
                    if(resource[0].Wed_Start_Time__c==null || resource[0].Wed_End_Time__c==null || ToffDates.contains(currentDate))  {
                        i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');
                    }else{
                        wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Wed_Start_Time__c, 
                                                resource[0].Wed_End_Time__c,expertSlot, resource[0].Break_Start_Time__c, 
                                                resource[0].Break_End_Time__c
                                               );
                        Map<Date, Map<String, String>> mb=m.mapOfslots2;
                        for(Date key : mb.keyset())
                        { wrapper.mapOfslots2.put(key, mb.get(key));}
                        currentDate=currentDate.addDays(1);
                        DateTime forDOW=currentDate;
                        dayOfWeek=forDOW.format('EEE');
                    }
                } 
                else if(dayOfWeek=='Thu') { if(resource[0].Thu_Start_Time__c==null || resource[0].Thu_End_Time__c==null || ToffDates.contains(currentDate)){  i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Thu_Start_Time__c,   resource[0].Thu_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c ); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));  } currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');
                                                                                                                                                                                                                                                                                                  }  } else if(dayOfWeek=='Fri')  { if(resource[0].Fri_Start_Time__c==null || resource[0].Fri_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Fri_Start_Time__c,  resource[0].Fri_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,   resource[0].Break_End_Time__c );   Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset())    {wrapper.mapOfslots2.put(key, mb.get(key)); }  currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE');  }
                                                                                                                                                                                                                                                                                                                                  } else if(dayOfWeek=='Sat')  { if(resource[0].Sat_Start_Time__c==null || resource[0].Sat_End_Time__c==null || ToffDates.contains(currentDate))  { i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sat_Start_Time__c,   resource[0].Sat_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c   );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) {wrapper.mapOfslots2.put(key, mb.get(key));  }currentDate=currentDate.addDays(1);    DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE'); }
                                                                                                                                                                                                                                                                                                                                                               } else if(dayOfWeek=='Sun') {if(resource[0].Sun_Start_Time__c==null || resource[0].Sun_End_Time__c==null || ToffDates.contains(currentDate)) {i=i-1;   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sun_Start_Time__c,   resource[0].Sun_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c  );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) {wrapper.mapOfslots2.put(key, mb.get(key));  } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }  } }
        }
        String dayOW;
        DateTime forDayOW;
        forDayOW=currentDate;  dayOW=forDayOW.format('EEE');
        integer exist=0;
        while(currentDate<=actualEDate){
            if(dayOW=='Mon'){if(resource[0].Mon_Start_Time__c!=null && resource[0].Mon_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }
            else if(dayOW=='Tue'){if(resource[0].Tue_Start_Time__c!=null && resource[0].Tue_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }
            else if(dayOW=='Wed'){if(resource[0].Wed_Start_Time__c!=null && resource[0].Wed_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }
            else if(dayOW=='Thu'){if(resource[0].Thu_Start_Time__c!=null && resource[0].Thu_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }
            else if(dayOW=='Fri'){if(resource[0].Fri_Start_Time__c!=null && resource[0].Fri_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }               
            else if(dayOW=='Sat'){if(resource[0].Sat_Start_Time__c!=null && resource[0].Sat_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }
            else if(dayOW=='Sun'){if(resource[0].Sun_Start_Time__c!=null && resource[0].Sun_End_Time__c!=null){exist=1;currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');wrapper.disl=true;}     }                  else{currentDate=currentDate.addDays(1);forDayOW=currentDate; dayOW=forDayOW.format('EEE');}     
        }
        if(exist==1){ wrapper.disl=false; }
        Date lastDate;
        for(Date key : wrapper.mapOfslots2.keyset())
        {lastDate=key; }
        if(lastDate==resource[0].End_Date__c){ wrapper.disl=true;
                                                       }else{}
        return wrapper;
    }
    
    @AuraEnabled public static Wrapper fetchPreSlot(String preDate, String regID,String expertId,String serviceId,String locationId){ Wrapper wrapper=new Wrapper();  Datetime myDate =DateTime.valueOf(preDate); wrapper sam=getResource(regID);  List<Resource__c> resource=sam.getRes;  integer expertSlot=integer.valueOf(resource[0].Time_Slot_Duration__c); Date actualSDate=resource[0].Start_Date__c; DateTime actualEDate=resource[0].End_Date__c;  myDate=myDate.addDays(-1); DateTime sDate=myDate; integer k=1;   list<Time_Off__c> TimeOffDate=[Select Id,Name,Start_Time__c,Start_Date__c,  End_Time__c ,End_Date__c, Resource__c, Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c=NULL AND End_Time__c=NULL AND Type__c!=Null]; Set<Date> ToffDates=new Set<Date>(); Date TOFFDate;  for(integer i=0;i<=TimeOffDate.size()-1;i++){ TOFFDate=TimeOffDate[i].Start_Date__c; while(TOFFDate<=TimeOffDate[i].End_Date__c) { ToffDates.add(TOFFDate);   TOFFDate=TOFFDate.addDays(1);  } } do{ if(sDate.format('EEE')=='Mon' && resource[0].Mon_Start_Time__c!=null  && resource[0].Mon_End_Time__c!=null  ){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1);}else{ K++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Tue' && resource[0].Tue_Start_Time__c!=null && resource[0].Tue_End_Time__c!=null ){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1);} else{   K++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Wed' && resource[0].Wed_Start_Time__c!=null && resource[0].Wed_End_Time__c!=null){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1);}else{ k++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Thu' && resource[0].Thu_Start_Time__c!=null && resource[0].Thu_End_Time__c!=null){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1); } else{   K++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Fri' && resource[0].Fri_Start_Time__c!=null && resource[0].Fri_End_Time__c!=null){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1);}else{ K++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Sat' && resource[0].Sat_Start_Time__c!=null && resource[0].Sat_End_Time__c!=null){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1); } else{   K++; if(k<=4)sDate=sDate.addDays(-1); }} else if(sDate.format('EEE')=='Sun' && resource[0].Sun_Start_Time__c!=null && resource[0].Sun_End_Time__c!=null){if(ToffDates.contains(sDate.date())){if(k<=4)sDate=sDate.addDays(-1);}else{  K++; if(k<=4)sDate=sDate.addDays(-1); }} else { if(k==1){K=1;}else{k=k--;} if(k<=4)sDate=sDate.addDays(-1); } }while(sDate.Date()>actualSDate && sDate.Date()>=(System.now()).Date() && k<=4); DateTime tempDate=sDate;  while(sDate.Date()<(System.now()).Date()){sDate=sDate.addDays(1);} if(actualSDate==sDate.Date()){wrapper.dis=true;}  DateTime todayDate=System.now(); Date tD=todayDate.date();  Date sD=sDate.date(); if(sD<=tD){  wrapper.dis=true; } DateTime DOW=sDate; String dayOfWeek=DOW.format('EEE'); Date currentDate=date.newinstance(sDate.year(), sDate.month(), sDate.day()); map<DateTime, list<DateTime>> Slots=new map<DateTime, list<DateTime>>();  List<DateTime> monSlots=new List<DateTime>(); List<DateTime> tueSlots=new List<DateTime>(); List<DateTime> wedSlots=new List<DateTime>(); List<DateTime> thuSlots=new List<DateTime>(); List<DateTime> friSlots=new List<DateTime>(); List<DateTime> satSlots=new List<DateTime>();  List<DateTime> sunSlots=new List<DateTime>(); List<Registration__c> allReg=[Select Id, Name, Registration_Time__c,End_Time__c From Registration__c where  Registration_Time__c >=: System.now()  AND Resource__c =:expertId AND Expert_Location__c =:locationId  AND Product2__c=:serviceId];  list<Time_Off__c> TimeOff=[Select Id,Name,Start_Time__c, End_Time__c,End_Date__c  ,Resource__c, Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c!=NULL AND End_Time__c!=NULL AND Type__c!=Null]; for(integer i=1;i<=4;i++) {     if(dayOfWeek=='Mon') { if(resource[0].Mon_Start_Time__c==null || resource[0].Mon_End_Time__c==null || ToffDates.contains(currentDate) )   { i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');   }else{    wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Mon_Start_Time__c,   resource[0].Mon_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );   Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset())   { wrapper.mapOfslots2.put(key, mb.get(key));  } currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }  } else if(dayOfWeek=='Tue') {if(resource[0].Tue_Start_Time__c==null || resource[0].Tue_End_Time__c==null || ToffDates.contains(currentDate)) {i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');}else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Tue_Start_Time__c, resource[0].Tue_End_Time__c,expertSlot, resource[0].Break_Start_Time__c, resource[0].Break_End_Time__c );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset())  { wrapper.mapOfslots2.put(key, mb.get(key));  }currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Wed') {if(resource[0].Wed_Start_Time__c==null || resource[0].Wed_End_Time__c==null || ToffDates.contains(currentDate)) {i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Wed_Start_Time__c,  resource[0].Wed_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );   Map<Date, Map<String, String>> mb=m.mapOfslots2;for(Date key : mb.keyset()) {wrapper.mapOfslots2.put(key, mb.get(key)); }currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;dayOfWeek=forDOW.format('EEE');  } } else if(dayOfWeek=='Thu') { if(resource[0].Thu_Start_Time__c==null || resource[0].Thu_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');}else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Thu_Start_Time__c,  resource[0].Thu_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,   resource[0].Break_End_Time__c  ); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1);DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Fri')   { if(resource[0].Fri_Start_Time__c==null || resource[0].Fri_End_Time__c==null || ToffDates.contains(currentDate)) {  i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Fri_Start_Time__c,    resource[0].Fri_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,   resource[0].Break_End_Time__c  ); Map<Date, Map<String, String>> mb=m.mapOfslots2;  for(Date key : mb.keyset())   {  wrapper.mapOfslots2.put(key, mb.get(key));  } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');   }   } else if(dayOfWeek=='Sat') { if(resource[0].Sat_Start_Time__c==null || resource[0].Sat_End_Time__c==null || ToffDates.contains(currentDate)) {  i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sat_Start_Time__c,  resource[0].Sat_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset())   { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Sun')  { if(resource[0].Sun_Start_Time__c==null || resource[0].Sun_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1;   currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  }else{wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sun_Start_Time__c,  resource[0].Sun_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c ); Map<Date, Map<String, String>> mb=m.mapOfslots2;  for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));}   currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');     }  } } String dayOW; DateTime forDayOW; tempDate=tempDate.addDays(-1); forDayOW=tempDate;  dayOW=forDayOW.format('EEE');integer exist=0; while(tempDate.Date()>=actualSDate && tempDate.Date()>=(system.now()).Date()){ if(tempDate.Date()==(system.now()).Date()){wrapper.dis=true; break;} if(dayOW=='Mon'){if(resource[0].Mon_Start_Time__c!=null && resource[0].Mon_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}} else if(dayOW=='Tue'){if(resource[0].Tue_Start_Time__c!=null && resource[0].Tue_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} } else if(dayOW=='Wed'){if(resource[0].Wed_Start_Time__c!=null && resource[0].Wed_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} }  else if(dayOW=='Thu'){if(resource[0].Thu_Start_Time__c!=null && resource[0].Thu_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} }  else if(dayOW=='Fri'){if(resource[0].Fri_Start_Time__c!=null && resource[0].Fri_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} }                else if(dayOW=='Sat'){if(resource[0].Sat_Start_Time__c!=null && resource[0].Sat_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} }else if(dayOW=='Sun'){if(resource[0].Sun_Start_Time__c!=null && resource[0].Sun_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;} } } if(exist==1){ wrapper.dis=false;  } return wrapper; }
    
    @AuraEnabled public static Wrapper confirmSlot(String regDate, String regId,String expId,String serId,String locId ){ system.debug('regId===>'+regId); system.debug('values===>'+expId+', '+serId+', '+locId); id currentReg=regId; Wrapper wrapper=new Wrapper(); DateTime regSDate=DateTime.valueOf(regDate); try{List<Queue_Allocation__c> QLA=[Select Id,Queue__c from  Queue_Allocation__c   where Resource__c=:expId AND Service__c=:serId AND Queue__r.Location__c=:locId]; String queueID=''; if(QLA.size()>=1){queueID=QLA[0].Queue__c;} system.debug('queueID===>'+queueID); if(queueID==''){queueID=null;} wrapper.updateSlotReg=[Select Id,Name,Resource__c,Resource__r.Name, Product2__c, Expert_Location__c, Resource__r.Time_Slot_Duration__c, Registration_Time__c, End_Time__c, Registration_End_Time__c, Queue__c, Status__c,Booked_Current_Status__c, Serve_Start_Time__c ,Serve_Finished_Time__c from Registration__c where id=:regId ]; system.debug('updateSlotReg==>'+wrapper.updateSlotReg); integer slot=integer.valueOf( wrapper.updateSlotReg[0].Resource__r.Time_Slot_Duration__c); DateTime regEDate=regSDate.addMinutes(slot); wrapper.updateSlotReg[0].Registration_Time__c=regSDate; wrapper.updateSlotReg[0].End_Time__c=regEDate; wrapper.updateSlotReg[0].Status__c='Booked'; wrapper.updateSlotReg[0].Booked_Current_Status__c=''; wrapper.updateSlotReg[0].Resource__c=expId; wrapper.updateSlotReg[0].Product2__c=serId; wrapper.updateSlotReg[0].Expert_Location__c=locId; wrapper.updateSlotReg[0].Queue__c=null; wrapper.updateSlotReg[0].Token_Number__c=null; wrapper.updateSlotReg[0].Check_In__c=False; wrapper.updateSlotReg[0].Serve_Finished_Time__c=null; wrapper.updateSlotReg[0].Serve_Start_Time__c=null; update wrapper.updateSlotReg; wrapper.updateSlotReg=[Select Id,Name,Registration_Time__c,End_Time__c,Status__c,Resource__c,Product2__c,Expert_Location__c, Resource__r.Name,Product2__r.Name,Expert_Location__r.Name From Registration__c where id=:regId]; }catch(Exception e){ system.debug('Error in updating the record. '+e); } return wrapper; }
    
    @AuraEnabled public static Wrapper slotOnDateChange(String changeDate, String resID,String expertId,String serviceId,String locationId){ Wrapper wrapper=new Wrapper(); if(Date.valueof(changeDate)<=Date.today()){wrapper.dis=true;}    changeDate+='T00:00:00.000Z'; Datetime sDate = Datetime.valueOfGMT(changeDate.replace('T', ' ')); wrapper sam=getResource(resID);   List<Resource__c> resource=sam.getRes; integer expertSlot=integer.valueOf(resource[0].Time_Slot_Duration__c);  Date actualSDate=resource[0].Start_Date__c;    DateTime actualEDate=resource[0].End_Date__c;   if(sDate<=actualSDate){sDate=actualSDate;wrapper.dis=true;}  String dayOW;  DateTime forDayOW;  DateTime tempDate=sDate.addDays(-1);   forDayOW=tempDate;  dayOW=forDayOW.format('EEE');   integer exist=0; while(tempDate.Date()>=actualSDate && tempDate.Date()>=(system.now()).Date()){ if(tempDate.Date()==(system.now()).Date()){wrapper.dis=true; }    if(dayOW=='Mon'){if(resource[0].Mon_Start_Time__c!=null && resource[0].Mon_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }  else if(dayOW=='Tue'){if(resource[0].Tue_Start_Time__c!=null && resource[0].Tue_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }else if(dayOW=='Wed'){if(resource[0].Wed_Start_Time__c!=null && resource[0].Wed_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }   else if(dayOW=='Thu'){if(resource[0].Thu_Start_Time__c!=null && resource[0].Thu_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }  else if(dayOW=='Fri'){if(resource[0].Fri_Start_Time__c!=null && resource[0].Fri_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }      else if(dayOW=='Sat'){if(resource[0].Sat_Start_Time__c!=null && resource[0].Sat_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     }  else if(dayOW=='Sun'){if(resource[0].Sun_Start_Time__c!=null && resource[0].Sun_End_Time__c!=null){exist=1;tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');} else{tempDate=tempDate.addDays(-1);forDayOW=tempDate; dayOW=forDayOW.format('EEE');wrapper.dis=true;}     } } if(exist==1){  wrapper.dis=false;  } if(sDate>actualEDate) {system.debug('No slots for the selected period.');  } else{ DateTime DOW=sDate;  String dayOfWeek=DOW.format('EEE');  Date currentDate=date.newinstance(sDate.year(), sDate.month(), sDate.day());system.debug('currentDate==>'+currentDate); map<DateTime, list<DateTime>> Slots=new map<DateTime, list<DateTime>>();  List<DateTime> monSlots=new List<DateTime>(); List<DateTime> tueSlots=new List<DateTime>(); List<DateTime> wedSlots=new List<DateTime>();   List<DateTime> thuSlots=new List<DateTime>();  List<DateTime> friSlots=new List<DateTime>(); List<DateTime> satSlots=new List<DateTime>();  List<DateTime> sunSlots=new List<DateTime>(); List<Registration__c> allReg=[Select Id, Name, Registration_Time__c,End_Time__c  From Registration__c   where   Registration_Time__c >=: System.now()   AND Resource__c =:expertId AND Expert_Location__c =:locationId AND Product2__c=:serviceId]; List<Time_Off__c> TimeOff=[Select Id,Name,Start_Date__c,End_Date__c,Start_Time__c, End_Time__c, Resource__c, Type__c    From Time_Off__c  where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c!=NULL AND End_Time__c!=NULL AND Type__c!=Null]; List<Time_Off__c> TimeOffDate=[Select Id,Name,Start_Time__c,Start_Date__c, End_Time__c ,End_Date__c, Resource__c, Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c=NULL AND End_Time__c=NULL AND Type__c!=Null]; Set<Date> ToffDates=new Set<Date>();  Date TOFFDate; for(integer i=0;i<=TimeOffDate.size()-1;i++){ TOFFDate=TimeOffDate[i].Start_Date__c; while(TOFFDate<=TimeOffDate[i].End_Date__c)       { ToffDates.add(TOFFDate);  TOFFDate=TOFFDate.addDays(1);    }  } for(integer i=1;i<=4;i++) {     if(currentDate>actualEDate ){i++;wrapper.disl=true;}  else{  if(dayOfWeek=='Mon')   {if(resource[0].Mon_Start_Time__c==null || resource[0].Mon_End_Time__c==null || ToffDates.contains(currentDate) )   { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');   }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Mon_Start_Time__c,       resource[0].Mon_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c  );    Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset())  { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Tue')    {if(resource[0].Tue_Start_Time__c==null || resource[0].Tue_End_Time__c==null || ToffDates.contains(currentDate) )  { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');  }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Tue_Start_Time__c,     resource[0].Tue_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c  ); Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset())  {wrapper.mapOfslots2.put(key, mb.get(key)); }  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE');  }  } else if(dayOfWeek=='Wed')  {if(resource[0].Wed_Start_Time__c==null || resource[0].Wed_End_Time__c==null || ToffDates.contains(currentDate) )   { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');   }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Wed_Start_Time__c,  resource[0].Wed_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,       resource[0].Break_End_Time__c );      Map<Date, Map<String, String>> mb=m.mapOfslots2;  for(Date key : mb.keyset())    {   wrapper.mapOfslots2.put(key, mb.get(key));  } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;     dayOfWeek=forDOW.format('EEE'); }  } else      if(dayOfWeek=='Thu')  { if(resource[0].Thu_Start_Time__c==null || resource[0].Thu_End_Time__c==null || ToffDates.contains(currentDate) ) {i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE'); system.debug('dayOfWeek==>'+dayOfWeek); }else{wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Thu_Start_Time__c,   resource[0].Thu_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,resource[0].Break_End_Time__c  );  Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); }currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }  } else if(dayOfWeek=='Fri')  { if(resource[0].Fri_Start_Time__c==null || resource[0].Fri_End_Time__c==null || ToffDates.contains(currentDate) ) { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE'); }else{wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Fri_Start_Time__c,  resource[0].Fri_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,   resource[0].Break_End_Time__c   );Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); }currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Sat') {if(resource[0].Sat_Start_Time__c==null || resource[0].Sat_End_Time__c==null || ToffDates.contains(currentDate) ) { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');  system.debug('dayOfWeek==>'+dayOfWeek);  }else{ wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sat_Start_Time__c,    resource[0].Sat_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c  ); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));} currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE'); }} else if(dayOfWeek=='Sun')  {if(resource[0].Sun_Start_Time__c==null || resource[0].Sun_End_Time__c==null  || ToffDates.contains(currentDate) )  { i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE'); }else{  wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sun_Start_Time__c,   resource[0].Sun_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c ); Map<Date, Map<String, String>> mb=m.mapOfslots2;  for(Date key : mb.keyset()) {    wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1);     DateTime forDOW=currentDate;    dayOfWeek=forDOW.format('EEE');  }  } } } String dayOWL;    DateTime forDayOWL;  forDayOWL=currentDate;  dayOWL=forDayOWL.format('EEE');  integer existL=0;  if(currentDate>actualEDate){wrapper.disl=true; } while(currentDate<=actualEDate){  if(currentDate==actualEDate){wrapper.disl=true; }  if(dayOWL=='Mon'){if(resource[0].Mon_Start_Time__c!=null && resource[0].Mon_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     }else if(dayOWL=='Tue'){if(resource[0].Tue_Start_Time__c!=null && resource[0].Tue_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     } else if(dayOWL=='Wed'){if(resource[0].Wed_Start_Time__c!=null && resource[0].Wed_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     } else if(dayOWL=='Thu'){if(resource[0].Thu_Start_Time__c!=null && resource[0].Thu_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     } else if(dayOWL=='Fri'){if(resource[0].Fri_Start_Time__c!=null && resource[0].Fri_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     }    else if(dayOWL=='Sat'){if(resource[0].Sat_Start_Time__c!=null && resource[0].Sat_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     }  else if(dayOWL=='Sun'){if(resource[0].Sun_Start_Time__c!=null && resource[0].Sun_End_Time__c!=null){existL=1;currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');wrapper.disl=true;}     }                   else{currentDate=currentDate.addDays(1);forDayOWL=currentDate; dayOWL=forDayOWL.format('EEE');} } if(existL==1){    wrapper.disl=false;  } }  return wrapper; }
    
     @AuraEnabled
    public static Wrapper getSlot(String expertId,String serviceId,String locationId){
        Wrapper wrapper=new Wrapper(); system.debug('getSlots server controller is called. exp==> '+expertId+' ser==> '+serviceId+' loc==>'+locationId);  
        try{
            List<Work_Planner__c> WP=[Select Id,Name,Location__c,Product__c  FROM Work_Planner__c where Location__c=:locationId  AND   Product__c=:serviceId];   set<String> WPIDS=new set<String>();   for(integer i=0;i<=WP.size()-1;i++) { WPIDS.add(WP[i].Id); }  List<Resource__c> Res=[Select Id,Name  FROM Resource__c Where Id=:expertId ];  set<String> ResIDS=new set<String>();  for(integer i=0;i<=Res.size()-1;i++) { ResIDS.add(Res[i].Id); }  List<Resource_Requirement__c> RR=[Select Id, Name,Preferred_Resource__c,Work_Planner__c From Resource_Requirement__c Where Preferred_Resource__c IN : ResIDS    AND Work_Planner__c IN : WPIDS];
            String resID; if(RR.size()>=1){resID =RR[0].Preferred_Resource__c;  }  
            wrapper sam=getResource(resID);    List<Resource__c> resource=sam.getRes;  wrapper.resource=resource;
            integer expertSlot=integer.valueOf(resource[0].Time_Slot_Duration__c);  Date startDate=resource[0].Start_Date__c;  DateTime endDate=resource[0].End_Date__c;  DateTime todaysDate=System.now(); Date ddd=date.today();  Date currentDate;  if(startDate>=todaysDate.Date()){currentDate=startDate;}else{ currentDate=todaysDate.Date();}  Time myTime = Time.newInstance(0, 0, 0, 0);DateTime DOW=DateTime.newInstance(currentDate,myTime);   String dayOfWeek=DOW.format('EEE');   map<DateTime, list<DateTime>> Slots=new map<DateTime, list<DateTime>>();  List<DateTime> monSlots=new List<DateTime>(); List<DateTime> tueSlots=new List<DateTime>();  List<DateTime> wedSlots=new List<DateTime>(); List<DateTime> thuSlots=new List<DateTime>();   List<DateTime> friSlots=new List<DateTime>(); List<DateTime> satSlots=new List<DateTime>(); List<DateTime> sunSlots=new List<DateTime>();  List<Registration__c> allReg=[Select Id, Name, Registration_Time__c,End_Time__c  From Registration__c  where  Registration_Time__c >=: System.now() AND Resource__c =:expertId AND Expert_Location__c =:locationId AND Product2__c=:serviceId]; list<Time_Off__c> TimeOff=[Select Id,Name,Start_Date__c,End_Date__c,Start_Time__c, End_Time__c, Resource__c, Type__c    From Time_Off__c  where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c!=NULL AND End_Time__c!=NULL AND Type__c!=Null]; list<Time_Off__c> TimeOffDate=[Select Id,Name,Start_Time__c,Start_Date__c,End_Time__c ,End_Date__c, Resource__c, Type__c From Time_Off__c where Resource__c=:resource[0].Id AND Start_Date__c!=null AND End_Date__c!=null AND  Start_Time__c=NULL AND End_Time__c=NULL AND Type__c!=Null]; Set<Date> ToffDates=new Set<Date>(); Date TOFFDate; for(integer i=0;i<=TimeOffDate.size()-1;i++){  TOFFDate=TimeOffDate[i].Start_Date__c; while(TOFFDate<=TimeOffDate[i].End_Date__c) { ToffDates.add(TOFFDate);    TOFFDate=TOFFDate.addDays(1);   } }  
            for(integer i=1;i<=4;i++) { if(currentDate>endDate ){system.debug('currentDate is greater than the endDate');i++;wrapper.disl=true;}else{   if(dayOfWeek=='Mon')  {if(resource[0].Mon_Start_Time__c==null || resource[0].Mon_End_Time__c==null || ToffDates.contains(currentDate))   {i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE');  }else{ Wrapper m=generateSlots(allReg, TimeOff, currentDate, resource[0].Mon_Start_Time__c,   resource[0].Mon_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c ); Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset()) {   wrapper.mapOfslots2.put(key, mb.get(key)); }  currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); } }     else if(dayOfWeek=='Tue')  { if(resource[0].Tue_Start_Time__c==null || resource[0].Tue_End_Time__c==null || ToffDates.contains(currentDate))  {i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE');  system.debug('dayOfWeek==>'+dayOfWeek); }else{  Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Tue_Start_Time__c,  resource[0].Tue_End_Time__c,expertSlot, resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key));}currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Wed') {if(resource[0].Wed_Start_Time__c==null || resource[0].Wed_End_Time__c==null|| ToffDates.contains(currentDate)){i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE'); system.debug('dayOfWeek==>'+dayOfWeek); }else{ Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Wed_Start_Time__c,   resource[0].Wed_End_Time__c,expertSlot,  resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); }currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); }  }  else if(dayOfWeek=='Thu') { if(resource[0].Thu_Start_Time__c==null || resource[0].Thu_End_Time__c==null || ToffDates.contains(currentDate)) { i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE'); system.debug('dayOfWeek==>'+dayOfWeek); }else{ Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Thu_Start_Time__c,  resource[0].Thu_End_Time__c,expertSlot , resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c);   Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) { wrapper.mapOfslots2.put(key, mb.get(key)); }currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Fri') { if(resource[0].Fri_Start_Time__c==null || resource[0].Fri_End_Time__c==null || ToffDates.contains(currentDate)){i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); }else{ Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Fri_Start_Time__c,  resource[0].Fri_End_Time__c,expertSlot , resource[0].Break_Start_Time__c, resource[0].Break_End_Time__c ); Map<Date, Map<String, String>> mb=m.mapOfslots2; for(Date key : mb.keyset()) {wrapper.mapOfslots2.put(key, mb.get(key)); }  currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE'); } } else if(dayOfWeek=='Sat') {  if(resource[0].Sat_Start_Time__c==null || resource[0].Sat_End_Time__c==null || ToffDates.contains(currentDate)){ i=i-1;  currentDate=currentDate.addDays(1);   DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); }else{ Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sat_Start_Time__c,  resource[0].Sat_End_Time__c,expertSlot , resource[0].Break_Start_Time__c,  resource[0].Break_End_Time__c); Map<Date, Map<String, String>> mb=m.mapOfslots2;  for(Date key : mb.keyset())   { wrapper.mapOfslots2.put(key, mb.get(key)); } currentDate=currentDate.addDays(1); DateTime forDOW=currentDate;  dayOfWeek=forDOW.format('EEE');  } } else if(dayOfWeek=='Sun') { if(resource[0].Sun_Start_Time__c==null || resource[0].Sun_End_Time__c==null || ToffDates.contains(currentDate))  { i=i-1; currentDate=currentDate.addDays(1);  DateTime forDOW=currentDate;   dayOfWeek=forDOW.format('EEE');  }else{   Wrapper m=generateSlots(allReg, TimeOff,currentDate, resource[0].Sun_Start_Time__c,      resource[0].Sun_End_Time__c,expertSlot ,  resource[0].Break_Start_Time__c,    resource[0].Break_End_Time__c );Map<Date, Map<String, String>> mb=m.mapOfslots2;   for(Date key : mb.keyset())  {wrapper.mapOfslots2.put(key, mb.get(key));} currentDate=currentDate.addDays(1); DateTime forDOW=currentDate; dayOfWeek=forDOW.format('EEE'); } } } } }catch(Exception e){system.debug('Error occurred...'+e);}
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper  changeExpert(String location,String service){   
        Wrapper wrapper=new Wrapper();  List<Work_Planner__c> wpls=[Select Id from Work_Planner__c where Location__c=:location AND Product__c=:service];Set<String> wpids=new Set<String>(); for(integer i=0;i<=wpls.size()-1;i++){ wpids.add(wpls[i].Id); }  List<Resource_Requirement__c> rrls=[Select Id, Preferred_Resource__c From Resource_Requirement__c   where Work_Planner__c IN:wpids ]; Set<String> resls=new Set<String>();  for(integer i=0;i<=rrls.size()-1;i++){resls.add(rrls[i].Preferred_Resource__c);}   List<Queue_Allocation__c> QLA=[Select Id,Resource__c From Queue_Allocation__c Where Service__c=:service AND Queue__r.Location__c=:location AND Active__c=true ];
        for(integer i=0;i<=QLA.size()-1;i++){   if(resls.contains(QLA[i].Resource__c)){ wrapper.ExpertIds.add(QLA[i].Resource__c);  }  }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper changeLocation(String locationId){  
        Wrapper wrapper=new Wrapper();
        List<Expert_Location__c> forlocName=[select Id,Name From Expert_Location__c where Id=:locationId];   wrapper.locName=forlocName[0].Name; List<Work_Planner__c> WP=[Select Id,Name,Location__c,Product__c FROM Work_Planner__c   where  Location__c=:locationId  ];   set<String> wpIDS=new set<String>();  for(integer i=0;i<=WP.size()-1;i++)  {   wpIDS.add(WP[i].Id); }   List<Resource__c> Res=[Select Id FROM Resource__c ]; set<String> resIDs=new set<String>();  for(integer i=0;i<=Res.size()-1;i++) { resIDs.add(Res[i].Id); }  List<Resource_Requirement__c> RR=[Select Id, Name,Preferred_Resource__c,Work_Planner__c,   Work_Planner__r.Product__c     From Resource_Requirement__c  Where Preferred_Resource__c IN : resIDs  AND Work_Planner__c IN : wpIDS ]; for(integer i=0;i<=RR.size()-1;i++) {wrapper.ServiceIds.add(RR[i].Work_Planner__r.Product__c); }  List<Queue_Allocation__c> QLA=[Select Id,Resource__c,Service__c,Queue__c FROM Queue_Allocation__c   where Queue__r.Location__c=:locationId AND Service__c!=null AND Resource__c!=null AND Active__c=true]; set<String> serQueue=new set<String>();   set<String> fser=new set<String>();  for(integer i=0;i<=QLA.size()-1;i++) { serQueue.add(QLA[i].Service__c); }  for(String s:serQueue) {wrapper.ServiceIds.contains(s);fser.add(s);} wrapper.ServiceIds.clear();      wrapper.ServiceIds=fser;  return wrapper;
    }
    
   
    @AuraEnabled
    public static Wrapper getResource(String resID){
        Wrapper wrapper=new Wrapper();
        wrapper.getRes=[Select Id, Name, Start_Date__c, End_Date__c,Time_Slot_Duration__c,Mon_Start_Time__c, Mon_End_Time__c,
                        Tue_Start_Time__c, Tue_End_Time__c,Wed_Start_Time__c, Wed_End_Time__c,Thu_Start_Time__c, Thu_End_Time__c,
                        Fri_Start_Time__c, Fri_End_Time__c,Sat_Start_Time__c, Sat_End_Time__c,Sun_Start_Time__c, Sun_End_Time__c,
                        Break_Start_Time__c, Break_End_Time__c From Resource__c where Id=:resID];
        return wrapper;
    }
    
    @AuraEnabled
    public static List<Attachment> uploadFile(String parent, String fileName, String base64Data, String contentType) { 
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8'); Attachment a = new Attachment();  a.parentId = parent; a.Body = EncodingUtil.base64Decode(base64Data); a.Name = fileName; a.ContentType = contentType; 
        insert a;
        System.debug(a.Id);
        List<Attachment> MYATS = [Select Id, Name, ParentId, ContentType From Attachment Where ParentId  =:parent Order By CreatedDate Asc];
        return MYATS;        
    }
    
    @AuraEnabled
    public static List<Note> SaveNotes(String NN, String regID) {   
        Note myNote = (Note) JSON.deserialize(NN, Note.class); wrapper wrapper=new wrapper(); try{  upsert myNote;  } catch(Exception e) { system.debug('Errro=>'+e.getMessage());wrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); } List<Note> MYATS = [Select Id, Title, ParentId From Note Where ParentId=:regID Order By CreatedDate Asc]; return MYATS;
    }
    
    @AuraEnabled
    public static wrapper  DeleteAT(String RAId, String ObjName){ 
        Wrapper wrapper=new Wrapper();
        try{ String query = 'select Id from ' +ObjName+ ' Where Id =:RAId'; SObject AT = Database.query(query); delete AT;} catch(Exception e) { system.debug('Errorr occured...'+e.getMessage()); wrapper.errorMsg = e.getMessage() +' Line Number @ : '+ e.getLineNumber(); }
        return wrapper;
    }
    
    @AuraEnabled
    public static wrapper getResources(String teamId,String loc,String ser){
        Wrapper wrapper=new Wrapper();
        List<Work_Planner__c> WP=[Select Id From Work_Planner__c where Location__c=:loc AND Product__c=:ser ]; 
        Set<String> wpids=new Set<String>();
        for(integer i=0;i<WP.size();i++) { wpids.add(WP[i].Id);  }
        List<Resource_Requirement__c> RR=[Select Id,Preferred_Resource__c From Resource_Requirement__c Where Work_Planner__c IN:wpids];  
        Set<String> RRres=new Set<String>();
        for(integer i=0;i<RR.size();i++ ) { RRres.add(RR[i].Preferred_Resource__c); }
        List<Team_Member__c> getResFromTM=[Select Id, Resource__c From Team_Member__c Where Resource__c IN:RRres AND Team__c=:teamId];  
        Set<String> resFromTM=new Set<String>();
        for(integer i=0;i<getResFromTM.size();i++) {  resFromTM.add(getResFromTM[i].Resource__c); }
        List<Queue_Allocation__c> QA=[Select id,Resource__c From Queue_Allocation__c Where Queue__r.Location__c=:loc AND Service__c=:ser AND Resource__c IN:resFromTM  AND Active__c=True AND Queue__r.Status__c='Active'] ;
        for(integer i=0;i<QA.size();i++) { wrapper.allresources.add(QA[i].Resource__c);    }
        return wrapper;  
    }
    
    @AuraEnabled 
    public static Records getRegRecords(){
        Records rec=new Records();
        return rec;
    } 
    
    public class Records{
        @AuraEnabled public Registration__c regRecords {get;set;} 
        @AuraEnabled public String waitingTime {get;set;}
        public Records(){
            regRecords = new Registration__c();
        }
    }
    
    public class selectOptions {
        @AuraEnabled public String label     { get; set; }
        @AuraEnabled public String value     { get; set; }  @AuraEnabled public Boolean selected { get; set; }
        
        public selectOptions(String lab, string val) { 
            label = lab;//selected = false;
            value = val;  }  public selectOptions(String lab, string val, Boolean sel) {label = lab; value = val; selected = sel;
        }
    }
    
    public class Wrapper{
        @AuraEnabled public  List<Selectoptions> allCategory            { get;set;}
        @AuraEnabled public List<Registration__c> records             {get;set;}  @AuraEnabled public String   errorMsg                                   {get;set;}
        @AuraEnabled public Set<String> allLocations                            {get;set;}  @AuraEnabled public String   LocationId                                 {get;set;}
        @AuraEnabled public map<String, Object> mapOfRecords                   {get;set;}  @AuraEnabled public String   serviceId                                  {get;set;}
        @AuraEnabled public boolean existLocation                               {get;set;}
        @AuraEnabled public boolean inProgress                                  {get;set;}
        @AuraEnabled public List<Registration__c> ObjectValues        {get;set;}
        @AuraEnabled public boolean updateStatus                                {get;set;}
        @AuraEnabled public boolean updateStatusForCancel                       {get;set;}
        @AuraEnabled public List<User> userName                                 {get;set;} 
        @AuraEnabled public List<RecordType> recordTypeName                     {get;set;}
        @AuraEnabled public list<Registration__c> getReschudle        {get;set;} @AuraEnabled public String bookedTime                                   {get;set;}
        @AuraEnabled public List<String> slots                                  {get;set;}
        @AuraEnabled public List<DateTime> dslots                               {get;set;} @AuraEnabled public DateTime resDate                                    {get;set;}
        
        @AuraEnabled public boolean updateTimeSlot                              {get;set;} @AuraEnabled public Date sDay                                           {get;set;}
        
        @AuraEnabled public Map<Date, List<DateTime>> mapOfslots                {get;set;} @AuraEnabled public String ExpertName                                   {get;set;}
        @AuraEnabled public DateTime todaysDate                                {get;set;}
        @AuraEnabled public List<Registration__c> updateSlotReg       {get;set;}
        @AuraEnabled public Map<Date, Map<String,String>> mapOfslots2           {get;set;}
        @AuraEnabled public List<DateTime> dateExist                            {get;set;}
        @AuraEnabled public List<Resource__c> resource                {get;set;}
        @AuraEnabled public Set<String> ExpertIds                               {get;set;}
        @AuraEnabled public Set<String> ServiceIds                              {get;set;}
        @AuraEnabled public Set<String> LocationIds                             {get;set;}
        @AuraEnabled public Set<String> programs                                {get;set;}
        @AuraEnabled public boolean dis                                         {get;set;}
        @AuraEnabled public boolean disl                                        {get;set;}
        @AuraEnabled public List<Work_Planner__c> WP                  {get;set;} 
        @AuraEnabled public List<Resource_Requirement__c> RR          {get;set;}
        @AuraEnabled public List<Resource__c> Res                     {get;set;}
        @AuraEnabled public set<String> allService                              {get;set;}
        @AuraEnabled public List<Queue__c> Queue                      {get;set;}
        @AuraEnabled public List<Resource__c> getRes                 {get;set;}
        @AuraEnabled public Set<String> allresources                            {get;set;} 
        @AuraEnabled public Set<String> allServices                             {get;set;} 
        @AuraEnabled public List<Queue__c> getLocation                {get;set;}  @AuraEnabled public  String   fser {get;set;}
        @AuraEnabled public String   fres                                       {get;set;} @AuraEnabled public String   floc                                       {get;set;}
        @AuraEnabled public String   locName                                    {get;set;}
        @AuraEnabled public List<Attachment> Attachments                       {get;set;} 
        @AuraEnabled public List<Note> Notes                                   {get;set;}  
        @AuraEnabled public Boolean   showTeam                                  {get;set;}  @AuraEnabled public  String resName {get;set;}    @AuraEnabled public String selectedTeamID                               {get;set;}
        @AuraEnabled public List<Records> regRecords                            {get;set;} @AuraEnabled public String currentProgram    {get;set;}
        @AuraEnabled public String        errmsg                                {get;set;}
        @AuraEnabled public List<Resource_Group__c>  allResGroup      {get;set;}  @AuraEnabled public  String selRG            {get;set;}
        @AuraEnabled public String                             selRes            {get;set;}
        @AuraEnabled public List<String>                       QueueFields      {get;set;}
        @AuraEnabled public List<String>                 appointmentFields      {get;set;}
        @AuraEnabled public List<String>                 customerFields         {get;set;} 
        @AuraEnabled public List<String>                 meetingFields          {get;set;} 
        @AuraEnabled public List<String>                 schudlarFields         {get;set;}   @AuraEnabled public Integer                      wbRefresh              { get;set;}
        @AuraEnabled public String                       SelectedUserName       { get;set;} //User Resource__c
        @AuraEnabled public String   appointmentFiler{ get;set;}
        public Wrapper(){
            QueueFields=new List<String>();
            appointmentFields=new List<String>();
            customerFields=new List<String>();
            meetingFields=new List<String>();
            schudlarFields=new List<String>();
            allResGroup=new List<Resource_Group__c>();
            errmsg=null;
            selRes=null;
            regRecords=new List<Records>();
            allLocations=new set<String>(); 
            mapOfRecords=new map<String, Object>();
            existLocation=false;
            records=new List<Registration__c>();
            ObjectValues=new List<Registration__c>();
            updateStatus=false;
            updateStatusForCancel=false;
            userName=new List<User>();
            recordTypeName=new List<RecordType>();
            inProgress=false;
            getReschudle=new List<Registration__c>();
            slots=new List<String>();
            dslots=new List<DateTime>();
            updateTimeSlot=false;
            mapOfslots=new Map<Date, List<DateTime>>();
            updateSlotReg=new  List<Registration__c>();
            mapOfslots2=new Map<Date, Map<String, String>>();
            dateExist=new List<DateTime>(); 
            resource=new List<Resource__c>();
            ExpertIds=new Set<String>();
            ServiceIds=new Set<String>();
            LocationIds=new Set<String>();
            programs=new Set<String>();
            dis=false;
            disl=false;
            WP=new List<Work_Planner__c>();
            RR=new List<Resource_Requirement__c>();
            Res=new List<Resource__c>();
            allService=new set<String>();
            Queue=new List<Queue__c>();
            getRes=new  List<Resource__c>();
            allresources=new Set<String>();
            allServices=new Set<String>();
            getLocation=new List<Queue__c>();
            Attachments=new List<Attachment>();  
            Notes=new List<Note>(); 
            showTeam=false;
            allCategory = new List<Selectoptions>(); 
            SelectedUserName='';
            appointmentFiler='';
        }
    }
       
}