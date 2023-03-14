--[[
	Client access to person player data and limited access to other players' data.

	See GameSettings.lua to see how player data is structured and replicated.

	TODO: Add support for requesting offline player data.
]]

--#region Imports
local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local serverFolder = replicatedStorageShared:WaitForChild "Server"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local Types = require(utilityFolder:WaitForChild "Types")
local Promise = require(utilityFolder:WaitForChild "Promise")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(serverFolder:WaitForChild "ServerTypeGroups")

type LocalPlayerParam = Types.LocalPlayerParam
type InventoryCategory = Types.InventoryCategory
type Promise = Types.Promise
type ProfileData = Types.ProfileData

local Value = Fusion.Value
local Observer = Fusion.Observer
--#endregion

local playerDataValue = Value {}

local ReplicatedPlayerData = {}

--[[
    Gets a player's data.
	Will dynamically update in computed objects if the data changes.

	Returns nil if the data has yet to replicate.

	If wait is true, this will wait for the data to replicate before returning.
]]
function ReplicatedPlayerData.get(player: Player | number | nil, wait: boolean?): ProfileData?
	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
		warn("ReplicatedPlayerData.get should not be called on the routing server.")
		warn(debug.traceback())
	end

	if not player then player = Players.LocalPlayer.UserId end

	local userId = typeof(player) == "number" and player or player.UserId

	local function waitForData()
		local data = playerDataValue:get()[userId]

		if data then return data end

		local connection

		return Promise.new(function(resolve)
			connection = Observer(playerDataValue):onChange(function()
				local data = playerDataValue:get()[userId]

				if data then
					connection()
					resolve(data)
				end
			end)
		end):expect()
	end

	return playerDataValue:get()[userId] or (wait and waitForData())
end

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	task.spawn(function()
		local publicDataReplica = ReplicaCollection.get "PlayerDataPublic"
		local privateDataReplica = ReplicaCollection.get "PlayerDataPrivate"

		local function updateValue() -- Uses the data from the replicas to update and merge the data into playerDataValue
			local playerDataTable = playerDataValue:get()

			for userId, data in pairs(publicDataReplica.Data) do
				playerDataTable[tonumber(userId)] = data
			end

			for userId, data in pairs(privateDataReplica.Data) do
				local userId = tonumber(userId)

				playerDataTable[userId] = playerDataTable[userId] or {}

				for key, value in pairs(data) do
					playerDataTable[userId][key] = value
				end
			end

			playerDataValue:set(playerDataTable)
		end

		publicDataReplica:ListenToRaw(updateValue)
		privateDataReplica:ListenToRaw(updateValue)

		updateValue()
	end)
end

return ReplicatedPlayerData