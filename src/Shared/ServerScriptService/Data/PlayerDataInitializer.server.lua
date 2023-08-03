--!strict

--#region Imports

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local Enums = require(ReplicatedFirst.Shared.Enums)
local ItemTypeHome = Enums.ItemTypeHome
local PlayerData = require(ReplicatedStorage.Shared.Data.PlayerData)
local HomeItems = PlayerData.Inventory.HomeItems
local Homes = PlayerData.Homes
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local TeleportUtility = require(ServerStorage.Shared.Utility.TeleportUtility)
local ServerStorageConfiguration = require(ServerStorage.Shared.Configuration)
local PlaceIDs = ServerStorageConfiguration.PlaceIDs
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ItemHome = Types.ItemHome
type ServerDataHome = Types.ServerInfoHome

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--#endregion

local function initializePersistentData(player: Player)
	local data = PlayerDataManager.viewPersistentData(player)

	assert(data)

	-- Initialize default home if none exists.

	local homes = data.inventory.homes

	local hasHomes = false

	for _, _ in pairs(homes) do
		hasHomes = true
		break
	end

	if not hasHomes then
		local newDefaultHome: ItemHome = {
			type = ItemTypeHome.defaultHome,
		}

		local newDeveloperHome: ItemHome = {
			type = ItemTypeHome.developerHome,
		}

		HomeItems.addHome(newDefaultHome, player)
		HomeItems.addHome(newDeveloperHome, player) -- TODO: Remove.
	end

	-- Set selected home if none is selected.

	if not data.home.selected then
		for homeId in pairs(homes) do
			Homes.setSelectedHome(homeId, player)
			break
		end
	end

	-- Reserve a home server if none is reserved.

	if not data.home.server then
		local reserveSuccess, newAccessCode, newServerId = TeleportUtility.safeReserveServerAsync(PlaceIDs.home)

		if reserveSuccess then
			local serverData: ServerDataHome = {
				homeOwner = player.UserId,
				type = "home",
			}

			local registerServerSuccess =
				DataStoreUtility.safeSetAsync(serverDictionary, newServerId, serverData, { player.UserId })

			if registerServerSuccess and PlayerDataManager.persistentDataIsLoaded(player) then
				PlayerDataManager.setValuePersistent(player, { "home", "server", "accessCode" }, newAccessCode)
				PlayerDataManager.setValuePersistent(player, { "home", "server", "privateServerId" }, newServerId)
			else
				warn(`Failed to register a home server for {player}!`)
			end
		else
			warn(`Failed to reserve a home server for {player}!`)
		end
	end
end

for _, player in pairs(PlayerDataManager.getPlayersWithLoadedPersistentData()) do
	initializePersistentData(player)
end

PlayerDataManager.persistentDataLoaded:Connect(initializePersistentData)
