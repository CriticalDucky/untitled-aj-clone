--[[
	This script manages parameters for functions.
]]

local ReplicatedFirst = game:GetService "ReplicatedFirst"
local utilityFolder = ReplicatedFirst:WaitForChild("Shared"):WaitForChild "Utility"

local Types = require(utilityFolder:WaitForChild "Types")

type Promise = Types.Promise
type PlayerParam = Types.PlayerParam

local Param = {}

--[[
	Takes in a list of lists. Each list begins with an object, and the rest of the list is a list of possible types for that object.
	Possible types can also be instances.
	This will return false if any objects are not of the correct type.
	Example:
	```lua
	Param.expect({1, "number"}, {"hello", "string"}, {true, "boolean", "Part"}) -- returns false
	```
	Returns true if everything checks out!
]]
function Param.expect(...) -- desired types are put after the object in a list. Example: {1, "number", "string"}
	local t = { ... }

	for _, v: {} in ipairs(t) do
		local obj = v[1]
		local types = { select(2, unpack(v)) }

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
			return false
		end
	end

	return true
end

return Param
