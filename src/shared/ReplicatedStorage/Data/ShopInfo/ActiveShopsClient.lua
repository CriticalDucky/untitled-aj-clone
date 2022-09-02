local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))

print("Getting active shops...")

local ActiveShops = ReplicaCollection.get("ActiveShops", true)

print("Active Shops replica received")

return ActiveShops.Data