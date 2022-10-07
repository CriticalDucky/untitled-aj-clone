local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local serverStorageShared = ServerStorage.Shared
local entranceDataFolder = ServerStorage.EntranceData
local teleportation = serverStorageShared.Teleportation
local dataFolder = serverStorageShared.Data

local Entrances = require(entranceDataFolder.Entrances)
local Teleport = require(teleportation.Teleport)
local PlayerData = require(dataFolder.PlayerData)
local Route = require(teleportation.Route)

local playersTouched = {}

for enum, entranceComponents in pairs(Entrances.groups) do
    entranceComponents.exit.Touched:Connect(function(touchedPart)
        if touchedPart and touchedPart.Parent and touchedPart.Parent:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(touchedPart.Parent)

            if player and not playersTouched[player] then
                playersTouched[player] = true

                PlayerData.yieldUntilHopReady(player)

                if not (Teleport.teleportToLocation({player}, enum) or Teleport.rejoin({player})) then
                    player:Kick("Failed to teleport. Please rejoin the game.")
                end
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    playersTouched[player] = nil
end)