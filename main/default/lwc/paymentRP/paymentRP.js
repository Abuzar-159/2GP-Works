import { LightningElement, api, track } from 'lwc';
import getOrderDetails from '@salesforce/apex/Epos.fetchOrderDetails';
import upsertInvoice from '@salesforce/apex/Epos.updateInvoice';
import getInitailCardDetails from '@salesforce/apex/Epos.fetchInitialCardDetails';
import bankOrCashPayment from '@salesforce/apex/Epos.createBankOrCashPaymentV2';
import getInitialBankDetails from '@salesforce/apex/Epos.fetchInitialBankDetails';

import cardPayment from '@salesforce/apex/Epos.createCardPaymentV2';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PaymentRP extends LightningElement {

    @api recordId;

    orderFilter = '';

    @track selectedOrderId = null;
    @track selectedOrderName = '';
    @track selectedOrderUrl = '';
    @track isOrderSelected = false;
@track invoiceToPay = [];
@track paymentToUpsert = { Total_Amount__c: 0 };
@track paymentAmount = 0;
@track paymentGateway;
@track selectedGateway ='';
paymentError = '';
selectedGateway = '';
paymentBillAdd = {};
CardTypes = {};
ExpiryMonth='';
ExpiryYear = '';
CountryList={};
CVV = '';
@track PaymentMethod = {};
@track accountTypeOptions = {};
    @track orderDetails = null;

    isLoading = false;
    errorMessage = '';

    activePaymentMethod = 'card';

  renderedCallback() {
    console.log('in render  ');
    if (!this.orderFilter && this.recordId) {
        this.orderFilter = `AccountId='${this.recordId}'`;
        console.log('Order filter set:', this.orderFilter);
    }
}


    handleOrderSelect(event) {
        const rec = event.detail;
        this.selectedOrderId = rec.Id;
        this.selectedOrderName = rec.Name;
        this.selectedOrderUrl = '/' + rec.Id;
        this.isOrderSelected = true;

        this.loadOrderDetails();
    }

    handleOrderRemove() {
        this.selectedOrderId = null;
        this.selectedOrderName = '';
        this.selectedOrderUrl = '';
        this.isOrderSelected = false;
        this.orderDetails = null;
    }

  loadOrderDetails() {
    this.isLoading = true;
    this.errorMessage = '';
    console.log('calling getOrderDetails ');
    getOrderDetails({ OrderId: this.selectedOrderId })
    .then(result => {
        this.orderDetails = result;
        console.log('orderDetails =>',JSON.stringify(this.orderDetails));
        // RESET PAYMENT STATE
        this.paymentToUpsert = { Total_Amount__c: 0 };
        this.paymentError = '';
        this.selectedGateway = '';
        this.invoiceToPay = [];

        let idx = 0;

        result.invoiceList.forEach(inv => {
            if (inv.Total_Due__c > 0) {
                this.invoiceToPay.push({
                    ...inv,
                    trKey: inv.Id + idx,
                    checked: false,
                    AmountToPaid: inv.Total_Due__c,
                    disableCheckbox: !inv.Posted__c && inv.RecordType.DeveloperName !== 'Advance',
                    isAdvance: inv.RecordType.DeveloperName === 'Advance',
                    invoiceurl: '/' + inv.Id,
                    postLable: inv.Posted__c ? 'Unpost' : 'Post',
                    isPosted: inv.Posted__c ? 'Yes' : 'No',
                    isPostedClass: inv.Posted__c ? 'bgGreen' : 'bgRed'
                });
                idx++;
            }
        });

        console.log('this.invoiceToPay ', JSON.stringify(this.invoiceToPay));  
        console.log('here ');
        // ✅ BILLING ADDRESS
        this.paymentBillAdd = result.ord?.Bill_To_Address__r || {};
        console.log('here 2');
        console.log('paymentBillAdd --> ',JSON.stringify(this.paymentBillAdd));
        // ✅ LOAD PAYMENT GATEWAYS
        return getInitailCardDetails();
    })
    .then(res => {
        console.log('gateways --> ',JSON.stringify(res.paymentGateways));
        this.paymentGateway = res.paymentGateways || [];

        if (this.paymentGateway.length === 0) {
            this.paymentError = 'Payment Credential Setup is not completed.';
        } else if (this.paymentGateway.length === 1) {
            this.selectedGateway = this.paymentGateway[0].value;
        }

        this.CardTypes = res.CardTypes;
        this.ExpiryMonth = res.ExpiryMonth;
        this.ExpiryYear = res.ExpiryYear;
        this.CountryList = res.CountryList;
        this.CountyList = res.CountyList;
    })
    .catch(error => {
        console.error(error);
        this.errorMessage = 'Failed to load order details';
    })
    .finally(() => {
        this.isLoading = false;
    });
}


    // Summary getters
    get orderAmount() { return this.orderDetails?.ord?.Order_Amount__c || 0; }
    get paidAmount() { return this.orderDetails?.ord?.Amount_Paid__c || 0; }
    get dueAmount() { return this.orderDetails?.ord?.Due_Amount__c || 0; }
    get creditAmount() { return this.orderDetails?.ord?.Account?.Available_Credit_Balance__c || 0; }
    get currencySymbol() {
    const cur = this.orderDetails?.orderCurrency || 'GBP';

    const map = {
        'GBP': '£',
        'USD': '$',
        'EUR': '€',
        'AED': 'د.إ',
        'INR': '₹',
        'CAD': '$',
        'AUD': '$'
    };

    return map[cur] || cur; // fallback to ISO code
}
get orderCurrency() {
    return this.orderDetails?.orderCurrency || 'GBP';
}
// ===== payment method state =====
    get isCardMethod() {
        return this.activePaymentMethod === 'card';
    }
    get isCashMethod() {
        return this.activePaymentMethod === 'cash';
    }
    get isBankMethod() {
        return this.activePaymentMethod === 'bank';
    }

    get cardMethodClass() {
        return 'payment-method-tab ' +
            (this.activePaymentMethod === 'card' ? 'payment-method-tab_active' : '');
    }
    get cashMethodClass() {
        return 'payment-method-tab ' +
            (this.activePaymentMethod === 'cash' ? 'payment-method-tab_active' : '');
    }
    get bankMethodClass() {
        return 'payment-method-tab ' +
            (this.activePaymentMethod === 'bank' ? 'payment-method-tab_active' : '');
    }


get invoices() {
    return this.orderDetails?.invoiceList || [];
}

get hasInvoices() {
    return this.invoices.length > 0;
}

get billing() {
    const b = this.orderDetails?.ord?.Bill_To_Address__r;
    return {
        Name:b?.Name || '',
        line1: b?.Address_Line1__c || '',
        line2: b?.Address_Line2__c || '',
        city: b?.City__c || '',
        country: b?.Country__c || '',
        state: b?.State__c || '',
        zip: b?.Postal_Code__c || ''
    };
}
get hasCardSection() {
    return this.isCardMethod && this.isOrderSelected;
}
navigateRecord(event) {
    const id = event.target.dataset.id;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: id,
            objectApiName: 'Invoice__c',
            actionName: 'view'
        }
    });
}
postInvoice(index) {
    console.log('POST INVOICE fired for index:', index);

    const inv = this.invoiceToPay[index];
    const postedValue = inv.postLable === 'Post';

    this.isLoading = true;

    upsertInvoice({ invId: inv.Id, postedValue })
        .then(result => {
            console.log('APEX RESULT:', result);

            // ✅ update row
            this.invoiceToPay[index] = {
                ...result,
                trKey: result.Id + index,
                AmountToPaid: result.Total_Due__c,
                checked: false,
                invoiceurl: '/' + result.Id,
                disableCheckbox: !result.Posted__c && result.RecordType.DeveloperName !== 'Advance',
                postLable: result.Posted__c ? 'Unpost' : 'Post',
                isPosted: result.Posted__c ? 'Yes' : 'No',
                isPostedClass: result.Posted__c ? 'bgGreen' : 'bgRed'
            };

            // ✅ refresh summary
            this.loadOrderDetails();

            // ✅ show toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Invoice ${this.invoiceToPay[index].Name} ${postedValue ? 'posted' : 'unposted'}`,
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.error('postInvoice error:', error);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Failed to update invoice',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
        });
}

