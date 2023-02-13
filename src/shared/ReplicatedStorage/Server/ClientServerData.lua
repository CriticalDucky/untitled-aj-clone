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

local privateServerId = game.PrivateServerId
local serverDataValue = Value({})

local function find(callback: ({}) -> any)
    return Promise.new(function(resolve)
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

function ClientServerData.get()
    return serverDataValue:get()
end

--[[
    Returns the worlds table from the server data.
    !! THIS DOES NOT RETURN A PROMISE !!
]]
function ClientServerData.getWorlds()
    return serverDataValue:get()[WORLDS_KEY]
end

--[[ 
    Returns the parties table from the server data.
    !! THIS DOES NOT RETURN A PROMISE !!
]]
function ClientServerData.getParties()
    return serverDataValue:get()[PARTIES_KEY]
end

--[[ 
    Returns the games table from the server data.
    !! THIS DOES NOT RETURN A PROMISE !!
]]
function ClientServerData.getGames()
    return serverDataValue:get()[GAMES_KEY]
end

--[[
    Returns a promise that resolves the server data.
]]
function ClientServerData.promise()
    return replicaPromise
end

--[[
    Returns a promise that resolves the worlds table.
]]
function ClientServerData.promiseWorlds()
    return find(function(serverData)
        return serverData[WORLDS_KEY]
    end)
end

--[[
    Returns a promise that resolves the parties table.
]]
function ClientServerData.promiseParties()
    return find(function(serverData)
        return serverData[PARTIES_KEY]
    end)
end

--[[
    Returns a promise that resolves the games table.
]]
function ClientServerData.promiseGames()
    return find(function(serverData)
        return serverData[GAMES_KEY]
    end)
end

--[[
    Returns a boolean indicating whether world has a specific location.
    !! THIS DOES NOT RETURN A PROMISE !!
]]
function ClientServerData.worldHasLocation(worldIndex, locationEnum)
    local worlds = ClientServerData.getWorlds()

    if worlds and worlds[worldIndex] then
        local locations = worlds[worldIndex].locations

        if locations[locationEnum] then
            return true
        end
    end

    return false
end

--[[
    Returns a promise that resolves the serverInfo.
]]
function ClientServerData.getServerInfo()
    return serverInfoPromise
end

return ClientServerData