local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverFolder = replicatedStorageShared.Server
local enums = replicatedStorageShared.Enums

local Games = require(serverFolder.Games)
local GameJoinType = require(enums.GameJoinType)

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
    
        local serverData = ServerData.traceServer()
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