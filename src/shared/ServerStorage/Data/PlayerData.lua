local INACTIVE_PROFILE_COOLDOWN = 30 -- seconds

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

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
local HomeLockType = require(enumsFolder.HomeLockType)
local Signal = require(replicatedFirstUtility.Signal)
local Promise = require(replicatedFirstUtility.Promise)
local Types = require(replicatedFirstUtility.Types)
local Param = require(replicatedFirstUtility.Param)
local PlayerFormat = require(enumsFolder.PlayerFormat)

type PlayerParam = Types.PlayerParam
type Promise = Types.Promise

local PROFILE_TEMPLATE = { -- Items in here can only be under a table. See:

	-- NOTE TO FUTURE SELF: adding stuff here also requires adding it to PROFILE_REPLICATION below

	currency = {
		money = 0,
	},

	inventory = {
		accessories = {},
		homeItems = {},
		homes = {},
	},

	playerInfo = { -- stuff that never changes
		homeServerInfo = {
			privateServerId = nil,
			serverCode = nil,
		},
		homeInfoStamped = false,
	},

	playerSettings = {
		findOpenWorld = true,
		homeLock = HomeLockType.unlocked,
		selectedHome = nil,
	},
}

local PROFILE_REPLICATION = {
	[ReplicationType.private] = { -- private data is only sent to the client that owns the profile
		"currency",
		"inventory",
	},

	[ReplicationType.public] = { -- public data is replicated to everyone
		"playerSettings",
	},
}

local TEMP_DATA_TEMPLATE
do
	local dictionaries = {}

	local function iterate(_, instance)
		if instance:IsA("ModuleScript") and instance.Name == "TempDataTemplate" then
			table.insert(dictionaries, require(instance))
		end
	end

	table.foreachi(ServerStorage:GetDescendants(), iterate)
	table.foreachi(ServerScriptService:GetDescendants(), iterate)

	TEMP_DATA_TEMPLATE = Table.merge(table.unpack(dictionaries))
end

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PROFILE_TEMPLATE)

local playerDataPublicReplica = ReplicaService.NewReplica({
	ClassToken = ReplicaService.NewClassToken("PlayerDataPublic"),
	Data = {},
	Replication = "All",
})

local playerDataCreationComplete = {}
local playerDataCollection = {}
local cachedInactiveProfiles = {}

local PlayerData = {}
PlayerData.__index = PlayerData

local function getReplicationType(index)
	for replicationType, keys in pairs(PROFILE_REPLICATION) do
		if table.find(keys, index) then
			return replicationType
		end
	end

	for key, value in pairs(TEMP_DATA_TEMPLATE) do
		if index == key then
			return value._replication
		end
	end

	return ReplicationType.server
end

local function getKey(playerId)
	return "Player_" .. playerId
end

--[[
    Sets up a new PlayerData object for the given player.
]]
function PlayerData.new(player: PlayerParam)
	Param.playerParam(player, PlayerFormat.instance):andThen(function(instance)
		player = instance

		return Promise.new(function(resolve, reject)
			local newPlayerData = setmetatable({}, PlayerData)
			newPlayerData.player = player

			local profile = ProfileStore:LoadProfileAsync(getKey(player.UserId), "ForceLoad")

			if profile then
				profile:AddUserId(player.UserId)
				profile:Reconcile()
				profile:ListenToRelease(function()
					playerDataCollection[player] = nil
					playerDataCreationComplete[player] = nil
				end)

				if player:IsDescendantOf(Players) then
					playerDataCollection[player] = newPlayerData
					local tempDataCopy = Table.deepCopy(TEMP_DATA_TEMPLATE)

					local function getMatchingProfileProps(privacy)
						local matchingProps = {}
						for _, key in ipairs(PROFILE_REPLICATION[privacy]) do
							matchingProps[key] = profile.Data[key]
						end
						return matchingProps
					end

					local function getMatchingTempDataProps(privacy)
						local matchingProps = {}
						for k, v in pairs(tempDataCopy) do
							matchingProps[k] = v._replication == privacy and v or nil
						end
						return matchingProps
					end

					local data_replicationPrivate = Table.merge(
						getMatchingProfileProps(ReplicationType.private),
						getMatchingTempDataProps(ReplicationType.private)
					)

					local data_replicationPublic = Table.merge(
						getMatchingProfileProps(ReplicationType.public),
						getMatchingTempDataProps(ReplicationType.public)
					)

					newPlayerData.profile = profile
					newPlayerData.tempData = tempDataCopy

					newPlayerData.replica_private = ReplicaService.NewReplica({
						ClassToken = ReplicaService.NewClassToken(
							"PlayerDataPrivate_" .. player.UserId .. PlayerJoinTimes.getTimesJoined(player)
						),
						Data = data_replicationPrivate,
						Replication = player,
					})

					print("Replicating data to " .. player.Name .. "...")

					playerDataPublicReplica:SetValue({ player.UserId }, data_replicationPublic)
					newPlayerData.replica_public = playerDataPublicReplica
				else
					profile:Release()
				end
			else
				print("Failed to load profile for player " .. player.Name)
				return reject()
			end

			resolve(newPlayerData)
		end)
	end)
