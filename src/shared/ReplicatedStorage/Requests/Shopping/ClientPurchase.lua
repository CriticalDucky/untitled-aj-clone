local REQUEST_TIMEOUT = 10

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
local PurchaseResponseType = require(enumsFolder:WaitForChild("PurchaseResponseType"))

local Purchase = {}

function Purchase.request(shopEnum, itemIndex)
    assert(shopEnum and ShopType[shopEnum] and ActiveShops[shopEnum], "shop must be a valid shop type")
    assert(itemIndex and ActiveShops[shopEnum][itemIndex], "item must be a valid item")

    local PurchaseRequest = ReplicaCollection.get("PurchaseRequest")
    local PurchaseResponse = ReplicaCollection.get("PurchaseResponse")

    if not PurchaseRequest or not PurchaseResponse then
        return
    end

    local isForSale = ShopItemStatus.get(itemIndex)

    if not isForSale then
        return
    end

    local requestCode = HttpService:GenerateGUID(false)

    PurchaseRequest:FireServer(shopEnum, itemIndex, requestCode)

    local response

    local connection do
        connection = PurchaseResponse:ConnectOnClientEvent(function(requestCode, success)
            if requestCode == requestCode then
                connection:Disconnect()
                
                if success then
                    response = PurchaseResponseType.success
                else
                    response = PurchaseResponseType.failure
                end
            end
        end) 
    end

    local startTime = time()

    while not response do
        task.wait()

        if time() - startTime > REQUEST_TIMEOUT then
            connection:Disconnect()
            response = PurchaseResponseType.timeout

            break
        end
    end

    return response
end

return Purchase