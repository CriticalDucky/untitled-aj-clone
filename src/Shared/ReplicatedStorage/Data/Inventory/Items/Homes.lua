local ReplicatedStorage = game:GetService "ReplicatedStorage"

local enumsFolder = ReplicatedStorage.Shared.Enums

local homeTypeEnum = require(enumsFolder.HomeType)
local Model = require(ReplicatedStorage.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
	return Model(ModelType.home, name)
end

return {
	[homeTypeEnum.defaultHome] = {
		name = "Default Home",
		model = model "DefaultHome",
	},
}
