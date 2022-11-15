local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared

local homeOwner do
    if RunService:IsClient() then
        local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

        homeOwner = ReplicaCollection.get("HomeOwner", true).Data.userId
    elseif RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")
    
        local serverStorageShared = ServerStorage.Shared
    
        local ReplicaService = require(serverStorageShared.Data.ReplicaService)
        local Fingerprint = require(serverStorageShared.Utility.Fingerprint)
    
        _, homeOwner = Fingerprint.trace(game.PrivateServerId)

        ReplicaService.NewReplica({
            ClassToken = ReplicaService.NewClassToken("HomeOwner"),
            Data = {
                userId = homeOwner,
            },
            Replication = "All",
        })
    end
end

local LocalHomeInfo = {}

LocalHomeInfo.homeOwner = homeOwner

return LocalHomeInfo