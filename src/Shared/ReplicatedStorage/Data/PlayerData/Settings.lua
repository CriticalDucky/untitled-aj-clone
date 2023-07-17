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
local ClientState = if not isServer then require(script.Parent:WaitForChild "ClientState") else nil
local DataReplication = require(script.Parent:WaitForChild "DataReplication")

local peek = if Fusion then Fusion.peek else nil

--#endregion

--#region Action Registration

if isServer then
	DataReplication.registerActionAsync("SetSettingFindOpenWorld", function(player: Player, value: boolean)
		if typeof(value) ~= "boolean" then
			DataReplication.replicate(
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
			DataReplication.replicate(
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
			DataReplication.replicate(
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
			DataReplication.replicate(
				"SetSettingSFXVolume",
				PlayerDataManager.viewPersistentData(player).settings.sfxVolume,
				player
			)

			return
		end

		PlayerDataManager.setValuePersistentAsync(player, { "settings", "sfxVolume" }, value)
	end)
else
	DataReplication.registerActionAsync(
		"SetSettingFindOpenWorld",
		function(value: boolean) ClientState.playerSettings.findOpenWorld:set(value) end
	)

	DataReplication.registerActionAsync(
		"SetSettingHomeLock",
		function(value: number) ClientState.playerSettings.homeLock:set(value) end
	)

	DataReplication.registerActionAsync(
		"SetSettingMusicVolume",
		function(value: number) ClientState.playerSettings.musicVolume:set(value) end
	)

	DataReplication.registerActionAsync(
		"SetSettingSFXVolume",
		function(value: number) ClientState.playerSettings.sfxVolume:set(value) end
	)
end

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's settings.
]]
local Settings = {}

--[[
	Gets the player's *Find Open World* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
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
		return peek(ClientState.settings.findOpenWorld)
	end
end

--[[
	Gets the Fusion state object for the player's *Find Open World* setting.

	---

	This function is **client only**.

	---

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingFindOpenWorldState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return ClientState.settings.findOpenWorld
end

--[[
	Gets the player's *Home Lock* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
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
		return peek(ClientState.settings.homeLock)
	end
end

--[[
	Gets the Fusion state object for the player's *Home Lock* setting.

	---

	This function is **client only**.

	---

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingHomeLockState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return ClientState.settings.homeLock
end

--[[
	Gets the player's *Music Volume* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
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
		return peek(ClientState.settings.musicVolume)
	end
end

--[[
	Gets the Fusion state object for the player's *Music Volume* setting.

	---

	This function is **client only**.

	---

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingMusicVolumeState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return ClientState.settings.musicVolume
end

--[[
	Gets the player's *SFX Volume* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
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
		return peek(ClientState.settings.sfxVolume)
	end
end

--[[
	Gets the Fusion state object for the player's *SFX Volume* setting.

	---

	This function is **client only**.

	---

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Settings.getSettingSFXVolumeState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return ClientState.settings.sfxVolume
end

--[[
	Sets the player's *Find Open World* setting.

	---

	The player parameter is **required** on the server and **ignored** on the client.
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
		DataReplication.replicate("SetSettingFindOpenWorld", value, player)
	else
		ClientState.playerSettings.findOpenWorld:set(value)
		DataReplication.replicate("SetSettingFindOpenWorld", value)
	end
end

--[[
	Sets the player's *Home Lock* setting.

	---
	
	The given home lock type must be a valid `HomeLockType` enum value.

	The player parameter is **required** on the server and **ignored** on the client.
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
		DataReplication.replicate("SetSettingHomeLock", homeLockType, player)
	else
		ClientState.playerSettings.homeLock:set(homeLockType)
		DataReplication.replicate("SetSettingHomeLock", homeLockType)
	end
end

--[[
	Sets the player's *Music Volume* setting.
	
	---
	
	The given volume must be a number between 0 and 1.

	The player parameter is **required** on the server and **ignored** on the client.
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
		DataReplication.replicate("SetSettingMusicVolume", volume, player)
	else
		ClientState.playerSettings.musicVolume:set(volume)
		DataReplication.replicate("SetSettingMusicVolume", volume)
	end
end

--[[
	Sets the player's *SFX Volume* setting.
	
	---
	
	The given volume must be a number between 0 and 1.
	
	The player parameter is **required** on the server and **ignored** on the client.
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
		DataReplication.replicate("SetSettingSFXVolume", volume, player)
	else
		ClientState.playerSettings.sfxVolume:set(volume)
		DataReplication.replicate("SetSettingSFXVolume", volume)
	end
end

return Settings
