local enumsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild "Enums"
local replicatedStorageShared = game:GetService("ReplicatedStorage"):WaitForChild "Shared"

local MinigameTypeEnum = require(enumsFolder:WaitForChild "MinigameType")
local MinigameServerType = require(enumsFolder:WaitForChild "MinigameServerType")
local Time = require(replicatedStorageShared:WaitForChild("Utility"):WaitForChild "Time")

local timeRange = Time.newRange
local group = Time.newRangeGroup

--[[ Example minigame entry

	[MinigameTypeEnum.example] = {
		name = "Example", -- Name of the minigame
		placeId = 123456789, -- PlaceId of the minigame
		serverType = MinigameServerType.public, -- Type of server the minigame is on
		populationInfo = { -- Information about the population of the minigame. Can be nil if the minigame is not public.
			max = 100,
			recommended = 50,
		},
		isBrowsable = true, -- Whether the minigame is browsable in the minigame list
		enabledTime = group (
			timeRange(
				{
					year = 2020,
					month = 1,
					day = 1,
					hour = 0,
					min = 0,
					sec = 0
				},

				{
					year = 2025,
					month = 1,
					day = 1,
					hour = 0,
					min = 0,
					sec = 0
				}
			)
		)
	}

]]

return {
	[MinigameTypeEnum.fishing] = {
		name = "Fishing",
		placeId = 11569189394,
		minigameServerType = MinigameServerType.instance,
		isBrowsable = true,
	},

	[MinigameTypeEnum.gatherer] = {
		name = "Gatherer",
		placeId = 12939855185,
		minigameServerType = MinigameServerType.public,
		isBrowsable = true,
	}
}
