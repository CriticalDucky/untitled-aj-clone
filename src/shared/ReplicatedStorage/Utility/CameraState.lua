local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UIFolder = ReplicatedStorage:WaitForChild("UI")
local Fusion = require(ReplicatedStorage:WaitForChild("Fusion"))

local Utility = ReplicatedStorage:WaitForChild("Utility")
local UIManagement = UIFolder:WaitForChild("UIManagement")
local Components = UIFolder:WaitForChild("Components")

local WaitForDescendant = require(Utility:WaitForChild("WaitForDescendant")) 

local Util = require(WaitForDescendant(Utility, "UIUtil"))

local Constants = require(UIManagement:WaitForChild("Constants"))
local Component = Util.Component

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

local cameraState = Value({})

local watchingProps = {
    "CFrame",
    "ViewportSize",
}

local function initCamera()
    local camera = workspace.CurrentCamera

    Hydrate(camera, {
        [OnEvent "Changed"] = function()
            local currentCameraState = cameraState:get()

            for _, v in pairs(watchingProps) do
                currentCameraState[v] = camera[v]
            end

            cameraState:set(currentCameraState)
        end
    })
end

workspace.Changed:Connect(function(property)
    if property == "CurrentCamera" and workspace.CurrentCamera and workspace.CurrentCamera.Parent then
        initCamera()
    end
end)

return cameraState