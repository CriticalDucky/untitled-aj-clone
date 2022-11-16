local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = ReplicatedFirst.Shared.Utility

local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local WaitForDescendant = require(utilityFolder.WaitForDescendant)

local function playerAdded(player: Player)
    local spawnpoint do
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
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
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
            spawnpoint = WaitForDescendant(workspace, function(descendant)
                local name = descendant.Name

                return string.find(name, "Spawn")
            end)
        end
    end

    player.RespawnLocation = spawnpoint
    player:LoadCharacter()
end

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)
end