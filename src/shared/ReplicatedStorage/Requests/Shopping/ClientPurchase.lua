local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local shopInfoFolder = dataFolder:WaitForChild("ShopInfo")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ActiveShops = require(shopInfoFolder:WaitForChild("ActiveShopsClient"))
local ShopItemStatus = require(shopInfoFolder:WaitForChild("ShopItemStatus"))
local ShopType = require(enumsFolder:WaitForChild("ShopType"))

local Purchase = {}

function Purchase.request(shop, itemIndex)
    assert(shop and ShopType[shop] and ActiveShops[shop], "shop must be a valid shop type")
    assert(itemIndex and ActiveShops[shop][itemIndex], "item must be a valid item")

    local PurchaseRequest = ReplicaCollection.get("PurchaseRequest")

    if not PurchaseRequest then
        return
    end

    local isForSale = ShopItemStatus.get(itemIndex)

    if not isForSale then
        return
    end

    PurchaseRequest:FireServer(shop, itemIndex, HttpService:GenerateGUID())
end

return Purchase