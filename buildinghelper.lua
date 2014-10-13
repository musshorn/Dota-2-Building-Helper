--[[
Building Helper for RTS-style and tower defense maps in Dota 2. version: 0.4
Developed by Myll
Credits to Ash47 and BMD for the timer code.
Please give credit in your work if you use this. Thanks, and happy modding!
]]

BUILDINGHELPER_THINK = 0.03
GRIDNAV_SQUARES = {}
BUILDING_SQUARES = {}
BH_UNITS = {}
FORCE_UNITS_AWAY = false
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
end

function BuildingHelper:SetForceUnitsAway(bForceAway)
	FORCE_UNITS_AWAY=bForceAway
end

-- Determines the squares that a unit is occupying.
function BuildingHelper:AddUnit(unit)

	-- Remove the unit if it was already added.

	unit.bGeneratePathingMap = false
	unit.vPathingMap = {}
	unit.bNeedsToJump=false
	unit.bCantBeBuiltOn = true
	unit.fCustomRadius = unit:GetHullRadius()
	unit.bForceAway = false
	unit.bPathingMapGenerated = false
	unit.bhID = DoUniqueString("bhID")

	-- Set the id to the playerID if it's a player's hero.
	if unit:IsHero() and unit:GetOwner() ~= nil then
		unit.bhID = unit:GetPlayerID()
	end
	BH_UNITS[unit.bhID] = unit

	function unit:SetCustomRadius(fRadius)
		unit.fCustomRadius = fRadius
	end
	
	function unit:GetCustomRadius()
		return unit.fCustomRadius
	end
	
	function unit:GeneratePathingMap()
		--print("Generating pathing map...")
		local pathmap = {}
		local length = snapToGrid64(unit.fCustomRadius)
		length = length+128
		local c = unit:GetAbsOrigin()
		local x2 = snapToGrid64(c.x)
		local y2 = snapToGrid64(c.y)
		local unitRect = makeBoundingRect(x2-length, x2+length, y2+length, y2-length)
		local xs = {}
		local ys = {}
		for a=0,2*3.14,3.14/10 do
			table.insert(xs, math.cos(a)*unit.fCustomRadius+c.x)
			table.insert(ys, math.sin(a)*unit.fCustomRadius+c.y)
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

function BuildingHelper:AddPlayerHeroes()
	-- Add every player's hero to BH_UNITS if it's not already.
	local heroes = HeroList:GetAllHeroes()
	for i,v in ipairs(heroes) do
		-- if it's a player's hero
		if v:GetOwner() ~= nil then
			BuildingHelper:AddUnit(v)
		end
	end
end

function BuildingHelper:RemoveUnit(unit)
	if unit.bhID == nil then
		-- unit was never added.
		return
	end
	BH_UNITS[unit.bhID] = nil
end

function BuildingHelper:AddBuildingToGrid(vPoint, nSize, hOwnersHero)
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
		return -1
	end
	
	-- The spot is not blocked, so add it to the closed squares.
	local closed = {}

	if BH_UNITS[hOwnersHero:GetPlayerID()] then
		hOwnersHero:GeneratePathingMap()
	else
		print("[Building Helper] Error: You haven't added the owner as a unit.")
	end
	
	for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
		for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
			if hOwnersHero ~= nil and hOwnersHero.vPathingMap ~= nil then
				-- jump the owner if it's in the way of this building.
				--print("Checking for jump...")
				if hOwnersHero.bPathingMapGenerated and hOwnersHero.vPathingMap[makeVectorString(Vector(x,y,BH_Z))] then
					--print('Owner jump')
					hOwnersHero.bNeedsToJump=true
				end
				-- check if other units are in the way of this building. could make this faster.
				for id,unit in pairs(BH_UNITS) do
					if unit ~= hOwnersHero then
						unit:GeneratePathingMap()
						-- if a square in the pathing map overlaps a square of this building
						if unit.vPathingMap[makeVectorString(Vector(x,y,BH_Z))] then
							-- force the units away if the bool is true.
							if FORCE_UNITS_AWAY then
								unit.bNeedsToJump=true
							else
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
	--print("Successfully added " .. #closed .. " closed squares.")
	return vBuildingCenter
end

function BuildingHelper:AddBuilding(building)
	building.bUpdatingHealth = false
	building.nBuildTime = 1
	building.fTimeBuildingCompleted = GameRules:GetGameTime()+1
	building.vOrigin = building:GetAbsOrigin()
	building.nMaxHealth = building:GetMaxHealth()
	building.nHealthInterval = 10
	building.fireEffect="modifier_jakiro_liquid_fire_burn"
	building.bForceUnits = false
	building.fMaxScale=1.0
	building.fCurrentScale = 0.0
	building.bScale=false
	
	for id,unit in pairs(BH_UNITS) do
		if unit.bNeedsToJump then
			--print("jumping")
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			unit.bNeedsToJump=false
		end
	end
	
	-- Work in progress.
	function building:PackWithDummies()
		local d = math.pow(0.5,0.5) + (math.pow(2,0.5) - math.pow(0.5,0.5))/2
	end
	
	function building:SetFireEffect(fireEffect)
		building.fireEffect = fireEffect
	end

	function building:UpdateFireEffect()
		if building.fireEffect == nil then
			print('[Building Helper] Fire effect is nil.')
			return
		end
		if building:GetHealth() <= building:GetMaxHealth()/2 and building.bUpdatingHealth == false then
			if building:HasModifier(building.fireEffect) == false then
				building:AddNewModifier(building, nil, building.fireEffect, nil)
			end
		elseif building:GetHealth() > building:GetMaxHealth()/2 and building:HasModifier(building.fireEffect) then
			building:RemoveModifierByName(building.fireEffect)
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
		local halfSide = (nSize/2.0)*64
		local buildingRect = {leftBorderX = center.x-halfSide, 
			rightBorderX = center.x+halfSide, 
			topBorderY = center.y+halfSide, 
			bottomBorderY = center.y-halfSide}
		local removeCount=0
		for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
			for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
				for v,b in pairs(BUILDING_SQUARES) do
					if v == makeVectorString(Vector(x,y,BH_Z)) then
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
	
	building.BuildingTimerName = DoUniqueString('building')

	Timers:CreateTimer(building.BuildingTimerName, {
    callback = function()
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

			-- clean up the timer if we don't need it.
			if not building.bUpdatingHealth and not building.bScale then
				return nil
			end
		-- not valid ent
		else
			return nil
		end
		
	    return BUILDINGHELPER_THINK
    end})
end

------------------------ UTILITY FUNCTIONS --------------------------------------------

-- use this to give building helper your map's Z. just feed any unit into this. it's just used for
-- debug draw functions.
function BuildingHelper:SetZ(unit)
	BH_Z = unit:GetAbsOrigin().z+1
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

-- Use BuildingHelper:GetZ before using these print funcs.
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

--[[function GameMode:DisplayBuildingGrids()
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