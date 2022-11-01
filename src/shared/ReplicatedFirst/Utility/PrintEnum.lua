--[[ Example enum:

local Enum = {
    Foo = 1,
    Bar = 2,
    Baz = 3,
}

]]

-- This script is purely for debugging purposes. It prints out the values of an enum.

return function (enumTable, value)
    for key, enumValue in pairs(enumTable) do
        if enumValue == value then
            print(key)
        end
    end
end