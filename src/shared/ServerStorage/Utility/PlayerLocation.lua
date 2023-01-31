local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility

local LiveServerData = require(replicatedStorageShared.Server.LiveServerData)
local ServerTypeEnum = require(enumsFolder.ServerType)
local Types = require(utilityFolder.Types)

type Promise = Types.Promise

local PlayerLocation = {}

function PlayerLocation.get(playerId): Promise
    return LiveServerData.get():andThen(function(serverData)
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
                    for partyIndex, serverInfo in pairs(partyTypeData) do
                        if table.find(serverInfo.players, playerId) then
                            playerLocationTable = {
                                serverType = serverType,
                                partyType = partyType,
                                partyIndex = partyIndex,
                            }

                            break
                        end
                    end
                end
            elseif serverType == ServerTypeEnum.game then
                for gameType, gameTypeData in pairs(serverTypeData) do
                    for gameIndex, serverInfo in pairs(gameTypeData) do
                        if table.find(serverInfo.players, playerId) then
                            playerLocationTable = {
                                serverType = serverType,
                                gameType = gameType,
                                gameIndex = gameIndex,
                            }

                            break
                        end
                    end
                end
            end
        end

        return playerLocationTable
    end)
end

return PlayerLocation