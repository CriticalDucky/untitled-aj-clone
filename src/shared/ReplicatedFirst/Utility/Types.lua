export type PlayerData = {
    setValue: (PlayerData, path: {}, value: any) -> nil,
    setValues: (PlayerData, path: {}, values: {}) -> nil,
    arrayInsert: (PlayerData, path: {}, value: any) -> nil,
    arraySet: (PlayerData, path: {}, index: number, value: any) -> nil,
    arrayRemove: (PlayerData, path: {}, index: number) -> nil,
    player: Player,
    profile: table,
}

export type HomeServerInfo = {
    serverCode: string,
    privateServerId: string,
}

export type InventoryItem = {
	id: string,
	itemCategory: string | number,
	itemEnum: string | number,
    placedItems: {}?,
}

return nil