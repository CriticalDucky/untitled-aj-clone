local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ShopTypeEnum = require(enumsFolder:WaitForChild("ShopType"))
local ItemType = require(enumsFolder:WaitForChild("ItemType"))
local AccessoryTypeEnum = require(enumsFolder:WaitForChild("AccessoryType"))
local FurnitureTypeEnum = require(enumsFolder:WaitForChild("FurnitureType"))
local HomeTypeEnum = require(enumsFolder:WaitForChild("HomeType"))
local TimeRange = require(utilityFolder:WaitForChild("TimeRange"))

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