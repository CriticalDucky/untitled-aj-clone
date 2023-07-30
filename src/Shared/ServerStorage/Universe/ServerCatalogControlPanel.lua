--!strict

--[[
	This time must be waited between each get/set DataStore operation.

	Only necessary for large setting operations to protect from rate limiting.
]]
local DATASTORE_OPERATION_COOLDOWN = 1

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

assert(not RunService:IsStudio(), "This module cannot be used in Studio.")

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local SafeTeleport = require(ServerStorage.Shared.Utility.SafeTeleport)
local ServerCatalog = require(ServerStorage.Shared.Universe.ServerCatalog)
local Table = require(ReplicatedFirst.Shared.Utility.Table)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type CatalogMinigameData = Types.CatalogMinigameData
type CatalogPartyData = Types.CatalogPartyData
type CatalogWorldData = Types.CatalogWorldData

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"

local minigameCatalog = DataStoreService:GetDataStore "MinigameCatalog"
local partyCatalog = DataStoreService:GetDataStore "PartyCatalog"
local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--#region Safer DataStore Functions

-- Slower functions for longer update procedures that need to be rate limited.

-- These only need to be used in for loops.

local lastRead
local lastWrite

local function slowGetAsync(dataStore, key)
	local now = os.time()

	if lastRead and now - lastRead < DATASTORE_OPERATION_COOLDOWN then
		task.wait(DATASTORE_OPERATION_COOLDOWN - (now - lastRead))
	end

	lastRead = os.time()

	return SafeDataStore.safeGetAsync(dataStore, key)
end

local function slowSetAsync(dataStore, key, value, userIds, options)
	local now = os.time()

	if lastWrite and now - lastWrite < DATASTORE_OPERATION_COOLDOWN then
		task.wait(DATASTORE_OPERATION_COOLDOWN - (now - lastWrite))
	end

	lastWrite = os.time()

	return SafeDataStore.safeSetAsync(dataStore, key, value, userIds, options)
end

--#endregion

--#region Operation Lock

local localOperationLock = false

--[[
	Locks the catalog for operations.

	---

	@param lock The lock state to set.
	@return Whether the operation was successful.
]]
local function setOperationLockAsync(lock: boolean): boolean
	if lock then
		local success = false

		local updateSuccess = SafeDataStore.safeUpdateAsync(catalogInfo, "OperationLock", function(oldValue)
			if oldValue then return end

			localOperationLock = true
			success = true
			return true
		end)

		if not updateSuccess then
			warn "An error occurred while adding the operation lock."
		elseif not success then
			warn "An operation is already in progress."
		end

		return success
	else
		local success = SafeDataStore.safeRemoveAsync(catalogInfo, "OperationLock")

		if not success then warn "An error occurred while removing the operation lock." end

		localOperationLock = false

		return success
	end
end

--#endregion

--[[
	Provides functions for managing the universe server catalog.

	---

	⚠️ **FOR MANUAL DEVELOPER USE ONLY** ⚠️
]]
local ServerCatalogControlPanel = {}

