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
local enumsFolder = replicatedStorageShared.Enums

local PlayerData = require(dataFolder.PlayerData)
local Items = require(replicatedStorageInventory.Items)
local Table = require(utilityFolder.Table)
local Signal = require(utilityFolder.Signal)
local ItemProps = require(inventoryFolder.ItemProps)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local MiniId = require(utilityFolder.MiniId)
local Promise = require(utilityFolder.Promise)
local Types = require(utilityFolder.Types)
local ResponseType = require(enumsFolder.ResponseType)
local ItemCategory = require(enumsFolder.ItemCategory)
local Param = require(utilityFolder.Param)
local PlayerFormat = require(enumsFolder.PlayerFormat)

type PlayerData = Types.PlayerData
type InventoryItem = Types.InventoryItem
type UserEnum = Types.UserEnum
type PlayerParam = Types.PlayerParam
type HomeOwnerParam = Types.HomeOwnerParam

local function addPropsToItem(item: InventoryItem)
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

InventoryManager.itemPlacingInInventory = Signal.new()
InventoryManager.itemRemovedFromInventory = Signal.new()

--[[
    Returns a promise with the player's inventory.
]]
function InventoryManager.getInventory(player: PlayerParam)
	return PlayerData.viewPlayerProfile(player, true):andThen(function(profile)
		return profile.inventory
	end)
end

--[[
    Returns a promise with the player's specified inventory category.
]]
function InventoryManager.getInventoryCategory(player: PlayerParam, itemCategory: UserEnum)
	return InventoryManager.getInventory(player):andThen(function(inventory)
		return inventory[itemCategory]
	end)
end

function InventoryManager.getAccessories(player: PlayerParam)
	return InventoryManager.getInventoryCategory(player, ItemCategory.accessory)
end

function InventoryManager.getFurniture(player: PlayerParam)
	return InventoryManager.getInventoryCategory(player, ItemCategory.furniture)
end

function InventoryManager.getHomes(player: PlayerParam)
	return InventoryManager.getInventoryCategory(player, ItemCategory.home)
end

--[[
    Returns a promise with the player's specified inventory item.
]]
function InventoryManager.getItemFromIndex(player: PlayerParam, itemCategory: UserEnum, itemIndex: number)
	return InventoryManager.getInventoryCategory(player, itemCategory):andThen(function(inventoryCategory)
		return inventoryCategory[itemIndex]
	end)
end

--[[	
    Returns a promise with the item from the player's inventory with the specified id.
    itemSource can be a player, userid, or inventory category.
    itemId is the id of the item to search for.
    Note: This promise will resolve with nil if the item is not found.
]]
function InventoryManager.getItemFromId(itemSource: PlayerParam | { InventoryItem }, itemId: string)
	if typeof(itemSource) == "Instance" or typeof(itemSource) == "number" then
		return InventoryManager.getInventory(itemSource):andThen(function(inventory)
			for itemCategory: UserEnum, items: { InventoryItem } in pairs(inventory) do
				local success, item, index = InventoryManager.getItemFromId(items, itemId):await()

				if success and item then
					return item, itemCategory, index
				end
			end
		end)
	elseif typeof(itemSource) == "table" then
		for index, item: InventoryItem in pairs(itemSource) do
			if item.id == itemId then
				return Promise.resolve(item, index)
			end
		end

		return Promise.resolve(nil)
	else
		error("InventoryManager.searchWithId: Invalid argument #1")
	end
end

--[[
    Returns a promise with the item category and index of the item with the specified id.
    Note: This promise will resolve with nil if the item is not found.
]]
function InventoryManager.getItemPathFromId(player: PlayerParam, itemId: string)
	return InventoryManager.getItemFromId(player, itemId):andThen(function(_, itemCategory: UserEnum, index: number)
		return itemCategory, index
	end)
end

--[[
    Returns a promise containing whether or not the player owns the specified item.
]]
function InventoryManager.playerOwnsItem(player: PlayerParam, itemId)
	return InventoryManager.getItemFromId(player, itemId):andThen(function(item)
		return item ~= nil
	end)
end

