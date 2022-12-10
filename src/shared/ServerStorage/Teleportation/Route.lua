local TESTING_DONT_TELEPORT = false

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local teleportation = serverStorageShared.Teleportation
local enumsFolder = ReplicatedStorage.Shared.Enums

local Teleport = require(teleportation.Teleport)
local ServerData = require(serverManagement.ServerData)
local PlayerData = require(serverStorageShared.Data.PlayerData)

local Route = {}

function Route.routeToWorld(player, worldsExcluded)
    if worldsExcluded and #worldsExcluded > 4 then
        warn("Too many worlds excluded")
        return
    end

    local worldIndex, locationEnum = ServerData.findAvailableWorldAndLocation(nil, worldsExcluded)

    local function teleport()
        return Teleport.toLocation(player, locationEnum, worldIndex)
    end

    if worldIndex then
        print("Routing to world")

        if TESTING_DONT_TELEPORT then
            return true
        end

        local teleportSuccess, teleportResults = teleport()

        if teleportSuccess then
            return true
        else
            local teleportResult = teleportResults and teleportResults[player]

            if teleportResult == Enum.TeleportResult.GameFull then
                locationEnum = ServerData.findAvailableLocation(worldIndex, {locationEnum})

                if locationEnum then
                    teleportSuccess, teleportResults = teleport()
                    local teleportResult = teleportResults and teleportResults[player]

                    if teleportSuccess then
                        return true
                    elseif teleportResult == Enum.TeleportResult.GameFull then
                        worldsExcluded = worldsExcluded or {}
                        
                        table.insert(worldsExcluded, worldIndex)

                        return Route.routeToWorld(player, worldsExcluded)
                    end
                end
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

    local success = Teleport.toPlayer(player, followingPlayerId)

    if success then
        return true
    else
        return false
    end
end

function Route.onRouteFailure(player)
    Teleport.rejoin(player, "An internal server error occurred. Please try again later. (err code R1)")
end

return Route

