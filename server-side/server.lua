-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
emP = {}
Tunnel.bindInterface("caua_racemoto",emP)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local racepoint = 1
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENTS
-----------------------------------------------------------------------------------------------------------------------------------------
local payments = {
	[1] = { 1200,2500,1000,0 },
	[2] = { 1000,3500,1000,0 },
	[3] = { 1500,4500,1000,0 },
	[4] = { 4000,5600,1000,0 },
	[5] = { 5000,6500,1000,0 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANDOMPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		racepoint = math.random(#payments)
		Citizen.Wait(5*60000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETRACEPOINT
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.getRacepoint()
	return parseInt(racepoint)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTBOMBRACE
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.startRace()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		vRP.tryGetInventoryItem(user_id,"ticket",1)
		vRP.tryGetInventoryItem(user_id,"gps",1)
		TriggerEvent("eblips:add",{ name = "Moto", src = source, color = 2 })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKTICKET
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.checkTicket()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		if vRP.getInventoryItemAmount(user_id,"ticket") >= 1 and vRP.getInventoryItemAmount(user_id,"gps") >= 1 then
			return true
        else
            TriggerClientEvent("Notify",source,"aviso","Aviso","Você precisa de um "..vRP.itemNameList("gps").." Modificado e de um "..vRP.itemNameList("ticket").." para iniciar a corrida.")
            return false
        end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEBOMBRACE
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.removeRace(check,status)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		TriggerClientEvent("eblips:remove",source) --- EVENTO PRA REMOVER BLIPS

		if status then
			vRP.searchTimer(user_id,300) -- SETA TIMER

			local valor = math.random(payments[check][1],payments[check][2])
			vRP.giveInventoryItem(user_id,"dinheirosujo",parseInt(valor))

			if vRP.tryGetInventoryItem(user_id,"rebite",1) then
				vRP.giveInventoryItem(user_id,"dinheirosujo",math.random(1000,1500))
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEFUSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("defuse",function(source,args,rawCommand)
	local user_id = vRP.getUserId(source)
	if user_id then
		if vRP.hasPermission(user_id,"policia.permissao") then
			local nplayer = vRPclient.getNearestPlayer(source,3)
			if nplayer then
				TriggerClientEvent("emp_race:unbomb",nplayer)
                TriggerClientEvent("Notify",source,"sucesso","Sucesso","Você desarmou a <b>Bomba</b> com sucesso.")
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RACENUM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("racenum",function(source,args,rawCommand)
	racepoint = parseInt(args[1])
	TriggerClientEvent("Notify",source,"importante","Importante","Você escolheu a <b>Rota #"..args[1].."</b> com sucesso.") -- ESCOLHER QUAL CORRIDA VOCÊ DESEJA CORRER
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REGISTER RECORD
-----------------------------------------------------------------------------------------------------------------------------------------
function emP.registerRecord(check,time)
	local source = source
	local user_id = vRP.getUserId(source)
	local name = ""
	if payments[check][4] ~= 0 then
		local identity = vRP.getUserIdentity(payments[check][4])
		name = ""..identity.name.." "..identity.firstname..""
	end

	if user_id then
		if time < payments[check][3] then
			TriggerClientEvent("Notify",source,"sucesso","Corrida","Você bateu o record do dia nesta corrida! Parabéns!<br>Tempo: "..time.."s")
			if payments[check][4] ~= 0 then
				if payments[check][4] == user_id then
					TriggerClientEvent("Notify",source,"importante","Corrida","Você bateu seu próprio record!<br>Tempo: "..time.."s")
				else
					TriggerClientEvent("Notify",source,"aviso","Corrida","O record anterior era de <b>"..name.."</b>.<br>Record anterior: "..payments[check][3].."s")
				end
			end
			payments[check][3] = time
			payments[check][4] = user_id
		else
			TriggerClientEvent("Notify",source,"importante","Corrida","Você completou a corrida.<br>Seu tempo: "..time.."s", 2000)
			if payments[check][4] == user_id then
				TriggerClientEvent("Notify",source,"importante","Corrida","O record desta corrida é seu!<br>Tempo recorde: "..payments[check][3].."s")
			else
				TriggerClientEvent("Notify",source,"aviso","Corrida","O record desta corrida pertence a <b>"..name.."</b>.<br>Tempo recorde: "..payments[check][3].."s", 4000)
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RECORDES MOTO
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('recordesm',function(source,rawCommand)
	local user_id = vRP.getUserId(source)
	local text = "<b>Recordes atuais:</b>"
	if not vRP.hasPermission(user_id,"policia.permissao") then
		for k,v in pairs(payments) do
			if v[4] ~= 0 then
				local identity = vRP.getUserIdentity(v[4])
				text = text.."<br><br><b>Corrida "..k.."</b><br>Corredor: <b><i>"..identity.name.." "..identity.firstname.."<i></b><br>Tempo: <b>"..v[3].."s</b>"
			else
				text = text.."<br><br><b>Corrida "..k.."</b><br>Nenhuma corrida hoje."
			end
		end
		TriggerClientEvent("Notify",source,"importante","Importante",text,2000)
	end
end)