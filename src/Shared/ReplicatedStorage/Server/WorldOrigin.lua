--[[
	Utility for getting the world origin of a player.

	A world origin is the world index assigned to a player in case they are in a non-location place.
	For example, if a player joins a party while in a location under world index 1, their world origin in the party will be 1.
	This makes it easy to teleport them back to the location they were in before they joined the party.

	```lua
	local worldOrigin: number = WorldOrigin.get(player)
	```
]]

--#region Imports
local Players = game:GetService "Players"
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
--#endregion Imports


local WorldOrigin = {}

--[[
	Gets the world origin of a player.

	A world origin is the world index assigned to a player in a non-location place.
	For example, if a player joins a party while in a location under world index 1, their world origin in the party will be 1.
	This makes it easy to teleport them back to the location they were in before they joined the party.

	If this function is called on the client, it will only return the world origin of the local player, regardless of the player parameter.

	```lua
	local worldOrigin: number = WorldOrigin.get(player)
	```
]]
function WorldOrigin.get(player: number | Player | nil): number
	local worldOrigin

	local ServerData
	do
		if RunService:IsServer() then
			local ServerStorage = game:GetService "ServerStorage"

			local serverStorageShared = ServerStorage:WaitForChild "Shared"

			ServerData = require(serverStorageShared.ServerManagement.ServerData)
		end
	end

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
		worldOrigin = LocalServerInfo.getServerIdentifier().worldIndex
	elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
		local teleportData

		if RunService:IsClient() then
			teleportData = TeleportService:GetLocalPlayerTeleportData()
		elseif RunService:IsServer() then -- Player will never be nil
			assert(player ~= nil, "Player cannot be nil on the server.")

			player = if typeof(player) == "number" then Players:GetPlayerByUserId(player) else player

			assert(player ~= nil, "Nonexistent player provided to WorldOrigin.get().")

			teleportData = player:GetJoinData().TeleportData

			if teleportData == nil or teleportData.worldOrigin == nil then
				local success, worldIndex = ServerData.findAvailableWorld()

				if success then worldOrigin = worldIndex end
			end
		end

		worldOrigin = if teleportData then teleportData.worldOrigin else worldOrigin
	elseif RunService:IsServer() then
		local success, worldIndex = ServerData.findAvailableWorld()

		if success then worldOrigin = worldIndex end
	end

	if not worldOrigin then -- Hackily guess a random world index (This is a stopgap that will rarely be used)
		warn "WorldOrigin.get() could not find a world origin. Guessing a random world index."
		worldOrigin = math.random(1, 10)
	end

	return worldOrigin
end

return WorldOrigin
