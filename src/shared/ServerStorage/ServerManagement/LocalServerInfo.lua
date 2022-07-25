local CACHE_UPDATE_INTERVAL = 60

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local ServerData = require(serverManagement:WaitForChild("ServerData"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))

local privateServerId = game.PrivateServerId

local lastCacheUpdate = 0
local cachedData

local serverType do
    if privateServerId == "" then
        serverType = ServerTypeEnum.routing
        print("Server type: routing (due to no private server id)")
    else
        local serverData = ServerData.get()
        local worlds = serverData.worlds

        for _, world in ipairs(worlds) do
            for enum, location in pairs(world.locations) do
                if location.privateServerId == privateServerId then
                    serverType = ServerTypeEnum.location
                    break
                end
            end

            if serverType then
                break
            end
        end

        if not serverType then
            serverType = ServerTypeEnum.routing
            print("Server type: routing (due to no matching private server id)")
        end
    end
end

local localServerInfo = {}

localServerInfo.serverType = serverType

return localServerInfo