--[[
Building Helper for RTS-style and tower defense maps in Dota 2. version: 0.3
Developed by Myll
Credits to Ash47 and BMD for the timer code.
Please give credit in your work if you use this. Thanks, and happy modding!
]]

BUILDINGHELPER_THINK = 0.03
GRIDNAV_SQUARES = {}
BUILDING_SQUARES = {}
BH_UNITS = {}
FORCE_UNITS_AWAY = false
FIRE_GAME_EVENTS = false
BH_Z=129

if BuildingHelper == nil then
	print('[BUILDING HELPER] Creating Building Helper')
	BuildingHelper = {}
	BuildingHelper.__index = BuildingHelper
end

function BuildingHelper:new(o)
	o = o or {}
	setmetatable(o, BuildingHelper)
	return o
end

function BuildingHelper:start()
	BuildingHelper = self
	self.timers = {}
	
	local wspawn = Entities:First()
	wspawn:SetThink("Think", self, "buildinghelper", BUILDINGHELPER_THINK)
end

function BuildingHelper:Think()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return
	end
	
	
	
	 -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local now = GameRules:GetGameTime()
  --print("now: " .. now)
  if BuildingHelper.t0 == nil then
    BuildingHelper.t0 = now
  end
  local dt = now - BuildingHelper.t0
  BuildingHelper.t0 = now

  -- Process timers
  for k,v in pairs(BuildingHelper.timers) do
    local bUseGameTime = false
    if v.useGameTime and v.useGameTime == true then
      bUseGameTime = true;
    end
    -- Check if the timer has finished
    if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
      -- Remove from timers list
      BuildingHelper.timers[k] = nil
      
      -- Run the callback
      local status, nextCall = pcall(v.callback, BuildingHelper, v)

      -- Make sure it worked
      if status then
        -- Check if it needs to loop
        if nextCall then
          -- Change it's end time
          v.endTime = nextCall
          BuildingHelper.timers[k] = v
        end

        -- Update timer data
        --self:UpdateTimerData()
      else
        -- Nope, handle the error
        BuildingHelper:HandleEventError('Timer', k, nextCall)
      end
    end
  end

  return BUILDINGHELPER_THINK
end

function BuildingHelper:HandleEventError(name, event, err)
  print(err)

  -- Ensure we have data
  name = tostring(name or 'unknown')
  event = tostring(event or 'unknown')
  err = tostring(err or 'unknown')

  -- Tell everyone there was an error
  --Say(nil, name .. ' threw an error on event '..event, false)
  --Say(nil, err, false)

  -- Prevent loop arounds
  if not self.errorHandled then
    -- Store that we handled an error
    self.errorHandled = true
  end
end

function BuildingHelper:CreateTimer(name, args)
  if not args.endTime or not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  BuildingHelper.timers[name] = args
end

function BuildingHelper:RemoveTimer(name)
  BuildingHelper.timers[name] = nil
end

function BuildingHelper:RemoveTimers(killAll)
  local timers = {}

  if not killAll then
    for k,v in pairs(BuildingHelper.timers) do
      if v.persist then
        timers[k] = v
      end
    end
  end

  BuildingHelper.timers = timers
end

function BuildingHelper:SetFireGameEvents(bFireGameEvents)
	if bFireGameEvents then FIRE_GAME_EVENTS = true end
end

function BuildingHelper:BlockGridNavSquares(nMapLength)
	local halfLength = nMapLength/2
	local gridnavCount = 0
	-- Check the center of each square on the map to see if it's blocked by the GridNav.
	for x=-halfLength+32, halfLength-32, 64 do
		for y=halfLength-32, -halfLength+32,-64 do
			if GridNav:IsTraversable(Vector(x,y,BH_Z)) == false or GridNav:IsBlocked(Vector(x,y,BH_Z)) then
				--table.insert(GRIDNAV_SQUARES, Vector(x,y,BH_Z))
				GRIDNAV_SQUARES[makeVectorString(Vector(x,y,BH_Z))] = true
				gridnavCount=gridnavCount+1
			end
		end
	end
	print("Total GridNav squares added: " .. gridnavCount)
