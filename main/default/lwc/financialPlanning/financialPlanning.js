import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/ChartJS';
import { NavigationMixin } from 'lightning/navigation';
import getMonthlyIncomeExpense from '@salesforce/apex/financialplanning.getMonthlyIncomeExpense';
import getChartOfAccountsByType from '@salesforce/apex/financialplanning.getChartOfAccountsByType';
import getCustomerInvoiceSummary from '@salesforce/apex/financialplanning.getCustomerInvoiceSummary';
import getMonthlyCreditDebitSummary from '@salesforce/apex/financialplanning.getMonthlyCreditDebitSummary';
import getMonthlyIncomeExpensenew from '@salesforce/apex/financialplanning.getMonthlyIncomeExpensenew';
import getOverallIncomeAndExpenseTotals from '@salesforce/apex/financialplanning.getOverallIncomeAndExpenseTotals';
import getChartOfAccountTotals from '@salesforce/apex/financialplanning.getChartOfAccountTotals';
import getOverallExpenseBreakdown from '@salesforce/apex/financialplanning.getOverallExpenseBreakdown';
import getExpenseTypeBreakdown from '@salesforce/apex/financialplanning.getFilteredExpenseBreakdown';
import getChartOfAccountsWithBudgetAccounts from '@salesforce/apex/financialplanning.getChartOfAccountsWithBudgetAccounts';
import getProjectBudgetsByChartOfAccount from '@salesforce/apex/financialplanning.getProjectBudgetsByChartOfAccount';
import getSingleProjectBudget from '@salesforce/apex/financialplanning.getSingleProjectBudget';
import getProjectsByChartOfAccount from '@salesforce/apex/financialplanning.getProjectsByChartOfAccount';
import getYearlyIncomeAndExpenseWithPrediction from '@salesforce/apex/financialplanning.getYearlyIncomeAndExpenseWithPrediction';
import getDefaultOrg from '@salesforce/apex/financialplanning.getDefaultOrg';
import getCurrencySymbol from '@salesforce/apex/financialplanning.getCurrencySymbol';
import getCustomerTableDetails from '@salesforce/apex/financialplanning.getGroupedInvoiceBillDetails';
import getMonthlyIncomeExpenseWithPrediction from '@salesforce/apex/financialplanning.getMonthlyIncomeExpenseWithPrediction';
import simulateForecastWithInputs from '@salesforce/apex/financialplanning.simulateForecastWithInputs';
import getChartOfAccountGrandTotal from '@salesforce/apex/financialplanning.getChartOfAccountGrandTotal';
import getMonthlyExpensesOnly from '@salesforce/apex/financialplanning.getMonthlyExpensesOnly';
import getSingleProjectBudgetSimulated from '@salesforce/apex/financialplanning.getSingleProjectBudgetSimulated';
import getProjectIDs from '@salesforce/apex/financialplanning.getProjectIDs';
import getOrgFiscalStartMonth from '@salesforce/apex/financialplanning.getOrgFiscalStartMonth';
import getMonthlyIncomeExpenseForFiscalYear from '@salesforce/apex/financialplanning.getMonthlyIncomeExpenseForFiscalYear';
import refineResponse from '@salesforce/apex/financialplanning.refineResponse';
import getMonthlyCreditDebitSummaryForFiscalYear from '@salesforce/apex/financialplanning.getMonthlyCreditDebitSummaryForFiscalYear';






export default class FinancialTabs extends NavigationMixin(LightningElement) {

 @track projectSelected = false; 
    @track isSimulatedBudgetVisible = false;    
        @track chartData;
    @track summaryTableData = {};
     @track isBudget = true;
    @track isCosting = false;
    @track filteredProjectIdList = [];
    @track expenseChartLabels = [];
    @track expenseDataForChart = [];
    @track isNewBudget = false;
    @track isNewPlanning = false;
    @track isNewPlanningIn = false;
    @track simulatedProjectBudgetData = {};
    @api organisationId;
     @track currencySymbol = ''; // 👈 Will hold the returned symbol
    @track fromDate = new Date();
    @track toDate = new Date();
    @track selectedRecordType = 'Assets';
    @track summaryView = 'Overdue';
    @track selectedCoa = '';
    @track showsimulation = true;
    @track availableCoas = [];
    @track coaData = {};
    @track coaKeys = [];
    @track showInitialCharts = false;
    @track showDetailedCharts = true;
    chartInstances = {};
    @track chartDataSimulated = false;
    isChartJsInitialized = false;
    @track isGroupedChartVisible = true; // Flag to control grouped chart visibility
    @track selectedYearforIncome = new Date().getFullYear();
@track availableYearsforIncome = [];
@track selectedCreditDebitYear = new Date().getFullYear();
 @track availableCreditDebitYears = [];
@track selectedChartOfAccount = {};
   @track selectedProject = {};
    @track projectFilter = '';
    @track isProjectPieVisible = false;
@track isProjectChartVisible = false; // Flag to control project chart visibility
@track summaryTableKeys = [];
  @track displayRows = [];
@track showSummaryTable = false;
@track predictedDataMap = {}; // Map to hold predicted income/expense data  
 @track simulatedIncomeInputs = [];
    @track simulatedExpenseInputs = [];
    @track showSimulationPanel = false;
   @track simulatedValuesMap = {};
 @track isLoading = false;
   @track optionsForSimulation = false;
    @track simulationResult;
    currentMonth;
  @track showSimulationPanel = false;
@track historicalData = {
        income: [],
        expense: []
    };
    @track isdisableToDate = false;
    @track selectedYearModeForProjuction = 'Standard';
    @track selectedYearMode = 'normal'; // default
    @track isSimulationTableVisible = false; // Flag to control simulation table visibility
    @track isSimulationApproved = false; // Flag to control simulation approved visibility
     @track simRows = [];
    @track rowIdCounter = 1;
     @track showSimulateModal = false;

    @track simulateApproved = 0;
    @track simulateConsumed = 0;
    @track simulateRemaining = 0;
    @track simulateCommitted = 0;
    @track simulateMonth = '';
     @track selectedApproved = 0;
    @track selectedConsumed = 0;
    @track selectedRemaining = 0;
    @track selectedCommitted = 0;
     @track simulatedProject = {};
    @track simulationTableData1 = false;
@track simulationTableData = [];
    @track predictedIncome = [];
    @track predictedExpense = [];

      @track simulattionmonth = '';


        @track months = [];               // <-- make sure months is an array
  sliderMin = -50;
  sliderMax = 50;
  sliderStep = 5;

    @track issliderVisible = false;

    @track currentMonth = {
        id: null,
        label: '',
        statement: '',
        originalValue: 1000,
        sliderPercent: 0,
        adjustedValue: 1000,
        deltaText: '0% → ',
        adjustedText: `${this.currencySymbol}1000`,
        deltaType: 'No change'
    };


    allMonthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul',
                      'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];


     @track categoryData = {
        'Cost Budget': [],
        'Time and Material Budget': [],
        'Fixed Budget': []
    };

    @track categories = ['Cost Budget', 'Time and Material Budget', 'Fixed Budget'];

  

populateYearsDropdown() {
    const currentYear = new Date().getFullYear();
    const years = [];
    for (let i = 0; i <= 10; i++) {
        years.push(currentYear - i);
    }
    this.availableYearsforIncome = years.sort((a, b) => b - a);
    this.availableCreditDebitYears = years.sort((a, b) => b - a);
}


handleChartOfAccountRemoved(event) {
    console.log('🟡 handleChartOfAccountRemoved triggered') ;
    console.log('📦 Event detail:', event.detail);
    this.selectedChartOfAccount = {};
    this.isProjectChartVisible = false; // Hide project chart
    this.budgetPlanData();
    console.log('🔄 Chart of Account removed, showing grouped chart');
}

    handleYearChangeforIncome(event) {

        this.selectedYearforIncome = parseInt(event.target.value, 10);
          const currentYear = new Date().getFullYear();

    if (parseInt(this.selectedYearforIncome, 10) === currentYear) {
        this.optionsForSimulation = true;
    } else {
        this.optionsForSimulation = false;
    }
        this.initializeLineChart();
        console.log('🔄 Year changed for Income Chart:', this.selectedYearforIncome);
        this.updateCreditDebitChart();
        console.log('🔄 Year changed for Credit/Debit Chart:', this.selectedYearforIncome);

       
    }

    

connectedCallback() {
    const today = new Date();
    const year = today.getFullYear();
    this.fromDate = `${year}-01-01`;
    this.toDate = today.toISOString().split('T')[0];



  


    this.populateYearsDropdown();

    // Get org
    // getDefaultOrg()
    //     .then(org => {
    //         this.organisationId = org.Id;
    //         console.log('🔄 Org Id:', this.organisationId);
    //     });



    if (parseInt(this.selectedYearforIncome, 10) === year) {
        this.optionsForSimulation = true;
    } else {
        this.optionsForSimulation = false;
    }

    // Fetch Chart of Accounts with Budget Accounts
    getChartOfAccountsWithBudgetAccounts({organisationId: this.organisationId})
        .then(ids => {
            if (ids.length > 0) {
                this.chartOfAccountFilter = `Id IN (${ids.map(id => `'${id}'`).join(',')})`;
            } else {
                this.chartOfAccountFilter = 'Id = null'; // fallback
            }
        })
        .catch(error => {
            console.error('❌ Error setting chartOfAccountFilter:', error);
            this.chartOfAccountFilter = ''; // fallback
        });



   
}


backtoInitialCharts() {
    this.showInitialCharts = true;
    this.showDetailedCharts = false;

     this.loadInitialCharts();
     this.loadChartDataforYearlySummary();

}





    renderedCallback() {
    if (this.isChartJsInitialized) return;
    this.isChartJsInitialized = true;

    loadScript(this, chartJs)
        .then(() => {
            // 🔄 Get Currency Symbol from Apex
            return getCurrencySymbol();
        })
        .then(symbol => {
            this.currencySymbol = symbol;
            console.log('💱 Currency Symbol:', this.currencySymbol);

            // ✅ Only initialize chart after currency is set
            this.initializeCharts();
        })
        .catch(error => {
            console.error('❌ Error fetching currency symbol or loading ChartJS:', error);
            this.currencySymbol = ''; // fallback
        });
}


   get budgetTabClass() {
    return this.isBudget ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}

get costingTabClass() {
    return this.isCosting ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}



get newBudgetTabClass() {
    return this.isNewBudget ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}



get newPlanningTabClass() {
    return this.isNewPlanning ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}

get newSubscriptionTabClass() {
    return this.isNewSubscription ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
}   

  resetTabs() {
    this.isBudget = false;
    this.isCosting = false;
    this.isNewBudget = false;
    this.isNewPlanning = false;
}

selectBudget() {
    this.resetTabs();
    this.isBudget = true;
    this.selectedYearforIncome = new Date().getFullYear();
    this.selectedYearMode = 'normal';
    setTimeout(() => this.initializeCharts(), 20);
}

selectCosting() {
    this.resetTabs();
    this.isCosting = true;
    this.summaryView = 'Overdue'; // Reset to default view
    this.selectedRecordType = 'Assets'; // Reset to default record type
    
    setTimeout(() => this.initializeCharts(), 20);
     this.fetchCustomerSummaryTable();
}



selectNewBudget() {
    this.resetTabs();
    this.isNewBudget = true;
    this.projectFilter = '';
    this.selectedChartOfAccount = {};
    this.selectedProject = {};
    this.isProjectChartVisible = false; // Hide project chart
    this.selectedYearModeForProjuction = 'Standard';
    this.loadIncomeExpenseCharts();





    setTimeout(() => this.initializeCharts(), 20);
   
    
}


  selectNewPlanning() {
        this.resetTabs();
        this.resetSimulation();
        this.selectedChartOfAccount = {};
        this.selectedProject = {};
        this.projectFilter = '';
        this.isNewPlanning = true;
        this.isNewPlanningIn = true;
         this.isSimulatedBudgetVisible = false;
          this.simulatedProjectBudgetData = {}; // Clear budget data
        this.selectedApproved = 0;
        this.selectedConsumed = 0;
        this.selectedRemaining = 0;
        this.selectedCommitted = 0;
        this.expenseDataForChart = [];
        this.expenseChartLabels = [];
        this.simulatedProject = {};
        this.chartDataSimulated = false; // Reset chart data flag
        this.isSimulationTableVisible = false;
        this.isSimulationApproved = false;
        this.simulatedApproved = 0;

       

          this.simRows = []; // Add initial row

        setTimeout(() => this.initializeCharts(), 20);
    }

    selectNewSubscription() {
        this.resetTabs();   
        this.isNewSubscription = true;

        setTimeout(() => this.initializeCharts(), 20);
    }   

handleRecordTypeChange(event) {
    this.selectedRecordType = event.target.value;
    this.updateDoubleBarChart();
}

    handleCustomerSummaryChange(event) {
        this.summaryView = event.target.value;
        this.updateCustomerHeatmap();
          this.fetchCustomerSummaryTable();
        console.log('🔄 Customer Summary View changed to:', this.summaryView);
    }


 fetchCustomerSummaryTable() {
        getCustomerTableDetails({ type: this.summaryView, organisationId: this.organisationId })
            .then(result => {
                console.log('📊 Customer Summary Table Data:', JSON.stringify(result, null, 2));
                this.summaryTableData = result || {};
                console.log('📊 Summary Table Data:', JSON.stringify(this.summaryTableData, null, 2));
                this.processSummaryTableData();
                   
            })
            .catch(error => {
                console.error('❌ Error fetching customer summary table:', error);
            });
    }


    processSummaryTableData() {
    const rows = [];

    let currentCustomer = null;
    let colorToggle = false;

    Object.entries(this.summaryTableData).forEach(([customer, records]) => {
        records.forEach((record, index) => {
            if (currentCustomer !== customer) {
                currentCustomer = customer;
                colorToggle = !colorToggle; // Flip color on new customer
            }

            rows.push({
                slno: index + 1,
                customer: index === 0 ? customer : '', // only show name in first row
                recordName: record.recordName,
                recordId: record.recordId,
                accountId: record.accountId,
                amount: record.amount,
                rowGroupClass: colorToggle ? 'group-color-a' : 'group-color-b'
            });
        });
    });

    this.summaryTableKeys = rows;
    console.log('🔄 Processed Summary Table Keys:', JSON.stringify(this.summaryTableKeys, null, 2));

    console.log('📊 Processed Summary Table Rows:', JSON.stringify(rows, null, 2));
    console.log('Account IDs:', JSON.stringify(rows.map(row => row.accountId), null, 2));

    this.displayRows = rows;
}

handleRecordClick(event) {
        const recordId = event.currentTarget.dataset.recordId;
        if (recordId) {
            const baseUrl = window.location.origin;
            const recordUrl = `${baseUrl}/${recordId}`;
            window.open(recordUrl, '_blank');
        } else {
            console.error('Record ID not found on clicked element');
        }
    }


    initializeCharts() {
        this.initializeLineChart();
        this.updateDoubleBarChart();
        this.updateCustomerHeatmap();
        this.updateCreditDebitChart();
        this.loadIncomeExpenseCharts();
        this.budgetPlanData();
        this.loadChartDataforYearlySummary();
        this.initializeLineChartwithPrediction();
        this.loadGrandTotalData();
        this.renderChartForBudgeting();

       
    }


handleCreateNewBudget() {

    
this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'Budget',
            actionName: 'new' // Open in new tab
        }

       
    });
    

}


