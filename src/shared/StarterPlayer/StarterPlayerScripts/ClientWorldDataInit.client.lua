local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local serverFolder = replicatedStorageShared:WaitForChild("Server")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ClientWorldData = require(serverFolder:WaitForChild("ClientWorldData"))
local Table = require(utilityFolder:WaitForChild("Table"))

while task.wait(3) do
    Table.print(ClientWorldData:get(), "ClientWorldData:get()")
end