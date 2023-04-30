local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicatedFirstUtility = replicatedFirstShared:WaitForChild("Utility")
local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums")

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local PlayerPermission = require(replicatedFirstUtility:WaitForChild("PlayerPermission"))
local PlayerPermissionLevel = require(enumsFolder:WaitForChild("PlayerPermissionLevel"))

if PlayerPermission.hasPermission(Players.LocalPlayer, PlayerPermissionLevel.moderator) then
    Cmdr:SetActivationKeys({Enum.KeyCode.F2})
end
