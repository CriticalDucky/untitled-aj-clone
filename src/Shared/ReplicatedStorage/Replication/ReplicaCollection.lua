local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageVendor = ReplicatedStorage:WaitForChild "Vendor"
local replicaServiceFolder = replicatedStorageVendor:WaitForChild "ReplicaService"

local ReplicaController = require(replicaServiceFolder:WaitForChild "ReplicaController")

local replicas = {}

local ReplicaCollection = {}

-- Gets the replica of the given class. Class must be a string.
function ReplicaCollection.waitForReplica(class: string)
	assert(type(class) == "string", "ReplicaCollection.get: class must be a string")

	local beginWaitTime = time()
	local warned = false

	while not replicas[class] do
		task.wait()

		if time() - beginWaitTime > 5 and not warned then
			warn("Infinite yield possible for replica of class ", class)
			warned = true
		end
	end

	return replicas[class]
end

ReplicaController.NewReplicaSignal:Connect(function(replica)
	local class = if string.find(replica.Class, "^.*__%$.-$")
		then string.sub(replica.Class, 1, string.find(replica.Class, "__%$.-$") - 1)
		else replica.Class

	if replicas[class] then warn("A replica of class", class, "already exists, so the old one will be overwritten.") end

	replicas[class] = replica
end)

ReplicaController.RequestData()

return ReplicaCollection
