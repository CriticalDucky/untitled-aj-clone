local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local Players = game:GetService "Players"

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local enumsFolder = replicatedFirstShared.Enums
local serverFolder = replicatedStorageShared.Server
local configurationFolder = replicatedFirstShared.Configuration

local LiveServerData = require(serverFolder.LiveServerData)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)

local serverIdentifier = LocalServerInfo.getServerIdentifier()

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

        --Optional custom server info

        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isMinigame) then
        end

        serverInfo.players = getUserIds()

        if not serverIdentifier then
            return
        end

        LiveServerData.publish(serverIdentifier, serverInfo)
    end
end)

game:BindToClose(function()
    runServiceConnection:Disconnect() -- Disconnect heartbeat connection so that no other publish requests are made after this

    task.delay(1, function()
        LiveServerData.publish(serverIdentifier, nil)
    end)
end)
