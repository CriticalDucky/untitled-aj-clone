--#region Imports

local RunService = game:GetService "RunService"

local isServer = RunService:IsServer()

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

	`action` is the name of the action to register. This is the name that will be used when replicating the action.

	`handler` is the function that will be called when the action is replicated. On the server, the first parameter is
	the player that replicated the action, while the second parameter is the action data. On the client, the first and
	only parameter is the action data.

	---

	This function is available on both the client and server. The context of where this function is called determines
	whether the action is registered in that context only. For replication to work, the action must be registered in
	both contexts. (Requests will queue if necessary.)

	An action can only be registered once per context. Attempting to register an action again will fail.

	On the client, this function will yield until the action is registered on the server.
]]
function StateReplication.registerActionAsync(action: string, handler: (Player, any) -> () | (any) -> ())
	if stateReplicationEvents[action] then
		warn("Action '" .. action .. "' is already registered. You cannot reregister an action.")
		return
	end

	if isServer then
		local replicationEvent = Instance.new "RemoteEvent"
		replicationEvent.Name = action
		replicationEvent.OnServerEvent:Connect(handler)
		replicationEvent.Parent = script
		stateReplicationEvents[action] = replicationEvent
	else
		local replicationEvent = script:WaitForChild(action)
		replicationEvent.OnClientEvent:Connect(handler)
		stateReplicationEvents[action] = replicationEvent
	end
end

return StateReplication
