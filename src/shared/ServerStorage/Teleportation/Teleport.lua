local RETRY_DELAY = 0.5
local MAX_RETRIES = 10
local FLOOD_DELAY = 15

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverManagement = serverStorageShared.ServerManagement
local enumsFolder = replicatedStorageShared.Enums

local Locations = require(replicatedStorageShared.Server.Locations)
local LocalServerInfo = require(serverManagement.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local PlayerLocation = require(serverManagement.PlayerLocation)
local WorldData = require(serverManagement.WorldData)
local GameServerData = require(serverManagement.GameServerData)
local Constants = require(replicatedStorageShared.Server.Constants)
local Table = require(replicatedFirstShared.Utility.Table)

local Teleport = {}

local function safeTeleport(destination, players, options)
    local attemptIndex = 0
    local teleportResult
    local success
 
    local teleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player, reason)
        if table.find(players, player) then -- If the player is in the list of players to teleport
            teleportResult = reason
        end
    end)

    repeat
        success = pcall(function()
            return TeleportService:TeleportAsync(destination, players, options)
        end)

        attemptIndex += 1

        if not success then
            task.wait(RETRY_DELAY)
        end
    until success or attemptIndex == MAX_RETRIES

    teleportFailConnection:Disconnect()

    return success, teleportResult
end

function Teleport.teleport(players: table, placeId, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return safeTeleport(placeId, players, teleportOptions)
end

function Teleport.teleportToLocation(players, locationEnum, worldIndex)
    if not locationEnum then
        print("Teleport.teleportToLocation: locationEnum is nil")
        return false
    end

    local worlds = WorldData.get()

    if not worlds then
        warn("Teleport.teleportToLocation: WorldData is nil")
        return false
    end

    local locationInfo = Locations.info[locationEnum]
    local teleportOptions = Instance.new("TeleportOptions")

    if worldIndex then
        local world = worlds[worldIndex]
        local location = world.locations[locationEnum]

        local populationInfo = GameServerData.getPopulationInfo(ServerTypeEnum.location, {
            worldIndex = worldIndex,
            locationEnum = locationEnum
        })

        if populationInfo and populationInfo.max_emptySlots == 0 then
            warn("Teleport.teleportToLocation: location is full")
            return false
        end

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return Teleport.teleport(players, locationInfo.placeId, teleportOptions)
    else
        if LocalServerInfo.serverType == ServerTypeEnum.location then
            local serverStorageLocation = ServerStorage.Location
            local locationServerManagement = serverStorageLocation.ServerManagement
            local LocalWorldInfo = require(locationServerManagement.LocalWorldInfo)

            local location = worlds[LocalWorldInfo.worldIndex].locations[locationEnum]
            local populationInfo = GameServerData.getPopulationInfo(ServerTypeEnum.location, {
                worldIndex = LocalWorldInfo.worldIndex,
                locationEnum = locationEnum
            })

            if populationInfo and populationInfo.max_emptySlots == 0 then
                warn("Teleport.teleportToLocation: location is full")
                return false
            end

            teleportOptions.ReservedServerAccessCode = location.serverCode
            teleportOptions:SetTeleportData({
                locationFrom = LocalWorldInfo.locationEnum,
            })

            return Teleport.teleport(players, locationInfo.placeId, teleportOptions)
        else
            print("Cannot teleport to location from a non-location server")
            return false
        end
    end
end

function Teleport.teleportToWorld(player, worldIndex)
    local worlds = WorldData.get()

    if not worlds then
        warn("Teleport.teleportToWorld: WorldData is nil")
        return false
    end

    local world = worlds[worldIndex]

    if not world then
        warn("Teleport.teleportToWorld: world is nil")
        return false
    end

    local locationEnum = WorldData.findAvailableLocation(worldIndex)

    if not locationEnum then
        warn("Teleport.teleportToWorld: no available locations")
        return false
    end

    local teleportSuccess = Teleport.teleportToLocation({player}, locationEnum, worldIndex)

    if not teleportSuccess then
        warn("Teleport.teleportToWorld: teleport failed")
        return false
    end

    return true
end

function Teleport.teleportToPlayer(player: Player, targetPlayerId)
    local targetPlayerLocation = PlayerLocation.get(targetPlayerId)

    if not targetPlayerLocation then
        print("Target player is not playing")
        return false
    end

    if targetPlayerLocation.serverType == ServerTypeEnum.location then
        local populationInfo = GameServerData.getPopulationInfo(ServerTypeEnum.location, {
            worldIndex = targetPlayerLocation.worldIndex,
            locationEnum = targetPlayerLocation.locationEnum,
        })
        
        if not populationInfo then
            print("Target player is unable to be teleported to")
            return false
        end

        if populationInfo.max_emptySlots == 0 then
            print("Target player's location is full")
            return false
        end

        local locationInfo = Locations.info[targetPlayerLocation.locationEnum]

        if locationInfo.cantJoinPlayer then
            print("Target player's location cannot be joined")
            return false
        end

        return Teleport.teleportToLocation(
            {player},
            targetPlayerLocation.locationEnum,
            targetPlayerLocation.worldIndex
        )
    else
        print("Target player is not in a supported server type")
        return false
    end
end

function Teleport.rejoin(players, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return Teleport.teleport(players, 10189729412, teleportOptions)
end

return Teleport