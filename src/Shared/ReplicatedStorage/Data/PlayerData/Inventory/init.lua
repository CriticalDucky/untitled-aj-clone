local AccessoryItems = require(script.AccessoryItems)
local FurnitureItems = require(script.FurnitureItems)
local HomeItems = require(script.HomeItems)

--[[
    A submodule of `PlayerData` that handles the player's inventory.
]]
local Inventory = {}

Inventory.AccessoryItems = AccessoryItems

Inventory.FurnitureItems = FurnitureItems

Inventory.HomeItems = HomeItems

return Inventory