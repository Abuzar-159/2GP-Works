({
    checkOrderStatus: function (cmp, event) {
        console.log("quoteId in checkOrderStatus:", cmp.get("v.quoteId"));
        var action = cmp.get("c.checkOrdStatus");
        action.setParams({ quoteId: cmp.get("v.quoteId") });
        action.setCallback(this, function (response) {
            var state = response.getState(); console.log("state of initial :", state);
            if (state == "SUCCESS") {
                var res = response.getReturnValue();
                console.log("response of initial :", res);
                if (res == 'Order not created') {
                    var action = cmp.get("c.getQuoteAndLine");
                    action.setParams({ quoteId: cmp.get("v.quoteId") });
                    action.setCallback(this, function (response) {
                        var state = response.getState(); console.log("state of initial :", state);
                        if (state == "SUCCESS") {
                            var res = response.getReturnValue();
                            console.log("response of initial :", res);
                            cmp.set("v.quoteName", res.quote.Name);
                            cmp.set("v.errorMsg", res.errorMsg);
                            cmp.set("v.orderStatusoptions", res.status);
                            cmp.set("v.orderTypeoptions", res.type1);
                            cmp.set("v.order.Status", res.status[0]);
                            cmp.set("v.order.Type", res.type1[0]);
                            cmp.set("v.order.AccountId", res.quote.Customer__c);
                            cmp.set("v.order.Contact__c", res.quote.Contact__c);
                            cmp.set("v.order.Order_Profile__c", res.quote.Order_Profile__c);
                            cmp.set("v.order.Bill_To_Address__c", res.quote.Bill_To_Address__c);
                            cmp.set("v.order.Ship_To_Address__c", res.quote.Ship_To_Address__c);
                            cmp.set("v.order.Employee__r", res.emp);
                            cmp.set("v.order.Employee__c", res.emp.Id);
                            cmp.set("v.recType", res.recType);
                            console.log('QuotelineItems :', res.qtLineWapper);
                            cmp.set("v.listOfQuoteLine", res.qtLineWapper);
                            console.log('listOfQuoteLine==>'+JSON.stringify(cmp.get('v.listOfQuoteLine')));
                            if (cmp.get("v.listOfQuoteLine").length == 0) cmp.set('v.errorMsg', 'Line Items not available');
                            this.handleDiscountPercent(cmp, event);

                        } else {
                            console.log('Error :', response.getError());
                            var error = response.getError();
                            cmp.set("v.errorMsg", error[0].message + ' ' + error[0].stackTrace);
                        }
                    });
                    $A.enqueueAction(action);
                } else {
                    $A.util.addClass(cmp.find("delModal"), "slds-fade-in-open");
                    $A.util.addClass(cmp.find("delModalBackdrop"), "slds-backdrop_open");
                    cmp.set('v.OrderAlreadyCreated', res);
                }

            } else {
                console.log('Error :', response.getError());
                var error = response.getError();
                cmp.set("v.errorMsg", error[0].message + ' ' + error[0].stackTrace);
            }
        });
        $A.enqueueAction(action);
    },
    handleDiscountPercent: function (cmp, event) {
        console.log("inside handleDiscountPercent");
        var listOfQuoteLine = cmp.get("v.listOfQuoteLine");
        for (var i = 0; i < listOfQuoteLine.length; i++) {
            if (!listOfQuoteLine[i].isPercent) {
                listOfQuoteLine[i].discountPercent = listOfQuoteLine[i].discountPercent / listOfQuoteLine[i].qtLine.Quantity__c;
            }
        }
        cmp.set("v.listOfQuoteLine", listOfQuoteLine);
        
    },

    validationCheck: function (cmp, event) {
        //var quotename=cmp.find("orderName").get("v.value");
        var customer = cmp.find("currCustomer");
        var profilling = cmp.find("currProfile");
        var currContact = cmp.find("currContact");
        var billToAdd = cmp.find("billToAdd");
        var shipToAdd = cmp.find("shipToAdd");
        //var isNameError;
        var isCustomerError;
        var isProfillingError;
        var isContactError;
        var isBillToAddError;
        var isShipToAddError;
        var NOerrorsval;
        /*if(quotename == ''){
            cmp.set("v.nameError","hasError1");
            isNameError=false;
        }else{
            cmp.set("v.nameError","");
            isNameError=true;
        }*/

        if (!$A.util.isUndefined(customer))
            isCustomerError = this.checkvalidationLookup(customer);
        if (!$A.util.isUndefined(profilling))
            isProfillingError = this.checkvalidationLookup(profilling);
        if (!$A.util.isUndefined(currContact))
            isContactError = this.checkvalidationLookup(currContact);
        if (!$A.util.isUndefined(billToAdd))
            isBillToAddError = this.checkvalidationLookup(billToAdd);
        if (!$A.util.isUndefined(shipToAdd))
            isShipToAddError = this.checkvalidationLookup(shipToAdd);

        if (isCustomerError && isProfillingError && isContactError && isBillToAddError && isShipToAddError) //isNameError && 
            NOerrorsval = true;
        else
            NOerrorsval = false;
        return NOerrorsval;
    },

    checkvalidationLookup: function (customer) {
        if ($A.util.isEmpty(customer.get("v.selectedRecordId"))) {
            customer.set("v.inputStyleclass", "hasError");
            return false;
        } else {
            customer.set("v.inputStyleclass", "");
            return true;
        }
    },

    validateFields: function (cmp, event) {
        console.log("inside validateFields");
        var selectedProducts = cmp.get("v.listOfQuoteLine");
        var isFieldsCom = false;
        var isPercent = true;
        for (var i = 0; i < selectedProducts.length; i++) {
            if (selectedProducts[i].qtLine.List_Price__c == '') {
                cmp.set("v.errorMsg", "Please enter the Price fields that are marked.");
            }

            if (selectedProducts[i].qtLine.Quantity__c == '') {
                cmp.set("v.errorMsg", "Please enter the quantity fields that are marked.");
            }

            if (parseInt(selectedProducts[i].discountPercent) == 0) { }
            else if (selectedProducts[i].discountPercent == '') {
                cmp.set("v.errorMsg", "Please enter the Discount fields that are marked.");
                isPercent = false;
            }

            if (selectedProducts[i].qtLine.List_Price__c == '' || selectedProducts[i].qtLine.Quantity__c == '' || isPercent == false) {
                return false;
            } else {
                isFieldsCom = true;
            }
        }
        if (isFieldsCom) return true;
        else return false;
    },

    taxCalculation: function (cmp, event) {
        console.log("inside taxCalculation");
        console.log("listOfQuoteLine ***", cmp.get("v.listOfQuoteLine"));
        var selectedProducts = cmp.get("v.listOfQuoteLine");
        for (var i = 0; i < selectedProducts.length; i++) {
            var discount = 0;
            var vatAmount1 = 0;
            var otherTax1 = 0;
            var discountPercent1 = parseFloat(selectedProducts[i].discountPercent);
            if (selectedProducts[i].discountPercent != 0) {
                if (selectedProducts[i].isPercent) {
                    discount = ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) * parseFloat(selectedProducts[i].discountPercent)) / 100;
                } else {
                    discount = parseFloat(selectedProducts[i].qtLine.Quantity__c) * (parseFloat(selectedProducts[i].discountPercent) / parseFloat(selectedProducts[i].qtLine.Quantity__c));
                }
            }
            
            //if (selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1 = (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined) ? (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))) : (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
            if(selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1= (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined)?(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))):(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c)*parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
            console.log('vat amoiunt here--'+(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c)*parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount)));
            if (selectedProducts[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined) ? (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))) : (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
            selectedProducts[i].vatAmount = vatAmount1;
            console.log('vat amt here 2 --'+selectedProducts[i].vatAmount);
            selectedProducts[i].otherTax = otherTax1;
            if (selectedProducts[i].qtLine.VAT_Amount__c != undefined) selectedProducts[i].qtLine.VAT_Amount__c = vatAmount1;
            console.log('qtline vat amount -> '+selectedProducts[i].qtLine.VAT_Amount__c);
            if (selectedProducts[i].qtLine.Other_Tax__c != undefined) selectedProducts[i].qtLine.Other_Tax__c = otherTax1;

        }
        cmp.set("v.listOfQuoteLine", selectedProducts);
    },

})