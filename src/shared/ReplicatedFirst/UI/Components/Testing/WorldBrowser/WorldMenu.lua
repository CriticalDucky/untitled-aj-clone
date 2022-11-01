local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = replicatedFirstShared:WaitForChild("UI")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")

local Component = require(utilityFolder:WaitForChild("GetComponent"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))
local WorldNames = require(serverFolder:WaitForChild("WorldNames"))
local ServerGroupEnum = require(enumsFolder:WaitForChild("ServerGroup"))
local ServerTypeGroups = require(serverFolder:WaitForChild("ServerTypeGroups"))
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild("ClientTeleport"))
local LocalWorldOrigin = require(serverFolder:WaitForChild("LocalWorldOrigin"))

local ClientWorldInfo do
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        local replicatedStorageLocation = ReplicatedStorage:WaitForChild("Location")
        local locationServerFolder = replicatedStorageLocation:WaitForChild("Server")
        ClientWorldInfo = require(locationServerFolder:WaitForChild("ClientWorldInfo")):get()
    end
end

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

    local function worldButton(worldIndex)
        local button = button {
            onClick = function()
                ClientTeleport.toWorld(worldIndex)
            end,
            layoutOrder = worldIndex - ClientWorldData.getWorldPopulation(worldIndex) * 10000,
            text = WorldNames.get(worldIndex),
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

                        if LocalWorldOrigin == j then
                            isEmpty = false
                        end

                        if isEmpty then
                            emptyWorlds += 1
                        end

                        if j == worldIndex then
                            isFirstThreeEmptyWorlds = true
                            break
                        end

                        if emptyWorlds >= 3 then
                            break
                        end
                    end
                end

                local isDifferentWorld do
                    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                        isDifferentWorld = ClientWorldInfo.worldIndex ~= worldIndex
                    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
                        isDifferentWorld = LocalWorldOrigin ~= worldIndex
                    else
                        isDifferentWorld = true
                    end
                end

                return ((isFirstThreeEmptyWorlds or (ClientWorldData.getWorldPopulation(worldIndex) ~= 0)) and isDifferentWorld and true) or false
            end),

            children = {
                New "TextLabel" {
                    Size = UDim2.new(0, 50, 1, 0),
                    Position = UDim2.new(1, 0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundTransparency = 1,

                    Text = Computed(function()
                        return ClientWorldData.getWorldPopulation(worldIndex)
                    end),
                    Font = Enum.Font.Gotham,
                }
            }
        }

        return button
    end

    local worldButtons = Computed(function()
        local currentWorlds = ClientWorldData:get()

        local worldButtons = {}

        for i, _ in ipairs(currentWorlds) do
            worldButtons[i] = worldButton(i)
        end

        return worldButtons
    end)

    local menu = Component "DefaultElementList" {
        open = open,
        elements = worldButtons,
    }

    local button = button {
        onClick = function()
            open:set(not open:get())
        end,
        text = "Worlds",
        size = UDim2.fromOffset(75, 75),
        layoutOrder = props.layoutOrder or 1,
    }

    return menu, button
end

return component