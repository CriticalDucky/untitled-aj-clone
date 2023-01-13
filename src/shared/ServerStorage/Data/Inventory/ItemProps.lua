local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local ItemCategory = require(enumsFolder.ItemCategory)

-- If you add something here, make sure to add it to the InventoryItem type in src\Shared\ReplicatedFirst\Utility\Types.lua

return {
    [ItemCategory.home] = {
        placedItems = {},
    },
}