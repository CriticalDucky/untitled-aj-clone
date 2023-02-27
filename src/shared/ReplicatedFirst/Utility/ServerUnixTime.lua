--[[
    ServerUnixTime.lua provides the server unix time wrapped in a Fusion.Value.
    Recommended to use over os.time() as it is more accurate and will not be affected by the client's clock.
    Probably going to merge this wih a general-purpose time utility module sometime in the future.
]]

local RunService = game:GetService("RunService")

local Fusion = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Fusion"))
local Value = Fusion.Value

local timeValue = Value(os.time())

local ServerUnixTime = {}

if RunService:IsClient() then
    local ReplicaCollection = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Replication"):WaitForChild("ReplicaCollection"))

    ReplicaCollection.get("ServerUnixTime"):andThen(function(timeReplica) -- Get the server's unix time replica.
        timeValue:set(timeReplica.Data.timeInfo.unix or os.time())

        timeReplica:ListenToChange({"timeInfo", "unix"}, function(newTime) -- Listen to changes to the server's unix time.
            timeValue:set(newTime) -- Update the time value.
        end)
    end)

    task.spawn(function()
        while true do
            timeValue:set(timeValue:get() + 1) -- Increment the time value by 1 every second. This is imprecise, but the time will be calibrated when the server's time is received.
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


