local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local componentsFolder = replicatedFirstShared:WaitForChild("UI"):WaitForChild("Components")

local WaitForDescendant = require(utilityFolder:WaitForChild("WaitForDescendant"))

return function(Name)
    return require(WaitForDescendant(componentsFolder, Name))
end