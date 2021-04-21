-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPserver = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
emP = Tunnel.getInterface("caua_racemoto")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local blips = false
local inrace = false
local timerace = 0
local cooldown = 0
local racepoint = 1
local racepos = 0
local startPoint = vector3(-474.94,-742.85,30.57) -- COORDS PARA INICIAR CORRIDA
local PlateIndex = nil
local bomba = nil
local explosive = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTRACES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("corridam", function(source,args,rawCommand)
	if not inrace then
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsUsing(ped)
		local x,y,z = table.unpack(GetEntityCoords(ped))
		local bowz,cdz = GetGroundZFor_3dCoord(startPoint.x,startPoint.y,startPoint.z)
		local distance = GetDistanceBetweenCoords(startPoint.x,startPoint.y,cdz,x,y,z,true)

		if distance <= 10.1 then
			if IsEntityAVehicle(vehicle) and GetVehicleClass(vehicle) == 8 and GetPedInVehicleSeat(vehicle,-1) == ped then
				if emP.checkTicket() then

					if cooldown <= 0 then

						inrace = true
						racepos = 1
						cooldown = 180
						racepoint = emP.getRacepoint() -- TODO
						timerace = Config.races[racepoint].time
						PlateIndex = GetVehicleNumberPlateText(vehicle)
						SetVehicleNumberPlateText(vehicle,"CORREDOR")
						CriandoBlip(racepoint,racepos)
						explosive = math.random(100)

						if explosive >= 1 then
							emP.startRace()
							bomba = CreateObject(GetHashKey("prop_c4_final_green"),x,y,z,true,true,true)
							AttachEntityToEntity(bomba,vehicle,GetEntityBoneIndexByName(vehicle,"exhaust"),0.0,0.0,0.0,180.0,-90.0,180.0,false,false,false,true,2,true)
							PlaySoundFrontend(-1,"Oneshot_Final","MP_MISSION_COUNTDOWN_SOUNDSET",false)
							TriggerEvent("Notify","importante","Importante","<b>#"..racepoint.."</b> Você começou uma corrida <b>Explosiva</b>, não saia da moto e termine no tempo estimado, ou então sua moto vai explodir com você dentro.",8000)
						end

					else
						TriggerEvent("Notify","aviso","Aviso","Aguarde <b>"..parseInt(cooldown).." segundos</b> para iniciar uma nova corrida.",8000)
					end

				end
			else
				TriggerEvent("Notify","aviso","Aviso","Você precisa estar dentro de uma moto para iniciar esta corrida.",8000)
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKPOINTS
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    local timeDistance = 500
	while true do
		if inrace then
			local ped = PlayerPedId()
			local vehicle = GetVehiclePedIsUsing(ped)
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local bowz,cdz = GetGroundZFor_3dCoord(Config.races[racepoint][racepos].x,Config.races[racepoint][racepos].y,Config.races[racepoint][racepos].z)
			local distance = GetDistanceBetweenCoords(Config.races[racepoint][racepos].x,Config.races[racepoint][racepos].y,cdz,x,y,z,true)

			if distance <= 100.0 then
                timeDistance = 4
				if IsEntityAVehicle(vehicle) and GetVehicleClass(vehicle) == 8 then
					DrawMarker(1,Config.races[racepoint][racepos].x,Config.races[racepoint][racepos].y,Config.races[racepoint][racepos].z-3,0,0,0,0,0,0,12.0,12.0,8.0, --[[COR BLIP]] 0, 145, 255 ,25,0,0,0,0)
					DrawMarker(22,Config.races[racepoint][racepos].x,Config.races[racepoint][racepos].y,Config.races[racepoint][racepos].z+1,0,0,0,0.0,0,0,3.0,3.0,2.0, --[[COR BLIP]] 0, 213, 255 ,100,1,0,0,1)
					if distance <= 15.1 then
                        timeDistance = 4
						RemoveBlip(blips)
						if racepos == #Config.races[racepoint] then
							inrace = false
							SetVehicleNumberPlateText(GetPlayersLastVehicle(),PlateIndex)
							PlateIndex = nil
							PlaySoundFrontend(-1,"RACE_PLACED","HUD_AWARDS",false)
							if explosive >= 1 then
								explosive = 0
								DeleteObject(bomba)
								emP.removeRace(racepoint,true)
								emP.paymentCheck(racepoint,2)
							else
								emP.paymentCheck(racepoint,1)
							end
							emP.registerRecord(racepoint)
						else
							racepos = racepos + 1
							CriandoBlip(racepoint,racepos)
						end
					end
				end
			end
		end
        Citizen.Wait(timeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TIMEDRAWN
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
    local timeDistance = 500
	while true do
		if inrace and timerace > 0 then
            timeDistance = 4
			drawTxt("TEMPO RESTANTE",4,0.085,0.73,0.45,255,255,255,180)
			drawTxt("~r~"..timerace.."~g~ SEGUNDOS",4,0.085,0.75,0.55,255,255,255,180)
		end
        Citizen.Wait(timeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- COOLDOWN
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		if cooldown > 0 then
			cooldown = cooldown - 1
		end
		Citizen.Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TIMERACE
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		if inrace and timerace > 0 then
			timerace = timerace - 1
			if timerace <= 0 or not IsPedInAnyVehicle(PlayerPedId()) then
				inrace = false
				RemoveBlip(blips)
				SetVehicleNumberPlateText(GetPlayersLastVehicle(),PlateIndex)
				PlateIndex = nil
				if explosive >= 1 then
					SetTimeout(5000,function()
						explosive = 0
						DeleteObject(bomba)
						emP.removeRace(racepoint,false)
						AddExplosion(GetEntityCoords(GetPlayersLastVehicle()),1,1.0,true,true,true)
					end)
				end
			end
		end
        Citizen.Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBOMB
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("emp_race:unbomb")
AddEventHandler("emp_race:unbomb",function()
	inrace = false
	SetVehicleNumberPlateText(GetPlayersLastVehicle(),PlateIndex)
	PlateIndex = nil
	RemoveBlip(blips)
	if explosive >= 1 then
		explosive = 0
		DeleteObject(bomba)
		emP.removeRace(racepoint,false)
		TriggerEvent("Notify","importante","Importante","A <b>Bomba</b> foi desarmada com sucesso.")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUNÇÕES
-----------------------------------------------------------------------------------------------------------------------------------------
function drawTxt(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function CriandoBlip(racepoint,racepos)
	blips = AddBlipForCoord(Config.races[racepoint][racepos].x, Config.races[racepoint][racepos].y, Config.races[racepoint][racepos].z)
	SetBlipSprite(blips,1)
	SetBlipColour(blips,3)
	SetBlipScale(blips,0.4)
	SetBlipAsShortRange(blips,false)
	SetBlipRoute(blips,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Corrida Clandestina")
	EndTextCommandSetBlipName(blips)
end

function math.sign(v)
	return (v >= 0 and 1) or -1
end

function math.round(v, bracket)
	bracket = bracket or 1
	return math.floor(v/bracket + math.sign(v) * 0.5) * bracket
end