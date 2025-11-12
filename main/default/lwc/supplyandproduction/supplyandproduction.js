function formatDateLocal(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}


import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
// import { CurrentPageReference } from 'lightning/navigation';


import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/ChartJS';

//apex classes

//import getMonthlyDemandSupply from '@salesforce/apex/supplyPlanningController.getMonthlySupplyDemand';
import getSupplyDemandForecastWithHistory from '@salesforce/apex/supplyPlanningController.getSupplyDemandForecastWithHistory';
import getSpendOverTimeWithForecast from '@salesforce/apex/supplyPlanningController.getSpendOverTimeWithForecast';

import getSupplyDemandByCountry from '@salesforce/apex/supplyPlanningController.getSupplyDemandByCountry';
//import getSpendOverTime from '@salesforce/apex/supplyPlanningController.getSpendOverTime';
import getOnTimeDeliveryMapped from '@salesforce/apex/supplyPlanningController.getOnTimeDeliveryMapped';
import getMonthlyQualityData from '@salesforce/apex/supplyPlanningController.getMonthlyQualityData';
// import getInventoryData from '@salesforce/apex/supplyPlanningController.getInventoryData';
import getTop5SupplyAndDemand from '@salesforce/apex/supplyPlanningController.getTop5SupplyAndDemand';
import getTop5CountrySupplyDemand from '@salesforce/apex/supplyPlanningController.getTop5CountrySupplyDemand';
// import getInventoryByProductAndDate from '@salesforce/apex/supplyPlanningController.getInventoryByProductAndDate';
import getSummedInventory from '@salesforce/apex/supplyPlanningController.getSummedInventory';
import getTop5Inventory from '@salesforce/apex/supplyPlanningController.getTop5Inventory';
import getOrgFiscalStartMonth from '@salesforce/apex/supplyPlanningController.getOrgFiscalStartMonth';
import getDefaultTopVendor from '@salesforce/apex/supplyPlanningController.getDefaultTopVendor';
import getCurrencySymbol from '@salesforce/apex/supplyPlanningController.getCurrencySymbol';
import getDefaultWarehouseByStock from '@salesforce/apex/supplyPlanningController.getDefaultWarehouseByStock';
import getStockAlertData from '@salesforce/apex/supplyPlanningController.getStockAlertData';

import getMonthlySalesPriceStats from '@salesforce/apex/supplyPlanningController.getMonthlySalesPriceStats';
import getMonthlyPurchasePriceStats from '@salesforce/apex/supplyPlanningController.getMonthlyPurchasePriceStats';
import getMonthlyManufacturingUnitPriceStats from '@salesforce/apex/supplyPlanningController.getMonthlyManufacturingUnitPriceStats';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 


export default class SupplyPlanningSidebar extends  NavigationMixin(LightningElement) {

    //  @wire(CurrentPageReference)
    // getStateParameters(pageRef) {
    //     if (pageRef) {
    //         this.organisationId = pageRef.state.c__organisationId;
    //         this.showChart = pageRef.state.c__showChart === 'true';
    //     }
    // }
    
    @api organisationId;
    @api showChart ;
    //stock alert 
    // Sorting for Safety Stock Table
sortBySafety = 'productName';
sortDirectionSafety = 'asc';

// Pagination for Safety Stock Table
pageSizeSafety = 10;
currentPageSafety = 1;
    @track isSafety = false;
    @api isSafetyTabOpen;
    @track safetyStockData = [];
    @track filteredSafetyStockData = [];
    @track selectedProductFilterForSafetyStock = '';
    @track selectedWarehouse = null;
    @track selectedWarehouseForSafetyStock = { Id: null, Name: null };
    @track isWarehouseSelectedForsafetyStock = false;
    @track selectedProduct={Id:null,Name:null};
    @track selectedLocation={id:null,Name:null};
    @track isLoading=false;
     charts = {};
      stockTableColumns = [
    { label: 'Product', fieldName: 'productName' },
    { label: 'Warehouse', fieldName: 'warehouse' },
    { label: 'Location', fieldName: 'location' },
    { label: 'Current Stock', fieldName: 'currentStock', type: 'number' },
    { label: 'Reorder Level', fieldName: 'reorderLevel', type: 'number' },
    { label: 'Safety Stock', fieldName: 'safetyStock', type: 'number' },
    {
  label: 'Status',
  fieldName: 'badgeLabel',
  cellAttributes: {
    class: { fieldName: 'badgeClass' }
  }
}
];
//end
    @track isSupplyOverview = true;
    @track isSupplierScorecard = false;
    @track isInventoryLevel = false;
    @track isProcurementPlanning = false;
    @track inventoryProduct = { Id: '', Name: '' }; // stores selected product {Id, Name}
    @track chartInstances = {};
    //@track productOptions = [];
    //@track supplyDemandData = [];
    @track countrySupplyDemandData;
    chartInstances = {};
    isChartJsInitialized = false;
    @track issuppydemandloaded = false;
    @track availableYears = [];
    @track selectedYear;
    onTimeDeliveryData = [];
    listqualitydata = [];
    @track selectedProductName = null;
    @track topFiveRows = [];   // merged Demand+Supply rows
    @track inventoryProduct = {}; // or however you're storing selected product
    @track countrySupplyDemandData = []; // populated from Apex
    @track selectedProductId;
    @track salesPriceData = [];
    @track purchasePriceData = [];
    @track manufacturingPriceData = [];
    @track isProductSelected = false;
    // @track showChart = true;
    @track showMoDetails = false;
    @track selectedRowMo;         
    @track selectedMOStatusData = []; 
    @track moOrderBy = { complete:null, inProgress:null, draft:null, cancelled:null, release:null };
    @track moOrder   = { complete:'ASC', inProgress:'ASC', draft:'ASC', cancelled:'ASC', release:'ASC' };
// Page size like your example (but 5 as requested)
    pageSizeMoPrice = 5;
    pageSizePoPrice = 5;

    showPoDetails = false;
    selectedRowPo;
    PO_STATUSES = [
  'draft','logged','assigned','approved','rejected',
  'inProgress','booked','closed','cancelled',
  'supplierAccepted','reconciled','submittedForApproval','onHold'
];

// one currentPage per status (same idea as your single currentPage)
currentPageMoPrice = {
  complete: 1,
  inProgress: 1,
  draft: 1,
  cancelled: 1,
  release: 1
};
    
    currentPagePoPrice = { draft:1, logged:1, assigned:1, approved:1, rejected:1,
  inprogress:1, booked:1, closed:1, cancelled:1, supplieraccepted:1,
  reconciled:1, submittedforapproval:1, onhold:1 };
poSortState = { /* same keys, default {sortBy:'orderDate', sortDir:'asc'} */ };
    
    pageSizeSummary = 5;
currentPageSummary = {
  mfg: 1,
  sales: 1,
  purchase: 1
};

   poSortState = {
  draft: { sortBy: 'orderDate', sortDir: 'asc' },
  logged: { sortBy: 'orderDate', sortDir: 'asc' },
  assigned: { sortBy: 'orderDate', sortDir: 'asc' },
  approved: { sortBy: 'orderDate', sortDir: 'asc' },
  rejected: { sortBy: 'orderDate', sortDir: 'asc' },
  inprogress: { sortBy: 'orderDate', sortDir: 'asc' },   // use lowercase, no spaces
  booked: { sortBy: 'orderDate', sortDir: 'asc' },
  closed: { sortBy: 'orderDate', sortDir: 'asc' },
  cancelled: { sortBy: 'orderDate', sortDir: 'asc' },
  supplieraccepted: { sortBy: 'orderDate', sortDir: 'asc' },
  reconciled: { sortBy: 'orderDate', sortDir: 'asc' },
  submittedforapproval: { sortBy: 'orderDate', sortDir: 'asc' },
  onhold: { sortBy: 'orderDate', sortDir: 'asc' }
};

    showSoDetails = false;
    selectedRowSo = null;

    // which page per status (avoid separate getters per status)
pageSizeSo = 5;
currentPageSo = {
  draft: 1,
  entered: 1,
  activated: 1,
  pickedUp: 1,
  partiallyShipped: 1,
  shipped: 1,
  delivered: 1,
  cancelled: 1
};
    SO_KEY_MAP = {
  draft: 'soDraftList',
  entered: 'soEnteredList',
  activated: 'soActivatedList',
  pickedup: 'soPickedUpList',
  partiallyshipped: 'soPartiallyShippedList',
  shipped: 'soShippedList',
  delivered: 'soDeliveredList',
  cancelled: 'soCancelledList'
    };
    soSort = {};
    
    // sort state per status (EffectiveDate only)
soSort = {
  draft: { by: 'EffectiveDate', dir: 'asc' },
  entered: { by: 'EffectiveDate', dir: 'asc' },
  activated: { by: 'EffectiveDate', dir: 'asc' },
  pickedUp: { by: 'EffectiveDate', dir: 'asc' },
  partiallyShipped: { by: 'EffectiveDate', dir: 'asc' },
  shipped: { by: 'EffectiveDate', dir: 'asc' },
  delivered: { by: 'EffectiveDate', dir: 'asc' },
  cancelled: { by: 'EffectiveDate', dir: 'asc' }
};

    




    //supplier
    @track selectedYearSup = new Date().getFullYear();
    @track yearOptions = this.generateYearOptions();
    @track selectedVendorId;
    @track selectedVendorName;
    @track deliveryData = []; // Add this line to store the delivery data
    @track qualitydata = [];
    @track goodData = [];
    @track badData = [];
    @track labelsForQualityChart = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    @api vendorId;
    @api selectedYear;
    @track currencySymbol = '$'; // default fallback
    @track actualData;
    @track forecastData= [];
        @track hasForecastData = false; // Add this line
        

    //Inventory
    @track rawData = [];
    @track wipData = [];
    @track finishedData = [];
    @track fromDate;
    @track toDate;
    @track filterDate;
    @track productId;
    @track productName;
    @track inventoryData = [];
    @track inventoryLevelData = {};
    top5ChartPending = false;
    singleChartPending = false;
    isSingleProductView = false;

    @track showTable = false;
    @track error;
    @track summaryData;
    @track top5Data;
    @track chartRendered = false;
    chartJsInitialized = false;
    @track fiscalLabels = [];

    @track selectedYearType = 'Fiscal'; // Default selection
@track yearTypeOptions = [
    { label: 'Fiscal Year', value: 'Fiscal' },
    { label: 'Custom Year (Jan - Dec)', value: 'Custom' }
];
    @track isCustomYear = false;
@track selectedCustomYear = new Date().getFullYear(); // Default current year
    @track availableYearOptions = [];
    
    @track selectedSpendYearType = 'Fiscal'; // default
@track selectedSpendCustomYear = new Date().getFullYear();
    @track showSpendCustomYearSelector = false;
    


    chart;          // Chart.js instance
    chartJsReady = false;
    hasRenderedCountryChart = false;

forecastAlgorithmOptions = [
    { label: 'Holt-Winters (Seasonal)', value: 'Holt-Winters' }
];

    
    

    get chartTitle() {
        return this.selectedProductId
            ? `${this.selectedProductName}  Monthly Supply vs Demand`
            : 'Top 5 Products   Supply vs Demand';
    }

    get isProductSelected() {
        return this.inventoryProduct && this.inventoryProduct.Id;
    }

    // get isShowDefaultData() {
    //     console.log('selectedProductId =>>', this.selectedProductId);
    //     console.log('inventoryProduct.Id ===>>>>',this.inventoryProduct.Id);


    //     return this.selectedProductId == null;


    // }
    chartInstances = {
        spendChart: null,
        deliveryChart: null,
        qualityChart: null
    };

    navigateToReports() {
        // Opens Salesforce Reports Tab (Lightning Experience)
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Report',
                actionName: 'home'
            }
        });
    }


    get showCustomYearSelector() {
    return this.selectedYearType === 'Custom';
}


    get showDateFilters() {
    return this.selectedYearType === 'Custom';
}

    
// generateAvailableYearOptions() {
//     const currentYear = new Date().getFullYear();
//     const years = [];

//     for (let i = currentYear - 10; i <= currentYear + 10; i++) {
//         years.push({ label: i.toString(), value: i });
//     }

//     this.availableYearOptions = years;
    // }
    
    // 🧠 Button Classes for styling toggle buttons
get fiscalButtonClass() {
    return `year-button ${this.selectedYearType === 'Fiscal' ? 'selected' : ''}`;
}

get customButtonClass() {
    return `year-button ${this.selectedYearType === 'Custom' ? 'selected' : ''}`;
}
    
    //for supplier score card
    // Computed classes for button styling
get spendFiscalRadioClass() {
    return `radio-button ${this.selectedSpendYearType === 'Fiscal' ? 'active' : ''}`;
}
get spendCustomRadioClass() {
    return `radio-button ${this.selectedSpendYearType === 'Custom' ? 'active' : ''}`;
}


// Click handlers for year type selection buttons for the spend over time
selectSpendFiscalYear() {
    this.selectedSpendYearType = 'Fiscal';
    this.showSpendCustomYearSelector = false;
    this.handleSpendYearTypeChange({ detail: { value: 'Fiscal' } });

      if (this.isProductSelected && this.inventoryProduct.Id) {
        this.fetchPriceData();
          
    }
}

    selectSpendCustomYear() {
        this.selectedSpendYearType = 'Custom';
        this.showSpendCustomYearSelector = true;
        this.handleSpendYearTypeChange({ detail: { value: 'Custom' } });

        // ✅ Same logic for Custom year
        if (this.isProductSelected && this.inventoryProduct.Id) {
        this.fetchPriceData();
                  

    }
        }
    



// 🟦 Click handlers for buttons for the supply overview
async selectFiscalYear() {
    this.selectedYearType = 'Fiscal';
    await this.handleYearTypeChange({ detail: { value: 'Fiscal' } });

    if (this.inventoryProduct?.Id && this.fromDate && this.toDate) {
        this.fetchPriceData();
                  

    }
}

async selectCustomYear() {
    this.selectedYearType = 'Custom';
    await this.handleYearTypeChange({ detail: { value: 'Custom' } });

    if (this.inventoryProduct?.Id && this.fromDate && this.toDate) {
        this.fetchPriceData();
                  

    }
}

    // 🎯 Year slider range
get minCustomYear() {
    return new Date().getFullYear() - 5;
}
get maxCustomYear() {
    return new Date().getFullYear() + 5;
}

// 📩 Year typed in input box
handleCustomYearTextChange(event) {
    const inputYear = parseInt(event.target.value, 10);
    if (inputYear >= this.minCustomYear && inputYear <= this.maxCustomYear) {
        this.selectedCustomYear = inputYear.toString();
        this.setCustomYearDates(this.selectedCustomYear);
        this.loadAllChartData();
    }
}

// 📩 Year changed via slider
handleCustomYearSliderChange(event) {
    // const sliderYear = event.target.value;
    // this.selectedCustomYear = sliderYear;
    // this.setCustomYearDates(sliderYear);
    // this.loadAllChartData();

     this.selectedCustomYear = event.target.value;
    this.setCustomYearDates(this.selectedCustomYear);
    this.loadAllChartData();
     if (this.isProductSelected && this.inventoryProduct.Id) {
        this.fetchPriceData();
                  

    }
}
    
    decreaseYear() {
    let year = parseInt(this.selectedCustomYear, 10);
    if (year > this.minCustomYear) {
        this.selectedCustomYear = (year - 1).toString();
        this.setCustomYearDates(this.selectedCustomYear);
        this.loadAllChartData();
    }
}

increaseYear() {
    let year = parseInt(this.selectedCustomYear, 10);
    if (year < this.maxCustomYear) {
        this.selectedCustomYear = (year + 1).toString();
        this.setCustomYearDates(this.selectedCustomYear);
        this.loadAllChartData();
    }
}
    
    
    //supplier score caard

    get minCustomYear() {
    return new Date().getFullYear() - 5;
}
get maxCustomYear() {
    return new Date().getFullYear() + 5;
}

handleSpendYearSliderChange(event) {
    this.selectedSpendCustomYear = event.target.value;
    this.setCustomSpendYearAndLoadData();
}

increaseSpendYear() {
    let nextYear = parseInt(this.selectedSpendCustomYear) + 1;
    if (nextYear <= this.maxCustomYear) {
        this.selectedSpendCustomYear = nextYear.toString();
        this.setCustomSpendYearAndLoadData();
    }
}

decreaseSpendYear() {
    let prevYear = parseInt(this.selectedSpendCustomYear) - 1;
    if (prevYear >= this.minCustomYear) {
        this.selectedSpendCustomYear = prevYear.toString();
        this.setCustomSpendYearAndLoadData();
    }
}

setCustomSpendYearAndLoadData() {
    this.selectedYearSup = parseInt(this.selectedSpendCustomYear, 10);
    this.fetchSupplierData(); // Your existing method
}

    
    
    handleToggleChange(event) {
    this.selectedYearType = event.target.checked ? 'Custom' : 'Fiscal';
    this.handleYearTypeChange({ detail: { value: this.selectedYearType } });
}
    
// handleYearTypeChange(event) {
//     this.selectedYearType = event.detail.value;

//     if (this.selectedYearType === 'Fiscal') {
//         this.setFiscalDates()
//             .then(() => {
//                 console.log('📅 Fiscal dates set:', this.fromDate, '→', this.toDate);
//                 // 🧠 Ensure fiscalLabels are regenerated here
//                 return getOrgFiscalStartMonth();
//             })
//             .then((startMonth) => {
//                 const today = new Date();
//                 let fiscalYear = today.getFullYear();
//                 if (today.getMonth() + 1 < startMonth) {
//                     fiscalYear -= 1;
//                 }

//                 this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);
//                 console.log('🔁 Regenerated fiscalLabels:', this.fiscalLabels);

//                 // 💡 Reset other chart data if needed
//                 this.supplyData = new Array(12).fill(0);
//                 this.demandData = new Array(12).fill(0);
//                 this.forecastedSupplyData = new Array(12).fill(null);
//                 this.forecastedDemandData = new Array(12).fill(null);

