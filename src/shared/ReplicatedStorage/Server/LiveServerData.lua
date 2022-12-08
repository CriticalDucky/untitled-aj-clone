local BROADCAST_CHANNEL = "Servers"
local BROADCAST_COOLDOWN = 10
local BROADCAST_COOLDOWN_PADDING = 2
local WAIT_TIME = BROADCAST_COOLDOWN + BROADCAST_COOLDOWN_PADDING

local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility

local Event = require(utilityFolder.Event)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local Table = require(utilityFolder.Table)
local GetServerFillInfo = require(serverFolder.GetServerFillInfo)

local Fusion = require(replicatedFirstShared.Fusion)
local Value = Fusion.Value
local unwrap = Fusion.unwrap

local isClient = RunService:IsClient()
local isServer = RunService:IsServer()

local function initDataWait()
    if time() < (WAIT_TIME) then
        task.wait(WAIT_TIME - time())
    end
end

local LiveServerData = {}

local data

if isServer then
    local ServerStorage = game:GetService("ServerStorage")

    local serverStorageShared = ServerStorage.Shared
    local messagingFolder = serverStorageShared.Messaging
    local dataFolder = serverStorageShared.Data

    local Message = require(messagingFolder.Message)
    local ReplicaService = require(dataFolder.ReplicaService)

    local lastBroadcast = 0

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
                    [partyIndex] = {
                        serverInfo
                    }
                }
            ]]
        },

        [ServerTypeEnum.game] = {
            --[[
                [gameType] = {
                    [gameIndex] | [privateServerId] = {
                        serverInfo
                    }
                }
            ]]
        }
    }

    data = cachedData

    local function filterServerInfo(serverInfo)
        if not serverInfo then
            return nil
        end
    
        local newTable = {}
                                                                                                     
        for key, value in pairs(serverInfo) do
            if key == "players" then
                newTable[key] = #value
    
                continue
            end

            if type(value) == "table" then
                newTable[key] = filterServerInfo(value)
            else
                newTable[key] = value
            end
        end
    
        return newTable
    end

    local replica = ReplicaService.NewReplica({
        ClassToken = ReplicaService.NewClassToken("LiveServerData"),
        Data = filterServerInfo(Table.deepCopy(cachedData)),
        Replication = "All"
    })

    Table.print(cachedData, "cachedData", true)

    LiveServerData.ServerInfoUpdated = Event.new()

    function LiveServerData.setCachedData(serverType, indexInfo, serverInfo)
        local cachedServerType = cachedData[serverType]

        if serverType == ServerTypeEnum.routing then
            cachedServerType[indexInfo.jobId] = serverInfo
        elseif serverType == ServerTypeEnum.location then
            local worldIndex = indexInfo.worldIndex
            local locationEnum = indexInfo.locationEnum

            local worldTable = cachedServerType[worldIndex] or {}

            worldTable[locationEnum] = serverInfo
            cachedServerType[worldIndex] = worldTable

            local replicaData = replica.Data[serverType]

            if not replicaData[worldIndex] then
                replica:SetValue({serverType, worldIndex}, filterServerInfo(Table.deepCopy(worldTable)))
            end

            replica:SetValue({serverType, worldIndex, locationEnum}, filterServerInfo(Table.deepCopy(serverInfo)))
        elseif serverType == ServerTypeEnum.home then
            local userId = indexInfo.userId

            cachedServerType[userId] = serverInfo

            replica:SetValue({serverType, userId}, filterServerInfo(Table.deepCopy(serverInfo)))
        elseif serverType == ServerTypeEnum.party then
            local partyType = indexInfo.partyType
            local partyIndex = indexInfo.partyIndex

            local partyTable = cachedServerType[partyType] or {}

            partyTable[partyIndex] = serverInfo
            cachedServerType[partyType] = partyTable

            local replicaData = replica.Data[serverType]

            if not replicaData[partyType] then
                replica:SetValue({serverType, partyType}, filterServerInfo(Table.deepCopy(partyTable)))
            end

            replica:SetValue({serverType, partyType, partyIndex}, filterServerInfo(Table.deepCopy(serverInfo)))
        elseif serverType == ServerTypeEnum.game then
            local gameType = indexInfo.gameType
            local gameIndex = indexInfo.gameIndex

            local gameTable = cachedServerType[gameType] or {}

            gameTable[gameIndex] = serverInfo
            cachedServerType[gameType] = gameTable

            local replicaData = replica.Data[serverType]

            if not replicaData[gameType] then
                replica:SetValue({serverType, gameType}, filterServerInfo(Table.deepCopy(gameTable)))
            end

            replica:SetValue({serverType, gameType, gameIndex}, filterServerInfo(Table.deepCopy(serverInfo)))
        else
            error("LiveServerData: Message received with invalid server type")
        end

        LiveServerData.ServerInfoUpdated:Fire(serverType, indexInfo, serverInfo)
    end

    function LiveServerData.publish(serverInfo, indexInfo)
        if not indexInfo then
            warn("LiveServerData: Attempted to publish with invalid data")
            return
        end

        lastBroadcast = time()

        Message.publish(BROADCAST_CHANNEL, {
            serverType = LocalServerInfo.serverType,
            serverInfo = serverInfo,
            indexInfo = indexInfo,
        })
    end

    function LiveServerData.canPublish()
        return time() - lastBroadcast >= BROADCAST_COOLDOWN
    end

    Message.subscribe(BROADCAST_CHANNEL, function(message)
        local message = message.Data

        print("LiveServerData: Received message from server")

        LiveServerData.setCachedData(message.serverType, message.indexInfo, message.serverInfo)
    end)