handleMenuSelect(event) {
    const index = event.detail.value;
    this.postInvoice(index);
}
handlePayInvCheck(event) {
    const index = event.currentTarget.dataset.index;
    const checked = event.target.checked;

    let row = this.invoiceToPay[index];
    row.checked = checked;

    // Recalculate total
    let total = 0;
    this.invoiceToPay.forEach(inv => {
        if (inv.checked) {
            total += parseFloat(inv.AmountToPaid || 0);
        }
    });

    this.paymentToUpsert.Total_Amount__c = total.toFixed(2);
}
handleInvDue(event) {
    const index = event.currentTarget.dataset.index;
    const newValue = parseFloat(event.target.value || 0);

    const inv = this.invoiceToPay[index];

    // Validation: cannot exceed total due
    if (newValue > parseFloat(inv.Total_Due__c)) {
        this.paymentError = `${inv.Name} : Amount cannot be greater than due amount`;
        return;
    }

    // Update invoice amount to pay
    this.invoiceToPay[index].AmountToPaid = newValue;

    // Recalc total amount for all checked invoices
    let total = 0;
    this.invoiceToPay.forEach(item => {
        if (item.checked) {
            total += parseFloat(item.AmountToPaid || 0);
        }
    });

    this.paymentToUpsert.Total_Amount__c = total.toFixed(2);
}

