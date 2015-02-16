# DOTA2建造模块V2.0

本模块作者为[Myll](https://github.com/Myll)，该说明由[XavierCHN](https://github.com/XavierCHN)汉化。

这个版本的建造模块，比上个版本，改进了整个的实现方式，在按下建造按钮的时候，将会显示虚拟的建筑样式，并对整个库的使用进行了简化。

[Gfy 的演示视频地址](http://gfycat.com/SpecificSkeletalCowbird)

## 安装使用

因为现在，本模块已经拥有了太多地方的修改，因此，如果你希望制作一个RTS类型的东西，你最好直接下载这个项目，把game和contents中的`dota_addons\samplerts`文件夹改名为你自己的addon文件夹，如`dota_addons\your_rts_addon`，然后直接覆盖这个文件夹到`dota_ugc`文件夹中，当然，如果你希望手动添加，那么你需要做如下操作：

**把这些文件添加到你的addon中:**
* `game/dota_addons/samplerts/scripts/vscripts/buildinghelper.lua`
* `game/dota_addons/samplerts/scripts/vscripts/FlashUtil.lua`
* `game/dota_addons/samplerts/scripts/vscripts/abilities.lua`
* `game/dota_addons/samplerts/resource/flash3/FlashUtil.swf`
* `game/dota_addons/samplerts/resource/flash3/CustomError.swf`
* `game/dota_addons/samplerts/resource/flash3/BuildingHelper.swf`
* `game/dota_addons/samplerts/particles/buildinghelper`
* `content/dota_addons/samplerts/particles/buildinghelper`

**把这些文件合并到你的addon中:**
* `game/dota_addons/samplerts/scripts/custom_events.txt`
* `game/dota_addons/samplerts/resource/flash3/custom_ui.txt`

在 `game/dota_addons/samplerts/scripts/npc/npc_abilities_custom.txt` 这个文件中，只有以`move_to_point`开头的技能必须要被合并的，这些技能将会在`"Usage"`部分做进一步的说明。

**将这些代码加入到你的addon_game_mode.lua中:**
```
require('timers.lua')
require('physics.lua')
require('FlashUtil.lua')
require('buildinghelper.lua')
require('abilities.lua')
PrecacheResource("particle_folder", "particles/buildinghelper", context)
```

这个模块同样的，需要一些特定的部分，你可以在[SampleRTS.lua](https://github.com/XavierCHN/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/samplerts.lua) 这个文件中查找BH Snippets这个关键字，那些部分是必须的（主要是为了进行初始化，同时在使用另一个技能的时候，要清除掉当前技能产生的虚影）.

你也可以看看 [addon_game_mode.lua](https://github.com/XavierCHN/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/addon_game_mode.lua) 这里面的东西，这里面的那些函数，是推荐使用的函数。

## 使用方法

在你的addon中，在你开始使用本模块中的功能之前，你必须先使用这个函数： `BuildingHelper:Init(nHalfMapLength)`. 在本范例中，他在 [这里](https://github.com/Myll/Dota-2-Building-Helper/blob/myll/game/dota_addons/samplerts/scripts/vscripts/samplerts.lua#L624) 被调用了， 下面这张图解释了如何获取 nHalfMapLength 这个变量的数值:

![](http://i.imgur.com/FpbxQAs.png)

如果你使用的是TileEdito自动生成的地形并没有改变大小，那么nHalfMapLength=8192。

当然，要注意，你设置的nHalfMapLength，应该是64的倍数。

在这个版本中，BH模块主要是基于KV模块，很少需要做Lua程序方面的工作，例如以下的代码
这些部分，Lua代码将会被本模块自动检索。

```
"build_arrow_tower"//技能：建造箭塔
{
	"AbilityBehavior"				"DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE"
	"BaseClass"						"ability_datadriven"//技能基类，只能是这个
	"AbilityTextureName"			"build_arrow_tower"//技能图标名称，根据8.png文件来。
	"AbilityCastAnimation"			"ACT_DOTA_DISABLED"
	// 模块所需要使用的参数
	"Building"						"1" //判定是否一个建造技能
	"BuildingSize"					"3" // 这个参数设置了所建造建筑的体积，这里的意思是3*3，也就是192(64*3)*192大小的一个建筑
	"BuildTime"						"2.0"//建造时间
	"AbilityCastRange"				"200"//技能释放范围
	"UpdateHealth"					"1" //是否在建造的时候同时增长血量
	"Scale"							"1" //是否在建造的时候，随着建造进程改变建筑大小
	"MaxScale"						"1.3"//最大体积
	"PlayerCanControl"				"1" //1或者0，这个决定的是，建造者建造完成之后是否可以控制那个建筑。
	//"CancelsBuildingGhost"			"0" //不显示建造的虚像（存疑，待我看完Lua代码）
	// 提示，下面这个UnitName，如果是一英雄，那么应该是使用英雄的基础名称
	"UnitName"						"npc_dota_hero_drow_ranger"
	"AbilityCooldown"				"3"//技能冷却时间
	"AbilityGoldCost"				"10"//技能的金钱消耗
	// 模块需要使用的参数，结束

	"AbilityCastPoint"				"0.0" // 建造技能的前摇，一般都设置为0
	"MaxLevel"						"1" // 技能的最大等级一般都是为1

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

本模将会处理好关于冷却时间和金钱消耗的部分的内容，如果没有成功安放建筑，将不会扣钱，也不会扣蓝，也不会将技能进冷却时间

关于那个 `move_to_point_` （移动到某个点的技能）你可以看到我们在上面按个技能中，定义了一个技能的施法范围`AbilityCastRange`，和一个技能类型`AbilityBehavior` : `"DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_IMMEDIATE"`，对于游戏来讲，施法距离并没有什么用，但是，如果你使用了一个施法范围为122的建造技能，那么，你同时需要做一个`move_to_point_122`的技能，否则，模块将会自动使用`move_to_point_100`这个技能，模块需要这个技能是因为，在某个点建造建筑之前，模块将会使用这个技能，要求建造者先走到距离为AbilityCastRange距离的位置，再开始建造过程。

一个更重要的事情是，本模块，在建造者使用另一个技能，或者说，以任何方式取消建造的时候，建筑将会消失。如果你不希望这种类型的建造者建造的建筑小时，你可以在技能中将`CancelsBuildingGhost`设置为`"0"`，如果设置为0之后，这个建筑在建造者取消的时候，将会继续进行建造。

接下来让我看看Lua代码的部分，之需要简单地做如下的操作。
```
function build( keys )
	BuildingHelper:AddBuilding(keys)
	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- 这个函数是在建造开始的时候的回调
		-- unit这个变量，储存的就是所建造的那个单位
		-- 如果你需要播放建造声音，也可以在这个地方建造
		-- 建造开始的时候，你可能会需要移动一下建造者，来避免建造者卡住。也在这里进行这个操作
	end)
	keys:OnConstructionCompleted(function(unit)
		print("Completed construction of " .. unit:GetUnitName())
		-- 这个函数是建造完成时候的回调
		-- 你可以在这里对建筑进行一系列的处理，BlahBlah
	end)
	-- 使用这个函数，可以定义，在这个建筑的血量低于50%的时候，将会附加的粒子特效modifier
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end
```

你可以在 [build 函数](https://github.com/Myll/Dota-2-Building-Helper/blob/master/game/dota_addons/samplerts/scripts/vscripts/abilities.lua#L1-L32) 的这些位置，看到关于可以使用的回调.

如果你需要帮助，你可以在 irc.gamesurge.net #dota2modhelpdesk （irc）频道来咨询，当然，也可以在 [这个位置](https://github.com/Myll/Dota-2-Building-Helper/issues/new) 创建一个新的.

[**已知存在的问题**](https://github.com/Myll/Dota-2-Building-Helper/issues)

## 欢迎贡献代码

贡献的代码将会是非常欢迎的，这个模块的目标是，给予DOTA2制作RTS模式和TD模式游戏的能力，我希望是整个制作者团体都可以来一起完成这个目标。

## 感谢

[Perry](https://github.com/perryvw): Flash工具，包含鼠标位置追踪同时帮助把单位的模型放入粒子特效中。

[BMD](https://github.com/bmddota): 帮助解决了如何在Flash中获取鼠标点击的问题，同时帮助制作了粒子特效

[zedor](https://github.com/zedor/CustomError): 他的错误显示模块。

## 说明

如果你是一个新手，那么建议你可以使用我的 [D2ModKit](https://github.com/Myll/Dota-2-ModKit) 来创建你的新模式。

如果你希望能够捐赠给Myll，这是他的链接

[![alt text](http://indigoprogram.org/wp-content/uploads/2012/01/Paypal-Donate-Button.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=stephenf%2ebme%40gmail%2ecom&lc=US&item_name=Myll%27s%20Dota%202%20Modding%20Contributions&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

## 许可

BH使用GNU许可，如果你在你的Mod中使用了BH，请在你的致谢中说明这一点。
