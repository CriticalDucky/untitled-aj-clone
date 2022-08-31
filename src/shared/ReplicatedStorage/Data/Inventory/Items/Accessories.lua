local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local AccessoryTypeEnum = require(enumsFolder.AccessoryType)
local CurrencyTypeEnum = require(enumsFolder.CurrencyType)

return {
    [AccessoryTypeEnum.hat_var1] = {
        name = "Hat",
        priceCurrencyType = CurrencyTypeEnum.money,
        price = 100,
    },

    [AccessoryTypeEnum.hat_var2] = {
        name = "Hat",
        priceCurrencyType = CurrencyTypeEnum.money,
        price = 30
    },
}