toggleChartsforSimulation() {
    this.showsimulation = false;


    // Delay the chart initialization until after DOM updates
    setTimeout(() => {
        this.initializeLineChartwithPrediction();
    }, 0);
}

    togglebackToMain() {
        this.showsimulation = true;
        this.selectBudget();
        this.showSimulationPanel = false; // Hide simulation panel
        this.simulationTableData1 = false; // Reset simulation table data visibility
        this.simulatedValuesMap = {}; // Reset simulated values map
        this.simulatedIncomeInputs = []; // Reset simulated income inputs
        this.resetSimulation(); // Reset simulation state

    }



    openSimulationModal() {
    const currentMonthIndex = new Date().getMonth(); // 0 = Jan, 11 = Dec
    const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Filter for future months
    this.simulatedIncomeInputs = monthLabels.slice(currentMonthIndex).map(month => ({
        label: month,
        value: null
    }));
    this.simulatedExpenseInputs = monthLabels.slice(currentMonthIndex).map(month => ({
        label: month,
        value: null
    }));
    
    this.showSimulationPanel = true;
}
handleSimInputChange(event) {
   
    
    const month = event.target.dataset.month;
    const type = event.target.dataset.type;
    const value = event.target.value ? parseFloat(event.target.value) : 0;

    if (!this.simulatedValuesMap[month]) {
        this.simulatedValuesMap[month] = { income: null, expense: null };
    }

    this.simulatedValuesMap[month][type] = value;

    console.log('📝 Simulated Values Map:', JSON.stringify(this.simulatedValuesMap));
}

resetSimulation() {
    this.simulatedValuesMap = {};
    this.simulatedIncomeInputs = [];
    this.simulatedExpenseInputs = [];
    this.showSimulationPanel = false;
    console.log('🔄 Simulation reset');
}


handleSimulateForecast() {
    const inputMap = {};
   
    // Step 1: Only include non-null simulated values
    for (const [month, values] of Object.entries(this.simulatedValuesMap)) {
        const income = values.income !== null && values.income !== undefined ? parseFloat(values.income) : null;
        const expense = values.expense !== null && values.expense !== undefined ? parseFloat(values.expense) : null;

        // Include only if at least one value is non-null
        if (income !== null || expense !== null) {
            inputMap[month] = {
                income,
                expense
            };
        }
    }

    console.log('🚀 Simulated data to send:', JSON.stringify(inputMap));

    // Step 2: Send to Apex for simulation
    simulateForecastWithInputs({ simulatedValues: inputMap, organisationId: this.organisationId })
        .then((result) => {
            console.log('📊 Simulated Forecast Result from Apex:', JSON.stringify(result));
            this.renderSimulatedForecastChart(result);
            this.showSimulationPanel = false;
        })
        .catch((error) => {
            console.error('❌ Forecast Simulation Error:', error);
        });
}

renderSimulatedForecastChart(data) {
    const ctx = this.template.querySelector('.income-expense-line-prediction')?.getContext('2d');
    if (!ctx) {
        console.warn('⚠️ Chart context not found');
        return;
    }

//  this.historicalData = {
//                 income: Array.from({ length: 12 }, (_, i) => result.income?.[i] ?? 0),
//                 expense: Array.from({ length: 12 }, (_, i) => result.expense?.[i] ?? 0)
//             };


    const labels = data.monthLabels || [];

    const actualIncome = this.historicalData.income || [];
    const actualExpense = this.historicalData.expense || [];

    const predictedIncome = this.predictedIncome || [];
    const predictedExpense = this.predictedExpense || [];

    const simulatedIncome = data.predictedIncome || []; 
    const simulatedExpense = data.predictedExpense || [];

    const simulatedinputIncome = data.simulatedIncome || [];
    const simulatedinputExpense = data.simulatedExpense || [];

    this.destroyChart('lineChart');

    const datasets = [
        {
            label: 'Income (Actual)',
            data: actualIncome,
            borderColor: '#9D53F2',
            backgroundColor: 'rgba(157, 83, 242, 0.1)',
            tension: 0.3,
            fill: true,
            pointRadius: 0,
            borderWidth: 2
        },
        {
            label: 'Expenses (Actual)',
            data: actualExpense,
            borderColor: '#3290ED',
            backgroundColor: 'rgba(50, 144, 237, 0.1)',
            tension: 0.3,
            fill: true,
            pointRadius: 0,
            borderWidth: 2
        },
        {
            label: 'Income (Predicted)',
            data: predictedIncome,
            borderColor: '#9D53F2',
            borderDash: [5, 5],
            tension: 0.3,
            fill: false,
            pointRadius: 0,
            borderWidth: 2
        },
        {
            label: 'Expenses (Predicted)',
            data: predictedExpense,
            borderColor: '#3290ED',
            borderDash: [5, 5],
            tension: 0.3,
            fill: false,
            pointRadius: 0,
            borderWidth: 2
        }
    ];

    // Add Simulated only if present
    if (simulatedIncome.length > 0) {
        datasets.push({
            label: 'Income (Simulated) Using HoltWinters',
            data: simulatedIncome,
            borderColor: '#F26522',
            borderDash: [2, 3],
            tension: 0.3,
            fill: false,
            pointRadius: 0,
            borderWidth: 2
        });
    }

    if (simulatedExpense.length > 0) {
        datasets.push({
            label: 'Expenses (Simulated) Using HoltWinters',
            data: simulatedExpense,
            borderColor: '#FF3C38',
            borderDash: [2, 3],
            tension: 0.3,
            fill: false,
            pointRadius: 0,
            borderWidth: 2
        });
    }

    this.chartInstances.lineChart = new window.Chart(ctx, {
        type: 'line',
        data: {
            labels,
            datasets
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
                        callback: value => (this.currencySymbol || '') + value.toLocaleString()
                    },
                    title: {
                        display: true,
                        text: 'Amount ' + (this.currencySymbol || '')
                    }
                }
            }
        }
    });

      this.monthLabels = labels;
       
this.simulationTableData = [
    {
        label: 'Actual Income',
        values: actualIncome.map((val, idx) => ({ val, key: `ActualIncome-${idx}` }))
    },
    {
        label: 'Actual Expense',
        values: actualExpense.map((val, idx) => ({ val, key: `ActualExpense-${idx}` }))
    },
    {
        label: 'Simulated Input Income',
        values: simulatedinputIncome.map((val, idx) => ({ val, key: `SimulatedInputIncome-${idx}` }))
    },
    {
        label: 'Simulated Input Expense',
        values: simulatedinputExpense.map((val, idx) => ({ val, key: `SimulatedInputExpense-${idx}` }))
    },
    {
        label: 'Simulated Income',
        values: simulatedIncome.map((val, idx) => ({ val, key: `SimulatedIncome-${idx}` }))
    },
    {
        label: 'Simulated Expense',
        values: simulatedExpense.map((val, idx) => ({ val, key: `SimulatedExpense-${idx}` }))
    }
];

 this.simulationTableData1 = true;

}




  // Called when "Create" button is clicked
    createBillOrInvoice() {
        this.showCheckboxes = true;
         this.displayRows = [...this.displayRows]; // 🔁 Force UI to re-render
    }

    // Called when checkbox is clicked for a row
    handleCheckboxClick(event) {
      let accountId = '';
let recordName = '';

const recordId = event.currentTarget.dataset.id;
const isChecked = event.currentTarget.checked;
recordName = event.currentTarget.dataset.name || '';

if (!isChecked) return;

const match = this.summaryTableKeys.find(item => item.recordId === recordId);

if (this.summaryView === 'Overdue') {
    if (match) {
        accountId = match.accountId;
    } else {
        console.warn(`❗ No matching record found for ID: ${recordId}`);
    }
    this.createInvoicePayment(recordId, accountId);

} else if (this.summaryView === 'Unpaid') {
    if (match) {
        recordName = match.recordName || recordName;
    }
    this.createBillPayment(recordId, recordName);

} else {
    console.warn('❓ Unknown summaryView:', this.summaryView);
}

// Reset checkbox and UI
event.currentTarget.checked = false;
this.showCheckboxes = false;
this.displayRows = [...this.displayRows];
    console.log('🔄 Checkbox clicked, resetting UI');
    }
// Handles Invoice Payment - opens VF
createInvoicePayment(invoiceId, accountId) {

    console.log('🧾 [createInvoicePayment] Called with:');
    console.log('🔹 invoiceId in invoice:', invoiceId);
    console.log('🔹 accountId in invoice:', accountId);
    if (!invoiceId || !accountId) {
        console.error('❌ Missing Invoice or Account ID.');
        this.showErrorToast('Missing Invoice or Account ID.');
        return;
    }

    const url = `/apex/createpayment?invoiceId=${encodeURIComponent(invoiceId)}&accountId=${encodeURIComponent(accountId)}&type=invoice`;
    
    console.log('🌐 Constructed VF URL:', url);
    console.log('🚀 Opening Visualforce page in new tab...');
    
    window.open(url, '_blank');
}



createBillPayment(billId, recordName) {
    const orgId = this.organisationId;

    console.log('🧾 [createBillPayment] Called with:');
    console.log('🔹 billId:', billId);
    console.log('🔹 orgId in bill:', orgId);
    console.log('🔹 recordName in bill:', recordName);

    if (!billId || !orgId) {
        this.showErrorToast('Missing Bill or Org ID.');
        return;
    }

    // 👉 Navigation to Accounts_Payable component with state parameters
    console.log('📌 Navigating to Accounts_Payable component with tab Bills and search set to:', recordName);

    this[NavigationMixin.Navigate]({
        type: 'standard__component',
        attributes: {
            componentName: 'Accounts_Payable'
        },
        state: {
            selectedTab: 'Bills',
            setSearch: recordName // <-- Make sure your target LWC reads this param
        }
    });
}





//  handlesimulatedProjectSelected(event) {
//         const selected = event.detail; // { Id, Name }
//         this.simulatedProject = selected;
//         console.log('🔄 Simulated Project Selected:', JSON.stringify(selected, null, 2));

//         if (selected?.Id) {
//             this.fetchProjectBudget(selected.Id);
//         }
//     }

   handlesimulatedProjectRemoved() {
    this.simulatedProject = {};
    this.chartDataSimulated = false;
    this.simulatedProjectBudgetData = {};
    this.selectedApproved = 0;
    this.selectedConsumed = 0;
    this.selectedRemaining = 0;
    this.selectedCommitted = 0;
    this.isSimulationTableVisible = false; // Hide simulation table
    this.simRows = []; // Reset simulation rows
    this.simulatedValuesMap = {}; // Reset simulated values map
    this.isSimulationApproved = false; // Reset simulation approved flag
    this.simulatedApproved = 0;

    // 🧹 Destroy existing chart if exists
    if (this.chartInstances['grouped']) {
        this.chartInstances['grouped'].destroy();
        delete this.chartInstances['grouped'];
    }

    // 🔁 Show grand total chart again
    this.loadGrandTotalDataInitial();
}




scrollToSimulationTable() {
    this.addRow(); // Ensure at least one row exists before scrolling
    console.log('🔄 Scrolling to simulation table section');

    const target = this.template.querySelector('[data-id="simulationTableSection"]');
   
    if (target) {
        setTimeout(() => {
            target.scrollIntoView({ behavior: 'smooth' });
        }, 500); // ⏱ 500ms delay
    } else {
        console.warn('📛 simulationTableSection not found!');
    }
}




//     fetchProjectBudget(projectId) {
//         getSingleProjectBudgetSimulated({ projectId })
//         .then((result) => {
//             console.log('📊 Project Budget Data:', JSON.stringify(result, null, 2));
//             this.simulatedProjectBudgetData = result; // ✅ Save full result2

//             // Also assign specific fields for UI
//             this.selectedApproved = result.approved || 0;
//             this.selectedConsumed = result.consumed || 0;
//             this.selectedRemaining = result.remaining || 0;
//             this.selectedCommitted = result.committed || 0;

//             this.chartDataSimulated = true; // ✅ Set flag to true

//         })
//         .catch((error) => {
//             console.error('Error fetching project budget:', error);
//             this.chartDataSimulated = false;
//             this.simulatedProjectBudgetData = {}; // clear stored data on error
//         });
// }


handlesimulatedProjectSelected(event) {
    const selected = event.detail;
    this.simulatedProject = selected;
    console.log('🔄 Simulated Project Selected:', JSON.stringify(selected, null, 2));

    if (selected?.Id) {
        this.fetchProjectBudget(selected.Id);
    }

    this.isSimulationTableVisible = true; 
    this.projectSelected = true;

    // ✅ Automatically add one default month row when a project is selected
    if (!this.months || this.months.length === 0) {
        this.addSimulationRow(); 
    }
}

//  get justchecking1() {
//     return this.issliderVisible
//         ? "slds-col slds-size_1-of-1 slds-p-right_small slds-large-size_5-of-12"
//         : "slds-col slds-size_1-of-1 slds-p-right_small slds-large-size_8-of-12";
// }

// get justchecking2() {
//     return this.issliderVisible
//         ? "slds-col slds-size_1-of-1 slds-p-right_small slds-large-size_3-of-12"
//         : "slds-col slds-size_1-of-1 slds-p-right_small slds-large-size_4-of-12";
// }


    fetchProjectBudget(projectId) {
        getSingleProjectBudgetSimulated({ projectId, organisationId: this.organisationId })
            .then(result => {
                console.log('📊 Project Budget Data:', JSON.stringify(result, null, 2));
                this.simulatedProjectBudgetData = result;

                // Assign fields
                this.selectedApproved = result.approved || 0;
                this.selectedConsumed = result.consumed || 0;
                this.selectedRemaining = result.remaining || 0;
                this.selectedCommitted = result.committed || 0;

                this.chartDataSimulated = true;

                // Update chart
                this.renderGroupedBarChartInitial(
                    [this.simulatedProject.Name || 'Selected Project'],
                    [this.selectedApproved],
                    [this.selectedConsumed],
                    [this.selectedCommitted],
                    [this.selectedRemaining]
                );
            })
            .catch(error => {
                console.error('Error fetching project budget:', error);
                this.chartDataSimulated = false;
                this.simulatedProjectBudgetData = {};
            });
    }

    renderGroupedBarChartInitial(labels, approved, consumed, committed, remaining) {
        const ctx = this.template.querySelector('canvas.grouped-bar-chart')?.getContext('2d');
        if (!ctx) {
            console.error('Canvas not found for grouped bar chart');
            return;
        }

        if (this.chartInstances['grouped']) {
            this.chartInstances['grouped'].destroy();
        }

        let delayed;
        const symbol = this.currencySymbol || '';

        this.chartInstances['grouped'] = new window.Chart(ctx, {
            type: 'bar',
            data: {
                labels,
                datasets: [
                    { label: 'Approved', data: approved, backgroundColor: '#3290ED' },
                    { label: 'Consumed', data: consumed, backgroundColor: '#9D53F2' },
                    { label: 'Committed', data: committed, backgroundColor: '#26ABA4' },
                    { label: 'Remaining', data: remaining, backgroundColor: '#4001d3ff' }
                ]
            },
            options: {
                responsive: true,
                animation: {
                    onComplete: () => {
                        delayed = true;
                    },
                    delay: (context) => {
                        let delay = 0;
                        if (context.type === 'data' && context.mode === 'default' && !delayed) {
                            delay = context.dataIndex * 300 + context.datasetIndex * 100;
                        }
                        return delay;
                    }
                },
                plugins: {
                    title: {
                        display: true,
                        text: 'Budget Summary by Project'
                    },
                    legend: { position: 'top' },
                    tooltip: {
                        mode: 'index',
                        intersect: false
                    }
                },
                scales: {
                    x: { stacked: false },
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Amount ' + symbol
                        },
                        ticks: {
                            callback: (value) => symbol + value.toLocaleString()
                        }
                    }
                }
            }
        });
    }


