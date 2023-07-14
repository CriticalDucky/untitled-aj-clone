--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Enums"

local HomeLockType = require(enumsFolder:WaitForChild "HomeLockType")
local PlayerDataManager = if isServer
	then require(ServerStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild "PlayerDataManager")
	else nil
local StateClient = if not isServer then require(script.Parent:WaitForChild "StateClient") else nil
local StateReplication = require(script.Parent:WaitForChild "StateReplication")

--#endregion

--#region Action Registration

if isServer then
	StateReplication.registerActionAsync("SetSettingFindOpenWorld", function(player: Player, value: boolean)
		if typeof(value) ~= "boolean" then
			StateReplication.replicate(
				"SetSettingFindOpenWorld",
				PlayerDataManager.viewPersistentData(player).settings.findOpenWorld,
				player
			)

			return
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "findOpenWorld" }, value)
	end)

	StateReplication.registerActionAsync("SetSettingHomeLock", function(player: Player, value: number)
		local validValue = false

		for _, enumValue: number in HomeLockType do
			if value == enumValue then
				validValue = true
				break
			end
		end

		if not validValue then
			StateReplication.replicate(
				"SetSettingHomeLock",
				PlayerDataManager.viewPersistentData(player).settings.homeLock,
				player
			)

			return
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "homeLock" }, value)
	end)

	StateReplication.registerActionAsync("SetSettingMusicVolume", function(player: Player, value: number)
		if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
			local salvageable = typeof(value) == "number" and value == value

			if salvageable then
				value = math.clamp(value, 0, 1)

				StateReplication.replicate(
					"SetSettingMusicVolume",
					PlayerDataManager.viewPersistentData(player).settings.musicVolume,
					player
				)
			end

			StateReplication.replicate(
				"SetSettingMusicVolume",
				PlayerDataManager.viewPersistentData(player).settings.musicVolume,
				player
			)

			if not salvageable then return end
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, value)
	end)

	StateReplication.registerActionAsync(
		"SetSettingSFXVolume",
		function(player: Player, value: number)
			PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, value)
		end
	)
else
	StateReplication.registerActionAsync(
		"SetSettingFindOpenWorld",
		function(value: boolean) StateClient.playerSettings.findOpenWorld:set(value) end
	)

	StateReplication.registerActionAsync(
		"SetSettingHomeLock",
		function(value: number) StateClient.playerSettings.homeLock:set(value) end
	)

	StateReplication.registerActionAsync(
		"SetSettingMusicVolume",
		function(value: number) StateClient.playerSettings.musicVolume:set(value) end
	)

	StateReplication.registerActionAsync(
		"SetSettingSFXVolume",
		function(value: number) StateClient.playerSettings.sfxVolume:set(value) end
	)
end

--#endregion

--[[
	A submodule of PlayerState that handles the player's settings.
]]
local Settings = {}

--[[
    Gets the player's *Find Open World* setting.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.getSettingFindOpenWorld(player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		local data = PlayerDataManager.viewPersistentData(player)

		if not data then
			warn "The player's persistent data is not loaded, so this setting cannot be retrieved."
			return
		end

		return data.settings.findOpenWorld
	else
		return StateClient.settings.findOpenWorld:get()
	end
end

--[[
	Gets the the state object for the player's *Find Open World* setting.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingFindOpenWorldState()
	if isServer then
		warn "This function is client-only. No state will be returned."
		return
	end

	return StateClient.settings.findOpenWorld
end

--[[
	Gets the player's *Home Lock* setting.

	---

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.getSettingHomeLock(player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		local data = PlayerDataManager.viewPersistentData(player)

		if not data then
			warn "The player's persistent data is not loaded, so this setting cannot be retrieved."
			return
		end

		return data.settings.homeLock
	else
		return StateClient.settings.homeLock:get()
	end
end

--[[
	Gets the the state object for the player's *Home Lock* setting.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingHomeLockState()
	if isServer then
		warn "This function is client-only. No state will be returned."
		return
	end

	return StateClient.settings.homeLock
end

--[[
	Gets the player's *Music Volume* setting.

	---

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.getSettingMusicVolume(player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		local data = PlayerDataManager.viewPersistentData(player)

		if not data then
			warn "The player's persistent data is not loaded, so this setting cannot be retrieved."
			return
		end

		return data.settings.musicVolume
	else
		return StateClient.settings.musicVolume:get()
	end
end

--[[
	Gets the the state object for the player's *Music Volume* setting.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!.*
]]
function Settings.getSettingMusicVolumeState()
	if isServer then
		warn "This function is client-only. No state will be returned."
		return
	end

	return StateClient.settings.musicVolume
end

--[[
	Gets the player's *SFX Volume* setting.

	---

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.getSettingSFXVolume(player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		local data = PlayerDataManager.viewPersistentData(player)

		if not data then
			warn "The player's persistent data is not loaded, so this setting cannot be retrieved."
			return
		end

		return data.settings.sfxVolume
	else
		return StateClient.settings.sfxVolume:get()
	end
end

--[[
	Gets the the state object for the player's *SFX Volume* setting.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingSFXVolumeState()
	if isServer then
		warn "This function is client-only. No state will be returned."
		return
	end

	return StateClient.settings.sfxVolume
end

--[[
    Sets the player's *Find Open World* setting.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingFindOpenWorld(value: boolean, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "findOpenWorld" }, value)
		StateReplication.replicate("SetSettingFindOpenWorld", value, player)
	else
		StateClient.playerSettings.findOpenWorld:set(value)
		StateReplication.replicate("SetSettingFindOpenWorld", value)
	end
end

--[[
    Sets the player's *Home Lock* setting.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingHomeLock(value: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "homeLock" }, value)
		StateReplication.replicate("SetSettingHomeLock", value, player)
	else
		StateClient.playerSettings.homeLock:set(value)
		StateReplication.replicate("SetSettingHomeLock", value)
	end
end

--[[
    Sets the player's *Music Volume* setting.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingMusicVolume(value: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, value)
		StateReplication.replicate("SetSettingMusicVolume", value, player)
	else
		StateClient.playerSettings.musicVolume:set(value)
		StateReplication.replicate("SetSettingMusicVolume", value)
	end
end

--[[
    Sets the player's *SFX Volume* setting.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingSFXVolume(value: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, value)
		StateReplication.replicate("SetSettingSFXVolume", value, player)
	else
		StateClient.playerSettings.sfxVolume:set(value)
		StateReplication.replicate("SetSettingSFXVolume", value)
	end
end

return Settings
