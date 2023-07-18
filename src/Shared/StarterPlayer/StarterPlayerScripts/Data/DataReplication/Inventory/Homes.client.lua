--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientState = require(ReplicatedStorage.Shared.Data.ClientState)
local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync("SetHomes", function(homes) ClientState.inventory.homes:set(homes) end)
