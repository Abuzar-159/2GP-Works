import { LightningElement, api, track, wire } from 'lwc';
import ProductSearchName from '@salesforce/label/c.ProductSearchName';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import BaseStaticResource from '@salesforce/resourceUrl/BaseStaticResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import OrderDocument from '@salesforce/label/c.OrderDocument';
import { RefreshEvent } from 'lightning/refresh';
//Apex Methods
import { refreshApex } from '@salesforce/apex';
import getInitialData from '@salesforce/apex/Epos.fetchInitailDetails';
import getAccountDetails from '@salesforce/apex/Epos.fetchAccDetails';
import getContactDetails from '@salesforce/apex/Epos.fetchContactDetails';
import getBillToAddress from "@salesforce/apex/Epos.billToAddress";
import getShipToAddress from "@salesforce/apex/Epos.shipToAddress";
import getOrderProfile from '@salesforce/apex/Epos.OrderProfile';
import getCurrentEmployee from "@salesforce/apex/Epos.currentEmp";
import getInitialProducts from '@salesforce/apex/Epos.initialProducts';
import getDiscountPlanupdated from '@salesforce/apex/Epos.getDiscountPlanupdated';
import getlatestStock from '@salesforce/apex/Epos.latestStock';
import saveOrderAndLine from '@salesforce/apex/Epos.saveOrderAndLines';
import getOrderDetails from "@salesforce/apex/Epos.fetchOrderDetails";
import getApplyCoupons from "@salesforce/apex/Epos.ApplyCoupons";
import fetchOrdDetailsForClone from "@salesforce/apex/Epos.fetchOrdDetailsForClone";


export default class Epos extends LightningElement {
@track searchText = '';
		companyName='';
    debounceTimeout;

