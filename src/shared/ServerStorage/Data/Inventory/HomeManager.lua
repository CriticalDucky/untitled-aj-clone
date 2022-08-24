local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local serverStorageShared = ServerStorage.Shared
local dataServerStorage = serverStorageShared.Data
local inventoryServerStorage = dataServerStorage.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
local dataReplicatedStorage = replicatedStorageShared.Data
local inventoryReplicatedStorage = dataReplicatedStorage.Inventory
local enums = replicatedStorageShared.Enums

local InventoryManager = require(inventoryServerStorage.InventoryManager)
local PlayerData = require(dataServerStorage.PlayerData)
local DataStore = require(serverStorageShared.Utility.DataStore)
local Items = require(inventoryReplicatedStorage.Items)
local ItemTypeEnum = require(enums.ItemType)

local homeInfoDataStore = DataStoreService:GetDataStore("HomeOwner")

local HomeManager = {}

function HomeManager.newHome(player, homeType)
    local homeInfo = Items[ItemTypeEnum.furniture] and Items[ItemTypeEnum.furniture][homeType]

    if not homeInfo then
        warn("HomeManager.newHome: Invalid home type: ", homeType)

        return
    end

    local playerData = PlayerData.get(player)

    if not playerData then
        warn("No player data found for player: " .. player.Name)

        return
    end

    local inventory = playerData.profile.inventory[ItemTypeEnum.furniture]

    if not inventory then
        warn("inventory/homeItems not found for player: " .. player.Name)

        return
    end

    local success, code, privateServerId = pcall(function()
        return TeleportService:ReserveServer(homeInfo.placeId)
    end)

    if success and code and privateServerId then
        if success then
            local home = InventoryManager.newItem(ItemTypeEnum.furniture, homeType)
            
            return home
        end
    else
        warn("Failed to reserve home server for player: " .. player.Name)
        return
    end
end

return HomeManager