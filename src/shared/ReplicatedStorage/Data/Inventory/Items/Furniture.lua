local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local homeItemTypeEnum = require(enumsFolder.FurnitureType)
local CurrencyTypeEnum = require(enumsFolder.CurrencyType)

return {
    [homeItemTypeEnum.beachBall] = {
        name = "Beach Ball",
        priceCurrencyType = CurrencyTypeEnum.money,
        price = 200
    }
}