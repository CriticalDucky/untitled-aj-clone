--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local StateClient = if not isServer then require(script.Parent:WaitForChild "StateClient") else nil
local StateReplication = require(script.Parent:WaitForChild "StateReplication")

local peek = if Fusion then Fusion.peek else nil

--#endregion

--#region Action Registration

if not isServer then
	StateReplication.registerActionAsync("SetMoney", function(amount)
		StateClient.currency.money:set(amount)
	end)
end

--#endregion

--[[
	A submodule of `PlayerState` that handles the player's currency.
]]
local Currency = {}

--[[
    Gets the amount of money the player has.

    ---

    *The player parameter is **required** on the server and **ignored** on the client.*
]]
function Currency.getMoney(player: Player?)
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

		return data.currency.money
	else
		return peek(StateClient.currency.money)
	end
end

--[[
	Gets the state object for the amount of money the player has.

	---

	*Client only.*

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Currency.getMoneyState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return StateClient.currency.money
end

--[[
	Increments the amount of money the player has. The amount provided will be rounded up to the nearest integer.

	---

	*Server only.*
]]
function Currency.incrementMoney(player: Player, amount: number)
	if not isServer then
		warn "This function can only be called on the server. No state will be modified."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their money cannot be modified."
		return
	end

	local currentMoney = PlayerDataManager.viewPersistentData(player).currency.money

	Currency.setMoney(player, currentMoney + amount)
end

--[[
	Sets the amount of money the player has. The amount provided will be rounded up to the nearest integer.

	---

	*Server only.*
]]
function Currency.setMoney(player: Player, amount: number)
	if not isServer then
		warn "This function can only be called on the server. No state will be modified."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their money cannot be modified."
		return
	end

	amount = math.ceil(amount)

	PlayerDataManager.setValuePersistent(player, { "currency", "money" }, amount)
	StateReplication.replicate("SetMoney", amount, player)
end

return Currency
