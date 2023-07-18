--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"

-- Source

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

-- Types

type ItemAccessoryType = Types.ItemAccessoryType

--#endregion

--[[
	Represents the type of an accessory.
]]
local ItemAccessoryType = {
	devAccessory = 1 :: ItemAccessoryType,
}

return ItemAccessoryType
