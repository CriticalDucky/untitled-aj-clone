--[[
	STRUCTURE OF THIS MODULE

	This module allows access to submodules that manage specific parts of the player's state.

	Each state submodule has getters and setters for states in their respective categories.

	The client's copy of the player's state is stored in the `ClientState` submodule. The server's copy of the player's
	state is stored in the separate `PlayerDataManager` module. The `StateReplication` remote event is used for
	replicating state changes.
]]

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local SSDataFolder = ServerStorage:WaitForChild("Shared"):WaitForChild "Data"

local Fusion = if isServer then require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion") else nil

local PlayerDataManager = if isServer then require(SSDataFolder:WaitForChild "PlayerDataManager") else nil
local ClientState = if not isServer then require(script:WaitForChild "ClientState") else nil

local peek = if isServer then Fusion.peek else nil

--[[
    Event that manages state replication. ~~On the client, this will have a queue to allow for rapid state changes
	without overloading the event.~~
]]
local StateReplicationEvent = script:WaitForChild "StateReplication"

--#endregion

--#region Process Replicated Events

--[[
	All setters must include checks to ensure that the value is valid, and ignore the set request (with a warning) if it is not. When realistic, they should instead convert invalid values to valid ones (such as by rounding currency).

	When replicating, the server must ensure that client-issued requests are valid, and send a corrective request to the client if they are not. The server must not attempt to convert invalid values to valid ones, as this may cause the client to be out of sync with the server. The client need not perform any validation, as it is assumed that the server has already done so.
]]

if isServer then
	StateReplicationEvent.OnServerEvent:Connect(function(player: Player, actions: table)
		for action: string, data in actions do
			if action == "SetFindOpenWorld" then
				if typeof(data) ~= "boolean" then
					warn("Invalid value for Find Open World setting:", data)

					
					
					continue
				end
				
				PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "findOpenWorld" }, data)
			elseif action == "SetHomeLock" then
				PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "homeLock" }, data)
			elseif action == "SetSelectedHome" then
				PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "selectedHome" }, data)
			elseif action == "SetMusicVolume" then
				PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "musicVolume" }, data)
			elseif action == "SetSFXVolume" then
				PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "sfxVolume" }, data)
			end
		end
	end)
else
	StateReplicationEvent.OnClientEvent:Connect(function(actions: table)
		for action: string, data in actions do
			if action == "SetMoney" then
				ClientState.currency.money:set(data)
			elseif action == "SetFindOpenWorld" then
				ClientState.playerSettings.findOpenWorld:set(data)
			elseif action == "SetHomeLock" then
				ClientState.playerSettings.homeLock:set(data)
			elseif action == "SetSelectedHome" then
				ClientState.playerSettings.selectedHome:set(data)
			elseif action == "SetMusicVolume" then
				ClientState.playerSettings.musicVolume:set(data)
			elseif action == "SetSFXVolume" then
				ClientState.playerSettings.sfxVolume:set(data)
			end
		end
	end)
end

--#endregion

--[[
    Manages the player's state on both the client and server.
]]
local PlayerState = {}

