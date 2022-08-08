local RETRY_DELAY = 0.5
local MAX_RETRIES = 10
local FLOOD_DELAY = 15

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local messagingFolder = serverStorageShared:WaitForChild("Messaging")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Locations = require(serverManagement:WaitForChild("Locations"))
local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))
local Message = require(messagingFolder:WaitForChild("Message"))
local PlayerLocationData = require(serverManagement:WaitForChild("PlayerLocationData"))
local WorldData = require(serverManagement:WaitForChild("WorldData"))
local WorldFillData = require(serverManagement:WaitForChild("WorldFillData"))

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

function Teleport.teleportToLocation(player, locationEnum, world)
    if not locationEnum then
        print("Teleport.teleportToLocation: locationEnum is nil")
        return false
    end

    local locationInfo = Locations.info[locationEnum]
    local teleportOptions = Instance.new("TeleportOptions")

    if world then
        local location = world.locations[locationEnum]

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
    else
        if LocalServerInfo.serverType == ServerTypeEnum.location then
            local serverStorageLocation = ServerStorage:WaitForChild("Location")
            local locationServerManagement = serverStorageLocation:WaitForChild("ServerManagement")
            local LocalWorldInfo = require(locationServerManagement:WaitForChild("LocalWorldInfo"))

            local world = LocalWorldInfo.getWorldData()
            local location = world.locations[locationEnum]

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

    local targetPlayerLocationData = PlayerLocationData.get(targetPlayerId)

    if not targetPlayerLocationData then
        print("Target player is not in a location")
        return false
    end

    if targetPlayerLocationData.serverType == ServerTypeEnum.location then
        local fillStatus = WorldFillData.get(
            targetPlayerLocationData.worldIndex,
            targetPlayerLocationData.locationEnum
        )

        if fillStatus == FillStatusEnum.full then
            print("Target player's location is full")
            return false
        end

        local worldData = WorldData.get()

        if not worldData then
            print("World data is nil")
            return false
        end

        return Teleport.teleportToLocation(
            {player},
            targetPlayerLocationData.locationEnum,
            worldData[targetPlayerLocationData.worldIndex]
        )
    else
        print("Target player is not in a location")
        return false
    end
end

return Teleport