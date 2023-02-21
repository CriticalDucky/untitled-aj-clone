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

local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local Table = require(utilityFolder.Table)
local GetServerFillInfo = require(serverFolder.GetServerFillInfo)
local Promise = require(utilityFolder.Promise)
local Signal = require(utilityFolder.Signal)
local Types = require(utilityFolder.Types)

type Promise = Types.Promise

local Fusion = require(replicatedFirstShared.Fusion)
local Value = Fusion.Value
local unwrap = Fusion.unwrap

local isClient = RunService:IsClient()
local isServer = RunService:IsServer()

local LiveServerData = {}

local dataPromise

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
                [homeOwner] = {
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
		},
	}

	dataPromise = Promise.resolve(cachedData)

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
		Replication = "All",
	})

	LiveServerData.ServerInfoUpdated = Signal.new()

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
				replica:SetValue({ serverType, worldIndex }, filterServerInfo(Table.deepCopy(worldTable)))
			end

			replica:SetValue({ serverType, worldIndex, locationEnum }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.home then
			local homeOwner = indexInfo.homeOwner

			cachedServerType[homeOwner] = serverInfo

			replica:SetValue({ serverType, homeOwner }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.party then
			local partyType = indexInfo.partyType
			local partyIndex = indexInfo.partyIndex

			local partyTable = cachedServerType[partyType] or {}

			partyTable[partyIndex] = serverInfo
			cachedServerType[partyType] = partyTable

			local replicaData = replica.Data[serverType]

			if not replicaData[partyType] then
				replica:SetValue({ serverType, partyType }, filterServerInfo(Table.deepCopy(partyTable)))
			end

			replica:SetValue({ serverType, partyType, partyIndex }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.game then
			local gameType = indexInfo.gameType
			local gameIndex = indexInfo.gameIndex

			local gameTable = cachedServerType[gameType] or {}

			gameTable[gameIndex] = serverInfo
			cachedServerType[gameType] = gameTable

			local replicaData = replica.Data[serverType]

			if not replicaData[gameType] then
				replica:SetValue({ serverType, gameType }, filterServerInfo(Table.deepCopy(gameTable)))
			end

			replica:SetValue({ serverType, gameType, gameIndex }, filterServerInfo(Table.deepCopy(serverInfo)))
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

	dataPromise = ReplicaCollection.get("LiveServerData", true):andThen(function(replica)
		local dataValue = Value(replica.Data)

		replica:ListenToRaw(function()
			dataValue:set(replica.Data)
		end)

		return dataValue
	end)
end

function LiveServerData.get(serverType, indexInfo): Promise
	return Promise.all({
		Promise.new(function(resolve)
			if time() < WAIT_TIME then
				task.wait(WAIT_TIME - time())
			end

			resolve()
		end),
		dataPromise,
	})
		:andThen(function(resultArray)
			return unwrap(resultArray[2])
		end)
		:andThen(function(data)
			local serverTypeData = data[serverType]

			if not serverType then
				return data
			end

			if not indexInfo then
				return serverTypeData
			end

			if serverType == ServerTypeEnum.routing then
				return serverTypeData[indexInfo.jobId]
			elseif serverType == ServerTypeEnum.location then
				local worldTable = serverTypeData[indexInfo.worldIndex]

				if worldTable then
					return worldTable[indexInfo.locationEnum]
				end
			elseif serverType == ServerTypeEnum.home then
				return serverTypeData[indexInfo.homeOwner]
			elseif serverType == ServerTypeEnum.party then
				local partyTable = serverTypeData[indexInfo.partyType]

				if partyTable then
					return partyTable[indexInfo.partyIndex]
				end
			elseif serverType == ServerTypeEnum.game then
				local gameTable = serverTypeData[indexInfo.gameType]

				if gameTable then
					return gameTable[indexInfo.gameIndex] or gameTable[indexInfo.privateServerId]
				end
			else
				error("LiveServerData: Message received with invalid server type")
			end
		end)
end

function LiveServerData.getLocation(worldIndex, locationEnum): Promise
	return LiveServerData.get(ServerTypeEnum.location, {
		worldIndex = worldIndex,
		locationEnum = locationEnum,
	})
end

function LiveServerData.getPopulationInfo(serverType, indexInfo): Promise
	return LiveServerData.get(serverType, indexInfo):andThen(function(serverData)
		if serverData then
			local serverInfoPlayers = serverData.players
			local population = if type(serverInfoPlayers) == "table" then #serverInfoPlayers else serverInfoPlayers
			local fillInfo = GetServerFillInfo(serverType, indexInfo)

			return {
				population = population,
				recommended_emptySlots = fillInfo.recommended and math.max(fillInfo.recommended - population, 0),
				max_emptySlots = math.max(fillInfo.max - population, 0),
			}
		end
	end)
end

function LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum): Promise
	return LiveServerData.getPopulationInfo(ServerTypeEnum.location, {
		worldIndex = worldIndex,
		locationEnum = locationEnum,
	})
end

function LiveServerData.getWorldPopulationInfo(worldIndex): Promise
	return LiveServerData.get(ServerTypeEnum.location):andThen(function(worlds)
		local worldTable = worlds[worldIndex]

		if worldTable then
			local worldPopulationInfo = {
				population = 0,
				recommended_emptySlots = 0,
				max_emptySlots = 0,

				locations = {},
			}

			local promises = {}

			for locationEnum, _ in pairs(worldTable) do
				table.insert(
					promises,
					LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum):andThen(function(populationInfo)
						if populationInfo then
							worldPopulationInfo.population += populationInfo.population
							worldPopulationInfo.max_emptySlots += populationInfo.max_emptySlots
							worldPopulationInfo.locations[locationEnum] = populationInfo
						end
					end)
				)
			end

			worldPopulationInfo.recommended_emptySlots =
				math.max(GameSettings.world_maxRecommendedPlayers - worldPopulationInfo.population, 0)

			return Promise.all(promises):andThen(function()
				return worldPopulationInfo
			end)
		end
	end)
end

function LiveServerData.getWorldPopulation(worldIndex): Promise
	return LiveServerData.getWorldPopulationInfo(worldIndex):andThen(function(worldPopulationInfo)
		return if worldPopulationInfo then worldPopulationInfo.population else 0
	end)
end

function LiveServerData.getPartyPopulationInfo(partyType, partyIndex): Promise
	return LiveServerData.getPopulationInfo(ServerTypeEnum.party, {
		partyType = partyType,
		partyIndex = partyIndex,
	})
end

function LiveServerData.getHomePopulationInfo(homeOwner): Promise
	return LiveServerData.getPopulationInfo(ServerTypeEnum.home, {
		homeOwner = homeOwner,
	})
end

function LiveServerData.getGamePopulationInfo(gameType, gameIndex: number | string): Promise
	return LiveServerData.getPopulationInfo(ServerTypeEnum.game, {
		gameType = gameType,
		gameIndex = gameIndex,
	})
end

function LiveServerData.getPartyServers(partyType): Promise
	return LiveServerData.get(ServerTypeEnum.party):andThen(function(partyData)
		return partyData[partyType] or {}
	end)
end

function LiveServerData.getHomeServers(): Promise
	return LiveServerData.get(ServerTypeEnum.home)
end

function LiveServerData.getGameServers(gameType): Promise
	return LiveServerData.get(ServerTypeEnum.game):andThen(function(gameData)
		return gameData[gameType] or {}
	end)
end

function LiveServerData.isWorldFull(worldIndex, numPlayersToAdd): Promise
	numPlayersToAdd = numPlayersToAdd or 0

	return LiveServerData.getWorldPopulationInfo(worldIndex):andThen(function(worldPopulationInfo)
		return if worldPopulationInfo and worldPopulationInfo.max_emptySlots - numPlayersToAdd <= 0 then true else false
	end)
end

function LiveServerData.isLocationFull(worldIndex, locationEnum, numPlayersToAdd):Promise
	numPlayersToAdd = numPlayersToAdd or 0

	return LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum):andThen(function(locationPopulationInfo)
		return if locationPopulationInfo and locationPopulationInfo.max_emptySlots - numPlayersToAdd <= 0
			then true
			else false
	end)
end

function LiveServerData.isPartyFull(partyType, partyIndex, numPlayersToAdd): Promise
	numPlayersToAdd = numPlayersToAdd or 0

	return LiveServerData.getPartyPopulationInfo(partyType, partyIndex):andThen(function(partyPopulationInfo)
		return if partyPopulationInfo and partyPopulationInfo.max_emptySlots - numPlayersToAdd <= 0 then true else false
	end)
end

function LiveServerData.isHomeFull(homeOwner, numPlayersToAdd): Promise
	numPlayersToAdd = numPlayersToAdd or 0

	return LiveServerData.getHomePopulationInfo(homeOwner):andThen(function(homePopulationInfo)
		return if homePopulationInfo and homePopulationInfo.max_emptySlots - numPlayersToAdd <= 0 then true else false
	end)
end

return LiveServerData
