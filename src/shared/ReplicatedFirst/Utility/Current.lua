local ServerUnixTime = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("ServerUnixTime"))

local function date(string)
    return tonumber(os.date(string, ServerUnixTime.get()))
end

local function currentYear()
    return date("%Y")
end

local function currentMonth()
    return date("%m")
end

local function currentDay()
    return date("%d")
end

local function currentHour()
    return date("%H")
end

local function currentMinute()
    return date("%M")
end

local function currentSecond()
    return date("%S")
end

current = {
    year = currentYear,
    month = currentMonth,
    day = currentDay,
    hour = currentHour,
    min = currentMinute,
    sec = currentSecond,
}

return current