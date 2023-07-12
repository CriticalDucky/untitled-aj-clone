--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local Value = Fusion.Value

local ReplicaCollection =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild "ReplicaCollection")

--#endregion

--#region Variables

local player = Players.LocalPlayer

local playerData = ReplicaCollection.waitForReplica("PrivatePlayerData" .. player.UserId).Data
-- local tempData = ReplicaCollection.waitForReplica("PrivatePlayerTempData" .. player.UserId).Data

--#endregion

local ClientState = {
	currency = {
		money = Value(playerData.currency.money),
	},

	inventory = {
		accessories = Value(playerData.inventory.accessories),
		homeItems = Value(playerData.inventory.homeItems),
		homes = Value(playerData.inventory.homes),
	},

	playerSettings = {
		findOpenWorld = Value(playerData.playerSettings.findOpenWorld),
		homeLock = Value(playerData.playerSettings.homeLock),
		selectedHome = Value(playerData.playerSettings.selectedHome),
		musicVolume = Value(playerData.playerSettings.musicVolume),
		sfxVolume = Value(playerData.playerSettings.sfxVolume),
	},
}

return ClientState
