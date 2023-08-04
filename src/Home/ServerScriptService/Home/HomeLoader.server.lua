--!strict

--#region Imports

local DataStoreService = game:GetService "DataStoreService"
local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local HomeInfo = require(ServerStorage.Configuration.HomeInfo)
local HomeModels = require(ServerStorage.Models.HomeModels)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local ServerDirectives = require(ServerStorage.Shared.Utility.ServerDirectives)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ServerInfoHome = Types.ServerInfoHome

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

local privateServerId = game.PrivateServerId

local getServerDataSuccess, serverData: ServerInfoHome? =
	DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

if not getServerDataSuccess or not serverData then ServerDirectives.shutDownServer "Failed to retrieve server data." end

assert(serverData)

local homeOwner = serverData.homeOwner

--#endregion

local loadedHomeType: number?

while task.wait() do
	local data = PlayerDataManager.viewOfflinePersistentDataAsync(homeOwner)

	if not data then
		warn "Failed to retrieve home owner's data."
		continue
	end
	assert(data)

	local selectedHome = data.home.selected

	if not selectedHome then
		warn "Home owner has no selected home."
		continue
	end
	assert(selectedHome)

	local selectedHomeData = data.inventory.homes[selectedHome]
	assert(selectedHomeData)

	local selectedHomeType = selectedHomeData.type

	if loadedHomeType == selectedHomeType then continue end

	-- Load new home type

	local player = Players:GetPlayerByUserId(homeOwner)

	if player then
		local character = player.Character

		if character then character:Destroy() end
	end

	if loadedHomeType then
		-- Unload old home type

		HomeInfo[loadedHomeType].model.Parent = HomeModels.modelStore
	end

	HomeInfo[selectedHomeType].model.Parent = workspace

	loadedHomeType = selectedHomeType

	player = Players:GetPlayerByUserId(homeOwner)

	if player then player:LoadCharacter() end
end