simulateAll() {
    const missingMonthRows = [];
    const missingAmountRows = [];

    this.simRows.forEach((row, index) => {
        const rowNumber = index + 1;
        const isMonthEmpty = !row.month || row.month.trim() === '';
        const isAmountInvalid = !row.additionalAllocation || isNaN(row.additionalAllocation) || row.additionalAllocation <= 0;

        if (isMonthEmpty) {
            missingMonthRows.push(rowNumber);
        }

        if (isAmountInvalid) {
            missingAmountRows.push(rowNumber);
        }
    });

    // 🛑 Compose error messages
    let errorMessage = '';
    if (missingMonthRows.length && missingAmountRows.length) {
        errorMessage = `⚠️ Missing Month and Allocation amount in row: ${[...new Set([...missingMonthRows, ...missingAmountRows])].join(', ')}`;
    } else if (missingMonthRows.length) {
        errorMessage = `⚠️ Please select a Month in row(s): ${missingMonthRows.join(', ')}`;
    }

    if (errorMessage) {
        alert(errorMessage);
        return;
    }

    // ✅ All valid — run simulation
    this.renderSimulationStackedChart();
    this.simulateAllformonthlywise();
}


handleRefineAI(event) {
    const index = event.currentTarget.dataset.index;
    const row = this.simRows[index];

    const projectName = this.simulatedProject.Name || 'Selected Budget';
    const statement = row.statement || '';
    const amount = row.additionalAllocation || 0;
    const month = row.month || 'a future month';

    const prompt = `Generate a formal and professional sentence that clearly describes a budget update where an additional amount of ${amount} is being added under the budget titled '${projectName}' for the month of ${month}. The reason for this adjustment is: ${statement}. Make the sentence informative, simple, detailed, no extra fluff,no extra text,dont change the name of the title.`;

    refineResponse({ inputText: prompt })
        .then((refinedText) => {
            this.simRows[index].statement = refinedText;
            this.simRows = [...this.simRows]; // refresh UI
        })
        .catch((error) => {
            console.error(' AI refinement :', error);
            this.simRows[index].statement = `The ${projectName} budget for ${month} has been adjusted by a ${amount}.`;
            this.simRows = [...this.simRows]; // refresh UI
           // alert(' AI refinement not working, Continue without AI refinement');
        });
}


    handleStatementChange(event) {
    this.selectedStatement = event.target.value;
    console.log('🔄 Selected Statement:', this.selectedStatement);
}

handleAllocationChange(event) {
    const index = event.target.dataset.index;
    const value = parseFloat(event.target.value || 0);

    // ✅ Update the value inside simRows
    this.simRows[index].additionalAllocation = value;

    console.log('🔄 Selected Allocation:', value);
}

renderSimulationStackedChart() {
    console.log('🧾 simRows:', JSON.stringify(this.simRows, null, 2));

    const approved = parseFloat(this.selectedApproved || 0);
    const remaining = parseFloat(this.selectedRemaining || 0);

    const extra = this.simRows.reduce((sum, row) => {
        const val = parseFloat(row.additionalAllocation || 0);
        return sum + (isNaN(val) ? 0 : val);
    }, 0);

    console.log('🔄 Approved:', approved);
    console.log('🔄 Extra:', extra);
    console.log('🔄 Remaining:', remaining);

    const totalApproved = approved + extra;
    this.simulatedApproved = totalApproved;
    this.isSimulationApproved = true;
    this.chartDataSimulated = true;

    const ctx = this.template.querySelector('canvas.grouped-bar-chart')?.getContext('2d');
    if (!ctx) {
        console.error('Canvas not found');
        return;
    }

    if (this.chartInstances['grouped']) {
        this.chartInstances['grouped'].destroy();
    }

    const symbol = this.currencySymbol || '';
    let delayed;

    this.chartInstances['grouped'] = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Approved Amount', 'Remaining Amount', 'Additional Allocation Amount', 'Total Approved Amount'],
            datasets: [{
                label: 'Amount',
                backgroundColor: ['#263eabff ', '#3290ED', '#9c27b0', '#9D53F2'],
                data: [approved, remaining, extra, totalApproved]
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false },
                title: {
                    display: true,
                    text: '📊 Budget with Additional Allocation'
                },
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            const value = context.parsed.y || 0;
                            return `${context.label}: ${symbol}${value.toLocaleString()}`;
                        }
                    }
                }
            },
            animation: {
                onComplete: () => {
                    delayed = true;
                },
                delay: (context) => {
                    let delay = 0;
                    if (context.type === 'data' && context.mode === 'default' && !delayed) {
                        delay = context.dataIndex * 300;
                    }
                    return delay;
                }
            },
            scales: {
                x: {
                    title: { display: true, text: 'Category' }
                },
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Amount (' + symbol + ')'
                    },
                    ticks: {
                        callback: (value) => symbol + value.toLocaleString()
                    }
                }
            }
        }
    });
}


yearModeOptionsForProjuction = [
    { label: 'Standard Year', value: 'Standard' },
    { label: 'Fiscal Year', value: 'Fiscal' }
];

handleYearModeChangeForProjuction(event) {
    this.selectedYearModeForProjuction = event.detail.value;

    if (this.selectedYearModeForProjuction === 'Fiscal') {
        // Fetch fiscal start month dynamically
        getOrgFiscalStartMonth()
            .then((startMonth) => {
                console.log('📅 Org Fiscal Start Month:', startMonth);

                const today = new Date();
                let fiscalStartYear;

                // Decide fiscal start year
                if (today.getMonth() + 1 >= startMonth) {
                    fiscalStartYear = today.getFullYear();
                } else {
                    fiscalStartYear = today.getFullYear() - 1;
                }

                // Build fiscal start + end
                const fiscalStart = new Date(fiscalStartYear, startMonth - 1, 1);
                const fiscalEnd = new Date(fiscalStartYear + 1, startMonth - 1, 0);

                // Format YYYY-MM-DD
                const fmt = (d) =>
                    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

                this.fromDate = fmt(fiscalStart);
                this.toDate = fmt(fiscalEnd);

                this.isdisableToDate = true; // Disable To Date input

                console.log('📅 Fiscal Year Mode selected → From:', this.fromDate, 'To:', this.toDate);

                // Save reference values if needed later
                this.fiscalStartMonth = startMonth;
                this.baseFiscalYear = fiscalStartYear;
                this.selectedYearforIncome = `${fiscalStartYear}-${String(startMonth).padStart(2, '0')}`;

                this.loadIncomeExpenseChartsforfiscalyear();
            })
            .catch((error) => {
                console.error('⚠️ Error fetching fiscal start month:', error);
            });

    } else {
        // Standard mode → current calendar year up to today
    const today = new Date();
    const year = today.getFullYear();
    

    this.isdisableToDate = false; // Disable To Date input   

    this.fromDate = `${year}-01-01`;
    this.toDate = today.toISOString().split('T')[0]; // today's date

    this.loadIncomeExpenseCharts();
    console.log('📅 Standard Year Mode selected → From:', this.fromDate, 'To:', this.toDate);
       

    }
}



handleSimulate() {
    // 👇 Set default values from the selected project’s summary
    this.simulateApproved = this.selectedApproved|| 0;
    this.simulateConsumed = this.selectedConsumed || 0;
    this.simulateRemaining = this.selectedRemaining || 0;
    this.simulateCommitted = this.selectedCommitted || 0;


      const today = new Date();

// Get the year
const year = today.getFullYear();

// Get the month (0-indexed), then add 1 to make it 1-indexed
const month = today.getMonth() + 1;

// Pad the month with a leading zero if it's a single digit
const formattedMonth = month < 10 ? '0' + month : month;

// Combine year and formatted month
const currentMonthFormatted = `${year}-${formattedMonth}`;

console.log(currentMonthFormatted);

this.simulateMonth = currentMonthFormatted; // Default to current month

    this.showSimulateModal = true;
}


    // Close modal
    handleCloseModal() {
        this.showSimulateModal = false;
        this.simulateApproved = 0;
        this.simulateConsumed = 0;
        this.simulateRemaining = 0;
        this.simulateCommitted = 0;
        this.simulateMonth = '';
        

      

    }

    // Save text input changes
    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    // Save month selection
    handleMonthChange(event) {
        this.simulateMonth = event.target.value;
        console.log('📅 Selected Month for Simulation:', this.simulateMonth);
    }

//    handleApplySimulation() {
   

//     // ✅ Extract values
// const selectedMonth = this.simulateMonth; // e.g., "2025-09"
// const simulatedAmount = Number(this.simulateRemaining) || 0;


// if (!selectedMonth) {
//     console.warn(' Missing simulation month');
//     return;
// }

// // ✅ Convert YYYY-MM to 'Sep' or similar
// const monthIndex = parseInt(selectedMonth.split('-')[1], 10) - 1;
// const monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][monthIndex];

// const allMonths = this.expenseChartLabels; // e.g. ['Jul', 'Aug', 'Sep', ..., 'Jun']
// const selectedIndex = allMonths.indexOf(monthName);

// if (selectedIndex === -1) {
//     console.warn('⚠️ Selected month not in labels');
//     return;
// }

// // ✅ Construct simulation payload including previous and next months
// const simulatedPoints = [];

// // Previous month (if exists)
// if (selectedIndex > 0) {
//     simulatedPoints.push({
//         month: allMonths[selectedIndex - 1],
//         amount: 0
//     });
// }

// // Selected month
// simulatedPoints.push({
//     month: monthName,
//     amount: simulatedAmount
// });

// // Next month (if exists)
// if (selectedIndex < allMonths.length - 1) {
//     simulatedPoints.push({
//         month: allMonths[selectedIndex + 1],
//         amount: 0
//     });
// }

// console.log('🧮 Simulated Points:', JSON.stringify(simulatedPoints, null, 2));

// // 🔁 Redraw chart with simulation data
// this.renderChartForBudgeting(this.expenseChartLabels, this.expenseDataForChart, simulatedPoints);

// // ✅ Close modal
// this.showSimulateModal = false;

// }

handleApplySimulation() {
    const selectedMonth = this.simulateMonth; // e.g. "2026-02"
    const simulatedAmount = Number(this.simulateRemaining) || 0;

    if (!selectedMonth) {
        console.warn('⚠️ Missing simulation month');
        return;
    }

    // Parse selected year & month
    const [year, monthNum] = selectedMonth.split('-').map(Number);
    const selectedKey = `${year}-${String(monthNum).padStart(2, '0')}`;

    // ✅ Build base months (Jan–Dec current year)
    const currentYear = new Date().getFullYear();
    const monthKeys = [];
    for (let m = 1; m <= 12; m++) {
        monthKeys.push(`${currentYear}-${String(m).padStart(2, '0')}`);
    }

    // ✅ Extend future months dynamically if selected > Dec current year
    if (year > currentYear) {
        for (let m = 1; m <= monthNum; m++) {
            monthKeys.push(`${year}-${String(m).padStart(2, '0')}`);
        }
    }

    // ✅ Create readable labels (e.g. "Jan 2025", "Feb 2026")
    const labels = monthKeys.map((key) => {
        const [y, m] = key.split('-');
        const d = new Date(y, m - 1);
        return d.toLocaleString('default', { month: 'short', year: 'numeric' });
    });

    // ✅ Build simulated dataset: only one adjusted month
    const simulatedPoints = [
        { month: selectedKey, amount: simulatedAmount }
    ];

    console.log('📆 Final Labels:', labels);
    console.log('💰 Simulated Points:', simulatedPoints);

    // ✅ Render the chart
    this.renderChartForBudgeting(labels, this.expenseDataForChart, simulatedPoints);

    this.showSimulateModal = false;
}


get monthOptions() {
    const options = [];
    const today = new Date();
    const currentYear = today.getFullYear();
    const currentMonth = today.getMonth(); // 0 = Jan, 11 = Dec

    const formatter = new Intl.DateTimeFormat('en-US', {
        month: 'long',
        year: 'numeric'
    });

    // Loop 12 months starting from current month
    for (let i = 0; i < 12; i++) {
        // Create a date for each month
        const date = new Date(currentYear, currentMonth + i, 1);

        // Format label as "Month Year" (e.g., "October 2025")
        const label = formatter.format(date);

        // Format value as "YYYY-MM" (e.g., "2025-10")
        const value = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;

        options.push({ label, value });
    }

    return options;
}



getSliderPercentLabel(month) {
    return `${month.sliderPercent || 0}%`;
}


handleDelete(event) {
    const id = parseInt(event.target.dataset.id, 10);
    this.months = this.months.filter(m => m.id !== id);
}
// Handle month selection per row
handleMonthChange2(event) {
    const id = parseInt(event.target.dataset.id, 10);
    const month = this.months.find(m => m.id === id);

    if (month) {
        // Raw combobox value from dropdown (e.g., "2025-10")
        const selectedValue = event.detail.value || this.monthOptions?.[0]?.value || '';

        // Store raw value for combobox usage
        month.value = selectedValue;

        // Derive pretty label for display (e.g., "Oct 2025")
        if (selectedValue) {
            const [year, monthNum] = selectedValue.split('-');
            const date = new Date(year, monthNum - 1); // JS months are 0-based
            const shortMonth = date.toLocaleString('default', { month: 'short' });
            month.label = `${shortMonth} ${year}`;
        } else {
            month.label = '';
        }

        // Refresh reactivity
        this.months = [...this.months];

        // Update the corresponding table row if it exists
        const index = parseInt(event.target.dataset.index, 10);
        if (this.simRows && this.simRows[index]) {
            this.simRows[index].month = selectedValue; // raw value for combobox
            this.simRows = [...this.simRows];           // trigger re-render
        }
    }
}



handleStatementChange(event) {
  const id = parseInt(event.target.dataset.id, 10);
  const month = this.months.find(m => m.id === id);
  if (month) {
    month.statement = event.target.value;
    this.months = [...this.months];
  }
}

handleValueChange(event) {
  const id = parseInt(event.target.dataset.id, 10);
  const month = this.months.find(m => m.id === id);
  if (month) {
    const base = parseFloat(event.target.value) || 0;
    month.originalValue = base;
     month.sliderPercent = 0; // ✅ Reset slider
    this.recalculateRow(month);
  }
}

handleSliderInput(event) {
  const id = parseInt(event.target.dataset.id, 10);
  const month = this.months.find(m => m.id === id);
  if (month) {
    month.sliderPercent = parseInt(event.target.value, 10);
    this.recalculateRow(month);
  }
}

// recalculateRow(m) {
//     // Calculate the adjusted value
//     m.adjustedValue = m.originalValue + (m.originalValue * m.sliderPercent / 100);

//     // Compute difference
//     const diff = m.adjustedValue - m.originalValue;

//     // Determine the sign for adjustedText display
//     const sign = diff > 0 ? '+' : diff < 0 ? '-' : '';

