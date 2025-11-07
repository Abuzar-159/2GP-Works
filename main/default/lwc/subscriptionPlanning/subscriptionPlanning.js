import { LightningElement, track, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import chartJs from '@salesforce/resourceUrl/ChartJS';
import { NavigationMixin } from 'lightning/navigation';
import getSubscribedProducts from '@salesforce/apex/subscriptionPlanning.getSubscribedProducts';
import getSubscribedOrderItems from '@salesforce/apex/subscriptionPlanning.getSubscribedOrderItems'
import getSubscriptionStatusCounts from '@salesforce/apex/subscriptionPlanning.getSubscriptionStatusCounts';
import getTopSubscribedProducts from '@salesforce/apex/subscriptionPlanning.getTopSubscribedProducts';

export default class SubscriptionPlanning extends NavigationMixin(LightningElement) {

        @api organisationId;

    @track isSubscribedProducts = false;
    @track isProductsOrderSummary = false;
    @track isSubscriptionAnalytics = true;
    @track isSubscriptionManagement = false;
    @track products = [];
    @track orderItems = [];
    @track error;
    @track statusCounts = [];



    
        get subscribedProducts() {
            return this.isSubscribedProducts ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
        }

        get productsOrderSummary() {
            return this.isProductsOrderSummary ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
        }

        get subscriptionAnalytics() {
            return this.isSubscriptionAnalytics ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';
        }

        get subscriptionManagement() {
            return this.isSubscriptionManagement ? 'sub-tab-horizontal active' : 'sub-tab-horizontal';  
        }


        selectSubscribedProducts() {
            this.isSubscribedProducts = true;
            this.isProductsOrderSummary = false;
            this.isSubscriptionAnalytics = false;
            this.isSubscriptionManagement = false;

           
        }

        selectProductsOrderSummary() {
            this.isSubscribedProducts = false;
            this.isProductsOrderSummary = true;
            this.isSubscriptionAnalytics = false;
            this.isSubscriptionManagement = false;
            this.getSubscribedProductSummary();
           
        }

        selectSubscriptionAnalytics() {
            this.isSubscribedProducts = false;
            this.isProductsOrderSummary = false;
            this.isSubscriptionAnalytics = true;
            this.isSubscriptionManagement = false;
            this.initializeChart();
            console.log('called initializeChart');
        }

        selectSubscriptionManagement() {
            this.isSubscribedProducts = false;
            this.isProductsOrderSummary = false;
            this.isSubscriptionManagement = true;
            this.isSubscriptionAnalytics = false;
        }

      connectedCallback() {
    // 🔹 Fetch data from Apex
    getSubscribedProducts()
        .then(result => {
            this.products = result;
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.products = [];
            console.error('❌ Error loading products:', error);
        });
}

renderedCallback() {
    // 🔹 Load Chart.js only once
    if (this.isChartJsInitialized) return;
    this.isChartJsInitialized = true;

    loadScript(this, chartJs)
        .then(() => {
            console.log('✅ Chart.js loaded');
            // You can now call your chart rendering function here if needed
        })
        .catch(error => {
            console.error('❌ Error loading Chart.js:', error);
        });
    this.initializeChart();
  
}







        getSubscribedProductSummary() {
            console.log('Fetching subscribed product summary...');
            // Call your Apex method to get the product summary
            getSubscribedOrderItems({organisationId : this.organisationId})
                .then(result => {
                    this.orderItems = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.orderItems = [];
                    console.error('Error loading product summary:', error);
                });
        }


        handleCreateProduct() {
            // Redirect, open modal, or custom logic
            console.log('Create Product clicked');
            // Example: Navigate to Product2 new record page
            window.open('/lightning/o/Product2/new', '_blank');
        }



        initializeChart() {
            this.loadSubscriptionChart();
            this.loadTopProductsChart();

        }
        
 loadSubscriptionChart() {
        getSubscriptionStatusCounts({organisationId : this.organisationId})
            .then(data => {
                this.statusCounts = data;
                this.renderStatusChart();
            })
            .catch(error => {
                console.error('❌ Error fetching subscription status counts:', error);
            });
    }
renderStatusChart() {
    const ctx = this.template.querySelector('canvas.subscription-chart').getContext('2d');

    // ✅ Fixed order
    const order = ['Active', 'On Hold', 'Cancelled'];

    // Ensure each status exists in the data
    const sortedData = order.map(status => {
        const found = this.statusCounts.find(item => item.status === status);
        return {
            status: status,
            count: found ? found.count : 0
        };
    });

    const labels = sortedData.map(item => item.status);
    const counts = sortedData.map(item => item.count);

    if (this.chartInstance) {
        this.chartInstance.destroy();
    }

    this.chartInstance = new window.Chart(ctx, {
        type: 'pie',
        data: {
            labels: labels,
            datasets: [{
                data: counts,
                backgroundColor: ['#263eabff', '#9c27b0', '#9D53F2'], // matching fixed order
                borderColor: '#fff',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: '📊 Subscription Status Breakdown'
                },
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            let value = context.parsed;
                            return `${context.label}: ${value}`;
                        }
                    }
                },
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}




loadTopProductsChart() {
    getTopSubscribedProducts({organisationId : this.organisationId})
        .then(data => {
            this.topProducts = data;
            this.renderTopProductsChart();
        })
        .catch(error => {
            console.error('❌ Error fetching top subscribed products:', error);
        });
}

renderTopProductsChart() {
    const ctx = this.template.querySelector('canvas.top-products-chart')?.getContext('2d');
    if (!ctx) {
        console.error('Canvas not found for Top Products Chart');
        return;
    }

    if (this.topProductsChartInstance) {
        this.topProductsChartInstance.destroy();
    }

    const labels = this.topProducts.map(item => item.productName);
    const counts = this.topProducts.map(item => item.count);
    const colors = ['#263eabff', '#3290ED', '#9c27b0', '#9D53F2', '#5436fdff'];

    this.topProductsChartInstance = new window.Chart(ctx, {
        type: 'bar',
        data: {
            labels, // Product names on X-axis
            datasets: [
                {
                    label: 'Top 5 Subscribed Products', // ✅ Fixed: single label instead of array
                    data: counts,
                    backgroundColor: colors
                }
            ]
        },
        options: {
            responsive: true,
            plugins: {
              
                legend: {
                    display: true,
                    position: 'top'
                },
                tooltip: {
                    callbacks: {
                        label: function (context) {
                            return `${context.label}: ${context.parsed.y}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    beginAtZero: true
                },
                y: {
                    beginAtZero: true,
                    ticks: { stepSize: 1 }
                }
            }
        }
    });
}



}