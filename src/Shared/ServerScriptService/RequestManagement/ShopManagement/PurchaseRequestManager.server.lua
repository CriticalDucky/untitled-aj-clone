local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local serverStorageShared = ServerStorage.Shared
local serverStorageVendor = ServerStorage.Vendor
local replicatedStorageShared = ReplicatedStorage.Shared
local dataFolder = serverStorageShared.Data
local shoppingFolder = dataFolder.Shopping
local replicatedShoppingFolder = replicatedStorageShared.Data.ShopInfo
local enumsFolder = replicatedStorageShared.Enums
local utilityFolder = replicatedStorageShared.Utility
local serverStorageSharedUtility = serverStorageShared.Utility

local ReplicaService = require(serverStorageVendor.ReplicaService)
local ActiveShops = require(shoppingFolder.ActiveShops)
local Shops = require(replicatedShoppingFolder.Shops)
local ShopManager = require(shoppingFolder.ShopManager)
local PurchaseResponseType = require(enumsFolder:WaitForChild "PurchaseResponseType")
local Param = require(utilityFolder:WaitForChild "Param")
local ReplicaResponse = require(serverStorageSharedUtility.ReplicaResponse)

local purchaseRequest = ReplicaService.NewReplica {
	ClassToken = ReplicaService.NewClassToken "PurchaseRequest",
	Replication = "All",
}

ReplicaResponse.listen(purchaseRequest, function(player, shopEnum: string, itemIndex: number)
	if not Param.expect({ shopEnum, "string" }, { itemIndex, "number" }) then
		warn "PurchaseRequestManager: Invalid arguments"

		return false, PurchaseResponseType.invalid
	end

	if not ActiveShops[shopEnum] then
		warn "PurchaseRequestManager: Shop is not active"

		return false, PurchaseResponseType.invalid
	end

	local shopInfo = Shops[shopEnum]
	local shopItem = shopInfo.items[itemIndex]

	if not shopItem then
		warn "PurchaseRequestManager: Shop item does not exist"

		return false, PurchaseResponseType.invalid
	end

	local canBuy, result = ShopManager.canPlayerBuyItem(player, shopEnum, itemIndex)

	if not canBuy then
		warn "PurchaseRequestManager: Player cannot buy item"

		return false, result
	end

	local success, result = ShopManager.purchaseShopItem(player, shopEnum, itemIndex)

	if not success then
		warn "PurchaseRequestManager: Player cannot buy item"

		return false, result
	end

	return true, result
end)