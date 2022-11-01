local RunService = game:GetService("RunService")

local Fusion = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Fusion"))
local Value = Fusion.Value

local ServerUnixTime = {}

if RunService:IsClient() then
    local ReplicaCollection = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

    local timeReplica = ReplicaCollection.get("ServerUnixTime", true)

    local cachedTime = Value(timeReplica.Data.time)

    timeReplica:ListenToChange({"time"}, function(newTime)
        cachedTime:set(newTime)
    end)

    task.spawn(function()
        while true do
            cachedTime:set(cachedTime:get() + 1)
            task.wait(1)
        end
    end)

    local function getUnixTime()
        return cachedTime:get()
    end

    ServerUnixTime.__call = getUnixTime
    ServerUnixTime.time = getUnixTime
end

function ServerUnixTime.evaluateTime()
    return if RunService:IsClient() then ServerUnixTime() else os.time()
end

return setmetatable(ServerUnixTime, ServerUnixTime)


