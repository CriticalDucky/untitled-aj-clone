local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local entranceDataFolder = ServerStorage:WaitForChild("EntranceData")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local teleportation = serverStorageShared:WaitForChild("Teleportation")

local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local LocationTypeEnum = require(enumsFolder:WaitForChild("LocationType"))
local Locations = require(serverManagement:WaitForChild("Locations"))
local Entrances = require(entranceDataFolder:WaitForChild("Entrances"))
local Teleport = require(teleportation:WaitForChild("Teleport"))

local playersTouched = {}

for enum, entranceComponents in pairs(Entrances.groups) do
    entranceComponents.exit.Touched:Connect(function(touchedPart)
        if touchedPart and touchedPart.Parent and touchedPart.Parent:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(touchedPart.Parent)

            if player and not playersTouched[player] then
                playersTouched[player] = true

                Teleport.teleportToLocation({player}, enum)
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    playersTouched[player] = nil
end)