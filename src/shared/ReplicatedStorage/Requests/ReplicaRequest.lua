local ReplicaRequest = {}

function ReplicaRequest.new(replica, ...)
    if not replica then
        warn("Replica not found")
        return
    end

    replica:FireServer(...)

    local response

    local connection do
        connection = replica:ConnectOnClientEvent(function(...)
            connection:Disconnect()
            response = {...}
        end)
    end

    local startTime = time()

    while not response and time() - startTime < 5 do
        task.wait()
    end

    connection:Disconnect()

    return response and unpack(response)
end

return ReplicaRequest