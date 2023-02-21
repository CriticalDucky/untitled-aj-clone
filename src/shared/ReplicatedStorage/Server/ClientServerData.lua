local WORLDS_KEY = "worlds"
local PARTIES_KEY = "parties"
local GAMES_KEY = "games"

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local replicatedStorageShared = ReplicatedStorage:WaitForChild("Shared")
local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")
local replicationFolder = replicatedStorageShared:WaitForChild("Replication")
local utilityFolder = replicatedFirstShared:WaitForChild("Utility")

local ReplicaCollection = require(replicationFolder:WaitForChild("ReplicaCollection"))
local Promise = require(utilityFolder:WaitForChild("Promise"))
local Table = require(utilityFolder:WaitForChild("Table"))
local Types = require(utilityFolder:WaitForChild("Types"))

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local Observer = Fusion.Observer

type ServerIdentifier = Types.ServerIdentifier
type Promise = Types.Promise

local privateServerId = game.PrivateServerId
local serverDataValue = Value({})

local function find(callback: ({}) -> any) -- Merger of Fusion and Promise
    return Promise.new(function(resolve, reject, onCancel)
        local disconnect

        local function find()
            local serverData = serverDataValue:get()

            local result = callback(serverData)

            if result then
                disconnect()
                resolve(result)
            end
        end

        disconnect = Observer(serverDataValue):onChange(find)

        find()

        onCancel(function()
            disconnect()
            reject()
        end)
    end)
end

local replicaPromise = ReplicaCollection.get("ServerData", true)
    :andThen(function(replica)
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

--[[
    You might notice that ClientServerData functions return both promises and values. This is because UI will use the values (for within computed values)
    and other stuff will use the promises (for when the server data is needed).
]]

local ClientServerData = {}

--[[
    Returns a promise that resolves the server data.
]]
function ClientServerData.get(): Promise
    return replicaPromise
end

--[[
    Returns a promise that resolves the worlds table.
]]
function ClientServerData.getWorlds(): Promise
    return find(function(serverData)
        return serverData[WORLDS_KEY]
    end)
end

--[[
    Returns a promise that resolves the parties table.
]]
function ClientServerData.getParties(): Promise
    return find(function(serverData)
        return serverData[PARTIES_KEY]
    end)
end

--[[
    Returns a promise that resolves the games table.
]]
function ClientServerData.getGames(): Promise
    return find(function(serverData)
        return serverData[GAMES_KEY]
    end)
end

--[[
    Returns a promise resolving to a boolean indicating whether world has a specific location.
]]
function ClientServerData.worldHasLocation(worldIndex, locationEnum): Promise
    ClientServerData.getWorlds():andThen(function(worlds)
        return worlds[worldIndex] and worlds[worldIndex].locations[locationEnum]
    end)
end

--[[
    Returns a promise that resolves the serverInfo.
]]
function ClientServerData.getServerInfo(): Promise
    return serverInfoPromise
end

return ClientServerData