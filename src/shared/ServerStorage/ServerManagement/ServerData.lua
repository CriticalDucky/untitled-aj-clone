local SERVERS_DATASTORE = "Servers"
local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local GAMES_KEY = "games"
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
local serverFolder = replicatedStorageShared.Server
local utilityFolder = serverStorageShared.Utility
local replicatedFirstUtility = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local Games = require(serverFolder.Games)
local DataStore = require(utilityFolder.DataStore)
local LiveServerData = require(serverFolder.LiveServerData)
local Math = require(replicatedFirstUtility.Math)
local Table = require(replicatedFirstUtility.Table)
local Event = require(replicatedFirstUtility.Event)
local PlayerData = require(serverStorageShared.Data.PlayerData)
local ReplicaService = require(dataFolder.ReplicaService)
local Promise = require(replicatedFirstUtility.Promise)

local serverDataStore = DataStoreService:GetDataStore(SERVERS_DATASTORE)

local cachedData = {
    [WORLDS_KEY] = {
        --[[
            [worldIndex] = {
                locations = {
                    [locationEnum] = {
                        privateServerId = privateServerId,
                        serverCode = serverCode,
                    }
                }
            }
        ]]
    },
    [PARTIES_KEY] = {
        --[[
            [partyType] = {
                [partyIndex] = {
                    privateServerId = privateServerId,
                    serverCode = serverCode,
                }
            }
        ]]
    },
    [GAMES_KEY] = {
        --[[
            [gameType] = {
                [gameIndex] = {
                    privateServerId = privateServerId,
                    serverCode = serverCode,
                }
            }
        ]]
    },
--[[
    [PrivateServerId] = {
        [any] = any
    }
]]
}

local lastDatastoreRequest = {
    [WORLDS_KEY] = 0,
    [PARTIES_KEY] = 0,
    [GAMES_KEY] = 0,
}

local constantKeys = {
    [WORLDS_KEY] = true,
    [PARTIES_KEY] = true,
    [GAMES_KEY] = true,
}

local isRetrieving = {}

local ServerData = {}

ServerData.WORLDS_KEY = WORLDS_KEY
ServerData.PARTIES_KEY = PARTIES_KEY
ServerData.GAMES_KEY = GAMES_KEY

local replica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ServerData"),
    Data = Table.copy(cachedData),
    Replication = "All"
})

local function retrieveDatastore(key) -- WARNING: Yields; should only be called from a Promise
    if isRetrieving[key] then
        repeat task.wait() until not isRetrieving[key]

        return
    end

    lastDatastoreRequest[key] = time()
    isRetrieving[key] = true

    DataStore.safeGet(serverDataStore, key)
        :andThen(function(data)
            cachedData[key] = data or {}

            replica:SetValue({key}, Table.copy(cachedData[key]))
        end)
        :catch(function()
            warn("Failed to retrieve datastore for key: " .. key)
        end)
        :finally(function()
            isRetrieving[key] = false
        end)
end

local function newLocation(locationEnum)
    local function getLocationTable()
        return Promise.try(function()
            local locationInfo = Locations.info[locationEnum]

            local serverCode, privateServerId = TeleportService:ReserveServer(locationInfo.placeId)

            local locationTable = {
                serverCode = serverCode,
                privateServerId = privateServerId,
            }

            return locationTable
        end)
    end

    return Promise.retry(
        getLocationTable,
        5
    )
end

function ServerData.get(key)
    return Promise.new(function(resolve, reject)
        local data = cachedData[key]

        if not data then
            retrieveDatastore(key)
        end

        (if cachedData[key] then resolve else reject)(cachedData[key])
    end)
end

function ServerData.getWorlds()
    return ServerData.get(WORLDS_KEY)
end

function ServerData.getParties()
    return ServerData.get(PARTIES_KEY)
end

function ServerData.getGames()
    return ServerData.get(GAMES_KEY)
end

function ServerData.getWorld(worldIndex)
    return ServerData.getWorlds()
        :andThen(function(worlds)
            return worlds[worldIndex]
        end)
end