//                 // 🔁 Re-load chart data
//                 this.loadAllChartData();
//             })
//             .catch(error => {
//                 console.error('❌ Error in fiscal year reset:', error);
//             });

//     } else if (this.selectedYearType === 'Custom') {
//         // this.setCustomYearDates(this.selectedCustomYear);
//         // this.loadAllChartData();

//          if (!this.selectedCustomYear) {
//             this.selectedCustomYear = new Date().getFullYear().toString();
//         }

//         this.setCustomYearDates(this.selectedCustomYear);
//         this.loadAllChartData();
//     }
    // }
    
    handleYearTypeChange(event) {
    return new Promise((resolve, reject) => {
        this.selectedYearType = event.detail.value;
            this.isLoading = true;
        if (this.selectedYearType === 'Fiscal') {
            this.setFiscalDates()
                .then(() => getOrgFiscalStartMonth())
                .then((startMonth) => {
                    const today = new Date();
                    let fiscalYear = today.getFullYear();
                    if (today.getMonth() + 1 < startMonth) {
                        fiscalYear -= 1;
                    }

                    this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);

                    // Reset chart data
                    this.supplyData = new Array(12).fill(0);
                    this.demandData = new Array(12).fill(0);
                    this.forecastedSupplyData = new Array(12).fill(null);
                    this.forecastedDemandData = new Array(12).fill(null);

                    // Reload chart data
                    this.loadAllChartData();

                    // ✅ All done, resolve
                    resolve();
                })
                .catch(error => {
                    console.error('❌ Error in fiscal year reset:', error);
                    reject(error);
                })
              .finally(() => {
                    this.isLoading = false;
                });
        } else if (this.selectedYearType === 'Custom') {
            if (!this.selectedCustomYear) {
                this.selectedCustomYear = new Date().getFullYear().toString();
            }

            this.setCustomYearDates(this.selectedCustomYear);
            this.loadAllChartData();

            // ✅ Custom year is synchronous here, resolve immediately
            resolve();
        }
    });
}




//     handleCustomYearChange(event) {
//     this.selectedCustomYear = event.detail.value;

//     if (this.selectedYearType === 'Custom') {
//         this.fromDate = `${this.selectedCustomYear}-01-01`;
//         this.toDate = `${this.selectedCustomYear}-12-31`;
//         this.handleSearchClick();
//     }
    // }
    
    handleCustomYearChange(event) {
    this.selectedCustomYear = event.detail.value;
    this.setCustomYearDates(this.selectedCustomYear);
    this.loadAllChartData();
}
setCustomYearDates(year) {
    this.fromDate = `${year}-01-01`;
    this.toDate = `${year}-12-31`;

    // For custom year, labels should be Jan–Dec
    this.fiscalLabels = this.generateCustomYearLabels(year);
}
generateCustomYearLabels(year) {
    const monthLabels = [];
    for (let i = 0; i < 12; i++) {
        const monthName = new Date(2000, i, 1).toLocaleString('default', { month: 'short' });
        monthLabels.push(`${monthName}${year}`);
    }
    return monthLabels;
}

    formatDate(dateObj) {
    const year = dateObj.getFullYear();
    const month = String(dateObj.getMonth() + 1).padStart(2, '0');
    const day = String(dateObj.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
    }
    

    generateAvailableYearOptions() {
    const currentYear = new Date().getFullYear();
    const options = [];

    for (let i = currentYear - 5; i <= currentYear + 5; i++) {
        options.push({ label: i.toString(), value: i.toString() });
    }

    this.customYearOptions = options;
}


    

    generateFiscalLabels(startMonth, year) {
    console.log('💕💕AZ in fiscal labels');

    let labels = [];

    for (let i = 0; i < 12; i++) {
        console.log('➰➰AZ in loop', i);

        const monthIndex = ((startMonth - 1 + i) % 12); // 0-based month
        const labelYear = year + Math.floor((startMonth - 1 + i) / 12);
        const monthName = new Date(2000, monthIndex, 1).toLocaleString('default', { month: 'short' });

        const label = `${monthName}${labelYear}`;
        labels.push(label);

        console.log('🔖🔖AZ label pushed:', label);
    }

    console.log('📦 Final labels array:', JSON.stringify(labels));
    return labels;
}  

    connectedCallback() {
        
        const currentYear = new Date().getFullYear().toString();
    if (!this.selectedCustomYear) {
        this.selectedCustomYear = currentYear;
    }

    if (this.hasRenderedCountryChart) return;
    this.siteFilter = "Company__c = '" + this.organisationId + "' AND Active__c = true";
    const canvas = this.template.querySelector('.breakdown-placeholder-chart');
    if (this.chartJsInitialized && this.isSupplierScorecard && !this.renderedOnce) {
        this.renderedOnce = true;
        console.log('fetch supplier before');
        this.fetchSupplierData();
        console.log('fetch after');
    } else {
        console.log('⏳ Waiting for canvas or data...');
    }

    loadScript(this, chartJs)
        .then(() => {
            console.log('✅ Chart.js loaded');
            this.chartJsReady = true;
            this.chartJsInitialized = true;
            this.showChart = true;


            // Get currency symbol
            getCurrencySymbol()
                .then(symbol => {
                    this.currencySymbol = symbol;
                    console.log(`💱 Currency Symbol: ${this.currencySymbol}`);
                })
                .catch(error => {
                    console.error('❌ Error fetching currency symbol:', error);
                    this.currencySymbol = '$'; // fallback
                });

            // ✅ Get fiscal start month and compute fromDate/toDate
            // ✅ Use existing method
            this.setFiscalDates()
                .then(() => {
                    console.log(`📅 Dates set: ${this.fromDate} → ${this.toDate}`);
                    this.loadAllChartData();
                })
                .catch(error => {
                    console.error('❌ Failed to set fiscal dates:', error);
                });

            // ✅ Only run vendor logic for supplier scorecard
            if (this.isSupplierScorecard) {
                console.log('📊 Fetching default vendor for Supplier Scorecard');
                            this.isLoading = true;
                getDefaultTopVendor({ organisationId: this.organisationId })
                    .then(vendor => {
                        if (vendor?.Id) {
                            this.selectedVendorId = vendor.Id;
                            this.selectedVendorName = vendor.Name;
                            console.log(`✅ Default vendor selected: ${vendor.Name}`);
                            this.fetchSupplierData();
                        } else {
                            console.warn('⚠️ No default vendor returned from Apex.');
                        }
                        // Generate year options for custom year picklist
                    this.generateAvailableYearOptions();
                    })
                    .catch(error => {
                        console.error('❌ Error fetching default vendor:', error);
                    })
                  .finally(() => {
                    this.isLoading = false;
                });
            }

            // ✅ Initialize supply forecast chart (can be safely done here)
            // this.initializeSupplyForecastChart();
            this.isLoading = true;
            getOrgFiscalStartMonth()
         .then((startMonth) => {
            const today = new Date();
            let fiscalYear = today.getFullYear();
            if (today.getMonth() + 1 < startMonth) {
                fiscalYear -= 1;
            }


                    this.selectedYearSup = fiscalYear; // 🟢 used in Apex calls
            this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);
            console.log('AZ ingenerateFiscalLabels',this.generateFiscalLabels(startMonth, fiscalYear));
            
            console.log('❌❌AZ Fiscal Labels',this.fiscalLabels);

            // Now call your chart function
            console.log('AZ calling initializeSupplyForecastChart from fiscal year');
            
            this.initializeSupplyForecastChart(
                this.fiscalLabels,
                this.supplyData,
                this.demandData,
                this.forecastedSupplyData,
                this.forecastedDemandData
            );
                this.generateAvailableYearOptions();

        })
        .catch((error) => {
            console.error('Error fetching fiscal start month:', error);
        });

            // ❌ Do NOT call other data loading methods here (they will be called from loadAllChartData)
        })
        .catch(error => {
            console.error('❌ ChartJS load error:', error);
        })
          .finally(() => {
                    this.isLoading = false;
                });



   }
    handleCreatePO() {
        console.log('create po');
        
    this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'c__CreatePurchaseOrder2'
        }
        // state: {
        //     c__recordId: this.selectedProduct?.Id
        // }
    });
    }

     // ---- helper getter for template visibility
    get hasManufacturingPriceData() {
        return Array.isArray(this.manufacturingPriceData) && this.manufacturingPriceData.length > 0;
    }

    
    async fetchPriceData() {
        if (!this.inventoryProduct?.Id || !this.fromDate || !this.toDate) return;

        try {
            // // Sales price
            // let salesData = await getMonthlySalesPriceStats({
            //     productId: this.inventoryProduct.Id,
            //     orgId: null,
            //     startDate: this.fromDate,
            //     endDate: this.toDate
            // });

            // this.salesPriceData = salesData.map(row => ({
            //     ...row,
            //     key: `${row.year}-${row.month}`,
            //     avgPrice: this.formatPrice(row.avgPrice),
            //     minPrice: this.formatPrice(row.minPrice),
            //     maxPrice: this.formatPrice(row.maxPrice)
            // }));


            // ---- SALES (UPDATED: totalSOCount + per-status lists) ----
            
    const salesData = await getMonthlySalesPriceStats({
      productId: this.inventoryProduct.Id,
      orgId: this.organisationId || null,
      startDate: this.fromDate,
      endDate: this.toDate
    });
console.log('📦 Apex getMonthlySalesPriceStats() raw response:', salesData);
console.log('🧾 Apex getMonthlySalesPriceStats() JSON string:', JSON.stringify(salesData, null, 2));
            

    const fmtAmount = (v) => this.formatPrice(v);
    const decorateSO = (list) => (list || []).map(s => ({
      ...s,
      subTotalFormatted: fmtAmount(s.subTotal),
      orderAmountFormatted: fmtAmount(s.orderAmount),
      accountName: s.accountName || s.accountId, // if Apex sends name use it; else id
      ExpectedDate: s.ExpectedDate,              // keep same shape for template
    }));

    this.salesPriceData = (salesData || []).map(row => ({
      ...row,
      key: `${row.year}-${row.month}`,
      avgPrice: this.formatPrice(row.avgPrice),
      minPrice: this.formatPrice(row.minPrice),
      maxPrice: this.formatPrice(row.maxPrice),
      totalSOCount: row.totalSOCount || 0,

      // Status detail lists (all defaulted + decorated)
      soDraftList:            decorateSO(row.soDraftList),
      soEnteredList:          decorateSO(row.soEnteredList),
      soActivatedList:        decorateSO(row.soActivatedList),
      soPickedUpList:         decorateSO(row.soPickedUpList),
      soPartiallyShippedList: decorateSO(row.soPartiallyShippedList),
      soShippedList:          decorateSO(row.soShippedList),
      soDeliveredList:        decorateSO(row.soDeliveredList),
      soCancelledList:        decorateSO(row.soCancelledList),
    }));

            // ---- Purchase price (UPDATED: add totalPOCount + per-status lists) ----
            


    const purchaseData = await getMonthlyPurchasePriceStats({
      productId: this.inventoryProduct.Id,
      orgId: this.organisationId, // or this.selectedOrgId || null
      startDate: this.fromDate,
      endDate: this.toDate
    });

    const decoratePO = (list) => (list || []).map(p => ({
      ...p,
      totalAmountFormatted: this.formatPrice(p.totalAmount),
      // If you later return org name from Apex, surface here:
      organisationName: p.organisationName || p.organisationId
    }));

    this.purchasePriceData = (purchaseData || []).map(row => ({
      ...row,
      key: `${row.year}-${row.month}`,
      avgPrice: this.formatPrice(row.avgPrice),
      minPrice: this.formatPrice(row.minPrice),
      maxPrice: this.formatPrice(row.maxPrice),
      totalPOCount: row.totalPOCount || 0,

      // status lists (default + decorate)
      poDraftList:                decoratePO(row.poDraftList),
      poLoggedList:               decoratePO(row.poLoggedList),
      poAssignedList:             decoratePO(row.poAssignedList),
      poApprovedList:             decoratePO(row.poApprovedList),
      poRejectedList:             decoratePO(row.poRejectedList),
      poInProgressList:           decoratePO(row.poInProgressList),
      poBookedList:               decoratePO(row.poBookedList),
      poClosedList:               decoratePO(row.poClosedList),
      poCancelledList:            decoratePO(row.poCancelledList),
      poSupplierAcceptedList:     decoratePO(row.poSupplierAcceptedList),
      poReconciledList:           decoratePO(row.poReconciledList),
      poSubmittedForApprovalList: decoratePO(row.poSubmittedForApprovalList),
      poOnHoldList:               decoratePO(row.poOnHoldList)
    }));            
            // Manufacturing Unit Cost
            const mfgData = await getMonthlyManufacturingUnitPriceStats({
                productId: this.inventoryProduct.Id,
                startDate: this.fromDate,
                endDate: this.toDate
            });

            // NOTE: keep the 5 lists from Apex AS-IS; just add convenience fields
            this.manufacturingPriceData = mfgData.map(row => ({
                ...row,
                key: `${row.year}-${row.month}`,
                avgPrice: this.formatPrice(row.avgPrice),
                minPrice: this.formatPrice(row.minPrice),
                maxPrice: this.formatPrice(row.maxPrice),
                avgDuration: row.avgDuration ? parseFloat(row.avgDuration).toFixed(1) : '0',
                avgDelay: row.avgDelay ? parseFloat(row.avgDelay).toFixed(1) : '0',
                totalCount: row.totalCount || 0,
                completedCount: row.completedCount || 0,
                inProgressCount: row.inProgressCount || 0,
                draftCount: row.draftCount || 0,
                cancelledCount: row.cancelledCount || 0,
                releaseCount: row.releaseCount || 0,
                // crucial: keep completeMOList, inProgressMOList, draftMOList, cancelledMOList, releaseMOList

                 // ✅ defensively default lists:
  completeMOList:   row.completeMOList   || [],
  inProgressMOList: row.inProgressMOList || [],
  draftMOList:      row.draftMOList      || [],
  cancelledMOList:  row.cancelledMOList  || [],
                releaseMOList: row.releaseMOList || [],
  

            }));
                    this._refreshSummaryPagers();

console.log('AZ manufacturing price',JSON.stringify(this.manufacturingPriceData));

        } catch (error) {
            console.error('Error fetching price data', error);
        }
    }

    formatPrice(value) {
        if (value === null || value === undefined) return '';
        let rounded = parseFloat(value).toFixed(2);
        return `${this.currencySymbol}${rounded}`;
    }


    // ===== Summary pagination (Manufacturing / Sales / Purchase) =====



// map a key -> the right array
_getSummaryData(key) {
  const map = {
    mfg: this.manufacturingPriceData || [],
    sales: this.salesPriceData || [],
    purchase: this.purchasePriceData || []
  };
  return map[key] || [];
}

_totalPagesSummary(key) {
  const len = this._getSummaryData(key).length;
  return len ? Math.ceil(len / this.pageSizeSummary) : 1;
}

_pagedSummary(key) {
  const data = this._getSummaryData(key);
  if (!data.length) return [];
  const page = this.currentPageSummary?.[key] || 1;
  const start = (page - 1) * this.pageSizeSummary;
  const end   = start + this.pageSizeSummary;
  return data.slice(start, end);
}

// single getter you can bind to in the template
get summaryPager() {
  const keys = ['mfg', 'sales', 'purchase'];
  const out = {};
  keys.forEach(k => {
    const total    = this._getSummaryData(k).length;
    const totalPg  = this._totalPagesSummary(k);
    const current  = this.currentPageSummary?.[k] || 1;
    const from     = total ? (current - 1) * this.pageSizeSummary + 1 : 0;
    const to       = Math.min(current * this.pageSizeSummary, total);

    out[k] = {
      paged: this._pagedSummary(k),
      total,
      currentPage: current,
      totalPages: totalPg,
      from,
      to,
      isFirst: current <= 1,
      isLast: current >= totalPg
    };
  });
  return out;
}

// immutable updates so LWC rerenders
handlePrevPageSummary = (event) => {
  const key = event.currentTarget.dataset.key; // 'mfg' | 'sales' | 'purchase'
  if (!key) return;
  const current = this.currentPageSummary?.[key] || 1;
  if (current <= 1) return;
  this.currentPageSummary = { ...this.currentPageSummary, [key]: current - 1 };
};

handleNextPageSummary = (event) => {
  const key = event.currentTarget.dataset.key;
  if (!key) return;
  const current = this.currentPageSummary?.[key] || 1;
  const totalPg = this._totalPagesSummary(key);
  if (current >= totalPg) return;
  this.currentPageSummary = { ...this.currentPageSummary, [key]: current + 1 };
};


//     sortByMo(event) {
//   this.showSpinner = true;

//     const statusKey = event.currentTarget.dataset.status;  // 'complete' | 'inProgress' | ...
//          if (statusKey) {
//     this.currentPageMoPrice = { ...this.currentPageMoPrice, [statusKey]: 1 };
//   }
//   const sortField = event.currentTarget.dataset.id;      // 'StartDate' | 'EndDate'

//   // map to wrapper fields
//   const fieldMap = { StartDate: 'startDate', EndDate: 'endDate' };
//   const moField = fieldMap[sortField];
//   if (!moField || !this.selectedRowMo) { this.showSpinner = false; return; }

//   // toggle ASC/DESC like your existing logic
//   const sortAsc = this.moOrderBy[statusKey] === sortField ? !(this.moOrder[statusKey] === 'ASC') : true;
//   this.moOrderBy[statusKey] = sortField;
//   this.moOrder[statusKey] = sortAsc ? 'ASC' : 'DESC';
//   // console.debug(`sortByMo: ${statusKey} by ${sortField} ${this.moOrder[statusKey]}`);

//   const listName = `${statusKey}MODetails`; // e.g., 'completeMODetails'
//   const source = this.selectedRowMo[listName] || [];
//   const table = [...source];

//   // sort like your product table (compute aValue/bValue, compare, flip for DESC)
//   table.sort((a, b) => {
//     const aRaw = a?.[moField];
//     const bRaw = b?.[moField];

