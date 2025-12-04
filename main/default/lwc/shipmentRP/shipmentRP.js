import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, PageReferenceNavigateEvent } from 'lightning/navigation';

import getLogisticLineItems from '@salesforce/apex/shipmentRP.getLogisticLineItems';
import getPackageDetails from '@salesforce/apex/shipmentRP.getPackageDetails';
import getBillToAddress from '@salesforce/apex/Epos.billToAddress';
import getShipToAddress from '@salesforce/apex/Epos.shipToAddress';
import getContactPhone from '@salesforce/apex/freightView.getContactPhone';
// import getOrderAddressInfo from '@salesforce/apex/shipmentRP.getOrderAddressInfo';
import fetchInitialData from '@salesforce/apex/shipmentRP.fetchInitialData';
import getQuoteRatesLTL from '@salesforce/apex/shipmentRP.getQuoteRatesLTL';
import getLogisticDetails from '@salesforce/apex/shipmentRP.getLogisticDetails';
import bookSelectedQuote from '@salesforce/apex/shipmentRP.bookSelectedQuote';
import saveFreightviewDocs from '@salesforce/apex/shipmentRP.saveFreightviewDocs';
import getShipmentDocs from '@salesforce/apex/freightView.getShipmentDocs';

import AXOLT_FV_KEY from '@salesforce/label/c.AxoltFreightViewERP';

// Helper to generate unique IDs
let packageId = 0;

const DEFAULT_PACKAGE = {
    FVPackageType: '',
    DeclaredValue: null,
    Length: null,
    Width: null,
    Height: null,
    DimensionUnit: null,
    Weight: null,
    WeightUnit: null,
    Quantity: 1,
    FreightClass: null,
    NMFCCode: null,
    IsHazmat: false,
    HazmatID: '',
    HazardClass: null,
    PackagingGroup: null,

    // expand / collapse defaults
    isExpanded: true,
    icon: 'utility:chevrondown',
    class: 'slds-show',

    displayIndex: 1
};

export default class ShipmentRP extends NavigationMixin(LightningElement) {
    @api recordId;

