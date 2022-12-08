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

function Table.print(t, note, printTypes)
    local MAX_PRINTS = 300
    local prints = 0

    local function printTable(t, indent)
        if prints >= MAX_PRINTS then
            return
        end

        for k, v in pairs(t) do
            local baseString = (printTypes and " (%s)" or "")
            local keyType = baseString:format(typeof(k))
            local valueType = baseString:format(typeof(v))

            if type(v) == "table" then
                print(indent .. tostring(k) .. keyType .. ":")

                prints += 1

                printTable(v, indent .. "    ")
            else
                print(indent .. tostring(k) .. keyType .. " : " .. tostring(v) .. valueType)

                prints += 1
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

function Table.compare(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return t1 == t2
    end

    for k, v in pairs(t1) do
        if not Table.compare(v, t2[k]) then
            return false
        end
    end

    for k, v in pairs(t2) do
        if not Table.compare(v, t1[k]) then
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

function Table.hasAnything(t)
    for _, _ in pairs(t) do
        return true
    end

    return false
end

function Table.deepReconcile(template, t)
    local function deepReconcile(t1, t2)
        for k, v in pairs(t1) do
            if type(v) == "table" then
                if type(t2[k]) ~= "table" then
                    t2[k] = Table.deepCopy(v)
                else
                    deepReconcile(v, t2[k])
                end
            else
                if t2[k] == nil then
                    t2[k] = v
                end
            end
        end
    end

    deepReconcile(template, t)
end

function Table.safeIndex(t, ...)
    local value = t

    for _, key in pairs({...}) do
        if type(value) == "table" then
            value = value[key]
        else
            return nil
        end
    end

    return value
end

function Table.deepToNumber(t, copy)
    t = if copy then Table.deepCopy(t) else t

    local function deepToNumber(t1)
        for k, v in pairs(t1) do
            if type(v) == "table" then
                deepToNumber(v)
            else
                t1[k] = tonumber(v) or v
            end
        end
    end

    deepToNumber(t)

    return t
end

function Table.deepToNumberKeys(t, copy): table
    t = if copy then Table.deepCopy(t) else t

    local function deepToNumberKeys(t1)
        for k, v in pairs(Table.copy(t1)) do
            if type(v) == "table" then
                deepToNumberKeys(v)
            end

            if type(k) == "string" then
                local numberKey = tonumber(k)

                if numberKey then
                    t1[numberKey] = v
                    t1[k] = nil
                end
            end
        end
    end

    deepToNumberKeys(t)

    return t
end

function Table.selectWithKeys(t, keys) -- takes in an array of keys and returns a table with only those keys
    local selected = {}

    for _, key in pairs(keys) do
        selected[key] = t[key]
    end

    return selected
end


local testTable = { -- has keys of all types and values of all types and many depths
    a = {
        b = 1,
        c = "hello",
        d = false,
        ["2"] = "number key",
        [1] = "number value",
    },
    b = 1,
    c = "hello",
    d = false,
    ["2"] = "number key",
    [1] = "number value",
}

return Table