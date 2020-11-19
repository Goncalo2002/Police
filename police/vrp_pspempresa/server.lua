--[[
#######################################################
###################Feito Por###########################
################Gonçalo-)#6824#########################
##########https://discord.gg/ABWPUTH###################
#######################################################
]]

local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
MySQL = module("vrp_mysql", "MySQL")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP","vrp_pspempresa")

vRPbf = {}
Tunnel.bindInterface("vrp_pspempresa",vRPbf)
Proxy.addInterface("vrp_pspempresa",vRPbf)

local cfg = module("vrp_pspempresa", "cfg/business")
local business = cfg.businessloc

MySQL.createCommand("vRP/pspempresa_tables","CREATE TABLE IF NOT EXISTS vrp_pspempresashop_table(id INTEGER AUTO_INCREMENT, bmoney INTEGER NOT NULL DEFAULT 0, data TEXT NOT NULL DEFAULT '', PRIMARY KEY (id)); INSERT IGNORE INTO vrp_pspempresashop_table(id,bmoney) VALUES(1,0);")
MySQL.createCommand("vRP/get_money_pspempresa","SELECT * FROM vrp_pspempresashop_table WHERE id = @id")
MySQL.createCommand("vRP/set_money_pspempresa","UPDATE vrp_pspempresashop_table SET bmoney=@bmoney WHERE id = @id")
MySQL.createCommand("vRP/update_money_pspempresa","UPDATE vrp_pspempresashop_table SET bmoney=bmoney+@bmoney WHERE id = @id")
MySQL.createCommand("vRP/update_pspempresashopdata","UPDATE vrp_pspempresashop_table SET data=@data WHERE id = @id")

MySQL.query("vRP/pspempresa_tables")

function parseInt(v)
	local n = tonumber(v)
	if n == nil then 
		return 0
	else
		return math.floor(n)
	end
end

function insertBusinessData(user_id, line)
	if user_id ~= nil then
		MySQL.query("vRP/get_money_pspempresa", {id = 1}, function(rows, affected)
			if #rows > 0 then
				for k,v in ipairs(rows) do
					local ndata = v.data
					if ndata ~= nil then
						local dataupdate = ndata..line.."<br />"
						MySQL.query("vRP/update_pspempresashopdata", {data = dataupdate, id = 1})
					else
						local dataupdate = line.."<br />"
						MySQL.query("vRP/update_pspempresashopdata", {data = dataupdate, id = 1})
					end
				end
			end
		end)
	end
end

