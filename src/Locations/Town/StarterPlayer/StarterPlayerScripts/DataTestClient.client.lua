local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local dataFolder = replicatedStorageShared:WaitForChild("Data")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ClientPlayerData = require(dataFolder:WaitForChild("ClientPlayerData"))
local ActiveShopsClient =require(dataFolder:WaitForChild("ShopInfo"):WaitForChild("ActiveShopsClient"))
local ClientPurchase = require(requestsFolder:WaitForChild("Shopping"):WaitForChild("ClientPurchase"))
local ShopType = require(enumsFolder:WaitForChild("ShopType"))

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

warn(playerValue:get())

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

local DEBOUNCE = 5
local lastTime = 0

workspace:WaitForChild("PurchasePart").Touched:Connect(function(part)
    if part and part.Parent and part.Parent:FindFirstChild("Humanoid") then
        if time() - lastTime > DEBOUNCE then
            print("Purchase part touched")


            lastTime = time()
            ClientPurchase.request(ShopType.test1, 1)
        end
    end
end)