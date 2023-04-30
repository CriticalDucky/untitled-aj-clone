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

PlayerDataManager.forAllPlayerData(function(playerData)
	local player = playerData.player

	local friends = Friends.get(player.UserId)

	for _, friendData in pairs(friends) do
		local playerLocation = PlayerLocation.get(friendData.Id)

		if playerLocation then
			playerData:setValue({ "friendLocations", "locations", friendData.Id }, playerLocation)
		end
	end
end)
