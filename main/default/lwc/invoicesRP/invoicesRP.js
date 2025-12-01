import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getInvoicesForAccount from '@salesforce/apex/Epos.getInvoicesForAccount';

export default class invoicesRP extends NavigationMixin(LightningElement) {

    @api recordId;   // coming from Account page
    _loaded = false;
    @track invoices = [];
    pageNumber = 1;
    pageSize = 10;
    totalRecords = 0;
    searchText = '';
    isLoading = false;
    errorMessage = '';

  renderedCallback() {
    if (!this._loaded && this.recordId) {
        this._loaded = true;
        this.loadInvoices();
    }
}


    loadInvoices() {
    this.isLoading = true;
    this.errorMessage = '';

    getInvoicesForAccount({
        accountId: this.recordId,
        pageNumber: this.pageNumber,
        pageSize: this.pageSize,
        searchText: this.searchText
    })
    .then(result => {
        this.totalRecords = result.totalRecords;

        this.invoices = result.invoices.map((inv, i) => ({
            Id: inv.Id,
            OrderId: inv.Order_S__c,
            OrderNumber: inv.Order_S__r?.OrderNumber,
            InvoiceNumber: inv.Name,
            AccountId: inv.Account__c,
            AccountName: inv.Account__r?.Name,
            ContactId: inv.Contact__c,
            ContactName: inv.Contact__r?.Name,
            CompanyId: inv.Company__c,
            CompanyName: inv.Company__r?.Name,
            InvoiceDate: inv.Invoice_Date__c,
            DueDate: inv.Due_Date__c,
            RowNumber: (this.pageNumber - 1) * this.pageSize + i + 1
        }));
    })
    .catch(error => {
        console.error(error);
        this.errorMessage = 'Failed to load invoices';
    })
    .finally(() => {
        this.isLoading = false;
    });
}


    handleSearch(event) {
        this.searchText = event.target.value;
        this.pageNumber = 1;
        this.loadInvoices();
    }

    handleNext() {
        this.pageNumber++;
        this.loadInvoices();
    }

    handlePrev() {
        this.pageNumber--;
        this.loadInvoices();
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    get disablePrev() {
        return this.pageNumber <= 1;
    }
    get hasInvoices() {
    return this.invoices && this.invoices.length > 0;
}
navigateToInvoice(event) {
    const id = event.target.closest('tr').dataset.id;
    this.navigateRecord(id);
}

navigateToOrder(event) {
    const id = event.target.closest('tr').dataset.orderid;
    this.navigateRecord(id);
}

navigateToAccount(event) {
    const id = event.target.closest('tr').dataset.accountid;
    this.navigateRecord(id);
}

navigateToContact(event) {
    const id = event.target.closest('tr').dataset.contactid;
    this.navigateRecord(id);
}

navigateToCompany(event) {
    const id = event.target.closest('tr').dataset.companyid;
    this.navigateRecord(id);
}

navigateRecord(recordId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: 'Invoice__c',
            actionName: 'view'
        }
    });
}
createInvoice() {
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
           url: `/apex/CreateInvoiceRecord?FromACRelatedPage=true&accountId=${this.recordId}`
        }
    });
}

}