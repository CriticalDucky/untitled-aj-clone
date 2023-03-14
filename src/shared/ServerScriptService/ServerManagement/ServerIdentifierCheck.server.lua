local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local teleportationFolder = serverStorageShared.Teleportation
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums

local ServerData = require(serverStorageShared.ServerManagement.ServerData)
local Teleport = require(teleportationFolder.Teleport)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	local success, result = ServerData.getServerIdentifier()

    if not success then
        Teleport.bootServer "An internal server error occurred. Please try again later. (err code SCF1)"
        return
    end
end
