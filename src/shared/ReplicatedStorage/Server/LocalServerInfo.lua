local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local ServerTypeEnum = require(enumsFolder.ServerType)
local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)


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

    if GameSettings.homePlaceId == game.PlaceId then
        serverType = ServerTypeEnum.home
    end

    if not serverType then
        serverType = ServerTypeEnum.routing
    end
end

local localServerInfo = {}

localServerInfo.serverType = serverType

return localServerInfo