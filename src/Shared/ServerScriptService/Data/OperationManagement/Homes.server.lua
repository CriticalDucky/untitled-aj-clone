local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

ClientServerCommunication.registerActionAsync("SetSelectedHome", function(player, homeId)
	local data = PlayerDataManager.viewPersistentData(player)
	assert(data)

	if not data.inventory.homes[homeId] then
		ClientServerCommunication.replicateAsync("SetSelectedHome", data.home.selected, player)
		return
	end

	PlayerDataManager.setValuePersistent(player, { "home", "selected" }, homeId)
end)
