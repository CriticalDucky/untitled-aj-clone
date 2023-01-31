local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local teleportation = serverStorageShared.Teleportation

local Teleport = require(teleportation.Teleport)
local ServerData = require(serverStorageShared.ServerManagement.ServerData)

local function onRouteFailure(player)
	Teleport.rejoin(player, "An internal server error occurred. Please try again later. (err code R1)")
end

local function routeToWorld(player)
	return ServerData.findAvailableWorld():andThen(function(worldIndex)
		return Teleport.toWorld(player, worldIndex, function(player)
			onRouteFailure(player)
		end)
	end):catch(function()
        onRouteFailure(player)
    end)
end

local function playerAdded(player: Player)
	local followUserId = player.FollowUserId

	if followUserId == 0 then
		routeToWorld(player)
	elseif followUserId ~= 0 then
		Teleport.Authorize
			.toPlayer(player, followUserId)
			:andThen(function()
				Teleport.toPlayer(player, followUserId, function()
					routeToWorld(player)
				end):catch(function()
					routeToWorld(player)
				end)
			end)
			:catch(function()
				routeToWorld(player)
			end)
	end
end

for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
