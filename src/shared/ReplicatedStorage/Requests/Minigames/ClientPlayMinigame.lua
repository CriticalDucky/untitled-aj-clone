local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local MinigameType = require(enumsFolder:WaitForChild("MinigameType"))
local Table = require(utilityFolder:WaitForChild("Table"))

local ClientPlayMinigame = {}

function ClientPlayMinigame.request(minigameType, ...)
    assert(Table.hasValue(MinigameType, minigameType), "ClientPlayMinigame.request() called with invalid minigameType: " .. tostring(minigameType))

    local response = ReplicaRequest.new(ReplicaCollection.get("PlayMinigameRequest"), minigameType, ...)

    return response
end

return ClientPlayMinigame
