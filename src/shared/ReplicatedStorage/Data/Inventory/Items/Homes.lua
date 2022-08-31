local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local homeTypeEnum = require(enumsFolder.HomeType)
local CurrencyTypeEnum = require(enumsFolder.CurrencyType)

return {
    [homeTypeEnum.testHome] = {
        name = "Test House",
        priceCurrencyType = CurrencyTypeEnum.money,
        price = 30
    }
}