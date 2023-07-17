--#region Imports

local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local ClientState = if not isServer then require(script.Parent:WaitForChild "ClientState") else nil
local DataReplication = require(script.Parent:WaitForChild "DataReplication")
local PlayerDataManager =
	require(ServerStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild "PlayerDataManager")

local localPlayer = Players.LocalPlayer

--#endregion

--#region Action Registration

if isServer then
	DataReplication.registerActionAsync(
		"SubscribeToPersistentData",
		function(player, userId) PlayerDataManager.subscribePlayerToPersistentData(player, userId) end
	)
end

--#endregion

--[[
    A submodule of `PlayerData` that handles players' public data.
]]

local PublicPlayerData = {}

--[[
    Subscribes the given player to the persistent data of the (likely) offline player with the given ID.

    ---

    This function is **client only**. The server can subscribe a player directly in `PlayerDataManager`.

    For more info on subscriptions, see `PlayerDataManager`.
]]
function PublicPlayerData.subscribeToPersistentData(userId: number)
	if isServer then
		warn "This function can only be called on the client. No player will be subscribed to."
		return
	end

	DataReplication.replicate("SubscribeToPersistentData", userId)
end

return PublicPlayerData
