import { track, api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import validateAddress from "@salesforce/label/c.Validate_Address";
import shipmentGoing from "@salesforce/label/c.X1_Where_is_this_shipment_going";
import CompanyLabel from "@salesforce/label/c.CompanyLabel";
import ContactLabel from "@salesforce/label/c.ContractConsole_Contact";
import PhoneLabel from "@salesforce/label/c.Phone_AddTimeCardEntry";

import upsLogo from '@salesforce/resourceUrl/LogisticsResource';
//Load scripts
import { loadStyle } from 'lightning/platformResourceLoader';
import CMP_CSS from '@salesforce/resourceUrl/CMP_CSS';
import PickPackShipResources from '@salesforce/resourceUrl/PickPackShipResources';
import SLDSX from '@salesforce/resourceUrl/SLDSX';


import getInitialData from '@salesforce/apex/UPSRestAPI.getDefaultData';
import getRates from '@salesforce/apex/UPSRestAPI.Service_And_Rate_Request';
import Shipping_Request_Response from '@salesforce/apex/UPSRestAPI.Shipping_Request_Response';
import voidShipment from '@salesforce/apex/UPSRestAPI.voidShipment';
import trackShipment from '@salesforce/apex/UPSRestAPI.getTrackingDetails';
import PickupRateRequest from '@salesforce/apex/UPSRestAPI.Pickup_Rate_Request';

export default class UPSRest extends NavigationMixin(LightningElement) {
    UpsImg = upsLogo + '/LogisticsResource/PickPackShipResource/assets/images/UPSLogo.png';

    @track shipmentFlows;
    @track isLoading = false;
    @track RateMsg = [];
    @track sucessMsg = '';
    @track ShowAddressbutton = true;
    @track masterShipmentId = '';
    @api shipmentIds =''; //= 'a0i0600000Eh9ztAAB,a0i0600000EhA5dAAF';
    @api packageIds = [];// = ['a0L0600000SxPFkEAN'];
    @track fromAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Contact__c: '', Contact__r: { Id: '', Name: '', Company__c: '' },Customer__c:'', Customer__r:{Id:'',Name: '',Company_txt__c:''} };
    @track suggestedAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Contact__c: '', Contact__r: { Id: '', Name: '', Company__c: '' } };
    @track ShowCancelShipment = false;
    @track toAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '' ,Customer__c:'', Customer__r:{Id:'',Name: '',Company_txt__c:''}};
    @track showFromAddress = false;
    @track showToAddress = true;
    @track ShowAddressbutton = false;
    @track toAddressSelected = false;
    @track toAddressUrl = '';
    @track toEmail = '';
    @track toPhone = '';
    @track isCompanyAvailable = false;
    @track isShiptoContactAvailable = false;
    @track toShipmentType = false;
    @track showSuggestedAddress = false;
    @track FromAddressSelected = false;
    @track billingAddressSelected = false;
    @track billContactSelected = false;
    @track fromAddressUrl = '';
    @track FromEmail = '';
    @track fromPhone = '';
    @track fromShipmentType = false;
    @track packageList = [];
    @track packageItems = [];
    @track TermsOfShipment = [];
    @track reasonforexportOptions = [];
    @track signatureserviceOptions = [];
    @track billingOptions = [];
    @track showTabTwo = false;
    @track showTabOne = true;
    @track ShowInitiateShipment = false;
    @track shipment = { Id: null, Name: '', Shipment_Identification_Number__c: '', Status__c: '', TrackingNumber__c: '', Label_options__c: 'LABEL', Invoice_Number__c: '', Purchase_Order_Number__c: '', Terms_Of_Shipment__c: '', Reason_For_Export__c: 'SAMPLE', Declaration_Statement__c: '', Shipment_Date__c: '', Description__c: '', Signature_Services__c: '', Shipment_Billing_options__c: 'SENDER', Fedex_Special_Services__c: '', Billing_Account_Number__c: '', Billing_Contact__c: '', Billing_Contact__r: { Id: '', Name: '' }, Billing_Address__c: '', Billing_Address__r: { Id: '', Name: '' },Package_Ready_Time__c:'', Customer_Close_Time__c:'',Pickup_Confirmation_Number__c:'' };
    @track returnShipment = { Id: null, Name: '', Shipment_Identification_Number__c: '', Status__c: '', TrackingNumber__c: '', Label_options__c: 'LABEL', Invoice_Number__c: '', Purchase_Order_Number__c: '', Terms_Of_Shipment__c: '', Reason_For_Export__c: 'SAMPLE', Declaration_Statement__c: '', Shipment_Date__c: '', Description__c: '', Signature_Services__c: '', Shipment_Billing_options__c: 'SENDER', Fedex_Special_Services__c: '', Billing_Account_Number__c: '', Billing_Contact__c: '', Billing_Contact__r: { Id: '', Name: '' }, Billing_Address__c: '', Billing_Address__r: { Id: '', Name: '' } };
    @track ShowGetRate = true;
    @track disableBillingOption = false;
    @track showReturnLabel = false;
    @track selectedDate;
    @track selectedTime;
    @api isforRMA;
    @api isfromLWC;
    @api returnmaid;
    @api refundamt;
    @api issaccess;
    @api isorderacc;
    @api isfromrmadetail;
    label = {
        validateAddress,
        shipmentGoing,
        CompanyLabel,
        ContactLabel,
        PhoneLabel
    };
    @track isReturnShipment = false;
    @track defaulWrap = {};
    @track selectedServiceType = '';
    @track selectedServiceCode = '';
    @track selectedCurrency = '';
    @track errorList = [];
    @track Credentials;
    @track fromContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' } };
    @track toContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' } };
    @track rateResponse;
    @track showLabel = false;
    @track allowReturnShipment = false;
    @track allowFedExReturnShipmentFromUPS = false;
    @track selectedLogisticReturnShipType = '';
    @track showReturnShipmentTab = false;
    @track showUPSReturnType = false;
    @track showFedexReturnType = false;
    validateAddressCall() {

    }

    navigateToAura(){
        console.log('navigte to aru');
        console.log('this.packageList nav aura----'+JSON.stringify(this.packageList));
           this[NavigationMixin.Navigate]({
               type: 'standard__component',
               attributes: {
                   componentName: 'c__RMAPackage' // Note: use namespace if needed
               },
               state: {
                   c__pkgListBool: 'true',
                   c__pkgBool : 'false' ,
                   //c__packageList : JSON.stringify(this.packageList),
                   c__ReturnMAID : this.returnmaid,
                   c__refundAmt : this.refundamt,
                   c__isSOAccess : this.issaccess,
                   c__isOrderAcc : this.isorderacc,
                   c__isFromRMADetail : this.isfromrmadetail
               }
           });
           console.log('333');
    }


    connectedCallback() {
        this.isLoading = true;
        console.log('packageIds : ',JSON.stringify(this.packageIds));
        // console.log('shipmentIds----'+this.shipmentIds);
        console.log('ReturnMAID:', this.returnmaid);
        console.log('Refund Amount:', this.refundamt);
        console.log('isSOAccess:', this.issaccess);
        console.log('isOrderAcc:', this.isorderacc);
        console.log('isFromRMADetail:', this.isfromrmadetail);
        getInitialData({ ShipId: this.shipmentIds, packIds: JSON.stringify(this.packageIds) })
            .then(result => {
                console.log('getInitialData res : ', result);

                    if (result) {
                        if (result.alertlist && result.alertlist.length > 0) {
                            this.errorList = Object.assign([], this.errorList);
                            this.errorList = result.alertlist;
                            this.isLoading = false;
                        }
                        else {
                        this.defaulWrap = result;
                        //console.log('1');
                        this.Credentials = result.credsWrap;
                        if(this.shipmentIds) {
                            if(!result.ship.Billing_Contact__c) {
                                result.ship.Billing_Contact__c = '';
                                result.ship.Billing_Contact__r = {Id : '',Name : ''};
                            }
                            if(!result.ship.Billing_Address__c){
                                result.ship.Billing_Address__c = '';
                                result.ship.Billing_Address__r = {Id : '',Name : ''};
                            }
                            this.shipment = result.ship;
                            //console.log('Name : ',this.shipment.Name);
                        }
                        //console.log('shipment :',JSON.stringify(this.shipment));
                        //console.log('2');
                        if(result.toAddress  && Object.keys(result.toAddress).length !== 0) this.toAddress = result.toAddress;
                        else this.errorList.push('To Address is missing on your logistics.');
                        //console.log('3');
                        if(result.fromAddress  && Object.keys(result.fromAddress).length !== 0) this.fromAddress = result.fromAddress;
                        else this.errorList.push('From Address is missing on your logistics.');
                        //console.log('4');
                        if (this.fromAddress.Id) {
                            this.FromAddressSelected = true;
                            this.fromAddressUrl = '/' + this.fromAddress.Id;
                        }
                        //console.log('5');
                        if (this.toAddress.Id) {
                            this.toAddressSelected = true;
                            this.toAddressUrl = '/' + this.toAddress.Id;
                        }
                       console.log('result.fromContact : ',result.fromContact);
                        if(result.fromContact && Object.keys(result.fromContact).length !== 0) this.fromContact = result.fromContact;
                        else this.errorList.push('From contact is missing on your logistics.');
                       // console.log('7');
                       if(result.toContact && Object.keys(result.toContact).length !== 0)  this.toContact = result.toContact;
                       else this.errorList.push('To contact is missing on your logistics.');
                       // console.log('8');
                        for (var x in result.packList) {
                            result.packList[x].packUrl = '/' + result.packList[x].Id;
                        }
                        this.allowReturnShipment = result.allowReturnShipment;
                        this.allowFedExReturnShipmentFromUPS = result.allowFedExReturnShipmentFromUPS;
                        //console.log('9');
                        if (result.packList && result.packList.length > 0) {
                            console.log('result.packList[0].Logistic__c=>'+result.packList[0].Logistic__c);
                            if (result.packList[0].Logistic__r != null) {this.shipment.Shipment_Billing_options__c = result.packList[0].Logistic__r.Billing_options__c;}
                            this.shipment.Billing_Contact__c = result.packList[0].Logistic__r != null ? result.packList[0].Logistic__r.Billing_Contact__c : '';
                            if (result.packList[0].Logistic__r != null && result.packList[0].Logistic__r.Billing_Contact__c) {
                                this.billContactSelected = true;
                                this.shipment.Billing_Contact__r.Id = result.packList[0].Logistic__r.Billing_Contact__c;
                                this.shipment.Billing_Contact__r.Name = result.packList[0].Logistic__r.Billing_Contact__r.Name;

                            }
                            else {
                                this.billContactSelected = false;
                                this.shipment.Billing_Contact__r = { Id: '', Name: '' };
                            }
                            if (result.packList[0].Logistic__r != null){
                                if (result.packList[0].Logistic__r.Billing_Address__c) { this.shipment.Billing_Address__c = result.packList[0].Logistic__r.Billing_Address__c;}
                            }
                            if(result.packList[0].Logistic__r != null){
                            if (result.packList[0].Logistic__r.Billing_Address__c) {
                                this.billingAddressSelected = true;
                                this.shipment.Billing_Address__r.Id = result.packList[0].Logistic__r.Billing_Address__c;
                                this.shipment.Billing_Address__r.Name = result.packList[0].Logistic__r.Billing_Address__r.Name;
                            }
                        }
                            else {
                                this.billContactSelected = false;
                                this.shipment.Billing_Address__r = { Id: '', Name: '' };
                            }
                            this.shipment.Billing_Account_Number__c = result.packList[0].Logistic__r != null ?   result.packList[0].Logistic__r.Billing_Account_number__c : '';
                            if (this.allowReturnShipment && result.packList[0].Logistic__r.Shipment_type_Return__c) {
                                this.selectedLogisticReturnShipType = result.packList[0].Logistic__r.Shipment_type_Return__c;
                               console.log('this.selectedLogisticReturnShipType : ',this.selectedLogisticReturnShipType);
                                 if (this.selectedLogisticReturnShipType == 'UPS') {
                                    this.showUPSReturnType = true;
                                    this.showFedexReturnType = false;
                                }
                                else if (this.selectedLogisticReturnShipType == 'FedEx') {
                                    this.showUPSReturnType = false;
                                    if (this.allowFedExReturnShipmentFromUPS) this.showFedexReturnType = true;
                                }
                            }
                            if (this.allowReturnShipment && this.selectedLogisticReturnShipType == '') {
                                if(this.allowFedExReturnShipmentFromUPS) this.showFedexReturnType = true;
                                this.showUPSReturnType = true;
                            }
                        }
                        console.log('this.showUPSReturn : ',this.showUPSReturnType);
                       // console.log('10');
                        this.packageList = result.packList;
                        this.packageItems = result.packItems;
                        //console.log('11');
                        var today = new Date();
                        if (!this.shipmentIds) this.shipment.Shipment_Date__c = today.getFullYear() + '-' + ('0' + (today.getMonth() + 1)).slice(-2) + '-' + ('0' + today.getDate()).slice(-2);
                        if (this.shipmentIds) {
                            this.showLabel = true;
                            this.ShowGetRate = false;
                            this.ShowCancelShipment = true;
                        }
                        if(result.returnShip && Object.keys(result.returnShip).length !== 0){
                            this.showFedexReturnType = false;
                            this.showUPSReturnType = false;
                            this.showReturnLabel = true;
                            this.returnShipment = result.returnShip;
                        }
                        //console.log('12');
                        this.disableBillingOption = result.disableBillingDetails;

                        this.isLoading = false;
                    }
                    }

            }).
            catch(error => {
                this.isLoading = false;
                console.log('1 Error:', error);
                this.errorList = Object.assign([], this.errorList);
                //if(error && error.body)
               // if (this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                //if (this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
            });
    }
    get ShowRateMsg() {
        if (this.RateMsg) {
            if (this.RateMsg.length > 0)
                return true;
            else
                return false;
        } else {
            return false;
        }

    }
    get isShipmentShipped() {
        return this.shipment.Status__c === 'Shipped';
    }
    renderedCallback() {
        try {
            Promise.all([
                loadStyle(this, CMP_CSS + '/CSS/global-axolt.css'),
                loadStyle(this, PickPackShipResources + '/assets/styles/erp_mark7_bootstrap.css'),
                loadStyle(this, SLDSX + '/assets/styles/salesforce-lightning-design-system-vf.css'),
            ])
                .then(() => {
                    console.log('Static Resource Loaded');
                })
                .catch(error => {
                    console.log('Static Resource Error', error);
                });
        } catch (e) {
            console.log('Error:', e);
        }
    }
    get showReturnShipment() {
        if (this.shipment) {
            if(this.shipment.Id && this.allowReturnShipment && !this.returnShipment.Id && this.shipment.Status__c != 'Cancelled') {
                console.log('true return ship');
                return true;
            }
        }
        else false;
    }
    handlebillOptionsChange(event) {
        this.shipment.Shipment_Billing_options__c = event.target.value;
    }
    closeErrorList() { this.errorList = []; }
    get isErrorList() {
        if (this.errorList) {
            if (this.errorList.length > 0)
                return true;
            else
                return false;
        } else {
            return false;
        }

    }
    Shipping_Rate() {
        this.isLoading = true;
        console.log('PackageItems : ', JSON.stringify(this.packageList));
        console.log('isReturnShipment : ',this.isReturnShipment);
        this.RateMsg = [];
        console.log('packList->',this.packageList)
        console.log("myConsVar->", JSON.stringify(this.Credentials))
        console.log("fromAdd-> ", JSON.stringify(this.fromAddress))
        console.log("toAdd->", JSON.stringify(this.toAddress))
        console.log("isReturnShipment->", this.isReturnShipment)
        console.log("fromContact->", JSON.stringify(this.fromContact))
        console.log("toContact->", JSON.stringify(this.toContact))
        console.log("shipment->", JSON.stringify(this.shipment))
        console.log("packageList->", JSON.stringify(this.packageList))

        getRates({ packList: this.packageList, myConsVar: JSON.stringify(this.Credentials), fromAdd: JSON.stringify(this.fromAddress), toAdd: JSON.stringify(this.toAddress), fromContact: JSON.stringify(this.fromContact), toContact: JSON.stringify(this.toContact), shipDate: this.shipment.Shipment_Date__c, Shipment: JSON.stringify(this.shipment), isReturnShipment: this.isReturnShipment }).then(result => {
            if (result) {
                console.log('getRates result : ', result);

                if (result.error != null && result.error != '' && result.error != undefined) {
                    this.errorList = Object.assign([], this.errorList);
                    this.errorList.push(result.error);
                    let responseObject = JSON.parse(result.response);
                    console.log('responseObject = ' + responseObject);

                    if (responseObject && responseObject.response && responseObject.response.errors && responseObject.response.errors.length > 0) {
                        let errorMessage = responseObject.response.errors[0].message;
                        this.errorList.push(errorMessage);
                    }

                    console.log('errorList = ' + this.errorList);
                    
                }
                else {
                    var rateSample = result.ratesList;
                    this.rateResponse = rateSample;
                    if(result.alertlist){
                        this.RateMsg = result.alertlist;
                    }
                }
                this.isLoading = false;

            }
        })
            .catch(error => {
                this.isLoading = false;
                console.log('2 Error:', error);
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
            });
    }
    handleServiceTypeChange(event) {
        this.selectedServiceType = event.target.value;
        console.log('Selected Service Type:', this.selectedServiceType);
        var servicecode = event.target.label;
        console.log('Selected servicecode :', servicecode);
        this.selectedServiceCode = servicecode;
        var index = event.target.dataset.index;
        console.log('Selected index :', index);
        this.selectedCurrency = this.rateResponse[index].currencycode;
        console.log('Selected Currency :', this.selectedCurrency);
        if (this.selectedServiceType) {
            this.ShowGetRate = false;
            this.ShowInitiateShipment = true;
        }
        console.log('this.ShowInitiateShipment :', this.ShowInitiateShipment);
        if(this.shipment.Description__c == null || this.shipment.Description__c == '' || this.shipment.Description__c == undefined )this.shipment.Description__c='This is ddescription';
        console.log('Description__c : ',this.shipment.Description__c);
    }
    Shipping_Request() {
        this.isLoading = true;
        this.RateMsg = [];
        console.log('isReturnShipment : ',this.isReturnShipment);
        console.log('Description__c : ',this.shipment.Description__c);
        console.log('this.packageList : ',JSON.stringify(this.packageList));
        console.log('myConsVar : ',JSON.stringify(this.Credentials));
        console.log('fromAdd : ',JSON.stringify(this.fromAddress));
        console.log('toAddress : ',JSON.stringify(this.toAddress));
        console.log('fromContact : ',JSON.stringify(this.fromContact));
        console.log('toContact : ',JSON.stringify(this.toContact));
        console.log('shipment : ',JSON.stringify(this.shipment));
        console.log('packageItems : ',JSON.stringify(this.packageItems));
        console.log('toComasterShipmentIdntact : ',this.masterShipmentId);
        console.log('package items : ',this.packageItems);
        console.log('Service code : ',this.selectedServiceCode);
        console.log('Service type : ',this.selectedServiceType);
        console.log('Currency code : ',this.selectedCurrency);

        Shipping_Request_Response({ packList: this.packageList, myConsVar: JSON.stringify(this.Credentials), fromAdd: JSON.stringify(this.fromAddress), toAdd: JSON.stringify(this.toAddress), fromContact: JSON.stringify(this.fromContact), toContact: JSON.stringify(this.toContact), shipDate: this.shipment.Shipment_Date__c, Shipment: JSON.stringify(this.shipment), isReturnShipment: this.isReturnShipment, packageItems: this.packageItems, service: this.selectedServiceType, serviceCode: this.selectedServiceCode, currencyCode: this.selectedCurrency,masterShipmentId : this.masterShipmentId }).then(result => {
            console.log('entered Shipping_Request_Response');
            if (result) {
                console.log('res : ', result);
                if (result.error != null && result.error != '' && result.error != undefined) {
                    this.errorList = Object.assign([], this.errorList);
                    this.errorList.push(result.error);
                    let responseObject = JSON.parse(result.response);
                    if (responseObject && responseObject.response && responseObject.response.errors && responseObject.response.errors.length > 0) {
                        let errorMessage = responseObject.response.errors[0].message;
                        this.errorList.push(errorMessage);
                    }
                }
                else {
                    if(this.isReturnShipment) this.returnShipment = result.shipment;
                    this.shipment = result.shipment;
                    this.showLabel = true;
                    this.ShowCancelShipment = true;
                    this.ShowInitiateShipment = false;
                    this.rateResponse = null;
                    this.sucessMsg = 'Shipment created succesfully!';
                    if(this.isforRMA){
                        this.showLabel=false;
                        this.showReturnLabel=true;
                    }
                    if (this.allowReturnShipment && this.packageList[0].Logistic__r.Shipment_type_Return__c) {
                        this.selectedLogisticReturnShipType = this.packageList[0].Logistic__r.Shipment_type_Return__c;
                       console.log('this.selectedLogisticReturnShipType : ',this.selectedLogisticReturnShipType);
                         if (this.selectedLogisticReturnShipType == 'UPS') {
                            this.showUPSReturnType = true;
                            this.showFedexReturnType = false;
                        }
                        else if (this.selectedLogisticReturnShipType == 'FedEx') {
                            this.showUPSReturnType = false;
                            if (this.allowFedExReturnShipmentFromUPS) this.showFedexReturnType = true;
                        }
                    }
                    if (this.allowReturnShipment && this.selectedLogisticReturnShipType == '') {
                        if(this.allowFedExReturnShipmentFromUPS) this.showFedexReturnType = true;
                        this.showUPSReturnType = true;
                    }
                }
                this.isLoading = false;
            }
        })
            .catch(error => {
                console.log('3 Error:', error);
                this.isLoading = false;
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
            });
    }
    viewReturnLabels(){
        try {
            console.log('label ');

            var shipmentsId =  this.returnShipment.Id ? this.returnShipment.Id : this.shipment.Id;
            console.log('shipmentsId =>'+shipmentsId);
            if(this.isforRMA) {
                this.isReturnShipment=this.Shipment;
                this.returnShipment.Tracking_Unique_Id__c = "UPS";
               }
            var fileName = 'UPS_Label';
            var val = 'pdf';
            console.log('val ');

            // Construct the URL
            var url = '/apex/PrintUPSLabel?shipmentsId=' + shipmentsId + '&fileName=' + fileName + '&val=' + val;

            // Open the URL in a new tab
            window.open(url, '_blank');

            console.log('URL opened in new tab');
        } catch (e) {
            console.log(e);
        }
    }
    viewLabels() {
        try {
            console.log('label ');

            var shipmentsId = (this.isReturnShipment) ? this.returnShipment.Id : this.shipment.Id;
            console.log('shipmentsId =>'+shipmentsId);

            var fileName = 'UPS_Label';
            var val = 'pdf';
            console.log('val ');

            // Construct the URL
            var url = '/apex/PrintUPSLabel?shipmentsId=' + shipmentsId + '&fileName=' + fileName + '&val=' + val;
            
            // Open the URL in a new tab
            window.open(url, '_blank');

            console.log('URL opened in new tab');
        } catch (e) {
            console.log(e);
        }
    }
    sendReturnLabels(){
        console.log('ENTERED sendReturnLabels');
        try {
            console.log('label ');

            var shipmentsId =  this.returnShipment.Id ? this.returnShipment.Id : this.shipment.Id;
            console.log('shipmentsId ->'+shipmentsId);
            if(this.isforRMA) {
                this.isReturnShipment=this.Shipment;
                this.returnShipment.Tracking_Unique_Id__c = "UPS";
               }
            var fileName = 'UPS_Label';
            var val = 'pdf';
            var shiptype = 'return';
            var contactId = '';
            if(this.toContact && this.toContact.Id != undefined && this.toContact.Id != null && this.toContact.Id != ''){
                contactId = this.toContact.Id;
            }
            console.log('contactId :  ',contactId);

            // Construct the URL
            var url = '/apex/PrintUPSLabel?shipmentsId=' + shipmentsId + '&fileName=' + fileName +'&contactId='+contactId+'&shiptype='+shiptype;

            // Open the URL in a new tab
            window.open(url, '_blank');

            console.log('URL opened in new tab');
        } catch (e) {
            console.log(e);
        }
    }
    viewcommercialLabels() {
        var shipmentsId = (this.isReturnShipment) ? this.returnShipment.Id : this.shipment.Id;
        var url = '/apex/UPSCommercialInvoice?shipmentsId=' + shipmentsId;

        // Open the URL in a new tab
        window.open(url, '_blank');
    }
    cancelShipment() {
        console.log('entered cancelShipment')
        this.isLoading = true;
        console.log('this.packageList=>'+JSON.stringify(this.packageList));
        console.log('myConsVar=>'+JSON.stringify(this.Credentials));
        console.log('Shipment=>'+JSON.stringify(this.shipment));
        voidShipment({ packList: this.packageList, myConsVar: JSON.stringify(this.Credentials), Shipment: JSON.stringify(this.shipment) }).then(result => {
            if (result) {
                console.log('res : ', result);
                if (result.error != null && result.error != '' && result.error != undefined) {
                    this.errorList = Object.assign([], this.errorList);
                    this.errorList.push(result.error);
                    let responseObject = JSON.parse(result.response);
                    if (responseObject && responseObject.response && responseObject.response.errors && responseObject.response.errors.length > 0) {
                        let errorMessage = responseObject.response.errors[0].message;
                        this.errorList.push(errorMessage);
                    }
                    this.isLoading = false;
                }
                else {
                    //this.shipment = result.shipment;
                    if (result.shipment && Object.keys(result.shipment).length > 0) {
                        this.shipment = result.shipment;
                    }
                    this.showLabel = false;
                    this.ShowCancelShipment = false;
                    this.ShowInitiateShipment = false;
                    this.ShowGetRate = true;
                    this.rateResponse = null;
                    this.sucessMsg = 'Shipment Deleted succesfully!';
                    this.isLoading = false;
                }

            }
        })
            .catch(error => {
                console.log('Error:', error);

                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                this.isLoading = false;
            });
    }
    handleStatusChange(event) {
        this.shipment.Status__c = event.currentTarget.value;
    }
    trackingShipment() {
        this.sucessMsg = '';
        this.isLoading = true;
        trackShipment({ packList: this.packageList, myConsVar: JSON.stringify(this.Credentials), Shipment: JSON.stringify(this.shipment) }).then(result => {
            if (result) {
                console.log('res : ', result);
                if (result.error != null && result.error != '' && result.error != undefined) {
                    this.errorList = Object.assign([], this.errorList);
                    this.errorList.push(result.error);
                    let responseObject = JSON.parse(result.response);
                    if (responseObject && responseObject.response && responseObject.response.errors && responseObject.response.errors.length > 0) {
                        let errorMessage = responseObject.response.errors[0].message;
                        this.errorList.push(errorMessage);
                    }
                    this.isLoading = false;
                }
                else {
                    this.shipment = result.shipment;
                    this.shipmentFlows = result.Shipmentflows;
                    this.showLabel = true;
                    if (this.shipment.Status__c != 'Cancelled' && !this.isReturnShipment)  this.ShowCancelShipment = true;
                    this.ShowInitiateShipment = false;
                    this.ShowGetRate = false;
                    this.rateResponse = null;
                    this.isLoading = false;
                    // this.sucessMsg = 'Shipment Deleted succesfully!';
                }
            }
        })
            .catch(error => {
                this.isLoading = false;
                console.log('4 Error:', error);
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
            });
    }
    handleqvNotification(event) {
        this.shipment.QV_Notification__c = event.target.value;
        console.log('QV : ', this.shipment.QV_Notification__c);
    }
    handleCarbonNeutral(event) {
        this.shipment.Carbon_Neutral__c = event.target.value;
        console.log('CN : ', this.shipment.Carbon_Neutral__c);
    }
    handleCOD(event) {
        this.shipment.COD__c = event.target.value;
        console.log('COD : ', this.shipment.COD__c);
    }
    handleDryIce(event) {
        this.shipment.Dry_Ice__c = event.target.value;
        console.log('ice : ', this.shipment.Dry_Ice__c);
    }
    handleReturnService(event) {
        this.shipment.Return_Service__c = event.target.value;
        console.log('return service : ', this.shipment.Return_Service__c);
    }
    handleAdditionalHandling(event) {
        this.shipment.Additional_Handling__c = event.target.value;
        console.log('additional : ', this.shipment.Additional_Handling__c);
    }
    handleVerbalConfirmation(event) {
        this.shipment.Verbal_Confirmation__c = event.target.value;
        console.log('verbal  : ', this.shipment.Verbal_Confirmation__c);
    }
    generateReturnShipment() {
        this.isLoading = true;
        this.sucessMsg = '';
        this.masterShipmentId = this.shipment.Id;
        var today = new Date();
        var fromDate = new Date(today.getFullYear(), 0, 1);
        fromDate = fromDate.getFullYear() + '-' + ('0' + (fromDate.getMonth() + 1)).slice(-2) + '-' + ('0' + fromDate.getDate()).slice(-2);
        console.log('fromDate : ' + fromDate);
        var toAddress = this.fromAddress;
        var fromAddres = this.toAddress;
        this.fromAddress = fromAddres;
        this.toAddress = toAddress;
        var today = new Date();
        this.shipment.Shipment_Date__c = today.getFullYear() + '-' + ('0' + (today.getMonth() + 1)).slice(-2) + '-' + ('0' + today.getDate()).slice(-2);
        this.isReturnShipment = true;

        this.showLabel = false;
        this.ShowCancelShipment = false;
        this.shipment.Name = '';
        this.shipment.Id = null;
        this.ShowGetRate = true;
        this.shipment.Status__c = '';

        if(this.packageList.length > 0){
            this.shipment.Billing_Account_Number__c = this.packageList[0].Logistic__r.Billing_Account_Number_Return__c;
            this.shipment.Shipment_Billing_options__c =  this.packageList[0].Logistic__r.Bill_To_Return__c;
            this.shipment.Billing_Contact__c =  this.packageList[0].Logistic__r.Billing_Contact_Return__c;
            if(this.packageList[0].Logistic__r.Billing_Contact_Return__c){
                this.shipment.Billing_Contact__r = {Id : this.packageList[0].Logistic__r.Billing_Contact_Return__c,Name : this.packageList[0].Logistic__r.Billing_Contact_Return__r.Name};
            }
            this.shipment.Billing_Address__c =  this.packageList[0].Logistic__r.Billing_Address__c;
            if(this.packageList[0].Logistic__r.Billing_Address__c){
                this.shipment.Billing_Address__r = {Id: this.packageList[0].Logistic__r.Billing_Address__c,Name :this.packageList[0].Logistic__r.Billing_Address__r.Name};
            }

        }
        this.isLoading = false;

    }
    backToOldShipment(){
        this.isReturnShipment = false;
        this.connectedCallback();
        this.rateResponse = null;
        this.RateMsg = [];
        this.sucessMsg = '';
    }
    
    handlePickupRate() {
    console.log('🚚 Inside handlePickupRate()');
    this.errorMsg = '';

    const fromAddress = this.fromAddress?.Id;
    const toAddress = this.toAddress?.Id;
    const myConsVariable = JSON.stringify(this.Credentials);

    let errorFlag = true;
    let errorMsg = '';

    console.log('📦 Package Ready Time:', this.shipment.Package_Ready_Time__c);
    console.log('🏪 Customer Close Time:', this.shipment.Customer_Close_Time__c);

    // --- Validations ---
    if (this.shipment.Pickup_Requested__c) {
        errorFlag = false;
        errorMsg += 'Shipment pickup is already active for this package. ';
    }

    if (this.shipment.Status__c === 'Delivered') {
        errorFlag = false;
        errorMsg += 'Shipment delivered — request cannot be processed. ';
    }

    if (this.shipment.Status__c !== 'Shipped') {
        errorFlag = false;
        errorMsg += 'Shipment status must be "Shipped" to process pickup rate request. ';
    }

    if (!this.shipment.Package_Ready_Time__c) {
        errorFlag = false;
        errorMsg += 'Pickup ready time is unavailable. ';
    }

    if (!this.shipment.Customer_Close_Time__c) {
        errorFlag = false;
        errorMsg += 'Pickup close time is unavailable. ';
    }

    if (
        this.shipment.Package_Ready_Time__c &&
        this.shipment.Customer_Close_Time__c &&
        this.shipment.Customer_Close_Time__c !== this.shipment.Package_Ready_Time__c
    ) {
        errorFlag = false;
        errorMsg += 'Pickup ready time and close time must be the same. ';
    }

    // --- If validation failed ---
    if (!errorFlag) {
        this.errorMsg = errorMsg.trim();
        console.error('❌ Validation Failed:', this.errorMsg);
        return; // stop further processing
    }

    // --- If all validations passed ---
    console.log('✅ Validations passed, calling Apex PickupRateRequest');

    PickupRateRequest({
        fromAdd: fromAddress,
        toAdd: toAddress,
        Shipment: JSON.stringify(this.shipment),
        dispatchDate: this.shipment.Shipment_Date__c,
        PackageReadyTime: this.shipment.Package_Ready_Time__c,
        CustomerCloseTime: this.shipment.Customer_Close_Time__c,
        myConsVar: myConsVariable
    })
        .then(result => {
            console.log('✅ Apex call success. Full result:', JSON.stringify(result, null, 2));
            this.UPS_Services = result;
            this.errorMsg = result?.UPSErrorMsg || '';
            this.ShowGetRate = false;

            // Optional: log service rates
            if (result?.rates?.length > 0) {
                console.log('UPS Pickup Rates:');
                result.rates.forEach((r, i) =>
                    console.log(`#${i + 1} ${r.service} — ${r.totalCharges} ${r.currencycode}`)
                );
            }
        })
        .catch(error => {
            console.error('❌ Apex call failed:', error);
            this.errorMsg = error?.body?.message || 'Unexpected error occurred.';
        });
}

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.combineDateTime();
    }

    handleTimeChange(event) {
        this.selectedTime = event.target.value;
        this.combineDateTime();
    }

    combineDateTime() {
        if (this.selectedDate && this.selectedTime) {
            const formattedTime = this.selectedTime.substr(0, 5) + ':00.000Z';
            const combinedDateTime = `${this.selectedDate}T${formattedTime}`;
            this.shipment.Package_Ready_Time__c = combinedDateTime;
            this.shipment.Customer_Close_Time__c = combinedDateTime;
            console.log('this.shipment.Package_Ready_Time__c: ',this.shipment.Package_Ready_Time__c);
            console.log('this.shipment.Customer_Close_Time__c: ',this.shipment.Customer_Close_Time__c);
        }
    }
    handleDescription(event){
        this.shipment.Description__c=event.target.value;
        console.log('this.shipment.Description__c: ',this.shipment.Description__c);
    }
    handleShipDate(event){
        this.shipment.Shipment_Date__c=event.target.value;
        console.log('this.shipment.Shipment_Date__c: ',this.shipment.Shipment_Date__c);
    }
    handleSaturdayDelivery(event){
       this. shipment.Saturday_Delivery__c=event.target.value;
    }
    handleDeliveryConfirmation (event){
        this.shipment.Delivery_Confirmation__c=event.target.value;
    }
    handleIfConfirmation (event){
        this.shipment.International_Forms__c=event.target.value;
    }
    handlePucConfirmation(event){
        this.shipment.Product_Unit_Code__c=event.target.value;
    }
    handleBillAccNum(event){
        this.shipment.Billing_Account_Number__c=event.target.value;
    }


}