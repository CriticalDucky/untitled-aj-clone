local RunService = game:GetService("RunService")

local function getModel(modelType, name)
    local model

    local function iterate(_, object)
        if object:IsA("Folder") and object.Name == "Models" then
            for _, descendant in ipairs(object:GetDescendants()) do
                if descendant.Name == name and descendant:FindFirstAncestor(modelType) then
                    model = descendant
                    break
                end
            end
        end
    end

    table.foreach(game:GetService("ReplicatedStorage"):GetDescendants(), iterate)
    table.foreach(game:GetService("ReplicatedFirst"):GetDescendants(), iterate)
    
    if RunService:IsServer() then
        table.foreach(game:GetService("ServerStorage"):GetDescendants(), iterate)
    end

    return model
end

return getModel