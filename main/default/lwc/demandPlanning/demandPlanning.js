function formatDateLocal(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

import { LightningElement, track, api } from 'lwc';
import chartJs from '@salesforce/resourceUrl/ChartJS';
import { loadScript } from 'lightning/platformResourceLoader';
//import getDemandData from '@salesforce/apex/sandOP.getDemandData';
import getTopProductsByDemand from '@salesforce/apex/sandOP.getTopProductsByDemand';
import getWarehouseInventory from '@salesforce/apex/sandOP.getWarehouseInventory';
import getLocationInventory from '@salesforce/apex/sandOP.getLocationInventory';
// import getStockAlertData from '@salesforce/apex/sandOP.getStockAlertData';
import getAgingTrendData from '@salesforce/apex/sandOP.getAgingTrendData';
import getCustomerOrderTrend from '@salesforce/apex/sandOP.getCustomerOrderTrend';
import getCustomerSummary from '@salesforce/apex/sandOP.getCustomerSummary';
import getDynamicStockAgingData from '@salesforce/apex/sandOP.getDynamicStockAgingData';
import getDemandForecastWithHistory from '@salesforce/apex/sandOP.getDemandForecastWithHistory';
import getTopCustomersForProduct from '@salesforce/apex/sandOP.getTopCustomersForProduct';
import getDefaultProductFromOrderItem from '@salesforce/apex/sandOP.getDefaultProductFromOrderItem';
import getDefaultCustomerFromOrders from '@salesforce/apex/sandOP.getDefaultCustomerFromOrders';
import getDefaultWarehouseByStock from '@salesforce/apex/sandOP.getDefaultWarehouseByStock';
import generateForecastFromHistorical from '@salesforce/apex/sandOP.generateForecastFromHistorical';
import getCurrencySymbol from '@salesforce/apex/sandOP.getCurrencySymbol';
import getTopReturnedProducts from '@salesforce/apex/sandOP.getTopReturnedProducts';
import getReturnReasonDistribution from '@salesforce/apex/sandOP.getReturnReasonDistribution';
import getReturnRateTrend from '@salesforce/apex/sandOP.getReturnRateTrend';
import getCurrentFiscalYear from '@salesforce/apex/sandOP.getCurrentFiscalYear';
import checkversionAvailability from '@salesforce/apex/sandOP.checkversionAvailability';
import getTopReturningCustomers from '@salesforce/apex/sandOP.getTopReturningCustomers';
import getSummedInventory from '@salesforce/apex/sandOP.getSummedInventory';
import getTop5Inventory from '@salesforce/apex/sandOP.getTop5Inventory';
import getOrgFiscalStartMonth from '@salesforce/apex/sandOP.getOrgFiscalStartMonth';
import getStockMovementData from '@salesforce/apex/sandOP.getStockMovementData';
import saveSimulation from '@salesforce/apex/sandOP.saveSimulation';
import evaluateSimulations from '@salesforce/apex/sandOP.evaluateSimulations';

import { NavigationMixin } from 'lightning/navigation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DemandPlanning extends NavigationMixin(LightningElement) {


//       @api initContext({ organisationId, flags }) {
//     this.organisationId = organisationId;
//     this.isDemandTabOpen = flags?.isDemandTabOpen;
//     this.isInventoryTabOpen = flags?.isInventoryTabOpen;
//     this.isRiskAndReturnTabOpen = flags?.isRiskAndReturnTabOpen;
//   }

    selectedFiscalYear = new Date().getFullYear();
    @track currencySymbol=null;
    @track isDemandProductSel = false;
    @track isWarehouseSelectedForAging = false;
    @track isDemand = false;
    @track isInventory = false;
    @api organisationId;
    @api isDemandTabOpen;
    @api isInventoryTabOpen;
    @api isRiskAndReturnTabOpen;
    @track isSiteSlectSelected = false;
    @track selectedProduct = { Id: null, Name: null };
    @track custProd = { Id: null, Name: null };
    @track selectedSite = { Id: null, Name: null };
    @track selectedLocation = { Id: '', Name: '' };
    @track siteFilter;
    @track demandData = {};
    @track topProductsData = {};
    @track showallWarehouses = false;
    chartJsInitialized = false;
    charts = {};
    @track selectedWarehouse = null;
    @track selectedWarehouseForSafetyStock = { Id: null, Name: null };
    @track isWarehouseSelectedForsafetyStock = false;
    @track locationFIlter = '';
    @track inventoryData = {};
    @track locationInventoryData = {};
    @track isLoading = false;
    @track inventoryProduct = { Id: '', Name: '' };
    @track isSafety = false;
    @api isSafetyTabOpen;
    @track safetyStockData = [];
    @track filteredSafetyStockData = [];
    @track selectedProductFilterForSafetyStock = '';
    @track warehouseOptions = [];
    @track locationOptions = [];
    @track productOptions = [];

    
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
    @track isInventoryLevel = false;
chartJsReady = false;

    top5ChartPending = false;
    singleChartPending = false;
    isSingleProductView = false;

    @track showTable = false;
    @track error;
    @track summaryData;
    @track top5Data;
    chartJsInitialized = false;

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
@track selectedWarehouseForAging = {Id:null,Name:null};
@track isAging = false;
@api isAgingTabOpen;
@track stockAgingData = [];
filteredAgingData = [];
agingTableColumns = [
    { label: 'Product', fieldName: 'productName', sortable: true },
    { label: 'Quantity', fieldName: 'quantity', type: 'number', sortable: true },
    { label: 'Received Date', fieldName: 'receivedDate', type: 'date', sortable: true },
    { label: 'Age (Days)', fieldName: 'ageInDays', type: 'number', sortable: true },
    { label: 'Bucket', fieldName: 'bucket', sortable: true },
    {
        label: 'Status',
        fieldName: 'status',
        sortable: true,
        cellAttributes: {
            class: { fieldName: 'statusClass' }
        }
    }
];

@track agingFilters = {
    product: '',
    bucket: '',
    status: ''
};
@track isCustomerSelected = false;
@track productOptionsAging = [];
@track bucketOptions = [
    { label: '<30d', value: '<30d' },
    { label: '30–90d', value: '30–90d' },
    { label: '90–180d', value: '90–180d' },
    { label: '180–365d', value: '180–365d' },
    { label: '>365d', value: '>365d' },
     { label: 'Expired', value: 'Expired' } 
];

@track statusOptions = [
    { label: 'Fresh', value: 'Fresh' },
    { label: 'Slow Moving', value: 'Slow Moving' },
    { label: 'Aging', value: 'Aging' },
    { label: 'At Risk', value: 'At Risk' },
    { label: 'Obsolete', value: 'Obsolete' },
     { label: 'Expired', value: 'Expired' } 
];
@track agingTrendData = [];
shouldRenderAgingTrend = false;
// Sorting
sortBy = 'productName';
sortDirection = 'asc';

// Pagination
pageSize = 10;
currentPage = 1;

@track yearOptions = this.generateYearOptions();
@track selectedYear;
@track isCustomerPattern = false;
@api isCustomerPatternTabOpen;
@track selectedCustomer = { Id: null, Name: null };
@track customerFilter="";
@track selectedCustomerYear;
@track customerYearOptions = [];

@track customerSummary = {
    frequency: null,
    monetary: null,
    recencyDays: null,
    lastOrderDate: null
};

@track showSimulationPanel = false;
@track simulationHasRun = false;
@track simulationInputs = [];
@track simulatedForecast = [];
@track fullHistoricalLabels = [];  
@track fullHistoricalValues = [];
@track futureForecastInputs = [];
@track selectedModel = 'Holt-Winters';

@track modelOptions = [
    { label: 'Holt-Winters (Seasonal)', value: 'Holt-Winters' },
    { label: 'Moving Average', value: 'MOVING_AVERAGE' }
];
@track topReturnedProducts = [];
@track chartTop5Products = [];
returnedProductsColumns = [
    {
        label: 'Product',
        fieldName: 'productName',
        type: 'text',
        wrapText: false,
        initialWidth: 300
    },
    {
        label: 'Units Sold',
        fieldName: 'totalSoldQty',
        type: 'number',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Units Returned',
        fieldName: 'totalReturnedQty',
        type: 'number',
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Return Rate (%)',
        fieldName: 'returnRate',
        type: 'number',
        typeAttributes: {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        },
        cellAttributes: { alignment: 'left' }
    },
    {
        label: 'Top Return Reason',
        fieldName: 'topReturnReason',
        type: 'text',
        wrapText: false
    }
    // ,{
    //     type: 'button',
    //     label: 'Action',
    //     typeAttributes: {
    //         label: 'Review',
    //         name: 'review',
    //         variant: 'brand-outline',
    //         iconName: 'utility:search'
    //     }
    // }
];
returnProductSortBy;
returnProductsSortDirection = 'asc';
RPpageSize = 10;
RPcurrentPage = 1;
RPtotalPages = 0;
@track selectedVersion = {Id: null, Name: null};
@track versionFilter=null;
@track isVersionAvailable = false;
@track isCustomerRAR = false;
@track top5Customers = [];
@track customerReturnData = [];
CRcurrentPage = 1;
CRitemsPerPage = 10;
customerReturnColumns = [
    { label: 'Customer', fieldName: 'customerName', type: 'text' },
    { label: 'Units Returned', fieldName: 'totalReturnedQty', type: 'number' },
    { label: 'Units Ordered', fieldName: 'totalOrderedQty', type: 'number' },
    { label: 'Return Rate (%)', fieldName: 'returnRate', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Top Reason', fieldName: 'topReturnReason', type: 'text' },
    { label: 'Cases', fieldName: 'totalReturnCases', type: 'number' },
    { label: 'Last Return Date', fieldName: 'lastReturnDate', type: 'date-local', typeAttributes: { year: "numeric", month: "short", day: "2-digit" } }
];
//save simulations
@track isSavingSimulation = false;
//simulation planning 
@track isSimulationPlanning=false;

get fiscalYearOptions() {
    const current = new Date().getFullYear();
    return [
        { label: `FY ${current}`, value: current },
        { label: `FY ${current - 1}`, value: current - 1 },
        { label: `FY ${current - 2}`, value: current - 2 }
    ];
}

generateYearOptions() {
        const currentYear = new Date().getFullYear();
        const years = [];
        for (let i = currentYear; i >= currentYear - 5; i--) {
            years.push({ label: i.toString(), value: i });
        }
        this.selectedCustomerYear = parseInt(currentYear,10);
        return years;
}
get totalPages() {
    return this.filteredAgingData ? Math.ceil(this.filteredAgingData.length / this.pageSize) : 1;
}


get isFirstPage() {
    return this.currentPage === 1;
}

get isLastPage() {
    return this.currentPage === this.totalPages;
}

get sortedData() {
    if (!this.filteredAgingData) return [];
    return [...this.filteredAgingData].sort((a, b) => {
        const aVal = a[this.sortBy] ? a[this.sortBy].toString().toLowerCase() : '';
        const bVal = b[this.sortBy] ? b[this.sortBy].toString().toLowerCase() : '';
        const multiplier = this.sortDirection === 'asc' ? 1 : -1;
        return aVal > bVal ? multiplier : aVal < bVal ? -multiplier : 0;
    });
}


get pagedAgingData() {
    if (!this.sortedData || this.sortedData.length === 0) return [];
    const start = (this.currentPage - 1) * this.pageSize;
    const end = start + this.pageSize;
    return this.sortedData.slice(start, end);
}

handleSort(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.currentPage = 1; // reset to page 1 on sort
}

handlePrevPage() {
    if (this.currentPage > 1) this.currentPage--;
}

handleNextPage() {
    if (this.currentPage < this.totalPages) this.currentPage++;
}

// Sorting for Safety Stock Table
sortBySafety = 'productName';
sortDirectionSafety = 'asc';

// Pagination for Safety Stock Table
pageSizeSafety = 10;
currentPageSafety = 1;
//forecast download 
@track customFileName = ''; 
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
get agingTabClass() {
    return this.isAging ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}
handleExpiredToggle(event) {
    this.showExpired = event.target.checked;
    this.applyAgingFilters();
}
handleYearChange(event) {
    this.selectedYear = parseInt(event.detail.value, 10);
    console.log('Selected Year is :', this.selectedYear);
    this.shouldRenderAgingTrend = true;
    this.fetchAgingTrendData();
}
    selectAging() {
        this.clearCharts();
        this.isDemand = false;
        this.isInventoryLevel = false;
        this.isInventory = false;
        this.isSafety = false;
        this.isAging = true;
        this.isCustomerPattern = false;
        this.isSimulationPlanning = false;
        this.isStockMovement = false;
        this.selectedProduct={Id:null,Name:null};
        getDefaultWarehouseByStock({ organisationId: this.organisationId })
        .then(site => {
            if (site) {
                this.selectedWarehouseForAging.Id = site.Id;
                this.selectedWarehouseForAging.Name = site.Name;
                this.isWarehouseSelectedForAging=true;
                this.fetchStockAgingData();
                console.log('loading years ');
                this.loadAvailableYears();  
            } else {
                console.warn('No default warehouse found based on stock');
            }
        })
        .catch(error => {
            console.error('Error fetching default warehouse by stock:', error);
        });
       // this.fetchStockAgingData();
        //this.shouldRenderAgingTrend = true; 
   }

    get demandTabClass() {
        return this.isDemand ?'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }
    get safetyTabClass() {
        return this.isSafety ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }

    get inventoryTabClass() {
        return this.isInventory ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }
    
    get riskAndReturnTabClass() {
        return this.isRiskAndReturn ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }
    get customerRARTabClass() {
        console.log('isCustomerRAR:', this.isCustomerRAR);
        return this.isCustomerRAR ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
    }
    selectDemand() {
        this.clearCharts();
        this.isDemand = true;
        this.isInventory = false;
        this.selectedWarehouse = null;
        this.isCustomerPattern = false;
        this.selectedCustomerYear = null
        this.selectedCustomer = { Id: null, Name: null };
        this.isSimulationPlanning = false;
         getDefaultProductFromOrderItem()
                            .then(product => {  console.log('default product: ',product);
                                if (product) {
                                    this.selectedProduct = {
                                        Id: product.Id,
                                        Name: product.Name
                                    };
                                    this.isDemandProductSel = true;
                                    this.fetchDemandData();
                                    this.fetchTopCustomers();
                                    this.fetchTopProducts();
                                } else {
                                    console.warn('No default product found from OrderItem.');
                                }
                            })
                            .catch(error => {
                                console.error('Error fetching default product from OrderItem:', error);
                            });
        this.custProd = { Id: null, Name: null };
       // this.scheduleChartRender();
        
    }

    selectInventory() {
        this.clearCharts();
        this.isDemand = false;
        this.isSafety = false;
        this.isAging = false;
        this.isCustomerPattern = false;
        this.isSimulationPlanning = false;
        this.isInventoryLevel = false;
        this.isInventory = true;
        this.showallWarehouses = true;
        this.isLoading = true;
        this.isSiteSlectSelected = false;
        this.locationInventoryData = {};
        this.isStockMovement = false;
        this.selectedProduct={Id:null,Name:null};
        getWarehouseInventory({ organisationId: this.organisationId , productId: this.inventoryProduct.Id })
        .then(result => {
            this.inventoryData = result;
            console.log('Fetched Warehouse Inventory Data:', this.inventoryData);
            this.scheduleChartRender();
        })
        .catch(error => {
            console.error('Error fetching warehouse inventory:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Failed to fetch warehouse inventory.',
                    variant: 'error'
                })
            );
        }).finally(() => {
            setTimeout(() => {
                this.isLoading = false;
            }, 500); 
        });
    }
    selectSafety() {
    this.clearCharts();
    this.isDemand = false;
    this.isInventory = false;
    this.isInventoryLevel = false;

    this.isAging = false;
    this.isCustomerPattern = false;this.isSimulationPlanning = false;
    this.selectedProduct = { Id: null, Name: null };
    this.isSafety = true;this.isStockMovement = false;
     // Get default warehouse
    getDefaultWarehouseByStock({ organisationId: this.organisationId })
        .then(site => {
            if (site) {
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
        });
    }

    handleProductSelected(event) {
        this.selectedProduct.Id = event.detail.Id;
        this.selectedProduct.Name = event.detail.Name;
        this.isDemandProductSel = true;
        console.log('Selected product:', this.selectedProduct);
        this.fetchDemandData();
        this.fetchTopCustomers();
        this.fetchTopProducts();
    }
    handleDemandProdRemove(){
        this.selectedProduct = { Id: null, Name: null };
        this.isDemandProductSel = false;
        this.showSimulationPanel = false;
        this.simulationHasRun = false;
        this.simulationInputs = [];
        this.simulatedForecast = [];
        this.simulatedForecast = [];
        console.log('Removed Demand product');
        
    //    window.location.reload();
    }
    handleRemoveInventoryProduct() {
        this.inventoryProduct = { Id: '', Name: '' };
        this.isVersionAvailable = false;
        console.log('Removed Inventory product');
        this.resolveInventoryFetch();
    }

    handleRemoveSite() {
            this.selectedSite = { Id: '', Name: '' };
            console.log('Site removed');
            this.resolveInventoryFetch();
    }

handleINVProductSelected(event) {
    this.inventoryProduct.Id = event.detail.Id;
    this.inventoryProduct.Name = event.detail.Name;

    checkversionAvailability({ productId: this.inventoryProduct.Id })
        .then(result => {
            this.isVersionAvailable = result;
            console.log('Is version available:', this.isVersionAvailable);
            if (this.isVersionAvailable) {
                this.versionFilter =
                    "Active__c = true AND Product__c = '" + this.inventoryProduct.Id + "'";
            } else {
                this.versionFilter =null;
            }

            this.resolveInventoryFetch(); 
        })
        .catch(error => {
            console.error('Error checking version availability:', error);
            this.resolveInventoryFetch(); 
        });
}

handleVersionSelected(event) {
    this.selectedVersion.Id = event.detail.Id;
    this.selectedVersion.Name = event.detail.Name; 
    console.log('Selected Inventory product:', this.selectedVersion.Name);
    this.resolveInventoryFetch();
}
handleVersionRemove() {
    this.selectedVersion = { Id: null, Name: null };
    console.log('Removed Version');
    this.resolveInventoryFetch();
}

handleSiteSelected(event) {
    this.selectedSite.Id = event.detail.Id;
    this.selectedSite.Name = event.detail.Name;
    console.log('Selected Site:', this.selectedSite);
    this.resolveInventoryFetch();
}


    connectedCallback() {
        console.log('organisationId:', this.organisationId);
        console.log('isDemandTabOpen:', this.isDemandTabOpen);
        console.log('isInventoryTabOpen:', this.isInventoryTabOpen);
        console.log('isRiskAndReturnTabOpen:', this.isRiskAndReturnTabOpen);
        this.siteFilter = "Company__c = '" + this.organisationId + "' AND Active__c = true";
        this.customerFilter = "Company__c = '" + this.organisationId + "' AND Active__c = true AND (" +
                      "Account_Type__c = 'Customer' OR " +
                      "Account_Type__c = 'Customer / Partner' OR " +
                      "Account_Type__c = 'Customer / Vendor' OR " +
                      "Account_Type__c = 'Customer / Partner / Vendor')";

        this.isDemand = this.isDemandTabOpen;
        this.isInventory = this.isInventoryTabOpen;
        this.isRiskAndReturn=this.isRiskAndReturnTabOpen;
        if(this.isInventory) this.showallWarehouses = true;
        console.log('isDemand:', this.isDemand, 'isInventory:', this.isInventory);
        if (!this.chartJsInitialized) {
            console.log('Loading Chart.js from:', chartJs);
            loadScript(this, chartJs)
                .then(() => {
                                this.chartJsReady = true;

                getCurrencySymbol()
                    .then(result => {
                        this.currencySymbol = result;
                        console.log('💱 Currency Symbol:', this.currencySymbol);
                    })
                    .catch(error => {
                        console.error('Error fetching currency symbol:', error);
                    });
                    console.log('Chart.js loaded successfully');
                    console.log('Chart.js version:', window.Chart ? window.Chart.version : 'Not available');
                    // if (!window.Chart || window.Chart.version !== '2.9.4') {
                    //     console.error('Incorrect Chart.js version loaded. Expected 2.9.4, got:', window.Chart ? window.Chart.version : 'undefined');
                    // }
                    this.chartJsInitialized = true;
                    // Fetch top products data immediately after Chart.js is loaded
                    if(this.isDemandTabOpen) {
                        if (this.isDemand) {
                        getDefaultProductFromOrderItem()
                            .then(product => { console.log('default product: ',product);
                                if (product) {
                                    this.selectedProduct = {
                                        Id: product.Id,
                                        Name: product.Name
                                    };
                                    this.isDemandProductSel = true;
                                    this.fetchDemandData();
                                    this.fetchTopCustomers();
                                    this.fetchTopProducts();
                                } else {
                                    console.warn('No default product found from OrderItem.');
                                }
                            })
                            .catch(error => {
                                console.error('Error fetching default product from OrderItem:', error);
                            });
                    }

                        //this.fetchTopProducts();
                    }
                    if(this.isInventoryTabOpen) {
                       this.selectInventory();
                    }
                    if(this.isRiskAndReturnTabOpen) {
                        this.selectRiskAndReturn();
                    }
                    
                })
                .catch(error => {
                    console.error('Error loading Chart.js:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Failed to load Chart.js library.',
                            variant: 'error'
                        })
                    );
                });
        }
    }
