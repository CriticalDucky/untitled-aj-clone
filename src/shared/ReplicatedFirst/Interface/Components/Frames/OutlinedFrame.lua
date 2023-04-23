local MARGIN = 4
local DEFUALT_PADDING = 40
local DEFUALT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

--#region Imports
local PolicyService = game:GetService "PolicyService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"
local settingsFolder = replicatedFirstShared:WaitForChild "Settings"

local InterfaceConstants = require(settingsFolder:WaitForChild "InterfaceConstants")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Ref = Fusion.Ref
local Children = Fusion.Children
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

---@diagnostic disable-next-line: undefined-type wtf
type CanBeState<T> = Fusion.CanBeState<T>
type Child = Fusion.Child
-- #endregion

export type Props = {
	-- Default props
	Name: CanBeState<string>?,
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	Size: CanBeState<UDim2>?,
	AutomaticSize: CanBeState<Enum.AutomaticSize>?,
	ZIndex: CanBeState<number>?,

	-- Custom props
	OutlineColor: CanBeState<Color3>?, -- Defaults to black
	BackgroundColor: CanBeState<Color3>?, -- Defaults to white

	PaddingTop: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingBottom: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingLeft: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingRight: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)

	Rotation: CanBeState<number>?, -- Defaults to 0

	OuterChildren: Child?, -- Children not under the padded frame
	Children: Child?, -- Children under the padded frame
}

--[[
	This component creates a standard outlined frame that all stylized menus must use.
]]
local function Component(props: Props)
	local outerRoundness = InterfaceConstants.roundness.menuOuter
	local innerRoundness = outerRoundness - MARGIN

	local defaultMenuColor = InterfaceConstants.colors.menuBackground

	local frame = New "Frame" {
		Name = props.Name or "OutlinedFrame",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		AutomaticSize = props.AutomaticSize,
		ZIndex = props.ZIndex,
		Rotation = props.Rotation or 0,

		BackgroundColor3 = props.OutlineColor or DEFUALT_OUTLINE_COLOR,

		[Children] = {
			New "UICorner" { -- For the outline
				CornerRadius = UDim.new(0, outerRoundness),
			},

			New "Frame" { -- This is invisible, and is used to apply padding to the children.
				Name = "PaddingFrame",
				Position = UDim2.fromOffset(MARGIN, MARGIN),
				Size = UDim2.new(1, -MARGIN * 2, 1, -MARGIN * 2),
				BackgroundTransparency = 1,
				ZIndex = -1,

				[Children] = {
					New "UIPadding" {
						PaddingTop = UDim.new(0, props.PaddingTop or DEFUALT_PADDING),
						PaddingBottom = UDim.new(0, props.PaddingBottom),
						PaddingLeft = UDim.new(0, props.PaddingLeft),
						PaddingRight = UDim.new(0, props.PaddingRight),
					},

					New "Frame" { -- This is the actual frame that the children are placed in.
						Name = "InnerFrame",
						Size = UDim2.fromScale(1, 1),
						BackgroundColor3 = props.BackgroundColor or defaultMenuColor,

						[Children] = {
							New "UICorner" {
								CornerRadius = UDim.new(0, innerRoundness),
							},

							props.Children,
						},
					},
				},
			},

			props.OuterChildren,
		},
	}

	return frame
end

return Component