    // ===== Toast helper =====
    showToast(title, message, variant = 'info', mode = 'dismissible') {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode
            })
        );
    }

    // ===== FROM / TO objects =====
    @track fromContact = {
        Id: '',
        Name: '',
        Company__c: '',
        Email: '',
        Phone: '',
        AccountId: '',
        Account: { Id: '', Name: '', Phone: '', Email__c: '' },
        Company__r: { Id: '', Name: '' }
    };

    @track toAddress = {
        Id: '',
        Name: '',
        Address_Line1__c: '',
        Address_Line2__c: '',
        City__c: '',
        State__c: '',
        Postal_Code__c: '',
        Country__c: '',
        Customer__c: '',
        Customer__r: { Id: '', Name: '', Company_txt__c: '' },
        opens_at__c: '',
        closes_at__c: ''
    };

    @track toContact = {
        Id: '',
        Name: '',
        Company__c: '',
        Email: '',
        Phone: '',
        AccountId: '',
        Account: { Id: '', Name: '', Phone: '', Email__c: '' },
        Company__r: { Id: '', Name: '' }
    };

    @track fromAddress = {
        Id: '',
        Name: '',
        Address_Line1__c: '',
        Address_Line2__c: '',
        City__c: '',
        State__c: '',
        Postal_Code__c: '',
        Country__c: '',
        Contact__c: '',
        Contact__r: { Id: '', Name: '', Company__c: '' },
        Customer__c: '',
        Customer__r: { Id: '', Name: '', Company_txt__c: '' },
        opens_at__c: '',
        closes_at__c: ''
    };

    // ===== Static carrier options (for your 2nd screen UI) =====
    @track carrierOptions = [
        {
            name: 'FedEx',
            count: 2,
            days: '3',
            startingPrice: '$125.50+',
            isAffordable: true,
            isReliable: true,
            icon: 'utility:chevronright',
            class: 'sub-options-container slds-hide',
            services: [
                { name: 'FedEx Ground Freight', price: '$125.50', value: 'FDX_Ground' },
                { name: 'FedEx 2Day Freight', price: '$180.99', value: 'FDX_2Day' }
            ]
        },
        {
            name: 'UPS',
            count: 1,
            days: '5',
            startingPrice: '$98.00+',
            isAffordable: false,
            isReliable: true,
            icon: 'utility:chevronright',
            class: 'sub-options-container slds-hide',
            services: [
                { name: 'UPS Standard Freight', price: '$98.00', value: 'UPS_Standard' }
            ]
        },
        {
            name: 'Freight View',
            count: 3,
            days: '2-5',
            startingPrice: '$110.00+',
            isAffordable: false,
            isReliable: false,
            isBestSelection: true,
            icon: 'utility:chevronright',
            class: 'sub-options-container slds-hide',
            services: [
                { name: 'Freight View - FedEx LTL', price: '$155.10', value: 'FV_FDX' },
                { name: 'Freight View - UPS Freight', price: '$110.00', value: 'FV_UPS' },
                { name: 'Freight View - Regional Carrier', price: '$105.99', value: 'FV_Regional' }
            ]
        }
    ];

    @track showShippingOptions = false;
 docIds = {};

    // ===== Order / Logistics / line items =====
   
    // orderSelected = false;

    @track logistics = { Id: null, Name: null };
    logisticsUrl;
    logisticsSelected = false;

    @track logisticLineItems = [];

    @track billToName = '';
    @track shipToName = '';

    // ===== Shipment object =====
    @track shipment = {
        emergency_contact__c: null,
        emergency_contact__r: { Id: null, Name: '', Phone: '' },
        Schedule_Pickup__c: true,
        Pickup_Date__c: null
    };

    // orderFilter = '';

    @track showSuccessScreen = false;

    // Package list
    @track packageList = [
        {
            id: packageId++,
            class: 'slds-show',
            icon: 'utility:chevrondown'
        }
    ];

    lastValidPickupDate = null;

    // picklist options
    @track dimensionUnitOptions = [];
    @track weightUnitOptions = [];
    @track freightClassOptions = [];
    @track hazardClassOptions = [];
    @track packagingGroupOptions = [];
    credentialsMap;

     billToSelected = false;
    shipToSelected = false;
    billToUrl;
    shipToUrl;
    @track quotes = []; // raw quotes from Apex
    @track groupedQuotes = [];
    get hasGroups() { return Array.isArray(this.groupedQuotes) && this.groupedQuotes.length > 0; }
    @track bookingResult;
    @track isLoading = false;
    @track selectedQuote = [];

    // ====== Lifecycle ======
    // renderedCallback() {
    //     if (!this.orderFilter && this.recordId) {
    //         this.orderFilter = `AccountId='${this.recordId}'`;
    //         console.log('Order filter set:', this.orderFilter);
    //     }
    // }

    connectedCallback() {
        this.loadInitData();
        if (!this.shipment.Pickup_Date__c) {
            const todayStr = new Date().toISOString().split('T')[0];
            this.shipment = {
                ...this.shipment,
                Pickup_Date__c: todayStr
            };
            this.lastValidPickupDate = todayStr;
        }
    }

     loadLogisticDetails(logisticId) {
        if (!logisticId) {
            console.warn('loadLogisticDetails called without logisticId');
            return;
        }

        console.log('🔍 Fetching Logistic Details for:', logisticId);

        getLogisticDetails({ logisticId })
            .then(wrap => {
                console.log('================= FULL WRAPPER =================');
                console.log(JSON.stringify(wrap, null, 2));

                console.log('-------- logistic (Logistic__c) --------');
                console.log(JSON.stringify(wrap.logistic, null, 2));

                console.log('-------- fromAddress (From_Address__r) --------');
                console.log(JSON.stringify(wrap.fromAddress, null, 2));

                console.log('-------- toAddress (To_Address__r) --------');
                console.log(JSON.stringify(wrap.toAddress, null, 2));

                console.log('-------- account (Account__r) --------');
                console.log(JSON.stringify(wrap.account, null, 2));

                console.log('-------- fromContact (priority FROM contact) --------');
                console.log(JSON.stringify(wrap.fromContact, null, 2));

                console.log('-------- contact (priority TO contact) --------');
                console.log(JSON.stringify(wrap.contact, null, 2));

                // Store if you want to reuse in other logic later
                this.fromAddress = wrap.fromAddress;
                this.toAddress   = wrap.toAddress;
                this.account     = wrap.account;
                this.fromContact = wrap.fromContact;
                this.toContact   = wrap.contact;
                this.logistics = wrap.logistic;
                console.log('📞 FROM Phone:', wrap.fromContact?.Phone);
                console.log('📞 TO Phone:', wrap.contact?.Phone);
                this.updateAddressSelectionFlags();

            })
            .catch(error => {
                console.error('❌ Error in getLogisticDetails:', error);
            });
            
    }

    get today() {
        return new Date().toISOString().split('T')[0];
    }

    // ====== Initial data & defaults ======
    loadInitData() {
        fetchInitialData()
            .then(data => {
                this.dimensionUnitOptions = data.dimensionOptions || [];
                this.weightUnitOptions = data.weightUnitOptions || [];
                this.freightClassOptions = data.freightClassOptions || [];
                this.hazardClassOptions = data.hazardClassOptions || [];
                this.packagingGroupOptions = data.packagingGroupOptions || [];
                this.credentialsMap = data.credentialsMap || {};

                this.defaultDimensionUnit = data.dimensionOptions?.[0]?.value || null;
                this.defaultWeightUnit = data.weightUnitOptions?.[0]?.value || null;
                this.defaultFreightClass = data.freightClassOptions?.[0]?.value || null;
                this.defaultHazardClass = data.hazardClassOptions?.[0]?.value || null;
                this.defaultPackagingGroup = data.packagingGroupOptions?.[0]?.value || null;

                this.applyDefaultsToExistingPackages();
            })
            .catch(error => {
                console.error('Error in fetchInitialData:', error);
            });
    }

    applyDefaultsToExistingPackages() {
        if (!this.packageList || this.packageList.length === 0) {
            return;
        }

        this.packageList = this.packageList.map((pkg, index) => ({
            ...pkg,
            Quantity: pkg.Quantity || 1,
            DimensionUnit: pkg.DimensionUnit || this.defaultDimensionUnit || null,
            WeightUnit: pkg.WeightUnit || this.defaultWeightUnit || null,
            FreightClass: pkg.FreightClass || this.defaultFreightClass || null,
            HazardClass: pkg.HazardClass || this.defaultHazardClass || null,
            PackagingGroup: pkg.PackagingGroup || this.defaultPackagingGroup || null,
            isExpanded: pkg.isExpanded ?? true,
            icon: pkg.icon || 'utility:chevrondown',
            class: pkg.class || 'slds-show',
            displayIndex: pkg.displayIndex || index + 1
        }));
    }

    // ===== Package Type Options (fvPackageTypeOptions) =====
    fvPackageTypeOptions = [
        { label: 'Pallet', value: 'pallet' },
        { label: 'Bag', value: 'bag' },
        { label: 'Basket', value: 'basket' },
        { label: 'Box', value: 'box' },
        { label: 'Bundle', value: 'bundle' },
        { label: 'Carpet', value: 'carpet' },
        { label: 'Coil', value: 'coil' },
        { label: 'Crate', value: 'crate' },
        { label: 'Cylinder', value: 'cylinder' },
        { label: 'Drum', value: 'drum' },
        { label: 'Jerrican', value: 'jerrican' },
        { label: 'Pail', value: 'pail' },
        { label: 'Piece', value: 'piece' },
        { label: 'Reel', value: 'reel' },
        { label: 'Roll', value: 'roll' },
        { label: 'Tote', value: 'tote' },
        { label: 'Tube/Pipe', value: 'tube_pipe' },
        { label: 'Unit', value: 'unit' }
    ];

    // ===== PACKAGE MANAGEMENT =====
    renumberPackages() {
        this.packageList = this.packageList.map((pkg, i) => ({
            ...pkg,
            displayIndex: i + 1
        }));
    }

    addPackage() {
        const newPkg = {
            ...DEFAULT_PACKAGE,
            id: ++packageId,
            DimensionUnit: this.defaultDimensionUnit || null,
            WeightUnit: this.defaultWeightUnit || null,
            FreightClass: this.defaultFreightClass || null,
            HazardClass: this.defaultHazardClass || null,
            PackagingGroup: this.defaultPackagingGroup || null
        };

        this.packageList = [...this.packageList, newPkg];
        this.renumberPackages();
    }

    removePackage(event) {
        const idToRemove = event.currentTarget.dataset.packageId;
        if (this.packageList.length === 1) {
            alert('You must have at least one package.');
            return;
        }

        this.packageList = this.packageList.filter(pkg => pkg.id != idToRemove);
        this.renumberPackages();
    }

    handlePackageChange(event) {
        const id = event.target.dataset.packageId;
        const name = event.target.name;
        const value =
            event.target.type === 'checkbox' || event.target.type === 'toggle'
                ? event.target.checked
                : event.target.value;

        this.packageList = this.packageList.map(pkg => {
            if (pkg.id == id) {
                if (name === 'IsHazmat') {
                    pkg.IsHazmat = value;
                }

                pkg[name] = value;

                if (name === 'Weight' || name === 'WeightUnit') {
                    pkg.Weight = name === 'Weight' ? Number(value) : pkg.Weight;
                    pkg.WeightUnit = name === 'WeightUnit' ? value : pkg.WeightUnit;
                }
            }
            return pkg;
        });

        if (name === 'FVPackageType') {
            this.applyPackageDefaults(value, id);
        }
    }

    applyPackageDefaults(packageTypeValue, packageIdParam) {
        if (!packageTypeValue) return;

        let csKey = packageTypeValue;
        if (packageTypeValue === 'pallet') {
            csKey = 'Pallet';
        }

        getPackageDetails({ packageType: csKey })
            .then(cs => {
                if (!cs) return;

                this.packageList = this.packageList.map(pkg => {
                    if (pkg.id == packageIdParam) {
                        pkg.Width = cs.Width__c;
                        pkg.Height = cs.Height__c;
                        pkg.DimensionUnit = cs.Dimension_Unit__c;
                        pkg.Weight = cs.Weight__c;
                        pkg.WeightUnit = cs.Weight_Unit__c;
                        pkg.Length = cs.Length__c;
                    }
                    return pkg;
                });
            })
            .catch(error => {
                console.error('Error getting package details', error);
            });
    }

    togglePackageDetails(event) {
        const id = event.currentTarget.dataset.packageId;

        this.packageList = this.packageList.map(pkg => {
            if (pkg.id == id) {
                const expanded = !pkg.isExpanded;
                return {
                    ...pkg,
                    isExpanded: expanded,
                    icon: expanded ? 'utility:chevrondown' : 'utility:chevronright',
                    class: expanded ? 'slds-show' : 'slds-hide'
                };
            }
            return pkg;
        });
    }

    // ===== CARRIER CARD TOGGLE =====
    toggleCarrierDetails(event) {
        const carrierName = event.currentTarget.dataset.carrier;
        const index = this.carrierOptions.findIndex(c => c.name === carrierName);
        if (index === -1) return;

        let newOptions = [...this.carrierOptions];
        let currentCarrier = newOptions[index];

        const isExpanded = currentCarrier.class.includes('slds-show');
        currentCarrier.class = isExpanded
            ? 'sub-options-container slds-hide'
            : 'sub-options-container slds-show';
        currentCarrier.icon = isExpanded ? 'utility:chevronright' : 'utility:chevrondown';

        this.carrierOptions = newOptions;
    }

    handleBackFromQuotes() {
        this.showShippingOptions = false;
    }

    handleNext() {
        // you can wire this to a final "create shipment" later
        this.showToast('Info', 'Ready to ship action is not implemented yet.', 'info');
    }

    // ===== PHONE UTIL =====
    sanitizePhone(phone) {
        if (!phone) return '';
        return String(phone).replace(/\D/g, '');
    }

    // ===== GET QUOTES =====
