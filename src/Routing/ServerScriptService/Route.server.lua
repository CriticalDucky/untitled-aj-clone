local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local teleportation = serverStorageShared.Teleportation

local Route = require(teleportation.Route)

local function playerAdded(player: Player)
    if player.FollowUserId == 0 then
        if not Route.routeToWorld(player) then
            Route.onRouteFailure()
        end
    elseif player.FollowUserId ~= 0 then
        if not (Route.routeToPlayer(player) or Route.routeToWorld(player)) then
            Route.onRouteFailure()
        end
    end
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)

