--!strict

local PLACE_IDS = {
	production = {
		home = 10564407502,
		locationForest = 10212920968,
		locationTown = 10189748812,
		minigameFishing = 11569189394,
		minigameGatherer = 12939855185,
		partyBeach = 11353468067,
		routing = 10189729412,
	},
	testing = {
		home = 10564407502,
		locationForest = 10212920968,
		locationTown = 10189748812,
		minigameFishing = 11569189394,
		minigameGatherer = 12939855185,
		partyBeach = 11353468067,
		routing = 10189729412,
	},
}

local currentPlaceId = game.PlaceId

local PlaceIds: typeof(PLACE_IDS.production) | typeof(PLACE_IDS.testing)

local identifiedPlaceId = false

for context, placeIdList in pairs(PLACE_IDS) do
	for name, placeId in pairs(placeIdList) do
		if placeId == currentPlaceId then
			PlaceIds = placeIdList
			identifiedPlaceId = true
			break
		end
	end
end

if not identifiedPlaceId then error "Failed to identify the current place ID." end

return PlaceIds
