local INACTIVE_PROFILE_COOLDOWN = 30 -- seconds

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerScriptService = game:GetService "ServerScriptService"
local ServerStorage = game:GetService "ServerStorage"

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local serverStorageSharedUtility = serverStorageShared.Utility
local serverStorageSharedData = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums
local replicatedFirstUtility = replicatedFirstShared.Utility

local ProfileService = require(serverStorageSharedUtility.ProfileService)
local ReplicaService = require(serverStorageSharedData.ReplicaService)
local ReplicationType = require(enumsFolder.ReplicationType)
local Table = require(replicatedFirstUtility.Table)
local PlayerJoinTimes = require(serverStorageSharedUtility.PlayerJoinTimes)
local Signal = require(replicatedFirstUtility.Signal)
local Promise = require(replicatedFirstUtility.Promise)
local Types = require(replicatedFirstUtility.Types)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)

type PlayerData = Types.PlayerData
type Promise = Types.Promise
type ProfileData = Types.ProfileData

local profileTemplate = GameSettings.profileTemplate
local tempDataTemplate = GameSettings.tempDataTemplate

local ProfileStore = Promise.retry(function()
	return Promise.try(function()
		return ProfileService.GetProfileStore("PlayerData", profileTemplate)
	end)
end, 5)

local playerDataPublicReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PlayerDataPublic",
	Data = {},
	Replication = "All",
}

local playerDataCreationComplete = { -- Used to track if a player's data has been created.
	--[[
		[player] = boolean
	]]
}

local playerDataCollection = { -- Collection of all player data.
	--[[
		[player] = PlayerData
	]]
}

local cachedViewedProfiles = { -- Collection of all viewed profiles (See `PlayerDataManager.viewPlayerProfile`).
	--[[
		[playerId] = ProfileData
	]]
}

local lastProfileCacheTime =
	{ -- Used to track when a profile was last cached (See `PlayerDataManager.viewPlayerProfile`).
		--[[
		[playerId] = number
	]]
	}

local PlayerData = {}
PlayerData.__index = PlayerData

-- For the given property of a profile or temp data, returns the replication type.
local function getReplicationType(prop)
	return GameSettings.dataKeyReplication[prop]
end

local function getKey(playerId)
	return "Player_" .. playerId
end

--[[
	Sets up a new `PlayerData` object for the given player.

	Loads the player's profile and manages replicas for the player's data.

	Returns the new `PlayerData` object, or `false` if the player's profile failed to load.
	It can also return `true` if the player left before the profile was loaded. Treat this as a success.
]]
function PlayerData.new(player: Player): PlayerData
	local newPlayerData = setmetatable({}, PlayerData)
	newPlayerData.player = player

	local profileStore = ProfileStore:expect()

	local profile = profileStore:LoadProfileAsync(getKey(player.UserId), "ForceLoad")

	if not profile then
		print("Failed to load profile for player " .. player.Name)
		return false
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		playerDataCollection[player] = nil
		playerDataCreationComplete[player] = nil
	end)

	if not player:IsDescendantOf(Players) then
		profile:Release()
		return true -- Player left before profile was loaded; treat as success.
	end

	playerDataCollection[player] = newPlayerData
	local tempDataCopy = Table.deepCopy(tempDataTemplate)

	-- Merge the player's profile data with the temp data and separate by replication type for the replicas.

	local function getMatchingProfileProps(privacy)
		local matchingProps = {}

		for propName, prop in pairs(profile.Data) do
			matchingProps[propName] = if GameSettings.dataKeyReplication[propName] == privacy then prop else nil
		end

		return matchingProps
	end

	local function getMatchingTempDataProps(privacy)
		local matchingProps = {}

		for propName, prop in pairs(tempDataCopy) do
			matchingProps[propName] = if GameSettings.dataKeyReplication[propName] == privacy then prop else nil
		end

		return matchingProps
	end

	local data_replicationPrivate =
		Table.merge(getMatchingProfileProps(ReplicationType.private), getMatchingTempDataProps(ReplicationType.private))

	local data_replicationPublic =
		Table.merge(getMatchingProfileProps(ReplicationType.public), getMatchingTempDataProps(ReplicationType.public))

	-- Set values for new player data object.

	newPlayerData.profile = profile
	newPlayerData.tempData = tempDataCopy

	-- Set up replicas.

	newPlayerData.replica_private = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(
			"PlayerDataPrivate_" .. player.UserId .. PlayerJoinTimes.getTimesJoined(player)
		),
		Data = data_replicationPrivate,
		Replication = player,
	}

	print("Replicating data to " .. player.Name .. "...")

	playerDataPublicReplica:SetValue({ player.UserId }, data_replicationPublic)
	newPlayerData.replica_public = playerDataPublicReplica

	return newPlayerData
end

