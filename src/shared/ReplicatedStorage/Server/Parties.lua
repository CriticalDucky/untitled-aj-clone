local PartyTypeEnum = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums"):WaitForChild("PartyType"))
local TimeRange = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("TimeRange"))

local timeRange = TimeRange.new
local group = TimeRange.newGroup

return {
    [PartyTypeEnum.baseballParty] = {
        name = "Baseball Party",
        placeId = 11353468067,
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
    },

    [PartyTypeEnum.beachParty] = {
        name = "Beach Party",
        placeId = 11353468067,
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
    },

    [PartyTypeEnum.birthdayParty] = {
        name = "Birthday Party",
        placeId = 11353468067,
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
    },

    [PartyTypeEnum.campingParty] = {
        name = "Camping Party",
        placeId = 11353468067,
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
    },

    [PartyTypeEnum.catParty] = {
        name = "Cat Party",
        placeId = 11353468067,
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
    },

    [PartyTypeEnum.circusParty] = {
        name = "Circus Party",
        placeId = 11353468067,
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
    },
}
