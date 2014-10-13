Dota 2 Building Helper
======================
Building Helper Library for Dota 2 Modding

Author: Myll

timers.lua done by www.github.com/bmddota

Demo: https://www.youtube.com/watch?v=NUuDTq3k18w

How to install: Place buildinghelper.lua in your vscripts and say `require('buildinghelper')` in `addon_game_mode.lua`. Do the same for timers.lua if you don't already have it.

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

**building:RemoveBuilding(nSize, bKill)**

Removes this building from the custom grid.
*nSize:* The size of the building (see above). Must be the same size as when you added the building.

*bKill:* Whether to ForceKill(true) the building or not. The building will also move -200 units in the Z direction. Set to false if you want your own death effects.

**building:UpdateHealth(fBuildTime, bScale, fMaxScale)**
Updates this building's health over the build time.
*bScale:* Whether to add the scaling effect or not.
*fMaxScale:* The max model scale this unit should scale to. Can be anything if bScale is false.

**building:UpdateFireEffect()**
Checks to see if the building needs a fire effect applied (<= 50% health) or taken away (>50% health). A good time to call this would be in the entity_hurt event (when a building takes damage).

**building:SetFireEffect(fireEffect)**
*fireEffect:* The modifier to add when the building's health is below 50%. Default is `modifier_jakiro_liquid_fire_burn`.

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

nMapLength: The map's length on one side. Map must be square shaped.

**BuildingHelper:BlockRectangularArea(leftBorderX, rightBorderX, topBorderY, bottomBorderY)**

Closes squares in a rectangular area. Look at your map in hammer to find values for the parameters.
Ex: BuildingHelper:BlockRectangularArea(-256, 64, 128, -64)
The values must be evenly divisible by 64.

**BuildingHelper:SetForceUnitsAway(bForceAway)**

Whether units should be forced away when a building is built on top of them. If false, buildings can not be built on top of units. Default is false.

Owners of buildings can always build buildings on top of themselves, and they are always forced away.

The bottom of buildinghelper.lua has some interesting utility functions that may be useful.
