local REFRESH_INTERVAL = 60

local DataStoreService = game:GetService "DataStoreService"
local ReplicatedFirst = game:GetService "ReplicatedFirst"
local ServerStorage = game:GetService "ServerStorage"

local SafeDataStore = require(ServerStorage.Shared.Utility.SafeDataStore)
local Types = require(ReplicatedFirst.Shared.Utility.Types)

type UniverseServerCatalog = Types.UniverseServerCatalog

local universeData = DataStoreService:GetDataStore "UniverseData"

local serverCatalog: UniverseServerCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")

task.spawn(function()
	while task.wait(REFRESH_INTERVAL) do
		serverCatalog = SafeDataStore.safeGetAsync(universeData, "ServerCatalog")
	end
end)

--[[
    A catalog of all public servers in the universe.

    ---

    A server counts as public if it
    - is a **location** in a world,
    - is a **minigame**, or
    - is a **party**.
]]
local UniverseServerCatalog = {}

UniverseServerCatalog = (
	setmetatable({}, {
		__index = function(_, key: string) return serverCatalog[key] end,
	}) :: any
) :: UniverseServerCatalog

return UniverseServerCatalog
