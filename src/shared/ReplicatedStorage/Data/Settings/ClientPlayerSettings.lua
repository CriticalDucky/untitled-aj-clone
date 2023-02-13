local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local Types = require(utilityFolder:WaitForChild("Types"))

type LocalPlayerParam = Types.LocalPlayerParam

local ClientPlayerSettings = {}

function ClientPlayerSettings.getSetting(settingName: string, playerParam: LocalPlayerParam)
	local data = ClientPlayerData.getData(playerParam)

	if not data then
		return
	end

	data = data:get()

	return data and data.playerSettings and data.playerSettings[settingName]
end

function ClientPlayerSettings.promiseSetting(settingName: string, playerParam: LocalPlayerParam)
	return ClientPlayerData.promiseData(playerParam):andThen(function(data)
		local playerSettings = data.playerSettings

		return playerSettings and playerSettings[settingName]
	end)
end

return ClientPlayerSettings