local BROADCAST_CHANNEL = "Servers"

local BROADCAST_COOLDOWN = 10
local BROADCAST_COOLDOWN_PADDING = 2

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local messagingFolder = serverStorageShared.Messaging
local serverManagement = serverStorageShared.ServerManagement
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility

local Event = require(utilityFolder.Event)
local Message = require(messagingFolder.Message)
local LocalServerInfo = require(serverManagement.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)

local cachedData = {
    [ServerTypeEnum.routing] = {
        --[[
            [jobId] = {
                serverInfo
            }
        ]]
    },

    [ServerTypeEnum.location] = {
        --[[
            [worldIndex] = {
                [locationEnum] = {
                    serverInfo
                }
            }
        ]]
    },

    [ServerTypeEnum.home] = {
        --[[
            [userId] = {
                serverInfo
            }
        ]]
    },
}
local lastBroadcast = 0

local GameServerData = {}

GameServerData.ServerInfoUpdated = Event.new()

function GameServerData.setCachedData(serverType, indexInfo, serverInfo)
    if serverType == ServerTypeEnum.routing then
        cachedData[serverType][indexInfo.jobId] = serverInfo
    elseif serverType == ServerTypeEnum.location then
        local worldTable = cachedData[serverType][indexInfo.worldIndex] or {}
        worldTable[indexInfo.locationEnum] = serverInfo
        cachedData[serverType][indexInfo.worldIndex] = worldTable
    elseif serverType == ServerTypeEnum.home then
        cachedData[serverType][indexInfo.userId] = serverInfo
    else
        error("GameServerData: Message received with invalid server type")
    end

    GameServerData.ServerInfoUpdated:Fire(serverType, indexInfo, serverInfo)
end

function GameServerData.get(serverType, indexInfo)
    local function check()
        if serverType == ServerTypeEnum.routing then
            return cachedData[serverType][indexInfo.jobId]
        elseif serverType == ServerTypeEnum.location then
            local worldTable = cachedData[serverType][indexInfo.worldIndex]

            if worldTable then
                return worldTable[indexInfo.locationEnum]
            end
        elseif serverType == ServerTypeEnum.home then
            return cachedData[serverType][indexInfo.userId]
        else
            error("GameServerData: Message received with invalid server type")
        end
    end

    local timeToWait = BROADCAST_COOLDOWN + BROADCAST_COOLDOWN_PADDING

    if not serverType then -- Wait for all data, and then return it
        if time() < (timeToWait) then
            task.wait(timeToWait - time())
        end

        return cachedData
    end

    local serverInfo = check()
        
    if serverInfo then
        return serverInfo
    end

    repeat
        task.wait()

        serverInfo = check()
    until time() > timeToWait or serverInfo

    return serverInfo
end

function GameServerData.getLocation(worldIndex, locationEnum)
    return GameServerData.get(ServerTypeEnum.location, {
        worldIndex = worldIndex,
        locationEnum = locationEnum,
    })
end

function GameServerData.publish(serverInfo, indexInfo)
    if not indexInfo then
        warn("GameServerData: Attempted to publish with invalid data")
        return
    end

    lastBroadcast = time()

    Message.publish(BROADCAST_CHANNEL, {
        serverType = LocalServerInfo.serverType,
        serverInfo = serverInfo,
        indexInfo = indexInfo,
    })
end

function GameServerData.canPublish()
    return time() - lastBroadcast >= BROADCAST_COOLDOWN
end

Message.subscribe(BROADCAST_CHANNEL, function(message)
    local message = message.Data

    print("GameServerData: Received message from server")

    GameServerData.setCachedData(message.serverType, message.indexInfo, message.serverInfo)
end)

return GameServerData