//  async  handleGetQuotes() {
//     try {
//         // 1️⃣ Run existing validation
//         const firstError = this.validateBeforeGetQuotes();
//         if (firstError) {
//             this.showToast('Validation Error', firstError, 'error', 'sticky');
//             return;
//         }

//         // 2️⃣ Extract real From/To Contact from address or order
//         const fromContact = this.fromContact;

//         const toContact =this.toContact;

//         // 3️⃣ Clean & sanitize phone numbers
//         const fromPhoneTC = this.sanitizePhone(fromContact?.Phone || '');
//         const toPhoneTC   = this.sanitizePhone(toContact?.Phone || '');
        
//         this.isLoading = true;
//         // 4️⃣ Log all values BEFORE sending to Apex
//         console.log('==== Before Apex Call (Sanitized & Resolved Values) ====');
//        // console.log('Order:', JSON.stringify(this.order));
//         console.log('Logistic:', JSON.stringify(this.logistics));
//         console.log('From Address:', JSON.stringify(this.fromAddress));
//         console.log('To Address:', JSON.stringify(this.toAddress));
//         console.log('Resolved From Contact:', JSON.stringify({ ...fromContact, Phone: fromPhoneTC }));
//         console.log('Resolved To Contact:', JSON.stringify({ ...toContact, Phone: toPhoneTC }));
//         console.log('Package Picklist Options:', JSON.stringify(this.fvPackageTypeOptions));
//         console.log('Package List:', JSON.stringify(this.packageList));
//         console.log('Schedule Pickup:', this.shipment?.Schedule_Pickup__c);
//         console.log('Pickup Date:', this.shipment?.Pickup_Date__c);
//         console.log('Selected Providers:', this.selectedProviders);

