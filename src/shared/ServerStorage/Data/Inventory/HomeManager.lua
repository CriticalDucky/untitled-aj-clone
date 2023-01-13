local LOADED_ITEM_ATTRIBUTE = "ItemId" -- This is the attribute that is set on items that are loaded into the game
local UPDATE_INTERVAL = 60 -- The time between each home update for home servers

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local dataServerStorage = serverStorageShared.Data
local inventoryServerStorage = dataServerStorage.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
local dataReplicatedStorage = replicatedStorageShared.Data
local inventoryReplicatedStorage = dataReplicatedStorage.Inventory
local settingsServerStorage = dataServerStorage.Settings
local enums = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = replicatedFirstShared.Utility

local InventoryManager = require(inventoryServerStorage.InventoryManager)
local PlayerData = require(dataServerStorage.PlayerData)
local Items = require(inventoryReplicatedStorage.Items)
local ItemCategory = require(enums.ItemCategory)
local HomeType = require(enums.HomeType)
local PlayerSettings = require(settingsServerStorage.PlayerSettings)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local ServerGroupEnum = require(enums.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local Table = require(utilityFolder.Table)
local SpacialQuery = require(utilityFolder.SpacialQuery)
local Serialization = require(utilityFolder.Serialization)
local ServerData = require(serverStorageShared.ServerManagement.ServerData)

local isHomeServer = ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome)
local initalLoad = false

local LocalHomeInfo, placedItemsFolder do
    if isHomeServer then
        LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)
        placedItemsFolder = workspace:FindFirstChild("PlacedItems") or Instance.new("Folder")
        placedItemsFolder.Name = "PlacedItems"
        placedItemsFolder.Parent = workspace
    end
end

local function getLoadedItemFromId(itemId)
    for _, placedItem in pairs(placedItemsFolder:GetChildren()) do
        if placedItem:GetAttribute(LOADED_ITEM_ATTRIBUTE) == itemId then
            return placedItem
        end
    end
end

local function getLoadedItems()
    local loadedItems = {}

    for _, placedItem in pairs(placedItemsFolder:GetChildren()) do
        local itemId = placedItem:GetAttribute(LOADED_ITEM_ATTRIBUTE)

        if itemId then
            loadedItems[itemId] = placedItem
        end
    end

    return loadedItems
end

local HomeManager = {}

function HomeManager.getSelectedHomeId(player: Player | number)
    local setting = PlayerSettings.getSetting(player, "selectedHome")

    return setting
end

function HomeManager.setSelectedHomeId(player, itemId)
    PlayerSettings.setSetting(player, "selectedHome", itemId)
end

function HomeManager.getLockStatus(player: Player | number)
    local setting = PlayerSettings.getSetting(player, "homeLockStatus")

    return setting
end

function HomeManager.setLockStatus(player, isLocked)
    PlayerSettings.setSetting(player, "homeLockStatus", isLocked)
end

function HomeManager.getHomes(player: Player | number)
    local inventory = InventoryManager.getInventory(player)
    local homes = inventory and inventory[ItemCategory.home]

    return homes
end

function HomeManager.getHome(player: Player | number, slot)
    assert(player, "HomeManager.getHome: player is nil")

    local homes = HomeManager.getHomes(player)

    if not homes then
        warn("No homes found for player", player)
        return nil
    end

    local home

    if type(slot) == "string" then
        home = InventoryManager.getItemFromId(homes, slot)
    elseif type(slot) == "number" then
        home = homes[slot]
    else -- nil
        local selectedHome = HomeManager.getSelectedHomeId(player)

        if selectedHome then
            home = HomeManager.getHome(player, selectedHome)
        end
    end

    return home
end

function HomeManager.getSelectedHomeIndex(player: Player | number)
    local selectedHomeId = HomeManager.getSelectedHomeId(player)
    local homes = HomeManager.getHomes(player)

    if not homes then
        return nil
    end

    for index, home in ipairs(homes) do
        if home.id == selectedHomeId then
            return index
        end
    end
end

function HomeManager.getHomeServerInfo(player)
    for _, p in pairs(Players:GetPlayers()) do
        if p.UserId == player then
            player = p
            break
        end
    end

    local playerData = PlayerData.get(player) or PlayerData.viewPlayerProfile(player)
    local profile = playerData and if playerData.profile then playerData.profile else playerData

    local homeServerInfo: homeServerInfo = profile and profile.Data.playerInfo.homeServerInfo

    return homeServerInfo
end

function HomeManager.isHomeInfoStamped(player: Player | number)
    local playerData = PlayerData.get(player) or PlayerData.viewPlayerProfile(player)
    local profile = playerData and if playerData.profile then playerData.profile else playerData

    if not playerData then
        return false
    end

    local isHomeInfoStamped = profile.Data.playerInfo.homeInfoStamped

    return isHomeInfoStamped
end

