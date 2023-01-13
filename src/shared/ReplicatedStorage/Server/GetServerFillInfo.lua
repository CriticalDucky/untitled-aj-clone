local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local settingsFolder = replicatedFirstShared:WaitForChild("Settings")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local GameSettings = require(settingsFolder:WaitForChild("GameSettings"))
local Games = require(serverFolder:WaitForChild("Games"))
local Parties = require(serverFolder:WaitForChild("Parties"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local ServerGroupEnum = require(enumsFolder:WaitForChild("ServerGroup"))
local ServerTypeGroups = require(serverFolder:WaitForChild("ServerTypeGroups"))
local Table = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Table"))

return function(serverType, indexInfo)
    local serverFillInfo = {
        max = 0,
        recommended = 0,
    }

    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, serverType) then
        local locationEnum = indexInfo.locationEnum

        local locationInfo = Locations.info[locationEnum]

        if locationInfo then
            local populationInfo = locationInfo.populationInfo

            if populationInfo then
                serverFillInfo.max = populationInfo.max
                serverFillInfo.recommended = populationInfo.recommended
            else
                serverFillInfo.max = GameSettings.location_maxPlayers
                serverFillInfo.recommended = GameSettings.location_maxRecommendedPlayers
            end
        else
            local LocationType = require(enumsFolder:WaitForChild("LocationType"))

            print(locationEnum, typeof(locationEnum), locationEnum == LocationType.forest)
            Table.print(Locations.info)

            error("Invalid location enum: " .. tostring(locationEnum))
        end
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
        local partyType = indexInfo.partyType

        local partyInfo = Parties[partyType]

        if partyInfo then
            local populationInfo = partyInfo.populationInfo

            if populationInfo then
                serverFillInfo.max = populationInfo.max
                serverFillInfo.recommended = populationInfo.recommended
            else
                serverFillInfo.max = GameSettings.party_maxPlayers
                serverFillInfo.recommended = GameSettings.party_maxRecommendedPlayers
            end
        else
            error("Invalid party enum: " .. tostring(partyType))
        end
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame, serverType) then
        local gameType = indexInfo.gameType

        local gameInfo = Games[gameType]

        if gameInfo then
            local populationInfo = gameInfo.populationInfo

            if populationInfo then
                serverFillInfo.max = populationInfo.max
                serverFillInfo.recommended = populationInfo.recommended
            else
                serverFillInfo.max = GameSettings.location_maxPlayers
                serverFillInfo.recommended = GameSettings.location_maxRecommendedPlayers
            end
        else
            error("Invalid game enum: " .. tostring(gameType))
        end
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, serverType) then
        serverFillInfo.max = GameSettings.home_maxNormalPlayers
    else
        error("Invalid server type: " .. tostring(serverType))
    end

    return serverFillInfo
end