local HttpService = game:GetService "HttpService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local Promise = require(ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild "Promise")

local ReplicaRequest = {}

function ReplicaRequest.new(replica, ...)
	assert(replica, "ReplicaRequest.new() called with nil replica")

	local varargs = { ... }

	return Promise.resolve():andThen(function()
		local requestCode = HttpService:GenerateGUID(false)
		local response

		local connection
		do
			connection = replica:ConnectOnClientEvent(function(returnedCode, ...)
				if returnedCode == requestCode then
					response = { ... }
					connection:Disconnect()
				end
			end)
		end

		replica:FireServer(requestCode, unpack(varargs))

		local startTime = time()

		while not response and time() - startTime < 5 do
			task.wait()
		end

		connection:Disconnect()

		return response
	end)
end

return ReplicaRequest
