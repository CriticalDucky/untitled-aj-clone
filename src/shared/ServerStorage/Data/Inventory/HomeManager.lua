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
local Promise = require(utilityFolder.Promise)
local Types = require(utilityFolder.Types)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local PlayerFormat = require(enums.PlayerFormat)
local Param = require(utilityFolder.Param)

type HomeServerInfo = Types.HomeServerInfo
type PlayerParam = Types.PlayerParam
type HomeOwnerParam = Types.HomeOwnerParam
type UserEnum = Types.UserEnum
type InventoryItem = Types.InventoryItem
type PlacedItem = Types.PlacedItem
type Promise = Types.Promise
type PlayerData = Types.PlayerData

local isHomeServer = ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome)
local homeOwnerPromise = LocalServerInfo.getServerInfo():andThen(function(serverInfo: HomeServerInfo)
	return serverInfo.homeOwner or Promise.reject("Not a home server")
end)
local initalLoad = false
local placedItemsFolder
do
	if isHomeServer then
		placedItemsFolder = workspace:FindFirstChild("PlacedItems") or Instance.new("Folder")
		placedItemsFolder.Name = "PlacedItems"
		placedItemsFolder.Parent = workspace
	end
end

--[[
	Gets a loaded item from an item id. This returns an instance or nil.
]]
local function getLoadedItemFromId(itemId: string): Instance?
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

--[[
	Gets the index of the home that a player is selecting. The player does not need to be in this server.
	Can reject if getting a player's data fails.
]]
function HomeManager.getSelectedHomeIndex(player: HomeOwnerParam)
	return HomeManager.getSelectedHomeId(player):andThen(function(itemId)
		return InventoryManager.getItemPathFromId(player, itemId):andThen(function(_, index)
			return index
		end)
	end)
end

--[[
    Gets the itemId of a home that a player has selected. The player does not need to be in this server.
    Can reject if getting a player's data fails.
]]
function HomeManager.getSelectedHomeId(player: HomeOwnerParam)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerSettings.getSetting(userId, "selectedHome")
	end)
end

--[[
    Sets the selected home id for the player. The player needs to be in this server.
]]
function HomeManager.setSelectedHomeId(player: HomeOwnerParam, itemId: string)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerSettings.setSetting(userId, "selectedHome", itemId)
	end)
end

--[[
    Gets the lock status of a player's home. The player does not need to be in this server.
    Can reject if getting a player's data fails.
]]
function HomeManager.getLockStatus(player: HomeOwnerParam)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerSettings.getSetting(userId, "homeLockStatus")
	end)
end

--[[
    Sets the lock status of a player's home. The player needs to be in this server.
]]
function HomeManager.setLockStatus(player: HomeOwnerParam, isLocked: boolean)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerSettings.setSetting(userId, "homeLockStatus", isLocked)
	end)
end

--[[
    Gets the home of a player. slot can be an itemId, index, or nil.
    The player does not need to be in this server.
    Can reject if getting a player's data fails.
]]
function HomeManager.getHome(player: HomeOwnerParam, slot: string | number | nil): Promise
	return InventoryManager.getHomes(player):andThen(function(homes)
		if type(slot) == "string" then
			return InventoryManager.getItemFromId(homes, slot)
		elseif type(slot) == "number" then
			return homes[slot]
		else -- type(slot) == "nil"
			return HomeManager.getSelectedHomeId(player):andThen(function(selectedHomeId)
				return HomeManager.getHome(player, selectedHomeId)
			end)
		end
	end)
end

--[[
	Gets the home server info of a player or homeowner wrapped in a promise.

	```lua
	homeServerInfo = {
		privateServerId = string,
		serverCode = string,
	},
	```
]]
function HomeManager.getHomeServerInfo(player: HomeOwnerParam)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerData.viewPlayerProfile(userId, true):andThen(function(profile)
			return profile.playerInfo.homeServerInfo
		end)
	end)
end

--[[
	Gets whether the home server info of a player or homeowner is stamped. The player does not need to be in this server.
]]
function HomeManager.isHomeInfoStamped(player: HomeOwnerParam)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(userId)
		return PlayerData.viewPlayerProfile(userId, true):andThen(function(profile)
			return profile.playerInfo.homeInfoStamped
		end)
	end)
