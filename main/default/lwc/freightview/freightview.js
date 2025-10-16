import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, PageReferenceNavigateEvent } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';

import freightviewLogo from '@salesforce/resourceUrl/freightviewLogo';
import getInitialData from '@salesforce/apex/freightView.getDefaultData';
import shippingRequestResponse from '@salesforce/apex/freightView.shippingRequestResponse';
import getQuoteRates from '@salesforce/apex/freightView.getQuoteRates';
 import getShipmentDocs from '@salesforce/apex/freightView.getShipmentDocs';    
 
 

// lables 
import shipmentGoing from "@salesforce/label/c.X1_Where_is_this_shipment_going";
import validateAddress from "@salesforce/label/c.Validate_Address";
import CompanyLabel from "@salesforce/label/c.CompanyLabel";
import ContactLabel from "@salesforce/label/c.ContractConsole_Contact";
import PhoneLabel from "@salesforce/label/c.Phone_AddTimeCardEntry";
export default class freightview extends NavigationMixin(LightningElement)
   {
    freightviewImg = freightviewLogo;

// Lables 
     label = {
        validateAddress,
        shipmentGoing,
        CompanyLabel,
        ContactLabel,
        PhoneLabel
     };
        @track isLoading = false;
        @track toContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' },Company__r:{Id:'',Name: ''} }; 
    @track fromAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Contact__c: '', Contact__r: { Id: '', Name: '', Company__c: '' }, Customer__c: '', Customer__r: { Id: '', Name: '', Company_txt__c: '' }, opens_at__c : '', closes_at__c : ''};
