# Dota 2 Building Helper v2.0

I'm pleased to announce that BuildingHelper has been completely revamped. It now includes RTS-style building ghost, and the library is overall more customizeable and simpler.

[Gfy Demo](http://gfycat.com/SpecificSkeletalCowbird)

## Installation

Since BuildingHelper (BH) now has various components in many different locations, I thought the best way to convey the installation information would be to make this repo contain a sample RTS-style addon. You can literally just merge these game and content folders into your `dota 2 beta/dota_ugc` folder, compile the map in Hammer, and you can see BH in action. I will of course still explain essential installation info in this section.

**Add these files to your own addon:**
* `game/dota_addons/samplerts/scripts/vscripts/buildinghelper.lua`
* `game/dota_addons/samplerts/scripts/vscripts/FlashUtil.lua`
* `game/dota_addons/samplerts/scripts/vscripts/timers.lua`
* `game/dota_addons/samplerts/scripts/vscripts/abilities.lua`
* `game/dota_addons/samplerts/resource/flash3/FlashUtil.swf`
* `game/dota_addons/samplerts/resource/flash3/CustomError.swf`
* `game/dota_addons/samplerts/resource/flash3/BuildingHelper.swf`
* `game/dota_addons/samplerts/particles/buildinghelper`
* `content/dota_addons/samplerts/particles/buildinghelper`

**Merge these files with your own addon:**
* `game/dota_addons/samplerts/scripts/custom_events.txt`
* `game/dota_addons/samplerts/resource/flash3/custom_ui.txt`

In `game/dota_addons/samplerts/scripts/npc/npc_abilities_custom.txt`, all of abilities between `START OF BUILDING HELPER ABILITIES` and `END OF BUILDING HELPER ABILITIES` are necessary.

In `game/dota_addons/samplerts/scripts/npc/npc_units_custom.txt`, the `npc_bh_dummy` unit is needed.

**Add these contents to addon_game_mode.lua:**
```
require('timers')
require('physics')
require('FlashUtil')
require('buildinghelper')
require('abilities')
PrecacheResource("particle_folder", "particles/buildinghelper", context)
```
BH requires some snippets of code in game event functions. See [SampleRTS.lua](https://github.com/Myll/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/samplerts.lua) and CTRL+F "BH Snippet".

See [addon_game_mode.lua](https://github.com/Myll/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/addon_game_mode.lua) for reference. It uses a function to require files which I recommend for your addon.

## Usage

Somewhere at the start of your addon you would call `BuildingHelper:Init(nHalfMapLength)`. In SampleRTS, it's called [here](https://github.com/Myll/Dota-2-Building-Helper/blob/myll/game/dota_addons/samplerts/scripts/vscripts/samplerts.lua#L624). The parameter nHalfMapLength is optional, but recommended, as it decreases the memory usage of BH. This picture explains how to get nHalfMapLength:

![](http://i.imgur.com/FpbxQAs.png)

For maps using the tile editor, nHalfMapLength=8192 is good.

Using BH is really easy compared to previous versions. The new BH is very KV-oriented. For example, the following ability would be parsed as a BH building:
```
"build_arrow_tower"
{
	"AbilityBehavior"				"DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE"
	"BaseClass"						"ability_datadriven"
	"AbilityTextureName"			"build_arrow_tower"
	"AbilityCastAnimation"			"ACT_DOTA_DISABLED"
	// BuildingHelper info
	"Building"						"1" //bool
	"BuildingSize"					"3" // this is (3x64) by (3x64) units, so 9 squares.
	"BuildTime"						"2.0"
	"AbilityCastRange"				"100"
	"UpdateHealth"					"1" //bool
	"Scale"							"1" //bool
	"MaxScale"						"1.3"
	"PlayerCanControl"				"1" //bool. Should the player issuing this build command be able to control the building once built?
	//"CancelsBuildingGhost"			"0" //bool
	// Note: if unit uses a npc_dota_hero baseclass, you must use the npc_dota_hero name.
	"UnitName"						"npc_dota_hero_drow_ranger"
	"AbilityCooldown"				"0"
	"AbilityGoldCost"				"10"
	// End of BuildingHelper info

	"AbilityCastPoint"				"0.0"
	"MaxLevel"						"1"

	// Item Info
	//-------------------------------------------------------------------------------------------------------------
	"AbilityManaCost"				"0"
	
	"OnSpellStart"
	{
		"RunScript"
		{
			"ScriptFile"			"scripts/vscripts/abilities.lua"
			"Function"				"build"
		}
	}
}
```
BH handles cooldowns and gold costs nicely for you. It won't charge the player the cost until he successfully places the building, nor start the cooldown either.

Regarding the `move_to_point_` abilities: You can see we have `AbilityCastRange` defined but the `AbilityBehavior` is `"DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE"`. To the game logic, `AbilityCastRange` does nothing, but BH takes this value and will try to find an associated `move_to_point_` ability. So if you have a building ability with `"AbilityCastRange"  "122"`, you must have a `move_to_point_122` ability or else BH will default it to `move_to_point_100`. These abilities are necessary for the building caster to walk a distance before being able to build the building.

One more important thing: By default, BH will cancel a building ghost if it detects the caster used another ability during the ghost. To make BH ignore abilities (i.e. not cancel the ghost) you can add the KV `"CancelsBuildingGhost"	"0"` to any ability or item. In this repo, the [example_ability](https://github.com/Myll/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/npc/npc_abilities_custom.txt#L89-L264) has this KV and thus will not cancel building ghost when it's executed.

Now onto the lua component of the front-end: In abilities.lua, we have the build function defined. It'll look simply like this:
```
function build( keys )
	BuildingHelper:AddBuilding(keys)
	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound
		-- FindClearSpace for the builder
	end)
	keys:OnConstructionCompleted(function(unit)
		print("Completed construction of " .. unit:GetUnitName())
		-- Play construction complete sound.
		-- Give building its abilities
	end)
	-- Have a fire effect when the building goes below 50% health.
	-- It will turn off if building goes above 50% health again.
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end
```
This really highlights BH's new simplicity and customizability, and is pretty self explanatory. BH handles the complicated stuff in the background, and gives you an easy to use front end interface. You can see all the callbacks BH provides you with in the [build function](https://github.com/Myll/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/abilities.lua#L1-L32).

#### Grid and Model Ghost options

In buildinghelper.lua, you will find these 4 variables to control the properties of the ghost particles.

* GRID_ALPHA: Transparency of the green/red grid.
* MODEL_ALPHA: Transparency of the ghost model
* RECOLOR_GHOST_MODEL: Choose between displaying the original colors of the building model, or green/red:
  
![img](http://puu.sh/g8p9y/ff0863ad95.jpg)

The grid will still turn red, with or without recoloring the ghost model:

![img](http://puu.sh/g8pXj/b26f519783.jpg)

* USE_PROJECTED_GRID: If you are using less than 100 on MODEL_ALPHA, enable this for the grid to be projected under the building:
  
![img](http://puu.sh/g8oea/8a50dd1418.jpg)

If you need help I can be reached on irc.gamesurge.net #dota2modhelpdesk or you can [create an issue](https://github.com/Myll/Dota-2-Building-Helper/issues/new).

[**Known issues**](https://github.com/Myll/Dota-2-Building-Helper/issues)

## Contributing

Contributing to this repo is absolutely welcomed. Building Helper's goal is to make Dota 2 a more compatible platform to create RTS-style and Tower Defense mods. It will take a community effort to achieve this goal, not just me.

## Credits

[Perry](https://github.com/perryvw): FlashUtil, which contains functions for cursor tracking. Also helped with making the building unit model into a particle.

[BMD](https://github.com/bmddota): Helped figure out how to get mouse clicks in Flash. Made the particles in BH.

[zedor](https://github.com/zedor/CustomError): Custom error in Flash.

[Noya](https://github.com/MNoya): Testing, ideas, building queue (soon to come)

## Notes

If you're a new modder I highly recommend forking a new starter addon using my [D2ModKit](https://github.com/Myll/Dota-2-ModKit) program.

Want to donate to me? That's really nice of you. Here you go:

[![alt text](http://indigoprogram.org/wp-content/uploads/2012/01/Paypal-Donate-Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=stephenf%2ebme%40gmail%2ecom&lc=US&item_name=Myll%27s%20Dota%202%20Modding%20Contributions&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

## License

Building Helper is licensed under the GNU General Public license. If you use Building Helper in your mod, please state so in your credits.
