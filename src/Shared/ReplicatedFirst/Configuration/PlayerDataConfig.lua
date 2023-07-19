local ReplicatedFirst = game:GetService "ReplicatedFirst"

local enumsFolder = ReplicatedFirst.Shared.Enums

local HomeLockType = require(enumsFolder.HomeLockType)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData

type PlayerDataConfig = {
	persistentDataTemplate: PlayerPersistentData,
	tempDataTemplate: {},
	inventoryLimits: {
		accessories: number,
		furniture: number,
		homes: number,
	},
}

--[[
	Configuration for player data.
]]
local PlayerDataConfig: PlayerDataConfig = {
	persistentDataTemplate = {
		currency = {
			money = 0,
		},

		home = {
			server = {},
		},

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
	inventoryLimits = {
		accessories = 500,
		furniture = 500,
		homes = 200,
	},
}

return PlayerDataConfig
