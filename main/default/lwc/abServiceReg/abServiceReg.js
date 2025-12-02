import { LightningElement, track, api } from 'lwc';
import getCheckForWarnings from '@salesforce/apex/ABHome_Sch.getCheckForWarnings';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getReg from '@salesforce/apex/ABHome_Sch.getReg';
// import getBookingCancelled from '@salesforce/apex/ABHome_Sch.getBookingCancelled';
// import getBookRegistration from '@salesforce/apex/ABHome_Sch.getBookRegistration';
import getCancellationReasons from '@salesforce/apex/ABHome_Sch.getCancellationReasons';
// import getRegUpdates from '@salesforce/apex/ABHome_Sch.getRegUpdates';
import updateRegRcord from '@salesforce/apex/ABHome_Sch.updateRegRcord';
import updateCancelReg from '@salesforce/apex/Queue_Sch.updateCancelReg';

export default class AbServiceReg extends LightningElement {
    @track createReg = {
        sobjectType: 'Registration__c',
        Id: '',
        Customer_Name__c: '',
        Customer_Lastname__c: '',
        Customer_Email__c: '',
        Customer_Contact__c: '',
        Resource__r: {},
    Product2__r: {},
    Expert_Location__r: {}
    };
    @track cancellationReasons = [];
    @track cancellationReason='';
    @track showCancelModal=false;
    @track showABServiceResource=true;
    @track showMainSpin = false;
    @track isMultiBooking = false;
    @track saveErrorMsg = '';
    @track isReschedule = true  ;
    @track showBookingWarning = false;
    @track AutoResourceAllocation=false;
    @track showNotAvailableSlots=false;
    @track selectedDate;
    @track allowed=true;
    @api RId;
    @api MId;
    @api AId;
    @track toastMessage='';

    connectedCallback() {
        try{
         console.log('LWC received RId:', this.RId);
        console.log('MId:', this.MId);
        console.log('AId:', this.AId);
          getReg({ RegId: this.RId })
            .then(result => {
                this.createReg = result;
                  if (this.createReg.Status__c !== 'Booked' || this.createReg.Event__c != null || this.createReg.Event__c != null ) {
    this.allowed = false;   // your flag
} else {
    this.allowed = true;
    this.fetchCancellationReasons(); 
}
                console.log('result', JSON.stringify(result));
                if (this.createReg?.Registration_Time__c) {
                    console.log('Issue 0?'); 
   //adnan let -> const regTime
                    const regTime = this.createReg.Registration_Time__c; // e.g. 2025-09-01T11:00:00.000Z
    this.selectedDate = regTime.split('T')[0];         // → "2025-09-01"
  
   console.log('Issue 1?'); 

} else {
    // fallback → today
    this.selectedDate = new Date().toISOString().split('T')[0];
}

            })
            .catch(error => {
                console.error('Error fetching registration:', error);
            });
          
        }catch (error) {
            console.error('Error in CC:', error);
        }
    }
    async fetchCancellationReasons() {
        try {
            console.log('Issue 2?'); 
            const result = await getCancellationReasons();
            this.cancellationReasons = result.map(option => ({
                label: option.label,
                value: option.value
            }));
            console.log('Issue 3?'); 
        } catch (error) {
            console.error('Error fetching cancellation reasons:', error);
        }
    }
    handleCloseModal() {
        this.showCancelModal = false;
        this.cancellationReason = '';
    }
    async handleConfirmCancel() {
        try {
            //this.isLoading = true;
            this.createReg.Status__c='Cancelled';
            await updateCancelReg({ Rg: String(this.createReg.Id), cancelReason: this.cancellationReason });
            //this.showToast('Success', 'Registration cancelled successfully.', 'success');
            this.toastMessage='Registration cancelled successfully.';
            this.showCancelModal = false;
            this.cancellationReason = '';
        } catch (error) {
            console.error('Error cancelling registration:', error);
            //this.errorMessage = 'Error cancelling registration: ' + error.body.message;
        } 
    }
    handleCancellationReasonChange(event) {
        this.cancellationReason = event.detail.value;
        console.log('cancellationReason:',this.cancellationReason);
    }

    handleChangeDate() {
        this.showABServiceResource=false;
    }
    // Handle form input changes
    handleInputChange(event) {
        const field = event.target.dataset.id;
        this.createReg[`${field}__c`] = event.target.value;
          console.log('result', JSON.stringify(this.createReg));
    }

    // Example: Call Apex for warnings
    async checkForWarning() {
        try {
            this.showMainSpin = true;
            const res = await getCheckForWarnings({
                RegJSON: JSON.stringify(this.createReg),
                selectedDate: this.selDate,
                BookingStartTime: this.bookingStartTime,
                BookingEndTime: this.bookingEndTime
            });
            this.showBookingWarning = !res;
        } catch (err) {
            console.error('checkForWarning error', err);
        } finally {
            this.showMainSpin = false;
        }
    }
    get isPastRegistration() {
    if (this.createReg?.Registration_Time__c) {
        const regDate = new Date(this.createReg.Registration_Time__c);
        const now = new Date();
        return regDate <= now; // disable if registration time is in the past or now
    }
    return true; // default to disabled if not set
}

handleBack(){
    window.location.assign('/' + this.createReg.Id);
}

async handleUpdate(){
    await updateRegRcord({ Reg: this.createReg });
    this.toastMessage = 'Reservation Updated Successfully!';
    setTimeout(() => this.toastMessage = '', 5000);
}
closeToast(){
     this.toastMessage = '';
}

async handleCancel(){
    this.showCancelModal = true;
    /*await getBookingCancelled({ RegId: this.createReg.Id });
    console.log('result', JSON.stringify(this.createReg));
    this.createReg.Status__c='Cancelled';
    this.toastMessage = 'Reservation Cancelled Successfully!';
    setTimeout(() => this.toastMessage = '', 3000);*/
}

}