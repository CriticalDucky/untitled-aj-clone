--!strict

--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local Enums = require(ReplicatedFirst.Shared.Enums)
local HomeLockType = Enums.HomeLockType
local TeleportToHomeResult = Enums.TeleportToHomeResult
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local SafeTeleport = require(ServerStorage.Shared.Utility.SafeTeleport)
local ServerStorageConfiguration = require(ServerStorage.Shared.Configuration)
local PlaceIds = ServerStorageConfiguration.PlaceIDs
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type PlayerPersistentData = Types.PlayerPersistentData
type ServerDataHome = Types.ServerDictionaryDataHome

--#endregion

--[[
    Provides functions for navigating between servers in the game's universe.
]]
local UniverseNavigation = {}

--[[
	Teleports the player to a home.

	---

	@param target The player to teleport.
	@param destination The owner of the home to teleport to. If nil, the player will be teleported to their own home.
	@return The result of the teleport.
]]
function UniverseNavigation.teleportToHomeAsync(target: Player, destination: number?)
	local destinationData: PlayerPersistentData

	if destination and target.UserId ~= destination then
		-- Retrieve the owner's data.

		local newDestinationData = PlayerDataManager.viewOfflinePersistentDataAsync(destination)

		if not newDestinationData then return TeleportToHomeResult.ownerDataNotFound end

		-- Check if the home is accessible.

		local homeLock = newDestinationData.settings.homeLock

		if homeLock == HomeLockType.locked then
			return TeleportToHomeResult.homeInaccessibleLocked
		elseif homeLock == HomeLockType.friendsOnly and not target:IsFriendsWith(destination) then
			return TeleportToHomeResult.homeInaccessibleFriendsOnly
		end

		destinationData = newDestinationData
	else
		-- Retrieve the owner's data.

		local newDestinationData = PlayerDataManager.viewPersistentData(target)

		if not newDestinationData then return TeleportToHomeResult.ownerDataNotFound end

		destinationData = newDestinationData
	end

	-- Retrieve the access code.

	local homeServerInfo = destinationData.home.server

	if not homeServerInfo then return TeleportToHomeResult.homeNotFound end

	local accessCode = homeServerInfo.accessCode

	-- Teleport the player to the home.

	local teleportOptions = Instance.new "TeleportOptions"
	teleportOptions.ReservedServerAccessCode = accessCode

	-- TODO: Teleport with world data.

	local success = SafeTeleport.safeTeleportAsync(PlaceIds.home, { target }, teleportOptions)

	return if success then TeleportToHomeResult.success else TeleportToHomeResult.teleportFailed
end

return UniverseNavigation
