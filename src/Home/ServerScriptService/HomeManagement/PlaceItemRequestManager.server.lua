local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local dataFolder = serverStorageShared.Data
local inventoryFolder = dataFolder.Inventory
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = replicatedFirstShared.Utility
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(dataFolder.ReplicaService)
local HomeManager = require(inventoryFolder.HomeManager)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local ResponseType = require(enumsFolder.ResponseType)
local PlaceItemRequestType = require(enumsFolder.PlaceItemRequestType)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local Types = require(utilityFolder.Types)
local Promise = require(utilityFolder.Promise)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)

type UserEnum = Types.UserEnum
type Promise = Types.Promise

local requestReplica = ReplicaService.NewReplica({
	ClassToken = ReplicaService.NewClassToken("PlaceItemRequest"),
	Replication = "All",
})

local homeOwnerPromise: Promise = LocalServerInfo.getServerInfo():andThen(function(serverInfo)
	return serverInfo.homeOwner
end)

ReplicaResponse.listen(requestReplica, function(player: Player, placeItemRequestType: UserEnum, ...)
	local vararg = {...}

	return Param:expect({ player, "Player" }, { placeItemRequestType, "number", "string" }, { ..., "table" })
		:andThen(function()
			return homeOwnerPromise
				:andThen(function(homeOwnerUserId)
					return if homeOwnerUserId == player.UserId
						then Promise.resolve()
						else Promise.reject(ResponseType.invalid)
				end)
				:andThen(function()
					return PlayerDataManager.get(player):andThen(function(playerData)
						return if playerData then Promise.resolve() else Promise.reject(ResponseType.invalid)
					end)
				end)
				:andThen(function()
					if placeItemRequestType == PlaceItemRequestType.place then
						local placedItemData = unpack(vararg)

						local itemId: string, pivotCFrame: CFrame = placedItemData.itemId, placedItemData.pivotCFrame

						if typeof(itemId) ~= "string" or typeof(pivotCFrame) ~= "CFrame" then
							warn("Invalid place item request data")

							return Promise.reject(ResponseType.invalid)
						end

						return HomeManager.addPlacedItem(itemId, pivotCFrame):catch(function(err)
							warn(err)

							return Promise.reject(ResponseType.error)
						end)
					elseif placeItemRequestType == PlaceItemRequestType.remove then
						local itemId: string = unpack(vararg)

						if typeof(itemId) ~= "string" then
							warn("Invalid place item request data")

							return Promise.reject(ResponseType.invalid)
						end

						return HomeManager.isItemPlaced(itemId):andThen(function(isItemPlaced)
							return if isItemPlaced then Promise.resolve() else Promise.reject(ResponseType.invalid)
						end):andThen(function()
							return HomeManager.removePlacedItem(itemId):catch(function(err)
								warn(err)

								return Promise.reject(ResponseType.error)
							end)
						end)
					else
						warn("Invalid place item request type")

						return Promise.reject(ResponseType.invalid)
					end
				end)
		end)
		:andThen(function()
			return Promise.resolve(ResponseType.success)
		end)
		:catch(function(err)
			warn("PlaceItemRequest error: ", tostring(err))
			return Promise.resolve(err or ResponseType.error)
		end)
end)