get computedPaymentAmount() {
    return this.invoiceToPay
        .filter(x => x.checked)
        .reduce((sum, x) => sum + parseFloat(x.AmountToPaid), 0)
        .toFixed(2);
}
handlePaymentGateway(event) {
    this.selectedGateway = event.detail.value;
    console.log('Gateway selected:', this.selectedGateway);
}
handleCardName(event) {
    this.PaymentMethod.Name_on_Card__c = event.target.value;
}

handleCardNumber(event) {
    this.PaymentMethod.Card_Number__c = event.target.value;
}

handleCVV(event) {
    this.CVV = event.target.value;
}

handleCardType(event) {
    this.PaymentMethod.CardType__c = event.detail.value;
}

handleCardExpMonth(event) {
    this.PaymentMethod.Card_Expiration_Month__c = event.detail.value;
}

handleCardExpYear(event) {
    this.PaymentMethod.Card_Expiration_Year__c = event.detail.value;
}

handleRefCheque(event) {
    this.paymentToUpsert.Reference_Cheque_No__c = event.target.value;
}
handlePaymentMethodClick(event) {
    const method = event.currentTarget.dataset.method;
    this.activePaymentMethod = method;

    // when user clicks BANK tab, load bank data
    if (method === 'bank') {
        this.openBankPayment();
    }
}

