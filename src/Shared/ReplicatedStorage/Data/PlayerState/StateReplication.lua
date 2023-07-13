--#region Imports

local RunService = game:GetService "RunService"

local isServer = RunService:IsServer()

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

--#region State Replication Handling

local stateReplicationHandlers: { string: (Player, any) -> () | (any) -> () } = {}

local queuedStateChanges: { string: any } | { Player: { string: any } } = {}

if isServer then
	stateReplicationEvent.OnServerEvent:Connect(function(player, actions: { string: any })
		for action: string, data in actions do
			local handler = stateReplicationHandlers[action]

			if handler then
				handler(player, data)
			else
				local playerQueuedStateChanges = queuedStateChanges[player] or {}
				queuedStateChanges[player] = playerQueuedStateChanges

				playerQueuedStateChanges[action] = data
			end
		end
	end)
else
	stateReplicationEvent.OnClientEvent:Connect(function(actions: { string: any })
		for action: string, data in actions do
			local handler = stateReplicationHandlers[action]

			if handler then
				handler(data)
			else
				queuedStateChanges[action] = data
			end
		end
	end)
end

--#endregion

--[[
	Manages state replication. This is used to replicate state changes from the server to the client and vice versa.
]]
local StateReplication = {}

--[[
	Replicates the given action(s) to the server or specified client (depending on where this function was called).

	`actions` is a dictionary of actions to replicate. The key is the action name and the value is the action data. You
	may pass as many actions as you want.

	*The player parameter is **required** on the server and **ignored** on the client.*
]]
function StateReplication.replicate(actions: { string: any }, player: Player?)
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
	Registers a state replication action, allowing it to be handled.

	`action` is the name of the action to register. This is the name that will be used when replicating the action.

	`handler` is the function that will be called when the action is replicated. On the server, the first parameter is
	the player that replicated the action, while the second parameter is the action data. On the client, the first and
	only parameter is the action data.

	This function is available on both the client and server. The context of where this function is called determines
	whether the action is registered to be handled on the client or server.

	An action can only be registered once per context. Attempting to register an action again will fail.
]]
function StateReplication.registerAction(action: string, handler: (Player, any) -> () | (any) -> ())
	if stateReplicationHandlers[action] then
		warn("Action '" .. action .. "' is already registered.")
		return
	end

	stateReplicationHandlers[action] = handler

	if isServer then
		

	local queuedStateChange = queuedStateChanges[action]

	if queuedStateChange then
		handler(queuedStateChange)
		queuedStateChanges[action] = nil
	end
end

return StateReplication
