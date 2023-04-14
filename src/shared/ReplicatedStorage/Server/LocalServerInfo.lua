local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums
local serverFolder = replicatedStorageShared.Server
local utilityFolder = replicatedFirstShared.Utility

local ServerTypeEnum = require(enumsFolder:WaitForChild "ServerType")
local Locations = require(serverFolder:WaitForChild "Locations")
local Parties = require(serverFolder:WaitForChild "Parties")
local Minigames = require(serverFolder:WaitForChild "Minigames")
local PlaceSettings = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild "PlaceSettings")
local MinigameServerType = require(enumsFolder:WaitForChild "MinigameServerType")
local Table = require(utilityFolder:WaitForChild "Table")

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

	if PlaceSettings.homePlaceId == game.PlaceId then serverType = ServerTypeEnum.home end

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
	local SessionInfo

	if not (serverType == ServerTypeEnum.routing or serverType == ServerTypeEnum.minigame) then
		if RunService:IsServer() then
			local ServerStorage = game:GetService "ServerStorage"

			local serverStorageShared = ServerStorage.Shared

			local ServerData = require(serverStorageShared.ServerManagement.ServerData)

			serverIdentifier = select(2, ServerData.getServerIdentifier())
		else
			local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")

			serverIdentifier = ReplicatedServerData.getServerIdentifier()
		end
	end

	if RunService:IsClient() then
		local ReplicaCollection =
			require(replicatedStorageShared:WaitForChild("Replication"):WaitForChild "ReplicaCollection")

		SessionInfo = ReplicaCollection.get("SessionInfo").Data
	end

	if serverIdentifier then serverIdentifier.serverType = serverType end

	if serverType == ServerTypeEnum.routing then
		serverIdentifier = {
			serverType = ServerTypeEnum.routing,
		}

		if RunService:IsServer() then
			serverIdentifier.jobId = game.JobId
		elseif RunService:IsClient() then
			serverIdentifier.jobId = SessionInfo.jobId
		end
	elseif serverType == ServerTypeEnum.minigame then
		local minigameType
		local minigameInfo

		for k, v in pairs(Minigames) do
			if v.placeId == game.PlaceId then
				minigameInfo = v
				minigameType = k
			end
		end

		if not minigameType then
			error "Something went wrong when getting the serverIdentifier for a minigame server."
		end

		if minigameInfo.minigameServerType == MinigameServerType.instance then
			if RunService:IsClient() then
				serverIdentifier = {
					serverType = ServerTypeEnum.minigame,
					minigameType = minigameType,
					privateServerId = SessionInfo.privateServerId,
				}
			else
				serverIdentifier = {
					serverType = ServerTypeEnum.minigame,
					minigameType = minigameType,
					privateServerId = game.JobId,
				}
			end
		else
			if RunService:IsClient() then
				local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")

				serverIdentifier = ReplicatedServerData.getServerIdentifier()
			else
				local ServerStorage = game:GetService "ServerStorage"

				local serverStorageShared = ServerStorage.Shared

				local ServerData = require(serverStorageShared.ServerManagement.ServerData)

				serverIdentifier = select(2, ServerData.getServerIdentifier())
			end
		end
	end

	return serverIdentifier
end

return LocalServerInfo
