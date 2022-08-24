local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local PlayerData = require(dataFolder.PlayerData)
local Items = require(replicatedStorageShared.Data.Inventory.Items)
local ItemType = require(enumsFolder.ItemType)

local LIMITS = {
    [ItemType.furniture] = 1000,
    [ItemType.accessory] = 1000,
    [ItemType.home] = 200,
}

local PROPS = {
    [ItemType.home] = {
        placedItems = {},
    },
}

local function deepCopy(value)
    if type(value) == "table" then
        local copy = {}

        for k, v in pairs(value) do
            copy[k] = deepCopy(v)
        end

        return copy
    end
        
    return value
end

local function addPropsToTable(itemType, t)
    if not PROPS[itemType] then
        return
    end
    
    for k, v in pairs(PROPS[itemType]) do
        if not t[k] then
            t[k] = deepCopy(v)
        end
    end

    return t
end

local InventoryManager = {}

function InventoryManager.reconcileInventory(player)
    local playerData = PlayerData.get(player, true)

    local inventory = playerData.profile.inventory

    for itemType, items in pairs(inventory) do
        for i, item in ipairs(items) do
            playerData:arraySet({"inventory", itemType}, i, addPropsToTable(itemType, item))
        end
    end
end

function InventoryManager.newItem(itemType, itemReferenceId)
    local itemsTable = Items[itemType]

    if not itemsTable then
        warn("Invalid item type: " .. itemType)

        return
    end

    local item = itemsTable[itemReferenceId]

    if not item then
        warn("Invalid item id: " .. itemReferenceId)

        return
    end

    return addPropsToTable(itemType, {
        id = HttpService:GenerateGUID(false),
        itemType = itemType,
        itemReferenceId = itemReferenceId
    })
end

function InventoryManager.inventoryIsFull(player, itemType, numItemsToAdd)
    local playerData = PlayerData.get(player)
    local inventory = playerData.profile.Data.inventory[itemType]
    local numItems = #inventory
    local numItemsToAdd = numItemsToAdd or 0

    if numItems == LIMITS[itemType] then
        return true
    end

    if numItems + numItemsToAdd > LIMITS[itemType] then
        return true
    end
end

function InventoryManager.changeOwnerOfItems(items, currentOwner: Player | nil, newOwner: Player | nil)
    local function checkIfInventoryWouldBeFull()
        for _, item in pairs(items) do
            local otherItemsOfSameType = {} do
                for _, otherItem in pairs(items) do
                    if otherItem.itemType == item.itemType then
                        table.insert(otherItemsOfSameType, otherItem)
                    end
                end
            end
            
            return InventoryManager.inventoryIsFull(newOwner, item.itemType, #otherItemsOfSameType)
        end
    end

    do
        if not currentOwner and not newOwner then
            warn("Both currentOwner and newOwner are nil")
    
            return
        end

        if #items == 0 then
            warn("No items to change owner of")
    
            return
        end

        local itemsTable = {}
        for _, item in pairs(items) do
            if itemsTable[item.id] then
                return
            end

            itemsTable[item.id] = true
        end
    
        if currentOwner then -- Verify currentOwner owns the given items and remove dupes
            local currentOwnerData = PlayerData.get(currentOwner)
    
            if not currentOwnerData then
                warn("PlayerData does not exist")
    
                return
            end
    
            for _, item in pairs(items) do
                local inventory = currentOwnerData.profile.Data.inventory[item.itemType]

                if not inventory then
                    warn("Player does not have an inventory of type " .. item.itemType)
    
                    return
                end
                
                local itemIndex do
                    for i, otherItem in ipairs(inventory) do
                        if otherItem.id == item.id then
                            itemIndex = i
                            
                            break
                        end
                    end
                end

                if not itemIndex then
                    warn("Player does not own item " .. item.id)
    
                    return
                end

                local itemsWithMatchingId = {}

                for _, otherItem in pairs(inventory) do
                    if otherItem.id == item.id then
                        table.insert(itemsWithMatchingId, otherItem)
                    end
                end

                if #itemsWithMatchingId > 1 then
                    warn("Player has multiple items with id " .. item.id)

                    currentOwnerData:arrayRemove({"inventory", item.itemType}, itemIndex)
    
                    return
                end
            end
        end
    end

    if newOwner and currentOwner then
        local currentOwnerData = PlayerData.get(currentOwner)
        local newOwnerData = PlayerData.get(newOwner)

        if not currentOwnerData or not newOwnerData then
            warn("Player data not found for player: " .. currentOwner.Name .. " or " .. newOwner.Name)
    
            return
        end

        if checkIfInventoryWouldBeFull() then
            warn("New owner's inventory would be full")
    
            return
        end

        for _, item in pairs(items) do
            local itemIndex do
                for i, v in ipairs(currentOwnerData.profile.Data.inventory[item.itemType]) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            currentOwnerData:arrayRemove({"inventory", item.itemType}, itemIndex)
            newOwnerData:arrayInsert({"inventory", item.itemType}, item)
        end

        return true
    elseif currentOwner and not newOwner then
        local playerData = PlayerData.get(currentOwner)

        if not playerData then
            warn("Player data not found for player: " .. currentOwner.Name)

            return
        end

        for _, item in pairs(items) do
            local itemIndex do
                for i, v in ipairs(playerData.profile.Data.inventory[item.itemType]) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            playerData:arrayRemove({"inventory", item.itemType}, itemIndex)
        end

        return true
    elseif not currentOwner and newOwner then
        local playerData = PlayerData.get(newOwner)

        if not playerData then
            warn("Player data not found for player: " .. newOwner.Name)

            return
        end

        if checkIfInventoryWouldBeFull() then
            warn("New owner's inventory would be full")
    
            return
        end

        for _, item in pairs(items) do
            playerData:arrayInsert({"inventory", item.itemType}, item)
        end
        
        return true
    end
end

function InventoryManager.addItemsToInventory(items, player)
    return InventoryManager.changeOwnerOfItems(items, nil, player)
end

function InventoryManager.deleteItemsFromInventory(items, player)
    return InventoryManager.changeOwnerOfItems(items, player, nil)
end

function InventoryManager.newItemInInventory(itemType, itemReferenceId, player)
    local item = InventoryManager.newItem(itemType, itemReferenceId)
    return item and InventoryManager.addItemsToInventory({item}, player)
end

return InventoryManager