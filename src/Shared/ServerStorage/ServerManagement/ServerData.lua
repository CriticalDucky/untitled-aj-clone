--[[ Script Info

This script manages, stores, and retrieves data from the Servers datastore.

 It's responsible for reserving servers for new locations, parties, and minigames.
 Using this script, agents can also find available servers for locations, parties, and minigames.
 Home server info is also stored by the Servers datastore.

 Server info is stored in the following format (see cachedData structure below):
 ```lua
 {
 	privateServerId = privateServerId: string?,
 	serverCode = serverCode: string?,
	[any] = any?
 }
 ```
 The serverCode is passed into TeleportOptions.ReservedServerAccessCode when teleporting to the server.

 Data is cached and is updated every 30 seconds. This is to prevent the datastore from being spammed.

 Structure of cachedData:
```lua
 cachedData = {
	[WORLDS_KEY] = {
		[worldIndex: number] = {
			locations = {
				[locationEnum: UserEnum] = {
					privateServerId = privateServerId,
					serverCode = serverCode,
				}
			}
			[any] = any -- Currently unused, but may be used in the future
		},
		...
	},
	[PARTIES_KEY] = {
		[partyType: UserEnum] = {
			[partyIndex: number] = {
				privateServerId = privateServerId,
				serverCode = serverCode,
			}
			...
		}
	},
	[MINIGAMES_KEY] = {
		[minigameType: UserEnum] = {
			[minigameIndex: number] = {
				privateServerId = privateServerId,
				serverCode = serverCode,
			}
			...
		}
	},
	[PrivateServerId] = {
		[any] = any
		-- privateServerId and serverCode don't need to be stored here because
		-- servers use their privateServerId as the means of identifying themselves.
		-- serverCodes are likely stored elsewhere because you would rarely need to
		-- get the serverCode if you already have the privateServerId. (that's how this game is structured)
	}
}
```
A serverIdentifier is a table that includes information about how to locate serverInfo within cachedData.
It's used for servers to identify themselves and for scripts like LiveServerData to find the serverInfo of a server.

Structure of serverIdentifier:
```lua
export type ServerIdentifier = {
	serverType: UserEnum, -- The type of server (location, party, minigame, etc.)
	jobId: string?, -- The jobId of the server (routing servers)
	worldIndex: number?, -- The index of the world the server is in (location servers)
	locationEnum: UserEnum?, -- The location of the server (location servers)
	homeOwner: number?, -- The userId of the player who owns the home (home servers)
	partyType: UserEnum?, -- The type of party the server is for (party servers)
	partyIndex: number?, -- The index of the party the server is for (party servers)
	minigameType: UserEnum?, -- The type of minigame the server is for (minigame servers)
	minigameIndex: number?, -- The index of the minigame the server is for (public minigame servers)
	privateServerId: string?, -- The privateServerId of the server (instance minigame servers)
}
```

--]]

local SERVERS_DATASTORE = "Servers"
local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local MINIGAMES_KEY = "minigames"
local CACHE_COOLDOWN = 30

--#region Imports
local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local TeleportService = game:GetService "TeleportService"
local ServerStorage = game:GetService "ServerStorage"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedFirstVendor = ReplicatedFirst.Vendor
local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local serverFolder = replicatedStorageShared.Server
local utilityFolder = serverStorageShared.Utility
local replicatedFirstUtility = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local Minigames = require(serverFolder.Minigames)
local DataStore = require(utilityFolder.DataStore)
local MinigameServerType = require(enumsFolder.MinigameServerType)
local LiveServerData = require(serverFolder.LiveServerData)
local Math = require(replicatedFirstUtility.Math)
local Table = require(replicatedFirstUtility.Table)
local ReplicaService = require(serverStorageVendor.ReplicaService)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local Promise = require(replicatedFirstVendor.Promise)
local Types = require(replicatedFirstUtility.Types)
local ServerTypeEnum = require(enumsFolder.ServerType)

type Promise = Types.Promise
type PlayerData = Types.PlayerData
type UserEnum = Types.UserEnum
--#endregion

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
	[MINIGAMES_KEY] = {
		--[[
			[minigameType] = {
				[minigameIndex] = {
					privateServerId = privateServerId,
					serverCode = serverCode,
				}
			}
		]]
	},
	--[[
	[PrivateServerId] = {
		[any] = any
	} | ServerIdentifier
]]
}

local constantKeys = {
	[WORLDS_KEY] = true,
	[PARTIES_KEY] = true,
	[MINIGAMES_KEY] = true,
}

