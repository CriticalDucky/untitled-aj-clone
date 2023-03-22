local RunService = game:GetService "RunService"

local replicatedFirstShared = game:GetService("ReplicatedFirst"):WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local Types = require(utilityFolder:WaitForChild "Types")
local Value = Fusion.Value

type TimeInfo = Types.TimeInfo
type TimeRange = Types.TimeRange

local unixTimeValue = Value(os.time())

local function date(string)
    return tonumber(os.date(string, unixTimeValue:get()))
end

if RunService:IsClient() then
	local replicatedStorageShared = game:GetService("ReplicatedStorage"):WaitForChild "Shared"
	local replicationFolder = replicatedStorageShared:WaitForChild "Replication"
	local ReplicaCollection = require(replicationFolder:WaitForChild "ReplicaCollection")

	local unixTimeReplica = ReplicaCollection.get "ServerUnixTime"

	unixTimeReplica:ListenToChange(
		{ "timeInfo", "unix" },
		function(newTime) -- Listen to changes to the server's unix time.
			unixTimeValue:set(newTime) -- Update the time value.
		end
	)
	unixTimeValue:set(unixTimeReplica.Data.timeInfo.unix or os.time())

	task.spawn(function()
		while true do
			unixTimeValue:set(unixTimeValue:get() + 1) -- Increment the time value by 1 every second. This is imprecise, but the time will be calibrated when the server's time is received.
			task.wait(1)
		end
	end)
else
	RunService.Heartbeat:Connect(function()
		unixTimeValue:set(os.time()) -- Only update the time value on the server, as the client's time will be updated by the server's time.
	end)
end

local Time = {}

-- TODO: TimeRanges deserve their own documentation, but it'll get it later.
local TimeRange = {}
TimeRange.__index = TimeRange

function TimeRange.new(introduction, closing): TimeRange
    local self = setmetatable({}, TimeRange)

    self.introduction = introduction
    self.closing = closing

    return self
end

function TimeRange.newGroup(...: TimeRange): TimeRange
    local self = setmetatable({}, TimeRange)

    self.timeRanges = { ... }

    return self
end

function TimeRange:isInRange(time: TimeInfo?)
    local time = if time then Time.getUnixFromTimeInfo(time) else Time.getUnix()

    if self.timeRanges then
        for _, timeRange in ipairs(self.timeRanges) do
            if timeRange:isInRange(time) then
                return true
            end
        end

        return false
    else
        return time >= Time.getUnixFromTimeInfo(self.introduction) and time <= Time.getUnixFromTimeInfo(self.closing)
    end
end

function TimeRange:distanceToClosing(time)
    local time = time or Time.getUnix()

    if self.timeRanges then
        local distance = 0

        for _, timeRange in ipairs(self.timeRanges) do
            if timeRange:isInRange(time) then
                local distanceToClosing = timeRange:distanceToClosing()

                if distanceToClosing > distance then
                    distance = distanceToClosing
                end
            end
        end

        return distance
    else
        return Time.getUnixFromTimeInfo(self.closing) - time
    end
end

function TimeRange:distanceToIntroduction(time)
    local time = time or Time.getUnix()

    if self.timeRanges then
        local distance = math.huge

        for _, timeRange in ipairs(self.timeRanges) do
            if not timeRange:isInRange(time) then
                local distanceToIntroduction = timeRange:distanceToIntroduction()

                if distanceToIntroduction < distance and distanceToIntroduction > 0 then
                    distance = distanceToIntroduction
                end
            end
        end

        if distance == math.huge then
            return 0
        else
            return distance
        end
    else
        return math.max(Time.getUnixFromTimeInfo(self.introduction) - time, 0)
    end
end

--[[
    Gets the *server's* unix time.
    Recommended to use over os.time() as it is more accurate and will not be affected by the client's clock.
    It will also dynamically update in Fusion computed values.
]]
function Time.getUnix()
	return unixTimeValue:get()
end

--[[
    Gets the current year. Returns a number.
]]
function Time.currentYear()
    return date("%Y")
end

--[[
    Gets the current month. Returns a number from 1 to 12.
]]
function Time.currentMonth()
    return date("%m")
end

--[[
    Gets the current day. Returns a number from 1 to 31.
]]
function Time.currentDay()
    return date("%d")
end

--[[
    Gets the current hour. Returns a number from 0 to 23.
]]
function Time.currentHour()
    return date("%H")
end

--[[
    Gets the current minute. Returns a number from 0 to 59.
]]
function Time.currentMinute()
    return date("%M")
end

--[[
    Gets the current second. Returns a number from 0 to 59.
]]
function Time.currentSecond()
    return date("%S")
end

--[[
    Gets the unix time that corresponds to the given time info.

    TimeInfo is a table or function that returns a table with the following keys:
    ```lua
    TimeInfo = {
        year: number
        month: number
        day: number
        hour: number
        min: number
        sec: number
    } | () -> TimeInfo
    ```
    TimeInfo can also be a number, in which case it will be returned as is.

    WARNING: Nil keys will be replaced with the current time. This is sometimes
    undesirable, so make sure your time info is complete with 0 values.
]]
function Time.getUnixFromTimeInfo(timeInfo: TimeInfo): number
    if type(timeInfo) == "function" then
        timeInfo = timeInfo()
    end

    if type(timeInfo) == "number" then
        return timeInfo
    end
    
    if not type(timeInfo) == "table" then
        error("Error: timeInfo is not a table")
    end

    return os.time({
        year = timeInfo.year or Time.currentYear(),
        month = timeInfo.month or Time.currentMonth(),
        day = timeInfo.day or Time.currentDay(),
        hour = timeInfo.hour or Time.currentHour(),
        min = timeInfo.min or Time.currentMinute(),
        sec = timeInfo.sec or Time.currentSecond(),
    })
end

--[[
    Creates a new time range from the given time info.
    A time range represents a time interval between two points in time.

    Example usage:
    ```lua
    local timeRange = Time.newRange({
        year = 2021,
        month = 1,
        day = 1,
        hour = 0,
        min = 0,
        sec = 0,
    }, {
        year = 2021,
        month = 1,
        day = 1,
        hour = 0,
        min = 0,
        sec = 10,
    })

    print(timeRange:isInRange()) -- true if the current time is between the time range's 10 second interval
    ```
]]
function Time.newRange(introduction: TimeInfo, closing: TimeInfo): TimeRange
    return TimeRange.new(introduction, closing)
end

--[[
    Creates a new time range group from the given time ranges.
    Rather than representing a single time interval, a time range group represents a collection of time intervals.

    Example usage:
    ```lua
    local timeRangeGroup = Time.newGroup(
        Time.newRange({
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 0,
        }, {
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 10,
        }),
        Time.newRange({
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 20,
        }, {
            year = 2021,
            month = 1,
            day = 1,
            hour = 0,
            min = 0,
            sec = 30,
        })
    )

    print(timeRangeGroup:isInRange()) -- true if the current time is between the time range group's *sectioned* 20 second interval
    ```
]]
function Time.newGroup(...: TimeRange)
    return TimeRange.newGroup(...)
end

return Time
