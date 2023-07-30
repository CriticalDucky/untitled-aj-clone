local ReplicatedFirst = game:GetService "ReplicatedFirst"

local enumsFolder = ReplicatedFirst.Shared.Enums

local HomeLockType = require(enumsFolder.HomeLockType)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

type PlayerDataInfo = {
	inventoryLimits: {
		accessories: number,
		furniture: number,
		homes: number,
	},
	persistentDataTemplate: PlayerPersistentData,
	tempDataTemplate: {},
}

--[[
	Configuration for player data.
]]
local PlayerDataInfo: PlayerDataInfo = {
	inventoryLimits = {
		accessories = 500,
		furniture = 500,
		homes = 200,
	},
	persistentDataTemplate = {
		currency = {
			money = 0,
		},

		home = {},

		inventory = {
			accessories = {},
			furniture = {},
			homes = {},
		},

		settings = {
			findOpenWorld = true,
			homeLock = HomeLockType.unlocked,
			musicVolume = 1,
			sfxVolume = 1,
		},
	},
	tempDataTemplate = {},
}

return PlayerDataInfo
