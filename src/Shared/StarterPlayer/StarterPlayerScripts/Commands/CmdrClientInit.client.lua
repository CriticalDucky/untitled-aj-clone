local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local utilityFolder = replicatedStorageShared:WaitForChild("Utility")
local enumsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Enums")

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local PlayerPermission = require(utilityFolder:WaitForChild("PlayerPermission"))
local PlayerPermissionLevel = require(enumsFolder:WaitForChild("PlayerPermissionLevel"))

if PlayerPermission.hasPermission(Players.LocalPlayer, PlayerPermissionLevel.moderator) then
    Cmdr:SetActivationKeys({Enum.KeyCode.F2})
end
