local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local utilityFolder = replicatedFirstShared.Utility
local serverFolder = replicatedStorageShared.Server
local enums = replicatedStorageShared.Enums

local Games = require(serverFolder.Games)
local GameJoinType = require(enums.GameJoinType)
local Promise = require(utilityFolder.Promise)

return Promise.new(function(resolve, reject)
    local gameType do
        for info_gameType, info_game in pairs(Games) do
            if info_game.placeId == game.PlaceId then
                gameType = info_gameType
                break
            end
        end
    end

    local LocalGameInfo = {}

    if Games[gameType].gameJoinType == GameJoinType.public then
        if RunService:IsClient() then
            local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

            LocalGameInfo.gameIndex = ReplicaCollection.get("GameIndex", true).Data.gameIndex
        elseif RunService:IsServer() then
            local ServerStorage = game:GetService("ServerStorage")

            local serverStorageShared = ServerStorage.Shared
            local serverManagementFolder = serverStorageShared.ServerManagement

            local ReplicaService = require(serverStorageShared.Data.ReplicaService)
            local ServerData = require(serverManagementFolder.ServerData)

            local serverData = ServerData.traceServerInfo()
            LocalGameInfo.gameIndex = serverData and serverData.gameIndex

            ReplicaService.NewReplica({
                ClassToken = ReplicaService.NewClassToken("GameIndex"),
                Data = {
                    gameIndex = LocalGameInfo.gameIndex,
                },
                Replication = "All",
            })
        end
    end

    LocalGameInfo.gameType = gameType

    return LocalGameInfo
end)