//     // Format for display on card
//     m.adjustedText = `${sign}${this.currencySymbol}${Math.abs(m.adjustedValue).toLocaleString()}`;

//     // Delta type for display
//     m.deltaType =
//         m.adjustedValue === m.originalValue
//             ? ''
//             : m.adjustedValue > m.originalValue
//             ? 'Increase'
//             : 'Decrease';

//     // Trigger re-render
//     this.months = [...this.months];
// }


recalculateRow(month) {
    const base = month.originalValue || 0;
    const percent = month.sliderPercent || 0;

    // ✅ Calculate adjusted value based on slider
    const adjusted = base + (base * percent) / 100;

    // ✅ Update the display text and delta type
    month.adjustedText = adjusted.toLocaleString(undefined, {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });

    month.deltaType =
        percent > 0
            ? `Increased by ${percent}%`
            : percent < 0
            ? `Decreased by ${Math.abs(percent)}%`
            : `No change`;

    // ✅ Trigger reactive refresh
    this.months = [...this.months];
}



resetSimulation() {
  this.months = this.months.map(m => ({
    ...m,
    statement: '',
    sliderPercent: 0,
    adjustedValue: m.originalValue,
    deltaText: '0% → ',
    adjustedText: `${this.currencySymbol}${m.originalValue}`,
    deltaType: ''
  }));
}




      addRow() {

         const today = new Date();
    const currentYear = today.getFullYear();
    const currentMonth = String(today.getMonth() + 1).padStart(2, '0'); // 1-indexed
    var month = `${currentYear}-${currentMonth}`; // "2025-09"

        this.simRows = [...this.simRows, {
            id: this.rowIdCounter++,
            month: month, // Default to current month
            additionalAllocation: 0,
            statement: ''
        }];

  // use the currently selected simulation month
    const defaultMonth = this.monthOptions?.[0]?.value || '';

    let monthLabel = defaultMonth;
    if (defaultMonth) {
        const [year, month] = defaultMonth.split('-'); // e.g. "2025-01"
        const date = new Date(year, month - 1);        // JS months are 0-based
        const shortMonth = date.toLocaleString('default', { month: 'short' }); // Jan, Feb...
        monthLabel = `${shortMonth} ${year}`;          // "Jan 2025"
    }

    const newMonth = {
        id: Date.now(),
        label: monthLabel,   // ✅ e.g. "Jan 2025"
        statement: '',
        originalValue: 1000,
        sliderPercent: 0,
        adjustedValue: 1000,
        deltaText: '0% → ',
        adjustedText: `${this.currencySymbol}1000`,
        deltaType: ''
    };

    this.months = [...this.months, newMonth];
    }


   addSimulationRow() {
    // use the currently selected simulation month
    const defaultMonth = this.monthOptions?.[0]?.value || '';

    let monthLabel = defaultMonth;
    if (defaultMonth) {
        const [year, month] = defaultMonth.split('-'); // e.g. "2025-01"
        const date = new Date(year, month - 1);        // JS months are 0-based
        const shortMonth = date.toLocaleString('default', { month: 'short' }); // Jan, Feb...
        monthLabel = `${shortMonth} ${year}`;          // "Jan 2025"
    }

    const newMonth = {
        id: Date.now(),
        label: monthLabel,   // ✅ e.g. "Jan 2025"
        statement: '',
        originalValue: 1000,
        sliderPercent: 0,
        adjustedValue: 1000,
        deltaText: '0% → ',
        adjustedText: `${this.currencySymbol}1000`,
        deltaType: ''
    };

    this.months = [...this.months, newMonth];
}
// handleSimulateForecastNew() {
//     if (this.months && this.months.length > 0) {
//         this.simRows = this.months.map((month, index) => {
//             let numericValue = null;
//             let sign = '';

//             if (month.adjustedText) {
//                 // Extract sign
//                 if (month.adjustedText.startsWith('-')) sign = '-';
//                 else if (month.adjustedText.startsWith('+')) sign = '+';

//                 // Extract numeric value (ignore currency symbols and commas)
//                 const match = month.adjustedText.match(/[\d,]+(\.\d+)?/);
//                 if (match) numericValue = Number(match[0].replace(/,/g, ''));
//             }

//             const allocationValue = numericValue !== null ? Number(sign + numericValue) : null;

//             // Compute class for coloring (+ green, - red)
//             let allocationClass = '';
//             if (allocationValue > 0) allocationClass = 'slds-text-color_success';
//             else if (allocationValue < 0) allocationClass = 'slds-text-color_error';

//             return {
//                 id: month.id || index,
//                 statement: month.statement || '',
//                 additionalAllocation: allocationValue,
//                 month: month.value || '',
//                 allocationClass // <-- store class here
//             };
//         });

//         console.log('Simulation Table Data:', JSON.stringify(this.simRows, null, 2));
//         this.simulateAll();
//     } else {
//         console.log('No months data available.');
//     }
// }


handleSimulateForecastNew() {
    if (this.months && this.months.length > 0) {
        this.simRows = this.months.map((month, index) => {
            let numericValue = null;
            let sign = '';

            if (month.adjustedText) {
                // Extract sign
                if (month.adjustedText.startsWith('-')) sign = '-';
                else if (month.adjustedText.startsWith('+')) sign = '+';

                // Extract numeric value (ignore currency symbols and commas)
                const match = month.adjustedText.match(/[\d,]+(\.\d+)?/);
                if (match) numericValue = Number(match[0].replace(/,/g, ''));
            }

            const allocationValue = numericValue !== null ? Number(sign + numericValue) : null;

            // Compute class for coloring (+ green, - red)
            let allocationClass = '';
            if (allocationValue > 0) allocationClass = 'slds-text-color_success';
            else if (allocationValue < 0) allocationClass = 'slds-text-color_error';

            // ✅ Add serial number here
            const serialNumber = index + 1;

            return {
                id: month.id || index,
                serialNumber, // ✅ added serial number field
                statement: month.statement || '',
                additionalAllocation: allocationValue,
                month: month.value || '',
                allocationClass
            };
        });

        console.log('Simulation Table Data:', JSON.stringify(this.simRows, null, 2));
        this.simulateAll();
    } else {
        console.log('No months data available.');
    }
}

    deleteRow(event) {
        const idToDelete = parseInt(event.target.dataset.id, 10);
        this.simRows = this.simRows.filter(row => row.id !== idToDelete);
    }

  handleProjectSelected1(event) {
    const index = parseInt(event.target.dataset.index, 10);
    const record = event.detail;

    console.log('🔄 Project index:', index);
    console.log('🔄 Project Selected:', JSON.stringify(record, null, 2));

    if (!this.simRows || !this.simRows[index]) {
        console.error('❌ simRows is undefined or row at index not found:', index);
        return;
    }

    getSingleProjectBudgetSimulated({ projectId: record.Id }).then(data => {
        const row = this.simRows[index];

        if (!row) return;

        row.approved = data.approved || 0;
        row.consumed = data.consumed || 0;
        row.remaining = data.remaining || 0;
        row.committed = data.committed || 0;

        this.simRows = [...this.simRows]; // Trigger reactivity
        console.log('✅ Updated simRows:', JSON.stringify(this.simRows, null, 2));
    }).catch(error => {
        console.error('❌ Apex error:', error);
    });
}


    handleMonthChange1(event) {
        const index = parseInt(event.target.dataset.index, 10);
        this.simRows[index].month = event.target.value;
    }


    //need to work on this 
// simulateAllformonthlywise() {
//     const allMonths = this.expenseChartLabels; // e.g., ['Jul', 'Aug', 'Sep', ..., 'Jun']
//     const monthMap = {}; // Map of month => total simulated amount

//     console.log('📋 Simulating for rows:', this.simRows.length);

//     this.simRows.forEach((row, index) => {
//         if (!row.month) {
//             console.warn(`⚠️ Row ${index + 1} has no selected month`);
//             return;
//         }

//         const monthValue = row.month; // e.g., "2025-09"
//         const amount = Number(row.additionalAllocation) || 0;

//         const monthIndex = parseInt(monthValue.split('-')[1], 10) - 1;
//         const monthName = [
//             'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//         ][monthIndex];

//         const chartIndex = allMonths.indexOf(monthName);

//         if (chartIndex === -1) {
//             console.warn(`❌ Month '${monthName}' not found in labels`);
//             return;
//         }

//         // Set center
//         if (!monthMap[monthName]) {
//             monthMap[monthName] = 0;
//         }
//         monthMap[monthName] += amount;

//         // Set surrounding zero months
//         const prevMonth = allMonths[chartIndex - 1];
//         const nextMonth = allMonths[chartIndex + 1];

//         if (prevMonth && !monthMap.hasOwnProperty(prevMonth)) {
//             monthMap[prevMonth] = 0;
//         }
//         if (nextMonth && !monthMap.hasOwnProperty(nextMonth)) {
//             monthMap[nextMonth] = 0;
//         }

//         console.log(`✅ Processed Row ${index + 1} — ${monthName}: +${amount}`);
//     });

//     console.log('🗺️ Aggregated Month Map:', JSON.stringify(monthMap, null, 2));

//     // Build final simulated array in chart label order
//     const simulatedPoints = allMonths.map(month => ({
//         month,
//         amount: monthMap.hasOwnProperty(month) ? monthMap[month] : null
//     }));

//     console.log('🧮 Final Simulated Points:', JSON.stringify(simulatedPoints, null, 2));

//     this.renderChartForBudgeting(this.expenseChartLabels, this.expenseDataForChart, simulatedPoints);
// }

simulateAllformonthlywise() {
    let allMonths = this.expenseChartLabels; // e.g., ['Jan', 'Feb', ..., 'Dec']
    const monthMap = {}; // Map of 'YYYY-MM' => total simulated amount

    console.log('📋 Simulating for rows:', this.simRows.length);

    const currentYear = new Date().getFullYear();
    let maxSimYear = currentYear;
    let maxSimMonth = 12;

    // Detect furthest selected month
    this.simRows.forEach((row) => {
        if (row.month && /^\d{4}-\d{2}$/.test(row.month)) {
            const [y, m] = row.month.split('-').map(Number);
            if (y > maxSimYear || (y === maxSimYear && m > maxSimMonth)) {
                maxSimYear = y;
                maxSimMonth = m;
            }
        }
    });

    // Extend labels for next year if needed
    if (maxSimYear > currentYear) {
        const nextMonths = [];
        for (let y = currentYear + 1; y <= maxSimYear; y++) {
            const limit = y === maxSimYear ? maxSimMonth : 12;
            for (let m = 1; m <= limit; m++) {
                const label = new Date(y, m - 1).toLocaleString('default', {
                    month: 'short',
                    year: 'numeric'
                });
                nextMonths.push(label);
            }
        }

        allMonths = [...allMonths, ...nextMonths]; 
    }

    // Build label → YYYY-MM key map
    const labelToKey = {};
    allMonths.forEach((lbl) => {
        const parts = lbl.split(' ');
        const monthName = parts[0];
        const year = parts[1] ? parseInt(parts[1], 10) : currentYear;
        const monthNum = new Date(`${monthName} 1, ${year}`).getMonth() + 1;
        labelToKey[lbl] = `${year}-${String(monthNum).padStart(2, '0')}`;
    });

    // Process simulation rows
    this.simRows.forEach((row, index) => {
        if (!row.month) {
            console.warn(`⚠️ Row ${index + 1} has no selected month`);
            return;
        }

        const monthValue = row.month; // e.g., "2026-01"
        const amount = Number(row.additionalAllocation) || 0;
        const [yearStr, monthStr] = monthValue.split('-');
        const year = parseInt(yearStr, 10);
        const monthNum = parseInt(monthStr, 10);

        // Current month
        if (!monthMap[monthValue]) monthMap[monthValue] = 0;
        monthMap[monthValue] += amount;

        // Add next month = 0
        let nextYear = year;
        let nextMonth = monthNum + 1;
        if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
        }
        const nextKey = `${nextYear}-${String(nextMonth).padStart(2, '0')}`;
        if (!monthMap.hasOwnProperty(nextKey)) {
            monthMap[nextKey] = 0;
        }

        console.log(`✅ Row ${index + 1} — ${monthValue}: +${amount}, next → ${nextKey}=0`);
    });

    // Include all months present in monthMap
    Object.keys(monthMap).forEach((key) => {
        const [y, m] = key.split('-').map(Number);
        const lbl = new Date(y, m - 1).toLocaleString('default', {
            month: 'short',
            year: 'numeric'
        });
        if (!allMonths.includes(lbl)) allMonths.push(lbl);
    });

    // ✅ Deduplicate and sort once at the end (fixes double rendering)
    allMonths = Array.from(new Set(allMonths));
    allMonths.sort((a, b) => {
        const toDate = (lbl) => {
            const parts = lbl.split(' ');
            const month = parts[0];
            const year = parts[1] ? parseInt(parts[1], 10) : currentYear;
            return new Date(`${month} 1, ${year}`);
        };
        return toDate(a) - toDate(b);
    });

    // Final label → key map
    const labelToKeyFinal = {};
    allMonths.forEach((lbl) => {
        const parts = lbl.split(' ');
        const monthName = parts[0];
        const year = parts[1] ? parseInt(parts[1], 10) : currentYear;
        const monthNum = new Date(`${monthName} 1, ${year}`).getMonth() + 1;
        labelToKeyFinal[lbl] = `${year}-${String(monthNum).padStart(2, '0')}`;
    });

    // Build final simulated points
    const simulatedPoints = allMonths.map((lbl) => {
        const key = labelToKeyFinal[lbl];
        return {
            month: key,
            amount: monthMap.hasOwnProperty(key) ? monthMap[key] : null
        };
    });

    console.log('🧮 Final Simulated Points:', JSON.stringify(simulatedPoints, null, 2));

    // Render chart
    this.renderChartForBudgeting(allMonths, this.expenseDataForChart, simulatedPoints);
}





yearModeOptions = [
    { label: 'Standard Year', value: 'normal' },
    { label: 'Fiscal Year', value: 'fiscal' }
];

// Control template conditions
get isNormalYearMode() {
    return this.selectedYearMode === 'normal';
}

get isFiscalYearMode() {
    return this.selectedYearMode === 'fiscal';
}

handleYearModeChange(event) {
    this.selectedYearMode = event.detail.value;
    console.log('🔄 Mode switched to:', this.selectedYearMode);

    if (this.selectedYearMode === 'normal') {
        this.selectedYearforIncome = new Date().getFullYear().toString();
        console.log('🔄 Year for Income set to:', this.selectedYearforIncome);
        this.initializeLineChart();
        this.updateCreditDebitChart();
    } else {
        // Fetch fiscal start month from Apex
        getOrgFiscalStartMonth()
            .then((startMonth) => {
                console.log('📅 Org Fiscal Start Month:', startMonth);

                const today = new Date();
                let fiscalStartYear;

                // If current month >= startMonth → fiscal started this year
                if (today.getMonth() + 1 >= startMonth) {
                    fiscalStartYear = today.getFullYear();
                } else {
                    // Otherwise fiscal started last year
                    fiscalStartYear = today.getFullYear() - 1;
                }

                // Save for use in change handler
                this.fiscalStartMonth = startMonth;
                this.baseFiscalYear = fiscalStartYear;

                // Default to current fiscal
                this.selectedYearforIncome = `${fiscalStartYear}-${String(startMonth).padStart(2, '0')}`;
                console.log('🔄 Default Year for Income set to (current fiscal):', this.selectedYearforIncome);

                // ✅ Call fiscal chart init directly for default case
                this.handleFiscalYearChange({ target: { value: 'currentFiscal' } });
            })
            .catch((error) => {
                console.error('❌ Error fetching fiscal start month:', error);
            });
    }
}