//     // robust date parsing (supports string/Date/Datetime)
//     const aValue = aRaw ? new Date(aRaw).getTime() : 0;
//     const bValue = bRaw ? new Date(bRaw).getTime() : 0;

//     let result = 0;
//     if (aValue < bValue) result = -1;
//     else if (aValue > bValue) result = 1;

//     return sortAsc ? result : -result;
//   });

//   // assign back to trigger reactivity (don’t mutate original object in place)
//   this.selectedRowMo = {
//     ...this.selectedRowMo,
//     [listName]: table
//   };

//   // (optional) reset that section's pagination to page 1 if you’re paging per status
//   if (this.state?.[statusKey]) this.state[statusKey].page = 1;

//   this.showSpinner = false;
    //     }
    
    sortByMo(event) {
  this.showSpinner = true;

  const statusKey = event.currentTarget.dataset.status; // 'complete' | 'inProgress' | ...
  if (statusKey) {
    this.currentPageMoPrice = { ...this.currentPageMoPrice, [statusKey]: 1 };
  }

  const sortField = event.currentTarget.dataset.id;      // 'StartDate' | 'EndDate'
  const fieldMap = { StartDate: 'startDate', EndDate: 'endDate' };
  const moField = fieldMap[sortField];
  if (!moField || !this.selectedRowMo) { this.showSpinner = false; return; }

  // ensure sort state objects exist
  this.moOrderBy = { ...(this.moOrderBy || {}) };
  this.moOrder   = { ...(this.moOrder   || {}) };

  const sortAsc = this.moOrderBy[statusKey] === sortField ? !(this.moOrder[statusKey] === 'ASC') : true;
  this.moOrderBy[statusKey] = sortField;
  this.moOrder[statusKey]   = sortAsc ? 'ASC' : 'DESC';

  const listName = `${statusKey}MODetails`; // e.g., 'completeMODetails'
  const source = this.selectedRowMo[listName] || [];
  const table = [...source].sort((a, b) => {
    const aValue = a?.[moField] ? new Date(a[moField]).getTime() : 0;
    const bValue = b?.[moField] ? new Date(b[moField]).getTime() : 0;
    return sortAsc ? aValue - bValue : bValue - aValue;
  });

  this.selectedRowMo = { ...this.selectedRowMo, [listName]: table };

  // ❌ REMOVE this (was causing cross-talk)
  // if (this.state?.[statusKey]) this.state[statusKey].page = 1;

  this.showSpinner = false;
}

    

    // ===== Generic helpers =====
_getList(status) {
  // returns the correct list for a status key
  const map = {
    complete:   this.selectedRowMo?.completeMODetails   || [],
    inProgress: this.selectedRowMo?.inProgressMODetails || [],
    draft:      this.selectedRowMo?.draftMODetails      || [],
    cancelled:  this.selectedRowMo?.cancelledMODetails  || [],
    release:    this.selectedRowMo?.releaseMODetails    || []
  };
  return map[status] || [];
}

// If you want the same date-sorting to apply *before* pagination, plug your sorted lists here.
// If not sorting, just return _getList(status).
_sortedFor(status) {
  // Example: reuse your existing sort state (optional)
  const list = this._getList(status);
  const s = this.state?.[status];
  if (!s) return list;

  // map UI keys to fields
  const key = s.sortBy === 'end' ? 'endDate' : 'startDate';
  const dir = s.sortDir === 'asc' ? 1 : -1;

  return [...list].sort((a, b) => {
    const av = a?.[key] ? new Date(a[key]).getTime() : 0;
    const bv = b?.[key] ? new Date(b[key]).getTime() : 0;
    if (av === bv) return 0;
    return av > bv ? dir : -dir;
  });
}

// total pages like your example, but per status
_totalPages(status) {
  const data = this._sortedFor(status);
  const len = data.length;
  return len ? Math.ceil(len / this.pageSizeMoPrice) : 1;
}

// windowed slice like your example
_paged(status) {
  const data = this._sortedFor(status);
  if (!data.length) return [];
  const page = this.currentPageMoPrice[status] || 1;
  const start = (page - 1) * this.pageSizeMoPrice;
  const end = start + this.pageSizeMoPrice;
  return data.slice(start, end);
}

// ===== Completed getters (mirror your example) =====
get totalPagesComplete() { return this._totalPages('complete'); }
get isFirstPageComplete() { return (this.currentPageMoPrice.complete || 1) === 1; }
get isLastPageComplete()  { return (this.currentPageMoPrice.complete || 1) === this.totalPagesComplete; }
get completeFrom() {
  const total = this._sortedFor('complete').length;
  if (!total) return 0;
  return (this.currentPageMoPrice.complete - 1) * this.pageSizeMoPrice + 1;
}
get completeTo() {
  const total = this._sortedFor('complete').length;
  return Math.min(this.currentPageMoPrice.complete * this.pageSizeMoPrice, total);
}
get pagedComplete() { return this._paged('complete'); }

// ===== In Progress =====
get totalPagesInProgress() { return this._totalPages('inProgress'); }
get isFirstPageInProgress() { return (this.currentPageMoPrice.inProgress || 1) === 1; }
get isLastPageInProgress()  { return (this.currentPageMoPrice.inProgress || 1) === this.totalPagesInProgress; }
get inProgressFrom() {
  const total = this._sortedFor('inProgress').length;
  if (!total) return 0;
  return (this.currentPageMoPrice.inProgress - 1) * this.pageSizeMoPrice + 1;
}
get inProgressTo() {
  const total = this._sortedFor('inProgress').length;
  return Math.min(this.currentPageMoPrice.inProgress * this.pageSizeMoPrice, total);
}
get pagedInProgress() { return this._paged('inProgress'); }

// ===== Draft =====
get totalPagesDraft() { return this._totalPages('draft'); }
get isFirstPageDraft() { return (this.currentPageMoPrice.draft || 1) === 1; }
get isLastPageDraft()  { return (this.currentPageMoPrice.draft || 1) === this.totalPagesDraft; }
get draftFrom() {
  const total = this._sortedFor('draft').length;
  if (!total) return 0;
  return (this.currentPageMoPrice.draft - 1) * this.pageSizeMoPrice + 1;
}
get draftTo() {
  const total = this._sortedFor('draft').length;
  return Math.min(this.currentPageMoPrice.draft * this.pageSizeMoPrice, total);
}
get pagedDraft() { return this._paged('draft'); }

// ===== Cancelled =====
get totalPagesCancelled() { return this._totalPages('cancelled'); }
get isFirstPageCancelled() { return (this.currentPageMoPrice.cancelled || 1) === 1; }
get isLastPageCancelled()  { return (this.currentPageMoPrice.cancelled || 1) === this.totalPagesCancelled; }
get cancelledFrom() {
  const total = this._sortedFor('cancelled').length;
  if (!total) return 0;
  return (this.currentPageMoPrice.cancelled - 1) * this.pageSizeMoPrice + 1;
}
get cancelledTo() {
  const total = this._sortedFor('cancelled').length;
  return Math.min(this.currentPageMoPrice.cancelled * this.pageSizeMoPrice, total);
}
get pagedCancelled() { return this._paged('cancelled'); }

// ===== Release =====
get totalPagesRelease() { return this._totalPages('release'); }
get isFirstPageRelease() { return (this.currentPageMoPrice.release || 1) === 1; }
get isLastPageRelease()  { return (this.currentPageMoPrice.release || 1) === this.totalPagesRelease; }
get releaseFrom() {
  const total = this._sortedFor('release').length;
  if (!total) return 0;
  return (this.currentPageMoPrice.release - 1) * this.pageSizeMoPrice + 1;
}
get releaseTo() {
  const total = this._sortedFor('release').length;
  return Math.min(this.currentPageMoPrice.release * this.pageSizeMoPrice, total);
}
get pagedRelease() { return this._paged('release'); }

// ===== Prev/Next like your example, but per status =====
handlePrevPageMoPrice = (event) => {
  const status = event.currentTarget.dataset.status;
  if (!status) return;
  const p = this.currentPageMoPrice[status] || 1;
  if (p > 1) {
    this.currentPageMoPrice = { ...this.currentPageMoPrice, [status]: p - 1 };
  }
};

handleNextPageMoPrice = (event) => {
  const status = event.currentTarget.dataset.status;
  if (!status) return;
  const p = this.currentPageMoPrice[status] || 1;
  const total = this._totalPages(status);
  if (p < total) {
    this.currentPageMoPrice = { ...this.currentPageMoPrice, [status]: p + 1 };
  }
};


   handleTotalMOClick(event) {
  const key = event.currentTarget.dataset.key;
  this.selectedRowMo = this.manufacturingPriceData.find(r => r.key === key) || null;
  this.showMoDetails = !!this.selectedRowMo;
}

    // —— Click total in summary grid → show full page
handleTotalPOClick = (event) => {
  const key = event.currentTarget.dataset.key;
  const row = (this.purchasePriceData || []).find(r => r.key === key);
    if (!row) return;
    
     // reset current pages for a fresh view
  Object.keys(this.currentPagePoPrice).forEach(k => this.currentPagePoPrice[k] = 1);

  // defensive defaults to keep template safe
  this.selectedRowPo = {
    ...row,
    poDraftList:                row.poDraftList || [],
    poLoggedList:               row.poLoggedList || [],
    poAssignedList:             row.poAssignedList || [],
    poApprovedList:             row.poApprovedList || [],
    poRejectedList:             row.poRejectedList || [],
    poInProgressList:           row.poInProgressList || [],
    poBookedList:               row.poBookedList || [],
    poClosedList:               row.poClosedList || [],
    poCancelledList:            row.poCancelledList || [],
    poSupplierAcceptedList:     row.poSupplierAcceptedList || [],
    poReconciledList:           row.poReconciledList || [],
    poSubmittedForApprovalList: row.poSubmittedForApprovalList || [],
    poOnHoldList:               row.poOnHoldList || []
  };
  this.showPoDetails = true;

  // reset paging when opening
  this.currentPagePo = { ...this.currentPagePo,
    draft:1, logged:1, assigned:1, approved:1, rejected:1,
    inProgress:1, booked:1, closed:1, cancelled:1,
    supplierAccepted:1, reconciled:1, submittedForApproval:1, onHold:1
  };
};
    
    goBack = () => {
        this.showMoDetails = false;
        this.selectedRowMo = undefined;
         this.showPoDetails = false;
        this.selectedRowPo = undefined;
        this.showSoDetails = false;
        this.selectedRowSo = null;
    };

    // navigateToMO = (event) => {
    //     const recordId = event.currentTarget.dataset.id;
    //     if (!recordId) return;
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             recordId,
    //             objectApiName: 'Manufacturing_Order__c',
    //             actionName: 'view'
    //         }
    //     });
    // };

    navigateToMO = (event) => {
  const recordId = event.currentTarget.dataset.id;

        // 👇 defaults to Manufacturing Order; override via data-object on the link
        
  const objectApiName = event.currentTarget.dataset.object || 'Manufacturing_Order__c';
  // optional: allow data-action="edit" if you ever need it
  const actionName = event.currentTarget.dataset.action || 'view';

  this[NavigationMixin.Navigate]({
    type: 'standard__recordPage',
    attributes: { recordId, objectApiName, actionName }
  });
};


closeModal() {
    this.showMoDetails = false;
}


handleCreateMO() {
    this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'c__WorkCenterSchedule' 
        }
    });
}
handleStockTakeNav() {
    this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'c__StockTake'  
        }
    });
}
    

    //from here for the po price stats

    // —— Click total in summary grid → show full page
handleTotalPOClick = (event) => {
  const key = event.currentTarget.dataset.key;
  const row = (this.purchasePriceData || []).find(r => r.key === key);
    if (!row) return;
    
     // reset current pages for a fresh view
  Object.keys(this.currentPagePoPrice).forEach(k => this.currentPagePoPrice[k] = 1);

  // defensive defaults to keep template safe
  this.selectedRowPo = {
    ...row,
    poDraftList:                row.poDraftList || [],
    poLoggedList:               row.poLoggedList || [],
    poAssignedList:             row.poAssignedList || [],
    poApprovedList:             row.poApprovedList || [],
    poRejectedList:             row.poRejectedList || [],
    poInProgressList:           row.poInProgressList || [],
    poBookedList:               row.poBookedList || [],
    poClosedList:               row.poClosedList || [],
    poCancelledList:            row.poCancelledList || [],
    poSupplierAcceptedList:     row.poSupplierAcceptedList || [],
    poReconciledList:           row.poReconciledList || [],
    poSubmittedForApprovalList: row.poSubmittedForApprovalList || [],
    poOnHoldList:               row.poOnHoldList || []
  };
  this.showPoDetails = true;

  // reset paging when opening
  this.currentPagePo = { ...this.currentPagePo,
    draft:1, logged:1, assigned:1, approved:1, rejected:1,
    inProgress:1, booked:1, closed:1, cancelled:1,
    supplierAccepted:1, reconciled:1, submittedForApproval:1, onHold:1
  };
};
    
    // Map status key -> list from selectedRowPo
_getPoList(key) {
  if (!this.selectedRowPo) return [];
  const m = {
    draft: this.selectedRowPo.poDraftList || [],
    logged: this.selectedRowPo.poLoggedList || [],
    assigned: this.selectedRowPo.poAssignedList || [],
    approved: this.selectedRowPo.poApprovedList || [],
    rejected: this.selectedRowPo.poRejectedList || [],
    inprogress: this.selectedRowPo.poInProgressList || [],
    booked: this.selectedRowPo.poBookedList || [],
    closed: this.selectedRowPo.poClosedList || [],
    cancelled: this.selectedRowPo.poCancelledList || [],
    supplieraccepted: this.selectedRowPo.poSupplierAcceptedList || [],
    reconciled: this.selectedRowPo.poReconciledList || [],
    submittedforapproval: this.selectedRowPo.poSubmittedForApprovalList || [],
    onhold: this.selectedRowPo.poOnHoldList || []
  };
  return m[key] || [];
}

// sort by orderDate, ASC/DESC per poSortState
_sortedPo(status) {
  const list = this._getPoList(status);
  const st = this.poSortState?.[status] || { sortBy: 'orderDate', sortDir: 'asc' };
  const key = st.sortBy === 'orderDate' ? 'orderDate' : 'orderDate';
  const dir = st.sortDir === 'asc' ? 1 : -1;

  return [...list].sort((a, b) => {
    const av = a?.[key] ? new Date(a[key]).getTime() : 0;
    const bv = b?.[key] ? new Date(b[key]).getTime() : 0;
    if (av === bv) return 0;
    return av > bv ? dir : -dir;
  });
}

_totalPagesPo(status) {
  const len = this._sortedPo(status).length;
  return len ? Math.ceil(len / this.pageSizePoPrice) : 1;
}

_pagedPo(status) {
  const data = this._sortedPo(status);
  if (!data.length) return [];
  const page = this.currentPagePoPrice[status] || 1;
  const start = (page - 1) * this.pageSizePoPrice;
  const end = start + this.pageSizePoPrice;
  return data.slice(start, end);
}
    
    _buildPoSection(key, title) {
  const total = this._getPoList(key).length;
  const totalPages = total ? Math.ceil(total / this.pageSizePoPrice) : 1;
  const currentPage = this.currentPagePoPrice?.[key] || 1;
  const from = total ? (currentPage - 1) * this.pageSizePoPrice + 1 : 0;
  const to = total ? Math.min(currentPage * this.pageSizePoPrice, total) : 0;

  return {
    key,
    title,
    total,
    totalPages,
    currentPage,
    from,
    to,
    isFirst: currentPage === 1,
    isLast: currentPage === totalPages,
    paged: this._pagedPo(key) // ← sorted + paged rows
  };
    }

    get poSections() {
  if (!this.showPoDetails || !this.selectedRowPo) return [];
  return [
    this._buildPoSection('draft', 'Draft'),
    this._buildPoSection('logged', 'Logged'),
    this._buildPoSection('assigned', 'Assigned'),
    this._buildPoSection('approved', 'Approved'),
    this._buildPoSection('rejected', 'Rejected'),
    this._buildPoSection('inprogress', 'In Progress'),
    this._buildPoSection('booked', 'Booked'),
    this._buildPoSection('closed', 'Closed'),
    this._buildPoSection('cancelled', 'Cancelled'),
    this._buildPoSection('supplieraccepted', 'Supplier Accepted'),
    this._buildPoSection('reconciled', 'Reconciled'),
    this._buildPoSection('submittedforapproval', 'Submitted for Approval'),
    this._buildPoSection('onhold', 'On Hold')
  ];
}
    

// example getters for Draft (repeat pattern for others or generate in template)
// get totalPagesPoDraft() { return this._totalPagesPo('draft'); }
// get isFirstPagePoDraft() { return (this.currentPagePoPrice.draft || 1) === 1; }
// get isLastPagePoDraft()  { return (this.currentPagePoPrice.draft || 1) === this.totalPagesPoDraft; }
// get draftFrom() {
//   const total = this._sortedPo('draft').length;
//   if (!total) return 0;
//   return (this.currentPagePoPrice.draft - 1) * this.pageSizePoPrice + 1;
// }
// get draftTo() {
//   const total = this._sortedPo('draft').length;
//   return Math.min(this.currentPagePoPrice.draft * this.pageSizePoPrice, total);
// }
// get pagedPoDraft() { return this._pagedPo('draft'); }

    
    get poPager() {
  // Returns an object keyed by status:
  // poPager.draft = { totalPages, isFirst, isLast, from, to, paged, total, currentPage }
  const obj = {};
  for (const st of this.PO_STATUSES) {
    const total = this._sortedPo(st).length;
    const totalPages = total ? Math.ceil(total / this.pageSizePoPrice) : 1;
    const current = this.currentPagePoPrice[st] || 1;
    const from = total ? (current - 1) * this.pageSizePoPrice + 1 : 0;
    const to = Math.min(current * this.pageSizePoPrice, total);
    obj[st] = {
      total,
      totalPages,
      isFirst: current === 1,
      isLast: current === totalPages,
      from,
      to,
      currentPage: current,
      paged: this._pagedPo(st)
    };
  }
  return obj;
}

    
    
