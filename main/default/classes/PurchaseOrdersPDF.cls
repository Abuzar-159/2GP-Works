public with sharing class PurchaseOrdersPDF{
    public PO__c PO{get;set;} public PO__c PODownload{get;set;} public list<Purchase_Line_Items__c> PoDownloadList{get;set;}
    public string imageURl{get;set;}
    public string POFields{get;set;}
    public string addressFields{get;set;}
    public Organization orgDetails{get;set;}
    public string PONumber{get;set;}
    public Contact currentContact{get;set;}
    public string toEmail_id{get;set;}
    public string EmailSubject{get;set;}
    public string TextBody{get;set;} public List<selectoption> AvailableRecipients{get;set;} public List<selectoption> SelectedRecipients{get;set;} public string selectedEmail{get;set;} public Map<string,string> ccEmails_map{get;set;} public list<string> ccEmails{get;set;}
    public string contactids{get;set;} public EmailTemplate SelectEmailTemplate{get;set;}
    public EmailTemplate MailselectedTemplate{get;set;} public EmailTemplate EmailedMailselectedTemplate          { get; set; }
    public Boolean MailSent{get;set;}
    public string sfdcBaseURL{get;set;}
    public Boolean isHtmlEmail{get;set;}
    public List<SetEmailTemplates__c> EmailTemplates_uniqueName{get;set;}
    public string HtmlBody{get;set;}
    public Address__c vendorAddress{get;set;}
    public Address__c invoiceAddress{get;set;}
    public Address__c deliveryAddress{get;set;} public string exceptionMsg{get;set;} public string ccEmail_Addresses{get;set;}
    public list<POWrp> poWrpList2{get;set;}
    public String poname                            { get; set; }
    public String cusId                            { get; set; } public String pdf                          { get; set; }
    public String  toCC_id                          { get; set; }
    public String  toBCC_id                          { get; set; }
    public String con_AccId                             { get; set; }  public Decimal itemCount                           { get; set; }
    public List<Attachment> fileList {get; set;} public String contactedId                                { get; set; }

    public PurchaseOrdersPDF(){
        try{
            system.debug('PurchaseOrdersPDF constructor');
            sfdcBaseURL = System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '.my.salesforce.com')+'.file.force.com';
            System.debug('sfdcBaseURL'+sfdcBaseURL);
            //sfdcBaseURL = sfdcBaseURL.removeEndIgnoreCase('visualforce.com');
            //Below works in our erp dev org
            //sfdcBaseURL = sfdcBaseURL.replace('.visual.force.com','.content.force.com');//need to uncommented

            //Commented by Parveez on 05-09-2023 as it was not woring in the sand box and Production.
            /*String initurl;
            if(sfdcBaseURL.contains('.visualforce.com')){ initurl = Label.initURL; }else { initurl = Label.initURL2; }
            String DestinationURL = Label.DestURL;

            sfdcBaseURL = sfdcBaseURL.replace(initurl,DestinationURL);
            if(sfdcBaseURL.contains('sandbox')){ sfdcBaseURL = sfdcBaseURL.replace('--c',''); }
            sfdcBaseURL = sfdcBaseURL.replace('--erp7','--c');
            system.debug('sfdcBaseURL3 '+sfdcBaseURL); */

            String initurl = Label.initURL;
            String DestinationURL = Label.DestURL;

           // sfdcBaseURL = sfdcBaseURL.replace(initurl,DestinationURL);
           // sfdcBaseURL = sfdcBaseURL.replace('--c','');
           // sfdcBaseURL = sfdcBaseURL.replace('my.salesforce.com', 'file.force.com');
           // sfdcBaseURL = Label.DocumentDomainURL;

            fileList = new List<Attachment>();

            //sfdcBaseURL = sfdcBaseURL.replace(initurl,DestinationURL); //working in dev org aqxolt-base-dev-ed.develop.my.salesforce.com
        //sfdcBaseURL = sfdcBaseURL.replace('--erp7','--c');

        //String sendEmailBaseURL = Label.sendEmailBaseURL;
           // sfdcBaseURL = sfdcBaseURL.replace('.visualforce.com','.documentforce.com');

            string CustID;
            MailSent = false;
            poWrpList2=null;
            if(ApexPages.CurrentPage().getParameters().get('Id')!=null)PONumber=EncodingUtil.urlEncode(ApexPages.CurrentPage().getParameters().get('Id'),'UTF-8');
            poname = PONumber;
            if(System.currentPageReference().getParameters().get('custId')!=null)CustID=EncodingUtil.urlEncode(System.currentPageReference().getParameters().get('custId'),'UTF-8');
            cusId = CustID;
            POFields=UtilClass.selectStarFromSObject('PO__c');
            utilClass.FLSCheck(POFields.split(','),'PO__c');
            addressFields=UtilClass.selectStarFromSObject('Address__c');
            utilClass.FLSCheck(addressFields.split(','),'Address__c');
            PO = new PO__c();
            if(PONumber!=null) PO = getPurchaseOrder(PONumber);
            if(PO.Id != null) if(PO.Count_PO_Line_Items__c != null) itemCount = PO.Count_PO_Line_Items__c;

            system.debug('here 1');

            //if(!Schema.sObjectType.Organization.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Organization.Label));//This was commented on 12/01/24 by Asra after getting confirmation from Imran and Moin
            //else orgDetails=[SELECT Id,Name FROM Organization WHERE Id=:UserInfo.getOrganizationId()];
            if(CustID!=null&&CustID!=''){
                if(!Schema.sObjectType.Contact.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Contact.Label));
                else currentContact=[SELECT id,Name,FirstName,LastName,Email,Fax,AccountId,Phone,Contact_Numer__c,Company__c FROM Contact WHERE Id=:CustID Limit 1];
            }
            if(currentContact!=null){
                toEmail_id=currentContact.Email;
                con_AccId = currentContact.AccountId;
            }
            List<Contact> conList= new List<Contact>();
            conList = [select Id, Name, Email, AccountId from Contact where AccountId=:con_AccId];
            /*if(conList.size()>0){
                for(Integer i=1;i<conList.size();i++){ Integer size=0; size=conList.size(); size=size-1; toCC_id+=conList[i].Email; if(size>=i){ toCC_id+=','; } }
            }*/
            List<String> emailList = new List<String>();
            for (Contact c : conList) {
                if (c.Email != null) {
                    if(currentContact!=null && currentContact.Email!=null){
                        if(currentContact.Email!=c.Email){
                        	emailList.add(c.Email);
                        }
                    }else{
                        emailList.add(c.Email);
                    }
                }
            }
            toCC_id = String.join(emailList, ',');

            /*imageURL='/servlet/servlet.FileDownload?file=';
            if(!Schema.sObjectType.Document.isAccessible()){
                system.debug('no access to document');
                ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Document.Label));

            }else{
                List<Document> documentList=[SELECT id,Name,developerName FROM document WHERE developerName=:'Invoice'];
                if(documentList.size()>0) imageURL=imageURL+documentList[0].id;
            }*/

            imageURL = '/servlet/servlet.ImageServer?id=';
            String oid = userInfo.getOrganizationId();
            if(Schema.sObjectType.Document.isAccessible()) {
                List<Document> documentList = new List<Document>();
                documentList = [select id, Name, developerName from document where developerName =: 'Invoice'];
                if(documentList.size() > 0){ imageURL += documentList[0].id; imageURL += '&oid='+oid; } else imageURL = ''; } else imageURL = '';

            system.debug('ImageURL~>'+imageURL);
        } catch(Exception e){ system.debug('exception~>'+e.getMessage()+' at line~>'+e.getStackTraceString()); exceptionMethod(e,'Constructor'); }
