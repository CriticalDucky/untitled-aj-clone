local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local enumsFolder = replicatedStorageShared.Enums

local ServerTypeEnum = require(enumsFolder.ServerType)
local Locations = require(serverManagement.Locations)
local Homes = require(replicatedStorageShared.Data.Inventory.Items.Homes)

local serverType do
    for _, locationInfo in pairs(Locations.info) do
        if locationInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.location
        end
    end

    for _, homeInfo in pairs(Homes) do
        if homeInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.home
        end
    end

    if not serverType then
        serverType = ServerTypeEnum.routing
    end
end

local localServerInfo = {}

localServerInfo.serverType = serverType

return localServerInfo