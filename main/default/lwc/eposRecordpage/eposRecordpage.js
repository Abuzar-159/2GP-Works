import { LightningElement, api, track } from 'lwc';

// Apex from existing EPOS
import getInitialData from '@salesforce/apex/Epos.fetchInitailDetails';
import getAccountDetails from '@salesforce/apex/Epos.fetchAccDetails';
import getContactDetails from '@salesforce/apex/Epos.fetchContactDetails';
import getBillToAddress from '@salesforce/apex/Epos.billToAddress';
import getShipToAddress from '@salesforce/apex/Epos.shipToAddress';
import getOrderProfile from '@salesforce/apex/Epos.OrderProfile';
import getCurrentEmployee from '@salesforce/apex/Epos.currentEmp';
import getInitialProducts from '@salesforce/apex/Epos.initialProducts';
import initialProductsByDC from '@salesforce/apex/Epos.initialProductsByDC';
import getDistributionChannels from '@salesforce/apex/Epos.getDistributionChannels';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveOrderAndLine from '@salesforce/apex/Epos.saveOrderAndLines1';
import { NavigationMixin } from 'lightning/navigation';

export default class AccountOrderTabs extends NavigationMixin(LightningElement) {
    @api recordId;

    // main tab state (for future tabs; currently only order)
    activeTab = 'order';

    @track order = {
        Status: 'Draft',
        Is_Back_Order__c: false,
        Is_Pre_Order__c: false,
        Is_Closed__c: false,
        Issue_Invoice__c: false,
        Sub_Total__c: 0,
        Due_Amount__c: 0
    };

    // lookup selected flags + URLs
    @track contactSelected = false;
    @track billToSelected = false;
    @track shipToSelected = false;
    @track orderProfileSelected = false;
    @track employeeSelected = false;
    @track projectSelected = false;

    contactUrl;
    billToUrl;
    shipToUrl;
    orderProfileUrl;
    employeeUrl;

    // collapsibles
    showContact = true;
    showOrderDetails = true;
    showProducts = true;

    contactChevronIcon = 'utility:chevrondown';
    orderDetailsChevronIcon = 'utility:chevrondown';
    productsChevronIcon = 'utility:chevrondown';

    // filters for lookups
    contactFilter = '';
    billToFilter = '';
    shipToFilter = '';
    orderProfileFilter = '';
    employeeFilter = " AND Employee_User__c != null AND Active__c=true ";
    @track dcOptions = [];

    // display address strings
    billToAddFull;
    shipToAddFull;

    // picklist data
    allCurrencies;
    shipmentType;
    ordStatusData;
    ordStatus;

    // misc
    spinner = false;
    @track modalSpinner = false;
    @track errorList = [];

    // edit product modal
    @track isEditOrderItem = false;
    @track orderItemToEdit;
    orderItemEditIndex;

    // delete confirmation
    @track deleteConfirmation = false;
    indexToDel;

    isMultiCurrency = false;
    itemsToDel = [];

    // products / modal
    @track showAddProductsModal = false;
    @track listOfProducts = [];
    @track listOfCheckedProucts = []; // keep selected across search
    searchItem = '';
    @track selectedProducts = [];

    // ===== tab getters =====
    get isOrder() {
        return this.activeTab === 'order';
    }

    // ===== lifecycle =====
    connectedCallback() {
        console.log('AccountOrderTabs loaded with recordId:', this.recordId);
        this.initOrderSkeleton();
        this.loadInitialData();
    }

    initOrderSkeleton() {
        // make sure nested refs exist so bindings don’t explode
        this.order.Account = { Id: this.recordId || '', Name: '' };
        this.order.Contact__r = { Id: '', Name: '', Email: '', Phone: '' };
        this.order.Bill_To_Address__r = { Id: '', Name: '' };
        this.order.Ship_To_Address__r = { Id: '', Name: '' };
        this.order.Order_Profile__r = { Id: '', Name: '' };
        this.order.Employee__r = { Id: '', Name: '' };
        this.order.Project__r = { Id: '', Name: '' };
    }


    handleProductsResponse(data) {
        this.listOfProducts = data.map(prod => {
            const rawStock = prod.stock; // could be number or 'Back Order' or 'Kit'
            let displayStock = rawStock;
            let levelClass = 'stock-pill--ok';  // default
            let numericStock = null;

            // Special text cases first
            if (rawStock === 'Back Order') {
                levelClass = 'stock-pill--backorder';
            } else if (rawStock === 'Kit') {
                levelClass = 'stock-pill--kit';
            } else {
                // Normal numeric stock
                numericStock = Number(rawStock);
                displayStock = numericStock; // what we show in {prod.stock}

                if (numericStock === 0) {
                    levelClass = 'stock-pill--none';
                } else if (numericStock > 0 && numericStock <= 10) {
                    levelClass = 'stock-pill--low';
                } else if (numericStock > 10 && numericStock <= 50) {
                    levelClass = 'stock-pill--medium';
                } // else keep --ok
            }

            const stockClass = `stock-pill ${levelClass}`;

            console.log(
                'Product:',
                prod.pbe?.Product2?.Name,
                '| rawStock:',
                rawStock,
                '| displayStock:',
                displayStock,
                '| class:',
                stockClass
            );

            return {
                ...prod,
                stock: displayStock, // this is what {prod.stock} shows
                stockClass,
                selectedDC: prod.selectedDC || 'All'
            };
        });
    }



