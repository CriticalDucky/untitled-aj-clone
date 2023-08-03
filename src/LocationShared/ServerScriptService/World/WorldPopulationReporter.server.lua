--!strict

--[[
    Determines how often to report the world's population to the world population memory store.
]]
local REPORT_INTERVAL = 10

local MemoryStoreService = game:GetService "MemoryStoreService"
local ServerStorage = game:GetService "ServerStorage"

local LocationInfo = require(ServerStorage.LocationShared.World.LocationInfo)
local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

local location = LocationInfo.location
local world = LocationInfo.world

-- Only report the world's population if this is the main location server.
if location ~= "town" then return end

local worldLocationPopulations = MemoryStoreService:GetSortedMap(`World{world}LocationPopulations`)
local worldPopulations = MemoryStoreService:GetSortedMap("WorldPopulations")

repeat
	task.spawn(function()
		local getAllPopulationsSuccess, locationPopulations =
			MemoryStoreUtility.safeSortedMapGetAllAsync(worldLocationPopulations, Enum.SortDirection.Ascending)

		if not getAllPopulationsSuccess then
			warn "Failed to get all location populations."
			return
		end

		local worldPopulation = 0

		for _, population in pairs(locationPopulations) do
			worldPopulation += population.value
		end

		MemoryStoreUtility.safeSortedMapSetAsync(worldPopulations, `World{world}`, worldPopulation, REPORT_INTERVAL + 5)
	end)
until not task.wait(REPORT_INTERVAL)
