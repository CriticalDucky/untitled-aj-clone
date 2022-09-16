local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFolder = ReplicatedStorage:WaitForChild("UI")
local Components = UIFolder:WaitForChild("Components")

local Utility = script.Parent
local WaitForDescendant = require(Utility:WaitForChild("WaitForDescendant"))

local Util = {
	LerpUDim = function(UDim0: UDim, UDim1: UDim, alpha: number)
		return (UDim2.new(UDim0, UDim.new(0, 0)):Lerp(UDim2.new(UDim1, UDim2.new(0, 0)), alpha)).X
	end,
    
	MultiplyUDim = function(UDim0: UDim, number: number)
		return UDim.new(
			UDim0.Scale * number,
			UDim0.Offset * number
		)
	end,
	
	Component = function(Name)
		return require(WaitForDescendant(Components, Name))
	end,
	
	ColorEdit = function(color3: Color3, edits, increment: boolean) -- For HSV values
		local h, s, v = color3:ToHSV()
		
		local t = { -- The keys go in the increments
			hue = h,
			sat = s,
			val = v
		}
		
		for k, v in pairs(edits) do
			if increment then
				t[k] += v
			else
				t[k] = v
			end
			
			t[k] = math.clamp(t[k], 0, 1)
		end
		
		return Color3.fromHSV(t.hue, t.sat, t.val)
	end,
	
	TimeConvertMS = function(seconds)
		return string.format("%2i:%02i", math.floor(seconds/60), seconds%60)
	end,
}

return Util