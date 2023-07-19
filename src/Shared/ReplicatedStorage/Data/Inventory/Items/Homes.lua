local ReplicatedFirst = game:GetService("ReplicatedFirst")

local enumsFolder = ReplicatedFirst.Shared.Enums

local homeTypeEnum = require(enumsFolder.ItemHomeType)
local Model = require(ReplicatedFirst.Shared.Utility.Model)
local ModelType = require(enumsFolder.ModelType)

local function model(name)
	return Model(ModelType.home, name)
end

return {
	[homeTypeEnum.devHome] = {
		name = "Developer Home",
		model = model "DevHome",
	},
}
