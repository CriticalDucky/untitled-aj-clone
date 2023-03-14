--[[
	Provides an inventory interface for the client.
	Wrapper for ReplicatedPlayerData.lua.

	See GameSettings.lua to see how player data is structured and replicated.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ReplicatedPlayerData = require(dataFolder:WaitForChild("ReplicatedPlayerData"))
local Types = require(utilityFolder:WaitForChild("Types"))

type Promise = Types.Promise
type LocalPlayerParam = Types.LocalPlayerParam
type UserEnum = Types.UserEnum

local ClientInventoryManager = {}

--[[
	Gets a player's inventory. If the player data is not replicated, this will return nil unless wait is true.
]]
function ClientInventoryManager.getInventory(player: Player | number | nil, wait: boolean)
	local data = ReplicatedPlayerData.get(player, wait)

	if data then
		return data.inventory
	end
end

--[[
	Gets a player's inventory category. If the player data is not replicated, this will return nil unless wait is true.
]]
function ClientInventoryManager.getInventoryCategory(player: Player | number | nil, category: UserEnum, wait: boolean)
	local inventory = ClientInventoryManager.getInventory(player, wait)

	if inventory then
		return inventory[category]
	end
end

return ClientInventoryManager