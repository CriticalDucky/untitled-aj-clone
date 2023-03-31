--[[
	Provides an interface for getting player settings on the client.

	See GameSettings.lua to see all the player settings.
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"

local ReplicatedPlayerData = require(dataFolder:WaitForChild "ReplicatedPlayerData")
local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local Types = require(utilityFolder:WaitForChild "Types")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")

local ClientPlayerSettings = {}

--[[
	Gets a player's setting. If the player data is not available, this will return nil.
]]
function ClientPlayerSettings.getSetting(settingName: string, player: Player | number | nil, wait: boolean?): any?
	local function getSetting(data)
		local playerSettings = data.playerSettings

		if playerSettings then return playerSettings[settingName] end
	end

	local data = ReplicatedPlayerData.get(player, wait)

	if data then
		return getSetting(data)
	elseif wait then
		data = select(2, ReplicatedPlayerData.requestData(if typeof(player) == "number" then player else player.UserId))

		if data then
			return getSetting(data)
		end
	end
end

--[[
	Sets a player's setting. Will return false if validation fails.
]]
function ClientPlayerSettings.setSetting(settingName: string, value: any): boolean
	local setSettingReplica = ReplicaCollection.get("SetSettingRequest")

	return unpack(ReplicaRequest.new(setSettingReplica, settingName, value))
end

return ClientPlayerSettings
