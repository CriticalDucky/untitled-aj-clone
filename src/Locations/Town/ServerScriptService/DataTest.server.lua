local COOLDOWN = 0

local Players = game:GetService("Players")

local PlayerData = require(game:GetService("ServerStorage").Shared.Data.PlayerData)
local InventoryManager = require(game:GetService("ServerStorage").Shared.Data.Inventory.InventoryManager)
local Currency = require(game:GetService("ServerStorage").Shared.Data.Currency.Currency)
local CurrencyType = require(game.ReplicatedStorage.Shared.Enums.CurrencyType)
local ItemType = require(game.ReplicatedStorage.Shared.Enums.ItemType)
local AccessoryType = require(game.ReplicatedStorage.Shared.Enums.AccessoryType)
local HomeItemType = require(game.ReplicatedStorage.Shared.Enums.HomeItemType)

function changeMoney(player, money)
    print("changeMoney", player.Name, money)

    Currency.increment(player, CurrencyType.money, money)
end

function addPoint(player)
    local playerData = PlayerData.get(player, true)

    print("addPoint", player.Name)

    if playerData then
        playerData:setValue({"awards", "points"}, playerData.tempData.awards.points + 1)
    end
end

lastCooldownTime = 0

workspace.MoneyTakePart.Touched:Connect(function(part)
    local player = Players:GetPlayerFromCharacter(part.Parent)

    if player and time() - lastCooldownTime > COOLDOWN then
        lastCooldownTime = time()
        changeMoney(player, -10)
    end
end)

workspace.MoneyAddPart.Touched:Connect(function(part)
    local player = Players:GetPlayerFromCharacter(part.Parent)

    if player and time() - lastCooldownTime > COOLDOWN then
        lastCooldownTime = time()
        changeMoney(player, 10)
    end
end)

workspace.Points.Touched:Connect(function(part)
    local player = Players:GetPlayerFromCharacter(part.Parent)

    if player and time() - lastCooldownTime > COOLDOWN then
        lastCooldownTime = time()
        addPoint(player)
    end
end)

workspace.Hat.Touched:Connect(function(part)
    local player = Players:GetPlayerFromCharacter(part.Parent)

    if player and time() - lastCooldownTime > COOLDOWN then
        lastCooldownTime = time()

        print(InventoryManager.newItemInInventory(ItemType.accessory, AccessoryType.hat, player))
    end
end)

workspace.BeachBall.Touched:Connect(function(part)
    local player = Players:GetPlayerFromCharacter(part.Parent)

    if player and time() - lastCooldownTime > COOLDOWN then
        lastCooldownTime = time()

        print(InventoryManager.newItemInInventory(ItemType.homeItem, HomeItemType.beachBall, player))
    end
end)