fetchDemandData() {
    this.isLoading = true;
console.log(' in fetch demand data orgId:', this.organisationId);
    getDemandForecastWithHistory({
         productId: this.selectedProduct.Id,
         modelName: this.selectedModel,
         organisationId: this.organisationId
    })
    .then(result => {
        // 🔹 Extract data
        const historicalLabels = result.historicalMonths;
        const historicalData = result.historicalValues;
        const forecastLabels = result.forecastMonths;
        const forecastData = result.forecastValues;

        // 🔒 Store original reference copies (for resets, simulation)
        this.fullHistoricalLabels = [...historicalLabels];
        this.fullHistoricalValues = [...historicalData];
        this.forecastLabels = [...forecastLabels];
        this.forecastData = [...forecastData];

        // 🔁 Filter only current year data for visible chart + input panel
        const currentYear = new Date().getFullYear();
        this.filteredHistLabels = [];
        this.filteredHistData = [];

        for (let i = 0; i < historicalLabels.length; i++) {
            if (historicalLabels[i].includes(currentYear.toString())) {
                this.filteredHistLabels.push(historicalLabels[i]);
                this.filteredHistData.push(historicalData[i]);
            }
        }

        // 🎯 Draw the original chart (historical + forecast)
        this.renderDemandForecastChart(
            this.fullHistoricalLabels,
            this.fullHistoricalValues,
            this.forecastLabels,
            this.forecastData,
            [] // no simulation yet
        );
    })
    .catch(error => {
        console.error('Error fetching demand forecast:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Failed to fetch demand forecast.',
                variant: 'error'
            })
        );
    })
    .finally(() => {
        this.isLoading = false;
    });
}

// renderDemandForecastChart(histLabels, histData, forecastLabels, forecastData) {
//     const ctx = this.template.querySelector("canvas[data-id='demandByMonth']");
//     if (!ctx || !window.Chart) return;

//     if (this.charts.demandChart) {
//         this.charts.demandChart.destroy();
//     }

//     // ⏱️ Filter only current year's data
//     const currentYear = new Date().getFullYear();
//     const filteredHistLabels = [];
//     const filteredHistData = [];

//     for (let i = 0; i < histLabels.length; i++) {
//         const label = histLabels[i]; // e.g., "Jan 2023"
//         if (label.includes(currentYear.toString())) {
//             filteredHistLabels.push(label);
//             filteredHistData.push(histData[i]);
//         }
//     }

//     // ⏩ Add forecast labels and data
//     const allLabels = [...filteredHistLabels, ...forecastLabels];
//     const forecastPlottedData = new Array(filteredHistLabels.length).fill(null).concat(forecastData);

