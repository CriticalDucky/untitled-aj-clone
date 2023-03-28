local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local replicatedShoppingFolder = replicatedStorageShared.Data.ShopInfo

local ReplicaService = require(dataFolder.ReplicaService)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(replicatedShoppingFolder.Shops)
local ShopManager = require(shoppingFolder.ShopManager)

local purchaseRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PurchaseRequest"),
    Replication = "All"
})

purchaseRequest:ConnectOnServerEvent(function(player, requestCode, shopEnum, itemIndex)
    local function requestIsValid()
        if not (shopEnum and itemIndex and type(requestCode) == "string") then
            warn("Invalid arguments")
            return false
        end

        if not ActiveShops[shopEnum] then
            warn("Shop is not active")
            return false
        end

        local shopInfo = Shops[shopEnum]
        local shopItem = shopInfo.items[itemIndex]

        if not shopItem then
            warn("Shop item does not exist")
            return false
        end

        if not ShopManager.playerCanBuyItem(player, shopEnum, itemIndex) then
            warn("Player cannot buy item")
            return false
        end

        return true
    end

    local function respond(success)
        purchaseRequest:FireClient(player, requestCode, success)
    end

    if requestIsValid() then
        respond(ShopManager.purchaseShopItem(player, shopEnum, itemIndex))
    else
        warn("Invalid request")
        respond(false)
    end
end)