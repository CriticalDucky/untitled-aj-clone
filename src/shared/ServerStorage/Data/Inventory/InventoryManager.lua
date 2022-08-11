local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local utilityFolder = serverStorageShared.Utility
local inventoryFolder = serverStorageShared.Inventory
local enumsFolder = replicatedStorageShared.Enums
local dataFolder = serverStorageShared.Data

local PlayerData = require(dataFolder.PlayerData)
local DataStore = require(utilityFolder.DataStore)
local Items = require(inventoryFolder.Items)
local ItemType = require(enumsFolder.ItemType)
local ItemValidationType = require(enumsFolder.ItemValidationType)

local itemStore = DataStoreService:GetDataStore("ItemData")

local LIMITS = {
    [ItemType.homeItem] = 400,
    [ItemType.accessory] = 400,
}

local InventoryManager = {}

function InventoryManager.newItem(itemType, itemNameId)
    local itemsTable = Items[itemType]

    if not itemsTable then
        warn("Invalid item type: " .. itemType)

        return
    end

    local item = itemsTable[itemNameId]

    if not item then
        warn("Invalid item id: " .. itemNameId)

        return
    end

    local id = HttpService:GenerateGUID(false)

    local success = DataStore.safeSet(itemStore, id, {
        itemType = itemType,
        itemNameId = itemNameId
    })

    if not success then
        warn("Failed to create item")

        return
    else
        return {
            id = id,
            itemType = itemType,
            itemNameId = itemNameId
        }
    end
end

function InventoryManager.deleteItem(itemId)
    local success = DataStore.safeRemove(itemStore, itemId)

    if not success then
        warn("Failed to delete item")

        return
    end

    return true
end

function InventoryManager.validateItem(player, item)
    local function handleInvalidItem()
        local playerData = PlayerData.get(player)
        local inventory = playerData.profile.inventory[item.itemType.indexName]

        local itemIndex do
            for index, inventoryItem in pairs(inventory) do
                if inventoryItem.id == item.id then
                    itemIndex = index
                end
            end
        end

        if not itemIndex then
            warn("Item not found in inventory")

            return
        end

        playerData:arrayRemove({"inventory", item.itemType.indexName}, itemIndex)

        return true
    end

    local itemData = DataStore.safeGet(itemStore, item.id)

    if not itemData then
        warn("Could not get data from id: " .. item.id)

        return ItemValidationType.noData
    end

    if itemData.owner and itemData.owner ~= player.userId then
        warn("Item is not owned by player")

        handleInvalidItem()

        return ItemValidationType.invalid
    end

    local playerData = PlayerData.get(player)
    local inventory = playerData.profile.inventory[item.itemType.indexName]

    local numMatching = 0

    for i, v in ipairs(inventory) do
        if v.id == item.id then
            numMatching += 1

            if numMatching > 1 then
                warn("Player has multiple items with the same id")

                handleInvalidItem()

                return ItemValidationType.invalid
            end
        end
    end

    if numMatching == 0 then
        warn("Item not in inventory")
        
        return ItemValidationType.invalid
    end

    return ItemValidationType.success
end

function InventoryManager.inventoryIsFull(player, itemType, numItemsToAdd)
    local playerData = PlayerData.get(player)
    local inventory = playerData.profile.inventory[itemType.indexName]
    local numItems = #inventory
    local numItemsToAdd = numItemsToAdd or 0

    if numItems + numItemsToAdd >= LIMITS[itemType] then
        return true
    end
end

function InventoryManager.changeOwnerOfItems(items, currentOwner, newOwner)
    local function checkIfInventoryWouldBeFull()
        for _, item in pairs(items) do
            local otherItemsOfSameType = {} do
                for otherItem in pairs(items) do
                    if otherItem.itemType == item.itemType then
                        table.insert(otherItemsOfSameType, otherItem)
                    end
                end
            end

            if InventoryManager.inventoryIsFull(newOwner, item.itemType, #otherItemsOfSameType) then
                return true
            end
        end
    end

    if not currentOwner and not newOwner then
        warn("Both currentOwner and newOwner are nil")

        return
    end

    for _, item in pairs(items) do
        local validation = InventoryManager.validateItem(currentOwner, item)

        if validation == ItemValidationType.noData then
            warn("Could not get data from id: " .. item.id)

            return
        end
        
        if validation == ItemValidationType.invalid then
            warn("Item is invalid")

            return
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

        local abortFunctions = {} -- Functions to call if any of the items fail to be transferred in the itemStore

        local abort = function()
            for i, v in ipairs(abortFunctions) do
                v()
            end
        end

        for _, item in pairs(items) do
            local itemIndex do
                for i, v in ipairs(currentOwnerData.profile.inventory[item.itemType.indexName]) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            currentOwnerData:arrayRemove({"inventory", item.itemType.indexName}, itemIndex)
            newOwnerData:arrayInsert({"inventory", item.itemType.indexName}, item)

            table.insert(abortFunctions, function()
                if currentOwnerData.profile:IsActive() and newOwnerData.profile:IsActive() then
                    currentOwnerData:arrayInsert({"inventory", item.itemType.indexName}, item)
                    
                    local newItemIndex do
                        for i, v in ipairs(newOwnerData.profile.inventory[item.itemType.indexName]) do
                            if v.id == item.id then
                                newItemIndex = i
                            end
                        end
                    end

                    newOwnerData:arrayRemove({"inventory", item.itemType.indexName}, newItemIndex)
                end
            end)
        end

        for _, item in pairs(items) do
            local success = DataStore.safeUpdate(itemStore, item.id, function(data)
                data.owner = newOwner.UserId

                return data
            end)

            if not success then -- If the first safeUpdate is successful, the rest will be successful as well (fingers crossed).
                warn("Failed to change owner of item: " .. item.id)

                abort()

                return
            end
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
                for i, v in ipairs(playerData.profile.inventory[item.itemType.indexName]) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            playerData:arrayRemove({"inventory", item.itemType.indexName}, itemIndex)
        end

        for _, item in pairs(items) do
            local success = InventoryManager.deleteItem(item.id)

            if not success then
                warn("Failed to delete item")
            end
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

        local abortFunctions = {} -- Functions to call if any of the items fail to be transferred in the itemStore
        local function abort()
            for i, v in ipairs(abortFunctions) do
                v()
            end
        end

        for _, item in pairs(items) do
            playerData:arrayInsert({"inventory", item.itemType.indexName}, item)

            table.insert(abortFunctions, function()
                if playerData.profile:IsActive() then
                    playerData:arrayRemove({"inventory", item.itemType.indexName}, item)
                end
            end)
        end

        for _, item in pairs(items) do
            local success = DataStore.safeUpdate(itemStore, item.id, function(data)
                data.owner = newOwner.UserId

                return data
            end)

            if not success then -- If the first safeUpdate is successful, the rest will be successful as well (fingers crossed).
                warn("Failed to change owner of item: " .. item.id)
                
                abort()
                
                return
            end
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

return InventoryManager