//     // 🧠 Build chart
//     this.charts.demandChart = new Chart(ctx, {
//         type: 'line',
//         data: {
//             labels: allLabels,
//             datasets: [
//                 {
//                     label: 'Historical Demand',
//                     data: filteredHistData,
//                     borderColor: '#9D53F2',
//                     backgroundColor: 'rgba(157, 83, 242, 0.1)',
//                     // borderColor: '#0070d2',
//                     // backgroundColor: 'rgba(0,112,210,0.1)',
//                     tension: 0.3,
//                     fill: true
//                 },
//                 {
//                     label: 'Forecasted Demand',
//                     data: forecastPlottedData,
//                     borderColor: '#3290ED',
//                     borderDash: [5, 5],
//                     tension: 0.3,
//                     fill: false
//                 }
//             ]
//         },
//         options: {
//             responsive: true,
//             plugins: {
//                 legend: {
//                     display: true,
//                     position: 'bottom'
//                 },
//                 tooltip: {
//                     mode: 'index',
//                     intersect: false
//                 }
//             },
//             scales: {
//                 y: {
//                     beginAtZero: true,
//                     ticks: {
//                         precision: 0
//                     }
//                 }
//             }
//         }
//     });
// }
renderDemandForecastChart(histLabels, histData, forecastLabels, forecastData, simulatedData = []) {
    const currentYear = new Date().getFullYear();
    
    this.filteredHistLabels = [];
    this.filteredHistData = [];
    // Save full history
    this.fullHistoricalLabels = histLabels;
    this.fullHistoricalValues = histData;

    this.forecastLabels = forecastLabels;
    this.forecastData = forecastData;
    for (let i = 0; i < histLabels.length; i++) {
        const label = histLabels[i]; // e.g., "Jan 2024"
        if (label.includes(currentYear.toString())) {
            this.filteredHistLabels.push(label);
            this.filteredHistData.push(histData[i]);
        }
    }

    const ctx = this.template.querySelector("canvas[data-id='demandByMonth']");
    if (!ctx || !window.Chart) return;

    if (this.charts.demandChart) {
        this.charts.demandChart.destroy();
    }

    const allLabels = [...this.filteredHistLabels, ...forecastLabels];
    const forecastPlottedData = new Array(this.filteredHistLabels.length).fill(null).concat(forecastData);
    const simulatedPlottedData = simulatedData.length > 0
        ? new Array(this.filteredHistLabels.length).fill(null).concat(simulatedData)
        : [];

    const datasets = [
        {
            label: 'Historical Demand',
            data: this.filteredHistData,
            borderColor: '#9D53F2',
            backgroundColor: 'rgba(157, 83, 242, 0.1)',
            tension: 0.3,
            fill: true
        },
        {
            label: 'Forecasted Demand',
            data: forecastPlottedData,
            borderColor: '#3290ED',
            borderDash: [5, 5],
            tension: 0.3,
            fill: false
        }
    ];

    if (simulatedPlottedData.length > 0) {
        datasets.push({
            label: 'Simulated Forecast',
            data: simulatedPlottedData,
            borderColor: '#F26522',
            borderDash: [2, 3],
            tension: 0.3,
            fill: false
        });
    }

    this.charts.demandChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: allLabels,
            datasets: datasets
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: true,
                    position: 'bottom'
                },
                tooltip: {
                    mode: 'index',
                    intersect: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        precision: 0
                    }
                }
            }
        }
    });
}


    // fetchDemandData() {
    //      this.isLoading = true;
    //     if (!this.selectedProduct.Id || !this.organisationId) {
    //         console.log('Missing productId or organisationId:', {
    //             productId: this.selectedProduct.Id,
    //             organisationId: this.organisationId
    //         });
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Error',
    //                 message: 'Product ID or Organisation ID is missing.',
    //                 variant: 'error'
    //             })
    //         );
    //         return;
    //     }
    //     console.log('Fetching demand data for product:', this.selectedProduct.Id);
    //     getDemandData({ productId: this.selectedProduct.Id, organisationId: this.organisationId })
    //         .then(result => {
    //             this.demandData = result || {};
    //             console.log('Demand data fetched:', this.demandData);
    //             this.scheduleChartRender();
    //         })
    //         .catch(error => {
    //             console.error('Error fetching demand data:', error);
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: error.body?.message || 'Failed to fetch demand data.',
    //                     variant: 'error'
    //                 })
    //             );
    //         }).finally(() => {
    //         setTimeout(() => {
    //             this.isLoading = false;
    //         }, 500); 
    //     });
    // }
renderTopCustomerPieChart(labels, values) {
    const ctx = this.template.querySelector("canvas[data-id='topCustomerPie']");
    if (!ctx || !window.Chart) return;

    if (this.charts.topCustomerPie) {
        this.charts.topCustomerPie.destroy();
    }

    this.charts.topCustomerPie = new Chart(ctx, {
        type: 'pie',
        data: {
            labels: labels,
            datasets: [{
                data: values,
                backgroundColor: [
                    // '#0070d2', '#ff6384', 
                    '#9D53F2', '#77B5F2',
                    '#3290ED','#26ABA4',
                    //'#36a2eb', '#ffce56',
                    '#8bc34a'
                ]
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}
fetchTopCustomers() {
    if (!this.selectedProduct?.Id) return;

    getTopCustomersForProduct({
        productId: this.selectedProduct.Id,
        topN: 5,
        OrgId: this.organisationId
    })
    .then(result => {
        const labels = result.map(row => row.accountName);
        const values = result.map(row => row.quantity);
        this.renderTopCustomerPieChart(labels, values);
    })
    .catch(error => {
        console.error('Error fetching top customers:', error);
    });
}

    fetchTopProducts() {
        this.isLoading = true;
        if (!this.organisationId) {
            console.log('Missing organisationId for top products');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Organisation ID is missing.',
                    variant: 'error'
                })
            );
            return;
        }
        console.log('Fetching top products for organisation:', this.organisationId);
        getTopProductsByDemand({ organisationId: this.organisationId })
            .then(result => {
                this.topProductsData = result || {};
                console.log('Top products data fetched:', this.topProductsData);
                this.scheduleChartRender();
            })
            .catch(error => {
                console.error('Error fetching top products:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Failed to fetch top products data.',
                        variant: 'error'
                    })
                );
            }).finally(() => {
            setTimeout(() => {
                this.isLoading = false;
            }, 500); 
        });
    }
    fetchWarehouseInventory() {
    this.isLoading = true;
    getWarehouseInventory({
        organisationId: this.organisationId,
        productId: this.inventoryProduct.Id
    })
        .then(result => {
            this.inventoryData = result;
            console.log('Fetched Warehouse Inventory Data:', this.inventoryData);
            this.scheduleChartRender();
        })
        .catch(error => {
            console.error('Error fetching warehouse inventory:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Failed to fetch warehouse inventory.',
                    variant: 'error'
                })
            );
        })
        .finally(() => {
            setTimeout(() => {
                this.isLoading = false;
            }, 500);
        });
    }
    fetchLocationInventory() {
    this.isSiteSlectSelected = true;
    this.showallWarehouses = false;
    this.isLoading = true;
    
    getLocationInventory({
        siteId: this.selectedSite.Id,
        organisationId: this.organisationId,
        productId: this.inventoryProduct.Id
    })
    .then(result => {
        this.locationInventoryData = result;
        console.log('Fetched Location Inventory Data:', this.locationInventoryData);
        this.scheduleChartRender();
    })
    .catch(error => {
        console.error('Error fetching location inventory:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error.body?.message || 'Failed to fetch location inventory.',
                variant: 'error'
            })
        );
    })
    .finally(() => {
        setTimeout(() => {
            this.isLoading = false;
        }, 500);
    });
    }
