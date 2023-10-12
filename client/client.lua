-- Holograms
local savedHolograms = lib.callback.await('abp_holograms:getHolograms', false)

function MergeSavedWithConfig()
	for k, v in pairs(savedHolograms) do
		if not Config.Holograms[k] then
			v.position = (type(v.position) == 'vector3' and v.position or vector3(v.position.x, v.position.y, v.position.z))

			Config.Holograms[k] = v
		end
	end

	savedHolograms = {}
end

RegisterNetEvent('abp_holograms:UpdateHologramsFromServer', function(holograms)
	savedHolograms = holograms
	MergeSavedWithConfig()
	InitializeDUI()
end)

RegisterNetEvent('abp_holograms:UpdateHologram', function(holoId, data)

	
	if Config.__HologramsObjects[holoId] then
		local update = true

		if Config.__HologramsObjects[holoId].data.urlTarget ~= data.urlTarget then
			SetDuiUrl(Config.__HologramsObjects[holoId].duiObject, data.urlTarget)
		end

		if (Config.__HologramsObjects[holoId].data.scale.x ~= data.scale.x) or (Config.__HologramsObjects[holoId].data.scale.y ~= data.scale.y) then
			update = false
			RebuildHologram(holoId, data)
		end

		if update then
			Config.__HologramsObjects[holoId].data = data
		end
	end
end)

RegisterNetEvent('abp_holograms:RemoveHologram', function(holoId)
	DestroyHologram(holoId)
end)

-- Constants
local ResourceName       = GetCurrentResourceName()
local AttachmentOffset   = vec3(2.5, -1, 0.85)
local AttachmentRotation = vec3(0, 0, -15)
local HologramModel      = `hologram_box_model`
local PlayerPed = PlayerPedId()



-- Initialise the DUI. We only need to do this once.
function InitializeDUI()
	DebugPrint("Initialising...")

	for holoId, holo in pairs(Config.Holograms) do
		CreateThread(function() 
			if not Config.__HologramsObjects[holoId] then
				local HologramURI        	= holo.urlTarget and holo.urlTarget or string.format("nui://%s/ui/pages/%s/%s.html", ResourceName, holo.htmlTarget, holo.htmlTarget)
				local internalId 			= "HologramDUI_"..holoId
				local internalTextureId 	= "DUI_"..holoId
	
				Config.__HologramsObjects[holoId] = {}
				Config.__HologramsObjects[holoId].data = holo
				Config.__HologramsObjects[holoId].duiIsReady = false
				Config.__HologramsObjects[holoId].enabled = holo.enabled
				Config.__HologramsObjects[holoId].visible = holo.visible or false
	
				Config.__HologramsObjects[holoId].duiObject = CreateDui(HologramURI, math.floor(holo.scale.x), math.floor(holo.scale.y))
	
				DebugPrint("\tDUI (".. Config.__HologramsObjects[holoId].duiObject ..") created for " .. holoId .. " Scale (".. math.floor(holo.scale.x) .. " , " .. math.floor(holo.scale.y) ..")")
	
				repeat Wait(0) until Config.__HologramsObjects[holoId].duiIsReady or holo.urlTarget ~= nil
	
				DebugPrint("\tDUI initialised for " .. holoId)
	
				Config.__HologramsObjects[holoId].internalId 		= internalId
				Config.__HologramsObjects[holoId].internalTextureId = internalTextureId
				Config.__HologramsObjects[holoId].txdHandle 		= CreateRuntimeTxd(internalId)
				Config.__HologramsObjects[holoId].duiHandle  		= GetDuiHandle(Config.__HologramsObjects[holoId].duiObject)
				Config.__HologramsObjects[holoId].duiTexture 		= CreateRuntimeTextureFromDuiHandle(Config.__HologramsObjects[holoId].txdHandle, internalTextureId, Config.__HologramsObjects[holoId].duiHandle)
	
				DebugPrint("\tRuntime texture created for " .. holoId .. " (duiObject: ".. Config.__HologramsObjects[holoId].duiObject ..")")
	
				if holo.attachTo ~= 'world' then
					Config.__HologramsObjects[holoId].hologramObject = CreateHologram()
					AddReplaceTexture("hologram_box_model", "p_hologram_box" , internalId, internalTextureId)
				end
				
				if holo.attachTo == 'player' then
					AttachHologramToPlayer(holoId)
				elseif holo.attachTo == 'vehicle' then
					-- Create the hologram object
					-- AttachEntityToEntity(Config.__HologramsObjects[holoId].hologramObject, GetVehiclePedIsIn(PlayerPedId(), false), GetEntityBoneIndexByName(GetVehiclePedIsIn(PlayerPedId(), false), "chassis"), holo.position, AttachmentRotation, false, false, false, false, false, true)
				end
	
				DebugPrint("Done! (".. Config.__HologramsObjects[holoId].duiObject ..") for " .. holoId)
			end
		end)
	end

	DebugPrint("DUI Creation has been finished!")

	SetModelAsNoLongerNeeded(HologramModel)
