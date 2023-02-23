local ServerStorage = game:GetService("ServerStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local utilityFolder = ReplicatedFirst.Shared.Utility
local enumsFolder = ReplicatedStorage.Shared.Enums

local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)
local Promise = require(utilityFolder.Promise)
local Types = require(utilityFolder.Types)
local ResponseType = require(enumsFolder.ResponseType)

type PlayerParam = Types.PlayerParam

local PlayerSettings = {}

--[[
    Gets the PlayerSettings table. The player does not need to be in this server.
]]
function PlayerSettings.get(player: PlayerParam)
    return PlayerDataManager.viewPlayerProfile(player):andThen(function(profile)
        return if profile then profile.playerSettings else Promise.reject(ResponseType.error)
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
	return PlayerDataManager.get(player, true):andThen(function(playerData)
        if not playerData then
            return Promise.reject()
        end

        playerData:setValue({ "playerSettings", settingName }, value)
    end)
end

return PlayerSettings
