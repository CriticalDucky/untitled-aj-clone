local OFFLINE_PROFILE_RETRIEVAL_INTERVAL = 5

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageVendor = ServerStorage.Vendor

local ProfileService = require(serverStorageVendor.ProfileService)
local ReplicaService = require(serverStorageVendor.ReplicaService)

local PlayerDataConstants = require(ReplicatedFirst.Shared.Settings.PlayerDataConstants)
local Table = require(ReplicatedFirst.Shared.Utility.Table)

type ProfileStore = typeof(ProfileService.GetProfileStore())
type Profile = typeof(ProfileService.GetProfileStore():LoadProfileAsync())

--#endregion

--#region Profile Setup

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PlayerDataConstants.profileTemplate)

local publicPlayerDataReplica = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PublicPlayerData",
	Replication = "All",
}

local function filterProfileForPublic(data: table): table
	local filteredData = {}

	filteredData.inventory = Table.deepCopy(data.inventory)

	filteredData.playerSettings = {}
	filteredData.playerSettings.homeLock = data.playerSettings.homeLock

	return filteredData
end

--#endregion

--#region Offline Profiles

local offlineProfileInfos = {}

local loadingOfflineProfiles = {}

--[[
	Loads a profile as offline.

	If no profile is given, the time is updated, but the profile data is not updated, so retrievals still have a
	cooldown.
	
	We don't update the profile when none is given because in case of error, we don't want to overwrite existing data.
]]
local function loadOfflineProfile(playerId: number, profile: Profile?)
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
	local profile = ProfileStore:ViewProfileAsync(`Player_{playerId}`) :: Profile
	loadingOfflineProfiles[playerId] = nil

	loadOfflineProfile(playerId, profile)

	return profile
end

--#endregion

--#region Active Profiles

local privatePlayerDataReplicas = {}

local profiles = {}

local profileLoadedEvent = Instance.new "BindableEvent"

--#region Profile Status Management

--[[
	`nil` means the profile is not loaded and is not loading. Either the profile has not started loading yet, or the
	profile has been released.

	`Loading` means the profile is loading.

	`Loaded` means the profile is loaded.

	`Failed` means the profile failed to load.
]]

local profileStatusLoading = 1
local profileStatusLoaded = 2
local profileStatusFailed = 3

local profileStatuses = {}

local profileStatusUpdatedEvent = Instance.new "BindableEvent"

local function updateProfileStatus(playerId: number, status: number?)
	if status == profileStatuses[playerId] then return end

	profileStatuses[playerId] = status

	profileStatusUpdatedEvent:Fire(playerId, status)

	if status == profileStatusLoaded then profileLoadedEvent:Fire(playerId) end
end

-- Returns whether the profile loaded successfully, or `nil` if the profile is neither loaded nor loading.
local function waitForProfileLoaded(playerId: number)
	if not profileStatuses[playerId] then return end
	if profileStatuses[playerId] == profileStatusLoaded then return true end
	if profileStatuses[playerId] == profileStatusFailed then return false end

	while true do
		local eventPlayerId, eventStatus = profileStatusUpdatedEvent.Event:Wait()

		if eventPlayerId == playerId then return eventStatus == profileStatusLoaded end
	end
end

--#endregion

--[[
	Loads the player's data and replicates it to the client.

	When the player joins, their profile is loaded. The function still loads the profile for a moment (when the
	`ProfileLoaded` event fires) even if the player has left.
]]
local function loadPlayerProfileAsync(player: Player)
	updateProfileStatus(player.UserId, profileStatusLoading)

	local profile = ProfileStore:LoadProfileAsync(`Player_{player.UserId}`, "ForceLoad")

	if not profile then
		warn(`Failed to load profile for {player.Name} (User ID {player.UserId})`)

		updateProfileStatus(player.UserId, profileStatusFailed)

		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "Failed to load your data."

		return
	end

	-- Set up profile

	profiles[player.UserId] = profile

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Set up private data replica for player

	local privatePlayerData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerData{player.UserId}__${math.floor(time() * 10)}`),
		Data = profile.Data,
		Replication = "All",
	}
	privatePlayerDataReplicas[player] = privatePlayerData

	-- Set up public data replica for player

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	-- Update profile status

	updateProfileStatus(player.UserId, profileStatusLoaded)

	-- Manage release of profile

	profile:ListenToRelease(function()
		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "You have joined another server."

		loadOfflineProfile(player.UserId, profile)

		privatePlayerDataReplicas[player]:Destroy()
		privatePlayerDataReplicas[player] = nil

		profiles[player.UserId] = nil

		updateProfileStatus(player.UserId, nil)
	end)

	if not player:IsDescendantOf(game) then
		profile:Release()
		return
	end
end

local function unloadPlayerProfile(player: Player)
	local profile = profiles[player.UserId]

	if profile then profile:Release() end
end

--[[
	Returns the player's profile (waiting if it is loading), or `nil` if it is neither loaded nor loading.
]]
local function getActiveProfileAsync(playerId: number): Profile?
	return profiles[playerId], waitForProfileLoaded(playerId)
end

-- Initialization

for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerProfileAsync, player)
end

Players.PlayerAdded:Connect(loadPlayerProfileAsync)

Players.PlayerRemoving:Connect(unloadPlayerProfile)

--#endregion

--#region Profile Subscriptions

-- Map of players to the user ID of the player whose profile they are subscribed to.
local subscriptions = {}

-- Map of user IDs (of players who are subscribed to) to the subscription info.
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

local tempDataLoadedEvent = Instance.new "BindableEvent"

-- Takes a temporary data and returns a copy filtered for public availability.
local function filterTempDataForPublic(data: table): table
	-- For now, no temporary data is public

	return {}
end

local function loadPlayerTempData(player: Player)
	local initialTempData = Table.deepCopy(PlayerDataConstants.tempDataTemplate)

	local privatePlayerTempData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerTempData{player.UserId}__${math.floor(time() * 10)}`),
		Data = initialTempData,
		Replication = "All",
	}
	privatePlayerTempDataReplicas[player.UserId] = privatePlayerTempData

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(initialTempData))

	tempDataLoadedEvent:Fire(player)
