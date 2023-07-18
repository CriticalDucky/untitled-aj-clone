--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientState = require(ReplicatedStorage.Shared.Data.ClientState)
local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync(
	"SetSettingFindOpenWorld",
	function(value: boolean) ClientState.settings.findOpenWorld:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingHomeLock",
	function(value: number) ClientState.settings.homeLock:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingMusicVolume",
	function(value: number) ClientState.settings.musicVolume:set(value) end
)

DataReplication.registerActionAsync(
	"SetSettingSFXVolume",
	function(value: number) ClientState.settings.sfxVolume:set(value) end
)
