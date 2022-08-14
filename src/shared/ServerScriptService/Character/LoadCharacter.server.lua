local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverManagement = serverStorageShared.ServerManagement

local LocalServerInfo = require(serverManagement.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)

local function playerAdded(player: Player)
    local spawnpoint do
        local serverType = LocalServerInfo.serverType

        if serverType == ServerTypeEnum.location then
            local entranceDataFolder = ServerStorage.EntranceData
            local Entrances = require(entranceDataFolder.Entrances)

            local joinData = player:GetJoinData()
            local locationFrom = joinData and joinData.TeleportData and joinData.TeleportData.locationFrom
    
            if locationFrom then
                local entranceGroup = Entrances.groups[locationFrom]
                spawnpoint = if entranceGroup then entranceGroup.entrance else Entrances.main
            else
                spawnpoint = Entrances.main
            end
        elseif serverType == ServerTypeEnum.home then
            spawnpoint = workspace:FindFirstChild("SpawnLocation", true)
        end
    end

    player.RespawnLocation = spawnpoint
    player:LoadCharacter()
end

if LocalServerInfo.serverType ~= ServerTypeEnum.routing then
    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)
end