handleFiscalYearChange(event) {
    const selectedValue = event.target.value;
    console.log('📌 Fiscal Year option selected:', selectedValue);

    let year = this.baseFiscalYear;
    const fiscalMonth = this.fiscalStartMonth; // 1–12

    // Create a proper JS Date for the fiscal start (day 1 of start month)
    let fiscalStartDate;
    if (selectedValue === 'currentFiscal') {
        fiscalStartDate = new Date(year, fiscalMonth - 1, 1);
    } else if (selectedValue === 'previousFiscal') {
        fiscalStartDate = new Date(year - 1, fiscalMonth - 1, 1);
    }

    // Format date for Apex in yyyy-MM-dd to avoid server error
    const fiscalStartDateStr = `${fiscalStartDate.getFullYear()}-${String(fiscalStartDate.getMonth() + 1).padStart(2, '0')}-${String(fiscalStartDate.getDate()).padStart(2, '0')}`;
    
    this.selectedFiscalStartDate = fiscalStartDateStr;

    console.log('✅ Final Fiscal Start Date (for Apex):', fiscalStartDateStr);

    // Call chart initialization
    this.initializeLineChartforFiscalYear();
    this.updateCreditDebitChartForFiscalYear();
}

initializeLineChartforFiscalYear() {
    console.log('🗓️ Initializing Fiscal Year Chart for start date:', this.selectedFiscalStartDate);
    const ctx = this.template.querySelector('.income-expense-line')?.getContext('2d');
    if (!ctx) {
        console.warn('⚠️ Chart context not found');
        return;
    }
    console.log('📅 Selected Fiscal Start Date:', this.selectedFiscalStartDate);

    getMonthlyIncomeExpenseForFiscalYear({ fiscalStartDate: this.selectedFiscalStartDate, organisationId: this.organisationId })
    
        .then(result => {
            console.log('📊 Raw Chart Data:', JSON.stringify(result));

            // Destroy previous chart if exists
            if (this.chartInstances?.lineChart) {
                this.chartInstances.lineChart.destroy();
                this.chartInstances.lineChart = null;
            }

          // Month names
const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const fiscalStartMonth = new Date(this.selectedFiscalStartDate).getMonth(); // 0–11
const fiscalStartYear = new Date(this.selectedFiscalStartDate).getFullYear();
let fiscalLabels = [];

for (let i = 0; i < 12; i++) {
    const monthIndex = (fiscalStartMonth + i) % 12;
    const year = (monthIndex < fiscalStartMonth) ? fiscalStartYear + 1 : fiscalStartYear;
    fiscalLabels.push(`${monthNames[monthIndex]}-${year}`);
}


            const incomeData = result.income || Array(12).fill(0);
            const expenseData = result.expense || Array(12).fill(0);

            // Create new chart
            this.chartInstances.lineChart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: fiscalLabels,
                    datasets: [
                        {
                            label: 'Income',
                            data: incomeData,
                            borderColor: '#9D53F2',
                            backgroundColor: 'rgba(157, 83, 242, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
                        },
                        {
                            label: 'Expenses',
                            data: expenseData,
                            borderColor: '#3290ED',
                            backgroundColor: 'rgba(50, 144, 237, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
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
                            title: { display: true, text: 'Amount ' + (this.currencySymbol || '') },
                            ticks: {
                                callback: value => (this.currencySymbol || '') + value.toLocaleString()
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('❌ Error loading chart data:', error);
        });
}




initializeLineChart() {
    const ctx = this.template.querySelector('.income-expense-line')?.getContext('2d');
    if (!ctx) {
        console.warn('⚠️ Chart context not found');
        return;
    }

    getMonthlyIncomeExpense({ year: this.selectedYearforIncome, organisationId: this.organisationId })
        .then(result => {
            console.log('📊 Raw Chart Data:', JSON.stringify(result));

            this.historicalData = {
                income: Array.from({ length: 12 }, (_, i) => result.income?.[i] ?? 0),
                expense: Array.from({ length: 12 }, (_, i) => result.expense?.[i] ?? 0)
            };

            // Normalize data
            let incomeData = Array.from({ length: 12 }, (_, i) => result.income?.[i] ?? 0);
            let expenseData = Array.from({ length: 12 }, (_, i) => result.expense?.[i] ?? 0);

            console.log('✅ Final Income Array:', JSON.stringify(incomeData));
            console.log('✅ Final Expense Array:', JSON.stringify(expenseData));

            this.destroyChart('lineChart');

            // Animation config
            const easing = window.Chart.helpers.easingEffects.easeInCubic;
            const totalDuration = 5000;
            const duration = (ctx) => easing(ctx.index / incomeData.length) * totalDuration / incomeData.length;
            const delay = (ctx) => easing(ctx.index / incomeData.length) * totalDuration;
            const previousY = (ctx) =>
                ctx.index === 0
                    ? ctx.chart.scales.y.getPixelForValue(0)
                    : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;

            const animation = {
                x: {
                    type: 'number',
                    easing: 'linear',
                    duration: duration,
                    from: NaN,
                    delay(ctx) {
                        if (ctx.type !== 'data' || ctx.xStarted) {
                            return 0;
                        }
                        ctx.xStarted = true;
                        return delay(ctx);
                    }
                },
                y: {
                    type: 'number',
                    easing: 'linear',
                    duration: duration,
                    from: previousY,
                    delay(ctx) {
                        if (ctx.type !== 'data' || ctx.yStarted) {
                            return 0;
                        }
                        ctx.yStarted = true;
                        return delay(ctx);
                    }
                }
            };

             const symbol = this.currencySymbol || ''; // fallback if not set

            // Chart creation
            this.chartInstances.lineChart = new window.Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                    datasets: [
                        {
                            label: 'Income',
                            data: incomeData,
                            borderColor: '#9D53F2',
                            backgroundColor: 'rgba(157, 83, 242, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
                        },
                        {
                            label: 'Expenses',
                            data: expenseData,
                            borderColor: '#3290ED',
                            backgroundColor: 'rgba(50, 144, 237, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
                        }
                    ]
                },
                options: {
                    responsive: true,
                    animation: animation, // ✅ Using your custom animation here
                    plugins: {
                        legend: { position: 'top' },
                        title: {
                            display: true
                           
                        },
                        tooltip: {
    mode: 'index',
    intersect: false
}
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => {
                                    return symbol + value.toLocaleString();
                                }
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('❌ Error loading chart data:', error);
        });
}



initializeLineChartwithPrediction() {
    const ctx = this.template.querySelector('.income-expense-line-prediction')?.getContext('2d');
    console.log('🔄 Initializing Line Chart with Prediction', ctx);
    if (!ctx) {
        console.warn('⚠️ Chart context not found');
        return;
    }

    getMonthlyIncomeExpenseWithPrediction({organisationId: this.organisationId})
        .then(result => {
            console.log('📊 Chart Data:', JSON.stringify(result));

            const symbol = this.currencySymbol || '';
            const labels = result.monthLabels || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            const incomeData = result.income || [];
            const expenseData = result.expense || [];
            const predictedIncome = result.predictedIncome || [];
            const predictedExpense = result.predictedExpense || [];

            this.predictedIncome = predictedIncome;
            this.predictedExpense = predictedExpense;

            console.log('✅ Income Data:', JSON.stringify(incomeData));
            console.log('✅ Expense Data:', JSON.stringify(expenseData));
            console.log('✅ Predicted Income Data:', JSON.stringify(predictedIncome));
            console.log('✅ Predicted Expense Data:', JSON.stringify(predictedExpense));

            // 🔐 Save predicted values for later
            this.predictedDataMap = {};
            labels.forEach((month, index) => {
                this.predictedDataMap[month] = {
                    income: predictedIncome[index] || 0,
                    expense: predictedExpense[index] || 0
                };
            });
            console.log('🧠 Saved predicted data map:', this.predictedDataMap);

            this.destroyChart('lineChart');

            const easing = window.Chart.helpers.easingEffects.easeInCubic;
            const totalDuration = 3000;
            const duration = (ctx) => easing(ctx.index / incomeData.length) * totalDuration / incomeData.length;
            const delay = (ctx) => easing(ctx.index / incomeData.length) * totalDuration;
            const previousY = (ctx) =>
                ctx.index === 0
                    ? ctx.chart.scales.y.getPixelForValue(0)
                    : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1]?.getProps(['y'], true).y;

            const animation = {
                x: {
                    type: 'number',
                    easing: 'linear',
                    duration: duration,
                    from: NaN,
                    delay(ctx) {
                        if (ctx.type !== 'data' || ctx.xStarted) return 0;
                        ctx.xStarted = true;
                        return delay(ctx);
                    }
                },
                y: {
                    type: 'number',
                    easing: 'linear',
                    duration: duration,
                    from: previousY,
                    delay(ctx) {
                        if (ctx.type !== 'data' || ctx.yStarted) return 0;
                        ctx.yStarted = true;
                        return delay(ctx);
                    }
                }
            };

            // 🖌️ Draw Chart
            this.chartInstances.lineChart = new window.Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Income (Actual)',
                            data: incomeData,
                            borderColor: '#9D53F2',
                            backgroundColor: 'rgba(157, 83, 242, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
                        },
                        {
                            label: 'Expenses (Actual)',
                            data: expenseData,
                            borderColor: '#3290ED',
                            backgroundColor: 'rgba(50, 144, 237, 0.1)',
                            fill: true,
                            pointRadius: 0,
                            borderWidth: 2
                        },
                        {
                            label: 'Income (Predicted)',
                            data: predictedIncome,
                            borderColor: '#9D53F2',
                            borderDash: [5, 5],
                            fill: false,
                            pointRadius: 0,
                            borderWidth: 2
                        },
                        {
                            label: 'Expenses (Predicted)',
                            data: predictedExpense,
                            borderColor: '#3290ED',
                            borderDash: [5, 5],
                            fill: false,
                            pointRadius: 0,
                            borderWidth: 2
                        }
                    ]
                },
                options: {
                    responsive: true,
                    animation: animation,
                    plugins: {
                        legend: { position: 'top' },
                        title: { display: false },
                        tooltip: {
    mode: 'index',
    intersect: false
}
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => symbol + value.toLocaleString()
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('❌ Error loading chart data:', error);
        });
}



     updateDoubleBarChart() {
        const ctx = this.template.querySelector('.coa-pie-chart')?.getContext('2d');
        if (!ctx) return;

        getChartOfAccountsByType({ recordType: this.selectedRecordType, organisationId: this.organisationId })
            .then(result => {
                console.log('📊 COA Chart Data:', result);

                const labels = result.labels;
                const debitData = result.debits;
                const creditData = result.credits;

                this.destroyChart('coaChart');

               let delayed;
                const symbol = this.currencySymbol || ''; // fallback if not set

this.chartInstances.coaChart = new window.Chart(ctx, {
    type: 'bar',
    data: {
        labels: labels,
        datasets: [
            {
                label: `Total Amount ${this.currencySymbol} Debited`,
                data: debitData,
                backgroundColor: '#9D53F2'
            },
            {
                label: `Total Amount ${this.currencySymbol} Credited`,
                data: creditData,
                backgroundColor: '#3290ED'
            }
        ]
    },
    options: {
        responsive: true,
        animation: {
            onComplete: () => {
                delayed = true;
            },
            delay: (context) => {
                let delay = 0;
                if (context.type === 'data' && context.mode === 'default' && !delayed) {
                    delay = context.dataIndex * 300 + context.datasetIndex * 100;
                }
                return delay;
            }
        },
        plugins: {
            legend: { position: 'top' },
            tooltip: {
    mode: 'index',
    intersect: false
}
        },
        scales: {
            y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => {
                                    return symbol + value.toLocaleString();
                                }
                            }
                        }
        }
    }
});

            })
            .catch(error => console.error('❌ Error fetching COA data:', error));
    }

  updateCustomerHeatmap() {
    const ctx = this.template.querySelector('.heatmap-overdue')?.getContext('2d');
    if (!ctx) return;

    getCustomerInvoiceSummary({ type: this.summaryView , organisationId: this.organisationId}) // 'Overdue' or 'Unpaid'
        .then(result => {
            const customers = result.labels;
            const amounts = result.amounts;
            const counts = result.counts;

            // Dummy third data series — replace with real data if needed
           // const otherMetric = result.otherMetric || customers.map(() => Math.floor(Math.random() * 5000));

            this.destroyChart('heatmap');
 const symbol = this.currencySymbol || ''; // fallback if not set
            this.chartInstances.heatmap = new window.Chart(ctx, {
                type: 'bar',
                data: {
                    labels: customers,
                    datasets: [
                        {
                            label: `Amount ${this.currencySymbol}`,
                            data: amounts,
                            backgroundColor: '#9D53F2 '
                        },
                        {
                            label: 'Count',
                            data: counts,
                            backgroundColor: '#3290ED'
                        }
                        // {
                        //     label: 'Other Metric',
                        //     data: otherMetric,
                        //     backgroundColor: '#26ABA4'
                        // }
                    ]
                },
                options: {
                    responsive: true,
                    indexAxis: 'x',
                    plugins: {
                        legend: {
                            position: 'top'
                        },
                        tooltip: {
                            mode: 'index',
                            intersect: false
                        }
                    },
                    scales: {
                        x: {
                            stacked: false,
                            beginAtZero: true
                        },
                        y: {
                            stacked: false,
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => {
                                    return symbol + value.toLocaleString();
                                }
                            }
                        }
                       
                    }
                }
            });
        })
        .catch(error => {
            console.error('Error loading invoice data:', error);
        });
}




