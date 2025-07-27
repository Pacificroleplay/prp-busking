local QBCore = exports['qb-core']:GetCoreObject()

local isBusking = false
local buskingZone = nil
local buskerId = nil
local buskingRadius = 10.0
local zoneName = 'busking_zone'
local currentBuskerId = nil 
local isCleaning = false
local cleaningType = nil
local cleaningThread = nil

-- Create busking zone around busker for others to interact with
local function createBuskingZone(coords, buskerServerId)
    buskingZone = lib.zones.sphere({
        coords = coords,
        radius = buskingRadius,
        debug = false,
        inside = function()
            if cache.serverId ~= buskerServerId and not isCleaning then
                lib.showTextUI('[E] Throw Cash', { position = 'bottom-center' })
                CreateThread(function()
                    while lib.isTextUIOpen() do
                        if IsControlJustReleased(0, 38) then -- E key
                            TriggerEvent('busking:throwCashMenu')
                            break
                        end
                        Wait(0)
                    end
                end)
            end
        end,
        onExit = function()
            lib.hideTextUI()
            if isCleaning then
                isCleaning = false
                cleaningType = nil
                if cleaningThread then
                    TerminateThread(cleaningThread)
                    cleaningThread = nil
                end
                lib.notify({ title = 'Busking', description = 'You stopped throwing money.', type = 'inform' })
            end
        end,
        name = zoneName
    })
end

-- Toggle busking state for the player
local function toggleBusking()
    if isBusking then
        isBusking = false
        lib.notify({ title = 'Busking', description = 'You stop busking.', type = 'inform' })
        lib.hideTextUI()
        if buskingZone then
            buskingZone:remove()
            buskingZone = nil
        end
        TriggerServerEvent('busking:endSession')
        currentBuskerId = nil
    else
        isBusking = true
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        buskerId = cache.serverId
        currentBuskerId = buskerId
        lib.notify({ title = 'Busking', description = 'You start busking.', type = 'success' })
        TriggerServerEvent('busking:startSession', coords, buskerId)
    end
end

exports.ox_target:addModel(`v_club_roc_micstd`, {
    {
        name = 'start_busking',
        label = 'Start Busking',
        icon = 'fas fa-microphone',
        distance = 2.0,
        canInteract = function()
            local player = QBCore.Functions.GetPlayerData()
            return not isBusking and Config.Allowed[player.citizenid]
        end,
        onSelect = function()
            toggleBusking()
        end
    },
    {
        name = 'stop_busking',
        label = 'Stop Busking',
        icon = 'fas fa-hand-paper',
        distance = 2.0,
        canInteract = function()
            local player = QBCore.Functions.GetPlayerData()
            return isBusking and Config.Allowed[player.citizenid]
        end,
        onSelect = function()
            toggleBusking()
        end
    }
})

-- Show menu for throwing cash rolls or bands
RegisterNetEvent('busking:throwCashMenu', function()
    local input = lib.inputDialog('Throw Dirty Money', {
        {
            type = 'select',
            label = 'Select Money Type',
            options = {
                {label = 'Cash Rolls', value = 'cashroll'},
                {label = 'Cash Bands', value = 'cashband'},
            },
            required = true,
            icon = 'money-bill-wave'
        }
    })

    if not input or not input[1] then return end
    cleaningType = input[1]
    isCleaning = true

    lib.notify({ title = 'Money Cleaning', description = 'You start throwing ' .. cleaningType, type = 'success' })

    -- Play the 'makeitrain' emote for the cleaner
    ExecuteCommand('e makeitrain')

    cleaningThread = CreateThread(function()
        while isCleaning do
            TriggerServerEvent('busking:cleanMoney', cleaningType)

            local waitTime = math.random(Config.ThrowInterval[1], Config.ThrowInterval[2])
            Wait(waitTime * 1000)
        end
    end)
end)


-- Stop cleaning money when busker ends busking
RegisterNetEvent('busking:stopThrowing', function()
    if interactingPlayers[cache.serverId] then
        interactingPlayers[cache.serverId] = nil
        lib.notify({ title = 'Busking', description = 'The busker has stopped. You stop cleaning money.', type = 'error' })
    end
end)

-- Create busking zone client-side when busking starts server-side
RegisterNetEvent('busking:createZoneForAll', function(coords, buskerServerId)
    if cache.serverId ~= buskerServerId then
        createBuskingZone(coords, buskerServerId)
    end
end)

-- Remove busking zone and cleanup when busking ends
RegisterNetEvent('busking:removeZone', function()
    if buskingZone then
        buskingZone:remove()
        buskingZone = nil
    end
    lib.hideTextUI()

    if isCleaning then
        isCleaning = false
        cleaningType = nil
        if cleaningThread then
            TerminateThread(cleaningThread)
            cleaningThread = nil
        end
        lib.notify({ title = 'Busking', description = 'Busking ended. You stopped throwing money.', type = 'inform' })
    end
end)