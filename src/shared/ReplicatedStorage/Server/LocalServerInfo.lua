local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local Parties = require(serverFolder:WaitForChild("Parties"))
local Minigames = require(serverFolder:WaitForChild("Minigames"))
local GameSettings = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild("GameSettings"))

local isServer = RunService:IsServer()
local isClient = RunService:IsClient()

local serverType do
    for _, locationInfo in pairs(Locations.info) do
        if locationInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.location
        end
    end

    for _, partyInfo in pairs(Parties) do
        if partyInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.party
        end
    end

    for _, gameInfo in pairs(Minigames) do
        if gameInfo.placeId == game.PlaceId then
            serverType = ServerTypeEnum.game
        end
    end

    if GameSettings.homePlaceId == game.PlaceId then
        serverType = ServerTypeEnum.home
    end

    if not serverType then
        serverType = ServerTypeEnum.routing
end
end

local LocalServerInfo = {}

LocalServerInfo.serverType = serverType

--[[
	Returns the serverIdentifier of the server this script is running on.
    Can either be called on the server or the client.

	Structure:

	```lua
	export type ServerIdentifier = {
		serverType: UserEnum, -- The type of server (location, party, game, etc.)
		jobId: string?, -- The jobId of the server (routing servers)
		worldIndex: number?, -- The index of the world the server is in (location servers)
		locationEnum: UserEnum?, -- The location of the server (location servers)
		homeOwner: number?, -- The userId of the player who owns the home (home servers)
		partyType: UserEnum?, -- The type of party the server is for (party servers)
		partyIndex: number?, -- The index of the party the server is for (party servers)
		gameType: UserEnum?, -- The type of game the server is for (game servers)
		gameIndex: number?, -- The index of the game the server is for (game servers)
	}
	```
]]
function LocalServerInfo.getServerIdentifier()
    if isServer then
        local ServerStorage = game:GetService("ServerStorage")

        local serverStorageShared = ServerStorage.Shared

        local ServerData = require(serverStorageShared.ServerManagement.ServerData)

        return select(2, ServerData.getServerIdentifier()) -- We can neglect the success value because ServerIdentifierCheck.server.lua will cover this.
    elseif isClient then
        local ReplicatedServerData = require(serverFolder:WaitForChild("ReplicatedServerData"))

        return ReplicatedServerData.getServerIdentifier()
    end
end

return LocalServerInfo