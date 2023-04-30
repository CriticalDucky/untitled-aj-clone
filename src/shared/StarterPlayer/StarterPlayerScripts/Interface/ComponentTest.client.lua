--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

local InterfaceConstants = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild "InterfaceConstants")

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
local doNothing = Fusion.doNothing -- Special thanks to @Validark for this one

-- #endregion

local outlinedFrame = require(componentsFolder:WaitForChild("OutlinedFrame"))
local playerGui = game:GetService "Players".LocalPlayer:WaitForChild "PlayerGui"

New "ScreenGui" {
    Name = "TestGui",
    Parent = playerGui,

    [Children] = {
        outlinedFrame {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 400, 0, 250),
            AnchorPoint = Vector2.new(0.5, 0.5),

            OutlineColor = InterfaceConstants.colors.green1,
            BackgroundColor = InterfaceConstants.colors.menuBackground,

            PaddingTop = UDim.new(0, 30),
        }
    }
}