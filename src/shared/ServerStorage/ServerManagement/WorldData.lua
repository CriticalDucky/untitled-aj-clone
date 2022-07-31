local WORLDS_KEY = "worlds"

local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = serverStorageShared:WaitForChild("Utility")

local Locations = require(serverManagement:WaitForChild("Locations"))
local WorldNames = require(serverManagement:WaitForChild("WorldNames"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))
local DataStore = require(utilityFolder:WaitForChild("DataStore"))
local WorldFillData = require(serverManagement:WaitForChild("WorldFillData"))
local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))

local worldsDataStore = DataStoreService:GetDataStore("Worlds")

local WorldData = {}

function WorldData.get()
    return DataStore.safeGet(worldsDataStore, WORLDS_KEY)
end

function WorldData.update(transformFunction)
    return DataStore.safeUpdate(worldsDataStore, WORLDS_KEY, transformFunction)
end

function WorldData.addWorld()
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
            }

            world.locations[enum] = locationTable
        end
    end

    return WorldData.update(function(worlds)
        local worldIndex = #worlds + 1

        world.name = WorldNames[worldIndex] or ("World " .. worldIndex)
        table.insert(worlds, world)

        return worlds
    end), world
end

function WorldData.findAvailable(forcedLocation)
    local worlds = WorldData.get()

    if worlds == nil then
        warn("No server data found")
        return
    end

    local availableWorld, availableLocationEnum do
        for worldIndex, world in ipairs(worlds) do
            for _, locationEnum in ipairs(Locations.priority) do
                local fillData = WorldFillData.get(worldIndex, locationEnum)

                if
                    (if forcedLocation then locationEnum == forcedLocation else true) and
                    (if fillData then (fillData == FillStatusEnum.notFilled) else true)
                then
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
            local success, newWorld = WorldData.addWorld()

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

return WorldData