local Players = game:GetService("Players")

local cachedFriends = {}

local getFriends = function(playerId)
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
    
        local friendPages = Players:GetFriendsAsync(playerId)
    
        local list = {}
    
        for item, _ in iterPageItems(friendPages) do
            table.insert(list, item)
        end

        cachedFriends[playerId] = list

        return list
    end

    return cachedFriends[playerId] or fetchFriends()
end

return getFriends