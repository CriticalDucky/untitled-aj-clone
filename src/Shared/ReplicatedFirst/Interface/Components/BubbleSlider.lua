local SIZE_Y = 12
local SPRING_SPEED = 65

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

local sliderBase = require(componentsFolder:WaitForChild "SliderBase")
local InterfaceConstants = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild "InterfaceConstants")

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
	Name: CanBeState<string>?,
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	SizeX: CanBeState<UDim>?,
	ZIndex: CanBeState<number>?,

    -- SliderBase props
    ProgressAlpha: CanBeState<number>?, -- 0 to 1
    Disabled: CanBeState<boolean>?, -- Whether or not the slider is disabled
    InputProgressChanged: CanBeState<(number) -> ()>?, -- Inexpensive, unyielding callback that runs every time input changes and updates ProgressAlpha.

    BackgroundColor: CanBeState<Color3>?, -- The color of the slider background; optional
    SliderColor: CanBeState<Color3>?, -- The color of the slider; optional
}

--[[
	This component creates a bubble slider.
]]
local function Component(props: Props)
    local isHoveringBackground = Value(false)
    local isHoveringSlider = Value(false)
    local isHeldDownBackground = Value(false)
    local isHeldDownSlider = Value(false)

	local isHovering = Computed(function(use)
        return use(isHoveringBackground) or use(isHoveringSlider)
    end)
	local isHeldDown = Computed(function(use) -- For possible future use
        return use(isHeldDownBackground) or use(isHeldDownSlider)
    end)

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

    local slider = sliderBase {
        Name = props.Name,
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        Size = Computed(function(use)
            return UDim2.new(use(props.SizeX) or UDim.new(0, 100), UDim.new(0, SIZE_Y))
        end),
        ZIndex = props.ZIndex,

        BackgroundInputShrink = Vector2.new(SIZE_Y, 0),
        BackgroundBody = New "Frame" {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),

            BackgroundColor3 = secondaryColor,

            [Children] = New "UICorner" {
                CornerRadius = UDim.new(1, 0),
            }
        },

        SliderSize = UDim2.fromOffset(SIZE_Y + 8, SIZE_Y + 8),
        SliderBody = New "Frame" {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),

            BackgroundColor3 = primaryColor,

            [Children] = New "UICorner" {
                CornerRadius = UDim.new(1, 0),
            }
        },

        ProgressAlpha = props.ProgressAlpha,
        Disabled = props.Disabled,
        InputProgressChanged = props.InputProgressChanged,
    }

    return slider
end

return Component
