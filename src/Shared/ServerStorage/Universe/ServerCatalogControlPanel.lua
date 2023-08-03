--!strict

local DANGEROUS_OPERATION_CONFIRM_TIME = 5

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

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local TeleportUtility = require(ServerStorage.Shared.Utility.TeleportUtility)
local ServerCatalog = require(ServerStorage.Shared.Universe.ServerCatalog)
local Table = require(ReplicatedFirst.Shared.Utility.Table)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type CatalogMinigameData = Types.CatalogMinigameData
type CatalogPartyData = Types.CatalogPartyData
type CatalogWorldData = Types.CatalogWorldData

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"

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

	return DataStoreUtility.safeGetAsync(dataStore, key)
end

local function slowSetAsync(dataStore, key, value, userIds, options)
	local now = os.time()

	if lastWrite and now - lastWrite < DATASTORE_OPERATION_COOLDOWN then
		task.wait(DATASTORE_OPERATION_COOLDOWN - (now - lastWrite))
	end

	lastWrite = os.time()

	return DataStoreUtility.safeSetAsync(dataStore, key, value, userIds, options)
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

		local updateSuccess = DataStoreUtility.safeUpdateAsync(catalogInfo, "OperationLock", function(oldValue)
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
		local success = DataStoreUtility.safeRemoveAsync(catalogInfo, "OperationLock")

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

function ServerCatalogControlPanel.addWorldLocation(name: string, placeId: number)
	if typeof(name) ~= "string" then
		warn "The location name must be a string."
		return
	elseif typeof(placeId) ~= "number" or placeId ~= placeId or placeId ~= math.floor(placeId) or placeId < 0 then
		warn "The place ID must be a non-negative integer."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(`Adding location '{name}' with place ID {placeId}…`)

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the world location list."

	if locationList[name] then
		print(`Location '{name}' already exists.`)
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
		print "The world count is 0, so a dummy server will be reserved to verify that this location is reservable."

		local reserveSuccess = TeleportUtility.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				`Failed to reserve a dummy private server for location '{name}'.`
					.. " (The given place ID may not be valid, or this may have been run in Studio.)"
			)
			setOperationLockAsync(false)
			return
		end

		print(`Successfully reserved a dummy private server for location '{name}'.`)
	end

	-- Add the location to all worlds

	for world = 1, worldCount do
		local getWorldSuccess, worldData: CatalogWorldData = slowGetAsync(worldCatalog, `World{world}`)

		if not getWorldSuccess then
			warn(`Failed to retrieve world {world} data.`)
			setOperationLockAsync(false)
			return
		end

		print(`Retrieved world {world} data.`)

		local reserveSuccess, accessCode, privateServerId = TeleportUtility.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				`Failed to reserve private server for location '{name}' in world {world}.`
					.. " (The given place ID may not be valid, or this may have been run in Studio.)"
			)
			setOperationLockAsync(false)
			return
		end

		print(`Reserved a private server for location '{name}' in world {world}.`)

		local setDictionarySuccess = slowSetAsync(serverDictionary, privateServerId, {
			location = name,
			type = "location",
			world = world,
		})

		if not setDictionarySuccess then
			warn(`Failed to add server dictionary entry for location '{name}' in world {world}.`)
			setOperationLockAsync(false)
			return
		end

		print(`Added server dictionary entry for location '{name}' in world {world}.`)

		worldData[name] = {
			accessCode = accessCode,
			privateServerId = privateServerId,
		}

		local setWorldSuccess = slowSetAsync(worldCatalog, `World{world}`, worldData)

		if not setWorldSuccess then
			warn(`Failed to add location '{name}' to world {world}.`)
			setOperationLockAsync(false)
			return
		end

		print(`Added location '{name}' to world {world}.`)
	end

	-- Register the location

	locationList[name] = {
		placeId = placeId,
	}

	local setLocationListSuccess = DataStoreUtility.safeSetAsync(catalogInfo, "WorldLocationList", locationList)

	if not setLocationListSuccess then
		warn "Failed to update the world location list."
		setOperationLockAsync(false)
		return
	end

	print(`Added location '{name}' to the world location list.`)

	print(`Location '{name}' has been successfully added.`)

	setOperationLockAsync(false)
