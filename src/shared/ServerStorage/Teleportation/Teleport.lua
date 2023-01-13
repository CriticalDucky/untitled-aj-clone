local LISTEN_TIMEOUT = 20
local MAX_TELEPORT_ATTEMPS = 5
local FLOOD_DELAY = 5
local RETRY_DELAY = 2
local MAX_RETRIES = 5

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedFirstUtility = replicatedFirstShared.Utility
local serverManagement = serverStorageShared.ServerManagement
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local serverUtility = serverStorageShared.Utility
local teleportationFolder = serverStorageShared.Teleportation

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local Games = require(serverFolder.Games)
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

type onFailCallbackParam = (Player, Enum.TeleportResult) -> nil | { (Player, Enum.TeleportResult) -> nil } | nil
type onSuccessCallbackParam = (Player) -> nil | { (Player) -> nil } | nil

local Teleport = {}
local Authorize = {}

--[[
    Returns a promise that resolves a TeleportOptions object.
    The TeleportOptions' teleportData contains the worldOrigin and locationFrom for the player.
    If the player is in a location server, the locationFrom will be set to the location of the server.
]]
function Teleport.getOptions(player: Player, teleportData)
	return WorldOrigin.get(player)
		:andThen(function(worldIndex)
			if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
				return LocalServerInfo.getServerInfo():andThen(function(serverInfo)
					return worldIndex, serverInfo.locationEnum
				end)
			else
				return worldIndex
			end
		end)
		:andThen(function(worldIndex, locationEnum)
			local teleportOptions = Instance.new("TeleportOptions")

			teleportOptions:SetTeleportData(Table.append(teleportData, {
				locationFrom = locationEnum,
				worldOrigin = worldIndex,
			}))

			return teleportOptions
		end)
		:catch(function()
			return Promise.reject(TeleportResponseType.teleportError)
		end)
end

--[[
    Recieves players, a placeId, teleportOptions, and callback functions for success and failure.
    Resolves with a table of promises, one for each player, that resolve when the player has successfully teleported.

    onFail functions are called with the player and the teleport result. The teleport result is an Enum.TeleportResult.

    Note: The promise returned by Teleport.go can reject.

    ```lua
    Teleport.go(
        player,
        123456789,
        Instance.new("TeleportOptions"),
        function(player, teleportResult)
            print("Handle teleport failure here")
        end,
        {
            function(player, teleportResult)
                print("Handle teleport success here")
            end)
        }
    ) --> Promise
    ```
]]
function Teleport.go(
	players: { Player } | Player,
	placeId: number,
	teleportOptions: TeleportOptions | nil,
	onFail: onFailCallbackParam,
	onSuccess: onSuccessCallbackParam,
	_triesLeft: nil | number,
	_isRecursion: nil | boolean
)
	players = if type(players) == "table" then players else { players }
	onFail = if type(onFail) == "table" then onFail else { onFail }
	onSuccess = if type(onSuccess) == "table" then onSuccess else { onSuccess }

	return Promise.new(function(resolve, reject)
		if teleportOptions == nil then
			local success, options = Teleport.getOptions(players[1]):await()

			if not success then
				return Promise.reject(TeleportResponseType.teleportError)
			end

			teleportOptions = options
		end

		if _triesLeft <= 0 then
			return reject(TeleportResponseType.teleportError)
		end

		local function attemptTeleport()
			return Promise.new(function(resolveAttempt, rejectAttempt)
				local success, result = pcall(function()
					return TeleportService:TeleportAsync(placeId, players, teleportOptions)
				end);

				(if success then resolveAttempt else rejectAttempt)(result)
			end)
		end

		Promise.retryWithDelay(attemptTeleport, MAX_RETRIES, RETRY_DELAY)
			:andThen(function()
				local function listen(player)
					return Promise.new(function(resolveTicket, rejectTicket)
						Promise.race({
							Promise.fromEvent(TeleportService.TeleportInitFailed, function(initFailedPlayer)
								return initFailedPlayer == player
							end),

							Promise.fromEvent(Players.PlayerRemoving, function(removingPlayer)
								return removingPlayer == player
							end),
						})
							:timeout(LISTEN_TIMEOUT)
							:andThen(function(_, teleportResult)
								if teleportResult then
									rejectTicket(teleportResult)
								else
									resolveTicket(TeleportResponseType.success)
								end
							end)
							:catch(function(err)
								warn("Teleport.go: error: " .. tostring(err))

								rejectTicket(TeleportResponseType.teleportError)
							end)
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

						return Teleport.go(
							player,
							placeId,
							teleportOptions,
							onSuccess,
							onFail,
							(_triesLeft or MAX_TELEPORT_ATTEMPS) - 1,
							true
						):andThen(function(promiseTable)
							return promiseTable[player]
						end)
					end)

					if not _isRecursion then -- only call callbacks on the first call
						listener
							:andThen(function(...)
								for _, callback in pairs(onSuccess) do
									callback(player, ...)
								end
							end)
							:catch(function(...)
								for _, callback in pairs(onFail) do
									callback(player, ...)
								end
							end)
					end

					promises[player] = listener
				end

				resolve(promises)
			end)
			:catch(function(err)
				warn("Teleport.go: error: " .. tostring(err))

				reject(TeleportResponseType.teleportError)
			end)
	end)
