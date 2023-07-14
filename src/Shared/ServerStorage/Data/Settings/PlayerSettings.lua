--[[
	Provides an interface to the PlayerSettings table in the player's profile data.
	Can read and set PlayerSettings settings.
]]

--#region Imports
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local utilityFolder = ReplicatedFirst.Shared.Utility

local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local Types = require(utilityFolder.Types)
--#endregion

local PlayerSettings = {}

--[[
	Gets the PlayerSettings table. The player does not need to be in this server.
	Refer to PlayerDataConfig.lua and search for "playerSettings" for the structure of this table.

	Returns a success boolean and the PlayerSettings table if successful.
]]
function PlayerSettings.get(player: Player | number)
	local profileData =
		PlayerDataManager.viewPersistentData(if typeof(player) == "number" then player else player.UserId)

	if profileData then
		return true, profileData.playerSettings
	else
		return false
	end
end

--[[
	Gets a PlayerSettings setting. The player does not need to be in this server.

	Returns a success boolean and the setting value if successful.
]]
function PlayerSettings.getSetting(player: Player | number, settingName: string)
	local success, playerSettings = PlayerSettings.get(player)

	if success then
		return true, playerSettings[settingName]
	else
		return false
	end
end

--[[
	Sets a PlayerSettings setting. The player must be in this server.

    Does not return anything.
]]
function PlayerSettings.setSetting(player: Player | number, settingName: string, value: any)
	assert(PlayerDataManager.persistentDataIsLoaded(player), "Player must have loaded profile")

	PlayerDataManager.setValuePersistentAsync(player, { "playerSettings", settingName }, value)
end

return PlayerSettings