end

function BuildingHelper:BlockRectangularArea(leftBorderX, rightBorderX, topBorderY, bottomBorderY)
	if leftBorderX%64 ~= 0 or rightBorderX%64 ~= 0 or topBorderY%64 ~= 0 or bottomBorderY%64 ~= 0 then
		print("One of the values does not divide evenly into 64. Returning.")
		return
	end
	local blockedCount = 0
	for x=leftBorderX+32, rightBorderX-32, 64 do
		for y=topBorderY-32, bottomBorderY+32,-64 do
			GRIDNAV_SQUARES[makeVectorString(Vector(x,y,BH_Z))] = true
			blockedCount=blockedCount+1
		end
	end
	print("Total closed squares added: " .. blockedCount)
end

function BuildingHelper:SetForceUnitsAway(bForceAway)
	FORCE_UNITS_AWAY=bForceAway
end

-- Determines the squares that a unit is occupying.
function BuildingHelper:AddUnit(unit)
	if unit:GetPlayerID() == nil then
		print("Not adding this unit because it's not a player's hero.")
		return
	end
	
	unit.bGeneratePathingMap = false
	unit.vPathingMap = {}
	unit.bNeedsToJump=false
	unit.bCantBeBuiltOn = true
	unit.nCustomRadius = unit:GetHullRadius()
	unit.bForceAway = false
	unit.bPathingMapGenerated = false
	
	local id = unit:GetPlayerID()
	if BH_UNITS[id] ~= true then
		BH_UNITS[id]=true
	end
	
	function unit:SetCustomRadius(nRadius)
		unit.nCustomRadius = nRadius
	end
	
	function unit:GetCustomRadius()
		return unit.nCustomRadius
	end
	
	function unit:GeneratePathingMap()
		--print("Generating pathing map...")
		local pathmap = {}
		local length = snapToGrid64(unit.nCustomRadius)
		length = length+128
		local c = unit:GetAbsOrigin()
		local x2 = snapToGrid64(c.x)
		local y2 = snapToGrid64(c.y)
		local unitRect = makeBoundingRect(x2-length, x2+length, y2+length, y2-length)
		local xs = {}
		local ys = {}
		for a=0,2*3.14,3.14/10 do
			table.insert(xs, math.cos(a)*unit.nCustomRadius+c.x)
			table.insert(ys, math.sin(a)*unit.nCustomRadius+c.y)
		end
		
		local pathmapCount=0
		for i=1, #xs do
			-- Check if this boundary circle point is inside any square in the list.
			for x=unitRect.leftBorderX+32,unitRect.rightBorderX-32,64 do
				for y=unitRect.topBorderY-32,unitRect.bottomBorderY+32,-64 do
					if (xs[i] >= x-32 and xs[i] <= x+32) and (ys[i] >= y-32 and ys[i] <= y+32) then
						if pathmap[makeVectorString(Vector(x,y,BH_Z))] ~= true then
							--BuildingHelper:PrintSquareFromCenterPointShort(Vector(x,y,BH_Z))
							pathmapCount=pathmapCount+1
							pathmap[makeVectorString(Vector(x,y,BH_Z))]=true
						end
					end
				end
			end
		end
		--print('pathmap length: ' .. pathmapCount)
		unit.vPathingMap = pathmap
		unit.bPathingMapGenerated = true
		return pathmap
	end
end

function BuildingHelper:RemoveUnit(unit)
	if IsValidEntity(unit) and BH_UNITS[unit]==false then
		BH_UNITS[unit]=nil
	end
end

