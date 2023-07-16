--#region Imports

local Currency = require(script.Currency)
local Settings = require(script.Settings)

--#endregion

--[[
    Manages the player's state.
]]
local PlayerState = {}

PlayerState.currency = Currency

PlayerState.settings = Settings

return PlayerState
