---@diagnostic disable: need-check-nil

-- Holograms
local savedHolograms = lib.callback.await('abp_holograms:getHolograms', false)
local holoCallbacks = {}
local holoScaleformsAvailable = {}

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
				local randId 				= math.random(1000, 9999)
				local internalId 			= "HologramDUI_"..holoId.."_"..randId
				local internalTextureId 	= "DUI_"..holoId.."-"..randId

				holo = CheckHoloDataDefaults(holo, holoId)

				Config.__HologramsObjects[holoId] = {}
				Config.__HologramsObjects[holoId].id = holoId
				Config.__HologramsObjects[holoId].data = holo
				Config.__HologramsObjects[holoId].data.loaded = false
				Config.__HologramsObjects[holoId].duiIsReady = false
				
				Config.__HologramsObjects[holoId].enabled = holo.enabled or true
				Config.__HologramsObjects[holoId].visible = holo.visible or false
	
				Config.__HologramsObjects[holoId].duiObject = CreateDui(HologramURI, math.floor(holo.scale.x), math.floor(holo.scale.y))

				DebugPrint("\tDUI (".. Config.__HologramsObjects[holoId].duiObject ..") created for " .. holoId .. " Scale (".. math.floor(holo.scale.x) .. " , " .. math.floor(holo.scale.y) ..")")

				repeat Wait(50) until Config.__HologramsObjects[holoId] and Config.__HologramsObjects[holoId].duiIsReady or holo.urlTarget ~= nil

				if not Config.__HologramsObjects[holoId] then return end

				DebugPrint("\tDUI initialised for " .. holoId)

				Config.__HologramsObjects[holoId].internalId 		= internalId
				Config.__HologramsObjects[holoId].internalTextureId = internalTextureId
				Config.__HologramsObjects[holoId].txdHandle 		= CreateRuntimeTxd(internalId)
				Config.__HologramsObjects[holoId].duiHandle  		= GetDuiHandle(Config.__HologramsObjects[holoId].duiObject)
				Config.__HologramsObjects[holoId].duiTexture 		= CreateRuntimeTextureFromDuiHandle(Config.__HologramsObjects[holoId].txdHandle, internalTextureId, Config.__HologramsObjects[holoId].duiHandle)

				DebugPrint("\tRuntime texture created for " .. holoId .. " (duiObject: ".. Config.__HologramsObjects[holoId].duiObject ..")")

				if holo.type ~= 'hologram-marker' then
					if holo.type == 'hologram-scaleform' then
						local handleIndex = GetAvailableScaleformIndex()
						if handleIndex then
							holoScaleformsAvailable[handleIndex] = true

							Config.__HologramsObjects[holoId].sfHandle = lib.requestScaleformMovie("GT_"..handleIndex, 1200)
							if Config.__HologramsObjects[holoId].sfHandle then
								PushScaleformMovieFunction(Config.__HologramsObjects[holoId].sfHandle, 'SET_TEXTURE')
								PushScaleformMovieMethodParameterString(internalId)
								PushScaleformMovieMethodParameterString(internalTextureId)

								PushScaleformMovieFunctionParameterInt(0)
								PushScaleformMovieFunctionParameterInt(0)
								PushScaleformMovieFunctionParameterInt(math.floor(holo.scale.x))
								PushScaleformMovieFunctionParameterInt(math.floor(holo.scale.y))

								PopScaleformMovieFunctionVoid()

								Config.__HologramsObjects[holoId].sfReady = true
								Config.__HologramsObjects[holoId].sfId = handleIndex
								DebugPrint("[Hologram] Setup Scaleform texture for ".. holoId .. ' with index ' , handleIndex)
							end
						else
							DebugPrint("[Hologram] No available scaleform texture for ".. holoId)
						end
					else
						Config.__HologramsObjects[holoId].hologramObject = CreateHologram()
						AddReplaceTexture("hologram_box_model", "p_hologram_box" , internalId, internalTextureId)
	
						if holo.typeProperties.cameraFollow then
							CreateThread(function() 
								local pos = holo.position
								if not pos then 
									pos = GetEntityCoords(Config.__HologramsObjects[holoId].hologramObject)
								end
	
								if not pos then return end
	
								while Config.__HologramsObjects[holoId] and DoesEntityExist(Config.__HologramsObjects[holoId].hologramObject) do
									DrawLightWithRange(pos.x, pos.y, pos.z, 255, 255, 255, 1.0, 100.0)
									SetEntityHeading(Config.__HologramsObjects[holoId].hologramObject,  GetGameplayCamRot(0).z)
	
									Wait(0)
								end
							end)
						end
					end

					if holo.attachTo == 'player' then
						AttachHologramToPlayer(holoId)
					elseif holo.attachTo == 'vehicle' then
						-- Create the hologram object
						-- AttachEntityToEntity(Config.__HologramsObjects[holoId].hologramObject, GetVehiclePedIsIn(PlayerPedId(), false), GetEntityBoneIndexByName(GetVehiclePedIsIn(PlayerPedId(), false), "chassis"), holo.position, AttachmentRotation, false, false, false, false, false, true)
					elseif holo.attachTo == 'world' then
						AttachHologramToWorld2(Config.__HologramsObjects[holoId].hologramObject, holo.position, holoId)
					end

				end


				DebugPrint("Done! (".. Config.__HologramsObjects[holoId].duiObject ..") for " .. holoId)
			end
		end)
	end

	DebugPrint("DUI Creation has been finished!")

	SetModelAsNoLongerNeeded(HologramModel)
