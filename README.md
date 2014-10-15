Dota 2 Building Helper
======================
Building Helper Library for Dota 2 Modding

Author: Myll

timers.lua done by https://github.com/bmddota and https://github.com/ash47

Demo: https://www.youtube.com/watch?v=NUuDTq3k18w

How to install: 

1. Place buildinghelper.lua in your vscripts and say `require('buildinghelper')` in `addon_game_mode.lua`. Do the same for timers.lua if you don't already have it.

2. Merge ```npc_abilties_custom.txt``` and ```npc_units_custom.txt``` with your own.

v0.5 Changelog (10/14/14):

1. Added circle-packing to buildings. See building:Pack() below.

2. RemoveBuilding no longer requires the building size.

3. GeneratePathingMap is no longer used by default. Building owners will always try to find clear space whenever they build a building. GeneratePathingMap was mainly for checking if building placement was blocked by units. It's inefficient atm, and most tower defense games don't need to check if units are in the way (other than the owner). You can have the old way back with BuildingHelper:UsePathingMap(true).

4. Library is overall more efficient. Timers will remove themselves when not needed.

Most useful functions:

**(1) BuildingHelper:AddBuildingToGrid(vPoint, nSize, hOwnersHero)**

Adds a new building to the custom grid given the target point, the size, and the owner's hero.

*vPoint*: The raw point where the user wants to place the building.

*nSize:* Length of 1 side of the building. Buildings must be square shaped. Example: nSize=2 would be 2x64 units. So, the building covers (2x64) by (2x64) units, or a total of 4 squares.

*hOwnersHero:* The hero that owns this building.

Returns -1 if a building can't be built at the location.

**(2) BuildingHelper:AddBuilding(building)**
*building:* The unit entity representing this building.

Sub-functions of (2):

**building:RemoveBuilding(bKill)**
Removes this building from the custom grid.

*bKill:* Whether to ForceKill(true) the building or not. The building will also move -200 units in the Z direction. Set to false if you want your own death effects.

**building:UpdateHealth(fBuildTime, bScale, fMaxScale)**
Updates this building's health over the build time.

*bScale:* Whether to add the scaling effect or not.

*fMaxScale:* The max model scale this unit should scale to. Can be anything if bScale is false.

**building:Pack()**
Places an invisible dummy unit on each corner of the building. Useful when you want units to path around buildings rectangularly. The hull radii are adjusted accordingly. Ex:
![](http://i.imgur.com/FeSsHLE.jpg)

**building:SetFireEffect(fireEffect)**
*fireEffect:* The modifier to add when the building's health is below 50%. The modifier will remove itself if the building's health goes over 50% again. Default is `modifier_jakiro_liquid_fire_burn`. Set to nil to disable.

**(3) BuildingHelper:AddUnit(unit)**

Adds a unit to the check-list of the helper.

Sub-functions of (3):

**unit:RemoveUnit()**

Removes the unit from the check-list of the helper.

**unit:GeneratePathingMap()**

Generates a pathing map for this unit. Primarily used to determine if a unit is interfering with building placement. Returns table full of center points of squares which the unit occupies.

**BuildingHelper:AddPlayerHeroes()**

Adds all player hero's to the check-list of the helper.

**BuildingHelper:BlockGridNavSquares(nMapLength)**

Adds the squares blocked by the GridNav to the custom grid's blocked squares. This means buildings can't be placed on squares blocked by the GridNav. Not called by default.

nMapLength: The map's length on one side. If you're using the tile editor it's 16384.

**BuildingHelper:AutoSetHull(bAutoSetHull)**
Whether to automatically adjust building's hull radii when AddBuilding is called. The hull radius adjusts according to the building's size. Default is true. Will always adjust if a building is packed.

**BuildingHelper:SetPacking(bPacking)**
Whether to automatically pack buildings. Default is false.

**BuildingHelper:UsePathingMap(bUsePathingMap)**
Whether to check if units are in the way before placing buildings (other than the owner). This is inefficient atm. Default is false.

**BuildingHelper:BlockRectangularArea(leftBorderX, rightBorderX, topBorderY, bottomBorderY)**
Closes squares in a rectangular area. Look at your map in hammer to find values for the parameters. Ex: BuildingHelper:BlockRectangularArea(-256, 64, 128, -64)
The values must be evenly divisible by 64.

**BuildingHelper:SetForceUnitsAway(bForceAway)**

Whether units should be forced away when a building is built on top of them. If false, buildings can not be built on top of units. Default is false.

Owners of buildings can always build buildings on top of themselves, and they are always forced away.

The bottom of buildinghelper.lua has some interesting utility functions that may be useful.
