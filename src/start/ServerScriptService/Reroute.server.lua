local TESTING_DONT_TELEPORT = false

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local teleportation = serverStorageShared:WaitForChild("Teleportation")

local Teleport = require(teleportation:WaitForChild("Teleport"))
local ServerData = require(serverManagement:WaitForChild("ServerData"))
local Locations = require(serverManagement:WaitForChild("Locations"))

local function rerouteToWorld(player)
    local world, locationEnum = ServerData.findAvailableWorldAndLocation()

    if world then
        print("Rerouting to world")

        if TESTING_DONT_TELEPORT then
            return true
        end

        local teleportSuccess = Teleport.teleportToLocation({player}, locationEnum, world)

        if teleportSuccess then
            return true
        else
            warn("Failed to teleport player to world")
            return false
        end
    else
        warn("No available world found")
    end
end

local function rerouteToPlayer(player)
    print("Rerouting player to player")

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
        warn("Failed to teleport player to player")
        return false
    end
end

local function playerAdded(player: Player)

    local function rerouteUnsuccessful()

    end

    if player.FollowUserId == 0 then
        if not rerouteToWorld(player) then
            rerouteUnsuccessful()
        end
    elseif player.FollowUserId ~= 0 then
        if not (rerouteToPlayer(player) or rerouteToWorld(player)) then
            rerouteUnsuccessful()
        end
    end
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)

