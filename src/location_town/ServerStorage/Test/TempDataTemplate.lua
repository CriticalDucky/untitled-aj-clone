local replicationType = require(game.ReplicatedStorage.Shared.Enums.ReplicationType)

return {
    awards = {
        _replication = replicationType.private,
        points = 0
    }
}