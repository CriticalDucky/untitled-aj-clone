local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Types = require(utilityFolder:WaitForChild("Types"))
local Table = require(utilityFolder:WaitForChild("Table"))
local Computed = Fusion.Computed

type ProfileData = Types.ProfileData
type ServerIdentifier = Types.ServerIdentifier

local playerData = ClientPlayerData.getData()

-- Gets a table of locations of friends. Warning: This can be nil.
-- Returns a promise with a table of Server Identifiers.
local FriendLocations = Computed(function()
    local data: ProfileData = playerData:getNow()

    return Table.safeIndex(data, "friendLocations", "locations") :: {[string]: ServerIdentifier}
end)

return FriendLocations