end

--[[
    Authorizes a player to teleport to a location in a world. Used to verify that parameters are valid for teleporting to a location.
    - `worldIndex` is optional. If not provided, the player's current world will be used.
]]
function Authorize.toLocation(players: { Player } | Player, locationEnum, worldIndex: number)
	return Promise.new(function(resolve, reject)
		assert(players and locationEnum, "Teleport.toLocation: missing argument")
		players = if type(players) == "table" then players else { players }

		local targetPlayer = players[1]

		ServerData.getWorlds()
			:andThen(function(worlds)
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
						return reject(TeleportResponseType.invalid)
					end

					LiveServerData.isLocationFull(worldIndex, locationEnum, #players)
						:andThen(function(isFull)
							if isFull then
								warn("locationTable.teleportToLocation: location is full")
								return reject(TeleportResponseType.full)
							end

							resolve(worldIndex)
						end)
						:catch(function(err)
							warn("locationTable.teleportToLocation: error: " .. tostring(err))
							reject(TeleportResponseType.teleportError)
						end)
				else
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isWorldBased) then
						WorldOrigin.get(targetPlayer)
							:andThen(function(worldIndex)
								return LiveServerData.isLocationFull(worldIndex, locationEnum, #players)
									:andThen(function(isFull)
										if isFull then
											warn("locationTable.teleportToLocation: location is full")
											return Promise.reject(TeleportResponseType.full)
										end
									end)
							end)
							:andThen(function()
								local world = worlds[worldIndex]

								if not world then
									warn("Teleport.teleportToLocation: world does not exist")
									return Promise.reject(TeleportResponseType.invalid)
								end

								local location = world.locations[locationEnum]

								if not location then
									warn("Teleport.teleportToLocation: location does not exist")
									return Promise.reject(TeleportResponseType.invalid)
								end
							end)
							:andThenCall(resolve, worldIndex)
							:catch(function(err)
								warn("locationTable.teleportToLocation: error: " .. tostring(err))
								reject(TeleportResponseType.teleportError)
							end)
					else
						warn("Cannot teleport to location from a non-world based server")
						return reject(TeleportResponseType.invalid)
					end
				end
			end)
			:catch(function(err)
				warn("locationTable.teleportToLocation: error: " .. tostring(err))
				reject(TeleportResponseType.teleportError)
			end)
	end)
end

--[[
    Authorizes a player to teleport to a world. Used to verify that parameters are valid for teleporting to a world.
    - `locationsExcluded` is optional. If provided, locationEnums in the table will be excluded from the possible locations to teleport to.
]]
function Authorize.toWorld(players: { Player } | Player, worldIndex: number, locationsExcluded: { number } | nil)
	return Promise.new(function(resolve, reject)
		assert(players and worldIndex, "Teleport.toWorld: missing argument")
		players = if type(players) == "table" then players else { players }

		ServerData.getWorlds()
			:andThen(function(worlds)
				local worldTable = worlds[worldIndex]

				if not worldTable then
					warn("Teleport.toWorld: world does not exist")
					return reject(TeleportResponseType.invalid)
				end

				LiveServerData.isWorldFull(worldIndex, #players)
					:catch(function(err)
						warn("Teleport.toWorld: error: " .. tostring(err))
						return Promise.reject(TeleportResponseType.teleportError)
					end)
					:andThen(function(isFull)
						if isFull then
							warn("Teleport.toWorld: world is full")
							return Promise.reject(TeleportResponseType.full)
						end

						return ServerData.findAvailableLocation(worldIndex, locationsExcluded):catch(function()
							warn("Teleport.toWorld: no available locations")
							return Promise.reject(TeleportResponseType.full)
						end)
					end)
					:andThen(function(locationEnum)
						resolve(worldIndex, locationEnum)
					end)
			end)
			:catch(function(err)
				warn("Teleport.toWorld: error: " .. tostring(err))
				reject(TeleportResponseType.teleportError)
			end)
	end)
end

--[[
    Authorizes a player to teleport to a party. Used to verify that parameters are valid for teleporting to a party.
]]
function Authorize.toParty(players: { Player } | Player, partyType: number, partyIndex: number | nil)
	assert(players and partyType, "Teleport.toParty: missing argument")
	players = if type(players) == "table" then players else { players };

	(partyIndex and Promise.resolve(partyIndex) or ServerData.findAvailableParty(partyType))
		:andThen(function(partyIndex)
			return LiveServerData.isPartyFull(partyType, partyIndex, #players)
				:andThen(function(isFull)
					if isFull then
						warn("Teleport.toParty: party is full")
						return Promise.reject(TeleportResponseType.full)
					end

					return partyIndex
				end)
				:catch(function(err)
					warn("Teleport.toParty: error: " .. tostring(err))
					return Promise.reject(TeleportResponseType.teleportError)
				end)
		end)
		:andThen(function(partyIndex)
			return ServerData.getParty(partyType, partyIndex)
				:andThen(function(party)
					if not party then
						warn("Teleport.toParty: party does not exist")
						return Promise.reject(TeleportResponseType.invalid)
					end

					return party
				end)
				:catch(function(err)
					warn("Teleport.toParty: error: " .. tostring(err))
					return Promise.reject(TeleportResponseType.invalid)
				end)
		end)
end

--[[
    Teleports a player or a set of players to a location in a world.
    - `worldIndex` is optional. If not provided, the player's current world will be used.
    - onFail is a function or table of functions that calls if the teleport fails.
    - onSuccess is a function or table of functions that calls if the teleport succeeds.

    Returns a promise that resolves a table of promises, where the key is the player and the value is a promise
    that resolves the player's teleport response.
]]
function Teleport.toLocation(
	players: { Player } | Player,
	locationEnum: number,
	worldIndex: number | nil,
	onFail: onFailCallbackParam,
	onSuccess: onSuccessCallbackParam
)
	return Authorize.toLocation(players, locationEnum, worldIndex):andThen(function(worldIndex)
		local targetPlayer = players[1]
		local locationInfo = Locations.info[locationEnum]
		local placeId = locationInfo.placeId

		return Promise.all({
			Teleport.getOptions(targetPlayer),
			ServerData.getWorlds(),
		}):andThen(function(table)
			local teleportOptions = table[1] :: TeleportOptions
			local worlds = table[2]
			local location = worlds[worldIndex].locations[locationEnum]

			teleportOptions.ReservedServerAccessCode = location.serverCode

			return Teleport.go(players, placeId, teleportOptions, onSuccess, onFail)
		end)
	end)
end

--[[
    Teleports a player or a set of players to a world.
    - onFail is a function or table of functions that calls if the teleport fails.
    - onSuccess is a function or table of functions that calls if the teleport succeeds.
    - locationsExcluded is a table of locations that should be excluded from the teleport.
        Used in cases where you'd want to restrict a certain location from being teleported to.

    Returns a promise that resolves if the preliminary teleport succeeds
    (things might fail later on, thats why we have onFail and onSuccess).
]]
function Teleport.toWorld(
	players: { Player } | Player,
	worldIndex: number,
	onFail: onFailCallbackParam,
	onSuccess: onSuccessCallbackParam,
	locationsExcluded: { number } | nil
)
	assert(players and worldIndex, "Teleport.toWorld: missing argument")

	players = if type(players) == "table" then players else { players }
	onFail = if type(onFail) == "table" then onFail else { onFail }
	onSuccess = if type(onSuccess) == "table" then onSuccess else { onSuccess }

	return Authorize.toWorld(players, worldIndex, locationsExcluded)
		:andThen(function(worldIndex, locationEnum)
			return Teleport.toLocation(players, locationEnum, worldIndex, function(playerFailed, teleportResult)
				local function bail()
					for _, callback in ipairs(onFail) do
						callback(playerFailed, teleportResult)
					end
				end

				if teleportResult == Enum.TeleportResult.GameFull then
					locationsExcluded = Table.append(locationsExcluded, { locationEnum })

					ServerData.findAvailableLocation(worldIndex, locationsExcluded)
						:andThen(function(locationEnum)
							return Teleport.toLocation(players, locationEnum, worldIndex, onFail, onSuccess)
						end)
						:catch(bail)
				else
					bail()
				end
			end, onSuccess)
		end)
		:andThen(function()
			return Promise.resolve() -- Clear the table of promises that Teleport.toLocation returns, because it shouldn't be used.
		end)
end

--[[
    Teleports a player or a set of players to a party.
    - partyIndex is optional. If not provided, an available party will be found.
    - onFail is a function or table of functions that calls if the teleport fails.
    - onSuccess is a function or table of functions that calls if the teleport succeeds.

    Returns a promise that resolves a table of promises, where the key is the player and the value is a promise
    that resolves the player's teleport response.
]]
function Teleport.toParty(
	players: Player | { Player },
	partyType: number,
	partyIndex: number | nil,
	onFail: onFailCallbackParam,
	onSuccess: onSuccessCallbackParam
)
	players = if type(players) == "table" then players else { players }
	onFail = if type(onFail) == "table" then onFail else { onFail }
	onSuccess = if type(onSuccess) == "table" then onSuccess else { onSuccess }

	return Authorize.toParty(players, partyType, partyIndex):andThen(function(party)
		local code = party.serverCode
		local targetPlayer = players[1]

		assert(code, "Teleport.toParty: party does not have a server code")

		return Teleport.getOptions(targetPlayer):andThen(function(teleportOptions: TeleportOptions)
			teleportOptions.ReservedServerAccessCode = code

			return Teleport.go(players, Parties[partyType].placeId, teleportOptions, onSuccess, onFail)
		end)
	end)
end

function Teleport.toHome(player: Player, homeOwnerUserId)
	if player.UserId ~= homeOwnerUserId then
		if LiveServerData.isHomeFull(homeOwnerUserId) then
			warn("Teleport.teleportToHome: home is full")
			return false
		end

		local homeLockType = HomeManager.getLockStatus(homeOwnerUserId)

		if homeLockType == HomeLockType.locked then
			warn("Teleport.teleportToHome: home is private")
			return false
		end

		local success, isFriendsWith = pcall(function()
			return player:IsFriendsWith(homeOwnerUserId)
		end)

		if not success then
			warn("Teleport.teleportToHome: failed to check friendship")
			return false
		end

		if homeLockType == HomeLockType.friendsOnly and not isFriendsWith then
			warn("Teleport.teleportToHome: home is friends only")
			return false
		end
	end

	local homeServerInfo = HomeManager.getHomeServerInfo(homeOwnerUserId)

	if not homeServerInfo then
		warn("Teleport.teleportToHome: home server info is nil")
		return false
	end

	if not HomeManager.isHomeInfoStamped(homeOwnerUserId) then
		local success = ServerData.stampHomeServer(homeOwnerUserId)

		if not success then
			warn("Teleport.teleportToHome: failed to stamp home server")
			return false
		end
	end

	local teleportOptions = Instance.new("TeleportOptions")

	teleportOptions.ReservedServerAccessCode = homeServerInfo.serverCode

	local worldIndex = getWorldIndexOrigin(player)

	teleportOptions:SetTeleportData({
		worldIndexOrigin = worldIndex,
	})

	return Teleport.teleport(player, GameSettings.homePlaceId, teleportOptions)
end

--[[
    Teleports a player or a set of players to the starting (routing) place.
    Should only be used if an error occurs.
    A reason can be provided to display to the player when they rejoin.

    Returns a promise that resolves a table of promises, where the key is the player and 
    the value is a promise that resolves the player's teleport response.
]]
function Teleport.rejoin(
	players: Player | { Player },
	reason: string | nil,
	onFail: onFailCallbackParam,
	onSuccess: onSuccessCallbackParam
)
	players = if type(players) == "table" then players else { players }
	onFail = if type(onFail) == "table" then onFail else { onFail }
	onSuccess = if type(onSuccess) == "table" then onSuccess else { onSuccess }

	local targetPlayer = players[1]

	return Teleport.getOptions(targetPlayer, {
		rejoinReason = reason,
	}):andThen(function(teleportOptions: TeleportOptions)
		return Teleport.go(players, GameSettings.routePlaceId, teleportOptions, onSuccess, onFail)
	end)
end

--[[
    Calls Teleport.rejoin for every player in the game and all players that join.
    Should only be used if a critical server error occurs.
    Always specify a reason.
]]
function Teleport.bootServer(reason)
	local serverBootingEnabled = false

	if not serverBootingEnabled then
		error("SERVER BOOT: " .. reason)
	end

	local rejoinFailedText = "[REJOIN FAILED] " .. (reason or "Unspecified reason")

	local function boot()
		Teleport.rejoin(Players:GetPlayers(), reason, function(player)
			player:Kick(rejoinFailedText)
		end):catch(function()
			for _, player in ipairs(Players:GetPlayers()) do
				player:Kick(rejoinFailedText)
			end
		end)
	end

	Players.PlayerAdded:Connect(boot)
    boot()
end

return Teleport
