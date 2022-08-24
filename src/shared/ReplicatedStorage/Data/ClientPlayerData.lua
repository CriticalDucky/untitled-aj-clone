local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedStorageShared:WaitForChild("Fusion"))

local Value = Fusion.Value

local playerDataTables = {}
local connections = {}

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

    local function onReplicaChange()
        local value = data.value or Value()

        if player == Players.LocalPlayer then
            for key, value in pairs(data._privateReplica.Data) do
                data._mergeTable[key] = value
            end

            for key, value in pairs(data._publicReplica.Data) do
                data._mergeTable[key] = value
            end

            value:set(data._mergeTable)
        else
            value:set(data._publicReplica.Data)
        end

        data.value = value
    end

    data._publicReplica = ReplicaCollection.get(player, true)
    connect(data._publicReplica:ListenToRaw(onReplicaChange))

    if player == Players.LocalPlayer then
        data._privateReplica = ReplicaCollection.get("PlayerDataPrivate_" .. player.UserId, true)
        connect(data._privateReplica:ListenToRaw(onReplicaChange))
        data._mergeTable = {}
    end

    playerDataTables[player] = data

    onReplicaChange()
end

function playerData.getData(player, wait)
    while wait and not (playerDataTables[player] and playerDataTables[player].value) do
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