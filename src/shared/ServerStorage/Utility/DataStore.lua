-- Helper functions for simple datastore requests for actions that don't require major wrappers like ProfileService

local DATASTORE_MAX_RETRIES = 10

local Promise = require(game:GetService("ReplicatedFirst").Shared.Utility.Promise)

local DataStore = {}

function DataStore.safeUpdate(dataStore, key, transformFunction, extra)
    print("DATASTORE: safeUpdate", key)

    local function try()
        return Promise.try(function()
            return dataStore:UpdateAsync(key, transformFunction, extra)
        end)
    end

    return Promise.retry(try, DATASTORE_MAX_RETRIES)
        :catch(function(err)
            warn("Failed to update data store:", tostring(err))
            return Promise.reject(err)
        end)
end

function DataStore.safeSet(dataStore, key, value, extra)
    print("DATASTORE: safeSet", key)

    local function try()
        return Promise.try(function()
            return dataStore:SetAsync(key, value, extra)
        end)
    end

    return Promise.retry(try, DATASTORE_MAX_RETRIES)
        :catch(function(err)
            warn("Failed to set data store:", tostring(err))
            return Promise.reject(err)
        end)
end

function DataStore.safeGet(dataStore, key, extra)
    print("DATASTORE: safeGet", key)

    Promise.resolve()
    :andThen(function()
        return Promise.reject()
    end)

    Promise.new(function(resolve, reject)
        resolve()
    end):andThen(function()
        return Promise.reject()
    end)

    local function try()
        return Promise.try(function()
            return dataStore:GetAsync(key, extra)
        end)
    end

    return Promise.retry(try, DATASTORE_MAX_RETRIES)
        :catch(function(err)
            warn("Failed to get data store:", tostring(err))
            return Promise.reject(err)
        end)
end

function DataStore.safeRemove(dataStore, key, extra)
    print("DATASTORE: safeRemove", key)

    local function try()
        return Promise.try(function()
            return dataStore:RemoveAsync(key, extra)
        end)
    end

    return Promise.retry(try, DATASTORE_MAX_RETRIES)
        :catch(function(err)
            warn("Failed to remove data store:", tostring(err))
            return Promise.reject(err)
        end)
end

return DataStore