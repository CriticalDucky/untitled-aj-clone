--#region Imports

local Currency = require(script.Currency)
local Homes = require(script.Homes)
local Inventory = require(script.Inventory)
local PublicPlayerData = require(script.PublicPlayerData)
local Settings = require(script.Settings)

--#endregion

--[[
    Manages the player's state.
]]
local PlayerState = {}

PlayerState.Currency = Currency

PlayerState.Homes = Homes

PlayerState.Inventory = Inventory

PlayerState.PublicPlayerData = PublicPlayerData

PlayerState.Settings = Settings

return PlayerState
