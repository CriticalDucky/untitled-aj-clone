--!strict

--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

ClientServerCommunication.registerActionAsync(
	"SubscribeToPersistentData",
	function(player, userId)
		if typeof(userId) ~= "number" or userId ~= userId then return end

		PlayerDataManager.subscribePlayerToPersistentData(player, userId) end
)
