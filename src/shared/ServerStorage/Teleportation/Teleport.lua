local RETRY_DELAY = 10
local MAX_RETRIES = 4

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local replicatedStorageShared = ReplicatedStorage.Shared
local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedFirstUtility = replicatedFirstShared.Utility
local serverManagement = serverStorageShared.ServerManagement
local serverFolder = replicatedStorageShared.Server
local enumsFolder = replicatedStorageShared.Enums
local serverUtility = serverStorageShared.Utility
local teleportationFolder = serverStorageShared.Teleportation

local Locations = require(serverFolder.Locations)
local Parties = require(serverFolder.Parties)
local Games = require(serverFolder.Games)
local ServerGroupEnum = require(enumsFolder.ServerGroup)
local ServerTypeGroups = require(serverFolder.ServerTypeGroups)
local PlayerLocation = require(serverUtility.PlayerLocation)
local ServerData = require(serverManagement.ServerData)
local LiveServerData = require(serverFolder.LiveServerData)
local Table = require(replicatedFirstUtility.Table)
local LocalWorldOrigin = require(serverFolder.LocalWorldOrigin)
local HomeManager = require(serverStorageShared.Data.Inventory.HomeManager)
local HomeLockType = require(enumsFolder.HomeLockType)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)
local TeleportTicket = require(teleportationFolder.TeleportTicket)

local function getWorldIndexOrigin(player)
    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation) then
        local LocalWorldInfo = require(ReplicatedStorage.Location.Server.LocalWorldInfo)

        return LocalWorldInfo.worldIndex, LocalWorldInfo.locationEnum
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldOrigin) then
        return LocalWorldOrigin(player) or ServerData.findAvailableWorld()
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isRouting) then
        return ServerData.findAvailableWorld()
    end
end

local Teleport = {}

function Teleport.toLocation(player, locationEnum, worldIndex)
    if not locationEnum then
        print("Teleport.teleportToLocation: locationEnum is nil")
        return false
    end

    local worlds = ServerData.getWorlds()

    if not worlds then
        warn("Teleport.teleportToLocation: WorldData is nil")
        return false
    end

    local locationInfo = Locations.info[locationEnum]
    local teleportOptions = Instance.new("TeleportOptions")

    if worldIndex then
        local world = worlds[worldIndex]
        local location = world.locations[locationEnum]

        if not location then
            warn("Teleport.teleportToLocation: Location " .. locationEnum .. " does not exist in world " .. worldIndex)
            return false
        end

        if LiveServerData.isLocationFull(worldIndex, locationEnum) then
            warn("Teleport.teleportToLocation: location is full")
            return false
        end

        teleportOptions.ReservedServerAccessCode = location.serverCode

        return TeleportTicket.new(player, locationInfo.placeId, teleportOptions)
    else
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
            local currentWorldIndex, currentLocation = getWorldIndexOrigin(player)

            if LiveServerData.isLocationFull(currentWorldIndex, locationEnum) then
                warn("Teleport.teleportToLocation: location is full")
                return false
            end
            --*
            local location = worlds[currentWorldIndex].locations[locationEnum]

            if not location then
                warn("Teleport.teleportToLocation: location is nil")
                return false
            end

            teleportOptions.ReservedServerAccessCode = location.serverCode
            teleportOptions:SetTeleportData({
                locationFrom = currentLocation,
                worldIndexOrigin = currentWorldIndex
            })

            return TeleportTicket.new(player, locationInfo.placeId, teleportOptions)
        else
            warn("Cannot teleport to location from an 'oblivious' server")
            return false
        end
    end
end

function Teleport.toWorld(player, worldIndex)
    local worlds = ServerData.getWorlds()

    if not worlds then
        warn("Teleport.teleportToWorld: WorldData is nil")
        return false
    end

    local world = worlds[worldIndex]

    if not world then
        warn("Teleport.teleportToWorld: world is nil")
        return false
    end

    local locationEnum = ServerData.findAvailableLocation(worldIndex)

    if not locationEnum then
        warn("Teleport.teleportToWorld: no available locations")
        return false
    end

    return Teleport.toLocation(player, locationEnum, worldIndex)
end

function Teleport.toParty(player, partyType, partyIndex)
    local teleportOptions = Instance.new("TeleportOptions")

    partyIndex = partyIndex or ServerData.findAvailableParty(partyType)

    if not partyIndex then
        warn("Teleport.teleportToParty: party find error")
        return false
    end

    if LiveServerData.isPartyFull(partyType, partyIndex) then
        warn("Teleport.teleportToParty: party is full")
        return false
    end

    local code = Table.safeIndex(ServerData.getParties(), partyType, partyIndex, "serverCode")

    if not code then
        warn("Teleport.teleportToParty: code is nil")
        return false
    end

    teleportOptions.ReservedServerAccessCode = code
    teleportOptions:SetTeleportData({
        worldIndexOrigin = getWorldIndexOrigin(player),
    })

    return Teleport.teleport(player, Parties[partyType].placeId, teleportOptions)
