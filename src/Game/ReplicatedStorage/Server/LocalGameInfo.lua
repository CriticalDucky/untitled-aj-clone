local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared

local gameType do
    if RunService:IsClient() then
        local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

        gameType = ReplicaCollection.get("GameType", true).Data.gameType
    elseif RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")
    
        local serverStorageShared = ServerStorage.Shared
    
        local ReplicaService = require(serverStorageShared.Data.ReplicaService)
        local Fingerprint = require(serverStorageShared.Utility.Fingerprint)
    
        _, gameType = Fingerprint.trace(game.PrivateServerId)

        ReplicaService.NewReplica({
            ClassToken = ReplicaService.NewClassToken("GameType"),
            Data = {
                gameType = gameType,
            },
            Replication = "All",
        })
    end
end

local LocalGameInfo = {}

LocalGameInfo.gameType = gameType

return LocalGameInfo