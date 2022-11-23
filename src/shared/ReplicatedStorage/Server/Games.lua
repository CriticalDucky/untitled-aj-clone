local enumsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums")
local replicatedFirstShared = game:GetService("ReplicatedFirst"):WaitForChild("Shared")

local GameTypeEnum = require(enumsFolder:WaitForChild("GameType"))
local GameJoinType = require(enumsFolder:WaitForChild("GameJoinType"))
local TimeRange = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("TimeRange"))

local timeRange = TimeRange.new
local group = TimeRange.newGroup

--[[ Example game entry

    [GameTypeEnum.example] = {
        name = "Example",
        placeId = 123456789,
        gameJoinType = GameJoinType.initial,
        maxPlayers = 10,
        enabledTime = group {
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
        }
    }

]]

return {
    [GameTypeEnum.fishing] = {
        name = "Fishing",
        placeId = 11569189394,
        gameJoinType = GameJoinType.initial,
    }
}