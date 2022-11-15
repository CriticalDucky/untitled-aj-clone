local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Table = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Table"))

local Value = Fusion.Value

local publicDataReplica = ReplicaCollection.get("PlayerDataPublic", true)

local playerDataTables = {}
local connections = {}
local publicDataLoaded = {}

local function addConnection(connection, player)
    connections[player] = connections[player] or {}
    table.insert(connections[player], connection)
end

local function removeAllConnections(player)
    if connections[player] then
        for _, connection in ipairs(connections[player]) do
            connection:Disconnect()
        end
        connections[player] = nil
    end
end

local playerData = {}

function playerData.add(player)
    local function connect(connection)
        addConnection(connection, player)
    end

    local data = {}
    local userIdKey = tostring(player.UserId)

    local function onReplicaChange()
        local value = data.value or Value()

        if publicDataReplica.Data[userIdKey] then
            publicDataLoaded[userIdKey] = true
        end

        if player == Players.LocalPlayer then
            for key, value in pairs(data._privateReplica.Data) do
                data._mergeTable[key] = value
            end

            if publicDataLoaded[userIdKey] then
                for key, value in pairs(publicDataReplica.Data[userIdKey]) do
                    data._mergeTable[key] = value
                end
            end

            value:set(data._mergeTable)
        else
            value:set(publicDataReplica.Data[userIdKey])
        end

        data.value = value
    end

    if player == Players.LocalPlayer then
        data._privateReplica = ReplicaCollection.get("PlayerDataPrivate", true)
        connect(data._privateReplica:ListenToRaw(onReplicaChange))
        data._mergeTable = {}
    end

    connect(publicDataReplica:ListenToRaw(onReplicaChange))

    playerDataTables[player] = data

    onReplicaChange()
end

function playerData.getData(player, wait)
    local lastPrint = time()

    while wait and not (playerDataTables[player] and playerDataTables[player].value and publicDataLoaded[tostring(player.UserId)]) do
        -- only print once every 5 seconds
        if time() - lastPrint > 5 then
            lastPrint = time()
            warn("Waiting for player data for " .. player.Name)
        end
        
        task.wait()
    end

    return playerDataTables[player].value
end

Players.PlayerRemoving:Connect(function(player)
    removeAllConnections(player)
    playerDataTables[player] = nil
end)

function playerData.getLocalPlayerData(wait)
    return playerData.getData(Players.LocalPlayer, wait)
end

return playerData