local ReplicatedFirst = game:GetService("ReplicatedFirst")

local Types = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Types"))

type Promise = Types.Promise

local ReplicaResponse = {}

--[[
    This function is used for replica responses on a server. Pass in a Replica,
	and a callback that takes a player and any number of arguments, and returns a Promise.
	
	When the replica is fired, the callback will be called with the player and the arguments.
	Values returned from the callback will be passed to the client.
]]
function ReplicaResponse.listen(requestReplica, callback: (Player, any) -> Promise)
	requestReplica:ConnectOnServerEvent(function(player, requestCode, ...)
		local function onResponse(...)
			requestReplica:FireClient(player, requestCode, ...)
		end

		callback(player, ...)
			:andThen(onResponse)
			:catch(onResponse)
	end)
end

return ReplicaResponse
