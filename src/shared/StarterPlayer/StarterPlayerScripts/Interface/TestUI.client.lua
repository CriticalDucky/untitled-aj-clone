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
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local worldMenu, worldButton = Component "WorldMenu" {}
local map, mapButton = Component "MapMenu" {}

local emptyTable = {}

local function useUI(element, ...) -- element: Instance, ...: all accepted ServerTypeEnums
    local use = false

    for _, serverTypeEnum in ipairs({...}) do
        if serverTypeEnum == LocalServerInfo.serverType then
            use = true
            break
        end
    end

    return if use then element else emptyTable
end

local testUI = New "ScreenGui" {
    Name = "TestUI",
    IgnoreGuiInset = true,
    Parent = playerGui,

    [Children] = {
        New "Frame" { -- A list that contains all the buttons on the right side of the screen
            Name = "RightButtonList",
            Size = UDim2.fromScale(0, 0.5),
            Position = UDim2.fromScale(1, 0.5),
            AnchorPoint = Vector2.new(1, 0),

            BackgroundTransparency = 1,

            [Children] = {
                New "UIListLayout" {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5),
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                },

                useUI(worldButton, ServerTypeEnum.location),
                useUI(mapButton, ServerTypeEnum.location),
            },
        },

        useUI(worldMenu, ServerTypeEnum.location),
        useUI(map, ServerTypeEnum.location),
    },
}

