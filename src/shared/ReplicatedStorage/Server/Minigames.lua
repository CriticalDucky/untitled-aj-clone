local enumsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild "Enums"
local replicatedFirstShared = game:GetService("ReplicatedFirst"):WaitForChild "Shared"

local MinigameTypeEnum = require(enumsFolder:WaitForChild "MinigameType")
local MinigameJoinType = require(enumsFolder:WaitForChild "MinigameJoinType")
local Time = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild "Time")

local timeRange = Time.newRange
local group = Time.newRangeGroup

--[[ Example minigame entry

    [MinigameTypeEnum.example] = {
        name = "Example",
        placeId = 123456789,
        minigameJoinType = MinigameJoinType.initial,
        maxPlayers = 10,
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
		minigameJoinType = MinigameJoinType.initial,
	},
}
