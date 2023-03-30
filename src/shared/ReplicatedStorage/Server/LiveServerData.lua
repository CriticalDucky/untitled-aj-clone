--[[
	This script is responsible for managiging live data that every server reports.
	It also provides utility functions for interfacing with the data.

	All live servers report:
		- Their population (player count)
		- UserIds of players in the server

	Cached live data is stored in a table that, on the highest level, is split into
	sections based on the server type. Each section contains a table of data that
	is specific to that server type.

	For example, the routing server type has a table of job IDs, and each job ID has
	a table of server info. Refer to ServerData.lua to learn more about the indecies
	that reference server info.

	Server info generally looksl ike this:

	```lua
	serverInfo = {
		players = {
			userIds
		},
		[any] = any
	}
	```

	```lua
	local cachedData = {
		[ServerTypeEnum.routing] = {
			[jobId] = {
				serverInfo
			}
		},

		[ServerTypeEnum.location] = {
			[worldIndex] = {
				[locationEnum] = {
					serverInfo
				}
			}
		},

		[ServerTypeEnum.home] = {
			[homeOwner] = {
				serverInfo
			}
		},

		[ServerTypeEnum.party] = {
			[partyType] = {
				[partyIndex] = {
					serverInfo
				}
			}
		},

		[ServerTypeEnum.minigame] = {
			[minigameType] = {
				[minigameIndex] | [privateServerId] = { -- Whether the index is a minigameIndex or privateServerId depends on the minigameType
					serverInfo
				}
			}
		},
	}
	```

	This script can be required from both the client and server.
	If required on the client, all functions will return values that
	can be used in Computeds that dynamically update.

	NOTE: This script represents data the is an approximation of reality.
	Because of this, don't rely on this for an critical actions, such as
	affecting a player's currency or inventory.

	Example usage:
	```lua
	local LiveServerData = require(game.ReplicatedStorage.Shared.Server.LiveServerData)

	local worldIndex = 1 -- The index of the world
	local locationEnum = 2 -- The enum of the location

	local success, isFull = LiveServerData.isLocationFull(worldIndex, locationEnum, playersToJoin)
	local success, populationInfo = LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)

	if success then
		-- A scenario where the server is full
		print(isFull and (populationInfo.max_emptySlots == 0)) --> true
		print(populationInfo.recommended_emptySlots) --> 0
		print(populationInfo.population) --> 20 (if this is the max # of players)
	end

	```
]]

local BROADCAST_CHANNEL = "Servers"
local BROADCAST_COOLDOWN = 5
local BROADCAST_COOLDOWN_PADDING = 2
local WAIT_TIME = BROADCAST_COOLDOWN + BROADCAST_COOLDOWN_PADDING
local DEBUG = false

--#region Imports
local RunService = game:GetService "RunService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility

local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local Table = require(utilityFolder.Table)
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(serverFolder:WaitForChild "ServerTypeGroups")
local Minigames = require(serverFolder:WaitForChild "Minigames")
local Parties = require(serverFolder:WaitForChild "Parties")
local Locations = require(serverFolder:WaitForChild "Locations")
local Promise = require(utilityFolder.Promise)
local Signal = require(utilityFolder.Signal)
local Types = require(utilityFolder.Types)
local LocationType = require(enumsFolder:WaitForChild "LocationType")

type Promise = Types.Promise
type ServerIdentifier = Types.ServerIdentifier
type UserEnum = Types.UserEnum

local Fusion = require(replicatedFirstShared.Fusion)
local Value = Fusion.Value
local unwrap = Fusion.unwrap

--#endregion

local LiveServerData = {}

local dataValue

