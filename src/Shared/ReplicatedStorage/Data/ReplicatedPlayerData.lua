--[[
	Client access to person player data and limited access to other players' data.

	See PlayerDataConstants.lua to see how player data is structured and replicated.
]]

--#region Imports
local Players = game:GetService "Players"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local utilityFolder = replicatedStorageShared:WaitForChild "Utility"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local constantsFolder = replicatedStorageShared:WaitForChild "Constants"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local Types = require(utilityFolder:WaitForChild "Types")
local Promise = require(replicatedFirstVendor:WaitForChild "Promise")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(constantsFolder:WaitForChild "ServerTypeGroups")

type InventoryCategory = Types.InventoryCategory
type Promise = Types.Promise
type ProfileData = Types.ProfileData
type Use = Fusion.Use

local Value = Fusion.Value
local Observer = Fusion.Observer
local peek = Fusion.peek
--#endregion

local player = Players.LocalPlayer

local playerDataValue = Value {}

local ReplicatedPlayerData = {}
ReplicatedPlayerData.value = playerDataValue

local withData = {}
ReplicatedPlayerData.withData = withData

--[[
	Traverses the provided data and looks for the provided player's data.
	
	Example usage for computeds:
	```lua
	Computed(function(use)
		local data = use(ReplicatedPlayerData.value)
		local profileData = ReplicatedPlayerData.withData.get(data) -- Gets the local player's data
	end)
	```
]]
function withData.get(data, player: Player | number | nil): ProfileData?
	if not player then player = Players.LocalPlayer.UserId end
	local userId = typeof(player) == "number" and player or player.UserId

	return data[userId]
end

--[[
	Gets a player's data.

	If you want this to update in computeds, use ReplicatedPlayerData.withData.get instead.

	Returns nil if the data has yet to replicate.
]]
function ReplicatedPlayerData.get(player: Player | number | nil): ProfileData?
	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
		warn "ReplicatedPlayerData.get should not be called on the routing server."
		warn(debug.traceback())
	end

	local data = withData.get(peek(playerDataValue), player)
	if data then return data end

	local connection

	return Promise.new(function(resolve)
		connection = Observer(playerDataValue):onChange(function()
			local data = withData.get(peek(playerDataValue), player)

			if data then
				connection()
				resolve(data)
			end
		end)
	end):expect()
end

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
	task.spawn(function()
		local publicDataReplica = ReplicaCollection.waitForReplica "PublicPlayerData"
		local privateDataReplica = ReplicaCollection.waitForReplica("PrivatePlayerData" .. player.UserId)

		local function updateValue() -- Uses the data from the replicas to update and merge the data into playerDataValue
			local playerDataTable = peek(playerDataValue)

			for userId, data in pairs(publicDataReplica.Data) do
				playerDataTable[tonumber(userId)] = data
			end

			local userId = Players.LocalPlayer.UserId

			playerDataTable[userId] = playerDataTable[userId] or {}

			for key, value in pairs(privateDataReplica.Data) do
				playerDataTable[userId][key] = value
			end

			playerDataValue:set(playerDataTable)
		end

		publicDataReplica:ListenToRaw(updateValue)
		privateDataReplica:ListenToRaw(updateValue)

		updateValue()
	end)
end

return ReplicatedPlayerData
