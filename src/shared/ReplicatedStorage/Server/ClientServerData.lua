local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local GAMES_KEY = "games"

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))

local replica = ReplicaCollection.get("ServerData", true)

local serverDataValue = Fusion.Value(replica.Data)

replica:ListenToRaw(function()
    serverDataValue:set(replica.Data)
end)

local ClientServerData = {}

function ClientServerData.get()
    return serverDataValue:get()
end

function ClientServerData.getWorlds()
    return ClientServerData:get()[WORLDS_KEY]
end

function ClientServerData.getParties()
    return ClientServerData:get()[PARTIES_KEY]
end

function ClientServerData.getGames()
    return ClientServerData:get()[GAMES_KEY]
end

function ClientServerData.worldHasLocation(worldIndex, locationEnum)
    local worlds = ClientServerData.getWorlds()

    if worlds[worldIndex] then
        local locations = worlds[worldIndex].locations

        if locations[locationEnum] then
            return true
        end
    end
end

return ClientServerData