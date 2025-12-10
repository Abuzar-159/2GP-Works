public with sharing class RMADocument {

    public Return_Merchandise_Authorisation__c RMA { get; set; }
    public String imageURl                             { get; set; }
     public String cusId{ get; set; }
    public String soname{ get; set; }
    public String RMAFields                             { get; set; }
    public String addressFields                        { get; set; }
    public Organization orgDetails                     { get; set; }
    public String RMANumber                             { get; set; }
    public Contact currentContact                      { get; set; }
    public String  toEmail_id                          { get; set; } public String EmailSubject                         { get; set; } public String TextBody                             { get; set; } public List<selectoption> AvailableRecipients      { get; set; } public List<selectoption> SelectedRecipients       { get; set; } public String selectedEmail                        { get; set; } public Map<string,string> ccEmails_map             { get; set; } public list<String>  ccEmails                      { get; set; }
    public String contactids                           { get; set; } public EmailTemplate SelectEmailTemplate           { get; set; }
    public EmailTemplate MailselectedTemplate          { get; set; } public Boolean MailSent                            { get; set; }
    public String sfdcBaseURL                          { get; set; }
    public Boolean isHtmlEmail                         { get; set; }
    public List<SetEmailTemplates__c> EmailTemplates_uniqueName { get; set; } public String HtmlBody                             { get; set; } public Address__c vendorAddress                     { get; set; } public Address__c invoiceAddress                    { get; set; }             public Address__c deliveryAddress                   { get; set; }
    public String exceptionMsg                          { get; set; } public String ccEmail_Addresses                     { get; set; }

    public RMADocument() {
        try {
          //  sfdcBaseURL = URL.getSalesforceBaseUrl().getHost();
            sfdcBaseURL = System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://','.my.salesforce.com')+'.file.force.com';
            system.debug('sfdcBaseURL before~>'+sfdcBaseURL);
            String initurl = Label.initURL;
            String DestinationURL = Label.DestURL;
            system.debug('initurl~>'+initurl);
            system.debug('DestinationURL~>'+DestinationURL);

            //sfdcBaseURL = sfdcBaseURL.replace(initurl,DestinationURL); //working in dev org
            //sfdcBaseURL = sfdcBaseURL.replace('--erp7','--c');

            // Commented By Aymaan
          //   String sendEmailBaseURL = Label.sendEmailBaseURL;
         	// sfdcBaseURL = sfdcBaseURL.replace(initurl,sendEmailBaseURL);
          //   system.debug('sfdcBaseURL bfr ~>'+sfdcBaseURL);
         	// if(sfdcBaseURL.contains('content')) sfdcBaseURL = sfdcBaseURL.replace('--Axolt','--c');
          //   else sfdcBaseURL = sfdcBaseURL.replace('--Axolt','');

          //    system.debug('sfdcBaseURL after~>'+sfdcBaseURL);

          //   sfdcBaseURL = sendEmailBaseURL;
          // Commented By Aymaan END
             /*sfdcBaseURL = sfdcBaseURL.replace('.visual.force.com','.content.force.com');
            sfdcBaseURL = sfdcBaseURL.replace('--erp7','--c');
    */
           // sfdcBaseURL = sfdcBaseURL.removeEndIgnoreCase('visualforce.com');
           // sfdcBaseURL = sfdcBaseURL.replace('--erp7','--c');
            String CustID;
            if(ApexPages.CurrentPage().getParameters().get('Id')!= null) RMANumber = EncodingUtil.urlEncode(ApexPages.CurrentPage().getParameters().get('Id'),'UTF-8');
            if(System.currentPageReference().getParameters().get('custId')!= null) CustID = EncodingUtil.urlEncode(System.currentPageReference().getParameters().get('custId'),'UTF-8');
			cusId = CustID;
            RMAFields = UtilClass.selectStarFromSObject('Return_Merchandise_Authorisation__c');
            utilClass.FLSCheck(RMAFields.split(','),'Return_Merchandise_Authorisation__c');
            addressFields = UtilClass.selectStarFromSObject('Address__c');
            utilClass.FLSCheck(addressFields.split(','),'Address__c');
            if(RMANumber != null) RMA = getRMA(RMANumber);

            if(CustID == null || CustID == '') ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'No Contact assigned on RMA'));

            //if(!Schema.sObjectType.Organization.isAccessible()) {  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Organization.Label));//This was commented on 12/01/24 by Asra after getting confirmation from Imran and Moin
            //} else { orgDetails = [SELECT Id, Name FROM Organization WHERE Id =: UserInfo.getOrganizationId()]; }

            if(CustID != null && CustID != '') {
                if(!Schema.sObjectType.Contact.isAccessible()) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Contact.Label));
                } else { currentContact = [Select id, Name, FirstName, LastName ,Email, Fax, AccountId, Phone, Contact_Numer__c, Company__c From Contact Where Id =: CustID Limit 1]; }
            }
            if(currentContact != null){ if(String.isNotEmpty(currentContact.Email)) toEmail_id = currentContact.Email; }


            imageURL='/servlet/servlet.FileDownload?file=';
            if(!Schema.sObjectType.Document.isAccessible()) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Document.Label));
            } else { List<Document> documentList = [select id, Name, developerName from document where developerName =: 'Invoice'];
                     if(documentList.size() > 0) imageURL = imageURL + documentList[0].id; } } catch(Exception e) { exceptionMethod(e, 'Constructor'); }

        /*Querying The Template for Preview and attachment*/
         try{
                EmailTemplates_uniqueName = [Select Template_Unique_Name__c,OrgWideEmailAddress__c,Html_Body__c,TemplateAsAttachment__c,Add_Template_As_Attachment__c From SetEmailTemplates__c where Name ='RMA_Document_Axolt' limit 1];
                if(EmailTemplates_uniqueName.isEmpty()) {
                    EmailTemplates_uniqueName = new  List<SetEmailTemplates__c>();
                    EmailTemplates_uniqueName.add(new SetEmailTemplates__c(OrgWideEmailAddress__c = null,Template_Unique_Name__c = 'RMA_Document_Axolt',TemplateAsAttachment__c = true,Add_Template_As_Attachment__c=true,Html_Body__c=false));
                }
               if(EmailTemplates_uniqueName.size() > 0 && EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Template_Unique_Name__c != null){
                    MailselectedTemplate = [select id,Body, Subject,HtmlValue from EmailTemplate where DeveloperName =:EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Template_Unique_Name__c];
                    isHtmlEmail =  EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Html_Body__c; }else{ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.info,'To SetUp  Email Template provide Unique Template Name or Contact your Administrator'));}}catch(Exception e){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+ ' @ Line Number ' +e.getLineNumber()));}
    }

    public void Email_Details(){
        /*To get Email Content Before Sending Email For Preview*/
        try{

            Messaging.SingleEmailMessage email_Attach = new Messaging.SingleEmailMessage();

            String [] toAddresses_test = new String[] {'test@test.com'};

                email_Attach.setToAddresses(toAddresses_test);
            email_Attach.setTemplateId(MailselectedTemplate.id);
            email_Attach.setSaveAsActivity(false);
            if(currentContact != null) email_Attach.setTargetObjectId(currentContact.id);
            email_Attach.setWhatId(RMA.id);
            Savepoint sp = Database.setSavepoint();  if(currentContact != null) if(currentContact.Email != Null) Messaging.SendemailResult [] email_Attach_Result = Messaging.sendemail(new Messaging.SingleEmailMessage[] {email_Attach});  EmailSubject=email_Attach.getSubject();TextBody = email_Attach.getPlainTextBody(); HtmlBody = email_Attach.getHtmlBody();Database.rollback(sp);

        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+ ' @ Line Number ' +e.getLineNumber()));
         }
    }

     /*
      Method For Getting SO Record
    */
    public Return_Merchandise_Authorisation__c getRMA(String RMANum) {
        Return_Merchandise_Authorisation__c RMA;
        try {            //Return_
            if(!Schema.sObjectType.Return_Merchandise_Authorisation__c.isAccessible()) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Return_Merchandise_Authorisation__c.Label));
            } else { RMA = Database.query('select ' + String.escapeSingleQuotes(RMAFields) + ', Order__r.Bill_To_Address__c, Order__r.Ship_To_Address__c, Return_Contact__r.Name from Return_Merchandise_Authorisation__c where (Id = \'' + String.escapeSingleQuotes(RMANum) + '\') Limit 1'); }

            if(RMA.Order__r.Bill_To_Address__c != null) {if(!Schema.sObjectType.Address__c.isAccessible()) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Address__c.Label));} else { invoiceAddress = Database.query('Select '+ String.escapeSingleQuotes(addressFields) + ' From Address__c Where (Id = \'' + String.escapeSingleQuotes(RMA.Order__r.Bill_To_Address__c) + '\')limit 1'); }
            }
            if(RMA.Order__r.Ship_To_Address__c != null) {  if(!Schema.sObjectType.Address__c.isAccessible()) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+ sObjectType.Address__c.Label));} else { deliveryAddress = Database.query('Select '+ String.escapeSingleQuotes(addressFields) + ' From Address__c Where (Id = \'' + String.escapeSingleQuotes(RMA.Order__r.Ship_To_Address__c) + '\')limit 1'); }
            }

        } catch(Exception e) {exceptionMethod(e, 'getRMA'); }
        return RMA;
    }

    public void buildCcEmail()
    {
        String[] strArray=contactids.split(','); ccEmails =strArray;
    }

     public PageReference sendRMA(){
        List<OrgWideEmailAddress> orgaddress = new List<OrgWideEmailAddress>();
         try{
             String csfdcBaseURL = sfdcBaseURL;
             PageReference pageRef = new PageReference('https://'+csfdcBaseURL+'/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+currentContact.id+'&related_to_id='+RMA.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail&val='+ApexPages.currentPage().getParameters().get('val'));

             Attachment InvoiceAttachment = new Attachment(Name=RMA.Name+'.pdf',contentType='application/pdf',body=PageRef.getContentAsPdf(),ParentId=RMA.id); if(String.isNotEmpty(toEmail_id)){   Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c != null ) { orgaddress = [SELECT id From OrgWideEmailAddress Where Address =:EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c LIMIT 1]; if(orgaddress.size() > 0) email.setOrgWideEmailAddressId(orgaddress[0].id); } else email.setSenderDisplayName('Aqxolt India Private Limited'); email.setCcAddresses(ccemails); String [] toAddresses = toEmail_id.split(',');email.setToAddresses(toAddresses); email.setBccSender(false);email.setUseSignature(false);email.setTreatBodiesAsTemplate(true); email.setSubject(EmailSubject); if(!EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Html_Body__c){ String HtmlEmailBody = '<pre style="font-size: 14px;font-family: sans-serif;">'+TextBody+'</pre>';email.setHtmlBody(HtmlEmailBody);}else{email.setHtmlBody(HtmlBody);} if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].TemplateAsAttachment__c){Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();attach.setFileName('RMA:'+RMA.Name+'.pdf'); Blob b = InvoiceAttachment.body;attach.setBody(b);email.setFileAttachments(new Messaging.EmailFileAttachment[] {attach}); }Messaging.SendEmailResult [] Email_Result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Email Sent Successfully')); }
        }
        catch(Exception e){
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+ ' @ Line Number ' +e.getLineNumber()));
         }
        return null;
    }

    public PageReference Back2RMA() {
        PageReference page = new PageReference('/'+RMA.Id); return page;
    }
    public void exceptionMethod(Exception e, String methodName) {
        exceptionMsg = 'Inside ' + methodName +', '+ e.getTypeName() +', '+ e.getMessage() +', Line : '+ e.getLineNumber();
    }

    //added by khaleeq for rma pdf functionamity
    public pageReference createPDF(){
    PageReference Page;
    try{

      sfdcBaseURL = System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '.my.salesforce.com') + '.file.force.com';
      PageReference pageRef = new PageReference('https://' + sfdcBaseURL +
                '/email/templaterenderer?id=' + MailselectedTemplate.id +
                '&recipient_type_id=' + currentContact.id +
                '&related_to_id=' + RMA.id +
                '&base_href=https://' + sfdcBaseURL + 'salesforce.com' +
                '&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY' +
                '&setupid=CommunicationTemplatesEmail&val=' + ApexPages.currentPage().getParameters().get('val'));
      //pdf = EncodingUtil.Base64Encode((!test.isRunningTest())?pageRef.getContentAsPdf():Blob.valueOf('Test'));
      /*soname : '+soname*/
      String ReceiveURL = '/apex/RMA_PDF1?Id=' + RMA.id + '&custId=' + cusId;
      Page = new PageReference(ReceiveURL);
    } catch (Exception e){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage() + ' @ Line Number ' + e.getLineNumber()));
    }

    //page.setRedirect(true);
    return Page;
  }





}