// Prev/Next (generic)
handlePrevPagePo = (event) => {
  const status = event.currentTarget.dataset.status; // e.g. 'draft'
  if (!status) return;

  const current = this.currentPagePoPrice?.[status] || 1;
  if (current <= 1) return;

  this.currentPagePoPrice = {
    ...this.currentPagePoPrice,
    [status]: current - 1
  };
};

handleNextPagePo = (event) => {
  const status = event.currentTarget.dataset.status;
  if (!status) return;

  const totalPages = this._totalPagesPo(status);
  const current = this.currentPagePoPrice?.[status] || 1;
  if (current >= totalPages) return;

  this.currentPagePoPrice = {
    ...this.currentPagePoPrice,
    [status]: current + 1
  };
};


// Sorting click on header (by Order Date)
sortByPo = (event) => {
  const status = (event.currentTarget.dataset.status || '').toLowerCase(); // e.g. 'draft'
  if (!status) return;

  const current = this.poSortState?.[status] || { sortBy: 'orderDate', sortDir: 'asc' };
  const next = { sortBy: 'orderDate', sortDir: current.sortDir === 'asc' ? 'desc' : 'asc' };

  // ✅ reassign whole objects for reactivity
  this.poSortState = { ...this.poSortState, [status]: next };
  this.currentPagePoPrice = { ...this.currentPagePoPrice, [status]: 1 };
};
    
    
    // from here for the sales price stats

    handleTotalSOClick = (e) => {
  const key = e.currentTarget?.dataset?.key;
  if (!key) return;
  // find the chosen month row
  const row = (this.salesPriceData || []).find(r => r.key === key);
  if (!row) return;
//   this.selectedRowSo = row;
this.selectedRowSo = {
    month: row.month,
    year: row.year,
    soDraftList:            (row.soDraftList            || []).map(so => this.decorateSO(so)),
    soEnteredList:          (row.soEnteredList          || []).map(so => this.decorateSO(so)),
    soActivatedList:        (row.soActivatedList        || []).map(so => this.decorateSO(so)),
    soPickedUpList:         (row.soPickedUpList         || []).map(so => this.decorateSO(so)),
    soPartiallyShippedList: (row.soPartiallyShippedList || []).map(so => this.decorateSO(so)),
    soShippedList:          (row.soShippedList          || []).map(so => this.decorateSO(so)),
    soDeliveredList:        (row.soDeliveredList        || []).map(so => this.decorateSO(so)),
    soCancelledList:        (row.soCancelledList        || []).map(so => this.decorateSO(so)),
  };

        // reset pages
  Object.keys(this.currentPageSo).forEach(k => this.currentPageSo[k] = 1);
  this.showSoDetails = true;
};

   sortBySo = (event) => {
  const status = (event.currentTarget.dataset.status || '').toLowerCase();
  const field  = event.currentTarget.dataset.id; // 'EffectiveDate'
  if (!status || !field) return;

  const prev = this.soSort?.[status];
  const nextDir = prev && prev.by === field && prev.dir === 'asc' ? 'desc' : 'asc';

  this.soSort = { ...this.soSort, [status]: { by: field, dir: nextDir } };
  // reset that status’ page to 1 so the user sees the first page of the new order
  this.currentPageSoPrice = { ...this.currentPageSoPrice, [status]: 1 };
};

    
    
    
    // helper: return raw list for a status key from selectedRowSo
_getSoList(statusKey) {
  if (!this.selectedRowSo) return [];
  const listName = this.SO_KEY_MAP[statusKey];
  return listName ? (this.selectedRowSo[listName] || []) : [];
}



    _sortedSo(statusKey) {
  const list = this._getSoList(statusKey);
  const s = this.soSort[statusKey];
  if (!s) return list;

  const { by, dir } = s;
  const mult = dir === 'asc' ? 1 : -1;

  return [...list].sort((a, b) => {
    let av = a?.[by], bv = b?.[by];

    if (by === 'EffectiveDate' || by === 'ExpectedDate') {
      const t1 = av ? new Date(av).getTime() : 0;
      const t2 = bv ? new Date(bv).getTime() : 0;
      if (t1 === t2) return 0;
      return t1 > t2 ? mult : -mult;
    }

    // string/number fallback
    if (av == null && bv == null) return 0;
    if (av == null) return -mult;
    if (bv == null) return mult;

    av = av.toString().toLowerCase();
    bv = bv.toString().toLowerCase();
    if (av === bv) return 0;
    return av > bv ? mult : -mult;
  });
}

_listNameForStatus(status) {
  switch (status) {
    case 'draft': return 'soDraftList';
    case 'entered': return 'soEnteredList';
    case 'activated': return 'soActivatedList';
    case 'pickedUp': return 'soPickedUpList';
    case 'partiallyShipped': return 'soPartiallyShippedList';
    case 'shipped': return 'soShippedList';
    case 'delivered': return 'soDeliveredList';
    case 'cancelled': return 'soCancelledList';
    default: return '';
  }
}


// helper: page slice
_pagedSo(statusKey) {
  const data = this._sortedSo(statusKey);
  if (!data.length) return [];
  const page = this.currentPageSo?.[statusKey] || 1;
  const start = (page - 1) * this.pageSizeSo;
  const end = start + this.pageSizeSo;
  return data.slice(start, end);
}

// build a single section model
_buildSoSection(key, title) {
  const total = this._getSoList(key).length;
  const totalPages = total ? Math.ceil(total / this.pageSizeSo) : 1;
  const currentPage = this.currentPageSo?.[key] || 1;
  const listLength = total > 0;
  const paged = this._pagedSo(key);

  const from = total ? (currentPage - 1) * this.pageSizeSo + 1 : 0;
  const to   = total ? Math.min(currentPage * this.pageSizeSo, total) : 0;

  return {
    key, title, count: total,
    listLength,
    paged,
    total,
    totalPages,
    currentPage,
    from,
    to,
    isFirst: currentPage === 1,
    isLast: currentPage === totalPages
  };
}

// exposed to template
get soSections() {
  if (!this.showSoDetails || !this.selectedRowSo) return [];
  return [
    this._buildSoSection('draft', 'Draft'),
    this._buildSoSection('entered', 'Entered'),
    this._buildSoSection('activated', 'Activated'),
    this._buildSoSection('pickedUp', 'Picked Up'),
    this._buildSoSection('partiallyShipped', 'Partially Shipped'),
    this._buildSoSection('shipped', 'Shipped'),
    this._buildSoSection('delivered', 'Delivered'),
    this._buildSoSection('cancelled', 'Cancelled')
  ];
}
decorateSO(so) {
  return {
    ...so, // keep Id, Name, OrderNumber, AccountName, EffectiveDate, ExpectedDate, SubTotal, OrderAmount, etc.
    effectiveDateFormatted: so.EffectiveDate ? new Date(so.EffectiveDate).toLocaleDateString() : '',
    expectedDateFormatted:  so.ExpectedDate  ? new Date(so.ExpectedDate).toLocaleDateString()  : '',
    subTotalFormatted:      this.formatPrice(so.SubTotal),
    orderAmountFormatted:   this.formatPrice(so.OrderAmount)
  };
}

    
// pager handlers
handlePrevPageSo = (event) => {
  const status = event.currentTarget.dataset.status;
  if (!status) return;
  const current = this.currentPageSo?.[status] || 1;
  if (current <= 1) return;
  this.currentPageSo = { ...this.currentPageSo, [status]: current - 1 };
};

handleNextPageSo = (event) => {
  const status = event.currentTarget.dataset.status;
  if (!status) return;
  const total = this._getSoList(status).length;
  const totalPages = total ? Math.ceil(total / this.pageSizeSo) : 1;
  const current = this.currentPageSo?.[status] || 1;
  if (current >= totalPages) return;
  this.currentPageSo = { ...this.currentPageSo, [status]: current + 1 };
};



    loadAllChartData() {
    this.fetchCountrySupplyDemand(this.fromDate, this.toDate);
    this.loadTopFive(this.fromDate, this.toDate);
    this.loadTop5CountrySupplyDemand(this.fromDate, this.toDate);

    if (!this.selectedProductId) {
        this.loadTop5Data(this.fromDate, this.toDate);
        this.initializeTop5CountryChart(this.fromDate, this.toDate);
        this.loadTopFive(this.fromDate, this.toDate);
        this.loadTop5CountrySupplyDemand(this.fromDate, this.toDate);


        

    } else {
        this.fetchData(this.fromDate, this.toDate);
    }

        this.initializeSupplyForecastChart();
        this.initializeTop5CountryChart();
        this.resolveSupplyOverviewData();    
        this.resolveCountrySupplyDemand();  
}



    // Tab CSS Classes
    get supplyOverviewTabClass() { return this.isSupplyOverview ? 'sub-tab-horizontal active' : 'sub-tab-horizontal'; }
    get supplierScorecardTabClass() { return this.isSupplierScorecard ? 'sub-tab-horizontal active' : 'sub-tab-horizontal'; }

    // New tab classes
    get inventoryLevelTabClass() { return this.isInventoryLevel ? 'sub-tab-horizontal active' : 'sub-tab-horizontal'; }
    get procurementPlanningTabClass() { return this.isProcurementPlanning ? 'sub-tab-horizontal active' : 'sub-tab-horizontal'; }



    
    resetTabs() {
        this.isSupplyOverview = false;
        this.isSupplierScorecard = false;
        this.isInventoryLevel = false;
        this.isProcurementPlanning = false;
        this.isSafety = false;
    }


    loadAvailableYears() {
        try {
            const currentYear = new Date().getFullYear();
            const numYearsToShow = 5;

            const years = [];
            for (let i = 0; i < numYearsToShow; i++) {
                years.push(currentYear - i);
            }

            this.availableYears = years;
            this.selectedYear = years[0];

            if (this.inventoryProduct?.Id && this.organisationId) {
                this.resolveSupplyOverviewData();
                this.resolveCountrySupplyDemand();
            }
        } catch (error) {
            console.error('❌ Error in loadAvailableYears():', error);
        }
    }

   handleSearchClick() {
    if (this.fromDate && this.toDate) {
        console.log(`🔍 Loading data from ${this.fromDate} to ${this.toDate}`);
        this.loadAllChartData(); // This method should handle all data/chart reloads
    } else {
        console.warn('⚠️ From or To Date is missing!');
    }
}

handleProductRemoved(event) {
            this.productId = null;
            this.productName = null;
            this.isProductSelected = false;
            this.showChart = false;
 
            // Optional: Clear existing chart
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
        }


   
    // Tab Selection Methods
    selectSupplyOverview() {
        this.showChart = true;
        this.productId = null;
        this.productName = null;
        this.resetTabs();
        console.log('in selectSupplyOverview');
        
        this.isSupplyOverview = true;
         this.isProductSelected = false;

        //  Reset year type and custom year
    this.selectedYearType = 'Fiscal';
    // this.showCustomYearSelector = false;
    // this.selectedCustomYear = null;
    // console.log('✅ Year type reset to Fiscal, custom year cleared');
        this.setFiscalDates();
        if (! this.inventoryProduct.Id) {
            console.log('calling load top 5');
            
            // ⬅️ If no product is selected, load both default charts
            this.loadTopFive(); // Top 5 Products
            this.loadTop5CountrySupplyDemand(); // Top 5 Countries
        }
        setTimeout(() => {
            this.initializeSupplyForecastChart();
             this.initializeBreakdownChart();
           this.initializeInventoryLevelChart();
        }, 100);

    }
    
//     selectSupplyOverview() {
//     console.log('🔹 selectSupplyOverview called');

//     this.productId = null;
//     this.productName = null;
//     this.inventoryProduct = { Id: null, Name: null };
//     this.resetTabs();
//     console.log('✅ Product selection and tabs reset');

//     // Reset year type and custom year
//     this.selectedYearType = 'Fiscal';
//     this.showCustomYearSelector = false;
//     this.selectedCustomYear = null;
//     console.log('✅ Year type reset to Fiscal, custom year cleared');

//     // Wait for fiscal dates to be set
//     this.setFiscalDates()
//         .then(() => {
//             console.log('📅 Fiscal dates set:', this.fromDate, '→', this.toDate);
//             return getOrgFiscalStartMonth();
//         })
//         .then((startMonth) => {
//             const today = new Date();
//             let fiscalYear = today.getFullYear();
//             if (today.getMonth() + 1 < startMonth) fiscalYear -= 1;

//             this.selectedYearSup = fiscalYear;
//             this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);
//             console.log('📆 Fiscal year & labels set:', this.selectedYearSup, this.fiscalLabels);

//             // Reset chart arrays
//             this.supplyData = new Array(12).fill(0);
//             this.demandData = new Array(12).fill(0);
//             this.forecastedSupplyData = new Array(12).fill(null);
//             this.forecastedDemandData = new Array(12).fill(null);
//             console.log('📊 Chart arrays reset');

//             // Load default charts if no product is selected
//             if (!this.inventoryProduct?.Id) {
//                 console.log('📊 Loading default Top 5 charts');
//                 this.loadTopFive();
//                 this.loadTop5CountrySupplyDemand();
//             }

//             // Initialize charts after data
//             console.log('📈 Initializing charts...');
//             this.initializeSupplyForecastChart();
//             this.initializeBreakdownChart();
//             this.initializeInventoryLevelChart();
//             console.log('✅ Charts initialized');
//         })
//         .catch((error) => {
//             console.error('❌ Error in selectSupplyOverview:', error);
//         });
// }





