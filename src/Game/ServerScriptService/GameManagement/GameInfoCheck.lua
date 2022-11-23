local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverStorageShared = ServerStorage.Shared

local LocalGameInfo = require(ReplicatedStorage.Game.Server.LocalGameInfo)
local Teleport = require(serverStorageShared.Teleportation.Teleport)

if not LocalGameInfo.success then
    Teleport.bootServer("An internal server error occurred. Please try again later. (err code 2)")
end