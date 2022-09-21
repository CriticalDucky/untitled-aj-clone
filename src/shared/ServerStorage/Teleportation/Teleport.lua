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
local messagingFolder = serverStorageShared.Messaging
local enumsFolder = replicatedStorageShared.Enums

local Locations = require(replicatedStorageShared.Server.Locations)
local LocalServerInfo = require(serverManagement.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local FillStatusEnum = require(enumsFolder.FillStatus)
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

function Teleport.teleport(players, placeId, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return safeTeleport(placeId, players, teleportOptions)
end

function Teleport.teleportToLocation(player, locationEnum, worldIndex)
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

        local serverData = GameServerData.get(ServerTypeEnum.location, {worldIndex = worldIndex, locationEnum = locationEnum})
        local population = if serverData then #serverData.players else 0

        if population >= Constants.location_maxPlayers then
            warn("Teleport.teleportToLocation: location is full")
            return false
        end

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
    else
        if LocalServerInfo.serverType == ServerTypeEnum.location then
            local serverStorageLocation = ServerStorage.Location
            local locationServerManagement = serverStorageLocation.ServerManagement
            local LocalWorldInfo = require(locationServerManagement.LocalWorldInfo)

            local location = worlds[LocalWorldInfo.worldIndex].locations[locationEnum]
            local serverData = GameServerData.get(ServerTypeEnum.location, {worldIndex = LocalWorldInfo.worldIndex, locationEnum = locationEnum})
            local population = if serverData then #serverData.players else 0

            if population >= Constants.location_maxPlayers then
                warn("Teleport.teleportToLocation: location is full")
                return false
            end

            teleportOptions.ReservedServerAccessCode = location.serverCode
            teleportOptions:SetTeleportData({
                locationFrom = LocalWorldInfo.locationEnum,
            })

            return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
        else
            print("Cannot teleport to location from a non-location server")
            return false
        end
    end
end

function Teleport.teleportToPlayer(player: Player, targetPlayerId) -- TODO: false return management
    local success, targetPlayerIsPlaying = pcall(function()
        local currentInstance, _, placeId, jobId = TeleportService:GetPlayerPlaceInstanceAsync(targetPlayerId)

        return currentInstance ~= nil and placeId ~= nil and jobId ~= nil
    end)

    if not success or not targetPlayerIsPlaying then
        print("Target player is not playing")
        return false
    end

    local targetPlayerLocation = PlayerLocation.get(targetPlayerId)

    if not targetPlayerLocation then
        print("Target player is not in a location")
        return false
    end

    if targetPlayerLocation.serverType == ServerTypeEnum.location then
        local serverData = GameServerData.getLocation(
            targetPlayerLocation.worldIndex,
            targetPlayerLocation.locationEnum
        )
        
        if not serverData then
            print("Target player is unable to be teleported to")
            return false
        end

        if #serverData.players >= Constants.location_maxPlayers then
            print("Target player's location is full")
            return false
        end

        return Teleport.teleportToLocation(
            {player},
            targetPlayerLocation.locationEnum,
            targetPlayerLocation.worldIndex
        )
    else
        print("Target player is not in a location")
        return false
    end
end

return Teleport