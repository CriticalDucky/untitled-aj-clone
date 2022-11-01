local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")

local ClientPlayerData = require(replicatedStorageShared:WaitForChild("Data"):WaitForChild("ClientPlayerData"))
local ServerGroupEnum = require(replicatedStorageShared:WaitForChild("Enums"):WaitForChild("ServerGroup"))
local ServerTypeGroups = require(replicatedStorageShared:WaitForChild("Server"):WaitForChild("ServerTypeGroups"))

local LocalPlayerSettings = {}

function LocalPlayerSettings.getSetting(settingName)
    if not ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        local value = ClientPlayerData.getLocalPlayerData(true)

        if not value then
            return
        end

        local playerSettings = value:get().playerSettings

        return playerSettings and playerSettings[settingName]
    end
end

return LocalPlayerSettings