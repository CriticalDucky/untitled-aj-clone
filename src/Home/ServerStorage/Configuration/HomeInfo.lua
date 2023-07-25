local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local Enums = require(ReplicatedFirst.Shared.Enums)
local ItemTypeHome = Enums.ItemTypeHome
local HomeModels = require(ServerStorage.Models.HomeModels)

local HomeInfo = {
	[ItemTypeHome.developerHome] = {
		model = HomeModels.DeveloperHome,
	},
	[ItemTypeHome.defaultHome] = {
		model = HomeModels.DefaultHome,
	},
}

return HomeInfo
