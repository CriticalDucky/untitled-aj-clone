local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Computed = Fusion.Computed

local playerData = ClientPlayerData.getLocalPlayerData(true)

local FriendLocations = Computed(function()
    return playerData:get().friendLocations
end)

return FriendLocations