function ServerCatalogControlPanel.addMinigame(name: string, placeId: number)
	if typeof(name) ~= "string" then
		warn "The minigame name must be a string."
		return
	elseif typeof(placeId) ~= "number" or placeId ~= placeId or placeId ~= math.floor(placeId) or placeId < 0 then
		warn "The place ID must be a non-negative integer."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Adding minigame '%s' with place ID %d…"):format(name, placeId))

	local minigameList = ServerCatalog.getMinigameListAsync()

	if not minigameList then
		warn "Failed to retrieve the minigame list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the minigame list."

	if minigameList[name] then
		print(("Minigame '%s' already exists."):format(name))
		setOperationLockAsync(false)
		return
	end

	local minigameServerCount = ServerCatalog.getMinigameServerCountAsync()

	if not minigameServerCount then
		warn "Failed to retrieve the minigame server count."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the minigame server count."

	if minigameServerCount == 0 then
		print "The minigame server count is 0, so a dummy server will be reserved to verify the place ID."

		local reserveSuccess = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve a dummy private server for minigame '%s'. (The given place ID may not be valid,"
					.. " or this may have been run in Studio.)"
				):format(name)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Successfully reserved a dummy private server for minigame '%s'."):format(name))
	end

	local newMinigame = {}

	for i = 1, minigameServerCount do
		local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve private server %d for minigame '%s'. (The given place ID may not be valid, or"
					.. " this may have been run in Studio.)"
				):format(i, name)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Reserved private server %d for minigame '%s'."):format(i, name))

		newMinigame[i] = {
			accessCode = accessCode,
			privateServerId = privateServerId,
		}
	end

	local setMinigameSuccess = slowSetAsync(minigameCatalog, name, newMinigame)

	if not setMinigameSuccess then
		warn(("Failed to add minigame '%s' to the minigame catalog."):format(name))
		setOperationLockAsync(false)
		return
	end

	print(("Added minigame '%s' to the minigame catalog."):format(name))

	minigameList[name] = {
		placeId = placeId,
	}

	local setMinigameListSuccess = SafeDataStore.safeSetAsync(catalogInfo, "MinigameList", minigameList)

	if not setMinigameListSuccess then
		warn(("Failed to add minigame '%s' to the minigame list."):format(name))
		setOperationLockAsync(false)
		return
	end

	print(("Added minigame '%s' to the minigame list."):format(name))

	print(("Minigame '%s' has been successfully added."):format(name))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.addParty(name: string, placeId: number)
	if typeof(name) ~= "string" then
		warn "The party name must be a string."
		return
	elseif typeof(placeId) ~= "number" or placeId ~= placeId or placeId ~= math.floor(placeId) or placeId < 0 then
		warn "The place ID must be a non-negative integer."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Adding party '%s' with place ID %d…"):format(name, placeId))

	local partyList = ServerCatalog.getPartyListAsync()

	if not partyList then
		warn "Failed to retrieve the party list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the party list."

	if partyList[name] then
		print(("Party '%s' already exists."):format(name))
		setOperationLockAsync(false)
		return
	end

	local partyServerCount = ServerCatalog.getPartyServerCountAsync()

	if not partyServerCount then
		warn "Failed to retrieve the party server count."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the party server count."

	if partyServerCount == 0 then
		print "The party server count is 0, so a dummy server will be reserved to verify the place ID."

		local reserveSuccess = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve a dummy private server for party '%s'. (The given place ID may not be valid, or"
					.. " this may have been run in Studio.)"
				):format(name)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Successfully reserved a dummy private server for party '%s'."):format(name))
	end

	local newParty = {}

	for i = 1, partyServerCount do
		local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve private server %d for party '%s'. (The given place ID may not be valid, or this"
					.. " may have been run in Studio.)"
				):format(i, name)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Reserved private server %d for party '%s'."):format(i, name))

		newParty[i] = {
			accessCode = accessCode,
			privateServerId = privateServerId,
		}
	end

	local setPartySuccess = slowSetAsync(partyCatalog, name, newParty)

	if not setPartySuccess then
		warn(("Failed to add party '%s' to the party catalog."):format(name))
		setOperationLockAsync(false)
		return
	end

	print(("Added party '%s' to the party catalog."):format(name))

	partyList[name] = {
		placeId = placeId,
	}

	local setPartyListSuccess = SafeDataStore.safeSetAsync(catalogInfo, "PartyList", partyList)

	if not setPartyListSuccess then
		warn(("Failed to add party '%s' to the party list."):format(name))
		setOperationLockAsync(false)
		return
	end

	print(("Added party '%s' to the party list."):format(name))

	print(("Party '%s' has been successfully added."):format(name))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.addWorldLocation(name: string, placeId: number)
	if typeof(name) ~= "string" then
		warn "The location name must be a string."
		return
	elseif typeof(placeId) ~= "number" or placeId ~= placeId or placeId ~= math.floor(placeId) or placeId < 0 then
		warn "The place ID must be a non-negative integer."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Adding location '%s' with place ID %d…"):format(name, placeId))

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the world location list."

	if locationList[name] then
		print(("Location '%s' already exists."):format(name))
		setOperationLockAsync(false)
		return
	end

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to retrieve the world count."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the world count."

	if worldCount == 0 then
		print "The world count is 0, so a dummy server will be reserved to verify the place ID."

		local reserveSuccess = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve a dummy private server for location '%s'. (The given place ID may not be valid,"
					.. " or this may have been run in Studio.)"
				):format(name)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Successfully reserved a dummy private server for location '%s'."):format(name))
	end

	-- Add the location to all worlds

	for i = 1, worldCount do
		local getWorldSuccess, worldData: CatalogWorldData = slowGetAsync(worldCatalog, tostring(i))

		if not getWorldSuccess then
			warn(("Failed to retrieve world %d data."):format(i))
			setOperationLockAsync(false)
			return
		end

		print(("Retrieved world %d data."):format(i))

		local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				(
					"Failed to reserve private server for location '%s' in world %d. (The given place ID may not be"
					.. " valid, or this may have been run in Studio.)"
				):format(name, i)
			)
			setOperationLockAsync(false)
			return
		end

		print(("Reserved a private server for location '%s' in world %d."):format(name, i))

		local setDictionarySuccess = slowSetAsync(serverDictionary, privateServerId, { world = i })

		if not setDictionarySuccess then
			warn(("Failed to add server dictionary entry for location '%s' in world %d."):format(name, i))
			setOperationLockAsync(false)
			return
		end

		print(("Added server dictionary entry for location '%s' in world %d."):format(name, i))

		worldData[name] = {
			accessCode = accessCode,
			privateServerId = privateServerId,
		}

		local setWorldSuccess = slowSetAsync(worldCatalog, tostring(i), worldData)

		if not setWorldSuccess then
			warn(("Failed to add location '%s' to world %d."):format(name, i))
			setOperationLockAsync(false)
			return
		end

		print(("Added location '%s' to world %d."):format(name, i))
	end

	-- Register the location

	locationList[name] = {
		placeId = placeId,
	}

	local setLocationListSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldLocationList", locationList)

	if not setLocationListSuccess then
		warn "Failed to update the world location list."
		setOperationLockAsync(false)
		return
	end

	print(("Added location '%s' to the world location list."):format(name))

	print(("Location '%s' has been successfully added."):format(name))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.forceReleaseOperationLock()
	print "Releasing the operation lock…"

	if localOperationLock then
		warn "Cannot force the operation lock to release because the operation lock is currently held locally."
		return
	end

	if not setOperationLockAsync(false) then return end

	print "The operation lock has been successfully removed."
