local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local UIFolder = replicatedFirstShared:WaitForChild "UI"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"

local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild "ClientTeleport")
local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
local ServerTypeGroups = require(serverFolder:WaitForChild "ServerTypeGroups")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ReponseType = require(enumsFolder:WaitForChild "ResponseType")
local Types = require(utilityFolder:WaitForChild "Types")

type ServerIdentifier = Types.ServerIdentifier

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
	local visible = Value(false)
	local errored = Value(false)

	if ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome) then
		ReplicatedServerData.getServerIdentifier():andThen(function(serverInfo: ServerIdentifier)
			visible:set(serverInfo.homeOwner ~= player.UserId)
		end)
	else
		visible:set "true"
	end

	return New "TextButton" {
		Size = UDim2.fromOffset(75, 75),
		LayoutOrder = 50,
		Visible = visible,
		BackgroundColor3 = Computed(function()
			if errored:get() then
				return Color3.fromRGB(255, 102, 102)
			else
				return Color3.fromRGB(255, 255, 255)
			end
		end),

		Text = "Home",
		Font = Enum.Font.Gotham,
		TextSize = 18,

		[OnEvent "MouseButton1Click"] = function()
			ClientTeleport.toHome(player.UserId):andThen(function(response)
				if response ~= ReponseType.success then
					warn("Failed to teleport to home:", response)
					errored:set(true)
				end
			end)
		end,

		[Children] = {
			New "UICorner" {
				CornerRadius = UDim.new(0, 5),
			},
		},
	}
end

return component
