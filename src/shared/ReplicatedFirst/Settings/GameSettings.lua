local ReplicatedStorage = game:GetService "ReplicatedStorage"

local enumsFolder = ReplicatedStorage.Shared.Enums

local ItemCategory = require(enumsFolder.ItemCategory)
local HomeLockType = require(enumsFolder.HomeLockType)
local ReplicationType = require(enumsFolder.ReplicationType)

local gameSettings = { -- Constants for the game
	location_maxPlayers = 20, -- The max amount of players that can be in a location at once
	location_maxRecommendedPlayers = 15, -- The recommended amount of players in a location at once
	world_maxRecommendedPlayers = 50, -- The recommended amount of players in a world at once
	party_maxPlayers = 20, -- The max amount of players that can be in a party at once
	party_maxRecommendedPlayers = 15, -- The recommended amount of players in a party at once
	home_maxNormalPlayers = 20, -- The max amount of normal players that can be in a home at once

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

	maxFurniturePlaced = 500, -- The max amount of furniture that can be placed in a home

	homePlaceId = 10564407502, -- The place ID of home
	routePlaceId = 10189729412, -- The place ID of the routing server
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
		},
	},
	tempDataTemplate = {
		friendLocations = {
			locations = {},
		},
	},
	dataKeyReplication = { -- Keys that have a private replicationType are replicated to the client, but not to other players. Public replicates to everyone. Absent keys are not replicated.
		currency = ReplicationType.private,
		inventory = ReplicationType.public,
		playerSettings = ReplicationType.public,
		friendLocations = ReplicationType.private,
	},
}

return gameSettings
