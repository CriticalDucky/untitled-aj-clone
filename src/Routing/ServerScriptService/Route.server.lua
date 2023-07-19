local Players = game:GetService "Players"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local teleportation = serverStorageShared.Teleportation

local Teleport = require(teleportation.Teleport)
local ServerData = require(serverStorageShared.ServerManagement.ServerData)

local function onRouteFailure(player)
	Teleport.rejoin(player, "An internal server error occurred. Please try again later. (err code R1)")
end

local function routeToWorld(player)
	local success, worldIndex = ServerData.findAvailableWorld()

	if not success then return onRouteFailure(player) end

	local succees, result = Teleport.toWorld(player, worldIndex)

	if not succees then return onRouteFailure(player) end

	for _, promise in pairs(result) do
		promise:catch(function(err)
			warn("RouteToWorld error: " .. tostring(err))

			onRouteFailure(player)
		end)
	end

	return
end

local function playerAdded(player: Player)
	local followUserId = player.FollowUserId

	if followUserId == 0 or Players:GetPlayerByUserId(followUserId) then
		routeToWorld(player)
	elseif followUserId ~= 0 then
		local isAllowed = Teleport.Authorize.toPlayer(player, followUserId)

		if not isAllowed then
			warn("Player ", player.Name, " tried to follow ", followUserId, " but was not allowed")

			return routeToWorld(player)
		end

		local success, result = Teleport.toPlayer(player, followUserId)

		if not success then
			warn("Player ", player.Name, " tried to follow ", followUserId, " but failed to teleport to them")

			return routeToWorld(player)
		end

		for _, promise in pairs(result) do
			promise:catch(function(err)
				warn("Route tp player error: " .. tostring(err))

				routeToWorld(player)
			end)
		end
	end

	return
end

for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
