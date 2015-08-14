'use strict';

var state = 'disabled';
var size = 0;
var pressedShift = false;

var particle;


function SnapToGrid64(coord){
  return 64*Math.floor(0.5+coord/64);
}

function SnapToGrid32(coord){
  return 32+64*Math.floor(coord/64);
}


function StartBuildingHelper( params )
{
  if (params !== undefined)
  {
    var entIndex = params["entIndex"];
    var MaxScale = params["MaxScale"];
    var player = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
    state = params["state"];
    size = params["size"];
    pressedShift = GameUI.IsShiftDown();
    
    if (particle !== undefined) {
      Particles.DestroyParticleEffect(particle, true)
    }

    $("#BuildingHelperBase").hittest = true;

    particle = Particles.CreateParticle("particles/buildinghelper/ghost_model.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN, player);
    Particles.SetParticleControlEnt(particle, 1, entIndex, ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, "follow_origin", Entities.GetAbsOrigin(entIndex), true);
    Particles.SetParticleControl(particle, 3, [100,0,0]);
    Particles.SetParticleControl(particle, 4, [MaxScale,0,0]);
  }
  if (state === 'active')
  {
    $.Schedule(0.001, StartBuildingHelper);
    var mPos = GameUI.GetCursorPosition();
    var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);

    if (size % 2 != 0) {
      GamePos[0] = SnapToGrid32(GamePos[0]);
      GamePos[1] = SnapToGrid32(GamePos[1]);
    } else {
      GamePos[0] = SnapToGrid64(GamePos[0]);
      GamePos[1] = SnapToGrid64(GamePos[1]);
    }

    if (GamePos[0] > 10000000) // fix for borderless windowed players
    {
      GamePos = [0,0,0];
    }

    Particles.SetParticleControl(particle, 0, [GamePos[0], GamePos[1], GamePos[2] + 1]); // #JustValveThings
    Particles.SetParticleControl(particle, 2, [0,255,0]);

    if ((!GameUI.IsShiftDown() && pressedShift))
    {
      EndBuildingHelper();
    }
  }
}

function EndBuildingHelper()
{
  $("#BuildingHelperBase").hittest = false;
  if (particle !== undefined) {
    Particles.DestroyParticleEffect(particle, true)
  }
  state = 'disabled'
}

function SendBuildCommand( params )
{
  var mPos = GameUI.GetCursorPosition();
  var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
  GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] } );
  pressedShift = GameUI.IsShiftDown();
  if (!GameUI.IsShiftDown()) // Remove the green square unless the player is holding shift
  {
    EndBuildingHelper();
  }
}

function SendCancelCommand( params )
{
  EndBuildingHelper();
  GameEvents.SendCustomGameEventToServer( "building_helper_cancel_command", {} );
}

(function () {
  GameEvents.Subscribe( "building_helper_enable", StartBuildingHelper);
})();