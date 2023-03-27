local TESTING_DONT_TELEPORT = false
local SERVER_BOOTING_ENABLED = false
local LISTEN_TIMEOUT = 20
local MAX_TELEPORT_GO_ATTEMPS = 5
local MAX_TELEPORTASYNC_TRIES = 5
local FLOOD_DELAY = 5
local RETRY_DELAY = 2

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local TeleportService = game:GetService "TeleportService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedFirstUtility = replicatedFirstShared.Utility
local serverManagement = serverStorageShared.ServerManagement
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local serverUtility = serverStorageShared.Utility

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local PlayerLocation = require(serverUtility.PlayerLocation)
local ServerData = require(serverManagement.ServerData)
local LiveServerData = require(serverFolder.LiveServerData)
local Table = require(replicatedFirstUtility.Table)
local WorldOrigin = require(serverFolder.WorldOrigin)
local HomeManager = require(serverStorageShared.Data.Inventory.HomeManager)
local HomeLockType = require(enumsFolder.HomeLockType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local Promise = require(replicatedFirstUtility.Promise)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local Types = require(replicatedFirstUtility.Types)
local PlayerSettings = require(serverStorageShared.Data.Settings.PlayerSettings)

type ServerIdentifier = Types.ServerIdentifier
type HomeServerInfo = Types.HomeServerInfo
type Promise = Types.Promise
type UserEnum = Types.UserEnum

local Teleport = {}
local Authorize = {}

Teleport.Authorize = Authorize

--[[
	Returns a TeleportOptions object outfitted with the default data. This includes the worldOrigin and locationFrom.
	If the player is in a location server, the locationFrom will be set to the location of the server.
	Otherwise, it'll be nil.

	Pass in an optional table to append to the teleport data.

	```lua
	local teleportOptions = Teleport.getOptions(player, { teleportData = "here" })
	```
]]
function Teleport.getOptions(player: Player, teleportData: {}?)
	local worldIndex = WorldOrigin.get(player)
	local locationEnum

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
		locationEnum = LocalServerInfo.getServerIdentifier().locationEnum
	end

	local teleportOptions = Instance.new "TeleportOptions"

	teleportOptions:SetTeleportData(Table.merge(teleportData, {
		locationFrom = locationEnum,
		worldOrigin = worldIndex,
	}))

	return teleportOptions
end

--[[
	Recieves players, a placeId, teleportOptions, and callback functions for success and failure.
	* Returns a success boolean and a table of promises for each player that resolve when the player has successfully teleported,
	or reject if the player fails to teleport.
	* Rejected promises will return an Enum.TeleportResult or TeleportResponseType (See possible responses below)
	* The success boolean is only for non-teleport errors. If a teleport fails, that player's promise will reject.
	* If success is false, the promises table will instead be a teleport response type. See TeleportResponseType.lua.

	The returned promise table looks like this:

	```lua
	{
		[Player] = Promise,
		[Player] = Promise,
		[Player] = Promise,
	} | TeleportResponseType
	```

	```lua
	local success, promises = Teleport.go(
		player,
		123456789, -- placeId
		Instance.new("TeleportOptions"),
	)

	if success and promises then
		for player, promise in promises do
			promise:andThen(function()
				print(player.Name, "teleported successfully!")
			end):catch(function(result: Enum.TeleportResult)
				print(player.Name, "failed to teleport with result", result)
			end)
		end
	else
		print("Teleport failed with response type: ", promises) -- `promises` is the response type in this case
	end
	```

	If you want to teleport multiple players at once, pass in a table of players.

	```lua
	local success, promises = Teleport.go(
		{ player1, player2, player3 },
		123456789, -- placeId
		Instance.new("TeleportOptions"),
	)
	```

	Possible responses (rejected values) for player promises:

	```lua
	TeleportResponseType.error -- An error occurred while trying to teleport
	Enum.TeleportResult.Failure -- The player failed to teleport
	Enum.TeleportResult.Flooded -- There were too many recent teleport requests
	Enum.TeleportResult.GameEnded -- The destination game has ended
	Enum.TeleportResult.GameFull -- The destination game is full
	Enum.TeleportResult.GameNotFound -- The destination game was not found
	Enum.TeleportResult.IsTeleporting -- The player is already teleporting
	Enum.TeleportResult.Unauthorized -- Unauthorized request
	```

	You don't need to check for every single response.
	Typically, you would only need to check for Flooded, GameFull, Failure.
	You can treat all other responses as a generic failure.
]]
function Teleport.go(
	players: { Player } | Player,
	placeId: number,
	teleportOptions: TeleportOptions | nil
): (boolean, { [Player]: Promise } | typeof(TeleportResponseType))
	players = if type(players) == "table" then players else { players }

	teleportOptions = teleportOptions or Teleport.getOptions(players[1])

	local function teleportAsync()
		return Promise.try(function()
			return if not TESTING_DONT_TELEPORT
				then TeleportService:TeleportAsync(placeId, players, teleportOptions)
				else print "Teleported!"
		end)
	end

	local function attemptTeleport(attemptsLeft: number)
		attemptsLeft -= 1

		local success = Promise.retryWithDelay(teleportAsync, MAX_TELEPORTASYNC_TRIES, RETRY_DELAY):await()

		if not success then
			warn("Teleport.go: failed to teleport players after", MAX_TELEPORTASYNC_TRIES, "retries")
			return false, TeleportResponseType.error
		end

		local function listen(player)
			return Promise.race({
				Promise.fromEvent(TeleportService.TeleportInitFailed, function(initFailedPlayer)
					return initFailedPlayer == player
				end),

				Promise.fromEvent(Players.PlayerRemoving, function(removingPlayer)
					return removingPlayer == player
				end),

				if TESTING_DONT_TELEPORT then Promise.delay(1) else nil,
			})
				:timeout(LISTEN_TIMEOUT)
				:andThen(function(_, teleportResult)
					if teleportResult then return Promise.reject(teleportResult) end
				end)
		end

		local promises = {}

		for _, player in pairs(players) do
			local listener = listen(player):catch(function(teleportResult)
				if
					teleportResult == Enum.TeleportResult.GameFull
					or teleportResult == Enum.TeleportResult.IsTeleporting
				then
					return Promise.reject(teleportResult)
				elseif teleportResult == Enum.TeleportResult.Flooded then
					task.wait(FLOOD_DELAY)
				end

				if attemptsLeft <= 0 then return Promise.reject(teleportResult) end

				local success, response = attemptTeleport(attemptsLeft)

				if not success then return Promise.reject(response) end

				return response[player]
			end)

			promises[player] = listener
		end

		return true, promises
	end

	return attemptTeleport(MAX_TELEPORT_GO_ATTEMPS)
end

--[[
	Authorizes a player to teleport to a location in a world. Used to verify that parameters are valid for teleporting to a location.
	- `worldIndex` is optional. If not provided, the player's current world will be used.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.
	This will return a worldIndex in place of the TeleportResponseType if authorization is successful.

	```lua
	local isAllowed, responseType = Authorize.toLocation({Player}, worldIndex)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toLocation(
	players: { Player } | Player,
	locationEnum,
	worldIndex: number?
): (boolean, typeof(TeleportResponseType) | number)
	assert(players and locationEnum, "Teleport.toLocation: missing argument")
	players = if type(players) == "table" then players else { players }

	local targetPlayer = players[1]

	local success, worlds = ServerData.getWorlds()

	if not success then
		warn "locationTable.teleportToLocation: failed to get worlds"
		return false, TeleportResponseType.error
	end

	if worldIndex then
		local worldTable = worlds[worldIndex]
		local locationTable = worldTable.locations[locationEnum]

		if not locationTable then
			warn(
				"locationTable.teleportToLocation: Location "
					.. locationEnum
					.. " does not exist in world "
					.. worldIndex
			)
			return false, TeleportResponseType.invalid
		end

		local isFull = LiveServerData.isLocationFull(worldIndex, locationEnum, #players)

		if isFull then
			warn "locationTable.teleportToLocation: location is full"
			return false, TeleportResponseType.full
		end

		return true, worldIndex
	end

	if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isWorldBased) then
		warn "locationTable.teleportToLocation: worldIndex is required for non-world-based servers"
		return false, TeleportResponseType.invalid
	end

	local worldIndexOrigin = WorldOrigin.get(targetPlayer)

	-- Check if the location is full. If it is, find an open world if the player has the setting enabled.

	if LiveServerData.isLocationFull(worldIndexOrigin, locationEnum, #players) then
		local success, findOpenWorld = PlayerSettings.getSetting(targetPlayer, "findOpenWorld")

		if not success then
			warn "locationTable.teleportToLocation: failed to get findOpenWorld setting"
			return false, TeleportResponseType.error
		end

		if findOpenWorld then
			local success, worldIndex = ServerData.findAvailableWorld(locationEnum)

			if not success then
				warn "locationTable.teleportToLocation: failed to find available world"
				return false, TeleportResponseType.error
			end

			return true, worldIndex
		else
			warn "locationTable.teleportToLocation: location is full"
			return false, TeleportResponseType.full
		end
	end

	local world = worlds[worldIndexOrigin]

	if not world then
		warn "Teleport.teleportToLocation: world does not exist"
		return false, TeleportResponseType.invalid
	end

	local location = world.locations[locationEnum]

	if not location then
		warn "Teleport.teleportToLocation: location does not exist"
		return false, TeleportResponseType.invalid
	end

	return true, worldIndexOrigin
end

--[[
	Authorizes a player to teleport to a world. Used to verify that parameters are valid for teleporting to a world.
	- `locationsExcluded` is optional. If provided, locationEnums in the table will be excluded from the possible locations to teleport to.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.
	This will return the generated location enum in place of the TeleportResponseType if authorization is successful.

	```lua
	local isAllowed, responseType = Authorize.toLocation({Player}, worldIndex, locationsExcluded)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toWorld(
	players: { Player } | Player,
	worldIndex: number,
	locationsExcluded: { number } | nil
): (boolean, typeof(TeleportResponseType) | number, UserEnum)
	assert(players and worldIndex, "Teleport.toWorld: missing argument")
	players = if type(players) == "table" then players else { players }

	local success, worlds = ServerData.getWorlds()

	if not success then
		warn "Teleport.toWorld: failed to get worlds"
		return false, TeleportResponseType.error
	end

	local worldTable = worlds[worldIndex]

	if not worldTable then
		warn "Teleport.toWorld: world does not exist"
		return false, TeleportResponseType.invalid
	end

	local isFull = LiveServerData.isWorldFull(worldIndex, #players)

	if isFull then
		warn "Teleport.toWorld: world is full"
		return false, TeleportResponseType.full
	end

	local success, locationEnum = ServerData.findAvailableLocation(worldIndex, locationsExcluded)

	if not success then
		warn "Teleport.toWorld: no available locations"
		return false, TeleportResponseType.full
	end

	return true, locationEnum
end

--[[
	Authorizes a player to teleport to a party. Used to verify that parameters are valid for teleporting to a party.
	- `partyIndex` is optional. If not provided, the player's current party will be used.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.
	This will return a partyIndex in place of the TeleportResponseType if authorization is successful.

	```lua
	local isAllowed, responseType = Authorize.toParty({Player}, partyType, partyIndex)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toParty(
	players: { Player } | Player,
	partyType: number,
	partyIndex: number?
): (boolean, typeof(TeleportResponseType) | number)
	assert(players and partyType, "Teleport.toParty: missing argument")
	players = if type(players) == "table" then players else { players }

	if not partyIndex then
		local success
		success, partyIndex = ServerData.findAvailableParty(partyType)

		if not success then
			warn "Teleport.toParty: no available parties"
			return false, TeleportResponseType.full
		end
	end

	local isFull = LiveServerData.isPartyFull(partyType, partyIndex, #players)

	if isFull then
		warn "Teleport.toParty: party is full"
		return false, TeleportResponseType.full
	end

	local success, data = ServerData.getParty(partyType, partyIndex)

	if not success or not data then
		warn "Teleport.toParty: party does not exist"
		return false, TeleportResponseType.invalid
	end

	return true, partyIndex
end

--[[
	Authorizes a player to teleport to a home. Used to verify that parameters are valid for teleporting to a home.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.
	This will return a HomeServerInfo in place of the TeleportResponseType if authorization is successful.

	```lua
	local isAllowed, responseType = Authorize.toHome(Player, homeOwnerUserId)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toHome(
	player: Player,
	homeOwnerUserId: number
): (boolean, typeof(TeleportResponseType) | HomeServerInfo)
	assert(player and homeOwnerUserId, "Teleport.toHome: missing argument")

	if player.UserId ~= homeOwnerUserId then -- If the player is not the destination home owner
		local isHomeFull = LiveServerData.isHomeFull(homeOwnerUserId)

		if isHomeFull then
			warn "Teleport.toHome: home is full"
			return false, TeleportResponseType.full
		end

		local success, isFriendsWith = pcall(function()
			return player:IsFriendsWith(homeOwnerUserId)
		end)

		if not success then
			warn "Teleport.toHome: failed to check if player is friends with home owner"
			return false, TeleportResponseType.error
		end

		if not isFriendsWith then
			warn "Teleport.toHome: home is locked"
			return false, TeleportResponseType.invalid
		end
	end

	local homeServerInfo = HomeManager.getHomeServerInfo(homeOwnerUserId)

	if not homeServerInfo then
		warn "Teleport.toHome: home does not exist"
		return false, TeleportResponseType.invalid
	end

	local success, isStamped = HomeManager.isHomeIdentifierStamped(homeOwnerUserId)

	if not success then
		warn "Teleport.toHome: failed to check if home is stamped"
		return false, TeleportResponseType.error
	end

	if not isStamped then
		warn "Teleport.toHome: home is not stamped"
		return false, TeleportResponseType.invalid
	end

	return true, homeServerInfo
end

--[[
	Authorizes a player to teleport to a location. Used to verify that parameters are valid for teleporting to a location.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.
	This will return special values in place of the TeleportResponseType if authorization is successful. These values vary depending on the server type
	of the destination player.

	* The server type is always the second argument assuming the first argument is true (success boolean)

	The next arguments:

	* For locations: the worldIndex and locationEnum of the destination player.
	* For parties: the partyType and partyIndex of the destination player.
	* For homes: the homeServerInfo of the destination player.

	```lua
	local isAllowed, responseType = Authorize.toLocation({Player}, locationEnum, worldIndex)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toPlayer(players: { Player } | Player, targetPlayer: number)
	players = if type(players) == "table" then players else { players }

	local serverIdentifier = PlayerLocation.get(targetPlayer)

	if not serverIdentifier then
		warn "Teleport.toPlayer: player is not in a server"

		return false, TeleportResponseType.invalid
	end

	local serverType = serverIdentifier.serverType

	for _, playerInServer in pairs(Players:GetPlayers()) do
		if playerInServer.UserId == targetPlayer then
			warn "Following player is in server"
			return false, TeleportResponseType.invalid
		end
	end

	if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isWorldBased, serverType) then
		warn "Teleport.toPlayer: server is not world based"

		return false, TeleportResponseType.invalid
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
		local isAllowed, responseType =
			Authorize.toLocation(players, serverIdentifier.locationEnum, serverIdentifier.worldIndex)

		if not isAllowed then
			warn "Teleport.toPlayer: unauthorized to teleport to location"

			return false, responseType
		end

		return true, serverType, serverIdentifier.locationEnum, serverIdentifier.worldIndex
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
		local isAllowed, responseType =
			Authorize.toParty(players, serverIdentifier.partyType, serverIdentifier.partyIndex)

		if not isAllowed then
			warn "Teleport.toPlayer: unauthorized to teleport to party"

			return false, responseType
		end

		return true, serverType, serverIdentifier.partyType, serverIdentifier.partyIndex
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, serverType) then
		if #players > 1 then
			warn "Teleport.toPlayer: cannot teleport multiple players to a home"

			return false, TeleportResponseType.invalid
		end

		local isAllowed, responseType = Authorize.toHome(players[1], serverIdentifier.homeOwner)

		if not isAllowed then
			warn "Teleport.toPlayer: unauthorized to teleport to home"

			return false, responseType
		end

		return true, serverType, serverIdentifier.homeOwner
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame, serverType) then
		return
	else
		warn "Teleport.toPlayer: server is not a valid server type"

		return false, TeleportResponseType.invalid
	end
end

--[[
	Teleports a player or a set of players to a location in a world.
	- `worldIndex` is optional. If not provided, the (target) player's current world will be used.

	Returns a success boolean and a table of promises that resolve when the teleport is complete successfully.
	See Teleport.go for more information.

	If success is false, the second value will be a TeleportResponseType.
]]
function Teleport.toLocation(
	players: { Player } | Player,
	locationEnum: number,
	worldIndex: number | nil
): (boolean, { [Player]: Promise } | typeof(TeleportResponseType))
	players = if type(players) == "table" then players else { players }
	local targetPlayer = players[1]
	local locationInfo = Locations.info[locationEnum]
	local placeId = locationInfo.placeId

	local isAllowed, responseType = Authorize.toLocation(players, locationEnum, worldIndex)

	if not isAllowed then
		warn("Teleport.toLocation: failed to authorize teleport to location ", locationEnum)

		return false, responseType
	end

	worldIndex = responseType

	local success, worlds = ServerData.getWorlds()

	if not success or not worlds then
		warn "Teleport.toLocation: failed to get worlds"

		return false, TeleportResponseType.error
	end

	local location = worlds[worldIndex].locations[locationEnum]

	if not location then
		warn "Teleport.toLocation: failed to get location"

		return false, TeleportResponseType.error
	end

	local teleportOptions = Teleport.getOptions(targetPlayer)
	teleportOptions.ReservedServerAccessCode = location.serverCode

	return Teleport.go(players, placeId, teleportOptions)
end

--[[
	Teleports a player or a set of players to a specified world.
	- locationsExcluded is a table of locations that should be excluded from the teleport.
	Used in cases where you'd want to restrict a certain location from being teleported to.

	Returns a success boolean and a table of promises that resolve when the teleport is complete successfully for each player.
	See Teleport.go for more information.

	If success is false, the second value will be a TeleportResponseType.
]]
function Teleport.toWorld(players: { Player } | Player, worldIndex: number, locationsExcluded: { number } | nil)
	assert(
		players and worldIndex,
		"Teleport.toWorld: missing argument: " .. (not players and "players" or "worldIndex")
	)

	players = if type(players) == "table" then players else { players }

	local isAuthorized, locationEnum = Authorize.toWorld(players, worldIndex, locationsExcluded)

	if not isAuthorized then
		warn("Teleport.toWorld: failed to authorize teleport to world " .. worldIndex)

		return false, locationEnum
	end

	local success, promiseTable = Teleport.toLocation(players, locationEnum, worldIndex)

	if not success then
		warn("Teleport.toWorld: failed to teleport to location ", locationEnum)

		return false, promiseTable -- promiseTable is actually a TeleportResponseType
	end

	--[[
		We're going to be using Table.map here to edit the promises in the promiseTable.
		For each promise, if the teleport fails, we'll try to find another location to teleport to.
		Finally, we'll return the newly-edited promiseTable.
	]]
	return true, Table.map(promiseTable, function(player: Player, promise: Promise)
		return promise:catch(function(teleportResult: Enum.TeleportResult)
			if teleportResult == Enum.TeleportResult.GameFull then
				locationsExcluded = Table.append(locationsExcluded, { locationEnum })

				local success, location = ServerData.findAvailableLocation(worldIndex, locationsExcluded)

				if not success or not location then
					warn "Teleport.toWorld: failed to find available location"

					return Promise.reject(teleportResult)
				end

				local success, result = Teleport.toLocation(player, location, worldIndex)

				if success then
					return result[player]
				else
					warn("Teleport.toWorld: failed to teleport to location ", location)

					return Promise.reject(result) -- result is a TeleportResponseType or a table of promises
				end
			end

			return Promise.reject(teleportResult)
		end)
	end)
end

--[[
	Teleports a player or a set of players to a party.
	- partyIndex is optional. If not provided, an available party will be found.

	Returns a success boolean and a table of promises that resolve when the teleport is complete successfully for each player.
	See Teleport.go for more information (it retruns what Teleport.go does).
]]
function Teleport.toParty(
	players: Player | { Player },
	partyType: number,
	partyIndex: number?
)
	players = if type(players) == "table" then players else { players }

	local isAllowed, response = Authorize.toParty(players, partyType, partyIndex)

	if not isAllowed then
		warn("Teleport.toParty: failed to authorize teleport to party " .. partyType)

		return false, response
	end

	partyIndex = partyIndex or response

	local success, party = ServerData.getParty(partyType, partyIndex)

	if not success or not party then
		warn "Teleport.toParty: failed to get party"

		return false, TeleportResponseType.error
	end

	local code = party.serverCode
	local targetPlayer = players[1]

	local teleportOptions = Teleport.getOptions(targetPlayer)
	teleportOptions.ReservedServerAccessCode = code

	return Teleport.go(players, Parties[partyType].placeId, teleportOptions)
end

--[[
	Teleports a player or a set of players to a home.
	- `homeOwnerUserId` is the user ID of the player who owns the home.
	- If `homeOwnerUserId` is not provided, the player will be teleported to their own home.

	Returns a success boolean and a table of promises that resolve when the
	teleport is complete successfully for each player.
	See Teleport.go for more information (it retruns what Teleport.go does).
]]

function Teleport.toHome(
	player: Player,
	homeOwnerUserId: number?
)
	assert(player, "Teleport.toHome: missing argument: player")

	homeOwnerUserId = homeOwnerUserId or player.UserId

	local isAllowed, response = Authorize.toHome(player, homeOwnerUserId)

	if not isAllowed then
		warn("Teleport.toHome: failed to authorize teleport to home ", homeOwnerUserId)

		return false, response
	end

	local homeServerInfo = response

	local teleportOptions = Teleport.getOptions(player)
	teleportOptions.ReservedServerAccessCode = homeServerInfo.serverCode

	return Teleport.go(player, GameSettings.homePlaceId, teleportOptions)
end

--[[
	Teleports a player or a set of players to a player.

	Returns a success boolean and a table of promises that resolve when the teleport is
	complete successfully for each player.
	See Teleport.go for more information (this retruns what Teleport.go does).
]]
function Teleport.toPlayer(
	players: { Player } | Player,
	targetPlayerId: number
)
	assert(players and targetPlayerId, "Teleport.toPlayer: missing argument")

	players = if type(players) == "table" then players else { players }

	-- The arguments here are ambiguous and open to interpretation based on the destination server type.
	local isAllowed, arg1, arg2, arg3 = Authorize.toPlayer(players, targetPlayerId)

	if not isAllowed then
		warn("Teleport.toPlayer: failed to authorize teleport to player " .. targetPlayerId)

		return false, arg1
	end

	local serverType = arg1

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
		local locationEnum, worldIndex = arg2, arg3

		return Teleport.toLocation(players, locationEnum, worldIndex)
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
		local partyType, partyIndex = arg2, arg3

		return Teleport.toParty(players, partyType, partyIndex)
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, serverType) then
		-- If there are multiple players, we can't teleport them to a home.
		if #players > 1 then
			warn("Teleport.toPlayer: cannot teleport multiple players to a home")

			return false, TeleportResponseType.invalid
		end

		return Teleport.toHome(players[1], targetPlayerId)
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame, serverType) then
		return
	end
end

--[[
	Teleports a player or a set of players to the starting (routing) place.
	Should only be used if an error occurs.
	A reason can be provided to display to the player when they rejoin.

	Returns nothing. Expect the player to be kicked if the teleport fails.
]]
function Teleport.rejoin(
	players: Player | { Player },
	reason: string?
)
	players = if type(players) == "table" then players else { players }

	local rejoinFailedText = "[REJOIN FAILED] " .. (reason or "Unspecified reason")

	local targetPlayer = players[1]

	warn("REJOIN: " .. reason)

	local teleportOptions = Teleport.getOptions(targetPlayer, {
		rejoinReason = reason,
	})

	local success, result = Teleport.go(
		players,
		GameSettings.routePlaceId,
		teleportOptions
	)

	if success then
		for player, promise in result do
			promise:catch(function()
				player:Kick(rejoinFailedText)
			end)
		end
	else
		warn("Teleport.rejoin failed: " .. result)

		for _, player in pairs(players) do
			player:Kick(rejoinFailedText)
		end
	end
end

--[[
	Calls Teleport.rejoin for every player in the game and all players that join.
	Should only be used if a critical server error occurs.
	Always specify a reason.
]]
function Teleport.bootServer(reason)
	if not SERVER_BOOTING_ENABLED then
		warn("SERVER BOOT: " .. reason)
		return
	end

	local function boot()
		Teleport.rejoin(Players:GetPlayers(), reason)
	end

	Players.PlayerAdded:Connect(boot)
	boot()
end

return Teleport
