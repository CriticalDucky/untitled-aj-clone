local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local teleportationFolder = serverStorageShared.Teleportation
local serverFolder = replicatedStorageShared.Server

local LocalServerInfo = require(serverFolder.LocalServerInfo)
local Teleport = require(teleportationFolder.Teleport)

LocalServerInfo.getServerInfo()
    :catch(function()
        Teleport.bootServer("An internal server error occurred. Please try again later. (err code SCF1)")
    end)