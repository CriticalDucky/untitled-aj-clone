local ReplicatedFirst = game:GetService "ReplicatedFirst"

local ReplicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"

local Enums = require(ReplicatedFirstShared:WaitForChild "Enums")
local ItemTypeHome = Enums.ItemTypeHome

local ItemTypeHomeInfo = {
	[ItemTypeHome.developerHome] = {
		name = "Developer Home",
	},
	[ItemTypeHome.defaultHome] = {
		name = "Default Home",
	},
}

return ItemTypeHomeInfo
