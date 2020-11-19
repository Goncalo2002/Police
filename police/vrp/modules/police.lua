--[[
#######################################################
###################Feito Por###########################
################Gonçalo-)#6824#########################
##########https://discord.gg/ABWPUTH###################
#######################################################
]]

-- Adicionar no vrp/modules/police.lua depois do | local cfg = module("cfg/police") | 
function updateMulta(percent)
	local id = vRP.getUsersByPermission("chefe.psp")
	if #id > 0 then
		for k, v in pairs(id) do
			MySQL.execute("vRP/update_money_pspempresa", {bmoney = percent,id = v})
		end
	end
end


-- adicionar no meio do codigo por exemplo depois do local choice_jail

local choice_fine = {function(player, choice)
  local user_id = vRP.getUserId(player)
  if user_id ~= nil then
    vRPclient.getNearestPlayer(player, {5}, function(nplayer)
      local nuser_id = vRP.getUserId(nplayer)
      if nuser_id ~= nil then
        local money = vRP.getMoney(nuser_id)+vRP.getBankMoney(nuser_id)

        -- build fine menu
        local menu = {name=lang.police.menu.fine.title(),css={top="75px",header_color="rgba(0,125,255,0.75)"}}

        local choose = function(player,choice) -- fine action
          local amount = cfg.fines[choice]
          if amount ~= nil then
			if vRP.tryFullPayment(nuser_id, amount) then
			local percent = amount
			  updateMulta(percent)
              vRP.insertPoliceRecord(nuser_id, lang.police.menu.fine.record({choice,amount}))
              vRPclient.notify(player,{lang.police.menu.fine.fined({choice,amount})})
              vRPclient.notify(nplayer,{lang.police.menu.fine.notify_fined({choice,amount})})
              vRP.closeMenu(player)
            else
              vRPclient.notify(player,{lang.money.not_enough()})
            end
          end
        end

        for k,v in pairs(cfg.fines) do -- add fines in function of money available
          if v <= money then
            menu[k] = {choose,v}
          end
        end

        -- open menu
        vRP.openMenu(player, menu)
      else
        vRPclient.notify(player,{lang.common.no_player_near()})
      end
    end)
  end
end, lang.police.menu.fine.description()}

