local itemCategory = require(game:GetService("ReplicatedStorage").Shared.Enums.ItemCategory)
local Promise = require(game:GetService("ReplicatedFirst").Shared.Utility.Promise)

local Items = {
    [itemCategory.furniture] = require(script:WaitForChild("Furniture")),
    [itemCategory.accessory] = require(script:WaitForChild("Accessories")),
    [itemCategory.home] = require(script:WaitForChild("Homes")),
}

--[[
    Returns a promise that resolves with the furniture category
]]
function Items.getFurniture()
    return Promise.resolve(Items[itemCategory.furniture])
end

--[[
    Returns a promise that resolves with the accessories category
]]
function Items.getAccessories()
    return Promise.resolve(Items[itemCategory.accessory])
end

--[[
    Returns a promise that resolves with the homes category
]]
function Items.getHomes()
    return Promise.resolve(Items[itemCategory.home])
end

--[[
    Returns a promise that resolves with a furniture item
]]
function Items.getFurnitureItem(furnitureEnum)
    return Items.getFurniture():andThen(function(furniture)
        return furniture[furnitureEnum]
    end)
end

--[[
    Returns a promise that resolves with an accessory item
]]
function Items.getAccessoryItem(accessoryEnum)
    return Items.getAccessories():andThen(function(accessories)
        return accessories[accessoryEnum]
    end)
end

--[[
    Returns a promise that resolves with a home item
]]
function Items.getHomeItem(homeEnum)
    return Items.getHomes():andThen(function(homes)
        return homes[homeEnum]
    end)
end

--[[
    Returns a promise that resolves with an item
]]
function Items.getItem(itemCategory, itemEnum)
    return Promise.try(function()
        return Items[itemCategory][itemEnum]
    end)
end

return Items