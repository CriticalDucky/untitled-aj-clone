local Table = {}

function Table.dictLen(dict)
    local count = 0

    for _ in pairs(dict) do
        count += 1
    end

    return count
end

function Table.deepCopy(value)
    if type(value) == "table" then
        local copy = {}

        for k, v in pairs(value) do
            copy[k] = Table.deepCopy(v)
        end

        return copy
    end
        
    return value
end

function Table.copy(t)
    local copy = {}

    for k, v in pairs(t) do
        copy[k] = v
    end

    return copy
end

function Table.hasValue(t, value)
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end

    return false
end

function Table.findMax(t)
    local k, v

    for key, value in pairs(t) do
        if not k or value > v then
            k, v = key, value
        end
    end

    return k, v
end

function Table.findMin(t)
    local k, v

    for key, value in pairs(t) do
        if not k or value < v then
            k, v = key, value
        end
    end

    return k, v
end

function Table.print(t, note)
    local function printTable(t, indent)
        for k, v in pairs(t) do
            if type(v) == "table" then
                print(indent .. tostring(k) .. " :")
                printTable(v, indent .. "    ")
            else
                print(indent .. tostring(k) .. " : " .. tostring(v))
            end
        end
    end

    print("Printing", note or tostring(t))

    printTable(t, "")
end

return Table