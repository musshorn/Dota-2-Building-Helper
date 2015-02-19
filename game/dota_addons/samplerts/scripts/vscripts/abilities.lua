function build( keys )
	local player = keys.caster:GetPlayerOwner()
	local pID = player:GetPlayerID()
	player.lumber = 20
	player.stone = 10
	local returnTable = BuildingHelper:AddBuilding(keys)
	--print("Lumber: " .. player.lumber)
	--print("Stone: " .. player.stone)

	-- handle errors if any
	if TableLength(returnTable) > 0 then
		--PrintTable(returnTable)
		if returnTable["error"] == "not_enough_resources" then
			local resourceTable = returnTable["resourceTable"]
			-- resourceTable is like this: {["lumber"] = 3, ["stone"] = 6}
			-- so resourceName = cost-playersResourceAmount
			-- the api searches for player[resourceName]. you need to keep this number updated
			-- throughout your game
			local firstResource = nil
			for k,v in pairs(resourceTable) do
				if not firstResource then
					firstResource = k
				end
				if Debug_BH then
					print("P" .. pID .. " needs " .. v .. " more " .. k .. ".")
				end
			end
			local capitalLetter = firstResource:sub(1,1):upper()
			firstResource = capitalLetter .. firstResource:sub(2)
			FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Not enough " .. firstResource .. "." } )
			return
		end
	end

	keys:OnConstructionStarted(function(unit)
		--print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound
		-- FindClearSpace for the builder
		FindClearSpaceForUnit(keys.caster, keys.caster:GetAbsOrigin(), true)
		-- start the building with 0 mana.
		unit:SetMana(0)
	end)
	keys:OnConstructionCompleted(function(unit)
		--print("Completed construction of " .. unit:GetUnitName())
		-- Play construction complete sound.
		-- Give building its abilities
		-- add the mana
		unit:SetMana(unit:GetMaxMana())
	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't unnecessarily fire multiple times.
	keys:OnBelowHalfHealth(function(unit)
		if Debug_BH then
			print(unit:GetUnitName() .. " is below half health.")
		end
	end)

	keys:OnAboveHalfHealth(function(unit)
		if Debug_BH then
			print(unit:GetUnitName() .. " is above half health.")
		end
	end)

	--[[keys:OnCanceled(function()
		print(keys.ability:GetAbilityName() .. " was canceled.")
	end)]]

	-- Have a fire effect when the building goes below 50% health.
	-- It will turn off it building goes above 50% health again.
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end

function create_building_entity( keys )
	BuildingHelper:InitializeBuildingEntity(keys)
end

