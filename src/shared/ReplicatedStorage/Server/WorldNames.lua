local names = {
    "Makalu",
    "Manaslu",
    "Krakatoa",
    "Broad",
    "Helens",
    "Everest",
    "Tambora",
    "Kilauea",
}

local WorldNames = {}

function WorldNames.get(index)
    return names[index] or ("World " .. index)
end

return WorldNames