function HomeManager.getPlacedItems(player: Player | number)
    assert(not (not isHomeServer and player == nil), "HomeManager.getPlacedItems: player is nil")

    player = player or LocalHomeInfo.homeOwner

    local home = HomeManager.getHome(player)

    return home and home.placedItems
end

function HomeManager.getPlacedItemFromId(itemId, owner: Player | number | nil) -- owner is optional only if called from a home server
    local placedItems = HomeManager.getPlacedItems(owner)

    for _, placedItem in ipairs(placedItems) do
        if placedItem.itemId == itemId then
            return placedItem
        end
    end
end

function HomeManager.isItemPlaced(itemId, owner: Player | number | nil) -- owner is optional only if called from a home server
    return HomeManager.getPlacedItemFromId(itemId, owner) ~= nil
end

function HomeManager.isPlacedItemsFull(player: Player | number, numItemsToAdd)
    assert(not (not isHomeServer and player == nil), "HomeManager.isPlacedItemsFull: player is nil")

    player = player or LocalHomeInfo.homeOwner
    numItemsToAdd = numItemsToAdd or 0

    local maxFurniturePlaced = GameSettings.maxFurniturePlaced
    local placedItems = HomeManager.getPlacedItems(player)

    if #placedItems + numItemsToAdd > maxFurniturePlaced or #placedItems == maxFurniturePlaced then
        return true
    end

    return false
end

function HomeManager.canPlaceItem(itemId, pivotCFrame)
    assert(isHomeServer, "HomeManager.placeItem can only be called in a home server")

    local homeOwner = LocalHomeInfo.homeOwner

    local isPlacedItemsFull = HomeManager.isPlacedItemsFull(homeOwner, 1)

    if isPlacedItemsFull then
        warn("HomeManager.placeItem: Placed items is full")
        return false
    end

    if not InventoryManager.playerOwnsItem(homeOwner, itemId) then
        warn("HomeManager.placeItem: player does not own item")
        return false
    end

    local canPlaceItem = false

    for _, part in pairs(SpacialQuery.getPartsTouchingPoint(pivotCFrame)) do
        canPlaceItem = true
        break
        -- TODO: check if part is a valid placeable item
        -- TODO: check the part that is being placed on
    end

    return canPlaceItem
end

function HomeManager.loadPlacedItem(placedItem)
    assert(isHomeServer, "HomeManager.renderPlacedItem can only be called in a home server")

    local item = InventoryManager.getItemFromId(LocalHomeInfo.homeOwner, placedItem.itemId)
    local itemInfo = Items[item.itemCategory][item.itemEnum]
    local object = getLoadedItemFromId(placedItem.itemId)

    if object == nil then
        object = itemInfo.model:Clone()
    end

    object:SetAttribute(LOADED_ITEM_ATTRIBUTE, placedItem.itemId)
    object:PivotTo(Serialization.deserialize(placedItem.pivotCFrame))
    object.Parent = placedItemsFolder

    print("HomeManager.loadPlacedItem: loaded item", placedItem.itemId)

    return true
end

function HomeManager.unloadPlacedItem(placedItem)
    assert(isHomeServer, "HomeManager.unrenderPlacedItem can only be called in a home server")

    local object = getLoadedItemFromId(placedItem.itemId)

    if object then
        object:Destroy()
    end

    return true
end

function HomeManager.addPlacedItem(itemId, pivotCFrame)
    assert(isHomeServer, "HomeManager.placeItem can only be called in a home server")

    local homeOwner = LocalHomeInfo.homeOwner

    local player = Players:GetPlayerByUserId(homeOwner)

    if not player then
        warn("HomeManager.placeItem: player not found")
        return false
    end

    local canPlaceItem = HomeManager.canPlaceItem(itemId, pivotCFrame)

    if not canPlaceItem then
        warn("HomeManager.placeItem: cannot place item")
        return false
    end

    local placedItems = HomeManager.getPlacedItems(homeOwner)
    local placedItem = HomeManager.getPlacedItemFromId(itemId)
    local placedItemExists = placedItem ~= nil
    local selectedHomeIndex = HomeManager.getSelectedHomeIndex(homeOwner)

    placedItem = placedItem or {}
    placedItem.pivotCFrame = Serialization.serialize(pivotCFrame)
    placedItem.itemId = itemId

    local placedItemIndex = table.find(placedItems, placedItem)
    local playerData = PlayerData.get(player)
    local path = {"inventory", "homes", selectedHomeIndex, "placedItems"}

    if not playerData then
        warn("HomeManager.placeItem: player data not found")
        return false
    end

    if placedItemExists then
        playerData:arraySet(path, placedItemIndex, placedItem)
    else
        playerData:arrayInsert(path, placedItem)
    end

    HomeManager.loadPlacedItem(placedItem)

    return true
end

