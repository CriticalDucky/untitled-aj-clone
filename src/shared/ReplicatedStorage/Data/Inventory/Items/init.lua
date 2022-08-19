local itemType = require(game:GetService("ReplicatedStorage").Shared.Enums.ItemType)

return {
    [itemType.furniture] = require(script.Furniture),
    [itemType.accessory] = require(script.Accessories),
}