end

--[[
	Returns a promise with the placed items of a player's active or specified home.
]]
function HomeManager.getPlacedItems(player: HomeOwnerParam, slot: string | number | nil)
	return HomeManager.getHome(player, slot):andThen(function(home)
		return home.placedItems
	end)
end

--[[
	Returns a promise with a placed item retrieved from an itemId.
]]
function HomeManager.getPlacedItemFromId(itemId, owner: HomeOwnerParam, slot: string | number | nil)
	return HomeManager.getPlacedItems(owner, slot):andThen(function(placedItems: { PlacedItem })
		for _, placedItem in ipairs(placedItems) do
			if placedItem.itemId == itemId then
				return placedItem
			end
		end
	end)
end

--[[
	Returns a promise with a boolean indicating whether a placed item exists in a player's active or specified home.
]]
function HomeManager.isItemPlaced(itemId, owner: HomeOwnerParam, slot: string | number | nil)
	return HomeManager.getPlacedItemFromId(itemId, owner, slot):andThen(function(placedItem)
		return placedItem ~= nil
	end)
end

--[[
	Returns a promise with a boolean indicating whether a player's active or specified home is full.
]]
function HomeManager.isPlacedItemsFull(player: HomeOwnerParam, numItemsToAdd, slot: string | number | nil)
	numItemsToAdd = numItemsToAdd or 0
	local maxFurniturePlaced = GameSettings.maxFurniturePlaced

	return HomeManager.getPlacedItems(player, slot):andThen(function(placedItems: { PlacedItem })
		if #placedItems + numItemsToAdd > maxFurniturePlaced or #placedItems == maxFurniturePlaced then
			return true
		end

		return false
	end)
end

--[[
	Returns a promise with a boolean indicating whether a player can place an item based on inventory space,
	whether the player owns the item, and whether or not the item is floating in the air.
	Can only be called in a home server.
]]
function HomeManager.canPlaceItem(itemId: string, pivotCFrame: CFrame): Promise
	return homeOwnerPromise:andThen(function(homeOwner: number)
		return Promise.all({
			HomeManager.isPlacedItemsFull(homeOwner, 1),
			InventoryManager.playerOwnsItem(homeOwner, itemId),
		}):andThen(function(results)
			local isPlacedItemsFull, playerOwnsItem = unpack(results)

			if isPlacedItemsFull then
				warn("HomeManager.placeItem: Placed items is full")
				return false
			end

			if not playerOwnsItem then
				warn("HomeManager.placeItem: player does not own item")
				return false
			end

			return SpacialQuery.getPartsTouchingPoint(pivotCFrame)[1] ~= nil
		end)
	end)
end

--[[
	Loads (or places), a placed item into the home server.
]]
function HomeManager.loadPlacedItem(placedItem: PlacedItem)
	return homeOwnerPromise:andThen(function(homeOwner: number)
		local itemId: string = placedItem.itemId
		local pivotCFrame: CFrame = Serialization.deserialize(placedItem.pivotCFrame)

		return InventoryManager.getItemFromId(homeOwner, placedItem.itemId):andThen(function(item)
			if item == nil then
				return Promise.reject("Item does not exist in inventory")
			end

			return Items.getFurnitureItem(item.itemEnum):andThen(function(info)
				local object = getLoadedItemFromId(itemId)

				object = object or info.model:Clone()

				object:SetAttribute(LOADED_ITEM_ATTRIBUTE, itemId)
				object:PivotTo(pivotCFrame)
				object.Parent = placedItemsFolder

				print("HomeManager.loadPlacedItem: loaded item", itemId)
			end)
		end)
	end)
end

--[[
	Unloads (or removes), a placed item from the home server.
]]
function HomeManager.unloadPlacedItem(placedItem: PlacedItem)
	return Promise.try(function()
		local object = getLoadedItemFromId(placedItem.itemId)
		assert(object, "HomeManager.unloadPlacedItem: object not found")

		object:Destroy()
	end)
