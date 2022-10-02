local HttpService = game:GetService("HttpService")

local ReplicaRequest = {}

function ReplicaRequest.new(replica, ...)
    if not replica then
        warn("Replica not found")
        return
    end

    local requestCode = HttpService:GenerateGUID(false)

    replica:FireServer(requestCode, ...)

    local response

    local connection do
        connection = replica:ConnectOnClientEvent(function(returnedCode, ...)
            if returnedCode == requestCode then
                response = {...}
                connection:Disconnect()
            end
        end)
    end

    local startTime = time()

    while not response and time() - startTime < 5 do
        task.wait()
    end

    connection:Disconnect()

    return response
end

return ReplicaRequest