local retrievedKeys = {} -- Determines if the datastore has been retrieved for a given key.
local isRetrieving = {} -- Used to prevent multiple requests to the datastore at once.
local lastDatastoreRequest = {} -- Used to determine when to update the datastore.

local ServerData = {}

local replica = ReplicaService.NewReplica { -- Create a new replica for the cached server data for the client.
	ClassToken = ReplicaService.NewClassToken "ServerData",
	Data = Table.deepCopy(cachedData),
	Replication = "All",
}

-- Attempts to update the data at the given key using the given transform function.
-- Returns the success of the update and the error if it failed.
local function updateDataStore(key: string, transformFunction: (any) -> any)
	local success, err = DataStore.safeUpdate(serverDataStore, key, transformFunction)

	if success then
		transformFunction(cachedData[key])
		replica:SetValue({ key }, Table.copy(cachedData[key]))
	else
		warn("Failed to update datastore for key: ", key)
	end

	return success, err
end

-- Retrieves and the server data for the given key.
-- Returns with the success of the request and the data.
local function getKeyData(key: string)
	assert(key, "Key must be provided to retrieve datastore")
	assert(type(key) == "string", "Key must be a string. Received " .. typeof(key))

	if isRetrieving[key] then -- If the datastore is currently being retrieved, wait for it to finish.
		repeat
			task.wait()
		until not isRetrieving[key]

		return true, cachedData[key]
	end

	lastDatastoreRequest[key] = time() -- Update the last time the datastore was requested.
	isRetrieving[key] = true -- Set the key to retrieving. This prevents multiple requests to the datastore at once.

	local success, result = DataStore.safeGet(serverDataStore, key)

	if success then
		cachedData[key] = result or {}

		if result then replica:SetValue({ key }, Table.copy(cachedData[key])) end
	else
		warn("Failed to retrieve datastore for key: ", key)
	end

	isRetrieving[key] = false
	retrievedKeys[key] = success

	return success, cachedData[key]
end

--[[
	Attempts to reserve a server for a new location.

	Returns a promise that resolves with a table containing the server code and private server id or rejects with
	nothing.

	You may notice that creating new parties or minigames don't have a dedicated function in the namespace.
	That's because in both ServerData.addWorld and ServerData.reconcileWorlds, we create new location tables.
]]
local function newLocation(locationEnum: UserEnum)
	local function getLocationTable()
		return Promise.try(function()
			local locationInfo = Locations.info[locationEnum]

			local serverCode, privateServerId = TeleportService:ReserveServer(locationInfo.placeId)

			local locationTable = { -- Create the serverInfo.
				serverCode = serverCode,
				privateServerId = privateServerId,
			}

			return locationTable
		end)
	end

	return Promise.retry(getLocationTable, 5):await()
end

-- Returns the success and the data for the given key.
function ServerData.get(key: string)
	assert(typeof(key) == "string" and key ~= "", "Key must be provided to get data")

	if retrievedKeys[key] then
		return true, cachedData[key]
	else
		return getKeyData(key)
	end
end

-- Returns the retriaval success and data for the worlds key.
function ServerData.getWorlds(): (boolean, table)
	return ServerData.get(WORLDS_KEY)
end

-- Returns the retriaval success and data for the parties key.
function ServerData.getParties(partyType: UserEnum?)
	local success, result = ServerData.get(PARTIES_KEY)

	if success then
		return true, if partyType then result[partyType] or {} else result
	else
		return false, result
	end
end

-- Returns the retriaval success and data for the minigames key.
function ServerData.getMinigames(minigameType: UserEnum?)
	local success, result = ServerData.get(MINIGAMES_KEY)

	if success then
		return true, if minigameType then result[minigameType] or {} else result
	else
		return false, result
	end
end

-- Returns the retriaval success and data for the given `worldIndex`. Can return nil if the world doesn't exist.
function ServerData.getWorld(worldIndex: number)
	assert(type(worldIndex) == "number", "World index must be a number. Received " .. typeof(worldIndex))

	local success, data = ServerData.getWorlds()

	if success then
		return true, data[worldIndex]
	else
		return false, data
	end
end

-- Returns the retriaval success and data for the given `partyType` and `partyIndex`. Can return nil if the party doesn't exist.
function ServerData.getParty(partyType: UserEnum, partyIndex: number): (boolean, table)
	assert(type(partyIndex) == "number", "Party index must be a number. Received " .. typeof(partyIndex))

	local success, data = ServerData.getParties(partyType)

	if success then
		return true, data[partyIndex]
	else
		return false, data
	end