elseif isClient then
    local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

    local replica = ReplicaCollection.get("LiveServerData", true)

    local dataValue = Value(replica.Data)

    data = dataValue

    replica:ListenToRaw(function(action_name, path)
        dataValue:set(replica.Data)
        Table.print(replica.Data, "LiveServerData", true)
    end)
end

function LiveServerData.get(serverType, indexInfo)
    local function check()
        local cachedServerType = unwrap(data)[serverType]

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
                return partyTable[indexInfo.partyIndex]
            end
        elseif serverType == ServerTypeEnum.game then
            local gameTable = cachedServerType[indexInfo.gameType]

            if gameTable then
                return gameTable[indexInfo.gameIndex] or gameTable[indexInfo.privateServerId]
            end
        else
            error("LiveServerData: Message received with invalid server type")
        end
    end

    if not serverType then -- Wait for all data, and then return it
        initDataWait()

        return unwrap(data)
    end

    if not indexInfo then -- Wait for server type data, and then return it
        initDataWait()

        return unwrap(data)[serverType]
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

function LiveServerData.getLocation(worldIndex, locationEnum)
    return LiveServerData.get(ServerTypeEnum.location, {
        worldIndex = worldIndex,
        locationEnum = locationEnum,
    })
end

function LiveServerData.getPopulationInfo(serverType, indexInfo)
    local serverInfo = LiveServerData.get(serverType, indexInfo)

    if serverInfo then
        local serverInfoPlayers = serverInfo.players
        local population = if type(serverInfoPlayers) == "table" then #serverInfoPlayers else serverInfoPlayers
        local fillInfo = GetServerFillInfo(serverType, indexInfo)

        return {
            population = population,
            recommended_emptySlots = fillInfo.recommended and math.max(fillInfo.recommended - population, 0),
            max_emptySlots = math.max(fillInfo.max - population, 0),
        }
    end
end

function LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)
    return LiveServerData.getPopulationInfo(ServerTypeEnum.location, {
        worldIndex = worldIndex,
        locationEnum = locationEnum,
    })
end

function LiveServerData.getWorldPopulationInfo(worldIndex)
    local worldTable = LiveServerData.get(ServerTypeEnum.location)[worldIndex]

    if worldTable then
        local worldPopulationInfo = {
            population = 0,
            recommended_emptySlots = 0,
            max_emptySlots = 0,
            
            locations = {},
        }

        for locationEnum, _ in pairs(worldTable) do
            local populationInfo = LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)

            if populationInfo then
                worldPopulationInfo.population += populationInfo.population
                worldPopulationInfo.max_emptySlots += populationInfo.max_emptySlots
                worldPopulationInfo.locations[locationEnum] = populationInfo
            end
        end

        worldPopulationInfo.recommended_emptySlots = math.max(GameSettings.world_maxRecommendedPlayers - worldPopulationInfo.population, 0)

        return worldPopulationInfo
    end
end

function LiveServerData.getWorldPopulation(worldIndex)
    local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

    return if worldPopulationInfo then worldPopulationInfo.population else 0
end

function LiveServerData.getPartyServers(partyType)
    initDataWait()

    local partyTable = LiveServerData.get(ServerTypeEnum.party)[partyType]

    return partyTable or {}
end

function LiveServerData.getPartyPopulationInfo(partyType, partyIndex)
    return LiveServerData.getPopulationInfo(ServerTypeEnum.party, {
        partyType = partyType,
        partyIndex = partyIndex,
    })
end

function LiveServerData.getHomePopulationInfo(userId)
    return LiveServerData.getPopulationInfo(ServerTypeEnum.home, {
        userId = userId,
    })
end

function LiveServerData.getHomeServers()
    initDataWait()

    return LiveServerData.get(ServerTypeEnum.home)
end

function LiveServerData.getGameServers(gameType)
    initDataWait()

    local gameTable = LiveServerData.get(ServerTypeEnum.game)[gameType] or {}

    return gameTable
end

function LiveServerData.isWorldFull(worldIndex)
    local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

    return worldPopulationInfo and worldPopulationInfo.max_emptySlots <= 0
end

function LiveServerData.isLocationFull(worldIndex, locationEnum)
    local locationPopulationInfo = LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)

    return locationPopulationInfo and locationPopulationInfo.max_emptySlots <= 0
end

function LiveServerData.isPartyFull(partyType, partyIndex)
    local partyPopulationInfo = LiveServerData.getPartyPopulationInfo(partyType, partyIndex)

    return partyPopulationInfo and partyPopulationInfo.max_emptySlots <= 0
end

function LiveServerData.isHomeFull(userId)
    local homePopulationInfo = LiveServerData.getHomePopulationInfo(userId)

    return homePopulationInfo and homePopulationInfo.max_emptySlots <= 0
end

function LiveServerData.getGamePopulationInfo(gameType, gameIndex: number | string) ---@TODO: Update codebase
    return LiveServerData.getPopulationInfo(ServerTypeEnum.game, {
        gameType = gameType,
        gameIndex = gameIndex,
    })
end

return LiveServerData