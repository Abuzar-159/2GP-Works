({
    getAllDetails : function(cmp, event, helper) {    
        $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
        var logId = cmp.get("v.logisticId"); 
        var show = cmp.get("v.show");  
        var action = cmp.get("c.getAll");
        console.log('filtertype : ',cmp.get("v.filtertype"));
        var channel = cmp.get("v.currentEmployee.Channel__c");
        console.log('Current Employee Channel:',channel);
        var site = cmp.get("v.selectedSite");
        if(site == null || site == undefined) site = '';
        if(channel == null || channel == undefined) channel = '';
        
        action.setParams({logisticId:logId, searchText:"", Channel:channel, Site:site, Offset:0, Show:show,filter : cmp.get("v.filtertype"),shipFilter :cmp.get("v.selectedShipment") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Result getall==>',response.getReturnValue());
                //alert(response.getReturnValue().selectedSite);
                cmp.set("v.PreventChange", true);
                cmp.set("v.Container", response.getReturnValue());
                console.log('Container getAll:',JSON.stringify(cmp.get("v.Container")));
                cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                //cmp.find("Site").set("v.options", response.getReturnValue().channelSites);
                cmp.set("v.SiteOptions",response.getReturnValue().channelSites);
                cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                cmp.set('v.allowChannelRemove',response.getReturnValue().dontallowChannelRemove);
                console.log('allowChannelRemove : ',response.getReturnValue().dontallowChannelRemove);
                cmp.set('v.showAllfilters',response.getReturnValue().ShowAllfilters);
                cmp.set('v.showShipFilters',response.getReturnValue().ShowShipfilters);
                cmp.set('v.ShipOptions',response.getReturnValue().shiptypes);
                console.log('query : ',response.getReturnValue().query);
                cmp.set("v.PreventChange", false);
                var alllogistics = response.getReturnValue().allLogs;
                let totalOrdersTobeShipped = 0;
                let totalPartialShipped = 0;
                let totaldelivered = 0;
                let TotalNewOrders = 0;
                let TotalShipOrders = 0;
                console.log('alllogistics.lenght~>'+alllogistics.length);
                console.log('showAllfilters~>'+response.getReturnValue().ShowAllfilters);
                for(var x in alllogistics){
                    console.log(' alllogistics[x] : '+alllogistics[x].Id+' Total_Quantity__c : '+alllogistics[x].Total_Quantity__c+' Delivered_Quantity__c : '+alllogistics[x].Delivered_Quantity__c+' Closed__c : '+alllogistics[x].Closed__c);
                    if(cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c >= 0 && alllogistics[x].Picked_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c  == 0 /*&& alllogistics[x].Ready_To_Ship__c == true*/ && alllogistics[x].Closed__c  == false){
                        totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                    }
                    else if(!cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c >= 0 && alllogistics[x].Delivered_Quantity__c  == 0 && alllogistics[x].Closed__c  == false && alllogistics[x].Picked_Quantity__c >= 0){//&& alllogistics[x].Ready_To_Ship__c == true 
                        totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                    }
                    if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Ready_To_Ship__c == true && alllogistics[x].Closed__c  == false && alllogistics[x].Shipped_Quantity__c  < alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0) {
                        totalPartialShipped = totalPartialShipped + 1;
                    }
                    if((alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Delivered_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c == alllogistics[x].Total_Quantity__c) || alllogistics[x].Closed__c  == true){
                        totaldelivered = totaldelivered + 1;
                        console.log('alllogistics[x] : ',alllogistics[x].Id);
                    }
                    if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Picked_Quantity__c  == 0 && alllogistics[x].Packed_Quantity__c  == 0 && alllogistics[x].Shipped_Quantity__c  == 0 &&  alllogistics[x].Closed__c == false){
                        TotalNewOrders = TotalNewOrders + 1;
                    }
                    if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Shipped_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Picked_Quantity__c > 0 && alllogistics[x].Picked_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0 && alllogistics[x].Packed_Quantity__c == alllogistics[x].Total_Quantity__c  && alllogistics[x].Closed__c  == false){
                        TotalShipOrders = TotalShipOrders + 1;
                    }
                }
                 console.log('TotalNewOrders~>'+TotalNewOrders);
                console.log('totalOrdersTobeShipped~>'+totalOrdersTobeShipped);
                console.log('totalPartialShipped~>'+totalPartialShipped);
                console.log('TotalShipOrders~>'+TotalShipOrders);
                console.log('totaldelivered~>'+totaldelivered);
                
                cmp.set('v.TotalOrdersToBeShipped',totalOrdersTobeShipped);
                cmp.set('v.TotalPartiallyShippedOrders',totalPartialShipped);
                cmp.set('v.TotalDeliveredOrders',totaldelivered);
                cmp.set('v.TotalNewOrders',TotalNewOrders);
                cmp.set('v.TotalShippedOrders',TotalShipOrders);
                if(cmp.get('v.filtertype') == 'OrdersToBeShipped'){
                    var cmpTarget = cmp.find('OrdersToBeShipped');
                    $A.util.addClass(cmpTarget, 'active-receive-grey');
                }
                $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action);

        
    },  
    
    LoadNow : function(cmp, event, helper) {
        //alert('out');
        console.log('Load called');
        window.scrollTo(0, 0);
        var logId = cmp.get("v.logisticId");
        var searchtext = cmp.get("v.searchText");
        var channel = cmp.get("v.currentEmployee.Channel__c");
        console.log('channel : ',channel);
        var filterSelected = cmp.get("v.filtertype");
        var site = cmp.get("v.selectedSite");
        var show = cmp.get("v.show");
        var offset = cmp.get("v.Container.Offset");
        if(channel == undefined) { channel = ""; site = ""; }
        if(searchtext == undefined) searchtext = "";
        if(searchtext != '') filterSelected = '';
        cmp.set("v.checkAll",false);
        //alert('offset : '+offset);
        //alert('show : '+show);
        
        if(!cmp.get("v.PreventChange") && channel != ""){
            console.log('Load in');
            //alert('in');
            $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
            var action = cmp.get("c.getAll");
            action.setParams({logisticId:logId, searchText:searchtext, Channel:channel, Site:site, Offset:offset, Show:show,filter : filterSelected,shipFilter :cmp.get("v.selectedShipment") });
            action.setCallback(this, function(response) {
                var state = response.getState();
                //alert(state);
                if (state === "SUCCESS") {
                    //alert(response.getReturnValue().selectedSite);
                    cmp.set("v.PreventChange", true);
                    cmp.set("v.Container", response.getReturnValue());
                    console.log('Container Outboundlogistics:',JSON.stringify(cmp.get("v.Container")));
                    cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                    //cmp.find("Site").set("v.options", response.getReturnValue().channelSites);
                    cmp.set("v.SiteOptions",response.getReturnValue().channelSites);
                    cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                    cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                    cmp.set("v.PreventChange", false);
                    
                    var alllogistics = response.getReturnValue().allLogs;
                    let totalOrdersTobeShipped = 0;
                    let totalPartialShipped = 0;
                    let totaldelivered = 0;
                    let TotalNewOrders = 0;
                    let TotalShipOrders = 0;
                    for(var x in alllogistics){
                        console.log(' alllogistics[x] : '+alllogistics[x].Id+' Total_Quantity__c : '+alllogistics[x].Total_Quantity__c+' Delivered_Quantity__c : '+alllogistics[x].Delivered_Quantity__c+' Closed__c : '+alllogistics[x].Closed__c);
                        if(cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c  == 0 && alllogistics[x].Ready_To_Ship__c == true && alllogistics[x].Closed__c  == false){
                            totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                        }
                        else if(!cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c >= 0 && alllogistics[x].Delivered_Quantity__c  == 0  && alllogistics[x].Closed__c  == false && alllogistics[x].Picked_Quantity__c >= 0){//&& alllogistics[x].Ready_To_Ship__c == true
                            totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                        }
                        if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Ready_To_Ship__c == true && alllogistics[x].Closed__c  == false && alllogistics[x].Shipped_Quantity__c  < alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0) {
                            totalPartialShipped = totalPartialShipped + 1;
                        }
                        if((alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Delivered_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c == alllogistics[x].Total_Quantity__c) || alllogistics[x].Closed__c  == true){
                            totaldelivered = totaldelivered + 1;
                            console.log('alllogistics[x] : ',alllogistics[x].Id);
                        }
                        if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Picked_Quantity__c  == 0 && alllogistics[x].Packed_Quantity__c  == 0 && alllogistics[x].Shipped_Quantity__c  == 0 &&  alllogistics[x].Closed__c == false){
                            TotalNewOrders = TotalNewOrders + 1;
                        }
                        if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Shipped_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Picked_Quantity__c > 0 && alllogistics[x].Picked_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0 && alllogistics[x].Packed_Quantity__c == alllogistics[x].Total_Quantity__c  && alllogistics[x].Closed__c  == false){
                            TotalShipOrders = TotalShipOrders + 1;
                        }
                    }
                    cmp.set('v.TotalOrdersToBeShipped',totalOrdersTobeShipped);
                    cmp.set('v.TotalPartiallyShippedOrders',totalPartialShipped);
                    cmp.set('v.TotalDeliveredOrders',totaldelivered);
                    cmp.set('v.TotalNewOrders',TotalNewOrders);
                    cmp.set('v.TotalShippedOrders',TotalShipOrders);
                    console.log('Total Orders to be Shipped: ', totalOrdersTobeShipped);
console.log('Total Partially Shipped Orders: ', totalPartialShipped);
console.log('Total Delivered Orders: ', totaldelivered);
console.log('Total New Orders: ', TotalNewOrders);
console.log('Total Shipped Orders: ', TotalShipOrders);
                    if(cmp.get('v.filtertype') == 'OrdersToBeShipped'){
                        var cmpTarget = cmp.find('OrdersToBeShipped');
                        $A.util.addClass(cmpTarget, 'active-receive-grey');
                    }
                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                }
            });
            $A.enqueueAction(action);
        }
    }, 
    
    LoadChannelChange : function(cmp, event, helper) {
        if(!cmp.get("v.PreventChange")){
            cmp.set("v.Container.Offset",0);
            //alert('out');
            window.scrollTo(0, 0);
            var logId = cmp.get("v.logisticId");
            var searchtext = cmp.get("v.searchText");
            var channel = cmp.get("v.currentEmployee.Channel__c");
            var site = cmp.get("v.selectedSite");
            var show = cmp.get("v.show");
            var offset = cmp.get("v.Container.Offset");
            site = "";
            if(channel == undefined) { channel = ""; site = ""; }
            if(searchtext == undefined) searchtext = "";
            cmp.set("v.checkAll",false);
            //alert('offset : '+offset);
            //alert('show : '+show);
            
            //alert('channel : '+channel);
            //alert('site : '+site);
            if(!cmp.get("v.PreventChange") && channel != ""){
                //alert('in');
                $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
                var action = cmp.get("c.getAll");
                action.setParams({logisticId:logId, searchText:searchtext, Channel:channel, Site:site, Offset:offset, Show:show});
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    //alert(state);
                    if (state === "SUCCESS") {
                        console.log('LoadChannelChange res : ',response.getReturnValue());
                        cmp.set("v.PreventChange", true);
                        cmp.set("v.Container", response.getReturnValue());
                        //cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                        //cmp.find("Site").set("v.options", response.getReturnValue().channelSites);
                        cmp.set("v.SiteOptions",response.getReturnValue().channelSites);
                        cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                        cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                        cmp.set("v.PreventChange", false);
                        var alllogistics = response.getReturnValue().allLogs;
                        let totalOrdersTobeShipped = 0;
                        let totalPartialShipped = 0;
                        let totaldelivered = 0;
                        let TotalNewOrders = 0;
                        let TotalShipOrders = 0;
                        for(var x in alllogistics){
                            
                            if(cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c  == 0 && alllogistics[x].Ready_To_Ship__c == true && alllogistics[x].Closed__c  == false){
                                totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                            }
                            else if(!cmp.get('v.showAllfilters') && alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c == 0 && alllogistics[x].Packed_Quantity__c >= 0 && alllogistics[x].Delivered_Quantity__c  == 0 &&  alllogistics[x].Closed__c  == false && alllogistics[x].Picked_Quantity__c >= 0){//alllogistics[x].Ready_To_Ship__c == true &&
                                totalOrdersTobeShipped = totalOrdersTobeShipped + 1;
                            }
                            if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Ready_To_Ship__c == true && alllogistics[x].Closed__c  == false && alllogistics[x].Shipped_Quantity__c  < alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0) {
                                totalPartialShipped = totalPartialShipped + 1;
                            }
                            if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Delivered_Quantity__c > 0 && alllogistics[x].Delivered_Quantity__c == alllogistics[x].Total_Quantity__c  && alllogistics[x].Closed__c  == true){
                                totaldelivered = totaldelivered + 1;
                                console.log('alllogistics[x] : ',alllogistics[x].Id);
                            }
                            if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Picked_Quantity__c  == 0 && alllogistics[x].Packed_Quantity__c  == 0 && alllogistics[x].Shipped_Quantity__c  == 0 &&  alllogistics[x].Closed__c == false){
                                TotalNewOrders = TotalNewOrders + 1;
                            }
                            if(alllogistics[x].Total_Quantity__c  > 0 && alllogistics[x].Shipped_Quantity__c > 0 && alllogistics[x].Shipped_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Picked_Quantity__c > 0 && alllogistics[x].Picked_Quantity__c == alllogistics[x].Total_Quantity__c && alllogistics[x].Packed_Quantity__c > 0 && alllogistics[x].Packed_Quantity__c == alllogistics[x].Total_Quantity__c  && alllogistics[x].Closed__c  == false){
                                TotalShipOrders = TotalShipOrders + 1;
                            }
                        }
                        console.log('')
                        cmp.set('v.TotalOrdersToBeShipped',totalOrdersTobeShipped);
                        cmp.set('v.TotalPartiallyShippedOrders',totalPartialShipped);
                        cmp.set('v.TotalDeliveredOrders',totaldelivered);
                        cmp.set('v.TotalNewOrders',TotalNewOrders);
                        cmp.set('v.TotalShippedOrders',TotalShipOrders);
                        if(cmp.get('v.filtertype') == 'OrdersToBeShipped'){
                            var cmpTarget = cmp.find('OrdersToBeShipped');
                            $A.util.addClass(cmpTarget, 'active-receive-grey');
                        }
                        $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                    }
                });
                $A.enqueueAction(action);
            }
        }
    },
    
    SetShow : function(cmp, event, helper) {
        cmp.set("v.Container.Offset",0);
        cmp.LoadNow();
    },
    
    OfsetChange : function(cmp, event, helper) {
        var container = cmp.get("v.Container");
        var PNS = container.PNS;
        var PageNum = container.PageNum;
        var Offset = parseInt(container.Offset);
        var show = parseInt(cmp.get("v.show"));
        
        if(PageNum > 0 && PageNum <= PNS.length){
            if(((Offset+show)/show) != PageNum){
                Offset = (show*PageNum)-show;
                cmp.set("v.Container.Offset",Offset);
            }
            cmp.LoadNow();
        } else cmp.set("v.Container.PageNum",(Offset+show)/show);
    },
    
    Next : function(cmp, event, helper) {
        var container = cmp.get("v.Container");
        var show = parseInt(cmp.get("v.show"));
        var Offset = parseInt(container.Offset);
        var endCount = parseInt(container.endCount);
        var recSize = parseInt(container.recSize);
        
        if(endCount != recSize){
            var newOffset = Offset+show
            cmp.set("v.Container.Offset",Offset+show);
            cmp.LoadNow();
        }
    },
    
    NextLast : function(cmp, event, helper) {
        var container = cmp.get("v.Container");
        var PNS = container.PNS;
        var show = parseInt(cmp.get("v.show"));
        var endCount = parseInt(container.endCount);
        var recSize = parseInt(container.recSize);
        if(endCount != recSize){
            cmp.set("v.Container.Offset",((PNS.length-1)*show));
            cmp.LoadNow();
        }
    },
    
    Previous : function(cmp, event, helper) {
        var container = cmp.get("v.Container");
        var Offset = parseInt(container.Offset);
        var show = parseInt(cmp.get("v.show"));
        var startCount = parseInt(container.startCount);
        if(startCount > 1){
            cmp.set("v.Container.Offset",Offset-show);
            cmp.LoadNow();
        }
    },
    
    PreviousFirst : function(cmp, event, helper) {
        var container = cmp.get("v.Container");
        var startCount = parseInt(container.startCount);
        if(startCount > 1){
            cmp.set("v.Container.Offset",0);
            cmp.LoadNow();
        }
    },
    
    Load : function(cmp, event, helper) {
        if(!cmp.get("v.PreventChange")){
            console.log('in load');
            cmp.set("v.Container.Offset",0);
            cmp.LoadNow();
        }
        

        
    },
    
    NavRecord : function (component, event) {
        var RecId = event.getSource().get("v.id");
        console.log('RecId : ',RecId);  //event.getSource().get("v.title");
        var RecUrl = "/" + RecId;
        window.open(RecUrl,'_blank');
    },
    
    Reload : function (component, event) {
        window.location.reload();
    },
    
    checkAll : function(cmp, event, helper) {
        var obj = cmp.get("v.Container.Logistics");
        var val = cmp.get("v.checkAll");
        for(var x in obj){
            obj[x].soSelected = val;
        }
        cmp.set("v.Container.Logistics",obj);
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
        var logId = '';
        try{
            logId = event.currentTarget.getAttribute('data-logisticId');
        } catch(err){ }
        
        if(logId == undefined || logId == '' || logId == 'null' || logId == null){
            var Logs = cmp.get("v.Container.Logistics");
            for(var x in Logs){
                if(Logs[x].soSelected == true) {
                    if(logId == undefined || logId == '' || logId == 'null' || logId == null) logId = Logs[x].Logistic.Id;
                    else logId = logId+','+Logs[x].Logistic.Id;
                }
            }
        }
        if(logId == '' || logId == 'null' || logId == null) cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Please_select_an_order_to_proceed_to_pick'));   
        else{
            //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
            //window.open(RecUrl,'_self');
            $A.createComponent("c:Pick",{
                "logisticIds":logId
            },function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.find("body");
                    body.set("v.body", newCmp);
                }
            });
        }
    },
    
    createPacks : function(cmp, event, helper) {
        var logId = '';
        try{
            logId = event.currentTarget.getAttribute('data-logisticId');
        } catch(err){ }
        
        if(logId == undefined || logId == '' || logId == 'null' || logId == null){
            var Logs = cmp.get("v.Container.Logistics");
            for(var x in Logs){
                if(Logs[x].soSelected == true) {
                    if(logId == undefined || logId == '' || logId == 'null' || logId == null) logId = Logs[x].Logistic.Id;
                    else logId = logId+','+Logs[x].Logistic.Id;
                }
            }
        }
        
        if(logId == undefined || logId == '' || logId == 'null' || logId == null) cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Please_select_an_order_to_proceed_to_pack'));   
        else{
            //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
            //window.open(RecUrl,'_self');
            $A.createComponent("c:Pack",{
                "logisticIds":logId
            },function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.find("body");
                    body.set("v.body", newCmp);
                }
            });
        }
    },
    
    createShips : function(cmp, event, helper) {
        console.log('createShips called');
        var logId = '';
        var bool = false;
        try{
            logId = event.currentTarget.getAttribute('data-logisticId');
        } catch(err){ }
        
        if(logId == undefined || logId == '' || logId == 'null' || logId == null){
            var Logs = cmp.get("v.Container.Logistics");
            for(var x in Logs){
                if(Logs[x].soSelected == true){
                    if(Logs[x].Logistic.Ready_To_Ship__c == true && Logs[x].Logistic.Packed_Quantity__c > 0) {
                        if(logId == undefined || logId == '' || logId == 'null' || logId == null) logId = Logs[x].Logistic.Id;
                        else logId = logId+','+Logs[x].Logistic.Id;
                    }else{
                        logId = '';
                        bool = true;
                        break;
                    }
                }
            }
        }
        
        if(logId == undefined || logId == '' || logId == 'null' || logId == null){
            if(bool){
                cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Please_make_sure_the_orders_are_packed_and_ready_to_ship'));   
            }else{
                cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Please_select_an_order_to_proceed_to_ship'));   
            }
        }else{
            //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
            //window.open(RecUrl,'_self');
            $A.createComponent("c:Ship",{
                "logisticIds":logId
            },function(newCmp, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.find("body");
                    body.set("v.body", newCmp);
                }
            });
        }
    },
    
    focusTOscan : function (component, event,helper) {
        component.set("v.scanValue",'');
        helper.focusTOscan(component, event);  
        
    },
    
    verifyScanCode : function (cmp, event, helper) {
        var scan_Code = cmp.get("v.scanValue");
        console.log('scan_Code : ',scan_Code);
        var mybarcode = scan_Code;
        if(mybarcode != ''){
            cmp.set("v.exceptionError", '');
            //alert(mybarcode); 
            if(mybarcode == 'ORDER') { cmp.Back2Outbound(); }
            else if(mybarcode == 'PICK') { cmp.createPicks(); }
                else if(mybarcode == 'PACK') { cmp.createPacks(); }
                    else if(mybarcode == 'SHIP') { cmp.createShips(); }
                        else{  
                            $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
                            let logselected = cmp.get("v.Container.Logistics");
                            for(var x in logselected){
                                console.log('logselected[x] : ',JSON.stringify(logselected[x]));
                                if(logselected[x].soSelected && (logselected[x].Logistic.Barcode__c == mybarcode || logselected[x].Logistic.Logistic_Barcode__c  == mybarcode || logselected[x].Logistic.Barcode_S__c == mybarcode)){
                                    cmp.set("v.exceptionError", 'Logistics is already scanned. Please scan PICK to pick the items');
                                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                                    return;
                                }
                                else{
                                    break;  
                                }
                            }
                            var action = cmp.get("c.scanLogistics");
                            action.setParams({barcode:mybarcode});
                            action.setCallback(this, function(response) {
                                var state = response.getState();
                                //alert(state);
                                if (state === "SUCCESS") {
                                    cmp.set("v.PreventChange", true);
                                    if(response.getReturnValue().Logistics.length > 0) cmp.set("v.Container", response.getReturnValue());
                                    else cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Invalid_barcode_scanned'));
                                    cmp.set("v.PreventChange", false);
                                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                                }
                            });
                            $A.enqueueAction(action);
                        }  
            cmp.set("v.scanValue",'');
        }
    },
    
    closeError : function (cmp, event) {
        cmp.set("v.exceptionError",'');
    },
    getSortedRecords : function(component,event,helper){
        component.set("v.OrderBy",event.currentTarget.id); 
        // component.set("v.Order",event.currentTarget.dataset.service); 
        if(component.get("v.Order")=='DESC') component.set("v.Order",'ASC'); 
        else if(component.get("v.Order")=='ASC') component.set("v.Order",'DESC');   
        helper.getLogisticRecords(component,event); 
    },
    showOrdersToBeShipped : function(component,event,helper){
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var cmpTarget = component.find('OrdersToBeShipped');
        $A.util.addClass(cmpTarget, 'active-receive-grey');
        var cmpTarget = component.find('DeliveredOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-blue');
        var cmpTarget = component.find('PartiallyShippedOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-orange');
        var cmpTarget = component.find('NewOrders');
        $A.util.removeClass(cmpTarget, 'active-new-order');
        let filter = event.target.dataset.record;
        console.log('filter : ',filter);
        component.set('v.filtertype',filter);
        var a = component.get('c.getAllDetails');
        $A.enqueueAction(a);
    },
    showDeliveredOrders : function(component,event,helper){
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var cmpTarget = component.find('OrdersToBeShipped');
        $A.util.removeClass(cmpTarget, 'active-receive-grey');
        var cmpTarget = component.find('DeliveredOrders');
        $A.util.addClass(cmpTarget, 'active-receive-blue');
        var cmpTarget = component.find('PartiallyShippedOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-orange');
        var cmpTarget = component.find('NewOrders');
        $A.util.removeClass(cmpTarget, 'active-new-order');
        let filter = event.target.dataset.record;
        console.log('filter : ',filter);
        component.set('v.filtertype',filter);
        var a = component.get('c.getAllDetails');
        $A.enqueueAction(a);
    },
    PartiallyShippedOrders : function(component,event,helper){
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var cmpTarget = component.find('OrdersToBeShipped');
        $A.util.removeClass(cmpTarget, 'active-receive-grey');
        var cmpTarget = component.find('DeliveredOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-blue');
        var cmpTarget = component.find('PartiallyShippedOrders');
        $A.util.addClass(cmpTarget, 'active-receive-orange');
        var cmpTarget = component.find('NewOrders');
        $A.util.removeClass(cmpTarget, 'active-new-order');
        let filter = event.target.dataset.record;
        console.log('filter : ',filter);
        component.set('v.filtertype',filter);
        var a = component.get('c.getAllDetails');
        $A.enqueueAction(a);
    },
    showNewOrders : function(component,event,helper){
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var cmpTarget = component.find('OrdersToBeShipped');
        $A.util.removeClass(cmpTarget, 'active-receive-grey');
        var cmpTarget = component.find('DeliveredOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-blue');
        var cmpTarget = component.find('PartiallyShippedOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-orange');
        var cmpTarget = component.find('NewOrders');
        $A.util.addClass(cmpTarget, 'active-new-order');
        let filter = event.target.dataset.record;
        console.log('filter : ',filter);
        component.set('v.filtertype',filter);
        var a = component.get('c.getAllDetails');
        $A.enqueueAction(a);
    },
    showShippedOrders : function(component,event,helper){
        $A.util.removeClass(component.find('mainSpin'), "slds-hide");
        var cmpTarget = component.find('OrdersToBeShipped');
        $A.util.removeClass(cmpTarget, 'active-receive-grey');
        var cmpTarget = component.find('ShippedOrders');
        $A.util.addClass(cmpTarget, 'active-receive-blue');
        var cmpTarget = component.find('PartiallyShippedOrders');
        $A.util.removeClass(cmpTarget, 'active-receive-orange');
        var cmpTarget = component.find('NewOrders');
        $A.util.removeClass(cmpTarget, 'active-new-order');
        let filter = event.target.dataset.record;
        console.log('filter : ',filter);
        component.set('v.filtertype',filter);
        var a = component.get('c.getAllDetails');
        $A.enqueueAction(a);
    }
})