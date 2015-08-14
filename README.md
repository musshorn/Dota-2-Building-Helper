# Dota 2 Building Helper v2.1

This is an attempt at rewriting most of the Building Helper core to add or improve support for:
* Multiplayer
* Multiple builders building multiple buildings at the same time
* Shift-Queueing (like other RTS games)

## [Installation Guide](https://github.com/snipplets/Dota-2-Building-Helper/wiki/Getting-Started)

# Notes:

* Shift queue behaviour is broken for queing different units. Still being investigated.

# API Changes

* Minimum BuildingSize is 2. T__'s point_simple_obstruction entity always takes up EXACTLY 2x2 gridnav squares (adjusting its scale didnt' seem to change anything). There doesnt seem to be a better way as yet to do 1x1 blocking.

# Issues

* Waiting for Client Side Gridnav to do red squares or something similar on bad build locations

# Future

A list of features that'll be added (soon<sup>tm</sup>)

* Add API's to adjust building properties, for example applyPercentageMaxHPModifier(float) for research that's pretty common in TD games where you might increase building health by 20%. Similar methods for armour etc. also flat values like +1000 to max hp.
* Add an UpgradeBuilding API
* Split the file up into 2-3 smaller files, way easier to maintain. Builders probably deserve their own file, the API+init can probably be in one
* Add 1x1 blockers
