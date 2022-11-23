local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverFolder = replicatedStorageShared.Server

local Games = require(serverFolder.Games)

local success

local gameType, players, serverCode do
    for info_gameType, info_game in pairs(Games) do
        if info_game.placeId == game.PlaceId then
            gameType = info_gameType
            break
        end
    end

    if RunService:IsClient() then
        local ReplicaCollection = require(replicatedStorageShared.Replication.ReplicaCollection)

        players = ReplicaCollection.get("GamePlayers", true).Data.players
    elseif RunService:IsServer() then
        local ServerStorage = game:GetService("ServerStorage")
    
        local serverStorageShared = ServerStorage.Shared
    
        local ReplicaService = require(serverStorageShared.Data.ReplicaService)
        local Fingerprint = require(serverStorageShared.Utility.Fingerprint)
    
        success, data = Fingerprint.trace(game.PrivateServerId)
        players, serverCode = data.players, data.serverCode

        ReplicaService.NewReplica({
            ClassToken = ReplicaService.NewClassToken("GamePlayers"),
            Data = {
                players = data.players,
            },
            Replication = "All",
        })
    end
end

local LocalGameInfo = {}

LocalGameInfo.success = success
LocalGameInfo.gameType = gameType
LocalGameInfo.players = players
LocalGameInfo.serverCode = serverCode

return LocalGameInfo