end

local function unloadPlayerTempData(player: Player)
	privatePlayerTempDataReplicas[player.UserId]:Destroy()
	privatePlayerTempDataReplicas[player.UserId] = nil

	publicPlayerTempDataReplica:SetValue({ player.UserId }, nil)
end

local function getPrivateTempDataReplica(player: Player)
	if not privatePlayerTempDataReplicas[player.UserId] then tempDataLoadedEvent.Event:Wait() end

	return privatePlayerTempDataReplicas[player.UserId]
end

-- Initialization

for _, player in Players:GetPlayers() do
	loadPlayerTempData(player)
end

Players.PlayerAdded:Connect(loadPlayerTempData)

Players.PlayerRemoving:Connect(unloadPlayerTempData)

--#endregion

--[[
	Manages persistent and temporary player data using `ProfileService` and `ReplicaService`.

	*Should only be used directly by the `PlayerState` module. Other modules should use `PlayerState` instead.*
]]
local PlayerDataManager = {}

--[[
	Performs `ArrayInsert()` on the player's persistent data replica and updates the public data replica accordingly.
	Waits for the data to load if it is not loaded already.

	No operation will be performed if the player's profile fails to load.
]]
function PlayerDataManager.arrayInsertProfileAsync(player: Player, path: { any }, value: any): boolean
	local profile = getActiveProfileAsync(player)

	if not profile then
		warn "This player's profile failed to load, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayInsert(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArrayInsert()` on the player's temporary data replica and updates the public data replica accordingly.
]]
function PlayerDataManager.arrayInsertTemp(player: Player, path: { any }, value: any): boolean
	local privateTempDataReplica = getPrivateTempDataReplica(player)

	privateTempDataReplica:ArrayInsert(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArrayRemove()` on the player's persistent data replica and updates the public data replica accordingly.
	Waits for the data to load if it is not loaded already.

	No operation will be performed if the player's profile fails to load.
]]
function PlayerDataManager.arrayRemoveProfileAsync(player: Player, path: { any }, index: number): boolean
	local profile = getActiveProfileAsync(player)

	if not profile then
		warn "This player's profile failed to load, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayRemove(path, index)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArrayRemove()` on the player's temporary data replica and updates the public data replica accordingly.
]]
function PlayerDataManager.arrayRemoveTemp(player: Player, path: { any }, index: number): boolean
	local privateTempDataReplica = getPrivateTempDataReplica(player)

	privateTempDataReplica:ArrayRemove(path, index)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArraySet()` on the player's persistent data replica and updates the public data replica accordingly.
	Waits for the data to load if it is not loaded already.

	No operation will be performed if the player's profile fails to load.
]]
function PlayerDataManager.arraySetProfileAsync(player: Player, path: { any }, index: number, value: any): boolean
	local profile = getActiveProfileAsync(player)

	if not profile then
		warn "This player's profile failed to load, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArraySet(path, index, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArraySet()` on the player's temporary data replica and updates the public data replica accordingly.
]]
function PlayerDataManager.arraySetTemp(player: Player, path: { any }, index: number, value: any): boolean
	local privateTempDataReplica = getPrivateTempDataReplica(player)

	privateTempDataReplica:ArraySet(path, index, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Returns an array of all players whose profiles are loaded.
]]
function PlayerDataManager.getPlayersWithLoadedProfiles(): { Player }
	local players = {}

	for playerId in profiles do
		local player = Players:GetPlayerByUserId(playerId)
		if player then table.insert(players, player) end
	end

	return players
