local TESTING_DONT_TELEPORT = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local teleportation = serverStorageShared.Teleportation
local enumsFolder = ReplicatedStorage.Shared.Enums

local Teleport = require(teleportation.Teleport)
local WorldData = require(serverManagement.WorldData)
local PlayerData = require(serverStorageShared.Data.PlayerData)

local Route = {}

function Route.routeToWorld(player) -- Once any of these functions are called, the player can no longer stay in this server
    local worldIndex, locationEnum = WorldData.findAvailable()

    if worldIndex then
        print("Routing to world")

        if TESTING_DONT_TELEPORT then
            return true
        end

        local teleportSuccess, teleportResult = Teleport.teleportToLocation(player, locationEnum, worldIndex)

        if teleportSuccess then
            return true
        else
            if teleportResult == Enum.TeleportResult.GameFull then
                return Route.routeToWorld(player) -- Try again
            end
            
            return false
        end
    else
        warn("No available world found")

        return false
    end
end

function Route.routeToPlayer(player)
    print("Routing player to player")

    local followingPlayerId = player.FollowUserId
    local followingPlayerIsInServer do
        for _, playerInServer in pairs(Players:GetPlayers()) do
            if playerInServer.UserId == followingPlayerId then
                followingPlayerIsInServer = true
                break
            end
        end
    end

    if followingPlayerIsInServer then
        warn("Following player is in server")
        return false
    end

    local success = Teleport.teleportToPlayer(player, followingPlayerId)

    if success then
        return true
    else
        return false
    end
end

function Route.onRouteFailure(player)
    Teleport.rejoin(player) -- Guthub copilot, please stop commenting on my code all the time
end

return Route

