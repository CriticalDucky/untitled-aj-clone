local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local DataReplication = require(ReplicatedStorage.Shared.Data.DataReplication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

DataReplication.registerActionAsync("SetSelectedHome", function(player, homeId)
	local data = PlayerDataManager.viewPersistentData(player)
	assert(data)

	if not data.inventory.homes[homeId] then
		DataReplication.replicateAsync("SetSelectedHome", data.home.selected, player)
		return
	end

	PlayerDataManager.setValuePersistent(player, { "home", "selected" }, homeId)
end)
