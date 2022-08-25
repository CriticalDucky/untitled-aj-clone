local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local inventoryFolder = dataFolder.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
local enumsFolder = replicatedStorageShared.Enums

local ShopType = require(enumsFolder.ShopType)
local ShopItemStatus = require(replicatedStorageShared.Data.ShopInfo.ShopItemStatus)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(shoppingFolder.Shops)

local ShopManager = {}

function ShopManager.purchaseItem(player, shop, itemIndex)
    if not (shop and ShopType[shop] and ActiveShops[shop]) then
        warn("Shop must be a valid shop type")
        return
    end
    
    if not (itemIndex and Shops[ActiveShops[shop]][itemIndex]) then
        warn("Item must be a valid item")
        return
    end
    
    local isForSale = ShopItemStatus.get(itemIndex)

    
end

return ShopManager

