--!strict

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"

local Promise = require(replicatedFirstVendor:WaitForChild "Promise")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

export type ItemAccessory = {
	type: number,
}

export type ItemFurniture = {
	type: number,
}

type Use = Fusion.Use

export type ItemCategory = { InventoryItem }

export type UserEnum = string | number

export type Profile = {
	Data: PlayerPersistentData,
	Release: (Profile) -> (),
	AddUserId: (Profile, number) -> (),
	Reconcile: (Profile) -> (),
	ListenToRelease: (Profile, () -> ()) -> (),
}

export type DataTreeArray = { DataTreeValue? }

export type DataTreeDictionary = { [string]: DataTreeValue? }

export type DataTreeValue = number | string | boolean | nil | DataTreeArray | DataTreeDictionary

export type PlayerPersistentData = {
	currency: {
		money: number,
	},
	home: {
		selected: string?,
		server: ServerIdentifier?,
	},
	inventory: {
		accessories: { [string]: ItemAccessory? },
		furniture: { [string]: ItemFurniture? },
		homes: { [string]: ItemHome? },
	},
	settings: {
		findOpenWorld: boolean,
		homeLock: number,
		musicVolume: number,
		sfxVolume: number,
	},
}

export type PlayerPersistentDataPublic = {
	inventory: {
		accessories: { [string]: ItemAccessory? },
		furniture: { [string]: ItemFurniture? },
		homes: { [string]: ItemHome? },
	},
	settings: {
		homeLock: number,
	},
}

export type TimeRange = {
	introduction: number | { [any]: any },
	closing: number | { [any]: any },
	isInRange: (TimeRange, timeInfo: TimeInfo?, Use) -> boolean,
	distanceToClosing: (TimeRange, timeInfo: TimeInfo?, Use) -> number,
	distanceToIntroduction: (TimeRange, timeInfo: TimeInfo?, Use) -> number,
	isATimeRange: true,
}

export type TimeInfo = number | (
	Use?
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

export type ItemHome = {
	type: number,
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
	pivotCFrame: CFrame | { [any]: any },
}

export type Promise = typeof(Promise.new(function() end))

export type ServerDictionaryDataHome = {
	homeOwner: number,
}

-- export type ServerIdentifier = {
-- 	serverType: UserEnum,
-- 	jobId: string?,
-- 	worldIndex: number?,
-- 	locationEnum: UserEnum?,
-- 	homeOwner: number?,
-- 	partyType: UserEnum?,
-- 	partyIndex: number?,
-- 	minigameType: UserEnum?,
-- 	minigameIndex: number?,
-- 	privateServerId: string?,
-- }

export type ServerIdentifier = {
	accessCode: string,
	placeId: number,
	privateServerId: string,
}

export type UniverseServerCatalog = {
	worlds: { { [string]: ServerIdentifier } }, -- worlds -> worldIndex -> locationType -> ServerIdentifier
	parties: { [string]: { ServerIdentifier } }, -- parties -> partyType -> serverIndex -> ServerIdentifier
	minigames: { [string]: { ServerIdentifier } }, -- minigames -> minigameType -> serverIndex -> ServerIdentifier
}

export type WorldData = { [string]: ServerIdentifier }

return nil
