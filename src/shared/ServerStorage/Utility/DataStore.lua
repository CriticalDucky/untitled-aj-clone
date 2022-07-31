local DATASTORE_MAX_RETRIES = 10

local DataStore = {}

function DataStore.safeUpdate(dataStore, key, transformFunction)
    local function try()
        return pcall(function()
            return dataStore:UpdateAsync(key, transformFunction)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success = try()

        if success then
            return true
        end
    end

    warn("Failed to update data store")
    return false
end

function DataStore.safeSet(dataStore, key, value)
    local function try()
        return pcall(function()
            return dataStore:SetAsync(key, value)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success = try()

        if success then
            return true
        end
    end

    warn("Failed to set data store")
    return false
end

function DataStore.safeGet(dataStore, key)
    local function try()
        return pcall(function()
            return dataStore:GetAsync(key)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, data = try()

        if success then
            return data
        end
    end

    print("Failed to get data store")
    return
end

return DataStore