selectSupplierScorecard() {
    // Reset product selection
    this.showChart = true;
    this.productId = null;
    this.productName = null;
    this.inventoryProduct.Id = null;
    this.inventoryProduct.Name = null;

    this.resetTabs();
    this.isSupplierScorecard = true;

    // 🔄 Reset year type to Fiscal and clear custom year
    this.selectedSpendYearType = 'Fiscal';
    this.showSpendCustomYearSelector = false;
    this.selectedSpendCustomYear = null;

    // Get fiscal year and labels
    getOrgFiscalStartMonth()
        .then(startMonth => {
            const today = new Date();
            let fiscalYear = today.getFullYear();
            if (today.getMonth() + 1 < startMonth) {
                fiscalYear -= 1;
            }

            this.selectedYearSup = fiscalYear; // For Apex & chart
            this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);

            // Clear and redraw chart
            this.destroyChart('spendChart');
            this.renderSpendChart([]);

            // Fetch default vendor data
            return getDefaultTopVendor({ organisationId: this.organisationId, year: fiscalYear });
        })
        .then((vendor) => {
            if (vendor && vendor.Id) {
                this.selectedVendorId = vendor.Id;
                this.selectedVendorName = vendor.Name;
                console.log(`✅ Default vendor selected: ${vendor.Name}`);
                this.fetchSupplierData();
            } else {
                console.warn('⚠️ No default vendor returned for Supplier Scorecard');
            }
        })
        .catch((error) => {
            console.error('❌ Error fetching fiscal start month or default vendor:', error);
        });
}


    selectInventoryLevel() {
         this.inventoryProduct.Id = null;
        this.inventoryProduct.Name = null;
        this.resetTabs();
        this.isInventoryLevel = true;
                this.setFiscalDates();

        if (!this.productId) {
            this.isTop5View = true;
            this.isSingleProductView = false;
            this.top5ChartPending = true;
            this.loadTop5Data(); // Fetch and render Top 5 products chart
        }
        setTimeout(() => this.initializeInventoryLevelChart(), 100);

    }

    // selectProcurementPlanning() {
    //     this.resetTabs();
    //     this.isProcurementPlanning = true;
    //     setTimeout(() => this.initializeProcurementChart(), 100);
    // }


    // handleMOSelection(event) {
    //     const detail = event.detail;
    //     console.log('🧩 handleMOSelection: event.detail =', JSON.stringify(detail));

    //     this.selectedMOId = detail.Id;
    //     this.selectedMOName = detail.Name;


    //     console.log('🆔 selectedMOId:', this.selectedMOId);
    //     console.log('📝 selectedMOName:', this.selectedMOName);

    //     if (!this.selectedMOId) {
    //         console.error('❌ No Manufacturing Order ID received.');
    //         return;
    //     }

    //     getInventoryData({ manufacturingOrderId: this.selectedMOId })
    //         .then(result => {
    //             this.rawData = result.raw || [];
    //             this.wipData = result.wip || [];
    //             this.finishedData = result.finished || [];
    //             console.log('✅ Raw Data:', this.rawData);
    //             console.log('✅ WIP Data:', this.wipData);
    //             console.log('✅ finishedData:', this.finishedData);

    //         })
    //         .catch(error => {
    //             console.error('❌ Error fetching inventory data:', JSON.stringify(error));
    //         });
    // }




    // Reusable destroy function
    destroyChart(name) {
        if (this.chartInstances[name]) {
            this.chartInstances[name].destroy();
            this.chartInstances[name] = null;
        }
    }
    // Called when a product is selected from <c-custom-input-lookup-l-w-c>


    resolveSupplyOverviewData() {
        if (!this.inventoryProduct?.Id || !this.organisationId) {
            console.warn('Product or Organisation not selected.');
            return;
        }

            this.isLoading = true;
        //getMonthlyDemandSupply({
        getSupplyDemandForecastWithHistory({
            
            productId: this.inventoryProduct.Id,
            organisationId: this.organisationId,
            //selectedYear: this.selectedYear,
            fromDate: this.fromDate, // 'YYYY-MM-DD' from LWC
        toDate: this.toDate

        })
            .then(result => {
                console.log('📊 Supply Overview Data:', result);
                console.log('✅this is After removing the apex method❌');
                
              //  this.supplyDemandRaw = result;
                this.processMonthlyDataForChart(result); // ✅ replaces transformToChartData + render
                //this.issuppydemandloaded = true; 
            })
            .catch(error => {
                console.error('Error fetching Supply Overview data:', error);
                //this.showToast('Error', error.body?.message || 'Failed to fetch supply overview.', 'error');
            })
              .finally(() => {
                    this.isLoading = false;
                });
    }



    //for defaault 

    fetchCountrySupplyDemand() {
                    this.isLoading = true;
        getSupplyDemandByCountry({
            organisationId: this.organisationId,
            selectedYear: this.selectedYear,
            productId: this.inventoryProduct.Id,
           // productId: this.selectedProductId || null,
            fromDate: this.fromDate,
    toDate: this.toDate
        })
            .then(result => {
                this.countrySupplyDemandData = result;
                this.hasRenderedCountryChart = false; // allow chart to render after DOM update

                console.log('✅✅✅before calling renderCountryChart from fetchCountrySupplyDemand getSupplyDemandByCountry ');

                this.renderCountryChart();
            })
            .catch(error => {
                console.error('Error fetching country supply-demand:', error);
            })
            .finally(() => {
                    this.isLoading = false;
                });
    }

    //country forselected product
    resolveCountrySupplyDemand() {
        if (!this.inventoryProduct?.Id || !this.organisationId) {
            console.warn('Missing product or organisation.');
            return;
        }
        console.log('cal to apex by country');
        this.isLoading = true;
        getSupplyDemandByCountry({
            productId: this.inventoryProduct.Id,
            organisationId: this.organisationId,
            selectedYear: this.selectedYear,
            fromDate: this.fromDate, // 'YYYY-MM-DD' from LWC
    toDate: this.toDate
            // productId: this.selectedProductId || null


        })
            .then(result => {
                console.log('🌍 Supply/Demand by Country:', result);
                this.countrySupplyDemandData = result;
                console.log("👍👍countrychart");

                this.renderCountryChart(); // use the real chart rendering here
            })
            .catch(error => {
                console.error('Error fetching country data:', error);
                //this.showToast('Error', error.body?.message || 'Failed to fetch country-level data.', 'error');
            })
          .finally(() => {
                    this.isLoading = false;
                });
        console.log("out of err");

    }



    handleINVProductSelected(event) {
        console.log('in inv selected');

        /* The custom lookup fires:
           • event.detail   = { Id, Name }   when a product is chosen
           • event.detail   = {} OR null     when the lookup is cleared          */
        const selId = event.detail && event.detail.Id ? event.detail.Id : null;
        const selName = event.detail && event.detail.Name ? event.detail.Name : null;

        /* ── keep your existing model updates ── */
        this.inventoryProduct.Id = selId;
        this.inventoryProduct.Name = selName;

        /* Refresh the year dropdown (your existing helper) */
        this.loadAvailableYears();

        this.isProductSelected = !!selId;

    if (this.isProductSelected) {
        this.showChart = true;
        this.fetchPriceData();

    } else {
        // Clear data if lookup is cleared
        this.showChart = false;
        this.salesPriceData = [];
        this.purchasePriceData = [];
    }

        /* ───────────────────────────── 1) No product selected → show Top 5 ──────────────────────────── */
        if (!selId) {

            this.selectedProductId = null;
            this.selectedProductName = null;

            // If a line chart was showing, destroy it
            this.destroyChart && this.destroyChart('lineChart');

            return;
        }

        /* ───────────────────────────── 2) Same product re‑selected → do nothing ─────────────────────── */
        if (this.selId === this.selectedProductId) {
            return;
        }

        /* ───────────────────────────── 3) New product selected → drill‑down chart ───────────────────── */
        this.selectedProductId = selId;
        this.selectedProductName = selName;

    }


    fetchSupplyDemandALL() {
        console.log('inside the fetch all');
        this.resolveSupplyOverviewData();
        console.log('resolve supply overview');
        //  if (this.issuppydemandloaded ) {
        //     console.log('callig resolve by country');
        this.resolveCountrySupplyDemand();
        //     console.log('aftr calling resolve');
        // }  
    }

    //top 5 supply demand

    /* ───────────────────────────────── Top‑5 overview ───────────────────────── */
    loadTopFive() {
        console.log('in load top 5');

        if (!this.chartJsReady) return;
            this.isLoading = true;
        getTop5SupplyAndDemand({
            organisationId: this.organisationId,
            selectedYear: this.selectedYear,
            fromDate: this.fromDate, // 'YYYY-MM-DD' from LWC
    toDate: this.toDate
        })
            .then(rows => {
                this.topFiveRows = rows;

                // rows already carry rankingType
                console.log('rows =>', rows);

                console.log('before calling render top 5');
                this.processTopFiveChartData(rows);


                // ⬅️ DOM will be ready now
            })
            .catch(e => console.error('Apex error (Top‑5)', e))
          .finally(() => {
                    this.isLoading = false;
                });
    }

   

    processTopFiveChartData(data) {
        console.log('in processTopFiveChartData');

        const demandRows = data.filter(r => r.rankingType === 'Demand');
        const supplyRows = data.filter(r => r.rankingType === 'Supply');

        // Full product names
        const fullLabels = demandRows.map(r => r.productName);

        // Truncated for X-axis
        const labels = fullLabels.map(name =>
            name.length > 10 ? name.substring(0, 10) + '...' : name
        );

        const supplyByName = new Map(
            supplyRows.map(r => [r.productName, r.totalSupply])
        );

        const demandData = demandRows.map(r => r.totalDemand);
        const supplyData = fullLabels.map(name => supplyByName.get(name) || 0);

        this.initializeTopFiveChart(labels, supplyData, demandData, fullLabels);
    }


    initializeTopFiveChart(labels, supply, demand, fullLabels) {
        const canvas = this.template.querySelector('.main-chart');
        if (!canvas) {
            console.error('❌ Canvas for Top 5 chart not found in DOM');
            return;
        }

        const ctx = canvas.getContext('2d');
        this.destroyChart('topFiveChart');
        this.chartInstances.topFiveChart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels, // Truncated labels for x-axis
                datasets: [
                    {
                        label: 'Demand',
                        data: demand,
                        // backgroundColor: 'rgba(50, 144, 237, 0.7)'
                                                    backgroundColor: '#3290ED'

                        // borderColor: '#3290ED',
                        // borderWidth: 1
                    },
                    {
                        label: 'Supply',
                        data: supply,
                        // backgroundColor: 'rgba(157, 83, 242, 0.7)'
                                                    backgroundColor: '#9D53F2 '

                        // borderColor: '#9D53F2',
                        // borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                interaction: {
                    mode: 'nearest',       // ✅ Picks the nearest data point along x-axis
                    axis: 'x',
                    intersect: false       // ✅ Works even when hovering on x-axis label
                },
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: 'Top 5 Products by Demand & Supply'
                    },
                    tooltip: {
                        mode: 'index',      // ✅ Show both demand/supply for the same product
                        intersect: false,
                        callbacks: {
                            title: (tooltipItems) => {
                                const index = tooltipItems[0].dataIndex;
                                return fullLabels[index]; // ✅ Show full label in tooltip
                            }
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: {
                            maxRotation: 0,
                            minRotation: 0
                        },
                        title: {
                            display: true,
                            text: 'Product'
                        }
                    },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Units'
                        }
                    }
                }
            }
        });

        console.log('✅ Top 5 Chart initialized with truncated X labels + full hover tooltips');
    }


    //for default getTop5CountrySupplyDemand

    loadTop5CountrySupplyDemand() {
        console.log('🌍 Loading top 5 country-level supply/demand');

        if (!this.chartJsReady) return;
            this.isLoading = true;
        getTop5CountrySupplyDemand({
            organisationId: this.organisationId,
            selectedYear: this.selectedYear,
            fromDate: this.fromDate,
    toDate: this.toDate
        })
            .then(rows => {
                this.topCountryRows = rows;
                console.log('🌍 Country rows =>', rows);

                this.processTop5CountryChartData(rows);
            })
            .catch(e => {
                console.error('❌ Apex error (Top‑5 Country Supply/Demand)', e);
            })
          .finally(() => {
                    this.isLoading = false;
                });
    }

    processTop5CountryChartData(data) {
        const labels = data.map(r => r.country);
        const demandData = data.map(r => r.totalDemand);
        const supplyData = data.map(r => r.totalSupply);

        this.initializeTop5CountryChart(labels, supplyData, demandData);
    }

    initializeTop5CountryChart(labels, supply, demand) {
        const canvas = this.template.querySelector('.country-chart'); // Ensure correct selector
        if (!canvas) {
            console.error('❌ Canvas for Top 5 Country Chart not found');
            return;
        }

        const ctx = canvas.getContext('2d');
        this.destroyChart('topFiveCountryChart');
        this.chartInstances.topFiveCountryChart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [
                    {
                        label: 'Demand',
                        data: demand,
                        backgroundColor: '#3290ED',
                        borderColor: '#3290ED',
                        borderWidth: 1
                    },
                    {
                        label: 'Supply',
                        data: supply,
                       backgroundColor: '#9D53F2',
                        borderColor: '#9D53F2',
                        borderWidth: 1
                    }
                ]
            },
            options: {
                responsive: true,
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false // ✅ Enables tooltip on x-axis label and empty space
                },
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: 'Top 5 Countries by Demand & Supply'
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false // ✅ Tooltip appears even if not directly over a bar
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Units'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Country'
                        }
                    }
                }
            }
        });


        console.log('✅ Top 5 Country Chart initialized');
    }



    //renders the supply and demand
    //from to date
    
//     processMonthlyDataForChart(rawData) {
//     console.log('🔍 Raw input to processMonthlyDataForChart:', rawData);

//         // const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//         const monthLabels = this.fiscalLabels;
//     const supplyData = new Array(12).fill(0);
//     const demandData = new Array(12).fill(0);
//     const supplyForecast = new Array(12).fill(null);
//     const demandForecast = new Array(12).fill(null);

//     const currentMonthIndex = new Date().getMonth(); // 0-indexed
//     console.log('📆 AZ Current Month Index:', currentMonthIndex);

//     const unifiedData = [];

//     // Convert historical
//     if (rawData.historicalMonths && rawData.historicalMonths.length) {
//         rawData.historicalMonths.forEach((monthStr, index) => {
//             unifiedData.push({
//                 month: monthStr,
//                 totalSupply: rawData.historicalSupplyValues?.[index] ?? 0,
//                 totalDemand: rawData.historicalDemandValues?.[index] ?? 0
//             });
//         });
//     }

//     // Convert forecast
//     if (rawData.forecastMonths && rawData.forecastMonths.length) {
//         rawData.forecastMonths.forEach((monthStr, index) => {
//             unifiedData.push({
//                 month: monthStr,
//                 forecastedSupply: rawData.forecastSupplyValues?.[index] ?? null,
//                 forecastedDemand: rawData.forecastDemandValues?.[index] ?? null
//             });
//         });
//     }

//     // ✅ Convert fromDate & toDate from component (YYYY-MM-DD) to Date objects
//     const fromDate = new Date(this.fromDate + 'T00:00:00');
//     const toDate = new Date(this.toDate + 'T23:59:59');

//     // Fill chart arrays
//     unifiedData.forEach(item => {
//         // const [monthName, yearStr] = item.month.split(' ');
//         // const monthIndex = monthLabels.indexOf(monthName);

//         const [monthName, yearStr] = item.month.split(' ');
// const fullLabel = `${monthName}${yearStr}`;
// const monthIndex = monthLabels.indexOf(fullLabel);


//         if (monthIndex === -1) {
//             // console.warn(`⚠️ Unknown month: ${item.month}`);
//                 console.warn(`⚠️ Unknown month: ${item.month} (looking for label ${fullLabel})`);

//             return;
//         }

//         // 🔄 Construct full date for this month (first day of month)
//         const monthDate = new Date(`${yearStr}-${(monthIndex).toString().padStart(2, '0')}-01`);

//         // 🔍 Check if the month falls within the date range
//         if (monthDate < fromDate || monthDate > toDate) {
//             console.log(`⏭️ Skipping ${item.month} as it's outside range ${this.fromDate} to ${this.toDate}`);
//             return;
//         }

//         const index = monthIndex;

//         console.log(`➡️ Processing ${item.month} -> index ${index}`);
//         console.log(`   🟦 Actual Supply: ${item.totalSupply}, Actual Demand: ${item.totalDemand}`);
//         console.log(`   🟨 Forecasted Supply: ${item.forecastedSupply}, Forecasted Demand: ${item.forecastedDemand}`);

//         if (item.totalSupply != null || item.totalDemand != null) {
//             supplyData[index] = item.totalSupply || 0;
//             demandData[index] = item.totalDemand || 0;
//         }

//         if ((item.forecastedSupply != null || item.forecastedDemand != null) && index >= currentMonthIndex) {
//             supplyForecast[index] = item.forecastedSupply || 0;
//             demandForecast[index] = item.forecastedDemand || 0;
//             console.log(`   ✅ Added forecast to month index ${index}`);
//         }
//     });

//     console.log('✅ Final Supply Data:', supplyData);
//     console.log('✅ Final Demand Data:', demandData);
//     console.log('📈 Final Forecast Supply Data:', supplyForecast);
//         console.log('📈 Final Forecast Demand Data:', demandForecast);
//         // 🧠 Store forecasted supply/demand data for CSV export
// this.supplyDemandForecastData = [];
// const currentYear = new Date().getFullYear();

// unifiedData.forEach(item => {
//     const [monthName, yearStr] = item.month.split(' ');
//     const forecastYear = parseInt(yearStr, 10);
//     const monthIndex = monthLabels.indexOf(monthName);

//     if ((item.forecastedSupply != null || item.forecastedDemand != null) && forecastYear === currentYear && monthIndex >= currentMonthIndex) {
//         this.supplyDemandForecastData.push({
//             month: `${monthName} ${forecastYear}`,
//             forecastedSupply: item.forecastedSupply ?? 0,
//             forecastedDemand: item.forecastedDemand ?? 0
//         });
//     }
// });

// this.hasSupplyDemandForecast = this.supplyDemandForecastData.length > 0;


//     try {
//         this.initializeSupplyForecastChart(monthLabels, supplyData, demandData, supplyForecast, demandForecast);
//         console.log('✅ initializeSupplyForecastChart executed.');
//     } catch (err) {
//         console.error('❌ Error initializing chart:', err);
//     }

//     this.issuppydemandloaded = true;
//     console.log('✅ Chart loaded flag set: issuppydemandloaded = true');
//     }
    
    
    
    processMonthlyDataForChart(rawData) {
    console.log('🔍 Raw input to processMonthlyDataForChart:', rawData);

    const monthLabels = this.fiscalLabels; // Will be fiscal OR custom depending on selectedYearType
    const supplyData = new Array(12).fill(0);
    const demandData = new Array(12).fill(0);
    const supplyForecast = new Array(12).fill(null);
    const demandForecast = new Array(12).fill(null);

    const currentDate = new Date();
    const currentMonthIndex = currentDate.getMonth(); // 0-indexed
    console.log('📆 AZ Current Month Index:', currentMonthIndex);

    const unifiedData = [];

    // 🧠 Convert historical
    if (rawData.historicalMonths?.length) {
        rawData.historicalMonths.forEach((monthStr, index) => {
            unifiedData.push({
                month: monthStr,
                totalSupply: rawData.historicalSupplyValues?.[index] ?? 0,
                totalDemand: rawData.historicalDemandValues?.[index] ?? 0
            });
        });
    }

    // 📈 Convert forecast
    if (rawData.forecastMonths?.length) {
        rawData.forecastMonths.forEach((monthStr, index) => {
            unifiedData.push({
                month: monthStr,
                forecastedSupply: rawData.forecastSupplyValues?.[index] ?? null,
                forecastedDemand: rawData.forecastDemandValues?.[index] ?? null
            });
        });
    }

    // 🗓 Convert fromDate & toDate to actual Date objects
    const fromDate = new Date(this.fromDate + 'T00:00:00');
    let toDate = new Date(this.toDate + 'T23:59:59');

    // 🧠 Adjustment: If yearType is "Fiscal" and fiscal end is in next year (e.g., Apr–Mar)
    if (this.selectedYearType === 'Fiscal') {
        const fiscalEndMonth = (this.fiscalLabels[11] || '').substring(0, 3); // Last month abbreviation
        const fiscalEndYear = parseInt(this.fiscalLabels[11].substring(3), 10);

        const monthIndex = new Date(`${fiscalEndMonth} 01, ${fiscalEndYear}`).getMonth();
        toDate = new Date(fiscalEndYear, monthIndex + 1, 0, 23, 59, 59); // Last day of that month
        console.log(`📅 Adjusted fiscal toDate: ${toDate.toISOString().split('T')[0]}`);
    }

    unifiedData.forEach(item => {
        const [monthName, yearStr] = item.month.split(' ');
        const fullLabel = `${monthName}${yearStr}`;
        const monthIndex = monthLabels.indexOf(fullLabel);

        if (monthIndex === -1) {
            console.warn(`⚠️ Unknown month: ${item.month} (looking for label ${fullLabel})`);
            return;
        }

        const monthDate = new Date(`${monthName} 1, ${yearStr}`);

        // ⛔ Skip months outside selected range
        if (monthDate < fromDate || monthDate > toDate) {
            console.log(`⏭️ Skipping ${item.month} (outside ${this.fromDate} - ${this.toDate})`);
            return;
        }

        const index = monthIndex;
        console.log(`➡️ Processing ${item.month} -> index ${index}`);
        console.log(`   🟦 Actual Supply: ${item.totalSupply}, Actual Demand: ${item.totalDemand}`);
        console.log(`   🟨 Forecasted Supply: ${item.forecastedSupply}, Forecasted Demand: ${item.forecastedDemand}`);

        // Populate historical
        if (item.totalSupply != null || item.totalDemand != null) {
            supplyData[index] = item.totalSupply || 0;
            demandData[index] = item.totalDemand || 0;
        }

        // Populate forecasted (only for future months)
        const isFutureMonth = monthDate >= currentDate;
        if ((item.forecastedSupply != null || item.forecastedDemand != null) && isFutureMonth) {
            supplyForecast[index] = item.forecastedSupply || 0;
            demandForecast[index] = item.forecastedDemand || 0;
            console.log(`   ✅ Forecast added for ${item.month}`);
        }
    });

    // 📦 Save forecast for CSV export
    this.supplyDemandForecastData = [];
    const currentYear = new Date().getFullYear();
    unifiedData.forEach(item => {
        const [monthName, yearStr] = item.month.split(' ');
        const forecastYear = parseInt(yearStr, 10);
        const label = `${monthName}${yearStr}`;
        const index = monthLabels.indexOf(label);

        if ((item.forecastedSupply != null || item.forecastedDemand != null)
            && index !== -1
            && new Date(`${monthName} 1, ${yearStr}`) >= currentDate) {
            this.supplyDemandForecastData.push({
                month: `${monthName} ${forecastYear}`,
                forecastedSupply: item.forecastedSupply ?? 0,
                forecastedDemand: item.forecastedDemand ?? 0
            });
        }
    });

    this.hasSupplyDemandForecast = this.supplyDemandForecastData.length > 0;

    // 🟢 Initialize chart
    try {
        this.initializeSupplyForecastChart(monthLabels, supplyData, demandData, supplyForecast, demandForecast);
        console.log('✅ initializeSupplyForecastChart executed.');
    } catch (err) {
        console.error('❌ Error initializing chart:', err);
    }

    this.issuppydemandloaded = true;
    console.log('✅ Chart loaded flag set: issuppydemandloaded = true');
}

