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
local GameType = require(enumsFolder:WaitForChild("GameType"))
local Table = require(utilityFolder:WaitForChild("Table"))

local PlayGame = {}

function PlayGame.request(gameType, ...)
    assert(Table.hasValue(GameType, gameType), "PlayGame.request() called with invalid gameType: " .. tostring(gameType))

    local response = ReplicaRequest.new(ReplicaCollection.get("PlayGameRequest"), gameType, ...)

    return response
end

return PlayGame
