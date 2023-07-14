--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Enums"

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

local HomeLockType = require(enumsFolder:WaitForChild "HomeLockType")
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local StateClient = if not isServer then require(script.Parent:WaitForChild "StateClient") else nil
local StateReplication = require(script.Parent:WaitForChild "StateReplication")

local peek = if Fusion then Fusion.peek else nil

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
			StateReplication.replicate(
				"SetSettingMusicVolume",
				PlayerDataManager.viewPersistentData(player).settings.musicVolume,
				player
			)

			return
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, value)
	end)

	StateReplication.registerActionAsync("SetSettingSFXVolume", function(player: Player, value: number)
		if typeof(value) ~= "number" or value ~= value or value ~= math.clamp(value, 0, 1) then
			StateReplication.replicate(
				"SetSettingSFXVolume",
				PlayerDataManager.viewPersistentData(player).settings.sfxVolume,
				player
			)

			return
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, value)
	end)
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
	A submodule of `PlayerState` that handles the player's settings.
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
		return peek(StateClient.settings.findOpenWorld)
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
		warn "This function can only be called on the client. No state will be returned."
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
		return peek(StateClient.settings.homeLock)
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
		warn "This function can only be called on the client. No state will be returned."
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
		return peek(StateClient.settings.musicVolume)
	end
end

--[[
	Gets the the state object for the player's *Music Volume* setting.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingMusicVolumeState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
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
		return peek(StateClient.settings.sfxVolume)
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
		warn "This function can only be called on the client. No state will be returned."
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
    Sets the player's *Home Lock* setting. The given home lock type must be a valid `HomeLockType` enum value.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingHomeLock(homeLockType: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "homeLock" }, homeLockType)
		StateReplication.replicate("SetSettingHomeLock", homeLockType, player)
	else
		StateClient.playerSettings.homeLock:set(homeLockType)
		StateReplication.replicate("SetSettingHomeLock", homeLockType)
	end
end

--[[
    Sets the player's *Music Volume* setting. The given volume must be a number between 0 and 1.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingMusicVolume(volume: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "musicVolume" }, volume)
		StateReplication.replicate("SetSettingMusicVolume", volume, player)
	else
		StateClient.playerSettings.musicVolume:set(volume)
		StateReplication.replicate("SetSettingMusicVolume", volume)
	end
end

--[[
    Sets the player's *SFX Volume* setting. The given volume must be a number between 0 and 1.

	---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Settings.setSettingSFXVolume(volume: number, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, volume)
		StateReplication.replicate("SetSettingSFXVolume", volume, player)
	else
		StateClient.playerSettings.sfxVolume:set(volume)
		StateReplication.replicate("SetSettingSFXVolume", volume)
	end
end

return Settings
