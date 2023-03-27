local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local settingsFolder = replicatedFirstShared:WaitForChild("Settings")

local Promise = require(utilityFolder:WaitForChild("Promise"))
local GameSettings = require(settingsFolder:WaitForChild("GameSettings"))
local Table = require(utilityFolder:WaitForChild("Table"))

local profileTemplate = GameSettings.profileTemplate
local tempDataTemplate = GameSettings.tempDataTemplate

export type ProfileData = typeof(profileTemplate) & typeof(tempDataTemplate)
export type Inventory = typeof(profileTemplate.inventory)
export type InventoryCategory = { InventoryItem }

export type UserEnum = string | number

export type Profile = {
	Data: ProfileData,
}

export type PlayerData = {
	setValue: (PlayerData, path: {}, value: any) -> nil,
	setValues: (PlayerData, path: {}, values: {}) -> nil,
	arrayInsert: (PlayerData, path: {}, value: any) -> nil,
	arraySet: (PlayerData, path: {}, index: number, value: any) -> nil,
	arrayRemove: (PlayerData, path: {}, index: number) -> nil,
	player: Player,
	profile: Profile,
}

export type TimeRange = {
	introduction: number | table,
	closing: number | table,
	isInRange: (TimeRange, time: number?) -> boolean,
	distanceToClosing: (TimeRange, time: number?) -> number,
	distanceToIntroduction: (TimeRange, time: number?) -> number,
	isATimeRange: true,
}

export type TimeInfo = number | (
) -> TimeInfo | {
	year: number?,
	month: number?,
	day: number?,
	hour: number?,
	min: number?,
	sec: number?,
}

export type PartyUnit = {
	partyType: UserEnum,
	halfHourId: number,
	time: TimeRange,
}

export type HomeServerInfo = {
	serverCode: string,
	privateServerId: string,
}

export type InventoryItem = {
	id: string,
	itemCategory: UserEnum,
	itemEnum: string | number,
	placedItems: {}?,
	permanent: boolean?,
}

export type PlacedItem = {
	itemId: string,
	pivotCFrame: CFrame | table,
}

export type Promise = typeof(Promise.new(function() end))

export type ServerIdentifier = {
	serverType: UserEnum,
	jobId: string?,
	worldIndex: number?,
	locationEnum: UserEnum?,
	homeOwner: number?,
	partyType: UserEnum?,
	partyIndex: number?,
	minigameType: UserEnum?,
	minigameIndex: number?,
}

return nil
