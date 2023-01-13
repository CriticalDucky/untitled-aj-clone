local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local Parties = require(serverFolder:WaitForChild("Parties"))
local Games = require(serverFolder:WaitForChild("Games"))
local GameSettings = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild("GameSettings"))
local Promise = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Promise"))

local ClientServerData = require(serverFolder:WaitForChild("ClientServerData"))

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

local serverType do
    for _, locationInfo in pairs(Locations.info) do
        if locationInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.location
        end
    end

    for _, partyInfo in pairs(Parties) do
        if partyInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.party
        end
    end

    for _, gameInfo in pairs(Games) do
        if gameInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.game
        end
    end

    if GameSettings.homePlaceId == game.PlaceId then
        serverType = ServerTypeEnum.home
    end

    if not serverType then
        serverType = ServerTypeEnum.routing
    end
end

local LocalServerInfo = {}

LocalServerInfo.serverType = serverType

function LocalServerInfo.getServerInfo()
    if isServer then
        local ServerStorage = game:GetService("ServerStorage")

        local serverStorageShared = ServerStorage.Shared

        local ServerData = require(serverStorageShared.ServerManagement.ServerData)

        return ServerData.traceServerInfo()
    elseif isClient then
        return ClientServerData.getServerInfo()
    end
end

return LocalServerInfo