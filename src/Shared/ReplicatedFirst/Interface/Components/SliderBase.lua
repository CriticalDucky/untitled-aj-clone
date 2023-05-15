local SELECT_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
}

local MOVEMENT_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true,
}

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"
local RunService = game:GetService "RunService"

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
	Size: CanBeState<UDim2>?,
	ZIndex: CanBeState<number>?,

	-- Custom props
	BackgroundBody: CanBeState<GuiObject>?, -- The actual design of the slider background
	SliderBody: CanBeState<GuiObject>?, -- The actual design of the slider
	SliderSize: CanBeState<UDim2>?, -- The size of the slider, which centers with the input body
	ProgressAlpha: CanBeState<number>?, -- Between 0 and 1, what the slider displays.
	Disabled: CanBeState<boolean>?, -- Whether or not the slider is disabled
	InputProgressChanged: CanBeState<(number) -> ()>?, -- Inexpensive, unyielding callback that runs every frame and updates ProgressAlpha called when the slider is changed

	isHoveringBackground: CanBeState<boolean>?,
	isHoveringSlider: CanBeState<boolean>?,
	isHeldDownBackground: CanBeState<boolean>?,
	isHeldDownSlider: CanBeState<boolean>?,
}

--[[
	This component creates an unstyled slider frame
]]
local function Component(props: Props)
	local mousePosition: Vector2? = nil -- Mouse position in screen space
	local selected: ("Background" | "Slider")?
	local sliderInputOffset: Vector2? -- Only relevant when selected == "Slider"

	local sliderAbsolutePosition = Value(Vector2.new(0, 0))
	local sliderAbsoluteSize = Value(Vector2.new(0, 0))

	local backgroundAbsolutePosition = Value(Vector2.new(0, 0))
	local backgroundAbsoluteSize = Value(Vector2.new(0, 0))

	local function updateProgress(input: InputObject)
		mousePosition = Vector2.new(input.Position.X, input.Position.Y)

		if MOVEMENT_INPUTS[input.UserInputType] and selected then
			local backgroundAbsolutePosition = peek(backgroundAbsolutePosition)
			local backgroundAbsoluteSize = peek(backgroundAbsoluteSize)

			local offset = if selected == "Slider" then (sliderInputOffset + peek(sliderAbsoluteSize)/2) else Vector2.new(0,0)

			local relativePosition = (mousePosition + offset - backgroundAbsolutePosition) / backgroundAbsoluteSize
			local clampedRelativePosition = Vector2.new(math.clamp(relativePosition.X, 0, 1), math.clamp(relativePosition.Y, 0, 1))

			-- Update the slider position
			props.InputProgressChanged(math.clamp(clampedRelativePosition.X, 0, 1))
		end
	end

	local inputChangedConnection = UserInputService.InputChanged:Connect(updateProgress)

	local inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if SELECT_INPUTS[input.UserInputType] then
			selected = nil
			sliderInputOffset = nil
		end
	end)

	local frame = New "Frame" {
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Name = props.Name or "SliderBase",

		[Cleanup] = {
			inputChangedConnection,
			inputEndedConnection,
		},

		[Out "AbsolutePosition"] = backgroundAbsolutePosition,
		[Out "AbsoluteSize"] = backgroundAbsoluteSize,

		[Children] = {
			buttonInput {
				Name = "BackgroundInput",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10000,

				Disabled = props.Disabled,

				InputBegan = function(input: InputObject)
					if SELECT_INPUTS[input.UserInputType] then
						selected = "Background"
						updateProgress(input)
					end
				end,

				isHeldDown = props.isHeldDownBackground,
				isHovering = props.isHoveringBackground,
			},

			props.BackgroundBody,

			New "Frame" {
				Name = "SliderFrame",
				BackgroundTransparency = 1,
				Size = props.SliderSize or UDim2.fromOffset(20, 20),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = Computed(function(use)
					return UDim2.fromScale(use(props.ProgressAlpha) or 0, 0.5)
				end),
				ZIndex = 20000,

				[Out "AbsolutePosition"] = sliderAbsolutePosition,
				[Out "AbsoluteSize"] = sliderAbsoluteSize,

				[Children] = {
					buttonInput {
						Name = "SliderInput",
						Size = UDim2.fromScale(1, 1),
						ZIndex = 10000,
	
						Disabled = props.Disabled,
	
						InputBegan = function(input: InputObject)
							if SELECT_INPUTS[input.UserInputType] then
								selected = "Slider"
								sliderInputOffset = peek(sliderAbsolutePosition) - Vector2.new(input.Position.X, input.Position.Y)
								updateProgress(input)
							end
						end,
	
						isHeldDown = props.isHeldDownSlider,
						isHovering = props.isHoveringSlider,
					},

					props.SliderBody,
				},
			}
		},
	}

	return frame
end

return Component
