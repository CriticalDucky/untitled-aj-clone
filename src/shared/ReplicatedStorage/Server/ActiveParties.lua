local NO_REPEAT_ZONE = 1 / 2 -- of current active parties
local PARTY_PADDING_MINUTES = 5 -- minutes

local utilityFolder = game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility")

local Parties =
	require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Server"):WaitForChild("Parties"))
local ServerUnixTime = require(utilityFolder:WaitForChild("ServerUnixTime"))
local Table = require(utilityFolder:WaitForChild("Table"))
local Math = require(utilityFolder:WaitForChild("Math"))
local TimeRange = require(utilityFolder:WaitForChild("TimeRange"))
local Types = require(utilityFolder:WaitForChild("Types"))

type PartyUnit = Types.PartyUnit

local function halfHourIdToUnixTime(halfHourId)
	return halfHourId * 1800
end

local function getPossiblePartiesFromHalfHour(halfHour)
	local possibleParties = {}

	for enum, party in pairs(Parties) do
		if party.enabledTime:isInRange(halfHourIdToUnixTime(halfHour)) then
			possibleParties[enum] = party.chanceWeight
		end
	end

	return possibleParties
end

local function getWeekId(time)
	return math.floor((time or ServerUnixTime.get()) / 604800)
end

local function getHalfHourId(time)
	return math.floor((time or ServerUnixTime.get()) / 1800)
end

local function createWeekPartySchedule(weekId)
	local random = Random.new(weekId)

	local partyOrder = {} --  hour since start of week -> party enum

	for day = 1, 7 do
		local dayId = weekId * 7 + day

		for halfHour = 1, 24 * 2 do
			local partyChances = getPossiblePartiesFromHalfHour(dayId * 24 * 2 + halfHour)
			local noRepeatZone = math.floor(Table.dictLen(partyChances) * NO_REPEAT_ZONE)

			local party

			local timeout = 0

			repeat -- Only allow parties that haven't been played in the last 2/3 of the possible parties
				party = Math.weightedChance(partyChances, random:NextNumber())

				for i = 1, noRepeatZone do
					if partyOrder[#partyOrder - i + 1] == party then
						party = nil
						break
					end
				end

				timeout += 1

				if timeout > 500 then
					warn(
						"Timeout while trying to find a party. Here are the stats: ",
						noRepeatZone,
						Table.dictLen(partyChances),
						#partyOrder
					)
					break
				end
			until party

			table.insert(partyOrder, party)
		end
	end

	local partySchedule = {}

	for halfHour, party in ipairs(partyOrder) do -- The number of half hours in a week is: 7 * 24 * 2 = 336
		local halfHourId = weekId * 336 + halfHour - 1

		partySchedule[halfHourId] = {
			partyType = party,
			halfHourId = halfHourId,
			time = TimeRange.new(
				halfHourIdToUnixTime(halfHourId),
				halfHourIdToUnixTime(halfHourId + 1) - (PARTY_PADDING_MINUTES * 60)
			),
		}
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

function ActiveParties.getPartyAtHalfHourId(halfHourId): PartyUnit
	local weekId = math.floor(halfHourId / 336)
	local partySchedule = getWeekPartySchedule(weekId)

	return partySchedule[halfHourId]
end

function ActiveParties.getActiveParty(): PartyUnit
	return ActiveParties.getPartyAtHalfHourId(getHalfHourId())
end

function ActiveParties.generatePartyList(length, time): { PartyUnit }
	local partyList = {}

	local halfHourId = getHalfHourId(time)

	for i = 1, length do
		table.insert(partyList, ActiveParties.getPartyAtHalfHourId(halfHourId + i - 1))
	end

	return partyList
end

return ActiveParties
