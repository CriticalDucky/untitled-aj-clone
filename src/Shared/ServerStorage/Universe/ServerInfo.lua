--!strict

--#region Imports

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local PlaceIDs = require(ServerStorage.Shared.Configuration.PlaceIDs)
local ServerDirectives = require(ServerStorage.Shared.Utility.ServerDirectives)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type LocationType = Types.LocationType
type MinigameType = Types.MinigameType
type PartyType = Types.PartyType
type ServerInfoHome = Types.ServerInfoHome
type ServerInfoLocation = Types.ServerInfoLocation

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

local placeId = game.PlaceId
local privateServerId = game.PrivateServerId

--#endregion

type HomePlaceInfo = {
	type: "home",
}

type HomeServerInfo = HomePlaceInfo & {
	homeOwner: number,
}

type LocationPlaceInfo = {
	type: "location",
	location: LocationType,
}

type LocationServerInfo = LocationPlaceInfo & {
	world: number,
}

type MinigamePlaceInfo = {
	type: "minigame",
	minigame: MinigameType,
}

type MinigameServerInfo = MinigamePlaceInfo

type PartyPlaceInfo = {
	type: "party",
	party: PartyType,
}

type PartyServerInfo = PartyPlaceInfo

type RoutingPlaceInfo = {
	type: "routing",
}

type RoutingServerInfo = RoutingPlaceInfo

type PlaceInfo = HomePlaceInfo | LocationPlaceInfo | MinigamePlaceInfo | PartyPlaceInfo | RoutingPlaceInfo

type ServerInfo = HomeServerInfo | LocationServerInfo | MinigameServerInfo | PartyServerInfo | RoutingServerInfo

local PLACE_ID_INFORMATION: { PlaceInfo } = {
	[PlaceIDs.home] = {
		type = "home",
	},
	[PlaceIDs.location.forest] = {
		type = "location",
		location = "forest",
	},
	[PlaceIDs.location.town] = {
		type = "location",
		location = "town",
	},
	[PlaceIDs.minigame.fishing] = {
		type = "minigame",
		minigame = "fishing",
	},
	[PlaceIDs.minigame.gatherer] = {
		type = "minigame",
		minigame = "gatherer",
	},
	[PlaceIDs.party.beach] = {
		type = "party",
		party = "beach",
	},
	[PlaceIDs.routing] = {
		type = "routing",
	},
}

--#region Server Info

local placeIdInformation = PLACE_ID_INFORMATION[placeId]

if not placeIdInformation then ServerDirectives.shutDownServer "The server could not identify itself." end

local ServerInfo = {}

ServerInfo.type = placeIdInformation.type

if placeIdInformation.type == "home" then
	-- Home Owner

	local getSuccess, serverInfo: ServerInfoHome = DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

	if not getSuccess or not serverInfo then
		ServerDirectives.shutDownServer "The server failed to retrieve home information."
	end

	ServerInfo.homeOwner = serverInfo.homeOwner
elseif placeIdInformation.type == "location" then
	-- Location Type

	ServerInfo.location = placeIdInformation.location

	-- World ID

	local getSuccess, serverInfo: ServerInfoLocation = DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

	if not getSuccess or not serverInfo then
		ServerDirectives.shutDownServer "The server failed to retrieve location information."
	end

	ServerInfo.world = serverInfo.world
elseif placeIdInformation.type == "minigame" then
	-- Minigame Type

	ServerInfo.minigame = placeIdInformation.minigame
elseif placeIdInformation.type == "party" then
	-- Party Type

	ServerInfo.party = placeIdInformation.party
end

--#endregion

return (ServerInfo :: any) :: ServerInfo
