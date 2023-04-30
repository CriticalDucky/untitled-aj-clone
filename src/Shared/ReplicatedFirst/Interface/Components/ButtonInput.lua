--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

-- Optional: Remove imports that you don't need
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local peek = Fusion.peek

---@diagnostic disable-next-line: undefined-type wtf!!!!!!!
type CanBeState<T> = Fusion.CanBeState<T>
---@diagnostic disable-next-line: undefined-type wtf!!!!!!!
type Value<T> = Fusion.Value<T>
-- #endregion

export type Props = {
    -- some generic properties we'll allow other code to control directly
    Name: CanBeState<string>?,
    LayoutOrder: CanBeState<number>?,
    Position: CanBeState<UDim2>?,
    AnchorPoint: CanBeState<Vector2>?,
    Size: CanBeState<UDim2>?,
    AutomaticSize: CanBeState<Enum.AutomaticSize>?,
    ZIndex: CanBeState<number>?,
    BackgroundTransparency: CanBeState<number>?,

    -- button-specific properties
    Text: CanBeState<string>?,
    OnClick: (() -> ())?,
    Disabled: CanBeState<boolean>?,

    -- edited values
    isHovering: Value<boolean>?,
    isHeldDown: Value<boolean>?,
}

--[[
	This component creates an un-styled button.

    WARNING: Hovering will be set to true even if the button is covered by other UI.
]]
local function Component(props: Props)
    local isHovering = props.isHovering or Value(false)
    local isHeldDown = props.isHeldDown or Value(false)

    isHovering:set(false)
    isHeldDown:set(false)

    return New "TextButton" {
        Name = props.Name or "Button",
        LayoutOrder = props.LayoutOrder,
        Position = props.Position,
        AnchorPoint = props.AnchorPoint,
        Size = props.Size,
        AutomaticSize = props.AutomaticSize,
        ZIndex = props.ZIndex,

        Text = props.Text,
        TextColor3 = Color3.fromHex("FFFFFF"),

        BackgroundTransparency = props.BackgroundTransparency or 1, -- The rough style behavior below will never be visible to the player, only for testing
        BackgroundColor3 = Spring(Computed(function(use)
            if use(props.Disabled) then
                return Color3.fromHex("CCCCCC")
            else
                local baseColor = Color3.fromHex("0085FF")
                -- darken/lighten when hovered or held down
                if use(isHeldDown) then
                    baseColor = baseColor:Lerp(Color3.new(0, 0, 0), 0.25)
                elseif use(isHovering) then
                    baseColor = baseColor:Lerp(Color3.new(1, 1, 1), 0.25)
                end
                return baseColor
            end
        end), 20),

        [OnEvent "Activated"] = function()
            if props.OnClick ~= nil and not peek(props.Disabled) then
                -- We're explicitly calling this function with no arguments to
                -- match the types we specified above. If we just passed it
                -- straight into the event, the function would receive arguments
                -- from the Activated event, which might not be desirable.
                props.OnClick()
            end
        end,

        [OnEvent "MouseButton1Down"] = function()
            isHeldDown:set(true) -- it's good UX to give immediate feedback
        end,

        [OnEvent "MouseButton1Up"] = function()
            isHeldDown:set(false)
        end,

        [OnEvent "MouseEnter"] = function()
            -- Roblox calls this event even if the button is being covered by
            -- other UI. For simplicity, we won't worry about that.
            isHovering:set(true)
        end,

        [OnEvent "MouseLeave"] = function()
            isHovering:set(false)
            -- If the button is being held down, but the cursor moves off the
            -- button, then we won't receive the mouse up event. To make sure
            -- the button doesn't get stuck held down, we'll release it if the
            -- cursor leaves the button.
            isHeldDown:set(false)
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0, 4)
            },

            New "UIPadding" {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6)
            }
        }
    }
end

return Component
