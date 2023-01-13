local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local GAMES_KEY = "games"

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Promise = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Promise"))
local Table = require(replicatedFirstShared:WaitForChild("Utility"):WaitForChild("Table"))

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local Observer = Fusion.Observer

local privateServerId = game.PrivateServerId

local replicaPromise = ReplicaCollection.get("ServerData", true)
    :andThen(function(replica)
        local serverDataValue = Fusion.Value(replica.Data)

        replica:ListenToRaw(function()
            serverDataValue:set(replica.Data)
        end)

        return serverDataValue
    end)

local serverInfoPromise = replicaPromise
    :andThen(function(serverDataValue)
        return Promise.new(function(resolve)
            local disconnect

            local function find()
                local serverData = serverDataValue:get()

                if serverData[privateServerId] then
                    disconnect()
                    resolve(serverData[privateServerId])
                end

                Table.recursiveIterate(serverData, function(path, value)
                    if type(value) == "table" and value.privateServerId == privateServerId then
                        disconnect()

                        local constantKey = path[1]

                        if constantKey == WORLDS_KEY then -- the path is [WORLDS_KEY, worldIndex, "locations", locationEnum]
                            resolve {
                                worldIndex = path[2],
                                locationEnum = path[4],
                            }
                        elseif constantKey == PARTIES_KEY then -- the path is [PARTIES_KEY, partyType, partyIndex]
                            resolve {
                                partyType = path[2],
                                partyIndex = path[3],
                            }
                        elseif constantKey == GAMES_KEY then -- the path is [GAMES_KEY, gameType, gameIndex]
                            resolve {
                                gameType = path[2],
                                gameIndex = path[3],
                            }
                        end
                    end
                end)
            end

            disconnect = Observer(serverDataValue):onChange(find)

            find()
        end)
    end)

local ClientServerData = {}

function ClientServerData.get()
    return ClientServerData:get()
end

function ClientServerData.getWorlds()
    return ClientServerData:get()[WORLDS_KEY]
end

function ClientServerData.getParties()
    return ClientServerData:get()[PARTIES_KEY]
end

function ClientServerData.getGames()
    return ClientServerData:get()[GAMES_KEY]
end

function ClientServerData.promise()
    return replicaPromise
end

function ClientServerData.worldHasLocation(worldIndex, locationEnum)
    local worlds = ClientServerData.getWorlds()

    if worlds[worldIndex] then
        local locations = worlds[worldIndex].locations

        if locations[locationEnum] then
            return true
        end
    end
end

function ClientServerData.getServerInfo()
    return serverInfoPromise
end

return ClientServerData