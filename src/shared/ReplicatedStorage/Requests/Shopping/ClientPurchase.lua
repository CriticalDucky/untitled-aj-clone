local REQUEST_TIMEOUT = 10

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local shopInfoFolder = dataFolder:WaitForChild("ShopInfo")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local ActiveShops = require(shopInfoFolder:WaitForChild("ActiveShopsClient"))
local ShopItemStatus = require(shopInfoFolder:WaitForChild("ShopItemStatus"))
local PurchaseResponseType = require(enumsFolder:WaitForChild("PurchaseResponseType"))
local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))

local Purchase = {}

function Purchase.request(shopEnum, itemIndex)
    assert(shopEnum and ActiveShops[shopEnum], "shop must be a valid shop type")
    assert(itemIndex and ActiveShops[shopEnum].items[itemIndex], "item must be a valid item")

    local PurchaseRequest = ReplicaCollection.get("PurchaseRequest")

    if not PurchaseRequest then
        warn("PurchaseRequest not found")
        return
    end

    local item = ActiveShops[shopEnum].items[itemIndex]
    local isForSale = ShopItemStatus.get(item)

    if not isForSale then
        warn("Item is not for sale")
        return
    end

    return ReplicaRequest.new(PurchaseRequest, shopEnum, itemIndex) or PurchaseResponseType.timeout
end

return Purchase