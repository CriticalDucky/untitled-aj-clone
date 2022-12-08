local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = replicatedFirstShared:WaitForChild("UI")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Component = require(utilityFolder:WaitForChild("GetComponent"))
local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Locations = require(serverFolder:WaitForChild("Locations"))
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild("ClientTeleport"))
local ServerTypeGroups = require(serverFolder:WaitForChild("ServerTypeGroups"))
local ServerGroupEnum = require(enumsFolder:WaitForChild("ServerGroup"))

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
    local locationButtons = {}

    local open = Value(false)

    for priority, locationEnum in pairs(Locations.priority) do
        local location = Locations.info[locationEnum]

        local button = New "TextButton" {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            LayoutOrder = priority,

            Text = location.name,
            TextSize = 18,
            TextWrapped = true,
            TextColor3 = Color3.fromRGB(255, 255, 255),

            [OnEvent "MouseButton1Click"] = function()
                if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                    local locationServerFolder = ReplicatedStorage:WaitForChild("Location"):WaitForChild("Server")
                    local LocalWorldInfo = require(locationServerFolder:WaitForChild("LocalWorldInfo"))

                    if LocalWorldInfo.locationEnum == locationEnum then
                        open:set(false)
                    else
                        ClientTeleport.toLocation(locationEnum)
                    end
                else
                    ClientTeleport.toLocation(locationEnum)
                end
            end
        }

        table.insert(locationButtons, button)
    end

	local map = New "Frame" {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 400, 0, 400),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Visible = open,

        [Children] = {
            New "Frame" {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,

                [Children] = {
                    New "UIGridLayout" {
                        CellSize = UDim2.new(0, 100, 0, 100),
                        FillDirection = Enum.FillDirection.Horizontal,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        StartCorner = Enum.StartCorner.TopLeft,
                    },

                    locationButtons
                }
            },

            Component "ExitButton" {
                value = open,
            },
        }
    }

    return map, New "TextButton" {
        Size = UDim2.fromOffset(75, 75),
        LayoutOrder = 100,
        Visible = true,

        Text = "Map",
        Font = Enum.Font.Gotham,
        TextSize = 18,

        [OnEvent "MouseButton1Click"] = function()
            open:set(not open:get())
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0, 5)
            },
        },
    }
end

return component