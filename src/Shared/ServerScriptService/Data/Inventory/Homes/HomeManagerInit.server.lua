local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local dataFolder = ServerStorage.Shared.Data
local serverFolder = ReplicatedStorage.Shared.Server
local enumsFolder = ReplicatedStorage.Shared.Enums
local constantsFolder = ReplicatedStorage.Shared.Constants

local HomeManager = require(dataFolder.Inventory.HomeManager)
local ServerTypeGroups = require(constantsFolder.ServerTypeGroups)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local Teleport = require(ServerStorage.Shared.Teleportation.Teleport)

if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
    if not HomeManager.loadHome() then
        Teleport.bootServer("The home failed to start up. (err code LH1)")
    end
end

