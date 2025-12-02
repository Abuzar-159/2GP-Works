import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import fetchTimeSlots from '@salesforce/apex/ABHome_Sch.getTimeSlots';
import createRegistration from '@salesforce/apex/ABHome_Sch.getCreateReg';
import getUsersByTimeZone from '@salesforce/apex/ABHome_Sch.getUsersByTimeZone';
import getBookRegistration from '@salesforce/apex/ABHome_Sch.getBookRegistration';
import CancelBooking from '@salesforce/apex/ABHome_Sch.CancelBooking';
import getSearchRecords from '@salesforce/apex/EventBooking_Sch.getSearchRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class AbResourceScheduler extends NavigationMixin(LightningElement) {
  @api expertId;
  @api rId;
  @api serviceName;
  @api locName;
  @api locId;
  @api serviceId;
  @api isMultiBooking = false;
  @api rescheduleBool = false;
  @api reschedule=false;
  @api autoResourceAllocation = false;
  @api showNotAvailableSlots = false;
  @api country;
  @track isInit=true;
  @track setConfirm=false;
  @track formattedDate;
  @track isPrevDisabled = false;

  @track showTabs = 'cus';
  @track activeTab = { cus: 'slds-is-active', inv: '', pay: '' };
  @track searchString = '';
  @api selectedDate;
  @track availableUsers = [];
  @track availableUsersOrg = [];
  @track availableSlots = [];
  @track morningSlots = [];
  @track afternoonSlots = [];
  @track eveningSlots = [];
  @track selectedMeeting = '';
  @track showMainSpin = false;
  @track showBooking = false;
  @track payNowDisabled = false;
  @track transactionMsg = '';
  @track cardNumber = '';
  @track cardCvv = '';
  @track cardHolderName = '';
  @track expMonth = '';
  @track expYear = '';
  @api createReg = {};
  @track selectedExpertId = '';
  @track selectedExpertDuration = 30; // Default duration
  @track timeselectedSlot = '';
  @track autoResourceAllocationVal = false;
  @track srcList = [];
  @track showSearchPanels = false;

  @track searchClientString = '';
    @track srList = [];
    @track showSearchIcons = true;
    @track showSearchPanel = false;
    @track toastMessage='';


  meetingOptions = [
    { value: 'zoom', class: 'zoom' },
    { value: 'goto', class: 'goto' },
    { value: 'microsoft', class: 'microsoft' },
    { value: 'hangout', class: 'hangout' },
    { value: 'cisco', class: 'cisco' }
  ];
