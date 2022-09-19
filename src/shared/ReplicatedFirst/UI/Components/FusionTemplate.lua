local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local ReplicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = ReplicatedFirstShared:WaitForChild("UI")
local UtilityFolder = ReplicatedFirstShared:WaitForChild("Utility")

local Component = require(UtilityFolder:WaitForChild("GetComponent"))
local Fusion = require(ReplicatedFirstShared:WaitForChild("Fusion"))

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local component = function(props)
	
end

return component