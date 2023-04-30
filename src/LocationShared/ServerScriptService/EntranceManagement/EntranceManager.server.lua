local ServerStorage = game:GetService "ServerStorage"
local Players = game:GetService "Players"

local serverStorageShared = ServerStorage.Shared
local entranceDataFolder = ServerStorage.EntranceData
local teleportation = serverStorageShared.Teleportation

local Entrances = require(entranceDataFolder.Entrances)
local Teleport = require(teleportation.Teleport)

local playersTouched = {}

for locationEnum, entranceComponents in pairs(Entrances.groups) do
	entranceComponents.exit.Touched:Connect(function(touchedPart)
		local player = Players:GetPlayerFromCharacter(touchedPart.Parent)

		if player and not playersTouched[player] then
			playersTouched[player] = true

			local success, result = Teleport.toLocation(player, locationEnum)

			if not success then
				warn(result)
				-- Just never try again if it fails, so we don't spam the player with errors
				return
			end

			for _, promise in result do
				promise
					:andThen(function()
						playersTouched[player] = nil
					end)
					:catch(function(result)
						warn("Failed to teleport player: " .. result)
					end)
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	playersTouched[player] = nil
end)
