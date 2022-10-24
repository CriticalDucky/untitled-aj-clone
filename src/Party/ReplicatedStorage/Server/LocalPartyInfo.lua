local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")

local Parties = require(serverFolder:WaitForChild("Parties"))

local LocalPartyInfo = {}

for partyType, partyInfo in pairs(Parties) do
    if partyInfo.placeId == game.PlaceId then
        LocalPartyInfo.partyType = partyType
        break
    end
end

return LocalPartyInfo

