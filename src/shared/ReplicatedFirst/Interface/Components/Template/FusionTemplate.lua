--[[
	This component creates a...

	Props:
	```lua
	{
		-- Format: key: type
		PropName: string
		[Children]: table
	}
	```

	Example:
	```lua
		
	```
]]
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageShared = ReplicatedStorage:WaitForChild "Shared"
local replicatedFirstShared = ReplicatedFirst:WaitForChild "Shared"
local utilityFolder = replicatedFirstShared:WaitForChild "Utility"

local Component = require(utilityFolder:WaitForChild "GetComponent")
local Fusion = require(replicatedFirstShared:WaitForChild "Fusion")
local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local component = function(props)
	props = props or {}
end

return component
