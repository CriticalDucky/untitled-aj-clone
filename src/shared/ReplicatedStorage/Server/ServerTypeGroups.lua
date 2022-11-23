local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ServerTypeEnum = require(enumsFolder.ServerType)
local ServerTypeGroup = require(enumsFolder.ServerGroup)
local LocalServerInfo = require(replicatedStorageShared.Server.LocalServerInfo)

local ServerTypeGroups = {
    [ServerTypeGroup.hasWorldOrigin] = {
        [ServerTypeEnum.home] = true,
        [ServerTypeEnum.party] = true,
        [ServerTypeEnum.game] = true,
    },

    [ServerTypeGroup.isLocation] = {
        [ServerTypeEnum.location] = true,
    },

    [ServerTypeGroup.isHome] = {
        [ServerTypeEnum.home] = true,
    },

    [ServerTypeGroup.isParty] = {
        [ServerTypeEnum.party] = true,
    },

    [ServerTypeGroup.isRouting] = {
        [ServerTypeEnum.routing] = true,
    },

    [ServerTypeGroup.isGame] = {
        [ServerTypeEnum.game] = true,
    },

    [ServerTypeGroup.hasWorldInfo] = {
        [ServerTypeEnum.home] = true,
        [ServerTypeEnum.party] = true,
        [ServerTypeEnum.location] = true,
        [ServerTypeEnum.game] = true,
    },

    [ServerTypeGroup.isWorldBased] = {
        [ServerTypeEnum.home] = true,
        [ServerTypeEnum.party] = true,
        [ServerTypeEnum.location] = true,
        [ServerTypeEnum.game] = true,
    },

    [ServerTypeGroup.needsIdentity] = {
        [ServerTypeEnum.home] = true,
        [ServerTypeEnum.party] = true,
        [ServerTypeEnum.game] = true,
    },

    [ServerTypeGroup.serverCodeFingerprint] = {
        [ServerTypeEnum.party] = true,
    },
}

function ServerTypeGroups.serverInGroup(group, serverType)
    return ServerTypeGroups[group][serverType or LocalServerInfo.serverType]
end

return ServerTypeGroups