end

--[[
	Adds/creates a placed item in a player's placedItems. The item is loaded right after.
]]
function HomeManager.addPlacedItem(itemId: string, pivotCFrame: CFrame)
	return homeOwnerPromise:andThen(function(homeOwner: number)
		return Promise.all({
			PlayerData.get(homeOwner):andThen(function(playerData)
				return playerData or Promise.reject("Player data not found")
			end),
			HomeManager.getPlacedItemFromId(itemId, homeOwner),
			HomeManager.getPlacedItems(homeOwner),
			HomeManager.getSelectedHomeIndex(homeOwner):andThen(function(selectedHomeIndex)
				return selectedHomeIndex or Promise.reject("Selected home index not found")
			end),
			HomeManager.canPlaceItem(itemId, pivotCFrame):andThen(function(canPlaceItem)
				if not canPlaceItem then
					return Promise.reject("Cannot place item")
				end
			end),
		}):andThen(function(results)
			local playerData: PlayerData, placedItem: PlacedItem | nil, placedItems: { PlacedItem }, selectedHomeIndex: number =
				table.unpack(results)
			local isItemPlaced = placedItem ~= nil

			placedItem = placedItem or {} :: PlacedItem
			placedItem.pivotCFrame = Serialization.serialize(pivotCFrame)
			placedItem.itemId = itemId

			local path = { "inventory", "homes", selectedHomeIndex, "placedItems" }

			if isItemPlaced then
				local placedItemIndex = table.find(placedItems, placedItem)

				if not placedItemIndex then
					return Promise.reject("Placed item not found")
				end

				playerData:arraySet(path, placedItemIndex, placedItem)
			else
				playerData:arrayInsert(path, placedItem)
			end

			return HomeManager.loadPlacedItem(placedItem)
		end)
	end)
end

--[[
	Removes a placed item from a player's placedItems. The item is unloaded right after.
]]
function HomeManager.removePlacedItem(itemId: string, player: HomeOwnerParam)
	return Param.playerParam(player, PlayerFormat.userId, true):andThen(function(homeOwner)
		return Promise.all({
			PlayerData.get(player):andThen(function(playerData)
				return playerData or Promise.reject("Player data not found")
			end),
			HomeManager.getPlacedItemFromId(itemId, homeOwner),
			HomeManager.getPlacedItems(homeOwner),
			HomeManager.getSelectedHomeIndex(homeOwner):andThen(function(selectedHomeIndex)
				return selectedHomeIndex or Promise.reject("Selected home index not found")
			end),
		}):andThen(function(results)
			local playerData: PlayerData, placedItem: PlacedItem | nil, placedItems: { PlacedItem }, selectedHomeIndex: number =
				table.unpack(results)

			if not placedItem then
				return Promise.reject("Placed item not found")
			end

			local placedItemIndex = table.find(placedItems, placedItem)

			if not placedItemIndex then
				return Promise.reject("Placed item index not found")
			end

			local path = { "inventory", "homes", selectedHomeIndex, "placedItems" }

			playerData:arrayRemove(path, placedItemIndex)

			return if isHomeServer then HomeManager.unloadPlacedItem(placedItem) else Promise.resolve()
		end)
	end)
end

--[[
	Loads all placed items found in a player's inventory into the workspace.
]]
function HomeManager.loadItems()
	return HomeManager.getPlacedItems():andThen(function(placedItems)
		return Promise.all(Table.editValues(placedItems, HomeManager.loadPlacedItem))
	end)
end

--[[
	Unloads all placed items found in a player's inventory from the workspace.
]]
function HomeManager.unloadItems()
	return HomeManager.getPlacedItems():andThen(function(placedItems)
		return Promise.all(Table.editValues(placedItems, HomeManager.unloadPlacedItem))
	end)
end

--[[
	Loads a home into the workspace.
]]
function HomeManager.loadHome()
	return HomeManager.getHome():andThen(function(home: InventoryItem | nil)
		assert(home)

		return Items.getHomeItem(home.itemEnum):andThen(function(homeInfo)
			local modelClone = homeInfo.model:Clone()
			modelClone.Name = "RenderedHome"
			modelClone.Parent = workspace

			return HomeManager.loadItems()
		end)
	end)
