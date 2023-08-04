--!strict

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

assert(not RunService:IsStudio(), "This module cannot be used in Studio.")

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type CatalogMinigameData = Types.CatalogMinigameData
type CatalogPartyData = Types.CatalogPartyData
type CatalogWorldData = Types.CatalogWorldData

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"

local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

--[[
    Provides access to the server catalog.
]]
local ServerCatalog = {}

--[[
    Returns world data for the given world.

    ---

    @param world The world to get data for.
    @return The world data, or `nil` if the world does not exist or an error occurred.
]]
function ServerCatalog.getWorldAsync(world: number): CatalogWorldData?
	assert(
		typeof(world) == "number" and world == world and world == math.floor(world) and world >= 1,
		"The world must be a positive integer."
	)

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount or world > worldCount then return end

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then return end

	local success, rawWorldData: CatalogWorldData = DataStoreUtility.safeGetAsync(worldCatalog, tostring(world))

	if not success then return end

	local worldData = {}

	for locationName in pairs(locationList) do
		worldData[locationName] = rawWorldData[locationName]
	end

	return worldData
end

--[[
    Returns the number of worlds that exist.

    ---

    @return The number of worlds that exist, or `nil` if an error occurred.
]]
function ServerCatalog.getWorldCountAsync(): number?
	local success, worldCount = DataStoreUtility.safeGetAsync(catalogInfo, "WorldCount")

	if not success then return end

	return worldCount or 0
end

--[[
    Returns the set of all locations that exist, including their place IDs.

    ---

    @return The set of all locations that exist, including their place IDs, or `nil` if an error occurred.
]]
function ServerCatalog.getWorldLocationListAsync(): { [string]: { placeId: number } }?
	local success, locationList = DataStoreUtility.safeGetAsync(catalogInfo, "WorldLocationList")

	if not success then return end

	return locationList or {}
end

return ServerCatalog
