local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data

local PlayerData = require(dataFolder.PlayerData)

local lastCurrencyChange = {
    --[[
    [player] = {
        currencyType = currencyType,
        amount = amount,
    }
    ]]
}

local Currency = {}

function Currency.get(player, currencyType)
    local playerData = PlayerData.get(player)
    
    if not playerData then
        return
    end

    local currencyTable = playerData.profile.Data.currency

    return if currencyType then currencyTable[currencyType] else currencyTable
end

function Currency.has(player, currencyType, amount)
    assert(player and currencyType and amount, "Currency.has: Missing argument(s)")
    local currency = Currency.get(player, currencyType)
    return currency and currency >= amount
end

function Currency.increment(player, currencyType, amount)
    assert(player and currencyType and amount, "Currency.increment: Missing argument(s)")

    local playerData = PlayerData.get(player)
    
    if not playerData then
        return
    end

    local currencyAmount = Currency.get(player, currencyType)

    if currencyAmount and currencyAmount + amount >= 0 then
        lastCurrencyChange[player] = amount
        playerData:setValue({"currency", currencyType}, currencyAmount + amount)

        return true
    end
end

function Currency.reimburse(player) -- Undo last currency change
    local playerCurrencyChange = lastCurrencyChange[player]
    Currency.increment(player, playerCurrencyChange.currencyType, -playerCurrencyChange.amount)
end

return Currency