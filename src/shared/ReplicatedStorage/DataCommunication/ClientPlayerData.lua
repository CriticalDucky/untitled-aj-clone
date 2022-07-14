local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local Players = game:GetService("Players")

local UIFolder = ReplicatedStorageShared:WaitForChild("UI")
local Fusion = require(ReplicatedStorageShared:WaitForChild("Fusion"))

local Utility = ReplicatedStorageShared:WaitForChild("Utility")
local UIManagement = UIFolder:WaitForChild("UIManagement")
local Components = UIFolder:WaitForChild("Components")

local WaitForDescendant = require(Utility:WaitForChild("WaitForDescendant")) 

local Util = require(WaitForDescendant(Utility, "UIUtil"))

local Constants = require(UIManagement:WaitForChild("Constants"))
local Component = Util.Component
local CameraState = require(Utility:WaitForChild("CameraState"))

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

local sendDataEvent = ReplicatedStorageShared:WaitForChild("DataCommunication"):WaitForChild("SendData")

local playersData = {}

local localPlayerData = Value {
    private = {},
    public = {}
}

sendDataEvent.OnClientEvent:Connect(function(player, data, privacy)
    local currentPlayerData = playersData[player] and playersData[player]:get() or {}

    currentPlayerData[privacy] = data

    if playersData[player] then
        playersData[player]:set(currentPlayerData)
    else
        playersData[player] = Value {currentPlayerData}
    end

    if player == Players.LocalPlayer then
        localPlayerData:set(playersData[player]:get())
    end
end)

return playersData, localPlayerData