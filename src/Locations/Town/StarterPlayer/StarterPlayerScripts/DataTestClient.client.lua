local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")

local ClientPlayerData = require(replicatedStorageShared:WaitForChild("Data"):WaitForChild("ClientPlayerData"))

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ScreenGui")

local playerValue = ClientPlayerData.getData(player, true)

New "TextLabel" {
    Text = Computed(function()
        return playerValue:get().currency.money or 0
    end),
    Size = UDim2.new(0, 100, 0, 100),
    Parent = screenGui
}

New "TextLabel" {
    Text = Computed(function()
        return playerValue:get().awards.points or 0
    end),
    Size = UDim2.new(0, 100, 0, 100),
    Position = UDim2.new(0, 0, 0, 100),
    Parent = screenGui
}