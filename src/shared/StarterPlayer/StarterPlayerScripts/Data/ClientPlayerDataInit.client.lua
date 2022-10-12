local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))

if LocalServerInfo.serverType ~= ServerTypeEnum.routing then
    local function playerAdded(player)
        ClientPlayerData.add(player)
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end
    
    Players.PlayerAdded:Connect(playerAdded)
end