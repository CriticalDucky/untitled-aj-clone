local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local utilityFolder = replicatedFirstShared.Utility

local Promise = require(utilityFolder.Promise)

return Promise.new(function(resolve, reject)
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
    
            ServerData.traceServerInfo()
                :andThen(function(serverInfo)
                    ReplicaService.NewReplica({
                        ClassToken = ReplicaService.NewClassToken("HomeOwner"),
                        Data = {
                            homeOwner = serverInfo.homeOwner,
                        },
                        Replication = "All",
                    })
    
                    resolve(serverInfo.homeOwner)
                end)
                :catch(reject)
        end
    end
    
    local LocalHomeInfo = {}
    
    LocalHomeInfo.homeOwner = homeOwner
    
    resolve(LocalHomeInfo)
end)