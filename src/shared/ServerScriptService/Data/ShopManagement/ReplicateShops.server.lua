local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping

local ReplicaService = require(dataFolder.ReplicaService)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(shoppingFolder.Shops)

local shops = {}

for shopType, _ in pairs(ActiveShops) do
    local shop = Shops[shopType]
    if shop then
        shops[shopType] = shop
    end
end

ReplicaService.NewReplica({
    ReplicaService.NewClassToken("ActiveShops"),
    Data = shops,
    Replication = "All"
})