@track shipment = { Id: null, Name: '', emergency_contact__c: '', schedulePickup__c: '', Status__c: '', TrackingNumber__c: '', Label_options__c: 'LABEL', Invoice_Number__c: '', Purchase_Order_Number__c: '', Terms_Of_Shipment__c: '', Reason_For_Export__c: 'SAMPLE', Declaration_Statement__c: '', Shipment_Date__c: '', Description__c: '', Signature_Services__c: '', Shipment_Billing_options__c: 'SENDER', Fedex_Special_Services__c: '', Billing_Account_Number__c: '', Billing_Contact__c: '', Billing_Contact__r: { Id: '', Name: '' }, Billing_Address__c: '', Billing_Address__r: { Id: '', Name: '' }, ShipmentID__c : '' };
        @track fromContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' },Company__r:{Id:'',Name: ''} };

    @track toAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Customer__c: '', Customer__r: { Id: '', Name: '', Company_txt__c: '' }, opens_at__c : '', closes_at__c : '' };
    @track toAddressSelected = false;
    @track FromAddressSelected = false;
    @track toAddressSelected = false;
    @track toShipmentType = false;
    @track fromShipmentType = false;
    @track packageList;
    @track packageItems = [];
    @track ShowLabels = false;
    @track ShowGetRate = true;
    @track ShowCancelShipment = false;
    @track billingAddressSelected = false;
    @track billContactSelected = false;
    @track isShipmentRatesOpen = false;
    @track showRates = false;
    // @track billingContact = { Id: null, Name: '' };
    // @track billingAddress = { Id: null, Name: '' };
    // @track billingContactSelected = true;
    @track isBillingAddressSelected = false;
    @track isBillingContactSelected = false;
    @track BillingAddressUrl = '';
    @track BillingContactUrl = '';
    @track BillingAddressName = '';
    @track BillingContactName = '';





   

    @api returnmaid;
    @api refundamt;
    @api issaccess;
    @api isorderacc;
    @api packageIds = []; //a0L0600000SwaYZEAZ // a0L0600000Sui9GEAR //a14J7000000giwtIAA //'a1zgK00000042T3QAI'
    @api shipId = '';
    @api shipmentIds = '';
    @api packageList;
    @track quotes;
    @track showCreateShipment = true;
     @track defaultDate;
    @track minDate;
    errorList = [];
    minShipDate;
    docIds = {};
    shipmentDateValue;
    billingContactUrl;
    billingAddressUrl;
    

    
    


    // connectedCallback() {
    //     try {
    //         this.isLoading = true;
    //         console.log('ReturnMAID:', this.returnmaid);
    //     console.log('Refund Amount:', this.refundamt);
    //     console.log('isSOAccess:', this.issaccess);
    //     console.log('isOrderAcc:', this.isorderacc);
    //     console.log('package ids',this.packageIds);
    //         console.log('this.shipmentIds : ', this.shipmentIds);
    //         var boolValue =false;
    //         getInitialData({ ShipId: this.shipmentIds, packIds: JSON.stringify(this.packageIds), ReturnShip: boolValue})
    //             .then(result => {
    //                 console.log('from address ==>',result.fromAddress);
                    
    //                 console.log('getInitialData res : ', JSON.stringify(result));
    //                 if (result) {
    //                     if (result.alertlist && result.alertlist.length > 0) {
    //                         this.errorList = Object.assign([], this.errorList);
    //                         this.errorList = result.alertlist;
    //                         this.ShowGetRate = false;
    //                         this.isLoading = false;
    //                     }
    //                     else {
    //                         this.defaulWrap = result;
    //                         //console.log('1');
    //                         this.credentials = result.credsWrap;
    //                         console.log('this.credentials : ', JSON.stringify(this.credentials));
    //                         if (this.shipmentIds) {
    //                             this.showCreateShipment = false;
    //                             if (!result.ship.Billing_Contact__c) {
    //                                 result.ship.Billing_Contact__c = '';
    //                                 result.ship.Billing_Contact__r = { Id: '', Name: '' };
    //                             }
    //                             if (!result.ship.Billing_Address__c) {
    //                                 result.ship.Billing_Address__c = '';
    //                                 result.ship.Billing_Address__r = { Id: '', Name: '' };
    //                             }
    //                             this.shipment = result.ship;
    //                             console.log('Name : ', this.shipment.Name);
    //                         }

    //                         if (result.toAddress && Object.keys(result.toAddress).length !== 0) {
    //                             this.toAddress = result.toAddress;
    //                             console.log('result.toAddress : ', JSON.stringify(result.toAddress));
    //                         }
                                                            
    //                         else this.errorList.push('To Address is missing on your logistics.');

    //                         if (result.fromAddress && Object.keys(result.fromAddress).length !== 0) this.fromAddress = result.fromAddress;
    //                         else this.errorList.push('From Address is missing on your logistics.');

    //                         if (this.fromAddress.Id) {
    //                             this.FromAddressSelected = true;
    //                             this.fromAddressUrl = '/' + this.fromAddress.Id;
    //                         }

    //                         if (this.toAddress.Id) {
    //                             this.toAddressSelected = true;
    //                             this.toAddressUrl = '/' + this.toAddress.Id;
    //                         }
    //                         console.log('result.fromContact : ', JSON.stringify(result.fromContact));
    //                         if (result.fromContact && Object.keys(result.fromContact).length !== 0) this.fromContact = result.fromContact;
    //                         else this.errorList.push('From contact is missing on your logistics.');
    //                         if (result.toContact && Object.keys(result.toContact).length !== 0) this.toContact = result.toContact;
    //                         else this.errorList.push('To contact is missing on your logistics.');
    //                         for (var x in result.packList) {
    //                             result.packList[x].packUrl = '/' + result.packList[x].Id;
    //                         }
                           
                       
    //                         if(result.packList && result.packList.length > 0){
    //                             console.log("entered result packlist:",JSON.stringify(result.packList));
    //                             if (result.packList[0].Logistic__r != null) {if (result.packList[0].Logistic__r.Billing_options__c) this.shipment.Shipment_Billing_options__c = result.packList[0].Logistic__r.Billing_options__c;}
    //                             else this.shipment.Shipment_Billing_options__c = 'SENDER';
    //                             this.shipment.Billing_Contact__c =  result.packList[0].Logistic__r != null ? result.packList[0].Logistic__r.Billing_Contact__c : '';
    //                             if (result.packList[0].Logistic__r != null && result.packList[0].Logistic__r.Billing_Contact__c) {
    //                                 this.billContactSelected = true;
    //                                 this.shipment.Billing_Contact__r.Id = result.packList[0].Logistic__r.Billing_Contact__c;
    //                                 this.shipment.Billing_Contact__r.Name = result.packList[0].Logistic__r.Billing_Contact__r.Name;

    //                             }
    //                             else {
    //                                 this.billContactSelected = false;
    //                                 this.shipment.Billing_Contact__r = { Id: '', Name: '' };
    //                             }
    //                             if (result.packList[0].Logistic__r != null){
    //                                 if (result.packList[0].Logistic__r.Billing_Address__c) { this.shipment.Billing_Address__c = result.packList[0].Logistic__r.Billing_Address__c;}
    //                             }
    //                             if(result.packList[0].Logistic__r != null){
    //                             if (result.packList[0].Logistic__r.Billing_Address__c) {
    //                                 this.billingAddressSelected = true;
    //                                 this.shipment.Billing_Address__r.Id = result.packList[0].Logistic__r.Billing_Address__c;
    //                                 this.shipment.Billing_Address__r.Name = result.packList[0].Logistic__r.Billing_Address__r.Name;
    //                             }
    //                         }
    //                             else {
    //                                 this.billContactSelected = false;
    //                                 this.shipment.Billing_Address__r = { Id: '', Name: '' };
    //                             }
                                
    //                 }
                        
                            
                           
    //                           console.log('this.showUPSReturn : ', this.showUPSReturnType);
    //                         // console.log('10');
    //                         this.packageList = result.packList;
    //                         console.log('packageList==>'+JSON.stringify(this.packageList));
    //                         this.packageItems = result.packItems;
    //                         //console.log('11');
    //                         var today = new Date();
    //                         if (!this.shipmentIds) this.shipment.Shipment_Date__c = today.getFullYear() + '-' + ('0' + (today.getMonth() + 1)).slice(-2) + '-' + ('0' + today.getDate()).slice(-2);
    //                         if (this.shipmentIds) {
    //                             this.ShowLabels = true;
    //                             this.ShowGetRate = false;
    //                             this.ShowCancelShipment = true;
    //                         }
                            
    //                         //console.log('12');
    //                         this.disableBillingOption = result.disableBillingDetails;

    //                         this.isLoading = false;
    //                     }
                        
                        
    //                 }
    //             }).
    //             catch(error => {
    //                 this.isLoading = false;
    //                 console.log('Error:', error);
    //                 this.errorList = Object.assign([], this.errorList);
    //                 if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
    //                 if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
    //             });
    //     } catch (error) {
    //         console.log('Error: getInitialData==>', error);
    //     }

    // }
