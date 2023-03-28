local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server

local ServerTypeEnum = require(enumsFolder:WaitForChild "ServerType")
local Locations = require(serverFolder:WaitForChild "Locations")
local Parties = require(serverFolder:WaitForChild "Parties")
local Minigames = require(serverFolder:WaitForChild "Minigames")
local GameSettings = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild "GameSettings")

local serverType
do
	for _, locationInfo in pairs(Locations.info) do
		if locationInfo.placeId == game.PlaceId then serverType = ServerTypeEnum.location end
	end

	for _, partyInfo in pairs(Parties) do
		if partyInfo.placeId == game.PlaceId then serverType = ServerTypeEnum.party end
	end

	for _, minigameInfo in pairs(Minigames) do
		if minigameInfo.placeId == game.PlaceId then serverType = ServerTypeEnum.minigame end
	end

	if GameSettings.homePlaceId == game.PlaceId then serverType = ServerTypeEnum.home end

	if not serverType then serverType = ServerTypeEnum.routing end
end

local LocalServerInfo = {}

LocalServerInfo.serverType = serverType

--[[
	Returns the serverIdentifier of the server this script is running on.
    Can either be called on the server or the client.

	Structure:

	```lua
	export type ServerIdentifier = {
		serverType: UserEnum, -- The type of server (location, party, minigame, etc.)
		jobId: string?, -- The jobId of the server (routing servers)
		worldIndex: number?, -- The index of the world the server is in (location servers)
		locationEnum: UserEnum?, -- The location of the server (location servers)
		homeOwner: number?, -- The userId of the player who owns the home (home servers)
		partyType: UserEnum?, -- The type of party the server is for (party servers)
		partyIndex: number?, -- The index of the party the server is for (party servers)
		minigameType: UserEnum?, -- The type of minigame the server is for (minigame servers)
		minigameIndex: number?, -- The index of the minigame the server is for (public minigame servers)
		privateServerId: string?, -- The private server id of the server (instance minigame servers)
	}
	```
]]
function LocalServerInfo.getServerIdentifier()
    local serverIdentifier

	if RunService:IsServer() then
		local ServerStorage = game:GetService "ServerStorage"

		local serverStorageShared = ServerStorage.Shared

		local ServerData = require(serverStorageShared.ServerManagement.ServerData)

		serverIdentifier = select(2, ServerData.getServerIdentifier())

		if serverIdentifier then
			serverIdentifier.jobId = game.JobId
			serverIdentifier.privateServerId = game.PrivateServerId
		end
	elseif RunService:IsClient() then
		local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
		local ReplicaCollection = require(replicatedStorageShared:WaitForChild("Replication"):WaitForChild "ReplicaCollection")

		serverIdentifier = ReplicatedServerData.getServerIdentifier()

		if serverIdentifier then
			local PrivateServerInfo = ReplicaCollection.get("PrivateServerInfo").Data

			serverIdentifier.privateServerId = PrivateServerInfo.privateServerId
		end
	end

	if serverIdentifier then
		serverIdentifier.serverType = serverType
	end

	if serverType == ServerTypeEnum.minigame then
        if serverIdentifier then
            return serverIdentifier
        end

		serverIdentifier = {
			serverType = ServerTypeEnum.minigame,
		}

        for minigameType, minigameInfo in pairs(Minigames) do
            if minigameInfo.placeId == game.PlaceId then
                serverIdentifier.minigameType = minigameType
            end
        end

        if not serverIdentifier.minigameType then
            warn("Could not find minigameType for minigame server")
            return nil
        end

        return serverIdentifier
	end

    return serverIdentifier
end

return LocalServerInfo
