local MAX_RETRIES = 3

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")

local Message = {}

function Message.publish(topic, message)
    local encodedMessage = HttpService:JSONEncode(message)

    local function try()
        return pcall(function()
            return MessagingService:PublishAsync(topic, encodedMessage)
        end)
    end

    for i = 1, MAX_RETRIES do
        local success = try()

        if success then
            return true
        end
    end
end

function Message.subscribe(topic, callback)
    local function try()
        return pcall(function()
            return MessagingService:SubscribeAsync(topic, function(message)
                callback({
                    Data = if message.Data then HttpService:JSONDecode(message.Data or "") else message.Data, 
                    Sent = message.Sent
                })
            end)
        end)
    end

    for i = 1, MAX_RETRIES do
        local success, subscribeConnection = try()

        if success then
            return subscribeConnection
        end
    end

    warn("Failed to subscribe to topic: " .. topic)
end

return Message