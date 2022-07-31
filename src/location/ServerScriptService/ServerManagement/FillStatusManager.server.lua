local FULL = 20
local RECOMMENDED_PLAYERS = 15

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverStorageLocation = ServerStorage:WaitForChild("Location")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local serverManagementShared = serverStorageShared:WaitForChild("ServerManagement")
local serverManagementLocation = serverStorageLocation:WaitForChild("ServerManagement")
local Teleportation = serverStorageShared:WaitForChild("Teleportation")

local WorldData = require(serverManagementShared:WaitForChild("WorldData"))
local WorldFillData = require(serverManagementShared:WaitForChild("WorldFillData"))
local Teleport = require(Teleportation:WaitForChild("Teleport"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))
local LocalWorldInfo = require(serverManagementLocation:WaitForChild("LocalWorldInfo"))

local fillStatus = FillStatusEnum.notFilled

local function onPlayerCountChanged()
    local currentPlayers = Players:GetPlayers()
    local playerCount = #currentPlayers

    if playerCount < RECOMMENDED_PLAYERS then
        fillStatus = FillStatusEnum.notFilled
    elseif playerCount < FULL then
        fillStatus = FillStatusEnum.pastRecommended
    else
        fillStatus = FillStatusEnum.full
    end
end

local function playerAdded(player)
    onPlayerCountChanged()
end

for _, player in Players:GetPlayers() do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.ChildRemoved:Connect(onPlayerCountChanged)

RunService.Heartbeat:Connect(function(deltaTime)
    WorldFillData.publish(fillStatus)
end)
