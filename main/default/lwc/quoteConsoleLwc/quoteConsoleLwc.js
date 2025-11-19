import { LightningElement, api, track, wire } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import cpqassets from '@salesforce/resourceUrl/cpqassets';
//import maqcustom from '@salesforce/resourceUrl/maqcustom';
import bootStrap from '@salesforce/resourceUrl/bootStarp_CPQ';
import fontawesome from '@salesforce/resourceUrl/fontawesomeCPQ';
import cpqtheme from '@salesforce/resourceUrl/cpqtheme';
import { RefreshEvent } from "lightning/refresh";


import ShowPandL from '@salesforce/label/c.isShowPandL';
import ShowSubscriptionTable from '@salesforce/label/c.Show_Subscription_Table';
import Product_Default_Discount_Limit from '@salesforce/label/c.Product_Default_Discount_Limit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import QuoteandLineItems from '@salesforce/label/c.Quote_and_Line_Items';
import QuoteLookup from '@salesforce/label/c.Quotelookup';

//import  from '@salesforce/label/c.';
import Quote_Name from '@salesforce/label/c.Quote_Name';
import Quote_Name_placeholder from '@salesforce/label/c.Quote_Name_placeholder';
import Request_Date from '@salesforce/label/c.Request_Date';
import Status from '@salesforce/label/c.Status';
import Customer_lookup from '@salesforce/label/c.Customer_lookup';
import Contact_lookUp from '@salesforce/label/c.Contact_lookUp';
import Customer_Profile_lookUp from '@salesforce/label/c.Customer_Profile_lookUp';
import Employee_LookUp from '@salesforce/label/c.Employee_LookUp';
import Currency_Picklist from '@salesforce/label/c.Currency';
import Bill_To_Address_LookUp from '@salesforce/label/c.Bill_To_Address_LookUp';
import Ship_To_Address_LookUp from '@salesforce/label/c.Ship_To_Address_LookUp';
import Description1 from '@salesforce/label/c.Description';
import CODE1 from '@salesforce/label/c.Code';
import PRODUCT from '@salesforce/label/c.PRODUCT';
import PRICE from '@salesforce/label/c.Price';
import QUANTITY from '@salesforce/label/c.Cost_Card_Quantity';
import DISCOUNT_UNIT from '@salesforce/label/c.Discount_Unit';
import Discount_Plan from '@salesforce/label/c.Discount_Plan';
import Actions from '@salesforce/label/c.Actions';
import TAX from '@salesforce/label/c.Tax';
import NET from '@salesforce/label/c.NET';
import GROSS from '@salesforce/label/c.Gross';
import DESCRIPTION2 from '@salesforce/label/c.Description';
import SUBCRIPTIONS from '@salesforce/label/c.SUBCRIPTIONS';
import START_DATE from '@salesforce/label/c.START_DATE';
import END_DATE from '@salesforce/label/c.END_DATE';
import Calculate_P_L from '@salesforce/label/c.Calculate_P_L';
import ADD_PRODUCTS from '@salesforce/label/c.Add_Products';
import SearchProduct from '@salesforce/label/c.Search_Product';
import Placeholder from '@salesforce/label/c.SearchproductPlaceHolder';
import Code from '@salesforce/label/c.Code';
import UOM from '@salesforce/label/c.UOM';
import ProductFamily from '@salesforce/label/c.Product_Family';
import STOCK from '@salesforce/label/c.Stock';
import Price_Unit from '@salesforce/label/c.Price_Unit';
import Back from '@salesforce/label/c.Back';
import Quote_Console from '@salesforce/label/c.Quote_Console';
import Add_Products1 from '@salesforce/label/c.Add_Products';
import Delete_Confirm_Msg from '@salesforce/label/c.Delete_Confirm_Msg';
import Cancelbutton from '@salesforce/label/c.Cancel';
import Deletebutton from '@salesforce/label/c.Delete1'
import Yes from '@salesforce/label/c.Yes';
import No from '@salesforce/label/c.No';
import Dicount_Alert from '@salesforce/label/c.Dicount_Alert';
import percentage_of_discount from '@salesforce/label/c.Percentage_Of_Discount_New';
import Approval_Confirm from '@salesforce/label/c.Approval_Confirm';
import QuoteDocumentBtn from '@salesforce/label/c.QuoteDocumentBtn';
import SaveBtn from '@salesforce/label/c.SaveBtn';
import ResetBtn from '@salesforce/label/c.ResetBtn';
import NewBtn from '@salesforce/label/c.NewBtn';
import CUSTOMER from '@salesforce/label/c.CUSTOMER';
import ADDRESS from '@salesforce/label/c.ADDRESS';
import Quotelookup from '@salesforce/label/c.Quotelookup';
import QC_PRODUCT_IMAGE from '@salesforce/label/c.QC_PRODUCT_IMAGE';
import Quote_and_Line_Items from '@salesforce/label/c.Quote_and_Line_Items';
import QC_Subscribe from '@salesforce/label/c.QC_Subscribe';
import EPOS_Product_Code from '@salesforce/label/c.EPOS_Product_Code';
import Discount from '@salesforce/label/c.Discount';
import Description from '@salesforce/label/c.Description';
import QuoteDocCustomLink from '@salesforce/label/c.QuoteDocCustomLink';

//Apex classes
import getStatus from "@salesforce/apex/QuoteConsole.getStatus";
import cusmChange from "@salesforce/apex/QuoteConsole.cusmChange";
import fetchProducts from "@salesforce/apex/QuoteConsole.fetchProducts";
import getSubscriptions from "@salesforce/apex/QuoteConsole.getSubscriptions";
import getDiscountPlans from '@salesforce/apex/QuoteConsole.getDiscountPlan';
import draftQuoteSave from "@salesforce/apex/QuoteConsole.draftQuoteSave";
import fetchQuoteLine from '@salesforce/apex/QuoteConsole.fetchQuoteLine';
import fetchOptionalProducts from "@salesforce/apex/QuoteConsole.fetchOptionalProducts";
import getQuoteId from "@salesforce/apex/QuoteConsole.getQuoteId";
import FetchBOMs from "@salesforce/apex/QuoteConsole.FetchBOMs";
//import getOppName from "@salesforce/apex/QuoteConsole.getOppName";
import getSubscriptionPlans from "@salesforce/apex/QuoteConsole.getSubscriptionPlans";
import getSelplanDetails from "@salesforce/apex/QuoteConsole.getselectedplanDetails";
import { CurrentPageReference } from 'lightning/navigation';
import changeProfilehandler from "@salesforce/apex/QuoteConsole.changeProfilehandler";
import getFnctionalityControls from "@salesforce/apex/QuoteConsole.getFnctionalityControls";
import getOrgEnivronment from "@salesforce/apex/QuoteConsole.CheckOrg";
import SndbxBaseURL from "@salesforce/apex/QuoteConsole.getBaseURL";
import getdiscountplandetails from "@salesforce/apex/QuoteConsole.discountPlanInfo";
//import { NavigationMixin } from 'lightning/navigation';


export default class QuoteConsoleLwc extends LightningElement {
    spinner = true;
    errorList = [];
    isShowSubscriptionTable = false;
    isSubscriptionProd = false;
    isGetSubscription = false;
    quoteStatus;
    allCurrencies;
    quoteCurrency = '';
    isMultiCurrency = false;
    DragIndex;
    quoteLineToDelete = [];
    flow = 'MainPage';
    @track quote = { Customer__c: '' };
    recType = '';
    isCloneConfirmation = false;
    @track ListOfSubsPlans = [];

    selectOrderProfile = false;
    orderSelected = false;
    dateError = '';
    searchItem = '';
    CurrentOrg = '';
    prodFamily;
    prodFamilyList;
    @track listOfProducts = [];
    @track selectedProducts = [];
    versionList = [];
    productsList = [];
    isFromDraftSave = false;
    @track resetQuote = false;
    deleteConfirmation = false;
    indexToDel;
    lineIdToDel;
    currentSelIndex;
    currentSelCount;
    Product_Default_Discount = parseFloat(Product_Default_Discount_Limit);
    isDiscountPlanConfirmation = false;
    isDiscountPlanConfirmationPSS = false;
    ShowUndo = false;
    @track Stock_Class;


    @track QuoteandLineItemsHeading = QuoteandLineItems;
    @track QuoteLookupLabel = QuoteLookup;
    @track Quote_NameLabel = Quote_Name;
    @track Quote_Name_placeholderLable = Quote_Name_placeholder;
    @track Request_DateLabel = Request_Date;
    @track StatusLabel = Status;
    @track Customer_lookupLabel = Customer_lookup;
    @track Contact_lookUpLabel = Contact_lookUp;
    @track Customer_Profile_lookUpLabel = Customer_Profile_lookUp;
    @track Employee_LookUpLabel = Employee_LookUp;
    @track Currency_PicklistLabel = Currency_Picklist;
    @track Bill_To_Address_LookUpLabel = Bill_To_Address_LookUp;
    @track Ship_To_Address_LookUpLabel = Ship_To_Address_LookUp;
    @track Description1Label = Description1;
    @track CODE1Labels = CODE1;
    @track PRODUCTLabels = PRODUCT;
    @track PRICELabels = PRICE;
    @track QUANTITYLabels = QUANTITY;
    @track DISCOUNT_UNITLabels = DISCOUNT_UNIT;
    @track DISCOUNT_PLANLabels = Discount_Plan;
    @track ACTIONS = Actions;
    @track TAXLabels = TAX;
    @track NETLabels = NET;
    @track GROSSLabels = GROSS;
    @track DESCRIPTION2Labels = DESCRIPTION2;
    @track SUBCRIPTIONSLabel = SUBCRIPTIONS;
    @track START_DATELabel = START_DATE;
    @track END_DATELabel = END_DATE;
    @track Calculate_P_Llabel = Calculate_P_L;
    @track ADD_PRODUCTSLabel = ADD_PRODUCTS;
    @track productsearchLabel = SearchProduct;
    @track searchplaceholder = Placeholder;
    @track ProdCode = Code;
    @track ProdUom = UOM;
    @track Family = ProductFamily;
    @track STOCKLabel = STOCK;
    @track Price_UnitLabel = Price_Unit;
    @track BackLabel = Back;
    @track Quote_Consolelabel = Quote_Console;
    @track AddproductSmallchar = Add_Products1;
    @track Delete_Confirm_MsgLabel = Delete_Confirm_Msg;
    @track CancelbuttonLabel = Cancelbutton;
    @track DeletebuttonLabel = Deletebutton;
    @track YesLabel = Yes;
    @track Nolabel = No;
    @track Dicount_AlertLabel = Dicount_Alert;
    @track Approval_ConfirmLabel = Approval_Confirm;
    @track percentage_of_discountLAbel = percentage_of_discount;
    @api quoteIdfromManage = '';
    @api OppId = '';
    @api Sub_AccountId = '';
    @api AccId = '';
    Default_LisView = true;
    @track Error_message = '';
    Grid_view = false;
    selectedProductIdList = [];
    @track No_of_SelectedProds = 0;
    SubscribeBadge = false;
    SubBatch = false;
    @track listOfCheckedProucts = [];
    @track QtBtnLbl = QuoteDocumentBtn;
    @track savebutton = SaveBtn;
    @track resetbutton = ResetBtn;
    @track newbutton = NewBtn;
    @track customerLabel = CUSTOMER;
    @track addressLabel = ADDRESS;
    @track QuoteLabel = Quotelookup;
    @track QLILabel = Quote_and_Line_Items;
    @track ProductImageLabel = QC_PRODUCT_IMAGE;
    @track SubscribeLabel = QC_Subscribe;
    @track ProductCodeLabel = EPOS_Product_Code;
    @track DiscountLabel = Discount;
    @track DescriptionLabel = Description;

    @track ShowFamily = false;
    @track ShowUOM = false;
    @track ShowStock = false;
    @track showOptions = false;
    @track hideStockTableHeading = false;

    @track DefaultListView = "WCCPM13 WCCPM14 acitve-list2";
    @track DefaultGridView = "WCCPM13 WCCPM14"
    @track frombackbutton = false;


