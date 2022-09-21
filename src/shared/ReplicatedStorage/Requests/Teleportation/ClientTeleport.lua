local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local Table = require(utilityFolder:WaitForChild("Table"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local TeleportRequestType = require(enumsFolder:WaitForChild("TeleportRequestType"))

local TeleportRequest = ReplicaCollection.get("TeleportRequest")

local Teleport = {}

function Teleport.request(teleportRequestType, ...)
    assert(Table.hasValue(TeleportRequestType, teleportRequestType), "Teleport.request() serverType must be a valid ServerTypeEnum value")

    return ReplicaRequest.new(TeleportRequest, teleportRequestType, ...)
end

function Teleport.toWorld(worldIndex)
    return Teleport.request(TeleportRequestType.toWorld, worldIndex)
end

return Teleport