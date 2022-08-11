local COOLDOWN = 3

local Players = game:GetService("Players")

local PlayerData = require(game.ServerStorage.Shared.Data.PlayerData)

function changeMoney(player, money)
    local playerData = PlayerData.get(player, true)

    print("changeMoney", player.Name, money)

    if playerData then
        playerData:setValue({"currency", "money"}, playerData.profile.Data.currency.money + money)
    end
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