if RunService:IsServer() then
	local ServerStorage = game:GetService "ServerStorage"

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

		[ServerTypeEnum.minigame] = {
			--[[
				[minigameType] = {
					[minigameIndex] | [privateServerId] = {
						serverInfo
					}
				}
			]]
		},
	}

	dataValue = cachedData

	--[[
		The purpose of this function is to remove playerIds from the cached data that's sent to the client.
		This is necessary because if an influencer streams gameplay, fans could use the streamer's playerId to find out
		where they are in the game.
	]]
	local function filterServerInfo(serverInfo)
		if not serverInfo then return nil end

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

	local replica = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken "LiveServerData",
		Data = filterServerInfo(Table.deepCopy(cachedData)), -- Copying cached data to prevent it from being modified
		Replication = "All",
	}

	LiveServerData.ServerInfoUpdated = Signal.new() -- This signal is fired when the server info is updated.

	--[[
		Server exclusive function.
		Used by LiveServerDataPublisher.lua to broadcast this server's data to all other servers.

		* `serverInfo` is a table that contains the server information (e.g. players)
		* `indexInfo` is a table that contains the index information (e.g. worldIndex, locationEnum, etc.)
	]]
	function LiveServerData.publish(serverIdentifier: ServerIdentifier, serverInfo: table)
		assert(serverIdentifier, "serverIdentifier is nil")
		assert(serverIdentifier.serverType, "serverIdentifier.serverType is nil")

		lastBroadcast = time()

		Message.publish(BROADCAST_CHANNEL, {
			serverInfo = serverInfo,
			serverIdentifier = serverIdentifier,
		})
	end

	--[[
		Used by LiveServerDataPublisher.lua to check if it's okay to broadcast this server's data to all other servers.
	]]
	function LiveServerData.canPublish()
		return time() - lastBroadcast >= BROADCAST_COOLDOWN
	end

	-- Here we're listening for messages from other servers and updating the cached data.
	Message.subscribe(BROADCAST_CHANNEL, function(message)
		-- Runs every time a message is received from any server broadcasting in BROADCAST_CHANNEL

		-- Recieved from LiveServerData.publish from another server:
		local message = message.Data :: {
			serverInfo: table,
			serverIdentifier: ServerIdentifier,
		}

		if DEBUG then print "LiveServerData: Received message from server" end

		local serverIdentifier = message.serverIdentifier
		local serverType = serverIdentifier.serverType
		local serverInfo = message.serverInfo

		assert(serverType, "LiveServerData: Received invalid message from server")

		local cachedServerType = cachedData[serverType]

		if serverType == ServerTypeEnum.routing then -- Each server type will have different means of storing data in the cache.
			cachedServerType[serverIdentifier.jobId] = serverInfo
		elseif serverType == ServerTypeEnum.location then
			local worldIndex = serverIdentifier.worldIndex
			local locationEnum = serverIdentifier.locationEnum

			local worldTable = cachedServerType[worldIndex] or {}

			worldTable[locationEnum] = serverInfo
			cachedServerType[worldIndex] = worldTable

			local replicaData = replica.Data[serverType]

			if not replicaData[worldIndex] then
				replica:SetValue({ serverType, worldIndex }, filterServerInfo(Table.deepCopy(worldTable)))
			end

			replica:SetValue({ serverType, worldIndex, locationEnum }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.home then
			local homeOwner = serverIdentifier.homeOwner

			cachedServerType[homeOwner] = serverInfo

			replica:SetValue({ serverType, homeOwner }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.party then
			local partyType = serverIdentifier.partyType
			local partyIndex = serverIdentifier.partyIndex

			local partyTable = cachedServerType[partyType] or {}

			partyTable[partyIndex] = serverInfo
			cachedServerType[partyType] = partyTable

			local replicaData = replica.Data[serverType]

			if not replicaData[partyType] then
				replica:SetValue({ serverType, partyType }, filterServerInfo(Table.deepCopy(partyTable)))
			end

			replica:SetValue({ serverType, partyType, partyIndex }, filterServerInfo(Table.deepCopy(serverInfo)))
		elseif serverType == ServerTypeEnum.minigame then
			local minigameType = serverIdentifier.minigameType

			local minigameTable = cachedServerType[minigameType] or {}

			local minigameIndex = serverIdentifier.minigameIndex or serverIdentifier.privateServerId

			minigameTable[minigameIndex] = serverInfo
			cachedServerType[minigameType] = minigameTable

			local replicaData = replica.Data[serverType]

			if not replicaData[minigameType] then
				replica:SetValue({ serverType, minigameType }, filterServerInfo(Table.deepCopy(minigameTable)))
			end

			replica:SetValue({ serverType, minigameType, minigameIndex }, filterServerInfo(Table.deepCopy(serverInfo)))
		else
			error ("LiveServerData: Message received with invalid server type. Received: " .. tostring(serverType))
		end

		LiveServerData.ServerInfoUpdated:Fire(serverType, serverIdentifier, serverInfo)
	end)
elseif RunService:IsClient() then -- Client
	local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

	local replicaData = ReplicaCollection.get("LiveServerData")

	dataValue = Value(replicaData.Data) -- Simple convenience for UI development
	-- Because of this, whenever we call any of the functions below,
	-- UI will dynamically update when the data is updated (as long as it's called from a Computed).

	replicaData:ListenToRaw(function()
		dataValue:set(replicaData.Data)
	end)
end

--[[
	Since servers broadcast their data every WAIT_TIME seconds,
	we need to wait for that time to pass before we can get an accurate representation of data
	from all the servers.

	Why don't I just have this built in to the get function?

	* Fusion Computeds cant yield, so UI scripts need to implement their own
	loading functionalities.

	* However, I can safely do this in the get function for the server.
]]
function LiveServerData.initialWait()
	if time() < WAIT_TIME then task.wait(WAIT_TIME - time()) end
end

--[[
	Gets the live server data for the given serverIdentifier.
	If a serverType is provided instead, it will return the whole data table for that serverType.
	If no serverIdentifier is provided, it will return the whole data table.
	
	Consider using the helper functions for convenience.


	Will return nil if the specified server is not live.
	If the server is live, it will return this:
	```lua
	serverInfo = {
		players = {
			userIds
		},
		[any] = any
	}
	```
]]
function LiveServerData.get(
	serverIdentifier: ServerIdentifier | UserEnum | nil
): nil | {} | { players: { [number]: number }, [any]: any }
	if RunService:IsServer() then LiveServerData.initialWait() end -- See LiveServerData.initialWait comment above

	local data = unwrap(dataValue)

	if not serverIdentifier then return data end

	local serverType = if typeof(serverIdentifier) == "table" then serverIdentifier.serverType else serverIdentifier
	local serverTypeData = data[serverType]

	if typeof(serverIdentifier) ~= "table" then return serverTypeData end

	if serverType == ServerTypeEnum.routing then
		return serverTypeData[serverIdentifier.jobId]
	elseif serverType == ServerTypeEnum.location then
		local worldTable = serverTypeData[serverIdentifier.worldIndex]

		if worldTable then return worldTable[serverIdentifier.locationEnum] end
	elseif serverType == ServerTypeEnum.home then
		return serverTypeData[serverIdentifier.homeOwner]
	elseif serverType == ServerTypeEnum.party then
		local partyTable = serverTypeData[serverIdentifier.partyType]

		if partyTable then return partyTable[serverIdentifier.partyIndex] end
	elseif serverType == ServerTypeEnum.minigame then
		local minigameTable = serverTypeData[serverIdentifier.minigameType]

		if minigameTable then
			return minigameTable[serverIdentifier.minigameIndex or serverIdentifier.privateServerId]
		end
	else
		error "LiveServerData: Message received with invalid server type"
	end
end

--[[
	Gets the location live server info for the given worldIndex and locationEnum.
]]
function LiveServerData.getLocation(worldIndex, locationEnum)
	return LiveServerData.get {
		serverType = ServerTypeEnum.location,
		worldIndex = worldIndex,
		locationEnum = locationEnum,
	}
end

--[[
	Gets the compiled population info for the given serverIdentifier.


	Population info looks like this:
	```lua
	{
		population = number,
		recommended_emptySlots = number,
		max_emptySlots = number,
	}
	```
	where `population` is the number of players on the server,
	`recommended_emptySlots` is the number of empty slots recommended for the server to fill up,
	and `max_emptySlots` is the maximum number of empty slots the server has left.
	Recommended empty slots will always either be higher or equal to max empty slots.

	To get the population info for a whole world, pass in a ServerIdentifier that leaves the locationEnum field nil:
	```lua
	local worldPopulationInfo = LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.location,
		worldIndex = 1,
	}
	```
	
	This will return the population info for the whole world:
	```lua
	{
		population = number,
		recommended_emptySlots = number,
		max_emptySlots = number,

		locations = {
			[LocationEnum] = {
				population = number,
				recommended_emptySlots = number,
				max_emptySlots = number,
			}
		}
	}
	```

	This is how you could check if a server is full:
	```lua
	local populationInfo = LiveServerData.getPopulationInfo(serverIdentifier)
	
	if populationInfo.max_emptySlots == 0 then -- Will error if the specified server is not live
		-- Server is full
	end
	```

	**Will return nil** if the specified server is not live.
]]
function LiveServerData.getPopulationInfo(serverIdentifier: ServerIdentifier)
	local serverType = serverIdentifier.serverType

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
		local locationEnum = serverIdentifier.locationEnum

		if locationEnum == nil then
			-- This is a request for the whole world's population info
			local worldIndex = serverIdentifier.worldIndex
			local worldTable = LiveServerData.get(ServerTypeEnum.location)[worldIndex]
			local worldPopulationInfo

			if worldTable and Table.hasAnything(worldTable) then -- If the world is live
				worldPopulationInfo = {
					population = 0,
					recommended_emptySlots = 0,
					max_emptySlots = 0,

					locations = {},
				}

				local priorityPopulation = 0 -- The population of locations where players can spawn

				for locationEnum, _ in pairs(worldTable) do
					local populationInfo = LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)

					if populationInfo then
						local population = populationInfo.population

						worldPopulationInfo.population += population
						worldPopulationInfo.locations[locationEnum] = populationInfo

						if table.find(Locations.priority, locationEnum) then
							priorityPopulation += population
						end
					end
				end

				worldPopulationInfo.recommended_emptySlots =
					math.max(Locations.getWorldRecommendedPlayerCount() - priorityPopulation, 0)
				worldPopulationInfo.max_emptySlots =
					math.max(Locations.getWorldMaxPlayerCount() - priorityPopulation, 0)
			end

			return worldPopulationInfo
		end
	end

	local serverInfo = LiveServerData.get(serverIdentifier)

	if serverInfo then
		local serverInfoPlayers = serverInfo.players
		local population = if type(serverInfoPlayers) == "table" then #serverInfoPlayers else serverInfoPlayers

		local serverFillInfo = {
			max = 0,
			recommended = 0,
		}

		if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
			local locationEnum = serverIdentifier.locationEnum

			local locationInfo = Locations.info[locationEnum]

			if locationInfo then
				local populationInfo = locationInfo.populationInfo

				if populationInfo then
					serverFillInfo.max = populationInfo.max
					serverFillInfo.recommended = populationInfo.recommended
				else
					serverFillInfo.max = GameSettings.location_maxPlayers
					serverFillInfo.recommended = GameSettings.location_maxRecommendedPlayers
				end
			else
				error("Invalid location enum: " .. tostring(locationEnum))
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
			local partyType = serverIdentifier.partyType

			local partyInfo = Parties[partyType]

			if partyInfo then
				local populationInfo = partyInfo.populationInfo

				if populationInfo then
					serverFillInfo.max = populationInfo.max
					serverFillInfo.recommended = populationInfo.recommended
				else
					serverFillInfo.max = GameSettings.party_maxPlayers
					serverFillInfo.recommended = GameSettings.party_maxRecommendedPlayers
				end
			else
				error("Invalid party enum: " .. tostring(partyType))
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isMinigame, serverType) then
			local minigameType = serverIdentifier.minigameType

			local minigameInfo = Minigames[minigameType]

			if minigameInfo then
				local populationInfo = minigameInfo.populationInfo

				if populationInfo then
					serverFillInfo.max = populationInfo.max
					serverFillInfo.recommended = populationInfo.recommended
				else
					serverFillInfo.max = GameSettings.location_maxPlayers
					serverFillInfo.recommended = GameSettings.location_maxRecommendedPlayers
				end
			else
				error("Invalid game enum: " .. tostring(minigameType))
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, serverType) then
			serverFillInfo.max = GameSettings.home_maxNormalPlayers
		else
			error("Invalid server type: " .. tostring(serverType))
		end

		return {
			population = population,
			recommended_emptySlots = math.max(serverFillInfo.recommended - population, 0),
			max_emptySlots = math.max(serverFillInfo.max - population, 0),
		}
	end
