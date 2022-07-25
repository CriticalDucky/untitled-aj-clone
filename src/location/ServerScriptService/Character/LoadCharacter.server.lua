local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local entranceDataFolder = ServerStorage:WaitForChild("EntranceData")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")

local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local LocationTypeEnum = require(enumsFolder:WaitForChild("LocationType"))
local Locations = require(serverManagement:WaitForChild("Locations"))
local Entrances = require(entranceDataFolder:WaitForChild("Entrances"))

local function playerAdded(player: Player)
    local joinData = player:GetJoinData()
    local locationFrom = joinData and joinData.TeleportData and joinData.TeleportData.locationFrom

    local entranceSpawn do
        if locationFrom then
            local entranceGroup = Entrances.groups[locationFrom]
            entranceSpawn = if entranceGroup then entranceGroup.entrance else Entrances.main
        else
            entranceSpawn = Entrances.main
        end
    end

    player.RespawnLocation = entranceSpawn
    player:LoadCharacter()
end

if LocalServerInfo.serverType ~= ServerTypeEnum.routing then
    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)
end