local ServerStorage = game:GetService("ServerStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")

local serverStorageShared = ServerStorage.Shared
local utilityFolder = serverStorageShared.Utility

local DataStore = require(utilityFolder.DataStore)

local fingerprintMemoryStore = MemoryStoreService:GetSortedMap("ServerFingerprint")

local Fingerprint = {}

function Fingerprint.stamp(identifier, data)
    return DataStore.safeSet(fingerprintMemoryStore, identifier, data, 300)
end

function Fingerprint.trace(identifier)
    return DataStore.safeGet(fingerprintMemoryStore, identifier)
end

return Fingerprint