local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local dataFolder = replicatedStorageShared:WaitForChild("Data")

local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)

if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
    return
end

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local ClientPartyData = require(serverFolder:WaitForChild("ClientPartyData"))
local ClientHomeData = require(serverFolder:WaitForChild("ClientHomeData"))
local LocalPlayerSettings = require(dataFolder:WaitForChild("Settings"):WaitForChild("LocalPlayerSettings"))
local Table = require(utilityFolder:WaitForChild("Table"))
local TeleportRequestType = require(enumsFolder:WaitForChild("TeleportRequestType"))
local TeleportResponseType = require(enumsFolder:WaitForChild("TeleportResponseType"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local FriendLocations = require(serverFolder:WaitForChild("FriendLocations"))
local LocalWorldOrigin = require(serverFolder:WaitForChild("LocalWorldOrigin"))
local ActiveParties = require(serverFolder:WaitForChild("ActiveParties"))
local PrintEnum = require(utilityFolder:WaitForChild("PrintEnum"))

local player = Players.LocalPlayer

local TeleportRequest = ReplicaCollection.get("TeleportRequest")

local Teleport = {}

function Teleport.request(teleportRequestType, ...)
    assert(Table.hasValue(TeleportRequestType, teleportRequestType), "Teleport.request() called with invalid teleportRequestType: " .. tostring(teleportRequestType))

    local response = ReplicaRequest.new(TeleportRequest, teleportRequestType, ...)

    return response
end

function Teleport.toWorld(worldIndex)
    local currentWorldData = ClientWorldData:get()

    if not currentWorldData then
        return TeleportResponseType.teleportError
    end

    if ClientWorldData.isWorldFull(worldIndex) then
        return TeleportResponseType.full
    end

    return Teleport.request(TeleportRequestType.toWorld, worldIndex)
end

function Teleport.toLocation(locationEnum)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
        local localWorldIndex do
            if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                local replicatedStorageLocation = ReplicatedStorage:WaitForChild("Location")
                local serverFolderLocation = replicatedStorageLocation:WaitForChild("Server")
    
                local ClientWorldInfo = require(serverFolderLocation:WaitForChild("ClientWorldInfo")):get()
                
                if locationEnum == ClientWorldInfo.locationEnum then
                    return TeleportResponseType.alreadyInPlace
                end

                localWorldIndex = ClientWorldInfo.worldIndex
            elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
                localWorldIndex = LocalWorldOrigin
            end
        end

        if localWorldIndex and ClientWorldData.isLocationFull(localWorldIndex, locationEnum) and not LocalPlayerSettings.getSetting("findOpenWorld") then
            print("Teleport.toLocation(): location is full")
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

        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
            if ClientWorldData.isLocationFull(friendLocation.worldIndex, friendLocation.locationEnum) then
                return TeleportResponseType.full
            end

            if Locations.info[friendLocation.locationEnum].cantJoinPlayer then
                return TeleportResponseType.invalid
            end

            return Teleport.request(TeleportRequestType.toFriend, playerId)
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
            if ClientPartyData.isPartyFull(friendLocation.partyType, friendLocation.privateServerId) then
                return TeleportResponseType.full
            end

            return Teleport.request(TeleportRequestType.toFriend, playerId)
        else
            return TeleportResponseType.invalid
        end
    else
        return TeleportResponseType.invalid
    end
end

function Teleport.toParty(partyType)
    local activeParty = ActiveParties.getActiveParty()

    if activeParty then
        if activeParty.partyType ~= partyType then
            return TeleportResponseType.disabled
        end

        return Teleport.request(TeleportRequestType.toParty, partyType)
    else
        return TeleportResponseType.invalid
    end
end

function Teleport.toHome(homeOwnerUserId)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        local LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)

        if LocalHomeInfo.homeOwner == homeOwnerUserId then
            return TeleportResponseType.alreadyInPlace
        end
    end

    if homeOwnerUserId == player.UserId then
        return Teleport.request(TeleportRequestType.toHome, homeOwnerUserId)
    end
end

return Teleport