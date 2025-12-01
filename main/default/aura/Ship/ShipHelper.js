({
	focusTOscan: function (component, event) {
        console.log('focusTOscan helper called');
        $(document).ready(function () {
            component.set("v.scanValue", '');
            var barcode = "";
            var pressed = false;
            var chars = [];
                        //added by zain
            $(window).off("keypress");
            $(window).off("keydown");
            $(window).keypress(function (e) {
                  var tagName = e.target.tagName ? e.target.tagName.toUpperCase() : "";
            if (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT' || tagName === 'LIGHTNING-INPUT') {
                return;
            }
                
                $(".scanMN").keypress(function (e) {
                    e.stopPropagation()
                });
                
                chars.push(String.fromCharCode(e.which));
                
            }); // end of window key press function         
            
            $(window).keydown(function (e) {
                if (e.which === 13) {
                      var tagName = e.target.tagName ? e.target.tagName.toUpperCase() : "";
            if (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT' || tagName === 'LIGHTNING-INPUT') {
                return;
            }   
                    e.preventDefault();
                    if (pressed == false) {
                    setTimeout(
                        function () {
                            pressed = false;//ss
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
                }
            });
        });
    },
       
    createShipment1 : function(cmp, event, shipmentId) {
        var shipId = shipmentId;
        var shipmentType = '';
        var obj = cmp.get("v.shipmentWrapperList");
        for(var x in obj) if(obj[x].shipM.Id == shipId) shipmentType = obj[x].shipmentType;
        var retValue = 'SOL'; 
        if(shipId != undefined && shipId != '' && shipId != null) { 
            if(shipmentType == 'UPS'){
                cmp.set("v.exceptionError", '');
                $A.createComponent("c:UPS", {
                    "shipmentId":shipId,
                }, function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        cmp.set("v.showShipComponent",true);
                        //cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");                            
                        body.set("v.body", newCmp);  
                    }
                });
            } else if(shipmentType == 'USPS'){
                
            } else if(shipmentType == 'FedEx'){
                cmp.set("v.exceptionError", '');
                $A.createComponent("c:FedEx", {
                    "shipmentId":shipId,
                }, function(newCmp, status, errorMessage){
                    if (status === "SUCCESS") {
                        cmp.set("v.showShipComponent",true);
                        var body = cmp.find("mybody");                            
                        body.set("v.body", newCmp);  
                    }
                });
            } else if(shipmentType == 'DHL'){
                
            } else { 
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
})