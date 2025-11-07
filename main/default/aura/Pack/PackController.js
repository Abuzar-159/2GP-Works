({
    getAllDetails: function (cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        var logisticIds = logIds.split(",");
        var LIds = JSON.stringify(logisticIds);
        console.log('LIds : ' + LIds);
        console.log('logisticIds : ', logisticIds);
        cmp.set("v.showShipComponent", false);
        console.log('showShipComponent : ', cmp.get("v.showShipComponent"));
        console.log('isAwaiting : ', cmp.get("v.isAwaiting"));
        console.log('createPack : ', cmp.get("v.createPack"));
        console.log('showShipAllbtton : ', cmp.get("v.showShipAllbtton"));
        var action = cmp.get("c.createPacksInit");
        action.setParams({ LogisticIds: LIds, Customer: '' });
        action.setCallback(this, function (response) {
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {
                
                cmp.set("v.PreventChange", true);
                //cmp.set("v.Container", response.getReturnValue());
                cmp.set("v.SiteName", response.getReturnValue().SiteName);
                cmp.set("v.ChannelName", response.getReturnValue().ChannelName);
                cmp.set("v.ChannelId", response.getReturnValue().ChannelId);
                cmp.set("v.Logistics", response.getReturnValue().LogisticRecs);
                cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                
                cmp.set("v.lineItemWrapperList", response.getReturnValue().lineItemWrapperList);
                cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                console.log('response.getReturnValue().Package2Create : ', response.getReturnValue().Package2Create);
                console.log('response.getReturnValue().LogisticRecs : ', response.getReturnValue().LogisticRecs);
                console.log('response.getReturnValue().lineItemWrapperList : ', response.getReturnValue().lineItemWrapperList);
                cmp.set('v.Shiptype', response.getReturnValue().Package2Create.Shipment_Type__c);
                console.log("ship type in 37  line ",cmp.get('v.Shiptype'));
                cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                cmp.set("v.enableFedexRestAPI", response.getReturnValue().enableFedexRestAPI);
                cmp.set("v.Customers", response.getReturnValue().Customers);
                cmp.set("v.SSTypeAccess", response.getReturnValue().showSSType);
                cmp.set("v.disablePackName", response.getReturnValue().disablePackName);
                cmp.set("v.disablePackDeclaredValue", response.getReturnValue().disablePackDeclaredValue);
                cmp.set("v.Customer", response.getReturnValue().Customer);
                cmp.set("v.CustomerPresent", response.getReturnValue().CustomerPresent);
                cmp.set("v.createPack", response.getReturnValue().createPack);
                cmp.set("v.isAwaiting", response.getReturnValue().isAwaiting);
                cmp.set("v.pkgTypeValue", response.getReturnValue().pkgTypeValue);
                cmp.set("v.WeightUnit", response.getReturnValue().WeightUnit);
                cmp.set("v.PackageType", response.getReturnValue().PackageType);
                cmp.set("v.ShipmentType", response.getReturnValue().ShipmentType);
                cmp.set("v.declareaccess", response.getReturnValue().enableDecalre);
                cmp.set("v.allowZerodeclaredValue", response.getReturnValue().allowZerodeclaredValue);
                cmp.set("v.disableShipmentType", response.getReturnValue().disableShipType);
                cmp.set("v.PreventChange", false);
                cmp.set("v.Dimension", response.getReturnValue().DimensionUnit);
                console.log('showShipComponent : ', cmp.get("v.showShipComponent"));
                console.log('isAwaiting : ', cmp.get("v.isAwaiting"));
                console.log('createPack : ', cmp.get("v.createPack"));
                console.log('showShipAllbtton : ', cmp.get("v.showShipAllbtton"));
                console.log('Response isAwaiting : ', response.getReturnValue().isAwaiting);
                console.log('Response createPack : ', response.getReturnValue().createPack);
                helper.getDependentPicklists(cmp, event, helper);
                
                $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action);
        
    },
    
    getAllCustomerDetails: function (cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        var logisticIds = logIds.split(",");
        var LIds = JSON.stringify(logisticIds);
        var customer = cmp.get("v.Customer");
        //window.scrollTo(0,0);
        $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
        
        var action = cmp.get("c.createPacksInit");
        action.setParams({ LogisticIds: LIds, Customer: customer });
        action.setCallback(this, function (response) {
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {
                //alert(response.getReturnValue().exceptionError);
                
                cmp.set("v.PreventChange", true);
                //cmp.set("v.Container", response.getReturnValue());
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                cmp.set("v.PreventChange", false);
                $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action);
        
    },
    
    checkAll: function (cmp, event, helper) {
        var obj = cmp.get("v.lineItemWrapperList");
        var val = cmp.get("v.checkAll");
        let err = false;
        for (var x in obj) {
            if ((obj[x].NoofLineItems > 0) && obj[x].pack.Status__c != 'Shipped' && obj[x].pack.Status__c != 'Picked Up' && obj[x].pack.Status__c != 'Delivered' && obj[x].pack.Logistic__r.Ready_To_Ship__c) {
                obj[x].sel = val;
                //alert(x);
            }
            else if (!obj[x].pack.Logistic__r.Ready_To_Ship__c) {
                cmp.set('v.exceptionError', $A.get('$Label.c.Please_enable_ready_to_ship_on_the_logistic'));
                err = true;
                break;
            }
            
        }
        cmp.set("v.lineItemWrapperList", obj);
        if (!err) cmp.set('v.showShipAllbtton', val);
    },
    
    checkAll2: function (cmp, event, helper) {
        var obj = cmp.get("v.packageWrapperList");
        var val = cmp.get("v.checkAll2");
        for (var x in obj) {
            obj[x].pkgSelected = val;
        }
        cmp.set("v.packageWrapperList", obj);
    },
    
    showship: function (component, event, helper) {
        try {
            var pkIds = [];
            var lineItemWrapperList = component.get("v.lineItemWrapperList");
            for (var x in lineItemWrapperList) {
                if (lineItemWrapperList[x].sel == true) {//lineItemWrapperList[x].pack.Shipment__c == undefined &&
                    console.log('lineItemWrapperList[x].sel ', lineItemWrapperList[x].sel + ' Id: ' + lineItemWrapperList[x].pack.Id);
                    pkIds.push(lineItemWrapperList[x].pack.Id);
                    //  else { pkIds += ','+lineItemWrapperList[x].pack.Id; }
                } else {
                    console.log('else lineItemWrapperList[x].sel ', lineItemWrapperList[x].sel);
                }
            }
            console.log('pkIds showship: ' + pkIds);
            if (pkIds.length > 0) {
                component.set('v.showShipAllbtton', true);
                console.log('showShipAllbtton: ', component.get('v.showShipAllbtton'));
            }
        } catch (e) {
            console.log('err==>' + e);
        }
    },
    
    createPackingLabels: function (cmp, event, helper) {
        cmp.set("v.exceptionError", "");
        var count = event.getSource().get("v.class");
        var pkIds = '';
        var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
        for (var x in lineItemWrapperList) {
            if ((lineItemWrapperList[x].sel == true || x == count)) {//lineItemWrapperList[x].pack.Shipment__c == undefined &&
                if (pkIds == '') pkIds = lineItemWrapperList[x].pack.Id;
                else pkIds += ',' + lineItemWrapperList[x].pack.Id;
            }
        }
        //alert(pkIds);
        if (pkIds == '') cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_package'));
        else {
            var PackLabel = $A.get("$Label.c.Pack_Label");
            var RecUrl = "/apex/" + PackLabel + "?pkIds=" + pkIds;
            window.open(RecUrl, '_blank');
        }
    },
    
    createSinglePackingLabel: function (cmp, event, helper) {
        cmp.set("v.exceptionError", "");
        var indx = event.currentTarget.getAttribute('data-index');
        if (indx != undefined && indx != null) {
            var pkIds = '';
            var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
            for (var x in lineItemWrapperList) {
                if (x == indx) {
                    pkIds = lineItemWrapperList[x].pack.Id;
                    break;
                }
            }
            if (pkIds != '') {
                var PackLabel = $A.get("$Label.c.Pack_Label");
                var RecUrl = "/apex/" + PackLabel + "?pkIds=" + pkIds;
                window.open(RecUrl, '_blank');
            }
        }
    },
    
    createPackingSlips: function (cmp, event, helper) {
        cmp.set("v.exceptionError", "");
        var count = event.getSource().get("v.class");
        var pkIds = '';
        var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
        for (var x in lineItemWrapperList) {
            if ((lineItemWrapperList[x].sel == true || x == count)) {//lineItemWrapperList[x].pack.Shipment__c == undefined &&
                if (pkIds == '') pkIds = lineItemWrapperList[x].pack.Id;
                else pkIds += ',' + lineItemWrapperList[x].pack.Id;
            }
        }
        //alert(pkIds);
        if (pkIds == '') cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_package'));
        else {
            var PackSlip = $A.get("$Label.c.Pack_Slip");
            var RecUrl = "/apex/" + PackSlip + "?pkIds=" + pkIds;
            console.log('RecUrl~> ' + RecUrl);
            window.open(RecUrl, '_blank');
        }
    },
    
    createSinglePackingSlip: function (cmp, event, helper) {
        cmp.set("v.exceptionError", "");
        var indx = event.currentTarget.getAttribute('data-index');
        if (indx != undefined && indx != null) {
            var pkIds = '';
            var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
            for (var x in lineItemWrapperList) {
                if (x == indx) {
                    pkIds = lineItemWrapperList[x].pack.Id;
                    break;
                }
            }
            if (pkIds != '') {
                var PackSlip = $A.get("$Label.c.Pack_Slip");
                var RecUrl = "/apex/" + PackSlip + "?pkIds=" + pkIds;
                window.open(RecUrl, '_blank');
            }
        }
    },
    
    createShips: function (cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Ship", {
            "logisticIds": logIds
        }, function (newCmp, status, errorMessage) {
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
    
    createShipment: function (cmp, event, helper) {
        try {
            console.log('createShipment called ');
            cmp.set("v.exceptionError", "");
            // var count = event.getSource().get("v.title");
            var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
            var sType = '';
            var error = false;
            var selectedPackIds = [];
            var shipmentType = '';
            cmp.set("v.exceptionError", '');
            
            for (var x in lineItemWrapperList) {
                if (lineItemWrapperList[x].pack.Shipment__c == undefined && lineItemWrapperList[x].pack.Logistic__r.Ready_To_Ship__c && (lineItemWrapperList[x].sel == true)) {
                    if (sType == '') {
                        sType = lineItemWrapperList[x].pack.Shipment_Type__c;
                    }
                    console.log('sType : ', sType);
                    if (sType == lineItemWrapperList[x].pack.Shipment_Type__c) {
                        console.log('lineItemWrapperList[x].pack.Shipment_Type__c : ', lineItemWrapperList[x].pack.Shipment_Type__c);
                        console.log('lineItemWrapperList[x].pack.ID : ', lineItemWrapperList[x].pack.Id);
                        selectedPackIds.push(lineItemWrapperList[x].pack.Id);
                        if (shipmentType == '') shipmentType = lineItemWrapperList[x].pack.Shipment_Type__c;
                    } else {
                        console.log('entered else');
                        cmp.set("v.exceptionError", $A.get('$Label.c.You_cannot_select_packages_with_different_shipment_type'));
                        error = true;
                        break;
                    }
                }
            }
            console.log('selectedPackIds : ', JSON.stringify(selectedPackIds));
            console.log('error : ', error);
            if (!error) {
                
                var retValue = 'SOL';
                //alert('selectedPackIds : '+selectedPackIds.length);
                //alert('shipmentType : '+shipmentType);
                if (selectedPackIds.length > 0) {
                    if (shipmentType == 'UPS') {
                        cmp.set("v.showShipComponent", true);
                        cmp.set("v.showUPSRestAPIcomp", true);
                        cmp.set("v.selectedPackIds", selectedPackIds);
                        
                        /*$A.createComponent("c:UPS",{
                  "packageId":selectedPackIds,
              }, function(newCmp, status, errorMessage){
                  //alert('Status : ' +status);
                  if (status === "SUCCESS") {
                      cmp.set("v.showShipComponent",true);
                      var body = cmp.find("mybody");
                      body.set("v.body", newCmp);
                  }
              });*/
          } else if (shipmentType == 'USPS') {
              if (selectedPackIds.length == 1){
                  cmp.set("v.showShipComponent", true);
                  cmp.set("v.showUSPSRestAPIcomp", true);
                  cmp.set("v.selectedPackIds", selectedPackIds);
              }else{
                  cmp.set("v.exceptionError", 'For USPS you can select only 1 package');
              }
              /* $A.createComponent("c:uSPS", {
              "packageId": selectedPackIds,
            }, function (newCmp, status, errorMessage) {
              if (status === "SUCCESS") {
                cmp.set("v.showShipComponent", true);
                var body = cmp.find("mybody");
                body.set("v.body", newCmp);
              }
              else {
                console.log("Error : ", errorMessage);
              }
            });*/
          } /*else if(shipmentType == 'FedEx'){
                    $A.createComponent("c:FedEx", {
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
                    });
                }*/
              else if (shipmentType == 'Canada Post') {
                  if (selectedPackIds.length == 1){
                      cmp.set("v.showShipComponent", true);
                      cmp.set("v.showCPRestAPIcomp", true);
                      cmp.set("v.selectedPackIds", selectedPackIds);
                  }else{
                      cmp.set("v.exceptionError", 'For USPS you can select only 1 package');
                  }
              }
            
                  else if (shipmentType == 'FedEx') {
                      //console.log('cmp.get("v.enableFedexRestAPI") : ',cmp.get("v.enableFedexRestAPI"));
                      //if(cmp.get("v.enableFedexRestAPI")){
                      cmp.set("v.showShipComponent", true);
                      cmp.set("v.showFedexRestAPIcomp", true);
                      cmp.set("v.selectedPackIds", selectedPackIds);
                      console.log('selectedPackIds : ', JSON.stringify(cmp.get("v.selectedPackIds")));
                      console.log('test');
                      /*}
            else{
                $A.createComponent("c:FedEx", {
                    "packageId":selectedPackIds,
                }, function(newcomponent, status, errorMessage){
                    //alert('Status in fedex : ' +status);
                    if (status === "SUCCESS") {
                        cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");
                        body.set("v.body", newcomponent);
                    }
                    else{
                        console.log("Error ==> ", errorMessage);
                    }
                });
            }*/
          }
            
            // else if (shipmentType == 'Sendle') {
            //   cmp.set("v.showShipComponent", true);
            //   cmp.set("v.showSendleAPI", true);
            //   cmp.set("v.selectedPackIds", selectedPackIds);
            //   console.log(shipmentType);
            // }
            
              else if (shipmentType == 'Sendle') {
                  $A.createComponent("c:sendle", {
                      "packageIds": selectedPackIds,
                  }, function (newCmp, status, errorMessage) {
                      //alert('Status in fedex : ' +status);
                      if (status === "SUCCESS") {
                          cmp.set("v.showShipComponent", true);
                          var body = cmp.find("mybody");
                          body.set("v.body", newCmp);
                      }
                      else {
                          console.log("Error : ", errorMessage);
                      }
                  });
              }
            
                  else if (shipmentType == 'DHL') {
                      $A.createComponent("c:DHL", {
                          "packageId": selectedPackIds,
                      }, function (newCmp, status, errorMessage) {
                          //alert('Status in fedex : ' +status);
                          if (status === "SUCCESS") {
                              cmp.set("v.showShipComponent", true);
                              var body = cmp.find("mybody");
                              body.set("v.body", newCmp);
                          }
                          else {
                              console.log("Error : ", errorMessage);
                          }
                      });
                      
                  }else if (shipmentType == 'Freight View') {
                console.log('selected Freight View');
                cmp.set("v.showShipComponent", true);
                cmp.set("v.selectedPackIds", selectedPackIds);
                cmp.set("v.showFreightViewComp", true);
            } else { //if(shipmentType == 'Shipment')
                       console.log("Is this internal shipment => ", shipmentType);
                      $A.createComponent("c:InternalShipment", {
                          "packageIDS": selectedPackIds,
                          "showHeader": false
                      }, function (newCmp, status, errorMessage) {
                          if (status === "SUCCESS") {
                              cmp.set("v.showShipComponent", true);
                              var body = cmp.find("mybody");
                              body.set("v.body", newCmp);
                          }
                      });
                  }
        }
          else cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_package'));
      }
    } catch (e) {
        console.log('errorr--' + e);
    }
  },
    
    createsingleShipment: function (cmp, event, helper) {
        try {
            console.log('entered createsingleShipment');
            cmp.set("v.exceptionError", "");
            var indx = event.currentTarget.getAttribute('data-index');
            var lineItemWrapperList = cmp.get("v.lineItemWrapperList");
            var sType = '';
            var error = false;
            var selectedPackIds = [];
            var shipmentType = '';
            
            if (indx != undefined && indx != null) {
                for (var x in lineItemWrapperList) {
                    if (x == indx) {
                        if (
                                (lineItemWrapperList[x].pack.Shipment__c == null 
                                    && lineItemWrapperList[x].pack.Logistic__r.Ready_To_Ship__c == true)
                                || lineItemWrapperList[x].pack.Status__c == 'Cancelled'
                            ) {
                            if (lineItemWrapperList[x].pack.Shipment_Type__c != undefined && lineItemWrapperList[x].pack.Shipment_Type__c != null && lineItemWrapperList[x].pack.Shipment_Type__c != '') {
                                sType = lineItemWrapperList[x].pack.Shipment_Type__c;
                            }
                            if (sType != '') {
                                selectedPackIds.push(lineItemWrapperList[x].pack.Id);
                                shipmentType = lineItemWrapperList[x].pack.Shipment_Type__c;
                            } else {
                                cmp.set("v.exceptionError", $A.get('$Label.c.Shipment_Type_not_defined_for_the_select_packages'));
                                error = true;
                            }
                        }
                        break;
                    }
                }
            }
            
            if (!error) {
                var retValue = 'SOL';
                console.log('selectedPackIds=>' + selectedPackIds.length);
                console.log('cmp.get()');
                if (selectedPackIds.length > 0) {
                    console.log('entered if');
                    if (shipmentType == 'UPS') {
                        cmp.set("v.showShipComponent", true);
                        cmp.set("v.showUPSRestAPIcomp", true);
                        cmp.set("v.selectedPackIds", selectedPackIds);
                        /*$A.createComponent("c:UPS",{
                  "packageId":selectedPackIds,
              }, function(newCmp, status, errorMessage){
                  //alert('Status : ' +status);
                  if (status === "SUCCESS") {
                      cmp.set("v.showShipComponent",true);
                      var body = cmp.find("mybody");
                      body.set("v.body", newCmp);
                  }
              });*/
          } else if (shipmentType == 'USPS') {
              if (selectedPackIds.length == 1){
                  cmp.set("v.showShipComponent", true);
                  cmp.set("v.showUSPSRestAPIcomp", true);
                  cmp.set("v.selectedPackIds", selectedPackIds);
              }else{
                  cmp.set("v.exceptionError", 'For USPS you can select only 1 package');
              }
              /* $A.createComponent("c:uSPS", {
              "packageId": selectedPackIds,
            }, function (newCmp, status, errorMessage) {
              if (status === "SUCCESS") {
                cmp.set("v.showShipComponent", true);
                var body = cmp.find("mybody");
                body.set("v.body", newCmp);
              }
              else {
                console.log("Error : ", errorMessage);
              }
            });*/
                        
                        
          } else if (shipmentType == 'Canada Post') {
              if (selectedPackIds.length == 1){
                  cmp.set("v.showShipComponent", true);
                  cmp.set("v.showCPRestAPIcomp", true);
                  cmp.set("v.selectedPackIds", selectedPackIds);
              }else{
                  cmp.set("v.exceptionError", 'For USPS you can select only 1 package');
              }
          }
              else if (shipmentType == 'FedEx') {
                  console.log('entered fedex shipment tyoe');
                  
                  /*$A.createComponent("c:FedEx", {
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
                  cmp.set("v.selectedPackIds", selectedPackIds)
                  cmp.set("v.showShipComponent", true);
                  cmp.set("v.showFedexRestAPIcomp", true);
                  
                  
              }  
              else if (shipmentType == 'Freight View') {
                console.log('selected Freight View');
                cmp.set("v.showShipComponent", true);
                cmp.set("v.selectedPackIds", selectedPackIds);
                cmp.set("v.showFreightViewComp", true);
            }
            
                  else if (shipmentType == 'Sendle') {
                      $A.createComponent("c:sendle", {
                          "packageIds": selectedPackIds,
                      }, function (newCmp, status, errorMessage) {
                          //alert('Status in fedex : ' +status);
                          if (status === "SUCCESS") {
                              cmp.set("v.showShipComponent", true);
                              var body = cmp.find("mybody");
                              body.set("v.body", newCmp);
                          }
                          else {
                              console.log("Error : ", errorMessage);
                          }
                      });
                  }
            
                      else if(shipmentType == 'Purolator'){
                          console.log('entered shipmentType =>'+shipmentType);
                          cmp.set("v.selectedPackIds", selectedPackIds);
                          console.log('c1='+cmp.get('v.selectedPackIds'));
                          cmp.set("v.showShipComponent", true);
                          console.log('c2='+cmp.get('v.showShipComponent'));
                          cmp.set("v.showPurolatorAPI", true);
                          console.log('c3='+cmp.get('v.showPurolatorAPI'));
                      }
                          else if (shipmentType == 'DHL') {
                              $A.createComponent("c:DHL", {
                                  "packageId": selectedPackIds,
                              }, function (newCmp, status, errorMessage) {
                                  //alert('Status in fedex : ' +status);
                                  if (status === "SUCCESS") {
                                      cmp.set("v.showShipComponent", true);
                                      var body = cmp.find("mybody");
                                      body.set("v.body", newCmp);
                                  }
                                  else {
                                      console.log("Error : ", errorMessage);
                                  }
                              });
                              
                    } else if (shipmentType == 'Freigt view') {
              if (selectedPackIds.length == 1){
                  cmp.set("v.showShipComponent", true);
                  cmp.set("v.showFreighViewcomp", true);
                  cmp.set("v.selectedPackIds", selectedPackIds);
              }else{
                  cmp.set("v.exceptionError", 'For USPS you can select only 1 package');
              }
          }
                    
                    else { //if(shipmentType == 'Shipment')
                              
                              $A.createComponent("c:InternalShipment", {
                                  "packageIDS": selectedPackIds,
                                  "showHeader": false
                              }, function (newCmp, status, errorMessage) {
                                  if (status === "SUCCESS") {
                                      cmp.set("v.showShipComponent", true);
                                      var body = cmp.find("mybody");
                                      body.set("v.body", newCmp);
                                  }
                              });
                    }
                     
        }
          else cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_the_package'));
      }
    } catch (e) {
        console.log('error-> shipment error' + e);
    }
  },
    
    editPack: function (cmp, event, helper) {
        //window.scrollTo(0,0);
        $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
        var packId = event.getSource().get("v.name");
        var action = cmp.get("c.editPackage");
        action.setParams({ pack2updateId: packId });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set('v.showShipAllbtton', false);
                cmp.set("v.PreventChange", true);
                cmp.set("v.fromedit", true);
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                cmp.set("v.createPack", response.getReturnValue().createPack);
                cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                cmp.set("v.lineItemWrapperList", response.getReturnValue().lineItemWrapperList);
                cmp.set("v.CustomerPresent", response.getReturnValue().CustomerPresent);
                cmp.set("v.isAwaiting", response.getReturnValue().isAwaiting);
                cmp.set("v.pkgTypeValue", response.getReturnValue().pkgTypeValue);
                cmp.set("v.PreventChange", false);
                $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action);
        
    },
    
    deletePack: function (cmp, event, helper) {
        var r = confirm('Are you sure you want to delete?');
        if (r == true) {
            //window.scrollTo(0,0);
            $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
            var packId = event.getSource().get("v.name");
            var logIds = cmp.get("v.logisticIds");
            var logisticIds = logIds.split(",");
            var LIds = JSON.stringify(logisticIds);
            
            var action = cmp.get("c.deletePackage");
            action.setParams({ pack2updateId: packId, LogisticIds: LIds });
            action.setCallback(this, function (response) {
                var state = response.getState();
                //alert(state);
                if (state === "SUCCESS") {
                    //alert(response.getReturnValue().exceptionError);
                    cmp.set("v.PreventChange", true);
                    //cmp.set("v.Container", response.getReturnValue());
                    cmp.set("v.SiteName", response.getReturnValue().SiteName);
                    cmp.set("v.Logistics", response.getReturnValue().LogisticRecs);
                    cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                    cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                    cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                    cmp.set("v.PreventChange", false);
                    
                    cmp.set("v.lineItemWrapperList", response.getReturnValue().lineItemWrapperList);
                    cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                    cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                    cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                    cmp.set("v.Customers", response.getReturnValue().Customers);
                    cmp.set("v.Customer", response.getReturnValue().Customer);
                    cmp.set("v.CustomerPresent", response.getReturnValue().CustomerPresent);
                    cmp.set("v.createPack", response.getReturnValue().createPack);
                    cmp.set("v.isAwaiting", response.getReturnValue().isAwaiting);
                    cmp.set("v.pkgTypeValue", response.getReturnValue().pkgTypeValue);
                    
                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                }
            });
            $A.enqueueAction(action);
            this.getAllDetails(cmp, event, helper);
        }
    },
    
    populatePkgDetail: function (cmp, event, helper) {
        var packType = event.getSource().get("v.value");
        var action = cmp.get("c.populatePackDetails");
        action.setParams({ Package2Create1: JSON.stringify(cmp.get("v.Package2Create")), pkgTypeValue: packType });
        action.setCallback(this, function (response) {
            var state = response.getState();
            //alert(state);
            if (state === "SUCCESS") {
                cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                cmp.set("v.PreventChange", true);
                cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                cmp.set("v.PreventChange", false);
            }
        });
        $A.enqueueAction(action);
        
    },
    
    fetchSOLIIs: function (cmp, event, helper) {
        var Package2Create = cmp.get("v.Package2Create");
        if (cmp.get("v.PreventChange") == false && Package2Create.Logistic__c != undefined && Package2Create.Logistic__c != '') {
            //window.scrollTo(0,0);
            $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
            var logIds = Package2Create.Logistic__c;
            var logisticIds = logIds.split(",");
            var LIds = JSON.stringify(logisticIds);
            var action = cmp.get("c.createPacksInit");
            action.setParams({ LogisticIds: LIds, Customer: '' });
            action.setCallback(this, function (response) {
                var state = response.getState();
                //alert(state);
                if (state === "SUCCESS") {
                    //alert(response.getReturnValue().exceptionError);
                    cmp.set("v.PreventChange", true);
                    //cmp.set("v.Container", response.getReturnValue());
                    cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                    cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                    cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                    cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                    cmp.set("v.Customers", response.getReturnValue().Customers);
                    cmp.set("v.Customer", response.getReturnValue().Customer);
                    cmp.set("v.CustomerPresent", response.getReturnValue().CustomerPresent);
                    //cmp.set("v.createPack", response.getReturnValue().createPack);
                    //cmp.set("v.isAwaiting", response.getReturnValue().isAwaiting);
                    cmp.set("v.pkgTypeValue", response.getReturnValue().pkgTypeValue);
                    cmp.set("v.PreventChange", false);
                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    processDetails: function (cmp, event, helper) {
        var Package2Create = cmp.get("v.Package2Create");
        var packageWrapperList = cmp.get("v.packageWrapperList");
        Package2Create.Weight__c = Package2Create.Declared_Value__c = 0;
        for (var x in packageWrapperList) {
            if (packageWrapperList[x].pkgSelected == false && (packageWrapperList[x].qtyToPack == '' || packageWrapperList[x].qtyToPack == null || packageWrapperList[x].qtyToPack == undefined)) {
                packageWrapperList[x].qtyToPack = 0;
                cmp.set('v.exceptionError', $A.get('$Label.c.Pack_qty_cannot_be_null'));
                
            }
            else if (packageWrapperList[x].pkgSelected == true && packageWrapperList[x].qtyToPack < 0) {
                // packageWrapperList[x].qtyToPack = 0;
                cmp.set('v.exceptionError', $A.get('$Label.c.Pack_qty_cannot_be_less_than_zero'));
                
            }
            if (packageWrapperList[x].loli.Product__r.Weight__c >= 0) Package2Create.Weight__c += (packageWrapperList[x].loli.Product__r.Weight__c * packageWrapperList[x].qtyToPack);
            if (packageWrapperList[x].loli.Price_Product__c >= 0) Package2Create.Declared_Value__c += (packageWrapperList[x].loli.Price_Product__c * packageWrapperList[x].qtyToPack);
        }
        cmp.set("v.PreventChange", true);
        cmp.set("v.Package2Create", Package2Create);
        cmp.set("v.PreventChange", false);
        cmp.set("v.packageWrapperList", packageWrapperList);
    },
    
    cancelPack: function (cmp, event, helper) {
        console.log('in cancelPack');
       /* cmp.set("v.createPack", false);
        cmp.set("v.showShipComponent", false);
        cmp.set("v.isAwaiting", true);*/
        var logId = '';
        try{
            logId = cmp.get("v.logisticIds");
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
    
    updatePack: function (cmp, event, helper) {
        var Package2Create = cmp.get("v.Package2Create");
        var packageWrapperList = cmp.get("v.packageWrapperList");
        var packageWrapperListjs = JSON.stringify(packageWrapperList);
        var logIds = cmp.get("v.logisticIds");
        var logisticIds = logIds.split(",");
        var LIds = JSON.stringify(logisticIds);
        var packlist = [];
        console.log('allowZerodeclaredValue : ', cmp.get("v.allowZerodeclaredValue"));
        /*
    var WeightStr = document.getElementById("WeightStr").value;
    var doubleWeight = 0.00;
    if (typeof WeightStr === 'string' || WeightStr instanceof String) doubleWeight = Number(WeightStr.replace(/[^0-9\.]+/g,""));
    else doubleWeight = WeightStr;
    Package2Create.Weight__c = doubleWeight;
    */
        var errMSG = cmp.get("v.errorMsg2");
        var exMSG = cmp.get("v.exceptionError");
        if (errMSG != null && errMSG != '' && errMSG != undefined && errMSG == 'Sorry, selected package type not available.') {
            cmp.set("v.exceptionError", $A.get('$Label.c.Please_select_a_diffrent_package_type_or_set_up_the_required_data'));
            return;
        }
        var error = false;
        for (var x in packageWrapperList) {
            if (packageWrapperList[x].pkgSelected == true) {
                packlist.push(packageWrapperList[x]);
            }
            if (packageWrapperList[x].qtyToPack > packageWrapperList[x].qtyToPick && packageWrapperList[x].pkgSelected == true) {
                cmp.set("v.errorMsg2", $A.get('$Label.c.Packed_quantity_cannot_be_greater_than_picked_Quantity'));
                error = true;
                break;
            }
            if (packageWrapperList[x].qtyToPack < 0 && packageWrapperList[x].pkgSelected == true) {
                cmp.set("v.exceptionError", $A.get('$Label.c.Packed_quantity_cannot_be_less_than_Zero'));
                error = true;
                break;
            }
            if ((packageWrapperList[x].qtyToPack == '' || packageWrapperList[x].qtyToPack == null || packageWrapperList[x].qtyToPack == undefined || packageWrapperList[x].qtyToPack == 0) && packageWrapperList[x].pkgSelected == true) {
                cmp.set("v.exceptionError", $A.get('$Label.c.Packed_quantity_cannot_be_less_than_Or_equal_to_Zero'));
                error = true;
                break;
            }
            
            
        }
        if (packlist.length == 0 && cmp.get("v.fromedit") == false) {
            error = true;
            cmp.set("v.errorMsg2", $A.get('$Label.c.PH_RMA_PACK_Select_atleast_one_line_item_to_create_package'));
        }
        if (Package2Create.Package_Type__c == '' || Package2Create.Package_Type__c == null || Package2Create.Package_Type__c == undefined) {
            cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_package_type'));
            error = true;
            return;
        }
        else if (Package2Create.Length__c <= 0 || Package2Create.Length__c == null || Package2Create.Length__c == undefined) {
            cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_length_of_the_package'));
            error = true;
            return;
        }
            else if (Package2Create.Width__c <= 0 || Package2Create.Width__c == null || Package2Create.Width__c == undefined) {
                cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_Width_of_the_package'));
                error = true;
                return;
            }
                else if (Package2Create.Height__c <= 0 || Package2Create.Height__c == null || Package2Create.Height__c == undefined) {
                    cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_height_of_the_package'));
                    error = true;
                    return;
                }
                    else if (Package2Create.Weight__c <= 0 || Package2Create.Weight__c == null || Package2Create.Weight__c == undefined) {
                        cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_weight_of_the_package'));
                        error = true;
                        return;
                    }
                        else if ((Package2Create.Declared_Value__c == null || Package2Create.Declared_Value__c == undefined) && cmp.get("v.allowZerodeclaredValue") == false) {
                            cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_declared_value_of_the_package'));
                            error = true;
                            return;
                        }
                            else if (Package2Create.Declared_Value__c <= 0 && cmp.get("v.allowZerodeclaredValue") == false) {
                                cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_declared_value_of_the_package'));
                                error = true;
                                return;
                            }
                                else if (Package2Create.Shipment_Type__c == '' || Package2Create.Shipment_Type__c == null || Package2Create.Shipment_Type__c == undefined || Package2Create.Shipment_Type__c == '--None--') {
                                    cmp.set("v.exceptionError", $A.get('$Label.c.Please_enter_the_shipment_type_of_the_package'));
                                    error = true;
                                    return;
                                }else if (Package2Create.Shipment_Type__c != '' && Package2Create.Shipment_Type__c != null && Package2Create.Shipment_Type__c != undefined && Package2Create.Shipment_Type__c == 'USPS' && Package2Create.Declared_Value__c >999999.99) {
                                    cmp.set("v.exceptionError", 'The declared value for USPS must be less than 999999.99');
                                    error = true;
                                    return;
                                }else if (Package2Create.Shipment_Type__c != '' && Package2Create.Shipment_Type__c != null && Package2Create.Shipment_Type__c != undefined && Package2Create.Shipment_Type__c == 'Canada Post' && Package2Create.Declared_Value__c >99999.99) {
                                    cmp.set("v.exceptionError", 'The declared value for Canada Post must be less than 999999.99');
                                    error = true;
                                    return;
                                }
        if (!error) {
            //window.scrollTo(0,0);
            $A.util.removeClass(cmp.find('mainSpin'), "slds-hide");
            var action = cmp.get("c.updatePacks");
            action.setParams({ Package2Create1: JSON.stringify(Package2Create), PackageWrapperListJs: packageWrapperListjs, LogisticIds: LIds, IsAwaiting: cmp.get("v.isAwaiting") });
            action.setCallback(this, function (response) {
                var state = response.getState();
                //alert(state);
                if (state === "SUCCESS") {
                    cmp.set("v.PreventChange", true);
                    cmp.set("v.Container", response.getReturnValue());
                    cmp.set("v.SiteName", response.getReturnValue().SiteName);
                    cmp.set("v.Logistics", response.getReturnValue().LogisticRecs);
                    cmp.set("v.currentEmployee", response.getReturnValue().Employee);
                    cmp.set("v.selectedSite", response.getReturnValue().selectedSite);
                    cmp.set("v.exceptionError", response.getReturnValue().exceptionError);
                    
                    cmp.set("v.lineItemWrapperList", response.getReturnValue().lineItemWrapperList);
                    cmp.set("v.packageWrapperList", response.getReturnValue().packageWrapperList);
                    cmp.set("v.Package2Create", response.getReturnValue().Package2Create);
                    cmp.set("v.errorMsg2", response.getReturnValue().errorMsg2);
                    cmp.set("v.Customers", response.getReturnValue().Customers);
                    cmp.set("v.Customer", response.getReturnValue().Customer);
                    cmp.set("v.CustomerPresent", response.getReturnValue().CustomerPresent);
                    cmp.set("v.createPack", response.getReturnValue().createPack);
                    cmp.set("v.isAwaiting", response.getReturnValue().isAwaiting);
                    cmp.set("v.pkgTypeValue", response.getReturnValue().pkgTypeValue);
                    cmp.set("v.PreventChange", false);
                    $A.util.addClass(cmp.find('mainSpin'), "slds-hide");
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    
    
    setScriptLoaded: function (cmp, event, helper) {
        
    },
    
    Back2Outbound: function (cmp, event, helper) {
        $A.createComponent("c:OutboundLogistics", {
        }, function (newCmp, status, errorMessage) {
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
    
    createPicks: function (cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Pick", {
            "logisticIds": logIds
        }, function (newCmp, status, errorMessage) {
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
    
    createPacks: function (cmp, event, helper) {
        var logIds = cmp.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:Pack", {
            "logisticIds": logIds
        }, function (newCmp, status, errorMessage) {
            if (status === "SUCCESS") {
                var body = cmp.find("body");
                body.set("v.body", newCmp);
            }
        });
        
    },
    
    
    
    focusTOscan: function (component, event, helper) {
        component.set("v.scanValue", '');
        helper.focusTOscan(component, event);
        
    },
    
    verifyScanCode: function (cmp, event, helper) {
        var scan_Code = cmp.get("v.scanValue");
        var mybarcode = scan_Code;
        if (mybarcode != '') {
            cmp.set("v.exceptionError", '');
            //alert(mybarcode);
            if (mybarcode == 'ORDER') { cmp.Back2Outbound(); }
            else if (mybarcode == 'PICK') { cmp.createPicks(); }
                else if (mybarcode == 'PACK') { cmp.createPacks(); }
                    else if (mybarcode == 'SAVE') { if (cmp.get("v.createPack")) cmp.updatePack(); else cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Invalid_barcode_scanned')); }
                        else if (mybarcode == 'SHIP') { cmp.createShips(); }
                            else {
                                cmp.set("v.exceptionError", $A.get('$Label.c.PH_OB_Invalid_barcode_scanned'));
                            }
            cmp.set("v.scanValue", '');
        }
    },
    
    closeError: function (cmp, event) {
        cmp.set("v.exceptionError", '');
    },
    
    StillToFulfill: function (component, event) {
        var logIds = component.get("v.logisticIds");
        //var RecUrl = "/apex/PickLC?core.apexpages.devmode.url=1&loId=" + logId;
        //window.open(RecUrl,'_self');
        $A.createComponent("c:StillToFulfillLightning", {
            "logisticIds": logIds
        }, function (newCmp, status, errorMessage) {
            
            if (status === "SUCCESS") {
                // $A.util.removeClass(component.find('mainSpin'), "slds-hide");
                var body = component.find("body");
                body.set("v.body", newCmp);
            }
        });
    },
    parentFieldChange: function (component, event, helper) {
        console.log('parentFieldChange : ', component.get("v.Package2Create.Shipment_Type__c"));
        //var controllerValue = component.find("parentField").get("v.value");// We can also use event.getSource().get("v.value")
        var pickListMap = component.get("v.depnedentFieldMap");
        console.log('pickListMap : ' + pickListMap);
        var controllerValue = component.get("v.Package2Create.Shipment_Type__c");
         console.log('controllerValue : ' + controllerValue);
        if (controllerValue != '--None--' && controllerValue != undefined && controllerValue != null && controllerValue != '' && pickListMap != null && pickListMap != undefined) {
            console.log('in parent');
            //get child picklist value
            var childValues = pickListMap[controllerValue];
            var childValueList = [];
            // childValueList.push('--None--');
            for (var i in childValues) {
                childValueList.push(childValues[i]);
            }
            // set the child list
            component.set("v.listDependingValues", childValueList);
            
            if (childValues.length > 0) {
                component.set("v.bDisabledDependentFld", false);
            } else {
                component.set("v.bDisabledDependentFld", true);
            }
            
        } else {
            component.set("v.listDependingValues", ['Package']);
            component.set("v.bDisabledDependentFld", true);
        }
    },
})