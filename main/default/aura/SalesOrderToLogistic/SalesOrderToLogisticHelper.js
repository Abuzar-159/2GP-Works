({
    doini: function(comp, event, helper) {
        $A.util.removeClass(comp.find('mainSpin'), "slds-hide");	
        var action = comp.get("c.getInstances");    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (comp.isValid() && state === "SUCCESS") {  
                comp.set("v.Logistic",response.getReturnValue().Logistic); 
                comp.set("v.LogisticLI",response.getReturnValue().LogisticLI);
                comp.set("v.LogisticTypeList",response.getReturnValue().LogisticTypeList);
                comp.set("v.showReadyToShip",response.getReturnValue().showReadyToShip);
                comp.set("v.allowEditName",response.getReturnValue().allowEdit);
                comp.set("v.allowChannelRemove",response.getReturnValue().dontallowChannelRemove );
                comp.set("v.showShipDetails",response.getReturnValue().showShipmentDetails);
                comp.set("v.ShowReturnShipSection",response.getReturnValue().ShowReturnShipSection);
                $A.util.addClass(comp.find('mainSpin'), "slds-hide");
            }else{
                $A.util.addClass(comp.find('mainSpin'), "slds-hide");
                var error1=response.getError();
                console.log('Error :',error1);
                comp.set('v.exceptionError',error1[0].message);
            }         
        });
        $A.enqueueAction(action);  
    },
    
    fetchOrdItemList: function(component,event,helper){
        console.log('fetchOrdItemList called');
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        component.set("v.channelId",'');   
        //component.set("v.DistributeChannelId",''); 
        //component.set("v.Logistic.Account__c",'');   
        var action = component.get("c.getordItemList");    
        action.setParams({
            "orderId":component.get("v.orderId")          
        }); // "DistributeChannelId":component.get("v.DistributeChannelId") 
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                component.set("v.LLIList",[]); 
                console.log('ordlist from fetchOrdItemList~>',response.getReturnValue());
               
                let ordList = response.getReturnValue().OrdList;    
                for(var x in ordList){
                   if(ordList[x].checked == undefined) ordList[x].checked = false;
                }
                component.set("v.OrdItemList",ordList);
                console.log('v.OrdItemList from fetchOrdItemList~>',component.get("v.OrdItemList"));
                component.set("v.BomItemList",response.getReturnValue().BOMS);
                console.log('fetch ord item--'+component.get('v.BomItemList'));
                console.log('fetch ord item--'+JSON.stringify(component.get('v.BomItemList')));
                
                //sorting arshad
                if(response.getReturnValue().OrdList.length > 0){
                    var sortAsc = false,
                        table = component.get("v.OrdItemList");
                    table.sort(function (a, b) {
                        if (($A.util.isEmpty(a.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(a.Reserved_Quantity__c)) && ($A.util.isEmpty(b.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(b.Reserved_Quantity__c))) return 0;
                        if (sortAsc) {
                            if ($A.util.isEmpty(b.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(b.Reserved_Quantity__c)) return 1;
                            if ($A.util.isEmpty(a.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(a.Reserved_Quantity__c)) return -1;
                        } else {
                            if ($A.util.isEmpty(b.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(b.Reserved_Quantity__c)) return -1;
                            if ($A.util.isEmpty(a.Reserved_Quantity__c) || $A.util.isUndefinedOrNull(a.Reserved_Quantity__c)) return 1;
                        }
                        
                        var t1 = a.Reserved_Quantity__c == b.Reserved_Quantity__c,
                            t2 = a.Reserved_Quantity__c > b.Reserved_Quantity__c;
                        return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? -1 : 1);
                    });
                }
                
                let order = response.getReturnValue().Ord;
                 
                console.log('order Ship 1 : ',JSON.stringify(order));
                if(!$A.util.isEmpty(response.getReturnValue().Ord.AccountId) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.AccountId)) component.set("v.Logistic.Account__c",response.getReturnValue().Ord.AccountId); 
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Contact__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Contact__c)) component.set("v.Logistic.Contact__c",response.getReturnValue().Ord.Contact__c); 
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Ship_To_Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Ship_To_Address__c)) component.set("v.Logistic.To_Address__c",response.getReturnValue().Ord.Ship_To_Address__c); 
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Channel__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Channel__c)) component.set("v.channelId",response.getReturnValue().Ord.Channel__c); 
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Company__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Company__c)) {component.set("v.companyId",response.getReturnValue().Ord.Company__c);  component.set("v.Logistic.Company__c",response.getReturnValue().Ord.Company__c);}//add by zain 
                console.log('component.get(comaony id)'+component.get("v.companyId"));
                if(!$A.util.isEmpty(response.getReturnValue().DistributeChannelId) && !$A.util.isUndefinedOrNull(response.getReturnValue().DistributeChannelId) && (component.get("v.DistributeChannelId") == null || component.get("v.DistributeChannelId") == undefined || component.get("v.DistributeChannelId") == '')) component.set("v.DistributeChannelId",response.getReturnValue().DistributeChannelId);
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Bill_To_Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Bill_To_Address__c))  component.set("v.Logistic.Billing_Address__c",response.getReturnValue().Ord.Bill_To_Address__c); 
                //added by shaguftha on 02_07_24
                if(!$A.util.isEmpty(response.getReturnValue().Ord.Ship_From_Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Ship_From_Address__c))  component.set("v.Logistic.From_Address__c",response.getReturnValue().Ord.Ship_From_Address__c); 
                if(!$A.util.isEmpty(response.getReturnValue().fromContact) && !$A.util.isUndefinedOrNull(response.getReturnValue().fromContact)) component.set("v.Logistic.From_Contact__c",response.getReturnValue().fromContact);
                
                console.log('Ord Shipment_Type__c 1 : ',order.Shipment_Type__c);
                component.set("v.Logistic.Shipment_type__c",response.getReturnValue().Ord.Shipment_Type__c);
                component.set("v.Logistic.Special_Instructions__c",response.getReturnValue().Ord.Description);
                console.log('log Shipment_Type__c 2 : ',component.get("v.Logistic.Shipment_type__c"));
				//component.set("v.Logistic.Shipping_Preferences__c",response.getReturnValue().Ord.Shipment_Preference_Speed__c); 
               
                //Added by Arshad 26 Oct 2023
                if(response.getReturnValue().ShowReturnShipSection){
                	
                    console.log('Shipment_type_Return__c here1~>'+component.get("v.Logistic.Shipment_type_Return__c"));
                    
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Shipment_type_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Shipment_type_Return__c)){
                        component.set("v.Logistic.Shipment_type_Return__c",response.getReturnValue().Ord.Shipment_type_Return__c);
                        console.log('ord Shipment_type_Return__c 2 : ',component.get("v.Logistic.Shipment_type_Return__c"));
                    }
                    
                    console.log('Shipment_type_Return__c here2~>'+component.get("v.Logistic.Shipment_type_Return__c"));
                    
                    if($A.util.isEmpty(component.get("v.Logistic.Shipment_type_Return__c")) || $A.util.isUndefinedOrNull(component.get("v.Logistic.Shipment_type_Return__c"))){
                        var RlistControllingValues = component.get("v.RlistControllingValues");
                        console.log('RlistControllingValues~>',RlistControllingValues);
                        if(RlistControllingValues != undefined && RlistControllingValues != null){
                            if(RlistControllingValues.length > 0){
                                component.set("v.Logistic.Shipment_type_Return__c",RlistControllingValues[0]);
                                console.log('Shipment_type_Return__c here3~>'+component.get("v.Logistic.Shipment_type_Return__c"));
                            }
                        }
                    }
                    
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Bill_To_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Bill_To_Return__c)){
                        component.set("v.Logistic.Bill_To_Return__c",response.getReturnValue().Ord.Bill_To_Return__c); 
                    }
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Billing_Account_Number_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Billing_Account_Number_Return__c)){
                        component.set("v.Logistic.Billing_Account_Number_Return__c",response.getReturnValue().Ord.Billing_Account_Number_Return__c); 
                    }
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Billing_Address_Return__c ) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Billing_Address_Return__c)){
                        component.set("v.Logistic.Billing_Address_Return__c",response.getReturnValue().Ord.Billing_Address_Return__c); 
                    }
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Billing_Contact_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Billing_Contact_Return__c)){
                        component.set("v.Logistic.Billing_Contact_Return__c",response.getReturnValue().Ord.Billing_Contact_Return__c); 
                    }
                    if(!$A.util.isEmpty(response.getReturnValue().Ord.Shipment_type_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Shipment_type_Return__c)){
                        if(!$A.util.isEmpty(response.getReturnValue().Ord.Shipping_Preferences_Return__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().Ord.Shipping_Preferences_Return__c)){
                            component.set("v.Logistic.Shipping_Preferences_Return__c",response.getReturnValue().Ord.Shipping_Preferences_Return__c); 
                        }
                    }
                }
                
                
                component.set("v.isReadyToPickPack",response.getReturnValue().isReadyToPickPack);
                
                
                component.set("v.showSDBool",false);
                component.set("v.showSDBool",true);                                           
                if(component.get("v.selectedTab")=='log'){     
                    component.set("v.selectedTab",'soli');
                    component.set("v.selectedTab",'log');
                }
                else if(component.get("v.selectedTab")=='soli'){
                    component.set("v.selectedTab",'log');
                    component.set("v.selectedTab",'soli');                                                  
                }     
                setTimeout($A.getCallback(function(){
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }),3000);
                
                this.getLogisticExisting(component, event, helper);
            }else{
                var error1=response.getError();
                console.log('Error :',error1);
                component.set('v.exceptionError',error1[0].message);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }
            
        });
        $A.enqueueAction(action);          
    },
    
    fetchSoliList:function(component, event, helper){ 
        console.log('fetchSoliList called');
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        component.reset=true;
        component.set("v.channelId",'');   component.set("v.DistributeChannelId",''); component.set("v.Logistic.Account__c",'');   
        var action = component.get("c.getSoliList");    
        action.setParams({
            "SOId":component.get("v.SOId")          
        }); // "DistributeChannelId":component.get("v.DistributeChannelId") 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.LLIList",[]); 
                console.log('SoliList : ',response.getReturnValue());
                // if(response.getReturnValue()!=null){                                             
                component.set("v.SoliList",response.getReturnValue().SoliList);
                if(!$A.util.isEmpty(response.getReturnValue().SO.Account__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().SO.Account__c)) component.set("v.Logistic.Account__c",response.getReturnValue().SO.Account__c); 
                if(!$A.util.isEmpty(response.getReturnValue().SO.Contact__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().SO.Contact__c)) component.set("v.Logistic.Contact__c",response.getReturnValue().SO.Contact__c); 
                if(!$A.util.isEmpty(response.getReturnValue().SO.Ship_To_Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().SO.Ship_To_Address__c)) component.set("v.Logistic.To_Address__c",response.getReturnValue().SO.Ship_To_Address__c); 
                if(!$A.util.isEmpty(response.getReturnValue().SO.Channel__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().SO.Channel__c)) component.set("v.channelId",response.getReturnValue().SO.Channel__c); 
                if(!$A.util.isEmpty(response.getReturnValue().DistributeChannelId) && !$A.util.isUndefinedOrNull(response.getReturnValue().DistributeChannelId)) component.set("v.DistributeChannelId",response.getReturnValue().DistributeChannelId);
                
                //added by shaguftha on 02_07_24
                if(!$A.util.isEmpty(response.getReturnValue().SO.Ship_From_Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().SO.Ship_From_Address__c))  component.set("v.Logistic.From_Address__c",response.getReturnValue().SO.Ship_From_Address__c); 
                if(!$A.util.isEmpty(response.getReturnValue().fromContact) && !$A.util.isUndefinedOrNull(response.getReturnValue().fromContact)) component.set("v.Logistic.From_Contact__c",response.getReturnValue().fromContact);
                
                  component.set("v.isReadyToPickPack",response.getReturnValue().isReadyToPickPack);
                
                component.set("v.showSDBool",false);
                component.set("v.showSDBool",true);                                           
                if(component.get("v.selectedTab")=='log'){                                              
                    component.set("v.selectedTab",'soli');
                    component.set("v.selectedTab",'log');
                }
                else if(component.get("v.selectedTab")=='soli'){
                    component.set("v.selectedTab",'log');
                    component.set("v.selectedTab",'soli');                                                  
                } 
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                this.getLogisticExisting(component, event, helper);
                
            }else{
                var error1=response.getError();
                console.log('Error :',error1);
                component.set('v.exceptionError',error1[0].message);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }        
        });
        $A.enqueueAction(action);  
        
    },
    
    fetchPOItemList : function(component,event,helper){
        console.log('fetchPOItemList called');
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        component.set("v.channelId",'');   component.set("v.DistributeChannelId",''); component.set("v.Logistic.Account__c",'');   
        var action=component.get("c.getPOItemList");
        action.setParams({
            "POId":component.get("v.POId")
        });
        action.setCallback(this, function(response){
            if(response.getState()=="SUCCESS"){
                component.set("v.LLIList",[]); 
                
                component.set("v.POItemList",response.getReturnValue().POList);
                if(!$A.util.isEmpty(response.getReturnValue().PO.Vendor__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Vendor__c)) component.set("v.Logistic.Account__c",response.getReturnValue().PO.Vendor__c); 
                if(!$A.util.isEmpty(response.getReturnValue().PO.Shipment_Type__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Shipment_Type__c)) component.set("v.Logistic.Shipment_Type__c",response.getReturnValue().PO.Shipment_Type__c); 
                //if(!$A.util.isEmpty(response.getReturnValue().PO.Shipment_Preference_Speed__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Shipment_Preference_Speed__c)) component.set("v.Logistic.Shipping_Preferences__c",response.getReturnValue().PO.Shipment_Preference_Speed__c); 
                if(!$A.util.isEmpty(response.getReturnValue().PO.Vendor_Contact__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Vendor_Contact__c)) component.set("v.Logistic.Contact__c",response.getReturnValue().PO.Vendor_Contact__c); 
                if(!$A.util.isEmpty(response.getReturnValue().PO.Channel__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Channel__c)) component.set("v.channelId",response.getReturnValue().PO.Channel__c); 
                if(!$A.util.isEmpty(response.getReturnValue().PO.Distribution_Channel__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Distribution_Channel__c)) component.set("v.DistributeChannelId",response.getReturnValue().PO.Distribution_Channel__c);
                if(!$A.util.isEmpty(response.getReturnValue().PO.Company__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Company__c))  component.set("v.Logistic.Company__c",response.getReturnValue().PO.Company__c);
                
                 //added by shaguftha on 02_07_24
                if(!$A.util.isEmpty(response.getReturnValue().PO.Distribution_Channel__r.Site__r.Primary_Contact__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Distribution_Channel__r.Site__r.Primary_Contact__c))  component.set("v.Logistic.From_Contact__c",response.getReturnValue().PO.Distribution_Channel__r.Site__r.Primary_Contact__c); 
                if(!$A.util.isEmpty(response.getReturnValue().PO.Distribution_Channel__r.Site__r.Address__c) && !$A.util.isUndefinedOrNull(response.getReturnValue().PO.Distribution_Channel__r.Site__r.Address__c)) component.set("v.Logistic.From_Address__c",response.getReturnValue().PO.Distribution_Channel__r.Site__r.Address__c);
                
                component.set("v.isReadyToPickPack",false);
                
                component.set("v.showSDBool",false);
                component.set("v.showSDBool",true);                                           
                if(component.get("v.selectedTab")=='log'){     
                    component.set("v.selectedTab",'soli');
                    component.set("v.selectedTab",'log');
                }
                else if(component.get("v.selectedTab")=='soli'){
                    component.set("v.selectedTab",'log');
                    component.set("v.selectedTab",'soli');                                                  
                }              
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                this.getLogisticExisting(component, event, helper);
                
            }else{
                var error1=response.getError();
                console.log('Error fetchPOItemList:',error1);
                component.set('v.exceptionError',error1[0].message);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action); 
    },
    
    fetchStoreAddress : function(component, event, helper, channelId) {
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        var action = component.get("c.getStoreAddress");    
        action.setParams({
            "chanId":channelId           
        });   
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") { 
                if(response.getReturnValue()!=null){
                    console.log('setting dc from fetchStoreAddress');
                    component.set("v.DistributeChannelId",response.getReturnValue()); 
                    component.set("v.showSDBool",false); 
                    component.set("v.showSDBool",true);
                }  
                setTimeout($A.getCallback(function(){
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }),3000);
            }else{
                setTimeout($A.getCallback(function(){
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }),3000);
                var error1=response.getError();
                console.log('Error fetchStoreAddress:',error1);
                component.set('v.exceptionError',error1[0].message);
            }          
        });
        $A.enqueueAction(action);        
    },
    
    validateMandatoryFieldsParent: function(component,event, helper) {
        var Logistic=component.get("v.Logistic");
        if(component.get("v.POId") != ''){
            if(this.trim(Logistic.Name)==false || this.trim(Logistic.Account__c)==false
               || this.trim(component.get("v.channelId"))==false || this.trim(component.get("v.DistributeChannelId"))==false){           
                // this.showToast('dismissible','', 'Error', 'All * Fields are mandatory',component);  
                return false;
            }else return true;
        }else{
            if(this.trim(Logistic.Name)==false || this.trim(Logistic.Account__c)==false || this.trim(Logistic.To_Address__c)==false
               || this.trim(component.get("v.channelId"))==false || this.trim(component.get("v.DistributeChannelId"))==false){           
                // this.showToast('dismissible','', 'Error', 'All * Fields are mandatory',component);  
                return false;
            }else return true;
        }
    },
    
    validateMandatoryFieldsChild:function(component,event, helper) {
        var LLIList=component.get('v.LLIList');
        var checkBool=false;  
        for(var i in LLIList){ 
            if(this.trim(LLIList[i].Name)==false || this.trim(LLIList[i].Product__c)==false || this.trim(LLIList[i].Quantity__c)==false){                 
                checkBool=false; return false;  //break;
            }else checkBool=true; //return true; 
        }
        return checkBool; 
    },
    
    createLogistic : function(component, event, helper) {   
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        var validateMFBoolParent=this.validateMandatoryFieldsParent(component, event, helper);
        var validateMFBoolChild=this.validateMandatoryFieldsChild(component, event, helper);  
        var SoliList =[]; SoliList=component.get("v.SoliList"); 
        var OrdItemList=[]; OrdItemList=component.get('v.OrdItemList');
        var POItemList=[]; POItemList=component.get('v.POItemList');
        
        if(validateMFBoolParent == true && validateMFBoolChild == true){ 
            if(component.get("v.QuantityErrorMsg") == ''){     
                if(SoliList.length > 0) component.set("v.Logistic.Sales_Order__c",component.get("v.SOId")); 
                else if(OrdItemList.length > 0) component.set("v.Logistic.Order_S__c",component.get("v.orderId"));
                    else if(POItemList.length > 0) component.set("v.Logistic.Purchase_Order__c",component.get("v.POId"));
                component.set("v.Logistic.Channel__c",component.get("v.channelId"));  
                component.set("v.Logistic.Distribution_Channel__c",component.get("v.DistributeChannelId"));
                component.set("v.Logistic.Active__c",true);
                if(component.get("v.POId") != '') component.set("v.Logistic.Type__c",'Inbound');
                else component.set("v.Logistic.Type__c",'Outbound');
                
                var action = component.get("c.getCreateLogistics");
                var Logistic=component.get("v.Logistic");  
                console.log('Logistic : ',JSON.stringify(Logistic));
                var LogisticJSON=JSON.stringify(Logistic);   
                var LLIList=[]; LLIList=component.get("v.LLIList");
                var LLIListJSON=JSON.stringify(LLIList); 
                var OrderLIneItemsJSON = JSON.stringify(component.get("v.OrdItemList"));
                var bomwrap =[]; bomwrap = component.get("v.BomItemList");
                var bomlist =[];
                for(var i in bomwrap){
                    bomlist[i] = bomwrap[i].Bom;
                }
                var BomItemsJSON =  JSON.stringify(bomlist);

                console.log('abu creating logistics');
                console.log('LogisticJSON = ', LogisticJSON);
                console.log('LLIListJSON = ', LLIListJSON);
                console.log('OrderLIneItemsJSON = ', OrderLIneItemsJSON);
                console.log('BomItemsJSON = ', BomItemsJSON);
                
                action.setParams({
                    "LogisticJSON":LogisticJSON,
                    "LLIListJSON":LLIListJSON,
                    "OrderLIneItems":OrderLIneItemsJSON,
                    "BomItems":BomItemsJSON,
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
                        
                        //if(response.getReturnValue()==null){  
                        //this.showToast('dismissible','', 'success', 'Saved Successfully',component);  
                        
                        /*var navEvt = $A.get("e.force:navigateToSObject");
                        if(navEvt != undefined){
                            navEvt.setParams({
                                "isredirect": true,
                                "recordId": response.getReturnValue(),
                                "slideDevName": "detail"
                            }); 
                            navEvt.fire(); //response.getReturnValue().Id
                        }else {*/
                        
                        if(response.getReturnValue() == null){
                            sforce.one.showToast({
                                "title": $A.get('$Label.c.Success'),
                                "message": $A.get('$Label.c.Saved_Successfully'),
                                "type": "Success"
                            });
                            if(component.get('v.orderId') !=''){
                                console.log('orderId here1');
                                try{
                                    let allloglines = component.get('v.OrdItemList');
                                    var returntologcreation = false;
                                    
                                    //Changed below by Arshad
                                    for(var x in allloglines){
                                        console.log('allloglines : ',JSON.stringify(allloglines[x]));
                                        var remainigqty = allloglines[x].Quantity - allloglines[x].Logistic_Quantity__c;
                                        console.log('remainigqty 1: ',remainigqty);
                                        remainigqty = remainigqty - allloglines[x].Remaining_Quantity__c;
                                        console.log('remainigqty 2: ',remainigqty);
                                        console.log('allloglines[x].Logistic_Quantity__c : ',allloglines[x].Logistic_Quantity__c); 
                                        if(remainigqty > 0){ //|| allloglines[x].Logistic_Quantity__c == 0
                                            returntologcreation = true; 
                                            break;
                                        }
                                    } 
                                    
                                    //added below arshad - go back to log creation screen/ stay in same url/ refresh page if partially logistic created
                                    console.log('returntologcreation : ',returntologcreation);
                                    if(returntologcreation){  //just added ! by khaleeq to go in the order page
                                        console.log('arshad refreshing orditems here and..');
                                        setTimeout($A.getCallback(function(){
                                            console.log('... here it isss !!!'); 
                                            $A.createComponent("c:SalesOrderToLogistic",{ 
                                                "orderId":component.get('v.orderId'),
                                                "DistributeChannelId" :component.get('v.DistributeChannelId'), 
                                            },function(newCmp, status, errorMessage){
                                                if (status === "SUCCESS") {
                                                    var body = component.find("body");
                                                    body.set("v.body", newCmp);
                                                }   
                                            });  
                                        }),9000); 
                                    } else{
                                        console.log('arshad inhere');
                                        var RecUrl = "/lightning/r/Order/" + component.get('v.orderId') + "/view";
                                        window.open(RecUrl,'_parent'); 
                                    }
                                }catch(e){
                                    console.log('arshad err occured after saving logistic and refreshing~>'+e);
                                }
                            }
                            else if(component.get('v.SOId') !=''){
                                var RecUrl = "/lightning/r/Sales_Order__c/" + component.get('v.SOId') + "/view";
                                window.open(RecUrl,'_parent');
                            }
                            else if(component.get('v.orderId') !=''){
                                var RecUrl = "/lightning/r/Order/" + component.get('v.orderId') + "/view";
                                window.open(RecUrl,'_parent');
                            }
                            else if(component.get('v.POId') !=''){
                                var RecUrl = "/lightning/r/PO__c/" + component.get('v.POId') + "/view";
                                window.open(RecUrl,'_parent');
                            }
                            else{
                                location.reload();  
                            }
                        }else{
                            sforce.one.showToast({
                                "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                                "message": response.getReturnValue(),
                                "type": "error"
                            });
                            $A.util.addClass(component.find('mainSpin'), "slds-hide");
                            return;
                        } 
                        setTimeout($A.getCallback(function(){
                            $A.util.addClass(component.find('mainSpin'), "slds-hide");
                        }),9000);
                    }else{
                        //this.showToast('dismissible','', 'Error', 'System.LimitException: c:Too many SOQL queries: 101',component); 
                        
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
            } else{
                if(component.get("v.QuantityErrorMsg") ==$A.get('$Label.c.Invalid_Quantity')){
                    sforce.one.showToast({
                        "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                        "message": $A.get('$Label.c.Invalid_Quantity'),
                        "type": "error"
                    });
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                    return;
                }
                if(component.get('v.SOId') != '' || component.get('v.orderId') != ''){
                    sforce.one.showToast({
                        "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                        "message": $A.get('$Label.c.Given_quantity_is_not_available_on_stock'),
                        "type": "error"
                    });
                }
                if(component.get('v.POId') != ''){
                    sforce.one.showToast({
                        "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                        "message": $A.get('$Label.c.Given_quantity_is_not_available'),
                        "type": "error"
                    });
                }
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                //this.showToast('dismissible','', 'Error', 'Given quantity is not available on stock',component); 
            }     
        }else{
            var LLIList=[]; LLIList=component.get('v.LLIList');  
            if(LLIList!=''){
                sforce.one.showToast({
                    "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                    "message": $A.get('$Label.c.All_fields_are_mandatory'),
                    "type": "error"
                });
                //this.showToast('dismissible','', 'Error', 'All * fields are mandatory',component); 
            }  
            else{
                sforce.one.showToast({
                    "title": $A.get('$Label.c.Error_UsersShiftMatch'),
                    "message": $A.get('$Label.c.Must_have_logistic_line_item'),
                    "type": "error"
                });
                //this.showToast('dismissible','', 'Error', 'Must have logistic line item',component); 
            } 
            $A.util.addClass(component.find('mainSpin'), "slds-hide");
        }      
    },
    
    handleErrors : function(component,errors) {
        // Configure error toast
        let toastParams = {
            title: $A.get('$Label.c.Error_UsersShiftMatch'),
            message: $A.get('$Label.c.Unknown_error'), // Default error message
            type: "error"
        };
        // Pass the error message if any
        if (errors && Array.isArray(errors) && errors.length > 0) {
            toastParams.message = errors[0].message;
        }
        let msg = component.get('v.message');
        msg['Title'] = 'Error';
        msg['Severity']='error';
        msg['Text'] = toastParams.message;
        component.set('v.message',msg);
        // Fire error toast
        // let toastEvent = $A.get("e.force:showToast");
        // toastEvent.setParams(toastParams);
        //toastEvent.fire();
    },
    
    showToast : function(modeType,title, type, message,component) {	
        var toastEvent = $A.get("e.force:showToast");
        if(toastEvent != undefined){
            toastEvent.setParams({
                "mode":modeType,
                "type": type,
                "message": message
            });
            toastEvent.fire();
        }else{
            let msg = component.get('v.message');
            msg['Title'] = title;
            msg['Severity']=type;
            msg['Text'] = message;
            component.set('v.message',msg);
        }
    },
    
    trim: function(value){  
        if(value !=undefined) return ((value.toString()).trim() !=''?true:false);
        else return false;
    },
    
    getLLIDeleteSingle:function(comp, event, helper){
        var action=comp.get("c.getLogisticInstance");    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (comp.isValid() && state === "SUCCESS") { 
                var LLIList=[];
                LLIList.push(response.getReturnValue());
                comp.set("v.LLIList",LLIList); 
                comp.set("v.LLIList",[]); 
            }else{
                var error1=response.getError();
                console.log('Error :',error1);
                comp.set('v.exceptionError',error1[0].message);
            }          
        });
        $A.enqueueAction(action);
        
    },
    
    getLogisticExisting:function(comp, event, helper){ //$A.util.removeClass(comp.find("cnvrtLogBtnId"),'a_disabled');  
        var action=comp.get("c.getLogisticExisting"); 
        action.setParams({
            "SOId":comp.get("v.SOId"),
            "OrderId":comp.get("v.orderId"),
            "POId":comp.get("v.POId")
        });   
        action.setCallback(this, function(response) {
            var state = response.getState(); 
            if (comp.isValid() && state === "SUCCESS") { 
                comp.set("v.LogisticsExisting",response.getReturnValue()); 
                this.getLLIDeleteSingle(comp, event, helper);
            }else{
                var error1=response.getError();
                console.log('Error :',error1);
                comp.set('v.exceptionError',error1[0].message);
            }          
        });
        $A.enqueueAction(action);
        
    },
      
    getDependentPicklists : function(component, event, helper) {
        console.log('getDependentPicklists called');
        var action = component.get("c.getDependentPicklist");
        action.setParams({
            ObjectName : component.get("v.objDetail"),
            parentField : component.get("v.controllingFieldAPI"),
            childField : component.get("v.dependingFieldAPI")
        });
        
        action.setCallback(this, function(response){
            var status = response.getState();
            console.log('status : ',status);
            if(status === "SUCCESS"){
                var pickListResponse = response.getReturnValue();
                console.log('pickListResponse : ',response.getReturnValue());
                //save response 
                component.set("v.depnedentFieldMap",pickListResponse.pickListMaps);
                
                // create a empty array for store parent picklist values 
                var parentkeys = []; // for store all map keys 
                var parentField = []; // for store parent picklist value to set on lightning:select. 
                
                // Iterate over map and store the key
                for (var pickKey in pickListResponse.pickListMaps) {
                    //console.log('pickKey~>',pickKey);
                    parentkeys.push(pickKey);
                }
                
                for (var i = 0; i < parentkeys.length; i++) {
                    //console.log('parentkeys~>',parentkeys[i]);
                    parentField.push(parentkeys[i]);
                }  
                
                console.log('parentField~>',parentField);
                
                // set the parent picklist
                component.set("v.listControllingValues", parentField);
                console.log('listControllingValues : ',component.get("v.listControllingValues"));
                console.log('setting Shipment_type__c Shipping_Preferences__c empty here1');
                component.set("v.Logistic.Shipment_type__c", '');
                component.set("v.Logistic.Shipping_Preferences__c",'');
                console.log('log Ship 1 : ',component.get("v.Logistic.Shipment_type__c"));
                
            }
            else{
                console.log('err : ',response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    
    getReturnDependentPicklists : function(component, event, helper) {
        console.log('getReturnDependentPicklists called');
        var action = component.get("c.getDependentPicklist");
        action.setParams({
            ObjectName : component.get("v.objDetail"),
            parentField : component.get("v.RcontrollingFieldAPI"),
            childField : component.get("v.RdependingFieldAPI")
        });
        
        action.setCallback(this, function(response){
            var status = response.getState();
            console.log('return status : ',status);
            if(status === "SUCCESS"){
                var pickListResponse = response.getReturnValue();
                console.log('return pickListResponse : ',response.getReturnValue());
                //save response 
                component.set("v.RdepnedentFieldMap",pickListResponse.pickListMaps);
                
                // create a empty array for store parent picklist values 
                var parentkeys = []; // for store all map keys 
                var parentField = []; // for store parent picklist value to set on lightning:select. 
                
                // Iterate over map and store the key
                for (var pickKey in pickListResponse.pickListMaps) {
                    //console.log('pickKey~>',pickKey);
                    parentkeys.push(pickKey);
                }
                
                for (var i = 0; i < parentkeys.length; i++) {
                    //console.log('parentkeys~>',parentkeys[i]);
                    parentField.push(parentkeys[i]);
                }  
                
                console.log('return parentField~>',JSON.stringify(parentField));
                
                // set the parent picklist - return //arshad
                component.set("v.RlistControllingValues", parentField);
                console.log('RlistControllingValues~> ',JSON.stringify(component.get("v.RlistControllingValues")));
                console.log('setting Shipment_type_Return__c Shipping_Preferences_Return__c empty here1');
                component.set("v.Logistic.Shipping_Preferences_Return__c",'');
                component.set("v.Logistic.Shipment_type_Return__c", ''); 
                console.log('Shipment_type_Return__c here0~> ',component.get("v.Logistic.Shipment_type_Return__c"));
            }
            else{
                console.log('RT err : ',response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
    
    fetchLogDetails: function(component,event,helper){
        console.log('fetchLogDetails called');
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");	
        var action=component.get("c.getLogisticAndItems");
        action.setParams({
            "LogisticId": component.get('v.LogId')
        });
        action.setCallback(this, function(response){
            if(response.getState() == "SUCCESS"){
                var obj = response.getReturnValue(); 
                console.log('fetchLogDetails resp~>',obj);
                component.set("v.LLIList",obj.logItems); 
                component.set("v.Logistic",obj.logistic);
                component.set("v.Logistic.Shipping_Preferences_Return__c",obj.shipReturnPreferences);
                component.set("v.Logistic.Shipping_Preferences__c",obj.shipPreferences);
                component.set("v.channelId",component.get("v.Logistic").Channel__c); 
                component.set("v.DistributeChannelId",component.get("v.Logistic").Distribution_Channel__c); 
                component.set("v.selectedTab",'log');                                       
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                
            }else{
                var error1=response.getError();
                console.log('Error fetchPOItemList:',error1);
                component.set('v.exceptionError',error1[0].message);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action); 
    },
    
    getBillingOptionsPickList: function(component,event,helper){
        console.log('getBillingOptionsPickList called');
        var billingOptionsAction = component.get("c.getbilloptions");
        var billingOpts=[];
        billingOptionsAction.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                billingOpts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            console.log('billingOpts~>',billingOpts);
            component.set("v.billingOptions",billingOpts);
        });
        $A.enqueueAction(billingOptionsAction); 
    },
    
})