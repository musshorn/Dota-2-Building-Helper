--[[
	Author: Noya
	Date: 11.02.2015.
	Creates a rally point flag for this unit, removing the old one if there was one
]]
Debug_Rally = false
function SetRallyPoint( event )
	local caster = event.caster
	local origin = caster:GetOrigin()
	if Debug_Rally then
		print(origin)
	end
	
	-- Need to wait one frame for the building to be properly positioned
	Timers:CreateTimer(0.03, function()

		-- If there's an old flag, remove
		if caster.flag then
			caster.flag:RemoveSelf()
		end

		-- Make a new one
		caster.flag = Entities:CreateByClassname("prop_dynamic")

		-- Find vector towards 0,0,0 for the initial rally point
		origin = caster:GetOrigin()
		local forwardVec = Vector(0,0,0) - origin
		forwardVec = forwardVec:Normalized()

		local point = origin
		if not event.target_points then
			-- For the initial rally point, get point away from the building looking towards (0,0,0)
			point = origin + forwardVec * 220
			DebugDrawCircle(point, Vector(255,255,255), 255, 10, false, 10)
			DebugDrawCircle(point, Vector(255,255,255), 255, 20, false, 10)

			-- Keep track of this position so that every unit is autospawned there (avoids going around the)
			caster.initial_spawn_position = point

			-- Add item ability to change rally point
			local item = CreateItem("item_rally", caster, caster)
			caster:AddItem(item)

		else
			point = event.target_points[1]
			--caster.flag = nil
		end

		local flag_model = "models/particle/legion_duel_banner.vmdl"

		caster.flag:SetAbsOrigin(point)
		caster.flag:SetModel(flag_model)
		caster.flag:SetModelScale(0.7)
		caster.flag:SetForwardVector(forwardVec)

		DebugDrawLine(caster:GetAbsOrigin(), point, 255, 255, 255, false, 10)
		if Debug_Rally then
			print(caster:GetUnitName().." sets rally point on ",point)
		end
	end)
end

-- Queues a movement command for the spawned unit to the rally point
function MoveToRallyPoint( event )
	local caster = event.caster
	local target = event.target

	if caster.flag then
		local position = caster.flag:GetAbsOrigin()
		Timers:CreateTimer(0.05, function() target:MoveToPosition(position) end)
		if Debug_Rally then
			print(target:GetUnitName().." moving to position",position)
		end
	end
end

function GetInitialRallyPoint( event )
	local caster = event.caster
	local initial_spawn_position = caster.initial_spawn_position

	local result = {}
	if initial_spawn_position then
		table.insert(result,initial_spawn_position)
	else
		if Debug_Rally then
			print("Fail, no initial rally point, this shouldn't happen")
		end
	end

	return result
end