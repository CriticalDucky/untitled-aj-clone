-- Helper functions for simple datastore requests for actions that don't require major wrappers like ProfileService

local DEBUG = true

local DATASTORE_MAX_RETRIES = 10

local Promise = require(game:GetService("ReplicatedFirst").Shared.Utility.Promise)

local DataStore = {}

-- Attempts to update the value in the specified key, automatically retrying if it fails.
--
-- Returns a `Promise` that either resolves with the results of `UpdateAsync()` or rejects with the error.
function DataStore.safeUpdate(dataStore: GlobalDataStore, key: string, transformFunction: (any) -> any)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")
	assert(typeof(transformFunction) == "function", "transformFunction must be a function")

	if DEBUG then print("DATASTORE: safeUpdate", key) end

	local function try()
		return Promise.try(function()
			return dataStore:UpdateAsync(key, transformFunction)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):catch(function(err)
		warn("Failed to update data store:", tostring(err))
		return Promise.reject(err)
	end)
end

-- Attempts to set the value in the specified key, automatically retrying if it fails.
--
-- Returns a `Promise` that either resolves with the results of `SetAsync()` or rejects with the error.
function DataStore.safeSet(
	dataStore: GlobalDataStore,
	key: string,
	value,
	userIds: { number }?,
	options: DataStoreSetOptions?
)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")
	assert(userIds == nil or typeof(userIds) == "table", "userIds must be a table")
	assert(
		options == nil or (typeof(options) == "Instance" and options:IsA "DataStoreSetOptions"),
		"options must be a DataStoreSetOptions"
	)

	if DEBUG then print("DATASTORE: safeSet", key) end

	local function try()
		return Promise.try(function()
			return dataStore:SetAsync(key, value, userIds, options)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):catch(function(err)
		warn("Failed to set data store:", tostring(err))
		return Promise.reject(err)
	end)
end

-- Attempts to get the value in the specified key, automatically retrying if it fails.
--
-- Returns a `Promise` that either resolves with the results of `GetAsync()` or rejects with the error.
function DataStore.safeGet(dataStore: GlobalDataStore, key: string)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")

	if DEBUG then print("DATASTORE: safeGet", key) end

	local function try()
		return Promise.try(function()
			return dataStore:GetAsync(key)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):catch(function(err)
		warn("Failed to get data store:", tostring(err))
		return Promise.reject(err)
	end)
end

-- Attempts to remove the value in the specified key, automatically retrying if it fails.
--
-- Returns a `Promise` that either resolves with the results of `RemoveAsync()` or rejects with the error.
function DataStore.safeRemove(dataStore: GlobalDataStore, key: string)
	assert(typeof(dataStore) == "Instance" and dataStore:IsA "GlobalDataStore", "dataStore must be a GlobalDataStore")
	assert(typeof(key) == "string", "key must be a string")

	if DEBUG then print("DATASTORE: safeRemove", key) end

	local function try()
		return Promise.try(function()
			return dataStore:RemoveAsync(key)
		end)
	end

	return Promise.retry(try, DATASTORE_MAX_RETRIES):catch(function(err)
		warn("Failed to remove data store:", tostring(err))
		return Promise.reject(err)
	end)
end

return DataStore
