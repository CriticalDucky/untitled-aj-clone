local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

if RunService:IsClient() then
    local teleportData = TeleportService:GetLocalPlayerTeleportData()

    return teleportData and teleportData.worldIndexOrigin
elseif RunService:IsServer() then
    return function(player: Player)
        local teleportData = player:GetJoinData().TeleportData

        print(teleportData, teleportData.worldIndexOrigin)

        return teleportData and teleportData.worldIndexOrigin
    end
end