function ServerData.getParty(partyType, partyIndex)
    return ServerData.getParties()
        :andThen(function(parties)
            return parties[partyType][partyIndex]
        end)
end

function ServerData.getGame(gameType, gameIndex)
    return ServerData.getGames()
        :andThen(function(games)
            return games[gameType][gameIndex]
        end)
end

function ServerData.getLocation(worldIndex, locationEnum)
    return ServerData.getWorld(worldIndex)
        :andThen(function(world)
            return world.locations[locationEnum]
        end)
end

function ServerData.getAll()
    return Promise.all({
        ServerData.getWorlds(),
        ServerData.getParties(),
        ServerData.getGames(),
    })
        :andThen(function()
            return cachedData
        end)
end

function ServerData.update(key, transformFunction, replicaFunction)
    return DataStore.safeUpdate(serverDataStore, key, transformFunction)
        :andThen(function()
            transformFunction(cachedData[key])

            if constantKeys[key] and replicaFunction then
                replicaFunction()
            end
        end)
end

function ServerData.addWorld()
    return Promise.new(function(resolve, reject)
        local world = {
            locations = {},
        }

        local promiseTable = {}

        for enum, _ in pairs(Locations.info) do
            local location = newLocation(enum)

            table.insert(promiseTable, location)

            world.locations[enum] = location
        end

        Promise.all(promiseTable)
            :andThenCall(resolve, world)
            :catch(reject)
    end)
        :andThen(function(world)
            return ServerData.update(
                WORLDS_KEY,
                function(worlds)
                    worlds = worlds or {}

                    table.insert(worlds, world)

                    return worlds
                end,
                function()
                    replica:ArrayInsert({WORLDS_KEY}, world)
                end
            )
                :andThen(function()
                    return #cachedData[WORLDS_KEY]
                end)
        end)
end

function ServerData.addParty(partyType)
    return Promise.try(function()
        local serverCode, privateServerId = TeleportService:ReserveServer(Parties[partyType].placeId)

        return {
            serverCode = serverCode,
            privateServerId = privateServerId,
        }
    end)
        :andThen(function(party)
            return ServerData.update(
                PARTIES_KEY, 
                function(parties)
                    parties = parties or {}

                    parties[partyType] = parties[partyType] or {}

                    table.insert(parties[partyType], party)

                    return parties
                end,
                function()
                    replica:ArrayInsert({PARTIES_KEY, partyType}, party)
                end
            )
                :andThen(function()
                    return #(cachedData[PARTIES_KEY][partyType] or {})
                end)
        end)
end

function ServerData.addGame(gameType)
    return Promise.try(function()
        local serverCode, privateServerId = TeleportService:ReserveServer(Games[gameType].placeId)

        return {
            serverCode = serverCode,
            privateServerId = privateServerId,
        }
    end)
        :andThen(function(newGame)
            return ServerData.update(
                GAMES_KEY, 
                function(games)
                    games = games or {}

                    games[gameType] = games[gameType] or {}

                    table.insert(games[gameType], newGame)

                    return games
                end,
                function()
                    replica:ArrayInsert({GAMES_KEY, gameType}, newGame)
                end
            )
                :andThen(function()
                    return #(cachedData[GAMES_KEY][gameType] or {})
                end)
        end)
end

function ServerData.stampHomeServer(owner: Player)
    return Promise.new(function(resolve, reject)
        local playerData = PlayerData.get(owner)

        if playerData then
            local homeServerInfo = playerData.profile.Data.playerInfo.homeServerInfo
            local privateServerId = homeServerInfo.privateServerId

            assert(privateServerId, "Player does not have a home server")

            DataStore.safeSet(serverDataStore, privateServerId, {
                homeOwner = owner.UserId,
            })
                :andThen(function()
                    cachedData[privateServerId] = {
                        homeOwner = owner.UserId,
                    }

                    playerData:setValue({"playerInfo", "homeInfoStamped"}, true)

                    resolve()
                end)
                :catch(reject)
        end
    end)
end

---@IMPORTANT: Make sure you remove support for traceServer and getServerInfo

