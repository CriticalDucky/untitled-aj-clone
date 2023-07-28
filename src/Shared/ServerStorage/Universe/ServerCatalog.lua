--!strict

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

assert(not RunService:IsStudio(), "This module cannot be used in Studio.")

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local SafeTeleport = require(ServerStorage.Shared.Utility.SafeTeleport)
local Table = require(ReplicatedFirst.Shared.Utility.Table)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type WorldData = Types.WorldData

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"

local minigameCatalog = DataStoreService:GetDataStore "MinigameCatalog"
local partyCatalog = DataStoreService:GetDataStore "PartyCatalog"
local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--[[
    Provides getter functions for the server catalog.
]]
local ServerCatalog = {}

function ServerCatalog.getWorldAsync(world: number): WorldData?
    if typeof(world) ~= "number" or world ~= world or world ~= math.floor(world) or world < 1 then
        warn "The world must be a positive integer."
        return
    end

    local getWorldCountSuccess, worldCount = SafeDataStore.safeGetAsync(catalogInfo, "WorldCount")

    if not getWorldCountSuccess then
        warn "Failed to retrieve the world count."
        return
    end

    if world > worldCount then
        warn(("World %d does not exist."):format(world))
        return
    end

    local getLocationListSuccess, locationList = SafeDataStore.safeGetAsync(catalogInfo, "WorldLocationList")

    if not getLocationListSuccess then
        warn "Failed to retrieve the world location list."
        return
    end

    local getWorldDataSuccess, rawWorldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(world))

    if not getWorldDataSuccess then
        warn(("Failed to retrieve world data for world %d."):format(world))
        return
    end

    local worldData = {}

    for locationName in pairs(locationList) do
        worldData[locationName] = rawWorldData[locationName]
    end

    return worldData
end

function ServerCatalog.getWorldCountAsync(): number?
    local getWorldCountSuccess, worldCount = SafeDataStore.safeGetAsync(catalogInfo, "WorldCount")

    if not getWorldCountSuccess then
        warn "Failed to retrieve the world count."
        return
    end

    return worldCount or 0
end

return ServerCatalog