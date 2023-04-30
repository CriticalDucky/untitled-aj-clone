--[[
    For replicating all the useful session info that Roblox neglected to replicate themselves.
]]

local ServerStorage = game:GetService("ServerStorage")

local serverStorageVendor = ServerStorage:WaitForChild("Vendor")

local ReplicaService = require(serverStorageVendor:WaitForChild("ReplicaService"))

ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("SessionInfo"),
    Data = {
        privateServerId = game.PrivateServerId,
        privateServerOwnerId = game.PrivateServerOwnerId,
        jobId = game.JobId,
    },
    Replication = "All"
})