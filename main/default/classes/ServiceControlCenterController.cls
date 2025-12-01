public with sharing class ServiceControlCenterController {
    @AuraEnabled(cacheable=true)
    public static List<BOMLineWrapper> getBOMItems(Id workOrderId) {
        List<BOMLineWrapper> wrappers = new List<BOMLineWrapper>();
        
        try {
            if (workOrderId == null) {
                System.debug('No workOrderId provided');
                return wrappers;
            }
            
            System.debug('Fetching MRP for workOrderId: ' + workOrderId);
            
            List<MRP__c> mrpRecords = [
                SELECT Id, Name, Status__c, Consumed_Quantity__c, Total_Amount_Required__c, Fulfilled_Amount__c,
                       MRP_Product__c, MRP_Product__r.Name, MRP_Product__r.ProductCode, MRP_Product__r.Serialise__c,
                       MRP_Product__r.QuantityUnitOfMeasure, MRP_Product__r.Available_Stock__c,
                       Work_Order__c, Work_Order__r.Name, Notes__c
                FROM MRP__c 
                WHERE Work_Order__c = :workOrderId
                ORDER BY MRP_Product__r.Name
            ];
            
            System.debug('Found ' + mrpRecords.size() + ' MRP records for workOrderId: ' + workOrderId);
            
            for (MRP__c mrp : mrpRecords) {
                BOMLineWrapper wrapper = new BOMLineWrapper();
                wrapper.id = mrp.Id;
                wrapper.name = mrp.Name; // Using MRP record name instead of BOM Line name
                wrapper.product = mrp.MRP_Product__r.Name; 
                wrapper.productCode = mrp.MRP_Product__r.ProductCode;
                wrapper.status = mrp.Status__c;
                wrapper.qty = mrp.Total_Amount_Required__c != null ? mrp.Total_Amount_Required__c : 0;
                wrapper.uom = mrp.MRP_Product__r.QuantityUnitOfMeasure; // Using QuantityUnitOfMeasure field
                wrapper.fulfilled = mrp.Fulfilled_Amount__c != null ? mrp.Fulfilled_Amount__c : 0;
                wrapper.consumed = mrp.Consumed_Quantity__c != null ? mrp.Consumed_Quantity__c : 0;
                wrapper.stock = mrp.MRP_Product__r.Available_Stock__c != null ? mrp.MRP_Product__r.Available_Stock__c : 0;
                wrapper.mainProduct = mrp.Work_Order__r.Name; // Using Work Order name as main product
                wrapper.serial = mrp.MRP_Product__r.Serialise__c;
                
                wrappers.add(wrapper);
            }
            
        } catch (Exception e) {
            System.debug('Error in getBOMItems: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching BOM items: ' + e.getMessage());
        }
        return wrappers;
    }

    @AuraEnabled(cacheable=true)
    public static List<ActionWrapper> getActions(Id workOrderId) {
        List<ActionWrapper> wrappers = new List<ActionWrapper>();
        
        try {
            if (workOrderId == null) {
                System.debug('No workOrderId provided');
                return wrappers;
            }
            
            System.debug('Fetching Actions for workOrderId: ' + workOrderId);
            
            List<Actions_Tasks__c> actionRecords = [
                SELECT Id, Name, Status__c, Description__c
                FROM Actions_Tasks__c 
                WHERE Work_Order__c = :workOrderId
                ORDER BY Name
            ];
            
            System.debug('Found ' + actionRecords.size() + ' Action records for workOrderId: ' + workOrderId);
            
            for (Actions_Tasks__c action : actionRecords) {
                ActionWrapper wrapper = new ActionWrapper();
                wrapper.id = action.Id;
                wrapper.name = action.Name;
                wrapper.status = action.Status__c;
                wrapper.description = action.Description__c;
                wrappers.add(wrapper);
            }
            
        } catch (Exception e) {
            System.debug('Error in getActions: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching actions: ' + e.getMessage());
        }
        return wrappers;
    }

    @AuraEnabled
    public static void updateAction(Id actionId, String status, String description, Id consumeMRPId, Decimal consumeQty) {
        try {
            Actions_Tasks__c action = new Actions_Tasks__c(Id = actionId);
            if (status != null) {
                action.Status__c = status;
            }
            if (description != null) {
                action.Description__c = description;
            }
            // update action;
            List<SObject> safeaction = FLSHelper.getSafeRecords(
    new List<SObject>{action}, // record if the items are just list
    'Actions_Tasks__c',
    AccessType.UPDATABLE
);
List<Actions_Tasks__c> typedaction = new List<Actions_Tasks__c>();
for (SObject s : safeaction) {
    typedaction.add((Actions_Tasks__c)s);
}
if (!typedaction.isEmpty()) {
    update typedaction;
}


            // Handle consumption if provided
            if (consumeMRPId != null && consumeQty != null && consumeQty > 0) {
                MRP__c mrp = [SELECT Id, Consumed_Quantity__c, Fulfilled_Amount__c, Total_Amount_Required__c, Status__c 
                              FROM MRP__c WHERE Id = :consumeMRPId LIMIT 1];
                if (mrp.Consumed_Quantity__c == null) mrp.Consumed_Quantity__c = 0;
                mrp.Consumed_Quantity__c += consumeQty;
                if (mrp.Consumed_Quantity__c >= mrp.Total_Amount_Required__c) {
                    mrp.Status__c = 'Committed';
                }
                update mrp;
            }

            // Update related task
            List<Task> relatedTasks = [SELECT Id, Description, Status FROM Task WHERE WhatId = :actionId LIMIT 1];
            if (!relatedTasks.isEmpty()) {
                Task task = relatedTasks[0];
                if (status != null) {
                    task.Status = status;
                }
                if (description != null) {
                    task.Description = description;
                }
                update task;
            }

            // Check if all actions are completed
            Actions_Tasks__c updatedAction = [SELECT Work_Order__c FROM Actions_Tasks__c WHERE Id = :actionId LIMIT 1];
            Id woId = updatedAction.Work_Order__c;

            List<Actions_Tasks__c> allActions = [SELECT Status__c FROM Actions_Tasks__c WHERE Work_Order__c = :woId];
            Boolean allActionsCompleted = true;
            for (Actions_Tasks__c a : allActions) {
                if (a.Status__c != 'Completed') {
                    allActionsCompleted = false;
                    break;
                }
            }

            List<MRP__c> allMRPs = [SELECT Consumed_Quantity__c, Total_Amount_Required__c FROM MRP__c WHERE Work_Order__c = :woId];
            Boolean allMRPsConsumed = true;
            for (MRP__c m : allMRPs) {
                Decimal consumed = m.Consumed_Quantity__c != null ? m.Consumed_Quantity__c : 0;
                if (consumed < m.Total_Amount_Required__c) {
                    allMRPsConsumed = false;
                    break;
                }
            }

            if (allActionsCompleted && allMRPsConsumed) {
                WO__c wo = new WO__c(Id = woId, Status__c = 'Complete');
                update wo;
            }

        } catch (Exception e) {
            System.debug('Error in updateAction: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error updating action: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getProductIdByName(String productName) {
        try {
            List<Product2> products = [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1];
            
            if (!products.isEmpty()) {
                System.debug('Found product Id: ' + products[0].Id + ' for name: ' + productName);
                return products[0].Id;
            } else {
                System.debug('No product found with name: ' + productName);
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in getProductIdByName: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching product Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getWorkOrderIdByName(String woName) {
        try {
            List<WO__c> workOrders = [SELECT Id FROM WO__c WHERE Name = :woName LIMIT 1];
            
            if (!workOrders.isEmpty()) {
                System.debug('Found work order Id: ' + workOrders[0].Id + ' for name: ' + woName);
                return workOrders[0].Id;
            } else {
                System.debug('No work order found with name: ' + woName);
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in getWorkOrderIdByName: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching work order Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getCustomerIdByName(String customerName) {
        try {
            List<Account> customers = [SELECT Id FROM Account WHERE Name = :customerName LIMIT 1];
            
            if (!customers.isEmpty()) {
                return customers[0].Id;
            } else {
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching customer Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getWorkCenterIdByName(String workCenterName) {
        try {
            if (String.isBlank(workCenterName)) {
                return null;
            }
            
            List<Work_Center__c> workCenters = [SELECT Id , Name FROM Work_Center__c WHERE Name = :workCenterName LIMIT 1];
            
            if (!workCenters.isEmpty()) {
                System.debug('Found work center Id: ' + workCenters[0].Id + ' for name: ' + workCenterName);
                return workCenters[0].Id;
            } else {
                System.debug('No work center found with name: ' + workCenterName);
                return null;
            }
        } catch (Exception e) {
            System.debug('Error in getWorkCenterIdByName: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching work center Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getWarehouseIdByName(String warehouseName) {
        try {
            if (String.isBlank(warehouseName)) {
                return null;
            }
            
            List<Site__c> warehouses = [SELECT Id FROM Site__c WHERE Name = :warehouseName LIMIT 1]; // Adjust object name if different
            
            if (!warehouses.isEmpty()) {
                return warehouses[0].Id;
            } else {
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching warehouse Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Id getResourceIdByName(String resourceName) {
        try {
            if (String.isBlank(resourceName)) {
                return null;
            }
            
            List<Resource__c> resources = [SELECT Id FROM Resource__c WHERE Name = :resourceName LIMIT 1]; // Adjust object name if different
            
            if (!resources.isEmpty()) {
                return resources[0].Id;
            } else {
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching resource Id: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<BOMOptionWrapper> getBOMLineItems() {
        List<BOMOptionWrapper> options = new List<BOMOptionWrapper>();
        
        try {
            List<Product2> products = [
                SELECT Id, Name, ProductCode, QuantityUnitOfMeasure
                FROM Product2 
                WHERE IsActive = true
                ORDER BY Name
                LIMIT 1000
            ];
            
            for (Product2 product : products) {
                BOMOptionWrapper wrapper = new BOMOptionWrapper();
                wrapper.label = product.Name + ' - ' + (product.ProductCode != null ? product.ProductCode : 'No Code');
                wrapper.value = product.Id;
                options.add(wrapper);
            }
            
        } catch (Exception e) {
            System.debug('Error in getBOMLineItems: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error fetching BOM line items: ' + e.getMessage());
        }
        return options;
    }

    @AuraEnabled
    public static String createMRPRecord(Map<String, Object> mrpData) {
        try {
            MRP__c newMRP = new MRP__c();
            
            if (mrpData.containsKey('Name') && String.isNotBlank((String)mrpData.get('Name'))) {
                newMRP.Name = (String) mrpData.get('Name');
            }
            if (mrpData.containsKey('MRP_Product__c')) {
                newMRP.MRP_Product__c = (String) mrpData.get('MRP_Product__c');
            }
            if (mrpData.containsKey('Total_Amount_Required__c')) {
                newMRP.Total_Amount_Required__c = (Decimal) mrpData.get('Total_Amount_Required__c');
            }
            if (mrpData.containsKey('Work_Order__c')) {
                newMRP.Work_Order__c = (String) mrpData.get('Work_Order__c');
            }
            if (mrpData.containsKey('Work_Center__c')) {
                newMRP.Work_Center__c = (String) mrpData.get('Work_Center__c');
            }
            if (mrpData.containsKey('Notes__c')) {
                newMRP.Notes__c = (String) mrpData.get('Notes__c');
            }
            
            newMRP.Status__c = 'Requested';
            
            insert newMRP;
            return newMRP.Id;
            
        } catch (Exception e) {
            System.debug('Error creating MRP record: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error creating MRP record: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateMRPRecord(Map<String, Object> mrpData) {
        try {
            Id mrpId = (Id) mrpData.get('id');
            MRP__c mrp = [SELECT Id, Name, MRP_Product__c, Total_Amount_Required__c, Notes__c FROM MRP__c WHERE Id = :mrpId LIMIT 1];
            
            if (mrpData.containsKey('Name')) {
                mrp.Name = (String) mrpData.get('Name');
            }
            if (mrpData.containsKey('Total_Amount_Required__c')) {
                mrp.Total_Amount_Required__c = (Decimal) mrpData.get('Total_Amount_Required__c');
            }
            if (mrpData.containsKey('Notes__c')) {
                mrp.Notes__c = (String) mrpData.get('Notes__c');
            }
            
            update mrp;
        } catch (Exception e) {
            System.debug('Error updating MRP record: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error updating MRP record: ' + e.getMessage());
        }
    }

    public class BOMLineWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String product;
        @AuraEnabled public String productCode;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal qty;
        @AuraEnabled public String uom;
        @AuraEnabled public Decimal fulfilled;
        @AuraEnabled public Decimal consumed;
        @AuraEnabled public Decimal stock;
        @AuraEnabled public String mainProduct; 
        @AuraEnabled public Boolean serial;
    }

    public class ActionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String description;
    }

    public class BOMOptionWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductSearchWrapper> searchProducts(String searchTerm) {
        List<ProductSearchWrapper> results = new List<ProductSearchWrapper>();
        
        try {
            if (String.isBlank(searchTerm)) {
                // Return some default products when no search term
                List<Product2> defaultProducts = [
                    SELECT Id, Name, ProductCode, Description, IsActive, QuantityUnitOfMeasure, Available_Stock__c
                    FROM Product2 
                    WHERE IsActive = true
                    ORDER BY Name
                    LIMIT 10
                ];
                
                for (Product2 product : defaultProducts) {
                    ProductSearchWrapper wrapper = new ProductSearchWrapper();
                    wrapper.Id = product.Id;
                    wrapper.Name = product.Name;
                    wrapper.ProductCode = product.ProductCode != null ? product.ProductCode : 'No Code';
                    wrapper.Description = product.Description;
                    wrapper.IsActive = product.IsActive;
                    wrapper.QuantityUnitOfMeasure = product.QuantityUnitOfMeasure;
                    wrapper.AvailableStock = product.Available_Stock__c;
                    results.add(wrapper);
                }
                return results;
            }
            
            String searchQuery = '%' + searchTerm + '%';
            
            List<Product2> products = [
                SELECT Id, Name, ProductCode, Description, IsActive, QuantityUnitOfMeasure, Available_Stock__c
                FROM Product2 
                WHERE (Name LIKE :searchQuery OR ProductCode LIKE :searchQuery)
                   AND IsActive = true
                ORDER BY Name
                LIMIT 50
            ];
            
            for (Product2 product : products) {
                ProductSearchWrapper wrapper = new ProductSearchWrapper();
                wrapper.Id = product.Id;
                wrapper.Name = product.Name;
                wrapper.ProductCode = product.ProductCode != null ? product.ProductCode : 'No Code';
                wrapper.Description = product.Description;
                wrapper.IsActive = product.IsActive;
                wrapper.QuantityUnitOfMeasure = product.QuantityUnitOfMeasure;
                wrapper.AvailableStock = product.Available_Stock__c;
                results.add(wrapper);
            }
            
        } catch (Exception e) {
            System.debug('Error in searchProducts: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error searching products: ' + e.getMessage());
        }
        return results;
    }

    public class ProductSearchWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String ProductCode;
        @AuraEnabled public String Description;
        @AuraEnabled public Boolean IsActive;
        @AuraEnabled public String QuantityUnitOfMeasure;
        @AuraEnabled public Decimal AvailableStock;
    }
    
    @AuraEnabled
    public static void deleteAction(Id actionId) {
        try {
            if (actionId == null) {
                throw new AuraHandledException('Action ID is required');
            }
            
            // First, find and delete related tasks
            List<Task> relatedTasks = [SELECT Id FROM Task WHERE WhatId = :actionId];
            
            // Delete tasks first (due to foreign key constraints)
            if (!relatedTasks.isEmpty()) {
                delete relatedTasks;
            }
            
            // Then delete the action
            Actions_Tasks__c actionToDelete = new Actions_Tasks__c(Id = actionId);
            delete actionToDelete;
            
        } catch (Exception e) {
            System.debug('Error in deleteAction: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error deleting action: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void createAction(Map<String, Object> actionData) {
        try {
            // Validate required fields
            if (!actionData.containsKey('name') || String.isBlank((String)actionData.get('name'))) {
                throw new AuraHandledException('Action name is required');
            }
            
            if (!actionData.containsKey('workOrderId') || String.isBlank((String)actionData.get('workOrderId'))) {
                throw new AuraHandledException('Work Order ID is required');
            }
            
            String actionName = (String) actionData.get('name');
            String status = (String) actionData.get('status');
            String description = (String) actionData.get('description');
            String workOrderId = (String) actionData.get('workOrderId');
            String workCenterId = (String) actionData.get('workCenterId');
            
            // Create new Action record
            Actions_Tasks__c newAction = new Actions_Tasks__c();
            newAction.Name = actionName;
            newAction.Status__c = status;
            newAction.Description__c = description;
            newAction.Work_Order__c = workOrderId;
            
            // Only set Work Center if we have a valid ID
            if (String.isNotBlank(workCenterId)) {
                newAction.Work_Center__c = workCenterId;
            }
            
            insert newAction;
            
            // Create associated Task record
            Task newTask = new Task();
            newTask.Subject = actionName + ' - Task';
            newTask.Status = status != null ? status : 'Not Started';
            newTask.Description = description;
            newTask.WhatId = newAction.Id; // Link to the Action record
            newTask.ActivityDate = Date.today().addDays(7); // Default due date 7 days from now
            
            insert newTask;
            
        } catch (Exception e) {
            System.debug('Error in createAction: ' + e.getMessage() + ' at ' + e.getLineNumber());
            throw new AuraHandledException('Error creating action: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Note> getNotes(Id parentId) {
        try {
            if (parentId == null) {
                return new List<Note>();
            }
            return [SELECT Id, Title, Body, LastModifiedDate, CreatedBy.Name 
                    FROM Note 
                    WHERE ParentId = :parentId 
                    ORDER BY LastModifiedDate DESC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching notes: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createNote(String title, String body, Id parentId) {
        try {
            if (String.isBlank(title) || String.isBlank(body) || parentId == null) {
                throw new AuraHandledException('Title, body, and parent ID are required');
            }
            Note newNote = new Note(
                Title = title,
                Body = body,
                ParentId = parentId
            );
            insert newNote;
            return newNote.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating note: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocument> getAttachments(Id parentId) {
        try {
            if (parentId == null) {
                return new List<ContentDocument>();
            }
            List<ContentDocumentLink> links = [SELECT ContentDocumentId 
                                               FROM ContentDocumentLink 
                                               WHERE LinkedEntityId = :parentId];
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink link : links) {
                docIds.add(link.ContentDocumentId);
            }
            return [SELECT Id, Title, FileType, ContentSize, LastModifiedDate, CreatedBy.Name 
                    FROM ContentDocument 
                    WHERE Id IN :docIds 
                    ORDER BY LastModifiedDate DESC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching attachments: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getShopFloorWarehouse(String workCenterName) {
        try {
            if (String.isBlank(workCenterName)) {
                return '';
            }
            List<Work_Center__c> workCenters = [
                SELECT Id , Name, Shop_Floor_Warehouse__c ,Shop_Floor_Warehouse__r.Name
                FROM Work_Center__c 
                WHERE Name = :workCenterName 
                LIMIT 1
            ];
            return !workCenters.isEmpty() ? workCenters[0].Shop_Floor_Warehouse__r.Name : '';
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching shop floor warehouse: ' + e.getMessage());
        }
    }

    public class comWrap {
        @AuraEnabled public String errorMsg;
        @AuraEnabled public List<mrpWrap> MRPs;
        @AuraEnabled public WO__c manuOrders;
    }

    public class mrpWrap {
        @AuraEnabled public MRP__c mrp;
    }

    @AuraEnabled
public static comWrap ReserveMRPSStocks(List<Id> mrpIds, Integer autostkLimit) {
    comWrap comW = new comWrap();
    comW.errorMsg = '';
    comW.MRPs = new List<mrpWrap>();
    
    try {
        System.debug('Starting stock allocation for MRP IDs: ' + mrpIds);
        
        if (mrpIds == null || mrpIds.isEmpty()) {
            comW.errorMsg = 'No MRP IDs provided';
            return comW;
        }

        // Query MRP records with Work Center information
        List<MRP__c> mrps = [
            SELECT Id, Name, Work_Order__c, Work_Order__r.Work_Center__c,
                   Work_Order__r.Work_Center__r.Name, Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c,
                   Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__r.Name,
                   MRP_Product__c, MRP_Product__r.Serialise__c, MRP_Product__r.Name,
                   Total_Amount_Required__c, Fulfilled_Amount__c, Process__c, 
                   Schedule__c, BOM_Line_Item__c, Status__c, Work_Center__c,
                   Work_Center__r.Name, Work_Center__r.Shop_Floor_Warehouse__c, 
                   Work_Center__r.Shop_Floor_Warehouse__r.Name
            FROM MRP__c 
            WHERE Id IN :mrpIds
        ];

        System.debug('Found ' + mrps.size() + ' MRP records');

        if (mrps.isEmpty()) {
            comW.errorMsg = 'No MRPs found with the provided IDs';
            return comW;
        }

        // Determine the warehouse/site to use from Work Center
        String selectedSite = null;
        Set<Id> productIds = new Set<Id>();
        String workCenterName = '';

        for (MRP__c mrp : mrps) {
            productIds.add(mrp.MRP_Product__c);
            
            // Try to get warehouse from MRP's Work Center first
            if (selectedSite == null && mrp.Work_Center__c != null) {
                if (mrp.Work_Center__r != null && mrp.Work_Center__r.Shop_Floor_Warehouse__c != null) {
                    selectedSite = mrp.Work_Center__r.Shop_Floor_Warehouse__c;
                    workCenterName = mrp.Work_Center__r.Name != null ? mrp.Work_Center__r.Name : 'Unknown Work Center';
                    System.debug('Selected site from MRP Work Center: ' + selectedSite + ', Work Center: ' + workCenterName);
                }
            }
            
            // If not found, try to get from Work Order's Work Center
            if (selectedSite == null && mrp.Work_Order__r != null && mrp.Work_Order__r.Work_Center__c != null) {
                if (mrp.Work_Order__r.Work_Center__r != null && mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c != null) {
                    selectedSite = mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c;
                    workCenterName = mrp.Work_Order__r.Work_Center__r.Name != null ? mrp.Work_Order__r.Work_Center__r.Name : 'Unknown Work Center';
                    System.debug('Selected site from Work Order Work Center: ' + selectedSite + ', Work Center: ' + workCenterName);
                }
            }
        }

        if (selectedSite == null) {
            comW.errorMsg = 'No shop floor warehouse configured for the work center';
            return comW;
        }

        System.debug('Using warehouse: ' + selectedSite + ' from Work Center: ' + workCenterName);
        System.debug('Product IDs to allocate: ' + productIds);

        // Query existing reservations
        List<Stock_Outward_Line_Item__c> existingReservations = [
            SELECT MRP_Material_Requirements_Planning__c, Quantity__c 
            FROM Stock_Outward_Line_Item__c 
            WHERE MRP_Material_Requirements_Planning__c IN :mrpIds AND Status__c = 'Reserved'
        ];

        Map<Id, Decimal> existingReservationQuantities = new Map<Id, Decimal>();
        for (Stock_Outward_Line_Item__c soli : existingReservations) {
            Id mrpId = soli.MRP_Material_Requirements_Planning__c;
            Decimal qty = existingReservationQuantities.get(mrpId) != null ? existingReservationQuantities.get(mrpId) : 0;
            existingReservationQuantities.put(mrpId, qty + (soli.Quantity__c != null ? soli.Quantity__c : 0));
        }

        // Query available inventory stocks
        List<Inventory_Stock__c> availableStocks = [
            SELECT Id, Product__c, Product__r.Name, Number_of_Item_In_Stock__c, 
                   Warehouse__c, Warehouse__r.Name, BOM__c, CreatedDate
            FROM Inventory_Stock__c 
            WHERE Product__c IN :productIds 
            AND Warehouse__c = :selectedSite 
            AND Number_of_Item_In_Stock__c > 0
            ORDER BY Product__c, CreatedDate ASC
        ];

        System.debug('Found ' + availableStocks.size() + ' available stock records in warehouse: ' + selectedSite);
        for (Inventory_Stock__c stock : availableStocks) {
            System.debug('Stock - Product: ' + stock.Product__r.Name + ', Qty: ' + stock.Number_of_Item_In_Stock__c + ', Warehouse: ' + stock.Warehouse__r.Name);
        }

        // Group stocks by product for easier allocation
        Map<Id, List<Inventory_Stock__c>> stocksByProduct = new Map<Id, List<Inventory_Stock__c>>();
        for (Inventory_Stock__c stock : availableStocks) {
            if (!stocksByProduct.containsKey(stock.Product__c)) {
                stocksByProduct.put(stock.Product__c, new List<Inventory_Stock__c>());
            }
            stocksByProduct.get(stock.Product__c).add(stock);
        }

        // Allocation logic
        List<Stock_Outward_Line_Item__c> reservationsToCreate = new List<Stock_Outward_Line_Item__c>();
        Map<Id, Decimal> allocatedQuantitiesByStock = new Map<Id, Decimal>();

        // NEW: Track MRPs that need status update
        List<MRP__c> mrpsToUpdateStatus = new List<MRP__c>();

        for (MRP__c mrp : mrps) {
            mrpWrap wrapper = new mrpWrap();
            wrapper.mrp = mrp;
            comW.MRPs.add(wrapper);

            // Calculate remaining quantity needed
            Decimal existingReservedQty = existingReservationQuantities.get(mrp.Id) != null ? existingReservationQuantities.get(mrp.Id) : 0;
            Decimal currentFulfilled = mrp.Fulfilled_Amount__c != null ? mrp.Fulfilled_Amount__c : 0;
            Decimal remainingQty = mrp.Total_Amount_Required__c - (currentFulfilled + existingReservedQty);
            
            System.debug('MRP: ' + mrp.MRP_Product__r.Name + ', Required: ' + mrp.Total_Amount_Required__c + 
                        ', Fulfilled: ' + currentFulfilled + ', Existing Reserved: ' + existingReservedQty + 
                        ', Remaining: ' + remainingQty);

            if (remainingQty <= 0) {
                System.debug('No allocation needed for ' + mrp.MRP_Product__r.Name);
                
                // NEW: Check if status should be updated to "Reserved"
                if (mrp.Total_Amount_Required__c != null && mrp.Total_Amount_Required__c > 0 && 
                    mrp.Fulfilled_Amount__c != null && 
                    mrp.Fulfilled_Amount__c >= mrp.Total_Amount_Required__c &&
                    mrp.Status__c != 'Reserved') {
                    
                    System.debug('Updating MRP status to Reserved for: ' + mrp.MRP_Product__r.Name);
                    mrp.Status__c = 'Reserved';
                    mrpsToUpdateStatus.add(mrp);
                }
                continue;
            }

            List<Inventory_Stock__c> productStocks = stocksByProduct.get(mrp.MRP_Product__c);
            
            if (productStocks == null || productStocks.isEmpty()) {
                String errorMsg = 'No stock available for product: ' + mrp.MRP_Product__r.Name + ' in warehouse: ' + selectedSite;
                System.debug(errorMsg);
                comW.errorMsg += (comW.errorMsg == '' ? '' : '; ') + errorMsg;
                continue;
            }

            System.debug('Found ' + productStocks.size() + ' stock records for product: ' + mrp.MRP_Product__r.Name);

            Integer allocationCount = 0;
            Decimal totalAllocated = 0;

            for (Inventory_Stock__c stock : productStocks) {
                if (autostkLimit != null && allocationCount >= autostkLimit) {
                    System.debug('Reached allocation limit for ' + mrp.MRP_Product__r.Name);
                    break;
                }

                // Calculate available quantity in this stock item
                Decimal availableQty = stock.Number_of_Item_In_Stock__c != null ? stock.Number_of_Item_In_Stock__c : 0;
                if (allocatedQuantitiesByStock.containsKey(stock.Id)) {
                    Decimal alreadyAllocated = allocatedQuantitiesByStock.get(stock.Id) != null ? allocatedQuantitiesByStock.get(stock.Id) : 0;
                    availableQty -= alreadyAllocated;
                }

                if (availableQty <= 0) {
                    continue;
                }

                // Calculate quantity to allocate from this stock
                Decimal allocateQty = Math.min(remainingQty, availableQty);
                
                System.debug('Allocating ' + allocateQty + ' from stock ID: ' + stock.Id + ' (Available: ' + availableQty + ')');

                // Create reservation record
                Stock_Outward_Line_Item__c reservation = new Stock_Outward_Line_Item__c(
                    Name = mrp.MRP_Product__r.Name + ' - Reservation',
                    Active__c = true,
                    Process__c = mrp.Process__c,
                    Schedule__c = mrp.Schedule__c,
                    MRP_Material_Requirements_Planning__c = mrp.Id,
                    BOM_Line_Item__c = mrp.BOM_Line_Item__c,
                    Status__c = 'Reserved',
                    Product__c = mrp.MRP_Product__c,
                    Site_Product_Service_Inventory_Stock__c = stock.Id,
                    BOM__c = stock.BOM__c,
                    Quantity__c = allocateQty
                );
                reservationsToCreate.add(reservation);

                // Update tracking variables
                remainingQty -= allocateQty;
                totalAllocated += allocateQty;
                allocationCount++;

                // Track allocated quantity for this stock
                Decimal currentAllocated = allocatedQuantitiesByStock.get(stock.Id) != null ? allocatedQuantitiesByStock.get(stock.Id) : 0;
                allocatedQuantitiesByStock.put(stock.Id, currentAllocated + allocateQty);

                if (remainingQty <= 0) {
                    break;
                }
            }

            // Update MRP fulfilled amount
            Decimal newFulfilledAmount = (mrp.Fulfilled_Amount__c != null ? mrp.Fulfilled_Amount__c : 0) + totalAllocated;
            mrp.Fulfilled_Amount__c = newFulfilledAmount;
            
            System.debug('Total allocated for ' + mrp.MRP_Product__r.Name + ': ' + totalAllocated + ', Remaining: ' + remainingQty);

            // NEW: Check if status should be updated to "Reserved" after allocation
            if (mrp.Total_Amount_Required__c != null && mrp.Total_Amount_Required__c > 0 && 
                newFulfilledAmount >= mrp.Total_Amount_Required__c &&
                mrp.Status__c != 'Reserved') {
                
                System.debug('Updating MRP status to Reserved for: ' + mrp.MRP_Product__r.Name);
                mrp.Status__c = 'Reserved';
                mrpsToUpdateStatus.add(mrp);
            }

            if (remainingQty > 0) {
                String warningMsg = 'Insufficient stock for ' + mrp.MRP_Product__r.Name + '. Required: ' + 
                                  remainingQty + ', Allocated: ' + totalAllocated;
                System.debug(warningMsg);
                comW.errorMsg += (comW.errorMsg == '' ? '' : '; ') + warningMsg;
            }
        }

        // Create reservations and update MRPs
        if (!reservationsToCreate.isEmpty()) {
            System.debug('Creating ' + reservationsToCreate.size() + ' reservation records');
            insert reservationsToCreate;
        }

        // NEW: Update MRP statuses for fully allocated items
        if (!mrpsToUpdateStatus.isEmpty()) {
            System.debug('Updating status for ' + mrpsToUpdateStatus.size() + ' MRP records to Reserved');
            update mrpsToUpdateStatus;
        }

        // Also update all MRPs (for fulfilled amount updates)
        if (!mrps.isEmpty()) {
            System.debug('Updating ' + mrps.size() + ' MRP records');
            update mrps;
        }

        System.debug('Stock allocation completed. Error message: ' + comW.errorMsg);

    } catch (Exception e) {
        System.debug('Error in ReserveMRPSStocks: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        comW.errorMsg = 'System error: ' + e.getMessage();
    }
    
    return comW;
}

    @AuraEnabled(cacheable=true)
    public static String debugStockAvailability(Id mrpId) {
        try {
            MRP__c mrp = [SELECT Id, MRP_Product__c, MRP_Product__r.Name, 
                                  Work_Center__c, Work_Center__r.Name, Work_Center__r.Shop_Floor_Warehouse__c,
                                  Work_Center__r.Shop_Floor_Warehouse__r.Name,
                                  Work_Order__r.Work_Center__c, Work_Order__r.Work_Center__r.Name,
                                  Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c,
                                  Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__r.Name
                          FROM MRP__c WHERE Id = :mrpId LIMIT 1];
            
            // Determine which warehouse to use - WITH PROPER NULL CHECKS
            String warehouseId = null;
            String warehouseName = '';
            String workCenterName = '';
            
            if (mrp.Work_Center__c != null && mrp.Work_Center__r != null) {
                if (mrp.Work_Center__r.Shop_Floor_Warehouse__c != null) {
                    warehouseId = mrp.Work_Center__r.Shop_Floor_Warehouse__c;
                    warehouseName = mrp.Work_Center__r.Shop_Floor_Warehouse__r != null ? 
                        mrp.Work_Center__r.Shop_Floor_Warehouse__r.Name : 'Unknown Warehouse';
                    workCenterName = mrp.Work_Center__r.Name != null ? mrp.Work_Center__r.Name : 'Unknown Work Center';
                }
            } else if (mrp.Work_Order__r != null && mrp.Work_Order__r.Work_Center__c != null && 
                       mrp.Work_Order__r.Work_Center__r != null) {
                if (mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c != null) {
                    warehouseId = mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__c;
                    warehouseName = mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__r != null ? 
                        mrp.Work_Order__r.Work_Center__r.Shop_Floor_Warehouse__r.Name : 'Unknown Warehouse';
                    workCenterName = mrp.Work_Order__r.Work_Center__r.Name != null ? 
                        mrp.Work_Order__r.Work_Center__r.Name : 'Unknown Work Center';
                }
            }
            
            if (warehouseId == null) {
                return 'Error: No shop floor warehouse configured for work center or work center not assigned to MRP';
            }
            
            List<Inventory_Stock__c> stocks = [SELECT Id, Product__r.Name, Number_of_Item_In_Stock__c, Warehouse__r.Name 
                                              FROM Inventory_Stock__c 
                                              WHERE Product__c = :mrp.MRP_Product__c 
                                              AND Warehouse__c = :warehouseId
                                              AND Number_of_Item_In_Stock__c > 0];
            
            Decimal totalQty = 0;
            for (Inventory_Stock__c stock : stocks) {
                totalQty += stock.Number_of_Item_In_Stock__c != null ? stock.Number_of_Item_In_Stock__c : 0;
            }
            
            return 'Product: ' + mrp.MRP_Product__r.Name + 
                   ', Work Center: ' + workCenterName +
                   ', Warehouse: ' + warehouseName +
                   ', Warehouse ID: ' + warehouseId +
                   ', Available Stocks: ' + stocks.size() + 
                   ', Total Qty: ' + totalQty;
        } catch (Exception e) {
            return 'Error: ' + e.getMessage() + ' at line ' + e.getLineNumber();
        }
    }
    @AuraEnabled(cacheable=true)
public static StockCheckResult checkProductStockAvailability(String productId, String workCenterName) {
    try {
        StockCheckResult result = new StockCheckResult();
        result.isAvailable = false;
        result.message = '';
        result.availableStock = 0;
        
        if (String.isBlank(productId) || String.isBlank(workCenterName)) {
            result.message = 'Product and Work Center are required';
            return result;
        }
        
        // Get the warehouse from work center
        List<Work_Center__c> workCenters = [
            SELECT Id, Name, Shop_Floor_Warehouse__c, Shop_Floor_Warehouse__r.Name
            FROM Work_Center__c 
            WHERE Name = :workCenterName 
            LIMIT 1
        ];
        
        if (workCenters.isEmpty()) {
            result.message = 'Work Center not found: ' + workCenterName;
            return result;
        }
        
        Work_Center__c workCenter = workCenters[0];
        
        if (workCenter.Shop_Floor_Warehouse__c == null) {
            result.message = 'No shop floor warehouse configured for work center: ' + workCenterName;
            return result;
        }
        
        // Check stock availability
        List<Inventory_Stock__c> stocks = [
            SELECT Id, Number_of_Item_In_Stock__c, Product__r.Name, Warehouse__r.Name
            FROM Inventory_Stock__c 
            WHERE Product__c = :productId 
            AND Warehouse__c = :workCenter.Shop_Floor_Warehouse__c
            AND Number_of_Item_In_Stock__c > 0
            LIMIT 1
        ];
        
        if (!stocks.isEmpty()) {
            result.isAvailable = true;
            result.availableStock = stocks[0].Number_of_Item_In_Stock__c != null ? stocks[0].Number_of_Item_In_Stock__c : 0;
            result.message = 'Stock available: ' + result.availableStock + ' units in ' + stocks[0].Warehouse__r.Name;
            result.warehouseName = stocks[0].Warehouse__r.Name;
        } else {
            result.message = 'No stock available for this product in the work center warehouse: ' + workCenter.Shop_Floor_Warehouse__r.Name;
            result.warehouseName = workCenter.Shop_Floor_Warehouse__r.Name;
        }
        
        return result;
        
    } catch (Exception e) {
        throw new AuraHandledException('Error checking stock availability: ' + e.getMessage());
    }
}

// Add this wrapper class
public class StockCheckResult {
    @AuraEnabled public Boolean isAvailable;
    @AuraEnabled public String message;
    @AuraEnabled public Decimal availableStock;
    @AuraEnabled public String warehouseName;
}

    @AuraEnabled
    public static void updateWorkOrderStatus(Id woId, String status) {
        try {
            WO__c wo = new WO__c(Id = woId, Status__c = status);
            update wo;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating work order status: ' + e.getMessage());
        }
    }

    public class MRPWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String ProductName;
        @AuraEnabled public Decimal Fulfilled;
        @AuraEnabled public Decimal Consumed;
        @AuraEnabled public Decimal Total;
    }

    @AuraEnabled(cacheable=true)
    public static List<MRPWrapper> getReservedMRPs(Id workOrderId) {
        List<MRPWrapper> wrappers = new List<MRPWrapper>();
        try {
            List<MRP__c> mrps = [
                SELECT Id, Name, MRP_Product__r.Name, Fulfilled_Amount__c, Consumed_Quantity__c, Total_Amount_Required__c
                FROM MRP__c 
                WHERE Work_Order__c = :workOrderId AND Status__c = 'Reserved'
            ];
            
            for (MRP__c m : mrps) {
                Decimal available = (m.Fulfilled_Amount__c != null ? m.Fulfilled_Amount__c : 0) - (m.Consumed_Quantity__c != null ? m.Consumed_Quantity__c : 0);
                if (available > 0) {
                    MRPWrapper w = new MRPWrapper();
                    w.Id = m.Id;
                    w.Name = m.Name;
                    w.ProductName = m.MRP_Product__r.Name;
                    w.Fulfilled = m.Fulfilled_Amount__c != null ? m.Fulfilled_Amount__c : 0;
                    w.Consumed = m.Consumed_Quantity__c != null ? m.Consumed_Quantity__c : 0;
                    w.Total = m.Total_Amount_Required__c != null ? m.Total_Amount_Required__c : 0;
                    wrappers.add(w);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching reserved MRPs: ' + e.getMessage());
        }
        return wrappers;
    }
}