end

function ServerCatalogControlPanel.printMinigame(minigame: string)
	if typeof(minigame) ~= "string" then
		warn "The minigame name must be a string."
		return
	end

	print(("Printing minigame '%s'…"):format(minigame))

	local minigameData = ServerCatalog.getMinigameAsync(minigame)

	if not minigameData then
		warn(("Failed to retrieve minigame '%s' data. (This minigame may not exist.)"):format(minigame))
		return
	end

	print(("Minigame '%s': %s"):format(minigame, Table.toString(minigameData, 4)))
end

function ServerCatalogControlPanel.printMinigameList()
	print "Retrieving the minigame list…"

	local minigameList = ServerCatalog.getMinigameListAsync()

	if not minigameList then
		warn "Failed to retrieve the minigame list."
		return
	end

	print(("Minigame list: %s"):format(Table.toString(minigameList, 4)))
end

function ServerCatalogControlPanel.printMinigameServerCount()
	print "Retrieving the minigame server count…"

	local minigameServerCount = ServerCatalog.getMinigameServerCountAsync()

	if not minigameServerCount then
		warn "Failed to retrieve the minigame server count."
		return
	end

	print(("There are %d servers for each minigame."):format(minigameServerCount))
end

function ServerCatalogControlPanel.printParty(party: string)
	if typeof(party) ~= "string" then
		warn "The party name must be a string."
		return
	end

	print(("Printing party '%s'…"):format(party))

	local partyData = ServerCatalog.getPartyAsync(party)

	if not partyData then
		warn(("Failed to retrieve party '%s' data. (This party may not exist.)"):format(party))
		return
	end

	print(("Party '%s': %s"):format(party, Table.toString(partyData, 4)))
end

