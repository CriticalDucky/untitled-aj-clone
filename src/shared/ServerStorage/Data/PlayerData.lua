local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local serverStorageSharedUtility = serverStorageShared.Utility
local serverStorageSharedData = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local ProfileService = require(serverStorageSharedUtility.ProfileService)
local ReplicaService = require(serverStorageSharedData.ReplicaService)
local ReplicationType = require(enumsFolder.ReplicationType)

local PROFILE_TEMPLATE = { -- Items in here can only be under a table
    currency = {
        money = 0,
    },

    inventory = {
        accessories = {},
        homeItems = {},
        homes = {},
    },
}

local PROFILE_REPLICATION = {
    [ReplicationType.private] = { -- private data is only sent to the client that owns the profile
        "currency",
        "inventory",
    },

    [ReplicationType.public] = { -- public data is replicated to everyone

    },
}

local TEMP_DATA_TEMPLATE do
    local function combineDictionaries(...)
        local result = {}
        for _, dictionary in ipairs({...}) do
            for key, value in pairs(dictionary) do
                result[key] = value
            end
        end
        return result
    end

    local dictionaries = {}

    for _, instance in ipairs(ServerStorage:GetDescendants()) do
        if instance:IsA("ModuleScript") and instance.Name == "TempDataTemplate" then
            table.insert(dictionaries, require(instance))
        end
    end

    TEMP_DATA_TEMPLATE = combineDictionaries(table.unpack(dictionaries))
end

local ProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    PROFILE_TEMPLATE
)

local playerDataCreationComplete = {}
local playerDataCollection = {}

local PlayerData = {}
PlayerData.__index = PlayerData

local function getReplicationType(index)
    for replicationType, keys in pairs(PROFILE_REPLICATION) do
        if table.find(keys, index) then
            return replicationType
        end
    end

    for key, value in pairs(TEMP_DATA_TEMPLATE) do
        if index == key then
            return value._replication
        end
    end

    return ReplicationType.server
end

local function deepCopy(value)
    if type(value) == "table" then
        local result = {}

        for key, value in pairs(value) do
            result[key] = deepCopy(value)
        end

        return result
    end

    return value
end

function PlayerData.new(player)
    local newPlayerData = setmetatable({}, PlayerData)
    newPlayerData.player = player

    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

    if profile then
        profile:AddUserId(player.UserId)
        profile:Reconcile()
        profile:ListenToRelease(function()
            playerDataCollection[player] = nil
            playerDataCreationComplete[player] = nil
        end)

        if player:IsDescendantOf(Players) then
            playerDataCollection[player] = newPlayerData
            local tempDataCopy = deepCopy(TEMP_DATA_TEMPLATE)

            local function getMatchingProfileProps(privacy)
                local matchingProps = {}
                for _, key in ipairs(PROFILE_REPLICATION[privacy]) do
                    matchingProps[key] = profile.Data[key]
                end
                return matchingProps
            end

            local function getMatchingTempDataProps(privacy)
                local matchingProps = {}
                for k, v in pairs(tempDataCopy) do
                    matchingProps[k] = v._replication == privacy and v or nil
                end
                return matchingProps
            end

            local function combineDictionaries(...)
                local result = {}
                for _, dictionary in ipairs({...}) do
                    for key, value in pairs(dictionary) do
                        result[key] = value
                    end
                end
                return result
            end

            local data_replicationPrivate = combineDictionaries(
                getMatchingProfileProps(ReplicationType.private),
                getMatchingTempDataProps(ReplicationType.private)
            )

            local data_replicationPublic = combineDictionaries(
                getMatchingProfileProps(ReplicationType.public),
                getMatchingTempDataProps(ReplicationType.public)
            )

            newPlayerData.profile = profile
            newPlayerData.tempData = tempDataCopy

            newPlayerData.replica_private = ReplicaService.NewReplica({
                ClassToken = ReplicaService.NewClassToken("PlayerDataPrivate_" .. player.UserId),
                Data = data_replicationPrivate,
                Replication = player
            })

            newPlayerData.replica_public = ReplicaService.NewReplica({
                ClassToken = ReplicaService.NewClassToken("PlayerDataPublic"),
                Data = {sender = player, data = data_replicationPublic},
                Replication = "All"
            })
        else
            profile:Release()
        end
    else 
        print("Failed to load profile for player " .. player.Name)
        -- TODO: Error handling
        return
    end

    return newPlayerData
