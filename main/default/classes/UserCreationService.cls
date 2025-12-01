global with sharing class UserCreationService {
    @future
    global static void createNewUser(String firstName,String lastName,String email, String profileDevName, Boolean newLetterSub, String guestUserId) {
       // System.runAs(new User(Id = guestUserId)) {
        try {
            String subject = '';
        	String emailBody = '';
            String UserId;
            String currentUserId;
            List < Profile > profList = [SELECT Id FROM Profile WHERE Name ='System Administrator'];
            system.debug('Profile  ~'+profList);
            if( profList.size() >0 ){
                List<User> userForRole =[Select id from User where profileId =:profList[0].Id AND isActive=true AND UserRoleId != Null ];
                if( userForRole.size() >0 )UserId = userForRole[0].Id;
                system.debug('UserId~'+ UserId);
            }
           User registeredUser=new User();
            List<Account> Accounts = [Select Id, Name, Email__c, Phone, Is_Portal_Account__c From Account Where Email__c =: email Limit 1];
            system.debug('Accounts~' + Accounts);
            Contact newCreatedContact = new Contact();
            Account newCreatedAccount= new Account();
            if(Accounts.size() > 0){
                newCreatedAccount = Accounts[0]; newCreatedAccount.Is_Portal_Account__c = true; newCreatedAccount.Account_Type__c='Customer';
                if( UserId != Null ){ newCreatedAccount.OwnerId =UserId; if(Schema.sObjectType.Account.fields.OwnerId.isCreateable() && Schema.sObjectType.Account.fields.Account_Type__c.isCreateable() && Schema.sObjectType.Account.fields.Is_Portal_Account__c.isCreateable()) {
                    //  upsert newCreatedAccount;

                    List<SObject> safenewCreatedAccount = FLSHelper.getSafeRecords(
    new List<Account>{newCreatedAccount},
    'Account',
    AccessType.CREATABLE
);
List<Account> typednewCreatedAccount = new List<Account>();
for (SObject s : safenewCreatedAccount) {
    typednewCreatedAccount.add((Account)s);
}
if (!typednewCreatedAccount.isEmpty()) {
    upsert typednewCreatedAccount; // or insert/update as needed
}


                   // List<SObject> safenewCreatedAccount = FLSHelper.getSafeRecords(new List<Account>{newCreatedAccount}, 'Account', AccessType.UPDATABLE);
                    // Now cast back to your object
                   /* List<Account> TypednewCreatedAccount = new List<Account>();
                    for (SObject SObj : safenewCreatedAccount) {
                        TypednewCreatedAccount.add((Account)SObj);
                    }
                    if(!TypednewCreatedAccount.isEmpty()){
                        upsert TypednewCreatedAccount;
                    }*/
                }else{}}
                List<Contact> Contacts = [Select Id, FirstName, LastName, Email, AccountId, Phone From Contact Where Email =: email And AccountId =: Accounts[0].Id Limit 1];
                if(Contacts.size() > 0){
                    newCreatedContact = Contacts[0]; newCreatedContact.firstName = firstName; newCreatedContact.lastName = lastName; newCreatedContact.Primary__c=true; newCreatedContact.Subscribe_To_NewsLetters__c=newLetterSub;
                    if(Schema.sObjectType.Contact.fields.firstName.isUpdateable() && Schema.sObjectType.Contact.fields.lastName.isUpdateable() && Schema.sObjectType.Contact.fields.Primary__c.isUpdateable() && Schema.sObjectType.Contact.fields.Subscribe_To_NewsLetters__c.isUpdateable())update newCreatedContact; else{}
                }
                else {
                    newCreatedContact.firstName = firstName; newCreatedContact.lastName = lastName; newCreatedContact.email = email; newCreatedContact.AccountId = newCreatedAccount.Id; newCreatedContact.Primary__c=true; newCreatedContact.Subscribe_To_NewsLetters__c=newLetterSub;
                    if(Schema.sObjectType.Contact.fields.firstName.isCreateable() && Schema.sObjectType.Contact.fields.lastName.isCreateable() && Schema.sObjectType.Contact.fields.Primary__c.isCreateable() && Schema.sObjectType.Contact.fields.Subscribe_To_NewsLetters__c.isCreateable()) insert newCreatedContact; else{}
                }
            }
            else {
                newCreatedAccount = new Account(Name = firstName + ' ' + lastName, Email__c = email, Is_Portal_Account__c = true,Account_Type__c='Customer');
                if( UserId != Null ) newCreatedAccount.OwnerId =UserId;
                if(Schema.sObjectType.Account.fields.Name.isCreateable() && Schema.sObjectType.Account.fields.Email__c.isCreateable() && Schema.sObjectType.Account.fields.Is_Portal_Account__c.isCreateable() && Schema.sObjectType.Account.fields.Account_Type__c.isCreateable()) insert newCreatedAccount; //else{}
                newCreatedContact.firstName = firstName;
                newCreatedContact.lastName = lastName;
                newCreatedContact.email = email;
                newCreatedContact.AccountId = newCreatedAccount.Id;
                newCreatedContact.Primary__c=true;
                if( UserId != Null ) newCreatedContact.OwnerId=UserId;
                if(Schema.sObjectType.Contact.fields.email.isCreateable() && Schema.sObjectType.Contact.fields.firstName.isCreateable() && Schema.sObjectType.Contact.fields.lastName.isCreateable() && Schema.sObjectType.Contact.fields.Primary__c.isCreateable()) insert newCreatedContact; else{}
            }
            system.debug('newCreatedAccount~' +newCreatedAccount);
            system.debug('newCreatedContact~' +newCreatedContact);
            registeredUser.Username = email;
            registeredUser.FirstName = firstName;
            registeredUser.LastName = lastName;
            registeredUser.Email = email;
            String custProfId=getProfileId();
            if(custProfId!=null && custProfId!=''){
                registeredUser.ProfileId=custProfId;
            }
            registeredUser.ProfileId = getProfileId(); //
            String tempNickName = ((firstName != null && firstName.length() > 0) ? firstName.substring(0, 1) : '') + lastName.substring(0, 1);
            tempNickName += String.valueOf(Crypto.getRandomInteger()).substring(1, 7);
            registeredUser.Alias = tempNickName;
            registeredUser.CommunityNickname = tempNickName;
            registeredUser.EmailEncodingKey = 'ISO-8859-1';
            registeredUser.IsActive = true;
            String accountId = newCreatedContact.AccountId;
            if (accountId != null) {
                system.debug('acc id~>'+accountId);
                system.debug('registeredUser~>'+registeredUser);
                currentUserId=Site.createPortalUser(registeredUser, accountId, null);
               // currentUserId = Site.createPortalUser(registeredUser, accountId, null);
                system.debug('currentUserId~>'+currentUserId);
            }else{
                system.debug('acc id empty');
            }
            system.debug('currentUserId~>'+currentUserId);
            if(String.isNotEmpty(currentUserId)){
                System.debug('User Created Successfully');
            } 
            else {   
                System.debug('User not created');
            }
            subject = 'Welcome to Our Portal!';
            emailBody = 'Hello ' + firstName + ',\n\nYour registration was successful! 🎉\n\nYou can now log in using your email: **' + email + '**' +
                        '\n\nThank you for joining our community.\n\n--\nAxolt';

            sendEmail(email, subject, emailBody);
        } catch (Exception ex) {
            System.debug('Error in future method: ' + ex.getMessage());
            String subject = 'Registration Failed';
            String emailBody = 'Hello ' + firstName + ',\n\nUnfortunately, we encountered an error while registering your account.' +
                        '\n\n**Error Message:** ' + ex.getMessage() +
                        '\n\nPlease try again later or contact support for assistance.\n\n--\nYour Company Team';

            sendEmail(email, subject, emailBody);
        }
        
    }
    private static Id profileId;
    private static Id getProfileId() {
        
            List < Profile > idList = [SELECT Id FROM Profile WHERE Name = 'Customer Community Portal User'];
            if (idList.size() > 0) {
                profileId = idList[0].id;
            }
        
        return profileId;
    }
    private static void sendEmail(String toAddress, String subject, String body) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { toAddress });
        email.setSubject(subject);
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}