-- Sets the data at the given path to the given value in the relevant replica.
function PlayerData:setValue(path: table, value)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:SetValue(path, value)
	elseif replicationType == ReplicationType.private then
		self.replica_private:SetValue(path, value)
	else
		local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

		for i = 1, #path - 1 do
			data = data[path[i]]
		end

		data[path[#path]] = value
	end
end

-- Sets the data at the given path to the given values in the relevant replica.
function PlayerData:setValues(path, values)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:SetValues(path, values)
	elseif replicationType == ReplicationType.private then
		self.replica_private:SetValues(path, values)
	else
		local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

		for i = 1, #path - 1 do
			data = data[path[i]]
		end

		for key, value in pairs(values) do
			data[path[#path]][key] = value
		end
	end
end

-- Inserts the given value into the array at the given path in the relevant replica.
function PlayerData:arrayInsert(path, value)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:ArrayInsert(path, value)
	elseif replicationType == ReplicationType.private then
		self.replica_private:ArrayInsert(path, value)
	else
		local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

		for i = 1, #path - 1 do
			data = data[path[i]]
		end

		table.insert(data[path[#path]], value)
	end
end

-- Sets the value at the given index in the array at the given path in the relevant replica.
function PlayerData:arraySet(path, index, value)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:ArraySet(path, index, value)
	elseif replicationType == ReplicationType.private then
		self.replica_private:ArraySet(path, index, value)
	else
		local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

		for i = 1, #path - 1 do
			data = data[path[i]]
		end

		data[path[#path]][index] = value
	end
end

-- Removes the value at the given index in the array at the given path in the relevant replica.
function PlayerData:arrayRemove(path, index)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:ArrayRemove(path, index)
	elseif replicationType == ReplicationType.private then
		self.replica_private:ArrayRemove(path, index)
	else
		local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

		for i = 1, #path - 1 do
			data = data[path[i]]
		end

		table.remove(data[path[#path]], index)
	end
end

local PlayerDataManager = {}

PlayerDataManager.playerDataAdded = Signal.new()

--[[
	Returns a player's data as long as the provided player is in this server.
	Use this if you intend to modify the player's data. Otherwise, see `PlayerDataManager.viewProfileData`.

	If `wait` is true, this method will wait until the player's data has been loaded before returning.
	If `wait` is false, this method will return nil if the player's data has not been loaded yet.
]]
function PlayerDataManager.get(player: Player | number, wait: boolean): PlayerData?
	player = if typeof(player) == "number" then Players:GetPlayerByUserId(player) else player

	local playerData = playerDataCollection[player]

	if playerData then
		return playerData
	elseif wait then
		while not playerDataCreationComplete[player] do
			task.wait()
		end

		return playerDataCollection[player]
	end

	-- Can return nil if wait is false and the player's data has not been loaded yet
end

--[[
	Returns an offline player's read-only *profile data*.
	Even if a player is online, this is the recommended way to get their data if you don't need to modify it.

	Can return nil if loading the profile failed.
]]
function PlayerDataManager.viewPlayerProfile(player: Player | number): ProfileData?
	player = if typeof(player) == "number" then Players:GetPlayerByUserId(player) else player

	if playerDataCollection[player] then
		local playerData = playerDataCollection[player]
		return Table.deepFreeze(Table.deepCopy(playerData.profile.Data))
	end

	local userId = player.UserId

	local profileData: ProfileData? = cachedViewedProfiles[userId]

	if profileData and time() - lastProfileCacheTime[userId] < INACTIVE_PROFILE_COOLDOWN then return profileData end

	local profile = ProfileStore:expect():ViewProfileAsync(getKey(userId))

	if profile then
		profileData = Table.deepFreeze(Table.deepCopy(profile.Data))
		cachedViewedProfiles[userId] = profileData
		return profileData
	else
		warn "Failed to view profile"
	end
end

--[[
	Initializes a player's data. Returns true if successful, false if not.
	Only for use by PlayerDataManagerInit.server.lua.
]]
function PlayerDataManager.init(player)
	print("Initializing player data for " .. player.Name)

	local playerData = PlayerData.new(player)

	if playerData then
		if playerData ~= true then
			playerDataCreationComplete[player] = true
			PlayerDataManager.playerDataAdded:Fire(playerData)
		end

		return true
	else
		warn("Failed to initialize player data for " .. player.Name)

		return false
	end
end

-- Calls a given function for all `PlayerData` instances and connects it to an event that calls it for any future
-- `PlayerData` instances. Returns that connection.
function PlayerDataManager.forAllPlayerData(callback: (PlayerData) -> nil)
	for _, playerData in pairs(playerDataCollection) do
		callback(playerData)
	end

	local connection = PlayerDataManager.playerDataAdded:Connect(callback)

	return connection
end

Players.PlayerRemoving:Connect(function(player)
	local playerData = playerDataCollection[player]

	if playerData then
		playerData.replica_private:Destroy()
		playerData.profile:Release()
	end

	playerDataCreationComplete[player] = nil
end)

return PlayerDataManager
