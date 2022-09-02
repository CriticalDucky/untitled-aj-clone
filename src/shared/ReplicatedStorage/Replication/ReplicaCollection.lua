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
    "PurchaseResponse",
}

local function onReplicaReceived(replica)
    warn("Replica recieved: ", replica.Class)
    replicas[replica.Data.sender or replica.Class] = replica
end

local replicaCollection = {}

function replicaCollection.get(class, wait) -- class must be either a string or a player
    assert(type(class) == "string" or (typeof(class) == "Instance" and class:IsA("Player")), "class must be either a string or a player")
    assert(if type(class) == "string" then table.find(classes, class) else true, "class must be a valid class")

    while wait and not replicas[class] do
        task.wait()

        if os.time() % 3 == 0 then
            print("Waiting for replica", class)
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