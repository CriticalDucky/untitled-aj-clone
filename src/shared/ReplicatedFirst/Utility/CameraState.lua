local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Hydrate = Fusion.Hydrate

local cameraState = Value({})

local watchingProps = {
    "CFrame",
    "ViewportSize",
}

local function initCamera()
    local camera = workspace.CurrentCamera

    Hydrate(camera){
        [OnEvent "Changed"] = function()
            local currentCameraState = cameraState:get()

            for _, v in pairs(watchingProps) do
                currentCameraState[v] = camera[v]
            end

            cameraState:set(currentCameraState)
        end
    }
end

workspace.Changed:Connect(function(property)
    if property == "CurrentCamera" and workspace.CurrentCamera and workspace.CurrentCamera.Parent then
        initCamera()
    end
end)

return cameraState