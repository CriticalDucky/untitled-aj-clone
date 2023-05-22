--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Ref = Fusion.Ref
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup
local Out = Fusion.Out
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Attribute = Fusion.Attribute
local AttributeChange = Fusion.AttributeChange
local AttributeOut = Fusion.AttributeOut
local Value = Fusion.Value
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local ForKeys = Fusion.ForKeys
local ForValues = Fusion.ForValues
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local peek = Fusion.peek
local cleanup = Fusion.cleanup
local doNothing = Fusion.doNothing

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	-- Default props
	CornerRadius: CanBeState<number>?,
    Color: CanBeState<Color3>?,
}

--[[
	This component creates a round corner mask for scrolling frames.
    This is a workaround for using a canvas group to round scolling frame corners.
    I generally want to avoid using canvas groups because they can cause issues with
    memory usage and have the chance to not render or lose resolution.

    To use, create this component as a sibling to the scrolling frame you want to mask.
]]
local function Component(props: Props)
    local rounderImageId = "rbxassetid://8657765392"

    local cornerRadius = props.CornerRadius or 8
    local color = props.Color or Color3.new(1, 1, 1)

    local ZIndex = 10000000

    return {
        New "ImageLabel" {
            AnchorPoint = Vector2.new(0, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 0),
            Size = UDim2.fromOffset(cornerRadius, cornerRadius),
            Image = rounderImageId,
            ImageColor3 = color,
            ImageRectSize = Vector2.new(128, 128),
            ImageRectOffset = Vector2.new(0, 0),
            ZIndex = ZIndex,
        },

        New "ImageLabel" {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(cornerRadius, cornerRadius),
            Image = rounderImageId,
            ImageColor3 = color,
            ImageRectSize = Vector2.new(128, 128),
            ImageRectOffset = Vector2.new(128, 0),
            ZIndex = ZIndex,
        },

        New "ImageLabel" {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromOffset(cornerRadius, cornerRadius),
            Image = rounderImageId,
            ImageColor3 = color,
            ImageRectSize = Vector2.new(128, 128),
            ImageRectOffset = Vector2.new(0, 128),
            ZIndex = ZIndex,
        },

        New "ImageLabel" {
            AnchorPoint = Vector2.new(1, 1),
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(cornerRadius, cornerRadius),
            Image = rounderImageId,
            ImageColor3 = color,
            ImageRectSize = Vector2.new(128, 128),
            ImageRectOffset = Vector2.new(128, 128),
            ZIndex = ZIndex,
        },
    }
end

return Component
