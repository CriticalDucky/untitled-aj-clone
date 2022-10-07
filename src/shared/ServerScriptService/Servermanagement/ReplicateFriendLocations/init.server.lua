local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverManagement = serverStorageShared.ServerManagement
local utilityFolder = replicatedFirstShared.Utility
local dataFolder = serverStorageShared.Data

local PlayerLocation = require(serverManagement.PlayerLocation)
local GetFriends = require(utilityFolder.GetFriends)
local PlayerData = require(dataFolder.PlayerData)

Players.PlayerAdded:Connect(function(player)
    local playerData = PlayerData.get(player, true)

    local friends = GetFriends(player.UserId)

    for _, friend in pairs(friends) do
        local friendLocation = PlayerLocation.get(friend.Id)

        if friendLocation then
            playerData:setValue({"friendLocations"}, friend.Id, friendLocation)
        end
    end
end)