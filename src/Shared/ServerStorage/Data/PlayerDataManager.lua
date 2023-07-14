local OFFLINE_PROFILE_RETRIEVAL_INTERVAL = 5

--#region Imports

local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageVendor = ServerStorage.Vendor

local ProfileService = require(serverStorageVendor.ProfileService)
local ReplicaService = require(serverStorageVendor.ReplicaService)

local PlayerDataConfig = require(ReplicatedFirst.Shared.Settings.PlayerDataConfig)
local Table = require(ReplicatedFirst.Shared.Utility.Table)

type ProfileStore = typeof(ProfileService.GetProfileStore())
type Profile = typeof(ProfileService.GetProfileStore():LoadProfileAsync())

--#endregion

--#region Profile Setup

local ProfileStore = ProfileService.GetProfileStore("PlayerData", PlayerDataConfig.persistentDataTemplate)

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

--#region Profile Archive

local profileArchive = {}

--[[
	Loads a profile into the archive.

	---

	For each player, the archive contains both the profile and the time the profile was updated. Loading a profile into
	the archive updates the time.

	The profile can be ommitted, in which case the update time is updated, but the profile in the archive does not
	change.
]]
local function loadProfileIntoArchive(playerId: number, profile: Profile?)
	local profileInfo = profileArchive[playerId] or {}
	profileArchive[playerId] = profileInfo

	profileInfo.lastUpdated = time()

	if profile then profileInfo.profile = profile end
end

--#endregion

--#region Active Profiles

local profileLoadedEvent = Instance.new "BindableEvent"

local profileUnloadedEvent = Instance.new "BindableEvent"

local privatePlayerDataReplicas = {}

local profiles = {}