--[[
	Gets the player's money.

	May return `nil` if the player's data cannot be retrieved.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getMoney(player: Player?): number?
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		local data = PlayerDataManager.viewPersistentDataAsync(player.UserId)

		if not data then
			warn("Player data not found for player", player)
			return
		end

		return data.currency.money
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.currency.money)
	end
end

--[[
	Gets a Fusion value that contains the player's money.
	
	*Client only.*
	
    *Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getMoneyState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.currency.money
end

--[[
	Gets the player's *Find Open World* setting.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getSettingFindOpenWorld(player: Player?)
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		local data = PlayerDataManager.viewPersistentDataAsync(player.UserId)

		if not data then
			warn("Player data not found for player", player)
			return
		end

		return data.playerSettings.findOpenWorld
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.playerSettings.findOpenWorld)
	end
end

--[[
	Gets a Fusion value that contains the player's *Find Open World* setting.
	
	*Client only.*
	
	*Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getSettingFindOpenWorldState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.playerSettings.findOpenWorld
end

--[[
	Gets the player's *Home Lock* setting.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getSettingHomeLock(player: Player?)
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		return PlayerDataManager.viewPersistentDataAsync(player.UserId).playerSettings.homeLock
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.playerSettings.homeLock)
	end
end

--[[
	Gets a Fusion value that contains the player's *Home Lock* setting.
	
	*Client only.*

	*Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getSettingHomeLockState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.playerSettings.homeLock
end

--[[
	Gets the player's *Selected Home* setting.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getSettingSelectedHome(player: Player)
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		return PlayerDataManager.viewPersistentDataAsync(player.UserId).playerSettings.selectedHome
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.playerSettings.selectedHome)
	end
end

--[[
	Gets a Fusion value that contains the player's *Selected Home* setting.

	*Client only.*
	
	*Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getSettingSelectedHomeState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.playerSettings.selectedHome
end

--[[
	Gets the player's *Music Volume* setting.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getSettingMusicVolume(player: Player)
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		return PlayerDataManager.viewPersistentDataAsync(player.UserId).playerSettings.musicVolume
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.playerSettings.musicVolume)
	end
end

--[[
	Gets a Fusion value that contains the player's *Music Volume* setting.
	
	*Client only.*

	*Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getSettingMusicVolumeState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.playerSettings.musicVolume
end

--[[
	Gets the player's *SFX Volume* setting.
	
    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.getSettingSfxVolume(player: Player)
	if isServer then
		assert(player, "A player must be provided when calling from the server")

		return PlayerDataManager.viewPersistentDataAsync(player.UserId).playerSettings.sfxVolume
	else
		if player then warn "The player parameter is unnecessary and ignored when calling from the client" end

		return peek(ClientState.playerSettings.sfxVolume)
	end
end

--[[
	Gets a Fusion value that contains the player's *SFX Volume* setting.
	
	*Client only.*
	
	*Do **NOT** modify the state returned by this function.*
]]
function PlayerState.getSettingSfxVolumeState()
	assert(not isServer, "This state can only be retrieved on the client. (Try getting the value directly instead.)")

	return ClientState.playerSettings.sfxVolume
end

--[[
	Increments the player's money.

	*Currency modification is server only.*
]]
function PlayerState.incrementMoney(amount: number, player: Player)
	assert(isServer, "Only the server can modify a player's money")

	local data = PlayerDataManager.viewPersistentDataAsync(player.UserId)

	if not data then
		warn("Could not increment money for player", player, "because their data could not be loaded.")
		return
	end

	PlayerState.setMoney(data.currency.money + amount, player)
end

--[[
	Sets the player's money.

	Non-integer values will be rounded up to the nearest integer.

    *Currency modification is server only.*
]]
function PlayerState.setMoney(amount: number, player: Player)
	assert(isServer, "Only the server can modify a player's money")

	amount = math.ceil(amount)

	PlayerDataManager.setValueProfileAsync(player, { "currency", "money" }, amount)
	StateReplicationEvent:FireClient(player, { SetMoney = amount })
end

--[[
    Sets the player's *Find Open World* setting.

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.setSettingFindOpenWorld(value: boolean, player: Player?)
	if isServer then
		if not player then
			warn "A player must be provided when calling from the server"
			return
		end

		PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "findOpenWorld" }, value)
		StateReplicationEvent:FireClient(player, { SetSettingFindOpenWorld = value })
	else
		if player then warn "The player parameter is ignored when calling from the client" end

		ClientState.playerSettings.findOpenWorld:set(value)
		StateReplicationEvent:FireServer { SetSettingFindOpenWorld = value }
	end
end

--[[
    Sets the player's *Home Lock* setting.

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.setSettingHomeLock(value: number, player: Player?)
	if isServer then
		if not player then
			warn "A player must be provided when calling from the server"
			return
		end

		PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "homeLock" }, value)
		StateReplicationEvent:FireClient(player, { SetSettingHomeLock = value })
	else
		if player then warn "The player parameter is ignored when calling from the client" end

		ClientState.playerSettings.homeLock:set(value)
		StateReplicationEvent:FireServer { SetSettingHomeLock = value }
	end
end

--[[
    Sets the player's *Selected Home* setting.

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.setSettingSelectedHome(value: number, player: Player?)
	if isServer then
		if not player then
			warn "A player must be provided when calling from the server"
			return
		end

		PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "selectedHome" }, value)
		StateReplicationEvent:FireClient(player, { SetSettingSelectedHome = value })
	else
		if player then warn "The player parameter is ignored when calling from the client" end

		ClientState.playerSettings.selectedHome:set(value)
		StateReplicationEvent:FireServer { SetSettingSelectedHome = value }
	end
end

--[[
    Sets the player's *Music Volume* setting.

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.setSettingMusicVolume(value: number, player: Player?)
	if isServer then
		if not player then
			warn "A player must be provided when calling from the server"
			return
		end

		PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "musicVolume" }, value)
		StateReplicationEvent:FireClient(player, { SetSettingMusicVolume = value })
	else
		if player then warn "The player parameter is ignored when calling from the client" end

		ClientState.playerSettings.musicVolume:set(value)
		StateReplicationEvent:FireServer { SetSettingMusicVolume = value }
	end
end

--[[
    Sets the player's *SFX Volume* setting.

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function PlayerState.setSettingSfxVolume(value: number, player: Player?)
	if isServer then
		if not player then
			warn "A player must be provided when calling from the server"
			return
		end

		PlayerDataManager.setValueProfileAsync(player, { "playerSettings", "sfxVolume" }, value)
		StateReplicationEvent:FireClient(player, { SetSettingSfxVolume = value })
	else
		if player then warn "The player parameter is ignored when calling from the client" end

		ClientState.playerSettings.sfxVolume:set(value)
		StateReplicationEvent:FireServer { SetSettingSfxVolume = value }
	end
end

return PlayerState
