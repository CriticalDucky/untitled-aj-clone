local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local ConstantsFolder = replicatedStorageShared:WaitForChild("Constants")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local LocationTypeEnum = require(enumsFolder:WaitForChild("LocationType"))
local PlaceConstants = require(ConstantsFolder:WaitForChild("PlaceConstants"))

local Locations = {
    info = {
        [LocationTypeEnum.town] = {
            name = "Town",
            placeId = 10189748812,
            populationInfo = { -- Example; optional
                max = PlaceConstants.location_maxPlayers,
                recommended = PlaceConstants.location_maxRecommendedPlayers,
            },
            cantJoinPlayer = false
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

function Locations.getMaxPlayerCount(locationEnum)
    assert(locationEnum, "locationEnum is nil")

    local locationInfo = Locations.info[locationEnum]

    if locationInfo then
        local populationInfo = locationInfo.populationInfo

        if populationInfo then
            return populationInfo.max
        end
    else
        error("Invalid location enum: " .. tostring(locationEnum))
    end

    return PlaceConstants.location_maxPlayers
end

function Locations.getRecommendedPlayerCount(locationEnum)
    assert(locationEnum, "locationEnum is nil")

    local locationInfo = Locations.info[locationEnum]

    if locationInfo then
        local populationInfo = locationInfo.populationInfo

        if populationInfo then
            return populationInfo.recommended
        end
    else
        error("Invalid location enum: " .. tostring(locationEnum))
    end

    return PlaceConstants.location_maxRecommendedPlayers
end

function Locations.getWorldMaxPlayerCount()
    local maxPlayerCount = 0

    for _, locationEnum in ipairs(Locations.priority) do
        maxPlayerCount += Locations.getMaxPlayerCount(locationEnum)
    end

    return maxPlayerCount
end

function Locations.getWorldRecommendedPlayerCount()
    local recommendedPlayerCount = 0

    for _, locationEnum in ipairs(Locations.priority) do
        recommendedPlayerCount += Locations.getRecommendedPlayerCount(locationEnum)
    end

    return recommendedPlayerCount
end

return Locations