local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local enumsFolder = ReplicatedStorage.Shared.Enums

local homeTypeEnum = require(enumsFolder.HomeType)
local CurrencyTypeEnum = require(enumsFolder.CurrencyType)
local Model = require(ReplicatedFirst.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
    return Model(ModelType.home, name)
end

return {
    [homeTypeEnum.defaultHome] = {
        name = "Default Home",
        priceCurrencyType = CurrencyTypeEnum.money,
        price = 30,
        model = model("DefaultHome"),
    }
}