local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local RunService = game:GetService "RunService"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local enumsFolder = replicatedStorageShared:WaitForChild "Enums"
local utilityFolder = ReplicatedFirst:WaitForChild("Shared"):WaitForChild "Utility"
local serverFolder = replicatedStorageShared:WaitForChild "Server"

local PlayerFormat = require(enumsFolder:WaitForChild "PlayerFormat")
local Types = require(utilityFolder:WaitForChild "Types")
local LocalServerInfo = require(serverFolder:WaitForChild "LocalServerInfo")
local Promise = require(utilityFolder:WaitForChild "Promise")
local ResponseType = require(enumsFolder:WaitForChild "ResponseType")

type Promise = Types.Promise

local serverInfoPromise = LocalServerInfo.getServerInfo()

local Param = {}

--[[
	Takes in a list of lists. Each list begins with an object, and the rest of the list is a list of possible types for that object.
	Possible types can also be instances.
	This will return a rejected promise if any objects are not of the correct type.
	Example:
	```lua
	Param.expect({1, "number"}, {"hello", "string"}, {true, "boolean", "Part"}) -- returns a rejected promise
	```
]]
function Param.expect(...) -- desired types are put after the object in a list. Example: {1, "number", "string"}
	local t = { ... }

	for _, v in ipairs(t) do
		local obj = v[1]
		local types = table.remove(v, 1) and v

		assert(#types > 0, "No types provided")

		local objType = typeof(obj)

		local found = false

		for _, typ in ipairs(types) do
			if objType == typ or (objType == "Instance" and obj:IsA(typ)) then
				found = true
				break
			end
		end

		if not found then
			return Promise.reject(ResponseType.invalid)
		end
	end

	return Promise.resolve()
end

--[[
	This function takes in a playerParam, a format, and two booleans. that indicate the behavior of when playerParam is nil.
	Returns a promise, so it's not safe to use in stateObjects.
]]
function Param.playerParam(
	playerParam: Types.PlayerParam,
	format: Types.UserEnum,
	useHomeOwner: boolean,
	useLocalPlayer: boolean
): Promise
	return Param.expect(
		{ playerParam, "Player", "number" },
		{ format, "string", "number" },
		{ useHomeOwner, "boolean" },
		{ useLocalPlayer, "boolean" }
	):andThen(function()
		return (if useHomeOwner then serverInfoPromise else Promise.resolve())
			:andThen(function(serverInfo)
				if useHomeOwner then
					return Param.playerParam(serverInfo.homeOwner, format, false)
				end

				if useLocalPlayer then
					return Param.playerParam(Players.LocalPlayer, format, false)
				end

				local paramType = typeof(playerParam)

				if format == PlayerFormat.instance then
					return if paramType == "Instance" then paramType else Players:GetPlayerByUserId(paramType)
				elseif format == PlayerFormat.userId then
					return if paramType == "number" then paramType else playerParam.UserId
				end
			end)
			:andThen(function(player)
				return player or Promise.reject(ResponseType.invalid)
			end)
			:catch(function(err)
				warn("Param.playerParam failed:", err)
				return Promise.reject(err)
			end)
	end)
end

--[[
	Wrapper for Param.playerParam that uses a local player param. Should only be used on the client.
	Unsafe for state objects.
]]
function Param.localPlayerParam(playerParam: Types.LocalPlayerParam, format: Types.UserEnum): Promise
	return Param.playerParam(playerParam, format, false, true)
end

return Param