//         // 5️⃣ Make sure package type options exist
//         if (!this.fvPackageTypeOptions.length) {
//             this.showToast('Init Error', 'No package types available!', 'error');
//             return;
//         }
        
//         // 6️⃣ Apex Call
//         getQuoteRatesLTL({
//             providerList:   this.selectedProviders?.length ? this.selectedProviders : ['freightview'],
//             fromAddressJson: JSON.stringify(this.fromAddress),
//             toAddressJson:   JSON.stringify(this.toAddress),
//             logisticJson:    JSON.stringify(this.logistics),
//             pkgListJson:     JSON.stringify(this.packageList),
//             schedulePickup:  this.shipment?.Schedule_Pickup__c,
//             pickupDT:        this.shipment?.Pickup_Date__c || this.today,
//             fromContact:     JSON.stringify({ ...fromContact, Phone: fromPhoneTC }),
//             toContact:       JSON.stringify({ ...toContact, Phone: toPhoneTC })
//         })
//             .then(result => {
//                 console.log('afr getQuotesLTL apex');
//                 const Q = result?.quotesFreightView || [];
//                 if (!Q.length) {
//                     this.showToast('No Quotes', 'No Freight View rates returned.', 'warning');
//                     return;
//                 }

//                 // 1️⃣ Store raw quotes
//                 this.quotes = Q.map(x => ({
//                     quoteId: x.quoteId,
//                     carrier: x.carrier,
//                     service: x.service,
//                     amount: x.amount,
//                     currency: x.currencyQ,
//                     shipmentId: x.shipmentId,
//                     provider: x.provider
//                 }));

//                 // 2️⃣ Build grouped UI cards
//                 this.buildCarrierGroups();

//                 this.showShippingOptions = true;
//             })


