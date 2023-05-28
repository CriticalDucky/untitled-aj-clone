local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageSharedUtility = serverStorageShared.Utility
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedStorageShared.Utility
local teleportationFolder = serverStorageShared.Teleportation
local constantsFolder = replicatedStorageShared.Constants

local ReplicaService = require(serverStorageVendor.ReplicaService)
local Minigames = require(constantsFolder.MinigameConstants)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(constantsFolder.ServerTypeGroups)
local PlayMinigameResponseType = require(enumsFolder.PlayMinigameResponseType)
local MinigameType = require(enumsFolder.MinigameType)
local Param = require(utilityFolder.Param)
local Teleport = require(teleportationFolder.Teleport)

local playMinigameRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PlayMinigameRequest",
	Replication = "All",
}

--[[
    Table of functions to call when a minigame is requested.
    Will be called with the player and any additional arguments.
    It is crucial to check the additional arguments for validity using Param.expect.

    Each function should return a success boolean and a PlayMinigameResponseType if the request failed.
]]
local onRequested: {[string]: (Player, ...any) -> (boolean, typeof(PlayMinigameResponseType))} = {
    [MinigameType.fishing] = function(player)
        return Teleport.toMinigame(player, MinigameType.fishing)
    end,

    [MinigameType.gatherer] = function(player)
        return Teleport.toMinigame(player, MinigameType.gatherer)
    end,
}

ReplicaResponse.listen(playMinigameRequest, function(player, minigameType, ...)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
		warn "Routing server received a play minigame request. This should never happen."
		return false, PlayMinigameResponseType.invalid
	end

    if not Param.expect { minigameType, "string"} then
        warn "Invalid request: minigameType is nil or invalid"

        return false, PlayMinigameResponseType.invalid
    end

    local minigame = Minigames[minigameType]

    if not minigame then
        warn("Invalid request: minigameType is invalid")

        return false, PlayMinigameResponseType.invalid
    end

    return onRequested[minigameType](player, ...)
end)
