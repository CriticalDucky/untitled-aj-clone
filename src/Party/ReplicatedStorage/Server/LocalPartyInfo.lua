local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local Parties = require(serverFolder:WaitForChild("Parties"))

local LocalPartyInfo = {}

for partyType, partyInfo in pairs(Parties) do
    if partyInfo.placeId == game.PlaceId then
        LocalPartyInfo.partyType = partyType
        break
    end
end

if RunService:IsClient() then
    local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

    LocalPartyInfo.partyIndex = ReplicaCollection.get("PartyIndex", true).Data.partyIndex
elseif RunService:IsServer() then
    local ServerStorage = game:GetService("ServerStorage")

    local serverStorageShared = ServerStorage.Shared
    local serverManagementFolder = serverStorageShared.ServerManagement

    local ReplicaService = require(serverStorageShared.Data.ReplicaService)
    local ServerData = require(serverManagementFolder.ServerData)

    local serverData = ServerData.traceServer()
    LocalPartyInfo.partyIndex = serverData and serverData.partyIndex

    ReplicaService.NewReplica({
        ClassToken = ReplicaService.NewClassToken("PartyIndex"),
        Data = {
            partyIndex = LocalPartyInfo.partyIndex,
        },
        Replication = "All",
    })
end

local a = {}

return LocalPartyInfo

