local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility


local ShopTypeEnum = require(enumsFolder.ShopType)
local ItemType = require(enumsFolder.ItemType)
local AccessoryTypeEnum = require(enumsFolder.AccessoryType)
local FurnitureTypeEnum = require(enumsFolder.FurnitureType)
local HomeTypeEnum = require(enumsFolder.HomeType)
local TimeRange = require(utilityFolder.TimeRange)

local timeRange = TimeRange.new
local group = TimeRange.newGroup

return {
    [ShopTypeEnum.test1] = {
        name = "Test Shop",
        items = {
            { -- Beach Ball
                itemType = ItemType.furniture,
                item = FurnitureTypeEnum.beachBall,
                sellingTime = group {
                    timeRange(
                        {
                            year = 2020,
                            month = 1,
                            day = 1,
                            hour = 0,
                            min = 0,
                            sec = 0
                        },

                        {
                            year = 2025,
                            month = 1,
                            day = 1,
                            hour = 0,
                            min = 0,
                            sec = 0
                        }
                    )
                }
            }
        },
    }
}