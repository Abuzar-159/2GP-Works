public with sharing class Queue_Sch {
    @AuraEnabled
    Public list<TimeSlot> TimeSlotList             {get;set;} 
    @AuraEnabled
    Public Date selectedDate                       {get;set;}
    @AuraEnabled
    Public list<TimeSlot> AllTimeSlotList             {get;set;}
    @AuraEnabled  
    Public List< Resource__c > AvailableResources               { get; set; }
    @AuraEnabled  
    public List< Id > AvailableUserIds               { get; set; } 
    
    public Queue_Sch(){ 
        AvailableUserIds = new List<Id>();
        TimeSlotList=new list<TimeSlot>();
        selectedDate=System.today();
        AllTimeSlotList=new list<TimeSlot>();
        AvailableResources = new List< Resource__c >();
    }
    
    public class customException extends Exception {} 
    
    @AuraEnabled 
    public static wrapper updateWTExceed(String RegId){
        Wrapper wrapper=new Wrapper();
        try{
            if(String.isNotEmpty(RegId)){
                Registration__c reg = new Registration__c();
                reg = [Select id,Wait_Time_Exceeded__c From Registration__c where id=:RegId]; 
            if(reg.Id != null){ reg.Wait_Time_Exceeded__c=true; /*update reg;*/
            
            List<SObject> safereg = FLSHelper.getSafeRecords(
    new List<SObject>{reg}, // record if the items are just list
    'Registration__c',
    AccessType.UPDATABLE
);
List<Registration__c> typedreg = new List<Registration__c>();
for (SObject s : safereg) {
    typedreg.add((Registration__c)s);
}
if (!typedreg.isEmpty()) {
    update typedreg;
}
}
            }
            return wrapper;  
        }catch(Exception e){ system.debug('Error ==>'+e);  wrapper.errMsg=String.valueOf(e); return wrapper;
                           }
    }
    
    @AuraEnabled(cacheable=true) 
    public static wrapper getQueueRecords(String location){
        Wrapper wrapper=new Wrapper();
        try{
            List<Queue__c> queueOfloc=[Select Id From Queue__c where Location__c=:location AND Status__c='Active']; 
            if(queueOfloc.size()>0){   
                wrapper.records=[Select id,Name, Customer_Name__c,Expert_Location__r.Image__c, Token_Number__c,Customer_Lastname__c, Customer_Email__c,
                                 Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,
                                 Product2__r.Name, Company__c,Status__c,waiting_Time__c,
                                 Booked_Date__c,RecordTypeId,Product2__r.Wait_Threshold__c,Booked_Current_Status__c,
                                 Registration_Time__c,Resource__c,Resource__r.Time_Slot_Duration__c, Checked_in_Date_Time__c
                                 From Registration__c where Status__c='Booked' AND 
                                 Appointment_DateDt__c = Today And
                                 Expert_Location__c=:location
                                 AND Product2__c!=null
                                 AND Check_In__c=True Order by Booked_Date__c ASC];
                Boolean exist=false;
                for(Registration__c reg : wrapper.records){ if(reg.Booked_Current_Status__c=='InProgress'){  exist=true; Wrapper.TokenReg=reg; } }
                if(!exist){
                    if(wrapper.records.size()>0){ Wrapper.TokenReg=wrapper.records[0];}
                }
              
                
            }
            return wrapper;    
        }catch(Exception e){ wrapper.errMsg='Exception'+e; system.debug('Error occured.'+e); return wrapper;
                           }   
        
    }
    
    @AuraEnabled 
    public static wrapper setLocations(String location){
        Wrapper wrapper=new Wrapper();
        try{  
            List<SystemCode__c> sysWB=new List<SystemCode__c>();
            sysWB=[Select Workbench_Refresh__c from SystemCode__c limit 1];
            if(sysWB.size()>0) wrapper.wbRefresh=integer.valueof(sysWB[0].Workbench_Refresh__c); 
            system.debug('wbRefresh==>'+wrapper.wbRefresh );    
            List<Queue__c> getQueueLocations=[SELECT Id,Location__c,Location__r.Name From Queue__c WHERE Status__c='Active']; 
            Set<String> qloc=new Set<String>(); for(integer i=0;i<=getQueueLocations.size()-1;i++){ qloc.add(getQueueLocations[i].Location__c); }  
            for(String loc : qloc){wrapper.allLocations.add(loc);}
            if(String.isNotEmpty(location)){    
                wrapper.getLocation= [SELECT Id, Location__c, Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' AND Location__c != null Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            }else{ 
                wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where  Status__c = 'Active' AND Location__c != null Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            }
            system.debug('wrapper.getLocation=>'+wrapper.getLocation);
            
            if(wrapper.getLocation.size()>0){
                wrapper.floc=wrapper.getLocation[0].Location__c; 
                system.debug('loc==>'+wrapper.floc);    
                List<Expert_Location__c> loc = [Select Id From Expert_Location__c where id=:wrapper.getLocation[0].Location__c];
                List<Resource_Requirement__c> RReq = new List<Resource_Requirement__c>();
                RReq = [Select id,Work_Planner__c,Work_Planner__r.Location__c,Work_Planner__r.Product__c,Resource_Group__c FROM Resource_Requirement__c 
                        Where Work_Planner__r.Product__c!=null AND Work_Planner__r.Status__c='Approved' AND
                        Work_Planner__r.Location__c=:wrapper.getLocation[0].Location__c AND Resource_Group__c!=null];
                system.debug('RReq==>'+RReq);
                Set<String> resg=new Set<String>();
                
                for(Resource_Requirement__c RR  : RReq){
                    wrapper.allServices.add(RR.Work_Planner__r.Product__c);
                    resg.add(RR.Resource_Group__c);
                } 
                List<Resource__c> Res = new List<Resource__c>();
                Res = [Select id from Resource__c where Resource_Group__c IN :resg];  
                for(Resource__c r : Res)wrapper.allresources.add(r.id);
                system.debug('allres=>'+wrapper.allresources);   
                system.debug('allres=>'+wrapper.allServices);
                wrapper.allCategory.add(new selectOptions('--All Category--', '--All Category--'));
                wrapper.allType.add(new selectOptions('--All Type--', '--All Type--'));
                wrapper.allSubType.add(new selectOptions('--All Sub Type--', '--All Sub Type--'));
                Set<String> allType=new Set<String>();Set<String> allCategory=new Set<String>();Set<String> allSubType=new Set<String>();
                List<Product2> forPrograms = new List<Product2>();
                if(wrapper.allServices.size() > 0) forPrograms = [Select id,Membership_Program__c from Product2 where Id IN : wrapper.allServices AND Membership_Program__c!=null];
                
                for(String str:allType){wrapper.allType.add(new selectOptions(str, str));}
                for(String str:allSubType){wrapper.allSubType.add(new selectOptions(str, str));}
                for(String str:allCategory){wrapper.allCategory.add(new selectOptions(str, str));}  
                Wrapper forProgrms = getlookups(wrapper.floc);
                wrapper.allPrograms = forProgrms.allPrograms; 
                system.debug('prgrms==>'+wrapper.allPrograms);   
                String can = 'Cancelled';
                String com = 'Completed';
                String no = 'No Show';
                String book = 'Booked';
                //Status__c!=\'Cancelled\' AND '+ ' Status__c!=\'Completed\' AND '+ ' Status__c!=\'No Show\' AND '
                if(String.isNotEmpty(wrapper.floc)){
                    wrapper.records = [Select id,Name, Customer_Name__c,Wait_Time_Exceeded__c, Token_Number__c,Customer_Lastname__c, Customer_Email__c,
                                       Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,
                                       Product2__r.Name, Company__c,Status__c,waiting_Time__c,
                                       Booked_Date__c,RecordTypeId,Product2__r.Wait_Threshold__c,Booked_Current_Status__c,
                                       Registration_Time__c,Resource__c,Resource__r.Name,Resource__r.User__c, Resource__r.Time_Slot_Duration__c, Checked_in_Date_Time__c
                                       From Registration__c where Expert_Location__c =: wrapper.floc AND Registration_Time__c = null AND Status__c != :can 
                                       //AND Product2__c=:wrapper.fser
                                       //AND Resource__c=:wrapper.fres
                                       Order by Booked_Date__c ASC Limit 500];
                    
                    wrapper.bookedAppointment = [Select Id, Name, Purpose__c, Information__c, Account__c, Category_of_registration__c, Customer_Email__c, Customer_Name__c, Customer_Lastname__c, Customer_Contact__c,
                                                 Customer_Status__c, Customer_Type__c, Discount__c, Event__c, Event__r.Name, Event_Zone__c, Event_Zone__r.Name, Expert__c, Expert_Location__c, Meeting_Status__c, 
                                                 Membership_Amount__c, Membership_Points__c, Product2__c, Registration_DateD__c, Registration_End_Time__c, Registration_Price__c, Registration_DateT__c, Registration_Type__c, 
                                                 Registration_Time__c, Status__c, Total_Due__c, Total_Due_Amount__c, Event_Zone__r.Event_Zone_Location__c, Event_Zone__r.Event_Zone_Location__r.Name, Expert_Location__r.Show_Experts__c, 
                                                 Expert_Location__r.Name, Expert_Location__r.Address__c, Expert_Location__r.City__c, Expert_Location__r.Province_State__c, Expert_Location__r.Country__c, Expert_Location__r.Zip_Code__c, 
                                                 Event__r.Start_Date__c, Resource__c, Resource__r.Name,Resource__r.User__c, Event__r.End_Date__c, Product2__r.Name, Registration__c, End_Time__c, Contact__c,Contact__r.MailingCity,Contact__r.MailingState, 
                                                 Contact__r.MailingCountry,Contact__r.MailingPostalCode, Where_Location_Voice_Video__c,Member__c,Member__r.Name,Appointment_DateDt__c,Contact__r.Name From Registration__c Where Appointment_DateDt__c != null 
                                                 AND Expert_Location__c =: wrapper.floc AND Status__c =: book AND Registration_Time__c != null AND End_Time__c != null and Event__c=null Order By LastModifiedDate DESC Limit 100];
                }
                
                integer size=wrapper.records.Size();
                if(size<=0){ wrapper.existLocation=true; }
                for(integer index=0;index<=wrapper.records.size()-1;index++) { 
                    wrapper.mapOfRecords.put(String.valueof(index), wrapper.records[index]); 
                }  
            }
        }catch(Exception e){
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
        return wrapper; 
    }
    
    @AuraEnabled 
    public static wrapper getFilterValues(String loc,String ser,String res,String event,String rtype){
        Wrapper wrapper=new Wrapper();
        system.debug('loc==>'+loc+' ser==>'+ser+' res==>'+res+' event==>'+event+' rtype==>'+rtype);
        if(loc!=null && ser!=null){
            wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c
                        FROM  Work_Planner__c
                        where Location__c=:loc// AND Location__r.RecordTypeId=:rtype
                        AND   Product__c=:ser];}
        else if(loc!=null && event!=null){ wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c where Location__c=:loc AND Event__c=:event ]; //// AND Location__r.RecordTypeId=:rtype
                                         } else if(loc!=null && ser==null && event==null){
                                             wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c
                                                         FROM  Work_Planner__c
                                                         where Location__c=:loc //AND Location__r.RecordTypeId=:rtype
                                                        ]; 
                                         }
        else{
            wrapper.WP=[Select Id,Name,Location__c,Product__c,Event__c FROM  Work_Planner__c ];
        }
        system.debug('wrapper.WP==>'+wrapper.WP);        
        set<String> WPIds=new set<String>();set<String> resGroup=new set<String>();
        for(integer i=0;i<=wrapper.WP.size()-1;i++) {   WPIds.add(wrapper.WP[i].Id); }
        if(res!=null){
            List<Resource__c> resForRG=[Select id,Resource_Group__c from Resource__c where id=:res and Resource_Group__c!=null];
            system.debug('resForRG==>'+resForRG);
            if(resForRG.size()>0){
                wrapper.RR=[Select Id, Name,Preferred_Resource__c,Resource_Group__c,Work_Planner__c,Work_Planner__r.Location__c, Work_Planner__r.Product__c, Work_Planner__r.Event__c From Resource_Requirement__c Where  Work_Planner__c IN:WPIds AND Resource_Group__c=:resForRG[0].Resource_Group__c
                           ];
                system.debug('wrapper.RR size==>'+wrapper.RR.size());
                for(Resource_Requirement__c rr:wrapper.RR)resGroup.add(rr.Resource_Group__c); wrapper.resFromRG=[Select id from Resource__c where Resource_Group__c IN : resGroup ];
                system.debug('resForRG==>'+resForRG); for(Resource__c resids: wrapper.resFromRG)wrapper.allresources.add(resids.id); 
                system.debug('resForRG size==>'+resForRG.size()); 
            }}
        else {
            wrapper.RR=[Select Id, Name,Preferred_Resource__c,Resource_Group__c,
                        Work_Planner__c,Work_Planner__r.Location__c,
                        Work_Planner__r.Product__c,Work_Planner__r.Event__c From Resource_Requirement__c Where  Work_Planner__c IN:WPIds ];
            for(Resource_Requirement__c rr:wrapper.RR)resGroup.add(rr.Resource_Group__c);
            wrapper.resFromRG=[Select id from Resource__c where Resource_Group__c IN : resGroup ];
            for(Resource__c resids: wrapper.resFromRG)wrapper.allresources.add(resids.id); 
        }
        set<String> RRLoc=new set<String>();
        for(integer i=0;i<=wrapper.RR.size()-1;i++)  {
            RRLoc.add(wrapper.RR[i].Work_Planner__r.Location__c);
            wrapper.allServices.add(wrapper.RR[i].Work_Planner__r.Product__c) ;
            // wrapper.allresources.add(wrapper.RR[i].Preferred_Resource__c) ; 
        }
        
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getlookups(String location){
        wrapper wrapper=new wrapper();
        system.debug('getlookups controller is called.'+location);
        List<Expert_Location__c> loc=[Select Id, Name From Expert_Location__c where id=:location];
        if(loc.size() > 0) wrapper.LocationName = loc[0].Name;
        wrapper filterwrap = getFilterValues(location,null,null,null,null);
        List<Product2> forPrograms=[Select id,Membership_Program__c from Product2 where id IN:filterwrap.allServices AND Membership_Program__c!=null];
        for(Product2 prgrms:forPrograms){
            wrapper.allPrograms.add(prgrms.Membership_Program__c);
        }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getSerForPrgrms(String location) {  //,String program
        Wrapper wrapper=new Wrapper();
        system.debug('getSerForPrgrms controller is called.'+location);
        List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
        wrapper filterwrap=getFilterValues(location,null,null,null,null);
        wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
        wrapper.allServices=filterwrap.allServices; 
        /*List<Product2> forPrograms=[Select id,Membership_Program__c from Product2 where id IN:wrapper.allServices AND Membership_Program__c=:program];
if(forPrograms.size()>0){wrapper.service=forPrograms[0].Id;}
*/
        
        list<Work_Planner__c> WorkPlannerList=new list<Work_Planner__c>();       
        WorkPlannerList=[SELECT Id, Name, Location__c,Location__r.Name, Product__c,Product__r.Name,Product__r.Membership_Program__c,Product__r.Membership_Program__r.Name
                         FROM Work_Planner__c
                         WHERE Status__c='Approved'AND Location__c=:location AND Product__c!=null AND Product__r.IsActive=true
                         Order By LastModifiedDate]; //AND Product__r.Membership_Program__c!=null 
        System.debug('getLocationsAndServices WorkPlannerList==>'+WorkPlannerList);
        
        set<Id> WPIds=new set<Id>();
        for(Work_Planner__c wp:WorkPlannerList) WPIds.add(wp.Id); 
        list<Resource_Requirement__c> RRList=new list<Resource_Requirement__c>();
        RRList=[SELECT Id, Name, Work_Planner__c, Work_Planner__r.Product__c,  Work_Planner__r.Location__c, Preferred_Resource__c,Location__c, Resource_Group__c,Work_Planner__r.Product__r.Membership_Program__c
                FROM Resource_Requirement__c 
                WHERE Resource_Group__c!=null
                AND Work_Planner__c IN:WPIds
                Order By LastModifiedDate];         
        System.debug('getTeams RRList=>'+RRList);
        
        
        wrapper.allServices.clear();
        wrapper.allCategory.add(new selectOptions('--All Category--', '--All Category--'));
        wrapper.allType.add(new selectOptions('--All Type--', '--All Type--'));
        wrapper.allSubType.add(new selectOptions('--All Sub Type--', '--All Sub Type--'));
        
        Set<String> allType=new Set<String>();Set<String> allCategory=new Set<String>();Set<String> allSubType=new Set<String>();
  
        
        for(Resource_Requirement__c rr:RRList)
            wrapper.allServices.add(rr.Work_Planner__r.Product__c);
        
        for(String str:allType){wrapper.allType.add(new selectOptions(str, str));}
        for(String str:allSubType){wrapper.allSubType.add(new selectOptions(str, str));}
        for(String str:allCategory){wrapper.allCategory.add(new selectOptions(str, str));}
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getFilterServices(String location, String ServiceId) { //,String program, String category,String typee,String subType
        Wrapper wrapper=new Wrapper();
        
        system.debug('getFilterServices controller is called location==>'+location+'  ,ServiceId==>'+ServiceId);
        List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
        wrapper filterwrap=getFilterValues(location,null,null,null,null);
        wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
        wrapper.allServices=filterwrap.allServices; 
        
        Set<String> allServcs=new set<string>();allServcs=wrapper.allServices;

        String query = 'select id,Name, Membership_Program__c from Product2 where id=:ServiceId '; 
        system.debug('Query==>'+query);
        List<Product2> forPrograms = Database.query(query);
        // List<Product2> forPrograms=[Select id,Membership_Program__c from Product2 where id IN:wrapper.allServices AND Membership_Program__c=:program];
        wrapper.allServices.clear();
        if(forPrograms.size()>0){wrapper.service=forPrograms[0].Id;}
        for(Product2 service:forPrograms){ wrapper.allServices.add(service.Id);
                                         }
        
        return Wrapper;
    }
    
    @AuraEnabled
    public static List<Registration__c> getBookedRegsList(String location,String resource, String service, String datefilterby, String searchfilterby) {
        try{
            String book = 'Booked';
            List<Registration__c> regs = new List<Registration__c>();
            String QueryFilter='';
            if(String.isNotEmpty(location)) QueryFilter = ' And Expert_Location__c=:location';
            if(String.isNotEmpty(resource)) QueryFilter += ' AND Resource__r.User__c=:resource';
            if(String.isNotEmpty(service)) QueryFilter += ' And Product2__c=:service';
            if(String.isNotEmpty(searchfilterby)) QueryFilter += ' And (Name like \'%' + searchfilterby + '%\' OR Customer_Name__c like \'%' + searchfilterby + '%\' OR Customer_Lastname__c like \'%' + searchfilterby + '%\' OR Customer_Email__c like \'%' + searchfilterby + '%\' OR Customer_Contact__c like \'%' + searchfilterby + '%\')';
            if(String.isNotEmpty(datefilterby)){
                if(datefilterby.contains('Today')) QueryFilter += ' AND DAY_ONLY(Registration_Time__c) = TODAY '; else if(datefilterby.contains('Future')) QueryFilter += ' AND DAY_ONLY(Registration_Time__c) > TODAY '; else if(datefilterby.contains('Past')) QueryFilter += ' AND DAY_ONLY(Registration_Time__c) < TODAY ';
            }
            String regBookFields='Select id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,Booked_Current_Status__c, '+
                ' Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Product2__r.Wait_Threshold__c, Product2__r.Name, Company__c,Status__c,waiting_Time__c,Booked_Date__c, Registration_Time__c,Resource__c,Resource__r.Time_Slot_Duration__c, Checked_in_Date_Time__c, '+
                ' Resource__r.Name,Resource__r.User__c,Member__c,Member__r.Name,Appointment_DateDt__c,End_Time__c,Contact__c,Contact__r.Name From Registration__c where Status__c = :book AND '+
                ' Product2__c != null AND Registration_Time__c != null AND End_Time__c != null AND Appointment_DateDt__c != null'+ QueryFilter +' Order by LastModifiedDate DESC limit 100';
            regs = Database.query(regBookFields); 
            return regs;
        } catch (Exception e) {
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    @AuraEnabled
    public static Wrapper getRegLocationqueueRecords(String location,String resource, String service,String eventid) { //getLocationqueueRecord,String program
        wrapper wrapper=new wrapper();
        try{
            system.debug('Actual values==>'+location+','+resource+', '+service+', '+eventid);
            // try{
            String res,ser,event;//,prgrm;
            if(service=='' || service==null){ ser=null;}else{ser=service;}   if(resource=='' || resource==null){res=null;}else{res=resource;} 
            
            system.debug('values==>'+location+' ,'+res+' ,'+ser+' Event '+event);
            List<Expert_Location__c> loc=[Select Id, Name From Expert_Location__c where id=:location];
            wrapper.getLocation= [SELECT Id, Event__c, Location__c, Location__r.Name  From Queue__c where Location__c =:location  Order By LASTMODIFIEDDATE DESC Limit 1 ]; 
            
            String QueryFilter='';
            if(String.isNotEmpty(location)) QueryFilter = ' And Expert_Location__c=:location';
            if(String.isNotEmpty(resource)) QueryFilter += ' AND Resource__r.User__c=:resource';
            if(String.isNotEmpty(service)) QueryFilter += ' And Product2__c=:service';
            String can = 'Cancelled';
            String com = 'Completed';
            String no = 'No Show';
            String book = 'Booked';
            String regFields='Select Id, Name, Customer_Name__c, Wait_Time_Exceeded__c, Token_Number__c, Customer_Lastname__c, Customer_Email__c, Booked_Current_Status__c, '+
                'Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name, Product2__r.Wait_Threshold__c, Product2__r.Name, Company__c, Status__c, waiting_Time__c, Booked_Date__c, Registration_Time__c, Resource__c, Resource__r.Time_Slot_Duration__c,Resource__r.User__c, Checked_in_Date_Time__c '+
                'From Registration__c where Registration_Time__c = null AND '+
                'Product2__c != null AND Status__c != :can '+ QueryFilter +' Order by Booked_Date__c ASC Limit 500 '; //Appointment_DateDt__c = Today AND 
            System.debug('wrapper.records QueryFilter==>'+QueryFilter);    
            wrapper.records = Database.query(regFields);  
            
            String regBookFields='Select id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,Booked_Current_Status__c, '+
                ' Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Product2__r.Wait_Threshold__c, Product2__r.Name, Company__c,Status__c,waiting_Time__c,Booked_Date__c, Registration_Time__c,Resource__c,Resource__r.Time_Slot_Duration__c, Checked_in_Date_Time__c, '+
                ' Resource__r.Name,Resource__r.User__c,Member__c,Member__r.Name,Appointment_DateDt__c,End_Time__c,Contact__c,Contact__r.Name From Registration__c where Status__c = :book AND '+
                ' Product2__c != null AND Registration_Time__c != null AND End_Time__c != null AND Appointment_DateDt__c != null '+ QueryFilter +' Order by LastModifiedDate DESC limit 100';
            wrapper.bookedAppointment = Database.query(regBookFields);  
            
            System.debug('wrapper.records==>'+wrapper.records.size());   
            
            if(service!=null){
                wrapper filterwrap=getFilterValues(location,null,null,null,null);   
                wrapper.getLocation= [SELECT Id, Location__c,Location__r.Name,Event__c  From Queue__c where Location__c =:location AND Status__c='Active' Order By LASTMODIFIEDDATE DESC Limit 1 ];  
                //List<Queue__c> queueOfloc=[Select Id From Queue__c where Location__c=:location AND Status__c='Active'];
                wrapper.allServices=filterwrap.allServices; 
                List<Product2> forPrograms = [Select id,Membership_Program__c from Product2 where Id IN:wrapper.allServices]; //  id=:service IN:wrapper.allServicesAND Membership_Program__c=:prgrm
                Set<String> serids=new Set<String>(); 
                for(Product2 prgrms:forPrograms){
                    serids.add(prgrms.id);  
                    wrapper.allPrograms.add(prgrms.Membership_Program__c);
                }
                if(wrapper.getLocation.size()>0){ if(wrapper.getLocation[0].Location__c != null) wrapper.LocationName=wrapper.getLocation[0].Location__r.Name; }
                System.debug('wrapper.LocationName=>'+wrapper.LocationName);   
            }
            
            integer size=wrapper.records.Size();
            if(size<=0) { wrapper.existLocation=true; }
            for(integer index=0;index<size;index++) {
                wrapper.mapOfRecords.put(String.valueof(index), wrapper.records[index]);
            }
            
            if(wrapper.getLocation.size()>0){ if(wrapper.getLocation[0].Location__c != null) wrapper.LocationName = wrapper.getLocation[0].Location__r.Name;  }
            
        }catch(Exception e){
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper serviceForExpert(String locationId ,String serviceID ){ 
        Wrapper wrapper=new Wrapper(); 
        List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:locationId];
        wrapper filterwrap=getFilterValues(locationId,serviceID,null,null,null); 
        for(integer i=0;i<=filterwrap.resFromRG.size()-1;i++) {
            wrapper.allresources.add(filterwrap.resFromRG[i].Id);     
        }
        return wrapper;   
    }
    
    @AuraEnabled
    public static Wrapper updateReg(String rId, String status) { 
        Wrapper wrapper = new Wrapper();
        try{System.debug('rId: '+rId+'status: '+status);
            Registration__c R = new Registration__c(id=rId,Status__c=status);
            update R;
            System.debug('rId: '+R.id+'status: '+R.Status__c);
        } catch(Exception e){ wrapper.errMsg=e.getMessage(); system.debug('Issue:'+e.getMessage());}
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper updateCancelReg(String Rg, String cancelReason) {
        Wrapper wrapper = new Wrapper();
        try{
            //Registration__c Reg = (Registration__c) JSON.deserialize(Rg, Registration__c .class);         
            Registration__c regNew=new Registration__c(); 
            if(Schema.sObjectType.Registration__c.isAccessible() && String.isNotEmpty(Rg))
                regNew=[SELECT Id, Name, status__c, Registration_Time__c,Total_Registration_Price__c, Customer_Email__c
                        FROM Registration__c WHERE Id=:Rg];
            regNew.status__c ='Cancelled'; if(String.isNotEmpty(cancelReason)) regNew.Cancellation_Reasons__c =cancelReason; 
            if(Schema.sObjectType.Registration__c.isAccessible() && Schema.sObjectType.Registration__c.isUpdateable()) {
                update regNew;
            }
        }catch(Exception e){ 
            wrapper.errMsg=e.getMessage();
        }
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper updateExistRecords(String qId, String fname, String lname, String email, String phone, String location,String expert, String service,  Map<Integer, Registration__c> existMap,String event,String queueId,DateTime selSlotST,DateTime selSlotET, String Reschedule){ // String programId,String category,String typee 
        try{
            system.debug('service==>'+service);       
            Product2 Prod=new Product2();
            if(String.isNotBlank(service)) Prod = [SELECT Id, Name, Membership_Program__c FROM Product2 WHERE Id=:service];   
            
            Wrapper wrapper=new Wrapper(); 
            DateTime SDT,EDT; System.debug('selSlotST==>'+selSlotST);
            if(selSlotST!=null){ // && selSlotST!='' 
                SDT=selSlotST; //DateTime.valueof(selSlotST); System.debug('selSlotST==>'+SDT);
                DateTime dTimeNow = System.now();
                if(SDT < dTimeNow){
                    Date stdateonly = date.newinstance(SDT.year(), SDT.month(), SDT.day()); Date nowdateonly = date.newinstance(dTimeNow.year(), dTimeNow.month(), dTimeNow.day());
                    if(stdateonly.daysBetween(nowdateonly)>0){
                         System.debug('This booking cannot be added for the past time.');
                        Wrapper.errMsg = 'This booking cannot be added for the past time.';  return wrapper;
                       
                    }
                }
            }
            
            System.debug('SDT==>'+SDT+' ,EDT==>'+EDT);  
            
            List<Product2> serviceSlotDuration=new  List<Product2>();   
            if(String.isNotBlank(service)){ 
                serviceSlotDuration = [Select id,Duration__c from Product2 where id=:Service ];
            }
            if(serviceSlotDuration.size()>0 && serviceSlotDuration[0].Duration__c != null){ if(SDT!=null) EDT=SDT.addMinutes(integer.valueof(serviceSlotDuration[0].Duration__c)); }
            if(EDT==null && SDT!=null)EDT=SDT.addMinutes(30);
            system.debug('SDT==>'+SDT+', EDT'+EDT);
            
            /*if(String.isNotBlank(service) && String.isNotBlank(email)){
List<Registration__c> RegistrationQueryList = [SELECT Id, Name FROM Registration__c WHERE Id != :qId And Customer_Email__c = : email AND Product2__c =: service And (Status__c = 'Booked' OR Status__c= 'On Waitlist' OR Status__c= 'Reserve')];
if(RegistrationQueryList.size() > 0) {
// Wrapper.errMsg = 'This booking cannot be added because of another booking with the same email address.'; 
//return wrapper; 
}
}

if(String.isNotBlank(service) && String.isNotBlank(phone)){
List<Registration__c> RegistrationQueryList = [SELECT Id, Name FROM Registration__c WHERE Id != :qId And Customer_Contact__c = : phone AND Product2__c =: service And (Status__c = 'Booked' OR Status__c= 'On Waitlist' OR Status__c= 'Reserve')];
if(RegistrationQueryList.size() > 0) {
// Wrapper.errMsg = 'This booking cannot be added because of another booking with the same phone number.';  
//return wrapper;
}
} */
            
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
            String ser = ''; String res = '';
            if(String.isNotBlank(expert)){ res=expert; } if(String.isNotBlank(service)){ ser=service; } 
            String qevent = '';
            List<Queue__c> queuforEvent = [Select id, Name, Location__c, Location__r.Name from Queue__c where Location__c=:location AND Status__c='Active' ]; 
            
            Registration__c recordToUpdate;
            //try {   
            recordToUpdate = [SELECT id,Name, Customer_Name__c,Check_In__c,Resource__r.Time_Slot_Duration__c, Customer_Lastname__c, Customer_Email__c,
                              Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Resource__c,Registration_Time__c,
                              Product2__r.Name,Event__c,Resource__r.User__c,Resource_Email__c From Registration__c WHERE id =:qId LIMIT 1];
            DateTime ED = System.now();
            recordToUpdate.Customer_Name__c = fname;
            recordToUpdate.Customer_Lastname__c = lname;
            recordToUpdate.Customer_Email__c = email;
            recordToUpdate.Customer_Contact__c = phone;
            if(String.isNotEmpty(location)) recordToUpdate.Expert_Location__c = location;
            if(String.isNotEmpty(qevent)) recordToUpdate.Event__c = qevent;
            if(String.isNotEmpty(ser)) recordToUpdate.Product2__c = ser;
            if(SDT!=null) recordToUpdate.Registration_Time__c=SDT; 
            if(EDT!=null) recordToUpdate.End_Time__c=EDT;
            if(SDT!=null) recordToUpdate.Status__c = 'Booked';
            if(String.isNotEmpty(Reschedule))  recordToUpdate.Cancellation_Reasons__c = Reschedule;
            //if(String.isNotEmpty(res)) recordToUpdate.Resource__c=res;
            if(queuforEvent.size()>0){ recordToUpdate.Queue__c=queuforEvent[0].Id; } else throw new customException('No Queue record available for selected location.');
            recordToUpdate.Booked_Date__c=System.now();
            recordToUpdate.Checked_in_Date_Time__c=System.now();
            if(Prod.Membership_Program__c!=null) recordToUpdate.Membership_Program__c=Prod.Membership_Program__c;//programId;
            
            Boolean newres = false;
            if(String.isNotBlank(res)){
                if(String.isNotEmpty(res)){
                    User existusr = new User(); existusr = [Select Id,Name, Email from User where Id =:res And IsActive = true];
                    if(recordToUpdate.Resource__c != null){
                        if(recordToUpdate.Resource__r.User__c != null && existusr.Id != null){
                            if(recordToUpdate.Resource__r.User__c != existusr.Id){ newres = true; }
                        }
                    }else newres = true;
                    
                    if(newres && existusr.Id != null){
                        List < Resource__c > UserResources = new List < Resource__c >();
                        UserResources=[Select Id, Name, User__c, Start_Date__c, End_Date__c, User__r.Email, Email__c  From Resource__c WHERE User__c =: res AND Start_Date__c>=TODAY 
                                       AND End_Date__c >= TODAY AND Resource_Group__c!=null AND RecordType.DeveloperName='Workforce' LIMIT 1];
                        if(UserResources.size()==0) UserResources = [Select Id, Name, User__c, Start_Date__c, End_Date__c,  User__r.Email, Email__c 
                                                                     From Resource__c WHERE User__c =: res AND RecordType.DeveloperName='Workforce' LIMIT 1];
                        if(UserResources.size()>0) {
                            recordToUpdate.Resource__c = UserResources[0].Id;
                            if(UserResources[0].Email__c != null){recordToUpdate.Resource_Email__c=UserResources[0].Email__c;}
                            else if(UserResources[0].User__r.Email != null){recordToUpdate.Resource_Email__c=UserResources[0].User__r.Email;}
                        }
                        else throw new customException('Selected resource not available.');
                        system.debug('updateExistRecords UserResources==>'+UserResources.Size());
                    }
                    else{
                        if(recordToUpdate.Resource_Email__c == null)recordToUpdate.Resource_Email__c=existusr.Email;
                    }
                }
            } //else recordToUpdate.Resource__c=null;
            
            if(!recordToUpdate.Check_In__c){  
                recordToUpdate.Booked_Current_Status__c='NotInProgress';
                recordToUpdate.Check_In__c=True;
                recordToUpdate.Customer_Status__c='Attended';
                wrapper.records=[Select id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,
                                 Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Booked_Current_Status__c,
                                 Product2__r.Name, Company__c,Product2__r.Wait_Threshold__c,
                                 Resource__r.Time_Slot_Duration__c,waiting_Time__c,Booked_Date__c, Checked_in_Date_Time__c
                                 From Registration__c where Status__c='Booked'  
                                 AND Expert_Location__c=:location AND  Appointment_DateDt__c = Today //And  Product2__c =:service AND Resource__c=:resource
                                 AND Check_In__c=True Order by Booked_Date__c ASC ];
                integer recSize=wrapper.records.size()+1;
                if(recSize<=9){ recordToUpdate.Token_Number__c='0'+String.valueof(recSize); }else{ recordToUpdate.Token_Number__c=String.valueof(recSize);   }
                system.debug('recordToUpdate==>'+recordToUpdate);
            }
            // update recordToUpdate; 
            List<SObject> saferecordToUpdate = FLSHelper.getSafeRecords(
    new List<SObject>{recordToUpdate}, // record if the items are just list
    'Registration__c',
    AccessType.UPDATABLE
);
List<Registration__c> typedrecordToUpdate = new List<Registration__c>();
for (SObject s : saferecordToUpdate) {
    typedrecordToUpdate.add((Registration__c)s);
}
if (!typedrecordToUpdate.isEmpty()) {
    update typedrecordToUpdate;
}

              
            //} catch(DmlException e) { System.debug('An unexpected error has occurred: ' + e.getMessage());}
            Wrapper forAllRecords= getRegLocationqueueRecords(location,res,ser,null); //,null
            wrapper.records = forAllRecords.records;
            integer size = wrapper.records.Size(); 
            if(size<=0) { wrapper.existLocation=true;} 
            for(integer index=0;index<size;index++) { wrapper.updateMap.put(String.valueof(index), wrapper.records[index]);  }
            return wrapper;
        }catch(Exception e){
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Wrapper insertRecords(String fname, String lname, String email, String phone, String location, String service, Map<Integer, Registration__c> existMap,String resource, String event,String queueId,DateTime selSlotST,DateTime selSlotET, String ServiceId){ // String  String programId,String category,String typee  
        try{
            system.debug('insertRecords enter resource==>'+resource);
            Wrapper wrapper = new Wrapper();
            
            /* if(ServiceId != Null && ServiceId != '' && email != Null && email != ''){
List<Registration__c> RegistrationQueryList = [SELECT Id, Name FROM Registration__c WHERE Customer_Email__c = : email AND Product2__c =: ServiceId And (Status__c = 'Booked' OR Status__c= 'On Waitlist' OR Status__c= 'Reserve')];
if(RegistrationQueryList.size() > 0) {
Wrapper.errMsg = 'This booking cannot be added because of another booking with the same email address.';  return wrapper; 
}
}

if(ServiceId != Null && ServiceId != '' && phone != Null && phone != ''){
List<Registration__c> RegistrationQueryList = [SELECT Id, Name FROM Registration__c WHERE Customer_Contact__c = : Phone AND Product2__c =: ServiceId And (Status__c = 'Booked' OR Status__c= 'On Waitlist' OR Status__c= 'Reserve')];if(RegistrationQueryList.size() > 0) {
Wrapper.errMsg = 'This booking cannot be added because of another booking with the same phone number.';   return wrapper;
}
} */
            
            //try{
            system.debug('ServiceId==>'+ServiceId); Product2 Prod=new Product2();
            if(String.isNotEmpty(ServiceId)) Prod= [SELECT Id, Name, Membership_Program__c FROM Product2 WHERE Id=:ServiceId];   
            
            DateTime SDT,EDT; System.debug('selSlotST==>'+selSlotST);
            if(selSlotST!=null){ // && selSlotST!='' 
                SDT=selSlotST;//DateTime.valueof(selSlotST); System.debug('selSlotST==>'+SDT);
                if(SDT < system.Now()){
                    Wrapper.errMsg = 'This booking cannot be added for the past time.'; 
                }
            }
            if(selSlotET!=null){
                EDT=selSlotET;//DateTime.valueof(selSlotET);
            }
            System.debug('SDT==>'+SDT+' ,EDT==>'+EDT);  
            String ser,res;  
            if(resource==null || resource=='' || resource.length()<=0) { res=''; }else{ res=resource; }    
            if(service==null || service=='' || service.length()<=0) { ser=null; }else{ ser=service; }
            /*if(SDT==null){ SDT=System.now(); }
            if(EDT==null) {
                List<Product2> serviceSlotDuration = new List<Product2>();   
                if(ser!=null){ serviceSlotDuration=[Select id,Duration__c from Product2 where id=:Service ]; }
                if(serviceSlotDuration.size()>0 && serviceSlotDuration[0].Duration__c != null){ EDT=SDT.addMinutes(integer.valueof(serviceSlotDuration[0].Duration__c)); }
                if(EDT==null){ EDT=SDT.addMinutes(30); }  
            }*/
            system.debug('SDT==>'+SDT+', EDT'+EDT);
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];  
            if(location==null || location==''){ location=null; }  
            if(service==null || service==''){ service=null; } 
            String qevent;
            List<Queue__c> queuforEvent=[Select id from Queue__c where Location__c=:location AND Status__c='Active']; 
            
            List<Registration__c> queue = new List<Registration__c>();   Registration__c q = new Registration__c();
            if(Schema.sObjectType.Registration__c.fields.Customer_Name__c.isCreateable()) {q.Customer_Name__c=fname; } 
            if(Schema.sObjectType.Registration__c.fields.Customer_Lastname__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Customer_Lastname__c.isUpdateable()) {q.Customer_Lastname__c=lname; } 
            if(Schema.sObjectType.Registration__c.fields.Customer_Email__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Customer_Email__c.isUpdateable())       {q.Customer_Email__c=email; }
            if(Schema.sObjectType.Registration__c.fields.End_Time__c.isCreateable() && Schema.sObjectType.Registration__c.fields.End_Time__c.isUpdateable())                   {q.End_Time__c=EDT; }
            if(Schema.sObjectType.Registration__c.fields.Registration_Time__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Registration_Time__c.isUpdateable()) {
                //System.debug('selSlotST bfr==>'+SDT);
                q.Registration_Time__c=SDT; 
                //System.debug('selSlotST aftr==>'+SDT);
            } 
            if(Schema.sObjectType.Registration__c.fields.End_Time__c.isCreateable() && Schema.sObjectType.Registration__c.fields.End_Time__c.isUpdateable())                   {
                q.End_Time__c=EDT;
            } 
            if(Schema.sObjectType.Registration__c.fields.Customer_Contact__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Customer_Contact__c.isUpdateable())   {q.Customer_Contact__c=phone; } 
            if(Schema.sObjectType.Registration__c.fields.Expert_Location__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Expert_Location__c.isUpdateable())     {q.Expert_Location__c=location;}   
            if(Schema.sObjectType.Registration__c.fields.Product2__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Product2__c.isUpdateable())                   {q.Product2__c=ser; } 
            List <Resource__c> UserResources = new List < Resource__c >(); 
            if(Schema.sObjectType.Registration__c.fields.Resource__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Resource__c.isUpdateable() && Schema.sObjectType.Registration__c.fields.Resource_Email__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Resource_Email__c.isUpdateable()){
                if(String.isNotEmpty(res)){ 
                    UserResources=[Select Id, Name, User__c, Start_Date__c, End_Date__c, User__r.Email, Email__c From Resource__c WHERE User__c =: res AND Start_Date__c>=TODAY AND End_Date__c >= TODAY AND Resource_Group__c!=null AND RecordType.DeveloperName='Workforce' LIMIT 1];
                    if(UserResources.size()==0) UserResources = [Select Id, Name, User__c, Start_Date__c, End_Date__c, User__r.Email, Email__c From Resource__c WHERE User__c =: res AND RecordType.DeveloperName='Workforce' LIMIT 1]; 
                    if(UserResources.size()>0) {
                        q.Resource__c = UserResources[0].Id;
                        if(UserResources[0].Email__c != null){q.Resource_Email__c=UserResources[0].Email__c;}
                        else if(UserResources[0].User__r.Email != null){q.Resource_Email__c=UserResources[0].User__r.Email;}
                    }
                    else throw new customException('Selected resource not available.');
                    system.debug('insertRecords UserResources==>'+UserResources.Size());
                } else throw new customException('Selected resource not available.');
            }
            //if(Schema.sObjectType.Registration__c.fields.User__c.isCreateable() && Schema.sObjectType.Registration__c.fields.User__c.isUpdateable()){ q.User__c =res;}
            if(queuforEvent.size()>0){
                if(Schema.sObjectType.Registration__c.fields.Queue__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Queue__c.isUpdateable())  {q.Queue__c=queuforEvent[0].Id; } 
            }else throw new customException('No Queue record available for selected location.');
            if(Schema.sObjectType.Registration__c.fields.Status__c.isCreateable() && Schema.sObjectType.Registration__c.fields.Status__c.isUpdateable()) {q.Status__c='Booked' ;} 
            q.Booked_Current_Status__c='NotInProgress';
            q.Booked_Date__c=System.now();
            q.Checked_in_Date_Time__c=System.now();
            q.Check_In__c=True;
            q.Customer_Status__c='Attended';
            if(Prod.Membership_Program__c!=null) q.Membership_Program__c=Prod.Membership_Program__c;//programId;
             
            q.Registration_Type__c='Walk in'; 
            
            wrapper.records=[Select id,Name, Customer_Name__c,Wait_Time_Exceeded__c,Token_Number__c, Customer_Lastname__c, Customer_Email__c,
                             Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,Booked_Current_Status__c,
                             Product2__r.Name, Company__c,Product2__r.Wait_Threshold__c,
                             Resource__r.Time_Slot_Duration__c,waiting_Time__c,Booked_Date__c, Checked_in_Date_Time__c
                             From Registration__c where Status__c='Booked' 
                             AND Expert_Location__c=:location AND  Appointment_DateDt__c = Today //And  Product2__c =:service AND Resource__c=:resource
                             AND Check_In__c=True Order by Booked_Date__c ASC ];
            system.debug(' wrapper.records=>'+ wrapper.records);
            system.debug(' wrapper.records size=>'+ wrapper.records.size());
            integer recSize=wrapper.records.size()+1;
            if(recSize<=9){ q.Token_Number__c='0'+String.valueof(recSize); }else{q.Token_Number__c=String.valueof(recSize);   }
            
            //chanegd by Arshad 11 Oct
            List<Contact> existContact = new List<Contact>();
            if(email != '' && phone != '') existContact = [Select Id, Name, Email, MobilePhone from Contact where Email=:email AND MobilePhone=:phone limit 1]; 
            else if(email != '' ) existContact = [Select Id, Name, Email, MobilePhone from Contact where Email=:email limit 1]; 
            else if(phone != '' ) existContact = [Select Id, Name, Email, MobilePhone from Contact where MobilePhone=:phone limit 1]; 
            
            if(email != '' && phone != '' && existContact.isEmpty())  existContact = [Select Id, Name, Email, MobilePhone from Contact where Email=:email limit 1]; 
            if(existContact.size()>0){
                system.debug('Exist Contact==>'+existContact[0].Id); q.Contact__c=existContact[0].Id; 
            }else{
                Contact Con = new Contact(FirstName=fname, LastName=lname, Email=email, MobilePhone=phone);
                if (Schema.sObjectType.contact.isCreateable() && Schema.sObjectType.Contact.isUpdateable())insert Con; 
                system.debug('New Contact==>'+Con.Id); 
                q.Contact__c=Con.Id; 
            }    
            
            system.debug('q==>'+q);
            //if (Schema.sObjectType.Registration__c.isCreateable()) {
            insert q;
            //}
            Wrapper forAllRecords= getRegLocationqueueRecords(location,res,ser,null); //,null
            wrapper.records=forAllRecords.records;
            integer size=wrapper.records.Size(); if(size<=0)  { wrapper.existLocation=true;} 
            for(integer index=0;index<size;index++) {  wrapper.updateMap.put(String.valueOf(index), wrapper.records[index]); }
            
            system.debug('wrapper==>'+wrapper);
            return wrapper;  
        }catch(Exception e){
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Wrapper searchRecords(String paramValue, String location){
        try{
            List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
            Wrapper wrapper = new Wrapper();
            wrapper.records=[Select id,Name, Customer_Name__c, Customer_Lastname__c, Checked_in_Date_Time__c, 
                             Customer_Contact__c, Registration_Time__c
                             From Registration__c where 
                             ( Name LIKE :('%' + paramValue + '%') 
                              OR Customer_Name__c LIKE :('%' + paramValue + '%')
                              OR Customer_Lastname__c LIKE :('%' + paramValue + '%')
                              OR Customer_Contact__c LIKE :('%' + paramValue + '%') )
                             AND Expert_Location__c=:location
                             AND Registration_Time__c=null
                             AND Product2__c!=null 
                             //AND Check_In__c=True
                             limit 5];
            return Wrapper;
        }catch (Exception e) {
            System.debug('Exception ~> '+ e.getMessage()+'; at line ~> '+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage()+'; at line ~> '+e.getStackTraceString());
        } 
    }
    
    @AuraEnabled
    public static Wrapper onfocusRecords(String location, String rtype){
        List<Expert_Location__c> loc=[Select Id From Expert_Location__c where id=:location];
        Date  today=(System.now()).Date();
        Wrapper wrapper = new Wrapper();
        wrapper.records=[Select id,Name, Customer_Name__c, Customer_Lastname__c, Customer_Email__c,
                         Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name,
                         Product2__r.Name, Company__c,Status__c, Checked_in_Date_Time__c,
                         Booked_Date__c
                         From Registration__c where
                         Customer_Lastname__c!=null
                         AND Registration_Time__c=null 
                         AND Expert_Location__c=:location 
                         AND Product2__c!=null
                         //AND Check_In__c=True
                         Order By LASTMODIFIEDDATE DESC Limit 5]; 
        return wrapper;
    }
    
    @AuraEnabled(cacheable=true) 
    Public static List<SelectOption> getCancellationReasons(){                     
        Schema.DescribeFieldResult fieldResult = Registration__c.Cancellation_Reasons__c.getDescribe();
        List < Schema.PicklistEntry > crList = fieldResult.getPicklistValues();
        List<SelectOption> CancellationReasonList=new List<SelectOption>();
        CancellationReasonList.add(new SelectOption('','--none--',false));
        for(Schema.PicklistEntry cr:crList) CancellationReasonList.add(new SelectOption(cr.value,cr.value,false)); 
        return CancellationReasonList;
    }  
    
    public class SelectOption {
        @AuraEnabled public String label { get;set; } @AuraEnabled public String value { get;set; } @AuraEnabled public Boolean disabled { get;set; } @AuraEnabled public Boolean escapeItem { get;set; }
        public SelectOption(String value, String label,Boolean isDisabled) {
            this.value = value; this.label = label; this.disabled = false; this.escapeItem = false;
        }
    }
    
    @AuraEnabled
    public static wrapper fetchExistRecords(String passId){
        Wrapper wrapper=new Wrapper();
        wrapper.records=[Select Id,Name, Customer_Name__c,Event__c, Customer_Lastname__c, Customer_Email__c,Contact__c,Contact__r.Name,
                         Customer_Contact__c, Expert_Location__c, Expert_Location__r.Name, Resource__r.User__c,
                         Product2__r.Name, Company__c,Resource__c,Product2__c,Membership_Program__c,
                         Check_In__c , Checked_in_Date_Time__c, Registration_Time__c, End_Time__c                     
                         From Registration__c where Id=:passId AND Product2__c!=null];
        
        return wrapper;
    }
    
    @AuraEnabled
    public static Wrapper getCheckinDetails(String regId){
        Wrapper wrapper=new Wrapper();
        
        List<Registration__c> regs=[SELECT id,Token_Number__c, Product2__c,Product2__r.Name, lastmodifieddate 
                                    FROM Registration__c where id=:regId
                                    limit 1];
        wrapper.serviceName=regs[0].Product2__r.Name;
        wrapper.lastmodified=String.valueOf((regs[0].lastmodifieddate).format('EEE, MMM d yyyy HH:mm:ss'));
        return wrapper;
    }
    
    public class selectOptions {
        @AuraEnabled public String label     { get; set; }
        @AuraEnabled public String value     { get; set; }
        @AuraEnabled public Boolean selected { get; set; }
        
        public selectOptions(String lab, string val) {
            label = lab;
            value = val;
            //selected = false;
        }
        public selectOptions(String lab, string val, Boolean sel) {
            label = lab; value = val; selected = sel;
        }
    }
    
    public class Wrapper{
        @AuraEnabled public  Registration__c              TokenReg                 { get; set;}
        @AuraEnabled @TestVisible public List<String> allrecords                                         { get; set;}
        @AuraEnabled @TestVisible public Map<String, Registration__c>  mapOfRecords            { get; set;}
        @AuraEnabled @TestVisible public List<Registration__c>  bookedAppointment            { get; set;}
        @AuraEnabled @TestVisible public  Map<String, Registration__c>  updateMap               { get; set;}
        @AuraEnabled @TestVisible public  List<Registration__c>          records                { get; set;}
        @AuraEnabled @TestVisible public  List<Queue__c>                 getLocation            { get; set;}
        @AuraEnabled @TestVisible public  Boolean                                  updateStatus           { get; set;} 
        @AuraEnabled @TestVisible public  Boolean                                  updateStatusForCancel  { get; set;} 
        @AuraEnabled @TestVisible public  String                                   service                { get; set;}
        @AuraEnabled @TestVisible public  String                                   serviceName            { get; set;}
        @AuraEnabled @TestVisible public  String                                   lastmodified            { get; set;}
        @AuraEnabled @TestVisible public  List<integer>                            timeSlot               { get; set;} 
        @AuraEnabled @TestVisible public  Boolean                                  existLocation          { get;set; } 
        @AuraEnabled @TestVisible public  List<Id>                                 allLocations           {get;set;}
        @AuraEnabled @TestVisible public  Set<Id>                                  serviceIds             {get;set;}
        @AuraEnabled @TestVisible public  Set<Id>                                  expertIds              {get;set;}
        @AuraEnabled @TestVisible public  List<Work_Planner__c>          WP                     {get;set;} 
        @AuraEnabled @TestVisible public List<Resource_Requirement__c>  RR                     {get;set;}
        @AuraEnabled @TestVisible public List<Resource__c>              Res                    {get;set;}
        @AuraEnabled @TestVisible public List<Resource__c>              resFromRG                      {get;set;} 
        @auraEnabled @TestVisible public set<String>                              allExperts             {get;set;}
        @AuraEnabled @TestVisible public  set<String>                              allServices            {get;set;}
        @AuraEnabled @TestVisible public  set<String>                              allresources           {get;set;}
        @AuraEnabled @TestVisible public  set<String>                              allEvents              {get;set;}  @AuraEnabled @TestVisible public  set<String>                             allCategories          {get;set;}  
        @AuraEnabled @TestVisible public  String                                   recType                {get;set;}   @AuraEnabled @TestVisible public  String                                   type                   {get;set;} @AuraEnabled public String                                     recTypeReg             {get;set;} 
        
        @AuraEnabled @TestVisible public String                                   EventService           {get;set;} 
        @AuraEnabled @TestVisible public String                                   fser                   {get;set;}
        @AuraEnabled @TestVisible public String                                   floc                   {get;set;}
        @AuraEnabled @TestVisible public set<String>                              allPrograms            {get;set;} 
        @AuraEnabled @TestVisible public String                                   fres                   {get;set;} 
        @AuraEnabled @TestVisible public String                                   currentProgram         {get;set;}
        @AuraEnabled @TestVisible public List<Selectoptions>                      allCategory            { get;set;}
        @AuraEnabled @TestVisible public List<Selectoptions>                      allType                { get;set;} 
        @AuraEnabled @TestVisible  public List<Selectoptions>                      allSubType             { get;set;}  
        @AuraEnabled @TestVisible public  String                                   errMsg                 { get;set;}  
        @AuraEnabled @TestVisible public List<Attachment>                         Attachments            { get;set;}   
        @AuraEnabled @TestVisible public Integer                                  wbRefresh              { get;set;} 
        @AuraEnabled @TestVisible public String                                  LocationName              { get;set;}  
        public Wrapper(){
            Attachments  = new List<Attachment>(); 
            errMsg       = null; LocationName=null;
            records      = new List<Registration__c>();
            bookedAppointment = new List<Registration__c>();
            getLocation  = new List<Queue__c>();
            timeSlot     = new List<integer>();
            allrecords   = new List<String>();
            mapOfRecords = new Map<String, Registration__c>();
            updateMap    = new Map<String, Registration__c>();
            updateStatus = false;
            wbRefresh = 0;
            updateStatusForCancel=false;
            service = floc = '';
            existLocation= false;
            allLocations = new List<Id>();
            serviceIds   = new Set<Id>();
            expertIds    = new Set<Id>();
            WP = new List<Work_Planner__c>();
            RR = new List<Resource_Requirement__c>();
            Res=new List<Resource__c>();
            resFromRG=new List<Resource__c>();
            allExperts   = new set<String>();
            allServices  = new set<String>();
            allresources = new set<String>();
            allEvents    = new Set<String>();
            allPrograms  = new Set<String>();
            allCategories= new Set<String>();
            allCategory = new List<Selectoptions>(); 
            allType = new List<Selectoptions>(); 
            allSubType = new List<Selectoptions>(); 
            TokenReg = new  Registration__c();
        }
        
    }
    
    @AuraEnabled
    public static MAP < String, String > getResourceSlots(String location, String Service, String Resource) {
        Wrapper wrapper = new Wrapper();
        system.debug('getResourceSlots values==>' + location + ',' + Service + ',' + Resource);
        List < Product2 > serviceSlotDuration = [Select id, Duration__c from Product2 where id =: Service];
        Decimal slot = 0;
        if (serviceSlotDuration.size() > 0) slot = serviceSlotDuration[0].Duration__c;
        if (slot == null) slot = 30;
        system.debug('slot=>' + slot);
        List < Time_Off__c > TOFF = [Select Id, Name, Start_Time__c, Start_Date__c,
                                     End_Time__c, End_Date__c,
                                     Resource__c,
                                     Type__c
                                     From Time_Off__c
                                     where Resource__c =: Resource AND Start_Date__c != null AND End_Date__c != Null AND Type__c != Null AND Start_Time__c != NULL AND End_Time__c != NULL
                                    ];
        system.debug('TOFF==>' + TOFF);
        Map < DateTime, DateTime > TODates = new Map < DateTime, DateTime > ();
        Date ST, todaysDate = (system.now()).Date();
        DateTime SelEDT, dayBST, dayBET, selDT = System.now();
        String dayOfWeek = selDT.format('EEE');
        List < Resource__c > finalRes = [Select Id, Name, Start_Date__c, End_Date__c, Time_Slot_Duration__c,
                                         Mon_Start_Time__c, Mon_End_Time__c,
                                         Tue_Start_Time__c, Tue_End_Time__c,
                                         Wed_Start_Time__c, Wed_End_Time__c,
                                         Thu_Start_Time__c, Thu_End_Time__c,
                                         Fri_Start_Time__c, Fri_End_Time__c,
                                         Sat_Start_Time__c, Sat_End_Time__c,
                                         Sun_Start_Time__c, Sun_End_Time__c,
                                         Break_Start_Time__c, Break_End_Time__c,
                                         Mon_Break_Start_Time__c, Mon_Break_End_Time__c,
                                         Tue_Break_Start_Time__c, Tue_Break_End_Time__c,
                                         Wed_Break_Start_Time__c, Wed_Break_End_Time__c,
                                         Thu_Break_Start_Time__c, Thu_Break_End_Time__c,
                                         Fri_Break_Start_Time__c, Fri_Break_End_Time__c,
                                         Sat_Break_Start_Time__c, Sat_Break_End_Time__c,
                                         Sun_Break_Start_Time__c, Sun_Break_End_Time__c,
                                         Description__c
                                         From Resource__c
                                         where Id =: Resource
                                        ];
        system.debug('finalRes==>' + finalRes);
        
        DateTime SD, ED;
        if (dayOfWeek == 'Mon' && finalRes[0].Mon_Start_Time__c != null && finalRes[0].Mon_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Mon_Start_Time__c); ED = DateTime.newInstance(selDT.Date(), finalRes[0].Mon_End_Time__c);
                                                                                                                }
        if (dayOfWeek == 'Tue' && finalRes[0].Tue_Start_Time__c != null && finalRes[0].Tue_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Tue_Start_Time__c); ED = DateTime.newInstance(selDT.Date(), finalRes[0].Tue_End_Time__c);
                                                                                                                }
        if (dayOfWeek == 'Wed' && finalRes[0].Wed_Start_Time__c != null && finalRes[0].Wed_End_Time__c != null) {
            SD = DateTime.newInstance(selDT.Date(), finalRes[0].Wed_Start_Time__c);
            ED = DateTime.newInstance(selDT.Date(), finalRes[0].Wed_End_Time__c);
        }
        if (dayOfWeek == 'Thu' && finalRes[0].Thu_Start_Time__c != null && finalRes[0].Thu_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Thu_Start_Time__c);ED = DateTime.newInstance(selDT.Date(), finalRes[0].Thu_End_Time__c);
                                                                                                                }
        if (dayOfWeek == 'Fri' && finalRes[0].Fri_Start_Time__c != null && finalRes[0].Fri_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Fri_Start_Time__c); ED = DateTime.newInstance(selDT.Date(), finalRes[0].Fri_End_Time__c);
                                                                                                                }
        if (dayOfWeek == 'Sat' && finalRes[0].Sat_Start_Time__c != null && finalRes[0].Sat_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Sat_Start_Time__c); ED = DateTime.newInstance(selDT.Date(), finalRes[0].Sat_End_Time__c);
                                                                                                                }
        if (dayOfWeek == 'Sun' && finalRes[0].Sun_Start_Time__c != null && finalRes[0].Sun_End_Time__c != null) { SD = DateTime.newInstance(selDT.Date(), finalRes[0].Sun_Start_Time__c);ED = DateTime.newInstance(selDT.Date(), finalRes[0].Sun_End_Time__c);
                                                                                                                }
        system.debug('SD and ED==>' + SD + ED);
        
        MAP < String, String > slots = new MAP < String, String > ();
        if (dayOfWeek == 'Mon' && finalRes[0].Mon_Break_Start_Time__c != null && finalRes[0].Mon_Break_End_Time__c != null) { dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Mon_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Mon_Break_End_Time__c);
                                                                                                                            }
        if (dayOfWeek == 'Tue' && finalRes[0].Tue_Break_Start_Time__c != null && finalRes[0].Tue_Break_End_Time__c != null) { dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Tue_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Tue_Break_End_Time__c);
                                                                                                                            }
        if (dayOfWeek == 'Wed' && finalRes[0].Wed_Break_Start_Time__c != null && finalRes[0].Wed_Break_End_Time__c != null) {
            dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Wed_Break_Start_Time__c); dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Wed_Break_End_Time__c);
        }
        if (dayOfWeek == 'Thu' && finalRes[0].Thu_Break_Start_Time__c != null && finalRes[0].Thu_Break_End_Time__c != null) {dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Thu_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Thu_Break_End_Time__c);
                                                                                                                            }
        if (dayOfWeek == 'Fri' && finalRes[0].Fri_Break_Start_Time__c != null && finalRes[0].Fri_Break_End_Time__c != null) {dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Fri_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Fri_Break_End_Time__c);
                                                                                                                            }
        if (dayOfWeek == 'Sat' && finalRes[0].Sat_Break_Start_Time__c != null && finalRes[0].Sat_Break_End_Time__c != null) {dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Sat_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Sat_Break_End_Time__c);
                                                                                                                            }
        if (dayOfWeek == 'Sun' && finalRes[0].Sun_Break_Start_Time__c != null && finalRes[0].Sun_Break_End_Time__c != null) {dayBST = DateTime.newInstance(selDT.Date(), finalRes[0].Sun_Break_Start_Time__c);dayBET = DateTime.newInstance(selDT.Date(), finalRes[0].Sun_Break_End_Time__c);
                                                                                                                            }
        system.debug('dayBST && dayBET==>' + dayBST + ', ' + dayBET);
        List < Registration__c > allReg = [Select id, Name, Registration_Time__c FROM Registration__c Where Registration_Time__c >=: System.NOW() AND Resource__c =: finalRes[0].Id AND Expert_Location__c =: location];
        Set < DateTime > allBlockR = new Set < DateTime > ();
        for (integer i = 0; i <= allReg.size() - 1; i++) { allBlockR.add(allReg[i].Registration_Time__c); }
        system.debug('allBlockR==>' + allBlockR);
        if (finalRes[0].Break_Start_Time__c != null && finalRes[0].Break_End_Time__c != null) {
            TODates.put(DateTime.newInstance(selDT.Date(), finalRes[0].Break_Start_Time__c), DateTime.newInstance(selDT.Date(), finalRes[0].Break_End_Time__c));
        }
        
        if (dayBST != null && dayBET != null) {
            TODates.put(dayBST, dayBET);
        }
        system.debug('Brofore==>' + TODates);
        if (dayBST != null && dayBET != null && finalRes[0].Break_Start_Time__c != null && finalRes[0].Break_End_Time__c != null) {
            if (dayBST > DateTime.newInstance(selDT.Date(), finalRes[0].Break_Start_Time__c)) {TODates.put(dayBST, dayBET);
                                                                                              } else {
                                                                                                  TODates.put(DateTime.newInstance(selDT.Date(), finalRes[0].Break_Start_Time__c), DateTime.newInstance(selDT.Date(), finalRes[0].Break_End_Time__c));
                                                                                              }
        }
        
        
        system.debug('after==>' + TODates);
        for (integer i = 0; i <= TOFF.size() - 1; i++) {
            ST = TOFF[i].Start_Date__c;
            while (ST <= TOFF[i].End_Date__c) {
                if (ST == (system.now()).Date()) { TODates.put(DateTime.newInstance(ST, TOFF[i].Start_Time__c), DateTime.newInstance(ST, TOFF[i].End_Time__c)); ST = ST.addDays(1);
                                                 } else {
                                                     ST = ST.addDays(1);
                                                 }
            } } system.debug('TOFF TODates==>' + TODates);
        
        List < DateTime > aList = new List < DateTime > ();
        aList.addAll(TODates.keySet());
        System.debug('aList==>' + aList);
        //aList.sort();
        System.debug('aList==>' + aList);
        TimeZone tz = UserInfo.getTimeZone();
        
        Boolean flag = false;
        While(SD <= ED) {
            if (aList.size() == 0) {if (SD >= System.now()) { if (allBlockR.contains(SD)) { SD = SD.addMinutes(Integer.valueof(slot)); } else {slots.put(string.valueof(SD), string.valueof(SD.addMinutes(Integer.valueof(slot))));SD = SD.addMinutes(Integer.valueof(slot));} } else { SD = SD.addMinutes(Integer.valueof(slot));
                                                                                                                                                                                                                                                                                      }
                                   }system.debug('Enter outer' + SD + ' , ' + ED);
            for (integer i = 0; i < aList.size(); i++) {
                DateTime key = aList[i]; if (SD >= System.now()) {
                    if (SD >= key && SD <= TODates.get(key)) {
                        SD = SD.addMinutes(Integer.valueof(slot));
                    } else {
                        if (allBlockR.contains(SD)) {SD = SD.addMinutes(Integer.valueof(slot));
                                                    } else {
                                                        if (SD <= ED) { slots.put(String.valueof(SD), string.valueof(SD.addMinutes(Integer.valueof(slot))));
                                                                      }
                                                        SD = SD.addMinutes(Integer.valueof(slot));
                                                        
                                                    }
                    } } else {
                        SD = SD.addMinutes(Integer.valueof(slot));
                    }
            }
        }
        system.debug('slots==>' + slots);
        return slots;
    }
    
    @AuraEnabled
    Public static Queue_Sch getTimeSlot(String LId, String sId, String EId, String TimeZoneName) {
        Date selDate=System.today();
        String Action='';
        System.debug('getTimeSlots LId=>'+LId+'  ,sId==>'+sId+'  ,EId==>'+EId+'  ,TimeZoneName==>'+TimeZoneName);
        Queue_Sch es = new Queue_Sch();
        if(EId!=null && EId!='null' && String.isNotEmpty(EID)){ 
            try {
                if(Action == null || Action == 'null') Action = '';
                Date selectedDate = date.valueof(selDate);
                if (Action == 'Next') selectedDate = selectedDate+1;
                if (Action == 'Prev') selectedDate = selectedDate-1;
                String MyTimezone = TimeZoneName;
                
                Date StartDate, EndDate;
                List < Resource__c > AvailableResourceListFR = new List < Resource__c > ();
                Map < Id, Resource__c > ResourceMap = new Map < Id, Resource__c > ();
                
                List < Resource__c > AvailableResourceList = new List < Resource__c >();//(OSRUtil.Resources.size() > 0)? OSRUtil.Resources : getResourcesByTimeZoneSingleUser(EID, LId, SId, MyTimezone, null, selectedDate);
                List < Resource__c > AvailableResourceListN = new List < Resource__c >();
                system.debug('Filtered AvailableResourceList==>'+AvailableResourceList.size());
                
                for(Resource__c R : AvailableResourceList){if(EID == R.User__c){ if (StartDate == null) StartDate = R.Start_Date__c; else if (R.Start_Date__c < StartDate) StartDate = R.Start_Date__c;if (EndDate == null) EndDate = R.End_Date__c; else if (R.End_Date__c > EndDate) EndDate = R.End_Date__c;Resource__c RN = new Resource__c(Name = R.Name, Id = R.Id, Start_Date__c = R.Start_Date__c, End_Date__c = R.End_Date__c); AvailableResourceListFR.add(RN);Resource__c RS = R.clone(true, true, false, false);  AvailableResourceListN.add(RS);
                                                                               }}
                if (StartDate == Null || StartDate < system.Today()) StartDate = system.Today();
                if (EndDate == Null) EndDate = system.Today();
                
                
                List < Resource__c > AvailableResourceListTemp = new List < Resource__c >();
                List < Resource__c > AvailableResourceListNTemp = new List < Resource__c >();
                
                if(String.isNotEmpty(EID)){
                    for(Integer i=0; i<AvailableResourceList.size(); i++){if(EID == AvailableResourceList[i].User__c){ AvailableResourceListTemp.add(AvailableResourceList[i]);AvailableResourceListNTemp.add(AvailableResourceListN[i]);
                                                                                                                     }
                                                                         } 
                    
                    AvailableResourceList = AvailableResourceListTemp;AvailableResourceListN = AvailableResourceListNTemp;}else{ AvailableResourceList = AvailableResourceList;AvailableResourceListN = AvailableResourceList;AvailableResourceListFR = AvailableResourceList; 
                                                                                                                               }
                ResourceMap = new Map < Id, Resource__c > (AvailableResourceListFR);
                system.debug('*** Filtered AvailableResourceList : '+AvailableResourceList.size());
                List < Holiday__c > HolidayList = [SELECT Id, Name, Active__c, Date__c FROM Holiday__c WHERE Date__c >= TODAY AND Active__c = true]; Product2 Product = [SELECT Id, Name, Users_Availability_In_Days__c, Duration__c, Allow_Not_Available_Slot__c, Allow_Not_Available_Day__c FROM Product2 WHERE Id = : SId];
                Integer UsersAvailabilityInDays = 60;
                if(Product.Users_Availability_In_Days__c > 0) UsersAvailabilityInDays = Integer.valueof(Product.Users_Availability_In_Days__c);
                
                List<SystemCode__c> sysCodes = [SELECT Id, Name, Afternoon_Start_Time__c, Evening_Start_Time__c, Time_Slot_Duration__c FROM SystemCode__c WHERE NAME != Null ORDER BY LastModifiedDate LIMIT 1];
                SystemCode__c sysCode = (sysCodes.size() > 0)? sysCodes[0] : new SystemCode__c();
                
                list<Work_Planner__c> WPs = [Select Id, Name, Description__c, Distribution_Timeline__c, Duration_Minutes__c, Event__c, Location__c, Maximum_Threshold__c,
                                             Minimum_Threshold__c, Product__c, Status__c, Weight__c
                                             From Work_Planner__c 
                                             WHERE Location__C=:LId
                                             AND Product__c=:SId
                                             AND Status__c='Approved' Limit 1];
                Date dt = System.today();
                if(WPs.size() > 0 && (WPs[0].Distribution_Timeline__c == 'Daily' || WPs[0].Distribution_Timeline__c == 'Weekly' || WPs[0].Distribution_Timeline__c == 'Monthly' || WPs[0].Distribution_Timeline__c == 'Yearly') && WPs[0].Maximum_Threshold__c != Null){if(WPs[0].Distribution_Timeline__c == 'Daily'){dt = System.today();} else if(WPs[0].Distribution_Timeline__c == 'Weekly'){ dt = dt.toStartofWeek();} else if(WPs[0].Distribution_Timeline__c == 'Monthly'){ dt = dt.toStartofMonth();} else if(WPs[0].Distribution_Timeline__c == 'Yearly'){dt = Date.newInstance(dt.year(), 1, 1); }
                                                                                                                                                                                                                                                                       } String Booked = 'Booked';String Completed = 'Completed'; String NoShow  = 'No Show';  String Reserve = 'Reserve';
                String Waiting = 'Waiting';
                String Invited = 'Invited';
                String query2 = 'select Id, Name, Registration_Time__c, End_Time__c, Override_duplicate_registration__c, Expert_Location__c, Product2__c, Appointment_DateDt__c, Resource__c, Resource__r.User__c from Registration__c where Resource__r.User__c  = : EID And Registration_Time__c != Null And Resource__r.User__c != Null And Appointment_DateDt__c >= : dt And (Status__c = :Booked Or Status__c = :Completed Or Status__c = :NoShow Or Status__c = :Reserve Or Status__c = :Waiting Or Status__c = :Invited) ';  
                query2 += ' ORDER BY Registration_Time__c';
                List<Registration__c> RegList = Database.query(query2);
                System.debug('*** RegList : '+RegList.size());
                
                list < Time_Off__c > TimeOffList = [SELECT Id, Name, Resource__c, Start_Date__c, End_Date__c, Type__c, Start_Time__c, End_Time__c, User__c
                                                    FROM Time_Off__c WHERE    
                                                    User__c  = : EID                     
                                                    And End_Date__c >= : System.today()  
                                                    AND Type__c != null
                                                    AND((Start_Time__c = null AND End_Time__c = null) OR(Start_Time__c != null AND End_Time__c != null))
                                                    AND Start_Date__c != null AND End_Date__c != null Order By Start_Date__c
                                                   ];
                
                Map < Id, list < Registration__c >> BookedRegMap = new Map < Id, list < Registration__c >> ();
                Map < Id, list < Time_Off__c >> TimeOffMap = new Map < Id, list < Time_Off__c >> ();
                
                BookedRegMap.put(EID, new list < Registration__c >());
                TimeOffMap.put(EID, new list < Time_Off__c >());
                
                for (Registration__c BR: RegList) {if (BookedRegMap.containsKey(BR.Resource__r.User__c)) BookedRegMap.get(BR.Resource__r.User__c).add(BR); else BookedRegMap.put(BR.Resource__r.User__c, new List<Registration__c>{BR});
                                                  }
                for (Time_Off__c TO: TimeOffList) { if (TimeOffMap.containsKey(TO.User__c)) TimeOffMap.get(TO.User__c).add(TO);else TimeOffMap.put(TO.User__c, new List<Time_Off__c>{TO});
                                                  }
                system.debug('*** Filtered AvailableResourceList : '+AvailableResourceList.size());
                //es = ClubNewMethod1(AvailableResourceList, AvailableResourceListFR,  MyTimezone, selectedDate, '', LId, SId, null, Product, sysCode, HolidayList, BookedRegMap, TimeOffMap, WPs);
                System.debug('getTimeSlots es.TimeSlotList==>'+es.TimeSlotList.size()+' ,es.TimeSlotList==>'+es.TimeSlotList);
            } catch (Exception ex) { System.debug('TSDI ex=>' + ex + ' @' + ex.getLineNumber() + ' ' + ex.getStackTraceString());
                                   }
            
        }/*else{
es = ClubNewMethod(TimeZoneName, selDate, '',  LId,  SId,null, null); 
}*/
        
        return es;
    }
    
    @AuraEnabled
    Public static Queue_Sch ClubNewMethod1(List <Resource__c> AvailableResourceList, List <Resource__c> AvailableResources, String MyTimezone, Date SelectedDate, String MyAct, String LId, String SId, String MemberId, Product2 Product, SystemCode__c sysCode, List < Holiday__c > HolidayList, Map<Id, List < Registration__c >> myBookedRegs, Map<Id, list < Time_Off__c >> myTOs, list < Work_Planner__c > WPs) {
        Queue_Sch es = new Queue_Sch();
        es.selectedDate = SelectedDate;
        Map<Id, DateTime> UserFirstAvailableSlot = new Map<Id, DateTime>();
        for(Integer R = 0; R < AvailableResourceList.size(); R++) AvailableResourceList[R].Start_Date__c = AvailableResources[R].Start_Date__c;
        Map<Id, Resource__c> ResourceMap = new Map<Id, Resource__c>(AvailableResources);
        List < TimeSlot > AllTimeSlotList = new List < TimeSlot > ();
        List < TimeSlot > myAllTimeSlotList = new List < TimeSlot > ();
        Set<DateTime> Slots = new Set<DateTime>();
        Map<DateTime, Integer> slotCount = new Map<DateTime, Integer>();
        Integer slotDuration = 30;
        if (Product.Duration__c != null && Product.Duration__c > 0) slotDuration = Integer.valueof(Product.Duration__c);
        else if (sysCode != null && sysCode.Time_Slot_Duration__c != null && sysCode.Time_Slot_Duration__c > 0) slotDuration = Integer.valueof(sysCode.Time_Slot_Duration__c);
        
        try {
            for (Resource__c Resource: AvailableResourceList) {Resource.Start_Date__c = ResourceMap.get(Resource.Id).Start_Date__c; es = getUserTimeSlots(Resource, SelectedDate, LId, SId, Product, sysCode, myBookedRegs.get(Resource.User__c), myTOs.get(Resource.User__c), HolidayList, '', WPs);
                                                               System.debug('ClubNewMethod1 es.TimeSlotList==>'+es.TimeSlotList.size()+'  ,SelectedDate=>'+SelectedDate+'  ,es.TimeSlotList==>'+es.TimeSlotList);
                                                               if(es.TimeSlotList.size() > 0){for(TimeSlot TS : es.TimeSlotList){ if(!Slots.contains(TS.Slot) && TS.SlotET!=null) AllTimeSlotList.add(TS);Slots.add(TS.Slot);
                                                                                                                                }
                                                                                             }
                                                              }
            if(AllTimeSlotList.size()>0) es.TimeSlotList=AllTimeSlotList;System.debug('ClubNewMethod1 es.TimeSlotList==>'+es.TimeSlotList.size()+'  ,AllTimeSlotList==>'+AllTimeSlotList.size()+'  ,es.TimeSlotList==>'+es.TimeSlotList);
            /*
es.TimeSlotList=AllTimeSlotList;
Set<TimeSlot> TSFinal=new Set<TimeSlot>();
for (Integer i = 0; i < es.TimeSlotList.size(); i++) {  if(i==0) TSFinal.add(es.TimeSlotList[i]);                              
for (TimeSlot regOld: TSFinal) {                                   
if((es.TimeSlotList[i].Slot >= regOld.Slot  && es.TimeSlotList[i].Slot <regOld.SlotET) ||
(es.TimeSlotList[i].Slot <= regOld.Slot  && es.TimeSlotList[i].Slot.addMinutes(slotDuration)>regOld.Slot)){
es.TimeSlotList[i].IsAvailable = false;
//Break;
}else if(!TSFinal.contains(es.TimeSlotList[i])){

TSFinal.add(es.TimeSlotList[i]); 

} 
}   
}            
System.debug('ClubNewMethod1 TSFinal==>'+TSFinal.size()+'  ,TSFinal==>'+TSFinal); 
if(TSFinal.size()>0) es.TimeSlotList=new List<TimeSlot>(TSFinal); 
*/
            
        } catch (Exception ex) {
            System.debug('TSDI ex=>' + ex + ' @' + ex.getLineNumber() + ' ' + ex.getStackTraceString());
        }
        return es;
    }
    
    @AuraEnabled
    Public static  List<Resource__c> getResourcesByTimeZoneSingleUser(String EId, String LocationId, String ServiceId, String TimeZoneName,String MemberId, Date sDate){ 
        System.debug('getResourcesByTimeZoneSingleUser LId=>'+LocationId+'  ,sId==>'+ServiceId+'  ,EId==>'+EId+'  ,TimeZoneName==>'+TimeZoneName);  
        List<Resource__c> RList = new List<Resource__c>();
        List < Resource__c > AvailableResourceList = new List < Resource__c > ();
        list<Work_Planner__c> WPs = [Select Id, Name, Description__c, Distribution_Timeline__c, Duration_Minutes__c, Event__c, Location__c, Maximum_Threshold__c,
                                     Minimum_Threshold__c, Product__c, Status__c, Weight__c
                                     From Work_Planner__c 
                                     WHERE Location__C=:LocationId
                                     AND Product__c=:ServiceId
                                     AND Status__c='Approved' Limit 1];
        
        System.debug('getResourcesByTimeZoneSingleUser WPs=>'+WPs.size());
        if(WPs.size() > 0){
            list < Resource_Requirement__c > RRListByResourceGroup = new list < Resource_Requirement__c > ();
            RRListByResourceGroup = [SELECT Id, Name, Work_Planner__c, Preferred_Resource__c, Location__c, Resource_Group__c,
                                     Work_Planner__r.Distribution_Timeline__c, Work_Planner__r.Minimum_Threshold__c, Work_Planner__r.Maximum_Threshold__c
                                     FROM Resource_Requirement__c
                                     WHERE Work_Planner__c =: WPs[0].Id
                                     AND Resource_Group__c != null
                                     //AND Preferred_Resource__c=null
                                    ];
            set < String > RGIds = new set < String > ();
            for (Resource_Requirement__c rr: RRListByResourceGroup) {
                RGIds.add(rr.Resource_Group__c);
            }
            System.debug('getResourcesByTimeZoneSingleUser RGIds=>'+RGIds);
            Date TodayDate = System.Today();
            String allFields = 'Resource_Group__c, Time_Slot_Duration__c, Start_Date__c, End_Date__c, Mon_Start_Time__c, Mon_End_Time__c, Tue_Start_Time__c, Tue_End_Time__c, Wed_Start_Time__c, Wed_End_Time__c, Thu_Start_Time__c, Thu_End_Time__c, Fri_Start_Time__c, Fri_End_Time__c, Sat_Start_Time__c, Sat_End_Time__c, Sun_Start_Time__c, Sun_End_Time__c, Break_Start_Time__c, Break_End_Time__c, Mon_Break_Start_Time__c, Mon_Break_End_Time__c, Tue_Break_Start_Time__c, Tue_Break_End_Time__c, Wed_Break_Start_Time__c, Wed_Break_End_Time__c, Thu_Break_Start_Time__c, Thu_Break_End_Time__c, Fri_Break_Start_Time__c, Fri_Break_End_Time__c, Sat_Break_Start_Time__c, Sun_Break_Start_Time__c, Sun_Break_End_Time__c, Description__c, User__c';
            
            String query1 = '';
            if(String.isNotEmpty(EId)) query1 = 'select User__r.Name, User__r.fullphotourl,' + allFields + ' from Resource__c where Resource_Group__c IN:RGIds AND End_Date__c>=:TodayDate AND User__c =: EId AND User__r.TimeZoneSidKey=:TimeZoneName AND User__r.IsActive=true ORDER By Start_Date__c ASC '; // Priority__c,  
            //else query1 = 'select User__r.Name, User__r.fullphotourl,' + allFields + ' from Resource__c where Resource_Group__c IN:RGIds AND User__c != null AND End_Date__c>=:TodayDate AND User__r.TimeZoneSidKey=:TimeZoneName AND User__r.IsActive=true ORDER By Start_Date__c ASC '; // Priority__c,              
            RList = Database.query(query1);
            System.debug('*** RList => ' + RList.size());
            
            
            Set < Id > UIds = new Set < Id > ();
            for (Resource__c R: RList) { UIds.add(R.User__c); }
            System.debug('*** WPs[0] : ' + WPs[0]);
            if (RList.size() > 0) { Date dt = System.today();
                                   if (WPs.size() > 0 && (WPs[0].Distribution_Timeline__c == 'Daily' || WPs[0].Distribution_Timeline__c == 'Weekly' || WPs[0].Distribution_Timeline__c == 'Monthly' || WPs[0].Distribution_Timeline__c == 'Yearly') && WPs[0].Maximum_Threshold__c != Null) {
                                       if (WPs[0].Distribution_Timeline__c == 'Daily') { dt = System.today();} else if (WPs[0].Distribution_Timeline__c == 'Weekly') { dt = dt.toStartofWeek(); } else if (WPs[0].Distribution_Timeline__c == 'Monthly') {dt = dt.toStartofMonth();} else if (WPs[0].Distribution_Timeline__c == 'Yearly') {dt = Date.newInstance(dt.year(), 1, 1);
                                                                                                                                                                                                                                                                                                                                           }
                                   }
                                   String Booked = 'Booked';String Completed = 'Completed';String NoShow = 'No Show';String Reserve = 'Reserve';String Waiting = 'Waiting'; String Invited = 'Invited';String query2 = 'select Id, Name, Registration_Time__c, End_Time__c, Override_duplicate_registration__c, Expert_Location__c, Product2__c, Appointment_DateDt__c, Resource__c, Resource__r.User__c from Registration__c where Resource__r.User__c In : UIds And Registration_Time__c != Null And Resource__r.User__c != Null And Appointment_DateDt__c >= : dt And (Status__c = :Booked Or Status__c = :Completed Or Status__c = :NoShow Or Status__c = :Reserve Or Status__c = :Waiting Or Status__c = :Invited)  ';
                                   query2 += ' ORDER BY Registration_Time__c';List < Registration__c > Registrations = Database.query(query2);
                                   System.debug('*** Registrations : ' + Registrations.size());
                                   
                                   Product2 Product = [SELECT Id, Name, Membership_Program__c, Duration__c, Allow_Not_Available_Slot__c, Allow_Not_Available_Day__c FROM Product2 WHERE Id =: ServiceId]; Product2 Prod = Product;
                                   
                                   Map < Id, Integer > userRegnCount = new Map < Id, Integer > ();Map < Id, List<Resource__c> > userResources = new Map < Id, List<Resource__c> > ();
                                   for (Resource__c R: RList) {if (userResources.containsKey(R.User__c)) userResources.get(R.User__c).add(R);else userResources.put(R.User__c, new List<Resource__c>{R});
                                                               if (sDate >= R.Start_Date__c && sDate <= R.End_Date__c) userRegnCount.put(R.User__c, 0);else if (!userRegnCount.containsKey(R.User__c)) userRegnCount.put(R.User__c, -1);
                                                              }
                                   System.debug('*** userRegnCount before : ' + userRegnCount);
                                   for (Registration__c R: Registrations) {boolean count = false;
                                                                           if(R.Expert_Location__c == WPs[0].Location__c && R.Product2__c == WPs[0].Product__c) {
                                                                               if (WPs[0].Distribution_Timeline__c == 'Daily' && R.Appointment_DateDt__c == sDate) {count = true;
                                                                                                                                                                   } else if (WPs[0].Distribution_Timeline__c == 'Weekly' && R.Appointment_DateDt__c >= sDate.toStartofWeek() && R.Appointment_DateDt__c <= sDate.toStartofWeek() + 6) { count = true;
                                                                                                                                                                                                                                                                                                                                       } else if (WPs[0].Distribution_Timeline__c == 'Monthly' && R.Appointment_DateDt__c >= sDate.toStartofMonth() && R.Appointment_DateDt__c <= sDate.addMonths(1).toStartofMonth().addDays(-1)) {count = true;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   } else if (WPs[0].Distribution_Timeline__c == 'Yearly' && R.Appointment_DateDt__c.year() == sDate.year()) { count = true;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             } if (count && R.Resource__r.User__c != null && userRegnCount.containsKey(R.Resource__r.User__c)) userRegnCount.put(R.Resource__r.User__c, userRegnCount.get(R.Resource__r.User__c) + 1);
                                                                           }
                                                                          }
                                   System.debug('*** userRegnCount after : ' + userRegnCount);
                                   List < Resource__c > RListNew = new List < Resource__c > ();List<Id> newUIds = new List<Id>(); newUIds.addAll(UIds);
                                   if (WPs[0].Minimum_Threshold__c != Null) {for (Integer i = 0; i < newUIds.size(); i++) { for (integer j = i + 1; j <= newUIds.size() - 1; j++) {if (userRegnCount.get(newUIds[i]) > userRegnCount.get(newUIds[j])) {Id nId = newUIds[i];newUIds[i] = newUIds[j];newUIds[j] = nId;
                                                                                                                                                                                                                                                      }
                                                                                                                                                                                  }
                                                                                                                          }
                                                                            }
                                   for(Id UId : newUIds){RListNew.addAll(userResources.get(UId)); }RList = RListNew;//OSRUtil.Resources = RList;
                                  }
        }
        return RList;       
    } 
    
    Public class TimeSlot{
        @AuraEnabled Public DateTime Slot            {set;get;}       
        @AuraEnabled Public Boolean IsAvailable      {set;get;}
        @AuraEnabled Public String ResourceId        {set;get;}
        @AuraEnabled Public String ResourceName      {set;get;}
        @AuraEnabled Public String UserId            {set;get;}
        @AuraEnabled Public String UserName          {set;get;}
        @AuraEnabled Public Boolean checked          {set;get;}  @AuraEnabled Public Integer slotCount        {get;set;}
        @AuraEnabled Public String SlotStr           {get;set;}
        @AuraEnabled Public DateTime SlotET          {set;get;}
        
        Public TimeSlot(){
            slot=SlotET=null; ResourceId=null; isAvailable=checked=false; ResourceName=''; UserId=''; UserName=''; SlotStr='';
        }  
    } 
    
    Public DateTime StartTime                      {set;get;}
    Public DateTime EndTime                        {set;get;}
    Public DateTime DBST                           {set;get;}
    Public DateTime DBET                           {set;get;} 
    
    
    @AuraEnabled //Queue
    Public static Queue_Sch getUserTimeSlots(Resource__c Resource, DateTime selDate, String LId, String sId, Product2 Product, SystemCode__c sysCode, list<Registration__c> BookedRegList, list<Time_Off__c> CurrentDateTimeOffList, List<Holiday__c> HolidayList, String Action, List<Work_Planner__c> WPs) { //, String Action, String TimeZoneName, String MemberId
        Queue_Sch es = new Queue_Sch();
        Date DateVal=Date.valueOf(selDate); 
        Date selectedDate=DateVal;          
        es.selectedDate=selectedDate;
        try {           
            es.selectedDate = selectedDate;
            if(WPs != Null && WPs.size() > 0 && (WPs[0].Distribution_Timeline__c == 'Daily' || WPs[0].Distribution_Timeline__c == 'Weekly' || WPs[0].Distribution_Timeline__c == 'Monthly' || WPs[0].Distribution_Timeline__c == 'Yearly') && WPs[0].Maximum_Threshold__c != Null){
                Integer count = 0;
                for(Registration__c R : BookedRegList){
                    if(R.Expert_Location__c == WPs[0].Location__c && R.Product2__c == WPs[0].Product__c) {
                        if(WPs[0].Distribution_Timeline__c == 'Daily' && R.Appointment_DateDt__c == es.selectedDate){count++;
                                                                                                                    } else if(WPs[0].Distribution_Timeline__c == 'Weekly' && R.Appointment_DateDt__c >= es.selectedDate.toStartofWeek() && R.Appointment_DateDt__c <= es.selectedDate.toStartofWeek()+6){count++;
                                                                                                                                                                                                                                                                                                        } else if(WPs[0].Distribution_Timeline__c == 'Monthly' && R.Appointment_DateDt__c >= es.selectedDate.toStartofMonth() && R.Appointment_DateDt__c <= es.selectedDate.addMonths(1).toStartofMonth().addDays(-1)){count++;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      } else if(WPs[0].Distribution_Timeline__c == 'Yearly' && R.Appointment_DateDt__c.year() == es.selectedDate.year()){ count++;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        }
                    }
                }
                if(count >= WPs[0].Maximum_Threshold__c) return es;
            }
            List<Registration__c> BookedRegListTemp = new List<Registration__c>();
            if(BookedRegList!=null)
                for(Registration__c R : BookedRegList){ if(R.Resource__r.User__c == Resource.User__c && R.Appointment_DateDt__c >= system.today() && R.Appointment_DateDt__c == selDate) BookedRegListTemp.add(R); 
                                                      }
            BookedRegList = BookedRegListTemp;
            
            Integer slotDuration = 30;
            Set < Date > Holidays = new Set < Date > ();
            for (Holiday__c hd: HolidayList) Holidays.add(hd.Date__c);
            if (Product.Duration__c != null && Product.Duration__c > 0) slotDuration = Integer.valueof(Product.Duration__c);
            else if (sysCode != null && sysCode.Time_Slot_Duration__c != null && sysCode.Time_Slot_Duration__c > 0) slotDuration = Integer.valueof(sysCode.Time_Slot_Duration__c);
            
            DateTime startTime, endTime, DBST, DBET;
            Queue_Sch TSD = new Queue_Sch();
            Date sDate = Date.valueOf(selDate);
            
            Boolean isHolyday = false;
            set < DateTime > ExpertBlockedTime = new set < DateTime > (); 
            list<Time_Off__c> TimeOffList=new list<Time_Off__c>();
            Boolean isTimeOff=false;
            for (Registration__c Reg: BookedRegList) {    ExpertBlockedTime.add(Reg.Registration_Time__c);
                                                     }
            set < DateTime > AvailableSlots = new set < DateTime > ();
            
            DateTime BST, BET;
            if (Resource.Break_Start_Time__c != Null && Resource.Break_End_Time__c != Null) {
                BST = DateTime.newInstance(selectedDate, Resource.Break_Start_Time__c);
                BET = DateTime.newInstance(selectedDate, Resource.Break_End_Time__c);
            }
            Resource__c Riz = Resource.clone(true, true, false, false);   
            TSD = getAvailableDate(selectedDate, Riz);
            isHolyday = false;
            if (Holidays.contains(selectedDate) && Resource.Override_Holidays__c == false) isHolyday = true;
            isTimeOff = false;
            for (Time_Off__c to: TimeOffList) { if (to.Start_Date__c <= selectedDate && to.End_Date__c >= selectedDate) { isTimeOff = true; 
                                                                                                                        }
                                              }
            if (TSD.startTime != null && TSD.endTime != null && TSD.startTime < TSD.endTime && TSD.endTime > System.now() && !isHolyday && !isTimeOff) {
                startTime = TSD.startTime;
                endTime = TSD.endTime;
                DBST = TSD.DBST;
                DBET = TSD.DBET;
            }
            Integer TotalMinutes;
            if (startTime != null && endTime != null) {
                TotalMinutes = (endTime.hour() - startTime.hour()) * 60 + (endTime.Minute() - startTime.Minute());
            }
            if (TotalMinutes != null) TotalMinutes = (TotalMinutes / slotDuration);
            //es.SelectedExpertDuration = slotDuration; //
            TimeSlot TS = new TimeSlot();
            Boolean CB, DB;
            CB = DB = true;
            if (BST != null && BET != null) CB = (startTime <= BST || startTime > BET);
            if (DBST != null && DBET != null) DB = (startTime <= DBST || startTime > DBET);
            if (!ExpertBlockedTime.contains(startTime) && startTime >= System.now() && CB && DB) {TS.Slot = startTime;TS.IsAvailable = true;TS.ResourceId = Resource.Id;
                                                                                                  es.TimeSlotList.add(TS); } else if (Product.Allow_Not_Available_Slot__c) {  TS.Slot = startTime;  TS.IsAvailable = false; TS.ResourceId = Resource.Id; es.TimeSlotList.add(TS);
                                                                                                                                                                           }
            Integer slotsMinutes = 0;
            if (endTime != null) slotsMinutes = endTime.minute() / slotDuration;
            Integer count = 0; System.debug('TotalMinutes=>' + TotalMinutes + ' startTime=>' +startTime+'  ,Resource=>'+Resource);
            if (TotalMinutes > 1)
                for (Integer i = 0; i < TotalMinutes; i++) {
                    TS = new TimeSlot();
                    startTime = startTime.addminutes(slotDuration);
                    DateTime myet = startTime.addminutes(slotDuration);
                    if (startTime.hour() <= endTime.hour()) {
                        CB = DB = true;
                        if (BST != null && BET != null) CB = (myet <= BST || myet > BET);
                        if (DBST != null && DBET != null) DB = (myet <= DBST || myet > DBET);
                        if (startTime.hour() < endTime.hour()) {
                            if (!ExpertBlockedTime.contains(startTime) && startTime >= System.now() && CB && DB) { TS.Slot = startTime; TS.SlotET = myet;TS.IsAvailable = true;TS.ResourceId = Resource.Id;
                                                                                                                 } 
                        } else {
                            if (endTime.minute() >= slotDuration) {
                                if (!ExpertBlockedTime.contains(startTime) && startTime >= System.now() && CB && DB) { TS.Slot = startTime; TS.SlotET = myet; TS.IsAvailable = true;TS.ResourceId = Resource.Id;
                                                                                                                     }
                                count = count + 1;
                                if (count > slotsMinutes) break;
                            }
                        }
                    }
                    if(TS.Slot != Null && TS.Slot >= system.now()){ es.TimeSlotList.add(TS); es.selectedDate = date.newinstance(TS.Slot.year(), TS.Slot.month(), TS.Slot.day());
                                                                  }
                }
            System.debug('es.TimeSlotList=>' + es.TimeSlotList.size() + ' es.TimeSlotList=>' +es.TimeSlotList);     
            
            /*FOR TIME OFF*/
            try {
                if(CurrentDateTimeOffList!=null)
                    if (CurrentDateTimeOffList.size() > 0) {
                        for (Integer i = 0; i < es.TimeSlotList.size(); i++) {
                            for (Integer j = 0; j < CurrentDateTimeOffList.size(); j++) {
                                if(CurrentDateTimeOffList[j].Start_Time__c == Null) CurrentDateTimeOffList[j].Start_Time__c = Time.newInstance(0,0,0,0); //'12:00 AM'; 
                                if(CurrentDateTimeOffList[j].End_Time__c == Null) CurrentDateTimeOffList[j].End_Time__c = Time.newInstance(23,45,0,0); //'11:45 PM';
                                if (selectedDate >= CurrentDateTimeOffList[j].Start_Date__c && selectedDate <= CurrentDateTimeOffList[j].End_Date__c && es.TimeSlotList[i].Slot >= DateTime.newInstance(selectedDate, CurrentDateTimeOffList[j].Start_Time__c) && es.TimeSlotList[i].Slot < DateTime.newInstance(selectedDate, CurrentDateTimeOffList[j].End_Time__c)) es.TimeSlotList[i].IsAvailable = false;
                                else if (es.TimeSlotList[i].Slot == DateTime.newInstance(selectedDate, CurrentDateTimeOffList[j].End_Time__c)) es.TimeSlotList[i].IsAvailable = true;
                                
                            }
                        }
                    }
            } catch (Exception ex) { System.debug('ex=>' + ex + ' @' + ex.getLineNumber()); }
            
            
            /*FOR REGISTRATION TIME RANGE*/
            try {
                if (BookedRegList.size() > 0) {Boolean isFound=false;
                                               for (Integer i = 0; i < es.TimeSlotList.size(); i++) {                               
                                                   for (Registration__c regOld: BookedRegList) {                                   
                                                       if((es.TimeSlotList[i].Slot >= regOld.Registration_Time__c  && es.TimeSlotList[i].Slot <regOld.End_Time__c) ||
                                                          (es.TimeSlotList[i].Slot <= regOld.Registration_Time__c  && es.TimeSlotList[i].Slot.addMinutes(slotDuration)>regOld.Registration_Time__c)){es.TimeSlotList[i].IsAvailable = false;Break;
                                                                                                                                                                                                    } 
                                                   }   
                                               }
                                              }
            }catch (Exception ex) { System.debug('REGISTRATION ex=>' + ex.getMessage() + ' @' + ex.getLineNumber()); }
            
            
            
            List < TimeSlot > AllTimeSlotListNew = new List < TimeSlot > ();
            if (Product.Allow_Not_Available_Slot__c == false) {
                for (TimeSlot slot: es.TimeSlotList) { if (slot.IsAvailable) AllTimeSlotListNew.add(slot);
                                                     }
                es.TimeSlotList = AllTimeSlotListNew;
            }
            if(es.TimeSlotList.size() > 0) System.debug('*** TimeSlotList size : ' + es.TimeSlotList.size() + '  ,es.SelectedDate=>' + es.TimeSlotList);
            
        } catch (Exception ex) { es.TimeSlotList = new List < TimeSlot > (); System.debug('ex=>' + ex + ' @' + ex.getLineNumber()); return es;
                               }
        
        return es;
    }
    
    public Static String getDayNameOfDate(Date DateVal){
        List<String> listDay = new List<String>{'Saturday' , 'Sunday' , 'Monday' , 'Tuesday' , 'Wednesday' , 'Thursday' , 'Friday'};
            Integer remainder = Math.mod(date.newInstance(0001, 1, 1).daysBetween(DateVal) , 7);
        return listDay.get(remainder).subString(0,3); 
    }
    
    Public Static Queue_Sch getAvailableDate(DateTime startTime, Resource__c Resource){
        //System.debug('***getAvailableDate StartTime=>'+startTime+'  ,Resource=>'+Resource);
        Queue_Sch TS=new Queue_Sch();
        DateTime EndTime, DBST, DBET;
        Date RST = Resource.Start_date__c;
        Resource.Start_date__c=Date.valueOf(startTime);
        // System.debug('***getAvailableDate StartTime=>'+Resource.Start_date__c);
        String DayName=getDayNameOfDate(Resource.Start_date__c);
        //System.debug('***getAvailableDate DayName=>'+DayName+'  ,Resource.Start_date__c=>'+Resource.Start_date__c);
        
        if(DayName=='Mon' && Resource.Mon_Start_Time__c != null && Resource.Mon_End_Time__c != null){ //startTime.format('E')=='Mon'
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Mon_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Mon_End_Time__c);
            if(Resource.Mon_Break_Start_Time__c != null && Resource.Mon_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Mon_Break_Start_Time__c);
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Mon_Break_End_Time__c); 
            }
            
        }
        else if(DayName=='Tue' && Resource.Tue_Start_Time__c != null && Resource.Tue_End_Time__c != null){
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Tue_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Tue_End_Time__c);
            if(Resource.Tue_Break_Start_Time__c != null && Resource.Tue_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Tue_Break_Start_Time__c);
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Tue_Break_End_Time__c); 
            }  
        }
        else if(DayName=='Wed' && Resource.Wed_Start_Time__c != null && Resource.Wed_End_Time__c != null){ 
            
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Wed_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Wed_End_Time__c);
            System.debug('getSlots wed EndTime=>'+EndTime);
            
            if(Resource.Wed_Break_Start_Time__c != null && Resource.Wed_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Wed_Break_Start_Time__c);
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Wed_Break_End_Time__c); 
            }  
        }
        else if(DayName=='Thu' && Resource.Thu_Start_Time__c != null && Resource.Thu_End_Time__c != null){
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Thu_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Thu_End_Time__c);
            if(Resource.Thu_Break_Start_Time__c != null && Resource.Thu_Break_End_Time__c != null){  DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Thu_Break_Start_Time__c); DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Thu_Break_End_Time__c); 
                                                                                                  } 
        }
        else if(DayName=='Fri' && Resource.Fri_Start_Time__c != null && Resource.Fri_End_Time__c != null){
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Fri_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Fri_End_Time__c);
            if(Resource.Fri_Break_Start_Time__c != null && Resource.Fri_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Fri_Break_Start_Time__c);
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Fri_Break_End_Time__c); 
            } 
        }
        else if(DayName=='Sat' && Resource.Sat_Start_Time__c != null && Resource.Sat_End_Time__c != null){ 
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Sat_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Sat_End_Time__c);
            if(Resource.Sat_Break_Start_Time__c != null && Resource.Sat_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Sat_Break_Start_Time__c); 
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Sat_Break_End_Time__c); 
            }    
        }
        else if(DayName=='Sun' && Resource.Sun_Start_Time__c != null && Resource.Sun_End_Time__c != null){
            StartTime = DateTime.newInstance(Resource.Start_Date__c,Resource.Sun_Start_Time__c);
            EndTime=DateTime.newInstance(Resource.Start_Date__c,Resource.Sun_End_Time__c);
            if(Resource.Sun_Break_Start_Time__c != null && Resource.Sun_Break_End_Time__c != null){
                DBST = DateTime.newInstance(Resource.Start_Date__c,Resource.Sun_Break_Start_Time__c);
                DBET=DateTime.newInstance(Resource.Start_Date__c,Resource.Sun_Break_End_Time__c); 
            } 
        }
        TS.StartTime=StartTime;
        TS.EndTime=EndTime;
        TS.DBST=DBST;
        TS.DBET=DBET;
        Resource.Start_date__c = RST;
        return TS;
    }   
    
}