end

local lastReleaseAttempt: number?

function ServerCatalogControlPanel.forceReleaseOperationLock()
	print "Releasing the operation lock…"

	if not lastReleaseAttempt or time() - lastReleaseAttempt > DANGEROUS_OPERATION_CONFIRM_TIME then
		warn "--- WARNING ---"
		warn "This operation is dangerous and should only be performed if the operation lock is stuck."
		warn(
			"Releasing the operation lock while an operation is in progress will allow you to perform another"
				.. " operation while the first operation is still in progress, potentially causing data corruption."
		)
		warn(
			"Think twice before continuing. If you choose to do so, rerun this command within"
				.. ` {DANGEROUS_OPERATION_CONFIRM_TIME} seconds of this call.`
		)

		lastReleaseAttempt = time()

		return
	end

	lastReleaseAttempt = nil

	if localOperationLock then
		warn "Cannot force the operation lock to release because the operation lock is currently held locally."
		return
	end

	if not setOperationLockAsync(false) then return end

	print "The operation lock has been successfully removed."
end

function ServerCatalogControlPanel.printWorld(world: number)
	if typeof(world) ~= "number" or world ~= world or world ~= math.floor(world) or world < 1 then
		warn "The world must be a positive integer."
		return
	end

	print(`Printing world {world}…`)

	local worldData = ServerCatalog.getWorldAsync(world)

	if not worldData then
		warn(`Failed to retrieve world data for world {world}. (This world may not exist.)`)
		return
	end

	print(`World {world}: {Table.toString(worldData, 4)}`)
end

function ServerCatalogControlPanel.printWorldCount()
	print "Retrieving the world count…"

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to retrieve the world count."
		return
	end

	print(`There are {worldCount} worlds.`)
end

function ServerCatalogControlPanel.printWorldLocationList()
	print "Retrieving the world location list…"

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		return
	end

	print(`World location list: {Table.toString(locationList, 4)}`)
end

local lastRemoveLocationAttempt: number?

function ServerCatalogControlPanel.removeWorldLocation(locationName: string)
	if typeof(locationName) ~= "string" then
		warn "The location name must be a string."
		return
	end

	if not lastRemoveLocationAttempt or time() - lastRemoveLocationAttempt > DANGEROUS_OPERATION_CONFIRM_TIME then
		warn "--- WARNING ---"
		warn(
			"This operation is dangerous and should only be performed if you are sure this location is no longer in"
				.. " use."
		)
		warn "Removing a location that is still in use will likely cause issues ingame."
		warn(
			"Think twice before continuing. If you choose to do so, rerun this command within"
				.. ` {DANGEROUS_OPERATION_CONFIRM_TIME} seconds of this call.`
		)

		lastRemoveLocationAttempt = time()

		return
	end

	lastRemoveLocationAttempt = nil

	if not setOperationLockAsync(true) then return end

	print(`Removing location '{locationName}'…`)

	local locationList = ServerCatalog.getWorldLocationListAsync()

	if not locationList then
		warn "Failed to retrieve the world location list."
		setOperationLockAsync(false)
		return
	end

	print "Retrieved the world location list."

	if not locationList[locationName] then
		print(`Location '{locationName}' already does not exist.`)
		setOperationLockAsync(false)
		return
	end

	locationList[locationName] = nil

	local removeLocationSuccess = DataStoreUtility.safeSetAsync(catalogInfo, "WorldLocationList", locationList)

	if not removeLocationSuccess then
		warn(`Failed to remove location '{locationName}' from the world location list.`)
		setOperationLockAsync(false)
		return
	end

	print(`Removed location '{locationName}' from the world location list.`)

	print(`Location '{locationName}' has been successfully removed.`)

	setOperationLockAsync(false)
