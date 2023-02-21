local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local PlaceItemRequestType = require(enumsFolder:WaitForChild "PlaceItemRequestType")
local Table = require(utilityFolder:WaitForChild "Table")
local Types = require(utilityFolder:WaitForChild "Types")

type UserEnum = Types.UserEnum

local PlaceItemRequest = ReplicaCollection.get "PlaceItemRequest"

local PlaceItem = {}

--[[
    Internal function for sending a request to the server.
]]
function PlaceItem._request(placeItemRequestType: UserEnum, info: { itemId: string, pivotCFrame: CFrame? })
	assert(
		Table.hasValue(PlaceItemRequestType, placeItemRequestType),
		"PlaceItem.request() called with invalid placeItemRequestType: " .. tostring(placeItemRequestType)
	)

	return PlaceItemRequest:andThen(function(PlaceItemRequest)
		return ReplicaRequest.new(PlaceItemRequest, placeItemRequestType, info)
	end)
end

--[[
    Sends a request to the server to place an item.
    Returns a promise that resolves when the item is placed.
]]
function PlaceItem.place(itemId: string, pivotCFrame: CFrame)
	return PlaceItem._request(PlaceItemRequestType.place, {
		itemId = itemId,
		pivotCFrame = pivotCFrame,
	})
end

--[[
    Sends a request to the server to remove an item.
    Returns a promise that resolves when the item is removed.
]]
function PlaceItem.remove(itemId: string)
	return PlaceItem._request(PlaceItemRequestType.remove, {
		itemId = itemId,
	})
end

return PlaceItem