end

function GetAvailableScaleformIndex()
	Wait(100 + (TableCount(holoScaleformsAvailable) + 10))

	local sfCount = TableCount(holoScaleformsAvailable)
	local sfNextIndex = sfCount + 1

	return sfCount <= Config.MaxGFX and sfNextIndex or false
end

function CheckHoloDataDefaults(holoData, holoId)

	--- Check Holo Data default
	if not holoData.typeProperties then
		holoData.typeProperties = {
			rotation = vector3(0.0, 0.0, 0.0),
			scale = vector3(1.0, 1.0, 1.0),
			rotate = false,
			cameraFollow = true,
			bobUpAndDown = false
		}
	else
		if not holoData.typeProperties.rotation then
			if holoData.attachTo ~= 'player' then
				holoData.typeProperties.rotation = vector3(90.0, 0.0, 0.0)
			end
		end

		if not holoData.typeProperties.scale then
			holoData.typeProperties.scale = vector3(1.0, 1.0, 1.0)
		end

		if not holoData.typeProperties.rotate then
			holoData.typeProperties.rotate = false
		end

		if not holoData.typeProperties.cameraFollow then
			holoData.typeProperties.cameraFollow = true
		end

		if not holoData.typeProperties.bobUpAndDown then
			holoData.typeProperties.bobUpAndDown = false
		end
	end
	
	if type(holoData.enabled) == 'nil' then
		holoData.enabled = true
	end

	if not holoData.urlTarget and not holoData.htmlTarget then
		holoData.urlTarget = "https://http.cat/404"
		print("[Hologram] Warning: Hologram ".. holoId .." urlTarget/htmlTarget not set, defaulting to [https://http.cat/404]")
	end
	
	if not holoData.attachTo then
		holoData.attachTo = 'world'
	end

	if not holoData.type then
		if holoData.attachTo ~= 'player' then
			holoData.type = 'hologram-marker'
		end
	end

	if not holoData.position then
		if holoData.attachTo ~= 'player' then
			holoData.position = vector3(0.0, 0.0, 0.0)
			print("[Hologram] Warning: Hologram ".. holoId .." position not set, defaulting to [0.0, 0.0, 0.0]")
		end
	end
	
	if not holoData.distanceView then
		holoData.distanceView = 30
	end

	if not holoData.scale then
		holoData.scale = vector2(1920, 1024)
		print("[Hologram] Warning: Hologram ".. holoId .." scale not set, defaulting to [1920, 1024]")
	end

	if not holoData.sfScale then
		holoData.sfScale = 0.1
	end

	if not holoData.visible then
		holoData.visible = false
	end

	return holoData
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
						local distanceView = tonumber(holoData.data.distanceView) or 30

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
					if holoData.data.attachTo == 'world' and holoData.data.type == 'hologram-marker'  then
						AttachHologramToWorld(holoData.data, holoData.internalId, holoData.internalTextureId)
					elseif holoData.data.attachTo == 'world' and holoData.data.type == 'hologram-scaleform' then
						local sfHandle = holoData.sfHandle
						if sfHandle and holoData.sfReady then
							local position = holoData.data.position
							local camRotation = holoData.data.typeProperties.cameraFollow and GetGameplayCamRot(2) or vec3(0,0,0)
							DrawScaleformMovie_3dNonAdditive(sfHandle,
								position.x, position.y, position.z + 2,
								0, -camRotation.z, camRotation.y,
								2, 2, 2,
								(holoData.data.sfScale * 1), (holoData.data.sfScale * (9/16)),
								1, 2
							)
						end
						
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
	SetEntityAlpha(hologramObject, 255, true)
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

function AttachHologramToWorld2(hologramObject, coords, holoId)
	if Config.__HologramsObjects[holoId].type ~= "hologram-scaleform" then
		SetEntityCoords(hologramObject, coords.x, coords.y, coords.z)
		FreezeEntityPosition(hologramObject, true)
		SetEntityHeading(hologramObject, 220.0)
		DebugPrint(string.format("DUI anchor %s attached to world", hologramObject))
	end
end

