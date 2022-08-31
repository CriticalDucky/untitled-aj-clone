local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local inventoryFolder = dataFolder.Inventory
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedStorageSharedData = replicatedStorageShared.Data
local enumsFolder = replicatedStorageShared.Enums

local ShopType = require(enumsFolder.ShopType)
local ShopItemStatus = require(replicatedStorageSharedData.ShopInfo.ShopItemStatus)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(shoppingFolder.Shops)
local PlayerData = require(dataFolder.PlayerData)
local InventoryManager = require(inventoryFolder.InventoryManager)
local Items = require(replicatedStorageSharedData.Inventory.Items)
local Currency = require(dataFolder.Currency.Currency)

local ShopManager = {}

function ShopManager.playerCanBuyItem(player, shopEnum, itemIndex)
    local shopInfoTable = Shops[shopEnum]
    local shopItem = shopInfoTable.Items[itemIndex]
    local itemInfo = Items[shopItem.itemType]

    local playerData = PlayerData.get(player)

    if not playerData then
        return false
    end

    if not ShopItemStatus.get(shopItem) then
        return false
    end

    if not Currency.has(player, itemInfo.currencyType, itemInfo.price) then
        return false
    end

    if not InventoryManager.isInventoryFull(player, shopItem.itemType, 1) then
        return false
    end

    return true
end

function ShopManager.purchaseShopItem(player, shopEnum, itemIndex)
    local shopInfoTable = Shops[shopEnum]
    local shopItem = shopInfoTable.items[itemIndex]

    local itemInfo = Items[shopItem.itemType]

    if ShopManager.playerCanBuyItem(player, shopEnum, itemIndex) then
        if InventoryManager.newItemInInventory(shopItem.itemType, shopItem.item, player) then
            return Currency.increment(player, itemInfo.priceCurrencyType, itemInfo.price)
        end
    end
end

return ShopManager