function ServerCatalogControlPanel.printPartyList()
	print "Retrieving the party list…"

	local partyList = ServerCatalog.getPartyListAsync()

	if not partyList then
		warn "Failed to retrieve the party list."
		return
	end

	print(("Party list: %s"):format(Table.toString(partyList, 4)))
end

function ServerCatalogControlPanel.printPartyServerCount()
	print "Retrieving the party server count…"

	local partyServerCount = ServerCatalog.getPartyServerCountAsync()

	if not partyServerCount then
		warn "Failed to retrieve the party server count."
		return
	end

	print(("There are %d servers for each party."):format(partyServerCount))
end

function ServerCatalogControlPanel.printWorld(world: number)
	if typeof(world) ~= "number" or world ~= world or world ~= math.floor(world) or world < 1 then
		warn "The world must be a positive integer."
		return
	end

	print(("Printing world %d…"):format(world))

	local worldData = ServerCatalog.getWorldAsync(world)

	if not worldData then
		warn(("Failed to retrieve world data for world %d. (This world may not exist.)"):format(world))
		return
	end

	print(("World %d: %s"):format(world, Table.toString(worldData, 4)))
end

function ServerCatalogControlPanel.printWorldCount()
	print "Retrieving the world count…"

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to retrieve the world count."
		return
	end

	print(("There are %d worlds."):format(worldCount))
end

function ServerCatalogControlPanel.printWorldLocationList()
	print "Retrieving the world location list…"

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		return
	end

	print(("World location list: %s"):format(Table.toString(locationList, 4)))
end