//   // Handle year dropdown change
// handleCreditDebitYearChange(event) {
//     this.selectedCreditDebitYear = parseInt(event.target.value, 10);
//     this.updateCreditDebitChart(); // Replace with your chart refresh function
// }

  updateCreditDebitChart() {
    const ctx = this.template.querySelector('.bar-monthly-notes')?.getContext('2d');
    if (!ctx) {
        console.error('Chart context not found');
        return;
    }

    let delayed; // 👈 Delayed flag to control animation sequence

    getMonthlyCreditDebitSummary({ year: this.selectedYearforIncome ,  organisationId: this.organisationId })
        .then(result => {
            const months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];

            const credits = result.credits ?? [];
            const debits = result.debits ?? [];

            this.destroyChart('creditDebitBar');

            const symbol = this.currencySymbol || ''; // fallback if not set

            this.chartInstances.creditDebitBar = new window.Chart(ctx, {
                type: 'bar',
                data: {
                    labels: months,
                    datasets: [
                        {
                            label: `Credit Note Amount`,
                            data: credits,
                            backgroundColor: '#9D53F2 '
                        },
                        {
                            label: `Debit Note Amount`,
                            data: debits,
                            backgroundColor: '#3290ED'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    animation: {
                        onComplete: () => {
                            delayed = true;
                        },
                        delay: (context) => {
                            let delay = 0;
                            if (context.type === 'data' && context.mode === 'default' && !delayed) {
                                delay = context.dataIndex * 300 + context.datasetIndex * 100;
                            }
                            return delay;
                        }
                    },
                    plugins: {
                        legend: { position: 'bottom' },
                        tooltip: {
                            mode: 'index',
                            intersect: false
                        }
                    },
                    scales: {
                        x: {
                            stacked: true // 👈 Enable stacking on X-axis
                        },
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => {
                                    return symbol + value.toLocaleString();
                                }
                            }

                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('Error loading Credit/Debit data:', error);
        });
}



updateCreditDebitChartForFiscalYear() {
    const ctx = this.template.querySelector('.bar-monthly-notes')?.getContext('2d');
    if (!ctx) {
        console.error('Chart context not found');
        return;
    }

    let delayed; // Delayed flag to control animation sequence

    // Call Apex for fiscal year data
    getMonthlyCreditDebitSummaryForFiscalYear({ fiscalStartDate: this.selectedFiscalStartDate,  organisationId: this.organisationId })
        .then(result => {
           const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// Generate fiscal year labels dynamically with year
const fiscalStartMonth = new Date(this.selectedFiscalStartDate).getMonth(); // 0–11
const fiscalStartYear = new Date(this.selectedFiscalStartDate).getFullYear();
let fiscalLabels = [];

for (let i = 0; i < 12; i++) {
    const monthIndex = (fiscalStartMonth + i) % 12;
    const year = (monthIndex < fiscalStartMonth) ? fiscalStartYear + 1 : fiscalStartYear;
    fiscalLabels.push(`${monthNames[monthIndex]}-${year}`);
}


            const credits = result.credits || Array(12).fill(0);
            const debits = result.debits || Array(12).fill(0);

            // Destroy previous chart if exists
            if (this.chartInstances?.creditDebitBar) {
                this.chartInstances.creditDebitBar.destroy();
                this.chartInstances.creditDebitBar = null;
            }

            const symbol = this.currencySymbol || ''; // fallback if not set

            // Create new chart
            this.chartInstances.creditDebitBar = new window.Chart(ctx, {
                type: 'bar',
                data: {
                    labels: fiscalLabels,
                    datasets: [
                        {
                            label: 'Credit Note Amount',
                            data: credits,
                            backgroundColor: '#9D53F2'
                        },
                        {
                            label: 'Debit Note Amount',
                            data: debits,
                            backgroundColor: '#3290ED'
                        }
                    ]
                },
                options: {
                    responsive: true,
                    animation: {
                        onComplete: () => { delayed = true; },
                        delay: (context) => {
                            let delay = 0;
                            if (context.type === 'data' && context.mode === 'default' && !delayed) {
                                delay = context.dataIndex * 300 + context.datasetIndex * 100;
                            }
                            return delay;
                        }
                    },
                    plugins: {
                        legend: { position: 'bottom' },
                        tooltip: { mode: 'index', intersect: false }
                    },
                    scales: {
                        x: { stacked: true },
                        y: {
                            beginAtZero: true,
                            title: { display: true, text: 'Amount ' + symbol },
                            ticks: {
                                callback: (value) => symbol + value.toLocaleString()
                            }
                        }
                    }
                }
            });
        })
        .catch(error => {
            console.error('❌ Error loading Credit/Debit data:', error);
        });
}







    destroyChart(name) {
        if (this.chartInstances[name]) {
            this.chartInstances[name].destroy();
            this.chartInstances[name] = null;
        }
    }




       handleFromDateChange(event) {
        this.fromDate = event.target.value;
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
    }


loadIncomeExpenseChartsforfiscalyear() {
    console.log('🔄 Starting loadIncomeExpenseCharts with fromDate:', this.fromDate, 'toDate:', this.toDate);
    if (!this.fromDate || !this.toDate) {
        console.warn('⛔ Please select both From and To dates.');
        return;
    }

    this.showInitialCharts = false;
    this.showDetailedCharts = true;

    // ✅ Call both APIs (monthly + expense breakdown)
    Promise.all([
        getMonthlyIncomeExpensenew({ fromDate: this.fromDate, toDate: this.toDate, organisationId: this.organisationId }),
        getExpenseTypeBreakdown({ fromDate: this.fromDate, toDate: this.toDate, organisationId: this.organisationId })
    ])
    .then(([data, expenseTypeData]) => {
        console.log('📥 Chart Data received:', data);
        console.log('📊 Expense Type Breakdown received:', JSON.stringify(expenseTypeData));

        // --- Fiscal Labels ---
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const fiscalStartMonth = new Date(this.fromDate).getMonth(); // 0–11
        const fiscalStartYear = new Date(this.fromDate).getFullYear();

        let labels = [];
        for (let i = 0; i < 12; i++) {
            const monthIndex = (fiscalStartMonth + i) % 12;
            const year = (monthIndex < fiscalStartMonth) ? fiscalStartYear + 1 : fiscalStartYear;
            labels.push(`${monthNames[monthIndex]}-${year}`);
        }
        console.log('📋 Dynamic Labels set to:', labels);

        // --- Rotate arrays to align with fiscal start ---
        function rotateArray(arr, startIndex) {
            if (!arr) return Array(12).fill(0);
            return arr.slice(startIndex).concat(arr.slice(0, startIndex));
        }

        const paidIncome = rotateArray(data.paid.income, fiscalStartMonth);
        const paidExpense = rotateArray(data.paid.expense, fiscalStartMonth);
        const unpaidIncome = rotateArray(data.unpaid.income, fiscalStartMonth);
        const unpaidExpense = rotateArray(data.unpaid.expense, fiscalStartMonth);

        // --- Paid Chart ---
        this.renderBarChartforfiscalyear(
            '.paid-income-expense-chart',
            labels,
            paidIncome,
            paidExpense,
            'Paid Income',
            'Paid Expense',
            'paidChart'
        );

        // --- Unpaid Chart ---
        this.renderBarChartforfiscalyear(
            '.unpaid-income-expense-chart',
            labels,
            unpaidIncome,
            unpaidExpense,
            'Unpaid Income',
            'Unpaid Expense',
            'unpaidChart'
        );

        // --- Total Income vs Expense Pie ---
        const totalIncome = [...(data.paid.income || []), ...(data.unpaid.income || [])].reduce((a, b) => a + b, 0);
        const totalExpense = [...(data.paid.expense || []), ...(data.unpaid.expense || [])].reduce((a, b) => a + b, 0);
        console.log('💰 Total Income calculated:', totalIncome, 'Total Expense calculated:', totalExpense);

        this.renderPieChart2(
            '.total-income-expense-pie',
            ['Income', 'Expenses'],
            [totalIncome, totalExpense],
            ['#3290ED', '#9D53F2 '],
            'Total Income vs Expenses',
            'totalPie'
        );

        // --- Expense Type Breakdown Doughnut ---
        const expenseLabels = ['Expense Bill', 'PO Bill', 'Advance to Vendor', 'My Expenses'];
        const expenseColors = ['#9D53F2 ', '#3290ED', '#9c27b0', '#263eabff']; 
        const expenseData = [
            expenseTypeData?.totalExpenseBill || 0,
            expenseTypeData?.totalPOBill || 0,
            expenseTypeData?.totalAdvance || 0,
            expenseTypeData?.totalMyExpense || 0
        ];
        console.log('📊 Expense Data for Doughnut:', expenseData);

        this.renderPieChart2(
            '.expense-type-doughnut',
            expenseLabels,
            expenseData,
            expenseColors,
            'Expense Type Breakdown',
            'expenseTypeDonut'
        );

        console.log('✅ Charts rendered successfully for fiscal year.');
    })
    .catch(error => {
        console.error('❌ Error fetching chart data 123:', JSON.stringify(error));
    });
}








loadIncomeExpenseCharts() {
    console.log('🔄 Starting loadIncomeExpenseCharts with fromDate:', this.fromDate, 'toDate:', this.toDate);
    if (!this.fromDate || !this.toDate) {
        console.warn('⛔ Please select both From and To dates.');
        return;
    }

    this.showInitialCharts = false;
    this.showDetailedCharts = true;

    Promise.all([
        getMonthlyIncomeExpensenew({ fromDate: this.fromDate, toDate: this.toDate , organisationId: this.organisationId}),
        getExpenseTypeBreakdown({ fromDate: this.fromDate, toDate: this.toDate })
    ])
    .then(([data, expenseTypeData]) => {
        console.log('📥 Chart Data received:', data);
        console.log('📊 Expense Type Breakdown received:', JSON.stringify(expenseTypeData));

        const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        console.log('📋 Labels set to:', labels);

        // Paid Chart
        console.log('🎨 Rendering Paid Chart with income:', data.paid.income, 'expense:', data.paid.expense);
        this.renderBarChart(
            '.paid-income-expense-chart',
            labels,
            data.paid.income,
            data.paid.expense,
            'Paid Income',
            'Paid Expense',
            'paidChart'
        );

        // Unpaid Chart
        console.log('🎨 Rendering Unpaid Chart with income:', data.unpaid.income, 'expense:', data.unpaid.expense);
        this.renderBarChart(
            '.unpaid-income-expense-chart',
            labels,
            data.unpaid.income,
            data.unpaid.expense,
            'Unpaid Income',
            'Unpaid Expense',
            'unpaidChart'
        );

        // Total Income vs Expense Pie
        const totalIncome = [...data.paid.income, ...data.unpaid.income].reduce((a, b) => a + b, 0);
        const totalExpense = [...data.paid.expense, ...data.unpaid.expense].reduce((a, b) => a + b, 0);
        console.log('💰 Total Income calculated:', totalIncome, 'Total Expense calculated:', totalExpense);
        this.renderPieChart2(
            '.total-income-expense-pie',
            ['Income', 'Expenses'],
            [totalIncome, totalExpense],
            ['#3290ED', '#9D53F2 '],
            'Total Income vs Expenses',
            'totalPie'
        );

        // Expense Type Breakdown Doughnut
        const expenseLabels = ['Expense Bill', 'PO Bill', 'Advance to Vendor', 'My Expenses'];
        const expenseColors = ['#9D53F2 ', '#3290ED', '#9c27b0', '#263eabff']; // Aligned with getOverallExpenseBreakdown colors
        const expenseData = [
            expenseTypeData.totalExpenseBill || 0,
            expenseTypeData.totalPOBill || 0,
            expenseTypeData.totalAdvance || 0,
            expenseTypeData.totalMyExpense || 0
        ];
        console.log('📊 Expense Data for Doughnut:', expenseData);
        this.renderPieChart2(
            '.expense-type-doughnut',
            expenseLabels,
            expenseData,
            expenseColors,
            'Expense Type Breakdown',
            'expenseTypeDonut'
        );
    })
    .catch(error => {
        console.error('❌ Error fetching chart data:', error);
    });
}



renderBarChart(selector, labels, incomeData, expenseData, incomeLabel, expenseLabel, chartKey) {
    console.log('📊 Rendering Bar Chart for', selector, 'with income:', incomeData, 'expense:', expenseData);
    const ctx = this.template.querySelector(selector)?.getContext('2d');
    if (!ctx) return;

    this.destroyChart(chartKey);

    let delayed;

    const symbol = this.currencySymbol || ''; // fallback if not set
this.chartInstances[chartKey] = new window.Chart(ctx, {
    type: 'bar',
    data: {
        labels: labels,
        datasets: [
            {
                label: incomeLabel,
                data: incomeData,
                backgroundColor: '#3290ED'
            },
            {
                label: expenseLabel,
                data: expenseData,
                backgroundColor: '#9D53F2 '
            }
        ]
    },
    options: {
        responsive: true,
        animation: {
            onComplete: () => {
                delayed = true;
            },
            delay: (context) => {
                let delay = 0;
                if (context.type === 'data' && context.mode === 'default' && !delayed) {
                    delay = context.dataIndex * 300 + context.datasetIndex * 100;
                }
                return delay;
            }
        },
        plugins: {
            legend: { position: 'top' },
            title: {
                display: true,
                text: `${incomeLabel} vs ${expenseLabel}`
            },
            tooltip: {
    mode: 'index',
    intersect: false
}
        },
        scales: {
            y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'Amount ' + symbol
                            },
                            ticks: {
                                callback: (value) => {
                                    return symbol + value.toLocaleString();
                                }
                            }
                        }
        }
    }
});

}
renderBarChartforfiscalyear(selector, labels, incomeData, expenseData, incomeLabel, expenseLabel, chartKey) {
    console.log('📊 Rendering Bar Chart for', selector, 'with income:', incomeData, 'expense:', expenseData);

    const ctx = this.template.querySelector(selector)?.getContext('2d');
    if (!ctx) return;

    this.destroyChart(chartKey);

    let delayed;
    const symbol = this.currencySymbol || ''; // fallback if not set

    this.chartInstances[chartKey] = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                {
                    label: incomeLabel,
                    data: incomeData,
                    backgroundColor: '#3290ED'
                },
                {
                    label: expenseLabel,
                    data: expenseData,
                    backgroundColor: '#9D53F2'
                }
            ]
        },
        options: {
            responsive: true,
            animation: {
                onComplete: () => {
                    delayed = true;
                },
                delay: (context) => {
                    let delay = 0;
                    if (context.type === 'data' && context.mode === 'default' && !delayed) {
                        delay = context.dataIndex * 300 + context.datasetIndex * 100;
                    }
                    return delay;
                }
            },
            plugins: {
                legend: { position: 'top' },
                title: {
                    display: true,
                    text: `${incomeLabel} vs ${expenseLabel}`
                },
                tooltip: {
                    mode: 'index',
                    intersect: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Amount ' + symbol
                    },
                    ticks: {
                        callback: (value) => {
                            return symbol + value.toLocaleString();
                        }
                    }
                }
            }
        }
    });
}



loadInitialCharts() {
    console.log('🔄 Starting loadInitialCharts');
    getOverallIncomeAndExpenseTotals({organisationId: this.organisationId})
        .then(result => {
            console.log('💰 Overall Income and Expense Totals:', result);
            const labels = ['Income', 'Expenses'];
            const values = [result.totalIncome, result.totalExpense];
            const colors = ['#3290ED', '#9D53F2'];
            console.log('📊 Pie Chart Data:', { labels, values, colors });
            this.renderPieChart2('.total-income-expense-pie', labels, values, colors, 'Total Income vs Expenses');
        });

   getOverallExpenseBreakdown({organisationId: this.organisationId})
    .then(result => {
        console.log('📊 Overall Expense Breakdown:', JSON.stringify(result));
        const labels = ['Expense Bill', 'PO Bill', 'Advance to Vendor', 'My Expenses'];
        const values = [
            result.totalExpenseBill || 0,
            result.totalPOBill || 0,
            result.totalAdvance || 0,
            result.totalMyExpense || 0
        ];
        const colors = ['#9D53F2 ', '#3290ED', '#9c27b0', '#263eabff'];
        console.log('📊 Doughnut Chart Data:', { labels, values, colors });
        this.renderPieChart2('.expense-type-doughnut', labels, values, colors, 'Expense Type Breakdown');
    }); 
}

