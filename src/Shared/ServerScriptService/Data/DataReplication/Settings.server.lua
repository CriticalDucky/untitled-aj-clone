--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)
local HomeLockType = require(ReplicatedFirst.Shared.Enums.HomeLockType)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

DataReplication.registerActionAsync("SetSettingFindOpenWorld", function(player: Player, value: boolean)
	if typeof(value) ~= "boolean" then
		DataReplication.replicateAsync(
			"SetSettingFindOpenWorld",
			PlayerDataManager.viewPersistentData(player).settings.findOpenWorld,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistentAsync(player, { "settings", "findOpenWorld" }, value)
end)

DataReplication.registerActionAsync("SetSettingHomeLock", function(player: Player, value: number)
	local validValue = false

	for _, enumValue: number in HomeLockType do
		if value == enumValue then
			validValue = true
			break
		end
	end

	if not validValue then
		DataReplication.replicateAsync(
			"SetSettingHomeLock",
			PlayerDataManager.viewPersistentData(player).settings.homeLock,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistentAsync(player, { "settings", "homeLock" }, value)
end)

DataReplication.registerActionAsync("SetSettingMusicVolume", function(player: Player, value: number)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		DataReplication.replicateAsync(
			"SetSettingMusicVolume",
			PlayerDataManager.viewPersistentData(player).settings.musicVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, value)
end)

DataReplication.registerActionAsync("SetSettingSFXVolume", function(player: Player, value: number)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		DataReplication.replicateAsync(
			"SetSettingSFXVolume",
			PlayerDataManager.viewPersistentData(player).settings.sfxVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, value)
end)
