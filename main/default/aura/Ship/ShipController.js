({
	getAllDetails : function(cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        var logisticIds = logIds.split(",");
        var LIds = JSON.stringify(logisticIds);

        var action = cmp.get("c.createShipments");
        action.setParams({LogisticIds:LIds}); //, Customer:''
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //alert(response.getReturnValue().exceptionError);
                cmp.set("v.PreventChange", true);
                //cmp.set("v.Container", response.getReturnValue());
                cmp.set("v.SiteName", response.getReturnValue().SiteName);
                cmp.set("v.ChannelName", response.getReturnValue().ChannelName);
                cmp.set("v.ChannelId", response.getReturnValue().ChannelId);
                cmp.set("v.LogisticsRecords", response.getReturnValue().LogisticRecs);
                console.log('logrecs~>'+typeof response.getReturnValue().LogisticRecs);
                cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);

                cmp.set("v.shipmentWrapperList", response.getReturnValue().shipmentWrapperList);
                console.log('shipmentWrapperList : '+JSON.stringify(response.getReturnValue().shipmentWrapperList));

                cmp.set("v.PreventChange", false);
                console.log('get shipid : ',cmp.get("v.shipId"));
                
                if(cmp.get("v.shipId") != '' && cmp.get("v.shipId") != null && cmp.get("v.shipId") != undefined) {
                    cmp.createShipment();
                }
                $A.util.addClass(cmp.find('mainSpin'), "slds-hide");

            }
        });
        $A.enqueueAction(action);

    },

    AssignShipment : function(cmp, event, helper) {
        // var shipId = event.getSource().get("v.title");
    var shipId = event.target.getAttribute("data-ship-id"); // Use event.target instead
     if(shipId == '' || shipId == null || shipId == undefined) {
            shipId = event.getSource().get("v.name");
        }

        cmp.set("v.shipId", shipId);
        console.log('shipId : ',shipId);
        //var a = cmp.get("c.createShipment");
		//$A.enqueueAction(a);
       cmp.createShipment();
    },

    


    createShipment : function(cmp, event, helper) {
        var shipId = cmp.get("v.shipId");
       
        console.log('shipId : ',shipId);
        var shipmentType = '';
        var obj = cmp.get("v.shipmentWrapperList");
        for(var x in obj) if(obj[x].shipM.Id == shipId) shipmentType = obj[x].shipmentType;
        var retValue = 'SOL';
        console.log("Is this sendle => ", shipmentType);
        if(shipId != undefined && shipId != '' && shipId != null) {
            if(shipmentType == 'UPS'){
                cmp.set("v.showShipComponent",true);
                cmp.set("v.showUPSRestAPIcomp",true);
                cmp.set("v.selectedShipmentId",shipId);
               /* cmp.set("v.exceptionError", '');
                $A.createComponent("c:UPS", {
                    "shipmentId":shipId,
                }, function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {

                        cmp.set("v.showShipComponent",true);
                        //cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");
                        body.set("v.body", newCmp);
                    }
                });*/
            } else if(shipmentType == 'USPS'){
                
                cmp.set("v.showShipComponent",true);
                cmp.set("v.showUSPScomp",true);
                cmp.set("v.selectedShipmentId",shipId);
                
              /*
                   $A.createComponent("c:uSPS", {
                        "packageId":selectedPackIds,
                    }, function(newCmp, status, errorMessage){
                        if (status === "SUCCESS") {
                            cmp.set("v.showShipComponent",true);
                            var body = cmp.find("mybody");
                            body.set("v.body", newCmp);
                        }
                        else{
                            console.log("Error : ", errorMessage);
                        }
                    });*/

            } 
                else if(shipmentType == 'Canada Post'){
                
                cmp.set("v.showShipComponent",true);
                cmp.set("v.showCPcomp",true);
                cmp.set("v.showload",true);
                cmp.set("v.selectedShipmentId",shipId);
                }
                    else if(shipmentType == 'FedEx'){
                        cmp.set("v.showShipComponent",true);
                        cmp.set("v.showFedExcomp",true);
                        cmp.set("v.selectedShipmentId",shipId);
                /*cmp.set("v.exceptionError", '');
                $A.createComponent("c:FedEx", {
                    "shipmentId":shipId,
                }, function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");
                        body.set("v.body", newCmp);
                    }
                });*/
            } else if(shipmentType == 'DHL'){
                /*
                    $A.createComponent("c:DHL", {
                        "packageId":selectedPackIds,
                    }, function(newCmp, status, errorMessage){
                        //alert('Status in fedex : ' +status);
                        if (status === "SUCCESS") {
                            cmp.set("v.showShipComponent",true);
                            var body = cmp.find("mybody");
                            body.set("v.body", newCmp);
                        }
                        else{
                            console.log("Error : ", errorMessage);
                        }
                    });*/


            } else if (shipmentType == 'Sendle') {
              cmp.set("v.showShipComponent",true);
              cmp.set("v.showSendle",true);
              cmp.set("v.selectedShipmentId",shipId);
              console.log("Is this sendle => ", shipmentType);

            }
             else if (shipmentType == 'Freight View') {
              cmp.set("v.showShipComponent",true);
              cmp.set("v.showFreightView",true);
              cmp.set("v.selectedShipmentId",shipId);
              console.log("Is  freight view => ", shipmentType);

            }
            else {
                console.log("Is this internal shipment => ", shipmentType);

                cmp.set("v.exceptionError", '');
                $A.createComponent("c:InternalShipment",{
                    "shipmentID":shipId,
                    "showHeader":cmp.get("v.showHeader")
                },function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");
                        body.set("v.body", newCmp);
                    }
                });

            }
        }
    },


    checkAll : function(cmp, event, helper) {
        var obj = cmp.get("v.shipmentWrapperList");
        var val = cmp.get("v.checkAll");
        for(var x in obj){
            obj[x].shipSelected = val;
        }
        cmp.set("v.shipmentWrapperList",obj);
    },

    createShippingSlips : function(cmp, event, helper) {
        cmp.set("v.exceptionError","");
        // var count = event.getSource().get("v.title");
            // var count = event.getSource().getElement().getAttribute("data-ship-count");


        var shIds = '';
        var shipmentWrapperList = cmp.get("v.shipmentWrapperList");
        for(var x in shipmentWrapperList) {
            if(shipmentWrapperList[x].shipSelected == true || x == count) {
                if(shIds == '') shIds = shipmentWrapperList[x].shipM.Id;
                else shIds += ','+shipmentWrapperList[x].shipM.Id;
            }
        }
        if(shIds == '') cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_shipment'));
        else{
             var shipSlip = $A.get("$Label.c.Ship_Slip");
            var RecUrl = "/apex/"+shipSlip+"?shIds=" + shIds;
        	window.open(RecUrl,'_blank');
        }
    },
     createShippingSlipsforAll : function(cmp, event, helper) {
        cmp.set("v.exceptionError","");

        var shIds = '';
        var shipmentWrapperList = cmp.get("v.shipmentWrapperList");
        for(var x in shipmentWrapperList) {
            if(shipmentWrapperList[x].shipSelected == true) {
                if(shIds == '') shIds = shipmentWrapperList[x].shipM.Id;
                else shIds += ','+shipmentWrapperList[x].shipM.Id;
            }
        }
        if(shIds == '') cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_shipment'));
        else{
             var shipSlip = $A.get("$Label.c.Ship_Slip");
            var RecUrl = "/apex/"+shipSlip+"?shIds=" + shIds;
        	window.open(RecUrl,'_blank');
        }
    },

    setScriptLoaded : function(cmp, event, helper) {

    },

    Back2Outbound : function(cmp, event, helper) {
        $A.createComponent("c:OutboundLogistics",{
        },function(newCmp, status, errorMessage){
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },

    createPicks : function(cmp, event, helper) {
    	var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Pick",{
            "logisticIds":logIds
        },function(newCmp, status, errorMessage){
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },

    createPacks : function(cmp, event, helper) {
    	var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Pack",{
            "logisticIds":logIds
        },function(newCmp, status, errorMessage){
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });

    },

    createShips : function(cmp, event, helper) {
    	var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Ship",{
            "logisticIds":logIds
        },function(newCmp, status, errorMessage){
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },

    focusTOscan : function (component, event,helper) {
        component.set("v.scanValue",'');
        helper.focusTOscan(component, event);

    },

    verifyScanCode : function (cmp, event, helper) {
        var scan_Code = cmp.get("v.scanValue");
        var mybarcode = scan_Code;
        if(mybarcode != ''){
            cmp.set("v.exceptionError", '');
            if(mybarcode == 'ORDER') { cmp.Back2Outbound(); }
            else if(mybarcode == 'PICK') { cmp.createPicks(); }
            else if(mybarcode == 'PACK') { cmp.createPacks(); }
            else if(mybarcode == 'SHIP') { cmp.createShips(); }
            else{
                cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Invalid_barcode_scanned'));
            }
            cmp.set("v.scanValue",'');
        }
    },

    closeError : function (cmp, event) {
    	cmp.set("v.exceptionError",'');
    },

    deleteShipm : function (component, event, helper) {
        var r = confirm('Are you sure you want to delete?');
        if (r == true) {
            $A.util.removeClass(component.find('mainSpin'), "slds-hide");
            var shipId = event.getSource().get("v.name");
            var logIds = component.get("v.logisticIds");
            var logisticIds = logIds.split(",");
            var LIds = JSON.stringify(logisticIds);

            var action = component.get("c.deleteShipments");
            action.setParams({ShipmentId:shipId, LogisticIds:LIds});
            action.setCallback(this, function(response) {
                if (response.getState() === "SUCCESS") {
                    console.log('success delepeShipments~>'+JSON.stringify(response.getReturnValue()));
                    console.log('logrecs~>'+JSON.stringify(response.getReturnValue().LogisticRecs));
                    //console.log('v.LogisticsRecords~>',component.get("v.LogisticsRecords"));
                    component.set("v.PreventChange", true);
                    console.log('here 1');
                    component.set("v.SiteName", response.getReturnValue().SiteName);
                    console.log('here 2');
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                    component.set("v.shipmentWrapperList", response.getReturnValue().shipmentWrapperList);
                    component.set("v.exceptionError", response.getReturnValue().exceptionError);
                    console.log('exceptionError~>'+response.getReturnValue().exceptionError);
                    try{
                        console.log('del logrecs~>'+typeof response.getReturnValue().LogisticRecs);
                    component.set("v.LogisticsRecords", response.getReturnValue().LogisticRecs);

                    }catch(e){
                        console.log('err~>'+JSON.stringify(e));
                    }
                }else{
                    console.log('error occured~>'+response.getReturnValue().exceptionError);
                    $A.util.addClass(component.find('mainSpin'), "slds-hide");
                }
            });
            $A.enqueueAction(action);
        }
    },

     StillToFulfill : function (component, event) {
       var logIds = component.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:StillToFulfillLightning",{
            "logisticIds":logIds
        },function(newCmp, status, errorMessage){

            if (status === "SUCCESS") {
                // $A.util.removeClass(component.find('mainSpin'), "slds-hide");
                var body = component.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
})