    // ===== data loading =====
    loadInitialData() {
        this.spinner = true;
        getInitialData()
            .then(result => {
                console.log('Initial data:', result);
                this.errorList = result.error || [];

                this.order.EffectiveDate = result.todayDate; // default effective date = today
                this.ordStatusData = result.ordStatus;

                if (this.order.Id) {
                    this.ordStatus = this.ordStatusData;
                } else {
                    this.ordStatus = [
                        {
                            label: this.ordStatusData[0].label,
                            value: this.ordStatusData[0].value
                        }
                    ];
                }

                this.shipmentType = result.ShipmentType;

                // default employee from initial data
                this.order.Employee__c = result.currEmp?.Id;
                this.order.Employee__r = result.currEmp;
                if (result.currEmp) {
                    this.employeeSelected = true;
                    this.employeeUrl = `/lightning/r/Employees__c/${result.currEmp.Id}/view`;
                }

                if (this.recordId) {
                    this.order.AccountId = this.recordId;

                    this.contactFilter =
                        " AND AccountId='" + this.order.AccountId + "'";
                    this.billToFilter =
                        " AND Customer__c='" +
                        this.order.AccountId +
                        "' AND Is_Billing_Address__c=true AND Active__c=true ";
                    this.shipToFilter =
                        " AND Customer__c='" +
                        this.order.AccountId +
                        "' AND Is_Shipping_Address__c=true AND Active__c=true ";

                    this.loadAccountDetails();
                }
            })
            .catch(error => {
                console.error('Error in getInitialData:', error);
                this.pushError(error);
            })
            .finally(() => {
                this.spinner = false;
            });
    }

    loadAccountDetails() {
        if (!this.order.AccountId) return;

        this.spinner = true;
        getAccountDetails({ accId: this.order.AccountId })
            .then(result => {
                console.log('Account details:', result);
                this.errorList = result.error || [];

                this.allCurrencies = result.allCurrencies;
                this.isMultiCurrency = result.isMultiCurrency;
                this.order.CurrencyIsoCode = result.orderCurrency;
                this.order.Account = JSON.parse(JSON.stringify(result.acc));

                // Order Profile & filter
                if (this.order.Account.Account_Profile__c) {
                    this.orderProfileFilter =
                        " AND Account_Profile__c = '" +
                        this.order.Account.Account_Profile__c +
                        "' and Active__c = true WITH SECURITY_ENFORCED ";
                } else {
                    this.orderProfileFilter =
                        " AND Channel__c != null and Price_Book__c != null and RecordType.DeveloperName='Order_Profile' and Active__c = true WITH SECURITY_ENFORCED ";
                }

                if (result.custProfile) {
                    this.order.Order_Profile__c = result.custProfile.Id;
                    this.order.Order_Profile__r = result.custProfile;

                    this.orderProfileSelected = true;
                    this.orderProfileUrl = `/lightning/r/Profiling__c/${result.custProfile.Id}/view`;
                }

                // default Contact
                if (result.con) {
                    this.order.Contact__c = result.con.Id;
                    this.order.Contact__r = result.con;
                    this.contactSelected = true;
                    this.contactUrl = `/lightning/r/Contact/${result.con.Id}/view`;
                }

                // Bill To
                if (result.billToAdd) {
                    this.order.Bill_To_Address__c = result.billToAdd.Id;
                    this.order.Bill_To_Address__r = result.billToAdd;
                    this.billToAddFull = this.addressGenerator(result.billToAdd);

                    this.billToSelected = true;
                    this.billToUrl = `/lightning/r/Address__c/${result.billToAdd.Id}/view`;
                }

                // Ship To
                if (result.shipToAdd) {
                    this.order.Ship_To_Address__c = result.shipToAdd.Id;
                    this.order.Ship_To_Address__r = result.shipToAdd;
                    this.shipToAddFull = this.addressGenerator(result.shipToAdd);

                    this.shipToSelected = true;
                    this.shipToUrl = `/lightning/r/Address__c/${result.shipToAdd.Id}/view`;
                }
            })
            .catch(error => {
                console.error('Error in getAccountDetails:', error);
                this.pushError(error);
            })
            .finally(() => {
                this.spinner = false;
            });
    }

