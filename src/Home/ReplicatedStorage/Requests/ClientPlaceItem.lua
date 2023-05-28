--[[
	Provides a client-side interface for placing and removing items in a home.
	Will deem invalid requests that are not made by the home owner.
]]

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = replicatedStorageShared:WaitForChild "Utility"

local ReplicaRequest = require(requestsFolder:WaitForChild "ReplicaRequest")
local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")
local PlaceItemRequestType = require(enumsFolder:WaitForChild "PlaceItemRequestType")
local Table = require(utilityFolder:WaitForChild "Table")
local Types = require(utilityFolder:WaitForChild "Types")

type UserEnum = Types.UserEnum

local PlaceItem = {}

--[[
	Internal function for sending a request to the server.
]]
local function request(placeItemRequestType: UserEnum, info: { itemId: string, pivotCFrame: CFrame? })
	local placeItemRequestReplica = ReplicaCollection.waitForReplica "PlaceItemRequest"
	return unpack(ReplicaRequest.new(placeItemRequestReplica, placeItemRequestType, info))
end

--[[
	Sends a request to the server to place an item.
	Returns a promise that resolves when the item is placed.
]]
function PlaceItem.place(itemId: string, pivotCFrame: CFrame)
	return request(PlaceItemRequestType.place, {
		itemId = itemId,
		pivotCFrame = pivotCFrame,
	})
end

--[[
	Sends a request to the server to remove an item.
	Returns a promise that resolves when the item is removed.
]]
function PlaceItem.remove(itemId: string)
	return request(PlaceItemRequestType.remove, {
		itemId = itemId,
	})
end

return PlaceItem
