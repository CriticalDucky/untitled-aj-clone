local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local madworkFolder = replicatedStorageShared:WaitForChild("Madwork")

local ReplicaController = require(madworkFolder:WaitForChild("ReplicaController"))

local replicas = {}

local classes = {
    "PlayerDataPublic",
    "PurchaseRequest",
    "TeleportRequest",
    "WorldInfo",
    "ServerUnixTime",
    "HomeOwner",
    "PlaceItemRequest",
    "PlayGameRequest",
    "PartyIndex",
    "GameIndex",
    "LiveServerData",
    "ServerData",
}

local inclusiveClasses = {
    "PlayerDataPrivate"
}

local function getInclusiveClass(class)
    for _, inclusiveClass in pairs(inclusiveClasses) do
        if string.find(class, inclusiveClass) then
            return inclusiveClass
        end
    end

    return false
end

local function onReplicaReceived(replica)
    local class = replica.Class

    class = getInclusiveClass(class) or class

    if not replicas[class] then
        print("Replica recieved: ", class)
    end

    replicas[class] = replica
end

local replicaCollection = {}

function replicaCollection.get(class, wait) -- class must be either a string or a player
    assert(type(class) == "string", "ReplicaCollection.get: class must be a string")
    assert(table.find(classes, class) or getInclusiveClass(class), "ReplicaCollection.get: class must be a valid class")

    class = getInclusiveClass(class) or class

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