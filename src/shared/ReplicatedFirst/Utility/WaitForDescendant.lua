--return function(parent: Instance, name: string)
--	local TIMEOUT = 10
	
--	local part do
--		for _, v in ipairs(parent:GetDescendants()) do
--			if v.Name == name then
--				part = v
--			end
--		end
--	end
	
--	if not part then
--		coroutine.wrap(function()
--			task.wait(TIMEOUT)
			
--			if not part then
--				warn(("Descendant %s was not found in Instance %s, infinite yield possible"):format(name, parent.Name))
--			end
--		end)()
		
--		repeat
--			local addedPart = parent.DescendantAdded:Wait()
--			part = if addedPart.Name == name then addedPart else nil
--		until part
--	end
	
--	return part
--end

local function waitForDescendant (descendantOf, str)
	assert(typeof(descendantOf) == "Instance", "Invalid type for argument 1 (descendatOf)")
	assert(typeof(str) == "string", "Invalid type for argument 2 (str)")
	
	local TIMEOUT = 10

	if descendantOf:FindFirstChild(str, true) then
		return descendantOf:FindFirstChild(str, true)
	else
		local object
		
		task.spawn(function()
			task.wait(TIMEOUT)

			if not object then
				warn("Infinite yield possible on "..tostring(descendantOf)..":WaitForDescendant("..str..")")
			end
		end)

		repeat
			local descendant = descendantOf.DescendantAdded:Wait()
			
			object = if descendant.Name == str then descendant else nil
		until object

		return object
	end
end

_G.waitForDescendant = waitForDescendant

return waitForDescendant