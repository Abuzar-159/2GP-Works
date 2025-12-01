import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';

import freightviewLogo from '@salesforce/resourceUrl/freightviewLogo';
import getInitialData from '@salesforce/apex/freightView.getDefaultData';
import shippingRequestResponse from '@salesforce/apex/freightView.shippingRequestResponse';
import getQuoteRates from '@salesforce/apex/freightView.getQuoteRates';
import getShipmentDocs from '@salesforce/apex/freightView.getShipmentDocs';
import getTrackingHistory from '@salesforce/apex/freightView.getTrackingHistory';
import getContactPhone from '@salesforce/apex/freightView.getContactPhone';
import requestTruckloadRFQ from '@salesforce/apex/freightView.requestTruckloadRFQ';
import addManualTruckloadQuote from '@salesforce/apex/freightView.addManualTruckloadQuote';
import getPackageEquipmentTypes from '@salesforce/apex/freightView.getPackageEquipmentTypes';
import getManualQuotes from '@salesforce/apex/freightView.getManualQuotes';
import confirmTruckloadManualSimplified from '@salesforce/apex/freightView.confirmTruckloadManualSimplified';
import cancelTruckloadShipment from '@salesforce/apex/freightView.cancelTruckloadShipment';


// lables 
import shipmentGoing from "@salesforce/label/c.X1_Where_is_this_shipment_going";
import validateAddress from "@salesforce/label/c.Validate_Address";
import CompanyLabel from "@salesforce/label/c.CompanyLabel";
import ContactLabel from "@salesforce/label/c.ContractConsole_Contact";
import PhoneLabel from "@salesforce/label/c.Phone_AddTimeCardEntry";

export default class freightview extends NavigationMixin(LightningElement) {
    freightviewImg = freightviewLogo;

    label = {
        validateAddress,
        shipmentGoing,
        CompanyLabel,
        ContactLabel,
        PhoneLabel
    };

    // ==============================================
    // ✨ NEW ACCORDION PROPERTIES & HANDLER ADDED HERE ✨
    // ==============================================
    // This controls which sections of the main form accordion are open.
    // Initialized to keep the 'destination' section open by default.
    @track activeSections = ['destination']; 

    // Handler for the main form accordion (optional, but good practice)
    handleAccordionToggle(event) {
        // Updates the list of currently open sections
        this.activeSections = event.detail.openSections;
        console.log('Main form accordion open sections: ' + this.activeSections);
    }
    // ==============================================
    // END ACCORDION PROPERTIES
    // ==============================================

