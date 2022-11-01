local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverFolder = replicatedStorageShared.Server
local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local teleportationFolder = serverStorageShared.Teleportation
local utilityFolder = replicatedFirstShared.Utility
local enumsFolder = replicatedStorageShared.Enums
local serverManagementFolder = serverStorageShared.ServerManagement

local ReplicaService = require(dataFolder.ReplicaService)
local Teleport = require(teleportationFolder.Teleport)
local PlayerData = require(dataFolder.PlayerData)
local Table = require(utilityFolder.Table)
local TeleportRequestType = require(enumsFolder.TeleportRequestType)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local GameServerData = require(serverManagementFolder.GameServerData)
local PlayerLocation = require(serverManagementFolder.PlayerLocation)
local Locations = require(serverFolder.Locations)
local ActiveParties = require(serverFolder.ActiveParties)
local LocalWorldOrigin = require(serverFolder.LocalWorldOrigin)
local WorldData = require(serverManagementFolder.WorldData)
local PlayerSettings = require(dataFolder.Settings.PlayerSettings)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)

local TeleportRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("TeleportRequest"),
    Replication = "All"
})

TeleportRequest:ConnectOnServerEvent(function(player: Player, requestCode, teleportRequestType, ...)
    local function requestIsValid()
        if not PlayerData.get(player) then
            print("Invalid request: PlayerData not found")

            return
        end

        if not player or not teleportRequestType then
            print("Invalid request: player or teleportRequestType is nil")

            return
        end

        if not Table.hasValue(TeleportRequestType, teleportRequestType) then
            print("Invalid request: teleportRequestType is not a valid TeleportRequestType value")

            return
        end

        return true
    end

    local function respond(...)
        TeleportRequest:FireClient(player, requestCode, ...)
    end

    local function onTeleportError()
        task.spawn(function()
            respond(TeleportResponseType.teleportError)
        
            local success = Teleport.rejoin(player)
    
            if not success then
                warn("Failed to rejoin player")
    
                player:Kick("There has been an error. Please rejoin.")
            end
        end)
    end

    local function evaluateSuccess(success)
        if not success then
            onTeleportError()
        else
            respond(TeleportResponseType.success)
        end
    end

    if not requestIsValid() then
        return respond(TeleportResponseType.invalid)
    end

    if teleportRequestType == TeleportRequestType.toWorld then
        local worldIndex = ...

        if not worldIndex then
            print("Invalid request: worldIndex is nil")

            return respond(TeleportResponseType.invalid)
        end

        local populationInfo = GameServerData.getWorldPopulationInfo(worldIndex)

        if populationInfo and populationInfo.max_emptySlots == 0 then
            return respond(TeleportResponseType.full)
        end

        PlayerData.yieldUntilHopReady(player)

        local success = Teleport.teleportToWorld(player, worldIndex)

        evaluateSuccess(success)
    elseif teleportRequestType == TeleportRequestType.toLocation then
        local locationEnum = ...

        if not locationEnum then
            print("Invalid request: locationEnum is nil")

            return respond(TeleportResponseType.invalid)
        end

        local populationInfo do
            local worldIndex

            if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                worldIndex = require(ServerStorage.Location.ServerManagement.LocalWorldInfo).worldIndex
            elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
                worldIndex = LocalWorldOrigin(player) or WorldData.findAvailableWorld(locationEnum)
            end

            if not worldIndex then
                return respond(TeleportResponseType.teleportError)
            end

            populationInfo = GameServerData.getLocationPopulationInfo(worldIndex, locationEnum)
        end

        local worldIndex

        if populationInfo and populationInfo.max_emptySlots == 0 then
            local findOpenWorld = PlayerSettings.getSetting(player, "findOpenWorld")

            if not findOpenWorld then
                return respond(TeleportResponseType.full)
            end

            worldIndex = WorldData.findAvailableWorld(locationEnum)

            if not worldIndex then
                return respond(TeleportResponseType.teleportError)
            end
        end

        PlayerData.yieldUntilHopReady(player)

        local success = Teleport.teleportToLocation(player, locationEnum, worldIndex)

        evaluateSuccess(success)
    elseif teleportRequestType == TeleportRequestType.toFriend then
        local targetPlayerId = ...

        if not targetPlayerId then
            print("Invalid request: targetPlayer is nil")

            return respond(TeleportResponseType.invalid)
        end

        local isFriendsWithTarget = true do
            local success, result = pcall(function()
                return player:IsFriendsWith(targetPlayerId)
            end)

            if success then
                isFriendsWithTarget = result
            end
        end

        if not isFriendsWithTarget then
            return respond(TeleportResponseType.invalid)
        end

        local targetPlayerLocation = PlayerLocation.get(targetPlayerId)

        if not targetPlayerLocation then
            return respond(TeleportResponseType.invalid)
        end

        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, targetPlayerLocation.serverType) then
            local populationInfo = GameServerData.getLocationPopulationInfo(targetPlayerLocation.worldIndex, targetPlayerLocation.locationEnum)
            
            if not populationInfo then
                print("Error: populationInfo not found")

                return respond(TeleportResponseType.teleportError)
            end
    
            if populationInfo.max_emptySlots == 0 then
                return respond(TeleportResponseType.full)
            end
    
            local locationInfo = Locations.info[targetPlayerLocation.locationEnum]
    
            if locationInfo.cantJoinPlayer then
                return respond(TeleportResponseType.invalid)
            end

            PlayerData.yieldUntilHopReady(player)

            evaluateSuccess(Teleport.teleportToPlayer(player, targetPlayerId))
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, targetPlayerLocation.serverType) then
            local partyType = targetPlayerLocation.partyType
            local privateServerId = targetPlayerLocation.privateServerId

            local populationInfo = GameServerData.getPartyPopulationInfo(partyType, privateServerId)

            if not populationInfo then
                print("Error: populationInfo not found")

                return respond(TeleportResponseType.teleportError)
            end

            if populationInfo.max_emptySlots == 0 then
                return respond(TeleportResponseType.full)
            end

            PlayerData.yieldUntilHopReady(player)

            evaluateSuccess(Teleport.teleportToPlayer(player, targetPlayerId))
        else
            return respond(TeleportResponseType.invalid)
        end
    elseif teleportRequestType == TeleportRequestType.toParty then
        local partyType = ...

        if not partyType then
            print("Invalid request: partyType is nil")

            return respond(TeleportResponseType.invalid)
        end

        if partyType ~= ActiveParties.getActiveParty().partyType then
            return respond(TeleportResponseType.disabled)
        end

        PlayerData.yieldUntilHopReady(player)

        evaluateSuccess(Teleport.teleportToParty(player, partyType))
    end
end)

