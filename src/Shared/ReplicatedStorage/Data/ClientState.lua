--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

assert(RunService:IsClient(), "ClientState can only be required on the client.")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

local ReplicaCollection =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild "ReplicaCollection")
local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

type PlayerPersistentData = Types.PlayerPersistentData

local Value = Fusion.Value

local player = Players.LocalPlayer

--#endregion

--#region Private Player Data

local privatePlayerData =
	ReplicaCollection.waitForReplica(`PrivatePlayerData{player.UserId}`).Data :: PlayerPersistentData

--#endregion

--#region Public Player Data

local publicPlayerData = ReplicaCollection.waitForReplica("PublicPlayerData").Data

local publicPlayerDataState = Value(publicPlayerData)

publicPlayerData:ListenToRaw(function(action) publicPlayerDataState:set(publicPlayerData) end)

--#endregion

--[[
	A submodule of `PlayerData` storing the client's state.

	---

	For proper server replication when modifying player data, use the `PlayerData` module.
]]
local ClientState = {
	currency = {
		money = Value(privatePlayerData.currency.money),
	},

	external = {
		worldPopulationList = Value(),
	},

	home = {
		selected = Value(privatePlayerData.home.selected),
	},

	inventory = {
		accessories = Value(privatePlayerData.inventory.accessories),
		furniture = Value(privatePlayerData.inventory.furniture),
		homes = Value(privatePlayerData.inventory.homes),
	},

	publicPlayerData = publicPlayerDataState,

	settings = {
		findOpenWorld = Value(privatePlayerData.settings.findOpenWorld),
		homeLock = Value(privatePlayerData.settings.homeLock),
		musicVolume = Value(privatePlayerData.settings.musicVolume),
		sfxVolume = Value(privatePlayerData.settings.sfxVolume),
	},
}

return ClientState
