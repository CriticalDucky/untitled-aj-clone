local PartyTypeEnum = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums"):WaitForChild("PartyType"))
local Time = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Time"))

local timeRange = Time.newRange
local group = Time.newGroup

--[[

[PartyTypeEnum.baseballParty] = {
    name = "Baseball Party",
    placeId = 11353468067,
    chanceWeight = 1,
    populationInfo = {
        max = 100,
        recommended = 50,
    },
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

]]

return {
    [PartyTypeEnum.baseballParty] = {
        name = "Baseball Party",
        placeId = 11353468067,
        chanceWeight = 1,
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
        chanceWeight = 30,
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
        chanceWeight = 1,
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
        chanceWeight = 1,
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
        chanceWeight = 1,
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
        chanceWeight = 1,
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
