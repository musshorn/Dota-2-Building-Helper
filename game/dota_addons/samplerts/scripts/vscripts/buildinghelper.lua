--[[
  A library to help make RTS-style and Tower Defense custom games in Dota 2
  Developer: Myll
  Version: 2.0
  Credits to:
    Ash47 and BMD for timers.lua.
    BMD for helping figure out how to get mouse clicks in Flash.
    Perry for writing FlashUtil, which contains functions for cursor tracking.
]]
-- Rewritten with multiplayer + shift queue in mind

BuildingHelper = {}
BuildingAbilities = {}

if not OutOfWorldVector then
  OutOfWorldVector = Vector(11000,11000,0)
end

DontCancelBuildingGhostAbils = {} -- not sure what this is for might remove.

function BuildingHelper:Init(...)

  Convars:RegisterCommand( "BuildingPosChosen", function()
    --get the player that sent the command
    local cmdPlayer = Convars:GetCommandClient()
    if cmdPlayer then
      FlashUtil:GetCursorWorldPos(cmdPlayer:GetPlayerID(), function ( pID, location )
        cmdPlayer.activeBuilder:AddToQueue(location)
      end )
    end
  end, "", 0 )

  Convars:RegisterCommand( "CancelBuilding", function()
    --get the player that sent the command
    local cmdPlayer = Convars:GetCommandClient()
    if cmdPlayer then
      cmdPlayer.cancelBuilding = true
    end
  end, "", 0 )

  AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  -- abils and items can't have the same name or the item will override the ability.

  for i=1,2 do
    local t = AbilityKVs
    if i == 2 then
      t = ItemKVs
    end
    for abil_name,abil_info in pairs(t) do
      if type(abil_info) == "table" then
        local isBuilding = abil_info["Building"]
        local cancelsBuildingGhost = abil_info["CancelsBuildingGhost"]
        if isBuilding ~= nil and tostring(isBuilding) == "1" then
          BuildingAbilities[tostring(abil_name)] = abil_info
        end
        if cancelsBuildingGhost ~= nil and tostring(cancelsBuildingGhost) == "0" then
          DontCancelBuildingGhostAbils[tostring(abil_name)] = true
        end
      end
    end
  end


end

function BuildingHelper:AddBuilding(keys)

  -- Callbacks
  function keys:OnConstructionStarted( callback )
    keys.onConstructionStarted = callback
  end

  function keys:OnConstructionCompleted( callback )
    keys.onConstructionCompleted = callback
  end

  function keys:EnableFireEffect( sFireEffect )
    keys.fireEffect = sFireEffect
  end

  function keys:OnBelowHalfHealth( callback )
    keys.onBelowHalfHealth = callback
  end

  function keys:OnAboveHalfHealth( callback )
    keys.onAboveHalfHealth = callback
  end

  function keys:OnBuildingPosChosen( callback )
    keys.onBuildingPosChosen = callback
  end

  local ability = keys.ability
  local abilName = ability:GetAbilityName()
  local buildingTable = BuildingAbilities[abilName]

  function buildingTable:GetVal( key, expectedType )
    local val = buildingTable[key]
    --print('val: ' .. tostring(val))
    if val == nil and expectedType == "bool" then
      return false
    end
    if val == nil and expectedType ~= "bool" then
      return nil
    end

    if tostring(val) == "" then
      return nil
    end

    local sVal = tostring(val)
    if sVal == "1" and expectedType == "bool" then
      return true
    elseif sVal == "0" and expectedType == "bool" then
      return false
    elseif sVal == "" then
      return nil
    elseif expectedType == "number" or expectedType == "float" then
      return tonumber(val)
    end
    return sVal
  end


  -- Extract data from the KV files
  local size = buildingTable:GetVal("BuildingSize", "number")
  if size == nil then
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a BuildingSize KeyValue')
    return
  end

  local unitName = buildingTable:GetVal("UnitName", "string")
  if unitName == nil then
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a UnitName KeyValue')
    return
  end

  local castRange = buildingTable:GetVal("AbilityCastRange", "number")
  if castRange == nil then
    castRange = 200
  end

  local fMaxScale = buildingTable:GetVal("MaxScale", "float")
  if fMaxScale == nil then
    -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
    local fModelScale = UnitKVs[unitName].ModelScale
    if fModelScale then
      fMaxScale = fModelScale
    else
      fMaxScale = 1
    end
  end

  
  -- Prepare the builder, if it hasn't already been done. Since this would need to be done for every builder in some games, might as well do it here.
  local builder = keys.caster
  if builder.buildingQueue == nil then
    builder.buildingQueue = {}
  end

  builder.workTimer = Timers:CreateTimer(0.1, function ()
    if #builder.buildingQueue > 0 and builder.processingWork == false then
      builder.ProcessingBuilding = true
      print("working on some dank meme")
    end
  end)

  -- Get the local player, this assumes the player is only placing one building at a time
  local player = builder:GetPlayerOwner()
  
  player.buildingPosChosen = false
  player.activeBuilder = builder
  player.activeBuilding = unitName
  player.activeBuildingTable = buildingTable

  player.modelGhostDummy = CreateUnitByName(unitName, OutOfWorldVector, false, nil, nil, builder:GetTeam())
  local mgd = player.modelGhostDummy -- alias

  function builder:AddToQueue( location )
    local player = builder:GetPlayerOwner()
    local building = player.activeBuilding
    local buildingTable = player.activeBuildingTable

    -- Create model ghost dummy out of the map, then make pretty particles
    mgd = CreateUnitByName(building, OutOfWorldVector, false, nil, nil, builder:GetTeam())

    --<BMD> position is 0, model attach is 1, color is CP2, alpha is CP3.x, scale is CP4.x
    modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, mgd, player)
    ParticleManager:SetParticleControlEnt(modelParticle, 1, mgd, 1, "follow_origin", mgd:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(modelParticle, 3, Vector(MODEL_ALPHA,0,0))
    ParticleManager:SetParticleControl(modelParticle, 4, Vector(1,0,0))

    ParticleManager:SetParticleControl(modelParticle, 0, builder:GetAbsOrigin())
    ParticleManager:SetParticleControl(modelParticle, 2, Vector(255,255,255))

    table.insert(builder.buildingQueue, {["point"] = location, ["name"] = building, ["buildingTable"] = buildingTable, ["particles"] = modelParticle})
    print("drawn lmao")


  end

  FireGameEvent('build_command_executed', { player_id = pID, building_size = size })

end