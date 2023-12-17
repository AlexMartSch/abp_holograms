CreateThread(function()

    local showHologramIds = false

    local cache_createdHolograms = nil
    local cache_currentHologramId = nil

    local editor_positionThread = false

    function ShowHologramIds()
        CreateThread(function() 
            while showHologramIds do

                for holoId, holoData in pairs(Config.__HologramsObjects) do
                    if holoData.enabled then
                        local pos = holoData.data.position + vector3(0, 0, 3)
                        local distance = math.floor(#(pos - GetEntityCoords(PlayerPedId())))
                        
                        if distance <= 70 then
                            DrawText3D(pos, "HoloID: ~y~" .. holoId, true, 4.0, 0)
                        end
                    end
                end

                Wait(0)
            end
        end)
    end

    function OpenCreatorInput()
        local input = lib.inputDialog('Creating Hologram', {
            {type = 'input',    label = 'Holo ID',          description = 'Some unique identificator',      required = true, min = 4, max = 16},
            {type = 'input',    label = 'URL Target',       default = cache_createdHolograms and cache_createdHolograms.urlTarget,   description = 'Set URL Target for Hologram',    required = true, min = 10, max = 256},
            {type = 'number',   label = 'Distance View',    default = cache_createdHolograms and cache_createdHolograms.distanceView, description = 'Max distance of render',         required = true, icon = 'hashtag', min = 10, max = 500},

            {type = 'number',   label = 'Scale X',  precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.scale.x, description = 'Resolution Scale X', icon = 'hashtag', min = 64, max = 2048, required = true},
            {type = 'number',   label = 'Scale Y',  precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.scale.y, description = 'Resolution Scale Y', icon = 'hashtag', min = 64, max = 2048, required = true},

            {type = 'checkbox', label = 'Hologream Always Rotate',    checked = false},
            {type = 'checkbox', label = 'Hologram Follow Player Cam', checked = false},
            {type = 'checkbox', label = 'Hologram Bob Up And Down',   checked = false},

            {type = 'checkbox', label = 'Show hologram inmediately',  description = 'Show hologram inmediately',      icon = 'eye', checked = true},
            
            {type = 'select',   label = 'Hologram Type', description = 'Hologram world type', icon = 'tag', default = '2d', options = {
                {label = 'Plain 2D', value = '2d'},
                {label = 'Cube 3D', value = '3d'},
            }},

            {type = 'checkbox', label = 'Display to server now',  checked = true},
        })

        if input then

            cache_createdHolograms = {
                enabled = true,

                urlTarget = input[2],
                attachTo = 'world',
		        type = 'hologram',

                typeProperties = {
                    rotate = input[6],
                    cameraFollow = input[7],
                    bobUpAndDown = input[8],
                    type = (input[10] == "2d" and 8 or 43),

                    scale = vec3(5, 5, 5),
                    rotation = vec3(90, 0, 0),
                },

                position = GetEntityCoords(PlayerPedId()),
                distanceView = input[3],
                scale = vec2(input[5], input[4]),

                visible = input[9],
            }

            if Config.Holograms[input[1]] then
                return lib.notify({
                    title = 'Hologram ID already exists',
                    description = 'Hologram ID "'.. input[1] ..'" already exists.',
                    type = 'error'
                })
            end

            local displayToServer = input[11]
            local success = lib.callback.await('abp_holograms:saveHologram', 0, string.lower(input[1]), cache_createdHolograms, displayToServer)

            if success then
                lib.notify({
                    title = 'Hologram Created',
                    description = 'Hologram "'.. input[1] ..'" ready for edit.',
                    type = 'success'
                })

                if not displayToServer then
                    Config.Holograms[input[1]] = cache_createdHolograms
                    InitializeDUI()
                end

                cache_createdHolograms = nil
            end

        end
    end

    function OpenSelectHologramToEditInput()

        local elements = {
            {
                type = 'input',
                label = 'Hologram ID',
                description = 'Some unique identificator',
            },
            {
                type = 'select',
                label = 'Hologram',
                description = 'Select near hologram to edit',
                options = {},
            }
        }

        for holoId, holoData in pairs(Config.__HologramsObjects) do
            if holoData.enabled and holoData.visible then
                local pos = holoData.data.position + vector3(0, 0, 3)
                local distance = math.floor(#(pos - GetEntityCoords(PlayerPedId())))
                
                if distance <= 50 then
                    table.insert(elements[2].options, {
                        label = string.lower(holoId),
                        value = holoId,
                    })
                end
            end
        end

        local input = lib.inputDialog('Hologram List', elements)

        if input then
            local holoName = input[2]
            if input[1] and input[1] ~= "" then
                holoName = string.lower(input[1])
                if not Config.__HologramsObjects[holoName] then
                    return lib.notify({
                        title = 'Hologram ID not exists',
                        description = 'Hologram ID "'.. holoName ..'" not exists.',
                        type = 'error'
                    })
                end
            end

            if input[1] == "" and not input[2] then
                return lib.notify({
                    title = 'Hologram not selected',
                    description = 'Hologram not selected.',
                    type = 'error'
                })
            end

            

            cache_currentHologramId = holoName

            lib.setMenuOptions('abpHologram_EditorMenu_editing', {label = 'Editing: '.. holoName}, 1)
            lib.showMenu('abpHologram_EditorMenu_editing')
        end

    end

    function OpenEditorMenuInput()
        local input = lib.inputDialog('Creating Hologram', {
            {type = 'input',    label = 'Holo ID',          default = cache_currentHologramId,      disabled = true},
            {type = 'input',    label = 'URL Target',       default = cache_createdHolograms and cache_createdHolograms.data.urlTarget,   description = 'Set URL Target for Hologram',    required = false, min = 10, max = 256},
            {type = 'input',    label = 'Html Target',       default = cache_createdHolograms and cache_createdHolograms.data.htmlTarget,   description = 'Set HTML Target for Hologram',    required = false, min = 10, max = 256},
            {type = 'number',   label = 'Distance View',    default = cache_createdHolograms and cache_createdHolograms.data.distanceView, description = 'Max distance of render',         required = true, icon = 'hashtag', min = 10, max = 500},

            {type = 'number',   label = 'Scale X',   precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.data.scale.y, description = 'Resolution Scale X', icon = 'hashtag', min = 64, max = 2048, required = true},
            {type = 'number',   label = 'Scale Y',   precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.data.scale.x, description = 'Resolution Scale Y', icon = 'hashtag', min = 64, max = 2048, required = true},

            {type = 'checkbox', label = 'Hologream Always Rotate',    checked = cache_createdHolograms and cache_createdHolograms.data.typeProperties.rotate},
            {type = 'checkbox', label = 'Hologram Follow Player Cam', checked = cache_createdHolograms and cache_createdHolograms.data.typeProperties.cameraFollow},
            {type = 'checkbox', label = 'Hologram Bob Up And Down',   checked = cache_createdHolograms and cache_createdHolograms.data.typeProperties.bobUpAndDown},

            {type = 'checkbox', label = 'Visibility',  description = 'Show hologram inmediately',      icon = 'eye', checked = cache_createdHolograms and cache_createdHolograms.data.visible},
            
            {type = 'select',   label = 'Hologram Type', description = 'Hologram world type', icon = 'tag', default = cache_createdHolograms and cache_createdHolograms.data.typeProperties.type == 43 and '3d' or '2d', options = {
                {label = 'Plain 2D', value = '2d'},
                {label = 'Cube 3D', value = '3d'},
            }},
        })

        if input then

            local currentHologram = Config.__HologramsObjects[cache_currentHologramId]

            local position = currentHologram.data.position
            local typePropertiesScale = vec3(currentHologram.data.typeProperties.scale.x, currentHologram.data.typeProperties.scale.y, currentHologram.data.typeProperties.scale.z)
            local typePropertiesRotation = vec3(currentHologram.data.typeProperties.rotation.x, currentHologram.data.typeProperties.rotation.y, currentHologram.data.typeProperties.rotation.z)

            cache_createdHolograms = {
                enabled = true,
                attachTo = 'world',
		        type = 'hologram',

                typeProperties = {
                    rotate = input[7],
                    cameraFollow = input[8],
                    bobUpAndDown = input[9],
                    type = (input[11] == "2d" and 8 or 43),

                    scale = typePropertiesScale,
                    rotation = typePropertiesRotation,
                },

                position = position,
                distanceView = input[3],
                scale = vec2(input[6], input[5]),

                visible = input[10],
            }

            if input[2] ~= "" then
                cache_createdHolograms.urlTarget = input[2]
            end

            if input[3] then
                cache_createdHolograms.htmlTarget = input[3]
            end

            lib.callback.await('abp_holograms:updateHologram', 0, cache_currentHologramId, cache_createdHolograms)
        end
    end

    function OpenScalingMenu()
        local input = lib.inputDialog('Creating Hologram', {
            {type = 'input',    label = 'Holo ID',          default = cache_currentHologramId,      disabled = true},

            {type = 'number',   label = 'Scale X', precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.data.typeProperties.scale.x, description = 'World Scale X', icon = 'hashtag', min = 0.5, max = 50, required = true},
            {type = 'number',   label = 'Scale Y', precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.data.typeProperties.scale.y, description = 'World Scale Y', icon = 'hashtag', min = 0.5, max = 50, required = true},
            {type = 'number',   label = 'Scale Y', precision = 2, step = 0.1, default = cache_createdHolograms and cache_createdHolograms.data.typeProperties.scale.z, description = 'World Scale Y', icon = 'hashtag', min = 0.5, max = 50, required = true},
        })

        if input then
            cache_createdHolograms.data.typeProperties.scale = vector3(input[2], input[3], input[4])

            lib.callback.await('abp_holograms:updateHologram', 0, cache_currentHologramId, cache_createdHolograms.data)
        end

        
    end

    lib.registerMenu({
        id = 'abpHologram_EditorMenu_editing',
        title = 'Editing Hologram',
        position = 'top-right',

        options = {
            {label = 'Editing: ',       icon = 'tag',  close=false},
            {label = 'Setup basic',     icon = 'gear', description = 'Open basic setup menu'},
            {label = 'Setup Rotation',  icon = 'gear', description = 'Start Rotation Setup'},
            {label = 'Setup Position',  icon = 'gear', description = 'Start Position Setup'},
            {label = 'Setup Scaling',   icon = 'gear', description = '3D Scaling'},
            {label = 'Delete',          icon = 'trash', description = 'Delete Hologram'},
        },
    }, function(selected, scrollIndex, args)
        cache_createdHolograms = Config.__HologramsObjects[cache_currentHologramId]

        if selected == 2 then
            OpenEditorMenuInput()

        elseif selected == 3 then
            StartRotationThread()
        elseif selected == 4 then
            StartPositionThread()
        elseif selected == 5 then
            OpenScalingMenu()
        elseif selected == 6 then
            local alert = lib.alertDialog({
                header = 'Deleting Hologram: ' .. cache_currentHologramId,
                content = 'Are you sure?',
                centered = true,
                cancel = true
            })

            if alert == 'confirm' then
                lib.callback.await('abp_holograms:removeHologram', 0, cache_currentHologramId)

                Config.__HologramsObjects[cache_currentHologramId] = nil

                lib.notify({
                    title = 'Hologram Deleted',
                    description = 'Hologram "'.. cache_currentHologramId ..'" deleted.',
                    type = 'success'
                })

                cache_createdHolograms = nil
                cache_currentHologramId = nil

                
            end
        end
    end)

    lib.registerMenu({
        id = 'abpHologram_EditorMenu',
        title = 'Hologram Editor',
        position = 'top-right',

        options = {
            {label = 'Create Hologram',    icon = 'wand-magic-sparkles', description = 'Create new Hologram'},
            {label = 'Edit Hologram',      icon = 'pen', description = 'Edit existing hologram'},
            {label = 'Toggle Hologram ID', icon = 'user-tag', checked = showHologramIds},
        },

        onCheck = function(selected, checked, args)
            if selected == 3 then
                showHologramIds = checked

                if showHologramIds then
                    ShowHologramIds()
                end
            end
        end,

    }, function(selected, scrollIndex, args)
        if selected == 1 then
            OpenCreatorInput()
        elseif selected == 2 then
            OpenSelectHologramToEditInput()
        elseif selected == 4 then
            lib.setMenuOptions('abpHologram_EditorMenu_editing', {label = 'Editing: '.. cache_currentHologramId}, 1)
            lib.showMenu('abpHologram_EditorMenu_editing')
        end
    end)

    lib.callback.register('abp_holograms:openHoloEditor', function()

        editor_positionThread = false

        if cache_currentHologramId then
            lib.setMenuOptions('abpHologram_EditorMenu', {label = 'Edit last: '.. cache_currentHologramId, icon = 'tag'}, 4)
        else
            lib.setMenuOptions('abpHologram_EditorMenu', {}, 4)
        end

        lib.showMenu('abpHologram_EditorMenu')
        return true
    end)

    function StartPositionThread()
        local holoID = cache_currentHologramId
        
        local cacheHologram = DeepTableCopy(Config.__HologramsObjects[holoID].data)
        local hologram = Config.__HologramsObjects[holoID].data
        local savePosition = false

        editor_positionThread = true

        lib.notify({
            title = 'Position Editor Started',
            description = 'Use ARROWS, Q or E to positioning.\nUse R to finish or SPACE to cancel.',
            type = 'info',
            duration = 10*1000
        })

        CreateThread(function() 
            while editor_positionThread do

                DisableControlAction(0, 44)
                DisableControlAction(0, 140)

                if IsControlPressed(0, 21) then
                    if IsControlPressed(0, 175) then -- Arrow Right
                        hologram.position = hologram.position + vector3(0.008, 0, 0)
                    end
    
                    if IsControlPressed(0, 172) then -- Arrow Up
                        hologram.position = hologram.position + vector3(0, 0.008, 0)
                    end
    
                    if IsControlPressed(0, 38) then -- E
                        hologram.position = hologram.position + vector3(0, 0, 0.008)
                    end
    
                    ------------------------------------------------
    
                    if IsControlPressed(0, 174) then -- Arrow Left
                        hologram.position = hologram.position - vector3(0.008, 0, 0)
                    end
    
                    if IsControlPressed(0, 173) then -- Arrow Down
                        hologram.position = hologram.position - vector3(0, 0.008, 0)
                    end
    
                    if IsDisabledControlPressed(0, 44) then -- Q
                        hologram.position = hologram.position - vector3(0, 0, 0.008)
                    end
                else
                    if IsControlPressed(0, 175) then -- Arrow Right
                        hologram.position = hologram.position + vector3(0.03, 0, 0)
                    end
    
                    if IsControlPressed(0, 172) then -- Arrow Up
                        hologram.position = hologram.position + vector3(0, 0.03, 0)
                    end
    
                    if IsControlPressed(0, 38) then -- E
                        hologram.position = hologram.position + vector3(0, 0, 0.03)
                    end
    
                    ------------------------------------------------
    
                    if IsControlPressed(0, 174) then -- Arrow Left
                        hologram.position = hologram.position - vector3(0.03, 0, 0)
                    end
    
                    if IsControlPressed(0, 173) then -- Arrow Down
                        hologram.position = hologram.position - vector3(0, 0.03, 0)
                    end
    
                    if IsDisabledControlPressed(0, 44) then -- Q
                        hologram.position = hologram.position - vector3(0, 0, 0.03)
                    end
                end

                

                if IsDisabledControlJustPressed(0, 140) then -- R
                    savePosition = true
                    editor_positionThread = false
                end

                if IsControlJustPressed(0, 76) then -- Spacebar
                    editor_positionThread = false
                end
                
                Wait(0)
            end

            EnableControlAction(0, 44)
            EnableControlAction(0, 140)

            if savePosition then
                if cache_createdHolograms then
                    cache_createdHolograms.data.position = hologram.position
                    lib.callback.await('abp_holograms:updateHologram', 0, cache_currentHologramId, cache_createdHolograms.data)

                    lib.notify({
                        title = 'Position Updated',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Position Canceled',
                        type = 'error'
                    })
                end
            else
                Config.__HologramsObjects[holoID].data = cacheHologram
                lib.notify({
                    title = 'Position Reverted',
                    type = 'success'
                })
            end

            lib.showMenu('abpHologram_EditorMenu_editing')
        end)
    end

    function StartRotationThread()
        local holoID = cache_currentHologramId
        
        local cacheHologram = DeepTableCopy(Config.__HologramsObjects[holoID].data)
        local hologram = Config.__HologramsObjects[holoID].data
        local savePosition = false

        editor_positionThread = true

        lib.notify({
            title = 'Rotator Editor Started',
            description = 'Use ARROWS, Q or E to rotate.\nUse R to finish or SPACE to cancel.',
            type = 'info',
            duration = 10*1000
        })

        hologram.typeProperties.rotation = vec3(hologram.typeProperties.rotation.x, hologram.typeProperties.rotation.y, hologram.typeProperties.rotation.z)

        CreateThread(function() 
            while editor_positionThread do

                DisableControlAction(0, 44)
                DisableControlAction(0, 140)

                if IsControlPressed(0, 21) then
                    if IsControlPressed(0, 175) then -- Arrow Right
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0.02, 0, 0)
                    end
    
                    if IsControlPressed(0, 172) then -- Arrow Up
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0, 0.02, 0)
                    end
    
                    if IsControlPressed(0, 174) then -- Arrow Left
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0.02, 0, 0)
                    end
    
                    if IsControlPressed(0, 173) then -- Arrow Down
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0, 0.02, 0)
                    end
                    
    
                    ------------------------------------------------

                    if IsDisabledControlPressed(0, 44) then -- Q
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0, 0, 0.02)
                    end
    
                    if IsControlPressed(0, 38) then -- E
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0, 0, 0.02)
                    end
                else

                    if IsControlPressed(0, 175) then -- Arrow Right
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0.1, 0, 0)
                    end
    
                    if IsControlPressed(0, 172) then -- Arrow Up
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0, 0.1, 0)
                    end
    
                    if IsControlPressed(0, 174) then -- Arrow Left
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0.1, 0, 0)
                    end
    
                    if IsControlPressed(0, 173) then -- Arrow Down
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0, 0.1, 0)
                    end
    
                    ------------------------------------------------

                    if IsControlPressed(0, 38) then -- E
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation - vector3(0, 0, 0.1)
                    end

                    if IsDisabledControlPressed(0, 44) then -- Q
                        hologram.typeProperties.rotation = hologram.typeProperties.rotation + vector3(0, 0, 0.1)
                    end
                end

                if IsDisabledControlJustPressed(0, 140) then -- R
                    savePosition = true
                    editor_positionThread = false
                end

                if IsControlJustPressed(0, 76) then -- Spacebar
                    editor_positionThread = false
                end
                
                Wait(0)
            end

            EnableControlAction(0, 44)
            EnableControlAction(0, 140)

            if savePosition then
                print(hologram.typeProperties.rotation.x, hologram.typeProperties.rotation.y, hologram.typeProperties.rotation.z)
                if cache_createdHolograms then
                    cache_createdHolograms.data.typeProperties.rotation = hologram.typeProperties.rotation
                    lib.callback.await('abp_holograms:updateHologram', 0, cache_currentHologramId, cache_createdHolograms.data)

                    lib.notify({
                        title = 'Rotation Updated',
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = 'Rotation Canceled',
                        type = 'error'
                    })
                end
            else
                Config.__HologramsObjects[holoID].data = cacheHologram
                lib.notify({
                    title = 'Rotation Reverted',
                    type = 'success'
                })
            end

            lib.showMenu('abpHologram_EditorMenu_editing')
        end)
    end
end)