local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local enumsFolder = replicatedStorageShared.Enums

local GameServerData = require(serverManagement.GameServerData)
local ServerTypeEnum = require(enumsFolder.ServerType)

local PlayerLocation = {}

function PlayerLocation.get(playerId)
    local serverData = GameServerData.get()

    local playerLocationTable

    for serverType, serverTypeData in pairs(serverData) do
        print("PlayerLocation: ", 1)
        if serverType == ServerTypeEnum.routing then
            for jobId, serverInfo in pairs(serverTypeData) do
                if table.find(serverInfo.players, playerId) then
                    playerLocationTable = {
                        serverType = serverType,
                        jobId = jobId,
                    }

                    break
                end
            end
        elseif serverType == ServerTypeEnum.location then
            print("PlayerLocation: ", 2, time())
            table.foreach(serverTypeData, print)
            for worldIndex, worldData in pairs(serverTypeData) do
                print("PlayerLocation: ", 3)
                for locationEnum, serverInfo in pairs(worldData) do
                    print("PlayerLocation: ", 4)
                    if table.find(serverInfo.players, playerId) then
                        print("PlayerLocation: ", 5)
                        playerLocationTable = {
                            serverType = serverType,
                            worldIndex = worldIndex,
                            locationEnum = locationEnum,
                        }

                        break
                    end
                end
            end
        elseif serverType == ServerTypeEnum.home then
            for userId, serverInfo in pairs(serverTypeData) do
                if table.find(serverInfo.players, playerId) then
                    playerLocationTable = {
                        serverType = serverType,
                        userId = userId,
                    }

                    break
                end
            end
        end
    end

    return playerLocationTable
end

return PlayerLocation