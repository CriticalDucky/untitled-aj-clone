local NO_REPEAT_ZONE = 2/3 -- of current active parties

local utilityFolder = game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility")

local Parties = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Server"):WaitForChild("Parties"))
local ServerUnixTime = require(utilityFolder:WaitForChild("ServerUnixTime"))
local Table = require(utilityFolder:WaitForChild("Table"))

local function getPossiblePartiesFromHour(hour, dayId)
    local possibleParties = {}

    for enum, party in ipairs(Parties) do
        if party.enabledTime:isInRange((dayId * 86400) + (hour or 0) * 3600) then
            table.insert(possibleParties, enum)
        end
    end

    return possibleParties 
end

local function getWeekId(time)
    return math.floor((time or ServerUnixTime.evaluateTime()) / 604800)
end

local function getHourId(time)
    return math.floor((time or ServerUnixTime.evaluateTime()) / 3600)
end

local function createWeekPartySchedule(weekId)
    local random = Random.new(weekId)

    local partyOrder = {} --  hour since start of week -> party enum

    for day = 1, 7 do
        local dayId = weekId * 7 + day

        for hour = 1, 24 do
            local possibleParties = getPossiblePartiesFromHour(hour, dayId)
            local noRepeatZone = math.floor(#possibleParties * NO_REPEAT_ZONE)

            local party

            repeat -- Only allow parties that haven't been played in the last 2/3 of the possible parties
                party = possibleParties[random:NextInteger(1, #possibleParties)]
                
                for i = #partyOrder - noRepeatZone + 1, #partyOrder do
                    if partyOrder[i] == party then
                        party = nil
                        break
                    end
                end
            until party

            table.insert(partyOrder, party)
        end
    end

    local partySchedule = {}

    for hour, party in ipairs(partyOrder) do
        partySchedule[weekId * 168 + hour] = party
    end

    return partySchedule
end

local partySchedules = {}

function getWeekPartySchedule(weekId)
    weekId = weekId or getWeekId()

    if not partySchedules[weekId] then
        partySchedules[weekId] = createWeekPartySchedule(weekId)
    end

    return partySchedules[weekId]
end

local ActiveParties = {}

function ActiveParties.getPartyAtHourId(hourId)
    local weekId = math.floor(hourId / 168)
    local partySchedule = getWeekPartySchedule(weekId)

    return partySchedule[hourId]
end

function ActiveParties.getActiveParty()
    return ActiveParties.getPartyAtHourId(getHourId())
end

function ActiveParties.generatePartyList(length)
    local partyList = {}

    local hourId = getHourId()

    for i = 1, length do
        table.insert(partyList, ActiveParties.getPartyAtHourId(hourId + i - 1))
    end

    return partyList
end

return ActiveParties