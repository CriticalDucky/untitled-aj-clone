--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"

-- Source

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

-- Types

type ItemHomeType = Types.ItemHomeType

--#endregion

--[[
	Represents the type of a home.
]]
local ItemHomeType = {
	devHome = 1 :: ItemHomeType,
}

return ItemHomeType
