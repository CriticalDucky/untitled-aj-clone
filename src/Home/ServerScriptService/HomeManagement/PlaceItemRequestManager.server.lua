local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedStorageHome = ReplicatedStorage.Home
local dataFolder = serverStorageShared.Data
local inventoryFolder = dataFolder.Inventory
local enumsFolder = replicatedStorageShared.Enums

local ReplicaService = require(dataFolder.ReplicaService)
local HomeManager = require(inventoryFolder.HomeManager)
local PlayerData = require(dataFolder.PlayerData)
local LocalHomeInfo = require(replicatedStorageHome.Server.LocalHomeInfo)
local InventoryManager = require(inventoryFolder.InventoryManager)
local PlaceItemResponseType = require(enumsFolder.PlaceItemResponseType)
local PlaceItemRequestType = require(enumsFolder.PlaceItemRequestType)

local requestReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PlaceItemRequest"),
    Replication = "All"
})

requestReplica:ConnectOnServerEvent(function(player: Player, requestCode, requestType, ...)
    local function isRequestValid()
        if not PlayerData.get(player) then
            print("PlayerData not found for player " .. player.Name)

            return false
        end

        if player.UserId ~= LocalHomeInfo.homeOwner then
            print("Player " .. player.Name .. " is not the home owner")

            return false
        end

        return true
    end

    local function respond(...)
        requestReplica:FireClient(player, requestCode, ...)
    end

    if not isRequestValid() then
        return respond(PlaceItemResponseType.invalid)
    end

    if requestType == PlaceItemRequestType.place then
        local placedItemData = ...

        local itemId: string, pivotCFrame: CFrame = placedItemData.itemId, placedItemData.pivotCFrame

        if typeof(itemId) ~= "string" or typeof(pivotCFrame) ~= "CFrame" then
            print("Invalid place item request data")

            return respond(PlaceItemResponseType.invalid)
        end

        if not HomeManager.addPlacedItem(itemId, pivotCFrame) then
            respond(PlaceItemResponseType.invalid)
    
            return
        end
    elseif requestType == PlaceItemRequestType.remove then
        local itemId = ...

        if not HomeManager.isItemPlaced(itemId) then
            respond(PlaceItemResponseType.invalid)
    
            return
        end

        if not HomeManager.removePlacedItem(itemId) then
            respond(PlaceItemResponseType.invalid)
    
            return
        end
    else
        print("Invalid place item request type")

        return respond(PlaceItemResponseType.invalid)
    end

    respond(PlaceItemResponseType.success)
end)