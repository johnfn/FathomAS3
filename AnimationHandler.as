package {
	// AnimationHandler takes care of animating Entities. You add animations with
	// addAnimation
	public class AnimationHandler {
		private var animations:Object = {};
		private var currentAnimation:String = "";
		private var currentFrame:int = 0;
		private var currentTick:int = 0;
		private var ticksPerFrame:int = 10;

		function AnimationHandler() {

		}

		// We assume that you hold y is constant, with numFrames frames starting at x.

		public function addAnimation(name:String, frameX:int, frameY:int, numFrames:int):void {
			var frames:Array = [];

			for (var i:int = frameX; i < frameX + numFrames; i++) {
				frames.push(i);
			}

			animations[name] = frames;
		}

		// In case addAnimation() isn't good enough, you can just use an array
		// to specify x positions of frames.

		public function addAnimationArray(name:String, frames:Array, frameY:int):void {
			animations[name] = frames;
		}

		public function deleteAnimation(name:String):void {
			delete animations[name];
		}

		public var advance():void {
			++currentTick;

			if (currentTick > ticksPerFrame) {
				++currentFrame;
				currentTick = 0;

				if (currentFrame > animations[currentAnimation].length) {
					currentFrame = 0;
				}
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

		public function setConstantY(val:int):void {
			constantY = val;
		}

		public function getAnimationFrame():int {
			return currentFrame;
		}
	}
}