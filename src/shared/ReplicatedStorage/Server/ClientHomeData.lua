local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Table = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Table"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local GameSettings = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild("GameSettings"))

local ClientHomeData = {}

local replica = ReplicaCollection.get("HomeServers", true)

local homeDataValue = Fusion.Value(replica.Data)

replica:ListenToRaw(function()
    homeDataValue:set(replica.Data)
end)

function ClientHomeData:get()
    return homeDataValue:get()
end

function ClientHomeData.getHomePopulationInfo(userId)
    local homeData = ClientHomeData:get()[userId]
    local serverInfo = homeData and homeData.serverInfo

    if serverInfo then
        local population = #serverInfo.players

        return {
            population = population,
            max_emptySlots = math.max(GameSettings.home_maxNormalPlayers - population, 0),
        }
    end
end

function ClientHomeData.isHomeFull(userId)
    local populationInfo = ClientHomeData.getHomePopulationInfo(userId)

    if populationInfo then
        return populationInfo.max_emptySlots == 0
    end
end

return ClientHomeData