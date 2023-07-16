local ReplicatedStorage = game:GetService "ReplicatedStorage"

local enumsFolder = ReplicatedStorage.Shared.Enums

local HomeLockType = require(enumsFolder.HomeLockType)
local ItemCategory = require(enumsFolder.ItemCategory)

--[[
	Configuration for player data.
]]
local PlayerDataConfig = {
	-- The player's default persistent data.
	persistentDataTemplate = {
		-- The player's currencies.
		currency = {
			money = 0,
		},

		home = {
			selected = nil :: string?,
			
			server = {
				-- The ID of the player's home server.
				id = nil :: string?,

				-- The access code of the player's home server.
				accessCode = nil :: string?,
			}
		},

		-- The player's Items.
		inventory = {
			-- Items that can be worn by the player.
			accessories = {},

			-- Items that can be placed in the player's home.
			furniture = {},

			-- The player's homes.
			homes = {},
		},

		-- The player's settings.
		settings = {
			-- Whether or not the player wants to teleport to an open world if the desired location is full.
			findOpenWorld = true,

			-- Who can access the player's home.
			homeLock = HomeLockType.unlocked,

			-- The volume of the music.
			musicVolume = 1,

			-- The volume of the sound effects.
			sfxVolume = 1,
		},
	},

	-- The player's default temporary data.
	tempDataTemplate = {},

	-- The maximum number of items the player can own for each inventory category.
	inventoryLimits = {
		accessories = 500,
		furniture = 500,
		homes = 200,
	},

	-- TODO: Remove
	itemProps = { -- Custom additional properties for each item type, if needed
		[ItemCategory.home] = {
			placedItems = {}, -- The items that are placed in the home
		},
	},
}

export type PlayerData = typeof(PlayerDataConfig.persistentDataTemplate)

local a: PlayerData = {}

a.currency.money = 1

return PlayerDataConfig
