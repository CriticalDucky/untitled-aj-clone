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
            for worldIndex, worldData in pairs(serverTypeData) do
                for locationEnum, serverInfo in pairs(worldData) do
                    if table.find(serverInfo.players, playerId) then
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
                        homeOwner = userId,
                    }

                    break
                end
            end
        elseif serverType == ServerTypeEnum.party then
            for partyType, partyTypeData in pairs(serverTypeData) do
                for privateServerId, serverInfo in pairs(partyTypeData) do
                    if table.find(serverInfo.players, playerId) then
                        playerLocationTable = {
                            serverType = serverType,
                            partyType = partyType,
                            privateServerId = privateServerId,
                        }

                        break
                    end
                end
            end
        end
    end

    return playerLocationTable
end

return PlayerLocation