local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local ItemCategory = require(enumsFolder.ItemCategory)

return { -- Constants for the game
    location_maxPlayers = 20, -- The max amount of players that can be in a location at once
    location_maxRecommendedPlayers = 15, -- The recommended amount of players in a location at once
    world_maxRecommendedPlayers = 50, -- The recommended amount of players in a world at once
    party_maxPlayers = 20, -- The max amount of players that can be in a party at once
    party_maxRecommendedPlayers = 15, -- The recommended amount of players in a party at once
    home_maxNormalPlayers = 20, -- The max amount of normal players that can be in a home at once

    inventoryLimits = { -- The item limits for each inventory type
        [ItemCategory.furniture] = 1000,
        [ItemCategory.accessory] = 1000,
        [ItemCategory.home] = 200,
    },

    maxFurniturePlaced = 900, -- The max amount of furniture that can be placed in a home

    homePlaceId = 10564407502, -- The place ID of home
}