local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ServerStorage.Shared.Data.PlayerData)

local PlayerSettings = {}

function PlayerSettings.get(player)
    local profile do
        local playerData = PlayerData.get(player)

        profile = if playerData then playerData.profile else PlayerData.viewPlayerData(player)
    end

    if not profile then
        return
    end

    return profile.Data.playerSettings
end

function PlayerSettings.getSetting(player, settingName)
    local playerSettings = PlayerSettings.get(player)

    if not playerSettings then
        return
    end

    return playerSettings[settingName]
end

return PlayerSettings