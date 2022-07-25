local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")

local dataCommunicationFolder = ReplicatedStorageShared:WaitForChild("DataCommunication")
local sendDataEvent = dataCommunicationFolder:WaitForChild("SendData")

local Fusion = require(ReplicatedStorageShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local New = Fusion.New
local Children = Fusion.Children
local Computed = Fusion.Computed
local Observer = Fusion.Observer
local Hydrate = Fusion.Hydrate
local unwrap = Fusion.unwrap

local playerConnections = {}
local playerData = {}

local function cleanAbsentPlayer()
    for player, connection in pairs(playerConnections) do
        if not Players:FindFirstChild(player.Name) then
            connection()
            playerConnections[player] = nil
            playerData[player] = nil
        end
    end
end

local function setData(player, value, ...)
    local currentData = playerData[player]:get()
    local lastIndexed = nil
    local argsTable = {...}

    for i = 1, #argsTable do
        local key = argsTable[i]

        if lastIndexed then
            if lastIndexed[key] then
                lastIndexed = lastIndexed[key]
            else
                lastIndexed[key] = if (i == #argsTable) then value else {}
                lastIndexed = lastIndexed[key]
            end
        else
            lastIndexed = currentData[key]
        end
    end

    playerData[player]:set(currentData)
end

local function playerAdded(player)
    local dataTable = Value {
        private = {},
        public = {}
    }

    playerData[player] = dataTable

    local observedData = Observer(dataTable)

    playerConnections[player] = observedData:onChange(function()
        sendDataEvent:FireAllClients(player, observedData:get().public, "public")
        sendDataEvent:FireClient(player, observedData:get().private, "private")
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.ChildRemoved:Connect(cleanAbsentPlayer)

return {
    setData = setData,
    playerData = playerData,
}