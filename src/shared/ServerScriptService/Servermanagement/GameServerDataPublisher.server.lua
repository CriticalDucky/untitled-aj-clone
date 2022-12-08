local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local LiveServerData = require(serverFolder.LiveServerData)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)

local indexInfo do
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        indexInfo = {
            jobId = game.JobId,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        local LocalWorldInfo = require(ReplicatedStorage.Location.Server.LocalWorldInfo)

        indexInfo = {
            worldIndex = LocalWorldInfo.worldIndex,
            locationEnum = LocalWorldInfo.locationEnum,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        local LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)

        indexInfo = {
            userId = LocalHomeInfo.homeOwner,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
        local LocalPartyInfo = require(ReplicatedStorage.Party.Server.LocalPartyInfo)

        indexInfo = {
            partyType = LocalPartyInfo.partyType,
            partyIndex = LocalPartyInfo.partyIndex,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame) then
        local LocalGameInfo = require(ReplicatedStorage.Game.Server.LocalGameInfo)

        indexInfo = {
            gameType = LocalGameInfo.gameType,
            gameIndex = LocalGameInfo.gameIndex,
            privateServerId = game.PrivateServerId,
        }
    end
end

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

    LiveServerData.publish(nil, indexInfo)
end)

