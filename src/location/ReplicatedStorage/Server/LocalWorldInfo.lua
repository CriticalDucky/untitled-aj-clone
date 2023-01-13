local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local Promise = require(utilityFolder:WaitForChild("Promise"))

return Promise.new(function(resolve, reject)
    if RunService:IsClient() then
        local ReplicaCollection = require(replicatedStorageShared:WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

        ReplicaCollection.get("WorldInfo", true)
            :andThen(function(worldInfoReplica)
                resolve(worldInfoReplica.Data.worldInfo)
            end)
    elseif RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")

        local serverStorageShared = ServerStorage.Shared
        local serverManagementFolder = serverStorageShared.ServerManagement

        local ReplicaService = require(serverStorageShared.Data.ReplicaService)
        local ServerData = require(serverManagementFolder.ServerData)

        ServerData.traceServerInfo()
            :andThen(function(serverInfo)
                ReplicaService.NewReplica({
                    ClassToken = ReplicaService.NewClassToken("WorldInfo"),
                    Data = {
                        worldInfo = serverInfo,
                    },
                    Replication = "All",
                })

                resolve(serverInfo)
            end)
            :catch(reject)
    end
end)