local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local ItemCategory = require(enumsFolder.ItemCategory)
local HomeLockType = require(enumsFolder.HomeLockType)
local ReplicationType = require(enumsFolder.ReplicationType)

return { -- Constants for the game
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

	maxFurniturePlaced = 500, -- The max amount of furniture that can be placed in a home

	homePlaceId = 10564407502, -- The place ID of home
	routePlaceId = 10189729412, -- The place ID of the routing server
	profileTemplate = { -- Items in here can only be under a table. Add a _replication field to decide who can see it. If it's not there, it's not replicated
		currency = {
			_replication = ReplicationType.private,
			money = 0,
		},

		inventory = {
			_replication = ReplicationType.public,
			accessories = {},
			homeItems = {},
			homes = {},
		},

		playerInfo = { -- stuff that never changes
			homeServerInfo = {
				privateServerId = nil,
				serverCode = nil,
			},
			homeInfoStamped = false,
		},

		playerSettings = {
			_replication = ReplicationType.public,
			findOpenWorld = true,
			homeLock = HomeLockType.unlocked,
			selectedHome = nil,
		},
	},
	tempDataTemplate = {
		friendLocations = {
			_replication = ReplicationType.private,
			locations = {}
		}
	},
}
