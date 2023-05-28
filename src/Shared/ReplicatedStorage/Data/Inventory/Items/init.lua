local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemCategory = require(ReplicatedStorage.Shared.Enums.ItemCategory)
local Types = require(ReplicatedStorage.Shared.Utility.Types)

type InventoryCategory = Types.InventoryCategory
type InventoryItem = Types.InventoryItem

local Items = {
	[ItemCategory.furniture] = require(script:WaitForChild "Furniture"),
	[ItemCategory.accessory] = require(script:WaitForChild "Accessories"),
	[ItemCategory.home] = require(script:WaitForChild "Homes"),
}

--[[
    Returns the furniture category
]]
function Items.getFurniture(): InventoryCategory
	return Items[ItemCategory.furniture]
end

--[[
    Returns the accessories category
]]
function Items.getAccessories(): InventoryCategory
	return Items[ItemCategory.accessory]
end

--[[
    Returns the homes category
]]
function Items.getHomes(): InventoryCategory
	return Items[ItemCategory.home]
end

--[[
    Returns a furniture item from the given furniture enum
]]
function Items.getFurnitureItem(furnitureEnum)
	return Items.getFurniture()[furnitureEnum]
end

--[[
    Returns an accessory item from the given accessory enum
]]
function Items.getAccessoryItem(accessoryEnum)
	return Items.getAccessories()[accessoryEnum]
end

--[[
    Returns a home item from the given home enum
]]
function Items.getHomeItem(homeEnum)
	return Items.getHomes()[homeEnum]
end

--[[
    Returns an item from the given item category and item enum
]]
function Items.getItem(itemCategory, itemEnum): InventoryItem
	return Items[itemCategory] and Items[itemCategory][itemEnum]
end

return Items
