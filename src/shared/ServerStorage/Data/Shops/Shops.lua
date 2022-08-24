local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums

local ShopTypeEnum = require(enumsFolder.ShopType)
local ItemType = require(enumsFolder.ItemType)

local AccessoryTypeEnum = require(enumsFolder.AccessoryType)
local FurnitureTypeEnum = require(enumsFolder.FurnitureType)
local HomeTypeEnum = require(enumsFolder.HomeType)

return {
    [ShopTypeEnum.test1] = {
        name = "Test Shop",
        items = {
            { -- Beach Ball
                itemType = ItemType.furniture,
                item = FurnitureTypeEnum.beachBall,
                sellingTime = {
                    {
                        introduction = {
                            day = 1,
                            month = 1,
                            year = 1970
                        },
                        closing = {
                            day = 1,
                            month = 1,
                            year = 1970
                        },
                    },
                },
            }
        },
    }
}