--!strict

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ReplicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"

local ClientState = require(ReplicatedStorageShared:WaitForChild("Data"):WaitForChild "ClientState")
local DataReplication = require(ReplicatedStorageShared:WaitForChild("Data"):WaitForChild "DataReplication")

DataReplication.registerActionAsync(
	"SetSelectedHome",
	function(homeId: string) ClientState.home.selected:set(homeId) end
)
