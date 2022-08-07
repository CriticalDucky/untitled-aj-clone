local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local entranceDataFolder = ServerStorage:WaitForChild("EntranceData")
local teleportation = serverStorageShared:WaitForChild("Teleportation")
local dataFolder = serverStorageShared:WaitForChild("Data")

local Entrances = require(entranceDataFolder:WaitForChild("Entrances"))
local Teleport = require(teleportation:WaitForChild("Teleport"))
local PlayerData = require(dataFolder:WaitForChild("PlayerData"))

local playersTouched = {}

for enum, entranceComponents in pairs(Entrances.groups) do
    entranceComponents.exit.Touched:Connect(function(touchedPart)
        if touchedPart and touchedPart.Parent and touchedPart.Parent:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(touchedPart.Parent)

            if player and not playersTouched[player] then
                playersTouched[player] = true

                PlayerData.yieldUntilHopReady(player)

                Teleport.teleportToLocation({player}, enum)
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    playersTouched[player] = nil
end)