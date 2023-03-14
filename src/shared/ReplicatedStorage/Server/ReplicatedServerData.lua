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
		[GAMES_KEY] = {
			[gameType: UserEnum] = {
				[gameIndex: number] = {
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
		serverType: UserEnum, -- The type of server (location, party, game, etc.)
		jobId: string?, -- The jobId of the server (routing servers)
		worldIndex: number?, -- The index of the world the server is in (location servers)
		locationEnum: UserEnum?, -- The location of the server (location servers)
		homeOwner: number?, -- The userId of the player who owns the home (home servers)
		partyType: UserEnum?, -- The type of party the server is for (party servers)
		partyIndex: number?, -- The index of the party the server is for (party servers)
		gameType: UserEnum?, -- The type of game the server is for (game servers)
		gameIndex: number?, -- The index of the game the server is for (game servers)
	}
	```

]]

local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local GAMES_KEY = "games"

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

type ServerIdentifier = Types.ServerIdentifier
--#endregion

local serverDataValue = Value {}

local serverIdentifierPromise = Promise.new(function(resolve) -- Fat boy promise
	local privateServerId = ReplicaCollection.get("PrivateServerInfo").Data.privateServerId

	local disconnect

	local function find()
		local serverData = serverDataValue:get()

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
				elseif constantKey == GAMES_KEY then -- the path is [GAMES_KEY, gameType, gameIndex]
					resolve {
						gameType = path[2],
						gameIndex = path[3],
					}
				end
			end
		end)
	end

	disconnect = Observer(serverDataValue):onChange(find)

	find()
end)

local ReplicatedServerData = {}

--[[
	Returns a table with the currently replicated server data.
	Will act dynamically within a computed value.

	Note: Can be an empty table if the server data has not been replicated yet.
]]
function ReplicatedServerData.get()
	return serverDataValue:get()
end

--[[
	Returns the worlds table from the currently replicated server data.
	Will act dynamically within a computed value.

	WARNING: Can return nil.
]]
function ReplicatedServerData.getWorlds()
	return ReplicatedServerData.get()[WORLDS_KEY]
end

--[[
	Returns the parties table from the currently replicated server data.
	Will act dynamically within a computed value.

	WARNING: Can return nil.
]]
function ReplicatedServerData.getParties()
	return ReplicatedServerData.get()[PARTIES_KEY]
end

--[[
	Returns the games table from the currently replicated server data.
	Will act dynamically within a computed value.

	WARNING: Can return nil.
]]
function ReplicatedServerData.getGames()
	return ReplicatedServerData.get()[GAMES_KEY]
end

--[[
	Returns the world with the specified index from the currently replicated server data.
	Will act dynamically within a computed value.

	WARNING: Can return nil.
]]
function ReplicatedServerData.getWorld(worldIndex)
	assert(typeof(worldIndex) == "number", "worldIndex must be a number")

	local worlds = ReplicatedServerData.getWorlds()

	return worlds and worlds[worldIndex] or nil
end

--[[
	Returns whether the specified world has the specified location.
	Will act dynamically within a computed value.

	WARNING: Can return nil.
]]
function ReplicatedServerData.worldHasLocation(worldIndex, locationEnum)
	assert(typeof(worldIndex) == "number", "worldIndex must be a number")
	assert(locationEnum, "locationEnum must not be nil")

	local world = ReplicatedServerData.getWorld(worldIndex)

	if not world then return nil end

	return world.locations[locationEnum] ~= nil
end

--[[
	Returns the serverIdentifier of the server this script is running on.

	Structure:

	```lua
	export type ServerIdentifier = {
		serverType: UserEnum, -- The type of server (location, party, game, etc.)
		jobId: string?, -- The jobId of the server (routing servers)
		worldIndex: number?, -- The index of the world the server is in (location servers)
		locationEnum: UserEnum?, -- The location of the server (location servers)
		homeOwner: number?, -- The userId of the player who owns the home (home servers)
		partyType: UserEnum?, -- The type of party the server is for (party servers)
		partyIndex: number?, -- The index of the party the server is for (party servers)
		gameType: UserEnum?, -- The type of game the server is for (game servers)
		gameIndex: number?, -- The index of the game the server is for (game servers)
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
