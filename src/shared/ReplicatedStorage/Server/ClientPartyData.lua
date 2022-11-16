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

local ClientPartyData = {}

local replica = ReplicaCollection.get("Parties", true)

local partyDataValue = Fusion.Value(replica.Data)

replica:ListenToRaw(function()
    partyDataValue:set(replica.Data)
end)

function ClientPartyData:get()
    return partyDataValue:get()
end

function ClientPartyData.getPartyPopulationInfo(partyType, privateServerId)
    local partyTypeData = ClientPartyData:get()[partyType]
    local privateServerData = partyTypeData and partyTypeData[privateServerId]
    local serverInfo = privateServerData and privateServerData.serverInfo

    if serverInfo then
        local population = #serverInfo.players

        return {
            population = population,
            recommended_emptySlots = math.max(GameSettings.party_maxRecommendedPlayers - population, 0),
            max_emptySlots = math.max(GameSettings.party_maxPlayers - population, 0),
        }
    end
end

function ClientPartyData.isPartyFull(partyType, privateServerId)
    local populationInfo = ClientPartyData.getPartyPopulationInfo(partyType, privateServerId)

    return populationInfo and populationInfo.max_emptySlots == 0
end

return ClientPartyData