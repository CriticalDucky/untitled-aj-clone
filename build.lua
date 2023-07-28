--[[
	This script builds and publishes the project to Roblox. It will overwrite the existing place asset.

	SETUP:

	Install and set up Aftman using the instructions on its GitHub page: https://github.com/LPGhatguy/aftman

	Run this script using the following command:
	> remodel run build.lua

	By default, this command will simply build place files. You may optionally pass in an argument to specify whether
	to attempt to publish to the testing or production game, like so:
	> remodel run build.lua testing
	> remodel run build.lua production

	Alternatively, you can run a VS Code task to build and publish to the testing or production game. (Search commands
	with the "tasks" keyword.) Building and publishing to the test game is the default build task.

	An authentication cookie is necessary to publish to Roblox! More info can be found here:
	https://github.com/rojo-rbx/remodel#authentication
]]

local function sleep(time)
	local start = os.time(os.date "*t")

	while true do
		local now = os.time(os.date "*t")

		if now > start + time then break end
	end
end

local args = { ... }

local mode = args[1]

mode = mode or "build"

if mode and mode ~= "build" and mode ~= "testing" and mode ~= "production" then
	print "First argument must be 'build', 'testing', or 'production'."

	return
end

-- Search for projects

print()

local files = remodel.readDir "src"

local projectsToBuild = {}
local numProjects = 0

for _, placeFileName in pairs(files) do
	if not remodel.isDir("src/" .. placeFileName) then goto continue end

	local placeFiles = remodel.readDir("src/" .. placeFileName)

	for _, fileName in pairs(placeFiles) do
		local projectId = fileName:match "(.+).project.json"

		if not projectId then goto continue end

		local path = ("src/%s/%s"):format(placeFileName, fileName)

		local project = json.fromString(remodel.readFile(path))

		if project.name:find "%(Shared%)" then goto continue end

		local servePlaceIds = project.servePlaceIds
		local name = project.name
		local placeId

		if mode == "testing" then
			placeId = servePlaceIds[2]
		else
			placeId = servePlaceIds[1]
		end

		projectsToBuild[projectId] = {
			name = name,
			path = path,
			placeId = placeId,
		}

		numProjects = numProjects + 1

		::continue::
	end

	::continue::
end

print(
	("Found %d project%s to build%s:"):format(
		numProjects,
		numProjects == 1 and "" or "s",
		mode ~= "build" and (" and publish to a %s place"):format(mode) or ""
	)
)

for _, project in pairs(projectsToBuild) do
	print(
		("\t%s%s"):format(
			project.name,
			mode ~= "build"
			and ("%s(%s Place ID: %s)"):format(
				("."):rep(30 - project.name:len()),
				mode == "testing" and "Testing" or "Production",
				project.placeId or "No Place ID"
			)
			or ""
		)
	)
end

if mode == "production" then
	local confirmationMessage =
	"I confirm that I would like to publish to production and understand that this is final."

	print()
	print "=================================================="
	print "WARNING: You are about to publish to production!"
	print "=================================================="
	print "To proceed, copy the following statement exactly."
	print("- " .. confirmationMessage)

	io.write "> "
	local input = io.read()
	if input ~= confirmationMessage then
		print "Statement does not match. Aborting."
		return
	end
end

-- Build and publish projects

::buildAndPublish::

local builtProjectsFolder = "build"

remodel.createDirAll(builtProjectsFolder)

local failures = 0

for projectId, project in pairs(projectsToBuild) do
	local projectName = project.name
	local projectPath = project.path
	local projectPlaceId = project.placeId

	print(
		("\n=== %s%s ===\n"):format(
			projectName,
			mode ~= "build"
			and (" (%s Place ID: %s)"):format(
				mode == "testing" and "Testing" or "Production",
				projectPlaceId and tostring(projectPlaceId) or "None"
			)
			or ""
		)
	)

	local rbxlx = ("%s/%s.rbxlx"):format(builtProjectsFolder, projectId)

	os.execute(("rojo build %s --output %s"):format(projectPath, rbxlx))

	if projectPlaceId and mode ~= "build" then
		print(("Publishing project '%s'"):format(projectName))

		local success, err =
			pcall(remodel.writeExistingPlaceAsset, remodel.readPlaceFile(rbxlx), tostring(projectPlaceId))

		if success then
			print(("Published project to %s place ID %s"):format(mode, projectPlaceId))

			projectsToBuild[projectId] = nil
		else
			errMessage = tostring(err):match "caused by: (.+)"

			print(("ERROR: Failed to publish! %s"):format(errMessage))

			failures = failures + 1
		end
	elseif mode ~= "build" then
		print(("No %s place ID found for project '%s'. Will not publish."):format(mode, projectName))
	end
end

print "\n==================================================\n"

if mode ~= "build" then
	if failures == 0 then
		print(("All projects published to the %s game successfully."):format(mode))
		print(
			("Finished building%s all projects at %s."):format(mode ~= "build" and " and publishing" or "",
				os.date "%I:%M %p")
		)
	elseif failures == numProjects then
		print(
			(
				"WARNING: All projects FAILED to publish to the %s game. "
				.. "Check that you have a valid authentication cookie set."
			):format(mode)
		)
	else
		print(
			("%d project%s failed to publish to the %s game. Retrying..."):format(
				failures,
				failures == 1 and "" or "s",
				mode
			)
		)

		sleep(3)

		goto buildAndPublish
	end
end

print()
