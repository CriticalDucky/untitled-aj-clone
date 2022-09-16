local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")


return function(Name)
    return require(WaitForDescendant(Components, Name))
end