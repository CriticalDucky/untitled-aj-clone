local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local serverManagementFolder = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local GameServerData = require(serverManagementFolder.GameServerData)
local ReplicaService = require(dataFolder.ReplicaService)
local PartyTypeEnum = require(enumsFolder.PartyType)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(replicatedStorageShared.Server.ServerTypeGroups)

local parties = {}

local function filterServerInfo(serverInfo)
    if not serverInfo then
        return nil
    end

    local newTable = {}

    for key, value in pairs(serverInfo) do
        if key == "players" then
            newTable[key] = #value

            continue
        end

        newTable[key] = value
    end

    return newTable
end

for _, partyType in pairs(PartyTypeEnum) do
    parties[partyType] = {}
end

for partyType, partyTypeData in pairs(GameServerData.getPartyServers()) do
    local t = parties[partyType]
    parties[partyType] = t or {}
    t = parties[partyType]


    for privateServerId, serverInfo in pairs(partyTypeData) do
        t[privateServerId] = {
            serverInfo = filterServerInfo(serverInfo),
        }
    end
end

local partyDataReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("Parties"),
    Data = parties,
    Replication = "All"
})

GameServerData.ServerInfoUpdated:Connect(function(serverType, indexInfo, serverInfo)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, serverType) then
        local partyType = indexInfo.partyType
        local privateServerId = indexInfo.privateServerId
        
        if not partyDataReplica.Data[partyType][privateServerId] then
            partyDataReplica:SetValue({partyType, privateServerId}, {
                serverInfo = filterServerInfo(serverInfo),
            })
        else
            partyDataReplica:SetValue({partyType, privateServerId, serverInfo}, filterServerInfo(serverInfo))
        end
    end
end)