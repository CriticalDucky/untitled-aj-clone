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
	RoundnessPixels: CanBeState<number>?,
	BorderColor: CanBeState<Color3>?, -- Defaults to black
	BorderHoverColor: CanBeState<Color3>?, -- Defaults to white
	BorderClickColor: CanBeState<Color3>?, -- Hover color will be used if not provided

	DarkenOnHover: CanBeState<boolean>?, -- Defaults to false
	Darkness: CanBeState<number>?, -- 0 to 1, defaults to 0.1

	ZoomOnHover: CanBeState<boolean>?, -- Defaults to false
	ZoomScale: CanBeState<number>?, -- Defaults to 1.05

	Children: CanBeState<{}>?, -- Children will be placed inside the button
}

--[[
	This component creates an solid image button that can:
	- Be rounded
	- Have a border
	- Have a darken effect on hover
	- Lighten border on hover
]]
local function Component(props: Props)
	local frame = New "Frame" {
		Name = props.Name or "BannerButton",
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Size = props.Size,
		ZIndex = props.ZIndex,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, props.RoundnessPixels),
			},

			New "CanvasGroup" {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -8, 1, -8),

				BackgroundTransparency = 1,

				[Children] = {
					New "UICorner" {
						CornerRadius = UDim.new(0, props.RoundnessPixels - 4),
					},

					New "ImageLabel" {
						
					}
				}
			}
		}
	}
end

return Component