end

--[[
	Gets the population info for the given worldIndex and locationEnum.
	Wrapper for LiveServerData.getPopulationInfo.

	Can return nil if the location is not live.
]]
function LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)
	return LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.location,
		worldIndex = worldIndex,
		locationEnum = locationEnum,
	}
end

--[[
	Gets the population info for the given partyType and partyIndex.
	Wrapper for LiveServerData.getPopulationInfo for party servers.

	Can return nil if the party is not live.
]]
function LiveServerData.getPartyPopulationInfo(partyType, partyIndex)
	return LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.party,
		partyType = partyType,
		partyIndex = partyIndex,
	}
end

--[[
	Gets the population info for the given home server.
	Wrapper for LiveServerData.getPopulationInfo for home servers.

	Can return nil if the home is not live.
]]
function LiveServerData.getHomePopulationInfo(homeOwner)
	return LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.home,
		homeOwner = homeOwner,
	}
end

--[[
	Gets the population info for the given minigameType and minigameIndex.
	minigameIndex can be a minigameIndex or privateServerId.
	Wrapper for LiveServerData.getPopulationInfo for minigame servers.

	Can return nil if the minigame is not live.
]]
function LiveServerData.getMinigamePopulationInfo(minigameType, minigameIndex: number | string)
	return LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.minigame,
		minigameType = minigameType,
		[if type(minigameIndex) == "number" then "minigameIndex" else "privateServerId"] = minigameIndex,
	}
