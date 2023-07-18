--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"

-- Source

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

-- Types

type ItemFurnitureType = Types.ItemFurnitureType

--#endregion

--[[
	Represents the type of furniture.
]]
local ItemFurnitureType = {
	devFurniture = 1 :: ItemFurnitureType,
}

return ItemFurnitureType
