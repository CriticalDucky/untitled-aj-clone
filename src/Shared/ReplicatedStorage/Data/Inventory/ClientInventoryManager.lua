--[[
	Provides an inventory interface for the client.
	Wrapper for ReplicatedPlayerData.lua.
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ReplicatedPlayerData = require(dataFolder:WaitForChild "ReplicatedPlayerData")
local Types = require(utilityFolder:WaitForChild "Types")

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local peek = Fusion.peek

type UserEnum = Types.UserEnum
type Inventory = Types.Inventory
type InventoryCategory = Types.InventoryCategory

local ClientInventoryManager = {}
ClientInventoryManager.value = ReplicatedPlayerData.value

local withData = {}
ClientInventoryManager.withData = withData

--[[
	Gets a player's inventory. Does not yield.

	Example usage for computeds:
	```lua
	Computed(function(use)
		local data = use(ClientInventoryManager.value)
		local inventory = ClientInventoryManager.withData.getInventory(data) -- Gets the local player's inventory
	end)
	```
]]
function withData.getInventory(data, player: Player | number | nil): Inventory?
	local profileData = ReplicatedPlayerData.withData.get(data, player)

	return profileData and profileData.inventory
end

--[[
	Gets a player's inventory category. Does not yield.

	Example usage for computeds:
	```lua
	Computed(function(use)
		local data = use(ClientInventoryManager.value)
		local inventoryCategory = ClientInventoryManager.withData.getInventoryCategory(data, category :: UserEnum) -- Gets the local player's inventory category
	end)
	```
]]
function withData.getInventoryCategory(data, category: UserEnum, player: Player | number | nil): InventoryCategory?
	local inventory = withData.getInventory(data, player)

	return inventory and inventory[category]
end

--[[
	Gets a player's inventory. Will yield until the player data is replicated.
	If you're getting the inventory inside a computed, use withData.getInventory instead.
]]
function ClientInventoryManager.getInventory(player: Player | number | nil): Inventory?
	local profileData = ReplicatedPlayerData.get(player)

	return profileData and withData.getInventory(profileData, player)
end

--[[
	Gets a player's inventory category with the specified category. Will yield until the player data is replicated.
	If you're getting the inventory category inside a computed, use withData.getInventoryCategory instead.
]]
function ClientInventoryManager.getInventoryCategory(category, player: Player | number | nil): InventoryCategory?
	local inventory = ClientInventoryManager.getInventory(player)

	return inventory and withData.getInventoryCategory(inventory, category, player)
end

return ClientInventoryManager
