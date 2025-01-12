local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local dataFolder = serverStorageShared.Data
local inventoryFolder = dataFolder.Inventory
local enumsFolder = replicatedFirstShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = replicatedFirstShared.Utility
local serverStorageSharedUtility = serverStorageShared.Utility

ServerStorage:WaitForChild("")

local ReplicaService = require(serverStorageVendor.ReplicaService)
local HomeManager = require(inventoryFolder.HomeManager)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local PlaceItemResponseType = require(enumsFolder.PlaceItemResponseType)
local PlaceItemRequestType = require(enumsFolder.PlaceItemRequestType)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local Types = require(utilityFolder.Types)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)

type UserEnum = Types.UserEnum
type Promise = Types.Promise

local requestReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PlaceItemRequest",
	Replication = "All",
}

local function getHomeOwner()
	local serverIdentifier = LocalServerInfo.getServerIdentifier()

	return if serverIdentifier then serverIdentifier.homeOwner else nil
end

ReplicaResponse.listen(requestReplica, function(player: Player, placeItemRequestType: UserEnum, ...)
	if not Param.expect({ player, "Player" }, { placeItemRequestType, "number", "string" }, { ..., "table" }) then
		warn "PlaceItemRequest: Invalid parameters"
		return PlaceItemResponseType.invalid
	end

	local homeOwnerUserId = getHomeOwner()

	if not homeOwnerUserId then
		warn "PlaceItemRequest: No home owner"
		return PlaceItemResponseType.invalid
	elseif homeOwnerUserId ~= player.UserId then
		warn "PlaceItemRequest: Not home owner"
		return PlaceItemResponseType.invalid
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "PlaceItemRequest: Invalid player data"
		return PlaceItemResponseType.invalid
	end

	if placeItemRequestType == PlaceItemRequestType.place then
		local itemId, pivotCFrame = ...

		if not Param.expect({ itemId, "string" }, { pivotCFrame, "CFrame" }) then
			warn "PlaceItemRequest: Invalid place item request data"
			return PlaceItemResponseType.invalid
		end

		local success = HomeManager.addPlacedItem(itemId, pivotCFrame)

		if not success then
			warn "PlaceItemRequest: Error placing item"
			return PlaceItemResponseType.error
		end
	elseif placeItemRequestType == PlaceItemRequestType.remove then
		local itemId = ...

		if not Param.expect { itemId, "string" } then
			warn "PlaceItemRequest: Invalid remove item request data"
			return PlaceItemResponseType.invalid
		end

		local success, isItemPlaced = HomeManager.isItemPlaced(itemId)

		if not isItemPlaced then
			warn "PlaceItemRequest: Item not placed"
			return PlaceItemResponseType.invalid
		elseif not success then
			warn "PlaceItemRequest: Error checking if item is placed"
			return PlaceItemResponseType.error
		end

		local removePlacedSuccess = HomeManager.removePlacedItem(itemId)

		if not removePlacedSuccess then
			warn "PlaceItemRequest: Error removing item"
			return PlaceItemResponseType.error
		end
	else
		warn "PlaceItemRequest: Invalid place item request type"
		return PlaceItemResponseType.invalid
	end

	return PlaceItemResponseType.success
end)
