-- The following three functions are necessary for building helper.

function build( keys )
    local player = keys.caster:GetPlayerOwner()
    local pID = player:GetPlayerID()
    local ability = keys.ability

    -- We don't want to charge the player resources at this point
    -- This is only relevent for abilities that use AbilityGoldCost
    local goldCost = ability:GetGoldCost(-1)

    PlayerResource:ModifyGold(pID, goldCost, false, 7) 
    ability:EndCooldown()

    BuildingHelper:AddBuilding(keys)

    keys:OnBuildingPosChosen(function(vPos)
        --print("OnBuildingPosChosen")
        -- in WC3 some build sound was played here.
    end)

    keys:OnPreConstruction(function ()
        -- Use this function to check/modify player resources before the construction begins
        -- Return false to abort the build. It cause OnConstructionFailed to be called
        if PlayerResource:GetGold(pID) < goldCost then
            return false
        end

        PlayerResource:ModifyGold(pID, -1 * goldCost, false, 7)
    end)

    keys:OnConstructionStarted(function(unit)
        -- This runs as soon as the building is created
        --team stuff
        local teamid = unit:GetTeamNumber() 
        local color = SampleRTS.m_TeamColors[teamid]
        --pedestal
        
        local pedestal = Entities:CreateByClassname("prop_dynamic")
        pedestal:SetModel("models/props_teams/logo_teams_tintable.vmdl")
        pedestal:SetRenderColor( color[1], color[2], color[3] ) 
        pedestal:SetModelScale(0.5) 
        pedestal:SetAbsOrigin(unit:GetAbsOrigin() - Vector(0,0,5))
        unit.pedestal = pedestal
        
        local particleIndex = ParticleManager:CreateParticle("particles/tower_levels.vpcf", PATTACH_OVERHEAD_FOLLOW, unit) 
	    --print(particleIndex)
	    ParticleManager:SetParticleControl(particleIndex, 0, Vector(1, 0, 0))
	    ParticleManager:SetParticleControl(particleIndex, 1, Vector(1, 0, 0))
	    ParticleManager:SetParticleControl(particleIndex, 2, Vector(1, 0, 0))
	    ParticleManager:SetParticleControl(particleIndex, 3, Vector(1, 0, 0))   
	    unit.particleIndex = particleIndex 
	    Timers:CreateTimer(1.5, function()
        --print("ding")
        unit:EmitSound("General.LevelUp") end) -- ding!
        ability:StartCooldown(ability:GetCooldown(-1))

    end)
    keys:OnConstructionCompleted(function(unit)
        -- Play construction complete sound.
        PlayerResource:IncrementDeaths(pID)
        unit:RemoveModifierByName("modifier_building")
        ParticleManager:SetParticleControl(unit.particleIndex, 4, Vector(1, 0, 0))
        -- start AI
        if unit:GetUnitName() == "npc_dota_tower_death" then 
        attack(unit)
        scythemaxdmg(unit)
        elseif unit:GetUnitName() == "npc_dota_tower_arrow" then 
        attackMagic(unit)
        elseif unit:GetUnitName() == "npc_dota_tower_zap" then 
        attackMagic(unit)
        physMagicSpell(unit)
        elseif unit:GetUnitName() == "npc_dota_tower_rocket" then 
        PewThink(unit)
        MissileThink(unit)  
        end
    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't unnecessarily fire multiple times.
    keys:OnBelowHalfHealth(function(unit)
    end)

    keys:OnAboveHalfHealth(function(unit)

    end)

    keys:OnConstructionFailed(function( building )
        -- This runs when a building cannot be placed, you should refund resources if any. building is the unit that would've been built.
        Notifications:Bottom(player:GetPlayerID(), {text="Can't build here!", duration=1,class="ErrorMessage"})
        player:EmitSound("General.InvalidTarget_Invulnerable") --meepmerp
        --print("Failed")
    end)

    keys:OnConstructionCancelled(function( building )
        -- This runs when a building is cancelled, building is the unit that would've been built.
        --print("Cancelled")
    end)

    -- Have a fire effect when the building goes below 50% health.
    -- It will turn off it building goes above 50% health again.
    keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end

function building_canceled( keys )
    BuildingHelper:CancelBuilding(keys)
end

function create_building_entity( keys )
    BuildingHelper:InitializeBuildingEntity(keys)
end

function builder_queue( keys )
    local ability = keys.ability
    local caster = keys.caster  

    if caster.ProcessingBuilding ~= nil then
        -- caster is probably a builder, stop them
        player = PlayerResource:GetPlayer(caster:GetMainControllingPlayer())
        player.activeBuilder:ClearQueue()
        player.activeBuilding = nil
        player.activeBuilder:Stop()
        player.activeBuilder.ProcessingBuilding = false
    end
end