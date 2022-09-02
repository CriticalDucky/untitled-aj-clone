local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums

local ShopTypeEnum = require(enumsFolder.ShopType)

return {
    [ShopTypeEnum.test1] = true
}