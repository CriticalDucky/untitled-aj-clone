--[[
	STRUCTURE OF THIS MODULE

	This module allows access to submodules that manage specific parts of the player's state.

	Each state submodule has getters and setters for states in their respective categories.

	The client's copy of the player's state is stored in the `StateClient` submodule. The server's copy of the player's
	state is stored in the separate `PlayerDataManager` module. The `StateReplication` remote event is used for
	replicating state changes.
]]

--#region Imports

local Currency = require(script.Currency)
local Settings = require(script.Settings)

--#endregion

--[[
    Manages the player's state.
]]
local PlayerState = {}

PlayerState.currency = Currency

PlayerState.settings = Settings

return PlayerState
