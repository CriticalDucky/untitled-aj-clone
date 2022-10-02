local Players = game:GetService("Players")

local friends = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("GetFriends"))(Players.LocalPlayer.UserId)

return friends
