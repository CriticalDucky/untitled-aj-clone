local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local UIFolder = replicatedFirstShared:WaitForChild("UI")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local requestsFolder = replicatedStorageShared:WaitForChild("Requests")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild("ClientTeleport"))
local ServerTypeGroups = require(serverFolder:WaitForChild("ServerTypeGroups"))
local ServerGroupEnum = require(enumsFolder:WaitForChild("ServerGroup"))

local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local player = Players.LocalPlayer

local component = function(props)
    local visible = true

    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
        local LocalHomeInfo = require(ReplicatedStorage.Home.Server.LocalHomeInfo)

        visible = if player.UserId == LocalHomeInfo.homeOwner then false else visible
    end

    return New "TextButton" {
        Size = UDim2.fromOffset(75, 75),
        LayoutOrder = 50,
        Visible = visible,

        Text = "Home",
        Font = Enum.Font.Gotham,
        TextSize = 18,

        [OnEvent "MouseButton1Click"] = function()
            ClientTeleport.toHome(player.UserId)
        end,

        [Children] = {
            New "UICorner" {
                CornerRadius = UDim.new(0, 5)
            },
        },
    }
end

return component