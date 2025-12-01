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
                //added by zain
                var tagName = e.target.tagName ? e.target.tagName.toUpperCase() : "";
            if (tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT' || tagName === 'LIGHTNING-INPUT') {
                return;
            }
               
                if (e.which === 13) {
                    e.preventDefault();
                    if (pressed == false) {
                    setTimeout(
                        function () {
                            pressed = false;
                            if (chars.length >= 3) {
                            barcode = chars.join("");
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
    
    getLogisticRecords : function(component, event, helper) {
         $A.util.removeClass(component.find('mainSpin'), "slds-hide");
       
    	 var action = component.get("c.fetchSortedLogistics");
        action.setParams({
            "OrderBy":component.get("v.OrderBy"),
            "SortOrder":component.get("v.Order"),
            'DcId' : component.get("v.selectedSite"),
            'ChId' : component.get("v.currentEmployee.Channel__c"),
            'Show' : component.get("v.show"),
            'Offset' : 0,
            'filter' :component.get("v.filtertype")
        }); 
        
        action.setCallback(this, function(response) {
                    var state = response.getState();
            if (state === "SUCCESS") {
                 component.set("v.PreventChange", true);
                component.set("v.Container", response.getReturnValue());
                component.set("v.currentEmployee", response.getReturnValue().Employee);
                //component.find("Site").set("v.options", response.getReturnValue().channelSites);
                component.set("v.SiteOptions",response.getReturnValue().channelSites);
                component.set("v.selectedSite", response.getReturnValue().selectedSite);
                component.set("v.exceptionError", response.getReturnValue().exceptionError);
                component.set("v.PreventChange", false);
                $A.util.addClass(component.find('mainSpin'), "slds-hide");
            }
        });
        $A.enqueueAction(action);
                           
        
    }
})