/*Querying The Template for Preview and attachment*/
        try{
            EmailTemplates_uniqueName=[SELECT Template_Unique_Name__c,OrgWideEmailAddress__c,Html_Body__c,TemplateAsAttachment__c,Add_Template_As_Attachment__c FROM SetEmailTemplates__c WHERE Name='Purchase_Order_Axolt' limit 1];
            if(EmailTemplates_uniqueName.isEmpty()){
                EmailTemplates_uniqueName=new  List<SetEmailTemplates__c>();
                EmailTemplates_uniqueName.add(new  SetEmailTemplates__c(OrgWideEmailAddress__c=null,Template_Unique_Name__c='Purchase_Order_Axolt',TemplateAsAttachment__c=true,Add_Template_As_Attachment__c=true,Html_Body__c=false));
            }
            if(EmailTemplates_uniqueName.size()>0 && EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Template_Unique_Name__c!=null){
                System.debug('template unique name is '+EmailTemplates_uniqueName+' size is '+EmailTemplates_uniqueName.size());

                MailselectedTemplate=[SELECT id,Body,Subject,HtmlValue FROM EmailTemplate WHERE DeveloperName=:EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Template_Unique_Name__c];
                isHtmlEmail=EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Html_Body__c;
            }
            else { ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.info,'To SetUp  Email Template provide Unique Template Name or Contact your Administrator')); }
        }
        catch(Exception e){ ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+' @ Line Number '+e.getLineNumber()));
        }
    }

    public void Email_Details(){
        try{
            Messaging.SingleEmailMessage email_Attach=new  Messaging.SingleEmailMessage();
            string[] toAddresses_test=new string[]{'test@test.com'};
            email_Attach.setToAddresses(toAddresses_test);
            email_Attach.setTemplateId(MailselectedTemplate.id);
            email_Attach.setSaveAsActivity(false);
            email_Attach.setTargetObjectId(currentContact.id);
            email_Attach.setWhatId(PO.id);
            Savepoint sp=Database.setSavepoint();
            if(currentContact.Email != Null) Messaging.SendemailResult[] email_Attach_Result=Messaging.sendemail(new Messaging.SingleEmailMessage[]{email_Attach});
            Database.rollback(sp);
            EmailSubject=email_Attach.getSubject();
            TextBody=email_Attach.getPlainTextBody();
            HtmlBody=email_Attach.getHtmlBody();System.debug('html body '+HtmlBody);
             } catch(Exception e){ ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+' @ Line Number '+e.getLineNumber())); }
    }
