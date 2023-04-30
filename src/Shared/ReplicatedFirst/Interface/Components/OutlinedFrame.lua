local ROUNDNESS = 32
local MARGIN = 4
local DEFUALT_PADDING = 24
local DEFUALT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

--#region Imports
local PolicyService = game:GetService "PolicyService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"
local settingsFolder = replicatedFirstShared:WaitForChild "Settings"

local InterfaceConstants = require(settingsFolder:WaitForChild "InterfaceConstants")

local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children

---@diagnostic disable-next-line: undefined-type wtf
type CanBeState<T> = Fusion.CanBeState<T>
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
	Visible: CanBeState<boolean>?, -- Defaults to true

	OutlineColor: CanBeState<Color3>?, -- Defaults to black
	BackgroundColor: CanBeState<Color3>?, -- Defaults to white

	PaddingTop: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingBottom: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingLeft: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
	PaddingRight: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)

	OuterRoundness: CanBeState<number>?, -- Defaults to InterfaceConstants.outlinedFrame.roundness

	Rotation: CanBeState<number>?, -- Defaults to 0

	OuterChildren: any,
	Children: any
}

--[[
	This component creates a standard outlined frame that all stylized menus must use.
]]
local function Component(props: Props)
	local outerRoundness = props.OuterRoundness or ROUNDNESS
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
		Visible = props.Visible,

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
						PaddingTop = props.PaddingTop or UDim.new(0, DEFUALT_PADDING),
						PaddingBottom = props.PaddingBottom,
						PaddingLeft = props.PaddingLeft,
						PaddingRight = props.PaddingRight,
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
