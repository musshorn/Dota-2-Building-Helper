# Dota 2 Building Helper v2.1

This is an attempt at rewriting most of the Building Helper core to add or improve support for:
* Multiplayer
* Multiple builders building multiple buildings at the same time
* Shift-Queueing (like RTS games)

Be aware that this removes all of the particle code due to it's aweful performance in multiplayer. Instead the green square is done in flash and uses some spooky math to look like it's in the 3d game world and not just sitting on the screen. 
As a result, the building model following the mouse was also lost, currently not aware of a good way to generate these in flash. The particle for it is drawn on click though.

If you want the current actually functional Building Helper, go here. [Building-Helper](https://github.com/Myll/Dota-2-Building-Helper). This fork was written specifically to solve the issues detailed above.

# Notes:

The core of the code has been restructured so that each builder owns a queue of current work for them, and they process the work from their queue. Also now using T__'s [fantastic Gridnav implementation](https://moddota.com/forums/discussion/comment/731/#Comment_731). 

API Changes
* Added onConstructionCancelled for when a player right clicks while buildings are shift queued, this is called once for each building cancelled
* Added onConstructionFailed for when a building can no longer be placed on that gridnav square
* Minimum BuildingSize is 2. T__'s point_simple_obstruction entity always takes up EXACTLY 2x2 gridnav squares (adjusting its scale didnt' seem to change anything)

# Future

A list of dreamboat features that could be added

* Add API's to adjust building properties, for example applyPercentageMaxHPModifier(float) for research that's pretty common in TD games where you might increase building health by 20%. Similar methods for armour etc. also flat values like +1000 to max hp.
* Split the file up into 2-3 smaller files, way easier to maintain. Builders probably deserve their own file, the API+init can probably be in one
* Solve the mystery of aligning it with the dota gridnav, also add 1x1 blockers
* Come up with a better mapping of the 3d world to a 2d shape in flash, add the models in flash

# Blog
Update 21/4:
* First "Viable" release
  - Shift-queue implemented
  - Should work in multiplayer, untested
  - Multiple builders building multiple buildings at the same time

Update 22/4:
* Bugfix edition
  - Flash now "snaps to grid", Only problem is that it's not the dota gridnav grid and I'm not sure if it even can be
  - Fixed flash square scaling and adjusted magic numbers to make it feel more real
  - Fixed odd sized buildings not snapping correctly
  - Fixed building scaling being off in some cases
  - Fixed ghost particles not being removed correctly in some cases

Update 23/4:
* Probably a final version
  - Few more bugs fixed with gridnav. No 1x1 point obstruction means the smallest building size has to be 2
