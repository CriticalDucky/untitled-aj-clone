local DATASTORE_MAX_RETRIES = 10

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")

local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))

local playerLocationDatastore = DataStoreService:GetDataStore("PlayerLocationData") 

local PlayerLocationData = {}

function PlayerLocationData.set(playerId)
    local function try()
        return pcall(function()
            return playerLocationDatastore:SetAsync(tostring(playerId), {
                serverType = LocalServerInfo.serverType,
                privateServerId = game.PrivateServerId
            })
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