function ServerCatalogControlPanel.removeMinigame(minigameName: string)
	if typeof(minigameName) ~= "string" then
		warn "The minigame name must be a string."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Removing minigame '%s'…"):format(minigameName))

	local minigameList = ServerCatalog.getMinigameListAsync()

	if not minigameList then
		warn "Failed to retrieve the minigame list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the minigame list."

	if not minigameList[minigameName] then
		print(("Minigame '%s' already does not exist."):format(minigameName))
		setOperationLockAsync(false)
		return
	end

	minigameList[minigameName] = nil

	local removeMinigameSuccess = SafeDataStore.safeSetAsync(catalogInfo, "MinigameList", minigameList)

	if not removeMinigameSuccess then
		warn(("Failed to remove minigame '%s' from the minigame list."):format(minigameName))
		setOperationLockAsync(false)
		return
	end

	print(("Removed minigame '%s' from the minigame list."):format(minigameName))

	print(("Minigame '%s' has been successfully removed."):format(minigameName))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.removeParty(partyName: string)
	if typeof(partyName) ~= "string" then
		warn "The party name must be a string."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Removing party '%s'…"):format(partyName))

	local partyList = ServerCatalog.getPartyListAsync()

	if not partyList then
		warn "Failed to retrieve the party list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the party list."

	if not partyList[partyName] then
		print(("Party '%s' already does not exist."):format(partyName))
		setOperationLockAsync(false)
		return
	end

	partyList[partyName] = nil

	local removePartySuccess = SafeDataStore.safeSetAsync(catalogInfo, "PartyList", partyList)

	if not removePartySuccess then
		warn(("Failed to remove party '%s' from the party list."):format(partyName))
		setOperationLockAsync(false)
		return
	end

	print(("Removed party '%s' from the party list."):format(partyName))

	print(("Party '%s' has been successfully removed."):format(partyName))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.removeWorldLocation(locationName: string)
	if typeof(locationName) ~= "string" then
		warn "The location name must be a string."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Removing location '%s'…"):format(locationName))

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the world location list."

	if not locationList[locationName] then
		print(("Location '%s' already does not exist."):format(locationName))
		setOperationLockAsync(false)
		return
	end

	locationList[locationName] = nil

	local removeLocationSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldLocationList", locationList)

	if not removeLocationSuccess then
		warn(("Failed to remove location '%s' from the world location list."):format(locationName))
		setOperationLockAsync(false)
		return
	end

	print(("Removed location '%s' from the world location list."):format(locationName))

	print(("Location '%s' has been successfully removed."):format(locationName))

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.setMinigameServerCount(count: number, force: true?)
	if typeof(count) ~= "number" or count ~= count or count ~= math.floor(count) or count < 0 then
		warn "The server count must be a non-negative integer."
		return
	elseif force ~= nil and force ~= true then
		warn "The force flag must be true or nil."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Setting the minigame server count to %d…"):format(count))

	local currentMinigameServerCount = ServerCatalog.getMinigameServerCountAsync()

	if not currentMinigameServerCount then
		warn "Failed to retrieve the minigame server count."
		setOperationLockAsync(false)
		return
	end

	if currentMinigameServerCount > count and not force then
		warn "Cannot reduce the minigame server count without the force flag."
		setOperationLockAsync(false)
		return
	end

	if currentMinigameServerCount == count then
		print(("The minigame server count is already %d."):format(count))
	elseif currentMinigameServerCount > count then
		local setMinigameServerCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "MinigameServerCount", count)

		if not setMinigameServerCountSuccess then
			warn(("Failed to update the minigame server count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the minigame server count to %d."):format(count))

		print(("The minigame server count has been successfully reduced to %d."):format(count))
	else
		local minigameList = ServerCatalog.getMinigameListAsync()

		if not minigameList then
			warn "Failed to retrieve the minigame list."
			setOperationLockAsync(false)
			return
		end

		print "Retrieved the minigame list."

		for minigameName, minigameInfo in pairs(minigameList) do
			local minigamePlaceId = minigameInfo.placeId

			local getMinigameSuccess, minigameData: CatalogMinigameData = slowGetAsync(minigameCatalog, minigameName)

			if not getMinigameSuccess then
				warn(("Failed to retrieve minigame '%s' data."):format(minigameName))
				setOperationLockAsync(false)
				return
			end

			for i = currentMinigameServerCount + 1, count do
				local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(minigamePlaceId)

				if not reserveSuccess then
					warn(
						(
							"Failed to reserve a private server for minigame '%s' in server %d. (This may have been run"
							.. " in Studio.)"
						):format(minigameName, i)
					)
					setOperationLockAsync(false)
					return
				end

				print(("Reserved a private server for minigame '%s' in server %d."):format(minigameName, i))

				minigameData[i] = {
					accessCode = accessCode,
					privateServerId = privateServerId,
				}
			end

			local setMinigameSuccess = slowSetAsync(minigameCatalog, minigameName, minigameData)

			if not setMinigameSuccess then
				warn(("Failed to add minigame '%s' to the minigame catalog."):format(minigameName))
				setOperationLockAsync(false)
				return
			end

			print(("Added minigame '%s' to the minigame catalog."):format(minigameName))
		end

		local setMinigameServerCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "MinigameServerCount", count)

		if not setMinigameServerCountSuccess then
			warn(("Failed to update the minigame server count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the minigame server count to %d."):format(count))

		print(("The minigame server count has been successfully increased to %d."):format(count))
	end

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.setPartyServerCount(count: number, force: true?)
	if typeof(count) ~= "number" or count ~= count or count ~= math.floor(count) or count < 0 then
		warn "The server count must be a non-negative integer."
		return
	elseif force ~= nil and force ~= true then
		warn "The force flag must be true or nil."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Setting the party server count to %d…"):format(count))

	local currentPartyServerCount = ServerCatalog.getPartyServerCountAsync()

	if not currentPartyServerCount then
		warn "Failed to retrieve the party server count."
		setOperationLockAsync(false)
		return
	end

	if currentPartyServerCount > count and not force then
		warn "Cannot reduce the party server count without the force flag."
		setOperationLockAsync(false)
		return
	end

	if currentPartyServerCount == count then
		print(("The party server count is already %d."):format(count))
	elseif currentPartyServerCount > count then
		local setPartyServerCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "PartyServerCount", count)

		if not setPartyServerCountSuccess then
			warn(("Failed to update the party server count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the party server count to %d."):format(count))

		print(("The party server count has been successfully reduced to %d."):format(count))
	else
		local partyList = ServerCatalog.getPartyListAsync()

		if not partyList then
			warn "Failed to retrieve the party list."
			setOperationLockAsync(false)
			return
		end

		print "Retrieved the party list."

		for partyName, partyInfo in pairs(partyList) do
			local partyPlaceId = partyInfo.placeId

			local getPartySuccess, partyData: CatalogPartyData = slowGetAsync(partyCatalog, partyName)

			if not getPartySuccess then
				warn(("Failed to retrieve party '%s' data."):format(partyName))
				setOperationLockAsync(false)
				return
			end

			for i = currentPartyServerCount + 1, count do
				local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(partyPlaceId)

				if not reserveSuccess then
					warn(
						(
							"Failed to reserve a private server for party '%s' in server %d. (This may have been run in"
							.. " Studio.)"
						):format(partyName, i)
					)
					setOperationLockAsync(false)
					return
				end

				print(("Reserved a private server for party '%s' in server %d."):format(partyName, i))

				partyData[i] = {
					accessCode = accessCode,
					privateServerId = privateServerId,
				}
			end

			local setPartySuccess = slowSetAsync(partyCatalog, partyName, partyData)

			if not setPartySuccess then
				warn(("Failed to add party '%s' to the party catalog."):format(partyName))
				setOperationLockAsync(false)
				return
			end

			print(("Added party '%s' to the party catalog."):format(partyName))
		end

		local setPartyServerCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "PartyServerCount", count)

		if not setPartyServerCountSuccess then
			warn(("Failed to update the party server count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the party server count to %d."):format(count))

		print(("The party server count has been successfully increased to %d."):format(count))
	end

	setOperationLockAsync(false)