fetchSafetyStockData() {
    if (!this.selectedWarehouseForSafetyStock) {
        this.showToast('Missing Input', 'Please select a warehouse.', 'warning');
        return;
    }

    this.isLoading = true;

    getStockAlertData({
        siteId: this.selectedWarehouseForSafetyStock.Id,
        location: this.selectedLocation?.Id || null,
        product: this.selectedProduct?.Id || null,
        OrgId: this.organisationId
    })
    .then(result => {
        console.log('⚠️ Raw result from Apex:', JSON.stringify(result));

        let critical = 0, reorder = 0, unconfigured = 0;

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

        // Store alert summary for UI display
        this.alertSummary = { critical, reorder, unconfigured };

        // Priority: Critical + Reorder first
        let criticalOrReorder = this.safetyStockData
            .filter(i => i.badgeLabel === 'Critical' || i.badgeLabel === 'Reorder');

        if (criticalOrReorder.length > 0) {
            this.filteredSafetyStockData = criticalOrReorder.slice(0, 20);
        } else {
            // Fallback to safe/not configured
            this.filteredSafetyStockData = this.safetyStockData
                .filter(i => i.badgeLabel === 'Safe' || i.badgeLabel === 'Not Configured')
                .slice(0, 20);

            this.showToast(
                'No Critical Stock Alerts',
                'No products need reordering now. Displaying safe stock instead.',
                'info'
            );
        }

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
scheduleChartRender() {
        setTimeout(() => {
            this.renderCharts();
        }, 0);
    }
renderCharts() {
        if (!this.chartJsInitialized || (!this.isDemand && !this.isInventory)) {
            console.log('Charts not rendered: isDemand=', this.isDemand, 'chartJsInitialized=', this.chartJsInitialized, 'isInventory=', this.isInventory);
            return;
        }

        console.log('Rendering charts...');
        if (this.isInventory) {

        // Render Inventory by Warehouse Chart
            if (this.inventoryData.warehouseLabels && this.showallWarehouses) {
            console.log('in renderCharts for Inventory');
            const warehouseCanvas = this.template.querySelector('[data-id="inventoryByWarehouse"]');
            if (warehouseCanvas) {
                console.log('Warehouse canvas found');
                try {
                    const ctxWarehouse = warehouseCanvas.getContext('2d');
                    if (ctxWarehouse) {
                        if (this.charts.warehouse) this.charts.warehouse.destroy();
                        this.charts.warehouse = new window.Chart(ctxWarehouse, {
                            type: 'pie',
                            data: {
                                labels: this.inventoryData.warehouseLabels,
                                datasets: [{
                                    label: 'Inventory in Warehouse',
                                    data: this.inventoryData.warehouseInventory,
                                    // backgroundColor: [
                                    //     'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                    //     'rgba(50, 144, 237, 0.5)',   // #3290ED
                                    //     'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                    //     'rgba(38, 38, 170, 0.5)'  
                                    //                                         ],
                                    // borderColor: [
                                    //     'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                    //     'rgba(50, 144, 237, 0.5)',   // #3290ED
                                    //     'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                    //     'rgba(38, 38, 170, 0.5)' 
                                    // ],
                                    backgroundColor:['#9D53F2 ', '#3290ED', '#9c27b0', '#263eabff'],
                                    borderWidth: 1
                                }]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                legend: {
                                    position: 'right'
                                },
                                title: {
                                    display: true,
                                    text: 'Inventory in Warehouse'
                                },
                                animation: {
                                    animateScale: true,
                                    animateRotate: true
                                },
                                plugins:{
                                    tooltip: {
                                    callbacks: {
                                        label: (context) => {
                                            const label = context.label || '';
                                            const value = context.parsed || 0;
                                            return `${label}: ${this.formatLargeNumber(value)}`;
                                        }
                                    }
                                }

                                }
                            }
                        });
                        console.log('Inventory by Warehouse chart rendered');
                    } else {
                        console.error('Failed to get 2D context for inventoryByWarehouse');
                    }
                } catch (error) {
                    console.error('Error rendering Inventory by Warehouse chart:', error);
                }
            } else {
                console.error('Warehouse canvas not found');
            }
        }
            else if (this.locationInventoryData.locationLabels && !this.showallWarehouses && this.isSiteSlectSelected) {
                    console.log('Condition check:', {
                        locationLabels: this.locationInventoryData.locationLabels,
                        showallWarehouses: this.showallWarehouses,
                        isSiteSlectSelected: this.isSiteSlectSelected
                    });
                    console.log('Will show locations for selected site:', this.selectedSite);
                    // Destroy the warehouse chart if it exists
                    if (this.charts.warehouse) {
                        this.charts.warehouse.destroy();
                        this.charts.warehouse = null;
                        console.log('Inventory by Warehouse chart destroyed');
                    }
                    const warehouseCanvas = this.template.querySelector('[data-id="inventoryByWarehouse"]');
                    const locationInventoryCanvas = this.template.querySelector('[data-id="inventoryByLocation"]');
                    if (warehouseCanvas) warehouseCanvas.style.display = 'none';
                    if (locationInventoryCanvas) locationInventoryCanvas.style.display = 'block';
                    if (locationInventoryCanvas) {
                        console.log('Location canvas found');
                        console.log('Location chart data:', {
                            labels: this.locationInventoryData.locationLabels,
                            data: this.locationInventoryData.locationInventory
                        });
                        try {
                            const ctxLocation = locationInventoryCanvas.getContext('2d');
                            if (ctxLocation) {
                                if (this.charts.location) this.charts.location.destroy();
                                this.charts.location = new window.Chart(ctxLocation, {
                                    type: 'bar', 
                                    data: {
                                        labels: this.locationInventoryData.locationLabels,
                                        datasets: [{
                                            label: 'Stock',
                                            data: this.locationInventoryData.locationInventory,
                                        //     backgroundColor: [
                                        // 'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                        // 'rgba(50, 144, 237, 0.5)',   // #3290ED
                                        // 'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                        // 'rgba(38, 38, 170, 0.5)' 
                                        //     ],
                                        //     borderColor: [
                                        // 'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                        // 'rgba(50, 144, 237, 0.5)',   // #3290ED
                                        // 'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                        // 'rgba(38, 38, 170, 0.5)' 
                                        //     ],
                                        backgroundColor:['#9D53F2', '#3290ED', '#9c27b0', '#263eabff'],
                                            borderWidth: 1
                                        }]
                                    },
                                    options: {
                                        responsive: true,
                                        maintainAspectRatio: false,
                                        legend: {
                                            display: true, // Show legend
                                            position: 'top'
                                        },
                                        title: {
                                            display: true,
                                            text: `Inventory by Location for ${this.selectedSite}`
                                        },
                                        scales: {
                                            yAxes: [{
                                                ticks: {
                                                    beginAtZero: true // Start y-axis at 0
                                                }
                                            }]
                                        },
                                        animation: {
                                            duration: 1000 
                                        }
                                    }
                                });
                                console.log('Inventory by Location chart rendered');
                            } else {
                                console.error('Failed to get 2D context for inventoryByLocation');
                            }
                        } catch (error) {
                            console.error('Error rendering Inventory by Location chart:', error);
                        }
                    } else {
                        console.error('locationInventory canvas not found');
                    }
                }

        }else  if(this.isDemand) {
            // Demand by Month Chart (Changed to Line Chart)
            if (this.demandData.monthLabels) {
                const monthCanvas = this.template.querySelector('[data-id="demandByMonth"]');
                if (monthCanvas) {
                    console.log('Month canvas found');
                    try {
                        const ctxMonth = monthCanvas.getContext('2d');
                        if (ctxMonth) {
                            if (this.charts.month) this.charts.month.destroy();
                            this.charts.month = new window.Chart(ctxMonth, {
                                type: 'line',
                                data: {
                                    labels: this.demandData.monthLabels,
                                    datasets: [{
                                        label: 'Demand by Month',
                                        data: this.demandData.monthData,
                                        borderColor: 'rgba(54, 162, 235, 1)',
                                        borderWidth: 2,
                                        fill: false,
                                        tension: 0.1
                                    }]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        yAxes: [{
                                            ticks: {
                                                beginAtZero: true
                                            },
                                            scaleLabel: {
                                                display: true,
                                                labelString: 'Units'
                                            }
                                        }]
                                    }
                                }
                            });
                            console.log('Demand by Month chart rendered');
                        } else {
                            console.error('Failed to get 2D context for demandByMonth');
                        }
                    } catch (error) {
                        console.error('Error rendering Demand by Month chart:', error);
                    }
                } else {
                    console.error('Month canvas not found');
                }
            }

            // Demand by Customer Chart
            if (this.demandData.customerLabels) {
                const customerCanvas = this.template.querySelector('[data-id="demandByCustomer"]');
                if (customerCanvas) {
                    console.log('Customer canvas found');
                    try {
                        const ctxCustomer = customerCanvas.getContext('2d');
                        if (ctxCustomer) {
                            if (this.charts.customer) this.charts.customer.destroy();
                            this.charts.customer = new window.Chart(ctxCustomer, {
                                type: 'pie',
                                data: {
                                    labels: this.demandData.customerLabels,
                                    datasets: [{
                                        label: 'Demand by Customer',
                                        data: this.demandData.customerData,
                                        backgroundColor: [
                                            'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                        'rgba(50, 144, 237, 0.5)',   // #3290ED
                                        'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                        'rgba(38, 38, 170, 0.5)'
                                        ],
                                        borderColor: [
                                    'rgba(157, 83, 242, 0.5)',   // #9D53F2
                                        'rgba(50, 144, 237, 0.5)',   // #3290ED
                                        'rgba(119, 181, 242, 0.5)',  // #77B5F2
                                        'rgba(38, 38, 170, 0.5)'
                                        ],
                                        borderWidth: 1
                                    }]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false
                                }
                            });
                            console.log('Demand by Customer chart rendered');
                        } else {
                            console.error('Failed to get 2D context for demandByCustomer');
                        }
                    } catch (error) {
                        console.error('Error rendering Demand by Customer chart:', error);
                    }
                } else {
                    console.error('Customer canvas not found');
                }
            }

            // Demand by Product Chart (Top 5 Products)
            if (this.topProductsData.topProductLabels) {
                const productCanvas = this.template.querySelector('[data-id="demandByProduct"]');
                if (productCanvas) {
                    console.log('Product canvas found');
                    try {
                        const ctxProduct = productCanvas.getContext('2d');
                        if (ctxProduct) {
                            if (this.charts.product) this.charts.product.destroy();
                            this.charts.product = new window.Chart(ctxProduct, {
                                type: 'bar',
                                data: {
                                    labels: this.topProductsData.topProductLabels,
                                    datasets: [{
                                        label: 'Top 5 Products by Demand',
                                        data: this.topProductsData.topProductData,
                                        backgroundColor: 'rgba(119, 181, 242, 0.5)',
                                        borderColor: 'rgba(119, 181, 242, 1)',
                                        borderWidth: 1
                                    }]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        yAxes: [{
                                            ticks: {
                                                beginAtZero: true
                                            },
                                            scaleLabel: {
                                                display: true,
                                                labelString: 'Units'
                                            }
                                        }]
                                    }
                                }
                            });
                            console.log('Demand by Product chart rendered');
                        } else {
                            console.error('Failed to get 2D context for demandByProduct');
                        }
                    } catch (error) {
                        console.error('Error rendering Demand by Product chart:', error);
                    }
                } else {
                    console.error('Product canvas not found');
                }
            }
        }
    }
    clearCharts() {
    for (const key in this.charts) {
        if (this.charts[key]) {
            this.charts[key].destroy();
            this.charts[key] = null;
        }
    }
    }
// renderSafetyStockChart() {
//     const canvas = this.template.querySelector('[data-id="safetyStockChart"]');

//     // Always clear previous chart
//     if (this.charts.safety) {
//         this.charts.safety.destroy();
//         this.charts.safety = null;
//     }

//     // If no canvas or no data, exit after clearing
//     if (!canvas) return;

//     const ctx = canvas.getContext('2d');

//     // If no data, render placeholder chart or message
//     if (!this.filteredSafetyStockData.length) {
//         // Optional: Draw 'No data' text on canvas
//         ctx.clearRect(0, 0, canvas.width, canvas.height);
//         ctx.font = '16px Arial';
//         ctx.fillStyle = '#666';
//         ctx.fillText('No stock data to display.', 20, 40);
//         return;
//     }

//     // Prepare data
//     const labels = this.filteredSafetyStockData.map(i => i.productName);
//     const currentStock = this.filteredSafetyStockData.map(i => i.currentStock);
//     const reorderLevel = this.filteredSafetyStockData.map(i => i.reorderLevel);
//     const safetyStock = this.filteredSafetyStockData.map(i => i.safetyStock);
//     const currentColors = this.filteredSafetyStockData.map(i =>
//         i.currentStock < i.safetyStock ? 'rgba(52, 152, 219, 0.7)' :
//         i.currentStock < i.reorderLevel ? 'rgba(243, 156, 18, 0.7)' :
//         'rgba(46, 204, 113, 0.7)'
//     );

//     // Render new chart
//     this.charts.safety = new window.Chart(ctx, {
//         type: 'bar',
//         data: {
//             labels,
//             datasets: [
//                 {
//                     label: 'Current Stock',
//                     data: currentStock,
//                     backgroundColor: currentColors
//                 },
//                 {
//                     label: 'Reorder Level',
//                     data: reorderLevel,
//                     backgroundColor: 'rgba(52, 152, 219, 0.7)'
//                 },
//                 {
//                     label: 'Safety Stock',
//                     data: safetyStock,
//                     backgroundColor: 'rgba(243, 156, 18, 0.7)'
//                 }
//             ]
//         },
//         options: {
//             responsive: true,
//             maintainAspectRatio: false,
//             barThickness: 30,
//             scales: {
//                 xAxes: [{
//                     stacked: false,
//                     barPercentage: 0.6
//                 }],
//                 yAxes: [{
//                     stacked: false,
//                     ticks: {
//                         beginAtZero: true
//                     }
//                 }]
//             },
//             title: {
//                 display: true,
//                 text: 'Filtered Stock Status'
//             }
//         }
//     });
// }
renderSafetyStockChart() {
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
                    backgroundColor: currentColors
                },
                {
                    label: 'Reorder Level',
                    data: reorderLevel,
                    backgroundColor: 'rgba(52, 152, 219, 0.5)' // Light Blue
                },
                {
                    label: 'Safety Stock',
                    data: safetyStock,
                    backgroundColor: 'rgba(155, 89, 182, 0.5)' // Purple-ish
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
                    text: 'Top 20 Stock Levels Needing Attention',
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




resolveInventoryFetch() {
    this.isLoading = true;

    if (this.selectedSite?.Id) {
        this.isSiteSlectSelected = true;
        this.showallWarehouses = false;
        console.log('Fetching inventory for site:', this.selectedSite.Id, 'organisationId:', this.organisationId, 'productId:', this.inventoryProduct.Id, 'version:', this.selectedVersion.Id);
        getLocationInventory({
            siteId: this.selectedSite.Id,
            organisationId: this.organisationId,
            productId: this.inventoryProduct.Id || '',
            version: this.selectedVersion.Id || null
        })
        .then(result => {
            this.locationInventoryData = result;
            console.log('Fetched Location Inventory Data:', this.locationInventoryData);
             const hasStock = result?.locationInventoryData?.some(qty => qty > 0); console.log('hasStock:', hasStock);
            //  if (this.inventoryProduct && this.inventoryProduct.Id && this.inventoryProduct.Id.trim() !== '') {
            //     if (!hasStock) {
            //         this.showToast('Notice', 'No stock available for this product in this warehouse.', 'info');
            //         return;
            //     }
            // }
            this.scheduleChartRender();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch location inventory.', 'error');
        })
        .finally(() => {
            setTimeout(() => {
                this.isLoading = false;
            }, 500);
        });
    } else {
        this.isSiteSlectSelected = false;
        this.showallWarehouses = true;

        getWarehouseInventory({
            organisationId: this.organisationId,
            productId: this.inventoryProduct.Id || '',
            version: this.selectedVersion.Id || null
        })
        .then(result => {
            this.inventoryData = result;
             const hasStock = result?.inventoryData?.some(qty => qty > 0);
             console.log('Fetched Warehouse Inventory Data:', this.inventoryData);
            //  if (this.inventoryProduct && this.inventoryProduct.Id && this.inventoryProduct.Id.trim() !== '') {
            // if (!hasStock) {
            //     this.showToast('Notice', 'No stock available for this product in any warehouse.', 'info');
            //     return;
            // }}
            this.scheduleChartRender();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Failed to fetch warehouse inventory.', 'error');
        })
        .finally(() => {
            setTimeout(() => {
                this.isLoading = false;
            }, 500);
        });
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
handleWarehouseSelectForAging(event){
    
    this.isWarehouseSelectedForAging=true;
    this.selectedWarehouseForAging = {Id:event.detail.Id,Name:event.detail.Name};
    // console.log('Selected Warehouse for Aging:', this.selectedWarehouseForAging);
    this.fetchStockAgingData();
    console.log('loading years ');
    this.loadAvailableYears(); 
    }
handleWarehouseRemoveAging(){
        this.isWarehouseSelectedForAging=false;
        this.selectedWarehouseForAging = {Id:null,Name:null};
        this.stockAgingData=[];
        this.filteredAgingData=[];
        //window.location.reload();
           // Destroy the trend chart if it exists
    if (this.charts?.agingTrend) {
        this.charts.agingTrend.destroy();
        this.charts.agingTrend = null;
    }
}
// handleWarehouseChangeAging(event){
//     console.log('on change ');
//     this.selectedWarehouseForAging = {Id:event.detail.Id,Name:event.detail.Name};
//     this.fetchStockAgingData();
//     console.log('loading years ');
//     this.loadAvailableYears(); 
// }
fetchStockAgingData() {
    this.isLoading = true;
    console.log('Fetching stock aging data for product:', this.selectedProduct.Id, 'and warehouse:', this.selectedWarehouseForAging.Name, 'organisationId:', this.organisationId);
    getDynamicStockAgingData({ siteId: this.selectedWarehouseForAging.Id, orgId: this.organisationId ,prodId : this.selectedProduct.Id})
        .then(result => {
            console.log('Sucess getDynamicStockAgingData')
            const today = new Date();
            this.stockAgingData = result.map((item, idx) => {
                const receivedDate = new Date(item.receivedDate);
                const ageInDays = Math.floor((today - receivedDate) / (1000 * 60 * 60 * 24));
                let bucket = '', status = '', statusClass = '';
                if (item.isExpired) {
                bucket = 'Expired';
                status = 'Expired';
                statusClass = 'badge-flat-purple';
                } else if (ageInDays < 30)       { bucket = '<30d';       status = 'Fresh';        statusClass = 'badge-blue-m'; }
                else if (ageInDays < 90)  { bucket = '30–90d';     status = 'Slow Moving';  statusClass = 'badge-flat-green'; }
                else if (ageInDays < 180) { bucket = '90–180d';    status = 'Aging';        statusClass = 'badge-flat-purple'; }
                else if (ageInDays < 365) { bucket = '180–365d';   status = 'At Risk';      statusClass = 'badge-flat-gray'; }
                else                      { bucket = '>365d';      status = 'Obsolete';     statusClass = 'badge-flat-red'; }

                return {
                    id: idx.toString(),
                    productId: item.productId,
                    productName: item.productName,
                    quantity: item.quantity,
                    receivedDate: item.receivedDate,
                    ageInDays,
                    bucket,
                    status,
                    statusClass
                };
            });

            this.prepareAgingFilters();
            this.applyAgingFilters();
             
        })
        .catch(error => {
            console.error('Error fetching stock aging data:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
}


prepareAgingFilters() {
    console.log('Preparing aging filters');
    const products = new Set(this.stockAgingData.map(item => item.productId));
    this.productOptionsAging = [...products].map(p => ({ label: p, value: p }));
}

applyAgingFilters() {
    console.log('Applying filters aging');
   this.filteredAgingData = this.stockAgingData.filter(item =>
        (!this.agingFilters.product || item.productId === this.agingFilters.product) &&
        (!this.agingFilters.bucket || item.bucket === this.agingFilters.bucket) &&
        (!this.agingFilters.status || item.status === this.agingFilters.status) &&
         (this.showExpired || item.status !== 'Expired') 
    );

    this.renderStockAgingChart();
}
handleAgingProductSelected(event) {
    this.selectedProduct.Id = event.detail.Id;
    this.selectedProduct.Name = event.detail.Name;
    this.fetchStockAgingData();
    this.fetchAgingTrendData();
}
handleAgingProductRemove(){
    this.selectedProduct={Id:null,Name:null};
    this.fetchStockAgingData();
    this.fetchAgingTrendData();
}
handleAgingProductChange(event) {
    this.agingFilters.product = event.detail.value;
    this.applyAgingFilters();
}
handleAgingBucketChange(event) {
    this.agingFilters.bucket = event.detail.value;
    this.applyAgingFilters();
}
handleAgingStatusChange(event) {
    this.agingFilters.status = event.detail.value;
    this.applyAgingFilters();
}

renderStockAgingChart() {
    const canvas = this.template.querySelector('[data-id="stockAgingChart"]');
     // Always clear previous chart
    if (this.charts.aging) {
        this.charts.aging.destroy();
        this.charts.aging = null;
    }

    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (this.charts.aging) this.charts.aging.destroy();

    const bucketCounts = { '<30d': 0, '30–90d': 0, '90–180d': 0, '180–365d': 0, '>365d': 0 , 'Expired': 0 };
    const dataSource = this.filteredAgingData;

    dataSource.forEach(item => bucketCounts[item.bucket] += item.quantity);

    this.charts.aging = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: Object.keys(bucketCounts),
            datasets: [{
                label: 'Qty by Aging Bucket',
                data: Object.values(bucketCounts),
                backgroundColor:['rgba(46, 204, 113, 0.7)', // replaces '#28a745'
                                    'rgba(52, 152, 219, 0.7)', // replaces '#ffc107'
                                    '#9b59b6', // replaces '#fd7e14'
                                    'rgba(127, 140, 141, 0.7)', // replaces '#ff6384'
                                    'rgba(231, 76, 60, 0.7)'
                                    ]
                // backgroundColor: ['#28a745', '#ffc107', '#fd7e14', '#ff6384', '#6c757d']
            }]
        },
        options: { 
            responsive: true, maintainAspectRatio: false,
             plugins: {
                        legend: { position: 'bottom' },
                        tooltip: {
                            mode: 'index',
                            intersect: false
                        }
                    },
         }
    });
}
clearAgingFilters() {
    this.agingFilters = { product: '', bucket: '', status: '' };
    this.applyAgingFilters();
}
fetchAgingTrendData() {
    this.isLoading = true;
    console.log('fetching aging trend data ');
    console.log('siteId:', this.selectedWarehouseForAging.Name);
    console.log('orgId:', this.organisationId);
    console.log('prodId:', this.selectedProduct.Id);
    console.log('yearStr:', this.selectedYear);
    getAgingTrendData({
        siteId: this.selectedWarehouseForAging.Id,
        orgId: this.organisationId,
        prodId: this.selectedProduct.Id || null,
        yearStr: this.selectedYear
    })
    .then(result => {
        console.log('Fetched Aging Trend Data:', result);
        this.agingTrendData = result;
        this.renderAgingTrendChart();
    })
    .catch(error => {
        console.error('Error fetching trend data', error);
    })
    .finally(() => {
        this.isLoading = false;
    });
}
renderAgingTrendChart() {
    console.log('in renderAging');
    const canvas = this.template.querySelector('[data-id="agingTrendChart"]');
    if (!canvas) {
        console.warn('Aging Trend canvas not found.');
        return;
    }

    const ctx = canvas.getContext('2d');

    if (!this.charts) this.charts = {};
    if (this.charts.agingTrend) this.charts.agingTrend.destroy();

    const labels = this.agingTrendData.map(row => row.month);
    const datasetKeys = ['<30d', '30–90d', '90–180d', '180–365d', '>365d'];

    const colors = {
        '<30d': 'rgba(46, 204, 113, 0.7)', // replaces '#28a745'
        '30–90d': 'rgba(52, 152, 219, 0.7)', // replaces '#ffc107'
        '90–180d': '#9b59b6', // replaces '#fd7e14'
        '180–365d': 'rgba(127, 140, 141, 0.7)',  // replaces '#ff6384'
        '>365d': 'rgba(231, 76, 60, 0.7)'
    };

    const datasets = datasetKeys.map(bucket => ({
        label: bucket,
        data: this.agingTrendData.map(row => row[bucket]),
        backgroundColor: colors[bucket],
        fill: true,
        tension: 0.3
    }));

    this.charts.agingTrend = new window.Chart(ctx, {
        type: 'line',
        data: {
            labels,
            datasets
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: { mode: 'index', intersect: false },
            stacked: true,
            plugins: {
                title: {
                    display: true,
                    text: 'Inventory Aging Trend (Monthly)'
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    stacked: true
                },
                x: {
                    stacked: true
                }
            }
        }
    });
}

 loadAvailableYears() {
        try {
            const currentYear = new Date().getFullYear();
            const numYearsToShow = 5;
        
            const years = [];
            for (let i = 0; i < numYearsToShow; i++) {
                years.push(currentYear - i);
            }
        
           // this.yearOptions = years;
            this.selectedYear = years[0];
            console.log('yearOptions:', JSON.stringify(this.yearOptions));
            console.log('selectedYear:', this.selectedYear);
            if (this.selectedWarehouseForAging.Id && this.organisationId) {
                this.fetchAgingTrendData();
            }
        } catch (error) {
            console.error('❌ Error in loadAvailableYears():', error);
        }
    }
    // customer trend code statrs here 
get customerPatternTabClass() {
    return this.isCustomerPattern ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}

selectCustomerPattern() {
    this.clearCharts();
    this.isDemand = false;
    this.isInventory = false;
    this.isSafety = false;
    this.isAging = false;
    this.selectedProduct = {Id:null,Name:null};
    this.isCustomerPattern = true;
    this.isSimulationPlanning = false;
    getDefaultCustomerFromOrders()
        .then(customer => {
            if (customer) {
                this.selectedCustomer = {
                    Id: customer.Id,
                    Name: customer.Name
                };
                this.isCustomerSelected = true
                this.customerYearOptions = this.generateYearOptions();
                this.isCustomerSelected = true;//duplicate
                this.fetchCustomerPatternTrend(); 
                
            } else {
                console.warn('No default customer found.');
            }
        })
        .catch(error => {
            console.error('Error fetching default customer:', error);
        });
}
handleCustomerSelected(event) {
    console.log('Inside customer select');
    this.selectedCustomer.Id = event.detail.Id;
    this.selectedCustomer.Name = event.detail.Name;
    this.customerYearOptions = this.generateYearOptions();
    this.fetchCustomerPatternTrend();
    this.isCustomerSelected = true;
    //this.selectedCustomerYear = new Date().getFullYear().toString();
}
handleCustProdRemove(){
    this.custProd={Id:null,Name:null};
    this.fetchCustomerPatternTrend();
}
handleCustomerYearChange(event) {
    this.selectedCustomerYear =  parseInt(event.detail.value, 10);
    this.fetchCustomerPatternTrend();
}

handleCustomerPatternProductSelected(event) {
    this.custProd.Id = event.detail.Id;
    this.custProd.Name = event.detail.Name;
    this.fetchCustomerPatternTrend();
}
// fetchCustomerPatternTrend() {
//     if (!this.selectedCustomer.Id && !this.selectedProduct.Id) return;
//     console.log('selectedCustomer:', this.selectedCustomer , 'selectedProduct:', this.selectedProduct, 'organisationId:', this.organisationId , 'selectedYear:', this.selectedCustomerYear);
//     this.isLoading = true;
//     getCustomerOrderTrend({
//         customerId: this.selectedCustomer.Id,
//         productId: this.selectedProduct.Id,
//         orgId: this.organisationId,
//         yearStr: this.selectedCustomerYear
//     })
//         .then(result => {
//             this.customerPatternData = result;
//             this.renderCustomerPatternChart();
//         })
//         .catch(error => {
//             console.error('Error fetching customer pattern trend:', error);
//         })
//         .finally(() => {
//             this.isLoading = false;
//         });
// }

fetchCustomerPatternTrend() {
    console.log('in fetchcustomerpatterntrend');
    //if (!this.selectedCustomer.Id && !this.selectedProduct.Id) return;
    if (!this.selectedCustomer?.Id) return;
    console.log('not null customer');
    this.isLoading = true;
    console.log('Calling apex methods');
    Promise.all([
        getCustomerOrderTrend({
            customerId: this.selectedCustomer.Id,
            productId: this.custProd.Id,
            orgId: this.organisationId,
            yearStr: this.selectedCustomerYear
        })
        ,
        getCustomerSummary({
            customerId: this.selectedCustomer.Id,
            productId: this.custProd.Id,
            yearStr: this.selectedCustomerYear,
            orgId: this.organisationId
        })
    ])
    .then(([trendData, summaryData]) => {
        console.log('IN sucess ');
        this.customerPatternData = trendData;
        console.log('customerPatternData trend ',this.customerPatternData);
        this.customerSummary = summaryData;
        this.renderCustomerPatternChart();
    })
    .catch(error => {
        console.error('Error fetching trend or summary:', error);
    })
    .finally(() => {
        this.isLoading = false;
    });
}
handleCustomerRemove(){
    this.selectedCustomer={Id:null,Name:null}
    this.customerYearOptions = [];
    this.isCustomerSelected = false;
    this.customerSummary = {
    frequency: null,
    monetary: null,
    recencyDays: null,
    lastOrderDate: null
};   
}

renderCustomerPatternChart() {
    console.log('In customer pattern chart ');
    const canvas = this.template.querySelector('[data-id="customerPatternChart"]');
    if (!canvas || !this.customerPatternData) return;
    console.log('customerPatternData ',this.customerPatternData);
    const ctx = canvas.getContext('2d');
    if (this.charts.customerPattern) this.charts.customerPattern.destroy();

    this.charts.customerPattern = new window.Chart(ctx, {
        type: 'line',
        data: {
            labels: this.customerPatternData.months,
            datasets: [{
                label: 'Order Quantity',
                data: this.customerPatternData.quantities,
                fill: false,
                borderColor: '#77B5F2', //'rgba(54, 162, 235, 1)',
                tension: 0.3
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Customer Order Pattern Over Time'
                },
                    legend: { position: 'bottom' },
                    tooltip: {
                            mode: 'index',
                            intersect: false
                    }
            }
        }
    });
}
formatLargeNumber(value, digits = 1) {
    if (value === null || value === undefined || isNaN(value)) return '';

    const abs = Math.abs(value);
    const units = [
        { value: 1_000_000_000, symbol: 'B' },
        { value: 1_000_000, symbol: 'M' },
        { value: 1_000, symbol: 'K' }
    ];

    for (let unit of units) {
        if (abs >= unit.value) {
            return (value / unit.value).toFixed(digits) + unit.symbol;
        }
    }

    return value.toLocaleString();
}

// get formattedMonetaryValue() {
//     return this.customerSummary.monetary != null
//         ? new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(this.customerSummary.monetary)
//         : '-';
// }

// get formattedLastOrderDate() {
//     return this.customerSummary.lastOrderDate
//         ? new Date(this.customerSummary.lastOrderDate).toLocaleDateString()
//         : '-';
// }
// toggleSimulationPanel() {
//     this.showSimulationPanel = !this.showSimulationPanel;

//     if (this.showSimulationPanel && !this.simulationHasRun) {
//         const currentYear = new Date().getFullYear();

//         // Setup simulationInputs (current year only)
//         this.simulationInputs = this.fullHistoricalLabels.map((label, i) => {
//             if (label.includes(currentYear.toString())) {
//                 return { label, value: this.fullHistoricalValues[i] };
//             }
//             return null;
//         }).filter(Boolean);

//         // Setup forecast inputs (first 3 forecast months)
//         this.futureForecastInputs = this.forecastLabels.slice(0, 3).map(label => ({
//             label,
//             value: '' // empty initially
//         }));
//     }
// }

handleFutureForecastChange(event) {
    const label = event.target.dataset.label;
    const newVal = parseFloat(event.target.value) || 0;

    this.futureForecastInputs = this.futureForecastInputs.map(row => {
        return row.label === label ? { ...row, value: newVal } : row;
    });
}



handleSimInputChange(event) {
    const label = event.target.dataset.label;
    const newVal = parseFloat(event.target.value) || 0;

    this.simulationInputs = this.simulationInputs.map(row => {
        return row.label === label ? { ...row, value: newVal } : row;
    });
}
handleSimulateForecast() {
    const baseHistoricalLabels = [...this.fullHistoricalLabels];
    const baseHistoricalValues = [...this.fullHistoricalValues];

    //  Override historical inputs only for current year
    const simOverrideMap = new Map(
        this.simulationInputs.map(row => [row.label, parseFloat(row.value) || 0])
    );

    const patchedHistorical = baseHistoricalLabels.map((label, i) => {
        return simOverrideMap.has(label)
            ? simOverrideMap.get(label)
            : baseHistoricalValues[i];
    });

    //  Append manual future overrides
    const futureOverrideMap = new Map();
    const manualForecastInputs = [];

    this.futureForecastInputs.forEach(row => {
        const val = parseFloat(row.value);
        if (!isNaN(val)) {
            futureOverrideMap.set(row.label, val);
            manualForecastInputs.push(val);
        }
    });

    const simulationSeries = [...patchedHistorical, ...manualForecastInputs];

   
    generateForecastFromHistorical({
        historicalValues: simulationSeries,
        modelName: this.selectedModel
    })
    .then(result => {
       
        const finalSimulatedForecast = result.forecastMonths.map((label, i) =>
            futureOverrideMap.has(label)
                ? futureOverrideMap.get(label)
                : result.forecastValues[i]
        );
        this.simulatedForecast = finalSimulatedForecast;// added for just to store and export
        this.renderDemandForecastChart(
            this.fullHistoricalLabels,       
            this.fullHistoricalValues,     
            this.forecastLabels,           
            this.forecastData,             
            finalSimulatedForecast          
        );
        this.simulationHasRun = true;
        this.showSimulationPanel = false; 

    })
    .catch(error => {
        console.error('Simulation failed:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Simulation Failed',
                message: error.body?.message || 'Something went wrong during simulation.',
                variant: 'error'
            })
        );
    });
}


// resetSimulation() {
//     this.simulationInputs = [];
//     this.futureForecastInputs = [];
//     this.simulatedForecast = [];
//     this.simulatedForecastMonths = [];
//     this.customFileName = '';
//     // 🔒 Restore filtered current-year historical data
//     const currentYear = new Date().getFullYear();
//     this.filteredHistLabels = [];
//     this.filteredHistData = [];

//     for (let i = 0; i < this.fullHistoricalLabels.length; i++) {
//         const label = this.fullHistoricalLabels[i];
//         const value = this.fullHistoricalValues[i];

//         if (label.includes(currentYear.toString())) {
//             this.filteredHistLabels.push(label);
//             this.filteredHistData.push(value);
//         }
//     }

//     // 🚫 Hide simulation panel
//     this.showSimulationPanel = false;

//     // 📊 Re-render chart with original data only
//     this.renderDemandForecastChart(
//         this.fullHistoricalLabels,
//         this.fullHistoricalValues,
//         this.forecastLabels,
//         this.forecastData,
//         [] // No simulated forecast
//     );
//     this.simulationHasRun = false;
//     this.showSimulationPanel = false;

// }

handleModelChange(event) {
    this.selectedModel = event.detail.value;
    this.fetchDemandData();
}
downloadForecastAsCSV() {
    console.log('⬇️ Starting CSV download...');

    if (!Array.isArray(this.simulatedForecast) || this.simulatedForecast.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Simulation Found',
                message: 'Please run a simulation before downloading.',
                variant: 'warning'
            })
        );
        return;
    }

    let csv = 'Month,Original Forecast,Manual Override,Simulated Forecast,Difference\n';

    const forecastMap = new Map();
    this.forecastLabels.forEach((label, i) => {
        forecastMap.set(label, this.forecastData[i]);
    });

    const overrideMap = new Map();
    this.futureForecastInputs.forEach(input => {
        const parsed = parseFloat(input.value);
        if (!isNaN(parsed)) {
            overrideMap.set(input.label, parsed);
        }
    });

    this.simulatedForecast.forEach((simValue, i) => {
        const month = this.forecastLabels[i];
        const base = forecastMap.get(month) || 0;
        const manual = overrideMap.has(month) ? overrideMap.get(month) : '';
        const diff = (simValue - base).toFixed(2);
        csv += `${month},${base},${manual},${simValue},${diff}\n`;
    });

    console.log('📄 Final CSV content:\n' + csv);

    // ✅ Encode CSV to base64-safe URI
    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);

    const baseName = this.customFileName?.trim();
    const safeName = baseName
        ? `${baseName}.csv`
        : (this.selectedProduct?.Name
            ? `SimulatedForecast_${this.selectedProduct.Name}.csv`
            : 'SimulatedForecast.csv');

    link.setAttribute('download', safeName);

   // link.setAttribute('download', fileName);
    document.body.appendChild(link);

    setTimeout(() => {
        link.click();
        document.body.removeChild(link);
        console.log('✅ Download triggered using data URI');
    }, 50);
}
downloadAgingAsCSV() {
    console.log('⬇️ Starting Stock Aging CSV download...');

    if (!Array.isArray(this.filteredAgingData) || this.filteredAgingData.length === 0) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Aging Data Found',
                message: 'Please load or filter aging data before downloading.',
                variant: 'warning'
            })
        );
        return;
    }

    const cleanText = (value) => {
        const text = value != null ? String(value) : '';
        return text
            .replace(/\u2013/g, '-')        // en-dash → hyphen
            .replace(/\u2014/g, '-')        // em-dash → hyphen
            .replace(/[\u2018\u2019]/g, "'") // smart single quotes
            .replace(/[\u201C\u201D]/g, '"') // smart double quotes
            .replace(/[\r\n]+/g, ' ')        // remove newlines
            .trim();
    };

    // Define header
    let csv = 'Product,Quantity,Received Date,Age (Days),Bucket,Status\n';

    // Loop and add rows
    this.filteredAgingData.forEach(item => {
        const product = cleanText(item.productName);
        const quantity = cleanText(item.quantity);
        const receivedDate = cleanText(item.receivedDate);
        const age = cleanText(item.ageInDays);
        const bucket = cleanText(item.bucket);
        const status = cleanText(item.status);

        csv += `${product},${quantity},${receivedDate},${age},${bucket},${status}\n`;
    });

    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', 'StockAgingReport.csv');
    document.body.appendChild(link);

    setTimeout(() => {
        link.click();
        document.body.removeChild(link);
        console.log('✅ Aging data CSV download triggered.');
    }, 50);
}

