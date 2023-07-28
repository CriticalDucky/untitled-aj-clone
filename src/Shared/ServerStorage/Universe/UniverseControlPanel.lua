--!strict

local DATASTORE_MODIFY_COOLDOWN = 1

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

assert(not RunService:IsStudio(), "This module cannot be used in Studio.")

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local SafeTeleport = require(ServerStorage.Shared.Utility.SafeTeleport)
local Table = require(ReplicatedFirst.Shared.Utility.Table)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type WorldData = Types.WorldData

local minigameCatalog = DataStoreService:GetDataStore "MinigameCatalog"
local partyCatalog = DataStoreService:GetDataStore "PartyCatalog"
local worldCatalog = DataStoreService:GetDataStore "WorldCatalog"

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

--[[
	Provides functions for managing the universe server catalog.

	---

	⚠️ **FOR MANUAL DEVELOPER USE ONLY** ⚠️
]]
local UniverseControlPanel = {}

function UniverseControlPanel.addLocation(locationName: string, placeId: number)
	assert(typeof(locationName) == "string", "The location name must be a string.")
	assert(typeof(placeId) == "number" and placeId == placeId, "The place ID must be a valid number.")
	assert(placeId == math.floor(placeId), "The place ID must be an integer.")

	print(("Adding location '%s'…"):format(locationName))

	local getCountSuccess, worldCount = SafeDataStore.safeGetAsync(worldCatalog, "Count")

	if not getCountSuccess then
		warn "Failed to retrieve the world count."
		return
	end

	if not worldCount or worldCount == 0 then
		warn "Worlds must be created before locations can be added."
		return
	end

	print "Retrieved world count."

	for i = 1, worldCount do
		local worldData

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local getSuccess, newWorldData: WorldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(i))

			worldData = newWorldData
		until getSuccess

		print(("Retrieved world %d data."):format(i))

		if worldData[locationName] then
			warn "This location already exists."
			continue
		end

		local accessCode, privateServerId

		repeat
			local reserveSuccess, newAccessCode, newPrivateServerId = SafeTeleport.safeReserveServerAsync(placeId)

			if i == 1 and not reserveSuccess then
				warn "The given place ID may not be valid."
				return
			end

			accessCode = newAccessCode
			privateServerId = newPrivateServerId
		until reserveSuccess

		print(("Reserved a private server for location '%s' in world %d."):format(locationName, i))

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local setSuccess = SafeDataStore.safeSetAsync(serverDictionary, privateServerId, { world = i })
		until setSuccess

		print(("Added server dictionary entry for location '%s' in world %d."):format(locationName, i))

		worldData[locationName] = {
			accessCode = accessCode,
			placeId = placeId,
			privateServerId = privateServerId,
		}

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local setSuccess = SafeDataStore.safeSetAsync(worldCatalog, tostring(i), worldData)
		until setSuccess

		print(("Added location '%s' to world %d."):format(locationName, i))
	end

	print(("Location '%s' has been added to all worlds."):format(locationName))
end

function UniverseControlPanel.printWorld(world: number)
	assert(typeof(world) == "number" and world == world, "The world must be a valid number.")
	assert(world == math.floor(world), "The world must be an integer.")
	assert(world > 0, "The world must be positive.")

	print(("Printing world %d…"):format(world))

	local getSuccess, worldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(world))

	if not getSuccess then
		warn "Failed to retrieve the world data."
		return
	end

	if not worldData then
		warn "This world does not exist."
		return
	end

	print(("World %d: %s"):format(world, Table.toString(worldData, 4)))
end

function UniverseControlPanel.printWorldCount()
	print "Retrieving the world count…"

	local getCountSuccess, count = SafeDataStore.safeGetAsync(worldCatalog, "Count")

	if not getCountSuccess then
		warn "Failed to retrieve the world count."
		return
	end

	if not getCountSuccess then
		print "Failed to retrieve the world count."
		return
	end

	print(("There are %d worlds."):format(count or 0))
end

function UniverseControlPanel.removeLocation(locationName: string)
	assert(typeof(locationName) == "string", "The location name must be a string.")

	print(("Removing location '%s'…"):format(locationName))

	local getCountSuccess, worldCount = SafeDataStore.safeGetAsync(worldCatalog, "Count")

	if not getCountSuccess then
		warn "Failed to retrieve the world count."
		return
	end

	print "Retrieved world count."

	if not worldCount or worldCount == 0 then
		warn "Worlds must be created before locations can be removed."
		return
	end

	for i = 1, worldCount do
		local worldData

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local getSuccess, newWorldData: WorldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(i))

			worldData = newWorldData
		until getSuccess

		print(("Retrieved world %d data."):format(i))

		if not worldData[locationName] then
			warn(("Location '%s' does not exist in world %d."):format(locationName, i))
			continue
		end

		local privateServerId = worldData[locationName].privateServerId

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local removeSuccess = SafeDataStore.safeRemoveAsync(serverDictionary, privateServerId)
		until removeSuccess

		print(("Removed server dictionary entry for location '%s' in world %d."):format(locationName, i))

		worldData[locationName] = nil

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local setSuccess = SafeDataStore.safeSetAsync(worldCatalog, tostring(i), worldData)
		until setSuccess

		print(("Removed location '%s' from world %d."):format(locationName, i))
	end

	print(("Location '%s' has been removed from all worlds."):format(locationName))