//     downloadSupplyDemandForecastAsCSV() {
//     console.log('⬇️ Starting Supply/Demand Forecast CSV download...');
//     if (!this.hasSupplyDemandForecast || !Array.isArray(this.supplyDemandForecastData)) {
//         this.showToast('No Forecast', 'No forecasted supply/demand data to download.', 'warning');
//         return;
//     }

//     const today = new Date();
//     const currentMonthIndex = today.getMonth();
//     const currentYear = today.getFullYear();

//     let csv = 'Month,Forecasted Supply,Forecasted Demand\n';

//     this.supplyDemandForecastData.forEach(entry => {
//         if (!entry.month) return;

//         const [monthStr, yearStr] = entry.month.split(' ');
//         const forecastYear = parseInt(yearStr, 10);
//         const forecastMonthIndex = new Date(`${monthStr} 1, ${forecastYear}`).getMonth();

//         if (forecastYear === currentYear && forecastMonthIndex >= currentMonthIndex) {
//             csv += `${entry.month},${entry.forecastedSupply},${entry.forecastedDemand}\n`;
//         }
//     });

//     console.log('📄 Final Supply/Demand Forecast CSV:\n' + csv);

//     const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
//     const link = document.createElement('a');
//     link.setAttribute('href', encodedUri);
//     const fileName = this.customFileName?.trim() || 'SupplyDemandForecast';
//     link.setAttribute('download', `${fileName}.csv`);
//     document.body.appendChild(link);
//     setTimeout(() => {
//         link.click();
//         document.body.removeChild(link);
//         console.log('✅ Supply/Demand Forecast Download triggered');
//     }, 50);
// }

downloadSupplyDemandForecastAsCSV() {
    console.log('⬇️ Starting Supply/Demand Forecast CSV download...');

    if (!this.hasSupplyDemandForecast || !Array.isArray(this.supplyDemandForecastData)) {
        this.showToast('No Forecast', 'No forecasted supply/demand data to download.', 'warning');
        return;
    }

    let csv = 'Month,Forecasted Supply,Forecasted Demand\n';

    const labelsToInclude = this.fiscalLabels; // works for both Fiscal and Custom years
    const allowedMonthsSet = new Set(labelsToInclude);

    this.supplyDemandForecastData.forEach(entry => {
        if (!entry.month) return;

        const [monthStr, yearStr] = entry.month.split(' ');
        const fullLabel = `${monthStr}${yearStr}`;

        if (allowedMonthsSet.has(fullLabel)) {
            csv += `${entry.month},${entry.forecastedSupply},${entry.forecastedDemand}\n`;
        }
    });

    if (csv === 'Month,Forecasted Supply,Forecasted Demand\n') {
        this.showToast('No Forecast', 'No matching forecast data for the selected year.', 'warning');
        return;
    }

    console.log('📄 Final Supply/Demand Forecast CSV:\n' + csv);

    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);

    const fileNameBase = this.customFileName?.trim() || 'SupplyDemandForecast';
    const yearLabel = this.selectedYearType === 'Fiscal' ? 'Fiscal' : `Custom_${this.selectedCustomYear}`;
    const finalFileName = `${fileNameBase}_${yearLabel}`;

    link.setAttribute('download', `${finalFileName}.csv`);
    document.body.appendChild(link);
    setTimeout(() => {
        link.click();
        document.body.removeChild(link);
        console.log('✅ Supply/Demand Forecast Download triggered');
    }, 50);
}

    // initializeSupplyForecastChart(labels, supply, demand) {
    //     // const canvas = this.template.querySelector('.main-chart');
    //     const canvas = this.template.querySelector('.supply-forecast-chart');
    //     if (!canvas) return;

    //     const ctx = canvas.getContext('2d');
    //     this.destroyChart('supplyForecastChart');

    //     this.chartInstances.supplyForecastChart = new window.Chart(ctx, {
    //         type: 'line',
    //         data: {
    //             labels: labels,
    //             datasets: [
    //                 {
    //                     label: 'Supply',
    //                     data: supply,
    //                     borderColor: '#9D53F2',
    //                     backgroundColor: 'rgba(157, 83, 242, 0.1)',
    //                     fill: true,
    //                     tension: 0.4,
    //                     borderWidth: 2
    //                 },
    //                 {
    //                     label: 'Demand',
    //                     data: demand,
    //                     borderColor: '#3290ED',
    //                     backgroundColor: 'rgba(50, 144, 237, 0.1)',
    //                     fill: true,
    //                     tension: 0.4,
    //                     borderWidth: 2
    //                 }
    //             ]
    //         },
    //         options: {
    //             responsive: true,
    //             interaction: {
    //                 mode: 'nearest',
    //                 axis: 'x',
    //                 intersect: false // ✅ enables tooltip on x-axis label and empty space
    //             },
    //             plugins: {
    //                 legend: { position: 'top' },
    //                 title: {
    //                     display: true,
    //                     text: 'Monthly Supply vs Demand'
    //                 },
    //                 tooltip: {
    //                     mode: 'index',
    //                     intersect: false // ✅ show both supply & demand on label hover
    //                 }
    //             },
    //             scales: {
    //                 y: {
    //                     beginAtZero: true,
    //                     title: {
    //                         display: true,
    //                         text: 'Units'
    //                     }
    //                 },
    //                 x: {
    //                     title: {
    //                         display: true,
    //                         text: 'Month'
    //                     }
    //                 }
    //             }
    //         }
    //     });
    // }

    // destroyChart(chartKey) {
    //     if (this.chartInstances[chartKey]) {
    //         this.chartInstances[chartKey].destroy();
    //         delete this.chartInstances[chartKey];
    //     }
    // }
initializeSupplyForecastChart(fiscalLabels, supply, demand, forecastedSupply, forecastedDemand) {
    console.log('📦 AZ labels received inside initialize:', JSON.stringify(fiscalLabels));

      if (!Array.isArray(fiscalLabels)) {
        console.error('❌ fiscalLabels is not an array:', fiscalLabels);
        return; // 🚫 Stop here if labels are invalid
    }


    // ✅ Clone fiscalLabels to a new clean array to avoid Proxy issues
    const monthLabels = [...fiscalLabels];
    console.log('✅ Final Month Labels used in chart:', JSON.stringify(monthLabels));

    console.log('💀 AZ Calling Chart.js from fiscal year method');

    const canvas = this.template.querySelector('.supply-forecast-chart');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    this.destroyChart('supplyForecastChart');

    this.chartInstances.supplyForecastChart = new window.Chart(ctx, {
        type: 'line',
        data: {
            labels: monthLabels, // ✅ Use clean month labels here
            datasets: [
                {
                    label: 'Supply',
                    data: [...supply],
                    borderColor: '#9D53F2',
                    backgroundColor: 'rgba(157, 83, 242, 0.1)',
                    fill: false,
                    tension: 0.3,
                    borderWidth: 2
                },
                {
                    label: 'Demand',
                    data: [...demand],
                    borderColor: '#3290ED',
                    backgroundColor: 'rgba(50, 144, 237, 0.1)',
                    fill: false,
                    tension: 0.4,
                    borderWidth: 2
                },
                {
                    label: 'Forecasted Supply',
                    data: [...forecastedSupply],
                    borderDash: [5, 5],
                    borderColor: '#9D53F2',
                    backgroundColor: 'rgba(157, 83, 242, 0.05)',
                    fill: false,
                    tension: 0.4,
                    borderWidth: 2
                },
                {
                    label: 'Forecasted Demand',
                    data: [...forecastedDemand],
                    borderDash: [5, 5],
                    borderColor: '#3290ED',
                    backgroundColor: 'rgba(50, 144, 237, 0.05)',
                    fill: false,
                    tension: 0.4,
                    borderWidth: 2
                }
            ]
        },
        options: {
            responsive: true,
            interaction: {
                mode: 'nearest',
                axis: 'x',
                intersect: false
            },
            plugins: {
                legend: { position: 'top' },
                title: {
                    display: true,
                    text: 'Monthly Supply vs Demand (Actual + Forecast)'
                },
                tooltip: {
                    mode: 'index',
                    intersect: false
                }
            },
            scales: {
                x: {
                    type: 'category', // ✅ Ensures it uses string labels like 'Apr2025'
                    title: {
                        display: true,
                        text: 'Month'
                    }
                },
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Units'
                    }
                }
            }
        }
    });
}



    //supplier score card

    loadChartJs() {
        if (this.chartJsInitialized) return;

        loadScript(this, chartJs)
            .then(() => {
                this.chartJsInitialized = true;
                console.log('ChartJS loaded');
            })
            .catch((error) => {
                console.error('Error loading ChartJS', error);
            });
    }

    generateYearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear; i >= currentYear - 5; i--) {
            years.push({ label: i.toString(), value: i });
        }
        return years;
    }

    // handleYearChangeSup(event) {
    //     // this.selectedYearSup = parseInt(event.detail.value, 10);
    //     this.fetchSupplierData();
    // }

    handleVendorSelect(event) {
        const vendor = event.detail;
        // if (vendor == null) {
        //     this.destroyChart('spendChart');
        //     this.destroyChart('countryBreakdownChart');
        //     this.destroyChart('onTimeDeliveryChart');

        // }
        this.selectedVendorId = vendor.Id;
        this.selectedVendorName = vendor.Name;
        this.fetchSupplierData();
    }

    handleVendorRemoved() {
    console.log('Vendor lookup cleared');

    // Clear selected vendor details
    this.selectedVendorId = null;
    this.selectedVendorName = null;

    // Reset all vendor-related data
    this.salesPriceData = [];
    this.purchasePriceData = [];
    this.isProductSelected = false;

    // Hide chart and show the illustration instead
    this.showChart = false;

    // Optionally, destroy any existing chart instance
   if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
}

 
    fetchSupplierData() {
        console.log("📥 In fetchSupplierData");

        const filtersMissing = !this.selectedVendorId || !this.selectedYearSup || !this.organisationId;

        // If filters are missing, render empty charts with axis only
        if (filtersMissing) {
            console.warn('⚠️ Missing filters: rendering empty chart');
            this.renderOnTimeDeliveryChart([]);
            this.renderSpendChart([]);
            this.renderQualityChart([]);

            return;
        }

        // ✅ All filters present → fetch real data
        // getSpendOverTime({
                    this.isLoading = true;
        getSpendOverTimeWithForecast({
            vendorId: this.selectedVendorId,
            organisationId: this.organisationId,
            year: this.selectedYearSup
        })
            .then((spendData) => {
                console.log('📊 Spend Over Time:', spendData);
                this.renderSpendChart(spendData);
            })
            .catch(error => {
                console.error('❌ Error fetching spend over time', error);
                this.renderSpendChart([]); // Fallback
            });
            this.isLoading = true;
        getOnTimeDeliveryMapped({
            vendorId: this.selectedVendorId,
            organisationId: this.organisationId,
            year: this.selectedYearSup
        })
            .then((deliveryData) => {
                console.log('🚚 On-Time Delivery Data:', deliveryData);
                this.deliveryData = deliveryData;
                this.renderOnTimeDeliveryChart(this.deliveryData);
            })
            .catch((error) => {
                console.error('❌ Error fetching On-Time Delivery data:', error);
                this.renderOnTimeDeliveryChart([]); // Fallback
            })
          .finally(() => {
                    this.isLoading = false;
                });
            this.isLoading = true;
        getMonthlyQualityData({
            vendorId: this.selectedVendorId,
            // vendorContactId: this.selectedVendorContactId,
            organisationId: this.organisationId,
            year: this.selectedYearSup
        })

            .then((qualitydata) => {
                console.log('🚚 Quality Data ab:', qualitydata);
                this.qualitydata = qualitydata;
                console.log("Before renderQualityChart");

                setTimeout(() => {
                    this.renderQualityChart(this.qualitydata);
                }, 0);
                console.log("After renderQualityChart");

            })
            .catch(error => {
                console.error(' ❌ Error fetching quality data', error);
            })
  .finally(() => {
                    this.isLoading = false;
                });
        
    }

    destroyChart(chartKey) {
        if (this.chartInstances[chartKey]) {
            this.chartInstances[chartKey].destroy();
            this.chartInstances[chartKey] = null;
        }
    }



    renderCountryChart() {

        // if (!this.countrySupplyDemandData || this.countrySupplyDemandData.length === 0) {
        //     console.warn('⚠️ No country supply/demand data available');
        //     return;
        // }

        // console.log('this.countrySupplyDemandData=>',this.countrySupplyDemandData);


        console.log('in renderCountryChart');

        console.log("in render country xhart");

        const canvas = this.template.querySelector('.breakdown-placeholder-chart');
        if (!canvas) {
            console.log('✅ ');

            console.warn('❌ No canvas found for country chart');
            return;
        }

        const countries = this.countrySupplyDemandData.map(item => item.country);
        const demand = this.countrySupplyDemandData.map(item => item.totalDemand);
        const supply = this.countrySupplyDemandData.map(item => item.totalSupply);

        console.log("country", countries);
        console.log("demand", demand);
        console.log("supply", supply);

        // const canvas = this.template.querySelector('.breakdown-placeholder-chart');
        console.log('✅ Canvas element found:', canvas);

        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        this.destroyChart('countryBreakdownChart'); // clear previous

        console.log('rendering bar chart');

        this.chartInstances.countryBreakdownChart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: countries,
                datasets: [
                    {
                        label: 'Demand',
                        data: demand,
                        backgroundColor: '#3290ED',
                        borderColor: '#3290ED',
                        borderWidth: 1, // reduced thickness

                    },
                    {
                        label: 'Supply',
                        data: supply,
                        backgroundColor: '#9D53F2',
                        borderColor: '#9D53F2',
                        borderWidth: 1 // reduced thickness
                    }
                ]
            },
            options: {
                responsive: true,
                 interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false // ✅ enables tooltip on x-axis label and empty space
                },

                plugins: {
                                        legend: { position: 'top' },

                    title: {
                        display: true,
                        text: 'Supply vs Demand by Country'
                    },
                     tooltip: {
                        mode: 'index',
                        intersect: false // ✅ show both supply & demand on label hover
                    }
                },

                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Units'
                        }
                    }
                }
            }
        });
    }


    // supplier score card fiscal year handle

//     get yearTypeOptions() {
//     return [
//         { label: 'Fiscal', value: 'Fiscal' },
//         { label: 'Custom', value: 'Custom' }
//     ];
// }

// get availableYearOptions() {
//     const years = [];
//     const currentYear = new Date().getFullYear();
//     for (let i = currentYear - 5; i <= currentYear + 5; i++) {
//         years.push({ label: i.toString(), value: i.toString() });
//     }
//     return years;
// }

    
//     handleSpendYearTypeChange(event) {
//     this.selectedSpendYearType = event.detail.value;

//     if (this.selectedSpendYearType === 'Fiscal') {
//         this.showSpendCustomYearSelector = false;

//         getOrgFiscalStartMonth()
//             .then(startMonth => {
//                 const today = new Date();
//                 let fiscalYear = today.getFullYear();
//                 if (today.getMonth() + 1 < startMonth) {
//                     fiscalYear -= 1;
//                 }
//                                 this.selectedYearSup = fiscalYear; // ✅ RESET to fiscal year for Apex

//                 this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);
//                 this.loadSpendChartDataUsingFiscal();
//             })
//             .catch(error => {
//                 console.error('❌ Error fetching fiscal start month:', error);
//             });

//     } else if (this.selectedSpendYearType === 'Custom') {
//         this.showSpendCustomYearSelector = true;
//         // this.loadSpendChartDataUsingCustomYear();
        
//     // 🔒 Safely set the custom year
//     const yearToUse = this.selectedSpendCustomYear || new Date().getFullYear().toString();
//     this.selectedYearSup = parseInt(yearToUse, 10);

//     // 🔁 Re-render with empty chart
//     this.destroyChart('spendChart');
//     this.renderSpendChart([]);

//     // 🔃 Fetch actual data
//     this.fetchSupplierData();
//     }
    // }
    
    handleSpendYearTypeChange(event) {
    this.selectedSpendYearType = event.detail.value;

    if (this.selectedSpendYearType === 'Fiscal') {
        this.showSpendCustomYearSelector = false;

        getOrgFiscalStartMonth()
            .then(startMonth => {
                const today = new Date();
                let fiscalYear = today.getFullYear();
                if (today.getMonth() + 1 < startMonth) {
                    fiscalYear -= 1;
                }

                this.selectedYearSup = fiscalYear; // ✅ RESET to fiscal year for Apex

                // Generate fiscal labels
                this.fiscalLabels = this.generateFiscalLabels(startMonth, fiscalYear);

                // Clear old chart and re-fetch correct data
                this.destroyChart('spendChart');
                this.renderSpendChart([]);

                // Fetch correct fiscal data
                this.fetchSupplierData();
            })
            .catch(error => {
                console.error('❌ Error fetching fiscal start month:', error);
            });

    } else if (this.selectedSpendYearType === 'Custom') {
        this.showSpendCustomYearSelector = true;

        // const yearToUse = this.selectedSpendCustomYear || new Date().getFullYear().toString();
          // ✅ Default current year if not already selected
        const currentYear = new Date().getFullYear().toString();
        this.selectedSpendCustomYear = this.selectedSpendCustomYear || currentYear;
        // this.selectedYearSup = parseInt(yearToUse, 10); // ✅ Use selected year
        this.selectedYearSup = parseInt(this.selectedSpendCustomYear, 10);

        this.destroyChart('spendChart');
        this.renderSpendChart([]);

        this.fetchSupplierData();
    }
}


