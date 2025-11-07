import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import sendleLogo from '@salesforce/resourceUrl/sendleLogo';

// Calling Apex
import getInitialData from '@salesforce/apex/sendle.getDefaultData';
import fetchToAddress from '@salesforce/apex/sendle.fetchToAddress';
import fetchFromAddress from '@salesforce/apex/sendle.fetchFromAddress';
import fetchingPackages from '@salesforce/apex/sendle.fetchingPackages';
import fetchingPackageLists from '@salesforce/apex/sendle.fetchingPackageLists';
import getSendlePicklistValues from '@salesforce/apex/sendle.getSendlePicklistValues'
import saveShipment from '@salesforce/apex/sendle.saveShipment'
import saveLabels from '@salesforce/apex/sendle.saveLabels'

import getSendleQuote from '@salesforce/apex/APISendle.getSendleQuote';
import getSendleProduct from '@salesforce/apex/APISendle.getSendleProduct';
import createSendleOrder from '@salesforce/apex/APISendle.createSendleOrder';
import cancelSendleOrder from '@salesforce/apex/APISendle.cancelSendleOrder';
import sendleTrackShipment from '@salesforce/apex/APISendle.sendleTrackShipment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Sendle extends NavigationMixin(LightningElement) {
  sendle = sendleLogo;

  // Pickup date validation
  errorMessage = '';
  selectedDate;
  showError = false;
  // Open and close info & header
  isOpenOne = true;
  isOpenTwo = true;
  isOpenThree = true;
  isOpenFour = true;
  isDisabled = true;
  isPickDropDisabled = false
  isServiceDisabled = false
  errorList = [];

  showRatesButton = true;
  showInitiateButton = false;
  showLabelButton = false;
  showCancelButton = false


  // picklist for services
  @track picklistOptions = [];
  @track selectedPicklistValue = '';
  @track selectedRadioValue = ''; // holds the selected value
  @track productCode = ''; // To store the product code
  // Variable to store selected product details
  selectedProduct = {};

  // Initiate Order
  @track toInstructions = '';
  @track fromInstructions = '';
  @track packageDescription = '';
  @track hideDetails = false;
  @track packageDescriptionError = '';
  @track successMessage = '';  // Green success message
  @track showSuccessMessage = false;  // Red error message
  @track sendleOrderResponse = {};  // Initialize as an empty object
  @track sendleOrderError = {};  // Initialize as an empty object
  @track showOrderErrorMessage = false;
  @track showCancelMessage = false;
  @track cancelMessage = '';
  @track cancelOrderResponse = {}
  @track showLetter = false;
  @track showCropped = false;


  @track description = "Package";
  @track contentValue = 1;
  @track hsCodeValue = '330410';
  @track contentType = 'Other'

  contentTypeOptions = [
    { label: 'Documents', value: 'Documents' },
    { label: 'Gift', value: 'Gift' },
    { label: 'Merchandise', value: 'Merchandise' },
    { label: 'Returned Goods', value: 'Returned Goods' },
    { label: 'Sample', value: 'Sample' },
    { label: 'Other', value: 'Other' }
  ];

  @track showTrackingMessage = false;
  @track trackingMessage = '';
  @track trackingNumber = '';
  @track trackShipmentResponse = {};

  // Validation Errors
  @track toCountryError = '';
  @track fromCountryError = '';
  @track toStateError = '';
  @track fromStateError = '';
  @track toPostalCodeError = '';
  @track fromPostalCodeError = '';
  @track showProductCodeError = false;  // Tracks if the error should be displayed

  @track customerReferenceNumber = 'ORDER000001';  // Initial reference number

  // Sendle API credentials
  apiUsername = 'SANDBOX_mohammed_aymaan_axol';
  apiPassword = 'sandbox_B8Vkm4zV3GrsSHk2h4cszvzp';

  @track quoteResponse = {};  // To store the API response
  @track quoteErrorMessage = '';  // To store error messages
  @track productResponse = [];  // To store the API response
  @track productErrorMessage = '';  // To store error messages
  @track selectedProduct = null; // Holds the selected product object
  @track showProducts = false;  // Flag to control product visibility
  @track showQuotes = false;    // Flag to control quote visibility


  @api shipmentIds = '';
  @api packageIds = '';


  // To Address
  @track toAddress = {
    'Id': '',
    Name: '',
    Address_Line1__c: '',
    Address_Line2__c: '',
    City__c: '',
    State__c: '',
    Postal_Code__c: '',
    Country__c: '',
    Contact__r: {
      Id: '',
      Name: '',
      Company__c: '',
      Email: '',
      Phone: '',
    }
  };
  //  FROM Address
  @track fromAddress = {
    'Id': '',
    Name: '',
    Address_Line1__c: '',
    Address_Line2__c: '',
    City__c: '',
    State__c: '',
    Postal_Code__c: '',
    Country__c: '',
    Contact__c: '',
    Contact__r: {
      Id: '',
      Name: '',
      Company__c: '',
      Email: '',
      Phone: '',
    }
  };
  // From Contact
  @track fromContact = {
    Id: '',
    Name: '',
    Company__c: '',
    Email: '',
    Phone: '',
    AccountId: '',
    Account: {
      Id: '',
      Name: '',
      Phone: '',
      Email__c: ''
    }
  };
  // To contact
  @track toContact = {
    Id: '',
    Name: '',
    Company__c: '',
    Email: '',
    Phone: '',
    AccountId: '',
    Account: {
      Id: '',
      Name: '',
      Phone: '',
      Email__c: ''
    }
  };

  @track shipment = {
    Id: null,
    Name: '',
    Status__c: '',
    TrackingNumber__c: '',
    Label_options__c: 'LABEL',
    Invoice_Number__c: '',
    Purchase_Order_Number__c: '',
    Terms_Of_Shipment__c: '',
    Reason_For_Export__c: 'SAMPLE',
    Declaration_Statement__c: '',
    Shipment_Date__c: '',
    Description__c: '',
    Signature_Services__c: '',
    Shipment_Billing_options__c: 'SENDER',
    Fedex_Special_Services__c: '',
    Billing_Account_Number__c: '',
    Billing_Contact__c: '',
    Billing_Contact__r: {
      Id: '',
      Name: ''
    },
    Billing_Address__c: '',
    Billing_Address__r: {
      Id: '',
      Name: ''
    }
  };

  // Allowed countries list
  allowedCountries = [
    { code: 'AU', name: 'Australia' },
    { code: 'CA', name: 'Canada' },
    { code: 'US', name: 'United States' }
  ];

  // Define the radio options
  options = [
    { label: 'Pickup', value: 'pickup' },
    { label: 'DropOff', value: 'dropOff' }
  ];

  // Define a mapping of product codes based on picklist and radio selections
  productCodeMapping = {
    'Sendle Saver (USA)': {
      pickup: 'SAVER-PICKUP',
      dropOff: 'SAVER-DROPOFF',
    },
    'Sendle Preferred (USA)': {
      pickup: 'STANDARD-PICKUP',
      dropOff: 'STANDARD-DROPOFF',
    },
    'Sendle 3-Day Guaranteed (USA)': {
      pickup: 'THREE-DAY-PICKUP',
      dropOff: 'THREE-DAY-DROPOFF',
    },
    'Sendle 2-Day Guaranteed (USA)': {
      pickup: 'TWO-DAY-PICKUP',
      dropOff: 'TWO-DAY-DROPOFF',
    },
    'Sendle Ground Advantage Plus (USA)': {
      pickup: 'GROUND-ADVANTAGE-PICKUP',
      dropOff: 'GROUND-ADVANTAGE-DROPOFF',
    },
    'Sendle Priority Mail Plus (USA)': {
      pickup: 'PRIORITY-PICKUP',
      dropOff: 'PRIORITY-DROPOFF',
    },
    'Sendle Priority Mail Express Plus (USA)': {
      pickup: 'PRIORITY-EXPRESS-PICKUP',
      dropOff: 'PRIORITY-EXPRESS-DROPOFF',
    },
    'Sendle Standard (AU)': {
      pickup: 'STANDARD-PICKUP',
      dropOff: 'STANDARD-DROPOFF',
    },
    'Sendle Express (AU Pickup-Only)': {
      pickup: 'EXPRESS-PICKUP',
      dropOff: '',
    },
    'Sendle Preferred (CA)': {
      pickup: 'STANDARD-PICKUP',
      dropOff: 'STANDARD-DROPOFF',
    },
  };

  @track defaultWrap = {};
  @track packageItems = [];
  @track Credentials;

  @track showToAddress = true;
  @track showFromAddress = true;
  @track toAddressSelected = false;
  @track fromAddressSelected = false;
  @track billingAddressSelected = false;
  @track toAddressUrl = '';
  @track fromAddressUrl = '';
  @track toEmail = '';
  @track toPhone = '';
  @track isCompanyAvailable = false;
  @track isShipToContactAvailable = false;

  // Open and close info & header function
  toggleOne() {
    this.isOpenOne = !this.isOpenOne
  }
  toggleTwo() {
    this.isOpenTwo = !this.isOpenTwo
  }

  toggleThree() {
    this.isOpenThree = !this.isOpenThree
  }

  toggleFour() {
    this.isOpenFour = !this.isOpenFour
  }

  // Handle radio button change
  handleRadioChange(event) {
    this.selectedRadioValue = event.target.value;
    console.log('Selected Value:', this.selectedRadioValue);
    this.updateProductCode(); // Update product code when radio button selection changes
    this.showRatesButton = true;
    this.showInitiateButton = false;
  }

  // Wire the Apex method to get the filtered picklist values
  @wire(getSendlePicklistValues)
  wiredPicklistValues({ error, data }) {
    if (data) {
      // First, convert the data to the format suitable for lightning-comboBox
      this.picklistOptions = data.map(value => ({
        label: value,
        value: value
      }));

      // Assuming that "toAddress" and "fromAddress" contain country information
      const toAddressCountry = this.toAddressCountry
      const fromAddressCountry = this.fromAddressCountry

      // Filter the picklist options based on country
      this.picklistOptions = this.filterPicklistOptionsByCountry(this.picklistOptions, toAddressCountry, fromAddressCountry);

      console.log('Filtered Picklist Options:', this.picklistOptions);
    } else if (error) {
      // Handle error and show a toast notification
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error loading picklist values',
          message: error.body.message,
          variant: 'error'
        })
      );
    }
  }

  // Getter for dynamic toAddressCountry
  get toAddressCountry() {
    return this.getAddressCountry(this.toAddress.Country__c);
  }

  // Getter for dynamic fromAddressCountry
  get fromAddressCountry() {
    return this.getAddressCountry(this.fromAddress.Country__c);
  }

  // Utility method to extract country from an address (simple string search)
  getAddressCountry(address) {
    if (!address) return null;

    const addressLower = address.toLowerCase();

    if (addressLower.includes('canada') || addressLower.includes('ca')) {
      return 'CA';
    } else if (addressLower.includes('united states') || addressLower.includes('us')) {
      return 'USA';
    } else if (addressLower.includes('australia') || addressLower.includes('au')) {
      return 'AU';
    }

    return null;
  }

  // Utility method to filter picklist options based on country
  filterPicklistOptionsByCountry(picklistOptions, toAddressCountry, fromAddressCountry) {
    const countryCode = toAddressCountry || fromAddressCountry;

    if (countryCode) {
      return picklistOptions.filter(option => option.value.includes(countryCode));
    } else {
      this.isServiceDisabled = false;
      this.isPickDropDisabled = false;
      return picklistOptions; // If no country detected, return all options
    }

  }

  // Handle picklist change
  handleChange(event) {
    this.selectedPicklistValue = event.detail.value;
    console.log('Selected value: ' + this.selectedPicklistValue);
    this.updateProductCode(); // Update product code when selection changes
  }

  updateProductCode() {
    if (this.selectedPicklistValue && this.selectedRadioValue) {
      const code = this.productCodeMapping[this.selectedPicklistValue]?.[this.selectedRadioValue];
      this.productCode = code || ''; // Retrieve the code or reset if not found
      console.log(code);
    } else {
      this.productCode = ''; // Reset if selections are incomplete
    }
  }

  // Handle date change
  handleDateChange(event) {
    const selectedDate = new Date(event.target.value);
    const today = new Date();

    // Remove the time from today's date to only compare the day
    today.setHours(0, 0, 0, 0);

    // Move today to the next day (tomorrow) by adding 1 day
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Check if the selected date is before tomorrow
    if (selectedDate < tomorrow) {
      this.showError = true;
      this.errorMessage = 'Pick-up date must be at least one business day ahead.';
    }
    // Check if the selected date is a business day (not Saturday or Sunday)
    else if (selectedDate.getDay() === 0 || selectedDate.getDay() === 6) {
      this.showError = true;
      this.errorMessage = 'Pick-up date must be a business day (Monday to Friday).';
    }
    // If both conditions are met, clear the error and update the selected date
    else {
      this.showError = false;
      this.selectedDate = event.target.value;
    }
  }

  validateCountry(addressCountry, type) {
    const validCountry = this.allowedCountries.find(
      country => country.code === addressCountry || country.name === addressCountry
    );
    if (!validCountry) {
      if (type === 'to') {
        this.toCountryError = 'Invalid country for the "To" address. Allowed: Australia, Canada, United States.';
      } else {
        this.fromCountryError = 'Invalid country for the "From" address. Allowed: Australia, Canada, United States.';
      }
    } else {
      if (type === 'to') this.toCountryError = '';
      else this.fromCountryError = '';
    }
  }

  validateState(addressState, addressCountry, type) {
    const validStates = {
      'Australia': ['ACT', 'QLD', 'NSW', 'New South Wales', 'Victoria', 'VIC',
        'WA', 'Western Australia', 'SA', 'South Australia',
        'TAS', 'Tasmania', 'NT', 'Northern Territory'],
      'Canada': ['ON', 'Ontario', 'AB', 'Alberta', 'BC', 'British Columbia',
        'QC', 'Quebec', 'MB', 'Manitoba', 'NB', 'New Brunswick',
        'NL', 'Newfoundland and Labrador', 'NS', 'Nova Scotia',
        'NT', 'Northwest Territories', 'NU', 'Nunavut',
        'PE', 'Prince Edward Island', 'SK', 'Saskatchewan', 'YT', 'Yukon'],
      'United States': ['AL', 'Alabama', 'AK', 'Alaska', 'AZ', 'Arizona', 'AR', 'Arkansas',
        'CA', 'California', 'CO', 'Colorado', 'CT', 'Connecticut', 'DE', 'Delaware',
        'FL', 'Florida', 'GA', 'Georgia', 'HI', 'Hawaii', 'ID', 'Idaho',
        'IL', 'Illinois', 'IN', 'Indiana', 'IA', 'Iowa', 'KS', 'Kansas',
        'KY', 'Kentucky', 'LA', 'Louisiana', 'ME', 'Maine', 'MD', 'Maryland',
        'MA', 'Massachusetts', 'MI', 'Michigan', 'MN', 'Minnesota',
        'MS', 'Mississippi', 'MO', 'Missouri', 'MT', 'Montana',
        'NE', 'Nebraska', 'NV', 'Nevada', 'NH', 'New Hampshire',
        'NJ', 'New Jersey', 'NM', 'New Mexico', 'NY', 'New York',
        'NC', 'North Carolina', 'ND', 'North Dakota', 'OH', 'Ohio',
        'OK', 'Oklahoma', 'OR', 'Oregon', 'PA', 'Pennsylvania',
        'RI', 'Rhode Island', 'SC', 'South Carolina', 'SD', 'South Dakota',
        'TN', 'Tennessee', 'TX', 'Texas', 'UT', 'Utah', 'VT', 'Vermont',
        'VA', 'Virginia', 'WA', 'Washington', 'WV', 'West Virginia',
        'WI', 'Wisconsin', 'WY', 'Wyoming']
    };

    if (validStates[addressCountry] && !validStates[addressCountry].includes(addressState)) {
      if (type === 'to') {
        this.toStateError = `Invalid state for ${addressCountry}.`;
      } else {
        this.fromStateError = `Invalid state for ${addressCountry}.`;
      }
    } else {
      if (type === 'to') this.toStateError = '';
      else this.fromStateError = '';
    }
  }

  validatePostalCode(addressPostalCode, addressCountry, type) {
    const postalCodePatterns = {
      'Australia': /^\d{4}$/, // 4-digit postcode
      'Canada': /^[A-Za-z]\d[A-Za-z] ?\d[A-Za-z]\d$/, // Canadian postal code (A1A 1A1)
      'United States': /^\d{5}(-\d{4})?$/ // US ZIP code (5-digit or ZIP+4)
    };

    if (!postalCodePatterns[addressCountry].test(addressPostalCode)) {
      if (type === 'to') {
        this.toPostalCodeError = `Invalid postal code for ${addressCountry}.`;
      } else {
        this.fromPostalCodeError = `Invalid postal code for ${addressCountry}.`;
      }
    } else {
      if (type === 'to') this.toPostalCodeError = '';
      else this.fromPostalCodeError = '';
    }
  }

  // Validate To Address
  validateToAddress() {
    this.validateCountry(this.toAddress.Country__c, 'to');
    this.validateState(this.toAddress.State__c, this.toAddress.Country__c, 'to');
    this.validatePostalCode(this.toAddress.Postal_Code__c, this.toAddress.Country__c, 'to');
  }

  // Validate From Address
  validateFromAddress() {
    this.validateCountry(this.fromAddress.Country__c, 'from');
    this.validateState(this.fromAddress.State__c, this.fromAddress.Country__c, 'from');
    this.validatePostalCode(this.fromAddress.Postal_Code__c, this.fromAddress.Country__c, 'from');
  }

  // Generate a random reference number
  autoGenerateReferenceNumber() {
    // Generate a random number between 0 and 999999
    let randomNumber = Math.floor(Math.random() * 1000000);

    // Format the random number with leading zeros
    this.customerReferenceNumber = 'ORDER' + String(randomNumber).padStart(6, '0');

    console.log('Generated Random Customer Reference Number:', this.customerReferenceNumber);
  }

  connectedCallback() {
    this.getToAddress();
    this.getFromAddress();
    this.getData();
    this.getPackageDetails();
    this.getPackageItemsDetails();
    this.autoGenerateReferenceNumber();  // Auto-generate the reference number
    this.optionsDisabled();
  }

  // Getting initial data
  getData() {
    getInitialData({ ShipId: this.shipmentIds, packIds: JSON.stringify(this.packageIds) })
      .then(result => {
        console.log('result getInitialData: ', JSON.stringify(result));
        if (result) {
          if (result.alertList && result.alertList.length > 0) {
            this.errorList = Object.assign([], result.alertList);
          }
          else {
            this.defaultWrap = result;
            this.Credentials = result.credWrap;
            if (this.shipmentIds) {
              if (!result.ship.Billing_Contact__c) {
                result.ship.Billing_Contact__c = '';
                result.ship.Billing_Contact__r = { Id: '', Name: '' };
              }
              if (!result.ship.Billing_Address__c) {
                result.ship.Billing_Address__c = '';
                result.ship.Billing_Address__r = { Id: '', Name: '' };
              }
              this.shipment = result.ship;
              console.log('Name : ', this.shipment.Name);
            }

            if (result.toAddress && Object.keys(result.toAddress).length !== 0) this.toAddress = result.toAddress;
            else this.errorList.push('To Address is missing on your logistics.');

            if (result.fromAddress && Object.keys(result.fromAddress).length !== 0) this.fromAddress = result.fromAddress;
            else this.errorList.push('From Address is missing on your logistics.');
            // from address
            if (this.fromAddress.Id) {
              this.fromAddressSelected = true;
              this.fromAddressUrl = '/' + this.fromAddress.Id;
            }
            // to address
            if (this.toAddress.Id) {
              this.toAddressSelected = true;
              this.toAddressUrl = '/' + this.toAddress.Id;
            }
            console.log('result.fromContact : ', JSON.stringify(result.fromContact));
            //  from contact
            if (result.fromContact && Object.keys(result.fromContact).length !== 0) this.fromContact = result.fromContact;
            else this.errorList.push('From contact is missing on your logistics.');
            //  to contact
            if (result.toContact && Object.keys(result.toContact).length !== 0) this.toContact = result.toContact;
            else this.errorList.push('To contact is missing on your logistics.');
            for (var x in result.packList) {
              result.packList[x].packUrl = '/' + result.packList[x].Id;
            }
            // packList
            if (result.packList && result.packList.length > 0) {
              console.log("entered result packList:", JSON.stringify(result.packList));
              if (result.packList[0].Logistic__r != null) { if (result.packList[0].Logistic__r.Billing_options__c) this.shipment.Shipment_Billing_options__c = result.packList[0].Logistic__r.Billing_options__c; }
              else this.shipment.Shipment_Billing_options__c = 'SENDER';
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
              if (result.packList[0].Logistic__r != null) {
                if (result.packList[0].Logistic__r.Billing_Address__c) { this.shipment.Billing_Address__c = result.packList[0].Logistic__r.Billing_Address__c; }
              }
              if (result.packList[0].Logistic__r != null) {
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
              this.shipment.Billing_Account_Number__c = result.packList[0].Logistic__r != null ? result.packList[0].Logistic__r.Billing_Account_number__c : '';
            }
            this.packageList = result.packList;
            console.log('packageList==>' + JSON.stringify(this.packageList));
            this.packageItems = result.packItems;
          }
        }
      })
  }
  // fetchToAddress
  getToAddress() {
    console.log('packId===' + JSON.stringify(this.packageIds));
    fetchToAddress({ packId: JSON.stringify(this.packageIds) })
      .then(result => {
        if (result) {
          console.log('result fetchToAddress: ', result);
          this.toAddress = result;
          this.toAddress.Id = result.Id;
          this.toAddress.Name = result.Name;
          this.toAddressUrl = '/' + this.toAddress.Id;
          if (result.Contact__c && result.Contact__r.Company__c) this.isCompanyAvailable = true;
          if (result.Contact__c && result.Contact__r.Name) this.isShipToContactAvailable = true;
          this.toEmail = (result.Contact__c && result.Contact__r.Email) ? result.Contact__r.Email : result.Customer__r.Email__c;
          this.toPhone = (result.Contact__c && result.Contact__r.Phone) ? result.Contact__r.Phone : result.Customer__r.Phone;
          this.toAddressSelected = true;
        }
      })
      .catch(error => {
        console.log('Error:', error);
        this.errorList = Object.assign([], this.errorList);
        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
      })
  }

  // fetchFromAddress
  getFromAddress() {
    fetchFromAddress({ packId: JSON.stringify(this.packageIds) })
      .then(result => {
        if (result) {
          console.log('result fetchFromAddress: ', result);
          this.fromAddress = result;
          this.fromAddress.Id = result.Id;
          this.fromAddress.Name = result.Name;
          this.fromAddressUrl = '/' + this.fromAddress.Id;
          if (result.Contact__c && result.Contact__r.Company__c) this.isCompanyAvailable = true;
          if (result.Contact__c && result.Contact__r.Name) this.isShipToContactAvailable = true;
          this.FromEmail = (result.Contact__c && result.Contact__r.Email) ? result.Contact__r.Email : result.Customer__r.Email__c;
          this.fromPhone = (result.Contact__c && result.Contact__r.Phone) ? result.Contact__r.Phone : result.Customer__r.Phone;
          this.fromAddressSelected = true;
        }
      })
      .catch(error => {
        console.log('Error:', error);
        this.errorList = Object.assign([], this.errorList);
        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
      })
  }

  getPackageDetails() {
    fetchingPackages({ packId: JSON.stringify(this.packageIds) })
      .then(result => {
        if (result) {
          console.log('result fetchingPackages: ', result);
          for (var x in result) {
            result[x].packUrl = '/' + result[x].Id;
          }
          this.packageList = result;
        }
      })
      .catch(error => {
        console.log('Error:', error);
        this.errorList = Object.assign([], this.errorList);
        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
      })
  }
  getPackageItemsDetails() {
    fetchingPackageLists({ packId: JSON.stringify(this.packageIds) })
      .then(result => {
        if (result) {
          console.log('result fetchingPackageLists: ', result);
          for (var x in result) {
            result[x].packUrl = result[x].Id;
          }
          this.packageItems = result;
        }
      })
      .catch(error => {
        console.log('Error:', error);
        this.errorList = Object.assign([], this.errorList);
        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
      })
  }

  optionsDisabled() {
    // Compare the toAddress and fromAddress country values
    const toCountry = this.toAddress.Country__c;
    const fromCountry = this.fromAddress.Country__c;
    // Normalize the country values for comparison
    const normalizedToCountry = toCountry.toLowerCase();
    const normalizedFromCountry = fromCountry.toLowerCase();

    if (normalizedFromCountry != 'united states' || 'us' || 'usa') {
      this.isServiceDisabled = true;
      this.isPickDropDisabled = true
    }
  }
  getRates() {

    this.validateAllAddresses();
    this.validateProductCode();

    console.log('getRates triggered');

    // Compare the toAddress and fromAddress country values
    const toCountry = this.toAddress.Country__c;
    const fromCountry = this.fromAddress.Country__c;

    // Normalize the country values for comparison
    const normalizedToCountry = toCountry.toLowerCase();
    const normalizedFromCountry = fromCountry.toLowerCase();

    if (normalizedFromCountry != 'united states' || 'us' || 'usa') {
      // If to and from addresses are the same, fetch and display only products
      this.showProducts = true;
      this.showQuotes = false;
      this.isServiceDisabled = true;
      this.isPickDropDisabled = true
      console.log('Addresses match, fetching only product');
      this.fetchProduct()
        .then(() => {
          console.log('Product fetched successfully');
          // Handle product display logic here
        })
        .catch(error => {
          console.error('Error while fetching product:', error);
        });
    } else {
      // If to and from addresses are different, fetch and display only quotes
      this.showProducts = false;
      this.showQuotes = true;
      console.log('Addresses differ, fetching only quotes');
      this.fetchQuote()
        .then(() => {
          console.log('Quotes fetched successfully');
          // Handle quotes display logic here
        })
        .catch(error => {
          console.error('Error while fetching quote:', error);
        });
    }

  }

  // Method to validate both addresses on button click
  validateAllAddresses() {
    this.validateToAddress();
    this.validateFromAddress();
  }

  // Validate Product Code when button is clicked
  validateProductCode() {
    if (this.productCode === '' || this.productCode === null || this.productCode.trim() === '') {
      this.showProductCodeError = true;  // Show error if the product code is empty
    } else {
      this.showProductCodeError = false;  // No error if product code is valid
      // Proceed with further logic (e.g., submit the form or perform some action)
      console.log('Product code is valid: ' + this.productCode);
    }
  }

  // Helper function to convert object to query string
  objectToQueryString(params) {
    return Object.keys(params)
      .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(params[key]))
      .join('&');
  }

  // Handle product selection and store all relevant data
  handleProductSelection(event) {
    const selectedProductName = event.target.value;
    const selectedProductCode = event.target.value;

    console.log('Selected Product Code:', selectedProductCode);  // Ensure this logs the correct value

    // Find the selected product in the productResponse array
    this.selectedProduct = this.productResponse.find(
      product => product.productName === selectedProductName,
      product => product.productCode === selectedProductCode
    );

    console.log('Selected Product: ', this.selectedProduct);

    // Now you can access any stored data like pickupDate or productCode
    console.log('Selected Pickup Date: ', this.selectedProduct.pickupDate);
    this.selectedDate = this.selectedProduct.pickupDate;
    console.log('Selected Product Code: ', this.selectedProduct.productCode);
    this.productCode = this.selectedProduct.productCode
    this.showProductCodeError = false;

    this.showRatesButton = false;
    this.showInitiateButton = true;

  }

  // Method to fetch the quote from Sendle API
  fetchQuote() {

    return new Promise((resolve, reject) => {
      console.log('Fetching Sendle quote');
      // Collect weight details
      const weightElements = this.template.querySelectorAll('[data-weight]');
      let totalWeight = 0;
      let weightUnit = 'lb'
      weightElements.forEach(element => {
        totalWeight += parseFloat(element.dataset.weight);  // Add weight
        let wUnit = element.dataset.weightUnit;
        if (wUnit === 'LBS' || wUnit === 'lbs') {
          let weightUnit = 'lb'
          console.log('Weight_units:', weightUnit);
        }
        else {
          let weightUnit = 'kg'
          console.log('Weight_units:', weightUnit);
        }
      });

      // Prepare the JSON request body
      const requestParams = {
        pickup_suburb: this.fromAddress.City__c,
        pickup_postcode: this.fromAddress.Postal_Code__c,
        pickup_country: this.fromAddress.Country__c,
        delivery_suburb: this.toAddress.City__c,
        delivery_postcode: this.toAddress.Postal_Code__c,
        delivery_country: this.toAddress.Country__c,
        weight_units: weightUnit,
        weight_value: totalWeight,
        product_code: this.productCode
      };
      console.log("Request body~~~~>", JSON.stringify(requestParams))
      const queryString = this.objectToQueryString(requestParams);
      console.log(queryString)

      // Call Apex method
      getSendleQuote({ queryString })
        .then(result => {
          const parsedResult = JSON.parse(result);

          // Check if there is an error message
          if (parsedResult.errorMessage) {
            this.quoteErrorMessage = parsedResult.errorMessage;  // Set the error message
            this.quoteResponse = {};  // Clear quote data
          } else {
            this.quoteResponse = parsedResult;  // Set the formatted quote data
            this.selectedDate = this.quoteResponse.pickupDate;
            this.quoteErrorMessage = '';  // Clear any previous error message
          }
        })
        .catch(error => {
          console.error('Error fetching quote:', error);
          this.quoteErrorMessage = ['An unexpected error occurred. Please try again later.',
            error.body.message || 'Unknown Error Occurred'];
          this.quoteResponse = {};  // Clear any previous quote data
        });
      this.showRatesButton = false;
      this.showInitiateButton = true;
    });
  }

  fetchProduct() {

    return new Promise((resolve, reject) => {
      console.log('Fetching Sendle product');
      // Collect weight details
      const weightElements = this.template.querySelectorAll('[data-weight]');
      let totalWeight = 0;
      let weightUnit = 'lb'
      weightElements.forEach(element => {
        totalWeight += parseFloat(element.dataset.weight);  // Add weight
        let wUnit = element.dataset.weightUnit;
        if (wUnit === 'LBS' || wUnit === 'lbs') {
          let weightUnit = 'lb'
          console.log('Weight_units:', weightUnit);
        }
        else {
          let weightUnit = 'kg'
          console.log('Weight_units:', weightUnit);
        }
      });

      // Prepare the JSON request body
      const requestParams = {
        sender_suburb: this.fromAddress.City__c,
        sender_postcode: this.fromAddress.Postal_Code__c,
        sender_country: this.fromAddress.Country__c,
        receiver_suburb: this.toAddress.City__c,
        receiver_postcode: this.toAddress.Postal_Code__c,
        receiver_country: this.toAddress.Country__c,
        weight_units: weightUnit,
        weight_value: totalWeight,
      };
      console.log("Request params :", JSON.stringify(requestParams))
      const queryString = this.objectToQueryString(requestParams);
      console.log(queryString)

      // Call Apex method
      getSendleProduct({ queryString })
        .then(result => {
          this.productQuotes = JSON.parse(result);
          this.productResponse = this.productQuotes
          console.log('Formatted Product Quotes:', this.productResponse);
        })
        .catch(error => {
          console.error('Error fetching product details:', error);
          this.errorMessage = error.body ? error.body.message : 'Unknown error occurred';
        });
    });
  }

  toInstructionsChange(event) {
    this.toInstructions = event.target.value
    console.log(this.toInstructions)
  }

  fromInstructionsChange(event) {
    this.fromInstructions = event.target.value
    console.log(this.fromInstructions)
  }

  handlePackageDescription(event) {
    this.packageDescription = event.target.value
    this.description = this.packageDescription
    console.log(this.packageDescription)
  }

  // Handler to capture the change event and store the selected value
  handleContentTypeChange(event) {
    this.contentType = event.detail.value;
  }

  valueChange(event) {
    this.contentValue = event.target.value
  }

  hsCode(event) {
    this.hsCodeValue = event.target.value
  }

  handleHideSelect(event) {
    this.hideDetails = event.target.checked
    console.log(this.hideDetails)
  }

  InitiateOrder() {
    if (this.showOrderErrorMessage == true) {
      this.showSuccessMessage = false;
      this.showInitiateButton = true;
      this.showOrderErrorMessage = true;
    } else {
      // Initiate the order creation process (assuming createOrder is async)
      try {
        this.createOrder();
        // Update the UI states after order creation
        this.showProducts = false;
        this.showQuotes = false;
        this.showInitiateButton = false;
        this.showLabelButton = true; // Show the label button
        this.showCancelButton = true
        this.showSuccessMessage = true; // Show success message
        this.showCancelOrder = true;
        this.showOrderErrorMessage = false
        setTimeout(() => {
          this.createShipment();
          this.successMessage = 'Shipment created successfully!'; // Set success message
        }, 5000);

      } catch (error) {
        console.error('Error creating order:', error);
        this.showSuccessMessage = false;
        this.showInitiateButton = true;
        this.showLabelButton = false; // Show the label button
        this.showCancelButton = false
        this.showCancelOrder = false;
      }
    }
  }

  createOrder() {
    return new Promise((resolve, reject) => {

      console.log("Weight :-> ")
      const weightElements = this.template.querySelectorAll('[data-weight]');
      let totalWeight = 0;
      let weightUnit = 'lb'
      weightElements.forEach(element => {
        totalWeight += parseFloat(element.dataset.weight);  // Add weight
        let wUnit = element.dataset.weightUnit;
        if (wUnit === 'LBS' || wUnit === 'lbs') {
          let weightUnit = 'lb'
          console.log('units:', weightUnit);
        }
        else {
          let weightUnit = 'kg'
          console.log('units:', weightUnit);
        }
      });
      console.log("Value : ", totalWeight);
      console.log("Dimensions :->")
      console.log('units:', 'in');

      const widthElement = this.template.querySelectorAll('[data-width]')
      let widthValue = 1
      widthElement.forEach(element => {
        widthValue = parseFloat(element.dataset.width);
        console.log("Width : ", widthValue)
      })
      const heightElement = this.template.querySelectorAll('[data-height]')
      let heightValue = 1
      heightElement.forEach(element => {
        heightValue = parseFloat(element.dataset.height);
        console.log("Height : ", heightValue)
      })
      const lengthElement = this.template.querySelectorAll('[data-l]')
      let lengthValue = 1
      lengthElement.forEach(element => {
        lengthValue = parseFloat(element.dataset.l)
        console.log("Length : ", lengthValue)
      })


      const requestBody = {
        sender: {
          contact: {
            name: this.fromAddress.Contact__r.Name,
            email: this.fromAddress.Contact__r.Email,
            phone: this.fromAddress.Contact__r.Phone,
            company: this.fromAddress.Contact__r.Company__c,
          },
          address: {
            country: this.fromAddress.Country__c,
            address_line1: this.fromAddress.Address_Line1__c,
            address_line2: this.fromAddress.Address_Line2__c || null,
            suburb: this.fromAddress.City__c,
            postcode: this.fromAddress.Postal_Code__c,
            state_name: this.fromAddress.State__c,
          },
          instructions: this.toInstructions || "null",
        },
        receiver: {
          contact: {
            name: this.toAddress.Contact__r.Name,
            email: this.toAddress.Contact__r.Email,
            phone: this.toAddress.Contact__r.Phone,
            company: this.toAddress.Contact__r.Company__c,
          },
          address: {
            country: this.toAddress.Country__c,
            address_line1: this.toAddress.Address_Line1__c,
            address_line2: this.toAddress.Address_Line2__c || null,
            suburb: this.toAddress.City__c,
            postcode: this.toAddress.Postal_Code__c,
            state_name: this.toAddress.State__c,
          },
          instructions: this.fromInstructions || "null",
        },
        weight: {
          units: weightUnit,
          value: totalWeight,
        },
        dimensions: {
          units: 'in',
          length: lengthValue,
          width: widthValue,
          height: heightValue,
        },
        description: this.description || 'None Given',
        customer_reference: this.customerReferenceNumber,
        product_code: this.productCode,
        pickup_date: this.selectedDate,
        packaging_type: 'box',
        hide_pickup_address: this.hideDetails,
        contents_type: this.contentType,
        parcel_contents: [
          {
            description: this.description,
            value: this.contentValue,
            country_of_origin: this.fromAddress.Country__c,
            hs_code: this.hsCodeValue
          }
        ]
      }
      console.log("Request body :", JSON.stringify(requestBody))
      const orderDetails = JSON.stringify(requestBody);

      createSendleOrder({ orderDetails })
        .then(result => {
          console.log("Result :", result)
          // Check if the result contains the word "error"
          if (typeof result === 'string' && result.toLowerCase().includes('error')) {
            console.error("Error in order creation response:", result);
            this.showOrderErrorMessage = true;
            this.sendleOrderError = JSON.parse(result) || result
          } else {
            this.sendleOrderResponse = JSON.parse(result) || result
            console.log("Formatted Response: ", this.sendleOrderResponse);
          }
        })
        .catch(error => {
          console.log("Error :", error)
        })
    })

  }

  // Getter for order ID
  get orderId() {
    return this.sendleOrderResponse.order_id;
  }

  // Getter for Sendle reference
  get sendleReference() {
    this.trackingNumber = this.sendleOrderResponse.sendle_reference
    return this.sendleOrderResponse.sendle_reference;
  }

  // Getter for expiry date
  get expiryDate() {
    const expiresAt = new Date(this.sendleOrderResponse.expires_at);
    return expiresAt ? expiresAt.toDateString() : 'No expiry date available';
  }

  // Getter for route description
  get routeDescription() {
    const route = this.sendleOrderResponse.route || {};
    return `${route.description || 'No description'} (${route.type || 'No type'}), Delivery Guarantee: ${route.delivery_guarantee_status || 'Not available'}`;
  }

  ShowLabel() {
    this.showLabelButton = false
    this.showLetter = true
    this.showCropped = true
  }

  LetterLabel() {
    // Find the cropped label
    const croppedLabel = this.sendleOrderResponse.labels.find(label => label.size === 'letter');

    if (croppedLabel && croppedLabel.url) {
      // Open the cropped label PDF in a new tab
      window.open(croppedLabel.url, '_blank');
    } else {
      console.error('Cropped PDF URL not found');
    }
  }

  CroppedLabel() {
    // Find the cropped label
    const croppedLabel = this.sendleOrderResponse.labels.find(label => label.size === 'cropped');

    if (croppedLabel && croppedLabel.url) {
      // Open the cropped label PDF in a new tab
      window.open(croppedLabel.url, '_blank');
    } else {
      console.error('Cropped PDF URL not found');
    }
  }

  InitiateCancelOrder() {
    this.successMessage = '';
    this.showSuccessMessage = false;
    this.cancelOrder();
  }

  cancelOrder() {
    return new Promise((resolve, reject) => {
      console.log("Cancel Order")

      cancelSendleOrder({ cancelId: this.orderId })
        .then(result => {
          console.log("Cancel Order Result :", result)
          this.cancelOrderResponse = JSON.parse(result)
          console.log("Formatted Response: ", this.cancelOrderResponse);
          this.cancelMessage = "Order Cancelled Successfully"
          this.showCancelMessage = true;
        })
        .catch(error => {
          console.error('Error cancelling order:', error);
          this.cancelMessage = ['An unexpected error occurred. Please try again later.',
            error.body.message || 'Unknown Error Occurred'];
          this.showCancelMessage = true;
        });
    })
  }

  get cancelledOrderId() {
    return this.cancelOrderResponse.order_id;
  }

  get cancelState() {
    return this.cancelOrderResponse.state;
  }

  get cancelledSendleReference() {
    this.trackingNumber = this.cancelOrderResponse.sendle_reference
    return this.cancelOrderResponse.sendle_reference;
  }

  get cancelledAt() {
    return this.cancelOrderResponse.cancelled_at
  }

  get cancelMessage() {
    return this.cancelOrderResponse.cancellation_message
  }

  initiateTrackShipment() {
    this.trackShipment();
  }

  trackShipment() {
    return new Promise((resolve, reject) => {
      console.log("Track Shipment")

      sendleTrackShipment({ trackingNumber: this.trackingNumber })
        .then(result => {
          console.log("Track Shipment Result :", result)
          this.trackShipmentResponse = JSON.parse(result)
          console.log("Formatted Response: ", this.trackShipmentResponse);
          this.trackingMessage = "Tracking Status : "
          this.showTrackingMessage = true;
        })
        .catch(error => {
          console.error('Error tracking shipment:', error);
          this.trackingMessage = ['An unexpected error occurred. Please try again later.',
            error.body.message || 'Unknown Error Occurred'];
          this.showTrackingMessage = true;
        });
    })
  }

  get trackingStatus() {
    return this.trackShipmentResponse.status.last_changed_at || 'Not available';
  }

  get trackingDescription() {
    return this.trackShipmentResponse.status.description || 'Not available';
  }

  get trackingStatusDelivered_on() {
    return this.trackShipmentResponse.scheduling.delivered_on || 'Not available';
  }

  get trackingStatusPickup_on() {
    return this.trackShipmentResponse.scheduling.pick_up_on || 'Not available';
  }

  get trackingStatusPickup_date() {
    return this.trackShipmentResponse.scheduling.pickup_date || 'Not available';
  }

  get trackingEstimationMin() {
    return this.trackShipmentResponse.scheduling.estimated_delivery_date_minimum || 'Not available';
  }

  get trackingEstimationMax() {
    return this.trackShipmentResponse.scheduling.estimated_delivery_date_maximum || 'Not available';
  }

  createShipment() {
    console.log("Create Shipment");

    let sendleData = [];
    var data = {
      name: "Sendle-" + this.customerReferenceNumber,
      service: this.productCode,
      track: this.sendleReference,
      orderId: this.orderId,
      package: this.packageList[0].Id,
      packageWeight: this.packageList[0].Weight__c,
      packageWeightUNit: this.packageList[0].Weight_Unit__c,
      order: this.packageList[0].Order__c,
      TO: this.packageList[0].Transfer_Order__c,
      SO: this.packageList[0].Sales_Order__c,
      RMA: this.packageList[0].Return_Merchandise_Authorisation__c
    };

    sendleData.push(data);
    console.log(JSON.stringify(sendleData))

    // Save the shipment data
    saveShipment({ items: JSON.stringify(sendleData) })
      .then((shipmentId) => {

        console.log("Shipment saved successfully");
        // Fetch label URLs
        const letterLabel = this.sendleOrderResponse.labels.find(label => label.size === 'letter');
        const croppedLabel = this.sendleOrderResponse.labels.find(label => label.size === 'cropped');
        console.log(letterLabel)
        const id = shipmentId[0]
        console.log(id)
        // Save the labels as attachments related to the shipment
        if (letterLabel) {
          this.uploadLabel(id, letterLabel, 'LetterLabel.pdf');
        }
        if (croppedLabel) {
          this.uploadLabel(id, croppedLabel, 'CroppedLabel.pdf');
        }
        this.showSuccessMessage = true;
      })
      .catch(error => {
        console.error("Error saving shipment:", error);
        this.sendleOrderError = "Error saving shipment-", error;
        this.showOrderErrorMessage = true; // Show error message if save fails
        this.showSuccessMessage = false;
        this.showInitiateButton = true; // Show the initiate button
        this.showCancelButton = false;
        this.showLabelButton = false;
      });
  }

  // Helper method to upload a label file
  uploadLabel(shipmentId, fileUrl, fileName) {
    fetch(fileUrl)
      .then(response => response.blob())
      .then(blob => {
        const reader = new FileReader();
        reader.onloadend = () => {
          const base64data = reader.result.split(',')[1]; // Extract base64 data

          // Call Apex method to save the file
          saveLabels({ parentId: shipmentId, fileName: fileName, base64Data: base64data })
            .then(() => console.log(`${fileName} uploaded successfully`))
            .catch(error => console.error(`Error uploading ${fileName}:`, error));
        };
        reader.readAsDataURL(blob);
      })
      .catch(error => console.error("Error fetching label:", error));
  }
}