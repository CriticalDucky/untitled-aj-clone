--!strict

--[[
	#### NOTE ####

	When registering a new place ID, make sure to do the following:
	* If it is a location, register it in the server catalog control panel.
	* If adding a new location, minigame, or party, update the corresponding type in the `Types` module to include it.
	* Add the place ID to the `PLACE_IDS` table. If it is a new location, minigame, or party, the name MUST be a valid
	  type of that variant as specified in the `Types` module.
	* Update the `ServerInfo` module to identify the new place ID.
]]

--#region Imports

local ServerStorage = game:GetService "ServerStorage"

local ServerDirectives = require(ServerStorage.Shared.Utility.ServerDirectives)

local currentPlaceId = game.PlaceId

--#endregion

type PlaceIDs = {
	home: number,
	location: {
		forest: number,
		town: number,
	},
	minigame: {
		fishing: number,
		gatherer: number,
	},
	party: {
		beach: number,
	},
	routing: number,
}

type PlaceConfiguration = {
	recommendedPlayerCount: number,
}
type PlaceInfo = PlaceConfiguration & {
	placeId: number,
}

local PLACE_IDS: { [string]: PlaceIDs } = {
	production = {
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
		for k, idOrSubset in pairs(set) do
			if idOrSubset == placeId then return set end

			if type(idOrSubset) == "table" then
				for _, id in pairs(idOrSubset) do
					if id == placeId then return set end
				end
			end
		end
	end

	return
end

--#endregion

--[[
	The set of place IDs in this universe.
]]
local PlaceIds = getPlaceIdSet(currentPlaceId)

if not PlaceIds then ServerDirectives.shutDownServer "Failed to identify the current place ID." end

assert(PlaceIds)

return PlaceIds
