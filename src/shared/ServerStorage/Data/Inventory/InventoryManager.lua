local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local inventoryFolder = dataFolder.Inventory
local utilityFolder = replicatedFirstShared.Utility
local replicatedStorageData = replicatedStorageShared.Data
local replicatedStorageInventory = replicatedStorageData.Inventory

local PlayerData = require(dataFolder.PlayerData)
local Items = require(replicatedStorageInventory.Items)
local Table = require(utilityFolder.Table)
local Event = require(utilityFolder.Event)
local ItemProps = require(inventoryFolder.ItemProps)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local MiniId = require(utilityFolder.MiniId)

local function addPropsToItem(item)
    local itemCategory = item.itemCategory

    local props = ItemProps[itemCategory]

    if props then
        for propName, propValue in pairs(props) do
            if item[propName] == nil then
                item[propName] = Table.deepCopy(propValue)
            end
        end
    end

    return item
end

local InventoryManager = {}

InventoryManager.itemPlacingInInventory = Event.new()
InventoryManager.itemRemovedFromInventory = Event.new()

function InventoryManager.getInventory(player: Player | number)
    local playerData = PlayerData.get(player)
    local profile = if playerData then playerData.profile else PlayerData.viewPlayerData(player, true)

    return profile and profile.Data.inventory
end

function InventoryManager.getItemInventory(player: Player | number, itemCategory)
    local inventory = InventoryManager.getInventory(player)

    return inventory and inventory[itemCategory]
end

function InventoryManager.isInventoryFull(player: Player | number, itemCategory, numItemsToAdd)
    local inventory = InventoryManager.getItemInventory(player, itemCategory)
    local numItems = #inventory

    numItemsToAdd = numItemsToAdd or 0

    local limit = GameSettings.inventoryLimits[itemCategory]

    if numItems == limit then
        return true
    end

    if numItems + numItemsToAdd > limit then
        return true
    end
end

function InventoryManager._removeItem(playerData, itemCategory, itemIndex)
    if not playerData then
        warn("InventoryManager._removeItem: No player data found")

        return
    end

    local item = InventoryManager.getItemInventory(playerData.player, itemCategory)[itemIndex]

    if not item then
        warn("InventoryManager._removeItem: No item found")

        return
    end

    playerData:arrayRemove({"inventory", itemCategory}, itemIndex)

    InventoryManager.itemRemovedFromInventory:Fire(playerData.player, itemCategory, itemIndex, item)
end

function InventoryManager._addItem(playerData, itemCategory, item)
    if not playerData then
        warn("InventoryManager._addItem: No player data found")

        return
    end

    local player = playerData.player

    if InventoryManager.isInventoryFull(player, itemCategory, 1) then
        warn("InventoryManager._addItem: Inventory is full")

        return
    end

    InventoryManager.itemPlacingInInventory:Fire(player, itemCategory, item)

    playerData:arrayInsert({"inventory", itemCategory}, item)
end

function InventoryManager.newItem(itemCategory, itemEnum, props)
    local itemsTable = Items[itemCategory]

    if not itemsTable then
        warn("Invalid item type: " .. itemCategory)

        return
    end

    local item = itemsTable[itemEnum]

    if not item then
        warn("Invalid item id: " .. itemEnum)

        return
    end

    item = addPropsToItem{
        id = MiniId(8),
        itemCategory = itemCategory,
        itemEnum = itemEnum
    }

    return if props then Table.merge(if table.isfrozen(props) then Table.deepCopy(props) else props, item) else item
end

function InventoryManager.changeOwnerOfItems(items, currentOwner: Player | nil, newOwner: Player | nil)
    local function checkIfInventoryWouldBeFull()
        for _, item in pairs(items) do
            local otherItemsOfSameCategory = {} do
                for _, otherItem in pairs(items) do
                    if otherItem.itemCategory == item.itemCategory then
                        table.insert(otherItemsOfSameCategory, otherItem)
                    end
                end
            end
            
            return InventoryManager.isInventoryFull(newOwner, item.itemCategory, #otherItemsOfSameCategory)
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
                local inventory = InventoryManager.getItemInventory(currentOwner, item.itemCategory)

                if not inventory then
                    warn("Player does not have an inventory of type " .. item.itemCategory)
    
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

                    InventoryManager._removeItem(currentOwnerData, item.itemCategory, itemIndex)
    
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
                for i, v in ipairs(InventoryManager.getItemInventory(currentOwner, item.itemCategory)) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            InventoryManager._removeItem(currentOwnerData, item.itemCategory, itemIndex)
            InventoryManager._addItem(newOwnerData, item.itemCategory, item)
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
                for i, v in ipairs(InventoryManager.getItemInventory(currentOwner, item.itemCategory)) do
                    if v.id == item.id then
                        itemIndex = i
                    end
                end
            end

            InventoryManager._removeItem(playerData, item.itemCategory, itemIndex)
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
            InventoryManager._addItem(playerData, item.itemCategory, item)
        end
        
        return true
    end
end

function InventoryManager.addItemsToInventory(items, player)
    return InventoryManager.changeOwnerOfItems(items, nil, player)
end

function InventoryManager.removeItemsFromInventory(items, player)
    return InventoryManager.changeOwnerOfItems(items, player, nil)
end

function InventoryManager.newItemInInventory(itemCategory, itemEnum, player, props)
    assert(itemCategory and itemEnum and player, "InventoryManager.newItemInInventory: Missing argument(s)")

    local item = InventoryManager.newItem(itemCategory, itemEnum, props)

    if not item then
        warn("Failed to create new item with type " .. itemCategory .. " and id " .. itemEnum)
    
        return
    end

    return InventoryManager.addItemsToInventory({item}, player)
end

function InventoryManager.reconcileItems(playerData) -- Takes in the player data, and any props that are missing from any item's template are added
    for itemCategory, items in pairs(InventoryManager.getInventory(playerData.player) or {}) do
        local propTemplate = ItemProps[itemCategory]

        if not propTemplate then
            continue
        end
        
        for itemIndex, item in ipairs(items) do
            Table.recursiveIterate(propTemplate, function(path, value)
                local prop

                local function index(t, indexPath)
                    local element = t

                    for _, index in ipairs(indexPath) do
                        element = element[index]
                    end

                    return element
                end

                prop = index(item, Table.copy(path))

                if prop == nil then
                    playerData:setValue({"inventory", itemCategory, itemIndex, table.unpack(path)}, Table.deepCopy(value))
                end
            end)
        end
    end
end

function InventoryManager.getItemWithId(itemSource: Player | table | number, itemId) -- takes in: (player: Player, id) or (itemInventory: Table, id)
    if typeof(itemSource) == "Instance" or typeof(itemSource) == "number" then
        local inventory = InventoryManager.getInventory(itemSource)

        for _, items in pairs(inventory) do
            local item = InventoryManager.getItemWithId(items, itemId)

            if item then
                return item
            end
        end
    elseif typeof(itemSource) == "table" then
        for _, item in pairs(itemSource) do
            if item.id == itemId then
                return item
            end
        end
    else
        warn("InventoryManager.searchWithId: Invalid argument #1")
    
        return
    end
end

function InventoryManager.playerOwnsItem(player: Player | number, itemId)
    return InventoryManager.getItemWithId(player, itemId) ~= nil
end

PlayerData.forAllPlayerData(InventoryManager.reconcileItems)

return InventoryManager