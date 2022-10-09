local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = replicatedFirstShared:WaitForChild("UI")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Component = require(utilityFolder:WaitForChild("GetComponent"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local ClientServerInfo = require(serverFolder:WaitForChild("ClientServerInfo"))
local WorldNames = require(serverFolder:WaitForChild("WorldNames"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local component = function(props)
    local open = Value(false)

    local buttons = {}

	local function button(buttonProps: table)
        return New "TextButton" {
            Size = buttonProps.size or UDim2.fromOffset(50, 50),
            LayoutOrder = buttonProps.layoutOrder or 1,
            Visible = buttonProps.visible or true,
    
            Text = buttonProps.text or "Worlds",
            Font = Enum.Font.Gotham,
            TextSize = 18,
    
            [OnEvent "MouseButton1Click"] = function()
                local onClick = buttonProps.onClick
                local enabled = buttonProps.enabled

                if onClick then
                    onClick()
                end

                if enabled then
                    enabled:set(not enabled:get())
                end
            end,
    
            [Children] = {
                New "UICorner" {
                    CornerRadius = UDim.new(0, 5)
                },

                buttonProps.children
            },
        }
    end

    local worldButtons = Computed(function()
        local currentWorlds = ClientWorldData:get()

        local worldButtons = {}

        for i, world in ipairs(currentWorlds) do
            local worldButton = if worldButtons[i] then worldButtons[i] else button {
                onClick = function()
                    print("Clicked world button")
                end,
                layoutOrder = i,
                text = WorldNames.get(i),
                size = UDim2.new(1, 0, 0, 50),
                visible = Computed(function()
                    local currentWorlds = ClientWorldData:get()

                    local isFirstThreeEmptyWorlds = false do
                        local emptyWorlds = 0

                        for j, worldData in ipairs(currentWorlds) do
                            local isEmpty = true

                            for _, data in pairs(worldData) do
                                if data.serverInfo then
                                    isEmpty = false
                                    break
                                end
                            end

                            if isEmpty then
                                emptyWorlds += 1
                            end

                            if j == i then
                                isFirstThreeEmptyWorlds = true
                                break
                            end

                            if emptyWorlds >= 3 then
                                break
                            end
                        end
                    end

                    local isDifferentWorld do 
                        if ClientServerInfo.serverType == ServerTypeEnum.location then
                            isDifferentWorld = ClientServerInfo.worldIndex ~= i
                        else
                            isDifferentWorld = true
                        end
                    end

                    return (isFirstThreeEmptyWorlds or currentWorlds[i].serverInfo and isDifferentWorld) ~= false
                end),

                children = {
                    New "TextLabel" {
                        Size = UDim2.new(50, 0, 1, 0),
                        Position = UDim2.new(1, 0, 0, 0),
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundTransparency = 1,

                        Text = Computed(function()
                            local currentWorlds = ClientWorldData:get()

                            local world = currentWorlds[i]

                            return world.serverInfo and world.serverInfo.players or 0
                        end),
                        Font = Enum.Font.Gotham,
                    }
                }
            }

            worldButtons[i] = worldButton
        end

        return worldButtons
    end)

    local menu = New "ScrollingFrame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 400),
        BackgroundColor3 = Color3.fromRGB(160, 160, 160),
        Visible = open,

        ClipDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(1, 0, 0, 0),
        ScrollBarThickness = 5,
        ScrollingDirection = Enum.ScrollingDirection.Y,

        [Children] = {
            New "UIListLayout" {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            },

            New "UIPadding" {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
            },

            New "UICorner" {
                CornerRadius = UDim.new(0, 5)
            },

            worldButtons,
        }
    }

    return menu, button {
        onClick = function()
            open:set(not open:get())
        end,
        text = "Worlds",
        size = UDim2.fromOffset(75, 75),
        layoutOrder = props.layoutOrder or 1,
    }
end

return component