//     } catch (e) {
//         console.error('handleGetQuotes Exception:', e);
//         this.showToast('Error', e.message || 'Unexpected error', 'error');
//     } finally{
//          this.isLoading = false;
//     }
// }
async handleGetQuotes() {
    const firstError = this.validateBeforeGetQuotes();
    if (firstError) {
        this.showToast('Validation Error', firstError, 'error', 'sticky');
        return;
    }

    const fromContact = this.fromContact;
    const toContact = this.toContact;
    const fromPhoneTC = this.sanitizePhone(fromContact?.Phone || '');
    const toPhoneTC = this.sanitizePhone(toContact?.Phone || '');

    this.isLoading = true;  // ✅ loader ON

    try {
        console.log('==== Before Apex Call ====');
        console.log('Logistic:', JSON.stringify(this.logistics));
        console.log('From Address:', JSON.stringify(this.fromAddress));
        console.log('To Address:', JSON.stringify(this.toAddress));
        console.log('From Contact:', JSON.stringify({ ...fromContact, Phone: fromPhoneTC }));
        console.log('To Contact:', JSON.stringify({ ...toContact, Phone: toPhoneTC }));
        console.log('Package List:', JSON.stringify(this.packageList));
        console.log('Schedule Pickup:', this.shipment?.Schedule_Pickup__c);
        console.log('Pickup Date:', this.shipment?.Pickup_Date__c);
        console.log('Providers:', this.selectedProviders);

        const result = await getQuoteRatesLTL({   // ✅ wait for Apex
            providerList: this.selectedProviders?.length ? this.selectedProviders : ['freightview'],
            fromAddressJson: JSON.stringify(this.fromAddress),
            toAddressJson: JSON.stringify(this.toAddress),
            logisticJson: JSON.stringify(this.logistics),
            pkgListJson: JSON.stringify(this.packageList),
            schedulePickup: this.shipment?.Schedule_Pickup__c,
            pickupDT: this.shipment?.Pickup_Date__c || this.today,
            fromContact: JSON.stringify({ ...fromContact, Phone: fromPhoneTC }),
            toContact: JSON.stringify({ ...toContact, Phone: toPhoneTC })
        });

        console.log('✅ After Apex Response:', result);

        const Q = result?.quotesFreightView || [];
        if (!Q.length) {
            this.showToast('No Quotes', 'No Freight View rates returned.', 'warning');
            return;
        }

        this.quotes = Q.map(x => ({
            quoteId: x.quoteId,
            carrier: x.carrier,
            service: x.service,
            amount: x.amount,
            currency: x.currencyQ,
            shipmentId: x.shipmentId,
            provider: x.provider
        }));

        this.buildCarrierGroups();
        this.showShippingOptions = true;

    } catch (e) {
        console.error('handleGetQuotes Error:', e);
        this.showToast('Error', e.message || 'Unexpected error', 'error');
    } finally {
        this.isLoading = false;  // ✅ loader OFF only after API finishes or fails
    }
}


    validateBeforeGetQuotes() {
        const allInputs = this.template.querySelectorAll('lightning-input');
        const allCombos = this.template.querySelectorAll('lightning-combobox');

        [...allInputs, ...allCombos].forEach(el => {
            if (typeof el.reportValidity === 'function') {
                el.reportValidity();
            }
        });

        // if (!this.order || !this.order.Id) {
        //     return 'Order is required.';
        // }

        if (!this.logistics || !this.logistics.Id) {
            return 'Logistics is required.';
        }

        if (!this.shipment || !this.shipment.Pickup_Date__c) {
            return 'Pickup Date is required.';
        }

        if (!this.packageList || this.packageList.length === 0) {
            return 'At least one package is required.';
        }

        const requiredPackageFields = [
            { api: 'FVPackageType', label: 'Package Type' },
            { api: 'DeclaredValue', label: 'Declared Value' },
            { api: 'Length', label: 'Length' },
            { api: 'Width', label: 'Width' },
            { api: 'Height', label: 'Height' },
            { api: 'DimensionUnit', label: 'Dimension Unit' },
            { api: 'Weight', label: 'Weight' },
            { api: 'WeightUnit', label: 'Weight Unit' },
            { api: 'Quantity', label: 'Quantity' },
            { api: 'FreightClass', label: 'Freight Class' },
            { api: 'NMFCCode', label: 'NMFC Code' }
        ];

        let anyHazmat = false;

        if (this.packageList && this.packageList.length > 0) {
            for (let i = 0; i < this.packageList.length; i++) {
                const pkg = this.packageList[i];
                const pkgLabel = `Package #${pkg.displayIndex || i + 1}`;

                for (let f of requiredPackageFields) {
                    const v = pkg[f.api];
                    const isEmpty =
                        v === null ||
                        v === undefined ||
                        v === '' ||
                        (typeof v === 'number' && isNaN(v));

                    if (isEmpty) {
                        return `${pkgLabel}: ${f.label} is required.`;
                    }
                }

                if (pkg.IsHazmat) {
                    anyHazmat = true;

                    if (!pkg.HazmatID) {
                        return `${pkgLabel}: Hazmat ID is required for Hazmat shipment.`;
                    }
                    if (!pkg.HazardClass) {
                        return `${pkgLabel}: Primary Hazard Class is required for Hazmat shipment.`;
                    }
                    if (!pkg.PackagingGroup) {
                        return `${pkgLabel}: Packaging Group is required for Hazmat shipment.`;
                    }
                }
            }
        }

        if (anyHazmat && !this.emergencyContactId) {
            return 'Emergency Contact is required when Hazmat is selected.';
        }

        return null;
    }

    // ===== SUCCESS SCREEN (if you enable that template) =====
    // handleReadyToShip() {
    //     this.showSuccessScreen = true;
    // }

    handleGoBackToForm() {
        this.showSuccessScreen = false;
    }

    // ===== ORDER HANDLERS =====
    // selectOrder(event) {
    //     const selectedId = event.detail.selectedRecordId || event.detail.Id;
    //     const selectedName = event.detail.selectedName || event.detail.Name;

    //     this.order = { Id: selectedId, Name: selectedName };
    //     this.orderUrl = `/${selectedId}`;
    //     this.orderSelected = true;

    //     if (selectedId) {
    //         getOrderAddressInfo({ orderId: selectedId })
    //             .then(o => {
    //                 if (!o) return;

    //                 this.order = {
    //                     ...this.order,
    //                     Bill_To_Address__c: o.Bill_To_Address__c,
    //                     Bill_To_Address__r: o.Bill_To_Address__r,
    //                     Ship_To_Address__c: o.Ship_To_Address__c,
    //                     Ship_To_Address__r: o.Ship_To_Address__r
    //                 };

    //                 this.billToSelected = !!o.Bill_To_Address__c;
    //                 this.billToName = o.Bill_To_Address__r
    //                     ? o.Bill_To_Address__r.Name
    //                     : '';
    //                 this.billToUrl = o.Bill_To_Address__c
    //                     ? '/' + o.Bill_To_Address__c
    //                     : null;

    //                 this.shipToSelected = !!o.Ship_To_Address__c;
    //                 this.shipToName = o.Ship_To_Address__r
    //                     ? o.Ship_To_Address__r.Name
    //                     : '';
    //                 this.shipToUrl = o.Ship_To_Address__c
    //                     ? '/' + o.Ship_To_Address__c
    //                     : null;

    //                 console.log('Order with addresses:', JSON.stringify(this.order));

    //                 this.fromAddress = o.Bill_To_Address__r || this.fromAddress;
    //                 this.toAddress = o.Ship_To_Address__r || this.toAddress;
    //             })
    //             .catch(error => {
    //                 console.error('Error in getOrderAddressInfo:', error);
    //             });
    //     }

    //     this.clearLogistics();
    // }

    // handleRemoveOrder() {
    //     this.order = { Id: null, Name: null };
    //     this.orderUrl = null;
    //     this.orderSelected = false;

    //     this.billToSelected = false;
    //     this.billToName = '';
    //     this.billToUrl = null;

    //     this.shipToSelected = false;
    //     this.shipToName = '';
    //     this.shipToUrl = null;

    //     this.clearLogistics();
    // }

    // ===== LOGISTICS HANDLERS =====
    // selectLogistics(event) {
    //     const selectedId = event.detail.selectedRecordId || event.detail.Id;
    //     const selectedName = event.detail.selectedName || event.detail.Name;

    //     this.logistics = { Id: selectedId, Name: selectedName };
    //     this.logisticsUrl = `/${selectedId}`;
    //     this.logisticsSelected = true;

    //     this.fetchLogisticLineItems();
    // }

    selectLogistics(event) {
        // Adjust based on how your c-input-lookup sends detail
        const sel = event.detail || {};

        const logisticId   = sel.Id || sel.recordId;
        const logisticName = sel.Name || sel.recordName;

        if (!logisticId) {
            console.warn('No Logistic__c Id from lookup event:', event.detail);
            return;
        }

        // Store in state for binding in your markup
        this.logistics = {
            Id: logisticId,
            Name: logisticName
        };
        this.logisticsUrl = '/' + logisticId;
        this.logisticsSelected = true;

        console.log('📦 Selected Logistic__c from lookup:', this.logistics);

        // Now load details from Apex and just log them
        this.fetchLogisticLineItems();
        this.loadLogisticDetails(logisticId);
    }


   handleRemoveLogistics() {
        this.logistics = {};
        this.logisticsSelected = false;
        this.logisticsUrl = null;

        this.fromAddress = null;
        this.toAddress   = null;
        this.account     = null;
        this.fromContact = null;
        this.toContact   = null;

         this.billToSelected = false;
        this.shipToSelected = false;
        this.billToUrl = null;
        this.shipToUrl = null;

        console.log('✂️ Logistics selection cleared');
    }
 

    clearLogistics() {
        this.logistics = { Id: null, Name: null };
        this.logisticsUrl = null;
        this.logisticsSelected = false;
        this.logisticLineItems = [];
    }

    // get setLogisticsQuery() {
    //     return this.order?.Id ? `AND Order_S__c = '${this.order.Id}'` : 'Id = null';
    // }
 get setLogisticsQuery() {
    console.log('AZ recordid',this.recordId);
    
        if (!this.recordId) {
            return null;
        }
        // return `SELECT Id, Name FROM Logistic__c WHERE Order__c = '${this.recordId}' LIMIT 50`;
        return  `Order_S__c = '${this.recordId}'`;

    }



    // ===== APEX: Logistic Line Items =====
    fetchLogisticLineItems() {
        if (!this.logistics?.Id) {
            this.logisticLineItems = [];
            return;
        }

        getLogisticLineItems({ logisticId: this.logistics.Id })
            .then(result => {
                this.logisticLineItems = result || [];
            })
            .catch(error => {
                console.error('Error fetching logistic line items', error);
                this.logisticLineItems = [];
            });
    }

 // ⬇️ These are used in the HTML selected-value / selected-name bindings

    // From Address (Logistic__c.From_Address__c)
    get fromAddressId() {
        // Prefer the wrapper (has full record), fallback to field on logistics
        return this.fromAddress?.Id || this.logistics?.From_Address__c || null;
    }

    get fromAddressName() {
        return this.fromAddress?.Name || '';
    }

    // To Address (Logistic__c.To_Address__c)
    get toAddressId() {
        return this.toAddress?.Id || this.logistics?.To_Address__c || null;
    }

    get toAddressName() {
        return this.toAddress?.Name || '';
    }

    updateAddressSelectionFlags() {
        this.billToSelected = !!this.fromAddressId;
        this.shipToSelected = !!this.toAddressId;

        this.billToUrl = this.fromAddressId ? '/' + this.fromAddressId : null;
        this.shipToUrl = this.toAddressId ? '/' + this.toAddressId : null;
    }

   
  

    // // ===== BILL TO / SHIP TO LOOKUPS =====
    // selectBillTo(event) {
    //     try {
    //         const selectedId = event.detail.selectedRecordId || event.detail.Id;
    //         const selectedName = event.detail.selectedName || event.detail.Name || '';

    //         this.Bill_To_Address__c = selectedId;
    //         this.billToSelected = true;
    //         this.billToUrl = '/' + selectedId;
    //         this.billToName = selectedName;

    //         if (selectedId) {
    //             getBillToAddress({ addId: selectedId })
    //                 .then(result => {
    //                     if (result) {
    //                         this.Bill_To_Address__r = result;
    //                     }
    //                 })
    //                 .catch(error => {
    //                     console.error('Error in getBillToAddress:', error);
    //                 });
    //         }
    //     } catch (e) {
    //         console.error('selectBillTo error:', e);
    //     }
    // }

    // selectShipTo(event) {
    //     try {
    //         const selectedId = event.detail.selectedRecordId || event.detail.Id;
    //         const selectedName = event.detail.selectedName || event.detail.Name || '';

    //         this.Ship_To_Address__c = selectedId;
    //         this.shipToSelected = true;
    //         this.shipToUrl = '/' + selectedId;
    //         this.shipToName = selectedName;

    //         if (selectedId) {
    //             getShipToAddress({ addId: selectedId })
    //                 .then(result => {
    //                     if (result) {
    //                         this.Ship_To_Address__r = result;
    //                     }
    //                 })
    //                 .catch(error => {
    //                     console.error('Error in getShipToAddress:', error);
    //                 });
    //         }
    //     } catch (e) {
    //         console.error('selectShipTo error:', e);
    //     }
    // }

    // removeBillTo() {
    //     this.Bill_To_Address__c = null;
    //     this.Bill_To_Address__r = { Id: null, Name: '' };
    //     this.billToSelected = false;
    //     this.billToUrl = null;
    //     this.billToName = '';
    // }

    // removeShipTo() {
    //     this.Ship_To_Address__c = null;
    //     this.Ship_To_Address__r = { Id: null, Name: '' };
    //     this.shipToSelected = false;
    //     this.shipToUrl = null;
    //     this.shipToName = '';
    // }

    // // // To Address ← Logistic__c.toAddress
    // // get shipToAddressId() {
    // //     return this.toAddress?.Id || null;
    // // }

    // // get shipToName() {
    // //     return this.toAddress?.Name || '';
    // // }

    // // // From Address ← Logistic__c.fromAddress
    // // get billToAddressId() {
    // //     return this.fromAddress?.Id || null;
    // // }

    // // get billToName() {
    // //     return this.fromAddress?.Name || '';
    // // }

    // get shipToFilter(){
    //     return this.recordId ? `To_Address__c='${this.recordId}'` : null;
    // }

    // get billToFilter(){
    //     return this.recordId ? `From_Address__c='${this.recordId}'` : null;
    // }
    // addressGenerator(addr) {
    //     if (!addr) return '';
    //     return [
    //         addr.Street__c,
    //         addr.City__c,
    //         addr.State__c,
    //         addr.Postal_Code__c,
    //         addr.Country__c
    //     ]
    //         .filter(line => line)
    //         .join(', ');
    // }

    // ===== EMERGENCY CONTACT GETTERS =====
    
    get emergencyContactId() {
        return this.shipment?.emergency_contact__c || '';
    }

    get emergencyContactName() {
        return this.shipment?.emergency_contact__r?.Name || '';
    }

    get emergencyContactUrl() {
        return this.emergencyContactId ? '/' + this.emergencyContactId : '';
    }

    get isEmergencyContactSelected() {
        return !!this.shipment?.emergency_contact__c;
    }

    handleEmergencyContactSelected(event) {
        const selected = event.detail;

        if (selected) {
            this.shipment = {
                ...this.shipment,
                emergency_contact__c: selected.Id,
                emergency_contact__r: {
                    Id: selected.Id,
                    Name: selected.Name,
                    Phone: ''
                }
            };

            getContactPhone({ contactId: selected.Id })
                .then(phone => {
                    this.shipment = {
                        ...this.shipment,
                        emergency_contact__r: {
                            ...this.shipment.emergency_contact__r,
                            Phone: phone || ''
                        }
                    };
                    console.log(
                        'Updated shipment with phone:',
                        JSON.stringify(this.shipment)
                    );
                })
                .catch(error => {
                    console.error('Error fetching contact phone:', error);
                });
        }
    }

    // ===== Contact filter (used by emergency contact lookup) =====
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

    // ===== Shipment field change (Pickup / Schedule) =====
    handleShipmentFieldChange(event) {
        const name = event.target.name;
        let value = event.target.value;

        if (event.target.type === 'checkbox') {
            value = event.target.checked;
        }

        if (name === 'PickupDate') {
            if (value) {
                const d = new Date(value + 'T00:00:00');
                const day = d.getDay(); // 0 = Sun, 6 = Sat

                if (day === 0 || day === 6) {
                    event.target.setCustomValidity(
                        'Pickup cannot be scheduled on Saturday or Sunday.'
                    );
                    event.target.reportValidity();

                    const revertTo = this.lastValidPickupDate || '';
                    this.shipment = {
                        ...this.shipment,
                        Pickup_Date__c: revertTo
                    };

                    return;
                } else {
                    event.target.setCustomValidity('');
                    event.target.reportValidity();
                    this.lastValidPickupDate = value;
                }
            } else {
                this.lastValidPickupDate = null;
                event.target.setCustomValidity('');
                event.target.reportValidity();
            }

            this.shipment = {
                ...this.shipment,
                Pickup_Date__c: value
            };
        } else if (name === 'SchedulePickup') {
            this.shipment = {
                ...this.shipment,
                Schedule_Pickup__c: value
            };
        } else {
            this.shipment = {
                ...this.shipment,
                [name]: value
            };
        }

        console.log('Updated shipment:', JSON.stringify(this.shipment));
    }
