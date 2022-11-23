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
local PlayGameResponseType = require(enumsFolder.PlayGameResponseType)
local Table = require(utilityFolder.Table)
local Games = require(serverFolder.Games)
local ReplicaService = require(dataFolder.ReplicaService)
local Teleport = require(serverStorageShared.Teleportation.Teleport)
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local PlayerData = require(dataFolder.PlayerData)
local GameJoinType = require(enumsFolder.GameJoinType)

local PlayGameRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PlayGameRequest"),
    Replication = "All"
})

PlayGameRequest:ConnectOnServerEvent(function(player, requestCode, gameType, ...)
    local function isRequestValid()
        if not PlayerData.get(player) then
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

    local function onTeleportError()
        task.spawn(function()
            respond(TeleportResponseType.teleportError)
        
            local success = Teleport.rejoin(player, "There was an error teleporting you. Please try again. (err code 8)")
    
            if not success then
                warn("Failed to rejoin player")
    
                player:Kick("There has been an error. Please rejoin. (err code 9)")
            end
        end)
    end

    local function evaluateSuccess(success)
        if not success then
            onTeleportError()
        else
            respond(TeleportResponseType.success)
        end
    end

    if not isRequestValid() then
        return respond(TeleportResponseType.invalid)
    end

    local gameInfo = Games[gameType]

    if gameInfo.gameJoinType == GameJoinType.initial then
        PlayerData.yieldUntilHopReady(player)

        evaluateSuccess(Teleport.teleportToGame(player, gameType))
    elseif gameInfo.gameJoinType == GameJoinType.public then

    elseif gameInfo.gameJoinType == GameJoinType.hosting then
        -- TODO: Implement hosting
    end
end)