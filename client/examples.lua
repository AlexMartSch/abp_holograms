CreateThread(function() 

    Wait(1000)

    local selector3dId = "testSelector"
    local selector3DPoint = nil
    local inSelectorZone = false


    local function onEnter()
        exports.abp_holograms:CreateHologram(selector3dId, {
            enabled = true,
            htmlTarget = "selectorexample",
            attachTo = 'world',
            type = 'hologram-marker',
            typeProperties = {
                ---- MARKER PROPERTIES
                rotation = vector3(0.0, 10.0, 10.0), -- vertial, horizontal
                scale = vec3(3.0, 3.0, 3.0),
                rotate = false,
                cameraFollow = true,
                bobUpAndDown = false,
            },
            position = vector3(1209.4915, 2662.0354, 37.809986),
            distanceView = 50,
            scale = vector2(2500, 1000)
        })
        inSelectorZone = true

        CreateThread(function() 
            while inSelectorZone do
                Wait(0)
                if IsControlJustPressed(0, 172) then -- UP
                    exports.abp_holograms:SendHologramData(selector3dId, "makeAction", "up")
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                elseif IsControlJustPressed(0, 173) then -- DOWN
                    exports.abp_holograms:SendHologramData(selector3dId, "makeAction", "down")
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                elseif IsControlJustPressed(0, 174) then -- LEFT
                    exports.abp_holograms:SendHologramData(selector3dId, "makeAction", "left")
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                elseif IsControlJustPressed(0, 175) then -- RIGHT
                    exports.abp_holograms:SendHologramData(selector3dId, "makeAction", "right")
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                elseif IsControlJustPressed(0, 38) then -- E
                    exports.abp_holograms:SendHologramData(selector3dId, "makeAction", "select")
                    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                end
            end
        end)
    end

    local function onExit()
        exports.abp_holograms:DestroyHologram(selector3dId, true)
        inSelectorZone = false
    end


    selector3DPoint = lib.points.new({
        coords = vector3(1209.4915, 2662.0354, 37.809986),
        distance = 60,
        invId = dropId,
        onEnter = onEnter,
        onExit = onExit,
        nextUpdate = 0,
    })

    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            if selector3D and selector3DPoint then
                exports.abp_holograms:DestroyHologram(selector3dId, true)
                selector3DPoint:remove()
            end
        end
    end)

    
    exports.abp_holograms:RegisterHologramCallback(selector3dId, 'onItemSelected', function(data)
        print(">>", data.title)
    end)
end)
