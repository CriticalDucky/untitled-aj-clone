local OFFLINE_PROFILE_RETRIEVAL_INTERVAL = 5

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local ProfileService = require(ServerStorage.Vendor.ProfileService)
local Promise = require(ReplicatedFirst.Vendor.Promise)
local ReplicaService = require(ServerStorage.Vendor.ReplicaService)

local PlayerDataConstants = require(ReplicatedFirst.Shared.Settings.PlayerDataConstants)
local Table = require(ReplicatedFirst.Shared.Utility.Table)

type ProfileStore = typeof(ProfileService.GetProfileStore())
type Profile = typeof(ProfileService.GetProfileStore():LoadProfileAsync())

--#endregion

--[[
	Manages persistent and temporary player data. Uses `ProfileService` and `ReplicaService`.
]]
local PlayerDataManager = {}

--#region Profile Setup

local ProfileStore: ProfileStore = Promise.retry(
	function() return ProfileService.GetProfileStore("PlayerData", PlayerDataConstants.profileTemplate) end,
	5
)
	:catch(function(err)
		warn("Failed to get profile store: " .. tostring(err))
		-- TODO: Boot server

		task.wait(math.huge)
	end)
	:expect()

local publicPlayerDataReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PublicPlayerData",
	Replication = "All",
}

local function filterProfileForPublic(data: table?): table?
	if not data then return end
	
	local filteredData = {}

	filteredData.inventory = Table.deepCopy(data.inventory)

	if data.playerSettings then
		filteredData.playerSettings = {}
		filteredData.playerSettings.homeLock = data.playerSettings.homeLock
	end

	return filteredData
end

--#endregion

--#region Offline Profiles

local offlineProfileInfos = {}

local loadingOfflineProfiles = {}

local function loadOfflineProfile(playerId: number, profile: Profile)
	local profileInfo = offlineProfileInfos[playerId] or {}
	offlineProfileInfos[playerId] = profileInfo

	profileInfo.lastUpdated = time()

	if profile then
		profileInfo.profile = profile

		publicPlayerDataReplica:SetValue({ playerId }, filterProfileForPublic(profile.Data))
	end
end

local function viewOfflineProfileAsync(playerId: number)
	-- Simply return the profile if it is young enough

	local profileInfo = offlineProfileInfos[playerId]

	if profileInfo and time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
		return profileInfo.profile
	end

	-- Otherwise, retrieve the profile or wait for another retrieval to finish

	if loadingOfflineProfiles[playerId] then
		while loadingOfflineProfiles[playerId] do
			task.wait()
		end

		return offlineProfileInfos[playerId].profile
	end

	loadingOfflineProfiles[playerId] = true
	local profile = ProfileStore:ViewProfileAsync("Player_" .. playerId)
	loadingOfflineProfiles[playerId] = nil

	loadOfflineProfile(playerId, profile)

	return profile
end

--#endregion

--#region Active Profiles

local privatePlayerDataReplicas = {}

local profiles = {}

local profileLoadedEvent = Instance.new "BindableEvent"

--[[
    Loads the player's data and replicates it to the client.
]]
local function loadPlayerAsync(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

	if not profile then
		warn(("Failed to load profile for %s (User ID %d)"):format(player.Name, player.UserId))
		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		return
	end

	-- Set up profile

	profiles[player] = profile

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function()
		-- TODO: Reroute player. Ideally this should reroute to the previous place
		-- they were if it's open, and simply reroute them otherwise.

		loadOfflineProfile(player.UserId, profile)

		privatePlayerDataReplicas[player]:Destroy()
		privatePlayerDataReplicas[player] = nil

		profiles[player] = nil
	end)

	if not player:IsDescendantOf(game) then
		profile:Release()
		return
	end

	-- Set up private data replica for player

	local privatePlayerData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(
			("PrivatePlayerData%d__$%d"):format(player.UserId, math.floor(time()))
		),
		Data = profile.Data,
		Replication = "All",
	}
	privatePlayerDataReplicas[player] = privatePlayerData

	-- Set up public data replica for player

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	-- Fire profile loaded event

	profileLoadedEvent:Fire(player)
end

local function unloadPlayer(player: Player)
	local profile = profiles[player]

	if profile then profile:Release() end
end

local function viewOnlineProfileAsync(player: Player)
	while player:IsDescendantOf(game) and not profiles[player] do
		task.wait()
	end

	return profiles[player]
end

-- Initialization

for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerAsync, player)
end

Players.PlayerAdded:Connect(loadPlayerAsync)

Players.PlayerRemoving:Connect(unloadPlayer)

--#endregion

--#region Profile Subscriptions

