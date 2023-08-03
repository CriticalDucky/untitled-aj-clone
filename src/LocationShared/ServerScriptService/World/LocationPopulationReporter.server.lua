--[[
    Determines how long after the last report the location's population should be reported again if the location's
    population has not changed in that time.
]]
local REREPORT_INTERVAL = 60

--[[
    Reports the location's population to the world's population memory store.
]]

local MemoryStoreService = game:GetService "MemoryStoreService"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local LocationInfo = require(ServerStorage.LocationShared.World.LocationInfo)
local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

local location = LocationInfo.location
local world = LocationInfo.world

local worldLocationPopulations = MemoryStoreService:GetSortedMap(`World{world}LocationPopulations`)

local lastReportedTime

local function reportPopulation()
	lastReportedTime = time()

	local population = #Players:GetPlayers()

	task.spawn(
		function()
			MemoryStoreUtility.safeSortedMapSetAsync(
				worldLocationPopulations,
				location,
				population,
				REREPORT_INTERVAL + 5
			)
		end
	)
end

RunService.Heartbeat:Connect(function()
    if not lastReportedTime or time() - lastReportedTime > REREPORT_INTERVAL then
        reportPopulation()
    end
end)

Players.PlayerAdded:Connect(reportPopulation)
Players.PlayerRemoving:Connect(reportPopulation)

game:BindToClose(function()
    MemoryStoreUtility.safeSortedMapRemoveAsync(worldLocationPopulations, location)
end)