    @track isLoading = false;
    @track toContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' }, Company__r: { Id: '', Name: '' } };
    @track fromAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Contact__c: '', Contact__r: { Id: '', Name: '', Company__c: '' }, Customer__c: '', Customer__r: { Id: '', Name: '', Company_txt__c: '' }, opens_at__c: '', closes_at__c: '' };
    @track shipment = { Id: null, Name: '', emergency_contact__c: '', emergency_contact__r: { Id: '', Name: '', Phone: '' }, schedulePickup__c: true, Status__c: '', TrackingNumber__c: '', Label_options__c: 'LABEL', Invoice_Number__c: '', Purchase_Order_Number__c: '', Terms_Of_Shipment__c: '', Reason_For_Export__c: 'SAMPLE', Declaration_Statement__c: '', Shipment_Date__c: '', Description__c: '', Signature_Services__c: '', Shipment_Billing_options__c: 'SENDER', Fedex_Special_Services__c: '', Billing_Account_Number__c: '', Billing_Contact__c: '', Billing_Contact__r: { Id: '', Name: '' }, Billing_Address__c: '', Billing_Address__r: { Id: '', Name: '' }, shipmentID__c: '', isLiveLoad__c: true };
    @track fromContact = { Id: '', Name: '', Company__c: '', Email: '', Phone: '', AccountId: '', Account: { Id: '', Name: '', Phone: '', Email__c: '' }, Company__r: { Id: '', Name: '' } };
    @track toAddress = { 'Id': '', Name: '', Address_Line1__c: '', Address_Line2__c: '', City__c: '', State__c: '', Postal_Code__c: '', Country__c: '', Customer__c: '', Customer__r: { Id: '', Name: '', Company_txt__c: '' }, opens_at__c: '', closes_at__c: '' };
    @track FromAddressSelected = false;
    @track toAddressSelected = false;
    @track toShipmentType = false;
    @track fromShipmentType = false;
    @track packageItems = [];
    @track isShipmentRatesOpen = false;

    @api returnmaid;
    @api refundamt;
    @api issaccess;
    @api isorderacc;
    @api packageIds = [];
    @api shipId = '';
    @api shipmentIds = '';
    @api packageList;
    @track quotes;
    @track showCreateShipment = true;
    @track FVshipmentID = '';
    @track trackingList = [];

    @track isBillingAddressSelected = false;
    @track isBillingContactSelected = false;

    @track BillingAddressUrl = '';
    @track BillingContactUrl = '';
    @track BillingAddressName = '';
    @track BillingContactName = '';

    errorList = [];
    docIds = {};
    defaulWrap;
    disableBillingOption;

    @track shipmentMode = 'LTL';
    @track tlStops = [];

    // rfq
    @track requestedFrom = [];
    rfqEmailsText = '';
    rfqMessage = '';
    rfqSending = false;

    // mqv
    mqAmount;
    mqCurrency = 'USD';
    mqCarrierEmail;
    mqAutoCreateCarrierName;
    mqCarrierName;
    mqQuoteNum;
    mqExpiresAt;
    mqTransitDays;
    mqEquipmentType;
    mqNotes;
    mqServiceId;
    mqServiceDescription;

    @track manualQuotes = [];
    @track selectedQuote = null;
    @track selectedRowIds = [];
    @track pickupConfNum = '';
    columns = [
        { label: 'Carrier', fieldName: 'assetCarrierName' },
        { label: 'Service', fieldName: 'serviceDescription' },
        { label: 'Pricing', fieldName: 'pricingMethod' },
        { label: 'Equip', fieldName: 'equipmentType' },
        { label: 'Amount', fieldName: 'amountFormatted' },
        { label: 'Currency', fieldName: 'currency', initialWidth: 100 },
        { label: 'Quote Id', fieldName: 'quoteId' },
        {
            type: 'button',
            typeAttributes: {
                label: 'Select',
                name: 'select',
                variant: 'brand-outline'
            },
            initialWidth: 110
        }
    ];

    mqSubmitting = false;

    currencyOptions = [
        { label: 'USD', value: 'USD' }
    ];

    // Predefined, curated Truckload service types
    serviceOptions = [
        { label: 'Standard', value: 'standard' },
        { label: 'Guaranteed', value: 'guaranteed' },
        { label: 'Expedited', value: 'expedited' },
        { label: 'Spot', value: 'spot' },
        { label: 'Dedicated', value: 'dedicated' },
    ];
    billingOptions = [
        { label: "SENDER", value: "SENDER" },
        { label: "RECIPIENT", value: "RECIPIENT" },
        { label: "THIRD_PARTY", value: "THIRD_PARTY" }
    ];

    // ==============================================
    // NEW TAB MANAGEMENT PROPERTIES
    // ==============================================
    
    // Tracks the ID of the currently active custom tab. Initialize to 'Cost'.
    @track activeSection = 'Cost'; 

    // Handler for all custom tab clicks
    handleTabClick(event) {
        event.preventDefault(); // Important: prevent page refresh if using <a> tag
        const selectedTabId = event.currentTarget.dataset.id;
        this.activeSection = selectedTabId;
    }
    
    // --- Computed Properties for Conditional Rendering (Visibility) ---
    get isCostActive() {
        return this.activeSection === 'Cost';
    }
    get isRfqsActive() {
        return this.activeSection === 'RFQs';
    }
    get isManualQuoteActive() {
        return this.activeSection === 'ManualQuote';
    }
    get isTrackActive() {
        return this.activeSection === 'Track';
    }
    
    // --- Computed Properties for Active Styling (SLDS Class) ---
    get costTabClass() {
        return `slds-tabs_default__item ${this.isCostActive ? 'slds-is-active' : ''}`;
    }
    get rfqsTabClass() {
        return `slds-tabs_default__item ${this.isRfqsActive ? 'slds-is-active' : ''}`;
    }
    get manualQuoteTabClass() {
        return `slds-tabs_default__item ${this.isManualQuoteActive ? 'slds-is-active' : ''}`;
    }
    get trackTabClass() {
        return `slds-tabs_default__item ${this.isTrackActive ? 'slds-is-active' : ''}`;
    }

    // ==============================================
    // END NEW TAB MANAGEMENT
    // ==============================================


    connectedCallback() {
        this.setDefaultDate();
        this.loadShipmentData();
        this.loadEquipmentTypes();
        // prefill equipment from packages if present
        const firstEquip = (this.packageList || []).find(p => p?.Equipment_Type__c)?.Equipment_Type__c;
        if (firstEquip) this.mqEquipmentType = firstEquip;
    }

    get emergencyContactId() {
        return this.shipment?.emergency_contact__c || '';
    }

    get emergencyContactName() {
        return (this.shipment && this.shipment.emergency_contact__r && this.shipment.emergency_contact__r.Name)
            ? this.shipment.emergency_contact__r.Name
            : '';
    }

    get emergencyContactUrl() {
        return this.emergencyContactId ? '/' + this.emergencyContactId : '';
    }

    get isEmergencyContactSelected() {
        return !!(this.shipment && this.shipment.emergency_contact__c);
    }

    get formattedOpensAt() { return this.convertTimeToHHMM(this.toAddress?.opens_at__c); }
    get formattedClosesAt() { return this.convertTimeToHHMM(this.toAddress?.closes_at__c); }
    get formattedFromOpensAt() { return this.convertTimeToHHMM(this.fromAddress?.opens_at__c); }
    get formattedFromClosesAt() { return this.convertTimeToHHMM(this.fromAddress?.closes_at__c); }

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

    get hasTracking() {
        return Array.isArray(this.trackingList) && this.trackingList.length > 0;
    }


    handleBackFromShipmentRates() {
        this.isShipmentRatesOpen = false;
        this.loadShipmentData();
    }


    createShipment() {
        console.log('In createShipment method');
        try {

            const dateInput = this.template.querySelector('lightning-input[data-id="shipmentDate"]');

            if (!dateInput) {
                console.error('Shipment date field not found.');
                return;
            }

            const isValidDate = this.validateShipmentDate(dateInput);

            if (!isValidDate) {
                this.showToast('Validation Error', 'Please select a valid shipment date.', 'error');
                return;
            }
            console.log('Creating shipment with date:', dateInput.value);
            this.shipment.Shipment_Date__c = dateInput.value;

            console.log('Selected shipment date:', this.shipment.Shipment_Date__c);


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

           else if (!/^\d{10,12}$/.test(fromPhone)) {
                this.showToast('Validation Error', 'From Phone number must be exactly 10 digits.', 'error');
                return;
            } else if (!/^\d{10,12}$/.test(toPhone)) {
                this.showToast('Validation Error', 'To Phone number must be exactly 10 digits.', 'error');
                return;
            }

            else if (pickupDate < today) {
                this.showToast('Validation Error', 'Pickup date cannot be earlier than today.', 'error');
                return;
            }

            console.log('✅ All validations passed. Proceeding with shipment creation...');

            console.log('Creating shipment...');
            
            // Determine if any item is hazmat
           const hasHazmat = this.packageList?.some(pkg => pkg.is_hazmat__c);

            console.log('packageitems : ', JSON.stringify(this.packageItems));
            console.log('hasHazmat ', hasHazmat);
            // Validate emergency contact if any hazmat
            if (hasHazmat && !this.shipment.emergency_contact__r?.Id) {
                this.showToast(
                    'Validation Error',
                    'Emergency Contact is required for hazardous items.',
                    'error'
                );
                return;
            }

            let rawFromPhone = this.fromContact?.Phone || this.fromContact?.Account?.Phone || '';
            let rawToPhone   = this.toContact?.Phone || this.toContact?.Account?.Phone || '';

            const fromPhoneTC = this.sanitizePhone(rawFromPhone);
            const toPhoneTC   = this.sanitizePhone(rawToPhone);

            if (!/^\d{10,12}$/.test(fromPhoneTC)) {
                this.showToast('Validation Error', 'From Phone must be 10–12 digits.', 'error');
                return;
            }
            if (!/^\d{10,12}$/.test(toPhoneTC)) {
                this.showToast('Validation Error', 'To Phone must be 10–12 digits.', 'error');
                return;
            }

            // override phones for payload
            const fromContactClean = {
                ...this.fromContact,
                Phone: fromPhoneTC
            };

            const toContactClean = {
                ...this.toContact,
                Phone: toPhoneTC
            };

            const fromContactJSON = JSON.stringify(fromContactClean);
            const toContactJSON   = JSON.stringify(toContactClean);
            // Build payloads
            const fromAddressJSON = JSON.stringify(this.fromAddress);
            const toAddressJSON = JSON.stringify(this.toAddress);
            //const fromContactJSON = JSON.stringify(this.fromContact);
            //const toContactJSON = JSON.stringify(this.toContact);
            const shipmentJSON = JSON.stringify(this.shipment);
            const credentialsJSON = JSON.stringify(this.credentials);
            const packageItemsJSON = this.packageItems;
            console.log('packageItemsJSON : ', JSON.stringify(packageItemsJSON));
            console.log('shipmentJSON ', JSON.stringify(shipmentJSON));
            const packListJSON = this.packageList;
            const shipDateStamp = this.shipment.Shipment_Date__c
                ? this.shipment.Shipment_Date__c
                : new Date().toISOString().split('T')[0];
            const masterShipmentId = this.shipment.Id || '';
            let emergencyContactPayload = {};
            if (this.shipment.emergency_contact__r?.Id) {
                emergencyContactPayload = {
                    name: this.shipment.emergency_contact__r.Name,
                   phone: this.sanitizePhone(this.shipment.emergency_contact__r.Phone)
                };
            }
            const stopsJson = JSON.stringify(this.tlStops);

            console.log('shipmentMode : ', this.shipmentMode);
            console.log('stopsJson : ', stopsJson);
            this.isLoading = true;
            // Call Apex
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
                masterShipmentId: masterShipmentId,
                shipmentMode: this.shipmentMode,
                tlStopsJson: stopsJson
            })
                .then(result => {
                    console.log('FreightView Shipment Response:', JSON.stringify(result));

                    // If there are errors, show them
                    if (result?.errMsgs?.length > 0) {
                        // Join all messages, remove the 'Property:' part if needed
                        const userMsg = result.errMsgs.map(m => m.split('| Message: ')[1] || m).join(' | ');
                        this.showToast('Error Creating Shipment', userMsg, 'error');
                        return;
                    }

                    // If ShipDetails is returned, consider it success
                    if (result?.ShipDetails) {
                        this.shipment = result.ShipDetails;
                        this.showCreateShipment = false;
                        console.log('Updated shipment:', JSON.stringify(this.shipment));
                        //console.log('fv shipment id afr creation ',this.result.ShipDetails.shipmentID__c);
                       // this.FVshipmentID = result.ShipDetails.shipmentID__c;
                       console.log('shipment id afr ',JSON.stringify(result.ShipDetails));
                           this.FVshipmentID = result.ShipDetails.shipmentID__c;

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Shipment Created',
                                message: 'Shipment created successfully!',
                                variant: 'success'
                            })
                        );
                    }
                })
                .catch(error => {
                    console.error('Error in FreightView shipment creation:', error);
                    const message = error?.body?.message || error?.message || 'Unknown error';
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Creating Shipment',
                            message: message,
                            variant: 'error'
                        })
                    );
                })
                .finally(() => {
                    this.isLoading = false;
                });

        } catch (e) {
            console.error('Exception in createShipment:', e);
        } 
