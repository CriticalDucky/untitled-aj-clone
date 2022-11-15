local itemCategory = require(game:GetService("ReplicatedStorage").Shared.Enums.ItemCategory)

return {
    [itemCategory.furniture] = require(script:WaitForChild("Furniture")),
    [itemCategory.accessory] = require(script:WaitForChild("Accessories")),
    [itemCategory.home] = require(script:WaitForChild("Homes")),
}