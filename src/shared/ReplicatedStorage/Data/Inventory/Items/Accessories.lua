local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums

local AccessoryTypeEnum = require(enumsFolder.AccessoryType)

return {
    [AccessoryTypeEnum.hat_var1] = {
        name = "Hat",
        price = 30
    },

    [AccessoryTypeEnum.hat_var2] = {
        name = "Hat",
        price = 30
    },
}