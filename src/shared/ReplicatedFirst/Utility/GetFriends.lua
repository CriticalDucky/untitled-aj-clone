local Players = game:GetService "Players"

local cachedFriends = {}
--[[
    Returns a cached list of friends for a player.
    Items in the list are as follows:

	{
    Id	        int64	    The user ID of the friend
    Username	string	    The current username of the friend
    IsOnline	boolean	    Whether or not the user is presently online.
	}
]]
local getFriends = function(userId: number): { [number]: { Id: number, Username: string, IsOnline: boolean } }
	local function fetchFriends()
		local function iterPageItems(pages: FriendPages)
			return coroutine.wrap(function()
				local pagenum = 1
				while true do
					for _, item in ipairs(pages:GetCurrentPage()) do
						coroutine.yield(item, pagenum)
					end
					if pages.IsFinished then break end
					pages:AdvanceToNextPageAsync()
					pagenum = pagenum + 1
				end
			end)
		end

		local success, friendPages = pcall(function()
			return Players:GetFriendsAsync(userId)
		end)

		if not success then return {} end

		local list = {}

		for item, _ in iterPageItems(friendPages) do
			table.insert(list, item)
		end

		cachedFriends[userId] = list

		return list
	end

	return if cachedFriends[userId] then cachedFriends[userId] else fetchFriends()
end

return getFriends