end

-- Returns the retriaval success and data for the given `minigameType` and `minigameIndex`. Can return nil if the minigame doesn't exist.
function ServerData.getMinigame(minigameType: UserEnum, minigameIndex: number)
	assert(type(minigameIndex) == "number", "Minigame index must be a number. Received " .. typeof(minigameIndex))

	local success, data = ServerData.getMinigames(minigameType)

	if success then
		return true, data[minigameIndex]
	else
		return false, data
	end
end

-- Returns the retriaval success and data for the given `worldIndex` and `locationEnum`. Can return nil if the location doesn't exist.
function ServerData.getLocation(worldIndex: number, locationEnum: UserEnum)
	assert(type(worldIndex) == "number", "World index must be a number. Received " .. typeof(worldIndex))

	local success, data = ServerData.getWorld(worldIndex)

	if success and data then
		return true, data.locations[locationEnum]
	else
		return false, data
	end
end

-- Returns the retriaval success and cachedData. This can be used to make sure all data is retrieved before using it.
function ServerData.getAll(): (boolean, table)
	return Promise.all({
		Promise.try(function()
			assert(ServerData.getWorlds())
		end),
		Promise.try(function()
			assert(ServerData.getParties())
		end),
		Promise.try(function()
			assert(ServerData.getMinigames())
		end),
	})
		:andThen(function()
			return cachedData
		end)
		:await() -- return the success and cachedData.
end

-- Attempts to add a world, returning a success value and a result that is either the world index or an error message.
--
-- **TODO** &mdash; Desynchronize location creation.
function ServerData.addWorld()
	local world = {
		locations = {},
	}

	local tasks = {} -- We want to create all locations asynchronously.

	for enum, _ in pairs(Locations.info) do -- We want each of these to run asynchronously.
		local promise = Promise.new(function(resolve, reject)
			local success, location = newLocation(enum)

			if not success then
				reject(location) -- Reject the promise with the error message.

				return
			end

			world.locations[enum] = location

			resolve()
		end)

		table.insert(tasks, promise)
	end

	local success, result = Promise.all(tasks):await() -- Wait for all locations to be created.

	if not success then
		warn("Failed to create locations: ", result)
		return
	end

	success, result = updateDataStore(WORLDS_KEY, function(worlds) -- Update the datastore.
		worlds = worlds or {}

		table.insert(worlds, world)

		return worlds
	end)

	if success then
		return true, #cachedData[WORLDS_KEY]
	else
		warn("Failed to add world: ", result)
		return success, result
	end
end

-- Attempts to add a party, returning a success value and a result that is either the party index or an error message.
function ServerData.addParty(partyType: UserEnum)
	assert(partyType, "Party type must be provided to add a party")

	local function try()
		return Promise.try(function()
			local serverCode, privateServerId = TeleportService:ReserveServer(Parties[partyType].placeId)

			return {
				serverCode = serverCode,
				privateServerId = privateServerId,
			}
		end)
	end

	local success, result = Promise.retry(try, 5):await()

	if not success then
		warn("Failed to add party: ", result)
		return success, result
	end

	success, result = updateDataStore(PARTIES_KEY, function(parties)
		parties = parties or {}

		parties[partyType] = parties[partyType] or {}

		table.insert(parties[partyType], result)

		return parties
	end)

	if success then
		return true, #cachedData[PARTIES_KEY][partyType]
	else
		warn("Failed to add party: ", result)
		return success, result
	end
end

-- Attempts to add a minigame server, returning a success value and a result that is either the minigame index or an error message.
function ServerData.addMinigame(minigameType: UserEnum)
	assert(minigameType, "Minigame type is nil")
	assert(Minigames[minigameType].minigameServerType == MinigameServerType.public, "Minigame must be public in order to add it to the server data.")

	local function try()
		return Promise.try(function()
			local serverCode, privateServerId = TeleportService:ReserveServer(Minigames[minigameType].placeId)

			return {
				serverCode = serverCode,
				privateServerId = privateServerId,
			}
		end)
	end

	local success, result = Promise.retry(try, 5):await()

	if not success then
		warn("Failed to add minigame: ", result)
		return success, result
	end

	success, result = updateDataStore(MINIGAMES_KEY, function(minigames)
		minigames = minigames or {}

		minigames[minigameType] = minigames[minigameType] or {}

		table.insert(minigames[minigameType], result)

		return minigames
	end)

	if success then
		return true, #cachedData[MINIGAMES_KEY][minigameType]
	else
		warn("Failed to add minigame: ", result)
		return success, result
	end