    // ===== helpers =====
    addressGenerator(address) {
        try {
            let fullAddress = '';
            if (address.Address_Line1__c) fullAddress = address.Address_Line1__c;
            if (address.Address_Line2__c) fullAddress += ', ' + address.Address_Line2__c;
            if (address.Address_Line3__c) fullAddress += ', ' + address.Address_Line3__c;
            if (address.City__c) fullAddress += ', ' + address.City__c;
            if (address.State__c) fullAddress += ', ' + address.State__c;
            if (address.Postal_Code__c) fullAddress += ', ' + address.Postal_Code__c;
            if (address.Country__c) fullAddress += ', ' + address.Country__c + '.';
            return fullAddress;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    pushError(error) {
        try {
            const msg = error?.body?.message || error?.message || JSON.stringify(error);
            this.errorList = [...this.errorList, msg];
        } catch (e) {
            console.error('Error while pushing error:', e);
        }
    }

    // ===== lookup handlers =====
    selectContact(event) {
        try {
            this.spinner = true;
            this.order.Contact__c = event.detail.Id;

            if (this.order.Contact__c) {
                getContactDetails({ contId: this.order.Contact__c })
                    .then(result => {
                        if (result) {
                            this.order.Contact__r = result;
                        }
                    })
                    .catch(error => {
                        console.error('Error in getContactDetails:', error);
                        this.pushError(error);
                    })
                    .finally(() => {
                        this.spinner = false;
                    });
            } else {
                this.spinner = false;
            }
        } catch (e) {
            console.error('selectContact error:', e);
        }
    }

    selectBillTo(event) {
        try {
            this.order.Bill_To_Address__c = event.detail.Id;
            if (this.order.Bill_To_Address__c) {
                getBillToAddress({ addId: this.order.Bill_To_Address__c })
                    .then(result => {
                        if (result) {
                            this.order.Bill_To_Address__r = result;
                            this.billToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.error('Error in getBillToAddress:', error);
                        this.pushError(error);
                    });
            }
        } catch (e) {
            console.error('selectBillTo error:', e);
        }
    }

    selectShipTo(event) {
        try {
            this.order.Ship_To_Address__c = event.detail.Id;
            if (this.order.Ship_To_Address__c) {
                getShipToAddress({ addId: this.order.Ship_To_Address__c })
                    .then(result => {
                        if (result) {
                            this.order.Ship_To_Address__r = result;
                            this.shipToAddFull = this.addressGenerator(result);
                        }
                    })
                    .catch(error => {
                        console.error('Error in getShipToAddress:', error);
                        this.pushError(error);
                    });
            }
        } catch (e) {
            console.error('selectShipTo error:', e);
        }
    }

    selectOrderProfile(event) {
        try {
            this.order.Order_Profile__c = event.detail.Id;
            if (event.detail.Id) {
                getOrderProfile({ ordProfileId: event.detail.Id })
                    .then(result => {
                        this.order.Order_Profile__r = result;
                    })
                    .catch(error => {
                        console.error('Error in getOrderProfile:', error);
                        this.pushError(error);
                    });
            }
        } catch (e) {
            console.error('selectOrderProfile error:', e);
        }
    }

    selectEmployee(event) {
        try {
            this.order.Employee__c = event.detail.Id;
            if (this.order.Employee__c) {
                getCurrentEmployee({ empId: this.order.Employee__c })
                    .then(result => {
                        if (result) {
                            this.order.Employee__r = result;
                        }
                    })
                    .catch(error => {
                        console.error('Error in getCurrentEmployee:', error);
                        this.pushError(error);
                    });
            }
        } catch (e) {
            console.error('selectEmployee error:', e);
        }
    }

    selectProject(event) {
        try {
            this.order.Project__c = event.detail.Id;
            this.order.Project__r = {
                Id: event.detail.Id,
                Name: event.detail.Name
            };
        } catch (e) {
            console.error('selectProject error:', e);
        }
    }

    // ===== field handlers =====
    handleCurrency(event) {
        this.order.CurrencyIsoCode = event.detail.value;
    }

    handleEffDate(event) {
        this.order.EffectiveDate = event.detail.value;
    }

    handleExpDate(event) {
        this.order.Expected_Date__c = event.detail.value;
    }

    handleChangeShipment(event) {
        this.order.Shipment_Type__c = event.detail.value;
    }

    handleChangeStatus(event) {
        this.order.Status = event.detail.value;
    }

    handleOrdRef(event) {
        this.order.OrderReferenceNumber = event.target.value;
    }

    handleOrdDescription(event) {
        this.order.Special_Instructions__c = event.target.value;
    }

    handleIssInv(event) {
        this.order.Issue_Invoice__c = event.detail.checked;
    }

    // ===== collapsible handlers =====
    toggleContact() {
        this.showContact = !this.showContact;
        this.contactChevronIcon = this.showContact
            ? 'utility:chevrondown'
            : 'utility:chevronright';
    }

    toggleOrderDetails() {
        this.showOrderDetails = !this.showOrderDetails;
        this.orderDetailsChevronIcon = this.showOrderDetails
            ? 'utility:chevrondown'
            : 'utility:chevronright';
    }

    toggleProducts() {
        this.showProducts = !this.showProducts;
        this.productsChevronIcon = this.showProducts
            ? 'utility:chevrondown'
            : 'utility:chevronright';
    }

    // ===== Add Products Modal =====
    showAddProductsPage() {
        try {
            this.errorList = [];

            if (!this.order.Order_Profile__c) {
                this.errorList = [...this.errorList, 'Select Order Profile first'];
                return;
            }

            this.showAddProductsModal = true;

            // Fetch Distribution Channels if not already loaded
            let channelId = this.order.Channel__c || (this.order.Order_Profile__r ? this.order.Order_Profile__r.Channel__c : null);

            if (channelId) {
                getDistributionChannels({ channelId: channelId })
                    .then(result => {
                        // Default "All" option
                        let options = [{ label: 'All', value: 'All' }];

                        // Map result to options
                        if (result && result.length > 0) {
                            result.forEach(dc => {
                                // Adjust property names based on your Apex Wrapper return (e.g., dc.dcName vs dc.Name)
                                options.push({ label: dc.dcName || dc.Name, value: dc.dcId || dc.Id });
                            });
                        }
                        this.dcOptions = options;
                    })
                    .catch(error => {
                        console.error('Error fetching DCs', error);
                    });
            }

            // initial load with empty search
            this.fetchProducts({
                currentTarget: { value: '' }
            });
        } catch (e) {
            console.error('showAddProductsPage error:', e);
        }
    }

    closeAddProducts() {
        this.showAddProductsModal = false;
    }

    fetchProducts(event) {
        try {
            this.modalSpinner = true;
            this.searchItem = event.currentTarget.value;
            console.log('searchItem:', this.searchItem);

            if (!this.listOfCheckedProucts) {
                this.listOfCheckedProucts = [];
            }

            getInitialProducts({
                currProfile: JSON.stringify(this.order.Order_Profile__r),
                billToAddId: this.order.Bill_To_Address__c,
                shipToAddId: this.order.Ship_To_Address__c,
                searchItem: this.searchItem
            })
                .then(result => {
                    let res = JSON.parse(JSON.stringify(result));

                    if (res.length > 0) {
                        for (let i in res) {
                            if (res[i].stock == 0 && res[i].pbe.Product2.Allow_Back_Orders__c)
                                res[i].stock = 'Back Order';

                            if (res[i].pbe.Product2.Is_Kit__c)
                                res[i].stock = 'Kit';

                            const alreadySelected = this.listOfCheckedProucts.find(
                                prod => prod.pbe.Product2.Id === res[i].pbe.Product2.Id
                            );

                            if (alreadySelected) {
                                res[i].checkSelected = true;

                                // --- NEW: Restore User Inputs ---
                                res[i].quantity = alreadySelected.quantity;             // Restore Quantity
                                res[i].discountPercent = alreadySelected.discountPercent; // Restore Discount
                                res[i].description = alreadySelected.description;       // Restore Description

                                // Optional: Restore selected DC if you want that persisted too
                                if (alreadySelected.selectedDC) {
                                    res[i].selectedDC = 'All';
                                }
                            } else {
                                res[i].checkSelected = false;
                                // Ensure default DC is set if not selected
                                if (!res[i].selectedDC) res[i].selectedDC = 'All';
                            }
                        }

                        // 🔥 decorate with stockClass + numeric stock
                        this.handleProductsResponse(res);

                    } else {
                        this.listOfProducts = undefined;
                    }


                    this.modalSpinner = false;
                })
                .catch(error => {
                    this.modalSpinner = false;
                    this.pushError(error);
                });
        } catch (e) {
            console.log('Error:', e);
            this.modalSpinner = false;
        }
    }

    handleCheckbox(event) {
        const index = event.target.dataset.index;
        const checked = event.target.checked;

        const products = [...this.listOfProducts];
        products[index].checkSelected = checked;
        this.listOfProducts = products;

        if (checked) {
            const existing = this.listOfCheckedProucts.find(
                p => p.pbe.Product2.Id === products[index].pbe.Product2.Id
            );
            if (!existing) {
                this.listOfCheckedProucts = [...this.listOfCheckedProucts, products[index]];
            }
        } else {
            this.listOfCheckedProucts = this.listOfCheckedProucts.filter(
                p => p.pbe.Product2.Id !== products[index].pbe.Product2.Id
            );
        }
    }

    handleDCChange(event) {
        const index = event.target.dataset.index;
        const newDcId = event.detail.value;
        const products = [...this.listOfProducts];
        const selectedRow = products[index];

        // 1. Update the UI selection immediately
        selectedRow.selectedDC = newDcId;

        // 2. Prepare params for Apex
        // Note: passing 'All' as dcId if selected, Apex should handle 'All' or empty string logic if needed
        const prodName = selectedRow.pbe.Product2.Name;
        const prodId = selectedRow.pbe.Product2.Id;
        const passedDcId = (newDcId === 'All') ? '' : newDcId; // Pass empty if All, or adjust based on Apex requirement

        this.modalSpinner = true;

        initialProductsByDC({
            currProfile: JSON.stringify(this.order.Order_Profile__r),
            billToAddId: this.order.Bill_To_Address__c,
            shipToAddId: this.order.Ship_To_Address__c,
            searchItem: prodName, // Exact Name
            dcId: passedDcId,
            productId: prodId
        })
            .then(result => {
                let res = JSON.parse(JSON.stringify(result));

                if (res && res.length > 0) {
                    // We expect one record back for the specific product
                    let updatedProd = res[0];

                    // Re-apply stock logic formatting locally since we aren't calling the bulk helper
                    // (Or extract stock logic to a pure utility function to avoid code duplication)
                    if (updatedProd.stock == 0 && updatedProd.pbe.Product2.Allow_Back_Orders__c)
                        updatedProd.stock = 'Back Order';
                    if (updatedProd.pbe.Product2.Is_Kit__c)
                        updatedProd.stock = 'Kit';

                    let rawStock = updatedProd.stock;
                    let displayStock = rawStock;
                    let levelClass = 'stock-pill--ok';
                    let numericStock = Number(rawStock);

                    if (rawStock === 'Back Order') levelClass = 'stock-pill--backorder';
                    else if (rawStock === 'Kit') levelClass = 'stock-pill--kit';
                    else {
                        displayStock = numericStock;
                        if (numericStock === 0) levelClass = 'stock-pill--none';
                        else if (numericStock <= 10) levelClass = 'stock-pill--low';
                        else if (numericStock <= 50) levelClass = 'stock-pill--medium';
                    }

                    // MERGE the new data into the existing row
                    // We preserve 'checkSelected' and 'quantity' from the user's current session if desired,
                    // OR overwrite them if the DC change implies a fresh start. Usually, we keep user input qty.

                    selectedRow.stock = displayStock;
                    selectedRow.stockClass = `stock-pill ${levelClass}`;
                    selectedRow.pbe = updatedProd.pbe; // Updates Price (UnitPrice)
                    selectedRow.tax = updatedProd.tax; // Updates Tax info

                    // If you want to overwrite quantity/description from DB:
                    // selectedRow.quantity = updatedProd.quantity; 

                    // Force reactivity
                    this.listOfProducts = products;

                    // *** NEW: Sync changes to Checked Products List ***
                    this.syncProductToCart(selectedRow);
                }
            })
            .catch(error => {
                console.error('Error fetching product by DC:', error);
                this.pushError(error);
            })
            .finally(() => {
                this.modalSpinner = false;
            });
    }

    handleUnitPrice(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;
        const products = [...this.listOfProducts];
        products[index].pbe.UnitPrice = value;
        this.listOfProducts = products;

        this.syncProductToCart(products[index]);
    }

    handleQuantity(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;
        const products = [...this.listOfProducts];
        products[index].quantity = value;
        this.listOfProducts = products;

        // Sync change to checked list
        this.syncProductToCart(products[index]);
    }

    handleDiscount(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;
        const products = [...this.listOfProducts];
        products[index].discountPercent = value;
        this.listOfProducts = products;

        // Sync change to checked list
        this.syncProductToCart(products[index]);
    }

    handleDescription(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;
        const products = [...this.listOfProducts];
        products[index].description = value;
        this.listOfProducts = products;

        // Sync change to checked list
        this.syncProductToCart(products[index]);
    }

    // Helper: Syncs a single product row change to the 'Cart' (listOfCheckedProucts)
    syncProductToCart(productRow) {
        try {
            // Only proceed if we have a cart and the item is actually in it
            if (this.listOfCheckedProucts && this.listOfCheckedProucts.length > 0) {

                const index = this.listOfCheckedProucts.findIndex(
                    item => item.pbe.Product2.Id === productRow.pbe.Product2.Id
                );

                if (index !== -1) {
                    // Update the item in the checked list
                    // We use object spread {...} to ensure the new values (Price, DC, etc) are copied
                    this.listOfCheckedProucts[index] = { ...productRow };

                    // console.log('Synced to Cart:', JSON.stringify(this.listOfCheckedProucts[index]));
                }
            }
        } catch (e) {
            console.error('Error syncing to cart:', e);
        }
    }

    addProducts() {
        try {
            console.log('inside addProducts');
            console.log('FINAL Selected products:', JSON.stringify(this.listOfCheckedProucts));

            if (!this.validateSelProd()) {
                return;
            }

            if (!this.selectedProducts) {
                this.selectedProducts = [];
            }

            let list = JSON.parse(JSON.stringify(this.listOfCheckedProucts)); // here iam getting the log of selected products 

            list.forEach(p => {
                // if (!p.checkSelected) return; // not required since we have stored the checked products in the list : this.listOfCheckedProucts

                let qty = parseFloat(p.quantity || 1);
                let price = parseFloat(p.pbe.UnitPrice || 0);

                // DISCOUNT
                let discount = 0;
                if (p.discountPercent && p.discountPercent != 0) {
                    if (p.isPercent) {
                        discount = (price * qty * p.discountPercent) / 100;
                    } else {
                        discount = qty * p.discountPercent;
                    }
                }

                // TAX
                let vat = 0;
                let othertax = 0;

                if (p.tax?.Tax_Rate__c) {
                    vat = (p.tax.Tax_Rate__c / 100) * (price * qty - discount);
                }

                if (p.tax?.Other_Tax_Rate__c) {
                    othertax = (p.tax.Other_Tax_Rate__c / 100) * (price * qty - discount);
                }

                if (p.description) {
                    p.pbe.Product2.Description = p.description;
                }
                p.vatAmount = vat;
                p.othertaxAmount = othertax;
                p.totalTaxAmount = vat + othertax;
                p.totalDiscount = discount;

                // NET / GROSS
                p.NetAmount = (price * qty) - discount;
                p.GrossAmount = p.NetAmount + p.totalTaxAmount;

                // this.selectedProducts.push(p); commented and added below by Raqeeb to avoid duplicates
                const existingIndex = this.selectedProducts.findIndex(
                    x => x.pbe.Product2.Id === p.pbe.Product2.Id
                );

                if (existingIndex !== -1) {
                    // Use splice to ensure Reactivity in UI
                    this.selectedProducts.splice(existingIndex, 1, p);
                } else {
                    this.selectedProducts.push(p);
                }
            });

            // 3. Force array refresh (optional safety measure)
            this.selectedProducts = [...this.selectedProducts];

            this.CalculateOrderValues();

            this.selectedProducts = [...this.selectedProducts];

            console.log('FINAL selectedProducts:', JSON.stringify(this.selectedProducts));

            this.showAddProductsModal = false;

        } catch (e) {
            console.error('addProducts error:', e);
        }
    }

    CalculateOrderValues() {
        try {
            let SubTotal = 0;
            let TotalDiscount1 = 0;
            let TotalTaxAmount1 = 0;
            let OrderAmount = 0;

            this.selectedProducts.forEach(p => {
                SubTotal += (p.pbe.UnitPrice * p.quantity);
                TotalDiscount1 += p.totalDiscount;
                TotalTaxAmount1 += p.totalTaxAmount;
                OrderAmount += p.GrossAmount;
            });

            if (!this.order.Amount_Paid__c) this.order.Amount_Paid__c = 0;
            if (!this.order.Total_Shipping_Amount__c) this.order.Total_Shipping_Amount__c = 0;
            if (!this.order.Shipping_Discount__c) this.order.Shipping_Discount__c = 0;

            this.order.Sub_Total__c = SubTotal;
            this.order.TotalDiscount__c = TotalDiscount1;
            this.order.Total_Tax_Amount__c = TotalTaxAmount1;

            this.order.Order_Amount__c =
                OrderAmount +
                this.order.Total_Shipping_Amount__c -
                this.order.Shipping_Discount__c;

            this.order.Due_Amount__c =
                this.order.Order_Amount__c -
                this.order.Amount_Paid__c;

        } catch (e) {
            console.log('CalculateOrderValues error:', e);
        }
    }

    validateSelProd() {
        try {
            this.errorList = [];

            let list = this.listOfCheckedProucts;

            if (!list || list.length === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Warning!',
                    variant: 'warning',
                    message: 'Please select Items to add'
                }));
                return false;
            }

            let count = 0;

            for (let i in list) {
                // if (!list[i].checkSelected) continue; // not required
                count++;

                if (!list[i].pbe.Product2.Allow_Back_Orders__c && list[i].stock == 0) {
                    this.errorList.push(`${list[i].pbe.Product2.Name}: Stock not available`);
                    return false;
                }

                if (!list[i].pbe.UnitPrice || list[i].pbe.UnitPrice < 0) {
                    this.errorList.push(`${list[i].pbe.Product2.Name}: Unit Price can not be negative or empty`);
                    return false;
                }

                if (!list[i].quantity || list[i].quantity <= 0) {
                    this.errorList.push(`${list[i].pbe.Product2.Name}: Quantity can not be negative, zero or empty`);
                    return false;
                }

                if (parseFloat(list[i].discountPercent) < 0) {
                    this.errorList.push(`${list[i].pbe.Product2.Name}: Discount % can not be negative or empty`);
                    return false;
                }

                if (parseFloat(list[i].discountPercent) > 100) {
                    this.errorList.push(`${list[i].pbe.Product2.Name}: Discount % can not be greater than 100`);
                    return false;
                }
            }

            return true;

        } catch (e) {
            console.log('validateSelProd error:', e);
        }
    }


