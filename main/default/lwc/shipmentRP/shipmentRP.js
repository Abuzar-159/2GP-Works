import { LightningElement, track } from 'lwc';

// Helper to generate unique IDs
let packageId = 1; 

// Define a default structure for a single package (used for newly added packages)
const DEFAULT_PACKAGE = {
    id: packageId,
    class: 'slds-hide', // Starts collapsed
    icon: 'utility:chevronright', // Chevron icon
    ShipmentType: null, ShipmentMode: null, FVPackageType: null,
    DeclaredValue: null, Length: null, Width: null, Height: null,
    DimensionUnit: null, Weight: 10, WeightUnit: 'kg', 
    PONumber: null, DepositTag: null, FreightClass: null, NMFCCode: null,
    IsHazmat: false, HazmatID: null, HazardClass: null, PackagingGroup: null
};

// Dummy Data for Tables
const DUMMY_LOGISTICS_DATA = [
    { id: '1', logisticsName: '0001328-Logistic-1', order: '0001328', channel: 'Direct Sales DC', quantity: '10.00', type: 'Outbound' },
    { id: '2', logisticsName: '0001328-Logistic-2', order: '0001328', channel: 'Direct Sales DC', quantity: '16.00', type: 'Outbound' },
    { id: '3', logisticsName: '0001328-Logistic-3', order: '0001328', channel: 'Direct Sales DC', quantity: '16.00', type: 'Outbound' }
];

export default class ShipmentRP extends LightningElement {
    // === 1. TOP-LEVEL DATA AND VIEW STATE ===
    @track showSuccessScreen = false;
    logisticsData = DUMMY_LOGISTICS_DATA;

    // Package List Management: Initializes first package as OPEN
    @track packageList = [ 
        {
            ...DEFAULT_PACKAGE, 
            id: packageId++,
            class: 'slds-show', 
            icon: 'utility:chevrondown'
        } 
    ]; 

    // COMBOBOX OPTIONS
    shipmentTypeOptions = [{ label: 'LTL (Less than Truckload)', value: 'ltl' }, { label: 'FTL (Full Truckload)', value: 'ftl' }];
    shipmentModeOptions = [{ label: 'Standard', value: 'standard' }, { label: 'Express', value: 'express' }];
    fvPackageTypeOptions = [{ label: 'Box', value: 'box' }, { label: 'Pallet', value: 'pallet' }, { label: 'Crate', value: 'crate' }];
    weightUnitOptions = [{ label: 'kg', value: 'kg' }, { label: 'lb', value: 'lb' }];
    dimensionUnitOptions = [{ label: 'cm', value: 'cm' }, { label: 'in', value: 'in' }];
    freightClassOptions = [{ label: 'Class 50', value: '50' }, { label: 'Class 100', value: '100' }, { label: 'Class 250', value: '250' }];
    hazardClassOptions = [{ label: 'Class 3 (Flammable)', value: '3' }, { label: 'Class 8 (Corrosives)', value: '8' }];
    packagingGroupOptions = [{ label: 'Group I', value: 'I' }, { label: 'Group II', value: 'II' }];
    sortingOptions = [{ label: 'Price (Lowest to Highest)', value: 'price_asc' }, { label: 'Transit Time (Fastest)', value: 'time_asc' }];

    @track carrierOptions = [
        { name: 'FedEx', count: 2, days: '3', startingPrice: '$125.50+', isAffordable: true, isReliable: true, icon: 'utility:chevronright', class: 'sub-options-container slds-hide',
            services: [{ name: 'FedEx Ground Freight', price: '$125.50', value: 'FDX_Ground' }, { name: 'FedEx 2Day Freight', price: '$180.99', value: 'FDX_2Day' }] },
        { name: 'UPS', count: 1, days: '5', startingPrice: '$98.00+', isAffordable: false, isReliable: true, icon: 'utility:chevronright', class: 'sub-options-container slds-hide',
            services: [{ name: 'UPS Standard Freight', price: '$98.00', value: 'UPS_Standard' }] },
        { name: 'Freight View', count: 3, days: '2-5', startingPrice: '$110.00+', isAffordable: false, isReliable: false, isBestSelection: true, icon: 'utility:chevronright', class: 'sub-options-container slds-hide',
            services: [{ name: 'Freight View - FedEx LTL', price: '$155.10', value: 'FV_FDX' }, { name: 'Freight View - UPS Freight', price: '$110.00', value: 'FV_UPS' }, { name: 'Freight View - Regional Carrier', price: '$105.99', value: 'FV_Regional' }] },
    ];

    // === 2. PACKAGE MANAGEMENT METHODS ===

    addPackage() {
        this.packageList = [...this.packageList, {...DEFAULT_PACKAGE, id: ++packageId}];
    }

    removePackage(event) {
        const idToRemove = event.currentTarget.dataset.packageId;
        if (this.packageList.length === 1) {
            alert('You must have at least one package.');
            return;
        }
        this.packageList = this.packageList.filter(pkg => pkg.id != idToRemove);
    }

    handlePackageChange(event) {
        const id = event.target.dataset.packageId;
        const name = event.target.name;
        const value = (event.target.type === 'checkbox' || event.target.type === 'toggle') ? event.target.checked : event.target.value;
        
        this.packageList = this.packageList.map(pkg => {
            if (pkg.id == id) {
                if (name === 'IsHazmat') {
                    pkg.IsHazmat = value;
                }
                pkg[name] = value;
                
                // Simple header update for visibility
                if (name === 'Weight' || name === 'WeightUnit') {
                    pkg.Weight = (name === 'Weight') ? value : pkg.Weight;
                    pkg.WeightUnit = (name === 'WeightUnit') ? value : pkg.WeightUnit;
                }
            }
            return pkg;
        });
    }

    togglePackageDetails(event) {
        const idToToggle = event.currentTarget.dataset.packageId;
        
        this.packageList = this.packageList.map(pkg => {
            if (pkg.id == idToToggle) {
                const isExpanded = pkg.class.includes('slds-show');
                pkg.class = isExpanded ? 'slds-hide' : 'slds-show';
                pkg.icon = isExpanded ? 'utility:chevronright' : 'utility:chevrondown';
            }
            return pkg;
        });
    }

    // === 3. GENERAL EVENT HANDLERS ===
    
    toggleCarrierDetails(event) {
        const carrierName = event.currentTarget.dataset.carrier;
        const index = this.carrierOptions.findIndex(c => c.name === carrierName);
        if (index === -1) return;

        let newOptions = [...this.carrierOptions];
        let currentCarrier = newOptions[index];

        const isExpanded = currentCarrier.class.includes('slds-show');
        currentCarrier.class = isExpanded ? 'sub-options-container slds-hide' : 'sub-options-container slds-show';
        currentCarrier.icon = isExpanded ? 'utility:chevronright' : 'utility:chevrondown';
        
        this.carrierOptions = newOptions;
    }
    
    handleGetQuotes() {
        console.log('Fetching quotes based on package list...');
        // Add your quote fetching logic here
    }

    handleReadyToShip() {
        // Final action: Switches to success screen
        this.showSuccessScreen = true;
    }

    handleGoBackToForm() {
        // Returns to the form page
        this.showSuccessScreen = false;
    }
}