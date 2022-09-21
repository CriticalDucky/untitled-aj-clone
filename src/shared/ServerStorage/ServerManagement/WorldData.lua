local WORLDS_KEY = "worlds"
local CACHE_COOLDOWN = 30

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverStorageShared = ServerStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local utilityFolder = serverStorageShared.Utility
local replicatedFirstUtility = replicatedFirstShared.Utility

local Locations = require(serverManagement.Locations)
local DataStore = require(utilityFolder.DataStore)
local GameServerData = require(serverManagement.GameServerData)
local Math = require(replicatedFirstUtility.Math)
local Table = require(replicatedFirstUtility.Table)
local Constants = require(replicatedStorageShared.Server.Constants)
local Event = require(replicatedFirstUtility.Event)

local worldsDataStore = DataStoreService:GetDataStore("Worlds")
local cachedWorlds = {}
local lastDatastoreRequest = 0

local WorldData = {}

WorldData.WorldsUpdated = Event.new()

local function retrieveDatastore()
    lastDatastoreRequest = time()
    local lastCachedWorlds = cachedWorlds
    
    for i, v in ipairs(DataStore.safeGet(worldsDataStore, WORLDS_KEY) or {}) do
        cachedWorlds[i] = v
    end

    if #cachedWorlds ~= #lastCachedWorlds then
        WorldData.WorldsUpdated:Fire(cachedWorlds)
    end
end

function WorldData.get(getUpdated)
    if getUpdated or #cachedWorlds == 0 then
        retrieveDatastore()

        Table.print(cachedWorlds, "WorldData.get")
    end

    return cachedWorlds
end

function WorldData.update(transformFunction)
    local success = DataStore.safeUpdate(worldsDataStore, WORLDS_KEY, transformFunction)

    if success then
        transformFunction(cachedWorlds)
        WorldData.WorldsUpdated:Fire(cachedWorlds)
    end

    Table.print(cachedWorlds, "WorldData.update")

    return success
end

function WorldData.addWorld()
    local world do
        world = {
            locations = {},
        }

        for enum, location in pairs(Locations.info) do
            local serverCode, privateServerId = TeleportService:ReserveServer(location.placeId)

            local locationTable = {
                serverCode = serverCode,
                privateServerId = privateServerId,
            }

            world.locations[enum] = locationTable
        end
    end

    return WorldData.update(function(worlds)
        table.insert(worlds, world)

        return worlds
    end), #cachedWorlds
end

function WorldData.findAvailable(forcedLocation)
    local worlds = WorldData.get()

    if worlds == nil then
        warn("No server data found")
        return
    end

    local function newWorldAndLocation()
        local success, world = WorldData.addWorld()

        if success then
            return world, Locations.priority[1]
        end
    end

    local worldIndex do
        local rarities = {}

        for worldIndex, world in ipairs(worlds) do
            local population = 0
            local worldIsSuitable = true

            for locationEnum, _ in pairs(world.locations) do
                local serverInfo = GameServerData.getLocation(worldIndex, locationEnum)

                if serverInfo then
                    local locationPopulation = #serverInfo.players

                    if (forcedLocation == locationEnum) and (locationPopulation >= Constants.location_maxPlayers) then
                        worldIsSuitable = false
                        break
                    end

                    population += locationPopulation
                end
            end

            if population >= Constants.world_maxRecommendedPlayers or population >= (Table.dictLen(world.locations) * Constants.location_maxRecommendedPlayers) then
                worldIsSuitable = false
            end

            if not worldIsSuitable then
                print("WorldData.findAvailable: World " .. worldIndex .. " is not suitable")
                continue
            end

            local chance do
                if population == 0 then
                    chance = 0.001
                else
                    chance = population
                end
            end

            print("WorldData.findAvailable: World " .. worldIndex .. " has a chance of " .. chance)

            rarities[worldIndex] = chance
        end

        worldIndex = Math.weightedChance(rarities)
    end

    if worldIndex == nil then
        print("No suitable world found, creating new world")
        return newWorldAndLocation()
    end

    local locationEnum do
        if not forcedLocation then
            for _, locationType in pairs(Locations.priority) do
                local serverInfo = GameServerData.getLocation(worldIndex, locationType)

                if serverInfo then
                    local locationPopulation = #serverInfo.players

                    if locationPopulation < Constants.location_maxRecommendedPlayers then
                        locationEnum = locationType
                        break
                    end
                else -- No server info, so location is available
                    locationEnum = locationType
                    break
                end
            end
        else
            locationEnum = forcedLocation
        end
    end

    print("Found world", worldIndex, "with location", locationEnum)

    if locationEnum == nil then
        print("No location found, creating new world")
        return newWorldAndLocation()
    end

    return worldIndex, locationEnum
end

RunService.Heartbeat:Connect(function()
    if time() - lastDatastoreRequest > CACHE_COOLDOWN then
        retrieveDatastore()
    end
end)

return WorldData