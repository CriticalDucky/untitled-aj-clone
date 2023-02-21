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
local ClientServerData = require(serverFolder:WaitForChild "ClientServerData")
local LiveServerData = require(serverFolder:WaitForChild "LiveServerData")
local ClientPlayerSettings = require(dataFolder:WaitForChild("Settings"):WaitForChild "ClientPlayerSettings")
local Table = require(utilityFolder:WaitForChild "Table")
local TeleportRequestType = require(enumsFolder:WaitForChild "TeleportRequestType")
local ResponseType = require(enumsFolder:WaitForChild "ResponseType")
local Locations = require(serverFolder:WaitForChild "Locations")
local FriendLocations = require(serverFolder:WaitForChild "FriendLocations")
local WorldOrigin = require(serverFolder:WaitForChild "WorldOrigin")
local ActiveParties = require(serverFolder:WaitForChild "ActiveParties")
local Promise = require(utilityFolder:WaitForChild "Promise")
local Types = require(utilityFolder:WaitForChild "Types")

type ServerIdentifier = Types.ServerIdentifier

local player = Players.LocalPlayer

local TeleportRequest = ReplicaCollection.get "TeleportRequest"

local ClientTeleport = {}
local Authorize = {}

--[[
	The general function for making a teleport request.
	Wrapped by other functions in this module, this is not for external use.
]]
function ClientTeleport._request(teleportRequestType, ...)
	assert(
		Table.hasValue(TeleportRequestType, teleportRequestType),
		"Teleport.request() called with invalid teleportRequestType: " .. tostring(teleportRequestType)
	)

	local vararg = { ... }

	return TeleportRequest:andThen(function(replica)
		return ReplicaRequest.new(replica, teleportRequestType, unpack(vararg))
	end)
end

--[[
	Authorize a teleport to a world.
]]
function Authorize.toWorld(worldIndex: number)
	return LiveServerData.isWorldFull(worldIndex, 1)
		:andThen(function(isWorldFull: boolean)
			return if isWorldFull then Promise.reject(ResponseType.full) else Promise.resolve()
		end)
		:catch(function(err)
			warn("ClientTeleport.toWorld() failed with error: " .. tostring(err))
			return Promise.reject(ResponseType.error)
		end)
end

--[[
	Authorize a teleport to a location.
]]
function Authorize.toLocation(locationEnum: number)
	return Promise.resolve()
		:andThen(function()
			if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
				return ClientServerData.getServerInfo()
					:catch(function(err)
						warn("ClientTeleport.toLocation() failed with error 1: " .. tostring(err))
						return Promise.reject(ResponseType.error)
					end)
					:andThen(function(serverInfo)
						if locationEnum == serverInfo.locationEnum then
							return Promise.reject(ResponseType.alreadyInPlace)
						end

						return serverInfo.worldIndex
					end)
			elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
				return WorldOrigin.get(player):catch(function(err)
					warn("ClientTeleport.toLocation() failed with error 2: " .. tostring(err))
					return Promise.reject(ResponseType.error)
				end)
			else
				warn "ClientTeleport.toLocation() called on server without world info"
				return Promise.reject(ResponseType.error)
			end
		end)
		:andThen(function(localWorldIndex)
			return if ClientServerData.worldHasLocation(localWorldIndex, locationEnum)
				then localWorldIndex
				else Promise.reject(ResponseType.invalid)
		end)
		:andThen(function(localWorldIndex)
			return LiveServerData.isLocationFull(localWorldIndex, locationEnum, 1)
				:catch(function(err)
					warn("ClientTeleport.toLocation() failed with error 3: " .. tostring(err))
					return Promise.reject(ResponseType.error)
				end)
				:andThen(function(isLocationFull: boolean)
					return (if isLocationFull then Promise.reject(ResponseType.full) else Promise.resolve()):catch(
						function()
							return ClientPlayerSettings.promiseSetting("findOpenWorld"):andThen(function(setting)
								return if setting then Promise.resolve() else Promise.reject(ResponseType.full)
							end)
						end
					)
				end)
		end)
		:catch(function(response)
			if not Table.hasValue(ResponseType, response) then
				warn("ClientTeleport.toLocation() failed with unknown error: " .. tostring(response))
				return Promise.reject(ResponseType.error)
			end

			return Promise.reject(response)
		end)
