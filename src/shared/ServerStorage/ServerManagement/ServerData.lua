local DATASTORE_MAX_RETRIES = 10
local SERVERDATA_KEY = "serverData"

local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Locations = require(serverManagement:WaitForChild("Locations"))
local WorldNames = require(serverManagement:WaitForChild("WorldNames"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))

local serversDatastore = DataStoreService:GetDataStore("Servers")

local ServerData = {}

local function updateAsyncSafe(key, transformFunction)
    local function try()
        return pcall(function()
            return serversDatastore:UpdateAsync(key, transformFunction)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success = try()

        if success then
            return true
        end
    end

    warn("Failed to update data store")
    return false
end

local function getAsyncSafe(key)
    local function try()
        return pcall(function()
            return serversDatastore:GetAsync(key)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, serverData = try()

        if success then
            return if serverData == nil then {} else serverData
        end
    end

    return
end

function ServerData.get()
    return getAsyncSafe(SERVERDATA_KEY)
end

function ServerData.update(transformFunction)
    return updateAsyncSafe(SERVERDATA_KEY, transformFunction)
end

function ServerData.addWorld()
    local world do
        world = {
            locations = {},
            name = "",
        }

        for enum, location in pairs(Locations.info) do
            local serverCode, privateServerId = TeleportService:ReserveServer(location.placeId)

            local locationTable = {
                serverCode = serverCode,
                privateServerId = privateServerId,
                fillStatus = FillStatusEnum.notFilled,
            }

            world.locations[enum] = locationTable
        end
    end

    return ServerData.update(function(serverData)
        local worlds = serverData.worlds
        local worldIndex = #worlds + 1

        world.name = WorldNames[worldIndex] or ("World " .. worldIndex)
        table.insert(worlds, world)

        return serverData
    end), world
end

function ServerData.findAvailableWorldAndLocation(forcedLocation)
    local serverData = ServerData.get()

    if serverData == nil then
        warn("No server data found")
        return
    end

    local availableWorld, availableLocationEnum do
        for _, world in ipairs(serverData.worlds) do
            for _, locationEnum in ipairs(Locations.priority) do
                local locationData = Locations.info[locationEnum]
                local location = world.locations[locationEnum]

                if location.fillStatus ~= FillStatusEnum.filled and locationData.spawnable and (if forcedLocation then locationEnum == forcedLocation else true) then
                    availableWorld = world
                    availableLocationEnum = locationEnum

                    break
                end
            end

            if availableWorld then
                break
            end
        end

        if not availableWorld then
            local success, newWorld = ServerData.addWorld()

            if success then
                availableWorld = newWorld
                availableLocationEnum = Locations.priority[1]
            else
                warn("Failed to add world")
                return
            end
        end
    end

    return availableWorld, availableLocationEnum
end

return ServerData