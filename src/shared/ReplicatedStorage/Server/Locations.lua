local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local LocationTypeEnum = require(enumsFolder:WaitForChild("LocationType"))

local Locations = {
    info = {
        [LocationTypeEnum.town] = {
            name = "Town",
            placeId = 10189748812,
            -- populationInfo = {
            --     max = 100,
            --     recommended = 50,
            -- },
            -- cantJoinPlayer = bool
        },
    
        [LocationTypeEnum.forest] = {
            name = "Forest",
            placeId = 10212920968,
        },
    },

    priority = {
        LocationTypeEnum.town,
        LocationTypeEnum.forest,
    },
}

return Locations