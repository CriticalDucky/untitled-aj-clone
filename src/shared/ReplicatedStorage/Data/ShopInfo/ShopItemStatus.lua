local ShopItemStatus = {}

function ShopItemStatus.get(shopItem)
    -- sellingTime = {
    --     {
    --         introduction = {
    --             day = 1,
    --             month = 1,
    --             year = 1970
    --         },
    --         closing = {
    --             day = 1,
    --             month = 1,
    --             year = 1970
    --         },
    --     },
    -- },

    local sellingTimeTable = shopItem.sellingTime

    if sellingTimeTable == nil then
        return false
    end

    local function currentYear()
        return tonumber(os.date("%Y"))
    end

    for i, v in ipairs(sellingTimeTable) do
        local function getUnixFromSellInfo(timeInfo)
            if not (type(timeInfo) == "table" or type(timeInfo) == "function") then
                return
            end

            if type(timeInfo) == "function" then
                timeInfo = timeInfo()
            end

            return os.time({
                year = timeInfo.year or currentYear(),
                month = timeInfo.month,
                day = timeInfo.day,
            })
        end

        local introductionUnix = getUnixFromSellInfo(v.introduction)
        local closingUnix = getUnixFromSellInfo(v.closing)

        if introductionUnix == nil or closingUnix == nil then
            return false
        end

        if os.time() >= introductionUnix and os.time() <= closingUnix then
            return true, closingUnix - os.time()
        end
    end
end

return ShopItemStatus