local X_IMAGE_ID = "rbxassetid://13267266385"

--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"
local settingsFolder = replicatedFirstShared:WaitForChild "Settings"

local bubbleButton = require(componentsFolder:WaitForChild "BubbleButton")
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
	LayoutOrder: CanBeState<number>?,
	Position: CanBeState<UDim2>?,
	AnchorPoint: CanBeState<Vector2>?,
	ZIndex: CanBeState<number>?,

    -- Custom props
    PrimaryColor: CanBeState<Color3>?, -- background color; defaults to blue
	SecondaryColor: CanBeState<Color3>?, -- outlines, text, icon color; defaults to a darker blue

    OnClick: (() -> ())?,
    Disabled: CanBeState<boolean>?,
}

--[[
	This component creates a stylized bubble exit button.
]]
local function Component(props: Props)
    return bubbleButton {
        Name = "ExitButton",
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        ZIndex = props.ZIndex,
        SizeX = 48,

        PrimaryColor = props.PrimaryColor or InterfaceConstants.colors.buttonBluePrimary,
        SecondaryColor = props.SecondaryColor or InterfaceConstants.colors.buttonBlueSecondary,

        OnClick = props.OnClick,
        Disabled = props.Disabled,

        Icon = X_IMAGE_ID,
    }
end

return Component
