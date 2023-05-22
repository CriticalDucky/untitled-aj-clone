--#region Imports
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local replicatedFirstVendor = ReplicatedFirst:WaitForChild "Vendor"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local componentsFolder = replicatedFirstShared:WaitForChild("Interface"):WaitForChild "Components"

local InterfaceConstants = require(replicatedFirstShared:WaitForChild("Settings"):WaitForChild "InterfaceConstants")

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

-- #endregion

local outlinedFrame = require(componentsFolder:WaitForChild "OutlinedFrame")
local bubbleButton = require(componentsFolder:WaitForChild "BubbleButton")
local bannerButton = require(componentsFolder:WaitForChild "BannerButton")
local floatingIconButton = require(componentsFolder:WaitForChild "FloatingIconButton")
local sliderBase = require(componentsFolder:WaitForChild "SliderBase")
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild "PlayerGui"
local bubbleSlider = require(componentsFolder:WaitForChild "BubbleSlider")
local bubbleToggle = require(componentsFolder:WaitForChild "BubbleToggle")
local outlinedMenu = require(componentsFolder:WaitForChild "OutlinedMenu")

local disabled = Value(false)

local progressAlpha = Value(0.5)
local state = Value(false)

local sliderFunction = function(value) progressAlpha:set(value) end

task.spawn(function()
	while true do
		task.wait(3)
		disabled:set(not peek(disabled))
	end
end)

New "ScreenGui" {
	Name = "TestGui",
	Parent = playerGui,

	[Children] = {
		-- outlinedFrame {
		-- 	Position = UDim2.new(0.5, 0, 0.5, 0),
		-- 	Size = UDim2.new(0, 400, 0, 250),
		-- 	AnchorPoint = Vector2.new(0.5, 0.5),

		-- 	OutlineColor = InterfaceConstants.colors.menuGreen1,
		-- 	BackgroundColor = InterfaceConstants.colors.menuBackground,

		-- 	PaddingTop = UDim.new(0, 20),

		-- 	Children = {
		-- 		-- bubbleButton {
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	SizeX = 50,
		-- 		-- 	Text = "Hello world!",
		-- 		-- 	OnClick = function() end,
		-- 		-- 	Disabled = disabled,
		-- 		-- },

		-- 		-- bannerButton {
		-- 		-- 	BorderColor = InterfaceConstants.colors.menuGreen1,
		-- 		-- 	Size = UDim2.fromOffset(250, 150),
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	ZoomOnHover = true,
		-- 		-- 	Image = "rbxassetid://3317811687",
		-- 		-- },

		-- 		-- floatingIconButton {
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 	Size = UDim2.fromOffset(48, 48),

		-- 		-- 	Image = "rbxassetid://13370286402",
		-- 		-- 	OutlineImage = "rbxassetid://13370286263"
		-- 		-- }

		-- 		-- sliderBase {
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 	Size = UDim2.fromOffset(200, 20),

		-- 		-- 	BackgroundBody = New "Frame" {
		-- 		-- 		AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 		Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 		Size = UDim2.fromScale(1, 1),

		-- 		-- 		BackgroundColor3 = Color3.new(0.678431, 0.678431, 0.678431),
		-- 		-- 	},
		-- 		-- 	SliderBody = New "Frame" {
		-- 		-- 		AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 		Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 		Size = UDim2.fromScale(1, 1),
		-- 		-- 		BackgroundTransparency = 0.2,

		-- 		-- 		BackgroundColor3 = Color3.new(1, 1, 1),
		-- 		-- 	},
		-- 		-- 	SliderSize = UDim2.fromOffset(24, 24),
		-- 		-- 	ProgressAlpha = progressAlpha,
		-- 		-- 	InputProgressChanged = sliderFunction,
		-- 		-- 	BackgroundInputShrink = Vector2.new(32,8)
		-- 		-- }

		-- 		-- bubbleSlider {
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),
		-- 		-- 	SizeX = UDim.new(0, 250),
		-- 		-- 	Disabled = disabled,

		-- 		-- 	ProgressAlpha = progressAlpha,
		-- 		-- 	InputProgressChanged = sliderFunction,
		-- 		-- }

		-- 		-- bubbleToggle {
		-- 		-- 	AnchorPoint = Vector2.new(0.5, 0.5),
		-- 		-- 	Position = UDim2.fromScale(0.5, 0.5),

		-- 		-- 	State = state,
		-- 		-- 	OnClick = function() state:set(not peek(state)) end,
		-- 		-- 	Disabled = disabled,
		-- 		-- },

				
		-- 	},
		-- },

		outlinedMenu {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(400, 350),

			TitleText = "LETS GO!",
			onExitButtonClicked = function()
				print("Exit button clicked!")
			end
		}
	},
}
