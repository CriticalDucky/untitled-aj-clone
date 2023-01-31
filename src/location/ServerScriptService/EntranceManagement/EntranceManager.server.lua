local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local serverStorageShared = ServerStorage.Shared
local entranceDataFolder = ServerStorage.EntranceData
local teleportation = serverStorageShared.Teleportation

local Entrances = require(entranceDataFolder.Entrances)
local Teleport = require(teleportation.Teleport)

local playersTouched = {}

for enum, entranceComponents in pairs(Entrances.groups) do
    entranceComponents.exit.Touched:Connect(function(touchedPart)
        local player = Players:GetPlayerFromCharacter(touchedPart.Parent)

        if player and not playersTouched[player] then
            playersTouched[player] = true

            Teleport.toLocation(player, enum, nil, function()
                playersTouched[player] = nil
            end):catch(function(err)
                warn(err)
                playersTouched[player] = nil
            end)
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    playersTouched[player] = nil
end)