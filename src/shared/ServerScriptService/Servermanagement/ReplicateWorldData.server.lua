local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage.Shared
local serverManagementFolder = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local GameServerData = require(serverManagementFolder.GameServerData)
local ReplicaService = require(dataFolder.ReplicaService)
local ServerTypeEnum = require(enumsFolder.ServerType)
local WorldData = require(serverManagementFolder.WorldData)

local mergedData = {}

local function filterServerInfo(serverInfo)
    if not serverInfo then
        return nil
    end

    local newTable = {}
                                                                                                 
    for key, value in pairs(serverInfo) do
        if key == "players" then
            newTable[key] = #value

            continue
        end

        newTable[key] = value
    end

    return newTable
end

local function newWorldElement(worldIndex, worldData)
    local worldTable = {}

    for locationEnum, _ in pairs(worldData.locations) do
        worldTable[locationEnum] = {
            serverInfo = filterServerInfo(GameServerData.getLocation(worldIndex, locationEnum)),
        }
    end

    return worldTable
end

for worldIndex, worldData in pairs(WorldData.get()) do
    mergedData[worldIndex] = newWorldElement(worldIndex, worldData)
end

local gameServerDataReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("Worlds"),
    Data = mergedData,
    Replication = "All"
})

GameServerData.ServerInfoUpdated:Connect(function(serverType, indexInfo, serverInfo)
    if serverType == ServerTypeEnum.location then
        local worldIndex = indexInfo.worldIndex
        local locationEnum = indexInfo.locationEnum

        if not mergedData[worldIndex] then
            return
        end

        gameServerDataReplica:SetValue({worldIndex, locationEnum, "serverInfo"}, filterServerInfo(serverInfo))
    end
end)

WorldData.WorldsUpdated:Connect(function()
    for worldIndex, worldData in pairs(WorldData.get()) do
        if not mergedData[worldIndex] then
            gameServerDataReplica:SetValue({worldIndex}, newWorldElement(worldIndex, worldData))
        end
    end
end)