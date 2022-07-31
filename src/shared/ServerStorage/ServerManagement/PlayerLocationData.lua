local DATASTORE_MAX_RETRIES = 10

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

local playerLocationDatastore = DataStoreService:GetDataStore("PlayerLocationData") 

local PlayerLocationData = {}

function PlayerLocationData.set(playerId)
    local function try()
        return pcall(function()
            local data do
                local serverType = LocalServerInfo.serverType

                data = {
                    serverType = serverType
                }

                if serverType == ServerTypeEnum.location then
                    local serverStorageLocation = ServerStorage:WaitForChild("Location")
                    local serverManagementLocation = serverStorageLocation:WaitForChild("ServerManagement")
                    local LocalWorldInfo = require(serverManagementLocation:WaitForChild("LocalWorldInfo"))

                    data.worldIndex = LocalWorldInfo.worldIndex
                    data.locationEnum = LocalWorldInfo.locationEnum
                end
            end

            return playerLocationDatastore:SetAsync(tostring(playerId), data)
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success = try()

        if success then
            return true
        end
    end
end

function PlayerLocationData.get(playerId)
    local function try()
        return pcall(function()
            return playerLocationDatastore:GetAsync(tostring(playerId))
        end)
    end

    for _ = 1, DATASTORE_MAX_RETRIES do
        local success, playerLocation = try()

        if success then
            return playerLocation
        end
    end
end

local function playerAdded(player)
    PlayerLocationData.set(player.UserId)
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)

return PlayerLocationData