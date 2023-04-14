--[[
	This script serves as a client-side interface to the server data.

	Server info is stored in the following format (see data structure below):
	```lua
	{
		privateServerId = privateServerId: string?,
		serverCode = serverCode: string?,
		[any] = any?
	}
	```
	The serverCode is passed into TeleportOptions.ReservedServerAccessCode when teleporting to the server.

	Data is replicated every 30 seconds.

	Structure of serverData:
	```lua
	serverData = {
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
	A serverIdentifier is a table that includes information about how to locate serverInfo within the data table.
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

	Example usage (not in computeds):
	```lua
	local parties = ReplicatedServerData.getParties()

	if not parties or not Table.hasAnything(parties) then
		warn("Parties have not replicated yet")
	end
	```

	Example usage (in computeds):
	```lua
	local Computed = Fusion.Computed

	Computed(function(use)
		local data = use(ReplicatedServerData.value)
		local withData = ReplicatedServerData.withData

		local world = withData.getWorld(data, 1)
	end)
	```lua
]]

local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local MINIGAMES_KEY = "minigames"

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local Promise = require(utilityFolder:WaitForChild "Promise")
local Table = require(utilityFolder:WaitForChild "Table")
local Types = require(utilityFolder:WaitForChild "Types")

local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local Value = Fusion.Value
local Observer = Fusion.Observer
local peek = Fusion.peek

type ServerIdentifier = Types.ServerIdentifier
type Use = Fusion.Use
--#endregion

local serverDataValue = Value {}

local serverIdentifierPromise = Promise.new(function(resolve) -- Fat boy promise
	local privateServerId = ReplicaCollection.get("SessionInfo").Data.privateServerId

	local disconnect

	local function find()
		local serverData = peek(serverDataValue)

		if serverData[privateServerId] then
			disconnect()
			resolve(serverData[privateServerId])
		end

		Table.recursiveIterate(serverData, function(path, value)
			if type(value) == "table" and value.privateServerId == privateServerId then
				disconnect()

				local constantKey = path[1]

				if constantKey == WORLDS_KEY then -- the path is [WORLDS_KEY, worldIndex, "locations", locationEnum]
					resolve {
						worldIndex = path[2],
						locationEnum = path[4],
					}
				elseif constantKey == PARTIES_KEY then -- the path is [PARTIES_KEY, partyType, partyIndex]
					resolve {
						partyType = path[2],
						partyIndex = path[3],
					}
				elseif constantKey == MINIGAMES_KEY then -- the path is [MINIGAMES_KEY, minigameType, minigameIndex]
					resolve {
						minigameType = path[2],
						minigameIndex = path[3],
					}
				end
			end
		end)
	end

	disconnect = Observer(serverDataValue):onChange(find)

	find()
end)



local ReplicatedServerData = {}
ReplicatedServerData.value = serverDataValue

local withData = {}
ReplicatedServerData.withData = withData

--[[
	Returns the worlds table with the currently replicated server data.
	Pass in a table to use as the data. (useful for computed values)

	Note: Can be an empty table if the server data has not been replicated yet.
]]
function withData.getWorlds(data)
	return data[WORLDS_KEY]
end

--[[
	Returns the parties table with the currently replicated server data.
	Pass in a table to use as the data. (useful for computed values)

	Note: Can be an empty table if the server data has not been replicated yet.
]]
function withData.getParties(data)
	return data[PARTIES_KEY]
end

--[[
	Returns the minigames table with the currently replicated server data.
	Pass in a table to use as the data. (useful for computed values)

	Note: Can be an empty table if the server data has not been replicated yet.
]]
function withData.getMinigames(data)
	return data[MINIGAMES_KEY]
end

--[[
	Returns the world with the specified index from the currently replicated server data.
	Pass in a table to use as the data. (useful for computed values)

	WARNING: Can return nil if the world has not been replicated yet. (or if the worldIndex is invalid)
]]
function withData.getWorld(data, worldIndex)
	assert(type(worldIndex) == "number", "worldIndex must be a number")

	local worlds = withData.getWorlds(data)

	return worlds and worlds[worldIndex]
end

--[[
	Returns whether the specified world has the specified location.
	Pass in a table to use as the data. (useful for computed values)

	WARNING: Can return nil if the world has not been replicated yet. (or if the worldIndex is invalid)
]]
function withData.worldHasLocation(data, worldIndex, locationEnum)
	assert(type(worldIndex) == "number", "worldIndex must be a number")
	assert(type(locationEnum) == "number", "locationEnum must be a number")

	local world = withData.getWorld(data, worldIndex)

	return world and world.locations[locationEnum]
end


--[[
	Returns a table with the currently replicated server data.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	Note: Can be an empty table if the server data has not been replicated yet.
]]
function ReplicatedServerData.get()
	return peek(serverDataValue)
end

--[[
	Returns the worlds table from the currently replicated server data.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	WARNING: Can return nil.
]]
function ReplicatedServerData.getWorlds()
	return withData.getWorlds(peek(serverDataValue))
end

--[[
	Returns the parties table from the currently replicated server data.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	WARNING: Can return nil.
]]
function ReplicatedServerData.getParties()
	return withData.getParties(peek(serverDataValue))
end

--[[
	Returns the minigames table from the currently replicated server data.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	WARNING: Can return nil.
]]
function ReplicatedServerData.getMinigames()
	return withData.getMinigames(peek(serverDataValue))
end

--[[
	Returns the world with the specified index from the currently replicated server data.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	WARNING: Can return nil.
]]
function ReplicatedServerData.getWorld(worldIndex)
	return withData.getWorld(peek(serverDataValue), worldIndex)
end

--[[
	Returns whether the specified world has the specified location.
	
	If you're using this in a computed value, consider using ReplicatedServerData.withData instead.
	(see the documentation at the top of the script)

	WARNING: Can return nil.
]]
function ReplicatedServerData.worldHasLocation(worldIndex, locationEnum)
	return withData.worldHasLocation(peek(serverDataValue), worldIndex, locationEnum)
end

--[[
	Returns the serverIdentifier of the server this script is running on. Yields.

	Structure:

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
]]
function ReplicatedServerData.getServerIdentifier(): ServerIdentifier
	return serverIdentifierPromise:expect()
end

task.spawn(function()
	local replica = ReplicaCollection.get "ServerData"

	replica:ListenToRaw(function()
		serverDataValue:set(replica.Data)
	end)

	serverDataValue:set(replica.Data)
end)

return ReplicatedServerData
