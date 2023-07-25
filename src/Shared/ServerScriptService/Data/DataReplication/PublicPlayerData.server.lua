--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

DataReplication.registerActionAsync(
	"SubscribeToPersistentData",
	function(player, userId)
		if typeof(userId) ~= "number" or userId ~= userId then return end

		PlayerDataManager.subscribePlayerToPersistentData(player, userId) end
)
