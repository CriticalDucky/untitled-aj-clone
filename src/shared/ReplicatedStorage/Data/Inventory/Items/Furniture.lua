local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local enumsFolder = ReplicatedStorage.Shared.Enums

local FurnitureType = require(enumsFolder.FurnitureType)
local CurrencyTypeEnum = require(enumsFolder.CurrencyType)
local Model = require(ReplicatedFirst.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
    return Model(ModelType.furniture, name)
end

return {
    [FurnitureType.beachBall] = {
        name = "Beach Ball",
        priceCurrencyType = CurrencyTypeEnum.money,
        model = model("BeachBall"),
        price = 200
    }
}