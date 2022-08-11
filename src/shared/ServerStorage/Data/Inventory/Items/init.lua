local itemType = require(game:GetService("ReplicatedStorage").Shared.Enums.ItemType)

return {
    [itemType.homeItem] = require(script.HomeItems),
    [itemType.accessory] = require(script.Accessories),
}