end

--[[
	Unloads a home from the workspace.
]]
function HomeManager.unloadHome()
	return Promise.try(function()
		assert(isHomeServer, "HomeManager.unrenderHome can only be called in a home server")

		workspace:FindFirstChild("RenderedHome"):Destroy()
		placedItemsFolder:ClearAllChildren()
	end)
end

PlayerData.forAllPlayerData(function(playerData: PlayerData)
	local player = playerData.player

	InventoryManager.getHomes(player)
		:andThen(function(homes: { InventoryItem })
			return Promise.resolve()
				:andThen(function()
					if #homes == 0 then
						return InventoryManager.newItemInInventory(ItemCategory.home, HomeType.defaultHome, player, {
							permanent = true,
						})
					end
				end)
				:andThen(function()
					return HomeManager.getSelectedHomeId(player):andThen(function(selectedHomeId)
						if not selectedHomeId or not HomeManager.getHome(player, selectedHomeId):expect() then
							return HomeManager.setSelectedHomeId(player, homes[1].id)
						end
					end)
				end)
				:andThen(function()
					return HomeManager.getHomeServerInfo(player):andThen(function(homeServerInfo: HomeServerInfo)
						if not (homeServerInfo and homeServerInfo.privateServerId and homeServerInfo.serverCode) then
							local function getReservedServer()
								return Promise.resolve()
									:andThen(function()
										return TeleportService:ReserveServer(GameSettings.homePlaceId)
									end)
									:andThen(function(...)
										local success, code, privateServerId = ...

										if success and code and privateServerId then
											return select(2, ...)
										end
									end)
							end

							return Promise.retry(getReservedServer, 5):andThen(function(code, privateServerId)
								playerData:setValue({ "playerInfo", "homeServerInfo" }, {
									serverCode = code,
									privateServerId = privateServerId,
								})
							end)
						end

						return Promise.resolve()
					end)
				end)
				:andThen(function()
					return HomeManager.isHomeInfoStamped(player):andThen(function(isStamped)
						if not isStamped then
							return ServerData.stampHomeServer(player)
						end
					end)
				end)
				:andThen(function()
					if isHomeServer and not initalLoad then
						initalLoad = true
						return HomeManager.loadHome()
					end
				end)
				:andThen(function()
					return HomeManager.getPlacedItems(player):andThen(function(placedItems: { PlacedItem })
						return Promise.all(Table.editValues(placedItems, function(placedItem: PlacedItem)
							return InventoryManager.playerOwnsItem(player, placedItem.itemId):andThen(function(owns)
								if not owns then
									return HomeManager.removePlacedItem(placedItem.itemId, player)
								end
							end)
						end))
					end)
				end)
				:andThen(function()
					if isHomeServer then
						return Promise.all(Table.editValues(getLoadedItems(), function(itemId)
							return InventoryManager.playerOwnsItem(player, itemId):andThen(function(owns)
								if not owns then
									return HomeManager.unloadPlacedItem(itemId)
								end
							end)
						end))
					end
				end)
		end)
		:catch(function(err)
			warn("HomeManager PlayerData Init Fail: ", err)
		end)
end)

InventoryManager.itemRemovedFromInventory:Connect(
	function(player: Player, itemCategory: UserEnum, _, item: InventoryItem)
		if itemCategory == ItemCategory.home then
			return HomeManager.getSelectedHomeId(player)
				:andThen(function(selectedHomeId)
					if selectedHomeId == item.id then
						return HomeManager.setSelectedHomeId(player, HomeManager.getHomes(player)[1].id)
					end
				end)
				:catch(function(err)
					warn("HomeManager itemRemovedFromInventory Fail: ", err)
				end)
		elseif itemCategory == ItemCategory.furniture then
			return HomeManager.isItemPlaced(item.id, player):andThen(function(isPlaced)
				if isPlaced then
					return HomeManager.removePlacedItem(item.id, player)
				end
			end)
		end
	end
)

return HomeManager