//         finally {
//             this.isLoading = false;
//         }
    }
    getQuotes() {
        console.log('in getQuotes');
        const shipmentJSON = JSON.stringify(this.shipment);
        const credentialsJSON = JSON.stringify(this.credentials);

        this.isLoading = true;
        getQuoteRates({ Shipment: shipmentJSON, myConsVar: credentialsJSON, modeFilter: (this.shipmentMode ? this.shipmentMode.toLowerCase() : 'ltl') })
            .then(result => {
                console.log('Raw quotes result:', JSON.stringify(result));

                // Normalize to array
                const quotes = Array.isArray(result?.quotes)
                    ? result.quotes
                    : (Array.isArray(result) ? result : []);

                // Optional: keep who we asked for later display
                this.requestedFrom = Array.isArray(result?.requestedFrom) ? result.requestedFrom : [];
                console.log('requestedFrom:', JSON.stringify(this.requestedFrom));
                if (!quotes.length) {
                    this.isShipmentRatesOpen = false;
                    this.quotes = [];
                    this.showToast(
                        'No Quotes Available',
                        'No carrier has returned a quote yet. Try again in a few minutes or Spot a Quote.',
                        'warning'
                    );
                    return;
                }

                // We have quotes — open panel
                this.quotes = quotes;
                this.isShipmentRatesOpen = true;
            })
            .catch(error => {
                console.error('Error fetching quotes:', error);
                let errorMsg = 'An unexpected error occurred while fetching quotes.';
                if (error?.body?.message) errorMsg = error.body.message;
                else if (error?.message) errorMsg = error.message;
                this.showToast('Error', errorMsg, 'error');
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

    // Alias for showToast used in Manual Quotes section
    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
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
    handleTrackShipment() {
        if (!this.FVshipmentID) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Shipment ID is missing. Cannot track shipment.',
                variant: 'error'
            }));
            return;
        }
        const credentialsJSON = JSON.stringify(this.credentials);
        this.isLoading = true;

        getTrackingHistory({ shipmentId: this.FVshipmentID, myConsVar: credentialsJSON })
            .then(result => {
                if (result?.length > 0) {
                    this.trackingList = result;
                } else {
                    this.trackingList = [];
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Info',
                        message: 'No tracking events available yet.',
                        variant: 'info'
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching tracking:', error);
                this.trackingList = [];
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch tracking details. Please try again.',
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handleSchedulePickupChange(event) {
        this.shipment.schedulePickup__c = event.target.checked;
        console.log('Schedule Pickup changed:', this.shipment.schedulePickup__c);
    }
    get isPending() {
        console.log('Shipment Status:', this.shipment?.Status__c);
        return this.shipment?.Status__c?.toLowerCase() === 'pending';
    }
    loadShipmentData() {
        try {
            this.isLoading = true;

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
                        return;
                    }

                    // Assign core data
                    this.defaulWrap = result;
                    this.credentials = result.credsWrap;
                    console.log('this.credentials:', JSON.stringify(this.credentials));

                    // Shipment initialization
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
                        console.log('in load shipment : ', JSON.stringify(this.shipment));
                        console.log('Shipment Name:', this.shipment.Name);
                        this.shipment.Billing_Contact__c = result.ship.Billing_Contact__c || '';
                        this.shipment.Billing_Address__c = result.ship.Billing_Address__c || '';
                        this.isBillingAddressSelected = true;
                        this.isBillingContactSelected = true;
                        this.BillingAddressUrl = '/' + this.shipment.Billing_Address__c;
                        this.BillingAddressName = this.shipment.Billing_Address__r.Name;
                        console.log('AZ billing address ', this.BillingAddressName);

                        this.BillingContactUrl = '/' + this.shipment.Billing_Contact__c;
                        this.BillingContactName = this.shipment.Billing_Contact__r.Name;
                    }

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

                    if (this.fromAddress?.Id) {
                        this.FromAddressSelected = true;
                        this.fromAddressUrl = '/' + this.fromAddress.Id;
                    }

                    if (this.toAddress?.Id) {
                        this.toAddressSelected = true;
                        this.toAddressUrl = '/' + this.toAddress.Id;
                    }

                    // Contacts validation
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

                    // Package list handling
                    if (result.packList?.length > 0) {
                        result.packList.forEach(p => (p.packUrl = '/' + p.Id));

                        const firstPack = result.packList[0];
                        const logistic = firstPack.Logistic__r;
                        console.log('logistc',JSON.stringify(logistic));
                        this.shipment.Shipment_Billing_options__c = logistic?.Billing_options__c || 'SENDER';
                        console.log('logistic?.Billing_options__c ',logistic?.Billing_options__c)
                        this.shipment.Billing_Contact__c = logistic?.Billing_Contact__c || '';
                        this.shipment.Billing_Address__c = logistic?.Billing_Address__c || '';
                        this.shipment.Billing_Account_Number__c = logistic?.Billing_Account_number__c;
                        // Set related names
                        if (logistic?.Billing_Contact__r) {
                            this.isBillingContactSelected = true;
                            this.shipment.Billing_Contact__r = {
                                Id: logistic.Billing_Contact__c,
                                Name: logistic.Billing_Contact__r.Name
                            };
                            this.BillingContactName = this.shipment.Billing_Contact__r.Name;
                        } else {
                            this.shipment.Billing_Contact__r = { Id: '', Name: '' };
                        }

                        if (logistic?.Billing_Address__r) {
                            this.isBillingAddressSelected = true;
                            this.shipment.Billing_Address__r = {
                                Id: logistic.Billing_Address__c,
                                Name: logistic.Billing_Address__r.Name
                            };
                            this.BillingAddressName =  this.shipment.Billing_Address__r.Name;
                        } else {
                            this.shipment.Billing_Address__r = { Id: '', Name: '' };
                        }
                    }
                    console.log('now the shipment is -->',JSON.stringify(this.shipment))
                    // Other UI setup
                    this.packageList = result.packList;
                    console.log('this.packageList:', JSON.stringify(this.packageList));
                    this.shipmentMode = this.computeShipmentMode(this.packageList);
                    console.log('Computed shipmentMode:', this.shipmentMode);
                    this.packageItems = result.packItems;
                    this.disableBillingOption = result.disableBillingDetails;

                    const today = new Date();
                    if (!this.shipmentIds) {

                        this.shipment.Shipment_Date__c = `${today.getFullYear()}-${('0' + (today.getMonth() + 1)).slice(-2)}-${('0' + today.getDate()).slice(-2)}`;
                    } else {
                        if (this.shipment.shipmentID__c) {
                            this.FVshipmentID = this.shipment.shipmentID__c;
                            console.log('FVshipmentID ', this.FVshipmentID);
                        }
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

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Loading Shipment Data',
                            message: errorMsg,
                            variant: 'error'
                        })
                    );
                })
                .finally(() => {
                    this.isLoading = false;
                    this.loadManualQuotes();
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
    handleEmergencyContactSelected(event) {
        console.log('inside handleEmergencyContactSelected');
        const selected = event.detail;

        if (selected) {
            // Set Id and Name immediately
            this.shipment = {
                ...this.shipment,
                emergency_contact__c: selected.Id,
                emergency_contact__r: {
                    Id: selected.Id,
                    Name: selected.Name,
                    Phone: '' // temporarily blank
                }
            };
            getContactPhone({ contactId: selected.Id })
                .then(phone => {
                    this.shipment.emergency_contact__r.Phone = phone || '';
                    console.log('Updated shipment with phone:', JSON.stringify(this.shipment));
                })
                .catch(error => {
                    console.error('Error fetching contact phone:', error);
                });

        }

        console.log('emergency contact after selection:', JSON.stringify(this.shipment));
    }
    get isEmergencyContactRequired() {
        console.log('Checking if Emergency Contact is required...');
        console.log('packageList:', JSON.stringify(this.packageList));
        const hasHazmat = this.packageList?.some(pkg => pkg.is_hazmat__c) || false;
        console.log('hasHazmat:', hasHazmat);
        return hasHazmat;
    }


    // set default date 
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
        this.maxDate = this.formatDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000));

        // Only set Shipment_Date__c if it’s empty
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
        console.log('in 2');
        this.validateShipmentDate(event.target);
    }



    validateShipmentDate(inputElement) {
        if (!inputElement?.value) { inputElement.setCustomValidity('Select a date.'); inputElement.reportValidity(); return false; }
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

        return errorMsg === '';
    }
    handleInputChange = (event) => {
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
                this.shipment.Shipment_Billing_options__c = value;
                break;
            case 'billingAddress':
                if (!this.shipment.Billing_Address__r) {
                    this.shipment.Billing_Address__r = {};
                }
                this.shipment.Billing_Address__r.Name = value;
                break;
            case 'pickupConfNum': // Added from manual quote section
                this.pickupConfNum = value;
                break;
            default:
                console.warn('Unhandled field:', field);
        }

        console.log('Updated shipment:', JSON.parse(JSON.stringify(this.shipment)));
    }
    computeShipmentMode(packList = this.packageList) {
        const modes = (packList || [])
            .map(p => p.Shipment_mode__c ?? p.Shipment_Mode__c)
            .filter(Boolean)
            .map(v => String(v).trim().toLowerCase());

        if (modes.includes('truckload') || modes.includes('truck load') || modes.includes('ftl') || modes.includes('tl')) {
            return 'TruckLoad';
        }
        if (modes.includes('ltl') || modes.includes('less than truckload')) {
            return 'LTL';
        }
        if (modes.includes('parcel')) {
            return 'Parcel';
        }
        return 'LTL';
    }

    get isTruckload() {
        console.log('is truck load : ', (this.shipmentMode || '').trim().toLowerCase() === 'truckload');
        return (this.shipmentMode || '').trim().toLowerCase() === 'truckload';
    }


    handleLiveLoadChange(event) {
        this.shipment.isLiveLoad__c = event.target.checked;
        console.log('isLiveLoad changed:', this.shipment.isLiveLoad__c);
    }
    // for adding stops 
    idxPlusOne(i) { return Number(i) + 1; }
    // stop type options (per your ask: Pickup, Pickup and Deliver, Deliver)
    get stopTypeOptions() {
        return [
            { label: 'Pickup', value: 'pickup' },
            { label: 'Pickup and Deliver', value: 'both' },
            { label: 'Deliver', value: 'deliver' }
        ];
    }

    handleAddStop() {
        const id = `stop-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
        this.tlStops = [
            ...this.tlStops,
            {
                id,
                type: 'pickup',
                addressId: '',
                addressName: '',
                isAddressSelected: false,
                instructions: ''
            }
        ];
    }

    handleRemoveStop(e) {
        const idx = Number(e.currentTarget.dataset.index);
        this.tlStops = this.tlStops.filter((_, i) => i !== idx);
    }


    handleStopTypeChange(e) {
        const idx = Number(e.target.dataset.index);
        this.updateStopAt(idx, { type: e.detail.value });
    }

    handleStopAddressSelected(e) {
        console.log('inside handleStopAddressSelected');
        const idx = Number(e.target.dataset.index);
        console.log('Stop index: ',     idx);
        const sel = e.detail;
        console.log('Selected address: ', JSON.stringify(sel));

        this.updateStopAt(idx, {
            addressId: sel.Id,
            addressName: sel.Name,
            instructions: '',
            isAddressSelected: true
        });
        console.log('Stop address selected:', JSON.stringify(this.tlStops[idx]));
        console.log('Selected address details:', JSON.stringify(sel));
        console.log('stops yet : ', JSON.stringify(this.tlStops));
    }
    handleStopInstructions(e) { this.updateStopAt(Number(e.target.dataset.index), { instructions: e.detail.value }); }
    get computedStops() {
        return (this.tlStops || []).map((s, i) => ({
            ...s,
            displayIndex: i + 1, // safe for template
        }));
    }
    updateStopAt(index, patch) {
        const next = [...this.tlStops];
        next[index] = { ...next[index], ...patch };
        this.tlStops = next;
    }

    //RFQ
    get requestedFromList() {
        const list = Array.isArray(this.requestedFrom) ? this.requestedFrom : [];
        return list.map((r, i) => ({
            key: `${r.carrierId || i}`,
            carrierName: r.carrierName || '—',
            email: r.email || r.name || '—',
            requestDateDisplay: r.requestDate ? new Date(r.requestDate).toLocaleString() : '—',
            hasRespondedDisplay: r.hasResponded ? 'Yes' : 'No',
            hasDeclinedDisplay: r.hasDeclined ? 'Yes' : 'No'
        }));
    }

    // handlers
    handleRfqEmailsChange(e) { this.rfqEmailsText = e.detail.value || ''; }
    handleRfqMessageChange(e) { this.rfqMessage = e.detail.value || ''; }

    // utility to parse comma-separated emails
    parseEmails(input) {
        return (input || '')
            .split(',')
            .map(s => s.trim())
            .filter(Boolean);
    }

    async sendRfq() {
        try {
            const emails = this.parseEmails(this.rfqEmailsText);
            if (!emails.length) {
                this.showToast('Validation', 'Please enter at least one email.', 'warning');
                return;
            }
            const shipmentId = this.FVshipmentID || this.shipment?.shipmentID__c;
            if (!shipmentId) {
                this.showToast('Validation', 'FreightView shipment ID not found.', 'error');
                return;
            }

            this.rfqSending = true;

            const res = await requestTruckloadRFQ({
                myConsVar: JSON.stringify(this.credentials),
                shipmentId,
                emails,
                message: this.rfqMessage || ''
            });

            // Success path: toast + refresh quotes (so you can see any immediate responses)
            this.showToast('RFQ Sent', 'Your RFQ request has been sent to the selected emails.', 'success');
            // optional refresh
            this.getQuotes();
        } catch (err) {
            console.error('RFQ error', err);
            let msg = 'Failed to send RFQ.';
            if (err?.body?.message) msg = err.body.message;
            else if (err?.message) msg = err.message;
            this.showToast('Error', msg, 'error');
        } finally {
            this.rfqSending = false;
        }
    }
    get hasRequestedFrom() {
        return Array.isArray(this.requestedFromList) && this.requestedFromList.length > 0;
    }

    get hasQuotes() {
        return Array.isArray(this.quotes) && this.quotes.length > 0;
    }
    //for manual quote 
    async loadEquipmentTypes() {
        try {
            const vals = await getPackageEquipmentTypes();
            this.equipmentTypeOptions = (vals || []).map(v => ({ label: v, value: v }));
        } catch (e) {
            // Non-fatal; just log
            console.error('Failed to load equipment types', e);
        }
    }

    // ---------- HELPERS ----------
    handleMqChange(e) {
        const id = e.target.dataset.id;
        const v = e.detail?.value ?? e.target?.value;
        switch (id) {
            case 'amount': this.mqAmount = v ? Number(v) : null; break;
            case 'currency': this.mqCurrency = v || 'USD'; break;
            case 'carrierEmail': this.mqCarrierEmail = v; break;
            case 'autoCreateCarrierName': this.mqAutoCreateCarrierName = v; break;
            case 'carrierName': this.mqCarrierName = v; break;
            case 'quoteNum': this.mqQuoteNum = v; break;
            case 'expiresAt': this.mqExpiresAt = v; break; // local datetime string
            case 'transitDays': this.mqTransitDays = v ? Number(v) : null; break;
            case 'equipmentType': this.mqEquipmentType = v; break;
            case 'notes': this.mqNotes = v; break;
            case 'serviceId': this.mqServiceId = v; break;
            case 'serviceDescription': this.mqServiceDescription = v; break;
        }
    }
    toISOZ(localDateTimeStr) {
        // LWC datetime-local returns local time "YYYY-MM-DDTHH:mm"
        if (!localDateTimeStr) return null;
        const dt = new Date(localDateTimeStr);
        if (isNaN(dt.getTime())) return null;
        return dt.toISOString().replace('.000Z', 'Z'); // ISO-UTC
    }

    validateManualQuote() {
        if (!(this.mqAmount >= 1)) {
            this.showToast('Validation', 'Amount must be at least 1.', 'warning');
            return false;
        }
        if (!this.mqCarrierEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.mqCarrierEmail)) {
            this.showToast('Validation', 'Valid carrier email is required.', 'warning');
            return false;
        }
        return true;
    }

    // ---------- SUBMIT ----------
    async handleAddManualQuote() {
        try {
            if (!this.isTruckload) {
                this.showToast('Validation', 'Manual quote is only available for Truckload.', 'warning');
                return;
            }
            const shipmentId = this.FVshipmentID || this.shipment?.shipmentID__c;
            if (!shipmentId) {
                this.showToast('Validation', 'FreightView shipment ID not found.', 'error');
                return;
            }
            if (!this.validateManualQuote()) return;

            this.mqSubmitting = true;

            const res = await addManualTruckloadQuote({
                myConsVar: JSON.stringify(this.credentials),
                shipmentId,
                amount: this.mqAmount,
                currency: this.mqCurrency || 'USD',
                carrierEmail: this.mqCarrierEmail,
                carrierName: this.mqCarrierName || null,
                autoCreateCarrierName: this.mqAutoCreateCarrierName || null,
                quoteNum: this.mqQuoteNum || null,
                notes: this.mqNotes || null,
                expiresAtISO: this.toISOZ(this.mqExpiresAt),
                transitDays: this.mqTransitDays || null,
                equipmentType: this.mqEquipmentType || null,
                serviceId: this.mqServiceId || null,
                serviceDescription: this.mqServiceDescription || null
            });

            // Success
            const qid = res?.quoteId ? ` (ID: ${res.quoteId})` : '';
            this.showToast('Manual Quote Added', `Quote created${qid}.`, 'success');

            // Clear only optional fields; keep carrier & equip defaults
            this.mqQuoteNum = '';
            this.mqNotes = '';
            this.mqExpiresAt = null;
            this.mqTransitDays = null;

            // Refresh quotes tab & RFQs table
            this.getQuotes();
        } catch (err) {
            console.error('Manual quote error', err);
            let msg = 'Failed to create manual quote.';
            if (err?.body?.message) msg = err.body.message;
            else if (err?.message) msg = err.message;
            this.showToast('Error', msg, 'error');
        } finally {
            this.mqSubmitting = false;
        }
    }
    //manual quotes existing and confirm
    get hasManualQuotes() {
        return Array.isArray(this.manualQuotes) && this.manualQuotes.length > 0;
    }

    get confirmDisabled() {
        return !(this.selectedQuote && this.pickupConfNum && this.pickupConfNum.trim().length > 0);
    }

    // Load awarded manual quotes
    async loadManualQuotes() {
        console.log('in loadManualQuotes');
        console.log('FVshipmentID:', this.FVshipmentID);
        console.log('')
        if (!this.FVshipmentID || !this.credentials) return;
        console.log('calling loadManualQuotes');
        this.isLoading = true;
        this.selectedQuote = null;
        this.selectedRowIds = [];
        try {
            console.log('calling getManualQuotes with shipmentID:', this.FVshipmentID);
            const rows = await getManualQuotes({
                myConsVar: JSON.stringify(this.credentials),
                fvShipmentId: this.shipment.shipmentID__c
            });
            console.log('getManualQuotes response:', rows);
            this.manualQuotes = (rows || []).map(r => ({
                ...r,
                amountFormatted: this.formatCurrency(r.amount, r.currency || 'USD')
            }));
        } catch (e) {
            this.toast('Error', e?.body?.message || e.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleRowAction(event) {
        const { action, row } = event.detail || {};
        if (action?.name === 'select') {
            this.selectedQuote = row;
            console.log('Selected quote:', this.selectedQuote);
            this.selectedRowIds = [row.quoteId];
        }
    }

    // handleInputChange is defined above and includes 'pickupConfNum'
    // handleInputChange = (e) => { ... } 

    async handleConfirm() {
        try {
            if (!this.selectedQuote) {
                this.toast('Select a Quote', 'Please select a manual quote to confirm.', 'warning');
                return;
            }
            if (!this.pickupConfNum || !this.pickupConfNum.trim()) {
                this.toast('Pickup Confirmation #', 'Please enter a valid confirmation number.', 'warning');
                return;
            }
            console.log('Confirming with quote:', this.selectedQuote);
            this.isLoading = true;
            const result = await confirmTruckloadManualSimplified({
                myConsVar: JSON.stringify(this.credentials),
                fvShipmentId: this.shipment.shipmentID__c,
                shipmentSfId: this.shipment.Id,
                pickupConfirmationNumber: this.pickupConfNum.trim(),
                manualQuoteJson: JSON.stringify(this.selectedQuote)
            });

            if (result?.success) {
                this.toast('Success', result.message || 'Shipment confirmed', 'success');
                this.dispatchEvent(new CustomEvent('confirmed', { detail: result }));
            } else {
                this.toast('Error', result?.message || 'Could not confirm shipment.', 'error');
            }
        } catch (e) {
            this.toast('Error', e?.body?.message || e.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    formatCurrency(amount, currency) {
        const n = Number(amount);
        if (!Number.isFinite(n)) return '';
        try {
            return new Intl.NumberFormat(undefined, { style: 'currency', currency: (currency || 'USD').toUpperCase() })
                .format(n);
        } catch {
            return `$${n.toFixed(2)}`;
        }
    }

    // toast is defined above
    // toast(title, message, variant) { ... }
    
    async handleCancelShipment() {
        try {
            if (!this.shipment?.shipmentID__c) {
                this.toast('Error', 'No Freightview Shipment ID found.', 'error');
                return;
            }

            const confirmed = await LightningConfirm.open({
                message: 'Are you sure you want to cancel this shipment?',
                label: 'Confirm Cancellation',
                theme: 'warning'
            });
            if (!confirmed) return;

            this.isLoading = true;

            const result = await cancelTruckloadShipment({
                myConsVar: JSON.stringify(this.credentials),
                shipmentJson: JSON.stringify(this.shipment)
            });

            if (result?.success) {
                this.toast('Success', result.message, 'success');
                // update local UI
                this.shipment.Status__c = 'Cancelled';
                // optionally reload data
                if (this.loadShipmentData) await this.loadShipmentData();
            } else {
                this.toast('Error', result?.message || 'Cancellation failed.', 'error');
            }
        } catch (e) {
            this.toast('Error', e?.body?.message || e.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
sanitizePhone(phone) {
    if (!phone) return '';
    return phone.replace(/\D/g, ''); // remove all non-digits
}
handleBillingChange(event) {
    this.shipment.Shipment_Billing_options__c = event.detail.value;
}
get customerIdForFilter() {
    return (
        this.toContact?.Company__c ||
        this.toAddress?.Customer__c ||
        this.toContact?.AccountId ||
        null
    );
}
get contactFilter() {
    const customerId = this.customerIdForFilter;
    console.log('contactFilter: ', customerId);
    if (!customerId) {
        return ''; 
    }
     return `(AccountId = '${customerId}' OR Company__c = '${customerId}')`;
}

}