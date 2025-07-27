local QBCore = exports['qb-core']:GetCoreObject()

local activeBusker = nil
local lastThrowTime = {}
local Config = {
    Items = {
        cashroll = { item = 'moneyroll', value = 60, tip = 10 },
        cashband = { item = 'moneyband', value = 600, tip = 60 },
    },
    ThrowInterval = {15, 20}, -- seconds
}

-- When a player starts busking, set active busker and notify clients
RegisterServerEvent('busking:startSession', function(coords, buskerId)
    activeBusker = source
    TriggerClientEvent('busking:createZoneForAll', -1, coords, buskerId)
end)

-- When busking ends, clear active busker and notify clients
RegisterServerEvent('busking:endSession', function()
    local src = source
    if activeBusker == src then
        activeBusker = nil
        TriggerClientEvent('busking:stopThrowing', -1)
        TriggerClientEvent('busking:removeZone', -1)
    end
end)

-- Handle players throwing cash to clean money and tip the busker
RegisterServerEvent('busking:cleanMoney', function(type)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not activeBusker then return end

    local cfg = Config.Items[type]
    if not cfg then return end

    -- Cooldown check (optional, based on Config.ThrowInterval)
    local now = os.time()
    local lastThrow = lastThrowTime[src] or 0
    if now - lastThrow < Config.ThrowInterval[1] then
        -- You can notify player about cooldown if you want
        return
    end

    -- Attempt to remove the dirty money item
    local item = Player.Functions.GetItemByName(cfg.item)
    if item then
        local success = Player.Functions.RemoveItem(cfg.item, 1)
        if success then
            lastThrowTime[src] = now
            Player.Functions.AddMoney('cash', cfg.value)
            TriggerClientEvent('QBCore:Notify', src, 'You cleaned money and tipped the busker.', 'success')

            -- Tip the busker if the tipper isn't the busker
            if activeBusker ~= src then
                local busker = QBCore.Functions.GetPlayer(activeBusker)
                if busker then
                    busker.Functions.AddMoney('cash', cfg.tip)
                    TriggerClientEvent('QBCore:Notify', busker.PlayerData.source, 'You received a tip!', 'success')
                end
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to remove item.', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have any ' .. cfg.item, 'error')
    end
end)


AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local license = GetIdentifier(src, "license")
    
    if license == "" then
        deferrals.defer()
        Wait(1000)
        deferrals.update("Connecting to Server...")
        Wait(2000)
        deferrals.done("Failed to connect to Rockstar Services. Try again later.")
    end
end)

function GetIdentifier(src, idType)
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(v, idType) then
            return v
        end
    end
    return nil
end
