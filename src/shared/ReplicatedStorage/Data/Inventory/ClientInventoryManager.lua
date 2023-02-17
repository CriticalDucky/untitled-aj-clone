local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local Promise = require(utilityFolder:WaitForChild("Promise"))
local Types = require(utilityFolder:WaitForChild("Types"))

type Promise = Types.Promise
type LocalPlayerParam = Types.LocalPlayerParam
type UserEnum = Types.UserEnum

local ClientInventoryManager = {}

--[[
    Returns a promise that resolves to the player's inventory.
]]
function ClientInventoryManager.getInventory(player: LocalPlayerParam): Promise
	return ClientPlayerData.getData(player):andThen(function(data)
		return data.inventory
	end)
end

--[[
    Returns a promise that resolves to the player's inventory category.
]]
function ClientInventoryManager.getInventoryCategory(player: LocalPlayerParam, category: UserEnum): Promise
	return ClientInventoryManager.getInventory(player):andThen(function(inventory)
		return inventory[category]
	end)
end

return ClientInventoryManager