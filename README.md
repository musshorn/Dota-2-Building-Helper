Dota-2-Building-Helper
======================

Building Helper Library for Dota 2 Modding

Author: Myll

Demo: https://www.youtube.com/watch?v=NUuDTq3k18w

How to install: Place buildinghelper.lua in your vscripts and say `require('buildinghelper')` in `addon_game_mode.lua`. If you got a seperate lua file, like buildings.lua and you're calling these functions in it, put a require in there too.

**(1) BuildingHelper:AddBuildingToGrid(vPoint, nSize, vOwnersHero)**

Adds a new building to the custom grid given the target point, the size, and the owner's hero.

*vPoint*: The raw point where the user wants to place the building.

*nSize:* Length of 1 side of the building. Buildings must be square shaped. Example: nSize=2 would be 2x64 units. So, the building covers (2x64) by (2x64) units, or a total of 4 squares.

*vOwnersHero:* The hero which owns this building.

Returns -1 if a building can't be built at the location.

**(2) BuildingHelper:AddBuilding(building)**

*building:* The unit entity representing this building.

Sub-functions of (2):

**RemoveBuilding(nSize, bKill)**

Removes this building from the custom grid.
*nSize:* The size of the building (see above). Must be the same size as when you added the building.

*bKill:* Whether to ForceKill(true) the building or not. The building will also move -200 units in the Z direction. Set to false if you want your own death effects.

**SetOwner(vOwner)**

Sets the owner of this building (a hero).

**GetOwner()**

Returns the owner of this building (a hero).

**UpdateHealth(fBuildTime, bScale, fMaxScale)**
Updates this building's health over the build time.
*bScale:* Whether to add the scaling effect or not.
*fMaxScale:* The max model scale this unit should scale to. Can be anything if bScale is false.

**SetFireEffect(fireEffect)**
*fireEffect:* The modifier to add when the building's health is below 50%. Default is `modifier_jakiro_liquid_fire_burn`. Set to nil to have no effect.


**GetFireEffect()**
Return the building's fire effect if it's not nil.

**(3) BuildingHelper:AddUnit(unit)**

Adds functionality to unit interactions with buildings.

Sub-functions of (3):

**GeneratePathingMap()**

Generates a pathing map for this unit. Primarily used to determine if a unit is interfering with building placement. Returns table full of center points of squares which the unit occupies.

**SetCustomRadius(nRadius)**

Sets a custom radius which will be used for determining the pathing map for a unit. Default is set to the unit's hull radius.

**GetCustomRadius()**

Returns the custom radius which will be used for determining the pathing map for a unit.

**BuildingHelper:BlockGridNavSquares(nMapLength)**

Adds the squares blocked by the GridNav to the custom grid's blocked squares. This means buildings can't be placed on squares blocked by the GridNav. Not called by default.

nMapLength: The map's length on one side. Map must be square shaped.

**BuildingHelper:IsRectangularAreaBlocked(boundingRect)**
Returns whether this rectangular area contains a blocked square (bool).

**BuildingHelper:SetForceUnitsAway(bForceAway)**

Whether units should be forced away when a building is built on top of them. If false, buildings can not be built on top of units. Default is false.

Owners of buildings can always build buildings on top of themselves, and they are always forced away.

Other functions:

*BuildingHelper:PrintSquareFromCenterPoint(v)*

*BuildingHelper:PrintSquareFromCenterPointShort(v)*

*YourGameMode:DisplayBuildingGrids()*

*snapToGrid64(coord)*

Snaps a coordinate to the 64-resolution grid.

*snapToGrid32(coord)*

Snaps a coordinate to the 32-resolution grid, but not the 64 grid.

*makeBoundingRect(leftBorderX, rightBorderX, topBorderY, bottomBorderY)*

*tableContains(list, element)*

Return true if the table contains this element, returns false otherwise.