function HomeManager.removePlacedItem(itemId, player: Player | number | nil) -- player is optional only if called from a home server
    assert(not (not isHomeServer and player == nil), "HomeManager.removePlacedItem: player is nil")

    local homeOwner = player or LocalHomeInfo.homeOwner
    player = player or Players:GetPlayerByUserId(homeOwner)

    if not player then
        warn("HomeManager.unplaceItem: player not found")
        return false
    end

    local placedItems = HomeManager.getPlacedItems(homeOwner)
    local placedItem = HomeManager.getPlacedItemFromId(itemId, homeOwner)
    local selectedHomeIndex = HomeManager.getSelectedHomeIndex(homeOwner)
    local playerData = PlayerData.get(player)

    if not placedItem then
        warn("HomeManager.unplaceItem: placed item not found")
        return false
    end

    if not playerData then
        warn("HomeManager.unplaceItem: player data not found")
        return false
    end

    local placedItemIndex = table.find(placedItems, placedItem)
    local path = "inventory.homes." .. selectedHomeIndex .. ".placedItems"

    if placedItemIndex then
        playerData:arrayRemove(path, placedItemIndex)
    end

    if isHomeServer then
        HomeManager.unloadPlacedItem(placedItem)
    end

    return true
end

function HomeManager.loadItems()
    assert(isHomeServer, "HomeManager.renderItems can only be called in a home server")

    local placedItems = HomeManager.getPlacedItems(LocalHomeInfo.homeOwner)

    for _, placedItem in ipairs(placedItems) do
        HomeManager.loadPlacedItem(placedItem)
    end
end

function HomeManager.unloadItems()
    assert(isHomeServer, "HomeManager.unrenderItems can only be called in a home server")

    local placedItems = HomeManager.getPlacedItems(LocalHomeInfo.homeOwner)

    for _, placedItem in ipairs(placedItems) do
        HomeManager.unloadPlacedItem(placedItem)
    end
end

function HomeManager.loadHome()
    assert(isHomeServer, "HomeManager.renderHome can only be called in a home server")

    local homeOwner = LocalHomeInfo.homeOwner

    local home = HomeManager.getHome(homeOwner)

    if home then
        local homeType = home.itemEnum
        local homeInfo = Items[ItemCategory.home][homeType]

        if homeInfo then
            local model = homeInfo.model

            if model then
                local modelClone = model:Clone()
                modelClone.Name = "RenderedHome"
                modelClone.Parent = workspace

                return HomeManager.loadItems()
            end
        end
    end
end

function HomeManager.unloadHome()
    assert(isHomeServer, "HomeManager.unrenderHome can only be called in a home server")

    local home = workspace:FindFirstChild("RenderedHome")

    if home then
        home:Destroy()
    end

    placedItemsFolder:ClearAllChildren()

    return true
end

PlayerData.forAllPlayerData(function(playerData)
    local player = playerData.player
    local homes = HomeManager.getHomes(player)

    if #homes == 0 then
        InventoryManager.newItemInInventory(ItemCategory.home, HomeType.defaultHome, player, {
            permanent = true,
        })
    end

    homes = HomeManager.getHomes(player)

    if not HomeManager.getSelectedHomeId(player) then
        HomeManager.setSelectedHomeId(player, homes[1].id)
    end
 
    local homeServerInfo = HomeManager.getHomeServerInfo(player)

    if not (homeServerInfo and homeServerInfo.privateServerId and homeServerInfo.serverCode) then
        local function try()
            local success, code, privateServerId = pcall(function()
                return TeleportService:ReserveServer(GameSettings.homePlaceId)
            end)
    
            if success then
                playerData:setValue({"playerInfo", "homeServerInfo"}, {
                    serverCode = code,
                    privateServerId = privateServerId,
                })
    
                return true
            end
        end

        for _ = 1, 5 do
            if try() then
                break
            end

            task.wait(1)
        end
    end

    if not HomeManager.isHomeInfoStamped(player) then
        ServerData.stampHomeServer(player)
    end

    if isHomeServer and not initalLoad then
        initalLoad = true
        HomeManager.loadHome()
    end

    local placedItems = HomeManager.getPlacedItems(player) -- remove placed items that the player no longer owns

    for _, placedItem in ipairs(Table.copy(placedItems)) do
        local item = InventoryManager.playerOwnsItem(player, placedItem.itemId)

        if not item then
            HomeManager.removePlacedItem(placedItem.itemId, player)
        end
    end

    if isHomeServer then
        for itemId, _ in pairs(getLoadedItems()) do
            local item = InventoryManager.playerOwnsItem(player, itemId)

            if not item then
                HomeManager.unloadPlacedItem(itemId)
            end
        end
    end
end)

InventoryManager.itemRemovedFromInventory:Connect(function(player, itemCategory, itemIndex, item)
    if itemCategory == ItemCategory.home then
        local selectedHomeId = HomeManager.getSelectedHomeId(player)

        if selectedHomeId == item.id then
            HomeManager.setSelectedHomeId(player, HomeManager.getHomes(player)[1].id)
        end
    elseif itemCategory == ItemCategory.furniture then
        if HomeManager.isItemPlaced(item.id, player) then
            HomeManager.removePlacedItem(item.id)
        end
    end
end)

return HomeManager