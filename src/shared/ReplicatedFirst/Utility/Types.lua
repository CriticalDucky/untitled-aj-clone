local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local Promise = require(utilityFolder:WaitForChild("Promise"))

local isServer = RunService:IsServer()

export type UserEnum = string | number

export type PlayerData = {
	setValue: (PlayerData, path: {}, value: any) -> nil,
	setValues: (PlayerData, path: {}, values: {}) -> nil,
	arrayInsert: (PlayerData, path: {}, value: any) -> nil,
	arraySet: (PlayerData, path: {}, index: number, value: any) -> nil,
	arrayRemove: (PlayerData, path: {}, index: number) -> nil,
	player: Player,
	profile: table,
}

export type TimeRange = {
	introduction: number | table,
	closing: number | table,
	isInRange: (TimeRange, time: number?) -> boolean,
	distanceToClosing: (TimeRange, time: number?) -> number,
	distanceToIntroduction: (TimeRange, time: number?) -> number,
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

export type PlayerParam = Player | number

export type HomeOwnerParam = PlayerParam | nil

export type LocalPlayerParam = PlayerParam | nil

export type Promise = typeof(Promise.new(function() end))

export type ServerIdentifier = {
	serverType: UserEnum,
	jobId: string?,
	worldIndex: number?,
	locationEnum: UserEnum?,
	homeOwner: number?,
	partyType: UserEnum?,
	partyIndex: number?,
	gameType: UserEnum?,
	gameIndex: number?,
}

return nil
