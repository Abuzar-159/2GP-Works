({
    doInit : function(comp, event, helper) {
        console.log('do init create inv');
        //helper.fetchCurrencyIso(comp);
        comp.set("v.showMmainSpin",true);
        helper.getInstancesAndRecordTypes(comp, event, helper);
        helper.functionalityControl(comp, event, helper);
        //helper.getInstancesAndRecordTypes1(comp, event, helper);
        console.log('SOId:',comp.get("v.SOId"));
        console.log('StdId:',comp.get("v.StdId"));
        if(!$A.util.isEmpty(comp.get("v.SOId")))
            helper.getFieldsSetApiNameHandler(comp,'Invoice__c','createinvoice');
        else if(!$A.util.isEmpty(comp.get("v.StdId")))
            helper.getFieldsSetApiNameHandler(comp,'Invoice__c','Create_Order_Invoice');
            else{
                helper.OrderProcess(comp, event, helper);
            }
        //comp.set("v.showMmainSpin",false);
        //helper.checkMultipleCurrency(comp);

        //helper.getFieldsSetApiNameHandler(comp,'Invoice__c','createinvoice');

        var now =  new Date();
        comp.set('v.today',now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate());
        if(!$A.util.isEmpty(comp.get("v.SOId")) && comp.get("v.selectedrecordTypeMap.DeveloperName")!='On_Account_Payment'){
            comp.set("v.defaultValues",{'Order__c':comp.get("v.SOId"),'Invoice_Date__c':now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate()});

        }
        if(!$A.util.isEmpty(comp.get("v.StdId")) && comp.get("v.selectedrecordTypeMap.DeveloperName")!='On_Account_Payment'){
            comp.set("v.defaultValues",{'Order_S__c':comp.get("v.StdId"),'Invoice_Date__c':now.getFullYear()+'-'+(now.getMonth()+1)+'-'+now.getDate()});

        }

    },



    selectRecordType: function (component, event, helper) {
            var index = event.currentTarget.dataset.index;
            var allOptions = component.get("v.InvoiceRTList");

            // Reset all cards to default
            allOptions.forEach((item, i) => {
                var cardEl = document.getElementById('card_' + i);
                if (cardEl) {
                    cardEl.classList.remove('selected-box');
                }
            });

            // Highlight clicked one
            var selectedCardEl = document.getElementById('card_' + index);
            if (selectedCardEl) {
                selectedCardEl.classList.add('selected-box');
            }

            // Update Aura attributes
            component.set("v.selectedCard", index);
            var selectedOption = allOptions[index];

            if (selectedOption) {
                component.set("v.tempSelectedOption", selectedOption.value);

                

                // ✅ Show next section
                $A.getCallback(function () {
                    component.set("v.NDisplay", true);
                    component.set("v.INVLIList", []);
                    console.log("Next section displayed automatically.");
                })();
            }
        },
    cancel : function(comp, event, helper) {
console.log('1');
        if(comp.get("v.FromAR")){
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:AccountsReceivable",
                componentAttributes: {
                    "showTabs" : 'inv'
                }
            });
            evt.fire();
        }else if(comp.get("v.StdId") != ''){
            console.log('StdId:',comp.get("v.StdId"));
            try{

                /*var workspaceAPI = comp.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });*/
                /*window.setTimeout(
                    $A.getCallback(function() {
                        window.close();
                    }), 1000
                );*/
            }catch(e){console.log('Error:',e);}

            //let url='www.google.com';
            //location.replace("www.google.com");

            /**/
            //window.location.replace(url);
            //window.history.pushState('', '', 'www.google.com');
            //history.back();
            /*var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": comp.get("v.StdId"),
            });
            navEvt.fire(); */

        } else{
            history.back();
        }

    },

    displayNext : function(c, e, h) {
        c.set("v.NDisplay",true);
        c.set("v.INVLIList", []);
    },

    next : function(c, e, h) {
        let valArr = c.find("invoiceRecordType").get("v.value").split('@');

        if(valArr.length>1){
            c.set("v.selectedrecordTypeMap",{'RecordTypeId':valArr[0],'DeveloperName':valArr[1]});
        }
        if(c.get("v.selectedrecordTypeMap.DeveloperName")==='On_Account_Payment'){
            var invilist = [];
            invilist.push({'Total_Price__c':0.00,'Sub_Total__c':0.00,'Description__c':'','VAT_Amount__c':0.00});
            console.log('invilist : ',invilist);
            c.set("v.INVLIList",invilist);
        }
        console.log('INVLIList : ',c.get("v.INVLIList"));
    },

    handleInvoiceSuccess: function(cmp, event, helper) {
      console.log('In here success');
        var payload = event.getParams().response;
        console.log('payload', payload);
        cmp.set("v.invrecordId",payload.id);
        console.log('Id-->', payload.id);
        //if(payload.id)
            helper.CreateInvoiceAndLineItem(cmp,event,helper);
    },
    onchangeInvoiceField: function(cmp, event, helper) {

        var sourceField = event.getSource();
        console.log('sourceField', sourceField);

        switch(sourceField.get("v.fieldName")) {
            case 'Order__c':
                if(cmp.get("v.selectedrecordTypeMap.DeveloperName")!='On_Account_Payment'){

                    cmp.set("v.SO_Id",sourceField.get("v.value"));
                    console.log('SO_Id:', cmp.get("v.SO_Id"));
                    cmp.set("v.SOId",sourceField.get("v.value"));
                    console.log('SOId:', cmp.get("v.SOId"));
                    console.log('getInvoiceLineItem 1:');
                    helper.getInvoiceLineItem(cmp);
                    helper.fetchOrderInfo(cmp);
                    helper.fetchScheduleInvoices(cmp);
                }
                break;
            case 'Order_S__c':
                if(cmp.get("v.selectedrecordTypeMap.DeveloperName")!='On_Account_Payment'){
                    cmp.set("v.SO_Id",sourceField.get("v.value"));
                    // cmp.set("v.SOId",sourceField.get("v.value"));
                    cmp.set("v.Std_Id",sourceField.get("v.value"));
                   // cmp.set("v.StdId",sourceField.get("v.value"));
                    console.log('getInvoiceLineItem 2:');
                    helper.getInvoiceLineItem(cmp);
                    helper.fetchStnOrderInfo(cmp);
                    helper.fetchScheduleInvoices(cmp);
                }
                break;
            case 'Account__c':
                if(cmp.get("v.selectedrecordTypeMap.DeveloperName")==='On_Account_Payment'){
                    helper.getAccountInformation(cmp,sourceField.get("v.value"));
                    var invliList =  cmp.find("invli");
                    for(let x in invliList)
                        invliList[x].set("v.disabled",false);
                }
                // fetch Tax percentage from customer profile
                break;
            default:
                // code block
        }
    },
    setDefaultValues : function(component, event, helper) {
        console.log('inside setDefaultValues:');
        console.log('Invoice Record Id', component.get("v.invrecordId"));
        if($A.util.isUndefinedOrNull(component.get("v.invrecordId"))){
          console.log('Invoice Record Id Later: ', component.get("v.invrecordId"));
            console.log('SOId: ', component.get("v.SOId"));
            console.log('StdId: ', component.get("v.StdId"));
          //helper.setDefaulthandler(component);

            if(!$A.util.isEmpty(component.get("v.SOId"))){
                component.set("v.SO_Id",component.get("v.SOId"));
                console.log('SOId later:', component.get("v.SOId"));
                helper.fetchTotalDownPayment(component);
                console.log('getInvoiceLineItem 3:');
                helper.getInvoiceLineItem(component);
                helper.fetchStnOrderInfo(component);
                helper.fetchScheduleInvoices(component);
            }
            if(!$A.util.isEmpty(component.get("v.StdId"))){
                component.set("v.Std_Id",component.get("v.StdId"));
                console.log('StdId later:', component.get("v.StdId"));
                helper.fetchTotalDownPayment(component);
                console.log('getInvoiceLineItem 4:');
                helper.getInvoiceLineItem(component);
                helper.fetchStnOrderInfo(component);
                helper.fetchScheduleInvoices(component);
            }
        }
    },
    handleSubmit: function(component, event, helper) {

        event.preventDefault();       // stop the form from submitting
         var renderedFields = component.find("inv_input_field");
        for (var x in renderedFields) {
            if (renderedFields[x].get('v.fieldName') === 'Order_S__c') {
                var recId= renderedFields[x].get("v.value");
                console.log('Id 1:',recId);
                renderedFields[x].set("v.value", component.get("v.StdId"));
                console.log('Id 1 aftr:',renderedFields[x].get("v.value"));
            }
        }
        var fields = event.getParam('fields');
        fields.RecordTypeId = component.get("v.selectedrecordTypeMap").RecordTypeId ;
        component.find('invoiceEditForm').submit(fields);
    },
    calculateDownPaymentPercentage: function(component, event, helper) {

        var renderedFields = component.find("inv_input_field");

        for(var  x in renderedFields){
            if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                shippingPrice = renderedFields[x].get("v.value");
                break;
            }
        }
    },
    // calculateDownPaymentAmt: function(component, event, helper) {

        // var val = event.getSource().get("v.value");
        // if(val>=1 && val<=100){
        //     var renderedFields = component.find("inv_input_field");
        //     var downPaymentAmt = component.find("downPaymentAmt");
        //     var advanceAmountPaid = parseFloat(component.get("v.advancePaymentPaidAmount") || 0);

        //     console.log('downPaymentAmt',downPaymentAmt);
        //     console.log('renderedFields',renderedFields);

        //     for(var  x in renderedFields){
        //         if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c')
        //             if(downPaymentAmt != undefined) downPaymentAmt.set("v.value",(renderedFields[x].get("v.value") * val)/100);
        //         if(renderedFields[x].get('v.fieldName')==='Total_Down_Payment_Amount__c'){
        //             component.set("v.downPaymentAmount", downPaymentAmt.get("v.value"));
        //             console.log('downPaymentAmount',component.get("v.downPaymentAmount").value);
        //             renderedFields[x].set('v.value',downPaymentAmt.get("v.value"));
        //         }

        //         if(renderedFields[x].get('v.fieldName')==='Down_Payment__c'){
        //             component.set("v.downPaymentPercentage",val);
        //             console.log('v.downPaymentPercentage',component.get("v.downPaymentPercentage").value);
        //             renderedFields[x].set('v.value',val);
        //         }

        //     }
        // }
