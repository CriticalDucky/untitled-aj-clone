local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local madworkFolder = replicatedStorageShared:WaitForChild("Madwork")

local ReplicaController = require(madworkFolder:WaitForChild("ReplicaController"))

local replicas = {}
local classes = {
    "PlayerDataPrivate_" .. Players.LocalPlayer.UserId,
    "PlayerDataPublic",
    "ActiveShops",
    "PurchaseRequest",
    "PurchaseResponse",
}

for _, class in ipairs(classes) do
    ReplicaController.ReplicaOfClassCreated(class, function(replica)
        replicas[(replica.Data.sender and replica.Data.sender) or class] = replica
    end)
end

local replicaCollection = {}

function replicaCollection.get(class, wait)
    assert(type(class) == "string", "class must be a string")
    assert(classes[class], "class must be one of " .. table.concat(classes, ", "))

    if wait then
        while not replicas[class] do
            task.wait()
        end
    end

    return replicas[class]
end

ReplicaController.RequestData()

return replicaCollection