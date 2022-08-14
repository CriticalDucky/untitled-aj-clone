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

    local currencyTable = playerData.profile.Data.currency

    if currencyTable[currencyType] and currencyTable[currencyType] + amount >= 0 then
        playerData:setValue({"currency", currencyType}, currencyTable[currencyType] + amount)

        return true
    end
end

return Currency