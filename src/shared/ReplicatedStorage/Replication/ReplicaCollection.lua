local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local madworkFolder = replicatedStorageShared:WaitForChild("Madwork")

local ReplicaController = require(madworkFolder:WaitForChild("ReplicaController"))
local Promise = require(utilityFolder:WaitForChild("Promise"))

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

local inclusiveClasses = { -- Classes that can be found inside a string. For example, "PlayerDataPrivate" can be found inside "PlayerDataPrivate_1234567890"
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

    return Promise.new(function(resolve)
        class = getInclusiveClass(class) or class

        local lastPrint = time()

        while wait and not replicas[class] do
            task.wait()

            if time() - lastPrint > 5 then
                print("Waiting for replica", class)
                lastPrint = time()
            end
        end

        resolve(replicas[class])
    end)
end

for _, class in ipairs(classes) do
    ReplicaController.ReplicaOfClassCreated(class, onReplicaReceived)
end

ReplicaController.NewReplicaSignal:Connect(onReplicaReceived)
ReplicaController.RequestData()

return replicaCollection