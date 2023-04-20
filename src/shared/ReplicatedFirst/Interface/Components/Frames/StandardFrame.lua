--#region Imports
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
    OutlineColor: CanBeState<Color3>?, -- Defaults to black
    BackgroundColor: CanBeState<Color3>?, -- Defaults to white

    PaddingTop: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
    PaddingBottom: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
    PaddingLeft: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)
    PaddingRight: CanBeState<UDim>?, -- Defaults to UDim.new(0, 0)

    Rotation: CanBeState<number>?, -- Defaults to 0
}

--[[
	This component creates a standard outlined frame that all stylized menus must use.
]]
local function Component(props: Props)
	local MARGIN = 4
	local OUTER_ROUNDNESS = InterfaceConstants.roundness.menuOuter
	local INNER_ROUNDNESS = OUTER_ROUNDNESS - MARGIN
	local DEFUALT_PADDING = 40
	local DEFUALT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

	local frame = New "Frame" {
		Name = props.Name or "StandardFrame",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		AutomaticSize = props.AutomaticSize,
		ZIndex = props.ZIndex,

		BackgroundColor3 = props.OutlineColor or DEFUALT_OUTLINE_COLOR,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, InterfaceConstants.roundness.menuOuter),
			},

			New "Frame" {
				Name = "InnerFrame",
				Position = UDim2.fromOffset(MARGIN, MARGIN),
				Size = UDim2.fromOffset(-MARGIN * 2, -MARGIN * 2),
				BackgroundColor3 = props.BackgroundColor or Color3.fromRGB(255, 255, 255),
				Rotation = props.Rotation or 0,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, INNER_ROUNDNESS),
					},

					New "UIPadding" {
						PaddingTop = props.PaddingTop or UDim.new(0, DEFUALT_PADDING),
						PaddingBottom = props.PaddingBottom or UDim.new(0, DEFUALT_PADDING),
						PaddingLeft = props.PaddingLeft or UDim.new(0, DEFUALT_PADDING),
						PaddingRight = props.PaddingRight or UDim.new(0, DEFUALT_PADDING),
					},
				},
			},
		}
	}
end

return Component