function AttachHologramToWorld(holoData, txd, txn)
	local coords = holoData.position
	local properties = holoData.typeProperties

	local scale = properties.scale
	local rotation = properties.rotation

	if txd and txn then
		DrawMarker(properties.type or 8, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, rotation.x, rotation.y, rotation.z, scale.x, scale.y, scale.z, 255, 255, 255, 200, properties.bobUpAndDown, properties.cameraFollow, 2, properties.rotate, txd, txn, false)
	end
end


-- Register a callback for when the DUI JS has loaded completely
RegisterNUICallback("duiIsReady", function(data, cb)
	local holoTarget  = data.duiName
	local foundHolos  = FindHologramByHtmlTarget(holoTarget)

	if foundHolos then
		for _, holoId in pairs(foundHolos) do
			DebugPrint("DUI for ".. holoTarget .." anchor is ready")
			Config.__HologramsObjects[holoId].duiIsReady = true
		end
	else
		DebugPrint("DUI for ".. holoTarget .." anchor not found")
	end

    cb({ok = true})
end)

RegisterNUICallback('sendData', function(data, cb) 
	local holoId = data.id
	local eventName = data.eventName
	local data = data.content

	if not Config.__HologramsObjects[holoId] then return end

	if holoCallbacks[holoId] and holoCallbacks[holoId][eventName] then
		return holoCallbacks[holoId][eventName](data)
	end

	return cb({ok = true})
end)

exports('RegisterHologramCallback', function(holoId, eventName, callback)
	if not holoCallbacks[holoId] then
		holoCallbacks[holoId] = {}
	end

	holoCallbacks[holoId][eventName] = callback
	print("Hologram callback registered for ".. holoId .." with event name ".. eventName)
end)

exports('ToggleHologramState', function(holoId, state)
	if Config.__HologramsObjects[holoId] then
		Config.__HologramsObjects[holoId].enabled = state
	end
end)

exports('CreateHologram', function(holoId, holoData) 

	if Config.__HologramsObjects[holoId] then
		print("Holograms object updating for ".. holoId)
		DestroyHologram(holoId, true)
	end
	
	Config.Holograms[holoId] = holoData
	InitializeDUI()

	return holoId
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

function DestroyHologram(__holoId__, forced)
	for holoId, holo in pairs(Config.__HologramsObjects) do
		if holoId == __holoId__ then
			holo.enabled = false

			if holo.sfHandle then
				SetScaleformMovieAsNoLongerNeeded(holo.sfId)
				DebugPrint("\tSetting scaleform movie as no longer needed for ".. holoId)
			end

			if DoesEntityExist(holo.hologramObject) then
				DeleteVehicle(holo.hologramObject)
				DebugPrint("\tDUI for ".. holoId .." anchor deleted "..tostring(holo.hologramObject))
			end
	
			--RemoveReplaceTexture("hologram_box_model", "p_hologram_box")
			DebugPrint("\tReplace texture removed")
	
			if holo.duiObject then
				DebugPrint("\tDUI browser destroyed")
				DestroyDui(holo.duiObject)
				holo.duiObject = false
			end

			break
		end
	end

	if forced then 
		Config.__HologramsObjects[__holoId__] = nil
		Config.Holograms[__holoId__] = nil
	end
end
exports('DestroyHologram', DestroyHologram)

function DestroyAllHolograms()
	DebugPrint("Cleaning up...")

	for holoId, holo in pairs(Config.__HologramsObjects) do

		if holo.sfHandle then
			SetScaleformMovieAsNoLongerNeeded(holo.sfId)
			DebugPrint("\tSetting scaleform movie as no longer needed for ".. holoId)
		end

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

EnsureDuiMessage = function(hologram, hologramId, eventName, data)

	if not Config.__HologramsObjects[hologramId] then return false end
	if not hologram then return false end
	if not hologram.enabled then return false end
	if not hologram.duiObject or hologram.duiObject == 0 then return false end
	if not IsDuiAvailable(hologram.duiObject) then return false end

	repeat Wait(50) until hologram.duiIsReady

	SendDuiMessage(hologram.duiObject, json.encode({
		content		= data,
		duiName 	= hologram.data.htmlTarget,
		id 			= hologramId,
		eventName 	= eventName
	}))
	return true
end

exports('SendHologramData', function(hologramId, eventName, data)
	if not Config.__HologramsObjects[hologramId] then return false end

	return EnsureDuiMessage(Config.__HologramsObjects[hologramId], hologramId, eventName, data)
end)

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		DestroyAllHolograms()
	end
end)

RegisterCommand('flushsf', function() 
	for holoId, holo in pairs(Config.__HologramsObjects) do
		if holo.sfHandle then
			SetScaleformMovieAsNoLongerNeeded(holo.sfHandle)
			DebugPrint("\tSetting scaleform movie as no longer needed for ".. holoId)
		end
	end

end)
----
-- DrawMarker 43 es un cubo donde se muestran todas sus caras.
