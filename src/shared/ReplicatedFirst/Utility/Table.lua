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