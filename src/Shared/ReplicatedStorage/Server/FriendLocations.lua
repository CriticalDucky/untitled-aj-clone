--[[
    This script returns the locations of friends of the local player.
    The backend uses LiveServerData to automatically update the data.

    See FriendLocations.get for more information.
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local utilityFolder = replicatedStorageShared:WaitForChild "Utility"

local ReplicatedPlayerData = require(dataFolder:WaitForChild "ReplicatedPlayerData")
local Types = require(utilityFolder:WaitForChild "Types")
local Table = require(utilityFolder:WaitForChild "Table")

type ProfileData = Types.ProfileData
type ServerIdentifier = Types.ServerIdentifier

local FriendLocations = {}

--[[
    Takes in "wait" that decides whether to wait for the data to be replicated or not.

    Returns a table of friend locations. The keys are the friend's userIds (string) and the values are the server identifiers.

    ```lua
    {
        [userId] = serverIdentifier,
        ... -- for all friends
    }
    ```
]]
function FriendLocations.get(wait: boolean?): { [number]: ServerIdentifier }
    local data: ProfileData = ReplicatedPlayerData.get(nil, wait)

    return Table.deepToNumberKeys(Table.safeIndex(data, "friendLocations", "locations") or {})
end

return FriendLocations
