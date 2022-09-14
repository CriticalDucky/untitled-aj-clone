local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))

local Teleport = {}

function Teleport.request(...)
    local TeleportRequest = ReplicaCollection.get("TeleportRequest")

    if not TeleportRequest then
        warn("TeleportRequest not found")
        return
    end

    return ReplicaRequest.new(TeleportRequest, ...)
end



return Teleport