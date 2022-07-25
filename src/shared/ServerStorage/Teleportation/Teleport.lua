local RETRY_DELAY = 0.5
local MAX_RETRIES = 10
local FLOOD_DELAY = 15

local TELEPORT_TO_PLAYER_TIMEOUT = 5
local TELEPORT_TO_PLAYER_TOPIC = "playerJoinQuery"
local TELEPORT_TO_PLAYER_RESPONSE_TOPIC = "playerJoinQueryResponse"

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
local Message = require(messagingFolder:WaitForChild("Message"))
local PlayerLocationData = require(serverManagement:WaitForChild("PlayerLocationData"))

local Teleport = {}

local function safeTeleport(destination, players, options)
    local attemptIndex = 0
    local success, result
 
    repeat
        success, result = pcall(function()
            return TeleportService:TeleportAsync(destination, players, options)
        end)

        attemptIndex += 1

        if not success then
            task.wait(RETRY_DELAY)
        end
    until success or attemptIndex == MAX_RETRIES
 
    if not success then
        warn("SafeTeleport fail: " .. result)
    end
 
    return success, result
end

local function handleFailedTeleport(player, teleportResult, errorMessage, targetPlaceId, teleportOptions)
    if teleportResult == Enum.TeleportResult.Flooded then
        task.wait(FLOOD_DELAY)
    elseif teleportResult == Enum.TeleportResult.Failure then
        task.wait(RETRY_DELAY)
    else
        -- if the teleport is invalid, don't retry, just report the error
        error(("Invalid teleport [%s]: %s"):format(teleportResult.Name, errorMessage))
    end
 
    safeTeleport(targetPlaceId, {player}, teleportOptions)
end

function Teleport.teleport(players, placeId, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return safeTeleport(placeId, players, teleportOptions)
end

function Teleport.teleportToLocation(players, locationEnum, world)
    if not locationEnum then
        return false
    end

    local locationInfo = Locations.info[locationEnum]
    local teleportOptions = Instance.new("TeleportOptions")

    if world then
        local location = world.locations[locationEnum]

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return Teleport.teleport(players, locationInfo.placeId, teleportOptions)
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

            return Teleport.teleport(players, locationInfo.placeId, teleportOptions)
        else
            return false
        end
    end
end

function Teleport.teleportToPlayer(player: Player, targetPlayerId)
    
end

TeleportService.TeleportInitFailed:Connect(handleFailedTeleport)

return Teleport