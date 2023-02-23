local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local requestsFolder = replicatedStorageShared.Requests
local replicationFolder = replicatedStorageShared.Replication
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedFirstShared.Utility
local serverFolder = replicatedStorageShared.Server
local dataFolder = serverStorageShared.Data

local GameType = require(enumsFolder.GameType)
local Table = require(utilityFolder.Table)
local Games = require(serverFolder.Games)
local ReplicaService = require(dataFolder.ReplicaService)
local Teleport = require(serverStorageShared.Teleportation.Teleport)
local PlayerDataManager = require(dataFolder.PlayerDataManager)
local GameJoinType = require(enumsFolder.GameJoinType)

local PlayGameRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PlayGameRequest"),
    Replication = "All"
})

PlayGameRequest:ConnectOnServerEvent(function(player, requestCode, gameType, ...)
    local function isRequestValid()
        if not PlayerDataManager.get(player) then
            return false
        end

        if not Table.hasValue(GameType, gameType) then
            return false
        end

        local gameInfo = Games[gameType]

        if not gameInfo then
            return false
        end

        if gameInfo.enabledTime and not gameInfo.enabledTime:isInRange() then
            return false
        end

        return true
    end

    local function respond(...)
        PlayGameRequest:FireClient(player, requestCode, ...)
    end

    if not isRequestValid() then
        return respond(TeleportResponseType.invalid)
    end

    local gameInfo = Games[gameType]

    if gameInfo.gameJoinType == GameJoinType.initial then

    elseif gameInfo.gameJoinType == GameJoinType.public then

    elseif gameInfo.gameJoinType == GameJoinType.hosting then
        -- TODO: Implement hosting
    end
end)