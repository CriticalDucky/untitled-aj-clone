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

type WorldData = Types.WorldData

local catalogInfo = DataStoreService:GetDataStore "CatalogInfo"

local minigameCatalog = DataStoreService:GetDataStore "MinigameCatalog"
local partyCatalog = DataStoreService:GetDataStore "PartyCatalog"
local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--[[
	Used by setter functions to prevent multiple operations from being run at once.

	TODO: Move to data store? In which case: also make a "force lock release" function.
]]
local operationLock = false

--[[
	Provides functions for managing the universe server catalog.

	---

	⚠️ **FOR MANUAL DEVELOPER USE ONLY** ⚠️
]]
local UniverseControlPanel = {}

function UniverseControlPanel.addLocation(locationName: string, placeId: number)
	assert(not operationLock, "An operation is already in progress.")
	assert(typeof(locationName) == "string", "The location name must be a string.")
	assert(typeof(placeId) == "number" and placeId == placeId, "The place ID must be a valid number.")
	assert(placeId == math.floor(placeId), "The place ID must be an integer.")

	operationLock = true

	print(("Adding location '%s' with place ID %d…"):format(locationName, placeId))

	local getLocationListSuccess, locationList = SafeDataStore.safeGetAsync(catalogInfo, "WorldLocationList")

	if not getLocationListSuccess then
		warn "Failed to retrieve the world location list."
		operationLock = false
		return
	end

	print "Retrieved the world location list."

	locationList = locationList or {}

	if locationList[locationName] then
		warn "The location already exists."
		operationLock = false
		return
	end

	task.wait(DATASTORE_OPERATION_COOLDOWN)

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to retrieve the world count."
		operationLock = false
		return
	end

	print "Retrieved the world count."

	-- Add the location to all worlds

	for i = 1, worldCount do
		if i == 1 then task.wait(DATASTORE_OPERATION_COOLDOWN) end

		local getWorldSuccess, worldData: WorldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(i))

		if not getWorldSuccess then
			warn(("Failed to retrieve world %d data."):format(i))
			operationLock = false
			return
		end

		print(("Retrieved world %d data."):format(i))

		local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(placeId)

		if not reserveSuccess then
			warn(
				"Failed to reserve a private server. (The given place ID may not be valid, or this may have been run "
					.. "in Studio.)"
			)
			operationLock = false
			return
		end

		print(("Reserved a private server for location '%s' in world %d."):format(locationName, i))

		if i ~= 1 then task.wait(DATASTORE_OPERATION_COOLDOWN) end

		local setDictionarySuccess = SafeDataStore.safeSetAsync(serverDictionary, privateServerId, { world = i })

		if not setDictionarySuccess then
			warn(("Failed to add server dictionary entry for location '%s' in world %d."):format(locationName, i))
			operationLock = false
			return
		end

		print(("Added server dictionary entry for location '%s' in world %d."):format(locationName, i))

		worldData[locationName] = {
			accessCode = accessCode,
			privateServerId = privateServerId,
		}

		task.wait(DATASTORE_OPERATION_COOLDOWN)

		local setWorldSuccess = SafeDataStore.safeSetAsync(worldCatalog, tostring(i), worldData)

		if not setWorldSuccess then
			warn(("Failed to update world %d data."):format(i))
			operationLock = false
			return
		end

		print(("Added location '%s' to world %d."):format(locationName, i))
	end

	-- Register the location

	locationList[locationName] = {
		placeId = placeId,
	}

	task.wait(DATASTORE_OPERATION_COOLDOWN)

	repeat
		local setSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldLocationList", locationList)
	until setSuccess

	print(("Added location '%s' to the world location list."):format(locationName))

	print(("Location '%s' has been successfully added."):format(locationName))

	operationLock = false
end

function UniverseControlPanel.printWorld(world: number)
	assert(typeof(world) == "number" and world == world, "The world must be a valid number.")
	assert(world == math.floor(world), "The world must be an integer.")
	assert(world > 0, "The world must be positive.")

	print(("Printing world %d…"):format(world))

	local worldData = ServerCatalog.getWorldAsync(world)

	if not worldData then
		warn(("Failed to retrieve world data for world %d."):format(world))
		return
	end

	print(("World %d: %s"):format(world, Table.toString(worldData, 4)))
end

function UniverseControlPanel.printWorldCount()
	print "Retrieving the world count…"

	local worldCount = ServerCatalog.getWorldCountAsync()

	if not worldCount then
		warn "Failed to retrieve the world count."
		return
	end

	print(("There are %d worlds."):format(worldCount))
