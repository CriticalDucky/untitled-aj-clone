-- This script creates a connection object that can be used to connect to an event.

local Connection = {}
Connection.__index = Connection

function Connection.new(event, callback)
    local self = setmetatable({}, Connection)

    self._event = event
    self._callback = callback

    return self
end

function Connection:Disconnect()
    self._event:Disconnect(self._callback)
end

local Event = {}
Event.__index = Event

function Event.new()
    local self = setmetatable({}, Event)

    self._connections = {}

    return self
end

function Event:Connect(callback)
    local connection = Connection.new(self, callback)

    table.insert(self._connections, connection)

    return connection
end

function Event:Disconnect(callback)
    for index, connection in ipairs(self._connections) do
        if connection._callback == callback then
            table.remove(self._connections, index)
            break
        end
    end
end

function Event:Fire(...)
    for _, connection in ipairs(self._connections) do
        task.spawn(connection._callback, ...)
    end
end

function Event:Destroy()
    for _, connection in pairs(self._connections) do
        connection:Disconnect()
    end
end

return Event