connectedCallback() {
  try {
    this.isLoading = true;
    this.setDefaultDate();


    console.log('ReturnMAID:', this.returnmaid);
    console.log('Refund Amount:', this.refundamt);
    console.log('isSOAccess:', this.issaccess);
    console.log('isOrderAcc:', this.isorderacc);
    console.log('package ids:', this.packageIds);
    console.log('this.shipmentIds:', this.shipmentIds);

    const boolValue = false;

    getInitialData({
      ShipId: this.shipmentIds,
      packIds: JSON.stringify(this.packageIds),
      ReturnShip: boolValue
    })
      .then(result => {
        console.log('getInitialData res:', JSON.stringify(result));

        if (!result) {
          throw new Error('No data returned from getInitialData.');
        }

        if (result.alertlist && result.alertlist.length > 0) {
          this.errorList = [...result.alertlist];
          this.ShowGetRate = false;
          return; // stop further execution if alertlist exists
        }

        // ✅ Assign core data
        this.defaulWrap = result;
        this.credentials = result.credsWrap;
        console.log('this.credentials:', JSON.stringify(this.credentials));

        // ✅ Shipment initialization
        if (this.shipmentIds) {
          this.showCreateShipment = false;

          // Ensure billing fields are always initialized
          if (!result.ship.Billing_Contact__c) {
            result.ship.Billing_Contact__c = '';
            result.ship.Billing_Contact__r = { Id: '', Name: '' };
          }
          if (!result.ship.Billing_Address__c) {
            result.ship.Billing_Address__c = '';
            result.ship.Billing_Address__r = { Id: '', Name: '' };
          }

            this.shipment = result.ship;
            console.log('AZ Return Ship', result.ship);
            console.log('AZ billing contact',result.ship.Billing_Contact__c);
            console.log('AZ billing address', result.ship.Billing_Address__c);
            // Ensure the billing fields are always populated with string values
            this.shipment.Billing_Contact__c = result.ship.Billing_Contact__c || '';
            this.shipment.Billing_Address__c = result.ship.Billing_Address__c || '';
            console.log('AZ billing contact', this.shipment.Billing_Contact__c);
            console.log('AZ billing address', this.shipment.Billing_Address__c);
            this.isBillingAddressSelected = true;
            this.isBillingContactSelected = true;
            this.BillingAddressUrl = '/' + this.shipment.Billing_Address__c;
            this.BillingAddressName = this.shipment.Billing_Address__r.Name;
            console.log('AZ billing address ', this.BillingAddressName);

            this.BillingContactUrl = '/' + this.shipment.Billing_Contact__c;
            this.BillingContactName = this.shipment.Billing_Contact__r.Name;
            
          console.log('Shipment Name:', this.shipment.Name);
        }

        // ✅ Validate addresses
        if (result.toAddress && Object.keys(result.toAddress).length) {
          this.toAddress = result.toAddress;
        } else {
          this.errorList.push('To Address is missing on your logistics.');
        }

        if (result.fromAddress && Object.keys(result.fromAddress).length) {
          this.fromAddress = result.fromAddress;
        } else {
          this.errorList.push('From Address is missing on your logistics.');
        }

        // ✅ Setup address URLs
        if (this.fromAddress?.Id) {
          this.FromAddressSelected = true;
          this.fromAddressUrl = '/' + this.fromAddress.Id;
        }

        if (this.toAddress?.Id) {
          this.toAddressSelected = true;
          this.toAddressUrl = '/' + this.toAddress.Id;
        }

        // ✅ Contacts validation
        if (result.fromContact && Object.keys(result.fromContact).length) {
          this.fromContact = result.fromContact;
        } else {
          this.errorList.push('From contact is missing on your logistics.');
        }

        if (result.toContact && Object.keys(result.toContact).length) {
          this.toContact = result.toContact;
        } else {
          this.errorList.push('To contact is missing on your logistics.');
        }

        // ✅ Package list handling
        if (result.packList?.length > 0) {
          result.packList.forEach(p => (p.packUrl = '/' + p.Id));

          const firstPack = result.packList[0];
          const logistic = firstPack.Logistic__r;

          this.shipment.Shipment_Billing_options__c = logistic?.Billing_options__c || 'SENDER';
          this.shipment.Billing_Contact__c = logistic?.Billing_Contact__c || '';
          this.shipment.Billing_Address__c = logistic?.Billing_Address__c || '';

          // Set related names
          if (logistic?.Billing_Contact__r) {
            this.billContactSelected = true;
            this.shipment.Billing_Contact__r = {
              Id: logistic.Billing_Contact__c,
              Name: logistic.Billing_Contact__r.Name
            };
          } else {
            this.billContactSelected = false;
            this.shipment.Billing_Contact__r = { Id: '', Name: '' };
          }

          if (logistic?.Billing_Address__r) {
            this.billingAddressSelected = true;
            this.shipment.Billing_Address__r = {
              Id: logistic.Billing_Address__c,
              Name: logistic.Billing_Address__r.Name
            };
          } else {
            this.billingAddressSelected = false;
            this.shipment.Billing_Address__r = { Id: '', Name: '' };
          }
        }

        // ✅ Other UI setup
        this.packageList = result.packList;
        this.packageItems = result.packItems;
        this.disableBillingOption = result.disableBillingDetails;

        const today = new Date();
          if (!this.shipmentIds) {
            
          this.shipment.Shipment_Date__c = `${today.getFullYear()}-${('0' + (today.getMonth() + 1)).slice(-2)}-${('0' + today.getDate()).slice(-2)}`;
        } else {
          this.ShowLabels = true;
          this.ShowGetRate = false;
              this.ShowCancelShipment = true;
               try {
                 this.fetchDocsForShipment();
            } catch (docError) {
                console.warn('Could not fetch shipment docs:', docError);
                this.docIds = {}; // fallback to empty
            }
        }
      })
      .catch(error => {
        console.error('Error in getInitialData:', error);

        let errorMsg =
          error?.body?.message ||
          error?.message ||
          'An unexpected error occurred while fetching shipment details.';

        this.errorList = [...this.errorList];
        if (!this.errorList.includes(errorMsg)) this.errorList.push(errorMsg);

        // ✅ Optional toast display for better UX
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error Loading Shipment Data',
            message: errorMsg,
            variant: 'error'
          })
        );
      })
      .finally(() => {
        // ✅ Always stop spinner
        this.isLoading = false;
      });
  } catch (error) {
    console.error('Outer Error in connectedCallback:', error);
    this.isLoading = false;

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Initialization Error',
        message: error.message || 'An unexpected error occurred during initialization.',
        variant: 'error'
      })
    );
  }
}

    
get formattedOpensAt() {
    return this.convertTimeToHHMM(this.toAddress?.opens_at__c);
}

