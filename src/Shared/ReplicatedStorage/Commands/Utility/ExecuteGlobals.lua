local ExecuteGlobals = {}

function ExecuteGlobals.i(instanceName: string): Instance?
    return game:FindFirstChild(instanceName, true)
end

function ExecuteGlobals.m(moduleName: string): any?
    local module = ExecuteGlobals.i(moduleName)

    if module and module:IsA("ModuleScript") then return require(module) end
end

return ExecuteGlobals