end

--[[
	Adds a home server to the Servers datastore.
	The key is the privateServerId, and the value is a serverIdentifier table:
	```lua
	{
		serverType = ServerTypeEnum.home,
		homeOwner = 123456789, -- The UserId of the player who owns the home.
	}
	```
	Returns a success value and an error message if the request failed.
]]
function ServerData.stampHomeServer(owner: Player)
	assert(PlayerDataManager.profileIsLoaded(owner), "Player profile is not loaded")
	
	local homeServerInfo = PlayerDataManager.viewPersistentDataAsync(owner.UserId).playerInfo.homeServerInfo
	local privateServerId = homeServerInfo.privateServerId

	assert(privateServerId, "Player does not have a home server")

	print("Stamping home server: ", privateServerId)

	local success, response = DataStore.safeSet(serverDataStore, privateServerId, {
		serverType = ServerTypeEnum.home,
		homeOwner = owner.UserId, -- Stamp the home server with the owner's UserId.
	})

	if success then
		cachedData[privateServerId] = { -- Update the cache.
			serverType = ServerTypeEnum.home,
			homeOwner = owner.UserId,
		}

		--[[
			We don't want to stamp the home server again if the player leaves and rejoins the minigame.
			We also don't want to stamp the home server if the player is already stamped.

			This may seem redundant, but it saves us from having to make a separate request to the datastore.
			(this is stored in the player's profile)
		]]
		PlayerDataManager.setValueProfileAsync(owner, { "playerInfo", "homeInfoStamped" }, true)
	else
		warn("Failed to stamp home server: ", response)
	end

	return success, response
end

--[[
	Attempts to get a server's identifier from the cache based on the provided privateServerId.
	If the server is not in the cache, it will be fetched from the datastore if onlySearchCache is false or nil.

	Note the difference between this and ServerData.get. This function returns this:
	```lua
	export type ServerIdentifier = {
		serverType: UserEnum, -- The type of server (world, party, minigame, home)
		jobId: string?, -- The jobId of the server (only for routing servers)
		worldIndex: number?, -- The index of the world in the worlds table (only for location servers)
		locationEnum: UserEnum?, -- The location enum of the location (only for location servers)
		homeOwner: number?, -- The UserId of the home owner (only for home servers)
		partyType: UserEnum?, -- The type of party (only for party servers)
		partyIndex: number?, -- The index of the party in the party type table (only for party servers)
		minigameType: UserEnum?, -- The type of minigame (only for minigame servers)
		minigameIndex: number?, -- The index of the minigame the server is for (public minigame servers)
		privateServerId: string?, -- The privateServerId of the server (instance minigame servers)
	}
	```
	This info is what actually characterizes the server instead of it being a serverCode or privateServerId.

	Returns a success value and a result that is either the server info or an error message.

	WARNING: This will not get the serverIdentifier for all servers, only those that need to use ServerData to identify themselves.
	For example, routing servers and independent minigame servers cannot use ServerData to identify themselves.
]]
function ServerData.getServerIdentifier(privateServerId: string, onlySearchCache: boolean)
	privateServerId = privateServerId or game.PrivateServerId

	local success, result = ServerData.getAll()

	if not success then
		warn("Failed to get all server info: ", result)
		return success, result
	end

	local info

	Table.recursiveIterate(cachedData, function(path, value)
		if type(value) == "table" and value.privateServerId == privateServerId then
			local constantKey = path[1]

			if constantKey == WORLDS_KEY then -- the path is [WORLDS_KEY, worldIndex, "locations", locationEnum]
				info = {
					serverType = ServerTypeEnum.location,
					worldIndex = path[2],
					locationEnum = path[4],
				}
			elseif constantKey == PARTIES_KEY then -- the path is [PARTIES_KEY, partyType, partyIndex]
				info = {
					serverType = ServerTypeEnum.party,
					partyType = path[2],
					partyIndex = path[3],
				}
			elseif constantKey == MINIGAMES_KEY then -- the path is [MINIGAMES_KEY, minigameType, minigameIndex]
				info = {
					serverType = ServerTypeEnum.minigame,
					minigameType = path[2],
					minigameIndex = path[3],
				}
			end
		end
	end)

	if info or onlySearchCache then return true, info end

	local success, serverInfo = ServerData.get(privateServerId)

	if not success then warn("Failed to get server info: ", success, serverInfo) end

	if success and serverInfo and Table.hasAnything(serverInfo) then
		return true, serverInfo
	else
		return false
	end
end

--[[
	Takes in a worldIndex along with an optional table with excluded locations.
	Based on population info, it will return the first available location.

	Returns a success value and a result that is either the location enum (if it exists) or an error message.

	**WARNING**: This function is not guaranteed to return a location, even if it succeeds.
	This would mean that the world simply has no available locations (all locations are full).
]]
function ServerData.findAvailableLocation(worldIndex: number, locationsExcluded: { UserEnum }?): (boolean, UserEnum?)
	assert(type(worldIndex) == "number", "World index must be a number. Got: " .. typeof(worldIndex))

	local locationEnum
	local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

	for _, locationType in pairs(Locations.priority) do
		if locationsExcluded and table.find(locationsExcluded, locationType) then continue end

		if worldPopulationInfo then
			local populationInfo = worldPopulationInfo.locations[locationType]

			if populationInfo then
				if populationInfo.recommended_emptySlots ~= 0 then
					locationEnum = locationType -- Location has free slots
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

	return true, locationEnum
end

--[[
	Finds an available world index based on population and chance.

	`forcedLocation` is an optional argument that restricts the search to worlds that have the location available.
	`worldsExcluded` is an optional argument that excludes the provided world indices from the search.

	Returns a success value and a result that is either the world index (if it exists) or an error message.
]]
function ServerData.findAvailableWorld(forcedLocation: { UserEnum }, worldsExcluded: { number }): (boolean, number)
	local success, worlds = ServerData.getWorlds()

	if not success then
		warn("Failed to get worlds: ", worlds)
		return success, worlds
	end

	local worldIndex
	do
		local rarities = {}

		for worldIndex, world in ipairs(worlds) do
			local worldPopulationInfo = LiveServerData.getWorldPopulationInfo(worldIndex)

			local worldIsSuitable = true

			if worldsExcluded and table.find(worldsExcluded, worldIndex) then worldIsSuitable = false end

			if worldIsSuitable and worldPopulationInfo then
				for locationEnum, _ in pairs(world.locations) do
					local locationPopulationInfo = worldPopulationInfo.locations[locationEnum]

					if
						locationPopulationInfo
						and (forcedLocation == locationEnum)
						and (locationPopulationInfo.max_emptySlots == 0)
					then
						worldIsSuitable = false
						break
					end
				end

				local success = ServerData.findAvailableLocation(worldIndex)

				if not success then worldIsSuitable = false end

				if worldPopulationInfo.recommended_emptySlots == 0 then worldIsSuitable = false end
			end

			if not worldIsSuitable then
				print("ServerData.findAvailableWorld: World " .. worldIndex .. " is not suitable")
				continue
			end

			local population = worldPopulationInfo and worldPopulationInfo.population or 0

			local chance
			do
				if population == 0 then
					chance = 0.001 -- Very low chance of empty worlds being chosen so players don't get stuck in empty worlds
				else
					chance = population
				end
			end

			-- print("ServerData.findAvailableWorld: World " .. worldIndex .. " has a chance of " .. chance)

			rarities[worldIndex] = chance
		end

		worldIndex = Math.weightedChance(rarities)
	end

	if worldIndex == nil then
		print "No suitable world found, creating new world"

		Table.print(worlds, "worlds")

		return ServerData.addWorld()
	end

	return true, worldIndex
end

--[[
	Finds an available party based on population and chance.

	`partyType` is the type of party to search for.

	Returns a success value and a result that is either the party index (if it exists) or an error message.
]]
function ServerData.findAvailableParty(partyType: UserEnum)
	assert(partyType, "Party type must be provided")

	local success, parties = ServerData.getParties(partyType)

	if not success or not parties then
		warn("Failed to get parties: ", parties)
		return success, parties
	end

	local partyIndex
	do
		local rarities = {}

		for partyIndex, _ in ipairs(parties) do
			local partyPopulationInfo = LiveServerData.getPartyPopulationInfo(partyType, partyIndex)

			local partyIsSuitable = true

			if partyPopulationInfo then
				if partyPopulationInfo.recommended_emptySlots == 0 then partyIsSuitable = false end
			end

			if not partyIsSuitable then
				print("ServerData.findAvailableParty: Party " .. partyIndex .. " is not suitable")
				continue
			end

			local population = partyPopulationInfo and partyPopulationInfo.population or 0

			local chance
			do
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
		print "No suitable party found, creating new party"

		return ServerData.addParty(partyType)
	end

	return true, partyIndex
end

--[[
	Finds an available minigame based on population and chance.

	`minigameType` is the type of minigame to search for.

	Returns a success value and a result that is either the minigame index (if it exists) or an error message.
]]
function ServerData.findAvailableMinigame(minigameType: UserEnum)
	assert(minigameType, "Minigame type must be provided")
	assert(Minigames[minigameType].minigameServerType)

	local success, minigames = ServerData.getMinigames(minigameType)

	if not success or not minigames then
		warn("Failed to get minigames: ", minigames)
		return success, minigames
	end

	local minigameIndex
	do
		local rarities = {}

		for minigameIndex, _ in ipairs(minigames) do
			local minigamePopulationInfo = LiveServerData.getMinigamePopulationInfo(minigameType, minigameIndex)

			local minigameIsSuitable = true

			if minigamePopulationInfo then
				if minigamePopulationInfo.recommended_emptySlots == 0 then minigameIsSuitable = false end
			end

			if not minigameIsSuitable then
				print("ServerData.findAvailableMinigame: Minigame " .. minigameIndex .. " is not suitable")
				continue
			end

			local population = minigamePopulationInfo and minigamePopulationInfo.population or 0

			local chance
			do
				if population == 0 then
					chance = 0.001
				else
					chance = population
				end
			end

			print("ServerData.findAvailableMinigame: Minigame " .. minigameIndex .. " has a chance of " .. chance)

			rarities[minigameIndex] = chance
		end

		minigameIndex = Math.weightedChance(rarities)
	end

	if minigameIndex == nil then
		print "No suitable minigame found, creating new minigame"

		return ServerData.addMinigame(minigameType)
	end

	return true, minigameIndex
end

--[[
	Finds an available world index and location by using `findAvailableWorld` and `findAvailableLocation`.

	`forcedLocation` is an optional argument that restricts the search to worlds that have the location available.
	`worldsExcluded` is an optional argument that excludes the provided world indices from the search.

	Returns a success value and result(s) that are either the world index and location (if they exist) or an error message.
]]
function ServerData.findAvailableWorldAndLocation(forcedLocation: UserEnum, worldsExcluded: { number }): Promise
	local success, worldIndex = ServerData.findAvailableWorld(forcedLocation, worldsExcluded)

	if not success then
		warn("ServerData.findAvailableWorldAndLocation: Error finding available world: " .. tostring(worldIndex))
		return success, worldIndex
	end

	local locationEnum

	if forcedLocation then
		locationEnum = forcedLocation
	else
		success, locationEnum = ServerData.findAvailableLocation(worldIndex)

		if not success then
			warn(
				"ServerData.findAvailableWorldAndLocation: Error finding available location: " .. tostring(locationEnum)
			)
			return success, locationEnum
		end
	end

	if not worldIndex or not locationEnum then
		warn "ServerData.findAvailableWorldAndLocation: worldIndex or locationEnum is nil."

		return false, "worldIndex or locationEnum is nil"
	else
		print(
			"ServerData.findAvailableWorldAndLocation: Found world " .. worldIndex .. " and location " .. locationEnum
		)
	end

	return true, worldIndex, locationEnum
end

--[[
	Reconciles the worlds in the data store with new locations.

	Always done **manually** in the live game.
]]
function ServerData.reconcileWorlds()
	local additions = {}
	local newLocations = {}

	local _, worlds = ServerData.getWorlds():await()

	for _ = 1, #worlds do
		for locationEnum, _ in pairs(Locations.info) do
			local locationTable = newLocations[locationEnum] or {}
			newLocations[locationEnum] = locationTable

			table.insert(locationTable, select(2, newLocation(locationEnum)))
		end
	end

	local function getNewLocation(locationEnum)
		local locationTable = newLocations[locationEnum]

		local newLocation = table.remove(locationTable, 1)

		return newLocation
	end

	updateDataStore(WORLDS_KEY, function(worlds)
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
	end)
end

task.spawn(function() -- Update the cache now and then every CACHE_COOLDOWN seconds
	local success, response = ServerData.getAll()

	if not success then warn("ServerData.getAll: Error getting all data: " .. tostring(response)) end

	RunService.Heartbeat:Connect(function()
		for constantKey, _ in pairs(constantKeys) do
			if time() - lastDatastoreRequest[constantKey] > CACHE_COOLDOWN then getKeyData(constantKey) end
		end
	end)
end)

return ServerData