openBankPayment() {
    try {
        this.isLoading = true;
        this.paymentError = '';

        // Reset all bank-related fields
        this.paymentToUpsert = {
            ...this.paymentToUpsert,
            Bank__c: '',
            Account_Holder_Name__c: '',
            Payment_Account__c: null,
            Account_Type__c: '',
            Account_Number__c: '',
            Bank_Code__c: '',
            Reference_Cheque_No__c: '',
            Total_Amount__c: 0
        };

        // Load invoice list again (same as card/cash logic)
        this.invoiceToPay = [];
        let idx = 0;

        this.orderDetails.invoiceList.forEach(inv => {
            if (inv.Total_Due__c > 0) {
                let entry = JSON.parse(JSON.stringify(inv));
                entry.trKey = entry.Id + idx;
                entry.checked = false;
                entry.AmountToPaid = inv.Total_Due__c;

                // disable / enable checkbox based on Posted__c + RecordType
                entry.disableCheckbox = !inv.Posted__c &&
                                        inv.RecordType.DeveloperName !== 'Advance';

                entry.isAdvance = inv.RecordType.DeveloperName === 'Advance';
                entry.postLable = inv.Posted__c ? 'Unpost' : 'Post';
                entry.isPosted = inv.Posted__c ? 'Yes' : 'No';
                entry.isPostedClass = inv.Posted__c ? 'bgGreen' : 'bgRed';

                this.invoiceToPay.push(entry);
                idx++;
            }
        });

        // Now set COA filter (optional)
        this.COAFilter = this.orderDetails?.ord?.Organisation__c
            ? `Organisation__c='${this.orderDetails.ord.Organisation__c}' AND Payment_Account__c=true`
            : `Payment_Account__c=true`;

        // 🔥 Now call Apex to get ACCOUNT TYPES
        getInitialBankDetails()
            .then(res => {
                this.accountTypeOptions = res.accountsType || [];

                if (this.accountTypeOptions.length > 0) {
                    this.paymentToUpsert.Account_Type__c =
                        this.accountTypeOptions[0].value;
                }

                this.isLoading = false;
            })
            .catch(err => {
                this.isLoading = false;
                this.paymentError = err.body?.message || err;
            });

    } catch (e) {
        this.isLoading = false;
        console.error('Bank Payment Init Error:', e);
    }
}

