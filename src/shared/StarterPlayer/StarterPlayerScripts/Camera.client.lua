local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

player.CharacterAdded:Connect(function()
    character = player.Character
end)

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

local UNIT_VECTOR = Vector3.new(1, 1.2, 1).Unit
local DISTANCE = 100
local FOV = 20

RunService.RenderStepped:Connect(function(deltaTime)
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable

        if character and character.Parent then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local position = humanoidRootPart.Position + UNIT_VECTOR * DISTANCE + Vector3.new(0, 1.5, 0)
                camera.CFrame = CFrame.lookAt(position, humanoidRootPart.Position)
                camera.FieldOfView = FOV
            end
        end
    end
end)