end

function ServerCatalogControlPanel.setWorldCount(count: number, force: true?)
	if typeof(count) ~= "number" or count ~= count or count ~= math.floor(count) or count < 0 then
		warn "The world count must be a non-negative integer."
		return
	elseif force ~= nil and force ~= true then
		warn "The force flag must be true or nil."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(("Setting the world count to %d…"):format(count))

	local currentWorldCount = ServerCatalog.getWorldCountAsync()

	if not currentWorldCount then
		warn "Failed to retrieve the world count."
		setOperationLockAsync(false)
		return
	end

	if currentWorldCount > count and not force then
		warn "Cannot reduce the world count without the force flag."
		setOperationLockAsync(false)
		return
	end

	if currentWorldCount == count then
		print(("The world count is already %d."):format(count))
	elseif currentWorldCount > count then
		local setWorldCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn(("Failed to update the world count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the world count to %d."):format(count))

		print(("The world count has been successfully reduced to %d."):format(count))
	else
		local locationList = ServerCatalog.getWorldLocationListAsync()

		if not locationList then
			warn "Failed to retrieve the world location list."
			setOperationLockAsync(false)
			return
		end

		print "Retrieved the world location list."

		for i = currentWorldCount + 1, count do
			local newWorld = {}

			for locationName, locationInfo in pairs(locationList) do
				local locationPlaceId = locationInfo.placeId

				local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(locationPlaceId)

				if not reserveSuccess then
					warn(
						(
							"Failed to reserve a private server for location '%s' in world %d. (This may have been run"
							.. " in Studio.)"
						):format(locationName, i)
					)
					setOperationLockAsync(false)
					return
				end

				print(("Reserved a private server for location '%s' in world %d."):format(locationName, i))

				local setDictionarySuccess = slowSetAsync(serverDictionary, privateServerId, { world = i })

				if not setDictionarySuccess then
					warn(
						("Failed to add server dictionary entry for location '%s' in world %d."):format(locationName, i)
					)
					setOperationLockAsync(false)
					return
				end

				print(("Added server dictionary entry for location '%s' in world %d."):format(locationName, i))

				newWorld[locationName] = {
					accessCode = accessCode,
					privateServerId = privateServerId,
				}
			end

			local setWorldSuccess = slowSetAsync(worldCatalog, tostring(i), newWorld)

			if not setWorldSuccess then
				warn(("Failed to add world %d to the world catalog."):format(i))
				setOperationLockAsync(false)
				return
			end

			print(("Added world %d to the world catalog."):format(i))
		end

		local setWorldCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn(("Failed to update the world count to %d."):format(count))
			setOperationLockAsync(false)
			return
		end

		print(("Updated the world count to %d."):format(count))

		print(("The world count has been successfully increased to %d."):format(count))
	end

	setOperationLockAsync(false)
end

return ServerCatalogControlPanel