handleSpendCustomYearChange(event) {
    this.selectedSpendCustomYear = event.detail.value;
    this.selectedYearSup = parseInt(this.selectedSpendCustomYear, 10);

    this.destroyChart('spendChart');
    this.renderSpendChart([]);
    this.fetchSupplierData();
}

    
    loadSpendChartDataUsingFiscal() {
    getSpendData({ 
        organisationId: this.organisationId, 
        monthLabels: this.fiscalLabels 
    })
        .then(data => {
            this.renderSpendChart(data);
        })
        .catch(error => {
            console.error('❌ Error loading fiscal spend data:', error);
        });
}

loadSpendChartDataUsingCustomYear() {
    const year = this.selectedSpendCustomYear;
    this.fiscalLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].map(m => `${m}${year}`);

    getSpendData({
        organisationId: this.organisationId,
        monthLabels: this.fiscalLabels
    })
        .then(data => {
            this.renderSpendChart(data);
        })
        .catch(error => {
            console.error('❌ Error loading custom spend data:', error);
        });
}


    
    renderSpendChart(data) {
    // if (!Array.isArray(data) || data.length === 0) {
    //     this.showToast('No Data', 'No spend data to display.', 'warning');
    //     return;
    // }

    //         const isEmpty = !Array.isArray(data) || data.length === 0;

    // if (isEmpty) {
    //     // 🔒 Only show warning if filters are selected and data is expected
    //     if (this.selectedVendorId && this.selectedYearSup && this.organisationId) {
    //         this.showToast('No Data', 'AZ No spend data to display.', 'warning');
    //     }

    //     this.destroyChart('spendChart'); // Reset the chart anyway
    //     return;
    // }
    const canvas = this.template.querySelector('.spend-over-time-chart');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    this.destroyChart('spendChart');

    const fullMonthNames = {
        January: 'Jan', February: 'Feb', March: 'Mar', April: 'Apr',
        May: 'May', June: 'Jun', July: 'Jul', August: 'Aug',
        September: 'Sep', October: 'Oct', November: 'Nov', December: 'Dec'
    };

    const standardMonthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    let chartLabels = [];
    const actualMap = {};
    const forecastMap = {};
    const forecastForDownload = [];

    const currentYear = new Date().getFullYear();

    // 🔁 Choose labels based on year type
    if (this.selectedSpendYearType === 'Fiscal') {
        chartLabels = this.fiscalLabels?.map(label => label.slice(0, 3)) || standardMonthLabels;
    } else {
        chartLabels = standardMonthLabels;
        }

// if (this.selectedSpendYearType === 'Fiscal') {
//     chartLabels = this.fiscalLabels || standardMonthLabels;  // 🔥 Use full fiscal labels like "Mar 2025"
// } else {
//     chartLabels = standardMonthLabels.map(month => `${month} ${this.selectedYearSup}`);
// }


    // data.forEach(item => {
    //     const shortMonth = fullMonthNames[item.month];
    //     if (!shortMonth) return;

    //     if (item.isForecast) {
    //         forecastMap[shortMonth] = item.amount;
    //         forecastForDownload.push({
    //             month: `${shortMonth} ${currentYear}`,
    //             forecast: item.amount
    //         });
    //     } else {
    //         actualMap[shortMonth] = item.amount;
    //     }
        // });
        
       data.forEach(item => {
    const shortMonth = fullMonthNames[item.month];
    if (!shortMonth) return;

    const monthIndex = standardMonthLabels.indexOf(shortMonth); // 0-based
    if (monthIndex === -1) return;

    const today = new Date();
    const currentMonthIndex = today.getMonth();
    const currentYear = today.getFullYear();

    // 🧠 Parse year based on label context
    let forecastYear = currentYear;

    if (this.selectedSpendYearType === 'Fiscal') {
        // Find full label like "Apr2025" in fiscalLabels
        const fullMonthLabel = this.fiscalLabels.find(label => label.startsWith(shortMonth));
        if (fullMonthLabel) {
            // Extract year from label
            forecastYear = parseInt(fullMonthLabel.replace(shortMonth, ''));
        }
    } else if (this.selectedSpendYearType === 'Custom') {
        forecastYear = parseInt(this.selectedSpendCustomYear);
    }

    const forecastDate = new Date(`${forecastYear}-${(monthIndex + 1).toString().padStart(2, '0')}-01`);

    const isFuture = forecastDate >= new Date(today.getFullYear(), today.getMonth(), 1);

    if (item.isForecast && isFuture) {
        forecastMap[shortMonth] = item.amount;
        forecastForDownload.push({
            month: `${shortMonth} ${forecastYear}`,
            forecast: item.amount
        });
    } else if (!item.isForecast) {
        actualMap[shortMonth] = item.amount;
    }
});


    const actualData = chartLabels.map(label =>
        actualMap[label] != null ? actualMap[label] : 0
    );

    const forecastData = chartLabels.map(label =>
        forecastMap[label] ?? null
    );

    this.forecastData = forecastForDownload;
    this.hasForecastData = forecastForDownload.length > 0;

    const currencySymbol = this.currencySymbol;

    this.chartInstances.spendChart = new window.Chart(ctx, {
        type: 'line',
        data: {
            labels: chartLabels,
            datasets: [
                {
                    label: `Spend (${currencySymbol})`,
                    data: actualData,
                    borderColor: '#9D53F2',
                    backgroundColor: 'rgba(157, 83, 242, 0.3)',
                    tension: 0.4,
                    fill: false,
                    borderWidth: 2
                },
                {
                    label: `Forecasted Spend (${currencySymbol})`,
                    data: forecastData,
                    borderColor: '#FFB300',
                    backgroundColor: 'rgba(255, 179, 0, 0.0)',
                    fill: false,
                    tension: 0.3,
                    borderWidth: 2,
                    borderDash: [5, 5],
                    pointRadius: 3
                }
            ]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'top' },
                tooltip: { mode: 'index', intersect: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return `${currencySymbol}${value.toLocaleString()}`;
                        }
                    },
                    title: {
                        display: true,
                        text: `Spend (${currencySymbol})`
                    }
                },
                x: {
                    title: {
                        display: true,
                        text: 'Month'
                    }
                }
            }
        }
    });
}

 


downloadSpendForecastAsCSV() {
    console.log('⬇️ Starting Spend Forecast CSV download...');
    console.log('forecastData', this.forecastData);
    if (!this.hasForecastData || this.forecastData.length === 0) {
        console.log('hasForecastData==>/',this.hasForecastData);
        
        this.showToast('No Forecast', 'No forecast data available to download.', 'warning');
        return;
    }

    if (!Array.isArray(this.forecastData) || this.forecastData.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Forecast Found',
                message: 'No forecasted spend data available to download.',
                variant: 'warning'
            })
        );
        return;
    }

    // Filter forecasted values starting from current month onward
    const today = new Date();
    const currentMonthIndex = today.getMonth(); //11/ 0-11
    const currentYear = today.getFullYear();

    let csv = 'Month,Forecasted Spend\n';

    this.forecastData.forEach(entry => {
        if (!entry.month || entry.forecast == null) return;

        const [monthStr, yearStr] = entry.month.split(' ');
        const forecastYear = parseInt(yearStr, 10);
        const forecastMonthIndex = new Date(`${monthStr} 1, ${forecastYear}`).getMonth();

        // Only include forecasted months from current month of current year onward
        if (
            forecastYear === currentYear &&
            forecastMonthIndex >= currentMonthIndex &&
            entry.forecast !== 0
        ) {
            csv += `${entry.month},${entry.forecast}\n`;
        }
    });

    console.log('📄 Final Spend Forecast CSV:\n' + csv);

    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);

    const baseName = this.customFileName?.trim();
    const safeName = baseName
        ? `${baseName}_SpendForecast.csv`
        : 'SpendForecast.csv';

    link.setAttribute('download', safeName);
    document.body.appendChild(link);

    setTimeout(() => {
        link.click();
        document.body.removeChild(link);
        console.log('✅ Spend Forecast Download triggered');
    }, 50);
}



    renderOnTimeDeliveryChart(data) {
        const ctx = this.template.querySelector('.on-time-delivery-chart')?.getContext('2d');
        if (!ctx) {
            console.warn('ChartJS canvas context not found.');
            return;
        }

        this.destroyChart('onTimeDeliveryChart');

        // const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        //     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        // const monthLabels = this.fiscalLabels.map(label => label.slice(0, 3)); // Get 'Jan', 'Feb' etc.
        const isFiscal = this.selectedSpendYearType === 'Fiscal';

const monthLabels = isFiscal && Array.isArray(this.fiscalLabels)
    ? this.fiscalLabels.map(label => label.slice(0, 3))
    : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];



        // Default 0-values if no data or filters not selected
        let onTimeData = new Array(12).fill(0);
        let lateData = new Array(12).fill(0);

        if (Array.isArray(data) && data.length > 0) {
            const deliveryMap = {};
            monthLabels.forEach(label => {
                deliveryMap[label] = { onTime: 0, late: 0 };
            });

            data.forEach(entry => {
                const rawMonth = entry.month; // e.g., "1/2025"
                if (!rawMonth.includes('/')) return;

                const [monthStr] = rawMonth.split('/');
                const monthIndex = parseInt(monthStr, 10) - 1;
                const monthLabel = monthLabels[monthIndex];

                if (monthLabel) {
                    deliveryMap[monthLabel].onTime += entry.onTime || 0;
                    deliveryMap[monthLabel].late += entry.late || 0;
                }
            });

            onTimeData = monthLabels.map(label => deliveryMap[label].onTime);
            lateData = monthLabels.map(label => deliveryMap[label].late);
        }

        // Render the chart with either real or empty data
        this.chartInstances.onTimeDeliveryChart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: monthLabels,
                datasets: [
                    {
                        label: 'On Time',
                        backgroundColor: '#9D53F2',
                        data: onTimeData,
                        stack: 'stack1'
                    },
                    {
                        label: 'Late',
                        backgroundColor: '#3290ED',
                        data: lateData,
                        stack: 'stack1'
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: 'On-Time Delivery Performance'
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false // ← show tooltip even when not directly over a bar
                    }
                },
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false // ← show tooltip even on the x-axis label
                },

                scales: {
                    x: {
                        stacked: true,
                        title: { display: true, text: 'Month' }
                    },
                    y: {
                        stacked: true,
                        beginAtZero: true,
                        title: { display: true, text: 'Deliveries' },
                        ticks: { precision: 0 }
                    }
                }
            }
        });
    }



    //Quality analysis chart

    renderQualityChart(data) {

         // If showChart is false, skip creating a Chart.js instance entirely
    if (!this.showChart) {
        console.log('📊 Skipping chart rendering because showChart is false — showing summary instead.');
        this.renderQualitySummary(data);
        return;
    }

        const ctx = this.template.querySelector('.quality-analysis-chart')?.getContext('2d');
        if (!ctx) {
            console.warn('⚠️ ChartJS canvas context not found for quality chart.');
            return;
        }

        this.destroyChart('qualityChart');

        // const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        //     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        // const monthLabels = this.fiscalLabels.map(label => label.slice(0, 3)); // Get 'Jan', 'Feb' etc.
        const isFiscal = this.selectedSpendYearType === 'Fiscal';

const monthLabels = isFiscal && Array.isArray(this.fiscalLabels)
    ? this.fiscalLabels.map(label => label.slice(0, 3))
    : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];


        let goodData = [];
        let badData = [];

        for (let i = 1; i <= 12; i++) {
            const monthData = data[i] || { good: 0, bad: 0 };
            goodData.push(monthData.good);
            badData.push(monthData.bad);
        }

        this.chartInstances.qualityChart = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels: monthLabels,
                datasets: [
                    {
                        label: 'Good Quality',
                        backgroundColor: '#9D53F2',
                        data: goodData,
                        stack: 'stack1'
                    },
                    {
                        label: 'Bad Quality',
                        backgroundColor: '#3290ED',
                        data: badData,
                        stack: 'stack1'
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: 'Monthly Quality Performance'
                    },
                    tooltip: {
                        mode: 'index',         // Show all bars at the same x-axis index
                        intersect: false        // Show tooltip even if not directly over the bar
                    }
                },
                interaction: {
                    mode: 'nearest',          // Nearest point on the x-axis
                    axis: 'x',
                    intersect: false          // Allow tooltip on x-axis hover
                },
                scales: {
                    x: {
                        stacked: true,
                        title: {
                            display: true,
                            text: 'Month'
                        }
                    },
                    y: {
                        stacked: true,
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Line Items'
                        },
                        ticks: {
                            precision: 0
                        }
                    }
                }
            }
        });
        
//         const summaryContainer = this.template.querySelector('.quality-summary');
//         if(this.showChart == false){
// if (summaryContainer) {
//     let summaryHtml = `
//         <table style="margin-top: 1rem; border-collapse: collapse; width: 100%;">
//             <thead>
//                 <tr style="font-weight: bold; background-color: #f3f3f3;">
//                     <td style="padding: 6px 10px;">📅 Month</td>
//                     <td style="padding: 6px 10px; color: #36a2eb;">✅ Good Quality</td>
//                     <td style="padding: 6px 10px; color: #ff6384;">❌ Bad Quality</td>
//                 </tr>
//             </thead>
//             <tbody>`;

//     let hasData = false;

//     for (let i = 0; i < 12; i++) {
//         const good = goodData[i];
//         const bad = badData[i];

//         if (good === 0 && bad === 0) {
//             continue; // ❌ Skip months with no data
//         }

//         hasData = true;

//         summaryHtml += `
//             <tr>
//                 <td style="padding: 6px 10px;">${monthLabels[i]}</td>
//                 <td style="padding: 6px 10px;">${good}</td>
//                 <td style="padding: 6px 10px;">${bad}</td>
//             </tr>`;
//     }

//     summaryHtml += `
//             </tbody>
//         </table>`;

//     summaryContainer.innerHTML = hasData ? summaryHtml : `<p style="margin-top:1rem;">📭 No quality data available for this year.</p>`;
// }
//         }
this.renderQualitySummary(data);
    }

