--!strict

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local DataStoreUtility = require(ServerStorage.Shared.Utility.DataStoreUtility)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type ServerInfo = Types.ServerInfo

local serverDictionary = DataStoreService:GetDataStore "ServerDictionary"

local privateServerId = game.PrivateServerId

--#region Server Info

local getServerInfoSuccess, serverInfo: ServerInfo? = DataStoreUtility.safeGetAsync(serverDictionary, privateServerId)

if not getServerInfoSuccess or not serverInfo then
	-- TODO: Soft kick players.
end

assert(getServerInfoSuccess and serverInfo)

--#endregion

local ServerInfo = serverInfo

return ServerInfo
