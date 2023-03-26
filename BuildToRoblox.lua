---@diagnostic disable

--[[

    This script *publishes* then project to Roblox. It will overwrite the existing place asset.

    TESTING_MODE controls whether it will publish to the testing or production game. This is extremely dangerous.
    It should only be changed when we want to push an update. Go through me first!

    SETUP:

    Add a folder called "BuiltProjects" to the root of your project. This is where the built projects will be stored.

	Command (make sure you have remodel installed on your PATH): 

	remodel run BuildToRoblox.lua
]]

local TESTING_MODE = false -- DO NOT TOUCH THIS! DANGEROUS!
local API_COOLDOWN = 45
local MAX_RETRIES = 4

local projectsToBuild = {}

local files = remodel.readDir "."

local function sleep(n)
	local t0 = os.clock()
	while os.clock() - t0 <= n do
	end
end

print "===================================="

for _, fileName in pairs(files) do
	if string.find(fileName, ".project.json") then
		local project = json.fromString(remodel.readFile(fileName))
		local servePlaceIds = project.servePlaceIds

		local id

		if TESTING_MODE then
			id = servePlaceIds[2]
		else
			id = servePlaceIds[1]
		end

		if id then projectsToBuild[fileName] = id end
	end
end

local builtProjectsFolder = "BuiltProjects"

local function buildProject(projectName)
	os.execute("rojo build " .. projectName .. " --output " .. builtProjectsFolder .. "/" .. projectName .. ".rbxlx")

	return builtProjectsFolder .. "/" .. projectName .. ".rbxlx"
end

for projectName, placeId in pairs(projectsToBuild) do
	print("Building " .. projectName .. " to " .. placeId)

	local rbxlx = buildProject(projectName)

	local function try()
		local success, err = pcall(remodel.writeExistingPlaceAsset, remodel.readPlaceFile(rbxlx), tostring(placeId))

		return success, err
	end

	local success, err = try()

	if not success then
		local retries = 0

		repeat
			print("API cooldown, retrying in " .. API_COOLDOWN .. " seconds...")

			sleep(API_COOLDOWN)

			success, err = try()

			retries = retries + 1
		until success or retries >= MAX_RETRIES

		if retries >= MAX_RETRIES then error "Too many retries, aborting!" end
	end

	print ""
end

print("Successfully built all projects!\n" .. os.date "%I:%M %p")
