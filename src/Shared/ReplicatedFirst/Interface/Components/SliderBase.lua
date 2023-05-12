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
    InputPadding: CanBeState<UIPadding>?, -- How much padding there should be between the parent frame of this component and the input frame where % progress is decided
    BackgroundBody: CanBeState<GuiObject>?, -- The actual design of the slider background, does not respect the InputPadding
    SliderBody: CanBeState<GuiObject>?, -- The actual design of the slider, does not respect the InputPadding
    SliderSize: CanBeState<UDim2>?, -- The size of the slider, which centers with the input body
    ProgressAlpha: CanBeState<number>?, -- Between 0 and 1, what the slider displays.

    -- Edited values
    InputProgressAlpha: CanBeState<number>?, -- Between 0 and 1, what the slider reports back as possible progress.
}

--[[
	This component creates an unstyled slider frame.
]]
local function Component(props: Props)
	
end

return Component