renderQualitySummary(data) {
    const summaryContainer = this.template.querySelector('.quality-summary');
    if (!summaryContainer) return;

    const isFiscal = this.selectedSpendYearType === 'Fiscal';
    const monthLabels =
        isFiscal && Array.isArray(this.fiscalLabels)
            ? this.fiscalLabels.map(label => label.slice(0, 3))
            : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    let summaryHtml = `
        <table style="margin-top: 1rem; border-collapse: collapse; width: 100%;">
            <thead>
                <tr style="font-weight: bold; background-color: #f3f3f3;">
                    <td style="padding: 6px 10px;">📅 Month</td>
                    <td style="padding: 6px 10px; color: #36a2eb;">✅ Good Quality</td>
                    <td style="padding: 6px 10px; color: #ff6384;">❌ Bad Quality</td>
                </tr>
            </thead>
            <tbody>`;

    let hasData = false;
    for (let i = 1; i <= 12; i++) {
        const monthData = data[i] || { good: 0, bad: 0 };
        const good = monthData.good;
        const bad = monthData.bad;

        if (good === 0 && bad === 0) continue;
        hasData = true;

        summaryHtml += `
            <tr>
                <td style="padding: 6px 10px;">${monthLabels[i - 1]}</td>
                <td style="padding: 6px 10px;">${good}</td>
                <td style="padding: 6px 10px;">${bad}</td>
            </tr>`;
    }

    summaryHtml += `
            </tbody>
        </table>`;

    summaryContainer.innerHTML = hasData
        ? summaryHtml
        : `<p style="margin-top:1rem;">📭 No quality data available for this year.</p>`;
}




    //Inventory overview



    setFiscalDates(fromProductSelection = false) {  
        return getOrgFiscalStartMonth()
            .then(startMonth => {
                console.log('Start month: ', startMonth);

                const today = new Date();
                const currentMonth = today.getMonth() + 1;

                // Fiscal year starts this year if today is >= start month, else previous year
                let fiscalYearStart;
                if (currentMonth >= startMonth) {
                    fiscalYearStart = today.getFullYear();
                    console.log('if part today.getFullYear', today.getFullYear);

                } else {
                    fiscalYearStart = today.getFullYear() - 1;
                    console.log('else part today.getFullYear', today.getFullYear);

                }
                console.log('fiscalYearStart = ', fiscalYearStart);
                console.log('startMonth = ', startMonth);
                const fromDate = new Date(fiscalYearStart, startMonth - 1, 1); // e.g., Jan 1
                const toDate = new Date(fiscalYearStart, startMonth - 1 + 12, 0);

                console.log(`📆 Fiscal Dates Set - From: ${fromDate}, To: ${toDate}`);

                // this.fromDate = fromDate.toISOString().split('T')[0];
                // this.toDate = toDate.toISOString().split('T')[0];


                this.fromDate = formatDateLocal(fromDate);
                this.toDate = formatDateLocal(toDate);

                console.log(`📆 Fiscal Dates Set - From: ${this.fromDate}, To: ${this.toDate}`);

                // Optionally fetch data immediately if triggered by product selection
                // if (fromProductSelection && this.productId) {
                //     return this.fetchData();
                // }

                return Promise.resolve();
            })
            .catch(error => {
                console.error('Error fetching fiscal start month:', error);
                return Promise.reject(error);
            });
    }

    handleProductSelection(event) {
        console.log('Lookup Event:', JSON.stringify(event.detail));
        this.productId = event.detail.Id;
        this.productName = event.detail.Name;

        // Optional: Clear existing chart
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }

        this.isSingleProductView = true;
        this.isTop5View = false;
        this.singleChartPending = true; // Optional: prepares canvas rendering

        // ⚠️ Call setFiscalDates and fetch data AFTER dates are set
        this.setFiscalDates(true).then(() => {
            this.fetchData(); // Now dates are ready
            // this.loadTop5Data();

        }).catch(error => {
            console.error('❌ Failed to set fiscal dates:', error);
        });

    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        console.log('From Date selected:', this.fromDate);
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
    }

    handleSearch() {
        console.log('🔍 handleSearch triggered');

        if (this.productId && this.fromDate && this.toDate) {
            console.log('📦 Fetching single product data:', this.productId, this.fromDate, this.toDate);

            this.fetchData(); // For selected product
        } else {
            console.log('🔄 Fallback to Top 5');

            this.loadTop5Data(); // Default fallback for top 5 products
        }
    }

    
    loadTop5Data() {
                    this.isLoading = true;
        getTop5Inventory()
            .then(result => {
                this.top5Data = result;
                this.inventoryLevelData = null;
                this.isTop5View = true;
                this.isSingleProductView = false;
                this.top5ChartPending = true; // will trigger in renderedCallback
            })
            .catch(error => {
                console.error('Error loading top 5 inventory:', error);
            })
          .finally(() => {
                    this.isLoading = false;
                });
    }

    fetchData() {
        console.log('📤 Calling getSummedInventory Apex method...');
        console.log('📤 Fetching for:', this.productId, 'From:', this.fromDate, 'To:', this.toDate);
            this.isLoading = true;

        getSummedInventory({
            productId: this.productId,
            fromDate: this.fromDate,
            toDate: this.toDate
        })
            .then(result => {
                console.log('✅ Received inventory data:', result);

                this.inventoryLevelData = result || {};
                this.top5Data = null;
                this.isTop5View = false;
                this.isSingleProductView = true;
                this.singleChartPending = true; // will trigger in renderedCallback
                console.log('inventoryLevelData====>>> AZAZ', this.inventoryLevelData);

                this.renderInitial();

            })
            .catch(error => {
                console.error('Error fetching inventory:', error);
            })
          .finally(() => {
                    this.isLoading = false;
                });
    }
    renderedCallback() {
        this.renderInitial();

        if (this.showChart && this.organisationId) {
            this.renderInitial();
        } else {
            this.destroyChart();
        }

    }

    renderInitial() {
        console.log('in render call back');

        if (this.chartJsReady) {
            if (this.top5ChartPending && this.isTop5View) {
                const canvas = this.template.querySelector('canvas.barChartTop5');
                if (canvas) {
                    this.renderTop5Chart();
                    this.setFiscalDates();
                    this.top5ChartPending = false;
                }
            }

            if (this.singleChartPending && this.isSingleProductView) {
                console.log('🔍 Looking for single chart canvas...');

                const canvas = this.template.querySelector('canvas.barChartSingle');
                if (canvas) {
                    console.log('🎯 Canvas found, rendering chart...');

                    this.renderChartSingleProductInventoryLevel();
                    this.singleChartPending = false;
                } else {
                    console.warn('🕳️ Canvas not in DOM yet.');
                }
            }
        }
    }

    get rawExpected() {
        return this.inventoryLevelData?.totalExpectedRaw ?? 0;
    }
    get rawConsumed() {
        return this.inventoryLevelData?.totalConsumedRaw ?? 0;
    }
    get rawScrapped() {
        return this.inventoryLevelData?.totalScrappedRaw ?? 0;
    }
    get wipQuantity() {
        return this.inventoryLevelData?.totalWipQuantity ?? 0;
    }
    get wipScrapped() {
        return this.inventoryLevelData?.totalWipScrapped ?? 0;
    }
    get finishedRequested() {
        return this.inventoryLevelData?.totalFinishedRequested ?? 0;
    }
    get finishedInStock() {
        return this.inventoryLevelData?.totalFinishedInStock ?? 0;
    }
    get finishedScrapped() {
        return this.inventoryLevelData?.totalFinishedScrapped ?? 0;
    }

    renderChartSingleProductInventoryLevel() {
        console.log('before return renderChartSingleProductInventoryLevel', this.inventoryLevelData);
        console.log('before return this.chartJsReady', this.chartJsReady);

        if (!this.chartJsReady || !this.inventoryLevelData) return;
        console.log('inventoryLevelData===>>>', this.inventoryLevelData);

        // Wait until canvas is in DOM
        setTimeout(() => {
            const canvas = this.template.querySelector('canvas.barChartSingle');
            if (!canvas) {
                console.warn('⚠️ Single product canvas not found');
                return;
            }

            const ctx = canvas.getContext('2d');
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;

            }

            this.chart = new window.Chart(ctx, {
                type: 'bar',
                data: {
                    labels: ['Raw', 'WIP', 'Finished'],
                    datasets: [
                        {
                            label: 'Expected',
                            data: [
                                this.inventoryLevelData.totalExpectedRaw,
                                this.inventoryLevelData.totalWipQuantity,
                                this.inventoryLevelData.totalFinishedRequested
                            ],
                            backgroundColor: '#0070d2'
                        },
                        {
                            label: 'Consumed / In Stock',
                            data: [
                                this.inventoryLevelData.totalConsumedRaw,
                                this.inventoryLevelData.totalWipScrapped,
                                this.inventoryLevelData.totalFinishedInStock
                            ],
                            backgroundColor: '#00c853'
                        },
                        {
                            label: 'Scrapped',
                            data: [
                                this.inventoryLevelData.totalScrappedRaw,
                                this.inventoryLevelData.totalWipScrapped,
                                this.inventoryLevelData.totalFinishedScrapped
                            ],
                            backgroundColor: '#d50000'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { position: 'top' },
                        title: {
                            display: true,
                            text: this.productName
                                ? `Inventory Summary for ${this.productName}`
                                : 'Inventory Summary for Fiscal Year'
                        },
                        tooltip: {
                            mode: 'index',     // ✅ Show tooltip for all datasets at a label
                            intersect: false
                        }
                    }
                }
            });
        }, 0); // Defer until DOM is rendered
    }

    renderTop5Chart() {
        if (!this.chartJsReady || !this.top5Data || this.top5Data.length === 0) {
            console.warn('🚫 Top 5 data not available or Chart.js not ready');
            return;
        }

        console.log('📊 Top 5 data:', JSON.stringify(this.top5Data));

        // Wait until canvas is rendered in DOM
        setTimeout(() => {
            const canvas = this.template.querySelector('canvas.barChartTop5');
            if (!canvas) {
                console.warn('⚠️ Top 5 inventory canvas not found');
                return;
            }

            const ctx = canvas.getContext('2d');
            if (this.chart) this.chart.destroy();


            const labels = this.top5Data.map(item => item.productName);
            const raw = this.top5Data.map(item => item.totalExpectedRaw);
            const wip = this.top5Data.map(item => item.totalWipQuantity);
            const finished = this.top5Data.map(item => item.totalFinishedInStock);

            this.chart = new window.Chart(ctx, {
                type: 'bar',
                data: {
                    labels,
                    datasets: [
                        { label: 'Raw', backgroundColor: '#1f77b4', data: raw },
                        { label: 'WIP', backgroundColor: '#ff7f0e', data: wip },
                        { label: 'Finished', backgroundColor: '#2ca02c', data: finished }
                    ]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { position: 'top' },
                        title: {
                            display: true,
                            text: 'Top 5 Products Inventory Summary (Current Fiscal Year)'
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false
                        }
                    },
                    scales: {
                        x: { stacked: true },
                        y: { stacked: true }
                    }
                }
            });
        }, 0); // Wait for render cycle
    }


// safety stock stock alert tab 
 get safetyTabClass() {
        return this.isSafety ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }
    selectSafety() {
    console.log('in selectsafety');
    this.clearCharts();
    this.selectedProduct = { Id: null, Name: null };
    this.isSupplyOverview=false;
    this.isSupplierScorecard=false;
    this.resetTabs();
        this.isSafety = true;
                    this.isLoading = true;
    getDefaultWarehouseByStock({ organisationId: this.organisationId })
        .then(site => {
            if (site) {
                console.log('sucess');
                this.selectedWarehouseForSafetyStock.Id = site.Id;
                this.selectedWarehouseForSafetyStock.Name = site.Name;
                //console.log('warehouse default ->',this.selectedWarehouseForSafetyStock);
                this.isWarehouseSelectedForsafetyStock = true;
                this.locationFilter = "Company__c = '" + this.organisationId + "' AND Active__c = true AND Site__c = '" + this.selectedWarehouseForSafetyStock.Id + "'";
                this.fetchSafetyStockData();
                this.renderSafetyStockChart();
            } else {
                console.warn('No default warehouse found based on stock');
            }
        })
        .catch(error => {
            console.error('Error fetching default warehouse by stock:', error);
        })
          .finally(() => {
                    this.isLoading = false;
                });
    }
    renderSafetyStockChart() {
        console.log('in render');
    const canvas = this.template.querySelector('[data-id="safetyStockChart"]');

    if (this.charts.safety) {
        this.charts.safety.destroy();
        this.charts.safety = null;
    }

    if (!canvas) return;

    const ctx = canvas.getContext('2d');

    if (!this.filteredSafetyStockData.length) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.font = '16px Arial';
        ctx.fillStyle = '#666';
        ctx.fillText('No stock data to display.', 20, 40);
        return;
    }

    // Prepare labels and data
    const labels = this.filteredSafetyStockData.map(i => i.productName);
    const currentStock = this.filteredSafetyStockData.map(i => i.currentStock);
    const reorderLevel = this.filteredSafetyStockData.map(i => i.reorderLevel);
    const safetyStock = this.filteredSafetyStockData.map(i => i.safetyStock);

    const currentColors = this.filteredSafetyStockData.map(i =>
        i.badgeLabel === 'Critical' ? 'rgba(231, 76, 60, 0.7)' : // Red
        i.badgeLabel === 'Reorder' ? 'rgba(243, 156, 18, 0.7)' : // Yellow
        i.badgeLabel === 'Safe' ? 'rgba(46, 204, 113, 0.7)' :     // Green
        'rgba(149, 165, 166, 0.7)' // Gray (Not Configured)
    );

    // Chart config
    this.charts.safety = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels,
            datasets: [
                {
                    label: 'Current Stock',
                    data: currentStock,
                    backgroundColor: 'rgba(47, 239, 127, 0.7)'
                },
                {
                    label: 'Reorder Level',
                    data: reorderLevel,
                   backgroundColor: '#3290ED',
                        // borderColor: '#36A2EB',
                },
                {
                    label: 'Safety Stock',
                    data: safetyStock,
                   backgroundColor: 'rgba(229, 68, 103, 0.6)'
                        // borderColor: '#FF6384',
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            indexAxis: 'x', // ← Horizontal bar chart
            scales: {
                x: {
                    beginAtZero: true,
                    stacked: false
                },
                y: {
                    stacked: false,
                    ticks: {
                        autoSkip: false
                    }
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Stocks Need Attention',
                    font: { size: 16 }
                },
                   legend: { position: 'bottom' },
                        tooltip: {
                            mode: 'index',
                            intersect: false
                        }
            },
            barThickness: 20
        }
    });
}
fetchSafetyStockData() {
    if (!this.selectedWarehouseForSafetyStock) {
        this.showToast('Missing Input', 'Please select a warehouse.', 'warning');
        return;
    }

    this.isLoading = true;
    // call to getstockalertdata
    getStockAlertData({
        siteId: this.selectedWarehouseForSafetyStock.Id,
        location: this.selectedLocation?.Id || null,
        product: this.selectedProduct?.Id || null,
        OrgId: this.organisationId
    })
    .then(result => {
        console.log('⚠️ Raw result from Apex:', JSON.stringify(result));

        let critical = 0, reorder = 0, unconfigured = 0;
        console.log('its sucess');
        this.safetyStockData = result.map(item => {
            let badgeLabel = '';
            let badgeClass = 'slds-text-align_left custom-align-left';
            const cs = item.currentStock || 0;
            const ss = item.safetyStock || 0;
            const rl = item.reorderLevel || 0;

            if (ss === 0 && rl === 0) {
                badgeLabel = 'Not Configured';
                badgeClass += ' badge-gray';
                unconfigured++;
            } else if (cs < ss) {
                badgeLabel = 'Critical';
                badgeClass += ' badge-red';
                critical++;
            } else if (cs < rl) {
                badgeLabel = 'Reorder';
                badgeClass += ' badge-yellow';
                reorder++;
            } else {
                badgeLabel = 'Safe';
                badgeClass += ' badge-green';
            }

            return { ...item, badgeLabel, badgeClass };
        });
        console.log('1');
        // Store alert summary for UI display
        this.alertSummary = { critical, reorder, unconfigured };
        console.log('2');
        // Priority: Critical + Reorder first
        let criticalOrReorder = this.safetyStockData
            .filter(i => i.badgeLabel === 'Critical' || i.badgeLabel === 'Reorder');
        console.log('3');
        if (criticalOrReorder.length > 0) {
            this.filteredSafetyStockData = criticalOrReorder.slice(0, 20);  console.log('4');
        } else {
            // Fallback to safe/not configured
            console.log('5');
            this.filteredSafetyStockData = this.safetyStockData
                .filter(i => i.badgeLabel === 'Safe' || i.badgeLabel === 'Not Configured')
                .slice(0, 20);
            console.log('6');
            this.showToast(
                'No Critical Stock Alerts',
                'No products need reordering now. Displaying safe stock instead.',
                'info'
            );
        }
        console.log('call to render');
        this.renderSafetyStockChart();
    })
    .catch(error => {
        console.error('Fetch error:', error);
        this.showToast('Error', error.body?.message || 'Failed to fetch stock alerts.', 'error');
    })
    .finally(() => {
        this.isLoading = false;
    });
}

handleWarehouseSaveForSafetyStock(event) {
     this.selectedWarehouseForSafetyStock.Id = event.detail.Id;
     this.selectedWarehouseForSafetyStock.Name = event.detail.Name;
    console.log('Selected Warehouse for Safety Stock:', this.selectedWarehouseForSafetyStock.Name);
    this.isWarehouseSelectedForsafetyStock=true;
    this.locationFilter = "Company__c = '" + this.organisationId + "' AND Active__c = true AND Site__c = '" + this.selectedWarehouseForSafetyStock.Id + "'";
    this.fetchSafetyStockData();
    this.renderSafetyStockChart();
}
handleSiteRemovedForSafety(){
    this.selectedWarehouseForSafetyStock = {Id:null,Name:null};
    this.isWarehouseSelectedForsafetyStock = false;
    this.safetyStockData = [];
    this.filteredSafetyStockData = [];
    this.locationFilter=null;
}
handleLocationSelect(event) {
    this.selectedLocation={Id: event.detail.Id, Name: event.detail.Name};
    this.fetchSafetyStockData();
}
handleLocationRemove(){
    this.selectedLocation={Id:'',Name:''}
    this.fetchSafetyStockData();
}
handleSafetyStockProductSelected(event) {
    this.selectedProduct = { Id: event.detail.Id, Name: event.detail.Name };
    this.fetchSafetyStockData();
}

handleSafetyProductRemove(){
    this.selectedProduct = { Id:null,Name:null};
    this.fetchSafetyStockData();
}
prepareFilterOptions() {
    const warehouses = new Set();
    const locations = new Set();
    const products = new Set();

    this.safetyStockData.forEach(item => {
        warehouses.add(item.warehouse);
        locations.add(item.location);
        products.add(item.productName);
    });

    this.warehouseOptions = [...warehouses].map(val => ({ label: val, value: val }));
    this.locationOptions = [...locations].map(val => ({ label: val, value: val }));
    this.productOptions = [...products].map(val => ({ label: val, value: val }));
}
applyFiltersForSafetyStock() {
    this.filteredSafetyStockData = this.safetyStockData.filter(item => {
        return (!this.selectedWarehouseForSafetyStock.Id || item.warehouse === this.selectedWarehouseForSafetyStock.Id) &&
               (!this.selectedLocationForSafetyStock || item.location === this.selectedLocationForSafetyStock) &&
               (!this.selectedProductFilterForSafetyStock || item.productName === this.selectedProductFilterForSafetyStock);
    });
}
clearCharts() {
    for (const key in this.charts) {
        if (this.charts[key]) {
            this.charts[key].destroy();
            this.charts[key] = null;
        }
    }
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
get totalPagesSafety() {
    return this.filteredSafetyStockData ? Math.ceil(this.filteredSafetyStockData.length / this.pageSizeSafety) : 1;
}

get isFirstPageSafety() {
    return this.currentPageSafety === 1;
}

get isLastPageSafety() {
    return this.currentPageSafety === this.totalPagesSafety;
}

get sortedSafetyData() {
    if (!this.filteredSafetyStockData) return [];
    return [...this.filteredSafetyStockData].sort((a, b) => {
        const aVal = a[this.sortBySafety] ? a[this.sortBySafety].toString().toLowerCase() : '';
        const bVal = b[this.sortBySafety] ? b[this.sortBySafety].toString().toLowerCase() : '';
        const multiplier = this.sortDirectionSafety === 'asc' ? 1 : -1;
        return aVal > bVal ? multiplier : aVal < bVal ? -multiplier : 0;
    });
}

get pagedSafetyData() {
    if (!this.sortedSafetyData || this.sortedSafetyData.length === 0) return [];
    const start = (this.currentPageSafety - 1) * this.pageSizeSafety;
    const end = start + this.pageSizeSafety;
    return this.sortedSafetyData.slice(start, end);
}
handleSortSafety(event) {
    this.sortBySafety = event.detail.fieldName;
    this.sortDirectionSafety = event.detail.sortDirection;
    this.currentPageSafety = 1;
}

handlePrevPageSafety() {
    if (this.currentPageSafety > 1) this.currentPageSafety--;
}

handleNextPageSafety() {
    if (this.currentPageSafety < this.totalPagesSafety) this.currentPageSafety++;
}
}