get formattedClosesAt() {
    return this.convertTimeToHHMM(this.toAddress?.closes_at__c);
}

convertTimeToHHMM(timeVal) {
    if (!timeVal) return '';

    // Case 1: It's a string like '08:30:00'
    if (typeof timeVal === 'string') {
        return timeVal.slice(0, 5); // return 'HH:mm'
    }

    // Case 2: It's a number (milliseconds)
    if (typeof timeVal === 'number') {
        const totalMinutes = Math.floor(timeVal / 60000);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;

        const hh = hours.toString().padStart(2, '0');
        const mm = minutes.toString().padStart(2, '0');
        return `${hh}:${mm}`;
    }

    return '';
}
    
    // ✅ Set default date (tomorrow, skipping Sat/Sun)
    // setDefaultDate() {
    //     let today = new Date();
    //     let tomorrow = new Date(today);
    //     tomorrow.setDate(today.getDate() );

    //     // Skip weekends
    //     let day = tomorrow.getDay(); // 0 = Sunday, 6 = Saturday
    //     if (day === 6) {
    //         // Saturday → +2 days (Monday)
    //         tomorrow.setDate(tomorrow.getDate() + 2);
    //     } else if (day === 0) {
    //         // Sunday → +1 day (Monday)
    //         tomorrow.setDate(tomorrow.getDate() + 1);
    //     }

    //     this.defaultDate = this.formatDate(tomorrow);
    //     this.minDate = this.defaultDate; // disable past dates
    // }

    setDefaultDate() {
    let today = new Date();
    let defaultDate = new Date(today);
    defaultDate.setDate(today.getDate()); // keep current logic (today)

    // Skip weekends
    let day = defaultDate.getDay(); // 0 = Sunday, 6 = Saturday
    if (day === 6) {
        // Saturday → +2 days (Monday)
        defaultDate.setDate(defaultDate.getDate() + 2);
    } else if (day === 0) {
        // Sunday → +1 day (Monday)
        defaultDate.setDate(defaultDate.getDate() + 1);
    }

    this.defaultDate = this.formatDate(defaultDate);
    this.minDate = this.defaultDate; // disable past dates

    // ✅ Only set Shipment_Date__c if it’s empty
    if (!this.shipment.Shipment_Date__c) {
        this.shipment.Shipment_Date__c = this.defaultDate;
    }
}

    // Helper to format date as yyyy-MM-dd
    formatDate(dateObj) {
        const yyyy = dateObj.getFullYear();
        const mm = String(dateObj.getMonth() + 1).padStart(2, '0');
        const dd = String(dateObj.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }

   
    
     handleShipmentDate(event) {
        this.shipmentDateValue = event.target.value;
        this.validateShipmentDate(event.target);
     }



     validateShipmentDate(inputElement) {
        const selectedDate = new Date(inputElement.value);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const day = selectedDate.getDay();

        let errorMsg = '';

        if (day === 6 || day === 0) {
            errorMsg = 'Saturday and Sunday are not allowed for shipment.';
        } else if (selectedDate < today) {
            errorMsg = 'Shipment date cannot be in the past.';
        }

        inputElement.setCustomValidity(errorMsg);
        inputElement.reportValidity();

        return errorMsg === ''; // returns true if valid
    }

    setToShipmentType(event) {
        this.toShipmentType = event.currentTarget.checked;
    }
    setFromShipmentType(event) {
        this.fromShipmentType = event.currentTarget.checked;
    }

 handleBackFromShipmentRates() {
        this.isShipmentRatesOpen = false;
 }
    // getQuotes1() {
    //     this.isShipmentRatesOpen = true; // show the shipmentRates component
    // }
   
       createShipment() {
    console.log('In createShipment method');
           try {       
               // validations for the date 
               
                 const dateInput = this.template.querySelector('lightning-input[data-id="shipmentDate"]');

        if (!dateInput) {
            console.error('Shipment date field not found.');
            return;
        }

        // Validate before proceeding
        const isValidDate = this.validateShipmentDate(dateInput);

        if (!isValidDate) {
            this.showToast('Validation Error', 'Please select a valid shipment date.', 'error');
            return;
        }

        // ✅ Proceed with shipment creation logic here
               console.log('Creating shipment with date:', dateInput.value);
               this.shipment.Shipment_Date__c = dateInput.value;

               console.log('Selected shipment date:', this.shipment.Shipment_Date__c);


                 // --- Validation for the where tis shipment id going fields ---
   
    const fromAddressName = this.fromAddress?.Name || '';
    const fromAddressLine1 = this.fromAddress?.Address_Line1__c || '';
    const fromCompany =
        this.fromContact?.Company__r?.Name ||
        this.fromAddress?.Customer__r?.Company_txt__c ||
        this.fromContact?.Account?.Name || '';
    const fromEmail = this.fromContact?.Email || this.fromContact?.Account?.Email__c || '';
    const fromPhone = this.fromContact?.Phone || this.fromContact?.Account?.Phone || '';
    const fromContactName = this.fromContact?.Name || '';
    const fromCity = this.fromAddress?.City__c || '';
    const fromState = this.fromAddress?.State__c || '';
    const fromPostalCode = this.fromAddress?.Postal_Code__c || '';
    const fromCountry = this.fromAddress?.Country__c || '';

    const toAddressName = this.toAddress?.Name || '';
    const toAddressLine1 = this.toAddress?.Address_Line1__c || '';
    const toCompany =
        this.toContact?.Company__r?.Name ||
        this.toAddress?.Customer__r?.Company_txt__c ||
        this.toContact?.Account?.Name || '';
    const toEmail = this.toContact?.Email || this.toContact?.Account?.Email__c || '';
    const toPhone = this.toContact?.Phone || this.toContact?.Account?.Phone || '';
    const toContactName = this.toContact?.Name || '';
    const toCity = this.toAddress?.City__c || '';
    const toState = this.toAddress?.State__c || '';
    const toPostalCode = this.toAddress?.Postal_Code__c || '';
    const toCountry = this.toAddress?.Country__c || '';
    const pickupDate = new Date(this.shipment?.Shipment_Date__c);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (fromAddressName.length > 30) {
        this.showToast('Validation Error', 'From Address name cannot exceed 30 characters.', 'error');
        return;
    }

    else if (!fromAddressLine1) {
        this.showToast('Validation Error', 'From Address Line 1 is required.', 'error');
        return;
    }

    else if (toAddressName.length > 30) {
        this.showToast('Validation Error', 'To Address name cannot exceed 30 characters.', 'error');
        return;
    }

    else if (!toAddressLine1) {
        this.showToast('Validation Error', 'To Address Line 1 is required.', 'error');
        return;
    }

    else if (!fromAddressName) {
        this.showToast('Validation Error', 'Please select a From Address.', 'error');
        return;
    } else if (!fromCompany) {
        this.showToast('Validation Error', 'From Company is required.', 'error');
        return;
    } else if (!fromEmail) {
        this.showToast('Validation Error', 'From Email is required.', 'error');
        return;
    } else if (!fromContactName) {
        this.showToast('Validation Error', 'From Contact Name is required.', 'error');
        return;
    } else if (!fromPhone) {
        this.showToast('Validation Error', 'From Phone Number is required.', 'error');
        return;
    } else if (!fromCity) {
        this.showToast('Validation Error', 'From City/Town is required.', 'error');
        return;
    } else if (!fromState) {
        this.showToast('Validation Error', 'From State/County is required.', 'error');
        return;
    } else if (!fromPostalCode) {
        this.showToast('Validation Error', 'From Zip/Postal Code is required.', 'error');
        return;
    } else if (!fromCountry) {
        this.showToast('Validation Error', 'From Country is required.', 'error');
        return;
    }

    else if (!toAddressName) {
        this.showToast('Validation Error', 'Please select a To Address.', 'error');
        return;
    } else if (!toCompany) {
        this.showToast('Validation Error', 'To Company is required.', 'error');
        return;
    } else if (!toEmail) {
        this.showToast('Validation Error', 'To Email is required.', 'error');
        return;
    } else if (!toContactName) {
        this.showToast('Validation Error', 'To Contact Name is required.', 'error');
        return;
    } else if (!toPhone) {
        this.showToast('Validation Error', 'To Phone Number is required.', 'error');
        return;
    } else if (!toCity) {
        this.showToast('Validation Error', 'To City/Town is required.', 'error');
        return;
    } else if (!toState) {
        this.showToast('Validation Error', 'To State/County is required.', 'error');
        return;
    } else if (!toPostalCode) {
        this.showToast('Validation Error', 'To Zip/Postal Code is required.', 'error');
        return;
    } else if (!toCountry) {
        this.showToast('Validation Error', 'To Country is required.', 'error');
        return;
    }

    else if (!/^\d{10}$/.test(fromPhone)) {
        this.showToast('Validation Error', 'From Phone number must be exactly 10 digits.', 'error');
        return;
    } else if (!/^\d{10}$/.test(toPhone)) {
        this.showToast('Validation Error', 'To Phone number must be exactly 10 digits.', 'error');
        return;
    }

    else if (pickupDate < today) {
        this.showToast('Validation Error', 'Pickup date cannot be earlier than today.', 'error');
        return;
    }

    console.log('✅ All validations passed. Proceeding with shipment creation...');
               
//------ validation ends here ---------
        console.log('Creating shipment...');
        this.isLoading = true;
 
        const fromAddressJSON = JSON.stringify(this.fromAddress);
        const toAddressJSON = JSON.stringify(this.toAddress);
        const fromContactJSON = JSON.stringify(this.fromContact);
        const toContactJSON = JSON.stringify(this.toContact);
        const shipmentJSON = JSON.stringify(this.shipment);
        const credentialsJSON = JSON.stringify(this.credentials);
        const packageItemsJSON = this.packageItems;
        const packListJSON = this.packageList;
        console.log('this.shipment.Shipment_Date__c: ',this.shipment.Shipment_Date__c);
        const shipDateStamp = this.shipment.Shipment_Date__c ? this.shipment.Shipment_Date__c : new Date().toISOString().split('T')[0];
        console.log('shipDateStamp : ',shipDateStamp);
        const masterShipmentId = this.shipment.Id ? this.shipment.Id : '';
 
        console.log('Payload prepared for FreightView call');
        console.log('fromAddress:', fromAddressJSON);
        console.log('toAddress:', toAddressJSON);
        console.log('fromContact:', fromContactJSON);
        console.log('toContact:', toContactJSON);
        console.log('shipment:', shipmentJSON);
        console.log('credentials:', credentialsJSON);
 
        // Call Apex method
        shippingRequestResponse({
            packList: packListJSON,
            fromAddress: fromAddressJSON,
            toAddress: toAddressJSON,
            fromContact: fromContactJSON,
            toContact: toContactJSON,
            ShipDateStamp: shipDateStamp,
            myConsVar: credentialsJSON,
            Shipment: shipmentJSON,
            packageItems: packageItemsJSON,
            masterShipmentId: masterShipmentId
        })
        .then(result => {
            this.isLoading = false;
            console.log('FreightView Shipment Response:', JSON.stringify(result));
            // You can handle success UI feedback here
            if (result) {
                if (result.ShipDetails) {
                    this.shipment = result.ShipDetails;
                    this.showCreateShipment = false;
                    console.log('Updated shipment:', JSON.stringify(this.shipment));
                }
                console.log('myConsVar:', JSON.stringify(this.myConsVar));
                console.log('Shipment:', JSON.stringify(this.shipment));
                // Example: show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Shipment Created',
                        message: 'FreightView LTL shipment created successfully!',
                        variant: 'success'
                    })
                );
            }
        })
        .catch(error => {
            this.isLoading = false;
            console.error('Error in FreightView shipment creation:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Creating Shipment',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        });
 
    } catch (e) {
        this.isLoading = false;
        console.error('Exception in createShipment:', e);
    }
       }

    handleInputChange(event) {
    const field = event.target.dataset.id;
    const value = event.target.value;

    switch (field) {
        case 'description':
            this.shipment.Description__c = value;
            break;
        case 'billingAccountNumber':
            this.shipment.Billing_Account_Number__c = value;
            break;
        case 'billingContact':
            // assuming this field is a text input for contact name only
            if (!this.shipment.Billing_Contact__r) {
                this.shipment.Billing_Contact__r = {};
            }
            this.shipment.Billing_Contact__r.Name = value;
            break;
        case 'billingOptions':
            this.shipment.Billing_Options__c = value;
            break;
        case 'billingAddress':
            if (!this.shipment.Billing_Address__r) {
                this.shipment.Billing_Address__r = {};
            }
            this.shipment.Billing_Address__r.Name = value;
            break;
        default:
            console.warn('Unhandled field:', field);
    }

    console.log('Updated shipment:', JSON.parse(JSON.stringify(this.shipment)));
}

    
    // validateFields() {
    //     let isValid = true;
    //     let errorMessage = '';

    //     const addressName = this.toAddress?.Name || '';
    //     const phone = this.toContact?.Phone || this.toContact?.Account?.Phone || '';

    //     // 🛑 Address name character limit
    //     if (addressName && addressName.length > 30) {
    //         this.showToast('Validation Error', 'To Address name cannot exceed 30 characters.', 'error');
    //         isValid = false;
    //     }

    //     // 🛑 Required fields check
    //     const requiredFields = [
    //         { field: this.toAddress?.Name, label: 'To Address' },
    //         { field: this.toContact?.Name, label: 'Contact Name' },
    //         { field: this.toContact?.Company__r?.Name || this.toAddress?.Customer__r?.Company_txt__c, label: 'Company' },
    //         { field: this.toContact?.Email || this.toContact?.Account?.Email__c, label: 'Email' },
    //         { field: this.toAddress?.City__c, label: 'City/Town' },
    //         { field: this.toAddress?.State__c, label: 'State/County' },
    //         { field: this.toAddress?.Postal_Code__c, label: 'Zip/Postal Code' },
    //         { field: this.toAddress?.Country__c, label: 'Country' },
    //         { field: phone, label: 'Phone' }
    //     ];

    //     for (let field of requiredFields) {
    //         if (!field.field || field.field.trim() === '') {
    //             this.showToast('Missing Information', `${field.label} is required.`, 'error');
    //             isValid = false;
    //             break;
    //         }
    //     }

    //     // 🛑 Phone number validation (should be 10 digits)
    //     if (phone && !/^\d{10}$/.test(phone)) {
    //         this.showToast('Validation Error', 'Phone number must be exactly 10 digits.', 'error');
    //         isValid = false;
    //     }

    //     return isValid;

    // }

     showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

