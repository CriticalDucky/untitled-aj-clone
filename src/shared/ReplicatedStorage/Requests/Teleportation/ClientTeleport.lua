local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local ClientWorldDataHelper = require(serverFolder:WaitForChild("ClientWorldDataHelper"))
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))
local Table = require(utilityFolder:WaitForChild("Table"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local TeleportRequestType = require(enumsFolder:WaitForChild("TeleportRequestType"))
local TeleportResponseType = require(enumsFolder:WaitForChild("TeleportResponseType"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local FriendLocations = require(serverFolder:WaitForChild("FriendLocations"))

local TeleportRequest = ReplicaCollection.get("TeleportRequest")

local Teleport = {}

function Teleport.request(teleportRequestType, ...)
    assert(Table.hasValue(TeleportRequestType, teleportRequestType), "Teleport.request() serverType must be a valid ServerTypeEnum value")

    return ReplicaRequest.new(TeleportRequest, teleportRequestType, ...)
end

function Teleport.toWorld(worldIndex)
    local currentWorldData = ClientWorldData:get()

    if not currentWorldData then
        return TeleportResponseType.teleportError
    end

    local worldData = currentWorldData[worldIndex]

    if ClientWorldDataHelper.isWorldFull(worldData) then
        return TeleportResponseType.full
    end

    return Teleport.request(TeleportRequestType.toWorld, worldIndex)
end

function Teleport.toLocation(locationEnum)
    if LocalServerInfo.serverType == ServerTypeEnum.location then
        local replicatedStorageLocation = ReplicatedStorage:WaitForChild("Location")
        local serverFolderLocation = replicatedStorageLocation:WaitForChild("Server")

        local ClientWorldInfo = require(serverFolderLocation:WaitForChild("ClientWorldInfo")):get()
        
        local currentWorldData = ClientWorldData:get()
        local localWorldIndex = ClientWorldInfo.worldIndex

        if locationEnum == ClientWorldInfo.locationEnum then
            return TeleportResponseType.alreadyInLocation
        end

        local worldData = currentWorldData[localWorldIndex]
        local locationData = worldData[locationEnum]

        if ClientWorldDataHelper.isLocationFull(locationData) then
            return TeleportResponseType.full
        end

        return Teleport.request(TeleportRequestType.toLocation, locationEnum)
    end
end

function Teleport.toFriend(playerId)
    local friendLocations = FriendLocations:get()
    local friendLocation = friendLocations[playerId]

    if friendLocation then
        local serverType = friendLocation.serverType

        if serverType == ServerTypeEnum.location then
            local currentWorldData = ClientWorldData:get()
            local locationData = currentWorldData[friendLocation.worldIndex][friendLocation.locationEnum]

            if ClientWorldDataHelper.isLocationFull(locationData) then
                return TeleportResponseType.full
            end

            if Locations.info[friendLocation.locationEnum].cantJoinPlayer then
                return TeleportResponseType.invalid
            end

            return Teleport.request(TeleportRequestType.toFriend, playerId)
        else
            return TeleportResponseType.invalid
        end
    else
        return TeleportResponseType.invalid
    end
end

return Teleport