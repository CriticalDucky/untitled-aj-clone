local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverFolder = replicatedStorageShared.Server
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local Teleport = require(serverStorageShared.Teleportation.Teleport)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
    local PlayerDataManager = require(dataFolder.PlayerDataManager)

    local function playerAdded(player)
        PlayerDataManager.init(player)
            :catch(function(err)
                warn("Error initializing player data: " .. tostring(err))
                Teleport.rejoin(player, "An internal server error occurred. (err code PDF)")
            end)
    end

    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)
end