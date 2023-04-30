local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data

local ReplicaService = require(dataFolder.ReplicaService)

local timeReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ServerUnixTime"),
    Data = {
        timeInfo = {
            unix = os.time()
        }
    },
    Replication = "All"
})

while task.wait(180) do
    timeReplica:SetValue({"timeInfo", "unix"}, os.time())
end