// },
// fixed
// calculateDownPaymentAmt: function (component, event, helper) {
//     var val = parseFloat(event.getSource().get("v.value") || 0); // Get the entered percentage value
//     console.log("Entered Percentage:", val); // Log the entered percentage

//     if (val >= 1 && val <= 100) {
//         var renderedFields = component.find("inv_input_field");
//         var downPaymentAmtField = component.find("downPaymentAmt");
//         var advanceAmountPaid = parseFloat(component.get("v.AmountPaid") || 0); // Fetch the already paid advance amount
//         console.log("Advance Amount Paid:", advanceAmountPaid); // Log the advance payment amount

//         for (var x in renderedFields) {
//             if (renderedFields[x].get("v.fieldName") === "Invoice_Amount__c") {
//                 var invoiceAmount = parseFloat(renderedFields[x].get("v.value") || 0); // Get invoice amount
//                 console.log("Invoice Amount:", invoiceAmount); // Log the invoice amount

//                 // Calculate remaining amount after subtracting advance payment
//                 var remainingAmount = invoiceAmount - advanceAmountPaid;
//                 if (remainingAmount < 0) remainingAmount = 0; // Prevent negative values
//                 console.log("Remaining Amount (after deduction):", remainingAmount);

//                 // Calculate the Down Payment Amount based on percentage
//                 var downPaymentAmount = (remainingAmount * val) / 100;
//                 console.log("Calculated Down Payment Amount:", downPaymentAmount);

//                 // Set Down Payment Amount in the component and UI
//                 component.set("v.downPaymentAmount", downPaymentAmount.toFixed(2)); // Set component attribute
//                 if (downPaymentAmtField) {
//                     downPaymentAmtField.set("v.value", downPaymentAmount.toFixed(2)); // Update UI field
//                     console.log("Updated Down Payment Amount in the UI:", downPaymentAmount);
//                 }

//                 // Update Total Down Payment Amount in rendered fields
//                 // if (renderedFields[x].get("v.fieldName") === "Total_Down_Payment_Amount__c") {
//                 //     renderedFields[x].set("v.value", downPaymentAmount.toFixed(2));
//                 //     console.log("Updated Total Down Payment Amount:", downPaymentAmount);
//                 // }
//                 if (renderedFields[x].get("v.fieldName") === "Total_Down_Payment_Amount__c") {
//                     var calculatedAmount = downPaymentAmount.toFixed(2); // Use a reliable source
//                     renderedFields[x].set("v.value", calculatedAmount);
//                     component.set("v.downPaymentAmount", calculatedAmount); // Update component attribute
//                     console.log("Updated Total Down Payment Amount:", calculatedAmount);
//                 }

//                 // Set Down Payment Percentage in the component and UI
//                 component.set("v.downPaymentPercentage", val); // Set component attribute
//                 if (renderedFields[x].get("v.fieldName") === "Down_Payment__c") {
//                     renderedFields[x].set("v.value", val); // Update UI field
//                     console.log("Updated Down Payment Percentage in the UI:", val);
//                 }
//             }
//         }
//     } else {
//         console.log("Invalid percentage value entered:", val); // Log invalid percentage
//     }
// },
// calculateDownPaymentAmt: function (component, event, helper) {
//     var val = parseFloat(event.getSource().get("v.value") || 0); // Get entered percentage value
//     console.log("Entered Percentage:", val);

//     if (val >= 1 && val <= 100) {
//         var renderedFields = component.find("inv_input_field");
//         var downPaymentAmtField = component.find("downPaymentAmt");
//         var advanceAmountPaid = parseFloat(component.get("v.AmountPaid") || 0); // Fetch the already paid advance amount
//         console.log("Advance Amount Paid:", advanceAmountPaid);

//         for (var x in renderedFields) {
//             if (renderedFields[x].get("v.fieldName") === "Invoice_Amount__c") {
//                 var invoiceAmount = parseFloat(renderedFields[x].get("v.value") || 0); // Get invoice amount
//                 console.log("Invoice Amount:", invoiceAmount);

//                 // Calculate remaining amount after subtracting advance payment
//                 var remainingAmount = invoiceAmount - advanceAmountPaid;
//                 if (remainingAmount < 0) remainingAmount = 0; // Prevent negative values
//                 console.log("Remaining Amount (after deduction):", remainingAmount);

//                 // Calculate the Down Payment Amount based on percentage
//                 var downPaymentAmount = (remainingAmount * val) / 100;
//                 console.log("Calculated Down Payment Amount:", downPaymentAmount);

