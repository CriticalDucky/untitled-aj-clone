local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local dataFolder = serverStorageShared:WaitForChild("Data")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

if LocalServerInfo.serverType ~= ServerTypeEnum.routing then
    local init = require(dataFolder:WaitForChild("PlayerData")).init

    for _, player in pairs(Players:GetPlayers()) do
        init(player)
    end

    Players.PlayerAdded:Connect(init)
end