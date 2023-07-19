local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local enumsFolder = replicatedFirstShared:WaitForChild("Enums")
local map = workspace:WaitForChild("Map")
local entrances = map:WaitForChild("Entrances")
local mainEntrance = entrances:WaitForChild("MainEntrance")

local LocationTypeEnum = require(enumsFolder:WaitForChild("LocationType"))

local function getComponents(name)
	local entranceGroup = entrances:WaitForChild(name)

	return {
		entrance = entranceGroup:WaitForChild("Entrance"),
		exit = entranceGroup:WaitForChild("Exit"),
	}
end

local entranceGroupTable = {
	groups = {
		[LocationTypeEnum.town] = getComponents("Town"),
	},

	main = mainEntrance,
}

return entranceGroupTable