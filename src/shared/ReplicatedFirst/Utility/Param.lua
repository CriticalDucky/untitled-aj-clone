local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local enumsFolder = replicatedStorageShared:WaitForChild("Enums")
local utilityFolder = ReplicatedFirst:WaitForChild("Shared"):WaitForChild("Utility")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local PlayerFormat = require(enumsFolder:WaitForChild("PlayerFormat"))
local Types = require(utilityFolder:WaitForChild("Types"))
local LocalServerInfo = require(serverFolder:WaitForChild("LocalServerInfo"))
local Promise = require(utilityFolder:WaitForChild("Promise"))

local serverInfoPromise = LocalServerInfo.getServerInfo()

local Param = {}

function Param.playerParam(playerParam: Types.PlayerParam, format: Types.UserEnum, useHomeOwner: boolean): Types.Promise
	return (if useHomeOwner then serverInfoPromise else Promise.resolve())
		:andThen(function(serverInfo)
			if useHomeOwner then
				return Param.playerParam(serverInfo.homeOwner, format, false)
			end

			local paramType = typeof(playerParam)

			if format == PlayerFormat.instance then
				return if paramType == "Instance" then paramType else Players:GetPlayerByUserId(paramType)
			elseif format == PlayerFormat.userId then
				return if paramType == "number" then paramType else playerParam.UserId
			end
		end)
		:andThen(function(player)
			return player or Promise.reject("Player not found")
		end)
		:catch(function(err)
			warn("Param.playerParam failed:", err)
			return Promise.reject(err)
		end)
end

return Param
