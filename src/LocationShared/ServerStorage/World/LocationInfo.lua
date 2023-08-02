--!strict

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"
local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

local placeId = game.PlaceId
local privateServerId = game.PrivateServerId

--#region Location

local getLocationListSuccess, locationList: Types.CatalogWorldLocationList? =
	SafeDataStore.safeGetAsync(catalogInfo, "WorldLocationList")

if not getLocationListSuccess or not locationList then
	-- TODO: Soft kick players.
end

assert(getLocationListSuccess and locationList)

local location

for locationName, locationData in pairs(locationList) do
	if placeId ~= locationData.placeId then continue end

	location = locationName
	break
end

if not location then
	-- TODO: Soft kick players.
end

--#endregion

--#region World

local getServerInfoSuccess, serverInfo: Types.ServerInfoLocation? =
	SafeDataStore.safeGetAsync(serverDictionary, privateServerId)

if not getServerInfoSuccess or not serverInfo then
	-- TODO: Soft kick players.
end

assert(getServerInfoSuccess and serverInfo)

local world = serverInfo.world

--#endregion

local LocationInfo = {
	world = world,
	location = location,
}

return LocationInfo
