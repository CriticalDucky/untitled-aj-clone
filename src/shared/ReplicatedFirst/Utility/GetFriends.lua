--[[
    Returns a cached list of friends for a player.
    Items in the list are as follows:

    Id	        int64	    The user ID of the friend
    Username	string	    The current username of the friend
    IsOnline	boolean	    Whether or not the user is presently online.
]]

local Players = game:GetService("Players")

local utilityFolder = game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility")
local enumsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Enums")

local Promise = require(utilityFolder:WaitForChild("Promise"))
local Types = require(utilityFolder:WaitForChild("Types"))
local Param = require(utilityFolder:WaitForChild("Param"))
local PlayerFormat = require(enumsFolder:WaitForChild("PlayerFormat"))

type LocalPlayerParam = Types.LocalPlayerParam
type Promise = Types.Promise

local cachedFriends = {}

local getFriends = function(player: LocalPlayerParam): Promise
	return Param.localPlayerParam(player, PlayerFormat.userId):andThen(function(userId)
		local function fetchFriends()
			local function iterPageItems(pages: FriendPages)
				return coroutine.wrap(function()
					local pagenum = 1
					while true do
						for _, item in ipairs(pages:GetCurrentPage()) do
							coroutine.yield(item, pagenum)
						end
						if pages.IsFinished then
							break
						end
						pages:AdvanceToNextPageAsync()
						pagenum = pagenum + 1
					end
				end)
			end

			local success, friendPages = pcall(function()
				return Players:GetFriendsAsync(userId)
			end)

			if not success then
				return {}
			end

			local list = {}

			for item, _ in iterPageItems(friendPages) do
				table.insert(list, item)
			end

			cachedFriends[player] = list

			return list
		end

		return if cachedFriends[player] then Promise.resolve(cachedFriends[player]) else Promise.try(fetchFriends)
	end)
end

return getFriends