handleFileNameChange(event) {
    this.customFileName = event.target.value;
}
handleCreatePO() {
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
selectRiskAndReturn(){
    console.log('inside selectRiskAndReturn');
    this.clearCharts();
    this.isDemand = false;
    this.isInventory = false;
    this.isSafety = false;
    this.isAging = false;
    this.isRiskAndReturn = true;
    this.isCustomerRAR = false;
    console.log('calling fetchReturnInsights');
    // this.fetchReturnInsights();
    // console.log('calling fetchReturnReasonDistribution');
     this.fetchReturnReasonDistribution();
    this.fetchAllReturnedProducts();
    console.log('calling to fetchreturntrend');
    this.fetchReturnRateTrend();

}
// fetchReturnInsights() { console.log('in fetchReturnInsights');
//     this.isLoading = true;
//     getTopReturnedProducts({ organisationId: this.organisationId, limitCount: 5 })
//         .then(result => {
//             if (result && result.length > 0) {
//                 const barLabels = result.map(p => p.productName);
//                 const barData = result.map(p => p.totalReturnedQty);
//                 this.renderBarChart(barLabels, barData);
//             }
//         })
//         .catch(error => {
//             console.error('Error fetching return insights:', error);
//         }).finally(() => {
//             this.isLoading = false;
//         }
//     );
// }

fetchReturnReasonDistribution() {   console.log('in fetchReturnReasonDistribution');
    this.isLoading = true;
    getReturnReasonDistribution({ organisationId: this.organisationId })
        .then(data => {
            if (data && data.length > 0) {
                const pieLabels = data.map(item => item.reason || 'Unknown');
                const pieData = data.map(item => item.totalQty);

                this.renderReturnReasonDonut(pieLabels, pieData);
            }
        })
        .catch(error => {
            console.error('Error fetching return reason distribution:', error);
        }).finally(() => {
            this.isLoading = false;
        }
    );
}

renderTopReturnBarChart(labels, data) {
    const ctx = this.template.querySelector("canvas[data-id='returnBar']");
    if (!ctx || !window.Chart) return;

    if (this.charts.returnBarChart) {
        this.charts.returnBarChart.destroy();
    }

    this.charts.returnBarChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Units Returned',
                data: data,
                backgroundColor: '#c1dbf8'
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false },
                tooltip: { mode: 'index', intersect: false }
            },
            scales: {
                y: { beginAtZero: true }
            }
        }
    });
}
renderReturnReasonDonut(labels, data) {
    const ctx = this.template.querySelector("canvas[data-id='returnPie']");
    if (!ctx || !window.Chart) return;

    if (this.charts.returnPieChart) {
        this.charts.returnPieChart.destroy();
    }

    this.charts.returnPieChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                label: 'Return Reasons',
                data: data,
                backgroundColor: [
                    '#9b59b6', '#3498db', '#FFCE56', '#85db9a', '#e67f78', '#6652e3ff', '#00ACC1'
                ]
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' },
                tooltip: { mode: 'index', intersect: false }
            }
        }
    });
}
fetchReturnRateTrend() {
    getReturnRateTrend({ organisationId: this.organisationId })
        .then(data => {
            console.log('📊 Return Rate Trend Data:', JSON.stringify(data));

            if (data && data.length > 0) {
                console.log('length of data ',data.length);
                const labels = data.map(d => d.monthLabel);console.log('labels ',labels);
                const returnRates = data.map(d => {
                    const rate = Number(d.returnRate);
                    return isNaN(rate) ? 0 : rate.toFixed(2);
                });

                setTimeout(() => {
                    console.log('call to render chart return trend');
                    this.renderReturnTrendChart(labels, returnRates);
                }, 0);
            }
        })
        .catch(error => {
            console.error('❌ Error fetching return rate trend:', error);
        });
}