end

--[[
	Gets the population info for the given worldIndex.
	Wrapper for LiveServerData.getPopulationInfo.

	Can return nil if the world is not live.
]]
function LiveServerData.getWorldPopulationInfo(worldIndex)
	return LiveServerData.getPopulationInfo {
		serverType = ServerTypeEnum.location,
		worldIndex = worldIndex,
	}
end

--[[
	Gets the compiled player count for the given worldIndex.
]]
function LiveServerData.getWorldPopulation(worldIndex)
	local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

	return if worldPopulationInfo then worldPopulationInfo.population else 0
end

--[[
	Gets the parties table for the given party type.
	Servers not live will not be included in the table.

	Can return nil if no parties of the given type are live.
]]
function LiveServerData.getPartyServers(partyType)
	local partyData = LiveServerData.get(ServerTypeEnum.party)

	if partyData then return partyData[partyType] end
end

--[[
	Gets the home servers table.

	```lua
	{
		[UserId] = {
			serverData
		}
	}
	```

	Servers not live will not be included in the table, and if no home servers are live, this will return nil.
]]
function LiveServerData.getHomeServers()
	return LiveServerData.get(ServerTypeEnum.home)
end

--[[
	Gets the minigames table for the given minigame type.
	Servers not live will not be included in the table.

	Can return nil if no minigames of the given type are live.
]]
function LiveServerData.getMinigameServers(minigameType)
	local minigameData = LiveServerData.get(ServerTypeEnum.minigame)

	if minigameData then return minigameData[minigameType] end
