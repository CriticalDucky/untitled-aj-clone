local ReplicatedStorage = game:GetService "ReplicatedStorage"

local enumsFolder = ReplicatedStorage.Shared.Enums

local HomeLockType = require(enumsFolder.HomeLockType)
local ReplicationType = require(enumsFolder.ReplicationType)
local ItemCategory = require(enumsFolder.ItemCategory)

local playerDataConstants = {
	profileTemplate = { -- Items in here can only be under a table. Add a _replication field to decide who can see it. If it's not there, it's not replicated
		currency = {
			money = 0,
		},

		inventory = {
			accessories = {},
			homeItems = {},
			homes = {},
		},

		playerInfo = { -- stuff that never changes
			homeServerInfo = {
				privateServerId = nil :: string,
				serverCode = nil :: string,
			},
			homeInfoStamped = false,
		},

		playerSettings = { -- Settings that can be changed by the player.
			-- NOTE: If you add something here, make sure to add a verification method in src\Shared\ServerScriptService\RequestManagement\Settings\SetSettingRequestManager.server.lua
			findOpenWorld = true, -- Whether or not the player wants to teleport to an open world if the desired location is full
			homeLock = HomeLockType.unlocked, -- Who can access the player's home
			selectedHome = nil, -- The home the player has selected
			musicVolume = 1, -- The volume of the music
			sfxVolume = 1, -- The volume of the sound effects
		},
	},
	tempDataTemplate = {
		-- The location of the player's friends
		friendLocations = {},
	},
	dataKeyReplication = { -- Keys that have a private replicationType are replicated to the client, but not to other players. Public replicates to everyone. Absent keys are not replicated.
		currency = ReplicationType.private,
		inventory = ReplicationType.public,
		playerSettings = ReplicationType.public,
		friendLocations = ReplicationType.private,
	},
	inventoryLimits = { -- The item limits for each inventory type
		[ItemCategory.furniture] = 500,
		[ItemCategory.accessory] = 500,
		[ItemCategory.home] = 200,
	},

	-- If you add something here, make sure to add it to the InventoryItem type in src\Shared\ReplicatedFirst\Utility\Types.lua
	itemProps = { -- Custom additional properties for each item type, if needed
		[ItemCategory.home] = {
			placedItems = {}, -- The items that are placed in the home
		},
	},
}

return playerDataConstants