    // ===== Edit Product Modal =====
    editProduct(event) {
        this.orderItemEditIndex = event.currentTarget.dataset.index;
        this.orderItemToEdit = JSON.parse(JSON.stringify(this.selectedProducts[this.orderItemEditIndex]));
        this.isEditOrderItem = true;
    }

    editUnitPrice(event) {
        this.orderItemToEdit.pbe.UnitPrice = parseFloat(event.target.value);
    }

    editQuantity(event) {
        this.orderItemToEdit.quantity = parseFloat(event.target.value);
    }

    editDiscount(event) {
        this.orderItemToEdit.discountPercent = parseFloat(event.target.value);
    }

    editDescription(event) {
        this.orderItemToEdit.pbe.Product2.Description = event.target.value;
    }

    updateOrderItem() {
        let p = this.orderItemToEdit;
        let qty = parseFloat(p.quantity || 0);
        let price = parseFloat(p.pbe.UnitPrice || 0);

        if(p.discountPercent && p.discountPercent < 0){
            // show a warning toast that disc% cannot be more than 100 
            this.dispatchEvent(new ShowToastEvent({
                    title: 'Warning!',
                    variant: 'warning',
                    message: 'Discount % cannot be negative'
                }));
            return;
        }

        if(p.discountPercent && p.discountPercent > 100){
            // show a warning toast that disc% cannot be more than 100 
            this.dispatchEvent(new ShowToastEvent({
                    title: 'Warning!',
                    variant: 'warning',
                    message: 'Discount % cannot be more than 100'
                }));
            return;
        }

        let discount = p.discountPercent ?
            (p.isPercent ? (price * qty * p.discountPercent) / 100 : qty * p.discountPercent)
            : 0;

        let vat = p.tax?.Tax_Rate__c ? (p.tax.Tax_Rate__c / 100) * (price * qty - discount) : 0;
        let othertax = p.tax?.Other_Tax_Rate__c ? (p.tax.Other_Tax_Rate__c / 100) * (price * qty - discount) : 0;

        p.totalDiscount = discount;

        p.vatAmount = vat;
        p.othertaxAmount = othertax;

        p.totalTaxAmount = vat + othertax;
        p.NetAmount = price * qty - discount;
        p.GrossAmount = p.NetAmount + p.totalTaxAmount;

        this.selectedProducts[this.orderItemEditIndex] = p;

        this.CalculateOrderValues();

        this.isEditOrderItem = false;
        this.orderItemToEdit = undefined;
        this.orderItemEditIndex = undefined;
    }

