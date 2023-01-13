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
local Signal = require(utilityFolder.Signal)
local ItemProps = require(inventoryFolder.ItemProps)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local MiniId = require(utilityFolder.MiniId)
local Promise = require(utilityFolder.Promise)
local Types = require(utilityFolder.Types)

type PlayerData = Types.PlayerData
type InventoryItem = Types.InventoryItem

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
function InventoryManager.getInventory(player: Player | number)
	return PlayerData.viewPlayerProfile(player, true):andThen(function(profile)
		return profile.inventory
	end)
end

--[[
    Returns a promise with the player's specified inventory category.
]]
function InventoryManager.getInventoryCategory(player: Player | number, itemCategory: string)
	return InventoryManager.getInventory(player):andThen(function(inventory)
		return inventory[itemCategory]
	end)
end

--[[
    Returns a promise with the player's specified inventory item.
]]
function InventoryManager.getItemFromIndex(player: Player | number, itemCategory: string, itemIndex: number)
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
function InventoryManager.getItemFromId(itemSource: Player | table | number, itemId: string)
	if typeof(itemSource) == "Instance" or typeof(itemSource) == "number" then
		return InventoryManager.getInventory(itemSource):andThen(function(inventory)
			for itemCategory: number, items: { InventoryItem } in pairs(inventory) do
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
function InventoryManager.getItemPathFromId(player: Player | number, itemId: string)
	return InventoryManager.getItemFromId(player, itemId):andThen(function(_, itemCategory: number, index: number)
		return itemCategory, index
	end)
end

--[[
    Returns a promise containing whether or not the player owns the specified item.
]]
function InventoryManager.playerOwnsItem(player: Player | number, itemId)
	return InventoryManager.getItemFromId(player, itemId):andThen(function(item)
		return item ~= nil
	end)
end

--[[
    Returns a promise with the item from the player's inventory with the specified id.
    itemSource can be a player, userid, or inventory category.
    itemId is the id of the item to search for.
    Note: This promise will resolve with nil if the item is not found.
]]
function InventoryManager.playerOwnsItems(player: Player | number, itemIds: { string | InventoryItem })
    itemIds = Table.map(itemIds, function(itemId: string | InventoryItem)
        return if type(itemId) == "table" then itemId.id else itemId
    end)

    return Promise.all(Table.map(itemIds, function(itemId)
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
function InventoryManager.isInventoryFull(player: Player | number, itemCategory: string, numItemsToAdd: number?)
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
function InventoryManager._removeItem(playerData: PlayerData | Player, itemCategory: string, itemIndex: number)
	assert(playerData and itemCategory and itemIndex, "InventoryManager._removeItem: Invalid arguments")
	local player: Player = if typeof(playerData) == "Instance" then playerData else playerData.player
	playerData = if typeof(playerData) == "Instance" then PlayerData.get(playerData) else Promise.resolve(playerData)

	return playerData:andThen(function(playerData)
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
function InventoryManager._addItem(playerData: PlayerData | Player, itemCategory: string, item: InventoryItem)
	assert(playerData and itemCategory and item, "InventoryManager._addItem: Invalid arguments")
	local player: Player = if typeof(playerData) == "Instance" then playerData else playerData.player
	playerData = if typeof(playerData) == "Instance" then PlayerData.get(playerData) else Promise.resolve(playerData)

	return playerData:andThen(function(playerData)
		return InventoryManager.isInventoryFull(player, itemCategory, 1):andThen(function(isFull)
			if isFull then
				return Promise.reject("Inventory is full")
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
function InventoryManager.newItem(itemCategory: string, itemEnum: number, props: table?)
	Items.getItem(itemCategory, itemEnum):andThen(function()
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
function InventoryManager.removeDupes(owner: Player, itemId: string | { string })
	if typeof(itemId) == "table" then
		return Promise.all(Table.map(itemId, function(_, itemId: string)
			return InventoryManager.removeDupes(owner, itemId)
		end))
	end

	return Promise.resolve()
		:andThen(function()
			return PlayerData.get(owner)
		end)
		:andThen(function(playerData)
			return InventoryManager.getItemPathFromId(owner, itemId):andThen(function(itemCategory, index)
				return if itemCategory
					then table.unpack({
						itemCategory = itemCategory,
						index = index,
					}, playerData)
					else Promise.reject("Item path from id not found")
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

function InventoryManager.changeOwnerOfItems(
	items: { InventoryItem },
	currentOwner: Player | nil,
	newOwner: Player | nil
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
            InventoryManager.playerOwnsItems(currentOwner, items):andThen(function(result)
                if result == false then
                    warn("Player does not own items")

                    return
                end
            end):catch(reject)

			InventoryManager.removeDupes(currentOwner, items[1].id):andThen(function()
                return InventoryManager.playerOwnsItems(currentOwner, items):andThen(function(result)
                    if result == false then
                        warn("Player does not own items")

                        return
                    end
                end)
            end):catch(reject)
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
				local itemIndex
				do
					for i, v in ipairs(InventoryManager.getInventoryCategory(currentOwner, item.itemCategory)) do
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
				local itemIndex
				do
					for i, v in ipairs(InventoryManager.getInventoryCategory(currentOwner, item.itemCategory)) do
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
	end)
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

	return InventoryManager.addItemsToInventory({ item }, player)
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
					playerData:setValue(
						{ "inventory", itemCategory, itemIndex, table.unpack(path) },
						Table.deepCopy(value)
					)
				end
			end)
		end
	end
end

PlayerData.forAllPlayerData(InventoryManager.reconcileItems)

return InventoryManager
