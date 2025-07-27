Config = {}

-- Items that can be cleaned during busking with their properties
Config.Items = {
    cashroll = { 
        item = 'moneyroll',   -- Item name to remove from player inventory
        value = 60,           -- Cash player receives when cleaning this item
        tip = 10              -- Tip the busker receives when a player cleans this item
    },
    cashband = { 
        item = 'moneyband',
        value = 600,
        tip = 60
    },
}

-- Time interval (in seconds) between cash throws/cleaning attempts
Config.ThrowInterval = {15, 20}

-- List of allowed citizen IDs that can start busking
Config.Allowed = {
    ["ZEF48533"] = true,
    ["DQS15409"] = true,
    ["VLC97653"] = true,
    ["WPV45309"] = true,
    ["MQJ58231"] = true,
    ["LRU71618"] = true,
}