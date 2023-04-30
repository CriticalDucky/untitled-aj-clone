local loadstringSub = require(game:GetService("ReplicatedFirst"):WaitForChild("Shared"):WaitForChild("Utility"):WaitForChild("Loadstring"))

return {
	Name = "execute";
	Aliases = {};
	Description = "Execute Lua 5.1 code on either the client or server.";
	Group = "DefaultAdmin";
	Args = {
		{
            Type = "string",
            Name = "runContext",
            Description = "'Client' or 'Server': where to run the command",
            Optional = false,
            Default = "Client"
        },

        {
            Type = "string",
            Name = "command",
            Description = "The command to run",
            Optional = false,
            Default = "print('Hello, world!')"
        },
	};
    ClientRun = function(context, runContext, command)
        local function replyError(message)
            context:Reply(message, Color3.new(1, 0.188235, 0.188235))
        end

        if string.lower(runContext) == "client" then
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
        else
            return
        end
    end;
}