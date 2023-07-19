return {
    --[[
        Public minigames can be joined even after initializations. They're the ones stored in ServerData with
        minigame indices. These act in a similar manner to party servers.
    ]]
    public = "public",
    --[[
        Instance minigames are only accessible once, and that's when they're initialized.
        The player (or other players) cannot (re)join after leaving. Not stored in ServerData as they are temporary, but accessible through
        LiveServerData until the server shuts down.
    ]]
    instance = "instance",
    --[[
        None is used for when a game does not require the initialization of a minigame server.
        Connect 4, for example, can be played on any server in a GUI.
    ]]
    none = "none",
}