    connectedCallback() {

        if (this.quoteId != null && this.quoteId != '' && this.quoteId != undefined && (this.quote.Id == null || this.quote.Id == '' || this.quote.Id == undefined)) { this.quote.Id = this.quoteId; }
        if (this.AccId != null && this.AccId != '' && this.AccId != undefined) {
            if (!this.quote.Customer__c) this.quote.Customer__c = this.AccId;

        }
        console.log('this.AccId::', this.AccId);
        if (this.OppId) { this.quote.opportunities__c = this.OppId; this.quote.Opportunity_Id__c = this.OppId; }

        console.log('ConnectedCallback Called------>', this.quoteIdfromManage);



        try {
            if (this.quote.Id == '' || this.quote.Id == null || this.quote.Id == undefined) {
                getQuoteId({
                    Qid: this.quoteIdfromManage,
                })
                    .then(result => {
                        console.log('getQuoteId result:', result);
                        let res = JSON.parse(JSON.stringify(result));
                        this.quote.Id = res.Id;
                        console.log('this.quote.Id:', this.quote.Id);

                    })
                    .catch(error => {
                        console.log('getQuoteId Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    })

            }

            getSubscriptionPlans()
                .then(result => {
                    let res = JSON.parse(JSON.stringify(result));   //deep clone
                    console.log('res:', res);
                    this.ListOfSubsPlans = res;
                    this.planlist = JSON.parse(JSON.stringify(this.ListOfSubsPlans));
                    console.log('this.ListOfSubsPlans:', JSON.parse(JSON.stringify(this.ListOfSubsPlans)));
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })

            if (this.quote.Customer__c == '' || this.quote.Customer__c == null) {
                this.quote.Customer__c = this.Sub_AccountId;
                console.log('Ovririding1:', this.quote.Customer__c);
            }

            getFnctionalityControls()
                .then(result => {
                    console.log('Functionality control result ::', JSON.stringify(result));
                    this.ShowFamily = result.ShowFamily;
                    this.ShowUOM = result.ShowUOM;
                    this.ShowStock = result.ShowStock;
                    this.handleDiscountField = result.handleDiscountField;
                    this.allowZeroUnitprice = result.allowZeroUnitprice;
                    this.showconfigBtn = result.showconfigBtn;
                    this.HidePnLBtn = result.HidePnLBtn;
                    this.showOptions = result.ShowOption;
                    this.ApplyDiscountTaxOnWholeQuote = result.ApplyDiscountTaxOnWholeQuote;
                    this.MarkFOCQuote = result.MarkFOCQuote;
                    this.applywholeQuoteDiscount = result.applywholeQuoteDiscount; if (this.applywholeQuoteDiscount) this.CardStyle = "min-height: 257px;";
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })


            getOrgEnivronment()
                .then(result => {
                    if (result) { console.log('getorgenvironment-' + result); this.CurrentOrg = result; }
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                })

            if (this.ShowStock) this.hideStockTableHeading = true; else this.hideStockTableHeading = false;

        } catch (e) {
            console.log('Error:', e);
        }
    }



    resetAll() {

        window.location.reload();
    }
    BacktoOpp() {
        history.back();
    }


    closeErrorList() {
        this.errorList = [];
    }

    get showCloneIcon() {
        return this.quote.Id ? true : false;
    }

    get isHide() {
        if (this.quoteIdfromManage || this.OppId)
            return true;
        else
            return false;
    }

    get showQuote() {
        if (this.OppId && !this.quote.Id)
            return false;
        else
            return true;
    }

    get isshowconfigBtn() {
        if (this.quote.Id && this.showconfigBtn)
            return false;
        else
            return true;
    }

    get isErrorList() {
        if (this.errorList) {
            if (this.errorList.length > 0) return true;
            else return false;
        } else return false;
    }

    get IsSubsPLans() {
        return this.flow == 'Subscription Plans page' ? true : false;
    }
    get isSubProdPage() {
        return this.flow == 'Subscription Product Page' ? true : false;
    }
    get isMainPage() {
        return this.flow == 'MainPage' ? true : false;
    }
    get isListOfProdPg() {
        return this.flow == 'ListOfProdPg' ? true : false;
    }
    get isConfPage() {
        return this.flow == 'ConfPage' ? true : false;
    }
    get isShowCalPandL() {
        return this.flow == 'showCalPandL' ? true : false;
    }
    get isShowPandL() {
        return ShowPandL === 'true' ? true : false;//Don't use this here
    }
    get isSelectedProducts() {

        if (this.selectedProducts) {
            return this.selectedProducts.length <= 0 ? true : false;
        }
        return false;
    }
    get accountQuery() {
        return " AND Account_Type__c= 'Customer'";
    }
    get contactQuery() {
        console.log('contactQuery  entered: ');
        return " AND AccountId = '" + this.quote.Customer__c + "'";

    }
    get orderProfileQuery() {
        console.log('rectype--' + this.recType);
        return " AND RecordTypeId ='" + this.recType + "'";
    }
    get prodSubplan() {
        return " AND Product__c ='" + this.ProdIdPlan + "'";
    }
    get billToAddQuery() {
        return " AND Is_Billing_Address__c=true AND Active__c=true AND Customer__c = '" + this.quote.Customer__c + "'";
    }
    get shipToAddQuery() {
        return " AND Is_Shipping_Address__c=true AND Active__c=true And Customer__c = '" + this.quote.Customer__c + "'";
    }
    get disableSaveButton() {
        return this.quote.Customer__c && this.quote.Customer__c != '' && this.quote.Contact__c && this.quote.Contact__c != '' && this.quote.Order_Profile__c && this.quote.Order_Profile__c != '' && this.quote.Employee__c && this.quote.Employee__c != '' && this.quote.Request_Date__c && this.quote.Request_Date__c != '' && this.quote.Status__c && this.quote.Status__c != '' && this.quote.Bill_To_Address__c && this.quote.Bill_To_Address__c != '' && this.quote.Ship_To_Address__c && this.quote.Ship_To_Address__c != '' ? false : true;
        console.log('Customer:', this.quote.Customer__c);
        console.log('Contact:', this.quote.Contact__c);
        console.log('Order Profile:', this.quote.Order_Profile__c);
        console.log('Employee:', this.quote.Employee__c);
        console.log('Request Date:', this.quote.Request_Date__c);
        console.log('Status:', this.quote.Status__c);
        console.log('Bill To Address 425:', this.quote.Bill_To_Address__c);
        console.log('Ship To Address:', this.quote.Ship_To_Address__c);
    }

    get addButtonDisable() {
        //return false;
        // console.log('Customer:', this.quote.Customer__c);
        // console.log('Contact:', this.quote.Contact__c);
        // console.log('Order Profile:', this.quote.Order_Profile__c);
        // console.log('Employee:', this.quote.Employee__c);
        // console.log('Request Date:', this.quote.Request_Date__c);
        // console.log('Status:', this.quote.Status__c);
        // console.log('Bill To Address 435:', this.quote.Bill_To_Address__c);
        // console.log('Ship To Address:', this.quote.Ship_To_Address__c);
        return this.quote.Customer__c && this.quote.Customer__c != '' && this.quote.Contact__c && this.quote.Contact__c != '' && this.quote.Order_Profile__c && this.quote.Order_Profile__c != '' && this.quote.Employee__c && this.quote.Employee__c != '' && this.quote.Request_Date__c && this.quote.Request_Date__c != '' && this.quote.Status__c && this.quote.Status__c != '' && this.quote.Bill_To_Address__c && this.quote.Bill_To_Address__c != '' && this.quote.Ship_To_Address__c && this.quote.Ship_To_Address__c != '' ? false : true;

    }
    get islistOfProdAvbl() {
        if (this.listOfProducts) {
            return this.listOfProducts.length > 0 ? true : false;
        }
        return false;
    }

    @wire(getStatus)
    wiredRecords({ error, data }) {
        if (data) {
            console.log('initial result:', data);
            console.log('ShowSubscriptionTable:', ShowSubscriptionTable);
            if (ShowSubscriptionTable == 'true')
                this.isShowSubscriptionTable = true;
            else this.isShowSubscriptionTable = false;
            console.log('this.isShowSubscriptionTable:', this.isShowSubscriptionTable);
            if (data.errorMsg != '') this.errorList.push(data.errorMsg);
            this.quote.Employee__c = data.emp.Id;
            //added new for clone company
            this.quote.Company__c = data.emp.Company__c;

            //this.quote.Channel__c = data.profile.Channel__c;
            this.quote.Request_Date__c = data.todayDate;
            this.CurrentDate = data.todayDate;
            this.recType = data.recType;
            console.log(' get status this.rectype' + this.recType);
            this.quoteStatus = data.quoteStatus;
            this.quote.Status__c = this.quoteStatus[0].value;
            this.allCurrencies = data.allCurrencies;
            this.quoteCurrency = this.allCurrencies[0].value;
            this.quote.CurrencyIsoCode = this.allCurrencies[0].value;
            this.isMultiCurrency = data.isMultiCurrency;
            this.prodFamily = data.prodFam[0].value;
            this.prodFamilyList = data.prodFam;
            this.spinner = false;
        } else if (error) {
            console.log('Error:', error);
            this.spinner = false;
            this.errorList = Object.assign([], this.errorList);
            if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
        }
    }


    openCloneConfirmation() {
        this.isCloneConfirmation = true;
    }
    closeCloneConfirmation() {
        this.isCloneConfirmation = false;
    }
    cloneQuote() {

        this.spinner = true;
        this.resetQuote = true;

        //delete this.quote.Id;
        this.quote.Name = '';
        this.quote.Id = '';
        this.quote.Request_Date__c = this.CurrentDate;

        this.quote.Price_Book__c = this.quote.Price_Book__c;
        this.quote.Company__c = this.quote.Company__c;

        for (let i in this.selectedProducts) {
            delete this.selectedProducts[i].Id;
        }

        const event = new ShowToastEvent({
            variant: 'success',
            message: 'Quote Cloned Successfully',
        });
        this.dispatchEvent(event);
        this.isCloneConfirmation = false;
        this.spinner = false;
        console.log('', this.spinner);
    }

    quoteSelection(event) {
        console.log('inside quoteSelection');
        if (this.quoteLineToDelete.length == 0) {
            this.quote.Id = event.detail.Id;
            if (!this.isFromDraftSave && !this.frombackbutton) this.fetchLineFromQuote(this.quote.Id);
        }

    }

    fetchLineFromQuote(quoteId) {
        console.log('inside fetchLineFromQuote ---------->');
        console.log('quoteId::', quoteId);
        try {
            //if(!this.quoteLineToDelete.length > 0){
            this.spinner = true;
            fetchQuoteLine({
                quoteId: quoteId,
            })
                .then(result => {
                    console.log('result of fetchQuoteLine:', result);
                    if (result.errorMsg != '') {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(result.errorMsg)) this.errorList.push(result.errorMsg);
                    }
                    this.quote = result.quote;
                    this.quote.opportunities__c = result.quote.opportunities__c;
                    //added now
                    if (this.quote.Id != null && this.changedStatus != null) this.quote.Status__c = this.changedStatus; this.discountPercent = result.quote.Discount_Percentage__c; this.quote.opportunities__c = result.quote.opportunities__c;
                    if (!this.isMultiCurrency) this.quote.CurrencyIsoCode = this.allCurrencies[0].value;
                    console.log('1');
                    let taxMap = new Map();
                    for (let i in result.taxMap) {
                        taxMap.set(result.taxMap[i].Id, result.taxMap[i]);
                    }
                    console.log('taxMap:', JSON.parse(JSON.stringify(taxMap)));

                    let i = 0;

                    result.qtLine.forEach(qtLine => {
                        this.selectedProducts[i] = {
                            pbe: {
                                Product2: {
                                    Id: qtLine.Product__c,
                                    Name: qtLine.Product__r.Name,
                                    ProductCode: qtLine.Product__r.ProductCode,
                                    nameUrl: '/' + qtLine.Product__c,
                                    Serialise__c: qtLine.Product__r.Serialise__c,
                                    Configure__c: qtLine.Product__r.Configure__c,
                                    Allow_Back_Orders__c: qtLine.Product__r.Allow_Back_Orders__c,
                                    //Description: qtLine.Product__r.Description,
                                    Description: qtLine.Description__c,
                                    Picture__c: qtLine.Product__r.Picture__c,
                                    QuantityUnitOfMeasure: qtLine.Product__r.QuantityUnitOfMeasure,
                                    Is_Subscribe__c: qtLine.Product__r.Is_Subscribe__c,

                                },
                                Product2Id: qtLine.Product__c,
                                UnitPrice: qtLine.List_Price__c,
                            },
                            lineStatus: qtLine.Status__c,
                            //version: qtLine.Product_Version__c ? qtLine.Product_Version__c : '',
                            version: qtLine.Product_Version__c,
                            quantity: qtLine.Quantity__c,
                            isPercent: true,
                            minDiscount: 0,
                            maxDiscount: 0,
                            discountPercent: qtLine.Discount_Percent__c ? qtLine.Discount_Percent__c : 0,
                            //stock=0;
                            disPlans: result.discountPlans,
                            tierDists: result.TDA,
                            tax: qtLine.Tax__c ? taxMap.get(qtLine.Tax__c) : {},
                            discountPlan: qtLine.Discount_Plan__c ? qtLine.Discount_Plan__c : '',
                            //PurchaseType_value:qtLine.Purchase_Type__c,
                            //PlanId: qtLine.Product_Subscription_Plan_Allocation__c,
                            startDate: qtLine.Start_Date__c,
                            endDate: qtLine.End_Date__c,
                            //isSubProd: qtLine.Product__r.Subscription_Plan__c ? true : false,
                            Year: Math.floor(qtLine.Month_Duration__c / 12),
                            Months: qtLine.Month_Duration__c % 12,
                            Days: qtLine.Duration_in_Days__c

                        };
                        //console.log('discountPercent ::: ', discountPercent);
                        this.selectedProducts[i].Optional_Item__c = qtLine.Optional_Item__c;
                        this.selectedProducts[i].FreeOfCharge__c = qtLine.FreeOfCharge__c;
                        //Setting all discount plans having range qunantity start
                        this.selectedProducts[i].CurrentDiscounts = [];
                        let tierDists = this.selectedProducts[i].tierDists;
                        let ind = 1;
                        this.selectedProducts[i].CurrentDiscounts[0] = { label: '--None--', value: '' };
                        for (let j in tierDists) {
                            if (qtLine.Product__c == tierDists[j].Product__c) {
                                if (qtLine.Quantity__c >= tierDists[j].Tier__r.Floor_Unit__c && qtLine.Quantity__c <= tierDists[j].Tier__r.Ceiling_Unit__c) {
                                    this.selectedProducts[i].CurrentDiscounts[ind] = { label: tierDists[j].Discount_Plan__r.Name, value: tierDists[j].Discount_Plan__r.Id };
                                }
                                ind++;
                            }
                        }
                        //Setting all discount plans having range quantity end

                        if (qtLine.Discount_Plan__c) {
                            result.discountPlans.forEach(disPlan => {
                                if (qtLine.Discount_Plan__c == disPlan.Id) {
                                    if (disPlan.Default_Discount_Percentage__c) {
                                        this.selectedProducts[i].isPercent = true;
                                        this.selectedProducts[i].minDiscount = disPlan.Floor_Discount_Percentage__c;
                                        this.selectedProducts[i].maxDiscount = disPlan.Ceiling_Discount_Percentage__c;
                                        this.selectedProducts[i].discountPercent = qtLine.Discount_Percent__c;

                                    } else if (disPlan.Default_Discount_Value__c) {
                                        this.selectedProducts[i].isPercent = false;
                                        this.selectedProducts[i].minDiscount = disPlan.Floor_Discount_Value__c;
                                        this.selectedProducts[i].maxDiscount = disPlan.Ceiling_Discount_Value__c;
                                        this.selectedProducts[i].discountPercent = qtLine.Discount_Amount__c / qtLine.Quantity__c;

                                    } else {
                                        this.selectedProducts[i].isPercent = true;
                                        this.selectedProducts[i].minDiscount = 0;
                                        this.selectedProducts[i].maxDiscount = 0;
                                        this.selectedProducts[i].discountPercent = 0;

                                    }
                                }
                            });
                        } else {
                            this.selectedProducts[i].minDiscount = 0;
                            this.selectedProducts[i].maxDiscount = 0;
                        }


                        this.selectedProducts[i].Id = qtLine.Id;
                        this.selectedProducts[i].keyValue = this.selectedProducts[i].pbe.Product2.Id + i + this.selectedProducts[i].quantity + Math.random();


                        //Calulate Discount and taxes
                        var discount = 0;
                        var vatAmount1 = 0;
                        var otherTax1 = 0;
                        if (this.selectedProducts[i].discountPercent != 0) {
                            if (this.selectedProducts[i].isPercent) {
                                discount = ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) * parseFloat(this.selectedProducts[i].discountPercent)) / 100;
                            } else {
                                discount = parseFloat(this.selectedProducts[i].quantity) * parseFloat(this.selectedProducts[i].discountPercent);
                            }
                        }
                        //added now 
                        if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                            if (this.selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1 = (this.selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[i].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * parseFloat(qtLine.Month_Duration__c)) + (parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * (parseFloat(this.selectedProducts[i].Days) / 30)) - parseFloat(discount)));

                            if (this.selectedProducts[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[i].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * parseFloat(qtLine.Month_Duration__c)) + (parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * (parseFloat(this.selectedProducts[i].Days) / 30)) - parseFloat(discount)));
                            console.log('other Tax 1 in here-->' + otherTax1);
                        }
                        if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                            console.log('2');
                            if (this.selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1 = (this.selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[i].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) - discount));
                            if (this.selectedProducts[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[i].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) - discount));
                        }

                        this.selectedProducts[i].vatAmount = vatAmount1;
                        this.selectedProducts[i].otherTax = otherTax1;
                        this.selectedProducts[i].totalTaxAmount = vatAmount1 + otherTax1;
                        this.selectedProducts[i].totalDiscount = discount;