end

function HologramDistanceCheckThread()
	local cPlayerPed = PlayerPedId()
	CreateThread(function() 
		while true do
			Wait(1000)
	
			PlayerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(PlayerPed)
	
			for holoId, holoData in pairs(Config.__HologramsObjects) do
				if Config.__HologramsObjects[holoId].enabled then
					if Config.__HologramsObjects[holoId].data.attachTo ~= 'player' then
						local distance = math.floor(#(holoData.data.position - playerCoords))
						local distanceView = holoData.data.distanceView or 30

						if distance <= distanceView then
							Config.__HologramsObjects[holoId].visible = true
						else
							Config.__HologramsObjects[holoId].visible = false
						end
					else
						if Config.__HologramsObjects[holoId].visible then
							if cPlayerPed ~= PlayerPedId() then
								cPlayerPed = PlayerPedId()
								AttachHologramToPlayer(holoId)
							else
								if IsPedDeadOrDying(cPlayerPed) then
									Config.__HologramsObjects[holoId].visible = false
								end
							end
						else
							if not IsPedDeadOrDying(cPlayerPed) then
								Config.__HologramsObjects[holoId].visible = true
							end
						end
					end
				end
			end
		end
	end)
end

function DisplayHolograms()
	CreateThread(function() 
		while true do
			for holoId, holoData in pairs(Config.__HologramsObjects) do
				if holoData.enabled and holoData.visible then
					if holoData.data.attachTo == 'world' and holoData.data.type == 'hologram'  then
						AttachHologramToWorld(holoData.data, holoData.internalId, holoData.internalTextureId)
					end
				end
			end
			Wait(0)
		end
	end)
end

CreateThread(function()
	if not IsModelInCdimage(HologramModel) or not IsModelAVehicle(HologramModel) then
		print("^1Could not find `hologram_box_model` in the game... ^rHave you installed the resource correctly?")
		return
	end

	MergeSavedWithConfig()

	InitializeDUI()

	HologramDistanceCheckThread()

	DisplayHolograms()

end)

-- Create hologram entity

function CreateHologram()
	-- Create the hologram objec
	RequestModel(HologramModel)
	repeat Wait(0) until HasModelLoaded(HologramModel)

	local hologramObject = CreateVehicle(HologramModel, GetEntityCoords(PlayerPedId()), 0.0, false, true)
	SetVehicleIsConsideredByPlayer(hologramObject, false)
	SetVehicleEngineOn(hologramObject, true, true)
	SetEntityCollision(hologramObject, false, false)
	DebugPrint("DUI anchor created "..tostring(hologramObject))

	Entity(hologramObject).state:set("hologram", true)
	return hologramObject
end


-- Get the attachment offset by vehicle class (or return default if it doesn't match anything)

function GetAttachmentByVehicle(currentVehicle)
	local vc = GetVehicleClass(currentVehicle)
	--[[ Examples, uncomment it if you like
    if(vc == 8 or vc == 13) then
		return vec3(1.5, -0.5, 0.85)
	end
	if(vc == 10 or vc == 20) then
		return vec3(2.5, 1.5, 2.5)
	end
	if(vc == 16) then
		return vec3(2.5, 1.5, 1.5)
	end
	if(vc == 15) then
		return vec3(2.5, 1, 1.5)
	end
	if(vc == 14) then
		return vec3(2.5, 0, 2)
	end
    ]]--
	return AttachmentOffset
end


-- Attach hologram entity to the vehicle

function AttachHologramToVehicle(hologramObject, currentVehicle)
	-- Attach the hologram to the vehicle
	AttachEntityToEntity(hologramObject, currentVehicle, GetEntityBoneIndexByName(currentVehicle, "chassis"), GetAttachmentByVehicle(currentVehicle), AttachmentRotation, false, false, false, false, false, true)
	DebugPrint(string.format("DUI anchor %s attached to %s", hologramObject, currentVehicle))
end

function AttachHologramToPlayer(holoId)
	local holo = Config.__HologramsObjects[holoId]
	local holoData = holo.data

	AttachEntityToEntity(
		holo.hologramObject, PlayerPedId(),
		GetPedBoneIndex(PlayerPedId(), 1),
		holoData.typeProperties.attachmentOffset,
		holoData.typeProperties.attachmentRotatio,
		false, true, false, true, true, true)
	DebugPrint(string.format("DUI anchor %s attached to %s", holo.hologramObject, PlayerPedId()))
end

-- function AttachHologramToWorld2(hologramObject, coords)
-- 	SetEntityCoords(hologramObject, coords.x, coords.y, coords.z)
-- 	FreezeEntityPosition(hologramObject, true)
-- 	SetEntityHeading(hologramObject, 220.0)
-- 	DebugPrint(string.format("DUI anchor %s attached to world", hologramObject))
-- end

function AttachHologramToWorld(holoData, txd, txn)
	local coords = holoData.position
	local properties = holoData.typeProperties

	local scale = properties.scale
	local rotation = properties.rotation


	DrawMarker(properties.type or 8, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, rotation.x, rotation.y, rotation.z, scale.x, scale.y, scale.z, 255, 255, 255, 200, properties.bobUpAndDown, properties.cameraFollow, 2, properties.rotate, txd, txn, false)
end


-- Register a callback for when the DUI JS has loaded completely
RegisterNUICallback("duiIsReady", function(data, cb)
	local holoTarget = data.duiName
	local foundHolo  = FindHologramByHtmlTarget(holoTarget)

	if foundHolo then
		DebugPrint("DUI for ".. holoTarget .." anchor is ready")
		Config.__HologramsObjects[foundHolo].duiIsReady = true
	end

    cb({ok = true})
end)



exports('ToggleHologramState', function(holoId, state)
	if Config.__HologramsObjects[holoId] then
		Config.__HologramsObjects[holoId].enabled = state
	end
end)

exports('CreateHologram', function(holoId, holoData) 
	if not Config.Holograms[holoId] then
		Config.Holograms[holoId] = holoData

		InitializeDUI()
	end
end)

exports('UpdateHologram', function(holoId, holoData)
	if Config.__HologramsObjects[holoId] then

		local holo = Config.__HologramsObjects[holoId]
		local _holoData = holo.data

		if _holoData.enabled ~= holoData.enabled then
			Config.__HologramsObjects[holoId].data.enabled = holoData.enabled
		end

		if _holoData.htmlTarget and (_holoData.htmlTarget ~= holoData.htmlTarget) then
			Config.__HologramsObjects[holoId].data.htmlTarget = holoData.htmlTarget
		end

		if _holoData.urlTarget and (_holoData.urlTarget ~= holoData.urlTarget) then
			Config.__HologramsObjects[holoId].data.urlTarget = holoData.urlTarget
		end

		if _holoData.attachTo ~= holoData.attachTo then
			Config.__HologramsObjects[holoId].data.attachTo = holoData.attachTo
		end

		if _holoData.type ~= holoData.type then
			Config.__HologramsObjects[holoId].data.type = holoData.type
		end

		if _holoData.typeProperties.rotation ~= holoData.typeProperties.rotation then
			Config.__HologramsObjects[holoId].data.typeProperties.rotation = holoData.typeProperties.rotation
		end

		if _holoData.typeProperties.scale ~= holoData.typeProperties.scale then
			Config.__HologramsObjects[holoId].data.typeProperties.scale = holoData.typeProperties.scale
		end

		if _holoData.typeProperties.rotate ~= holoData.typeProperties.rotate then
			Config.__HologramsObjects[holoId].data.typeProperties.rotate = holoData.typeProperties.rotate
		end

		if _holoData.typeProperties.cameraFollow ~= holoData.typeProperties.cameraFollow then
			Config.__HologramsObjects[holoId].data.typeProperties.cameraFollow = holoData.typeProperties.cameraFollow
		end

		if _holoData.typeProperties.bobUpAndDown ~= holoData.typeProperties.bobUpAndDown then
			Config.__HologramsObjects[holoId].data.typeProperties.bobUpAndDown = holoData.typeProperties.bobUpAndDown
		end

		if _holoData.position ~= holoData.position then
			Config.__HologramsObjects[holoId].data.position = holoData.position
		end

		if _holoData.distanceView ~= holoData.distanceView then
			Config.__HologramsObjects[holoId].data.distanceView = holoData.distanceView
		end

		if _holoData.scale ~= holoData.scale then
			Config.__HologramsObjects[holoId].data.scale = holoData.scale
		end
	end
end)

-- Resource cleanup

function RebuildHologram(__holoId__, __holoData__)
	for holoId, holo in pairs(Config.__HologramsObjects) do
		if holoId == __holoId__ then
			if DoesEntityExist(holo.hologramObject) then
				DeleteVehicle(holo.hologramObject)
				DebugPrint("\tDUI for ".. holoId .." anchor deleted "..tostring(holo.hologramObject))
			end
	
			RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
			DebugPrint("\tReplace texture removed")
	
			if holo.duiObject then
				DebugPrint("\tDUI browser destroyed")
				DestroyDui(holo.duiObject)
				holo.duiObject = false
			end
		end
	end

	Config.__HologramsObjects[__holoId__] = nil
	Config.Holograms[__holoId__] = __holoData__

	InitializeDUI()

end

function DestroyHologram(__holoId__)
	for holoId, holo in pairs(Config.__HologramsObjects) do
		if holoId == __holoId__ then
			holo.enabled = false
			if DoesEntityExist(holo.hologramObject) then
				DeleteVehicle(holo.hologramObject)
				DebugPrint("\tDUI for ".. holoId .." anchor deleted "..tostring(holo.hologramObject))
			end
	
			RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
			DebugPrint("\tReplace texture removed")
	
			if holo.duiObject then
				DebugPrint("\tDUI browser destroyed")
				DestroyDui(holo.duiObject)
				holo.duiObject = false
			end
		end
	end
end

function DestroyAllHolograms()
	DebugPrint("Cleaning up...")

	for holoId, holo in pairs(Config.__HologramsObjects) do

		holo.enabled = false

		if DoesEntityExist(holo.hologramObject) then
			DeleteVehicle(holo.hologramObject)
			DebugPrint("\tDUI for ".. holoId .." anchor deleted "..tostring(holo.hologramObject))
		end

		RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
		DebugPrint("\tReplace texture removed")

		if holo.duiObject then
			DebugPrint("\tDUI browser destroyed")
			DestroyDui(holo.duiObject)
			holo.duiObject = false
		end
	end
end

RegisterCommand('destroyholos', function() 
	DestroyAllHolograms()
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == ResourceName then
		DestroyAllHolograms()
	end
end)

----
-- DrawMarker 43 es un cubo donde se muestran todas sus caras.
