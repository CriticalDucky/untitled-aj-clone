local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local utilityFolder = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data
local serverUtility = serverStorageShared.Utility

local PlayerLocation = require(serverUtility.PlayerLocation)
local Friends = require(utilityFolder.Friends)
local PlayerDataManager = require(dataFolder.PlayerDataManager)

local function initFriendLocations(player: Player)
	local friends = Friends.get(player.UserId)

	for _, friendData in pairs(friends) do
		local playerLocation = PlayerLocation.get(friendData.Id)

		if playerLocation then
			PlayerDataManager.setValueTemp(player, { "friendLocations", friendData.Id }, playerLocation)
		end
	end
end

for _, player in PlayerDataManager.getPlayersWithLoadedTempData() do
	initFriendLocations(player)
end

PlayerDataManager.tempDataLoaded:Connect(initFriendLocations)
