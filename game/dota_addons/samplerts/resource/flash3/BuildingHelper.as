package {
	import scaleform.gfx.*;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.net.URLRequest;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	import flash.geom.ColorTransform;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	
	public class BuildingHelper extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		public var screenWidth:int;
		
		//change sound to a ui related sound
		private var buildSound:String = "ui.inv_pickup_stone";
		
		//is the player in shift queue
		var shiftQueue:Boolean = false;
			
		//for screen resizing.
		var originalScaleSaved:Boolean = false;
		var originalXScale:Number;
		var originalYScale:Number;
		
		//saves the screen resize, so it can be applied to the matrix.
		var mScaleX:Number;
		var mScaleY:Number;
		
		//scale of the current building
		var buildingScale:Number;
			
		//constructor, you usually will use onLoaded() instead
		public function BuildingHelper() : void {
		}
		
		//this function is called when the UI is loaded
		public function onLoaded() : void {		
			//make this UI visible
			visible = true;
			
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);

			this.gameAPI.SubscribeToGameEvent("build_command_executed", this.onBuildCommandExecuted);

			//this is not needed, but it shows you your UI has loaded (needs 'scaleform_spew 1' in console)
			trace("BuilingHelper UI loaded!");
		}
		
        private function onClickListenerClicked(event) : void {
			var e:MouseEventEx = event as MouseEventEx;
			if (e.buttonIdx == MouseEventEx.LEFT_BUTTON) {
				globals.GameInterface.PlaySound(buildSound);
				this.gameAPI.SendServerCommand("BuildingPosChosen");
				if (!shiftQueue)
				{
					mouseGhost.visible = false;
					this.mouseGhost.removeEventListener(MouseEvent.CLICK, onClickListenerClicked);
					stage.removeEventListener(MouseEvent.MOUSE_MOVE, followMouse);
					globals.GameInterface.RemoveKeyInputConsumer();
				} 				
			}
			else
			{
				this.gameAPI.SendServerCommand("CancelBuilding");
				mouseGhost.visible = false;
				globals.GameInterface.RemoveKeyInputConsumer();
				this.mouseGhost.removeEventListener(MouseEvent.CLICK, onClickListenerClicked);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, followMouse);
				trace("Right click detected.")
			}
        }
		
		
		//handles whether the user is in shift queue
		private function keyDown(e:KeyboardEvent)
		{
			globals.GameInterface.PlaySound(buildSound);
			if(e.keyCode == 16 && !shiftQueue)
			{
				shiftQueue = true;
			}
		}
		
		private function keyUp(e:KeyboardEvent)
		{
			if(e.keyCode == 16 && shiftQueue)
			{
				shiftQueue = false;
			}
		}
		
		private function onBuildCommandExecuted(args:Object) : void {
			globals.GameInterface.PlaySound(buildSound);
			var pID:int = globals.Players.GetLocalPlayer();
			var ghostSize = args.building_size;
			if (args.player_id == pID) {
				globals.GameInterface.AddKeyInputConsumer();
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
				globals.GameInterface.HideCursor();
				stage.addEventListener(MouseEvent.MOUSE_MOVE, followMouse);
				var trans:ColorTransform = new ColorTransform();
				trans.color = 0x00FF00;
				mouseGhost.transform.colorTransform = trans;
				mouseGhost.color = 0x00FF00;
				mouseGhost.visible = true;
				mouseGhost.scaleX = ((ghostSize + 1) * 0.5) * buildingScale;
				mouseGhost.scaleY = ((ghostSize + 1) * 0.5) * buildingScale;
				mouseGhost.x = stage.mouseX;
				mouseGhost.y = stage.mouseY;
				var pos:Array = globals.Game.ScreenXYToWorld(stage.mouseX, stage.mouseY);
				buildingScale = args.building_size - 1;
				this.mouseGhost.addEventListener(MouseEvent.CLICK, onClickListenerClicked);
			}
			else {
				//this.clickListener.visible = false;
			}
        }
		
		public function followMouse(e:MouseEvent)
		{
			var pos:Array = globals.Game.ScreenXYToWorld(stage.mouseX, stage.mouseY);
			
			var mouseZ:Number = (pos[2] / 128);
			var mouseScale = (mouseZ - 2) * 0.5 + 0.5;
			//trace(mouseZ);
			//trace('scale ' + String(mouseScale));
			//trace('result ' + String(mouseZ * mouseScale) * buildingScale));
			var ghostSize = 0.8 + 0.2 * (mouseZ - 1);
			mouseGhost.x = stage.mouseX - mouseGhost.width / 2;
			mouseGhost.y = stage.mouseY - mouseGhost.height / 2;
			
			var skewMatrix:Matrix = new Matrix();
			skewMatrix.tx = mouseGhost.x;
			skewMatrix.ty = mouseGhost.y;
			skewMatrix.a = (ghostSize * mScaleX) * buildingScale;
			skewMatrix.d = (ghostSize * mScaleY) * buildingScale;
			skewMatrix.c = (stage.mouseX - (screenWidth / 2)) / screenWidth;
			mouseGhost.transform.matrix = skewMatrix;
		}
		
		//this handles the resizes - credits to Nullscope & Perry
		public function onResize(re:ResizeManager) : * {
			
			var topBarHeight = (64 * re.ScreenHeight) / 2560;
            var rm = Globals.instance.resizeManager;
            var currentRatio:Number =  re.ScreenWidth / re.ScreenHeight;
            var divided:Number;

            // Set this to your stage height, however, if your assets are too big/small for 1024x768, you can change it
            var originalHeight:Number = 900;
                    
            if(currentRatio < 1.5)
            {
                // 4:3
                divided = currentRatio / 1.333;
            }
            else if(re.Is16by9()){
                // 16:9
                divided = currentRatio / 1.7778;
            } else {
                // 16:10
                divided = currentRatio / 1.6;
            }
                    			
			if(originalScaleSaved == false)
			{
				originalXScale = mouseGhost.scaleX;
				originalYScale = mouseGhost.scaleY;
			}
			
			var correctedRatio:Number =  re.ScreenHeight / originalHeight * divided;
			
			mScaleX = originalXScale * correctedRatio;
			mScaleY = originalYScale * correctedRatio;
					
			screenWidth = re.ScreenWidth;
			//clickListener.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			
		}
	}
}