function BuildingHelper:AddBuildingToGrid(vPoint, nSize, vOwnersHero)
	-- Remember, our blocked squares are defined according to the square's center.
	local startX = snapToGrid32(vPoint.x)
	local startY = snapToGrid32(vPoint.y)
	
	-- This is the place where you should SetAbsOrigin the building.
	local centerX = snapToGrid64(vPoint.x)
	local centerY = snapToGrid64(vPoint.y)
	-- Buildings are centered differently when the size is odd.
	if nSize%2 ~= 0 then
		centerX=startX
		centerY=startY
		--print("Odd size.")
	end
	local vBuildingCenter = Vector(centerX,centerY,vPoint.z)
	local halfSide = (nSize/2)*64
	local buildingRect = {leftBorderX = centerX-halfSide, 
		rightBorderX = centerX+halfSide, 
		topBorderY = centerY+halfSide, 
		bottomBorderY = centerY-halfSide}
		
	if BuildingHelper:IsRectangularAreaBlocked(buildingRect) then
		print("Building location blocked. Returning -1")
		-- It'd be wise to fire a game event when this returns -1 and use Actionscript to notify the player that the spot is blocked.
		return -1
	end
	
	-- Add every player's hero to BH_UNITS if it's not already.
	local heroes = HeroList:GetAllHeroes()
	for i,v in ipairs(heroes) do
		if v:GetOwner() ~= nil and BH_UNITS[v:GetPlayerID()] ~= true then
			print('adding unit')
			self:AddUnit(v)
		end
	end
	
	-- The spot is not blocked, so add it to the closed squares.
	local closed = {}
	if BH_UNITS[vOwnersHero:GetPlayerID()] then
		vOwnersHero:GeneratePathingMap()
	else
		print("You haven't added the owner as a unit. No pathing map will be generated, and the owner may get stuck after building the building.")
	end
	
	for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
		for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
			if vOwnersHero ~= nil and vOwnersHero.vPathingMap ~= nil then
				--print("Checking for jump...")
				if vOwnersHero.bPathingMapGenerated and vOwnersHero.vPathingMap[makeVectorString(Vector(x,y,BH_Z))] then
					--print('Owner jump')
					vOwnersHero.bNeedsToJump=true
				end
				for id,b in pairs(BH_UNITS) do
					local unit = PlayerResource:GetPlayer(id):GetAssignedHero()
					if unit ~= vOwnersHero then
						unit:GeneratePathingMap()
						if unit.vPathingMap[makeVectorString(Vector(x,y,BH_Z))] then
							if FORCE_UNITS_AWAY then
								unit.bNeedsToJump=true
							else
								print("Building location blocked. Returning -1")
								return -1
							end
						end
					end
				end
			end
			
			table.insert(closed,Vector(x,y,BH_Z))
		end
	end
	--table.insert(BUILDING_SQUARES, closed)
	for i,v in ipairs(closed) do
		BUILDING_SQUARES[makeVectorString(v)]=true
	end
	print("Successfully added " .. #closed .. " closed squares.")
	return vBuildingCenter
end

function BuildingHelper:AddBuilding(building)
	building.BuildingHelperTimer = self.timers[building.BuildingHelperTimer]
	building.bUpdatingHealth = false
	building.nBuildTime = 1
	building.fTimeBuildingCompleted = GameRules:GetGameTime()+1
	building.vOrigin = building:GetAbsOrigin()
	building.nMaxHealth = building:GetMaxHealth()
	building.nHealthInterval = 10
	building.fireEffect="modifier_jakiro_liquid_fire_burn"
	building.bFireEnabled=true
	building.bForceUnits = false
	building.fMaxScale=1.0
	building.fCurrentScale = 0.0
	building.bScale=false
	
	for id,b in pairs(BH_UNITS) do
		local unit = PlayerResource:GetPlayer(id):GetAssignedHero()
		if unit.bNeedsToJump then
			--print("jumping")
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			unit.bNeedsToJump=false
		end
	end
	
	function building:PackWithDummies()
		local d = math.pow(0.5,0.5) + (math.pow(2,0.5) - math.pow(0.5,0.5))/2
	end
	
	function building:SetFireEffect(fireEffect)
		if fireEffect==nil then building.bFireEnabled = false return end
		building.fireEffect = fireEffect
	end
	
	function building:GetFireEffect()
		if building.fireEffect ~= nil then
			return building.fireEffect
		end
	end

	function building:UpdateHealth(fBuildTime, bScale, fMaxScale)
		building:SetHealth(1)
		building.nfBuildTime=fBuildTime
		building.fTimeBuildingCompleted=GameRules:GetGameTime()+fBuildTime+fBuildTime*.35
		building.nMaxHealth = building:GetMaxHealth()
		building.nHealthInterval = building.nMaxHealth*1/(fBuildTime/BUILDINGHELPER_THINK)
		building.bUpdatingHealth = true
		if bScale then
			building.fMaxScale=fMaxScale
			building.fScaleInterval=building.fMaxScale*1/(fBuildTime/BUILDINGHELPER_THINK)
			building.fScaleInterval=building.fScaleInterval-.1*building.fScaleInterval
			building.fCurrentScale=.2*fMaxScale
			building.bScale=true
		end
	end
	
	function building:RemoveBuilding(nSize, bKill)
		local center = building:GetAbsOrigin()
		--DebugDrawCircle( center, Vector(0,255,0), 13.0, 3, false, 50 )
		--[[Error check
		if ((nSize%2 ~= 0) and (centerX%32 == 0 and centerY%32 == 0)) == false then
			print("Invalid center! Returning.")
			return
		elseif ((nSize%2 == 0) and (centerX%64 == 0 and centerY%64 == 0)) == false then
			print("Invalid center! Returning.")
			return
		end]]
		local halfSide = (nSize/2.0)*64
		local buildingRect = {leftBorderX = center.x-halfSide, 
			rightBorderX = center.x+halfSide, 
			topBorderY = center.y+halfSide, 
			bottomBorderY = center.y-halfSide}
		local removeCount=0
		for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
			for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
				for v,b in pairs(BUILDING_SQUARES) do
					--if tableContains(v, Vector(x,y,BH_Z)) then
					if v == makeVectorString(Vector(x,y,BH_Z)) then
						--print("Removing " .. #v .. " squares.")
						--table.remove(BUILDING_SQUARES, i)
						BUILDING_SQUARES[v]=nil
						removeCount=removeCount+1
						if bKill then
							building:SetAbsOrigin(Vector(center.x,center.y,center.z-200))
							building:ForceKill(true)
						end
					end
				end
			end
		end
		print("Removing " .. removeCount .. " squares.")
	end
	
	function building:SetOwner(vOwner)
		building.vOwner = vOwner
	end
	
	function building:GetOwner()
		return building.vOwner
	end
	
	building.BuildingTimerName = DoUniqueString('building')
	BuildingHelper:CreateTimer(building.BuildingTimerName, {
    endTime = GameRules:GetGameTime(),
    useGameTime = true,
    callback = function(sheeptag, args)
		local curTime = GameRules:GetGameTime()
		
		if IsValidEntity(building) then
			if building.bUpdatingHealth then
				if building:GetHealth() < building.nMaxHealth and GameRules:GetGameTime() <= building.fTimeBuildingCompleted then
					building:SetHealth(building:GetHealth()+building.nHealthInterval)
				else
					building.bUpdatingHealth=false
				end
			end
			
			if building.bScale then
				if building.fCurrentScale < building.fMaxScale then
					building.fCurrentScale = building.fCurrentScale+building.fScaleInterval
					building:SetModelScale(building.fCurrentScale)
				else
					building.bScale=false
				end
			end

			if building.bFireEnabled then
				if building:GetHealth() <= building:GetMaxHealth()/2 and building.bUpdatingHealth == false then
					if building:HasModifier(building.fireEffect) == false then
						building:AddNewModifier(building, nil, building.fireEffect, nil)
				end
				elseif building:GetHealth() > building:GetMaxHealth()/2 and building:HasModifier(building.fireEffect) then
					building:RemoveModifierByName(building.fireEffect)
				end
			end
		end
		
	    return curTime
    end})
end

function makeVectorString(v)
	--print(tostring(v))
	local s = tostring(v.x .. "," .. v.y)
	return s
end

function BuildingHelper:IsRectangularAreaBlocked(boundingRect)
	for x=boundingRect.leftBorderX+32,boundingRect.rightBorderX-32,64 do
		for y=boundingRect.topBorderY-32,boundingRect.bottomBorderY+32,-64 do
			local vect = Vector(x,y,BH_Z)
			if GRIDNAV_SQUARES[makeVectorString(vect)] or BUILDING_SQUARES[makeVectorString(vect)] then
				return true
			end
		end
	end
	return false
end

function snapToGrid64(coord)
	return 64*math.floor(0.5+coord/64)
end

function snapToGrid32(coord)
	return 32+64*math.floor(coord/64)
end


function tableContains(list, element)
  if list == nil then return false end
  for i=1,#list do
    if list[i] == element then
      return true
    end
  end
  return false
end

function makeBoundingRect(leftBorderX, rightBorderX, topBorderY, bottomBorderY)
	return {leftBorderX = leftBorderX, rightBorderX = rightBorderX, topBorderY = topBorderY, bottomBorderY = bottomBorderY}
end

--Set BH_Z to a little above whatever your map's base Z-level is if you want to print out squares with these functions.
function BuildingHelper:PrintSquareFromCenterPoint(v)
			DebugDrawLine(Vector(v.x-32,v.y+32,BH_Z), Vector(v.x+32,v.y+32,BH_Z), 255, 0, 0, false, 30)
			DebugDrawLine(Vector(v.x-32,v.y+32,BH_Z), Vector(v.x-32,v.y-32,BH_Z), 255, 0, 0, false, 30)
			DebugDrawLine(Vector(v.x-32,v.y-32,BH_Z), Vector(v.x+32,v.y-32,BH_Z), 255, 0, 0, false, 30)
			DebugDrawLine(Vector(v.x+32,v.y-32,BH_Z), Vector(v.x+32,v.y+32,BH_Z), 255, 0, 0, false, 30)
end
function BuildingHelper:PrintSquareFromCenterPointShort(v)
			DebugDrawLine(Vector(v.x-32,v.y+32,BH_Z), Vector(v.x+32,v.y+32,BH_Z), 255, 0, 0, false, .1)
			DebugDrawLine(Vector(v.x-32,v.y+32,BH_Z), Vector(v.x-32,v.y-32,BH_Z), 255, 0, 0, false, .1)
			DebugDrawLine(Vector(v.x-32,v.y-32,BH_Z), Vector(v.x+32,v.y-32,BH_Z), 255, 0, 0, false, .1)
			DebugDrawLine(Vector(v.x+32,v.y-32,BH_Z), Vector(v.x+32,v.y+32,BH_Z), 255, 0, 0, false, .1)
end

--Put this line in InitGameMode to use this function: Convars:RegisterCommand( "buildings", Dynamic_Wrap(YourGameMode, 'DisplayBuildingGrids'), "blah", 0 )

--[[function YourGameMode:DisplayBuildingGrids()
  print( '******* Displaying Building Grids ***************' )
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    local playerID = cmdPlayer:GetPlayerID()
    if playerID ~= nil and playerID ~= -1 then
      -- Do something here for the player who called this command
		for vectString,b in pairs(BUILDING_SQUARES) do
			if b then
				local i = vectString:find(",")
				local x = tonumber(vectString:sub(1,i-1))
				local y = tonumber(vectString:sub(i+1))
				print("x: " .. x .. "y: " .. y)
				--PrintVector(square)
				BuildingHelper:PrintSquareFromCenterPoint(Vector(x,y,BH_Z))
			end
		end
    end
  end
  print( '*********************************************' )
end]]

BuildingHelper:start()
