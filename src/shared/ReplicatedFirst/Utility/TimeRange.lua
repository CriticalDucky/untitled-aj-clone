local utilityFolder = game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility")

local ServerUnixTime = require(utilityFolder:WaitForChild("ServerUnixTime"))
local Current = require(utilityFolder:WaitForChild("Current"))

local function getUnixFromInfo(timeInfo)
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
        year = timeInfo.year or Current.year(),
        month = timeInfo.month or Current.month(),
        day = timeInfo.day or Current.day(),
        hour = timeInfo.hour or Current.hour(),
        min = timeInfo.min or Current.min(),
        sec = timeInfo.sec or Current.sec(),
    })
end

local TimeRange = {}
TimeRange.__index = TimeRange

function TimeRange.new(introduction, closing)
    local self = setmetatable({}, TimeRange)

    self.introduction = introduction
    self.closing = closing

    return self
end

function TimeRange.newGroup(timeRanges)
    local self = setmetatable({}, TimeRange)

    self.timeRanges = timeRanges

    return self
end

function TimeRange:isInRange(time)
    local time = time or ServerUnixTime.evaluateTime()

    if self.timeRanges then
        for _, timeRange in ipairs(self.timeRanges) do
            if timeRange:isInRange(time) then
                return true
            end
        end

        return false
    else
        return time >= getUnixFromInfo(self.introduction) and time <= getUnixFromInfo(self.closing)
    end
end

function TimeRange:distanceToClosing(time)
    local time = time or ServerUnixTime.evaluateTime()

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
        return getUnixFromInfo(self.closing) - time
    end
end

function TimeRange:distanceToIntroduction(time)
    local time = time or ServerUnixTime.evaluateTime()

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
        return math.max(getUnixFromInfo(self.introduction) - time, 0)
    end
end

return TimeRange