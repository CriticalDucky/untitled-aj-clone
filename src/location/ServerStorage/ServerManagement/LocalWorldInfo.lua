local CACHE_UPDATE_INTERVAL = 90

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local WorldData = require(serverManagement:WaitForChild("WorldData"))

local privateServerId = game.PrivateServerId

local lastCacheUpdate = 0
local cachedData
local worldIndex
local locationEnum

do
    local worlds = WorldData.get()

    if worlds then
        for i, world in ipairs(worlds) do
            for enum, location in pairs(world.locations) do
                if location.privateServerId == privateServerId then
                    worldIndex = i
                    locationEnum = enum

                    break
                end
            end

            if worldIndex then
                break
            end
        end
    else
        --TODO: Error handling
        warn("LocalWorldInfo: Failed to get world data")
    end
end

local localWorldInfo = {}

localWorldInfo.worldIndex = worldIndex
localWorldInfo.locationEnum = locationEnum

return localWorldInfo