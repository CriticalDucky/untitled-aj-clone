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

local ServerInfo = require(ServerStorage.Shared.Universe.ServerInfo)
local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

assert(ServerInfo and ServerInfo.type == "location")

local location = ServerInfo.location
local world = ServerInfo.world

local worldLocationPopulations = MemoryStoreService:GetSortedMap(`World{world}LocationPopulations`)

local lastReportedTime

local function reportPopulation()
	lastReportedTime = time()

	local population = #Players:GetPlayers()

	MemoryStoreUtility.safeSortedMapSetAsync(worldLocationPopulations, location, population, REREPORT_INTERVAL + 5)
end

local heartbeatConnection = RunService.Heartbeat:Connect(function()
	if not lastReportedTime or time() - lastReportedTime > REREPORT_INTERVAL then reportPopulation() end
end)

local playerAddedConnection = Players.PlayerAdded:Connect(reportPopulation)
local playerRemovingConnection = Players.PlayerRemoving:Connect(reportPopulation)

game:BindToClose(function()
	heartbeatConnection:Disconnect()
	playerAddedConnection:Disconnect()
	playerRemovingConnection:Disconnect()

	MemoryStoreUtility.safeSortedMapRemoveAsync(worldLocationPopulations, location)
end)
