local MAX_RECOMMENDED_PLAYERS = 20
local MIN_RECOMMENDED_PLAYERS = 15

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverStorageShared = ServerStorage:WaitForChild("Shared")
local serverStorageLocation = ServerStorage:WaitForChild("Location")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local serverManagementShared = serverStorageShared:WaitForChild("ServerManagement")
local serverManagementLocation = serverStorageLocation:WaitForChild("ServerManagement")
local Teleportation = serverStorageShared:WaitForChild("Teleportation")

local ServerData = require(serverManagementShared:WaitForChild("ServerData"))
local Teleport = require(Teleportation:WaitForChild("Teleport"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))
local LocalWorldInfo = require(serverManagementLocation:WaitForChild("LocalWorldInfo"))

local Fusion = require(replicatedStorageShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local playerCount = Value(FillStatusEnum.notFilled)
local fillStatusValue = Value(FillStatusEnum.notFilled)

local function reroutePlayer(player)
    local world = ServerData.findAvailableWorldAndLocation(LocalWorldInfo.locationEnum)

    if world then
        local teleportSuccess = Teleport.teleportToLocation({player}, LocalWorldInfo.locationEnum, world)

        if teleportSuccess then
            return true
        else
            warn("Failed to teleport player to world")
            return false
        end
    else
        warn("No available world found")
    end
end

local function onPlayerCountChanged()
    local currentPlayers = Players:GetPlayers()
    playerCount = #currentPlayers

    if fillStatusValue:get() == FillStatusEnum.notFilled then
        if playerCount >= MAX_RECOMMENDED_PLAYERS then
            fillStatusValue:set(FillStatusEnum.filled)
        end
    elseif fillStatusValue:get() == FillStatusEnum.filled then
        if playerCount <= MIN_RECOMMENDED_PLAYERS then
            fillStatusValue:set(FillStatusEnum.notFilled)
        end
    end
end

local function playerAdded(player)
    if playerCount + 1 > MAX_RECOMMENDED_PLAYERS then
        local success = reroutePlayer(player)

        if not success then
            player:Kick("Placement error; server is full")
        end

        return
    end 

    onPlayerCountChanged()
end

for _, player in Players:GetPlayers() do
    playerAdded(player)
end

Observer(fillStatusValue):onChange(function()
    ServerData.update(function(serverData)
        local worlds = serverData.worlds
        local world = worlds[LocalWorldInfo.worldIndex]
        local location = world.locations[LocalWorldInfo.locationEnum]

        location.fillStatus = fillStatusValue:get()

        return serverData
    end)
end)

Players.PlayerAdded:Connect(playerAdded)
Players.ChildRemoved:Connect(onPlayerCountChanged)