    closeEditModal() {
        this.isEditOrderItem = false;
        this.orderItemToEdit = undefined;
    }

    // ===== Delete line item =====
    openDeleteModal(event) {
        this.indexToDel = parseInt(event.currentTarget.dataset.index, 10);
        this.deleteConfirmation = true;
    }

    closeDeleteModal() {
        try {
            this.deleteConfirmation = false;
            this.indexToDel = undefined;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    removeLineItem() {
        try {
            if (this.indexToDel !== undefined && this.indexToDel !== null) {

                if (this.selectedProducts[this.indexToDel].Id) {
                    if (!this.itemsToDel) this.itemsToDel = [];
                    this.itemsToDel.push(this.selectedProducts[this.indexToDel].Id);
                }

                this.selectedProducts.splice(this.indexToDel, 1);
            }

            this.CalculateOrderValues();

            this.indexToDel = undefined;
            this.deleteConfirmation = false;

        } catch (e) {
            console.log('Error:', e);
        }
    }

    // ===== Product link =====
    openProductLink(event) {
        const index = event.currentTarget.dataset.index;
        const prodId = this.selectedProducts[index]?.pbe?.Product2?.Id;

        if (prodId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: prodId,
                    objectApiName: 'Product2',
                    actionName: 'view'
                }
            });
        }
    }

    // ===== Remove lookups =====
    removeContact() {
        this.order.Contact__c = '';
        this.order.Contact__r = { Id: '', Name: '', Email: '', Phone: '' };
        this.contactSelected = false;
        this.contactUrl = null;
    }

    removeBillTo() {
        this.order.Bill_To_Address__c = '';
        this.order.Bill_To_Address__r = { Id: '', Name: '' };
        this.billToAddFull = '';
        this.billToSelected = false;
        this.billToUrl = null;
    }

    removeShipTo() {
        this.order.Ship_To_Address__c = '';
        this.order.Ship_To_Address__r = { Id: '', Name: '' };
        this.shipToAddFull = '';
        this.shipToSelected = false;
        this.shipToUrl = null;
    }

    removeOrderProfile() {
        this.order.Order_Profile__c = '';
        this.order.Order_Profile__r = { Id: '', Name: '' };
        this.orderProfileSelected = false;
        this.orderProfileUrl = null;
        // this.listOfProducts = [];
        // this.selectedProducts = [];
        this.CalculateOrderValues();
    }

    removeEmployee() {
        this.order.Employee__c = '';
        this.order.Employee__r = { Id: '', Name: '' };
        this.employeeSelected = false;
        this.employeeUrl = null;
    }

    removeProject() {
        this.order.Project__c = '';
        this.order.Project__r = { Id: '', Name: '' };
        this.projectSelected = false;
    }

    // ===== Misc =====
    handleRefreshComponent() {
        try {
            window.location.reload();
            console.log('Iam In the Refresh::');
        } catch (e) {
            console.log('Error:', JSON.stringify(e));
        }
    }
