--!strict

--#region Imports

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local PlaceIDs = require(ServerStorage.Shared.Configuration.PlaceIDs)
local ServerDirectives = require(ServerStorage.Shared.Utility.ServerDirectives)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ServerInfoHome = Types.ServerInfoHome
type ServerInfoLocation = Types.ServerInfoLocation

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

local placeId = game.PlaceId
local privateServerId = game.PrivateServerId

--#endregion

type HomeServerInfo = {
	type: "home",
	homeOwner: number,
}

type LocationServerInfo = {
	type: "location",
	location: string,
	world: number,
}

type MinigameServerInfo = {
	type: "minigame",
	minigame: string,
}

type PartyServerInfo = {
	type: "party",
	party: string,
}

type RoutingServerInfo = {
	type: "routing",
}

type ServerInfo = HomeServerInfo | LocationServerInfo | MinigameServerInfo | PartyServerInfo | RoutingServerInfo

local function getPlaceIdInformation(placeId: number): (string, string?)
	if placeId == PlaceIDs.home then return "home" end

	for placeType, id in pairs(PlaceIDs.location) do
		if id == placeId then return "location", placeType end
	end

	for placeType, id in pairs(PlaceIDs.minigame) do
		if id == placeId then return "minigame", placeType end
	end

	for placeType, id in pairs(PlaceIDs.party) do
		if id == placeId then return "party", placeType end
	end

	if placeId == PlaceIDs.routing then return "routing" end

	return "unknown"
end

local placeType, placeSubtype = getPlaceIdInformation(placeId)

--#region Server Info

local ServerInfo = {}

ServerInfo.type = placeType

if placeType == "home" then
	-- Home Owner

	local getSuccess, serverInfo: ServerInfoHome = DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

	if not getSuccess or not serverInfo then
		ServerDirectives.shutDownServer "The server failed to retrieve home information."
	end

	ServerInfo.homeOwner = serverInfo.homeOwner
elseif placeType == "location" then
	-- Location Type

	ServerInfo.location = placeSubtype

	-- World ID

	local getSuccess, serverInfo: ServerInfoLocation = DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

	if not getSuccess or not serverInfo then
		ServerDirectives.shutDownServer "The server failed to retrieve location information."
	end

	ServerInfo.world = serverInfo.world
elseif placeType == "minigame" then
	-- Minigame Type

	ServerInfo.minigame = placeSubtype
elseif placeType == "party" then
	-- Party Type

	ServerInfo.party = placeSubtype
else
	ServerDirectives.shutDownServer "The server could not identify itself."
end

--#endregion

return (ServerInfo :: any) :: ServerInfo
