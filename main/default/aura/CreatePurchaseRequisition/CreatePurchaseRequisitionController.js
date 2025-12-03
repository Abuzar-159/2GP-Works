({
    doInit : function(component, event, helper) {
       
      /*
       
       
         component.set("v.OrgName",Org);
        */
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        let poStatus = component.get("c.getStatus");
        poStatus.setCallback(this,function(response){
                let resList = response.getReturnValue().StatusList;
                var isAccess = response.getReturnValue().isAccessible;
                component.set("v.PRStatusoptions",resList);
                component.set("v.IsBusinessUnitAccess",isAccess);
            $A.util.addClass(component.find('mainSpin'), "slds-hide");
        });
        $A.enqueueAction(poStatus);
        if(!$A.util.isUndefined(component.get("v.soliID")) && !$A.util.isEmpty(component.get("v.soliID")))
            helper.SOLIDOInit(component, event, helper);
        if(!$A.util.isUndefined(component.get("v.orderId")) && !$A.util.isEmpty(component.get("v.orderId")))
            helper.OrdItmDOInit(component, event, helper); helper.PopulateFields(component, event, helper);  component.set("v.PR.Order_S__c",component.get("v.orderId"));
        if(!$A.util.isUndefined(component.get("v.mrplineId")) && !$A.util.isEmpty(component.get("v.mrplineId")))
            helper.mrplineInit(component, event, helper);
        if(!$A.util.isUndefined(component.get("v.MOId")) && !$A.util.isEmpty(component.get("v.MOId")))
            helper.MOInit(component, event, helper);
        if(!$A.util.isUndefined(component.get("v.WOId")) && !$A.util.isEmpty(component.get("v.WOId")))
            helper.WOInit(component, event, helper);
        if(!$A.util.isUndefined(component.get("v.SalesId")) && !$A.util.isEmpty(component.get("v.SalesId")))
            helper.SalesDOInit(component, event, helper);
        helper.displayRecords(component, event, helper);
    },
    
    handleDateChange : function(component, event, helper) {
        let selectedDate = event.getSource().get("v.value");
        component.set("v.PR.Expected_Delivery_Date__c", selectedDate);
        console.log('Updated Expected Delivery Date:', selectedDate);
        
        let today = new Date();
        today.setHours(0,0,0,0); // normalize to midnight (ignore time)
        let chosenDate = new Date(selectedDate);
        if(chosenDate < today){
            //component.set("v.exceptionError", 'Expected Delivery Date cannot be earlier than today');
             helper.showToast('Warning !','warning','Expected Delivery Date cannot be earlier than today');
            return;
        }

    },
    
    addNew : function(component, event, helper) {
        var prliList = component.get("v.prli");
        var OrderId = component.get("v.orderId");
        prliList.unshift({sObjectType :'Purchase_Requisition_Line_Items__c',ItemsinStock : 0.0, demand: 0.0,AwaitingStock :0.0});
        component.set("v.prli",prliList);
    },
    
    deletePrli :function(component, event, helper) {
        
	   var prliList =[]; 
       prliList=component.get("v.prli");       
       var index=event.getParam("Index"); //component.get("v.Index2del");
       prliList.splice(index,1);
       component.set("v.prli",prliList);
        
     },
    
    savePR : function(component, event, helper){
        var ordId=component.get('v.orderId');
         var SoId=component.get('v.SalesId');
        var prLIst = component.get("v.prli");
        
        if(component.get("v.Mtask") != null && component.get("v.Mtask") != undefined && component.get("v.Mtask") != ""){
            var task = component.get("v.Mtask");
            component.set("v.PR.Tasks__c", task.Id);
            component.set("v.PR.Project__c", task.Project__c);
        }
        
        component.set("v.PR.Channel__c",component.get("v.channelId"));
        component.set("v.PR.Distribution_Channel__c",component.get("v.distributionChannel.Id"));
       // var errorDisplay = helper.validationCheckName(component, event);
        
        var errorCh = helper.validationCheckCh(component,event,helper);
        var errorDC = helper.validationCheckDC(component,event,helper);
        var isErrors=helper.validationCheckQuantity(component, event, helper);
        //var isErrorsUP = helper.validationCheckUnitPrice(component, event, helper);
        console.log('errorCh : ',errorCh);
        console.log('errorDC : ',errorDC);
        console.log('isErrors : ',isErrors);
        if(!isErrors && errorDC && errorCh){//errorDisplay && 
            $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        if(prLIst.length>0){
            console.log('in save pr');
            var selectedDate = component.get("v.PR.Expected_Delivery_Date__c");
            let today = new Date();
            today.setHours(0,0,0,0); // normalize to midnight (ignore time)
            let chosenDate = new Date(selectedDate);
            if(chosenDate < today){
                component.set("v.exceptionError", 'Expected Delivery Date cannot be earlier than today');
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                return;
                
            }
            console.log('PR ',JSON.stringify(component.get("v.PR")));
            console.log('prLIst ',JSON.stringify(prLIst));
        var saveAction = component.get("c.save_PurchaseRequisition");
            saveAction.setParams({"purchaseRequisition":JSON.stringify(component.get("v.PR")),
                                  "PRLI_List":JSON.stringify(prLIst),
                                  "orderId":component.get('v.orderId'),
                                  "SOId":component.get('v.SalesId')});
            saveAction.setCallback(this,function(response){
            if(response.getState() === 'SUCCESS'){
                console.log('OUTPUT : ',JSON.stringify(prLIst));
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                helper.showToast($A.get('$Label.c.Success'),'success',$A.get('$Label.c.Purchase_Requisition_Created_Successfully'));
                if(component.get("v.Mtask")){
                    helper.goBackTaskM(component, event);
                }
                else{
                    if(ordId != '' && ordId !=undefined){
                        sforce.one.showToast({
                            "title": $A.get('$Label.c.Success'),
                            "type": "success",
                            "message": $A.get('$Label.c.Purchase_Requisition_Created_Successfully')
                        });
                        var RecUrl = "/lightning/r/Order/" + ordId + "/view";
                        window.open(RecUrl,'_parent');
                    }
                    else if(SoId != '' && SoId !=undefined){
                        sforce.one.showToast({
                            "title": $A.get('$Label.c.Success'),
                            "type": "success",
                            "message": $A.get('$Label.c.Purchase_Requisition_Created_Successfully')
                        });
                        var RecUrl = "/lightning/r/Sales_Order__c/" + SoId + "/view";
                        window.open(RecUrl,'_parent');
                    }
                   else if((component.get("v.MOId") != null && component.get("v.MOId") != '' && component.get("v.MOId") != undefined) || (component.get("v.MPsMOId") != null && component.get("v.MPsMOId") != '' && component.get("v.MPsMOId") != undefined)){
                       var MoId = (component.get("v.MOId") != null && component.get("v.MOId") != '' && component.get("v.MOId") != undefined) ? component.get("v.MOId") :  component.get("v.MPsMOId");  
                       $A.createComponent("c:Manufacturing_Orders",{
                                "MO": MoId,
                                "NAV":'mp',
                                "RD":'yes',
                                "allowNav" : true
                            },function(newCmp, status, errorMessage){
                                if (status === "SUCCESS") {
                                    var body = component.find("body");
                                    body.set("v.body", newCmp);
                                    component.set("v.showFooter", false);
                                }
                            });
                   }
                    else if(component.get("v.navigateToRecord")){
                        var navEvt = $A.get("e.force:navigateToSObject");
                        if(navEvt != undefined){
                            navEvt.setParams({
                                "isredirect": true,
                                "recordId": response.getReturnValue().Id,
                                "slideDevName": "detail"
                            }); 
                            navEvt.fire();
                        }else {
                            location.reload();  
                        }
                    }else{
                        var params = event.getParam('arguments');
                        var callback;
                        if (params) {
                            callback = params.callback;
                        }
                        if (callback) callback(response.getReturnValue());
                    }
                }
              }
            else{
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
                var errors = response.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    helper.showToast($A.get('$Label.c.Error_UsersShiftMatch'),'error',errors[0].message);
                }
            }
        });
        $A.enqueueAction(saveAction);
        }
        else{
            $A.util.addClass(component.find('mainSpin'), "slds-hide");
            component.set("v.exceptionError", $A.get('$Label.c.PH_DebNote_Please_add_a_Line_Item'));
        }
        }
        else{
            component.set("v.exceptionError", $A.get('$Label.c.PH_DebNote_Review_All_Errors'));
            
                 var errorMessage = '';
             if(!errorCh && !errorDC && isErrors ){//!errorDisplay &&
                 errorMessage = $A.get('$Label.c.PO_Please_enter_the_required_fields_that_are_marked');
             }
             else if(!errorCh && !errorDC){//!errorDisplay && 
                 errorMessage = $A.get('$Label.c.PO_Please_enter_the_required_fields_that_are_marked');
             }
            else if(!isErrors){//!errorDisplay && 
                 errorMessage = $A.get('$Label.c.PO_Please_enter_the_required_fields_that_are_marked');
             }
             else{
                 errorMessage = $A.get('$Label.c.Please_enter');
                /* if (!errorDisplay)
                     errorMessage += "Purchase Requisition name";*/
                 
                 if(!errorCh){
                     if(errorMessage != $A.get('$Label.c.Please_enter'))
                         errorMessage += ", ";
                     
                     errorMessage += $A.get('$Label.c.Channel_StockTake') +" ";
                     if(errorDC)
                         errorMessage += "information";
                 }
                 
                 if (!errorDC){
                     if(errorMessage != $A.get('$Label.c.Please_enter'))
                         errorMessage += ", ";
                     
                     errorMessage += $A.get('$Label.c.Distribution_center_receiving') +" ";
                     if(errorCh)
                         errorMessage += "information";
                 }
                 
                 if (isErrors){
                     if(errorMessage != $A.get('$Label.c.Please_enter'))
                         errorMessage += ",";
                     
                     errorMessage += " "+$A.get('$Label.c.valid_quantity_New');
                 }
                  /*if (isErrorsUP){
                     if(errorMessage != " Please enter ")
                         errorMessage += ", ";
                     
                     errorMessage += "Unit Price" ;
                 }*/
                 
                 if (!errorCh && !errorDC)
                     errorMessage += " information";
                 errorMessage += ".";
             }
             component.set("v.exceptionError",errorMessage);
        }
    
    },
 
    validateField : function(component, event, helper){
        var prName = component.find("prName");
        if(!$A.util.isUndefined(prName)) 
            helper.checkValidationField(prName);
    },
    UpdateOA: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Company__c",pr.Company__r.Id);        
    },
    
    UpdateRB: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Requisitioned_By__c",pr.Requisitioned_By__r.Id);        
    },
    
    UpdateOBU: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Originating_Business_Unit__c",pr.Originating_Business_Unit__r.Id);        
    },
    
    UpdateDC: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Delivery_Contact__c",pr.Delivery_Contact__r.Id);        
    },
    
    UpdateDA: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Delivery_Address__c",pr.Delivery_Address__r.Id);        
    },
    
    UpdateChan: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Channel__c",pr.Channel__r.Id);        
    },
    
    UpdateDChan: function(component,event,helper){
        var pr = component.get("v.PR");
        component.set("v.PR.Distribution_Channel__c",pr.Distribution_Channel__r.Id);        
    },
    
    closeError : function (cmp, event) {
    	cmp.set("v.exceptionError",'');
    },
    
    goBackTaskM : function(component, event, helper) {
        $A.createComponent("c:AddMilestoneTask",{
            "aura:id" : "taskCmp",
            "projectId" : component.get("v.projectId"),
            "taskId" : component.get("v.Mtask.Id"),
            "newTask" : component.get("v.Mtask"),
            "currentMilestones" : component.get("v.currentMilestones"),
            "currentProject" : component.get("v.currentProject")
        },function(newCmp, status, errorMessage){
            if (status === "SUCCESS") {
                var body = component.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
    goBack: function(cmp,event,helper){
        window.history.back();
    },
    showLogisticRecordDetailsPage:function(comp,event,helper){ 
    var recordId = event.target.dataset.record;  
        
    comp.set("v.nameUrl",'/'+recordId); 
   },
})