function ServerData.traceServerInfo(privateServerId: string | nil)
    privateServerId = privateServerId or game.PrivateServerId

    return Promise.resolve()
        :andThen(function()
            return ServerData.getAll() -- make sure data was loaded at some point
        end)
        :andThen(function()
            local info

            Table.recursiveIterate(cachedData, function(path, value)
                if type(value) == "table" and value.privateServerId == privateServerId then
                    local constantKey = path[1]
        
                    if constantKey == WORLDS_KEY then -- the path is [WORLDS_KEY, worldIndex, "locations", locationEnum]
                        info = {
                            worldIndex = path[2],
                            locationEnum = path[4],
                        }
                    elseif constantKey == PARTIES_KEY then -- the path is [PARTIES_KEY, partyType, partyIndex]
                        info = {
                            partyType = path[2],
                            partyIndex = path[3],
                        }
                    elseif constantKey == GAMES_KEY then -- the path is [GAMES_KEY, gameType, gameIndex]
                        info = {
                            gameType = path[2],
                            gameIndex = path[3],
                        }
                    end
                end
            end)

            return info
        end)
        :andThen(function(info)
            if info then
                return info
            else
                return ServerData.get(privateServerId)
            end
        end)
end

function ServerData.findAvailableLocation(worldIndex, locationsExcluded)
    return Promise.new(function(resolve, reject)
        assert(worldIndex, "No world index provided")

        local locationEnum
        local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

        for _, locationType in pairs(Locations.priority) do
            if locationsExcluded and table.find(locationsExcluded, locationType) then
                continue
            end

            if worldPopulationInfo then
                local populationInfo = worldPopulationInfo.locations[locationType]

                if populationInfo then
                    if populationInfo.recommended_emptySlots ~= 0 then
                        locationEnum = locationType
                        break
                    end
                else -- No server info, so location is available
                    locationEnum = locationType
                    break
                end
            else -- No server info, so location is available
                locationEnum = locationType
                break
            end
        end

        if locationEnum then
            resolve(locationEnum)
        else
            reject()
        end
    end)
end

function ServerData.findAvailableWorld(forcedLocation, worldsExcluded)
    return ServerData.getWorlds()
        :andThen(function(worlds)
            local worldIndex do
                local rarities = {}

                for worldIndex, world in ipairs(worlds) do
                    local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

                    local worldIsSuitable = true

                    if worldsExcluded and table.find(worldsExcluded, worldIndex) then
                        worldIsSuitable = false
                    end

                    if worldIsSuitable and worldPopulationInfo then
                        for locationEnum, _ in pairs(world.locations) do
                            local locationPopulationInfo = worldPopulationInfo.locations[locationEnum]

                            if locationPopulationInfo and (forcedLocation == locationEnum) and (locationPopulationInfo.max_emptySlots == 0) then
                                worldIsSuitable = false
                                break
                            end
                        end

                        local success = ServerData.findAvailableLocation(worldIndex):await()

                        if not success then
                            worldIsSuitable = false
                        end

                        if worldPopulationInfo.recommended_emptySlots == 0 then
                            worldIsSuitable = false
                        end
                    end

                    if not worldIsSuitable then
                        print("ServerData.findAvailableWorld: World " .. worldIndex .. " is not suitable")
                        continue
                    end

                    local population = worldPopulationInfo and worldPopulationInfo.population or 0

                    local chance do
                        if population == 0 then
                            chance = 0.001
                        else
                            chance = population
                        end
                    end

                    print("ServerData.findAvailableWorld: World " .. worldIndex .. " has a chance of " .. chance)

                    rarities[worldIndex] = chance
                end

                worldIndex = Math.weightedChance(rarities)
            end

            if worldIndex == nil then
                print("No suitable world found, creating new world")

                return ServerData.addWorld()
            end

            return worldIndex
        end)
end

