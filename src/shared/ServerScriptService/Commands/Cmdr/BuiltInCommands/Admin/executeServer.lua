local loadstringSub = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Loadstring"))

return function(context, runContext, command)
    local function replyError(message)
        context:Reply(message, Color3.new(1, 0.188235, 0.188235))
    end

    local env, failtureReason = loadstringSub(command)

    if not failtureReason then
        local success, err = pcall(env)

        if not success then
            replyError(err)
        end
    else
        replyError(failtureReason)
    end

    return ""
end