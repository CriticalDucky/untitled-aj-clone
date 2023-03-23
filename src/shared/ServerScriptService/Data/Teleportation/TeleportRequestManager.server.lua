local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService "ServerStorage"

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
local TeleportResponseType = require(enumsFolder.TeleportResponseType)
local ActiveParties = require(serverFolder.ActiveParties)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local Param = require(utilityFolder.Param)
local Promise = require(utilityFolder.Promise)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)

local Types = require(utilityFolder.Types)

type Promise = Types.Promise

local TeleportRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "TeleportRequest",
	Replication = "All",
}

ReplicaResponse.listen(TeleportRequest, function(player: Player, teleportRequestType, ...)
	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
		warn "Routing server received a teleport request. This should never happen."
		return false, TeleportResponseType.invalid
	end

	if not Param.expect { teleportRequestType, "string" } then
		warn "Invalid request: teleportRequestType is nil or invalid"
		return false, TeleportResponseType.invalid
	end

	if teleportRequestType == TeleportRequestType.toWorld then
		local worldIndex = ...

		if not Param.expect { worldIndex, "number" } then
			warn "Invalid request: worldIndex is nil or invalid"
			return false, TeleportResponseType.invalid
		end

		local success, result = Teleport.toWorld(player, worldIndex)

        if success then
            return result[1]:await()
        else
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toLocation then
		local locationEnum = ...

		if not Param.expect { locationEnum, "string" } then
            warn "Invalid request: locationEnum is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toLocation(player, locationEnum)

        if success then
            return result[1]:await()
        else
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toFriend then
		local targetPlayerId = ...

        if not Param.expect { targetPlayerId, "number" } then
            warn "Invalid request: targetPlayerId is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toPlayer(player, targetPlayerId)

        if success then
            return result[1]:await()
        else
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toParty then
		local partyType = ...

        if not Param.expect { partyType, "number" } then
            warn "Invalid request: partyType is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        if partyType ~= ActiveParties.getActiveParty().partyType then
            return false, TeleportResponseType.disabled
        end

        local success, result = Teleport.toParty(player, partyType)

        if success then
            return result[1]:await()
        else
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.toHome then
		local homeOwnerUserId = ...

        if not Param.expect { homeOwnerUserId, "number" } then
            warn "Invalid request: homeOwnerUserId is nil or invalid"
            return false, TeleportResponseType.invalid
        end

        local success, result = Teleport.toHome(player, homeOwnerUserId)

        if success then
            return result[1]:await()
        else
            return false, result
        end
	elseif teleportRequestType == TeleportRequestType.rejoin then
		Teleport.rejoin(player, "An unknown error occured on the client. (err code C1)")
	else
		warn "Invalid request: teleportRequestType is nil or invalid"

		return false, TeleportResponseType.invalid
	end
end)