allSections = ['morning', 'afternoon', 'evening'];
  monthOptions = [
    { label: '01', value: '01' },
    { label: '02', value: '02' },
    // Add more months
  ];

  yearOptions = [
    { label: '2025', value: '25' },
    { label: '2026', value: '26' },
    // Add more years
  ];
  mapFieldName(name) {
    const fieldMap = {
        firstName: 'Customer_Name__c',
        lastName: 'Customer_Lastname__c',
        email: 'Customer_Email__c',
        phone: 'Customer_Contact__c'
    };
    return fieldMap[name];
}

  connectedCallback() {
    this.initializeComponent();
     console.log('--- Props received in <c-ab-resource-scheduler> ---');
        console.log('selecteddate:', this.selectedDate);
        console.log('expertId:', this.expertId);
        console.log('serviceName:', this.serviceName);
        console.log('locName:', this.locName);
        console.log('locId:', this.locId);
        console.log('serviceId:', this.serviceId);
        console.log('isMultiBooking:', this.isMultiBooking);
        console.log('rescheduleBool:', this.rescheduleBool);
        console.log('autoResourceAllocation:', this.autoResourceAllocation);
        console.log('showNotAvailableSlots:', this.showNotAvailableSlots);
        console.log('country:', this.country);
        console.log('----------------------------------------------------');
        const today = new Date().toISOString().split('T')[0];
        //this.selectedDate = today;
        this.updateFormattedDate(today);
        this.checkPrevDisabled(today);
  }
  
    handlePrev() {
      //let -> const by adnan
       // let date = new Date(this.selectedDate);
       const date = new Date(this.selectedDate);
        date.setDate(date.getDate() - 1);

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        if (date >= today) {
            this.selectedDate = date.toISOString().split('T')[0];
            this.updateFormattedDate(this.selectedDate);
        }
        this.checkPrevDisabled(this.selectedDate);
        this.fetchSlots();
    }

    handleNextDate() {
      console.log('Inside handleNextDate:',this.selectedDate);
      //let -> const by adnan
       //let date = new Date(this.selectedDate);
       const date = new Date(this.selectedDate);
        date.setDate(date.getDate() + 1);

        this.selectedDate = date.toISOString().split('T')[0];
        console.log('after change handleNextDate:',this.selectedDate);
        this.updateFormattedDate(this.selectedDate);
        this.checkPrevDisabled(this.selectedDate);
        this.fetchSlots();
    }

    updateFormattedDate(dateStr) {
        if (dateStr) {
            const options = { weekday: 'long', day: '2-digit', month: 'short', year: 'numeric' };
            this.formattedDate = new Date(dateStr).toLocaleDateString('en-GB', options);
        }
    }

    checkPrevDisabled(dateStr) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const current = new Date(dateStr);
        this.isPrevDisabled = current <= today;
    }

  initializeComponent() {
    this.showMainSpin = true;
    this.autoResourceAllocationVal = this.autoResourceAllocation;
    this.isInit=true;
    this.fetchSlots();
    this.serviceloc = `${this.serviceName}/${this.locName}`;
  }


  async fetchSlots() {
    try {
      const slots = await fetchTimeSlots({ EId: this.expertId, selDate:this.selectedDate, LId: this.locId, sId: this.serviceId, Action: '', TimeZoneName:'Asia/Kolkata' ,MemberId:''});
      console.log('Result of fetchTimeSlots', JSON.stringify(slots));
      this.availableSlots = slots.AllTimeSlotList || [];
      //let allTimeSlots = this.availableSlots;   commented by adnan let->const
            const allTimeSlots = this.availableSlots;

//let slotDateTime = allTimeSlots[0].Slot;//from here

//let selectedDate = slotDateTime.split('T')[0];
let selectedDate;
console.log('selectedDate',selectedDate);


if (allTimeSlots.length > 0 && allTimeSlots[0].Slot) {
    const slotDateTime = allTimeSlots[0].Slot;
    this.selectedDate = slotDateTime.split('T')[0];
} else {
    // fallback → today’s date in YYYY-MM-DD
    const today = new Date();
    this.selectedDate = today.toISOString().split('T')[0];
}
//till here
console.log('Selected Date:', this.selectedDate);
      if(this.isInit==true){
      const userList = await getUsersByTimeZone({ LocationId: this.locId,ServiceId: this.serviceId, TimeZoneName:'Asia/Kolkata' ,MemberId:'', sDate:this.selectedDate });
       this.availableUsers = userList;//slots.AvailableUsers || [];
       this.availableUsersOrg = userList;
        console.log('Result of getUsersByTimeZone', JSON.stringify(userList));
        this.isInit=false;
      }
      this.categorizeSlots();
    } catch (error) {
      console.error('fetchSlots error:', error);
       if (error && error.body && error.body.message) {
        console.error('Apex error message:', error.body.message);
    }
    if (error && error.body && error.body.pageErrors) {
        console.error('Page errors:', JSON.stringify(error.body.pageErrors));
    }
    console.error('Full error JSON:', JSON.stringify(error));
    } finally {
      this.showMainSpin = false;
    }
  }
  /*get usersToDisplay() {
    if (this.autoResourceAllocation && this.expertId) {
        // find the matching user by Id
        const match = this.availableUsers.find(
            item => item.users && item.users.Id === this.expertId
        );
        return match ? [match] : [];
    }
    return this.availableUsers;
}*/
get usersToDisplay() {
    if (this.autoResourceAllocation && this.expertId) {
        const match = this.availableUsers.find(
            item => item.users && item.users.Id === this.expertId
        );
        return match
            ? [{ ...match, cssClass: 'resource-card active' }]
            : [];
    }

    return this.availableUsers.map(item => ({
        ...item,
        cssClass:
            item.users && item.users.Id === this.expertId
                ? 'resource-card active slds-m-top_small'
                : 'resource-card slds-m-top_small'
    }));
}

