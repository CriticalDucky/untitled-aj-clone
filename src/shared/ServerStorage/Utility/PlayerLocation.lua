local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage.Shared
local utilityFolder = ReplicatedFirst.Shared.Utility
local enumsFolder = replicatedStorageShared.Enums

local LiveServerData = require(replicatedStorageShared.Server.LiveServerData)
local ServerTypeEnum = require(enumsFolder.ServerType)
local Types = require(utilityFolder.Types)

type ServerIdentifier = Types.ServerIdentifier

local PlayerLocation = {}

-- Gets the server identifier of the specified player, if they are online.
-- If they are not online, returns nil.
function PlayerLocation.get(userId: number): ServerIdentifier?
	local liveServerData = LiveServerData.get()

	if not liveServerData then return nil end

	local playerServerIdentifier

	for serverType, serverTypeData in liveServerData do
		if serverType == ServerTypeEnum.routing then
			for jobId, serverInfo in pairs(serverTypeData) do
				if table.find(serverInfo.players, userId) then
					playerServerIdentifier = {
						serverType = serverType,
						jobId = jobId,
					}

					break
				end
			end
		elseif serverType == ServerTypeEnum.location then
			for worldIndex, worldData in pairs(serverTypeData) do
				for locationEnum, serverInfo in pairs(worldData) do
					if table.find(serverInfo.players, userId) then
						playerServerIdentifier = {
							serverType = serverType,
							worldIndex = worldIndex,
							locationEnum = locationEnum,
						}

						break
					end
				end
			end
		elseif serverType == ServerTypeEnum.home then
			for userId, serverInfo in pairs(serverTypeData) do
				if table.find(serverInfo.players, userId) then
					playerServerIdentifier = {
						serverType = serverType,
						homeOwner = userId,
					}

					break
				end
			end
		elseif serverType == ServerTypeEnum.party then
			for partyType, partyTypeData in pairs(serverTypeData) do
				for partyIndex, serverInfo in pairs(partyTypeData) do
					if table.find(serverInfo.players, userId) then
						playerServerIdentifier = {
							serverType = serverType,
							partyType = partyType,
							partyIndex = partyIndex,
						}

						break
					end
				end
			end
		elseif serverType == ServerTypeEnum.game then
			for gameType, gameTypeData in pairs(serverTypeData) do
				for gameIndex, serverInfo in pairs(gameTypeData) do
					if table.find(serverInfo.players, userId) then
						playerServerIdentifier = {
							serverType = serverType,
							gameType = gameType,
							gameIndex = gameIndex,
						}

						break
					end
				end
			end
		end
	end

	return playerServerIdentifier
end

return PlayerLocation
