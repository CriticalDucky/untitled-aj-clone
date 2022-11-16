local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

if RunService:IsClient() then
    local teleportData = TeleportService:GetLocalPlayerTeleportData()

    return teleportData and teleportData.worldIndexOrigin
elseif RunService:IsServer() then
    return function(player: Player)
        if not player then
            return
        end

        local teleportData = player:GetJoinData().TeleportData

        return teleportData and teleportData.worldIndexOrigin
    end
end