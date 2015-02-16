Debug_Peasant = false

function Gather( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_class = target:GetClassname()

	-- Initialize variable to keep track of how much resource is the unit carrying
	if not caster.lumber_gathered then
		caster.lumber_gathered = 0
	end

	-- Intialize the variable to stop the return (workaround for ExecuteFromOrder being good and MoveToNPC now working after a Stop)
	caster.manual_order = false

	if target_class == "ent_dota_tree" then
		caster:MoveToTargetToAttack(target)
		if Debug_Peasant then
			print("Moving to ", target_class)
		end
		caster.target_tree = target
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})

	-- Visual fake toggle
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end

	-- Hide Return
	local return_ability = caster:FindAbilityByName("return_resources")
	return_ability:SetHidden(true)
	ability:SetHidden(false)
	if Debug_Peasant then
		print("Gather ON, Return OFF")
	end
end

-- Toggles Off Gather
function ToggleOffGather( event )
	local caster = event.caster
	local gather_ability = caster:FindAbilityByName("gather_lumber")

	if gather_ability:GetToggleState() == true then
		gather_ability:ToggleAbility()
		if Debug_Peasant then
			print("Toggled Off Gather")
		end
	end
end

-- Toggles Off Return because of an order (e.g. Stop)
function ToggleOffReturn( event )
	local caster = event.caster
	local return_ability = caster:FindAbilityByName("return_resources")

	if return_ability:GetToggleState() == true then 
		return_ability:ToggleAbility()
		if Debug_Peasant then
			print("Toggled Off Return")
		end
	end
	caster.skip_order = false
end


function CheckTreePosition( event )

	local caster = event.caster
	local target = caster.target_tree -- Index tree so we know which target to start with
	local ability = event.ability
	local target_class = target:GetClassname()

	if target_class == "ent_dota_tree" then
		caster:MoveToTargetToAttack(target)
		--print("Moving to "..target_class)
	end

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance < 100
	if not collision then
		--print("Moving to tree, distance: ",distance)
	elseif not caster:HasModifier("modifier_chopping_wood") then
		caster:RemoveModifierByName("modifier_gathering_lumber")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_chopping_wood", {})
		if Debug_Peasant then
			print("Reached tree")
		end
	end
end

function Gather1Lumber( event )
	
	local caster = event.caster
	local ability = event.ability
	local max_lumber_carried = 10 --20 with upgrade

	local return_ability = caster:FindAbilityByName("return_resources")

	caster.lumber_gathered = caster.lumber_gathered + 1
	if Debug_Peasant then
		print("Gathered "..caster.lumber_gathered)
	end

	-- Show the stack of resources that the unit is carrying
	if not caster:HasModifier("modifier_returning_resources") then
        return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_returning_resources", nil)
    end
    caster:SetModifierStackCount("modifier_returning_resources", caster, caster.lumber_gathered)
 
	-- Increase up to the max, or cancel
	if caster.lumber_gathered < max_lumber_carried then

		-- Fake Toggle the Return ability
		if return_ability:GetToggleState() == false or return_ability:IsHidden() then
			if Debug_Peasant then
				print("Gather OFF, Return ON")
			end
			return_ability:SetHidden(false)
			if return_ability:GetToggleState() == false then
				return_ability:ToggleAbility()
			end
			ability:SetHidden(true)
		end
	else
		local player = caster:GetOwner():GetPlayerID()
		caster:RemoveModifierByName("modifier_chopping_wood")

		-- Return Ability On		
		caster:CastAbilityNoTarget(return_ability, player)
		return_ability:ToggleAbility()
	end
end


function ReturnResources( event )

	local caster = event.caster
	local ability = event.ability

	if caster.lumber_gathered and caster.lumber_gathered > 0 then
		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster )
		if Debug_Peasant then
			print("Returning "..caster.lumber_gathered.." Lumber back to "..building:GetUnitName())
		end

		-- Set On, Wait one frame, as OnOrder gets executed before this is applied.
		Timers:CreateTimer(0.03, function() 
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
				if Debug_Peasant then
					print("Return Ability Toggled On")
				end
			end
		end)

		ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, TargetIndex = building:GetEntityIndex(), Position = building:GetAbsOrigin(), Queue = false}) 
		caster.skip_order = true
		caster.target_building = building
	end
end

function CheckBuildingPosition( event )

	local caster = event.caster
	local target = caster.target_building -- Index building so we know which target to start with
	local ability = event.ability

	if not target then
		return
	end

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance <= (caster.target_building:GetHullRadius()+100)
	if not collision then
		--print("Moving to building, distance: ",distance)
	else
		local hero = caster:GetOwner()
		local pID = hero:GetPlayerID()
		caster:RemoveModifierByName("modifier_returning_resources")
		if Debug_Peasant then
			print("Removed modifier_returning_resources")
		end

		if caster.lumber_gathered > 0 then
			if Debug_Peasant then
				print("Reached building, give resources")
			end

			-- Green Particle Lumber Popup
			POPUP_SYMBOL_PRE_PLUS = 0 -- This makes the + on the message particle
			local pfxPath = string.format("particles/msg_fx/msg_damage.vpcf", pfx)
			local pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, caster)
			local color = Vector(10, 200, 90)
			local lifetime = 3.0
		    local digits = #tostring(caster.lumber_gathered) + 1
		    
		    ParticleManager:SetParticleControl(pidx, 1, Vector( POPUP_SYMBOL_PRE_PLUS, caster.lumber_gathered, 0 ) )
		    ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
		    ParticleManager:SetParticleControl(pidx, 3, color)

		    --[[ Increase Custom Resource
			hero.lumber = hero.lumber + caster.lumber_gathered 
    		print("Lumber Gained. " .. hero:GetUnitName() .. " is currently at " .. hero.lumber)
    		FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = hero.lumber })]]

			caster.lumber_gathered = 0
		end

		-- Return Ability Off
		if ability:ToggleAbility() == true then
			ability:ToggleAbility()
			if Debug_Peasant then
				print("Return Ability Toggled Off")
			end
		end

		-- Gather Ability
		local gather_ability = caster:FindAbilityByName("gather_lumber")
		if gather_ability:ToggleAbility() == false then
			-- Fake toggle On
			gather_ability:ToggleAbility() 
			if Debug_Peasant then
				print("Gather Ability Toggled On")
			end
		end
		caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
		if Debug_Peasant then
			print("Casting ability to target tree")
		end
	end
end


-- Aux to find resource deposit
function FindClosestResourceDeposit( caster )
	local position = caster:GetAbsOrigin()

	-- Find a building to deliver
	local barracks = Entities:FindAllByModel("models/props_structures/good_barracks_melee001.vmdl")	
	local distance = 9999
	local closest_building = nil

	if barracks then
		if Debug_Peasant then
			print("barrack found")
		end
		for _,building in pairs(barracks) do
			-- Ensure the same owner
			if building:GetOwner() == caster:GetOwner() then
				local this_distance = (position - building:GetAbsOrigin()):Length()
				if this_distance < distance then
					distance = this_distance
					closest_building = building
				end
			end
		end
		return closest_building

	end

end