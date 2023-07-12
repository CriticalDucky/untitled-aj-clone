-- local REPLICATION_COOLDOWN = 0.5

--#region Imports

local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local PlayerDataManager = if isServer then require(ServerStorage.Data.PlayerDataManager) else nil
local StateClient = if not isServer then require(script.Parent.StateClient) else nil

--#endregion

--#region State Replication Event

local stateReplicationEvent

if isServer then
	stateReplicationEvent = Instance.new "RemoteEvent"
	stateReplicationEvent.Name = "StateReplicationEvent"
	stateReplicationEvent.Parent = script
else
	stateReplicationEvent = script:WaitForChild "StateReplicationEvent"
end

--#endregion

local StateReplication = {}

--[[
	Replicates the given action(s) to the server or specified client (depending on where this function was called).

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function StateReplication.replicate(actions: table, player: Player?)
	if isServer and not player then
		warn "Player parameter is missing, so no actions will be replicated."
		return
	elseif not isServer and player then
		warn "Player parameter is unnecessary on the client, so it will be ignored."
	end

	if isServer then
		stateReplicationEvent:FireClient(player, actions)
	else
		stateReplicationEvent:FireServer(actions)
	end
end

--[[
	
]]

return StateReplication
