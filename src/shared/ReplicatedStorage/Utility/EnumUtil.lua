local EnumUtil = {}

function EnumUtil.enumValueExists(enum, value)
    for _, v in pairs(enum) do
        if v == value then
            return true
        end
    end
    return false
end

return EnumUtil