--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedStorageShared:WaitForChild "Utility"
local componentsFolder = replicatedStorageShared:WaitForChild("Interface"):WaitForChild "Components"
local constantsFolder = replicatedStorageShared:WaitForChild "Constants"

local InterfaceConstants = require(constantsFolder:WaitForChild "InterfaceConstants")

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children

type CanBeState<T> = Fusion.CanBeState<T>
-- #endregion

export type Props = {
	-- Default props
	Name: CanBeState<string>?,
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	ZIndex: CanBeState<number>?,

    -- Custom props
    Text: CanBeState<string>?,
    TextOutlineColor: CanBeState<Color3>?,
    TextColor: CanBeState<Color3>?,
    FontFace: CanBeState<Font>?,
    TextSize: CanBeState<Enum.FontSize>?,
    LineJoinMode: CanBeState<Enum.LineJoinMode>?,
    Thickness: CanBeState<number>?, -- Default 7
}

--[[
	This component creates a 3D bubble text using UIStroke.
    Size is automatically calculated based on the text and font size.
    Make sure you do not care about the size of the bubble text.
]]
local function Component(props: Props)
    local fontFace = props.FontFace or InterfaceConstants.fonts.thickTitle.font
    local textSize = props.TextSize or InterfaceConstants.fonts.thickTitle.size

    local outerTextLabel = New "TextLabel" {
        Name = props.Name,
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        ZIndex = props.ZIndex,
        AutomaticSize = Enum.AutomaticSize.XY,

        Text = props.Text,
        FontFace = fontFace,
        TextSize = textSize,
        TextColor3 = props.TextOutlineColor,
        BackgroundTransparency = 1,

        [Children] = {
            New "UIStroke" {
                Color = props.TextOutlineColor,
                LineJoinMode = props.LineJoinMode,
                Thickness = props.Thickness or 7,
            },

            New "TextLabel" {
                Name = "Inner",
                Size = UDim2.fromScale(1, 1),
                -- Position = UDim2.fromOffset(0, -5),
                BackgroundTransparency = 1,
                Text = props.Text,
                FontFace = fontFace,
                TextSize = textSize,
                TextColor3 = props.TextColor,

                [Children] = {
                    New "UIPadding" {
                        PaddingBottom = UDim.new(0, 5),
                    }
                }
            },
        }
    }

    return outerTextLabel
end

return Component
