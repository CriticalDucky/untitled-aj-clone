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
            [partyEnum] = {
                [partyIndex] = {
                    privateServerId = privateServerId,
                    serverCode = serverCode,
                }
            }
        ]]
    },
    [GAMES_KEY] = {
        --[[
            [gameEnum] = {
                [gameIndex] = {
                    privateServerId = privateServerId,
                    serverCode = serverCode,
                }
            }
        ]]
    },
--[[
    [PrivateServerId] = {
        privateServerId = privateServerId,
        serverCode = serverCode,
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

local function retrieveDatastore(key)
    if isRetrieving[key] then
        repeat task.wait() until not isRetrieving[key]

        return
    end

    lastDatastoreRequest[key] = time()
    isRetrieving[key] = true

    local success, data = DataStore.safeGet(serverDataStore, key)

    isRetrieving[key] = false
    
    if success then
        cachedData[key] = data or {}

        if constantKeys[key] then
            replica:SetValue({key}, Table.copy(cachedData[key]))
        end
    end
end

local function newLocation(locationEnum)
    local locationInfo = Locations.info[locationEnum]

    local serverCode, privateServerId = TeleportService:ReserveServer(locationInfo.placeId)

    local locationTable = {
        serverCode = serverCode,
        privateServerId = privateServerId,
    }
    
    return locationTable
end

function ServerData.get(key)
    local data = cachedData[key]

    if not data or not Table.hasAnything(data) then
        retrieveDatastore(key)
    end

    return cachedData[key]
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

function ServerData.update(key, transformFunction, replicaFunction)
    local success = DataStore.safeUpdate(serverDataStore, key, transformFunction)

    local data = cachedData[key]

    if success then
        transformFunction(data)

        if constantKeys[key] and replicaFunction then
            replicaFunction()
        end
    end

    return success
end

function ServerData.addWorld()
    local world do
        world = {
            locations = {},
        }

        for enum, _ in pairs(Locations.info) do
            world.locations[enum] = newLocation(enum)
        end
    end

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
    ),
    #cachedData[WORLDS_KEY]
end

function ServerData.addParty(partyEnum)
    local party do
        local serverCode, privateServerId = TeleportService:ReserveServer(Parties[partyEnum].placeId)

        party = {
            serverCode = serverCode,
            privateServerId = privateServerId,
        }
    end

    return ServerData.update(
        PARTIES_KEY, 
        function(parties)
            parties = parties or {}

            parties[partyEnum] = parties[partyEnum] or {}

            table.insert(parties[partyEnum], party)

            return parties
        end,
        function()
            replica:ArrayInsert({PARTIES_KEY, partyEnum}, party)
        end
    ),
    #(cachedData[PARTIES_KEY][partyEnum] or {})
end

function ServerData.addGame(gameEnum)
    local newGame do
        local serverCode, privateServerId = TeleportService:ReserveServer(Games[gameEnum].placeId)

        newGame = {
            serverCode = serverCode,
            privateServerId = privateServerId,
        }
    end

    return ServerData.update(
        GAMES_KEY, 
        function(games)
            games = games or {}

            games[gameEnum] = games[gameEnum] or {}

            table.insert(games[gameEnum], newGame)

            return games
        end,
        function()
            replica:ArrayInsert({GAMES_KEY, gameEnum}, newGame)
        end
    ),
    #(cachedData[GAMES_KEY][gameEnum] or {})
end

function ServerData.stampHomeServer(owner: Player)
    local playerData = PlayerData.get(owner)

    if playerData then
        local homeServerInfo = playerData.profile.Data.playerInfo.homeServerInfo
        local privateServerId = homeServerInfo.privateServerId

        assert(privateServerId, "Player does not have a home server")

        local success = DataStore.safeSet(serverDataStore, privateServerId, {
            homeOwner = owner.UserId,
        })

        if success then
            cachedData[privateServerId] = {
                homeOwner = owner.UserId,
            }

            playerData:setValue({"playerInfo", "homeInfoStamped"}, true)

            return true
        end
    end
end

function ServerData.traceServer(privateServerId)
    privateServerId = privateServerId or game.PrivateServerId

    local serverInfo = cachedData[privateServerId]

    if not serverInfo or not Table.hasAnything(serverInfo) then
        retrieveDatastore(privateServerId)
    end

    return cachedData[privateServerId]
end

function ServerData.getServerInfo(key)
    if constantKeys[key] then
        local data = ServerData.get(key)

        local info

        if key == WORLDS_KEY then
            for i, world in ipairs(data) do
                for enum, location in pairs(world.locations) do
                    if location.privateServerId == game.PrivateServerId then
                        info = {
                            worldIndex = i,
                            locationEnum = enum,
                        }

                        break
                    end
                end

                if info then
                    break
                end
            end
        elseif key == PARTIES_KEY then
            for _, parties in pairs(data) do
                for i, party in ipairs(parties) do
                    if party.privateServerId == game.PrivateServerId then
                        info = {
                            partyIndex = i,
                        }

                        break
                    end
                end

                if info then
                    break
                end
            end
        elseif key == GAMES_KEY then
            for _, games in pairs(data) do
                for i, game in ipairs(games) do
                    if game.privateServerId == game.PrivateServerId then
                        info = {
                            gameIndex = i,
                        }

                        break
                    end
                end

                if info then
                    break
                end
            end
        end

        return info
    else
        return ServerData.traceServer(key)
    end
end

function ServerData.findAvailableLocation(worldIndex, locationsExcluded)
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

    return locationEnum
end

function ServerData.findAvailableWorld(forcedLocation, worldsExcluded)
    local worlds = ServerData.getWorlds()

    if worlds == nil then
        warn("No server data found")
        return
    end

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
    
                if not ServerData.findAvailableLocation(worldIndex) then
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

        local success, worldIndex = ServerData.addWorld()

        return success and worldIndex
    end

    return worldIndex
end

function ServerData.findAvailableParty(partyEnum)
    local parties = ServerData.getParties(partyEnum)

    if parties == nil then
        warn("No server data found")
        return
    end

    local partyIndex do
        local rarities = {}

        for partyIndex, party in ipairs(parties) do
            local partyPopulationInfo = LiveServerData.getPartyPopulationInfo(partyEnum, partyIndex)

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

        local success, partyIndex = ServerData.addParty(partyEnum)

        return success and partyIndex
    end

    return partyIndex
end

function ServerData.findAvailableWorldAndLocation(forcedLocation, worldsExcluded)
    local worlds = ServerData.getWorlds()

    if worlds == nil then
        warn("No server data found")
        return
    end

    local worldIndex = ServerData.findAvailableWorld(forcedLocation, worldsExcluded)
    local locationEnum = forcedLocation or ServerData.findAvailableLocation(worldIndex)

    print("Found world", worldIndex, "with location", locationEnum)

    if locationEnum == nil then
        print("No available location found, creating new world")
        
        local success, newWorldIndex = ServerData.addWorld()

        if success then
            worldIndex = newWorldIndex
            locationEnum = ServerData.findAvailableLocation(worldIndex)
        else -- Failed to create new world
            warn("Failed to create new world")
            return
        end
    end

    return worldIndex, locationEnum
end

function ServerData.reconcileWorlds() -- Never done in the live game
    local additions = {}
    local newLocations = {}

    for _ = 1, #ServerData.getWorlds() do
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


RunService.Heartbeat:Connect(function()
    for constantKey, _ in pairs(constantKeys) do
        if time() - lastDatastoreRequest[constantKey] > CACHE_COOLDOWN then
            retrieveDatastore(constantKey)
        end
    end
end)

return ServerData