--[[
	Provides an interface for getting player settings on the client.
	Player settings are settings that the player controls (e.g. music, findOpenWorld, etc.).
	Player settings are publicly replicated, meaning that the client can see other players' settings.

	See PlayerDataConstants.lua to see all the player settings.
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
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local Types = require(utilityFolder:WaitForChild "Types")

local peek = Fusion.peek

local ClientPlayerSettings = {}
ClientPlayerSettings.value = ReplicatedPlayerData.value

local withData = {}
ClientPlayerSettings.withData = withData

--[[
	Gets a player's setting. Does not wait for the data to be available.

	Example usage for computeds:
	```lua
	Computed(function(use)
		local data = use(ClientPlayerSettings.value)
		local setting = ClientPlayerSettings.withData.getSetting(data, "settingName")
		-- Gets a setting from the local player's data (does not wait for the data to be available)
	end)
	```
]]
function withData.getSetting(data, settingName: string, player: Player | number | nil): any?
	local profileData = ReplicatedPlayerData.withData.get(data, player)

	return profileData and profileData.playerSettings and profileData.playerSettings[settingName]
end

--[[
	Gets a player's setting. If the player data is not available, it will wait for it to be available.
	If you're getting a setting within a computed, you should use ClientPlayerSettings.withData.getSetting instead.
]]
function ClientPlayerSettings.getSetting(settingName: string, player: Player | number | nil): any?
	ReplicatedPlayerData.get(player)

	return withData.getSetting(peek(ReplicatedPlayerData.value), settingName, player)
end

--[[
	Sets a player's setting. Will return false if validation fails.
]]
function ClientPlayerSettings.setSetting(settingName: string, value: any): boolean
	local setSettingReplica = ReplicaCollection.get "SetSettingRequest"

	return unpack(ReplicaRequest.new(setSettingReplica, settingName, value))
end

return ClientPlayerSettings
