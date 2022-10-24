local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("ReplicaCollection")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local madworkFolder = replicatedStorageShared:WaitForChild("Madwork")

local ReplicaController = require(madworkFolder:WaitForChild("ReplicaController"))

local replicas = {}
local classes = {
    "PlayerDataPrivate_" .. Players.LocalPlayer.UserId,
    "PlayerDataPublic",
    "ActiveShops",
    "PurchaseRequest",
    "TeleportRequest",
    "ServerInfo",
    "Worlds",
    "WorldInfo",
    "ServerUnixTime",
    "Parties"
}

local function onReplicaReceived(replica)
    local index = replica.Class

    if not replicas[index] then
        print("Replica recieved: ", index)
    end

    replicas[index] = replica
end

local replicaCollection = {}

function replicaCollection.get(class, wait) -- class must be either a string or a player
    assert(type(class) == "string", "ReplicaCollection.get: class must be a string")
    assert(table.find(classes, class), "ReplicaCollection.get: class must be a valid class")

    local lastPrint = time()

    while wait and not replicas[class] do
        task.wait()

        if time() - lastPrint > 5 then
            print("Waiting for replica", class)
            lastPrint = time()
        end
    end

    return replicas[class]
end

for _, class in ipairs(classes) do
    ReplicaController.ReplicaOfClassCreated(class, onReplicaReceived)
end

ReplicaController.NewReplicaSignal:Connect(onReplicaReceived)
ReplicaController.RequestData()

return replicaCollection