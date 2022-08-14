local TESTING_DONT_TELEPORT = false

local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local teleportation = serverStorageShared:WaitForChild("Teleportation")
local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums")

local Teleport = require(teleportation:WaitForChild("Teleport"))
local WorldData = require(serverManagement:WaitForChild("WorldData"))
local WorldFillData = require(serverManagement:WaitForChild("WorldFillData"))
local Locations = require(serverManagement:WaitForChild("Locations"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))

local function routeUnsuccessful(player, reason)
    -- TODO: Route unsuccessful
    warn("Route unsuccessful: " .. reason)
end

local function routeToWorld(player)
    local world, locationEnum = WorldData.findAvailable()

    if world then
        print("Rerouting to world")

        if TESTING_DONT_TELEPORT then
            return true
        end

        local teleportSuccess, teleportResult = Teleport.teleportToLocation({player}, locationEnum, world)

        if teleportSuccess then
            return true
        else
            if teleportResult == Enum.TeleportResult.GameFull then
                WorldFillData.localSet(world, locationEnum, FillStatusEnum.full)

                return routeToWorld(player)
            end
            
            return false
        end
    else
        warn("No available world found")

        return false
    end
end

local function routeToPlayer(player)
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
    if player.FollowUserId == 0 then
        if not routeToWorld(player) then
            routeUnsuccessful()
        end
    elseif player.FollowUserId ~= 0 then
        if not (routeToPlayer(player) or routeToWorld(player)) then
            routeUnsuccessful()
        end
    end
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)