getQuotes() {
    console.log('in getQuotes');
    const shipmentJSON = JSON.stringify(this.shipment);
    const credentialsJSON = JSON.stringify(this.credentials);
    console.log('JSON.stringify(this.Shipment):', shipmentJSON);
    console.log('JSON.stringify(this.myConsVar):',credentialsJSON);
    this.isLoading = true; 
    console.log('loading is true');
    getQuoteRates({ Shipment: shipmentJSON, myConsVar: credentialsJSON })
  .then(result => {
    console.log('Quotes:', result);
    this.isShipmentRatesOpen = true;
    this.quotes = result; // store in a variable for UI
  }).catch(error => {
      console.error('Error fetching quotes:', error);

      let errorMsg = 'An unexpected error occurred while fetching quotes.';
      if (error && error.body && error.body.message) {
        errorMsg = error.body.message;
      } else if (error && error.message) {
        errorMsg = error.message;
      }

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: errorMsg,
          variant: 'error',
        })
      );
    })
    .finally(() => {
      this.isLoading = false;
    });
}
    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
    }
    
      openPreview(event) {
    const type = event.currentTarget.dataset.type; // 'bol' or 'label'
    const contentDocumentId = this.docIds?.[type];
    if (!contentDocumentId) {
      this.showToast('File Not Found', `No ${type.toUpperCase()} document found.`, 'warning');
      return;
    }
    this.openPreviewById(contentDocumentId);
  }
 
 openPreviewById(contentDocumentId) {
    console.log('Navigating to ContentDocumentId:', contentDocumentId);
    this[NavigationMixin.Navigate]({
        type: 'standard__namedPage',
        attributes: { pageName: 'filePreview' },
        state: { selectedRecordId: contentDocumentId }
    });
 }
    async fetchDocsForShipment() {
    if (!this.shipment?.Id) return;
    try {
        this.isLoading = true;
        const docs = await getShipmentDocs({ shipmentId: this.shipment.Id });
        this.docIds = docs;
        console.log('Fetched docIds:', JSON.stringify(this.docIds));
    } catch (error) {
        console.error('Error fetching shipment docs:', error);
    } finally {
        this.isLoading = false;
    }
}
 

}