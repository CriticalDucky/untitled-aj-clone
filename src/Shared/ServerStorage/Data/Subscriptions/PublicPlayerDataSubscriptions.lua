--!strict

local SUBSCRIPTION_RETRIEVAL_INTERVAL = 10

--#region Imports

local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

local ClientServerCommunication = require(ReplicatedStorage.Shared.Data.ClientServerCommunication)
local PlayerDataManager = require(ServerStorage.Shared.Data.PlayerDataManager)

--#endregion

--#region Subscriptions

local subscriptions = {}

local function subscribe(player: Player, userId: number)
	if subscriptions[player] then return end

    local subscriptionInfo = {}
    subscriptions[player] = subscriptionInfo

    subscriptionInfo.userId = userId
	subscriptionInfo.thread = task.spawn(function()
		repeat
			ClientServerCommunication.replicateAsync(
				"UpdatePublicPlayerData",
				PlayerDataManager.viewOfflinePersistentDataAsync(userId),
				player
			)
		until not task.wait(SUBSCRIPTION_RETRIEVAL_INTERVAL)
	end)
end

local function unsubscribe(player: Player)
	if not subscriptions[player] then return end

	task.cancel(subscriptions[player].thread)
	subscriptions[player] = nil
end

Players.PlayerRemoving:Connect(unsubscribe)

--#endregion

local PublicPlayerDataSubscriptions = {}

function PublicPlayerDataSubscriptions.subscribe(player: Player, userId: number)
    if not player:IsDescendantOf(game) then return end

    local subscriptionInfo = subscriptions[player]

    if subscriptionInfo then
        if subscriptionInfo.userId == userId then
            return
        else
            unsubscribe(player)
        end
    end

    subscribe(player, userId)
end

function PublicPlayerDataSubscriptions.unsubscribe(player: Player)
    if not player:IsDescendantOf(game) then return end

    unsubscribe(player)
end

return PublicPlayerDataSubscriptions
