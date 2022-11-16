local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local ItemCategory = require(enumsFolder.ItemCategory)

return {
    [ItemCategory.home] = {
        placedItems = {},
    },
}