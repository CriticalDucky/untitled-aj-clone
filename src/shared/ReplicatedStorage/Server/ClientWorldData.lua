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

local ClientWorldData = {}

local replica = ReplicaCollection.get("Worlds", true)

local worldDataValue = Fusion.Value(replica.Data)

replica:ListenToRaw(function()
    worldDataValue:set(replica.Data)
end)

function ClientWorldData:get()
    return worldDataValue:get()
end

function ClientWorldData.getWorldPopulation(worldIndex)
    local worldData = ClientWorldData:get()[worldIndex]

    local population = 0

    for _, locationData in pairs(worldData) do
        population += if locationData.serverInfo then locationData.serverInfo.players else 0
    end

    return population
end

function ClientWorldData.isWorldFull(worldIndex)
    return ClientWorldData.getWorldPopulation(worldIndex) >= #Locations.priority * GameSettings.location_maxPlayers
end

function ClientWorldData.isLocationFull(worldIndex, locationEnum)
    local locationData = ClientWorldData:get()[worldIndex][locationEnum]

    return locationData.serverInfo and locationData.serverInfo.players >= GameSettings.location_maxPlayers
end

return ClientWorldData