--[[
    Returns a promise with whether or not the player owns all of the specified items.
]]
function InventoryManager.playerOwnsItems(player: PlayerParam, itemIds: { string | InventoryItem })
	itemIds = Table.editValues(itemIds, function(itemId: string | InventoryItem)
		return if type(itemId) == "table" then itemId.id else itemId
	end)

	return Promise.all(Table.editValues(itemIds, function(itemId)
		return InventoryManager.playerOwnsItem(player, itemId)
	end)):andThen(function(results)
		for _, result in pairs(results) do
			if not result then
				return false
			end
		end

		return true
	end)
end

--[[
    Returns a promise with a boolean indicating if the player's inventory is full.
    - player is the player to check
    - itemCategory is the category of the item to add
    - numItemsToAdd is the number of items to add (optional, defaults to 0)
]]
function InventoryManager.isInventoryFull(player: PlayerParam, itemCategory: UserEnum, numItemsToAdd: number?)
	return InventoryManager.getInventoryCategory(player, itemCategory):andThen(function(inventory)
		local numItems = #inventory

		numItemsToAdd = numItemsToAdd or 0

		local limit = GameSettings.inventoryLimits[itemCategory]

		if numItems == limit then
			return true
		end

		if numItems + numItemsToAdd > limit then -- OK
			return true
		end

		return false
	end)
end

--[[
    Internal function for removing an item from the player's inventory.
    - playerData is the player's data
    - itemCategory is the category of the item to remove
    - itemIndex is the index of the item to remove
]]
function InventoryManager._removeItem(playerData: PlayerParam | PlayerData, itemCategory: UserEnum, itemIndex: number)
	assert(playerData and itemCategory and itemIndex, "InventoryManager._removeItem: Invalid arguments")

	local playerPromise = if not typeof(playerData) == "table"
		then Param.playerParam(playerData, PlayerFormat.instance)
		else Promise.resolve(playerData.player)

	local playerDataPromise = if typeof(playerData) == "table"
		then Promise.resolve(playerData)
		else PlayerData.get(playerData)

	return Promise.all({ playerPromise, playerDataPromise }):andThen(function(results)
		local player: Player = results[1]
		local playerData: PlayerData = results[2]

		if not playerData then
			return Promise.reject(ResponseType.playerDataNotFound)
		end

		return InventoryManager.getItemFromIndex(player, itemCategory, itemIndex):andThen(function(item)
			playerData:arrayRemove({ "inventory", itemCategory }, itemIndex)

			InventoryManager.itemRemovedFromInventory:Fire(player, itemCategory, itemIndex, item)
		end)
	end)
end

--[[
    Internal function for adding an item to the player's inventory.
    - playerData is the player's data
    - itemCategory is the category of the item to add
    - item is the item to add
]]
function InventoryManager._addItem(playerData: PlayerParam | PlayerData, itemCategory: UserEnum, item: InventoryItem)
	assert(playerData and itemCategory and item, "InventoryManager._addItem: Invalid arguments")

	local playerPromise = if not typeof(playerData) == "table"
		then Param.playerParam(playerData, PlayerFormat.instance)
		else Promise.resolve(playerData.player)

	local playerDataPromise = if typeof(playerData) == "table"
		then Promise.resolve(playerData)
		else PlayerData.get(playerData)

	return Promise.all({ playerPromise, playerDataPromise }):andThen(function(results)
		local player: Player = results[1]
		local playerData: PlayerData = results[2]

		if not playerData then
			return Promise.reject(ResponseType.playerDataNotFound)
		end

		return InventoryManager.isInventoryFull(player, itemCategory, 1):andThen(function(isFull)
			if isFull then
				return Promise.reject(ResponseType.fullInventory)
			end

			InventoryManager.itemPlacingInInventory:Fire(player, itemCategory, item)

			playerData:arrayInsert({ "inventory", itemCategory }, item)
		end)
	end)
end

--[[
    Returns a promise resolving with a new item.
    - itemCategory is the category of the item to add
    - itemEnum is the enum of the item to add
    - props is a table of properties to add to the item (optional)
]]
function InventoryManager.newItem(itemCategory: UserEnum, itemEnum: UserEnum, props: table?)
	return Items.getItem(itemCategory, itemEnum):andThen(function()
		local item = addPropsToItem({
			id = MiniId(8),
			itemCategory = itemCategory,
			itemEnum = itemEnum,
		})

		return if props then Table.merge(if table.isfrozen(props) then Table.deepCopy(props) else props, item) else item
	end)