end

function Teleport.toHome(player: Player, homeOwnerUserId)
    if player.UserId ~= homeOwnerUserId then
        if LiveServerData.isHomeFull(homeOwnerUserId) then
            warn("Teleport.teleportToHome: home is full")
            return false
        end

        local homeLockType = HomeManager.getLockStatus(homeOwnerUserId)

        if homeLockType == HomeLockType.locked then
            warn("Teleport.teleportToHome: home is private")
            return false
        end

        local success, isFriendsWith = pcall(function()
            return player:IsFriendsWith(homeOwnerUserId)
        end)

        if not success then
            warn("Teleport.teleportToHome: failed to check friendship")
            return false
        end

        if homeLockType == HomeLockType.friendsOnly and not isFriendsWith then
            warn("Teleport.teleportToHome: home is friends only")
            return false
        end
    end

    local homeServerInfo = HomeManager.getHomeServerInfo(homeOwnerUserId)

    if not homeServerInfo then
        warn("Teleport.teleportToHome: home server info is nil")
        return false
    end

    if not HomeManager.isHomeInfoStamped(homeOwnerUserId) then
        local success = ServerData.stampHomeServer(homeOwnerUserId)

        if not success then
            warn("Teleport.teleportToHome: failed to stamp home server")
            return false
        end
    end

    local teleportOptions = Instance.new("TeleportOptions")

    teleportOptions.ReservedServerAccessCode = homeServerInfo.serverCode

    local worldIndex = getWorldIndexOrigin(player)

    teleportOptions:SetTeleportData({
        worldIndexOrigin = worldIndex,
    })

    return Teleport.teleport(player, GameSettings.homePlaceId, teleportOptions)
end

function Teleport.toGame(players, gameType, privateServerId)
    players = if type(players) == "table" then players else {players}


end

function Teleport.toPlayer(player: Player, targetPlayerId)
    local targetPlayerLocation = PlayerLocation.get(targetPlayerId)

    if not targetPlayerLocation then
        print("Target player is not playing")
        return false
    end

    if ServerTypeGroups.serverInGroup(ServerGroupEnum.isLocation, targetPlayerLocation.serverType) then
        if not LiveServerData.getLocationPopulationInfo(targetPlayerLocation.worldIndex, targetPlayerLocation.locationEnum) then
            print("Target player's location is full")
            return false
        end

        local locationInfo = Locations.info[targetPlayerLocation.locationEnum]

        if locationInfo.cantJoinPlayer then
            print("Target player's location cannot be joined")
            return false
        end

        return Teleport.toLocation(
            player,
            targetPlayerLocation.locationEnum,
            targetPlayerLocation.worldIndex
        )
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, targetPlayerLocation.serverType) then
        if not LiveServerData.getPartyPopulationInfo(targetPlayerLocation.partyType, targetPlayerLocation.partyIndex) then
            print("Target player's party is full")
            return false
        end

        return Teleport.toParty(
            player,
            targetPlayerLocation.partyType,
            targetPlayerLocation.partyIndex
        )
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isHome, targetPlayerLocation.serverType) then
        local homeOwnerUserId = targetPlayerLocation.homeOwner

        local populationInfo = LiveServerData.getHomePopulationInfo(homeOwnerUserId)
        
        if not populationInfo then
            print("Target player is unable to be teleported to")
            return false
        end

        return Teleport.toHome(
            player,
            homeOwnerUserId
        )
    else
        print("Target player is not in a supported server type")
        return false
    end
end

function Teleport.rejoin(players, reason)
    local teleportOptions = Instance.new("TeleportOptions")

    if reason then
        teleportOptions:SetTeleportData({
            rejoinReason = reason,
        })
    end

    return Teleport.teleport(players, 10189729412, teleportOptions)
end

local serverBootingEnabled = false

function Teleport.bootServer(reason)
    if not serverBootingEnabled then
        error("SERVER BOOT: " .. reason)
        return false
    end

    local rejoinFailedText = "[REJOIN FAILED] " .. (reason or "Unspecified reason")

    if not Teleport.rejoin(Players:GetPlayers(), reason) then
        for _, player in ipairs(Players:GetPlayers()) do
            player:Kick(rejoinFailedText)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if not Teleport.rejoin(player, reason) then
            player:Kick(rejoinFailedText)
        end
    end)
end

return Teleport