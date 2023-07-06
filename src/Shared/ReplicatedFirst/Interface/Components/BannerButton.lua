local SPRING_SPEED = 50

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

local buttonInput = require(componentsFolder:WaitForChild "ButtonInput")

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstVendor:WaitForChild "Fusion")
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
	Size: CanBeState<UDim2>?, -- If you want to preserve the aspect ratio of the image, calculate the size as size + BorderSizePixels * 2
	ZIndex: CanBeState<number>?,

	-- Custom props
	RoundnessPixels: CanBeState<number>?, -- Defaults to 24
	BorderSizePixels: CanBeState<number>?, -- Defaults to 4
	BorderColor: CanBeState<Color3>?, -- Defaults to black
	BottomExtraPx: CanBeState<number>?, -- Defaults to 0, adds extra px to the bottom of the button
	BorderHoverColor: CanBeState<Color3>?, -- Defaults to brightened border color
	BorderClickColor: CanBeState<Color3>?, -- Hover color will be used if not provided
	BorderDisabledColor: CanBeState<Color3>?, -- Defaults to slightly darkened border color

	DarkenOnHover: CanBeState<boolean>?, -- Defaults to false
	Darkness: CanBeState<number>?, -- 0 to 1, defaults to 0.1. Decides how dark the button will be when hovered (transparency = 1 - darkness)

	ZoomOnHover: CanBeState<boolean>?, -- Defaults to false
	ZoomScale: CanBeState<number>?, -- Defaults to 1.05

	InputExtraPx: CanBeState<number>?, -- Defaults to 0, adds extra px to the input area

	Children: CanBeState<{}>?, -- Children will be placed inside the button

	Disabled: CanBeState<boolean>?, -- Defaults to false

	Image: CanBeState<string>?, -- Defaults to nil
	ResampleMode: CanBeState<Enum.ResamplerMode>?, -- Defaults to Enum.ResamplerMode.Default
}

--[[
	This component creates an solid image button that can:
	- Be rounded
	- Have a border
	- Have a darken effect on hover
	- Lighten border on hover
]]
local function Component(props: Props)
	local function brighten(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.min(v + 40 / 255, 1))
	end

	local function darken(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.max(v - 40 / 255, 0))
	end

	local roundnessPixels = props.RoundnessPixels or 24
	local borderColor = props.BorderColor or Color3.new(0, 0, 0)
	local borderHoverColor = props.BorderHoverColor or brighten(borderColor)
	local borderClickColor = props.BorderClickColor or borderHoverColor
	local borderSizePixels = props.BorderSizePixels or 4
	local borderDisabledColor = props.BorderDisabledColor or darken(borderColor)

	local darkenOnHover = props.DarkenOnHover or false
	local darkness = props.Darkness or 0.1

	local zoomOnHover = props.ZoomOnHover or false
	local zoomScale = props.ZoomScale or 1.05

	local inputExtraPx = props.InputExtraPx or 0

	local isHovering = Value(false)
	local isHeldDown = Value(false)

	local frame = New "Frame" {
		Name = props.Name or "BannerButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		BackgroundColor3 = Spring(
			Computed(function(use)
				local color = borderColor

				if use(props.Disabled) then return borderDisabledColor end

				if use(isHeldDown) then
					color = borderClickColor
				elseif use(isHovering) then
					color = borderHoverColor
				end

				return color
			end),
			SPRING_SPEED,
			1
		),

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, roundnessPixels),
			},

			buttonInput {
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.new(1, inputExtraPx * 2, 1, inputExtraPx * 2),

				Disabled = props.Disabled,

				isHeldDown = isHeldDown,
				isHovering = isHovering,
			},

			New "CanvasGroup" {
				Name = "ImageContainer",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0) + UDim2.fromOffset(0, borderSizePixels),
				Size = UDim2.new(1, -borderSizePixels * 2, 1, -borderSizePixels * 2 - inputExtraPx),
				ZIndex = -1,

				BackgroundTransparency = 1,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, roundnessPixels - 4),
					},

					New "UIPadding" {
						PaddingBottom = UDim.new(0, -1), -- Hack to fix the image being cut off (stupid roblox)
					},

					New "ImageLabel" {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = Spring(
							Computed(function(use)
								local scale = 1

								if use(isHovering) and use(zoomOnHover) then scale = use(zoomScale) end

								return UDim2.fromScale(scale, scale)
							end),
							SPRING_SPEED,
							1
						),
						BackgroundTransparency = 1,
						ZIndex = -100,

						Image = props.Image,
						ResampleMode = props.ResampleMode or Enum.ResamplerMode.Default,
						ScaleType = Enum.ScaleType.Crop,
					},

					New "Frame" {
						Name = "Darken",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BackgroundTransparency = Spring(
							Computed(function(use)
								local transparency = 1

								if use(props.Disabled) then return transparency end

								if use(isHovering) and use(darkenOnHover) then transparency = 1 - use(darkness) end

								return transparency
							end),
							SPRING_SPEED,
							1
						),
						ZIndex = -1,
					},

					props.Children,
				},
			},
		},
	}

	return frame
end

return Component