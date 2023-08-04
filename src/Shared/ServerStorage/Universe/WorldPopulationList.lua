--!strict

local CACHE_DURATION = 10

local MemoryStoreService = game:GetService "MemoryStoreService"
local ServerStorage = game:GetService "ServerStorage"

local MemoryStoreUtility = require(ServerStorage.Shared.Utility.MemoryStoreUtility)

local catalogInfo = MemoryStoreService:GetSortedMap "CatalogInfo"

local isRetrieving = false
local lastRetrieval

local cachedWorldPopulationList

local WorldPopulationList = {}

function WorldPopulationList.get()
	-- If the world population list is being retrieved, wait until it is done being retrieved.

	if isRetrieving then
		repeat
			task.wait()
		until not isRetrieving

		return cachedWorldPopulationList
	end

	-- If the world population list was retrieved within the cache duration, return the cached world population list.

	if lastRetrieval and time() - lastRetrieval < CACHE_DURATION then return cachedWorldPopulationList end

	-- Otherwise, retrieve the world population list.

	isRetrieving = true

	local getWorldPopulationListSuccess, worldPopulationList: { number }? =
		MemoryStoreUtility.safeSortedMapGetAsync(catalogInfo, "WorldPopulationList")

	lastRetrieval = time()
	isRetrieving = false

	if not getWorldPopulationListSuccess then return cachedWorldPopulationList end

	cachedWorldPopulationList = worldPopulationList

	return worldPopulationList
end

return WorldPopulationList
