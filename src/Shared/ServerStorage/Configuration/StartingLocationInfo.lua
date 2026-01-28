--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Types = require(ReplicatedFirst.Shared.Utility.Types)

type LocationType = Types.LocationType

--#endregion

type StartingLocationInfo = {
	{
		location: LocationType,
		maxRecommendedPlayers: number,
	}
}

--[[
	The locations to route to when a player joins a world, in order of priority. Each location is checked in that order
	until a location is found that has less players than `maxRecommendedPlayers`. If no location is found, the player
	will fail to join the world.
]]
local StartingLocationInfo: StartingLocationInfo = {
	{
		location = "town",
		maxRecommendedPlayers = 30,
	},
}

return StartingLocationInfo
