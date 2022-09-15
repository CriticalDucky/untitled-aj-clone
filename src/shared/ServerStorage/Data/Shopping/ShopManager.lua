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
    local shopItem = shopInfoTable.items[itemIndex]
    local itemInfo = Items[shopItem.itemType][shopItem.item]

    local playerData = PlayerData.get(player)

    if not playerData then
        warn("Player data not found")
        return false
    end

    if not ShopItemStatus.get(shopItem) then
        warn("Shop item is not available")
        return false
    end

    if not Currency.has(player, itemInfo.priceCurrencyType, itemInfo.price) then
        warn("Player does not have enough currency")
        return false
    end

    if InventoryManager.isInventoryFull(player, shopItem.itemType, 1) then
        warn("Player inventory is full")
        return false
    end

    return true
end

function ShopManager.purchaseShopItem(player, shopEnum, itemIndex)
    local shopInfoTable = Shops[shopEnum]
    local shopItem = shopInfoTable.items[itemIndex]

    local itemInfo = Items[shopItem.itemType][shopItem.item]

    if ShopManager.playerCanBuyItem(player, shopEnum, itemIndex) then
        if InventoryManager.newItemInInventory(shopItem.itemType, shopItem.item, player) then
            if Currency.increment(player, itemInfo.priceCurrencyType, -itemInfo.price) then
                return true
            else
                warn("Failed to increment currency")
            end
        else
            warn("Failed to add item to inventory")
        end
    else
        warn("Player cannot buy item")
    end
end

return ShopManager
