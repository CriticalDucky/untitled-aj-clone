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
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(dataFolder.ReplicaService)
local Teleport = require(teleportationFolder.Teleport)
local PlayerData = require(dataFolder.PlayerData)
local Table = require(utilityFolder.Table)
local TeleportRequestType = require(enumsFolder.TeleportRequestType)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local LiveServerData = require(serverFolder.LiveServerData)
local PlayerLocation = require(serverStorageSharedUtility.PlayerLocation)
local Locations = require(serverFolder.Locations)
local ActiveParties = require(serverFolder.ActiveParties)
local LocalWorldOrigin = require(serverFolder.LocalWorldOrigin)
local ServerData = require(serverManagementFolder.ServerData)
local PlayerSettings = require(dataFolder.Settings.PlayerSettings)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local HomeManager = require(dataFolder.Inventory.HomeManager)
local HomeLockType = require(enumsFolder.HomeLockType)

local TeleportRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("TeleportRequest"),
    Replication = "All"
})

local function getWorldIndexOrigin(player)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        local LocalWorldInfo = require(ReplicatedStorage.Location.Server.LocalWorldInfo)

        return LocalWorldInfo.worldIndex, LocalWorldInfo.locationEnum
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
        return LocalWorldOrigin(player) or ServerData.findAvailableWorld()
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        return ServerData.findAvailableWorld()
    end
end

TeleportRequest:ConnectOnServerEvent(function(player: Player, requestCode, teleportRequestType, ...)
    local function requestIsValid()
        if not PlayerData.get(player) then
            print("Invalid request: PlayerData not found")

            return
        end

        if not teleportRequestType then
            print("Invalid request: teleportRequestType is nil")

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
        
            local success = Teleport.rejoin(player, "There was an error teleporting you. Please try again. (TR1)")
    
            if not success then
                warn("Failed to rejoin player")
    
                player:Kick("There has been an error. Please rejoin. (err code TR1K)")
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

        if LiveServerData.isWorldFull(worldIndex) then
            print("Invalid request: world is full")

            return respond(TeleportResponseType.full)
        end

        local success = Teleport.toWorld(player, worldIndex)

        if not success then
            return respond(TeleportResponseType.teleportError)
        else
            return respond(TeleportResponseType.success)
        end
    elseif teleportRequestType == TeleportRequestType.toLocation then
        local locationEnum = ...

        if not locationEnum then
            print("Invalid request: locationEnum is nil")

            return respond(TeleportResponseType.invalid)
        end

        local function validateLocationEnum(worldIndex)
            local worlds = ServerData.getWorlds()

            if not worlds[worldIndex].locations[locationEnum] then
                print("Invalid request: locationEnum is not a valid location for worldIndex")

                return false
            end

            return true
        end

        local isLocationFull do
            local worldIndex

            if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                worldIndex = require(ReplicatedStorage.Location.Server.LocalWorldInfo).worldIndex
            elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
                worldIndex = LocalWorldOrigin(player) or ServerData.findAvailableWorld(locationEnum)
            end

            if not worldIndex then
                return respond(TeleportResponseType.teleportError)
            end

            if not validateLocationEnum(worldIndex) then
                return respond(TeleportResponseType.invalid)
            end

            isLocationFull = LiveServerData.isLocationFull(worldIndex, locationEnum)
        end

        local worldIndex

        if isLocationFull then
            local findOpenWorld = PlayerSettings.getSetting(player, "findOpenWorld")

            if not findOpenWorld then
                return respond(TeleportResponseType.full)
            end

            worldIndex = ServerData.findAvailableWorld(locationEnum)

            if not worldIndex then
                return respond(TeleportResponseType.teleportError)
            end

            if not validateLocationEnum(worldIndex) then
                return respond(TeleportResponseType.invalid)
            end
        end

        local success = Teleport.toLocation(player, locationEnum, worldIndex)

        if not success then
            return respond(TeleportResponseType.teleportError)
        else
            return respond(TeleportResponseType.success)
        end
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
            local isLocationFull = LiveServerData.isLocationFull(targetPlayerLocation.worldIndex, targetPlayerLocation.locationEnum)

            if isLocationFull then
                return respond(TeleportResponseType.full)
            end
    
            local locationInfo = Locations.info[targetPlayerLocation.locationEnum]
    
            if locationInfo.cantJoinPlayer then
                return respond(TeleportResponseType.invalid)
            end

            local success = Teleport.toPlayer(player, targetPlayerId)

            if not success then
                return respond(TeleportResponseType.teleportError)
            else
                return respond(TeleportResponseType.success)
            end
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, targetPlayerLocation.serverType) then
            local partyType = targetPlayerLocation.partyType
            local partyIndex = targetPlayerLocation.partyIndex

            local isPartyFull = LiveServerData.isPartyFull(partyType, partyIndex)

            if isPartyFull then
                return respond(TeleportResponseType.full)
            end

            local success = Teleport.toPlayer(player, targetPlayerId)

            if not success then
                return respond(TeleportResponseType.teleportError)
            else
                return respond(TeleportResponseType.success)
            end
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

        local success = Teleport.toParty(player, partyType)

        if not success then
            return respond(TeleportResponseType.teleportError)
        else
            return respond(TeleportResponseType.success)
        end
    elseif teleportRequestType == TeleportRequestType.toHome then
        local homeOwnerUserId = ...

        if not homeOwnerUserId then
            print("Invalid request: homeOwnerUserId is nil")

            return respond(TeleportResponseType.invalid)
        end

        if player.UserId ~= homeOwnerUserId then
            if LiveServerData.isHomeFull(homeOwnerUserId) then
                warn("Teleport.teleportToHome: home is full")
                return respond(TeleportResponseType.full)
            end
    
            local homeLockType = HomeManager.getLockStatus(homeOwnerUserId)
    
            if homeLockType == HomeLockType.locked then
                warn("Teleport.teleportToHome: home is private")
                return respond(TeleportResponseType.invalid)
            end
    
            local success, isFriendsWith = pcall(function()
                return player:IsFriendsWith(homeOwnerUserId)
            end)
    
            if not success then
                warn("Teleport.teleportToHome: failed to check friendship")
                return respond(TeleportResponseType.teleportError)
            end
    
            if homeLockType == HomeLockType.friendsOnly and not isFriendsWith then
                warn("Teleport.teleportToHome: home is friends only")
                return respond(TeleportResponseType.invalid)
            end
        end

        local success = Teleport.toHome(player, homeOwnerUserId)

        if not success then
            return respond(TeleportResponseType.teleportError)
        else
            return respond(TeleportResponseType.success)
        end
    else
        warn("Invalid request: teleportRequestType is nil or invalid")

        return respond(TeleportResponseType.invalid)
    end
end)

