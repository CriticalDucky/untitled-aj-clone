local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedStorageShared:WaitForChild("Fusion"))

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local playerDataTables = {}
local playerData = {}

function playerData.add(player)
    local data = {}

    data._publicReplica = ReplicaCollection.get(player, true)

    if player == Players.LocalPlayer then
        data._privateReplica = ReplicaCollection.get("PlayerDataPrivate_" .. player.UserId, true)
        data._mergeTable = {}
    end

    playerDataTables[player] = data
end

function playerData.getDataValue(player, wait)
    if wait then
        while not playerDataTables[player] and not playerDataTables[player].value do
            task.wait()
        end
    end

    return playerDataTables[player].value
end

RunService.Heartbeat:Connect(function()
    for player, data in pairs(playerDataTables) do
        if not player:IsDescendantOf(Players) then
            return
        end

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
end)

return playerData