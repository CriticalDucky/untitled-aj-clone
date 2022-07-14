local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local sharedFolder = script.Parent
local character = sharedFolder.Parent
local humanoid = character:WaitForChild("Humanoid")

local Fusion = require(ReplicatedStorageShared:WaitForChild("Fusion"))

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

local MOVE_ACTION_NAME = "clickToMove"

local movementEnabled = false

local function onClickAction(action, state, input)
    if action == MOVE_ACTION_NAME then
        if state == Enum.UserInputState.Begin then
            print("Begin")
            movementEnabled = true
        elseif state == Enum.UserInputState.End then
            print("End")
            movementEnabled = false
        end
    end
end

local renderConnection, destroyingConnection do
    local pathRendering = false

    renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if movementEnabled and not pathRendering then
            local mouse = player:GetMouse()

            humanoid:MoveTo(mouse.Hit.Position)
        end
    end)

    destroyingConnection = character.Destroying:Connect(function()
        renderConnection:Disconnect()
        destroyingConnection:Disconnect()
    end)
end

ContextActionService:BindAction(MOVE_ACTION_NAME, onClickAction, false, Enum.UserInputType.MouseButton1)
