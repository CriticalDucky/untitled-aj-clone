local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local teleportationFolder = serverStorageShared.Teleportation
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local constantsFolder = replicatedStorageShared.Constants

local ServerData = require(serverStorageShared.ServerManagement.ServerData)
local Teleport = require(teleportationFolder.Teleport)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(constantsFolder.ServerTypeGroups)
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	local result = LocalServerInfo.getServerIdentifier()

    if not result then
        Teleport.bootServer "An internal server error occurred. (err code SCF1)"
        return
    end
end
