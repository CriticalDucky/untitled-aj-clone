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

local minigameCatalog = DataStoreService:GetDataStore "MinigameCatalog"
local partyCatalog = DataStoreService:GetDataStore "PartyCatalog"
local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

--[[
    Provides access to the server catalog.
]]
local ServerCatalog = {}

--[[
	Returns minigame data for the given minigame.

	---

	@param minigame The minigame to get data for.
	@return The minigame data, or `nil` if the minigame does not exist or an error occurred.
]]
function ServerCatalog.getMinigameAsync(minigame: string): CatalogMinigameData?
	local minigameList = ServerCatalog.getMinigameListAsync()

	if not minigameList or not minigameList[minigame] then return end

	local serverCount = ServerCatalog.getMinigameServerCountAsync()

	if not serverCount then return end

	local success, rawMinigameData: CatalogMinigameData = DataStoreUtility.safeGetAsync(minigameCatalog, minigame)

	if not success then return end

	local minigameData = {}

	for i = 1, serverCount do
		minigameData[i] = rawMinigameData[i]
	end

	return minigameData
end

--[[
    Returns the set of all minigames that exist, including their place IDs.

    ---

    @return The set of all minigames that exist, including their place IDs, or `nil` if an error occurred.
]]
function ServerCatalog.getMinigameListAsync(): { [string]: { placeId: number } }?
	local success, minigameList = DataStoreUtility.safeGetAsync(catalogInfo, "MinigameList")

	if not success then return end

	return minigameList or {}
end

--[[
    Returns the number of servers that exist for each minigame.

    ---

    @return The number of servers that exist for each minigame, or `nil` if an error occurred.
]]
function ServerCatalog.getMinigameServerCountAsync(): number?
	local success, minigameServerCount = DataStoreUtility.safeGetAsync(catalogInfo, "MinigameServerCount")

	if not success then return end

	return minigameServerCount or 0
end

--[[
	Returns party data for the given party.

	---

	@param party The party to get data for.
	@return The party data, or `nil` if the party does not exist or an error occurred.
]]
function ServerCatalog.getPartyAsync(party: string): CatalogPartyData?
	local partyList = ServerCatalog.getPartyListAsync()

	if not partyList or not partyList[party] then return end

	local serverCount = ServerCatalog.getPartyServerCountAsync()

	if not serverCount then return end

	local success, rawPartyData: CatalogPartyData = DataStoreUtility.safeGetAsync(partyCatalog, party)

	if not success then return end

	local partyData = {}

	for i = 1, serverCount do
		partyData[i] = rawPartyData[i]
	end

	return partyData
end

--[[
	Returns the set of all parties that exist, including their place IDs.

	---

	@return The set of all parties that exist, including their place IDs, or `nil` if an error occurred.
]]
function ServerCatalog.getPartyListAsync(): { [string]: { placeId: number } }?
	local success, partyList = DataStoreUtility.safeGetAsync(catalogInfo, "PartyList")

	if not success then return end

	return partyList or {}
end

--[[
	Returns the number of servers that exist for each party.

	---

	@return The number of servers that exist for each party, or `nil` if an error occurred.
]]
function ServerCatalog.getPartyServerCountAsync(): number?
	local success, partyServerCount = DataStoreUtility.safeGetAsync(catalogInfo, "PartyServerCount")

	if not success then return end

	return partyServerCount or 0
end

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
