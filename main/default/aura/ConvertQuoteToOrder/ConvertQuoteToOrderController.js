({
	showSpinner: function(cmp, event, helper) {
        cmp.set("v.Spinner", true); 
    },    
    hideSpinner : function(cmp,event,helper){
        cmp.set("v.Spinner", false);
    },
    closeError : function(cmp,event){
        cmp.set("v.errorMsg",'');
    },
    
    initial : function(cmp, event, helper) {
        console.log("inside initial");
        console.log("quoteId :",cmp.get("v.quoteId"));
        helper.checkOrderStatus(cmp,event);
        
	},
    
    backToQuote : function(cmp, event) {
        $A.util.removeClass(cmp.find("delModal"),"slds-fade-in-open");
        $A.util.removeClass(cmp.find("delModalBackdrop"),"slds-backdrop_open");   
        var RecUrl = "/" + cmp.get("v.quoteId");
        //window.open(RecUrl,'_Self');
        sforce.one.navigateToURL(RecUrl);
    },
    
    removeError : function(cmp,event,helper){
        console.log("inside removeError");
        var value=cmp.find("orderName").get("v.value");
        if(value == ''){
            cmp.set("v.nameError","hasError1");
            cmp.set("v.errorMsg","Please enter the required fields that are marked *.");
        }
        else{
            cmp.set("v.nameError","");
            cmp.set("v.errorMsg","");
        }            
    },
    
  saveOrderAndLine1: function(cmp, event, helper) {
    console.log("inside saveOrderAndLine");

    // Perform initial validation checks for required fields
    var flag = helper.validationCheck(cmp, event);
    
    if (flag) {
        var valFields = helper.validateFields(cmp, event);
        
        if (valFields) {
            // Get the list of Quote Lines
            var listOfQuoteLine = cmp.get("v.listOfQuoteLine");

            // Ensure the order has a name
            var orderName = cmp.get("v.order.Name");
            if (!orderName || orderName === '') {
                orderName = 'Update_Name';
            }
            console.log('JSON.stringify(listOfQuoteLine) --'+JSON.stringify(listOfQuoteLine));
            // Prepare server-side action
            var action = cmp.get("c.saveOrderAndLine");
            action.setParams({
                listOfQuoteLine: JSON.stringify(listOfQuoteLine),
                quoteId: cmp.get("v.quoteId"),
                orderName: orderName,
                customer: cmp.get("v.order.AccountId"),
                contact: cmp.get("v.order.Contact__c"),
                orderProfile: cmp.get("v.order.Order_Profile__c"),
                employee: cmp.get("v.order.Employee__r.Id"),
                status: cmp.get("v.order.Status"),
                orderType: cmp.get("v.order.Type"),
                billToAdd: cmp.get("v.order.Bill_To_Address__c"),
                shipToAdd: cmp.get("v.order.Ship_To_Address__c"),
                description: cmp.get("v.order.Description"),
                org: cmp.get("v.order.Employee__r.Company__c")
            });

            // Handle the callback
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('State of saveOrderAndLine:', state);
                
                if (state === "SUCCESS") {
                    // Get the response value
                    var returnValue = response.getReturnValue();
                    console.log("Response of listOfQuoteLine:", returnValue);
                    
                    // Check if there are specific errors related to products or other issues
                    if (returnValue.includes("An order product's Start Date can't be earlier than Order Start Date")) {
                        cmp.set("v.errorMsg", "An order product's Start Date can't be earlier than Order Start Date. Please verify subscription product's start date is today or a future date.");
                    } else if (returnValue.includes("Line Number @") || returnValue.includes("Order Already created for") || returnValue.includes("User is not Allowed to create")) {
                        cmp.set("v.errorMsg", returnValue);
                    } else {
                        // Success - navigate to the new order record
                        //var RecUrl = "/" + returnValue;
                        //window.open(RecUrl, "_parent");  // Open the order record
                        window.location.href = "/" + returnValue;
                    }
                } else {
                    // Handle error state
                    var error = response.getError();
                    console.log('Error:', error);
                    cmp.set("v.errorMsg", error[0].message + ' ' + error[0].stackTrace);
                }
            });

            // Enqueue action
            $A.enqueueAction(action);
        }
    } else {
        // Handle validation error
        cmp.set("v.errorMsg", "Please enter the required fields that are marked *.");
    }
},
    
    NavRecord : function (component, event) {
        var RecId = event.getSource().get("v.title");
        var RecUrl = "/" + RecId;
        window.open(RecUrl,'_blank');
    },
    
    goBack : function(cmp,event,helper){
        //window.history.back();
        var RecUrl = "/" + cmp.get("v.quoteId");
        sforce.one.navigateToURL(RecUrl);
    },
    
   AllCheckboxSelect: function(cmp, event, helper) {
    var selectedHeaderCheck = event.getSource().get("v.value");
    var listOfQuoteLine = cmp.get("v.listOfQuoteLine");
    for (var i = 0; i < listOfQuoteLine.length; i++) {
        listOfQuoteLine[i].checkSelected = selectedHeaderCheck;
    }
    cmp.set("v.listOfQuoteLine", listOfQuoteLine);
},
    
    checkboxSelect : function(cmp,event,helper){
        var listOfQuoteLine=cmp.get("v.listOfQuoteLine");
        var count=0;
        for(var i=0;i<listOfQuoteLine.length;i++){
            if(listOfQuoteLine[i].checkSelected)
                count++;
        }
        if(count==listOfQuoteLine.length)
            cmp.find("AllBox").set("v.value", true);
        else
            cmp.find("AllBox").set("v.value", false);
    },
    
    handleUnitPrice : function(cmp,event,helper){
        console.log("inside handleUnitPrice");
        helper.taxCalculation(cmp,event);
    },
    
    handleQuantity : function(cmp,event,helper){
        console.log("inside handleQuantity");
        if(cmp.get("v.order.AccountId") ==''){
            cmp.set("v.errorMsg","Please Select Customer.");
            return;
        }
        if(cmp.get("v.order.Order_Profile__c") == ''){
            cmp.set("v.errorMsg","Please Select Order Profile.");
            return;
        }
        var index=event.getSource().get("v.title");
        var quantity=event.getSource().get("v.value");
        var listOfQuoteLine=cmp.get("v.listOfQuoteLine");
        var currCustomer=cmp.get("v.order.AccountId");
        var currProfile=cmp.get("v.order.Order_Profile__c");
        var crtlistOfQuoteLine=listOfQuoteLine[index];
        if(quantity != 0 && quantity != ''){
            var action=cmp.get("c.getDiscountPlan");
            action.setParams({
                customer : currCustomer,
                qtProfile : currProfile,
                prodId : crtlistOfQuoteLine.qtLine.Product__c,
                quantity : quantity
            });
            action.setCallback(this,function(response){
                var state=response.getState();	console.log("state of handleQuantity :",state);
                if(state == "SUCCESS"){
                    var res=response.getReturnValue();
                    console.log("response of handleQuantity :",res);
                    crtlistOfQuoteLine.discountPlan=res.qtLineWapper[0].discountPlan;
                    crtlistOfQuoteLine.CurrentDiscounts=res.qtLineWapper[0].CurrentDiscounts;
                    crtlistOfQuoteLine.disPlans=res.qtLineWapper[0].disPlans;
                    crtlistOfQuoteLine.discountPercent=res.qtLineWapper[0].discountPercent;
                    crtlistOfQuoteLine.maxDiscount=res.qtLineWapper[0].maxDiscount;
                    crtlistOfQuoteLine.minDiscount=res.qtLineWapper[0].minDiscount;
                    crtlistOfQuoteLine.tierDists=res.qtLineWapper[0].tierDists;
                    for(var i=0;i<listOfQuoteLine.length;i++){
                        if(i==index)
                            listOfQuoteLine[i]=crtlistOfQuoteLine;
                    }
                    cmp.set("v.listOfQuoteLine",listOfQuoteLine);
                    helper.taxCalculation(cmp,event);
                    return;
                }else{
                    console.log('Error :',response.getError());
                    var error=response.getError();
                    cmp.set("v.errorMsg",error[0].message+' '+error[0].stackTrace);
                }
            });
            $A.enqueueAction(action);
        }        
    },
    
    handleDiscPlan : function(cmp,event,helper){
        console.log("inside handleDiscPlan");        
        var currentProd=event.getSource().get("v.title");
        var discountPlan=event.getSource().get("v.value");
        console.log("discountPlan :"+discountPlan);
        var listOfQuoteLine=cmp.get("v.listOfQuoteLine");
        console.log("listOfQuoteLine :",listOfQuoteLine);
        if(discountPlan != ''){
            for(var i=0;i<listOfQuoteLine.length;i++){
                if(currentProd == listOfQuoteLine[i].qtLine.Product__c){
                    listOfQuoteLine[i].discountPlan=discountPlan;
                    if(listOfQuoteLine[i].qtLine.Discount_Plan__c != undefined) listOfQuoteLine[i].qtLine.Discount_Plan__c=discountPlan;
                    for(var j=0;j<listOfQuoteLine[i].disPlans.length;j++){
                        if(discountPlan == listOfQuoteLine[i].disPlans[j].Id){
                            if(listOfQuoteLine[i].disPlans[j].Default_Discount_Percentage__c != undefined){
                                listOfQuoteLine[i].isPercent=true;
                                if(listOfQuoteLine[i].disPlans[j].Default_Discount_Percentage__c != undefined)
                                	listOfQuoteLine[i].discountPercent=listOfQuoteLine[i].disPlans[j].Default_Discount_Percentage__c;
                                else
                                    listOfQuoteLine[i].discountPercent=0;
                                if(listOfQuoteLine[i].disPlans[j].Floor_Discount_Percentage__c != undefined)
                                    listOfQuoteLine[i].minDiscount=listOfQuoteLine[i].disPlans[j].Floor_Discount_Percentage__c;
                                else
                                    listOfQuoteLine[i].minDiscount=0;
                                if(listOfQuoteLine[i].disPlans[j].Ceiling_Discount_Percentage__c != undefined)
                                    listOfQuoteLine[i].maxDiscount=listOfQuoteLine[i].disPlans[j].Ceiling_Discount_Percentage__c;
                                else
                                    listOfQuoteLine[i].maxDiscount=0;
                            }else{
                                listOfQuoteLine[i].isPercent=false;
                                if(listOfQuoteLine[i].disPlans[j].Default_Discount_Value__c != undefined)
                                	listOfQuoteLine[i].discountPercent=listOfQuoteLine[i].disPlans[j].Default_Discount_Value__c;
                                else
                                    listOfQuoteLine[i].discountPercent=0;
                                if(listOfQuoteLine[i].disPlans[j].Floor_Discount_Value__c != undefined)
                                    listOfQuoteLine[i].minDiscount=listOfQuoteLine[i].disPlans[j].Floor_Discount_Value__c;
                                else
                                    listOfQuoteLine[i].minDiscount=0;
                                if(listOfQuoteLine[i].disPlans[j].Ceiling_Discount_Value__c != undefined)
                                    listOfQuoteLine[i].maxDiscount=listOfQuoteLine[i].disPlans[j].Ceiling_Discount_Value__c;
                                else
                                    listOfQuoteLine[i].maxDiscount=0;
                            }                                
                            cmp.set("v.listOfQuoteLine",listOfQuoteLine);
                            return;
                        }
                    }                
                }            
            }
        }else{
            for(var i=0;i<listOfQuoteLine.length;i++){
                if(currentProd == listOfQuoteLine[i].qtLine.Product__c){
                    listOfQuoteLine[i].discountPlan=discountPlan;
                    listOfQuoteLine[i].isPercent=true;
                    listOfQuoteLine[i].discountPercent=0;
                    listOfQuoteLine[i].minDiscount=0;
                    listOfQuoteLine[i].maxDiscount=0;
                    cmp.set("v.listOfQuoteLine",listOfQuoteLine);
                    return;
                }
            }
        }
    },
    
    handleDiscount : function(cmp,event,helper){
        console.log("inside handleDiscount");
        var currentIndex=event.getSource().get("v.title");
        var discount=event.getSource().get("v.value");
        var listOfQuoteLine=cmp.get("v.listOfQuoteLine");
        var crtlistOfQuoteLine=listOfQuoteLine[currentIndex];
        console.log('discount :',discount);
        if(discount != ''){
            if(crtlistOfQuoteLine.maxDiscount != 0){
                if(discount > crtlistOfQuoteLine.maxDiscount){
                    cmp.set("v.errorMsg","Discount was larger than Max discount");
                    for(var i=0;i<listOfQuoteLine.length;i++){
                        if(i==currentIndex){
                            for(var j=0;j<listOfQuoteLine[i].disPlans.length;j++){
                                if(crtlistOfQuoteLine.isPercent){
                                    crtlistOfQuoteLine.discountPercent=listOfQuoteLine[i].disPlans[j].Default_Discount_Percentage__c;
                                    break;
                                }                                	
                                else{
                                    crtlistOfQuoteLine.discountPercent=listOfQuoteLine[i].disPlans[j].Default_Discount_Value__c;
                                }
                            }                            	
                            listOfQuoteLine[i]=crtlistOfQuoteLine;
                        }   
                    }                    
                    cmp.set("v.listOfQuoteLine",listOfQuoteLine);
                    helper.taxCalculation(cmp,event);
                    return;
                }else{
                    helper.taxCalculation(cmp,event);
                }
            }else{
                helper.taxCalculation(cmp,event);
            }             
        }
    },
    
    handleDrag : function(cmp, event, helper) {
        cmp.set("v.DragIndex", event.target.id);
    },
    
    allowDrop : function(cmp, event, helper) {
        event.preventDefault();
    },
    
    handleDrop : function(cmp, event, helper) {        
        var DragIndex = parseInt(cmp.get("v.DragIndex"));
        var indexVal=parseInt(event.currentTarget.getAttribute('data-index'));
        var listOfLineItems = cmp.get("v.listOfQuoteLine"); 
        var ShiftElement = listOfLineItems[DragIndex];
        console.log('ShiftElement :',ShiftElement);
        if($A.util.isUndefinedOrNull(ShiftElement)) return;
        listOfLineItems.splice(DragIndex, 1);                                          
        listOfLineItems.splice(indexVal, 0 , ShiftElement);
        cmp.set("v.listOfQuoteLine", listOfLineItems);
    },
     handleShipToRemove : function(component, event, helper) {
        // Reset Ship To Address
        component.set("v.order.Ship_To_Address__c", null);
        
        // Optionally, refresh the lookup query if necessary
        helper.refreshLookUp(component, 'shipToAdd');
    }
    
})