end

local lastRemoveWorldAttempt: number?

function ServerCatalogControlPanel.setWorldCount(count: number)
	if typeof(count) ~= "number" or count ~= count or count ~= math.floor(count) or count < 0 then
		warn "The world count must be a non-negative integer."
		return
	end

	if not setOperationLockAsync(true) then return end

	print(`Setting the world count to {count}…`)

	local currentWorldCount = ServerCatalog.getWorldCountAsync()

	if not currentWorldCount then
		warn "Failed to retrieve the world count."
		setOperationLockAsync(false)
		return
	end

	if
		currentWorldCount > count
		and (not lastRemoveWorldAttempt or time() - lastRemoveWorldAttempt > DANGEROUS_OPERATION_CONFIRM_TIME)
	then
		warn "--- WARNING ---"
		warn(
			"This operation is dangerous and should only be performed if you are sure if the affect world(s) is/are no"
				.. " longer in use."
		)
		warn "Removing a world that is still in use will likely cause issues ingame."
		warn(
			"Think twice before continuing. If you choose to do so, rerun this command within"
				.. ` {DANGEROUS_OPERATION_CONFIRM_TIME} seconds of this call.`
		)

		lastRemoveWorldAttempt = time()

		setOperationLockAsync(false)
		return
	end

	lastRemoveWorldAttempt = nil

	if currentWorldCount == count then
		print(`The world count is already {count}.`)
	elseif currentWorldCount > count then
		local setWorldCountSuccess = DataStoreUtility.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn(`Failed to update the world count to {count}.`)
			setOperationLockAsync(false)
			return
		end

		print(`Updated the world count to {count}.`)

		print(`The world count has been successfully reduced to {count}.`)
	else
		local locationList = ServerCatalog.getWorldLocationListAsync()

		if not locationList then
			warn "Failed to retrieve the world location list."
			setOperationLockAsync(false)
			return
		end

		print "Retrieved the world location list."

		for world = currentWorldCount + 1, count do
			local newWorld = {}

			for locationName, locationInfo in pairs(locationList) do
				local locationPlaceId = locationInfo.placeId

				local reserveSuccess, accessCode, privateServerId =
					TeleportUtility.safeReserveServerAsync(locationPlaceId)

				if not reserveSuccess then
					warn(
						`Failed to reserve a private server for location '{locationName}' in world {world}.`
							.. " (This may have been run in Studio)."
					)
					setOperationLockAsync(false)
					return
				end

				print(`Reserved a private server for location '{locationName}' in world {world}.`)

				local setDictionarySuccess = slowSetAsync(serverDictionary, privateServerId, {
					location = locationName,
					type = "location",
					world = world,
				})

				if not setDictionarySuccess then
					warn(`Failed to add server dictionary entry for location '{locationName}' in world {world}.`)
					setOperationLockAsync(false)
					return
				end

				print(`Added server dictionary entry for location '{locationName}' in world {world}.`)

				newWorld[locationName] = {
					accessCode = accessCode,
					privateServerId = privateServerId,
				}
			end

			local setWorldSuccess = slowSetAsync(worldCatalog, `World{world}`, newWorld)

			if not setWorldSuccess then
				warn(`Failed to add world {world} to the world catalog.`)
				setOperationLockAsync(false)
				return
			end

			print(`Added world {world} to the world catalog.`)
		end

		local setWorldCountSuccess = DataStoreUtility.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn(`Failed to update the world count to {count}.`)
			setOperationLockAsync(false)
			return
		end

		print(`Updated the world count to {count}.`)

		print(`The world count has been successfully increased to {count}.`)
	end

	setOperationLockAsync(false)
end

return ServerCatalogControlPanel