-- Map of players to the user ID of the player whose profile they are subscribed to
local subscriptions = {}

-- Map of user IDs (of players who are subscribed to) to the subscription info
local subscriptionInfos = {}

local function unsubscribePlayer(player: Player)
	local subscription = subscriptions[player]

	if not subscription then return end

	local info = subscriptionInfos[subscription]

	subscriptions[player] = nil
	info.numberOfSubscribers -= 1

	if info.numberOfSubscribers ~= 0 then return end

	task.cancel(info.thread)
	subscriptionInfos[subscription] = nil
end

Players.PlayerRemoving:Connect(unsubscribePlayer)

--#endregion

--#region Temporary Data

local publicPlayerTempDataReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PublicPlayerTempData",
	Replication = "All",
}

local privatePlayerTempDataReplicas = {}

local loadedTempDatas = {}

local tempDataLoadedEvent = Instance.new "BindableEvent"

-- Takes a temporary data and returns a copy filtered for public availability.
local function filterTempDataForPublic(data: table?): table?
	if not data then return end
	
	-- For now, no temporary data is public

	return {}
end

local function loadPlayerTempData(player: Player)
	local initialTempData = Table.deepCopy(PlayerDataConstants.tempDataTemplate)

	local privatePlayerTempData = ReplicaService.NewReplica {
			ClassToken = ReplicaService.NewClassToken(
				("PrivatePlayerTempData%d__$%d"):format(player.UserId, math.floor(time()))
			),
			Data = initialTempData,
			Replication = "All",
		}
	privatePlayerTempDataReplicas[player] = privatePlayerTempData

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(initialTempData))

	loadedTempDatas[player] = true

	tempDataLoadedEvent:Fire(player)
end

local function unloadPlayerTempData(player: Player)
	privatePlayerTempDataReplicas[player]:Destroy()
	privatePlayerTempDataReplicas[player] = nil

	publicPlayerTempDataReplica:SetValue({ player.UserId }, nil)

	loadedTempDatas[player] = nil
end

-- Initialization

for _, player in Players:GetPlayers() do
	loadPlayerTempData(player)
end

Players.PlayerAdded:Connect(loadPlayerTempData)

Players.PlayerRemoving:Connect(unloadPlayerTempData)

--#endregion

