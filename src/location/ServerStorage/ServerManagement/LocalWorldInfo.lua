local CACHE_UPDATE_INTERVAL = 90

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ServerData = require(serverManagement:WaitForChild("ServerData"))

local privateServerId = game.PrivateServerId

local lastCacheUpdate = 0
local cachedData
local currentWorldIndex
local currentLocationEnum

local function parseServerData(serverData)
    cachedData = serverData.worlds[currentWorldIndex]
end

do
    local serverData = ServerData.get()

    if serverData then
        local worlds = serverData.worlds

        for i, world in ipairs(worlds) do
            for enum, location in pairs(world.locations) do
                if location.privateServerId == privateServerId then
                    currentWorldIndex = i
                    currentLocationEnum = enum

                    break
                end
            end

            if currentWorldIndex then
                break
            end
        end
    else
        --TODO: Error handling
        warn("LocalWorldInfo: Failed to get server data")
    end
end

local localWorldInfo = {}

localWorldInfo.worldIndex = currentWorldIndex
localWorldInfo.locationEnum = currentLocationEnum

function localWorldInfo.updateCachedData()
    lastCacheUpdate = time()

    local serverData = ServerData.get()

    if serverData then
        parseServerData(serverData)
    else
        warn("Failed to get server data")
    end
end

function localWorldInfo.getWorldData(getUpdated)
    if cachedData == nil or getUpdated then
        localWorldInfo.updateCachedData()
    end

    return cachedData
end

function localWorldInfo.getLocationData(getUpdated)
    if cachedData == nil or getUpdated then
        localWorldInfo.updateCachedData()
    end

    return cachedData.locations[currentLocationEnum]
end

RunService.Stepped:Connect(function(t, deltaTime)
    if time() - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        localWorldInfo.updateCachedData()
    end
end)

return localWorldInfo