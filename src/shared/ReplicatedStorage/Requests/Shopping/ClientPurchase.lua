local REQUEST_TIMEOUT = 10

local HttpService = game:GetService "HttpService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local dataFolder = replicatedStorageShared:WaitForChild "Data"
local shopInfoFolder = dataFolder:WaitForChild "ShopInfo"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"

local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local ResponseType = require(enumsFolder:WaitForChild "ResponseType")
local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local Shops = require(shopInfoFolder:WaitForChild "Shops")

local Purchase = {}

function Purchase.request(shopEnum, itemIndex)
	assert(shopEnum and Shops[shopEnum], "shop must be a valid shop type")
	assert(itemIndex and Shops[shopEnum].items[itemIndex], "item must be a valid item")

	return ReplicaCollection.get("PurchaseRequest", true):andThen(function(purchaseRequest)
		return ReplicaRequest.new(purchaseRequest, shopEnum, itemIndex)
	end)
end

return Purchase
