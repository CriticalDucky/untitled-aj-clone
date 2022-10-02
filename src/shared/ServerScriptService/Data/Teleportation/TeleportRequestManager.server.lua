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
local ServerTypeEnum = require(enumsFolder.ServerType)
local TeleportRequestType = require(enumsFolder.TeleportRequestType)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local GameServerData = require(serverManagementFolder.GameServerData)
local PlayerLocation = require(serverManagementFolder.PlayerLocation)
local Locations = require(serverFolder.Locations)

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

        if not populationInfo then
            print("Error: populationInfo not found")

            return respond(TeleportResponseType.teleportError)
        end

        if populationInfo.max_emptySlots == 0 then
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

        local LocalWorldInfo = require(ServerStorage.Location.ServerManagement.LocalWorldInfo)
        local populationInfo = GameServerData.getPopulationInfo(ServerTypeEnum.location, {
            locationEnum = locationEnum,
            worldIndex = LocalWorldInfo.worldIndex
        })

        if populationInfo and populationInfo.max_emptySlots == 0 then
            return respond(TeleportResponseType.full)
        end

        PlayerData.yieldUntilHopReady(player)

        local success = Teleport.teleportToLocation(player, locationEnum)

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

        if targetPlayerLocation.serverType == ServerTypeEnum.location then
            local populationInfo = GameServerData.getPopulationInfo(ServerTypeEnum.location, {
                worldIndex = targetPlayerLocation.worldIndex,
                locationEnum = targetPlayerLocation.locationEnum,
            })
            
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
        else
            return respond(TeleportResponseType.invalid)
        end
    end
end)

