function line(startPoint, endPoint)
	DrawLine(
	  startPoint.x, startPoint.y, startPoint.z,
	  endPoint.x, endPoint.y, endPoint.z,
	  255, 0, 0, 255
	);
end

function DrawText3D(coords, text, drawBorder, size, font)
	coords = vector3(coords.x, coords.y, coords.z)

	local camCoords = GetGameplayCamCoords()
	local distance = #(coords - camCoords)

	if not size then size = 1.0 end
	if not font then font = 0 end
	if not drawBorder then drawBorder = false end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	SetTextScale(0.0 * scale, 0.55 * scale)
	SetTextFont(font)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	SetDrawOrigin(coords, 0)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()

	if drawBorder then
		local factor = (string.len(text)) / 370
		DrawRect(coords.x, (coords.y + 0.0125), (0.015 + factor), 0.03, 41, 11, 41, 68)
	end
end

function DrawRect(position, txd, txn)
    local p1 = vector3( -0.5, 0, 0.5 )
    local p2 = vector3( 0.5, 0, 0.5 )
    local p3 = vector3( 0.5, 0, -0.5 )
    local p4 = vector3( -0.5, 0, -0.5 )
    
    p1 = p1 + position;
    p2 = p2 + position;
    p3 = p3 + position;
    p4 = p4 + position;
    
    DrawSpritePoly(
      p3.x, p3.y, p3.z,
      p2.x, p2.y, p2.z, 
      p1.x, p1.y, p1.z, 
      255, 255, 255, 255,
      txd, txn,
      1, 1, 1, 
      1, 0, 1,
      0, 0, 1
    );
    
    DrawSpritePoly(
      p1.x, p1.y, p1.z,
      p4.x, p4.y, p4.z, 
      p3.x, p3.y, p3.z, 
      255, 255, 255, 255,
      txd, txn,
      0, 0, 1, 
      0, 1, 1,
      1, 1, 1
    );
    
    if Config.DebugMode then
        line( p1, p2 );
        line( p2, p3 );
        line( p3, p4 );
        line( p4, p1 );
    end
end

function DebugPrint(...)
	if Config.DebugMode then
		print(...)
	end
end

function FindHologramByHtmlTarget(htmlTarget)
    for k, v in pairs(Config.Holograms) do
        if v.htmlTarget == htmlTarget then
            return k
        end
    end

    return false
end

DeepTableCopy = function(t)
	local u = {}
	for k, v in pairs(t) do u[k] = v end
	return setmetatable(u, getmetatable(t))
end

---- FIX THIS
-- function EnsureDuiMessage(duiObject, data)
-- 	if duiIsReady then
-- 		SendDuiMessage(duiObject, json.encode(data))
-- 		return true
-- 	end

-- 	return false
-- end
