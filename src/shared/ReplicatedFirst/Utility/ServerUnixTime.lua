local RunService = game:GetService("RunService")

local ServerUnixTime = {}

if RunService:IsClient() then
    local ReplicaCollection = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

    local timeReplica = ReplicaCollection.get("ServerUnixTime")

    local cachedTime = timeReplica.Data.time

    timeReplica:ListenToChange({"time"}, function(newTime)
        cachedTime = newTime
    end)

    task.spawn(function()
        while true do
            cachedTime = cachedTime + 1
            task.wait(1)
        end
    end)

    local function getUnixTime()
        return cachedTime
    end

    ServerUnixTime.__call = getUnixTime
    ServerUnixTime.time = getUnixTime
end

function ServerUnixTime.evaluateTime()
    return if RunService:IsClient() then ServerUnixTime() else os.time()
end

return setmetatable(ServerUnixTime, ServerUnixTime)