renderReturnTrendChart(labels, data) {
    console.log('in return render chart');
    const ctx = this.template.querySelector("canvas[data-id='returnRateTrend']");
    if (!ctx || !window.Chart) return;

    if (this.charts?.returnTrendChart) {
        this.charts.returnTrendChart.destroy();
    }

    this.charts = this.charts || {};
    this.charts.returnTrendChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Return Rate (%)',
                data: data,
                borderColor: '#9a57f2',
                backgroundColor: '#f5edfe',
                tension: 0.3,
                fill: false,
                pointRadius: 4,
                pointHoverRadius: 6
            }]
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
                    title: {
                        display: true,
                        text: 'Return Rate (%)'
                    }
                }
            }
        }
    });
}

    fetchAllReturnedProducts() {
    console.log('AZ in fetchAllReturnedProducts');
    
     getTopReturnedProducts({ organisationId: this.organisationId ,limitCount: 2000})
         .then(data => {
            console.log('AZ logged',JSON.stringify(data));
            
            if (data && data.length > 0) {
                console.log('Fetched returned products:', data.length);
                console.log('data ',data);
                // 🔸 All products → used in table
                this.topReturnedProducts = data;
                 this.RPtotalPages = Math.ceil(data.length / this.RPpageSize);
                 this.setPageData();
                // 🔸 Top 5 → used in bar chart
                this.chartTop5Products = [...data].slice(0, 5);

                // Render bar chart
                const labels = this.chartTop5Products.map(p => p.productName);
                const returnQtys = this.chartTop5Products.map(p => p.totalReturnedQty);
                setTimeout(() => {
                    this.renderTopReturnBarChart(labels, returnQtys);
                });
            }
        })
        .catch(error => {
            console.error('❌ Error fetching returned products:', error);
        });
    }
    




setPageData() {
    const start = (this.RPcurrentPage - 1) * this.RPpageSize;
    const end = start + this.RPpageSize;
    this.pagedReturnedProducts = this.topReturnedProducts.slice(start, end);
}
handleRPPreviousPage() {
    if (this.RPcurrentPage > 1) {
        this.RPcurrentPage--;
        this.setPageData();
    }
}

handleRPNextPage() {
    if (this.RPcurrentPage < this.RPtotalPages) {
        this.RPcurrentPage++;
        this.setPageData();
    }
}
get isRPFirstPage() {
    return this.RPcurrentPage === 1;
}

get isRPLastPage() {
    return this.RPcurrentPage === this.RPtotalPages;
}
// customer return insight 
selectCustomerRAR(){
    this.clearCharts();
    this.isDemand = false;
    this.isInventory = false;
    this.isSafety = false;
    this.isAging = false;
    this.isRiskAndReturn = false;
    this.isCustomerRAR = true;
    this.fetchTopReturningCustomers();
}
fetchTopReturningCustomers() {
    console.log('Fetching top returning customers...');
    getTopReturningCustomers({ organisationId: this.organisationId, limitCount: 2000 })
        .then(data => {
            if (data && data.length > 0) {
                this.customerReturnData = data;
                console.log('customerreturndata->',JSON.stringify(this.customerReturnData));
                console.log('Fetched customer return data:', this.customerReturnData.length);
                this.top5Customers = [...data].slice(0, 5);
                const labels = this.top5Customers.map(c => c.customerName || 'Unknown');
                const returnQtys = this.top5Customers.map(c => c.totalReturnedQty || 0);

                setTimeout(() => {
                    this.renderCustomerReturnBar(labels, returnQtys);
                }, 0);
            }
        })
        .catch(error => {
            console.error('❌ Error fetching top returning customers:', error);
        });
}