                        //Calculate NetAmount and GrossAmount
                        if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                            if (this.selectedProducts[i].isPercent) {
                                this.selectedProducts[i].NetAmount = ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) - (((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) * parseFloat(this.selectedProducts[i].discountPercent)) / 100)));
                                this.selectedProducts[i].GrossAmount = ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) - (((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) * parseFloat(this.selectedProducts[i].discountPercent)) / 100) + (parseFloat(this.selectedProducts[i].vatAmount) + parseFloat(this.selectedProducts[i].otherTax))));
                            } else {
                                this.selectedProducts[i].NetAmount = (((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) - (parseFloat(this.selectedProducts[i].quantity) * parseFloat(this.selectedProducts[i].discountPercent))));
                                this.selectedProducts[i].GrossAmount = (((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) - (parseFloat(this.selectedProducts[i].quantity) * parseFloat(this.selectedProducts[i].discountPercent)) + (parseFloat(this.selectedProducts[i].vatAmount) + parseFloat(this.selectedProducts[i].otherTax))));
                            }
                        } else {//added now else part
                            if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                                this.selectedProducts[i].NetAmount = qtLine.Net_Price__c;
                                this.selectedProducts[i].GrossAmount = qtLine.TotalPrice__c;
                            }
                        }
                        i++;


                    });
                    // for (let i in this.selectedProducts) {
                    //     if (this.selectedProducts[i].PlanId) {
                    //         console.log('Result of fetch quote lie subscribe::');
                    //         console.log('this.selectedProducts[i].PlanId::~>', this.selectedProducts[i].PlanId);

                    //         this.selectedProducts[i].IsSubscribed = false;
                    //         this.selectedProducts[i].enable = true;
                    //         this.selectedProducts[i].SubBatch = true;
                    //     }
                    //     else {
                    //         this.selectedProducts[i].IsSubscribed = false;
                    //         this.selectedProducts[i].enable = false;
                    //         this.selectedProducts[i].SubBatch = false;
                    //     }
                    //     if (this.selectedProducts[i].pbe.Product2.Configure__c && this.showconfigBtn) this.selectedProducts[i].showQtlnconfigBtn = true; else this.selectedProducts[i].showQtlnconfigBtn = false;
                    // }
                    for (let i in this.selectedProducts) { //added now 
                        if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) { this.selectedProducts[i].enable = true; this.selectedProducts[i].SubBatch = true; this.selectedProducts[i].IsSubscribed = true; }
                        else { this.selectedProducts[i].IsSubscribed = false; this.selectedProducts[i].enable = false; this.selectedProducts[i].SubBatch = false; }
                    }
                    if (!result.qtLine.length > 0) this.selectedProducts = [];
                    this.spinner = false;

                    console.log('fetchLineFromQuote Quoteline items List :~>', JSON.stringify(this.selectedProducts));

                })
                .catch(error => {
                    this.spinner = false;
                    console.log('fetch quote line items Error:', error);
                    const stackLines = error.stack.split('\n');
                    if (stackLines.length > 1) {
                        const lineInfo = stackLines[1];
                        console.log('Error location:', lineInfo);
                    }

                    this.errorList = Object.assign([], this.errorList);
                    //if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                })
            //}

        } catch (e) { console.log('Error:', e); }
    }
    quoteRemove() {
        try {
            //eval("$A.get('e.force:refreshView').fire();");
            window.location.reload();
        }
        catch (e) { console.log('quote remove Exception:', e.message); }
    }

    nameHandle(event) {
        this.quote.Name = event.currentTarget.value;
    }
    accountSelection(event) {
        console.log('inside accountSelection ------->');
        try {
            this.spinner = true;
            this.errorList = [];

            if (!this.quote.Contact__c != '') { this.quote.Contact__c = ''; }
            //console.log('quote.cont--'+this.quote.Contact__c);

            console.log('this.quote.Bill_To_Address__c 716: ', this.quote.Bill_To_Address__c);
            if (this.frombackbutton === false) {
                this.quote.Bill_To_Address__c = '';
                this.quote.Ship_To_Address__c = '';
            }
            console.log('this.quote.Bill_To_Address__c 721: ', this.quote.Bill_To_Address__c);
            this.quote.Customer__c = event.detail.Id;
            console.log('Ovririding2:', this.quote.Customer__c);
            cusmChange({ accId: this.quote.Customer__c })
                .then(result => {
                    console.log('result of custChange:', result);
                    if (this.quote.Contact__c == null || this.quote.Contact__c == '' || this.quote.Contact__c == undefined) this.quote.Contact__c = result.conId;

                    if (result.acc.Order_Profile__c && (this.quote.Order_Profile__c == null || this.quote.Order_Profile__c == '' || this.quote.Order_Profile__c == undefined)) this.quote.Order_Profile__c = result.acc.Order_Profile__c;
                    if (result.acc.Order_Profile__c && (this.quote.Channel__c == null || this.quote.Channel__c == '' || this.quote.Channel__c == undefined)) this.quote.Channel__c = result.acc.Order_Profile__r.Channel__c;
                    if (result.acc.Order_Profile__c && (this.quote.Price_Book__c == null || this.quote.Price_Book__c == '' || this.quote.Price_Book__c == undefined)) this.quote.Price_Book__c = result.acc.Order_Profile__r.Price_Book__c;
                    console.log('this.quote.Bill_To_Address__c 732: ', this.quote.Bill_To_Address__c);
                    if (this.quote.Bill_To_Address__c == null || this.quote.Bill_To_Address__c == '' || this.quote.Bill_To_Address__c == undefined) this.quote.Bill_To_Address__c = result.billAdd;
                    if (this.quote.Ship_To_Address__c == null || this.quote.Ship_To_Address__c == '' || this.quote.Ship_To_Address__c == undefined) this.quote.Ship_To_Address__c = result.shipAdd;
                    this.quote.Company__c = result.acc.Company__c;

                    this.spinner = false;
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                })


        } catch (e) { console.log(e); }
    }
    accountRemove() {
        try {
            console.log('remove account');
            this.quote.Customer__c = undefined;
            this.quote.Order_Profile__c = undefined;
            this.quote.Contact__c = undefined;
            //window.location.reload();
        } catch (e) { console.log(e); }
    }
    contactSelection(event) {
        try {
            this.quote.Contact__c = event.detail.Id;

        } catch (e) { console.log(e); }
    }
    contactRemove() {
        try {
            this.quote.Contact__c = undefined;

        } catch (e) { console.log(e); }
    }
    temprofileId = '';
    profileSelection(event) {
        try {
            console.log('this.quote.Order_Profile__c bfr: ', this.quote.Order_Profile__c);
            console.log('event.detail.Id bfr: ', event.detail.Id);
            var ProdIds = [];
            if (this.selectedProducts.length > 0 && this.quote.Order_Profile__c != event.detail.Id) {
                for (var x in this.selectedProducts) {
                    ProdIds.push(this.selectedProducts[x].pbe.Product2.Id);
                }
                console.log('ProdIds : ', ProdIds);
            }
            this.quote.Order_Profile__c = event.detail.Id;
            console.log('this.quote.Order_Profile__c after: ', this.quote.Order_Profile__c);
            if (ProdIds.length > 0) {
                this.spinner = true;
                changeProfilehandler({
                    currProfile: this.quote.Order_Profile__c,
                    billToAddId: this.quote.Bill_To_Address__c,
                    shipToAddId: this.quote.Ship_To_Address__c,
                    ProdId: ProdIds,
                    currencycode: this.quote.CurrencyIsoCode
                })
                    .then(result => {
                        console.log('res of changeProfilehandler:', result);
                        let res = JSON.parse(JSON.stringify(result));
                        if (res.length > 0) {
                            this.quote.Price_Book__c = res[0].pbe.Pricebook2Id;
                            for (let i in res) {
                                console.log('res[i] : ', res[i]);
                                for (let x in this.selectedProducts) {
                                    console.log('this.selectedProducts : ', JSON.stringify(this.selectedProducts[x]));
                                    if (res[i].pbe.Product2.Id == this.selectedProducts[x].pbe.Product2.Id) {
                                        var discount = 0;
                                        var vatAmount1 = 0;
                                        var otherTax1 = 0;
                                        //added now 
                                        let No_of_Months = 0;
                                        let No_of_Days = 0;
                                        if (this.selectedProducts[x].pbe.Product2.Is_Subscribe__c) { if (this.selectedProducts[x].Year > 0) { No_of_Months = this.selectedProducts[x].Year * 12; } if (this.selectedProducts[x].Months > 0) { No_of_Months += this.selectedProducts[x].Months; } if (this.selectedProducts[x].Days > 0) { No_of_Days = this.selectedProducts[x].Days; } console.log('No_of_Months:', No_of_Months); }
                                        //till here
                                        if (res[i].discountPercent != 0) {
                                            if (res[i].isPercent) {
                                                discount = ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) * parseFloat(res[i].discountPercent)) / 100;
                                            } else {
                                                discount = parseFloat(this.selectedProducts[x].quantity) * parseFloat(res[i].discountPercent);
                                            }
                                        }
                                        //added now
                                        if (this.selectedProducts[x].pbe.Product2.Is_Subscribe__c) {
                                            if (res[i].tax.Tax_Rate__c != undefined) vatAmount1 = (res[i].tax.Apply_Tax_On__c == 'Cost Price' && res[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(res[i].tax.Tax_Rate__c) / 100 * (parseFloat(res[i].pbe.Purchase_Price__c))) : (parseFloat(res[i].tax.tax.Tax_Rate__c) / 100 * ((parseFloat(res[i].tax.pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) * parseFloat(No_of_Months)) + (parseFloat(res[i].tax.pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) * (parseFloat(No_of_Days) / 30)) - parseFloat(discount)));
                                            if (res[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (res[i].tax.Apply_Tax_On__c == 'Cost Price' && res[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(res[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(res[i].pbe.Purchase_Price__c))) : (parseFloat(res[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) * parseFloat(No_of_Months)) + (parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) * (parseFloat(No_of_Days) / 30)) - parseFloat(discount)));
                                        }
                                        if (!this.selectedProducts[x].pbe.Product2.Is_Subscribe__c) { //added now
                                            if (res[i].tax.Tax_Rate__c != undefined) vatAmount1 = (res[i].tax.Apply_Tax_On__c == 'Cost Price' && res[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(res[i].tax.Tax_Rate__c) / 100 * (parseFloat(res[i].pbe.Purchase_Price__c))) : (parseFloat(res[i].tax.Tax_Rate__c) / 100 * ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - discount));
                                            if (res[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (res[i].tax.Apply_Tax_On__c == 'Cost Price' && res[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(res[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(res[i].pbe.Purchase_Price__c))) : (parseFloat(res[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - discount));
                                        }
                                        res[i].vatAmount = vatAmount1;
                                        res[i].otherTax = otherTax1;
                                        res[i].totalTaxAmount = vatAmount1 + otherTax1;
                                        res[i].totalDiscount = discount;
                                        //added now
                                        if (!this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) { if (res[i].isPercent) { res[i].NetAmount = ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) - (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) * parseFloat(res[i].discountPercent)) / 100))); res[i].GrossAmount = ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) - (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) * parseFloat(res[i].discountPercent)) / 100) + (parseFloat(res[i].vatAmount) + parseFloat(res[i].otherTax)))); } else { res[i].NetAmount = (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - (parseFloat(this.selectedProducts[x].quantity) * parseFloat(res[i].discountPercent)))); res[i].GrossAmount = (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - (parseFloat(this.selectedProducts[x].quantity) * parseFloat(res[i].discountPercent)) + (parseFloat(res[i].vatAmount) + parseFloat(res[i].otherTax)))); } }
                                        if (this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) { //added now
                                            if (res[i].isPercent) {
                                                res[i].NetAmount = ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) - (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) * parseFloat(res[i].discountPercent)) / 100)));
                                                res[i].GrossAmount = ((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity) - (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) * parseFloat(res[i].discountPercent)) / 100) + (parseFloat(res[i].vatAmount) + parseFloat(res[i].otherTax))));
                                            } else {
                                                res[i].NetAmount = (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - (parseFloat(this.selectedProducts[x].quantity) * parseFloat(res[i].discountPercent))));
                                                res[i].GrossAmount = (((parseFloat(res[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[x].quantity)) - (parseFloat(this.selectedProducts[x].quantity) * parseFloat(res[i].discountPercent)) + (parseFloat(res[i].vatAmount) + parseFloat(res[i].otherTax))));
                                            }
                                        }
                                        res[i].pbe.Product2.nameUrl = '/' + res[i].pbe.Product2.Id;
                                        this.selectedProducts[x] = res[i];
                                    }
                                    else {
                                        this.selectedProducts[x].vatAmount = 0.0;
                                        this.selectedProducts[x].otherTax = 0.0;
                                        this.selectedProducts[x].totalTaxAmount = 0.0;
                                        this.selectedProducts[x].totalDiscount = 0.0;
                                        this.selectedProducts[x].NetAmount = 0.0;
                                        this.selectedProducts[x].GrossAmount = 0.0;
                                        this.selectedProducts[x].pbe.UnitPrice = 0.0;

                                    }
                                    console.log('this.selectedProducts after: ', JSON.stringify(this.selectedProducts[x]));
                                }
                            }

                            console.log('this.selectedProducts:', JSON.stringify(this.selectedProducts));
                        }

                    })
                    .catch(error => {
                        console.log('Error changeProfilehandler:', error);
                        this.spinner = false;
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    });
                this.spinner = false;
            }

        } catch (e) { console.log(e); }
    }
    profileRemove() {
        try {
            this.quote.Order_Profile__c = undefined;
        } catch (e) { console.log(e); }
    }
    employeeSelection(event) {
        try {
            this.quote.Employee__c = event.detail.Id;
        } catch (e) { console.log(e); }
    }
    employeeRemove() {
        try {
            this.quote.Employee__c = undefined;
        } catch (e) { console.log(e); }
    }
    requestedDateSelection(event) {
        try {
            this.quote.Request_Date__c = event.detail.value;
        } catch (e) { console.log(e); }
    }
    statusSelection(event) {
        try {
            this.quote.Status__c = event.detail.value;
            if (this.quote.Id != null) this.changedStatus = this.quote.Status__c;
        } catch (e) { console.log(e); }
    }
    currencySelection(event) {
        try {
            this.quote.CurrencyIsoCode = event.detail.value;
            this.quoteCurrency = event.detail.value;

        } catch (e) { console.log(e); }
    }
    billToSelection(event) {
        try {
            this.quote.Bill_To_Address__c = event.detail.Id;
            console.log('Selected Bill To Address ID: ', selectedAddressId);
            //this.quote.Bill_To_Address__c = selectedAddressId;
        } catch (e) { console.log(e); }
    }
    billToRemove() {
        try {
            this.quote.Bill_To_Address__c = undefined;
        } catch (e) { console.log(e); }
    }
    shipToSelection(event) {
        try {
            this.quote.Ship_To_Address__c = event.detail.Id;
            console.log('this.quote.Ship_To_Address__c bfr: ', this.quote.Ship_To_Address__c);
        } catch (e) { console.log(e); }
    }
    shipToRemove() {
        try {
            this.quote.Ship_To_Address__c = undefined;
        } catch (e) { console.log(e); }
    }
    handleQuoteDescription(event) {
        try {
            this.quote.Description__c = event.currentTarget.value;
        } catch (e) {
            console.log('Error:', e);
        }
    }

    fetchProducts(event) {
        this.searchItem = event.currentTarget.value;
        if (this.isGetSubscription)
            this.showAddProductsPageGetSubscription();
        else
            this.showAddProductsPage();
    }

    setProductFamily(event) {
        try {
            this.prodFamily = event.detail.value;
            this.showAddProductsPage();
        } catch (e) { console.log("Error", e); }
    }

    showAddProductsPageNormal() {
        console.log('entered showAddProductsPageNormal ');
        try {
            this.listOfCheckedProucts = [];
            this.isSubscriptionProd = false;
            this.showAddProductsPage();
        } catch (e) { console.log('Error:', error); }
    }

    showAddProductsPageSubscription() {
        try {
            this.isSubscriptionProd = true;
            this.showAddProductsPage();
        } catch (e) { console.log('Error:', error); }
    }

    ShowSubsPage = false;
    ShowSubriptionProdspage() {
        try {
            this.isSubscriptionProd = true;
            this.showAddProductsPage();
            this.flow = 'Subscription Product Page';
        }
        catch (e) { console.log('Error:', error); }
    }

    trackCount = 0;

    showAddProductsPage() {
        console.log('entered showAddProductsPage ');
        try {
            this.No_of_SelectedProds = 0;
            this.spinner = true;
            console.log('this.quote.CurrencyIsoCode : ' + this.quote.CurrencyIsoCode);
            fetchProducts({
                currProfile: this.quote.Order_Profile__c,
                billToAddId: this.quote.Bill_To_Address__c,
                shipToAddId: this.quote.Ship_To_Address__c,
                searchItem: this.searchItem,
                prodFamily: this.prodFamily,
                isSubscriptionProd: this.isSubscriptionProd,
                currencycode: this.quote.CurrencyIsoCode
            })
                .then(result => {
                    console.log('res of fetchProducts:', result);
                    let res = JSON.parse(JSON.stringify(result));

                    if (res.length > 0) {
                        res.forEach(element => {
                            if (element.pbe.Product2.Family != '' && element.pbe.Product2.Family == 'Software') {

                                element.isLicense = true;
                                element.isStock = false;

                                if (element.License > 0) {
                                    element.msg = true;
                                    element.Stock_Class = 'license_green';
                                }



                                if (element.License == 0) {
                                    element.License = 'Licenses Not Available';
                                    element.Stock_Class = 'license_Orange';
                                    element.msg = false;
                                }
                            }
                            else {
                                element.isLicense = false;
                                element.isStock = true;

                                if (element.stock == 0 && element.pbe.Product2.Allow_Back_Orders__c) {
                                    element.stock = 'Back Order';
                                    element.Stock_Class = 'stock-pill-Blue';
                                }

                                if (element.stock == 0 && element.pbe.Product2.Allow_Back_Orders__c == '') {
                                    element.stock = 0;
                                    element.Stock_Class = 'stock-pill-Red';
                                }
                                if (element.stock > 0)
                                    element.Stock_Class = 'stock-pill-Green';

                                if (element.pbe.Product2.Track_Inventory__c) this.trackCount += 1;
                            }

                            let tempDescription = element.pbe.Product2.Description;

                            if (element.pbe.Product2.Goods_Description__c && element.isgoodsDescription) element.pbe.Product2.Description = element.pbe.Product2.Goods_Description__c; else element.pbe.Product2.Description = tempDescription;

                            element.checkSelected = false;
                            element.pbe.Product2.nameUrl = '/' + element.pbe.Product2.Id;
                            element.selConfiguration = [];
                            element.isSelConfiguration = element.selConfiguration.length > 0 ? true : false;
                            element.isPSSPbe = false;
                            element.PSSPbe = [];

                        });


                        this.listOfProducts = res;
                        console.log('this.listOfProducts:', JSON.stringify(this.listOfProducts));
                        if (this.trackCount > 0 && !this.ShowStock) this.hideStockTableHeading = false; else this.hideStockTableHeading = true;
                    } else
                        this.listOfProducts = [];



                    if (this.isSubscriptionProd == true)
                        this.flow = 'Subscription Product Page';
                    else
                        this.flow = 'ListOfProdPg';

                    this.spinner = false;
                })
                .catch(error => {
                    console.log('Error:', error);
                    this.spinner = false;
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                })
        } catch (e) { console.log(e); }
    }
    backToMainPage() {
        this.frombackbutton = true;
        console.log("bill to address1", this.quote.Bill_To_Address__c);
        this.flow = 'MainPage';
        console.log("bill to address2", this.quote.Bill_To_Address__c);
        this.searchItem = '';
        console.log("bill to address3", this.quote.Bill_To_Address__c);
        this.prodFamily = '';
        console.log("bill to address4", this.quote.Bill_To_Address__c);

        this.isGetSubscription = false;
        console.log("bill to address5", this.quote.Bill_To_Address__c);

        this.Grid_view = false;
        console.log("bill to address6", this.quote.Bill_To_Address__c);

        this.Default_LisView = true;
        console.log("bill to address7", this.quote.Bill_To_Address__c);

        console.log("bill to address8", this.quote.Bill_To_Address__c);

    }




    handleDrag(event) {
        this.DragIndex = event.currentTarget.dataset.index;
    }

    allowDrop(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        try {
            let DragIndex = parseInt(this.DragIndex);
            let indexVal = parseInt(event.currentTarget.getAttribute('data-index'));
            let listOfLineItems = JSON.parse(JSON.stringify(this.selectedProducts));
            let ShiftElement = listOfLineItems[DragIndex];
            if (!ShiftElement) { this.spinner = false; return; }
            listOfLineItems.splice(DragIndex, 1);
            listOfLineItems.splice(indexVal, 0, ShiftElement);
            this.selectedProducts = listOfLineItems;
        } catch (e) { console.log('Error:', e); }
    }

    closeDeleteModal() {
        this.deleteConfirmation = false;
    }

    openDeleteModal(event) {
        console.log('open modal 1');
        if (!this.isOrderActivated) {
            console.log('open modal 2');
            this.indexToDel = event.currentTarget.dataset.index;
            this.lineIdToDel = event.currentTarget.dataset.id;
            this.ProdnameToDel = this.selectedProducts[this.indexToDel].pbe.Product2.Name;
            this.ProdUrlToDel = this.selectedProducts[this.indexToDel].pbe.Product2.nameUrl;

            this.deleteConfirmation = true;
        }
    }
    // DeleteprodDetails = [];
    removeLineItem(event) {

        console.log("inside removeLineItem");
        this.selectedProducts.splice(this.indexToDel, 1);
        if (this.lineIdToDel) {
            this.quoteLineToDelete.push(this.lineIdToDel);
        }
        this.indexToDel = undefined;
        this.lineIdToDel = undefined;
        this.deleteConfirmation = false;

    }


    handleStartDateSel(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let value = event.detail.value;
            console.log('Date value::', value);
            this.selectedProducts[index].startDate = value;
            this.calculateDateDifference(index);
            this.calculateSelItemsTax(index);
        } catch (e) { console.log('Error:', e); }
    }

    handleEndDateSel(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let value = event.detail.value;
            this.selectedProducts[index].endDate = value;

        } catch (e) { console.log('Error:', e); }
    }

    //Add this latest code for IsSubscribed funtionality , Saqlain Khan 
    handleEndDateSel(event) { try { let index = event.currentTarget.dataset.index; let value = event.detail.value; this.selectedProducts[index].endDate = value; this.calculateDateDifference(index); this.calculateSelItemsTax(index); } catch (e) { console.log('Error:', e); } }

    calculateDateDifference(index) {
        if (this.selectedProducts[index].startDate && this.selectedProducts[index].endDate) {
            const start = new Date(this.selectedProducts[index].startDate);
            const end = new Date(this.selectedProducts[index].endDate);

            // Calculate the difference in milliseconds
            const timeDifference = end - start;

            // Convert the time difference to days
            const daysDifference = timeDifference / (1000 * 60 * 60 * 24);

            // Calculate Year
            const Year = Math.floor(daysDifference / 365);

            // Calculate months
            const months = Math.floor((daysDifference % 365) / 30);

            // Calculate days
            const days = Math.floor((daysDifference % 365) % 30);

            this.selectedProducts[index].Year = Year;
            this.selectedProducts[index].Months = months;
            this.selectedProducts[index].Days = days;
        }
    }

    handleUnitPriceSel(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let value = event.currentTarget.value;
            this.selectedProducts[index].pbe.UnitPrice = (value != '') ? parseFloat(value) : '';
            this.selectedProducts[index].pbe.UnitPriceClass = this.selectedProducts[index].pbe.UnitPrice === '' ? 'hasError1 ' : ' ';
            this.calculateSelItemsTax(index);
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleQuantitySel(event) {
        try {
            console.log('Inside handleQuantitySel ------->');
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            this.selectedProducts[index].quantity = (value != '') ? parseFloat(value) : '';
            this.selectedProducts[index].quantityClass = this.selectedProducts[index].quantity == '' ? 'hasError1 ' : ' ';

            if (value && value != '') {
                this.spinner = true;
                getDiscountPlans({
                    profileId: this.quote.Order_Profile__c,
                    prodId: this.selectedProducts[index].pbe.Product2.Id,
                    quantity: this.selectedProducts[index].quantity
                })
                    .then(result => {
                        console.log('result of getDiscountPlans:', result);
                        this.selectedProducts[index].CurrentDiscounts = result[0].CurrentDiscounts;
                        this.selectedProducts[index].discountPlan = result[0].discountPlan;
                        this.selectedProducts[index].disPlans = result[0].disPlans;

                        this.selectedProducts[index].maxDiscount = result[0].maxDiscount;
                        this.selectedProducts[index].minDiscount = result[0].minDiscount;
                        this.selectedProducts[index].tierDists = result[0].tierDists;
                        this.selectedProducts[index].isPercent = result[0].isPercent;
                        console.log('this.selectedProducts[index]:', this.selectedProducts[index]);


                        //Auto discount plan handling
                        let discPlan = '';
                        if (result[0].disPlans.length > 0)
                            discPlan = result[0].disPlans[0].Id;
                        this.handleDiscPlanSel(index, discPlan);

                        this.spinner = false;
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error of getDiscountPlans:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            }
            this.calculateSelItemsTax(index);
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    discountPercent = 0;
    handleDiscountQuote(event) {
        try {
            let discount = event.currentTarget.value != '' ? parseFloat(event.currentTarget.value) : '';
            console.log('discount Quote:', discount);
            if (discount > 0) this.allowDiscount = true;
            if (discount == '' || discount < 0 || discount == 0) {
                this.allowDiscount = false; this.discountPercent = 0;
            }
            if (discount && discount !== '') {
                this.Product_Default_Discount = parseFloat(Product_Default_Discount_Limit);
                if (discount > parseFloat(Product_Default_Discount_Limit)) {
                    this.discountPercent = discount === '' ? '' : parseFloat(discount);
                    this.isDiscountPlanConfirmation = true;
                } else {
                    this.discountPercent = discount === '' ? '' : parseFloat(discount);
                    let selectedprodList = [];
                    selectedprodList = this.selectedProducts;
                    for (var i = 0; i < selectedprodList.length; i++) selectedprodList[i].discountPercent = this.discountPercent; this.selectedProducts = selectedprodList; for (var j in this.selectedProducts) this.calculateSelItemsTax(j);
                }
            } else { this.discountPercent = discount === '' ? '' : parseFloat(discount); }
        } catch (e) { console.log('Error:', e); }
    }


    handleDiscPlanSel(index, discountPlan) {//event
        try {
            this.spinner = true;

            this.selectedProducts[index].discountPlan = discountPlan;

            if (discountPlan != '') {
                for (var j = 0; j < this.selectedProducts[index].disPlans.length; j++) {
                    if (discountPlan == this.selectedProducts[index].disPlans[j].Id) {
                        if (this.selectedProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined) {
                            this.selectedProducts[index].isPercent = true;
                            if (this.selectedProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined)
                                this.selectedProducts[index].discountPercent = this.selectedProducts[index].disPlans[j].Default_Discount_Percentage__c;
                            else
                                this.selectedProducts[index].discountPercent = 0;
                            if (this.selectedProducts[index].disPlans[j].Floor_Discount_Percentage__c != undefined)
                                this.selectedProducts[index].minDiscount = this.selectedProducts[index].disPlans[j].Floor_Discount_Percentage__c;
                            else
                                this.selectedProducts[index].minDiscount = 0;
                            if (this.selectedProducts[index].disPlans[j].Ceiling_Discount_Percentage__c != undefined)
                                this.selectedProducts[index].maxDiscount = this.selectedProducts[index].disPlans[j].Ceiling_Discount_Percentage__c;
                            else
                                this.selectedProducts[index].maxDiscount = 0;
                        } else {
                            this.selectedProducts[index].isPercent = false;
                            if (this.selectedProducts[index].disPlans[j].Default_Discount_Value__c != undefined)
                                this.selectedProducts[index].discountPercent = this.selectedProducts[index].disPlans[j].Default_Discount_Value__c;
                            else
                                this.selectedProducts[index].discountPercent = 0;
                            if (this.selectedProducts[index].disPlans[j].Floor_Discount_Value__c != undefined)
                                this.selectedProducts[index].minDiscount = this.selectedProducts[index].disPlans[j].Floor_Discount_Value__c;
                            else
                                this.selectedProducts[index].minDiscount = 0;
                            if (this.selectedProducts[index].disPlans[j].Ceiling_Discount_Value__c != undefined)
                                this.selectedProducts[index].maxDiscount = this.selectedProducts[index].disPlans[j].Ceiling_Discount_Value__c;
                            else
                                this.selectedProducts[index].maxDiscount = 0;
                        }
                        this.spinner = false;
                        this.calculateSelItemsTax(index);
                        return;
                    }
                }
            } else {
                this.selectedProducts[index].discountPlan = discountPlan;
                this.selectedProducts[index].isPercent = true;

                this.selectedProducts[index].minDiscount = 0;
                this.selectedProducts[index].maxDiscount = 0;
            }
            this.calculateSelItemsTax(index);
            this.spinner = false;
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    handleDiscountSel(event) {
        try {
            let discount = event.currentTarget.value != '' ? parseFloat(event.currentTarget.value) : '';
            console.log('discount:', discount);
            let index = event.currentTarget.dataset.index;
            console.log('index:', index);
            this.currentSelIndex = index;
            if (discount === '') this.selectedProducts[index].discountClass = 'hasError1';
            else this.selectedProducts[index].discountClass = '';

            console.log('this.selectedProducts:', this.selectedProducts);
            if (discount && discount !== '') {
                console.log('inside discount:', discount);
                if (this.selectedProducts[index].maxDiscount != 0) {
                    if (discount > this.selectedProducts[index].maxDiscount) {
                        console.log('inside greater');
                        this.Product_Default_Discount = this.selectedProducts[index].maxDiscount;
                        this.selectedProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                        this.isDiscountPlanConfirmation = true;
                    } else {
                        console.log('inside smaller');
                        this.selectedProducts[index].discountPercent = discount != '' ? parseFloat(discount) : '';
                    }
                } else {
                    console.log('When no discount plan:', discount);
                    console.log('Product_Default_Discount_Limit:', parseFloat(Product_Default_Discount_Limit));
                    this.Product_Default_Discount = parseFloat(Product_Default_Discount_Limit);
                    if (discount > parseFloat(Product_Default_Discount_Limit)) {
                        this.selectedProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                        this.isDiscountPlanConfirmation = true;
                    } else
                        this.selectedProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                }
            } else {
                console.log('inside 2');
                this.selectedProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
            }

            console.log('this.selectedProducts[index]', this.selectedProducts[index]);
            this.calculateSelItemsTax(index);
        } catch (e) {
            console.log('Error:', e);
        }
    }

    Description1 = '';
    handleDescriptionSel(event) {
        try {
            console.log('callll:');

            let value = event.currentTarget.value;
            console.log('value:', value);

            let index = event.currentTarget.dataset.index;
            console.log('index:', index);


            this.selectedProducts[index].pbe.Product2.Description = value;

        } catch (e) {
            console.log('Error:', e);
        }
    }


    prodForConfig = {};
    defaultImg = '';
    IsSubscribed = false;
    handleCheckbox(event) {

        try {

            let checked = event.detail.checked;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].checkSelected = checked;
            console.log('this.listOfProducts[index].checkSelected::~>', this.listOfProducts[index].checkSelected);
            if (this.listOfProducts[index].pbe.Product2.Configure__c && checked) {
                this.prodForConfig = this.listOfProducts[index].pbe;
                this.prodForConfig.mainProductQuantity = this.listOfProducts[index].quantity;
                if (this.listOfProducts[index].pbe.Product2.Picture__c)
                    this.defaultImg = this.listOfProducts[index].pbe.Product2.Picture__c;
                this.flow = 'ConfPage';
            }

            if (checked) {
                this.spinner = true;
                var selectedProductIdList = [];
                for (var i in this.listOfProducts) {
                    if (this.listOfProducts[i].checkSelected == true) {
                        selectedProductIdList.push(this.listOfProducts[i].Id);
                    }
                }
                this.No_of_SelectedProds = selectedProductIdList.length;

                fetchOptionalProducts({
                    currProfile: this.quote.Order_Profile__c,
                    billToAddId: this.quote.Bill_To_Address__c,
                    shipToAddId: this.quote.Ship_To_Address__c,
                    prodId: this.listOfProducts[index].pbe.Product2.Id,
                })
                    .then(result => {
                        console.log('res of fetchOptionalProducts:', result);
                        let res = JSON.parse(JSON.stringify(result));

                        if (res.length > 0) {
                            res.forEach(element => {
                                if (element.stock == 0 && element.pbe.Product2.Allow_Back_Orders__c)
                                    element.stock = 'Back Order';
                                element.keyValue = element.pbe.Product2.Id + Math.random();
                                element.checkSelected = false;
                                element.pbe.Product2.nameUrl = '/' + element.pbe.Product2.Id;
                                element.selConfiguration = [];
                                element.isSelConfiguration = element.selConfiguration.length > 0 ? true : false;

                                 let alreadyChecked = this.listOfCheckedProucts.some(
                p => p.pbe.Product2Id === element.pbe.Product2Id
            );
            element.checkSelected = alreadyChecked;
                                
                            });
                            

                            this.listOfProducts[index].PSSPbe = res;
                            if (res.length > 0) this.listOfProducts[index].isPSSPbe = true;
                            else this.listOfProducts[index].isPSSPbe = false;
                        }

                        let selectedProduct = this.listOfProducts[index];
    let exists = this.listOfCheckedProucts.some(
        p => p.pbe.Product2Id === selectedProduct.pbe.Product2Id
    );

    if (!exists) {
        this.listOfCheckedProucts.push(selectedProduct);
    }

    console.log(
        'this.listOfCheckedProucts::',
        JSON.stringify(this.listOfCheckedProucts)
    );

                        //this.listOfCheckedProucts.push(this.listOfProducts[index]);

                        console.log('this.listOfCheckedProucts.push(this.listOfProducts[index])::', JSON.stringify(this.listOfCheckedProucts));
                        this.spinner = false;

                    })
                    .catch(error => {
                        console.log('Error:', error);
                        this.spinner = false;
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                    })
            }
            else {

                if (this.listOfProducts[index].checkSelected == false) {
                    this.No_of_SelectedProds = this.No_of_SelectedProds - 1;

                    for (var i in this.listOfCheckedProucts) {

                        if (i > -1) {

                            if (this.listOfCheckedProucts[i].pbe.Product2.Id === this.listOfProducts[index].pbe.Product2.Id)
                                this.listOfCheckedProucts.splice(i, 1);
                        }

                    }
                    console.log('this.listOfCheckedProucts:', JSON.stringify(this.listOfCheckedProucts));
                }

            }

        } catch (e) { console.log(e); }
    }

    backToListOfProdPg() {
        this.flow = 'ListOfProdPg';
    }

    handleUnitPrice(event) {
        try {
            console.log('event.currentTarget.value:', event.currentTarget.value);
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].pbe.UnitPrice = (value != '') ? parseFloat(value) : '';
            if (this.listOfProducts[index].pbe.UnitPrice === '') { this.listOfProducts[index].UnitPriceClass = 'hasError1 '; }
            else { this.listOfProducts[index].UnitPriceClass = ''; }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleQuantity(event) {
        try {
            console.log('Inside handleQuantity ------->');
            this.spinner = true;
            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            let prod = event.currentTarget.dataset.prodid;
            this.listOfProducts[index].quantity = (value != '') ? parseFloat(value) : '';
            if (this.listOfProducts[index].quantity == '') this.listOfProducts[index].quantityClass = 'hasError1';
            else this.listOfProducts[index].quantityClass = '';
            if (value && value != '') {
                getDiscountPlans({
                    profileId: this.quote.Order_Profile__c,
                    prodId: prod,
                    quantity: this.listOfProducts[index].quantity
                })
                    .then(result => {
                        console.log('result of getDiscountPlans:', result);
                        this.listOfProducts[index].CurrentDiscounts = result[0].CurrentDiscounts;
                        this.listOfProducts[index].discountPlan = result[0].discountPlan;
                        this.listOfProducts[index].disPlans = result[0].disPlans;
                        this.listOfProducts[index].discountPercent = result[0].discountPercent;
                        this.listOfProducts[index].maxDiscount = result[0].maxDiscount;
                        this.listOfProducts[index].minDiscount = result[0].minDiscount;
                        this.listOfProducts[index].tierDists = result[0].tierDists;
                        this.listOfProducts[index].isPercent = result[0].isPercent;

                        //Auto discount plan handling
                        let discPlan = '';
                        if (result[0].disPlans.length > 0)
                            discPlan = result[0].disPlans[0].Id;
                        this.handleDiscPlan(discPlan, index);
                        this.spinner = false;
                        console.log('this.listOfProducts[index]:', this.listOfProducts[index]);
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error of getDiscountPlans:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error.body.message)) this.errorList.push(error.body.message);
                        if (!this.errorList.includes(error.body.stackTrace) && error.body.stackTrace) this.errorList.push(error.body.stackTrace);
                    })
            } else {
                this.spinner = false;
            }
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDiscPlan(discountPlan, index) {//event
        try {
            this.spinner = true;

            this.listOfProducts[index].discountPlan = discountPlan;

            if (discountPlan != '') {
                for (var j = 0; j < this.listOfProducts[index].disPlans.length; j++) {
                    if (discountPlan == this.listOfProducts[index].disPlans[j].Id) {
                        if (this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined) {
                            this.listOfProducts[index].isPercent = true;
                            if (this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].discountPercent = 0;
                            if (this.listOfProducts[index].disPlans[j].Floor_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].minDiscount = this.listOfProducts[index].disPlans[j].Floor_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].minDiscount = 0;
                            if (this.listOfProducts[index].disPlans[j].Ceiling_Discount_Percentage__c != undefined)
                                this.listOfProducts[index].maxDiscount = this.listOfProducts[index].disPlans[j].Ceiling_Discount_Percentage__c;
                            else
                                this.listOfProducts[index].maxDiscount = 0;
                        } else {
                            this.listOfProducts[index].isPercent = false;
                            if (this.listOfProducts[index].disPlans[j].Default_Discount_Value__c != undefined)
                                this.listOfProducts[index].discountPercent = this.listOfProducts[index].disPlans[j].Default_Discount_Value__c;
                            else
                                this.listOfProducts[index].discountPercent = 0;
                            if (this.listOfProducts[index].disPlans[j].Floor_Discount_Value__c != undefined)
                                this.listOfProducts[index].minDiscount = this.listOfProducts[index].disPlans[j].Floor_Discount_Value__c;
                            else
                                this.listOfProducts[index].minDiscount = 0;
                            if (this.listOfProducts[index].disPlans[j].Ceiling_Discount_Value__c != undefined)
                                this.listOfProducts[index].maxDiscount = this.listOfProducts[index].disPlans[j].Ceiling_Discount_Value__c;
                            else
                                this.listOfProducts[index].maxDiscount = 0;
                        }
                        this.spinner = false;
                        return;
                    }
                }
            } else {
                this.listOfProducts[index].discountPlan = discountPlan;
                this.listOfProducts[index].isPercent = true;
                this.listOfProducts[index].discountPercent = 0;
                this.listOfProducts[index].minDiscount = 0;
                this.listOfProducts[index].maxDiscount = 0;
            }
            this.spinner = false;
        } catch (e) {
            this.spinner = false;
            console.log('Error:', e);
        }
    }

    handleDiscount(event) {
        try {
            let discount = event.currentTarget.value != '' ? parseFloat(event.currentTarget.value) : '';
            console.log('discount:', discount);
            let index = event.currentTarget.dataset.index;
            this.currentSelIndex = index;
            if (discount === '') this.listOfProducts[index].discountClass = 'hasError1';
            else this.listOfProducts[index].discountClass = '';
            console.log('this.listOfProducts:', this.listOfProducts);
            if (discount && discount !== '') {
                if (this.listOfProducts[index].maxDiscount != 0) {
                    if (discount > this.listOfProducts[index].maxDiscount) {
                        console.log('inside greater');
                        this.Product_Default_Discount = this.listOfProducts[index].maxDiscount;
                        this.listOfProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                        this.isDiscountPlanConfirmation = true;
                    } else {
                        console.log('inside smaller');
                        this.listOfProducts[index].discountPercent = discount != '' ? parseFloat(discount) : '';
                    }
                } else {
                    console.log('When no discount plan:', parseFloat(Product_Default_Discount_Limit));
                    if (discount > parseFloat(Product_Default_Discount_Limit)) {
                        this.listOfProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                        this.isDiscountPlanConfirmation = true;
                    } else
                        this.listOfProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
                }
            } else {
                console.log('inside 2');
                this.listOfProducts[index].discountPercent = discount === '' ? '' : parseFloat(discount);
            }
            console.log('this.listOfProducts:', this.listOfProducts);
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleDescription(event) {
        try {
            console.log('handle desc:');

            let value = event.currentTarget.value;
            let index = event.currentTarget.dataset.index;
            this.listOfProducts[index].pbe.Product2.Description = value;
            console.log('this.listOfProducts[index].pbe.Product2.Description::', this.listOfProducts[index].pbe.Product2.Description);
        } catch (e) {
            console.log('Error:', e);
        }
    }

    handleCheckboxPSS(event) {

        try {
            let checked = event.detail.checked;
            let index = event.currentTarget.dataset.index;
            let count = event.currentTarget.dataset.count;
            this.listOfProducts[index].PSSPbe[count].checkSelected = checked;
            if (this.listOfProducts[index].PSSPbe[count].pbe.Product2.Configure__c && checked) {
                this.prodForConfig = this.listOfProducts[index].PSSPbe[count].pbe;
                if (this.listOfProducts[index].PSSPbe[count].pbe.Product2.Picture__c) this.defaultImg = this.listOfProducts[index].PSSPbe[count].pbe.Product2.Picture__c;
                this.flow = 'ConfPage';
            }

        } catch (e) {
            console.log('Error:', e);
        }
    }






    validateSelProd() {
        try {
            console.log('inside validateSelProd1');
            let listOfProducts = this.listOfProducts;
            let count = 0;
            this.errorList = Object.assign([], this.errorList);
            this.errorList = undefined;
            for (let i in listOfProducts) {
                if (listOfProducts[i].checkSelected) {
                    count++;
                    if (this.ShowStock) return true;
                    else
                        if (!this.ShowStock) {
                            if (!listOfProducts[i].pbe.Product2.Allow_Back_Orders__c && listOfProducts[i].stock == 0 && listOfProducts[i].pbe.Product2.Track_Inventory__c) {
                                this.errorList = Object.assign([], this.errorList);
                                if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Stock/License not available')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Stock not available');
                                return false;
                            }
                        }



                    /*if (listOfProducts[i].pbe.UnitPrice === '' || listOfProducts[i].pbe.UnitPrice == undefined ||listOfProducts[i].pbe.UnitPrice <0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty');
                        return false;
                    }*/



                    if ((listOfProducts[i].pbe.UnitPrice === '' && !this.allowZeroUnitprice) || (listOfProducts[i].pbe.UnitPrice == undefined && !this.allowZeroUnitprice) || (listOfProducts[i].pbe.UnitPrice < 0 && !this.allowZeroUnitprice) || (listOfProducts[i].pbe.UnitPrice == 0 && !this.allowZeroUnitprice)) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty');
                        return false;
                    }



                    if (listOfProducts[i].quantity == '' || listOfProducts[i].quantity == undefined || listOfProducts[i].quantity == 0 || listOfProducts[i].quantity < 0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty');
                        return false;
                    }
                    if (listOfProducts[i].discountPercent === '' || parseFloat(listOfProducts[i].discountPercent) < 0) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty');
                        return false;
                    }
                    if (parseFloat(listOfProducts[i].discountPercent) > 100) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(listOfProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100%')) this.errorList.push(listOfProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100%');
                        return false;
                    }
                }
            }

            if (count == 0) {
                /*const event = new ShowToastEvent({
                    variant: 'error',
                    message: 'Please select Item to add',
                });
                this.dispatchEvent(event);*/
                this.errorvisible = true;
                this.Error_message = 'Please select Item to add';
                return false;
            }
            return true;
        } catch (e) {
            console.log('Error:', e);
        }
    }
    addProducts() {
        try {
            console.log('Inside Addproducts ------------------>'); 
            console.log('validateSelProd():', this.validateSelProd());
            if (this.validateSelProd()) {
                //Creating a metadata Type of OrderProduct Object

                let selectedProducts = this.selectedProducts;

                let listOfProducts = JSON.parse(JSON.stringify(this.listOfProducts));
                console.log('listOfProducts inside addProducts:', listOfProducts);

                let listOfCheckedProucts1 = JSON.parse(JSON.stringify(this.listOfCheckedProucts));
                console.log('listOfCheckedProucts1 inside addProducts:', listOfCheckedProucts1);

                for (let i in listOfCheckedProucts1) {
                    if (listOfCheckedProucts1[i].checkSelected) {
                        listOfCheckedProucts1[i].keyValue = listOfCheckedProucts1[i].pbe.Product2.Id + i + listOfCheckedProucts1[i].quantity + Math.random();
                        if (!listOfCheckedProucts1[i].lineStatus) listOfCheckedProucts1[i].lineStatus = 'Approved';

                        //Calulate Discount and taxes
                        var discount = 0;
                        var vatAmount1 = 0;
                        var otherTax1 = 0;
                        if (listOfCheckedProucts1[i].discountPercent != 0) {
                            if (listOfCheckedProucts1[i].isPercent) {
                                discount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100;
                            } else {
                                discount = parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent);
                            }
                        }
                        else {
                            if (listOfCheckedProucts1[i].discountPercent == 0 && this.handleDiscountField)
                                listOfCheckedProucts1[i].hideDiscount = true;
                            else
                                listOfCheckedProucts1[i].hideDiscount = false;
                        }

                        if (listOfCheckedProucts1[i].tax.Tax_Rate__c != undefined) vatAmount1 = (listOfCheckedProucts1[i].tax.Apply_Tax_On__c == 'Cost Price' && listOfCheckedProucts1[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(listOfCheckedProucts1[i].tax.Tax_Rate__c) / 100 * (parseFloat(listOfCheckedProucts1[i].pbe.Purchase_Price__c))) : (parseFloat(listOfCheckedProucts1[i].tax.Tax_Rate__c) / 100 * ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - discount));
                        if (listOfCheckedProucts1[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (listOfCheckedProucts1[i].tax.Apply_Tax_On__c == 'Cost Price' && listOfCheckedProucts1[i].pbe.Purchase_Price__c != undefined) ? (parseFloat(listOfCheckedProucts1[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(listOfCheckedProucts1[i].pbe.Purchase_Price__c))) : (parseFloat(listOfCheckedProucts1[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - discount));
                        listOfCheckedProucts1[i].vatAmount = vatAmount1
                        listOfCheckedProucts1[i].otherTax = otherTax1;
                        listOfCheckedProucts1[i].totalTaxAmount = vatAmount1 + otherTax1;
                        listOfCheckedProucts1[i].totalDiscount = discount;


                        //Calculate NetAmount and GrossAmount
                        if (listOfCheckedProucts1[i].isPercent) {
                            listOfCheckedProucts1[i].NetAmount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity) - (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100)));
                            listOfCheckedProucts1[i].GrossAmount = ((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity) - (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) * parseFloat(listOfCheckedProucts1[i].discountPercent)) / 100) + (parseFloat(listOfCheckedProucts1[i].vatAmount) + parseFloat(listOfCheckedProucts1[i].otherTax))));
                        } else {
                            listOfCheckedProucts1[i].NetAmount = (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - (parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent))));
                            listOfCheckedProucts1[i].GrossAmount = (((parseFloat(listOfCheckedProucts1[i].pbe.UnitPrice) * parseFloat(listOfCheckedProucts1[i].quantity)) - (parseFloat(listOfCheckedProucts1[i].quantity) * parseFloat(listOfCheckedProucts1[i].discountPercent)) + (parseFloat(listOfCheckedProucts1[i].vatAmount) + parseFloat(listOfCheckedProucts1[i].otherTax))));
                        }
                        selectedProducts.push(listOfCheckedProucts1[i]);

                    }
                }
                this.selectedProducts = selectedProducts;
                console.log('this.selectedProducts:', JSON.stringify(this.selectedProducts));
                if (this.selectedProducts.length > 0) {
                    for (let i in this.selectedProducts) {
                        if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c == true) {
                            //added now fro below this.selectedProducts[
                            const start = new Date(this.selectedProducts[i].startDate);
                            const end = new Date(this.selectedProducts[i].endDate);
                            console.log('start date-' + start + 'end date' + end);
                            let No_of_Months = (end.getFullYear() - start.getFullYear()) * 12 + (end.getMonth() - start.getMonth());
                            console.log('No_of_Months---' + No_of_Months);
                            this.selectedProducts[i].Months = No_of_Months;
                            this.selectedProducts[i].enable = true; this.selectedProducts[i].IsSubscribed = true; this.selectedProducts[i].qryFilter = " AND Product__c = '" + this.selectedProducts[i].pbe.Product2.Id + "'";
                        }
                        else {
                            this.selectedProducts[i].IsSubscribed = false;
                            this.selectedProducts[i].enable = false;
                        }

                    }


                    this.discountshow = false;
                    for (let j in this.selectedProducts) {

                        if (this.selectedProducts[j].discountPercent != 0)
                            this.discountshow = true;
                    }

                    //console.log('discountshow::', this.discountshow);
                    if (this.quote.Id != null && this.changedStatus) this.quote.Status__c = this.changedStatus;
                    this.flow = 'MainPage';
                    this.searchItem = '';
                    this.prodFamily = '';
                    this.isGetSubscription = false;
                }
            }
        } catch (e) {
            console.log('Error:', e);
        }
        console.log('End of Addproducts ------------------>');
    }


    @track visible = false;
    saveQuoteAndLine(event) {
        try {
            let isQuoteValid = this.validateQuote();
            let isQuoteLineValid = this.validateLines();
            console.log('isQuoteValid:', isQuoteValid);
            console.log('selectedProducts:', JSON.stringify(this.selectedProducts));

            if (isQuoteValid && isQuoteLineValid) {
                this.spinner = true;

                if (!this.isMultiCurrency) delete this.quote.CurrencyIsoCode;
                let quoteLines = [];
                for (let i in this.selectedProducts) {
                    quoteLines[i] = {};
                    if (this.selectedProducts[i].Id) quoteLines[i].Id = this.selectedProducts[i].Id;
                    let discount = 0;
                    if (this.selectedProducts[i].pbe.Id) quoteLines[i].Pricebook_Entry_Id__c = this.selectedProducts[i].pbe.Id;
                    quoteLines[i].sortOrder__c = i;
                    quoteLines[i].Status__c = this.selectedProducts[i].lineStatus;
                    if (this.selectedProducts[i].pbe.Product2.Name.length > 75) quoteLines[i].Name = this.selectedProducts[i].pbe.Product2.Name.substring(0, 75);
                    else quoteLines[i].Name = this.selectedProducts[i].pbe.Product2.Name;

                    //storing subscription information to Quote 
                    let No_of_Months = 0;                                      //&& (this.selectedProducts[i].PlanId != null || this.selectedProducts[i].PlanId != '')
                    if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                        // console.log('inside subscription save ---->');

                        // quoteLines[i].Product_Subscription_Plan_Allocation__c = this.selectedProducts[i].PlanId;
                        // quoteLines[i].Is_Subscribe__c = this.selectedProducts[i].pbe.Product2.Is_Subscribe__c;
                        // if (this.selectedProducts[i].startDate) quoteLines[i].Start_Date__c = this.selectedProducts[i].startDate;
                        // if (this.selectedProducts[i].Plan_Duration) quoteLines[i].Month_Duration__c = this.selectedProducts[i].Plan_Duration;
                        // if (this.selectedProducts[i].Order_frequency) quoteLines[i].Order_Delivery_Frequency__c = this.selectedProducts[i].Order_frequency;
                        //added nowwwww
                        console.log('inside subscription save ---->');
                        quoteLines[i].Is_Subscribe__c = this.selectedProducts[i].pbe.Product2.Is_Subscribe__c;
                        if (this.selectedProducts[i].Year > 0) { No_of_Months = this.selectedProducts[i].Year * 12; }
                        if (this.selectedProducts[i].Months > 0) { No_of_Months += this.selectedProducts[i].Months; }
                        quoteLines[i].Month_Duration__c = No_of_Months; quoteLines[i].Duration_in_Days__c = this.selectedProducts[i].Days;
                        if (this.selectedProducts[i].startDate) quoteLines[i].Start_Date__c = this.selectedProducts[i].startDate; if (this.selectedProducts[i].endDate) quoteLines[i].End_Date__c = this.selectedProducts[i].endDate;
                        console.log('subscribe condition--' + this.ApplyDiscountTaxOnWholeQuote);
                    }

                    //storing Non Subscribe information to Quote
                    else {
                        console.log('inside Normal  save ---->');
                    }

                    /*if (this.selectedProducts[i].isSubProd) {
                        quoteLines[i].Start_Date__c = this.selectedProducts[i].startDate;
                        quoteLines[i].End_Date__c = this.selectedProducts[i].endDate;
                    }*/
                    quoteLines[i].Product__c = this.selectedProducts[i].pbe.Product2.Id;
                    quoteLines[i].List_Price__c = this.selectedProducts[i].pbe.UnitPrice;
                    quoteLines[i].Quantity__c = this.selectedProducts[i].quantity;
                    if (this.selectedProducts[i].DynamicDiscount != null) {
                        console.log('Dynamic Discount lookup:', this.selectedProducts[i].DynamicDiscount);
                        quoteLines[i].Dynamic_Discount__c = this.selectedProducts[i].DynamicDiscount;
                        //quoteLines[i].Dynamic_Discount_Amount__c = this.selectedProducts[i].;
                    }
                    // if (this.selectedProducts[i].isPercent) {
                    //     quoteLines[i].Discount_Percent__c = this.selectedProducts[i].discountPercent;
                    //     console.log('Discount_Percent__c - 1 -- '+this.selectedProducts[i].discountPercent);
                    //     discount = (((this.selectedProducts[i].pbe.UnitPrice * this.selectedProducts[i].quantity) * this.selectedProducts[i].discountPercent) / 100);
                    //     quoteLines[i].Discount_Amount__c = discount;
                    // } else {
                    //     discount = this.selectedProducts[i].quantity * this.selectedProducts[i].discountPercent;
                    //     quoteLines[i].Discount_Amount__c = discount;
                    //     let total = quoteLines[i].List_Price__c * quoteLines[i].Quantity__c;
                    //     let per = (discount / total) * 100;
                    //     quoteLines[i].Discount_Percent__c = per;
                    //     console.log('Discount_Percent__c - 2 -- '+per);
                    // }
                    //added noww

                    //   if (this.selectedProducts[i].isPercent) {
                    //     quoteLines[i].Discount_Percent__c = this.selectedProducts[i].discountPercent;
                    //     if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) discount = discount = ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * parseFloat(No_of_Months)) + (parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity) * (parseFloat(this.selectedProducts[i].days) / 30)) * parseFloat(this.selectedProducts[i].discountPercent)) / 100;
                    //     if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) discount = (((this.selectedProducts[i].pbe.UnitPrice * this.selectedProducts[i].quantity) * this.selectedProducts[i].discountPercent) / 100);

                    //     quoteLines[i].Discount_Amount__c = discount;
                    // } else {
                    //     if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) discount = this.selectedProducts[i].quantity * this.selectedProducts[i].discountPercent;
                    //     if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) discount = (this.selectedProducts[i].quantity * this.selectedProducts[i].discountPercent * No_of_Months) + this.selectedProducts[i].quantity * this.selectedProducts[i].discountPercent * this.selectedProducts[i].this.selectedProducts[i].days;
                    //     quoteLines[i].Discount_Amount__c = discount;
                    //     let total;
                    //     if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) total = quoteLines[i].List_Price__c * quoteLines[i].Quantity__c;
                    //     if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) total = (quoteLines[i].List_Price__c * quoteLines[i].Quantity__c * No_of_Months) + (quoteLines[i].List_Price__c * quoteLines[i].Quantity__c * this.selectedProducts[i].Days);
                    //     let per = (discount / total) * 100;
                    //     quoteLines[i].Discount_Percent__c = per;
                    // }


                    if (this.selectedProducts[i].isPercent) {
                        quoteLines[i].Discount_Percent__c = this.selectedProducts[i].discountPercent;
                        let discount = 0;

                        if (this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                            // subscription base = (unitPrice * qty * months) + (unitPrice * qty * days/30)
                            const unitPrice = parseFloat(this.selectedProducts[i].pbe.UnitPrice) || 0;
                            const qty = parseFloat(this.selectedProducts[i].quantity) || 0;
                            const months = parseFloat(No_of_Months) || 0;
                            const days = parseFloat(this.selectedProducts[i].Days || this.selectedProducts[i].days) || 0;
                            const subscriptionBase = (unitPrice * qty * months) + (unitPrice * qty * (days / 30));
                            discount = (subscriptionBase * parseFloat(this.selectedProducts[i].discountPercent)) / 100;
                        } else {
                            discount = ((parseFloat(this.selectedProducts[i].pbe.UnitPrice) * parseFloat(this.selectedProducts[i].quantity)) * parseFloat(this.selectedProducts[i].discountPercent)) / 100;
                        }

                        quoteLines[i].Discount_Amount__c = discount;
                    } else {
                        let discount = 0;
                        if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) {
                            discount = (parseFloat(this.selectedProducts[i].quantity) || 0) * (parseFloat(this.selectedProducts[i].discountPercent) || 0);
                        } else {
                            const qty = parseFloat(this.selectedProducts[i].quantity) || 0;
                            const months = parseFloat(No_of_Months) || 0;
                            const days = parseFloat(this.selectedProducts[i].Days || this.selectedProducts[i].days) || 0;
                            // flat discount treated as amount per unit per period
                            discount = (qty * (parseFloat(this.selectedProducts[i].discountPercent) || 0) * months) + (qty * (parseFloat(this.selectedProducts[i].discountPercent) || 0) * (days / 30));
                        }

                        quoteLines[i].Discount_Amount__c = discount;
                        let total = 0;
                        if (!this.selectedProducts[i].pbe.Product2.Is_Subscribe__c) total = quoteLines[i].List_Price__c * quoteLines[i].Quantity__c;
                        else total = (quoteLines[i].List_Price__c * quoteLines[i].Quantity__c * No_of_Months) + (quoteLines[i].List_Price__c * quoteLines[i].Quantity__c * (parseFloat(this.selectedProducts[i].Days || this.selectedProducts[i].days) || 0));
                        let per = total !== 0 ? (discount / total) * 100 : 0;
                        quoteLines[i].Discount_Percent__c = per;
                    }

                    if (this.selectedProducts[i].discountPlan) quoteLines[i].Discount_Plan__c = this.selectedProducts[i].discountPlan;
                    if (this.selectedProducts[i].version) quoteLines[i].Product_Version__c = this.selectedProducts[i].version;
                    if (this.selectedProducts[i].tax.Id) quoteLines[i].Tax__c = this.selectedProducts[i].tax.Id;
                    if (this.selectedProducts[i].vatAmount != 0) quoteLines[i].VAT_Amount__c = this.selectedProducts[i].vatAmount;
                    if (this.selectedProducts[i].otherTax != 0) quoteLines[i].Other_Tax__c = this.selectedProducts[i].otherTax;
                    if (this.selectedProducts[i].pbe.Product2.Description) quoteLines[i].Description__c = this.selectedProducts[i].pbe.Product2.Description;
                    if (this.selectedProducts[i].pbe.Product2.Track_Inventory__c) quoteLines[i].Inventory_Tracked__c = this.selectedProducts[i].pbe.Product2.Track_Inventory__c;
                    quoteLines[i].Optional_Item__c = this.selectedProducts[i].Optional_Item__c;
                    quoteLines[i].FreeOfCharge__c = this.selectedProducts[i].FreeOfCharge__c;
                }



                console.log('this.quote:', JSON.stringify(this.quote));
                console.log('quoteLines:', JSON.stringify(quoteLines));
                console.log('this.quoteLineToDelete:', this.quoteLineToDelete);

                draftQuoteSave({
                    quote: JSON.stringify(this.quote),
                    quoteLines: JSON.stringify(quoteLines),
                    quoteLinesIdToDel: JSON.stringify(this.quoteLineToDelete)
                })
                    .then(result => {
                        console.log('result of draftQuoteSave:', JSON.stringify(result));
                        this.spinner = false;
                        if (result.includes('Line:')) {
                            this.errorList = Object.assign([], this.errorList);
                            if (result.includes('Some quote line Items require approvals')) {
                                if (!this.errorList.includes('Some quote line Items require approvals')) this.errorList.push('Some quote line Items require approvals');
                            } else {
                                if (!this.errorList.includes(result)) this.errorList.push(result);
                            }
                        } else {
                            /**
                             * Here not setting the selectedProducts Line Id, because Quote line have same products multiple times.
                             */
                            this.isFromDraftSave = true;
                            if (!this.isMultiCurrency) this.quote.CurrencyIsoCode = this.allCurrencies[0].value;
                            let qt = JSON.parse(result);
                            this.quote.Id = qt[0].Id;
                            this.fetchLineFromQuote(this.quote.Id);
                            this.quoteLineToDelete = [];
                            // const event = new ShowToastEvent({
                            //     variant: 'success',
                            //     message: 'Quote Saved Successfully',
                            // });
                            // this.dispatchEvent(event);

                            this.visible = true;
                            let timer = window.setTimeout(() => {
                                this.visible = false;
                                window.clearTimeout(timer)
                            }, 1750)
                        }
                    })
                    .catch(error => {
                        this.spinner = false;
                        console.log('Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(error)) this.errorList.push(error);
                    })

            }
        } catch (e) { console.log('Error:', e); }
    }
    validateQuote() {
        try {
            let count = 0;

            if (!this.template.querySelector('[data-id="qtCustomer"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtCustomer"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtContact"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtContact"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtProfile"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtProfile"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtEmployee"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtEmployee"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtReqDate"]').value) {
                this.template.querySelector('[data-id="qtReqDate"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtStatus"]').value) {
                this.template.querySelector('[data-id="qtStatus"]').className = 'hasError';
                count++;
            }

            if (!this.template.querySelector('[data-id="qtBillToAdd"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtBillToAdd"]').className = 'hasError';
                count++;
            }
            if (!this.template.querySelector('[data-id="qtShipToAdd"]').selectedRecordId) {
                this.template.querySelector('[data-id="qtShipToAdd"]').className = 'hasError';
                count++;
            }

            if (count > 0) {
                const event = new ShowToastEvent({
                    variant: 'error',
                    message: 'Required Field Missing',
                });
                this.dispatchEvent(event);

                return false;
            }
            else return true;
        } catch (e) { console.log('Error:', e); }
    }

    @track errorvisible = false;

    validateLines() {
        try {
            console.log('inside validateSelProd2');
            let selectedProducts = this.selectedProducts;
            let count = 0;
            this.errorList = Object.assign([], this.errorList);
            this.errorList = undefined;
            for (let i in selectedProducts) {
                count++;

                /*if (!selectedProducts[i].pbe.Product2.Allow_Back_Orders__c && selectedProducts[i].stock == 0 && !this.ShowStock) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Stock not available')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Stock not available');
                    return false;
                }*/

                if (this.ShowStock) return true;
                else
                    if (!this.ShowStock) {
                        if (!selectedProducts[i].pbe.Product2.Allow_Back_Orders__c && selectedProducts[i].stock == 0 && selectedProducts[i].pbe.Product2.Track_Inventory__c) {
                            this.errorList = Object.assign([], this.errorList);
                            if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Stock not available')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Stock not available');
                            return false;
                        }
                    }

                /*if (selectedProducts[i].pbe.UnitPrice === '' || selectedProducts[i].pbe.UnitPrice == undefined || selectedProducts[i].pbe.UnitPrice <0) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Unit Price can not be negative,zero or empty');
                    return false;
                }*/

                if ((selectedProducts[i].pbe.UnitPrice === '' && !this.allowZeroUnitprice) || (selectedProducts[i].pbe.UnitPrice == undefined && !this.allowZeroUnitprice) || (selectedProducts[i].pbe.UnitPrice < 0 && !this.allowZeroUnitprice) || (selectedProducts[i].pbe.UnitPrice == 0 && !this.allowZeroUnitprice)) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Unit Price can not be negative or empty')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Unit Price can not be negative,zero or empty');
                    return false;
                }




                if (selectedProducts[i].quantity === '' || selectedProducts[i].quantity == undefined || selectedProducts[i].quantity == 0 || selectedProducts[i].quantity < 0) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Quantity can not be negative, zero or empty');
                    console.log('selectedProducts[i].quantity::', selectedProducts[i].quantity);
                    return false;
                }
                if (selectedProducts[i].discountPercent === '' || parseFloat(selectedProducts[i].discountPercent) < 0) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Discount can not be negative or empty');
                    return false;
                }
                if (parseFloat(selectedProducts[i].discountPercent) > 100) {
                    this.errorList = Object.assign([], this.errorList);
                    if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100%')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Discount can not be greater than 100%');
                    return false;
                }

                if (selectedProducts[i].Is_Subscribe__c == true && (selectedProducts[i].PlanId != null || selectedProducts[i].PlanId != '')) {



                    if (selectedProducts[i].Plan_Duration == '' || selectedProducts[i].Plan_Duration == undefined) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Selected plan Does not have Duration.')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Selected plan Does not have Duration.');
                        return false;
                    }

                    if (selectedProducts[i].Order_frequency == '' || selectedProducts[i].Order_frequency == undefined) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Selected plan Does not have Order Frequency.')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Selected plan Does not have Order Frequency.');
                        return false;
                    }

                    let today1 = new Date();
                    let year = today1.getFullYear();
                    let month = '' + (today1.getMonth() + 1);
                    let day = '' + today1.getDate();
                    if (month.length < 2) month = '0' + month;
                    if (day.length < 2) day = '0' + day;
                    let today = [year, month, day].join('-');

                    if (selectedProducts[i].startDate < today) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Start date should be today or in future.')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Start date should be today or in future.');
                        return false;
                    }
                    if (!selectedProducts[i].startDate) {
                        this.errorList = Object.assign([], this.errorList);
                        if (!this.errorList.includes(selectedProducts[i].pbe.Product2.Name + ': Select a start date')) this.errorList.push(selectedProducts[i].pbe.Product2.Name + ': Select a start date');
                        return false;
                    }
                }
            }

            if (count == 0) {
                /*const event = new ShowToastEvent({
                    variant: 'error',
                    message: 'Add Products To Save',
                });
                this.dispatchEvent(event);*/
                this.errorvisible = true;
                this.Error_message = 'Add Products To Save';
                return false;
            }
            return true;
        } catch (e) {
            console.log('Error:', e);
        }
    }


    PandLView() {
        console.log('inside PandLView');
        console.log('PandLView selectedProducts==>' + JSON.stringify(this.selectedProducts));
        try {
            this.versionList = [];
            this.productsList = [];
            this.selectedProducts.forEach(element => {
                if (element.version != '') this.versionList.push(element.version);
                this.productsList.push(element.pbe.Product2Id);
            });
            console.log('PandLView productsList==>' + JSON.stringify(this.productsList));
            this.flow = 'showCalPandL';
        } catch (e) { console.log('Error:', e); }
    }


    @track resVersion;
    tooltip = false;
    showToolTip() {
        this.tooltip = true;
    }
    HideToolTip() {
        this.tooltip = false;
    }
    assignVersion(event) {
        try {
            console.log("configureEvent:", event.detail);
            this.spinner = true;
            this.resVersion = event.detail.resVersion;
            let prodId = event.detail.prodId;

            for (var i = 0; i < this.listOfProducts.length; i++) {
                if (prodId == this.listOfProducts[i].pbe.Product2.Id) {
                    this.listOfProducts[i].version = this.resVersion;

                    this.listOfProducts[i].pbe.UnitPrice = parseFloat(this.listOfProducts[i].pbe.UnitPrice) + parseFloat(event.detail.selProTotalPri);
                    this.listOfProducts[i].selConfiguration = event.detail.selConfiguration;
                    this.listOfProducts[i].isSelConfiguration = this.listOfProducts[i].selConfiguration.length > 0 ? true : false;
                    break;
                }
            }
            this.flow = 'ListOfProdPg';
            console.log("this.listOfProducts after set version", this.listOfProducts);
            this.spinner = false;
        } catch (e) { console.log('Error:', e); }

    }

    //commented by abuzar for handling the tax calculation for the subscription products
    // calculateSelItemsTax(index) {
    //     console.log('inside calculateSelItemsTax');
    //     try {
    //         var discount = 0;
    //         var vatAmount1 = 0;
    //         var otherTax1 = 0;


    //         if (this.selectedProducts[index].discountPercent != 0) {
    //             if (this.selectedProducts[index].isPercent) {
    //                 discount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100;
    //             } else {
    //                 discount = parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent);
    //             }
    //         }
    //         if (this.selectedProducts[index].tax.Tax_Rate__c != undefined) vatAmount1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - parseFloat(discount)));
    //         if (this.selectedProducts[index].tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - parseFloat(discount)));
    //         this.selectedProducts[index].vatAmount = vatAmount1;
    //         this.selectedProducts[index].otherTax = otherTax1;
    //         this.selectedProducts[index].totalTaxAmount = vatAmount1 + otherTax1;
    //         this.selectedProducts[index].totalDiscount = discount;


    //         //Calculate NetAmount and GrossAmount
    //         if (this.selectedProducts[index].isPercent) {
    //             this.selectedProducts[index].NetAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) - (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100)));
    //             this.selectedProducts[index].GrossAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) - (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax))));
    //         } else {
    //             this.selectedProducts[index].NetAmount = (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - (parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent))));
    //             this.selectedProducts[index].GrossAmount = (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - (parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent)) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax))));
    //         }
    //         console.log('this.selectedProducts[index]:', this.selectedProducts[index]);
    //     } catch (e) { console.log('Error:', e); }
    // }

    //added by abuzar for handling the tax calculation for the subscription products

    // calculateSelItemsTax(index) {
    //     console.log('inside calculateSelItemsTax');
    //     try {
    //         var discount = 0;
    //         var vatAmount1 = 0;
    //         var otherTax1 = 0;

    //         let No_of_Months = 0;
    //         let No_of_Days = 0;

    //         if (this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) {
    //             if (this.selectedProducts[index].Year > 0) { No_of_Months = this.selectedProducts[index].Year * 12; } if (this.selectedProducts[index].Months > 0) { No_of_Months += this.selectedProducts[index].Months; } if (this.selectedProducts[index].Days > 0) { No_of_Days = this.selectedProducts[index].Days; }
    //             console.log('No_of_Months:', No_of_Months);
    //         }

    //         if (this.selectedProducts[index].discountPercent != 0) {
    //             if (this.selectedProducts[index].isPercent) {
    //                 if (!this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) discount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100;
    //                 if (this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) discount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months)) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100;
    //             } else {
    //                 discount = parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent);
    //             }
    //         }
    //         console.log('discount in calculateSelItemsTax:', discount);
    //         if (this.selectedProducts[index].discountPercent == 0) discount = 0;
    //         if (this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) {
    //             if (this.selectedProducts[index].tax.Tax_Rate__c != undefined) vatAmount1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months)) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)) - parseFloat(discount)));
    //             if (this.selectedProducts[index].tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months)) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)) - parseFloat(discount)));
    //         }
    //         console.log('AZ total tax',vatAmount1);
    //         console.log('AZ other Tax 1',otherTax1);
    //         console.log('AZ vat + other',vatAmount1 + otherTax1);
            
    //         if (!this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) {
    //             if (this.selectedProducts[index].tax.Tax_Rate__c != undefined) vatAmount1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - parseFloat(discount)));
    //             if (this.selectedProducts[index].tax.Other_Tax_Rate__c != undefined) otherTax1 = (this.selectedProducts[index].tax.Apply_Tax_On__c == 'Cost Price' && this.selectedProducts[index].pbe.Purchase_Price__c != undefined) ? (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * (parseFloat(this.selectedProducts[index].pbe.Purchase_Price__c))) : (parseFloat(this.selectedProducts[index].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - parseFloat(discount)));
    //         }
    //         this.selectedProducts[index].vatAmount = vatAmount1;
    //         this.selectedProducts[index].otherTax = otherTax1;
    //         this.selectedProducts[index].totalTaxAmount = vatAmount1 + otherTax1;
    //         this.selectedProducts[index].totalDiscount = discount;

    //         //Calculate NetAmount and GrossAmount
    //         if (!this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) {
    //             if (this.selectedProducts[index].isPercent) { console.log('7'); this.selectedProducts[index].NetAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) - (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100))); this.selectedProducts[index].GrossAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) - (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) * parseFloat(this.selectedProducts[index].discountPercent)) / 100) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax)))); }
    //             else { console.log('8'); this.selectedProducts[index].NetAmount = (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - (parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent)))); this.selectedProducts[index].GrossAmount = (((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity)) - (parseFloat(this.selectedProducts[index].quantity) * parseFloat(this.selectedProducts[index].discountPercent)) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax)))); }
    //             console.log('net amount 1 --' + this.selectedProducts[index].NetAmount);
    //         }
    //         else
    //             if (this.selectedProducts[index].pbe.Product2.Is_Subscribe__c) { if (this.selectedProducts[index].isPercent) { console.log('99'); this.selectedProducts[index].NetAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months)) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30))); console.log('999---this.selectedProducts[index].NetAmount---' + this.selectedProducts[index].NetAmount); this.selectedProducts[index].GrossAmount = (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)) - ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30))) * parseFloat(this.selectedProducts[index].discountPercent) / 100) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax))); } else { console.log('10'); this.selectedProducts[index].NetAmount = (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) - parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) * parseFloat(this.selectedProducts[index].discountPercent) + parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)); this.selectedProducts[index].GrossAmount = ((parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30))) - (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * parseFloat(No_of_Months) * parseFloat(this.selectedProducts[index].discountPercent) + (parseFloat(this.selectedProducts[index].pbe.UnitPrice) * parseFloat(this.selectedProducts[index].quantity) * (parseFloat(No_of_Days) / 30)))) + (parseFloat(this.selectedProducts[index].vatAmount) + parseFloat(this.selectedProducts[index].otherTax)); } }
    //         console.log('11--this.selectedProducts[index].NetAmount--' + this.selectedProducts[index].NetAmount);
    //     } catch (e) { console.log('Error:', e); }
    // }

    //enhanced version of the above method for better readability and performance by Abuzar

    calculateSelItemsTax(index) {
    console.log('inside calculateSelItemsTax');
    try {
        const item = this.selectedProducts[index];

        // Safely extract booleans / strings
        const isSubscribe = item.pbe?.Product2?.Is_Subscribe__c;
        const applyTaxOnCostPrice = item.tax?.Apply_Tax_On__c === 'Cost Price';

        // Convert everything to numbers once
        const quantity        = Number(item.quantity) || 0;
        const unitPrice       = Number(item.pbe?.UnitPrice) || 0;
        const purchasePrice   = Number(item.pbe?.Purchase_Price__c) || 0;
        const discountPercent = Number(item.discountPercent) || 0;    // percent OR flat value (based on isPercent)
        const isPercent       = !!item.isPercent;

        const taxRate         = item.tax?.Tax_Rate__c != null
            ? Number(item.tax.Tax_Rate__c)
            : null;

        const otherTaxRate    = item.tax?.Other_Tax_Rate__c != null
            ? Number(item.tax.Other_Tax_Rate__c)
            : null;

        const year   = Number(item.Year)   || 0;
        const months = Number(item.Months) || 0;
        const days   = Number(item.Days)   || 0;

        // Subscription duration
        let No_of_Months = 0;
        let No_of_Days   = 0;

        if (isSubscribe) {
            if (year   > 0) No_of_Months += year * 12;
            if (months > 0) No_of_Months += months;
            if (days   > 0) No_of_Days    = days;

            console.log('No_of_Months:', No_of_Months);
        }

        // Common base amounts
        const normalBaseAmount = unitPrice * quantity;
        const subMonthAmount   = unitPrice * quantity * No_of_Months;
        const subDayAmount     = unitPrice * quantity * (No_of_Days / 30);
        const subBaseAmount    = subMonthAmount + subDayAmount;

        // -------------------- DISCOUNT --------------------
        let discount = 0;

        if (discountPercent !== 0) {
            if (isPercent) {
                // Percent discount on total amount
                if (!isSubscribe) {
                    discount = (normalBaseAmount * discountPercent) / 100;
                } else {
                    discount = (subBaseAmount * discountPercent) / 100;
                }
            } else {
                // Flat per-unit discount
                discount = quantity * discountPercent;
            }
        }

        console.log('discount in calculateSelItemsTax:', discount);

        if (discountPercent === 0) {
            discount = 0;
        }

        // -------------------- TAX CALCULATION --------------------
        let vatAmount1   = 0;
        let otherTax1    = 0;
        let taxBaseAmount;

        if (isSubscribe) {
            if (applyTaxOnCostPrice && purchasePrice) {
                taxBaseAmount = purchasePrice;
            } else {
                taxBaseAmount = subBaseAmount - discount;
            }

            if (taxRate != null) {
                vatAmount1 = (taxRate / 100) * taxBaseAmount;
            }

            if (otherTaxRate != null) {
                otherTax1 = (otherTaxRate / 100) * taxBaseAmount;
            }
        }

        if (!isSubscribe) {
            if (applyTaxOnCostPrice && purchasePrice) {
                taxBaseAmount = purchasePrice;
            } else {
                taxBaseAmount = normalBaseAmount - discount;
            }

            if (taxRate != null) {
                vatAmount1 = (taxRate / 100) * taxBaseAmount;
            }

            if (otherTaxRate != null) {
                otherTax1 = (otherTaxRate / 100) * taxBaseAmount;
            }
        }

        console.log('AZ total tax', vatAmount1);
        console.log('AZ other Tax 1', otherTax1);
        console.log('AZ vat + other', vatAmount1 + otherTax1);

        const totalTax = vatAmount1 + otherTax1;

        item.vatAmount       = vatAmount1;
        item.otherTax        = otherTax1;
        item.totalTaxAmount  = totalTax;
        item.totalDiscount   = discount;

        // -------------------- NET & GROSS AMOUNT --------------------
        if (!isSubscribe) {
            // Non-subscription products
            let netAmount  = 0;
            let grossAmount = 0;

            if (isPercent) {
                console.log('7');
                netAmount   = normalBaseAmount - (normalBaseAmount * discountPercent / 100);
                grossAmount = netAmount + totalTax;
            } else {
                console.log('8');
                netAmount   = normalBaseAmount - (quantity * discountPercent);
                grossAmount = netAmount + totalTax;
            }

            item.NetAmount   = netAmount;
            item.GrossAmount = grossAmount;
            console.log('net amount 1 --' + item.NetAmount);
        } else {
            // Subscription products
            if (isPercent) {
                console.log('99');

                const base = subBaseAmount; // month + day
                const discountForSub = (base * discountPercent) / 100;
                item.NetAmount   = base - discountForSub;  // Subtract discount from NetAmount
                console.log('999---this.selectedProducts[index].NetAmount---' + item.NetAmount);

                item.GrossAmount = base - discountForSub + totalTax;
            } else {
                console.log('10');

                // Keeping your original math, just using the precomputed variables
                const netAmount =
                    subMonthAmount
                    - (quantity * No_of_Months * discountPercent)
                    + subDayAmount;

                const grossAmount =
                    (subMonthAmount + subDayAmount)
                    - (subMonthAmount * discountPercent + subDayAmount)
                    + totalTax;

                item.NetAmount   = netAmount;
                item.GrossAmount = grossAmount;
            }
        }

        console.log('11--this.selectedProducts[index].NetAmount--' + item.NetAmount);
    } catch (e) {
        console.log('Error:', e);
    }
}


    closeDiscountPlanConfirmation() {
        try {
            if (this.flow == 'MainPage') {
                this.selectedProducts[this.currentSelIndex].lineStatus = 'Approved';
                this.selectedProducts[this.currentSelIndex].discountPercent = 0;
                this.calculateSelItemsTax(this.currentSelIndex);
            } else if (this.flow == 'ListOfProdPg') {
                this.listOfProducts[this.currentSelIndex].lineStatus = 'Approved';
                this.listOfProducts[this.currentSelIndex].discountPercent = 0;
            }

            this.isDiscountPlanConfirmation = false;
        } catch (e) { console.log('Error:', e); }

    }

    makeLineWaitingForApproval() {
        this.quote.Status__c = 'Waiting for approval';
        if (this.flow == 'MainPage') {
            this.selectedProducts[this.currentSelIndex].lineStatus = 'Waiting for Approval';
        } else if (this.flow == 'ListOfProdPg') {
            this.listOfProducts[this.currentSelIndex].lineStatus = 'Waiting for Approval';
        }

        this.isDiscountPlanConfirmation = false;
    }


    renderedCallback() {
        try {
            console.log('inside QuoteConsole renderedCallback');

            Promise.all([
                loadStyle(this, cpqassets + '/css/QuoteConsole.css'),
                loadStyle(this, cpqassets + '/css/global-axolt.css'),
                //loadStyle(this, maqcustom + '/css/main-style.css'),
                loadStyle(this, bootStrap + '/css/bootstrap-4.1.css'),
                loadStyle(this, fontawesome + '/fontawesome5/css/all.css'),
                loadStyle(this, cpqtheme + '/css/slim.css'),


            ])
                .then(() => {
                    console.log('Static Resource Loaded');
                })
                .catch(error => {
                    console.log('Static Resource Error', error);
                });
        } catch (e) {
            console.log('Error:', e);
        }
        console.log('End of QuoteConsole renderedCallback');
    }

    handleChange(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let value1 = event.detail.value;
            this.selectedProducts[index].value = value1;
        } catch (e) { console.log('Error:', e); }

    }

    ShowListView() {
        this.Grid_view = false;
        this.Default_LisView = true;

        var applynewclass1 = "WCCPM13 WCCPM14";
        var applynewclass2 = "WCCPM13 WCCPM14 acitve-list2";

        this.DefaultListView = applynewclass2;
        this.DefaultGridView = applynewclass1;
    }

    ShowGridView() {
        this.Grid_view = true;
        this.Default_LisView = false;

        var applynewclass1 = "WCCPM13 WCCPM14";
        var applynewclass2 = "WCCPM13 WCCPM14 acitve-list2";

        this.DefaultListView = applynewclass1;
        this.DefaultGridView = applynewclass2;

    }

    handleEndDate(event) {
        let StartDate = event.currentTarget.value;
        var dt = new Date(StartDate);
        alert('Start Date::~>', dt);
        //dt.setDate(dt.getDate() + 3);
    }
    ShowMainPage() {
        this.flow = 'MainPage';
    }
    SubsPlanSelection(event) {
        let index = event.currentTarget.dataset.index;
        let value = JSON.stringify(event.detail.Id);
    }
    ShowSubsPlanPage() {
        this.flow = 'Subscription Plans page';
    }
    prodURL(event) {
        try {
            console.log('inside prodURL');
            let currentIndex = event.currentTarget.dataset.index;
            //event.detail.title
            console.log('val:', currentIndex);
            const rowData = this.planlist[currentIndex];
            window.open('/' + rowData.Id, '_blank');
        } catch (e) {
            console.log('Error:', e);
        }
    }

    CreateOrEditPlan = false;
    @track Modeltitel = '';




    ChevroIcontoggle(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let IconName = event.target.iconName;
            console.log('Icon Index::~>', IconName);

            if (IconName == 'utility:chevrondown') {
                this.selectedProducts[index].IsSubscribed = false;
                event.target.iconName = 'utility:chevronright';
            }
            if (IconName == 'utility:chevronright') {
                this.selectedProducts[index].IsSubscribed = true;
                event.target.iconName = 'utility:chevrondown';
            }
        } catch (e) { console.log('Error:', e); }
    }

    Open_Subscribe_Modal = false;
    showSubPlans = false;
    ParentIndex;
    ProdIdPlan = '';
    enable = false;


    closeSubscribeModal() {
        this.Open_Subscribe_Modal = false;
    }

    Plan_Duration = '';
    Order_frequency = '';
    startDate = '';
    selecetedPlan(event) {
        try {

            let index = event.currentTarget.dataset.index;
            this.selectedProducts[index].PlanId = event.detail.Id;
            console.log('index::', index);
            console.log('Plan Id::', this.selectedProducts[index].PlanId);
            this.spinner = true;
            let plan = this.selectedProducts[index].PlanId;
            if (this.selectedProducts[index].PlanId) {
                console.log("Inside the planselection with PlanId::", this.PlanId);
                getSelplanDetails({ selectedPlan_Id: plan })
                    .then(result => {

                        console.log('Selected plan result:', result.SelectedsubPlan);
                        let res = JSON.parse(JSON.stringify(result.SelectedsubPlan));

                        this.selectedProducts[index].Plan_Duration = res.Subscription_Plan__r.Duration__c;
                        this.selectedProducts[index].Order_frequency = res.Subscription_Plan__r.Order_Delivery_Frequency__c;
                        //this.handleDiscPlanSel(index, discPlan);
                        this.calculateSelItemsTax(index);


                        this.spinner = false;
                    })
                    .catch(error => {
                        console.log('getSelectedplanDetails Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                    })
            }
        } catch (e) { console.log(e); }

    }

    removeplan(event) {
        try {
            let index = event.currentTarget.dataset.index;
            this.selectedProducts[index].PlanId = '';
        } catch (e) { console.log(e); }
    }

    getrelatedplans(event) {
        let index = event.currentTarget.dataset.index;
        console.log('index::', index);
        this.ProdIdPlan = this.selectedProducts[index].pbe.Product2.Id;
    }

    DocumentURL = '';
    CurrentBaseURL = '';
    OpenQuoteDoc() {
        try {
            if (this.quote.Id && this.quote.Id != '') {
                console.log('Quote Id::-->', this.quote.Id);
                var URL_Ord = '';
                this.DocumentURL = QuoteDocCustomLink;
                var URL_Ord = "/apex/" + this.DocumentURL + "?CustId=" + this.quote.Contact__c + "&Id=" + this.quote.Id;
                window.open(URL_Ord, '_blank');
            }
        } catch (e) { console.log(e); }
    }

    RefreshQuote() {
        try {
            this.spinner = true;
            if (this.quote.Id && this.quote.Id != '') {
                this.fetchLineFromQuote(this.quote.Id);
            }
            let timer = window.setTimeout(() => {
                this.spinner = false;
                window.clearTimeout(timer)
            }, 1750)

        } catch (e) {
            console.log('Error:', e);
        }
    }

    closeToast() {
        this.visible = false;
    }


    closeerror() {
        this.errorvisible = false;
    }

    get DiscountHide() {

        if (this.discountshow && this.hideDiscount)
            return true;
        else
            return false;
    }


    viewConfig = false;
    @api configoptions = [];
    @track configoptions1 = [];
    Quotelinelist = [];

    @track QuotelineIcon = 'utility:chevrondown';
    @track showBomtable = true;

    openviewconfig(event) {

        try {
            this.viewConfig = true;
            this.showBomtable = true;

            if (this.quote.Id) {
                this.Quotelineindex = event.currentTarget.dataset.index;
                this.QuotelineId = event.currentTarget.dataset.id;
                this.QuotelineVersion = this.selectedProducts[this.Quotelineindex].version;
                this.spinner = true;

                FetchBOMs({
                    QuoteLineId: this.QuotelineId,
                    QuotelineVersion: this.QuotelineVersion,
                })
                    .then(result => {

                        let Q = 0;
                        let QuotelineItemArray = [];
                        result.QuoteLineItem.forEach(QuoteLineItem => {
                            QuotelineItemArray[Q] = {
                                Id: QuoteLineItem.Id,
                                prodName: QuoteLineItem.Name,
                                totalUnitPrice: QuoteLineItem.TotalPrice__c,
                                Quantity: QuoteLineItem.Quantity__c,
                                QuotelinePicture: QuoteLineItem.Product__r.Picture__c,
                                IsversionAvailable: QuoteLineItem.Product_Version__c ? true : false,
                            };
                        });


                        let Lvl1Bom = result.QuoteLineBOM;

                        let Lvl2Bom = result.Level2BOM;


                        const result1 = Lvl1Bom.map(Lvl1B => {
                            let temp = [];
                            Lvl2Bom.forEach(lvl2Bo => {
                                if (lvl2Bo.BOM_Version__c == Lvl1B.Component_Version__c) {
                                    temp.push(lvl2Bo);
                                }
                            })
                            Lvl1B.RelatedChildBoms = temp;
                            Lvl1B.showlvl2 = true;
                            return Lvl1B;
                        })

                        this.Quotelinelist = QuotelineItemArray;
                        console.log('this.Quotelinelist::', JSON.stringify(this.Quotelinelist));
                        for (var a in result1) {
                            if (!result1[a].RelatedChildBoms.length > 0) result1[a].showAddIcon = false; else result1[a].showAddIcon = true;
                        }
                        this.configoptions1 = result1;
                        console.log('result1::', JSON.stringify(result1));
                        this.spinner = false;
                    })

                    .catch(error => {
                        console.log('FetchBOMs Error:', error);
                        this.errorList = Object.assign([], this.errorList);
                    })

            }
        } catch (e) { console.log('Error:', e); }

    }

    closeviewconfig() {
        this.viewConfig = false;
        this.showBomtable = false;
    }

    getSelectedOptions(event) {
        this.configoptions = event.detail.SelectedOptions;
    }

    handleQuotelineIcon(event) {
        if (this.QuotelineIcon === 'utility:chevrondown') {
            this.QuotelineIcon = 'utility:chevronup';
            this.showBomtable = false;
        }
        else if (this.QuotelineIcon === 'utility:chevronup') {
            this.QuotelineIcon = 'utility:chevrondown';
            this.showBomtable = true;
        }

    }

    ChevroIcontoggleBOms(event) {
        try {
            let index = event.currentTarget.dataset.index;
            let IconName = event.target.iconName;

            if (IconName === 'utility:jump_to_bottom') {
                this.configoptions1[index].showlvl2 = false;
                event.target.iconName = 'utility:jump_to_right';
            }
            if (IconName === 'utility:jump_to_right') {
                this.configoptions1[index].showlvl2 = true;
                event.target.iconName = 'utility:jump_to_bottom';
            }
        } catch (e) { console.log('Error:', e); }
    }
    onCheck(event) {
        try {
            let index = event.currentTarget.dataset.index;
            console.log('event.detail.checked; : ', event.detail.checked);
            if (index != null && index != '' && index != undefined) {
                this.selectedProducts[index].Optional_Item__c = event.detail.checked;

            }
        } catch (e) { console.log('Error:', e); }
    }

    onCheckFOC(event) {
        try {
            let index = event.currentTarget.dataset.index;
            console.log('event.detail.checked; : ', event.detail.checked);
            if (index != null && index != '' && index != undefined) {
                this.selectedProducts[index].FreeOfCharge__c = event.detail.checked;
            }
        } catch (e) { console.log('Error:', e); }
    }

    checkindex1(event) {
        console.log("checkindex1 ::", event.currentTarget.dataset.index);
    }
    checkindex2(event) {
        console.log("checkindex2 ::", event.currentTarget.dataset.index);
    }

    applyDiscount(event) {
        try {
            var discountplanId = event.detail.value;
            let index = event.currentTarget.dataset.index;
            console.log('Seledcted value in applyDiscount:', event.detail.value);
            if (discountplanId != null && discountplanId != '--None--') {
                getdiscountplandetails({
                    planId: discountplanId
                })
                    .then(result => {
                        console.log('getDiscount plan Info result:', JSON.stringify(result));
                        this.listOfProducts[index].discountPlan = result.Id;
                        this.listOfProducts[index].discountPercent = result.Discount_Percent__c;
                        if (result.RecordType.Name == 'Dynamic Discount') {
                            this.listOfProducts[index].DynamicDiscount = result.Id;
                        }
                    })
                    .catch(error => {
                        console.log('getDiscount plan Info Error:', error);
                    })
            }
            if (discountplanId == '--None--' || discountplanId != null) {
                console.log('in here');
                this.listOfProducts[index].DynamicDiscount = '';
                this.listOfProducts[index].discountPercent = 0;
            }
        } catch (e) { console.log('getDiscount log error', e); }

    }
    handleDescriptionPSS(event) {
        console.log('handleDescriptionPSS:');

        try {
            console.log('handleDescriptionPSS:');

            let value = event.target.value;
            console.log('value:', value);

            let index = event.currentTarget.dataset.index;
            console.log('index:', index);

            this.listOfProducts[index].pbe.Product2.Description = value;
            console.log('this.listOfProducts[index].pbe.Product2.Description: ', this.listOfProducts[index].pbe.Product2.Description);
            console.log('prods: ', this.listOfProducts);
            // Force UI reactivity if necessary
            this.listOfProducts = [...this.listOfProducts];  // Shallow copy to trigger UI update
        } catch (e) {
            console.log('Error:', e);
        }
    }
    get iconDisableOrNot() { return this.isOrderActivated ? 'disableIcon' : 'clickableIcon'; }

    get isOrderActivated() { return this.quote.Status__c != 'Draft' ? true : false; }


}