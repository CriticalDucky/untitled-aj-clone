local TELEPORT_TO_PLAYER_TOPIC = "playerJoinQuery"
local TELEPORT_TO_PLAYER_RESPONSE_TOPIC = "playerJoinQueryResponse"

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage:WaitForChild("Shared")
local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local messagingFolder = serverStorageShared:WaitForChild("Messaging")
local serverManagement = serverStorageShared:WaitForChild("ServerManagement")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")

local Message = require(messagingFolder:WaitForChild("Message"))
local LocalServerInfo = require(serverManagement:WaitForChild("LocalServerInfo"))
local ServerTypeEnum = require(enumsFolder:WaitForChild("ServerType"))
local FillStatusEnum = require(enumsFolder:WaitForChild("FillStatus"))
local JoinDenialReasonEnum = require(enumsFolder:WaitForChild("JoinDenialReason"))
local Locations = require(serverManagement:WaitForChild("Locations"))

local serverType = LocalServerInfo.serverType

if serverType ~= ServerTypeEnum.routing then
    Message.subscribe(TELEPORT_TO_PLAYER_TOPIC, function(message)
        print("Received player join query")

        local data = message.Data
        local recipient = data.recipient
        local sender = data.sender

        local matchingPlayer do
            for _, player in pairs(Players:GetPlayers()) do
                if player.UserId == recipient then
                    matchingPlayer = player
                    break
                end
            end
        end

        if matchingPlayer then
            if serverType == ServerTypeEnum.location then
                local serverStorageLocation = ServerStorage:WaitForChild("Location")
                local serverManagementLocation = serverStorageLocation:WaitForChild("ServerManagement")

                local LocalWorldInfo = require(serverManagementLocation:WaitForChild("LocalWorldInfo"))

                local worldData = LocalWorldInfo.getWorldData()
                local locationEnum = LocalWorldInfo.locationEnum
                local location = worldData.locations[locationEnum]

                local canJoin, joinDenialReason do
                    if location.fillStatus == FillStatusEnum.filled then
                        canJoin = false
                        joinDenialReason = JoinDenialReasonEnum.full
                    end
                end

                Message.publish(TELEPORT_TO_PLAYER_RESPONSE_TOPIC, {
                    recipient = sender,
                    sender = recipient,
                    
                    placeId = Locations.info[locationEnum].placeId,
                    serverCode = location.serverCode,

                    canJoin = canJoin,
                    joinDenialReason = joinDenialReason,
                })
            end
        else -- Player not found
            warn("Player not found")
        end
    end)
end

