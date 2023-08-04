--!strict

--[[
    Determines how often to compile the world population list.
]]
local REPORT_INTERVAL = 10

local MemoryStoreService = game:GetService "MemoryStoreService"
local ServerStorage = game:GetService "ServerStorage"

local ServerInfo = require(ServerStorage.Shared.Universe.ServerInfo)
local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

assert(ServerInfo.type == "location")

local location = ServerInfo.location
local world = ServerInfo.world

-- Only compile the world population list on the main location server of the first world.
if location ~= "town" or world ~= 1 then return end

local worldPopulationList = MemoryStoreService:GetSortedMap "WorldPopulationList"
local worldPopulations = MemoryStoreService:GetSortedMap "WorldPopulations"

local lastBeganReporting

repeat
	lastBeganReporting = time()

	local getAllPopulationsSuccess, worldPopulationsCollection =
		MemoryStoreUtility.safeSortedMapGetAllAsync(worldPopulations, Enum.SortDirection.Ascending)

	if not getAllPopulationsSuccess then
		warn "Failed to get all world populations."
		return
	end

	local newWorldPopulationList = {}

	for _, worldPopulation in pairs(worldPopulationsCollection) do
		local currentWorldString = worldPopulation.key:match "%d+"

		if not currentWorldString then
			warn(`Failed to get world number from world population key '{worldPopulation.key}'`)
			continue
		end

		local currentWorld = tonumber(currentWorldString)

		newWorldPopulationList[currentWorld] = worldPopulation.value
	end

	MemoryStoreUtility.safeSortedMapSetAsync(
		worldPopulationList,
		"WorldPopulationList",
		newWorldPopulationList,
		REPORT_INTERVAL + 5
	)
until not task.wait(REPORT_INTERVAL - time() + lastBeganReporting)