end

--[[
	Returns an array of all players whose temporary data is loaded.
]]
function PlayerDataManager.getPlayersWithLoadedTempData(): { Player }
	local players = {}

	for playerId in privatePlayerTempDataReplicas do
		local player = Players:GetPlayerByUserId(playerId)

		if player then table.insert(players, player) end
	end

	return players
end

--[[
	Returns if the player's profile is loaded.
]]
function PlayerDataManager.profileIsLoaded(player: Player): boolean return profiles[player.UserId] ~= nil end

--[[
	Returns if the player's temporary data is loaded.
]]
function PlayerDataManager.tempDataIsLoaded(player: Player): boolean
	--
	return privatePlayerTempDataReplicas[player.UserId] ~= nil
end

--[[
	Performs `SetValue()` on the player's persistent data replica and updates the public data replica accordingly. Waits
	for the data to load if it is not loaded already.

	No operation will be performed if the player's profile fails to load.
]]
function PlayerDataManager.setValueProfileAsync(player: Player, path: { any }, value: any): boolean
	local profile = getActiveProfileAsync(player)

	if not profile then
		warn "This player's profile failed to load, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValue(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `SetValue()` on the player's temporary data replica and updates the public data replica accordingly.
]]
function PlayerDataManager.setValueTemp(player: Player, path: { any }, value: any): boolean
	local privateTempDataReplica = getPrivateTempDataReplica(player)

	privateTempDataReplica:SetValue(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `SetValues()` on the player's persistent data replica and updates the public data replica accordingly.
	Waits for the data to load if it is not loaded already.

	No operation will be performed if the player's profile fails to load.
]]
function PlayerDataManager.setValuesProfileAsync(player: Player, path: { any }, values: table): boolean
	local profile = getActiveProfileAsync(player)

	if not profile then
		warn "This player's profile failed to load, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValues(path, values)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `SetValues()` on the player's temporary data replica and updates the public data replica accordingly.
]]
function PlayerDataManager.setValuesTemp(player: Player, path: { any }, values: table): boolean
	local privateTempDataReplica = getPrivateTempDataReplica(player)

	privateTempDataReplica:SetValues(path, values)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Subscribes* the given player to the profile of the player with the given ID. If no ID is given, the player will be
	unsubscribed from any profile they're currently subscribed to.

	A player can only be subscribed to one profile at a time, so subscribing to a new player while already having a 
	subscription will cancel the previous one. Any subscription will be cancelled if the player leaves the game.

	It is recommended that the player be unsubscribed when they no longer need to view the profile to reduce
	unnecessary requests.

	*\*If a player subscribes to another player's profile, this means that the former player wants to view the profile
	of the latter player, and therefore that profile will be routinely retrieved and updated in the public replica.*
]]
function PlayerDataManager.subscribePlayerToProfile(player: Player, profileUserId: number?)
	if subscriptions[player] == profileUserId then return end

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
			viewOfflineProfileAsync(profileUserId)

			local profileInfo = offlineProfileInfos[profileUserId]

			while true do
				-- Wait for the next interval. The player must be offline and the profile old enough.

				while true do
					if time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
						task.wait(OFFLINE_PROFILE_RETRIEVAL_INTERVAL - (time() - profileInfo.lastUpdated))
					elseif Players:GetPlayerByUserId(profileUserId) then
						task.wait()
					else
						break
					end
				end

				-- Update the profile.

				viewOfflineProfileAsync(profileUserId)
			end
		end),
	}

	subscriptionInfos[profileUserId] = subscriptionInfo
end

--[[
	Returns a read-only snapshot of the player's persistent data, even if the player is offline. Waits for the data to
	load if it is not loaded already.

	If the player doesn't have a profile, `nil` will be returned. Even if the player is online, this may return `nil`
	if the profile failed to load.

	*Do **NOT** motify the returned profile data under any circumstances! It should only be modified internally
	by this module.*
]]
function PlayerDataManager.viewProfileAsync(playerId: number): table?
	if not profileStatuses[playerId] then
		local profile = viewOfflineProfileAsync(playerId)

		return if profile then profile.Data else nil
	end

	local player = Players:GetPlayerByUserId(playerId)

	if player then
		local profile = getActiveProfileAsync(player)

		if not profile then
			warn "This player's profile failed to load, so it cannot be viewed."
			return
		end

		return profile.Data
	end
end

--[[
	Returns a read-only snapshot of the player's temporary data if it exists.

	*Do **NOT** motify the returned profile data under any circumstances! It should only be managed internally by this
	module.*
]]
function PlayerDataManager.viewTemp(player: Player): table?
	local privatePlayerTempData = getPrivateTempDataReplica(player)

	if privatePlayerTempData then return privatePlayerTempData.Data end
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
