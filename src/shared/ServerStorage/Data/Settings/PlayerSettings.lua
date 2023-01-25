local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local utilityFolder = ReplicatedFirst.Shared.Utility

local PlayerData = require(ServerStorage.Shared.Data.PlayerData)
local Promise = require(utilityFolder.Promise)
local Types = require(utilityFolder.Types)
local Param = require(utilityFolder.Param)

type PlayerParam = Types.PlayerParam

local PlayerSettings = {}

--[[
    Gets the PlayerSettings table. The player does not need to be in this server.
]]
function PlayerSettings.get(player: PlayerParam)
    return PlayerData.viewPlayerProfile(player, true):andThen(function(playerData)
        if not playerData then
            return PlayerData.viewPlayerProfile(player):andThen(function(profile)
                return profile or Promise.reject()
            end)
        else
            return playerData.profile
        end
    end):andThen(function(profile)
        return profile.Data.playerSettings
    end)
end

--[[
    Gets a PlayerSettings setting. The player does not need to be in this server.
]]
function PlayerSettings.getSetting(player: PlayerParam, settingName: string)
	return PlayerSettings.get(player):andThen(function(settings)
        return settings[settingName]
    end)
end

--[[
    Sets a PlayerSettings setting. The player must be in this server.
]]
function PlayerSettings.setSetting(player: PlayerParam, settingName: string, value)
	return PlayerData.get(player, true):andThen(function(playerData)
        if not playerData then
            return Promise.reject()
        end

        playerData:setValue({ "playerSettings", settingName }, value)
    end)
end

return PlayerSettings
