local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local serverManagement = serverStorageShared.ServerManagement
local dataFolder = serverStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local LocalServerInfo = require(serverManagement.LocalServerInfo)
local ServerTypeEnum = require(enumsFolder.ServerType)

if LocalServerInfo.serverType ~= ServerTypeEnum.routing then
    local PlayerData = require(dataFolder.PlayerData)
    local InventoryManager = require(dataFolder.Inventory.InventoryManager)

    local function playerAdded(player)
        PlayerData.init(player)

        InventoryManager.reconcileInventory(player)
    end

    for _, player in pairs(Players:GetPlayers()) do
        playerAdded(player)
    end

    Players.PlayerAdded:Connect(playerAdded)
end