--[[
	Performs `ArrayInsert()` on the player's persistent data and updates the public data replica accordingly.

	This will only work if the player's profile is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arrayInsertProfile(player: Player, path: { any }, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "The player's profile could not be found"
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayInsert(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	return
end

--[[
	Performs `ArrayInsert()` on the player's temporary data and updates the public data replica accordingly.

	This will only work if the player's temporary data is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arrayInsertTemp(player: Player, path: { any }, value: any): boolean
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if not privatePlayerTempData then
		warn "The player's temporary data could not be found"
		return
	end

	privatePlayerTempData:ArrayInsert(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privatePlayerTempData.Data))

	return
end

--[[
	Performs `ArrayRemove()` on the player's persistent data and updates the public data replica accordingly.

	This will only work if the player's profile is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arrayRemoveProfile(player: Player, path: { any }, index: number): boolean
	local profile = profiles[player]

	if not profile then
		warn "The player's profile could not be found"
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayRemove(path, index)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	return
end

--[[
	Performs `ArrayRemove()` on the player's temporary data and updates the public data replica accordingly.

	This will only work if the player's temporary data is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arrayRemoveTemp(player: Player, path: { any }, index: number): boolean
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if not privatePlayerTempData then
		warn "The player's temporary data could not be found"
		return
	end

	privatePlayerTempData:ArrayRemove(path, index)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privatePlayerTempData.Data))

	return
end

--[[
	Performs `ArraySet()` on the player's persistent data and updates the public data replica accordingly.

	This will only work if the player's profile is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arraySetProfile(player: Player, path: { any }, index: number, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "The player's profile could not be found"
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArraySet(path, index, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	return
end

--[[
	Performs `ArraySet()` on the player's temporary data and updates the public data replica accordingly.

	This will only work if the player's temporary data is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.arraySetTemp(player: Player, path: { any }, index: number, value: any): boolean
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if not privatePlayerTempData then
		warn "The player's temporary data could not be found"
		return
	end

	privatePlayerTempData:ArraySet(path, index, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privatePlayerTempData.Data))

	return
end

--[[
	Returns an array of all players whose profiles are loaded.
]]
function PlayerDataManager.getPlayersWithLoadedProfiles(): { Player }
	local players = {}

	for player in profiles do
		table.insert(players, player)
	end

	return players
end

--[[
	Returns an array of all players whose temporary data is loaded.
]]
function PlayerDataManager.getPlayersWithLoadedTempData(): { Player }
	local players = {}

	for player in loadedTempDatas do
		table.insert(players, player)
	end

	return players
end

--[[
	Returns if the player's profile is loaded.
]]
function PlayerDataManager.profileIsLoaded(player: Player): boolean return profiles[player] ~= nil end

--[[
	Returns if the player's temporary data is loaded.
]]
function PlayerDataManager.tempDataIsLoaded(player: Player): boolean return loadedTempDatas[player] ~= nil end

--[[
	Performs `SetValue()` on the player's persistent data and updates the public data replica accordingly.

	This will only work if the player's profile is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.setValueProfile(player: Player, path: { any }, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "The player's profile could not be found"
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValue(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	return
end

--[[
	Performs `SetValue()` on the player's temporary data and updates the public data replica accordingly.

	This will only work if the player's temporary data is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.setValueTemp(player: Player, path: { any }, value: any): boolean
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if not privatePlayerTempData then
		warn "The player's temporary data could not be found"
		return
	end

	privatePlayerTempData:SetValue(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privatePlayerTempData.Data))

	return
end

--[[
	Performs `SetValues()` on the player's persistent data and updates the public data replica accordingly.

	This will only work if the player's profile is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.setValuesProfile(player: Player, path: { any }, values: table): boolean
	local profile = profiles[player]

	if not profile then
		warn "The player's profile could not be found"
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValues(path, values)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	return
end

--[[
	Performs `SetValues()` on the player's temporary data and updates the public data replica accordingly.

	This will only work if the player's temporary data is loaded, so ensure that it is beforehand.
]]
function PlayerDataManager.setValuesTemp(player: Player, path: { any }, values: table): boolean
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if not privatePlayerTempData then
		warn "The player's temporary data could not be found"
		return
	end

	privatePlayerTempData:SetValues(path, values)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privatePlayerTempData.Data))

	return
end

--[[
	Subscribes the given player to the profile of the player with the given ID. (This means that the given player wants
	to view the profile of the player with the given ID, and therefore that profile will be routinely retrieved and
	updated in the public replica.) If no ID is given, the player will be unsubscribed from any profile they're
	currently subscribed to.

	A player can only be subscribed to one profile at a time, and the subscription will be cancelled if the player
	leaves the game.

	It is recommended that the player be unsubscribed when they no longer need to view the profile.
]]
function PlayerDataManager.subscribePlayerToProfile(player: Player, profileUserId: number?)
	unsubscribePlayer(player)

	if not profileUserId then return end

	subscriptions[player] = profileUserId

	local subscriptionInfo = subscriptionInfos[profileUserId]

	if subscriptionInfo then
		subscriptionInfo.numberOfSubscribers += 1
		return
	end

	subscriptionInfo = {
		numberOfSubscribers = 1,
		thread = task.spawn(function()
			while true do
				-- First ensure that the player that was subscribed to is offline. If not, we pause the subscription.

				local subscribedPlayer = Players:GetPlayerByUserId(profileUserId)

				while subscribedPlayer do
					task.wait()
				end

				-- Retrieve the profile and wait for the next interval.

				viewOfflineProfileAsync(profileUserId)

				local profileInfo = offlineProfileInfos[profileUserId]

				if time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
					task.wait(OFFLINE_PROFILE_RETRIEVAL_INTERVAL - (time() - profileInfo.lastUpdated))
				end
			end
		end),
	}

	subscriptionInfos[profileUserId] = subscriptionInfo
end

--[[
	Returns a read-only snapshot of the player's persistent data, even if the player is offline.
]]
function PlayerDataManager.viewProfileAsync(playerId: number): table?
	local player = Players:GetPlayerByUserId(playerId)

	if player then
		local profile = viewOnlineProfileAsync(player)

		if profile then return Table.deepSnapshot(profile.Data) end
	end

	local profile = viewOfflineProfileAsync(playerId)

	if profile then return Table.deepSnapshot(profile.Data) end
end

--[[
	Returns a read-only snapshot of the player's temporary data if it exists.
]]
function PlayerDataManager.viewTemp(player: Player): table?
	local privatePlayerTempData = privatePlayerTempDataReplicas[player]

	if privatePlayerTempData then return Table.deepSnapshot(privatePlayerTempData.Data) end
end

--[[
	An event that fires when the player's profile is loaded. The player is passed as the first argument.
]]
PlayerDataManager.profileLoaded = profileLoadedEvent.Event

--[[
	An event that fires when the player's temporary data is loaded. The player is passed as the first argument.
]]
PlayerDataManager.tempDataLoaded = tempDataLoadedEvent.Event

return PlayerDataManager