end

--[[
    Returns a promise that rejects if removing dupes fails.
    - owner is the player to remove dupes from
    - itemId is the id of the item to remove dupes of
]]
function InventoryManager.removeDupes(owner: PlayerParam, itemId: string | { string })
	if typeof(itemId) == "table" then
		return Promise.all(Table.editValues(itemId, function(itemId: string)
			return InventoryManager.removeDupes(owner, itemId)
		end))
	end

	return Promise.resolve()
		:andThen(function()
			return PlayerData.get(owner)
		end)
		:andThen(function(playerData: PlayerData | nil)
			if not playerData then
				return Promise.reject(ResponseType.playerDataNotFound)
			end

			return InventoryManager.getItemPathFromId(owner, itemId):andThen(function(itemCategory, index)
				return if itemCategory
					then table.unpack({
						{
							itemCategory = itemCategory,
							index = index,
						},
						playerData,
					})
					else Promise.reject(ResponseType.itemNotOwned)
			end)
		end)
		:andThen(function(path, playerData)
			return InventoryManager.getInventoryCategory(owner, path.itemCategory):andThen(function(inventory)
				for index, item in ipairs(inventory) do
					if item.id == itemId and index ~= path.index then
						InventoryManager._removeItem(playerData, path.itemCategory, index)

						return InventoryManager.removeDupes(owner, itemId)
					end
				end
			end)
		end)
end

