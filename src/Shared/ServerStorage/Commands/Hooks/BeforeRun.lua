local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstUtility = replicatedStorageShared.Utility
local enumsFolder = replicatedStorageShared.Enums

local PlayerPermission = require(replicatedFirstUtility.PlayerPermission)
local PlayerPermissionLevel = require(enumsFolder.PlayerPermissionLevel)

local GROUPS = {
    ["DefaultAdmin"] = PlayerPermissionLevel.admin,
    ["DefaultDebug"] = PlayerPermissionLevel.admin,
    ["DefaultUtil"] = PlayerPermissionLevel.admin,
    ["Help"] = PlayerPermissionLevel.moderator,
    ["UserAlias"] = PlayerPermissionLevel.admin
}

return function(registry)
    registry:RegisterHook("BeforeRun", function(context)
        local player = context.Executor
        local group = context.Group
        local groupPermissionLevel = GROUPS[group]

        if not groupPermissionLevel or not PlayerPermission.hasPermission(player, groupPermissionLevel) then
            return "You do not have permission to run this command lol :)"
        end
    end)
end