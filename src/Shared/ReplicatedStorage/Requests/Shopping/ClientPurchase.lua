local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local shopInfoFolder = dataFolder:WaitForChild "ShopInfo"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local Shops = require(shopInfoFolder:WaitForChild "Shops")

local ClientPurchase = {}

function ClientPurchase.request(shopEnum, itemIndex)
	assert(shopEnum and Shops[shopEnum], "shop must be a valid shop type")
	assert(itemIndex and Shops[shopEnum].items[itemIndex], "item must be a valid item")

	local purchaseRequestReplica = ReplicaCollection.get("PurchaseRequest")

	return ReplicaRequest.new(purchaseRequestReplica, shopEnum, itemIndex)
end

return ClientPurchase