buildCarrierGroups() {
    if (!Array.isArray(this.quotes) || !this.quotes.length) {
        this.carrierOptions = [];
        return;
    }

    const groups = {};

    // 1️⃣ Group quotes by carrier + store provider once
    this.quotes.forEach(q => {
        const carrier = q.carrier || 'Unknown Carrier';
        const service = q.service || 'Standard';
        const price   = q.amount || 0;

        if (!groups[carrier]) {
            groups[carrier] = { provider: q.provider, list: [] };
        }

        groups[carrier].list.push({
            service,
            price,
            quoteId: q.quoteId
        });
    });

    // 2️⃣ Build UI model
    this.carrierOptions = Object.keys(groups).map(carrierName => {
        const obj  = groups[carrierName];
        const list = obj.list;

        return {
            name: carrierName,
            count: list.length, // ✅ shows total options under carrier
            provider: obj.provider, // ✅ parent only provider
            days: '',
            isAffordable: false,
            isReliable: false,
            icon: 'utility:chevrondown',
            startingPrice: this.formatCurrency(Math.min(...list.map(x => x.price))),
            class: 'slds-hide',

            services: list.map(i => ({
                name:  i.service,
                value: i.quoteId, // ✅ use quoteId as value so it stays unique
                price: this.formatCurrency(i.price),
                quoteId: i.quoteId
            }))
        };
    });

    console.log('carrier grouped:', JSON.stringify(this.carrierOptions));
}


 formatCurrency(amount, currencyCode) {
  const n = Number(amount);
  if (!Number.isFinite(n)) return '';
  const cur = (currencyCode || 'USD').toUpperCase();
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: cur,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(n);
  } catch {
    return n.toFixed(2);
  }
}
handleSelectQuote(e) {
    const quoteId = e.target.dataset.quoteId;
    const carrier = e.target.dataset.carrier;
    const cost    = e.target.dataset.cost;

    // Find the full quote object from this.quotes (populated after getQuoteRatesLTL)
    const q = (this.quotes || []).find(q => q.quoteId === quoteId);

    if (!q) {
        console.error('❌ Quote not found for quoteId:', quoteId, 'in', JSON.stringify(this.quotes));
        this.showToast('Error', 'Could not find quote details. Please try again.', 'error');
        this.hasSelectedQuote = false;
        return;
    }

    this.selectedQuote = q;
    this.hasSelectedQuote = true;

    console.log('✅ Selected quote saved:', JSON.stringify(this.selectedQuote));

    // Optional: remove alert if it's annoying
   // alert(`Quote Selected!\nQuote ID: ${quoteId}\nCarrier: ${carrier}\nCost: ${cost}`);
}

