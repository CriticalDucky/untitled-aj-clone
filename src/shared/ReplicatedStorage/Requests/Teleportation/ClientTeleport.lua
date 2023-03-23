--[[
	Provides client access to teleportation requests.
]]

--#region Imports
local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local dataFolder = replicatedStorageShared:WaitForChild "Data"

local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
local LiveServerData = require(serverFolder:WaitForChild "LiveServerData")
local ClientPlayerSettings = require(dataFolder:WaitForChild("Settings"):WaitForChild "ClientPlayerSettings")
local Table = require(utilityFolder:WaitForChild "Table")
local TeleportRequestType = require(enumsFolder:WaitForChild "TeleportRequestType")
local TeleportResponseType = require(enumsFolder:WaitForChild "TeleportResponseType")
local Locations = require(serverFolder:WaitForChild "Locations")
local FriendLocations = require(serverFolder:WaitForChild "FriendLocations")
local WorldOrigin = require(serverFolder:WaitForChild "WorldOrigin")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local Promise = require(utilityFolder:WaitForChild "Promise")
local Types = require(utilityFolder:WaitForChild "Types")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")

type ServerIdentifier = Types.ServerIdentifier
type UserEnum = Types.UserEnum
--#endregion

local player = Players.LocalPlayer

local ClientTeleport = {}
local Authorize = {}

--[[
	The general function for making a teleport request.
	Wrapped by other functions in this module.
]]
local function requestTeleport(teleportRequestType, ...)
	assert(
		Table.hasValue(TeleportRequestType, teleportRequestType),
		"Teleport.request() called with invalid teleportRequestType: " .. tostring(teleportRequestType)
	)

	local vararg = { ... }

	local TeleportRequest = ReplicaCollection.get "TeleportRequest"

	local response = ReplicaRequest.new(TeleportRequest, teleportRequestType, unpack(vararg))

	Table.print(response, "request() response:", true)
	return unpack(response)
end

--[[
	Authorize a teleport to a world.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, responseType = Authorize.toWorld(worldIndex)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toWorld(worldIndex: number)
	local isWorldFull = LiveServerData.isWorldFull(worldIndex, 1)

	if isWorldFull then
		return false, TeleportResponseType.full
	else
		return true
	end
end

--[[
	Authorize a teleport to a location.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toLocation(locationEnum)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toLocation(locationEnum: UserEnum)
	local localWorldIndex -- The world index of the server we're on (or the world origin if we're in a game, party, or home)

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
		local serverIdentifier = LocalServerInfo.getServerIdentifier()

		if locationEnum == serverIdentifier.locationEnum then return false, TeleportResponseType.alreadyInPlace end

		localWorldIndex = serverIdentifier.worldIndex
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
		localWorldIndex = WorldOrigin.get(player)
	else
		error "ClientTeleport.toLocation() called on server without world info"
	end

	if not ReplicatedServerData.worldHasLocation(localWorldIndex, locationEnum) then
		return false, TeleportResponseType.invalid -- The replicated server data might not have replicated yet, so we can't be sure
	end

	if LiveServerData.isLocationFull(localWorldIndex, locationEnum, 1) then
		local setting = ClientPlayerSettings.getSetting("findOpenWorld", nil, true) -- nil means use local player, true means wait for setting to load

		if setting then
			return true
		else
			return false, TeleportResponseType.full
		end
	end

	return true
end

--[[
	Authorize a teleport to a friend.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toFriend(playerId)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toFriend(playerId: number)
	local friendLocation = FriendLocations.get(true)[playerId]

	if friendLocation then
		local serverType = friendLocation.serverType

		if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
			if not ReplicatedServerData.worldHasLocation(friendLocation.worldIndex, friendLocation.locationEnum) then
				return false, TeleportResponseType.invalid
			end

			if LiveServerData.isLocationFull(friendLocation.worldIndex, friendLocation.locationEnum, 1) then
				return false, TeleportResponseType.full
			end

			if Locations.info[friendLocation.locationEnum].cantJoinPlayer then
				return false, TeleportResponseType.invalid
			end
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
			if LiveServerData.isPartyFull(friendLocation.partyType, friendLocation.partyIndex, 1) then
				return false, TeleportResponseType.full
			end
		else
			return false, TeleportResponseType.invalid
		end
	else
		return false, TeleportResponseType.invalid
	end
end

--[[
	Authorize a teleport to a party.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toParty(partyType)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toParty(partyType: UserEnum)
	assert(partyType, "ClientTeleport.toParty() called with nil partyType")

	local activeParty = ActiveParties.getActiveParty()

	if activeParty.partyType ~= partyType then return false, TeleportResponseType.disabled end
end

--[[
	Authorize a teleport to a home.

	Returns a boolean indicating whether the teleport is allowed, and a TeleportResponseType if not.

	```lua
	local isAllowed, teleportResponseType = Authorize.toHome(homeOwnerUserId)
	```

	Authorization allows for knowing whether a teleport is allowed without actually performing the teleport.
]]
function Authorize.toHome(homeOwnerUserId: number)
	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
		local serverIdentifier = ReplicatedServerData.getServerIdentifier()

		if serverIdentifier.homeOwner == homeOwnerUserId then return false, TeleportResponseType.alreadyInPlace end
	end

	if homeOwnerUserId == player.UserId then return true end -- If we're trying to teleport to our own home, we don't need to check if it's full

	if LiveServerData.isHomeFull(homeOwnerUserId, 1) then return false, TeleportResponseType.full end

	-- TODO: Check if home is private
end

--[[
	Initializes a teleport request to the given world.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toWorld(worldIndex)
	```
]]
function ClientTeleport.toWorld(worldIndex: number)
	local isAllowed, teleportResponseType = Authorize.toWorld(worldIndex)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toWorld, worldIndex)
	else
		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given location.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toLocation(locationEnum)
	```
]]
function ClientTeleport.toLocation(locationEnum: UserEnum)
	local isAllowed, teleportResponseType = Authorize.toLocation(locationEnum)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toLocation, locationEnum)
	else
		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given friend.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toFriend(playerId)
	```
]]
function ClientTeleport.toFriend(playerId: number)
	local isAllowed, teleportResponseType = Authorize.toFriend(playerId)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toFriend, playerId)
	else
		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given party.
	Returns the success of the request along with a TeleportResponseType if not.

	```lua
	local success, teleportResponseType = ClientTeleport.toParty(partyType)
	```
]]
function ClientTeleport.toParty(partyType: UserEnum)
	local isAllowed, teleportResponseType = Authorize.toParty(partyType)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toParty, partyType)
	else
		return false, teleportResponseType
	end
end

--[[
	Initializes a teleport request to the given home.
	Returns the success of the request along with a TeleportResponseType if not.

	NOTE: Currently only supports teleporting to your own home.

	```lua
	local success, teleportResponseType = ClientTeleport.toHome(homeOwnerUserId)
	```
]]
function ClientTeleport.toHome(homeOwnerUserId: number)
	local isAllowed, teleportResponseType = Authorize.toHome(homeOwnerUserId)

	if isAllowed then
		return requestTeleport(TeleportRequestType.toHome, homeOwnerUserId)
	else
		return false, teleportResponseType
	end
end

--[[
	Initializes a client-requested rejoin.
	Guaranteed to succeed, does not return anything.

	No rejoin reason providable due to security reasons

	```lua
	local success, teleportResponseType = ClientTeleport.rejoin()
	```
]]
function ClientTeleport.rejoin()
	requestTeleport(TeleportRequestType.rejoin)
end

return ClientTeleport
