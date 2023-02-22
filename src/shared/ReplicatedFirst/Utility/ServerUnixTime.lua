local RunService = game:GetService("RunService")

local Fusion = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Fusion"))
local Value = Fusion.Value

local timeValue = Value(os.time())

local ServerUnixTime = {}

if RunService:IsClient() then
    local ReplicaCollection = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

    ReplicaCollection.get("ServerUnixTime"):andThen(function(timeReplica)
        timeValue:set(timeReplica.Data.timeInfo.unix or os.time())

        timeReplica:ListenToChange({"timeInfo", "unix"}, function(newTime)
            timeValue:set(newTime)
        end)
    end)

    task.spawn(function()
        while true do
            timeValue:set(timeValue:get() + 1)
            task.wait(1)
        end
    end)

    local function getUnixTime()
        return timeValue:get()
    end

    ServerUnixTime.__call = getUnixTime
    ServerUnixTime.time = getUnixTime
end

if RunService:IsServer() then
    RunService.Heartbeat:Connect(function()
        timeValue:set(os.time())
    end)
end

function ServerUnixTime.get() -- Gets the server's unix time, or the client's if the server is not available.
    return timeValue:get()
end

return setmetatable(ServerUnixTime, ServerUnixTime)


