import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import SOPlogo from '@salesforce/resourceUrl/SOPlogo';
import getDefaultOrganisation from '@salesforce/apex/sandOP.getDefaultOrganisation';

export default class SandOP extends NavigationMixin (LightningElement) {
    logoUrl = SOPlogo;

    @track DefaultOrganisation = { Id: '', Name: '' };
    @track isDataLoaded = false;
    @track currentTab = null;
    @track showChart = true;
    // Main tabs
    @track isDemandTabOpen = true;
    @track isSupplyTabOpen = false;
    @track isInventoryTabOpen = false;
    @track isProductionTabOpen = false;
    @track isFinanceTabOpen = false;
    @track isExecutiveTabOpen = false;
    @track isRiskAndReturnTabOpen = false;
    @track isSubscriptionTabOpen = false;

    supplyAndProductionConstructor;
    demandPlanningConstructor;
    financialPlanningConstructor;
    subscriptionPlanningConstructor;

    // Removed dynamic loading - testing direct HTML rendering

    // Subtab value
    @track selectedForecastType = 'Short';

    connectedCallback() {
        this.loadDefaultOrganisation();
        this.loadDynamicComponents();
    }

    async loadDynamicComponents() {
        // Define components to load with their property names
        const componentsToLoad = [
            {
                path: 'c/supplyandproduction',
                property: 'supplyAndProductionConstructor',
            },
            {
                path: 'c/financialplanning',
                property: 'financialPlanningConstructor',
            },
            {
                path: 'c/demandplanning',
                property: 'demandPlanningConstructor',
            },
            {
                path: 'c/subscriptionplanning',
                property: 'subscriptionPlanningConstructor',
            }
        ];

        // Load all components
        const promises = componentsToLoad.map(component =>
            this.importComponent(component.path, component.property)
        );

        // Wait for all imports to complete (optional)
        try {
            await Promise.allSettled(promises);
            console.log('All dynamic components loaded');
        } catch (error) {
            console.error('Error loading some components:', error);
        }
    }

    async importComponent(componentPath, propertyName) {
        try {
            const { default: constructor } = await import(componentPath);
            this[propertyName] = constructor;
            console.log(`${propertyName} component loaded successfully`);
        } catch (error) {
            console.error(`Error importing ${propertyName} component:`, error);
        }
    }

//     renderedCallback() {
//   const orgId = this?.DefaultOrganisation?.Id;
//   if (!orgId || !this.isDataLoaded) return;

//   if (this.refs.demand) {
//     this.refs.demand.initContext({
//       organisationId: orgId,
//       flags: { isDemandTabOpen: this.isDemandTabOpen }
//     });
//   }


// }


// navigateToSupply method removed - using dynamic loading instead

    loadDefaultOrganisation() {
        getDefaultOrganisation()
            .then(result => {
                this.DefaultOrganisation = { Id: result.Id, Name: result.Name };
                this.isDataLoaded = true;
            })
            .catch(error => {
                console.error('Error fetching default organisation:', error);
            });
    }

      handleOrganisationRemoved() {
        console.log('Organisation lookup cleared');
        this.DefaultOrganisation = { Id: null, Name: null };
        this.showChart = false; // hide charts → show SVGs instead
    }


    handleOrganisationSelect(event) {
        // this.DefaultOrganisation = { Id: event.detail.Id, Name: event.detail.Name };
        this.DefaultOrganisation.Id = event.detail.Id;
        this.DefaultOrganisation.Name = event.detail.Name;
         this.showChart = true;
        console.log('Selected Organisation:', JSON.stringify(this.DefaultOrganisation));
        this.isDataLoaded = true;
        this.resetTabs();
        if (this.currentTab == null) this.currentTab = 'demand';
        switch (this.currentTab) {
            case 'demand':
                setTimeout(() => {

                    this.isDemandTabOpen = true;
                    this.currentTab = 'demand';
                    console.log('Demand tab clicked');
                    this.selectedForecastType = 'Short'; // Default subtab

                }, 50);
                break;

            case 'supply':
                setTimeout(() => {
                    this.isSupplyTabOpen = true;
                    this.currentTab = 'supply';
                    console.log('supply tab clicked - direct HTML rendering');
                }, 50);
                break;
            case 'inventory':
                setTimeout(() => {

                    this.isInventoryTabOpen = true;
                    this.currentTab = 'inventory';
                    console.log('Inventory tab clicked');
                }, 50);
                break;
            case 'production':
                setTimeout(() => {

                    this.isProductionTabOpen = true;
                    this.currentTab = 'production';
                    console.log('Production tab clicked');
                }, 50);
                break;
            case 'finance':
                setTimeout(() => {

                    this.isFinanceTabOpen = true;
                    this.currentTab = 'finance';
                }, 50);
                break;
            case 'executive':
                setTimeout(() => {

                    this.isExecutiveTabOpen = true;
                    this.currentTab = 'executive';
                }, 50);
                break;
            case 'subscription':
                setTimeout(() => {

                    this.isSubscriptionTabOpen = true;
                     }, 50);
                break;
            case 'riskAndReturn':
                setTimeout(() => {

                    this.isRiskAndReturnTabOpen = true; console.log('Risk and Return tab clicked');
                    this.currentTab = 'riskAndReturn';
                }, 50);
                break;
        }
    }

