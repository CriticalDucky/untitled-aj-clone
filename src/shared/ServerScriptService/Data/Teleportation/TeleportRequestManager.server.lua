local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverFolder = replicatedStorageShared.Server
local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local teleportationFolder = serverStorageShared.Teleportation
local utilityFolder = replicatedFirstShared.Utility
local enumsFolder = replicatedStorageShared.Enums
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(dataFolder.ReplicaService)
local Teleport = require(teleportationFolder.Teleport)
local Table = require(utilityFolder.Table)
local TeleportRequestType = require(enumsFolder.TeleportRequestType)
local ResponseType = require(enumsFolder.ResponseType)
local ActiveParties = require(serverFolder.ActiveParties)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)
local Promise = require(utilityFolder.Promise)

local TeleportRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("TeleportRequest"),
    Replication = "All"
})

ReplicaResponse.listen(TeleportRequest, function(player: Player, teleportRequestType, ...)
    local vararg = {...}

    return Param.expect({teleportRequestType, "number"}):andThen(function()
        if teleportRequestType == TeleportRequestType.toWorld then
            local worldIndex = table.unpack(vararg)

            return Param.expect({worldIndex, "number"}):andThen(function()
                return Teleport.toWorld(player, worldIndex)
            end)
        elseif teleportRequestType == TeleportRequestType.toLocation then
            local locationEnum = table.unpack(vararg)
    
            return Param.expect({locationEnum, "number", "string"}):andThen(function()
                return Teleport.toLocation(player, locationEnum)
            end)
        elseif teleportRequestType == TeleportRequestType.toFriend then
            local targetPlayerId = table.unpack(vararg)
            
            return Param.expect({targetPlayerId, "number"}):andThen(function()
                return Teleport.toFriend(player, targetPlayerId)
            end)
        elseif teleportRequestType == TeleportRequestType.toParty then
            local partyType = table.unpack(vararg)
    
            return Param.expect({partyType, "number"}):andThen(function()
                if partyType ~= ActiveParties.getActiveParty().partyType then
                    return Promise.reject(ResponseType.disabled)
                end
                
                return Teleport.toParty(player, partyType)
            end)
        elseif teleportRequestType == TeleportRequestType.toHome then
            local homeOwnerUserId = table.unpack(vararg)

            return Param.expect({homeOwnerUserId, "number"}):andThen(function()
                return Teleport.toHome(player, homeOwnerUserId)
            end)
        else
            warn("Invalid request: teleportRequestType is nil or invalid")
    
            return Promise.reject(ResponseType.invalid)
        end
    end):andThen(function()
        return Promise.resolve(ResponseType.success)
    end)
end)