cardPaymentSave() {
    this.paymentError = '';
    console.log('in  card payment save !');
    // -------------------
    // BASIC VALIDATION
    // -------------------
    if (!this.paymentGateway || this.paymentGateway.length === 0) {
        this.paymentError = 'Payment Credential Setup is not completed.';
        return;
    }
      console.log('Ok 1');
    if (!this.invoiceToPay || this.invoiceToPay.length === 0) {
        this.paymentError = 'Due Invoice not available to pay';
        return;
    }
  console.log('Ok 2');
    let invAndAmount = [];
    let salesCount = 0, advCount = 0, checkedCount = 0;
    let singleInvoiceId = null;
  console.log('Ok 3');
    // -------------------
    // INVOICE SELECTION
    // -------------------
    this.invoiceToPay.forEach(inv => {
        if (inv.checked) {
            checkedCount++;
            invAndAmount.push({
                Id: inv.Id,
                Invoice_Amount__c: inv.AmountToPaid
            });

            singleInvoiceId = inv.Id;

            if (inv.RecordType.DeveloperName === 'Sale') salesCount++;
            if (inv.RecordType.DeveloperName === 'Advance') advCount++;
        }
    });
  console.log('Ok 4');
    if (checkedCount === 0) {
        this.paymentError = 'Please select invoice to pay';
        return;
    }
  console.log('Ok 5');
    // block paying both advance + sales
    if (salesCount > 0 && advCount > 0) {
        this.paymentError = 'Cannot pay sale and advance invoices together.';
        return;
    }

    if (checkedCount === 1) {
        this.paymentToUpsert.Invoice__c = singleInvoiceId;
    }
  console.log('Ok 6');
    // -------------------
    // CARD VALIDATION
    // -------------------
    if (!this.PaymentMethod.Name_on_Card__c) {
        this.paymentError = 'Enter Card Holder Name';
        return;
    }
    if (!this.PaymentMethod.CardType__c) {
        this.paymentError = 'Select Card Type';
        return;
    }
    if (!this.PaymentMethod.Card_Number__c) {
        this.paymentError = 'Enter Card Number';
        return;
    }
    if (!this.CVV) {
        this.paymentError = 'Enter CVV';
        return;
    }
  console.log('Ok 7');
    const expiryMonth = parseInt(this.PaymentMethod.Card_Expiration_Month__c, 10);
    const expiryYear = parseInt(this.PaymentMethod.Card_Expiration_Year__c, 10);
      console.log('Ok 1.1 ');
    const now = new Date();
    const cy = now.getFullYear();
    const cm = now.getMonth() + 1;
console.log('Ok 1.2 ');
    if (expiryYear < cy || (expiryYear === cy && expiryMonth < cm)) {
        this.paymentError = 'Card has expired';
        return;
    }
console.log('Ok 1.3 ');
    if (!this.paymentToUpsert.Total_Amount__c || this.paymentToUpsert.Total_Amount__c <= 0) {
        this.paymentToUpsert.Total_Amount__c = 100;
       this.paymentError = 'Payment Amount cannot be zero or negative';
       return;
    }
    console.log('Ok 8');
    // BILLING ADDRESS CHECK
    if (!this.paymentBillAdd.Country__c) {
        this.paymentError = 'Select Country';
        return;
    }
    if (!this.paymentBillAdd.State__c) {
        this.paymentError = 'Select State/Province';
        return;
    }
    if (!this.selectedGateway) {
        this.paymentError = 'Select Payment Gateway';
        return;
    }
    console.log(' here ');
    this.isLoading = true;
  console.log('Ok 9');
    // -------------------
    // PREPARE PAYMENT OBJECT (as EPOS does)
    // -------------------
    this.paymentToUpsert.Account_Holder_Name__c = this.PaymentMethod.Name_on_Card__c;
    this.paymentToUpsert.Order__c = this.orderDetails.ord.Id;
    this.paymentToUpsert.Accounts__c = this.orderDetails.ord.AccountId;
    this.paymentToUpsert.Amount__c = this.paymentToUpsert.Total_Amount__c;

    // -------------------
    // CALL APEX
    // -------------------
    console.log('calling apex ');
    cardPayment({
        payments: JSON.stringify(this.paymentToUpsert),
        paymentMethods: JSON.stringify(this.PaymentMethod),
        CVV: this.CVV,
        billAddress: JSON.stringify(this.paymentBillAdd),
        selectedGateway: this.selectedGateway,
        myCur: this.orderCurrency,
        invAndAmount: JSON.stringify(invAndAmount),
        resCode: 1,
        ordID: this.orderDetails.ord.Id
    })
    .then(result => {
        if (result.includes('Payment Created Successfully')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    variant: 'success',
                    message: result
                })
            );

            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('payment'));
        } else {
            this.paymentError = result;
            this.isLoading = false;
        }
    })
    .catch(err => {
        this.paymentError = err.body?.message || err;
        this.isLoading = false;
    });
}
cashPaymentSave() {
    this.paymentError = '';

    // No invoices
    if (!this.invoiceToPay || this.invoiceToPay.length === 0) {
        this.paymentError = 'Due Invoice not available to pay';
        return;
    }

    let invAndAmount = [];
    let selectedCount = 0;
    let singleInvoiceId = null;
    let salesCount = 0;
    let advCount = 0;

    // Build invoice list
    this.invoiceToPay.forEach(inv => {
        if (inv.checked) {
            selectedCount++;
            singleInvoiceId = inv.Id;

            invAndAmount.push({
                Id: inv.Id,
                Invoice_Amount__c: inv.AmountToPaid
            });

            if (inv.RecordType.DeveloperName === 'Sale') salesCount++;
            if (inv.RecordType.DeveloperName === 'Advance') advCount++;
        }
    });

    if (salesCount > 0 && advCount > 0) {
        this.paymentError = 'Cannot pay Sales and Advance invoices together.';
        return;
    }

    if (selectedCount === 0) {
        this.paymentError = 'Please select invoice to pay';
        return;
    }

    if (selectedCount === 1) {
        this.paymentToUpsert.Invoice__c = singleInvoiceId;
    }

    // Validate each invoice
    for (let i in this.invoiceToPay) {
        const inv = this.invoiceToPay[i];

        if (inv.checked && inv.AmountToPaid <= 0) {
            this.paymentError = inv.Name + ' : Amount to pay cannot be zero or negative';
            return;
        }

        if (inv.checked && inv.AmountToPaid > inv.Total_Due__c) {
            this.paymentError = inv.Name + ' : Amount cannot be greater than due amount';
            return;
        }
    }

    // Reference No
    if (!this.paymentToUpsert.Reference_Cheque_No__c) {
        this.paymentError = 'Missing Reference No';
        return;
    }

    // Total Amount
    let total = parseFloat(this.computedPaymentAmount);
    if (total <= 0) {
        this.paymentError = 'Payment Amount cannot be zero or negative';
        return;
    }

    this.paymentToUpsert.Total_Amount__c = total;
    this.paymentToUpsert.Amount__c = total;

    // Cash Payment fields
    this.paymentToUpsert.Type__c = 'Debit';
    this.paymentToUpsert.Payment_Type__c = 'Cash';
    this.paymentToUpsert.Status__c = 'Paid';

    // Billing Address
    const b = this.paymentBillAdd;
    this.paymentToUpsert.Address__c = b.Name;
    this.paymentToUpsert.Address_Line1__c = b.Address_Line1__c;
    this.paymentToUpsert.Address_Line2__c = b.Address_Line2__c;
    this.paymentToUpsert.City__c = b.City__c;
    this.paymentToUpsert.State__c = b.State__c;
    this.paymentToUpsert.Country__c = b.Country__c;
    this.paymentToUpsert.Zipcode__c = b.Postal_Code__c;

    // Order Info
    this.paymentToUpsert.Order__c = this.orderDetails.ord.Id;
    this.paymentToUpsert.Accounts__c = this.orderDetails.ord.AccountId;

    this.isLoading = true;

    bankOrCashPayment({
        payments: JSON.stringify(this.paymentToUpsert),
        invAndAmount: JSON.stringify(invAndAmount),
        paymentType: 'Cash',
        ordID: this.orderDetails.ord.Id
    })
        .then(result => {
            if (result.includes('Payment Created Successfully')) {

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result,
                        variant: 'success'
                    })
                );

                // RESET UI + REFRESH ORDER
                this.paymentToUpsert = { Total_Amount__c: 0 };
                this.invoiceToPay = [];
                this.loadOrderDetails();
            } else {
                this.paymentError = result;
            }

            this.isLoading = false;
        })
        .catch(err => {
            this.paymentError = err.body?.message || err;
            this.isLoading = false;
        });
}
bankPaymentSave() {
    this.paymentError = '';

    if (!this.invoiceToPay || this.invoiceToPay.length === 0) {
        this.paymentError = 'Due Invoice not available to pay';
        return;
    }

    let invAndAmount = [];
    let selectedCount = 0;
    let singleInvoiceId = null;
    let salesCount = 0;
    let advCount = 0;

    // Select Invoices
    this.invoiceToPay.forEach(inv => {
        if (inv.checked) {
            selectedCount++;
            singleInvoiceId = inv.Id;

            invAndAmount.push({
                Id: inv.Id,
                Invoice_Amount__c: inv.AmountToPaid
            });

            if (inv.RecordType.DeveloperName === 'Sale') salesCount++;
            if (inv.RecordType.DeveloperName === 'Advance') advCount++;
        }
    });

    if (salesCount > 0 && advCount > 0) {
        this.paymentError = 'Cannot pay Sales and Advance invoices together.';
        return;
    }

    if (selectedCount === 0) {
        this.paymentError = 'Please select invoice to pay';
        return;
    }

    if (selectedCount === 1) {
        this.paymentToUpsert.Invoice__c = singleInvoiceId;
    }

    // Invoice amount validation
    for (let inv of this.invoiceToPay) {
        if (inv.checked && inv.AmountToPaid <= 0) {
            this.paymentError = inv.Name + ' : Amount must be greater than zero';
            return;
        }
        if (inv.checked && inv.AmountToPaid > inv.Total_Due__c) {
            this.paymentError = inv.Name + ' : Amount cannot exceed due';
            return;
        }
    }

    // Reference No
    if (!this.paymentToUpsert.Reference_Cheque_No__c) {
        this.paymentError = 'Missing Reference/Cheque No';
        return;
    }

    // Total Amount
    let total = parseFloat(this.computedPaymentAmount);
    if (total <= 0) {
        this.paymentError = 'Payment Amount cannot be zero or negative';
        return;
    }

    // Assign payment fields
    this.paymentToUpsert.Total_Amount__c = total;
    this.paymentToUpsert.Amount__c = total;
    this.paymentToUpsert.Payment_Type__c = 'Bank';
    this.paymentToUpsert.Type__c = 'Debit';
    this.paymentToUpsert.Status__c = 'Paid';

    // Order Info
    const ord = this.orderDetails.ord;
    this.paymentToUpsert.Order__c = ord.Id;
    this.paymentToUpsert.Accounts__c = ord.AccountId;

    // Billing info
    const b = this.paymentBillAdd;
    this.paymentToUpsert.Address_Line1__c = b.Address_Line1__c;
    this.paymentToUpsert.Address_Line2__c = b.Address_Line2__c;
    this.paymentToUpsert.City__c = b.City__c;
    this.paymentToUpsert.State__c = b.State__c;
    this.paymentToUpsert.Country__c = b.Country__c;
    this.paymentToUpsert.Zipcode__c = b.Postal_Code__c;

    this.isLoading = true;

    bankOrCashPayment({
        payments: JSON.stringify(this.paymentToUpsert),
        invAndAmount: JSON.stringify(invAndAmount),
        paymentType: 'Bank',
        ordID: ord.Id
    })
        .then(result => {
            if (result.includes('Payment Created Successfully')) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        variant: 'success',
                        message: result
                    })
                );

                // Reset + Refresh
                this.paymentToUpsert = { Total_Amount__c: 0 };
                this.invoiceToPay = [];
                this.loadOrderDetails();
            } else {
                this.paymentError = result;
            }

            this.isLoading = false;
        })
        .catch(err => {
            this.paymentError = err.body?.message || err;
            this.isLoading = false;
        });
}

 handleBillLine(event) {
        this.paymentBillAdd.Name = event.currentTarget.value;
    }
    handleBillLine1(event) {
        this.paymentBillAdd.Address_Line1__c = event.currentTarget.value;
    }
    handleBillLine2(event) {
        this.paymentBillAdd.Address_Line2__c = event.currentTarget.value;
    }
    handleBillCountry(event) {
        this.paymentBillAdd.Country__c = event.currentTarget.value;
    }
    handleBillCity(event) {
        this.paymentBillAdd.City__c = event.detail.value;
    }
    handleBillState(event) {
        this.paymentBillAdd.State__c = event.currentTarget.value;
    }
    handleBillZip(event) {
        this.paymentBillAdd.Postal_Code__c = event.currentTarget.value;
    }
    handleBankName(e) {
    this.paymentToUpsert.Bank__c = e.target.value;
}
handleAHName(e) {
    this.paymentToUpsert.Account_Holder_Name__c = e.target.value;
}
removeCOA() {
    this.paymentToUpsert.Payment_Account__c = null;
}
selectCOA(e) {
    this.paymentToUpsert.Payment_Account__c = e.detail.Id;
}
handleACtype(e) {
    this.paymentToUpsert.Account_Type__c = e.detail.value;
}
handleACNumber(e) {
    this.paymentToUpsert.Account_Number__c = e.target.value;
}
handleBankCode(e) {
    this.paymentToUpsert.Bank_Code__c = e.target.value;
}
handleBankRefCheque(e) {
    this.paymentToUpsert.Reference_Cheque_No__c = e.target.value;
}

}