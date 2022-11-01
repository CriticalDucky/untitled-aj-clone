local RETRY_DELAY = 0.5
local MAX_RETRIES = 10

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local serverManagement = serverStorageShared.ServerManagement
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local LocalServerInfo = require(serverFolder.LocalServerInfo)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local PlayerLocation = require(serverManagement.PlayerLocation)
local WorldData = require(serverManagement.WorldData)
local GameServerData = require(serverManagement.GameServerData)
local Table = require(replicatedFirstShared.Utility.Table)
local Fingerprint = require(serverStorageShared.Utility.Fingerprint)
local LocalWorldOrigin = require(serverFolder.LocalWorldOrigin)

local Teleport = {}

local function safeTeleport(destination, players, options)
    local attemptIndex = 0
    local teleportResult
    local success
 
    local teleportFailConnection = TeleportService.TeleportInitFailed:Connect(function(player, reason)
        if table.find(players, player) then -- If the player is in the list of players to teleport
            teleportResult = reason
        end
    end)

    repeat
        success = pcall(function()
            return TeleportService:TeleportAsync(destination, players, options)
        end)

        attemptIndex += 1

        if not success then
            task.wait(RETRY_DELAY)
        end
    until success or attemptIndex == MAX_RETRIES

    teleportFailConnection:Disconnect()

    return success, teleportResult
end

