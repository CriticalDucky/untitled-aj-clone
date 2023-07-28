--!strict

local MAX_CATALOG_SIZE = 4194304

local DataStoreService = game:GetService "DataStoreService"
local HttpService = game:GetService "HttpService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local Promise = require(ReplicatedFirst.Vendor.Promise)

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local SafeTeleport = require(ServerStorage.Shared.Utility.SafeTeleport)
local Table = require(ReplicatedFirst.Shared.Utility.Table)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type UniverseServerCatalog = Types.UniverseServerCatalog

local universeData = DataStoreService:GetDataStore "UniverseData"

--[[
	Provides functions for managing the universe server catalog.

	---

	⚠️ **FOR MANUAL DEVELOPER USE ONLY** ⚠️
]]
local UniverseServerCatalogControlPanel = {}

function UniverseServerCatalogControlPanel.addLocation(locationName: string, placeId: number)
	print "Adding a location…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	if not serverCatalog then
		print "The server catalog has not been initialized!"
		return
	end

	local worlds = serverCatalog.worlds

	if not worlds then
		print "Worlds have not been initialized!"
		return
	end

	if not worlds[1] then
		print "Worlds must be created before locations can be added."
		return
	end

	if worlds[1][locationName] then
		print "The location already exists."
		return
	end

	for _, world in ipairs(worlds) do
		world[locationName] = {
			placeId = placeId,
		}
	end

	while true do
		local reserveServerPromises = {}

		for _, world in ipairs(worlds) do
			local location = world[locationName]

			local reserveServerPromise = Promise.new(function(resolve, reject)
				local reserveSuccess, accessCode, privateServerId =
					SafeTeleport.safeReserveServerAsync(location.placeId)

				if not reserveSuccess then return reject() end

				location.accessCode = accessCode
				location.privateServerId = privateServerId

				return resolve()
			end)

			table.insert(reserveServerPromises, reserveServerPromise)
		end

		local reserveServersSuccess = Promise.all(reserveServerPromises):await()

		if reserveServersSuccess then break end
	end

	print "Pushing changes to the server catalog…"

	local setSuccess = SafeDataStore.safeSetAsync(universeData, "ServerCatalog", serverCatalog)

	if not setSuccess then
		print "Failed to push changes to the server catalog."
		return
	end

	print(("Location '%s' added."):format(locationName))
end

function UniverseServerCatalogControlPanel.initialize()
	print "Initializing the server catalog…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	serverCatalog = serverCatalog or {}

	if serverCatalog.minigames and serverCatalog.parties and serverCatalog.worlds then
		print "The server catalog is already initialized."
		return
	end

	if serverCatalog.minigames then
		print "Minigames already initialized."
	else
		serverCatalog.minigames = {}
		print "Minigames initialized."
	end

	if serverCatalog.parties then
		print "Parties already initialized."
	else
		serverCatalog.parties = {}
		print "Parties initialized."
	end

	if serverCatalog.worlds then
		print "Worlds already initialized."
	else
		serverCatalog.worlds = {}
		print "Worlds initialized."
	end

	print "Pushing changes to the server catalog…"

	local setSuccess = SafeDataStore.safeSetAsync(universeData, "ServerCatalog", serverCatalog)

	if not setSuccess then
		print "Failed to push changes to the server catalog."
		return
	end

	print "Server catalog initialized."
end

function UniverseServerCatalogControlPanel.print()
	print "Printing the server catalog…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	if not serverCatalog then
		print "The server catalog has not been initialized!"
		return
	end

	print("\n\nServer Catalog:", Table.toString(serverCatalog, 4) .. "\n")
	print(
		"NOTE: If changes were recently made to the server catalog, it may take some time for servers to receive them"
			.. " (including this one)."
	)
end

function UniverseServerCatalogControlPanel.printSize()
	print "Printing the size of the server catalog…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	if not serverCatalog then
		print "The server catalog has not been initialized!"
		return
	end

	local serverCatalogJson = HttpService:JSONEncode(serverCatalog)

	print(("The server catalog is %d characters long."):format(serverCatalogJson:len()))
	print(
		("Assuming the maximum size of the server catalog is %d characters, the server catalog is %.2f%% full."):format(
			MAX_CATALOG_SIZE,
			serverCatalogJson:len() / MAX_CATALOG_SIZE * 100
		)
	)
end

function UniverseServerCatalogControlPanel.removeLocation(locationName: string)
	print "Removing a location…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	if not serverCatalog then
		print "The server catalog has not been initialized!"
		return
	end

	local worlds = serverCatalog.worlds

	if not worlds then
		print "Worlds have not been initialized!"
		return
	end

	if not worlds[1] then
		print "Worlds must be created before locations can be removed."
		return
	end

	if not worlds[1][locationName] then
		print "The location does not exist."
		return
	end

	for _, world in ipairs(worlds) do
		world[locationName] = nil
	end

	print "Pushing changes to the server catalog…"

	local setSuccess = SafeDataStore.safeSetAsync(universeData, "ServerCatalog", serverCatalog)

	if not setSuccess then
		print "Failed to push changes to the server catalog."
		return
	end

	print(("Location '%s' removed."):format(locationName))
end

function UniverseServerCatalogControlPanel.setWorldCount(count: number, force: true?)
	print "Setting the world count…"

	local getSuccess, serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

	if not getSuccess then
		print "Failed to retrieve the server catalog."
		return
	end

	if not serverCatalog then
		print "The server catalog has not been initialized!"
		return
	end

	local worlds = serverCatalog.worlds

	if not worlds then
		print "Worlds have not been initialized!"
		return
	end

	if not force and #worlds > count then
		print "The world count cannot be decreased unless the force flag is set."
		return
	end

	if #worlds == count then
		print "The world count is already set to the specified value."
	elseif #worlds > count then
		for i = count + 1, #worlds do
			worlds[i] = nil
		end

		print "Pushing changes to the server catalog…"

		local setSuccess = SafeDataStore.safeSetAsync(universeData, "ServerCatalog", serverCatalog)

		if not setSuccess then
			print "Failed to push changes to the server catalog."
			return
		end

		print(("The world count has been reduced to %d."):format(count))
	else
		local worldTemplate = worlds[1]

		for i = #worlds + 1, count do
			local world = {}

			if worldTemplate then
				for locationName, locationData in pairs(worldTemplate) do
					local location = {}
					world[locationName] = location

					location.placeId = locationData.placeId
				end
			end

			worlds[i] = world
		end

		while true do
			local reserveServerPromises = {}

			for i, world in ipairs(worlds) do
				for locationName, locationData in pairs(world) do
					if locationData.accessCode then continue end

					local reserveServerPromise = Promise.new(function(resolve, reject)
						local reserveSuccess, accessCode, privateServerId =
							SafeTeleport.safeReserveServerAsync(locationData.placeId)

						if not reserveSuccess then return reject() end

						locationData.accessCode = accessCode
						locationData.privateServerId = privateServerId

						return resolve()
					end)

					table.insert(reserveServerPromises, reserveServerPromise)
				end
			end

			local reserveServersSuccess = Promise.all(reserveServerPromises):await()

			if reserveServersSuccess then break end
		end

		print "Pushing changes to the server catalog…"

		local setSuccess = SafeDataStore.safeSetAsync(universeData, "ServerCatalog", serverCatalog)

		if not setSuccess then
			print "Failed to push changes to the server catalog."
			return
		end

		print(("The world count has been increased to %d."):format(count))
	end
end

return UniverseServerCatalogControlPanel
