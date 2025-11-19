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
//Commented by Abuzar on 12-11-2025 to add new tax calculation logic for subscription products
//     taxCalculation: function (cmp, event) {
//         console.log('AZ Inside tax calculation');
        
//         console.log("inside taxCalculation");
//         console.log("listOfQuoteLine ***", cmp.get("v.listOfQuoteLine"));
//         var selectedProducts = cmp.get("v.listOfQuoteLine");
//         for (var i = 0; i < selectedProducts.length; i++) {
//             var discount = 0;
//             var vatAmount1 = 0;
//             var otherTax1 = 0;
//             var discountPercent1 = parseFloat(selectedProducts[i].discountPercent);
//             if (selectedProducts[i].discountPercent != 0) {
//                 if (selectedProducts[i].isPercent) {
//                     discount = ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) * parseFloat(selectedProducts[i].discountPercent)) / 100;
//                 } else {
//                     discount = parseFloat(selectedProducts[i].qtLine.Quantity__c) * (parseFloat(selectedProducts[i].discountPercent) / parseFloat(selectedProducts[i].qtLine.Quantity__c));
//                 }
//             }
            
//             //if (selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1 = (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined) ? (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))) : (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
//             // if(selectedProducts[i].tax.Tax_Rate__c != undefined) vatAmount1= (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined)?(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))):(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c)*parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
//             // console.log('vat amoiunt here--'+(parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c)*parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount)));
//             // if (selectedProducts[i].tax.Other_Tax_Rate__c != undefined) otherTax1 = (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && selectedProducts[i].qtLine.List_Price__c != undefined) ? (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * (parseFloat(selectedProducts[i].qtLine.Cost_Price__c))) : (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 * ((parseFloat(selectedProducts[i].qtLine.List_Price__c) * parseFloat(selectedProducts[i].qtLine.Quantity__c)) - discount));
           
// if (selectedProducts[i].qtLine.Product2 && selectedProducts[i].qtLine.Product2__r.Is_Subscribe__c) {
//         var No_of_Months = selectedProducts[i].qtLine.No_of_Months__c || 0;
//     var No_of_Days = selectedProducts[i].qtLine.No_of_Days__c || 0;
    
//     console.log('Subscription - Months:', No_of_Months, 'Days:', No_of_Days);
    
//     // --- VAT for Subscription Product ---
//     if (selectedProducts[i].tax && selectedProducts[i].tax.Tax_Rate__c != undefined) {
//         vatAmount1 =
//             (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' &&
//                 selectedProducts[i].qtLine.Cost_Price__c != undefined)
//                 ? (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 *
//                     parseFloat(selectedProducts[i].qtLine.Cost_Price__c))
//                 : (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 *
//                     (
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c) *
//                             parseFloat(No_of_Months))
//                         +
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c) *
//                             (parseFloat(No_of_Days) / 30))
//                         - parseFloat(discount)
//                     )
//                 );
//     }

//     // --- Other Tax for Subscription Product ---
//     if (selectedProducts[i].tax && selectedProducts[i].tax.Other_Tax_Rate__c != undefined) {
//         otherTax1 =
//             (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' &&
//                 selectedProducts[i].qtLine.Cost_Price__c != undefined)
//                 ? (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 *
//                     parseFloat(selectedProducts[i].qtLine.Cost_Price__c))
//                 : (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 *
//                     (
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c) *
//                             parseFloat(No_of_Months))
//                         +
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c) *
//                             (parseFloat(No_of_Days) / 30))
//                         - parseFloat(discount)
//                     )
//                 );
//     }

// } else {

//     // --- VAT for Non-Subscription Product ---
//     if (selectedProducts[i].tax && selectedProducts[i].tax.Tax_Rate__c != undefined) {
//         vatAmount1 =
//             (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' &&
//                 selectedProducts[i].qtLine.Cost_Price__c != undefined)
//                 ? (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 *
//                     parseFloat(selectedProducts[i].qtLine.Cost_Price__c))
//                 : (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100 *
//                     (
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c))
//                         - parseFloat(discount)
//                     )
//                 );
//     }

