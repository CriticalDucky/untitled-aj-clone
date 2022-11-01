local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = replicatedFirstShared:WaitForChild("UI")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local Component = require(utilityFolder:WaitForChild("GetComponent"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))

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
	local state = props.value

    local button = New "TextButton" {
        Size = UDim2.fromOffset(30, 30),
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(1, 10, 0, 0),
        Visible = true,

        Text = "X",
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,

        [OnEvent "MouseButton1Down"] = function()
            state:set(false)
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(1, 0),
            },
        }
    }

    return button
end

return component