local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping

local ReplicaService = require(dataFolder.ReplicaService)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(shoppingFolder.Shops)
local ShopItemStatus = require(replicatedStorageShared.Data.ShopInfo.ShopItemStatus)
local ShopManager = require(shoppingFolder.ShopManager)
local PlayerData = require(dataFolder.PlayerData)

local purchaseRequest = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PurchaseRequest"),
})

local purchaseResponse = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("PurchaseResponse"),
})

purchaseRequest:ConnectOnServerEvent(function(player, shopEnum, itemIndex, requestCode) -- Player will always be valid
    local function requestIsValid()
        if not (shopEnum and itemIndex and type(requestCode) == "string") then
            return false
        end

        if not ActiveShops[shopEnum] then
            return false
        end

        local shopInfo = Shops[shopEnum]
        local shopItem = shopInfo.items[itemIndex]

        if not shopItem then
            return false
        end

        if not ShopManager.playerCanBuyItem(player, shopEnum, itemIndex) then
            return false
        end

        return true
    end

    local function respond(success)
        purchaseResponse:FireClient(player, requestCode, success)
    end

    if requestIsValid() then
        respond(ShopManager.purchaseShopItem(player, shopEnum, itemIndex))
    else
        respond(false)
    end
end)