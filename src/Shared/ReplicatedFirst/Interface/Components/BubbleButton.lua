local SIZE_Y = 40
local DEFAULT_SIZE_X = 100
local DEFAULT_ICON_SIZE = 24
local SPRING_SPEED = 70

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"
local settingsFolder = replicatedFirstShared:WaitForChild "Settings"

local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")
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
	Size: CanBeState<UDim2>?, -- Consider using SizeX, but can be used to override SizeY and SizeX if you want
	AutomaticSize: CanBeState<Enum.AutomaticSize>?,
	ZIndex: CanBeState<number>?,

	-- Custom props
	Text: CanBeState<string>?,
	Icon: CanBeState<string>?, -- content id
	IconSize: CanBeState<number>?, -- offset size
	PrimaryColor: CanBeState<Color3>?, -- background color
	SecondaryColor: CanBeState<Color3>?, -- outlines, text, icon color
	SizeX: CanBeState<number>?, -- use this so that the Y size is always the same, but if you want to override it, you can use Size

	OnClick: (() -> ())?,
	Disabled: CanBeState<boolean>?,
}

--[[
	This component creates a stylized bubble button that can either hold text or an icon.
    It plays a sound when clicked and hovered over.
]]
local function Component(props: Props)
	local textSize = InterfaceConstants.fonts.button.size
	local textFont = InterfaceConstants.fonts.button.font

	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local function brighten(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.min(v + 40 / 255, 1))
	end

	local function desaturate(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, math.max(s - 0.2, 0), v)
	end

	local primaryColor = Spring(
		Computed(function(use)
			local color = use(props.PrimaryColor or InterfaceConstants.colors.buttonBluePrimary)

			if use(props.Disabled) then
				return desaturate(color)
			else
				return if use(isHovering) then brighten(color) else color
			end
		end),
		SPRING_SPEED,
		1
	)

	local secondaryColor = Spring(
		Computed(function(use)
			local color = use(props.SecondaryColor or InterfaceConstants.colors.buttonBlueSecondary)

			if use(props.Disabled) then
                return desaturate(color)
            else
                return if use(isHovering) then brighten(color) else color
            end
		end),
		SPRING_SPEED,
		1
	)

	local frame = New "TextLabel" {
		Name = props.Name or "BubbleButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.new(UDim.new(0, props.SizeX or DEFAULT_SIZE_X), UDim.new(0, SIZE_Y)),
		AutomaticSize = props.AutomaticSize,
		ZIndex = props.ZIndex,

		BackgroundColor3 = primaryColor,
		Text = props.Text or "",
		TextColor3 = secondaryColor,
		TextSize = textSize,
		FontFace = textFont,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, 20),
			},

			New "UIStroke" {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = secondaryColor,
				Thickness = 4,
			},

			Computed(function(use)
				if not use(props.Text) then
					return New "ImageLabel" {
						Size = UDim2.fromOffset(
							props.IconSize or DEFAULT_ICON_SIZE,
							props.IconSize or DEFAULT_ICON_SIZE
						),
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = props.Icon,
						ImageColor3 = secondaryColor,
						ZIndex = -1,
					}
				end
			end, Fusion.cleanup),

			buttonInput {
				Size = UDim2.fromScale(1, 1),
				OnClick = props.OnClick,
				Disabled = props.Disabled,

				isHeldDown = isHeldDown,
				isHovering = isHovering,
			},
		},
	}

	return frame
end

return Component
