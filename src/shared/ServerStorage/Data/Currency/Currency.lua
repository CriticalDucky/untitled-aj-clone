local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data

local PlayerData = require(dataFolder.PlayerData)

local Currency = {}

function Currency.increment(player, currencyType, amount)
    local playerData = PlayerData.get(player)
    
    if not playerData then
        return
    end

    local currencyTable = playerData.profile.currency

    if currencyTable[currencyTable.indexName] and currencyTable[currencyTable.indexName] + amount >= 0 then
        playerData:setValue({"currency", currencyType.indexName}, currencyTable[currencyTable.indexName] + amount)

        return true
    end
end

return Currency