handleShipmentHandlingCostChange(event) {
    const value = event.target.value; // string/number from input
    this.order = {
        ...this.order,
        Shipment_Handling_Cost__c: value ? parseFloat(value) : null
    };
}

    saveOrder() {
        try {
            // reset errors for this run
            this.errorList = [];

            console.log('order.Status:', this.order.Status);
            console.log('ordStatus:', this.ordStatus);

            let isvalid = true;
            if (!this.order.Contact__c || this.order.Contact__c == '') {
                if (!this.errorList.includes('Contact not found')) this.errorList.push('Contact not found');
                isvalid = false;
            }
            if (!this.order.Bill_To_Address__c || this.order.Bill_To_Address__c == '') {
                if (!this.errorList.includes('Bill To Address not found')) this.errorList.push('Bill To Address not found');
                isvalid = false;
            }
            if (!this.order.Ship_To_Address__c || this.order.Ship_To_Address__c == '') {
                if (!this.errorList.includes('Ship To Address not found')) this.errorList.push('Ship To Address not found');
                isvalid = false;
            }
            if (!this.order.Order_Profile__c || this.order.Order_Profile__c == '') {
                if (!this.errorList.includes('Order Profile not found')) this.errorList.push('Order Profile not found');
                isvalid = false;
            }
            if (!this.order.Employee__c || this.order.Employee__c == '') {
                if (!this.errorList.includes('Employee not found')) this.errorList.push('Employee not found');
                isvalid = false;
            }
            if (!this.order.EffectiveDate || this.order.EffectiveDate == '') {
                if (!this.errorList.includes('Order start date not found')) this.errorList.push('Order start date not found');
                isvalid = false;
            }
            if (this.selectedProducts.length == 0) {
                const event = new ShowToastEvent({
                    title: 'Error!',
                    variant: 'warning',
                    message: 'No products added yet.'
                });
                this.dispatchEvent(event);
                isvalid = false;
            }
            if (!isvalid) {
                this.template.querySelector('.page-background').scrollIntoView({ behavior: 'smooth' });
                return;
            }

            this.spinner = true;
            if (this.order.Id == '') delete this.order.Id;
            if (!this.isMultiCurrency) delete this.order.CurrencyIsoCode;
            this.order.Active__c = true;
            this.order.Customer_Email__c = this.order.Contact__r.Email;
            this.order.Stage__c = 'Entered';
            this.order.Shipment_Handling_Cost__c = this.order.Shipment_Handling_Cost__c || 0;
            if (this.order.Employee__r.Employee_User__c) this.order.OwnerId = this.order.Employee__r.Employee_User__c;
            if (this.order.Account.Company__c) this.order.Company__c = this.order.Account.Company__c;
            if (this.order.Order_Profile__r.Price_Book__c) this.order.Pricebook2Id = this.order.Order_Profile__r.Price_Book__c;
            if (this.order.Order_Profile__r.Channel__c) this.order.Channel__c = this.order.Order_Profile__r.Channel__c;


            console.log('this.order:', JSON.stringify(this.order));

            //Initialization of orderItems
            let prodList = [];
            let selectedProducts = this.selectedProducts;
            let OrderItems = [];
            for (let i in selectedProducts) {
                let discount = 0;
                OrderItems[i] = {};
                if (selectedProducts[i].Id) OrderItems[i].Id = selectedProducts[i].Id;
                OrderItems[i].Active__c = true;
                OrderItems[i].Allocate_Stock__c = true;
                if (!selectedProducts[i].pbe.Product2.Is_Kit__c) OrderItems[i].Inventory_Tracked__c = true;
                if (selectedProducts[i].isPercent) {
                    OrderItems[i].Discount_Percent__c = selectedProducts[i].discountPercent;
                    discount = (((selectedProducts[i].pbe.UnitPrice * selectedProducts[i].quantity) * selectedProducts[i].discountPercent) / 100);
                    OrderItems[i].Discount_Amount__c = discount;
                } else {
                    discount = selectedProducts[i].quantity * selectedProducts[i].discountPercent;
                    OrderItems[i].Discount_Amount__c = discount;
                    let total = selectedProducts[i].pbe.UnitPrice * selectedProducts[i].quantity;
                    let per = (discount / total) * 100;
                    OrderItems[i].Discount_Percent__c = per;
                }
                if (selectedProducts[i].discountPlan != '') {
                    OrderItems[i].Discount_Plan__c = selectedProducts[i].discountPlan;
                }
                OrderItems[i].Product2Id = selectedProducts[i].pbe.Product2Id;
                prodList.push(selectedProducts[i].pbe.Product2Id);

                if (selectedProducts[i].version != '') OrderItems[i].BOM__c = selectedProducts[i].version;
                OrderItems[i].Quantity = selectedProducts[i].quantity;
                OrderItems[i].Sort_Order__c = parseInt(i, 10);
                if (selectedProducts[i].tax.Id) OrderItems[i].Tax__c = selectedProducts[i].tax.Id;
                OrderItems[i].VAT_Amount__c = selectedProducts[i].vatAmount;
                OrderItems[i].Other_Tax__c = selectedProducts[i].othertaxAmount;
                OrderItems[i].Sub_Total__c = parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity);
                OrderItems[i].Total_Price__c =
                    parseFloat(selectedProducts[i].pbe.UnitPrice) * parseFloat(selectedProducts[i].quantity) -
                    parseFloat(discount) +
                    parseFloat(selectedProducts[i].vatAmount) +
                    parseFloat(selectedProducts[i].othertaxAmount);
                OrderItems[i].UnitPrice = selectedProducts[i].pbe.UnitPrice;
                OrderItems[i].Description = selectedProducts[i].description || selectedProducts[i].pbe.Product2.Description;
                OrderItems[i].Company__c = this.order.Company__c;
                OrderItems[i].ServiceDate = this.order.EffectiveDate;
            }

            console.log('OrderItems :', JSON.stringify(OrderItems));
            console.log('order ', JSON.stringify(this.order));
            saveOrderAndLine({
                ord: JSON.stringify(this.order),
                ordItems: JSON.stringify(OrderItems),
                prodList: JSON.stringify(prodList),
                itemsToDel: this.itemsToDel
            })
                .then(result => {
                    this.spinner = false;

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Order created successfully',
                            variant: 'success'
                        })
                    );

                    // let toast show briefly, then navigate
                    setTimeout(() => {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: result.ord.Id,
                                objectApiName: 'Order',
                                actionName: 'view'
                            }
                        });
                    }, 500);
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                });
        } catch (e) {
            console.log('Error:', e);
        }
    }
    handleClose() {
        this.errorList = [];
    }
}