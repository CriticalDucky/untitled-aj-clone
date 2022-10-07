local ReplicationType = require(game:GetService("ReplicatedStorage").Shared.Enums.ReplicationType)

return {
    friendLocations = {
        _replication = ReplicationType.private,
        locations = {}
    }
}