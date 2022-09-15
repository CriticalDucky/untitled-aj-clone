local DATASTORE_MAX_RETRIES = 10

local DataStore = {}

function DataStore.safeUpdate(dataStore, key, transformFunction)
    print("DATASTORE: safeUpdate")

    local possibleError

    local function try()
        return pcall(function()
            return dataStore:UpdateAsync(key, transformFunction)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, err = try()

        possibleError = err

        if success then
            return true
        end
    end

    warn("Failed to update data store", possibleError)
    return false
end

function DataStore.safeSet(dataStore, key, value)
    print("DATASTORE: safeSet")

    local possibleError

    local function try()
        return pcall(function()
            return dataStore:SetAsync(key, value)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, err = try()

        possibleError = err

        if success then
            return true
        end
    end

    warn("Failed to set data store", possibleError)
    return false
end

function DataStore.safeGet(dataStore, key)
    print("DATASTORE: safeGet")

    local possibleError

    local function try()
        return pcall(function()
            return dataStore:GetAsync(key)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, data = try()

        possibleError = data

        if success then
            return data
        end
    end

    print("Failed to get data store", possibleError)
    return
end

function DataStore.safeRemove(dataStore, key)
    print("DATASTORE: safeRemove")

    local possibleError

    local function try()
        return pcall(function()
            return dataStore:RemoveAsync(key)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, err = try()

        possibleError = err

        if success then
            return true
        end
    end

    warn("Failed to remove data store", possibleError)
    return false
end

return DataStore