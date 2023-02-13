local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local ServerGroupEnum = require(enumsFolder:WaitForChild("ServerGroup"))
local ServerTypeGroups = require(serverFolder:WaitForChild("ServerTypeGroups"))
local Promise = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Promise"))
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild("ClientTeleport"))

if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
    local function playerAdded(player)
        Promise.try(function()
            ClientPlayerData.add(player)
        end):catch(function()
            ClientTeleport.rejoin()
        end)
        
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end
    
    Players.PlayerAdded:Connect(playerAdded)
end