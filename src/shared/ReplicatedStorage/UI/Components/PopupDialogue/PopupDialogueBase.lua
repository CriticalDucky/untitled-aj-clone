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
    local position = props.position
    local size = props.size

    local worldPosition = props.worldPosition

    local visible = Computed(function()
        local cameraState = CameraState:get()

        local guiSize: UDim2 = unwrap(size)
        local guiSizeX = guiSize.X.Offset
        local guiSizeY = guiSize.Y.Offset
        
        local guiPosition: UDim2 = unwrap(position)
        local guiPositionX = guiPosition.X.Offset
        local guiPositionY = guiPosition.Y.Offset
    end)

    local frame = New "Frame" {
        --AnchorPoint = anchorPoint,
        Position = position,
        Size = size,

        BackgroundTransparency = 1,

        [Children] = {
            props.Children
        }
    }

    return frame
end

return component