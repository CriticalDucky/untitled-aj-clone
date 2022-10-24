local ServerStorage = game:GetService("ServerStorage")

local serverStorageShared = ServerStorage.Shared
local dataFolder = serverStorageShared.Data

local ReplicaService = require(dataFolder.ReplicaService)

local timeReplica = ReplicaService.NewReplica({
    ClassToken = ReplicaService.NewClassToken("ServerUnixTime"),
    Data = {
        time = os.time()
    },
    Replication = "All"
})

while task.wait(180) do
    timeReplica:SetValue({"time"}, os.time())
end