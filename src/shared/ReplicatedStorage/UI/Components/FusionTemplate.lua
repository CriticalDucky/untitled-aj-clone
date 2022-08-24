local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local ReplicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")

local UIFolder = ReplicatedStorageShared:WaitForChild("UI")
local Fusion = require(ReplicatedFirstShared:WaitForChild("Fusion"))

local Utility = ReplicatedStorageShared:WaitForChild("Utility")
local UIManagement = UIFolder:WaitForChild("UIManagement")
local Components = UIFolder:WaitForChild("Components")

local WaitForDescendant = require(Utility:WaitForChild("WaitForDescendant")) 

local Util = require(WaitForDescendant(Utility, "UIUtil"))

local Constants = require(UIManagement:WaitForChild("Constants"))
local Component = Util.Component
local CameraState = require(Utility:WaitForChild("CameraState"))

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