renderPieChart2(selector, labels, data, colors, title) {
    console.log('🖌️ Rendering Pie Chart2 for', selector, 'with data:', data);
    const ctx = this.template.querySelector(selector)?.getContext('2d');
    if (!ctx) return;

    const key = selector.replace('.', '');
    this.destroyChart(key);

  const symbol = this.currencySymbol || ''; // fallback if not set

this.chartInstances[key] = new window.Chart(ctx, {
    type: 'pie',
    data: {
        labels: labels,
        datasets: [{
            data: data,
            backgroundColor: colors
        }]
    },
    options: {
        responsive: true,
        plugins: {
            legend: { position: 'top' },
            title: {
                display: true,
                text: `${title} (${symbol})` // ← adds $, $, etc. in title
            },
            tooltip: {
                callbacks: {
                    label: function(context) {
                        const value = context.parsed || 0;
                        const label = context.label || '';
                        return `${label}: ${symbol}${value.toLocaleString()}`;
                    }
                }
            }
        }
    }
});

}



  loadGrandTotalData() {
        getChartOfAccountGrandTotal({organisationId: this.organisationId})
            .then(result => {
                this.chartData = result;
                this.renderPieChart();
            })
            .catch(error => {
                console.error('Error loading chart data', error);
            });
    }

    renderPieChart() {
        const ctx = this.template.querySelector('.pie-chart-budget').getContext('2d');
        const { approved = 0, consumed = 0, remaining = 0, committed = 0 } = this.chartData;

        const labels = ['Approved', 'Consumed', 'Remaining', 'Committed'];
        const data = [approved, consumed, remaining, committed];
         const colors = ['#9D53F2 ', '#3290ED', '#9c27b0', '#263eabff'];
        const symbol = this.currencySymbol;

        if (this.chartInstance) {
            this.chartInstance.destroy();
        }

        this.chartInstance = new window.Chart(ctx, {
            type: 'pie',
            data: {
                labels,
                datasets: [{
                    data,
                    backgroundColor: colors
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: `Budget Overview (${symbol})`
                    },
                    tooltip: {
                        callbacks: {
                            label: function (context) {
                                const value = context.parsed || 0;
                                const label = context.label || '';
                                return `${label}: ${symbol}${value.toLocaleString()}`;
                            }
                        }
                    }
                }
            }
        });
    }

    // Getters for formatted numbers with symbols
    get formattedApproved() {
        return this.formatNumber(this.chartData?.approved);
    }
    get formattedConsumed() {
        return this.formatNumber(this.chartData?.consumed);
    }
    get formattedRemaining() {
        return this.formatNumber(this.chartData?.remaining);
    }
    get formattedCommitted() {
        return this.formatNumber(this.chartData?.committed);
    }

    formatNumber(value) {
        const num = value || 0;
        return `${this.currencySymbol}${Number(num).toLocaleString()}`;
    }


 budgetPlanData() {
    getChartOfAccountTotals({organisationId: this.organisationId})
        .then(data => {
            console.log('📊 Grouped Budget Plan Data:', JSON.stringify(data));
            if (!data.length) {
                this.coaKeys = [];
                this.isGroupedChartVisible = false;
                return;
            }

            // Set flags
            this.isGroupedChartVisible = true;

            // Prepare arrays
            const labels = [];
            const approved = [];
            const consumed = [];
            const committed = [];
            const remaining = [];

            data.forEach(item => {
                labels.push(item.chartOfAccount || 'N/A');
                approved.push(item.approved || 0);
                consumed.push(item.consumed || 0);
                committed.push(item.committed || 0);
                remaining.push(item.remaining || 0);
            });

            // Ensure DOM is ready
            Promise.resolve().then(() => {
                this.renderGroupedBarChart(labels, approved, consumed, committed, remaining);
            });
        })
        .catch(error => {
            console.error('❌ Error loading budget data:', JSON.stringify(error));
        });
}



renderGroupedBarChart(labels, approved, consumed, committed, remaining) {
    const ctx = this.template.querySelector('canvas.grouped-bar-chart')?.getContext('2d');
    if (!ctx) {
        console.error('Canvas not found for grouped bar chart');
        return;
    }

    // Destroy old chart if exists
    if (this.chartInstances['grouped']) {
        this.chartInstances['grouped'].destroy();
    }

    this.isGroupedChartVisible = true;

   let delayed;

   const symbol = this.currencySymbol || ''; // fallback if not set

this.chartInstances['grouped'] = new window.Chart(ctx, {
    type: 'bar',
    data: {
        labels: labels,
        datasets: [
            { label: 'Approved', data: approved, backgroundColor: '#3290ED' },
            { label: 'Consumed', data: consumed, backgroundColor: '#9D53F2 ' },
            { label: 'Committed', data: committed, backgroundColor: '#26ABA4' },
            { label: 'Remaining', data: remaining, backgroundColor: '#4001d3ff' }
        ]
    },
    options: {
        responsive: true,
        animation: {
            onComplete: () => {
                delayed = true;
            },
            delay: (context) => {
                let delay = 0;
                if (context.type === 'data' && context.mode === 'default' && !delayed) {
                    delay = context.dataIndex * 300 + context.datasetIndex * 100;
                }
                return delay;
            }
        },
        plugins: {
            title: {
                display: true,
                text: 'Budget Summary by Chart of Account'
            },
            legend: {
                position: 'top'
            },
            tooltip: {
    mode: 'index',
    intersect: false
}
        },
        scales: {
            x: {
                stacked: false
            },
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Amount ' + symbol
                },
                ticks: {
                    callback: (value) => {
                        return symbol + value.toLocaleString();
                    }
                }
            }
        }
    }
});

}




handleChartOfAccountSelected(event) {
    console.log('🟡 handleChartOfAccountSelected triggered');
    console.log('📦 Event detail:', event.detail);

    this.selectedChartOfAccount = event.detail;

    if (this.selectedChartOfAccount?.Id) {
        console.log('✅ Selected COA ID:', this.selectedChartOfAccount.Id);
        console.log('✅ Selected COA Name:', this.selectedChartOfAccount.Name);

        // 👇 Hide the original grouped chart
        this.isGroupedChartVisible = true;

        // 👇 Fetch and show project-wise budget data
        this.fetchProjectBudgets(this.selectedChartOfAccount.Id);
        console.log('🔄 Fetching project budgets for COA:', this.selectedChartOfAccount.Id);

        // 👇 Reset selected project and pie chart visibility
        this.selectedProject = {};
        this.isSingleProjectChartVisible = false;

        // 👇 Fetch filtered projects for project lookup
        getProjectsByChartOfAccount({ chartOfAccountId: this.selectedChartOfAccount.Id, organisationId: this.organisationId })
            .then(projects => {
                console.log('📋 Filtered Projects:', projects);

                if (projects && projects.length > 0) {
                    const ids = projects.map(p => `'${p.id}'`);
                    this.projectFilter = `Id IN (${ids.join(',')})`;
                    console.log('📌 Applied Project Filter:', this.projectFilter);
                } else {
                    this.projectFilter = 'Id = null';
                    console.warn('⚠️ No projects found for selected COA');
                }
            })
            .catch(error => {
                console.error('❌ Error fetching filtered projects:', error);
                this.projectFilter = 'Id = null';
            });

    } else {
        console.warn('⚠️ No Chart of Account selected');
        this.isGroupedChartVisible = true;
        this.isProjectChartVisible = false;
        this.isSingleProjectChartVisible = false;
        this.projectFilter = 'Id = null';
    }

setTimeout(() => {
    this.scrolltoisProjectChartVisibleID;
},500);
   
}

scrolltoisProjectChartVisibleID(){
    console.log('Scroll of chart');
 const target = this.template.querySelector('[data-id="isProjectChartVisibleID"]');
   
    if (target) {
     setTimeout(() => {

            target.scrollIntoView({ behavior: 'smooth' });
        }, 500);
    } else {
        console.warn('📛 isProjectChartVisibleID not found!');
    }
}


handleProjectSelected(event) {
    console.log('🟡 handleProjectSelected triggered');
        this.selectedProject = event.detail;
    console.log('📦 Selected Project:', this.selectedProject);
        if (this.selectedProject?.Id && this.selectedChartOfAccount?.Id) {
            getSingleProjectBudget({
                chartOfAccountId: this.selectedChartOfAccount.Id,
                projectId: this.selectedProject.Id,
                organisationId: this.organisationId
            })
                .then(data => {
                    this.isProjectPieVisible = true;
                  setTimeout(() => {
    this.renderProjectPie(data);
}, 0);

                    console.log('🔄 Fetching project budget for:', this.selectedProject.Id);
                    console.log('📊 Project Budget Data:', JSON.stringify(data));
                })
                
                .catch(err => console.error('Pie chart load error:', err));
        }

         setTimeout(() => {
            this.scrolltoisProjectPieVisibleID();
        }, 500);
       
  
    }

    scrolltoisProjectPieVisibleID(){
          const target = this.template.querySelector('[data-id="isProjectPieVisibleID"]');
   console.log('📌 Scrolling to isProjectPieVisibleID');
    if (target) {
     setTimeout(() => {
            console.log('📌 Scrolling to target:', target);
            target.scrollIntoView({ behavior: 'smooth' });
        }, 500);
    } else {
        console.warn('📛 isProjectPieVisibleID not found!');
    }
    }

    handleProjectRemoved() {
        this.selectedProject = {};
        this.isProjectPieVisible = false;
        this.projectSelected = false;

    }

   renderProjectPie(data) {
    const ctx = this.template.querySelector('canvas.project-pie')?.getContext('2d');
    console.log('📊 Rendering Project Pie Chart with data:', JSON.stringify(data));

    if (!ctx) {
        console.warn('❌ Canvas with class `project-pie` not found');
        return;
    }

    // Destroy previous instance if it exists
    if (this.chartInstances.projectPieChart) {
        this.chartInstances.projectPieChart.destroy();
    }

    const symbol = this.currencySymbol || '';

    this.chartInstances.projectPieChart = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Total', 'Consumed', 'Committed', 'Remaining'],
            datasets: [{
                label: 'Amount',
                data: [data.total, data.consumed, data.committed, data.remaining],
                backgroundColor: ['#200079', '#9D53F2', '#26ABA4', '#2196f3']
            }]
        },
        options: {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: '📊 Project Budget Breakdown'
                },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    callbacks: {
                        label: function (context) {
                            const value = context.parsed.y || 0;
                            return `${context.dataset.label}: ${symbol}${value.toLocaleString()}`;
                        }
                    }
                },
                legend: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Amount (' + symbol + ')'
                    },
                    ticks: {
                        callback: value => symbol + value.toLocaleString()
                    }
                }
            }
        }
    });
}


fetchProjectBudgets(chartOfAccountId) {
    getProjectBudgetsByChartOfAccount({ chartOfAccountId })
    
        .then(data => {
            console.log('📊 Project Budgets Data:', JSON.stringify(data)); // ✅ confirmed already

            if (!data || data.length === 0) {
                this.isProjectChartVisible = false;
                console.warn('⚠️ No budget data found.');
                return;
            }

            this.isGroupedChartVisible = true;
            this.isProjectChartVisible = true;

            const labels = data.map(d => d.projectName);
            const totals = data.map(d => d.total);
            const consumed = data.map(d => d.consumed);
            const committed = data.map(d => d.committed);
            const remaining = data.map(d => d.remaining);

            console.log('📊 Labels:', labels);
            console.log('📊 Totals:', totals);
            console.log('📊 Consumed:', consumed);

            this.renderProjectChart(labels, totals, consumed, committed, remaining);
        })
        .catch(error => {
            console.error('❌ Error fetching project budgets:', JSON.stringify(error));
        });
}

renderProjectChart(labels, totals, consumed, committed, remaining) {
    // Wait until DOM updates are complete
    window.requestAnimationFrame(() => {
        const canvas = this.template.querySelector('canvas.project-chart');
        if (!canvas) {
            console.error('❌ Canvas not found for project chart.');
            return;
        }

        const ctx = canvas.getContext('2d');

        // Destroy old chart if exists
        this.destroyChart('projectBudgetChart');

        // Create new chart
       let delayed;

         const symbol = this.currencySymbol || ''; // fallback if not set
this.chartInstances.projectBudgetChart = new window.Chart(ctx, {
    type: 'bar',
    data: {
        labels: labels,
        datasets: [
            { label: 'Total', data: totals, backgroundColor: '#d80ab3ff' },
            { label: 'Consumed', data: consumed, backgroundColor: '#9D53F2 ' },
            { label: 'Committed', data: committed, backgroundColor: '#26ABA4' },
            { label: 'Remaining', data: remaining, backgroundColor: '#4001d3ff' }
        ]
    },
    options: {
        responsive: true,
        animation: {
            onComplete: () => {
                delayed = true;
            },
            delay: (context) => {
                let delay = 0;
                if (context.type === 'data' && context.mode === 'default' && !delayed) {
                    delay = context.dataIndex * 300 + context.datasetIndex * 100;
                }
                return delay;
            }
        },
        plugins: {
            title: {
                display: true,
                text: `Budget Summary by Project `
            },
            legend: {
                position: 'top'
            },
            tooltip: {
    mode: 'index',
    intersect: false
}
        },
        scales: {
            x: {
                stacked: false
            },
            y: {
                beginAtZero: true,
                title: {
                    display: true,
                    text: 'Amount ' + symbol
                },
                ticks: {
                    callback: (value) => {
                        return symbol + value.toLocaleString();
                    }
                }
            }
        }
    }
});

    });
}


loadChartDataforYearlySummary() {
    console.log('🔄 Starting loadChartDataforYearlySummary');
    getYearlyIncomeAndExpenseWithPrediction({organisationId: this.organisationId})
        .then(result => {
            console.log('📊 Yearly Data:', result);
            const years = result.years;
            const income = result.income;
            const expense = result.expense;
            const predictedIncome = result.predictedIncome;
            const predictedExpense = result.predictedExpense;

            console.log('📅 Years:', years);
            console.log('💰 Income Data:', income);
            console.log('📉 Expense Data:', expense);
            console.log('🔮 Predicted Income:', predictedIncome);
            console.log('🔮 Predicted Expense:', predictedExpense);

            this.renderChart(years, income, expense, predictedIncome, predictedExpense);
            console.log('✅ Yearly Chart Data Rendered');
        })
        .catch(error => {
            console.error('❌ Apex Error:', error);
        });
}

