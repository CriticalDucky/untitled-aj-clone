local ReplicatedStorage = game:GetService "ReplicatedStorage"

local replicatedStorageVendor = ReplicatedStorage:WaitForChild "Vendor"
local replicaServiceFolder = replicatedStorageVendor:WaitForChild "ReplicaService"

local ReplicaController = require(replicaServiceFolder:WaitForChild "ReplicaController")

local replicas = {}

local classes = {
	"PlayerDataPublic",
	"PurchaseRequest",
	"TeleportRequest",
	"ServerUnixTime",
	"PlaceItemRequest",
	"PlayMinigameRequest",
	"LiveServerData",
	"ServerData",
	"SessionInfo",
	"ProfileDataRequest",
	"SetSettingRequest"
}

local inclusiveClasses =
	{ -- Classes that can be found inside a string. For example, "PlayerDataPrivate" can be found inside "PlayerDataPrivate_1234567890"
		"PlayerDataPrivate",
	}

local function getInclusiveClass(class)
	for _, inclusiveClass in pairs(inclusiveClasses) do
		if string.find(class, inclusiveClass) then return inclusiveClass end
	end

	return false
end

local function onReplicaReceived(replica)
	local class = replica.Class

	class = getInclusiveClass(class) or class

	if not replicas[class] then print("Replica recieved: ", class) end

	replicas[class] = replica
end

local replicaCollection = {}

-- Gets the replica of the given class. Class must be a string.
function replicaCollection.get(class: string)
	assert(type(class) == "string", "ReplicaCollection.get: class must be a string")
	assert(table.find(classes, class) or getInclusiveClass(class), "ReplicaCollection.get: class must be a valid class")

	class = getInclusiveClass(class) or class

	local lastPrint = time()

	while not replicas[class] do
		task.wait()

		if time() - lastPrint > 5 then
			print("Waiting for replica", class)
			lastPrint = time()
		end
	end

	return replicas[class]
end

for _, class in ipairs(classes) do
	ReplicaController.ReplicaOfClassCreated(class, onReplicaReceived)
end

ReplicaController.NewReplicaSignal:Connect(onReplicaReceived)
ReplicaController.RequestData()

return replicaCollection
