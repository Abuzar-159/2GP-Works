({
      doInit : function(component, event, helper) {
        console.log('doInit called');
         component.set("v.isLoading", true);
        helper.getDependentPicklists(component, event, helper);
        helper.getReturnDependentPicklists(component, event, helper);
        helper.doini(component, event, helper);
        helper.getBillingOptionsPickList(component,event,helper);
        
        if(component.get('v.SOId') != '') 
            helper.fetchSoliList(component, event, helper);
        else if(component.get('v.orderId') != '')
            helper.fetchOrdItemList(component, event, helper);
            else if(component.get('v.POId') != '')
                helper.fetchPOItemList(component, event,helper);
                else if(component.get('v.LogId') != ''){
                    console.log('in log det');
                    helper.fetchLogDetails(component, event,helper);
                }
        console.log('loaded');
        // Set loading to false shortly after init
    setTimeout($A.getCallback(() => {
        component.set("v.isLoading", false);
        console.log('Loading complete');
    }), 200);  // small delay ensures picklists loaded
    },

    handleRemainingQtyChange : function(component, event, helper) {
       try{
        var index = event.getSource().get("v.name"); // if you set name attribute
        var newValue = event.getSource().get("v.value");
        component.set("v.isDisabled", false);
        if(newValue == '' || newValue == undefined){
            return;
        }
    
        console.log("Remaining Quantity changed. Index:", index, " Value:", newValue);
        console.log('handleRemainingQtyChange fetchOrdItemList~>',JSON.stringify(component.get("v.OrdItemList")));
        console.log('handleRemainingQtyChange bom items--'+JSON.stringify(component.get('v.BomItemList')));

        var ordItemList = []; ordItemList = component.get("v.OrdItemList");
        console.log('ordItemList[index].Quantity--'+ordItemList[index].Quantity__c);
        if(newValue > ordItemList[index].Quantity){
            console.log('new valu--'+newValue);
            sforce.one.showToast({
                                    "title": 'error',
                                    "message": 'Cannot add quantity greater than order product quantity',
                                    "type": "error"
                                });
                                component.set("v.isDisabled", true);
                                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                                return;
        }
        var BOMItems = component.get('v.BomItemList');
        console.log('BOMItems==> '+JSON.stringify(BOMItems));
        console.log('ordItemList==> '+JSON.stringify(ordItemList));
        
    var changedRow = ordItemList[index].Remaining_Quantity__c;
    //ordItemList[index].Quantity = changedRow;
    
    //console.log('ordItemList[index].Quantity-- '+ordItemList[index].Quantity);

    // update Remaining Quantity
    //changedRow.Remaining_Quantity__c = newValue;
    console.log('changedRow.Remaining_Quantity__c-> '+changedRow);

    // if Kit, recalc BOM quantities
    console.log('true / false ->'+ordItemList[index].Product2.Is_Kit__c);
    component.set("v.reRenderSOLItable",true);
    console.log('component.get order id--'+component.get('v.orderId'));
    component.set("v.orderId",component.get('v.orderId'));
    component.set("v.OrdItemList", component.get("v.OrdItemList"));
    console.log('final order item list==> '+JSON.stringify(component.get("v.OrdItemList")));

   /* if (ordItemList[index].Product2.Is_Kit__c) {
        console.log('BOMItems.length'+BOMItems.length);
        if (BOMItems && BOMItems.length > 0) {
            for (let i = 0; i < BOMItems.length; i++) {
                let bom = BOMItems[i]; 
                if (bom.BomLM && bom.BomLM.Quantity__c > 0) {  // ensure BomLM is not undefined
                    let bomName = bom.BomLM.Name;
                    console.log('qty-'+bom.BomLM.Quantity__c + 'and chngedrow--'+changedRow);
                    bom.BomLM.Quantity__c = bom.BomLM.Quantity__c * changedRow;
                    console.log("BOM Item: " + bomName + " | Quantity: " + bom.BomLM.Quantity__c);
                } else {
                    console.log("⚠️ BomLM is undefined for this BOM item:", bom);
                }
            }
        }
    }

    // put back into list
    component.set("v.SoliList", BOMItems);
    
    component.set("v.SOId",component.get('v.SOId'));
    console.log('reRenderSOLItable--'+component.get('v.reRenderSOLItable'));
    console.log('component.get order id--'+component.get('v.orderId'));
        console.log('soli list for qty chnge-->'+JSON.stringify(component.get("v.SoliList")));*/

       }catch(e){
        console.log('err -->'+e);
       }
    },
    
    fetchSoliList:function(component,event,helper){
        helper.fetchSoliList(component, event, helper);
    },
    
    fetchOrdItemList:function(component,event,helper){
        helper.fetchOrdItemList(component, event, helper);
    },
    
    fetchPOItemList : function(component,event,helper){
        helper.fetchPOItemList(component,event,helper);
    },
    
    fetchDistributionChannel:function(component,event,helper){
        console.log('fetchDistributionChannel called channel id~>'+component.get("v.channelId"));
        if(component.get("v.channelId") == undefined ||component.get("v.channelId") == '' || component.get("v.channelId") == null) component.set("v.DistributeChannelId",'');    
        else helper.fetchStoreAddress(component,event,helper,component.get("v.channelId")); 
    },
    
 /*   fetchstocksDC:function(component,event,helper){
        try{
            console.log('fetchstocksDC called dc~>'+component.get("v.DistributeChannelId"));
            $A.util.removeClass(component.find('mainSpin'), "slds-hide");
            
            var OrderId;
            if(component.get('v.SOId') != '') 
                OrderId = component.get('v.SOId');
            else if(component.get('v.orderId') != '')
                OrderId = component.get('v.orderId');
                else if(component.get('v.POId') != '')
                    OrderId = component.get('v.POId');
            
            console.log('OrderId',OrderId);
            var action = component.get("c.getupdatedstocksDCs");
            action.setParams({
                "OrdId" : OrderId,
                "orditms": JSON.stringify(component.get("v.OrdItemList")),
                "chnId" : component.get("v.channelId"),
                "DCId": component.get("v.DistributeChannelId"),
                "LogItems" : JSON.stringify(component.get("v.LLIList")),
            });
            action.setCallback(this, function(response){
                if(response.getState() === "SUCCESS"){
                    console.log('response.getReturnValue() or bomlist: ',response.getReturnValue())
                    if(response.getReturnValue() != null){
                        component.set("v.OrdItemList",response.getReturnValue().UpdatedOrdList);
                        component.set("v.BomItemList",response.getReturnValue().UpdatedBomList);
                        component.set("v.LLIList",response.getReturnValue().UpdatedlogList);
                    }
                    
                    component.set("v.allSOLIselected",false);
                    var elem = []; elem=component.find('schId');
                    if(elem){
                        if(elem.length){
                            for(var i in elem){
                                elem[i].set("v.checked",false);
                            }
                        }else elem.set("v.checked",false);
                    }
                    
                    component.set("v.SelectedSoliList",[]);
                    component.set("v.reRenderSOLItable",false);
                    component.set("v.reRenderSOLItable",true);
                    setTimeout($A.getCallback(function(){
                        $A.util.addClass(component.find('mainSpin'), "slds-hide");
                    }),3000);
                    
                    //New code added by Parveez 28/07/23
                    
                    let tempOrderitems = component.get("v.OrdItemList");
                    let tempbom = component.get("v.BomItemList");
                    console.log('tempbom : ',tempbom);
                    console.log('tempOrderitems.length : ',tempOrderitems.length);
                    if(tempOrderitems.length > 0){
                        console.log('in if conditionsssss');
                        for(var k in tempOrderitems){
                             console.log('in for conditionsssss');
                            let totalkitbom = [];
                            let bomwithinventory = [];
                            console.log('tempOrderitems:', JSON.parse(JSON.stringify(tempOrderitems)));
                            console.log('tempOrderitems[' + k + ']:', JSON.parse(JSON.stringify(tempOrderitems[k])));
                            console.log('Product2Id:', tempOrderitems[k].Product2Id);
                            console.log('Product2:', tempOrderitems[k].Product2);
                            if(tempOrderitems[k].Product2Id != undefined && tempOrderitems[k].Product2.Is_Kit__c){
                             console.log('Condition passed - Kit product found:', tempOrderitems[k].Product2Id); 
                                console.log('--- STARTING BOM MATCHING ALGORITHM ---');
                                console.log('Current Order Item (k=' + k + '):', JSON.parse(JSON.stringify(tempOrderitems[k])));
                                console.log('Order Item Product2Id:', tempOrderitems[k].Product2Id);
                                console.log('All Available BOMs:', tempbom);
                                for(var i in tempbom){
                                    console.log('did i enter here ');
                                    console.log('Product2Id:', tempOrderitems[k].Product2Id);
                                    console.log('tempbom[i].Bom.BOM_Product__c:', tempbom[i].BomLM.BOM_Product__c);
                                    if(tempOrderitems[k].Product2Id == tempbom[i].BomLM.BOM_Product__c){
                                        console.log('ok i came here also ');
                                        totalkitbom.push(tempbom[i].Name);
                                        if(tempbom[i].stock > 0){
                                            bomwithinventory.push(tempbom[i].Name);
                                        }  
                                    }
                                }
                                console.log('totalkitbom:',totalkitbom.length);
                                console.log('bomwithinventory:',bomwithinventory.length);
                                if(totalkitbom.length != bomwithinventory.length){
                                    tempOrderitems[k].AllowKit = 'Not-Allowed';
                                }
                                else if(totalkitbom.length == bomwithinventory.length){
                                    tempOrderitems[k].AllowKit = 'Allow';
                                }
                            }
                            
                        }
                        console.log('kitList :',JSON.stringify(tempOrderitems));
                    }
                    
                    //
                }else{
                    setTimeout($A.getCallback(function(){
                        $A.util.addClass(component.find('mainSpin'), "slds-hide");
                    }),3000);
                    var errors = response.getError();
                    console.log("server error in fetchstocksDC : ", errors);
                    component.set("v.exceptionError", errors[0].message);
                    setTimeout( function(){component.set("v.exceptionError", "");}, 5000);
                } 
            });
            if(!$A.util.isEmpty(component.get("v.channelId")) && !$A.util.isUndefinedOrNull(component.get("v.channelId")) && !$A.util.isEmpty(component.get("v.DistributeChannelId")) && !$A.util.isUndefinedOrNull(component.get("v.DistributeChannelId")) && (component.get("v.OrdItemList").length > 0 || component.get("v.LLIList").length > 0)){
                $A.enqueueAction(action);
            }else{
                console.log('not updating stocks');
                component.set("v.allSOLIselected",false);
                var elem = []; elem=component.find('schId');
                console.log('elem ~>'+elem);
                if(elem){
                    if(elem.length){
                        for(var i in elem){
                            elem[i].set("v.checked",false);
                        }
                    }else elem.set("v.checked",false);
                }
                
                component.set("v.SelectedSoliList",[]);
                component.set("v.reRenderSOLItable",false);
                component.set("v.reRenderSOLItable",true);
                setTimeout($A.getCallback(function(){
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }),3000);
                
            }
        }
        catch(e){console.log('Error:',e);}
    },*/
    fetchstocksDC: function(component, event, helper) {
        if (component.get("v.isLoading")) {
            console.log("Skipping handler during loading");
            return;
        }

            try {
                console.log('fetchstocksDC called dc~>' + component.get("v.DistributeChannelId"));
                $A.util.removeClass(component.find('mainSpin'), "slds-hide");
                
                var OrderId;
                if (component.get('v.SOId') != '') 
                    OrderId = component.get('v.SOId');
                else if (component.get('v.orderId') != '')
                    OrderId = component.get('v.orderId');
                else if (component.get('v.POId') != '')
                    OrderId = component.get('v.POId');
                
                var action = component.get("c.getupdatedstocksDCs");
                action.setParams({
                    "OrdId": OrderId,
                    "orditms": JSON.stringify(component.get("v.OrdItemList")),
                    "chnId": component.get("v.channelId"),
                    "DCId": component.get("v.DistributeChannelId"),
                    "LogItems": JSON.stringify(component.get("v.LLIList"))
                });

                action.setCallback(this, function(response) {
                    if (response.getState() === "SUCCESS") {
                        console.log('response.getReturnValue() : ', response.getReturnValue());
                        if (response.getReturnValue() != null) {
                            component.set("v.OrdItemList", response.getReturnValue().UpdatedOrdList);
                            component.set("v.BomItemList", response.getReturnValue().UpdatedBomList);
                            component.set("v.LLIList", response.getReturnValue().UpdatedlogList);
                            
                            let tempOrderitems = component.get("v.OrdItemList");
                            
                            // New: Initialize IsExploded to false for all items (prevents undefined issues)
                            for (var k = 0; k < tempOrderitems.length; k++) {
                                if (tempOrderitems[k].IsExploded === undefined) {
                                    tempOrderitems[k].IsExploded = false;
                                }
                            }
                            
                            var explodedOrderItems = response.getReturnValue().ExplodedOrderItems || {};
                            var hasExplodedItems = false;
                            var explodedIds = [];
                            var explodedNames = [];

                            // Check for exploded items (use for...in safely)
                            for (var oiId in explodedOrderItems) {
                                if (explodedOrderItems.hasOwnProperty(oiId) && explodedOrderItems[oiId]) {
                                    hasExplodedItems = true;
                                    for (var k = 0; k < tempOrderitems.length; k++) {  // Indexed loop for array
                                        if (tempOrderitems[k].Id == oiId) {
                                            explodedNames.push(tempOrderitems[k].Product2.Name);
                                            tempOrderitems[k].IsExploded = true;
                                            explodedIds.push(oiId);
                                            console.log('Exploded item found: ' + oiId);  // Debug
                                            break;
                                        }
                                    }
                                }
                            }
                            component.set("v.OrdItemList", tempOrderitems);
                            component.set("v.hasExplodedItems", hasExplodedItems);
                            console.log('hasExplodedItems set to: ' + hasExplodedItems);  // Debug

                            // Show error if exploded
                            if (hasExplodedItems) {
                                var lang = $A.get("$Locale.language");
                                var message = lang === "fr" 
                                    ? "Vous avez déjà explosé les produits suivants : " + explodedNames.join(', ') + "."
                                    : "You have already exploded the following products: " + explodedNames.join(', ') + ".";
                                component.set("v.explodedError", message);
                                component.set("v.SelectedSoliList", explodedIds);
                                
                                // Optional: Auto-create logistics for exploded items (uncomment if desired)
                                // setTimeout(function() {
                                //     helper.convertToLogistic(component, event, helper);
                                // }, 3000);
                            } else {
                                component.set("v.explodedError", "");
                            }

                            var allSOLIselected = true;
                            for (var i = 0; i < tempOrderitems.length; i++) {
                                // Safe check: IsExploded defaults to false
                                if (!tempOrderitems[i].IsExploded && tempOrderitems[i].Active__c && 
                                    ((tempOrderitems[i].Remaining_Quantity__c <= tempOrderitems[i].Reserved_Quantity__c && 
                                    tempOrderitems[i].Remaining_Quantity__c > 0 && 
                                    tempOrderitems[i].Remaining_Quantity__c <= tempOrderitems[i].Quantity) || 
                                    (tempOrderitems[i].Product2.Is_Kit__c && tempOrderitems[i].AllowKit == 'Allow'))) {
                                    allSOLIselected = allSOLIselected && tempOrderitems[i].checked;
                                }
                            }
                            component.set("v.allSOLIselected", allSOLIselected);
                            
                            // Handle kit items inventory check
                            var bomItems = component.get("v.BomItemList");
                            for (var i = 0; i < tempOrderitems.length; i++) {
                                if (tempOrderitems[i].Product2.Is_Kit__c) {
                                    var hasEnoughStock = true;
                                    for (var j = 0; j < bomItems.length; j++) {
                                        if (bomItems[j].OrderProdId == tempOrderitems[i].Id && 
                                            bomItems[j].stock < bomItems[j].BomLM.Quantity__c) {
                                            hasEnoughStock = false;
                                            break;
                                        }
                                    }
                                    tempOrderitems[i].AllowKit = hasEnoughStock ? 'Allow' : 'Not-Allowed';
                                }
                            }
                            component.set("v.OrdItemList", tempOrderitems);
                            
                            // Refresh the UI
                            component.set("v.reRenderSOLItable", false);
                            component.set("v.reRenderSOLItable", true);
                        }
                    } else {
                        var errors = response.getError();
                        if (errors && errors[0] && errors[0].message) {
                            component.set("v.exceptionError", errors[0].message);
                        }
                    }
                    
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                });

                if (!$A.util.isEmpty(component.get("v.channelId")) && !$A.util.isUndefinedOrNull(component.get("v.channelId")) && component.get("v.DistributeChannelId") && component.get("v.OrdItemList") && component.get("v.OrdItemList").length > 0) {
                    $A.enqueueAction(action);
                } else {
                    console.log('Channel not selected - skipping stock update');
                    //component.set("v.exceptionError", "Please select a Channel before proceeding.");
                    // if (event.getParam("oldValue")) {  
                    //     component.set("v.exceptionError", "Please select a Channel and Distribution Channel.");
                    //     setTimeout(() => component.set("v.exceptionError", ""), 4000);
                    // }
                    let channel = component.get("v.channelId");
                    let dc = component.get("v.DistributeChannelId");
                    console.log('channel ',channel,'dc',dc);
                    // Only show the error if the user actually left something blank
                    if (!channel) {
                        component.set("v.exceptionError", "Please select a Channel");
                        setTimeout(() => component.set("v.exceptionError", ""), 4000);
                    }
                    component.set("v.allSOLIselected", false);
                    var elem = component.find('schId');
                    if (elem) {
                        if (elem.length) {
                            for (var i = 0; i < elem.length; i++) {  // Indexed loop
                                elem[i].set("v.checked", false);
                            }
                        } else {
                            elem.set("v.checked", false);
                        }
                    }
                    component.set("v.SelectedSoliList", []);
                    component.set("v.reRenderSOLItable", false);
                    component.set("v.reRenderSOLItable", true);
                    
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }
                
            } catch (e) {
                console.log('Error in fetchstocksDC:', e);
                component.set("v.exceptionError", e.message);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }
    },
    reloadSoli:function(component,event,helper){
        location.reload();  
    },
    
    backToSoliTab:function(component,event,helper){
        try{
            component.set("v.selectedTab",'soli');
            let selectedItem = []; selectedItem = component.get("v.LLIList");
            console.log('selectedItem : ',selectedItem);
            var OrdItemList=[]; OrdItemList=component.get('v.OrdItemList');
            console.log('OrdItemList : ',OrdItemList);
            var selectedDum = [];
            if(selectedItem.length > 0 && OrdItemList.length > 0){
                console.log('2 here');
                for(var y in OrdItemList){
                    OrdItemList[y].checked = false;
                    for(var x in selectedItem){
                        if(OrdItemList[y].Id == selectedItem[x].Order_Product__c){
                            OrdItemList[y].checked = true;
                            selectedDum.push(OrdItemList[y]);
                            console.log('3 in here');
                            break;
                            
                        } 
                    }
                    
                } 
                component.set("v.OrdItemList",OrdItemList); 
                component.set("v.SelectedSoliList",selectedDum); 
            }
            component.set("v.LLIList",[]); 
            component.set("v.selectedTab",'soli');
        }
        catch(e){console.log(e);}
    },
    
    backToSoli:function(component,event,helper){
        //component.set("v.selectedTab",'soli');
      /*  if(component.get('v.SOId') !=''){
            var RecUrl = "/lightning/r/Sales_Order__c/" + component.get('v.SOId') + "/view";
            window.open(RecUrl,'_parent');
        }else 
       if(component.get('v.orderId') !=''){
            var RecUrl = "/lightning/r/Order/" + component.get('v.orderId') + "/view";
            window.open(RecUrl,'_parent');
        }else if(component.get('v.POId') !=''){
            var RecUrl = "/lightning/r/PO__c/" + component.get('v.POId') + "/view";
            window.open(RecUrl,'_parent');
        }*/ // changes done by bushra 21072025
        window.history.back();
    },
    
    resetSelected : function(component,event,helper){
        console.log('resetSelected called');
        component.set('v.SelectedSoliList',[]);
        component.set('v.allSOLIselected',false);
    },
    
 selectSoli: function(component, event, helper) {     
        var isSelect = event.getSource().get("v.checked");
        var recordId = event.getSource().get("v.value");
        
        var SelectedSoliList = []; SelectedSoliList = component.get('v.SelectedSoliList');
        var SoliList = []; SoliList = component.get("v.SoliList");
        var OrdItemList = []; OrdItemList = component.get('v.OrdItemList');
        var POItemList = []; POItemList = component.get('v.POItemList');
        var BomItems = []; BomItems = component.get('v.BomItemList');
        $A.util.removeClass(component.find("cnvrtLogBtnId"), 'a_disabled'); 
        
        // Block if item is exploded (for OrderItems)
        var explodedItem = null;
        if (OrdItemList.length > 0) {
            explodedItem = OrdItemList.find(function(item) { return item.Id === recordId && item.IsExploded; });
        }
        if (explodedItem) {
            event.getSource().set("v.checked", false); // Uncheck immediately
            var message = "Cannot select exploded product: " + explodedItem.Product2.Name;
            sforce.one.showToast({
                "title": 'Validation Error',
                "message": message,
                "type": "error"
            });
            component.set("v.explodedError", message);
            return; // Exit early - no further processing
        }
        
        try { 
            if (isSelect) {
                if (SoliList.length > 0) {
                    for (var x = 0; x < SoliList.length; x++) {
                        if (SoliList[x].Id == recordId) SelectedSoliList.push(SoliList[x]);
                    }
                } else if (OrdItemList.length > 0) {
                    for (var y = 0; y < OrdItemList.length; y++) {
                        if (OrdItemList[y].Id == recordId) SelectedSoliList.push(OrdItemList[y]);
                    }
                } else if (POItemList.length > 0) {
                    for (var z = 0; z < POItemList.length; z++) {
                        if (POItemList[z].Id == recordId) SelectedSoliList.push(POItemList[z]);
                    }
                }
            } else {
                var SelectedSoliListDum = []; SelectedSoliListDum = SelectedSoliList;
                for (var x = 0; x < SelectedSoliListDum.length; x++) {          
                    if (SelectedSoliListDum[x].Id == recordId) {
                        SelectedSoliListDum.splice(x, 1);
                        break;
                    }               
                }
                SelectedSoliList = SelectedSoliListDum;
            }   
        } catch (ex) { 
            console.log('ex in checkbox ' + ex);  
        }    
        component.set("v.SelectedSoliList", SelectedSoliList);
        console.log('Selected after selectSoli: ' + SelectedSoliList.length);  // Debug
    },
    
selectAllSoli: function(component, event, helper) {
        var isSelect = event.getSource().get("v.checked");
        console.log('isSelect : ', isSelect);
        var elem = []; elem = component.find('schId');
        console.log('elem~>', elem);
        var SelectedSoliList = [];
        var SoliList = []; SoliList = component.get("v.SoliList"); 
        var OrdItemList = []; OrdItemList = component.get('v.OrdItemList');
        var POItemList = []; POItemList = component.get('v.POItemList');
        
        var SelectedSoliListDum = [];
        
        if (SoliList.length > 0) {
            for (var j = 0; j < SoliList.length; j++) { 
                if (isSelect == true) {  
                    if (SoliList[j].Active__c == true) {
                        if (elem && elem.length > j) {  // Safe access
                            elem[j].set("v.checked", true);        
                        }
                        SelectedSoliListDum.push(SoliList[j]); 
                    }          
                }   
                else {
                    if (elem && elem.length > j) {
                        elem[j].set("v.checked", false);        
                    }
                    SelectedSoliListDum = [];
                }
            }
        } else if (OrdItemList.length > 0) {
            for (var j = 0; j < OrdItemList.length; j++) { 
                // Skip exploded items
                if (OrdItemList[j].IsExploded) continue;
                
                if (isSelect == true) {  
                    if ((OrdItemList[j].Active__c === true && 
                         ((OrdItemList[j].Remaining_Quantity__c <= OrdItemList[j].Reserved_Quantity__c && 
                           OrdItemList[j].Remaining_Quantity__c > 0 &&  
                           OrdItemList[j].Remaining_Quantity__c <= OrdItemList[j].Quantity) || 
                          (OrdItemList[j].Product2.Is_Kit__c && OrdItemList[j].AllowKit == 'Allow')))) {  
                        console.log('here222');
                        if (elem && elem.length > j) {
                            elem[j].set("v.checked", true);        
                        }         
                        console.log('here pushed');
                        SelectedSoliListDum.push(OrdItemList[j]); 
                    } else {
                        console.log('here notpushed');
                    }
                }   
                else {
                    if (elem && elem.length > j) {
                        elem[j].set("v.checked", false);        
                    }
                    SelectedSoliListDum = [];
                }
            }
        } else if (POItemList.length > 0) {
            for (var j = 0; j < POItemList.length; j++) { 
                if (isSelect == true) { 
                    if (POItemList[j].Active__c == true) {          
                        if (elem && elem.length > j) {
                            elem[j].set("v.checked", true);        
                        }                                                     
                        SelectedSoliListDum.push(POItemList[j]); 
                    }          
                }   
                else {
                    if (elem && elem.length > j) {
                        elem[j].set("v.checked", false);        
                    }
                    SelectedSoliListDum = [];
                }
            }
        }
        console.log('SelectedSoliListDum ~>' + SelectedSoliListDum.length);
        component.set("v.SelectedSoliList", SelectedSoliListDum); 
        
        if (isSelect && SelectedSoliListDum.length > 0) $A.util.removeClass(component.find("cnvrtLogBtnId"), 'a_disabled');
        else $A.util.addClass(component.find("cnvrtLogBtnId"), 'a_disabled');                               
    },
    
convertToLogistic: function(component, event, helper) {
        try {
            console.log('convertToLogistic called');
            component.set('v.LLIList', []);
            var SelectedSoliList = []; SelectedSoliList = component.get('v.SelectedSoliList');  
            console.log('SelectedSoliList ~>' + SelectedSoliList.length);
            var SoliList = []; SoliList = component.get("v.SoliList"); 
            var OrdItemList = []; OrdItemList = component.get('v.OrdItemList');
            console.log('ordei tem list ++ ' + JSON.stringify(OrdItemList));
            var POItemList = []; POItemList = component.get('v.POItemList');
            
            // Check for exploded in selection and block
            var hasExploded = false;
            var explodedNames = [];
            if (OrdItemList.length > 0 && SelectedSoliList.length > 0) {
                for (var x = 0; x < SelectedSoliList.length; x++) {
                    var explodedItem = OrdItemList.find(function(item) { return item.Id === SelectedSoliList[x].Id && item.IsExploded; });
                    if (explodedItem) {
                        hasExploded = true;
                        explodedNames.push(explodedItem.Product2.Name);
                    }
                }
            }
            if (hasExploded) {
                var message = "Cannot create manual logistic for exploded products: " + explodedNames.join(', ') + ".";
                sforce.one.showToast({
                    "title": 'Validation Error',
                    "message": message,
                    "type": "error"
                });
                component.set("v.explodedError", message);
                return; // Block conversion
            }
            
            if (SelectedSoliList.length > 0) {
                var LLIList = []; LLIList = component.get("v.LLIList");
                var LLIListDum = []; LLIListDum = LLIList;
                for (let x = 0; x < SelectedSoliList.length; x++) {
                    var found = false;
                    for (let y = 0; y < LLIList.length; y++) {
                        if (SoliList.length > 0) {
                            /*if(LLIList[y].Product__c == SelectedSoliList[x].Product__c){ 
                                found = true;
                                break;
                            }*/
                        } else if (OrdItemList.length > 0) {
                            /*if(LLIList[y].Product2Id == SelectedSoliList[x].Product2Id){ 
                                found = true;
                                break;
                            }*/
                        } else if (POItemList.length > 0) {
                            /*if(LLIList[y].Product__c == SelectedSoliList[x].Product__c){ 
                                found = true;
                                break;
                            }*/
                        }
                    }
                    if (!found) { 
                        if (SoliList.length > 0) {
                            console.log('SoliList inhere');
                            var obj = { 
                                Name: SelectedSoliList[x].Name,
                                Product__c: SelectedSoliList[x].Product__c,
                                Quantity__c: SelectedSoliList[x].Quantity__c - SelectedSoliList[x].Logistic_Quantity__c,
                                Price_Product__c: SelectedSoliList[x].Base_Price__c,                  
                                Sales_Order_Line_Item__c: SelectedSoliList[x].Id,
                                Logistic__c: ''
                            };
                            obj.Product__r = {
                                'Id': SelectedSoliList[x].Product__c,
                                'Name': SelectedSoliList[x].Product__r.Name 
                            };
                            
                            LLIListDum.push(obj);
                        } else if (OrdItemList.length > 0) {
                            console.log('OrdItemList inhere');
                            var j = x + 1;
                            var BomItemList = []; BomItemList = component.get("v.BomItemList");
                            if (SelectedSoliList[x].Product2.Is_Kit__c) {
                                console.log('inhere 3, component.get("v.BomItemList"): ' + component.get("v.BomItemList"));
                                for (var jj in BomItemList) {  // jj to avoid conflict
                                    console.log('inhere 2');
                                    if (SelectedSoliList[x].Product2Id == BomItemList[jj].BomLM.BOM_Product__c && BomItemList[jj].OrderProdId == SelectedSoliList[x].Id) {
                                        console.log('inhere 1');
                                        console.log('quanity ====' + OrdItemList[0].Quantity * BomItemList[jj].BomLM.Quantity__c);
                                        var obj = { 
                                            Name: BomItemList[jj].BomLM.BOM_Component__r.Name + '-LogisticLine-' + jj,
                                            Product__c: BomItemList[jj].BomLM.BOM_Component__c,
                                            // Quantity__c: BomItemList[jj].BomLM.Quantity__c * OrdItemList[0].Quantity,
                                            Quantity__c: BomItemList[jj].BomLM.Quantity__c * OrdItemList[0].Remaining_Quantity__c,
                                            Price_Product__c: BomItemList[jj].pbe.UnitPrice,                  
                                            Order_Product__c: SelectedSoliList[x].Id,
                                            Logistic__c: ''
                                        };
                                        obj.Product__r = {
                                            'Id': BomItemList[jj].BomLM.BOM_Component__c,
                                            'Name': BomItemList[jj].BomLM.BOM_Component__r.Name 
                                        };
                                        LLIListDum.push(obj); 
                                    }
                                }
                            } else {
                                var obj = { 
                                    Name: SelectedSoliList[x].Product2.Name + '-LogisticLine-' + j,
                                    Product__c: SelectedSoliList[x].Product2Id,
                                    Quantity__c: SelectedSoliList[x].Remaining_Quantity__c, //SelectedSoliList[x].Quantity-SelectedSoliList[x].Logistic_Quantity__c,
                                    Price_Product__c: SelectedSoliList[x].UnitPrice,                  
                                    Order_Product__c: SelectedSoliList[x].Id,
                                    Logistic__c: ''
                                };
                                //Check it (is it working or not for Standard order)
                                obj.Product__r = {
                                    'Id': SelectedSoliList[x].Product2.Id,
                                    'Name': SelectedSoliList[x].Product2.Name 
                                };
                                LLIListDum.push(obj);
                            }
                        } else if (POItemList.length > 0) {
                            console.log('POItemList inhere');
                            var obj = { 
                                Name: SelectedSoliList[x].Name,
                                Product__c: SelectedSoliList[x].Product__c,
                                Quantity__c: SelectedSoliList[x].Quantity__c - SelectedSoliList[x].Logistic_Quantity__c,
                                Price_Product__c: SelectedSoliList[x].Unit_Price__c,                  
                                Purchase_Line_Items__c: SelectedSoliList[x].Id,
                                Logistic__c: ''
                            };
                            obj.Product__r = {
                                'Id': SelectedSoliList[x].Product__c,
                                'Name': SelectedSoliList[x].Product__r.Name 
                            };
                            LLIListDum.push(obj);
                        }                    
                    }
                }
                console.log('LLIListDum convertToLogistic json~>' + JSON.stringify(LLIListDum));
                component.set("v.LLIList", LLIListDum);
                console.log('LLIList length after build: ' + component.get("v.LLIList").length);  // Debug
                if (component.get("v.LLIList").length > 0) component.set("v.selectedTab", 'log');
            } else {
                sforce.one.showToast({
                    "title": $A.get('$Label.c.warning_UserAvailabilities_New'),
                    "message": $A.get('$Label.c.No_Item_Selected'),
                    "type": "warning"
                });
            }  
            
            var lognum = parseInt(component.get("v.LogisticsExisting.length") + 1);
            if (SoliList.length > 0) {
                var logName = '' + SoliList[0].Sales_Order__r.Name + '-Logistic-' + lognum;
                component.set("v.Logistic.Name", logName);
            } else if (OrdItemList.length > 0) {
                var logName = '' + OrdItemList[0].Order.Name + '-Logistic-' + lognum;
                component.set("v.Logistic.Name", logName);
            } else if (POItemList.length > 0) {
                var logName = '' + POItemList[0].Purchase_Orders__r.Name + '-Logistic-' + lognum;
                component.set("v.Logistic.Name", logName);
            }
        } catch (ex) { 
            console.log('Error in convertToLogistic: ' + ex);  // Debug
        } 
    },
    
  singleConvertToLogistic: function(component, event, helper) {  
    try {
        console.log('singleConvertToLogistic called');
        component.set('v.LLIList', []);
        var index = event.currentTarget.dataset.service;
        var soliListForCom = []; soliListForCom = component.get("v.SoliList");
        var OrderListListForCom = []; OrderListListForCom = component.get("v.OrdItemList");
        var POListForCom = []; POListForCom = component.get("v.POItemList");
        var SoliList = []; SoliList = component.get("v.SoliList"); 
        
        var BomItemList = []; BomItemList = component.get("v.BomItemList");
        var ordItemListDum = [];
        
        var ordItemList = []; ordItemList = component.get("v.OrdItemList");
        
        var POItemList = []; POItemList = component.get("v.POItemList");   
        
        var selectedSoli = [];
        if (SoliList.length > 0) {
            selectedSoli = SoliList[index];	
        } else 
            if (ordItemList.length > 0) {       
                selectedSoli = ordItemList[index];
            }
            else if (POItemList.length > 0) {
                selectedSoli = POItemList[index];
            }
        
        // New: Block if item is exploded
        if (ordItemList.length > 0 && selectedSoli.IsExploded) {
            var message = "Cannot create manual logistic for exploded product: " + selectedSoli.Product2.Name;
            sforce.one.showToast({
                "title": 'Validation Error',
                "message": message,
                "type": "error"
            });
            component.set("v.explodedError", message);
            return; // Block single conversion
        }
        
        var LLIList = component.get('v.LLIList'); //LLIList=[];
        var LLIListMore = []; 
        console.log('selectedSoli json~>' + JSON.stringify(selectedSoli));
        if(soliListForCom.length > 0){
                console.log('soliListForCom inhere');
                var obj = { 
                    Name:selectedSoli.Name,
                    Product__c:selectedSoli.Product__c,
                    Quantity__c:selectedSoli.Quantity__c-selectedSoli.Logistic_Quantity__c,
                    Price_Product__c:selectedSoli.Base_Price__c,                                     
                    Sales_Order_Line_Item__c:selectedSoli.Id,   
                    Logistic__c:'',
                    Company__c:'0018d00000VaxUVAAZ'    
                };
                obj.Product__r={
                    'Id':selectedSoli.Product__c,
                    'Name':selectedSoli.Product__r.Name 
                };
                LLIListMore.push(obj); //Quantity__c
            }
            else if(OrderListListForCom.length > 0){
                console.log('OrderListListForCom inhere');
                if(selectedSoli.Remaining_Quantity__c <= 0 || selectedSoli.Remaining_Quantity__c > selectedSoli.Quantity){
                    component.set("v.exceptionError", $A.get('$Label.c.REMAINING_QUANTITY') +' > 0 && <= '+$A.get('$Label.c.Acc_Pay_Total_Quantity'));
                    setTimeout( function(){component.set("v.exceptionError", "");}, 5000);
                    return;
                }
                console.log('selectedSoli.Product2.Is_Kit__c--'+selectedSoli.Product2.Is_Kit__c);
                if(selectedSoli.Product2.Is_Kit__c){
                    console.log('BOMITEMLIST -- '+JSON.stringify(BomItemList));
                    for(var j in BomItemList){
                        console.log('BomItemList[j].Bom.BOM_Product__c-'+BomItemList[j].BomLM.BOM_Product__c);
                        console.log('22--'+selectedSoli.Product2Id == BomItemList[j].BomLM.BOM_Product__c && BomItemList[j].OrderProdId == selectedSoli.Id);
                        if(selectedSoli.Product2Id == BomItemList[j].BomLM.BOM_Product__c && BomItemList[j].OrderProdId == selectedSoli.Id){
                            var obj = { 
                                Name: BomItemList[j].BomLM.BOM_Component__r.Name+'-LogisticLine-1',
                                Product__c:BomItemList[j].BomLM.BOM_Component__c,
                                Quantity__c:BomItemList[j].BomLM.Quantity__c * OrderListListForCom[0].Quantity,
                                Price_Product__c:BomItemList[j].pbe.UnitPrice,                  
                                Order_Product__c:selectedSoli.Id,
                                Logistic__c:''
                            };
                            obj.Product__r={
                                'Id':BomItemList[j].BomLM.BOM_Component__c,
                                'Name':BomItemList[j].BomLM.BOM_Component__r.Name 
                            };
                            LLIListMore.push(obj); 
                        }
                    }
                }
                else{
                    var obj = { 
                        Name:selectedSoli.Product2.Name+'-LogisticLine-1',
                        Product__c:selectedSoli.Product2Id,
                        Quantity__c:selectedSoli.Remaining_Quantity__c, //selectedSoli.Quantity-selectedSoli.Logistic_Quantity__c,
                        Price_Product__c:selectedSoli.UnitPrice,                  
                        Order_Product__c:selectedSoli.Id,
                        Logistic__c:'',
                        Company__c:'0018d00000VaxUVAAZ'
                    };
                    obj.Product__r={
                        'Id':selectedSoli.Product2.Id,
                        'Name':selectedSoli.Product2.Name 
                    };
                    LLIListMore.push(obj); 
                }
                //Quantity__c
                  
            }
            else if(POListForCom.length > 0){
                    console.log('POListForCom inhere');
                    //var AQuantity=SelectedSoliList[x].Quantity__c-SelectedSoliList[x].Logistic_Quantity__c; SelectedSoliList[x].Reserved_Quantity__c
                    var obj = { 
                        Name:selectedSoli.Name,
                        Product__c:selectedSoli.Product__c,
                        Quantity__c:selectedSoli.Quantity__c-selectedSoli.Logistic_Quantity__c,
                        Price_Product__c:selectedSoli.Unit_Price__c,                  
                        Purchase_Line_Items__c:selectedSoli.Id,
                        Logistic__c:'',
                         Company__c:'0018d00000VaxUVAAZ'
                    };
                    obj.Product__r={
                        'Id':selectedSoli.Product__c,
                        'Name':selectedSoli.Product__r.Name 
                    };
                    LLIListMore.push(obj); //Quantity__c
            }
        
        console.log('LLIListMore inhere pushing to LLIList');
        for (let x = 0; x < LLIListMore.length; x++) LLIList.push(LLIListMore[x]); 
        
        console.log('LLIList singleConvertToLogistic json~>' + JSON.stringify(LLIList));
        component.set("v.LLIList", LLIList);
        if (component.get("v.LLIList").length > 0) component.set("v.selectedTab", 'log');
        
        var lognum = parseInt(component.get("v.LogisticsExisting.length") + 1);
        if (SoliList.length > 0) {
            console.log('logName SoliList inhere');
            var logName = '' + SoliList[0].Sales_Order__r.Name + '-Logistic-' + lognum;
            component.set("v.Logistic.Name", logName);
        } else if (ordItemList.length > 0) {
            console.log('logName ordItemList inhere');
            var logName = '' + ordItemList[0].Order.Name + '-Logistic-' + lognum;
            component.set("v.Logistic.Name", logName);
        } else if (POItemList.length > 0) {
            console.log('logName POItemList inhere');
            var logName = '' + POItemList[0].Purchase_Orders__r.Name + '-Logistic-' + lognum;
            component.set("v.Logistic.Name", logName);
        }
    } catch (ex) {
        console.log('exception ex-' + ex);
    }
},
    
    getLLIDelete:function(component,event,helper){ 
        var deleteconfirm = confirm($A.get('$Label.c.Do_you_want_to_Delete_Item'));
        if(deleteconfirm){
            var LLIList=component.get("v.LLIList");
            //delete LLIList[event.currentTarget.dataset.service];
            console.log('LLIList bfr: ',LLIList);
            var index=event.currentTarget.dataset.service;
            LLIList.splice(index,1);
            //  delete LLIList[index];
            
            component.set("v.LLIList",LLIList);
            console.log('LLIList after: ',LLIList);
            component.set("v.reRenderLogisticTable",false);
            component.set("v.reRenderLogisticTable",true);
            
            // if(LLIList.length==1 || LLIList.length==0)  helper.getLLIDeleteSingle(component, event, helper);  
            if(LLIList.length==0){   
                component.set("v.LLIList",[]); 
                helper.getLLIDeleteSingle(component, event, helper);  
            }   
            
            if(component.get("v.selectedTab")=='log'){     
                component.set("v.selectedTab",'soli');
                component.set("v.selectedTab",'log');
            }
            else if(component.get("v.selectedTab")=='soli'){
                component.set("v.selectedTab",'log');
                component.set("v.selectedTab",'soli');
            }
            
        }
      
    },
    
    addLLI: function(component, event, helper){
        var action = component.get("c.getLLIInstance");     
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {  
                var LLIList=[]; LLIList=component.get("v.LLIList");
                LLIList.push(response.getReturnValue());           
                component.set("v.LLIList",LLIList);
                
            }         
        });
        $A.enqueueAction(action);    
        
    },
    
    createLogistic:function(component,event,helper){
        helper.createLogistic(component,event,helper);
                        console.log('Logistic line item : ',JSON.stringify(component.get("v.LLIList")));

    },

    verifyQuantity:function(component,event,helper){
        
        component.set("v.QuantityErrorMsg",'');  
        
        var Index=event.getSource().get("v.name"); 
        var SoliList =[]; SoliList=component.get("v.SoliList");
        var OrdItemList =[]; OrdItemList=component.get("v.OrdItemList");
        var POItemList =[]; POItemList=component.get("v.POItemList");
        
        var LLIList =[]; LLIList=component.get("v.LLIList"); 
        var lliRecord=LLIList[Index]; 
        var soliRecord; 
        for(var i in SoliList){ 
            if(SoliList[i].Id==lliRecord.Sales_Order_Line_Item__c) soliRecord=SoliList[i];          
        }  
        
        var ordItRecord;
        for(var i in OrdItemList){
            if(OrdItemList[i].Id==lliRecord.Order_Product__c) ordItRecord=OrdItemList[i];
        }
        var POLIRecord;
        for(var i in POItemList){
            if(POItemList[i].Id==lliRecord.Purchase_Line_Items__c) POLIRecord=POItemList[i];
        }
        
        var elems=[]; elems=component.find('loliQuantityIds');
        var elem; if(elems.length>1) elem=elems[Index]; else elem=elems;
        
        var AQuantity;
        if(component.get('v.SOId') != ''){
            AQuantity=soliRecord.Quantity__c-soliRecord.Logistic_Quantity__c; //Reserved_Quantity__c 
        }  
        if(component.get('v.orderId') != ''){
            AQuantity = ordItRecord.Remaining_Quantity__c; //ordItRecord.Quantity-ordItRecord.Logistic_Quantity__c;
        }
        if(component.get('v.POId') != ''){
            AQuantity=POLIRecord.Quantity__c-POLIRecord.Logistic_Quantity__c;
        }
        
        if(lliRecord.Quantity__c>AQuantity){
            elem.set("v.class",'hasError');
            component.set("v.QuantityErrorMsg",$A.get('$Label.c.Given_quantity_is_not_available')); // on stock
            
            sforce.one.showToast({
                "title": $A.get('$Label.c.warning_UserAvailabilities_New'),
                "message": $A.get('$Label.c.Given_quantity_is_not_available'),
                "type": "warning"
            });
            
            
            //helper.showToast('dismissible','', 'Error', 'Given quantity is not available',component); //on stock  
        }      
        
        else if(lliRecord.Quantity__c<=0) {
            component.set("v.QuantityErrorMsg",$A.get('$Label.c.Invalid_Quantity')); 
            sforce.one.showToast({
                "title": $A.get('$Label.c.warning_UserAvailabilities_New'),
                "message": $A.get('$Label.c.Invalid_Quantity'),
                "type": "warning"
            });
            //helper.showToast('dismissible','', 'Error', 'Invalid Quantity',component);  
            elem.set("v.class",'hasError');  
        }else{ 
            elem.set("v.class",''); 
            component.set("v.QuantityErrorMsg",''); 
        }
        
    }, 
    
    showLogisticRecordDetailsPage:function(component,event,helper){ 
        var recordId = event.target.dataset.record;  
        component.set("v.nameUrl",'/'+recordId); 
    },
    
    parentFieldChange : function(component, event, helper) {
        var controllerValue =  component.get("v.Logistic.Shipment_type__c");//component.find("parentField").get("v.value");// We can also use event.getSource().get("v.value")
        var pickListMap = component.get("v.depnedentFieldMap");
        console.log('parentFieldChange controllerValue : '+controllerValue);
        if (controllerValue != '' && controllerValue != null && controllerValue != undefined) {
            //get child picklist value
            
            //component.set("v.Logistic.Shipment_type__c",controllerValue);
            var childValues = pickListMap[controllerValue];
            console.log('parentFieldChange childValues : ',JSON.stringify(childValues));
            var childValueList = [];
            //childValueList.push('');
            for (var i = 0; i < childValues.length; i++) {
                childValueList.push(childValues[i]);
            }
            // set the child list
            component.set("v.listDependingValues", childValueList);
            console.log('parentFieldChange listDependingValues : ',component.get("v.listDependingValues"));
            if(childValues.length > 0){
                component.set("v.bDisabledDependentFld" , false);  
            }else{
                component.set("v.bDisabledDependentFld" , true); 
            }
        } else {
            var list = [];
            component.set("v.listDependingValues", list);
            component.set("v.bDisabledDependentFld" , true);
            console.log('setting Shipment_type__c Shipping_Preferences__c empty here');
            component.set("v.Logistic.Shipment_type__c", '');
            component.set("v.Logistic.Shipping_Preferences__c",'');
        }
        if(component.get("v.listDependingValues").length > 0){
            var listdependingValues = component.get("v.listDependingValues");
            console.log('parentFieldChange listdependingValues~>'+listdependingValues[0]);
            component.set("v.Logistic.Shipping_Preferences__c",listdependingValues[0].value);
        }
        console.log('parentFieldChange v.Logistic.Shipping_Preferences__c~>'+component.get("v.Logistic.Shipping_Preferences__c"));
    },
    
    //Added by Arshad 26 Oct 23
   ReturnparentFieldChange : function(component, event, helper) {
        var controllerValue =  component.get("v.Logistic.Shipment_Type_Return__c");
        var pickListMap = component.get("v.RdepnedentFieldMap");
        console.log('ReturnparentFieldChange called controllerValue : '+controllerValue);
        if (controllerValue != '' && controllerValue != null && controllerValue != undefined) {
            //get child picklist value
            
            //component.set("v.Logistic.Shipment_type__c",controllerValue);
            var childValues = pickListMap[controllerValue];
            console.log('ReturnparentFieldChange childValues : ',JSON.stringify(childValues));
            var childValueList = [];
            //childValueList.push('');
            for (var i = 0; i < childValues.length; i++) {
                childValueList.push(childValues[i]);
            }
            // set the child list
            component.set("v.RlistDependingValues", childValueList);
            console.log('ReturnparentFieldChange RlistDependingValues here: ',component.get("v.RlistDependingValues"));
            if(childValues.length > 0){
                component.set("v.RbDisabledDependentFld" , false);  
            }else{
                component.set("v.RbDisabledDependentFld" , true); 
            }
        } 
        else {
            var list = [];
            component.set("v.RlistDependingValues", list);
            component.set("v.RbDisabledDependentFld" , true);
            console.log('setting Shipping_Preferences_Return__c empty here');
            //component.set("v.Logistic.Shipment_type_Return__c", '');
            component.set("v.Logistic.Shipping_Preferences_Return__c",'');
        }
        if(component.get("v.RlistDependingValues").length > 0){
            var RlistDependingValues = component.get("v.RlistDependingValues");
            console.log('ReturnparentFieldChange RlistDependingValues~>'+RlistDependingValues[0]);
            component.set("v.Logistic.Shipping_Preferences_Return__c",RlistDependingValues[0].value);
        }
        console.log('ReturnparentFieldChange v.Logistic.Shipping_Preferences_Return__c~>'+component.get("v.Logistic.Shipping_Preferences_Return__c"));
    },
    
    closeError :function(component,event,helper){
      //  component.set(exceptionError,'');
      component.set("v.exceptionError", "");
    },
    
   /* closeError :function(component,event,helper){
        component.set(exceptionError,'');
    },*/
    
    updateLogistic : function(component,event,helper){
        console.log('updateLogistic called');
         $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var err = false;
        var LLIList=[]; LLIList=component.get("v.LLIList");
        if(LLIList.length > 0){
            for(var x in LLIList){
                if(LLIList[x].Quantity__c > LLIList[x].Fulfilled_Quantity__c){
                    sforce.one.showToast({
                        "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                        "message": 'Can_not_select_more_that_available_stock',
                        "type": "error"
                    });
                    err =true;
                     $A.util.addClass(component.find('mainSpin'), "slds-hide");
                } 
            }
        }
        if(!err){
            component.set("v.Logistic.Channel__c",component.get("v.channelId"));  
            component.set("v.Logistic.Distribution_Channel__c",component.get("v.DistributeChannelId"));
            var Logistic=component.get("v.Logistic");  
            console.log('Logistic : ',JSON.stringify(Logistic));
            var LogisticJSON=JSON.stringify(Logistic); 
            var LLIList=[]; LLIList=component.get("v.LLIList");
            var LLIListJSON=JSON.stringify(LLIList); 
            var action = component.get("c.getUpdateLogistic");
            action.setParams({
                "LogisticJSON":LogisticJSON,
                "LLIListJSON":LLIListJSON
            });  
            action.setCallback(this, function(response) {
                if (response.getState() === "SUCCESS") {  
                    console.log('getCreateLogistic resp~>',response.getReturnValue());
                    
                    if(response.getReturnValue() != null){
                        if(response.getReturnValue().includes('STRING_TOO_LONG')){
                            sforce.one.showToast({
                                "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                                "message": $A.get('$Label.c.Logistic_name_should_not_exceed_80_characters'),
                                "type": "error"
                            });
                            $A.util.addClass(component.find('mainSpin'), "slds-hide");
                            return;
                        }
                    }                           
                    if(response.getReturnValue() == null){
                        sforce.one.showToast({
                            "title": $A.get('$Label.c.Success'),
                            "message": $A.get('$Label.c.Saved_Successfully'),
                            "type": "Success"
                        });
                        var RecUrl = "/lightning/r/Logistic__c/" + component.get('v.LogId') + "/view";
                        window.open(RecUrl,'_parent'); 
                    }else{
                        sforce.one.showToast({
                            "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                            "message": response.getReturnValue(),
                            "type": "error"
                        });
                        $A.util.addClass(component.find('mainSpin'), "slds-hide");
                        return;
                    } 
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }else{
                    var error1=response.getError();
                    console.log('Error :',error1);
                    component.set('v.exceptionError',error1[0].message);
                    sforce.one.showToast({
                        "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                        "message": error1[0].message,
                        "type": "error"
                    });
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }        
            });
            $A.enqueueAction(action);
        }
    },
    
clearExplodedError: function(component, event, helper) {
    component.set("v.explodedError", "");
},    
})