function ServerData.findAvailableParty(partyType)
    return ServerData.getParties()
        :andThen(function(parties)
            local partyIndex do
                local rarities = {}
        
                for partyIndex, _ in ipairs(parties) do
                    local partyPopulationInfo = LiveServerData.getPartyPopulationInfo(partyType, partyIndex)
        
                    local partyIsSuitable = true
        
                    if partyPopulationInfo then
                        if partyPopulationInfo.recommended_emptySlots == 0 then
                            partyIsSuitable = false
                        end
                    end
        
                    if not partyIsSuitable then
                        print("ServerData.findAvailableParty: Party " .. partyIndex .. " is not suitable")
                        continue
                    end
        
                    local population = partyPopulationInfo and partyPopulationInfo.population or 0
        
                    local chance do
                        if population == 0 then
                            chance = 0.001
                        else
                            chance = population
                        end
                    end
        
                    print("ServerData.findAvailableParty: Party " .. partyIndex .. " has a chance of " .. chance)
        
                    rarities[partyIndex] = chance
                end
        
                partyIndex = Math.weightedChance(rarities)
            end
        
            if partyIndex == nil then
                print("No suitable party found, creating new party")
        
                return ServerData.addParty(partyType)
            end
        end)
end

function ServerData.findAvailableWorldAndLocation(forcedLocation, worldsExcluded)
    return ServerData.findAvailableWorld(forcedLocation, worldsExcluded)
        :andThen(function(worldIndex)
            return Promise.new(function(resolve, reject)
                if forcedLocation then
                    resolve(forcedLocation)
                else
                    ServerData.findAvailableLocation(worldIndex)
                        :andThen(resolve)
                        :catch(reject)
                end
            end)
            :andThen(function(locationEnum)
                return worldIndex, locationEnum
            end)
            :catch(function()
                print("No available location found, creating new world")

                return ServerData.addWorld()
                    :andThen(function(newWorldIndex)
                        return ServerData.findAvailableLocation(newWorldIndex)
                            :andThen(function(newLocationEnum)
                                return newWorldIndex, newLocationEnum
                            end)
                    end)
            end)
        end)
        :tap(function(worldIndex, locationEnum)
            if not worldIndex or not locationEnum then
                warn("ServerData.findAvailableWorldAndLocation: worldIndex or locationEnum is nil.")
            else
                print("ServerData.findAvailableWorldAndLocation: Found world " .. worldIndex .. " and location " .. locationEnum)
            end
        end)
end

function ServerData.reconcileWorlds() -- Never done in the live game
    local additions = {}
    local newLocations = {}

    local _, worlds = ServerData.getWorlds():await()

    for _ = 1, #worlds do
        for locationEnum, _ in pairs(Locations.info) do
            local locationTable =  newLocations[locationEnum] or {}
            newLocations[locationEnum] = locationTable

            table.insert(locationTable, newLocation(locationEnum))
        end
    end

    local function getNewLocation(locationEnum)
        local locationTable = newLocations[locationEnum]

        local newLocation = table.remove(locationTable, 1)

        return newLocation
    end

    ServerData.update(
        WORLDS_KEY,
        function(worlds)
            for worldIndex, world in ipairs(worlds) do
                local locations = world.locations
        
                for locationEnum, _ in pairs(Locations.info) do
                    if not locations[locationEnum] then
                        local location = getNewLocation(locationEnum)
                        locations[locationEnum] = location
                        table.insert(additions, {
                            worldIndex = worldIndex,
                            locationEnum = locationEnum,
                            location = location,
                        })
                    end
                end
            end

            return worlds
        end,
        function()
            for _, addition in pairs(additions) do
                replica:SetValue(
                    {
                        WORLDS_KEY,
                        addition.worldIndex,
                        "locations",
                        addition.locationEnum,
                    },
                    addition.location
                )
            end
        end
    )
end

ServerData.getAll()
    :catch(function(err)
        warn("Startup loading failed:", tostring(err))
    end)
    :finally(function()
        RunService.Heartbeat:Connect(function()
            for constantKey, _ in pairs(constantKeys) do
                if time() - lastDatastoreRequest[constantKey] > CACHE_COOLDOWN then
                    retrieveDatastore(constantKey)
                end
            end
        end)
    end)

return ServerData