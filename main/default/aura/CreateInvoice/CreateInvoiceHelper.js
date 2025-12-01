({
    getInstancesAndRecordTypes: function (comp, event, helper) {

        var action = comp.get("c.getInvoiceRecordType");
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (comp.isValid() && state === "SUCCESS") {

                comp.set("v.Invoice", response.getReturnValue().InvoiceRecord);
                comp.set("v.InvoiceRTList", response.getReturnValue().InvoiceRTList);
                console.log('InvoiceRTList~>' + JSON.stringify(response.getReturnValue().InvoiceRTList));
                if (comp.get("v.InvoiceRTList").length == 1) {
                    let valArr = comp.get("v.InvoiceRTList")[0].split('@');
                    if (valArr.length > 1) {
                        comp.set("v.selectedrecordTypeMap", { 'RecordTypeId': valArr[0], 'DeveloperName': valArr[1] });
                    }
                }
                comp.set("v.showMmainSpin", false);
            } else {
                console.log('Error:', response.getError());
            }

        });
        $A.enqueueAction(action);
    },


    getAccountInformation: function (c, recId) {

        var a = c.get("c.fetchAccountDetails");
        a.setParam('recordId', recId);
        a.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                var obj = response.getReturnValue();
                var renderedFields = c.find("inv_input_field");
                for (var x in renderedFields) {
                    if (obj.hasOwnProperty(renderedFields[x].get('v.fieldName')))
                        renderedFields[x].set("v.value", obj[renderedFields[x].get('v.fieldName')]);

                }
            } else {
                console.log('Error:', response.getError());
            }
        });
        $A.enqueueAction(a);
    },
    CreateInvoiceAndLineItem: function (comp, event, helper) {
      console.log('CreateInvoiceAndLineItem');
        var INVLIList;
        console.log('comp.get("v.selectedrecordTypeMap.DeveloperName") : ', comp.get("v.selectedrecordTypeMap.DeveloperName"));

        if (comp.get("v.selectedrecordTypeMap.DeveloperName") === 'On_Account_Payment') {
            INVLIList = comp.get("v.INVLIList");
            console.log('here 1 INVLIList -->',INVLIList);
        } else {
            INVLIList = comp.get("v.actualInvLI");
            console.log('here 2 INVLIList -->',INVLIList);
        }

        for (var x = 0; x < INVLIList.length; x++) {
        //    alert(comp.get("v.invrecordId"));
            INVLIList[x].Invoice__c = comp.get("v.invrecordId");
            console.log('INVLIList[x].Invoice__c : ', INVLIList[x].Invoice__c);
            console.log('here 3 INVLIList -->',INVLIList);

            if (!$A.util.isEmpty(comp.get("v.StdId"))){
              console.log('Inside StdId');
              console.log('INVLIList[x].Order_Product__r.Invoiced_Quantity__c : ',INVLIList[x].Order_Product__r.Invoiced_Quantity__c);
              console.log('INVLIList[x].Quantity__c : ',INVLIList[x].Quantity__c);
                INVLIList[x].Order_Product__r.Invoiced_Quantity__c += parseFloat(INVLIList[x].Quantity__c);
            }
            if (!$A.util.isEmpty(comp.get("v.SOId"))){
              console.log('Inside SOId');
              console.log('INVLIList[x].Order_Product__r.Invoiced_Quantity__c : ',INVLIList[x].Order_Product__r.Invoiced_Quantity__c);
              console.log('INVLIList[x].Quantity__c : ',INVLIList[x].Quantity__c);
                INVLIList[x].Order_Product__r.Invoiced_Quantity__c += parseFloat(INVLIList[x].Quantity__c);
                console.log('INVLIList[x].Order_Product__r.Invoiced_Quantity__c againn : ',INVLIList[x].Order_Product__r.Invoiced_Quantity__c);

            }

        }
        if (comp.get('v.enableShippingAmount') && comp.get('v.enableShipping') && comp.get('v.salesorder.Total_Shipping_Amount__c') > 0
            && comp.get('v.selectedrecordTypeMap.DeveloperName') != 'Advance') {
            comp.set('v.salesorder.Include_Shipping_Amount__c', true);
        }

        var action = comp.get("c.getCreateInvoiceAndLineItemUpdated");
        console.log("INVLIList:", INVLIList);
        console.log("Sales Order:", comp.get("v.salesorder"));
        console.log("Payload:", {
            InvoiceLineItem: INVLIList ? JSON.stringify(INVLIList) : "INVLIList is undefined/null",
            SO: comp.get("v.salesorder") ? JSON.stringify(comp.get("v.salesorder")) : "Sales Order is undefined/null"
        });

        let salesorder = comp.get('v.salesorder');
        salesorder.Total_Down_Payment_Amount__c = comp.get('v.downPaymentAmount');
        console.log('salesorder',salesorder);
        console.log('INVLIList',INVLIList);

        action.setParams({
            Invoice : JSON.stringify(comp.get("v.NewInvoice")),
            InvoiceLineItem: JSON.stringify(INVLIList),
            // SO: JSON.stringify(comp.get('v.salesorder')),
            SO: JSON.stringify(salesorder),
            SOId: comp.get("v.SOId"),
            StdId: comp.get("v.StdId"),
            invType: comp.get('v.selectedrecordTypeMap.DeveloperName')
        });


        action.setCallback(this, function (response) {
            var state = response.getState();
            console.log('Company---> : ',comp.get("v.OrgId"));
            if (comp.isValid() && state === "SUCCESS") {
                if (comp.get("v.FromAR")) {
                    $A.createComponent(
                        "c:AccountsReceivable", {
                        "showTabs": 'inv',//comp.get("v.showTabs"),
                        "fetchRecordsBool": false,
                        "OrgId": comp.get("v.OrgId"),
                        "Order":'DESC',
                        "setSearch" :response.getReturnValue().Name,
                        "OrderBy":'CreatedDate'
                    },
                        function (newComp) {
                            var content = comp.find("body");
                            content.set("v.body", newComp);
                        }
                    );
                } else {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    if (!$A.util.isUndefined(navEvt)) {
                        navEvt.setParams({
                            "recordId": response.getReturnValue().Id,
                        });
                        navEvt.fire();
                    } else {
                        window.open("/"+response.getReturnValue().Id,"_self");//window.open("/" + comp.get("v.invrecordId"), "_self");
                    }

                }
            } else {
                console.log('Error:', response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    updateTotalPrice_Handler: function (component) {
        try {
            var invli = component.get("v.actualInvLI");
            var totalPrice = 0.00;
            var subTotal = 0.00;
            var shippingPrice = 0.00;
            var tax = 0.00;
            var amountPaid = 0.00;
            var discount = 0.00;
            for (var x in invli) {
                totalPrice += parseFloat(invli[x].Total_Price__c);
                tax += parseFloat(invli[x].VAT_Amount__c);
                tax += parseFloat(invli[x].Other_Tax__c);
                discount += parseFloat(invli[x].Discount_Amount__c);
                subTotal += parseFloat(invli[x].Sub_Total__c);
            }
            console.log('totalPrice : ', totalPrice);
            console.log('tax : ', tax);
            console.log('discount : ', discount);
            component.set("v.taxAmount", tax);
            component.set("v.invLineSubTotal", subTotal);

            var couponDiscount = component.get('v.salesorder.Coupon_Discount__c');
            if (couponDiscount != null && couponDiscount != '' && couponDiscount != undefined) discount += couponDiscount;
            if (couponDiscount == null || couponDiscount == '' || couponDiscount == undefined) couponDiscount = 0;
            var shipping_tax_ammount = 0;
            if (component.get('v.enableShippingAmount') && component.get('v.enableShipping')) shipping_tax_ammount = component.get('v.salesorder.Shipping_VAT__c');
            if (shipping_tax_ammount == null || shipping_tax_ammount == '') shipping_tax_ammount = 0;
            if (component.get('v.enableShippingAmount') && component.get('v.enableShipping')) tax += shipping_tax_ammount;

            var renderedFields = component.find("inv_input_field");
            var shipping_amount = 0;
            shipping_amount = component.get('v.salesorder.Total_Shipping_Amount__c');
            for (var x in renderedFields) {
                if (component.get('v.enableShippingAmount') && component.get('v.enableShipping')) {
                    if (renderedFields[x].get('v.fieldName') === 'Invoice_Shipping_Amount__c') {
                        renderedFields[x].set("v.value", shipping_amount);
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Invoice_Shipping_Amount__c') {
                        shippingPrice = renderedFields[x].get("v.value");

                    }
                }
                if (renderedFields[x].get('v.fieldName') === 'Amount_Paid__c') {
                    amountPaid = renderedFields[x].get("v.value");

                }

            }

            var downpayment = component.find("downPayment");
            var downpaymentAmt = component.find("downPaymentAmt");
            for (var x in renderedFields) {
                if (renderedFields[x].get('v.fieldName') === 'Invoice_Amount__c') {
                    //renderedFields[x].set("v.value",parseFloat((shippingPrice + totalPrice + shipping_tax_ammount) - couponDiscount ));
                    if (component.get("v.selectedrecordTypeMap.DeveloperName") === 'Schedule_Invoice') {
                        renderedFields[x].set("v.value", parseFloat(((shippingPrice + totalPrice + shipping_tax_ammount) - couponDiscount) - component.get('v.TDPayment')));
                    } else renderedFields[x].set("v.value", parseFloat(((shippingPrice + totalPrice + shipping_tax_ammount) - couponDiscount)));



                    //break;
                }
                if (renderedFields[x].get('v.fieldName') === 'Tax_Amount__c') {
                    renderedFields[x].set("v.value", parseFloat(tax));
                    //break;
                }
                if (renderedFields[x].get('v.fieldName') === 'Discount_Amount__c') {
                    renderedFields[x].set("v.value", parseFloat(discount));
                    //break;
                }
            }
        } catch (e) {
            console.log('err', e);
        }
    },

    getFieldsSetApiNameHandler: function (component, objectApiName, fieldSetApiName) {
        var action = component.get("c.getFieldsSetApiName");
        action.setParams({
            sObjectName: objectApiName,
            fieldSetApiName: fieldSetApiName
        });
        action.setCallback(this, function (response) {
            if (objectApiName === 'Invoice__c')
                component.set("v.invoiceFields", response.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    fetchTotalDownPayment: function (cmp) {

        var action = cmp.get("c.fetchTotalDownPayment1");
        action.setParams({
            orderId: cmp.get("v.SO_Id"),
            SorderId: cmp.get("v.Std_Id")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                cmp.set('v.TDPayment', response.getReturnValue());
                console.log('fetchTotalDownPayment1 TDPayment :  ', cmp.get('v.TDPayment'));
            }
            else {
                console.log('Error:', response.getError());
            }
        });
        $A.enqueueAction(action);
    },



    fetchScheduleInvoices: function (cmp) {
        var action = cmp.get("c.scheduleInvoices");
        action.setParams({
            orderId: cmp.get("v.SO_Id"),
            SorderId: cmp.get("v.Std_Id")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                console.log('response scheduleInvoices : ', response.getReturnValue());
                cmp.set('v.schInvoiceList', response.getReturnValue().schlst);
                cmp.set('v.advanceInvoiceList', response.getReturnValue().advlst);
                var advanceInvoices = [];
                advanceInvoices = response.getReturnValue().advlst;
                var advancePaymentPaidAmount = 0.0;
                for (var x in advanceInvoices) {
                    if (advanceInvoices[x].Amount_Paid__c != null && advanceInvoices[x].Amount_Paid__c != undefined) {
                        advancePaymentPaidAmount = advancePaymentPaidAmount + advanceInvoices[x].Amount_Paid__c;
                    }
                }
                console.log('advancePaymentPaidAmount : ', advancePaymentPaidAmount);
                cmp.set('v.advancePaymentPaidAmount', advancePaymentPaidAmount);
                var schInvoices = [];
                schInvoices = response.getReturnValue().schlst;
                var priorIA = 0.00;
                var priorIAPaidApplied = 0.00;
                var priorIAPaidReturned = 0.00;
                var priorSalesPaidApplied = 0.00;
                var creditIA = 0.00;
                var salesorderAmount = 0.00;
                var AmountPaid = 0.00;
                var salesInvoices = [];
                salesInvoices = response.getReturnValue().saleslst;
                for (var i in salesInvoices) {
                    if (salesInvoices[i].Paid_Amount_Applied__c != null) priorSalesPaidApplied = parseFloat(salesInvoices[i].Paid_Amount_Applied__c) + priorSalesPaidApplied;
                    if (salesInvoices[i].Paid_Amount_Returned__c != null) priorIAPaidReturned = parseFloat(salesInvoices[i].Paid_Amount_Returned__c) + priorIAPaidReturned;
                }
                for (var i in schInvoices) {
                    if (schInvoices[i].Invoice_Amount__c != null) priorIA = parseFloat(schInvoices[i].Invoice_Amount__c) + priorIA;
                    if (schInvoices[i].Credit_Note__c != null) creditIA = parseFloat(schInvoices[i].Credit_Note__c) + creditIA;
                    salesorderAmount = parseFloat(schInvoices[i].Sales_Order_Amount__c);
                    if (schInvoices[i].Paid_Amount_Applied__c != null) priorIAPaidApplied = parseFloat(schInvoices[i].Paid_Amount_Applied__c) + priorIAPaidApplied;
                    if (schInvoices[i].Paid_Amount_Returned__c != null) priorIAPaidReturned = parseFloat(schInvoices[i].Paid_Amount_Returned__c) + priorIAPaidReturned;
                }
                cmp.set("v.schInvAmount", priorIA);
                cmp.set("v.schInvCreditAmount", creditIA);
                cmp.set("v.schInvPaidApplied", priorIAPaidApplied);
                if(cmp.get("v.selectedrecordTypeMap.DeveloperName") != 'Schedule_Invoice') cmp.set("v.PaidAmountApplied", cmp.get("v.AmountPaid") - priorIAPaidApplied - priorSalesPaidApplied + priorIAPaidReturned);
                else cmp.set("v.PaidAmountApplied", 0.00);
                console.log('AmountPaid: ', cmp.get("v.AmountPaid"));
                console.log('priorIAPaidApplied: ', priorIAPaidApplied);
                console.log('priorSalesPaidApplied: ', priorSalesPaidApplied);
                console.log('priorIAPaidReturned: ', priorIAPaidReturned);
                cmp.set("v.TotalPaidAmountApplied", priorIAPaidApplied + priorSalesPaidApplied - priorIAPaidReturned);
                console.log('PaidAmountApplied 1: ', cmp.get("v.PaidAmountApplied"));
                var paidAmountApplied = cmp.find("paidAmountApplied");
                if (paidAmountApplied != null && paidAmountApplied != undefined && paidAmountApplied != '') paidAmountApplied.set("v.value", cmp.get("v.PaidAmountApplied"));
                //if(val!=null && val!=undefined && val!=''){
                var renderedFields = cmp.find("inv_input_field");
                for (var x in renderedFields) {
                    if (renderedFields[x].get('v.fieldName') === 'Paid_Amount_Applied__c') {
                        renderedFields[x].set('v.value', cmp.get("v.PaidAmountApplied"));
                    }
                     if (renderedFields[x].get('v.fieldName') === 'Account__c') {
                        console.log('AccId here 2 :',renderedFields[x].get("v.value"));
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Company__c') {
                        console.log('Comp here 2:',renderedFields[x].get("v.value"));
                    }
                }
                //}
                var amt = priorIA - creditIA;
                console.log('amt : ', amt);
                console.log('salesorderAmount : ', salesorderAmount);

                if (amt >= salesorderAmount && schInvoices.length > 0) {
                    console.log('in : ');
                    cmp.set("v.selectedrecordTypeMap.DeveloperName", '');
                    cmp.set("v.showToast", true);
                    //this.showToast($A.get('$Label.c.Error_UsersShiftMatch'),'error','We have already record a complete scheduled invoices for this Order');
                    cmp.set("v.message", "We have already record a complete scheduled invoices for this Order");
                    window.setTimeout(
                        $A.getCallback(function () {
                            history.back();
                        }), 5000
                    );
                }
                if (schInvoices.length > 0 && cmp.get("v.selectedrecordTypeMap.DeveloperName") == 'Advance') {
                    cmp.set("v.showToast", true);
                    cmp.set("v.message", "There is already a schedule invoice against this order. So please create the schedule invoice");
                    cmp.set("v.selectedrecordTypeMap.DeveloperName", '');
                }
                if (advanceInvoices.length > 0 && cmp.get("v.selectedrecordTypeMap.DeveloperName") == 'Advance') {
                    cmp.set("v.showToast", true);
                    cmp.set("v.message", "There is already an advance invoice against this order. So please create the sales or schedule invoice");
                    cmp.set("v.selectedrecordTypeMap.DeveloperName", '');
                }
                console.log('cmp.get("v.AmountPaid") : ', cmp.get("v.AmountPaid"));
                console.log('TDPayment get : ', cmp.get("v.TDPayment"));
                console.log('cmp.get("v.selectedrecordTypeMap").DeveloperName : ', cmp.get("v.selectedrecordTypeMap").DeveloperName);
                if (cmp.get("v.TDPayment") != null && cmp.get("v.TDPayment") != undefined && cmp.get("v.TDPayment") > 0 && cmp.get("v.TDPayment") != cmp.get("v.AmountPaid") && (cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Schedule_Invoice' || cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Sales')) { // cmp.get("v.TDPayment") != cmp.get("v.AmountPaid") has been changed to equals as requested by polymem. The user should be able to create schedule invoice once the advance invovice is paid and the total down payemnt equals Amount paid
                    cmp.set("v.showToast", true);
                    cmp.set("v.message", "There is already an Advance invoice against this order which is not paid. So please create a payment and record a schedule invoice");
                    cmp.set("v.selectedrecordTypeMap.DeveloperName", '');
                }
            }
            else {
                console.log('Error:', response.getError());
            }
        });
        $A.enqueueAction(action);
    },

    /*checkMultipleCurrency : function(cmp){
        var action = cmp.get("c.checkMultipleCurrency");
        action.setCallback(this,function(response){
            cmp.set('v.MultipleCurrency',response.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    fetchCurrencyIso : function(cmp){
        var action = cmp.get("c.currencyIso");
        action.setParams({SalesorderId:cmp.get("v.SO_Id")});
        action.setCallback(this,function(response){
            cmp.set('v.CurrencyIsoCode',response.getReturnValue());
        });
    },*/

    fetchOrderInfo: function (cmp) {

        var action = cmp.get("c.fetchOrderDetails");
        action.setParams({
            orderId: cmp.get("v.SO_Id")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                cmp.set('v.salesorder', response.getReturnValue());
                cmp.set("v.orderAmount", response.getReturnValue().Sales_Order_Amount__c);
                if (cmp.get('v.salesorder.Total_Shipping_Amount__c') == null || cmp.get('v.salesorder.Total_Shipping_Amount__c') == '')
                    cmp.set('v.salesorder.Total_Shipping_Amount__c', 0);
                if (cmp.get('v.salesorder.Shipping_VAT__c') == null || cmp.get('v.salesorder.Shipping_VAT__c') == '')
                    cmp.set('v.salesorder.Shipping_VAT__c', 0);
                if (cmp.get('v.salesorder.Include_Shipping_Amount__c')) cmp.set('v.enableShippingAmount', false);
                else cmp.set('v.enableShippingAmount', true);
                var invli = cmp.get("v.INVLIList");
                var totalPrice = 0.00;
                var tax = 0.00;
                for (var x in invli) {
                    totalPrice += invli[x].Sub_Total__c;
                    tax += invli[x].VAT_Amount__c;
                    tax += invli[x].Other_Tax__c;
                }
                var result = response.getReturnValue();
                cmp.set("v.NewInvoice.Account__c", result.AccountId);
                cmp.set("v.NewInvoice.Contact__c", result.Contact__c);
                var obj = {
                    'Company__c': result.Company__c, 'Account__c': result.Account__c, 'Contact__c': result.Contact__c,
                    'Amount_Paid__c': result.Amount_Paid__c, 'Total_Down_Payment_Amount__c': cmp.get('v.TDPayment'), 'Sales_Invoice_Percentage__c': 0, 'Sales_Invoice_Tax_Percentage__c': 0
                };
                cmp.set("v.OrgId",result.Company__c);
                console.log('Company---from fetchOrderInfo : ',cmp.get("v.OrgId"));
                /* var obj = {'Company__c':result.Company__c,'Account__c':result.Account__c,
                           'Invoice_Shipping_Amount__c':result.Total_Shipping_Amount__c,
                           'Tax_Amount__c':parseFloat(tax), //response.getReturnValue().Total_Tax_Amount__c,
                           'Amount_Paid__c':result.Amount_Paid__c,
                           'Invoice_Amount__c':parseFloat((tax+totalPrice+result.Total_Shipping_Amount__c) - result.Amount_Paid__c) //response.getReturnValue().Sales_Order_Amount__c
                          };*/
                /*
                           'Total_Down_Payment_Amount__c':parseFloat(tax+totalPrice+result.Total_Shipping_Amount__c),
                           'Down_Payment__c':parseFloat(1.00),*/
                if (result.Amount_Paid__c != null && result.Amount_Paid__c > 0) {
                    cmp.set("v.displayPaid", true);
                }
                if (result.Account__c != null && result.Account__r.Payment_Terms__c != null) {
                    var now = new Date();
                    now.setDate(now.getDate() + result.Account__r.Payment_Terms__c);
                    cmp.set("v.defaultValues", { 'Invoice_Date__c': now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate(), 'Invoice_Due_Date__c': now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate() });
                }
                cmp.set("v.AmountPaid", parseFloat(result.Amount_Paid__c));
                if (cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Schedule_Invoice') {
                    var downPaymentAmtSales = cmp.find("downPaymentAmtSales");
                    downPaymentAmtSales.set("v.value", 0.00);
                    var downPaymentTax = cmp.find("downPaymentTax");
                    if (downPaymentTax != undefined) downPaymentTax.set("v.value", 0.00);
                }
                if (cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Advance') {
                    var downpayment = cmp.find("downPayment");
                    //downpayment.set("v.value",1);
                    downpayment.set("v.disabled", false);

                    // Disabling downpayment for first time
                    var downpaymentAmt = cmp.find("downPaymentAmt");
                    /* downpaymentAmt.set("v.value",parseFloat(tax+totalPrice+result.Total_Shipping_Amount__c));
                   */
                    downpaymentAmt.set("v.disabled", false);
                    /*obj['Down_Payment__c'] = 1;
                    obj['Total_Down_Payment_Amount__c'] = parseFloat(tax+totalPrice+result.Total_Shipping_Amount__c);
                    */
                }
                if (!$A.util.isUndefinedOrNull(obj)) {
                    var renderedFields = cmp.find("inv_input_field");
                    for (var x in renderedFields) {

                        if (obj.hasOwnProperty(renderedFields[x].get('v.fieldName')))
                            renderedFields[x].set("v.value", obj[renderedFields[x].get('v.fieldName')]);

                    }
                }
            } else {
                console.log('Error:', response.getError());
            }
        });
        if (!$A.util.isEmpty(cmp.get("v.SO_Id")))
            $A.enqueueAction(action);
        else
            this.setDefaulthandler(cmp);

    },
    fetchStnOrderInfo: function (cmp) {
        var action = cmp.get("c.fetchStndOrdDetails");
        console.log("cmp.get('v.Std_Id') : ", cmp.get("v.Std_Id"));
        action.setParams({
            Std_Id: cmp.get("v.Std_Id")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                cmp.set('v.salesorder', response.getReturnValue());
                console.log('response.getReturnValue() : ', response.getReturnValue());
                cmp.set("v.orderAmount", response.getReturnValue().Order_Amount__c);
                cmp.set("v.OrgId", response.getReturnValue().Company__c);
                console.log('Company---from fetchStnOrderInfo : ',cmp.get("v.OrgId"));
                if (cmp.get('v.salesorder.Total_Shipping_Amount__c') == null || cmp.get('v.salesorder.Total_Shipping_Amount__c') == '')
                    cmp.set('v.salesorder.Total_Shipping_Amount__c', 0);
                if (cmp.get('v.salesorder.Shipping_VAT__c') == null || cmp.get('v.salesorder.Shipping_VAT__c') == '')
                    cmp.set('v.salesorder.Shipping_VAT__c', 0);
                if (cmp.get('v.salesorder.Include_Shipping_Amount__c')) cmp.set('v.enableShippingAmount', false);
                else cmp.set('v.enableShippingAmount', true);
                var invli = cmp.get("v.INVLIList");
                var totalPrice = 0.00;
                var tax = 0.00;
                var VATamt = 0.00;
                for (var x in invli) {
                    totalPrice += invli[x].Sub_Total__c;
                    tax += invli[x].VAT_Amount__c;
                    VATamt += invli[x].VAT_Amount__c;
                    tax += invli[x].Other_Tax__c;
                }
                //var ordamt = (cmp.get("v.orderAmount") != undefined && cmp.get("v.orderAmount") != null && cmp.get("v.orderAmount") != '') ? cmp.get("v.orderAmount") : 0;
                //cmp.set("v.orderAmount", parseFloat(ordamt+VATamt));
                var result = response.getReturnValue();
                cmp.set("v.NewInvoice.Account__c", result.AccountId);
                cmp.set("v.NewInvoice.Contact__c", result.Contact__c);
                console.log('result fetchStndOrdDetails', JSON.stringify(result));
                var obj = {
                    'Company__c': result.Company__c, 'Account__c': result.AccountId, 'Contact__c': result.Contact__c,
                    'Amount_Paid__c': result.Amount_Paid__c, 'Total_Down_Payment_Amount__c': cmp.get('v.TDPayment'), 'Sales_Invoice_Percentage__c': 0, 'Sales_Invoice_Tax_Percentage__c': 0
                };
                var resultAmountPaid = 0;

                try {
                    console.log('result.Amount_Paid__c~>' + result.Amount_Paid__c);
                    if ($A.util.isUndefinedOrNull(result.Amount_Paid__c) || $A.util.isEmpty(result.Amount_Paid__c)) {
                        resultAmountPaid = 0;
                    } else resultAmountPaid = result.Amount_Paid__c;
                    console.log('resultAmountPaid~>' + resultAmountPaid);
                } catch (e) {
                    console.log('err', e);
                }
                resultAmountPaid = (resultAmountPaid > 0) ? parseFloat(resultAmountPaid) : 0;
                cmp.set("v.AmountPaid", resultAmountPaid);
                console.log('v.AmountPaid~>' + cmp.get("v.AmountPaid"));
                if (resultAmountPaid > 0) {
                    cmp.set("v.displayPaid", true);
                }
                if (result.AccountId != null && result.Account.Payment_Terms__c != null) {
                    var now = new Date();
                    now.setDate(now.getDate() + result.Account.Payment_Terms__c);
                    cmp.set("v.defaultValues", { 'Invoice_Date__c': now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate(), 'Invoice_Due_Date__c': now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate() });
                }
                if (cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Schedule_Invoice') {
                    var downPaymentAmtSales = cmp.find("downPaymentAmtSales");
                    if (downPaymentAmtSales != undefined) downPaymentAmtSales.set("v.value", 0.00);
                    var downPaymentTax = cmp.find("downPaymentTax");
                    if (downPaymentTax != undefined) downPaymentTax.set("v.value", 0.00);
                }
                if (cmp.get("v.selectedrecordTypeMap").DeveloperName === 'Advance') {
                    var downpayment = cmp.find("downPayment");
                    //downpayment.set("v.value",1);
                    if (downpayment != undefined) downpayment.set("v.disabled", false);

                    // Disabling downpayment for first time
                    var downpaymentAmt = cmp.find("downPaymentAmt");

                    if (downpaymentAmt != undefined) downpaymentAmt.set("v.disabled", false);

                }
                if (!$A.util.isUndefinedOrNull(obj)) {
                    var renderedFields = cmp.find("inv_input_field");
                    for (var x in renderedFields) {
                        if (obj.hasOwnProperty(renderedFields[x].get('v.fieldName')))
                            renderedFields[x].set("v.value", obj[renderedFields[x].get('v.fieldName')]);

                    }
                }
                var renderedFields = cmp.find("inv_input_field");

                var now = new Date();
                cmp.set('v.today', now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate());

                for (var x in renderedFields) {
                    if (renderedFields[x].get('v.fieldName') === 'Order_S__c') {
                        var recId= renderedFields[x].get("v.value");
                        renderedFields[x].set("v.value", cmp.get('v.Std_Id') );
                        console.log('Id 2:',recId);
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Account__c') {
                        renderedFields[x].set("v.value", result.AccountId);
                        console.log('AccId here:',result.AccountId);
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Company__c') {
                        renderedFields[x].set("v.value", result.Company__c);
                        console.log('Comp here:',result.Company__c);
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Invoice_Date__c') {
                        var currentValue = renderedFields[x].get('v.value');
                        if (!currentValue) { // checks null, undefined, or empty string
                            renderedFields[x].set('v.value', cmp.get("v.today"));
                        }
                    }
                    if (renderedFields[x].get('v.fieldName') === 'Invoice_Due_Date__c') {
                        var currentValue = renderedFields[x].get('v.value');
                        if (!currentValue) { // checks null, undefined, or empty string
                            renderedFields[x].set('v.value', cmp.get("v.today"));
                        }
                    }
                }
            } else {
                console.log('Error:', response.getError());
            }
        });
        if (!$A.util.isEmpty(cmp.get("v.Std_Id")))
            $A.enqueueAction(action);
        else
            this.setDefaulthandler(cmp);

    },

    getInvoiceLineItem: function (component) {
        console.log('getInvoiceLineItem inside::~.');
        var action = component.get("c.getInvoiceLineItems");
        action.setParams({
            SOId: component.get("v.SO_Id"),
            Std_Id: component.get("v.Std_Id")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                console.log('response getInvoiceLineItems : ', response.getReturnValue());
                component.set("v.INVLIList", response.getReturnValue());
            } else {
                console.log('Error:', response.getError());
            }

        });
        if (!$A.util.isEmpty(component.get("v.SO_Id")) || !$A.util.isEmpty(component.get("v.Std_Id")))
            $A.enqueueAction(action);

        else
            component.set("v.INVLIList", []);

    },
    setDefaulthandler: function (component) {
        var obj = component.get("v.defaultValues");
        var now = new Date();
        component.set('v.today', now.getFullYear() + '-' + (now.getMonth() + 1) + '-' + now.getDate());
        var renderedFields = component.find("inv_input_field");
        var downpayment = component.find("downPayment");
        if (!$A.util.isUndefined(downpayment)) {
            downpayment.set("v.value", 0.00);
            downpayment.set("v.disabled", true);
        }

        var downpaymentAmt = component.find("downPaymentAmt");
        if (!$A.util.isUndefined(downpaymentAmt)) {
            downpaymentAmt.set("v.value", 0.00);
            downpaymentAmt.set("v.disabled", true);
        }
        for (var x in renderedFields) {
            if (!$A.util.isUndefinedOrNull(obj) && obj.hasOwnProperty(renderedFields[x].get('v.fieldName')))
                renderedFields[x].set("v.value", obj[renderedFields[x].get('v.fieldName')]);
            if (renderedFields[x].get('v.fieldName') === 'Invoice_Amount__c' || renderedFields[x].get('v.fieldName') === 'Tax_Amount__c' || renderedFields[x].get('v.fieldName') === 'Invoice_Amount__c' || renderedFields[x].get('v.fieldName') === 'Invoice_Shipping_Amount__c') {
                renderedFields[x].set("v.value", 0.00);
                renderedFields[x].set("v.disabled", true);
            }
            if (renderedFields[x].get('v.fieldName') === 'Order_S__c') {
                renderedFields[x].set("v.value", component.get("v.SOId"));
            }
            if (renderedFields[x].get('v.fieldName') === 'Down_Payment__c')
                renderedFields[x].set('v.value', 0);
            if (renderedFields[x].get('v.fieldName') === 'Invoice_Date__c')
                renderedFields[x].set('v.value', component.get("v.today"));
            if (renderedFields[x].get('v.fieldName') === 'Company__c' || renderedFields[x].get('v.fieldName') === 'Account__c')
                renderedFields[x].set("v.value", '');
        }

    },
    showToast: function (title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent != undefined) {
            toastEvent.setParams({
                "mode": "dismissible",
                "title": title,
                "type": type,
                "message": message
            });
            toastEvent.fire();
        }

    },


    OrderProcess: function (cmp, event, helper) {
        var action = cmp.get("c.getFunctionalityControlOrderProcess");
        action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                if (response.getReturnValue()) {
                    this.getFieldsSetApiNameHandler(cmp, 'Invoice__c', 'Create_Order_Invoice');
                } else {
                    this.getFieldsSetApiNameHandler(cmp, 'Invoice__c', 'createinvoice');
                }
            }
        });
        $A.enqueueAction(action);

    },


    functionalityControl: function (cmp, event, helper) {
        var action = cmp.get("c.getFuntionalityControl");
        action.setCallback(this, function (response) {
            if (response.getState() === 'SUCCESS') {
                if (response.getReturnValue() != null) {
                    try {
                        cmp.set("v.disSchTax", response.getReturnValue().Display_Tax_Percentage_for_scheduled_inv__c);
                        cmp.set("v.enableSchTax", response.getReturnValue().Allow_scheduled_invoice_tax_editing__c);
                        cmp.set("v.disableSubTotal", response.getReturnValue().disableSubTotalOnInvoice__c);
                        cmp.set("v.doneShowAdvanceAppliedAmount", response.getReturnValue().Dont_show_Advance_applied_in_invoice__c);
                    } catch (e) {
                        console.log('err', e);
                    }
                }
            }
        });
        $A.enqueueAction(action);

    },
})