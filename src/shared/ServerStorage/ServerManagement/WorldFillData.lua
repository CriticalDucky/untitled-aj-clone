local BROADCAST_CHANNEL = "WorldFillData"

local BROADCAST_COOLDOWN = 10
local BROADCAST_COOLDOWN_PADDING = 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local messagingFolder = serverStorageShared:WaitForChild("Messaging")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Message = require(messagingFolder:WaitForChild("Message"))
local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

local cachedData = {}
local lastBroadcast = 0

local WorldFillData = {}

function WorldFillData.get(worldIndex, locationEnum)
    local function check()
        if cachedData[worldIndex] then
            return cachedData[worldIndex][locationEnum]
        end
    end

    local fillStatus = check()
        
    if fillStatus then
        return fillStatus
    end

    repeat
        task.wait()

        fillStatus = check()
    until time() > (BROADCAST_COOLDOWN + BROADCAST_COOLDOWN_PADDING) or fillStatus

    return fillStatus
end

function WorldFillData.localSet(worldIndex, locationEnum, fillStatus)
    cachedData[worldIndex] = cachedData[worldIndex] or {}
    cachedData[worldIndex][locationEnum] = fillStatus 
end

function WorldFillData.publish(fillStatus)
    if LocalServerInfo.serverType == ServerTypeEnum.routing then
        warn("WorldFillData: Cannot publish fill status on routing server")
        return
    end

    if time() - lastBroadcast < BROADCAST_COOLDOWN then
        return
    end

    lastBroadcast = time()

    local serverStorageLocation = ServerStorage:WaitForChild("Location")
    local serverManagementLocation = serverStorageLocation:WaitForChild("ServerManagement")

    local LocalWorldInfo = require(serverManagementLocation:WaitForChild("LocalWorldInfo"))

    Message.publish(BROADCAST_CHANNEL, {
        fillStatus = fillStatus,

        worldIndex = LocalWorldInfo.worldIndex,
        locationEnum = LocalWorldInfo.locationEnum,
    })
end

Message.subscribe(BROADCAST_CHANNEL, function(message)
    local fillStatus = message.Data.fillStatus
    local worldIndex = message.Data.worldIndex
    local locationEnum = message.Data.locationEnum

    if not worldIndex or not locationEnum then
        warn("WorldFillData: Invalid message received")
        return
    end

    local world do
        cachedData[worldIndex] = cachedData[worldIndex] or {}

        world = cachedData[worldIndex]
    end

    world[locationEnum] = fillStatus
end)

return WorldFillData

