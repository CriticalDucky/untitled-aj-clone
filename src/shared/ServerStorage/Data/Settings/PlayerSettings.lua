local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ServerStorage.Shared.Data.PlayerData)

local PlayerSettings = {}

function getPlayerOrId(player)
    return if type(player) =="number" then Players:GetPlayerByUserId(player) else player
end

function PlayerSettings.get(player: Player | number)
    player = getPlayerOrId(player)

    local profile do
        local playerData = PlayerData.get(player)

        profile = if playerData then playerData.profile else PlayerData.viewPlayerData(player)
    end

    if not profile then
        return
    end

    return profile.Data.playerSettings
end

function PlayerSettings.getSetting(player: Player | number, settingName: string)
    player = getPlayerOrId(player)

    local playerSettings = PlayerSettings.get(player)

    if not playerSettings then
        return
    end

    return playerSettings[settingName]
end

function PlayerSettings.setSetting(player: Player | number, settingName: string, value)
    player = getPlayerOrId(player)

    local playerData = PlayerData.get(player, true)

    if not playerData then
        return
    end

    playerData:setValue({"playerSettings", settingName}, value)
end

return PlayerSettings