--[[
	Internal function for changing the owner of items. The success of this function is not guaranteed.
	It will return a promise that rejects if the ownership changes for any reason.
	It rejects with an ResponseType enum.

	- If a current owner is provided but a new owner is not, the items will be removed from the current 
	owner's inventory.
	- If a new owner is provided but a current owner is not, the items will be added to the new owner's
	inventory.
	- If both a current owner and a new owner are provided, the items will be removed from the current
	owner's inventory and added to the new owner's inventory. If the new owner's inventory is full, the
	promise will reject.
]]
function InventoryManager._changeOwnerOfItems(
	items: { InventoryItem },
	currentOwner: PlayerParam | nil,
	newOwner: PlayerParam | nil
)
	assert(currentOwner or newOwner, "InventoryManager.changeOwnerOfItems: Both currentOwner and newOwner are nil")
	assert(#items > 0, "InventoryManager.changeOwnerOfItems: No items to change owner of")

	return Promise.new(function(resolve, reject)
		local function checkIfInventoryWouldBeFull()
			for _, item in pairs(items) do
				local otherItemsOfSameCategory = {}

				for _, otherItem in pairs(items) do
					if otherItem.itemCategory == item.itemCategory then
						table.insert(otherItemsOfSameCategory, otherItem)
					end
				end

				return InventoryManager.isInventoryFull(newOwner, item.itemCategory, #otherItemsOfSameCategory)
			end
		end

		if currentOwner then
			local valid = true

			InventoryManager.playerOwnsItems(currentOwner, items)
				:andThen(function(result)
					if result == false then
						warn("Player does not own items")

						return Promise.reject()
					end
				end)
				:catch(function()
					valid = false
				end)

			InventoryManager.removeDupes(currentOwner, items[1].id)
				:andThen(function()
					return InventoryManager.playerOwnsItems(currentOwner, items):andThen(function(result)
						if result == false then
							warn("Player does not own items")

							return Promise.reject()
						end
					end)
				end)
				:catch(function()
					valid = false
				end)

			if not valid then
				return reject(ResponseType.itemNotOwned)
			end
		end

		if newOwner and currentOwner then
			Promise.all({
				PlayerData.get(currentOwner),
				PlayerData.get(newOwner),
			})
				:andThen(function(results)
					return if results[1] and results[2]
						then table.unpack(results)
						else Promise.reject(ResponseType.playerDataNotFound)
				end)
				:andThen(function(currentOwnerData, newOwnerData)
					return checkIfInventoryWouldBeFull():andThen(function(wouldBeFull)
						if wouldBeFull then
							warn("New owner's inventory would be full")

							return Promise.reject(ResponseType.inventoryFull)
						end

						return Promise.all({
							Promise.all(Table.editValues(items, function(item)
								return InventoryManager.getItemPathFromId(currentOwner, item.id)
									:andThen(function(itemCategory, index)
										if not itemCategory then
											warn("Item path from id not found")

											return Promise.reject(ResponseType.itemNotOwned)
										end

										return InventoryManager._removeItem(currentOwnerData, itemCategory, index)
											:andThen(function()
												return InventoryManager._addItem(newOwnerData, itemCategory, item)
											end)
									end)
							end)),
						})
					end)
				end)
				:andThen(resolve)
				:catch(reject)
		elseif currentOwner and not newOwner then
			PlayerData.get(currentOwner)
				:andThen(function(playerData: PlayerData)
					return Promise.all(Table.editValues(items, function(item)
						return InventoryManager.getItemPathFromId(currentOwner, item.id)
							:andThen(function(itemCategory, index)
								if not itemCategory then
									warn("Item path from id not found")

									return Promise.reject(ResponseType.itemNotOwned)
								end

								return InventoryManager._removeItem(playerData, itemCategory, index)
							end)
					end))
				end)
				:andThen(resolve)
				:catch(reject)
		elseif not currentOwner and newOwner then
			PlayerData.get(newOwner)
				:andThen(function(playerData: PlayerData)
					return checkIfInventoryWouldBeFull():andThen(function(wouldBeFull)
						if wouldBeFull then
							warn("New owner's inventory would be full")

							return Promise.reject(ResponseType.inventoryFull)
						end

						return Promise.all(Table.editValues(items, function(item)
							return InventoryManager._addItem(playerData, item.itemCategory, item)
						end))
					end)
				end)
				:andThen(resolve)
				:catch(reject)
		end
	end)
end

--[[
	Adds an array of items to a player's inventory.
	Wrapper for InventoryManager._changeOwnerOfItems.
	This function can be used outside of this script. Note that all functions starting with a "_"
	are only to be used within this script. Players must be online and in the same server.
]]
function InventoryManager.addItemsToInventory(items: { InventoryItem }, player: PlayerParam)
	return InventoryManager._changeOwnerOfItems(items, nil, player)
end

--[[
	Removes an array of items from a player's inventory.
	Wrapper for InventoryManager._changeOwnerOfItems.
	This function can be used outside of this script. Note that all functions starting with a "_"
	are only to be used within this script. Players must be online and in the same server.
]]
function InventoryManager.removeItemsFromInventory(items: { InventoryItem }, player: PlayerParam)
	return InventoryManager._changeOwnerOfItems(items, player, nil)
end

--[[
	Creates a new item and puts in in the player's inventory using the specified itemCategory and itemEnum. Players must be online and in the same server.
]]
function InventoryManager.newItemInInventory(
	itemCategory: UserEnum,
	itemEnum: UserEnum,
	player: PlayerParam,
	props: { string: any }
)
	assert(itemCategory and itemEnum and player, "InventoryManager.newItemInInventory: Missing argument(s)")

	return InventoryManager.newItem(itemCategory, itemEnum, props):andThen(function(item)
		return InventoryManager.addItemsToInventory({ item }, player)
	end)
end

--[[
	Takes in the player data, and any props that are missing from any item's template are added
]]
function InventoryManager.reconcileItems(playerData: PlayerData): nil
	return InventoryManager.getInventory(playerData.player):andThen(function(inventory)
		for itemCategory, items in pairs(InventoryManager.getInventory(playerData.player) or {}) do
			local propTemplate = ItemProps[itemCategory]

			if not propTemplate then
				continue
			end

			for itemIndex, item in ipairs(items) do
				Table.recursiveIterate(propTemplate, function(path, value)
					local function index(t, indexPath)
						local element = t

						for _, index in ipairs(indexPath) do
							element = element[index]
						end

						return element
					end

					if index(item, Table.copy(path)) == nil then
						playerData:setValue(
							{ "inventory", itemCategory, itemIndex, table.unpack(path) },
							Table.deepCopy(value)
						)
					end
				end)
			end
		end
	end)
end

PlayerData.forAllPlayerData(function(...)
	InventoryManager.reconcileItems(...)
		:andThen(function()
			print("Reconciled items")
		end)
		:catch(function(err)
			warn("Failed to reconcile items: " .. tostring(err))
		end)
end)

return InventoryManager
