local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local utilityFolder = ReplicatedFirst:WaitForChild("Shared"):WaitForChild "Utility"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"

local WaitForDescendant = require(utilityFolder:WaitForChild "WaitForDescendant")

return function(Name) return require(WaitForDescendant(componentsFolder, Name)) end
