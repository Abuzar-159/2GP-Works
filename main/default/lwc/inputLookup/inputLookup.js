//import lookUp from '@salesforce/apex/InputLookUp.searchItems';
import fetchLookUpValues from '@salesforce/apex/InputLookUpCPQ.fetchLookUpValues';
import fetchLookUpValueById from '@salesforce/apex/InputLookUpCPQ.fetchLookUpValueById';
import { api, LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';


export default class inputLookup extends LightningElement {

    @api objName;
    @api iconName;
    @api qry = '';
    @api searchPlaceholder = 'Search...';
    @api recordId;  //@api selectedValue;
    @api selectedName;
    @track records;
    @api isValueSelected;
    @track blurTimeout;
    @track message = '';
    @api selectedNameUrl;
    @api hideRemove = false;
    @api labelName;
    @api SearchField = 'Name';
    @api required = false;
    @api reset = false;

    isOnSelect = false;

    // added by Abubakar on 27/11/2025
    @api
    focus() {
        const input = this.template.querySelector('input');
        if (input) {
            input.focus();
        }
    }

    @api searchTerm = '';
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = 'slds-input';

    /*@wire(lookUp, { searchTerm: '$searchTerm', myObject: '$objName', qry: '$qry' })
    wiredRecords({ error, data }) {
        console.log('wire lookUp called');
        console.log('this.selectedName : ', this.selectedName);
        console.log('this.recordId : ', this.recordId);
        if (this.selectedName != '' && this.selectedName != null) {
            console.log('inside if');
            this.selectedName = this.selectedName;
            if (this.recordId != null && this.recordId != '') this.selectedNameUrl = '/' + this.recordId;
            this.isValueSelected = true;
            this.message = '';
            return refreshApex(this.isValueSelected);
        }
        else if (data) {
            if (data.length == 0)
                this.message = 'No Result Found...';
            else
                this.message = '';
            this.error = undefined;
            this.records = data;

        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    handleClick() {
        console.log('handle click called');
        //this.searchTerm = '';
        this.inputClass = 'slds-has-focus slds-input';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
       
    }
    
    onChange(event) {
        console.log('inside onchange:', event.target.value);
        this.searchTerm = event.target.value;
    }
    */

    onBlur() {
        this.blurTimeout = setTimeout(() => { this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus' }, 300);
    }

    onSelect(event) {
        this.isOnSelect = true;
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('lookupselected', { detail: { Id: selectedId, Name: selectedName } });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        this.selectedName = selectedName;
        this.selectedNameUrl = '/' + selectedId;
        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    handleRemovePill(event) {
        this.isOnSelect=false;
        this.isValueSelected = false;
        this.selectedName = '';
        this.recordId = '';
        event.preventDefault();
        this.dispatchEvent(new CustomEvent('remove'));
    }

    @api get selectedRecordId() {
        return this.recordId;
    }
    set selectedRecordId(value) {
        if (value)
            this.recordId = value;
        else
            this.recordId = '';
        if (!this.isOnSelect)
            this.fetchRecordById();
    }



    fetchRecordById() {
        console.log('fetchRecordById called:', this.recordId);
        if (this.recordId) {
            fetchLookUpValueById({
                ObjectName: this.objName,
                SearchField: this.SearchField,
                recordId: this.recordId,
            })
                .then(result => {
                    console.log(result);
                    if (result) {
                        const valueSelectedEvent = new CustomEvent('lookupselected', {
                            detail: {
                                Id: result.Id,
                                Name: result.Name,
                            }
                        });
                        this.dispatchEvent(valueSelectedEvent);
                        this.isValueSelected = true;
                        this.selectedName = result.Name;
                        this.selectedNameUrl = '/' + result.Id;
                        if (this.blurTimeout) {
                            clearTimeout(this.blurTimeout);
                        }
                        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                })
        } else if (this.recordId === '' && this.reset) {
            this.isValueSelected = false;
            this.selectedName = '';
            this.selectedNameUrl = '';
        }
    }

//     handleInputChange(event) {
//         this.inputClass = 'slds-has-focus slds-input';
//         this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
//         //window.clearTimeout(this.delayTimeout);

//         this.searchTerm = event.target.value;
//         console.log('searchKey:', this.searchTerm);
//         console.log('queryFilter:', this.qry);
//         console.log('ObjectName:', this.objName);
//         console.log('SearchField:', this.SearchField);
//         if (this.searchTerm == '' || !this.searchTerm) this.searchTerm = '';


//         fetchLookUpValues({
//             searchKeyWord: this.searchTerm,
//             ObjectName: this.objName,
//             queryFilter: this.qry,
//             SearchField: this.SearchField,

//         })
//             .then(result => {
//                 if (result) {
//                     console.log('sucess fetchLookUpValues');
//                     let res = JSON.parse(JSON.stringify(result));
//                     for (let i in res)
//                         res[i].keyValue = res[i].Id + i;
//                     if (res.length == 0)
//                         this.message = 'No Result Found...';
//                     else
//                         this.message = '';
//                     this.records = res;
//                 }
//             })
//             .catch(error => {
//                 console.log('catch fetchLookUpValues');
//                 console.error('Error:', error);
//             })
//             .finally(() => {
//             });
//     }
//fixed by matheen : not showing the contacts when we create using the account tab from epos and more than 1 contacts then needed to refresh

handleInputChange(event) {
    this.inputClass = 'slds-has-focus slds-input';
    this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';

    // Update searchTerm immediately to reflect the input
    this.searchTerm = event.target.value || '';
    console.log('searchKey:', this.searchTerm);

    const eventToParent = new CustomEvent('searchtermchange', {
        detail: this.searchTerm
    });
    this.dispatchEvent(eventToParent);

    // Log query details for debugging
    console.log('queryFilter before validation:', this.qry);
    console.log('ObjectName:', this.objName);
    console.log('SearchField:', this.SearchField);

    // Validate and fix the queryFilter
    if (this.qry) {
        this.qry = this.qry.trim();
        if (!this.qry.toUpperCase().includes('WHERE') && !this.qry.toUpperCase().startsWith('AND')) {
            this.qry = 'AND ' + this.qry;
        }
    } else {
        this.qry = '';
    }

    console.log('queryFilter after validation:', this.qry);
// added by matheen to avoid text getting cut off in the input box due to calling apex without a delay
    // Clear any existing timeout to debounce the search
    if (this.debounceTimeout) {
        clearTimeout(this.debounceTimeout);
    }

    // Set a new timeout to debounce the fetchLookUpValues call
    this.debounceTimeout = setTimeout(() => {
        fetchLookUpValues({
            searchKeyWord: this.searchTerm,
            ObjectName: this.objName,
            queryFilter: this.qry,
            SearchField: this.SearchField,
        })
            .then(result => {
                if (result) {
                    console.log('success fetchLookUpValues');
                    let res = JSON.parse(JSON.stringify(result));
                    for (let i in res) {
                        res[i].keyValue = res[i].Id + i;
                    }
                    this.message = res.length === 0 ? 'No Result Found...' : '';
                    this.records = res;
                }
            })
            .catch(error => {
                console.log('catch fetchLookUpValues');
                console.error('Error:', error);
            })
            .finally(() => {
                // Optional cleanup if needed
            });
    }, 300); // 300ms debounce delay
}
}