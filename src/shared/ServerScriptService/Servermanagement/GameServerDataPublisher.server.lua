local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverManagementShared = serverStorageShared.ServerManagement
local serverFolder = replicatedStorageShared.Server

local GameServerData = require(serverManagementShared.GameServerData)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local Teleport = require(serverStorageShared.Teleportation.Teleport)
local Fingerprint = require(serverStorageShared.Utility.Fingerprint)

local indexInfo do
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        indexInfo = {
            jobId = game.JobId,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        local LocalWorldInfo = require(ServerStorage.Location.ServerManagement.LocalWorldInfo)

        indexInfo = {
            worldIndex = LocalWorldInfo.worldIndex,
            locationEnum = LocalWorldInfo.locationEnum,
        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        indexInfo = {

        }
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
        local LocalPartyInfo = require(ReplicatedStorage.Party.Server.LocalPartyInfo)

        indexInfo = {
            partyType = LocalPartyInfo.partyType,
            privateServerId = game.PrivateServerId
        }
    end
end

local party_serverCode

if ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
    party_serverCode = Fingerprint.trace(game.PrivateServerId)

    if not party_serverCode then
        Teleport.rejoin(Players:GetPlayers())

        Players.PlayerAdded:Connect(function(player)
            Teleport.rejoin(player) -- Shut down the server.
        end)
    end -- Boot players if the server code is not found
end

local runServiceConnection = RunService.Heartbeat:Connect(function()
    if GameServerData.canPublish() then
        local serverInfo

        local function getUserIds()
            local userIds = {}

            for _, player in pairs(Players:GetPlayers()) do
                table.insert(userIds, player.UserId)
            end

            return userIds
        end

        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
            serverInfo = {
                
            }
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
            serverInfo = {
                
            }
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
            serverInfo = {
                
            }
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
            serverInfo = {
                serverCode = party_serverCode,
            }
        end

        serverInfo.players = getUserIds()

        GameServerData.publish(serverInfo, indexInfo)
    end
end)

game:BindToClose(function()
    runServiceConnection:Disconnect() -- Disconnect heartbeat connection so that no other publish requests are made after this

    GameServerData.publish(nil, indexInfo)
end)

