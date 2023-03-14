--[[
	Provides an interface for getting player settings on the client.

	See GameSettings.lua to see all the player settings.
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ReplicatedPlayerData = require(dataFolder:WaitForChild "ReplicatedPlayerData")
local Types = require(utilityFolder:WaitForChild "Types")

type LocalPlayerParam = Types.LocalPlayerParam

local ClientPlayerSettings = {}

--[[
	Gets a player's setting. If the player is not available, this will return nil.
]]
function ClientPlayerSettings.getSetting(settingName: string, player: Player | number | nil, wait: boolean?)
	local data = ReplicatedPlayerData.get(player, wait)

	if data then
		local playerSettings = data.playerSettings

		if playerSettings then return playerSettings[settingName] end
	end
end

return ClientPlayerSettings
