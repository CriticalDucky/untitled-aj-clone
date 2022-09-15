local names = {
    "name1",
    "name2",
    "name3",
}

local WorldNames = {}

function WorldNames.get(index)
    return names[index] or ("World " .. index)
end

return names