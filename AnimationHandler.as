package {
	// AnimationHandler takes care of animating Entities. You add animations
	// with addAnimations(), turn one on with setAnimation(),  and Entity will
	// take care of the rest.

	public class AnimationHandler {
		private var animations:Object = {};

		private var currentAnimation:String = "";
		private var currentFrame:int = 0;
		private var currentTick:int = 0;
		private var ticksPerFrame:int = 10;
		private var ent:Entity;
		private var _hasAnyAnimations:Boolean = false;

		function AnimationHandler(s:Entity) {
			currentAnimation = "default";
			this.ent = s;
		}

		// TODO: Bad naming
		public function hasAnyAnimations():Boolean {
			return _hasAnyAnimations;
		}

		// We assume that you hold y is constant, with numFrames frames starting at x.

		public function addAnimation(name:String, frameX:int, frameY:int, numFrames:int):void {
			var frames:Array = [];

			for (var i:int = 0; i < numFrames; i++) {
				frames.push(frameX + i);
			}

			animations[name] = { "frames": frames, "y": frameY };
			_hasAnyAnimations = true;
		}

		public function toString():String {
			return "[Animation " + currentAnimation + " " + currentFrame + "]";
		}

		// In case addAnimation() isn't good enough, you can just use an array
		// to specify x positions of frames.

		public function addAnimationArray(name:String, frames:Array, frameY:int):void {
			animations[name] = { "frames": frames, "y": frameY };
			_hasAnyAnimations = true;
		}

		public function deleteAnimation(name:String):void {
			delete animations[name];
		}

	    /* Convenient function for adding many animations simultaneously.

	    addAnimations({ "walk": {startPos: [0, 0], numFrames: 4 }
	                  , "die" : {startPos: [4, 0], numFrames: 4 }
	                  , "hurt": {array: [1, 3, 5], y: 0}
	                  });

	    "start" is the starting x and y position of the animation on the tilesheet.
	    "numFrames" is the length of the animation.

	    You can alternatively specify an array and a y value.
	    */

		public function addAnimations(animationList:Object):void {
	        for (var animName:String in animationList) {
		        var val:Object = animationList[animName];
		        var frames:Array = [];
		        var y:int;

		        if (val["startPos"]) {
		          addAnimation(animName, val["startPos"][0], val["startPos"][1], val["numFrames"]);
		        } else {
		          addAnimationArray(animName, val["array"], val["y"]);
		        }
	        }
		}

		public function advance():void {
			var lastFrame:int = currentFrame;

			++currentTick;

			if (currentTick > ticksPerFrame) {
				++currentFrame;
				currentTick = 0;

				if (currentFrame >= animations[currentAnimation]["frames"].length) {
					currentFrame = 0;
				}
			}

			// Update tile if necessary.

			if (lastFrame != currentFrame) {
				this.ent.setTile(currentFrame, animations[currentAnimation]["y"]);
			}
		}

		public function hasAnimation(name:String):Boolean {
			return (name in animations);
		}

		public function setAnimation(name:String):void {
			if (currentAnimation != name) {
				currentAnimation = name;
				currentTick = 0;
				currentFrame  = 0;
			}
		}

		public function getAnimationFrame():int {
			return currentFrame;
		}
	}
}