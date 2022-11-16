local BROADCAST_CHANNEL = "Servers"

local BROADCAST_COOLDOWN = 10
local BROADCAST_COOLDOWN_PADDING = 2
local WAIT_TIME = BROADCAST_COOLDOWN + BROADCAST_COOLDOWN_PADDING

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local messagingFolder = serverStorageShared.Messaging
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility

local Event = require(utilityFolder.Event)
local Message = require(messagingFolder.Message)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local Table = require(utilityFolder.Table)

local SERVER_FILL = {
    [ServerTypeEnum.location] = {
        max = GameSettings.location_maxPlayers,
        recommended = GameSettings.location_maxRecommendedPlayers
    },

    [ServerTypeEnum.party] = {
        max = GameSettings.party_maxPlayers,
        recommended = GameSettings.party_maxRecommendedPlayers
    },

    [ServerTypeEnum.home] = {
        max = GameSettings.home_maxNormalPlayers,
    }
}

local cachedData = {
    [ServerTypeEnum.routing] = {
        --[[
            [jobId] = {
                serverInfo
            }
        ]]
    },

    [ServerTypeEnum.location] = {
        --[[
            [worldIndex] = {
                [locationEnum] = {
                    serverInfo
                }
            }
        ]]
    },

    [ServerTypeEnum.home] = {
        --[[
            [userId] = {
                serverInfo
            }
        ]]
    },

    [ServerTypeEnum.party] = {
        --[[
            [partyType] = {
                [privateServerId] = {
                    serverInfo
                }
            }
        ]]
    },
}

local lastBroadcast = 0

local function initDataWait()
    if time() < (WAIT_TIME) then
        task.wait(WAIT_TIME - time())
    end
end

local GameServerData = {}

GameServerData.ServerInfoUpdated = Event.new()

function GameServerData.setCachedData(serverType, indexInfo, serverInfo)
    local cachedServerType = cachedData[serverType]

    if serverType == ServerTypeEnum.routing then
        cachedServerType[indexInfo.jobId] = serverInfo
    elseif serverType == ServerTypeEnum.location then
        local worldTable = cachedServerType[indexInfo.worldIndex] or {}
        worldTable[indexInfo.locationEnum] = serverInfo
        cachedServerType[indexInfo.worldIndex] = worldTable
    elseif serverType == ServerTypeEnum.home then
        cachedServerType[indexInfo.userId] = serverInfo
    elseif serverType == ServerTypeEnum.party then
        local partyTable = cachedServerType[indexInfo.partyType] or {}
        partyTable[indexInfo.privateServerId] = serverInfo
        cachedServerType[indexInfo.partyType] = partyTable
    else
        error("GameServerData: Message received with invalid server type")
    end

    GameServerData.ServerInfoUpdated:Fire(serverType, indexInfo, serverInfo)
end

function GameServerData.get(serverType, indexInfo)
    local function check()
        local cachedServerType = cachedData[serverType]

        if serverType == ServerTypeEnum.routing then
            return cachedServerType[indexInfo.jobId]
        elseif serverType == ServerTypeEnum.location then
            local worldTable = cachedServerType[indexInfo.worldIndex]

            if worldTable then
                return worldTable[indexInfo.locationEnum]
            end
        elseif serverType == ServerTypeEnum.home then
            return cachedServerType[indexInfo.userId]
        elseif serverType == ServerTypeEnum.party then
            local partyTable = cachedServerType[indexInfo.partyType]

            if partyTable then
                return partyTable[indexInfo.privateServerId]
            end
        else
            error("GameServerData: Message received with invalid server type")
        end
    end

    if not serverType then -- Wait for all data, and then return it
        initDataWait()

        return cachedData
    end

    local serverInfo = check()
        
    if serverInfo then
        return serverInfo
    end

    repeat
        task.wait()

        serverInfo = check()
    until time() > WAIT_TIME or serverInfo

    return serverInfo
end

function GameServerData.getLocation(worldIndex, locationEnum)
    return GameServerData.get(ServerTypeEnum.location, {
        worldIndex = worldIndex,
        locationEnum = locationEnum,
    })
end

function GameServerData.getPopulationInfo(serverType, indexInfo)
    local serverInfo = GameServerData.get(serverType, indexInfo)

    if serverInfo then
        local population = #serverInfo.players
        local fillInfo = SERVER_FILL[serverType]

        return {
            population = population,
            recommended_emptySlots = fillInfo.recommended and math.max(fillInfo.recommended - population, 0),
            max_emptySlots = math.max(fillInfo.max - population, 0),
        }
    end
end

function GameServerData.getWorldPopulationInfo(worldIndex)
    initDataWait()

    local worldTable = cachedData[ServerTypeEnum.location][worldIndex]
    local fillInfo = SERVER_FILL[ServerTypeEnum.location]

    if worldTable then
        local populationInfo = {
            population = 0,
            recommended_emptySlots = GameSettings.world_maxRecommendedPlayers,

            locations = {},
        }

        for locationEnum, locationServerInfo in pairs(worldTable) do
            local locationPopulation = #locationServerInfo.players
            local locationRecommended_emptySlots = math.max(fillInfo.recommended - locationPopulation, 0)
            local locationMax_emptySlots = math.max(fillInfo.max - locationPopulation, 0)

            populationInfo.population += locationPopulation
            populationInfo.recommended_emptySlots = math.max(populationInfo.recommended_emptySlots - locationPopulation, 0)

            populationInfo.locations[locationEnum] = {
                population = locationPopulation,
                recommended_emptySlots = locationRecommended_emptySlots,
                max_emptySlots = locationMax_emptySlots,
            }
        end

        return populationInfo
    end
end

function GameServerData.getPartyServers(partyType)
    initDataWait()

    local partyTable = cachedData[ServerTypeEnum.party][partyType]

    return partyTable or {}
end

function GameServerData.getPartyCode(privateServerId)
    initDataWait()

    local partyTable = cachedData[ServerTypeEnum.party]

    for partyType, partyServers in pairs(partyTable or {}) do
        for serverId, serverInfo in pairs(partyServers or {}) do
            if serverId == privateServerId then
                return serverInfo.serverCode
            end
        end
    end
end

function GameServerData.getPartyPopulationInfo(partyType, privateServerId)
    return GameServerData.getPopulationInfo(ServerTypeEnum.party, {
        partyType = partyType,
        privateServerId = privateServerId,
    })
end

function GameServerData.getLocationPopulationInfo(worldIndex, locationEnum)
    return GameServerData.getPopulationInfo(ServerTypeEnum.location, {
        worldIndex = worldIndex,
        locationEnum = locationEnum,
    })
end

function GameServerData.getHomePopulationInfo(userId)
    return GameServerData.getPopulationInfo(ServerTypeEnum.home, {
        userId = userId,
    })
end

function GameServerData.getHomeServers()
    initDataWait()

    return cachedData[ServerTypeEnum.home]
end

function GameServerData.publish(serverInfo, indexInfo)
    if not indexInfo then
        warn("GameServerData: Attempted to publish with invalid data")
        return
    end

    lastBroadcast = time()

    Message.publish(BROADCAST_CHANNEL, {
        serverType = LocalServerInfo.serverType,
        serverInfo = serverInfo,
        indexInfo = indexInfo,
    })
end

function GameServerData.canPublish()
    return time() - lastBroadcast >= BROADCAST_COOLDOWN
end

Message.subscribe(BROADCAST_CHANNEL, function(message)
    local message = message.Data

    print("GameServerData: Received message from server")

    GameServerData.setCachedData(message.serverType, message.indexInfo, message.serverInfo)
end)

return GameServerData

