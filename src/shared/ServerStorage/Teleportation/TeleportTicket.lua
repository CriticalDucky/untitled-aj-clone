local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst.Shared
local replicatedFirstUtility = replicatedFirstShared.Utility

local Event = require(replicatedFirstUtility.Event)
local Table = require(replicatedFirstUtility.Table)
local GameSettings = require(replicatedFirstShared.Settings.GameSettings)

export type TeleportTicket = {
    players: table,
    teleportOptions: TeleportOptions,
    placeId: number,
    onError: table,
    use: (players: table | Player | nil) -> boolean,
    close: () -> nil,
    closeFor: (player: Player) -> nil,
}

local teleportTickets = {}

local function getTicketForPlayer(player)
    for _, ticket in pairs(teleportTickets) do
        if Table.indexOf(ticket.players, player) then
            return ticket
        end
    end
end

local TeleportTicket = {}
TeleportTicket.__index = TeleportTicket

function TeleportTicket.new(players, placeId, teleportOptions: TeleportOptions): TeleportTicket
    assert(players, "TeleportTicket.new: No players provided")
    assert(placeId, "TeleportTicket.new: No placeId provided")
    assert(teleportOptions, "TeleportTicket.new: No teleportOptions provided")

    for _, player in pairs(players) do
        assert(getTicketForPlayer(player) == nil, ("TeleportTicket.new: Player %s already has a teleport ticket"):format(player.Name))
    end

    local self = setmetatable({}, TeleportTicket)

    self.players = if type(players) == "table" then players else {players}
    self.teleportOptions = teleportOptions
    self.placeId = placeId
    self.onError = Event.new()

    table.insert(teleportTickets, self)

    return self
end

function TeleportTicket:use(players: table | Player | nil, onErrorCallback)
    players = players or self.players

    if typeof(players) == "Instance" then
        players = {players}
    end

    local options = self.teleportOptions
    local success, err = false, nil

    if onErrorCallback then
        self.onError:Connect(onErrorCallback)
    end

    local function try()
        success, err = pcall(function()
            return TeleportService:TeleportAsync(self.placeId, players, options)
        end)
    end

    for i = 1, GameSettings.teleport_maxRetries do
        try()

        if success then
            break
        end

        warn(("Teleport attempt #%s failed: %s \nRetrying in %s seconds"):format(i, err, GameSettings.teleport_retryDelay))

        task.wait(GameSettings.teleport_retryDelay)
    end

    return success
end

function TeleportTicket:close()
    self.onError:Destroy()

    local index = Table.indexOf(teleportTickets, self)

    if index then
        table.remove(teleportTickets, index)
    end
end

function TeleportTicket:closeFor(player)
    local index = Table.indexOf(self.players, player)

    if index then
        table.remove(self.players, index)
    end

    if #self.players == 0 then
        self:close()
    end
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
    warn("TeleportInitFailed: " .. errorMessage)

    local ticket = getTicketForPlayer(player)

    if ticket then
        ticket:closeFor(player)
        ticket.onError:Fire(player, teleportResult, errorMessage)
    else
        error("TeleportInitFailed: no ticket found for player. This should never happen and is an immediate concern.")
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local ticket = getTicketForPlayer(player)

    if ticket then
        ticket:closeFor(player)
    end
end)

return TeleportTicket