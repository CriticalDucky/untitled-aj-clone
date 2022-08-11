local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")

PlayerLocationData = require(serverManagement:WaitForChild("PlayerLocationData"))

local function playerAdded(player)
    PlayerLocationData.set(player.UserId)
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)