end

function PlayerData:setValue(path: table, value)
    local replicationType = getReplicationType(path[1])

    if replicationType == ReplicationType.public then
        table.insert(path, 1, "data")

        self.replica_public:SetValue(path, value)
    elseif replicationType == ReplicationType.private then
        self.replica_private:SetValue(path, value)
    else
        local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

        for i = 1, #path - 1 do
            data = data[path[i]]
        end

        data[path[#path]] = value
    end
end

function PlayerData:setValues(path, values)
    local replicationType = getReplicationType(path[1])

    if replicationType == ReplicationType.public then
        table.insert(path, 1, "data")

        self.replica_public:SetValues(path, values)
    elseif replicationType == ReplicationType.private then
        self.replica_private:SetValues(path, values)
    else
        local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

        for i = 1, #path - 1 do
            data = data[path[i]]
        end

        for key, value in pairs(values) do
            data[path[#path]][key] = value
        end
    end
end

function PlayerData:arrayInsert(path, value)
    local replicationType = getReplicationType(path[1])

    if replicationType == ReplicationType.public then
        table.insert(path, 1, "data")

        self.replica_public:ArrayInsert(path, value)
    elseif replicationType == ReplicationType.private then
        self.replica_private:ArrayInsert(path, value)
    else
        local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

        for i = 1, #path - 1 do
            data = data[path[i]]
        end

        table.insert(data[path[#path]], value)
    end
end

function PlayerData:arraySet(path, index, value)
    local replicationType = getReplicationType(path[1])

    if replicationType == ReplicationType.public then
        table.insert(path, 1, "data")

        self.replica_public:ArraySet(path, index, value)
    elseif replicationType == ReplicationType.private then
        self.replica_private:ArraySet(path, index, value)
    else
        local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

        for i = 1, #path - 1 do
            data = data[path[i]]
        end

        data[path[#path]][index] = value
    end
end

function PlayerData:arrayRemove(path, index)
    local replicationType = getReplicationType(path[1])

    if replicationType == ReplicationType.public then
        table.insert(path, 1, "data")

        self.replica_public:ArrayInsert(path, index)
    elseif replicationType == ReplicationType.private then
        self.replica_private:ArrayRemove(path, index)
    else
        local data = if self.profile.Data[path[1]] then self.profile.Data else self.tempData

        for i = 1, #path - 1 do
            data = data[path[i]]
        end

        table.remove(data[path[#path]], index)
    end
end

local PlayerDataManager = {}

function PlayerDataManager.get(player, wait)
    local playerData = playerDataCollection[player]

    if playerData then
        return playerData
    elseif wait and playerDataCreationComplete then
        while not playerDataCreationComplete[player] do
            task.wait()
            playerData = playerDataCollection[player]
        end

        return playerData
    end
end

function PlayerDataManager.init(player)
    print("Initializing player data for " .. player.Name)

    PlayerData.new(player)
    playerDataCreationComplete[player] = true
end

function PlayerDataManager.yieldUntilHopReady(player)
    local playerData = PlayerDataManager.get(player)

    if playerData then
        local profile = playerData.profile
        profile:Release()

        local connection

        connection = profile:ListenToHopReady(function()
            connection:Disconnect()
            connection = nil
        end)

        while connection do
            task.wait()
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    local playerData = playerDataCollection[player]

    if playerData then
        playerData.profile:Release()
    end

    playerDataCreationComplete[player] = nil
end)

return PlayerDataManager