//                 // Update Down Payment Amount in the component and UI
//                 component.set("v.downPaymentAmount", downPaymentAmount.toFixed(2)); // Update component attribute
//                 if (downPaymentAmtField) {
//                     downPaymentAmtField.set("v.value", downPaymentAmount.toFixed(2)); // Update UI field
//                 }
//             }

//             // Update Total Down Payment Amount
//             if (renderedFields[x].get("v.fieldName") === "Total_Down_Payment_Amount__c") {
//                 renderedFields[x].set("v.value", downPaymentAmount.toFixed(2)); // UI update
//                 component.set("v.downPaymentAmount", downPaymentAmount.toFixed(2)); // Component update
//                 console.log("Updated Total Down Payment Amount:", downPaymentAmount);
//             }

//             // Update Down Payment Percentage
//             if (renderedFields[x].get("v.fieldName") === "Down_Payment__c") {
//                 renderedFields[x].set("v.value", val); // UI update
//                 component.set("v.downPaymentPercentage", val); // Component update
//                 console.log("Updated Down Payment Percentage:", val);
//             }
//         }
//     } else {
//         console.log("Invalid percentage value entered:", val); // Log invalid percentage
//     }
// },



calculateDownPaymentAmt: function(component, event, helper) {
    var val;

    // Check if the function is called via event or manually
    if (event && event.getSource) {
        val = event.getSource().get("v.value");
    } else {
        var downPaymentField = component.find("downPayment");
        val = downPaymentField ? downPaymentField.get("v.value") : 0;
    }

    if (val >= 1 && val <= 100) {
        var renderedFields = component.find("inv_input_field");
        var downPaymentAmt = component.find("downPaymentAmt");

        for (var x in renderedFields) {
            if (renderedFields[x].get('v.fieldName') === 'Invoice_Amount__c') {
                var invoiceAmt = renderedFields[x].get("v.value");
                var calculatedDP = (invoiceAmt * val) / 100;
                if (downPaymentAmt !== undefined) {
                    downPaymentAmt.set("v.value", calculatedDP);
                }
            }

            if (renderedFields[x].get('v.fieldName') === 'Total_Down_Payment_Amount__c') {
                component.set("v.downPaymentAmount", downPaymentAmt.get("v.value"));
                renderedFields[x].set("v.value", downPaymentAmt.get("v.value"));
            }

            if (renderedFields[x].get('v.fieldName') === 'Down_Payment__c') {
                component.set("v.downPaymentPercentage", val);
                renderedFields[x].set("v.value", val);
            }
        }
    }
},



    updateTotalPrice : function(component, event, helper) {
        component.set("v.changeTD", true);
        if(component.get("v.TDPayment")=='' || component.get("v.TDPayment")==null || component.get("v.TDPayment")==undefined){
            component.set("v.TDPayment", 0);
        }
        var renderedFields = component.find("inv_input_field");
        //var downPaymentAmt = component.find("downPaymentAmt");
        for(var  x in renderedFields){
            if(renderedFields[x].get('v.fieldName')==='Total_Down_Payment_Amount__c')
                renderedFields[x].set('v.value',component.get("v.TDPayment"));
        }
        helper.updateTotalPrice_Handler(component);
    },
    addInvoiceLineItem:function(comp,event,helper){

        var ILIList=[];
        ILIList=comp.get("v.ILIList");
        var action = comp.get("c.getInvoiceAndLineItemInstance");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (comp.isValid() && state === "SUCCESS") {
                if(ILIList==null) ILIList=response.getReturnValue();
                else ILIList.push(response.getReturnValue());
                comp.set("v.ILIList",ILIList);
            }else{
                console.log('Error:',response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    getDelete:function(comp,event,helper){

        var Index=event.getSource().get("v.value");//event.currentTarget.dataset.service;
        var INVLIList=comp.get("v.INVLIList");

        INVLIList.splice(Index,1);
        comp.set("v.INVLIList",INVLIList);
        helper.updateTotalPrice_Handler(comp);
    },

    CreateInvoiceAndLineItem:function(comp,event,helper){
        try{
            if(comp.get("v.selectedrecordTypeMap.DeveloperName")==='Schedule_Invoice'){
                var remainingAmount = (comp.get("v.advancePaymentPaidAmount") - comp.get("v.TotalPaidAmountApplied"));
                console.log('remainingAmount 556677: ',remainingAmount);
                console.log('PaidAmountApplied : ',comp.get("v.PaidAmountApplied"));
                console.log('Company---> : ',comp.get("v.OrgId"));
                if (comp.get("v.PaidAmountApplied") < 0) {//added by Raqeeb
                comp.set("v.showToast", true);
                comp.set("v.message", "Paid amount applied cannot be a negative value.");
                window.setTimeout(
                    $A.getCallback(function() {
                        comp.set("v.showToast", false);
                    }), 5000
                );
                return; 
            }else if (parseFloat(comp.get("v.subTotal")) < 0 || isNaN(parseFloat(comp.get("v.subTotal")))) {
                        comp.set("v.showToast", true);
                        comp.set("v.message", "Invoice % and/or Sub Total cannot be a negative value.");
                        comp.set("v.showMmainSpin", false);
                        window.setTimeout(
                    $A.getCallback(function() {
                        comp.set("v.showToast", false);
                    }), 5000
                );
                return; 
            }
                
                if(comp.get("v.PaidAmountApplied") > remainingAmount.toFixed(2)){//Moin Added this .toFixed(2)
                    console.log('in');
                    comp.set("v.showToast",true);
                    comp.set("v.message","Paid amount applied is greater than advance payment");
                    window.setTimeout(
                        $A.getCallback(function() {
                            comp.set("v.showToast",false);
                        }), 5000
                    );
                    return;
                }else{
                    console.log('inhere else');
                }

            }
            comp.set("v.showMmainSpin",true);

            if(comp.get("v.selectedrecordTypeMap.DeveloperName")==='On_Account_Payment'){
                console.log('in here On_Account_Payment');
                var invli = comp.find("invli");
                var valid = true;
                for(var x in invli){
                    if(invli[x].get("v.required") && (!invli[x].checkValidity() || invli[x].get("v.value")== 0.00)){
                        invli[x].setCustomValidity('Value must be > 0.00');
                        valid = false;
                    }else
                        invli[x].setCustomValidity('');
                    invli[x].showHelpMessageIfInvalid();
                }
                if(valid){
                    comp.find("RecordTypeId").set("v.value",comp.get("v.selectedrecordTypeMap").RecordTypeId);
                    comp.find("invoiceEditForm").submit();
                } else{
                    comp.set("v.showToast",true);
                    comp.set("v.message","Review All Error Messages");

                    setTimeout(
                        $A.getCallback(function() {
                            comp.set("v.showToast",false);
                        }), 3000
                    );
                    //helper.showToast('error','error','Review All Error Messages');
                }
            }
            else{
                var actualInvLIIndex=comp.get('v.actualInvLIIndex');
                console.log('in here actualInvLIIndex');
                console.log('v.subTotal~>'+comp.get('v.subTotal'));
                console.log('v.invTax~>'+comp.get('v.invTax'));
                console.log('v.schInvAmount~>'+comp.get('v.schInvAmount'));
                console.log('v.schInvCreditAmount~>'+comp.get('v.schInvCreditAmount'));

                var tatalamount = parseFloat(comp.get("v.subTotal"))+parseFloat(comp.get("v.invTax"))+parseFloat(comp.get("v.schInvAmount")) - parseFloat(comp.get("v.schInvCreditAmount"));//+ parseFloat(comp.get("v.AmountPaid"))
                tatalamount = tatalamount.toFixed(2);
                //alert(tatalamount);
                console.log('tatalamount : ',tatalamount);
                console.log('v.salesorder.Order_Amount__c~>'+comp.get('v.salesorder.Order_Amount__c'));
                console.log('v.orderAmount~>'+comp.get('v.orderAmount'));
                try{
                    if(comp.get("v.AmountPaid") == undefined || comp.get("v.AmountPaid") == null){
                        comp.set("v.AmountPaid",0);
                    }
                    if(comp.get("v.AmountPaid") == '') comp.set("v.AmountPaid",0);
                    console.log('v.AmountPaid~>'+comp.get('v.AmountPaid'));

                    if(actualInvLIIndex.length==0){
                        comp.set("v.showToast",true);
                        comp.set("v.message","Please select the invoice Line Item.");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000000
                        );
                        comp.set("v.showMmainSpin",false);
                        //helper.showToast('error','error','Please select the invoice Line Item');
                    }else if(comp.get("v.selectedrecordTypeMap.DeveloperName")==='Schedule_Invoice' && tatalamount > parseFloat(comp.get('v.orderAmount'))){
                        comp.set("v.showToast",true);
                        comp.set("v.message","Sum of scheduled amount is greater then order amount");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000
                        );
                        comp.set("v.showMmainSpin",false);
                    }else if(comp.get("v.selectedrecordTypeMap.DeveloperName")==='Advance' && (comp.get("v.downPaymentAmount")<=0 || $A.util.isEmpty(comp.get("v.downPaymentAmount")))){
                        comp.set("v.showToast",true);
                        comp.set("v.message","Please Enter the Down Payment Percentage or Amount");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000
                        );
                        comp.set("v.showMmainSpin",false);
                    }else if(comp.get("v.selectedrecordTypeMap.DeveloperName")==='Advance' && (comp.get("v.downPaymentPercentage")>=100 || $A.util.isEmpty(comp.get("v.downPaymentPercentage")))){
                        comp.set("v.showToast",true);
                        comp.set("v.message","Down Payment Amount must be less than 100%");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000
                        );
                        comp.set("v.showMmainSpin",false);
                    }else if(comp.get("v.AmountPaid") != undefined && comp.get("v.AmountPaid") != null && comp.get("v.AmountPaid") > 0 && comp.get("v.PaidAmountApplied")!=null && comp.get("v.PaidAmountApplied")!=undefined && comp.get("v.PaidAmountApplied") > 0 && comp.get("v.PaidAmountApplied")>comp.get("v.AmountPaid")){
                        console.log('in here Paid Amount Applied is greater then the Advance Payment');
                        comp.set("v.showToast",true);
                        comp.set("v.message","Paid Amount Applied is greater then the Advance Payment");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000
                        );
                        comp.set("v.showMmainSpin",false);
                    }
                    else if(comp.get("v.PaidAmountApplied")<0){
            
                        comp.set("v.showToast",true);
                        comp.set("v.message","Paid Amount Applied cannot be a negative value");

                        setTimeout(
                            $A.getCallback(function() {
                                comp.set("v.showToast",false);
                            }), 3000
                        );
                        comp.set("v.showMmainSpin",false);
                    }else{
                        console.log('in here here');
                        var invli = comp.find("invli");
                        var valid = true;
                        if($A.util.isUndefined((invli.length))){
                            invli.checkValidation();
                            if(!invli.get("v.validate")) valid = false;
                        }else{
                            for(var x in invli){
                                invli[x].checkValidation();
                                if(!invli[x].get("v.validate"))
                                    valid = false;
                            }
                        }

                        if(valid){
                            comp.find("RecordTypeId").set("v.value",comp.get("v.selectedrecordTypeMap").RecordTypeId);
                          /*  helper.showToast('success','success','Invoice Created Successfully');
                            setTimeout(
                                $A.getCallback(function() {
                                   // comp.find("invoiceEditForm").submit();
                                }), 2000
                            );*/
                             var renderedFields = comp.find("inv_input_field");
                            //alert(comp.get("v.Invoice.Invoice_Date__c"));
                            for(var  x in renderedFields){
                                comp.set("v.NewInvoice.RecordTypeId", comp.get("v.selectedrecordTypeMap").RecordTypeId);
                                if(renderedFields[x].get('v.fieldName')==='Invoice_Date__c'){
                                    comp.set("v.NewInvoice.Invoice_Date__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                                    comp.set("v.NewInvoice.Invoice_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Down_Payment__c'){
                                    comp.set("v.NewInvoice.Down_Payment__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Total_Down_Payment_Amount__c'){
                                    comp.set("v.NewInvoice.Total_Down_Payment_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Percentage__c'){
                                    comp.set("v.NewInvoice.Sales_Invoice_Percentage__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                                    comp.set("v.NewInvoice.Invoice_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Amount_Paid__c'){
                                    comp.set("v.NewInvoice.Amount_Paid__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c'){
                                    comp.set("v.NewInvoice.Sales_Invoice_Tax_Percentage__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Sub_Total_Amount__c'){
                                    comp.set("v.NewInvoice.Sub_Total_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Invoice_Shipping_Amount__c'){
                                    comp.set("v.NewInvoice.Invoice_Shipping_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                                    comp.set("v.NewInvoice.Tax_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Discount_Amount__c'){
                                    comp.set("v.NewInvoice.Discount_Amount__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Order_S__c'){
                                    comp.set("v.NewInvoice.Order_S__c",renderedFields[x].get("v.value"));
                                }
                                if(renderedFields[x].get('v.fieldName')==='Paid_Amount_Applied__c'){
                                    if(comp.get("v.selectedrecordTypeMap.DeveloperName")!='Schedule_Invoice') comp.set("v.NewInvoice.Paid_Amount_Applied__c",renderedFields[x].get("v.value"));
                                }
                            }
                            if(!$A.util.isEmpty(comp.get("v.SOId")))
                                comp.set("v.NewInvoice.Order_S__c",comp.get("v.SOId"));
                             comp.set("v.NewInvoice.Company__c",comp.get("v.OrgId"));
                            helper.CreateInvoiceAndLineItem(comp,event,helper);
                        }
                        else{

                            comp.set("v.showToast",true);
                            comp.set("v.message","Review All Error Messages");

                            setTimeout(
                                $A.getCallback(function() {
                                    comp.set("v.showToast",false);
                                }), 3000
                            );
                            //helper.showToast('error','error','Review All Error Messages');
                            comp.set("v.showMmainSpin",false);
                        }
                    }
                }catch(e){
                    console.log('arshad err1',e);
                }
            }

        }catch(e){
            console.log('arshad err2',e);
        }
    },

    calculateAmount:function(comp,event,helper){

        var invli = comp.get("v.INVLIList");
        var fields = comp.find("invli");
        var tax = 0.00;
        var taxAmount =0.00;
        var totalAmount = 0.00;
        for(let x in fields)
            if(fields[x].get("v.name")==='tax'){
                tax=fields[x].get("v.value");
                break;
            }

        for(var x in invli){
            taxAmount = parseFloat(tax)*invli[x].Sub_Total__c;
            invli[x].VAT_Amount__c = taxAmount;
            totalAmount =  parseFloat(invli[x].VAT_Amount__c) + parseFloat(invli[x].Sub_Total__c);
            invli[x].Total_Price__c = totalAmount;

        }
        console.log('invli : ',invli);
        comp.set("v.INVLIList",invli);
        var renderedFields = comp.find("inv_input_field");

        for(var  x in renderedFields){
            if( renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                renderedFields[x].set("v.value",taxAmount);
                component.set("v.invTax", taxAmount);
            }
            if( renderedFields[x].get('v.fieldName')==='Invoice_Amount__c')
                renderedFields[x].set("v.value",totalAmount);
            // if( renderedFields[x].get('v.fieldName')==='Invoice_Shipping_Amount__c')
            //   renderedFields[x].set("v.value",100);
        }

    },

    /*fetchInvoiceLineItems:function(comp,event,helper){

        var ILIList=[];//comp.get("v.ILIList");
        console.log('getInvoiceLineItem 5:');
        var action = comp.get("c.getInvoiceLineItem");
        action.setParams({
            "SOId":comp.get("v.Invoice.Order__c") //InvoiceOrder.Id Invoice.Order__c.Id
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (comp.isValid() && state === "SUCCESS") {

                for(var i in response.getReturnValue())
                    ILIList.push(response.getReturnValue()[i]);

                //comp.set("v.ILIList",ILIList);

            }else{
                console.log('Error:',response.getError());
            }
        });
        $A.enqueueAction(action);

    },*/

    cancelCreateInvoiceAndLineItem:function(comp,event,helper){
        console.log('2');
        comp.set("v.allChecked",false);
        comp.set("v.INVLIList", []);
        comp.set("v.SOId", null);
        comp.set("v.StdId", null);
        comp.set("v.subTotal", 0.00);
        comp.set("v.invTax", 0.00);
        comp.set("v.PaidAmountApplied", 0.00);
        let selectedMap = comp.get("v.selectedrecordTypeMap");
        selectedMap.DeveloperName = '';
        comp.set("v.selectedrecordTypeMap", selectedMap);

       /* if(comp.get("v.FromAR")){
            $A.createComponent(
                "c:AccountsReceivable", {
                    "showTabs":comp.get("v.showTabs"),
                    "fetchRecordsBool":false,
                    "OrgId":comp.get("v.OrgId"),
                    "Order":'DESC',
                    "OrderBy":'CreatedDate'
                },
                function(newComp) {
                    var content = comp.find("body");
                    content.set("v.body", newComp);
                }
            );
        }else {
            console.log('here');
            history.back();

        }*/

    },

    CancelCalled : function(comp, event, helper){
    console.log('3');
      // This Shit Code was Commented By Aymaan
        // if (comp.get("v.showTabs")=='cus'){
        //     var evt = $A.get("e.force:navigateToComponent");
        //     evt.setParams({
        //         componentDef : "c:AccountsReceivable",
        //         componentAttributes: {
        //             "showTabs" : 'cus'
        //         }
        //     });
        //     evt.fire();

        // }else if(comp.get("v.FromAR")){
        //     var evt = $A.get("e.force:navigateToComponent");
        //     evt.setParams({
        //         componentDef : "c:AccountsReceivable",
        //         componentAttributes: {
        //             "showTabs" : 'inv'
        //         }
        //     });
        //     evt.fire();
        // }
        // else{
        //     history.back();
        // }

        // console.log('comp.get("v.FromAR") : ',comp.get("v.FromAR"));
        // console.log('comp.get("v.FromEPOS") : ',comp.get("v.FromEPOS"));
        if(comp.get("v.FromAR")){
          console.log('Navigating to Accounts Receivable');
          var evt = $A.get("e.force:navigateToComponent");
          evt.setParams({
              componentDef : "c:AccountsReceivable",
              componentAttributes: {
                  "showTabs" : comp.get("v.showTabs")
              }
          });
          evt.fire();
        }
    // added this by matheen on 9/5/25
        else if (comp.get("v.FromEPOS") == true) {
            console.log('Navigating to epos LWC');
            window.location.href = "/lightning/n/Epos";
        }
        //added by Raqeeb
        else if(comp.get("v.fromProject",true)){
            var selRT = comp.get("v.selectedrecordTypeMap") || {};
            var devName = selRT.DeveloperName ? selRT.DeveloperName : '';
             if (devName !== '' || comp.get("v.NDisplay") === true) {
            console.log('go back to RT selection');

            comp.set("v.NDisplay", false);
            comp.set("v.selectedrecordTypeMap", {});            
            return;
        }

            var rtList = comp.get("v.InvoiceRTList") || [];
        if (rtList.length > 1 && ($A.util.isEmpty(devName))) {
            console.log('On RT selection -> navigate back to Milestones (step 2)');
            console.log('cancelled',comp.get("v.fromProject"));
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:Milestones",
                componentAttributes: {
                    "newProj" : false,
                    "projectId":comp.get("v.ProjId")
                }
                
            });
            evt.fire();
            return;
        }
    }
        else{
          console.log('Navigating back to previous page');
          console.log('FromAR:', comp.get("v.FromAR"));
          console.log('FromEPOS:', comp.get("v.FromEPOS"));
            history.back();
        }

    },

    getallinvoiceLI : function(cmp, event, helper){
        try{
            let checked = false;
            if(event != undefined){
                checked = event.getSource().get("v.checked");
                console.log('checked : ',checked);
                var allbbox = cmp.find("boxPack");
                if(allbbox.length>0){
                    for(var x in allbbox) allbbox[x].set("v.value",checked);
                }else allbbox.set("v.value",checked);
                var actualInvLIIndex = [];//cmp.get('v.actualInvLIIndex');
                var actualInvLI = [];//cmp.get('v.actualInvLI');
                var invli=cmp.get("v.INVLIList");

                if(checked){
                    cmp.set("v.allChecked",true);
                    for(var ind in invli ){
                        actualInvLIIndex.push(ind);
                        actualInvLI.push(invli[ind]);
                        cmp.set('v.actualInvLI',actualInvLI);
                        cmp.set('v.actualInvLIIndex',actualInvLIIndex);
                    }
                }
                else{
                    cmp.set("v.allChecked",false);
                    var INVLIList=cmp.get("v.INVLIList");
                    var actList=[];
                    var actINVList=[];
                    /*for(var j in INVLIList){
                actINVList.push(j);
            }*/
                    cmp.set('v.actualInvLI',actList);
                    cmp.set("v.actualInvLIIndex",actINVList);

                }
            }
            helper.updateTotalPrice_Handler(cmp);
             $A.enqueueAction(cmp.get("c.calculateDownPaymentAmt"));
            $A.enqueueAction(cmp.get("c.calculateDownPaymentPercentag"));

        }catch(err){
            console.log('err : ',err);
        }
    },

    getinvoiceLI : function(cmp, event, helper){

        var allbbox = cmp.find("select");
        allbbox.set("v.checked",false);
        var actualInvLIIndex = cmp.get('v.actualInvLIIndex');
        var actualInvLI = cmp.get('v.actualInvLI');

        var invli=cmp.get("v.INVLIList");

        if(event.getSource().get("v.checked")){

            for(var ind in invli ) {
                if(ind==event.getSource().get("v.name")){
                    actualInvLIIndex.push(ind);
                    actualInvLI.push(invli[ind]);
                    cmp.set('v.actualInvLI',actualInvLI);
                    cmp.set('v.actualInvLIIndex',actualInvLIIndex);

                }

            }

        }
        else{

            var INVLIList=cmp.get("v.actualInvLIIndex");
            var actList=[];
            var index=event.getSource().get("v.name");
            var act=cmp.get('v.actualInvLI');
            var actINVList=[];
            for(var j in INVLIList){
                if(INVLIList[j]!=index){
                    actList.push(act[j]);
                    actINVList.push(INVLIList[j]);
                }
            }
            cmp.set('v.actualInvLI',actList);
            cmp.set("v.actualInvLIIndex",actINVList);

        }
        helper.updateTotalPrice_Handler(cmp);
        $A.enqueueAction(cmp.get("c.calculateDownPaymentAmt"));
        $A.enqueueAction(cmp.get("c.calculateDownPaymentPercentag"));
    },

    onCheck : function(c, e, h){

        var shipping_tax_ammount =0,old=0,shipping_amount = 0;


        if(c.get('v.enableShipping'))
        {shipping_tax_ammount=c.get('v.salesorder.Shipping_VAT__c');
         shipping_amount=c.get('v.salesorder.Total_Shipping_Amount__c');
         if(shipping_tax_ammount==null || shipping_tax_ammount=='')shipping_tax_ammount=0;
         if(shipping_amount==null || shipping_amount=='')shipping_amount=0;
         var renderedFields = c.find("inv_input_field");
         for(var  x in renderedFields){
             if(renderedFields[x].get('v.fieldName')==='Invoice_Shipping_Amount__c'){
                 old = renderedFields[x].get("v.value");
                 if(old==null || old=='')old=0;
                 renderedFields[x].set("v.value",parseFloat(old+shipping_amount));
             }
             if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                 old = renderedFields[x].get("v.value");
                 if(old==null || old=='')old=0;
                 renderedFields[x].set("v.value",parseFloat(old+shipping_tax_ammount));
             }
             if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                 old = renderedFields[x].get("v.value");
                 if(old==null || old=='')old=0;
                 renderedFields[x].set("v.value",parseFloat(old+shipping_tax_ammount+shipping_amount));
             }
         }
        }
        else{
            shipping_tax_ammount=c.get('v.salesorder.Shipping_VAT__c');
            shipping_amount=c.get('v.salesorder.Total_Shipping_Amount__c');
            if(shipping_tax_ammount==null || shipping_tax_ammount=='')shipping_tax_ammount=0;
            if(shipping_amount==null || shipping_amount=='')shipping_amount=0;
            var renderedFields = c.find("inv_input_field");
            for(var  x in renderedFields){
                if(renderedFields[x].get('v.fieldName')==='Invoice_Shipping_Amount__c'){
                    old = renderedFields[x].get("v.value");
                    if(old==null || old=='')old=0;
                    renderedFields[x].set("v.value",parseFloat(old-shipping_amount));
                }
                if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                    old = renderedFields[x].get("v.value");
                    if(old==null || old=='')old=0;
                    renderedFields[x].set("v.value",parseFloat(old-shipping_tax_ammount));
                }
                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                    old = renderedFields[x].get("v.value");
                    if(old==null || old=='')old=0;
                    renderedFields[x].set("v.value",parseFloat(old-shipping_tax_ammount-shipping_amount));
                }
            }
        }


    },

    // calculateDownPaymentPercentag: function(component, event, helper) {

    //     var val = event.getSource().get("v.value");
    //     var renderedFields = component.find("inv_input_field");
    //     //if(val>0 && val<=96){
    //     var renderedFields = component.find("inv_input_field");
    //     var downPayment = component.find("downPayment");
    //     for(var  x in renderedFields){
    //         if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
    //             if(downPayment != undefined) downPayment.set("v.value",((val/renderedFields[x].get("v.value"))*100).toFixed(2));
    //         }

    //         if(renderedFields[x].get('v.fieldName')==='Down_Payment__c'){
    //             component.set("v.downPaymentPercentage",downPayment.get("v.value"));
    //             renderedFields[x].set('v.value',downPayment.get("v.value"));
    //         }
    //         if(renderedFields[x].get('v.fieldName')==='Total_Down_Payment_Amount__c'){
    //             renderedFields[x].set('v.value',val);
    //             component.set("v.downPaymentAmount", val);
    //         }



    //         // }
    //     }
    // },
    // calculateDownPaymentPercentag: function (component, event, helper) {
    //     var val = parseFloat(event.getSource().get("v.value") || 0); // Get the entered down payment amount
    //     console.log("Entered Down Payment Amount:", val);

    //     var renderedFields = component.find("inv_input_field");
    //     var downPayment = component.find("downPayment");
    //     var advanceAmountPaid = parseFloat(component.get("v.AmountPaid") || 0); // Get the advance amount paid
    //     console.log("Advance Amount Paid:", advanceAmountPaid);

    //     for (var x in renderedFields) {
    //         if (renderedFields[x].get("v.fieldName") === "Invoice_Amount__c") {
    //             var invoiceAmount = parseFloat(renderedFields[x].get("v.value") || 0);
    //             console.log("Invoice Amount:", invoiceAmount);

    //             // Calculate the remaining invoice amount
    //             var remainingAmount = invoiceAmount - advanceAmountPaid;
    //             console.log("Remaining Invoice Amount (after deducting advance):", remainingAmount);

    //             // Calculate the Down Payment Percentage
    //             var downPaymentPercentage = remainingAmount > 0 ? (val / remainingAmount) * 100 : 0;
    //             console.log("Calculated Down Payment Percentage:", downPaymentPercentage);

    //             // Update the Down Payment Percentage and Amount attributes
    //             component.set("v.downPaymentPercentage", downPaymentPercentage.toFixed(2));
    //             component.set("v.downPaymentAmount", val.toFixed(2));

    //             // Update the Down Payment Percentage field in the UI
    //             if (downPayment != undefined) {
    //                 downPayment.set("v.value", downPaymentPercentage.toFixed(2));
    //                 console.log("Updated Down Payment Percentage in the UI:", downPaymentPercentage);
    //             }

    //             // Update Total Down Payment Amount field
    //             if (renderedFields[x].get("v.fieldName") === "Total_Down_Payment_Amount__c") {
    //                 renderedFields[x].set("v.value", val.toFixed(2));
    //                 console.log("Updated Total Down Payment Amount in the UI:", val);
    //             }
    //         }
    //     }
    // },
    // calculateDownPaymentPercentag: function (component, event, helper) {
    //     var val = parseFloat(event.getSource().get("v.value") || 0); // Get the entered down payment amount
    //     console.log("Entered Down Payment Amount:", val);

    //     var renderedFields = component.find("inv_input_field");
    //     var downPayment = component.find("downPayment");
    //     var advanceAmountPaid = parseFloat(component.get("v.AmountPaid") || 0); // Get the advance amount paid
    //     console.log("Advance Amount Paid:", advanceAmountPaid);

    //     var invoiceAmount = 0;
    //     var remainingAmount = 0;

    //     // Loop through fields to find Invoice_Amount__c
    //     for (var x in renderedFields) {
    //         if (renderedFields[x].get("v.fieldName") === "Invoice_Amount__c") {
    //             invoiceAmount = parseFloat(renderedFields[x].get("v.value") || 0);
    //             console.log("Invoice Amount:", invoiceAmount);
    //             break; // Exit the loop once Invoice_Amount__c is found
    //         }
    //     }

    //     // Calculate remaining amount and percentage
    //     remainingAmount = invoiceAmount - advanceAmountPaid;
    //     if (remainingAmount < 0) remainingAmount = 0;
    //     console.log("Remaining Invoice Amount (after deducting advance):", remainingAmount);

    //     var downPaymentPercentage = remainingAmount > 0 ? (val / remainingAmount) * 100 : 0;
    //     console.log("Calculated Down Payment Percentage:", downPaymentPercentage);

    //     // Update fields
    //     component.set("v.downPaymentPercentage", downPaymentPercentage.toFixed(2));
    //     component.set("v.downPaymentAmount", val.toFixed(2));

    //     // Update relevant fields in the UI
    //     for (var x in renderedFields) {
    //         var fieldName = renderedFields[x].get("v.fieldName");

    //         // Update Total Down Payment Amount
    //         if (fieldName === "Total_Down_Payment_Amount__c") {
    //             renderedFields[x].set("v.value", val.toFixed(2));
    //             console.log("Updated Total Down Payment Amount in the UI:", val);
    //         }

    //         // Update Down Payment Percentage
    //         if (fieldName === "Down_Payment__c") {
    //             renderedFields[x].set("v.value", downPaymentPercentage.toFixed(2));
    //             console.log("Updated Down Payment Percentage in the UI:", downPaymentPercentage);
    //         }
    //     }

    //     // Update Down Payment Percentage field in UI (if found)
    //     if (downPayment != undefined) {
    //         downPayment.set("v.value", downPaymentPercentage.toFixed(2));
    //         console.log("Updated Down Payment Percentage in the UI:", downPaymentPercentage);
    //     }
    // },



    calculateDownPaymentPercentag: function(component, event, helper) {
        var val;

        // Get value from event if available, otherwise get it from the downPaymentAmt input
        if (event && event.getSource) {
            val = event.getSource().get("v.value");
        } else {
            var dpAmtField = component.find("downPaymentAmt");
            val = dpAmtField ? dpAmtField.get("v.value") : 0;
        }

        var renderedFields = component.find("inv_input_field");
        var downPayment = component.find("downPayment");

        for (var x in renderedFields) {
            if (renderedFields[x].get('v.fieldName') === 'Invoice_Amount__c') {
                var invoiceAmt = renderedFields[x].get("v.value");
                if (invoiceAmt && invoiceAmt != 0 && downPayment != undefined) {
                    var percent = ((val / invoiceAmt) * 100).toFixed(2);
                    downPayment.set("v.value", percent);
                }
            }

            if (renderedFields[x].get('v.fieldName') === 'Down_Payment__c') {
                var dpValue = downPayment ? downPayment.get("v.value") : 0;
                component.set("v.downPaymentPercentage", dpValue);
                renderedFields[x].set('v.value', dpValue);
            }

            if (renderedFields[x].get('v.fieldName') === 'Total_Down_Payment_Amount__c') {
                renderedFields[x].set('v.value', val);
                component.set("v.downPaymentAmount", val);
            }
        }
    },




    calculateInvoiceAmount : function(component, event, helper) {
        try{
            var val = event.getSource().get("v.value");
            var renderedFields = component.find("inv_input_field");
            console.log('renderedFields calculateInvoiceAmount',renderedFields);
            //var renderedFields = component.find("inv_input_field");
            var downPaymentAmtSales = component.find("downPaymentAmtSales");
            if(val == null || val == undefined || val == '') val = 0;
            if(val!=null && val!=undefined && val!=''){
                var subTotal = 0.00;//component.get("v.")
                var totalTaxInv=0.00;
                var invli = component.get("v.actualInvLI");
                for(var x in invli){
                    subTotal += parseFloat(invli[x].Sub_Total__c);
                    totalTaxInv+=parseFloat(invli[x].VAT_Amount__c)+parseFloat(invli[x].Other_Tax__c);
                }
                console.log('Initially sub total inv: '+(subTotal).toFixed(2));
                console.log('Initially total tax inv: '+(totalTaxInv).toFixed(2));

                for(var  x in renderedFields){
                    if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                        renderedFields[x].set('v.value',((subTotal*val)/100).toFixed(2));
                        component.set("v.subTotal", ((subTotal*val)/100).toFixed(2));
                        //component.set("v.InvAmount",((subTotal*val)/100).toFixed(2));
                        console.log('inv amt set here '+((subTotal*val)/100).toFixed(2));
                    }
                    if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                        renderedFields[x].set('v.value',0.00);
                        component.set("v.invTax", 0.00);
                        console.log('inv tax set here 0');
                    }
                    if(renderedFields[x].get('v.fieldName')==='Paid_Amount_Applied__c'){
                        renderedFields[x].set('v.value',((component.get("v.AmountPaid")*val)/100).toFixed(2));
                        var paidAmountApplied = component.find("paidAmountApplied");
                        if(paidAmountApplied != undefined && component.get("v.selectedrecordTypeMap.DeveloperName") != 'Schedule_Invoice') paidAmountApplied.set("v.value",((component.get("v.AmountPaid")*val)/100).toFixed(2));
                        if(component.get("v.selectedrecordTypeMap.DeveloperName") != 'Schedule_Invoice')component.set("v.PaidAmountApplied", ((component.get("v.AmountPaid")*val)/100).toFixed(2));
                        console.log('PaidAmountApplied 2: ',component.get("v.PaidAmountApplied"));
                    }
                    if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Percentage__c'){
                        console.log('inhere1');
                        renderedFields[x].set('v.value',val);
                    }
                    if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c'){
                        console.log('inhere2');
                        //renderedFields[x].set('v.value',0.00);
                        renderedFields[x].set('v.value',val);
                    }
                }
                console.log('inhere3');
                var downPaymentAmtSales = component.find("downPaymentAmtSales");
                if(downPaymentAmtSales != undefined) downPaymentAmtSales.set("v.value",val);
                var downPaymentTax = component.find("downPaymentTax");

                console.log('inhere4');
                //alert(downPaymentTax);
                console.log('component.get("v.disSchTax"): '+component.get("v.disSchTax")+' , component.get("v.subTotal")'+component.get("v.subTotal")+' , component.get("v.taxAmount"): '+component.get("v.taxAmount"));
                if(!component.get("v.disSchTax") && component.get("v.subTotal") > 0 && component.get("v.taxAmount")>0){
                    console.log('inhere5');
                    if(downPaymentTax!=undefined) downPaymentTax.set("v.value",parseFloat($A.get("$Label.c.Default_schedule_invoice_Tax")));
                    var value = parseFloat($A.get("$Label.c.Default_schedule_invoice_Tax"));
                    var renderedFields = component.find("inv_input_field");
                    var downPaymentAmtSales = component.find("downPaymentTax");
                    console.log('inhere6 Default_schedule_invoice_Tax '+val);
                    if(val!=null && val!=undefined && val!=''){
                        console.log('inhere7');
                        var invAmount = 0.00;
                        var TaxAmount = 0.00;
                        for(var  x in renderedFields){
                            if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                                TaxAmount = ((totalTaxInv*val)/100).toFixed(2);
                                renderedFields[x].set('v.value',TaxAmount);
                                component.set("v.invTax", TaxAmount);
                                console.log('inv tax set here 1~>'+TaxAmount);
                            }
                            if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c'){
                                renderedFields[x].set('v.value',val);
                                console.log('here Sales_Invoice_Tax_Percentage__c'+val);
                            }
                        }

                        for(var  x in renderedFields){
                            if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                                var invoiceAmount = parseFloat(component.get("v.subTotal"))+parseFloat(TaxAmount);
                                renderedFields[x].set('v.value',invoiceAmount);
                                component.set("v.InvAmount",invoiceAmount);
                                console.log('inv amt set here 2~>'+invoiceAmount);
                            }
                        }
                        var downPaymentTax = component.find("downPaymentTax");
                        if(downPaymentTax != undefined) downPaymentTax.set("v.value",val);
                        console.log('inhere8');
                    }
                    console.log('inhere9');
                }else{
                    console.log('inhere10');
                    for(var  x in renderedFields){
                        if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                            var invoiceAmount = parseFloat(component.get("v.subTotal"));
                            renderedFields[x].set('v.value',invoiceAmount);
                            component.set("v.InvAmount",invoiceAmount);
                            console.log('inv amt set here 2~>'+invoiceAmount);
                        }
                    }
                    if(downPaymentTax != undefined) downPaymentTax.set("v.value",0.00);
                }
                console.log('inhere11');
            }else{
                console.log('inhere12');
                var downPaymentAmtSales = component.find("downPaymentTax");
                if(downPaymentAmtSales!=undefined) downPaymentAmtSales.set("v.value",0.00);
                component.set("v.subTotal", 0.00);
                console.log('inhere13');
                for(var  x in renderedFields){
                    if(renderedFields[x].get('v.fieldName')==='Paid_Amount_Applied__c'){
                        renderedFields[x].set('v.value',0);
                        var paidAmountApplied = component.find("paidAmountApplied");
                        if(paidAmountApplied != undefined) paidAmountApplied.set("v.value",0);
                        component.set("v.PaidAmountApplied", 0);
                        console.log('PaidAmountApplied 2: ',component.get("v.PaidAmountApplied"));
                    }
                    if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                        renderedFields[x].set('v.value',0);
                        component.set("v.subTotal", 0);
                        component.set("v.InvAmount",0);
                    }
                }
                $A.enqueueAction(component.get("c.getallinvoiceLI"));
            }
        }catch(e){
            console.log('err',e);
        }
    },

    updateInvoicePercentage : function(component, event, helper) {
        var amount = component.get("v.subTotal");
        if(amount>0){
            var downPaymentAmtSales = component.find("downPaymentAmtSales");
            var percentage= (amount/component.get("v.invLineSubTotal"))*100;
            if(downPaymentAmtSales != undefined) downPaymentAmtSales.set("v.value",percentage.toFixed(2));
            if(amount>0){
                //downPaymentTax.set("v.value",parseFloat($A.get("$Label.c.Default_schedule_invoice_Tax")));
                var val = parseFloat($A.get("$Label.c.Default_schedule_invoice_Tax"));
                var renderedFields = component.find("inv_input_field");
                var downPaymentAmtSales = component.find("downPaymentTax");
                if(val!=null && val!=undefined && val!=''){
                    var invAmount = 0.00;
                    var TaxAmount = 0.00;
                    for(var  x in renderedFields){
                        if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c' && component.get("v.taxAmount")>0){
                            TaxAmount = ((component.get("v.subTotal")*val)/100).toFixed(2);
                            renderedFields[x].set('v.value',TaxAmount);
                            component.set("v.invTax", TaxAmount);
                        }
                        if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                            var invoiceAmount = parseFloat(component.get("v.subTotal"))+parseFloat(TaxAmount);
                            renderedFields[x].set('v.value',invoiceAmount);
                        }
                        if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c' && component.get("v.taxAmount")>0){
                            renderedFields[x].set('v.value',val);
                        }
                    }
                    var downPaymentTax = component.find("downPaymentTax");
                    if(component.get("v.taxAmount")>0 && downPaymentTax!=undefined) downPaymentTax.set("v.value",val);
                }
            }
        }else{
            var downPaymentAmtSales = component.find("downPaymentAmtSales");
            if(downPaymentAmtSales != undefined) downPaymentAmtSales.set("v.value",0.00);
            var renderedFields = component.find("inv_input_field");
            for(var  x in renderedFields){
                if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                    renderedFields[x].set('v.value',0.00);
                    component.set("v.invTax", 0.00);
                }
                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                    renderedFields[x].set('v.value',0.00);
                }
                if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c'){
                    renderedFields[x].set('v.value',0.00);
                }
            }
        }
    },

    calculateIvoiceTaxAmount : function(component, event, helper) {

        var val = event.getSource().get("v.value");
        var renderedFields = component.find("inv_input_field");
        //var renderedFields = component.find("inv_input_field");
        var downPaymentAmtSales = component.find("downPaymentTax");
        if(val!=null && val!=undefined && val!=''){
            var invAmount = 0.00;
            var TaxAmount = 0.00;
            /*for(var  x in renderedFields){
                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                    invAmount = renderedFields[x].get('v.value');
                }
            }*/

            for(var  x in renderedFields){
                if(renderedFields[x].get('v.fieldName')==='Tax_Amount__c'){
                    TaxAmount = ((component.get("v.subTotal")*val)/100).toFixed(2);
                    renderedFields[x].set('v.value',TaxAmount);
                    component.set("v.invTax", TaxAmount);
                }
                if(renderedFields[x].get('v.fieldName')==='Invoice_Amount__c'){
                    //alert(component.get("v.subTotal"));
                    var invoiceAmount = parseFloat(component.get("v.subTotal"))+parseFloat(TaxAmount);
                    renderedFields[x].set('v.value',invoiceAmount);
                }
                if(renderedFields[x].get('v.fieldName')==='Sales_Invoice_Tax_Percentage__c'){
                    console.log('BEING CALLED??'+val);
                    renderedFields[x].set('v.value',val);
                }
            }
            var downPaymentTax = component.find("downPaymentTax");
            if(downPaymentTax!=undefined) downPaymentTax.set("v.value",val);
        }
    },

    closePopup : function(cmp){
        cmp.set("v.showToast",false);
    },


    setAmountApplied : function(component, event, helper) {
        try{
            var val = event.getSource().get("v.value");
            console.log('val : ',val);
            console.log('advancePaymentPaidAmount: ',component.get("v.advancePaymentPaidAmount"));
            console.log('TotalPaidAmountApplied: ',component.get("v.TotalPaidAmountApplied"));
            var remainingAmount = (component.get("v.advancePaymentPaidAmount") - component.get("v.TotalPaidAmountApplied"));
            console.log('remainingAmount 555555: ',remainingAmount);
            if(val <0) component.set("v.showToast",true);{
                component.set("v.message","Paid amount applied cannot be negative");
                component.set("v.PaidAmountApplied",remainingAmount.toFixed(2));
            }
            if(val > remainingAmount.toFixed(2)){//Moin added this .toFixed(2)
                console.log('in 4: ');
                component.set("v.showToast",true);
                component.set("v.message","Paid amount applied is greater than advance payment");
                component.set("v.PaidAmountApplied",remainingAmount.toFixed(2));
                var paidAmountApplied = component.find("paidAmountApplied");
                if(paidAmountApplied != undefined) paidAmountApplied.set("v.value",remainingAmount.toFixed(2));
                var renderedFields = component.find("inv_input_field");
                for(var  x in renderedFields){
                    if(renderedFields[x].get('v.fieldName')==='Paid_Amount_Applied__c'){
                        renderedFields[x].set('v.value',remainingAmount.toFixed(2));
                    }
                }
                console.log('PaidAmountApplied 4: ',component.get("v.PaidAmountApplied"));
                window.setTimeout(
                    $A.getCallback(function() {
                        component.set("v.showToast",false);
                    }), 7000
                );
            }
            else{
                console.log('in 5: ');
                var paidAmountApplied = component.find("paidAmountApplied");
                if(paidAmountApplied != undefined) paidAmountApplied.set("v.value",val);
                component.set("v.PaidAmountApplied", val);
                console.log('PaidAmountApplied 3: ',component.get("v.PaidAmountApplied"));

                var renderedFields = component.find("inv_input_field");
                for(var  x in renderedFields){
                    if(renderedFields[x].get('v.fieldName')==='Paid_Amount_Applied__c'){
                        if(val!=null && val!=undefined && val!=''){
                            renderedFields[x].set('v.value',val);
                        }else renderedFields[x].set('v.value',0.00);
                    }
                }
            }
        }catch(e){
            console.log('err',e);
        }
    }
})