end

function UniverseControlPanel.setWorldCount(count: number, force: true?)
	assert(typeof(count) == "number" and count == count, "The world count must be a valid number.")
	assert(count == math.floor(count), "The world count must be an integer.")
	assert(count >= 0, "The world count must be non-negative.")
	assert(force == nil or force == true, "The force flag must be true or nil.")

	print(("Setting the world count to %d…"):format(count))

	local getCountSuccess, currentCount = SafeDataStore.safeGetAsync(worldCatalog, "Count")

	if not getCountSuccess then
		warn "Failed to retrieve the current world count."
		return
	end

	currentCount = currentCount or 0

	if currentCount > count and not force then
		warn "Cannot reduce the world count without the force flag."
		return
	end

	if currentCount == count then
		print(("The world count is already %d."):format(count))
	elseif currentCount > count then
		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local setSuccess = SafeDataStore.safeSetAsync(worldCatalog, "Count", count)
		until setSuccess

		print(("Updated the world counter to %d."):format(count))

		for i = currentCount, count + 1, -1 do
			local worldData

			task.wait(DATASTORE_MODIFY_COOLDOWN)

			repeat
				local getSuccess, newWorldData: WorldData = SafeDataStore.safeGetAsync(worldCatalog, tostring(i))

				worldData = newWorldData
			until getSuccess

			print(("Retrieved world %d data."):format(i))

			for locationName, locationData in pairs(worldData) do
				local privateServerId = locationData.privateServerId

				task.wait(DATASTORE_MODIFY_COOLDOWN)

				repeat
					local removeSuccess = SafeDataStore.safeRemoveAsync(serverDictionary, privateServerId)
				until removeSuccess

				print(("Removed server dictionary entry for location '%s' in world %d."):format(locationName, i))
			end

			task.wait(DATASTORE_MODIFY_COOLDOWN)

			repeat
				local removeSuccess = SafeDataStore.safeRemoveAsync(worldCatalog, tostring(i))
			until removeSuccess

			print(("Removed world %d."):format(i))
		end

		print(("The world count has been reduced to %d."):format(count))
	else
		task.wait(DATASTORE_MODIFY_COOLDOWN)

		local getSuccess, worldTemplate = SafeDataStore.safeGetAsync(worldCatalog, "1")

		if not getSuccess then
			warn "Failed to retrieve world 1 as a location template."
			return
		end

		print "Retrieved world 1 as a location template."

		for i = currentCount + 1, count do
			local newWorld = {}

			if worldTemplate then
				for locationName, locationData in pairs(worldTemplate) do
					local accessCode, privateServerId

					repeat
						local reserveSuccess, newAccessCode, newPrivateServerId =
							SafeTeleport.safeReserveServerAsync(locationData.placeId)

						accessCode = newAccessCode
						privateServerId = newPrivateServerId
					until reserveSuccess

					print(("Reserved a private server for location '%s' in world %d."):format(locationName, i))

					task.wait(DATASTORE_MODIFY_COOLDOWN)

					repeat
						local setSuccess = SafeDataStore.safeSetAsync(serverDictionary, privateServerId, { world = i })
					until setSuccess

					print(("Added server dictionary entry for location '%s' in world %d."):format(locationName, i))

					newWorld[locationName] = {
						accessCode = accessCode,
						placeId = locationData.placeId,
						privateServerId = privateServerId,
					}
				end
			end

			task.wait(DATASTORE_MODIFY_COOLDOWN)

			repeat
				local setSuccess = SafeDataStore.safeSetAsync(worldCatalog, tostring(i), newWorld)
			until setSuccess

			print(("Created world %d."):format(i))
		end

		task.wait(DATASTORE_MODIFY_COOLDOWN)

		repeat
			local setSuccess = SafeDataStore.safeSetAsync(worldCatalog, "Count", count)
		until setSuccess

		print(("Updated the world counter to %d."):format(count))

		print(("The world count has been increased to %d."):format(count))
	end
end

return UniverseControlPanel
