--[[
    This script returns the locations of friends of the local player.
    The backend uses LiveServerData to automatically update the data.

    See FriendLocations.get for more information.
]]

local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"

local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local Types = require(utilityFolder:WaitForChild "Types")

-- type ProfileData = Types.ProfileData
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
function FriendLocations.get(wait: boolean?)--: { [number]: ServerIdentifier }
    -- local data: ProfileData = ReplicatedPlayerData.get(nil, wait)

    -- return Table.deepToNumberKeys(Table.safeIndex(data, "friendLocations", "locations") or {})
end

return FriendLocations
