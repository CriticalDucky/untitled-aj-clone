local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums

local ServerTypeEnum = require(enumsFolder.ServerType)
local Locations = require(replicatedStorageShared.Server.Locations)
local Parties = require(replicatedStorageShared.Server.Parties)

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

    if not serverType then
        serverType = ServerTypeEnum.routing
    end
end

local localServerInfo = {}

localServerInfo.serverType = serverType

return localServerInfo