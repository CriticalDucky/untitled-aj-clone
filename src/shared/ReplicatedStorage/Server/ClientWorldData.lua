local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Table = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Table"))  

local ClientWorldData = ReplicaCollection.get("Worlds", true)

local worldDataValue = Fusion.Value(ClientWorldData.Data)

ClientWorldData:ListenToRaw(function()
    worldDataValue:set(ClientWorldData.Data)
end)

return worldDataValue