function Teleport.teleport(players, placeId, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    if type(players) ~= "table" then
        players = {players}
    end

    return safeTeleport(placeId, players, teleportOptions)
end

function Teleport.teleportToLocation(player, locationEnum, worldIndex)
    if not locationEnum then
        print("Teleport.teleportToLocation: locationEnum is nil")
        return false
    end

    local worlds = WorldData.get()

    if not worlds then
        warn("Teleport.teleportToLocation: WorldData is nil")
        return false
    end

    local locationInfo = Locations.info[locationEnum]
    local teleportOptions = Instance.new("TeleportOptions")

    if worldIndex then
        local world = worlds[worldIndex]
        local location = world.locations[locationEnum]

        local populationInfo = GameServerData.getLocationPopulationInfo(worldIndex, locationEnum)

        if populationInfo and populationInfo.max_emptySlots == 0 then
            warn("Teleport.teleportToLocation: location is full")
            return false
        end

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
    else
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
            local currentWorldIndex, currentLocation do
                if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
                    local localWorldInfo = require(ServerStorage.Location.ServerManagement.LocalWorldInfo)
                    
                    currentWorldIndex = localWorldInfo.worldIndex
                    currentLocation = localWorldInfo.locationEnum
                elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
                    currentWorldIndex = LocalWorldOrigin(player) or WorldData.findAvailableWorld()
                end
            end

            local populationInfo = GameServerData.getLocationPopulationInfo(currentWorldIndex, locationEnum)

            if populationInfo and populationInfo.max_emptySlots == 0 then
                warn("Teleport.teleportToLocation: location is full")
                return false
            end
            
            local location = worlds[currentWorldIndex].locations[locationEnum]

            teleportOptions.ReservedServerAccessCode = location.serverCode
            teleportOptions:SetTeleportData({
                locationFrom = currentLocation,
                worldIndexOrigin = currentWorldIndex
            })

            return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
        else
            warn("Cannot teleport to location from an 'oblivious' server")
            return false
        end
    end
end

function Teleport.teleportToWorld(player, worldIndex)
    local worlds = WorldData.get()

    if not worlds then
        warn("Teleport.teleportToWorld: WorldData is nil")
        return false
    end

    local world = worlds[worldIndex]

    if not world then
        warn("Teleport.teleportToWorld: world is nil")
        return false
    end

    local locationEnum = WorldData.findAvailableLocation(worldIndex)

    if not locationEnum then
        warn("Teleport.teleportToWorld: no available locations")
        return false
    end

    local teleportSuccess = Teleport.teleportToLocation(player, locationEnum, worldIndex)

    if not teleportSuccess then
        warn("Teleport.teleportToWorld: teleport failed")
        return false
    end

    return true
end

function Teleport.teleportToParty(player, partyType, privateServerId)
    local teleportOptions = Instance.new("TeleportOptions")

    local code

    if not privateServerId then -- Look for the party, with the given party type, that has the highest player count
        local slots = {
            -- [privateServerId] = number of open slots
        }

        for serverId, _ in pairs(GameServerData.getPartyServers(partyType)) do
            local populationInfo = GameServerData.getPartyPopulationInfo(partyType, serverId)

            slots[serverId] = if populationInfo then populationInfo.recommended_emptySlots else nil

            if slots[serverId] == 0 then
                slots[serverId] = nil
            end
        end

        privateServerId = Table.findMin(slots)
        Table.print(slots)

        if not privateServerId then
            print("Teleport.teleportToParty: no available party servers")

            local success

            success, code, privateServerId = pcall(function()
                return TeleportService:ReserveServer(Parties[partyType].placeId)
            end)

            if not success or not privateServerId then
                warn("Teleport.teleportToParty: Failed to reserve server: " .. code)
                return false
            end

            local success = Fingerprint.stamp(privateServerId, code)

            if not success then
                warn("Teleport.teleportToParty: Failed to stamp server")
                return false
            end

            teleportOptions.ReservedServerAccessCode = code
        end
    end

    local populationInfo = GameServerData.getPartyPopulationInfo(partyType, privateServerId)

    if populationInfo and populationInfo.recommended_emptySlots == 0 then
        warn("Teleport.teleportToParty: party is full")
        return false
    end
    
    code = code or GameServerData.getPartyCode(privateServerId)

    if not code then
        warn("Teleport.teleportToParty: code is nil")
        return false
    end

    teleportOptions.ReservedServerAccessCode = code

    local worldIndex do
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
            local serverStorageLocation = ServerStorage.Location
            local locationServerManagement = serverStorageLocation.ServerManagement
            local LocalWorldInfo = require(locationServerManagement.LocalWorldInfo)
    
            worldIndex = LocalWorldInfo.worldIndex
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
            worldIndex = LocalWorldOrigin(player) or WorldData.findAvailableWorld()
        elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
            worldIndex = WorldData.findAvailableWorld()
        end
    end

    teleportOptions:SetTeleportData({
        worldIndexOrigin = worldIndex,
    })

    return Teleport.teleport(player, Parties[partyType].placeId, teleportOptions)
end

function Teleport.teleportToPlayer(player: Player, targetPlayerId)
    local targetPlayerLocation = PlayerLocation.get(targetPlayerId)

    if not targetPlayerLocation then
        print("Target player is not playing")
        return false
    end

    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, targetPlayerLocation.serverType) then
        local populationInfo = GameServerData.getLocationPopulationInfo(targetPlayerLocation.worldIndex, targetPlayerLocation.locationEnum)
        
        if not populationInfo then
            print("Target player is unable to be teleported to")
            return false
        end

        if populationInfo.max_emptySlots == 0 then
            print("Target player's location is full")
            return false
        end

        local locationInfo = Locations.info[targetPlayerLocation.locationEnum]

        if locationInfo.cantJoinPlayer then
            print("Target player's location cannot be joined")
            return false
        end

        return Teleport.teleportToLocation(
            player,
            targetPlayerLocation.locationEnum,
            targetPlayerLocation.worldIndex
        )
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, targetPlayerLocation.serverType) then
        local populationInfo = GameServerData.getPartyPopulationInfo(targetPlayerLocation.partyType, targetPlayerLocation.privateServerId)
        
        if not populationInfo then
            print("Target player is unable to be teleported to")
            return false
        end

        if populationInfo.recommended_emptySlots == 0 then
            print("Target player's party is full")
            return false
        end

        return Teleport.teleportToParty(
            player,
            targetPlayerLocation.partyType,
            targetPlayerLocation.privateServerId
        )
    else
        print("Target player is not in a supported server type")
        return false
    end
end

function Teleport.rejoin(players, options)
    local teleportOptions = options or Instance.new("TeleportOptions")

    return Teleport.teleport(players, 10189729412, teleportOptions)
end

return Teleport