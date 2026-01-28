--!strict

--[[
	#### NOTE ####

	When registering a new place ID, make sure to do the following:
	* If it is a location, register it in the server catalog control panel.
	* Add the place ID to the `PLACE_IDS` table. If it is a new location, minigame, or party, the name MUST be a valid
	  type of that variant as specified in the `Types` module.
	* If it is a routable location, register it in the `StartingLocationInfo` module.
]]

--#region Imports

local ServerStorage = game:GetService "ServerStorage"

local ServerCatalog = require(ServerStorage.Shared.Universe.ServerCatalog)
local ServerDirectives = require(ServerStorage.Shared.Utility.ServerDirectives)

local currentPlaceId = game.PlaceId

--#endregion

type PlaceIDs = {
	home: number,
	minigame: {[string]: number},
	party: {[string]: number},
	routing: number,
}

local PLACE_IDS: { [string]: PlaceIDs } = {
	production = {
		home = 10564407502,
		minigame = {
			fishing = 11569189394,
			gatherer = 12939855185,
		},
		party = {
			beach = 11353468067,
		},
		routing = 10189729412,
	},
	testing = {
		home = 10564407502,
		location = {
			forest = 10212920968,
			town = 10189748812,
		},
		minigame = {
			fishing = 11569189394,
			gatherer = 12939855185,
		},
		party = {
			beach = 11353468067,
		},
		routing = 10189729412,
	},
}

--#region Calculate Context

local function getPlaceIdSet(placeId: number): PlaceIDs?
	for _, set in pairs(PLACE_IDS) do
		if set.home == placeId then return set end

		for _, id in pairs(set.minigame) do
			if id == placeId then return set end
		end

		for _, id in pairs(set.party) do
			if id == placeId then return set end
		end

		if set.routing == placeId then return set end
	end

	return
end

--#endregion

--[[
	The set of place IDs in this universe.
]]
local PlaceIds = getPlaceIdSet(currentPlaceId)

if not PlaceIds then
	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then ServerDirectives.shutDownServer "Failed to retrieve the server's location list." end

	assert(locationList)

end

if not PlaceIds then ServerDirectives.shutDownServer "Failed to identify the server's place ID." end

assert(PlaceIds)

return PlaceIds
