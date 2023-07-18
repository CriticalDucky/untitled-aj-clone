--#region Imports

-- Services

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- Vendor

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

-- Source

local Id = if isServer then require(ReplicatedFirst.Shared.Utility.Id) else nil
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local ClientState = if not isServer then require(script.Parent.Parent:WaitForChild "ClientState") else nil
local DataReplication = require(script.Parent.Parent:WaitForChild "DataReplication")

-- Types

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Types")

type Home = Types.Home
type ItemHomeType = Types.ItemHomeType

-- Methods

local peek = if Fusion then Fusion.peek else nil

--#endregion

--#region Action Registration

if not isServer then
	DataReplication.registerActionAsync("SetHomes", function(homes) ClientState.inventory.homes:set(homes) end)
end

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's homes.
]]
local Homes = {}

--[[
	Adds a home to the player's inventory.

	---

	The ID of the new home is returned.

	This function is **server only**.
]]
function Homes.addHome(home: Home, player: Player)
	if not isServer then
		warn "Adding homes can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so no home can be added."
		return
	end

	local homes = PlayerDataManager.viewPersistentData(player).inventory.homes

	local newHomeId = Id.generate(homes)

	PlayerDataManager.setValuePersistent(player, { "inventory", "homes", newHomeId }, home)
	DataReplication.replicate("SetHomes", homes, player)

	return newHomeId
end

--[[
	Removes a home from the player's inventory.

	---

	This function is **server only**.
]]
function Homes.removeHome(homeId: string, player: Player)
	if not isServer then
		warn "Removing homes can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so no home can be removed."
		return
	end

	local homes = Homes.getHomes(player)

	if not homes[homeId] then
		warn "The player does not own a home with the given ID, so no home can be removed."
		return
	end

	PlayerDataManager.setValuePersistent(player, { "inventory", "homes", homeId }, nil)
	DataReplication.replicate("SetHomes", homes, player)
end

return Homes
