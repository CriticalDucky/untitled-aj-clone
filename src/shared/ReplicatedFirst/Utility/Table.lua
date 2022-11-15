local Table = {}

_G.Table = Table

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

function Table.merge(...)
    local merged = {}

    for _, t in pairs({...}) do
        for k, v in pairs(t) do
            merged[k] = v
        end
    end

    return merged
end

function Table.isEqualTo(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end

    for k, v in pairs(t1) do
        if not Table.isEqualTo(v, t2[k]) then
            return false
        end
    end

    for k, v in pairs(t2) do
        if not Table.isEqualTo(v, t1[k]) then
            return false
        end
    end

    return true
end

function Table.recursiveIterate(t, callback)
    local function recursiveIterate(t1, path)
        for k, v in pairs(t1) do
            local newPath = Table.copy(path)
            table.insert(newPath, k)

            if type(v) == "table" then
                callback(Table.copy(newPath), v) -- Copy the path so it doesn't get modified by the callback
                recursiveIterate(v, newPath)
            else
                callback(Table.copy(newPath), v)
            end
        end
    end

    recursiveIterate(t, {})
end

function Table.findFirstKey(t, callback) -- callback can be nil
    for k, v in pairs(t) do
        if not callback or callback(k, v) then
            return k, v
        end
    end
end

return Table