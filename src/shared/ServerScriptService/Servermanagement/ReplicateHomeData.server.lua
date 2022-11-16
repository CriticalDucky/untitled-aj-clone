local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local serverStorageShared = ServerStorage.Shared
local serverManagementFolder = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local GameServerData = require(serverManagementFolder.GameServerData)
local ReplicaService = require(dataFolder.ReplicaService)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(replicatedStorageShared.Server.ServerTypeGroups)

local homes = {}

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

for playerId, serverInfo in pairs(GameServerData.getHomeServers()) do
    homes[tostring(playerId)] = {
        serverInfo = filterServerInfo(serverInfo),
    }
end

local homeDataReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("HomeServers"),
    Data = homes,
    Replication = "All"
})

GameServerData.ServerInfoUpdated:Connect(function(serverType, indexInfo, serverInfo)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, serverType) then
        local userId = indexInfo.userId
        
        if not homeDataReplica.Data[userId] then
            homeDataReplica:SetValue({tostring(userId)}, {
                serverInfo = filterServerInfo(serverInfo),
            })
        else
            homeDataReplica:SetValue({tostring(userId), "serverInfo"}, filterServerInfo(serverInfo))
        end
    end
end)