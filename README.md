# Dota 2 Building Helper v2.1

This is an attempt at rewriting most of the Building Helper core to add or improve support for:
* Multiplayer
* Multiple builders building multiple buildings at the same time
* Shift-Queueing (like other RTS games)

## [Installation Guide](https://github.com/snipplets/Dota-2-Building-Helper/wiki/Getting-Started)

# Notes:

* Shift queue behaviour isn't currently "optimal", it still feels somewhat awkward.
* Green building ghosts are only placed on click, rather than mouse move. If Valve expose a way to do client side particles then it'll be added to follow the mouse.
* Camera height changes everything. The numbers in building_helper.js can be tweaked to whatever you need until the mystery of aligning it perfectly to gridnav is solved.

# API Changes

* Minimum BuildingSize is 2. T__'s point_simple_obstruction entity always takes up EXACTLY 2x2 gridnav squares (adjusting its scale didnt' seem to change anything). There doesnt seem to be a better way as yet to do 1x1 blocking.

# Issues

* Snap to grid is currently broken until I can work out how to accuratly align it with the dota gridnav all the time.

# Future

A list of features that'll be added (soon<sup>tm</sup>)

* Add API's to adjust building properties, for example applyPercentageMaxHPModifier(float) for research that's pretty common in TD games where you might increase building health by 20%. Similar methods for armour etc. also flat values like +1000 to max hp.
* Add an UpgradeBuilding API
* Split the file up into 2-3 smaller files, way easier to maintain. Builders probably deserve their own file, the API+init can probably be in one
* Solve the mystery of aligning it with the dota gridnav
* Add 1x1 blockers
