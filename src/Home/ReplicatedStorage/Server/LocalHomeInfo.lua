local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared

local homeOwner do
    if RunService:IsClient() then
        local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

        homeOwner = ReplicaCollection.get("HomeOwner", true).Data.homeOwner
    elseif RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")
    
        local serverStorageShared = ServerStorage.Shared
        local serverManagementFolder = serverStorageShared.ServerManagement
    
        local ReplicaService = require(serverStorageShared.Data.ReplicaService)
        local ServerData = require(serverManagementFolder.ServerData)

        local serverData = ServerData.traceServer()
        homeOwner = serverData and serverData.homeOwner

        ReplicaService.NewReplica({
            ClassToken = ReplicaService.NewClassToken("HomeOwner"),
            Data = {
                homeOwner = homeOwner,
            },
            Replication = "All",
        })
    end
end

local LocalHomeInfo = {}

LocalHomeInfo.homeOwner = homeOwner

return LocalHomeInfo