//     // --- Other Tax for Non-Subscription Product ---
//     if (selectedProducts[i].tax && selectedProducts[i].tax.Other_Tax_Rate__c != undefined) {
//         otherTax1 =
//             (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' &&
//                 selectedProducts[i].qtLine.Cost_Price__c != undefined)
//                 ? (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 *
//                     parseFloat(selectedProducts[i].qtLine.Cost_Price__c))
//                 : (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100 *
//                     (
//                         (parseFloat(selectedProducts[i].qtLine.List_Price__c) *
//                             parseFloat(selectedProducts[i].qtLine.Quantity__c))
//                         - parseFloat(discount)
//                     )
//                 );
//     }
// }
//             selectedProducts[i].vatAmount = vatAmount1;
//             console.log('vat amt here 2 --'+selectedProducts[i].vatAmount);
//             selectedProducts[i].otherTax = otherTax1;
//             if (selectedProducts[i].qtLine.VAT_Amount__c != undefined) selectedProducts[i].qtLine.VAT_Amount__c = vatAmount1;
//             console.log('qtline vat amount -> '+selectedProducts[i].qtLine.VAT_Amount__c);
//             if (selectedProducts[i].qtLine.Other_Tax__c != undefined) selectedProducts[i].qtLine.Other_Tax__c = otherTax1;

//         }
//         cmp.set("v.listOfQuoteLine", selectedProducts);
//     },



//             //-------------- added by abuzr on 12-11-2025 for handling the subscribtion produt tax calculation on quantity change ----------------

