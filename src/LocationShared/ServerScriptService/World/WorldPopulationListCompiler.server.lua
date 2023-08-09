--!strict

--[[
    Determines how often to compile the world population list.
]]
local REPORT_INTERVAL = 30

local MemoryStoreService = game:GetService "MemoryStoreService"
local ServerStorage = game:GetService "ServerStorage"

local ServerCatalog = require(ServerStorage.Shared.Universe.ServerCatalog)
local ServerInfo = require(ServerStorage.Shared.Universe.ServerInfo)
local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

assert(ServerInfo and ServerInfo.type == "location")

local location = ServerInfo.location
local world = ServerInfo.world

-- Only compile the world population list on the main location server of the first world.
if location ~= "town" or world ~= 1 then return end

local catalogInfo = MemoryStoreService:GetSortedMap "CatalogInfo"
local worldPopulations = MemoryStoreService:GetSortedMap "WorldPopulations"

local lastBeganReporting

repeat
	lastBeganReporting = time()

	local getAllPopulationsSuccess, worldPopulationsCollection: {{key: string, value:number}} =
		MemoryStoreUtility.safeSortedMapGetAllAsync(worldPopulations, Enum.SortDirection.Ascending)

	if not getAllPopulationsSuccess then
		warn "Failed to get all world populations when compiling the world population list."
		continue
	end

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to get world count when compiling the world population list."
		continue
	end
	assert(worldCount)

	local worldPopulationsMap = {}

	for _, worldPopulation in pairs(worldPopulationsCollection) do
		worldPopulationsMap[worldPopulation.key] = worldPopulation.value
	end

	local worldPopulationList = {}

	for worldNumber = 1, worldCount do
		local worldPopulation = worldPopulationsMap[`World{worldNumber}`] or 0

		worldPopulationList[worldNumber] = worldPopulation
	end

	MemoryStoreUtility.safeSortedMapSetAsync(
		catalogInfo,
		"WorldPopulationList",
		worldPopulationList,
		REPORT_INTERVAL + 5
	)
until not task.wait(REPORT_INTERVAL - time() + lastBeganReporting)