end

function Authorize.toFriend(playerId: number)
	return Promise.resolve()
		:andThen(function()
			local friendLocations = FriendLocations:get()
			local friendLocation = friendLocations[playerId]

			if friendLocation then
				local serverType = friendLocation.serverType

				if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
					if
						not ClientServerData.worldHasLocation(friendLocation.worldIndex, friendLocation.locationEnum)
					then
						return Promise.reject(ResponseType.invalid)
					end

					if
						LiveServerData.isLocationFull(friendLocation.worldIndex, friendLocation.locationEnum, 1)
							:expect()
					then
						return Promise.reject(ResponseType.full)
					end

					if Locations.info[friendLocation.locationEnum].cantJoinPlayer then
						return Promise.reject(ResponseType.invalid)
					end
				elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
					if LiveServerData.isPartyFull(friendLocation.partyType, friendLocation.partyIndex, 1):expect() then
						return Promise.reject(ResponseType.full)
					end
				else
					return Promise.reject(ResponseType.invalid)
				end
			else
				return Promise.reject(ResponseType.invalid)
			end
		end)
		:catch(function(response)
			if not Table.hasValue(ResponseType, response) then
				warn("ClientTeleport.toFriend() failed with unknown error: " .. tostring(response))
				return Promise.reject(ResponseType.error)
			end

			return Promise.reject(response)
		end)
end

function Authorize.toParty(partyType: number)
	return Promise.resolve()
		:andThen(function()
			local activeParty = ActiveParties.getActiveParty()

			if activeParty.partyType ~= partyType then
				return Promise.reject(ResponseType.disabled)
			end
		end)
		:catch(function(response)
			if not Table.hasValue(ResponseType, response) then
				warn("ClientTeleport.toParty() failed with unknown error: " .. tostring(response))
				return Promise.reject(ResponseType.error)
			end

			return Promise.reject(response)
		end)
end

function Authorize.toHome(homeOwnerUserId: number)
	return Promise.resolve()
		:andThen(function()
			if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
				return ClientServerData.getServerInfo():andThen(function(serverInfo: ServerIdentifier)
					if serverInfo.homeOwner == homeOwnerUserId then
						return Promise.reject(ResponseType.alreadyInPlace)
					end
				end)
			end
		end)
		:andThen(function()
			if homeOwnerUserId == player.UserId then
				return Promise.resolve()
			end

			return LiveServerData.isHomeFull(homeOwnerUserId, 1):andThen(function(isFull: boolean)
				if isFull then
					return Promise.reject(ResponseType.full)
				end
			end)
		end)
		:andThen(function()
			-- TODO: Check if home is private
		end)
		:catch(function(response)
			if not Table.hasValue(ResponseType, response) then
				warn("ClientTeleport.toHome() failed with unknown error: " .. tostring(response))
				return Promise.reject(ResponseType.error)
			end

			return Promise.reject(response)
		end)
end

function ClientTeleport.toWorld(worldIndex)
	return Authorize.toWorld(worldIndex):andThen(function()
		return ClientTeleport._request(TeleportRequestType.toWorld, worldIndex)
	end)
end

function ClientTeleport.toLocation(locationEnum: number)
	return Authorize.toLocation(locationEnum):andThen(function()
		return ClientTeleport._request(TeleportRequestType.toLocation, locationEnum)
	end)
end

function ClientTeleport.toFriend(playerId)
	return Authorize.toFriend(playerId):andThen(function()
		return ClientTeleport._request(TeleportRequestType.toFriend, playerId)
	end)
end

function ClientTeleport.toParty(partyType: number)
	return Authorize.toParty(partyType):andThen(function()
		return ClientTeleport._request(TeleportRequestType.toParty, partyType)
	end)
end

function ClientTeleport.toHome(homeOwnerUserId: number)
	return Authorize.toHome(homeOwnerUserId):andThen(function()
		return ClientTeleport._request(TeleportRequestType.toHome, homeOwnerUserId)
	end)
end

function ClientTeleport.rejoin() -- No reason provided for security reasons
	return ClientTeleport._request(TeleportRequestType.rejoin)
end

return ClientTeleport