end

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

function PlayerData:arrayRemove(path, index)
	local replicationType = getReplicationType(path[1])

	if replicationType == ReplicationType.public then
		table.insert(path, 1, self.player)

		self.replica_public:ArrayInsert(path, index)
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
    Gets a player's data. If the player's data has not been loaded yet, it will wait until it has
    been loaded if wait is true.
]]
function PlayerDataManager.get(player: PlayerParam, wait: boolean): Promise 
	return Param.playerParam(player, PlayerFormat.instance)
		:andThen(function(instance)
			player = instance

			local playerData = playerDataCollection[player]

			if playerData then
				return playerData
			elseif wait then
				while not playerDataCreationComplete[player] do
					task.wait()
				end

				return playerDataCollection[player]
			else
				return nil
			end
		end)
		:timeout(20, "Timed out waiting for player data to load")
		:catch(function(err)
			warn("Failed to get player data for player " .. player.Name .. ": " .. err)
			return Promise.reject()
		end)
end

--[[
    Returns a promise that resolves a player's view-only profile.
    If getRaw is set to true, the promise will resolve with the base profile instead of profile.Data.
]]
function PlayerDataManager.viewPlayerProfile(player: PlayerParam, getUpdated: boolean, getRaw: boolean)
	return Param.playerParam(player, PlayerFormat.instance):andThen(function(player: Player)
		if playerDataCollection[player] then
			local profile = playerDataCollection[player].profile
			return if getRaw then profile else profile.Data
		end

        local userId = player.UserId

		local profileSettings = cachedInactiveProfiles[userId]

		return Promise.new(function(resolve, reject)
			if
				not profileSettings or (getUpdated and time() - profileSettings.cachedTime > INACTIVE_PROFILE_COOLDOWN)
			then
				profileSettings = cachedInactiveProfiles[userId] or {}
				profileSettings.cachedTime = time()
				cachedInactiveProfiles[userId] = profileSettings

				local profile = ProfileStore:ViewProfileAsync(getKey(userId))

				if profile then
					cachedInactiveProfiles[userId].profile = profile
					resolve(getRaw and profile or profile.Data)
				else
					warn("Failed to view profile")

					reject()
				end
			else
				resolve(profileSettings.profile)
			end
		end)
	end)
end

function PlayerDataManager.init(player)
	print("Initializing player data for " .. player.Name)

	return PlayerData.new(player):andThen(function(playerData)
		playerDataCreationComplete[player] = true
		PlayerDataManager.playerDataAdded:Fire(playerData)
	end)
end

function PlayerDataManager.yieldUntilHopReady(player)
	return PlayerDataManager.get(player):andThen(function(playerData)
		local profile = playerData.profile
		profile:Release()

		local connection

		connection = profile:ListenToHopReady(function()
			connection:Disconnect()
			connection = nil
		end)

		while connection do
			task.wait()
		end
	end)
end

function PlayerDataManager.forAllPlayerData(callback)
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