renderCustomerReturnBar(labels, data) {
    const ctx = this.template.querySelector("canvas[data-id='customerReturnBar']");
    if (!ctx || !window.Chart) return;

    if (this.charts?.customerBarChart) {
        this.charts.customerBarChart.destroy();
    }

    this.charts = this.charts || {};
    this.charts.customerBarChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Units Returned',
                data: data,
                backgroundColor: '#9b59b6'
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false },
                tooltip: { mode: 'index', intersect: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Returned Qty'
                    }
                }
            }
        }
    });
}
get CRtotalPages() {
    return Math.ceil((this.customerReturnData?.length || 0) / this.CRitemsPerPage);
}

get paginatedCustomerReturns() {
    const start = (this.CRcurrentPage - 1) * this.CRitemsPerPage;
    const end = start + this.CRitemsPerPage;
    return this.customerReturnData?.slice(start, end) || [];
}

handleCRNextPage() {
    if (this.CRcurrentPage < this.CRtotalPages) {
        this.CRcurrentPage += 1;
    }
}

handleCRPreviousPage() {
    if (this.CRcurrentPage > 1) {
        this.CRcurrentPage -= 1;
    }
}
get isCRFirstPage() {
    return this.CRcurrentPage === 1;
}

get isCRLastPage() {
    return this.CRcurrentPage === this.CRtotalPages;
}

    
    
    // =================================================== Inventory levels =================================================


    
    loadAllChartData() {
    // this.fetchCountrySupplyDemand(this.fromDate, this.toDate);
    // this.loadTopFive(this.fromDate, this.toDate);
    // this.loadTop5CountrySupplyDemand(this.fromDate, this.toDate);

    if (!this.selectedProductId) {
        this.loadTop5Data(this.fromDate, this.toDate);
        // this.initializeTop5CountryChart(this.fromDate, this.toDate);
        // this.loadTopFive(this.fromDate, this.toDate);
        // this.loadTop5CountrySupplyDemand(this.fromDate, this.toDate);


        

    } else {
        this.fetchData(this.fromDate, this.toDate);
    }

        // this.initializeSupplyForecastChart();
        // this.initializeTop5CountryChart();
        // this.resolveSupplyOverviewData();        // Monthly chart
        // this.resolveCountrySupplyDemand();   // Country-wise chart
}

        get inventoryLevelTabClass() { return this.isInventoryLevel ? 'sub-tab-horizontal active' : 'sub-tab-horizontal'; }
 
    resetTabs() {
        this.isSupplyOverview = false;
        this.isSupplierScorecard = false;
        this.isInventoryLevel = false;
        this.isProcurementPlanning = false;
        this.isSafety = false;
    }

    selectInventoryLevel() {
        
        this.clearCharts();
        this.isDemand = false;
        this.isInventory = false;
        this.isSafety = false;
        this.isAging = false;
        this.isCustomerPattern = false;
        this.isSimulationPlanning = false;
        this.inventoryProduct.Id = null;
        this.inventoryProduct.Name = null;
        this.isStockMovement = false;
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
 
            if (this.productId) {
                console.log('📦 Fetching single product data:', this.productId, this.fromDate, this.toDate);
                if(this.fromDate && this.toDate){
                    this.fetchData(); // For selected product
                }else{
                    this.setFiscalDates(true).then(() => {
                        this.fetchData(); // Now dates are ready
                    }).catch(error => {
                        console.error('❌ Failed to set fiscal dates:', error);
                    });
                }
            } else  {
                console.log('🔄 Fallback to Top 5');
                if(this.fromDate && this.toDate){
                    this.loadTop5Data(); // Fetch and render Top 5 products chart
                }else{
                    this.selectInventoryLevel();
                }
            }
            }
    
    handleProductRemoved(event) {
            this.productId = null;
            this.productName = null;
 
            // Optional: Clear existing chart
            if (this.chart) {
                this.chart.destroy();
                this.chart = null;
            }
 
            this.selectInventoryLevel();
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
                    this.renderInitial();//now M
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
    // renderedCallback() {
    //         console.log('calling initial');
            
    //         this.renderInitial();
    //     }
    
        renderInitial() {
            console.log('in render call back');
    
            if (this.chartJsReady) {
                console.log('🤣🤣🤣');
                
                if (this.top5ChartPending && this.isTop5View) {
                    const canvas = this.template.querySelector('canvas.barChartTop5');
                    if (canvas) {
                        console.log('render top 5 chart');
                        
                        this.renderTop5Chart();
                        console.log('set fiscal dates');
                        
                        this.setFiscalDates();
                        console.log('🤣🤣🤣');
                        
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
            console.log('✅✅in render single chart');
            
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
                                backgroundColor: 'rgba(243, 156, 18, 0.7)'
                            },
                            {
                                label: 'Consumed / In Stock',
                                data: [
                                    this.inventoryLevelData.totalConsumedRaw,
                                    this.inventoryLevelData.totalWipScrapped,
                                    this.inventoryLevelData.totalFinishedInStock
                                ],
                                backgroundColor: 'rgba(46, 204, 113, 0.7)'
                            },
                            {
                                label: 'Scrapped',
                                data: [
                                    this.inventoryLevelData.totalScrappedRaw,
                                    this.inventoryLevelData.totalWipScrapped,
                                    this.inventoryLevelData.totalFinishedScrapped
                                ],
                                backgroundColor: 'rgba(231, 76, 60, 0.7)'
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
            console.log('❌❌❌in render top 5');
            
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
                            { label: 'Raw', backgroundColor: 'rgba(46, 204, 113, 0.7)', data: raw },
                            { label: 'WIP', backgroundColor:'rgba(243, 156, 18, 0.7)', data: wip },
                            { label: 'Finished', backgroundColor:  'rgba(231, 76, 60, 0.7)', data: finished }
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

    // stock movement code starts here 
@track isstockMovement=false;
totalInwards = 0;
totalOutwards = 0;
stockInwardsData = [];
stockOutwardsData = [];

get stockMovementTabClass(){
    return this.isStockMovement ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}
selectStockMovement(){
    this.clearCharts();
    this.isDemand = false;
    this.isInventoryLevel = false;
    this.isInventory = false;
    this.isSafety = false;
    this.isAging = false;
    this.isCustomerPattern = false;
    this.isSimulationPlanning = false;
    this.isStockMovement = true;
    this.loadAvailableYears();
    this.fetchStockMovements();
}   
fetchStockMovements() {
    console.log('calling stock movement');
    this.isLoading = true;
    getStockMovementData({
         yearStr: this.selectedYear.toString(),
             organisationId: this.organisationId       // ✅ added this line

    })
    .then(result => {
        let inwards = result.inwards || [];
        let outwards = result.outwards || [];

        // Totals
        this.totalInwards = inwards.reduce((sum, rec) => sum + (rec.quantity || 0), 0);
        this.totalOutwards = outwards.reduce((sum, rec) => sum + (rec.quantity || 0), 0);

        // Breakdown for charts
        let inwardBySource = this.aggregateBySource(inwards);
        let outwardBySource = this.aggregateBySource(outwards);

        // Monthly trend
        let inwardByMonth = this.aggregateByMonth(inwards);
        let outwardByMonth = this.aggregateByMonth(outwards);

        // Render charts
        setTimeout(() => {
            this.renderInwardBreakdownChart(Object.keys(inwardBySource), Object.values(inwardBySource));
            this.renderOutwardBreakdownChart(Object.keys(outwardBySource), Object.values(outwardBySource));
            this.renderTrendChart(Object.keys(inwardByMonth), Object.values(inwardByMonth), Object.values(outwardByMonth));
        }, 0);
    })
    .catch(error => {
        console.error('❌ Error fetching stock movements:', error);
    })
    .finally(() => {
        this.isLoading = false;
    });
}

// fetchStockMovements() {
//     console.log('calling stock movement ');
//     getStockMovementData({
//          yearStr: this.selectedYear.toString()
//     })
//     .then(result => {
//         let inwards = result.inwards || [];
//         let outwards = result.outwards || [];

//         // Totals
//         this.totalInwards = inwards.reduce((sum, rec) => sum + (rec.quantity || 0), 0);
//         this.totalOutwards = outwards.reduce((sum, rec) => sum + (rec.quantity || 0), 0);

//         // Breakdown for charts
//         let inwardBySource = this.aggregateBySource(inwards);
//         let outwardBySource = this.aggregateBySource(outwards);

//         // Render charts
//         setTimeout(() => {
//             this.renderInwardBreakdownChart(Object.keys(inwardBySource), Object.values(inwardBySource));
//             this.renderOutwardBreakdownChart(Object.keys(outwardBySource), Object.values(outwardBySource));
//         }, 0);
//     })
//     .catch(error => {
//         console.error('❌ Error fetching stock movements:', error);
//     });
// }

aggregateBySource(list) {
    let map = {};
    list.forEach(rec => {
        let source = rec.source || 'Unknown';
        if (!map[source]) {
            map[source] = 0;
        }
        map[source] += rec.quantity || 0;
    });
    return map;
}
aggregateByMonth(data) {
    let map = {};
    data.forEach(rec => {
        const month = rec.month || 'Unknown';
        map[month] = (map[month] || 0) + (rec.quantity || 0);
    });

    // Sort by year then month
    const sortedKeys = Object.keys(map).sort((a, b) => {
        const [ma, ya] = a.split('/').map(Number);
        const [mb, yb] = b.split('/').map(Number);
        if (ya === yb) return ma - mb;
        return ya - yb;
    });

    let sortedMap = {};
    sortedKeys.forEach(key => {
        sortedMap[key] = map[key];
    });

    return sortedMap;
}
renderTrendChart(monthLabels, inwardData, outwardData) {
    const ctx = this.template.querySelector("canvas[data-id='stockTrendChart']");
    if (!ctx || !window.Chart) return;

    if (this.charts?.stockTrendChart) {
        this.charts.stockTrendChart.destroy();
    }

    this.charts = this.charts || {};
    this.charts.stockTrendChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: monthLabels,
            datasets: [
                {
                    label: 'Stock Inwards',
                    data: inwardData,
                     borderColor: '#9D53F2',
                    backgroundColor: 'rgba(157, 83, 242, 0.1)',
                    fill: true,
                    tension: 0.3
                },
                {
                    label: 'Stock Outwards',
                    data: outwardData,
                    borderColor: '#3290ED',
                    backgroundColor: 'rgba(50, 144, 237, 0.1)',
                    fill: true,
                    tension: 0.3
                }
            ]
        },
        options: {
            responsive: true,
            plugins: {
                tooltip: { mode: 'index', intersect: false },
                legend: { position: 'top' }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: { display: true, text: 'Quantity' }
                }
            }
        }
    });
}


renderInwardBreakdownChart(labels, data) {
    const ctx = this.template.querySelector("canvas[data-id='inwardChart']");
    if (!ctx || !window.Chart) return;

    if (this.charts?.inwardChart) {
        this.charts.inwardChart.destroy();
    }

    this.charts = this.charts || {};
    this.charts.inwardChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                label: 'Inward Qty',
                data: data,
                backgroundColor: ['#9D53F2', '#77B5F2', '#3290ED', '#26ABA4', '#FF5722', '#607D8B']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' },
                tooltip: { mode: 'index', intersect: false }
            }
        }
    });
}

renderOutwardBreakdownChart(labels, data) {
    const ctx = this.template.querySelector("canvas[data-id='outwardChart']");
    if (!ctx || !window.Chart) return;

    if (this.charts?.outwardChart) {
        this.charts.outwardChart.destroy();
    }

    this.charts = this.charts || {};
    this.charts.outwardChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                label: 'Outward Qty',
                data: data,
                backgroundColor: ['#9D53F2', '#77B5F2', '#3290ED', '#26ABA4', '#8BC34A', '#FF9800']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom' },
                tooltip: { mode: 'index', intersect: false }
            }
        }
    });
}