handleToggleChange(event) {
        this.autoResourceAllocation = event.target.checked;
    }

  categorizeSlots() {
    this.morningSlots = this.availableSlots.filter(slot => this.isMorning(slot.Slot));
    this.afternoonSlots = this.availableSlots.filter(slot => this.isAfternoon(slot.Slot));
    this.eveningSlots = this.availableSlots.filter(slot => this.isEvening(slot.Slot));
  }
  getHourInTimeZone(slotTime, timeZone = 'Asia/Kolkata') {
  const dateTimeFormat = new Intl.DateTimeFormat('en-US', {
    hour: 'numeric',
    hour12: false,
    timeZone: timeZone
  });

  const hour = parseInt(dateTimeFormat.format(new Date(slotTime)), 10);
  console.log(`Time in ${timeZone} for slot ${slotTime}: Hour = ${hour}`);
  return hour;
}

  isMorning(slotTime) {
    const hour = new Date(slotTime).getHours();
    return hour >= 0 && hour < 12;
  }

  isAfternoon(slotTime) {
    const hour = new Date(slotTime).getHours();
    return hour >= 12 && hour < 17;
  }

  isEvening(slotTime) {
    const hour = new Date(slotTime).getHours();
    return hour >= 17;
  }
  handleInputChange(event) {
    const field = event.target.name;
    const value = event.target.value;

    this.createReg = {
        ...this.createReg,
        [this.mapFieldName(field)]: value
    };
}

  validateRequiredFields() {
    const { Customer_Name__c, Customer_Lastname__c, Customer_Email__c, Customer_Contact__c } = this.createReg;

    if (!Customer_Name__c || !Customer_Lastname__c || !Customer_Email__c || !Customer_Contact__c) {
        this.showToast('error', 'Please fill out all required fields.');
        return false;
    }
    return true;
}

  async handleConfirmReg() {
    if (!this.validateRequiredFields()) {
        return;
    }
    this.showMainSpin = true;

    try {
      this.regJSON = JSON.stringify(this.createReg);
        const response = await getBookRegistration({
            RegJSON: this.regJSON,
            RegsJSON: JSON.stringify([]),
            selectedTime: this.createReg.Registration_Time__c,
            serviceId: this.serviceId,
            LocationId: this.locId,
            expertId: this.expertId,
            isReschedule: false,
            priceAmount: this.priceAmount,
            RoomId: this.roomId,
            BookingStartTime: this.bookingStartTime,
            BookingEndTime: this.bookingEndTime,
            selectedDate: this.selDate,
            selectedMeeting: this.selectedMeeting
        });

        const expMsg = response?.ExpMsg;

        if (!expMsg) {
            const registration = response.registration;
            // const regStatus = response.RegStatus; //! Commented by Aymaan Rule:no-unused-vars 'regStatus' is assigned a value but never used.

            this.createReg = {
                ...this.createReg,
                Registration_Time__c: registration.Registration_Time__c,
                End_Time__c: registration.End_Time__c,
                Appointment_DateDt__c: registration.Appointment_DateDt__c
            };

            this.sTime = registration.Registration_Time__c;
            this.eTime = registration.End_Time__c;
            this.selDate = registration.Appointment_DateDt__c;

            this.regDetails = registration;
            this.setConfirm=true;

                //this.showToast('success', regStatus === 'Booked' ? 'Appointment updated successfully' : 'Appointment booked successfully');
             if(this.reschedule){//regStatus=='Booked'){ //this.setConfirm){
               this.toastMessage = 'Registration updated successfully!';

              /*this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Registration updated successfully',
          variant: 'success'
        })
      );*/
    }else{
       /*this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Registration created successfully',
          variant: 'success'
        })
      );*/
      this.toastMessage = 'Registration created successfully!';
    }



        } else {
            this.saveErrorMsg = expMsg;
            console.error('aPEX error:', expMsg);
        }
    } catch (error) {
        console.error('getBookRegistration error:', error);
    } finally {
        this.showMainSpin = false;
    }
}

