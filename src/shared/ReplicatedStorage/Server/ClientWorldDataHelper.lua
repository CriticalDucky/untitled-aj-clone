local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local Locations = require(serverFolder:WaitForChild("Locations"))
local Constants = require(serverFolder:WaitForChild("Constants"))

local Helper = {}

function Helper.getWorldPopulation(worldData)
    local population = 0

    for _, locationData in pairs(worldData) do
        population += if locationData.serverInfo then locationData.serverInfo.players else 0
    end

    return population
end

function Helper.isWorldFull(worldData)
    return Helper.getWorldPopulation(worldData) >= #Locations.priority * Constants.location_maxPlayers
end

function Helper.isLocationFull(locationData)
    return locationData.serverInfo and locationData.serverInfo.players >= Constants.location_maxPlayers
end

return Helper