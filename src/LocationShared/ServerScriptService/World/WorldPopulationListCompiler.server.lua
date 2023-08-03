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

repeat
	task.spawn(function()
		local getAllPopulationsSuccess, worldPopulations =
			MemoryStoreUtility.safeSortedMapGetAllAsync(worldPopulations, Enum.SortDirection.Ascending)

		if not getAllPopulationsSuccess then
			warn "Failed to get all world populations."
			return
		end

		local newWorldPopulationList = {}

		for _, worldPopulation in pairs(worldPopulations) do
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
	end)
until not task.wait(REPORT_INTERVAL)
