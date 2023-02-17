local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Table = require(utilityFolder:WaitForChild("Table"))
local Promise = require(utilityFolder:WaitForChild("Promise"))
local Types = require(utilityFolder:WaitForChild("Types"))
local Param = require(utilityFolder:WaitForChild("Param"))
local PlayerFormat = require(enumsFolder:WaitForChild("PlayerFormat"))

type LocalPlayerParam = Types.LocalPlayerParam
type InventoryCategory = Types.InventoryCategory
type Promise = Types.Promise
type ProfileData = Types.ProfileData

local Value = Fusion.Value

local publicDataReplicaPromise = ReplicaCollection.get("PlayerDataPublic", true)

local playerDataTables = {}
local connections = {}
local publicDataLoaded = {}

local function addConnection(connection, player)
	connections[player] = connections[player] or {}
	table.insert(connections[player], connection)
end

local function removeAllConnections(player)
	if connections[player] then
		for _, connection in ipairs(connections[player]) do
			connection:Disconnect()
		end
		connections[player] = nil
	end
end

local playerData = {}

--[[
    Only for use by ClientPlayerDataInit.client.lua
]]
function playerData.add(player: Player)
	local publicDataReplica = publicDataReplicaPromise:expect()

	local function connect(connection)
		addConnection(connection, player)
	end

	local data = {}
	local userIdKey = tostring(player.UserId)

	local function onReplicaChange()
		local value = data.value or Value()

		if publicDataReplica.Data[userIdKey] then
			publicDataLoaded[userIdKey] = true
		end

		if player == Players.LocalPlayer then
			for key, value in pairs(data._privateReplica.Data) do
				data._mergeTable[key] = value
			end

			if publicDataLoaded[userIdKey] then
				for key, value in pairs(publicDataReplica.Data[userIdKey]) do
					data._mergeTable[key] = value
				end
			end

			value:set(data._mergeTable)
		else
			value:set(publicDataReplica.Data[userIdKey])
		end

		data.value = value
	end

	if player == Players.LocalPlayer then
		data._privateReplica = ReplicaCollection.get("PlayerDataPrivate", true):expect()
		connect(data._privateReplica:ListenToRaw(onReplicaChange))
		data._mergeTable = {}
	end

	connect(publicDataReplica:ListenToRaw(onReplicaChange))

	playerDataTables[player] = data

	onReplicaChange()
end

--[[
    Gets a player's data, if it exists.
    It does not return a promise, so it's safe for state objects.
    It can return nil, so make sure to check for that.
]]

--[[
    Gets a player's data, if it exists.
    It returns a promise, so it's not safe for state objects.
]]
function playerData.getData(player: LocalPlayerParam)
	return Promise.new(function(resolve, reject, onCancel)
		Param.localPlayerParam(player)
			:andThen(function(player)
				local lastPrint = time()
				local stop = false

				onCancel(function()
					stop = true
				end)

				while
					not (
						playerDataTables[player]
						and playerDataTables[player].value
						and publicDataLoaded[tostring(player.UserId)]
					) and not stop
				do
					-- only print once every 5 seconds
					if time() - lastPrint > 5 then
						lastPrint = time()
						warn("Waiting for player data for " .. player.Name)
					end

					task.wait()
				end

				if stop then
					return Promise.reject()
				end

				return playerDataTables[player].value:get()
			end)
			:andThen(resolve)
			:catch(reject)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	removeAllConnections(player)
	playerDataTables[player] = nil
end)

return playerData
