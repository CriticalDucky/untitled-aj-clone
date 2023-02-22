local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local utilityFolder = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data
local serverUtility = serverStorageShared.Utility

local PlayerLocation = require(serverUtility.PlayerLocation)
local GetFriends = require(utilityFolder.GetFriends)
local PlayerData = require(dataFolder.PlayerData)
local Types = require(utilityFolder.Types)

type PlayerData = Types.PlayerData

PlayerData.forAllPlayerData(function(playerData)
    local player = playerData.player

    local friends = GetFriends(player.UserId)

    for _, friend in pairs(friends) do
        PlayerLocation.get(friend.Id):andThen(function(location)
            if location then
                playerData:setValue({"friendLocations", "locations", friend.Id}, location)
            end
        end):catch(function(err)
            warn("Error getting friend location: " .. tostring(err))
        end)
    end
end)