local REPLENISH_DELAY = 30
local MAX_CREDITS = 5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedStorageShared = ReplicatedStorage.Shared
local dataFolder = serverStorageShared.Data
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(serverStorageVendor.ReplicaService)
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)
local PlayerDataManager = require(dataFolder.PlayerDataManager)

--[[
    When a client requests someone's profile data and it is not cached, one credit will be used.
    One credit is replenished every REPLENISH_DELAY seconds until the player has MAX_CREDITS credits.
]]
local datastoreCredits = {
    -- [Player] = number
}

local profileDataRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ProfileDataRequest"),
    Replication = "All"
})

ReplicaResponse.listen(profileDataRequest, function(player, userId: number)
    if typeof(userId) ~= "number" then
        return false
    end

    local credits = datastoreCredits[player] or 0

    if PlayerDataManager.isDataCached(userId) then
        return true, PlayerDataManager.viewPlayerProfile(userId)
    end

    if credits <= 0 then
        return false
    end

    datastoreCredits[player] = credits - 1

    local profileData = PlayerDataManager.viewPlayerProfile(userId)

    return true, profileData
end)

while task.wait(REPLENISH_DELAY) do
    for player, credits in pairs(datastoreCredits) do
        if credits < MAX_CREDITS then
            datastoreCredits[player] = credits + 1
        end
    end
end
