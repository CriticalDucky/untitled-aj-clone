local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")

local worldInfo

if RunService:IsClient() then
    local ReplicaCollection = require(replicatedStorageShared:WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

    worldInfo = ReplicaCollection.get("WorldInfo", true).Data.worldInfo
elseif RunService:IsServer() then
    local ServerStorage = game:GetService("ServerStorage")

    local serverStorageShared = ServerStorage.Shared
    local serverManagementFolder = serverStorageShared.ServerManagement

    local ReplicaService = require(serverStorageShared.Data.ReplicaService)
    local ServerData = require(serverManagementFolder.ServerData)

    worldInfo = ServerData.getServerInfo(ServerData.WORLDS_KEY)

    ReplicaService.NewReplica({
        ClassToken = ReplicaService.NewClassToken("WorldInfo"),
        Data = {
            worldInfo = worldInfo,
        },
        Replication = "All",
    })
end

local localWorldInfo = {}

localWorldInfo.worldIndex = worldInfo and worldInfo.worldIndex
localWorldInfo.locationEnum = worldInfo and worldInfo.locationEnum

return localWorldInfo