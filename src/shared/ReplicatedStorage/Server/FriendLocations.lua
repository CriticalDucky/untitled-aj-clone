local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ClientPlayerData = require(dataFolder:WaitForChild "ClientPlayerData")
local Types = require(utilityFolder:WaitForChild "Types")
local Table = require(utilityFolder:WaitForChild "Table")

type ProfileData = Types.ProfileData
type ServerIdentifier = Types.ServerIdentifier

local FriendLocations = {}

function FriendLocations.get()
    local data: ProfileData = ClientPlayerData.getData():getNow()

    return Table.safeIndex(data, "friendLocations", "locations") :: { [string]: ServerIdentifier } or {}
end

return FriendLocations