end

function UniverseControlPanel.removeLocation(locationName: string)
	assert(not operationLock, "An operation is already in progress.")
	assert(typeof(locationName) == "string", "The location name must be a string.")

	operationLock = true

	print(("Removing location '%s'…"):format(locationName))

	local getLocationListSuccess, locationList = SafeDataStore.safeGetAsync(catalogInfo, "WorldLocationList")

	if not getLocationListSuccess then
		warn "Failed to retrieve the world location list."
		operationLock = false
		return
	end

	print "Retrieved the world location list."

	locationList = locationList or {}

	if not locationList[locationName] then
		warn "This location does not exist."
		operationLock = false
		return
	end

	locationList[locationName] = nil

	local removeLocationSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldLocationList", locationList)

	if not removeLocationSuccess then
		warn "Failed to remove the location from the world location list."
		operationLock = false
		return
	end

	print(("Removed location '%s' from the world location list."):format(locationName))

	print(("Location '%s' has been successfully removed."):format(locationName))

	operationLock = false
end

function UniverseControlPanel.setWorldCount(count: number, force: true?)
	assert(not operationLock, "An operation is already in progress.")
	assert(typeof(count) == "number" and count == count, "The world count must be a valid number.")
	assert(count == math.floor(count), "The world count must be an integer.")
	assert(count >= 0, "The world count must be non-negative.")
	assert(force == nil or force == true, "The force flag must be true or nil.")

	operationLock = true

	print(("Setting the world count to %d…"):format(count))

	local currentWorldCount = ServerCatalog.getWorldCountAsync()

	if not currentWorldCount then
		warn "Failed to retrieve the world count."
		operationLock = false
		return
	end

	if currentWorldCount > count and not force then
		warn "Cannot reduce the world count without the force flag."
		operationLock = false
		return
	end

	if currentWorldCount == count then
		print(("The world count is already %d."):format(count))
	elseif currentWorldCount > count then
		local setWorldCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn "Failed to update the world count."
			operationLock = false
			return
		end

		print(("Updated the world counter to %d."):format(count))

		print(("The world count has been successfully reduced to %d."):format(count))
	else
		task.wait(DATASTORE_OPERATION_COOLDOWN)

		local getLocationsSuccess, locationList = SafeDataStore.safeGetAsync(catalogInfo, "WorldLocationList")

		if not getLocationsSuccess then
			warn "Failed to retrieve the world location list."
			operationLock = false
			return
		end

		print "Retrieved the world location list."

		locationList = locationList or {}

		for i = currentWorldCount + 1, count do
			local newWorld = {}

			for locationName, locationInfo in pairs(locationList) do
				local locationPlaceId = locationInfo.placeId

				local reserveSuccess, accessCode, privateServerId = SafeTeleport.safeReserveServerAsync(locationPlaceId)

				if not reserveSuccess then
					warn "Failed to reserve a private server. (This may have been run in Studio.)"
					operationLock = false
					return
				end

				print(("Reserved a private server for location '%s' in world %d."):format(locationName, i))

				if i ~= currentWorldCount + 1 then task.wait(DATASTORE_OPERATION_COOLDOWN) end

				local setDictionarySuccess = SafeDataStore.safeSetAsync(serverDictionary, privateServerId, {
					world = i,
				})

				if not setDictionarySuccess then
					warn(
						("Failed to add server dictionary entry for location '%s' in world %d."):format(locationName, i)
					)
					operationLock = false
					return
				end

				print(("Added server dictionary entry for location '%s' in world %d."):format(locationName, i))

				newWorld[locationName] = {
					accessCode = accessCode,
					privateServerId = privateServerId,
				}
			end

			task.wait(DATASTORE_OPERATION_COOLDOWN)

			local setWorldSuccess = SafeDataStore.safeSetAsync(worldCatalog, tostring(i), newWorld)

			if not setWorldSuccess then
				warn(("Failed to create world %d."):format(i))
				operationLock = false
				return
			end

			print(("Created world %d."):format(i))
		end

		task.wait(DATASTORE_OPERATION_COOLDOWN)

		local setWorldCountSuccess = SafeDataStore.safeSetAsync(catalogInfo, "WorldCount", count)

		if not setWorldCountSuccess then
			warn "Failed to update the world count."
			operationLock = false
			return
		end

		print(("Updated the world count to %d."):format(count))

		print(("The world count has been successfully increased to %d."):format(count))
	end

	operationLock = false
end

return UniverseControlPanel
