local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverStorageShared = ServerStorage.Shared
local utilityFolder = replicatedFirstShared.Utility
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local LiveServerData = require(serverFolder.LiveServerData)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local Promise = require(utilityFolder.Promise)

Promise.resolve()
    :andThen(function()
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
            return {
                jobId = game.JobId,
            }
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
            return LocalServerInfo.getServerIdentifier()
                :andThen(function(serverInfo)
                    return {
                        worldIndex = serverInfo.worldIndex,
                        locationEnum = serverInfo.locationEnum,
                    }
                end)
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
            return LocalServerInfo.getServerIdentifier()
                :andThen(function(serverInfo)
                    return {
                        homeOwner = serverInfo.homeOwner,
                    }
                end)
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
            return LocalServerInfo.getServerIdentifier()
                :andThen(function(serverInfo)
                    return {
                        partyType = serverInfo.partyType,
                        partyIndex = serverInfo.partyIndex,
                    }
                end)
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame) then
            return LocalServerInfo.getServerIdentifier()
                :andThen(function(serverInfo)
                    return {
                        gameType = serverInfo.gameType,
                        gameIndex = serverInfo.gameIndex,
                    }
                end)
        end
    end)
    :andThen(function(indexInfo)
        local runServiceConnection = RunService.Heartbeat:Connect(function()
            if LiveServerData.canPublish() then
                local serverInfo
        
                local function getUserIds()
                    local userIds = {}
        
                    for _, player in pairs(Players:GetPlayers()) do
                        table.insert(userIds, player.UserId)
                    end
        
                    return userIds
                end
        
                serverInfo = {}
        
                --#region Optional custom server info
        
                if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        
                elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        
                elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        
                elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
        
                elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame) then
        
                end
        
                --#endregion
        
                serverInfo.players = getUserIds()
        
                LiveServerData.publish(serverInfo, indexInfo)
            end
        end)
        
        game:BindToClose(function()
            runServiceConnection:Disconnect() -- Disconnect heartbeat connection so that no other publish requests are made after this

            task.delay(1, function()
                LiveServerData.publish(nil, indexInfo)
            end)
        end)
    end)

