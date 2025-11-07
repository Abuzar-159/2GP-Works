import lookUp from '@salesforce/apex/Lookup.search';
//import fetchLookUpValueById from '@salesforce/apex/Lookup.fetchLookUpValueById';
import { api, LightningElement, track, wire } from 'lwc';
import {refreshApex} from '@salesforce/apex';

export default class customLookUp extends LightningElement {

    @api objName;
    @api iconName;
    @api limit = '5';
    @api filter = '';
    @api searchPlaceholder='Search';
    @api selectedValue;
    @api selectedName;
    @track records;
   @api isValueSelected;
    @track blurTimeout;
    @track message='';
    @api selectedNameUrl;
    @api hideRemove=false;

    @api searchTerm;
    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    @wire(lookUp, {searchTerm : '$searchTerm', myObject : '$objName', filter : '$filter', num : '$limit'})
    wiredRecords({ error, data }) {
        console.log('customLookUp wire lookUp called searchTerm~>'+this.searchTerm+' objName~>'+this.objName+' filter~>'+this.filter);
        console.log('customLookUp this.selectedName : '+this.selectedName+' this.selectedValue : '+this.selectedValue);
        if(this.selectedName != '' && this.selectedName != null){
            console.log('inside if');
            this.selectedName = this.selectedName;
            if(this.selectedValue != null && this.selectedValue != '') this.selectedNameUrl = '/'+this.selectedValue;
            this.isValueSelected = true;
            this.message='';
            return refreshApex(this.isValueSelected);
        }
        else if(data) {
            if(data.length == 0)
                this.message='No Result Found...';
            else
                this.message='';
            this.error = undefined;
            this.records = data;

        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    /*@api onclickAK(AccId,Name){
        console.log('onclickAK call back ');
        console.log('record:',this.records);
        console.log('onclickAK call back :',AccId);
        console.log('selectedValue :',this.selectedValue);
        this.selectedValue=AccId;
        this.selectedName=Name;
    }

    renderedCallback() {
        console.log('renderedCallback call back ');
        console.log('selectedValue :',this.selectedValue);
    }
    connectedCallback() {
        console.log('connected call back ');
        console.log('selectedValue :',this.selectedValue);
       // this.isValueSelected = true;
       // this.inputClass = 'slds-has-focus';
        //this.boxClass = 'slds-combobox slds-has-focus';
    }*/
   /* @wire(fetchLookUpValueById, {ObjectName :'$objName',SearchField : '$searchTerm',recordId : '$selectedValue'})
    wiredRecords({ error, data }) {
        if (data) {
            console.log('data fetchLookUpValueById : ',data);
            this.error = undefined;
            var result = data;
            this.selectedName = result.Name;
            console.log('this.selectedName wired: ',this.selectedName);
            this.isValueSelected = true;
            return refreshApex(this.isValueSelected);
            //this.records = data;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

connectedCallback(){
    console.log('this.selectedValue : ',this.selectedValue);
    if(this.selectedValue != '' && this.selectedValue != null && this.selectedValue != undefined){

        this.searchTerm = 'Name';
        fetchLookUpValueById({ObjectName :this.objName,SearchField : this.searchTerm,recordId : this.selectedValue}).then(result=>{
            console.log('result : ',result);
            //this.records = result;
            this.selectedName = result.Name;
            this.isValueSelected = true;
            console.log('this.selectedName renderedCallback: ',this.selectedName);
            this.isValueSelected = true;
            console.log('this.isValueSelected renderedCallback: ',this.isValueSelected);
            return refreshApex(this.selectedName);

          })
          .catch(error=>{
            console.log('fetchLookUpValueById',error);
          })
    }
}*/
    handleClick() {
        console.log('handle click called');
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
    }

    onBlur() {
        this.blurTimeout = setTimeout(() =>  {this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus'}, 300);
    }

    onSelect(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        const valueSelectedEvent = new CustomEvent('lookupselected', {detail: { Id: selectedId,Name : selectedName } });
        this.dispatchEvent(valueSelectedEvent);
        this.isValueSelected = true;
        this.selectedName = selectedName;
        this.selectedNameUrl='/'+selectedId;
        if(this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    }

    @api handleRemovePill(event) {
        console.log('handleRemovePill called');
        this.isValueSelected = false;
        this.selectedName = '';
        this.selectedValue = '';
        //event.preventDefault();
        this.dispatchEvent(new CustomEvent('remove'));
        console.log('handle remoce succesfulle');
       // return refreshApex(this.isValueSelected);
    }

    onChange(event) {
        this.searchTerm = event.target.value;
    }

}