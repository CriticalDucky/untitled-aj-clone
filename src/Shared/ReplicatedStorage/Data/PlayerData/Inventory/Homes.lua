--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

local Id = if isServer then require(ReplicatedFirst.Shared.Utility.Id) else nil
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local ClientState = if not isServer then require(script.Parent.Parent:WaitForChild "ClientState") else nil
local DataReplication = require(script.Parent.Parent:WaitForChild "DataReplication")

local peek = if Fusion then Fusion.peek else nil

export type Home = {
	type: number,
}

--#endregion

--#region Action Registration

if not isServer then
	DataReplication.registerActionAsync("SetHomes", function(homes)
		ClientState.inventory.homes:set(homes)
	end)
end

--#endregion

--[[
	A submodule of `PlayerData` that handles the player's homes.
]]
local Homes = {}

--[[
	Adds a home to the player's inventory.

	---

	The `homeVariant` parameter must be a valid `ItemHomeVariant` enum value.

	The ID of the new home is returned.

	This function is **server only**.
]]
function Homes.addHome(homeVariant: number, player: Player)
	if not isServer then
		warn "Adding homes can only be done on the server."
		return
	end

	if not PlayerDataManager.persistentDataIsLoaded(player) then
		warn "The player's persistent data is not loaded, so no home can be added."
		return
	end

	local homes = PlayerDataManager.viewPersistentData(player).inventory.homes

	local newHome = {
		type = homeVariant,
	}

	local newHomeId = Id.generate(homes)

	PlayerDataManager.setValuePersistent(player, { "inventory", "homes", newHomeId }, newHome)
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
