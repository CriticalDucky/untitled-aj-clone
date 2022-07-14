local RETRY_DELAY = 0.5
local MAX_RETRIES = 10
local FLOOD_DELAY = 15

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local adventurePlaceIDs = {
    test1 = 10189748812
}

local Teleport = {}

local function SafeTeleport(destination, players, options)
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
        warn(result)
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
 
    SafeTeleport(targetPlaceId, {player}, teleportOptions)
end

function Teleport.teleport(players, placeId, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return SafeTeleport(placeId, players, teleportOptions)
end

TeleportService.TeleportInitFailed:Connect(handleFailedTeleport)

return Teleport