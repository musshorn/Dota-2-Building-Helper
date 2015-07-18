-- The following three functions are necessary for building helper.

function build( keys )
    local player = keys.caster:GetPlayerOwner()
    local pID = player:GetPlayerID()
    local ability = keys.ability

    -- We don't want to charge the player resources at this point
    -- This is only relevent for abilities that use AbilityGoldCost
    local goldCost = keys.ability:GetGoldCost(-1)
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
        FindClearSpaceForUnit(keys.caster, keys.caster:GetAbsOrigin(), true)
        ability:StartCooldown(ability:GetCooldown(-1))

    end)
    keys:OnConstructionCompleted(function(unit)
        -- Play construction complete sound.
        -- Give building its abilities
        -- add the mana
        unit:SetMana(unit:GetMaxMana())
    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't unnecessarily fire multiple times.
    keys:OnBelowHalfHealth(function(unit)
    end)

    keys:OnAboveHalfHealth(function(unit)

    end)

    keys:OnConstructionFailed(function( building )
        -- This runs when a building cannot be placed, you should refund resources if any. building is the unit that would've been built.
    end)

    keys:OnConstructionCancelled(function( building )
        -- This runs when a building is cancelled, building is the unit that would've been built.
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