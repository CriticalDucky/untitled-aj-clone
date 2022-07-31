local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local Locations = require(serverManagement:WaitForChild("Locations"))

local serverType do
    for _, locationInfo in pairs(Locations.info) do
        if locationInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.location
        end
    end

    if not serverType then
        serverType = ServerTypeEnum.routing
    end
end

local localServerInfo = {}

localServerInfo.serverType = serverType

return localServerInfo