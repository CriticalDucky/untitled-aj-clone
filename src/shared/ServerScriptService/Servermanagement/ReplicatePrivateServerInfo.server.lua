local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local dataFolder = serverStorageShared:WaitForChild("Data")

local ReplicaService = require(dataFolder:WaitForChild("ReplicaService"))

ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PrivateServerInfo"),
    Data = {
        privateServerId = game.PrivateServerId,
        privateServerOwnerId = game.PrivateServerOwnerId,
    },
    Replication = "All"
})