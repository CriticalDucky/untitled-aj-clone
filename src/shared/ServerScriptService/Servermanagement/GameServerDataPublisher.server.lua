local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverManagementShared = serverStorageShared.ServerManagement

local GameServerData = require(serverManagementShared.GameServerData)
local LocalServerInfo = require(serverManagementShared.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)

local indexInfo do
    if LocalServerInfo.serverType == ServerTypeEnum.routing then
        indexInfo = {
            jobId = game.JobId,
        }
    elseif LocalServerInfo.serverType == ServerTypeEnum.location then
        local LocalWorldInfo = require(ServerStorage.Location.ServerManagement.LocalWorldInfo)

        indexInfo = {
            worldIndex = LocalWorldInfo.worldIndex,
            locationEnum = LocalWorldInfo.locationEnum,
        }
    elseif LocalServerInfo.serverType == ServerTypeEnum.home then
        indexInfo = {
            userId = LocalServerInfo.userId,
        }
    end
end

local runServiceConnection = RunService.Heartbeat:Connect(function(deltaTime)
    if GameServerData.canPublish() then
        local serverInfo

        local function getUserIds()
            local userIds = {}

            for _, player in pairs(Players:GetPlayers()) do
                table.insert(userIds, player.UserId)
            end

            return userIds
        end

        if LocalServerInfo.serverType == ServerTypeEnum.routing then
            serverInfo = {
                players = getUserIds(),
            }
        elseif LocalServerInfo.serverType == ServerTypeEnum.location then
            serverInfo = {
                players = getUserIds(),
            }
        elseif LocalServerInfo.serverType == ServerTypeEnum.home then
            serverInfo = {
                players = getUserIds(),
            }
        end

        GameServerData.publish(serverInfo, indexInfo)
    end
end)

game:BindToClose(function()
    runServiceConnection:Disconnect() -- Disconnect heartbeat connection so that no other publish requests are made after this

    GameServerData.publish(nil, indexInfo)
end)