taxCalculation: function (cmp, event) {
    console.log('AZ Inside tax calculation');
    console.log("inside taxCalculation");
    console.log("listOfQuoteLine ***", cmp.get("v.listOfQuoteLine"));
    var selectedProducts = cmp.get("v.listOfQuoteLine");
    
    for (var i = 0; i < selectedProducts.length; i++) {
        var discount = 0;
        var vatAmount1 = 0;
        var otherTax1 = 0;
        var discountPercent1 = parseFloat(selectedProducts[i].discountPercent);
        
        // Calculate base amount (before tax)
        var baseAmount = 0;
        
        // Handle VAT and Other Tax for both subscription and non-subscription products
        if (selectedProducts[i].qtLine.Product__r && selectedProducts[i].qtLine.Product__r.Is_Subscribe__c) {
            
            var No_of_Months = parseFloat(selectedProducts[i].qtLine.Month_Duration__c) || 0;
            var No_of_Days = parseFloat(selectedProducts[i].qtLine.Duration_in_Days__c) || 0;
            
            console.log('Subscription - Months:', No_of_Months, 'Days:', No_of_Days);
            
            // Calculate base amount for subscription (Price * Quantity * Months + Price * Quantity * Days/30)
            var monthlyAmount = (parseFloat(selectedProducts[i].qtLine.List_Price__c) * 
                                parseFloat(selectedProducts[i].qtLine.Quantity__c) * 
                                No_of_Months);
            
            var dailyAmount = (parseFloat(selectedProducts[i].qtLine.List_Price__c) * 
                              parseFloat(selectedProducts[i].qtLine.Quantity__c) * 
                              (No_of_Days / 30));
            
            // For subscription: calculate base without discount first
            var baseBeforeDiscount = monthlyAmount + dailyAmount;
            
            // Calculate discount for subscription based on months/days base
            var discount = 0;
            if (selectedProducts[i].discountPercent != 0) {
                if (selectedProducts[i].isPercent) {
                    discount = (baseBeforeDiscount * parseFloat(selectedProducts[i].discountPercent)) / 100;
                } else {
                    discount = parseFloat(selectedProducts[i].discountPercent);
                }
            }
            
            baseAmount = baseBeforeDiscount - discount;
            
            console.log('Monthly Amount:', monthlyAmount, 'Daily Amount:', dailyAmount, 'Base Amount:', baseAmount);
            
            // --- VAT for Subscription Product ---
            if (selectedProducts[i].tax && selectedProducts[i].tax.Tax_Rate__c != undefined) {
                if (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && 
                    selectedProducts[i].qtLine.Cost_Price__c != undefined) {
                    vatAmount1 = (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100) * 
                                 parseFloat(selectedProducts[i].qtLine.Cost_Price__c);
                } else {
                    vatAmount1 = (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100) * baseAmount;
                }
            }
            
            // --- Other Tax for Subscription Product ---
            if (selectedProducts[i].tax && selectedProducts[i].tax.Other_Tax_Rate__c != undefined) {
                if (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && 
                    selectedProducts[i].qtLine.Cost_Price__c != undefined) {
                    otherTax1 = (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100) * 
                                parseFloat(selectedProducts[i].qtLine.Cost_Price__c);
                } else {
                    otherTax1 = (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100) * baseAmount;
                }
            }
            
        } else {
            
            // Calculate base amount for non-subscription
            var baseBeforeDiscount = (parseFloat(selectedProducts[i].qtLine.List_Price__c) * 
                                     parseFloat(selectedProducts[i].qtLine.Quantity__c));
            
            // Calculate discount for non-subscription
            var discount = 0;
            if (selectedProducts[i].discountPercent != 0) {
                if (selectedProducts[i].isPercent) {
                    discount = (baseBeforeDiscount * parseFloat(selectedProducts[i].discountPercent)) / 100;
                } else {
                    discount = parseFloat(selectedProducts[i].discountPercent);
                }
            }
            
            baseAmount = baseBeforeDiscount - discount;
            
            console.log('Non-Subscription Base Amount:', baseAmount);
            
            // --- VAT for Non-Subscription Product ---
            if (selectedProducts[i].tax && selectedProducts[i].tax.Tax_Rate__c != undefined) {
                if (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && 
                    selectedProducts[i].qtLine.Cost_Price__c != undefined) {
                    vatAmount1 = (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100) * 
                                 parseFloat(selectedProducts[i].qtLine.Cost_Price__c);
                } else {
                    vatAmount1 = (parseFloat(selectedProducts[i].tax.Tax_Rate__c) / 100) * baseAmount;
                }
            }
            
            // --- Other Tax for Non-Subscription Product ---
            if (selectedProducts[i].tax && selectedProducts[i].tax.Other_Tax_Rate__c != undefined) {
                if (selectedProducts[i].tax.Apply_Tax_On__c == 'Cost Price' && 
                    selectedProducts[i].qtLine.Cost_Price__c != undefined) {
                    otherTax1 = (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100) * 
                                parseFloat(selectedProducts[i].qtLine.Cost_Price__c);
                } else {
                    otherTax1 = (parseFloat(selectedProducts[i].tax.Other_Tax_Rate__c) / 100) * baseAmount;
                }
            }
        }
        
        selectedProducts[i].vatAmount = vatAmount1;
        selectedProducts[i].otherTax = otherTax1;
        selectedProducts[i].baseAmount = baseAmount;
        
        // Calculate net and gross amounts for display in component
        var netAmount = baseAmount;  // netAmount = base amount after discount
        var grossAmount = netAmount + vatAmount1 + otherTax1;  // grossAmount = net + tax
        
        selectedProducts[i].netAmount = netAmount;
        selectedProducts[i].subNetAmount = netAmount;       // For component display
        selectedProducts[i].subGrossAmount = grossAmount;  // For component display
        
        console.log('VAT Amount:', selectedProducts[i].vatAmount);
        console.log('Other Tax:', selectedProducts[i].otherTax);
        console.log('Net Amount:', selectedProducts[i].netAmount);
        console.log('Sub Net Amount:', selectedProducts[i].subNetAmount); 
        console.log('Sub Gross Amount:', selectedProducts[i].subGrossAmount);
        
        if (selectedProducts[i].qtLine.VAT_Amount__c != undefined) 
            selectedProducts[i].qtLine.VAT_Amount__c = vatAmount1;
        if (selectedProducts[i].qtLine.Other_Tax__c != undefined) 
            selectedProducts[i].qtLine.Other_Tax__c = otherTax1;
    }
    
    cmp.set("v.listOfQuoteLine", selectedProducts);
},
//             //-----------end here abuzar's changes---------


})