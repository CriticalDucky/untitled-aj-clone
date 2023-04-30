local ServerScriptService = game:GetService("ServerScriptService")

local commandsFolder = ServerScriptService.Shared.Commands
local hooksFolder = commandsFolder.Cmdr.Hooks
local customCommandsFolder = commandsFolder.Custom

local Cmdr = require(commandsFolder.Cmdr)

Cmdr:RegisterHooksIn(hooksFolder)
Cmdr:RegisterCommandsIn(customCommandsFolder)