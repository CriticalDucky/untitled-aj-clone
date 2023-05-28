local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local utilityFolder = replicatedStorageShared:WaitForChild("Utility")
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild("Components")

local WaitForDescendant = require(utilityFolder:WaitForChild("WaitForDescendant"))

return function(Name)
    return require(WaitForDescendant(componentsFolder, Name))
end