// handleReadyToShip() {
//     if (!this.hasSelectedQuote) {
//         this.showToast('Error', 'Please select a quote before booking.', 'error');
//         return;
//     }

//     const q = this.selectedQuote;
//     console.log('selected quote ',q);
//     console.log('--- DATA SENT TO APEX ---');
//     console.log('provider:', q.provider);
//     console.log('quoteId:', q.quoteId);
//     console.log('fvShipmentId:', q.shipmentId);
//     console.log('schedulePickup:', true);
//     console.log('mode:', 'ltl');

//     console.log('fromAddressJson:', JSON.stringify(this.fromAddress || {}));
//     console.log('toAddressJson:', JSON.stringify(this.toAddress || {}));
//     console.log('logisticJson:', JSON.stringify(this.logistics || {}));
//     console.log('fromContactJson:', JSON.stringify(this.fromContact || {}));
//     console.log('toContactJson:', JSON.stringify(this.toContact || {}));
//     this.isLoading = true;
//     console.log('booking the quote bfr apex');
//    bookSelectedQuote({
//         provider:        q.provider,
//         quoteId:         q.quoteId,
//         fvShipmentId:    q.shipmentId,
//         schedulePickup:  true,
//         mode:            'ltl',
//         fromAddressJson: JSON.stringify(this.fromAddress || {}),
//         toAddressJson:   JSON.stringify(this.toAddress || {}),
//         logisticJson:    JSON.stringify(this.logistics || {}),
//         fromContactJson: JSON.stringify(this.fromContact || {}),
//         toContactJson:   JSON.stringify(this.toContact || {})
//     })
//         .then(res => {
//             console.log('afr bookSelectedQuoteApex');
//              if (res?.success) {
//                 this.bookingResult = res;
//                 this.showToast('Shipment Booked', res.message, 'success');
//                     console.log('provider -->',q.provider.toLowerCase());
//                 if (q.provider && q.provider.toLowerCase().includes('freight view')){
                    
