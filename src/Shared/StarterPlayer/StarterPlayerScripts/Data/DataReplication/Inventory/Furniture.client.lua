--#region Imports

-- Services

local ReplicatedStorage = game:GetService "ReplicatedStorage"

-- Source

local replicatedStorageSharedData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild "Data"

local ClientState = require(replicatedStorageSharedData:WaitForChild "ClientState")
local DataReplication = require(replicatedStorageSharedData:WaitForChild "DataReplication")

--#endregion

DataReplication.registerActionAsync(
	"SetFurniture",
	function(furniture) ClientState.inventory.furniture:set(furniture) end
)
