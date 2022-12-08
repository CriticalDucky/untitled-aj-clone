local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local teleportationFolder = serverStorageShared.Teleportation
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local Teleport = require(teleportationFolder.Teleport)

if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
    local LocalWorldInfo = require(ReplicatedStorage.Location.Server.LocalWorldInfo)

    if not LocalWorldInfo.worldIndex or not LocalWorldInfo.locationEnum then
        Teleport.bootServer("An internal server error occurred. Please try again later. (err code CH1)")
    end
elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
    local LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)

    if not LocalHomeInfo.homeOwner then
        Teleport.bootServer("An internal server error occurred. Please try again later. (err code CH2)")
    end
elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty) then
    local LocalPartyInfo = require(ReplicatedStorage.Party.Server.LocalPartyInfo)

    if not LocalPartyInfo.partyType or not LocalPartyInfo.partyIndex then
        Teleport.bootServer("An internal server error occurred. Please try again later. (err code CH3)")
    end
elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isGame) then
    local LocalGameInfo = require(ReplicatedStorage.Game.Server.LocalGameInfo)

    if not LocalGameInfo.gameType or not LocalGameInfo.gameIndex then
        Teleport.bootServer("An internal server error occurred. Please try again later. (err code CH4)")
    end
end