//                     const fvCred = this.credentialsMap?.[AXOLT_FV_KEY];
//                     if (!fvCred) {
//                         console.error('FreightView credentials missing');
//                         return;
//                     }

//                     console.log('📄 Calling FreightView doc save…');

//                     saveFreightviewDocs({
//                         respRawJson: res.responseRaw,
//                         shipmentId:  res.shipmentSalesforceId,
//                         username:    fvCred.Username_Login__c,
//                         password:    fvCred.Password_Transkey__c,
//                         url:         fvCred.URL__c
//                     })
//                     .then(docRes => {
//                         console.log('📄 Doc save response=', docRes);
//                          if (docRes?.success) {
//                             const d = docRes;
//                             this.docIds = this.deriveDocMap(d.contentTitles, d.contentTitles);

//                             // Now call doc link query ✅
//                             getShipmentDocs({ shipmentId: res.shipmentSalesforceId })
//                                 .then(docMap => {
//                                     console.log('✅ Shipment Docs from Apex =', JSON.stringify(docMap));
//                                     this.docIds = docMap; 
//                                     this.bookingResult.docByType = docMap;
//                                 })
//                                 .catch(e => console.error('❌ Error fetching shipment docs', e));
//                         }
//                         this.showSuccessScreen = true;
//                     })
//                     .catch(e => console.error('Docs download/save failed', e));

//                 }
//                 else{
//                     this.showSuccessScreen = true;
//                 }
//             }
//         })
//         .catch(error => {
//             console.error('Error booking shipment:', error);
//             const msg =
//                 error?.body?.message ||
//                 error?.message ||
//                 'Unexpected error while booking shipment.';
//             this.showToast('Error', msg, 'error', 'sticky');
//         })
//         .finally(() => {
//             this.isLoading = false;
//         });
// }
async handleReadyToShip() {
    if (!this.hasSelectedQuote) {
        this.showToast('Error', 'Please select a quote before booking.', 'error');
        return;
    }

    const q = this.selectedQuote;
    this.isLoading = true;  // ✅ Loader ON for booking

    try {
        console.log('Booking shipment…');
        const res = await bookSelectedQuote({  // ✅ Wait booking response
            provider: q.provider,
            quoteId: q.quoteId,
            fvShipmentId: q.shipmentId,
            schedulePickup: true,
            mode: 'ltl',
            fromAddressJson: JSON.stringify(this.fromAddress || {}),
            toAddressJson: JSON.stringify(this.toAddress || {}),
            logisticJson: JSON.stringify(this.logistics || {}),
            fromContactJson: JSON.stringify(this.fromContact || {}),
            toContactJson: JSON.stringify(this.toContact || {})
        });

        console.log('Booking response:', res);

        if (!res?.success) {
            this.showToast('Error', res?.message || 'Booking failed', 'error');
            return;
        }

        this.bookingResult = res;
        this.showToast('Shipment Booked', res.message, 'success');

        // ✅ Now handle FreightView docs if provider matches
        if (q.provider && q.provider.toLowerCase().includes('freight view')) {
            const fvCred = this.credentialsMap?.[AXOLT_FV_KEY];
            if (!fvCred) {
                console.error('FreightView credentials missing');
                return;
            }

            this.isLoading = true;  // ✅ Loader ON again before doc saving
            console.log('Saving FreightView docs…');

            const docRes = await saveFreightviewDocs({  // ✅ Wait doc save response
                respRawJson: res.responseRaw,
                shipmentId: res.shipmentSalesforceId,
                username: fvCred.Username_Login__c,
                password: fvCred.Password_Transkey__c,
                url: fvCred.URL__c
            });

            console.log('Doc save response:', docRes);

            if (docRes?.success) {
                this.docIds = this.deriveDocMap(docRes.contentTitles, docRes.contentTitles);

                // ✅ Fetch linked docs from Apex
                const docMap = await getShipmentDocs({ shipmentId: res.shipmentSalesforceId });
                console.log('Shipment Docs:', docMap);
                this.docIds = docMap;
                this.bookingResult.docByType = docMap;
            }

            this.showSuccessScreen = true;
        } else {
            this.showSuccessScreen = true;
        }

    } catch (error) {
        console.error('Shipment booking failed:', error);
        this.showToast('Error', error?.message || 'Unexpected error', 'error', 'sticky');
    } finally {
        this.isLoading = false;  // ✅ Loader OFF only after whole flow
    }
}

openShipmentRecord(e) {
    const id = e.currentTarget.dataset.id;
    window.open('/' + id, '_blank');
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
backToForm() {
    this.showSuccessScreen = false;
}

backToForm() {
    this.showShippingOptions = false;
    this.showSuccessScreen = false;
    console.log('🔙 Back to form');
}

deriveDocMap(ids, titles) {
    const map = { label: null, bol: null };
    if (!Array.isArray(titles)) return map;

    titles.forEach((t,i) => {
        const lower = t.toLowerCase();
        if (lower.includes('-label')) map.label = ids?.[i] || t; 
        if (lower.includes('-bol'))   map.bol   = ids?.[i] || t;
    });
    return map;
}



}