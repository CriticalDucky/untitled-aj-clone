local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local UIFolder = replicatedFirstShared:WaitForChild "UI"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local requestsFolder = replicatedStorageShared:WaitForChild "Requests"

local Component = require(utilityFolder:WaitForChild "GetComponent")
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local ReplicatedServerData = require(serverFolder:WaitForChild "ReplicatedServerData")
local LiveServerData = require(serverFolder:WaitForChild "LiveServerData")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local WorldNames = require(serverFolder:WaitForChild "WorldNames")
local ServerGroupEnum = require(enumsFolder:WaitForChild "ServerGroup")
local ServerTypeGroups = require(serverFolder:WaitForChild "ServerTypeGroups")
local ClientTeleport = require(requestsFolder:WaitForChild("Teleportation"):WaitForChild "ClientTeleport")
local WorldOrigin = require(serverFolder:WaitForChild "WorldOrigin")
local Promise = require(utilityFolder:WaitForChild "Promise")
local Table = require(utilityFolder:WaitForChild "Table")

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
local Cleanup = Fusion.Cleanup

local component = function(props)
	local open = Value(false)
	local enabled = Value(false)

	local worldButtons = {}

	Promise.all({
		Promise.new(function(resolve)
			LocalServerInfo.getServerIdentifier()
			resolve()
		end),

		Promise.new(function(resolve)
			LiveServerData.initialWait()
			resolve()
		end),
	}):andThen(function()
		enabled:set(true)
	end)

	local function button(buttonProps: table)
		return New "TextButton" {
			Size = buttonProps.size or UDim2.fromOffset(50, 50),
			LayoutOrder = buttonProps.layoutOrder or 1,
			Visible = buttonProps.visible or true,

			Text = buttonProps.text or "Worlds",
			Font = Enum.Font.Gotham,
			TextSize = 18,

			[OnEvent "MouseButton1Click"] = function()
				local onClick = buttonProps.onClick
				local enabled = buttonProps.enabled

				if onClick then onClick() end

				if enabled then enabled:set(not enabled:get()) end
			end,

			[Children] = {
				New "UICorner" {
					CornerRadius = UDim.new(0, 5),
				},

				buttonProps.children,
			},
		}
	end

	local function worldButton(worldIndex)
		local errored = Value(false)
		local layoutOrder = Value(0)

		Observer(open):onChange(function()
			if open:get() then
 layoutOrder:set(worldIndex - LiveServerData.getWorldPopulation(worldIndex) * 10000) end
		end)

		local button = button {
			onClick = function()
				local success, response = ClientTeleport.toWorld(worldIndex)

				if not success then
					errored:set(true)
					warn("Failed to teleport to world " .. worldIndex .. ": ", response)
				end
			end,
			layoutOrder = layoutOrder,
			text = WorldNames.get(worldIndex),
			size = UDim2.new(1, 0, 0, 50),
			visible = Computed(function()
				local currentWorlds = ReplicatedServerData.getWorlds()

				if not currentWorlds then return false end

				local isFirstThreeEmptyWorlds = false
				do
					local emptyWorlds = 0

					for index, _ in ipairs(currentWorlds) do
						if LiveServerData.getWorldPopulation(index) == 0 then
							emptyWorlds += 1
						end

						if index == worldIndex then
							isFirstThreeEmptyWorlds = true
							break
						end

						if emptyWorlds >= 3 then break end
					end
				end

				local isDifferentWorld
				do
					if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
						local serverIdentifier = LocalServerInfo.getServerIdentifier()

						if serverIdentifier then
							isDifferentWorld = serverIdentifier.worldIndex ~= worldIndex
						else
							isDifferentWorld = true
						end
					elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
						local worldOrigin = WorldOrigin.get()

						if worldOrigin then
							isDifferentWorld = worldOrigin ~= worldIndex
						else
							isDifferentWorld = true
						end
					else
						isDifferentWorld = true
					end
				end

				return (
					(isFirstThreeEmptyWorlds or (LiveServerData.getWorldPopulation(worldIndex) ~= 0))
					and isDifferentWorld
					and true
				) or false
			end),

			children = {
				New "TextLabel" {
					Size = UDim2.new(0, 50, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,

					Text = Computed(function()
						return LiveServerData.getWorldPopulation(worldIndex)
					end),
					TextColor3 = Computed(function()
						return if errored:get() then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(0, 0, 0)
					end),
					Font = Enum.Font.Gotham,
				},
			},
		}

		return button
	end

	local worldButtons = Computed(function()
		local currentWorlds = ReplicatedServerData.getWorlds()

		if currentWorlds then
			for i, _ in ipairs(currentWorlds) do
				worldButtons[i] = worldButtons[i] or worldButton(i)
			end
		end

		return worldButtons
	end)

	local menu = Component "DefaultElementList" {
		open = open,
		elements = worldButtons,
	}

	local button = button {
		onClick = function()
			open:set(not open:get())
		end,
		text = "Worlds",
		size = UDim2.fromOffset(75, 75),
		layoutOrder = props.layoutOrder or 1,
		visible = enabled,
	}

	return menu, button
end

return component