closeToast(){
     this.toastMessage = '';
}
  handleTabChange(event) {
    const tab = event.target.dataset.record;
    this.showTabs = tab;
    this.activeTab = {
      cus: tab === 'cus' ? 'slds-is-active' : '',
      inv: tab === 'inv' ? 'slds-is-active' : '',
      pay: tab === 'pay' ? 'slds-is-active' : ''
    };
  }

  /*handleSearch(event) {
    this.searchString = event.target.value;
    console.log('searchString:'+searchString);
    if (this.searchString) {
      this.searchResources();
    } else {
      this.availableUsers = this.timeSlotObj?.AvailableUsers || [];
    }
  }

  async searchResources() {
    try {
      const users = this.timeSlotObj?.AvailableUsers || [];
      this.availableUsers = users.filter(user =>
        user.Name.toLowerCase().includes(this.searchString.toLowerCase())
      );
    } catch (error) {
      console.error('searchResources error:', error);
    }
  }*/
  handleSearch(event) {
    this.searchString = event.target.value;
    console.log('searchString: ' + this.searchString);

    if (this.searchString) {
        this.searchResources();
    } else {
        // reset to original full list
        this.availableUsers = [...this.availableUsersOrg];
    }
}

async searchResources() {
    try {
        const users = this.availableUsersOrg || []; // always filter from master list
        this.availableUsers = users.filter(user =>
            user.users?.Name?.toLowerCase().includes(this.searchString.toLowerCase())
        );
    } catch (error) {
        console.error('searchResources error:', error);
    }
}

  handleDateChange(event) {
    this.selectedDate = event.target.value;
    console.log('Date changed 2');
    if (!this.autoResourceAllocationVal) {
      this.fetchTimeSlots(this.selectedExpertId);
    } else {
       this.fetchSlots(this.selectedExpertId);
      //this.fetchClubbingSlots();
    }
  }
  //commented by abuzar as it was repeated twice

  //  handleDateChange(event) {
  //       this.selectedDate = event.target.value;
  //       console.log('Date changed 1');
  //       this.updateFormattedDate(this.selectedDate);
  //       this.checkPrevDisabled(this.selectedDate);
  //       this.fetchSlots();
  //   }


  async fetchTimeSlots(expertId) {
    try {
      this.showMainSpin = true;
      //Changed by abuzar from expertId to this.expertId
      const slots =  await fetchTimeSlots({ EId: expertId, selDate:this.selectedDate, LId: this.locId, sId: this.serviceId, Action: '', TimeZoneName:'Asia/Kolkata' ,MemberId:''});//await fetchTimeSlots({ expertId });
      console.log('Result of fetchTimeSlots', JSON.stringify(slots));
      this.availableSlots = slots;
      const allTimeSlots = this.availableSlots;
//let slotDateTime = allTimeSlots[0].Slot;//from here

//let selectedDate = slotDateTime.split('T')[0];
// let selectedDate;

if (allTimeSlots.length > 0 && allTimeSlots[0].Slot) {
    const slotDateTime = allTimeSlots[0].Slot;
    this.selectedDate = slotDateTime.split('T')[0];
} else {
    // fallback → today’s date in YYYY-MM-DD
    const today = new Date();
    this.selectedDate = today.toISOString().split('T')[0];
}
//till here
console.log('Selected Date:', this.selectedDate);
      if ( this.availableSlots.length > 0)this.categorizeSlots();
    } catch (error) {
     console.error('fetchTimeSlots error (raw):', error);

    // Unwrap LWC proxy safely
    let errMsg = '';

    if (Array.isArray(error.body)) {
        // multiple errors
        errMsg = error.body.map(e => e.message).join(', ');
    } else if (error.body && typeof error.body.message === 'string') {
        // single Apex error
        errMsg = error.body.message;
    } else if (typeof error.message === 'string') {
        // JS error
        errMsg = error.message;
    } else {
        // fallback
        errMsg = JSON.stringify(error, Object.getOwnPropertyNames(error));
    }

    console.error('Extracted error message:', errMsg);

    // If you want full object with all props, use this:
    console.error('Full error dump:', Object.assign({}, error));
    } finally {
      this.showMainSpin = false;
    }
  }

  async fetchClubbingSlots() {
    // Implement clubbing slots logic if needed
    console.log('fetchClubbingSlots not implemented');
  }

  handleFetchTimeSlot(event) {
    const expertId = event.currentTarget.dataset.record;
    this.expertId= expertId;
    const expertName = event.currentTarget.dataset.name;
    if (expertId) {
      this.selectedExpertId = expertId;
      this.expertClick = expertName;
      this.fetchSlots();
      this.showBooking = true;
    }
  }

  handleReserveRegistration(event) {
    if (this.isMultiBooking) return;

    this.showMainSpin = true;
    const selTime = event.currentTarget.dataset.selTime;
    const resourceId = event.currentTarget.dataset.resourceId;
    const allDates = [selTime];
    const selResources = [resourceId];

    this.timeselectedSlot = selTime;

    if (this.createReg?.Id) {
        const proceed = window.confirm('Are you sure you want to change the date?');
        if (!proceed) {
            this.showMainSpin = false; // reset spinner if cancelled
            return;
        }
    }


    createRegistration({
      selDates: JSON.stringify(allDates),
      Resources: JSON.stringify(selResources),
      Duration: this.selectedExpertDuration.toString(),
      locId: this.locId,
      ResourceId: this.selectedExpertId || resourceId,
      RId: this.rId || this.createReg.Id
    })
      .then(result => {
        this.createReg = result.registration;
        console.log('this.createReg',JSON.stringify(this.createReg));
        if(this.rescheduleBool ==true) this.setConfirm=true;
        this.selectedExpertDuration = result.SelectedExpertDuration;
        this.showBooking = !this.autoResourceAllocation;
        this.showMainSpin = false;
        /*this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Reservation created successfully',
            variant: 'success'
          })
        );*/
      })
      .catch(error => {
        console.error('createRegistration error:', error);
        this.showMainSpin = false;
        //this.toastMessage = 'Registration updated successfully!';
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: 'Failed to create reservation',
            variant: 'error'
          })
        );
      });
  }

  handleMeetingSelect(event) {
    this.selectedMeeting = event.target.value;
  }

  handleDeselectMeeting() {
    this.selectedMeeting = '';
  }

  /*handleNext(event) {
    this.showBooking = true;
    const button = event.currentTarget.dataset.button;
    // Implement next logic
    console.log('Next button clicked:', button);
  }*/

  handlePrevious(event) {
    this.showBooking = true;
    const button = event.currentTarget.dataset.button;
    // Implement previous logic
    console.log('Previous button clicked:', button);
    window.location.reload();
  }

  handleRec() {
    window.location.assign('/' + this.createReg.Id);
  }

  handlehome() {
    this.showMainSpin = true;
    // const regId = this.rId || this.createReg.Id;
     window.location.reload();
    /*cancelBooking({ RegId: regId })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Booking cancelled successfully',
            variant: 'success'
          })
        );
        window.location.reload();
      })
      .catch(error => {
        console.error('cancelBooking error:', error);
        this.showMainSpin = false;
        window.location.reload();
      });*/
  }

  async handleCancel(){
     this.showMainSpin = true;
    await CancelBooking({ RegId: this.createReg.Id });
     window.location.reload();

}

  handleDownloadCsv() {
    const csvData = this.generateCsv();
    if (!csvData) return;

    const fileName = `${this.serviceName}_${this.locName}_${this.selectedDate}.csv`;
    const link = document.createElement('a');
    link.href = `data:text/csv;charset=utf-8,${encodeURI(csvData)}`;
    link.target = '_blank';
    link.download = fileName;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  generateCsv() {
    // Implement CSV generation logic
    const headers = ['Slot', 'ResourceId', 'Status'];
    const rows = this.availableSlots.map(slot => [slot.Slot, slot.ResourceId, slot.Status || 'Available']);
    return [headers, ...rows].map(row => row.join(',')).join('\n');
  }

  handleCardNumberChange(event) {
    this.cardNumber = event.target.value;
    this.detectCardType();
  }

  handleCvvChange(event) {
    this.cardCvv = event.target.value;
  }

  handleCardHolderChange(event) {
    this.cardHolderName = event.target.value;
  }

  handleExpMonthChange(event) {
    this.expMonth = event.target.value;
  }

  handleExpYearChange(event) {
    this.expYear = event.target.value;
  }

  detectCardType() {
    if (!this.cardNumber || this.cardNumber.length < 2) return;

    const firstDigit = parseInt(this.cardNumber.charAt(0));
    const cardTypeInput = this.template.querySelector('[data-id="cardType"]');
    if (firstDigit === 4) cardTypeInput.value = 'Visa';
    else if (firstDigit === 5) cardTypeInput.value = 'MasterCard';
    else if (firstDigit === 3) cardTypeInput.value = 'American Express';
    else if (firstDigit === 6) cardTypeInput.value = 'Discover';
    else cardTypeInput.value = 'Others';
  }
get formattedMorningSlots() {
  return this.morningSlots?.map(slot => ({
    ...slot,
    className: slot.Slot === this.timeselectedSlot ? 'slot-button slot-btn-selected' : 'slot-button slot-btn-normal',
    localTime: this.formatSlotTimeToLocal(slot.Slot)
  }));
}
get formattedAfternoonSlots() {
  return this.afternoonSlots?.map(slot => ({
    ...slot,
    className: slot.Slot === this.timeselectedSlot ? 'slot-button slot-btn-selected' : 'slot-button slot-btn-normal',
    localTime: this.formatSlotTimeToLocal(slot.Slot)
  }));
}
get formattedEveningSlots() {
  return this.eveningSlots?.map(slot => ({
    ...slot,
    className: slot.Slot === this.timeselectedSlot ? 'slot-button slot-btn-selected' : 'slot-button slot-btn-normal',//selectedTime
    localTime: this.formatSlotTimeToLocal(slot.Slot)
  }));
}
formatSlotTimeToLocal(slotTime) {
  const date = new Date(slotTime);
  const options = {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  };
  return new Intl.DateTimeFormat('en-IN', options).format(date); // uses browser's timezone
}

  handleAutoResourceAllocation(event) {
    this.autoResourceAllocationVal = event.target.checked;
    this.showAllDetails = false;
    this.showBooking = false;
    if (this.autoResourceAllocationVal) {
      this.fetchSlots();
    } else {
       this.fetchSlots();
      //this.fetchClubbingSlots();
    }
  }

  slotClass(slot) {
    return slot.checked ? 'available-time selected' : slot.Status === 'Available' ? 'available-time' : 'available-time disabled';
  }
   handleClientSearch(event) {
  console.log('in handle CLient search');
  
    this.searchClientString = event.target.value;
    console.log('this.searchClientString :',this.searchClientString);
    
    this.displayRecords();
}

    async displayRecords() {
        /*if (!this.searchClientString) {
            console.log('this.searchClientString NOT: ' + this.searchClientString);
            this.clearSearch();
            return;
        }*/
        try {
            console.log('this.searchClientString: ' + this.searchClientString);
            const result = await getSearchRecords({ searchString: this.searchClientString });
            this.srcList = result;
             console.log('this.searchClientString res: ' + result);
            if (result?.length > 0) {
                this.showSearchPanels = true;
            }
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
            setTimeout(() => {
                this.errorMessage = '';
            }, 5000);
        }
    }
    setRecord(event) {
        // const index = event.currentTarget.dataset.index;
        // const record = this.srcList[index];
        // this.createReg.Contact__c = record.Id;
        // this.searchClientString = record.Name;
        // this.showSearchPanels = false;
        // const nameArray = record.Name.split(' ');
        // if (nameArray.length === 1) {
        //     this.createReg.Customer_Lastname__c = nameArray[0];
        // } else if (nameArray.length > 1) {
        //     this.createReg.Customer_Name__c = nameArray[0];
        //     this.createReg.Customer_Lastname__c = nameArray[1];
        // }
        // if (record.Email) {
        //     this.createReg.Customer_Email__c = record.Email;
        // }
        // if (record.Phone) {
        //     this.createReg.Customer_Contact__c = record.Phone;
        // }
        // this.disableForm = false;
        const index = event.currentTarget.dataset.index;
          console.log('1. Selected Index:', index);

          const record = this.srcList[index];
          console.log('2. Source Record found:', JSON.stringify(record)); // Using JSON parse/stringify to handle LWC Proxies cleanly

          console.log('Assigning Contact ID:', record.Id);
    this.createReg.Contact__c = record.Id;

    console.log('Updating Search String to:', record.Name);
    this.searchClientString = record.Name;
    
    console.log('Closing Search Panels...');
    this.showSearchPanels = false;

          const nameArray = record.Name.split(' ');
          console.log('3. Name split array:', nameArray);

          if (nameArray.length === 1) {
              console.log('-> Logic: Single name detected');
              this.createReg.Customer_Lastname__c = nameArray[0];
          } else if (nameArray.length > 1) {
              console.log('-> Logic: First and Last name detected');
              this.createReg.Customer_Name__c = nameArray[0];
              // Note: This logic assigns the *second* part of the name to Lastname. 
              // If there are 3 parts (e.g., "John Von Doe"), nameArray[1] will be "Von".
              this.createReg.Customer_Lastname__c = nameArray[1]; 
          }

          if (record.Email) {
              this.createReg.Customer_Email__c = record.Email;
          } else {
              console.log('-> Warning: No Email found on record');
          }

          if (record.Phone) {
              this.createReg.Customer_Contact__c = record.Phone;
          }

          this.disableForm = false;

          console.log('4. Final createReg state:', JSON.parse(JSON.stringify(this.createReg)));
        console.log('CreateReg:', JSON.stringify(this.createReg));

    }

    closeSearchPanel() {
        this.showSearchPanels = false;
    }
       clearSearch() {
        this.srcList = [];
        this.searchClientString = '';
        this.createReg.Customer_Name__c = '';
        this.createReg.Customer_Lastname__c = '';
        this.createReg.Customer_Email__c = '';
        this.createReg.Customer_Contact__c = '';
        if (!this.event.Allow_Guest_Registrations__c) {
            this.disableForm = true;
        }
       console.log('CreateReg:', JSON.stringify(this.createReg));

    }
    get showSearchPanelSection() {
    return this.srcList.length > 0 && this.showSearchPanels;
}
}