end

--[[
	Returns a boolean indicating if the specified location is full.
	Optionally, you can specify the number of players you plan to add to the location.

	Will return false if the location is not live (makes sense, right?)
]]
function LiveServerData.isLocationFull(worldIndex, locationEnum, numPlayersToAdd: number)
	numPlayersToAdd = numPlayersToAdd or 0

	local locationPopulationInfo = LiveServerData.getLocationPopulationInfo(worldIndex, locationEnum)

	return if locationPopulationInfo and locationPopulationInfo.max_emptySlots - numPlayersToAdd <= 0
		then true
		else false
end

--[[
	Returns a boolean indicating if the specified world is full.
	Optionally, you can specify the number of players you plan to add to the world.

	Will return false if the world is not live (makes sense, right?)
]]
function LiveServerData.isWorldFull(worldIndex, numPlayersToAdd: number)
	return LiveServerData.isLocationFull(worldIndex, nil, numPlayersToAdd)
end

--[[
	Returns a boolean indicating if the specified party is full.
	Optionally, you can specify the number of players you plan to add to the party.

	Will return false if the party is not live (makes sense, right?)
]]
function LiveServerData.isPartyFull(partyType, partyIndex, numPlayersToAdd: number)
	numPlayersToAdd = numPlayersToAdd or 0

	local partyPopulationInfo = LiveServerData.getPartyPopulationInfo(partyType, partyIndex)

	return if partyPopulationInfo and partyPopulationInfo.max_emptySlots - numPlayersToAdd <= 0
		then true
		else false
end

--[[
	Returns a boolean indicating if the specified home is full.
	Optionally, you can specify the number of players you plan to add to the home.

	Will return false if the home is not live (makes sense, right?)
]]
function LiveServerData.isHomeFull(homeOwner, numPlayersToAdd: number)
	numPlayersToAdd = numPlayersToAdd or 0

	local homePopulationInfo = LiveServerData.getHomePopulationInfo(homeOwner)

	return if homePopulationInfo and homePopulationInfo.max_emptySlots - numPlayersToAdd <= 0
		then true
		else false
end

--[[
	Returns a boolean indicating if the specified minigame is full.
	Optionally, you can specify the number of players you plan to add to the minigame.

	Will return false if the minigame is not live (makes sense, right?)
]]
function LiveServerData.isMinigameFull(minigameType, minigameIndex: number | string, numPlayersToAdd: number)
	numPlayersToAdd = numPlayersToAdd or 0

	local minigamePopulationInfo = LiveServerData.getMinigamePopulationInfo(minigameType, minigameIndex)

	return if minigamePopulationInfo and minigamePopulationInfo.max_emptySlots - numPlayersToAdd <= 0
		then true
		else false
end

return LiveServerData