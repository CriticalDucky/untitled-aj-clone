local loadstring = require(game:GetService("ReplicatedStorage"):WaitForChild("Vendor"):WaitForChild("Loadstring"))

return function(context, runContext, command)
    local function replyError(message)
        context:Reply(message, Color3.new(1, 0.188235, 0.188235))
    end

    if string.lower(runContext) == "server" then
        local env, failtureReason = loadstring(command)

        if not failtureReason then
            local success, err = pcall(env)

            if not success then
                replyError(err)
            end
        else
            replyError(failtureReason)
        end
    else
        replyError("Invalid run context")
    end

    return ""
end