--[[
	Loads the player's data and replicates it to the client.
]]
local function loadPlayerProfileAsync(player: Player)
	local profile = ProfileStore:LoadProfileAsync(`Player_{player.UserId}`, "ForceLoad")

	if not profile then
		warn(`Failed to load profile for {player.Name} (User ID {player.UserId})`)

		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "Failed to load your data."

		return
	end

	-- Set up profile

	profiles[player] = profile

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Manage release of profile

	profile:ListenToRelease(function()
		-- TODO: Reroute player. Ideally this should reroute to the previous place they were if it's open, and simply
		-- reroute them otherwise.

		player:Kick "You have joined another server."

		loadProfileIntoArchive(player.UserId, profile)

		if privatePlayerDataReplicas[player] then
			privatePlayerDataReplicas[player]:Destroy()
			privatePlayerDataReplicas[player] = nil
		end

		profiles[player] = nil

		-- Fire profile unloaded event

		profileUnloadedEvent:Fire(player)
	end)

	if not player:IsDescendantOf(game) then
		profile:Release()

		return
	end

	-- Set up private data replica for player

	local privatePlayerData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerData{player.UserId}__${math.floor(time() * 10)}`),
		Data = profile.Data,
		Replication = "All",
	}
	privatePlayerDataReplicas[player] = privatePlayerData

	-- Set up public data replica for player

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))

	-- Fire profile loaded event

	profileLoadedEvent:Fire(player, profile)
end

local function unloadPlayerProfile(player: Player)
	local profile = profiles[player]

	if profile then profile:Release() end
end

-- Initialization

for _, player in Players:GetPlayers() do
	task.spawn(loadPlayerProfileAsync, player)
end

Players.PlayerAdded:Connect(loadPlayerProfileAsync)

Players.PlayerRemoving:Connect(unloadPlayerProfile)

--#endregion

--#region Offline Profiles

local loadingOfflineProfiles = {}

local function viewOfflineProfileAsync(playerId: number): table?
	-- If the player is online, return their profile

	local player = Players:GetPlayerByUserId(playerId)

	if player and profiles[player] then
		return profiles[player]
	end
	
	-- Simply return the profile if it is young enough

	local profileInfo = profileArchive[playerId]

	if profileInfo and time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
		return profileInfo.profile
	end

	-- Otherwise, retrieve the profile or wait for another retrieval to finish

	if loadingOfflineProfiles[playerId] then
		repeat
			task.wait()
		until not loadingOfflineProfiles[playerId]

		return profileArchive[playerId].profile
	end

	loadingOfflineProfiles[playerId] = true
	local profile = ProfileStore:ViewProfileAsync(`Player_{playerId}`) :: Profile
	loadingOfflineProfiles[playerId] = nil

	loadProfileIntoArchive(playerId, profile)

	player = Players:GetPlayerByUserId(playerId)

	if profile and not profiles[player] then
		publicPlayerDataReplica:SetValue({ playerId }, filterProfileForPublic(profile.Data))
	end

	return profile
end

--#endregion

--#region Profile Subscriptions

-- Map of players to the user ID of the player whose profile they are subscribed to.
local subscriptions = {}

-- Map of user IDs (of players who are subscribed to) to the subscription info.
local subscriptionInfos = {}

local function unsubscribePlayer(player: Player)
	local subscription = subscriptions[player]

	if not subscription then return end

	local subscriptionInfo = subscriptionInfos[subscription]

	subscriptions[player] = nil
	subscriptionInfo.numberOfSubscribers -= 1

	if subscriptionInfo.numberOfSubscribers ~= 0 then return end

	task.cancel(subscriptionInfo.thread)
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

local tempDataUnloadedEvent = Instance.new "BindableEvent"

-- Takes a temporary data and returns a copy filtered for public availability.
local function filterTempDataForPublic(data: table): table
	-- For now, no temporary data is public

	return {}
end

local function loadPlayerTempData(player: Player)
	local initialTempData = Table.deepCopy(PlayerDataConfig.tempDataTemplate)

	local privatePlayerTempData = ReplicaService.NewReplica {
		ClassToken = ReplicaService.NewClassToken(`PrivatePlayerTempData{player.UserId}__${math.floor(time() * 10)}`),
		Data = initialTempData,
		Replication = "All",
	}
	privatePlayerTempDataReplicas[player] = privatePlayerTempData

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(initialTempData))

	-- Fire temp data loaded event

	tempDataLoadedEvent:Fire(player)
end

local function unloadPlayerTempData(player: Player)
	privatePlayerTempDataReplicas[player]:Destroy()
	privatePlayerTempDataReplicas[player] = nil

	publicPlayerTempDataReplica:SetValue({ player }, nil)

	-- Fire temp data unloaded event

	tempDataUnloadedEvent:Fire(player)
end

-- Initialization

for _, player in Players:GetPlayers() do
	loadPlayerTempData(player)
end

Players.PlayerAdded:Connect(loadPlayerTempData)

Players.PlayerRemoving:Connect(unloadPlayerTempData)

--#endregion

--[[
	Manages players' persistent and temporary player data.

	---

	*Should only be used directly by the `PlayerState` module. Other modules should use `PlayerState` instead.*
]]
local PlayerDataManager = {}

--[[
	Performs `ArrayInsert()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arrayInsertPersistentAsync(player: Player, path: { any }, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayInsert(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArrayInsert()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arrayInsertTemp(player: Player, path: { any }, value: any): boolean
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArrayInsert(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArrayRemove()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arrayRemovePersistentAsync(player: Player, path: { any }, index: number): boolean
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArrayRemove(path, index)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArrayRemove()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arrayRemoveTemp(player: Player, path: { any }, index: number): boolean
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArrayRemove(path, index)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `ArraySet()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.arraySetPersistentAsync(player: Player, path: { any }, index: number, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:ArraySet(path, index, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `ArraySet()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.arraySetTemp(player: Player, path: { any }, index: number, value: any): boolean
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:ArraySet(path, index, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Returns an array of all players whose persistent data are loaded.
]]
function PlayerDataManager.getPlayersWithLoadedPersistentData(): { Player }
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

	for player in privatePlayerTempDataReplicas do
		table.insert(players, player)
	end

	return players
end

--[[
	Returns if the player's persistent data is loaded.
]]
function PlayerDataManager.persistentDataIsLoaded(player: Player): boolean
	--
	return profiles[player] ~= nil
end

--[[
	Returns if the player's temporary data is loaded.
]]
function PlayerDataManager.tempDataIsLoaded(player: Player): boolean
	--
	return privatePlayerTempDataReplicas[player] ~= nil
end

--[[
	Performs `SetValue()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.setValuePersistentAsync(player: Player, path: { any }, value: any): boolean
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValue(path, value)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `SetValue()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.setValueTemp(player: Player, path: { any }, value: any): boolean
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:SetValue(path, value)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Performs `SetValues()` on the player's persistent data replica and updates the public data replica accordingly.

	---

	The player's persistent data must be loaded.
]]
function PlayerDataManager.setValuesPersistentAsync(player: Player, path: { any }, values: table): boolean
	local profile = profiles[player]

	if not profile then
		warn "This player's profile is not loaded, so no operation will be performed."
		return
	end

	privatePlayerDataReplicas[player.UserId]:SetValues(path, values)

	publicPlayerDataReplica:SetValue({ player.UserId }, filterProfileForPublic(profile.Data))
end

--[[
	Performs `SetValues()` on the player's temporary data replica and updates the public data replica accordingly.

	---

	The player's temporary data must be loaded.
]]
function PlayerDataManager.setValuesTemp(player: Player, path: { any }, values: table): boolean
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if not privateTempDataReplica then
		warn "This player's temporary data is not loaded, so no operation will be performed."
		return
	end

	privateTempDataReplica:SetValues(path, values)

	publicPlayerTempDataReplica:SetValue({ player.UserId }, filterTempDataForPublic(privateTempDataReplica.Data))
end

--[[
	Subscribes the given player to the persistent data of the (likely) offline player with the given ID. Doing so means
	that the persistent data of the given offline player will be routinely retrieved. If no ID is given, the given
	player will be unsubscribed from any persistent data they're currently subscribed to.

	---

	A player can only be subscribed to one player's persistent data at a time, so subscribing to a new player while
	already having a subscription will cancel the previous one. Any subscription will be cancelled if the player leaves
	the game.

	It is recommended that the player be unsubscribed when they no longer need to view the persistent data to reduce
	unnecessary requests.
]]
function PlayerDataManager.subscribePlayerToPersistentData(player: Player, dataUserId: number?)
	if subscriptions[player] == dataUserId then return end

	unsubscribePlayer(player)

	if not dataUserId then return end

	subscriptions[player] = dataUserId

	local subscriptionInfo = subscriptionInfos[dataUserId]

	if subscriptionInfo then
		subscriptionInfo.numberOfSubscribers += 1
		return
	end

	subscriptionInfo = {
		numberOfSubscribers = 1,
		thread = task.spawn(function()
			while true do
				-- Wait for the next interval. The player must be offline and the profile old enough.

				while true do
					local profileInfo = profileArchive[dataUserId]
					local playerSubscribedTo = Players:GetPlayerByUserId(dataUserId)

					if profileInfo and time() - profileInfo.lastUpdated < OFFLINE_PROFILE_RETRIEVAL_INTERVAL then
						task.wait(OFFLINE_PROFILE_RETRIEVAL_INTERVAL - (time() - profileInfo.lastUpdated))
					elseif playerSubscribedTo and profiles[playerSubscribedTo] then
						task.wait()
					else
						break
					end
				end

				-- Update the profile.

				viewOfflineProfileAsync(dataUserId)
			end
		end),
	}
	subscriptionInfos[dataUserId] = subscriptionInfo
end

--[[
	Returns a copy of the offline player's persistent data for viewing only. Returns `nil` if no such data exists or the
	retrieval failed.
]]
function PlayerDataManager.viewOfflinePersistentDataAsync(playerId: number): table?
	local profile = viewOfflineProfileAsync(playerId)

	if profile then return profile.Data end
end

--[[
	Returns the player's persistent data for viewing only. Returns `nil` if it is not loaded.

	---

	*Do **NOT** motify the returned data under any circumstances! Use the modifier functions in this module instead.*
]]
function PlayerDataManager.viewPersistentData(player: Player): table?
	local profile = profiles[player]

	if profile then return profile.Data end
end

--[[
	Returns the player's temporary data for viewing only. Returns `nil` if it is not loaded.

	---

	*Do **NOT** motify the returned data under any circumstances! Use the modifier functions in this module instead.*
]]
function PlayerDataManager.viewTempData(player: Player): table?
	local privateTempDataReplica = privatePlayerTempDataReplicas[player]

	if privateTempDataReplica then return privateTempDataReplica.Data end
end

--[[
	An event that fires when the player's persistent data is loaded. The player is passed as the first argument.
]]
PlayerDataManager.persistentDataLoaded = profileLoadedEvent.Event

--[[
	An event that fires when the player's persistent data is unloaded. The player is passed as the first argument.
]]
PlayerDataManager.persistentDataUnloaded = profileUnloadedEvent.Event

--[[
	An event that fires when the player's temporary data is loaded. The player is passed as the first argument.
]]
PlayerDataManager.tempDataLoaded = tempDataLoadedEvent.Event

--[[
	An event that fires when the player's temporary data is unloaded. The player is passed as the first argument.
]]
PlayerDataManager.tempDataUnloaded = tempDataUnloadedEvent.Event

return PlayerDataManager
