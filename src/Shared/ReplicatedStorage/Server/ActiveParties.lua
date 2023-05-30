--[[
	This script is responsible for calculating the active parties for any given session.
	It's very messy and looking back I don't understand half the maths.
	Just take for granted it works, not bothering cleaning it up
]]

local NO_REPEAT_ZONE = 1 / 2 -- of current active parties
local PARTY_PADDING_MINUTES = 5 -- minutes

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"

local utilityFolder = replicatedStorageShared:WaitForChild "Utility"
local constantsFolder = replicatedStorageShared:WaitForChild "Constants"

local Parties = require(constantsFolder:WaitForChild "PartyConstants")
local Table = require(utilityFolder:WaitForChild "Table")
local Math = require(utilityFolder:WaitForChild "Math")
local Time = require(utilityFolder:WaitForChild "Time")
local Types = require(utilityFolder:WaitForChild "Types")

local Fusion = require(ReplicatedFirst:WaitForChild("Vendor"):WaitForChild "Fusion")

type Use = Fusion.Use
type PartyUnit = Types.PartyUnit

local function halfHourIdToUnixTime(halfHourId) return halfHourId * 1800 end

local function getPossiblePartiesFromHalfHour(halfHour)
	local possibleParties = {}

	for enum, party in pairs(Parties) do
		if party.enabledTime:isInRange(halfHourIdToUnixTime(halfHour)) then
			possibleParties[enum] = party.chanceWeight
		end
	end

	return possibleParties
end

local function getWeekId(time, use: Use) return math.floor((time or Time.getUnix(use)) / 604800) end

local function getHalfHourId(time, use: Use?) return math.floor((time or Time.getUnix(use)) / 1800) end

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
			time = Time.newRange(
				halfHourIdToUnixTime(halfHourId),
				halfHourIdToUnixTime(halfHourId + 1) - (PARTY_PADDING_MINUTES * 60)
			),
		}
	end

	return partySchedule
end

local partySchedules = {}

--[[
	Gets the party schedule for a given week.
	Pass in a Use to dynamically update within computeds.
]]
function getWeekPartySchedule(weekId, use: Use?): { [number]: PartyUnit }
	weekId = weekId or getWeekId(use)

	if not partySchedules[weekId] then partySchedules[weekId] = createWeekPartySchedule(weekId) end

	return partySchedules[weekId]
end

local ActiveParties = {}

--[[
	Gets the party at a given half hour id.
	Pass in a Use to dynamically update within computeds.
]]
function ActiveParties.getPartyAtHalfHourId(halfHourId: number, use: Use?): PartyUnit
	local weekId = math.floor(halfHourId / 336)
	local partySchedule = getWeekPartySchedule(weekId, use)

	return partySchedule[halfHourId]
end

--[[
	Gets the party at the current half hour id.
	Pass in a Use to dynamically update within computeds.
]]
function ActiveParties.getActiveParty(use: Use?): PartyUnit
	return ActiveParties.getPartyAtHalfHourId(getHalfHourId(nil, use), use)
end

--[[
	Gets the party list for the next x half hours.
	Pass in a Use to dynamically update within computeds.
]]
function ActiveParties.generatePartyList(length, time: number?, use: Use?): { PartyUnit }
	local partyList = {}

	local halfHourId = getHalfHourId(time, use)

	for i = 1, length do
		table.insert(partyList, ActiveParties.getPartyAtHalfHourId(halfHourId + i - 1, use))
	end

	return partyList
end

return ActiveParties
