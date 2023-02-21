local RunService = game:GetService "RunService"
local TeleportService = game:GetService "TeleportService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"

local ServerTypeGroups = require(serverFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local Promise = require(utilityFolder:WaitForChild "Promise")
local Param = require(utilityFolder:WaitForChild "Param")
local Types = require(utilityFolder:WaitForChild "Types")
local PlayerFormat = require(enumsFolder:WaitForChild "PlayerFormat")
local ResponseType = require(enumsFolder:WaitForChild "ResponseType")

type LocalPlayerParam = Types.LocalPlayerParam
type Promise = Types.Promise

local isClient = RunService:IsClient()
local isServer = RunService:IsServer()

local WorldOrigin = {}

function WorldOrigin.get(player: LocalPlayerParam): Promise -- Gets the world origin of a player. Clients cannot get the world origin of other players. Can be nil in rare cases.
	return Param.localPlayerParam(player, PlayerFormat.instance):andThen(function(player: Player)
		local ServerData
		do
			if isServer then
				local ServerStorage = game:GetService "ServerStorage"

				local serverStorageShared = ServerStorage:WaitForChild "Shared"

				ServerData = require(serverStorageShared.ServerManagement.ServerData)
			end
		end

		if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
			return LocalServerInfo.getServerInfo():andThen(function(serverInfo)
				return serverInfo.worldIndex
			end)
		elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
			local teleportData

			if isClient then
				teleportData = TeleportService:GetLocalPlayerTeleportData()
			elseif isServer then
				teleportData = player:GetJoinData().TeleportData

				if teleportData == nil or teleportData.worldOrigin == nil then
					return ServerData.findAvailableWorld()
				end
			end

			return Promise.resolve(teleportData and teleportData.worldOrigin)
		elseif isServer then
			return ServerData.findAvailableWorld()
		end

		return Promise.reject(ResponseType.invalid)
	end)
end

return WorldOrigin
