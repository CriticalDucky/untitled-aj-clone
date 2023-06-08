local enumsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild "Enums"
local replicatedStorageShared = game:GetService("ReplicatedStorage"):WaitForChild "Shared"
local utiltiyFolder = replicatedStorageShared:WaitForChild "Utility"

local MinigameTypeEnum = require(enumsFolder:WaitForChild "MinigameType")
local MinigameServerType = require(enumsFolder:WaitForChild "MinigameServerType")
local Time = require(utiltiyFolder:WaitForChild "Time")
local Types = require(utiltiyFolder:WaitForChild "Types")

type TimeRange = Types.TimeRange

local timeRange = Time.newRange
local group = Time.newRangeGroup

export type minigameEntry = {
	name: string,
	placeId: number,
	minigameServerType: string,
	isBrowsable: boolean?, -- If not specified, minigame will not appear in the minigame menu
	enabledTime: TimeRange?,
	layoutOrder: number?, -- What order the minigame appears in the minigame menu
	minigameIcon: {
		image: string,
		color: Color3,
	},
	populationInfo: {
		max: number,
		recommended: number,
	}?,
}

return {
	[MinigameTypeEnum.fishing] = {
		name = "Fishing",
		placeId = 11569189394,
		minigameServerType = MinigameServerType.instance,
		isBrowsable = true,
		minigameIcon = {
			image = "rbxassetid://2692649113",
			color = Color3.fromRGB(0, 159, 167),
		}
	},

	[MinigameTypeEnum.gatherer] = {
		name = "Gatherer",
		placeId = 12939855185,
		minigameServerType = MinigameServerType.public,
		isBrowsable = true,
		minigameIcon = {
			image = "rbxassetid://1014006459",
			color = Color3.fromRGB(54, 85, 66),
		}
	}
} :: {[string]: minigameEntry}