handleSMYearChange(){
    this.selectedYear = parseInt(event.detail.value, 10);
    this.fetchStockMovements();
}
get outwardBoxClass() {
    return this.totalOutwards > this.totalInwards
        ? 'summary-box outwards warning'
        : 'summary-box outwards';
}
toYearMonth(label) {
    if (!label) return '';
    const [mon, year] = String(label).split(' ');
    const map = { Jan:'01', Feb:'02', Mar:'03', Apr:'04', May:'05', Jun:'06',
                  Jul:'07', Aug:'08', Sep:'09', Oct:'10', Nov:'11', Dec:'12' };
    return `${year}-${map[mon] || '01'}`;
}
async handleSaveSimulation() {
    try {
        if (!Array.isArray(this.simulatedForecast) || this.simulatedForecast.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No Simulation',
                message: 'Run a simulation first.',
                variant: 'warning'
            }));
            return;
        }

        if (!this.selectedProduct || !this.selectedProduct.Id) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Product required',
                message: 'Select a product to attribute this simulation to.',
                variant: 'error'
            }));
            return;
        }

        this.isSavingSimulation = true;

        // Build payload
        const name = `Sim - ${this.selectedProduct.Name || 'Product'} - ${new Date().toLocaleString()}`;
        const fromPeriod = this.toYearMonth(this.forecastLabels?.[0]);
        const toPeriod = this.toYearMonth(this.forecastLabels?.[this.forecastLabels.length - 1]);

        const lines = (this.forecastLabels || []).map((label, i) => ({
            yearMonth: this.toYearMonth(label),
            forecasted: Number(this.forecastData?.[i] ?? 0),
            simulated: Number(this.simulatedForecast?.[i] ?? 0)
            // actual: add here if you want to pass historical values too
        }));

        const payload = {
            name,
            model: this.selectedModel || 'HOLT_WINTERS',
            type: 'Demand',
            productId: this.selectedProduct.Id,
            fromPeriod,
            toPeriod,
            lines
        };

        // 🚀 Await Apex call
        const simId = await saveSimulation({ payloadJson: JSON.stringify(payload) });
        console.log('Simulation created with Id:', simId);

        this.dispatchEvent(new ShowToastEvent({
            title: 'Simulation saved',
            message: `Simulation "${name}" created successfully`,
            variant: 'success'
        }));

        // 🚀 Navigate to Simulation record
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: simId,
                objectApiName: 'Simulation__c',
                actionName: 'view'
            }
        });

    } catch (e) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Save failed',
            message: (e && e.body && e.body.message)
                ? e.body.message
                : (e?.message || 'Unknown error'),
            variant: 'error'
        }));
        console.error('Save Simulation error:', e);

    } finally {
        this.isSavingSimulation = false;
    }
}

// async handleEvaluateSimulations() {
//     try {
//         if (!this.selectedProduct?.Id) {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Select a product first',
//                 variant: 'error'
//             }));
//             return;
//         }

//         // Build actuals payload
//         const actuals = (this.fullHistoricalLabels || []).map((label, i) => ({
//             yearMonth: this.toYearMonth(label),
//             actual: Number(this.fullHistoricalValues?.[i] ?? 0)
//         }));

//         const results = await evaluateSimulations({
//             productId: this.selectedProduct.Id,
//             year: '2025',
//             actualsJson: JSON.stringify(actuals)
//         });

//         if (!results || results.length === 0) {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'No Simulations',
//                 message: 'No approved simulations found for this product/year',
//                 variant: 'info'
//             }));
//             return;
//         }

//         // Keep top 3
//         const top3 = results.slice(0, 3);

//         // Clear old overlays before adding new ones
//         this.demandByMonth.data.datasets = this.demandByMonth.data.datasets.filter(ds =>
//             !ds.label.includes('(MAE:')
//         );

//         // Add overlay lines for top3
//         top3.forEach((sim, idx) => {
//             const simData = [];
//             this.forecastLabels.forEach(label => {
//                 const ym = this.toYearMonth(label);
//                 const line = sim.lines.find(l => l.yearMonth === ym);
//                 simData.push(line ? line.simulated : null);
//             });
//             this.demandByMonth.data.datasets.push({
//                 label: `${sim.simulationName} (MAE: ${sim.mae})`,
//                 data: simData,
//                 borderColor: this.getColor(idx),
//                 borderDash: [5, 5],
//                 fill: false
//             });
//         });

//         this.demandByMonth.update();

//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Evaluation Complete',
//             message: 'Top 3 most accurate simulations are shown on the chart.',
//             variant: 'success'
//         }));

//     } catch (e) {
//         console.error('Evaluation error:', e);
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Error',
//             message: e?.body?.message || e.message,
//             variant: 'error'
//         }));
//     }
// }
async handleEvaluateSimulations() {
    try {
        // Guard: chart must exist
        if (!this.charts?.demandChart) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Chart not ready',
                message: 'Run forecast first to render the chart before evaluating simulations.',
                variant: 'warning'
            }));
            return;
        }

        // Build actual values from JS arrays
        const actualMap = {};
        (this.fullHistoricalLabels || []).forEach((label, i) => {
            actualMap[this.toYearMonth(label)] = Number(this.fullHistoricalValues?.[i] ?? 0);
        });
        (this.forecastLabels || []).forEach((label, i) => {
            if (!(this.toYearMonth(label) in actualMap)) {
                actualMap[this.toYearMonth(label)] = 0; // default if missing
            }
        });

        // Call Apex evaluation
        const results = await evaluateSimulations({
            productId: this.selectedProduct.Id,
            year:'2025',
            actualValuesJson: JSON.stringify(actualMap)
        });

        if (!results || results.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No simulations',
                message: 'No simulations found to evaluate.',
                variant: 'info'
            }));
            return;
        }

        // Take top 3 simulations by accuracy (lowest MAE)
        const top3 = results.slice(0, 3);

        const chart = this.charts.demandChart;

        // Remove old comparison datasets
        chart.data.datasets = chart.data.datasets.filter(ds => !ds.label.includes('(MAE:'));

        
        const allLabels = [...this.filteredHistLabels, ...this.forecastLabels];

        top3.forEach((sim, idx) => {
            // Align simulation data to allLabels (history + forecast)
            const simData = allLabels.map(label => {
                const ym = this.toYearMonth(label);
                const line = sim.lines.find(l => l.yearMonth === ym);
                return line ? line.simulated : null;
            });

            this.charts.demandChart.data.datasets.push({
                label: `${sim.simulationName} (MAE: ${sim.mae})`,
                data: simData,
                borderColor: this.getColor(idx),
                borderDash: [4, 4],
                tension: 0.3,
                fill: false
            });
        });

        this.charts.demandChart.update();


        this.dispatchEvent(new ShowToastEvent({
            title: 'Evaluation complete',
            message: `Top ${top3.length} simulations plotted.`,
            variant: 'success'
        }));
    } catch (err) {
        console.error('Evaluation error:', err);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Evaluation failed',
            message: err.body?.message || err.message || 'Unknown error',
            variant: 'error'
        }));
    }
}


getColor(i) {
    const palette = ['#f0ff1aff', 'rgba(208, 49, 195, 1)', '#33FF57'];
    return palette[i % palette.length];
}

//simualtion planning tab 
get simulationPlanningTabClass() {
    return this.isSimulationPlanning ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}
selectSimulationPlanning() {
    this.clearCharts();
    this.isDemand = false;
    this.isInventoryLevel = false;
    this.isInventory = false;
    this.isSafety = false;
    this.isAging = false;
    this.isCustomerPattern = false;
    this.isStockMovement = false;
    this.isSimulationPlanning = true;
    this.selectedProduct={Id:null,Name:null};
     getDefaultProductFromOrderItem()
                            .then(product => {  console.log('default product: ',product);
                                if (product) {
                                    this.selectedProduct = {
                                        Id: product.Id,
                                        Name: product.Name
                                    };
                                    this.isDemandProductSel = true;
                                    this.fetchDemandData();
                                    this.fetchTopCustomers();
                                    this.fetchTopProducts();
                                } else {
                                    console.warn('No default product found from OrderItem.');
                                }
                            })
                            .catch(error => {
                                console.error('Error fetching default product from OrderItem:', error);
                            });
        this.custProd = { Id: null, Name: null };
}
// reactive properties
// showSimulationPanel = false;
historicalStart = 1;
historicalEnd = 1;
futureEditCount = 0;
maxSliderValue = 20000; // adjust to your scale

// helpers to compute counts (used in template)
get historicalMonthsCount() {
  return Array.isArray(this.filteredHistLabels) ? this.filteredHistLabels.length : 0;
}
get forecastHorizon() {
  return Array.isArray(this.forecastLabels) ? this.forecastLabels.length : 0;
}

// computed lists for template
get displayHistoricalMonths() {
  if (!this.filteredHistLabels || !this.filteredHistLabels.length) return [];
  const startIdx = Math.max(0, Math.min(this.historicalMonthsCount - 1, (this.historicalStart || 1) - 1));
  const endIdx = Math.max(startIdx, Math.min(this.historicalMonthsCount, this.historicalEnd || this.historicalMonthsCount));
  const out = [];
  for (let i = startIdx; i < endIdx; i++) {
    const label = this.filteredHistLabels[i];
    // try to find existing override
    const existing = Array.isArray(this.simulationInputs) ? this.simulationInputs.find(si => si.label === label) : null;
    const fallback = (this.filteredHistData && this.filteredHistData[i] !== undefined) ? this.filteredHistData[i] : 0;
    out.push({ label, value: existing ? existing.value : fallback, index: i });
  }
  return out;
}

get displayFutureMonths() {
  if (!this.forecastLabels || !this.forecastLabels.length) return [];
  const count = Math.max(0, Math.min(this.forecastLabels.length, this.futureEditCount || 0));
  const out = [];
  for (let i = 0; i < count; i++) {
    const label = this.forecastLabels[i];
    const existing = Array.isArray(this.futureForecastInputs) ? this.futureForecastInputs.find(fi => fi.label === label) : null;
    const fallback = (this.forecastData && this.forecastData[i] !== undefined) ? this.forecastData[i] : null;
    out.push({ label, value: existing ? existing.value : fallback, index: i });
  }
  return out;
}

/* ------ event handlers ------ */

toggleSimulationPanel() {
  this.showSimulationPanel = !this.showSimulationPanel;
  // when opening, init start/end to sensible defaults:
  if (this.showSimulationPanel) {
    this.historicalStart = 1;
    this.historicalEnd = this.historicalMonthsCount || 1;
    this.futureEditCount = 0; // default, let user choose
    // optionally load existing overrides into arrays (if already exist)
    this.simulationInputs = this.simulationInputs || [];
    this.futureForecastInputs = this.futureForecastInputs || [];
  }
}

handleHistoricalStartChange(evt) {
  let v = Number(evt.target.value) || 1;
  v = Math.max(1, Math.min(v, this.historicalMonthsCount || 1));
  this.historicalStart = v;
  if (this.historicalEnd < this.historicalStart) {
    this.historicalEnd = this.historicalStart;
  }
}

handleHistoricalEndChange(evt) {
  let v = Number(evt.target.value) || this.historicalMonthsCount || 1;
  v = Math.max(1, Math.min(v, this.historicalMonthsCount || 1));
  this.historicalEnd = v;
  if (this.historicalStart > this.historicalEnd) {
    this.historicalStart = this.historicalEnd;
  }
}

handleFutureCountChange(evt) {
  this.futureEditCount = Number(evt.detail ? evt.detail.value : evt.target.value) || 0;
}

// shared update routine used by slider + number input
updateMonthValue(label, value) {
  // ensure arrays exist
  this.simulationInputs = Array.isArray(this.simulationInputs) ? [...this.simulationInputs] : [];
  this.futureForecastInputs = Array.isArray(this.futureForecastInputs) ? [...this.futureForecastInputs] : [];

  // decide whether label is future (present in forecastLabels) or historical
  const isFuture = Array.isArray(this.forecastLabels) && this.forecastLabels.indexOf(label) !== -1;
  if (isFuture) {
    const idx = this.futureForecastInputs.findIndex(f => f.label === label);
    if (idx >= 0) {
      this.futureForecastInputs[idx] = { ...this.futureForecastInputs[idx], value };
    } else {
      this.futureForecastInputs.push({ label, value });
    }
    // reassign reference so LWC re-renders
    this.futureForecastInputs = [...this.futureForecastInputs];
  } else {
    const idx = this.simulationInputs.findIndex(s => s.label === label);
    if (idx >= 0) {
      this.simulationInputs[idx] = { ...this.simulationInputs[idx], value };
    } else {
      this.simulationInputs.push({ label, value });
    }
    this.simulationInputs = [...this.simulationInputs];
  }
}

handleMonthSliderChange(evt) {
  // lightning-slider provides event.detail.value; fallback to target.value
  const label = evt.target.dataset.label;
  const value = Number(evt.detail && evt.detail.value !== undefined ? evt.detail.value : evt.target.value);
  this.updateMonthValue(label, value);
 
}

handleMonthNumberChange(evt) {
  const label = evt.target.dataset.label;
  const value = Number(evt.target.value);
  this.updateMonthValue(label, value);
}

resetSimulation() {
  // revert the override arrays (clear overrides)
  this.simulationInputs = [];
  this.futureForecastInputs = [];
  // keep panel open or close as per your UX; I will keep it open:
  this.historicalStart = 1;
  this.historicalEnd = this.historicalMonthsCount || 1;
  this.futureEditCount = 0;
  // Also re-run a fresh fetch or chart refresh if necessary:
  // this.fetchDemandData(); // optional
}



}