    resetTabs() {
        this.isDemandTabOpen = false;
        this.isSupplyTabOpen = false;
        this.isInventoryTabOpen = false;
        this.isProductionTabOpen = false;
        this.isFinanceTabOpen = false;
        this.isExecutiveTabOpen = false;
        this.isRiskAndReturnTabOpen = false;
        this.isSubscriptionTabOpen = false;

        // No dynamic loading cleanup needed
    }



    handleMainTabClick(event) {
        const tab = event.currentTarget.dataset.tab;
        this.resetTabs();
        switch (tab) {
            case 'demand':
                this.isDemandTabOpen = true;
                this.currentTab = 'demand';
                this.selectedForecastType = 'Short'; // Default subtab
                break;
            case 'supply':
                this.isSupplyTabOpen = true;
                this.currentTab = 'supply';
                console.log('Supply tab clicked - testing direct HTML rendering');
                break;
            case 'inventory':
                this.isInventoryTabOpen = true;
                this.currentTab = 'inventory';
                break;
            case 'production':
                this.isProductionTabOpen = true;
                this.currentTab = 'production';
                break;
            case 'finance':
                this.isFinanceTabOpen = true;
                this.currentTab = 'finance';
                break;
            case 'executive':
                this.isExecutiveTabOpen = true;
                this.currentTab = 'executive';
                break;
            case 'subscription':
                this.isSubscriptionTabOpen = true;
                this.currentTab = 'subscription';
                break;
            case 'riskAndReturn':
                this.isRiskAndReturnTabOpen = true; console.log('Risk and Return tab clicked');
                this.currentTab = 'riskAndReturn';
                break;
        }
    }

    // Handle subtab switching
    handleSubTabClick(event) {
        this.selectedForecastType = event.currentTarget.dataset.subtab;
    }

    // Subtab active class bindings
    get shortTermTabClass() {
        return `slds-tabs_default__link ${this.selectedForecastType === 'Short' ? 'slds-active' : ''}`;
    }

    get midTermTabClass() {
        return `slds-tabs_default__link ${this.selectedForecastType === 'Mid' ? 'slds-active' : ''}`;
    }

    get longTermTabClass() {
        return `slds-tabs_default__link ${this.selectedForecastType === 'Long' ? 'slds-active' : ''}`;
    }

    // Main tab styling (optional)
    get demandTabClass() {
        return `tab-item ${this.isDemandTabOpen ? 'active-tab' : ''}`;
    }
    get supplyTabClass() {
        return `tab-item ${this.isSupplyTabOpen ? 'active-tab' : ''}`;
    }
    get inventoryTabClass() {
        return `tab-item ${this.isInventoryTabOpen ? 'active-tab' : ''}`;
    }
    get productionTabClass() {
        return `tab-item ${this.isProductionTabOpen ? 'active-tab' : ''}`;
    }
    get financeTabClass() {
        return `tab-item ${this.isFinanceTabOpen ? 'active-tab' : ''}`;
    }
    get executiveTabClass() {
        return `tab-item ${this.isExecutiveTabOpen ? 'active-tab' : ''}`;
    }
    get riskAndReturnTabClass() {
        return `tab-item ${this.isRiskAndReturnTabOpen ? 'active-tab' : ''}`;
    }
    get subscriptionTabClass() {
        return `tab-item ${this.isSubscriptionTabOpen ? 'active-tab' : ''}`;
    }
}