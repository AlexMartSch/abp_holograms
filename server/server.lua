local savedHolograms = {}

function GetSavedHolograms()
    if Config.SaveAlgorithm == 'json' then
        savedHolograms = json.decode(LoadResourceFile(GetCurrentResourceName(), "./data/holograms.json"))
    else
        savedHolograms = json.decode(GetResourceKvpString('savedHolograms') or '{}')
    end
end

GetSavedHolograms()

function SaveHologram()

    local nilCheckHolograms = {}

    for holoId, holoData in pairs(savedHolograms) do
        if holoData then
            nilCheckHolograms[holoId] = holoData
        end
    end

    if Config.SaveAlgorithm == 'json' then
        SaveResourceFile(GetCurrentResourceName(), "./data/holograms.json", json.encode(nilCheckHolograms), -1)
    else
        SetResourceKvp('savedHolograms', json.encode(nilCheckHolograms))
    end

    savedHolograms = nilCheckHolograms
end

lib.addCommand('holoeditor', {
    help = 'Open Hologram Editor',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    lib.callback('abp_holograms:openHoloEditor', source)
end)

lib.addCommand('resetsavedholograms', {
    help = 'Reset (delete) all saved holograms',
    params = {},
    restricted = 'group.admin'
}, function(source, args, raw)
    savedHolograms = {}
    SaveHologram()
    TriggerClientEvent('abp_holograms:UpdateHologramsFromServer', -1, savedHolograms)

    return TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        text = 'Holograms removed!'
    })
end)

lib.addCommand('resethologram', {
    help = 'Reset (delete) single saved hologram',
    params = {
        {
            name = 'hologram',
            type = 'string',
            help = 'Hologram Id',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    if savedHolograms[args.hologram] then
        savedHolograms[args.hologram] = nil
        SaveHologram()

        TriggerClientEvent('abp_holograms:UpdateHologramsFromServer', -1, savedHolograms)

        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            text = 'Hologram removed!'
        })
    end

    return TriggerClientEvent('ox_lib:notify', source, {
        type = 'error',
        text = 'Hologram not found!'
    })
end)

lib.callback.register('abp_holograms:getHolograms', function(source)
    return savedHolograms
end)

lib.callback.register('abp_holograms:saveHologram', function(source, holoId, holoData, announceToServer)
    if not savedHolograms[holoId] then
        savedHolograms[holoId] = holoData

        SaveHologram()

        if announceToServer then
            TriggerClientEvent('abp_holograms:UpdateHologramsFromServer', -1, savedHolograms)
        end

        return true
    end

    return false
end)

lib.callback.register('abp_holograms:updateHologram', function(source, holoId, holoData)
    if savedHolograms[holoId] then
        savedHolograms[holoId] = holoData

        SaveHologram()

        TriggerClientEvent('abp_holograms:UpdateHologram', -1, holoId, holoData)

        return true
    end

    return false
end)

lib.callback.register('abp_holograms:removeHologram', function(source, holoId)
    if savedHolograms[holoId] then
        savedHolograms[holoId] = nil

        SaveHologram()

        TriggerClientEvent('abp_holograms:RemoveHologram', -1, holoId)

        return true
    end

    return false
end)