local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage.Shared
local serverManagementFolder = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local GameServerData = require(serverManagementFolder.GameServerData)
local ReplicaService = require(dataFolder.ReplicaService)
local ServerTypeEnum = require(enumsFolder.ServerType)

local gameServerDataReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("WorldFillData"),
    Data = {
        ServerInfo = GameServerData.get(),
    },
    Replication = "All"
})

local function filterServerInfo(serverInfo)
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

GameServerData.ServerInfoUpdated:Connect(function(serverType, indexInfo, serverInfo)
    if serverType == ServerTypeEnum.location then
        gameServerDataReplica.Data.ServerInfo = filterServerInfo(serverInfo)
    end
end)



