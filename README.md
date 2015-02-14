# Dota 2 Building Helper v2.0

I'm pleased to announce that BuildingHelper has been completely revamped. It now includes RTS-style building ghost, and the library is overall more customizeable and simpler.

## Installation

Since BuildingHelper (BH) now has various components in many different locations, I thought the best way to convey the installation information would be to make this repo contain a sample RTS-style addon. You can literally just merge these game and content folders into your `dota 2 beta/dota_ugc` folder, compile the map in Hammer, and you can see BH in action. I will of course still explain essential installation info in this section.

**Note:** BuildingHelper is only compatible with square-shaped maps that are centered at x=0,y=0.

**Add these files to your own addon:**
* `game/dota_addons/samplerts/scripts/vscripts/buildinghelper.lua`
* `game/dota_addons/samplerts/scripts/vscripts/FlashUtil.lua`
* `game/dota_addons/samplerts/scripts/vscripts/abilities.lua`
* `game/dota_addons/samplerts/resource/flash3/FlashUtil.swf`
* `game/dota_addons/samplerts/resource/flash3/CustomError.swf`
* `game/dota_addons/samplerts/resource/flash3/BuildingHelper.swf`

**Merge these files with your own addon:**
* `game/dota_addons/samplerts/scripts/custom_events.txt`
In `game/dota_addons/samplerts/scripts/npc/npc_abilities_custom.txt`, only the abilities that start with `move_to_point_` are required. These abilities are explained more in the "Usage" section.
* `game/dota_addons/samplerts/resource/flash3/custom_ui.txt`

**Add these contents to addon_game_mode.lua:**
```
require('util.lua')
require('timers.lua')
require('physics.lua')
require('FlashUtil.lua')
require('buildinghelper.lua')
require('abilities.lua')
PrecacheResource("particle_folder", "particles/buildinghelper", context)
```
BH requires some snippets of code in game event functions. See SampleRTS.lua and CTRL+F "BH Snippet".

See [addon_game_mode.lua]() for reference. It uses a function to require files which I recommend for your addon.

## Usage

Somewhere at the start of your addon you would call `BuildingHelper:Init(nHalfMapLength), where nHalfMapLength is half the length of one side of your map. So you would get this value by scrolling really really close on a corner of your map in Hammer, and then taking the abs value of one the coordinates. For example, if you're using the Tile Editor and haven't changed the map size, the value will be 8192.

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
	"AbilityCastRange"				"200"
	"UpdateHealth"					"1" //bool
	"Scale"							"1" //bool
	"MaxScale"						"1.3"
	"CasterCanControl"				"1" //bool. This will automatically run SetControllableByPlayer and let the caster of this ability to control the building.
	//"CancelsBuildingGhost"			"0" //bool
	// Note: if unit uses a npc_dota_hero baseclass, you must use the npc_dota_hero name.
	"UnitName"						"npc_dota_hero_drow_ranger"
	"AbilityCooldown"				"3"
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

Regarding the `move_to_point_` abilities: You can see we have `AbilityCastRange` defined but the `AbilityBehavior` is `"DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE"`. To the game logic, `AbilityCastRange` does nothing, but BH takes this value and will try to find an associated `move_to_point_` ability. So if you have a building ability with `"AbilityCastRange"  "122"`, you must have a `move_to_point_122` ability or else BH will default it to `move_to_point_100`. These are abilities are necessary for the building caster to walk a distance before being able to build the building.

One more important thing: By default, BH will cancel a building ghost if it detects the caster used another ability during the ghost. To make BH ignore abilities (i.e. not cancel the ghost) you can add the KV `"CancelsBuildingGhost"	"0"` to any ability or item. In this repo, the ability `example_ability` has this KV and thus will not cancel building ghost when it's executed.

In abilities.lua, we have the build function defined. It'll look simply like this:
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
	-- It will turn off it building goes above 50% health again.
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end
```
This really highlights BH's new simplicity and customizability, and is pretty self explanatory. BH handles the complicated stuff in the background, and gives you an easy to use front end interface. You can see all the callbacks BH provides you with in the build function in abilities.lua.

If you need help I can be reached on irc.gamesurge.net #dota2modhelpdesk or you can [create an issue](https://github.com/Myll/Dota-2-Building-Helper/issues/new).

[**Known issues**](https://github.com/Myll/Dota-2-Building-Helper/issues)

## Contributing

Contributing to this repo is absolutely welcomed. Building Helper's goal is to make Dota 2 a more compatible platform to create RTS-style and Tower Defense mods. It will take a community effort to achieve this goal, not just me.

## Credits

[Perry](https://github.com/perryvw): FlashUtil, which contains functions for cursor tracking. Also helped with making the building unit model into a particle.

[BMD](https://github.com/bmddota): Helped figure out how to get mouse clicks in Flash. Made the particles in BH.

[zedor](https://github.com/zedor/CustomError): Custom error in Flash.

## Notes

If you're a new modder I highly recommend forking a new starter addon using my [D2ModKit](https://github.com/Myll/Dota-2-ModKit) program.

Want to donate to me? That's really nice of you. Here you go:

[![alt text](http://indigoprogram.org/wp-content/uploads/2012/01/Paypal-Donate-Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=stephenf%2ebme%40gmail%2ecom&lc=US&item_name=Myll%27s%20Dota%202%20Modding%20Contributions&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

## License

Building Helper is licensed under the GNU General Public license. If you use Building Helper in your mod, please state so in your credits.