local function ch_consultarsaldo(player,choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		MySQL.query("vRP/get_money_pspempresa", {id = 1}, function(rows, affected)
			if #rows > 0 then
				for k,v in ipairs(rows) do
					local saldo = v.bmoney
					vRP.buildMenu({"searchbusiness", {player = player}, function(menu)
						menu.name = "Saldo"
						menu["Saldo disponível"] = {nil,"Saldo disponível: $"..saldo.."."}
						vRP.openMenu({player,menu})
					end})
				end
			else
				vRPclient.notify(player,{"~y~SISTEMA: ~w~Não foi possível encontrar dados da Empresa."})
			end
		end)
	end
end

local player_lists = {}
local function ch_consultardata(player,choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		if player_lists[player] then
			player_lists[player] = nil
			vRPclient.removeDiv(player,{"business_pc"})
		else
			MySQL.query("vRP/get_money_pspempresa", {id = 1}, function(rows, affected)
				if #rows > 0 then
					for k,v in ipairs(rows) do
						local data = v.data
						player_lists[player] = true
						vRPclient.setDiv(player,{"business_pc",".div_business_pc{ background-color: rgba(0,0,0,0.75); color: white; font-weight: bold; width: 500px; padding: 10px; margin: auto; margin-top: 150px; }",data})
					end
				else
					vRPclient.notify(player,{"~y~SISTEMA: ~w~Não foi possível encontrar dados da Empresa."})
				end
			end)
		end
	end
end

local function ch_retirarsaldo(player,choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		MySQL.query("vRP/get_money_pspempresa", {id = 1}, function(rows, affected)
			if #rows > 0 then
				for k,v in ipairs(rows) do
					local saldo = v.bmoney
					vRP.prompt({player,"Saldo: "..saldo.." | Quantia para Retirar:","",function(player,response)
						if response ~= nil and response ~= "" then
							if parseInt(response) > 1 then
								response = parseInt(response)
								if response > saldo then
									vRPclient.notify(player,{"~y~SISTEMA: ~w~Não existe esse valor disponível para saque."})
								else
									local saldoupdate = saldo-response
									MySQL.query("vRP/set_money_pspempresa", {bmoney = saldoupdate, id = 1})
									MySQL.query("vRP/get_money_pspempresa", {id = 1}, function(rows, affected)
										if #rows > 0 then
											for k,v in ipairs(rows) do
												local newsaldo = v.bmoney
												if newsaldo ~= saldo then
													vRP.giveMoney({user_id,response})
													vRPclient.notify(player,{"~y~SISTEMA: ~w~Você retirou $"..response.."."})
													insertBusinessData(user_id, "[ID "..user_id.."] retirou $"..response.."")
												else
													vRPclient.notify(player,{"~y~SISTEMA: ~w~Algo de errado não está certo."})
												end
											end
										else
											vRPclient.notify(player,{"~y~SISTEMA: ~w~Não foi possível encontrar dados da Empresa."})
										end
									end)
								end
							elseif parseInt(response) < 1 then
								response = 0
								vRPclient.notify(player,{"~y~SISTEMA: ~w~Não aceitamos valores núlos ou negativos."})
							else
								response = 0
								vRPclient.notify(player,{"~y~SISTEMA: ~w~Não aceitamos valores núlos ou negativos."})
							end
						else
							vRPclient.notify(player,{"~y~SISTEMA: ~w~Dados inválidos ou vazios."})
						end
				    end})
				end
			end
		end)
	end
end

local function ch_depositarsaldo(player,choice)
	local user_id = vRP.getUserId({player})
	if user_id ~= nil then
		local wallet = vRP.getMoney({user_id})
		vRP.prompt({player,"Carteira: "..wallet.." | Quantia para Depositar:","",function(player,response)
			if response ~= nil and response ~= "" then
				if parseInt(response) > 1 then
					response = parseInt(response)
					if(vRP.tryPayment({user_id,response})) then
						MySQL.query("vRP/update_money_pspempresa", {bmoney = response, id = 1})
						local newwallet = vRP.getMoney({user_id})
						if newwallet ~= wallet then
							vRPclient.notify(player,{"~y~SISTEMA: ~w~Você depositou $"..response.."."})
							insertBusinessData(user_id, "[ID "..user_id.."] depositou $"..response.."")
						else
							vRPclient.notify(player,{"~y~SISTEMA: ~w~Algo de errado não está certo."})
						end
					else
						vRPclient.notify(player,{"~y~SISTEMA: ~w~Não existe esse valor disponível para deposito."})
					end
				elseif parseInt(response) < 1 then
					response = 0
					vRPclient.notify(player,{"~y~SISTEMA: ~w~Não aceitamos valores núlos ou negativos."})
				else
					response = 0
					vRPclient.notify(player,{"~y~SISTEMA: ~w~Não aceitamos valores núlos ou negativos."})
				end
			else
				vRPclient.notify(player,{"~y~SISTEMA: ~w~Dados inválidos ou vazios."})
			end
	    end})
	end
end

local function ch_businessMenu(player, choice)
	vRP.buildMenu({"pspempresa", {player = player}, function(menu)
		menu.name = cfg.business_title
		local user_id = vRP.getUserId({player})
		menu["Consultar Saldo"] = {ch_consultarsaldo,"Ver o saldo da Empresa"}
		menu["Consultar Histórico"] = {ch_consultardata,"Ver o Histórico da Empresa"}
		vRP.openMenu({player,menu})
	end})
end




local function build_client_businesscenter(source)
	local user_id = vRP.getUserId({source})
	if user_id ~= nil then
		for k,v in pairs(business) do
			local x,y,z = table.unpack(v)

			local business_enter = function(source)
				local user_id = vRP.getUserId({source})
				if user_id ~= nil and vRP.hasPermission({user_id,cfg.permission}) then
					local menudata = {
						name=cfg.business_title
					}
					menudata["Depositar Dinheiro"] = {ch_depositarsaldo}
					menudata["Consultar Saldo"] = {ch_consultarsaldo}
					menudata["Retirar Saldo"] = {ch_retirarsaldo}
					menudata["Consultar Histórico"] = {ch_consultardata}
					vRP.openMenu({source, menudata})
				end
			end

			local function business_leave(source)
				vRP.closeMenu({source})
			end

			--vRPclient.addBlip(source,{x,y,z,cfg.blipid,cfg.blipcolor,cfg.business_title})
			vRPclient.addMarker(source,{x,y,z-1,0.7,0.7,0.5,0,255,125,125,150})

			vRP.setArea({source,"vRP:pspempresa"..k,x,y,z,1,1.5,business_enter,business_leave})
		end
	end
end


AddEventHandler("vRP:playerSpawn",function(user_id, source, first_spawn)
	if first_spawn then
		build_client_businesscenter(source)
	end
end)