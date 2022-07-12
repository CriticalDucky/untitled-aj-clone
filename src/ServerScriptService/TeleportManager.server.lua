local proximityPart = workspace:WaitForChild("ProximityPart")
local proximityPrompt: ProximityPrompt = proximityPart:WaitForChild("ProximityPrompt")
local teleportModule = require(game:GetService("ServerScriptService"):WaitForChild("Teleport"))

proximityPrompt.Triggered:Connect(function(playerWhoTriggered)
    teleportModule.teleportToAdventure("test1", {playerWhoTriggered})
end)