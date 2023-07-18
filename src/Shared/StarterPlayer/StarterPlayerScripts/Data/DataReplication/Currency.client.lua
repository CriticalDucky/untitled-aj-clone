--#region Imports

local ReplicatedStorage = game:GetService "ReplicatedStorage"

local ClientState = require(ReplicatedStorage.Shared.Data.ClientState)
local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)

--#endregion

DataReplication.registerActionAsync("SetMoney", function(amount) ClientState.currency.money:set(amount) end)
