local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverStorageShared = ServerStorage.Shared
local teleportationFolder = serverStorageShared.Teleportation
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedFirstShared.Enums
local configurationFolder = replicatedFirstShared.Configuration

local Teleport = require(teleportationFolder.Teleport)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(configurationFolder.ServerTypeGroups)
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	local result = LocalServerInfo.getServerIdentifier()

    if not result then
        Teleport.bootServer "An internal server error occurred. (err code SCF1)"
        return
    end
end
