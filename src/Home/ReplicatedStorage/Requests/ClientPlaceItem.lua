local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ReplicaRequest = require(requestsFolder:WaitForChild("ReplicaRequest"))
local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local PlaceItemRequestType = require(enumsFolder:WaitForChild("PlaceItemRequestType"))
local Table = require(utilityFolder:WaitForChild("Table"))

local PlaceItemRequest = ReplicaCollection.get("PlaceItemRequest")

local PlaceItem = {}

function PlaceItem.request(placeItemRequestType, ...)
    assert(Table.hasValue(PlaceItemRequestType, placeItemRequestType), "PlaceItem.request() called with invalid placeItemRequestType: " .. tostring(placeItemRequestType))

    local response = ReplicaRequest.new(PlaceItemRequest, placeItemRequestType, ...)

    return response
end

function PlaceItem.place(itemId, pivotCFrame)
    return PlaceItem.request(PlaceItemRequestType.place, {
        itemId = itemId,
        pivotCFrame = pivotCFrame,
    })
end

function PlaceItem.remove(itemId)
    return PlaceItem.request(PlaceItemRequestType.remove, {
        itemId = itemId,
    })
end

return PlaceItem