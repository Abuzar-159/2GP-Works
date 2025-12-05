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
import getTotalStockPerProduct from '@salesforce/apex/shipmentRP.getTotalStockPerProduct';
import getOrderAndItemsAnalysis from '@salesforce/apex/shipmentRP.getOrderAndItemsAnalysis';
import getOrderAndDcDetails from '@salesforce/apex/shipmentRP.getOrderAndDcDetails';
import getCreateLogistics from '@salesforce/apex/shipmentRP.getCreateLogistics';


import AXOLT_FV_KEY from '@salesforce/label/c.AxoltFreightView';

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
        this.loadOrderData();
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

        if(name === 'Name'){
            this.newLogistic.Name = value;
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
// order to logistics thing here 

@track orderLineAnalysis = [];
@track order;
@track showOrderToLogisticsStep = false;
@track showCreateLogisticStep = false;   // Step-2 (logistic creation screen)
@track orderVsLogisticsEqual = false;
@track selectedRows = [];
// @track isCreateDisabled = true;
@track existingLogistics = [];
@track selectedProductIds = [];
@track stockMap;
@track newLogistic = {
    Id: null,
    Name: '',
    Order_S__c: this.recordId,  // ✅ link to Order
    Account__c: null,
    Contact__c: null,          // you can use From_Contact__c also based on your field
    From_Address__c: null,
    To_Address__c: null
};
@track newLogisticLineItems = [];
@track selectedDC = {
    Id: null,
    Name: '',
    Active__c: true,
    Priority__c: '',
    Site__c: null,
    Site__r: {
        Id: '',
        Name: '',
        Address__c: '',
        Address__r: { Id:'', Name:'' },
        Primary_Contact__c: '',
        Primary_Contact__r: { Id:'', Name:'' }
    }
};
@track account = {Id : '',Name : ''};

distributionUrl = null;

// Auto-filled from order + DC Site
fromContactId = null;
fromContactName = '';
fromContactUrl = null;

fromAddressId = null;
fromAddressName = '';
fromAddressUrl = null;

toContactId = null;
toContactName = '';
toContactUrl = null;

toAddressId = null;
toAddressName = '';
toAddressUrl = null;

accountId = null;
accountName = '';
accountUrl = null;
@track selectedChannel = null;
@track selectedChannelName = '';
@track channelUrl = null;

// loadOrderData() {
//     if (!this.recordId) return;

//     this.isLoading = true;
//     getOrderAndItemsAnalysis({ orderId: this.recordId })
//         .then(res => {
//             this.order = res.order;
//             this.orderLineItems = res.items;
//             this.existingLogistics = res.logistics || res.logistics; 

//             console.log('🚛 Existing Logistics:', JSON.stringify(this.existingLogistics));

//             console.log('order -> ', JSON.stringify(this.order));
//             console.log('items -> ', JSON.stringify(this.orderLineItems));

//             const orderQty    = this.order?.Total_Quantity__c || 0;
//             const logisticQty = this.order?.Total_Logistic_Quantity_U__c || 0;

//             // ✅ Correct flag logic
//             this.showOrderToLogisticsStep = (orderQty !== logisticQty);
//              const dc = res.distributionChannelRaw || res.distributionChannel || null;
//              if (dc) {
//                 this.selectedDC = {
//                     Id: dc.Id,
//                     Name: dc.Name,
//                     Active__c: true,
//                     Priority__c: dc.Priority__c || '',
//                     Site__c: dc.Site__c || null,

//                     Site__r: {
//                         Id: dc.Site__r?.Id || '',
//                         Name: dc.Site__r?.Name || '',
//                         Address__c: dc.Site__r?.Address__c || '',
//                         Address__r: {
//                             Id: dc.Site__r?.Address__r?.Id || '',
//                             Name: dc.Site__r?.Address__r?.Name || ''
//                         },
//                         Primary_Contact__c: dc.Site__r?.Primary_Contact__c || '',
//                         Primary_Contact__r: {
//                             Id: dc.Site__r?.Primary_Contact__r?.Id || '',
//                             Name: dc.Site__r?.Primary_Contact__r?.Name || ''
//                         }
//                     }
//                 };

//                 console.log('📍 selectedDC →', JSON.stringify(this.selectedDC));
//             }

//             // ✅ MOST IMPORTANT → map into the variable used in HTML loop
//             this.orderLineAnalysis = (res.items || []).map(x => {
//                 const rec = x.record;
//                 return {
//                     Id: rec?.Id,
//                     orderItemNumber: rec?.OrderItemNumber,
//                     productName: rec?.Product2?.Name,
//                     productId: rec?.Product2?.Id,
//                     orderQty: rec?.Quantity,
//                     logisticQty: rec?.Logistic_Quantity_U__c || rec?.Logistic_Quantity__c || 0,
//                     remainingQty: x.remainingQty
//                 };
//             });

//             console.log('🧠 Mapped Items:', JSON.stringify(this.orderLineAnalysis));
//             console.log('📦 Order Qty:', orderQty);
//             console.log('🚚 Logistic Total Qty:', logisticQty);
//             console.log('🧩 showOrderToLogisticsStep:', this.showOrderToLogisticsStep);
//         })
//         .catch(err => console.error('❌ Error', err))
//         .finally(() => {
//             this.isLoading = false;
//         });
// }
// Channel lookup selected?
get channelSelected() {
    return this.selectedChannel != null;
}

// Distribution Channel lookup selected?
get dcSelected() {
    return this.selectedDC?.Id != null;
}

// From Contact selected?
get fromContactSelected() {
    return this.fromContactId != null;
}

// To Contact selected?
get toContactSelected() {
    return this.toContactId != null;
}

// From Address selected?
get fromAddressSelected() {
    return this.fromAddressId != null;
}

// To Address selected?
get toAddressSelected() {
    return this.toAddressId != null;
}

// Account selected?
get accountSelected() {
    return this.accountId != null;
}

// Logistic name selected? (we consider parent exists if name not null)
get logisticNameSelected() {
    return this.newLogistic?.Name != null;
}

loadOrderData() {
    if (!this.recordId) return;

    this.isLoading = true;
    getOrderAndItemsAnalysis({ orderId: this.recordId })
        .then(res => {

            this.existingLogistics = res.logistics || res.logistics; 
            this.order = res.order || {};
            console.log('Order:', JSON.stringify(this.order));
            // ===== MAP CHANNEL FROM ORDER =====
            this.selectedDC = this.selectedDC || {};
            this.selectedChannel = this.order?.Channel__c || null;
            this.selectedChannelName = this.order?.Channel__r?.Name || '';
            this.channelUrl = this.selectedChannel ? '/' + this.selectedChannel : null;
        
            // ===== MAP TOP PRIORITY DC =====
            const dc = res.distributionChannel || null;

            console.log('Distribution Channel:', JSON.stringify(dc));
            if (dc) {
                this.selectedDC = {
                    Id: dc.Id,
                    Name: dc.Name,
                    Active__c: true,
                    Priority__c: dc.Priority__c || '',
                    Site__c: dc.Site.siteId || null,

                    Site__r: {
                        Id: dc.Site.siteId || '',
                        Name: dc.Site.siteName || '',
                        Address__c: dc.Site.siteAddressId || '',
                        Address__r: {
                            Id: dc.Site.siteAddressId || '',
                            Name: dc.Site.siteAddressName || ''
                        },
                        Primary_Contact__c: dc.Site.sitePrimaryContactId || '',
                        Primary_Contact__r: {
                            Id: dc.Site.sitePrimaryContactId || '',
                            Name: dc.Site.sitePrimaryContactName || ''
                        }
                    }
                };
                this.distributionUrl = this.selectedDC?.Id ? '/' + this.selectedDC?.Id : null;
                console.log('📍 Top priority DC mapped →', JSON.stringify(this.selectedDC));
            }

            // ===== AUTO-FILL STEP 2 VALUES FROM ORDER & DC =====
            this.fromContactId = this.selectedDC?.Site__r?.Primary_Contact__c || null;
            this.fromContactName = this.selectedDC?.Site__r?.Primary_Contact__r?.Name || '';
            this.fromContactUrl = this.fromContactId ? '/' + this.fromContactId : null;

            this.fromAddressId = this.selectedDC?.Site__r?.Address__c || null;
            this.fromAddressName = this.selectedDC?.Site__r?.Address__r?.Name || '';
            this.fromAddressUrl = this.fromAddressId ? '/' + this.fromAddressId : null;

            this.toContactId = this.order?.Contact__c || null;
            this.toContactName = this.order?.Contact__r?.Name || '';
            this.toContactUrl = this.toContactId ? '/' + this.toContactId : null;

            this.toAddressId = this.order?.Ship_To_Address__c || null;
            this.toAddressName = this.order?.Ship_To_Address__r?.Name ||  '';
            this.toAddressUrl = this.toAddressId ? '/' + this.toAddressId : null;

            this.accountId = this.order?.AccountId || null;
            this.accountName = this.order?.Account?.Name || this.order?.Account__r?.Name || '';
            this.accountUrl = this.accountId ? '/' + this.accountId : null;

            // Compare totals for step-1 visibility
            const orderQty = Number(this.order?.Total_Quantity__c || 0);
            const logisticQty = Number(this.order?.Total_Logistic_Quantity_U__c || 0);
            this.showOrderToLogisticsStep = (orderQty !== logisticQty);

            // Map order items for Step-1 table
            //this.orderLineAnalysis = (res.items || []).map(x => x);
             this.orderLineAnalysis = (res.items || []).map(x => {
                const rec = x.record;
                return {
                    Id: rec?.Id,
                    orderItemNumber: rec?.OrderItemNumber,
                    productName: rec?.Product2?.Name,
                    productId: rec?.Product2?.Id,
                    orderQty: rec?.Quantity,
                    totalQty: rec?.Quantity || 0,
                    priceProductC: rec?.UnitPrice || 0,
                    logisticQty: x?.logisticQty || x?.logisticQty || 0,
                    remainingQty: x.remainingQty,
                    isDisabled: x.remainingQty <= 0
                };
            });

            console.log('📦 Step-1 Analysis mapped →', JSON.stringify(this.orderLineAnalysis));
            this.refreshSelections();
        })
        .catch(err => console.error('❌ Error', err))
        .finally(() => this.isLoading = false);
}
handleRowSelect(e) {
    const id = e.target.dataset.id;
    const checked = e.target.checked;

    console.log('Row selected:', id, checked);

    // Find row in orderLineAnalysis
    this.orderLineAnalysis = this.orderLineAnalysis.map(row => {
        if (row.Id === id) {

            // Prevent selecting disabled rows
            if (row.isDisabled) {
                e.target.checked = false;
                return row;
            }

            // Update UI flag
            row.isSelected = checked;

            // Update selectedProductIds list
            if (checked) {
                if (!this.selectedProductIds.includes(row.productId)) {
                    this.selectedProductIds = [
                        ...this.selectedProductIds,
                        row.productId
                    ];
                }
            } else {
                this.selectedProductIds = this.selectedProductIds.filter(
                    pid => pid !== row.productId
                );
            }
        }
        return row;
    });

    console.log('Selected Products:', JSON.stringify(this.selectedProductIds));
}

refreshSelections() {
    this.orderLineAnalysis = this.orderLineAnalysis.map(row => ({
        ...row,
        isSelected: !row.isDisabled && this.selectedProductIds.includes(row.productId)
    }));
}

itemRowClass(item) {
    return item.isDisabled ? 'disabled-row' : '';
}


handleDCRemoval() {
    this.selectedDC = {
        Id: null,
        Name: '',
       
    };
    this.distributionUrl = null;
    console.log('Distribution Channel cleared');
}

handleDCSelection(event) {
    const selected = event.detail || {};
console.log('selected',selected);

    if(selected == null || selected?.Id == null){
        console.log('Error', 'No Distribution Channel selected', 'error');
        return;
    }

    if(this.recordId  == null){ // show tost that no order found
        this.showToast('Error', 'No Order found to fetch details', 'error');
        return;
    }

    this.isLoading = true;
    getOrderAndDcDetails({orderId: this.recordId ,  dcId: selected?.Id  })
        .then(res => {

            this.existingLogistics = res.logistics || res.logistics; 
            this.order = res.order || {};
            console.log('Order:', JSON.stringify(this.order));
            // ===== MAP CHANNEL FROM ORDER =====
            this.selectedDC = this.selectedDC || {};
            this.selectedChannel = this.order?.Channel__c || null;
            this.selectedChannelName = this.order?.Channel__r?.Name || '';
            this.channelUrl = this.selectedChannel ? '/' + this.selectedChannel : null;
        
            // ===== MAP TOP PRIORITY DC =====
            const dc = res.distributionChannel || null;

            console.log('Distribution Channel:', JSON.stringify(dc));
            if (dc) {
                this.selectedDC = {
                    Id: dc.Id,
                    Name: dc.Name,
                    Active__c: true,
                    Priority__c: dc.Priority__c || '',
                    Site__c: dc.Site.siteId || null,

                    Site__r: {
                        Id: dc.Site.siteId || '',
                        Name: dc.Site.siteName || '',
                        Address__c: dc.Site.siteAddressId || '',
                        Address__r: {
                            Id: dc.Site.siteAddressId || '',
                            Name: dc.Site.siteAddressName || ''
                        },
                        Primary_Contact__c: dc.Site.sitePrimaryContactId || '',
                        Primary_Contact__r: {
                            Id: dc.Site.sitePrimaryContactId || '',
                            Name: dc.Site.sitePrimaryContactName || ''
                        }
                    }
                };
                this.distributionUrl = this.selectedDC?.Id ? '/' + this.selectedDC?.Id : null;
                console.log('📍 Top priority DC mapped →', JSON.stringify(this.selectedDC));
            }

            // ===== AUTO-FILL STEP 2 VALUES FROM ORDER & DC =====
            this.fromContactId = this.selectedDC?.Site__r?.Primary_Contact__c || null;
            this.fromContactName = this.selectedDC?.Site__r?.Primary_Contact__r?.Name || '';
            this.fromContactUrl = this.fromContactId ? '/' + this.fromContactId : null;

            this.fromAddressId = this.selectedDC?.Site__r?.Address__c || null;
            this.fromAddressName = this.selectedDC?.Site__r?.Address__r?.Name || '';
            this.fromAddressUrl = this.fromAddressId ? '/' + this.fromAddressId : null;

            this.toContactId = this.order?.Contact__c || null;
            this.toContactName = this.order?.Contact__r?.Name || '';
            this.toContactUrl = this.toContactId ? '/' + this.toContactId : null;

            this.toAddressId = this.order?.Ship_To_Address__c || null;
            this.toAddressName = this.order?.Ship_To_Address__r?.Name ||  '';
            this.toAddressUrl = this.toAddressId ? '/' + this.toAddressId : null;

            this.accountId = this.order?.AccountId || null;
            this.accountName = this.order?.Account?.Name || this.order?.Account__r?.Name || '';
            this.accountUrl = this.accountId ? '/' + this.accountId : null;

            // Compare totals for step-1 visibility
            const orderQty = Number(this.order?.Total_Quantity__c || 0);
            const logisticQty = Number(this.order?.Total_Logistic_Quantity_U__c || 0);
            this.showOrderToLogisticsStep = (orderQty !== logisticQty);

            // Map order items for Step-1 table
            //this.orderLineAnalysis = (res.items || []).map(x => x);
             this.orderLineAnalysis = (res.items || []).map(x => {
                const rec = x.record;
                return {
                    Id: rec?.Id,
                    orderItemNumber: rec?.OrderItemNumber,
                    productName: rec?.Product2?.Name,
                    productId: rec?.Product2?.Id,
                    orderQty: rec?.Quantity,
                    totalQty: rec?.Quantity || 0,
                    priceProductC: rec?.UnitPrice || 0,
                    logisticQty: x?.logisticQty || x?.logisticQty || 0,
                    remainingQty: x.remainingQty,
                    isDisabled: x.remainingQty <= 0
                };
            });


            if(this.selectedDC?.Id  != null){
                this.handleCreateLogistic();
            }

            console.log('📦 Step-1 Analysis mapped →', JSON.stringify(this.orderLineAnalysis));
            this.refreshSelections();

        })
        .catch(err => console.error('❌ Error', err))
        .finally(() => this.isLoading = false);

        
}

handleChannelSelection(event) {
    const selected = event.detail || {};
            if(this.selectedChannel != selected.Id){
        this.handleDCRemoval();   
        }
    console.log('Channel selected:', JSON.stringify(selected));

    if (selected == null || selected?.Id == null) {
        console.log('Error', 'No Channel selected', 'error');
        return;
    }

    this.selectedChannel = selected.Id;
    this.selectedChannelName = selected.Name || '';
    this.channelUrl = this.selectedChannel ? '/' + this.selectedChannel : null;

    

    console.log('✅ Channel set to:', this.selectedChannel);
} 

handleQuantityChange(event) {
    try {
        // Use currentTarget to read data-id from <lightning-input>
        const recordId = event.currentTarget.dataset.id;
        console.log('record id = ', recordId);

        // Value from lightning-input comes in event.detail.value
        let newQtyRaw = event.detail.value;
        let newQty =
            newQtyRaw === '' || newQtyRaw === null || newQtyRaw === undefined
                ? 0
                : Number(newQtyRaw);

        // Validate numeric
        if (isNaN(newQty)) {
            this.showToast('Error', 'Quantity must be a number', 'error');
            event.target.value = 0;
            return;
        }

        // Negative check
        if (newQty < 0) {
            this.showToast('Error', 'Quantity cannot be negative', 'error');
            event.target.value = 0;
            newQty = 0;
        }

        // Find line item
        const line = this.newLogisticLineItems.find(li => li.tempKey === recordId);
        if (!line) {
            this.showToast('Error', 'Line item not found', 'error');
            return;
        }

        // Remaining qty (QuantityValue is remaining qty)
        const maxQty = Number(line.QuantityValue) || 0;

        if (newQty > maxQty) {
            this.showToast(
                'Error',
                `Quantity cannot exceed remaining quantity of ${maxQty}`,
                'error'
            );
            event.target.value = maxQty;
            newQty = maxQty;
        }

        // Update lineItems with newQuantityValue
        this.newLogisticLineItems = this.newLogisticLineItems.map(li => {
            if (li.tempKey === recordId) {
                return { ...li, newQuantityValue: newQty };
            }
            return li;
        });

    } catch (error) {
        // eslint-disable-next-line no-console
        console.log('in the qty change error = ', error);
    }
}



handleChannelRemoval() {
    this.selectedChannel = null;
    this.selectedChannelName = '';
    this.channelUrl = null;
    console.log('Channel cleared');
}

get dcFilter() {
    //dc filter based on selected channel
    if (this.selectedChannel) {
        return ` AND Channel__c = '${this.selectedChannel}' `;
    }
    return '';
}   


async handleCreateLogistic() {

    this.isLoading = true;
    try {
        const res = await getTotalStockPerProduct({
            productIds: this.selectedProductIds,
            channel: '',
            distributionChannel: this.selectedDC?.Id || ''
        });
        
        console.log('🧾 Stock Result:', JSON.stringify(res));

        this.stockMap = res; // store for next step ✅
        this.buildNewLogisticAndLines(); // go to next logic ✅
        // ✅ Move to Step-2 UI
    // this.showOrderToLogisticsStep = false;
    this.showCreateLogisticStep = true;


    } catch(err) {
        console.error(err.body?.message || 'Unexpected error');
        console.log('Error:', err.body?.message || 'Unexpected error');
        this.showToast('Error', err.body?.message || 'Unexpected error', 'error');
        this.showToast('Error', 'Stock fetch failed', 'error');
    } finally {
        this.isLoading = false;
    }
}
buildNewLogisticAndLines() {
    console.log('Building new Logistic and Lines...');
    const orderName = this.order?.Name || 'Order';

    const nextNumber = (this.existingLogistics?.length || 0) + 1;
    const channel = this.order?.Channel__c || null;
    const distChannel = this.selectedDC?.Id || null;

    // Build Logistic
    this.newLogistic = {
        Id: null,
        Name: `${orderName}-Logistic-${nextNumber}`,
        Order_S__c: this.recordId,
        Account__c: this.order?.AccountId || null,
        From_Contact__c: this.fromContactId || null,
        Contact__c: this.order?.Contact__c || null,
        From_Address__c: this.fromAddressId || null,
        To_Address__c: this.toAddressId || null,
        Channel__c: channel,
        Distribution_Channel__c: distChannel,
        Company__c: this.order?.Company__c || null,
        Billing_Address__c: this.toAddressId || null,
        Active__c: true,
	    Type__c: "Outbound",
        Shipment_type_Return__c: "--None--",
        Bill_To_Return__c: "SENDER",
        Active__c: true,
        Shipment_type__c: "--None--",
        Shipping_Preferences__c: "",
        Shipping_Preferences_Return__c: "",
    };

    // Build Line Items + Stock + Temp Keys
    const newLines = [];
    console.log('Building new Logistic and Lines...');
    console.log('Selected Product IDs:', this.selectedProductIds);
    console.log('Order Line Analysis:', JSON.stringify(this.orderLineAnalysis));
    this.selectedProductIds.forEach((productId, i) => {
        const found = this.orderLineAnalysis.find(x => x.productId === productId);
        console.log('Found:', JSON.stringify(found));
        if (!found) return;

        const ln = i + 1;
        const tempKey = `temp-${productId}-${ln}`; // ✅ Unique, never null

        newLines.push({
            tempKey,                     // ✅ loop key
            logisticUrl: `/${tempKey}`,  // Optional for preview navigation
            Product__c: productId,
            productName: found.productName || '',
            QuantityValue: found.remainingQty || 0,
            newQuantityValue: found.remainingQty || 0,
            logisticQty: found.logisticQty || 0,
            Order_Product__c: found.Id || null,
            Price_Product__c: found.priceProductC || 0,
            totalQty: found.totalQty || 0,
            Logistic__c: "",
            StockValue: this.stockMap[productId].totalQty || 0,
            Name: `${found.productName} - LogisticLine-${ln}`,
            Product__r: {
                Id: productId,
                Name: found.productName || ''
            }
        });
    });

    this.newLogisticLineItems = newLines;

    console.log('🚛 newLogistic →', JSON.stringify(this.newLogistic));
    console.log('📦 newLogisticLineItems →', JSON.stringify(this.newLogisticLineItems));
}

handleSaveLogistic() {
    console.log('Saving new Logistic and Lines...');
    if (!this.logisticNameSelected) {
        this.showToast('Error', 'Please enter a name for the Logistic.', 'error');
        return;
    }
    if (!this.dcSelected) {
        this.showToast('Error', 'Please select a Distribution Channel.', 'error');
        return;
    }
    if (!this.fromContactSelected) {
        this.showToast('Error', 'Please select a From Contact.', 'error');
        return;
    }
    if (!this.toContactSelected) {
        this.showToast('Error', 'Please select a To Contact.', 'error');
        return;
    }
    if (!this.fromAddressSelected) {
        this.showToast('Error', 'Please select a From Address.', 'error');
        return;
    }
    if (!this.toAddressSelected) {
        this.showToast('Error', 'Please select a To Address.', 'error');
        return;
    }

    // Validate line items quantities
    for (const line of this.newLogisticLineItems) {
        if (line.newQuantityValue <= 0) {
            this.showToast('Error', `Quantity for product ${line.productName} must be greater than zero.`, 'error');
            return;
        }
        if (line.newQuantityValue > line.StockValue) {
            this.showToast('Error', `Quantity for product ${line.productName} exceeds available stock (${line.StockValue}).`, 'error');
            return;
        }
    }

    // Prepare data for Apex
    const logisticToSave = { ...this.newLogistic };

    const linesToSave = this.newLogisticLineItems.map(line => ({
        Name: line.Name,
        Product__c: line.Product__c,
        Quantity__c: Number(line.newQuantityValue) || 0,
        Price_Product__c: line.Price_Product__c || 0,
        Order_Product__c: line.Order_Product__c || null,
        Logistic__c: line.Logistic__c || '',
        Product__r: {
            Id: (line.Product__r && line.Product__r.Id) ? line.Product__r.Id : line.Product__c,
            Name: (line.Product__r && line.Product__r.Name) ? line.Product__r.Name : (line.productName || '')
        }
    }));
    
    this.isLoading = true;

    console.log('before saving logistic ');

    console.log('JSON.stringify(logisticToSave), ', JSON.stringify(logisticToSave));
    console.log('JSON.stringify(linesToSave), ', JSON.stringify(linesToSave));

    getCreateLogistics({
        LogisticJSON: JSON.stringify(logisticToSave),
        LLIListJSON: JSON.stringify(linesToSave),
        OrderLIneItems : '',
        BomItems : ''
    })
    .then(res => {
        // console.log('Logistic save response:', res);
        // if (res?.includes('Upserted SOLI ID:')) {
        //     this.showToast('Success', 'Logistic and Line Items created successfully.', 'success');
        //     // Reset and go back to Step-1
        //     this.showCreateLogisticStep = false;
        //     this.showOrderToLogisticsStep = true;
        //     this.loadOrderData(); // Refresh data
        // } else {
        //     this.showToast('Error', res?.message || 'Failed to save Logistic.', 'error');
        // }
        console.log('Logistic save response:', res);

            // If Apex returned an error message
            if (res == null  || res.logistic== null || res.logistic.Id == null) {
                this.showToast('Error', res.message, 'error');
                return;
            }

            // If success, Apex returned a Logistic__c object
            const logisticRecord = res?.logistic;

            if (logisticRecord && logisticRecord.Id) {
                const logisticId = logisticRecord.Id;
                const logisticName = logisticRecord.Name;

                // SUCCESS TOAST
                this.showToast('Success', `Logistic ${logisticName} created successfully.`, 'success');

                // SET THE SELECTED LOGISTIC VALUES
                this.logistics = {
                    Id: logisticId,
                    Name: logisticName
                };
                this.logisticsUrl = '/' + logisticId;
                this.logisticsSelected = true;

                console.log('📦 Selected Logistic__c from lookup:', this.logistics);

                // Hide and show screens
                this.showCreateLogisticStep = false;
                this.showOrderToLogisticsStep = false;
                // Load related details
                this.fetchLogisticLineItems();
                this.loadLogisticDetails(logisticId);

            } else {
                this.showToast('Error', 'Failed to save Logistic.', 'error');
            }
    })
    .catch(err => {
        console.error('Error saving Logistic:', err);
        this.showToast('Error', err.body?.message || 'Unexpected error while saving Logistic.', 'error');
    })
    .finally(() => {
        this.isLoading = false;
    });
}


handleSkip() {
    this.showOrderToLogisticsStep = false;
    console.log('Skipping Order → Logistic creation step');
}

openOrderItemRecord(e) {
    const id = e.currentTarget.dataset.id;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: id,
            objectApiName: 'OrderItem',
            actionName: 'view'
        }
    });
}

openProductRecord(e) {
    const id = e.currentTarget.dataset.id;
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: id,
            objectApiName: 'Product2',
            actionName: 'view'
        }
    });
}
get isCreateDisabled() {
    return this.selectedProductIds.length === 0;
}
handlePrevious() {
    console.log('Previous clicked');

    // ✅ Go back to Step-1 screen
    this.showCreateLogisticStep = false;
    this.showOrderToLogisticsStep = true;
}
openOrderItemRecord(e) {
    const id = e.currentTarget.dataset.id;
    if (id) this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: id, actionName: 'view' }});
}

openProductRecord(e) {
    const id = e.currentTarget.dataset.id;
    if (id) this[NavigationMixin.Navigate]({ type: 'standard__recordPage', attributes: { recordId: id, actionName: 'view' }});
}

}