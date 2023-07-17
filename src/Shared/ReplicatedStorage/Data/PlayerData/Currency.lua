--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local ClientState = if not isServer then require(script.Parent:WaitForChild "ClientState") else nil
local DataReplication = require(script.Parent:WaitForChild "DataReplication")

local peek = if Fusion then Fusion.peek else nil

--#endregion

--#region Action Registration

if not isServer then
	DataReplication.registerActionAsync("SetMoney", function(amount)
		ClientState.currency.money:set(amount)
	end)
end

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's currency.
]]
local Currency = {}

--[[
	Increments the amount of money the player has. The amount provided will be rounded up to the nearest integer.

	---

	This function is **server only**.
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

	This function is **server only**.
]]
function Currency.setMoney(player: Player, amount: number)
	if not isServer then
		warn "This function can only be called on the server. No data will be modified."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so their money cannot be modified."
		return
	end

	amount = math.ceil(amount)

	PlayerDataManager.setValuePersistent(player, { "currency", "money" }, amount)
	DataReplication.replicate("SetMoney", amount, player)
end

return Currency
