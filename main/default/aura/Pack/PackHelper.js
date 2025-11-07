({
    focusTOscan: function (component, event) {
        console.log('focusTOscan helper called');
        $(document).ready(function () {
            component.set("v.scanValue", '');
            var barcode = "";
            var pressed = false;
            var chars = [];
            $(window).keypress(function (e) {
                
                $(".scanMN").keypress(function (e) {
                    e.stopPropagation()
                });
                
                chars.push(String.fromCharCode(e.which));
                if (pressed == false) {
                    setTimeout(
                        function () {
                            pressed = false;
                            if (chars.length >= 3) {
                                var barcode = chars.join("");
                                barcode = barcode.trim();
                                chars = [];
                                pressed = false;
                                component.set("v.scanValue", barcode);
                                console.log('scanValue : ',component.get("v.scanValue"));
                                chars = [];
                                pressed = false;
                            }
                            chars = [];
                            pressed = false;
                        }, 500);
                }
                pressed = true;
            }); // end of window key press function         
            
            $(window).keydown(function (e) {
                if (e.which === 13) {
                    e.preventDefault();
                }
            });
        });
    },
    
    getDependentPicklists : function(component, event, helper) {
        console.log('getDependentPicklists called');
        var action = component.get("c.getDependentPicklistMap");
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
                component.set("v.depnedentFieldMap",pickListResponse.pickListMap);
                console.log('depnedentFieldMap : ', component.get("v.depnedentFieldMap"));
                console.log('pickListResponse : ', pickListResponse.pickListMap);
                // create a empty array for store parent picklist values 
                var parentkeys = []; // for store all map keys 
                var parentField = []; // for store parent picklist value to set on lightning:select. 
                
                // Iterate over map and store the key
                for (var pickKey in pickListResponse.pickListMap) {
                    parentkeys.push(pickKey);
                    console.log('parentkeys-> '+parentkeys+' pickKey-> '+pickKey);
                }
                
                //set the parent field value for lightning:select
                /* if (parentkeys != undefined && parentkeys.length > 0) {
                    parentField.push('--None--');
                }*/
                
                for (var i in parentkeys) {
                    parentField.push(parentkeys[i]);
                    console.log('parentkeys[i]-> '+parentkeys[i]+' parentField-> '+parentField);
                }  
                // set the parent picklist
                component.set("v.listControllingValues", parentField);
                 console.log('parentField : '+parentField);
                console.log('listControllingValues : '+component.get("v.listControllingValues"));
                //
                console.log('Package2Create.Shipment_Type__c : ',component.get("v.Package2Create.Shipment_Type__c"));
                var shiptype = component.get("v.Shiptype");
                console.log('shiptype : ',shiptype);
                if(shiptype == null || shiptype == '' || shiptype == undefined){
                    component.set("v.Package2Create.Shipment_Type__c", 'FedEx');
                }
                else component.set("v.Package2Create.Shipment_Type__c", shiptype);
                console.log('Package2Create.Shipment_Type__c after: ',component.get("v.Package2Create.Shipment_Type__c"));
                var pickListMap = component.get("v.depnedentFieldMap");
                console.log('pickListMap : ',JSON.stringify(pickListMap));
                if(component.get("v.Package2Create.Shipment_Type__c") != null && component.get("v.Package2Create.Shipment_Type__c") != '' && component.get("v.Package2Create.Shipment_Type__c") != undefined){
                    shiptype = component.get("v.Package2Create.Shipment_Type__c")
                    var childValues = (pickListMap != null && pickListMap != undefined) ? pickListMap[shiptype] : [];
                    if(childValues == null || childValues == undefined) childValues = [];
                    var childValueList = [];
                    // childValueList.push('--None--');
                    for (var i in childValues) {
                        childValueList.push(childValues[i]);
                    }
                    // set the child list
                    console.log('childValueList: '+childValueList);
                    component.set("v.listDependingValues", childValueList);
                    console.log('listDependingValues: '+component.get("v.listDependingValues"));
                    
                    if(childValues.length > 0){
                        component.set("v.bDisabledDependentFld" , false);  
                    }else{
                        component.set("v.bDisabledDependentFld" , true); 
                    }
                     console.log('childValueList: ',component.get("v.bDisabledDependentFld"));
                }
                else {
                    component.set("v.listDependingValues", ['Package']);
                    component.set("v.bDisabledDependentFld" , true);
                }
                
            }
            else{
                console.log('err : ',response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
})