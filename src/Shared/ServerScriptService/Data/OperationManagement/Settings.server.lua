--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local HomeLockType = require(ReplicatedFirst.Shared.Enums.HomeLockType)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

--#endregion

ClientServerCommunication.registerActionAsync("SetSettingFindOpenWorld", function(player: Player, value)
	if typeof(value) ~= "boolean" then
		ClientServerCommunication.replicateAsync(
			"SetSettingFindOpenWorld",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.findOpenWorld,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "findOpenWorld" }, value)
end)

ClientServerCommunication.registerActionAsync("SetSettingHomeLock", function(player: Player, value)
	local validValue = false

	for _, enumValue in pairs(HomeLockType) do
		if value == enumValue then
			validValue = true
			break
		end
	end

	if not validValue then
		ClientServerCommunication.replicateAsync(
			"SetSettingHomeLock",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.homeLock,
			player
		)

		return
	end

	assert(typeof(value) == "number")

	PlayerDataManager.setValuePersistent(player, { "settings", "homeLock" }, value)
end)

ClientServerCommunication.registerActionAsync("SetSettingMusicVolume", function(player: Player, value)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		ClientServerCommunication.replicateAsync(
			"SetSettingMusicVolume",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.musicVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "musicVolume" }, value)
end)

ClientServerCommunication.registerActionAsync("SetSettingSFXVolume", function(player: Player, value)
	if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
		ClientServerCommunication.replicateAsync(
			"SetSettingSFXVolume",
			(PlayerDataManager.viewPersistentData(player) :: PlayerPersistentData).settings.sfxVolume,
			player
		)

		return
	end

	PlayerDataManager.setValuePersistent(player, { "settings", "sfxVolume" }, value)
end)
