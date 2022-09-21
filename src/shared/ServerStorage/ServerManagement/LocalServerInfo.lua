local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local ServerTypeEnum = require(enumsFolder.ServerType)
local Locations = require(replicatedStorageShared.Server.Locations)
local Homes = require(replicatedStorageShared.Data.Inventory.Items.Homes)
local ReplicaService = require(dataFolder.ReplicaService)

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

ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ServerInfo"),
    Data = localServerInfo,
    Replication = "All",
})

return localServerInfo