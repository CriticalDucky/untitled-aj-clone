-- if LocalHomeInfo.homeOwner == nil, boot the player and all players who join

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local serverStorageShared = ServerStorage.Shared

local LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)
local Teleport = require(serverStorageShared.Teleportation.Teleport)

if not LocalHomeInfo.homeOwner then
    Teleport.bootServer("An internal server error occurred. Please try again later. (err code 1)")
end