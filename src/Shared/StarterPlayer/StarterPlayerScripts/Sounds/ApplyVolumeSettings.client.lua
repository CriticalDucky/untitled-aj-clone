local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local SoundService = game:GetService "SoundService"

local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")

local Computed = Fusion.Computed
local Hydrate = Fusion.Hydrate

local ClientPlayerSettings =
	require(replicatedStorageShared:WaitForChild("Data"):WaitForChild("Settings"):WaitForChild "ClientPlayerSettings")

local musicVolume = Computed(function(use)
	return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "musicVolume")
end)

local sfxVolume = Computed(function(use)
	return ClientPlayerSettings.withData.getSetting(use(ClientPlayerSettings.value), "sfxVolume")
end)

Hydrate(SoundService:WaitForChild "Music") {
	Volume = musicVolume,
}

Hydrate(SoundService:WaitForChild "SFX") {
	Volume = sfxVolume,
}
