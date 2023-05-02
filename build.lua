---@diagnostic disable

--[[
	This script builds and publishes the project to Roblox. It will overwrite the existing place asset.

	SETUP:

	Install and set up Aftman using the instructions on its GitHub page: https://github.com/LPGhatguy/aftman

	Run this script using the following command:
	> remodel run build.lua

	By default, this command will attempt to publish to the testing game. You may optionally pass in an argument to
	specify whether to attempt to publish to the testing or production game, like so:
	> remodel run build.lua testing
	> remodel run build.lua production

	An authentication cookie is necessary to publish to Roblox! More info can be found here:
	https://github.com/rojo-rbx/remodel#authentication
]]

local args = { ... }

local testingMode

if not args[1] or args[1] == "testing" then
	testingMode = true
elseif args[1] == "production" then
	testingMode = false
else
	error "First argument must be 'testing' or 'production'."
end

-- Search for projects

print()

local files = remodel.readDir "."

local projectsToBuild = {}
local numProjects = 0

for _, fileName in pairs(files) do
	local projectId = fileName:match "(.+).project.json"

	if projectId then
		local project = json.fromString(remodel.readFile(fileName))
		local servePlaceIds = project.servePlaceIds
		local name = project.name
		local placeId

		if testingMode then
			placeId = servePlaceIds[2]
		else
			placeId = servePlaceIds[1]
		end

		projectsToBuild[projectId] = {
			name = name,
			placeId = placeId,
		}

		numProjects = numProjects + 1
	end
end

print(
	("Found %d project%s to build and publish to a %s place:"):format(
		numProjects,
		numProjects == 1 and "" or "s",
		testingMode and "testing" or "production"
	)
)

for _, project in pairs(projectsToBuild) do
	print(
		("\t%s (%s Place ID: %s)"):format(
			project.name,
			testingMode and "Testing" or "Production",
			project.placeId or "No Place ID"
		)
	)
end

if not testingMode then
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

local builtProjectsFolder = "build"

remodel.createDirAll(builtProjectsFolder)

local failures = 0

for projectId, project in pairs(projectsToBuild) do
	local projectName = project.name
	local projectPlaceId = project.placeId

	print(
		("\n=== %s (%s Place ID: %s) ===\n"):format(
			projectName,
			testingMode and "Testing" or "Production",
			projectPlaceId and tostring(projectPlaceId) or "None"
		)
	)

	local rbxlx = ("%s/%s.rbxlx"):format(builtProjectsFolder, projectId)

	os.execute(("rojo build %s.project.json --output %s"):format(projectId, rbxlx))

	if projectPlaceId then
		print(("Publishing project '%s'"):format(projectName))

		local success, err =
			pcall(remodel.writeExistingPlaceAsset, remodel.readPlaceFile(rbxlx), tostring(projectPlaceId))

		if success then
			print(
				("Published project to %s place ID %s"):format(
					testingMode and "testing" or "production",
					projectPlaceId
				)
			)
		else
			errMessage = tostring(err):match "caused by: (.+)"

			print(("ERROR: Failed to publish! %s"):format(errMessage))

			failures = failures + 1
		end
	else
		print(
			("No %s place ID found for project '%s'. Will not publish."):format(
				testingMode and "testing" or "production",
				projectName
			)
		)
	end
end

print "\n==================================================\n"
print(("Finished building and publishing all projects at %s."):format(os.date "%I:%M %p"))

if failures == 0 then
	print(("All projects published to the %s game successfully."):format(testingMode and "testing" or "production"))
elseif failures == numProjects then
	print(
		(
			"WARNING: All projects FAILED to publish to the %s game. "
			.. "Check that you have a valid authentication cookie set."
		):format(testingMode and "testing" or "production")
	)
else
	print(
		("%d project%s failed to publish to the %s game. Would you like to retry? (y/n)"):format(
			failures,
			failures == 1 and "" or "s",
			testingMode and "testing" or "production"
		)
	)

	while true do
		io.write "> "
		local input = io.read()

		if input:lower() == "y" or input:lower() == "yes" then
			os.execute(("remodel run build.lua %s"):format(table.concat(args, " ")))
			break
		elseif input:lower() == "n" or input:lower() == "no" then
			print "Aborting."
			break
		else
			print "Invalid input."
		end
	end
end

print()
