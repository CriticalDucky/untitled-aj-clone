local RETRY_DELAY = 10
local MAX_RETRIES = 4
local TELEPORT_TIMEOUT = 20

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
local Event = require(replicatedFirstUtility.Event)

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

local teleportTickets = {}
local TeleportTicket = {}
TeleportTicket.__index = TeleportTicket

function TeleportTicket.new(players, placeId, teleportOptions: TeleportOptions)
    assert(players, "TeleportTicket.new: No players provided")
    assert(placeId, "TeleportTicket.new: No placeId provided")
    assert(teleportOptions, "TeleportTicket.new: No teleportOptions provided")

    local self = setmetatable({}, TeleportTicket)

    self.players = if type(players) == "table" then players else {players}
    self.id = teleportOptions.ReservedServerAccessCode
    self.teleportOptions = teleportOptions
    self.placeId = placeId
    self.onErrored = Event.new()

    teleportTickets[self.id] = self

    return self
end

function TeleportTicket:use(players: table | Player | nil)
    players = players or self.players

    if typeof(players) == "Instance" then
        players = {players}
    end

    local options = self.teleportOptions
    local success, err = false, nil

    local function try()
        success, err = pcall(function()
            return TeleportService:TeleportAsync(self.placeId, players, options)
        end)
    end

    for i = 1, MAX_RETRIES do
        try()

        if success then
            break
        end

        warn(("Teleport attempt #%s failed: %s \nRetrying in %s seconds"):format(i, err, RETRY_DELAY))

        task.wait(RETRY_DELAY)
    end

    return if success then Enum.TeleportResult.Success else Enum.TeleportResult.Failure
end

function TeleportTicket:close()
    self.onErrored:Destroy()
    teleportTickets[self.id] = nil
end

local function safeTeleport(destination, players, options)
    local attemptIndex = 0
    local teleportResults
    local success
    local result

    while not success and attemptIndex < MAX_RETRIES do
        attemptIndex += 1

        local attemptComplete = false

        task.spawn(function()
            success, result = pcall(function()
                return TeleportService:TeleportAsync(destination, players, options)
            end)

            if success then
                local accessCode = result.ReservedServerAccessCode
                print(accessCode)
                success = (type(accessCode) == "string") and #accessCode > 0
            end

            warn("This happens")
            attemptComplete = true
        end)

        local startTime = time()
        local scrap

        local function areAnyPlayersInTeleportResponses()
            for _, player in pairs(players) do
                if teleportResponses[player] then
                    return true
                end
            end

            return false
        end

        local function clearPlayersFromTeleportResponses()
            for _, player in pairs(players) do
                teleportResponses[player] = nil
            end
        end

        print(attemptComplete == false, not areAnyPlayersInTeleportResponses(), not success)
        while attemptComplete == false and not areAnyPlayersInTeleportResponses() and not success do
            if time() - startTime > TELEPORT_TIMEOUT then
                scrap = true

                break
            end

            task.wait()
        end

        if scrap then
            warn("Teleport attempt #" .. attemptIndex .. " timed out")
            break
        end
        
        local function retry()
            teleportResults = Table.selectWithKeys(teleportResponses, players)
            clearPlayersFromTeleportResponses()

            task.wait(RETRY_DELAY)
        end

        if success and areAnyPlayersInTeleportResponses() then
            warn("A player did not go through the teleport process.")
               
            retry()
        elseif not success then
            warn("Teleport attempt #" .. attemptIndex .. " failed")
            
            retry()
        end
    end

    return success, teleportResults
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

        return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
    else
        if ServerTypeGroups.serverInGroup(ServerGroupEnum.hasWorldInfo) then
            local currentWorldIndex, currentLocation = getWorldIndexOrigin(player)

            if LiveServerData.isLocationFull(currentWorldIndex, locationEnum) then
                warn("Teleport.teleportToLocation: location is full")
                return false
            end
            
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

            return Teleport.teleport(player, locationInfo.placeId, teleportOptions)
        else
            warn("Cannot teleport to location from an 'oblivious' server")
            return false
        end
    end
end

function Teleport.teleportToWorld(player, worldIndex)
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

    local teleportSuccess = Teleport.teleportToLocation(player, locationEnum, worldIndex)

    if not teleportSuccess then
        warn("Teleport.teleportToWorld: teleport failed")
        return false
    end

    return true
end

function Teleport.teleportToParty(player, partyType, partyIndex)
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

function Teleport.teleportToHome(player: Player, homeOwnerUserId)
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

function Teleport.teleportToGame(players, gameType, privateServerId)
    players = if type(players) == "table" then players else {players}


end

function Teleport.teleportToPlayer(player: Player, targetPlayerId)
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

        return Teleport.teleportToLocation(
            player,
            targetPlayerLocation.locationEnum,
            targetPlayerLocation.worldIndex
        )
    elseif ServerTypeGroups.serverInGroup(ServerGroupEnum.isParty, targetPlayerLocation.serverType) then
        if not LiveServerData.getPartyPopulationInfo(targetPlayerLocation.partyType, targetPlayerLocation.partyIndex) then
            print("Target player's party is full")
            return false
        end

        return Teleport.teleportToParty(
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

        return Teleport.teleportToHome(
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

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage, _, teleportOptions: TeleportOptions)
    warn("TeleportInitFailed: " .. errorMessage)

    local id = teleportOptions.ReservedServerAccessCode
    local ticket = teleportTickets[id]

    if ticket then
        ticket.onErrored:Fire(player, teleportResult, errorMessage)
    end
end)

return Teleport