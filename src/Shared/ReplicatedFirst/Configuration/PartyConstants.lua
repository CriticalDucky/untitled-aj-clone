local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"

local PartyTypeEnum = require(replicatedFirstShared:WaitForChild("Enums"):WaitForChild "PartyType")
local Time = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild "Time")

local timeRange = Time.newRange
local group = Time.newRangeGroup

--[[

[PartyTypeEnum.baseballParty] = {
    name = "Baseball Party",
    placeId = 11353468067,
    chanceWeight = 1,
    populationInfo = {
        max = 100,
        recommended = 50,
    },
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
},

]]

local parties = {
	-- [PartyTypeEnum.baseballParty] = {
	-- 	name = "Baseball Party",
	-- 	placeId = 11353468067,
	-- 	chanceWeight = 1,
	-- 	enabledTime = group(timeRange({
	-- 		year = 2020,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	}, {
	-- 		year = 2025,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	})),
	-- },

	[PartyTypeEnum.beachParty] = {
		name = "Beach Party",
		placeId = 11353468067,
		chanceWeight = 30,
		enabledTime = group(timeRange({
			year = 2020,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		}, {
			year = 2025,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		})),
		partyPellet = {
			image = "rbxassetid://1479990073",
			outlineColor = Color3.fromRGB(69, 51, 120),
			textColor = Color3.fromRGB(243, 222, 255),
		},
	},

	[PartyTypeEnum.birthdayParty] = {
		name = "Birthday Party",
		placeId = 11353468067,
		chanceWeight = 1,
		enabledTime = group(timeRange({
			year = 2020,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		}, {
			year = 2025,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		})),
		partyPellet = {
			image = "rbxassetid://5103374805",
			outlineColor = Color3.fromRGB(130, 65, 0),
			textColor = Color3.fromRGB(255, 178, 101),
		},
	},

	-- [PartyTypeEnum.campingParty] = {
	-- 	name = "Camping Party",
	-- 	placeId = 11353468067,
	-- 	chanceWeight = 1,
	-- 	enabledTime = group(timeRange({
	-- 		year = 2020,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	}, {
	-- 		year = 2025,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	})),
	-- },

	-- [PartyTypeEnum.catParty] = {
	-- 	name = "Cat Party",
	-- 	placeId = 11353468067,
	-- 	chanceWeight = 1,
	-- 	enabledTime = group(timeRange({
	-- 		year = 2020,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	}, {
	-- 		year = 2025,
	-- 		month = 1,
	-- 		day = 1,
	-- 		hour = 0,
	-- 		min = 0,
	-- 		sec = 0,
	-- 	})),
	-- },

	[PartyTypeEnum.circusParty] = {
		name = "Circus Party",
		placeId = 11353468067,
		chanceWeight = 1,
		enabledTime = group(timeRange({
			year = 2020,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		}, {
			year = 2025,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		})),
		partyPellet = {
			image = "rbxassetid://12534565817",
			outlineColor = Color3.fromRGB(72, 134, 172),
			textColor = Color3.fromRGB(213, 233, 255),
		},
	},
}

return parties
