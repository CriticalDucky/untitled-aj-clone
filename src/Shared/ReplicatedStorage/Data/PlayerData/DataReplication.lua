--#region Imports

local RunService = game:GetService "RunService"
local ServerStorage = game:GetService "ServerStorage"

local isServer = RunService:IsServer()

local PlayerDataManager = if isServer
	then require(ServerStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild "PlayerDataManager")
	else nil

--#endregion

--#region State Replication Management

local stateReplicationEvents: { string: RemoteEvent } = {}

--#endregion

--[[
	Manages state replication. This is used to replicate state changes from the server to the client and vice versa.
]]
local StateReplication = {}

--[[
	Replicates the given action(s) to the server or specified client (depending on where this function was called).

	`action` is the name of the action to replicate.

	`data` is the data to replicate with the action. This can be any replicatable value.

	---

	Actions must be registered before they can be replicated; otherwise, they will be ignored. See
	`StateReplication.registerActionAsync` for more information.

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function StateReplication.replicate(action: string, data: any, player: Player?)
	if isServer and not player then
		warn "Player parameter is missing, so no actions will be replicated."
		return
	elseif not isServer and player then
		warn "Player parameter is unnecessary on the client, so it will be ignored."
	end

	local handler = stateReplicationEvents[action]

	if handler then
		if isServer then
			handler:FireClient(player, data)
		else
			handler:FireServer(data)
		end
	else
		warn("Action '" .. action .. "' is not registered, so this replication request will be ignored.")
	end
end

--[[
	Registers a state replication action. This adds it to the list of actions that can be replicated and sets up the
	handler function that will be called when the action is replicated to this context.

	---

	`name` is the name of the action to register. This is the name that will be used when replicating the action.

	`handler` is the function that will be called when the action is replicated. On the server, the first parameter is
	the player that replicated the action, while the second parameter is the action data. On the client, the first and
	only parameter is the action data.

	---

	This function is available on both the client and server. The context of where this function is called determines
	whether the action is registered in that context only. For replication to work, the action must be registered in
	both contexts. (Requests will queue if necessary.)

	An action can only be registered once per context. Attempting to register an action again will fail.

	On the client, this function will yield until the action is registered on the server.

	When registering an action on the server, the provided handler should ensure that the given data is valid. If
	it is not, it should not accept the request and instead send a replication request back to the client with the
	current data to resync.

	On the server, you can assume that the player's persistent data is loaded when the handler is called. (This is
	because the inverse should never happen; and if it somehow does, the handler will automatically be ignored.)
]]
function StateReplication.registerActionAsync(name: string, handler: (Player, any) -> () | (any) -> ())
	if stateReplicationEvents[name] then
		warn("Action '" .. name .. "' is already registered. You cannot reregister an action.")
		return
	end

	if isServer then
		local replicationEvent = Instance.new "RemoteEvent"
		replicationEvent.Name = name
		replicationEvent.OnServerEvent:Connect(function(player, ...)
			if not PlayerDataManager.persistentDataIsLoaded(player) then return end

			handler(player, ...)
		end)
		replicationEvent.Parent = script
		stateReplicationEvents[name] = replicationEvent
	else
		local replicationEvent = script:WaitForChild(name)
		replicationEvent.OnClientEvent:Connect(handler)
		stateReplicationEvents[name] = replicationEvent
	end
end

return StateReplication
