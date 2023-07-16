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

local playerData = ReplicaCollection.waitForReplica(`PrivatePlayerData{player.UserId}`).Data

--#endregion

local ClientState = {
	currency = {
		money = Value(playerData.currency.money),
	},

	home = {
		selected = Value(playerData.home.selected),
	},

	inventory = {
		accessories = Value(playerData.inventory.accessories),
		furniture = Value(playerData.inventory.furniture),
		homes = Value(playerData.inventory.homes),
	},

	settings = {
		findOpenWorld = Value(playerData.settings.findOpenWorld),
		homeLock = Value(playerData.settings.homeLock),
		musicVolume = Value(playerData.settings.musicVolume),
		sfxVolume = Value(playerData.settings.sfxVolume),
	},
}

return ClientState
