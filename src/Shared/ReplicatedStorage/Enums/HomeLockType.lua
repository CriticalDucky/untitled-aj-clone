--[[
    The type of home lock.
]]
local HomeLockType = {
    -- Only the player's friends can access their home.
	friendsOnly = 3,

    -- Only the player can access their home.
	locked = 2,

    -- Anyone can access the player's home.
	unlocked = 1,
}

return HomeLockType