renderChart(labels, incomeData, expenseData, predictedIncome, predictedExpense) {
    const ctx = this.template.querySelector('.yearly-chart')?.getContext('2d');
    if (!ctx) {
        console.error('❌ Canvas context not found');
        return;
    }

    if (this.chart) {
        this.chart.destroy();
    }

    // Animation easing and delay logic
    const easing = window.Chart.helpers.easingEffects.easeOutQuad;
    const totalDuration = 5000;

    const duration = (ctx) => easing(ctx.index / labels.length) * totalDuration / labels.length;
    const delay = (ctx) => easing(ctx.index / labels.length) * totalDuration;
    const previousY = (ctx) =>
        ctx.index === 0
            ? ctx.chart.scales.y.getPixelForValue(100)
            : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;

    // Final animation block
    const animation = {
        x: {
            type: 'number',
            easing: 'linear',
            duration: duration,
            from: NaN,
            delay(ctx) {
                if (ctx.type !== 'data' || ctx.xStarted) return 0;
                ctx.xStarted = true;
                return delay(ctx);
            }
        },
        y: {
            type: 'number',
            easing: 'linear',
            duration: duration,
            from: previousY,
            delay(ctx) {
                if (ctx.type !== 'data' || ctx.yStarted) return 0;
                ctx.yStarted = true;
                return delay(ctx);
            }
        }
    };

    // Set currency symbol
    const symbol = this.currencySymbol || ''; // fallback if not set    

    // Chart data & config
    const data = {
        labels: labels.map(String),
        datasets: [
            {
                label: 'Income',
                fill: false,
                backgroundColor: '#26ABA4',
                borderColor: '#26ABA4',
                data: incomeData
            },
            {
                label: 'Expense',
                fill: false,
                backgroundColor: '#9D53F2',
                borderColor: '#9D53F2',
                data: expenseData
               
            },
            {
                label: 'Predicted Income (Holt’s)',
                fill: false,
                backgroundColor: '#81c784',
                borderColor: '#81c784',
                data: Array(labels.length - predictedIncome.length).fill(null).concat(predictedIncome),
                borderDash: [4, 4],
                pointRadius: 5
            },
            {
                label: 'Predicted Expense (Holt’s)',
                fill: false,
                backgroundColor: '#ef9a9a',
                borderColor: '#ef9a9a',
                data: Array(labels.length - predictedExpense.length).fill(null).concat(predictedExpense),
                borderDash: [4, 4],
                pointRadius: 5
            }
        ]
    };

    const config = {
        type: 'line',
        data: data,
        options: {
            responsive: true,
            animation: animation,
            plugins: {
                title: {
                    display: true,
                    text: 'Yearly Financial Summary with Holt’s Prediction'
                },
                legend: {
                    position: 'top'
                },
                tooltip: {
                    mode: 'index',
                    intersect: false
                }
            },
            interaction: {
                mode: 'index',
                intersect: false
            },
            scales: {
                x: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Year'
                    }
                },
                y: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Amount ' + symbol
                    },
                    ticks: {
                        callback: (value) => {
                            return symbol + value.toLocaleString();
                        }
                    },
                    beginAtZero: true
                }
            }
        }
    };

    this.chart = new window.Chart(ctx, config);
}




handleSimulateBudget() {
    console.log('🔄 Simulating budget...');
    this.isNewPlanning = true;
    this.isNewPlanningIn = false;
    this.isSimulatedBudgetVisible = true;

    getProjectIDs({organisationId: this.organisationId})
        .then((jsonString) => {
            const ids = JSON.parse(jsonString);
            this.filteredProjectIdList = ids; // ✅ Save the filtered list
            console.log('📌 Filtered Project IDs:', this.filteredProjectIdList);

            // Now continue with chart rendering
            setTimeout(() => {
                this.loadBudgetingExpenseChart();
                this.loadGrandTotalDataInitial();
            }, 0);        })
        .catch((error) => {
            console.error('❌ Error fetching project IDs:', error);
            this.filteredProjectIdList = [];
        });

       
}

closeModal() {
    console.log('🔄 Closing modal...');

    this.isSimulatedBudgetVisible = false;
    this.showModal = false;
   this.selectNewPlanning();

}


loadBudgetingExpenseChart() {
    const currentYear = new Date().getFullYear(); // 👈 current year

    getMonthlyExpensesOnly({ year: currentYear, organisationId: this.organisationId })
        .then(result => {
            const expenseData = result?.expense || [];
            const labels = this.allMonthLabels || ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

            this.expenseDataForChart = [...expenseData]; // Save for simulation updates
            this.expenseChartLabels = [...labels];

            this.renderChartForBudgeting(labels, expenseData);
        })
        .catch(error => {
            console.error('❌ Error loading budget-only expenses:', error);
        });
}


// renderChartForBudgeting(labels, expenseData, simulatedPoints = []) {
//     const ctx = this.template.querySelector('.budget-expense-line')?.getContext('2d');
//     if (!ctx) {
//         console.error('❌ Canvas context for budgeting not found');
//         return;
//     }

//     if (this.chartInstances.budgetExpenseChart) {
//         this.chartInstances.budgetExpenseChart.destroy();
//     }

//     const easing = window.Chart.helpers.easingEffects.easeOutQuad;
//     const totalDuration = 2000;

//     const duration = (ctx) => easing(ctx.index / labels.length) * totalDuration / labels.length;
//     const delay = (ctx) => easing(ctx.index / labels.length) * totalDuration;
//     const previousY = (ctx) =>
//         ctx.index === 0
//             ? ctx.chart.scales.y.getPixelForValue(0)
//             : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;

//     const animation = {
//         x: {
//             type: 'number',
//             easing: 'linear',
//             duration: duration,
//             from: NaN,
//             delay(ctx) {
//                 if (ctx.type !== 'data' || ctx.xStarted) return 0;
//                 ctx.xStarted = true;
//                 return delay(ctx);
//             }
//         },
//         y: {
//             type: 'number',
//             easing: 'linear',
//             duration: duration,
//             from: previousY,
//             delay(ctx) {
//                 if (ctx.type !== 'data' || ctx.yStarted) return 0;
//                 ctx.yStarted = true;
//                 return delay(ctx);
//             }
//         }
//     };

//     const symbol = this.currencySymbol || '';

//     const datasets = [
//         {
//             label: 'Expense',
//             fill: true,
//             backgroundColor: 'rgba(157, 83, 242, 0.1)',
//             borderColor: '#9D53F2',
//             data: expenseData,
//             tension: 0.3,
//             borderWidth: 2,
//             pointRadius: 0
//         }
//     ];

//     if (simulatedPoints && simulatedPoints.length) {
//         const simData = labels.map((label) => {
//             const match = simulatedPoints.find((p) => p.month === label);
//             return match ? match.amount : null;
//         });

//         console.log('🔄 Simulated Data Array:', simData);

//         datasets.push({
//             label: 'Adjusted Approvaled Amount',
//             data: simData,
//             borderColor: '#FF5733',
//             borderDash: [6, 6],
//             backgroundColor: 'rgba(255, 87, 51, 0.1)',
//             fill: false,
//             pointRadius: 6,
//             pointBackgroundColor: '#FF5733',
//             pointStyle: 'rectRot',
//             tension: 0.3,
//             borderWidth: 2
//         });
//     }

//     this.chartInstances.budgetExpenseChart = new window.Chart(ctx, {
//         type: 'line',
//         data: {
//             labels: labels.map(String),
//             datasets: datasets
//         },
//         options: {
//             responsive: true,
//             animation: animation,
//             plugins: {
//                 title: {
//                     display: true,
//                     text: 'Monthly Budgeted Expenses'
//                 },
//                 legend: {
//                     position: 'top'
//                 },
//                 tooltip: {
//                     mode: 'index',
//                     intersect: false
//                 }
//             },
//             interaction: {
//                 mode: 'index',
//                 intersect: false
//             },
//             scales: {
//                 x: {
//                     display: true,
//                     title: {
//                         display: true,
//                         text: 'Month'
//                     }
//                 },
//                 y: {
//                     display: true,
//                     title: {
//                         display: true,
//                         text: 'Amount ' + symbol
//                     },
//                     ticks: {
//                         callback: (value) => symbol + value.toLocaleString()
//                     },
//                     beginAtZero: true
//                 }
//             }
//         }
//     });
// }


renderChartForBudgeting(labels, expenseData, simulatedPoints = []) {
    const ctx = this.template.querySelector('.budget-expense-line')?.getContext('2d');
    if (!ctx) {
        console.error('❌ Canvas context for budgeting not found');
        return;
    }

    if (this.chartInstances.budgetExpenseChart) {
        this.chartInstances.budgetExpenseChart.destroy();
    }

    const easing = window.Chart.helpers.easingEffects.easeOutQuad;
    const totalDuration = 2000;

    const duration = (ctx) => easing(ctx.index / labels.length) * totalDuration / labels.length;
    const delay = (ctx) => easing(ctx.index / labels.length) * totalDuration;
    const previousY = (ctx) =>
        ctx.index === 0
            ? ctx.chart.scales.y.getPixelForValue(0)
            : ctx.chart.getDatasetMeta(ctx.datasetIndex).data[ctx.index - 1].getProps(['y'], true).y;

    const animation = {
        x: {
            type: 'number',
            easing: 'linear',
            duration: duration,
            from: NaN,
            delay(ctx) {
                if (ctx.type !== 'data' || ctx.xStarted) return 0;
                ctx.xStarted = true;
                return delay(ctx);
            }
        },
        y: {
            type: 'number',
            easing: 'linear',
            duration: duration,
            from: previousY,
            delay(ctx) {
                if (ctx.type !== 'data' || ctx.yStarted) return 0;
                ctx.yStarted = true;
                return delay(ctx);
            }
        }
    };

    const symbol = this.currencySymbol || '';

    // 🔥 FIX START — normalize all base labels to include current year
    const currentYear = new Date().getFullYear();
    labels = labels.map((lbl, idx) => {
        // if label already contains year (like "Dec 2025"), keep it
        if (lbl.includes(' ')) return lbl;

        // otherwise add current year
        const monthNum = idx + 1;
        const date = new Date(currentYear, monthNum - 1);
        const monthName = date.toLocaleString('default', { month: 'short' });
        return `${monthName} ${currentYear}`;
    });
    // 🔥 FIX END

    // Find max year/month from simulated points
    let maxSimYear = currentYear;
    let maxSimMonth = 12;

    if (simulatedPoints && simulatedPoints.length) {
        simulatedPoints.forEach((p) => {
            if (p.month && /^\d{4}-\d{2}$/.test(p.month)) {
                const [yearStr, monthStr] = p.month.split('-');
                const y = parseInt(yearStr, 10);
                const m = parseInt(monthStr, 10);
                if (y > maxSimYear || (y === maxSimYear && m > maxSimMonth)) {
                    maxSimYear = y;
                    maxSimMonth = m;
                }
            }
        });
    }

    // Extend chart labels dynamically if simulated months go beyond current year
    let extendedLabels = [...labels];
    if (maxSimYear > currentYear) {
        const nextMonths = [];
        for (let y = currentYear + 1; y <= maxSimYear; y++) {
            const limit = y === maxSimYear ? maxSimMonth : 12;
            for (let m = 1; m <= limit; m++) {
                const monthName = new Date(y, m - 1).toLocaleString('default', {
                    month: 'short',
                    year: 'numeric'
                });
                nextMonths.push(monthName);
            }
        }
        extendedLabels = [...labels, ...nextMonths];
    }

    // ✅ Deduplicate and sort labels to remove duplicates like “Dec” + “Dec 2025”
    extendedLabels = Array.from(new Set(extendedLabels));
    extendedLabels.sort((a, b) => {
        const toDate = (lbl) => {
            const [monthName, yearStr] = lbl.split(' ');
            return new Date(`${monthName} 1, ${yearStr}`);
        };
        return toDate(a) - toDate(b);
    });

    labels = extendedLabels;
    console.log('📆 Final Labels:', labels);

    // Build adjusted approved amount data
    const simData = labels.map((label) => {
        const [monthName, year] = label.split(' ');
        const monthNum = new Date(`${monthName} 1, ${year}`).getMonth() + 1;
        const key = `${year}-${String(monthNum).padStart(2, '0')}`;
        const match = simulatedPoints.find((p) => p.month === key);
        return match ? Number(match.amount) : null;
    });

    console.log('🔄 Simulated Data Array:', simData);

    // Grouped bar datasets
    const datasets = [
        {
            label: 'Expense',
            backgroundColor: '#9D53F2',
            borderColor: '#7A3FC2',
            borderWidth: 1,
            data: expenseData,
            barThickness: 24
        },
        {
            label: 'Adjusted Approved Amount',
            backgroundColor: 'rgba(255, 87, 51, 0.8)',
            borderColor: '#FF5733',
            borderWidth: 1,
            data: simData,
            barThickness: 24
        }
    ];

    // Render grouped bar chart
    this.chartInstances.budgetExpenseChart = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels.map(String),
            datasets: datasets
        },
        options: {
            responsive: true,
            animation: animation,
            plugins: {
                title: {
                    display: true,
                    text: 'Monthly Budgeted Expenses'
                },
                legend: { position: 'top' },
                tooltip: {
                    mode: 'index',
                    intersect: false,
                    callbacks: {
                        label: function (context) {
                            const val = context.parsed.y;
                            return `${context.dataset.label}: ${symbol}${val?.toLocaleString() || 0}`;
                        }
                    }
                }
            },
            interaction: {
                mode: 'index',
                intersect: false
            },
            scales: {
                x: {
                    display: true,
                    title: { display: true, text: 'Month' },
                    grid: { display: false }
                },
                y: {
                    display: true,
                    title: { display: true, text: `Amount (${symbol})` },
                    ticks: {
                        callback: (value) => symbol + value.toLocaleString()
                    },
                    beginAtZero: true
                }
            }
        }
    });
}

  loadGrandTotalDataInitial() {
        getChartOfAccountGrandTotal({organisationId: this.organisationId})
            .then(result => {
                this.chartData = result;
                this.renderGroupedBarChartInitial(
                    ['Total'], // only one label for now
                    [result.approved || 0],
                    [result.consumed || 0],
                    [result.committed || 0],
                    [result.remaining || 0]
                );
            })
            .catch(error => {
                console.error('Error fetching grand total:', error);
            });
    }


exportToExcel() {
    console.log('⬇️ Initiating Excel export of simulation data...');

    if (!Array.isArray(this.simRows) || this.simRows.length === 0) {
        console.warn('⚠️ No simulation data to export.');
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'No Data',
                message: 'Please add at least one simulation row before exporting.',
                variant: 'warning'
            })
        );
        return;
    }

    // 🏷️ Project Title
    const projectName = this.simulatedProject?.Name || 'Budget Summary';
    const symbol = this.currencySymbol || '$';

    console.log(`📌 Project Name: ${projectName}`);
    console.log(`💱 Currency Symbol: ${symbol}`);

    // 🧾 CSV Header Labels
    const headers = [
        'SL.No',
        'Approved Amount (' + symbol + ')',
        'Remaining Amount (' + symbol + ')',
        'Expense Description',
        'Month',
        'Additional Allocation Amount (' + symbol + ')',
        'Total Approved Amount (' + symbol + ')'
    ];

    // 🧠 Prepare Excel body
    let csv = `Budget Name: ${projectName}\n`;              // Title row
    csv += headers.join(',') + '\n';                    // Column headers

    const approved = parseFloat(this.selectedApproved || 0);
    const remaining = parseFloat(this.selectedRemaining || 0);

    console.log('🟦 Selected Approved:', approved);
    console.log('🟩 Selected Remaining:', remaining);

    // 🛠️ Build each row
    this.simRows.forEach((row, index) => {
        const extra = parseFloat(row.additionalAllocation || 0);
        const total = approved + extra;
        const rowDesc = (row.statement || '').replace(/"/g, '""'); // Escape double quotes

        const rowData = [
            index + 1,
            `${symbol}${approved}`,
            `${symbol}${remaining}`,
            `"${rowDesc}"`,
            row.month || 'N/A',
            `${symbol}${extra}`,
            `${symbol}${total}`
        ];

        console.log(`📤 Row ${index + 1}:`, rowData);
        csv += rowData.join(',') + '\n';
    });

    console.log('✅ Final CSV Content:\n' + csv);

    // 📦 Trigger file download
    const encodedUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);

    const fileName = `Simulation_Export_${new Date().toISOString().split('T')[0]}.csv`;
    link.setAttribute('download', fileName);

    document.body.appendChild(link);

    setTimeout(() => {
        link.click();
        document.body.removeChild(link);
        console.log(`📁 Download triggered: ${fileName}`);
    }, 50);
}



}