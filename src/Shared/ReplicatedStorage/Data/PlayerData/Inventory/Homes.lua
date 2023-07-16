--#region Imports

local ReplicatedFirst = game:GetService "ReplicatedFirst"
-- local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

-- local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Enums"

local Fusion = if not isServer then require(ReplicatedFirst.Vendor.Fusion) else nil

local Id = if isServer then require(ReplicatedFirst.Shared.Utility.Id) else nil
local PlayerDataManager = if isServer then require(ServerStorage.Shared.Data.PlayerDataManager) else nil
local DataClient = if not isServer then require(script.Parent.Parent:WaitForChild "DataClient") else nil
local DataReplication = require(script.Parent.Parent:WaitForChild "DataReplication")

local peek = if Fusion then Fusion.peek else nil

--#endregion

local Homes = {}

--[[
	Gets the player's home with the given ID.

	---

	The `player` parameter is **required** on the server and **ignored** on the client.

	The return value is a table with the home's data. If the home does not exist, `nil` will be returned.

	---

	*Do **NOT** modify the returned table under any circumstances!*
]]
function Homes.getHome(homeId: string, player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
		player = nil
	end

	if isServer then
		if not PlayerDataManager.persistentDataIsLoaded(player) then
			warn "The player's persistent data is not loaded, so no home can be retrieved."
			return
		end

		return PlayerDataManager.viewPersistentData(player).inventory.homes[homeId]
	else
		return peek(DataClient.inventory.homes)[homeId]
	end
end

--[[
	Gets all the player's homes.

	---

	The `player` parameter is **required** on the server and **ignored** on the client.

	The return value is a dictionary of homes, where the key is the home's ID and the value is a table with the home's
	data.

	---

	*Do **NOT** modify the returned table under any circumstances!*
]]
function Homes.getHomes(player: Player?)
	if isServer and not player then
		warn "A player must be provided when calling from the server."
		return
	elseif not isServer and player then
		warn "No player needs to be given when calling from the client, so this parameter will be ignored."
	end

	if isServer then
		if not PlayerDataManager.persistentDataIsLoaded(player) then
			warn "The player's persistent data is not loaded, so no homes can be retrieved."
			return
		end

		return PlayerDataManager.viewPersistentData(player).inventory.homes
	else
		return peek(DataClient.inventory.homes)
	end
end

--[[
	Gets the state object for the player's homes.

	---

	The return value is a Fusion `Value` object. The value of the `Value` object is a dictionary of homes, where the
	key is the home's ID and the value is a table with the home's data.

	This function is **client only**.

	---

	*Do **NOT** modify the state object returned by this function under any circumstances!*
]]
function Homes.getHomesState()
	if isServer then
		warn "This function can only be called on the client. No state will be returned."
		return
	end

	return peek(DataClient.inventory.homes)
end

--[[
	Adds a home to the player's inventory.

	---

	The `homeType` parameter must be a valid `ItemHomeType` enum value.

	The ID of the new home is returned.

	This function is **server only**.
]]
function Homes.addHome(homeType: number, player: Player)
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
		type = homeType,
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