    handleInputChange(event) {
        this.searchText = event.target.value;

        // Log the current input text to the console
        console.log('Current input in lookup field:', this.searchText);

        // Debounce logic to delay search calls
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.performSearch(this.searchText);
        }, 300);
    }

    performSearch(searchText) {
        // Your search logic goes here
        console.log('Searching for:', searchText);
        // Make server calls or filter local data based on searchText
    }

    error;
    errorList = [];
    spinner = false;
    @track order = { Status: 'Draft', Is_Back_Order__c: false, Is_Pre_Order__c: false, Is_Closed__c: false, Issue_Invoice__c: false, Sub_Total__c: 0, Due_Amount__c: 0 };
    OrderFilter = "";
    @track orderCurrency;
    itemsToDel = [];
    //changes by maqsood
    @track currentTab = 'OrderTab';
    /*orderTabClass='active';
    discountTabClass='';
    paymentTabClass='';
    deliveryTabClass='';
    chatterTabClass='';
    accountTabClass='';*/
    @track isOrderSelected = false; // Controls enabling/disabling of Issue Invoice fix for giih 524
    get orderTabClass() {
        return this.currentTab == 'OrderTab' ? 'active' : '';
    }
    get discountTabClass() {
        return this.currentTab == 'DiscountTab' ? 'active' : '';
    }
    get paymentTabClass() {
        return this.currentTab == 'PaymentTab' ? 'active' : '';
    }
    get deliveryTabClass() {
        return this.currentTab == 'DeliveryTab' ? 'active' : '';
    }
    get chatterTabClass() {
        return this.currentTab == 'ChatterTab' ? 'active' : '';
    }
    get accountTabClass() {
        return this.currentTab == 'AccountTab' ? 'active' : '';
    }


    get isShowOrder() {
        return this.currentTab == 'OrderTab' ? true : false;
    }
    get isShowDiscount() {
        return this.currentTab == 'DiscountTab' ? true : false;
    }
    get isShowPayment() {
        return this.currentTab == 'PaymentTab' ? true : false;
    }
    get isShowDelivery() {
        return this.currentTab == 'DeliveryTab' ? true : false;
    }
    get isShowChatter() {
        return this.currentTab == 'ChatterTab' ? true : false;
    }
    get isShowAccount() {
        return this.currentTab == 'AccountTab' ? true : false;
    }
    get isOrderActivated() {
        return this.order.Status != 'Draft' ? true : false;
    }

    get iconDisableOrNot() {
        return this.isOrderActivated ? 'disableIcon' : 'clickableIcon';
    }

    showOrderTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'OrderTab';

    }
    showDiscountTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'DiscountTab';
    }
    showPaymentTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'PaymentTab';
    }
    showDeliveryTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'DeliveryTab';
    }
    showChatterTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'ChatterTab';
    }
    showAccountTab() {
        console.log('this.currentTab:', this.currentTab);
        console.log('isShowDiscount:', this.isShowDiscount);

        this.currentTab = 'AccountTab';
    }



    allCurrencies;
    isMultiCurrency = false;
    ordStatusData;
    ordStatus;
    shipmentType;

    contactFilter = "AccountId ='" + this.AccountId + "'";

    billToAddFull;
    billToFilter = "Customer__c='' AND Is_Billing_Address__c=true AND Active__c=true";

    shipToAddFull;
    shipToFilter = "Customer__c='' AND Is_Shipping_Address__c=true AND Active__c=true";

    OrderProfileFilter = '';
    orgFilter = "Account_Type__C = 'Organisation'";

    employeeFilter = 'Employee_User__c != null AND Active__c=true';

    showAddButton = false;
    showSaveButton = true;

    isCloningOrder = false;
    isCloneConfirmation = false;
    /*get showAddButton() {
        if (this.order.AccountId && this.order.Order_Profile__c && this.order.Order_Profile__r.Channel__c && this.order.Order_Profile__r.Price_Book__c && this.order.Bill_To_Address__c && this.order.Ship_To_Address__c)
            return true;
        else return false;


    }
    get showSaveButton() {
        console.log('inside showSaveButton');
        console.log('this.order:', this.order);
        if (this.order.AccountId && this.order.Contact__c && this.order.Bill_To_Address__c && this.order.Ship_To_Address__c && this.order.Order_Profile__c && this.selectedProducts)//this.order.Ship_To_Address__c
            return false;
        else return true;
    }*/
    showCon = true;

    currentFlow = 'mainPage';

    SearchName = ProductSearchName;
    searchItem;

    isEditOrderItem = false;
    @track orderItemEditIndex;
    @track orderItemToEdit;

    deleteConfirmation = false;
    indexToDel;

    @track listOfProducts;
    @track selectedProducts = [];

    couponCode;
    couponRemList = [];
    iscouponRemList = false;
    disableApply = true;

    invoiceList = [];
    isInvoiceList = false;
    paymentList = [];
    isPaymentList = false;

    @track shipmentsList = [];
    @track isShipmentsList = false;
    @track listOfCheckedProucts = [];

    GetAccountId = '';
    getAccountName = '';
    GetContactId = '';


    subTotal = 0;
    discounts = 0;
    finalDue = 0;


    get accountSelected() {
        console.log('accountSelected called');
        return this.order.Account.Id != '' ? true : false;
    }
    get customerUrl() {
        console.log('customerUrl called');
        return '/' + this.order.Account.Id;
    }
    get contactSelected() {
        return this.order.Contact__c ? true : false;
    }
    get contactUrl() {
        return '/' + this.order.Contact__c;
    }
    get billToSelected() {
        return this.order.Bill_To_Address__c ? true : false;
    }
    get billToAddUrl() {
        return '/' + this.order.Bill_To_Address__c;
    }
    get shipToSelected() {
        return this.order.Ship_To_Address__c ? true : false;
    }
    get shipToAddUrl() {
        return '/' + this.order.Ship_To_Address__c;
    }

    get orderSelected() {
        return this.order.Id ? true : false;
    }
    get orderUrl() {
        return '/' + this.order.Id;
    }
    get OrderPofileUrl() {
        return '/' + this.order.Order_Profile__r.Id
    }
    get OrderProfileSelected() {
        return this.order.Order_Profile__r.Id != '' ? true : false;
    }
    get employeeSelected() {
        return this.order.Employee__c ? true : false;
    }
    get employeeUrl() {
        return '/' + this.order.Employee__c;
    }
    get selectProjectUrl() {
        return '/' + this.order.Project__r.Id
    }
    get projectSelected() {
        return this.order.Project__c ? true : false;
    }

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

    closeErrorList() {
        this.errorList = [];
    }

    /*@wire(getInitialData)
    InitailDetails({ error, data }) {
        if (data) {
            console.log('initial result:', data);
            this.errorList = data.error;
            this.order.EffectiveDate = data.todayDate;
            this.ordStatusData = data.ordStatus;
            if (this.order.Id) this.ordStatus = this.ordStatusData;
            else this.ordStatus = [{ label: this.ordStatusData[0].label, value: this.ordStatusData[0].value }];
            this.shipmentType = data.ShipmentType;
            this.order.Employee__c = data.currEmp.Id;
            this.order.Employee__r = data.currEmp;
            console.log('order:', this.order);
        } else if (error) {
            this.errorList = Object.assign([], this.errorList);
            if(!this.errorList.includes(error)) this.errorList.push(error);
        }
    }*/

    selectAccount(event) {
        console.log('selectAccount called');
        try {
            this.spinner = true;
            console.log('selectAccount called : ', JSON.stringify(event.detail));
            this.order.AccountId = event.detail.Id;
            this.GetAccountId = this.order.AccountId;
            console.log('slected Account Name Epos:', event.detail.Name);
            this.accountname = event.detail.Name;
            //this.accountSelected = true;
            this.contactFilter = " AND AccountId='" + this.order.AccountId + "'";
            this.billToFilter = " AND Customer__c='" + this.order.AccountId + "' AND Is_Billing_Address__c=true AND Active__c=true ";
            this.shipToFilter = " AND Customer__c='" + this.order.AccountId + "' AND Is_Shipping_Address__c=true AND Active__c=true ";
            this.OrderFilter = " AND AccountId='" + this.order.AccountId + "'";
            if (this.order.AccountId) {
                getAccountDetails({ accId: this.order.AccountId })
                    .then(result => {
                        console.log('res of getAccountDetails:', result);
                        this.errorList = result.error;
                        this.orderCurrency = result.orderCurrency;
                        this.allCurrencies = result.allCurrencies;
                        this.isMultiCurrency = result.isMultiCurrency;
                        this.order.CurrencyIsoCode = result.orderCurrency;
                        this.order.Account = JSON.parse(JSON.stringify(result.acc));

                        console.log('this.order.Account~>' + JSON.stringify(this.order.Account));

                        if (this.order.Account.Order_Profile__c) {
                            console.log('inhere order.accout.orderprofile exists');
                            this.order.Order_Profile__c = result.custProfile.Id;
                            this.order.Order_Profile__r = result.custProfile;

                            if (!this.order.Order_Profile__r.Channel__c) {
                                this.errorList = Object.assign([], this.errorList);
                                if (!this.errorList.includes('Do not have Channel on Order Profile :' + this.order.Account.Order_Profile__r.Name)) this.errorList.push('Do not have Channel on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }
                            if (!this.order.Order_Profile__r.Price_Book__c) {
                                this.errorList = Object.assign([], this.errorList);
                                if (!this.errorList.includes('Do not have Pricebook on Order Profile :' + this.order.Account.Order_Profile__r.Name)) this.errorList.push('Do not have Pricebook on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }
                            /*if (this.order.Account.Order_Profile__r.Channel__c) this.order.Order_Profile__r.Channel__c = this.order.Account.Order_Profile__r.Channel__c;
                            else {
                                this.errorList = Object.assign([], this.errorList);
                                this.errorList.push('Do not have Channel on Order Profile :' +this.order.Account.Order_Profile__r.Name);
                            }
                            if (this.order.Account.Order_Profile__r.Price_Book__c) this.order.Order_Profile__r.Price_Book__c = this.order.Account.Order_Profile__r.Price_Book__c;
                            else {
                                this.errorList = Object.assign([], this.errorList);
                                this.errorList.push('Do not have Price Book on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }*/

                        } else {
                            console.log('order profile not found inhere but whyyy??');
                            this.errorList = Object.assign([], this.errorList);
                            if (!this.errorList.includes('Order Profile Not available on Account, Please select Order Profile')) this.errorList.push('Order Profile Not available on Account, Please select Order Profile');
                        }

                        if (this.order.Account.Account_Profile__c)
                            this.OrderProfileFilter = " AND Account_Profile__c = '" + this.order.Account.Account_Profile__c + "' and Active__c = true WITH SECURITY_ENFORCED ";
                        else {
                            this.OrderProfileFilter = " AND Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED ";
                            this.order.Account.Account_Profile__r = { Id: '', Name: '' };
                        }

                        console.log('this.OrderProfileFilter~>' + this.OrderProfileFilter);

                        this.order.Contact__c = result.con.Id;
                        this.order.Contact__r = result.con;

                        this.GetContactId = result.con.Id;
                        this.contactname = result.con.Name;
                        
                        this.order.Bill_To_Address__c = result.billToAdd.Id;
                        this.order.Bill_To_Address__r = result.billToAdd;
                        
                        if(this.order.Account.Company__c != null && this.order.Account.Company__c != undefined){
                            this.order.Account.Company__r.Name = result.acc.Company__r.Name;
                            this.order.Account.Company__c = result.acc.Company__r.Id;
                        }

                        if (this.order.Bill_To_Address__c) {
                            console.log('this.order.Bill_To_Address__c generating');
                            this.billToAddFull = this.addressGenerator(this.order.Bill_To_Address__r);
                        }

                        this.order.Ship_To_Address__c = result.shipToAdd.Id;
                        this.order.Ship_To_Address__r = result.shipToAdd;
                        if (this.order.Ship_To_Address__c) {
                            console.log('this.order.Ship_To_Address__c generating');
                            this.shipToAddFull = this.addressGenerator(this.order.Ship_To_Address__r);
                        }
                        this.spinner = false;

                        console.log('this.order atlast~>' + JSON.stringify(this.order));

                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error getAccountDetails:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    });
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    selectNewAccount(event) {
        try {
            console.log('inside selectNewAccount');
            console.log('afterRefresh called : ', event.detail.Id);
						

            if (this.order.AccountId && this.order.AccountId != '')
                return;
            else
                this.order.AccountId = event.detail.Id;
            this.spinner = true;
            //this.accountSelected = true;
            this.contactFilter = "AccountId='" + this.order.AccountId + "'";
            this.billToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Billing_Address__c=true AND Active__c=true";
            this.shipToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Shipping_Address__c=true AND Active__c=true";
            this.OrderFilter = "AccountId='" + this.order.AccountId + "'";
            if (this.order.AccountId) {
                getAccountDetails({ accId: this.order.AccountId })
                    .then(result => {
                        console.log('res of getAccountDetails:', result);
                        this.errorList = result.error;
                        this.orderCurrency = result.orderCurrency;
                        this.allCurrencies = result.allCurrencies;
                        this.isMultiCurrency = result.isMultiCurrency;
                        this.order.CurrencyIsoCode = result.orderCurrency;
                        this.order.Account = JSON.parse(JSON.stringify(result.acc));
                        if (this.order.Account.Order_Profile__c) {
                            this.order.Order_Profile__c = result.custProfile.Id;
                            this.order.Order_Profile__r = result.custProfile;

                            if (!this.order.Order_Profile__r.Channel__c) {
                                this.errorList = Object.assign([], this.errorList);
                                if (!this.errorList.includes('Do not have Channel on Order Profile :' + this.order.Account.Order_Profile__r.Name)) this.errorList.push('Do not have Channel on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }
                            if (!this.order.Order_Profile__r.Price_Book__c) {
                                this.errorList = Object.assign([], this.errorList);
                                if (!this.errorList.includes('Do not have Pricebook on Order Profile :' + this.order.Account.Order_Profile__r.Name)) this.errorList.push('Do not have Pricebook on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }
                            /*if (this.order.Account.Order_Profile__r.Channel__c) this.order.Order_Profile__r.Channel__c = this.order.Account.Order_Profile__r.Channel__c;
                            else {
                                this.errorList = Object.assign([], this.errorList);
                                this.errorList.push('Do not have Channel on Order Profile :' +this.order.Account.Order_Profile__r.Name);
                            }
                            if (this.order.Account.Order_Profile__r.Price_Book__c) this.order.Order_Profile__r.Price_Book__c = this.order.Account.Order_Profile__r.Price_Book__c;
                            else {
                                this.errorList = Object.assign([], this.errorList);
                                this.errorList.push('Do not have Price Book on Order Profile :' + this.order.Account.Order_Profile__r.Name);
                            }*/

                        } else {
                            this.errorList = Object.assign([], this.errorList);
                            if (!this.errorList.includes('Order Profile Not available on Account, Please select Order Profile')) this.errorList.push('Order Profile Not available on Account, Please select Order Profile');
                        }

                        if (this.order.Account.Account_Profile__c)
                            this.OrderProfileFilter = "Account_Profile__c = '" + this.order.Account.Account_Profile__c + "' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                        else {
                            this.OrderProfileFilter = "Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                            this.order.Account.Account_Profile__r = { Id: '', Name: '' };
                        }

                        this.order.Contact__c = result.con.Id;
                        this.order.Contact__r = result.con;

                        this.order.Bill_To_Address__c = result.billToAdd.Id;
                        this.order.Bill_To_Address__r = result.billToAdd;
                        if (this.order.Bill_To_Address__c) {
                            this.billToAddFull = this.addressGenerator(this.order.Bill_To_Address__r);
                        }

                        this.order.Ship_To_Address__c = result.shipToAdd.Id;
                        this.order.Ship_To_Address__r = result.shipToAdd;
                        if (this.order.Ship_To_Address__c) {
                            this.shipToAddFull = this.addressGenerator(this.order.Ship_To_Address__r);
                        }
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error getAccountDetails:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    });
            }
        } catch (e) { console.log('Error:', error); }
    }

    handleRefreshComponent() {
        try {
           // if (!this.order.Id) {
                window.location.reload();
            //}
            console.log('Iam In the Refresh::');
            //eval("$A.get('e.force:refreshView').fire();");
            //this.dispatchEvent(new RefreshEvent());
            /*this.order.Account = '';
            this.order.Account.AccountNumber = '';
            this.order.Contact__c = '';
            this.order.Bill_To_Address__c = '';
            this.order.Ship_To_Address__c = '';*/
        } catch (e) {

            console.log('Error:', JSON.stringify(e));
        }
    }

    selectContact(event) {
        try {
            console.log('selectAccount called : ', JSON.stringify(event.detail));
            this.spinner = true;
            this.order.Contact__c = event.detail.Id;
            this.contactname = event.detail.Name;
            this.GetContactId = this.order.Contact__c;
            if (this.order.Contact__c) {
                getContactDetails({ contId: this.order.Contact__c })
                    .then(result => {
                        console.log('res of getContactDetails:', result);
                        if (result) this.order.Contact__r = result;
                        this.order.Contact__r.Title = result.Title;
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error of getContactDetails:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    });
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    selectNewContact(event) {
        try {
            console.log('selectNewContact called : ', JSON.stringify(event.detail));
            if (this.order.Contact__c && this.order.Contact__c != '') {
                return;
            }
            else if (this.order.AccountId == event.detail.AccId)
                this.order.Contact__c = event.detail.Id;
            else
                return;
            if (this.order.Contact__c) {
                getContactDetails({ contId: this.order.Contact__c })
                    .then(result => {
                        console.log('res of getContactDetails:', result);
                        if (result) this.order.Contact__r = result;
                    })
                    .catch(error => {
                        console.log('Error of getContactDetails:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    });
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeContact() {
        try {
            this.order.Contact__c = null;
            this.order.Contact__r = { Id: '', Name: '' };
        } catch (e) {
            console.log('Error:', e);
        }
    }

    selectNewAddress(event) {
        let isBillingAddAvbl = false;
        let isShippingAddAvbl = false;
        if (this.order.Bill_To_Address__c)
            isBillingAddAvbl = true;
        if (this.order.Ship_To_Address__c)
            isShippingAddAvbl = true;

        if (!isBillingAddAvbl && event.detail.isBilling && this.order.AccountId == event.detail.accId) {
            this.order.Bill_To_Address__c = event.detail.Id;
            if (this.order.Bill_To_Address__c) {
                getBillToAddress({ addId: this.order.Bill_To_Address__c })
                    .then(result => {
                        console.log('res of getBillToAddress:', result);
                        if (result) {
                            this.order.Bill_To_Address__r = result;
                            this.billToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.log('Error of getBillToAddress:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        }

        if (!isShippingAddAvbl && event.detail.isShipping && this.order.AccountId == event.detail.accId) {
            this.order.Ship_To_Address__c = event.detail.Id;
            if (this.order.Ship_To_Address__c) {
                getShipToAddress({ addId: this.order.Ship_To_Address__c })
                    .then(result => {
                        console.log('res of getShipToAddress:', result);
                        if (result) {
                            this.order.Ship_To_Address__r = result;
                            this.shipToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.log('Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        }
    }

    selectBillTo(event) {
        try {
            console.log('inside selectBillTo: ', JSON.stringify(event.detail));
            this.order.Bill_To_Address__c = event.detail.Id;
            if (this.order.Bill_To_Address__c) {
                getBillToAddress({ addId: this.order.Bill_To_Address__c })
                    .then(result => {
                        console.log('res of getBillToAddress:', result);
                        if (result) {
                            this.order.Bill_To_Address__r = result;
                            this.billToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.log('Error of getBillToAddress:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeBillTo() {
        try {
            console.log('inside removeBillToAdd');
            this.order.Bill_To_Address__c = null;
            this.order.Bill_To_Address__r = { Id: '', Name: '' };
            this.billToAddFull = undefined;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    selectShipTo(event) {
        try {
            console.log('inside selectBillTo: ', JSON.stringify(event.detail));
            this.order.Ship_To_Address__c = event.detail.Id;
            if (this.order.Ship_To_Address__c) {
                getShipToAddress({ addId: this.order.Ship_To_Address__c })
                    .then(result => {
                        console.log('res of getShipToAddress:', result);
                        if (result) {
                            this.order.Ship_To_Address__r = result;
                            this.shipToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.log('Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeShipTo() {
        try {
            console.log('inside removeShipTo');
            this.order.Ship_To_Address__c = null;
            this.order.Ship_To_Address__r = { Id: '', Name: '' };
            this.shipToAddFull = undefined;
        } catch (e) {
            console.log('Error:', e);
        }
    }
  // isIssueInvoiceDisabled Getter to determine if Issue Invoice should be disabled for fix giih 524 by matheen
  get isIssueInvoiceDisabled() {
    return !this.isOrderSelected;
}
    selectOrder(event) {
        try {
            this.order.Id = event.detail.Id;
            console.log('Order Id on order lookup Selection::~>', this.order.Id);
            this.fetchOrdDetailsHelper(this.order.Id);
             // isOrderSelected Sets isOrderSelected to true if an order is selected fix for giih 524 by matheen
            this.isOrderSelected = !!this.order.Id;  
            this.showSaveButton = false;//added on 8/5/25 by matheen
            console.log('showSaveButton:', this.showSaveButton); 
            /*getOrderDetails({
                OrderId: this.order.Id,
            })
                .then(result => {
                    console.log('result of selectOrder:', result);
                    this.order = JSON.parse(JSON.stringify(result.ord));
                    if (this.order.Id) this.ordStatus = this.ordStatusData;
                    if (this.order.Bill_To_Address__c) this.billToAddFull = this.addressGenerator(this.order.Bill_To_Address__r);
                    if (this.order.Ship_To_Address__c) this.shipToAddFull = this.addressGenerator(this.order.Ship_To_Address__r);
    
                    this.evaluateOrder();
                    
                    this.selectedProducts = this.convertOrdItemsToSelProds(result.ordItems);
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })*/
        } catch (e) {
            console.log('Error:', e);
        }

    }
    removeOrder() {
        try {
            this.order.Id = '';
            this.order.Name = '';
            this.selectedProducts = [];
        } catch (e) {
            console.log('Error:', e);
        }

    }

    selectOrderProfile(event) {
        try {
            this.order.Order_Profile__c = event.detail.Id;
            if (event.detail.Id) {
                getOrderProfile({ ordProfileId: event.detail.Id })
                    .then(result => {
                        console.log("res of getOrderProfile:", result);
                        this.order.Order_Profile__r = result;
                    })
                    .catch(error => {
                        console.log('Error of getOrderProfile:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })

            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeOrderProfile() {
        try {
            this.order.Order_Profile__c = null;
            this.order.Order_Profile__r = { Id: '', Name: '' };
        } catch (e) {
            console.log('Error:', e);
        }
    }

    selectEmployee(event) {
        try {
            this.order.Employee__c = event.detail.Id;
            if (this.order.Employee__c) {
                getCurrentEmployee({ empId: this.order.Employee__c })
                    .then(result => {
                        if (result) {
                            this.order.Employee__r = result;
                            console.log('this.order:', this.order);
                        }
                    })
                    .catch(error => {
                        console.log('Error of getCurrentEmployee:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeEmployee() {
        try {
            this.order.Employee__c = null;
            this.order.Employee__r = { Id: '', Name: '' };
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleCurrency(event) {
        try {
            this.order.CurrencyIsoCode = event.detail.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }


    selectProject(event) {
        try {
            this.order.Project__c = event.detail.Id;
            this.order.Project__r = { Id: event.detail.Id, Name: event.detail.Name };
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeProject() {
        try {
            this.order.Project__c = null;
            this.order.Project__r = { Id: '', Name: '' };
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleOrdRef(event) {
        try {
            this.order.OrderReferenceNumber = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleEffDate(event) {
        try {
            this.order.EffectiveDate = event.detail.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    /*handleEffDate(event) {
try {
    const enteredDate = new Date(event.detail.value);
    const today = new Date();

    // Set today's date to midnight to avoid time differences affecting the comparison
    today.setHours(0, 0, 0, 0);

    if (enteredDate > today) {
        this.order.EffectiveDate = today.toISOString().split('T')[0]; // format date as YYYY-MM-DD
    } else {
        this.order.EffectiveDate = event.detail.value;
    }
} catch (e) {
    console.log('Error:', e);
}
}*/

    handleExpDate(event) {
        try {
            this.order.Expected_Date__c = event.detail.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleChangeStatus(event) {
        try {
            this.order.Status = event.detail.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleOrdDescription(event) {
        try {
            this.order.Special_Instructions__c = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleChangeShipment(event) {
        try {
            this.order.Shipment_Type__c = event.detail.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    /*handleAuthorize(event) {
        this.order.Authorised__c = event.detail.checked;
    }*/
    handleIssInv(event) {
        try {
            this.order.Issue_Invoice__c = event.detail.checked;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleIsClose(event) {
        try {
            this.order.Is_Closed__c = event.detail.checked;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    get showAddProducts() {
        return (this.currentFlow == 'addProducts') ? true : false;
    }
    get showMainPage() {
        return (this.currentFlow == 'mainPage') ? true : false;
    }
    get isProdSelected() {
        return this.selectedProducts.length > 0 ? true : false;
    }
    get islistOfProdAvbl() {
        if (this.listOfProducts) {
            return this.listOfProducts.length > 0 ? true : false;
        }
        return false;
    }

    openOrderDoc() {
        if (this.order.Id && this.order.Id != '') {
            var URL_Ord = '';
            URL_Ord = OrderDocument;
            URL_Ord = URL_Ord + 'custId=' + this.order.Contact__c + '&Id=' + this.order.Id;
            console.log('URL_Ord',URL_Ord);
            window.open(URL_Ord, '_blank');
        }
    }

    showAddProductsPage() {
        try {
            this.listOfCheckedProucts = [];
            //this.mainPage=false;
            //this.adProd=true;
            console.log('orderProfile:', this.order.Order_Profile__c);
            getInitialProducts({
                currProfile: JSON.stringify(this.order.Order_Profile__r),
                billToAddId: this.order.Bill_To_Address__c,
                shipToAddId: this.order.Ship_To_Address__c,
                searchItem: '',
            })
                .then(result => {
                    console.log('result of getInitialProducts:', result);

                    let res = JSON.parse(JSON.stringify(result));   //deep clone
                    //let res= Object.assign([], result);           //Shalow clone
                    console.log('res:', res);
                    for (let i in res) {
                        console.log('Product:', res[i].pbe.Product2.Name, 'Is Kit:', res[i].pbe.Product2.Is_Kit__c, 'Stock:', res[i].stock);
                        if (res[i].stock == 0 && res[i].pbe.Product2.Allow_Back_Orders__c) res[i].stock = 'Back Order';
                        if (res[i].pbe.Product2.Is_Kit__c) res[i].stock = 'Kit';
                        res[i].checkSelected = false;
                    }
                    this.listOfProducts = res;
                    this.currentFlow = 'addProducts';
                    console.log('this.listOfProducts:', this.listOfProducts);
                })
                .catch(error => {
                    console.log('Error of getInitialProducts:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) {
            console.log('Error:', e);
        }
    }

    prodURL(event) {
        try {
            console.log('inside prodURL');
            let currentIndex = event.currentTarget.dataset.index;
            //event.detail.title
            console.log('val:', currentIndex);
            const rowData = this.listOfProducts[currentIndex];
            window.open('/' + rowData.pbe.Product2.Id, '_blank');
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleCheckbox(event) {
        try {
            let checked = event.detail.checked;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].checkSelected = checked;
            if (checked) {
                this.listOfCheckedProucts.push(this.listOfProducts[index]);
                console.log('this.listOfCheckedProucts:', this.listOfCheckedProucts);
            }
            else if (!checked) {

                for (var i in this.listOfCheckedProucts) {

                    if (i > -1) {
                        console.log('localIndex::', i);
                        if (this.listOfCheckedProucts[i].pbe.Product2.Id === this.listOfProducts[index].pbe.Product2.Id)
                            this.listOfCheckedProucts.splice(i, 1);
                    }

                }

            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleUnitPrice(event) {
        try {
            console.log('event.currentTarget.value:', event.currentTarget.value);
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].pbe.UnitPrice = (value != '') ? parseFloat(value) : '';
            if (this.listOfProducts[index].pbe.UnitPrice == '') this.listOfProducts[index].UnitPriceClass = 'hasError1 ';
            else this.listOfProducts[index].UnitPriceClass = '';
            //else res[i].pbe.UnitPriceClass = 'no-display inputWidth3';
            //this.calculateTaxAndDiscount(index);
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleQuantity(event) {
        try {
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            let prod = event.currentTarget.dataset.prodid;
            this.listOfProducts[index].quantity = (value != '') ? parseFloat(value) : '';
            if (this.listOfProducts[index].quantity == '') this.listOfProducts[index].quantityClass = 'hasError1';
            else this.listOfProducts[index].quantityClass = '';
            if (value && value != '') {
                getDiscountPlanupdated({
                    profileId: this.order.Order_Profile__c,
                    prodId: prod,
                    quantity: value
                })
                    .then(result => {
                        console.log('result of getDiscountPlanupdated:', result);
                        this.listOfProducts[index].CurrentDiscounts = result[0].CurrentDiscounts;
                        this.listOfProducts[index].discountPlan = result[0].discountPlan;
                        this.listOfProducts[index].disPlans = result[0].disPlans;
                        this.listOfProducts[index].discountPercent = result[0].discountPercent;
                        this.listOfProducts[index].maxDiscount = result[0].maxDiscount;
                        this.listOfProducts[index].minDiscount = result[0].minDiscount;
                        this.listOfProducts[index].tierDists = result[0].tierDists;
                        this.listOfProducts[index].isPercent = result[0].isPercent;
                        console.log('this.listOfProducts[index]:', this.listOfProducts[index]);
                    })
                    .catch(error => {
                        console.log('Error of getDiscountPlanupdated:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDiscPlan(event) {
        try {
            this.spinner = true;
            let discountPlan = event.detail.value;
            let index = event.currentTarget.dataset.index;
            //let prod = event.currentTarget.dataset.prodid;
            this.listOfProducts[index].discountPlan = discountPlan;

            if (discountPlan != '') {
                for (var j = 0; j < this.listOfProducts[index].disPlans.length; j++) {
                    if (discountPlan == this.listOfProducts[index].disPlans[j].Id) {
                        if (this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined) {
                            this.listOfProducts[index].isPercent = true;
                            if (this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].discountPercent = 0;
                            if (this.listOfProducts[index].disPlans[j].Floor_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].minDiscount = this.listOfProducts[index].disPlans[j].Floor_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].minDiscount = 0;
                            if (this.listOfProducts[index].disPlans[j].Ceiling_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].maxDiscount = this.listOfProducts[index].disPlans[j].Ceiling_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].maxDiscount = 0;
                        } else {
                            this.listOfProducts[index].isPercent = false;
                            if (this.listOfProducts[index].disPlans[j].Default_Discount_Value__c != undefined)
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Value__c;
                            else
                                this.listOfProducts[index].discountPercent = 0;
                            if (this.listOfProducts[index].disPlans[j].Floor_Discount_Value__c != undefined)
                                this.listOfProducts[index].minDiscount = this.listOfProducts[index].disPlans[j].Floor_Discount_Value__c;
                            else
                                this.listOfProducts[index].minDiscount = 0;
                            if (this.listOfProducts[index].disPlans[j].Ceiling_Discount_Value__c != undefined)
                                this.listOfProducts[index].maxDiscount = this.listOfProducts[index].disPlans[j].Ceiling_Discount_Value__c;
                            else
                                this.listOfProducts[index].maxDiscount = 0;
                        }
                        this.spinner = false;
                        return;
                    }
                }
            } else {
                this.listOfProducts[index].discountPlan = discountPlan;
                this.listOfProducts[index].isPercent = true;
                this.listOfProducts[index].discountPercent = 0;
                this.listOfProducts[index].minDiscount = 0;
                this.listOfProducts[index].maxDiscount = 0;
            }
            this.spinner = false;
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }
    handleDiscount(event) {
        try {
            let discount = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            if (discount == '') this.listOfProducts[index].discountClass = 'hasError1';
            else this.listOfProducts[index].discountClass = '';
            if (discount && discount != '') {
                if (this.listOfProducts[index].maxDiscount != 0) {
                    if (discount > this.listOfProducts[index].maxDiscount) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes('Discount was larger than Max discount')) this.errorList.push('Discount was larger than Max discount');
                        for (var j = 0; j < this.listOfProducts[index].disPlans.length; j++) {
                            if (this.listOfProducts[index].isPercent) {
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c;
                                break;
                            }
                            else
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Value__c;
                        }

                    } else {
                        this.listOfProducts[index].discountPercent = discount != '' ? parseFloat(discount) : '';
                    }
                } else {
                    this.listOfProducts[index].discountPercent = discount != '' ? parseFloat(discount) : '';
                }
            } else {
                this.listOfProducts[index].discountPercent = discount != '' ? parseFloat(discount) : '';
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDescription(event) {
        try {
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].pbe.Product2.Description = value;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    backToMainPage() {
        try {
            this.currentFlow = 'mainPage';
            //this.mainPage=true;
            //this.adProd=false;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    /*assignSearchValue(event) {
        let search = event.detail.value;
        this.searchItem = search;
    }*/

    fetchProducts(event) {
        try {
            this.spinner = true;
            this.searchItem = event.currentTarget.value;
            console.log('searchItem:', this.searchItem);
            getInitialProducts({
                currProfile: JSON.stringify(this.order.Order_Profile__r),
                billToAddId: this.order.Bill_To_Address__c,
                shipToAddId: this.order.Ship_To_Address__c,
                searchItem: this.searchItem,
            })
                .then(result => {
                    console.log('result of fetchProducts:', result);

                    let res = JSON.parse(JSON.stringify(result));
                    if (res.length > 0) {
                        for (let i in res) {
                            console.log(' fetch products Product:', res[i].pbe.Product2.Name, 'Is Kit:', res[i].pbe.Product2.Is_Kit__c, 'Stock:', res[i].stock)
                            if (res[i].stock == 0 && res[i].pbe.Product2.Allow_Back_Orders__c) res[i].stock = 'Back Order';
                            if (res[i].pbe.Product2.Is_Kit__c) res[i].stock = 'Kit';
                          //  res[i].checkSelected = false;
                        //   added by matheen on 10/9/25 for GIIH-1083
                           let alreadySelected = this.listOfCheckedProucts.find(
                                prod => prod.pbe.Product2.Id === res[i].pbe.Product2.Id
                            );
                            res[i].checkSelected = alreadySelected ? true : false;
                        }
                        this.listOfProducts = res;
                        this.currentFlow = 'addProducts';
                        console.log('this.listOfProducts:', this.listOfProducts);
                    } else
                        this.listOfProducts = undefined;

                    this.spinner = false;

                })
                .catch(error => {
                    console.log('Error of fetchProducts:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) {
            console.log('Error:', e);
        }
    }

    validateSelProd() {
        try {
            console.log('inside validateSelProd');
            let listOfProducts = this.listOfProducts;
            //let isValid = true;
            let count = 0;
            this.errorList = Object.assign([], this.errorList);
            this.errorList = undefined;
            for (let i in listOfProducts) {
                if (listOfProducts[i].checkSelected) {
                    count++;
                    if (!listOfProducts[i].pbe.Product2.Allow_Back_Orders__c && listOfProducts[i].stock == 0) {
                        console.log('listOfProducts[i].stock.',listOfProducts[i].stock);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Stock not available')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Stock not available');
                        return false;
                    }
                    if (listOfProducts[i].pbe.UnitPrice == '' || listOfProducts[i].pbe.UnitPrice == undefined || listOfProducts[i].pbe.UnitPrice < 0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty');

                        return false;
                    }
                    if (listOfProducts[i].quantity == '' || listOfProducts[i].quantity == undefined || listOfProducts[i].quantity == 0 || listOfProducts[i].quantity < 0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty');
                        //isValid = false;
                        return false;
                    }
                    console.log('1:', listOfProducts[i].discountPercent == '');
                    console.log('2', listOfProducts[i].discountPercent < 0);
                    console.log('2', parseFloat(listOfProducts[i].discountPercent) < 0);
                    if (typeof (listOfProducts[i].discountPercent) == 'string' || parseFloat(listOfProducts[i].discountPercent) < 0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty');
                        //isValid = false;
                        return false;
                    }
                    if (parseFloat(listOfProducts[i].discountPercent) > 100) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100');
                        //isValid = false;
                        return false;
                    }
                }
            }
            if (count == 0) {
                const event = new ShowToastEvent({
                    title: 'Warning!',
                    variant: 'warning',
                    message:
                        'Please select Item to add',
                });
                this.dispatchEvent(event);
            }
            return true;
            /*if (isValid)
                return true;
            else
                return false;*/
        } catch (e) {
            console.log('Error:', e);
        }
    }

    addProducts() {
        try {
            console.log('inside addProducts');
            console.log('searchItem:', this.searchItem);
            console.log('selectedProducts:', this.selectedProducts);
            console.log('validateSelProd():', this.validateSelProd());



            if (this.validateSelProd()) {
                //Creating a metadata Type of OrderProduct Object
                let selectedProducts = this.selectedProducts;
                let listOfProducts = this.listOfProducts;
                let listOfCheckedProucts1 = JSON.parse(JSON.stringify(this.listOfCheckedProucts));
                console.log('listOfCheckedProucts1 inside addProducts:', listOfCheckedProucts1);

                /*for (let i in listOfProducts) { if (listOfProducts[i].checkSelected) { //Calulate Discount and taxes var discount = 0; var vatAmount1 = 0; var otherTax1 = 0; if (listOfProducts[i].discountPercent != 0) { if (listOfProducts[i].isPercent) { discount = ((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) * parseFloat(listOfProducts[i].discountPercent)) / 100; } else { discount = parseFloat(listOfProducts[i].quantity) * parseFloat(listOfProducts[i].discountPercent); } } if (listOfProducts[i].tax.ERP7__Tax_Rate__c != undefined) vatAmount1 = (listOfProducts[i].tax.ERP7__Apply_Tax_On__c == 'Cost Price' && listOfProducts[i].pbe.ERP7__Purchase_Price__c != undefined) ? (parseFloat(listOfProducts[i].tax.ERP7__Tax_Rate__c) / 100 * (parseFloat(listOfProducts[i].pbe.ERP7__Purchase_Price__c))) : (parseFloat(listOfProducts[i].tax.ERP7__Tax_Rate__c) / 100 * ((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) - discount)); if (listOfProducts[i].tax.ERP7__Other_Tax_Rate__c != undefined) otherTax1 = (listOfProducts[i].tax.ERP7__Apply_Tax_On__c == 'Cost Price' && listOfProducts[i].pbe.ERP7__Purchase_Price__c != undefined) ? (parseFloat(listOfProducts[i].tax.ERP7__Other_Tax_Rate__c) / 100 * (parseFloat(listOfProducts[i].pbe.ERP7__Purchase_Price__c))) : (parseFloat(listOfProducts[i].tax.ERP7__Other_Tax_Rate__c) / 100 * ((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) - discount)); listOfProducts[i].vatAmount = vatAmount1;
                        listOfProducts[i].otherTax = otherTax1; listOfProducts[i].totalTaxAmount = vatAmount1 + otherTax1; listOfProducts[i].totalDiscount = discount; //Calculate NetAmount and GrossAmount if (listOfProducts[i].isPercent) { listOfProducts[i].NetAmount = ((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity) - (((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) * parseFloat(listOfProducts[i].discountPercent)) / 100))); listOfProducts[i].GrossAmount = ((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity) - (((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) * parseFloat(listOfProducts[i].discountPercent)) / 100) + (parseFloat(listOfProducts[i].vatAmount) + parseFloat(listOfProducts[i].otherTax)))); } else { listOfProducts[i].NetAmount = (((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) - (parseFloat(listOfProducts[i].quantity) * parseFloat(listOfProducts[i].discountPercent)))); listOfProducts[i].GrossAmount = (((parseFloat(listOfProducts[i].pbe.UnitPrice) * parseFloat(listOfProducts[i].quantity)) - (parseFloat(listOfProducts[i].quantity) * parseFloat(listOfProducts[i].discountPercent)) + (parseFloat(listOfProducts[i].vatAmount) + parseFloat(listOfProducts[i].otherTax)))); } selectedProducts.push(listOfProducts[i]); }
                }*/

                for (let i in listOfCheckedProucts1) {
                    if (listOfCheckedProucts1[i].checkSelected) {
                        //Calulate Discount and taxes
                        var discount = 0;
                        var vatAmount1 = 0;
                        var otherTax1 = 0;
                        if (listOfCheckedProucts1[i].discountPercent != 0) {
                            if (listOfCheckedProucts1[i].isPercent) {
                                discount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100;
                            } else {
                                discount = parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent);
                            }
                        }
                        if (listOfCheckedProucts1[i].tax.Tax_Rate__c != undefined) vatAmount1 = (listOfCheckedProucts1[i].tax.Apply_Tax_On__c == 'Cost Price' && listOfCheckedProucts1[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(listOfCheckedProucts1[i].tax.Tax_Rate__c) / 100 * (parseFloat(listOfCheckedProucts1[i].pbe.Purchase_Price__c))) : (parseFloat(listOfCheckedProucts1[i].tax.Tax_Rate__c) / 100 * ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - discount));
                        if (listOfCheckedProucts1[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (listOfCheckedProucts1[i].tax.Apply_Tax_On__c == 'Cost Price' && listOfCheckedProucts1[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(listOfCheckedProucts1[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(listOfCheckedProucts1[i].pbe.Purchase_Price__c))) : (parseFloat(listOfCheckedProucts1[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - discount));
                        listOfCheckedProucts1[i].vatAmount = vatAmount1;
                        listOfCheckedProucts1[i].otherTax = otherTax1;
                        listOfCheckedProucts1[i].totalTaxAmount = vatAmount1 + otherTax1;
                        listOfCheckedProucts1[i].totalDiscount = discount;


                        //Calculate NetAmount and GrossAmount
                        if (listOfCheckedProucts1[i].isPercent) {
                            listOfCheckedProucts1[i].NetAmount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity) - (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100)));
                            listOfCheckedProucts1[i].GrossAmount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity) - (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100) + (parseFloat(listOfCheckedProucts1[i].vatAmount) + parseFloat(listOfCheckedProucts1[i].otherTax))));
                        } else {
                            listOfCheckedProucts1[i].NetAmount = (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - (parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent))));
                            listOfCheckedProucts1[i].GrossAmount = (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - (parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent)) + (parseFloat(listOfCheckedProucts1[i].vatAmount) + parseFloat(listOfCheckedProucts1[i].otherTax))));
                        }

                        selectedProducts.push(listOfCheckedProucts1[i]);
                    }
                }



                this.CalculateOrderValues();
                this.selectedProducts = selectedProducts;




                /*if (this.selectedProducts)
                    this.selectedProducts.push(selectedProducts);
                else
                    this.selectedProducts = selectedProducts;*/
                console.log('this.selectedProducts: Addproducts', JSON.stringify(this.selectedProducts));
                //this.calculateTaxAndDisc();
                if (this.selectedProducts.length > 0)
                    this.currentFlow = 'mainPage';
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    selProdURL(event) {
        try {
            if (this.selectedProducts[event.currentTarget.dataset.index].Id)
                window.open('/' + this.selectedProducts[event.currentTarget.dataset.index].Id, '_blank');
            else
                window.open('/' + this.selectedProducts[event.currentTarget.dataset.index].pbe.Product2.Id, '_blank');
        } catch (e) {
            console.log('Error:', e);
        }
    }

    openDeleteModal(event) {
        try {
            if (!this.isOrderActivated) {
                this.indexToDel = event.currentTarget.dataset.index;
                this.deleteConfirmation = true;
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    closeDeleteModal() {
        try {
            this.deleteConfirmation = false;
            this.indexToDel = undefined;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    removeLineItem() {
        try {
            if (this.indexToDel) {
                if (this.selectedProducts[this.indexToDel].Id)
                    this.itemsToDel.push(this.selectedProducts[this.indexToDel].Id);
                this.selectedProducts.splice(this.indexToDel, 1);
            }
            this.CalculateOrderValues();
            this.indexToDel = undefined;
            this.deleteConfirmation = false;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    orderItemEditModal(event) {
        try {
            if (!this.isOrderActivated) {
                this.orderItemEditIndex = event.currentTarget.dataset.index;
                this.orderItemToEdit = JSON.parse(JSON.stringify(this.selectedProducts[this.orderItemEditIndex]));

                //get latest stock
                getlatestStock({
                    channelId: this.order.Order_Profile__r.Channel__c,
                    prodId: this.orderItemToEdit.pbe.Product2.Id,
                })
                    .then(result => {
                        console.log('getlatestStock:', result);
                        if (result > 0)
                            this.orderItemToEdit.stock = parseFloat(result);
                        console.log('this.orderItemToEdit.pbe.Product2.Is_Kit__c : ', this.orderItemToEdit.pbe.Product2.Is_Kit__c);
                        if (this.orderItemToEdit.pbe.Product2.Is_Kit__c == true) this.orderItemToEdit.stock = 'Kit';
                        else {
                            (this.orderItemToEdit.pbe.Product2.Allow_Back_Orders__c == true) ? 'Back Order' : parseFloat(result);
                        }
                        this.error = undefined;
                        this.isEditOrderItem = true;
                    })
                    .catch(error => {
                        console.log('Error of getlatestStock:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    closeEditModal() {
        try {
            this.orderItemEditIndex = undefined;
            this.orderItemToEdit = undefined;
            this.isEditOrderItem = false;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    updateOrderItem() {
        try {
            console.log('this.selectedProducts:', this.selectedProducts);
            console.log('this.orderItemToEdit:', this.orderItemToEdit);
            //Validate this.orderItemToEdit
            this.error = undefined;
            if (!this.orderItemToEdit.pbe.Product2.Allow_Back_Orders__c && this.orderItemToEdit.stock == 0) {
                this.error = this.orderItemToEdit.pbe.Product2.Name + ': Stock not available';
                return;
            }
            if (this.orderItemToEdit.pbe.UnitPrice == '' || this.orderItemToEdit.pbe.UnitPrice == undefined || this.orderItemToEdit.pbe.UnitPrice < 0) {
                this.error = this.orderItemToEdit.pbe.Product2.Name + ': Unit Price can not be negative or empty';
                return;
            }
            if (this.orderItemToEdit.quantity == '' || this.orderItemToEdit.quantity == undefined || this.orderItemToEdit.quantity == 0 || this.orderItemToEdit.quantity < 0) {
                this.error = this.orderItemToEdit.pbe.Product2.Name + ': Quantity can not be negative, zero or empty';
                return;
            }
            if (typeof (this.orderItemToEdit.discountPercent) == 'string' || parseFloat(this.orderItemToEdit.discountPercent) < 0) {
                this.error = this.orderItemToEdit.pbe.Product2.Name + ': Discount can not be negative or empty';
                return;
            }


            //calculate Discount and Taxes
            this.spinner = true;
            var discount = 0;
            var vatAmount1 = 0;
            var otherTax1 = 0;
            if (this.orderItemToEdit.discountPercent != 0) {
                if (this.orderItemToEdit.isPercent) {
                    discount = ((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) * parseFloat(this.orderItemToEdit.discountPercent)) / 100;
                } else {
                    discount = parseFloat(this.orderItemToEdit.quantity) * parseFloat(this.orderItemToEdit.discountPercent);
                }
            }
            if (this.orderItemToEdit.tax.Tax_Rate__c != undefined) vatAmount1 = (this.orderItemToEdit.tax.Apply_Tax_On__c == 'Cost Price' && this.orderItemToEdit.pbe.Purchase_Price__c != undefined) ? (parseFloat(this.orderItemToEdit.tax.Tax_Rate__c) / 100 * (parseFloat(this.orderItemToEdit.pbe.Purchase_Price__c))) : (parseFloat(this.orderItemToEdit.tax.Tax_Rate__c) / 100 * ((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) - parseFloat(discount)));
            if (this.orderItemToEdit.tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.orderItemToEdit.tax.Apply_Tax_On__c == 'Cost Price' && this.orderItemToEdit.pbe.Purchase_Price__c != undefined) ? (parseFloat(this.orderItemToEdit.tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.orderItemToEdit.pbe.Purchase_Price__c))) : (parseFloat(this.orderItemToEdit.tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) - parseFloat(discount)));
            this.orderItemToEdit.vatAmount = vatAmount1;
            this.orderItemToEdit.otherTax = otherTax1;
            this.orderItemToEdit.totalTaxAmount = vatAmount1 + otherTax1;
            this.orderItemToEdit.totalDiscount = discount;


            //Calculate NetAmount and GrossAmount
            if (this.orderItemToEdit.isPercent) {
                this.orderItemToEdit.NetAmount = ((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity) - (((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) * parseFloat(this.orderItemToEdit.discountPercent)) / 100)));
                this.orderItemToEdit.GrossAmount = ((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity) - (((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) * parseFloat(this.orderItemToEdit.discountPercent)) / 100) + (parseFloat(this.orderItemToEdit.vatAmount) + parseFloat(this.orderItemToEdit.otherTax))));
            } else {
                this.orderItemToEdit.NetAmount = (((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) - (parseFloat(this.orderItemToEdit.quantity) * parseFloat(this.orderItemToEdit.discountPercent))));
                this.orderItemToEdit.GrossAmount = (((parseFloat(this.orderItemToEdit.pbe.UnitPrice) * parseFloat(this.orderItemToEdit.quantity)) - (parseFloat(this.orderItemToEdit.quantity) * parseFloat(this.orderItemToEdit.discountPercent)) + (parseFloat(this.orderItemToEdit.vatAmount) + parseFloat(this.orderItemToEdit.otherTax))));
            }

            this.selectedProducts[this.orderItemEditIndex] = this.orderItemToEdit;

            this.CalculateOrderValues();

            this.orderItemEditIndex = undefined;
            this.orderItemToEdit = undefined;
            this.isEditOrderItem = false;
            this.spinner = false;
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    editURL() {
        try {
            window.open('/' + this.orderItemToEdit.pbe.Product2.Id, '_blank');
        } catch (e) {
            console.log('Error:', e);
        }
    }

    EditUnitPrice(event) {
        try {
            let value = event.currentTarget.value;
            this.orderItemToEdit.pbe.UnitPrice = (value != '') ? parseFloat(value) : '';
            if (this.orderItemToEdit.pbe.UnitPrice == '') this.orderItemToEdit.UnitPriceClass = 'hasError1 ';
            else this.orderItemToEdit.UnitPriceClass = '';
        } catch (e) {
            console.log('Error:', e);
        }
    }

    editQuantity(event) {
        try {
            this.spinner = true;
            let value = event.currentTarget.value;
            this.orderItemToEdit.quantity = (value != '') ? parseFloat(value) : '';
            if (this.orderItemToEdit.quantity == '') this.orderItemToEdit.quantityClass = 'hasError1 ';
            else this.orderItemToEdit.quantityClass = '';

            if (value && value != '') {
                getDiscountPlanupdated({
                    profileId: this.order.Order_Profile__c,
                    prodId: this.orderItemToEdit.pbe.Product2.Id,
                    quantity: this.orderItemToEdit.quantity
                })
                    .then(result => {
                        console.log('result of getDiscountPlanupdated:', result);
                        this.orderItemToEdit.CurrentDiscounts = result[0].CurrentDiscounts;
                        this.orderItemToEdit.discountPlan = result[0].discountPlan;
                        this.orderItemToEdit.disPlans = result[0].disPlans;
                        if(this.orderItemToEdit.discountPlan != null && this.orderItemToEdit.discountPlan != '--None--' && this.orderItemToEdit.discountPlan != undefined && this.orderItemToEdit.discountPlan != '') this.orderItemToEdit.discountPercent = result[0].discountPercent;
                        this.orderItemToEdit.maxDiscount = result[0].maxDiscount;
                        this.orderItemToEdit.minDiscount = result[0].minDiscount;
                        this.orderItemToEdit.tierDists = result[0].tierDists;
                        this.orderItemToEdit.isPercent = result[0].isPercent;
                        console.log('this.orderItemToEdit:', this.orderItemToEdit);
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error of getDiscountPlanupdated:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    editDiscPlan(event) {
        try {
            let discountPlan = event.detail.value;
            this.orderItemToEdit.discountPlan = discountPlan;
            this.spinner = true;
            if (discountPlan != '') {
                for (var j = 0; j < this.orderItemToEdit.disPlans.length; j++) {
                    if (discountPlan == this.orderItemToEdit.disPlans[j].Id) {
                        if (this.orderItemToEdit.disPlans[j].Default_Discount_Percentage__c != undefined) {
                            this.orderItemToEdit.isPercent = true;
                            if (this.orderItemToEdit.disPlans[j].Default_Discount_Percentage__c != undefined)
                                this.orderItemToEdit.discountPercent = this.orderItemToEdit.disPlans[j].Default_Discount_Percentage__c;
                            else
                                this.orderItemToEdit.discountPercent = 0;
                            if (this.orderItemToEdit.disPlans[j].Floor_Discount_Percentage__c != undefined)
                                this.orderItemToEdit.minDiscount = this.orderItemToEdit.disPlans[j].Floor_Discount_Percentage__c;
                            else
                                this.orderItemToEdit.minDiscount = 0;
                            if (this.orderItemToEdit.disPlans[j].Ceiling_Discount_Percentage__c != undefined)
                                this.orderItemToEdit.maxDiscount = this.orderItemToEdit.disPlans[j].Ceiling_Discount_Percentage__c;
                            else
                                this.orderItemToEdit.maxDiscount = 0;
                        } else {
                            this.orderItemToEdit.isPercent = false;
                            if (this.orderItemToEdit.disPlans[j].Default_Discount_Value__c != undefined)
                                this.orderItemToEdit.discountPercent = this.orderItemToEdit.disPlans[j].Default_Discount_Value__c;
                            else
                                this.orderItemToEdit.discountPercent = 0;
                            if (this.orderItemToEdit.disPlans[j].Floor_Discount_Value__c != undefined)
                                this.orderItemToEdit.minDiscount = this.orderItemToEdit.disPlans[j].Floor_Discount_Value__c;
                            else
                                this.orderItemToEdit.minDiscount = 0;
                            if (this.orderItemToEdit.disPlans[j].Ceiling_Discount_Value__c != undefined)
                                this.orderItemToEdit.maxDiscount = this.orderItemToEdit.disPlans[j].Ceiling_Discount_Value__c;
                            else
                                this.orderItemToEdit.maxDiscount = 0;
                        }
                        this.spinner = false;
                        return;
                    }
                }
            } else {
                this.orderItemToEdit.discountPlan = discountPlan;
                this.orderItemToEdit.isPercent = true;
                this.orderItemToEdit.discountPercent = 0;
                this.orderItemToEdit.minDiscount = 0;
                this.orderItemToEdit.maxDiscount = 0;
                this.spinner = false;
            }
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    editDiscount(event) {
        try {
            let discount = event.currentTarget.value;
            if (discount == '') this.orderItemToEdit.discountClass = 'hasError1';
            else this.orderItemToEdit.discountClass = '';
            if (discount && discount != '') {
                if (this.orderItemToEdit.maxDiscount != 0) {
                    if (discount > this.orderItemToEdit.maxDiscount) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes('Discount was larger than Max discount')) this.errorList.push('Discount was larger than Max discount');
                        for (var j = 0; j < this.orderItemToEdit.disPlans.length; j++) {
                            if (this.orderItemToEdit.isPercent) {
                                this.orderItemToEdit.discountPercent = this.orderItemToEdit.disPlans[j].Default_Discount_Percentage__c;
                                break;
                            }
                            else
                                this.orderItemToEdit.discountPercent = this.orderItemToEdit.disPlans[j].Default_Discount_Value__c;
                        }

                    } else {
                        this.orderItemToEdit.discountPercent = discount != '' ? parseFloat(discount) : '';
                    }
                } else {
                    this.orderItemToEdit.discountPercent = discount != '' ? parseFloat(discount) : '';
                }
            } else {
                this.orderItemToEdit.discountPercent = discount != '' ? parseFloat(discount) : '';
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    editDescription(event) {
        try {
            this.orderItemToEdit.pbe.Product2.Description = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDisAmt(event) {
        try {
            this.order.Order_Discount__c = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDistDesc(event) {
        try {
            this.order.Order_Discount_Description__c = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    get isOrderHasId() {
        //Validate for Invoice Availability
        if (this.order.Id) {
            if (this.order.Id != '') return true;
            else false;
        } else {
            return false;
        }
    }

    saveOrder() {
        try {
            console.log('order.Status:', this.order.Status);
            console.log('ordStatus:', this.ordStatus);

            this.errorList = Object.assign([], this.errorList);

            let isvalid = true;
            if (!this.order.Contact__c || this.order.Contact__c == '') {
                if (!this.errorList.includes('Conatct not found')) this.errorList.push('Conatct not found');
                isvalid = false;
            }
            if (!this.order.Bill_To_Address__c || this.order.Bill_To_Address__c == '') {
                if (!this.errorList.includes('Bill To Address not found')) this.errorList.push('Bill To Address not found');
                isvalid = false;
            }
            if (!this.order.Ship_To_Address__c || this.order.Ship_To_Address__c == '') {
                if (!this.errorList.includes('Ship To Address not found')) this.errorList.push('Ship To Address not found');
                isvalid = false;
            }
            if (!this.order.Order_Profile__c || this.order.Order_Profile__c == '') {
                if (!this.errorList.includes('Order Profile not found')) this.errorList.push('Order Profile not found');
                isvalid = false;
            }
            if (!this.order.Employee__c || this.order.Employee__c == '') {
                if (!this.errorList.includes('Employee not found')) this.errorList.push('Employee not found');
                isvalid = false;
            }
            if (!this.order.EffectiveDate || this.order.EffectiveDate == '') {
                if (!this.errorList.includes('Order start date not found')) this.errorList.push('Order start date not found');
                isvalid = false;
            }
            if (this.selectedProducts.length == 0) {
                const event = new ShowToastEvent({
                    title: 'Error!',
                    variant: 'error',
                    message: 'Line Item not found',
                });
                this.dispatchEvent(event);
                isvalid = false;
            }
            if (!isvalid) return;

            this.spinner = true;
            //Initialization of Order
            //this.order.Amount__c
            //this.order.Amount_Paid__c
            //this.order.Issue_Warranty__c
            //this.order.Coupon_Discount__c
            if (this.order.Id == '') delete this.order.Id;
            if (!this.isMultiCurrency) delete this.order.CurrencyIsoCode;
            this.order.Active__c = true;
            this.order.Customer_Email__c = this.order.Contact__r.Email;
            this.order.Stage__c = 'Entered';
            if (this.order.Employee__r.Employee_User__c) this.order.OwnerId = this.order.Employee__r.Employee_User__c;
            if (this.order.Account.Company__c) this.order.Company__c = this.order.Account.Company__c;
            if (this.order.Order_Profile__r.Price_Book__c) this.order.Pricebook2Id = this.order.Order_Profile__r.Price_Book__c;
            if (this.order.Order_Profile__r.Channel__c) this.order.Channel__c = this.order.Order_Profile__r.Channel__c;

            console.log('this.order:', JSON.stringify(this.order));

            //Initialization of orderItems
            let prodList = [];
            let selectedProducts = this.selectedProducts;
            let OrderItems = [];
            for (let i in selectedProducts) {
                let discount = 0;
                OrderItems[i] = {};
                if (selectedProducts[i].Id) OrderItems[i].Id = selectedProducts[i].Id;
                OrderItems[i].Active__c = true;
                OrderItems[i].Allocate_Stock__c = true;
                if (!selectedProducts[i].pbe.Product2.Is_Kit__c) OrderItems[i].Inventory_Tracked__c = true;
                if (selectedProducts[i].isPercent) {
                    OrderItems[i].Discount_Percent__c = selectedProducts[i].discountPercent;
                    discount = (((selectedProducts[i].pbe.UnitPrice * selectedProducts[i].quantity) * selectedProducts[i].discountPercent) / 100);
                    OrderItems[i].Discount_Amount__c = discount;
                } else {
                    discount = selectedProducts[i].quantity * selectedProducts[i].discountPercent;
                    OrderItems[i].Discount_Amount__c = discount;
                    let total = selectedProducts[i].pbe.UnitPrice * selectedProducts[i].quantity;
                    let per = (discount / total) * 100;
                    OrderItems[i].Discount_Percent__c = per;
                }
                if (selectedProducts[i].discountPlan != '') {
                    OrderItems[i].Discount_Plan__c = selectedProducts[i].discountPlan;
                    /*OrderItems[i].Discount_Plan__r = {};
                    OrderItems[i].Discount_Plan__r.Id = selectedProducts[i].discountPlan;
                    let CurrentDiscounts = selectedProducts[i].CurrentDiscounts;
                    for (let j in CurrentDiscounts) {
                        //console.log('inside 2:',JSON.stringify(CurrentDiscounts[j]));
                        if (CurrentDiscounts[j].value == selectedProducts[i].discountPlan)
                            OrderItems[i].Discount_Plan__r.Name = CurrentDiscounts[j].label;
                    }*/
                }
                OrderItems[i].Product2Id = selectedProducts[i].pbe.Product2Id;
                prodList.push(selectedProducts[i].pbe.Product2Id);
                /*OrderItems[i].Product2 = {};
                OrderItems[i].Product2.Id = selectedProducts[i].pbe.Product2Id;
                OrderItems[i].Product2.Name = selectedProducts[i].pbe.Product2.Name;
                OrderItems[i].Product2.ProductCode = selectedProducts[i].pbe.Product2.ProductCode;
                OrderItems[i].Product2.QuantityUnitOfMeasure = selectedProducts[i].pbe.Product2.QuantityUnitOfMeasure;
                OrderItems[i].Product2.Picture__c = selectedProducts[i].pbe.Product2.Picture__c;
                OrderItems[i].Product2.Allow_Back_Orders__c = selectedProducts[i].pbe.Product2.Allow_Back_Orders__c;*/

                if (selectedProducts[i].version != '') OrderItems[i].BOM__c = selectedProducts[i].version;
                OrderItems[i].Quantity = selectedProducts[i].quantity;
                OrderItems[i].Sort_Order__c = parseInt(i);
                if (selectedProducts[i].tax.Id) OrderItems[i].Tax__c = selectedProducts[i].tax.Id
                OrderItems[i].VAT_Amount__c = selectedProducts[i].vatAmount;
                OrderItems[i].Other_Tax__c = selectedProducts[i].otherTax
                OrderItems[i].Total_Price__c = parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity) - parseFloat(discount) + parseFloat(selectedProducts[i].vatAmount) + parseFloat(selectedProducts[i].otherTax);
                OrderItems[i].UnitPrice = selectedProducts[i].pbe.UnitPrice
                OrderItems[i].Description = selectedProducts[i].pbe.Product2.Description;
                OrderItems[i].Company__c = this.order.Company__c;
                OrderItems[i].ServiceDate = this.order.EffectiveDate;
            }

            console.log('OrderItems :', OrderItems);

            saveOrderAndLine({
                ord: JSON.stringify(this.order),
                ordItems: JSON.stringify(OrderItems),
                prodList: JSON.stringify(prodList),
                itemsToDel: this.itemsToDel,
            })
                .then(result => {
                    console.log('result saveOrderAndLine:', result);
                    this.errorList = result.error;
                    /*this.order = result.ord;
                    if (this.order.Id) this.ordStatus = this.ordStatusData;
                    this.evaluateOrder();                
                    this.selectedProducts = this.convertOrdItemsToSelProds(result.ordItems);*/
                    this.fetchOrdDetailsHelper(result.ord.Id);


                    console.log('this.selectedProducts:', this.selectedProducts);
                    this.spinner = false;
                    this.isOrderSelected = true;
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) {
            console.log('Error:', e);
        }
    }


    RefreshOrder() {
        try {
            console.log('RefreshOrder Called ==>');
            //this.spinner = true;
            this.fetchOrdDetailsHelper(this.order.Id);
            //this.spinner = false;
        } catch (e) {
            console.log('Error:', e);
        }
    }


    openCloneConfirmation() {
        this.isCloneConfirmation = true;
    }
    closeCloneConfirmation() {
        this.isCloneConfirmation = false;
    }

    cloneOrder() {
        try {
            //eval("$A.get('e.force:refreshView').fire();");

            this.spinner = true;
            console.log('this.order.Id:', this.order.Id);
            fetchOrdDetailsForClone({
                OrderId: this.order.Id,
            })
                .then(result => {
                    console.log('result:', result);
                    this.couponRemList = [];
                    this.shipmentsList = [];
                    this.invoiceList = [];
                    this.paymentList = [];
                    this.iscouponRemList = this.couponRemList.length > 0 ? true : false;
                    this.isShipmentsList = this.shipmentsList.length > 0 ? true : false;
                    this.isInvoiceList = result.invoiceList.length > 0 ? true : false;
                    this.isPaymentList = result.paymentList.length > 0 ? true : false;
                    this.orderCurrency = result.orderCurrency;
                    this.allCurrencies = result.allCurrencies;
                    this.isMultiCurrency = result.isMultiCurrency;

                    this.order = JSON.parse(JSON.stringify(result.ord));
                    this.order.Id = '';
                    this.order.Name = '';
                    this.order.Status = 'Draft';
                    this.order.Due_Amount__c = this.Order_Amount__c;
                    this.order.Order_Discount__c = 0;
                    this.order.Order_Discount_Description__c = '';
                    this.order.Issue_Invoice__c = false;
                    this.order.Is_Closed__c = false;

                    this.order.CurrencyIsoCode = result.orderCurrency;
                    this.ordStatus = [{ label: this.ordStatusData[0].label, value: this.ordStatusData[0].value }];
                    if (this.order.Bill_To_Address__c) this.billToAddFull = this.addressGenerator(this.order.Bill_To_Address__r);
                    if (this.order.Ship_To_Address__c) this.shipToAddFull = this.addressGenerator(this.order.Ship_To_Address__r);

                    //this.evaluateOrder();
                    //Initial values
                    if (!this.order.Contact__c)
                        this.order.Contact__r = { Id: '', Name: '' };
                    if (!this.order.Bill_To_Address__c)
                        this.order.Bill_To_Address__r = { Id: '', Name: '' };
                    if (!this.order.Ship_To_Address__c)
                        this.order.Ship_To_Address__r = { Id: '', Name: '' };
                    if (!this.order.Order_Profile__c)
                        this.order.Order_Profile__r = { Id: '', Name: '' };
                    if (!this.order.Employee__c)
                        this.order.Employee__r = { Id: '', Name: '' };
                    if (!this.order.Project__c)
                        this.order.Project__r = { Id: '', Name: '' };
                    if (!this.order.Company__c)
                        this.order.Company__r = { Id: '', Name: '' };
                    if (!this.order.Account.Account_Profile__c)
                        this.order.Account.Account_Profile__r = { Id: '', Name: '' };

                    //set Filter
                    this.contactFilter = "AccountId='" + this.order.AccountId + "'";
                    this.billToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Billing_Address__c=true AND Active__c=true";
                    this.shipToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Shipping_Address__c=true AND Active__c=true";
                    this.OrderFilter = "AccountId='" + this.order.AccountId + "'";
                    if (this.order.Account.Account_Profile__c)
                        this.OrderProfileFilter = "Account_Profile__c = '" + this.order.Account.Account_Profile__c + "' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                    else {
                        this.OrderProfileFilter = "Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                    }

                    //Set values
                    if (!this.order.Order_Amount__c) this.order.Order_Amount__c = 0;
                    this.order.Amount_Paid__c = 0;
                    if (!this.order.Due_Amount__c) this.order.Due_Amount__c = 0;
                    if (!this.order.Account.Available_Credit_Balance__c) this.order.Account.Available_Credit_Balance__c = 0;

                    //Set Status
                    //if (this.order.Id) this.ordStatus = this.ordStatusData;
                    console.log('this.order:', this.order);
                    this.isCloningOrder = true;
                    this.isCloneConfirmation = false;
                    this.selectedProducts = this.convertOrdItemsToSelProds(result.ordItems);
                    const event = new ShowToastEvent({
                        variant: 'success',
                        message: 'Cloned Successfully, Save to create Order',
                    });
                    this.dispatchEvent(event);
                    this.spinner = false;
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) { console.log('Error:', e); }
    }

    handlecouponCode(event) {
        try {
            this.couponCode = event.detail.value;
            if(this.order.Id == undefined || this.order.Id == null || this.order.Id == ''){
                this.disableApply = true;
                this.couponCode = '';
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes('Order is not created')) this.errorList.push('Order is not created');
            }
            else if (this.couponCode && this.couponCode != '') 
                this.disableApply = false;
            else
                this.disableApply = true;

            if (this.couponRemList.length > 0) {
                this.disableApply = true;
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes('Already redeemed one coupon')) this.errorList.push('Already redeemed one coupon');
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }
    ApplyCoupon() {
        try {
            this.spinner = true;
            if (this.couponCode && this.couponCode != '') {
                if (!this.isMultiCurrency) delete this.order.CurrencyIsoCode;
                getApplyCoupons({
                    ord: JSON.stringify(this.order),
                    custId: this.order.AccountId,
                    Coupon: this.couponCode,
                })
                    .then(result => {
                        console.log('result:', result);
                        if (result.includes('Coupon Redeemed Successfully')) {
                            const event = new ShowToastEvent({
                                variant: 'success',
                                message: result,
                            });
                            this.dispatchEvent(event);
                            this.fetchOrdDetailsHelper(this.order.Id);
                        } else {
                            this.errorList = Object.assign([], this.errorList);
                            if (!this.errorList.includes(result)) this.errorList.push(result);
                        }
                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            } else {
                this.spinner = false;
                this.disableApply = true;
                this.errorList = Object.assign([], this.errorList);
                if (!this.errorList.includes('Please enter coupon code')) this.errorList.push('Please enter coupon code');
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }






    //***************Helpers********************

    fetchOrdDetailsHelper(ordId) {
        try {
            refreshApex(this.invoiceList);
            refreshApex(this.paymentList);
            this.spinner = true;
            getOrderDetails({
                OrderId: ordId,
            })
                .then(result => {
                    console.log('result of getOrderDetails:', result);
                    this.orderCurrency = result.orderCurrency;
                    this.allCurrencies = result.allCurrencies;
                    this.isMultiCurrency = result.isMultiCurrency;

                    this.couponRemList = JSON.parse(JSON.stringify(result.CRList));
                    for (let i in this.couponRemList) {
                        this.couponRemList[i].nameUrl = '/' + this.couponRemList[i].Id;
                        this.couponRemList[i].Coupon__r.CPUrl = '/' + this.couponRemList[i].Coupon__r.Id;
                    }
                    this.iscouponRemList = this.couponRemList.length > 0 ? true : false;

                    this.shipmentsList = JSON.parse(JSON.stringify(result.shipments));
                    for (let i in this.shipmentsList) {
                        this.shipmentsList[i].nameUrl = '/' + this.shipmentsList[i].Id;
                        if (this.shipmentsList[i].RecordType.Name == 'Internal Shipping')
                            this.shipmentsList[i].shipmentType = 'Internal';
                        if (this.shipmentsList[i].RecordType.Name == 'UPS Shipping')
                            this.shipmentsList[i].shipmentType = 'UPS';
                        if (this.shipmentsList[i].RecordType.Name == 'Fedex Shipping')
                            this.shipmentsList[i].shipmentType = 'Fedex';
                        if (this.shipmentsList[i].RecordType.Name == 'DHL Shipping')
                            this.shipmentsList[i].shipmentType = 'DHL';

                    }

                    this.isShipmentsList = this.shipmentsList.length > 0 ? true : false;


                    this.invoiceList = JSON.parse(JSON.stringify(result.invoiceList));
                    for (let i in this.invoiceList) {
                        if (!this.invoiceList[i].Credit_Note__c) this.invoiceList[i].Credit_Note__c = 0;
                        this.invoiceList[i].invoiceurl = '/' + this.invoiceList[i].Id;
                        if (this.invoiceList[i].Posted__c) {
                            this.invoiceList[i].isPosted = 'Yes';
                            this.invoiceList[i].postLable = 'Unpost';
                            this.invoiceList[i].isPostedClass = 'bgGreen';
                        }
                        else {
                            this.invoiceList[i].isPosted = 'No';
                            this.invoiceList[i].postLable = 'Post';
                            this.invoiceList[i].isPostedClass = 'bgRed';
                        }
                        if (this.invoiceList[i].RecordType.DeveloperName == 'Advance')
                            this.invoiceList[i].isAdvance = true;
                        else
                            this.invoiceList[i].isAdvance = false;
                    }
                    this.isInvoiceList = result.invoiceList.length > 0 ? true : false;

                    this.paymentList = JSON.parse(JSON.stringify(result.paymentList));
                    for (let i in this.paymentList)
                        this.paymentList[i].paymenturl = '/' + this.paymentList[i].Id;
                    this.isPaymentList = result.paymentList.length > 0 ? true : false;

                    this.order = JSON.parse(JSON.stringify(result.ord));
                    this.order.CurrencyIsoCode = result.orderCurrency;
                    if (this.order.Id) this.ordStatus = this.ordStatusData;
                    if (this.order.Bill_To_Address__c) this.billToAddFull = this.addressGenerator(this.order.Bill_To_Address__r);
                    if (this.order.Ship_To_Address__c) this.shipToAddFull = this.addressGenerator(this.order.Ship_To_Address__r);

                    if (this.order.AccountId) { this.GetAccountId = this.order.AccountId; this.accountname = this.order.Account.Name; }
                    if (this.order.Contact__c) { this.GetContactId = this.order.Contact__c; this.contactname = this.order.Contact__r.Name; }

                    //this.evaluateOrder();
                    //Initial values
                    if (!this.order.Contact__c)
                        this.order.Contact__r = { Id: '', Name: '' };
                    if (!this.order.Bill_To_Address__c)
                        this.order.Bill_To_Address__r = { Id: '', Name: '' };
                    if (!this.order.Ship_To_Address__c)
                        this.order.Ship_To_Address__r = { Id: '', Name: '' };
                    if (!this.order.Order_Profile__c)
                        this.order.Order_Profile__r = { Id: '', Name: '' };
                    if (!this.order.Employee__c)
                        this.order.Employee__r = { Id: '', Name: '' };
                    if (!this.order.Project__c)
                        this.order.Project__r = { Id: '', Name: '' };
                    if (!this.order.Company__c)
                        this.order.Company__r = { Id: '', Name: '' };
                    if (!this.order.Account.Account_Profile__c)
                        this.order.Account.Account_Profile__r = { Id: '', Name: '' };

                    //set Filter
                    this.contactFilter = "AccountId='" + this.order.AccountId + "'";
                    this.billToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Billing_Address__c=true AND Active__c=true";
                    this.shipToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Shipping_Address__c=true AND Active__c=true";
                    this.OrderFilter = "AccountId='" + this.order.AccountId + "'";
                    if (this.order.Account.Account_Profile__c)
                        this.OrderProfileFilter = "Account_Profile__c = '" + this.order.Account.Account_Profile__c + "' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                    else {
                        this.OrderProfileFilter = "Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
                    }

                    //Set values
                    if (!this.order.Order_Amount__c) this.order.Order_Amount__c = 0;
                    if (!this.order.Amount_Paid__c) this.order.Amount_Paid__c = 0;
                    if (!this.order.Due_Amount__c) this.order.Due_Amount__c = 0;
                    if (!this.order.Account.Available_Credit_Balance__c) this.order.Account.Available_Credit_Balance__c = 0;

                    //Set Status
                    if (this.order.Id) this.ordStatus = this.ordStatusData;
                    console.log('this.order:', this.order);

                    this.selectedProducts = this.convertOrdItemsToSelProds(result.ordItems);
                    this.spinner = false;
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) {
            console.log('Error:', e);
        }
    }

    /*evaluateOrder() {
        //Initial values
        if (!this.order.Contact__c)
            this.order.Contact__r = { Id: '', Name: '' };
        if (!this.order.Bill_To_Address__c)
            this.order.Bill_To_Address__r = { Id: '', Name: '' };
        if (!this.order.Ship_To_Address__c)
            this.order.Ship_To_Address__r = { Id: '', Name: '' };
        if (!this.order.Order_Profile__c)
            this.order.Order_Profile__r = { Id: '', Name: '' };
        if (!this.order.Employee__c)
            this.order.Employee__r = { Id: '', Name: '' };
        if (!this.order.Project__c)
            this.order.Project__r = { Id: '', Name: '' };

        //set Filter
        this.contactFilter = "AccountId='" + this.order.AccountId + "'";
        this.billToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Billing_Address__c=true AND Active__c=true";
        this.shipToFilter = "Customer__c='" + this.order.AccountId + "' AND Is_Shipping_Address__c=true AND Active__c=true";
        this.OrderFilter = "AccountId='" + this.order.AccountId + "'";
        if (this.order.Account.Account_Profile__c)
            this.OrderProfileFilter = "Account_Profile__c = '" + this.order.Account.Account_Profile__c + "' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
        else {
            this.OrderProfileFilter = "Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED order by Default__c DESC";
        }

        //Set values
        if (!this.order.Order_Amount__c) this.order.Order_Amount__c = 0;
        if (!this.order.Amount_Paid__c) this.order.Amount_Paid__c = 0;
        if (!this.order.Due_Amount__c) this.order.Due_Amount__c = 0;
        if (!this.order.Account.Available_Credit_Balance__c) this.order.Account.Available_Credit_Balance__c = 0;

        console.log('this.order:', this.order);
    }*/

    convertOrdItemsToSelProds(ordItems) {
        try {
            let selectedProducts = [];
            for (let i in ordItems) {
                selectedProducts[i] = {};
                selectedProducts[i].keyId = ordItems[i].Product2Id + i;
                selectedProducts[i].checkSelected = true;

                if (!this.isCloningOrder) {
                    if (ordItems[i].Id) selectedProducts[i].Id = ordItems[i].Id;
                }


                //Setup pbe
                selectedProducts[i].pbe = {};
                selectedProducts[i].pbe.Product2 = ordItems[i].Product2;
                selectedProducts[i].pbe.Product2Id = ordItems[i].Product2Id;
                selectedProducts[i].pbe.UnitPrice = ordItems[i].UnitPrice;
                selectedProducts[i].pbe.Product2.Is_Kit__c = ordItems[i].Product2.Is_Kit__c;
                if (ordItems[i].BOM__c) selectedProducts[i].version = ordItems[i].BOM__c;
                else selectedProducts[i].version = '';
                selectedProducts[i].quantity = ordItems[i].Quantity;
                selectedProducts[i].stock = 0;

                //If Discount_Plan__c is not available
                selectedProducts[i].isPercent = true;
                selectedProducts[i].minDiscount = 0;
                selectedProducts[i].maxDiscount = 0;
                if (ordItems[i].Discount_Percent__c) selectedProducts[i].discountPercent = ordItems[i].Discount_Percent__c;
                else selectedProducts[i].discountPercent = 0;
                if (ordItems[i].Discount_Amount__c) selectedProducts[i].totalDiscount = ordItems[i].Discount_Amount__c;
                else selectedProducts[i].totalDiscount = 0;

                //Setup Discount Plan
                if (ordItems[i].Discount_Plan__c) {
                    //For latest and all Discount_Plan__c, make a server call here
                    selectedProducts[i].CurrentDiscounts = [{ label: '--None--', value: '' }, { label: ordItems[i].Discount_Plan__r.Name, value: ordItems[i].Discount_Plan__r.Id }];
                    selectedProducts[i].disPlans = [];
                    selectedProducts[i].disPlans.push(ordItems[i].Discount_Plan__r);

                    selectedProducts[i].discountPlan = ordItems[i].Discount_Plan__c;
                    if (ordItems[i].Discount_Plan__r.Default_Discount_Percentage__c) {
                        selectedProducts[i].isPercent = true;
                        selectedProducts[i].minDiscount = ordItems[i].Discount_Plan__r.Floor_Discount_Percentage__c;
                        selectedProducts[i].maxDiscount = ordItems[i].Discount_Plan__r.Ceiling_Discount_Percentage__c;
                        selectedProducts[i].discountPercent = ordItems[i].Discount_Percent__c;
                        selectedProducts[i].totalDiscount = ordItems[i].Discount_Amount__c;
                    } else if (ordItems[i].Discount_Plan__r.Default_Discount_Value__c) {
                        selectedProducts[i].isPercent = false;
                        selectedProducts[i].minDiscount = ordItems[i].Discount_Plan__r.Floor_Discount_Value__c;
                        selectedProducts[i].maxDiscount = ordItems[i].Discount_Plan__r.Ceiling_Discount_Value__c;
                        selectedProducts[i].discountPercent = ordItems[i].Discount_Amount__c;
                        selectedProducts[i].totalDiscount = ordItems[i].Discount_Amount__c;
                    } else {
                        selectedProducts[i].discountPlan = '';
                        selectedProducts[i].minDiscount = 0;
                        selectedProducts[i].maxDiscount = 0;
                        selectedProducts[i].discountPercent = 0;
                        selectedProducts[i].totalDiscount = 0;
                    }
                }
                else {
                    selectedProducts[i].discountPlan = '';
                    selectedProducts[i].CurrentDiscounts = [{ label: '--None--', value: '' }];
                    selectedProducts[i].isPercent = true;
                }
                /*            
                CurrentDiscounts=new List<SelectOptions>();            
                disPlans=new List<Discount_Plan__c>();
                tierDists= new List<Tier_Discount_Allocation__c>();            
                */

                //If Tax__c is not available
                if (ordItems[i].VAT_Amount__c) selectedProducts[i].vatAmount = ordItems[i].VAT_Amount__c;
                else selectedProducts[i].vatAmount = 0;
                if (ordItems[i].Other_Tax__c) selectedProducts[i].otherTax = ordItems[i].Other_Tax__c;
                else selectedProducts[i].otherTax = 0;
                //Setup Tax
                if (ordItems[i].Tax__c) {
                    selectedProducts[i].tax = ordItems[i].Tax__r;
                    selectedProducts[i].vatAmount = ordItems[i].VAT_Amount__c;
                    selectedProducts[i].otherTax = ordItems[i].Other_Tax__c;
                } else {
                    selectedProducts[i].tax = {};
                }
                selectedProducts[i].totalTaxAmount = parseFloat(selectedProducts[i].vatAmount) + parseFloat(selectedProducts[i].otherTax);
                console.log('ordItems[i].Id:', ordItems[i].Id);

                //Calculate NetAmount and GrossAmount
                if (selectedProducts[i].isPercent) {
                    selectedProducts[i].NetAmount = ((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity) - (((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity)) * parseFloat(selectedProducts[i].discountPercent)) / 100)));
                    selectedProducts[i].GrossAmount = ((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity) - (((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity)) * parseFloat(selectedProducts[i].discountPercent)) / 100) + (parseFloat(selectedProducts[i].vatAmount) + parseFloat(selectedProducts[i].otherTax))));
                } else {
                    selectedProducts[i].NetAmount = (((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity)) - (parseFloat(selectedProducts[i].quantity) * parseFloat(selectedProducts[i].discountPercent))));
                    selectedProducts[i].GrossAmount = (((parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity)) - (parseFloat(selectedProducts[i].quantity) * parseFloat(selectedProducts[i].discountPercent)) + (parseFloat(selectedProducts[i].vatAmount) + parseFloat(selectedProducts[i].otherTax))));
                }

            }
            return selectedProducts;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    addressGenerator(address) {
        try {
            let fullAddress;
            if (address.Address_Line1__c) fullAddress = address.Address_Line1__c;
            if (address.Address_Line2__c) fullAddress += ', ' + address.Address_Line2__c;
            if (address.Address_Line3__c) fullAddress += ', ' + address.Address_Line3__c;
            if (address.City__c) fullAddress += ', ' + address.City__c;
            if (address.State__c) fullAddress += ', ' + address.State__c;
            if (address.Postal_Code__c) fullAddress += ', ' + address.Postal_Code__c;
            if (address.Country__c) fullAddress += ', ' + address.Country__c + '.';
            return fullAddress;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    connectedCallback() {
        try {
            console.log('inside connectedCallback');
            //initialize initial order lookups values
            this.order.Account = { Id: '', Name: '' };
            this.order.Account.Account_Profile__r = { Id: '', Name: '' };
            this.order.Contact__r = { Id: '', Name: '' };
            this.order.Bill_To_Address__r = { Id: '', Name: '' };
            this.order.Ship_To_Address__r = { Id: '', Name: '' };
            this.order.Order_Profile__r = { Id: '', Name: '' };
            this.order.Employee__r = { Id: '', Name: '' };
            this.order.Project__r = { Id: '', Name: '' };
            this.order.Company__r = { Id: '', Name: '' };


            getInitialData()
                .then(result => {
                    console.log('initial result:', result);
                    this.errorList = result.error;
                    this.order.EffectiveDate = result.todayDate;
                    this.ordStatusData = result.ordStatus;
                    if (this.order.Id) this.ordStatus = this.ordStatusData;
                    else this.ordStatus = [{ label: this.ordStatusData[0].label, value: this.ordStatusData[0].value }];
                    //if (this.order.Id) this.ordStatus = result.ordStatus;
                    //else this.ordStatus = [{ label: result.ordStatus[0].label, value: result.ordStatus[0].value }];
                    this.shipmentType = result.ShipmentType;
                    this.order.Employee__c = result.currEmp.Id;
                    this.order.Employee__r = result.currEmp;
                    console.log('order:', this.order);
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })
        } catch (e) {
            console.log('Error:', e);
        }
    }

    CalculateOrderValues() {
        try {
            console.log('Inside the CalculateOrderValues ::');
            var SubTotal = 0;
            var TotalDue = 0;
            var TotalDiscount1 = 0;
            var TotalTaxAmount1 = 0;
            var OrderAmount = 0;
            for (var i in this.selectedProducts) {

                SubTotal = SubTotal + (parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity));
                TotalDue = TotalDue + (parseFloat(this.selectedProducts[i].GrossAmount));
                TotalDiscount1 = TotalDiscount1 + this.selectedProducts[i].totalDiscount;
                TotalTaxAmount1 = TotalTaxAmount1 + this.selectedProducts[i].totalTaxAmount;
                OrderAmount = OrderAmount + this.selectedProducts[i].GrossAmount;
            }
            if (!this.order.Amount_Paid__c) this.order.Amount_Paid__c = 0;
            if (!this.order.Total_Shipping_Amount__c) this.order.Total_Shipping_Amount__c = 0;
            if (!this.order.Shipping_Discount__c) this.order.Shipping_Discount__c = 0;

            this.order.Sub_Total__c = SubTotal;
            this.order.Due_Amount__c = TotalDue - this.order.Amount_Paid__c + this.order.Total_Shipping_Amount__c - this.order.Shipping_Discount__c;
            this.order.TotalDiscount__c = TotalDiscount1;
            this.order.Total_Tax_Amount__c = TotalTaxAmount1;
            this.order.Order_Amount__c = OrderAmount + this.order.Total_Shipping_Amount__c - this.order.Shipping_Discount__c;



        }
        catch (e) {
            console.log('Error:', e);
        }
    }


    renderedCallback() {
        try {
            console.log('inside renderedCallback');
            console.log('renderedCallback his.order:', JSON.stringify(this.order));

            if (this.order.AccountId && this.order.Order_Profile__c && this.order.Order_Profile__r.Channel__c && this.order.Order_Profile__r.Price_Book__c && this.order.Bill_To_Address__c && this.order.Ship_To_Address__c)
                this.showAddButton = true;
						else this.showAddButton = false;
						
						if (this.order && this.order.Account && this.order.Account.Company__c && this.order.Account.Company__r.name) {
								console.log('here: '+ this.order.Account);
								this.companyName = this.order.Account.Company__r.name;
								console.log('companyName: '+ this.companyName);
						} else {
								console.log('no company:');
								// Handle undefined by setting a default name
								this.companyName = 'No Company';
						}
            console.log('renderedCallback this.showAddButton 1 :', this.showAddButton);

            if (this.order.AccountId && this.order.Contact__c && this.order.Bill_To_Address__c && this.order.Ship_To_Address__c && this.order.Order_Profile__c && this.order.Employee__c && this.selectedProducts)
                this.showSaveButton = false;
           // else this.showSaveButton = true; // commented by matheen on 8/5/25

            console.log('renderedCallback this.showAddButton 2 :', this.showAddButton);

            Promise.all([
                loadStyle(this, BaseStaticResource + '/CMP_CSS/CSS/global-axolt.css'),
                loadStyle(this, BaseStaticResource + '/PickPackShipResource/assets/styles/erp_mark7_bootstrap.css'),
                loadStyle(this, BaseStaticResource + '/bootStrap/css/bootstrap-4.1.css'),
                loadStyle(this, BaseStaticResource + '/SLDS/assets/styles/salesforce-lightning-design-system.css'),
                loadStyle(this, BaseStaticResource + '/ProjectWorkbench/css/main-style.css'),
                loadStyle(this, BaseStaticResource + '/fontawesome5/fontawesome5/css/all.css'),
                loadStyle(this, BaseStaticResource + '/eposcustom/assets/css/app.min.css'),
                loadStyle(this, BaseStaticResource + '/eposcustom/assets/css/bootstrap.min.css'),
                loadStyle(this, BaseStaticResource + '/eposcustom/assets/css/icons.min.css'),
                loadStyle(this, BaseStaticResource + '/eposcustom/assets/css/icons.css'),
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
    get billToqry() {
        if (this.order && this.order.Customer__c && this.order.Customer__c.Id) {
            console.log('Customer__c Id:', this.order.Customer__c.Id);  // Debug the Id
            return `AND Customer__c = '${this.order.Customer__c.Id}'`;  // Filter by the correct lookup field
        }
        return '';
    }
}