/*
Method For Getting PO Record
*/
    public PO__c getPurchaseOrder(string PONum){
        PO__c PO = new PO__c();
        try{
            if(!Schema.sObjectType.PO__c.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.PO__c.Label));
            else PO=Database.query('select '+String.escapeSingleQuotes(POFields)+', Contract__r.Name from PO__c where (Id = \''+string.escapeSingleQuotes(PONum)+'\') Limit 1');
            if(PO.Invoice_Address__c!=null){
                if(!Schema.sObjectType.Address__c.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Address__c.Label));
                else invoiceAddress=Database.query('Select '+String.escapeSingleQuotes(addressFields)+' From Address__c Where (Id = \''+String.escapeSingleQuotes(PO.Invoice_Address__c)+'\')limit 1');
            }
            if(PO.Delivery_Address__c!=null){
                if(!Schema.sObjectType.Address__c.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Address__c.Label));
                else deliveryAddress=Database.query('Select '+String.escapeSingleQuotes(addressFields)+' From Address__c Where (Id = \''+String.escapeSingleQuotes(PO.Delivery_Address__c)+'\')limit 1');
            }
            if(PO.Vendor_Address__c!=null){
                if(!Schema.sObjectType.Address__c.isAccessible())ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.FATAL,'Insufficient access to Object '+sObjectType.Address__c.Label));
                else vendorAddress=Database.query('Select '+String.escapeSingleQuotes(addressFields)+' From Address__c Where (Id = \''+String.escapeSingleQuotes(PO.Vendor_Address__c)+'\')limit 1');
            }
        }
        catch(Exception e){  exceptionMethod(e,'getPurchaseOrder'); }
        return PO;
    }
    public void buildCcEmail(){

        string[] strArray=contactids.split(','); ccEmails=strArray;

    }

   public PageReference AddAttachs() { fileList.add(new Attachment()); return null; }

    public PageReference sendPO(){
        List<OrgWideEmailAddress> orgaddress = new List<OrgWideEmailAddress>();
        try{
           	// String sendEmailBaseURL = Label.sendEmailBaseURL;
            // sendEmailBaseURL = sfdcBaseURL.replace(Label.DestURL,sendEmailBaseURL);
            //  if(!sfdcBaseURL.contains('content')) sendEmailBaseURL = sendEmailBaseURL.replace('--c','');
            // system.debug('sendEmailBaseURL'+sendEmailBaseURL);
            // //erp-mark-7-dev-ed.file.force.com
            // system.debug('sfdcBaseURL : '+sfdcBaseURL);
            // sendEmailBaseURL = 'aqxolt-base-dev-ed.develop.file.force.com';
            String csfdcBaseURL =  System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '.my.salesforce.com')+'.file.force.com';//Label.DocumentDomainURL;
            system.debug('csfdcBaseURL'+csfdcBaseURL);
            //PageReference pageRef=new  PageReference('https://'+csfdcBaseURL+'documentforce.com/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+currentContact.id+'&related_to_id='+PO.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail&val='+ApexPages.currentPage().getParameters().get('val'));
            //Below works in our erp dev org
            PageReference pageRef;
            if(ApexPages.currentPage().getParameters().get('val')!=null) pageRef = new PageReference('https://'+csfdcBaseURL+'/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+contactedId+'&related_to_id='+PO.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail&val='+ApexPages.currentPage().getParameters().get('val'));
            else pageRef = new PageReference('https://'+csfdcBaseURL+'/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+currentContact.id+'&related_to_id='+PO.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail');
            Attachment InvoiceAttachment=new Attachment(Name=PO.Name+'.pdf',contentType='application/pdf',body=(!test.isRunningTest())?PageRef.getContentAsPdf():Blob.valueof('Test'),ParentId=PO.id);
            System.debug('PageRef.getContentAsPdf  '+PageRef.getContentAsPdf());

            //orgaddress=[SELECT id FROM OrgWideEmailAddress LIMIT 1];

            if(String.isNotEmpty(toEmail_id)){ Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c != null ) {orgaddress = [SELECT id From OrgWideEmailAddress Where Address =:EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c LIMIT 1];if(orgaddress.size() > 0) email.setOrgWideEmailAddressId(orgaddress[0].id); }else { string senderName = System.Label.SenderDisplayName;
                                                   system.debug('senderName : '+senderName); email.setSenderDisplayName(senderName);String [] toAddresses = toEmail_id.split(',');email.setToAddresses(toAddresses); }
                                              //email.setBccSender(false);
                                              if(String.isNotEmpty(toCC_id)) {String [] toCCAddresses = toCC_id.split(',');email.setCcAddresses(toCCAddresses); } if(String.isNotEmpty(toBCC_id)) {String [] toBCCAddresses = toBCC_id.split(',');email.setBccAddresses(toBCCAddresses);} email.setUseSignature(false);email.setTreatBodiesAsTemplate(true);email.setSubject(EmailSubject);

                                              if(!EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Html_Body__c){ String HtmlEmailBody = '<pre style="font-size: 14px;font-family: sans-serif;">'+TextBody+'</pre>'; email.setHtmlBody(HtmlEmailBody); }else{email.setHtmlBody(HtmlBody);}
                                              if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].TemplateAsAttachment__c){
                                                  List<Messaging.EmailFileAttachment> attachList = new List<Messaging.EmailFileAttachment>();
                                                  for(Attachment att : fileList){  if(att.name != null && att.body != null){ Messaging.EmailFileAttachment attach1 = new Messaging.EmailFileAttachment(); attach1.setFileName(att.name);Blob b = att.body;attach1.setBody(b);attachList.add(attach1); att.ParentId = PONumber; }
                                                  }
                                                  if(fileList.size()>0){ insert fileList; }
                                                  if(InvoiceAttachment!=null){
                                                      insert InvoiceAttachment;
                                                  }
                                                  Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment(); attach.setFileName('Purchase Order:'+PO.Name+'.pdf');Blob b = InvoiceAttachment.body;attach.setBody(b);attachList.add(attach);
                                                  email.setFileAttachments(new List<Messaging.EmailFileAttachment>(attachList));
                                              } Messaging.SendEmailResult [] Email_Result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});MailSent = Email_Result.get(0).isSuccess();  if(MailSent){ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Email Sent Successfully')); } else{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,Email_Result.get(0).getErrors()[0].getMessage()));
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             }
                                             }else{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please Enter the Email Address')); }
        }
           /* if(string.isNotEmpty(toEmail_id)){
                String SenderDisplayLabelValue = System.Label.Email_Sender_Display_Name;
                Messaging.SingleEmailMessage email = new  Messaging.SingleEmailMessage();
                if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c != null ) {
                     orgaddress = [SELECT id From OrgWideEmailAddress Where Address =:EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].OrgWideEmailAddress__c LIMIT 1];
                     if(orgaddress.size() > 0) email.setOrgWideEmailAddressId(orgaddress[0].id);
                }
                else email.setSenderDisplayName(SenderDisplayLabelValue);
                //else email.setSenderDisplayName('Aqxolt India Private Limited');
                //email.setCcAddresses(ccemails);
                string[] toAddresses=toEmail_id.split(',');
                email.setToAddresses(toAddresses);
                if(String.isNotEmpty(toCC_id)) {
                    String [] toCCAddresses = toCC_id.split(',');
                    email.setCcAddresses(toCCAddresses);
                }
                if(String.isNotEmpty(toBCC_id)) {
                   String [] toBCCAddresses = toBCC_id.split(',');
                   email.setBccAddresses(toBCCAddresses);
                }
                //email.setBccSender(false);
                email.setUseSignature(false);
                email.setTreatBodiesAsTemplate(true);
                email.setSubject(EmailSubject);
                if(!EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].Html_Body__c){
                    string HtmlEmailBody='<pre style="font-size: 14px;font-family: sans-serif;">'+TextBody+'</pre>';
                    email.setHtmlBody(HtmlEmailBody);
                }
                else email.setHtmlBody(HtmlBody);
                if(EmailTemplates_uniqueName[EmailTemplates_uniqueName.size()-1].TemplateAsAttachment__c){
                    Messaging.EmailFileAttachment attach=new  Messaging.EmailFileAttachment();
                    attach.setFileName('Purchase Order:'+PO.Name+'.pdf');
                    Blob b=InvoiceAttachment.body;
                    attach.setBody(b);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
                }
                Messaging.SendEmailResult[] Email_Result=Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});

                MailSent = Email_Result.get(0).isSuccess();

                if(MailSent){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,'Email Sent Successfully'));
                } else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,Email_Result.get(0).getErrors()[0].getMessage()));
                }
            }
         }*/



        catch(Exception e){
            ApexPages.addMessage(new  ApexPages.Message(ApexPages.Severity.Error,e.getMessage()+' @ Line Number '+e.getLineNumber()));
        }
        return null;
    }
    public PageReference Back2PO(){ try{ PageReference page=new  PageReference('/'+PO.Id); return page; }catch(Exception e){ PageReference page=new  PageReference('/'+PO.Id);  return page; } }

    public void exceptionMethod(Exception e,string methodName){  exceptionMsg='Inside '+methodName+', '+e.getTypeName()+', '+e.getMessage()+', Line : '+e.getLineNumber();
    }

    public void getPOListVF(){
        try{
        String AccId = apexpages.currentpage().getparameters().get('Id'); String poListString = apexpages.currentpage().getparameters().get('pos'); list<POWrp> poWrpList=new list<POWrp>(); List<PO__c> PoList = (List<PO__c>) JSON.deserialize(poListString, List<PO__c>.class);


        //String query='SELECT Id, Name,Total_Amount__c ,Inbound_Total_Quantity__c,Inbound_Received_Quantity__c, Tax_Amount__c  , Status__c , Total_Quantity__c ,Vendor__r.Name,Vendor__c , Amount_Paid__c    FROM PO__c WHERE Vendor__c=\''+AccId+'\'  and RecordTypeId != null ';//  WHERE Vendor__c=\''+AccIdTotal_Amount__c ,Inbound_Total_Quantity__c,Inbound_Received_Quantity__c, Tax_Amount__c  , Status__c , Total_Quantity__c ,Vendor__r.Name,Vendor__c , Amount_Paid__c    FROM PO__c WHERE Vendor__c !=null
        //List<PO__c> PoList=DataBase.query(query);
        for(integer i=0;i<PoList.size();i++){ POWrp poWrp=new POWrp(); list<Purchase_Line_Items__c> purchaseOrderList=new list<Purchase_Line_Items__c>(); purchaseOrderList=[select id,Name,Product__r.Name,Quantity__c,Unit_Price__c,Total_Tax__c,Total_Price__c from Purchase_Line_Items__c where Purchase_Orders__c=:PoList[i].Id]; poWrp.pOrderList=purchaseOrderList; poWrp.Po=PoList[i]; poWrpList.add(poWrp); }
        poWrpList2=poWrpList;
        }catch(Exception e){        }
   }

    public void getPOListDownload(){ try{ String pId = apexpages.currentpage().getparameters().get('Id'); PODownload=[select Id,Contract__r.Name,Order_Date__c,Revision_Number__c,Revision_Date__c,Description__c,Payment_Terms__c,Publication_Date__c, Name,Delivery_Address__r.Address_Line3__c,Delivery_Address__r.Postal_Code__c,Delivery_Address__r.Country__c,Delivery_Address__r.County__c,Delivery_Address__r.City__c,Total_Amount__c ,Delivery_Address__r.Address_Line2__c,Delivery_Address__r.Address_Line1__c,Vendor_Contact__r.Phone,Vendor_Address__r.Country__c,Vendor_Address__r.Postal_Code__c ,Vendor_Address__r.County__c,Vendor_Address__r.City__c,Vendor_Address__r.Address_Line3__c,Vendor_Address__r.Address_Line2__c,Vendor_Address__r.Address_Line1__c,Vendor_Contact__r.Name,Vendor__r.Company__c,Inbound_Total_Quantity__c,Inbound_Received_Quantity__c, Tax_Amount__c  , Company__r.Name,Company__r.BillingCountry,Company__r.Phone,Company__r.Fax,Company__r.BillingStreet,Company__r.BillingCity,Company__r.BillingState, Status__c , Total_Quantity__c ,Vendor__r.Name,Vendor__c , Amount_Paid__c    FROM PO__c WHERE Id=:pId]; PoDownloadList=[select id,Name,Product__r.Name,Quantity__c,Total_Tax__c,Unit_Price__c,Total_Price__c,Shipping_Cost__c,Quantity_Received__c from Purchase_Line_Items__c where Purchase_Orders__c=:pId]; }catch(Exception e){} }


    public class POWrp { public PO__c po{get;set;} public list<Purchase_Line_Items__c> pOrderList{get;set;} }

    public pageReference createPDF() {
        try{
            system.debug('createPDF');
        String csfdcBaseURL = System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '.my.salesforce.com')+'.file.force.com';//Label.DocumentDomainURL;
        //PageReference pageRef = new PageReference('https://'+csfdcBaseURL+'documentforce.com/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+currentContact.id+'&related_to_id='+PO.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail&val='+ApexPages.currentPage().getParameters().get('val'));
        //Below works in our erp dev org
        //EmailedMailselectedTemplate =  [select id,Body, Subject,HtmlValue from EmailTemplate where DeveloperName ='Purchase_Order_Alert'];
        PageReference pageRef = new PageReference('https://'+csfdcBaseURL+'/email/templaterenderer?id='+MailselectedTemplate.id+'&recipient_type_id='+currentContact.id+'&related_to_id='+PO.id+'&base_href=https://'+csfdcBaseURL+'salesforce.com&preview_frame=previewFrame&render_type=REPLACED_HTML_BODY&setupid=CommunicationTemplatesEmail&val='+ApexPages.currentPage().getParameters().get('val'));
      //  pdf = EncodingUtil.Base64Encode((!test.isRunningTest())?PageRef.getContentAsPdf():Blob.valueOf('Test'));
        String ReceiveURL = '/apex/PoPdf?id='+poname+'&custId='+cusId;
        PageReference Page = new PageReference(ReceiveURL);System.debug('html body in createPDF '+HtmlBody);System.debug('ReceiveURL createPDF '+ReceiveURL);
        return Page; }catch(Exception e){            String csfdcBaseURL = System.Url.getOrgDomainUrl().toExternalForm().substringBetween('https://', '.my.salesforce.com')+'.file.force.com';/*Label.DocumentDomainURL;  */          PageReference Page = new PageReference(csfdcBaseURL);        	return Page; }
    }
}